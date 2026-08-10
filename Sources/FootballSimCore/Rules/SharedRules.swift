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

    /// `02` section 11.3. Rivalry strength accumulates for a whole career, so the list is bounded
    /// and holds the strongest.
    public static let rivalriesPerProgramme = 8

    /// `02` section 11.3.1. One save runs both leagues, so they share one week counter rather than
    /// each keeping their own — the pro league has to be playing while the coach is still in
    /// college, or section 9 has nowhere to promote them to.
    public static let inSeasonWeeks = 21

    /// `02` section 11.3.2. Decline begins here, per position.
    ///
    /// A table rather than a `switch` in `Position`, because these are design constants and
    /// `03b` section 6 puts design constants in a rules module. Total by construction: every
    /// position has an entry, and `RulesTests` asserts it.
    public static let declineAgeByPosition: [Position: Int] = [
        .runningBack: 27,
        .cornerback: 29, .wideReceiver: 29, .edgeRusher: 29,
        .safety: 30, .linebacker: 30, .defensiveTackle: 30, .tightEnd: 30,
        .leftTackle: 31, .guardPosition: 31, .center: 31, .rightTackle: 31,
        .quarterback: 34,
        .kicker: 36, .punter: 36,
    ]

    /// Unreachable while `declineAgeByPosition` is total, which `RulesTests` asserts. Present so a
    /// lookup does not need an optional at every call site, and set to the earliest age in the
    /// table so a missing entry fails safe toward decline rather than toward immortality.
    public static let declineAgeFallback = 27
}
