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

    /// The per-conference half of `bracketTeams` -- named separately because the bracket is seeded
    /// within each conference, not by overall rank (`PostseasonSystem.advance`'s pro quarterfinal
    /// case takes the top `playoffSeedsPerConference` of each conference's own ranking, not the
    /// top `bracketTeams` overall). `bracketTeams == conferenceCount * playoffSeedsPerConference`.
    public static let playoffSeedsPerConference = 4

    public static var bracketRounds: Int { bracketTeams.trailingZeroBitCount }

    public static var seasonWeeks: Int { regularSeasonWeeks + bracketRounds }

    /// A player cannot play in the bye week, so the possible game total is smaller than the shared
    /// calendar even for a team that reaches the championship.
    public static var maximumGamesPerSeason: Int {
        gamesPerRegularSeason + bracketRounds
    }

    // MARK: - The roster

    public static let activeRosterLimit = 53
    public static let gamedayActiveLimit = 48

    /// Target-scale initial population from `02-GAME-DESIGN.md` section 11.2.1.
    public static let initialRosterByPosition: [Position: Int] = [
        .quarterback: 3,
        .runningBack: 4,
        .wideReceiver: 6,
        .tightEnd: 3,
        .leftTackle: 2,
        .guardPosition: 5,
        .center: 2,
        .rightTackle: 2,
        .edgeRusher: 4,
        .defensiveTackle: 4,
        .linebacker: 5,
        .cornerback: 6,
        .safety: 5,
        .kicker: 1,
        .punter: 1,
    ]

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

    /// How many distinct terms a bootstrapped roster rotates through, so roughly `1/spread` of it
    /// expires each season (`02` section 4.2a).
    ///
    /// Five, not four, and the reason is a bound rather than a preference: expiries land in a
    /// free-agent pool capped at `ProMarketState.maximumFreeAgentIDs` (512) against
    /// `teamCount * activeRosterLimit` professionals. A quarter of 1,696 is 424, which fits only if
    /// every prior year's unsigned player has already left the pool; a fifth is about 339, which
    /// leaves headroom for carryover and still turns over eleven players per roster per season.
    public static let bootstrapContractTermSpread = 5

    /// The share of the cap a bootstrapped roster commits, leaving room for the draft class and
    /// in-season signings. A league that spends its whole cap at generation is non-compliant the
    /// moment it drafts anyone.
    public static let bootstrapPayrollPercentOfCap = 85

    /// The floor a bootstrapped deal pays. Weighted shares of a payroll can round to nothing for
    /// the last man on a roster, and a contract paying zero is not a contract.
    public static let bootstrapMinimumSalary = 795_000

    /// The season the base cap is stated for; cap growth compounds from here.
    public static let baseSalaryCapSeason = 0


    // MARK: - The draft

    public static let draftRounds = 7

    public static var draftPicksPerRound: Int { teamCount }

    public static var draftPickCount: Int { draftRounds * draftPicksPerRound }
}
