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

    /// `02` section 4.1a. Every legal number, and the band each position wears inside it.
    ///
    /// A band is one contiguous range per position rather than the two-or-three ranges a real
    /// rulebook allows, because the second range buys nothing a reader would notice and costs a
    /// wrapping rule at every band edge. The table must be total over `Position` —
    /// `RulesTests` asserts it — so a position added later cannot silently fall back.
    /// Each unit's bands partition the range: offence 1–19/20–39/40–49/50–79/80–99, defence
    /// 0–39/40–59/60–99. Offence and defence bands overlap each other freely and are meant to —
    /// uniqueness is per unit, so a 55 on the line and a 55 at linebacker is not a clash.
    ///
    /// Every band is at least as wide as the roster template asks of it, and `JerseyNumberTests`
    /// asserts that against `CollegeRules.initialRosterByPosition` rather than trusting the
    /// arithmetic here. The first version sized them from memory of real football and put nine
    /// edge rushers and nine tackles into ten numbers, which spilled to `#0` on the first screen
    /// anyone looked at.
    public static let jerseyNumberRange: ClosedRange<Int> = 0...99
    public static let jerseyBandByPosition: [Position: ClosedRange<Int>] = [
        .quarterback: 1...19,
        .runningBack: 20...39,
        .tightEnd: 40...49,
        .leftTackle: 50...79,
        .guardPosition: 50...79,
        .center: 50...79,
        .rightTackle: 50...79,
        .wideReceiver: 80...99,
        .cornerback: 0...39,
        .safety: 0...39,
        .linebacker: 40...59,
        .edgeRusher: 60...99,
        .defensiveTackle: 60...99,
        .kicker: 1...19,
        .punter: 1...19,
    ]

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

    /// `02` section 11.3.1. A career runs seasons 0 through 29; the calendar may reach season 30
    /// week 1 and rests there, and the week cannot be advanced past it.
    ///
    /// Owner decision 2026-08-20, and the reason is save size rather than pacing. `D7`'s bounds
    /// table never listed `DomainEventLedger.archive`, which appends one digest per season forever,
    /// so save growth was linear in season count with no ceiling and no measurement could be a
    /// worst case. This is the wall that makes one exist. `01-RESEARCH.md` section 2.2 records the
    /// precedent it follows.
    public static let maximumCareerSeasons = 30

    /// Minimum playable coverage checked after every AI roster pass.
    ///
    /// Every entry is at least what `DepthChart`'s formation fields at that position, and
    /// `RulesTests` asserts that against both templates by construction rather than by inspection.
    /// Linebacker read 2 until 2026-08-20 while the defence starts 3, so a roster sitting at the
    /// "minimum playable" coverage put somebody out of position at linebacker on every snap and
    /// carried a spare cornerback the formation never used. Nothing compared the two constants, so
    /// nothing said so.
    ///
    /// Raised rather than resolved the other way: the formation is unchanged and cornerback keeps
    /// its floor of 3. Which base defence the league plays is a design question `02` does not
    /// answer — the 4-3 shape lives only in `DepthChart`'s templates — and it is flagged for the
    /// owner rather than settled here.
    public static let minimumPlayableRosterByPosition: [Position: Int] = [
        .quarterback: 1, .runningBack: 2, .wideReceiver: 3, .tightEnd: 1,
        .leftTackle: 1, .guardPosition: 2, .center: 1, .rightTackle: 1,
        .edgeRusher: 2, .defensiveTackle: 2, .linebacker: 3,
        .cornerback: 3, .safety: 2, .kicker: 1, .punter: 1,
    ]

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
