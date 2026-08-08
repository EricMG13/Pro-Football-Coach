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
    /// -1...1. Ball-carrier decisions after the catch or handoff.
    public var running: Double

    public init(accuracy: Double = 0, timing: Double = 0, running: Double = 0) {
        self.accuracy = Self.clamp(accuracy)
        self.timing = Self.clamp(timing)
        self.running = Self.clamp(running)
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

    /// Completion probability shift, at most ±12 points.
    public var completionModifier: Double { accuracy * 0.12 }

    /// Sack probability multiplier. Getting rid of the ball early genuinely helps.
    public var sackMultiplier: Double { timing < 0 ? 1 + (-timing * 0.8) : 1 - (timing * 0.35) }

    /// Interception multiplier. A badly placed ball is the one that gets picked off.
    public var interceptionMultiplier: Double { accuracy < 0 ? 1 + (-accuracy * 0.9) : 1 - (accuracy * 0.3) }

    /// Extra yards after the catch or on a run, at most ±3.5.
    public var yardsModifier: Double { running * 3.5 }

    /// Chance the carrier coughs it up, raised by reckless running.
    public var fumbleMultiplier: Double { running < -0.5 ? 1.6 : 1.0 }

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

    /// Converts a kick-meter score into a make-probability shift, at most ±18 points.
    public static func kickModifier(quality: Double) -> Double { quality * 0.18 }
}
