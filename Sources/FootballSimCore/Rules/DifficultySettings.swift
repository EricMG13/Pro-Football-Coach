import Foundation

/// How hard the game is, and how fast. `02` §3.16.
///
/// The whole difficulty model was one sentence — `02` §3.1's "tunable from ~12 to ~40 as a difficulty
/// and pacing setting" — and it was not implemented anywhere: `SharedRules.callInsPerGameRange`
/// existed and nothing read it as a preference. Screen 6 promises "device, match and accessibility
/// choices" and the match choices were unspecified.
///
/// **Three levels and one dial, not a slider farm.** Every setting here has to change a decision the
/// player makes or the pressure they are under; a difficulty that only multiplies a hidden number is
/// the "progression too random" complaint `02` §5 records about the reference title, arriving from a
/// different direction.
public struct DifficultySettings: Codable, Sendable, Equatable {
    /// How often the coach is pulled in. `02` §3.1's tunable rate, clamped to its stated range.
    public let callInsPerGame: Int
    /// How much of the coach's own week the staff may be handed. A harder game delegates less.
    public let allowsDelegation: Bool
    /// How quickly job security moves against expectation, as a percentage of the base rate.
    ///
    /// `02` §7 makes job security move weekly; this is what makes an easier game forgiving without
    /// making the number stop moving, which is the prior build's failure and not a difficulty.
    public let jobSecurityPressurePercent: Int

    public init(callInsPerGame: Int, allowsDelegation: Bool, jobSecurityPressurePercent: Int) {
        self.callInsPerGame = Swift.min(
            Swift.max(callInsPerGame, SharedRules.callInsPerGameRange.lowerBound),
            SharedRules.callInsPerGameRange.upperBound
        )
        self.allowsDelegation = allowsDelegation
        self.jobSecurityPressurePercent = Swift.max(1, jobSecurityPressurePercent)
    }

    /// Named levels, because a player choosing "how hard is this" should not have to reason about
    /// three numbers before they have played a game.
    public enum Level: String, Codable, Sendable, CaseIterable {
        case assistant
        case headCoach
        case programmeBuilder

        public var label: String {
            switch self {
            case .assistant: return "Assistant"
            case .headCoach: return "Head coach"
            case .programmeBuilder: return "Programme builder"
            }
        }

        /// What the level means, in the player's terms rather than in multipliers.
        public var summary: String {
            switch self {
            case .assistant:
                return "Fewer calls, more help from your staff, and an athletic director who waits."
            case .headCoach:
                return "The intended game: the rate the design is built around."
            case .programmeBuilder:
                return "More calls, nothing delegated, and a job you can lose quickly."
            }
        }

        public var settings: DifficultySettings {
            switch self {
            case .assistant:
                return DifficultySettings(
                    callInsPerGame: SharedRules.callInsPerGameRange.lowerBound,
                    allowsDelegation: true,
                    jobSecurityPressurePercent: 60
                )
            case .headCoach:
                return DifficultySettings(
                    callInsPerGame: SharedRules.defaultCallInsPerGame,
                    allowsDelegation: true,
                    jobSecurityPressurePercent: 100
                )
            case .programmeBuilder:
                return DifficultySettings(
                    callInsPerGame: SharedRules.callInsPerGameRange.upperBound,
                    allowsDelegation: false,
                    jobSecurityPressurePercent: 150
                )
            }
        }
    }

    public static let `default` = Level.headCoach.settings
}
