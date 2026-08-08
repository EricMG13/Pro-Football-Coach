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
        let dead = player.isOnPracticeSquad ? 0 : (player.contract?.deadMoneyIfCutNow() ?? 0)
        league.deadMoney[teamID, default: 0] += dead

        player.contract = nil
        player.isOnPracticeSquad = false
        // Morale takes a knock from being released; it recovers if someone signs him.
        player.morale = max(20, player.morale - 10)
        league.freeAgents.append(player)
        league.teams[teamIndex].autoSortDepthChart()
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
        guard canAfford(contract, team: team, in: league) else { return false }

        var player = league.freeAgents.remove(at: freeAgentIndex)
        player.contract = contract
        player.isOnPracticeSquad = practiceSquad
        player.morale = min(95, player.morale + 8)
        league.teams[teamIndex].roster.append(player)
        league.teams[teamIndex].autoSortDepthChart()
        return true
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
