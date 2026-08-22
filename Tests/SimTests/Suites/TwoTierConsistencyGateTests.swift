import Foundation
import FootballSimCore

// The commitment `PRODUCT.md` makes about the off-screen model: a week the player watches and a
// week the player skips have to describe the same sport. `docs/03-MATCH-ENGINE.md` §5.1 names the
// metrics that have to agree.
//
// **TOST on the difference, not a range check.** The instrument is the same one `01-RESEARCH.md`
// §6.2 requires of calibration, applied to a paired question: the 90 percent interval around
// (abstracted - detailed) must lie entirely inside a symmetric margin. A point-estimate comparison
// would pass whenever the two models happened to land near each other and would never tighten as
// the sample grew.
//
// **The margin is canonical, never chosen.** `03` §4.1 supplies explicit equivalence margins for
// points, yards/play, completion, sacks and turnovers. Metrics without one use half their
// calibration-band width.
// Picking a margin freehand is `03` §5.2's widening, one step earlier in the process.

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
        "points per game", "offensive plays per game", "yards per play", "completion rate",
        "sack rate", "turnover rate", "explosive-play rate", "home advantage",
        "field-goal accuracy by distance bucket", "fourth-quarter scoring share",
        "drive-outcome distribution",
        "target/carry distribution across the depth chart",
    ]

    static let canonGaps: [(metric: String, tier: Tier, gap: String)] = []

    static let uncoveredMetrics: [(metric: String, blockedOn: String)] = []

    /// The controlled worlds used to tune constants and the disjoint worlds used by the committed
    /// gate. A holdout that is also a tuning input only proves the constants can fit their inputs.
    /// Fixed literals keep both phases reproducible.
    ///
    /// **Multiple worlds because of a rate, not a preference.** A per-team-game mean like
    /// points reaches its margin in a few hundred team-games, but a win rate does not: at p near
    /// 0.55 and a margin of 0.04, the pooled 90 percent interval only fits inside the margin past
    /// roughly 840 paired games, and one professional slate is 272. A suite that asserted home
    /// advantage on one world would fail on the width of its own interval and read as a model
    /// divergence — the "both edges" failure `Band.test` names precisely so that this is not
    /// mistaken for the model being off in a direction.
    static let tuningWorldSeeds: [UInt64] = [
        90_210, 90_211, 90_212, 90_213,
        91_210, 91_211, 91_212, 91_213,
        190_210, 190_211, 190_212, 190_213,
        191_210, 191_211, 191_212, 191_213,
        192_210, 192_211, 192_212, 192_213,
    ]
    static let holdoutWorldSeeds: [UInt64] = [
        290_210, 290_211, 290_212, 290_213,
        291_210, 291_211, 291_212, 291_213,
        292_210, 292_211, 292_212, 292_213,
        293_210, 293_211, 293_212, 293_213,
        294_210, 294_211, 294_212, 294_213,
    ]

    /// Games sampled per world and tier. The twenty-world holdout produces 6,400 paired games, or
    /// 12,800 team-games, so the rate and yards-per-play intervals fit inside their margins without
    /// relying on a generated schedule's roster or mismatch composition.
    static let sampledGames = 320
    static let pointsPerGameMargin = 0.75
    static let yardsPerPlayMargin = 0.15
    static let completionRateMargin = 1.5
    static let sackRateMargin = 0.6
    static let turnoverRateMargin = 0.4
    static let depthChartUsageMargin = 0.02
}

private enum TargetUsageBucket: String, CaseIterable {
    case wr1 = "WR1"
    case wr2 = "WR2"
    case wr3Plus = "WR3+"
    case tightEnd = "TE"
    case runningBack = "RB"
    case other
}

private enum CarryUsageBucket: String, CaseIterable {
    case rb1 = "RB1"
    case rb2Plus = "RB2+"
    case quarterback = "QB"
    case other
}

private enum CanonicalDriveOutcome: CaseIterable {
    case touchdown, fieldGoalAttempt, punt, turnover, downs, safety, periodExpiry
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
    var targetBuckets: [UUID: TargetUsageBucket] = [:]
    var carryBuckets: [UUID: CarryUsageBucket] = [:]
}

private func registerUsageBuckets(_ personnel: SnapPersonnel, in sample: inout TwoTierSample) {
    let ranked = { (players: [Player]) in
        players.sorted {
            $0.overall == $1.overall
                ? $0.id.uuidString < $1.id.uuidString
                : $0.overall > $1.overall
        }
    }
    for player in personnel.offense {
        sample.targetBuckets[player.id] = .other
        sample.carryBuckets[player.id] = .other
    }
    for (index, player) in ranked(personnel.offensive(.wideReceiver)).enumerated() {
        sample.targetBuckets[player.id] = index == 0 ? .wr1 : index == 1 ? .wr2 : .wr3Plus
    }
    for player in personnel.offensive(.tightEnd) {
        sample.targetBuckets[player.id] = .tightEnd
    }
    for (index, player) in ranked(personnel.offensive(.runningBack)).enumerated() {
        sample.targetBuckets[player.id] = .runningBack
        sample.carryBuckets[player.id] = index == 0 ? .rb1 : .rb2Plus
    }
    for player in personnel.offensive(.quarterback) {
        sample.carryBuckets[player.id] = .quarterback
    }
}

private func collectTwoTierSample(tier: Tier, worldSeeds: [UInt64]) -> TwoTierSample {
    var sample = TwoTierSample()
    for worldSeed in worldSeeds {
        collect(tier: tier, worldSeed: worldSeed, into: &sample)
    }
    return sample
}

private func collect(tier: Tier, worldSeed: UInt64, into sample: inout TwoTierSample) {
    for fixture in 0..<TwoTierConsistency.sampledGames {
        let ladder = CalibrationHarness.talentLadder(matchup: fixture)
        let home = CalibrationRoster.team(
            skill: ladder.home,
            seed: worldSeed &+ UInt64(fixture)
        )
        let away = CalibrationRoster.team(
            skill: ladder.away,
            seed: worldSeed &+ UInt64(fixture) &+ 500_000
        )
        registerUsageBuckets(home, in: &sample)
        registerUsageBuckets(away, in: &sample)
        let gameSeed = SeededRandom.derive(
            from: worldSeed,
            scope: .game,
            ordinal: fixture
        )
        guard let abstracted = AbstractGameSimulator.play(
            tier: tier,
            home: home,
            away: away,
            seed: gameSeed
        ) else {
            expect(false, "controlled fixture reused a participant across teams")
            return
        }
        sample.abstracted.append(abstracted)

        let record = GameEngine.play(
            tier: tier,
            home: home,
            away: away,
            seed: gameSeed
        )
        sample.detailed.append(DetailedGameSummaryBuilder.make(
            record: record,
            homeParticipantIDs: abstracted.homeParticipantIDs,
            awayParticipantIDs: abstracted.awayParticipantIDs
        ))
    }
}

private func usageRates<Bucket: Hashable>(
    _ summaries: [GameSummary],
    buckets: [UUID: Bucket],
    bucket: Bucket,
    count: (PlayerGameStatistics) -> Int
) -> [Double] {
    summaries.map { summary in
        let total = summary.playerStatistics.reduce(0) { $0 + count($1) }
        guard total > 0 else { return .nan }
        let selected = summary.playerStatistics.reduce(0) { partial, statistics in
            partial + (buckets[statistics.playerID] == bucket ? count(statistics) : 0)
        }
        return Double(selected) / Double(total)
    }
}

/// Yards per play, one value per team-game.
///
/// A per-team-game mean rather than a ratio of totals, so the existing mean estimator's standard
/// error is the right one and a lopsided game weighs the same as any other. A side that took no
/// snaps contributes NaN so the gate fails without shifting the remaining paired observations.
private func yardsPerPlay(_ summaries: [GameSummary]) -> [Double] {
    teamValues(summaries) {
        guard $0.offensivePlays > 0 else { return .nan }
        return Double($0.offensiveYards) / Double($0.offensivePlays)
    }
}

/// One value per team-game, so a per-team mean has the sample size it claims.
private func teamValues(
    _ summaries: [GameSummary],
    _ value: (TeamGameStatistics) -> Double
) -> [Double] {
    summaries.flatMap { [value($0.homeStatistics), value($0.awayStatistics)] }
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
    guard abstracted.count == detailed.count,
          abstracted.count > 1,
          abstracted.allSatisfy(\.isFinite),
          detailed.allSatisfy(\.isFinite) else { return nil }
    return meanEstimate(zip(abstracted, detailed).map { $0.0 - $0.1 })
}

private typealias RateCount = (hits: Int, trials: Int)

private func pairedPercentageDifference(
    _ abstracted: [RateCount],
    _ detailed: [RateCount]
) -> Estimate? {
    guard abstracted.count == detailed.count, abstracted.count > 1,
          (abstracted + detailed).allSatisfy({
              $0.hits >= 0 && $0.trials >= $0.hits
          }) else { return nil }

    func totals(_ counts: [RateCount]) -> RateCount {
        counts.reduce(into: (hits: 0, trials: 0)) {
            $0.hits += $1.hits
            $0.trials += $1.trials
        }
    }
    func percentage(_ count: RateCount) -> Double? {
        count.trials > 0 ? 100 * Double(count.hits) / Double(count.trials) : nil
    }

    let first = totals(abstracted)
    let second = totals(detailed)
    guard let firstPercentage = percentage(first),
          let secondPercentage = percentage(second) else { return nil }

    var leaveOneOut: [Double] = []
    leaveOneOut.reserveCapacity(abstracted.count)
    for index in abstracted.indices {
        guard let firstLeaveOneOut = percentage((
            first.hits - abstracted[index].hits,
            first.trials - abstracted[index].trials
        )), let secondLeaveOneOut = percentage((
            second.hits - detailed[index].hits,
            second.trials - detailed[index].trials
        )) else { return nil }
        leaveOneOut.append(firstLeaveOneOut - secondLeaveOneOut)
    }

    let jackknifeMean = leaveOneOut.reduce(0, +) / Double(leaveOneOut.count)
    let squaredError = leaveOneOut.reduce(0) {
        $0 + ($1 - jackknifeMean) * ($1 - jackknifeMean)
    }
    let standardError = (Double(leaveOneOut.count - 1)
        / Double(leaveOneOut.count) * squaredError).squareRoot()
    return Estimate(
        value: firstPercentage - secondPercentage,
        sampleSize: leaveOneOut.count,
        standardDeviation: standardError * Double(leaveOneOut.count).squareRoot(),
        estimator: .mean
    )
}

private func aggregatePercentageDifference(
    _ abstracted: [RateCount],
    _ detailed: [RateCount]
) -> Estimate? {
    func total(_ counts: [RateCount]) -> RateCount {
        counts.reduce(into: (hits: 0, trials: 0)) {
            $0.hits += $1.hits
            $0.trials += $1.trials
        }
    }
    let first = total(abstracted)
    let second = total(detailed)
    guard first.hits >= 0, first.trials >= first.hits, first.trials > 0,
          second.hits >= 0, second.trials >= second.hits, second.trials > 0 else { return nil }
    let firstRate = Double(first.hits) / Double(first.trials)
    let secondRate = Double(second.hits) / Double(second.trials)
    let standardError = 100 * (
        firstRate * (1 - firstRate) / Double(first.trials)
            + secondRate * (1 - secondRate) / Double(second.trials)
    ).squareRoot()
    return Estimate(
        value: 100 * (firstRate - secondRate),
        sampleSize: 1,
        standardDeviation: standardError,
        estimator: .mean
    )
}

private func weightedConditionalFieldGoalTVD(
    _ abstracted: [RateCount],
    _ detailed: [RateCount]
) -> Double? {
    guard abstracted.count == FieldGoalDistanceBucket.allCases.count,
          detailed.count == FieldGoalDistanceBucket.allCases.count else { return nil }
    let pooledAttempts = zip(abstracted, detailed).reduce(0) { $0 + $1.0.trials + $1.1.trials }
    guard pooledAttempts > 0 else { return nil }
    var distance = 0.0
    for (abstractedBucket, detailedBucket) in zip(abstracted, detailed) {
        let pooled = abstractedBucket.trials + detailedBucket.trials
        guard abstractedBucket.hits >= 0, abstractedBucket.trials >= abstractedBucket.hits,
              detailedBucket.hits >= 0, detailedBucket.trials >= detailedBucket.hits else { return nil }
        guard pooled == 0 || (abstractedBucket.trials > 0 && detailedBucket.trials > 0) else {
            return nil
        }
        guard pooled > 0 else { continue }
        let abstractedRate = Double(abstractedBucket.hits) / Double(abstractedBucket.trials)
        let detailedRate = Double(detailedBucket.hits) / Double(detailedBucket.trials)
        distance += Double(pooled) / Double(pooledAttempts) * abs(abstractedRate - detailedRate)
    }
    return distance
}

private func totalVariationDistance(_ abstracted: [Int], _ detailed: [Int]) -> Double? {
    guard abstracted.count == detailed.count,
          abstracted.allSatisfy({ $0 >= 0 }), detailed.allSatisfy({ $0 >= 0 }) else { return nil }
    let abstractedTotal = abstracted.reduce(0, +)
    let detailedTotal = detailed.reduce(0, +)
    guard abstractedTotal > 0, detailedTotal > 0 else { return nil }
    return 0.5 * zip(abstracted, detailed).reduce(0.0) {
        $0 + abs(Double($1.0) / Double(abstractedTotal) - Double($1.1) / Double(detailedTotal))
    }
}

private func expectTVD(
    metric: String,
    tier: Tier,
    abstracted: [Int],
    detailed: [Int]
) {
    guard let distance = totalVariationDistance(abstracted, detailed) else {
        expect(false, "\(metric) [\(tier.rawValue)] has no comparable observations")
        return
    }
    expect(distance <= 0.05, String(
        format: "%@ [%@]: TVD %.4f exceeds 0.0500 | abstracted %@ | detailed %@",
        metric, tier.rawValue, distance, String(describing: abstracted), String(describing: detailed)
    ))
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

/// Asserts that the two models agree on one per-team-game mean, and reports enough on failure to
/// say which model moved and whether it moved in the mean or in the tails.
private func expectAgreement(
    metric: String,
    margin: Double?,
    tier: Tier,
    abstracted: [Double],
    detailed: [Double],
    confidence: String = "derived: half the 01 section 6.5 band width"
) {
    guard let margin else {
        let missing = "no band for \(metric) [\(tier.rawValue)] to derive a margin from"
        expect(false, missing)
        return
    }
    let band = Band("\(metric) agreement", tier: tier, -margin, margin, estimator: .mean,
                    confidence: confidence)
    guard let difference = pairedMeanDifference(abstracted, detailed) else {
        let misaligned = "paired samples for \(metric) [\(tier.rawValue)] are empty or misaligned"
            + " | detailed " + shape(detailed)
        expect(false, misaligned)
        return
    }
    let result = band.test(difference)
    // A mean that agrees over a spread that does not is 01 section 6.3's invisible failure, so the
    // report carries both tails as well as both levels.
    //
    // Built into a local before the call, never inside `expect`'s `@autoclosure`. Swift 6.3.3's
    // optimizer crashes verifying the SIL when that autoclosure concatenates owned Strings after
    // inlining ("Found outside of lifetime use?!"), and every `expect` in this file follows the
    // same rule for that reason.
    let message = result.report
        + " | abstracted " + shape(abstracted)
        + " | detailed " + shape(detailed)
    expect(result.passed, message)
}

private func expectPercentageAgreement(
    metric: String,
    margin: Double?,
    tier: Tier,
    abstracted: [RateCount],
    detailed: [RateCount],
    confidence: String = "03 section 4.1 explicit equivalence margin"
) {
    guard let margin else {
        expect(false, "no band for \(metric) [\(tier.rawValue)] to derive a margin from")
        return
    }
    let band = Band("\(metric) agreement", tier: tier, -margin, margin, estimator: .rate,
                    confidence: confidence)
    guard let difference = pairedPercentageDifference(abstracted, detailed) else {
        expect(false, "paired counts for \(metric) [\(tier.rawValue)] are invalid or misaligned")
        return
    }
    let result = band.test(difference)
    func totals(_ counts: [RateCount]) -> RateCount {
        counts.reduce(into: (hits: 0, trials: 0)) {
            $0.hits += $1.hits
            $0.trials += $1.trials
        }
    }
    let first = totals(abstracted)
    let second = totals(detailed)
    let message = result.report + String(
        format: " | abstracted %d/%d = %.2f%% | detailed %d/%d = %.2f%%",
        first.hits, first.trials, 100 * Double(first.hits) / Double(first.trials),
        second.hits, second.trials, 100 * Double(second.hits) / Double(second.trials)
    )
    expect(result.passed, message)
}

private func expectAggregatePercentageAgreement(
    metric: String,
    margin: Double,
    tier: Tier,
    abstracted: [RateCount],
    detailed: [RateCount],
    confidence: String
) {
    let band = Band("\(metric) agreement", tier: tier, -margin, margin, estimator: .mean,
                    confidence: confidence)
    guard let difference = aggregatePercentageDifference(abstracted, detailed) else {
        expect(false, "aggregate counts for \(metric) [\(tier.rawValue)] are invalid")
        return
    }
    let result = band.test(difference)
    let message = result.report
    expect(result.passed, message)
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
        let missing = "no band for \(metric) [\(tier.rawValue)] to derive a margin from"
        expect(false, missing)
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
        let misaligned = "paired samples for \(metric) [\(tier.rawValue)] are empty or misaligned"
        expect(false, misaligned)
        return
    }
    let result = band.test(difference)
    let abstractedTotals = totals(abstractedOutcomes)
    let detailedTotals = totals(detailedOutcomes)
    let message = result.report + String(
        format: " | abstracted %d/%d = %.4f | detailed %d/%d = %.4f",
        abstractedTotals.hits, abstractedTotals.trials,
        Double(abstractedTotals.hits) / Double(abstractedTotals.trials),
        detailedTotals.hits, detailedTotals.trials,
        Double(detailedTotals.hits) / Double(detailedTotals.trials)
    )
    expect(result.passed, message)
}

/// The per-tier metric assertions.
///
/// At file scope, taking the tier and its sample, rather than nested inside the suite's tier loop.
/// Swift 6.3.3's optimizer crashes verifying the SIL for `expect`'s `@autoclosure` message when it
/// captures a borrowed `String` — here `tier.rawValue` — through that much closure nesting
/// ("Found outside of lifetime use?!"). Flattening is also how the file reads best: one function
/// per concern, and adding the next metric is one block rather than one more level of indent.
private func assertTwoTierMetrics(tier: Tier, sample: TwoTierSample) {
    let tierName = tier.rawValue

    test("points per team-game agrees between the models — \(tierName)") {
        expectAgreement(
            metric: "points per team-game",
            margin: TwoTierConsistency.pointsPerGameMargin,
            tier: tier,
            abstracted: teamValues(sample.abstracted) { Double($0.points) },
            detailed: teamValues(sample.detailed) { Double($0.points) },
            confidence: "03 section 4.1 explicit equivalence margin"
        )
    }

    test("offensive plays per team-game agrees between the models — \(tierName)") {
        expectAgreement(
            metric: "offensive plays per team-game",
            margin: equivalenceMargin(metric: "offensive plays per team-game", tier: tier),
            tier: tier,
            abstracted: teamValues(sample.abstracted) { Double($0.offensivePlays) },
            detailed: teamValues(sample.detailed) { Double($0.offensivePlays) }
        )
    }

    test("completion percentage agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            summaries.map {
                (
                    $0.homeStatistics.passCompletions + $0.awayStatistics.passCompletions,
                    $0.homeStatistics.passAttempts + $0.awayStatistics.passAttempts
                )
            }
        }
        expectPercentageAgreement(
            metric: "completion percentage",
            margin: TwoTierConsistency.completionRateMargin,
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed)
        )
    }

    test("sack rate agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            summaries.map {
                let sacks = $0.homeStatistics.sacks + $0.awayStatistics.sacks
                return (
                    sacks,
                    sacks + $0.homeStatistics.passAttempts + $0.awayStatistics.passAttempts
                )
            }
        }
        expectPercentageAgreement(
            metric: "sack rate",
            margin: TwoTierConsistency.sackRateMargin,
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed)
        )
    }

    test("turnover rate agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            summaries.map {
                (
                    $0.homeStatistics.turnovers + $0.awayStatistics.turnovers,
                    $0.homeStatistics.offensivePlays + $0.awayStatistics.offensivePlays
                )
            }
        }
        expectPercentageAgreement(
            metric: "turnover rate",
            margin: TwoTierConsistency.turnoverRateMargin,
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed)
        )
    }

    test("explosive run rate agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            summaries.map {
                let home = $0.homeStatistics
                let away = $0.awayStatistics
                return (
                    home.explosiveRuns + away.explosiveRuns,
                    home.offensivePlays - home.passAttempts - home.sacks
                        + away.offensivePlays - away.passAttempts - away.sacks
                )
            }
        }
        expectPercentageAgreement(
            metric: "explosive run rate",
            margin: equivalenceMargin(metric: "explosive run rate", tier: tier).map { 100 * $0 },
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed),
            confidence: "derived: half the 01 section 6.5 band width"
        )
    }

    test("explosive pass rate agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            summaries.map {
                (
                    $0.homeStatistics.explosivePasses + $0.awayStatistics.explosivePasses,
                    $0.homeStatistics.passAttempts + $0.awayStatistics.passAttempts
                )
            }
        }
        expectPercentageAgreement(
            metric: "explosive pass rate",
            margin: equivalenceMargin(metric: "explosive pass rate", tier: tier).map { 100 * $0 },
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed),
            confidence: "derived: half the 01 section 6.5 band width"
        )
    }

    test("home advantage agrees between the models — \(tierName)") {
        expectRateAgreement(
            metric: "home win rate",
            margin: equivalenceMargin(metric: "home win rate", tier: tier),
            tier: tier,
            abstracted: sample.abstracted,
            detailed: sample.detailed
        )
    }

    test("yards per play agrees between the models — \(tierName)") {
        expectAgreement(
            metric: "yards per play",
            margin: TwoTierConsistency.yardsPerPlayMargin,
            tier: tier,
            abstracted: yardsPerPlay(sample.abstracted),
            detailed: yardsPerPlay(sample.detailed),
            confidence: "03 section 4.1 explicit equivalence margin"
        )
    }

    test("field-goal accuracy by distance agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            FieldGoalDistanceBucket.allCases.map { bucket in
                summaries.reduce(into: (hits: 0, trials: 0)) { total, summary in
                    for statistics in [summary.homeStatistics, summary.awayStatistics] {
                        total.hits += statistics.fieldGoals.made(in: bucket)
                        total.trials += statistics.fieldGoals.attempts(in: bucket)
                    }
                }
            }
        }
        guard let distance = weightedConditionalFieldGoalTVD(
            counts(sample.abstracted), counts(sample.detailed)
        ) else {
            expect(false, "field-goal accuracy [\(tierName)] has no comparable attempts")
            return
        }
        expect(distance <= 0.05, String(
            format: "field-goal accuracy [%@]: weighted conditional TVD %.4f exceeds 0.0500 | abstracted %@ | detailed %@",
            tierName, distance, String(describing: counts(sample.abstracted)), String(describing: counts(sample.detailed))
        ))
    }

    test("fourth-quarter scoring share agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [RateCount] {
            summaries.map { ($0.fourthQuarterPoints, $0.regulationPoints) }
        }
        expectAggregatePercentageAgreement(
            metric: "fourth-quarter scoring share",
            margin: 0.321_597,
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed),
            confidence: "01 section 6.5 2022–2024 FBS annual Q4-share half-width"
        )
    }

    test("drive-outcome distribution agrees between the models — \(tierName)") {
        func counts(_ summaries: [GameSummary]) -> [Int] {
            CanonicalDriveOutcome.allCases.map { bucket in
                summaries.reduce(into: 0) { total, summary in
                    let outcomes = summary.driveOutcomes
                    switch bucket {
                    case .touchdown: total += outcomes.count(in: .touchdown)
                    case .fieldGoalAttempt:
                        total += outcomes.count(in: .fieldGoalMade) + outcomes.count(in: .fieldGoalMissed)
                    case .punt: total += outcomes.count(in: .punt)
                    case .turnover: total += outcomes.count(in: .turnover)
                    case .downs: total += outcomes.count(in: .downs)
                    case .safety: total += outcomes.count(in: .safety)
                    case .periodExpiry: total += outcomes.count(in: .periodExpiry)
                    }
                }
            }
        }
        expectTVD(
            metric: "drive-outcome distribution",
            tier: tier,
            abstracted: counts(sample.abstracted),
            detailed: counts(sample.detailed)
        )
    }

    for bucket in TargetUsageBucket.allCases {
        test("target share agrees between the models — \(tierName), \(bucket.rawValue)") {
            expectAgreement(
                metric: "target share \(bucket.rawValue)",
                margin: TwoTierConsistency.depthChartUsageMargin,
                tier: tier,
                abstracted: usageRates(
                    sample.abstracted,
                    buckets: sample.targetBuckets,
                    bucket: bucket,
                    count: \.targets
                ),
                detailed: usageRates(
                    sample.detailed,
                    buckets: sample.targetBuckets,
                    bucket: bucket,
                    count: \.targets
                )
            )
        }
    }

    for bucket in CarryUsageBucket.allCases {
        test("carry share agrees between the models — \(tierName), \(bucket.rawValue)") {
            expectAgreement(
                metric: "carry share \(bucket.rawValue)",
                margin: TwoTierConsistency.depthChartUsageMargin,
                tier: tier,
                abstracted: usageRates(
                    sample.abstracted,
                    buckets: sample.carryBuckets,
                    bucket: bucket,
                    count: \.carries
                ),
                detailed: usageRates(
                    sample.detailed,
                    buckets: sample.carryBuckets,
                    bucket: bucket,
                    count: \.carries
                )
            )
        }
    }
}

/// The coverage accounting: every metric `03` §5.1 names is asserted, named as uncovered, or named
/// as a tier gap. Nothing falls between.
private func assertMetricAccounting() {
    test("tuning and holdout worlds are disjoint") {
        let overlap = Set(TwoTierConsistency.tuningWorldSeeds)
            .intersection(TwoTierConsistency.holdoutWorldSeeds)
        expect(overlap.isEmpty, "tuning and holdout share \(overlap.count) world seeds")
    }

    test("controlled fixtures reject a participant assigned to both teams") {
        let personnel = CalibrationRoster.team(skill: 72, seed: 72_001)
        let summary = AbstractGameSimulator.play(
            tier: .pro,
            home: personnel,
            away: personnel,
            seed: 1
        )
        expect(summary == nil, "a participant was accepted on both teams")
    }

    test("paired means reject non-finite observations") {
        let estimate = pairedMeanDifference([.nan, 1], [1, 1])
        expect(estimate == nil, "a non-finite paired observation reached TOST")
    }

    test("every metric 03 section 5.1 names is either asserted or named as uncovered") {
        let accounted = Set(TwoTierConsistency.coveredMetrics)
            .union(TwoTierConsistency.uncoveredMetrics.map(\.metric))
        expectEqual(accounted, Set(TwoTierConsistency.section51Metrics))
        for entry in TwoTierConsistency.uncoveredMetrics {
            let message = "\(entry.metric) is uncovered for no stated reason"
            expect(!entry.blockedOn.isEmpty, message)
        }
        // A tier-metric pair can only be skipped if it is named here, and only if the metric is
        // genuinely asserted in the other tier. A gap entry for a metric nothing measures would be
        // a way to retire a metric without saying so.
        for gap in TwoTierConsistency.canonGaps {
            let named = "\(gap.metric) [\(gap.tier.rawValue)]"
            expect(!gap.gap.isEmpty, "\(named) names no gap")
            expect(TwoTierConsistency.coveredMetrics.contains(gap.metric),
                   "\(named) is listed as a tier gap but is not asserted in any tier")
        }
    }
}

func runTwoTierConsistencyTests() {
    let worldSeeds = CommandLine.arguments.contains("--two-tier-consistency-tuning")
        ? TwoTierConsistency.tuningWorldSeeds
        : TwoTierConsistency.holdoutWorldSeeds
    suite("Two-tier consistency") {
        assertMetricAccounting()
        for tier in Tier.allCases {
            // One world set per tier, played once by each model. Both metric tests read the same
            // sample, because bootstrapping and replaying seasons is the expensive part.
            assertTwoTierMetrics(
                tier: tier,
                sample: collectTwoTierSample(tier: tier, worldSeeds: worldSeeds)
            )
        }
    }

    suite("abstracted summary statistics") {
        test("detailed summaries classify terminal drive outcomes") {
            let endings: [DriveEnding] = [
                .touchdown, .fieldGoal, .missedFieldGoal, .punt,
                .turnover, .downs, .safety, .endOfHalf, .endOfQuarter,
            ]
            let record = GameRecord(
                homeScore: 0,
                awayScore: 0,
                drives: endings.map {
                    DriveRecord(
                        offense: .home,
                        plays: [],
                        ending: $0,
                        pointsScored: 0,
                        startYardLine: 25
                    )
                },
                tier: .pro
            )
            let summary = DetailedGameSummaryBuilder.make(
                record: record,
                homeParticipantIDs: [],
                awayParticipantIDs: []
            )
            for bucket in DriveOutcomeBucket.allCases {
                expectEqual(summary.driveOutcomes.count(in: bucket), 1, bucket.label)
            }
            expectEqual(summary.driveOutcomes.total, DriveOutcomeBucket.allCases.count)
        }

        test("detailed summaries preserve fourth-quarter scoring") {
            let home = CalibrationRoster.team(skill: 72, seed: 41_001)
            let away = CalibrationRoster.team(skill: 72, seed: 541_001)
            var scoredGame: (record: GameRecord, points: Int)?
            for seed in UInt64(1)...50 {
                let record = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                let points = record.drives.reduce(into: 0) { total, drive in
                    if drive.plays.last?.situation.quarter == 4 { total += drive.pointsScored }
                }
                if points > 0 {
                    scoredGame = (record, points)
                    break
                }
            }
            guard let scoredGame else {
                expect(false, "diagnostic seeds produced no fourth-quarter scoring")
                return
            }
            let summary = DetailedGameSummaryBuilder.make(
                record: scoredGame.record,
                homeParticipantIDs: home.offense.map(\.id) + home.defense.map(\.id),
                awayParticipantIDs: away.offense.map(\.id) + away.defense.map(\.id)
            )
            expectEqual(summary.fourthQuarterPoints, scoredGame.points)
        }

        test("game summaries default drive outcomes") {
            let statistics = TeamGameStatistics(
                points: 0,
                offensiveYards: 0,
                passingYards: 0,
                rushingYards: 0,
                turnovers: 0
            )
            let summary = GameSummary(
                homeScore: 0,
                awayScore: 0,
                homeStatistics: statistics,
                awayStatistics: statistics,
                playerStatistics: []
            )
            expectEqual(summary.driveOutcomes.total, 0)
            for bucket in DriveOutcomeBucket.allCases {
                expectEqual(summary.driveOutcomes.count(in: bucket), 0, bucket.label)
            }
        }

        test("game summaries default fourth-quarter scoring") {
            let statistics = TeamGameStatistics(
                points: 7,
                offensiveYards: 75,
                passingYards: 50,
                rushingYards: 25,
                turnovers: 0
            )
            let summary = GameSummary(
                homeScore: 7,
                awayScore: 0,
                homeStatistics: statistics,
                awayStatistics: TeamGameStatistics(
                    points: 0,
                    offensiveYards: 0,
                    passingYards: 0,
                    rushingYards: 0,
                    turnovers: 0
                ),
                playerStatistics: []
            )
            expectEqual(summary.fourthQuarterPoints, 0)
        }

        test("game summaries project regulation points compatibly") {
            let statistics = TeamGameStatistics(
                points: 7,
                offensiveYards: 75,
                passingYards: 50,
                rushingYards: 25,
                turnovers: 0
            )
            let summary = GameSummary(
                homeScore: 7,
                awayScore: 3,
                homeStatistics: statistics,
                awayStatistics: TeamGameStatistics(
                    points: 3,
                    offensiveYards: 0,
                    passingYards: 0,
                    rushingYards: 0,
                    turnovers: 0
                ),
                playerStatistics: []
            )
            expectEqual(summary.regulationPoints, 10)

            let clamped = GameSummary(
                homeScore: 7,
                awayScore: 3,
                homeStatistics: statistics,
                awayStatistics: statistics,
                regulationPoints: 99,
                playerStatistics: []
            )
            expectEqual(clamped.regulationPoints, 10)

            let lowerClamped = GameSummary(
                homeScore: 7,
                awayScore: 3,
                homeStatistics: statistics,
                awayStatistics: statistics,
                regulationPoints: -1,
                playerStatistics: []
            )
            expectEqual(lowerClamped.regulationPoints, 0)

            var legacy = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(summary)
            ) as! [String: Any]
            legacy.removeValue(forKey: "regulationPoints")
            guard let decoded = try? JSONDecoder.stable().decode(
                GameSummary.self,
                from: JSONSerialization.data(withJSONObject: legacy)
            ) else {
                expect(false, "legacy game summary no longer decodes")
                return
            }
            expectEqual(decoded.regulationPoints, 10)
        }

        test("legacy team statistics default new rate counters") {
            let data = Data(
                #"{"points":21,"offensiveYards":300,"passingYards":200,"rushingYards":100,"turnovers":1,"offensivePlays":64}"#.utf8
            )
            guard let statistics = try? JSONDecoder().decode(TeamGameStatistics.self, from: data) else {
                expect(false, "legacy team statistics no longer decode")
                return
            }
            expectEqual(statistics.passAttempts, 0)
            expectEqual(statistics.passCompletions, 0)
            expectEqual(statistics.sacks, 0)
            expectEqual(statistics.explosivePlays, 0)
            for bucket in FieldGoalDistanceBucket.allCases {
                expectEqual(statistics.fieldGoals.attempts(in: bucket), 0)
                expectEqual(statistics.fieldGoals.made(in: bucket), 0)
            }
        }
    }
}
