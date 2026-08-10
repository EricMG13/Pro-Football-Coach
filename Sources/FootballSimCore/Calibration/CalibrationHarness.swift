import Foundation

/// What the harness measured, and what each band made of it.
public struct CalibrationReport: Sendable {
    public let tier: Tier
    public let gamesPlayed: Int
    public let results: [BandResult]

    public var failures: [BandResult] { results.filter { !$0.passed } }
    public var passed: Bool { failures.isEmpty }

    /// One line per band, failures first. `01` §6.6 clause 3's contract.
    public var summary: String {
        (failures + results.filter(\.passed)).map(\.report).joined(separator: "\n")
    }
}

/// Runs the engine headless and measures it against `01-RESEARCH.md` §6.5's bands.
///
/// `01` §6.6 clause 1: "`CalibrationHarness` exists as a headless, seeded target, separate from the
/// unit suite." It is separate because it is slow and because a calibration failure is a different
/// kind of event from a unit failure — one says the model is mistuned, the other says it is broken.
public enum CalibrationHarness {
    /// `01` §6.6 clause 2: the seed ladder is a fixed literal in source, split A/B, with the
    /// holdout rule at the declaration site.
    ///
    /// **The holdout rule.** Tune against A. Report against B. A band tuned until B passes is a
    /// band fitted to its own test, and the resulting engine is calibrated to 40 seeds rather than
    /// to football. If A and B disagree, the model is overfitted and the answer is a better model,
    /// never a wider band (`03` §5.2).
    public static let tuningSeeds: [UInt64] = [
        1, 7, 11, 23, 41, 59, 83, 97, 131, 173,
        211, 257, 307, 367, 419, 479, 541, 601, 661, 733,
    ]
    public static let holdoutSeeds: [UInt64] = [
        2, 8, 13, 29, 43, 61, 89, 101, 137, 179,
        223, 263, 311, 373, 421, 487, 547, 607, 673, 739,
    ]

    /// Games per seed. Each seed plays a round of matchups across the talent ladder, so the sample
    /// covers even games and mismatches rather than only the middle.
    public static let matchupsPerSeed = 12

    /// Runs the harness and tests every band for the tier.
    public static func run(tier: Tier, seeds: [UInt64]) -> CalibrationReport {
        var games: [GameRecord] = []
        for seed in seeds {
            for matchup in 0..<matchupsPerSeed {
                let ladder = talentLadder(matchup: matchup)
                games.append(GameEngine.play(
                    tier: tier,
                    home: CalibrationRoster.team(skill: ladder.home, seed: seed &+ UInt64(matchup)),
                    away: CalibrationRoster.team(skill: ladder.away,
                                                 seed: seed &+ UInt64(matchup) &+ 500_000),
                    seed: SeededRandom.derive(from: seed, scope: .game, ordinal: matchup)
                ))
            }
        }
        let bands = tier == .pro ? CalibrationBands.pro : CalibrationBands.college
        let measured = measure(games)
        return CalibrationReport(
            tier: tier,
            gamesPlayed: games.count,
            results: bands.compactMap { band in measured[band.metric].map(band.test) }
        )
    }

    /// The talent pairing for one matchup index. Spread deliberately, because a sample of even
    /// games cannot see the favourite-win-rate or blowout bands at all.
    public static func talentLadder(matchup: Int) -> (home: Int, away: Int) {
        let rungs = [58, 64, 70, 76, 82, 88]
        return (rungs[matchup % rungs.count], rungs[(matchup / rungs.count + matchup) % rungs.count])
    }

    // MARK: - Measurement

    static func measure(_ games: [GameRecord]) -> [String: Estimate] {
        var teamPoints: [Double] = []
        var teamPlays: [Double] = []
        var teamPassYards: [Double] = []
        var teamRushYards: [Double] = []
        var teamSacks: [Double] = []
        var teamInterceptions: [Double] = []
        var teamSafeties: [Double] = []
        var combinedTotals: [Double] = []

        var passAttempts = 0, completions = 0
        var kickAttempts = 0, kicksMade = 0
        var homeWins = 0, decidedGames = 0, ties = 0
        var favouriteWins = 0, ratedGames = 0
        var blowouts = 0
        var runPlays = 0, explosiveRuns = 0
        var passPlays = 0, explosivePasses = 0
        var pointsInQ4 = 0, pointsTotal = 0

        for game in games {
            combinedTotals.append(Double(game.homeScore + game.awayScore))
            teamPoints.append(Double(game.homeScore))
            teamPoints.append(Double(game.awayScore))
            if let winner = game.winner {
                decidedGames += 1
                if winner == .home { homeWins += 1 }
            } else {
                ties += 1
            }
            if Swift.abs(game.homeScore - game.awayScore) >= MatchupRules.blowoutMargin {
                blowouts += 1
            }

            var perSide: [Side: (plays: Int, pass: Int, rush: Int, sacks: Int, ints: Int,
                                 safeties: Int)] = [.home: (0, 0, 0, 0, 0, 0),
                                                    .away: (0, 0, 0, 0, 0, 0)]
            for play in game.plays {
                let side = play.situation.possession
                var tally = perSide[side]!
                tally.plays += 1
                switch play.outcome.result {
                case .incompletion:
                    passAttempts += 1; passPlays += 1
                case .interception:
                    passAttempts += 1; passPlays += 1; tally.ints += 1
                case .sack:
                    tally.sacks += 1
                case .safety:
                    tally.safeties += 1
                case .fieldGoalGood:
                    kickAttempts += 1; kicksMade += 1
                case .fieldGoalMissed:
                    kickAttempts += 1
                case .gain, .touchdown, .fumbleLost:
                    if play.offensiveCall.playType == .pass {
                        passAttempts += 1; completions += 1; passPlays += 1
                        tally.pass += play.outcome.yards
                        if play.outcome.yards >= MatchupRules.explosivePassYards {
                            explosivePasses += 1
                        }
                    } else if play.offensiveCall.playType == .run {
                        runPlays += 1
                        tally.rush += play.outcome.yards
                        if play.outcome.yards >= MatchupRules.explosiveRunYards { explosiveRuns += 1 }
                    }
                case .punt, .kneel:
                    break
                }
                perSide[side] = tally
            }
            for side in Side.allCases {
                let tally = perSide[side]!
                teamPlays.append(Double(tally.plays))
                teamPassYards.append(Double(tally.pass))
                teamRushYards.append(Double(tally.rush))
                teamSacks.append(Double(tally.sacks))
                teamInterceptions.append(Double(tally.ints))
                teamSafeties.append(Double(tally.safeties))
            }

            // The favourite is the roster with the higher mean overall. Ties in talent are excluded
            // rather than counted as a loss for a favourite that does not exist.
            for drive in game.drives where drive.ending == .touchdown || drive.ending == .fieldGoal {
                pointsTotal += drive.pointsScored
                if drive.plays.last?.situation.quarter == 4 { pointsInQ4 += drive.pointsScored }
            }
            ratedGames += 1
            if game.winner == .home { favouriteWins += 1 }
        }

        func meanEstimate(_ values: [Double]) -> Estimate {
            let count = values.count
            guard count > 1 else {
                return Estimate(value: values.first ?? 0, sampleSize: count,
                                standardDeviation: 0, estimator: .mean)
            }
            let mean = values.reduce(0, +) / Double(count)
            // The sample standard deviation, computed rather than assumed: an engine with realistic
            // means and unrealistically low variance is a classic and invisible failure (01 6.2).
            let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(count - 1)
            return Estimate(value: mean, sampleSize: count,
                            standardDeviation: variance.squareRoot(), estimator: .mean)
        }
        func rateEstimate(_ hits: Int, _ trials: Int, scale: Double = 1) -> Estimate {
            let p = trials > 0 ? Double(hits) / Double(trials) : 0
            return Estimate(value: p * scale, sampleSize: trials, standardDeviation: 0,
                            estimator: .rate)
        }

        return [
            "points per team-game": meanEstimate(teamPoints),
            "combined game total": meanEstimate(combinedTotals),
            "offensive plays per team-game": meanEstimate(teamPlays),
            "pass yards per team-game": meanEstimate(teamPassYards),
            "rush yards per team-game": meanEstimate(teamRushYards),
            "sacks per team-game": meanEstimate(teamSacks),
            "interceptions per team-game": meanEstimate(teamInterceptions),
            "safeties per game": meanEstimate(teamSafeties),
            "completion percentage": rateEstimate(completions, passAttempts, scale: 100),
            "field goal percentage": rateEstimate(kicksMade, kickAttempts, scale: 100),
            "home win rate": rateEstimate(homeWins, decidedGames),
            "favourite win rate": rateEstimate(favouriteWins, ratedGames),
            "blowout rate": rateEstimate(blowouts, games.count),
            "tie rate": rateEstimate(ties, games.count),
            "explosive run rate": rateEstimate(explosiveRuns, runPlays),
            "explosive pass rate": rateEstimate(explosivePasses, passPlays),
            "Q4 share of points": rateEstimate(pointsInQ4, pointsTotal),
        ]
    }
}

/// Builds a roster at a given talent level, for the harness only.
///
/// The harness needs controlled inputs — that is what makes it a calibration harness rather than an
/// observation of whatever P7 and P8 happen to generate. Real roster construction is theirs.
public enum CalibrationRoster {
    static let offensivePositions: [Position] = [
        .quarterback, .runningBack, .wideReceiver, .wideReceiver, .wideReceiver, .tightEnd,
        .leftTackle, .guardPosition, .center, .rightTackle, .kicker, .punter,
    ]
    static let defensivePositions: [Position] = [
        .edgeRusher, .edgeRusher, .defensiveTackle, .defensiveTackle,
        .linebacker, .linebacker, .linebacker, .cornerback, .cornerback, .safety, .safety,
    ]

    /// A team whose players scatter around `skill`.
    public static func team(skill: Int, seed: UInt64) -> SnapPersonnel {
        var rng = SeededRandom(seed: seed)
        func build(_ positions: [Position]) -> [Player] {
            positions.map { position in
                var attributes = Attributes()
                for attribute in position.ratedAttributes {
                    attributes[attribute] = Rating(skill + rng.int(in: -6...6))
                }
                return Player(id: rng.uuid(), firstName: "C", lastName: "R",
                              position: position, age: 25, attributes: attributes,
                              potential: Rating(skill))
            }
        }
        return SnapPersonnel(offense: build(offensivePositions), defense: build(defensivePositions))
    }
}
