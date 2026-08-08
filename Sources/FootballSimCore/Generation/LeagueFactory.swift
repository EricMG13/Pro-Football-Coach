import Foundation

/// Builds a fresh 32-team league: rosters, contracts, staff and depth charts, all from one seed.
public enum LeagueFactory {

    /// Competitive tiers assigned at generation so the league starts with contenders and
    /// rebuilders rather than 32 identical teams.
    private enum Tier: CaseIterable {
        case contender, solid, mediocre, rebuilding

        var count: Int {
            switch self {
            case .contender: 4
            case .solid: 12
            case .mediocre: 12
            case .rebuilding: 4
            }
        }

        /// Target overall for a starter on this team.
        var starterTarget: ClosedRange<Int> {
            switch self {
            case .contender: 83...89
            case .solid: 77...83
            case .mediocre: 71...77
            case .rebuilding: 65...71
            }
        }

        var reputation: ClosedRange<Int> {
            switch self {
            case .contender: 75...92
            case .solid: 58...74
            case .mediocre: 42...57
            case .rebuilding: 25...41
            }
        }

        var personalities: [AIPersonality] {
            switch self {
            case .contender: [.winNow, .winNow, .balanced]
            case .solid: [.balanced, .winNow, .capHawk]
            case .mediocre: [.balanced, .capHawk, .rebuilder]
            case .rebuilding: [.rebuilder, .rebuilder, .capHawk]
            }
        }
    }

    public static func makeDefaultLeague(
        seed: UInt64,
        userTeamIndex: Int,
        coach: CoachProfile,
        year: Int = 2026,
        settings: LeagueSettings = LeagueSettings()
    ) -> League {
        var rng = SeededRandom(seed: seed)

        var tiers: [Tier] = []
        for tier in Tier.allCases { tiers.append(contentsOf: Array(repeating: tier, count: tier.count)) }
        tiers = rng.shuffled(tiers)

        var teams: [Team] = []
        for (index, entry) in TeamTable.entries.enumerated() {
            let tier = tiers[index]
            teams.append(makeTeam(entry: entry, tier: tier, year: year, rng: &rng))
        }

        let userIndex = min(max(userTeamIndex, 0), teams.count - 1)
        var league = League(
            rng: rng,
            year: year,
            phase: .preseason,
            teams: teams,
            userTeamID: teams[userIndex].id,
            coach: coach,
            settings: settings
        )
        league.standings = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, TeamRecord()) })
        league.freeAgents = makeInitialFreeAgents(year: year, rng: &league.rng)
        return league
    }

    private static func makeTeam(
        entry: TeamTable.Entry,
        tier: Tier,
        year: Int,
        rng: inout SeededRandom
    ) -> Team {
        let personality = rng.pick(tier.personalities)
        var team = Team(
            id: rng.uuid(),
            city: entry.city,
            name: entry.name,
            abbreviation: entry.abbreviation,
            colors: TeamColors(primaryHex: entry.primaryHex, secondaryHex: entry.secondaryHex),
            conference: entry.conference,
            division: entry.division,
            stadiumName: entry.stadium,
            offensiveScheme: rng.pick(OffensiveScheme.allCases),
            defensiveScheme: rng.pick(DefensiveScheme.allCases),
            reputation: rng.int(in: tier.reputation),
            ownerPatience: rng.int(in: 2...5),
            aiPersonality: personality,
            staffBudget: rng.int(in: LeagueRules.staffBudgetRange)
        )

        team.roster = makeRoster(tier: tier, personality: personality, year: year, rng: &rng)
        team.staff = makeStaff(team: team, tier: tier, rng: &rng)
        team.autoSortDepthChart()
        return team
    }

    private static func makeRoster(
        tier: Tier,
        personality: AIPersonality,
        year: Int,
        rng: inout SeededRandom
    ) -> [Player] {
        var roster: [Player] = []

        for position in Position.allCases {
            for slot in 0..<position.rosterTarget {
                // Talent falls off behind the starters — depth is where teams differ.
                let starters = position.starterCount
                let falloff: Int
                if slot < starters {
                    falloff = slot * 2
                } else {
                    falloff = starters * 2 + (slot - starters + 1) * 3
                }
                let base = rng.int(in: tier.starterTarget)
                let target = (base - falloff).clampedToRating()
                let age = PlayerFactory.age(for: position, personality: personality, &rng)
                var player = PlayerFactory.make(
                    position: position,
                    age: age,
                    targetOverall: target,
                    year: year,
                    rng: &rng
                )
                player.contract = startingContract(for: player, rng: &rng)
                player.draftOrigin = inventedDraftOrigin(for: player, year: year, rng: &rng)
                roster.append(player)
            }
        }

        // Practice squad: young, cheap, mostly projects.
        for _ in 0..<LeagueRules.practiceSquadSize {
            let position = rng.pick(Position.allCases.filter { !$0.isSpecialist })
            let target = (rng.int(in: tier.starterTarget) - rng.int(in: 11...17)).clampedToRating()
            var player = PlayerFactory.make(
                position: position,
                age: rng.int(in: 21...24),
                targetOverall: target,
                year: year,
                rng: &rng
            )
            player.isOnPracticeSquad = true
            player.contract = ContractPricer.minimumContract(age: player.age)
            roster.append(player)
        }

        return roster
    }

    /// Gives a generated veteran a plausible draft history. Without it every player on a
    /// brand-new league reads "Undrafted", which looks like a bug on a thirteen-year starter.
    private static func inventedDraftOrigin(
        for player: Player,
        year: Int,
        rng: inout SeededRandom
    ) -> DraftOrigin {
        let draftYear = year - player.yearsPro
        // Better players plausibly went earlier, with plenty of noise so the board is not a
        // straight line from overall to draft slot.
        let expectedRound = Double(90 - player.overall) / 5.5 + rng.gaussian(mean: 0, sd: 2.1)
        let round = Int(expectedRound.rounded())

        guard round >= 1 else {
            return DraftOrigin(year: draftYear, round: 1, pickInRound: rng.int(in: 1...8))
        }
        guard round <= LeagueRules.draftRounds else {
            // Undrafted free agents are a real and common origin for fringe players.
            return DraftOrigin(year: draftYear, round: 0, pickInRound: 0)
        }
        return DraftOrigin(
            year: draftYear,
            round: round,
            pickInRound: rng.int(in: 1...LeagueRules.teamCount)
        )
    }

    /// Existing deals are partly used up, so contracts expire on a stagger rather than all at once.
    private static func startingContract(for player: Player, rng: inout SeededRandom) -> Contract {
        var contract = ContractPricer.marketContract(for: player, rng: &rng)
        let elapsed = rng.int(in: 0...(contract.years - 1))
        contract.yearsElapsed = elapsed
        return contract
    }

    private static func makeStaff(team: Team, tier: Tier, rng: inout SeededRandom) -> [StaffMember] {
        let ratingRange: ClosedRange<Int>
        switch tier {
        case .contender: ratingRange = 72...92
        case .solid: ratingRange = 62...84
        case .mediocre: ratingRange = 52...76
        case .rebuilding: ratingRange = 45...68
        }

        return StaffRole.allCases.map { role in
            let (first, last) = NameBank.fullName(&rng)
            // Most coordinators know the scheme their team runs; some are a mismatched hire.
            let matches = rng.chance(0.7)
            return StaffMember(
                id: rng.uuid(),
                firstName: first,
                lastName: last,
                role: role,
                age: rng.int(in: 34...64),
                rating: rng.int(in: ratingRange),
                offensiveScheme: role == .offensiveCoordinator
                    ? (matches ? team.offensiveScheme : rng.pick(OffensiveScheme.allCases))
                    : nil,
                defensiveScheme: role == .defensiveCoordinator
                    ? (matches ? team.defensiveScheme : rng.pick(DefensiveScheme.allCases))
                    : nil,
                trait: rng.chance(0.3) ? rng.pick(StaffTrait.allCases) : nil,
                salary: rng.int(in: 1_200_000...6_500_000),
                contractYears: rng.int(in: 1...3)
            )
        }
    }

    /// A thin street free-agent pool so in-season injury replacements exist from day one.
    private static func makeInitialFreeAgents(year: Int, rng: inout SeededRandom) -> [Player] {
        (0..<45).map { _ in
            let position = rng.pick(Position.allCases)
            return PlayerFactory.make(
                position: position,
                age: rng.int(in: 24...33),
                targetOverall: rng.int(in: 55...70),
                year: year,
                rng: &rng
            )
        }
    }
}
