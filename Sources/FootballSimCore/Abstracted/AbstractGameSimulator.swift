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

    public static func play(
        _ game: ScheduledGame,
        in state: GameState,
        tacticalPlans: [UUID: TacticalPlan]
    ) -> GameSummary {
        let home = profile(for: game.homeID, tier: game.tier, in: state)
        let away = profile(for: game.awayID, tier: game.tier, in: state)
        let homePlan = tacticalPlans[game.homeID] ?? .balanced
        let awayPlan = tacticalPlans[game.awayID] ?? .balanced
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: state.league.seed,
            scope: .game,
            identifier: game.id
        ))
        let baseline = CompetitionRules.baselinePoints(for: game.tier)
        let deviation = CompetitionRules.scoreDeviation(for: game.tier)
        // `02` §8.1. A tradition's home-field effect is rating points, converted here at the same
        // scale every other rating difference uses, so the loudest week in a programme's year is
        // worth what the generator said it was rather than nothing.
        let traditionBonus = Double(TraditionEffects.homeFieldBonus(
            home: game.homeID, against: game.awayID, week: game.week, in: state
        )) * CompetitionRules.strengthPointScale
        var homeScore = score(
            expectation: baseline
                + Double(home.offense - away.defense) * CompetitionRules.strengthPointScale
                + CompetitionRules.homeFieldPoints
                + traditionBonus
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
        if homeScore == awayScore {
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
            points: homeScore,
            offense: home.offense,
            opposingDefense: away.defense,
            scheme: home.scheme.offense,
            tacticalPlan: homePlan,
            using: &rng
        )
        let awayStats = teamStatistics(
            points: awayScore,
            offense: away.offense,
            opposingDefense: home.defense,
            scheme: away.scheme.offense,
            tacticalPlan: awayPlan,
            using: &rng
        )
        // `02` §3.11. The counters are derived from the totals above rather than drawn, so the box
        // score cannot contradict the team line it came from and no seeded output moves because it
        // exists. The two contexts are computed first because each side's defence is scored from
        // what the *other* side gave up — a defence's sacks are the offence's sacks taken, exactly,
        // rather than approximately.
        let homeContext = AbstractBoxScore.context(for: homeStats, opposingDefense: away.defense)
        let awayContext = AbstractBoxScore.context(for: awayStats, opposingDefense: home.defense)
        let homeTouchdowns = max(0, homeScore / CompetitionRules.touchdownPointEstimate)
        let awayTouchdowns = max(0, awayScore / CompetitionRules.touchdownPointEstimate)
        let statistics = AbstractBoxScore.offensiveLines(
            roster: home.roster, statistics: homeStats, context: homeContext,
            touchdowns: homeTouchdowns
        ) + AbstractBoxScore.offensiveLines(
            roster: away.roster, statistics: awayStats, context: awayContext,
            touchdowns: awayTouchdowns
        ) + AbstractBoxScore.defensiveLines(
            roster: home.roster, opponentContext: awayContext,
            opponentPlays: CompetitionRules.abstractedPlaysPerGame
        ) + AbstractBoxScore.defensiveLines(
            roster: away.roster, opponentContext: homeContext,
            opponentPlays: CompetitionRules.abstractedPlaysPerGame
        )
        return GameSummary(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStatistics: withCounters(homeStats, homeContext),
            awayStatistics: withCounters(awayStats, awayContext),
            homeParticipantIDs: home.roster.map(\.id),
            awayParticipantIDs: away.roster.map(\.id),
            playerStatistics: statistics.filter { !$0.isEmpty }
        )
    }

    /// The team line with its derived counters attached, so the team record and the player lines
    /// carry the same numbers rather than two versions of them.
    private static func withCounters(
        _ statistics: TeamGameStatistics,
        _ context: AbstractBoxScore.TeamContext
    ) -> TeamGameStatistics {
        TeamGameStatistics(
            points: statistics.points,
            offensiveYards: statistics.offensiveYards,
            passingYards: statistics.passingYards,
            rushingYards: statistics.rushingYards,
            turnovers: statistics.turnovers,
            sacksAllowed: context.sacksAllowed,
            interceptionsThrown: context.interceptionsThrown,
            penalties: context.penalties,
            penaltyYards: context.penaltyYards
        )
    }

    private static func profile(for id: UUID, tier: Tier, in state: GameState) -> TeamProfile {
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
        let roster = rosterIDs.compactMap { id in
            state.people.playerLifecycle[id]?.isAvailable == true ? state.players[id] : nil
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
        points: Int,
        offense: Int,
        opposingDefense: Int,
        scheme: OffensiveScheme,
        tacticalPlan: TacticalPlan,
        using rng: inout SeededRandom
    ) -> TeamGameStatistics {
        let expectedYards = CompetitionRules.baselineOffensiveYards
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
        return TeamGameStatistics(
            points: points,
            offensiveYards: yards,
            passingYards: passingYards,
            rushingYards: yards - passingYards,
            turnovers: rng.int(in: CompetitionRules.turnoverRange)
        )
    }

}
