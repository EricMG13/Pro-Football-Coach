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

    /// Pairs of programmes that exchange conferences each season. `02` §8.
    ///
    /// Two, so the map is different after a career and recognisable after a season — canon's own
    /// phrasing is "change the map without churning it". Swaps rather than moves, so every
    /// conference keeps a legal size by construction.
    public static let realignmentSwapsPerSeason = 2

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

    /// A player cannot play in the bye week. The largest possible total is every regular-season
    /// game, the conference championship, and every national-bracket round.
    public static var maximumGamesPerSeason: Int {
        gamesPerRegularSeason + conferenceChampionshipWeeks + bracketRounds
    }

    // MARK: - The roster

    public static let rosterLimit = 105

    /// The sport's limit. Asserted per programme by the soak (`03` section 6).
    public static let scholarshipLimit = 85

    /// Target-scale initial population from `02-GAME-DESIGN.md` section 11.2.1.
    public static let initialRosterByPosition: [Position: Int] = [
        .quarterback: 4,
        .runningBack: 7,
        .wideReceiver: 14,
        .tightEnd: 6,
        .leftTackle: 6,
        .guardPosition: 12,
        .center: 5,
        .rightTackle: 6,
        .edgeRusher: 9,
        .defensiveTackle: 9,
        .linebacker: 11,
        .cornerback: 9,
        .safety: 5,
        .kicker: 1,
        .punter: 1,
    ]

    // MARK: - Recruiting and eligibility

    /// `02` section 4.3's "~25 signings", made exact.
    public static let initialSigningsPerClass = 25

    /// The user-facing shortlist ceiling from `02-GAME-DESIGN.md` section 4.3.
    public static let recruitingBoardLimit = 40

    /// A 20% choice margin over 134 classes of 25 without making the pool a database-sized burden.
    public static var annualProspectCount: Int {
        programmeCount * initialSigningsPerClass * 6 / 5
    }

    /// Integer weekly currency shared by user and AI recruiting actions.
    public static let weeklyRecruitingContactPoints = 100
    public static let aiWeeklyBoardGrowth = 5
    public static let aiBoardDepthBeyondClassTarget = 15
    public static let aiWeeklyInvestmentActionLimit = 15
    public static let aiEvaluationContactPoints = 20
    public static let aiInitialNILAllocation = 500
    public static let minimumCommitmentWeek = 4
    public static let minimumCommitmentScore = 60
    public static let minimumCommitmentFlipScoreImprovement = 10
    public static let commitmentHistoryLimit = 4
    public static let visitContactCost = 30
    public static let visitInterestBonus = 8
    public static let scholarshipOfferInterestBonus = 6
    public static let nilInterestPointsPerUnit = 100
    public static var maximumSeasonRecruitingContactPoints: Int {
        weeklyRecruitingContactPoints * SharedRules.inSeasonWeeks
    }

    /// NIL remains an abstract integer resource rather than salary or currency in M3.
    public static let nilBudgetPerResourcePoint = 100
    public static var maximumNILBudget: Int {
        SharedRules.ratingRange.upperBound * nilBudgetPerResourcePoint
    }

    /// Task 5's bounded national transfer candidate pool.
    public static let portalPoolLimit = 300
    public static let maximumPortalNILReservations = portalPoolLimit
    public static let maximumPortalOffersPerEntrant = 5
    public static var maximumPortalOffersPerWindow: Int {
        portalPoolLimit * maximumPortalOffersPerEntrant
    }
    public static let portalPolicyVersion = 1
    public static let maximumPortalNILBand = 20
    public static let portalIntentReasonCount = 6
    public static let maximumPortalIntentComponentMagnitude = 20
    public static var portalIntentTotalRange: ClosedRange<Int> {
        let magnitude = portalIntentReasonCount * maximumPortalIntentComponentMagnitude
        return -magnitude...magnitude
    }
    public static let portalIntentSelectionThreshold = 25
    public static let portalAdmissionReasonCount = 6
    public static let maximumPortalAdmissionComponentMagnitude = 20
    public static var portalAdmissionTotalRange: ClosedRange<Int> {
        let magnitude = portalAdmissionReasonCount * maximumPortalAdmissionComponentMagnitude
        return -magnitude...magnitude
    }

    public static let prospectAgeRange: ClosedRange<Int> = 17...21
    public static let knowledgeConfidenceRange: ClosedRange<Int> = 0...100
    public static let maximumScoutingEvidence = 10_000
    public static let maximumProspectKnowledgeConfidence = 95
    public static let maximumObservationsPerProgramme = 5_000
    public static var maximumPendingEvaluations: Int {
        programmeCount * recruitingBoardLimit
    }
    public static let maximumArchivedProspectIdentities = 100_000
    public static let walkOnRatingPenalty = 12

    public static let seasonsOfCompetition = 4

    public static let maximumRedshirtAppearances = 4
    public static let redshirtAppearanceLimitRange = 0...maximumRedshirtAppearances

    /// The clock is a year longer than the seasons it holds. That year is the redshirt, and
    /// spending it is `02` section 4.1's redshirt decision.
    public static let eligibilityClockYears = 5

    /// `02` section 4.1: one after the bracket, one in spring.
    public static let portalWindowCount = 2

    // MARK: - Signing day

    /// `02` section 4.1. The last week of the shared calendar: the college bracket ends in week 17
    /// (`seasonWeeks`), so the college coach has no game left and the class is what the week is for.
    ///
    /// Derived from the shared calendar rather than written as 21, so it cannot disagree with the
    /// week the world actually ends on.
    public static var signingDayWeek: Int { SharedRules.inSeasonWeeks }

    /// The cycle phase a given week carries.
    ///
    /// The phase is a *function of the week*, never a flag a system sets and another reads back.
    /// It was the latter, and the result was a case no code path could reach: `signing` existed in
    /// the enum and in `SigningDayView`, and nothing assigned it. Deriving it here means every
    /// caller — the scheduler that advances the world, the integrity check that polices it, and the
    /// session that opens a saved one — agrees by construction instead of by discipline.
    public static func recruitingCyclePhase(inWeek week: Int) -> RecruitingCyclePhase {
        week == signingDayWeek ? .signing : .active
    }
}
