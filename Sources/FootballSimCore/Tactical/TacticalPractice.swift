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

    /// The development contribution replaces the old fixed practice point while preserving the
    /// balanced plan's historical value of one. A position focus is intentionally a trade-off.
    public func developmentValue(for player: Player) -> Int {
        let install = installMinutes / 30
        let focus = positionFocusMinutes / 15
        let focusedValue = positionFocus == nil || positionFocus == player.position.group
            ? focus
            : 0
        return min(2, install + focusedValue)
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

public struct TacticalPracticePlanRecord: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let plan: TacticalPracticePlan

    public init(calendar: CalendarState, plan: TacticalPracticePlan) {
        self.calendar = calendar
        self.plan = plan
    }
}

