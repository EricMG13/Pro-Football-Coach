import Foundation

/// Salary-cap arithmetic. Every roster move routes through here so a team can never quietly
/// end up illegal.
public enum CapEngine {

    /// Total cap charged against a team: every contract's current hit, plus dead money.
    public static func capSpent(for team: Team, deadMoney: Int = 0) -> Int {
        let contracts = team.roster.reduce(0) { total, player in
            guard let contract = player.contract else { return total }
            return total + (player.isOnPracticeSquad
                ? LeagueRules.practiceSquadSalary
                : contract.currentCapHit)
        }
        return contracts + deadMoney
    }

    public static func capSpace(for team: Team, cap: Int, deadMoney: Int = 0) -> Int {
        cap - capSpent(for: team, deadMoney: deadMoney)
    }

    public static func capSpace(for team: Team, in league: League) -> Int {
        guard league.settings.salaryCapEnabled else { return .max / 4 }
        return capSpace(
            for: team,
            cap: league.salaryCap,
            deadMoney: league.deadMoney[team.id] ?? 0
        )
    }

    /// Whether a team could absorb a new contract's first-year hit.
    public static func canAfford(_ contract: Contract, team: Team, in league: League) -> Bool {
        guard league.settings.salaryCapEnabled else { return true }
        return capSpace(for: team, in: league) >= contract.capHit(inYear: 0)
    }

    /// Cuts a player: he leaves the roster and his dead money lands on the team's books.
    /// Returns the dead money incurred so callers can report it.
    @discardableResult
    public static func cut(playerID: UUID, from teamID: UUID, in league: inout League) -> Int {
        guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }),
              let playerIndex = league.teams[teamIndex].roster.firstIndex(where: { $0.id == playerID })
        else { return 0 }

        var player = league.teams[teamIndex].roster.remove(at: playerIndex)
        // Dead money follows the contract, never the practice-squad flag. A practice-squad deal
        // carries no bonus and no guarantee, so this is still zero for anyone genuinely on one —
        // but flagging a $30M veteran no longer erases what the club owes him.
        let dead = player.contract?.deadMoneyIfCutNow() ?? 0
        league.deadMoney[teamID, default: 0] += dead

        player.contract = nil
        player.isOnPracticeSquad = false
        // Morale takes a knock from being released; it recovers if someone signs him.
        player.morale = max(20, player.morale - 10)
        league.freeAgents.append(player)
        // `depthOrder` drops names that are no longer on the roster, so a release does not need
        // to rebuild the chart — and rebuilding it would throw away the user's own ordering.
        return dead
    }

    /// Signs a free agent to a team. Fails (returning false) if the cap or roster won't allow it.
    @discardableResult
    public static func sign(
        playerID: UUID,
        to teamID: UUID,
        contract: Contract,
        practiceSquad: Bool = false,
        in league: inout League
    ) -> Bool {
        guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }),
              let freeAgentIndex = league.freeAgents.firstIndex(where: { $0.id == playerID })
        else { return false }

        let team = league.teams[teamIndex]
        let limit = practiceSquad ? LeagueRules.practiceSquadSize : LeagueRules.activeRosterSize
        let current = practiceSquad ? team.practiceSquad.count : team.activeRoster.count
        guard current < limit else { return false }

        // The practice squad pays practice-squad money. Honouring a negotiated salary here would
        // let a club park a star on the squad for a stipend and keep his real number off the cap.
        let candidate = league.freeAgents[freeAgentIndex]
        let terms = practiceSquad
            ? ContractPricer.minimumContract(age: candidate.age)
            : contract
        guard canAfford(terms, team: team, in: league) else { return false }

        var player = league.freeAgents.remove(at: freeAgentIndex)
        player.contract = terms
        player.isOnPracticeSquad = practiceSquad
        player.morale = min(95, player.morale + 8)
        league.teams[teamIndex].roster.append(player)
        league.teams[teamIndex].autoSortDepthChart()
        return true
    }

    /// Why a roster move was refused, so the interface can say something better than "no".
    public enum RosterMoveError: Error, Equatable {
        case playerNotFound
        case activeRosterFull
        case practiceSquadFull
        case wouldLeavePositionShort(Position)
        case notOnPracticeSquad
        case alreadyOnPracticeSquad
        /// He is under a real contract; the practice squad pays a stipend.
        case contractTooLarge(Int)
        case noCapRoom(Int)
    }

    /// The most a deal can be worth and still belong on the practice squad.
    public static var practiceSquadContractCeiling: Int { LeagueRules.minimumSalaryVeteran }

    /// Promotes a practice-squad player onto the active roster.
    ///
    /// A promotion swaps the stipend for the player's real cap hit, so it has to be paid for.
    /// Returns nil on success, or why the move was refused.
    @discardableResult
    public static func elevate(
        playerID: UUID,
        on teamID: UUID,
        in league: inout League
    ) -> RosterMoveError? {
        guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }),
              let playerIndex = league.teams[teamIndex].roster.firstIndex(where: { $0.id == playerID })
        else { return .playerNotFound }
        guard league.teams[teamIndex].roster[playerIndex].isOnPracticeSquad
        else { return .notOnPracticeSquad }
        guard league.teams[teamIndex].activeRoster.count < LeagueRules.activeRosterSize
        else { return .activeRosterFull }

        // Promotion means a real contract, not the practice-squad stipend.
        let age = league.teams[teamIndex].roster[playerIndex].age
        let deal = league.teams[teamIndex].roster[playerIndex].contract
            ?? ContractPricer.minimumContract(age: age)
        // The stipend stops and the deal starts, so the club has to have room for the difference.
        let extra = deal.capHit(inYear: 0) - LeagueRules.practiceSquadSalary
        let room = capSpace(for: league.teams[teamIndex], in: league)
        if league.settings.salaryCapEnabled, extra > room {
            return .noCapRoom(extra - room)
        }

        league.teams[teamIndex].roster[playerIndex].isOnPracticeSquad = false
        league.teams[teamIndex].roster[playerIndex].contract = deal
        league.teams[teamIndex].roster[playerIndex].morale = min(
            100, league.teams[teamIndex].roster[playerIndex].morale + 10
        )
        // The depth chart is not re-sorted: the user set that order by hand on the same screen
        // these moves are made from, and `depthOrder` slots a new name in on its own.
        return nil
    }

    /// Sends an active player down to the practice squad.
    ///
    /// Refused if it would leave a position below the minimum the team needs to field a unit —
    /// the same floor cutdown and cap compliance respect — or if the player is under a real
    /// contract. A practice-squad player is charged a stipend, so without that second rule a
    /// club could wipe a thirty-million-dollar cap hit by swiping a row.
    /// Returns nil on success, or why the move was refused.
    @discardableResult
    public static func demote(
        playerID: UUID,
        on teamID: UUID,
        in league: inout League
    ) -> RosterMoveError? {
        guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }),
              let player = league.teams[teamIndex].roster.first(where: { $0.id == playerID })
        else { return .playerNotFound }
        guard !player.isOnPracticeSquad else { return .alreadyOnPracticeSquad }
        guard league.teams[teamIndex].practiceSquad.count < LeagueRules.practiceSquadSize
        else { return .practiceSquadFull }

        // The positional floor is checked first because it is the more fundamental refusal: no
        // contract, however small, makes it legal to field a team without a kicker.
        let remaining = league.teams[teamIndex].activeRoster
            .filter { $0.position == player.position && $0.id != playerID }
            .count
        guard remaining >= player.position.minimumRosterCount
        else { return .wouldLeavePositionShort(player.position) }

        let hit = player.contract?.currentCapHit ?? 0
        guard hit <= practiceSquadContractCeiling else { return .contractTooLarge(hit) }

        guard let playerIndex = league.teams[teamIndex].roster.firstIndex(where: { $0.id == playerID })
        else { return .playerNotFound }
        league.teams[teamIndex].roster[playerIndex].isOnPracticeSquad = true
        league.teams[teamIndex].roster[playerIndex].morale = max(
            15, league.teams[teamIndex].roster[playerIndex].morale - 12
        )
        // Not re-sorted, for the same reason as a promotion: the order is the user's.
        return nil
    }

    /// Advances every contract a year, expiring the finished ones into free agency, and
    /// clears the year's dead money.
    public static func rolloverContracts(in league: inout League) {
        for teamIndex in league.teams.indices {
            var expiring: [Player] = []
            var kept: [Player] = []
            for var player in league.teams[teamIndex].roster {
                guard let contract = player.contract else {
                    expiring.append(player)
                    continue
                }
                let aged = contract.aged()
                if aged.isExpired {
                    player.contract = nil
                    player.isOnPracticeSquad = false
                    expiring.append(player)
                } else {
                    player.contract = aged
                    kept.append(player)
                }
            }
            league.teams[teamIndex].roster = kept
            league.teams[teamIndex].autoSortDepthChart()
            league.freeAgents.append(contentsOf: expiring)
        }
        league.deadMoney = [:]
    }

    /// Grows the cap for the new league year.
    public static func advanceSalaryCap(in league: inout League) {
        let growth = league.rng.double01()
            * (LeagueRules.capGrowthRange.upperBound - LeagueRules.capGrowthRange.lowerBound)
            + LeagueRules.capGrowthRange.lowerBound
        league.salaryCap = ((Int(Double(league.salaryCap) * growth)) / 1_000_000) * 1_000_000
    }

    /// Emergency valve: an AI team over the cap sheds its worst value contracts until legal.
    /// Cuts the player whose cap saving per point of overall is highest.
    public static func enforceCapCompliance(teamID: UUID, in league: inout League) {
        guard league.settings.salaryCapEnabled else { return }
        var guard_ = 0
        while let team = league.team(id: teamID),
              capSpace(for: team, in: league) < 0,
              guard_ < LeagueRules.activeRosterSize {
            guard_ += 1
            let candidates = team.activeRoster
                .filter { $0.contract?.capSavingsIfCutNow() ?? 0 > 0 }
                .filter { player in
                    // Never cut below the positional floor.
                    team.activeRoster.filter { $0.position == player.position }.count
                        > player.position.minimumRosterCount
                }
            guard let victim = candidates.max(by: { lhs, rhs in
                let lhsValue = Double(lhs.contract?.capSavingsIfCutNow() ?? 0) / Double(max(1, lhs.overall))
                let rhsValue = Double(rhs.contract?.capSavingsIfCutNow() ?? 0) / Double(max(1, rhs.overall))
                return lhsValue < rhsValue
            }) else { return }
            cut(playerID: victim.id, from: teamID, in: &league)
        }
    }
}
