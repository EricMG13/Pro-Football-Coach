import Foundation

/// Which side has the ball.
public enum Side: String, Codable, Sendable, CaseIterable {
    case home, away

    public var opponent: Side { self == .home ? .away : .home }
}

/// The state a snap resolves against.
///
/// `03-MATCH-ENGINE.md` §2: "Situation is a value type carried into resolution: down, distance,
/// field position, score differential, time remaining, timeouts. **Every call-in trigger in `02`
/// reads it.**" So the call-in triggers live here as computed properties rather than in the UI —
/// a trigger the view computed would be a rule the engine could not test.
public struct Situation: Codable, Sendable, Equatable {
    /// 1 through 4.
    public var down: Int
    /// Yards needed for a first down.
    public var distance: Int
    /// Yards from the offence's own goal line, 0 to 100. 75 means the ball is on the opponent's
    /// 25-yard line.
    public var yardLine: Int
    public var possession: Side
    public var homeScore: Int
    public var awayScore: Int
    /// 1-based; a value above the tier's regulation quarters is overtime.
    public var quarter: Int
    public var secondsRemainingInQuarter: Int
    public var timeoutsRemaining: [Side: Int]

    public init(
        down: Int = 1,
        distance: Int = 10,
        yardLine: Int = 25,
        possession: Side = .home,
        homeScore: Int = 0,
        awayScore: Int = 0,
        quarter: Int = 1,
        secondsRemainingInQuarter: Int = 900,
        timeoutsRemaining: [Side: Int] = [.home: 3, .away: 3]
    ) {
        self.down = down
        self.distance = distance
        self.yardLine = yardLine
        self.possession = possession
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.quarter = quarter
        self.secondsRemainingInQuarter = secondsRemainingInQuarter
        self.timeoutsRemaining = timeoutsRemaining
    }

    /// Yards to the opponent's goal line.
    public var yardsToGoal: Int { 100 - yardLine }

    /// Score from the perspective of whoever has the ball. Negative means trailing.
    public var scoreDifferential: Int {
        possession == .home ? homeScore - awayScore : awayScore - homeScore
    }

    public var isRedZone: Bool { yardsToGoal <= MatchupRules.redZoneYards }

    public var isGoalToGo: Bool { distance >= yardsToGoal }

    /// A first down would not be enough to matter — the whole drive is the fourth down.
    public var isFourthDown: Bool { down == 4 }

    public var isThirdAndLong: Bool { down == 3 && distance >= MatchupRules.longYardage }

    /// Seconds left in the half, which is what two-minute logic reads. The quarter alone is not
    /// enough: 30 seconds left in the first quarter is not a two-minute situation.
    public func secondsRemainingInHalf(rules: any ClockRules.Type) -> Int {
        let quartersLeftInHalf = quarter % 2 == 1 ? 1 : 0
        return secondsRemainingInQuarter + quartersLeftInHalf * rules.quarterSeconds
    }

    public func isTwoMinute(rules: any ClockRules.Type) -> Bool {
        secondsRemainingInHalf(rules: rules) <= rules.twoMinuteSeconds
    }

    /// Whether this snap should pull the coach in, per `02` §3.1's trigger list.
    ///
    /// Five of the seven triggers are properties of the situation and live here. The other two —
    /// "the opponent has shown a tendency the plan did not anticipate" and "the game plan leaves the
    /// situation genuinely open" — need the plan and the game's history, so `DriveEngine` adds them.
    /// Splitting them is deliberate: these five are testable against a `Situation` alone.
    public func situationalCallInTriggers(rules: any ClockRules.Type,
                                          isSnapAfterTurnover: Bool) -> [CallInTrigger] {
        var triggers: [CallInTrigger] = []
        if isFourthDown { triggers.append(.fourthDown) }
        if isRedZone { triggers.append(.redZone) }
        if isTwoMinute(rules: rules) { triggers.append(.twoMinute) }
        if isThirdAndLong { triggers.append(.thirdAndLong) }
        if isSnapAfterTurnover { triggers.append(.afterTurnover) }
        return triggers
    }
}

/// Why the coach is being pulled in. `02` §3.1 lists seven; the surface shows the reason, so it is
/// modelled rather than inferred.
public enum CallInTrigger: String, Codable, Sendable, CaseIterable {
    case fourthDown
    case redZone
    case twoMinute
    case thirdAndLong
    case afterTurnover
    case unanticipatedTendency
    case planLeavesItOpen

    public var label: String {
        switch self {
        case .fourthDown: return "Fourth down"
        case .redZone: return "Red zone"
        case .twoMinute: return "Two minutes"
        case .thirdAndLong: return "Third and long"
        case .afterTurnover: return "After the turnover"
        case .unanticipatedTendency: return "They have shown something new"
        case .planLeavesItOpen: return "The plan does not cover this"
        }
    }
}
