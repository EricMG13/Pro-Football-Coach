import Foundation

/// The play caller that honours the two teams' game plans. `02` §3.14.
///
/// Without this, wiring the detailed engine into the season would have produced a played match that
/// the coach's own game plan could not touch: `GameEngine` takes a `PlayCaller`, the plan lives in
/// `TacticalState`, and nothing joined them. The abstracted model has read plans since M4 — the
/// played game reading none would have made the week's mandatory game-plan decision worth *less*
/// when the coach watches than when they do not.
///
/// It wraps the baseline caller rather than replacing it. The baseline knows situational football —
/// fourth downs, two-minute, field-goal range — and the plan is a lean applied on top, which is what
/// a game plan is: `02` §3.1 has the coordinator calling plays *inside* the plan.
public struct TacticalPlanCaller: PlayCaller, Sendable {
    /// The plan of whichever side has the ball, and of the side defending it.
    public let offensivePlan: TacticalPlan
    public let defensivePlan: TacticalPlan

    public init(offensivePlan: TacticalPlan, defensivePlan: TacticalPlan) {
        self.offensivePlan = offensivePlan
        self.defensivePlan = defensivePlan
    }

    public func offensiveCall(
        for situation: Situation,
        rules: any ClockRules.Type
    ) -> OffensiveCall {
        var call = BaselinePlayCaller().offensiveCall(for: situation, rules: rules)
        // A kick is a kick. A run-heavy plan does not talk a coach out of a field goal on fourth
        // down, and a plan that could would be overruling situational football rather than leaning
        // it — which is the difference between a game plan and a script.
        guard call.playType == .run || call.playType == .pass else { return call }

        switch offensivePlan.runPassBias {
        case .runHeavy:
            // Lean, not law: the bias flips the call on early downs, where either is defensible,
            // and leaves third-and-long alone because there the situation decides.
            if call.playType == .pass, situation.down <= 2,
               situation.distance <= MatchupRules.runningDownDistance {
                call.playType = .run
            }
        case .passHeavy:
            if call.playType == .run, !situation.isGoalToGo {
                call.playType = .pass
                call.passDepth = situation.distance >= MatchupRules.longYardage ? .mid : .short
            }
        case .balanced:
            break
        }

        switch offensivePlan.tempo {
        case .hurry:
            if call.tempo == .normal { call.tempo = .hurry }
        case .deliberate:
            if call.tempo == .normal { call.tempo = .bleed }
        case .balanced:
            break
        }
        call.aggression = Swift.min(1, Swift.max(-1, call.aggression
            + Double(offensivePlan.runPassBias.rawValue) * MatchupRules.planAggressionStep))
        return call
    }

    public func defensiveCall(
        for situation: Situation,
        rules: any ClockRules.Type
    ) -> DefensiveCall {
        let base = BaselinePlayCaller().defensiveCall(for: situation, rules: rules)
        let extraRushers: Int
        switch defensivePlan.pressure {
        case .attack: extraRushers = 1
        case .contain: extraRushers = -1
        case .balanced: extraRushers = 0
        }
        return DefensiveCall(
            coverage: base.coverage,
            rushers: base.rushers + extraRushers,
            aggression: Swift.min(1, Swift.max(-1, base.aggression
                + Double(defensivePlan.pressure.rawValue) * MatchupRules.planAggressionStep))
        )
    }
}
