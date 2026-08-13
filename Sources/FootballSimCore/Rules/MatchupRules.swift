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
    public static let completionThreshold = -0.02
    /// How much a low-decision passer is pulled toward progression order rather than the open man.
    public static let progressionPenalty = 0.25

    // MARK: - Run

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

    // MARK: - Penalties

    /// Chance a snap draws a flag, before the volatile adjustment. `02` §3.5.
    ///
    /// **Not calibrated.** Like every other number in this module it is a plain starting point; the
    /// harness now measures penalties per team-game, and `03` §5.1 gains a band when a source for
    /// one exists. A rate tuned by eye here would make that band a formality over a number already
    /// fitted to it.
    public static let penaltyChancePerSnap = 0.085

    /// How much a fully volatile roster raises that rate, as a multiplier on the volatile share.
    public static let volatilePenaltyRateBonus = 0.5

    /// How much likelier a volatile player is to be the one flagged. `02` §11.3.3's Discipline bite.
    public static let volatileOffenderWeight = 3

    public static let minorPenaltyYards = 5
    public static let majorPenaltyYards = 10
    public static let severePenaltyYards = 15

    // Relative frequencies. Uniform selection would make pass interference as common as a false
    // start, which is wrong by an order of magnitude and would double the average cost of a flag.
    public static let falseStartWeight = 22
    public static let delayOfGameWeight = 6
    public static let offensiveHoldingWeight = 24
    public static let offsideWeight = 14
    public static let defensiveHoldingWeight = 12
    public static let passInterferenceWeight = 8
    public static let personalFoulWeight = 6

    // MARK: - In-play injuries

    // MARK: - Weather

    /// Leverage a throw loses to the conditions. `02` §3.10.
    public static let windPassPenalty = 0.10
    public static let rainPassPenalty = 0.12
    public static let snowPassPenalty = 0.18

    /// Leverage a kick loses. Wind costs a kick more than it costs a throw, which is why these are
    /// two tables rather than one weather term.
    public static let windKickPenalty = 0.22
    public static let rainKickPenalty = 0.10
    public static let snowKickPenalty = 0.26

    /// How much likelier the ball comes loose.
    public static let windFumbleMultiplier = 1.1
    public static let rainFumbleMultiplier = 1.6
    public static let snowFumbleMultiplier = 1.9

    /// The week by which the season counts as fully late, for the weather draw.
    public static let weatherLateWeek = 16
    public static let clearWeatherShare = 0.74
    /// How much of that share a fully late season gives up.
    public static let lateSeasonClearWeatherLoss = 0.28
    public static let windShareOfAdverse = 0.45
    public static let rainShareOfAdverse = 0.35
    /// How late the season must be before snow is reachable at all.
    public static let snowRequiresLateness = 0.5

    // MARK: - Clock management

    /// Inside this many seconds of the half, a trailing defence stops the clock. `02` §3.9.
    ///
    /// Larger than the offence's window because the side without the ball is the one that needs the
    /// clock: it is buying possessions, not seconds.
    public static let defensiveTimeoutSecondsRemaining = 150

    /// Inside this many seconds, a trailing offence stops it too — late enough that the timeout is
    /// worth more than the twenty-odd seconds it saves.
    public static let offensiveTimeoutSecondsRemaining = 50

    /// Chance a snap hurts somebody. `02` §3.8.
    ///
    /// Per snap across both teams, so roughly one and a half a game at this engine's play counts.
    /// Who it lands on is weighted by durability, which is what makes the rating visible on the
    /// player carrying it rather than only in a team-wide rate. **Not calibrated**: `03` §5.1 has no
    /// in-play injury band, and one invented here would be fitted to the engine that produced it.
    public static let injuryChancePerSnap = 0.012

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

    // MARK: - The conversion

    /// Points a converted two-point try is worth. `02` §3.4.
    public static let twoPointPoints = 2

    /// Yards to the goal line the extra-point kick is snapped from. Through
    /// `fieldGoalSnapDistance` this is a 32-yard kick, which is the routine attempt the difficulty
    /// curve was rebased around.
    public static let extraPointKickYardsToGoal = 15

    /// Yards to the goal line the two-point try is snapped from.
    public static let twoPointYardsToGoal = 2

    /// The seed ordinal the conversion draws under.
    ///
    /// One past the last legal play index, so a try can never collide with a snap's stream and
    /// adding the try cannot shift the drive that produced it — the same reason each snap derives
    /// its own seed rather than sharing the drive's generator.
    public static let conversionSeedOrdinal = maximumPlaysPerDrive

    /// Deficits that two points change the shape of, with the touchdown already on the board.
    ///
    /// The classic chart, and it is arithmetic rather than taste: at 2 the try ties the game, at 5
    /// it makes the next score a field goal, at 10 and 18 it sets up two scores that finish level,
    /// and at 12 and 16 it puts the deficit inside one possession.
    public static let twoPointDeficits: Set<Int> = [2, 5, 10, 12, 16, 18]

    /// Whether the chart says go for two. `02` §3.4.
    ///
    /// Gated on the final quarter because a margin bought in the first is one the remaining three
    /// erase, which is what real charts encode and what keeps the kick the default.
    public static func twoPointIsIndicated(
        deficitAfterTouchdown: Int,
        quarter: Int,
        quarters: Int
    ) -> Bool {
        guard quarter >= quarters else { return false }
        return twoPointDeficits.contains(deficitAfterTouchdown)
    }

    // MARK: - Drive and game

    public static let yardsForFirstDown = 10
    public static let kickoffTouchbackYardLine = 25

    // MARK: - Kickoffs

    /// Chance a deep kickoff reaches the end zone with no return, before leg strength.
    public static let kickoffTouchbackChance = 0.52
    /// How much a maximum leg adds to that chance. The reason leg strength is rated apart from
    /// accuracy: it buys touchbacks, and touchbacks are field position.
    public static let legStrengthTouchbackHelp = 0.22
    /// Where a returned kick is fielded, from the receiving team's own goal line.
    public static let kickoffReturnStartYardLine = 5
    /// Yards a perfectly average return gains from there.
    public static let baseKickoffReturnYards = 18
    /// How far a won or lost coverage matchup moves that, in yards per leverage unit.
    public static let kickoffReturnYardScale = 22.0
    /// Chance a return that beat its coverage breaks all the way.
    ///
    /// A separate draw rather than a threshold on the matchup, because the matchup cannot reach the
    /// end zone from the fielding spot at any leverage — a threshold there would be a branch nothing
    /// could enter.
    public static let kickoffBreakawayChance = 0.006

    /// Chance the kicking team recovers an onside kick.
    ///
    /// Flat, and low. It is a scramble for a bouncing ball among ten players, so the trailing team's
    /// last mechanism is a real one that usually fails — which is what makes recovering one the
    /// moment it is.
    public static let onsideRecoveryChance = 0.12
    /// Where the recovering team starts either way, from its own goal line.
    public static let onsideRecoveryYardLine = 45
    /// Inside this many seconds of the half, a trailing team may try one.
    public static let onsideKickSecondsRemaining = 180
    /// Beyond this deficit an onside kick cannot save the game, so the kicking team kicks deep and
    /// trusts its defence instead.
    public static let onsideKickMaximumDeficit = 16
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

    // MARK: - Overtime

    /// How far each side starts from the goal line in an alternating-possession overtime. `02` §3.7.
    public static let overtimeYardsToGoal = 25

    /// Seconds a timed overtime period lasts.
    public static let overtimePeriodSeconds = 600

    /// The clock an untimed overtime possession is given.
    ///
    /// An alternating-possession overtime has no game clock, and the drive loop is clock-driven, so
    /// the possession is handed more seconds than any drive can consume rather than the loop being
    /// taught a second way to end. Bounded either way by the play cap.
    public static let overtimeUntimedSeconds = 3_600

    /// Timeouts each side carries into an overtime period.
    public static let overtimeTimeouts = 1

    /// How many alternating periods before the game is recorded as a tie.
    ///
    /// A tie is an honest outcome and an unbounded loop is not. `03` §5.1's college tie band is
    /// exactly zero, so if this bound is ever reached in calibration the model is wrong somewhere
    /// upstream and the band says so.
    public static let maximumOvertimePeriods = 8

    /// Drive bound inside a timed overtime period.
    public static let maximumOvertimeDrives = 30
}
