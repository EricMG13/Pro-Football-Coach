import Foundation
import FootballSimCore

func runCareerArcTests() {
    suite("M5 career arc") {
        test("career arc state is bounded and save-stable") {
            let arc = CareerArcState()
            let restored = try JSONDecoder.stable().decode(
                CareerArcState.self,
                from: JSONEncoder.stable().encode(arc)
            )
            expectEqual(restored, arc)
            expectEqual(arc.status, .seeking)
            expectEqual(Set(arc.stakeholderSupport.keys), Set(CareerStakeholder.allCases))
            expect(arc.stakeholderSupport.values.allSatisfy(CareerArcState.supportRange.contains))
        }

        test("career arc records support, firing, and durable job history") {
            let organisationID = UUID(uuidString: "00000000-0000-4000-8000-000000000A01")!
            let startedAt = CalendarState(season: 0, week: 1)
            let endedAt = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            var arc = CareerArcState()

            expect(arc.establishCollegeJob(organisationID: organisationID, at: startedAt))
            expect(arc.applySupport(deltas: Dictionary(uniqueKeysWithValues: 
                CareerStakeholder.allCases.map { ($0, -100) }
            )))
            expect(arc.markFired(at: endedAt))
            expectEqual(arc.status, .fired)
            expect(arc.currentJob == nil)
            expectEqual(arc.jobHistory.count, 1)
            expectEqual(arc.jobHistory[0].reason, .fired)
            expectEqual(arc.jobHistory[0].endedAt, endedAt)
        }

        test("career opportunities support promotion and resignation through the intent boundary") {
            let source = GameState.bootstrap(seed: 99_105)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let proTeam = controlled.proTeams.values[0]
            var arc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: controlled.calendar
                ),
                status: .employed
            )
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A05")!,
                organisationID: proTeam.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: proTeam.prestige,
                rationale: .staffRecommendation
            )
            expect(arc.addOpportunity(opportunity))
            expect(arc.acceptOpportunity(id: opportunity.id, at: controlled.calendar))
            expectEqual(arc.currentJob?.organisationID, proTeam.id)
            expectEqual(arc.currentJob?.tier, .professional)
            expectEqual(arc.jobHistory.last?.reason, .promoted)

            var promoting = controlled
            promoting.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: controlled.calendar
                ),
                opportunities: [opportunity],
                status: .employed
            )
            let promoted = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: promoting.calendar,
                    action: .acceptOpportunity(opportunityID: opportunity.id)
                )),
                in: promoting
            )
            expect(promoted.state.career.college == nil)
            expectEqual(promoted.state.careerArc.currentJob?.tier, .professional)

            var resigning = controlled
            resigning.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: controlled.calendar
                ),
                status: .employed
            )
            let resolved = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: resigning.calendar,
                    action: .resign
                )),
                in: resigning
            )
            expect(resolved.state.career.college == nil,
                   "resignation left the coach controlling the former programme")
            expectEqual(resolved.state.careerArc.status, .seeking)
            expect(resolved.state.careerArc.currentJob == nil)
            if case .careerUpdated = resolved.result {
                expect(true)
            } else {
                expect(false, "career intent did not return a career result")
            }
        }

        testAsync("the career actor routes resignation without exposing root state") {
            let source = GameState.bootstrap(seed: 99_106)
            let programmeID = source.programmes.ids[0]
            let proTeam = source.proTeams.values[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            controlled.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: controlled.calendar
                ),
                opportunities: [CareerOpportunity(
                    id: UUID(uuidString: "00000000-0000-4000-8000-000000000A07")!,
                    organisationID: proTeam.id,
                    tier: .professional,
                    offeredAt: controlled.calendar,
                    expiresAt: controlled.calendar.advancedWeek(),
                    prestige: proTeam.prestige,
                    rationale: .staffRecommendation
                )],
                status: .employed
            )
            controlled.pending = PendingQueues()
            let delegateID = controlled.programmes[programmeID]!.staffIDs.first {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }!
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: delegateID),
                    in: &controlled
                ))
            }
            let session = try CareerSession(state: controlled)
            let receipt = try await session.resolve(.career(.resign))
            expectEqual(receipt.projection.calendar, controlled.calendar)
            expectEqual(receipt.projection.tier, nil)
            expectEqual(receipt.projection.programme, nil)
            if case .intent(.careerUpdated) = receipt.result {
                expect(true)
            } else {
                expect(false, "career actor did not return a career result")
            }

            let restoredState = try SaveEnvelope.decode(GameState.self, from: await session.saveData())
            let restored = try CareerSession(state: restoredState)
            expectEqual((await restored.projection()).programme, nil)
            let accepted = try await restored.resolve(.career(.acceptOpportunity(
                opportunityID: UUID(uuidString: "00000000-0000-4000-8000-000000000A07")!
            )))
            expectEqual(accepted.projection.tier, .professional)
            expectEqual(accepted.projection.programme?.id, proTeam.id)
        }

        test("season end establishes the controlled job and updates stakeholders") {
            let source = GameState.bootstrap(seed: 99_101)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            var seasonEnd = controlled
            seasonEnd.calendar = CalendarState(
                season: controlled.calendar.season,
                week: SharedRules.inSeasonWeeks
            )
            seasonEnd.league.week = SharedRules.inSeasonWeeks
            var arc = seasonEnd.careerArc

            CareerArcSystem.evaluateSeasonEnd(
                after: seasonEnd.calendar,
                in: seasonEnd,
                arc: &arc
            )

            expectEqual(arc.currentJob?.organisationID, programmeID)
            expectEqual(arc.currentJob?.tier, .college)
            expectEqual(arc.status, .employed)
            expect(arc.stakeholderSupport.values.allSatisfy(CareerArcState.supportRange.contains))
        }

        test("weekly results move stakeholder support without reading hidden player truth") {
            let source = GameState.bootstrap(seed: 99_103)
            guard let game = source.competition.currentSchedule.games.first(where: {
                $0.tier == .college && $0.week == source.calendar.week
            }) else {
                expect(false, "bootstrap did not produce a week-one college game")
                return
            }
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: game.homeID,
                in: source
            ).state
            var state = controlled
            let summary = AbstractGameSimulator.play(game, in: state)
            expect(state.competition.currentSchedule.replace(ScheduledGame(
                id: game.id,
                season: game.season,
                tier: game.tier,
                week: game.week,
                stage: game.stage,
                homeID: game.homeID,
                awayID: game.awayID,
                result: summary
            )))
            var arc = state.careerArc
            CareerArcSystem.evaluateWeek(after: state.calendar, in: state, arc: &arc)
            expectEqual(arc.currentJob?.organisationID, game.homeID)
            expect(arc.stakeholderSupport.values.allSatisfy(CareerArcState.supportRange.contains))
        }

        test("the scheduler carries the controlled career arc through rollover") {
            let source = GameState.bootstrap(seed: 99_104)
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            let programmeID = controlled.career.college!.programmeID
            let delegateID = controlled.programmes[programmeID]!.staffIDs.first {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }!
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: delegateID),
                    in: &controlled
                ))
            }
            var state = controlled
            for _ in 0..<SharedRules.inSeasonWeeks {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar, CalendarState(season: 1, week: 1))
            expect(state.careerArc.status == .employed || state.careerArc.status == .fired)
            expect(WorldIntegrity.check(state).isValid)
        }

        test("root integrity rejects a career job owned by an unknown organisation") {
            let source = GameState.bootstrap(seed: 99_102)
            let unknownID = UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFA1")!
            let arc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: unknownID,
                    tier: .college,
                    startedAt: source.calendar
                ),
                status: .employed
            )
            var invalid = source
            invalid.careerArc = arc
            expect(
                WorldIntegrity.check(invalid).issues.contains(.invalidCareerArc),
                "unknown career employer passed root integrity"
            )
        }
        test("promotion carries the head-coaching seat into the pro tier") {
            let source = GameState.bootstrap(seed: 99_120)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            guard let coachID = controlled.career.coachID else {
                expect(false, "career start left no coach")
                return
            }
            let proTeam = controlled.proTeams.values[0]
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A20")!,
                organisationID: proTeam.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: proTeam.prestige,
                rationale: .sustainedCollegeSuccess
            )
            var promoting = controlled
            promoting.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: controlled.calendar
                ),
                opportunities: [opportunity],
                status: .employed
            )
            let promoted = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: promoting.calendar,
                    action: .acceptOpportunity(opportunityID: opportunity.id)
                )),
                in: promoting
            ).state

            // The seat moves. Holding both at once is the duplication this asserts against.
            expect(
                promoted.proTeams[proTeam.id]?.staffIDs.contains(coachID) == true,
                "promotion did not seat the coach at the pro team"
            )
            expect(
                promoted.programmes[programmeID]?.staffIDs.contains(coachID) == false,
                "promotion left the coach holding the college seat as well"
            )
            expectEqual(
                promoted.proTeams[proTeam.id]?.staffIDs.filter {
                    promoted.staff[$0]?.role == .headCoach
                }.count,
                1,
                "pro team ended the promotion with more than one head coach"
            )
            // The coaching tree and the history archive both read staffCareers, so the pro seat
            // has to be recorded there or the promotion vanishes from every history surface.
            let assignments = promoted.people.staffCareers[coachID]?.assignments ?? []
            expectEqual(assignments.last?.organisationID, proTeam.id)
            expectEqual(assignments.last?.role, .headCoach)
            expectEqual(assignments.last?.season, promoted.calendar.season)
            expect(
                assignments.contains { $0.organisationID == programmeID },
                "promotion erased the college seat from the career record"
            )
            expect(WorldIntegrity.check(promoted).isValid, "promoted world failed integrity")
        }
        test("resignation vacates the college seat and keeps the career record") {
            let source = GameState.bootstrap(seed: 99_121)
            let programmeID = source.programmes.ids[0]
            var resigning = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            guard let coachID = resigning.career.coachID else {
                expect(false, "career start left no coach")
                return
            }
            resigning.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: resigning.calendar
                ),
                status: .employed
            )
            let resigned = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: resigning.calendar,
                    action: .resign
                )),
                in: resigning
            ).state

            expect(
                resigned.programmes[programmeID]?.staffIDs.contains(coachID) == false,
                "resignation left the coach on the programme's staff"
            )
            expectEqual(
                resigned.programmes[programmeID]?.staffIDs.filter {
                    resigned.staff[$0]?.role == .headCoach
                }.count,
                1,
                "resignation left the programme without exactly one head coach"
            )
            // The coach survives separation as a person: the career record is what the coaching
            // tree and the history archive read, and a resignation is not an erasure.
            expect(
                resigned.staff[coachID] != nil,
                "resignation deleted the coach"
            )
            expect(
                resigned.people.staffCareers[coachID]?.assignments.contains {
                    $0.organisationID == programmeID && $0.role == .headCoach
                } == true,
                "resignation erased the college seat from the career record"
            )
            expectEqual(resigned.career.coachID, coachID)
            expect(WorldIntegrity.check(resigned).isValid, "resigned world failed integrity")

            // Separation has to leave a world the same coach can be hired into again, at a
            // different programme, without the stale seat trailing behind them.
            let nextProgrammeID = resigned.programmes.ids[1]
            let rehired = try CareerControlSystem.startCollegeCareer(
                at: nextProgrammeID,
                in: resigned
            ).state
            expectEqual(rehired.career.coachID, coachID)
            expect(
                rehired.programmes[nextProgrammeID]?.staffIDs.contains(coachID) == true,
                "the rehired coach was not seated at the new programme"
            )
            expect(
                rehired.programmes[programmeID]?.staffIDs.contains(coachID) == false,
                "the rehired coach still held the former programme's seat"
            )
            expectEqual(
                rehired.people.staffCareers[coachID]?.assignments.last?.organisationID,
                nextProgrammeID
            )
            expect(
                rehired.people.staffCareers[coachID]?.assignments.contains {
                    $0.organisationID == programmeID
                } == true,
                "rehiring erased the first programme from the career record"
            )
            expect(WorldIntegrity.check(rehired).isValid, "rehired world failed integrity")
        }
    }
}
