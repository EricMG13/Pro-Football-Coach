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
    /// A user-owned controlled fixture must be entered through `CareerSession` so its
    /// resumable MatchSessionState is persisted instead of being silently abstracted.
    case controlledMatchRequired(UUID)
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
    private static let missingFixtureID = UUID(uuidString: "00000000-0000-4000-8000-000000000000")!

    /// Test-only checkpoint after each committed transaction inside the weekly step loop, so an
    /// invariant can be asserted **after every transaction** rather than only on the root the week
    /// comes to rest on.
    ///
    /// `WorldIntegrity` runs once a week, at `.saveGrowthAndIntegrity`. Everything the season
    /// boundary does — the people transition, scholarship reconciliation, the cycle rollover, both
    /// portal windows, both walk-on windows — commits inside a single step, so a rule can be
    /// breached and repaired between two consecutive transactions and the week still comes to rest
    /// clean. That is not a hypothetical: `reconcileScholarships` exists precisely to repair one.
    ///
    /// `package`, so nothing outside this package can install one, and `nil` in every shipped
    /// build: each checkpoint is then a null check.
    package nonisolated(unsafe) static var transactionObserver: (
        @Sendable (String, GameState) -> Void
    )?

    /// The label is autoclosed so a shipped build never builds one: the per-step call site
    /// interpolates, and interpolating sixteen strings a week to hand them to a `nil` observer is
    /// a test seam charging the game for its own existence.
    @inline(__always)
    private static func checkpoint(
        _ label: @autoclosure () -> String,
        _ state: @autoclosure () -> GameState
    ) {
        guard let transactionObserver else { return }
        transactionObserver(label(), state())
    }

    /// Installs a resumable controlled fixture before the weekly transaction can abstract it.
    /// Calling this repeatedly is idempotent: an existing checkpoint is returned unchanged.
    public static func prepareControlledMatch(in state: GameState) throws -> GameState {
        guard state.matchSession == nil,
              let controlledID = controlledOrganisationID(in: state),
              let game = state.competition.currentSchedule.games.first(where: {
                  $0.season == state.calendar.season
                      && $0.week == state.calendar.week
                      && $0.result == nil
                      && ($0.homeID == controlledID || $0.awayID == controlledID)
              }) else {
            return state
        }

        var next = state
        next.matchSession = makeMatchSession(for: game, controlledID: controlledID, in: &next)
        let integrity = WorldIntegrity.check(next)
        guard integrity.isValid else {
            throw WorldSchedulerError.integrityFailed(integrity.issues)
        }
        return next
    }

    /// Commits one completed controlled fixture exactly once. The weekly scheduler remains the
    /// owner of all later phases; its next invocation sees this result and processes only the
    /// remaining due games before standings, records, and the week snapshot.
    public static func finalizeControlledMatch(
        _ completion: MatchCompletionReceipt,
        in state: GameState
    ) throws -> GameState {
        guard let session = state.matchSession,
              session.completed,
              let fixtureID = session.fixtureID,
              completion.evidence.fixtureID == fixtureID,
              session.completion == completion,
              let game = state.competition.currentSchedule.games.first(where: {
                  $0.id == fixtureID
              }), game.result == nil,
              completion.record.tier == game.tier else {
            throw WorldSchedulerError.scheduledGameMissing(
                completion.evidence.fixtureID ?? missingFixtureID
            )
        }
        let summary = DetailedGameSummaryBuilder.make(
            record: completion.record,
            homeParticipantIDs: session.home.offense.map(\.id) + session.home.defense.map(\.id),
            awayParticipantIDs: session.away.offense.map(\.id) + session.away.defense.map(\.id),
            evidence: completion.evidence
        )
        var next = state
        do {
            _ = try next.competition.currentSchedule.recordResults([
                ScheduledGameResult(gameID: fixtureID, summary: summary)
            ])
        } catch let error as ScheduleResultRecordingError {
            throw WorldSchedulerError.scheduleResultRecordingFailed(error)
        }
        next.matchSession = nil
        TacticalPlanSystem.recordReviews(
            for: game,
            result: summary,
            at: state.calendar,
            in: &next.tactical
        )
        var emittedEvents: [DomainEvent] = []
        try appendEvents(
            payloads: [.gameCompleted(
                gameID: game.id,
                homeID: game.homeID,
                awayID: game.awayID,
                stage: game.stage,
                homeScore: summary.homeScore,
                awayScore: summary.awayScore
            )],
            occurredAt: state.calendar,
            to: &next,
            emittedEvents: &emittedEvents
        )
        next.competition = CompetitionReducer.rebuildStandings(from: next)
        next.competition = CompetitionReducer.rebuildStatistics(from: next)
        let integrity = WorldIntegrity.check(next)
        guard integrity.isValid else {
            throw WorldSchedulerError.integrityFailed(integrity.issues)
        }
        return next
    }

    private static func controlledOrganisationID(in state: GameState) -> UUID? {
        if let college = state.career.college { return college.programmeID }
        guard let job = state.careerArc.currentJob, job.tier == .professional else { return nil }
        return job.organisationID
    }

    private static func attachInjuryEvidence(
        from payloads: [DomainEventPayload],
        at calendar: CalendarState,
        to state: inout GameState
    ) {
        guard calendar.week > 1 else { return }
        let workloadCalendar = CalendarState(season: calendar.season, week: calendar.week - 1)
        let injuries = payloads.compactMap { payload -> (UUID, InjuryArea, InjurySeverity, Int)? in
            guard case let .playerInjured(playerID, area, severity, weeks) = payload else {
                return nil
            }
            return (playerID, area, severity, weeks)
        }
        guard !injuries.isEmpty else { return }

        var byGame: [UUID: [GameInjuryEvidence]] = [:]
        for (playerID, area, severity, weeks) in injuries {
            guard let game = state.competition.currentSchedule.games
                .filter({ game in
                    game.season == workloadCalendar.season
                        && game.week == workloadCalendar.week
                        && game.result?.source == .detailed
                        && game.result?.evidence != nil
                        && ((game.result?.homeParticipantIDs.contains(playerID) ?? false)
                            || (game.result?.awayParticipantIDs.contains(playerID) ?? false))
                })
                .sorted(by: { $0.id.uuidString < $1.id.uuidString })
                .first,
                  let result = game.result,
                  let evidence = result.evidence else { continue }

            let side: Side = result.homeParticipantIDs.contains(playerID) ? .home : .away
            guard !evidence.injuries.contains(where: { $0.playerID == playerID }) else {
                continue
            }
            byGame[game.id, default: []].append(GameInjuryEvidence(
                playerID: playerID,
                side: side,
                area: area,
                severity: severity,
                weeks: weeks,
                occurredAt: workloadCalendar
            ))
        }

        for gameID in byGame.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard var game = state.competition.currentSchedule.games.first(where: { $0.id == gameID }),
                  let result = game.result,
                  let evidence = result.evidence else { continue }
            let updatedEvidence = GameEvidence(
                fixtureID: evidence.fixtureID ?? gameID,
                record: evidence.record,
                homeParticipantIDs: evidence.homeParticipantIDs,
                awayParticipantIDs: evidence.awayParticipantIDs,
                callInReceipts: evidence.callInReceipts,
                injuries: evidence.injuries + (byGame[gameID] ?? [])
            )
            game.result = GameSummary(
                homeScore: result.homeScore,
                awayScore: result.awayScore,
                homeStatistics: result.homeStatistics,
                awayStatistics: result.awayStatistics,
                homeParticipantIDs: result.homeParticipantIDs,
                awayParticipantIDs: result.awayParticipantIDs,
                playerStatistics: result.playerStatistics,
                source: result.source,
                evidence: updatedEvidence
            )
            _ = state.competition.currentSchedule.replace(game)
        }
    }

    private static func fullyDelegatedCollegeCareer(in state: GameState) -> Bool {
        guard let control = state.career.college else { return false }
        return CollegeCareerResponsibility.allCases.allSatisfy { responsibility in
            if case .delegated = control.responsibilityOwners[responsibility] {
                return true
            }
            return false
        }
    }

    private static func makeMatchSession(
        for game: ScheduledGame,
        controlledID: UUID,
        in state: inout GameState
    ) -> MatchSessionState {
        let homeRoster = playableRoster(for: game.homeID, tier: game.tier, in: state)
        let awayRoster = playableRoster(for: game.awayID, tier: game.tier, in: state)
        let homeUnavailable = unavailableIDs(for: game.homeID, tier: game.tier, in: state)
        let awayUnavailable = unavailableIDs(for: game.awayID, tier: game.tier, in: state)
        let homePersonnel = DepthChart.personnel(
            roster: homeRoster,
            plan: state.tactical.personnelPlan(for: game.homeID, at: state.calendar),
            unavailableIDs: homeUnavailable
        )
        let awayPersonnel = DepthChart.personnel(
            roster: awayRoster,
            plan: state.tactical.personnelPlan(for: game.awayID, at: state.calendar),
            unavailableIDs: awayUnavailable
        )
        let homePlan = TacticalPlanSystem.plan(
            for: game.homeID,
            against: game.awayID,
            at: state.calendar,
            in: state,
            tactical: &state.tactical
        )
        let awayPlan = TacticalPlanSystem.plan(
            for: game.awayID,
            against: game.homeID,
            at: state.calendar,
            in: state,
            tactical: &state.tactical
        )
        return MatchReducer.start(
            tier: game.tier,
            stage: game.stage,
            home: homePersonnel,
            away: awayPersonnel,
            seed: SeededRandom.derive(
                from: state.league.seed,
                scope: .game,
                identifier: game.id
            ),
            controlledSide: game.homeID == controlledID ? .home : .away,
            homePlan: homePlan,
            awayPlan: awayPlan,
            fixtureID: game.id
        )
    }

    private static func playableRoster(
        for organisationID: UUID,
        tier: Tier,
        in state: GameState
    ) -> [Player] {
        let ids: [UUID]
        switch tier {
        case .college: ids = state.programmes[organisationID]?.rosterIDs ?? []
        case .pro: ids = state.proTeams[organisationID]?.rosterIDs ?? []
        }
        return ids.compactMap { state.players[$0] }
    }

    private static func unavailableIDs(
        for organisationID: UUID,
        tier: Tier,
        in state: GameState
    ) -> Set<UUID> {
        let roster = playableRoster(for: organisationID, tier: tier, in: state)
        return Set(roster.compactMap { player in
            guard state.people.playerLifecycle[player.id]?.isAvailable == true else { return player.id }
            if tier == .college,
               !CollegeRedshirtSystem.allowsAutomaticAppearance(
                   playerID: player.id,
                   programmeID: organisationID,
                   in: state
               ) {
                return player.id
            }
            return nil
        })
    }

    public static func advanceWeek(_ state: GameState) throws -> WorldTransition {
        if let session = state.matchSession, let fixtureID = session.fixtureID {
            throw WorldSchedulerError.controlledMatchRequired(fixtureID)
        }
        if let controlledID = controlledOrganisationID(in: state),
           let game = state.competition.currentSchedule.games.first(where: {
               $0.season == state.calendar.season
                   && $0.week == state.calendar.week
                   && $0.result == nil
                   && ($0.homeID == controlledID || $0.awayID == controlledID)
           }),
           !fullyDelegatedCollegeCareer(in: state) {
            throw WorldSchedulerError.controlledMatchRequired(game.id)
        }
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
                    checkpoint("portalCommit.spring", nextState)
                    let walkOns = CollegeCycleSystem.addWalkOns(
                        for: .springRosterFill,
                        season: completed.season,
                        in: nextState
                    )
                    nextState.programmes = walkOns.programmes
                    nextState.players = walkOns.players
                    nextState.people = walkOns.people
                    checkpoint("walkOns.springRosterFill", nextState)
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
                checkpoint("recruitingMarket.weekly", nextState)
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
                checkpoint("recruitingAI", nextState)
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
                checkpoint("recruitingDelegation", nextState)
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
                attachInjuryEvidence(
                    from: transition.eventPayloads,
                    at: completed,
                    to: &nextState
                )
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
                    tactical: &nextState.tactical
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
                let personnelPlans = nextState.tactical.personnelPlansByOrganisation
                let resultRecords = dueGames.map { game in
                    ScheduledGameResult(
                        gameID: game.id,
                        summary: AbstractGameSimulator.play(
                            game,
                            in: nextState,
                            tacticalPlans: tacticalPlans,
                            personnelPlans: personnelPlans
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
                if nextState.careerArc.status == .fired {
                    // Firing revokes control in the same scheduler transaction. Leaving the
                    // college control record behind lets a fired coach keep advancing the old
                    // team through the next screen, and leaving the chair behind leaves them
                    // listed as the programme's head coach on every staff surface.
                    nextState.career.clearCollege()
                    CareerControlSystem.vacateCurrentSeat(in: &nextState)
                }
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
                    checkpoint("recruitingMarket.terminal", nextState)
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
                    if nextState.careerArc.status == .fired {
                        nextState.career.clearCollege()
                        CareerControlSystem.vacateCurrentSeat(in: &nextState)
                    }
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
                nextState.college = peopleTransition.college
                checkpoint("seasonLifecycle", nextState)
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
                    // D15 (`02` §4.2a): dead money is a single-season charge, so the season now
                    // ending is discharged here -- after beat 1, before beat 2. The compliance
                    // pass below then charges the season about to start, which makes each season's
                    // dead money exactly that season's releases rather than every release the save
                    // has ever made.
                    nextState = ProManagementSystem.dischargeDeadMoney(in: nextState)
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
                    // Realignment sits here, after evolution and before the college cycle, and
                    // it cannot be hoisted above the slate that reads it: `completeSeason` draws
                    // the whole of next season from conference membership, and it runs earlier in
                    // this same step because the season-completed event has to stay observable
                    // ahead of lifecycle and cycle construction. So the slate is redrawn below
                    // rather than the swap being moved above the event it must follow.
                    //
                    // Its own placement costs nothing either way — `bestSwap` scores a swap purely
                    // on the distance from a programme's city to its conference's centroid, so
                    // neither evolution nor the cycle can move its answer.
                    let realignment = ConferenceRealignmentSystem.processTransition(in: nextState)
                    nextState = realignment.state
                    if !realignment.swaps.isEmpty {
                        try appendEvents(
                            payloads: [.realignment(
                                season: completed.season,
                                reason: realignment.reason,
                                swaps: realignment.swaps
                            )],
                            occurredAt: completed,
                            to: &nextState,
                            emittedEvents: &events
                        )
                        // `completeSeason` drew the coming season from the map this swap has just
                        // replaced, so every programme that moved was scheduled into the
                        // conference it left. Redraw against the map that now exists.
                        //
                        // A redraw rather than a patch because `ScheduleGenerator` pairs a whole
                        // tier at once: one changed membership shifts the preference filter for
                        // every week, so there is no local edit that leaves the rest standing.
                        // The professional slate is regenerated from unchanged inputs and so comes
                        // back identical; only the college one moves. Nothing has to be rebuilt
                        // behind it — standings and statistics read completed games, and a slate
                        // this new has none.
                        //
                        // Guarded on the season having actually rolled: `completeSeason` declines
                        // to roll one that finished without a champion, and must keep the slate it
                        // declined on.
                        if nextState.competition.currentSchedule.season == completed.season + 1 {
                            nextState.competition.currentSchedule = SeasonSchedule(
                                season: completed.season + 1,
                                games: ScheduleGenerator.regularSeason(
                                    seed: nextState.league.seed,
                                    season: completed.season + 1,
                                    programmes: nextState.programmes.values,
                                    proTeams: nextState.proTeams.values
                                )
                            )
                        }
                    }
                    nextState.college.reconcileScholarships(with: nextState.programmes)
                    checkpoint("reconcileScholarships", nextState)
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
                    checkpoint("collegeCycle.closeAndOpen", nextState)
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
                    checkpoint("portalCommit.postseason", nextState)
                    let walkOns = CollegeCycleSystem.addWalkOns(
                        for: .postseasonCoverage,
                        season: completed.season + 1,
                        in: nextState
                    )
                    nextState.programmes = walkOns.programmes
                    nextState.players = walkOns.players
                    nextState.people = walkOns.people
                    checkpoint("walkOns.postseasonCoverage", nextState)
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
                // Signing day (`02` section 4.1). Set here rather than in an earlier step because
                // this is where the calendar itself moves: `saveGrowthAndIntegrity` has already
                // checked the root against the week being *left*, so a phase written before it
                // would be checked against the wrong week. Assigned unconditionally, not only on
                // the boundary that opens it, so the phase cannot survive a week it does not
                // belong to.
                nextState.college.phase = CollegeRules.recruitingCyclePhase(inWeek: next.week)
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
            checkpoint("step.\(step.rawValue)", nextState)
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
