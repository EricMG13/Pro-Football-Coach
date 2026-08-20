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
    public static let deepShotDistance = 9

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

    /// Home advantage, per tier, in leverage units applied to every duel the home offence takes
    /// and reversed for the away one.
    ///
    /// **Per tier because `01` §6.5's bands say so**: home wins 0.50 to 0.58 of pro games and 0.60
    /// to 0.68 of college ones, and one constant cannot land both. Tiny numbers with a large reach —
    /// 0.035 is worth about 1.3 rating points on a single duel and **14.5 points of margin** over a
    /// game, measured by playing even teams with the bonus zeroed (19.9 to 18.8, home winning half)
    /// and again at 0.035 (28.7 to 14.2, home winning 0.656). That conversion rate is itself a
    /// defect and is not this constant's to fix; see `docs/STATUS.md`.
    public static let proHomeAdvantage = 0.017
    public static let collegeHomeAdvantage = 0.063

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
    ///
    /// Was 0.66 — above the 99th percentile of pressure the engine actually produces (measured
    /// mean 0.10, p99 0.58 over 5,343 dropbacks), so a sack was reachable only in the extreme tail:
    /// 1.4 percent of dropbacks against a real rate of roughly 6 to 7 percent, and `01` §6.5's band
    /// of 2.0 to 3.1 sacks per team-game read 0.72 to 0.97. 0.50 sits at the tier's p93 to p94 for
    /// an average-poise passer once `poiseSackRelief` is applied, which is where that real rate is.
    public static let sackPressureThreshold = 0.50
    /// How much a maximally poised passer raises that threshold.
    public static let poiseSackRelief = 0.22
    public static let sackYards = -7
    public static let blitzPressureBonus = 0.14
    public static let pressureThrowPenalty = 0.30
    /// How much being open helps the throw, in leverage units at full openness.
    public static let opennessThrowHelp = 0.30

    /// The rating a throw is resolved against, by depth. A deep ball is hard to complete even to an
    /// open receiver, and making depth the difficulty — rather than only reading the passer's own
    /// depth-specific accuracy attribute — is what keeps incompletions reachable at all: `01` §6.4's
    /// generator scatters `accuracyShort`/`accuracyMid`/`accuracyDeep` independently around the same
    /// skill, so nothing in the roster itself encodes "deep is harder"; this is the only place that
    /// does.
    ///
    /// Was 68/80/92 — a flat +12 per step chosen with no measurement behind it. Against a typical
    /// 70-something accuracy that put completion at 66/48/21 percent by depth (league completion
    /// 43.5 against a band of 61 to 67) and put deep's interception rate at 13.2 percent, because
    /// `01` §6.5's -0.94 cutoff was within a normal throw's noise once the deterministic term was
    /// already deeply negative. These three came from solving `logistic` for the mean each depth's
    /// raw throw leverage needed to land its measured completion share in band, holding the route
    /// and pressure terms fixed, then walking the whole three-value set against
    /// `--calibration-gate` — completion percentage, interceptions, sacks and pass yards all move
    /// together off the same throw, so no single depth could be solved in isolation.
    public static func throwDifficulty(_ depth: PassDepth) -> Int {
        switch depth {
        case .short: return 56
        case .mid: return 71
        case .deep: return 82
        }
    }
    public static let aggressionThrowBonus = 0.06
    /// Below this the throw is intercepted; below `completionThreshold` it falls incomplete.
    public static let interceptionThreshold = -0.94
    public static let completionThreshold = -0.02
    /// How much a low-decision passer is pulled toward progression order rather than the open man.
    public static let progressionPenalty = 0.25

    // MARK: - Run

    /// The yards a carry gains when the front is even, the carrier wins nothing and no tackle
    /// breaks. Without it, `resolveRun` was `lane * laneYardScale + broken` and an even front
    /// averages a lane leverage of zero, so a neutral run gained **nothing**: every yard in the
    /// engine came out of the break chain and the harness measured 1.34 yards a carry against a
    /// rush band of 100 to 130 per team-game. A run play that is blocked to a standstill still
    /// gains a couple of yards; that is what this is.
    public static let baseRunYards = 3.0
    /// Yards per unit of lane leverage.
    public static let laneYardScale = 3.5
    /// Multiplies the lane and contact terms in the college tier.
    ///
    /// **Per tier because `01` §6.5's bands are**: explosive runs are 0.105 to 0.130 of carries in
    /// the pro tier and 0.135 to 0.165 in the college one, and the two ranges do not overlap, so no
    /// shared pair of scales can satisfy both — the same argument that put `homeAdvantage` and the
    /// field-goal penalty on the tier. `03` §5.1 attributes the college tier's wider outcomes partly
    /// to talent dispersion, which would be the more fundamental place to express this; the harness's
    /// `CalibrationRoster` takes no tier and draws both tiers from one distribution, so dispersion
    /// is not currently a lever the engine has. This is the honest stand-in and `docs/STATUS.md`
    /// records that it is one.
    public static let collegeRunSpreadMultiplier = 1.09
    /// Yards per unit of carrier-versus-pursuit leverage.
    ///
    /// `03` §1.1 says "the carrier's vision and elusiveness resolve against pursuit leverage **into
    /// yards**". That duel was resolved and then read only as a break-or-not threshold, so beating
    /// the first defender by a mile and beating him by an inch produced the same carry. This is the
    /// part of the sentence that was missing.
    public static let contactYardScale = 3.5
    /// Outside runs multiply the lane result, trading certainty for the edge.
    public static let outsideRunVariance = 1.35
    public static let crashRunBonus = 0.10
    public static let aggressionRunBonus = 0.05
    /// Yards a completion gains after the catch before anyone is beaten, and yards per unit of the
    /// receiver's leverage against the first pursuer.
    ///
    /// The pass had the defect the run had before `baseRunYards`: yards after the catch came only
    /// from the break-tackle chain, so a receiver who caught the ball and beat nobody gained
    /// **nothing**. Measured, every depth completed for almost exactly its air yards — short 4.7
    /// against 5 air, mid 11.9 against 12, deep 22.4 against 24 — so the explosive-pass rate was
    /// carried entirely by deep balls (0.385 of deep attempts, 0.006 of mid, 0.000 of short) and sat
    /// under `01` §6.5's floor. Real receptions average around five yards after the catch, and most
    /// of that is on the short and intermediate routes this model gave none to.
    public static let baseCatchYards = 0.3
    public static let catchYardScale = 1.0
    /// Leverage above which a receiver breaks a tackle after the catch.
    ///
    /// Lower than `breakTackleThreshold` because the two are not the same event: a carrier meets the
    /// front seven at the line, a receiver catches in space with one defender arriving. Sharing one
    /// threshold meant tuning the run's tail moved the explosive-pass rate with it — `01` §6.5 bands
    /// those separately (0.105–0.130 run against 0.125–0.150 pass in the pro tier), so one constant
    /// could not serve both.
    public static let catchBreakTackleThreshold = 0.46
    /// How much lower the college tier's break threshold sits.
    ///
    /// A smooth lever where scaling the chain's yards was not: broken-tackle yards are integers
    /// (4, then 12, then 24), so multiplying them by a tier factor stepped the first break from 4
    /// to 5 between multipliers of 1.09 and 1.13 and jumped the explosive-run rate from 0.136 to
    /// 0.171 with nothing in between. Break *probability* moves continuously with the threshold.
    public static let collegeBreakTackleRelief = 0.05
    /// Leverage above which the carrier breaks a tackle.
    public static let breakTackleThreshold = 0.46
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
    /// Added to the base for college kicks.
    ///
    /// **Per tier because `01` §6.5's bands are**: field goals go 81 to 88 percent in the pro tier
    /// and 72 to 79 in the college one, a gap of nine points that one shared constant cannot span —
    /// the same argument that put `homeAdvantage` on the tier. College kicking is worse because
    /// college kickers are, which is a fact about the people rather than about the posts, but the
    /// engine has no separate college kicker population to express it through, so it lands here.
    public static let collegeFieldGoalDifficultyPenalty = 7

    public static func fieldGoalDifficulty(distanceYards: Int, tier: Tier) -> Int {
        let base = fieldGoalBaseDifficulty
            + (tier == .college ? collegeFieldGoalDifficultyPenalty : 0)
        return Swift.min(Swift.max(base + distanceYards,
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

    /// Inside this many yards of his own goal line a passer takes a shorter drop.
    ///
    /// The quick game is what teams call from their own five, so the pocket does not collapse seven
    /// yards deep and nearly every safety the engine produced — 27 of 28 measured — stopped coming
    /// from an ordinary sack on an ordinary dropback.
    public static let backedUpYardLine = 7
    public static let backedUpSackYards = -3

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
