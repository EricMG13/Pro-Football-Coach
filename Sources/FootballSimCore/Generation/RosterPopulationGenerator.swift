import Foundation

public struct RosterPopulation: Sendable, Equatable {
    public let players: [Player]
    public let programmeRosterIDs: [UUID: [UUID]]
    public let proRosterIDs: [UUID: [UUID]]

    public init(
        players: [Player],
        programmeRosterIDs: [UUID: [UUID]],
        proRosterIDs: [UUID: [UUID]]
    ) {
        self.players = players
        self.programmeRosterIDs = programmeRosterIDs
        self.proRosterIDs = proRosterIDs
    }
}

public enum RosterPopulationGenerator {
    public static func walkOn(
        rootSeed: UInt64,
        season: Int,
        organisationID: UUID,
        position: Position,
        ordinal: Int,
        prestige: Rating
    ) -> Player {
        var player = replacement(
            rootSeed: rootSeed,
            season: season,
            organisationID: organisationID,
            position: position,
            ordinal: ordinal,
            prestige: prestige,
            tier: .college
        )
        for attribute in position.ratedAttributes {
            player.attributes[attribute] = Rating(
                player.attributes[attribute].value - CollegeRules.walkOnRatingPenalty
            )
        }
        player.potential = Rating(player.potential.value - CollegeRules.walkOnRatingPenalty)
        return player
    }

    public static func replacement(
        rootSeed: UInt64,
        season: Int,
        organisationID: UUID,
        position: Position,
        ordinal: Int,
        prestige: Rating,
        tier: Tier
    ) -> Player {
        let organisationSeed = SeededRandom.derive(
            from: rootSeed,
            scope: .personnel,
            identifier: organisationID
        )
        let seasonSeed = SeededRandom.derive(
            from: organisationSeed,
            scope: .season,
            ordinal: season
        )
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: seasonSeed,
            scope: .personnel,
            ordinal: ordinal
        ))
        let name = NameGrammar.personName(using: &rng)
        let base = baseRating(prestige: prestige, tier: tier)
        var attributes = Attributes()
        for attribute in position.ratedAttributes {
            attributes[attribute] = Rating(base + rng.int(in: -10...10))
        }
        let id = rng.uuid()
        let potential = Rating(base + rng.int(in: 4...18))
        return Player(
            id: id,
            firstName: name.given,
            lastName: name.family,
            position: position,
            age: tier == .college ? 18 : 22,
            attributes: attributes,
            potential: potential,
            traits: TraitPopulationGenerator.traits(for: id),
            eligibility: tier == .college ? Eligibility() : nil
        )
    }

    public static func generate(
        seed: UInt64,
        programmes: [Programme],
        proTeams: [ProTeam]
    ) -> RosterPopulation {
        var players: [Player] = []
        players.reserveCapacity(
            programmes.count * CollegeRules.rosterLimit
                + proTeams.count * ProRules.activeRosterLimit
        )
        var programmeRosterIDs: [UUID: [UUID]] = [:]
        var proRosterIDs: [UUID: [UUID]] = [:]

        for programme in programmes.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            let roster = generateRoster(
                seed: SeededRandom.derive(from: seed, scope: .league, identifier: programme.id),
                template: CollegeRules.initialRosterByPosition,
                prestige: programme.prestige,
                tier: .college
            )
            players.append(contentsOf: roster)
            programmeRosterIDs[programme.id] = roster.map(\.id)
        }
        for team in proTeams.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            let roster = generateRoster(
                seed: SeededRandom.derive(from: seed, scope: .league, identifier: team.id),
                template: ProRules.initialRosterByPosition,
                prestige: team.prestige,
                tier: .pro
            )
            players.append(contentsOf: roster)
            proRosterIDs[team.id] = roster.map(\.id)
        }

        return RosterPopulation(
            players: players,
            programmeRosterIDs: programmeRosterIDs,
            proRosterIDs: proRosterIDs
        )
    }

    private static func generateRoster(
        seed: UInt64,
        template: [Position: Int],
        prestige: Rating,
        tier: Tier
    ) -> [Player] {
        var roster: [Player] = []
        var slot = 0
        for position in Position.allCases {
            for _ in 0..<(template[position] ?? 0) {
                var rng = SeededRandom(seed: SeededRandom.derive(
                    from: seed,
                    scope: .game,
                    ordinal: slot
                ))
                let name = NameGrammar.personName(using: &rng)
                let base = baseRating(prestige: prestige, tier: tier)
                var attributes = Attributes()
                for attribute in position.ratedAttributes {
                    attributes[attribute] = Rating(base + rng.int(in: -10...10))
                }

                let age: Int
                let eligibility: Eligibility?
                switch tier {
                case .college:
                    let classYear = rng.int(in: 0...3)
                    age = 18 + classYear
                    eligibility = Eligibility(
                        seasonsRemaining: CollegeRules.seasonsOfCompetition - classYear,
                        yearsRemaining: CollegeRules.eligibilityClockYears - classYear
                    )
                case .pro:
                    age = min(34, max(22, Int(rng.gaussian(mean: 27, sd: 3).rounded())))
                    eligibility = nil
                }

                let id = rng.uuid()
                let potential = Rating(base + rng.int(in: 4...18))
                roster.append(Player(
                    id: id,
                    firstName: name.given,
                    lastName: name.family,
                    position: position,
                    age: age,
                    attributes: attributes,
                    potential: potential,
                    traits: TraitPopulationGenerator.traits(for: id),
                    eligibility: eligibility
                ))
                slot += 1
            }
        }
        return roster
    }

    private static func baseRating(prestige: Rating, tier: Tier) -> Int {
        let span = prestige.value - SharedRules.ratingRange.lowerBound
        switch tier {
        case .college:
            return 50 + span * 25 / 59
        case .pro:
            return 60 + span * 15 / 59
        }
    }
}
