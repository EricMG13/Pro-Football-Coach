import Foundation

/// A pick that has already been made.
public struct CompletedPick: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let round: Int
    public let pickInRound: Int
    public let overall: Int
    public let teamID: UUID
    public let playerID: UUID
    public let playerName: String
    public let position: Position
    /// True overall, which is only knowable once he is on a roster.
    public let rating: Int

    public init(
        id: UUID,
        round: Int,
        pickInRound: Int,
        overall: Int,
        teamID: UUID,
        playerID: UUID,
        playerName: String,
        position: Position,
        rating: Int
    ) {
        self.id = id
        self.round = round
        self.pickInRound = pickInRound
        self.overall = overall
        self.teamID = teamID
        self.playerID = playerID
        self.playerName = playerName
        self.position = position
        self.rating = rating
    }
}

/// A draft the user can actually sit through.
///
/// `DraftEngine.runDraft` resolves the whole thing at once, which is right for simming ahead
/// but gives the user no say in their own picks. This walks the same pick order one selection
/// at a time, making the AI choices automatically and stopping whenever the user is on the
/// clock — the draft being the one day a year a franchise game should slow down.
public struct DraftSession: Sendable {
    public private(set) var order: [(round: Int, teamID: UUID)]
    public private(set) var index: Int
    public private(set) var completed: [CompletedPick]
    public var prospects: [DraftProspect]

    private let userTeamID: UUID

    public init(league: League, prospects: [DraftProspect], picks: [DraftPick]) {
        order = DraftEngine.pickSequence(league: league, picks: picks)
        index = 0
        completed = []
        self.prospects = prospects
        userTeamID = league.userTeamID
    }

    public var isFinished: Bool { index >= order.count || prospects.isEmpty }

    /// Who is picking right now.
    public var onTheClock: (round: Int, teamID: UUID)? {
        guard !isFinished else { return nil }
        return order[index]
    }

    public var isUserOnTheClock: Bool { onTheClock?.teamID == userTeamID }

    /// Pick number within its round, 1-based.
    public var pickInRound: Int {
        guard let current = onTheClock else { return 0 }
        return order[..<index].filter { $0.round == current.round }.count + 1
    }

    public var overallPick: Int { index + 1 }

    /// Runs AI selections until the user is on the clock or the draft ends.
    /// Returns the picks made along the way so the UI can show the ticker.
    @discardableResult
    public mutating func advanceToUserPick(league: inout League) -> [CompletedPick] {
        var made: [CompletedPick] = []
        while !isFinished, !isUserOnTheClock {
            guard let pick = makeAISelection(league: &league) else { break }
            made.append(pick)
        }
        return made
    }

    /// Makes the user's selection, then runs the AI up to their next turn.
    @discardableResult
    public mutating func select(prospectID: UUID, league: inout League) -> CompletedPick? {
        guard isUserOnTheClock, let current = onTheClock else { return nil }
        guard let prospect = prospects.first(where: { $0.id == prospectID }) else { return nil }
        let pick = commit(prospect: prospect, round: current.round, teamID: current.teamID, league: &league)
        advanceToUserPick(league: &league)
        return pick
    }

    /// Hands the current pick to the same logic the other teams use.
    @discardableResult
    public mutating func autoPickForUser(league: inout League) -> CompletedPick? {
        guard isUserOnTheClock else { return nil }
        let pick = makeAISelection(league: &league)
        advanceToUserPick(league: &league)
        return pick
    }

    /// Finishes the remainder without stopping, for a user who has seen enough.
    public mutating func finish(league: inout League) {
        while !isFinished {
            guard makeAISelection(league: &league) != nil else { break }
        }
        DraftEngine.signUndrafted(&league, prospects: &prospects)
    }

    // MARK: - Internals

    private mutating func makeAISelection(league: inout League) -> CompletedPick? {
        guard let current = onTheClock,
              let team = league.team(id: current.teamID) else {
            index += 1
            return nil
        }
        guard let prospect = DraftEngine.aiSelection(
            for: team, from: prospects, round: current.round, rng: &league.rng
        ) else {
            index += 1
            return nil
        }
        return commit(prospect: prospect, round: current.round, teamID: current.teamID, league: &league)
    }

    private mutating func commit(
        prospect: DraftProspect,
        round: Int,
        teamID: UUID,
        league: inout League
    ) -> CompletedPick {
        let slot = pickInRound
        prospects.removeAll { $0.id == prospect.id }

        var rookie = prospect.player
        rookie.draftOrigin = DraftOrigin(year: league.year, round: round, pickInRound: slot)
        rookie.contract = ContractPricer.rookieContract(round: round, pickInRound: slot)

        if let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }) {
            league.teams[teamIndex].roster.append(rookie)
            league.teams[teamIndex].autoSortDepthChart()
        }

        let pick = CompletedPick(
            id: league.rng.uuid(),
            round: round,
            pickInRound: slot,
            overall: index + 1,
            teamID: teamID,
            playerID: rookie.id,
            playerName: rookie.name,
            position: rookie.position,
            rating: rookie.overall
        )
        completed.append(pick)
        index += 1

        if round <= 2 || teamID == league.userTeamID {
            league.news.append(
                NewsItem(
                    id: league.rng.uuid(),
                    year: league.year,
                    week: 0,
                    category: .draft,
                    headline: "\(league.team(id: teamID)?.name ?? "A team") take \(rookie.position.abbreviation) \(rookie.name)",
                    body: "Round \(round), pick \(slot).",
                    teamIDs: [teamID]
                )
            )
        }
        return pick
    }

    /// How good this pick looks against where he was expected to go — the war-room grade.
    public static func grade(for pick: CompletedPick, expectedRound: Int) -> String {
        let slipped = expectedRound - pick.round
        switch slipped {
        case ..<(-2): return "Reach"
        case -2...(-1): return "Slight reach"
        case 0: return "On the board"
        case 1...2: return "Good value"
        default: return "Steal"
        }
    }
}

/// Keeping an expiring player, and whether he says yes.
public enum ReSignEngine {

    /// What the player wants to stay. Loyalty and a happy locker room cut the price;
    /// a good season and a miserable one both raise it.
    public static func askingSalary(for player: Player, team: Team, league: League) -> Int {
        var salary = Double(
            ContractPricer.askingSalary(
                for: player,
                teamReputation: team.reputation,
                salaryCap: league.salaryCap
            )
        )
        // Production this season moves the price: a career year costs more to reward.
        let line = league.seasonStats(for: player.id)
        let production = Double(line.totalTouchdowns) * 0.012
            + Double(line.passingYards) * 0.000_02
            + Double(line.scrimmageYards) * 0.000_06
            + Double(line.sacks) * 0.010
            + Double(line.interceptions) * 0.012
        salary *= 1 + min(0.30, production)
        return max(LeagueRules.minimumSalaryYoung, Int(salary / 100_000) * 100_000)
    }

    /// 0...1 chance he accepts. Being his own team is worth something, but not everything.
    public static func acceptance(
        player: Player,
        offer: Contract,
        team: Team,
        league: League
    ) -> Double {
        let asking = askingSalary(for: player, team: team, league: league)
        let ratio = Double(offer.averagePerYear) / Double(max(1, asking))

        var chance = min(1.0, max(0, (ratio - 0.75) / 0.45))
        // Incumbency: a player would rather not move house.
        chance += 0.10
        if player.has(.loyal) { chance += 0.15 }
        if player.has(.mercenary) { chance -= 0.10 }
        chance += Double(player.morale - 60) * 0.003
        chance += Double(team.reputation - 50) * 0.001

        // Length matters at the extremes: nobody old wants five years, nobody young wants one.
        let peak = LeagueRules.peakAgeWindow(player.position)
        if player.age > peak.upperBound, offer.years >= 4 { chance -= 0.20 }
        if player.age < peak.lowerBound, offer.years <= 1 { chance -= 0.10 }

        return min(1, max(0, chance))
    }

    /// Re-signs a player already on the roster. Fails if the cap will not take it.
    @discardableResult
    public static func reSign(
        playerID: UUID,
        to teamID: UUID,
        contract: Contract,
        in league: inout League
    ) -> Bool {
        guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }),
              let playerIndex = league.teams[teamIndex].roster.firstIndex(where: { $0.id == playerID })
        else { return false }
        guard CapEngine.canAfford(contract, team: league.teams[teamIndex], in: league) else { return false }

        // A real contract means a real roster place. Leaving the flag on would charge a
        // negotiated deal at the practice-squad stipend, which is the same laundering hole the
        // cap engine closes on every other door into this state. Checked before anything is
        // written, so a refusal leaves the player exactly as he was.
        let promoting = league.teams[teamIndex].roster[playerIndex].isOnPracticeSquad
            && contract.currentCapHit > CapEngine.practiceSquadContractCeiling
        if promoting {
            guard league.teams[teamIndex].activeRoster.count < LeagueRules.activeRosterSize
            else { return false }
        }

        league.teams[teamIndex].roster[playerIndex].contract = contract
        if promoting { league.teams[teamIndex].roster[playerIndex].isOnPracticeSquad = false }
        league.teams[teamIndex].roster[playerIndex].morale = min(
            100, league.teams[teamIndex].roster[playerIndex].morale + 6
        )
        return true
    }

    /// Players on a team whose deals are up. Practice-squad men are not negotiated with — they
    /// are on stipends, and the squad refills itself at cutdown.
    public static func expiring(for team: Team) -> [Player] {
        team.activeRoster
            .filter { $0.contract == nil || ($0.contract?.isExpiring ?? false) }
            .sorted { $0.overall > $1.overall }
    }
}
