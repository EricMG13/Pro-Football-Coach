import Foundation

/// How well the user executed a snap they played by hand.
///
/// This is the whole interface between the arcade mode and the simulation. The arcade decides
/// *inputs* — where the throw was aimed, when it was released, whether a cut was timed right —
/// and hands over these three numbers. The engine still decides what happens, so a played snap
/// cannot produce an outcome a simulated one couldn't, and the rules live in exactly one place.
///
/// Every field is centred on zero, which is deliberate: zero means "as well as the AI would
/// have done it", so a player who never touches the controls gets the simulated game, and skill
/// moves the result either way from there.
public struct PlayExecution: Sendable, Equatable {
    /// -1...1. How close the throw was to where the receiver actually was.
    public var accuracy: Double
    /// -1...1. Release timing against the pass rush. Negative is holding the ball too long.
    public var timing: Double
    /// -1 (go down cleanly) to 1 (fight for every yard). One axis, because in football it is
    /// one decision: the yards you chase and the ball security you give up are the same choice.
    public var running: Double
    /// -1...1. How cleanly a placekick was struck.
    public var kicking: Double

    public init(
        accuracy: Double = 0,
        timing: Double = 0,
        running: Double = 0,
        kicking: Double = 0
    ) {
        self.accuracy = Self.clamp(accuracy)
        self.timing = Self.clamp(timing)
        self.running = Self.clamp(running)
        self.kicking = Self.clamp(kicking)
    }

    private static func clamp(_ value: Double) -> Double {
        Swift.min(1, Swift.max(-1, value.isFinite ? value : 0))
    }

    /// What the AI does, and the baseline every arcade input is measured against.
    public static let neutral = PlayExecution()

    // MARK: - Effect on a play
    //
    // The ceilings below are deliberately modest. A great player should win more games than a
    // poor one, but a 60-rated quarterback must not throw like a 90 because someone is good with
    // their thumbs — the roster is what the management half of the game is about.

    /// Completion probability shift, capped by `ArcadeTuning.completionSwing`.
    public var completionModifier: Double { accuracy * ArcadeTuning.completionSwing }

    /// Sack probability multiplier. Getting rid of the ball early genuinely helps.
    public var sackMultiplier: Double {
        timing < 0
            ? 1 + (-timing * ArcadeTuning.sackTimingPenalty)
            : 1 - (timing * ArcadeTuning.sackTimingReward)
    }

    /// Interception multiplier. A badly placed ball is the one that gets picked off.
    public var interceptionMultiplier: Double {
        accuracy < 0
            ? 1 + (-accuracy * ArcadeTuning.interceptionPlacementPenalty)
            : 1 - (accuracy * ArcadeTuning.interceptionPlacementReward)
    }

    /// Extra yards after the catch or on a run, capped by `ArcadeTuning.yardsSwing`.
    public var yardsModifier: Double { running * ArcadeTuning.yardsSwing }

    /// Chance the carrier coughs it up. Rises only as he fights for extra yards — going down
    /// cleanly is the safe end of the axis, which is what makes it a real trade-off rather than
    /// a free choice.
    public var fumbleMultiplier: Double {
        1 + Swift.max(0, running) * ArcadeTuning.fumbleAggressionPenalty
    }

    /// Make-probability shift on a placekick, capped by `ArcadeTuning.kickSwing`.
    public var kickModifier: Double { kicking * ArcadeTuning.kickSwing }

    public var isNeutral: Bool { self == .neutral }
}

/// Translates raw arcade gestures into a `PlayExecution`.
///
/// Kept in the engine rather than the view so the mapping is testable without a simulator, and
/// so the relationship between a player's ratings and what his hands can do stays in one place.
public enum ArcadeInput {

    /// Scores a throw by how far it landed from the receiver, in yards.
    ///
    /// The tolerance a quarterback earns comes from his accuracy rating: an inaccurate passer
    /// punishes a good read, an accurate one rescues a sloppy one. This is what makes upgrading
    /// the position feel different in the hand rather than only on the box score.
    public static func throwAccuracy(
        missDistanceYards: Double,
        quarterback: Player
    ) -> Double {
        let rating = Double(quarterback.ratings[.throwAccuracy])
        // Roughly 2 yards of tolerance at 40 accuracy, 6 at 99.
        let tolerance = 2.0 + (rating - 40) / 59 * 4.0
        let error = missDistanceYards / Swift.max(0.5, tolerance)
        // 0 miss reads as a perfect ball; one tolerance out is neutral; beyond that it degrades.
        return Swift.min(1, Swift.max(-1, 1 - error))
    }

    /// Scores release timing against how long the protection was going to hold.
    public static func releaseTiming(
        heldSeconds: Double,
        pocketSeconds: Double
    ) -> Double {
        guard pocketSeconds > 0 else { return 0 }
        let share = heldSeconds / pocketSeconds
        switch share {
        // Getting it out inside two-thirds of the pocket is clean.
        case ..<0.66: return 1 - share / 0.66 * 0.4
        // The last third is live but survivable.
        case 0.66..<1.0: return 0.6 - (share - 0.66) / 0.34 * 0.6
        // Past the pocket the rush is there.
        default: return Swift.max(-1, -(share - 1.0) * 2)
        }
    }

    /// Scores ball-carrier play from how many defenders were beaten and whether he went down
    /// cleanly. Running through contact is rewarded; running backwards is not.
    public static func carrierPlay(
        defendersBeaten: Int,
        yardsLostScrambling: Double,
        wentOutOfBoundsSafely: Bool
    ) -> Double {
        var score = Double(defendersBeaten) * 0.35
        score -= yardsLostScrambling * 0.12
        if wentOutOfBoundsSafely { score += 0.1 }
        return Swift.min(1, Swift.max(-1, score))
    }

    /// Scores a two-tap kick meter: how centred the power tap was and how centred the aim was.
    /// Both arrive as 0...1 where 0.5 is dead centre.
    public static func kickQuality(power: Double, aim: Double) -> Double {
        let powerError = abs(power - 0.5) * 2
        let aimError = abs(aim - 0.5) * 2
        // Aim matters roughly twice as much as power on a kick.
        return Swift.min(1, Swift.max(-1, 1 - (powerError * 0.6 + aimError * 1.4)))
    }

    /// Converts a kick-meter score into a make-probability shift.
    public static func kickModifier(quality: Double) -> Double { quality * ArcadeTuning.kickSwing }

    /// Turns what happened on the 2D field into what the engine understands.
    ///
    /// This is the join the whole all-22 design rests on: the spatial layer measures — how far
    /// off the ball landed, whether the man was open when it left, how many tacklers the carrier
    /// beat, which lane he took — and the engine still decides. Nothing below returns a yard or
    /// a probability; they return the same centred -1...1 axes a thumbless player scores zero on.
    public static func execution(from grades: SnapGrades, quarterback: Athlete?) -> PlayExecution {
        // A trace with nothing in it must grade to neutral, or "play nothing, get the simulated
        // game" stops being true and every calibration band drifts.
        guard !grades.isNeutral else { return .neutral }

        return PlayExecution(
            accuracy: placementScore(grades: grades, quarterback: quarterback),
            timing: grades.releaseTiming,
            running: carryScore(grades: grades),
            kicking: 0
        )
    }

    /// Scores where the ball actually arrived, against the tolerance the passer earns.
    ///
    /// Throwing at a covered man is charged here rather than in the engine, because the engine
    /// cannot see coverage at the moment of release — only the field can. A perfect ball into a
    /// red window is still a bad decision, and it should read like one.
    static func placementScore(grades: SnapGrades, quarterback: Athlete?) -> Double {
        guard grades.ending == .thrown else {
            // Pressured, thrown away, or never thrown: placement is not what happened.
            return grades.ending == .pressured ? -0.6 : 0
        }
        let rating = Double(quarterback?.throwAccuracy ?? 70)
        let tolerance = ArcadeTuning.curve(rating, at40: 2.0, at99: 6.0)
        let error = grades.placementErrorYards / Swift.max(0.5, tolerance)
        var score = Swift.min(1, Swift.max(-1, 1 - error))

        switch grades.targetOpenness {
        case .open: break
        case .contested: score -= 0.35
        case .covered: score -= 0.8
        }
        return Swift.min(1, Swift.max(-1, score))
    }

    /// Scores the run after the catch or handoff: tacklers beaten, the lane taken, and how hard
    /// the carrier was told to fight for it.
    static func carryScore(grades: SnapGrades) -> Double {
        var score = Double(grades.pursuitBeaten) * 0.3
        // Lane quality is 0...1 with 0.5 meaning "as good as the AI would have picked", so it
        // has to be recentred before it can join a -1...1 axis.
        score += (grades.laneQuality - 0.5) * 0.6
        score += grades.aggression * 0.5
        return Swift.min(1, Swift.max(-1, score))
    }
}
