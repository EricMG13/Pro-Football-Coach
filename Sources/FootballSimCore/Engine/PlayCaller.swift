import Foundation

/// The situation a play is called in. Everything the AI needs to decide, in one value.
public struct GameSituation: Codable, Sendable, Equatable {
    public var quarter: Int
    public var clockSeconds: Int
    public var down: Int
    public var distance: Int
    /// Yards from the offense's own goal line, 0...100.
    public var yardLine: Int
    public var offenseScore: Int
    public var defenseScore: Int
    public var offenseTimeouts: Int
    public var defenseTimeouts: Int
    public var isOvertime: Bool

    public init(
        quarter: Int = 1,
        clockSeconds: Int = LeagueRules.quarterLengthSeconds,
        down: Int = 1,
        distance: Int = 10,
        yardLine: Int = 25,
        offenseScore: Int = 0,
        defenseScore: Int = 0,
        offenseTimeouts: Int = LeagueRules.timeoutsPerHalf,
        defenseTimeouts: Int = LeagueRules.timeoutsPerHalf,
        isOvertime: Bool = false
    ) {
        self.quarter = quarter
        self.clockSeconds = clockSeconds
        self.down = down
        self.distance = distance
        self.yardLine = yardLine
        self.offenseScore = offenseScore
        self.defenseScore = defenseScore
        self.offenseTimeouts = offenseTimeouts
        self.defenseTimeouts = defenseTimeouts
        self.isOvertime = isOvertime
    }

    public var yardsToGoal: Int { LeagueRules.fieldLengthYards - yardLine }
    public var scoreDifferential: Int { offenseScore - defenseScore }
    public var isRedZone: Bool { yardsToGoal <= 20 }
    public var isGoalToGo: Bool { distance >= yardsToGoal }
    public var fieldGoalDistance: Int { yardsToGoal + 17 }
    public var isInFieldGoalRange: Bool { fieldGoalDistance <= PlayMatrix.maxFieldGoalDistance - 3 }

    /// Seconds left in the game, treating regulation as four quarters.
    public var secondsRemainingInHalf: Int {
        let quartersLeftInHalf = (quarter == 1 || quarter == 3) ? 1 : 0
        return clockSeconds + quartersLeftInHalf * LeagueRules.quarterLengthSeconds
    }

    public var isTwoMinuteDrill: Bool {
        secondsRemainingInHalf <= 120 && (quarter == 2 || quarter == 4 || isOvertime)
    }
}

/// Chooses plays for a team without a human at the wheel. Also produces the "Suggested" call
/// shown to the user, at a quality set by the coordinator's rating.
public enum PlayCaller {

    /// The offensive call an AI (or a coordinator suggestion) would make.
    public static func offensiveCall(
        situation: GameSituation,
        team: Team,
        coordinatorQuality: Double = 0.8,
        rng: inout SeededRandom
    ) -> OffensivePlay {
        // Situations with only one sane answer come first.
        if let forced = forcedCall(situation: situation, team: team, rng: &rng) { return forced }

        var weights: [OffensivePlay: Double] = [
            .insideRun: 1.00,
            .outsideRun: 0.62,
            .shortPass: 1.30,
            .deepPass: 0.42,
            .playAction: 0.50,
            .screen: 0.32,
        ]

        // Down and distance.
        switch situation.down {
        case 1:
            weights[.insideRun]! *= 1.35
            weights[.outsideRun]! *= 1.20
            weights[.playAction]! *= 1.30
            weights[.deepPass]! *= 0.95
        case 2:
            if situation.distance >= 8 {
                weights[.shortPass]! *= 1.25
                weights[.deepPass]! *= 1.15
            } else {
                weights[.insideRun]! *= 1.25
            }
        case 3:
            if situation.distance <= 2 {
                weights[.insideRun]! *= 2.4
                weights[.deepPass]! *= 0.35
                weights[.screen]! *= 0.4
            } else if situation.distance >= 8 {
                weights[.insideRun]! *= 0.20
                weights[.outsideRun]! *= 0.25
                weights[.shortPass]! *= 1.35
                weights[.deepPass]! *= 1.60
                weights[.screen]! *= 1.10
            } else {
                weights[.shortPass]! *= 1.40
                weights[.insideRun]! *= 0.55
            }
        default:
            weights[.insideRun]! *= 1.6
            weights[.shortPass]! *= 1.2
        }

        // Scheme identity — a power-run team and an air-raid team should not call alike.
        switch team.offensiveScheme {
        case .powerRun:
            weights[.insideRun]! *= 1.55
            weights[.outsideRun]! *= 1.25
            weights[.deepPass]! *= 0.75
        case .vertical:
            weights[.deepPass]! *= 1.85
            weights[.playAction]! *= 1.25
            weights[.insideRun]! *= 0.80
        case .spread:
            weights[.shortPass]! *= 1.35
            weights[.screen]! *= 1.55
            weights[.insideRun]! *= 0.75
        case .westCoast:
            weights[.shortPass]! *= 1.45
            weights[.screen]! *= 1.20
            weights[.deepPass]! *= 0.85
        case .balanced:
            break
        }

        // Clock context: chasing points means throwing, protecting a lead means running.
        if situation.isTwoMinuteDrill && situation.scoreDifferential < 0 {
            weights[.insideRun]! *= 0.12
            weights[.outsideRun]! *= 0.20
            weights[.deepPass]! *= 1.9
            weights[.shortPass]! *= 1.4
        } else if situation.quarter >= 4 && situation.scoreDifferential > 8 {
            weights[.insideRun]! *= 1.9
            weights[.outsideRun]! *= 1.3
            weights[.deepPass]! *= 0.4
        }

        // Compressed field: no room for deep routes.
        if situation.yardsToGoal <= 10 {
            weights[.deepPass]! *= 0.15
            weights[.insideRun]! *= 1.35
        }

        // A weak coordinator drifts toward a coin flip; a good one plays the percentages.
        let sharpness = max(0.25, min(1.5, coordinatorQuality))
        let shaped = weights.mapValues { pow($0, sharpness * 1.4) }
        return weightedPick(shaped, &rng) ?? .shortPass
    }

    /// Calls that the situation dictates: kneel-downs, kicks, and desperation fourth downs.
    private static func forcedCall(
        situation: GameSituation,
        team: Team,
        rng: inout SeededRandom
    ) -> OffensivePlay? {
        // Kneel out a win.
        if situation.quarter == 4,
           situation.scoreDifferential > 0,
           situation.clockSeconds <= 40,
           situation.defenseTimeouts == 0 {
            return .kneel
        }

        guard situation.down == 4 else { return nil }
        return fourthDownDecision(situation: situation, team: team, rng: &rng)
    }

    /// Go, kick, or punt. A simple expected-value comparison rather than a lookup table, so it
    /// behaves sensibly in situations nobody tabulated.
    public static func fourthDownDecision(
        situation: GameSituation,
        team: Team,
        rng: inout SeededRandom
    ) -> OffensivePlay {
        let trailing = situation.scoreDifferential < 0
        let desperate = situation.quarter == 4 && trailing && situation.clockSeconds <= 300
        let mustScore = desperate && situation.scoreDifferential < -8

        // Conversion odds fall away sharply with distance.
        let conversionChance = max(0.15, 0.72 - Double(situation.distance) * 0.055)
        let fieldGoalChance = situation.isInFieldGoalRange
            ? kickerFieldGoalProbability(team: team, distance: situation.fieldGoalDistance)
            : 0

        // Deep in your own end, punting is nearly always right.
        if situation.yardLine < 45 && !mustScore {
            if situation.distance <= 1 && situation.yardLine >= 40 && conversionChance > 0.6 {
                return runOrPassForShortYardage(team: team, rng: &rng)
            }
            return .punt
        }

        if mustScore && situation.yardsToGoal > 5 { return .deepPass }

        // Value of three points now against the chance of keeping a scoring drive alive.
        let goValue = conversionChance * (situation.isRedZone ? 5.2 : 4.0)
        let kickValue = fieldGoalChance * 3.0
        let puntValue = situation.yardLine >= 60 ? 0.9 : 1.6

        if desperate && goValue > kickValue * 0.75 {
            return situation.distance <= 2
                ? runOrPassForShortYardage(team: team, rng: &rng)
                : .shortPass
        }
        if kickValue >= goValue && kickValue >= puntValue { return .fieldGoal }
        if goValue > puntValue && goValue > kickValue {
            return situation.distance <= 2
                ? runOrPassForShortYardage(team: team, rng: &rng)
                : .shortPass
        }
        return situation.isInFieldGoalRange && fieldGoalChance > 0.5 ? .fieldGoal : .punt
    }

    private static func runOrPassForShortYardage(
        team: Team,
        rng: inout SeededRandom
    ) -> OffensivePlay {
        rng.chance(0.72) ? .insideRun : .playAction
    }

    /// Probability this team's kicker makes a given attempt — used by the AI and by the
    /// fourth-down hint shown to the user.
    public static func kickerFieldGoalProbability(team: Team, distance: Int) -> Double {
        guard distance <= PlayMatrix.maxFieldGoalDistance else { return 0 }
        let base = PlayMatrix.baseFieldGoalProbability(distance: distance)
        guard let kicker = team.starters(at: .k).first else { return base * 0.6 }
        let accuracy = Double(kicker.ratings[.kickAccuracy] - 70) * 0.0035
        let power = Double(kicker.ratings[.kickPower] - 70) * 0.0030
        // Leg strength only matters once the kick is long.
        let powerWeight = distance >= 45 ? 1.0 : 0.25
        return min(0.99, max(0.02, base + accuracy + power * powerWeight))
    }

    /// The defensive call an AI makes against an unknown offensive play.
    public static func defensiveCall(
        situation: GameSituation,
        team: Team,
        coordinatorQuality: Double = 0.8,
        rng: inout SeededRandom
    ) -> DefensivePlay {
        var weights: [DefensivePlay: Double] = [
            .base: 1.00,
            .blitz: 0.42,
            .nickel: 0.85,
            .dime: 0.30,
            .contain: 0.45,
            .prevent: 0.05,
        ]

        switch situation.down {
        case 1:
            weights[.base]! *= 1.5
            weights[.contain]! *= 1.2
            weights[.dime]! *= 0.4
        case 2:
            if situation.distance >= 8 { weights[.nickel]! *= 1.3 }
        case 3:
            if situation.distance <= 2 {
                weights[.base]! *= 1.8
                weights[.contain]! *= 1.5
                weights[.dime]! *= 0.2
            } else if situation.distance >= 8 {
                weights[.nickel]! *= 1.5
                weights[.dime]! *= 2.0
                weights[.blitz]! *= 1.4
                weights[.base]! *= 0.4
            } else {
                weights[.nickel]! *= 1.4
                weights[.blitz]! *= 1.2
            }
        default:
            weights[.base]! *= 1.4
            weights[.contain]! *= 1.3
        }

        switch team.defensiveScheme {
        case .threeFour: weights[.blitz]! *= 1.45
        case .nickelBase: weights[.nickel]! *= 1.55; weights[.base]! *= 0.7
        case .fourThree: weights[.base]! *= 1.2
        }

        // Protecting a lead late: keep everything in front.
        if situation.quarter >= 4, situation.scoreDifferential <= -9, situation.clockSeconds < 240 {
            weights[.prevent]! *= 14
            weights[.blitz]! *= 0.4
        }
        if situation.isRedZone {
            weights[.prevent]! *= 0.05
            weights[.blitz]! *= 1.25
        }

        let sharpness = max(0.25, min(1.5, coordinatorQuality))
        let shaped = weights.mapValues { pow($0, sharpness * 1.4) }
        return weightedPick(shaped, &rng) ?? .base
    }

    /// Tempo the offense should be playing at, given the clock and the scoreboard.
    public static func tempo(situation: GameSituation) -> Tempo {
        if situation.isTwoMinuteDrill && situation.scoreDifferential <= 0 { return .hurryUp }
        if situation.quarter == 4, situation.scoreDifferential > 0, situation.clockSeconds < 300 {
            return .chewClock
        }
        return .normal
    }

    private static func weightedPick<T>(_ weights: [T: Double], _ rng: inout SeededRandom) -> T? {
        let total = weights.values.reduce(0, +)
        guard total > 0 else { return nil }
        // Sort for determinism: dictionary iteration order is not stable across runs.
        let ordered = weights.sorted { String(describing: $0.key) < String(describing: $1.key) }
        var roll = rng.double01() * total
        for (key, weight) in ordered {
            roll -= weight
            if roll <= 0 { return key }
        }
        return ordered.last?.key
    }
}
