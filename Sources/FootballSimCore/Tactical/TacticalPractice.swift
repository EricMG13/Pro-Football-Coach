import Foundation

/// The four weekly practice buckets from the management loop. Minutes are deliberately integer
/// values so a saved plan cannot drift through floating-point arithmetic.
public struct TacticalPracticePlan: Codable, Sendable, Equatable {
    public static let weeklyMinutes = 60

    public let installMinutes: Int
    public let conditioningMinutes: Int
    public let recoveryMinutes: Int
    public let positionFocusMinutes: Int
    public let positionFocus: PositionGroup?

    public init(
        installMinutes: Int,
        conditioningMinutes: Int,
        recoveryMinutes: Int,
        positionFocusMinutes: Int,
        positionFocus: PositionGroup?
    ) {
        precondition(Self.isValid(
            installMinutes: installMinutes,
            conditioningMinutes: conditioningMinutes,
            recoveryMinutes: recoveryMinutes,
            positionFocusMinutes: positionFocusMinutes,
            positionFocus: positionFocus
        ), "A tactical practice plan must spend exactly the weekly practice budget.")
        self.installMinutes = installMinutes
        self.conditioningMinutes = conditioningMinutes
        self.recoveryMinutes = recoveryMinutes
        self.positionFocusMinutes = positionFocusMinutes
        self.positionFocus = positionFocus
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let install = try container.decode(Int.self, forKey: .installMinutes)
        let conditioning = try container.decode(Int.self, forKey: .conditioningMinutes)
        let recovery = try container.decode(Int.self, forKey: .recoveryMinutes)
        let focusMinutes = try container.decode(Int.self, forKey: .positionFocusMinutes)
        let focus = try container.decodeIfPresent(PositionGroup.self, forKey: .positionFocus)
        guard Self.isValid(
            installMinutes: install,
            conditioningMinutes: conditioning,
            recoveryMinutes: recovery,
            positionFocusMinutes: focusMinutes,
            positionFocus: focus
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .installMinutes,
                in: container,
                debugDescription: "Practice minutes must be nonnegative and sum to the weekly budget."
            )
        }
        self.init(
            installMinutes: install,
            conditioningMinutes: conditioning,
            recoveryMinutes: recovery,
            positionFocusMinutes: focusMinutes,
            positionFocus: focus
        )
    }

    public static let balanced = TacticalPracticePlan(
        installMinutes: 15,
        conditioningMinutes: 15,
        recoveryMinutes: 15,
        positionFocusMinutes: 15,
        positionFocus: nil
    )

    /// Rules-owned consequences of one committed weekly plan. Keeping this derived from the
    /// persisted minutes makes every consumer use the same 60-minute budget without adding a
    /// second practice currency or another mutable source of truth.
    public var effects: TacticalPracticeEffects {
        TacticalPracticeEffects(plan: self)
    }

    /// The development contribution replaces the old fixed practice point while preserving the
    /// balanced plan's historical value of one. A position focus is intentionally a trade-off.
    public func developmentValue(for player: Player) -> Int {
        effects.developmentValue(for: player)
    }

    private static func isValid(
        installMinutes: Int,
        conditioningMinutes: Int,
        recoveryMinutes: Int,
        positionFocusMinutes: Int,
        positionFocus: PositionGroup?
    ) -> Bool {
        let values = [installMinutes, conditioningMinutes, recoveryMinutes, positionFocusMinutes]
        return values.allSatisfy { (0...weeklyMinutes).contains($0) }
            && values.reduce(0, +) == weeklyMinutes
            && (positionFocus != nil || positionFocusMinutes == 0 || positionFocusMinutes == 15)
    }
}

/// Bounded, deterministic practice output shared by development, readiness, and match preparation.
/// Conditioning and recovery are intentionally expressed as small integer steps so previews and
/// saved receipts remain byte-stable.
public struct TacticalPracticeEffects: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case developmentValue, conditioningBenefit, recoveryBenefit, positionFocus
    }

    public let developmentValue: Int
    public let conditioningBenefit: Int
    public let recoveryBenefit: Int
    public let positionFocus: PositionGroup?

    public init(plan: TacticalPracticePlan) {
        self.developmentValue = min(
            2,
            plan.installMinutes / 30
                + (plan.positionFocusMinutes / 15)
        )
        self.conditioningBenefit = plan.conditioningMinutes / 15
        self.recoveryBenefit = plan.recoveryMinutes / 15
        self.positionFocus = plan.positionFocus
    }

    public init(
        developmentValue: Int,
        conditioningBenefit: Int,
        recoveryBenefit: Int,
        positionFocus: PositionGroup?
    ) {
        precondition((0...2).contains(developmentValue))
        precondition((0...4).contains(conditioningBenefit))
        precondition((0...4).contains(recoveryBenefit))
        self.developmentValue = developmentValue
        self.conditioningBenefit = conditioningBenefit
        self.recoveryBenefit = recoveryBenefit
        self.positionFocus = positionFocus
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let development = try container.decode(Int.self, forKey: .developmentValue)
        let conditioning = try container.decode(Int.self, forKey: .conditioningBenefit)
        let recovery = try container.decode(Int.self, forKey: .recoveryBenefit)
        guard (0...2).contains(development),
              (0...4).contains(conditioning),
              (0...4).contains(recovery) else {
            throw DecodingError.dataCorruptedError(
                forKey: .developmentValue,
                in: container,
                debugDescription: "Practice effects exceed their bounded ranges."
            )
        }
        self.init(
            developmentValue: development,
            conditioningBenefit: conditioning,
            recoveryBenefit: recovery,
            positionFocus: try container.decodeIfPresent(PositionGroup.self, forKey: .positionFocus)
        )
    }

    public func developmentValue(for player: Player) -> Int {
        guard positionFocus == nil || positionFocus == player.position.group else {
            return developmentValue - (developmentValue > 0 ? 1 : 0)
        }
        return developmentValue
    }
}

public struct TacticalPracticePlanRecord: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let plan: TacticalPracticePlan

    public init(calendar: CalendarState, plan: TacticalPracticePlan) {
        self.calendar = calendar
        self.plan = plan
    }
}
