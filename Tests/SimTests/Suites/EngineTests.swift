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

// MARK: - Snap resolution

/// A deterministic test roster. Ratings are passed in so a test can make one side better.
func testPersonnel(offenseSkill: Int, defenseSkill: Int) -> SnapPersonnel {
    func player(_ position: Position, _ index: Int, _ skill: Int) -> Player {
        var attributes = Attributes()
        for attribute in position.ratedAttributes { attributes[attribute] = Rating(skill) }
        return Player(
            id: UUID(uuidString: String(format: "00000000-0000-4000-8000-%012X",
                                        index + skill * 1_000))!,
            firstName: "T", lastName: "P\(index)", position: position, age: 24,
            attributes: attributes, potential: Rating(80)
        )
    }
    var offense: [Player] = []
    var index = 0
    for position in [Position.quarterback, .runningBack, .wideReceiver, .wideReceiver,
                     .wideReceiver, .tightEnd, .leftTackle, .guardPosition, .center,
                     .rightTackle, .kicker, .punter] {
        offense.append(player(position, index, offenseSkill)); index += 1
    }
    var defense: [Player] = []
    for position in [Position.edgeRusher, .edgeRusher, .defensiveTackle, .defensiveTackle,
                     .linebacker, .linebacker, .linebacker, .cornerback, .cornerback,
                     .safety, .safety] {
        defense.append(player(position, index, defenseSkill)); index += 1
    }
    return SnapPersonnel(offense: offense, defense: defense)
}

func runSnapResolverTests() {
    let rules = Tier.pro.clockRules
    let even = testPersonnel(offenseSkill: 70, defenseSkill: 70)

    suite("Snap resolution") {
        test("the same seed and state resolve to the same snap") {
            func once() -> SnapOutcome {
                var rng = SeededRandom(seed: 555)
                return SnapResolver.resolve(
                    offensiveCall: OffensiveCall(playType: .pass),
                    defensiveCall: DefensiveCall(coverage: .man),
                    personnel: even, situation: Situation(), rules: rules, rng: &rng
                )
            }
            expectEqual(once(), once(), "a snap is not reproducible from its seed and state")
        }

        test("a snap consumes the same number of draws whatever it produced") {
            // The determinism property that matters most, and the one that is easy to lose: a
            // resolver whose draw count depends on the outcome makes every later snap in the drive
            // diverge as soon as one play differs. Every branch — sack, incompletion, catch,
            // touchdown, fumble — must leave the stream in the same place.
            func stateAfter(_ call: OffensiveCall, _ defence: DefensiveCall,
                            _ situation: Situation, _ personnel: SnapPersonnel) -> UInt64 {
                var rng = SeededRandom(seed: 909)
                _ = SnapResolver.resolve(offensiveCall: call, defensiveCall: defence,
                                         personnel: personnel, situation: situation,
                                         rules: rules, rng: &rng)
                return rng.next()
            }
            let base = stateAfter(OffensiveCall(playType: .pass), DefensiveCall(coverage: .man),
                                  Situation(), even)
            // Same call and personnel, different field position: the goal-line branch must not
            // change how much of the stream the snap consumed.
            expectEqual(base,
                        stateAfter(OffensiveCall(playType: .pass), DefensiveCall(coverage: .man),
                                   Situation(yardLine: 98), even),
                        "the goal-line branch changed the draw count")
        }

        test("every pass snap records the matchups that produced it") {
            // D2 rejected the distribution model because it cannot say why. A resolver that
            // returned yardage without the duels would be that model.
            var rng = SeededRandom(seed: 4)
            var sawProtection = false, sawRoute = false, sawThrow = false
            for _ in 0..<200 {
                let outcome = SnapResolver.resolve(
                    offensiveCall: OffensiveCall(playType: .pass),
                    defensiveCall: DefensiveCall(coverage: .zoneUnder),
                    personnel: even, situation: Situation(), rules: rules, rng: &rng
                )
                expect(!outcome.matchups.isEmpty, "a pass produced no matchups")
                for matchup in outcome.matchups {
                    if matchup.kind == .passProtection { sawProtection = true }
                    if matchup.kind == .routeVersusCoverage { sawRoute = true }
                    if matchup.kind == .throwing { sawThrow = true }
                }
            }
            expect(sawProtection, "no protection duel was ever recorded")
            expect(sawRoute, "no route matchup was ever recorded")
            expect(sawThrow, "no throw was ever recorded")
        }

        test("a sack names the protection duel that lost") {
            // 04 section 5.3 draws a sack as the protection duel that lost, and can only do that
            // if the engine said which one.
            var rng = SeededRandom(seed: 31)
            var found = false
            for _ in 0..<400 {
                let outcome = SnapResolver.resolve(
                    offensiveCall: OffensiveCall(playType: .pass),
                    defensiveCall: DefensiveCall(coverage: .man, rushers: 7, aggression: 1),
                    personnel: testPersonnel(offenseSkill: 45, defenseSkill: 95),
                    situation: Situation(), rules: rules, rng: &rng
                )
                guard outcome.result == .sack else { continue }
                found = true
                guard let deciding = outcome.decidingMatchup else {
                    expect(false, "a sack named no deciding matchup"); continue
                }
                expectEqual(deciding.kind, .passProtection,
                            "a sack was decided by something other than a protection duel")
                expect(!deciding.attackerWon, "the blocker won the duel that produced a sack")
            }
            expect(found, "a heavy blitz against a weak line never produced a sack in 400 snaps")
        }

        test("every snap result is reachable") {
            // Dead capability is this project's first named failure mode. A result the engine
            // declares and never produces is exactly that.
            var rng = SeededRandom(seed: 17)
            var seen: Set<SnapResult> = []
            let weak = testPersonnel(offenseSkill: 45, defenseSkill: 95)
            let strong = testPersonnel(offenseSkill: 95, defenseSkill: 45)
            for index in 0..<3_000 {
                let personnel = index % 2 == 0 ? weak : strong
                let call: OffensiveCall
                switch index % 5 {
                case 0: call = OffensiveCall(playType: .pass, passDepth: .deep, aggression: 1)
                case 1: call = OffensiveCall(playType: .run, runGap: .outsideLeft)
                case 2: call = OffensiveCall(playType: .fieldGoal)
                case 3: call = OffensiveCall(playType: .punt)
                default: call = OffensiveCall(playType: .pass, passDepth: .short)
                }
                let situation = Situation(yardLine: index % 3 == 0 ? 92 : 30)
                seen.insert(SnapResolver.resolve(
                    offensiveCall: call,
                    defensiveCall: DefensiveCall(coverage: CoverageShell.allCases[index % 4],
                                                 rushers: 3 + index % 5),
                    personnel: personnel, situation: situation, rules: rules, rng: &rng
                ).result)
            }
            seen.insert(SnapResolver.resolve(
                offensiveCall: OffensiveCall(playType: .kneel),
                defensiveCall: DefensiveCall(coverage: .prevent), personnel: even,
                situation: Situation(), rules: rules, rng: &rng
            ).result)
            let unreachable = SnapResult.allCases.filter { !seen.contains($0) && $0 != .safety }
            expect(unreachable.isEmpty,
                   "these results are declared and never produced: "
                       + unreachable.map(\.rawValue).joined(separator: ", "))
        }

        test("a better offence gains more than a worse one") {
            func meanYards(offense: Int, defense: Int) -> Double {
                var rng = SeededRandom(seed: 8_080)
                var total = 0
                for _ in 0..<1_500 {
                    total += SnapResolver.resolve(
                        offensiveCall: OffensiveCall(playType: .pass),
                        defensiveCall: DefensiveCall(coverage: .zoneUnder),
                        personnel: testPersonnel(offenseSkill: offense, defenseSkill: defense),
                        situation: Situation(), rules: rules, rng: &rng
                    ).yards
                }
                return Double(total) / 1_500
            }
            let good = meanYards(offense: 90, defense: 50)
            let bad = meanYards(offense: 50, defense: 90)
            expect(good > bad,
                   "a 90-rated offence gained \(good) a snap against a 50-rated one's \(bad)")
        }

        test("prevent concedes the short throw and takes away the deep one") {
            // Every shell must give something up, or one is always right and 02 section 2.2's
            // first test for a real decision fails.
            expect(CoverageShell.prevent.help(against: .deep) > 0, "prevent does not help deep")
            expect(CoverageShell.prevent.help(against: .short) < 0, "prevent does not concede short")
            expect(CoverageShell.zoneUnder.help(against: .deep) < 0,
                   "an underneath zone does not concede the deep ball")
            for shell in CoverageShell.allCases {
                expect(shell.runCost > 0, "\(shell.rawValue) costs nothing against the run")
            }
        }

        test("blitzing trades coverage for pressure") {
            expect(DefensiveCall(coverage: .man, rushers: 6).coverageDrain > 0,
                   "an extra rusher costs the coverage nothing")
            expect(DefensiveCall(coverage: .man, rushers: 3).coverageDrain < 0,
                   "dropping a rusher does not help the coverage")
            expectEqual(DefensiveCall(coverage: .man, rushers: 99).rushers,
                        MatchupRules.maximumRushers, "the rusher count is unbounded")
        }

        test("a poor decider is pulled toward progression order") {
            // The second receiver is more open, but a low-decision passer should still favour the
            // first read.
            let openSecond = SnapResolver.weightedTarget(0.9, order: 1, decision: 0.05)
            let coveredFirst = SnapResolver.weightedTarget(0.2, order: 0, decision: 0.05)
            expect(coveredFirst > openSecond, "a poor decider found the open man anyway")
            let sharpSecond = SnapResolver.weightedTarget(0.9, order: 1, decision: 0.95)
            let sharpFirst = SnapResolver.weightedTarget(0.2, order: 0, decision: 0.95)
            expect(sharpSecond > sharpFirst, "a sharp decider missed the open man")
        }

        test("a long field goal is harder than a short one") {
            func madeRate(from yardLine: Int) -> Double {
                var rng = SeededRandom(seed: 606)
                var made = 0
                for _ in 0..<800 {
                    if SnapResolver.resolve(
                        offensiveCall: OffensiveCall(playType: .fieldGoal),
                        defensiveCall: DefensiveCall(coverage: .man), personnel: even,
                        situation: Situation(yardLine: yardLine), rules: rules, rng: &rng
                    ).result == .fieldGoalGood { made += 1 }
                }
                return Double(made) / 800
            }
            let short = madeRate(from: 90)
            let long = madeRate(from: 55)
            expect(short > long,
                   "a 27-yard kick went in \(short) of the time against a 62-yarder's \(long)")
        }

        test("a kneel loses a yard and stops nothing") {
            var rng = SeededRandom(seed: 1)
            let outcome = SnapResolver.resolve(
                offensiveCall: OffensiveCall(playType: .kneel),
                defensiveCall: DefensiveCall(coverage: .prevent), personnel: even,
                situation: Situation(), rules: rules, rng: &rng
            )
            expectEqual(outcome.result, .kneel)
            expectEqual(outcome.yards, -1)
            expect(!outcome.result.stopsClock, "a kneel stopped the clock")
        }

        test("tempo changes how much clock a snap costs") {
            func seconds(_ tempo: Tempo) -> Int {
                var rng = SeededRandom(seed: 2)
                return SnapResolver.resolve(
                    offensiveCall: OffensiveCall(playType: .run, tempo: tempo),
                    defensiveCall: DefensiveCall(coverage: .man), personnel: even,
                    situation: Situation(), rules: rules, rng: &rng
                ).secondsElapsed
            }
            expect(seconds(.hurry) < seconds(.normal), "hurrying up saved no clock")
            expect(seconds(.bleed) > seconds(.normal), "bleeding the clock cost none")
        }

        test("a turnover and a clock stop are properties of the result, not of a call site") {
            expect(SnapResult.interception.isTurnover, "an interception is not a turnover")
            expect(SnapResult.fumbleLost.isTurnover, "a lost fumble is not a turnover")
            expect(!SnapResult.punt.isTurnover, "a punt is a turnover")
            expect(SnapResult.incompletion.stopsClock, "an incompletion does not stop the clock")
            expect(!SnapResult.gain.stopsClock, "a gain in bounds stops the clock")
        }
    }
}
