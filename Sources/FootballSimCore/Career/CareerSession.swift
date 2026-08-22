import Foundation

public enum CareerSessionIntent: Sendable, Equatable {
    case advanceWeek
    case prepareWeek
    case match(MatchAction)
    case recruiting(prospectID: UUID, action: RecruitingAction)
    case tacticalPlan(TacticalPlan)
    case practicePlan(TacticalPracticePlan)
    case personnelPlan(PersonnelPlan)
    case setResponsibility(
        responsibility: CollegeCareerResponsibility,
        owner: CareerResponsibilityOwner
    )
    case delegateDecision(decisionID: UUID, staffID: UUID)
    case career(CareerArcAction)
    case proManagement(ProManagementAction)
    case proMarket(ProMarketAction)
    case mandatoryDecision(decisionID: UUID, optionID: UUID)
}

public enum CareerSessionError: Error, Sendable, Equatable {
    case missingControlledCareer
    case missingWeeklyPreparation([TacticalPreparationRequirement])
    case responsibilityDelegated
    case missingMandatoryDecision
    case missingDecisionOption
    case decisionActionFailed
    case responsibilityUpdateFailed
    case invalidState
    case matchInProgress
    case matchNotStarted
    case staleMatchCheckpoint
    case matchActionFailed(MatchReducerError)
    /// The career reached `SharedRules.maximumCareerSeasons`. Terminal, and the save stays
    /// readable -- every screen still answers, the week simply cannot advance again.
    case careerComplete
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
    /// `nil` when the coach is jobless but remains a durable career identity.
    public let tier: CareerJobTier?
    /// The currently controlled organisation, or `nil` while seeking work.
    public let programme: CollegeProgrammeProjection?
    public let recruitingBoard: [CareerRecruitingProspectProjection]
    public let mandatoryDecisions: [MandatoryDecision]
}

public enum CareerSessionResult: Sendable, Equatable {
    case intent(IntentResult)
    case preparationCommitted(organisationID: UUID, calendar: CalendarState)
    case responsibilityUpdated(
        responsibility: CollegeCareerResponsibility,
        owner: CareerResponsibilityOwner
    )
    case decisionDelegated(decisionID: UUID, staffID: UUID, optionID: UUID)
    case decisionResolved(decisionID: UUID, optionID: UUID)
    case matchStarted(fixtureID: UUID)
    case matchStep(MatchStepReceipt)
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
        guard state.career.coachID != nil
                || state.career.college != nil
                || state.careerArc.currentJob?.tier == .professional else {
            throw CareerSessionError.missingControlledCareer
        }
        var prepared = CareerMandatoryDecisionSystem.refresh(in: state)
        // The recruiting cycle phase is derived from the week (`02` section 4.1), so recomputing it
        // here costs nothing and carries no information loss. It exists because a root written
        // before signing day was reachable carries `active` in the signing week, and the integrity
        // check below would refuse it — turning an openable save into `invalidState`.
        prepared.college.phase = CollegeRules
            .recruitingCyclePhase(inWeek: prepared.calendar.week)
        guard WorldIntegrity.check(prepared).isValid else {
            throw CareerSessionError.invalidState
        }
        self.state = prepared
    }

    public func projection() -> CareerProjection {
        Self.makeProjection(from: state)
    }

    /// The authoritative root, for the composition layer that builds screen read models from it.
    ///
    /// This is a read-only copy of a value type, so a caller cannot write back through it; the only
    /// way to change the world remains `resolve`. It exists because a truthful read model needs the
    /// whole root and `CareerProjection` is deliberately a narrow slice — and because the engine
    /// cannot build those read models itself without importing the UI, which `03b` §1 forbids.
    public func snapshot() -> GameState { state }

    /// Revalidates the route's fixture and checkpoint inside the actor before applying the action.
    /// The screen-level preflight remains useful for copy, but this is the authority that closes the
    /// await gap between reading a model and committing a control.
    public func resolveMatch(
        fixtureID: UUID,
        revision: UInt64,
        action: MatchAction
    ) throws -> CareerSessionReceipt {
        guard let match = state.matchSession,
              match.fixtureID == fixtureID,
              match.revision == revision else {
            throw CareerSessionError.staleMatchCheckpoint
        }
        return try resolve(.match(action))
    }

    public func saveData() throws -> Data {
        try Task.checkCancellation()
        return try SaveEnvelope.encode(state)
    }

    public func resolve(_ intent: CareerSessionIntent) throws -> CareerSessionReceipt {
        try Task.checkCancellation()
        let control = state.career.college
        guard state.career.coachID != nil
                || control != nil
                || state.careerArc.currentJob?.tier == .professional else {
            throw CareerSessionError.missingControlledCareer
        }
        var resolutionState = state
        let coachIntent: CoachIntent
        switch intent {
        case .prepareWeek:
            guard let organisationID = controlledOrganisationID(in: state),
                  currentUnplayedGame(for: organisationID, in: state) != nil else {
                throw CareerSessionError.missingControlledCareer
            }
            let missing = state.tactical.missingPreparation(
                for: organisationID,
                at: state.calendar
            )
            var candidate = state
            if missing.contains(.gamePlan) {
                guard candidate.tactical.setPlan(
                    .balanced,
                    for: organisationID,
                    at: state.calendar
                ) else { throw CareerSessionError.invalidState }
            }
            if missing.contains(.practicePlan) {
                guard candidate.tactical.setPracticePlan(
                    .balanced,
                    for: organisationID,
                    at: state.calendar
                ) else { throw CareerSessionError.invalidState }
            }
            guard WorldIntegrity.check(candidate).isValid else {
                throw CareerSessionError.invalidState
            }
            state = candidate
            return CareerSessionReceipt(
                projection: Self.makeProjection(from: state),
                result: .preparationCommitted(
                    organisationID: organisationID,
                    calendar: state.calendar
                )
            )
        case .advanceWeek:
            // Translated here rather than left to propagate: `WorldSchedulerError` is not a
            // `CareerSessionError`, so the app's exhaustive refusal switch would never see it and
            // a finished career would read as "that action could not be completed".
            guard state.calendar.season < SharedRules.maximumCareerSeasons else {
                throw CareerSessionError.careerComplete
            }
            guard state.matchSession == nil else { throw CareerSessionError.matchInProgress }
            var prepared = state
            let delegated = shouldDelegateControlledMatch(in: state)
            if let organisationID = controlledOrganisationID(in: state),
               currentUnplayedGame(for: organisationID, in: state) != nil {
                let missing = state.tactical.missingPreparation(
                    for: organisationID,
                    at: state.calendar
                )
                if !missing.isEmpty {
                    guard delegated else {
                        throw CareerSessionError.missingWeeklyPreparation(missing)
                    }
                    if missing.contains(.gamePlan) {
                        _ = prepared.tactical.setPlan(
                            .balanced,
                            for: organisationID,
                            at: state.calendar
                        )
                    }
                    if missing.contains(.practicePlan) {
                        _ = prepared.tactical.setPracticePlan(
                            .balanced,
                            for: organisationID,
                            at: state.calendar
                        )
                    }
                }
            }
            if !delegated {
                prepared = try WorldScheduler.prepareControlledMatch(in: prepared)
            }
            if let match = prepared.matchSession, let fixtureID = match.fixtureID {
                state = prepared
                return CareerSessionReceipt(
                    projection: Self.makeProjection(from: state),
                    result: .matchStarted(fixtureID: fixtureID)
                )
            }
            // Delegated weeks still use the shared resolver; carry its balanced preparation into
            // the resolver input, committing the actor only after that resolver succeeds.
            resolutionState = prepared
            coachIntent = .advanceWeek
        case let .match(action):
            guard var match = state.matchSession else {
                throw CareerSessionError.matchNotStarted
            }
            let step: MatchStepReceipt
            do {
                step = try MatchReducer.reduce(action, state: &match)
            } catch let error as MatchReducerError {
                throw CareerSessionError.matchActionFailed(error)
            }
            var candidate = state
            candidate.matchSession = match
            if match.completed, let completion = match.completion {
                candidate = try WorldScheduler.finalizeControlledMatch(completion, in: candidate)
            }
            state = CareerMandatoryDecisionSystem.refresh(in: candidate)
            return CareerSessionReceipt(
                projection: Self.makeProjection(from: state),
                result: .matchStep(step)
            )
        case let .recruiting(prospectID, action):
            guard let control else { throw CareerSessionError.missingControlledCareer }
            guard control.responsibilityOwners[.recruiting] == .user else {
                throw CareerSessionError.responsibilityDelegated
            }
            coachIntent = .recruiting(RecruitingActionRequest(
                programmeID: control.programmeID,
                prospectID: prospectID,
                action: action
            ))
        case let .tacticalPlan(plan):
            guard let organisationID = control?.programmeID
                    ?? state.careerArc.currentJob?.organisationID else {
                throw CareerSessionError.missingControlledCareer
            }
            coachIntent = .tacticalPlan(TacticalPlanRequest(
                organisationID: organisationID,
                calendar: state.calendar,
                plan: plan
            ))
        case let .practicePlan(plan):
            guard let organisationID = control?.programmeID
                    ?? state.careerArc.currentJob?.organisationID else {
                throw CareerSessionError.missingControlledCareer
            }
            coachIntent = .practicePlan(TacticalPracticePlanRequest(
                organisationID: organisationID,
                calendar: state.calendar,
                plan: plan
            ))
        case let .personnelPlan(plan):
            guard let organisationID = controlledOrganisationID(in: state),
                  plan.organisationID == organisationID,
                  plan.calendar == state.calendar else {
                throw CareerSessionError.missingControlledCareer
            }
            coachIntent = .personnelPlan(PersonnelPlanRequest(plan: plan))
        case let .setResponsibility(responsibility, owner):
            guard !state.pending.mandatoryDecisions.contains(where: {
                $0.responsibility == responsibility
            }) else {
                throw CareerSessionError.responsibilityUpdateFailed
            }
            var candidate = state
            guard CareerControlSystem.setResponsibility(
                responsibility,
                owner: owner,
                in: &candidate
            ) else {
                throw CareerSessionError.responsibilityUpdateFailed
            }
            state = candidate
            return CareerSessionReceipt(
                projection: Self.makeProjection(from: state),
                result: .responsibilityUpdated(
                    responsibility: responsibility,
                    owner: owner
                )
            )
        case let .delegateDecision(decisionID, staffID):
            guard let control,
                  let decision = state.pending.mandatoryDecisions.first(where: {
                      $0.id == decisionID
                          && $0.owner == .user
                          && $0.programmeID == control.programmeID
                  }),
                  control.responsibilityOwners[decision.responsibility] == .user,
                  let programme = state.programmes[control.programmeID],
                  programme.staffIDs.contains(staffID),
                  staffID != control.coachID,
                  state.staff[staffID] != nil else {
                throw CareerSessionError.responsibilityUpdateFailed
            }
            var candidate = state
            guard let option = decision.options.first(where: {
                $0.id == decision.recommendedOptionID
            }) else {
                throw CareerSessionError.missingDecisionOption
            }
            candidate = try applyDecision(
                decision,
                option: option,
                control: control,
                in: candidate
            )
            guard candidate.pending.removeDecision(id: decisionID) != nil,
                  candidate.career.recordResolution(MandatoryDecisionResolution(
                      decisionID: decision.id,
                      programmeID: decision.programmeID,
                      subject: decision.subject,
                      optionID: option.id,
                      action: option.action,
                      decidedAt: candidate.calendar
                  )),
                  CareerControlSystem.setResponsibility(
                      decision.responsibility,
                      owner: .delegated(staffID: staffID),
                      in: &candidate
                  ),
                  WorldIntegrity.check(candidate).isValid else {
                throw CareerSessionError.responsibilityUpdateFailed
            }
            try Task.checkCancellation()
            state = CareerMandatoryDecisionSystem.refresh(in: candidate)
            return CareerSessionReceipt(
                projection: Self.makeProjection(from: state),
                result: .decisionDelegated(
                    decisionID: decisionID,
                    staffID: staffID,
                    optionID: option.id
                )
            )
        case let .career(action):
            coachIntent = .career(CareerArcRequest(
                calendar: state.calendar,
                action: action
            ))
        case let .proManagement(action):
            guard let job = state.careerArc.currentJob, job.tier == .professional else {
                throw CareerSessionError.invalidState
            }
            coachIntent = .proManagement(ProManagementRequest(
                calendar: state.calendar,
                action: action
            ))
        case let .proMarket(action):
            guard let job = state.careerArc.currentJob, job.tier == .professional else {
                throw CareerSessionError.invalidState
            }
            coachIntent = .proMarket(ProMarketRequest(
                calendar: state.calendar,
                action: action
            ))
        case let .mandatoryDecision(decisionID, optionID):
            guard let control else { throw CareerSessionError.missingMandatoryDecision }
            return try resolveDecision(
                decisionID: decisionID,
                optionID: optionID,
                control: control
            )
        }
        let resolved = try IntentResolver.resolve(coachIntent, in: resolutionState)
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
        candidate = try applyDecision(
            decision,
            option: option,
            control: control,
            in: candidate
        )
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

    private func applyDecision(
        _ decision: MandatoryDecision,
        option: MandatoryDecisionOption,
        control: CollegeCareerControl,
        in candidate: GameState
    ) throws -> GameState {
        var candidate = candidate
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
        return candidate
    }

    private func shouldDelegateControlledMatch(in state: GameState) -> Bool {
        guard let control = state.career.college else { return false }
        return CollegeCareerResponsibility.allCases.allSatisfy { responsibility in
            guard case .delegated = control.responsibilityOwners[responsibility] else {
                return false
            }
            return true
        }
    }

    private func controlledOrganisationID(in state: GameState) -> UUID? {
        state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
    }

    private func currentUnplayedGame(for organisationID: UUID, in state: GameState)
        -> ScheduledGame? {
        state.competition.currentSchedule.games.first {
            $0.season == state.calendar.season
                && $0.week == state.calendar.week
                && $0.result == nil
                && ($0.homeID == organisationID || $0.awayID == organisationID)
        }
    }

    private static func makeProjection(from state: GameState) -> CareerProjection {
        let control = state.career.college
        let tier: CareerJobTier?
        let programme: CollegeProgrammeProjection?
        let recruiting: ProgrammeRecruitingState?
        if let control,
           let collegeProgramme = state.programmes[control.programmeID],
           let collegeRecruiting = state.college.programmes[control.programmeID] {
            tier = .college
            programme = CollegeProgrammeProjection(
                id: collegeProgramme.id,
                name: collegeProgramme.name,
                nickname: collegeProgramme.nickname,
                prestige: collegeProgramme.prestige.value,
                resources: collegeProgramme.resources.value,
                rosterCount: collegeProgramme.rosterIDs.count,
                scholarshipCount: collegeRecruiting.scholarshipPlayerIDs.count,
                responsibilityOwners: control.responsibilityOwners
            )
            recruiting = collegeRecruiting
        } else if let job = state.careerArc.currentJob,
                  job.tier == .professional,
                  let team = state.proTeams[job.organisationID] {
            tier = .professional
            programme = CollegeProgrammeProjection(
                id: team.id,
                name: team.displayName,
                nickname: team.nickname,
                prestige: team.prestige.value,
                resources: team.prestige.value,
                rosterCount: team.rosterIDs.count,
                scholarshipCount: team.practiceSquadIDs.count,
                responsibilityOwners: [:]
            )
            recruiting = nil
        } else {
            tier = nil
            programme = nil
            recruiting = nil
        }
        let board = recruiting?.boardIDs.compactMap { prospectID
            -> CareerRecruitingProspectProjection? in
            guard let prospect = state.prospects[prospectID],
                  let relationship = recruiting?.relationships[prospectID] else { return nil }
            guard let control else { return nil }
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
                nilAllocation: recruiting?.nilState.recruitingReservations[prospectID] ?? 0,
                estimatedOverall: estimatedOverall,
                estimatedPotential: observation?.estimatedPotential.value,
                confidence: observation?.confidence
            )
        }
        return CareerProjection(
            calendar: state.calendar,
            tier: tier,
            programme: programme,
            recruitingBoard: board ?? [],
            mandatoryDecisions: state.pending.mandatoryDecisions
        )
    }
}
