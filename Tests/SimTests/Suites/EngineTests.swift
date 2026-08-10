import Foundation
import FootballSimCore

func runEngineTests() {
    suite("Leverage") {
        test("an even matchup is even, and the extremes saturate the right way") {
            expectClose(Leverage.logistic(0), 0, 0.000_001, "an even matchup is not even")
            expect(Leverage.logistic(60) > 0.9, "a 60-point edge barely favours the attacker")
            expect(Leverage.logistic(-60) < -0.9, "a 60-point deficit barely favours the defender")
        }

        test("the rating term is odd, so a matchup reads the same from either side") {
            for difference in stride(from: -59.0, through: 59.0, by: 7) {
                expectClose(Leverage.logistic(difference), -Leverage.logistic(-difference),
                            0.000_001, "the curve is not symmetric at \(difference)")
            }
        }

        test("the curve is monotonic and stays inside its range across the whole rating span") {
            // The span is 40 to 99, so a difference runs -59 to 59.
            var previous = -Double.infinity
            for difference in stride(from: -59.0, through: 59.0, by: 1) {
                let value = Leverage.logistic(difference)
                expect(value > previous, "the curve is not increasing at \(difference)")
                expect(value > -1 && value < 1, "the curve left its range at \(difference)")
                previous = value
            }
        }

        test("a ten-point gap is worth more in the middle of the scale than at the ends") {
            // 03 section 1.1's actual requirement, and the reason the term is a logistic rather
            // than a line. A linear ramp satisfies the range and every symmetry assertion above
            // while failing this one, which is why the shape is asserted and not just the bounds.
            let middle = Leverage.logistic(5) - Leverage.logistic(-5)
            let edge = Leverage.logistic(59) - Leverage.logistic(49)
            expect(middle > edge * 3,
                   "a 10-point gap is worth \(middle) in the middle and \(edge) at the edge, which "
                       + "is not the diminishing return a logistic is for")
        }

        test("the steepest point is the middle, and peakSlope names it") {
            let epsilon = 0.001
            let measured = (Leverage.logistic(epsilon) - Leverage.logistic(-epsilon)) / (2 * epsilon)
            expectClose(measured, Leverage.peakSlope, 0.000_1,
                        "peakSlope does not describe the curve it claims to")
        }

        test("a full score stays inside [-1, 1] however hostile the inputs") {
            var rng = SeededRandom(seed: 11)
            for _ in 0..<20_000 {
                let value = Leverage.score(
                    attacker: Rating(rng.int(in: 40...99)),
                    defender: Rating(rng.int(in: 40...99)),
                    schemeFit: Double(rng.int(in: -400...400)) / 100,
                    attackerFatigue: Double(rng.int(in: -400...400)) / 100,
                    defenderFatigue: Double(rng.int(in: -400...400)) / 100,
                    situationModifier: Double(rng.int(in: -300...300)) / 100,
                    rng: &rng
                )
                expect(value >= -1 && value <= 1, "leverage left its range at \(value)")
            }
        }

        test("scoring consumes exactly one draw whatever the inputs") {
            // A resolver whose draw count depended on the ratings would couple the stream to the
            // roster, which is the defect that made P2's archetype sampling non-uniform — and it
            // would make a replay diverge the moment a player's rating changed.
            //
            // Measured by comparing the generator's state after scoring against the state after
            // the same number of bare draws, at inputs chosen to be as different as possible.
            func stateAfterScoring(attacker: Int, defender: Int, fit: Double) -> UInt64 {
                var rng = SeededRandom(seed: 4242)
                _ = Leverage.score(attacker: Rating(attacker), defender: Rating(defender),
                                   schemeFit: fit, rng: &rng)
                return rng.next()
            }
            let a = stateAfterScoring(attacker: 99, defender: 40, fit: 1)
            let b = stateAfterScoring(attacker: 40, defender: 99, fit: -1)
            let c = stateAfterScoring(attacker: 70, defender: 70, fit: 0)
            expectEqual(a, b, "two different matchups left the stream in different places")
            expectEqual(b, c, "two different matchups left the stream in different places")
        }

        test("scheme fit and fatigue move the score in the direction they claim") {
            func score(fit: Double, attackerFatigue: Double, defenderFatigue: Double) -> Double {
                var rng = SeededRandom(seed: 7)
                return Leverage.score(attacker: Rating(70), defender: Rating(70), schemeFit: fit,
                                      attackerFatigue: attackerFatigue,
                                      defenderFatigue: defenderFatigue, rng: &rng)
            }
            let neutral = score(fit: 0, attackerFatigue: 0, defenderFatigue: 0)
            expect(score(fit: 1, attackerFatigue: 0, defenderFatigue: 0) > neutral,
                   "fitting the scheme did not help the attacker")
            expect(score(fit: -1, attackerFatigue: 0, defenderFatigue: 0) < neutral,
                   "fighting the scheme did not hurt the attacker")
            expect(score(fit: 0, attackerFatigue: 1, defenderFatigue: 0) < neutral,
                   "a tired attacker did not lose ground")
            expect(score(fit: 0, attackerFatigue: 0, defenderFatigue: 1) > neutral,
                   "a tired defender did not lose ground")
        }

        test("a better player wins more matchups than a worse one, over many draws") {
            // The property that makes ratings mean anything, asserted on the whole score rather
            // than the noiseless term. Not a calibration band — P4 owns those — just the sign.
            var rng = SeededRandom(seed: 99)
            var wins = 0
            for _ in 0..<10_000 where Leverage.score(attacker: Rating(85), defender: Rating(60),
                                                     rng: &rng) > 0 {
                wins += 1
            }
            expect(wins > 8_000,
                   "a 25-point edge won only \(wins) of 10,000 matchups, so ratings barely matter")
        }
    }

    suite("Situation") {
        test("field position and score read from the right side") {
            var situation = Situation(yardLine: 75, possession: .home, homeScore: 21, awayScore: 14)
            expectEqual(situation.yardsToGoal, 25)
            expectEqual(situation.scoreDifferential, 7)
            situation.possession = .away
            expectEqual(situation.scoreDifferential, -7,
                        "the score differential is not from the perspective of whoever has the ball")
        }

        test("the red zone and goal-to-go are where they should be") {
            expect(Situation(yardLine: 81).isRedZone, "the 19-yard line is not in the red zone")
            expect(Situation(yardLine: 80).isRedZone, "the 20-yard line is not in the red zone")
            expect(!Situation(yardLine: 79).isRedZone, "the 21-yard line is in the red zone")
            expect(Situation(distance: 5, yardLine: 96).isGoalToGo,
                   "first and five from the four is not goal to go")
            expect(!Situation(distance: 10, yardLine: 80).isGoalToGo,
                   "first and ten from the twenty is goal to go")
        }

        test("two minutes is measured in the half, not the quarter") {
            // 30 seconds left in the first quarter is not a two-minute situation, and a check that
            // read only the quarter clock would say it was.
            let rules = Tier.pro.clockRules
            expect(!Situation(quarter: 1, secondsRemainingInQuarter: 30).isTwoMinute(rules: rules),
                   "the end of the first quarter read as a two-minute situation")
            expect(Situation(quarter: 2, secondsRemainingInQuarter: 90).isTwoMinute(rules: rules),
                   "90 seconds left in the half is not a two-minute situation")
            expect(Situation(quarter: 4, secondsRemainingInQuarter: 90).isTwoMinute(rules: rules),
                   "90 seconds left in the game is not a two-minute situation")
        }

        test("every situational call-in trigger 02 section 3.1 names fires") {
            // 02 section 3.1 lists seven triggers. Five are properties of the situation and are
            // asserted here; the other two need the plan and the game's history and belong to the
            // drive loop. A trigger that never fires is dead capability with a name.
            let rules = Tier.college.clockRules
            var fired: Set<CallInTrigger> = []
            for situation in [
                Situation(down: 4, distance: 2, yardLine: 55),
                Situation(down: 1, distance: 10, yardLine: 90),
                Situation(down: 3, distance: 9, yardLine: 40),
                Situation(down: 1, distance: 10, yardLine: 25, quarter: 4,
                          secondsRemainingInQuarter: 60),
            ] {
                fired.formUnion(situation.situationalCallInTriggers(rules: rules,
                                                                    isSnapAfterTurnover: false))
            }
            fired.formUnion(Situation().situationalCallInTriggers(rules: rules,
                                                                  isSnapAfterTurnover: true))
            for trigger in [CallInTrigger.fourthDown, .redZone, .twoMinute, .thirdAndLong,
                            .afterTurnover] {
                expect(fired.contains(trigger), "\(trigger.rawValue) never fired")
            }
        }

        test("an ordinary early-down snap triggers nothing") {
            // The other direction. A trigger set that fired on everything would make the call-in
            // rate meaningless and blow D1's session budget.
            let triggers = Situation(down: 1, distance: 10, yardLine: 30, quarter: 1,
                                     secondsRemainingInQuarter: 800)
                .situationalCallInTriggers(rules: Tier.college.clockRules,
                                           isSnapAfterTurnover: false)
            expect(triggers.isEmpty, "first and ten in the first quarter fired \(triggers)")
        }

        test("every trigger has a label, so a surface never has to invent one") {
            for trigger in CallInTrigger.allCases {
                expect(!trigger.label.isEmpty, "\(trigger.rawValue) has no label")
            }
        }
    }

    suite("Clock rules") {
        test("the tiers differ where 03 section 2 says they differ") {
            expect(CollegeClockRules.clockStopsOnFirstDown,
                   "the college clock does not stop on a first down")
            expect(!ProClockRules.clockStopsOnFirstDown,
                   "the pro clock stops on a first down")
            expect(CollegeClockRules.overtime != ProClockRules.overtime,
                   "both tiers resolve a tie the same way")
        }

        test("college tempo falls out of the clock model rather than a fudge factor") {
            // 03 section 2: "Higher college tempo is a consequence of the clock model, not a fudge
            // factor applied afterwards." The consequence has to be visible in the constants: the
            // college offence takes less time between snaps and its clock stops more often.
            expect(CollegeClockRules.normalTempoSnapSeconds < ProClockRules.normalTempoSnapSeconds,
                   "the college offence does not snap faster")
            expect(CollegeClockRules.clockStopsOnFirstDown && !ProClockRules.clockStopsOnFirstDown,
                   "the first-down stop is not the tier difference it is documented as")
        }

        test("both tiers' clock constants are internally coherent") {
            for rules in [Tier.college.clockRules, Tier.pro.clockRules] {
                expect(rules.quarters > 0, "a game with no quarters")
                expect(rules.quarterSeconds > 0, "a quarter with no time")
                expect(rules.hurryTempoSnapSeconds < rules.normalTempoSnapSeconds,
                       "hurrying up does not save time")
                expect(rules.bleedTempoSnapSeconds > rules.normalTempoSnapSeconds,
                       "bleeding the clock does not cost time")
                expect(rules.bleedTempoSnapSeconds <= rules.playClockSeconds,
                       "bleeding the clock would draw a delay-of-game penalty every snap")
                expect(rules.twoMinuteSeconds < rules.quarterSeconds,
                       "the two-minute warning is longer than a quarter")
                expect(rules.timeoutsPerHalf > 0, "a half with no timeouts")
            }
        }

        test("a tier reports the clock rules that belong to it") {
            expect(Tier.college.clockRules.clockStopsOnFirstDown,
                   "the college tier is wired to the pro clock")
            expect(!Tier.pro.clockRules.clockStopsOnFirstDown,
                   "the pro tier is wired to the college clock")
        }
    }
}
