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
        let base = baseRating(strength: prestige, tier: tier)
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
        season: Int,
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
            players.append(contentsOf: signed(
                roster: roster,
                season: season,
                seed: SeededRandom.derive(from: seed, scope: .contract, identifier: team.id)
            ))
            proRosterIDs[team.id] = roster.map(\.id)
        }

        return RosterPopulation(
            players: players,
            programmeRosterIDs: programmeRosterIDs,
            proRosterIDs: proRosterIDs
        )
    }

    /// Issues one contract per professional, per `02` section 4.2a.
    ///
    /// Two properties matter more than the numbers, and both are structural rather than tuned.
    ///
    /// **The term spread is a rotation, not a draw.** Terms cycle 1…5 through the roster in a
    /// deterministically shuffled order, so every roster expires close to a fifth of itself each
    /// season *by construction*. Drawing terms independently would leave the tail teams that expire
    /// half a roster at once, and a league-wide expiry count is bounded above:
    /// `ProMarketState.maximumFreeAgentIDs` is 512 against 1,696 professionals, and
    /// `ProMarketSystem.expireContracts` throws `invalidRoot` rather than overflow the pool.
    ///
    /// **Cap legality is allocated, not hoped for.** Salaries are shares of a target payroll rather
    /// than absolute figures derived from rating, so no rating distribution can push a team over
    /// the cap. Rating sets the *share*; the cap sets the total. Colours must pass contrast at
    /// generation instead of being fixed up later, and a payroll is the same obligation: a league
    /// that starts illegal has no legal move that makes it legal.
    private static func signed(roster: [Player], season: Int, seed: UInt64) -> [Player] {
        guard !roster.isEmpty else { return roster }

        // Deal only with what a bootstrapped roster can afford: the cap less the room a draft class
        // and in-season signings need. Spending the whole cap at generation would make every team
        // instantly non-compliant the moment it drafted anyone.
        let cap = ProRules.salaryCap(seasonsAfterBase: max(0, season - ProRules.baseSalaryCapSeason))
        let targetPayroll = cap * ProRules.bootstrapPayrollPercentOfCap / 100

        // Weight by rating so better players cost more, with a floor so nobody plays for nothing.
        // The +40 keeps the spread from being savage: a 90 overall costs about twice a 60, not
        // thirty times.
        let weights = roster.map { player in max(1, player.overall.value + 40) }
        let totalWeight = weights.reduce(0, +)

        var rng = SeededRandom(seed: seed)
        var order = Array(roster.indices)
        // Fisher-Yates over a seeded stream: the rotation must not correlate term with position,
        // or every roster would lose its whole secondary in the same offseason.
        for index in stride(from: order.count - 1, to: 0, by: -1) {
            order.swapAt(index, rng.int(in: 0...index))
        }

        var termByIndex = [Int](repeating: 0, count: roster.count)
        for (rotation, index) in order.enumerated() {
            termByIndex[index] = rotation % ProRules.bootstrapContractTermSpread + 1
        }

        // Integer dollars throughout, and the remainder is handed out rather than dropped so the
        // payroll sums to the target exactly. A dollar lost here is a dollar of cap invented.
        var allocated = 0
        var signedRoster: [Player] = []
        signedRoster.reserveCapacity(roster.count)
        for (index, player) in roster.enumerated() {
            let isLast = index == roster.count - 1
            let share = isLast
                ? targetPayroll - allocated
                : targetPayroll * weights[index] / totalWeight
            let salary = max(ProRules.bootstrapMinimumSalary, share)
            allocated += share
            var signed = player
            signed.contract = Contract(
                years: termByIndex[index],
                baseSalaryByYear: Array(repeating: salary, count: termByIndex[index]),
                signingBonus: 0,
                signedSeason: season
            )
            signedRoster.append(signed)
        }
        return signedRoster
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
                let base = baseRating(strength: prestige, tier: tier)
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

    /// The talent scale both intake paths share, keyed on whatever makes the source strong.
    ///
    /// `strength` is a programme's prestige when generating that programme's roster, and a region's
    /// talent density when generating the prospects it produces. The two were separate expressions
    /// until 2026-08-20 — this one, and `42 + span * 28/59` in `ProspectPopulationGenerator` — which
    /// put recruiting 6.5 points below bootstrap with a floor 8 points lower. Nothing asserted they
    /// agreed, so the college game decayed from the bootstrap scale to the recruiting scale over six
    /// seasons and settled there; the rating-spread band's tier-gap limb is what caught it. One
    /// expression, so a change to the scale cannot move one intake path without the other.
    static func baseRating(strength: Rating, tier: Tier) -> Int {
        let span = strength.value - SharedRules.ratingRange.lowerBound
        switch tier {
        case .college:
            return 50 + span * 25 / 59
        case .pro:
            return 60 + span * 15 / 59
        }
    }
}
