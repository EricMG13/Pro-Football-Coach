import Foundation
import FootballSimCore

func runCareerControlTests() {
    suite("Controlled college career authority") {
        test("a chosen college job becomes one persisted authoritative career") {
            let source = GameState.bootstrap(seed: 98_001)
            let programmeID = source.programmes.ids[0]
            let headCoachID = source.programmes[programmeID]!.staffIDs.first {
                source.staff[$0]?.role == .headCoach
            }!

            let transition = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            )

            expectEqual(transition.state.career.college?.programmeID, programmeID)
            expectEqual(transition.state.career.college?.coachID, headCoachID)
            expectEqual(transition.state.career.college?.startedAt, source.calendar)
            expectEqual(
                Set(transition.state.career.college?.responsibilityOwners.map(\.key) ?? []),
                Set(CollegeCareerResponsibility.allCases)
            )
            expect(transition.state.career.college?.responsibilityOwners.values.allSatisfy {
                $0 == .user
            } ?? false)
            expectEqual(source.career, CareerControlState())
            expect(WorldIntegrity.check(transition.state).isValid)

            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(transition.state)
            )
            expectEqual(restored, transition.state)

            do {
                _ = try CareerControlSystem.startCollegeCareer(
                    at: source.programmes.ids[1],
                    in: transition.state
                )
                expect(false, "a second controlled college job was started")
            } catch let error as CareerControlError {
                expectEqual(error, .careerAlreadyStarted)
            }
        }

        test("scheduled recruiting AI never acts for the controlled programme") {
            let source = GameState.bootstrap(seed: 98_002)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state

            let transition = try CollegeRecruitingAISystem.process(in: controlled)

            expect(!transition.decisions.contains(where: {
                $0.request.programmeID == programmeID
            }))
            expect(transition.decisions.contains(where: {
                $0.request.programmeID != programmeID
            }))
            expectEqual(
                transition.college.programmes[programmeID],
                controlled.college.programmes[programmeID]
            )
        }

        test("delegation ownership is limited to staff employed by the controlled programme") {
            let source = GameState.bootstrap(seed: 98_003)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let coordinatorID = controlled.programmes[programmeID]!.staffIDs.first {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }!
            let outsiderID = controlled.programmes[controlled.programmes.ids[1]]!.staffIDs[0]

            expect(CareerControlSystem.setResponsibility(
                .recruiting,
                owner: .delegated(staffID: coordinatorID),
                in: &controlled
            ))
            expectEqual(
                controlled.career.college?.responsibilityOwners[.recruiting],
                .delegated(staffID: coordinatorID)
            )
            let beforeRejected = try SaveEnvelope.encode(controlled)
            expect(!CareerControlSystem.setResponsibility(
                .recruiting,
                owner: .delegated(staffID: outsiderID),
                in: &controlled
            ))
            expectEqual(try SaveEnvelope.encode(controlled), beforeRejected)
            expect(WorldIntegrity.check(controlled).isValid)
        }

        test("career-owned staff are not silently removed by routine retirement") {
            let source = GameState.bootstrap(seed: 98_011)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let coachID = controlled.career.college!.coachID
            let coordinatorID = controlled.programmes[programmeID]!.staffIDs.first {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }!
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: coordinatorID),
                    in: &controlled
                ))
            }
            _ = controlled.staff.update(coachID) {
                $0.age = PeopleRules.staffAgeRange.upperBound
            }
            _ = controlled.staff.update(coordinatorID) {
                $0.age = PeopleRules.staffAgeRange.upperBound
            }
            controlled.calendar = CalendarState(
                season: controlled.calendar.season,
                week: SharedRules.inSeasonWeeks
            )
            controlled.league.week = SharedRules.inSeasonWeeks

            let transition = try SeasonLifecycleSystem.advance(
                after: controlled.calendar,
                in: controlled
            )

            expect(transition.programmes[programmeID]?.staffIDs.contains(coachID) == true)
            expect(transition.programmes[programmeID]?.staffIDs.contains(coordinatorID) == true)
            expectEqual(transition.staff[coachID]?.age, PeopleRules.staffAgeRange.upperBound)
            expectEqual(
                transition.staff[coordinatorID]?.age,
                PeopleRules.staffAgeRange.upperBound
            )
        }

        test("mandatory decisions persist typed authority and stable options") {
            let source = GameState.bootstrap(seed: 98_004)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let prospectID = controlled.prospects.ids[0]
            let decisionID = UUID(uuidString: "00000000-0000-4000-8000-0000000000D1")!
            let keepID = UUID(uuidString: "00000000-0000-4000-8000-0000000000D2")!
            let withdrawID = UUID(uuidString: "00000000-0000-4000-8000-0000000000D3")!
            let decision = MandatoryDecision(
                id: decisionID,
                programmeID: programmeID,
                subject: .recruiting(prospectID: prospectID),
                createdAt: controlled.calendar,
                deadline: controlled.calendar.advancedWeek(),
                owner: .user,
                options: [
                    MandatoryDecisionOption(
                        id: keepID,
                        action: .recruiting(.offerScholarship)
                    ),
                    MandatoryDecisionOption(
                        id: withdrawID,
                        action: .recruiting(.withdraw)
                    ),
                ],
                recommendedOptionID: keepID,
                reasons: [
                    MandatoryDecisionReason(
                        code: .rosterNeed,
                        value: 8,
                        relatedEntityID: prospectID
                    ),
                    MandatoryDecisionReason(code: .deadline, value: 1),
                ]
            )
            var state = controlled

            expect(state.pending.enqueue(decision))
            expect(!state.pending.enqueue(decision))
            expectEqual(state.pending.mandatoryDecisions, [decision])
            expectEqual(decision.responsibility, .recruiting)
            expectEqual(decision.options.map(\.id), [keepID, withdrawID])
            expectEqual(decision.recommendedOptionID, keepID)
            expect(WorldIntegrity.check(state).isValid)

            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            )
            expectEqual(restored, state)

            do {
                _ = try IntentResolver.resolve(.advanceWeek, in: state)
                expect(false, "advance week bypassed a typed mandatory decision")
            } catch let error as IntentResolutionError {
                expectEqual(error, .unresolvedMandatoryDecisions(count: 1))
            }
        }

        testAsync("career session derives programme authority and projects only observed recruiting truth") {
            let source = GameState.bootstrap(seed: 98_005)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let prospectID = controlled.prospects.ids[0]
            let hiddenPotential = controlled.prospects[prospectID]!.potential.value
            let session = try CareerSession(state: controlled)

            let receipt = try await session.resolve(.recruiting(
                prospectID: prospectID,
                action: .addToBoard
            ))
            let projection = receipt.projection

            expectEqual(projection.programme.id, programmeID)
            expectEqual(projection.programme.name, controlled.programmes[programmeID]!.name)
            expectEqual(projection.recruitingBoard.count, 1)
            expectEqual(projection.recruitingBoard[0].prospectID, prospectID)
            expectEqual(projection.recruitingBoard[0].estimatedOverall, nil)
            expectEqual(projection.recruitingBoard[0].estimatedPotential, nil)
            expect(!projection.recruitingBoard.contains(where: {
                $0.estimatedPotential == hiddenPotential
            }))
            switch receipt.result {
            case let .intent(.recruitingUpdated(result)):
                expectEqual(result.request.programmeID, programmeID)
                expectEqual(result.request.prospectID, prospectID)
            default:
                expect(false, "career recruiting returned the wrong receipt")
            }
        }

        testAsync("a cancelled career intent leaves actor-owned state byte-identical") {
            let source = GameState.bootstrap(seed: 98_006)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let prospectID = controlled.prospects.ids[0]
            let session = try CareerSession(state: controlled)
            let before = try await session.saveData()

            let cancelled = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return try await session.resolve(.recruiting(
                    prospectID: prospectID,
                    action: .addToBoard
                ))
            }
            do {
                _ = try await cancelled.value
                expect(false, "a cancelled career intent mutated the session")
            } catch is CancellationError {
                expect(true)
            }

            expectEqual(try await session.saveData(), before)
            expectEqual((await session.projection()).recruitingBoard.count, 0)
        }

        testAsync("delegated recruiting uses the shared policy while direct user intents are refused") {
            let source = GameState.bootstrap(seed: 98_007)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let coordinatorID = controlled.programmes[programmeID]!.staffIDs.first {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }!
            expect(CareerControlSystem.setResponsibility(
                .recruiting,
                owner: .delegated(staffID: coordinatorID),
                in: &controlled
            ))

            let delegated = try CollegeCareerDelegationSystem.processRecruiting(in: controlled)
            expect(!delegated.decisions.isEmpty)
            expect(delegated.decisions.allSatisfy {
                $0.request.programmeID == programmeID
            })
            expectEqual(
                delegated.eventPayloads.count,
                delegated.decisions.count
            )

            let session = try CareerSession(state: controlled)
            do {
                _ = try await session.resolve(.recruiting(
                    prospectID: controlled.prospects.ids[0],
                    action: .addToBoard
                ))
                expect(false, "a user intent bypassed delegated recruiting authority")
            } catch let error as CareerSessionError {
                expectEqual(error, .responsibilityDelegated)
            }
        }

        testAsync("mandatory decision resolution is atomic and uses its persisted option") {
            let source = GameState.bootstrap(seed: 98_008)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let prospectID = controlled.prospects.ids[0]
            let decisionID = UUID(uuidString: "00000000-0000-4000-8000-0000000000E1")!
            let addID = UUID(uuidString: "00000000-0000-4000-8000-0000000000E2")!
            let withdrawID = UUID(uuidString: "00000000-0000-4000-8000-0000000000E3")!
            _ = controlled.pending.enqueue(MandatoryDecision(
                id: decisionID,
                programmeID: programmeID,
                subject: .recruiting(prospectID: prospectID),
                createdAt: controlled.calendar,
                deadline: controlled.calendar,
                owner: .user,
                options: [
                    MandatoryDecisionOption(id: addID, action: .recruiting(.addToBoard)),
                    MandatoryDecisionOption(id: withdrawID, action: .recruiting(.withdraw)),
                ],
                recommendedOptionID: addID,
                reasons: [MandatoryDecisionReason(code: .deadline, value: 0)]
            ))
            let session = try CareerSession(state: controlled)
            let before = try await session.saveData()

            do {
                _ = try await session.resolve(.mandatoryDecision(
                    decisionID: decisionID,
                    optionID: UUID(uuidString: "00000000-0000-4000-8000-0000000000EF")!
                ))
                expect(false, "an unknown decision option was accepted")
            } catch let error as CareerSessionError {
                expectEqual(error, .missingDecisionOption)
            }
            expectEqual(try await session.saveData(), before)

            let receipt = try await session.resolve(.mandatoryDecision(
                decisionID: decisionID,
                optionID: addID
            ))
            expect(!receipt.projection.mandatoryDecisions.contains(where: {
                $0.id == decisionID
            }))
            expectEqual(receipt.projection.recruitingBoard.map(\.prospectID), [prospectID])
            expectEqual(receipt.result, .decisionResolved(
                decisionID: decisionID,
                optionID: addID
            ))
        }

        test("week-one redshirt exceptions produce stable causal decisions") {
            let source = GameState.bootstrap(seed: 98_009)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let roster = controlled.programmes[programmeID]!.rosterIDs.compactMap {
                controlled.players[$0]
            }
            let position = Position.allCases.first { position in
                roster.filter { $0.position == position }.count
                    > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
            } ?? .quarterback
            let positionPlayers = roster.filter { $0.position == position }.sorted {
                if $0.overall.value != $1.overall.value {
                    return $0.overall.value > $1.overall.value
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            let candidateIndex = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
            let candidateID = positionPlayers[candidateIndex].id
            _ = controlled.players.update(candidateID) {
                $0.eligibility = Eligibility(
                    seasonsRemaining: CollegeRules.seasonsOfCompetition,
                    yearsRemaining: CollegeRules.eligibilityClockYears
                )
            }

            let first = CareerMandatoryDecisionSystem.refresh(in: controlled)
            let second = CareerMandatoryDecisionSystem.refresh(in: controlled)
            let decision = first.pending.mandatoryDecisions.first {
                $0.subject == .redshirt(playerID: candidateID)
            }

            expect(decision != nil)
            expectEqual(first.pending, second.pending)
            expectEqual(decision?.deadline, controlled.calendar)
            expectEqual(decision?.owner, .user)
            expectEqual(decision?.options.count, 2)
            expect(decision?.reasons.contains(where: { $0.code == .playingTime }) ?? false)
            expect(WorldIntegrity.check(first).isValid)
        }

        testAsync("a fully delegated controlled career completes a deterministic annual cycle") {
            func delegatedState(seed: UInt64) throws -> GameState {
                let source = GameState.bootstrap(seed: seed)
                let programmeID = source.programmes.ids[0]
                var state = try CareerControlSystem.startCollegeCareer(
                    at: programmeID,
                    in: source
                ).state
                let staffID = state.programmes[programmeID]!.staffIDs.first {
                    state.staff[$0]?.role == .offensiveCoordinator
                }!
                for responsibility in CollegeCareerResponsibility.allCases {
                    expect(CareerControlSystem.setResponsibility(
                        responsibility,
                        owner: .delegated(staffID: staffID),
                        in: &state
                    ))
                }
                return state
            }

            let first = try CareerSession(state: delegatedState(seed: 98_010))
            let second = try CareerSession(state: delegatedState(seed: 98_010))
            for _ in 0...SharedRules.inSeasonWeeks {
                async let firstAdvance = first.resolve(.advanceWeek)
                async let secondAdvance = second.resolve(.advanceWeek)
                _ = try await (firstAdvance, secondAdvance)
            }

            let firstProjection = await first.projection()
            let secondProjection = await second.projection()
            expectEqual(firstProjection, secondProjection)
            expectEqual(firstProjection.calendar, CalendarState(season: 1, week: 2))
            expect(firstProjection.mandatoryDecisions.isEmpty)
            let firstData = try await first.saveData()
            expectEqual(firstData, try await second.saveData())
            let restored = try SaveEnvelope.decode(GameState.self, from: firstData)
            expect(WorldIntegrity.check(restored).isValid)
            expectEqual(restored.college.portal.phase, .closed)
        }

    }
}

func runCareerPortalDecisionTests() {
    suite("Controlled college portal decisions") {
        testAsync("spring retention choices pause a user-owned portal responsibility") {
            var state = GameState.bootstrap(seed: 98_001)
            for _ in 0..<SharedRules.inSeasonWeeks {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.college.portal.phase, .awaitingSpring)
            guard let snapshot = CollegePortalPolicyV1.makeSnapshot(
                targetSeason: state.calendar.season,
                window: .spring,
                in: state
            ) else {
                expect(false, "the spring fixture did not expose an authoritative snapshot")
                return
            }
            guard let retainedIntent = snapshot.intents.first(where: { intent in
                guard let programme = state.college.programmes[intent.sourceProgrammeID],
                      let transition = CollegePortalPolicyV1.resolveRetention(
                          for: intent.sourceProgrammeID,
                          programme: programme,
                          using: snapshot
                      ) else { return false }
                return transition.resolutions[intent.playerID]?.outcome == .retained
            }) else {
                expect(false, "the spring fixture produced no retainable portal intent")
                return
            }
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: retainedIntent.sourceProgrammeID,
                in: state
            ).state
            let session = try CareerSession(state: controlled)
            let projection = await session.projection()
            let decision = projection.mandatoryDecisions.first {
                $0.subject == .portalRetention(
                    playerID: retainedIntent.playerID,
                    window: .spring
                )
            }

            expect(decision != nil)
            expectEqual(decision?.deadline, state.calendar)
            expectEqual(decision?.owner, .user)
            expectEqual(decision?.recommendedOptionID, decision?.options.first {
                if case .portalRetention = $0.action { return true }
                return false
            }?.id)
            guard let decision else { return }
            let releaseOption = decision.options.first {
                $0.action == .portalRelease
            }!
            _ = try await session.resolve(.mandatoryDecision(
                decisionID: decision.id,
                optionID: releaseOption.id
            ))
            let afterDecision = await session.projection()
            expect(!afterDecision.mandatoryDecisions.contains(where: {
                $0.id == decision.id
            }))
            for remaining in afterDecision.mandatoryDecisions {
                guard case .portalRetention = remaining.subject,
                      let release = remaining.options.first(where: {
                          $0.action == .portalRelease
                      }) else { continue }
                _ = try await session.resolve(.mandatoryDecision(
                    decisionID: remaining.id,
                    optionID: release.id
                ))
            }
            _ = try await session.resolve(.advanceWeek)
            let saved = try await session.saveData()
            let restored = try SaveEnvelope.decode(GameState.self, from: saved)
            let record = restored.people.playerCareers[retainedIntent.playerID]?.portalWindows.first {
                $0.targetSeason == restored.calendar.season && $0.window == .spring
            }
            expect(record != nil)
            expect(record?.outcome != .retainedBySource)
        }
    }
}

func runCareerAdvanceTests() {
    suite("Advancing more than one week") {
        testAsync("an advance stops the moment something wants the coach") {
            // 02 section 3.12. advanceWeek was the only way to move time, so an offseason was a
            // sequence of taps with a measured 2.83-second wait behind each one.
            let source = GameState.bootstrap(seed: 98_040)
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            let session = try CareerSession(state: controlled)
            let before = await session.projection().calendar

            let receipt = try await session.advance(weeks: 4)

            expect(receipt.weeksAdvanced >= 0 && receipt.weeksAdvanced <= 4,
                   "an advance of four weeks moved \(receipt.weeksAdvanced)")
            let after = receipt.projection.calendar
            if receipt.weeksAdvanced == 0 {
                expectEqual(after, before, "no weeks advanced but the calendar moved")
                expect(receipt.stoppedBecause != .reachedRequestedWeeks,
                       "an advance that moved nothing claimed it finished the run")
            } else {
                expect(after != before, "weeks advanced and the calendar did not move")
            }
            if receipt.stoppedBecause == .mandatoryDecision {
                expect(!receipt.projection.mandatoryDecisions.isEmpty,
                       "the advance stopped for a decision that is not there")
            }
            if receipt.stoppedBecause == .reachedRequestedWeeks {
                expectEqual(receipt.weeksAdvanced, 4,
                           "the run claimed to finish without finishing")
            }
        }

        testAsync("asking for no weeks does nothing") {
            let source = GameState.bootstrap(seed: 98_041)
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            let session = try CareerSession(state: controlled)
            let before = await session.projection().calendar
            let receipt = try await session.advance(weeks: 0)
            expectEqual(receipt.weeksAdvanced, 0)
            expectEqual(receipt.projection.calendar, before)
            let negative = try await session.advance(weeks: -5)
            expectEqual(negative.weeksAdvanced, 0, "a negative advance moved time")
        }
    }
}
