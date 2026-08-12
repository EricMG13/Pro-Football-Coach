import Foundation

public enum WorldStep: String, Codable, Sendable, CaseIterable, Hashable {
    case expiringInboundEvents
    case injuriesAndRecovery
    case practiceAndDevelopment
    case scoutingKnowledge
    case marketInteractions
    case aiDecisions
    case nonUserGames
    case userGame
    case standingsAndRankings
    case statisticsAndRecords
    case relationshipsAndStakeholders
    case newsAndNarrative
    case jobAndStaffMarkets
    case saveGrowthAndIntegrity
    case weekSnapshot
}

public enum WorldStepStatus: String, Codable, Sendable, Equatable {
    case executed
    case inactive
}

public struct WorldStepRecord: Codable, Sendable, Equatable {
    public let step: WorldStep
    public let status: WorldStepStatus

    public init(step: WorldStep, status: WorldStepStatus) {
        self.step = step
        self.status = status
    }
}

public struct WeekSnapshot: Codable, Sendable, Equatable {
    public let completed: CalendarState
    public let next: CalendarState
    public let emittedEventIDs: [UUID]

    public init(completed: CalendarState, next: CalendarState, emittedEventIDs: [UUID]) {
        self.completed = completed
        self.next = next
        self.emittedEventIDs = emittedEventIDs
    }
}

public struct WorldTransition: Codable, Sendable, Equatable {
    public let state: GameState
    public let snapshot: WeekSnapshot
    public let stepRecords: [WorldStepRecord]
    public let emittedEvents: [DomainEvent]

    public init(
        state: GameState,
        snapshot: WeekSnapshot,
        stepRecords: [WorldStepRecord],
        emittedEvents: [DomainEvent]
    ) {
        self.state = state
        self.snapshot = snapshot
        self.stepRecords = stepRecords
        self.emittedEvents = emittedEvents
    }
}

public enum WorldSchedulerError: Error, Equatable {
    case integrityFailed([IntegrityIssue])
    case scheduledGameMissing(UUID)
    case scheduledGameResultMissing(UUID)
    case scheduleResultRecordingFailed(ScheduleResultRecordingError)
    case eventAppendFailed
    case aiRecruitingActionFailed(RecruitingActionError)
    case collegeCycleFailed
    case portalMarketFailed(CollegePortalWindow)
    case portalCommitFailed(CollegePortalWindow)
    case professionalMarketFailed(ProMarketError)
}

/// The versioned, fixed-order weekly transaction. Unbuilt systems remain explicit inactive steps,
/// so adding a subsystem is an auditable activation rather than an invisible ordering change.
public enum WorldScheduler {
    public static let version = 1
    public static let steps: [WorldStep] = WorldStep.allCases

    public static func advanceWeek(_ state: GameState) throws -> WorldTransition {
        var nextState = state
        let completed = state.calendar
        let next = completed.advancedWeek()
        var records: [WorldStepRecord] = []
        var events: [DomainEvent] = []

        for step in steps {
            switch step {
            case .marketInteractions:
                let expiredWaivers = nextState.proMarket.waivers.filter {
                    $0.claimDeadline.season < completed.season
                        || ($0.claimDeadline.season == completed.season
                            && $0.claimDeadline.week < completed.week)
                }
                if !expiredWaivers.isEmpty {
                    do {
                        nextState = try ProMarketSystem.resolveExpiredWaivers(
                            at: completed,
                            in: nextState
                        )
                    } catch let error as ProMarketError {
                        throw WorldSchedulerError.professionalMarketFailed(error)
                    }
                    try appendEvents(
                        payloads: [.proWaiversResolved(count: expiredWaivers.count)],
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                }
                if nextState.college.portal.phase == .awaitingSpring {
                    try resolveAndCommitPortal(
                        window: .spring,
                        state: &nextState,
                        emittedEvents: &events
                    )
                    let walkOns = CollegeCycleSystem.addWalkOns(
                        for: .springRosterFill,
                        season: completed.season,
                        in: nextState
                    )
                    nextState.programmes = walkOns.programmes
                    nextState.players = walkOns.players
                    nextState.people = walkOns.people
                    try appendEvents(
                        payloads: walkOns.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                }
                let transition = CollegeRecruitingMarketSystem.process(
                    at: completed,
                    in: nextState
                )
                nextState.college = transition.college
                try appendEvents(
                    payloads: transition.eventPayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                records.append(WorldStepRecord(step: step, status: .executed))

            case .aiDecisions:
                let transition: CollegeRecruitingAITransition
                do {
                    transition = try CollegeRecruitingAISystem.process(in: nextState)
                } catch let error as CollegeRecruitingAIError {
                    switch error {
                    case let .rejectedLegalDecision(actionError):
                        throw WorldSchedulerError.aiRecruitingActionFailed(actionError)
                    }
                }
                nextState.college = transition.college
                nextState.scouting = transition.scouting
                try appendEvents(
                    payloads: transition.eventPayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                let delegated: CollegeRecruitingAITransition
                do {
                    delegated = try CollegeCareerDelegationSystem.processRecruiting(in: nextState)
                } catch let error as CollegeRecruitingAIError {
                    switch error {
                    case let .rejectedLegalDecision(actionError):
                        throw WorldSchedulerError.aiRecruitingActionFailed(actionError)
                    }
                }
                nextState.college = delegated.college
                nextState.scouting = delegated.scouting
                try appendEvents(
                    payloads: delegated.eventPayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                do {
                    let professional = try ProRosterAISystem.process(
                        at: completed,
                        in: nextState
                    )
                    nextState = professional.state
                    try appendEvents(
                        payloads: professional.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                } catch let error as ProMarketError {
                    throw WorldSchedulerError.professionalMarketFailed(error)
                }
                records.append(WorldStepRecord(step: step, status: .executed))

            case .injuriesAndRecovery:
                let transition = PeopleLifecycleSystem.processHealth(at: completed, in: nextState)
                nextState.people = transition.people
                try appendEvents(
                    payloads: transition.eventPayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                records.append(WorldStepRecord(step: step, status: .executed))

            case .practiceAndDevelopment:
                let transition = DevelopmentSystem.practice(
                    at: completed,
                    in: nextState,
                    tactical: nextState.tactical
                )
                nextState.players = transition.players
                nextState.people = transition.people
                try appendEvents(
                    payloads: transition.eventPayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                records.append(WorldStepRecord(step: step, status: .executed))

            case .scoutingKnowledge:
                if nextState.college.portal.phase == .awaitingSpring {
                    records.append(WorldStepRecord(step: step, status: .inactive))
                } else {
                    let transition = ScoutingSystem.process(at: completed, in: nextState)
                    nextState.scouting = transition.scouting
                    try appendEvents(
                        payloads: transition.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                    records.append(WorldStepRecord(step: step, status: .executed))
                }

            case .nonUserGames:
                nextState.tactical.prepare(for: completed)
                let dueGames = nextState.competition.currentSchedule.games.filter {
                    $0.season == completed.season
                        && $0.week == completed.week
                        && $0.result == nil
                }
                var tacticalPlans: [UUID: TacticalPlan] = [:]
                tacticalPlans.reserveCapacity(dueGames.count * 2)
                for game in dueGames {
                    tacticalPlans[game.homeID] = TacticalPlanSystem.plan(
                        for: game.homeID,
                        against: game.awayID,
                        at: completed,
                        in: nextState,
                        tactical: &nextState.tactical
                    )
                    tacticalPlans[game.awayID] = TacticalPlanSystem.plan(
                        for: game.awayID,
                        against: game.homeID,
                        at: completed,
                        in: nextState,
                        tactical: &nextState.tactical
                    )
                }
                let resultRecords = dueGames.map { game in
                    ScheduledGameResult(
                        gameID: game.id,
                        summary: AbstractGameSimulator.play(
                            game,
                            in: nextState,
                            tacticalPlans: tacticalPlans
                        )
                    )
                }
                let completedGames: [ScheduledGame]
                do {
                    completedGames = try nextState.competition.currentSchedule.recordResults(
                        resultRecords
                    )
                } catch let error as ScheduleResultRecordingError {
                    if case let .unknownGameID(gameID) = error {
                        throw WorldSchedulerError.scheduledGameMissing(gameID)
                    }
                    throw WorldSchedulerError.scheduleResultRecordingFailed(error)
                }
                var gamePayloads: [DomainEventPayload] = []
                gamePayloads.reserveCapacity(completedGames.count)
                for game in completedGames {
                    guard let result = game.result else {
                        throw WorldSchedulerError.scheduledGameResultMissing(game.id)
                    }
                    gamePayloads.append(.gameCompleted(
                        gameID: game.id,
                        homeID: game.homeID,
                        awayID: game.awayID,
                        stage: game.stage,
                        homeScore: result.homeScore,
                        awayScore: result.awayScore
                    ))
                    TacticalPlanSystem.recordReviews(
                        for: game,
                        result: result,
                        at: completed,
                        in: &nextState.tactical
                    )
                }
                try appendEvents(
                    payloads: gamePayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                records.append(WorldStepRecord(step: step, status: .executed))

            case .standingsAndRankings:
                nextState.competition = CompetitionReducer.rebuildStandings(from: nextState)
                let postseason = PostseasonSystem.advance(after: completed, in: nextState)
                nextState.competition = postseason.competition
                try appendEvents(
                    payloads: postseason.eventPayloads,
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                records.append(WorldStepRecord(step: step, status: .executed))

            case .statisticsAndRecords:
                nextState.competition = CompetitionReducer.rebuildStatistics(from: nextState)
                CareerArcSystem.evaluateWeek(
                    after: completed,
                    in: nextState,
                    arc: &nextState.careerArc
                )
                records.append(WorldStepRecord(step: step, status: .executed))

            case .relationshipsAndStakeholders:
                let rivalries = RivalrySystem.process(after: completed, in: nextState)
                nextState.rivalries = rivalries.rivalries
                records.append(WorldStepRecord(step: step, status: .executed))

            case .jobAndStaffMarkets:
                if completed.week == SharedRules.inSeasonWeeks {
                    let expiredWaivers = nextState.proMarket.waivers.filter {
                        $0.claimDeadline.season < completed.season
                            || ($0.claimDeadline.season == completed.season
                                && $0.claimDeadline.week < completed.week)
                    }
                    if !expiredWaivers.isEmpty {
                        do {
                            nextState = try ProMarketSystem.resolveExpiredWaivers(
                                at: completed,
                                in: nextState
                            )
                        } catch let error as ProMarketError {
                            throw WorldSchedulerError.professionalMarketFailed(error)
                        }
                        try appendEvents(
                            payloads: [.proWaiversResolved(count: expiredWaivers.count)],
                            occurredAt: completed,
                            to: &nextState,
                            emittedEvents: &events
                        )
                    }
                    do {
                        let expiry = try ProMarketSystem.expireContracts(
                            at: completed,
                            in: nextState
                        )
                        nextState = expiry.state
                        try appendEvents(
                            payloads: expiry.expiredPlayerIDs.map {
                                .proContractExpired(playerID: $0)
                            },
                            occurredAt: completed,
                            to: &nextState,
                            emittedEvents: &events
                        )
                    } catch let error as ProMarketError {
                        throw WorldSchedulerError.professionalMarketFailed(error)
                    }
                    if nextState.proMarket.phase != .closed {
                        let closedSeason = nextState.proMarket.season
                        do {
                            nextState = try ProMarketSystem.close(in: nextState)
                        } catch let error as ProMarketError {
                            throw WorldSchedulerError.professionalMarketFailed(error)
                        } catch {
                            throw WorldSchedulerError.professionalMarketFailed(.invalidRoot)
                        }
                        try appendEvents(
                            payloads: [.proMarketClosed(season: closedSeason)],
                            occurredAt: completed,
                            to: &nextState,
                            emittedEvents: &events
                        )
                    }
                    // Resolve work performed after the ordinary pre-AI market before signing.
                    // Appending immediately keeps commitment history causally ahead of the
                    // resolution and join events emitted by the college cycle below.
                    let terminalMarket = CollegeRecruitingMarketSystem.process(
                        at: completed,
                        in: nextState
                    )
                    nextState.college = terminalMarket.college
                    try appendEvents(
                        payloads: terminalMarket.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                }
                let peopleTransition = try SeasonLifecycleSystem.advance(
                    after: completed,
                    in: nextState
                )
                if completed.week == SharedRules.inSeasonWeeks {
                    CareerArcSystem.evaluateSeasonEnd(
                        after: completed,
                        in: nextState,
                        arc: &nextState.careerArc
                    )
                    let completion = PostseasonSystem.completeSeason(
                        after: completed,
                        in: nextState
                    )
                    nextState.competition = completion.competition
                    // Season completion was historically observable before lifecycle/cycle
                    // construction. Preserve that boundary as the one exceptional second batch
                    // in this step; final event order and global sequences remain unchanged.
                    try appendEvents(
                        payloads: completion.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                }
                nextState.programmes = peopleTransition.programmes
                nextState.proTeams = peopleTransition.proTeams
                nextState.players = peopleTransition.players
                nextState.staff = peopleTransition.staff
                nextState.people = peopleTransition.people
                if completed.week == SharedRules.inSeasonWeeks {
                    nextState.college.reconcileScholarships(with: nextState.programmes)
                    let cycle: CollegeCycleTransition
                    do {
                        cycle = try CollegeCycleSystem.closeAndOpen(
                            nextSeason: completed.season + 1,
                            in: nextState
                        )
                    } catch {
                        throw WorldSchedulerError.collegeCycleFailed
                    }
                    nextState.programmes = cycle.programmes
                    nextState.players = cycle.players
                    nextState.people = cycle.people
                    nextState.prospects = cycle.prospects
                    nextState.college = cycle.college
                    nextState.scouting = cycle.scouting
                    try appendEvents(
                        payloads: peopleTransition.eventPayloads + cycle.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                    try resolveAndCommitPortal(
                        window: .postseason,
                        state: &nextState,
                        emittedEvents: &events
                    )
                    let walkOns = CollegeCycleSystem.addWalkOns(
                        for: .postseasonCoverage,
                        season: completed.season + 1,
                        in: nextState
                    )
                    nextState.programmes = walkOns.programmes
                    nextState.players = walkOns.players
                    nextState.people = walkOns.people
                    try appendEvents(
                        payloads: walkOns.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                    do {
                        nextState = try ProMarketSystem.openOffseason(in: nextState)
                    } catch let error as ProMarketError {
                        throw WorldSchedulerError.professionalMarketFailed(error)
                    } catch {
                            throw WorldSchedulerError.professionalMarketFailed(.invalidRoot)
                        }
                    try appendEvents(
                        payloads: [.proMarketOpened(
                            season: nextState.proMarket.season,
                            draftClassCount: nextState.proMarket.draftClass.count,
                            freeAgentCount: nextState.proMarket.freeAgentIDs.count
                        )],
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                } else {
                    try appendEvents(
                        payloads: peopleTransition.eventPayloads,
                        occurredAt: completed,
                        to: &nextState,
                        emittedEvents: &events
                    )
                }
                records.append(WorldStepRecord(step: step, status: .executed))

            case .saveGrowthAndIntegrity:
                nextState.college = CollegeCycleSystem.pruningArchivedProspects(in: nextState)
                var integrityProjection = nextState
                if completed.week == SharedRules.inSeasonWeeks {
                    integrityProjection.calendar = next
                    integrityProjection.league.season = next.season
                    integrityProjection.league.week = next.week
                }
                let report = WorldIntegrity.check(integrityProjection)
                guard report.isValid else {
                    throw WorldSchedulerError.integrityFailed(report.issues)
                }
                try appendEvents(
                    payloads: [.integrityChecked(issueCount: report.issues.count)],
                    occurredAt: completed,
                    to: &nextState,
                    emittedEvents: &events
                )
                nextState.college = CollegeCycleSystem.pruningArchivedProspects(in: nextState)
                records.append(WorldStepRecord(step: step, status: .executed))

            case .weekSnapshot:
                nextState.calendar = next
                nextState.league.season = next.season
                nextState.league.week = next.week
                nextState.tactical.advance(to: next)
                nextState.college.resetWeeklyContactPoints()
                guard nextState.competition.currentSchedule.season == next.season else {
                    throw WorldSchedulerError.integrityFailed([.calendarDisagreement])
                }
                try appendEvents(
                    payloads: [.weekAdvanced(completed: completed, next: next)],
                    occurredAt: next,
                    to: &nextState,
                    emittedEvents: &events
                )
                nextState.college = CollegeCycleSystem.pruningArchivedProspects(in: nextState)
                records.append(WorldStepRecord(step: step, status: .executed))

            default:
                records.append(WorldStepRecord(step: step, status: .inactive))
            }
        }

        let snapshot = WeekSnapshot(
            completed: completed,
            next: next,
            emittedEventIDs: events.map(\.id)
        )
        return WorldTransition(
            state: nextState,
            snapshot: snapshot,
            stepRecords: records,
            emittedEvents: events
        )
    }

    private static func appendEvents(
        payloads: [DomainEventPayload],
        occurredAt: CalendarState,
        to state: inout GameState,
        emittedEvents: inout [DomainEvent]
    ) throws {
        guard !payloads.isEmpty else {
            guard state.history.append(contentsOf: []) else {
                throw WorldSchedulerError.eventAppendFailed
            }
            return
        }
        guard let firstSequence = state.history.firstSequence(
            forAppending: payloads.count
        ) else {
            throw WorldSchedulerError.eventAppendFailed
        }

        var stepEvents: [DomainEvent] = []
        stepEvents.reserveCapacity(payloads.count)
        for (offset, payload) in payloads.enumerated() {
            let (sequence, overflow) = firstSequence.addingReportingOverflow(offset)
            guard !overflow else {
                throw WorldSchedulerError.eventAppendFailed
            }
            stepEvents.append(DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: state.league.seed,
                    sequence: sequence
                ),
                sequence: sequence,
                occurredAt: occurredAt,
                payload: payload
            ))
        }
        guard state.history.append(contentsOf: stepEvents) else {
            throw WorldSchedulerError.eventAppendFailed
        }
        emittedEvents.append(contentsOf: stepEvents)
    }

    private static func resolveAndCommitPortal(
        window: CollegePortalWindow,
        state: inout GameState,
        emittedEvents: inout [DomainEvent]
    ) throws {
        guard let market = CollegePortalPolicyV1.makeMarketSnapshot(
            targetSeason: state.college.recruitingSeason,
            window: window,
            in: state
        ), let result = CollegePortalPolicyV1.match(using: market) else {
            throw WorldSchedulerError.portalMarketFailed(window)
        }
        guard let transition = CollegePortalPolicyV1.commit(result) else {
            throw WorldSchedulerError.portalCommitFailed(window)
        }
        state = transition.state
        try appendExistingEvents(
            transition.events,
            in: state,
            emittedEvents: &emittedEvents
        )
    }

    private static func appendExistingEvents(
        _ existingEvents: [DomainEvent],
        in state: GameState,
        emittedEvents: inout [DomainEvent]
    ) throws {
        let retainedCount = min(existingEvents.count, state.history.retentionLimit)
        guard existingEvents.isEmpty
                || Array(state.history.recent.suffix(retainedCount))
                    == Array(existingEvents.suffix(retainedCount)),
              emittedEvents.last.map({ last in
                  existingEvents.first.map { $0.sequence > last.sequence } ?? true
              }) ?? true else {
            throw WorldSchedulerError.eventAppendFailed
        }
        emittedEvents.append(contentsOf: existingEvents)
    }

}
