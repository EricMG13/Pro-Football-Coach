import Foundation

public enum CompetitionRules {
    public static var maximumParticipantsPerTeam: Int {
        max(CollegeRules.rosterLimit, ProRules.activeRosterLimit)
    }

    public static let collegeBaselinePoints = 27.0
    public static let proBaselinePoints = 23.0
    public static let collegeScoreDeviation = 10.0
    public static let proScoreDeviation = 8.0
    public static let strengthPointScale = 0.24
    public static let homeFieldPoints = 2.4
    public static let maximumTeamScore = 70
    public static let overtimeFieldGoalPoints = 3
    public static let overtimeTouchdownPoints = 6
    public static var maximumFinalTeamScore: Int {
        maximumTeamScore + overtimeTouchdownPoints
    }
    public static let overtimeFieldGoalProbability = 0.72
    public static let overtimeHomeWinProbability = 0.52

    public static let baselineOffensiveYards = 350.0
    public static let strengthYardScale = 4.0
    public static let offensiveYardDeviation = 70.0
    public static let offensiveYardRange: ClosedRange<Int> = 120...750
    public static let turnoverRange: ClosedRange<Int> = 0...4
    public static let touchdownPointEstimate = 10
    public static let playerAwardTouchdownValue = 50

    /// What a defensive season's events are worth against its tackle count, for the award order.
    /// `02` §3.11 made these countable; these weights are what make them comparable.
    public static let awardSackValue = 25
    public static let awardInterceptionValue = 40
    public static let awardForcedFumbleValue = 30
    public static let awardPassDefendedValue = 8

    // MARK: - The abstracted box score

    /// Rates the abstracted box score derives its counters at. `02` §3.11.
    ///
    /// **Derivations, not draws.** Each one turns a yardage total the simulator already produced
    /// into the count that total implies, so a box score cannot contradict the team line it came
    /// from and no seeded output moves because these exist. **Not calibrated**: `03` §5.1 bands
    /// yards and rates, not counts, and a number fitted here by eye would make the eventual band a
    /// formality.
    public static let yardsPerCompletion = 11
    public static let completionPercentEstimate = 62
    public static let yardsPerCarry = 4
    public static let fieldGoalPercentEstimate = 80
    /// What share of a team's touchdowns were thrown rather than run.
    public static let passingTouchdownPercent = 62
    public static let sacksPerHundredPassYards = 1
    public static let basePenaltiesPerGame = 5
    public static let penaltyVarianceModulus = 4
    public static let averagePenaltyYards = 9
    public static let basePuntsPerGame = 8
    /// Every this many offensive yards is one fewer punt: a team that moves the ball punts less.
    public static let yardsPerFewerPunt = 90
    /// Tackles are counted per hundred plays the opponent ran, which is what makes the number scale
    /// with the tier's tempo rather than being a flat per-game figure.
    public static let tacklesPerHundredPlays = 95
    public static let abstractedRunnersPerGame = 2
    public static let abstractedReceiversPerGame = 4
    public static let abstractedTacklersPerGame = 8
    /// Plays an abstracted team is treated as having run, for counters that scale with volume.
    public static let abstractedPlaysPerGame = 64

    public static func baselinePoints(for tier: Tier) -> Double {
        tier == .college ? collegeBaselinePoints : proBaselinePoints
    }

    public static func scoreDeviation(for tier: Tier) -> Double {
        tier == .college ? collegeScoreDeviation : proScoreDeviation
    }

    public static func passingSharePercent(for scheme: OffensiveScheme) -> Int {
        switch scheme {
        case .airRaid, .runAndShoot: return 68
        case .westCoast: return 63
        case .proStyle: return 58
        case .spreadOption: return 52
        case .powerRun: return 45
        }
    }
}
