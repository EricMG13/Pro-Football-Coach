import SwiftUI
import Observation
import FootballSimCore

/// The one object the whole app reads from. Owns the loaded franchise, the save file behind
/// it, and the transient state that lives beside a league (draft class, picks, goals).
@Observable
@MainActor
public final class AppState {
    public private(set) var league: League?
    public private(set) var saveID: UUID?
    public private(set) var saveName: String = "My Franchise"
    public private(set) var saves: [SaveMeta] = []

    /// Season-long extras that hang off the league rather than living inside it.
    public var draftClass: [DraftProspect] = []
    public var draftPicks: [DraftPick] = []
    public var seasonGoals: [CoachEngine.SeasonGoal] = []
    public var scoutingPoints: Int = LeagueRules.scoutingPointsPerSeason

    public var autosaveEnabled = true
    public var lastError: String?
    public var isBusy = false

    private let store: SaveStore

    public init(store: SaveStore = SaveStore()) {
        self.store = store
        saves = store.list()
    }

    public var userTeam: Team? { league?.userTeam }

    public var theme: TeamTheme {
        userTeam.map { TeamTheme(colors: $0.colors) } ?? .neutral
    }

    // MARK: - Lifecycle

    public func startNewFranchise(
        teamIndex: Int,
        coach: CoachProfile,
        settings: LeagueSettings,
        saveName: String,
        seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)
    ) {
        var coach = coach
        CoachEngine.applyBackgroundBonus(to: &coach)

        var new = LeagueFactory.makeDefaultLeague(
            seed: seed,
            userTeamIndex: teamIndex,
            coach: coach,
            settings: settings
        )
        var rng = new.rng
        seasonGoals = CoachEngine.makeSeasonGoals(for: new, rng: &rng)
        new.rng = rng

        draftPicks = TradeEngine.makePicks(for: new)
        draftClass = []
        scoutingPoints = CoachEngine.scoutingPoints(for: new.coach)

        league = new
        saveID = UUID()
        self.saveName = saveName.isEmpty ? "\(new.userTeam?.name ?? "New") Franchise" : saveName
        persist()
    }

    public func load(id: UUID) {
        do {
            let loaded = try store.load(id: id)
            league = loaded
            saveID = id
            saveName = saves.first { $0.id == id }?.name ?? "Franchise"
            draftPicks = TradeEngine.makePicks(for: loaded)
            scoutingPoints = CoachEngine.scoutingPoints(for: loaded.coach)
        } catch {
            lastError = "That save could not be opened."
        }
    }

    public func closeFranchise() {
        persist()
        league = nil
        saveID = nil
        draftClass = []
        seasonGoals = []
    }

    public func delete(id: UUID) {
        store.delete(id: id)
        if saveID == id { league = nil; saveID = nil }
        saves = store.list()
    }

    /// Writes the current franchise to disk. Called after every state-changing action.
    public func persist() {
        guard let league, let saveID else { return }
        do {
            _ = try store.save(league, id: saveID, name: saveName)
            saves = store.list()
        } catch {
            lastError = "Could not save: \(error.localizedDescription)"
        }
    }

    private func autosave() {
        guard autosaveEnabled else { return }
        persist()
    }

    // MARK: - Mutation

    /// The single funnel for changing the league, so autosave can never be forgotten.
    public func mutate(_ change: (inout League) -> Void) {
        guard var current = league else { return }
        change(&current)
        league = current
        autosave()
    }

    // MARK: - Season flow

    public func advanceWeek(userGameResult: GameRecord? = nil) {
        mutate { league in
            SeasonEngine.advanceWeek(&league, userGameResult: userGameResult)
        }
        refreshGoals()
    }

    public func kickOffSeason() {
        mutate { SeasonEngine.startSeason(&$0) }
        if let league {
            var rng = league.rng
            seasonGoals = CoachEngine.makeSeasonGoals(for: league, rng: &rng)
            mutate { $0.rng = rng }
        }
    }

    private func refreshGoals() {
        guard var league, !seasonGoals.isEmpty else { return }
        var goals = seasonGoals
        CoachEngine.settleGoals(&goals, league: &league)
        seasonGoals = goals
        self.league = league
    }

    /// The user's next scheduled game, if there is one.
    public var nextGame: ScheduledGame? {
        guard let league else { return nil }
        let week: Int
        switch league.phase {
        case .regularSeason(let value): week = value
        case .playoffs(let round): week = LeagueRules.seasonWeeks + 1 + round
        default: return nil
        }
        return league.games(inWeek: week).first {
            $0.involves(league.userTeamID) && !league.hasPlayed($0)
        }
    }

    public var isOnBye: Bool {
        guard let league, league.phase.isRegularSeason else { return false }
        return nextGame == nil
    }

    // MARK: - Offseason

    public func advanceOffseasonStage() {
        guard league != nil else { return }
        var prospects = draftClass
        var picks = draftPicks
        mutate { league in
            OffseasonEngine.advanceStage(&league, prospects: &prospects, picks: &picks)
        }
        draftClass = prospects
        draftPicks = picks

        // A new league year resets the coaching season.
        if let league, league.phase == .preseason {
            var rng = league.rng
            seasonGoals = CoachEngine.makeSeasonGoals(for: league, rng: &rng)
            scoutingPoints = CoachEngine.scoutingPoints(for: league.coach)
            mutate { $0.rng = rng }
        }
    }

    // MARK: - Roster actions

    public func cut(playerID: UUID) {
        guard let teamID = league?.userTeamID else { return }
        mutate { CapEngine.cut(playerID: playerID, from: teamID, in: &$0) }
    }

    public func sign(playerID: UUID, contract: Contract, practiceSquad: Bool = false) -> Bool {
        guard let teamID = league?.userTeamID, var current = league else { return false }
        let signed = CapEngine.sign(
            playerID: playerID, to: teamID, contract: contract,
            practiceSquad: practiceSquad, in: &current
        )
        league = current
        if signed { autosave() }
        return signed
    }

    public func autoSortDepthChart() {
        mutate { league in
            guard var team = league.userTeam else { return }
            team.autoSortDepthChart()
            league.update(team)
        }
    }

    public func moveDepthChart(position: Position, from source: IndexSet, to destination: Int) {
        mutate { league in
            guard var team = league.userTeam else { return }
            var order = team.depthOrder(for: position, healthyOnly: false).map(\.id)
            order.move(fromOffsets: source, toOffset: destination)
            team.depthChart[position] = order
            league.update(team)
        }
    }

    // MARK: - Coach

    public func unlockSkill(branch: SkillBranch, index: Int) {
        mutate { league in
            CoachEngine.unlock(branch: branch, index: index, coach: &league.coach)
        }
    }

    public var capSpace: Int {
        guard let league, let team = league.userTeam else { return 0 }
        return CapEngine.capSpace(for: team, in: league)
    }
}
