import Foundation

/// Every constant the snap resolver reads.
///
/// `03-MATCH-ENGINE.md` opens: "The engine is pure Swift with zero `import SwiftUI`. It runs
/// headless, and **every number below lives in a rules module rather than inline.**" This is that
/// module.
///
/// **These numbers are not calibrated.** P3 builds the mechanism; P4 owns the bands and tunes them
/// under TOST. A P3 that tuned by eye would make P4's TOST a formality over numbers already fitted
/// to it, so the values here are deliberately plain starting points and `docs/STATUS.md` says so.
public enum MatchupRules {
    // MARK: - Situation

    /// Inside this many yards from the goal line is the red zone. A `02` §3.1 call-in trigger.
    public static let redZoneYards = 20

    /// Distance at or beyond which third down counts as "and long". A `02` §3.1 call-in trigger.
    public static let longYardage = 7

    // MARK: - Leverage

    /// The logistic's steepness, in rating points.
    ///
    /// `03` §1.1: "The rating term uses a **logistic** on the difference, not a linear one, so a
    /// 10-point gap matters more in the middle of the scale than at the ends." This is the scale
    /// parameter of that logistic — the rating difference at which the curve is steepest per point.
    /// Smaller means a sharper, more deterministic engine; larger means ratings matter less.
    public static let leverageScale = 12.0

    /// Standard deviation of the noise added to every matchup, in leverage units.
    ///
    /// The single most important number in the engine: it is what makes a worse team able to win.
    /// `03` §5.1's talent-dispersion band is what will pin it in P4.
    public static let leverageNoise = 0.34

    /// How much scheme fit can move a matchup, in leverage units at full fit.
    ///
    /// `02` §6 makes scheme identity "the spine", and "the roster's fit to it modifies every matchup
    /// in the engine". This is the size of that modification.
    public static let schemeFitWeight = 0.18

    /// How much full fatigue costs a player, in leverage units.
    public static let fatigueWeight = 0.22

    /// Home advantage, in leverage units applied to every home matchup before traditions.
    public static let homeAdvantage = 0.08
}
