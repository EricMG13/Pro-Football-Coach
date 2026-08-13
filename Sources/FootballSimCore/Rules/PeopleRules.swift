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
