import Foundation
import FootballSimCore

private func applyingCollegeCycle(
    _ transition: CollegeCycleTransition,
    to state: GameState
) -> GameState {
    var next = state
    next.programmes = transition.programmes
    next.players = transition.players
    next.people = transition.people
    next.prospects = transition.prospects
    next.college = transition.college
    next.scouting = transition.scouting
    let nextSeason = transition.college.recruitingSeason
    next.calendar = CalendarState(season: nextSeason, week: 1)
    next.league.season = nextSeason
    next.league.week = 1
    next.competition = CompetitionState(
        currentSchedule: SeasonSchedule(
            season: nextSeason,
            games: ScheduleGenerator.regularSeason(
                seed: next.league.seed,
                season: nextSeason,
                programmes: next.programmes.values,
                proTeams: next.proTeams.values
            )
        ),
        archives: next.competition.archives,
        recordBook: next.competition.recordBook
    )
    next.competition = CompetitionReducer.rebuild(from: next)
    return next
}

private func recruitingHistoryEvent(
    in state: GameState,
    prospectID: UUID,
    sequence: Int
) -> DomainEvent {
    DomainEvent(
        id: DomainEvent.deterministicID(rootSeed: state.league.seed, sequence: sequence),
        sequence: sequence,
        occurredAt: state.calendar,
        payload: .recruitingInteraction(
            programmeID: state.programmes.ids[0],
            prospectID: prospectID,
            action: .contact,
            resourceCost: 1,
            interestAfter: 1
        )
    )
}

func runCollegeStateTests() {
    if ProcessInfo.processInfo.environment["INVALID_ELIGIBILITY_CONSTRUCTION_PROBE"] != nil {
        _ = Eligibility(
            seasonsRemaining: CollegeRules.seasonsOfCompetition + 1,
            yearsRemaining: CollegeRules.eligibilityClockYears
        )
        return
    }

    suite("College management state") {
        test("eligibility construction rejects counters outside their supported bounds") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            process.arguments = ["--college-state"]
            var environment = ProcessInfo.processInfo.environment
            environment["INVALID_ELIGIBILITY_CONSTRUCTION_PROBE"] = "1"
            process.environment = environment

            try process.run()
            process.waitUntilExit()

            expect(process.terminationStatus != 0)
        }

        test("persisted eligibility rejects counters outside their supported bounds") {
            let hostileCounters = [
                (-1, CollegeRules.eligibilityClockYears),
                (CollegeRules.seasonsOfCompetition + 1, CollegeRules.eligibilityClockYears),
                (CollegeRules.seasonsOfCompetition, -1),
                (CollegeRules.seasonsOfCompetition, CollegeRules.eligibilityClockYears + 1),
            ]

            for (seasonsRemaining, yearsRemaining) in hostileCounters {
                let data = Data(
                    #"{"seasonsRemaining":\#(seasonsRemaining),"yearsRemaining":\#(yearsRemaining)}"#.utf8
                )
                do {
                    _ = try JSONDecoder().decode(Eligibility.self, from: data)
                    expect(
                        false,
                        "eligibility decoded counters \(seasonsRemaining)/\(yearsRemaining)"
                    )
                } catch {
                    expect(true)
                }
            }
        }

        test("active college roots reject impossible eligibility clock gaps") {
            let baseline = GameState.bootstrap(seed: 92_040)
            let programme = baseline.programmes.values[0]
            let playerID = programme.rosterIDs[0]
            let hostileClocks = [
                Eligibility(
                    seasonsRemaining: CollegeRules.seasonsOfCompetition,
                    yearsRemaining: CollegeRules.seasonsOfCompetition - 1
                ),
                Eligibility(seasonsRemaining: 1, yearsRemaining: 3),
            ]

            for clock in hostileClocks {
                var state = baseline
                state.players.update(playerID) {
                    $0.eligibility = clock
                }
                expect(
                    WorldIntegrity.check(state).issues.contains(
                        .invalidPlayerLifecycle(playerID: playerID)
                    )
                )
            }
        }

        test("persisted college state requires a non-null redshirt-plan collection") {
            let state = GameState.bootstrap(seed: 92_041)
            let encoded = try JSONEncoder().encode(state.college)
            let baseline = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

            var missing = baseline
            missing.removeValue(forKey: "redshirtPlans")
            var null = baseline
            null["redshirtPlans"] = NSNull()

            for object in [missing, null] {
                do {
                    _ = try JSONDecoder().decode(
                        CollegeState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "college state decoded without a redshirt-plan collection")
                } catch {
                    expect(true)
                }
            }
        }

        test("persisted redshirt plans belong to a current college programme and their key") {
            let state = GameState.bootstrap(seed: 92_042)
            let programme = state.programmes.values[0]
            let playerID = programme.rosterIDs[0]
            let plan = RedshirtPlan(
                playerID: playerID,
                programmeID: programme.id,
                season: state.college.recruitingSeason,
                plannedAppearanceLimit: CollegeRules.maximumRedshirtAppearances
            )
            let college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: state.college.phase,
                programmes: state.college.programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: [playerID: plan]
            )
            let encoded = try JSONEncoder().encode(college)
            let baseline = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

            func replacingPlan(
                key: UUID = playerID,
                programmeID: UUID = programme.id,
                season: Int = state.college.recruitingSeason
            ) -> [String: Any] {
                var object = baseline
                var plans = object["redshirtPlans"] as! [String: Any]
                var encodedPlan = plans[playerID.uuidString] as! [String: Any]
                encodedPlan["programmeID"] = programmeID.uuidString
                encodedPlan["season"] = season
                plans.removeValue(forKey: playerID.uuidString)
                plans[key.uuidString] = encodedPlan
                object["redshirtPlans"] = plans
                return object
            }

            let hostileStates = [
                replacingPlan(
                    key: UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF9242")!
                ),
                replacingPlan(
                    programmeID: UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF9243")!
                ),
                replacingPlan(season: state.college.recruitingSeason + 1),
            ]
            for object in hostileStates {
                do {
                    _ = try JSONDecoder().decode(
                        CollegeState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "college state decoded an orphan or stale redshirt plan")
                } catch {
                    expect(true)
                }
            }
        }

        test("the NIL ledger atomically reserves adjusts refunds and reclassifies money") {
            let programmeID = UUID(uuidString: "00000000-0000-4000-8000-000000009230")!
            let prospectID = UUID(uuidString: "00000000-0000-4000-8000-000000009231")!
            var ledger = ProgrammeNILState(
                programmeID: programmeID,
                season: 3,
                annualBudget: 1_000
            )

            expect(ledger.setRecruitingReservation(400, for: prospectID))
            expectEqual(ledger.recruitingReservations[prospectID], 400)
            expectEqual(ledger.remaining, 600)
            expect(ledger.setRecruitingReservation(650, for: prospectID))
            expectEqual(ledger.remaining, 350)
            expect(ledger.setRecruitingReservation(250, for: prospectID))
            expectEqual(ledger.remaining, 750)

            let beforeReclassification = ledger.remaining
            expect(ledger.reclassifyRecruitingReservation(
                prospectID: prospectID,
                playerID: prospectID
            ))
            expectEqual(ledger.recruitingReservations[prospectID], nil)
            expectEqual(ledger.rosterAllocations[prospectID], 250)
            expectEqual(ledger.remaining, beforeReclassification)
            expectEqual(ledger.removeRosterAllocation(for: prospectID), 250)
            expectEqual(ledger.remaining, 1_000)

            expect(ledger.setRecruitingReservation(200, for: prospectID))
            expectEqual(ledger.refundRecruitingReservation(for: prospectID), 200)
            expectEqual(ledger.remaining, 1_000)
        }

        test("the NIL ledger rejects invalid or duplicate-category changes without mutation") {
            let programmeID = UUID(uuidString: "00000000-0000-4000-8000-000000009232")!
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000009233")!
            let prospectID = UUID(uuidString: "00000000-0000-4000-8000-000000009234")!
            var ledger = ProgrammeNILState(
                programmeID: programmeID,
                season: 2,
                annualBudget: 500,
                rosterAllocations: [playerID: 100]
            )

            for invalidAmount in [-1, 501] {
                let before = ledger
                expect(!ledger.setRecruitingReservation(invalidAmount, for: prospectID))
                expectEqual(ledger, before)
            }
            let duplicateBefore = ledger
            expect(!ledger.setRecruitingReservation(100, for: playerID))
            expectEqual(ledger, duplicateBefore)
            expect(!ledger.setPortalReservation(100, for: playerID))
            expectEqual(ledger, duplicateBefore)

            expect(ledger.setPortalReservation(100, for: prospectID))
            let portalBefore = ledger
            expect(!ledger.setRecruitingReservation(100, for: prospectID))
            expectEqual(ledger, portalBefore)
            expect(!ledger.reclassifyRecruitingReservation(
                prospectID: prospectID,
                playerID: playerID
            ))
            expectEqual(ledger, portalBefore)
        }

        test("hostile NIL ledgers cannot decode overcommit or duplicate categories") {
            let programmeID = UUID(uuidString: "00000000-0000-4000-8000-000000009235")!
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000009236")!
            let prospectID = UUID(uuidString: "00000000-0000-4000-8000-000000009237")!
            let valid = ProgrammeNILState(
                programmeID: programmeID,
                season: 4,
                annualBudget: 1_000,
                rosterAllocations: [playerID: 300],
                recruitingReservations: [prospectID: 200]
            )
            let encoded = try JSONEncoder().encode(valid)

            var overcommitted = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            overcommitted["annualBudget"] = 400
            do {
                _ = try JSONDecoder().decode(
                    ProgrammeNILState.self,
                    from: JSONSerialization.data(withJSONObject: overcommitted)
                )
                expect(false, "an overcommitted NIL ledger decoded")
            } catch {
                expect(true)
            }

            var duplicated = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            duplicated["portalReservations"] = duplicated["rosterAllocations"]
            do {
                _ = try JSONDecoder().decode(
                    ProgrammeNILState.self,
                    from: JSONSerialization.data(withJSONObject: duplicated)
                )
                expect(false, "one NIL identity decoded in multiple categories")
            } catch {
                expect(true)
            }
        }

        test("hostile NIL ledgers cannot decode unbounded identity categories") {
            let programmeID = UUID(uuidString: "00000000-0000-4000-8000-000000009238")!
            let encoded = try JSONEncoder().encode(ProgrammeNILState(
                programmeID: programmeID,
                season: 4,
                annualBudget: CollegeRules.maximumNILBudget
            ))
            let baseline = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

            func encodedAllocations(count: Int, offset: Int) throws -> Any {
                let allocations = Dictionary(uniqueKeysWithValues: (0..<count).map { index in
                    let suffix = String(format: "%012X", offset + index)
                    return (
                        UUID(uuidString: "00000000-0000-4000-8000-\(suffix)")!,
                        1
                    )
                })
                return try JSONSerialization.jsonObject(
                    with: JSONEncoder().encode(allocations)
                )
            }

            let hostileCategories = [
                ("rosterAllocations", CollegeRules.rosterLimit + 1, 10_000),
                ("recruitingReservations", CollegeRules.recruitingBoardLimit + 1, 20_000),
                ("portalReservations", CollegeRules.maximumPortalNILReservations + 1, 30_000),
            ]
            for (key, count, offset) in hostileCategories {
                var object = baseline
                object[key] = try encodedAllocations(count: count, offset: offset)
                do {
                    _ = try JSONDecoder().decode(
                        ProgrammeNILState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an unbounded \(key) NIL category decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("root integrity binds each NIL ledger to its programme season and identity stores") {
            let baseline = GameState.bootstrap(seed: 92_031)
            let programmeID = baseline.programmes.ids[0]
            let programme = baseline.programmes[programmeID]!
            let existing = baseline.college.programmes[programmeID]!
            let foreignProspectID = baseline.prospects.ids[0]
            let foreignPlayerID = baseline.players.ids.first {
                !programme.rosterIDs.contains($0)
            }!

            func replacingNIL(_ nilState: ProgrammeNILState) -> GameState {
                var state = baseline
                var programmes = state.college.programmes
                programmes[programmeID] = ProgrammeRecruitingState(
                    programmeID: programmeID,
                    boardIDs: existing.boardIDs,
                    relationships: existing.relationships,
                    scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                    contactPointsRemaining: existing.contactPointsRemaining,
                    nilState: nilState
                )
                state.college = CollegeState(
                    recruitingSeason: state.college.recruitingSeason,
                    portal: state.college.portal,
                    phase: .active,
                    programmes: programmes,
                    prospectRecruitment: state.college.prospectRecruitment,
                    archivedProspects: state.college.archivedProspects
                )
                return state
            }
            let annualBudget = programme.resources.value
                * CollegeRules.nilBudgetPerResourcePoint
            let wrongSeason = replacingNIL(ProgrammeNILState(
                programmeID: programmeID,
                season: baseline.college.recruitingSeason + 1,
                annualBudget: annualBudget
            ))
            let orphanReservation = replacingNIL(ProgrammeNILState(
                programmeID: programmeID,
                season: baseline.college.recruitingSeason,
                annualBudget: annualBudget,
                recruitingReservations: [foreignProspectID: 100]
            ))
            let foreignRosterAllocation = replacingNIL(ProgrammeNILState(
                programmeID: programmeID,
                season: baseline.college.recruitingSeason,
                annualBudget: annualBudget,
                rosterAllocations: [foreignPlayerID: 100]
            ))
            let prematurePortal = replacingNIL(ProgrammeNILState(
                programmeID: programmeID,
                season: baseline.college.recruitingSeason,
                annualBudget: annualBudget,
                portalReservations: [baseline.players.ids[0]: 100]
            ))

            for state in [
                wrongSeason,
                orphanReservation,
                foreignRosterAllocation,
                prematurePortal,
            ] {
                expect(
                    WorldIntegrity.check(state).issues.contains(
                        .invalidProgrammeRecruitingState(programmeID: programmeID)
                    )
                )
            }
        }

        test("bootstrap creates legal programme resources and a normalized annual prospect pool") {
            let state = GameState.bootstrap(seed: 92_001)

            expectEqual(GameState.schemaVersion, 10)
            expectEqual(state.prospects.count, CollegeRules.annualProspectCount)
            expectEqual(state.college.programmes.count, state.programmes.count)
            expectEqual(state.college.prospectRecruitment.count, state.prospects.count)
            expect(state.scouting.observationsByObserver.isEmpty)
            for programme in state.programmes.values {
                guard let recruiting = state.college.programmes[programme.id] else {
                    expect(false, "programme has no college management state")
                    continue
                }
                expectEqual(recruiting.programmeID, programme.id)
                expect(recruiting.boardIDs.isEmpty)
                expect(recruiting.relationships.isEmpty)
                expectEqual(
                    recruiting.scholarshipPlayerIDs.count,
                    CollegeRules.scholarshipLimit
                )
                expectEqual(
                    Set(recruiting.scholarshipPlayerIDs).count,
                    recruiting.scholarshipPlayerIDs.count
                )
                expect(Set(recruiting.scholarshipPlayerIDs).isSubset(of: Set(programme.rosterIDs)))
                expectEqual(
                    recruiting.contactPointsRemaining,
                    CollegeRules.weeklyRecruitingContactPoints
                )
                expectEqual(recruiting.nilState.programmeID, programme.id)
                expectEqual(recruiting.nilState.season, state.college.recruitingSeason)
                expectEqual(
                    recruiting.nilState.annualBudget,
                    programme.resources.value * CollegeRules.nilBudgetPerResourcePoint
                )
                expectEqual(recruiting.nilState.remaining, recruiting.nilState.annualBudget)
                expect(recruiting.nilState.rosterAllocations.isEmpty)
                expect(recruiting.nilState.recruitingReservations.isEmpty)
                expect(recruiting.nilState.portalReservations.isEmpty)
            }
            expect(state.prospects.values.allSatisfy { prospect in
                state.map.city(prospect.originCityID) != nil
                    && CollegeRules.prospectAgeRange.contains(prospect.age)
                    && prospect.priorities.count == RecruitingPitch.allCases.count
                    && state.college.prospectRecruitment[prospect.id]?.phase == .available
            })
        }

        test("annual prospect generation is deterministic and positionally complete") {
            let world = LeagueGenerator.generate(seed: 92_004)
            let first = ProspectPopulationGenerator.generate(
                rootSeed: 92_004,
                season: 0,
                map: world.map
            )
            let second = ProspectPopulationGenerator.generate(
                rootSeed: 92_004,
                season: 0,
                map: world.map
            )

            expectEqual(first.count, CollegeRules.annualProspectCount)
            expectEqual(try JSONEncoder.stable().encode(first), try JSONEncoder.stable().encode(second))
            expectEqual(Set(first.map(\.id)).count, first.count)
            for position in Position.allCases {
                expect(first.contains { $0.position == position }, "prospect pool omits \(position)")
            }
        }

        test("prospect truth stays separate from one observer's estimate") {
            let prospectID = UUID(uuidString: "00000000-0000-4000-8000-000000009201")!
            let cityID = UUID(uuidString: "00000000-0000-4000-8000-000000009202")!
            let observerID = UUID(uuidString: "00000000-0000-4000-8000-000000009203")!
            var truth = Attributes()
            truth[.speed] = Rating(90)
            let prospect = Prospect(
                id: prospectID,
                firstName: "Test",
                lastName: "Prospect",
                position: .wideReceiver,
                age: 18,
                originCityID: cityID,
                attributes: truth,
                potential: Rating(95),
                traits: [],
                priorities: [.proximity: Rating(80)]
            )
            let observation = ProspectObservation(
                prospectID: prospectID,
                estimatedAttributes: [.speed: Rating(70)],
                estimatedPotential: Rating(75),
                confidence: 25,
                lastUpdated: CalendarState(),
                evidenceCount: 1
            )
            let scouting = ScoutingState(observationsByObserver: [
                observerID: [prospectID: observation],
            ])

            expectEqual(prospect.attributes[.speed], Rating(90))
            expectEqual(scouting.observation(observerID: observerID, prospectID: prospectID), observation)
            expectEqual(observation.estimatedAttribute(.speed), Rating(70))
            expect(observation.estimatedAttribute(.speed) != prospect.attributes[.speed])
        }

        test("commitment state distinguishes available, committed, and signed prospects") {
            let prospectID = UUID(uuidString: "00000000-0000-4000-8000-000000009204")!
            let programmeID = UUID(uuidString: "00000000-0000-4000-8000-000000009205")!
            let available = ProspectRecruitmentState(
                prospectID: prospectID,
                phase: .available
            )
            let commitment = RecruitingCommitmentContext(
                committedAt: CalendarState(
                    season: 0,
                    week: CollegeRules.minimumCommitmentWeek
                ),
                winner: RecruitingCommitmentContenderContext(
                    programmeID: programmeID,
                    score: CollegeRules.minimumCommitmentScore,
                    explanation: [],
                    relationshipInterest: CollegeRules.minimumCommitmentScore,
                    nilAllocation: 0,
                    visitScheduled: false
                )
            )
            let committed = ProspectRecruitmentState(
                prospectID: prospectID,
                phase: .committed,
                commitmentHistory: [commitment]
            )
            let signed = ProspectRecruitmentState(
                prospectID: prospectID,
                phase: .signed,
                commitmentHistory: [commitment]
            )

            expectEqual(available.programmeID, nil)
            expectEqual(committed.programmeID, programmeID)
            expectEqual(signed.programmeID, programmeID)
            expect(committed.phase != signed.phase)
        }

        test("recruiting actions reject a cycle that is not active") {
            var state = GameState.bootstrap(seed: 92_017)
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: .closed,
                programmes: state.college.programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects
            )
            do {
                _ = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: state.programmes.ids[0],
                        prospectID: state.prospects.ids[0],
                        action: .addToBoard
                    ),
                    in: state
                )
                expect(false, "a closed recruiting cycle accepted an action")
            } catch let error as RecruitingActionError {
                expectEqual(error, .cycleUnavailable)
            }
        }

        test("persisted recruiting resources reject impossible counters") {
            let programmeID = UUID(uuidString: "00000000-0000-4000-8000-000000009206")!
            let recruiting = ProgrammeRecruitingState(programmeID: programmeID)
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(recruiting)
            ) as! [String: Any]
            object["contactPointsRemaining"] = CollegeRules.weeklyRecruitingContactPoints + 1
            let corrupted = try JSONSerialization.data(withJSONObject: object)

            do {
                _ = try JSONDecoder().decode(ProgrammeRecruitingState.self, from: corrupted)
                expect(false, "out-of-range recruiting resources decoded")
            } catch {
                expect(true)
            }
        }

        test("integrity rejects orphan board and scouting prospect references") {
            var state = GameState.bootstrap(seed: 92_002)
            let programmeID = state.programmes.ids[0]
            let orphanID = UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF9202")!
            let current = state.college.programmes[programmeID]!
            var programmeStates = state.college.programmes
            programmeStates[programmeID] = ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: [orphanID],
                relationships: [
                    orphanID: ProgrammeProspectRelationship(prospectID: orphanID),
                ],
                scholarshipPlayerIDs: current.scholarshipPlayerIDs,
                contactPointsRemaining: current.contactPointsRemaining,
                nilState: current.nilState
            )
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: state.college.phase,
                programmes: programmeStates,
                prospectRecruitment: [:]
            )
            state.scouting = ScoutingState(observationsByObserver: [
                programmeID: [
                    orphanID: ProspectObservation(
                        prospectID: orphanID,
                        estimatedAttributes: [:],
                        estimatedPotential: Rating(60),
                        confidence: 10,
                        lastUpdated: state.calendar,
                        evidenceCount: 1
                    ),
                ],
            ])

            let issues = WorldIntegrity.check(state).issues
            expect(issues.contains { issue in
                if case .missingProspect(prospectID: orphanID, ownerID: programmeID) = issue {
                    return true
                }
                return false
            })
            expect(issues.contains { issue in
                if case .invalidScoutingObservation(
                    observerID: programmeID,
                    prospectID: orphanID
                ) = issue {
                    return true
                }
                return false
            })
        }

        test("provisional rollover replaces departed scholarship IDs without changing the limit") {
            var state = GameState.bootstrap(seed: 92_003)
            let programmeID = state.programmes.ids[0]
            let departedID = state.college.programmes[programmeID]!.scholarshipPlayerIDs[0]
            let replacementID = UUID(uuidString: "00000000-0000-4000-8000-000000009207")!
            state.programmes.update(programmeID) {
                $0.rosterIDs.removeAll { $0 == departedID }
                $0.rosterIDs.append(replacementID)
            }

            state.college.reconcileScholarships(with: state.programmes)

            let scholarships = state.college.programmes[programmeID]!.scholarshipPlayerIDs
            expectEqual(scholarships.count, CollegeRules.scholarshipLimit)
            expect(!scholarships.contains(departedID))
            expect(scholarships.contains(replacementID))
        }

        test("the scheduler processes queued scouting for only the entitled observer") {
            var state = GameState.bootstrap(seed: 92_005)
            let observerID = state.programmes.ids[0]
            let otherObserverID = state.programmes.ids[1]
            let prospectID = state.prospects.ids[0]
            expect(state.scouting.queueEvaluation(
                observerID: observerID,
                prospectID: prospectID,
                effort: 20
            ))

            let first = try WorldScheduler.advanceWeek(state)
            let firstObservation = first.state.scouting.observation(
                observerID: observerID,
                prospectID: prospectID
            )
            expectEqual(
                first.stepRecords.first { $0.step == .scoutingKnowledge }?.status,
                .executed
            )
            expect(firstObservation != nil)
            expect((firstObservation?.confidence ?? 0) > 0)
            expect((firstObservation?.confidence ?? 100) <= CollegeRules.maximumProspectKnowledgeConfidence)
            expect(!first.state.scouting.pendingEvaluations.contains {
                $0.observerID == observerID && $0.prospectID == prospectID
            })
            expectEqual(
                first.state.scouting.observation(
                    observerID: otherObserverID,
                    prospectID: prospectID
                ),
                nil
            )
            expect(first.emittedEvents.contains { event in
                if case .prospectEvaluated(
                    observerID: observerID,
                    prospectID: prospectID,
                    confidence: _
                ) = event.payload { return true }
                return false
            })

            state = first.state
            expect(state.scouting.queueEvaluation(
                observerID: observerID,
                prospectID: prospectID,
                effort: 20
            ))
            let second = try WorldScheduler.advanceWeek(state)
            let secondObservation = second.state.scouting.observation(
                observerID: observerID,
                prospectID: prospectID
            )
            expect((secondObservation?.confidence ?? 0) > (firstObservation?.confidence ?? 0))
            expect((secondObservation?.evidenceCount ?? 0) > (firstObservation?.evidenceCount ?? 0))
            expectEqual(second.state.prospects[prospectID], state.prospects[prospectID])
        }

        test("recruiting fit exposes real prestige and proximity components") {
            let state = GameState.bootstrap(seed: 92_006)
            let prospectID = state.prospects.ids[0]
            let prospectCity = state.map.city(state.prospects[prospectID]!.originCityID)!
            let programmes = state.programmes.values
            let highPrestige = programmes.max { $0.prestige.value < $1.prestige.value }!
            let lowPrestige = programmes.min { $0.prestige.value < $1.prestige.value }!
            let nearest = programmes.min { lhs, rhs in
                let lhsCity = state.map.city(state.identities[lhs.id]!.homeCityID)!
                let rhsCity = state.map.city(state.identities[rhs.id]!.homeCityID)!
                return prospectCity.squaredDistance(to: lhsCity)
                    < prospectCity.squaredDistance(to: rhsCity)
            }!
            let farthest = programmes.max { lhs, rhs in
                let lhsCity = state.map.city(state.identities[lhs.id]!.homeCityID)!
                let rhsCity = state.map.city(state.identities[rhs.id]!.homeCityID)!
                return prospectCity.squaredDistance(to: lhsCity)
                    < prospectCity.squaredDistance(to: rhsCity)
            }!

            let high = RecruitingFitSystem.evaluate(
                programmeID: highPrestige.id,
                prospectID: prospectID,
                in: state
            )!
            let low = RecruitingFitSystem.evaluate(
                programmeID: lowPrestige.id,
                prospectID: prospectID,
                in: state
            )!
            let near = RecruitingFitSystem.evaluate(
                programmeID: nearest.id,
                prospectID: prospectID,
                in: state
            )!
            let far = RecruitingFitSystem.evaluate(
                programmeID: farthest.id,
                prospectID: prospectID,
                in: state
            )!

            expect(high.value(for: .prestige) >= low.value(for: .prestige))
            expect(near.value(for: .proximity) >= far.value(for: .proximity))
            expectEqual(Set(high.components.map(\.reason)).count, high.components.count)
            expectEqual(high.total, high.components.reduce(0) { $0 + $1.value })
        }

        test("unscouted recruiting fit cannot read hidden prospect ability") {
            var state = GameState.bootstrap(seed: 92_012)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let original = state.prospects[prospectID]!
            let before = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )
            var alteredAttributes = original.attributes
            alteredAttributes[.schemeFit] = Rating(
                original.attributes[.schemeFit].value < 70 ? 99 : 40
            )
            state.prospects.insert(Prospect(
                id: original.id,
                firstName: original.firstName,
                lastName: original.lastName,
                position: original.position,
                age: original.age,
                originCityID: original.originCityID,
                attributes: alteredAttributes,
                potential: Rating(original.potential.value == 99 ? 40 : 99),
                traits: original.traits,
                priorities: original.priorities
            ))

            let after = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )
            expectEqual(after, before)
        }

        test("AI recruiting is deterministic and conserves legal weekly resources") {
            let state = GameState.bootstrap(seed: 92_013)
            let first = try CollegeRecruitingAISystem.process(in: state)
            let second = try CollegeRecruitingAISystem.process(in: state)

            expectEqual(first, second)
            expect(first.decisions.count <= state.programmes.count * (
                CollegeRules.aiWeeklyBoardGrowth
                    + CollegeRules.aiWeeklyInvestmentActionLimit
            ))
            expect(first.decisions.allSatisfy {
                $0.score == $0.explanation.total
            })
            expectEqual(first.eventPayloads.count, first.decisions.count)
            expect(first.decisions.indices.allSatisfy { index in
                let decision = first.decisions[index]
                guard case let .recruitingInteraction(
                    programmeID,
                    prospectID,
                    kind,
                    _,
                    _
                ) = first.eventPayloads[index],
                      programmeID == decision.request.programmeID,
                      prospectID == decision.request.prospectID else { return false }
                switch (decision.request.action, kind) {
                case (.addToBoard, .addToBoard),
                     (.contact, .contact),
                     (.evaluate, .evaluate),
                     (.scheduleVisit, .visit),
                     (.offerScholarship, .scholarshipOffer),
                     (.setNILAllocation, .nilAllocation),
                     (.withdraw, .withdraw):
                    return true
                default:
                    return false
                }
            })
            var resultingState = state
            resultingState.college = first.college
            resultingState.scouting = first.scouting
            let perProspectInvestmentLimit = max(
                1,
                CollegeRules.aiWeeklyInvestmentActionLimit
                    / CollegeRules.aiWeeklyBoardGrowth
            )
            for programmeID in state.programmes.ids {
                let recruiting = first.college.programmes[programmeID]!
                let programmeDecisions = first.decisions.filter {
                    $0.request.programmeID == programmeID
                }
                let targetDecisions = programmeDecisions.filter {
                    if case .addToBoard = $0.request.action { return true }
                    return false
                }
                let investmentDecisions = programmeDecisions.filter {
                    if case .addToBoard = $0.request.action { return false }
                    if case .withdraw = $0.request.action { return false }
                    return true
                }
                let investmentsByProspect = Dictionary(
                    grouping: investmentDecisions,
                    by: { $0.request.prospectID }
                )
                let evaluationCount = investmentDecisions.filter {
                    if case .evaluate = $0.request.action { return true }
                    return false
                }.count
                let pendingEvaluationCount = first.scouting.pendingEvaluations.filter {
                    $0.observerID == programmeID
                }.count
                let contactSpend = first.eventPayloads.reduce(into: 0) { total, payload in
                    guard case let .recruitingInteraction(
                        eventProgrammeID,
                        _,
                        action,
                        resourceCost,
                        _
                    ) = payload,
                          eventProgrammeID == programmeID else { return }
                    switch action {
                    case .contact, .evaluate, .visit:
                        total += resourceCost
                    case .addToBoard, .scholarshipOffer, .nilAllocation, .withdraw:
                        break
                    }
                }
                let capacity = CollegeCommitmentCapacitySystem.capacity(
                    programmeID: programmeID,
                    in: resultingState,
                    college: resultingState.college
                )!

                expectEqual(recruiting.boardIDs.count, targetDecisions.count)
                expect(targetDecisions.count <= CollegeRules.aiWeeklyBoardGrowth)
                expect(investmentDecisions.count <= CollegeRules.aiWeeklyInvestmentActionLimit)
                expect(investmentsByProspect.values.allSatisfy {
                    $0.count <= perProspectInvestmentLimit
                })
                expectEqual(evaluationCount, pendingEvaluationCount)
                expectEqual(
                    recruiting.contactPointsRemaining,
                    state.college.programmes[programmeID]!.contactPointsRemaining
                        - contactSpend
                )
                expectEqual(
                    recruiting.nilState.remaining
                        + recruiting.nilState.recruitingReservations.values.reduce(0, +),
                    state.college.programmes[programmeID]!.nilState.remaining
                )
                expect(recruiting.boardIDs.allSatisfy { prospectID in
                    guard recruiting.relationships[prospectID] != nil,
                          resultingState.college.prospectRecruitment[prospectID]?.phase
                            == .available,
                          let position = resultingState.prospects[prospectID]?.position
                    else { return false }
                    return capacity.canReserve(position: position)
                })
                expect(programmeDecisions.allSatisfy {
                    !$0.explanation.components.isEmpty
                })
                expectEqual(
                    recruiting.nilState.remaining
                        + recruiting.nilState.rosterAllocations.values.reduce(0, +)
                        + recruiting.nilState.recruitingReservations.values.reduce(0, +)
                        + recruiting.nilState.portalReservations.values.reduce(0, +),
                    state.programmes[programmeID]!.resources.value
                        * CollegeRules.nilBudgetPerResourcePoint
                )
            }
        }

        test("AI board growth follows the calendar ramp and projected class target") {
            var state = GameState.bootstrap(seed: 92_021)
            state.calendar = CalendarState(season: state.calendar.season, week: 2)
            let expectedByProgramme = Dictionary(uniqueKeysWithValues:
                state.programmes.ids.map { programmeID in
                    let classTarget = CollegeCommitmentCapacitySystem.capacity(
                        programmeID: programmeID,
                        in: state,
                        college: state.college
                    )!.maximumReservations
                    return (
                        programmeID,
                        min(
                            CollegeRules.recruitingBoardLimit,
                            state.calendar.week * CollegeRules.aiWeeklyBoardGrowth,
                            classTarget + CollegeRules.aiBoardDepthBeyondClassTarget
                        )
                    )
                }
            )

            let transition = try CollegeRecruitingAISystem.process(in: state)

            for programmeID in state.programmes.ids {
                expectEqual(
                    transition.college.programmes[programmeID]?.boardIDs.count,
                    expectedByProgramme[programmeID]
                )
            }
        }

        test("AI closes a lost commitment pursuit and refunds its exact NIL allocation") {
            var state = GameState.bootstrap(seed: 92_022)
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            let prospectID = state.prospects.ids[0]
            let losingProgrammeID = state.programmes.ids[0]
            let winningProgrammeID = state.programmes.ids[1]
            let losingBudget = state.college.programmes[losingProgrammeID]!.nilState.remaining

            for action in [
                RecruitingAction.addToBoard,
                .setNILAllocation(amount: 700),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: losingProgrammeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            for action in [
                RecruitingAction.addToBoard,
                .contact(points: 60),
                .scheduleVisit,
                .offerScholarship,
                .setNILAllocation(amount: 500),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: winningProgrammeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            let market = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
            expectEqual(market.commitments.first?.programmeID, winningProgrammeID)
            state.college = market.college

            let transition = try CollegeRecruitingAISystem.process(in: state)

            let losing = transition.college.programmes[losingProgrammeID]!
            let winning = transition.college.programmes[winningProgrammeID]!
            expect(!losing.boardIDs.contains(prospectID))
            expectEqual(losing.relationships[prospectID], nil)
            expectEqual(
                losing.nilState.remaining
                    + losing.nilState.rosterAllocations.values.reduce(0, +)
                    + losing.nilState.recruitingReservations.values.reduce(0, +)
                    + losing.nilState.portalReservations.values.reduce(0, +),
                losingBudget
            )
            expectEqual(losing.nilState.recruitingReservations[prospectID], nil)
            expect(winning.boardIDs.contains(prospectID))
            expect(winning.relationships[prospectID] != nil)
            expect(transition.decisions.contains { decision in
                guard decision.request.programmeID == losingProgrammeID,
                      decision.request.prospectID == prospectID else { return false }
                if case .withdraw = decision.request.action { return true }
                return false
            })
            expect(transition.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: losingProgrammeID,
                    prospectID: prospectID,
                    action: .withdraw,
                    resourceCost: -700,
                    interestAfter: 0
                ) = payload { return true }
                return false
            })
        }

        test("withdrawal permits only available or another programme's commitment") {
            var state = GameState.bootstrap(seed: 92_024)
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            let prospectID = state.prospects.ids[0]
            let losingProgrammeID = state.programmes.ids[0]
            let winningProgrammeID = state.programmes.ids[1]
            for programmeID in [losingProgrammeID, winningProgrammeID] {
                for action in [
                    RecruitingAction.addToBoard,
                    .contact(points: 60),
                    .offerScholarship,
                ] {
                    let transition = try CollegeRecruitingSystem.apply(
                        RecruitingActionRequest(
                            programmeID: programmeID,
                            prospectID: prospectID,
                            action: action
                        ),
                        in: state
                    )
                    state.college = transition.college
                    state.scouting = transition.scouting
                }
            }
            let market = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
            guard let winnerID = market.commitments.first?.programmeID,
                  let commitment = market.college.prospectRecruitment[prospectID]
            else {
                expect(false, "fixture produced no commitment")
                return
            }
            let loserID = winnerID == losingProgrammeID
                ? winningProgrammeID
                : losingProgrammeID
            state.college = market.college

            let losingWithdrawal = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: loserID,
                    prospectID: prospectID,
                    action: .withdraw
                ),
                in: state
            )
            expectEqual(losingWithdrawal.college.programmes[loserID]?
                .relationships[prospectID], nil)

            for phase in [ProspectRecruitmentPhase.committed, .signed, .released] {
                var recruitment = state.college.prospectRecruitment
                recruitment[prospectID] = ProspectRecruitmentState(
                    prospectID: prospectID,
                    phase: phase,
                    commitmentHistory: commitment.commitmentHistory,
                    releaseReason: phase == .released ? .scholarshipCapacityChanged : nil
                )
                state.college = CollegeState(
                    recruitingSeason: state.college.recruitingSeason,
                    portal: state.college.portal,
                    phase: state.college.phase,
                    programmes: state.college.programmes,
                    prospectRecruitment: recruitment,
                    archivedProspects: state.college.archivedProspects
                )
                do {
                    _ = try CollegeRecruitingSystem.apply(
                        RecruitingActionRequest(
                            programmeID: winnerID,
                            prospectID: prospectID,
                            action: .withdraw
                        ),
                        in: state
                    )
                    expect(false, "the winner withdrew a \(phase.rawValue) prospect")
                } catch let error as RecruitingActionError {
                    expectEqual(error, .prospectUnavailable)
                }
            }
        }

        test("NIL allocation decreases and withdrawal conserve the annual budget") {
            var state = GameState.bootstrap(seed: 92_025)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let annualBudget = state.programmes[programmeID]!.resources.value
                * CollegeRules.nilBudgetPerResourcePoint

            func apply(_ action: RecruitingAction) throws -> RecruitingActionTransition {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
                return transition
            }
            func conserved() -> Bool {
                let recruiting = state.college.programmes[programmeID]!
                return recruiting.nilState.remaining
                    + recruiting.nilState.rosterAllocations.values.reduce(0, +)
                    + recruiting.nilState.recruitingReservations.values.reduce(0, +)
                    + recruiting.nilState.portalReservations.values.reduce(0, +)
                    == annualBudget
            }

            _ = try apply(.addToBoard)
            let increased = try apply(.setNILAllocation(amount: 500))
            expect(conserved())
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .recruitingReservations[prospectID],
                500
            )
            expect(increased.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .nilAllocation,
                    resourceCost: 500,
                    interestAfter: _
                ) = payload { return true }
                return false
            })

            let decreased = try apply(.setNILAllocation(amount: 200))
            expect(conserved())
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .recruitingReservations[prospectID],
                200
            )
            expect(decreased.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .nilAllocation,
                    resourceCost: -300,
                    interestAfter: _
                ) = payload { return true }
                return false
            })

            let withdrawn = try apply(.withdraw)
            expect(conserved())
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .recruitingReservations[prospectID],
                nil
            )
            expect(withdrawn.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .withdraw,
                    resourceCost: -200,
                    interestAfter: 0
                ) = payload { return true }
                return false
            })
        }

        test("AI culls available pursuits when projected commitment capacity is filled") {
            var state = GameState.bootstrap(seed: 92_023)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let initialBudget = state.college.programmes[programmeID]!.nilState.remaining
            for action in [
                RecruitingAction.addToBoard,
                .setNILAllocation(amount: 600),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            for playerID in state.programmes[programmeID]!.rosterIDs {
                state.players.update(playerID) {
                    $0.eligibility = Eligibility()
                }
            }
            expectEqual(
                CollegeCommitmentCapacitySystem.capacity(
                    programmeID: programmeID,
                    in: state,
                    college: state.college
                )?.openReservations,
                0
            )

            let transition = try CollegeRecruitingAISystem.process(in: state)

            let recruiting = transition.college.programmes[programmeID]!
            expect(recruiting.boardIDs.isEmpty)
            expect(recruiting.relationships.isEmpty)
            expectEqual(recruiting.nilState.remaining, initialBudget)
            expectEqual(
                transition.decisions.filter { $0.request.programmeID == programmeID }.count,
                1
            )
            if let decision = transition.decisions.first(where: {
                $0.request.programmeID == programmeID
            }) {
                if case .withdraw = decision.request.action {
                    expect(true)
                } else {
                    expect(false, "capacity cull did not use the shared withdrawal action")
                }
            }
        }

        test("the weekly scheduler activates the college market and AI steps") {
            let state = GameState.bootstrap(seed: 92_014)
            let transition = try WorldScheduler.advanceWeek(state)

            expectEqual(
                transition.stepRecords.first { $0.step == .marketInteractions }?.status,
                .executed
            )
            expectEqual(
                transition.stepRecords.first { $0.step == .aiDecisions }?.status,
                .executed
            )
            expect(transition.state.college.programmes.values.allSatisfy {
                $0.boardIDs.count == CollegeRules.aiWeeklyBoardGrowth
                    && $0.contactPointsRemaining == CollegeRules.weeklyRecruitingContactPoints
            })
            let pendingEvaluations = transition.state.scouting.pendingEvaluations
            let pendingKeys = pendingEvaluations.map {
                "\($0.observerID.uuidString)|\($0.prospectID.uuidString)"
            }
            let evaluationEventKeys = transition.emittedEvents.compactMap {
                event -> String? in
                guard case let .recruitingInteraction(
                    programmeID,
                    prospectID,
                    .evaluate,
                    resourceCost,
                    _
                ) = event.payload else { return nil }
                expectEqual(resourceCost, CollegeRules.aiEvaluationContactPoints)
                return "\(programmeID.uuidString)|\(prospectID.uuidString)"
            }
            expect(!pendingEvaluations.isEmpty)
            expect(pendingEvaluations.count
                <= state.programmes.count * CollegeRules.aiWeeklyBoardGrowth)
            expectEqual(Set(pendingKeys).count, pendingKeys.count)
            expect(pendingEvaluations.allSatisfy { assignment in
                assignment.effort == CollegeRules.aiEvaluationContactPoints
                    && transition.state.college.programmes[assignment.observerID]?
                        .boardIDs.contains(assignment.prospectID) == true
                    && transition.state.college.programmes[assignment.observerID]?
                        .relationships[assignment.prospectID] != nil
            })
            expectEqual(Set(evaluationEventKeys), Set(pendingKeys))
            expectEqual(Set(transition.emittedEvents.map(\.id)).count,
                        transition.emittedEvents.count)
        }

        test("the recruiting market creates one deterministic commitment and remembers the race") {
            var state = GameState.bootstrap(seed: 92_015)
            let prospectID = state.prospects.ids[0]
            let contenders = Array(state.programmes.ids.prefix(2))
            for programmeID in contenders {
                for action in [
                    RecruitingAction.addToBoard,
                    .contact(points: 60),
                    .scheduleVisit,
                    .offerScholarship,
                    .setNILAllocation(amount: 500),
                ] {
                    let transition = try CollegeRecruitingSystem.apply(
                        RecruitingActionRequest(
                            programmeID: programmeID,
                            prospectID: prospectID,
                            action: action
                        ),
                        in: state
                    )
                    state.college = transition.college
                    state.scouting = transition.scouting
                }
            }

            let first = CollegeRecruitingMarketSystem.process(
                at: CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek),
                in: state
            )
            let second = CollegeRecruitingMarketSystem.process(
                at: CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek),
                in: state
            )

            expectEqual(first, second)
            expectEqual(first.commitments.count, 1)
            let commitment = first.commitments[0]
            expectEqual(commitment.prospectID, prospectID)
            expect(contenders.contains(commitment.programmeID))
            expect(contenders.contains(commitment.runnerUpProgrammeID!))
            expect(commitment.runnerUpProgrammeID != commitment.programmeID)
            expectEqual(
                first.college.prospectRecruitment[prospectID]?.phase,
                .committed
            )
            expectEqual(
                first.college.prospectRecruitment[prospectID]?.programmeID,
                commitment.programmeID
            )
            expect(first.eventPayloads.contains { payload in
                if case .prospectCommitted(
                    prospectID: prospectID,
                    context: commitment.context
                ) = payload { return true }
                return false
            })

            state.college = first.college
            do {
                _ = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: commitment.programmeID,
                        prospectID: prospectID,
                        action: .contact(points: 1)
                    ),
                    in: state
                )
                expect(false, "a committed prospect accepted another recruiting action")
            } catch let error as RecruitingActionError {
                expectEqual(error, .prospectUnavailable)
            }
        }

        test("signing preserves prospect identity and creates authoritative player state") {
            var state = GameState.bootstrap(seed: 92_016)
            let prospectID = state.prospects.ids[0]
            let programmeID = state.programmes.ids[0]
            for action in [
                RecruitingAction.addToBoard,
                .contact(points: 60),
                .scheduleVisit,
                .offerScholarship,
                .setNILAllocation(amount: 500),
            ] {
                let actionTransition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = actionTransition.college
                state.scouting = actionTransition.scouting
            }
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            state.league.week = state.calendar.week
            let market = CollegeRecruitingMarketSystem.process(
                at: state.calendar,
                in: state
            )
            expectEqual(market.commitments.first?.programmeID, programmeID)
            state.college = market.college

            let departingID = state.programmes[programmeID]!.rosterIDs[0]
            state.programmes.update(programmeID) {
                $0.rosterIDs.removeAll { $0 == departingID }
                $0.scholarshipCount -= 1
            }
            state.college.reconcileScholarships(with: state.programmes)
            expectEqual(state.programmes[programmeID]?.rosterIDs.count,
                        CollegeRules.rosterLimit - 1)
            expectEqual(state.college.programmes[programmeID]?.scholarshipPlayerIDs.count,
                        CollegeRules.scholarshipLimit - 1)
            expectEqual(state.players[prospectID], nil)
            let signing = try CollegeSigningSystem.signCommitted(in: state)
            let prospect = state.prospects[prospectID]!
            let player = signing.players[prospectID]

            expectEqual(signing.signings.count, 1)
            expectEqual(signing.signings.first?.prospectID, prospectID)
            expectEqual(signing.signings.first?.programmeID, programmeID)
            expectEqual(player?.id, prospect.id)
            expectEqual(player?.firstName, prospect.firstName)
            expectEqual(player?.lastName, prospect.lastName)
            expectEqual(player?.attributes, prospect.attributes)
            expectEqual(player?.potential, prospect.potential)
            expectEqual(player?.eligibility, Eligibility())
            expectEqual(player?.contract, nil)
            expect(signing.programmes[programmeID]!.rosterIDs.contains(prospectID))
            expect(signing.college.programmes[programmeID]!
                .scholarshipPlayerIDs.contains(prospectID))
            expectEqual(
                signing.college.prospectRecruitment[prospectID]?.phase,
                .signed
            )
            expectEqual(
                signing.college.programmes[programmeID]?.nilState
                    .recruitingReservations[prospectID],
                nil
            )
            expectEqual(
                signing.college.programmes[programmeID]?.nilState
                    .rosterAllocations[prospectID],
                500
            )
            expect(signing.people.playerLifecycle[prospectID] != nil)
            expect(signing.people.playerCareers[prospectID] != nil)
            expectEqual(
                signing.people.playerCareers[prospectID]?.recruitingOrigin?.programmeID,
                programmeID
            )
            expectEqual(
                signing.people.playerCareers[prospectID]?.recruitingOrigin?.signingSeason,
                state.college.recruitingSeason
            )
            expectEqual(
                signing.people.playerCareers[prospectID]?.recruitingOrigin?.originCityID,
                prospect.originCityID
            )
            expectEqual(
                signing.people.playerCareers[prospectID]?.recruitingOrigin?.finalNILAllocation,
                500
            )
            expect(signing.eventPayloads.contains { payload in
                if case .playerJoined(
                    playerID: prospectID,
                    organisationID: programmeID,
                    source: .recruitedScholarship
                ) = payload { return true }
                return false
            })
        }

        test("departure cleanup and rollover retain only authoritative roster NIL allocations") {
            var state = GameState.bootstrap(seed: 92_030)
            let programmeID = state.programmes.ids[0]
            let programme = state.programmes[programmeID]!
            let retainedPlayerID = programme.rosterIDs[0]
            let departingPlayerID = programme.rosterIDs[1]
            let prospectID = state.prospects.ids[0]
            let existing = state.college.programmes[programmeID]!
            var programmeStates = state.college.programmes
            programmeStates[programmeID] = ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: existing.boardIDs,
                relationships: existing.relationships,
                scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                contactPointsRemaining: existing.contactPointsRemaining,
                nilState: ProgrammeNILState(
                    programmeID: programmeID,
                    season: state.college.recruitingSeason,
                    annualBudget: programme.resources.value
                        * CollegeRules.nilBudgetPerResourcePoint,
                    rosterAllocations: [
                        retainedPlayerID: 300,
                        departingPlayerID: 200,
                    ]
                )
            )
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: .active,
                programmes: programmeStates,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects
            )

            state.programmes.update(programmeID) {
                $0.rosterIDs.removeAll { $0 == departingPlayerID }
                $0.scholarshipCount -= 1
            }
            state.college.reconcileScholarships(with: state.programmes)
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .rosterAllocations[departingPlayerID],
                nil
            )
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .rosterAllocations[retainedPlayerID],
                300
            )

            for action in [
                RecruitingAction.addToBoard,
                .contact(points: 60),
                .scheduleVisit,
                .offerScholarship,
                .setNILAllocation(amount: 500),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            state.league.week = state.calendar.week
            let market = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
            expectEqual(market.commitments.first?.programmeID, programmeID)
            state.college = market.college

            let cycle = try CollegeCycleSystem.closeAndOpen(nextSeason: 1, in: state)
            let nextNIL = cycle.college.programmes[programmeID]!.nilState
            expectEqual(nextNIL.season, 1)
            expectEqual(nextNIL.rosterAllocations[retainedPlayerID], 300)
            expectEqual(nextNIL.rosterAllocations[prospectID], 500)
            expectEqual(nextNIL.rosterAllocations[departingPlayerID], nil)
            expect(nextNIL.recruitingReservations.isEmpty)
            expect(nextNIL.portalReservations.isEmpty)
            expectEqual(nextNIL.remaining, nextNIL.annualBudget - 800)
        }

        test("shared recruiting actions enforce contact cost and preserve prospect truth") {
            var state = GameState.bootstrap(seed: 92_007)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let truth = state.prospects[prospectID]!
            let added = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .addToBoard
                ),
                in: state
            )
            state.college = added.college
            state.scouting = added.scouting
            let initial = state.college.programmes[programmeID]!.relationships[prospectID]!
            expect(state.college.programmes[programmeID]!.boardIDs.contains(prospectID))
            expect(!initial.lastExplanation.isEmpty)

            let contacted = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .contact(points: 20)
                ),
                in: state
            )
            let after = contacted.college.programmes[programmeID]!.relationships[prospectID]!
            expectEqual(
                contacted.college.programmes[programmeID]!.contactPointsRemaining,
                CollegeRules.weeklyRecruitingContactPoints - 20
            )
            expect(after.interest > initial.interest)
            expectEqual(after.contactPointsInvested, 20)
            expectEqual(contacted.prospects[prospectID], truth)
            expect(contacted.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .contact,
                    resourceCost: 20,
                    interestAfter: _
                ) = payload { return true }
                return false
            })

            do {
                _ = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: .contact(points: CollegeRules.weeklyRecruitingContactPoints + 1)
                    ),
                    in: state
                )
                expect(false, "recruiting contact overspend succeeded")
            } catch let error as RecruitingActionError {
                expectEqual(error, .insufficientContactPoints)
            }
        }

        test("evaluation uses the same weekly budget and queues observer-specific work") {
            var state = GameState.bootstrap(seed: 92_008)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let added = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .addToBoard
                ),
                in: state
            )
            state.college = added.college
            state.scouting = added.scouting

            let evaluated = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .evaluate(points: 15)
                ),
                in: state
            )

            expectEqual(
                evaluated.college.programmes[programmeID]!.contactPointsRemaining,
                CollegeRules.weeklyRecruitingContactPoints - 15
            )
            expect(evaluated.scouting.pendingEvaluations.contains {
                $0.observerID == programmeID && $0.prospectID == prospectID && $0.effort == 15
            })
        }

        test("recruiting intent appends events without inventing a week transition") {
            let state = GameState.bootstrap(seed: 92_009)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let request = RecruitingActionRequest(
                programmeID: programmeID,
                prospectID: prospectID,
                action: .addToBoard
            )

            let resolved = try IntentResolver.resolve(.recruiting(request), in: state)

            expectEqual(resolved.state.calendar, state.calendar)
            expectEqual(resolved.state.history.totalCount, state.history.totalCount + 1)
            expect(resolved.state.college.programmes[programmeID]!.boardIDs.contains(prospectID))
            switch resolved.result {
            case let .recruitingUpdated(result):
                expectEqual(result.request, request)
                expectEqual(result.emittedEvents.count, 1)
                expectEqual(result.explanation.prospectID, prospectID)
            case .weekAdvanced:
                expect(false, "recruiting intent fabricated a week transition")
            case .tacticalUpdated:
                expect(false, "recruiting intent fabricated a tactical transition")
            case .careerUpdated:
                expect(false, "recruiting intent fabricated a career transition")
            case .proManagementUpdated:
                expect(false, "recruiting intent fabricated a professional-management transition")
            case .proMarketUpdated:
                expect(false, "recruiting intent fabricated a professional-market transition")
            }
        }

        test("visits offers and NIL create distinct costs and consequences") {
            var state = GameState.bootstrap(seed: 92_010)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            func apply(_ action: RecruitingAction) throws -> RecruitingActionTransition {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
                return transition
            }

            _ = try apply(.addToBoard)
            let before = state.college.programmes[programmeID]!.relationships[prospectID]!.interest
            _ = try apply(.scheduleVisit)
            let afterVisit = state.college.programmes[programmeID]!.relationships[prospectID]!
            expect(afterVisit.visitScheduled)
            expect(afterVisit.interest > before)
            expectEqual(
                state.college.programmes[programmeID]!.contactPointsRemaining,
                CollegeRules.weeklyRecruitingContactPoints - CollegeRules.visitContactCost
            )

            _ = try apply(.offerScholarship)
            let afterOffer = state.college.programmes[programmeID]!.relationships[prospectID]!
            expect(afterOffer.scholarshipOffered)
            expect(afterOffer.interest > afterVisit.interest)

            let nilBefore = state.college.programmes[programmeID]!.nilState.remaining
            let scoreBeforeNIL = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )!
            let nilTransition = try apply(.setNILAllocation(amount: 500))
            let afterNIL = state.college.programmes[programmeID]!.relationships[prospectID]!
            expectEqual(
                state.college.programmes[programmeID]!.nilState
                    .recruitingReservations[prospectID],
                500
            )
            expectEqual(
                state.college.programmes[programmeID]!.nilState.remaining,
                nilBefore - 500
            )
            expectEqual(afterNIL.interest, afterOffer.interest)
            expectEqual(
                nilTransition.explanation.nilAllocationAdjustment,
                500 / CollegeRules.nilInterestPointsPerUnit
            )
            expectEqual(
                nilTransition.explanation.total,
                scoreBeforeNIL.total
                    + nilTransition.explanation.value(for: .nilOpportunity)
                    - scoreBeforeNIL.value(for: .nilOpportunity)
                    + nilTransition.explanation.nilAllocationAdjustment
                    - scoreBeforeNIL.nilAllocationAdjustment
            )
            expect(nilTransition.explanation.total > scoreBeforeNIL.total)

            _ = try apply(.withdraw)
            expect(!state.college.programmes[programmeID]!.boardIDs.contains(prospectID))
            expectEqual(state.college.programmes[programmeID]!.nilState.remaining, nilBefore)
        }

        test("two renewals retain exactly the former prospects referenced by hot history") {
            var state = GameState.bootstrap(seed: 92_018)
            let seasonZeroIDs = Set(state.prospects.ids)
            let seasonZeroProspectID = state.prospects.ids[0]
            let initialPlayerIDs = Set(state.players.ids)
            var history = DomainEventLedger(retentionLimit: 2)
            expect(history.append(recruitingHistoryEvent(
                in: state,
                prospectID: seasonZeroProspectID,
                sequence: 0
            )))
            state.history = history

            state = applyingCollegeCycle(
                try CollegeCycleSystem.closeAndOpen(nextSeason: 1, in: state),
                to: state
            )
            let seasonOneIDs = Set(state.prospects.ids)
            let seasonOneProspectID = state.prospects.ids[0]
            expectEqual(state.college.recruitingSeason, 1)
            expectEqual(state.prospects.count, CollegeRules.annualProspectCount)
            expect(seasonZeroIDs.isDisjoint(with: seasonOneIDs))
            expectEqual(
                state.college.archivedProspects[seasonZeroProspectID]?.recruitingSeason,
                0
            )

            expect(state.history.append(recruitingHistoryEvent(
                in: state,
                prospectID: seasonOneProspectID,
                sequence: 1
            )))
            state = applyingCollegeCycle(
                try CollegeCycleSystem.closeAndOpen(nextSeason: 2, in: state),
                to: state
            )
            let seasonTwoIDs = Set(state.prospects.ids)
            expectEqual(state.college.recruitingSeason, 2)
            expectEqual(state.prospects.count, CollegeRules.annualProspectCount)
            expect(seasonZeroIDs.isDisjoint(with: seasonTwoIDs))
            expect(seasonOneIDs.isDisjoint(with: seasonTwoIDs))
            expectEqual(
                Set(state.college.archivedProspects.keys),
                Set([seasonZeroProspectID, seasonOneProspectID])
            )
            expectEqual(
                state.college.archivedProspects[seasonZeroProspectID]?.recruitingSeason,
                0
            )
            expectEqual(
                state.college.archivedProspects[seasonOneProspectID]?.recruitingSeason,
                1
            )
            expectEqual(Set(state.college.prospectRecruitment.keys), seasonTwoIDs)
            expect(state.college.prospectRecruitment.values.allSatisfy {
                $0.phase == .available && $0.programmeID == nil
            })
            expect(state.college.programmes.values.allSatisfy {
                $0.boardIDs.isEmpty && $0.relationships.isEmpty
            })
            expect(state.scouting.observationsByObserver.isEmpty)
            expect(state.scouting.pendingEvaluations.isEmpty)
            expect(seasonTwoIDs.isDisjoint(with: initialPlayerIDs))
            expect(seasonTwoIDs.isDisjoint(with: Set(state.college.archivedProspects.keys)))

            let neutralSequence = state.history.nextSequence
            expect(state.history.append(DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: state.league.seed,
                    sequence: neutralSequence
                ),
                sequence: neutralSequence,
                occurredAt: state.calendar,
                payload: .integrityChecked(issueCount: 0)
            )))
            let activeProspectID = state.prospects.ids[0]
            state = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: state.programmes.ids[0],
                    prospectID: activeProspectID,
                    action: .addToBoard
                )),
                in: state
            ).state

            expect(state.college.archivedProspects.isEmpty,
                   "former prospect identities outlived their last hot event")
        }

        test("a week transition prunes prospect tombstones evicted by scheduler events") {
            var state = GameState.bootstrap(seed: 92_019)
            let oldProspectID = state.prospects.ids[0]
            var history = DomainEventLedger(retentionLimit: 1)
            expect(history.append(recruitingHistoryEvent(
                in: state,
                prospectID: oldProspectID,
                sequence: 0
            )))
            state.history = history
            state = applyingCollegeCycle(
                try CollegeCycleSystem.closeAndOpen(nextSeason: 1, in: state),
                to: state
            )
            expect(state.college.archivedProspects[oldProspectID] != nil)

            state = try WorldScheduler.advanceWeek(state).state

            expect(state.college.archivedProspects.isEmpty,
                   "scheduler event eviction left a stale prospect identity")
        }

        test("integrity rejects prospect identities duplicated across lifecycle stores") {
            var activePlayerCollision = GameState.bootstrap(seed: 92_020)
            let activeProspect = activePlayerCollision.prospects.values[0]
            let duplicatePlayer = Player(
                id: activeProspect.id,
                firstName: activeProspect.firstName,
                lastName: activeProspect.lastName,
                position: activeProspect.position,
                age: activeProspect.age,
                attributes: activeProspect.attributes,
                potential: activeProspect.potential,
                eligibility: Eligibility()
            )
            activePlayerCollision.players.insert(duplicatePlayer)
            activePlayerCollision.people.insert(player: duplicatePlayer)
            expect(WorldIntegrity.check(activePlayerCollision).issues.contains { issue in
                if case .invalidProspect(prospectID: activeProspect.id) = issue { return true }
                return false
            }, "an active prospect also existed as a player")

            var archivedPlayerCollision = GameState.bootstrap(seed: 92_021)
            let formerProspect = archivedPlayerCollision.prospects.values[0]
            _ = archivedPlayerCollision.prospects.remove(formerProspect.id)
            let remainingRecruitment = archivedPlayerCollision.college.prospectRecruitment.filter {
                $0.key != formerProspect.id
            }
            let archivedIdentity = ArchivedProspectIdentity(
                prospect: formerProspect,
                recruitingSeason: 0
            )
            archivedPlayerCollision.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(targetSeason: 1),
                phase: .active,
                programmes: archivedPlayerCollision.college.programmes,
                prospectRecruitment: remainingRecruitment,
                archivedProspects: [formerProspect.id: archivedIdentity]
            )
            let formerPlayer = Player(
                id: formerProspect.id,
                firstName: formerProspect.firstName,
                lastName: formerProspect.lastName,
                position: formerProspect.position,
                age: formerProspect.age,
                attributes: formerProspect.attributes,
                potential: formerProspect.potential,
                eligibility: Eligibility()
            )
            archivedPlayerCollision.players.insert(formerPlayer)
            archivedPlayerCollision.people.insert(player: formerPlayer)
            var retainedHistory = DomainEventLedger(retentionLimit: 1)
            expect(retainedHistory.append(recruitingHistoryEvent(
                in: archivedPlayerCollision,
                prospectID: formerProspect.id,
                sequence: 0
            )))
            archivedPlayerCollision.history = retainedHistory
            expect(WorldIntegrity.check(archivedPlayerCollision).issues.contains { issue in
                if case .invalidProspect(prospectID: formerProspect.id) = issue { return true }
                return false
            }, "an archived prospect also existed as a player")

            var staleArchive = archivedPlayerCollision
            _ = staleArchive.players.remove(formerProspect.id)
            staleArchive.people = PeopleState.bootstrap(
                players: staleArchive.players.values,
                staff: staleArchive.staff.values,
                staffEmployerIDs: Dictionary(uniqueKeysWithValues:
                    staleArchive.programmes.values.flatMap { programme in
                        programme.staffIDs.map { ($0, programme.id) }
                    } + staleArchive.proTeams.values.flatMap { team in
                        team.staffIDs.map { ($0, team.id) }
                    }
                ),
                season: staleArchive.calendar.season
            )
            staleArchive.history = DomainEventLedger(retentionLimit: 1)
            expect(WorldIntegrity.check(staleArchive).issues.contains { issue in
                if case .invalidProspect(prospectID: formerProspect.id) = issue { return true }
                return false
            }, "an unreferenced prospect tombstone survived integrity")
        }

        test("advancing a week restores the shared contact budget") {
            var state = GameState.bootstrap(seed: 92_011)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            state = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .addToBoard
                )),
                in: state
            ).state
            state = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .contact(points: 25)
                )),
                in: state
            ).state
            expectEqual(
                state.college.programmes[programmeID]!.contactPointsRemaining,
                CollegeRules.weeklyRecruitingContactPoints - 25
            )

            state = try WorldScheduler.advanceWeek(state).state

            expectEqual(
                state.college.programmes[programmeID]!.contactPointsRemaining,
                CollegeRules.weeklyRecruitingContactPoints
            )
        }
    }
}
