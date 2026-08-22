import Foundation

public enum AbstractGameSimulator {
    private struct TeamProfile {
        let roster: [Player]
        let prestige: Rating
        let scheme: SchemeIdentity
        let offense: Int
        let defense: Int
    }

    public static func play(_ game: ScheduledGame, in state: GameState) -> GameSummary {
        play(game, in: state, tacticalPlans: [:])
    }

    /// Plays the same controlled personnel and seed as the detailed consistency harness.
    public static func play(
        tier: Tier,
        stage: CompetitionStage = .regularSeason,
        home: SnapPersonnel,
        away: SnapPersonnel,
        seed: UInt64
    ) -> GameSummary? {
        let homeRoster = home.offense + home.defense
        let awayRoster = away.offense + away.defense
        guard Set(homeRoster.map(\.id)).isDisjoint(with: Set(awayRoster.map(\.id))) else {
            return nil
        }
        return play(
            tier: tier,
            stage: stage,
            home: TeamProfile(
                roster: homeRoster,
                prestige: Rating(SharedRules.ratingRange.lowerBound),
                scheme: SchemeIdentity(offense: .proStyle, defense: .fourThree),
                offense: controlledStrength(home.offense),
                defense: controlledStrength(home.defense)
            ),
            away: TeamProfile(
                roster: awayRoster,
                prestige: Rating(SharedRules.ratingRange.lowerBound),
                scheme: SchemeIdentity(offense: .proStyle, defense: .fourThree),
                offense: controlledStrength(away.offense),
                defense: controlledStrength(away.defense)
            ),
            homePlan: .balanced,
            awayPlan: .balanced,
            seed: seed
        )
    }

    public static func play(
        _ game: ScheduledGame,
        in state: GameState,
        tacticalPlans: [UUID: TacticalPlan],
        personnelPlans: [UUID: PersonnelPlan] = [:]
    ) -> GameSummary {
        let home = profile(for: game.homeID, tier: game.tier, in: state,
                           personnelPlan: personnelPlans[game.homeID])
        let away = profile(for: game.awayID, tier: game.tier, in: state,
                           personnelPlan: personnelPlans[game.awayID])
        let homePlan = tacticalPlans[game.homeID] ?? .balanced
        let awayPlan = tacticalPlans[game.awayID] ?? .balanced
        return play(
            tier: game.tier,
            stage: game.stage,
            home: home,
            away: away,
            homePlan: homePlan,
            awayPlan: awayPlan,
            seed: SeededRandom.derive(
                from: state.league.seed,
                scope: .game,
                identifier: game.id
            )
        )
    }

    private static func controlledStrength(_ players: [Player]) -> Int {
        guard !players.isEmpty else { return SharedRules.ratingRange.lowerBound }
        return players.reduce(0) { $0 + $1.overall.value } / players.count
    }

    private static func play(
        tier: Tier,
        stage: CompetitionStage,
        home: TeamProfile,
        away: TeamProfile,
        homePlan: TacticalPlan,
        awayPlan: TacticalPlan,
        seed: UInt64
    ) -> GameSummary {
        var rng = SeededRandom(seed: seed)
        var homeRateRNG = SeededRandom(
            seed: SeededRandom.derive(from: seed, scope: .game, ordinal: 1)
        )
        var awayRateRNG = SeededRandom(
            seed: SeededRandom.derive(from: seed, scope: .game, ordinal: 2)
        )
        var quarterRateRNG = SeededRandom(
            seed: SeededRandom.derive(from: seed, scope: .game, ordinal: 3)
        )
        var driveOutcomeRNG = SeededRandom(
            seed: SeededRandom.derive(from: seed, scope: .game, ordinal: 4)
        )
        var usageRNG = SeededRandom(
            seed: SeededRandom.derive(from: seed, scope: .game, ordinal: 5)
        )
        let baseline = CompetitionRules.baselinePoints(for: tier)
        let deviation = CompetitionRules.scoreDeviation(for: tier)
        var homeScore = score(
            expectation: baseline
                + Double(home.offense - away.defense) * CompetitionRules.strengthPointScale
                + CompetitionRules.homeFieldPoints(for: tier)
                + homePlan.pointAdjustment(against: awayPlan),
            deviation: deviation + homePlan.scoreDeviationAdjustment(),
            using: &rng
        )
        var awayScore = score(
            expectation: baseline
                + Double(away.offense - home.defense) * CompetitionRules.strengthPointScale
                + awayPlan.pointAdjustment(against: homePlan),
            deviation: deviation + awayPlan.scoreDeviationAdjustment(),
            using: &rng
        )
        let regulationPoints = homeScore + awayScore
        // Professional regular-season ties are an allowed outcome. College and every
        // postseason stage continue through bounded overtime so their summaries always
        // identify a winner.
        if homeScore == awayScore,
           tier == .college || stage != .regularSeason {
            let overtimePoints = rng.chance(CompetitionRules.overtimeFieldGoalProbability)
                ? CompetitionRules.overtimeFieldGoalPoints
                : CompetitionRules.overtimeTouchdownPoints
            if rng.chance(CompetitionRules.overtimeHomeWinProbability) {
                homeScore += overtimePoints
            } else {
                awayScore += overtimePoints
            }
        }

        let homeStats = teamStatistics(
            tier: tier,
            points: homeScore,
            offense: home.offense,
            opposingDefense: away.defense,
            scheme: home.scheme.offense,
            tacticalPlan: homePlan,
            using: &rng,
            rateRNG: &homeRateRNG
        )
        let awayStats = teamStatistics(
            tier: tier,
            points: awayScore,
            offense: away.offense,
            opposingDefense: home.defense,
            scheme: away.scheme.offense,
            tacticalPlan: awayPlan,
            using: &rng,
            rateRNG: &awayRateRNG
        )
        let fourthQuarterPoints = (0..<regulationPoints).reduce(into: 0) { total, _ in
            if quarterRateRNG.chance(
                CompetitionRules.baselineFourthQuarterScoringShare(for: tier)
            ) {
                total += 1
            }
        }
        let driveOutcomes = driveOutcomes(tier: tier, using: &driveOutcomeRNG)
        return GameSummary(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStatistics: homeStats,
            awayStatistics: awayStats,
            fourthQuarterPoints: fourthQuarterPoints,
            regulationPoints: regulationPoints,
            driveOutcomes: driveOutcomes,
            homeParticipantIDs: home.roster.map(\.id),
            awayParticipantIDs: away.roster.map(\.id),
            playerStatistics: playerLines(
                roster: home.roster,
                statistics: homeStats,
                using: &usageRNG
            ) + playerLines(
                roster: away.roster,
                statistics: awayStats,
                using: &usageRNG
            )
        )
    }

    private static func driveOutcomes(
        tier: Tier,
        using rng: inout SeededRandom
    ) -> DriveOutcomeStatistics {
        var outcomes = DriveOutcomeStatistics()
        for _ in 0..<CompetitionRules.baselineDriveCount(for: tier) {
            let draw = rng.double01()
            var cumulativeProbability = 0.0
            let bucket = DriveOutcomeBucket.allCases.first { bucket in
                cumulativeProbability += CompetitionRules.baselineDriveOutcomeProbability(
                    for: tier,
                    bucket: bucket
                )
                return draw < cumulativeProbability
            } ?? .periodExpiry
            outcomes.record(bucket)
        }
        // ponytail: outcome shape is independent of score; derive both from shared drives when
        // the abstract simulation becomes possession-resolved.
        return outcomes
    }

    private static func profile(
        for id: UUID,
        tier: Tier,
        in state: GameState,
        personnelPlan: PersonnelPlan?
    ) -> TeamProfile {
        let rosterIDs: [UUID]
        let prestige: Rating
        let scheme: SchemeIdentity
        switch tier {
        case .college:
            let programme = state.programmes[id]
            rosterIDs = (programme?.rosterIDs ?? []).filter {
                CollegeRedshirtSystem.allowsAutomaticAppearance(
                    playerID: $0,
                    programmeID: id,
                    in: state
                )
            }
            prestige = programme?.prestige ?? Rating(SharedRules.ratingRange.lowerBound)
            scheme = programme?.scheme ?? SchemeIdentity(offense: .proStyle, defense: .fourThree)
        case .pro:
            let team = state.proTeams[id]
            rosterIDs = team?.rosterIDs ?? []
            prestige = team?.prestige ?? Rating(SharedRules.ratingRange.lowerBound)
            scheme = team?.scheme ?? SchemeIdentity(offense: .proStyle, defense: .fourThree)
        }
        let availableRoster = rosterIDs.compactMap { id in
            state.people.playerLifecycle[id]?.isAvailable == true ? state.players[id] : nil
        }
        let roster: [Player]
        if let personnelPlan {
            let resolved = personnelPlan.resolve(roster: availableRoster)
            let resolvedIDs = Position.allCases.flatMap { resolved[$0] ?? [] }
            let byID = Dictionary(uniqueKeysWithValues: availableRoster.map { ($0.id, $0) })
            roster = resolvedIDs.compactMap { byID[$0] }
        } else {
            roster = availableRoster
        }
        return TeamProfile(
            roster: roster,
            prestige: prestige,
            scheme: scheme,
            offense: strength(
                of: roster.filter { $0.position.unit == .offense },
                prestige: prestige,
                people: state.people
            ),
            defense: strength(
                of: roster.filter { $0.position.unit == .defense },
                prestige: prestige,
                people: state.people
            )
        )
    }

    private static func strength(
        of players: [Player],
        prestige: Rating,
        people: PeopleState
    ) -> Int {
        guard !players.isEmpty else { return prestige.value }
        let effectiveTotal = players.reduce(0) { total, player in
            let fatigue = people.playerLifecycle[player.id]?.fatigue ?? 0
            let penalty = fatigue * PeopleRules.fatigueStrengthPenaltyMaximum
                / PeopleRules.fatigueRange.upperBound
            return total + max(SharedRules.ratingRange.lowerBound, player.overall.value - penalty)
        }
        return (effectiveTotal / players.count * 4
            + prestige.value) / 5
    }

    private static func score(
        expectation: Double,
        deviation: Double,
        using rng: inout SeededRandom
    ) -> Int {
        min(
            CompetitionRules.maximumTeamScore,
            max(0, Int(rng.gaussian(mean: expectation, sd: deviation).rounded()))
        )
    }

    private static func teamStatistics(
        tier: Tier,
        points: Int,
        offense: Int,
        opposingDefense: Int,
        scheme: OffensiveScheme,
        tacticalPlan: TacticalPlan,
        using rng: inout SeededRandom,
        rateRNG: inout SeededRandom
    ) -> TeamGameStatistics {
        let expectedYards = CompetitionRules.baselineOffensiveYards(for: tier)
            + Double(offense - opposingDefense) * CompetitionRules.strengthYardScale
        let rawYards = Int(rng.gaussian(
            mean: expectedYards,
            sd: CompetitionRules.offensiveYardDeviation
        ).rounded())
        let yards = min(
            CompetitionRules.offensiveYardRange.upperBound,
            max(CompetitionRules.offensiveYardRange.lowerBound, rawYards)
        )
        let passingShare = min(
            85,
            max(
                15,
                CompetitionRules.passingSharePercent(for: scheme)
                    + tacticalPlan.passingShareAdjustment()
            )
        )
        let passingYards = yards * passingShare / 100
        // Preserve the established stream position for yards and play counts while rate metrics
        // use their own per-team stream.
        _ = rng.int(in: CompetitionRules.turnoverRange)
        let plays = min(
            CompetitionRules.playCountRange.upperBound,
            max(CompetitionRules.playCountRange.lowerBound, Int(rng.gaussian(
                mean: CompetitionRules.baselinePlays(for: tier)
                    + tacticalPlan.playCountAdjustment(),
                sd: CompetitionRules.playCountDeviation
            ).rounded()))
        )
        let passDropbacks = max(1, plays * passingShare / 100)
        let sackProbability = min(
            0.20,
            max(
                0.01,
                CompetitionRules.baselineSackProbability(for: tier)
                    + Double(opposingDefense - offense) * CompetitionRules.strengthSackProbabilityScale
            )
        )
        let sacks = (0..<passDropbacks).reduce(into: 0) { total, _ in
            if rateRNG.chance(sackProbability) { total += 1 }
        }
        let passAttempts = max(1, passDropbacks - sacks)
        let completionProbability = min(
            0.85,
            max(
                0.40,
                CompetitionRules.baselineCompletionProbability(for: tier)
                    + Double(offense - opposingDefense)
                        * CompetitionRules.strengthCompletionProbabilityScale
            )
        )
        let passCompletions = (0..<passAttempts).reduce(into: 0) { total, _ in
            if rateRNG.chance(completionProbability) { total += 1 }
        }
        let turnovers = min(
            CompetitionRules.turnoverRange.upperBound,
            (0..<plays).reduce(into: 0) { total, _ in
                if rateRNG.chance(CompetitionRules.baselineTurnoverProbability(for: tier)) {
                    total += 1
                }
            }
        )
        var fieldGoals = FieldGoalStatistics()
        for bucket in FieldGoalDistanceBucket.allCases {
            for _ in 0..<rateRNG.int(in: 0...1) {
                fieldGoals.record(
                    bucket,
                    made: rateRNG.chance(CompetitionRules.baselineFieldGoalAccuracy(
                        for: bucket,
                        tier: tier
                    ))
                )
            }
        }
        let runPlays = max(0, plays - passAttempts - sacks)
        let explosiveRuns = (0..<runPlays).reduce(into: 0) { total, _ in
            if rateRNG.chance(CompetitionRules.baselineExplosiveRunProbability(for: tier)) {
                total += 1
            }
        }
        let explosivePasses = (0..<passAttempts).reduce(into: 0) { total, _ in
            if rateRNG.chance(CompetitionRules.baselineExplosivePassProbability(for: tier)) {
                total += 1
            }
        }
        return TeamGameStatistics(
            points: points,
            offensiveYards: yards,
            passingYards: passingYards,
            rushingYards: yards - passingYards,
            turnovers: turnovers,
            offensivePlays: plays,
            passAttempts: passAttempts,
            passCompletions: passCompletions,
            sacks: sacks,
            explosivePlays: explosiveRuns + explosivePasses,
            explosiveRuns: explosiveRuns,
            explosivePasses: explosivePasses,
            fieldGoals: fieldGoals
        )
    }

    private static func playerLines(
        roster: [Player],
        statistics: TeamGameStatistics,
        using rng: inout SeededRandom
    ) -> [PlayerGameStatistics] {
        var lines: [PlayerGameStatistics] = []
        let ranked = roster.sorted {
            $0.overall == $1.overall
                ? $0.id.uuidString < $1.id.uuidString
                : $0.overall > $1.overall
        }
        let quarterback = ranked.first(where: { $0.position == .quarterback })
        let runners = Array(ranked.filter { $0.position == .runningBack }.prefix(2))
        let receivers = Array(ranked.filter {
            $0.position == .wideReceiver || $0.position == .tightEnd
        }.prefix(4))
        let wideReceivers = receivers.filter { $0.position == .wideReceiver }
        let tightEnds = receivers.filter { $0.position == .tightEnd }
        var targetWeights: [(Player, Double)] = []
        if let wr1 = wideReceivers.first {
            targetWeights.append((wr1, CompetitionRules.wr1TargetShare))
        }
        if wideReceivers.count > 1 {
            targetWeights.append((wideReceivers[1], CompetitionRules.wr2TargetShare))
        }
        if wideReceivers.count > 2 {
            let share = CompetitionRules.wr3PlusTargetShare / Double(wideReceivers.count - 2)
            targetWeights += wideReceivers.dropFirst(2).map { ($0, share) }
        }
        if !tightEnds.isEmpty {
            let share = CompetitionRules.tightEndTargetShare / Double(tightEnds.count)
            targetWeights += tightEnds.map { ($0, share) }
        }
        if !runners.isEmpty {
            let share = CompetitionRules.runningBackTargetShare / Double(runners.count)
            targetWeights += runners.map { ($0, share) }
        }
        var carryWeights = runners.enumerated().map { index, runner in
            (runner, index == 0
                ? CompetitionRules.primaryBackCarryShare
                : CompetitionRules.reserveBackCarryShare / Double(max(1, runners.count - 1)))
        }
        if let quarterback {
            carryWeights.append((quarterback, CompetitionRules.quarterbackCarryShare))
        }
        let targets = distributedCounts(
            total: statistics.passAttempts,
            weights: targetWeights,
            using: &rng
        )
        let carries = distributedCounts(
            total: max(0, statistics.offensivePlays - statistics.passAttempts - statistics.sacks),
            weights: carryWeights,
            using: &rng
        )
        if let quarterback {
            lines.append(PlayerGameStatistics(
                playerID: quarterback.id,
                passingYards: statistics.passingYards,
                touchdowns: max(0, statistics.points / CompetitionRules.touchdownPointEstimate),
                carries: carries[quarterback.id, default: 0]
            ))
        }
        lines.append(contentsOf: distributedLines(
            players: runners,
            total: statistics.rushingYards,
            keyPath: .rushing,
            targets: targets,
            carries: carries
        ))
        lines.append(contentsOf: distributedLines(
            players: receivers,
            total: statistics.passingYards,
            keyPath: .receiving,
            targets: targets,
            carries: carries
        ))
        return lines
    }

    private static func distributedCounts(
        total: Int,
        weights: [(Player, Double)],
        using rng: inout SeededRandom
    ) -> [UUID: Int] {
        let totalWeight = weights.reduce(0) { $0 + max(0, $1.1) }
        guard total > 0, totalWeight > 0 else { return [:] }
        var counts: [UUID: Int] = [:]
        for _ in 0..<total {
            let draw = rng.double01() * totalWeight
            var cumulative = 0.0
            let player = weights.first {
                cumulative += max(0, $0.1)
                return draw < cumulative
            }?.0 ?? weights[weights.count - 1].0
            counts[player.id, default: 0] += 1
        }
        return counts
    }

    private enum YardageKind { case rushing, receiving }

    private static func distributedLines(
        players: [Player],
        total: Int,
        keyPath: YardageKind,
        targets: [UUID: Int],
        carries: [UUID: Int]
    ) -> [PlayerGameStatistics] {
        guard !players.isEmpty else { return [] }
        let share = total / players.count
        let remainder = total % players.count
        return players.enumerated().map { index, player in
            let yards = share + (index < remainder ? 1 : 0)
            switch keyPath {
            case .rushing:
                return PlayerGameStatistics(
                    playerID: player.id,
                    rushingYards: yards,
                    targets: targets[player.id, default: 0],
                    carries: carries[player.id, default: 0]
                )
            case .receiving:
                return PlayerGameStatistics(
                    playerID: player.id,
                    receivingYards: yards,
                    targets: targets[player.id, default: 0],
                    carries: carries[player.id, default: 0]
                )
            }
        }
    }
}
