import Foundation

/// Constants both tiers share, from `02-GAME-DESIGN.md` section 11.3.
///
/// `03b` section 6: a constant used by both tiers lives in a shared rules module and is named for
/// what it is, rather than duplicated into each tier and drifting.
public enum SharedRules {
    /// `02` section 5. Enforced by `Rating`, not by discipline.
    public static let ratingRange: ClosedRange<Int> = 40...99

    /// Potential shares the rating scale so the two are comparable without conversion.
    public static let potentialRange: ClosedRange<Int> = 40...99

    /// `02` section 3.1. The default is a design choice; the range is a difficulty and pacing
    /// setting, and D1's session-length arithmetic is built on the default.
    public static let defaultCallInsPerGame = 25
    public static let callInsPerGameRange: ClosedRange<Int> = 12...40

    /// `02` section 6.
    public static let coordinatorCount = 4

    /// `02` section 7: the AD or GM, a booster or ownership bloc, the fanbase, the locker room.
    public static let stakeholderGroupCount = 4

    /// `02` section 8.
    public static let programmeArchetypeCount = 14
}
