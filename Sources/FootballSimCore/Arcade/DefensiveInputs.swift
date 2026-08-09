import Foundation

/// Where the coverage is tilted before the snap.
public enum CoverageShade: String, Sendable, CaseIterable, Equatable, Codable {
    case balanced, boundary, field, deep, box

    public var displayName: String {
        switch self {
        case .balanced: "Balanced"
        case .boundary: "Boundary"
        case .field: "Field"
        case .deep: "Over the Top"
        case .box: "In the Box"
        }
    }

    /// What this shade is guessing the offense will do. Guessing right is worth something;
    /// guessing wrong costs the same amount, which is what makes it a call rather than a bonus.
    func anticipates(_ call: OffensivePlay) -> Bool {
        switch self {
        case .balanced: false
        case .deep: call == .deepPass
        case .box: call.isRun
        case .boundary, .field: call == .shortPass || call == .screen
        }
    }

    func isExposedBy(_ call: OffensivePlay) -> Bool {
        switch self {
        case .balanced: false
        case .deep: call.isRun
        case .box: call == .deepPass
        case .boundary, .field: call == .deepPass
        }
    }
}

/// What the player did on a defensive snap.
///
/// Three moments, and only three: the pre-snap shade, a timed break on the ball, and whether to
/// commit to filling a gap. Deliberately not a fourth control scheme — the mode's promise is one
/// thumb, and defense is a series of reads rather than a second joystick. Steering a defender
/// yourself is the v2 idea; this is the version that fits in the time between snaps.
public struct DefensiveInput: Sendable, Equatable {
    public var shade: CoverageShade
    /// How close to the throw the break-on-the-ball tap landed, 0 being perfect and 1 being a
    /// whole window early or late. `nil` means the player did not tap.
    public var breakError: Double?
    /// True when the player committed to the run fit, false when they hung back, `nil` when
    /// they left it to the defender.
    public var committedToTackle: Bool?

    public init(
        shade: CoverageShade = .balanced,
        breakError: Double? = nil,
        committedToTackle: Bool? = nil
    ) {
        self.shade = shade
        self.breakError = breakError.map { Swift.min(1, Swift.max(0, $0)) }
        self.committedToTackle = committedToTackle
    }

    public static let none = DefensiveInput()

    public var isNeutral: Bool { self == .none }
}

/// Turns defensive reads into the same currency everything else in this layer speaks.
///
/// There is no separate defensive path through the engine, and there should not be: a defensive
/// input is simply an offensive snap made harder or easier, so it comes back as a `PlayExecution`
/// applied to the *opposing* offense with its sign flipped. One resolution path, one set of
/// calibration bands, and a cap that is checked rather than trusted.
public enum DefensiveInputs {

    /// The most any single read may be worth, so the three together stay inside the cap.
    static var perReadSwing: Double { ArcadeTuning.defensiveSwing / 3 }

    /// The accuracy-axis magnitude that corresponds to a given completion-probability shift.
    static func accuracyAxis(forCompletionShift shift: Double) -> Double {
        guard ArcadeTuning.completionSwing > 0 else { return 0 }
        return shift / ArcadeTuning.completionSwing
    }

    public static func execution(
        input: DefensiveInput,
        against call: OffensivePlay
    ) -> PlayExecution {
        guard !input.isNeutral else { return .neutral }

        // Positive helps the defense; converted to a negative offensive execution at the end.
        var completionShift = 0.0
        var yardsShift = 0.0

        if input.shade.anticipates(call) { completionShift += perReadSwing }
        if input.shade.isExposedBy(call) { completionShift -= perReadSwing }

        if let breakError = input.breakError, call.isPass {
            // A centred break is worth a full read; a mistimed one is worse than not breaking,
            // because the man behind you is now uncovered.
            completionShift += perReadSwing * (1 - breakError * 2)
        }

        if let committed = input.committedToTackle {
            if call.isRun {
                yardsShift += committed ? perReadSwing : -perReadSwing * 0.5
            } else {
                // Committing to a run that never came is how play action works.
                yardsShift -= committed ? perReadSwing : 0
            }
        }

        let cappedCompletion = Swift.min(
            ArcadeTuning.defensiveSwing, Swift.max(-ArcadeTuning.defensiveSwing, completionShift)
        )
        let cappedYards = Swift.min(
            ArcadeTuning.defensiveSwing, Swift.max(-ArcadeTuning.defensiveSwing, yardsShift)
        )

        return PlayExecution(
            // Negated: what is good for the defense is bad for the offense holding the ball.
            accuracy: -accuracyAxis(forCompletionShift: cappedCompletion),
            timing: 0,
            running: -(cappedYards / Swift.max(0.0001, ArcadeTuning.defensiveSwing)) * 0.4,
            kicking: 0
        )
    }

    /// The window, in seconds either side of the throw, in which a break counts as timed.
    public static func breakWindow(awareness: Int) -> Double {
        ArcadeTuning.curve(awareness, at40: 0.22, at99: 0.45)
    }

    /// Scores a tap against when the ball actually left the passer's hand.
    public static func breakError(tapAt: Double, releaseAt: Double, window: Double) -> Double {
        guard window > 0 else { return 1 }
        return Swift.min(1, abs(tapAt - releaseAt) / window)
    }
}
