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

func runReadModelProviderTests() {
    suite("Read model provider: identity") {
        test("no controlled career produces no coaching HQ") {
            expectEqual(
                CoachWorldReadModelProvider.coachingHQ(from: GameState.bootstrap(seed: 4_001)),
                nil
            )
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
            expectEqual(model.recordLabel, "\(row?.wins ?? 0)-\(row?.losses ?? 0)")
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
    }

    suite("Read model provider: states nothing it cannot know") {
        test("the week plan is empty because the calendar has no days") {
            let (state, _) = try startedCareer(seed: 4_010)
            expectEqual(CoachWorldReadModelProvider.coachingHQ(from: state)?.weekPlan.count, 0)
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

        test("no staff recommendation is shown while G-02 is unbuilt") {
            let (state, _) = try startedCareer(seed: 4_012)
            expectEqual(CoachWorldReadModelProvider.coachingHQ(from: state)?.staffRecommendation,
                        nil)
        }

        test("an unranked programme carries no rank rather than a placeholder") {
            var state = try startedCareer(seed: 4_013).0
            state.competition.rankings = [:]
            expectEqual(CoachWorldReadModelProvider.coachingHQ(from: state)?.rankLabel, nil)
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
            // Every attribute shown is one this position is actually rated on.
            let shown = Set(model.attributeGroups.flatMap { $0.attributes }.map(\.label))
            let rated = Set(player.position.ratedAttributes.map(\.label))
            expect(shown.isSubset(of: rated),
                   "the profile shows attributes the position is not rated on: "
                       + shown.subtracting(rated).sorted().joined(separator: ", "))
            expect(!shown.isEmpty, "the profile showed no attributes at all")
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
                .appendingPathComponent("pfc-save-4040", isDirectory: true)
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
}
