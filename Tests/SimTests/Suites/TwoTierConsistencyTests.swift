import Foundation
import FootballSimCore

// The commitment `PRODUCT.md` makes about the off-screen model: a week the player watches and a
// week the player skips have to describe the same sport. `docs/03-MATCH-ENGINE.md` §5.1 names the
// metrics that have to agree.
//
// **TOST on the difference, not a range check.** The instrument is the same one `01-RESEARCH.md`
// §6.2 requires of calibration, applied to a two-sample question: the 90 percent interval around
// (abstracted - detailed) must lie entirely inside a symmetric margin. A point-estimate comparison
// would pass whenever the two models happened to land near each other and would never tighten as
// the sample grew.
//
// **The margin is derived, never chosen.** For a metric with a calibration band, the margin is half
// that band's width — the two models must agree to within the tolerance the project already accepts
// for the metric being recognisable football at all. Picking a margin freehand is `03` §5.2's
// widening, one step earlier in the process.

/// `03` §5.1's list, transcribed. Every entry is either measured below or named in
/// `uncoveredMetrics` with what it is blocked on: a suite that silently covers the two metrics both
/// models happen to expose is the coverage-boundary failure `CLAUDE.md` names.
enum TwoTierConsistency {
    static let section51Metrics = [
        "points per game", "yards per play", "completion rate", "sack rate", "turnover rate",
        "explosive-play rate", "field-goal accuracy by distance bucket", "home advantage",
        "fourth-quarter scoring share", "drive-outcome distribution",
        "target/carry distribution across the depth chart",
        // Not in §5.1's prose list, and asserted anyway: it is the denominator of yards per play,
        // §6.5 bands it in both tiers, and the abstracted model had no notion of a snap until it
        // was added for this suite.
        "offensive plays per game",
    ]

    /// Metrics this suite asserts today.
    static let coveredMetrics = [
        "points per game", "offensive plays per game", "yards per play", "home advantage",
    ]

    /// Tier-metric pairs this suite measures in one tier and cannot measure in the other, because
    /// `01-RESEARCH.md` §6.5 has no row to compose a margin from.
    ///
    /// Named rather than skipped. A metric that is asserted for the professional tier and silently
    /// absent for college would report green over half the game, which is the coverage boundary
    /// becoming the quality boundary. The fix is a canon amendment, not a number chosen here:
    /// `CLAUDE.md`'s doc-first rule says the gap gets answered in `01` first.
    static let canonGaps: [(metric: String, tier: Tier, gap: String)] = [
        ("yards per play", .college,
         "01 section 6.5 states no college pass or rush yards per team-game rows, so no yards per "
             + "play range can be composed; its section 4.9 records the same gap"),
    ]

    /// The rest, with the reason each cannot be asserted yet.
    ///
    /// `GameSummary` is the interface both models publish, and it carries points, yards, a
    /// pass/rush split, turnovers and per-player yardage lines. Every metric below needs something
    /// the abstracted model does not produce at all — it never simulates a play, a drive or a kick —
    /// so covering them is a change to that model, not a change to this suite.
    static let uncoveredMetrics: [(metric: String, blockedOn: String)] = [
        ("completion rate", "the abstracted model produces no pass attempts"),
        ("sack rate", "the abstracted model produces no sacks"),
        ("turnover rate", "the abstracted model draws turnovers from a flat range, unconditioned"),
        ("explosive-play rate", "the abstracted model produces no per-play yardage"),
        ("field-goal accuracy by distance bucket", "the abstracted model produces no kicks"),
        ("fourth-quarter scoring share", "the abstracted model produces no clock"),
        ("drive-outcome distribution", "the abstracted model produces no drives"),
        ("target/carry distribution across the depth chart",
         "the abstracted model splits yardage evenly across a prefix of the depth chart"),
    ]

    /// The worlds each tier is sampled from. Fixed literals, so a failure is reproducible and a
    /// pass is not a lucky draw.
    ///
    /// **Four rather than one because of a rate, not a preference.** A per-team-game mean like
    /// points reaches its margin in a few hundred team-games, but a win rate does not: at p near
    /// 0.55 and a margin of 0.04, the pooled 90 percent interval only fits inside the margin past
    /// roughly 840 games *per model*, and one professional slate is 272. A suite that asserted home
    /// advantage on one world would fail on the width of its own interval and read as a model
    /// divergence — the "both edges" failure `Band.test` names precisely so that this is not
    /// mistaken for the model being off in a direction.
    static let worldSeeds: [UInt64] = [90_210, 90_211, 90_212, 90_213]

    /// Games sampled per tier: the first `sampledGames` fixtures of the tier's regular season.
    ///
    /// Stated rather than silent. The professional slate is 272 fixtures and so runs whole; the
    /// college slate is 804 and is cut to a fixed prefix, because the detailed model has to play
    /// every sampled fixture on top of the abstracted one. A prefix rather than a sample keeps the
    /// set deterministic, and 320 fixtures is 640 team-games — enough that the interval is narrower
    /// than the margin, which is the only sample-size requirement TOST has.
    static let sampledGames = 320
}

/// Whether a summary was a home win, an away win, or a tie.
///
/// Ties leave the denominator rather than counting against the home side, which is how
/// `CalibrationHarness` measures the same rate. Counting a tie as half a win would put the two
/// gates on different definitions of one number.
private func homeWon(_ summary: GameSummary) -> Bool? {
    guard summary.homeScore != summary.awayScore else { return nil }
    return summary.homeScore > summary.awayScore
}

/// Both models' output for one tier, at the interface they share.
///
/// `GameSummary` is that interface — it is what the schedule stores and what every screen reads —
/// so a metric this suite can measure is exactly a metric the rest of the game can see. The
/// detailed side goes through `DetailedGameSummaryBuilder` rather than reading the record directly,
/// because the adapter is the production path and a suite that bypassed it would be comparing
/// something the game never uses.
private struct TwoTierSample {
    var abstracted: [GameSummary] = []
    var detailed: [GameSummary] = []
}

private func collectTwoTierSample(tier: Tier) -> TwoTierSample {
    var sample = TwoTierSample()
    for worldSeed in TwoTierConsistency.worldSeeds {
        collect(tier: tier, worldSeed: worldSeed, into: &sample)
    }
    return sample
}

private func collect(tier: Tier, worldSeed: UInt64, into sample: inout TwoTierSample) {
    let state = GameState.bootstrap(seed: worldSeed)
    let games = state.competition.currentSchedule.games
        .filter { $0.tier == tier }
        .prefix(TwoTierConsistency.sampledGames)

    for game in games {
        let abstracted = AbstractGameSimulator.play(game, in: state)
        sample.abstracted.append(abstracted)

        // The detailed model plays the roster the abstracted model just declared it played, rather
        // than re-deriving eligibility. Two filters that agree today and drift tomorrow would show
        // up here as a model divergence, which is the one thing this suite must not invent.
        let record = GameEngine.play(
            tier: tier,
            stage: game.stage,
            home: personnel(ids: abstracted.homeParticipantIDs, in: state),
            away: personnel(ids: abstracted.awayParticipantIDs, in: state),
            seed: SeededRandom.derive(from: state.league.seed, scope: .game, identifier: game.id)
        )
        sample.detailed.append(DetailedGameSummaryBuilder.make(
            record: record,
            homeParticipantIDs: abstracted.homeParticipantIDs,
            awayParticipantIDs: abstracted.awayParticipantIDs
        ))
    }
}

/// Yards per play, one value per team-game.
///
/// A per-team-game mean rather than a ratio of totals, so the existing mean estimator's standard
/// error is the right one and a lopsided game weighs the same as any other. A side that took no
/// snaps contributes nothing rather than a division by zero.
private func yardsPerPlay(_ summaries: [GameSummary]) -> [Double] {
    teamValues(summaries) { $0.offensivePlays > 0
        ? Double($0.offensiveYards) / Double($0.offensivePlays)
        : -1
    }.filter { $0 >= 0 }
}

/// One value per team-game, so a per-team mean has the sample size it claims.
private func teamValues(
    _ summaries: [GameSummary],
    _ value: (TeamGameStatistics) -> Double
) -> [Double] {
    summaries.flatMap { [value($0.homeStatistics), value($0.awayStatistics)] }
}

private func personnel(ids: [UUID], in state: GameState) -> SnapPersonnel {
    DepthChart.personnel(roster: ids.compactMap { state.players[$0] }, plan: nil)
}

/// A compact description of a per-team-game sample: mean, spread and both tails.
///
/// The tails are percentiles rather than thresholds, so the same line reads correctly for every
/// metric. An earlier version counted shutouts and fifty-point games, which says something about
/// points and nothing at all about plays.
private func shape(_ values: [Double]) -> String {
    let estimate = meanEstimate(values)
    let sorted = values.sorted()
    func percentile(_ fraction: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let index = Int((Double(sorted.count - 1) * fraction).rounded())
        return sorted[index]
    }
    return String(format: "mean=%.2f sd=%.2f min=%.0f p05=%.0f p95=%.0f max=%.0f",
                  estimate.value, estimate.standardDeviation,
                  sorted.first ?? 0, percentile(0.05), percentile(0.95), sorted.last ?? 0)
}

private func meanEstimate(_ values: [Double]) -> Estimate {
    guard values.count > 1 else {
        return Estimate(value: values.first ?? 0, sampleSize: values.count,
                        standardDeviation: 0, estimator: .mean)
    }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count - 1)
    return Estimate(value: mean, sampleSize: values.count,
                    standardDeviation: variance.squareRoot(), estimator: .mean)
}

private func pairedMeanDifference(_ abstracted: [Double], _ detailed: [Double]) -> Estimate? {
    guard abstracted.count == detailed.count, abstracted.count > 1 else { return nil }
    return meanEstimate(zip(abstracted, detailed).map { $0.0 - $0.1 })
}

/// Paired jackknife estimate for a difference between two conditional rates. Each model keeps the
/// calibration harness's definition — ties leave that model's denominator — while resampling the
/// shared fixture, so covariance between the two outcomes is retained.
private func pairedRateDifference(_ abstracted: [Bool?], _ detailed: [Bool?]) -> Estimate? {
    guard abstracted.count == detailed.count, abstracted.count > 1 else { return nil }

    func totals(_ outcomes: [Bool?]) -> (hits: Int, trials: Int) {
        let decided = outcomes.compactMap { $0 }
        return (decided.filter { $0 }.count, decided.count)
    }
    func rate(hits: Int, trials: Int) -> Double? {
        trials > 0 ? Double(hits) / Double(trials) : nil
    }

    let first = totals(abstracted)
    let second = totals(detailed)
    guard let firstRate = rate(hits: first.hits, trials: first.trials),
          let secondRate = rate(hits: second.hits, trials: second.trials) else { return nil }

    var leaveOneOut: [Double] = []
    leaveOneOut.reserveCapacity(abstracted.count)
    for index in abstracted.indices {
        let firstTrial = abstracted[index] == nil ? 0 : 1
        let secondTrial = detailed[index] == nil ? 0 : 1
        guard let firstLeaveOneOut = rate(
            hits: first.hits - (abstracted[index] == true ? 1 : 0),
            trials: first.trials - firstTrial
        ), let secondLeaveOneOut = rate(
            hits: second.hits - (detailed[index] == true ? 1 : 0),
            trials: second.trials - secondTrial
        ) else { return nil }
        leaveOneOut.append(firstLeaveOneOut - secondLeaveOneOut)
    }

    let jackknifeMean = leaveOneOut.reduce(0, +) / Double(leaveOneOut.count)
    let squaredError = leaveOneOut.reduce(0) {
        $0 + ($1 - jackknifeMean) * ($1 - jackknifeMean)
    }
    let standardError = (Double(leaveOneOut.count - 1)
        / Double(leaveOneOut.count) * squaredError).squareRoot()
    // Estimate has no custom-standard-error form, so encode the jackknife SE through its mean
    // representation. Band.test reads standardError and does not require its estimator to match.
    return Estimate(
        value: firstRate - secondRate,
        sampleSize: leaveOneOut.count,
        standardDeviation: standardError * Double(leaveOneOut.count).squareRoot(),
        estimator: .mean
    )
}

private func calibrationBand(_ metric: String, _ tier: Tier) -> Band? {
    (tier == .pro ? CalibrationBands.pro : CalibrationBands.college).first { $0.metric == metric }
}

/// Half the width of the metric's calibration band, or nil if the metric has no band in this tier.
private func equivalenceMargin(metric: String, tier: Tier) -> Double? {
    calibrationBand(metric, tier).map { ($0.upper - $0.lower) / 2 }
}

/// Yards per play has no row of its own in `01` §6.5, so its margin is *composed* from the rows
/// that do exist rather than invented: the widest ratio the tier's yardage and plays bands jointly
/// allow. Composing from canon is not the same as adding to it — `CLAUDE.md`'s doc-first rule
/// forbids the second, and a number picked here would be exactly the freehand margin `03` §5.2
/// warns about.
///
/// Returns nil for a tier whose yardage rows §6.5 does not state, which is why college appears in
/// `canonGaps` rather than quietly passing.
private func composedYardsPerPlayMargin(tier: Tier) -> Double? {
    guard let plays = calibrationBand("offensive plays per team-game", tier),
          let pass = calibrationBand("pass yards per team-game", tier),
          let rush = calibrationBand("rush yards per team-game", tier),
          plays.lower > 0, plays.upper > 0 else { return nil }
    return ((pass.upper + rush.upper) / plays.lower - (pass.lower + rush.lower) / plays.upper) / 2
}

/// Asserts that the two models agree on one per-team-game mean, and reports enough on failure to
/// say which model moved and whether it moved in the mean or in the tails.
private func expectAgreement(
    metric: String,
    margin: Double?,
    tier: Tier,
    abstracted: [Double],
    detailed: [Double]
) {
    guard let margin else {
        expect(false, "no band for \(metric) [\(tier.rawValue)] to derive a margin from")
        return
    }
    let band = Band("\(metric) agreement", tier: tier, -margin, margin, estimator: .mean,
                    confidence: "derived: half the 01 section 6.5 band width")
    guard let difference = pairedMeanDifference(abstracted, detailed) else {
        expect(false, "paired samples for \(metric) [\(tier.rawValue)] are empty or misaligned")
        return
    }
    let result = band.test(difference)
    // A mean that agrees over a spread that does not is 01 section 6.3's invisible failure, so the
    // report carries both tails as well as both levels.
    expect(result.passed, result.report
        + " | abstracted " + shape(abstracted)
        + " | detailed " + shape(detailed))
}

/// Asserts that the two models agree on one rate, under the same TOST the means use.
///
/// A rate needs its own entry point because ties can leave each model with a different denominator.
/// The paired jackknife retains fixture covariance while recomputing those conditional rates.
private func expectRateAgreement(
    metric: String,
    margin: Double?,
    tier: Tier,
    abstracted: [GameSummary],
    detailed: [GameSummary]
) {
    guard let margin else {
        expect(false, "no band for \(metric) [\(tier.rawValue)] to derive a margin from")
        return
    }
    func outcomes(_ summaries: [GameSummary]) -> [Bool?] {
        summaries.map(homeWon)
    }
    func totals(_ outcomes: [Bool?]) -> (hits: Int, trials: Int) {
        let decided = outcomes.compactMap { $0 }
        return (decided.filter { $0 }.count, decided.count)
    }
    let band = Band("\(metric) agreement", tier: tier, -margin, margin, estimator: .rate,
                    confidence: "derived: half the 01 section 6.5 band width")
    let abstractedOutcomes = outcomes(abstracted)
    let detailedOutcomes = outcomes(detailed)
    guard let difference = pairedRateDifference(abstractedOutcomes, detailedOutcomes) else {
        expect(false, "paired samples for \(metric) [\(tier.rawValue)] are empty or misaligned")
        return
    }
    let result = band.test(difference)
    let abstractedTotals = totals(abstractedOutcomes)
    let detailedTotals = totals(detailedOutcomes)
    expect(result.passed, result.report + String(
        format: " | abstracted %d/%d = %.4f | detailed %d/%d = %.4f",
        abstractedTotals.hits, abstractedTotals.trials,
        Double(abstractedTotals.hits) / Double(abstractedTotals.trials),
        detailedTotals.hits, detailedTotals.trials,
        Double(detailedTotals.hits) / Double(detailedTotals.trials)
    ))
}

func runTwoTierConsistencyTests() {
    suite("Two-tier consistency") {
        test("paired estimators retain within-fixture covariance") {
            let alignedMean = pairedMeanDifference([1, 2, 3], [0, 1, 2])
            let shuffledMean = pairedMeanDifference([1, 2, 3], [2, 1, 0])
            expectClose(alignedMean?.value ?? .nan, 1, 1e-12)
            expectClose(alignedMean?.standardError ?? .nan, 0, 1e-12)
            expect((shuffledMean?.standardError ?? 0) > 0)

            let alignedRate = pairedRateDifference(
                [true, true, false, false],
                [true, true, false, false]
            )
            let shuffledRate = pairedRateDifference(
                [true, true, false, false],
                [true, false, true, false]
            )
            expectClose(alignedRate?.value ?? .nan, 0, 1e-12)
            expectClose(alignedRate?.standardError ?? .nan, 0, 1e-12)
            expect((shuffledRate?.standardError ?? 0) > 0)
        }

        test("every metric 03 section 5.1 names is either asserted or named as uncovered") {
            let accounted = Set(TwoTierConsistency.coveredMetrics)
                .union(TwoTierConsistency.uncoveredMetrics.map(\.metric))
            expectEqual(accounted, Set(TwoTierConsistency.section51Metrics))
            for entry in TwoTierConsistency.uncoveredMetrics {
                expect(!entry.blockedOn.isEmpty, "\(entry.metric) is uncovered for no stated reason")
            }
            // A tier-metric pair can only be skipped if it is named here, and only if the metric is
            // genuinely asserted in the other tier. A gap entry for a metric nothing measures would
            // be a way to retire a metric without saying so.
            for gap in TwoTierConsistency.canonGaps {
                expect(!gap.gap.isEmpty, "\(gap.metric) [\(gap.tier.rawValue)] names no gap")
                expect(TwoTierConsistency.coveredMetrics.contains(gap.metric),
                       "\(gap.metric) is listed as a tier gap but is not asserted in any tier")
            }
        }

        for tier in Tier.allCases {
            // One world per tier, played once by each model. Both metric tests read the same
            // sample, because bootstrapping and replaying a season is the expensive part and
            // running it twice would buy nothing but a second draw from the same distribution.
            let sample = collectTwoTierSample(tier: tier)

            test("points per team-game agrees between the models — \(tier.rawValue)") {
                expectAgreement(
                    metric: "points per team-game",
                    margin: equivalenceMargin(metric: "points per team-game", tier: tier),
                    tier: tier,
                    abstracted: teamValues(sample.abstracted) { Double($0.points) },
                    detailed: teamValues(sample.detailed) { Double($0.points) }
                )
            }

            test("offensive plays per team-game agrees between the models — \(tier.rawValue)") {
                expectAgreement(
                    metric: "offensive plays per team-game",
                    margin: equivalenceMargin(metric: "offensive plays per team-game", tier: tier),
                    tier: tier,
                    abstracted: teamValues(sample.abstracted) { Double($0.offensivePlays) },
                    detailed: teamValues(sample.detailed) { Double($0.offensivePlays) }
                )
            }

            test("home advantage agrees between the models — \(tier.rawValue)") {
                expectRateAgreement(
                    metric: "home win rate",
                    margin: equivalenceMargin(metric: "home win rate", tier: tier),
                    tier: tier,
                    abstracted: sample.abstracted,
                    detailed: sample.detailed
                )
            }

            test("yards per play agrees between the models — \(tier.rawValue)") {
                guard let margin = composedYardsPerPlayMargin(tier: tier) else {
                    // Not a pass and not a failure: `01` §6.5 states no college yardage rows, so
                    // there is nothing honest to test against until canon says what the range is.
                    let gap = TwoTierConsistency.canonGaps.first {
                        $0.metric == "yards per play" && $0.tier == tier
                    }
                    expect(gap != nil,
                           "yards per play cannot be measured for \(tier.rawValue) and the gap is "
                               + "not named in canonGaps")
                    return
                }
                expectAgreement(
                    metric: "yards per play",
                    margin: margin,
                    tier: tier,
                    abstracted: yardsPerPlay(sample.abstracted),
                    detailed: yardsPerPlay(sample.detailed)
                )
            }
        }
    }
}
