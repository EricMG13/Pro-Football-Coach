import Foundation
import FootballSimCore

func runTacticalManagementTests() {
    suite("M4 tactical management") {
        test("practice effects are bounded, monotonic, and stable across a save round trip") {
            let lighter = TacticalPracticePlan(
                installMinutes: 15,
                conditioningMinutes: 15,
                recoveryMinutes: 15,
                positionFocusMinutes: 15,
                positionFocus: .quarterbacks
            )
            let heavier = TacticalPracticePlan(
                installMinutes: 30,
                conditioningMinutes: 15,
                recoveryMinutes: 0,
                positionFocusMinutes: 15,
                positionFocus: .quarterbacks
            )
            expect(heavier.effects.developmentValue >= lighter.effects.developmentValue)
            expect(heavier.effects.conditioningBenefit >= lighter.effects.conditioningBenefit)
            expect(heavier.effects.recoveryBenefit <= lighter.effects.recoveryBenefit)
            expectEqual(
                try JSONDecoder.stable().decode(
                    TacticalPracticeEffects.self,
                    from: JSONEncoder.stable().encode(lighter.effects)
                ),
                lighter.effects
            )
        }

        test("opponent observations are scoped, bounded, and reject stale or future evidence") {
            let observerID = UUID(uuidString: "00000000-0000-0000-0000-000000000411")!
            let opponentID = UUID(uuidString: "00000000-0000-0000-0000-000000000412")!
            let observedThrough = CalendarState(season: 0, week: 8)
            let observation = OpponentObservation(
                observerID: observerID,
                snapshot: OpponentScoutingSnapshot(
                    teamID: opponentID,
                    observedThrough: observedThrough,
                    passRate: 62,
                    turnoverRate: 18
                ),
                sourceGameIDs: [
                    UUID(uuidString: "00000000-0000-0000-0000-000000000413")!,
                    UUID(uuidString: "00000000-0000-0000-0000-000000000414")!
                ],
                confidence: 60,
                sampleSize: 2
            )
            expect(observation.isCurrent(at: CalendarState(season: 0, week: 12)))
            expect(!observation.isCurrent(at: CalendarState(season: 0, week: 13)))
            expect(!observation.isCurrent(at: CalendarState(season: 1, week: 1)))
            expectEqual(
                try JSONDecoder.stable().decode(
                    OpponentObservation.self,
                    from: JSONEncoder.stable().encode(observation)
                ),
                observation
            )
            var hostile = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(observation)
            ) as! [String: Any]
            hostile["confidence"] = 101
            do {
                _ = try JSONDecoder.stable().decode(
                    OpponentObservation.self,
                    from: JSONSerialization.data(withJSONObject: hostile)
                )
                expect(false, "hostile observation confidence decoded")
            } catch {
                expect(true)
            }
            let fallback = OpponentObservation.balanced(
                observerID: observerID,
                opponentID: opponentID,
                observedThrough: observedThrough
            )
            expectEqual(fallback.confidence, 0)
            expectEqual(fallback.sampleSize, 0)
            expectEqual(fallback.passRate, 50)
            let observedPlan = TacticalCoordinatorSystem.plan(
                for: observation,
                at: observedThrough,
                coordinatorRating: Rating(80)
            )
            let stalePlan = TacticalCoordinatorSystem.plan(
                for: observation,
                at: CalendarState(season: 0, week: 13),
                coordinatorRating: Rating(80)
            )
            expectEqual(observedPlan.runPassBias, .runHeavy)
            expectEqual(
                stalePlan,
                TacticalCoordinatorSystem.plan(for: nil, coordinatorRating: Rating(80))
            )
        }

        test("opponent scouting is deterministic and uses observed season totals") {
            let teamID = UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
            let statistics = TeamSeasonStatistics(
                games: 10,
                passingYards: 2_400,
                rushingYards: 1_600,
                turnovers: 12
            )
            let first = OpponentScoutingSnapshot.from(
                teamID: teamID,
                observedThrough: CalendarState(season: 0, week: 8),
                statistics: statistics
            )
            let second = OpponentScoutingSnapshot.from(
                teamID: teamID,
                observedThrough: CalendarState(season: 0, week: 8),
                statistics: statistics
            )
            expectEqual(first, second)
            expectEqual(first.passRate, 60)
            expectEqual(first.turnoverRate, 30)
        }

        test("opponent scouting decoding rejects impossible percentages") {
            let snapshot = OpponentScoutingSnapshot(
                teamID: UUID(uuidString: "00000000-0000-0000-0000-000000000403")!,
                observedThrough: CalendarState(season: 0, week: 8),
                passRate: 50,
                turnoverRate: 20
            )
            let encoded = try JSONEncoder.stable().encode(snapshot)
            var object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
            object?["passRate"] = 101
            let corrupted = try JSONSerialization.data(withJSONObject: object as Any)
            do {
                _ = try JSONDecoder().decode(OpponentScoutingSnapshot.self, from: corrupted)
                expect(false, "impossible scouting percentage decoded")
            } catch {
                expect(true)
            }
        }

        test("coordinator plan follows permitted scouting directions") {
            let teamID = UUID(uuidString: "00000000-0000-0000-0000-000000000402")!
            let passHeavy = OpponentScoutingSnapshot(
                teamID: teamID,
                observedThrough: CalendarState(season: 0, week: 8),
                passRate: 70,
                turnoverRate: 10
            )
            let plan = TacticalCoordinatorSystem.plan(
                for: passHeavy,
                coordinatorRating: Rating(80)
            )
            expectEqual(plan.runPassBias, .runHeavy)
            expectEqual(plan.tempo, .hurry)
            expectEqual(plan.pressure, .attack)
        }

        test("the detailed caller applies plan choices without losing situation guards") {
            let caller = TacticalPlayCaller(plan: TacticalPlan(
                runPassBias: .passHeavy,
                tempo: .hurry,
                pressure: .attack
            ))
            let normal = Situation(down: 1, distance: 10)
            let offensive = caller.offensiveCall(for: normal, rules: ProClockRules.self)
            let defensive = caller.defensiveCall(for: normal, rules: ProClockRules.self)
            expectEqual(offensive.playType, .pass)
            expectEqual(offensive.tempo, .hurry)
            expectEqual(defensive.rushers, MatchupRules.baseRushers + 1)

            let fourthDown = Situation(down: 4, distance: 10)
            expectEqual(
                caller.offensiveCall(for: fourthDown, rules: ProClockRules.self).playType,
                .punt
            )
            let lateAndTrailing = Situation(
                down: 2,
                distance: 8,
                possession: .home,
                homeScore: 10,
                awayScore: 17,
                quarter: 4,
                secondsRemainingInQuarter: 60
            )
            expectEqual(
                caller.defensiveCall(for: lateAndTrailing, rules: ProClockRules.self).coverage,
                .prevent
            )
        }

        test("call-in proposals expose a bounded, inspectable decision") {
            let situation = Situation(
                down: 4,
                distance: 2,
                yardLine: 72,
                homeScore: 14,
                awayScore: 17,
                quarter: 4,
                secondsRemainingInQuarter: 80
            )
            let proposal = TacticalCallInSystem.proposal(
                for: situation,
                plan: .balanced,
                isAfterTurnover: true,
                rules: ProClockRules.self
            )
            expect(proposal != nil, "a fourth-down situation should produce a call-in")
            guard let proposal else { return }
            expect((1...3).contains(proposal.options.count))
            expectEqual(Set(proposal.options.map(\.action)).count, proposal.options.count)
            expect(proposal.options.allSatisfy {
                !$0.rationale.isEmpty && !$0.risk.isEmpty
            })
            expectEqual(proposal.trigger, .fourthDown)
            expectEqual(proposal.recommendation, .attack)
        }

        test("tactical plans measurably alter deterministic abstract outcomes") {
            let state = GameState.bootstrap(seed: 94_001)
            let games = Array(state.competition.currentSchedule.games.prefix(24))
            let aggressive = TacticalPlan(
                runPassBias: .passHeavy,
                tempo: .hurry,
                pressure: .attack
            )
            var changed = 0
            for game in games {
                let baseline = AbstractGameSimulator.play(game, in: state)
                let explicitBalanced = AbstractGameSimulator.play(
                    game,
                    in: state,
                    tacticalPlans: [game.homeID: .balanced, game.awayID: .balanced]
                )
                expectEqual(baseline, explicitBalanced)
                let planned = AbstractGameSimulator.play(
                    game,
                    in: state,
                    tacticalPlans: [game.homeID: aggressive]
                )
                let replay = AbstractGameSimulator.play(
                    game,
                    in: state,
                    tacticalPlans: [game.homeID: aggressive]
                )
                expectEqual(planned, replay)
                if planned != baseline { changed += 1 }
            }
            expect(changed > 0, "tactical plans did not alter any deterministic outcome")
        }
    }
}
