import Foundation

/// How a metric's standard error is computed. `01-RESEARCH.md` §6.2 names both.
public enum EstimatorKind: String, Sendable {
    /// A proportion. `SE = sqrt(p(1-p)/n)`, n the number of trials **for that metric** — attempts,
    /// plays, games — not the number of games in the sample.
    case rate
    /// A per-team-game mean. `SE = s/sqrt(m)`, and **the harness computes s rather than assuming
    /// it**: an engine with realistic means and unrealistically low variance is a classic and
    /// invisible calibration failure.
    case mean
}

/// One acceptance band, from `01-RESEARCH.md` §6.5.
public struct Band: Sendable, Equatable {
    public let metric: String
    public let tier: Tier
    public let lower: Double
    public let upper: Double
    public let estimator: EstimatorKind
    /// `01` §0.1's evidence grade, carried so a failure report can say how much the band itself is
    /// worth. A provisional band failing is a different event from a graded one failing.
    public let confidence: String

    public init(_ metric: String, tier: Tier, _ lower: Double, _ upper: Double,
                estimator: EstimatorKind, confidence: String) {
        self.metric = metric
        self.tier = tier
        self.lower = lower
        self.upper = upper
        self.estimator = estimator
        self.confidence = confidence
    }
}

/// A metric's observed value, with everything TOST needs.
public struct Estimate: Sendable, Equatable {
    public let value: Double
    /// Trials for a rate, team-games for a mean.
    public let sampleSize: Int
    /// Sample standard deviation. Zero for a rate, where the SE comes from the proportion itself.
    public let standardDeviation: Double
    public let estimator: EstimatorKind

    public init(value: Double, sampleSize: Int, standardDeviation: Double,
                estimator: EstimatorKind) {
        self.value = value
        self.sampleSize = sampleSize
        self.standardDeviation = standardDeviation
        self.estimator = estimator
    }

    /// `01` §6.2's standard error.
    public var standardError: Double {
        guard sampleSize > 0 else { return .infinity }
        switch estimator {
        case .rate:
            let p = Swift.min(Swift.max(value, 0), 1)
            return (p * (1 - p) / Double(sampleSize)).squareRoot()
        case .mean:
            return standardDeviation / Double(sampleSize).squareRoot()
        }
    }
}

/// The result of testing one band.
///
/// **TOST, not range membership.** `01` §6.2 and `03` §4.1 both reject range membership as the
/// instrument: "A model whose true home-win rate is 0.62 passes a 0.50…0.60 range check roughly 1
/// run in 6 at n = 600, because the check has no notion of sampling error and does not tighten as n
/// grows. TOST puts the burden on the model."
public struct BandResult: Sendable, Equatable {
    public let band: Band
    public let estimate: Estimate
    public let passed: Bool
    /// Which edge the confidence interval crossed, if any. `01` §6.6 clause 3 requires the failure
    /// message to name it.
    public let violatedEdge: String?

    public var confidenceInterval: (low: Double, high: Double) {
        let half = Band.zNinety * estimate.standardError
        return (estimate.value - half, estimate.value + half)
    }

    /// `01` §6.6 clause 3's failure-message contract: metric, estimate, CI90, band, n, and which
    /// edge was violated.
    ///
    /// The prior suite's `expectIn` printed value and range and neither n nor the interval, "which
    /// is why a noise failure and a real failure look identical today".
    public var report: String {
        let interval = confidenceInterval
        let head = String(format: "%@ [%@]: theta=%.4f CI90=[%.4f, %.4f] band=[%.4f, %.4f] n=%d",
                          band.metric, band.tier.rawValue, estimate.value,
                          interval.low, interval.high, band.lower, band.upper, estimate.sampleSize)
        guard let violatedEdge else { return head + " PASS (\(band.confidence))" }
        return head + " FAIL on the \(violatedEdge) edge (\(band.confidence))"
    }
}

public extension Band {
    /// The two-sided 90 percent normal quantile. `01` §6.2 states 1.645 explicitly; naming it
    /// rather than inlining keeps `CLAUDE.md`'s no-magic-number rule and makes the alpha visible.
    static let zNinety = 1.645

    /// TOST at alpha = 0.05: pass if and only if the 90 percent confidence interval lies entirely
    /// inside the band.
    func test(_ estimate: Estimate) -> BandResult {
        let half = Band.zNinety * estimate.standardError
        let low = estimate.value - half
        let high = estimate.value + half
        let belowFloor = low < lower
        let aboveCeiling = high > upper
        let edge: String?
        switch (belowFloor, aboveCeiling) {
        case (false, false): edge = nil
        case (true, false): edge = "lower"
        case (false, true): edge = "upper"
        // A CI wider than the band fails both ways, and saying so is more useful than picking one:
        // it means the sample is too small to decide, not that the model is off in a direction.
        case (true, true): edge = "both (the interval is wider than the band)"
        }
        return BandResult(band: self, estimate: estimate, passed: edge == nil, violatedEdge: edge)
    }
}

/// Total variation distance between an observed distribution and a target.
///
/// `01` §6.3: "Means are not enough. Two engines can agree on average margin and disagree completely
/// about whether football is a game of 3-point and 40-point results or a game of 17-point results
/// every week — and that difference is precisely what the player experiences."
public enum TotalVariation {
    /// `TVD = 0.5 * sum |p_i - q_i|` over matching bins. Returns 1 — maximally different — if the
    /// shapes do not line up, rather than silently comparing the overlap.
    public static func distance(observed: [Double], target: [Double]) -> Double {
        guard observed.count == target.count, !observed.isEmpty else { return 1 }
        let observedTotal = observed.reduce(0, +)
        let targetTotal = target.reduce(0, +)
        guard observedTotal > 0, targetTotal > 0 else { return 1 }
        var sum = 0.0
        for index in observed.indices {
            sum += Swift.abs(observed[index] / observedTotal - target[index] / targetTotal)
        }
        return sum / 2
    }
}
