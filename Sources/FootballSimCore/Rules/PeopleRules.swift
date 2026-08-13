import Foundation

public enum PeopleRules {
    public static let fatigueRange: ClosedRange<Int> = 0...100
    public static let careerSeasonHistoryLimit = 40
    public static var portalWindowHistoryLimit: Int {
        CollegeRules.portalWindowCount * CollegeRules.eligibilityClockYears
    }
    public static let maximumInjuryWeeks = 52
    public static let maximumDevelopmentComponents = 8
    public static let maximumAttributeChangesPerSummary = 16
    public static let developmentComponentRange: ClosedRange<Int> = -2...2
    public static let attributeDevelopmentRange: ClosedRange<Int> = -1...1
    public static let playerAgeRange: ClosedRange<Int> = 16...60
    public static let staffAgeRange: ClosedRange<Int> = 28...68
    public static let staffPerOrganisation = 1
        + SharedRules.coordinatorCount
        + PositionGroup.allCases.count
    public static let weeklyFatigueRecovery = 10
    public static let gameFatigueLoad = 14
    public static let statisticalWorkloadFatigueMaximum = 10
    public static let fatigueStrengthPenaltyMaximum = 8
    public static let baseWeeklyInjuryProbability = 0.001
    public static let fatigueInjuryProbabilityScale = 0.000_15
    public static let durabilityInjuryProbabilityScale = 0.000_08
    public static let traitPopulationProbability = 0.08
    public static let inSeasonDevelopmentWeeks: [Int] = [8, 16]
    public static let developmentThreshold = 5
    public static let strongCoachRating = 80
    public static let competentCoachRating = 60
    public static let strongWorkEthicRating = 80
    public static let adequateWorkEthicRating = 60
    public static let poorWorkEthicRating = 50
    public static let schemeFitDevelopmentRating = 75
    public static let guaranteedRetirementYearsAfterDecline = 8
    public static let retirementProbabilityPerYearAfterDecline = 0.14

    public static func injuryProbability(fatigue: Int, durability: Rating) -> Double {
        baseWeeklyInjuryProbability
            + Double(min(max(fatigue, fatigueRange.lowerBound), fatigueRange.upperBound))
                * fatigueInjuryProbabilityScale
            + Double(SharedRules.ratingRange.upperBound - durability.value)
                * durabilityInjuryProbabilityScale
    }

    /// How many people are available for a staff role at once. `02` §6.1. Small: a shortlist is a
    /// decision, a directory is a search.
    public static let staffCandidatesPerRole = 5
    /// What is still owed to the coach being replaced, as a fraction of their salary. Replacing an
    /// expensive coach with a cheap one is not free.
    public static let staffSeveranceShare = 2

    // MARK: - Morale

    /// Where a player sits before anything has happened to them. `02` §5.1.
    public static let baselineMorale = 60
    public static let unhappyMorale = 45
    public static let delightedMorale = 78

    /// Appearance share, as a percentage of the team's games, at which a player counts as a starter
    /// or as buried. Between the two they are a rotation player with nothing much to say.
    public static let starterAppearanceShare = 70
    public static let benchAppearanceShare = 25
    /// Win share at which a season counts as contending or as struggling.
    public static let contendingWinShare = 65
    public static let strugglingWinShare = 35

    public static let moralePlayingTimeBonus = 14
    public static let moraleTeamSuccessBonus = 10
    public static let moraleInjuryCost = 8
    public static let moraleInvestmentBonus = 6

    // MARK: - Staff careers. `02` §6.1.

    /// Up to this age a coach is still learning the job; past `staffDeclineAge` the years start
    /// taking something back. Both sit inside `staffAgeRange`, which is the hiring window.
    public static let staffLearningAge = 45
    public static let staffDeclineAge = 62
    /// Seasons in one place before continuity is worth anything. `02` §6 calls continuity a
    /// resource; this is the one place it pays.
    public static let staffSettledSeasons = 3

    public static let staffExperienceValue = 2
    public static let staffAgeCost = 2
    public static let staffResultValue = 2
    public static let staffContinuityValue = 1
    public static let staffDevelopmentNoise: ClosedRange<Int> = -2...2
    /// The score a season has to reach before a rating moves at all. Bounded exactly as player
    /// development is — one attribute, one point, once a season — because a system that can move a
    /// rating faster turns a twenty-season career into a range nobody designed.
    public static let staffDevelopmentThreshold = 3
    /// What a winning or losing season does to what other clubs see.
    public static let staffReputationStep = 2

    /// Where a coach's organisation has to finish for the season to count as a success or a
    /// failure, as a percentile of the final ranking with 100 at the top.
    ///
    /// A percentile rather than a win share, because staff development runs at the season boundary
    /// — after the table has rolled over — and the archived ranking is the only description of the
    /// completed season still standing at that moment. It is also what prestige is moved by, so
    /// "a good season" means one thing in this game rather than two.
    public static let staffSuccessPercentile = 70
    public static let staffFailurePercentile = 30

    /// How many coordinators change hands in one offseason, at most. A market that moved everybody
    /// every year would make continuity unbuyable rather than valuable.
    public static let maximumPoachingsPerSeason = 6
    /// The reputation a coordinator needs before anybody comes for them.
    public static let poachableReputation = 68
    /// How much more prestigious the poacher has to be. A lateral move is not a poaching, and
    /// without a gap the market would churn between equals forever.
    public static let poachingPrestigeGap = 8

    // MARK: - Preseason camp. `02` §5.3.

    /// How close two players have to be for the job to count as open. Three points of overall is
    /// inside the noise a camp can move, which is what makes it a battle rather than a depth chart.
    public static let campBattleRatingGap = 3
    /// A report is a screen, not a census.
    public static let maximumCampMovements = 10
    public static let maximumCampBattles = 8

    // MARK: - Discipline. `02` §5.2.

    /// The longest a coach can put one of their own players out. Bounded because a suspension is a
    /// stored countdown and an unbounded one is a player removed from the game by a screen.
    public static let maximumSuspensionWeeks = 8

    /// How often a settled, contented professional gets into trouble in a given week. Small: an
    /// incident every week is a soap opera, and one a season across a roster is a football team.
    public static let baseIncidentProbability = 0.004
    /// What `volatile` adds to that. `02` §11.3.3 names Discipline as the trait's authoritative
    /// system, and this is the half of it that decides who turns up in the file.
    public static let volatileIncidentProbability = 0.020
    /// What being unhappy adds. Morale is derived (`02` §5.1), so this is the one place the two
    /// systems meet: a player nobody plays and nobody pays is the one who misses meetings.
    public static let unhappyIncidentProbability = 0.012

    /// What a coach is advised to give for each kind, in weeks. Advice, not enforcement — `02` §5.2
    /// makes the response the coach's, and a game that suspended players on the coach's behalf would
    /// be administering its own discipline.
    public static let recommendedSuspensionWeeks: [DisciplineIncidentKind: Int] = [
        .timekeeping: 0,
        .conduct: 1,
        .teamRules: 2,
        .offField: 4,
    ]

    /// What being suspended costs morale, per week of the suspension, to a stated floor. A player
    /// who is punished feels worse about the place, which is the loop that makes discipline a
    /// decision rather than a free action.
    public static let moraleSuspensionCostPerWeek = 4
    public static let maximumMoraleSuspensionCost = 20

    // MARK: - Injury severity

    /// The severity ladder, as constants rather than as literals at a call site.
    ///
    /// These four numbers lived inline in `PeopleLifecycleSystem`'s weekly draw — `0.72`, `0.95` and
    /// the three week ranges — which `CLAUDE.md` forbids and which mattered the moment a second
    /// caller needed the same ladder: the match engine's in-play injuries (`02` §3.8) would
    /// otherwise have carried a hand-copied duplicate that nothing asserts agrees.
    public static let minorInjuryShare = 0.72
    public static let moderateInjuryShare = 0.95
    public static let minorInjuryWeeks: ClosedRange<Int> = 1...2
    public static let moderateInjuryWeeks: ClosedRange<Int> = 3...6
    public static let severeInjuryWeeks: ClosedRange<Int> = 7...14

    /// Severity and its week range, from one uniform roll.
    public static func injurySeverity(
        roll: Double
    ) -> (severity: InjurySeverity, weeks: ClosedRange<Int>) {
        if roll < minorInjuryShare { return (.minor, minorInjuryWeeks) }
        if roll < moderateInjuryShare { return (.moderate, moderateInjuryWeeks) }
        return (.severe, severeInjuryWeeks)
    }

    /// What `ironman` is worth: a share of the weeks lost, never below one.
    ///
    /// `02` §11.3.3 says the trait "recovers faster, misses fewer weeks". This is the second half of
    /// that sentence, and the first half stays with recovery in the lifecycle system.
    public static let ironmanInjuryWeekShare = 0.6

    public static func injuryWeeks(_ weeks: Int, ironman: Bool) -> Int {
        guard ironman else { return weeks }
        return max(1, Int((Double(weeks) * ironmanInjuryWeekShare).rounded()))
    }
}
