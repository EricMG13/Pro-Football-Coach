import Foundation

public enum CoachIntent: Codable, Sendable, Equatable {
    case advanceWeek
    case recruiting(RecruitingActionRequest)
    case tacticalPlan(TacticalPlanRequest)
    case practicePlan(TacticalPracticePlanRequest)
    case personnelPlan(PersonnelPlanRequest)
    case career(CareerArcRequest)
    case proManagement(ProManagementRequest)
    case proMarket(ProMarketRequest)
}

public enum IntentResolutionError: Error, Equatable {
    case unresolvedMandatoryDecisions(count: Int)
    case unresolvedWeeklyPreparation([TacticalPreparationRequirement])
    case recruitingUnavailableDuringPortal
    case tacticalPlanUnavailable
    case personnelPlanUnavailable
    case tacticalCalendarMismatch
    case careerArcUnavailable
    case careerCalendarMismatch
    case professionalManagementUnavailable
    case professionalCalendarMismatch
    case professionalTransactionFailed(ProManagementError)
    case professionalMarketUnavailable
    case professionalMarketCalendarMismatch
    case professionalMarketActionFailed(ProMarketError)
    case eventAppendFailed
    case integrityFailed(issueCount: Int)
}

public struct TacticalPlanRequest: Codable, Sendable, Equatable {
    public let organisationID: UUID
    public let calendar: CalendarState
    public let plan: TacticalPlan

    public init(organisationID: UUID, calendar: CalendarState, plan: TacticalPlan) {
        self.organisationID = organisationID
        self.calendar = calendar
        self.plan = plan
    }
}

public struct TacticalPracticePlanRequest: Codable, Sendable, Equatable {
    public let organisationID: UUID
    public let calendar: CalendarState
    public let plan: TacticalPracticePlan

    public init(organisationID: UUID, calendar: CalendarState, plan: TacticalPracticePlan) {
        self.organisationID = organisationID
        self.calendar = calendar
        self.plan = plan
    }
}

public struct PersonnelPlanRequest: Codable, Sendable, Equatable {
    public let plan: PersonnelPlan

    public init(plan: PersonnelPlan) {
        self.plan = plan
    }
}

public struct CareerArcRequest: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let action: CareerArcAction

    public init(calendar: CalendarState, action: CareerArcAction) {
        self.calendar = calendar
        self.action = action
    }
}

public enum TacticalUpdateKind: String, Codable, Sendable, Equatable {
    case gamePlan
    case practicePlan
    case personnelPlan
}

public struct TacticalIntentResult: Codable, Sendable, Equatable {
    public let organisationID: UUID
    public let calendar: CalendarState
    public let kind: TacticalUpdateKind

    public init(organisationID: UUID, calendar: CalendarState, kind: TacticalUpdateKind) {
        self.organisationID = organisationID
        self.calendar = calendar
        self.kind = kind
    }
}

public struct CareerIntentResult: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let action: CareerArcAction

    public init(calendar: CalendarState, action: CareerArcAction) {
        self.calendar = calendar
        self.action = action
    }
}

public struct ProManagementIntentResult: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let action: ProManagementAction
    public let cap: ProCapSnapshot

    public init(
        calendar: CalendarState,
        action: ProManagementAction,
        cap: ProCapSnapshot
    ) {
        self.calendar = calendar
        self.action = action
        self.cap = cap
    }
}

public struct ProMarketIntentResult: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let action: ProMarketAction
    public let emittedEvents: [DomainEvent]

    public init(
        calendar: CalendarState,
        action: ProMarketAction,
        emittedEvents: [DomainEvent] = []
    ) {
        self.calendar = calendar
        self.action = action
        self.emittedEvents = emittedEvents
    }
}

public struct RecruitingIntentResult: Codable, Sendable, Equatable {
    public let request: RecruitingActionRequest
    public let explanation: RecruitingDecisionExplanation
    public let emittedEvents: [DomainEvent]

    public init(
        request: RecruitingActionRequest,
        explanation: RecruitingDecisionExplanation,
        emittedEvents: [DomainEvent]
    ) {
        self.request = request
        self.explanation = explanation
        self.emittedEvents = emittedEvents
    }
}

public enum IntentResult: Codable, Sendable, Equatable {
    case weekAdvanced(snapshot: WeekSnapshot, emittedEvents: [DomainEvent])
    case recruitingUpdated(RecruitingIntentResult)
    case tacticalUpdated(TacticalIntentResult)
    case careerUpdated(CareerIntentResult)
    case proManagementUpdated(ProManagementIntentResult)
    case proMarketUpdated(ProMarketIntentResult)
}

public struct ResolvedIntent: Codable, Sendable, Equatable {
    public let state: GameState
    public let result: IntentResult

    public init(state: GameState, result: IntentResult) {
        self.state = state
        self.result = result
    }
}

/// The sole mutation boundary exposed to presentation code.
public enum IntentResolver {
    public static func resolve(_ intent: CoachIntent, in state: GameState) throws -> ResolvedIntent {
        switch intent {
        case .advanceWeek:
            guard state.pending.mandatoryDecisions.isEmpty else {
                throw IntentResolutionError.unresolvedMandatoryDecisions(
                    count: state.pending.mandatoryDecisions.count
                )
            }
            if let organisationID = controlledOrganisationID(in: state),
               currentUnplayedGame(for: organisationID, in: state) != nil {
                let missing = state.tactical.missingPreparation(
                    for: organisationID,
                    at: state.calendar
                )
                guard missing.isEmpty else {
                    throw IntentResolutionError.unresolvedWeeklyPreparation(missing)
                }
            }
            let transition = try WorldScheduler.advanceWeek(state)
            return ResolvedIntent(
                state: transition.state,
                result: .weekAdvanced(
                    snapshot: transition.snapshot,
                    emittedEvents: transition.emittedEvents
                )
            )

        case let .recruiting(request):
            guard state.college.portal.phase != .awaitingSpring else {
                throw IntentResolutionError.recruitingUnavailableDuringPortal
            }
            let transition = try CollegeRecruitingSystem.apply(request, in: state)
            var nextState = state
            nextState.prospects = transition.prospects
            nextState.college = transition.college
            nextState.scouting = transition.scouting
            var emittedEvents: [DomainEvent] = []
            for payload in transition.eventPayloads {
                let event = DomainEvent(
                    id: DomainEvent.deterministicID(
                        rootSeed: nextState.league.seed,
                        sequence: nextState.history.nextSequence
                    ),
                    sequence: nextState.history.nextSequence,
                    occurredAt: nextState.calendar,
                    payload: payload
                )
                guard nextState.history.append(event) else {
                    throw IntentResolutionError.eventAppendFailed
                }
                emittedEvents.append(event)
            }
            nextState.college = CollegeCycleSystem.pruningArchivedProspects(in: nextState)
            let integrity = WorldIntegrity.check(nextState)
            guard integrity.isValid else {
                throw IntentResolutionError.integrityFailed(issueCount: integrity.issues.count)
            }
            return ResolvedIntent(
                state: nextState,
                result: .recruitingUpdated(RecruitingIntentResult(
                    request: request,
                    explanation: transition.explanation,
                    emittedEvents: emittedEvents
                ))
            )

        case let .tacticalPlan(request):
            guard request.calendar == state.calendar else {
                throw IntentResolutionError.tacticalCalendarMismatch
            }
            guard state.programmes[request.organisationID] != nil
                    || state.proTeams[request.organisationID] != nil else {
                throw IntentResolutionError.tacticalPlanUnavailable
            }
            var nextState = state
            guard nextState.tactical.setPlan(
                request.plan,
                for: request.organisationID,
                at: request.calendar
            ) else {
                throw IntentResolutionError.tacticalPlanUnavailable
            }
            let integrity = WorldIntegrity.check(nextState)
            guard integrity.isValid else {
                throw IntentResolutionError.integrityFailed(issueCount: integrity.issues.count)
            }
            return ResolvedIntent(
                state: nextState,
                result: .tacticalUpdated(TacticalIntentResult(
                    organisationID: request.organisationID,
                    calendar: request.calendar,
                    kind: .gamePlan
                ))
            )

        case let .practicePlan(request):
            guard request.calendar == state.calendar else {
                throw IntentResolutionError.tacticalCalendarMismatch
            }
            guard state.programmes[request.organisationID] != nil
                    || state.proTeams[request.organisationID] != nil else {
                throw IntentResolutionError.tacticalPlanUnavailable
            }
            var nextState = state
            guard nextState.tactical.setPracticePlan(
                request.plan,
                for: request.organisationID,
                at: request.calendar
            ) else {
                throw IntentResolutionError.tacticalPlanUnavailable
            }
            let integrity = WorldIntegrity.check(nextState)
            guard integrity.isValid else {
                throw IntentResolutionError.integrityFailed(issueCount: integrity.issues.count)
            }
            return ResolvedIntent(
                state: nextState,
                result: .tacticalUpdated(TacticalIntentResult(
                    organisationID: request.organisationID,
                    calendar: request.calendar,
                    kind: .practicePlan
                ))
            )

        case let .personnelPlan(request):
            guard request.plan.calendar == state.calendar else {
                throw IntentResolutionError.tacticalCalendarMismatch
            }
            let organisationID = request.plan.organisationID
            let rosterIDs: [UUID]
            if let programme = state.programmes[organisationID] {
                rosterIDs = programme.rosterIDs
            } else if let team = state.proTeams[organisationID] {
                rosterIDs = team.rosterIDs
            } else {
                throw IntentResolutionError.personnelPlanUnavailable
            }
            let roster = rosterIDs.compactMap { state.players[$0] }
            let rosterByID = Dictionary(uniqueKeysWithValues: roster.map { ($0.id, $0) })
            guard request.plan.overrides.allSatisfy({ override in
                override.playerIDs.allSatisfy { id in
                    guard let player = rosterByID[id] else { return false }
                    return player.position == override.position
                }
            }) else {
                throw IntentResolutionError.personnelPlanUnavailable
            }
            var nextState = state
            guard nextState.tactical.setPersonnelPlan(request.plan) else {
                throw IntentResolutionError.personnelPlanUnavailable
            }
            let integrity = WorldIntegrity.check(nextState)
            guard integrity.isValid else {
                throw IntentResolutionError.integrityFailed(issueCount: integrity.issues.count)
            }
            return ResolvedIntent(
                state: nextState,
                result: .tacticalUpdated(TacticalIntentResult(
                    organisationID: organisationID,
                    calendar: request.plan.calendar,
                    kind: .personnelPlan
                ))
            )

        case let .career(request):
            guard request.calendar == state.calendar else {
                throw IntentResolutionError.careerCalendarMismatch
            }
            let canAcceptWhileSeeking: Bool
            let canAcceptWhileEmployed: Bool
            let canResign: Bool
            switch request.action {
            case .acceptOpportunity:
                canAcceptWhileSeeking = state.careerArc.currentJob == nil
                    && state.careerArc.status == .seeking
                    && state.career.coachID != nil
                canAcceptWhileEmployed = state.career.college != nil
                    && state.careerArc.currentJob?.tier == .college
                    && state.careerArc.status == .employed
                canResign = false
            case .resign:
                canAcceptWhileSeeking = false
                canAcceptWhileEmployed = false
                canResign = state.careerArc.currentJob != nil
            }
            if case .resign = request.action,
               !state.pending.mandatoryDecisions.isEmpty {
                throw IntentResolutionError.careerArcUnavailable
            }
            if case .acceptOpportunity = request.action,
               !state.pending.mandatoryDecisions.isEmpty {
                throw IntentResolutionError.careerArcUnavailable
            }
            guard canAcceptWhileEmployed || canAcceptWhileSeeking || canResign else {
                throw IntentResolutionError.careerArcUnavailable
            }
            var nextState = state
            let applied: Bool
            switch request.action {
            case let .acceptOpportunity(opportunityID):
                applied = nextState.careerArc.acceptOpportunity(
                    id: opportunityID,
                    at: request.calendar
                )
                if applied {
                    nextState.career.clearCollege()
                    if let job = nextState.careerArc.currentJob {
                        CareerControlSystem.seatProfessionalPromotion(
                            teamID: job.organisationID,
                            in: &nextState
                        )
                    }
                }
            case .resign:
                applied = nextState.careerArc.resign(at: request.calendar)
                if applied {
                    // Separation is atomic: a seeking coach must not retain authority over the
                    // former programme while the carousel evaluates the next job, and must not
                    // stay on its staff as its head coach either.
                    nextState.career.clearCollege()
                    CareerControlSystem.vacateCurrentSeat(in: &nextState)
                }
            }
            guard applied else { throw IntentResolutionError.careerArcUnavailable }
            let integrity = WorldIntegrity.check(nextState)
            guard integrity.isValid else {
                throw IntentResolutionError.integrityFailed(issueCount: integrity.issues.count)
            }
            return ResolvedIntent(
                state: nextState,
                result: .careerUpdated(CareerIntentResult(
                    calendar: request.calendar,
                    action: request.action
                ))
            )

        case let .proManagement(request):
            guard request.calendar == state.calendar else {
                throw IntentResolutionError.professionalCalendarMismatch
            }
            guard state.career.college == nil,
                  let job = state.careerArc.currentJob,
                  job.tier == .professional else {
                throw IntentResolutionError.professionalManagementUnavailable
            }
            let nextState: GameState
            let cap: ProCapSnapshot
            do {
                switch request.action {
                case let .acquire(playerID, teamID, kind, contract):
                    guard teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    let receipt = try ProManagementSystem.acquire(
                        playerID: playerID,
                        for: teamID,
                        kind: kind,
                        contract: contract,
                        in: state
                    )
                    nextState = receipt.state
                    cap = receipt.capAfter
                case let .release(playerID, teamID):
                    guard teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    let receipt = try ProManagementSystem.release(
                        playerID: playerID,
                        from: teamID,
                        in: state
                    )
                    nextState = receipt.state
                    cap = receipt.capAfter
                case let .beginNegotiation(playerID, teamID, offer, deadline):
                    guard teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    let receipt = try ProManagementSystem.beginNegotiation(
                        playerID: playerID,
                        teamID: teamID,
                        offer: offer,
                        deadline: deadline,
                        in: state
                    )
                    nextState = receipt.state
                    cap = receipt.capAfter
                case let .counterNegotiation(negotiationID, offer):
                    let receipt = try ProManagementSystem.counterNegotiation(
                        negotiationID: negotiationID,
                        offer: offer,
                        in: state
                    )
                    guard receipt.negotiation.teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    nextState = receipt.state
                    cap = receipt.capAfter
                case let .acceptNegotiation(negotiationID):
                    let receipt = try ProManagementSystem.settleNegotiation(
                        negotiationID: negotiationID,
                        as: .accepted,
                        in: state
                    )
                    guard receipt.negotiation.teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    nextState = receipt.state
                    cap = receipt.capAfter
                case let .rejectNegotiation(negotiationID):
                    let receipt = try ProManagementSystem.settleNegotiation(
                        negotiationID: negotiationID,
                        as: .rejected,
                        in: state
                    )
                    guard receipt.negotiation.teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    nextState = receipt.state
                    cap = receipt.capAfter
                case let .withdrawNegotiation(negotiationID):
                    let receipt = try ProManagementSystem.settleNegotiation(
                        negotiationID: negotiationID,
                        as: .withdrawn,
                        in: state
                    )
                    guard receipt.negotiation.teamID == job.organisationID else {
                        throw ProManagementError.missingTeam
                    }
                    nextState = receipt.state
                    cap = receipt.capAfter
                }
            } catch let error as ProManagementError {
                throw IntentResolutionError.professionalTransactionFailed(error)
            }
            return ResolvedIntent(
                state: nextState,
                result: .proManagementUpdated(ProManagementIntentResult(
                    calendar: request.calendar,
                    action: request.action,
                    cap: cap
                ))
            )

        case let .proMarket(request):
            guard request.calendar == state.calendar else {
                throw IntentResolutionError.professionalMarketCalendarMismatch
            }
            guard state.career.college == nil,
                  let job = state.careerArc.currentJob,
                  job.tier == .professional else {
                throw IntentResolutionError.professionalMarketUnavailable
            }
            var nextState: GameState
            do {
                switch request.action {
                case .openOffseason:
                    nextState = try ProMarketSystem.openOffseason(in: state)
                case let .scout(teamID, prospectID):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.recordScouting(
                        teamID: teamID,
                        prospectID: prospectID,
                        in: state
                    )
                case .beginDraft:
                    nextState = try ProMarketSystem.beginDraft(in: state)
                case let .signFreeAgent(playerID, teamID, contract):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.signFreeAgent(
                        playerID: playerID,
                        teamID: teamID,
                        contract: contract,
                        in: state
                    )
                case let .draft(prospectID, teamID, contract):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.draft(
                        prospectID: prospectID,
                        for: teamID,
                        contract: contract,
                        in: state
                    )
                case let .moveToPracticeSquad(playerID, teamID):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.moveToPracticeSquad(
                        playerID: playerID,
                        teamID: teamID,
                        in: state
                    )
                case let .promoteFromPracticeSquad(playerID, teamID):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.promoteFromPracticeSquad(
                        playerID: playerID,
                        teamID: teamID,
                        in: state
                    )
                case let .trade(sourcePlayerID, sourceTeamID, destinationPlayerID, destinationTeamID):
                    guard sourceTeamID == job.organisationID || destinationTeamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.trade(
                        sourcePlayerID: sourcePlayerID,
                        sourceTeamID: sourceTeamID,
                        destinationPlayerID: destinationPlayerID,
                        destinationTeamID: destinationTeamID,
                        in: state
                    )
                case let .placeOnWaivers(playerID, teamID):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.placeOnWaivers(
                        playerID: playerID,
                        teamID: teamID,
                        at: request.calendar,
                        in: state
                    )
                case let .claimWaiver(playerID, teamID):
                    guard teamID == job.organisationID else {
                        throw ProMarketError.missingTeam
                    }
                    nextState = try ProMarketSystem.claimWaiver(
                        playerID: playerID,
                        teamID: teamID,
                        at: request.calendar,
                        in: state
                    )
                case .resolveExpiredWaivers:
                    nextState = try ProMarketSystem.resolveExpiredWaivers(
                        at: request.calendar,
                        in: state
                    )
                case .close:
                    nextState = try ProMarketSystem.close(in: state)
                }
            } catch let error as ProMarketError {
                throw IntentResolutionError.professionalMarketActionFailed(error)
            }
            let payloads: [DomainEventPayload]
            switch request.action {
            case .openOffseason:
                payloads = [.proMarketOpened(
                    season: nextState.proMarket.season,
                    draftClassCount: nextState.proMarket.draftClass.count,
                    freeAgentCount: nextState.proMarket.freeAgentIDs.count
                )]
            case let .scout(teamID, prospectID):
                let confidence = nextState.proMarket.observations.first {
                    $0.teamID == teamID && $0.prospectID == prospectID
                }?.confidence ?? 0
                payloads = [.proDraftScouted(
                    teamID: teamID,
                    prospectID: prospectID,
                    confidence: confidence
                )]
            case let .signFreeAgent(playerID, teamID, _):
                guard let committedContract = nextState.players[playerID]?.contract else {
                    throw IntentResolutionError.eventAppendFailed
                }
                payloads = [.proPlayerSigned(
                    playerID: playerID,
                    teamID: teamID,
                    kind: .freeAgency,
                    contract: committedContract
                )]
            case let .draft(prospectID, teamID, contract):
                let draftContract = nextState.proMarket.draftClass
                    .first(where: { $0.id == prospectID })
                    .map { ProMarketSystem.rookieContract(for: $0.player) }
                guard (contract
                        ?? nextState.players[prospectID]?.contract
                        ?? draftContract) != nil else {
                    throw IntentResolutionError.eventAppendFailed
                }
                guard let committedContract = nextState.players[prospectID]?.contract else {
                    throw IntentResolutionError.eventAppendFailed
                }
                payloads = [.proDraftPick(
                    prospectID: prospectID,
                    teamID: teamID,
                    pick: state.proMarket.nextPick,
                    contract: committedContract
                )]
            case .beginDraft:
                payloads = [.proDraftStarted(season: nextState.proMarket.season)]
            case let .moveToPracticeSquad(playerID, teamID):
                payloads = [.proPracticeSquadMoved(playerID: playerID, teamID: teamID, promoted: false)]
            case let .promoteFromPracticeSquad(playerID, teamID):
                payloads = [.proPracticeSquadMoved(playerID: playerID, teamID: teamID, promoted: true)]
            case let .trade(sourcePlayerID, sourceTeamID, destinationPlayerID, destinationTeamID):
                payloads = [.proTradeCompleted(
                    sourcePlayerID: sourcePlayerID,
                    sourceTeamID: sourceTeamID,
                    destinationPlayerID: destinationPlayerID,
                    destinationTeamID: destinationTeamID
                )]
            case let .placeOnWaivers(playerID, teamID):
                guard let entry = nextState.proMarket.waivers.first(where: { $0.playerID == playerID }) else {
                    throw IntentResolutionError.eventAppendFailed
                }
                payloads = [.proWaiverPlaced(
                    playerID: playerID,
                    teamID: teamID,
                    claimDeadline: entry.claimDeadline
                )]
            case let .claimWaiver(playerID, teamID):
                guard let sourceTeamID = state.proMarket.waivers.first(where: { $0.playerID == playerID })?.sourceTeamID else {
                    throw IntentResolutionError.eventAppendFailed
                }
                payloads = [.proWaiverClaimed(
                    playerID: playerID,
                    sourceTeamID: sourceTeamID,
                    destinationTeamID: teamID
                )]
            case .resolveExpiredWaivers:
                let count = state.proMarket.waivers.filter {
                    $0.claimDeadline.season < request.calendar.season
                        || ($0.claimDeadline.season == request.calendar.season
                            && $0.claimDeadline.week < request.calendar.week)
                }.count
                payloads = [.proWaiversResolved(count: count)]
            case .close:
                payloads = [.proMarketClosed(season: state.proMarket.season)]
            }
            var emittedEvents: [DomainEvent] = []
            for payload in payloads {
                let event = DomainEvent(
                    id: DomainEvent.deterministicID(
                        rootSeed: nextState.league.seed,
                        sequence: nextState.history.nextSequence
                    ),
                    sequence: nextState.history.nextSequence,
                    occurredAt: request.calendar,
                    payload: payload
                )
                guard nextState.history.append(event) else {
                    throw IntentResolutionError.eventAppendFailed
                }
                emittedEvents.append(event)
            }
            let integrity = WorldIntegrity.check(nextState)
            guard integrity.isValid else {
                throw IntentResolutionError.integrityFailed(issueCount: integrity.issues.count)
            }
            return ResolvedIntent(
                state: nextState,
                result: .proMarketUpdated(ProMarketIntentResult(
                    calendar: request.calendar,
                    action: request.action,
                    emittedEvents: emittedEvents
                ))
            )
        }
    }

    private static func controlledOrganisationID(in state: GameState) -> UUID? {
        state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
    }

    private static func currentUnplayedGame(for organisationID: UUID, in state: GameState)
        -> ScheduledGame? {
        state.competition.currentSchedule.games.first {
            $0.season == state.calendar.season
                && $0.week == state.calendar.week
                && $0.result == nil
                && ($0.homeID == organisationID || $0.awayID == organisationID)
        }
    }
}
