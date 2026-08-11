import Foundation

public enum TacticalCallInAction: String, Codable, Sendable, CaseIterable {
    case trustCoordinator
    case attack
    case protect
}

public struct TacticalCallInOption: Codable, Sendable, Equatable {
    public let action: TacticalCallInAction
    public let title: String
    public let rationale: String
    public let risk: String
    public let plan: TacticalPlan

    public init(
        action: TacticalCallInAction,
        title: String,
        rationale: String,
        risk: String,
        plan: TacticalPlan
    ) {
        precondition(!title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        precondition(!rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        precondition(!risk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        self.action = action
        self.title = title
        self.rationale = rationale
        self.risk = risk
        self.plan = plan
    }
}

public struct TacticalCallInProposal: Codable, Sendable, Equatable {
    public let trigger: CallInTrigger
    public let situation: Situation
    public let options: [TacticalCallInOption]
    public let recommendation: TacticalCallInAction

    public init(
        trigger: CallInTrigger,
        situation: Situation,
        options: [TacticalCallInOption],
        recommendation: TacticalCallInAction
    ) {
        precondition((1...3).contains(options.count))
        precondition(Set(options.map(\.action)).count == options.count)
        precondition(options.contains { $0.action == recommendation })
        self.trigger = trigger
        self.situation = situation
        self.options = options
        self.recommendation = recommendation
    }
}

public enum TacticalCallInSystem {
    /// Builds the small, inspectable decision shown at a flagged snap. It is pure: no hidden
    /// opponent attributes, random draws, or mutation are consulted.
    public static func proposal(
        for situation: Situation,
        plan: TacticalPlan,
        opponentPlan: TacticalPlan? = nil,
        isAfterTurnover: Bool = false,
        rules: any ClockRules.Type
    ) -> TacticalCallInProposal? {
        var triggers = situation.situationalCallInTriggers(
            rules: rules,
            isSnapAfterTurnover: isAfterTurnover
        )
        if let opponentPlan, opponentPlan.runPassBias != plan.runPassBias {
            triggers.append(.unanticipatedTendency)
        }
        if plan == .balanced {
            triggers.append(.planLeavesItOpen)
        }
        guard let trigger = triggers.first else { return nil }

        let attack = TacticalCallInOption(
            action: .attack,
            title: "Attack the moment",
            rationale: "Put pressure on the tendency before it can settle.",
            risk: "A failed snap gives the opponent a shorter field.",
            plan: TacticalPlan(runPassBias: .passHeavy, tempo: .hurry, pressure: .attack)
        )
        let protect = TacticalCallInOption(
            action: .protect,
            title: "Protect the margin",
            rationale: "Reduce variance and make the opponent earn the next decision.",
            risk: "A conservative call may surrender the initiative.",
            plan: TacticalPlan(runPassBias: .runHeavy, tempo: .deliberate, pressure: .contain)
        )
        let trust = TacticalCallInOption(
            action: .trustCoordinator,
            title: "Trust the coordinator",
            rationale: "Keep the installed plan and let the staff own the snap.",
            risk: "The current plan may leave this situation uncovered.",
            plan: plan
        )
        let recommendation: TacticalCallInAction = situation.scoreDifferential < 0
            ? .attack
            : (situation.isTwoMinute(rules: rules) ? .protect : .trustCoordinator)
        return TacticalCallInProposal(
            trigger: trigger,
            situation: situation,
            options: [trust, attack, protect],
            recommendation: recommendation
        )
    }
}

