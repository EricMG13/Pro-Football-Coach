import Foundation

public enum CompetitionRules {
    public static var maximumParticipantsPerTeam: Int {
        max(CollegeRules.rosterLimit, ProRules.activeRosterLimit)
    }

    public static let collegeBaselinePoints = 25.5
    public static let proBaselinePoints = 22.6
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
    /// Both values are back-solved from the controlled tuning worlds rather than the final holdout.
    /// The detailed reducer's home rates are 0.539 professionally and 0.655 in college there.
    ///
    /// **Caveat worth carrying to the owner.** 6.25 points is roughly double what college
    /// home-field is worth on a real spread. §6.5's college band is high partly because real
    /// college home teams are systematically stronger — the bought non-conference game — and a
    /// generated schedule has no such bias, so this one constant absorbs both effects. If §6.5 ever
    /// splits true home advantage from home *scheduling* advantage, this number comes down and the
    /// schedule generator takes the rest.
    public static let proHomeFieldPoints = 1.5
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

    /// Controlled-fixture scrimmage-play means, measured on the tuning worlds after punts and
    /// field goals were removed from the detailed summary's denominator.
    public static let proBaselinePlays = 63.3
    public static let collegeBaselinePlays = 73.0

    /// **[ASSUMPTION]** `01` §6.5 bands the *mean* plays per team-game and says nothing about the
    /// spread, so this is not transcribed. It is set near a real per-team-game standard deviation
    /// so that the shape is plausible rather than flat; `01` §6.3's point is that a model with the
    /// right mean and no variance is a failure that means alone cannot see. Replace it the moment
    /// §6.5 grows a spread row.
    public static let playCountDeviation = 8.0

    /// Bounds a drawn play count to something a game can actually contain. A tail beyond this is
    /// the gaussian's, not football's.
    public static let playCountRange: ClosedRange<Int> = 40...105
    public static let baselineCompletionProbability = 0.618
    public static let collegeBaselineCompletionProbability = 0.617
    public static let strengthCompletionProbabilityScale = 0.003
    public static let baselineSackProbability = 0.084
    public static let collegeBaselineSackProbability = 0.0856
    public static let strengthSackProbabilityScale = 0.001
    public static let baselineTurnoverProbability = 0.0333
    public static let collegeBaselineTurnoverProbability = 0.036
    public static let proBaselineExplosiveRunProbability = 0.1175
    public static let collegeBaselineExplosiveRunProbability = 0.15
    public static let proBaselineExplosivePassProbability = 0.1375
    public static let collegeBaselineExplosivePassProbability = 0.143

    public static let proBaselineOffensiveYards = 300.0
    public static let collegeBaselineOffensiveYards = 360.0
    public static let strengthYardScale = 4.0
    public static let offensiveYardDeviation = 70.0
    public static let offensiveYardRange: ClosedRange<Int> = 120...750
    public static let turnoverRange: ClosedRange<Int> = 0...4
    public static let touchdownPointEstimate = 10
    public static let playerAwardTouchdownValue = 50
    public static let wr1TargetShare = 0.48
    public static let wr2TargetShare = 0.17
    public static let wr3PlusTargetShare = 0.03
    public static let tightEndTargetShare = 0.23
    public static let runningBackTargetShare = 0.08
    public static let primaryBackCarryShare = 0.70
    public static let reserveBackCarryShare = 0.25
    public static let quarterbackCarryShare = 0.05

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

    public static func baselineExplosiveRunProbability(for tier: Tier) -> Double {
        tier == .college
            ? collegeBaselineExplosiveRunProbability
            : proBaselineExplosiveRunProbability
    }

    public static func baselineExplosivePassProbability(for tier: Tier) -> Double {
        tier == .college
            ? collegeBaselineExplosivePassProbability
            : proBaselineExplosivePassProbability
    }

    public static func baselineCompletionProbability(for tier: Tier) -> Double {
        tier == .college ? collegeBaselineCompletionProbability : baselineCompletionProbability
    }

    public static func baselineSackProbability(for tier: Tier) -> Double {
        tier == .college ? collegeBaselineSackProbability : baselineSackProbability
    }

    public static func baselineTurnoverProbability(for tier: Tier) -> Double {
        tier == .college ? collegeBaselineTurnoverProbability : baselineTurnoverProbability
    }

    public static func baselineFourthQuarterScoringShare(for tier: Tier) -> Double {
        tier == .college ? 0.274 : 0.280
    }

    public static func baselineDriveCount(for tier: Tier) -> Int {
        tier == .college ? 23 : 21
    }

    public static func baselineDriveOutcomeProbability(
        for tier: Tier,
        bucket: DriveOutcomeBucket
    ) -> Double {
        let probabilities = tier == .college
            ? [0.2949, 0.0907, 0.0189, 0.3371, 0.1704, 0.0172, 0.0034, 0.0674]
            : [0.2734, 0.0958, 0.0199, 0.3413, 0.1674, 0.0184, 0.0033, 0.0804]
        return probabilities[bucket.rawValue]
    }

    public static func baselineFieldGoalAccuracy(
        for bucket: FieldGoalDistanceBucket,
        tier: Tier
    ) -> Double {
        if tier == .college {
            switch bucket {
            case .under30: return 0.944
            case .from30To39: return 0.856
            case .from40To49: return 0.696
            case .atLeast50: return 0.529
            }
        }
        switch bucket {
        case .under30: return 0.96
        case .from30To39: return 0.90
        case .from40To49: return 0.79
        case .atLeast50: return 0.64
        }
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
