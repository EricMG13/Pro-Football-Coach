import Foundation

/// Who answers a call-in. `02` §3.1, §3.15.
///
/// `TacticalCallInSystem.proposal` built exactly what `02` §3.1 specifies — at most three options,
/// each with its rationale and its risk, plus the coordinator's recommendation — and had **no
/// production caller**. It was reachable only from a unit test. The whole agency model, ~25 calls a
/// game and ~500 a season against the previous build's ~20, existed as a function nobody invoked.
///
/// This is the seam it was missing. The engine produces the call-in, counts it against the game's
/// budget and applies the answer; *who* answers is the caller's business, which is what lets the
/// same loop serve a coordinator that defers, a player at a phone, and a test.
public protocol MatchCallInHandler: Sendable {
    /// Answers one call-in, returning the plan the offence runs from here.
    ///
    /// Returning `proposal.recommendation`'s plan is deferring, and `02` §3.1 is explicit that
    /// deferring is a real choice rather than a non-answer: "a coach who trusts their coordinator is
    /// playing correctly."
    func answer(_ proposal: TacticalCallInProposal, current: TacticalPlan) -> TacticalCallInAction
}

/// The coordinator, answering for a coach who is not watching.
///
/// Takes its own recommendation, which is the same behaviour a handed-off match has and the same
/// behaviour every game in the world that the coach does not control has.
public struct CoordinatorCallInHandler: MatchCallInHandler {
    public init() {}

    public func answer(
        _ proposal: TacticalCallInProposal,
        current: TacticalPlan
    ) -> TacticalCallInAction {
        proposal.recommendation
    }
}

/// One call-in as it happened: what was asked, what was answered, and where.
public struct MatchCallInRecord: Codable, Sendable, Equatable {
    public let driveIndex: Int
    public let trigger: CallInTrigger
    public let situation: Situation
    public let chosen: TacticalCallInAction
    public let recommended: TacticalCallInAction

    public init(driveIndex: Int, trigger: CallInTrigger, situation: Situation,
                chosen: TacticalCallInAction, recommended: TacticalCallInAction) {
        self.driveIndex = driveIndex
        self.trigger = trigger
        self.situation = situation
        self.chosen = chosen
        self.recommended = recommended
    }

    /// Whether the coach went with the coordinator. The aftermath surface reads this, and so does
    /// any judgement about whether trusting the staff is paying.
    public var deferred: Bool { chosen == recommended }
}

/// The call-in loop's state for one game. `02` §3.15.
///
/// A value type carried through the game loop rather than an object it holds, so a replay of the
/// same seed with the same answers is the same game — and so the loop stays a pure function of its
/// inputs, which is `03` §3's determinism contract.
public struct CallInDriver: Sendable {
    /// The offence's plan, which a call-in can change for the rest of the game.
    public private(set) var plan: TacticalPlan
    /// The defence's plan. Read for the unanticipated-tendency trigger and never changed here.
    public let opponentPlan: TacticalPlan
    /// How many call-ins this game may raise. `02` §3.1: ~25, tunable 12 to 40.
    public let budget: Int
    public private(set) var raised: [MatchCallInRecord]
    private let handler: any MatchCallInHandler

    public init(
        plan: TacticalPlan,
        opponentPlan: TacticalPlan,
        budget: Int = SharedRules.defaultCallInsPerGame,
        handler: any MatchCallInHandler = CoordinatorCallInHandler()
    ) {
        self.plan = plan
        self.opponentPlan = opponentPlan
        self.budget = Swift.min(
            Swift.max(budget, SharedRules.callInsPerGameRange.lowerBound),
            SharedRules.callInsPerGameRange.upperBound
        )
        self.handler = handler
        self.raised = []
    }

    /// Raises a call-in for this drive if the situation qualifies and the budget allows, applies the
    /// answer, and returns the plan the drive runs under.
    ///
    /// Called once per drive rather than once per snap, because that is the shape
    /// `TacticalCallInSystem` was built in: every option it offers *is* a `TacticalPlan`, so the
    /// decision it models is what the offence does from here, not which play runs next.
    public mutating func planForDrive(
        index: Int,
        situation: Situation,
        isAfterTurnover: Bool,
        rules: any ClockRules.Type
    ) -> TacticalPlan {
        guard raised.count < budget else { return plan }
        guard let proposal = TacticalCallInSystem.proposal(
            for: situation,
            plan: plan,
            opponentPlan: opponentPlan,
            isAfterTurnover: isAfterTurnover,
            rules: rules
        ) else { return plan }

        let chosen = handler.answer(proposal, current: plan)
        // An answer that names an option nobody offered is treated as a deferral rather than
        // trusted: a handler is allowed to be wrong, and the engine is not allowed to act on a plan
        // that was never on the card.
        let option = proposal.options.first { $0.action == chosen }
            ?? proposal.options.first { $0.action == proposal.recommendation }
        raised.append(MatchCallInRecord(
            driveIndex: index,
            trigger: proposal.trigger,
            situation: situation,
            chosen: option?.action ?? proposal.recommendation,
            recommended: proposal.recommendation
        ))
        if let option { plan = option.plan }
        return plan
    }
}
