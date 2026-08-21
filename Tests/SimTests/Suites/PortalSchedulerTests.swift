import Foundation
import FootballSimCore

private final class ScholarshipTransactionRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var checkpoints: Set<String> = []
    private(set) var breaches: [(String, [UUID])] = []

    func observe(_ checkpoint: String, state: GameState) {
        let violations = WorldIntegrity.collegeScholarshipViolations(in: state)
        lock.lock()
        defer { lock.unlock() }
        checkpoints.insert(checkpoint)
        if !violations.isEmpty {
            breaches.append((checkpoint, violations))
        }
    }
}

private func portalSchedulerFinalWeekFixture(seed: UInt64) throws -> GameState {
    var state = GameState.bootstrap(seed: seed)
    while state.calendar.week < SharedRules.inSeasonWeeks {
        state = try WorldScheduler.advanceWeek(state).state
    }
    precondition(state.calendar == CalendarState(
        season: 0,
        week: SharedRules.inSeasonWeeks
    ))
    return state
}

func runPortalSchedulerTests() {
    let finalWeek = try! portalSchedulerFinalWeekFixture(seed: 98_001)
    let postseason = try! WorldScheduler.advanceWeek(finalWeek)
    let spring = try! WorldScheduler.advanceWeek(postseason.state)

    suite("College portal scheduler lifecycle") {
        test("scholarships remain valid immediately after the season lifecycle transaction") {
            var state = finalWeek
            let programmeID = state.programmes.ids[0]
            let playerID = state.college.programmes[programmeID]!.scholarshipPlayerIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 1)
            }
            var programmeStates = state.college.programmes
            let recruiting = programmeStates[programmeID]!
            var nilState = recruiting.nilState
            expect(nilState.setRosterAllocation(1, for: playerID))
            programmeStates[programmeID] = ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: recruiting.boardIDs,
                relationships: recruiting.relationships,
                scholarshipPlayerIDs: recruiting.scholarshipPlayerIDs,
                contactPointsRemaining: recruiting.contactPointsRemaining,
                nilState: nilState
            )
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: state.college.phase,
                programmes: programmeStates,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: state.college.redshirtPlans
            )

            let transition = try SeasonLifecycleSystem.advance(
                after: state.calendar,
                in: state
            )
            var afterTransaction = state
            afterTransaction.programmes = transition.programmes
            afterTransaction.proTeams = transition.proTeams
            afterTransaction.players = transition.players
            afterTransaction.staff = transition.staff
            afterTransaction.people = transition.people
            afterTransaction.college = transition.college

            expect(WorldIntegrity.collegeScholarshipViolations(in: afterTransaction).isEmpty)
            expectEqual(
                afterTransaction.college.programmes[programmeID]?
                    .nilState.rosterAllocations[playerID],
                nil
            )
        }

        test("scholarships remain valid after every scheduler transaction") {
            let recorder = ScholarshipTransactionRecorder()
            WorldScheduler.transactionObserver = { checkpoint, state in
                recorder.observe(checkpoint, state: state)
            }
            defer { WorldScheduler.transactionObserver = nil }

            var state = finalWeek
            state = try WorldScheduler.advanceWeek(state).state
            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(state.calendar, CalendarState(season: 1, week: 2))

            for checkpoint in [
                "seasonLifecycle",
                "reconcileScholarships",
                "collegeCycle.closeAndOpen",
                "portalCommit.postseason",
                "walkOns.postseasonCoverage",
                "portalCommit.spring",
                "walkOns.springRosterFill",
                "recruitingMarket.weekly",
                "recruitingMarket.terminal",
                "recruitingAI",
                "recruitingDelegation",
            ] {
                expect(
                    recorder.checkpoints.contains(checkpoint),
                    "transaction checkpoint \(checkpoint) never ran"
                )
            }
            for step in WorldScheduler.steps {
                expect(
                    recorder.checkpoints.contains("step.\(step.rawValue)"),
                    "scheduler step \(step.rawValue) was not checked"
                )
            }
            for breach in recorder.breaches.prefix(8) {
                expect(false, "scholarships broke after \(breach.0): \(breach.1)")
            }
            expectEqual(recorder.breaches.count, 0)
        }

        test("final-week rollover commits postseason portal before minimum walk-on coverage") {
            let transition = postseason
            expectEqual(transition.state.calendar, CalendarState(season: 1, week: 1))
            expectEqual(transition.state.college.portal.phase, .awaitingSpring)
            expectEqual(
                transition.state.college.portal.summaries.map(\.window),
                [.postseason]
            )
            expect(transition.state.college.portal.entries.values.allSatisfy {
                $0.window == .postseason
            })
            expect(transition.state.programmes.values.allSatisfy { programme in
                let counts = Dictionary(grouping: programme.rosterIDs.compactMap {
                    transition.state.players[$0]?.position
                }, by: { $0 }).mapValues(\.count)
                return SharedRules.minimumPlayableRosterByPosition.allSatisfy {
                    position, minimum in (counts[position] ?? 0) >= minimum
                }
            })
            expect(transition.state.programmes.values.contains {
                $0.rosterIDs.count < CollegeRules.rosterLimit
            })
            expect(WorldIntegrity.check(transition.state).isValid)
        }

        test("week one resolves spring before recruiting and games then fills every roster") {
            expectEqual(spring.state.calendar, CalendarState(season: 1, week: 2))
            expectEqual(spring.state.college.portal.phase, .closed)
            expectEqual(
                spring.state.college.portal.summaries.map(\.window),
                [.postseason, .spring]
            )
            expect(spring.state.college.portal.entries.values.allSatisfy {
                $0.window == .spring
            })
            expect(spring.state.programmes.values.allSatisfy {
                $0.rosterIDs.count == CollegeRules.rosterLimit
            })
            let scoutingStep = spring.stepRecords.first { $0.step == .scoutingKnowledge }
            expectEqual(scoutingStep?.status, .inactive)

            let completionIndex = spring.emittedEvents.firstIndex {
                if case .portalWindowCompleted(let summary) = $0.payload {
                    return summary.window == .spring
                }
                return false
            }
            expect(completionIndex != nil)
            if let completionIndex {
                let premature = spring.emittedEvents[..<completionIndex].contains { event in
                    switch event.payload {
                    case .recruitingInteraction, .prospectCommitted, .gameCompleted:
                        return true
                    default:
                        return false
                    }
                }
                expect(!premature)
            }
            expect(WorldIntegrity.check(spring.state).isValid)
        }

        test("postseason and spring preserve durable careers without a second transfer") {
            let postseasonRecords = postseason.state.college.portal.entries
            let springRecords = spring.state.college.portal.entries
            for (playerID, record) in postseasonRecords {
                expectEqual(
                    spring.state.people.playerCareers[playerID]?.portalWindows.first,
                    record
                )
            }
            for career in spring.state.people.playerCareers.values {
                let transferred = career.portalWindows.filter { record in
                    guard record.targetSeason == 1 else { return false }
                    if case .transferred = record.outcome { return true }
                    return false
                }
                expect(transferred.count <= 1)
            }
            let signedIDs = Set(postseason.emittedEvents.compactMap { event -> UUID? in
                if case let .playerJoined(playerID, _, source) = event.payload,
                   source == .recruitedScholarship {
                    return playerID
                }
                return nil
            })
            expect(signedIDs.isDisjoint(with: Set(postseasonRecords.keys)))
            expect(signedIDs.isDisjoint(with: Set(springRecords.keys)))
        }

        test("both portal boundaries survive save round trips") {
            let encoder = JSONEncoder.stable()
            let decoder = JSONDecoder()
            let postseasonData = try encoder.encode(postseason.state)
            let springData = try encoder.encode(spring.state)
            expectEqual(
                try decoder.decode(GameState.self, from: postseasonData),
                postseason.state
            )
            expectEqual(
                try decoder.decode(GameState.self, from: springData),
                spring.state
            )
        }

        test("portal event groups are causally ordered around rollover and spring work") {
            let firstPostseasonPortal = postseason.emittedEvents.firstIndex {
                if case .portalEntered = $0.payload { return true }
                return false
            }
            let postseasonCompletion = postseason.emittedEvents.firstIndex {
                if case .portalWindowCompleted(let summary) = $0.payload {
                    return summary.window == .postseason
                }
                return false
            }
            expect(firstPostseasonPortal != nil)
            expect(postseasonCompletion != nil)
            if let firstPostseasonPortal, let postseasonCompletion {
                for (index, event) in postseason.emittedEvents.enumerated() {
                    switch event.payload {
                    case .redshirtResolved, .playerDeparted, .commitmentResolved:
                        expect(index < firstPostseasonPortal)
                    case let .playerJoined(_, _, source) where source == .recruitedScholarship:
                        expect(index < firstPostseasonPortal)
                    case let .playerJoined(_, _, source) where source == .walkOn:
                        expect(index > postseasonCompletion)
                    default:
                        break
                    }
                }
            }
            expect(postseason.state.competition.currentSchedule.games.allSatisfy {
                $0.season != 1 || $0.result == nil
            })
        }

        test("awaiting spring blocks direct scouting market AI and recruiting intents") {
            var awaiting = postseason.state
            let programmeID = awaiting.programmes.ids[0]
            let prospectID = awaiting.prospects.ids[0]
            expect(awaiting.scouting.queueEvaluation(
                observerID: programmeID,
                prospectID: prospectID,
                effort: 1
            ))
            let scoutingBefore = awaiting.scouting
            let scouting = ScoutingSystem.process(at: awaiting.calendar, in: awaiting)
            expectEqual(scouting.scouting, scoutingBefore)
            expect(scouting.eventPayloads.isEmpty)

            let awaitingPortal = awaiting.college.portal
            awaiting.college = CollegeState(
                recruitingSeason: awaiting.college.recruitingSeason,
                portal: CollegePortalState(targetSeason: awaiting.college.recruitingSeason),
                phase: awaiting.college.phase,
                programmes: awaiting.college.programmes,
                prospectRecruitment: awaiting.college.prospectRecruitment,
                archivedProspects: awaiting.college.archivedProspects,
                redshirtPlans: awaiting.college.redshirtPlans
            )
            let seededBoard = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .addToBoard
                ),
                in: awaiting
            )
            awaiting.college = CollegeState(
                recruitingSeason: seededBoard.college.recruitingSeason,
                portal: awaitingPortal,
                phase: seededBoard.college.phase,
                programmes: seededBoard.college.programmes,
                prospectRecruitment: seededBoard.college.prospectRecruitment,
                archivedProspects: seededBoard.college.archivedProspects,
                redshirtPlans: seededBoard.college.redshirtPlans
            )
            awaiting.scouting = seededBoard.scouting
            let awaitingBytes = try JSONEncoder.stable().encode(awaiting)
            do {
                _ = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: .contact(points: 1)
                    ),
                    in: awaiting
                )
                expect(false, "direct recruiting mutation bypassed the spring portal pause")
            } catch let error as RecruitingActionError {
                expectEqual(error, .cycleUnavailable)
            }
            expectEqual(try JSONEncoder.stable().encode(awaiting), awaitingBytes)
            let market = CollegeRecruitingMarketSystem.process(
                at: awaiting.calendar,
                in: awaiting
            )
            expectEqual(market.college, awaiting.college)
            expect(market.eventPayloads.isEmpty)
            let ai = try CollegeRecruitingAISystem.process(in: awaiting)
            expectEqual(ai.college, awaiting.college)
            expectEqual(ai.scouting, awaiting.scouting)
            expect(ai.decisions.isEmpty)
            expect(ai.eventPayloads.isEmpty)

            do {
                _ = try IntentResolver.resolve(
                    .recruiting(RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: .contact(points: 1)
                    )),
                    in: awaiting
                )
                expect(false, "recruiting intent acted before spring portal closure")
            } catch let error as IntentResolutionError {
                expectEqual(error, .recruitingUnavailableDuringPortal)
            }
        }

        test("walk-on windows use distinct ordinals and skip every reserved world identity") {
            var collisionState = postseason.state
            let programmeID = collisionState.programmes.ids[0]
            let programme = collisionState.programmes[programmeID]!
            let position = Position.allCases.first {
                (SharedRules.minimumPlayableRosterByPosition[$0] ?? 0) > 0
            }!
            let minimum = SharedRules.minimumPlayableRosterByPosition[position]!
            let positionIDs = programme.rosterIDs.filter {
                collisionState.players[$0]?.position == position
            }
            let removalCount = max(0, positionIDs.count - minimum + 1)
            let removed = Set(positionIDs.prefix(removalCount))
            _ = collisionState.programmes.update(programmeID) {
                $0.rosterIDs.removeAll(where: removed.contains)
            }

            let collided = RosterPopulationGenerator.walkOn(
                rootSeed: collisionState.league.seed,
                season: 1,
                organisationID: programmeID,
                position: position,
                ordinal: CollegeWalkOnWindow.postseasonCoverage.rawValue * 1_000_000,
                prestige: programme.prestige
            )
            collisionState.league = League(
                id: collided.id,
                seed: collisionState.league.seed,
                season: collisionState.league.season,
                week: collisionState.league.week,
                conferences: collisionState.league.conferences,
                divisions: collisionState.league.divisions
            )
            let postseasonWalkOns = CollegeCycleSystem.addWalkOns(
                for: .postseasonCoverage,
                season: 1,
                in: collisionState
            )
            let nextPostseason = RosterPopulationGenerator.walkOn(
                rootSeed: collisionState.league.seed,
                season: 1,
                organisationID: programmeID,
                position: position,
                ordinal: CollegeWalkOnWindow.postseasonCoverage.rawValue * 1_000_000 + 1,
                prestige: programme.prestige
            )
            expect(!postseasonWalkOns.programmes[programmeID]!.rosterIDs.contains(collided.id))
            expect(postseasonWalkOns.programmes[programmeID]!.rosterIDs.contains(nextPostseason.id))

            let springFirst = RosterPopulationGenerator.walkOn(
                rootSeed: collisionState.league.seed,
                season: 1,
                organisationID: programmeID,
                position: position,
                ordinal: CollegeWalkOnWindow.springRosterFill.rawValue * 1_000_000,
                prestige: programme.prestige
            )
            let springWalkOns = CollegeCycleSystem.addWalkOns(
                for: .springRosterFill,
                season: 1,
                in: collisionState
            )
            expect(springWalkOns.programmes[programmeID]!.rosterIDs.contains(springFirst.id))
            expect(nextPostseason.id != springFirst.id)
        }

        test("bounded history retains one portal event but emits the complete committed batch") {
            var bounded = finalWeek
            var history = DomainEventLedger(retentionLimit: 1)
            expect(history.append(contentsOf: finalWeek.history.recent))
            bounded.history = history

            let transition = try WorldScheduler.advanceWeek(bounded)
            let portalEvents = transition.emittedEvents.filter { event in
                switch event.payload {
                case .portalEntered, .portalRetentionResolved, .portalOfferMade,
                     .playerTransferred, .portalWindowCompleted:
                    return true
                default:
                    return false
                }
            }
            expect(portalEvents.count > transition.state.history.recent.count)
            expectEqual(transition.state.history.recent.count, 1)
            expectEqual(transition.state.college.portal.phase, .awaitingSpring)
            expect(WorldIntegrity.check(transition.state).isValid)
        }

        test("a second season replays byte-identically and reports untuned portal outcomes") {
            let encoder = JSONEncoder.stable()
            let savedSpring = try encoder.encode(spring.state)
            var first = spring.state
            var second = try JSONDecoder().decode(GameState.self, from: savedSpring)
            var firstEvents: [DomainEvent] = []
            var secondEvents: [DomainEvent] = []
            let startedAt = Date()
            while first.calendar.season < 2 || first.calendar.week < 2 {
                let firstTransition = try WorldScheduler.advanceWeek(first)
                let secondTransition = try WorldScheduler.advanceWeek(second)
                first = firstTransition.state
                second = secondTransition.state
                firstEvents.append(contentsOf: firstTransition.emittedEvents)
                secondEvents.append(contentsOf: secondTransition.emittedEvents)
            }
            let runtimeMilliseconds = Int(Date().timeIntervalSince(startedAt) * 1_000)

            expectEqual(try encoder.encode(first), try encoder.encode(second))
            expectEqual(
                try encoder.encode(firstEvents),
                try encoder.encode(secondEvents)
            )
            expectEqual(first.calendar, CalendarState(season: 2, week: 2))
            expectEqual(first.college.portal.phase, .closed)
            expectEqual(first.college.portal.targetSeason, 2)
            expectEqual(first.college.portal.summaries.map(\.window), [.postseason, .spring])
            expect(WorldIntegrity.check(first).isValid)

            let currentRecords = first.people.playerCareers.values
                .flatMap(\.portalWindows)
                .filter { $0.targetSeason == 2 }
            let retained = currentRecords.filter { $0.outcome == .retainedBySource }.count
            let returned = currentRecords.filter { $0.outcome == .returnedToSource }.count
            let transferredRecords = currentRecords.filter {
                if case .transferred = $0.outcome { return true }
                return false
            }
            let transferNIL = transferredRecords.map(\.finalRosterNIL)
            let nilTotal = transferNIL.reduce(0, +)
            let nilMinimum = transferNIL.min() ?? 0
            let nilMaximum = transferNIL.max() ?? 0
            print(
                "portal scheduler characterization: runtimeMs=\(runtimeMilliseconds) "
                    + "entrantWindows=\(currentRecords.count) retained=\(retained) "
                    + "transferred=\(transferredRecords.count) returned=\(returned) "
                    + "transferNILTotal=\(nilTotal) transferNILMin=\(nilMinimum) "
                    + "transferNILMax=\(nilMaximum)"
            )
        }
    }
}
