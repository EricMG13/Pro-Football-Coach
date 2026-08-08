import Foundation

/// A preset challenge: an ordinary league with its starting conditions bent into a specific
/// predicament, plus the goal that defines winning it.
///
/// Every scenario is expressed as a transformation of a generated league rather than a bespoke
/// game mode, so nothing in the engine needs a special case.
public struct Scenario: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let summary: String
    public let objective: String
    /// Applied to the freshly generated league before the first season.
    public let apply: @Sendable (inout League) -> Void

    public init(
        id: String,
        name: String,
        summary: String,
        objective: String,
        apply: @escaping @Sendable (inout League) -> Void
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.objective = objective
        self.apply = apply
    }

    public static let all: [Scenario] = [capHell, expansion, agingLegend]

    /// A contender that mortgaged its future. Talented, expensive, and running out of room.
    public static let capHell = Scenario(
        id: "cap-hell",
        name: "Cap Hell",
        summary: "You inherit a roster good enough to win now and a cap sheet that says you can't.",
        objective: "Win a championship within three seasons without stripping the team to the studs."
    ) { league in
        guard var team = league.userTeam else { return }

        // Everyone gets a richer, more front-loaded deal — exactly the structure that makes
        // cutting a player cost more than keeping him.
        for index in team.roster.indices {
            guard let existing = team.roster[index].contract else { continue }
            let inflated = existing.salaryPerYear.map { Int(Double($0) * 1.45) }
            team.roster[index].contract = Contract(
                years: existing.years,
                salaryPerYear: inflated,
                signingBonus: Int(Double(existing.signingBonus) * 2.2),
                guaranteedYears: min(existing.years, existing.guaranteedYears + 1),
                yearsElapsed: existing.yearsElapsed
            )
        }
        team.reputation = min(95, team.reputation + 20)
        league.update(team)

        // Dead money from the previous regime's mistakes.
        league.deadMoney[team.id, default: 0] += 24_000_000
        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: 0,
                category: .league,
                headline: "\(team.fullName) hire a new coach with the cap in ruins",
                body: "The roster can win today. The books say tomorrow is the problem.",
                teamIDs: [team.id]
            )
        )
    }

    /// A brand-new team: nothing but young bodies and draft capital.
    public static let expansion = Scenario(
        id: "expansion",
        name: "Expansion Franchise",
        summary: "A first-year team with no history, no stars, and a stack of picks.",
        objective: "Reach the playoffs within four seasons."
    ) { league in
        guard var team = league.userTeam else { return }

        // Replace the roster with young, cheap, unproven players.
        var replacements: [Player] = []
        for position in Position.allCases {
            for slot in 0..<position.rosterTarget {
                let target = 66 - slot * 2
                var player = PlayerFactory.make(
                    position: position,
                    age: league.rng.int(in: 21...25),
                    targetOverall: target.clampedToRating(),
                    year: league.year,
                    rng: &league.rng
                )
                player.contract = ContractPricer.minimumContract(age: player.age, years: 3)
                replacements.append(player)
            }
        }
        for _ in 0..<LeagueRules.practiceSquadSize {
            var player = PlayerFactory.make(
                position: league.rng.pick(Position.allCases.filter { !$0.isSpecialist }),
                age: league.rng.int(in: 21...23),
                targetOverall: league.rng.int(in: 48...58),
                year: league.year,
                rng: &league.rng
            )
            player.isOnPracticeSquad = true
            player.contract = ContractPricer.minimumContract(age: player.age)
            replacements.append(player)
        }

        team.roster = replacements
        team.reputation = 20
        team.ownerPatience = 5
        team.aiPersonality = .rebuilder
        team.autoSortDepthChart()
        league.update(team)

        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: 0,
                category: .league,
                headline: "\(team.fullName) play their first season",
                body: "Cheap, young, and completely unproven — but the cap is clean and the picks are yours.",
                teamIDs: [team.id]
            )
        )
    }

    /// One great quarterback at the end of his career, and not much else.
    public static let agingLegend = Scenario(
        id: "aging-legend",
        name: "Aging Legend",
        summary: "A 38-year-old superstar has two years left. The roster around him does not.",
        objective: "Win it all before he retires."
    ) { league in
        guard var team = league.userTeam else { return }

        // The legend himself.
        if let index = team.roster.firstIndex(where: { $0.position == .qb }) {
            var legend = PlayerFactory.make(
                position: .qb,
                age: 38,
                targetOverall: 96,
                year: league.year,
                rng: &league.rng,
                potentialOverride: .f
            )
            legend.contract = Contract(
                years: 2,
                salaryPerYear: [42_000_000, 44_000_000],
                signingBonus: 20_000_000,
                guaranteedYears: 2
            )
            legend.morale = 90
            legend.traits = [.clutch, .leader]
            team.roster[index] = legend
        }

        // Everyone else takes a step down: the supporting cast is the problem to solve.
        for index in team.roster.indices where team.roster[index].position != .qb {
            team.roster[index].ratings.adjustAll(by: -6)
        }
        team.autoSortDepthChart()
        league.update(team)

        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: 0,
                category: .league,
                headline: "The window is two years wide",
                body: "Your quarterback is still one of the best alive. Nobody knows for how long.",
                teamIDs: [team.id]
            )
        )
    }
}
