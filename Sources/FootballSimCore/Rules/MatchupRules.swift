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

    /// Distance at or under which an early down is a running down.
    ///
    /// Ten, not seven: first-and-ten is the most common snap in football and a caller that treated
    /// it as a passing down threw on almost every play.
    public static let runningDownDistance = 10

    /// Distance at or beyond which a deep shot is on the table.
    public static let deepShotDistance = 8

    // MARK: - Leverage

    /// The logistic's steepness, in rating points.
    ///
    /// `03` §1.1: "The rating term uses a **logistic** on the difference, not a linear one, so a
    /// 10-point gap matters more in the middle of the scale than at the ends." This is the scale
    /// parameter of that logistic — the rating difference at which the curve is steepest per point.
    /// Smaller means a sharper, more deterministic engine; larger means ratings matter less.
    public static let leverageScale = 18.0

    /// Standard deviation of the noise added to every matchup, in leverage units.
    ///
    /// The single most important number in the engine: it is what makes a worse team able to win.
    /// `03` §5.1's talent-dispersion band is what will pin it in P4.
    public static let leverageNoise = 0.38

    /// How much scheme fit can move a matchup, in leverage units at full fit.
    ///
    /// `02` §6 makes scheme identity "the spine", and "the roster's fit to it modifies every matchup
    /// in the engine". This is the size of that modification.
    public static let schemeFitWeight = 0.18

    /// How much full fatigue costs a player, in leverage units.
    public static let fatigueWeight = 0.22

    /// Home advantage, in leverage units applied to every home matchup before traditions.
    public static let homeAdvantage = 0.035

    // MARK: - Assignment

    public static let baseRushers = 4
    public static let minimumRushers = 3
    public static let maximumRushers = 7
    /// What each extra rusher costs the coverage, in leverage units. The cost that makes a blitz a
    /// decision rather than a free choice (`02` §2.2's third test).
    public static let rusherCoverageDrain = 0.09
    public static let receiversInRoute = 4
    public static let runLaneMatchups = 3

    // MARK: - Coverage shells

    // Every shell helps against something and concedes something else. A shell with no cost would
    // always be right, and `02` §2.2's first test for a real decision is that two answers are
    // defensible.
    public static let manCoveragePassHelp = 0.10
    public static let manCoverageRunCost = 0.06
    public static let zoneUnderPassHelp = 0.08
    public static let zoneUnderRunCost = 0.02
    public static let zoneDeepPassHelp = 0.12
    public static let zoneDeepRunCost = 0.10
    public static let preventPassHelp = 0.20
    public static let preventRunCost = 0.24

    // MARK: - Pass

    public static let shortPassAirYards = 5
    public static let midPassAirYards = 12
    public static let deepPassAirYards = 24
    /// Average pressure above which the pocket collapses into a sack.
    public static let sackPressureThreshold = 0.66
    /// How much a maximally poised passer raises that threshold.
    public static let poiseSackRelief = 0.22
    public static let sackYards = -7
    public static let blitzPressureBonus = 0.14
    public static let pressureThrowPenalty = 0.30
    /// How much being open helps the throw, in leverage units at full openness.
    public static let opennessThrowHelp = 0.30

    /// The rating a throw is resolved against, by depth. A deep ball is hard to complete even to an
    /// open receiver, and making depth the difficulty is what keeps incompletions reachable at all.
    public static func throwDifficulty(_ depth: PassDepth) -> Int {
        switch depth {
        case .short: return 68
        case .mid: return 80
        case .deep: return 92
        }
    }
    public static let aggressionThrowBonus = 0.06
    /// Below this the throw is intercepted; below `completionThreshold` it falls incomplete.
    public static let interceptionThreshold = -0.94
    public static let completionThreshold = -0.30
    /// How much a low-decision passer is pulled toward progression order rather than the open man.
    public static let progressionPenalty = 0.25

    // MARK: - Run

    /// Neutral blocking still creates ordinary forward progress; leverage moves the run around it.
    public static let baselineRunYards = 3
    /// Yards per unit of lane leverage.
    public static let laneYardScale = 3.0
    /// Outside runs multiply the lane result, trading certainty for the edge.
    public static let outsideRunVariance = 1.35
    public static let crashRunBonus = 0.10
    public static let aggressionRunBonus = 0.05
    /// Leverage above which the carrier breaks a tackle.
    public static let breakTackleThreshold = 0.40
    /// Yards for the first break. Each successive one is worth a multiple of this, which is what
    /// gives a run distribution its right tail.
    public static let brokenTackleYards = 4
    /// Each successive break is harder. Bounded, because an unbounded chain is a hang with a small
    /// probability and `03` §7's frame budget has no room for one.
    public static let brokenTackleDecay = 0.18
    public static let maximumBrokenTackles = 4

    // MARK: - Kicks

    /// Yards behind the line of scrimmage the ball is spotted, plus the end zone.
    public static let fieldGoalSnapDistance = 17
    /// A kick's difficulty as a rating: `base + distance`, clamped to the scale.
    ///
    /// The first version was `40 + distance`, which made a routine 25-yard attempt a 65-rated
    /// defender and a 55-yarder a 95 — so the harness measured 42 percent against a band of 81 to
    /// 88. Distance still drives it; the base is where a chip shot sits.
    public static let fieldGoalBaseDifficulty = 18

    public static func fieldGoalDifficulty(distanceYards: Int) -> Int {
        Swift.min(Swift.max(fieldGoalBaseDifficulty + distanceYards,
                            SharedRules.ratingRange.lowerBound),
                  SharedRules.ratingRange.upperBound)
    }
    public static let legStrengthHelp = 0.25
    public static let basePuntYards = 34
    public static let puntLegYards = 18
    public static let puntVariance = 6

    // MARK: - Consequence

    public static let fumbleChance = 0.012

    // MARK: - Calibration thresholds

    /// 01 section 6.5 defines a blowout as a margin of 17 or more.
    public static let blowoutMargin = 17
    /// 01 section 6.5 re-bases the explosive bands on these lengths.
    public static let explosiveRunYards = 10
    public static let explosivePassYards = 15

    // MARK: - Scoring

    public static let touchdownPoints = 6
    public static let extraPointPoints = 1
    public static let fieldGoalPoints = 3
    public static let safetyPoints = 2

    // MARK: - Drive and game

    public static let yardsForFirstDown = 10
    public static let kickoffTouchbackYardLine = 25
    /// Where a punt that reaches the goal line spots the receiving team. Without it a deep punt
    /// clamped the receiver to its own 1, which happened on 2 percent of measured punts.
    public static let puntTouchbackYardLine = 20
    /// Inside this many yards from the goal line, a kick is worth attempting.
    public static let fieldGoalRangeYards = 38
    public static let fourthDownGoForItDistance = 2
    public static let fourthDownGoForItTerritory = 50

    /// Bounds. An unbounded loop here is a hang rather than a bug — a resolver that returned zero
    /// yards forever would never reach a fourth down that ended anything — and `03` §7's budgets
    /// have no room for one. Both are far above any real drive or game.
    public static let maximumPlaysPerDrive = 40
    public static let maximumDrivesPerGame = 60
    /// A controlled game may pause repeatedly in a red zone; cap retained decisions so a long
    /// replay cannot make the save grow with unbounded UI history.
    public static let maximumCallInsPerGame = 256
}
