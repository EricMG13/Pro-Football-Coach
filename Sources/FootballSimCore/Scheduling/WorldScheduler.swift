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
    case capComplianceFailed(ProManagementError)
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
                if !rivalries.reorderedProgrammeIDs.isEmpty {
                    // Sorted once, outside the loop: `strongest` breaks intensity ties on the
                    // rivalry's own id, and it can only do that from a stable input. Hoisted
                    // because the ordering does not vary per programme.
                    let ranked = rivalries.rivalries.values
                        .sorted { $0.id.uuidString < $1.id.uuidString }
                    for programmeID in rivalries.reorderedProgrammeIDs {
                        let ordered = RivalrySeeder.strongest(for: programmeID, among: ranked)
                        _ = nextState.programmes.update(programmeID) {
                            $0.reorderRivals(to: ordered)
                        }
                    }
                }
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
                    // Contracts expire here: after the people transition and the college cycle have
                    // been applied, and before anything projects the root into the new season. It
                    // used to run at the top of this step, which was wrong in three ways that only
                    // became visible once `0deb629` made a generated world issue contracts at all —
                    // nothing expired before that, so the ordering had never been exercised.
                    //
                    // 1. FSC-013 legalises a departure only when the player's *career record* names
                    //    that organisation for that season, and `SeasonLifecycleSystem.advance`
                    //    writes those rows later in this same step. Expiring first therefore
                    //    invalidated every completed professional game the departing player had
                    //    appeared in, and `expireContracts` refused its own candidate root.
                    // 2. The people transition and the college cycle each assign `nextState.players`
                    //    wholesale, so a cleared contract written before them was discarded.
                    // 3. The portal commit checks the whole root *projected into the target season*
                    //    (`CollegePortalTransactionV1`), and the cap invariant refuses a contract
                    //    whose term has run out by the projected season. Last season's deals had to
                    //    be off the books before that projection is taken, or the college portal
                    //    fails on a professional cap that nothing in the portal touched. That is
                    //    the `portalCommitFailed(.postseason)` this defect register carried as D-1
                    //    with its attribution open; it was never a portal defect.
                    //
                    // `openOffseason` later recomputes the free-agent pool from unowned,
                    // uncontracted players, so expiring here is also what puts them in the market.
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
                    // Beat 2 (`02` §4.2/§4.2a), right after beat 1's expiry and before anything
                    // takes the season-projected view a later step in this same block does (the
                    // college portal's postseason commit): the same D-1 lesson applies here as it
                    // did to expiry itself. Every professional team but the controlled one is
                    // forced legal here so nothing downstream ever sees an over-cap root.
                    do {
                        let compliance = try ProManagementSystem.enforceCapCompliance(
                            at: completed,
                            in: nextState
                        )
                        nextState = compliance.state
                        try appendEvents(
                            payloads: compliance.releases.map {
                                .proCapComplianceRelease(
                                    playerID: $0.playerID,
                                    teamID: $0.teamID,
                                    deadMoneyAdded: $0.deadMoneyAdded
                                )
                            },
                            occurredAt: completed,
                            to: &nextState,
                            emittedEvents: &events
                        )
                    } catch let error as ProManagementError {
                        throw WorldSchedulerError.capComplianceFailed(error)
                    }
                    // After the people transition has been applied, never before it: that assignment
                    // replaces `programmes` wholesale, so prestige written earlier in this step
                    // would be silently discarded. The ranking comes from the archive the season
                    // completion just wrote.
                    if let archive = nextState.competition.archives.last,
                       archive.season == completed.season {
                        nextState = ProgrammeEvolutionSystem.process(
                            collegeRanking: archive.finalCollegeRanking,
                            proRanking: archive.finalProRanking,
                            in: nextState
                        )
                    }
                    // Realignment after evolution, and both before the college cycle rebuilds the
                    // next season's schedule: the schedule is generated from conference membership,
                    // so a swap has to land before it is read, not after.
                    nextState = ConferenceRealignmentSystem.process(in: nextState)
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
