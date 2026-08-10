import Foundation
import FootballSimCore

/// Pinned play-by-play fingerprints. See "the play-by-play fingerprint is pinned across processes".
private let PINNED_PRO_GAME_FINGERPRINT: UInt64 = 12_812_997_658_043_978_554
private let PINNED_COLLEGE_GAME_FINGERPRINT: UInt64 = 17_380_292_129_192_486_949

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

    suite("Outcome sampling") {
        test("weighted sampling selects the first and last buckets at their boundaries") {
            let distribution = WeightedOutcome([("first", 1.0), ("last", 3.0)])
            expectEqual(distribution.sample(roll: 0), "first")
            expectEqual(distribution.sample(roll: 0.249_999_999), "first")
            expectEqual(distribution.sample(roll: 0.25), "last")
            expectEqual(distribution.sample(roll: Double(1).nextDown), "last")
            expectEqual(distribution.sample(roll: 1), "last",
                        "a terminal roll did not clamp into the final bucket")
        }

        test("weighted sampling rejects empty and invalid distributions") {
            expectEqual(WeightedOutcome<Int>([]).sample(roll: 0), nil,
                        "an empty distribution produced a value")
            expectEqual(WeightedOutcome([(1, 0.0)]).sample(roll: 0.5), nil,
                        "a zero-total distribution produced a value")
            expectEqual(WeightedOutcome([(1, -1.0)]).sample(roll: 0.5), nil,
                        "a negative weight produced a value")
            expectEqual(WeightedOutcome([(1, Double.nan)]).sample(roll: 0.5), nil,
                        "a NaN weight produced a value")
            expectEqual(WeightedOutcome([(1, Double.infinity)]).sample(roll: 0.5), nil,
                        "an infinite weight produced a value")
            expectEqual(WeightedOutcome([(1, 1.0)]).sample(roll: Double.nan), nil,
                        "a NaN roll produced a value")
        }

        test("zero-weight entries do not claim a bucket") {
            let distribution = WeightedOutcome([("zero", 0.0), ("positive", 1.0)])
            expectEqual(distribution.sample(roll: 0), "positive")
        }

        test("integer sampling includes both range endpoints") {
            expectEqual(OutcomeSampling.integer(in: -3...4, roll: 0), -3)
            expectEqual(OutcomeSampling.integer(in: -3...4, roll: Double(1).nextDown), 4)
            expectEqual(OutcomeSampling.integer(in: -3...4, roll: 1), 4,
                        "a terminal roll did not clamp to the upper endpoint")
            expectEqual(OutcomeSampling.integer(in: -3...4, roll: Double.infinity), nil,
                        "an infinite roll produced an integer")
            expectEqual(OutcomeSampling.integer(in: Int.min...Int.max, roll: 0.5), nil,
                        "an overflowing range produced an integer")
        }

        test("integer sampling preserves the terminal endpoint in a wide valid range") {
            let range = 0...(Int.max - 1)
            expectEqual(OutcomeSampling.integer(in: range, roll: Double(1).nextDown), range.upperBound,
                        "a representable terminal roll lost the upper endpoint to Double precision")
            expectEqual(OutcomeSampling.integer(in: range, roll: 1), range.upperBound,
                        "a clamped terminal roll lost the upper endpoint to Double precision")
        }

        test("snap draws consume a fixed budget and sampling leaves the same RNG state") {
            var actual = SeededRandom(seed: 83)
            let draws = SnapDraws(rng: &actual)
            var expected = SeededRandom(seed: 83)
            for _ in 0..<8 { _ = expected.double01() }
            expect(draws.outcome >= 0 && draws.spareB < 1,
                   "the captured snap draws were outside the unit interval")
            expectEqual(actual.next(), expected.next(), "a snap did not consume exactly eight draws")

            var left = SeededRandom(seed: 17)
            var right = SeededRandom(seed: 17)
            let leftDraws = SnapDraws(rng: &left)
            let rightDraws = SnapDraws(rng: &right)
            let outcomes = WeightedOutcome([("loss", 1.0), ("gain", 1.0)])
            expectEqual(outcomes.sample(roll: leftDraws.outcome), outcomes.sample(roll: rightDraws.outcome))
            let lowOutcome = outcomes.sample(roll: 0)
            let highOutcome = outcomes.sample(roll: 0.99)
            expect(lowOutcome != highOutcome, "the fixture did not sample different outcomes")
            expectEqual(left.next(), right.next(),
                        "different sampled outcomes left the RNG in different states")
        }

        test("snap draw values can be injected without an RNG") {
            let draws = SnapDraws(outcome: 0, yardage: 0.1, target: 0.2, attribution: 0.3,
                                  secondary: 0.4, turnover: 0.5, spareA: 0.6, spareB: 0.7)
            expectEqual(draws, SnapDraws(outcome: 0, yardage: 0.1, target: 0.2, attribution: 0.3,
                                         secondary: 0.4, turnover: 0.5, spareA: 0.6, spareB: 0.7))
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
            expect(DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 2, secondsRemainingInQuarter: 120),
                rules: CollegeClockRules.self
            ), "the college clock does not stop on a first down inside two minutes")
            expect(!DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 2, secondsRemainingInQuarter: 120),
                rules: ProClockRules.self
            ), "the pro clock stops on a first down")
            expect(CollegeClockRules.overtime != ProClockRules.overtime,
                   "both tiers resolve a tie the same way")
        }

        test("college tempo falls out of the clock model rather than a fudge factor") {
            // 03 section 2: "Higher college tempo is a consequence of the clock model, not a fudge
            // factor applied afterwards." The consequence has to be visible in the constants: the
            // college offence takes less time between snaps and stops after first downs only
            // after the two-minute timeout.
            expect(CollegeClockRules.normalTempoSnapSeconds < ProClockRules.normalTempoSnapSeconds,
                   "the college offence does not snap faster")
            expect(DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 4, secondsRemainingInQuarter: 120),
                rules: CollegeClockRules.self
            ) && !DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 4, secondsRemainingInQuarter: 120),
                rules: ProClockRules.self
            ), "the first-down stop is not the tier difference it is documented as")
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
            expect(DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 2, secondsRemainingInQuarter: 120),
                rules: Tier.college.clockRules
            ), "the college tier is wired to the pro clock")
            expect(!DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 2, secondsRemainingInQuarter: 120),
                rules: Tier.pro.clockRules
            ), "the pro tier is wired to the college clock")
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

        test("an even run game has ordinary gains and a reachable explosive tail") {
            var rng = SeededRandom(seed: 8_008)
            var yards = 0
            var explosive = 0
            var ordinaryGains = 0
            let attempts = 12_000
            for attempt in 0..<attempts {
                let outcome = SnapResolver.resolve(
                    offensiveCall: OffensiveCall(
                        playType: .run,
                        runGap: RunGap.allCases[attempt % RunGap.allCases.count]
                    ),
                    defensiveCall: DefensiveCall(coverage: .zoneUnder),
                    personnel: even,
                    situation: Situation(),
                    rules: rules,
                    rng: &rng
                )
                yards += outcome.yards
                if outcome.yards >= MatchupRules.explosiveRunYards { explosive += 1 }
                if (1..<MatchupRules.explosiveRunYards).contains(outcome.yards) {
                    ordinaryGains += 1
                }
            }
            let yardsPerCarry = Double(yards) / Double(attempts)
            let explosiveRate = Double(explosive) / Double(attempts)
            let ordinaryGainRate = Double(ordinaryGains) / Double(attempts)
            expect((3.4...4.8).contains(yardsPerCarry),
                   "even rushing averaged \(yardsPerCarry) yards per carry")
            expect((0.05...0.09).contains(explosiveRate),
                   "even rushing produced an explosive rate of \(explosiveRate)")
            expect(Double(ordinaryGains) / Double(attempts) >= 0.70,
                   "even rushing produced an ordinary-gain rate of \(ordinaryGainRate)")
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
            // Three rungs, not two. The first version alternated a 45-rated offence against a
            // 95-rated defence and the reverse — all mismatches, so it exercised only the tails.
            // A tuning pass that changed the completion threshold made `incompletion` unreachable
            // in the fixture while ordinary games were still full of them, which is the fixture
            // being wrong rather than the engine.
            let level = [weak, even, strong]
            for index in 0..<3_000 {
                let personnel = level[index % level.count]
                let call: OffensiveCall
                switch index % 5 {
                case 0: call = OffensiveCall(playType: .pass, passDepth: .deep, aggression: 1)
                case 1: call = OffensiveCall(playType: .run, runGap: .outsideLeft)
                case 2: call = OffensiveCall(playType: .fieldGoal)
                case 3: call = OffensiveCall(playType: .punt)
                default: call = OffensiveCall(playType: .pass, passDepth: .short)
                }
                // Goal-line snaps have to be in the mix or `touchdown` is unreachable from a
                // single-snap fixture: from the 30, no one play covers 70 yards.
                let situation = Situation(yardLine: [96, 92, 30, 55][index % 4])
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

        test("a snap reports its play's own duration, not the pre-snap clock") {
            // The pre-snap clock moved to the drive loop, because whether it runs at all depends on
            // what the PREVIOUS snap did and on the tier's first-down rule — neither of which a
            // single snap can see. Tempo's effect is asserted at the game level instead, where it
            // now lives.
            func seconds(_ tempo: Tempo) -> Int {
                var rng = SeededRandom(seed: 2)
                return SnapResolver.resolve(
                    offensiveCall: OffensiveCall(playType: .run, tempo: tempo),
                    defensiveCall: DefensiveCall(coverage: .man), personnel: even,
                    situation: Situation(), rules: rules, rng: &rng
                ).secondsElapsed
            }
            expectEqual(seconds(.hurry), seconds(.bleed),
                        "a snap's own duration should not depend on the tempo it was called at")
            expect(seconds(.normal) > 0, "a snap took no time at all")
        }

        test("a turnover and a clock stop are properties of the result, not of a call site") {
            expect(SnapResult.interception.isTurnover, "an interception is not a turnover")
            expect(SnapResult.fumbleLost.isTurnover, "a lost fumble is not a turnover")
            expect(!SnapResult.punt.isTurnover, "a punt is a turnover")
            expect(SnapResult.incompletion.stopsClock, "an incompletion does not stop the clock")
            expect(!SnapResult.gain.stopsClock, "a gain in bounds stops the clock")
        }
    }

    suite("Distribution snap resolution") {
        let neutralDraws = SnapDraws(outcome: 0.5, yardage: 0.5, target: 0.5,
                                     attribution: 0.5, secondary: 0.5, turnover: 0.5,
                                     spareA: 0.5, spareB: 0.5)

        func resolve(
            _ call: OffensiveCall,
            situation: Situation = Situation(),
            personnel: SnapPersonnel = even,
            draws: SnapDraws = neutralDraws,
            tier: Tier = .pro,
            defence: DefensiveCall = DefensiveCall(coverage: .man)
        ) -> SnapOutcome {
            DistributionSnapResolver.resolve(
                tier: tier, offensiveCall: call, defensiveCall: defence,
                personnel: personnel, situation: situation, isHomeOffense: false, draws: draws
            )
        }

        func draws(outcome: Double, yardage: Double = 0.5, target: Double = 0.5,
                   attribution: Double = 0.5, secondary: Double = 0.5) -> SnapDraws {
            SnapDraws(outcome: outcome, yardage: yardage, target: target,
                      attribution: attribution, secondary: secondary, turnover: 0.5,
                      spareA: 0.5, spareB: 0.5)
        }

        test("fixed draws reach every declared snap result") {
            var seen: Set<SnapResult> = []
            let calls = [
                OffensiveCall(playType: .run, runGap: .insideLeft),
                OffensiveCall(playType: .pass, passDepth: .mid),
                OffensiveCall(playType: .fieldGoal),
                OffensiveCall(playType: .punt),
                OffensiveCall(playType: .kneel),
            ]
            for call in calls {
                for yardLine in [1, 30, 99] {
                    for rollIndex in 0...1_000 {
                        let roll = Double(rollIndex) / 1_000
                        seen.insert(resolve(call, situation: Situation(yardLine: yardLine),
                                            draws: draws(outcome: roll, yardage: roll)).result)
                    }
                }
            }
            let missing = SnapResult.allCases.filter { !seen.contains($0) }
            expect(missing.isEmpty,
                   "fixed draws could not reach: \(missing.map(\.rawValue).joined(separator: ", "))")
        }

        test("every fixed run band names its prescribed causal pair") {
            let call = OffensiveCall(playType: .run)
            let defence = DefensiveCall(coverage: .man)
            let assignment = Assignment.assign(offensiveCall: call, defensiveCall: defence,
                                               personnel: even)
            let attribution = 0.75
            let lane = assignment.runLane[Int(attribution * Double(assignment.runLane.count))]
            let pursuer = assignment.pursuit[Int(attribution * Double(assignment.pursuit.count))]
            let carrier = assignment.carrier!
            let situation = Situation(distance: 5)
            let cases: [(name: String, roll: Double, result: SnapResult, yards: Int,
                         kind: MatchupRecord.Kind, attacker: UUID, defender: UUID,
                         attackerWon: Bool)] = [
                ("loss", 0.05, .gain, -1, .runLane, lane.blocker.id, lane.defender.id, false),
                ("short", 0.20, .gain, 2, .runLane, lane.blocker.id, lane.defender.id, true),
                ("medium", 0.70, .gain, 7, .runLane, lane.blocker.id, lane.defender.id, true),
                ("explosive", 0.90, .gain, 14, .carrierVersusPursuit,
                 carrier.id, pursuer.id, true),
                ("breakaway", 0.983, .gain, 40, .carrierVersusPursuit,
                 carrier.id, pursuer.id, true),
                ("fumble", 0.995, .fumbleLost, 2, .ballSecurity,
                 carrier.id, pursuer.id, false),
            ]

            for item in cases {
                let outcome = resolve(call, situation: situation,
                                      draws: draws(outcome: item.roll,
                                                   attribution: attribution), defence: defence)
                expectEqual(outcome.result, item.result, "run \(item.name) sampled wrong result")
                expectEqual(outcome.yards, item.yards, "run \(item.name) sampled wrong yards")
                expectEqual(outcome.ballCarrierID, carrier.id)
                expect(outcome.passerID == nil && outcome.targetID == nil,
                       "run \(item.name) invented pass identities")
                expectEqual(outcome.matchups.count, 1)
                let record = outcome.matchups.first
                expectEqual(record?.kind, item.kind)
                expectEqual(record?.attackerID, item.attacker)
                expectEqual(record?.defenderID, item.defender)
                expectEqual(record?.attackerWon, item.attackerWon,
                            "run \(item.name) recorded the wrong leverage sign")
            }
        }

        test("every fixed pass band names its prescribed target or protection pair") {
            let call = OffensiveCall(playType: .pass, passDepth: .mid)
            let defence = DefensiveCall(coverage: .man)
            let assignment = Assignment.assign(offensiveCall: call, defensiveCall: defence,
                                               personnel: even)
            let target = assignment.routes[1]
            let protection = assignment.protection[1]
            let passer = assignment.passer!
            let situation = Situation(distance: 5)
            let cases: [(name: String, roll: Double, result: SnapResult, yards: Int,
                         sign: Bool, carrier: UUID?)] = [
                ("sack", 0.03, .sack, -6, false, nil),
                ("interception", 0.07, .interception, 0, false, nil),
                ("incompletion", 0.20, .incompletion, 0, false, nil),
                ("completion", 0.50, .gain, 8, true, target.receiver.id),
                ("explosive", 0.90, .gain, 25, true, target.receiver.id),
                ("fumble", 0.995, .fumbleLost, 8, false, target.receiver.id),
            ]

            for item in cases {
                let outcome = resolve(call, situation: situation,
                                      draws: draws(outcome: item.roll, target: 0.3,
                                                   attribution: 0.3), defence: defence)
                expectEqual(outcome.result, item.result, "pass \(item.name) sampled wrong result")
                expectEqual(outcome.yards, item.yards, "pass \(item.name) sampled wrong yards")
                expectEqual(outcome.ballCarrierID, item.carrier)
                expectEqual(outcome.passerID, passer.id)
                if item.name == "sack" {
                    expect(outcome.targetID == nil, "a sack invented a target")
                    expectEqual(outcome.matchups.count, 1)
                    let record = outcome.matchups.first
                    expectEqual(record?.kind, .passProtection)
                    expectEqual(record?.attackerID, protection.blocker.id)
                    expectEqual(record?.defenderID, protection.rusher.id)
                    expectEqual(record?.attackerWon, false)
                    continue
                }

                expectEqual(outcome.targetID, target.receiver.id)
                for kind in [MatchupRecord.Kind.routeVersusCoverage, .throwing] {
                    let record = outcome.matchups.first { $0.kind == kind }
                    expectEqual(record?.attackerID, target.receiver.id,
                                "pass \(item.name) used the wrong target for \(kind)")
                    expectEqual(record?.defenderID, target.defender.id,
                                "pass \(item.name) used the wrong defender for \(kind)")
                    expectEqual(record?.attackerWon, item.name == "fumble" ? true : item.sign,
                                "pass \(item.name) recorded the wrong \(kind) sign")
                }
                if item.name == "fumble" {
                    let security = outcome.matchups.first { $0.kind == .ballSecurity }
                    expectEqual(security?.attackerID, target.receiver.id)
                    expectEqual(security?.defenderID, target.defender.id)
                    expectEqual(security?.attackerWon, false)
                }
            }
        }

        test("fixed field-goal bands name the specialist and ranked defender") {
            let call = OffensiveCall(playType: .fieldGoal)
            let defence = DefensiveCall(coverage: .man)
            let assignment = Assignment.assign(offensiveCall: call, defensiveCall: defence,
                                               personnel: even)
            let specialist = even.offensive(group: .specialists).first!
            let defender = assignment.pursuit.first!
            for (name, roll, result, won) in [
                ("good", 0.1, SnapResult.fieldGoalGood, true),
                ("missed", 0.9, SnapResult.fieldGoalMissed, false),
            ] {
                let outcome = resolve(call, situation: Situation(yardLine: 75),
                                      draws: draws(outcome: roll), defence: defence)
                expectEqual(outcome.result, result, "field goal \(name) sampled wrong result")
                expectEqual(outcome.yards, 0)
                expectEqual(outcome.ballCarrierID, specialist.id)
                expect(outcome.passerID == nil && outcome.targetID == nil,
                       "field goal \(name) invented pass identities")
                let record = outcome.matchups.first
                expectEqual(record?.kind, .kick)
                expectEqual(record?.attackerID, specialist.id)
                expectEqual(record?.defenderID, defender.id)
                expectEqual(record?.attackerWon, won)
            }
        }

        test("distribution validation requires independent unit mass") {
            expect(DistributionSnapResolver.validDistribution([0.1, 0.2, 0.7]),
                   "a finite non-negative unit distribution was rejected")
            expect(!DistributionSnapResolver.validDistribution([0.1, 0.2, 0.6]),
                   "a finite non-negative distribution with non-unit mass was accepted")
        }

        test("target weighting selects the second route and keeps its defender causal") {
            let assignment = Assignment.assign(
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man), personnel: even
            )
            expect(assignment.routes.count >= 2, "fixture has fewer than two routes")
            let selected = assignment.routes[1]
            let first = assignment.routes[0]
            // Equal route weights divide the unit interval evenly; this lies in route two.
            let outcome = resolve(OffensiveCall(playType: .pass),
                                  draws: draws(outcome: 0.5, target: 0.3))
            expectEqual(outcome.targetID, selected.receiver.id)
            expect(outcome.targetID != first.receiver.id, "the first route was silently selected")
            let route = outcome.matchups.first { $0.kind == .routeVersusCoverage }
            let throwing = outcome.matchups.first { $0.kind == .throwing }
            expectEqual(route?.attackerID, selected.receiver.id)
            expectEqual(route?.defenderID, selected.defender.id)
            expectEqual(throwing?.attackerID, selected.receiver.id)
            expectEqual(throwing?.defenderID, selected.defender.id)
        }

        test("empty and partial personnel use the exact non-inventing fallback") {
            let empty = SnapPersonnel(offense: [], defense: [])
            for tier in Tier.allCases {
                let rules = tier.clockRules
                for playType in [OffensivePlayType.run, .pass] {
                    let outcome = resolve(OffensiveCall(playType: playType), personnel: empty,
                                          tier: tier)
                    expectEqual(outcome.result, .gain)
                    expectEqual(outcome.yards, 0)
                    expectEqual(outcome.secondsElapsed, rules.inBoundsPlaySeconds)
                    expect(outcome.matchups.isEmpty, "fallback invented a matchup")
                    expect(outcome.ballCarrierID == nil && outcome.passerID == nil
                               && outcome.targetID == nil, "fallback invented a player ID")
                }
                let kick = resolve(OffensiveCall(playType: .fieldGoal), personnel: empty, tier: tier)
                expectEqual(kick.result, .fieldGoalMissed)
                expectEqual(kick.yards, 0)
                expectEqual(kick.secondsElapsed, rules.stoppedPlaySeconds)
                expect(kick.matchups.isEmpty && kick.ballCarrierID == nil,
                       "empty kick invented attribution")
                expectEqual(resolve(OffensiveCall(playType: .punt), personnel: empty,
                                    tier: tier).result, .punt)
                expectEqual(resolve(OffensiveCall(playType: .kneel), personnel: empty,
                                    tier: tier).result, .kneel)
            }

            let noCarrier = SnapPersonnel(
                offense: even.offense.filter { $0.position != .runningBack }, defense: even.defense
            )
            let noLine = SnapPersonnel(
                offense: even.offense.filter { $0.position.group != .offensiveLine },
                defense: even.defense
            )
            let noPursuit = SnapPersonnel(offense: even.offense, defense: [])
            for personnel in [noCarrier, noLine, noPursuit] {
                let outcome = resolve(OffensiveCall(playType: .run), personnel: personnel)
                expectEqual(outcome, SnapOutcome(result: .gain, yards: 0,
                                                 secondsElapsed: rules.inBoundsPlaySeconds,
                                                 matchups: []))
            }
            let noPasser = SnapPersonnel(
                offense: even.offense.filter { $0.position != .quarterback }, defense: even.defense
            )
            let noRoutes = SnapPersonnel(
                offense: even.offense.filter { $0.position.group != .receivers },
                defense: even.defense
            )
            for personnel in [noPasser, noRoutes, noLine, noPursuit] {
                let outcome = resolve(OffensiveCall(playType: .pass), personnel: personnel)
                expectEqual(outcome, SnapOutcome(result: .gain, yards: 0,
                                                 secondsElapsed: rules.inBoundsPlaySeconds,
                                                 matchups: []))
            }
            let noSpecialist = SnapPersonnel(
                offense: even.offense.filter { $0.position.group != .specialists },
                defense: even.defense
            )
            for personnel in [noSpecialist, noPursuit] {
                let outcome = resolve(OffensiveCall(playType: .fieldGoal), personnel: personnel)
                expectEqual(outcome, SnapOutcome(result: .fieldGoalMissed, yards: 0,
                                                 secondsElapsed: rules.stoppedPlaySeconds,
                                                 matchups: []))
            }
        }

        test("every missing-person fallback still consumes all eight public RNG draws") {
            let empty = SnapPersonnel(offense: [], defense: [])
            let noCarrier = SnapPersonnel(
                offense: even.offense.filter { $0.position != .runningBack }, defense: even.defense
            )
            let noLanePair = SnapPersonnel(
                offense: even.offense.filter { $0.position.group != .offensiveLine },
                defense: even.defense
            )
            let noPursuer = SnapPersonnel(offense: even.offense, defense: [])
            let noPasser = SnapPersonnel(
                offense: even.offense.filter { $0.position != .quarterback }, defense: even.defense
            )
            let noRoutePair = SnapPersonnel(
                offense: even.offense.filter { $0.position.group != .receivers },
                defense: even.defense
            )
            let noProtectionPair = noLanePair
            let noSpecialist = SnapPersonnel(
                offense: even.offense.filter { $0.position.group != .specialists },
                defense: even.defense
            )
            let cases: [(name: String, playType: OffensivePlayType,
                         personnel: SnapPersonnel, expected: SnapOutcome)] = [
                ("empty run", .run, empty,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("empty pass", .pass, empty,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("empty field goal", .fieldGoal, empty,
                 SnapOutcome(result: .fieldGoalMissed, yards: 0,
                             secondsElapsed: rules.stoppedPlaySeconds, matchups: [])),
                ("run missing carrier", .run, noCarrier,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("run missing lane pair", .run, noLanePair,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("run missing pursuer", .run, noPursuer,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("pass missing passer", .pass, noPasser,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("pass missing route pair", .pass, noRoutePair,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("pass missing protection pair", .pass, noProtectionPair,
                 SnapOutcome(result: .gain, yards: 0,
                             secondsElapsed: rules.inBoundsPlaySeconds, matchups: [])),
                ("field goal missing specialist", .fieldGoal, noSpecialist,
                 SnapOutcome(result: .fieldGoalMissed, yards: 0,
                             secondsElapsed: rules.stoppedPlaySeconds, matchups: [])),
                ("field goal missing ranked defender", .fieldGoal, noPursuer,
                 SnapOutcome(result: .fieldGoalMissed, yards: 0,
                             secondsElapsed: rules.stoppedPlaySeconds, matchups: [])),
            ]

            for (index, item) in cases.enumerated() {
                let seed = UInt64(50_000 + index)
                var actual = SeededRandom(seed: seed)
                let outcome = DistributionSnapResolver.resolve(
                    tier: .pro, offensiveCall: OffensiveCall(playType: item.playType),
                    defensiveCall: DefensiveCall(coverage: .man), personnel: item.personnel,
                    situation: Situation(), isHomeOffense: false, rng: &actual
                )
                expectEqual(outcome, item.expected, "\(item.name) changed the exact fallback")
                var expected = SeededRandom(seed: seed)
                for _ in 0..<8 { _ = expected.double01() }
                expectEqual(actual.next(), expected.next(),
                            "\(item.name) did not consume exactly eight draws")
            }
        }

        test("only the preselected run lane can move its sampled boundary") {
            let attribution = Double.zero
            var boostedOffense = even.offense
            let initiallyFirst = Assignment.assign(
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man), personnel: even
            ).runLane.first!.blocker.id
            let boostedIndex = boostedOffense.firstIndex { $0.id == initiallyFirst }!
            for attribute in boostedOffense[boostedIndex].position.ratedAttributes {
                boostedOffense[boostedIndex].attributes[attribute] = Rating(99)
            }
            let basePersonnel = SnapPersonnel(offense: boostedOffense, defense: even.defense)
            let baseAssignment = Assignment.assign(
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man), personnel: basePersonnel
            )
            let selectedID = baseAssignment.runLane.first!.blocker.id
            let unselectedID = baseAssignment.runLane.last!.blocker.id

            func changing(_ id: UUID, runBlock: Int) -> SnapPersonnel {
                var offense = basePersonnel.offense
                let index = offense.firstIndex { $0.id == id }!
                offense[index].attributes[.runBlock] = Rating(runBlock)
                return SnapPersonnel(offense: offense, defense: basePersonnel.defense)
            }

            let selectedWeak = changing(selectedID, runBlock: 40)
            let unselectedWeak = changing(unselectedID, runBlock: 65)
            var moved = false
            for index in 0...10_000 {
                let roll = Double(index) / 10_000
                let injected = draws(outcome: roll, attribution: attribution)
                let goalLine = Situation(yardLine: 99)
                let baseline = resolve(OffensiveCall(playType: .run), situation: goalLine,
                                       personnel: basePersonnel, draws: injected)
                let selected = resolve(OffensiveCall(playType: .run), situation: goalLine,
                                       personnel: selectedWeak, draws: injected)
                let unselected = resolve(OffensiveCall(playType: .run), situation: goalLine,
                                         personnel: unselectedWeak, draws: injected)
                expectEqual(unselected.result, baseline.result,
                            "an unselected lane participant moved the table")
                if selected.result != baseline.result {
                    moved = true
                    expectEqual(selected.matchups.first?.attackerID, selectedID)
                }
            }
            expect(moved, "weakening the selected lane never moved a bucket boundary")
        }

        test("only the preselected protection pair can move the sack boundary") {
            let call = OffensiveCall(playType: .pass)
            let defence = DefensiveCall(coverage: .man)
            var boostedOffense = even.offense
            let initiallyFirst = Assignment.assign(offensiveCall: call, defensiveCall: defence,
                                                   personnel: even).protection.first!.blocker.id
            let boostedIndex = boostedOffense.firstIndex { $0.id == initiallyFirst }!
            for attribute in boostedOffense[boostedIndex].position.ratedAttributes {
                boostedOffense[boostedIndex].attributes[attribute] = Rating(99)
            }
            let basePersonnel = SnapPersonnel(offense: boostedOffense, defense: even.defense)
            let baseAssignment = Assignment.assign(offensiveCall: call, defensiveCall: defence,
                                                   personnel: basePersonnel)
            let selected = baseAssignment.protection.first!
            let unselectedID = baseAssignment.protection.last!.blocker.id

            func changing(_ id: UUID, passBlock: Int) -> SnapPersonnel {
                var offense = basePersonnel.offense
                let index = offense.firstIndex { $0.id == id }!
                offense[index].attributes[.passBlock] = Rating(passBlock)
                return SnapPersonnel(offense: offense, defense: basePersonnel.defense)
            }

            let selectedWeak = changing(selected.blocker.id, passBlock: 40)
            let unselectedWeak = changing(unselectedID, passBlock: 40)
            var movedToSack = false
            for index in 0...10_000 {
                let injected = draws(outcome: Double(index) / 10_000,
                                     attribution: Double.zero)
                let baseline = resolve(call, personnel: basePersonnel, draws: injected,
                                       defence: defence)
                let weakened = resolve(call, personnel: selectedWeak, draws: injected,
                                       defence: defence)
                let control = resolve(call, personnel: unselectedWeak, draws: injected,
                                      defence: defence)
                expectEqual(control.result, baseline.result,
                            "an unselected protection blocker moved the table")
                if weakened.result == .sack, baseline.result != .sack {
                    movedToSack = true
                    let record = weakened.decidingMatchup
                    expectEqual(record?.attackerID, selected.blocker.id)
                    expectEqual(record?.defenderID, selected.rusher.id)
                }
            }
            expect(movedToSack, "weakening selected protection never expanded the sack bucket")
        }

        test("fumbles stop short of the goal line and losses become safeties") {
            func firstFumble(_ call: OffensiveCall) -> SnapOutcome? {
                for index in 0...1_000 {
                    let outcome = resolve(call, situation: Situation(yardLine: 99),
                                          draws: draws(outcome: Double(index) / 1_000,
                                                       yardage: Double(1).nextDown))
                    if outcome.result == .fumbleLost { return outcome }
                }
                return nil
            }
            for call in [OffensiveCall(playType: .run), OffensiveCall(playType: .pass)] {
                let fumble = firstFumble(call)
                expectEqual(fumble?.yards, 0, "a fumble crossed the goal line")
                expectEqual(fumble?.decidingMatchup?.kind, .ballSecurity)
            }
            let runSafety = resolve(OffensiveCall(playType: .run),
                                    situation: Situation(yardLine: 1),
                                    draws: draws(outcome: 0, yardage: 0))
            expectEqual(runSafety.result, .safety)
            expectEqual(runSafety.yards, -1)
            let passSafety = resolve(OffensiveCall(playType: .pass),
                                     situation: Situation(yardLine: 1),
                                     draws: draws(outcome: 0, yardage: 0))
            expectEqual(passSafety.result, .safety)
            expectEqual(passSafety.yards, -1)
        }

        test("all resolver branches consume exactly the fixed eight-draw budget") {
            let wanted: Set<String> = ["run loss", "run gain", "run fumble",
                                       "pass sack", "pass incompletion", "pass completion",
                                       "field goal good", "field goal missed", "punt", "kneel"]
            var seen: Set<String> = []
            for seed in UInt64(1)...20_000 where seen != wanted {
                for playType in OffensivePlayType.allCases {
                    var actual = SeededRandom(seed: seed)
                    let outcome = DistributionSnapResolver.resolve(
                        tier: .pro, offensiveCall: OffensiveCall(playType: playType),
                        defensiveCall: DefensiveCall(coverage: .man), personnel: even,
                        situation: Situation(), isHomeOffense: false, rng: &actual
                    )
                    let branch: String?
                    switch (playType, outcome.result) {
                    case (.run, .gain) where outcome.yards <= 0: branch = "run loss"
                    case (.run, .gain), (.run, .touchdown): branch = "run gain"
                    case (.run, .fumbleLost): branch = "run fumble"
                    case (.pass, .sack): branch = "pass sack"
                    case (.pass, .incompletion): branch = "pass incompletion"
                    case (.pass, .gain), (.pass, .touchdown): branch = "pass completion"
                    case (.fieldGoal, .fieldGoalGood): branch = "field goal good"
                    case (.fieldGoal, .fieldGoalMissed): branch = "field goal missed"
                    case (.punt, .punt): branch = "punt"
                    case (.kneel, .kneel): branch = "kneel"
                    default: branch = nil
                    }
                    guard let branch, wanted.contains(branch) else { continue }
                    var expected = SeededRandom(seed: seed)
                    for _ in 0..<8 { _ = expected.double01() }
                    expectEqual(actual.next(), expected.next(),
                                "\(playType)/\(outcome.result) did not consume eight draws")
                    seen.insert(branch)
                }
            }
            expectEqual(seen, wanted, "not every fixed-budget branch was sampled")
        }

        test("reading an already-resolved distribution game cannot change it") {
            var rng = SeededRandom(seed: 7_007)
            let calls = [OffensivePlayType.run, .pass, .fieldGoal, .punt, .kneel]
            let plays = calls.enumerated().map { index, playType in
                let situation = Situation(down: 1, distance: 10, yardLine: 25 + index)
                let call = OffensiveCall(playType: playType)
                let outcome = DistributionSnapResolver.resolve(
                    tier: .pro, offensiveCall: call,
                    defensiveCall: DefensiveCall(coverage: .zoneUnder), personnel: even,
                    situation: situation, isHomeOffense: true, rng: &rng
                )
                return PlayRecord(situation: situation, offensiveCall: call,
                                  defensiveCall: DefensiveCall(coverage: .zoneUnder),
                                  preSnapSeconds: 0, outcome: outcome, callInTriggers: [])
            }
            let game = GameRecord(homeScore: 0, awayScore: 0,
                                  drives: [DriveRecord(offense: .home, plays: plays,
                                                       ending: .punt, pointsScored: 0,
                                                       startYardLine: 25)], tier: .pro)
            let before = game.playByPlayFingerprint
            for play in game.plays {
                _ = play.outcome.decidingMatchup
                _ = play.outcome.matchups.map(\.leverage)
                _ = play.outcome.result.stopsClock
            }
            expectEqual(game.playByPlayFingerprint, before)
        }
    }
}

// MARK: - Drive and game loops

func runGameLoopTests() {
    let home = testPersonnel(offenseSkill: 74, defenseSkill: 72)
    let away = testPersonnel(offenseSkill: 68, defenseSkill: 70)

    func identityGame(carrier: UUID, passer: UUID, target: UUID) -> GameRecord {
        let situation = Situation()
        let call = OffensiveCall(playType: .pass)
        let outcome = SnapOutcome(result: .gain, yards: 7,
                                  secondsElapsed: Tier.pro.clockRules.inBoundsPlaySeconds,
                                  matchups: [], ballCarrierID: carrier,
                                  passerID: passer, targetID: target)
        let play = PlayRecord(situation: situation, offensiveCall: call,
                              defensiveCall: DefensiveCall(coverage: .man),
                              preSnapSeconds: 0, outcome: outcome, callInTriggers: [])
        return GameRecord(homeScore: 0, awayScore: 0,
                          drives: [DriveRecord(offense: .home, plays: [play], ending: .punt,
                                               pointsScored: 0, startYardLine: 25)], tier: .pro)
    }

    let identityA = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
    let identityB = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
    let identityC = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!
    let identityD = UUID(uuidString: "00000000-0000-4000-8000-000000000004")!

    suite("Game loop") {
        test("college first downs stop only inside two minutes") {
            func stops(_ tier: Tier, _ seconds: Int) -> Bool {
                DriveEngine.firstDownStopsClock(
                    madeFirstDown: true,
                    situation: Situation(quarter: 2, secondsRemainingInQuarter: seconds),
                    rules: tier.clockRules
                )
            }
            expect(!stops(.college, 300), "college stopped after a first down with five minutes left")
            expect(stops(.college, 90), "college did not stop after a first down inside two minutes")
            expect(stops(.college, 120), "college did not stop at the exact two-minute boundary")
            expect(!stops(.college, 121), "college stopped one second before the two-minute boundary")
            expect(!DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 1, secondsRemainingInQuarter: 90),
                rules: CollegeClockRules.self
            ), "first-quarter 1:30 was mistaken for the end of the half")
            expect(!DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 3, secondsRemainingInQuarter: 90),
                rules: CollegeClockRules.self
            ), "third-quarter 1:30 was mistaken for the end of the half")
            expect(DriveEngine.firstDownStopsClock(
                madeFirstDown: true,
                situation: Situation(quarter: 4, secondsRemainingInQuarter: 90),
                rules: CollegeClockRules.self
            ), "fourth-quarter 1:30 did not use end-of-half timing")
            expect(!stops(.pro, 300), "pro stopped after a first down with five minutes left")
            expect(!stops(.pro, 90), "pro stopped after a first down inside two minutes")

            expectEqual(DriveEngine.preSnapSeconds(
                clockRunning: false, clockStoppedByFirstDown: true, tempo: .normal,
                rules: CollegeClockRules.self
            ), CollegeClockRules.readyForPlaySeconds,
            "college first-down restart did not charge the 18-second ready-for-play interval")
        }

        test("a college first-down restart records and charges ready-for-play time") {
            struct FixedRunCaller: PlayCaller, Sendable {
                func offensiveCall(for situation: Situation,
                                   rules: any ClockRules.Type) -> OffensiveCall {
                    OffensiveCall(playType: .run, tempo: .normal)
                }

                func defensiveCall(for situation: Situation,
                                   rules: any ClockRules.Type) -> DefensiveCall {
                    DefensiveCall(coverage: .man)
                }
            }

            let start = Situation(down: 1, distance: 1, yardLine: 25, possession: .home,
                                  quarter: 2, secondsRemainingInQuarter: 125)
            let offense = testPersonnel(offenseSkill: 99, defenseSkill: 40)
            let defense = testPersonnel(offenseSkill: 40, defenseSkill: 99)

            func drive(_ rules: any ClockRules.Type, seed: UInt64) -> DriveRecord {
                DriveEngine.run(from: start, offense: offense, defense: defense,
                                caller: FixedRunCaller(), rules: rules, homeFieldAdvantage: 0,
                                driveSeed: seed, isAfterTurnover: false, clockRunning: true).drive
            }

            var selectedSeed: UInt64?
            var collegeDrive: DriveRecord?
            for seed in UInt64(1)...200 {
                let candidate = drive(CollegeClockRules.self, seed: seed)
                guard candidate.plays.count >= 3,
                      candidate.plays[0].outcome.yards >= candidate.plays[0].situation.distance,
                      !candidate.plays[0].outcome.result.isTurnover
                else { continue }
                selectedSeed = seed
                collegeDrive = candidate
                break
            }

            guard let seed = selectedSeed, let college = collegeDrive else {
                expect(false, "no qualifying college first-down drive found in seeds 1...200")
                return
            }
            let second = college.plays[1]
            let third = college.plays[2]
            expectEqual(second.preSnapSeconds, CollegeClockRules.readyForPlaySeconds,
                        "seed \(seed): college restart did not record ready-for-play time")
            expectEqual(third.situation.secondsRemainingInQuarter,
                        second.situation.secondsRemainingInQuarter
                            - second.preSnapSeconds - second.outcome.secondsElapsed,
                        "seed \(seed): recorded college restart time was not charged to the clock")

            let pro = drive(ProClockRules.self, seed: seed)
            expect(pro.plays.count >= 2, "seed \(seed): pro fixture ended before the restart snap")
            expectEqual(pro.plays[1].preSnapSeconds, ProClockRules.normalTempoSnapSeconds,
                        "seed \(seed): pro first down used the college ready-for-play interval")
        }

        test("the same seed replays a game exactly, by hash of the full play-by-play") {
            // 03 section 3's test, verbatim: "same seed across two separate process invocations,
            // compared by hash of the full play-by-play". The in-process half is here; the
            // cross-process half is the pinned fingerprint below, which is a literal in a source
            // file and therefore cannot be salted per launch.
            let first = GameEngine.play(tier: .pro, home: home, away: away, seed: 12_345)
            let second = GameEngine.play(tier: .pro, home: home, away: away, seed: 12_345)
            expectEqual(first.playByPlayFingerprint, second.playByPlayFingerprint,
                        "the same seed produced a different game")
            expectEqual(first, second, "the same seed produced a different record")
        }

        test("the play-by-play fingerprint is pinned across processes") {
            // Regenerate only when the engine is changed deliberately. P4's calibration will move
            // it, and that is the point: a tuning change must be a visible edit here.
            expectEqual(GameEngine.play(tier: .pro, home: home, away: away, seed: 12_345)
                            .playByPlayFingerprint,
                        PINNED_PRO_GAME_FINGERPRINT,
                        "the engine's output changed. If that was deliberate, re-pin")
            expectEqual(GameEngine.play(tier: .college, home: home, away: away, seed: 12_345)
                            .playByPlayFingerprint,
                        PINNED_COLLEGE_GAME_FINGERPRINT,
                        "the engine's output changed. If that was deliberate, re-pin")
        }

        test("the fingerprint notices a single play moving") {
            // The self-test. A fingerprint that ignored order or magnitude would make the pin above
            // green forever.
            let game = GameEngine.play(tier: .pro, home: home, away: away, seed: 12_345)
            let reversed = GameRecord(homeScore: game.homeScore, awayScore: game.awayScore,
                                      drives: game.drives.reversed(), tier: game.tier)
            expect(reversed.playByPlayFingerprint != game.playByPlayFingerprint,
                   "the fingerprint ignores drive order")
            let nudged = GameRecord(homeScore: game.homeScore + 1, awayScore: game.awayScore,
                                    drives: game.drives, tier: game.tier)
            expect(nudged.playByPlayFingerprint != game.playByPlayFingerprint,
                   "the fingerprint ignores the score")
        }

        test("a different seed produces a different game") {
            let a = GameEngine.play(tier: .pro, home: home, away: away, seed: 1)
            let b = GameEngine.play(tier: .pro, home: home, away: away, seed: 2)
            expect(a.playByPlayFingerprint != b.playByPlayFingerprint,
                   "two seeds produced the same game, so the seed is not being read")
        }

        test("a game finishes, scores, and stays inside its bounds") {
            for seed in UInt64(1)...30 {
                let game = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                expect(!game.drives.isEmpty, "seed \(seed) produced no drives")
                expect(game.drives.count <= MatchupRules.maximumDrivesPerGame,
                       "seed \(seed) ran past the drive bound")
                expect(game.homeScore >= 0 && game.awayScore >= 0,
                       "seed \(seed) produced a negative score")
                for drive in game.drives {
                    expect(drive.plays.count <= MatchupRules.maximumPlaysPerDrive,
                           "a drive ran past the play bound")
                    expect((1...99).contains(drive.startYardLine),
                           "a drive started off the field at \(drive.startYardLine)")
                }
                for play in game.plays {
                    expect((1...99).contains(play.situation.yardLine),
                           "a snap happened off the field")
                    expect((1...4).contains(play.situation.down),
                           "a snap happened on down \(play.situation.down)")
                }
            }
        }

        test("college games run more plays than pro games") {
            // 03 section 2: higher college tempo must be a CONSEQUENCE of the clock model. The
            // college clock stops after first downs inside two minutes and its offence snaps
            // faster, so with the same rosters and the same seed it must fit more plays into the
            // same four quarters. This is
            // not a calibration band — P4 owns those — it is the direction the model must point.
            var collegePlays = 0, proPlays = 0
            for seed in UInt64(1)...20 {
                collegePlays += GameEngine.play(tier: .college, home: home, away: away,
                                                seed: seed).plays.count
                proPlays += GameEngine.play(tier: .pro, home: home, away: away, seed: seed).plays.count
            }
            expect(collegePlays > proPlays,
                   "college fitted \(collegePlays) plays into 20 games against pro's \(proPlays), "
                       + "so the tier clock difference is not reaching the play count")
        }

        test("the better team wins more often than not") {
            // Not a calibration band. Just the sign: if the stronger roster did not win more, the
            // engine would be noise with a scoreboard.
            var homeWins = 0, decided = 0
            for seed in UInt64(1)...120 {
                let game = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                guard let winner = game.winner else { continue }
                decided += 1
                if winner == .home { homeWins += 1 }
            }
            expect(decided > 100, "only \(decided) of 120 games were decided")
            expect(homeWins * 2 > decided,
                   "the better team won \(homeWins) of \(decided), which is not more than half")
        }

        test("every drive ending is reachable") {
            // Dead capability again. A drive ending the loop declares and never produces is a
            // branch nothing exercises.
            var seen: Set<DriveEnding> = []
            for seed in UInt64(1)...200 {
                for drive in GameEngine.play(tier: .college, home: home, away: away,
                                             seed: seed).drives {
                    seen.insert(drive.ending)
                }
            }
            // No exemptions. `endOfGame` used to be here and was exempted; it covered the same
            // event as `endOfHalf`, nothing produced it, and an exemption is how a declared-but-
            // unreachable case survives its own reachability test. It was deleted instead.
            let unreachable = DriveEnding.allCases.filter { !seen.contains($0) }
            expect(unreachable.isEmpty,
                   "these drive endings never happen: "
                       + unreachable.map(\.rawValue).joined(separator: ", "))
        }

        test("call-ins fire at a rate 02 section 3.1 would recognise") {
            // What this measures is the number of snaps that QUALIFY, which is not the same as the
            // number of call-ins the player sees. 02 section 3.1 sets the rate at ~25 a game,
            // tunable 12 to 40, and that is a budget applied to the qualifying set — the phase that
            // builds the call-in queue owns the selection. Asserting the raw qualifying count
            // against the tunable ceiling conflated the two, and the first version of this test did
            // exactly that.
            //
            // What P3 can assert is that the qualifying set is neither empty nor everything. Empty
            // is the previous build's failure verbatim: one mandatory decision a week. Everything
            // would mean the triggers are not selecting.
            var qualifying = 0, snaps = 0
            for seed in UInt64(1)...20 {
                let game = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                qualifying += game.plays.filter { !$0.callInTriggers.isEmpty }.count
                snaps += game.plays.count
            }
            let perGame = Double(qualifying) / 20
            expect(perGame >= Double(SharedRules.callInsPerGameRange.lowerBound),
                   "only \(perGame) snaps a game qualify for a call-in, which is under the 12 the "
                       + "tunable range's floor would need to select from")
            expect(Double(qualifying) < Double(snaps) * 0.8,
                   "\(qualifying) of \(snaps) snaps qualify, so the triggers are not selecting")
        }

        test("rendering cannot change an outcome") {
            // 03 section 1.3's honesty invariant, engine half. A GameRecord is a value type with no
            // reference to the engine, so a consumer holding one cannot reach back into the
            // simulation; and re-reading it any number of times cannot alter it. This asserts the
            // property a match view would rely on before there is a match view to rely on it.
            let game = GameEngine.play(tier: .pro, home: home, away: away, seed: 777)
            let before = game.playByPlayFingerprint
            for play in game.plays {
                _ = play.outcome.decidingMatchup
                _ = play.outcome.matchups.map(\.leverage)
                _ = play.outcome.result.stopsClock
            }
            expectEqual(game.playByPlayFingerprint, before,
                        "reading a game changed it")
            expectEqual(GameEngine.play(tier: .pro, home: home, away: away, seed: 777)
                            .playByPlayFingerprint, before,
                        "replaying after reading produced a different game")
        }

        test("tempo changes how much of the game clock a drive burns") {
            // Where tempo actually bites now: the drive loop charges the pre-snap clock, and only
            // when the clock was running.
            func secondsUsed(_ tempo: Tempo) -> Int {
                struct FixedTempoCaller: PlayCaller, Sendable {
                    let tempo: Tempo
                    func offensiveCall(for situation: Situation,
                                       rules: any ClockRules.Type) -> OffensiveCall {
                        OffensiveCall(playType: .run, tempo: tempo)
                    }
                    func defensiveCall(for situation: Situation,
                                       rules: any ClockRules.Type) -> DefensiveCall {
                        DefensiveCall(coverage: .man)
                    }
                }
                let game = GameEngine.play(tier: .pro, home: home, away: away,
                                           caller: FixedTempoCaller(tempo: tempo), seed: 4_040)
                return game.plays.count
            }
            expect(secondsUsed(.hurry) > secondsUsed(.bleed),
                   "hurrying up did not fit more plays into the game than bleeding the clock")
        }

        test("the clock only runs when it should") {
            // `stopsClock` and the inside-two-minute first-down stop are clock decisions the
            // drive loop must apply. Ignoring the latter would erase a real tier difference.
            //
            // Asserted through the consequence: with the same rosters and seeds, the tier whose
            // clock stops after late first downs fits more plays into the same four quarters.
            var collegeFirstDowns = 0, proFirstDowns = 0
            var collegePlays = 0, proPlays = 0
            for seed in UInt64(1)...12 {
                let college = GameEngine.play(tier: .college, home: home, away: away, seed: seed)
                let pro = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                collegePlays += college.plays.count
                proPlays += pro.plays.count
                collegeFirstDowns += college.plays.filter {
                    $0.outcome.yards >= $0.situation.distance
                }.count
                proFirstDowns += pro.plays.filter { $0.outcome.yards >= $0.situation.distance }.count
            }
            expect(collegeFirstDowns > 0 && proFirstDowns > 0, "no first downs were made at all")
            expect(collegePlays > proPlays,
                   "college fitted \(collegePlays) plays against pro's \(proPlays), so the "
                       + "first-down clock stop is not reaching the play count")
        }

        test("possession does not change at the end of the first or third quarter") {
            // It did, in every game: the drive loop treated every quarter boundary as the end of a
            // half and the epilogue handed the ball over unconditionally.
            for seed in UInt64(1)...25 {
                let game = GameEngine.play(tier: .pro, home: home, away: away, seed: seed)
                for (index, drive) in game.drives.enumerated() where drive.ending == .endOfQuarter {
                    guard index + 1 < game.drives.count else { continue }
                    expectEqual(game.drives[index + 1].offense, drive.offense,
                                "seed \(seed): possession changed at a quarter boundary")
                }
            }
        }

        test("the after-turnover call-in trigger actually fires") {
            // 02 section 3.1 lists it. It was a local of DriveEngine.run that nothing ever set to
            // true, so it was a declared trigger the game could not produce — dead capability in
            // the one system the previous build failed hardest at.
            var fired = 0
            for seed in UInt64(1)...40 {
                for play in GameEngine.play(tier: .pro, home: home, away: away, seed: seed).plays
                where play.callInTriggers.contains(.afterTurnover) {
                    fired += 1
                }
            }
            expect(fired > 0, "the after-turnover trigger never fired across 40 games")
        }

        test("the fingerprint sees possession, the calls and the players") {
            // Seven mutations of a real game used to produce a byte-identical fingerprint,
            // including flipping possession on every drive. A determinism gate that cannot see who
            // had the ball is not one.
            let game = GameEngine.play(tier: .pro, home: home, away: away, seed: 12_345)
            let base = game.playByPlayFingerprint

            func rebuilt(_ transform: (PlayRecord) -> PlayRecord) -> UInt64 {
                GameRecord(
                    homeScore: game.homeScore, awayScore: game.awayScore,
                    drives: game.drives.map {
                        DriveRecord(offense: $0.offense, plays: $0.plays.map(transform),
                                    ending: $0.ending, pointsScored: $0.pointsScored,
                                    startYardLine: $0.startYardLine)
                    },
                    tier: game.tier
                ).playByPlayFingerprint
            }
            expect(rebuilt { play in
                var situation = play.situation
                situation.possession = situation.possession.opponent
                return PlayRecord(situation: situation, offensiveCall: play.offensiveCall,
                                  defensiveCall: play.defensiveCall,
                                  preSnapSeconds: play.preSnapSeconds, outcome: play.outcome,
                                  callInTriggers: play.callInTriggers)
            } != base, "the fingerprint ignores possession")
            expect(rebuilt { play in
                PlayRecord(situation: play.situation,
                           offensiveCall: OffensiveCall(playType: .kneel),
                           defensiveCall: play.defensiveCall,
                           preSnapSeconds: play.preSnapSeconds, outcome: play.outcome,
                           callInTriggers: play.callInTriggers)
            } != base, "the fingerprint ignores the offensive call")
            expect(rebuilt { play in
                PlayRecord(situation: play.situation, offensiveCall: play.offensiveCall,
                           defensiveCall: play.defensiveCall,
                           preSnapSeconds: play.preSnapSeconds, outcome: play.outcome,
                           callInTriggers: [])
            } != base, "the fingerprint ignores the call-in triggers")
            expect(rebuilt { play in
                PlayRecord(situation: play.situation, offensiveCall: play.offensiveCall,
                           defensiveCall: play.defensiveCall,
                           preSnapSeconds: play.preSnapSeconds + 1, outcome: play.outcome,
                           callInTriggers: play.callInTriggers)
            } != base, "the fingerprint ignores pre-snap clock charges")
            expect(GameRecord(homeScore: game.homeScore, awayScore: game.awayScore,
                              drives: game.drives, tier: .college).playByPlayFingerprint != base,
                   "the fingerprint ignores the tier")
        }

        test("replacing only the carrier changes the fingerprint") {
            let original = identityGame(carrier: identityA, passer: identityB, target: identityC)
            let changed = identityGame(carrier: identityD, passer: identityB, target: identityC)
            expect(original.playByPlayFingerprint != changed.playByPlayFingerprint,
                   "the fingerprint ignores the carrier")
            let restored = try SaveEnvelope.decode(GameRecord.self,
                                                   from: try SaveEnvelope.encode(original))
            expectEqual(restored.playByPlayFingerprint, original.playByPlayFingerprint)
        }

        test("replacing only the passer changes the fingerprint") {
            let original = identityGame(carrier: identityA, passer: identityB, target: identityC)
            let changed = identityGame(carrier: identityA, passer: identityD, target: identityC)
            expect(original.playByPlayFingerprint != changed.playByPlayFingerprint,
                   "the fingerprint ignores the passer")
            let restored = try SaveEnvelope.decode(GameRecord.self,
                                                   from: try SaveEnvelope.encode(original))
            expectEqual(restored.playByPlayFingerprint, original.playByPlayFingerprint)
        }

        test("replacing only the target changes the fingerprint") {
            let original = identityGame(carrier: identityA, passer: identityB, target: identityC)
            let changed = identityGame(carrier: identityA, passer: identityB, target: identityD)
            expect(original.playByPlayFingerprint != changed.playByPlayFingerprint,
                   "the fingerprint ignores the target")
            let restored = try SaveEnvelope.decode(GameRecord.self,
                                                   from: try SaveEnvelope.encode(original))
            expectEqual(restored.playByPlayFingerprint, original.playByPlayFingerprint)
        }

        test("every throwing matchup names the defender covering the target") {
            // It named routes[0]'s defender, which was wrong on 42 percent of throws — so the
            // causal record 04 section 5.3 reads was a lie on nearly half the passes in the game.
            var checked = 0
            for seed in UInt64(1)...25 {
                for play in GameEngine.play(tier: .pro, home: home, away: away, seed: seed).plays {
                    guard let target = play.outcome.targetID else { continue }
                    guard let throwing = play.outcome.matchups.first(where: { $0.kind == .throwing }),
                          let route = play.outcome.matchups.first(where: {
                              $0.kind == .routeVersusCoverage && $0.attackerID == target
                          })
                    else { continue }
                    checked += 1
                    expectEqual(throwing.defenderID, route.defenderID,
                                "the throw credited a defender who was covering somebody else")
                }
            }
            expect(checked > 200, "only \(checked) throws were checkable")
        }

        test("a game survives the save envelope unchanged") {
            let game = GameEngine.play(tier: .college, home: home, away: away, seed: 99)
            let restored = try SaveEnvelope.decode(GameRecord.self,
                                                   from: try SaveEnvelope.encode(game))
            expectEqual(restored, game)
            expectEqual(restored.playByPlayFingerprint, game.playByPlayFingerprint)
        }

        test("a schema-1 save without pre-snap charges remains readable") {
            let game = GameEngine.play(tier: .college, home: home, away: away, seed: 99)
            let currentEnvelope = try SaveEnvelope.encode(game)
            let header = Data(currentEnvelope.prefix(SaveEnvelope.headerLength))
            let body = try JSONSerialization.jsonObject(
                with: currentEnvelope.dropFirst(SaveEnvelope.headerLength)
            )

            func removingPreSnapSeconds(from value: Any) -> Any {
                if var object = value as? [String: Any] {
                    object.removeValue(forKey: "preSnapSeconds")
                    return object.mapValues(removingPreSnapSeconds)
                }
                if let array = value as? [Any] {
                    return array.map(removingPreSnapSeconds)
                }
                return value
            }

            var legacyEnvelope = header
            legacyEnvelope.append(try JSONSerialization.data(
                withJSONObject: removingPreSnapSeconds(from: body), options: [.sortedKeys]
            ))
            expectEqual(try SaveEnvelope.schemaVersion(ofHeader: legacyEnvelope),
                        SaveEnvelope.currentSchemaVersion,
                        "the fixture must retain the schema-1 header")

            let restored = try SaveEnvelope.decode(GameRecord.self, from: legacyEnvelope)
            let expected = GameRecord(
                homeScore: game.homeScore,
                awayScore: game.awayScore,
                drives: game.drives.map { drive in
                    DriveRecord(
                        offense: drive.offense,
                        plays: drive.plays.map { play in
                            PlayRecord(
                                situation: play.situation,
                                offensiveCall: play.offensiveCall,
                                defensiveCall: play.defensiveCall,
                                preSnapSeconds: 0,
                                outcome: play.outcome,
                                callInTriggers: play.callInTriggers
                            )
                        },
                        ending: drive.ending,
                        pointsScored: drive.pointsScored,
                        startYardLine: drive.startYardLine
                    )
                },
                tier: game.tier
            )
            expectEqual(restored, expected,
                        "legacy schema-1 body did not preserve game data with zero pre-snap charges")
            expect(restored.plays.allSatisfy { $0.preSnapSeconds == 0 },
                   "a decoded legacy play retained a non-zero pre-snap charge")
        }

        test("a schema-1 save rejects a null pre-snap charge") {
            let game = GameEngine.play(tier: .college, home: home, away: away, seed: 99)
            let currentEnvelope = try SaveEnvelope.encode(game)
            let header = Data(currentEnvelope.prefix(SaveEnvelope.headerLength))
            let body = try JSONSerialization.jsonObject(
                with: currentEnvelope.dropFirst(SaveEnvelope.headerLength)
            )

            func nullingPreSnapSeconds(in value: Any) -> Any {
                if var object = value as? [String: Any] {
                    if object["preSnapSeconds"] != nil {
                        object["preSnapSeconds"] = NSNull()
                    }
                    return object.mapValues(nullingPreSnapSeconds)
                }
                if let array = value as? [Any] {
                    return array.map(nullingPreSnapSeconds)
                }
                return value
            }

            var malformedEnvelope = header
            malformedEnvelope.append(try JSONSerialization.data(
                withJSONObject: nullingPreSnapSeconds(in: body), options: [.sortedKeys]
            ))
            do {
                _ = try SaveEnvelope.decode(GameRecord.self, from: malformedEnvelope)
                expect(false, "an explicit null pre-snap charge decoded as a legacy missing key")
            } catch DecodingError.valueNotFound {
                // Expected: only an absent schema-1 key receives the legacy zero default.
            }
        }
    }
}
