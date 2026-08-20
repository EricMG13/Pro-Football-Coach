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

    /// Offensive plays per team-game, at the midpoint of `01-RESEARCH.md` §6.5's band for the tier
    /// (pro 60-68, college 67-75). The abstracted model draws around this rather than around
    /// whatever the detailed model currently produces, because the band is the statement about
    /// football and the detailed model is not yet calibrated to it (`docs/STATUS.md`, P4).
    public static let proBaselinePlays = 64.0
    public static let collegeBaselinePlays = 71.0

    /// **[ASSUMPTION]** `01` §6.5 bands the *mean* plays per team-game and says nothing about the
    /// spread, so this is not transcribed. It is set near a real per-team-game standard deviation
    /// so that the shape is plausible rather than flat; `01` §6.3's point is that a model with the
    /// right mean and no variance is a failure that means alone cannot see. Replace it the moment
    /// §6.5 grows a spread row.
    public static let playCountDeviation = 8.0

    /// Bounds a drawn play count to something a game can actually contain. A tail beyond this is
    /// the gaussian's, not football's.
    public static let playCountRange: ClosedRange<Int> = 40...105

    public static let baselineOffensiveYards = 350.0
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
