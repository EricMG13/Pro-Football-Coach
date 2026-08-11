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
    public let programme: CollegeProgrammeProjection
    public let recruitingBoard: [CareerRecruitingProspectProjection]
    public let mandatoryDecisions: [MandatoryDecision]
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
        guard state.career.college != nil else {
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
        guard let control = state.career.college else {
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
            if case .acceptOpportunity = action {
                throw CareerSessionError.invalidState
            }
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
        state = CareerMandatoryDecisionSystem.refresh(in: resolved.state)
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
        var candidate = state
        switch option.action {
        case let .recruiting(action):
            candidate = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: control.programmeID,
                    prospectID: decision.subject.entityID,
                    action: action
                )),
                in: candidate
            ).state
        case let .redshirt(plannedAppearanceLimit):
            if let plannedAppearanceLimit {
                candidate.college = try CollegeRedshirtSystem.designate(
                    playerID: decision.subject.entityID,
                    programmeID: control.programmeID,
                    plannedAppearanceLimit: plannedAppearanceLimit,
                    in: candidate
                )
            } else if candidate.college.redshirtPlans[decision.subject.entityID] != nil {
                candidate.college = try CollegeRedshirtSystem.clearDesignation(
                    playerID: decision.subject.entityID,
                    programmeID: control.programmeID,
                    in: candidate
                )
            }
        case let .nilAllocation(amount):
            var applied = false
            _ = candidate.college.updateProgramme(control.programmeID) {
                applied = $0.setRosterNILAllocation(
                    amount,
                    playerID: decision.subject.entityID
                )
            }
            guard applied else { throw CareerSessionError.decisionActionFailed }
        case .portalRetention, .portalRelease:
            break
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
            preconditionFailure("A career session lost its controlled programme.")
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
                confidence: observation?.confidence
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
            mandatoryDecisions: state.pending.mandatoryDecisions
        )
    }
}
