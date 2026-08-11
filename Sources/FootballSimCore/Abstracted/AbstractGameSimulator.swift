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
        var homeScore = score(
            expectation: baseline
                + Double(home.offense - away.defense) * CompetitionRules.strengthPointScale
                + CompetitionRules.homeFieldPoints
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
        return GameSummary(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStatistics: homeStats,
            awayStatistics: awayStats,
            homeParticipantIDs: home.roster.map(\.id),
            awayParticipantIDs: away.roster.map(\.id),
            playerStatistics: playerLines(roster: home.roster, statistics: homeStats)
                + playerLines(roster: away.roster, statistics: awayStats)
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

    private static func playerLines(
        roster: [Player],
        statistics: TeamGameStatistics
    ) -> [PlayerGameStatistics] {
        var lines: [PlayerGameStatistics] = []
        let ranked = roster.sorted {
            $0.overall == $1.overall
                ? $0.id.uuidString < $1.id.uuidString
                : $0.overall > $1.overall
        }
        if let quarterback = ranked.first(where: { $0.position == .quarterback }) {
            lines.append(PlayerGameStatistics(
                playerID: quarterback.id,
                passingYards: statistics.passingYards,
                touchdowns: max(0, statistics.points / CompetitionRules.touchdownPointEstimate)
            ))
        }
        let runners = Array(ranked.filter { $0.position == .runningBack }.prefix(2))
        lines.append(contentsOf: distributedLines(
            players: runners,
            total: statistics.rushingYards,
            keyPath: .rushing
        ))
        let receivers = Array(ranked.filter {
            $0.position == .wideReceiver || $0.position == .tightEnd
        }.prefix(4))
        lines.append(contentsOf: distributedLines(
            players: receivers,
            total: statistics.passingYards,
            keyPath: .receiving
        ))
        return lines
    }

    private enum YardageKind { case rushing, receiving }

    private static func distributedLines(
        players: [Player],
        total: Int,
        keyPath: YardageKind
    ) -> [PlayerGameStatistics] {
        guard !players.isEmpty else { return [] }
        let share = total / players.count
        let remainder = total % players.count
        return players.enumerated().map { index, player in
            let yards = share + (index < remainder ? 1 : 0)
            switch keyPath {
            case .rushing:
                return PlayerGameStatistics(playerID: player.id, rushingYards: yards)
            case .receiving:
                return PlayerGameStatistics(playerID: player.id, receivingYards: yards)
            }
        }
    }
}
