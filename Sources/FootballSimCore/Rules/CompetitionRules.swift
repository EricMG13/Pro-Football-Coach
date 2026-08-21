import Foundation

public enum CompetitionRules {
    public static var maximumParticipantsPerTeam: Int {
        max(CollegeRules.rosterLimit, ProRules.activeRosterLimit)
    }

    public static let collegeBaselinePoints = 26.8
    public static let proBaselinePoints = 23.45
    public static let collegeScoreDeviation = 10.0
    public static let proScoreDeviation = 8.0
    public static let strengthPointScale = 0.24
    public static let homeFieldPoints = 2.4
    public static let maximumTeamScore = 70
    public static let overtimeFieldGoalPoints = 3
    public static let overtimeTouchdownPoints = 6
    /// The bounded timed period used by the detailed reducer when the regulation score is tied.
    /// College alternates possessions inside the same bound; professional regular-season games
    /// may still finish tied after the bound expires.
    public static let overtimePeriodSeconds = 600
    public static let maximumOvertimePeriods = 3
    public static let overtimePossessionYardLine = 75
    public static var maximumFinalTeamScore: Int {
        maximumTeamScore + overtimeTouchdownPoints
    }
    public static let overtimeFieldGoalProbability = 0.72
    public static let overtimeHomeWinProbability = 0.52

    public static let proBaselinePlays = 64.0
    public static let collegeBaselinePlays = 71.0
    public static let playCountDeviation = 8.0
    public static let playCountRange: ClosedRange<Int> = 40...105
    public static let baselineCompletionProbability = 0.645
    public static let strengthCompletionProbabilityScale = 0.003
    public static let baselineSackProbability = 0.032
    public static let strengthSackProbabilityScale = 0.001
    public static let baselineTurnoverProbability = 0.05

    public static let proBaselineOffensiveYards = 350.0
    public static let collegeBaselineOffensiveYards = 386.0
    public static let strengthYardScale = 4.0
    public static let offensiveYardDeviation = 70.0
    public static let offensiveYardRange: ClosedRange<Int> = 120...750
    public static let turnoverRange: ClosedRange<Int> = 0...4
    public static let touchdownPointEstimate = 10
    public static let playerAwardTouchdownValue = 50

    public static func baselinePoints(for tier: Tier) -> Double {
        tier == .college ? collegeBaselinePoints : proBaselinePoints
    }

    public static func scoreDeviation(for tier: Tier) -> Double {
        tier == .college ? collegeScoreDeviation : proScoreDeviation
    }

    public static func baselinePlays(for tier: Tier) -> Double {
        tier == .college ? collegeBaselinePlays : proBaselinePlays
    }

    public static func baselineOffensiveYards(for tier: Tier) -> Double {
        tier == .college ? collegeBaselineOffensiveYards : proBaselineOffensiveYards
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
