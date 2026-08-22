import Foundation
import FootballSimCore

/// Captures the root the weekly step loop had reached at one named checkpoint, so a test can
/// re-simulate from the state the scheduler itself simulated from rather than from the root the
/// week began on.
private final class KickoffStateRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var captured: GameState?
    private let checkpoint: String?

    /// Named by the step it comes *before*, and resolved through `WorldScheduler.steps`, so a step
    /// inserted ahead of kickoff moves this with it. Restating the predecessor by name would make
    /// the day someone reorders the week the day this silently measures the wrong root.
    init(before step: WorldStep) {
        let steps = WorldScheduler.steps
        checkpoint = steps.firstIndex(of: step)
            .flatMap { $0 > 0 ? "step.\(steps[$0 - 1].rawValue)" : nil }
    }

    var state: GameState? {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    func observe(_ label: String, state: GameState) {
        guard let checkpoint, label == checkpoint else { return }
        lock.lock()
        defer { lock.unlock() }
        captured = state
    }
}

func runTacticalStateTests() {
    suite("M4 tactical state") {
        test("weekly plans are calendar-bound, persistent, and deterministic") {
            let calendar = CalendarState(season: 0, week: 1)
            let organisationID = UUID(uuidString: "00000000-0000-0000-0000-000000000451")!
            let plan = TacticalPlan(
                runPassBias: .passHeavy,
                tempo: .hurry,
                pressure: .attack
            )
            var tactical = TacticalState(calendar: calendar)
            expect(tactical.setPlan(plan, for: organisationID, at: calendar))
            expectEqual(tactical.plan(for: organisationID, at: calendar), plan)
            expect(!tactical.setPlan(plan, for: organisationID, at: calendar.advancedWeek()))
            expectEqual(
                try JSONDecoder.stable().decode(
                    TacticalState.self,
                    from: JSONEncoder.stable().encode(tactical)
                ),
                tactical
            )
        }

        test("practice plans persist and change development contribution by focus") {
            let calendar = CalendarState(season: 0, week: 8)
            let organisationID = UUID(uuidString: "00000000-0000-0000-0000-000000000452")!
            let quarterback = Player(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000453")!,
                firstName: "A",
                lastName: "Quarterback",
                position: .quarterback,
                age: 19,
                attributes: Attributes([
                    .speed: Rating(60),
                    .awareness: Rating(60),
                    .workEthic: Rating(60),
                    .schemeFit: Rating(60),
                    .accuracyShort: Rating(60),
                    .accuracyMid: Rating(60),
                    .accuracyDeep: Rating(60),
                    .armStrength: Rating(60),
                    .decision: Rating(60),
                    .poise: Rating(60)
                ]),
                potential: Rating(80),
                eligibility: Eligibility(seasonsRemaining: 4, yearsRemaining: 5)
            )
            let plan = TacticalPracticePlan(
                installMinutes: 0,
                conditioningMinutes: 15,
                recoveryMinutes: 15,
                positionFocusMinutes: 30,
                positionFocus: .quarterbacks
            )
            var tactical = TacticalState(calendar: calendar)
            expect(tactical.setPracticePlan(plan, for: organisationID, at: calendar))
            expectEqual(tactical.practicePlan(for: organisationID, at: calendar), plan)
            expectEqual(plan.developmentValue(for: quarterback), 2)
            expectEqual(
                try JSONDecoder.stable().decode(
                    TacticalState.self,
                    from: JSONEncoder.stable().encode(tactical)
                ),
                tactical
            )
        }

        test("the committed practice effects are consumed once and retained as a receipt") {
            let calendar = CalendarState(season: 0, week: 8)
            let organisationID = UUID(uuidString: "00000000-0000-0000-0000-000000000454")!
            var tactical = TacticalState(calendar: calendar)
            let plan = TacticalPracticePlan(
                installMinutes: 15,
                conditioningMinutes: 30,
                recoveryMinutes: 15,
                positionFocusMinutes: 0,
                positionFocus: nil
            )
            expect(tactical.setPracticePlan(plan, for: organisationID, at: calendar))
            expectEqual(tactical.consumePracticePlan(for: organisationID, at: calendar), plan.effects)
            expectEqual(tactical.consumePracticePlan(for: organisationID, at: calendar), nil)
            expectEqual(
                try JSONDecoder.stable().decode(
                    TacticalState.self,
                    from: JSONEncoder.stable().encode(tactical)
                ),
                tactical
            )
        }

        test("observer film aggregates distinct games and expires after its bounded window") {
            let observerID = UUID(uuidString: "00000000-0000-0000-0000-000000000461")!
            let opponentID = UUID(uuidString: "00000000-0000-0000-0000-000000000462")!
            let firstGameID = UUID(uuidString: "00000000-0000-0000-0000-000000000463")!
            let secondGameID = UUID(uuidString: "00000000-0000-0000-0000-000000000464")!
            let weekOne = CalendarState(season: 0, week: 1)
            var tactical = TacticalState(calendar: weekOne)
            expect(tactical.recordObservation(OpponentObservation(
                observerID: observerID,
                opponentID: opponentID,
                observedThrough: weekOne,
                sourceGameIDs: [firstGameID],
                confidence: 25,
                sampleSize: 1,
                passRate: 70,
                turnoverRate: 20
            )))

            tactical.advance(to: CalendarState(season: 0, week: 2))
            expect(tactical.recordObservation(OpponentObservation(
                observerID: observerID,
                opponentID: opponentID,
                observedThrough: tactical.calendar,
                sourceGameIDs: [secondGameID],
                confidence: 25,
                sampleSize: 1,
                passRate: 30,
                turnoverRate: 40
            )))
            guard let merged = tactical.observation(
                for: observerID,
                opponentID: opponentID,
                at: tactical.calendar
            ) else {
                expect(false, "merged opponent film disappeared")
                return
            }
            expectEqual(merged.sampleSize, 2)
            expectEqual(merged.confidence, 50)
            expectEqual(merged.passRate, 50)
            expectEqual(merged.turnoverRate, 30)
            expectEqual(merged.sourceGameIDs.count, 2)
            expectEqual(
                try JSONDecoder.stable().decode(
                    TacticalState.self,
                    from: JSONEncoder.stable().encode(tactical)
                ),
                tactical
            )

            tactical.advance(to: CalendarState(season: 0, week: 7))
            expectEqual(
                tactical.observation(
                    for: observerID,
                    opponentID: opponentID,
                    at: tactical.calendar
                ),
                nil,
                "film older than the bounded window must not become hidden truth"
            )
        }

        test("the weekly scheduler consumes plans and records a review") {
            var state = GameState.bootstrap(seed: 94_051)
            guard let game = state.competition.currentSchedule.games.first(where: {
                $0.week == state.calendar.week && $0.tier == .college
            }) else {
                expect(false, "bootstrap did not produce a college game")
                return
            }
            let plan = TacticalPlan(
                runPassBias: .passHeavy,
                tempo: .hurry,
                pressure: .attack
            )
            expect(state.tactical.setPlan(plan, for: game.homeID, at: state.calendar))

            // `injuriesAndRecovery` runs before `nonUserGames`, so a player injured on the health
            // tick is not on the field for the game played later the same week. Re-simulating from
            // the root the week began on would compare against a squad that never took it, and the
            // whole summary — not just the participant lists — is what this asserts. The
            // comparison root is therefore the one the step loop had reached at the last step
            // before kickoff.
            let recorder = KickoffStateRecorder(before: .nonUserGames)
            WorldScheduler.transactionObserver = { checkpoint, observed in
                recorder.observe(checkpoint, state: observed)
            }
            defer { WorldScheduler.transactionObserver = nil }

            let transition = try WorldScheduler.advanceWeek(state)
            guard let kickoff = recorder.state else {
                expect(false, "the week never reached the step before kickoff")
                return
            }
            let expected = AbstractGameSimulator.play(
                game,
                in: kickoff,
                tacticalPlans: [game.homeID: plan]
            )
            guard let completed = transition.state.competition.currentSchedule.games.first(where: {
                $0.id == game.id
            }), let result = completed.result else {
                expect(false, "scheduled game did not record a result")
                return
            }
            expectEqual(result, expected)
            expect(transition.state.tactical.reviews.contains {
                $0.organisationID == game.homeID && $0.opponentID == game.awayID
            })
        }

        test("root integrity rejects tactical identities outside the world") {
            var state = GameState.bootstrap(seed: 94_052)
            let unknownID = UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFEF")!
            expect(state.tactical.setPlan(
                .balanced,
                for: unknownID,
                at: state.calendar
            ))
            expect(
                WorldIntegrity.check(state).issues.contains(.invalidTacticalState),
                "an unknown tactical organisation survived root integrity"
            )
        }

        test("the intent boundary persists game and practice plans") {
            let state = GameState.bootstrap(seed: 94_053)
            guard let organisationID = state.programmes.ids.sorted(by: {
                $0.uuidString < $1.uuidString
            }).first else {
                expect(false, "bootstrap did not produce a programme")
                return
            }
            let calendar = state.calendar
            let plan = TacticalPlan(
                runPassBias: .runHeavy,
                tempo: .deliberate,
                pressure: .contain
            )
            let practice = TacticalPracticePlan(
                installMinutes: 30,
                conditioningMinutes: 15,
                recoveryMinutes: 0,
                positionFocusMinutes: 15,
                positionFocus: .defensiveLine
            )
            let planned = try IntentResolver.resolve(
                .tacticalPlan(TacticalPlanRequest(
                    organisationID: organisationID,
                    calendar: calendar,
                    plan: plan
                )),
                in: state
            )
            let practiced = try IntentResolver.resolve(
                .practicePlan(TacticalPracticePlanRequest(
                    organisationID: organisationID,
                    calendar: calendar,
                    plan: practice
                )),
                in: planned.state
            )
            expectEqual(practiced.state.tactical.plan(for: organisationID, at: calendar), plan)
            expectEqual(practiced.state.tactical.practicePlan(for: organisationID, at: calendar), practice)
            if case .tacticalUpdated = practiced.result {
                expect(true)
            } else {
                expect(false, "tactical intent did not return a tactical result")
            }
        }

        test("personnel overrides persist through the intent boundary and stay roster-scoped") {
            let state = GameState.bootstrap(seed: 94_054)
            guard let organisationID = state.programmes.ids.sorted(by: {
                $0.uuidString < $1.uuidString
            }).first, let programme = state.programmes[organisationID] else {
                expect(false, "bootstrap did not produce a programme")
                return
            }
            guard let quarterback = programme.rosterIDs.compactMap({ state.players[$0] })
                .first(where: { $0.position == .quarterback }) else {
                expect(false, "programme did not produce a quarterback")
                return
            }
            let plan = PersonnelPlan(
                organisationID: organisationID,
                calendar: state.calendar,
                overrides: [DepthChartOverride(
                    position: .quarterback,
                    playerIDs: [quarterback.id]
                )]
            )
            let resolved = try IntentResolver.resolve(
                .personnelPlan(PersonnelPlanRequest(plan: plan)),
                in: state
            )
            expectEqual(
                resolved.state.tactical.personnelPlan(
                    for: organisationID, at: state.calendar
                ),
                plan
            )
            if case let .tacticalUpdated(result) = resolved.result {
                expectEqual(result.kind, .personnelPlan)
            } else {
                expect(false, "personnel intent returned the wrong receipt")
            }
        }
    }
}
