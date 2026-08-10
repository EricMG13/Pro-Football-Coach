import Foundation

/// The pro tier's rules, from `02-GAME-DESIGN.md` section 11.2.
///
/// Money is integer dollars throughout. `CLAUDE.md`: no floating-point currency, anywhere, for any
/// reason — a percentage applied as a `Double` and rounded is how a cap ends up a dollar out from
/// itself after twenty seasons, which the soak then reports as an illegal roster.
public enum ProRules {
    // MARK: - The league

    public static let conferenceCount = 2
    public static let divisionsPerConference = 4
    public static let teamsPerDivision = 4

    public static var teamCount: Int {
        conferenceCount * divisionsPerConference * teamsPerDivision
    }

    // MARK: - The calendar

    public static let gamesPerRegularSeason = 17
    public static let byeWeeksPerRegularSeason = 1

    public static var regularSeasonWeeks: Int { gamesPerRegularSeason + byeWeeksPerRegularSeason }

    /// Four per conference. No first-round bye, so the bracket is a clean three rounds and the
    /// season lands on `02` section 2.3's ~21 weeks exactly.
    public static let bracketTeams = 8

    public static var bracketRounds: Int { bracketTeams.trailingZeroBitCount }

    public static var seasonWeeks: Int { regularSeasonWeeks + bracketRounds }

    // MARK: - The roster

    public static let activeRosterLimit = 53
    public static let gamedayActiveLimit = 48

    /// P8's cap-laundering defences apply here specifically: the practice squad is where the prior
    /// build's attack hid a contract.
    public static let practiceSquadLimit = 16

    // MARK: - Money

    public static let baseSalaryCap = 255_000_000

    /// Applied as integer arithmetic, compounding once per season.
    public static let capGrowthPercentPerYear = 7

    /// The cap `seasonsAfterBase` seasons after the base year.
    ///
    /// Compounds in integers: each season's growth is computed from that season's cap and truncated,
    /// so the sequence is exactly reproducible and never accumulates a fractional cent. Truncation
    /// is deliberate and downward — a cap that rounds up is a cap teams can exceed.
    /// A season before the base returns the base cap rather than trapping. `Rating` sets the
    /// project's policy for a value that can arrive from a corrupt save — clamp, never trap — and
    /// `season` arrives from disk. A `precondition` here turns a bad save into a crash on the cap
    /// screen.
    public static func salaryCap(seasonsAfterBase seasons: Int) -> Int {
        var cap = baseSalaryCap
        for _ in 0..<Swift.max(0, seasons) {
            cap += cap * capGrowthPercentPerYear / 100
        }
        return cap
    }

    /// A signing bonus spreads over the contract's length, to a maximum of five years. The
    /// remainder of an unamortised bonus is what becomes dead money when a player is released,
    /// which is P8's business.
    public static let maximumProrationYears = 5

    /// `02` section 11.2. An upper bound so a save claiming `years: 9223372036854775807` clamps
    /// instead of asking for an unbounded allocation and trapping.
    public static let contractYearsRange: ClosedRange<Int> = 1...7

    // MARK: - The draft

    public static let draftRounds = 7

    public static var draftPicksPerRound: Int { teamCount }

    public static var draftPickCount: Int { draftRounds * draftPicksPerRound }
}
