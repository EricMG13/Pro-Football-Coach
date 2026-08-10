import Foundation

/// The clock constants that differ between the tiers.
///
/// `03-MATCH-ENGINE.md` §2: "College clock rules differ from pro and must be modelled per tier — the
/// current rule on the clock stopping for first downs is a tier constant, not a shared one. Higher
/// college tempo is a **consequence of the clock model**, not a fudge factor applied afterwards."
///
/// So this protocol exists to make the difference a data difference rather than a branch: the clock
/// engine reads a `ClockRules` and never asks which tier it is in. A tempo constant applied on top
/// of a shared clock would be exactly the fudge `03` forbids.
///
/// NCAA Football Rule 3-3-2-e-1 (2025) confirms the college first-down difference: after the
/// two-minute timeout, a Team A first down stops the game clock until the referee's ready-for-play
/// signal. The 2026 published changes do not replace that timing rule.
public protocol ClockRules: Sendable {
    /// Quarters in a regulation game.
    static var quarters: Int { get }
    /// Seconds in a quarter.
    static var quarterSeconds: Int { get }
    /// The play clock, in seconds.
    static var playClockSeconds: Int { get }
    /// Seconds the offence typically burns before snapping, at normal tempo.
    static var normalTempoSnapSeconds: Int { get }
    /// Seconds burned at hurry-up tempo.
    static var hurryTempoSnapSeconds: Int { get }
    /// Seconds burned when bleeding the clock.
    static var bleedTempoSnapSeconds: Int { get }
    /// Seconds a play itself consumes when it ends in bounds.
    static var inBoundsPlaySeconds: Int { get }
    /// Seconds a play consumes when it ends out of bounds or incomplete.
    static var stoppedPlaySeconds: Int { get }
    /// Seconds burned getting to the line when the clock was stopped but restarts on the
    /// ready-for-play rather than the snap — the college first-down rule.
    static var readyForPlaySeconds: Int { get }
    /// **The tier difference `03` §2 names.** Does a first down stop the game clock after the
    /// two-minute timeout, until ready for play?
    static var clockStopsOnFirstDownInsideTwoMinutes: Bool { get }
    /// Timeouts per team per half.
    static var timeoutsPerHalf: Int { get }
    /// The two-minute threshold, in seconds remaining in a half.
    static var twoMinuteSeconds: Int { get }
    /// Overtime format.
    static var overtime: OvertimeFormat { get }
}

/// How a tie is resolved. The two tiers do genuinely different things, and the difference is
/// visible to the player, so it is modelled rather than approximated.
public enum OvertimeFormat: String, Codable, Sendable {
    /// Each team gets a possession from a fixed yard line; repeat until someone leads after both
    /// have had one.
    case alternatingPossessions
    /// A timed period; first score wins after both teams have had a possession, or the period ends.
    case timedPeriod
}

/// College clock constants.
public enum CollegeClockRules: ClockRules {
    public static let quarters = 4
    public static let quarterSeconds = 900
    public static let playClockSeconds = 40
    public static let normalTempoSnapSeconds = 26
    public static let hurryTempoSnapSeconds = 12
    public static let bleedTempoSnapSeconds = 36
    public static let inBoundsPlaySeconds = 6
    public static let stoppedPlaySeconds = 5
    public static let readyForPlaySeconds = 18

    /// NCAA Football Rule 3-3-2-e-1: after the two-minute timeout, a Team A first down stops the
    /// clock until the referee's ready-for-play signal.
    public static let clockStopsOnFirstDownInsideTwoMinutes = true

    public static let timeoutsPerHalf = 3
    public static let twoMinuteSeconds = 120
    public static let overtime = OvertimeFormat.alternatingPossessions
}

/// Pro clock constants.
public enum ProClockRules: ClockRules {
    public static let quarters = 4
    public static let quarterSeconds = 900
    public static let playClockSeconds = 40
    public static let normalTempoSnapSeconds = 30
    public static let hurryTempoSnapSeconds = 14
    public static let bleedTempoSnapSeconds = 38
    public static let inBoundsPlaySeconds = 6
    public static let stoppedPlaySeconds = 5
    /// Unused in this tier — the pro clock does not stop on a first down — but the protocol needs
    /// a value and a tier-specific one is more honest than a shared default.
    public static let readyForPlaySeconds = 18

    /// The pro clock keeps running on a first down.
    public static let clockStopsOnFirstDownInsideTwoMinutes = false

    public static let timeoutsPerHalf = 3
    public static let twoMinuteSeconds = 120
    public static let overtime = OvertimeFormat.timedPeriod
}

/// The tier's clock rules, as an existential-free lookup.
///
/// Returns the metatype rather than an instance so the constants stay static and no allocation
/// happens per snap — the game loop calls this on every play of every one of ~65 college games a
/// week (`03` §4).
public extension Tier {
    var clockRules: any ClockRules.Type {
        switch self {
        case .college: return CollegeClockRules.self
        case .pro: return ProClockRules.self
        }
    }
}
