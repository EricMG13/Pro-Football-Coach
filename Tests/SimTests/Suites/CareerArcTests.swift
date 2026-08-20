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

        test("a save from before stakeholderLastMovement existed decodes to an empty record") {
            let arc = CareerArcState()
            let encoded = try JSONEncoder.stable().encode(arc)
            guard var object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
            else {
                expect(false, "CareerArcState must encode to a JSON object")
                return
            }
            expect(object.removeValue(forKey: "stakeholderLastMovement") != nil,
                   "the fixture must actually carry the key this test removes, or it proves nothing")
            let legacyData = try JSONSerialization.data(withJSONObject: object)
            let restored = try JSONDecoder.stable().decode(CareerArcState.self, from: legacyData)
            expect(restored.stakeholderLastMovement.isEmpty,
                   "a save missing the key must decode to an empty record, not fail or crash")
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
            // applySupport records the delta it actually applied per stakeholder, not just the
            // resulting support level -- that record is what lets a surface say why support
            // moved, and it must reflect exactly what was passed, not the clamped support value.
            expectEqual(arc.stakeholderLastMovement, Dictionary(uniqueKeysWithValues:
                CareerStakeholder.allCases.map { ($0, -100) }
            ))
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
        test("the promotion survives a save round trip with its job history intact") {
            let source = GameState.bootstrap(seed: 99_122)
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
            let startedAt = controlled.calendar
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A21")!,
                organisationID: proTeam.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: proTeam.prestige,
                rationale: .rivalryWin
            )
            var promoting = controlled
            promoting.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: startedAt
                ),
                stakeholderSupport: Dictionary(uniqueKeysWithValues: [
                    (CareerStakeholder.administration, 81),
                    (CareerStakeholder.boosters, 74),
                    (CareerStakeholder.fanbase, 90),
                    (CareerStakeholder.lockerRoom, 67),
                ]),
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

            // The college job becomes history rather than disappearing, and it says why it ended.
            expectEqual(promoted.careerArc.jobHistory.count, 1)
            expectEqual(promoted.careerArc.jobHistory.last?.job.organisationID, programmeID)
            expectEqual(promoted.careerArc.jobHistory.last?.job.tier, .college)
            expectEqual(promoted.careerArc.jobHistory.last?.job.startedAt, startedAt)
            expectEqual(promoted.careerArc.jobHistory.last?.reason, .promoted)
            // The accepted opportunity is consumed, not left standing to be taken twice.
            expect(
                promoted.careerArc.opportunities.isEmpty,
                "the accepted opportunity was left on the board"
            )

            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(promoted)
            )
            expectEqual(restored.careerArc, promoted.careerArc)
            expectEqual(restored.career.coachID, coachID)
            expectEqual(
                restored.people.staffCareers[coachID]?.assignments,
                promoted.people.staffCareers[coachID]?.assignments
            )
            expect(
                restored.proTeams[proTeam.id]?.staffIDs.contains(coachID) == true,
                "the reloaded save lost the professional seat"
            )
            // The coaching tree is deliberately not Codable and is rebuilt after load, so the
            // reloaded world has to rebuild the same tree rather than a smaller one.
            expectEqual(
                CoachingTreeReadModel.build(from: restored),
                CoachingTreeReadModel.build(from: promoted)
            )
            expect(WorldIntegrity.check(restored).isValid, "reloaded promoted world failed integrity")
        }
        test("the coaching tree attributes the professional seat to the promoted coach") {
            let source = GameState.bootstrap(seed: 99_123)
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
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A22")!,
                organisationID: proTeam.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: proTeam.prestige,
                rationale: .staffRecommendation
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
            var promoted = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: promoting.calendar,
                    action: .acceptOpportunity(opportunityID: opportunity.id)
                )),
                in: promoting
            ).state

            // One assistant on the new staff goes on to a head-coaching job of their own. The tree
            // should name the promoted coach as who they came up under, not the coach the
            // promotion displaced.
            guard let assistantID = promoted.proTeams[proTeam.id]?.staffIDs.first(where: {
                promoted.staff[$0]?.role == .offensiveCoordinator
            }), let assistant = promoted.staff[assistantID] else {
                expect(false, "the professional team had no coordinator to promote")
                return
            }
            promoted.people.recordStaffAssignment(
                StaffCareerAssignment(
                    season: promoted.calendar.season + 1,
                    organisationID: programmeID,
                    role: .headCoach
                ),
                for: assistant
            )

            let tree = CoachingTreeReadModel.build(from: promoted)
            let branch = tree.branches.first { $0.mentorID == coachID }
            expect(
                branch?.disciples.contains { $0.staffID == assistantID } == true,
                "the coaching tree did not place the assistant under the promoted coach"
            )
        }
        test("promotion moves the coaching group and leaves the rest of the world alone") {
            let source = GameState.bootstrap(seed: 99_124)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            guard let coachID = controlled.career.coachID else {
                expect(false, "career start left no coach")
                return
            }
            // Delegating first, so the promotion is walked by a coach who had staff relationships
            // to leave behind rather than a coach who ran everything alone.
            guard let delegateID = controlled.programmes[programmeID]?.staffIDs.first(where: {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }) else {
                expect(false, "the programme had no coordinator to delegate to")
                return
            }
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: delegateID),
                    in: &controlled
                ))
            }

            let proTeam = controlled.proTeams.values[0]
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A23")!,
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

            // World history is not the coach's to carry or to lose.
            expectEqual(promoted.rivalries, controlled.rivalries)
            expectEqual(promoted.competition.archives, controlled.competition.archives)

            // Every organisation the coach did not touch keeps exactly the staff it had.
            for otherID in promoted.programmes.ids where otherID != programmeID {
                expectEqual(
                    promoted.programmes[otherID]?.staffIDs,
                    controlled.programmes[otherID]?.staffIDs,
                    "an untouched programme's staff moved during the promotion"
                )
            }
            for otherID in promoted.proTeams.ids where otherID != proTeam.id {
                expectEqual(
                    promoted.proTeams[otherID]?.staffIDs,
                    controlled.proTeams[otherID]?.staffIDs,
                    "an untouched professional team's staff moved during the promotion"
                )
            }

            // The group that moves is the head coach and the four coordinators (`02` section 9),
            // so the two organisations that do change, change by exactly five people each and
            // neither changes size. A drop and a duplicate both fail this.
            let moving = Set([coachID] + StaffRole.coordinators.compactMap { role in
                controlled.programmes[programmeID]?.staffIDs.first {
                    controlled.staff[$0]?.role == role
                }
            })
            expectEqual(moving.count, StaffRole.coordinators.count + 1)

            let programmeBefore = Set(controlled.programmes[programmeID]?.staffIDs ?? [])
            let programmeAfter = Set(promoted.programmes[programmeID]?.staffIDs ?? [])
            expectEqual(programmeBefore.subtracting(programmeAfter), moving)
            expectEqual(programmeAfter.subtracting(programmeBefore).count, moving.count)
            expectEqual(programmeAfter.count, programmeBefore.count)

            let teamBefore = Set(controlled.proTeams[proTeam.id]?.staffIDs ?? [])
            let teamAfter = Set(promoted.proTeams[proTeam.id]?.staffIDs ?? [])
            expectEqual(teamAfter.subtracting(teamBefore), moving)
            expectEqual(teamBefore.subtracting(teamAfter).count, moving.count)
            expectEqual(teamAfter.count, teamBefore.count)
            // The coordinator the coach had delegated to is one of the people who carries the
            // scheme, so the relationship survives the tier change even though the delegation
            // itself does not.
            expect(
                teamAfter.contains(delegateID),
                "the delegated coordinator did not follow the coach"
            )

            // Nobody is deleted: a displaced coach is a person the history still names.
            expect(
                Set(controlled.staff.ids).isSubset(of: Set(promoted.staff.ids)),
                "the promotion deleted a staff member"
            )
            expectEqual(promoted.staff.ids.count, controlled.staff.ids.count + moving.count)
            expectEqual(
                Set(promoted.people.staffCareers.keys),
                Set(promoted.staff.ids),
                "a staff member ended the promotion without a career record"
            )
        }
        test("a career of four moves keeps one unbroken job history") {
            let source = GameState.bootstrap(seed: 99_125)
            let firstProgrammeID = source.programmes.ids[0]
            let secondProgrammeID = source.programmes.ids[1]
            var state = try CareerControlSystem.startCollegeCareer(
                at: firstProgrammeID,
                in: source
            ).state
            state.pending = PendingQueues()
            guard let coachID = state.career.coachID else {
                expect(false, "career start left no coach")
                return
            }
            let firstTeamID = state.proTeams.ids[0]
            let secondTeamID = state.proTeams.ids[1]
            let staffCountAtStart = state.staff.ids.count

            func offer(_ teamID: UUID, _ suffix: String) -> CareerOpportunity {
                CareerOpportunity(
                    id: UUID(uuidString: "00000000-0000-4000-8000-0000000000\(suffix)")!,
                    organisationID: teamID,
                    tier: .professional,
                    offeredAt: state.calendar,
                    expiresAt: state.calendar.advancedWeek(),
                    prestige: state.proTeams[teamID]?.prestige ?? Rating(50),
                    rationale: .sustainedCollegeSuccess
                )
            }
            func apply(_ action: CareerArcAction) throws {
                state = try IntentResolver.resolve(
                    .career(CareerArcRequest(calendar: state.calendar, action: action)),
                    in: state
                ).state
                expect(WorldIntegrity.check(state).isValid, "a career move failed integrity")
            }

            // 1. Promoted out of the first college job.
            var arc = state.careerArc
            _ = arc.establishCollegeJob(organisationID: firstProgrammeID, at: state.calendar)
            let firstOffer = offer(firstTeamID, "B1")
            expect(arc.addOpportunity(firstOffer))
            state.careerArc = arc
            try apply(.acceptOpportunity(opportunityID: firstOffer.id))

            // 2. Walks away from the professional job.
            try apply(.resign)
            expectEqual(state.careerArc.status, .seeking)

            // 3. Hired back into the college game, at a different programme.
            state = try CareerControlSystem.startCollegeCareer(
                at: secondProgrammeID,
                in: state
            ).state
            state.pending = PendingQueues()
            arc = state.careerArc
            _ = arc.establishCollegeJob(organisationID: secondProgrammeID, at: state.calendar)
            let secondOffer = offer(secondTeamID, "B2")
            expect(arc.addOpportunity(secondOffer))
            state.careerArc = arc

            // 4. Promoted again, to a different professional team.
            try apply(.acceptOpportunity(opportunityID: secondOffer.id))

            // The spine: four moves, three closed jobs, in order, each saying why it ended.
            expectEqual(state.careerArc.jobHistory.count, 3)
            expectEqual(
                state.careerArc.jobHistory.map(\.job.organisationID),
                [firstProgrammeID, firstTeamID, secondProgrammeID]
            )
            expectEqual(
                state.careerArc.jobHistory.map(\.job.tier),
                [.college, .professional, .college]
            )
            expectEqual(
                state.careerArc.jobHistory.map(\.reason),
                [.promoted, .resigned, .promoted]
            )
            expectEqual(state.careerArc.currentJob?.organisationID, secondTeamID)
            expectEqual(state.careerArc.currentJob?.tier, .professional)

            // The same career, told by the other authority. Both tiers, in the order they happened,
            // with no seat recorded twice and none missing.
            expectEqual(
                state.people.staffCareers[coachID]?.assignments.map(\.organisationID),
                [firstProgrammeID, firstTeamID, secondProgrammeID, secondTeamID]
            )
            expect(
                state.people.staffCareers[coachID]?.assignments.allSatisfy {
                    $0.role == .headCoach
                } == true,
                "the coach was recorded in a seat that was not the top job"
            )

            // The coach holds exactly one chair in the whole world, and it is the current one.
            let seats = state.programmes.ids.filter {
                state.programmes[$0]?.staffIDs.contains(coachID) == true
            } + state.proTeams.ids.filter {
                state.proTeams[$0]?.staffIDs.contains(coachID) == true
            }
            expectEqual(seats, [secondTeamID])
            // One successor per vacated seat and not one more. Two promotions leave a whole
            // coaching group behind, at five seats each; the resignation in between leaves only
            // the coach's, because staff follow a promotion and not a separation.
            let promotionSeats = 2 * (StaffRole.coordinators.count + 1)
            expectEqual(state.staff.ids.count, staffCountAtStart + promotionSeats + 1)
        }
        test("the coordinators follow the coach into the professional tier") {
            let source = GameState.bootstrap(seed: 99_126)
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
            let followers = StaffRole.coordinators.compactMap { role in
                controlled.programmes[programmeID]?.staffIDs.first {
                    controlled.staff[$0]?.role == role
                }
            }
            let positionCoaches = (controlled.programmes[programmeID]?.staffIDs ?? []).filter {
                controlled.staff[$0]?.role == .positionCoach
            }
            expectEqual(followers.count, StaffRole.coordinators.count)
            expect(!positionCoaches.isEmpty, "the programme had no position coaches")

            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A26")!,
                organisationID: proTeam.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: proTeam.prestige,
                rationale: .staffRecommendation
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

            // Scheme identity travels with the people who hold it.
            for followerID in followers {
                expect(
                    promoted.proTeams[proTeam.id]?.staffIDs.contains(followerID) == true,
                    "a coordinator did not follow the coach to the professional team"
                )
                expect(
                    promoted.programmes[programmeID]?.staffIDs.contains(followerID) == false,
                    "a coordinator held both the college and the professional seat"
                )
                expectEqual(
                    promoted.people.staffCareers[followerID]?.assignments.last?.organisationID,
                    proTeam.id,
                    "a coordinator's move was not recorded in their career"
                )
            }
            // Position coaches are not part of the subset that carries.
            for coachID in positionCoaches {
                expect(
                    promoted.programmes[programmeID]?.staffIDs.contains(coachID) == true,
                    "a position coach was taken along by the promotion"
                )
            }

            // Both organisations still field one coach per role: five seats vacated, five filled.
            for organisationStaff in [
                promoted.programmes[programmeID]?.staffIDs ?? [],
                promoted.proTeams[proTeam.id]?.staffIDs ?? [],
            ] {
                for role in [.headCoach] + StaffRole.coordinators {
                    expectEqual(
                        organisationStaff.filter { promoted.staff[$0]?.role == role }.count,
                        1,
                        "an organisation ended the promotion without exactly one \(role.rawValue)"
                    )
                }
            }
            expect(
                promoted.proTeams[proTeam.id]?.staffIDs.contains(coachID) == true,
                "the coach did not take the professional seat"
            )
            expect(WorldIntegrity.check(promoted).isValid, "promoted world failed integrity")
        }
        test("being fired vacates the seat the same way resigning does") {
            let source = GameState.bootstrap(seed: 99_127)
            let programmeID = source.programmes.ids[0]
            var state = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            state.pending = PendingQueues()
            guard let coachID = state.career.coachID else {
                expect(false, "career start left no coach")
                return
            }
            // Fully delegated, so the scheduler may abstract the controlled fixture instead of
            // demanding it be played through a match session.
            guard let delegateID = state.programmes[programmeID]?.staffIDs.first(where: {
                state.staff[$0]?.role == .offensiveCoordinator
            }) else {
                expect(false, "the programme had no coordinator to delegate to")
                return
            }
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: delegateID),
                    in: &state
                ))
            }

            // Support on the floor, so the first week that resolves ends the job.
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: state.calendar
                ),
                stakeholderSupport: Dictionary(
                    uniqueKeysWithValues: CareerStakeholder.allCases.map { ($0, 0) }
                ),
                status: .employed
            )

            var weeks = 0
            while state.careerArc.status != .fired, weeks < SharedRules.inSeasonWeeks {
                state = try WorldScheduler.advanceWeek(state).state
                state.pending = PendingQueues()
                weeks += 1
            }
            expectEqual(state.careerArc.status, .fired)
            expect(state.career.college == nil, "firing left the coach controlling the programme")

            // A fired coach is off the staff, exactly like one who resigned. The programme is not
            // left short a head coach either.
            expect(
                state.programmes[programmeID]?.staffIDs.contains(coachID) == false,
                "firing left the coach on the programme's staff"
            )
            expectEqual(
                state.programmes[programmeID]?.staffIDs.filter {
                    state.staff[$0]?.role == .headCoach
                }.count,
                1,
                "firing left the programme without exactly one head coach"
            )
            // Firing is a separation, so nobody follows them out.
            for role in StaffRole.coordinators {
                expectEqual(
                    state.programmes[programmeID]?.staffIDs.filter {
                        state.staff[$0]?.role == role
                    }.count,
                    1,
                    "firing disturbed a coordinator seat"
                )
            }
            // The career record keeps the job that just ended.
            expect(
                state.people.staffCareers[coachID]?.assignments.contains {
                    $0.organisationID == programmeID && $0.role == .headCoach
                } == true,
                "firing erased the job from the career record"
            )
            expectEqual(state.career.coachID, coachID)
            expectEqual(state.careerArc.jobHistory.last?.reason, .fired)
            expect(WorldIntegrity.check(state).isValid, "fired world failed integrity")
        }
        // Three transitions end a coach's job — promotion, resignation, firing — and all three
        // shipped having cleared the career control without vacating the chair in the world. Three
        // hand-written walks cover the three that exist today, which is the coverage boundary
        // becoming the quality boundary: a fourth would be wrong on the day it was added.
        //
        // So the class is enumerated by construction instead. Every `clearCollege()` in the engine
        // has to be answered by a world-side move within a few lines, and a new one that is not
        // fails here rather than in a save six months from now.
        test("every career separation in the engine also vacates the seat") {
            let window = 6
            var unanswered: [String] = []
            var callSites = 0
            for file in swiftFiles(under: "Sources") {
                let lines = codeLines(of: file.text)
                for (number, line) in lines.enumerated() where line.contains("clearCollege()") {
                    // The declaration itself, not a call.
                    guard !line.contains("func clearCollege") else { continue }
                    callSites += 1
                    let following = lines[number..<min(number + window, lines.count)]
                        .joined(separator: "\n")
                    guard !following.contains("vacateCurrentSeat"),
                          !following.contains("seatProfessionalPromotion") else { continue }
                    unanswered.append("\(file.path):\(number + 1)")
                }
            }
            // A scan that reaches nothing also reports nothing wrong. The three transitions are
            // four call sites — two firing, one resignation, one promotion — so anything less than
            // that means the walk missed the tree, not that the tree is clean.
            expect(
                callSites >= 4,
                "the separation scan found only \(callSites) call sites, so it is not reaching Sources"
            )
            expect(
                unanswered.isEmpty,
                "career control is cleared without vacating the seat at: \(unanswered.joined(separator: ", "))"
            )
        }

        // A scan that has never failed is not known to be a scan. ContractTests states the rule and
        // plants an offender in a synthetic file for each of its scans; this does the same.
        test("the separation scan catches a clearCollege that vacates nothing") {
            let offender = """
            func fireTheCoach(in state: inout GameState) {
                state.career.clearCollege()
                state.pending = PendingQueues()
            }
            """
            let lines = codeLines(of: offender)
            var caught = false
            for (number, line) in lines.enumerated() where line.contains("clearCollege()") {
                let following = lines[number..<min(number + 6, lines.count)].joined(separator: "\n")
                if !following.contains("vacateCurrentSeat"),
                   !following.contains("seatProfessionalPromotion") {
                    caught = true
                }
            }
            expect(caught, "the separation scan did not catch a planted offender")
        }
        test("a coordinator the promotion displaced is not the new coach's disciple") {
            let source = GameState.bootstrap(seed: 99_128)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            guard let coachID = controlled.career.coachID else {
                expect(false, "no coach")
                return
            }
            let proTeam = controlled.proTeams.values[0]
            let displacedCoordinators = (controlled.proTeams[proTeam.id]?.staffIDs ?? []).filter {
                controlled.staff[$0].map { StaffRole.coordinators.contains($0.role) } ?? false
            }
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000A28")!,
                organisationID: proTeam.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: proTeam.prestige,
                rationale: .staffRecommendation
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
            var promoted = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: promoting.calendar,
                    action: .acceptOpportunity(opportunityID: opportunity.id)
                )),
                in: promoting
            ).state

            // One of the coordinators the promotion threw out later becomes a head coach.
            guard let victimID = displacedCoordinators.first,
                  let victim = promoted.staff[victimID] else {
                expect(false, "no displaced coordinator")
                return
            }
            promoted.people.recordStaffAssignment(
                StaffCareerAssignment(
                    season: promoted.calendar.season + 1,
                    organisationID: programmeID,
                    role: .headCoach
                ),
                for: victim
            )
            let tree = CoachingTreeReadModel.build(from: promoted)
            let branch = tree.branches.first { $0.mentorID == coachID }
            let isPhantom = branch?.disciples.contains { $0.staffID == victimID } == true
            expect(
                !isPhantom,
                "a coordinator the promotion threw out was credited as the coach's disciple"
            )
        }
        test("the coach's season record is written and carries across the promotion") {
            try assertCoachSeasonRecordCarriesAcrossPromotion()
        }
    }
}

func runCoachSeasonRecordTests() {
    suite("Coach season record") {
        test("the coach's season record is written and carries across the promotion") {
            try assertCoachSeasonRecordCarriesAcrossPromotion()
        }
    }
}

private func assertCoachSeasonRecordCarriesAcrossPromotion() throws {
    let source = GameState.bootstrap(seed: 99_129)
    let programmeID = source.programmes.ids[0]
    var state = try CareerControlSystem.startCollegeCareer(
        at: programmeID,
        in: source
    ).state
    state.pending = PendingQueues()
    guard let coachID = state.career.coachID else {
        expect(false, "career start left no coach")
        return
    }
    guard let delegateID = state.programmes[programmeID]?.staffIDs.first(where: {
        state.staff[$0]?.role == .offensiveCoordinator
    }) else {
        expect(false, "no coordinator to delegate to")
        return
    }
    for responsibility in CollegeCareerResponsibility.allCases {
        expect(CareerControlSystem.setResponsibility(
            responsibility,
            owner: .delegated(staffID: delegateID),
            in: &state
        ))
    }

    // A whole season, so the season-end line is written from real standings.
    var completedWins = 0
    var completedLosses = 0
    var completedTies = 0
    for week in 0..<SharedRules.inSeasonWeeks {
        if week == SharedRules.inSeasonWeeks - 1,
           let row = state.competition.standings[.college]?.first(where: {
               $0.id == programmeID
           }) {
            completedWins = row.wins
            completedLosses = row.losses
            completedTies = row.ties
        }
        state = try WorldScheduler.advanceWeek(state).state
        state.pending = PendingQueues()
    }

    let records = state.people.staffCareers[coachID]?.seasonRecords ?? []
    expectEqual(records.count, 1, "the season did not leave a career record line")
    expectEqual(records.last?.season, source.calendar.season)
    expectEqual(records.last?.organisationID, programmeID)
    // Against the standings the completed season actually produced, not the fresh next season.
    expectEqual(records.last?.wins, completedWins)
    expectEqual(records.last?.losses, completedLosses)
    expectEqual(records.last?.ties, completedTies)
    expect(
        (records.last?.wins ?? 0) + (records.last?.losses ?? 0) + (records.last?.ties ?? 0) > 0,
        "the recorded season had no games in it"
    )
    if let record = records.last {
        var reordered = state.people
        expect(reordered.recordCoachSeason(
            CoachSeasonRecord(
                season: record.season + 1,
                organisationID: programmeID,
                wins: 0,
                losses: 0,
                ties: 0
            ),
            for: coachID
        ))
        expect(
            !reordered.recordCoachSeason(record, for: coachID),
            "season-record writer accepted an out-of-order line"
        )
    }
    expect(WorldIntegrity.check(state).isValid, "season-end world failed integrity")

    // The record lives on the coach, not on the job, so a promotion cannot drop it.
    guard state.careerArc.status != .fired else {
        expect(true, "coach was fired before the promotion could be walked")
        return
    }
    let proTeam = state.proTeams.values[0]
    let opportunity = CareerOpportunity(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000A29")!,
        organisationID: proTeam.id,
        tier: .professional,
        offeredAt: state.calendar,
        expiresAt: state.calendar.advancedWeek(),
        prestige: proTeam.prestige,
        rationale: .sustainedCollegeSuccess
    )
    var promoting = state
    var arc = promoting.careerArc
    _ = arc.establishCollegeJob(organisationID: programmeID, at: promoting.calendar)
    expect(arc.addOpportunity(opportunity))
    promoting.careerArc = arc
    let promoted = try IntentResolver.resolve(
        .career(CareerArcRequest(
            calendar: promoting.calendar,
            action: .acceptOpportunity(opportunityID: opportunity.id)
        )),
        in: promoting
    ).state
    expectEqual(promoted.people.staffCareers[coachID]?.seasonRecords, records)

    // And it survives the save, like the assignments beside it.
    let restored = try SaveEnvelope.decode(
        GameState.self,
        from: SaveEnvelope.encode(promoted)
    )
    expectEqual(restored.people.staffCareers[coachID]?.seasonRecords, records)
}
