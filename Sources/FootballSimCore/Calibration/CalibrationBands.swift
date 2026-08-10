import Foundation

/// The band tables, transcribed from `01-RESEARCH.md` §6.5.
///
/// **Transcribed, not invented.** Every row carries the confidence grade `01` §0.1 assigned it, so
/// a failure report can say how much the band itself is worth: a `provisional [U]` band failing is
/// a different event from a `[C]` band failing, and treating them alike is how a gate gets widened
/// to make a red light go away.
///
/// `03` §5.2 records what that looks like: the prior suite's overtime band was `0.008…0.14`, a
/// seventeen-fold range. "That is what widening a band to stop a false failure looks like. Under
/// TOST the correct response to a band that will not hold is to fix the model or state the margin
/// honestly, never to widen until green."
///
/// **Not every band in §6.5 is here yet.** The ones that need machinery P3 does not have — per-drive
/// accounting, target shares, overtime, postseason context, non-conference mismatch splits — are
/// listed in `unimplementedMetrics` rather than silently dropped, because a band table that quietly
/// covers two thirds of §6.5 is the coverage-boundary failure `CLAUDE.md` names.
public enum CalibrationBands {
    public static let pro: [Band] = [
        Band("points per team-game", tier: .pro, 20.0, 26.0, estimator: .mean, confidence: "[C]"),
        Band("pass yards per team-game", tier: .pro, 185, 245, estimator: .mean, confidence: "[Q]"),
        Band("rush yards per team-game", tier: .pro, 100, 130, estimator: .mean,
             confidence: "provisional [U]"),
        Band("completion percentage", tier: .pro, 61, 67, estimator: .rate,
             confidence: "provisional [U]"),
        Band("interceptions per team-game", tier: .pro, 0.6, 1.1, estimator: .mean,
             confidence: "provisional [U]"),
        Band("sacks per team-game", tier: .pro, 2.0, 3.1, estimator: .mean,
             confidence: "provisional [U]"),
        Band("field goal percentage", tier: .pro, 81, 88, estimator: .rate, confidence: "[Q]"),
        Band("home win rate", tier: .pro, 0.50, 0.58, estimator: .rate, confidence: "[C]"),
        Band("favourite win rate", tier: .pro, 0.62, 0.72, estimator: .rate, confidence: "[C]"),
        Band("blowout rate", tier: .pro, 0.17, 0.26, estimator: .rate, confidence: "[Q]"),
        Band("offensive plays per team-game", tier: .pro, 60, 68, estimator: .mean,
             confidence: "[P]"),
        Band("Q4 share of points", tier: .pro, 0.22, 0.32, estimator: .rate, confidence: "[P]"),
        Band("explosive run rate", tier: .pro, 0.105, 0.130, estimator: .rate, confidence: "[Q]"),
        Band("explosive pass rate", tier: .pro, 0.125, 0.150, estimator: .rate, confidence: "[Q]"),
        Band("safeties per game", tier: .pro, 0.005, 0.05, estimator: .mean,
             confidence: "provisional [U]"),
        Band("tie rate", tier: .pro, 0.000, 0.020, estimator: .rate, confidence: "[P]"),
    ]

    public static let college: [Band] = [
        Band("points per team-game", tier: .college, 26, 31, estimator: .mean, confidence: "[C]"),
        Band("combined game total", tier: .college, 52, 60, estimator: .mean, confidence: "[Q]"),
        Band("field goal percentage", tier: .college, 72, 79, estimator: .rate, confidence: "[C]"),
        Band("home win rate", tier: .college, 0.60, 0.68, estimator: .rate, confidence: "[C]"),
        Band("favourite win rate", tier: .college, 0.70, 0.78, estimator: .rate, confidence: "[C]"),
        Band("explosive run rate", tier: .college, 0.135, 0.165, estimator: .rate,
             confidence: "[Q]"),
        Band("explosive pass rate", tier: .college, 0.128, 0.158, estimator: .rate,
             confidence: "[Q]"),
        Band("offensive plays per team-game", tier: .college, 67, 75, estimator: .mean,
             confidence: "[ASSUMPTION] blocked on 01 section 4.2"),
    ]

    public static var all: [Band] { pro + college }

    /// Bands in `01` §6.5 that this harness does not yet measure, and what each is waiting on.
    ///
    /// Named rather than dropped. `01` §6.6 clause 3 says every scalar band in §6.5 is gated by
    /// TOST; until that is true, the honest statement is a list of what is missing, not a green
    /// report over the subset that happens to be implemented.
    public static let unimplementedMetrics: [(metric: String, waitingOn: String)] = [
        ("FG percentage, 50+ yards", "distance-bucketed kick accounting"),
        ("best-vs-worst win rate", "a league with a talent ordering — P6's schedule"),
        ("points per drive", "drive-level accounting the harness does not yet aggregate"),
        ("touchdowns of 40+ yards per game", "play-length accounting"),
        ("overtime rate", "overtime, which P6 owns"),
        ("TE target share", "per-player stat lines, which P3 does not produce"),
        ("RB target share", "per-player stat lines"),
        ("max single-receiver target share", "per-player stat lines"),
        ("modal combined total", "a binned distribution and the TVD shape check"),
        ("blowout rate, non-conference mismatch", "schedule context, which P6 owns"),
        ("blowout rate, power conference game", "conference tiering, which P6 owns"),
        ("average margin by context", "schedule context, which P6 owns"),
        ("college tie rate (exactly zero)", "overtime, which P6 owns"),
        ("overtime settled in one period", "overtime, which P6 owns"),
        ("title-capable share of programmes", "a season, which P6 owns"),
        ("college completion percentage, pass/rush yards, sacks, interceptions, points per drive",
         "unset in 01 section 6.5 itself, see its section 4.9"),
    ]
}
