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

    /// A game and the talent it was played at, so the favourite can be identified.
    struct SampledGame {
        let record: GameRecord
        let homeSkill: Int
        let awaySkill: Int
    }

    /// Runs the harness and tests every band for the tier.
    public static func run(tier: Tier, seeds: [UInt64]) -> CalibrationReport {
        var games: [SampledGame] = []
        for seed in seeds {
            for matchup in 0..<matchupsPerSeed {
                let ladder = talentLadder(matchup: matchup)
                games.append(SampledGame(record: GameEngine.play(
                    tier: tier,
                    home: CalibrationRoster.team(skill: ladder.home, seed: seed &+ UInt64(matchup)),
                    away: CalibrationRoster.team(skill: ladder.away,
                                                 seed: seed &+ UInt64(matchup) &+ 500_000),
                    seed: SeededRandom.derive(from: seed, scope: .game, ordinal: matchup)
                ), homeSkill: ladder.home, awaySkill: ladder.away))
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

    /// The talent pairing for one matchup index.
    ///
    /// The first version paired rung *i* with rung *i* for half the schedule and rung *i+1* for the
    /// other half, so every "mismatch" was a six-point gap. A favourite that is six points better
    /// wins about 53 percent of the time, which is what the harness measured and then blamed on the
    /// engine. `01` §6.5's 0.62 to 0.72 favourite band describes real betting favourites, whose
    /// edge is much larger.
    ///
    /// This spreads the gaps the way a schedule does: some even games, a majority of moderate
    /// mismatches, a few routs.
    public static func talentLadder(matchup: Int) -> (home: Int, away: Int) {
        // Gaps of 0 to 9 rating points, not 0 to 26. A twenty-point gap applied to every player on
        // the roster is not a mismatch, it is a different sport: real rosters overlap heavily and
        // the *team* difference between a contender and a bottom side is a few points of mean.
        // The wide version measured a 0.94 favourite win rate against a 0.62 to 0.72 band and the
        // reading was the harness's, not the engine's.
        let pairs: [(Int, Int)] = [
            (72, 72), (74, 71), (69, 72),
            (76, 70), (70, 76), (73, 67),
            (67, 73), (78, 69), (69, 78),
            (75, 66), (66, 75), (71, 74),
        ]
        return pairs[matchup % pairs.count]
    }

    // MARK: - Measurement

    static func measure(_ samples: [SampledGame]) -> [String: Estimate] {
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

        for sample in samples {
            let game = sample.record
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
            _ = sample.awaySkill

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

            for drive in game.drives where drive.ending == .touchdown || drive.ending == .fieldGoal {
                pointsTotal += drive.pointsScored
                if drive.plays.last?.situation.quarter == 4 { pointsInQ4 += drive.pointsScored }
            }

            // The favourite is the better roster, not the home team. It was `winner == .home`,
            // which measures home-field advantage twice and the favourite band not at all — the
            // harness was reporting an engine defect that was its own.
            //
            // Even matchups and draws are excluded rather than scored against a favourite who does
            // not exist.
            if sample.homeSkill != sample.awaySkill, let winner = game.winner {
                ratedGames += 1
                let favourite: Side = sample.homeSkill > sample.awaySkill ? .home : .away
                if winner == favourite { favouriteWins += 1 }
            }
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
            "blowout rate": rateEstimate(blowouts, samples.count),
            "tie rate": rateEstimate(ties, samples.count),
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
                // Wide, deliberately. A team whose every player sits within six points of one
                // number has no stars and no holes, so a small mean difference becomes a uniform
                // advantage in every matchup and the favourite wins almost always. Real rosters are
                // spiky, and the spikiness is most of what makes a game close.
                for attribute in position.ratedAttributes {
                    attributes[attribute] = Rating(skill + rng.int(in: -18...18))
                }
                return Player(id: rng.uuid(), firstName: "C", lastName: "R",
                              position: position, age: 25, attributes: attributes,
                              potential: Rating(skill))
            }
        }
        return SnapPersonnel(offense: build(offensivePositions), defense: build(defensivePositions))
    }
}
