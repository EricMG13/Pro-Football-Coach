import Foundation
import FootballSimCore
import ProFootballCoachUI
import CoachWorldApp

/// G-01's gate. Two obligations, and the second is the one that is easy to lose.
///
/// The first is that what the screen shows is what the root holds — every assertion below reads the
/// value out of `GameState` and compares, rather than comparing against a literal that would drift.
///
/// The second is that what the root does *not* hold is not shown at all. `04` §4.4 requires a
/// surface without engine backing to ship without the claim, and the cheapest way to break that is
/// for a later change to fill a blank field with something plausible. The "states nothing it cannot
/// know" suite pins each such field to empty, so filling one requires deleting an assertion that
/// names the register item which would justify it.
private func startedCareer(seed: UInt64) throws -> (GameState, Programme) {
    let world = GameState.bootstrap(seed: seed)
    guard let programme = world.programmes.values.sorted(by: {
        $0.id.uuidString < $1.id.uuidString
    }).first else {
        throw CareerControlError.missingProgramme
    }
    let started = try CareerControlSystem.startCollegeCareer(at: programme.id, in: world)
    return (started.state, programme)
}

private func professionalCareer(seed: UInt64) throws -> (GameState, ProTeam) {
    var state = GameState.bootstrap(seed: seed)
    guard let team = state.proTeams.values.sorted(by: { $0.id.uuidString < $1.id.uuidString }).first,
          let coachID = team.staffIDs.first else {
        throw CareerControlError.missingHeadCoach
    }
    state.career = CareerControlState(coachID: coachID)
    state.careerArc = CareerArcState(
        currentJob: CareerJob(
            organisationID: team.id,
            tier: .professional,
            startedAt: state.calendar
        ),
        status: .employed
    )
    return (state, team)
}

func runReadModelProviderTests() {
    suite("Read model provider: identity") {
        test("starting jobs are three deterministic generated programmes") {
            let firstState = GameState.bootstrap(seed: 4_000)
            let secondState = GameState.bootstrap(seed: 4_000)
            let first = CoachWorldReadModelProvider.startingJobs(from: firstState)
            let second = CoachWorldReadModelProvider.startingJobs(from: secondState)
            expectEqual(first, second)
            expectEqual(first.count, 3)
            expectEqual(Set(first.map(\.stableID)).count, first.count)
            expect(first.indices.dropFirst().allSatisfy { index in
                first[index - 1].prestige <= first[index].prestige
            })
            expect(first.allSatisfy { job in
                guard let programme = firstState.programmes[UUID(uuidString: job.stableID)!] else {
                    return false
                }
                let target = min(95, max(40, programme.prestige.value + 10))
                return programme.name == job.programme.name
                    && job.archetype == Archetype.with(id: programme.archetypeID).name
                    && job.expectation == "Target performance \(target)"
                    && job.resources >= SharedRules.ratingRange.lowerBound
                    && job.resources <= SharedRules.ratingRange.upperBound
            })
            expectEqual(CoachWorldReadModelProvider.startingJobs(from: firstState, limit: 0), [])
        }

        test("canonical teams receive their stable logo references") {
            let world = GameState.bootstrap(seed: 20_260_812)
            let results = CoachWorldReadModelProvider.worldSearch(from: world).results
            expectEqual(results.count, 166)
            expect(results.allSatisfy { result in
                result.team.mark?.stableID == result.team.stableID
                    && result.team.mark?.assetName.hasPrefix("TeamLogo_") == true
            })
        }

        test("alternate seeds do not borrow canonical logos") {
            let world = GameState.bootstrap(seed: 20_260_813)
            let results = CoachWorldReadModelProvider.worldSearch(from: world).results
            expect(results.allSatisfy { $0.team.mark == nil })
        }

        test("no controlled career produces no coaching HQ") {
            expectEqual(
                CoachWorldReadModelProvider.coachingHQ(from: GameState.bootstrap(seed: 4_001)),
                nil
            )
        }

        testAsync("the floodlit causal loop survives personnel, match resume, and aftermath") {
            var state = GameState.bootstrap(seed: 4_200)
            let programmeID = state.programmes.ids[0]
            state = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: state
            ).state
            state.calendar = CalendarState(season: 0, week: 8)
            state.league.week = 8
            state.tactical.prepare(for: state.calendar)
            state.pending = PendingQueues()

            guard let programme = state.programmes[programmeID] else {
                expect(false, "the controlled programme disappeared")
                return
            }
            let delegatedProspectID = state.prospects.ids[0]
            let delegatedDecisionID = UUID(uuidString: "00000000-0000-4000-8000-000000004201")!
            let delegatedOptionID = UUID(uuidString: "00000000-0000-4000-8000-000000004202")!
            let delegatedFallbackOptionID = UUID(uuidString: "00000000-0000-4000-8000-000000004203")!
            var delegationState = state
            expect(delegationState.pending.enqueue(MandatoryDecision(
                id: delegatedDecisionID,
                programmeID: programmeID,
                subject: .recruiting(prospectID: delegatedProspectID),
                createdAt: state.calendar,
                deadline: state.calendar,
                owner: .user,
                options: [
                    MandatoryDecisionOption(
                        id: delegatedOptionID,
                        action: .recruiting(.addToBoard)
                    ),
                    MandatoryDecisionOption(
                        id: delegatedFallbackOptionID,
                        action: .recruiting(.withdraw)
                    ),
                ],
                recommendedOptionID: delegatedOptionID,
                reasons: [MandatoryDecisionReason(code: .rosterNeed, value: 1)]
            )))
            let delegatedStaffID = programme.staffIDs.compactMap { state.staff[$0] }
                .first { $0.id != state.career.college?.coachID }!.id
            let delegationSession = try CareerSession(state: delegationState)
            let delegationReceipt = try await delegationSession.resolve(.delegateDecision(
                decisionID: delegatedDecisionID,
                staffID: delegatedStaffID
            ))
            if case let .decisionDelegated(resolvedID, resolvedStaffID, optionID) = delegationReceipt.result {
                expectEqual(resolvedID, delegatedDecisionID)
                expectEqual(resolvedStaffID, delegatedStaffID)
                expectEqual(optionID, delegatedOptionID)
            } else {
                expect(false, "delegation did not return the shared typed receipt")
            }
            expect(!state.staff[delegatedStaffID]!.fullName.isEmpty)

            let quarterbacks = programme.rosterIDs.compactMap { state.players[$0] }
                .filter { $0.position == .quarterback }
                .sorted { $0.id.uuidString < $1.id.uuidString }
            guard let forcedOut = quarterbacks.first,
                  let fallback = quarterbacks.dropFirst().first else {
                expect(false, "the generated roster had no quarterback fallback")
                return
            }
            _ = state.people.updatePlayerLifecycle(forcedOut.id) {
                $0.suspend(PlayerSuspension(
                    reason: .conduct,
                    occurredAt: state.calendar,
                    originalWeeks: 2,
                    weeksRemaining: 2
                ))
            }
            let personnel = PersonnelPlan(
                organisationID: programmeID,
                calendar: state.calendar,
                overrides: [DepthChartOverride(
                    position: .quarterback,
                    playerIDs: [forcedOut.id, fallback.id]
                )]
            )
            let practice = TacticalPracticePlan(
                installMinutes: 30,
                conditioningMinutes: 15,
                recoveryMinutes: 0,
                positionFocusMinutes: 15,
                positionFocus: .quarterbacks
            )
            expect(state.tactical.setPlan(
                TacticalPlan(
                    runPassBias: .passHeavy,
                    tempo: .hurry,
                    pressure: .attack
                ),
                for: programmeID,
                at: state.calendar
            ))
            expect(state.tactical.setPracticePlan(
                practice,
                for: programmeID,
                at: state.calendar
            ))
            expect(state.tactical.setPersonnelPlan(personnel))
            expect(WorldIntegrity.check(state).isValid)

            let prepared = try WorldScheduler.prepareControlledMatch(in: state)
            guard let installed = prepared.matchSession,
                  let fixtureID = installed.fixtureID,
                  let controlledSide = installed.controlledSide else {
                expect(false, "the prepared week did not install a controlled checkpoint")
                return
            }
            let controlledPersonnel = controlledSide == .home ? installed.home : installed.away
            expect(!controlledPersonnel.offense.contains { $0.id == forcedOut.id })
            expect(!controlledPersonnel.defense.contains { $0.id == forcedOut.id })
            expect(controlledPersonnel.offense.contains { $0.id == fallback.id })

            let savedCheckpoint = try SaveEnvelope.encode(prepared)
            let resumedRoot = try SaveEnvelope.decode(GameState.self, from: savedCheckpoint)
            var beforeCallIn = try SaveEnvelope.decode(GameState.self, from: savedCheckpoint)
            guard var checkpoint = resumedRoot.matchSession else {
                expect(false, "the saved checkpoint did not decode")
                return
            }
            var firstProposal: TacticalCallInProposal?
            while !checkpoint.completed {
                let step = try MatchReducer.reduce(.advance, state: &checkpoint)
                if let proposal = step.proposal {
                    firstProposal = proposal
                    break
                }
            }
            guard let proposal = firstProposal else {
                expect(false, "the controlled reducer never paused for a call-in")
                return
            }
            expectEqual(proposal.situation.possession, controlledSide)
            let callInAction = proposal.options[0].action
            let checkpointData = try JSONEncoder.stable().encode(checkpoint)
            var direct = try JSONDecoder.stable().decode(MatchSessionState.self, from: checkpointData)
            var resumed = try JSONDecoder.stable().decode(MatchSessionState.self, from: checkpointData)
            let directStep = try MatchReducer.reduce(
                .chooseCallIn(callInAction),
                state: &direct
            )
            let resumedStep = try MatchReducer.reduce(
                .chooseCallIn(callInAction),
                state: &resumed
            )
            expectEqual(directStep.callIn?.side, controlledSide)
            expectEqual(directStep.callIn, resumedStep.callIn)
            expectEqual(direct.drives, resumed.drives)

            func finish(_ match: inout MatchSessionState) throws {
                while !match.completed {
                    if let pending = match.pendingCallIn {
                        _ = try MatchReducer.reduce(
                            .chooseCallIn(pending.options[0].action),
                            state: &match
                        )
                    } else {
                        _ = try MatchReducer.reduce(.advance, state: &match)
                    }
                }
            }
            try finish(&direct)
            try finish(&resumed)
            expectEqual(direct.completion?.fingerprint, resumed.completion?.fingerprint)
            expectEqual(direct.completion?.evidence, resumed.completion?.evidence)

            beforeCallIn.matchSession = resumed
            let finalized = try WorldScheduler.finalizeControlledMatch(
                resumed.completion!,
                in: beforeCallIn
            )
            guard let game = finalized.competition.currentSchedule.games.first(where: {
                $0.id == fixtureID
            }), let result = game.result else {
                expect(false, "finalization did not record the scheduled result")
                return
            }
            expect(finalized.matchSession == nil)
            expect(!result.playerStatistics.isEmpty)
            guard let aftermath = CoachWorldReadModelProvider.aftermath(from: finalized) else {
                expect(false, "finalization did not expose immutable aftermath evidence")
                return
            }
            expectEqual(aftermath.provenance, .simulationSnapshot)
            expectEqual(aftermath.recordedOutcomeID, fixtureID.uuidString)
            expect(!aftermath.grades.isEmpty)
            expect(!aftermath.callIns.isEmpty)

            let next = try WorldScheduler.advanceWeek(finalized).state
            guard let practiceReceipt = next.tactical.practiceReceiptsByOrganisation[programmeID] else {
                expect(false, "the committed practice plan was not consumed")
                return
            }
            expectEqual(practiceReceipt.calendar, state.calendar)
            expectEqual(practiceReceipt.effects, practice.effects)
            expect(next.tactical.reviews.contains {
                $0.organisationID == programmeID && $0.calendar == state.calendar
            })
            let controlledParticipantIDs = controlledSide == .home
                ? result.homeParticipantIDs
                : result.awayParticipantIDs
            guard let playerID = controlledParticipantIDs.first(where: { candidate in
                      result.playerStatistics.contains { $0.playerID == candidate }
                  }),
                  let profile = CoachWorldReadModelProvider.playerProfile(playerID, in: next) else {
                expect(false, "the next-week player profile had no controlled box-score participant")
                return
            }
            expect((1...5).contains(profile.recentForm.count))
            expect(profile.historyEvidence.contains("completed game"))
            expect(!profile.developmentEvidence.isEmpty)
            expect(profile.developmentEvidence.count <= 512)
        }

        test("news is a bounded typed-history projection") {
            let state = try startedCareer(seed: 4_001).0
            guard let model = CoachWorldReadModelProvider.news(from: state) else {
                expect(false, "a started career produced no news model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expect(model.items.count <= NewsReadModel.maximumItems)
            expectEqual(model, CoachWorldReadModelProvider.news(from: state))
            expectEqual(
                CoachWorldReadModelProvider.news(from: GameState.bootstrap(seed: 4_001)),
                nil
            )
        }

        test("durable history routes share one bounded simulation projection") {
            let state = try startedCareer(seed: 4_026).0
            guard let model = CoachWorldReadModelProvider.legacyHistory(from: state) else {
                expect(false, "a started career produced no history model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model, CoachWorldReadModelProvider.legacyHistory(from: state))
            expect(model.records.count <= 8)
            expect(model.rivalries.count <= 8)
            expect(model.careerLine.count <= 64)
            expect(model.coachingTree.count <= 256)
            expectEqual(model.team.stableID, state.career.college?.programmeID.uuidString)
            expectEqual(
                CoachWorldReadModelProvider.legacyHistory(from: GameState.bootstrap(seed: 4_026)),
                nil
            )
        }

        test("statistics and honours stay bounded and truthful when archives are empty") {
            let state = try startedCareer(seed: 4_027).0
            guard let stats = CoachWorldReadModelProvider.statisticsLeaders(from: state),
                  let honours = CoachWorldReadModelProvider.awardsHonours(from: state) else {
                expect(false, "a started career produced no competition history models")
                return
            }
            expectEqual(stats.provenance, .simulationSnapshot)
            expectEqual(honours.provenance, .simulationSnapshot)
            expect(stats.rows.count <= 32)
            expect(honours.awards.count <= 64)
            expectEqual(stats, CoachWorldReadModelProvider.statisticsLeaders(from: state))
            expectEqual(honours, CoachWorldReadModelProvider.awardsHonours(from: state))
            expectEqual(
                CoachWorldReadModelProvider.statisticsLeaders(from: GameState.bootstrap(seed: 4_027)),
                nil
            )
            expectEqual(
                CoachWorldReadModelProvider.awardsHonours(from: GameState.bootstrap(seed: 4_027)),
                nil
            )
        }

        test("realignment is a typed event surface, not a current-table guess") {
            let state = try startedCareer(seed: 4_028).0
            guard let model = CoachWorldReadModelProvider.realignment(from: state) else {
                expect(false, "a started career produced no realignment model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model, CoachWorldReadModelProvider.realignment(from: state))
            if let event = model.event {
                expect(event.swaps.count <= 2)
                expect(!event.reason.isEmpty)
            }
            expectEqual(
                CoachWorldReadModelProvider.realignment(from: GameState.bootstrap(seed: 4_028)),
                nil
            )

            var professional = state
            professional.career = CareerControlState(coachID: state.career.coachID)
            professional.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: professional.proTeams.values[0].id,
                    tier: .professional,
                    startedAt: professional.calendar
                ),
                status: .employed
            )
            let event = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: professional.league.seed,
                    sequence: professional.history.nextSequence
                ),
                sequence: professional.history.nextSequence,
                occurredAt: professional.calendar,
                payload: .realignment(
                    season: professional.calendar.season,
                    reason: .geographicFit,
                    swaps: []
                )
            )
            expect(professional.history.append(event))
            expectEqual(CoachWorldReadModelProvider.realignment(from: professional), nil)

            var staleCollegeControl = professional
            staleCollegeControl.career = state.career
            expectEqual(CoachWorldReadModelProvider.realignment(from: staleCollegeControl), nil)
        }

        test("the coaching HQ is a simulation snapshot, not a fixture") {
            let (state, _) = try startedCareer(seed: 4_002)
            guard let model = CoachWorldReadModelProvider.coachingHQ(from: state) else {
                expect(false, "a started career produced no coaching HQ")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
        }

        test("team, coach and venue are the programme's own, not a sample's") {
            let (state, programme) = try startedCareer(seed: 4_003)
            guard let model = CoachWorldReadModelProvider.coachingHQ(from: state),
                  let control = state.career.college,
                  let coach = state.staff[control.coachID] else {
                expect(false, "a started career produced no coaching HQ")
                return
            }
            expectEqual(model.team.stableID, programme.id.uuidString)
            expectEqual(model.team.name, programme.name)
            expectEqual(model.coach.name, coach.fullName)
            expectEqual(model.coach.stableID, coach.id.uuidString)
            expectEqual(coach.role, .headCoach)
            expectEqual(
                model.team.primaryColorHex,
                state.identities[programme.id]?.colours.primary.hex
            )
            expectEqual(
                model.team.secondaryColorHex,
                state.identities[programme.id]?.colours.secondary.hex
            )
        }

        test("the opponent and venue are this week's scheduled game") {
            let (state, programme) = try startedCareer(seed: 4_004)
            guard let model = CoachWorldReadModelProvider.coachingHQ(from: state) else {
                expect(false, "a started career produced no coaching HQ")
                return
            }
            let game = state.competition.currentSchedule.games.first {
                $0.season == state.calendar.season
                    && $0.week == state.calendar.week
                    && ($0.homeID == programme.id || $0.awayID == programme.id)
            }
            guard let game else {
                // A bye week is a legitimate state and the read model must show no opponent.
                expectEqual(model.opponent, nil)
                expectEqual(model.venue, nil)
                return
            }
            let opponentID = game.homeID == programme.id ? game.awayID : game.homeID
            expectEqual(model.opponent?.stableID, opponentID.uuidString)
            expectEqual(model.venue?.name, state.identities[game.homeID]?.venueName)
        }

        test("the record and week labels are read out of the root") {
            let (state, programme) = try startedCareer(seed: 4_005)
            guard let model = CoachWorldReadModelProvider.coachingHQ(from: state) else {
                expect(false, "a started career produced no coaching HQ")
                return
            }
            let row = state.competition.standings.values
                .flatMap { $0 }
                .first { $0.id == programme.id }
            guard let row else {
                expect(false, "a started career had no standings row")
                return
            }
            expectEqual(model.recordLabel, "\(row.wins)-\(row.losses)")
            expectEqual(model.week.weekLabel, "Week \(state.calendar.week)")
            expectEqual(model.week.seasonLabel, "Season \(state.calendar.season + 1)")
            let ranked = state.competition.rankings.values
                .compactMap { $0.firstIndex(of: programme.id) }
                .first
            expectEqual(model.rankLabel, ranked.map { "#\($0 + 1)" })
        }

        test("the same seed produces the same read model") {
            let first = CoachWorldReadModelProvider.coachingHQ(from: try startedCareer(seed: 4_006).0)
            let second = CoachWorldReadModelProvider.coachingHQ(from: try startedCareer(seed: 4_006).0)
            expectEqual(first, second)
        }

        test("game and practice plans expose live bounded choices") {
            let (state, programme) = try startedCareer(seed: 4_018)
            guard let gamePlan = CoachWorldReadModelProvider.gamePlan(from: state),
                  let practicePlan = CoachWorldReadModelProvider.practicePlan(from: state) else {
                expect(false, "a started career produced no weekly management models")
                return
            }
            expectEqual(gamePlan.provenance, .simulationSnapshot)
            expectEqual(practicePlan.provenance, .simulationSnapshot)
            expectEqual(gamePlan.team.stableID, programme.id.uuidString)
            expectEqual(Set(gamePlan.options.map(\.id)).count, gamePlan.options.count)
            expectEqual(Set(practicePlan.options.map(\.id)).count, practicePlan.options.count)
            expect(practicePlan.options.allSatisfy {
                let plan = $0.plan
                return plan.installMinutes + plan.conditioningMinutes
                    + plan.recoveryMinutes + plan.positionFocusMinutes
                    == TacticalPracticePlan.weeklyMinutes
            })
            expect(gamePlan.options.contains { $0.plan == .balanced })
            expect(practicePlan.options.contains { $0.plan == .balanced })
        }

        test("depth chart exposes available personnel and bounded overrides") {
            let (state, programme) = try startedCareer(seed: 4_019)
            guard let model = CoachWorldReadModelProvider.depthChart(from: state) else {
                expect(false, "a started career produced no depth chart")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.team.stableID, programme.id.uuidString)
            expect(!model.positions.isEmpty)
            expect(model.positions.allSatisfy { group in
                !group.slots.isEmpty && group.slots.filter(\.isStarter).count == 1
            })
            expectEqual(Set(model.options.map(\.id)).count, model.options.count)
            expect(model.options.allSatisfy {
                $0.plan.organisationID == programme.id
                    && $0.plan.calendar == state.calendar
            })
            expect(model.options.contains { $0.plan.overrides.isEmpty })
        }

        test("depth chart marks redshirt-limited players unavailable") {
            let (source, programme) = try startedCareer(seed: 4_020)
            var state = source
            guard let playerID = programme.rosterIDs.first(where: { id in
                guard let player = state.players[id], let eligibility = player.eligibility,
                      let lifecycle = state.people.playerLifecycle[id] else { return false }
                return lifecycle.status == .active && !eligibility.isExhausted
            }) else {
                expect(false, "the generated roster had no redshirt-eligible player")
                return
            }
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programme.id,
                plannedAppearanceLimit: 0,
                in: state
            )
            guard let model = CoachWorldReadModelProvider.depthChart(from: state),
                  let slot = model.positions.flatMap(\.slots).first(where: {
                      $0.playerID == playerID.uuidString
                  }) else {
                expect(false, "the redshirted player was absent from the depth chart")
                return
            }
            expect(slot.isUnavailable)
            expect(!slot.isStarter)
        }

        test("team health is a bounded lifecycle projection") {
            let (state, _) = try startedCareer(seed: 4_023)
            guard let model = CoachWorldReadModelProvider.teamHealth(from: state) else {
                expect(false, "a started career produced no team health model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expect(model.players.count <= 128)
            expect(model.players.allSatisfy {
                (0...100).contains($0.condition) && (0...100).contains($0.fatigue)
            })
            expectEqual(model.players.count, CoachWorldReadModelProvider.roster(from: state)?.players.count)
            expectEqual(
                model.injuryCount,
                model.players.compactMap { UUID(uuidString: $0.stableID) }.filter {
                    state.people.playerLifecycle[$0]?.injury != nil
                }.count
            )
            expectEqual(
                model.suspensionCount,
                model.players.compactMap { UUID(uuidString: $0.stableID) }.filter {
                    state.people.playerLifecycle[$0]?.suspension != nil
                }.count
            )
            expectEqual(model, CoachWorldReadModelProvider.teamHealth(from: state))
            expectEqual(
                CoachWorldReadModelProvider.teamHealth(from: GameState.bootstrap(seed: 4_023)),
                nil
            )

            var injuredAndSuspended = state
            let calendar = injuredAndSuspended.calendar
            guard let playerID = injuredAndSuspended.career.college.flatMap({
                injuredAndSuspended.programmes[$0.programmeID]?.rosterIDs.first
            }) else {
                expect(false, "the generated controlled roster has no player")
                return
            }
            _ = injuredAndSuspended.people.updatePlayerLifecycle(playerID) {
                $0.sustain(PlayerInjury(
                    area: .knee,
                    severity: .moderate,
                    occurredAt: calendar,
                    originalWeeks: 2,
                    weeksRemaining: 2
                ))
                $0.suspend(PlayerSuspension(
                    reason: .conduct,
                    occurredAt: calendar,
                    originalWeeks: 2,
                    weeksRemaining: 2
                ))
            }
            let combined = CoachWorldReadModelProvider.teamHealth(from: injuredAndSuspended)
            let combinedRow = combined?.players.first { $0.stableID == playerID.uuidString }
            expectEqual(combined?.injuryCount, model.injuryCount + 1)
            expectEqual(combined?.suspensionCount, model.suspensionCount + 1)
            expect(combinedRow?.statusDetail.contains("Injury 2 week(s) remaining") == true)
            expect(combinedRow?.statusDetail.contains("Suspension 2 week(s) remaining") == true)
        }

        test("professional offseason projects the controlled market and observer evidence") {
            let (closed, team) = try professionalCareer(seed: 4_060)
            guard let closedModel = CoachWorldReadModelProvider.proOffseason(from: closed) else {
                expect(false, "a professional appointment produced no offseason model")
                return
            }
            expectEqual(closedModel.provenance, .simulationSnapshot)
            expectEqual(closedModel.phase, .closed)
            expectEqual(closedModel.team.stableID, team.id.uuidString)
            expectEqual(closedModel.prospects, [])
            expect(closedModel.actions.contains { $0.id == "pro:open-offseason" && $0.isAvailable })
            expectEqual(
                CoachWorldReadModelProvider.proOffseason(from: GameState.bootstrap(seed: 4_060)),
                nil
            )

            let opened = try IntentResolver.resolve(
                .proMarket(ProMarketRequest(calendar: closed.calendar, action: .openOffseason)),
                in: closed
            ).state
            guard let openedModel = CoachWorldReadModelProvider.proOffseason(from: opened) else {
                expect(false, "an opened professional market disappeared from the model")
                return
            }
            expectEqual(openedModel.phase, .freeAgency)
            expectEqual(openedModel.prospects.count, min(ProRules.draftPickCount, ProOffseasonReadModel.maximumRows))
            expectEqual(openedModel.freeAgents.count, opened.proMarket.freeAgentIDs.count)
            expect(openedModel.prospects.allSatisfy {
                $0.estimatedOverall == nil && $0.confidence == nil
            })
            expect(openedModel.actions.contains { $0.id == "pro:begin-draft" && $0.isAvailable })
            guard let prospect = opened.proMarket.draftClass.first,
                  let scout = openedModel.prospects.first(where: { $0.id == prospect.id })?.action else {
                expect(false, "the opened draft class had no scout action")
                return
            }
            if case let .scout(teamID, prospectID) = scout.action {
                expectEqual(teamID, team.id)
                expectEqual(prospectID, prospect.id)
            } else {
                expect(false, "the draft board projected the wrong scout action")
            }

            let observed = try IntentResolver.resolve(
                .proMarket(ProMarketRequest(calendar: opened.calendar, action: scout.action)),
                in: opened
            ).state
            let observedRow = CoachWorldReadModelProvider.proOffseason(from: observed)?.prospects
                .first(where: { $0.id == prospect.id })
            expect(observedRow?.estimatedOverall != nil)
            expect(observedRow?.confidence != nil)
            expect(WorldIntegrity.check(observed).isValid)

            var fired = closed
            fired.careerArc = CareerArcState(status: .fired)
            expectEqual(CoachWorldReadModelProvider.proOffseason(from: fired), nil)
        }

        test("professional management projects bounded cap and roster actions") {
            let (state, team) = try professionalCareer(seed: 4_062)
            guard let model = CoachWorldReadModelProvider.proManagement(from: state),
                  let cap = try? ProManagementSystem.capSnapshot(teamID: team.id, in: state) else {
                expect(false, "a professional appointment produced no management model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.team.stableID, team.id.uuidString)
            expectEqual(model.cap.remainingCap, cap.remainingCap)
            expect(model.activeRoster.count <= ProManagementReadModel.maximumRows)
            expect(model.practiceSquad.count <= ProManagementReadModel.maximumRows)
            expect(model.activeRoster.allSatisfy { $0.action?.action == .release(playerID: $0.id, teamID: team.id) })
            expectEqual(model, CoachWorldReadModelProvider.proManagement(from: state))
            expectEqual(
                CoachWorldReadModelProvider.proManagement(from: GameState.bootstrap(seed: 4_062)),
                nil
            )
        }

        test("staff room projects the controlled organisation's bounded staff ledger") {
            let (state, programme) = try startedCareer(seed: 4_063)
            guard let model = CoachWorldReadModelProvider.staffRoom(from: state) else {
                expect(false, "a started career produced no staff room")
                return
            }
            expectEqual(model.team.stableID, programme.id.uuidString)
            expect(model.rows.count <= StaffRoomReadModel.maximumRows)
            expect(model.rows.allSatisfy {
                $0.reputation >= SharedRules.ratingRange.lowerBound
                    && $0.reputation <= SharedRules.ratingRange.upperBound
                    && $0.development >= SharedRules.ratingRange.lowerBound
                    && $0.development <= SharedRules.ratingRange.upperBound
            })
            expectEqual(model, CoachWorldReadModelProvider.staffRoom(from: state))
            expectEqual(
                CoachWorldReadModelProvider.staffRoom(from: GameState.bootstrap(seed: 4_063)),
                nil
            )
        }

        test("college offseason projects portal boundaries and bounded cycle facts") {
            let (started, programme) = try startedCareer(seed: 4_061)
            let openPortal = CollegePortalState(
                targetSeason: started.college.recruitingSeason,
                phase: .postseasonOpen
            )
            var state = started
            state.college = CollegeState(
                recruitingSeason: started.college.recruitingSeason,
                portal: openPortal,
                phase: started.college.phase,
                programmes: started.college.programmes,
                prospectRecruitment: started.college.prospectRecruitment,
                archivedProspects: started.college.archivedProspects,
                redshirtPlans: started.college.redshirtPlans
            )
            guard let model = CoachWorldReadModelProvider.collegeOffseason(from: state) else {
                expect(false, "an open college portal produced no offseason model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.programme.stableID, programme.id.uuidString)
            expectEqual(model.portalPhase, .postseasonOpen)
            expectEqual(model.boardCount, state.college.programmes[programme.id]?.boardIDs.count)
            expectEqual(model.nilCommitted, 0)
            expect(model.decisions.count <= CollegeOffseasonReadModel.maximumDecisions)
            expectEqual(model, CoachWorldReadModelProvider.collegeOffseason(from: state))
            expectEqual(
                CoachWorldReadModelProvider.collegeOffseason(from: GameState.bootstrap(seed: 4_061)),
                nil
            )
        }

        test("inbox is a bounded authoritative decision and story projection") {
            let (state, _) = try startedCareer(seed: 4_024)
            guard let model = CoachWorldReadModelProvider.inbox(from: state) else {
                expect(false, "a started career produced no inbox model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expect(model.items.count <= InboxReadModel.maximumItems)
            expect(model.items.allSatisfy { !$0.stableID.isEmpty && !$0.title.isEmpty })
            expect(model.items.filter { $0.kind == .decision }.allSatisfy {
                $0.destination == .coachingHQ && $0.deadline != nil
            })
            expect(model.items.filter { $0.kind == .task }.allSatisfy {
                $0.destination == .gamePlan || $0.destination == .practicePlan
            })
            expectEqual(model, CoachWorldReadModelProvider.inbox(from: state))
            if let first = model.items.first {
                let read = CoachWorldReadModelProvider.inbox(
                    from: state,
                    readInboxItemIDs: [first.stableID]
                )
                expectEqual(read?.items.first(where: { $0.stableID == first.stableID })?.isUnread, false)
            }
            expectEqual(
                CoachWorldReadModelProvider.inbox(from: GameState.bootstrap(seed: 4_024)),
                nil
            )
        }

        test("opponent film never substitutes hidden totals for missing observation") {
            let (state, _) = try startedCareer(seed: 4_025)
            guard let model = CoachWorldReadModelProvider.opponentFilm(from: state) else {
                expect(false, "a started career produced no film model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expect((0...100).contains(model.confidence))
            expect((0...100).contains(model.passRate))
            expect((0...100).contains(model.turnoverRate))
            if !model.isCurrent {
                expect(model.unavailableReason != nil)
                expectEqual(model.sourceGameCount, 0)
            }
            expectEqual(model, CoachWorldReadModelProvider.opponentFilm(from: state))
            expectEqual(
                CoachWorldReadModelProvider.opponentFilm(from: GameState.bootstrap(seed: 4_025)),
                nil
            )

            var completed = state
            guard let observerID = state.career.college?.programmeID,
                  let scheduled = state.competition.currentSchedule.games.first(where: {
                      $0.homeID == observerID || $0.awayID == observerID
                  }) else {
                expect(false, "the started career had no scheduled fixture to complete")
                return
            }
            var resolved = scheduled
            resolved.result = GameSummary(
                homeScore: 21,
                awayScore: 17,
                homeStatistics: TeamGameStatistics(
                    points: 21, offensiveYards: 300, passingYards: 200,
                    rushingYards: 100, turnovers: 0
                ),
                awayStatistics: TeamGameStatistics(
                    points: 17, offensiveYards: 280, passingYards: 180,
                    rushingYards: 100, turnovers: 1
                ),
                playerStatistics: []
            )
            expect(completed.competition.currentSchedule.replace(resolved))
            expectEqual(CoachWorldReadModelProvider.coachingHQ(from: completed)?.opponent, nil)
            expectEqual(CoachWorldReadModelProvider.opponentFilm(from: completed)?.opponent, nil)

            let source = GameState.bootstrap(seed: 4_008)
            guard let fixture = source.competition.currentSchedule.games.first(where: {
                $0.result == nil && source.programmes[$0.homeID] != nil
            }) else {
                expect(false, "the generated fixture had no current opponent")
                return
            }
            var observed = try CareerControlSystem.startCollegeCareer(
                at: fixture.homeID,
                in: source
            ).state
            guard let observedHQ = CoachWorldReadModelProvider.coachingHQ(from: observed),
                  let observerID = UUID(uuidString: observedHQ.team.stableID),
                  let game = observed.competition.currentSchedule.games.first(where: {
                      $0.season == observed.calendar.season
                          && $0.week == observed.calendar.week
                          && $0.result == nil
                          && ($0.homeID == observerID || $0.awayID == observerID)
                  }) else {
                expect(false, "the controlled fixture had no current opponent")
                return
            }
            let opponentID = game.homeID == observerID ? game.awayID : game.homeID
            expect(observed.tactical.recordObservation(OpponentObservation(
                observerID: observerID,
                opponentID: opponentID,
                observedThrough: observed.tactical.calendar,
                sourceGameIDs: [game.id],
                confidence: 50,
                sampleSize: 1,
                passRate: 62,
                turnoverRate: 8
            )))
            let current = CoachWorldReadModelProvider.opponentFilm(from: observed)
            expectEqual(current?.isCurrent, true)
            expectEqual(current?.sourceGameCount, 1)
            expectEqual(current?.passRate, 62)
            expectEqual(current?.turnoverRate, 8)
        }

        test("a controlled checkpoint produces a live Match Day model") {
            let source = GameState.bootstrap(seed: 4_008)
            guard let game = source.competition.currentSchedule.games.first(where: {
                $0.season == source.calendar.season
                    && $0.week == source.calendar.week
                    && $0.result == nil
                    && source.programmes[$0.homeID] != nil
            }) else {
                expect(false, "the generated fixture had no controlled college side")
                return
            }
            let started = try CareerControlSystem.startCollegeCareer(at: game.homeID, in: source).state
            let checkpoint = try WorldScheduler.prepareControlledMatch(in: started)
            guard let model = CoachWorldReadModelProvider.matchDay(from: checkpoint) else {
                expect(false, "a controlled checkpoint produced no Match Day model")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.actors.count, 22)
            expectEqual(model.actors.filter { $0.side == .home }.count, 11)
            expectEqual(model.actors.filter { $0.side == .away }.count, 11)
            expect(model.recordedOutcomeID.contains(game.id.uuidString))
            expect(model.controls.contains { $0.id == .keyMoments && $0.isEnabled })
            expect(model.controls.contains {
                $0.id == .takeOver && $0.isEnabled && $0.isSelected && $0.value == "Hand back"
            }, "a controlled checkpoint did not expose hand-back control")
            expect(model.controls.contains { $0.id == .tactics && $0.isEnabled },
                   "a controlled checkpoint with no pending call-in must allow a tactics change")

            var interrupted = checkpoint
            guard var session = interrupted.matchSession else {
                expect(false, "the controlled checkpoint lost its match session")
                return
            }
            session.situation = Situation(
                down: 4,
                distance: 2,
                yardLine: 72,
                possession: .home,
                homeScore: 14,
                awayScore: 17,
                quarter: 4,
                secondsRemainingInQuarter: 80,
                timeoutsRemaining: [.home: 3, .away: 3]
            )
            _ = try MatchReducer.reduce(.advance, state: &session)
            interrupted.matchSession = session
            let interruptedModel = CoachWorldReadModelProvider.matchDay(from: interrupted)
            expect(interruptedModel?.controls.contains {
                $0.id == .pause && !$0.isEnabled
            } == true, "pause remained enabled while a call-in required a choice")
            expect(interruptedModel?.controls.contains {
                $0.id == .tactics && !$0.isEnabled
            } == true, "tactics remained enabled while a call-in required a choice")
        }

        test("a promoted professional career still has a live coaching HQ") {
            let controlled = try startedCareer(seed: 4_007).0
            let programmeID = controlled.career.college!.programmeID
            let team = controlled.proTeams.values[0]
            let opportunity = CareerOpportunity(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000701")!,
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
            let model = CoachWorldReadModelProvider.coachingHQ(from: promoted)
            expectEqual(model?.team.stableID, team.id.uuidString)
            // Read the public name, do not rebuild it. cityName stays state-qualified for the
            // map; the public name does not carry a state, and recomposing here was asserting the
            // old rule against the new world.
            expectEqual(model?.team.name, team.displayName)
            expectEqual(model?.provenance, .simulationSnapshot)
        }

        test("career hub exposes the controlled appointment and bounded support ledger") {
            let (state, _) = try startedCareer(seed: 4_009)
            guard let control = state.career.college,
                  let model = CoachWorldReadModelProvider.careerHub(from: state) else {
                expect(false, "a started career produced no career hub")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.coach.stableID, control.coachID.uuidString)
            expectEqual(model.currentJob?.team.stableID, control.programmeID.uuidString)
            expectEqual(model.currentJob?.tier, "College")
            expectEqual(model.support.count, CareerStakeholder.allCases.count)
            expect(model.support.allSatisfy { (0...100).contains($0.value) })
        }

        test("career hub disables expired professional offers") {
            var state = try startedCareer(seed: 4_011).0
            let programmeID = state.career.college!.programmeID
            let team = state.proTeams.values[0]
            let offerID = UUID(uuidString: "00000000-0000-4000-8000-000000000711")!
            state.calendar = CalendarState(season: 0, week: 2)
            state.league.week = 2
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: programmeID,
                    tier: .college,
                    startedAt: CalendarState(season: 0, week: 1)
                ),
                opportunities: [CareerOpportunity(
                    id: offerID,
                    organisationID: team.id,
                    tier: .professional,
                    offeredAt: CalendarState(season: 0, week: 1),
                    expiresAt: CalendarState(season: 0, week: 1),
                    prestige: team.prestige,
                    rationale: .staffRecommendation
                )],
                status: .employed
            )
            guard let offer = CoachWorldReadModelProvider.careerHub(from: state)?.opportunities.first else {
                expect(false, "the career hub dropped the expired offer instead of explaining it")
                return
            }
            expect(!offer.canAccept)
            expectEqual(offer.unavailableReason, "This offer has expired.")
        }

        test("career hub does not enable an offer for a stale college control") {
            var state = try startedCareer(seed: 4_012).0
            let programmeID = state.career.college!.programmeID
            let team = state.proTeams.values[0]
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: team.id,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                opportunities: [CareerOpportunity(
                    id: UUID(uuidString: "00000000-0000-4000-8000-000000000712")!,
                    organisationID: team.id,
                    tier: .professional,
                    offeredAt: state.calendar,
                    expiresAt: state.calendar.advancedWeek(),
                    prestige: team.prestige,
                    rationale: .staffRecommendation
                )],
                status: .employed
            )
            guard let offer = CoachWorldReadModelProvider.careerHub(from: state)?.opportunities.first else {
                expect(false, "the stale-control offer disappeared instead of explaining its refusal")
                return
            }
            expect(!offer.canAccept)
            expectEqual(offer.unavailableReason, "A professional appointment is already active.")
            expectEqual(
                CoachWorldReadModelProvider.careerHub(from: state)?.currentJob?.team.stableID,
                team.id.uuidString
            )
            expectEqual(programmeID, state.career.college?.programmeID)
        }

        test("standings are sourced from the authoritative competition table") {
            let (state, _) = try startedCareer(seed: 4_010)
            guard let model = CoachWorldReadModelProvider.standings(from: state),
                  let control = state.career.college else {
                expect(false, "a started career produced no college standings")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.tier, "College")
            expectEqual(
                model.rows.count,
                state.competition.standings[.college]?.count ?? 0
            )
            expect(model.rows.contains { $0.team.stableID == control.programmeID.uuidString
                && $0.isControlled })
            expect(model.rows.allSatisfy { $0.wins >= 0 && $0.losses >= 0 && $0.ties >= 0 })
        }

        test("professional competition surfaces follow the professional career tier") {
            let (state, team) = try professionalCareer(seed: 4_011)
            let tier = CoachWorldReadModelProvider.controlledCompetitionTier(from: state)
            expectEqual(tier, .pro)

            guard let standings = CoachWorldReadModelProvider.standings(tier: tier, from: state),
                  let schedule = CoachWorldReadModelProvider.schedule(tier: tier, from: state) else {
                expect(false, "a professional career produced no professional competition surfaces")
                return
            }
            let sourceGames = state.competition.currentSchedule.games.filter { $0.tier == .pro }
            let overview = CoachWorldReadModelProvider.competitionOverview(tier: tier, from: state)

            expectEqual(standings.tier, "Professional")
            expectEqual(standings.rows.count, state.competition.standings[.pro]?.count ?? 0)
            expect(standings.rows.contains {
                $0.team.stableID == team.id.uuidString && $0.isControlled
            })
            expectEqual(schedule.tier, "Professional")
            expectEqual(schedule.games.count, sourceGames.count)
            expect(schedule.games.contains { $0.isControlled })
            expectEqual(overview.tier, "Professional")
            expectEqual(overview.rankings.count, state.competition.rankings[.pro]?.count ?? 0)
            expect(overview.rankings.contains {
                $0.team.stableID == team.id.uuidString && $0.isControlled
            })
        }

        test("a pro ranking's seed matches an independent re-derivation of the same algorithm") {
            // Re-implements the selection PostseasonSystem.advance's own pro quarterfinal case
            // uses (PostseasonSystem.swift): per conference, filter the whole-tier ranking down to
            // that conference's members (preserving order) and take the top
            // playoffSeedsPerConference. Written independently here rather than shared with the
            // provider, so a typo in one is unlikely to appear in the other -- this cannot prove
            // the provider matches what a live postseason transition actually pairs, only that its
            // computation matches a clean restatement of the documented rule; the accompanying
            // source-scan test below is what actually guards the provider and PostseasonSystem
            // against drifting onto two different constants.
            let (state, _) = try professionalCareer(seed: 4_017)
            let overview = CoachWorldReadModelProvider.competitionOverview(tier: .pro, from: state)
            let order = state.competition.rankings[.pro] ?? []
            expect(!order.isEmpty, "a professional career produced no pro ranking to check")

            var expectedSeeds: [UUID: Int] = [:]
            for conference in state.league.conferences(in: .pro) {
                let entrants = order.filter(conference.memberIDs.contains)
                    .prefix(ProRules.playoffSeedsPerConference)
                for (index, id) in entrants.enumerated() { expectedSeeds[id] = index + 1 }
            }

            for row in overview.rankings {
                guard let id = UUID(uuidString: row.id) else {
                    expect(false, "ranking row \(row.id) is not a valid UUID")
                    continue
                }
                expectEqual(row.seed, expectedSeeds[id],
                            "\(row.team.name)'s seed disagrees with PostseasonSystem's own selection")
                expectEqual(row.isQualifying, expectedSeeds[id] != nil,
                            "\(row.team.name)'s isQualifying disagrees with whether it actually seeded")
                expectEqual(row.qualifyingSlots, ProRules.playoffSeedsPerConference)
            }
            expect(overview.rankings.contains { $0.isQualifying },
                   "at least one team in a full pro league must qualify, or this test proves nothing")
        }

        test("schedule rows preserve fixture identity and controlled-team context") {
            let (state, _) = try startedCareer(seed: 4_015)
            guard let control = state.career.college,
                  let model = CoachWorldReadModelProvider.schedule(from: state) else {
                expect(false, "a started career produced no college schedule")
                return
            }
            let sourceGames = state.competition.currentSchedule.games.filter {
                $0.tier == .college
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.games.count, sourceGames.count)
            expect(model.games.contains { $0.isControlled })
            expect(model.games.allSatisfy { !$0.id.isEmpty && !$0.home.name.isEmpty })
            expect(model.games.contains {
                $0.home.stableID == control.programmeID.uuidString
                    || $0.away.stableID == control.programmeID.uuidString
            })
        }

        test("team profile preserves map identity, competition context and stable fixtures") {
            let (state, programme) = try startedCareer(seed: 4_016)
            guard let model = CoachWorldReadModelProvider.teamProgrammeProfile(
                programme.id,
                from: state
            ) else {
                expect(false, "a generated programme produced no team profile")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.team.stableID, programme.id.uuidString)
            expectEqual(model.cityName, programme.cityName)
            expectEqual(model.venue.name, state.identities[programme.id]?.venueName)
            expectEqual(model.rosterCount, programme.rosterIDs.count)
            expectEqual(model.staffCount, programme.staffIDs.count)
            expect(model.fixtures.allSatisfy { !$0.id.isEmpty && !$0.opponent.name.isEmpty })
            expect(model.rivals.allSatisfy { (0...100).contains($0.intensity) })
            expectEqual(
                Set(model.fixtures.map(\.id)),
                Set(state.competition.currentSchedule.games.filter {
                    $0.homeID == programme.id || $0.awayID == programme.id
                }.prefix(12).map { $0.id.uuidString })
            )
        }

        test("world search is bounded, deterministic and uses organisation IDs") {
            let (state, _) = try startedCareer(seed: 4_017)
            let first = CoachWorldReadModelProvider.worldSearch(from: state)
            let second = CoachWorldReadModelProvider.worldSearch(from: state)
            expectEqual(first, second)
            expectEqual(first.provenance, .simulationSnapshot)
            expectEqual(first.results.count, state.programmes.count + state.proTeams.count)
            expectEqual(Set(first.results.map(\.id)).count, first.results.count)
            expect(first.results.allSatisfy { UUID(uuidString: $0.id) != nil })
            expect(first.results.allSatisfy { !$0.team.name.isEmpty && !$0.cityName.isEmpty })
        }

        test("competition overview joins rankings and postseason games by fixture ID") {
            let (state, _) = try startedCareer(seed: 4_018)
            let model = CoachWorldReadModelProvider.competitionOverview(from: state)
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.rankings.count, state.competition.rankings[.college]?.count ?? 0)
            expectEqual(
                Set(model.bracket.map(\.id)),
                Set(state.competition.currentSchedule.games.filter {
                    $0.tier == .college && $0.stage != .regularSeason
                }.prefix(64).map { $0.id.uuidString })
            )
            expect(model.rankings.allSatisfy { $0.rank > 0 && !$0.team.name.isEmpty })
        }
    }

    suite("Read model provider: states nothing it cannot know") {
        test("the week plan exposes the four state-backed management lanes") {
            let (state, _) = try startedCareer(seed: 4_010)
            let plan = CoachWorldReadModelProvider.coachingHQ(from: state)?.weekPlan ?? []
            expectEqual(plan.count, 4)
            expectEqual(plan.map(\.dayLabel), ["Inbox", "Game plan", "Practice", "Recruiting"])
        }

        test("a bye week does not invent preparation that the engine refuses") {
            var state = try startedCareer(seed: 4_010).0
            let programmeID = state.career.college!.programmeID
            state.competition.currentSchedule = SeasonSchedule(
                season: state.competition.currentSchedule.season,
                games: state.competition.currentSchedule.games.filter {
                    !($0.season == state.calendar.season
                        && $0.week == state.calendar.week
                        && ($0.homeID == programmeID || $0.awayID == programmeID))
                }
            )
            let model = CoachWorldReadModelProvider.coachingHQ(from: state)
            expectEqual(model?.opponent, nil)
            expect(model?.weekPlan.allSatisfy { !$0.isCurrent } == true)
            _ = try IntentResolver.resolve(.advanceWeek, in: state)
        }

        test("correspondence is empty because no inbox system exists") {
            let (state, _) = try startedCareer(seed: 4_011)
            expectEqual(CoachWorldReadModelProvider.coachingHQ(from: state)?.correspondence.count, 0)
            // The scheduler agrees: the step that would fill an inbox is inactive.
            let transition = try WorldScheduler.advanceWeek(state)
            expectEqual(
                transition.stepRecords.first { $0.step == .expiringInboundEvents }?.status,
                .inactive
            )
        }

        test("HQ does not invent a staff author or confidence for a system recommendation") {
            var state = try startedCareer(seed: 4_012).0
            guard let control = state.career.college,
                  let prospectID = state.prospects.ids.first else {
                expect(false, "the world generated no controlled programme or prospect")
                return
            }
            let recommendedID = UUID(uuidString: "00000000-0000-0000-0000-000000004012")!
            let alternateID = UUID(uuidString: "00000000-0000-0000-0000-000000004013")!
            _ = state.pending.enqueue(MandatoryDecision(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000004014")!,
                programmeID: control.programmeID,
                subject: .recruiting(prospectID: prospectID),
                createdAt: state.calendar,
                deadline: state.calendar,
                owner: .user,
                options: [
                    MandatoryDecisionOption(
                        id: recommendedID,
                        action: .recruiting(.offerScholarship)
                    ),
                    MandatoryDecisionOption(
                        id: alternateID,
                        action: .recruiting(.withdraw)
                    ),
                ],
                recommendedOptionID: recommendedID,
                reasons: [MandatoryDecisionReason(code: .rosterNeed, value: 3)]
            ))
            let model = CoachWorldReadModelProvider.coachingHQ(from: state)
            expectEqual(model?.staffRecommendation, nil)
            expect(model?.decision?.choices.allSatisfy { $0.cost == "No recorded cost" } == true)
            expect(model?.decision?.choices.allSatisfy(\.consequence.isEmpty) == true)
        }

        test("missing competition rows carry no invented rank or record") {
            var state = try startedCareer(seed: 4_013).0
            state.competition.rankings = [:]
            state.competition.standings = [:]
            let model = CoachWorldReadModelProvider.coachingHQ(from: state)
            expectEqual(model?.rankLabel, nil)
            expectEqual(model?.recordLabel, "Record unavailable")
        }
    }

    suite("Read model provider: decisions") {
        test("every obligation is a mandatory decision the root queued") {
            let (state, programme) = try startedCareer(seed: 4_020)
            guard let model = CoachWorldReadModelProvider.coachingHQ(from: state) else {
                expect(false, "a started career produced no coaching HQ")
                return
            }
            let queued = state.pending.mandatoryDecisions.filter { $0.programmeID == programme.id }
            expectEqual(model.obligations.count, queued.count)
            expectEqual(Set(model.obligations.map(\.stableID)),
                        Set(queued.map { $0.id.uuidString }))
            expect(model.obligations.allSatisfy(\.isMandatory),
                   "a queued decision that does not block the week is not mandatory")
        }

        test("a decision's choices are the root's own options, identifier for identifier") {
            var state = try startedCareer(seed: 4_021).0
            guard let control = state.career.college,
                  let prospectID = state.prospects.ids.first else {
                expect(false, "the world generated no prospects")
                return
            }
            let decisionID = UUID(uuidString: "00000000-0000-4000-8000-0000000004A0")!
            let offer = UUID(uuidString: "00000000-0000-4000-8000-0000000004A1")!
            let withdraw = UUID(uuidString: "00000000-0000-4000-8000-0000000004A2")!
            _ = state.pending.enqueue(MandatoryDecision(
                id: decisionID,
                programmeID: control.programmeID,
                subject: .recruiting(prospectID: prospectID),
                createdAt: state.calendar,
                deadline: state.calendar,
                owner: .user,
                options: [
                    MandatoryDecisionOption(id: offer, action: .recruiting(.offerScholarship)),
                    MandatoryDecisionOption(id: withdraw, action: .recruiting(.withdraw)),
                ],
                recommendedOptionID: offer,
                reasons: [MandatoryDecisionReason(code: .rosterNeed, value: 3)]
            ))

            guard let decision = CoachWorldReadModelProvider.coachingHQ(from: state)?.decision else {
                expect(false, "a queued user decision produced no decision surface")
                return
            }
            expectEqual(decision.stableID, decisionID.uuidString)
            expectEqual(decision.choices.map(\.intentID.rawValue),
                        [offer.uuidString, withdraw.uuidString])
            expectEqual(decision.choices.map(\.title), ["Offer scholarship", "Withdraw"])
            expect(decision.title.contains(state.prospects[prospectID]?.fullName ?? "?"),
                   "a decision must name the person it is about")
            expectEqual(decision.evidence, ["Roster need: 3"])
        }

        test("a delegated decision produces an obligation but no decision surface") {
            var state = try startedCareer(seed: 4_022).0
            guard let control = state.career.college,
                  let programme = state.programmes[control.programmeID],
                  let delegate = programme.staffIDs.first(where: {
                      state.staff[$0]?.role != .headCoach
                  }),
                  let prospectID = state.prospects.ids.first else {
                expect(false, "the world generated no delegate or prospect")
                return
            }
            let decisionID = UUID(uuidString: "00000000-0000-4000-8000-0000000004B0")!
            _ = state.pending.enqueue(MandatoryDecision(
                id: decisionID,
                programmeID: control.programmeID,
                subject: .recruiting(prospectID: prospectID),
                createdAt: state.calendar,
                deadline: state.calendar,
                owner: .delegated(staffID: delegate),
                options: [
                    MandatoryDecisionOption(
                        id: UUID(uuidString: "00000000-0000-4000-8000-0000000004B1")!,
                        action: .recruiting(.offerScholarship)
                    ),
                    MandatoryDecisionOption(
                        id: UUID(uuidString: "00000000-0000-4000-8000-0000000004B2")!,
                        action: .recruiting(.withdraw)
                    ),
                ],
                recommendedOptionID: UUID(uuidString: "00000000-0000-4000-8000-0000000004B1")!,
                reasons: [MandatoryDecisionReason(code: .deadline, value: 1)]
            ))

            let model = CoachWorldReadModelProvider.coachingHQ(from: state)
            expect(model?.obligations.contains { $0.stableID == decisionID.uuidString } ?? false,
                   "a delegated decision still blocks the week and must be visible")
            expectEqual(model?.decision, nil)
            expectEqual(CoachWorldReadModelProvider.roster(from: state)?.canContinue, false)
            expectEqual(CoachWorldReadModelProvider.recruitingBoard(from: state)?.canContinue, false)
        }
    }

    suite("Read model provider: practice budget") {
        test("an unplanned week offers the whole budget") {
            let (state, _) = try startedCareer(seed: 4_030)
            expectEqual(
                CoachWorldReadModelProvider.coachingHQ(from: state)?.unallocatedPracticeMinutes,
                TacticalPracticePlan.weeklyMinutes
            )
        }

        test("last week's plan does not spend this week's budget") {
            let (state, programme) = try startedCareer(seed: 4_031)
            let planned = try IntentResolver.resolve(
                .practicePlan(TacticalPracticePlanRequest(
                    organisationID: programme.id,
                    calendar: state.calendar,
                    plan: .balanced
                )),
                in: state
            ).state
            expectEqual(
                CoachWorldReadModelProvider.coachingHQ(from: planned)?.unallocatedPracticeMinutes,
                0
            )

            var laterWeek = planned
            laterWeek.calendar = planned.calendar.advancedWeek()
            expectEqual(
                CoachWorldReadModelProvider.coachingHQ(from: laterWeek)?
                    .unallocatedPracticeMinutes,
                TacticalPracticePlan.weeklyMinutes
            )
        }
    }

    suite("Read model provider: personnel") {
        test("the roster is the programme's own, numbered and accounted for") {
            let (state, programme) = try startedCareer(seed: 4_050)
            guard let model = CoachWorldReadModelProvider.roster(from: state) else {
                expect(false, "a started career produced no roster")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.players.count, programme.rosterIDs.count)
            expectEqual(Set(model.players.map(\.stableID)),
                        Set(programme.rosterIDs.map(\.uuidString)))
            // Per unit, per `02` §4.1a — 105 players do not fit in 100 numbers.
            for unit in Unit.allCases {
                let inUnit = model.players.filter { row in
                    state.players[UUID(uuidString: row.stableID)!]?.position.unit == unit
                }
                expectEqual(Set(inUnit.map(\.number)).count, inUnit.count,
                            "\(unit.rawValue) shows two players wearing one number")
            }
            expectEqual(model.rosterLimit, CollegeRules.rosterLimit)
            expectEqual(
                model.injuryCount,
                programme.rosterIDs.filter { state.people.playerLifecycle[$0]?.injury != nil }.count
            )
            // Every row's overall is the engine's, not a second scale invented for display.
            for row in model.players {
                let player = state.players[UUID(uuidString: row.stableID)!]
                expectEqual(row.overall, player?.overall.value)
                expectEqual(row.person.name, player?.fullName)
                expectEqual(row.development, 0,
                            "production roster must not treat a development delta as a rating")
                let maximumDelta = PeopleRules.maximumAttributeChangesPerSummary
                    * max(abs(PeopleRules.attributeDevelopmentRange.lowerBound),
                          abs(PeopleRules.attributeDevelopmentRange.upperBound))
                expect(row.developmentDelta.map { (-maximumDelta...maximumDelta).contains($0) } ?? true,
                       "retained development evidence must stay within the engine delta bounds")
            }
        }

        test("a profile states nothing the root does not hold") {
            let (state, programme) = try startedCareer(seed: 4_051)
            guard let playerID = programme.rosterIDs.first,
                  let model = CoachWorldReadModelProvider.playerProfile(playerID, in: state),
                  let player = state.players[playerID] else {
                expect(false, "a rostered player produced no profile")
                return
            }
            expectEqual(model.person.name, player.fullName)
            // G-04 has no form series and G-02 no staff verdict, so both ship empty rather than
            // invented. The hometown is the same: the root records a *prospect's* origin city, not
            // a rostered player's.
            expectEqual(model.recentForm.count, 0)
            expectEqual(model.staffSummary, "")
            expectEqual(model.hometown, "")
            expectEqual(model.developmentEvidence, "No recorded development change in this snapshot.")
            expectEqual(
                model.historyEvidence,
                "No completed game history is retained in this season's schedule."
            )
            // Every attribute shown is one this position is actually rated on.
            let shown = Set(model.attributeGroups.flatMap { $0.attributes }.map(\.label))
            let rated = Set(player.position.ratedAttributes.map(\.label))
            expect(shown.isSubset(of: rated),
                   "the profile shows attributes the position is not rated on: "
                       + shown.subtracting(rated).sorted().joined(separator: ", "))
            expect(!shown.isEmpty, "the profile showed no attributes at all")
        }

        test("a professional appointment exposes the team's active roster") {
            var state = GameState.bootstrap(seed: 4_054)
            guard let team = state.proTeams.values.sorted(by: { $0.id.uuidString < $1.id.uuidString }).first,
                  let coachID = team.staffIDs.first,
                  let playerID = team.rosterIDs.first else {
                expect(false, "the generated world has no professional roster fixture")
                return
            }
            state.career = CareerControlState(coachID: coachID)
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: team.id,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )

            guard let model = CoachWorldReadModelProvider.roster(from: state),
                  let profile = CoachWorldReadModelProvider.playerProfile(playerID, in: state) else {
                expect(false, "a professional appointment produced no roster/profile")
                return
            }
            expectEqual(model.team.stableID, team.id.uuidString)
            expectEqual(model.players.count, team.rosterIDs.count + team.practiceSquadIDs.count)
            expectEqual(model.rosterLimit, ProRules.activeRosterLimit + ProRules.practiceSquadLimit)
            expectEqual(profile.rosterRole, "Active roster")
            expectEqual(profile.person.name, state.players[playerID]?.fullName)
        }

        test("no career produces no roster and no profile") {
            let world = GameState.bootstrap(seed: 4_052)
            expectEqual(CoachWorldReadModelProvider.roster(from: world), nil)
            guard let anyPlayerID = world.players.ids.first else { return }
            expectEqual(CoachWorldReadModelProvider.playerProfile(anyPlayerID, in: world), nil)
        }

        test("a player outside the controlled roster has no profile") {
            let (state, programme) = try startedCareer(seed: 4_053)
            guard let outsiderID = state.players.ids.first(where: {
                !programme.rosterIDs.contains($0)
            }) else {
                expect(false, "every player in the world is on the controlled roster")
                return
            }
            expectEqual(CoachWorldReadModelProvider.playerProfile(outsiderID, in: state), nil)
        }

        test("suspension is visible as unavailable on roster and profile") {
            var state = try startedCareer(seed: 4_055).0
            guard let playerID = state.career.college.flatMap({
                state.programmes[$0.programmeID]?.rosterIDs.first
            }) else {
                expect(false, "the controlled roster has no player")
                return
            }
            _ = state.people.updatePlayerLifecycle(playerID) {
                $0.suspend(PlayerSuspension(
                    reason: .conduct,
                    occurredAt: state.calendar,
                    originalWeeks: 2,
                    weeksRemaining: 2
                ))
            }
            let row = CoachWorldReadModelProvider.roster(from: state)?.players.first {
                $0.stableID == playerID.uuidString
            }
            expectEqual(row?.availability, "Suspended 2 week(s)")
            expectEqual(
                CoachWorldReadModelProvider.playerProfile(playerID, in: state)?.availability,
                "Suspended 2 week(s)"
            )
        }

        test("signed prospects expose no invalid recruiting actions") {
            var state = try startedCareer(seed: 4_056).0
            guard let control = state.career.college,
                  let programme = state.programmes[control.programmeID],
                  let prospectID = state.prospects.ids.first,
                  let recruiting = state.college.programmes[programme.id] else {
                expect(false, "the generated world has no recruiting fixture")
                return
            }
            let calendar = CalendarState(season: state.calendar.season, week: CollegeRules.minimumCommitmentWeek)
            state.calendar = calendar
            let contender = RecruitingCommitmentContenderContext(
                programmeID: programme.id,
                score: CollegeRules.minimumCommitmentScore,
                explanation: [],
                relationshipInterest: CollegeRules.minimumCommitmentScore,
                nilAllocation: 0,
                visitScheduled: false
            )
            let recruitment = ProspectRecruitmentState(
                prospectID: prospectID,
                phase: .signed,
                commitmentHistory: [RecruitingCommitmentContext(
                    committedAt: calendar,
                    winner: contender
                )]
            )
            let relationship = ProgrammeProspectRelationship(prospectID: prospectID)
            let board = ProgrammeRecruitingState(
                programmeID: programme.id,
                boardIDs: [prospectID],
                relationships: [prospectID: relationship],
                scholarshipPlayerIDs: recruiting.scholarshipPlayerIDs,
                contactPointsRemaining: recruiting.contactPointsRemaining,
                nilState: recruiting.nilState
            )
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: .active,
                programmes: [programme.id: board],
                prospectRecruitment: [prospectID: recruitment],
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: state.college.redshirtPlans
            )
            let choices = CoachWorldReadModelProvider.recruitingBoard(from: state)?.prospects
                .first?.choices ?? []
            expect(!choices.isEmpty, "the signed prospect should retain a bounded action explanation")
            expect(choices.allSatisfy { !$0.isAvailable && $0.unavailableReason != nil },
                   "a signed prospect exposed an enabled or unexplained action")

            state.college.phase = .signing
            let closedChoices = CoachWorldReadModelProvider.recruitingBoard(from: state)?.prospects
                .first?.choices ?? []
            let withdraw = closedChoices.first { $0.intentID.rawValue == "withdraw" }
            expect(withdraw?.isAvailable == false,
                   "withdraw must remain disabled outside the active recruiting phase")
            expectEqual(withdraw?.unavailableReason, "Recruiting is not open in this phase")

            var missingRelationship = state
            missingRelationship.college.phase = .active
            var missingProgrammes = missingRelationship.college.programmes
            missingProgrammes[programme.id] = ProgrammeRecruitingState(
                programmeID: programme.id,
                boardIDs: [prospectID],
                relationships: [:],
                scholarshipPlayerIDs: recruiting.scholarshipPlayerIDs,
                contactPointsRemaining: recruiting.contactPointsRemaining,
                nilState: recruiting.nilState
            )
            missingRelationship.college = CollegeState(
                recruitingSeason: missingRelationship.college.recruitingSeason,
                portal: missingRelationship.college.portal,
                phase: .active,
                programmes: missingProgrammes,
                prospectRecruitment: missingRelationship.college.prospectRecruitment,
                archivedProspects: missingRelationship.college.archivedProspects,
                redshirtPlans: missingRelationship.college.redshirtPlans
            )
            let missingChoices = CoachWorldReadModelProvider.recruitingBoard(
                from: missingRelationship
            )?.prospects.first?.choices ?? []
            expect(missingChoices.allSatisfy { !$0.isAvailable && $0.unavailableReason ==
                "This prospect is not on this programme's board" },
                   "a board row without a relationship exposed actions the engine rejects")

            var portalBoundary = state
            let portalTargetSeason = max(1, portalBoundary.college.recruitingSeason)
            portalBoundary.college = CollegeState(
                recruitingSeason: portalTargetSeason,
                portal: CollegePortalState(
                    targetSeason: portalTargetSeason,
                    phase: .awaitingSpring,
                    summaries: [CollegePortalWindowSummary(
                        targetSeason: portalTargetSeason,
                        window: .postseason,
                        completedAt: CalendarState(
                            season: portalTargetSeason - 1,
                            week: SharedRules.inSeasonWeeks
                        ),
                        entrantCount: 0,
                        retainedCount: 0,
                        transferredCount: 0,
                        returnedCount: 0,
                        offerCount: 0
                    )]
                ),
                phase: .active,
                programmes: portalBoundary.college.programmes,
                prospectRecruitment: portalBoundary.college.prospectRecruitment,
                archivedProspects: portalBoundary.college.archivedProspects,
                redshirtPlans: portalBoundary.college.redshirtPlans
            )
            let portalChoices = CoachWorldReadModelProvider.recruitingBoard(
                from: portalBoundary
            )?.prospects.first?.choices ?? []
            expect(portalChoices.allSatisfy { !$0.isAvailable && $0.unavailableReason ==
                "Recruiting is paused for the spring portal transaction" },
                   "the spring portal boundary exposed recruiting actions the engine rejects")
        }
    }

    suite("Read model provider: recruiting board") {
        test("the board is the programme's own, in its own rank order") {
            let (state, programme) = try startedCareer(seed: 4_060)
            guard let recruiting = state.college.programmes[programme.id],
                  let model = CoachWorldReadModelProvider.recruitingBoard(from: state) else {
                expect(false, "a started career produced no recruiting board")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.prospects.map(\.stableID),
                        recruiting.boardIDs.map(\.uuidString))
            expectEqual(model.prospects.map(\.boardRank), Array(model.prospects.indices.map {
                $0 + 1
            }))
            expectEqual(
                model.capacity.scholarshipSlotsRemaining,
                CollegeRules.scholarshipLimit - programme.scholarshipCount
            )
        }

        test("a prospect signed by a rival programme reads as elsewhere, not this "
            + "programme's own") {
            // Phase 4 review, 2026-08-20: statusLabel's .signed arm returned a bare "Signed"
            // with no ownership check, so a rival's signed prospect left on this programme's
            // board was indistinguishable from an actual own signee and inflated
            // ClassOverviewView's committed count. This reproduces the real, reachable shape of
            // the bug rather than a hand-built fixture: CollegeRecruitingAISystem.process(in:)
            // explicitly excludes the career-controlled programme from its own lost-pursuit
            // cleanup, so nothing but an explicit Withdraw ever prunes this board, and this test
            // never calls that system at all.
            var (state, careerProgramme) = try startedCareer(seed: 4_070)
            guard let rivalProgrammeID = state.programmes.ids.first(where: {
                $0 != careerProgramme.id
            }), let prospectID = state.prospects.ids.first else {
                expect(false, "a started career produced no rival programme or prospect to use")
                return
            }

            let addToBoard = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: careerProgramme.id, prospectID: prospectID, action: .addToBoard
                ),
                in: state
            )
            state.college = addToBoard.college
            state.scouting = addToBoard.scouting
            expect(state.college.programmes[careerProgramme.id]!.boardIDs.contains(prospectID),
                   "the prospect never landed on the career programme's own board")

            state.calendar = CalendarState(
                season: state.calendar.season, week: CollegeRules.minimumCommitmentWeek
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
                        programmeID: rivalProgrammeID, prospectID: prospectID, action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            let market = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
            expectEqual(market.commitments.first?.programmeID, rivalProgrammeID,
                        "the rival programme did not win the commitment this test needs")
            state.college = market.college

            // A fresh bootstrap's roster already sits at capacity, so CollegeSigningSystem would
            // release this commitment for want of a roster/scholarship vacancy rather than sign
            // it -- a real gate this test needs to clear, not something to route around. Frees
            // exactly one slot by removing a player from the rival's single largest position
            // group, which by construction sits well above SharedRules.minimumPlayableRosterByPosition's
            // floor for every position (roster limit 105 against per-position floors of 1-3 across
            // fifteen positions), so this cannot trip the minimum-position-coverage gate the way an
            // arbitrarily chosen position could.
            let rivalRoster = state.programmes[rivalProgrammeID]!.rosterIDs
            let rivalPositionCounts = Dictionary(
                grouping: rivalRoster.compactMap { state.players[$0]?.position }, by: { $0 }
            ).mapValues(\.count)
            guard let deepestPosition = rivalPositionCounts.max(by: { $0.value < $1.value })?.key,
                  let departingID = rivalRoster.first(where: {
                      state.players[$0]?.position == deepestPosition
                  }) else {
                expect(false, "could not find a rival roster player to free capacity with")
                return
            }
            state.programmes.update(rivalProgrammeID) {
                $0.rosterIDs.removeAll { $0 == departingID }
                $0.scholarshipCount -= 1
            }
            state.college.reconcileScholarships(with: state.programmes)

            let signing = try CollegeSigningSystem.signCommitted(in: state)
            expect(
                signing.resolutions.contains { $0.prospectID == prospectID && $0.outcome == .signed },
                "the rival programme's commitment did not resolve to signed"
            )
            state.programmes = signing.programmes
            state.players = signing.players
            state.people = signing.people
            state.college = signing.college

            expect(state.college.programmes[careerProgramme.id]!.boardIDs.contains(prospectID),
                   "the prospect left the career programme's board on its own -- this test's "
                       + "premise (nothing but Withdraw prunes it) no longer holds")

            guard let model = CoachWorldReadModelProvider.recruitingBoard(from: state),
                  let row = model.prospects.first(where: { $0.stableID == prospectID.uuidString })
            else {
                expect(false, "the signed-elsewhere prospect did not resolve to a board row")
                return
            }
            expectEqual(row.status, "Signed elsewhere")
            expect(!row.isCommitted,
                   "a rival's signee counted toward this programme's own committed figure")
            let withdraw = row.choices.first { $0.intentID == CoachWorldIntentID(rawValue: "withdraw") }
            expect(withdraw?.isAvailable == true,
                   "a coach can no longer clear a rival's signee off their own board")
        }

        test("discovery exposes an untracked prospect and add-to-board consumes it") {
            let (state, programme) = try startedCareer(seed: 4_068)
            guard let before = CoachWorldReadModelProvider.recruitingBoard(from: state),
                  let prospect = before.discovery.first,
                  let prospectID = UUID(uuidString: prospect.stableID) else {
                expect(false, "a started career produced no discoverable prospect")
                return
            }
            let add = prospect.choices.first { $0.intentID.rawValue == "addToBoard" }
            expect(add?.isAvailable == true, "a current discovery prospect was not addable")
            expectEqual(
                CoachWorldReadModelProvider.recruitingAction(
                    for: CoachWorldIntentID(rawValue: "addToBoard")
                ),
                .addToBoard
            )

            let resolved = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: programme.id,
                    prospectID: prospectID,
                    action: .addToBoard
                )),
                in: state
            ).state
            guard let after = CoachWorldReadModelProvider.recruitingBoard(from: resolved) else {
                expect(false, "the recruiting board disappeared after add-to-board")
                return
            }
            expect(after.prospects.contains { $0.stableID == prospect.stableID },
                   "added discovery prospect was not placed on the board")
            expect(!after.discovery.contains { $0.stableID == prospect.stableID },
                   "added discovery prospect remained discoverable")
        }

        test("weekly capacity reads the engine's own contact-points pool") {
            let (state, programme) = try startedCareer(seed: 4_061)
            guard let recruiting = state.college.programmes[programme.id],
                  let model = CoachWorldReadModelProvider.recruitingBoard(from: state) else {
                expect(false, "a started career produced no recruiting board")
                return
            }
            expectEqual(model.capacity.weeklyHoursRemaining, recruiting.contactPointsRemaining)
            // Freshly bootstrapped and never spent against, so this is the full weekly pool.
            expectEqual(model.capacity.weeklyHoursRemaining, CollegeRules.weeklyRecruitingContactPoints)
            expectEqual(
                model.capacity.officialVisitsRemaining,
                recruiting.contactPointsRemaining / CollegeRules.visitContactCost
            )
        }

        test("spending contact points moves the capacity the provider shows") {
            // The board starts empty at week one for the *controlled* programme specifically —
            // confirmed on the simulator ("No prospects on the board") — because
            // `CollegeRecruitingAISystem` explicitly excludes the controlled programme from its
            // own weekly board growth (`state.programmes.ids.filter { $0 != controlledProgrammeID
            // }`); AI board growth is what the other ~133 programmes get, not the player's.
            // `addToBoard` is resolved directly here to set up a fixture, the same way other
            // fixtures in this suite build state through the engine rather than by hand.
            let (state, programme) = try startedCareer(seed: 4_066)
            guard let prospectID = state.prospects.ids.first else {
                expect(false, "the world generated no prospects at all")
                return
            }
            let boarded = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: programme.id,
                    prospectID: prospectID,
                    action: .addToBoard
                )),
                in: state
            ).state
            let resolved = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: programme.id,
                    prospectID: prospectID,
                    action: .contact(points: CollegeRules.aiEvaluationContactPoints)
                )),
                in: boarded
            )
            guard let before = CoachWorldReadModelProvider.recruitingBoard(from: boarded),
                  let after = CoachWorldReadModelProvider.recruitingBoard(from: resolved.state)
            else {
                expect(false, "the board disappeared across a legal recruiting action")
                return
            }
            expectEqual(
                after.capacity.weeklyHoursRemaining,
                before.capacity.weeklyHoursRemaining - CollegeRules.aiEvaluationContactPoints
            )
        }

        test("known recruiting resource limits disable actions with a reason") {
            let (state, programme) = try startedCareer(seed: 4_067)
            guard let prospectID = state.prospects.ids.first else { return }
            var drained = try IntentResolver.resolve(
                .recruiting(RecruitingActionRequest(
                    programmeID: programme.id,
                    prospectID: prospectID,
                    action: .addToBoard
                )),
                in: state
            ).state
            while drained.college.programmes[programme.id]?.contactPointsRemaining ?? 0
                >= CollegeRules.aiEvaluationContactPoints {
                drained = try IntentResolver.resolve(
                    .recruiting(RecruitingActionRequest(
                        programmeID: programme.id,
                        prospectID: prospectID,
                        action: .contact(points: CollegeRules.aiEvaluationContactPoints)
                    )),
                    in: drained
                ).state
            }
            guard let prospect = CoachWorldReadModelProvider.recruitingBoard(from: drained)?
                .prospects.first(where: { $0.stableID == prospectID.uuidString }),
                  let contact = prospect.choices.first(where: { $0.intentID.rawValue == "contact" }) else {
                expect(false, "the boarded prospect disappeared after legal contact actions")
                return
            }
            expect(!contact.isAvailable)
            expect(contact.unavailableReason?.contains("contact points") == true)
        }

        test("no career produces no board") {
            expectEqual(
                CoachWorldReadModelProvider.recruitingBoard(from: GameState.bootstrap(seed: 4_062)),
                nil
            )
        }

        test("a board prospect with no commitment record reads as uncommitted") {
            // The reachable case: freshly generated prospects carry no `prospectRecruitment`
            // entry at all, and the provider must read that as "Uncommitted" rather than as
            // absence of a fact. The other three phases (`committed`, `signed`, `released`) are
            // exercised end to end by `CollegeCommitmentTests`; constructing one here would mean
            // hand-building a `RecruitingCommitmentContext` through a module-internal initialiser
            // this target cannot reach without `@testable`, which `GenerationTests` already
            // documents as a deliberate import boundary.
            let (state, _) = try startedCareer(seed: 4_063)
            guard let model = CoachWorldReadModelProvider.recruitingBoard(from: state),
                  let prospect = model.prospects.first else {
                // A board that starts empty is a legitimate world; nothing to check against.
                return
            }
            expectEqual(prospect.status, "Uncommitted")
        }

        test("every choice maps back to a real RecruitingAction") {
            let (state, _) = try startedCareer(seed: 4_064)
            guard let model = CoachWorldReadModelProvider.recruitingBoard(from: state),
                  let prospect = model.prospects.first else {
                // No board entries is legitimate at week one for some seeds.
                return
            }
            expect(!prospect.choices.isEmpty, "a board prospect offered no actions at all")
            for choice in prospect.choices {
                expect(CoachWorldReadModelProvider.recruitingAction(for: choice.intentID) != nil,
                       "\(choice.intentID.rawValue) does not map to a RecruitingAction")
            }
        }

        test("an unmapped intent identifier resolves to no action") {
            expectEqual(
                CoachWorldReadModelProvider.recruitingAction(
                    for: CoachWorldIntentID(rawValue: "not-a-real-action")
                ),
                nil
            )
        }

        testAsync("committing a recruiting choice resolves it and refreshes the board") {
            let (state, _) = try startedCareer(seed: 4_065)
            let session = try CareerSession(state: state)
            guard let before = CoachWorldReadModelProvider
                .recruitingBoard(from: await session.snapshot()),
                let prospect = before.prospects.first,
                let choice = prospect.choices.first(where: { $0.intentID.rawValue == "contact" })
            else {
                // No board entries or delegated responsibility at week one is a legitimate start
                // state; the resolved-decision path is exercised by the fixture above instead.
                return
            }
            guard let action = CoachWorldReadModelProvider.recruitingAction(for: choice.intentID),
                  let prospectID = UUID(uuidString: prospect.stableID) else {
                expect(false, "the mapped action or prospect identifier was invalid")
                return
            }
            _ = try await session.resolve(.recruiting(
                prospectID: prospectID,
                action: action
            ))
            let after = CoachWorldReadModelProvider.recruitingBoard(from: await session.snapshot())
            expect(after != before, "the board did not change after a contact action resolved")
        }
    }

    // `CoachWorldStore` itself is deliberately absent from this suite. It is `@MainActor`, and
    // `TestKit.testAsync` blocks the calling thread on a semaphore — a hop back to the main actor
    // deadlocks, as the harness's own comment says. So what is asserted here is everything the
    // store delegates to: the session that owns the world, the provider that renders it, and the
    // file the save lands in. The store adds no rule of its own beyond wiring those three.
    suite("Career session and save") {
        testAsync("a career saves and reloads to the same screen") {
            let (state, _) = try startedCareer(seed: 4_040)
            let session = try CareerSession(state: state)
            let before = CoachWorldReadModelProvider.coachingHQ(from: await session.snapshot())
            expectEqual(before?.provenance, .simulationSnapshot)

            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-4040-\(UUID().uuidString)", isDirectory: true)
            let saves = CoachWorldSaveStore(directory: directory)
            defer { try? FileManager.default.removeItem(at: directory) }

            expect(!saves.hasSave, "a fresh directory reported an existing save")
            try saves.write(await session.saveData())
            expect(saves.hasSave, "the save was written but not found")

            let restored = try CareerSession(
                state: SaveEnvelope.decode(GameState.self, from: saves.read())
            )
            expectEqual(
                CoachWorldReadModelProvider.coachingHQ(from: await restored.snapshot()),
                before
            )
        }

        testAsync("advancing a week moves the screen's week with it") {
            let (state, _) = try startedCareer(seed: 4_041)
            let session = try CareerSession(state: state)
            guard let before = CoachWorldReadModelProvider
                .coachingHQ(from: await session.snapshot()) else {
                expect(false, "a started career produced no coaching HQ")
                return
            }
            guard (try? await session.resolve(.advanceWeek)) != nil else {
                // An open mandatory decision legitimately refuses the advance; that path is the
                // decision suite's business, not this one's.
                return
            }
            let after = CoachWorldReadModelProvider.coachingHQ(from: await session.snapshot())
            expectEqual(after?.week.weekLabel, "Week 2")
            expect(after?.snapshotID != before.snapshotID,
                   "the snapshot identifier did not move with the week")
        }
    }

    suite("Read model provider: league map") {
        test("every place is a real member standing on its own generated city") {
            let (state, _) = try startedCareer(seed: 4_070)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            expectEqual(model.provenance, .simulationSnapshot)
            expectEqual(model.gridWidth, GameMap.width)
            expectEqual(model.gridHeight, GameMap.height)
            expectEqual(model.regions.count, GameMap.regionCount)
            // Every member of both tiers, and nothing else.
            expectEqual(model.places.count, state.programmes.count + state.proTeams.count)
            expectEqual(
                Set(model.places.map(\.stableID)),
                Set(state.programmes.ids.map(\.uuidString))
                    .union(state.proTeams.ids.map(\.uuidString))
            )

            for place in model.places {
                guard let id = UUID(uuidString: place.stableID) else {
                    expect(false, "\(place.team.name) carries an unparseable identifier")
                    continue
                }
                // The identifier join, not the name join: the city is the one the identity names.
                guard let identity = state.identities[id],
                      let city = state.map.city(identity.homeCityID) else {
                    expect(false, "\(place.team.name) resolved to no city")
                    continue
                }
                expectEqual(place.x, city.x)
                expectEqual(place.y, city.y)
                expectEqual(place.cityName, city.name)
                expectEqual(place.marketSize, city.marketSize.value)
                expectEqual(place.venueName, identity.venueName)
                expect((0...GameMap.width).contains(place.x),
                       "\(place.cityName) sits off the grid at x \(place.x)")
                expect((0...GameMap.height).contains(place.y),
                       "\(place.cityName) sits off the grid at y \(place.y)")
                expectEqual(place.regionID, city.regionID.uuidString)
                expectEqual(
                    place.regionName,
                    state.map.regions.first { $0.id == city.regionID }?.name ?? "Region not set"
                )
                expect(place.regionName != "Region not set",
                       "\(place.cityName) resolved to no region")

                let ownerConferenceID = state.programmes[id]?.conferenceID
                    ?? state.proTeams[id]?.conferenceID
                expectEqual(
                    place.conferenceName,
                    ownerConferenceID.flatMap { conferenceID in
                        state.league.conferences.first { $0.id == conferenceID }?.name
                    },
                    "\(place.team.name)'s conference does not match the one it actually belongs to"
                )
            }
        }

        test("no two places share a point, and one place is the controlled programme") {
            let (state, programme) = try startedCareer(seed: 4_071)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            // One city per member is a generation property — `LeagueGenerator` walks a single
            // cursor across a 166-city map. Asserting it here is what would catch a provider that
            // resolved two members to one city and drew them on top of each other.
            let coordinates = model.places.map { "\($0.x),\($0.y)" }
            expectEqual(Set(coordinates).count, coordinates.count,
                        "two members were placed on one point")
            expectEqual(model.places.filter(\.isControlled).count, 1)
            expectEqual(model.places.first(where: \.isControlled)?.stableID,
                        programme.id.uuidString)
            // Both tiers are present, and every place is one of the two.
            let tiers = Set(model.places.map(\.tierLabel))
            expectEqual(tiers, [LeagueMapReadModel.Tier.college,
                                LeagueMapReadModel.Tier.professional])
            expectEqual(
                model.places.filter { $0.tierLabel == LeagueMapReadModel.Tier.college }.count,
                state.programmes.count
            )
        }

        test("rivals are the engine's own strongest, and never cross a tier") {
            let (state, _) = try startedCareer(seed: 4_072)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            let rivalries = state.rivalries.values
            let tierByID = Dictionary(
                uniqueKeysWithValues: model.places.map { ($0.stableID, $0.tierLabel) }
            )
            for place in model.places {
                guard let id = UUID(uuidString: place.stableID) else { continue }
                let expected = RivalrySeeder.strongest(for: id, among: rivalries)
                expectEqual(place.rivals.map(\.stableID), expected.map(\.uuidString),
                            "\(place.team.name) shows a rival order the engine did not choose")
                expect(place.rivals.count <= SharedRules.rivalriesPerProgramme,
                       "\(place.team.name) shows \(place.rivals.count) rivals, above the bound")
                for rival in place.rivals {
                    guard let otherID = UUID(uuidString: rival.stableID) else { continue }
                    guard let rivalry = rivalries.first(where: {
                        $0.involves(id) && $0.involves(otherID)
                    }) else {
                        expect(false, "\(rival.name) is not a recorded rivalry")
                        continue
                    }
                    expectEqual(rival.intensity, rivalry.intensity.value)
                    expectEqual(rival.name, model.places
                        .first { $0.stableID == rival.stableID }?.team.name)
                    // Rivalries are seeded within a tier, so a college place can never name a
                    // professional rival. A cross-tier rival would mean the provider matched two
                    // members the world never pairs.
                    expectEqual(tierByID[rival.stableID], place.tierLabel,
                                "\(place.team.name) names a rival from the other tier")
                    // `LeagueGenerator` seeds professional rivalries by passing each team's
                    // *division* id into the field college seeding fills with a real conference
                    // id (`conferenceID: team.divisionID`), so a professional `.conference`/`.both`
                    // origin means "same division" — a materially different, tighter group than
                    // the 16-team conference the place's own `conferenceName` already names.
                    // Wording it "Conference" would restate a bigger group under a smaller one's
                    // name on the same screen.
                    if place.tierLabel == LeagueMapReadModel.Tier.professional {
                        expect(!rival.originLabel.contains("Conference"),
                               "\(place.team.name)'s rival \(rival.name) is labelled "
                                   + "\"\(rival.originLabel)\" but professional rivalries share a "
                                   + "division, never the 16-team conference")
                    } else {
                        expect(!rival.originLabel.contains("Division"),
                               "\(place.team.name)'s rival \(rival.name) is labelled "
                                   + "\"\(rival.originLabel)\" but college has no divisions")
                    }
                }
            }
        }

        test("the map states nothing it cannot know") {
            let (state, _) = try startedCareer(seed: 4_073)
            guard let model = CoachWorldReadModelProvider.leagueMap(from: state) else {
                expect(false, "a started career produced no league map")
                return
            }
            // Each of these is empty because the engine holds nothing behind it. Filling one
            // requires deleting the assertion that names the gap which would justify it.
            for place in model.places {
                // No engine system reads `Programme.recruitingReach` — a full source scan finds it
                // only in its own initialiser and the D6 archetype falsifier — so there is no
                // grid-unit mapping to draw a radius from.
                expect(place.reachRadius == nil,
                       "\(place.team.name) claims a recruiting reach the engine never consumes")
                for rival in place.rivals {
                    // `Rivalry.notableMeetings` stores a zero-based season inside a formatted
                    // string, which would contradict the "Season N+1" labels beside it.
                    expect(rival.notableMeetings.isEmpty,
                           "a notable meeting was rendered with its zero-based season")
                }
            }
            // Regions have a name, members and a talent density — never an extent.
            for region in model.regions {
                expect(SharedRules.ratingRange.contains(region.talentDensity),
                       "\(region.name) reports a talent density off the rating scale")
                guard let source = state.map.regions
                    .first(where: { $0.id.uuidString == region.stableID }) else {
                    expect(false, "\(region.name) is not a region the map holds")
                    continue
                }
                expectEqual(region.name, source.name)
                expectEqual(region.talentDensity, source.talentDensity.value)
            }
        }

        test("the same seed builds the same map") {
            let (first, _) = try startedCareer(seed: 4_074)
            let (second, _) = try startedCareer(seed: 4_074)
            expectEqual(CoachWorldReadModelProvider.leagueMap(from: first),
                        CoachWorldReadModelProvider.leagueMap(from: second))
        }
    }
}

/// What the route map used to compute, kept here as the thing the cheap answer is measured against.
///
/// The switch is exhaustive on purpose. `availableScreens` answers each route from the root instead
/// of by building the screen, which is what took the route map from 1.59 s to 1 ms — and the price
/// of that is a second copy of each provider's guard. This table is what stops the copy drifting:
/// a new `CoachWorldScreenID` will not compile until someone says which model backs it, and the
/// suite below then holds the two answers together in every career shape.
///
/// `nil` means the registry number is an alias or an entry surface, so no route ever advertises it.
private func modelBackedAvailability(
    _ screen: CoachWorldScreenID,
    in state: GameState,
    selectedSubjectID: UUID? = nil
) -> Bool? {
    let provider = CoachWorldReadModelProvider.self
    switch screen {
    case .coachingHQ: return provider.coachingHQ(from: state) != nil
    case .inbox: return provider.inbox(from: state) != nil
    case .opponentReportFilmRoom: return provider.opponentFilm(from: state) != nil
    case .gamePlan: return provider.gamePlan(from: state) != nil
    case .practicePlan: return provider.practicePlan(from: state) != nil
    case .teamHealth: return provider.teamHealth(from: state) != nil
    case .matchDay: return provider.matchDay(from: state) != nil
    case .aftermath, .gameDetailBoxScore: return provider.aftermath(from: state) != nil
    case .roster, .developmentPlan: return provider.roster(from: state) != nil
    case .playerProfile: return provider.roster(from: state)?.players.isEmpty == false
    case .depthChart: return provider.depthChart(from: state) != nil
    case .staffRoom: return provider.staffRoom(from: state) != nil
    case .recruitingBoard, .prospectProfile, .shortlist, .contactVisitPlanner, .classOverview:
        return provider.recruitingBoard(from: state) != nil
    case .signingDay: return provider.collegeOffseason(from: state)?.cyclePhase == .signing
    case .collegeOffseason: return provider.collegeOffseason(from: state) != nil
    case .capContracts, .contractNegotiation, .rosterCutsTransactions:
        return provider.proManagement(from: state) != nil
    case .draftRoom: return provider.proOffseason(from: state)?.phase == .draft
    case .proOffseason: return provider.proOffseason(from: state) != nil
    case .leagueMap: return provider.leagueMap(from: state) != nil
    case .teamProgrammeProfile:
        let controlled = state.career.college?.programmeID
            ?? state.careerArc.currentJob?.organisationID
        guard let id = selectedSubjectID ?? controlled else { return false }
        return provider.teamProgrammeProfile(id, from: state) != nil
    case .standings:
        return provider.standings(
            tier: provider.controlledCompetitionTier(from: state),
            from: state
        ) != nil
    case .schedule:
        return provider.schedule(
            tier: provider.controlledCompetitionTier(from: state),
            from: state
        ) != nil
    case .rankingsPlayoffPicture, .bracketPostseason, .worldSearch: return true
    case .statisticsLeaders: return provider.statisticsLeaders(from: state) != nil
    case .awardsHonours: return provider.awardsHonours(from: state) != nil
    case .news: return provider.news(from: state) != nil
    case .realignmentEvent: return provider.realignment(from: state)?.event != nil
    case .careerHub, .stakeholders: return provider.careerHub(from: state) != nil
    case .promotionDecision:
        return provider.careerHub(from: state)?.opportunities.contains { $0.canAccept } == true
    case .recordBook, .rivalries, .careerLine, .coachingTree:
        return provider.legacyHistory(from: state) != nil
    case .titleContinue, .newCareerCoachIdentity, .jobBoard, .offer, .appointment,
         .settingsAccessibility, .staffMarketProfile, .schemeBook, .personnelPackages,
         .portalHub, .retentionDecisions, .portalMarket, .nilAllocation,
         .proScoutingBoard, .draftBoard, .freeAgency, .jobSecurity, .coachingCarousel:
        return nil
    }
}

func runAvailabilityProviderTests() {
    suite("Route availability") {
        let worlds: [(String, GameState)] = [
            ("no career", GameState.bootstrap(seed: 41_001)),
            ("college career", (try? startedCareer(seed: 41_002).0) ?? GameState.bootstrap(seed: 41_002)),
            ("professional career", (try? professionalCareer(seed: 41_003).0) ?? GameState.bootstrap(seed: 41_003))
        ]

        test("the cheap route map agrees with the models it replaced, on every screen") {
            for (label, state) in worlds {
                let available = CoachWorldReadModelProvider.availableScreens(from: state)
                for screen in CoachWorldScreenID.allCases {
                    guard let expected = modelBackedAvailability(screen, in: state) else {
                        expect(!available.contains(screen),
                               "\(label): \(screen.canonicalName) is an alias or entry surface and "
                                   + "must never be advertised as a route")
                        continue
                    }
                    expectEqual(available.contains(screen), expected,
                                "\(label): \(screen.canonicalName) availability disagrees with its "
                                    + "read model — a guard has drifted from the screen it gates")
                }
            }
        }

        test("a career with no coach advertises only the world surfaces") {
            let available = CoachWorldReadModelProvider.availableScreens(from: worlds[0].1)
            expectEqual(
                available.sorted { $0.rawValue < $1.rawValue },
                [.worldSearch, .standings, .schedule, .rankingsPlayoffPicture, .bracketPostseason]
                    .sorted { $0.rawValue < $1.rawValue }
            )
        }

        test("the route map is answered without building a screen") {
            // The regression this guards is the one that made every render cost 1.59 s: answering
            // "does this route exist" by building the model and testing it for nil. A world with a
            // full college career resolves the whole map faster than one recruiting board takes.
            let state = worlds[1].1
            let clock = ContinuousClock()
            let mapStarted = clock.now
            _ = CoachWorldReadModelProvider.availableScreens(from: state)
            let mapCost = mapStarted.duration(to: clock.now)
            let modelStarted = clock.now
            _ = CoachWorldReadModelProvider.recruitingBoard(from: state)
            let modelCost = modelStarted.duration(to: clock.now)
            expect(mapCost < modelCost,
                   "the route map cost \(mapCost) against \(modelCost) for a single screen, so it "
                       + "is building models again")
        }
    }
}
