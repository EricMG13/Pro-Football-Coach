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
    /// The abstracted canon carries a larger college home effect than the professional one, so the
    /// detailed default must be tier-specific as well.
    public static let proHomeAdvantage = 0.005
    public static let collegeHomeAdvantage = 0.075

    public static func homeAdvantage(for tier: Tier) -> Double {
        tier == .college ? collegeHomeAdvantage : proHomeAdvantage
    }

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

    /// Air yards by depth. A completion gains these plus whatever the receiver makes after it.
    ///
    /// Trimmed from 5/12/24 once completions were arriving at a football rate: the harness measured
    /// 12.8 yards per completion against a real figure near 11.5, which put pass yards at 268
    /// against a 185-245 band and the explosive-pass rate at 0.178 against 0.125-0.150. Both are
    /// the same number seen twice, because an explosive pass is defined by the yardage a completion
    /// gains.
    public static let shortPassAirYards = 4
    public static let midPassAirYards = 11
    public static let deepPassAirYards = 21

    /// Scatter around a depth's air yards.
    ///
    /// **Without this a pass depth had no distribution.** Air yards were a constant per depth, so
    /// every deep completion gained exactly `deepPassAirYards` before the catch and "explosive"
    /// became a step function of the play call rather than a property of the throw: with the deep
    /// figure above `explosivePassYards`, every deep completion was explosive by construction and
    /// the rate simply tracked how often the caller went deep. Shortening the constants moved the
    /// rate the *wrong* way for that reason.
    ///
    /// Real throws of a given depth vary continuously, which is the same thing `runYardDeviation`
    /// says about carries.
    public static let passAirYardDeviation = 6.0
    /// Pressure above which the pocket collapses into a sack, measured on the *worst* protection
    /// duel rather than the average of them.
    ///
    /// Raised from 0.66 when the resolver stopped averaging. The minimum of four draws sits far
    /// below their mean, so the old threshold applied to the new statistic would have sacked the
    /// passer on a quarter of dropbacks. At `leverageNoise` 0.38 across four rushers, this is
    /// roughly where seven percent of dropbacks end in a sack, which is what a 2.0-3.1 per
    /// team-game band asks for over about 34 of them.
    ///
    /// Fitted, not guessed. Two measurements against `CalibrationRoster` — 31.6 percent of
    /// dropbacks at 0.28 and 3.2 percent at 0.70 — determine both parameters of the second-worst
    /// duel's distribution: mean -0.244, deviation 0.305. Roughly seven percent of dropbacks, which
    /// is what a 2.0-3.1 per team-game band asks for over about 34 of them, falls at a total
    /// threshold near 0.69, of which the poise relief supplies 0.11 at an even roster's rating.
    public static let sackPressureThreshold = 0.58

    /// Which protection duel, ranked worst-first from zero, decides whether the pocket collapses.
    ///
    /// One means the second-worst: the pocket goes when more than one protector loses. Zero — the
    /// single worst — hands the pass rush to the roster's weakest lineman and read 10.6 sacks per
    /// team-game against `CalibrationRoster`'s ±18 scatter. An average, or any blend toward one,
    /// makes blitzing counterproductive, because rushers past the front four are linebackers who
    /// lose their duels and pull an average upward.
    public static let protectionCollapseRank = 1
    /// How much a maximally poised passer raises that threshold.
    public static let poiseSackRelief = 0.22
    public static let sackYards = -7
    public static let blitzPressureBonus = 0.14
    public static let pressureThrowPenalty = 0.30
    /// How much being open helps the throw, in leverage units at full openness.
    public static let opennessThrowHelp = 0.30

    /// The rating a throw is resolved against, by depth. A deep ball is hard to complete even to an
    /// open receiver, and making depth the difficulty is what keeps incompletions reachable at all.
    /// How hard a throw of each depth is, on the rating scale a passer's accuracy is measured on.
    ///
    /// **These are not difficulty rankings, they are opponents.** `Leverage` feeds
    /// `accuracy - throwDifficulty` through a logistic scaled to 18 rating points, so the number
    /// here is the rating a passer has to match to make the throw an even proposition. The former
    /// 68/80/92 made an average passer a heavy underdog at mid and deep — `logistic(70 - 80)` is
    /// -0.268 and `logistic(70 - 92)` is -0.545, against a `completionThreshold` of -0.02 — and the
    /// harness duly read 42 percent completions against a band of 61 to 67.
    ///
    /// The spacing was also too wide. Twelve rating points between depths is two thirds of the
    /// logistic's scale, which made a deep ball roughly a one-in-six proposition against a real
    /// figure near two in five. These are spaced to reproduce completion rates by depth, and
    /// `EngineTests` asserts each one rather than only their aggregate — the aggregate is what let
    /// too few completions and too many yards each cancel into a passing-yards band that passed.
    public static func throwDifficulty(_ depth: PassDepth) -> Int {
        switch depth {
        case .short: return 61
        case .mid: return 67
        case .deep: return 75
        }
    }
    public static let aggressionThrowBonus = 0.06
    /// Below this the throw is intercepted; below `completionThreshold` it falls incomplete.
    /// Moved with the completion cut. It sat at -0.94 because the whole throw distribution sat
    /// low: once an average passer is no longer a heavy underdog, both cuts describe a different
    /// distribution and neither can move alone.
    ///
    /// Back-solved from measurement rather than picked. With the completion cut in place the throw
    /// distribution measured a mean near -0.02 against `leverageNoise` of 0.38, and -0.66 caught
    /// 4.6 percent of attempts against a real figure near 2. -0.80 is where two percent falls.
    public static let interceptionThreshold = -0.80
    public static let completionThreshold = -0.02
    /// How much a low-decision passer is pulled toward progression order rather than the open man.
    public static let progressionPenalty = 0.25

    // MARK: - Run

    /// Yards per unit of lane leverage.
    public static let laneYardScale = 3.0

    /// What a neutral carry gains before leverage or contact.
    ///
    /// **Without this the run had no middle.** `Leverage.logistic` returns exactly zero for an even
    /// matchup, by design and by `03` §1.1, so `lane * laneYardScale` was zero and a carry's whole
    /// distribution came from a break-tackle chain gated at `breakTackleThreshold`. The harness read
    /// 1.35 yards per carry against a real 4.3. A back handed the ball with his line neither winning
    /// nor losing still gains ground: the offence knows the play and the defence does not.
    public static let baselineRunYards = 4.0

    /// Per-carry scatter, before contact.
    ///
    /// **Without this the run had no shape.** `lane` is the mean of `runLaneMatchups` duels, so its
    /// own deviation is `leverageNoise` over root three — about 0.22, which `laneYardScale` turns
    /// into two thirds of a yard. Real carries scatter by about six. Averaging the duels destroys
    /// the variance by construction, and no value of `laneYardScale` restores it without also
    /// making a good line gain twenty yards a carry: leverage has to *shift* a distribution rather
    /// than *be* one. `docs/STATUS.md` reached the same conclusion from the other end — "the next
    /// attempt should widen the *model*, not the grid".
    public static let runYardDeviation = 3.6
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
