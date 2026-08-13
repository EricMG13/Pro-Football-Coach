import Foundation

public enum CareerSessionIntent: Sendable, Equatable {
    case advanceWeek
    case recruiting(prospectID: UUID, action: RecruitingAction)
    case tacticalPlan(TacticalPlan)
    case practicePlan(TacticalPracticePlan)
    case career(CareerArcAction)
    case mandatoryDecision(decisionID: UUID, optionID: UUID)
}

public enum CareerSessionError: Error, Sendable, Equatable {
    case missingControlledCareer
    case responsibilityDelegated
    case missingMandatoryDecision
    case missingDecisionOption
    case decisionActionFailed
    case invalidState
}

public struct CareerRecruitingProspectProjection: Sendable, Equatable, Identifiable {
    public var id: UUID { prospectID }
    public let prospectID: UUID
    public let name: String
    public let position: Position
    public let interest: Int
    public let scholarshipOffered: Bool
    public let visitScheduled: Bool
    public let nilAllocation: Int
    public let estimatedOverall: Int?
    public let estimatedPotential: Int?
    public let confidence: Int?
    /// Half-width of the band around the two estimates, in rating points. `nil` when the programme
    /// has never scouted this prospect and there is no estimate to qualify.
    ///
    /// `02` §4.3 requires the displayed rating to carry a visible confidence band rather than a bare
    /// number pretending to certainty. The engine computed this radius at sample time and then threw
    /// it away; the three bare integers above were all a surface could read.
    public let estimateRadius: Int?

    public var estimatedOverallRange: ClosedRange<Int>? {
        guard let estimatedOverall, let estimateRadius else { return nil }
        return Self.band(around: estimatedOverall, radius: estimateRadius)
    }

    public var estimatedPotentialRange: ClosedRange<Int>? {
        guard let estimatedPotential, let estimateRadius else { return nil }
        return Self.band(around: estimatedPotential, radius: estimateRadius)
    }

    /// Clamped to the rating scale, because a band that runs past 99 advertises a certainty the
    /// scale cannot hold.
    private static func band(around value: Int, radius: Int) -> ClosedRange<Int> {
        let lower = max(SharedRules.ratingRange.lowerBound, value - radius)
        let upper = min(SharedRules.ratingRange.upperBound, value + radius)
        return lower...max(lower, upper)
    }
}

public struct CollegeProgrammeProjection: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let nickname: String
    public let prestige: Int
    public let resources: Int
    public let rosterCount: Int
    public let scholarshipCount: Int
    public let responsibilityOwners: [
        CollegeCareerResponsibility: CareerResponsibilityOwner
    ]
}

public struct CareerProjection: Sendable, Equatable {
    public let calendar: CalendarState
    /// `nil` between jobs. A sacked coach still has a career, and the session that survives the
    /// sacking has to be able to describe it — this used to be non-optional behind a
    /// `preconditionFailure`, which was safe only because nothing could ever take the job away.
    public let programme: CollegeProgrammeProjection?
    public let recruitingBoard: [CareerRecruitingProspectProjection]
    public let mandatoryDecisions: [MandatoryDecision]
    public let employmentStatus: CareerEmploymentStatus
    /// What the coach may accept. `02` §7 guarantees this is non-empty while out of work.
    public let opportunities: [CareerOpportunity]
}

public enum CareerSessionResult: Sendable, Equatable {
    case intent(IntentResult)
    case decisionResolved(decisionID: UUID, optionID: UUID)
}

public struct CareerSessionReceipt: Sendable, Equatable {
    public let projection: CareerProjection
    public let result: CareerSessionResult
}

/// Actor-owned career state. No suspension occurs between validation and commit, so an intent
/// cannot re-enter the session against a partially applied `GameState`.
public actor CareerSession {
    private var state: GameState

    public init(state: GameState) throws {
        // A save whose coach is between jobs still opens: it has a career arc, a market, and a week
        // to advance. Requiring a controlled programme here would make being sacked unloadable.
        guard state.career.college != nil
                || state.careerArc.currentJob != nil
                || !state.careerArc.jobHistory.isEmpty else {
            throw CareerSessionError.missingControlledCareer
        }
        let prepared = CareerMandatoryDecisionSystem.refresh(in: state)
        guard WorldIntegrity.check(prepared).isValid else {
            throw CareerSessionError.invalidState
        }
        self.state = prepared
    }

    public func projection() -> CareerProjection {
        Self.makeProjection(from: state)
    }

    public func saveData() throws -> Data {
        try Task.checkCancellation()
        return try SaveEnvelope.encode(state)
    }

    public func resolve(_ intent: CareerSessionIntent) throws -> CareerSessionReceipt {
        try Task.checkCancellation()
        // Two intents outlive the job. Advancing must stay available or a sacked coach's save is
        // frozen at the week they were sacked, and accepting an offer is the only way back in —
        // between them they are what stops `02` §7's carousel dead-ending.
        let control: CollegeCareerControl
        switch (state.career.college, intent) {
        case let (existing?, _):
            control = existing
        case (nil, .advanceWeek), (nil, .career):
            return try resolveWithoutControl(intent)
        case (nil, _):
            throw CareerSessionError.missingControlledCareer
        }
        let coachIntent: CoachIntent
        switch intent {
        case .advanceWeek:
            coachIntent = .advanceWeek
        case let .recruiting(prospectID, action):
            guard control.responsibilityOwners[.recruiting] == .user else {
                throw CareerSessionError.responsibilityDelegated
            }
            coachIntent = .recruiting(RecruitingActionRequest(
                programmeID: control.programmeID,
                prospectID: prospectID,
                action: action
            ))
        case let .tacticalPlan(plan):
            coachIntent = .tacticalPlan(TacticalPlanRequest(
                organisationID: control.programmeID,
                calendar: state.calendar,
                plan: plan
            ))
        case let .practicePlan(plan):
            coachIntent = .practicePlan(TacticalPracticePlanRequest(
                organisationID: control.programmeID,
                calendar: state.calendar,
                plan: plan
            ))
        case let .career(action):
            // Accepting used to be refused here outright, which meant the promotion `02` §9 sells
            // was unreachable through the only actor the game has. It is reachable now, and the
            // projection tolerates the controlled programme going away as a result.
            coachIntent = .career(CareerArcRequest(
                calendar: state.calendar,
                action: action
            ))
        case let .mandatoryDecision(decisionID, optionID):
            return try resolveDecision(
                decisionID: decisionID,
                optionID: optionID,
                control: control
            )
        }
        let resolved = try IntentResolver.resolve(coachIntent, in: state)
        try Task.checkCancellation()
        // No refresh here any more: obligations are raised inside the weekly transaction, at the
        // scheduler's `newsAndNarrative` step. Raising them again out here would be the second
        // generator, and the one that ran after integrity had already passed.
        state = resolved.state
        return CareerSessionReceipt(
            projection: Self.makeProjection(from: state),
            result: .intent(resolved.result)
        )
    }

    /// The reduced surface available to a coach between jobs.
    private func resolveWithoutControl(
        _ intent: CareerSessionIntent
    ) throws -> CareerSessionReceipt {
        let coachIntent: CoachIntent
        switch intent {
        case .advanceWeek:
            coachIntent = .advanceWeek
        case let .career(action):
            coachIntent = .career(CareerArcRequest(calendar: state.calendar, action: action))
        default:
            throw CareerSessionError.missingControlledCareer
        }
        let resolved = try IntentResolver.resolve(coachIntent, in: state)
        try Task.checkCancellation()
        state = resolved.state
        return CareerSessionReceipt(
            projection: Self.makeProjection(from: state),
            result: .intent(resolved.result)
        )
    }

    private func resolveDecision(
        decisionID: UUID,
        optionID: UUID,
        control: CollegeCareerControl
    ) throws -> CareerSessionReceipt {
        guard let decision = state.pending.mandatoryDecisions.first(where: {
            $0.id == decisionID
        }) else { throw CareerSessionError.missingMandatoryDecision }
        guard decision.owner == .user,
              control.responsibilityOwners[decision.responsibility] == .user else {
            throw CareerSessionError.responsibilityDelegated
        }
        guard let option = decision.options.first(where: { $0.id == optionID }) else {
            throw CareerSessionError.missingDecisionOption
        }
        // The same application the scheduler uses when the deadline elapses and the delegate
        // answers instead. One definition of what an option means, so the two outcomes cannot drift.
        guard let application = CareerMandatoryDecisionSystem.applying(
            option.action,
            subject: decision.subject,
            programmeID: control.programmeID,
            in: state
        ) else { throw CareerSessionError.decisionActionFailed }
        var candidate = application.state
        for payload in application.eventPayloads {
            let event = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: candidate.league.seed,
                    sequence: candidate.history.nextSequence
                ),
                sequence: candidate.history.nextSequence,
                occurredAt: candidate.calendar,
                payload: payload
            )
            guard candidate.history.append(event) else {
                throw CareerSessionError.decisionActionFailed
            }
        }
        guard candidate.pending.removeDecision(id: decisionID) != nil,
              candidate.career.recordResolution(MandatoryDecisionResolution(
                  decisionID: decision.id,
                  programmeID: decision.programmeID,
                  subject: decision.subject,
                  optionID: option.id,
                  action: option.action,
                  decidedAt: candidate.calendar
              )),
              WorldIntegrity.check(candidate).isValid else {
            throw CareerSessionError.decisionActionFailed
        }
        try Task.checkCancellation()
        state = candidate
        return CareerSessionReceipt(
            projection: Self.makeProjection(from: state),
            result: .decisionResolved(decisionID: decisionID, optionID: optionID)
        )
    }

    private static func makeProjection(from state: GameState) -> CareerProjection {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let recruiting = state.college.programmes[control.programmeID] else {
            return CareerProjection(
                calendar: state.calendar,
                programme: nil,
                recruitingBoard: [],
                mandatoryDecisions: state.pending.mandatoryDecisions,
                employmentStatus: state.careerArc.status,
                opportunities: state.careerArc.opportunities
            )
        }
        let board = recruiting.boardIDs.compactMap { prospectID
            -> CareerRecruitingProspectProjection? in
            guard let prospect = state.prospects[prospectID],
                  let relationship = recruiting.relationships[prospectID] else { return nil }
            let observation = state.scouting.observation(
                observerID: control.programmeID,
                prospectID: prospectID
            )
            let estimates = observation.map { observation in
                prospect.position.ratedAttributes.compactMap {
                    observation.estimatedAttributes[$0]?.value
                }
            }
            let estimatedOverall = estimates.flatMap { values in
                values.count == prospect.position.ratedAttributes.count && !values.isEmpty
                    ? values.reduce(0, +) / values.count
                    : nil
            }
            return CareerRecruitingProspectProjection(
                prospectID: prospectID,
                name: prospect.fullName,
                position: prospect.position,
                interest: relationship.interest,
                scholarshipOffered: relationship.scholarshipOffered,
                visitScheduled: relationship.visitScheduled,
                nilAllocation: recruiting.nilState.recruitingReservations[prospectID] ?? 0,
                estimatedOverall: estimatedOverall,
                estimatedPotential: observation?.estimatedPotential.value,
                confidence: observation?.confidence,
                estimateRadius: observation?.errorRadius
            )
        }
        return CareerProjection(
            calendar: state.calendar,
            programme: CollegeProgrammeProjection(
                id: programme.id,
                name: programme.name,
                nickname: programme.nickname,
                prestige: programme.prestige.value,
                resources: programme.resources.value,
                rosterCount: programme.rosterIDs.count,
                scholarshipCount: recruiting.scholarshipPlayerIDs.count,
                responsibilityOwners: control.responsibilityOwners
            ),
            recruitingBoard: board,
            mandatoryDecisions: state.pending.mandatoryDecisions,
            employmentStatus: state.careerArc.status,
            opportunities: state.careerArc.opportunities
        )
    }
}
