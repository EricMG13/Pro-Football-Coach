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
    ]

    /// Metrics this suite asserts today.
    static let coveredMetrics = ["points per game"]

    /// The rest, with the reason each cannot be asserted yet.
    ///
    /// `GameSummary` is the interface both models publish, and it carries points, yards, a
    /// pass/rush split, turnovers and per-player yardage lines. Every metric below needs something
    /// the abstracted model does not produce at all — it never simulates a play, a drive or a kick —
    /// so covering them is a change to that model, not a change to this suite.
    static let uncoveredMetrics: [(metric: String, blockedOn: String)] = [
        ("yards per play", "the abstracted model produces no play count"),
        ("completion rate", "the abstracted model produces no pass attempts"),
        ("sack rate", "the abstracted model produces no sacks"),
        ("turnover rate", "the abstracted model draws turnovers from a flat range, unconditioned"),
        ("explosive-play rate", "the abstracted model produces no per-play yardage"),
        ("field-goal accuracy by distance bucket", "the abstracted model produces no kicks"),
        ("home advantage", "measured as a win rate; awaiting its own pass"),
        ("fourth-quarter scoring share", "the abstracted model produces no clock"),
        ("drive-outcome distribution", "the abstracted model produces no drives"),
        ("target/carry distribution across the depth chart",
         "the abstracted model splits yardage evenly across a prefix of the depth chart"),
    ]

    /// One bootstrapped world per tier. Fixed, so a failure is reproducible and a pass is not a
    /// lucky draw.
    static let worldSeed: UInt64 = 90_210

    /// Games sampled per tier: the first `sampledGames` fixtures of the tier's regular season.
    ///
    /// Stated rather than silent. The professional slate is 272 fixtures and so runs whole; the
    /// college slate is 804 and is cut to a fixed prefix, because the detailed model has to play
    /// every sampled fixture on top of the abstracted one. A prefix rather than a sample keeps the
    /// set deterministic, and 320 fixtures is 640 team-games — enough that the interval is narrower
    /// than the margin, which is the only sample-size requirement TOST has.
    static let sampledGames = 320
}

/// Both models' output for one tier, at the interface they share.
private struct TwoTierSample {
    var abstractedTeamPoints: [Double] = []
    var detailedTeamPoints: [Double] = []
}

private func collectTwoTierSample(tier: Tier) -> TwoTierSample {
    let state = GameState.bootstrap(seed: TwoTierConsistency.worldSeed)
    var sample = TwoTierSample()
    let games = state.competition.currentSchedule.games
        .filter { $0.tier == tier }
        .prefix(TwoTierConsistency.sampledGames)

    for game in games {
        let abstracted = AbstractGameSimulator.play(game, in: state)
        sample.abstractedTeamPoints.append(Double(abstracted.homeScore))
        sample.abstractedTeamPoints.append(Double(abstracted.awayScore))

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
        sample.detailedTeamPoints.append(Double(record.homeScore))
        sample.detailedTeamPoints.append(Double(record.awayScore))
    }
    return sample
}

private func personnel(ids: [UUID], in state: GameState) -> SnapPersonnel {
    DepthChart.personnel(roster: ids.compactMap { state.players[$0] }, plan: nil)
}

/// A compact description of a team-score sample: mean, spread and both tails.
private func shape(_ values: [Double]) -> String {
    let estimate = meanEstimate(values)
    let shutouts = values.filter { $0 == 0 }.count
    let fifties = values.filter { $0 >= 50 }.count
    return String(format: "mean=%.2f sd=%.2f min=%.0f max=%.0f shutouts=%.3f fifty-plus=%.3f",
                  estimate.value, estimate.standardDeviation,
                  values.min() ?? 0, values.max() ?? 0,
                  Double(shutouts) / Double(max(values.count, 1)),
                  Double(fifties) / Double(max(values.count, 1)))
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

/// Half the width of the metric's calibration band, or nil if the metric has no band in this tier.
private func equivalenceMargin(metric: String, tier: Tier) -> Double? {
    let bands = tier == .pro ? CalibrationBands.pro : CalibrationBands.college
    return bands.first { $0.metric == metric }.map { ($0.upper - $0.lower) / 2 }
}

func runTwoTierConsistencyTests() {
    suite("Two-tier consistency") {
        test("every metric 03 section 5.1 names is either asserted or named as uncovered") {
            let accounted = Set(TwoTierConsistency.coveredMetrics)
                .union(TwoTierConsistency.uncoveredMetrics.map(\.metric))
            expectEqual(accounted, Set(TwoTierConsistency.section51Metrics))
            for entry in TwoTierConsistency.uncoveredMetrics {
                expect(!entry.blockedOn.isEmpty, "\(entry.metric) is uncovered for no stated reason")
            }
        }

        for tier in Tier.allCases {
            test("points per team-game agrees between the models — \(tier.rawValue)") {
                guard let margin = equivalenceMargin(metric: "points per team-game", tier: tier) else {
                    expect(false, "no points band for \(tier.rawValue) to derive a margin from")
                    return
                }
                let sample = collectTwoTierSample(tier: tier)
                let abstracted = meanEstimate(sample.abstractedTeamPoints)
                let detailed = meanEstimate(sample.detailedTeamPoints)
                let band = Band("points per team-game agreement", tier: tier, -margin, margin,
                                estimator: .mean,
                                confidence: "derived: half the 01 section 6.5 band width")
                let result = band.test(Estimate.difference(of: abstracted, and: detailed))
                // Both levels and both shapes, not only the difference: a failure has to say
                // which model moved and whether it moved in the mean or in the tails. A mean that
                // agrees over a spread that does not is 01 section 6.3's invisible failure.
                expect(result.passed, result.report
                    + " | abstracted " + shape(sample.abstractedTeamPoints)
                    + " | detailed " + shape(sample.detailedTeamPoints))
            }
        }
    }
}
