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
            expect(transition.state.career.college?.coachID != headCoachID)
            expectEqual(
                transition.state.career.college?.coachID,
                transition.state.career.coachID
            )
            let playerCoachID = transition.state.career.coachID!
            expect(transition.state.programmes[programmeID]!.staffIDs.contains(playerCoachID))
            expect(!transition.state.programmes[programmeID]!.staffIDs.contains(headCoachID))
            expectEqual(transition.state.staff[playerCoachID]?.role, .headCoach)
            expect(transition.state.people.staffCareers[playerCoachID] != nil)
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

            guard let projectedProgramme = projection.programme else {
                expect(false, "a controlled college session lost its programme projection")
                return
            }
            expectEqual(projectedProgramme.id, programmeID)
            expectEqual(projectedProgramme.name, controlled.programmes[programmeID]!.name)
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

        testAsync("career session delegation records its named employed owner") {
            let source = GameState.bootstrap(seed: 98_017)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let staffID = controlled.programmes[programmeID]!.staffIDs
                .compactMap { controlled.staff[$0] }
                .first { $0.id != controlled.career.college!.coachID }!
                .id
            let session = try CareerSession(state: controlled)

            let receipt = try await session.resolve(.setResponsibility(
                responsibility: .recruiting,
                owner: .delegated(staffID: staffID)
            ))
            if case let .responsibilityUpdated(responsibility, owner) = receipt.result {
                expectEqual(responsibility, .recruiting)
                expectEqual(owner, .delegated(staffID: staffID))
            } else {
                expect(false, "delegation did not return its typed receipt")
            }
            guard let projectedProgramme = receipt.projection.programme else {
                expect(false, "delegation lost its programme projection")
                return
            }
            expectEqual(
                projectedProgramme.responsibilityOwners[.recruiting],
                .delegated(staffID: staffID)
            )

            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: try await session.saveData()
            )
            expectEqual(
                restored.career.college?.responsibilityOwners[.recruiting],
                .delegated(staffID: staffID)
            )
            expect(WorldIntegrity.check(restored).isValid)
        }

        testAsync("career session commits a calendar-scoped personnel override") {
            let source = GameState.bootstrap(seed: 98_018)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let quarterbacks = controlled.programmes[programmeID]!.rosterIDs
                .compactMap { controlled.players[$0] }
                .filter { $0.position == .quarterback }
                .map(\.id)
            guard let first = quarterbacks.first else {
                expect(false, "the generated roster had no quarterback")
                return
            }
            let plan = PersonnelPlan(
                organisationID: programmeID,
                calendar: controlled.calendar,
                overrides: [DepthChartOverride(position: .quarterback, playerIDs: [first])]
            )
            let session = try CareerSession(state: controlled)
            let receipt = try await session.resolve(.personnelPlan(plan))
            if case let .intent(.tacticalUpdated(result)) = receipt.result {
                expectEqual(result.kind, .personnelPlan)
                expectEqual(result.organisationID, programmeID)
            } else {
                expect(false, "personnel update did not return its typed receipt")
            }
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: try await session.saveData()
            )
            expectEqual(
                restored.tactical.personnelPlan(for: programmeID, at: restored.calendar),
                plan
            )
            expect(WorldIntegrity.check(restored).isValid)
        }

        testAsync("delegating a pending decision applies the recommendation atomically") {
            let source = GameState.bootstrap(seed: 98_019)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let prospectID = controlled.prospects.ids[0]
            let decisionID = UUID(uuidString: "00000000-0000-4000-8000-000000000F19")!
            let addID = UUID(uuidString: "00000000-0000-4000-8000-000000000F1A")!
            let withdrawID = UUID(uuidString: "00000000-0000-4000-8000-000000000F1B")!
            let decision = MandatoryDecision(
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
                reasons: [MandatoryDecisionReason(code: .rosterNeed, value: 1)]
            )
            expect(controlled.pending.enqueue(decision))
            let staffID = controlled.programmes[programmeID]!.staffIDs
                .compactMap { controlled.staff[$0] }
                .first { $0.id != controlled.career.college!.coachID }!
                .id
            let session = try CareerSession(state: controlled)

            let receipt = try await session.resolve(.delegateDecision(
                decisionID: decisionID,
                staffID: staffID
            ))
            if case let .decisionDelegated(resolvedID, resolvedStaffID, optionID) = receipt.result {
                expectEqual(resolvedID, decisionID)
                expectEqual(resolvedStaffID, staffID)
                expectEqual(optionID, addID)
            } else {
                expect(false, "delegation did not return its typed receipt")
            }
            expect(!receipt.projection.mandatoryDecisions.contains { $0.id == decisionID })
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: try await session.saveData()
            )
            expectEqual(
                restored.career.college?.responsibilityOwners[.recruiting],
                .delegated(staffID: staffID)
            )
            expect(restored.career.mandatoryDecisionResolutions.contains {
                $0.decisionID == decisionID && $0.optionID == addID
            })
            expect(WorldIntegrity.check(restored).isValid)
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
            // Author the week before advancing. This test is about a released portal record
            // surviving a save round trip; the advance is only how it gets there. A controlled
            // programme with an unplayed game and no authored preparation refuses to advance --
            // deliberately, as "Weekly preparation authority" below proves -- so without this the
            // test throws `missingWeeklyPreparation` and never reaches its own assertions.
            _ = try await session.resolve(.prepareWeek)
            _ = try await session.resolve(.advanceWeek)
            let saved = try await session.saveData()
            let restored = try SaveEnvelope.decode(GameState.self, from: saved)
            // Keyed on the season the snapshot targeted, not on the restored calendar's season.
            // The record is written for the former, and the advance above can roll the latter --
            // at which point the lookup silently finds nothing and the test reports a missing
            // record rather than the season mismatch that actually caused it.
            let targetSeason = snapshot.targetSeason
            let record = restored.people.playerCareers[retainedIntent.playerID]?.portalWindows.first {
                $0.targetSeason == targetSeason && $0.window == .spring
            }
            expect(
                record != nil,
                "no spring portal record for target season \(targetSeason); "
                    + "restored calendar season is \(restored.calendar.season)"
            )
            expect(record?.outcome != .retainedBySource)
        }
    }
}

func runWeeklyAuthorityTests() {
    suite("Weekly preparation authority") {
        testAsync("a user-controlled match week pauses until preparation is authored") {
            let source = GameState.bootstrap(seed: 98_014)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            controlled.calendar = CalendarState(season: 0, week: 3)
            controlled.league.week = 3
            controlled.pending = PendingQueues()
            let session = try CareerSession(state: controlled)

            do {
                _ = try await session.resolve(.advanceWeek)
                expect(false, "a user-controlled week advanced without preparation")
            } catch let error as CareerSessionError {
                expectEqual(error, .missingWeeklyPreparation([.gamePlan, .practicePlan]))
            }

            _ = try await session.resolve(.tacticalPlan(.balanced))
            do {
                _ = try await session.resolve(.advanceWeek)
                expect(false, "a user-controlled week advanced without practice")
            } catch let error as CareerSessionError {
                expectEqual(error, .missingWeeklyPreparation([.practicePlan]))
            }

            _ = try await session.resolve(.practicePlan(.balanced))
            let receipt = try await session.resolve(.advanceWeek)
            expectEqual(receipt.projection.calendar, controlled.calendar)
            if case .matchStarted = receipt.result {
                expect(true)
            } else {
                expect(false, "prepared week did not start its resumable controlled match")
            }
        }

        test("direct scheduler advancement refuses to abstract a user-controlled fixture") {
            let source = GameState.bootstrap(seed: 98_017)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            controlled.calendar = CalendarState(season: 0, week: 3)
            controlled.league.week = 3
            controlled.pending = PendingQueues()

            do {
                _ = try WorldScheduler.advanceWeek(controlled)
                expect(false, "the direct scheduler abstracted a user-controlled fixture")
            } catch let error as WorldSchedulerError {
                guard case .controlledMatchRequired = error else {
                    expect(false, "wrong scheduler boundary: \(error)")
                    return
                }
                expect(true)
            }
        }

        testAsync("a delayed match action is rejected after the checkpoint advances") {
            let source = GameState.bootstrap(seed: 98_020)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            controlled.calendar = CalendarState(season: 0, week: 3)
            controlled.league.week = 3
            controlled.pending = PendingQueues()
            let session = try CareerSession(state: controlled)
            _ = try await session.resolve(.tacticalPlan(.balanced))
            _ = try await session.resolve(.practicePlan(.balanced))
            _ = try await session.resolve(.advanceWeek)
            let checkpoint = await session.snapshot()
            guard let started = checkpoint.matchSession,
                  let fixtureID = started.fixtureID else {
                expect(false, "prepared week did not install a match checkpoint")
                return
            }
            let oldRevision = started.revision
            _ = try await session.resolveMatch(
                fixtureID: fixtureID,
                revision: oldRevision,
                action: .advance
            )
            do {
                _ = try await session.resolveMatch(
                    fixtureID: fixtureID,
                    revision: oldRevision,
                    action: .togglePause
                )
                expect(false, "a delayed action mutated a newer match checkpoint")
            } catch let error as CareerSessionError {
                expectEqual(error, .staleMatchCheckpoint)
            }
        }

        testAsync("balanced preparation commits both records in one receipt") {
            let source = GameState.bootstrap(seed: 98_015)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            controlled.calendar = CalendarState(season: 0, week: 3)
            controlled.league.week = 3
            controlled.pending = PendingQueues()
            let session = try CareerSession(state: controlled)

            let receipt = try await session.resolve(.prepareWeek)
            if case let .preparationCommitted(organisationID, calendar) = receipt.result {
                expectEqual(organisationID, programmeID)
                expectEqual(calendar, controlled.calendar)
            } else {
                expect(false, "preparation did not return its typed receipt")
            }
            let saved = try await session.saveData()
            let restored = try SaveEnvelope.decode(GameState.self, from: saved)
            expectEqual(
                restored.tactical.plan(for: programmeID, at: restored.calendar),
                .balanced
            )
            expectEqual(
                restored.tactical.practicePlan(for: programmeID, at: restored.calendar),
                .balanced
            )
        }

        testAsync("delegated preparation reaches the same weekly resolver") {
            let source = GameState.bootstrap(seed: 98_016)
            let programmeID = source.programmes.ids[0]
            var controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            controlled.calendar = CalendarState(season: 0, week: 3)
            controlled.league.week = 3
            controlled.pending = PendingQueues()
            let staffID = controlled.programmes[programmeID]!.staffIDs.first {
                controlled.staff[$0]?.role == .offensiveCoordinator
            }!
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: staffID),
                    in: &controlled
                ))
            }
            let session = try CareerSession(state: controlled)
            let receipt = try await session.resolve(.advanceWeek)
            expect(receipt.projection.calendar != controlled.calendar)
        }
    }
}

func runProfessionalCareerSessionTests() {
    suite("Professional career session") {
        testAsync("promotion opens a professional projection and persists its tactical plan") {
            let source = GameState.bootstrap(seed: 98_013)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let team = controlled.proTeams.values[0]
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000F02")!,
                organisationID: team.id,
                tier: .professional,
                offeredAt: controlled.calendar,
                expiresAt: controlled.calendar.advancedWeek(),
                prestige: team.prestige,
                rationale: .staffRecommendation
            )
            var candidate = controlled
            candidate.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: candidate.calendar
                ),
                opportunities: [opportunity],
                status: .employed
            )
            let promoted = try IntentResolver.resolve(
                .career(CareerArcRequest(
                    calendar: candidate.calendar,
                    action: .acceptOpportunity(opportunityID: opportunity.id)
                )),
                in: candidate
            ).state
            let session = try CareerSession(state: promoted)
            expectEqual(promoted.career.coachID, controlled.career.college?.coachID)
            let projection = await session.projection()
            expectEqual(projection.tier, .professional)
            expectEqual(projection.programme?.id, team.id)
            expect(projection.recruitingBoard.isEmpty)
            expect(projection.mandatoryDecisions.isEmpty)

            _ = try await session.resolve(.tacticalPlan(.balanced))
            let saved = try await session.saveData()
            let restored = try SaveEnvelope.decode(GameState.self, from: saved)
            expectEqual(restored.tactical.plan(for: team.id, at: restored.calendar), .balanced)
            expect(WorldIntegrity.check(restored).isValid)
        }
    }
}
