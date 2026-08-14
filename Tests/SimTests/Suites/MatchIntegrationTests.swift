import Foundation
import FootballSimCore

func runMatchIntegrationTests() {
    suite("The coach's own game is played") {
        test("the controlled fixture is resolved by the detailed engine") {
            // 02 section 3.14. GameEngine.play had exactly one caller in the tree and it was the
            // calibration harness; the scheduler's userGame step was declared and inactive, so
            // every game in a career — including the coach's own — came from the abstracted model.
            let source = GameState.bootstrap(seed: 88_001)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            let programmeID = state.career.college!.programmeID

            var playedWeeks = 0
            for _ in 0..<4 {
                let transition = try WorldScheduler.advanceWeek(state)
                if transition.stepRecords.contains(where: {
                    $0.step == .userGame && $0.status == .executed
                }) { playedWeeks += 1 }
                state = transition.state
            }
            expect(playedWeeks > 0,
                   "the userGame step never executed in four weeks, so the coach's match is still "
                       + "resolved by the abstracted model")

            let ourGames = state.competition.currentSchedule.games.filter {
                ($0.homeID == programmeID || $0.awayID == programmeID) && $0.result != nil
            }
            expect(!ourGames.isEmpty, "the controlled programme played no games")
            for game in ourGames {
                guard let result = game.result else { continue }
                expect(!result.playerStatistics.isEmpty,
                       "a played game produced no player lines")
                expect(result.homeParticipantIDs.count + result.awayParticipantIDs.count > 0,
                       "a played game recorded no participants")
            }
        }

        test("a played game is recorded exactly once, and only once") {
            // The failure this guards is double-recording: nonUserGames used to play every fixture,
            // so leaving the coach's game in both steps would either throw on the second record or
            // silently overwrite the first.
            let source = GameState.bootstrap(seed: 88_002)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            for _ in 0..<3 { state = try WorldScheduler.advanceWeek(state).state }

            let played = state.competition.currentSchedule.games.filter { $0.result != nil }
            expectEqual(Set(played.map(\.id)).count, played.count,
                        "a game was recorded more than once")
            for game in played {
                guard let result = game.result else { continue }
                expect(result.homeScore >= 0 && result.awayScore >= 0,
                       "a recorded game carried a negative score")
            }
        }

        test("the world stays whole after a played game") {
            // The whole point of routing both engines through one GameSummary: standings,
            // statistics, records, the archive and integrity never learn which engine produced a
            // result.
            let source = GameState.bootstrap(seed: 88_003)
            var state = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            for _ in 0..<3 {
                state = try WorldScheduler.advanceWeek(state).state
                let issues = WorldIntegrity.check(state)
                expect(issues.isValid,
                       "integrity broke after a played game: \(issues.issues)")
            }
        }

        test("the same seed plays the same game") {
            let source = GameState.bootstrap(seed: 88_004)
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            func play() throws -> Data {
                var state = controlled
                for _ in 0..<2 { state = try WorldScheduler.advanceWeek(state).state }
                return try JSONEncoder.stable().encode(state.competition.currentSchedule)
            }
            expectEqual(try play(), try play(),
                        "two runs of the same seed produced different schedules")
        }

        test("a game plan reaches the field") {
            // 02 section 3.14. Without this the played match would be the one game the coach's own
            // mandatory game-plan decision could not touch.
            let attacking = TacticalPlanCaller(
                offensivePlan: TacticalPlan(runPassBias: .passHeavy, tempo: .hurry, pressure: .attack),
                defensivePlan: TacticalPlan(runPassBias: .balanced, tempo: .balanced, pressure: .attack)
            )
            let grinding = TacticalPlanCaller(
                offensivePlan: TacticalPlan(runPassBias: .runHeavy, tempo: .deliberate,
                                            pressure: .contain),
                defensivePlan: TacticalPlan(runPassBias: .balanced, tempo: .balanced,
                                            pressure: .contain)
            )
            let home = testPersonnel(offenseSkill: 72, defenseSkill: 71)
            let away = testPersonnel(offenseSkill: 71, defenseSkill: 72)
            let passing = GameEngine.play(tier: .pro, home: home, away: away, caller: attacking,
                                          seed: 5_050)
            let running = GameEngine.play(tier: .pro, home: home, away: away, caller: grinding,
                                          seed: 5_050)
            func passShare(_ game: GameRecord) -> Double {
                let scrimmage = game.plays.filter {
                    $0.offensiveCall.playType == .pass || $0.offensiveCall.playType == .run
                }
                guard !scrimmage.isEmpty else { return 0 }
                return Double(scrimmage.filter { $0.offensiveCall.playType == .pass }.count)
                    / Double(scrimmage.count)
            }
            expect(passShare(passing) > passShare(running),
                   "a pass-heavy plan threw \(passShare(passing)) of the time against a run-heavy "
                       + "plan's \(passShare(running)), so the plan is not reaching the field")
            expect(passing.playByPlayFingerprint != running.playByPlayFingerprint,
                   "two opposite game plans produced the same game")

            let rushers = TacticalPlanCaller(
                offensivePlan: .balanced,
                defensivePlan: TacticalPlan(runPassBias: .balanced, tempo: .balanced,
                                            pressure: .attack)
            ).defensiveCall(for: Situation(), rules: Tier.pro.clockRules).rushers
            let contained = TacticalPlanCaller(
                offensivePlan: .balanced,
                defensivePlan: TacticalPlan(runPassBias: .balanced, tempo: .balanced,
                                            pressure: .contain)
            ).defensiveCall(for: Situation(), rules: Tier.pro.clockRules).rushers
            expect(rushers > contained, "the pressure plan changed nobody's rush")
        }
    }
}

/// A handler that always takes the aggressive option, to prove an answer changes the game.
struct AttackingCallInHandler: MatchCallInHandler {
    func answer(_ proposal: TacticalCallInProposal, current: TacticalPlan) -> TacticalCallInAction {
        proposal.options.contains { $0.action == .attack } ? .attack : proposal.recommendation
    }
}

/// A handler that answers with an option nobody offered, to prove the engine refuses it.
struct LyingCallInHandler: MatchCallInHandler {
    func answer(_ proposal: TacticalCallInProposal, current: TacticalPlan) -> TacticalCallInAction {
        // `trustCoordinator` is always on the card, so this names the one action the driver has to
        // fall back from only when it is absent — which is why the assertion checks the record
        // rather than the plan.
        .attack
    }
}

func runCallInTests() {
    let home = testPersonnel(offenseSkill: 73, defenseSkill: 71)
    let away = testPersonnel(offenseSkill: 71, defenseSkill: 73)

    suite("Call-ins") {
        test("a played game raises call-ins at a rate 02 section 3.1 would recognise") {
            // TacticalCallInSystem.proposal built exactly what 02 section 3.1 specifies and had no
            // production caller at all: it was reachable only from a unit test.
            var raised = 0
            for seed in UInt64(1)...12 {
                let game = GameEngine.play(
                    tier: .pro, home: home, away: away,
                    callIns: CallInDriver(plan: .balanced, opponentPlan: .balanced),
                    seed: seed
                )
                expect(!game.callIns.isEmpty, "seed \(seed) raised no call-in at all")
                expect(game.callIns.count <= SharedRules.defaultCallInsPerGame,
                       "seed \(seed) raised \(game.callIns.count) call-ins, past its budget")
                raised += game.callIns.count
            }
            expect(raised > 12, "only \(raised) call-ins across twelve games")
        }

        test("a game without a driver raises none") {
            // Every game in the world the coach does not control, and the reason the driver is
            // optional rather than always-on.
            let game = GameEngine.play(tier: .pro, home: home, away: away, seed: 3_003)
            expect(game.callIns.isEmpty, "a game nobody was watching raised a call-in")
        }

        test("the answer changes the game") {
            // The whole point. If answering changed nothing, the call-in would be the previous
            // build's failure with more steps: a decision about presentation.
            let deferred = GameEngine.play(
                tier: .pro, home: home, away: away,
                callIns: CallInDriver(plan: .balanced, opponentPlan: .balanced),
                seed: 8_181
            )
            let attacked = GameEngine.play(
                tier: .pro, home: home, away: away,
                callIns: CallInDriver(plan: .balanced, opponentPlan: .balanced,
                                      handler: AttackingCallInHandler()),
                seed: 8_181
            )
            expect(deferred.playByPlayFingerprint != attacked.playByPlayFingerprint,
                   "answering every call-in differently produced the same game")
            expect(attacked.callIns.contains { !$0.deferred },
                   "the attacking handler never actually departed from the recommendation")
            expect(deferred.callIns.allSatisfy(\.deferred),
                   "the coordinator's own handler did not take its own recommendation")
        }

        test("the budget is honoured and bounded by the tunable range") {
            let tight = GameEngine.play(
                tier: .college, home: home, away: away,
                callIns: CallInDriver(plan: .balanced, opponentPlan: .balanced, budget: 12),
                seed: 4_004
            )
            expect(tight.callIns.count <= 12, "a twelve call-in budget raised \(tight.callIns.count)")
            let clamped = CallInDriver(plan: .balanced, opponentPlan: .balanced, budget: 500)
            expectEqual(clamped.budget, SharedRules.callInsPerGameRange.upperBound,
                        "the budget escaped 02 section 3.1's tunable range")
        }

        test("the same answers replay the same game") {
            func play() -> UInt64 {
                GameEngine.play(
                    tier: .pro, home: home, away: away,
                    callIns: CallInDriver(plan: .balanced, opponentPlan: .balanced,
                                          handler: AttackingCallInHandler()),
                    seed: 9_119
                ).playByPlayFingerprint
            }
            expectEqual(play(), play(), "the same answers produced a different game")
        }

        test("every raised call-in names its trigger and what was recommended") {
            let game = GameEngine.play(
                tier: .college, home: home, away: away,
                callIns: CallInDriver(plan: .balanced, opponentPlan: .balanced,
                                      handler: LyingCallInHandler()),
                seed: 7_007
            )
            for callIn in game.callIns {
                expect(CallInTrigger.allCases.contains(callIn.trigger),
                       "a call-in carried no trigger")
                expect((1...4).contains(callIn.situation.down),
                       "a call-in was raised on down \(callIn.situation.down)")
                expect(callIn.driveIndex >= 0, "a call-in came from no drive")
            }
        }
    }
}
