import Foundation

/// The open market. Free agency runs in waves so the stars go early and the bargains surface
/// late, and every offer is judged on more than money.
public enum FreeAgencyEngine {

    public static let waves = 3

    /// A team's offer to a free agent.
    public struct Offer: Sendable {
        public let teamID: UUID
        public let contract: Contract

        public init(teamID: UUID, contract: Contract) {
            self.teamID = teamID
            self.contract = contract
        }
    }

    /// How appealing an offer is to a player, 0...1. Money dominates, but a winner with a
    /// clear starting job can beat a bigger cheque somewhere worse.
    public static func interest(
        player: Player,
        offer: Offer,
        team: Team,
        league: League
    ) -> Double {
        let ask = ContractPricer.askingSalary(
            for: player,
            teamReputation: team.reputation,
            salaryCap: league.salaryCap
        )
        let offered = offer.contract.averagePerYear

        // Money: 55% of the decision, saturating so absurd overpays stop buying more goodwill.
        let moneyRatio = Double(offered) / Double(max(1, ask))
        let money = min(1.0, moneyRatio / 1.4) * 0.55

        // Contender status: 20%.
        let record = league.record(for: team.id)
        let winning = record.gamesPlayed > 0 ? record.winPercentage : Double(team.reputation) / 100
        let contender = winning * 0.20

        // Role: 15%. Would he start here?
        let incumbents = team.depthOrder(for: player.position, healthyOnly: false)
        let wouldStart = incumbents.prefix(player.position.starterCount)
            .allSatisfy { $0.overall < player.overall }
        let role = (wouldStart ? 1.0 : 0.35) * 0.15

        // Franchise standing: 10%.
        let reputation = Double(team.reputation) / 100 * 0.10

        var total = money + contender + role + reputation
        if player.has(.mercenary) { total = money / 0.55 * 0.8 + total * 0.2 }
        if player.has(.loyal), player.contract != nil { total += 0.05 }
        return min(1, max(0, total))
    }

    /// Runs one wave: AI teams bid on the best available, players pick the best offer.
    /// Returns the signings that happened, as news.
    @discardableResult
    public static func runWave(_ league: inout League, wave: Int) -> [NewsItem] {
        var news: [NewsItem] = []

        // The market moves best-first, so stars are gone before the depth pieces are decided.
        let available = league.freeAgents.sorted { $0.overall > $1.overall }
        let batchSize = max(1, available.count / max(1, waves - wave))

        for player in available.prefix(batchSize) {
            guard league.freeAgents.contains(where: { $0.id == player.id }) else { continue }

            var offers: [Offer] = []
            for team in league.teams {
                guard team.id != league.userTeamID else { continue }
                guard let offer = aiOffer(for: player, from: team, in: league) else { continue }
                offers.append(offer)
            }
            guard !offers.isEmpty else { continue }

            // The player signs wherever he likes best, provided anyone clears his bar at all.
            let ranked = offers
                .compactMap { offer -> (Offer, Double)? in
                    guard let team = league.team(id: offer.teamID) else { return nil }
                    return (offer, interest(player: player, offer: offer, team: team, league: league))
                }
                .sorted { lhs, rhs in
                    lhs.1 == rhs.1 ? lhs.0.teamID.uuidString < rhs.0.teamID.uuidString : lhs.1 > rhs.1
                }

            guard let (winning, appeal) = ranked.first, appeal >= 0.45 else { continue }
            guard CapEngine.sign(
                playerID: player.id,
                to: winning.teamID,
                contract: winning.contract,
                in: &league
            ) else { continue }

            if let team = league.team(id: winning.teamID) {
                news.append(
                    NewsEngine.signing(
                        player: player,
                        team: team,
                        contract: winning.contract,
                        league: league,
                        rng: &league.rng
                    )
                )
            }
        }

        league.news.append(contentsOf: news)
        return news
    }

    /// What an AI team is willing to offer, or nil if it has no need, room, or interest.
    public static func aiOffer(for player: Player, from team: Team, in league: League) -> Offer? {
        guard team.activeRoster.count < LeagueRules.activeRosterSize else { return nil }

        let need = positionalNeed(for: player.position, on: team)
        guard need > 0.15 else { return nil }

        // A rebuilder will not pay for a 31-year-old; a win-now team will.
        let peak = LeagueRules.peakAgeWindow(player.position)
        var appetite = need
        if player.age > peak.upperBound {
            appetite *= team.aiPersonality.veteranPreference
        } else if player.age < peak.lowerBound {
            appetite *= 2 - team.aiPersonality.veteranPreference
        }
        guard appetite > 0.2 else { return nil }

        var rng = SeededRandom(seed: UInt64(truncatingIfNeeded: player.id.hashValue ^ team.id.hashValue))
        let ask = ContractPricer.askingSalary(
            for: player,
            teamReputation: team.reputation,
            salaryCap: league.salaryCap
        )
        // Bid up when the need is severe, shade down when it is marginal.
        let multiplier = 0.85 + appetite * 0.35 + (team.aiPersonality == .capHawk ? -0.08 : 0)
        let salary = max(LeagueRules.minimumSalaryYoung, Int(Double(ask) * multiplier))
        let years = ContractPricer.expectedYears(overall: player.overall, age: player.age, &rng)

        let bonusShare = player.overall >= 80 ? 0.32 : 0.15
        let total = salary * years
        let signingBonus = Int(Double(total) * bonusShare)
        let perYear = max(LeagueRules.minimumSalaryYoung, (total - signingBonus) / years)
        let contract = Contract(
            years: years,
            salaryPerYear: Array(repeating: perYear, count: years),
            signingBonus: signingBonus,
            guaranteedYears: player.overall >= 80 ? 2 : (player.overall >= 72 ? 1 : 0)
        )

        guard CapEngine.canAfford(contract, team: team, in: league) else { return nil }
        return Offer(teamID: team.id, contract: contract)
    }

    /// 0...1 measure of how badly a team needs a player at this position.
    public static func positionalNeed(for position: Position, on team: Team) -> Double {
        let group = team.activeRoster.filter { $0.position == position }
        let starters = group.sorted { $0.overall > $1.overall }.prefix(position.starterCount)

        // Missing bodies is the most urgent kind of need.
        if group.count < position.minimumRosterCount { return 1.0 }
        guard !starters.isEmpty else { return 1.0 }

        let averageStarter = Double(starters.reduce(0) { $0 + $1.overall }) / Double(starters.count)
        // A unit averaging 80 needs nothing; one averaging 60 needs everything.
        let quality = max(0, min(1, (78 - averageStarter) / 20))
        let depth = group.count < position.rosterTarget ? 0.25 : 0.0
        return min(1, quality + depth)
    }

    /// Fills holes left by injuries and cuts from the street free-agent pool.
    public static func fillRosterHoles(_ league: inout League) {
        for teamIndex in league.teams.indices {
            let team = league.teams[teamIndex]
            guard team.id != league.userTeamID else { continue }

            for position in Position.allCases {
                let count = team.activeRoster.filter { $0.position == position }.count
                guard count < position.minimumRosterCount else { continue }
                let candidates = league.freeAgents
                    .filter { $0.position == position }
                    .sorted { $0.overall > $1.overall }
                guard let best = candidates.first else { continue }
                CapEngine.sign(
                    playerID: best.id,
                    to: team.id,
                    contract: ContractPricer.minimumContract(age: best.age),
                    in: &league
                )
            }
        }
    }

    /// Tops the market back up so it never runs dry across long dynasties.
    public static func replenishStreetFreeAgents(_ league: inout League, target: Int = 40) {
        guard league.freeAgents.count < target else { return }
        for _ in league.freeAgents.count..<target {
            let position = league.rng.pick(Position.allCases)
            let player = PlayerFactory.make(
                position: position,
                age: league.rng.int(in: 24...33),
                targetOverall: league.rng.int(in: 52...68),
                year: league.year,
                rng: &league.rng
            )
            league.freeAgents.append(player)
        }
    }
}
