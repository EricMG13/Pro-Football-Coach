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
    public static let recentChangeHistoryLimit = 6
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
}
