import Foundation
import FootballSimCore

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
            let expected = AbstractGameSimulator.play(
                game,
                in: state,
                tacticalPlans: [game.homeID: plan]
            )
            let transition = try WorldScheduler.advanceWeek(state)
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
    }
}
