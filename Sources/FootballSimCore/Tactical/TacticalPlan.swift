import Foundation

public enum TacticalRunPassBias: Int, Codable, Sendable, CaseIterable {
    case runHeavy = -1
    case balanced = 0
    case passHeavy = 1
}

public enum TacticalTempo: Int, Codable, Sendable, CaseIterable {
    case deliberate = -1
    case balanced = 0
    case hurry = 1
}

public enum TacticalPressure: Int, Codable, Sendable, CaseIterable {
    case contain = -1
    case balanced = 0
    case attack = 1
}

public struct TacticalPlan: Codable, Sendable, Equatable {
    public let runPassBias: TacticalRunPassBias
    public let tempo: TacticalTempo
    public let pressure: TacticalPressure

    public init(
        runPassBias: TacticalRunPassBias,
        tempo: TacticalTempo,
        pressure: TacticalPressure
    ) {
        self.runPassBias = runPassBias
        self.tempo = tempo
        self.pressure = pressure
    }

    public static let balanced = TacticalPlan(
        runPassBias: .balanced,
        tempo: .balanced,
        pressure: .balanced
    )

    public func pointAdjustment(against opponent: TacticalPlan) -> Double {
        Double(runPassBias.rawValue) * 0.9
            + Double(tempo.rawValue) * 0.6
            - Double(opponent.pressure.rawValue) * 0.8
    }

    public func scoreDeviationAdjustment() -> Double {
        Double(tempo.rawValue) * 0.8
    }

    public func passingShareAdjustment() -> Int {
        runPassBias.rawValue * 8
    }

    public func playCountAdjustment() -> Double {
        Double(tempo.rawValue) * 5
    }
}

public struct OpponentScoutingSnapshot: Codable, Sendable, Equatable {
    public let teamID: UUID
    public let observedThrough: CalendarState
    public let passRate: Int
    public let turnoverRate: Int

    public init(
        teamID: UUID,
        observedThrough: CalendarState,
        passRate: Int,
        turnoverRate: Int
    ) {
        precondition((0...100).contains(passRate))
        precondition((0...100).contains(turnoverRate))
        self.teamID = teamID
        self.observedThrough = observedThrough
        self.passRate = passRate
        self.turnoverRate = turnoverRate
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPassRate = try container.decode(Int.self, forKey: .passRate)
        let decodedTurnoverRate = try container.decode(Int.self, forKey: .turnoverRate)
        guard (0...100).contains(decodedPassRate),
              (0...100).contains(decodedTurnoverRate) else {
            throw DecodingError.dataCorruptedError(
                forKey: .passRate,
                in: container,
                debugDescription: "Tactical scouting rates must be percentages from zero through one hundred."
            )
        }
        self.init(
            teamID: try container.decode(UUID.self, forKey: .teamID),
            observedThrough: try container.decode(CalendarState.self, forKey: .observedThrough),
            passRate: decodedPassRate,
            turnoverRate: decodedTurnoverRate
        )
    }

    public static func from(
        teamID: UUID,
        observedThrough: CalendarState,
        statistics: TeamSeasonStatistics
    ) -> OpponentScoutingSnapshot {
        let totalYards = statistics.passingYards + statistics.rushingYards
        let passRate = totalYards == 0
            ? 50
            : min(100, max(0, statistics.passingYards * 100 / totalYards))
        let turnoverRate = statistics.games == 0
            ? 0
            : min(100, statistics.turnovers * 100 / max(1, statistics.games * 4))
        return OpponentScoutingSnapshot(
            teamID: teamID,
            observedThrough: observedThrough,
            passRate: passRate,
            turnoverRate: turnoverRate
        )
    }

    public static func from(
        teamID: UUID,
        observedThrough: CalendarState,
        statistics: TeamGameStatistics
    ) -> OpponentScoutingSnapshot {
        let totalYards = statistics.passingYards + statistics.rushingYards
        return OpponentScoutingSnapshot(
            teamID: teamID,
            observedThrough: observedThrough,
            passRate: totalYards == 0 ? 50 : min(100, statistics.passingYards * 100 / totalYards),
            turnoverRate: min(100, statistics.turnovers * 25)
        )
    }
}

public enum TacticalCoordinatorSystem {
    public static func plan(
        for opponent: OpponentScoutingSnapshot?,
        coordinatorRating: Rating
    ) -> TacticalPlan {
        let passRate = opponent?.passRate ?? 50
        let turnoverRate = opponent?.turnoverRate ?? 0
        let pressure: TacticalPressure = passRate >= 60 && coordinatorRating.value >= 55
            ? .attack
            : .balanced
        let runPassBias: TacticalRunPassBias = passRate >= 60 || turnoverRate >= 45
            ? .runHeavy
            : .balanced
        let tempo: TacticalTempo = coordinatorRating.value >= 75 && turnoverRate < 40
            ? .hurry
            : .balanced
        return TacticalPlan(
            runPassBias: runPassBias,
            tempo: tempo,
            pressure: pressure
        )
    }

    /// Uses only evidence that belongs to this observer and remains within the current bounded
    /// window. Missing, future, or stale film deliberately falls back to the same balanced plan as
    /// an unscouted opponent rather than reading the opponent's authoritative hidden totals.
    public static func plan(
        for observation: OpponentObservation?,
        at calendar: CalendarState,
        coordinatorRating: Rating
    ) -> TacticalPlan {
        let snapshot = observation.flatMap { $0.isCurrent(at: calendar) ? $0.snapshot : nil }
        return plan(for: snapshot, coordinatorRating: coordinatorRating)
    }
}

/// Applies a plan to the existing situation-aware caller without changing the drive engine's
/// deterministic seed flow. Balanced plans delegate exactly to the established baseline caller.
public struct TacticalPlayCaller: PlayCaller, Sendable {
    public let plan: TacticalPlan

    public init(plan: TacticalPlan) {
        self.plan = plan
    }

    public func offensiveCall(
        for situation: Situation,
        rules: any ClockRules.Type
    ) -> OffensiveCall {
        let baseline = BaselinePlayCaller().offensiveCall(for: situation, rules: rules)
        guard plan != .balanced,
              !situation.isFourthDown,
              baseline.playType != .fieldGoal,
              baseline.playType != .punt,
              baseline.playType != .kneel else {
            return baseline
        }

        let tempo: Tempo = switch plan.tempo {
        case .deliberate: .bleed
        case .balanced: baseline.tempo
        case .hurry: .hurry
        }
        switch plan.runPassBias {
        case .runHeavy where baseline.playType == .pass && situation.distance <= 8:
            return OffensiveCall(
                playType: .run,
                runGap: RunGap.allCases[situation.yardLine % RunGap.allCases.count],
                tempo: tempo,
                aggression: plan.pressure == .attack ? 0.2 : 0
            )
        case .passHeavy where baseline.playType == .run:
            let depth: PassDepth = situation.distance >= MatchupRules.deepShotDistance ? .deep : .mid
            return OffensiveCall(
                playType: .pass,
                passDepth: depth,
                tempo: tempo,
                aggression: plan.pressure == .attack ? 0.2 : 0
            )
        default:
            return OffensiveCall(
                playType: baseline.playType,
                passDepth: baseline.passDepth,
                runGap: baseline.runGap,
                tempo: tempo,
                aggression: baseline.aggression
            )
        }
    }

    public func defensiveCall(
        for situation: Situation,
        rules: any ClockRules.Type
    ) -> DefensiveCall {
        let baseline = BaselinePlayCaller().defensiveCall(for: situation, rules: rules)
        guard !(situation.isTwoMinute(rules: rules) && situation.scoreDifferential < 0) else {
            return baseline
        }
        switch plan.pressure {
        case .balanced:
            return baseline
        case .contain:
            return DefensiveCall(
                coverage: situation.isThirdAndLong ? .zoneDeep : .zoneUnder,
                rushers: MatchupRules.baseRushers,
                aggression: -0.2
            )
        case .attack:
            return DefensiveCall(
                coverage: baseline.coverage,
                rushers: min(MatchupRules.maximumRushers, baseline.rushers + 1),
                aggression: 0.2
            )
        }
    }
}
