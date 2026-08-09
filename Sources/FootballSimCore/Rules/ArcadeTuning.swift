import Foundation

/// Every tunable number the on-field arcade mode reads.
///
/// The same rule `LeagueRules` follows: nothing in the spatial layer hard-codes a figure a
/// designer might want to move. This file is also the contract for the balance tests — the caps
/// at the bottom are what stops a good thumb from outplaying the roster, and they are asserted
/// rather than trusted.
public enum ArcadeTuning {

    // MARK: - Cadence

    /// Logical ticks per second. Rendering interpolates between these, so the number is a
    /// simulation choice rather than a frame-rate one: fine enough that a 10 yd/s receiver moves
    /// a third of a yard per tick, coarse enough that a whole snap is a few hundred steps.
    public static let ticksPerSecond: Double = 30
    public static var secondsPerTick: Double { 1 / ticksPerSecond }

    /// A snap that has not resolved by here is over regardless — the guard that stops a bad
    /// pursuit calculation from spinning forever.
    public static let maxSnapSeconds: Double = 12
    public static var maxSnapTicks: Int { Int((maxSnapSeconds * ticksPerSecond).rounded()) }

    // MARK: - Field

    /// A real field is 53 1/3 yards wide. Lateral coordinates are -1...1 across it.
    public static let fieldWidthYards: Double = 53.3
    /// How much of the field the camera shows ahead of the ball.
    public static let cameraWindowYards: Double = 45
    /// Receivers are held this far inside the sideline so a route never runs out of bounds.
    public static let sidelineMarginYards: Double = 2.0

    // MARK: - Rating curves

    /// Maps a 40...99 rating onto a value, clamping outside the legal band.
    ///
    /// Every "X at 40, Y at 99" line in `06-PLAYED-GAME-MODE.md` comes through here, so the
    /// relationship between a rating and what it buys is linear and inspectable in one place.
    public static func curve(_ rating: Double, at40 low: Double, at99 high: Double) -> Double {
        let floor = Double(LeagueRules.ratingFloor)
        let ceiling = Double(LeagueRules.ratingCeiling)
        let clamped = Swift.min(Swift.max(rating, floor), ceiling)
        return low + (high - low) * ((clamped - floor) / (ceiling - floor))
    }

    public static func curve(_ rating: Int, at40 low: Double, at99 high: Double) -> Double {
        curve(Double(rating), at40: low, at99: high)
    }

    // MARK: - Movement

    /// Top speed in yards per second. A 99 runs a shade under 10 yd/s, which is about what the
    /// fastest real players manage; a 40 is comfortably catchable.
    public static func topSpeed(_ speedRating: Int) -> Double {
        curve(speedRating, at40: 5.6, at99: 9.6)
    }

    /// How fast a player reaches top speed, in yards per second squared.
    public static func acceleration(_ agilityRating: Int) -> Double {
        curve(agilityRating, at40: 7.0, at99: 12.0)
    }

    /// How long a defender takes to react to something new — a cut, a throw, a handoff.
    /// Inverted: awareness buys a shorter delay.
    public static func reactionDelay(_ awarenessRating: Int) -> Double {
        curve(awarenessRating, at40: 0.55, at99: 0.12)
    }

    // MARK: - Openness

    /// Separation at or above this reads green.
    public static let openSeparationYards: Double = 3.0
    /// Separation below this reads red.
    public static let coveredSeparationYards: Double = 1.5
    /// A receiver with green separation still reads orange if a defender is closing this fast —
    /// the "maybe" case: open now, not open when the ball lands.
    public static let closingSpeedThreshold: Double = 4.0

    /// How long the quarterback takes to notice a window has changed.
    ///
    /// This is the whole of how awareness expresses itself in the hand. The colour is never a
    /// lie; a poor passer simply learns about it late.
    public static func indicatorLatency(_ awarenessRating: Int) -> Double {
        curve(awarenessRating, at40: 0.90, at99: 0.15)
    }

    /// Awareness at or above this reveals the coverage shell before the snap.
    public static let coverageHintAwareness = 80

    // MARK: - Throwing

    /// Radius of the landing-scatter ring at the aim point, before distance and pressure.
    public static func scatterRadius(_ accuracyRating: Int) -> Double {
        curve(accuracyRating, at40: 2.5, at99: 0.5)
    }

    /// Scatter grows with how far the ball has to travel: ×1.0 up to ten yards, ×1.6 at thirty.
    public static func scatterDistanceFactor(throwYards: Double) -> Double {
        let shortRange: Double = 10
        let longRange: Double = 30
        guard throwYards > shortRange else { return 1.0 }
        let t = Swift.min(1, (throwYards - shortRange) / (longRange - shortRange))
        return 1.0 + 0.6 * t
    }

    /// Throwing with the rush arriving costs placement.
    public static let scatterPressureFactor: Double = 1.5

    /// How much of the trajectory arc is drawn. A poor passer loses the end of the flight,
    /// which is exactly the part you need to judge a deep ball.
    public static func visibleArcFraction(_ accuracyRating: Int) -> Double {
        curve(accuracyRating, at40: 0.35, at99: 1.0)
    }

    /// Furthest a throw can travel downfield.
    public static func maxThrowYards(_ powerRating: Int) -> Double {
        curve(powerRating, at40: 18, at99: 32)
    }

    /// Ball flight speed in yards per second. A weak arm lets a window close mid-flight.
    public static func ballSpeed(_ powerRating: Int, isBullet: Bool) -> Double {
        let base = curve(powerRating, at40: 14, at99: 22)
        return isBullet ? base * 1.25 : base * 0.85
    }

    /// A lobbed ball hangs, which gives a covered receiver time to be arrived at — and a
    /// contested-catch roll rather than a clean one.
    public static let lobHangFactor: Double = 1.35

    // MARK: - Protection

    /// How long the pocket holds, from the offensive line's unit rating against the rush.
    ///
    /// Anchored to the figures in `06`: about 2.2 s behind a 55 line, about 4.5 s behind a 90.
    /// Kept as a unit-rating curve rather than the 40...99 one because a line is a group.
    public static func pocketSeconds(lineUnit: Double, rushUnit: Double) -> Double {
        let base = 2.2 + (lineUnit - 55) / 35 * 2.3
        // A strong rush eats into it, a weak one gives some back — half a second at 20 points.
        let rushDelta = (rushUnit - lineUnit) * 0.025
        return Swift.min(6.0, Swift.max(0.9, base - rushDelta))
    }

    /// Spread of individual breakthrough times around the pocket mean, so the rush arrives as
    /// four separate duels rather than one alarm clock.
    public static let breakthroughSpreadSeconds: Double = 0.7

    /// A blitzer gets there sooner and takes his coverage responsibility with him.
    public static let blitzBreakthroughFactor: Double = 0.72

    /// How long before the rush arrives the sack warning flashes.
    public static func sackWarningLead(_ awarenessRating: Int) -> Double {
        curve(awarenessRating, at40: 0.20, at99: 0.60)
    }

    // MARK: - Running

    /// Half-width of a run lane, in yards, from the blocking duel that opened it.
    public static func laneHalfWidth(blockAdvantage: Double) -> Double {
        Swift.min(3.2, Swift.max(0.3, 1.4 + blockAdvantage * 0.045))
    }

    /// How reliably the suggested-lane highlight points at the genuinely best lane.
    public static func laneReadReliability(_ visionRating: Int) -> Double {
        curve(visionRating, at40: 0.45, at99: 0.97)
    }

    /// How long a juke input stays live — the window you have to time.
    public static func jukeWindow(_ agilityRating: Int) -> Double {
        curve(agilityRating, at40: 0.18, at99: 0.42)
    }

    /// How far sideways one juke moves the carrier.
    public static let jukeLateralYards: Double = 2.2

    /// A dive gains this much and ends the play.
    public static let diveYards: Double = 1.2

    // MARK: - Contact

    /// Chance the carrier beats a tackler, before the timing bonus.
    public static func breakTackleChance(carrier: Int, strength: Int, tackler: Int) -> Double {
        let edge = (Double(carrier) * 0.7 + Double(strength) * 0.3) - Double(tackler)
        return Swift.min(0.75, Swift.max(0.04, 0.22 + edge * 0.006))
    }

    /// A juke landed inside the window adds this much to the break-tackle roll.
    public static let jukeTimingBonus: Double = 0.18

    /// Within this many yards a defender is making the tackle attempt.
    public static let contactRadiusYards: Double = 0.9

    // MARK: - Fatigue

    /// Touches before a carrier starts losing top speed.
    public static let fatigueFreeTouches = 12
    /// Top-speed loss per touch past the free allowance, as a fraction.
    public static let fatiguePerTouch: Double = 0.012
    /// The most fatigue can ever cost.
    public static let maxFatigueLoss: Double = 0.18

    // MARK: - Difficulty

    /// The only three numbers difficulty is allowed to touch. Anything else would be a stat
    /// cheat, which is the complaint this mode exists to answer.
    public struct DifficultyDials: Sendable, Equatable {
        public let reactionMultiplier: Double
        public let closingMultiplier: Double
        public let coverageDiscipline: Double

        public init(reactionMultiplier: Double, closingMultiplier: Double, coverageDiscipline: Double) {
            self.reactionMultiplier = reactionMultiplier
            self.closingMultiplier = closingMultiplier
            self.coverageDiscipline = coverageDiscipline
        }
    }

    public static let easyDials = DifficultyDials(
        reactionMultiplier: 1.45, closingMultiplier: 0.90, coverageDiscipline: 0.85
    )
    public static let normalDials = DifficultyDials(
        reactionMultiplier: 1.0, closingMultiplier: 1.0, coverageDiscipline: 1.0
    )
    public static let hardDials = DifficultyDials(
        reactionMultiplier: 0.75, closingMultiplier: 1.08, coverageDiscipline: 1.12
    )

    // MARK: - Execution caps
    //
    // The ceilings that keep the roster the point of the game. Widened from the 4B figures
    // (±12 points of completion, ±3.5 yards) because full control of the field asks more of the
    // player than aiming did — but deliberately still short of "thumbs beat scouting".

    /// Most completion probability a perfectly played snap can add, in points.
    public static let completionSwing: Double = 0.20
    /// Most yards execution can add to or take off a play.
    public static let yardsSwing: Double = 6.0
    /// Most make-probability a perfect kick meter can add.
    public static let kickSwing: Double = 0.18
    /// Most all defensive timed inputs together can shift a play.
    public static let defensiveSwing: Double = 0.10

    /// Sack-probability multiplier at the extremes of release timing.
    public static let sackTimingPenalty: Double = 0.8
    public static let sackTimingReward: Double = 0.35
    /// Interception-probability multiplier at the extremes of placement.
    public static let interceptionPlacementPenalty: Double = 0.9
    public static let interceptionPlacementReward: Double = 0.3
    /// Extra fumble risk from fighting for every yard.
    public static let fumbleAggressionPenalty: Double = 0.6
}
