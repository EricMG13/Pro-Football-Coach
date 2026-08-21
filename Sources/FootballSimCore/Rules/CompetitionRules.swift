import Foundation

public enum CompetitionRules {
    public static var maximumParticipantsPerTeam: Int {
        max(CollegeRules.rosterLimit, ProRules.activeRosterLimit)
    }

    /// Back-solved against the detailed reducer's controlled-fixture tuning worlds rather than the
    /// disjoint holdout or generated-schedule aggregate, which includes a separate
    /// roster-composition effect.
    public static let collegeBaselinePoints = 23.5
    public static let proBaselinePoints = 20.5
    public static let collegeScoreDeviation = 10.0
    public static let proScoreDeviation = 8.0
    public static let strengthPointScale = 0.24
    /// Home advantage, in points, per tier.
    ///
    /// **One shared constant could not hold both bands.** `01-RESEARCH.md` §6.5 asks for a home win
    /// rate of 0.50-0.58 professionally and 0.60-0.68 in college, and a single number produced
    /// 0.575 and 0.562 — inside the professional band and below the college one. The tiers disagree
    /// in canon, so the constant has to.
    ///
    /// Both values are back-solved from the controlled tuning worlds rather than the holdout. The
    /// detailed reducer's home rates are 0.511 professionally and 0.670 in college there.
    ///
    /// **Caveat worth carrying to the owner.** 5.5 points is roughly double what college home-field
    /// is worth on a real spread. §6.5's college band is high partly because real college home
    /// teams are systematically stronger — the bought non-conference game — and a generated
    /// schedule has no such bias, so this one constant absorbs both effects. If §6.5 ever splits
    /// true home advantage from home *scheduling* advantage, this number comes down and the
    /// schedule generator takes the rest.
    public static let proHomeFieldPoints = 0.5
    public static let collegeHomeFieldPoints = 6.25
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
    /// Controlled-fixture scrimmage-play means, measured on the tuning worlds after punts and field
    /// goals were removed from the detailed summary's denominator.
    public static let proBaselinePlays = 56.0
    public static let collegeBaselinePlays = 67.0

    /// **[ASSUMPTION]** `01` §6.5 bands the *mean* plays per team-game and says nothing about the
    /// spread, so this is not transcribed. It is set near a real per-team-game standard deviation
    /// so that the shape is plausible rather than flat; `01` §6.3's point is that a model with the
    /// right mean and no variance is a failure that means alone cannot see. Replace it the moment
    /// §6.5 grows a spread row.
    public static let playCountDeviation = 8.0

    /// Bounds a drawn play count to something a game can actually contain. A tail beyond this is
    /// the gaussian's, not football's.
    public static let playCountRange: ClosedRange<Int> = 40...105

    public static let proBaselineOffensiveYards = 300.0
    public static let collegeBaselineOffensiveYards = 350.0
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

    public static func homeFieldPoints(for tier: Tier) -> Double {
        tier == .college ? collegeHomeFieldPoints : proHomeFieldPoints
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
