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

    /// Draft picks are derivable from the league, so they are rebuilt on load rather than stored.
    public var draftPicks: [DraftPick] = []

    /// Season goals, the scouting budget and the draft board are part of the franchise, so they
    /// read and write straight through to the league and survive a save.
    public var seasonGoals: [CoachEngine.SeasonGoal] {
        get { league?.seasonGoals ?? [] }
        set { mutate { $0.seasonGoals = newValue } }
    }

    public var scoutingPoints: Int {
        get { league?.scoutingPoints ?? 0 }
        set { mutate { $0.scoutingPoints = newValue } }
    }

    public var draftClass: [DraftProspect] {
        get { league?.draftClass ?? [] }
        set { mutate { $0.draftClass = newValue } }
    }

    /// Live draft, present only while the draft stage is being played out.
    public private(set) var draftSession: DraftSession?

    /// Identifier of the scenario this franchise started under, if any.
    public var activeScenario: String?
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
        new.seasonGoals = CoachEngine.makeSeasonGoals(for: new, rng: &rng)
        new.rng = rng
        new.scoutingPoints = CoachEngine.scoutingPoints(for: new.coach)
        new.draftClass = []

        draftPicks = TradeEngine.makePicks(for: new)
        league = new
        saveID = UUID()
        self.saveName = saveName.isEmpty ? "\(new.userTeam?.name ?? "New") Franchise" : saveName
        persist()
    }

    /// Starts a franchise under a scenario's altered starting conditions.
    public func startScenario(
        _ scenario: Scenario,
        teamIndex: Int,
        coach: CoachProfile,
        settings: LeagueSettings,
        seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)
    ) {
        startNewFranchise(
            teamIndex: teamIndex,
            coach: coach,
            settings: settings,
            saveName: scenario.name,
            seed: seed
        )
        mutate { scenario.apply(&$0) }
        activeScenario = scenario.id
        persist()
    }

    public func load(id: UUID) {
        do {
            var loaded = try store.load(id: id)
            // A franchise saved before goals were persisted comes back without any. Rather than
            // leave it permanently goal-less, set this season's objectives on the way in.
            if loaded.seasonGoals.isEmpty, !loaded.phase.isOffseason {
                var rng = loaded.rng
                loaded.seasonGoals = CoachEngine.makeSeasonGoals(for: loaded, rng: &rng)
                loaded.rng = rng
            }
            league = loaded
            saveID = id
            saveName = saves.first { $0.id == id }?.name ?? "Franchise"
            draftPicks = TradeEngine.makePicks(for: loaded)
            persist()
        } catch {
            lastError = "That save could not be opened."
        }
    }

    public func closeFranchise() {
        persist()
        league = nil
        saveID = nil
        draftSession = nil
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
        mutate { league in
            SeasonEngine.startSeason(&league)
            var rng = league.rng
            league.seasonGoals = CoachEngine.makeSeasonGoals(for: league, rng: &rng)
            league.rng = rng
        }
    }

    private func refreshGoals() {
        mutate { league in
            guard !league.seasonGoals.isEmpty else { return }
            var goals = league.seasonGoals
            CoachEngine.settleGoals(&goals, league: &league)
            league.seasonGoals = goals
        }
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
        if league?.phase == .preseason {
            mutate { league in
                var rng = league.rng
                league.seasonGoals = CoachEngine.makeSeasonGoals(for: league, rng: &rng)
                league.scoutingPoints = CoachEngine.scoutingPoints(for: league.coach)
                league.rng = rng
            }
        }
    }

    // MARK: - Draft

    /// Opens a live draft if one is not already running.
    public func beginDraftIfNeeded() {
        guard draftSession == nil, var league else { return }
        if league.draftClass.isEmpty {
            league.draftClass = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            draftPicks = TradeEngine.makePicks(for: league)
        }
        var session = DraftSession(league: league, prospects: league.draftClass, picks: draftPicks)
        session.advanceToUserPick(league: &league)
        league.draftClass = session.prospects
        draftSession = session
        self.league = league
        autosave()
    }

    public func advanceDraftToUserPick() {
        guard var session = draftSession, var league else { return }
        session.advanceToUserPick(league: &league)
        commit(session: session, league: league)
    }

    @discardableResult
    public func selectInDraft(prospectID: UUID) -> CompletedPick? {
        guard var session = draftSession, var league else { return nil }
        let pick = session.select(prospectID: prospectID, league: &league)
        commit(session: session, league: league)
        return pick
    }

    @discardableResult
    public func autoPickForUser() -> CompletedPick? {
        guard var session = draftSession, var league else { return nil }
        let pick = session.autoPickForUser(league: &league)
        commit(session: session, league: league)
        return pick
    }

    public func finishDraft() {
        guard var session = draftSession, var league else { return }
        session.finish(league: &league)
        commit(session: session, league: league)
    }

    /// Closes out the draft stage and moves the offseason on.
    public func completeDraftStage() {
        if let session = draftSession, !session.isFinished { finishDraft() }
        draftSession = nil
        mutate { $0.draftClass = [] }
        advanceOffseasonStage()
    }

    private func commit(session: DraftSession, league: League) {
        var updated = league
        updated.draftClass = session.prospects
        draftSession = session
        self.league = updated
        autosave()
    }

    // MARK: - Re-signing

    /// Offers an extension. The roll happens here so a marginal offer stays a gamble.
    public func reSign(playerID: UUID, contract: Contract, chance: Double) -> Bool {
        guard var league, let teamID = league.userTeam?.id else { return false }
        var rng = league.rng
        let accepted = rng.chance(chance)
        league.rng = rng
        guard accepted else {
            self.league = league
            return false
        }
        let signed = ReSignEngine.reSign(
            playerID: playerID, to: teamID, contract: contract, in: &league
        )
        self.league = league
        if signed { autosave() }
        return signed
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

    /// Promotes a practice-squad player. Returns a sentence to show if the move was refused.
    @discardableResult
    public func elevate(playerID: UUID) -> String? {
        guard var current = league, let teamID = current.userTeam?.id else { return nil }
        let refusal = CapEngine.elevate(playerID: playerID, on: teamID, in: &current)
        league = current
        if refusal == nil { autosave() }
        return refusal.map(Self.describe)
    }

    /// Sends an active player down. Returns a sentence to show if the move was refused.
    @discardableResult
    public func demote(playerID: UUID) -> String? {
        guard var current = league, let teamID = current.userTeam?.id else { return nil }
        let refusal = CapEngine.demote(playerID: playerID, on: teamID, in: &current)
        league = current
        if refusal == nil { autosave() }
        return refusal.map(Self.describe)
    }

    private static func describe(_ error: CapEngine.RosterMoveError) -> String {
        switch error {
        case .playerNotFound: "That player is no longer on the roster."
        case .activeRosterFull:
            "The active roster is full. Send somebody down or release a player first."
        case .practiceSquadFull: "The practice squad is full."
        case .wouldLeavePositionShort(let position):
            "That would leave you short at \(position.displayName)."
        case .notOnPracticeSquad: "He is already on the active roster."
        case .alreadyOnPracticeSquad: "He is already on the practice squad."
        }
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
