import Foundation

/// The college tier's rules, from `02-GAME-DESIGN.md` section 11.1.
///
/// Every number the college tier needs is here. A magic number anywhere else in the engine is a
/// defect, and derived quantities are computed from their parts rather than written down twice —
/// a season length stated independently of the weeks that make it up is a number that drifts the
/// first time one of those weeks changes.
public enum CollegeRules {
    // MARK: - The league

    /// D14, decided without owner input and marked reversible in `docs/STATUS.md`. P5 tests the
    /// fallback to 64 if the week-advance ceiling cannot be met at this scale.
    public static let programmeCount = 134

    public static let conferenceCount = 10

    /// `02` section 11.4: composition is generated, not listed, so the map differs per save. The
    /// rules module owns the shape only.
    public static let conferenceSizeRange: ClosedRange<Int> = 12...16

    // MARK: - The calendar

    public static let gamesPerRegularSeason = 12
    public static let byeWeeksPerRegularSeason = 1

    /// Every programme plays a game or takes a bye in each of these weeks.
    public static var regularSeasonWeeks: Int { gamesPerRegularSeason + byeWeeksPerRegularSeason }

    public static let conferenceChampionshipWeeks = 1

    public static let bracketTeams = 8

    /// Halving 8 down to 1 takes 3 rounds. Derived so the two cannot disagree.
    ///
    /// `trailingZeroBitCount` is log2 for a power of two and needs no floating point to say so. A
    /// bracket size that is not a power of two would need byes, and `RulesTests` asserts
    /// `1 << bracketRounds == bracketTeams` so that change cannot arrive silently.
    public static var bracketRounds: Int { bracketTeams.trailingZeroBitCount }

    /// `02` section 2.3's ~17 weeks, made exact.
    public static var seasonWeeks: Int {
        regularSeasonWeeks + conferenceChampionshipWeeks + bracketRounds
    }

    // MARK: - The roster

    public static let rosterLimit = 105

    /// The sport's limit. Asserted per programme by the soak (`03` section 6).
    public static let scholarshipLimit = 85

    // MARK: - Recruiting and eligibility

    /// `02` section 4.3's "~25 signings", made exact.
    public static let initialSigningsPerClass = 25

    public static let seasonsOfCompetition = 4

    /// The clock is a year longer than the seasons it holds. That year is the redshirt, and
    /// spending it is `02` section 4.1's redshirt decision.
    public static let eligibilityClockYears = 5

    /// `02` section 4.1: one after the bracket, one in spring.
    public static let portalWindowCount = 2
}
