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


    // MARK: - Negotiation. `02` §4.2d.

    /// **Every figure in this market is a share of the cap, never a number of dollars.** The cap
    /// compounds at `capGrowthPercentPerYear`, so it roughly quadruples across a twenty-season
    /// career; a star whose price was written in fixed dollars would cost 5% of the cap in season
    /// zero and 1.3% in season twenty, which is a market that stops existing halfway through the
    /// game the player actually plays. Shares are in ten-thousandths so the arithmetic stays
    /// integer, per `CLAUDE.md`.
    public static let basisPointScale = 10_000

    /// The least a professional deal can pay in a year, as a share of the cap. Set to land beside
    /// `bootstrapMinimumSalary` in the base season so a generated league and a negotiated deal do
    /// not disagree about what the bottom of the market is.
    public static let minimumSalaryBasisPoints = 31

    /// The rating at which a professional is replaceable, and so asks for the minimum. Pro rosters
    /// generate in a band around `RosterPopulationGenerator.baseRating`; below this a club can find
    /// the same player for nothing, which is what a floor means.
    public static let replacementRating = 55

    /// What one rating point above replacement adds to an annual demand, as a share of the cap.
    ///
    /// Calibrated against the generated payroll rather than picked: `bootstrapPayrollPercentOfCap`
    /// over `activeRosterLimit` is about 160 basis points for an average professional, and a
    /// mid-band player at this rate asks for about 155. A whole roster re-signed at its asking
    /// price therefore costs slightly more than the cap, which is the intended shape — you keep a
    /// core, let depth walk, and replace it at the minimum.
    public static let askingBasisPointsPerRatingPoint = 12

    /// Signing bonus, as a share of the annual rate.
    public static let signingBonusPercent = 60

    /// Term by career stage. A declining player asks for what they are worth, for fewer years.
    public static let youngPlayerAge = 25
    public static let youngContractYears = 5
    public static let primeContractYears = 4
    public static let decliningContractYears = 2

    /// What one prestige point is worth to a player weighing two offers, as a share of the cap.
    /// Real money rather than a tiebreak: taking less to join a contender is one of the few things
    /// everybody knows about this market. Across the whole league's prestige span this is worth
    /// about a quarter of a mid-sized deal — enough to lose a bidding war, not enough to win one
    /// from nothing.
    public static let prestigeValueBasisPointsPerPoint = 3

    /// What each year short of the asking term costs an offer's value, as a share of the cap.
    public static let shortTermPenaltyBasisPoints = 35

    /// The cap-relative minimum for a season.
    public static func minimumSalary(seasonsAfterBase seasons: Int) -> Int {
        salaryCap(seasonsAfterBase: seasons) * minimumSalaryBasisPoints / basisPointScale
    }

    /// Turns a share of the cap into dollars for a season.
    public static func capShare(basisPoints: Int, seasonsAfterBase seasons: Int) -> Int {
        salaryCap(seasonsAfterBase: seasons) * basisPoints / basisPointScale
    }

    /// Seasons since the cap's base year, floored at zero, so callers do not each re-derive it.
    public static func seasonsAfterBase(_ season: Int) -> Int {
        Swift.max(0, season - baseSalaryCapSeason)
    }

    // MARK: - The draft

    public static let draftRounds = 7

    public static var draftPicksPerRound: Int { teamCount }

    public static var draftPickCount: Int { draftRounds * draftPicksPerRound }
}
