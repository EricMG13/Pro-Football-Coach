public enum RunOutcomeBand: String, Sendable, CaseIterable {
    case loss, short, medium, explosive, breakaway, fumbleLost
}

public enum PassOutcomeBand: String, Sendable, CaseIterable {
    case sack, interception, incompletion, completion, explosiveCompletion, fumbleLost
}

public enum OutcomeDistributionRules {
    public static let proRunExplosiveMass = 0.118
    public static let collegeRunExplosiveMass = 0.151
    public static let passCompletionMass = 0.640
    public static let passSackMass = 0.060
    public static let passInterceptionMass = 0.022
    public static let proPassExplosiveMass = 0.137
    public static let collegePassExplosiveMass = 0.143
    public static let fumbleLostMass = 0.012

    public static func runWeights(tier: Tier) -> [(RunOutcomeBand, Double)] {
        switch tier {
        case .pro:
            return [(.loss, 0.100), (.short, 0.550 - fumbleLostMass),
                    (.medium, 1 - 0.100 - 0.550 - proRunExplosiveMass),
                    (.explosive, proRunExplosiveMass - 0.010), (.breakaway, 0.010),
                    (.fumbleLost, fumbleLostMass)]
        case .college:
            return [(.loss, 0.100), (.short, 0.520 - fumbleLostMass),
                    (.medium, 1 - 0.100 - 0.520 - collegeRunExplosiveMass),
                    (.explosive, collegeRunExplosiveMass - 0.015), (.breakaway, 0.015),
                    (.fumbleLost, fumbleLostMass)]
        }
    }

    public static func passWeights(tier: Tier) -> [(PassOutcomeBand, Double)] {
        let explosive = tier == .pro ? proPassExplosiveMass : collegePassExplosiveMass
        return [(.sack, passSackMass), (.interception, passInterceptionMass),
                (.incompletion, 1 - passSackMass - passInterceptionMass - passCompletionMass),
                (.completion, passCompletionMass - explosive - fumbleLostMass),
                (.explosiveCompletion, explosive), (.fumbleLost, fumbleLostMass)]
    }

    public static let lossYards = -3...0
    public static let shortRunYards = 1...3
    public static let mediumRunYards = 4...9
    public static let explosiveRunYards = 10...18
    public static let breakawayRunYards = 19...60
    public static let ordinaryPassYards = 1...14
    public static let explosivePassYards = 15...35
    public static let runFumbleYards = 1...3
    public static let passFumbleYards = 1...14
    public static let sackYards = -9 ... -4
    public static let puntYards = 35...55
    public static let kneelYards = -1
    public static let maximumProbabilityShift = 0.04
    public static let maximumBallSecurityProbabilityShift = 0.006
    public static let ratingPointsForMaximumShift = 20.0
    public static let maximumDepthProbabilityShift = 0.010
    public static let outsideRunProbabilityShift = 0.010
    public static let runAggressionProbabilityShift = 0.006
    public static let passAggressionProbabilityShift = 0.008
    public static let defensiveAggressionProbabilityShift = 0.006
    public static let rusherSackShiftPerPlayer = 0.006
    public static let coverageShellProbabilityShift = 0.008
    public static let longYardageProbabilityShift = 0.008
    public static let shortYardageProbabilityShift = 0.006
    public static let shortYardageDistance = 2
    public static let longYardageDistance = 7
    public static let targetRatingFloor = 1.0
    public static let riskRewardSplit = 0.5
    public static let passProtectionThrowWeight = 0.5
    public static let minimumAttributionMagnitude = 0.5
    public static let attributionMagnitudeRange = 0.5
    public static let proHomeProbabilityShift = 0.010
    public static let collegeHomeProbabilityShift = 0.045
    public static let proFieldGoalBase = 0.84
    public static let collegeFieldGoalBase = 0.76
    public static let maximumFieldGoalMatchupProbabilityShift = 0.10
    public static let fieldGoalDistancePenaltyPerYard = 0.006
    public static let fieldGoalReferenceDistance = 35
    public static let minimumFieldGoalProbability = 0.02
    public static let maximumFieldGoalProbability = 0.98
    public static let lastFieldYardOffset = 1
    public static let probabilityTolerance = 1e-12
}
