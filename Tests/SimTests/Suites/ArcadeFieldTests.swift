import Foundation
import FootballSimCore

/// Fixtures for the all-22 kernel. Teams here are uniform on purpose: when every player at a
/// position rates the same, any difference the kernel produces has to have come from the one
/// rating the test moved.
enum FieldFixtures {
    static func team(rating: Int, name: String = "Test", abbreviation: String = "TST") -> Team {
        var built = Team(
            city: "Test City",
            name: name,
            abbreviation: abbreviation,
            colors: TeamColors(primaryHex: "#123456", secondaryHex: "#654321"),
            conference: .liberty,
            division: .east,
            stadiumName: "Test Field",
            roster: TestFixtures.roster(rating: rating)
        )
        built.autoSortDepthChart()
        return built
    }

    /// A team at `rating` everywhere except one attribute at one position.
    static func team(rating: Int, position: Position, attribute: Attribute, value: Int) -> Team {
        var built = team(rating: rating)
        for index in built.roster.indices where built.roster[index].position == position {
            built.roster[index].ratings[attribute] = value
        }
        built.autoSortDepthChart()
        return built
    }

    static func offense(_ team: Team) -> OffensivePersonnel { OffensivePersonnel(team: team) }

    static func defense(_ team: Team, call: DefensivePlay = .base) -> DefensivePersonnel {
        DefensivePersonnel(team: team, call: call)
    }

    static func kernel(
        offense offenseTeam: Team,
        defense defenseTeam: Team,
        call: OffensivePlay = .shortPass,
        defensiveCall: DefensivePlay = .base,
        seed: UInt64 = 4_100
    ) -> SnapKernel {
        SnapKernel(
            offense: offense(offenseTeam),
            defense: defense(defenseTeam, call: defensiveCall),
            call: call,
            defensiveCall: defensiveCall,
            seed: seed
        )
    }
}

func runArcadeFieldTests() {

    // MARK: - Tuning

    suite("ArcadeTuning") {
        test("rating curves are monotonic and clamp at the legal bounds") {
            var previous = -Double.infinity
            for rating in stride(from: 40, through: 99, by: 1) {
                let value = ArcadeTuning.curve(rating, at40: 1, at99: 10)
                expect(value >= previous, "curve dipped at \(rating)")
                previous = value
            }
            expectClose(ArcadeTuning.curve(40, at40: 1, at99: 10), 1, 0.0001)
            expectClose(ArcadeTuning.curve(99, at40: 1, at99: 10), 10, 0.0001)
            expectClose(ArcadeTuning.curve(20, at40: 1, at99: 10), 1, 0.0001, "below floor must clamp")
            expectClose(ArcadeTuning.curve(150, at40: 1, at99: 10), 10, 0.0001, "above ceiling must clamp")
        }

        test("inverted curves work the same way round") {
            expect(
                ArcadeTuning.indicatorLatency(99) < ArcadeTuning.indicatorLatency(40),
                "awareness must buy a shorter delay, not a longer one"
            )
            expectClose(ArcadeTuning.indicatorLatency(40), 0.90, 0.001)
            expectClose(ArcadeTuning.indicatorLatency(99), 0.15, 0.001)
        }

        test("the execution caps are the ones the design document promises") {
            expectClose(ArcadeTuning.completionSwing, 0.20, 0.0001)
            expectClose(ArcadeTuning.yardsSwing, 6.0, 0.0001)
            expectClose(ArcadeTuning.kickSwing, 0.18, 0.0001)
            expectClose(ArcadeTuning.defensiveSwing, 0.10, 0.0001)
        }

        test("scatter shrinks with accuracy and grows with distance and pressure") {
            expect(ArcadeTuning.scatterRadius(99) < ArcadeTuning.scatterRadius(40))
            expectClose(ArcadeTuning.scatterRadius(99), 0.5, 0.001)
            expectClose(ArcadeTuning.scatterDistanceFactor(throwYards: 5), 1.0, 0.001)
            expectClose(ArcadeTuning.scatterDistanceFactor(throwYards: 30), 1.6, 0.001)
            expect(
                ArcadeTuning.scatterDistanceFactor(throwYards: 60) <= 1.6,
                "the distance factor must not run away past its stated ceiling"
            )
        }

        test("difficulty moves only reaction, closing and discipline") {
            expect(ArcadeTuning.hardDials.reactionMultiplier < ArcadeTuning.normalDials.reactionMultiplier)
            expect(ArcadeTuning.hardDials.closingMultiplier > ArcadeTuning.normalDials.closingMultiplier)
            expect(ArcadeTuning.easyDials.coverageDiscipline < ArcadeTuning.normalDials.coverageDiscipline)
        }
    }

    // MARK: - Geometry

    suite("Field geometry") {
        test("a yard sideways costs the same as a yard forward") {
            let origin = FieldPoint.yards(depth: 0, lateralYards: 0)
            let forward = FieldPoint.yards(depth: 5, lateralYards: 0)
            let sideways = FieldPoint.yards(depth: 0, lateralYards: 5)
            expectClose(origin.distance(to: forward), 5, 0.001)
            expectClose(
                origin.distance(to: sideways), 5, 0.001,
                "lateral distance must convert to yards or pursuit angles are wrong"
            )
        }

        test("nobody runs out of bounds") {
            let wide = FieldPoint(depth: 10, lateral: 4).clampedToField()
            expect(abs(wide.lateral) <= 1, "clamped point still off the field")
            expect(abs(wide.lateralYards) < ArcadeTuning.fieldWidthYards / 2)
        }

        test("closing speed is positive when the gap is shrinking") {
            let defender = FieldPoint.yards(depth: 0, lateralYards: 0)
            let receiver = FieldPoint.yards(depth: 10, lateralYards: 0)
            let chasing = closingSpeed(
                defender: defender,
                defenderVelocity: FieldVector(depth: 8, lateralYards: 0),
                receiver: receiver,
                receiverVelocity: FieldVector(depth: 5, lateralYards: 0)
            )
            expectClose(chasing, 3, 0.001, "a faster chaser closes at the speed difference")

            let losing = closingSpeed(
                defender: defender,
                defenderVelocity: FieldVector(depth: 5, lateralYards: 0),
                receiver: receiver,
                receiverVelocity: FieldVector(depth: 9, lateralYards: 0)
            )
            expect(losing < 0, "a receiver pulling away must read as negative closing")
        }

        test("morale reaches the two attributes the design says it touches") {
            var happy = TestFixtures.player(position: .wr, rating: 70)
            happy.morale = 95
            var miserable = TestFixtures.player(position: .wr, rating: 70)
            miserable.morale = 10
            expect(
                Athlete(player: happy).catching > Athlete(player: miserable).catching,
                "morale should move catching"
            )
            expectEqual(
                Athlete(player: happy).speed, Athlete(player: miserable).speed,
                "morale must not move speed"
            )
        }
    }

    // MARK: - Formations

    suite("Formations") {
        let offenseTeam = FieldFixtures.team(rating: 70)
        let defenseTeam = FieldFixtures.team(rating: 70, name: "Other", abbreviation: "OTH")

        test("both sides field exactly eleven, and eleven different men") {
            for call in OffensivePlay.standardCalls {
                let players = Formations.offense(
                    for: call, personnel: FieldFixtures.offense(offenseTeam)
                )
                expectEqual(players.count, 11, "\(call.displayName) fielded \(players.count)")
                expectEqual(
                    Set(players.map(\.id)).count, 11,
                    "\(call.displayName) fielded the same player twice"
                )
            }
            for call in DefensivePlay.allCases {
                let players = Formations.defense(
                    for: call, personnel: FieldFixtures.defense(defenseTeam, call: call)
                )
                expectEqual(players.count, 11, "\(call.displayName) fielded \(players.count)")
                expectEqual(Set(players.map(\.id)).count, 11, "\(call.displayName) duplicated a player")
            }
        }

        test("nobody lines up out of bounds") {
            let players = Formations.offense(
                for: .deepPass, personnel: FieldFixtures.offense(offenseTeam)
            )
            for player in players {
                expect(
                    abs(player.point.lateral) <= 1,
                    "\(player.athlete.name) lined up off the field at \(player.point.lateral)"
                )
            }
        }

        test("sub packages really are personnel changes") {
            expectEqual(DefensivePersonnel.counts(for: .base).lb, 3)
            expectEqual(DefensivePersonnel.counts(for: .nickel).cb, 3, "nickel is the fifth back")
            expectEqual(DefensivePersonnel.counts(for: .dime).cb, 4, "dime is the sixth")
            expect(
                DefensivePersonnel.counts(for: .dime).lb < DefensivePersonnel.counts(for: .base).lb,
                "the extra back has to come from somewhere"
            )
            for call in DefensivePlay.allCases {
                let counts = DefensivePersonnel.counts(for: call)
                expectEqual(
                    counts.dl + counts.lb + counts.cb + counts.s, 11,
                    "\(call.displayName) does not add up to eleven"
                )
            }
        }

        test("a blitz sends somebody extra") {
            let blitzing = Formations.defense(
                for: .blitz, personnel: FieldFixtures.defense(defenseTeam, call: .blitz)
            )
            let base = Formations.defense(
                for: .base, personnel: FieldFixtures.defense(defenseTeam, call: .base)
            )
            let blitzRushers = blitzing.filter { $0.role == .rusher }.count
            let baseRushers = base.filter { $0.role == .rusher }.count
            expect(blitzRushers > baseRushers, "a blitz rushed \(blitzRushers), base rushed \(baseRushers)")
        }

        test("a decimated roster still fields eleven rather than crashing") {
            var thin = FieldFixtures.team(rating: 60)
            // Strip the receivers entirely — the depth chart has to fall through to somebody.
            thin.roster.removeAll { $0.position == .wr }
            thin.autoSortDepthChart()
            let players = Formations.offense(for: .shortPass, personnel: FieldFixtures.offense(thin))
            expectEqual(players.count, 11)
            expectEqual(Set(players.map(\.id)).count, 11, "a thin roster must not double-field a man")
        }
    }

    // MARK: - Routes

    suite("Routes") {
        test("every eligible gets a route, and an audible re-deals the same concept") {
            let straight = Routes.deal(for: .deepPass, eligibleCount: 5, variation: 0)
            let audibled = Routes.deal(for: .deepPass, eligibleCount: 5, variation: 1)
            expectEqual(straight.count, 5)
            expectEqual(audibled.count, 5)
            expect(straight != audibled, "an audible that changes nothing is not an audible")
            expectEqual(
                Set(straight), Set(audibled),
                "an audible must re-deal the concept, not call a different play"
            )
        }

        test("a deep call really is a deeper set of routes") {
            let deep = Routes.deal(for: .deepPass, eligibleCount: 5)
            let short = Routes.deal(for: .shortPass, eligibleCount: 5)
            let deepMean = deep.reduce(0.0) { $0 + $1.breakDepth } / Double(deep.count)
            let shortMean = short.reduce(0.0) { $0 + $1.breakDepth } / Double(short.count)
            expect(deepMean > shortMean, "deep averaged \(deepMean), short \(shortMean)")
        }

        test("routes break toward the middle from either side") {
            let leftSide = FieldPoint.yards(depth: 0, lateralYards: -18)
            let rightSide = FieldPoint.yards(depth: 0, lateralYards: 18)
            let leftPost = Routes.waypoint(.post, leg: 1, from: leftSide)
            let rightPost = Routes.waypoint(.post, leg: 1, from: rightSide)
            expect(
                leftPost.lateralYards > leftSide.lateralYards,
                "a post from the left must break right, toward the middle"
            )
            expect(
                rightPost.lateralYards < rightSide.lateralYards,
                "a post from the right must break left, toward the middle"
            )
        }

        test("a crisp route runner keeps more speed through the break") {
            let crisp = Routes.cutSpeedRetention(.comeback, routeRunning: 99)
            let sloppy = Routes.cutSpeedRetention(.comeback, routeRunning: 40)
            expect(crisp > sloppy, "crisp \(crisp) vs sloppy \(sloppy)")
            expect(sloppy > 0.2 && crisp <= 1.0, "retention must stay a sane fraction")
            expect(
                Routes.cutSpeedRetention(.go, routeRunning: 40)
                    > Routes.cutSpeedRetention(.comeback, routeRunning: 40),
                "a go route has less of a cut to lose speed on than a comeback"
            )
        }
    }

    // MARK: - Openness

    suite("Openness") {
        test("the bands are the ones the design document states") {
            expectEqual(Openness.state(separationYards: 1.0, closingSpeed: 0), .covered)
            expectEqual(Openness.state(separationYards: 2.0, closingSpeed: 0), .contested)
            expectEqual(Openness.state(separationYards: 4.0, closingSpeed: 0), .open)
        }

        test("open but closing fast reads as the maybe, not the green") {
            expectEqual(
                Openness.state(separationYards: 4.0, closingSpeed: 6.0), .contested,
                "a receiver about to be arrived at is not open"
            )
        }

        test("an accurate quarterback is told sooner than an inaccurate one") {
            var sharp = IndicatorFeed(awareness: 99)
            var dull = IndicatorFeed(awareness: 40)
            let id = UUID()
            sharp.update(truth: [id: .covered], now: 0)
            dull.update(truth: [id: .covered], now: 0)

            // The window opens at t = 0.2 and stays open.
            for step in stride(from: 0.2, through: 0.5, by: 0.05) {
                sharp.update(truth: [id: .open], now: step)
                dull.update(truth: [id: .open], now: step)
            }
            expectEqual(sharp.state(for: id), .open, "a 99 should have seen this by now")
            expectEqual(dull.state(for: id), .covered, "a 40 should still be a beat behind")
        }

        test("the indicator never shows a state that never happened") {
            // The honesty invariant. A colour may be late; it may never be invented.
            var feed = IndicatorFeed(awareness: 55)
            let id = UUID()
            var seen: Set<OpennessState> = []
            var rng = SeededRandom(seed: 99)
            let script: [OpennessState] = [.covered, .contested, .open, .contested, .covered, .open]
            var now = 0.0
            for state in script {
                seen.insert(state)
                for _ in 0..<8 {
                    now += ArcadeTuning.secondsPerTick
                    feed.update(truth: [id: state], now: now)
                    if let shown = feed.state(for: id) {
                        expect(
                            seen.contains(shown),
                            "the feed showed \(shown) before it had ever been true"
                        )
                    }
                }
                _ = rng.double01()
            }
        }

        test("a window that flickers shut faster than the latency is never shown") {
            var feed = IndicatorFeed(awareness: 40)
            let id = UUID()
            feed.update(truth: [id: .covered], now: 0)
            // Open for a quarter of a second — well inside a 0.9s latency.
            var now = 0.0
            for _ in 0..<7 {
                now += ArcadeTuning.secondsPerTick
                feed.update(truth: [id: .open], now: now)
            }
            expectEqual(
                feed.state(for: id), .covered,
                "a 40-awareness passer must not catch a window this brief"
            )
        }
    }

    // MARK: - Pocket

    suite("Pocket") {
        /// Mean pocket life over many seeded snaps, for a line and a rush of given ratings.
        func meanPocket(line: Int, rush: Int, samples: Int = 400) -> Double {
            let offenseTeam = FieldFixtures.team(rating: line)
            let defenseTeam = FieldFixtures.team(rating: rush, name: "D", abbreviation: "DEF")
            let blockers = Formations.offense(
                for: .shortPass, personnel: FieldFixtures.offense(offenseTeam)
            ).filter { $0.role == .blocker }
            let rushers = Formations.defense(
                for: .base, personnel: FieldFixtures.defense(defenseTeam)
            ).filter { $0.role == .rusher }

            var total = 0.0
            for index in 0..<samples {
                var rng = SeededRandom(seed: 7_000 &+ UInt64(index))
                total += Pocket.resolve(blockers: blockers, rushers: rushers, rng: &rng).life
            }
            return total / Double(samples)
        }

        test("the calibrated anchors from the design document hold") {
            expectClose(
                meanPocket(line: 55, rush: 55), 2.2, 0.25,
                "a 55 line should give about 2.2 seconds"
            )
            expectClose(
                meanPocket(line: 90, rush: 90), 4.5, 0.35,
                "a 90 line should give about 4.5 seconds"
            )
        }

        test("a better line buys more time against the same rush") {
            let poor = meanPocket(line: 55, rush: 70)
            let good = meanPocket(line: 85, rush: 70)
            expect(good > poor, "85 line got \(good)s, 55 line got \(poor)s")
        }

        test("the rush arrives as separate duels, not one alarm clock") {
            let offenseTeam = FieldFixtures.team(rating: 70)
            let defenseTeam = FieldFixtures.team(rating: 70, name: "D", abbreviation: "DEF")
            let blockers = Formations.offense(
                for: .shortPass, personnel: FieldFixtures.offense(offenseTeam)
            ).filter { $0.role == .blocker }
            let rushers = Formations.defense(
                for: .base, personnel: FieldFixtures.defense(defenseTeam)
            ).filter { $0.role == .rusher }
            var rng = SeededRandom(seed: 7_777)
            let state = Pocket.resolve(blockers: blockers, rushers: rushers, rng: &rng)

            expectEqual(state.breakthroughs.count, rushers.count, "every rusher needs an arrival")
            let times = state.breakthroughs.values.sorted()
            expect(times.count > 1, "there should be more than one rusher")
            expect(times[times.count - 1] > times[0], "all four arriving at once is not a pocket")
            expectClose(times[0], state.life, 0.001, "the pocket's life is the first arrival")
            expect(state.firstArrival != nil, "somebody has to get there first")
        }

        test("the sack warning arrives before the sack, and sooner for a sharp passer") {
            let offenseTeam = FieldFixtures.team(rating: 70)
            let defenseTeam = FieldFixtures.team(rating: 70, name: "D", abbreviation: "DEF")
            let blockers = Formations.offense(
                for: .shortPass, personnel: FieldFixtures.offense(offenseTeam)
            ).filter { $0.role == .blocker }
            let rushers = Formations.defense(
                for: .base, personnel: FieldFixtures.defense(defenseTeam)
            ).filter { $0.role == .rusher }
            var rng = SeededRandom(seed: 7_100)
            let state = Pocket.resolve(blockers: blockers, rushers: rushers, rng: &rng)

            expect(state.warningTime(awareness: 99) < state.life, "the warning must precede the hit")
            expect(
                state.warningTime(awareness: 99) < state.warningTime(awareness: 40),
                "awareness should buy an earlier warning"
            )
        }
    }

    // MARK: - Run lanes

    suite("Run lanes") {
        func meanBestLane(runBlock: Int, samples: Int = 200) -> Double {
            let offenseTeam = FieldFixtures.team(
                rating: 70, position: .ol, attribute: .runBlock, value: runBlock
            )
            let defenseTeam = FieldFixtures.team(rating: 70, name: "D", abbreviation: "DEF")
            let blockers = Formations.offense(
                for: .insideRun, personnel: FieldFixtures.offense(offenseTeam)
            ).filter { $0.role == .blocker }
            let defenders = Formations.defense(
                for: .base, personnel: FieldFixtures.defense(defenseTeam)
            )
            var total = 0.0
            for index in 0..<samples {
                var rng = SeededRandom(seed: 8_000 &+ UInt64(index))
                let lanes = RunLanes.open(
                    blockers: blockers, defenders: defenders, call: .insideRun, rng: &rng
                )
                total += lanes.map(\.halfWidth).max() ?? 0
            }
            return total / Double(samples)
        }

        test("better blocking opens a bigger hole") {
            let poor = meanBestLane(runBlock: 50)
            let good = meanBestLane(runBlock: 95)
            expect(good > poor, "95 run block opened \(good) yards, 50 opened \(poor)")
        }

        test("a five-man line makes six gaps") {
            let offenseTeam = FieldFixtures.team(rating: 70)
            let blockers = Formations.offense(
                for: .insideRun, personnel: FieldFixtures.offense(offenseTeam)
            ).filter { $0.role == .blocker }
            expectEqual(RunLanes.gapCenters(blockers: blockers).count, 6)
        }

        test("vision decides how much the highlight can be trusted") {
            let lanes = [
                RunLane(gapIndex: 0, centerLateralYards: -6, halfWidth: 0.5),
                RunLane(gapIndex: 1, centerLateralYards: -3, halfWidth: 0.6),
                RunLane(gapIndex: 2, centerLateralYards: -1, halfWidth: 3.0),
                RunLane(gapIndex: 3, centerLateralYards: 1, halfWidth: 0.7),
                RunLane(gapIndex: 4, centerLateralYards: 3, halfWidth: 0.4),
                RunLane(gapIndex: 5, centerLateralYards: 6, halfWidth: 0.8),
            ]
            func hitRate(vision: Int) -> Double {
                var rng = SeededRandom(seed: 8_500)
                var hits = 0
                let samples = 2_000
                for _ in 0..<samples {
                    if RunLanes.suggested(lanes: lanes, vision: vision, rng: &rng)?.gapIndex == 2 {
                        hits += 1
                    }
                }
                return Double(hits) / Double(samples)
            }
            let sharp = hitRate(vision: 99)
            let blind = hitRate(vision: 40)
            expect(sharp > 0.9, "a 99-vision back found the crease only \(sharp) of the time")
            expect(blind < sharp, "vision has to matter: \(blind) vs \(sharp)")
            expect(blind > 0.3, "even a poor back is not worse than random: \(blind)")
        }
    }

    // MARK: - Kernel

    suite("SnapKernel") {
        let offenseTeam = FieldFixtures.team(rating: 75)
        let defenseTeam = FieldFixtures.team(rating: 75, name: "D", abbreviation: "DEF")

        test("a snap starts with twenty-two men on the field") {
            let kernel = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam)
            expectEqual(kernel.players.count, 22)
            expectEqual(kernel.offensePlayers.count, 11)
            expectEqual(kernel.defensePlayers.count, 11)
            expectEqual(
                Set(kernel.players.map(\.id)).count, 22,
                "somebody is on the field twice"
            )
        }

        test("the same inputs produce the same snap, every time") {
            let trace = InputTrace([
                TracedAction(time: 0.4, action: .beginAim),
                TracedAction(time: 0.9, action: .aim(FieldPoint.yards(depth: 9, lateralYards: -8))),
                TracedAction(time: 1.2, action: .release),
                TracedAction(time: 1.9, action: .juke(direction: 1)),
            ])
            var first = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam, seed: 4_242)
            var second = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam, seed: 4_242)
            let gradesA = first.run(trace: trace)
            let gradesB = second.run(trace: trace)

            expectEqual(gradesA, gradesB, "the kernel is not deterministic")
            expectEqual(first.players.count, second.players.count)
            for (left, right) in zip(first.players, second.players) {
                expectEqual(left.id, right.id, "player order diverged")
                expectClose(left.point.depth, right.point.depth, 0.0001, "\(left.athlete.name) drifted")
                expectClose(left.point.lateral, right.point.lateral, 0.0001)
            }
        }

        test("a different seed produces a different snap") {
            var first = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam, seed: 1)
            var second = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam, seed: 2)
            first.run(trace: .none)
            second.run(trace: .none)
            expect(
                first.pocket.life != second.pocket.life,
                "two seeds gave an identical pocket — the stream is not being consumed"
            )
        }

        test("touching nothing grades to neutral, which is what keeps the sim honest") {
            var kernel = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam)
            let grades = kernel.run(trace: .none)
            expect(grades.isNeutral, "an untouched snap must grade neutral")
            let execution = ArcadeInput.execution(
                from: grades, quarterback: FieldFixtures.offense(offenseTeam).quarterback
            )
            expect(execution.isNeutral, "a neutral grade must produce a neutral execution")
        }

        test("a scripted throw reaches the states the design describes") {
            var kernel = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam)
            kernel.apply(.snap)
            for _ in 0..<10 { kernel.step() }
            expectEqual(kernel.phase, .dropback, "the ball should still be in his hands")

            kernel.apply(.beginAim)
            kernel.apply(.aim(FieldPoint.yards(depth: 8, lateralYards: -6)))
            kernel.apply(.release)
            if case .ballInAir = kernel.phase {
                expect(true)
            } else {
                expect(false, "releasing should put the ball in the air, phase was \(kernel.phase)")
            }

            var ticks = 0
            while !kernel.isOver, ticks < ArcadeTuning.maxSnapTicks {
                kernel.step()
                ticks += 1
            }
            expect(kernel.isOver, "the snap never resolved")
            expectEqual(kernel.grades.ending, .thrown)
            expect(!kernel.grades.isNeutral, "a thrown ball is not a neutral snap")
        }

        test("the pocket is a real clock: hold it and the rush arrives") {
            var kernel = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam)
            kernel.apply(.snap)
            kernel.apply(.beginAim)
            var ticks = 0
            while !kernel.isOver, ticks < ArcadeTuning.maxSnapTicks {
                kernel.step()
                ticks += 1
            }
            expectEqual(
                kernel.grades.ending, .pressured,
                "holding the ball forever has to end in pressure"
            )
            expectClose(
                kernel.grades.releaseTiming, -1, 0.001,
                "a collapsed pocket is the worst timing score there is"
            )
        }

        test("the rush clock starts when you start aiming, not at the snap") {
            var patient = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam, seed: 55)
            patient.apply(.snap)
            // Read the field for a second and a half before even looking to throw.
            for _ in 0..<45 { patient.step() }
            expect(
                !patient.isOver,
                "thinking must not be punished — the snap ended before he looked to throw"
            )
            expect(!patient.isUnderPressure, "pressure started without an aim")
        }

        test("an out-of-range throw falls short rather than travelling forever") {
            var weakArm = FieldFixtures.team(rating: 75, position: .qb, attribute: .throwPower, value: 40)
            weakArm.autoSortDepthChart()
            var kernel = FieldFixtures.kernel(offense: weakArm, defense: defenseTeam)
            kernel.apply(.snap)
            kernel.apply(.beginAim)
            kernel.apply(.aim(FieldPoint.yards(depth: 60, lateralYards: 0)))
            let reach = kernel.maxThrowYards
            expect(reach <= 20, "a 40-power arm should not reach 20 yards, got \(reach)")
            expect(
                kernel.frame.aimPoint?.depth ?? 99 < 60,
                "the aim point should have been pulled back inside his range"
            )
        }

        test("reconciling moves the ball to the engine's number") {
            var kernel = FieldFixtures.kernel(offense: offenseTeam, defense: defenseTeam, call: .insideRun)
            kernel.apply(.snap)
            kernel.apply(.handOff(gapIndex: nil))
            var ticks = 0
            while !kernel.isOver, ticks < ArcadeTuning.maxSnapTicks {
                kernel.step()
                ticks += 1
            }
            kernel.reconcile(officialYards: 7)
            expectClose(
                kernel.ballPoint.depth, 7, 0.0001,
                "what you watched and what the box score says must be the same play"
            )
            expectClose(kernel.grades.provisionalYards, 7, 0.0001)
        }

        test("a snap always terminates") {
            for seed in stride(from: UInt64(1), through: 40, by: 1) {
                var kernel = FieldFixtures.kernel(
                    offense: offenseTeam, defense: defenseTeam, seed: seed
                )
                kernel.run(trace: .none)
                expect(kernel.isOver, "seed \(seed) left a snap running")
                expect(
                    kernel.elapsed <= ArcadeTuning.maxSnapSeconds + 0.1,
                    "seed \(seed) ran \(kernel.elapsed)s"
                )
            }
        }
    }

    // MARK: - Grades

    suite("Grades to execution") {
        let quarterback = Athlete(player: TestFixtures.player(position: .qb, rating: 75))

        test("a perfect ball to an open man is the best score there is") {
            let grades = SnapGrades(
                placementErrorYards: 0, targetOpenness: .open, releaseTiming: 1,
                ending: .thrown, isNeutral: false
            )
            let execution = ArcadeInput.execution(from: grades, quarterback: quarterback)
            expectClose(execution.accuracy, 1, 0.001)
            expect(
                execution.completionModifier <= ArcadeTuning.completionSwing,
                "the cap has to hold even at a perfect grade"
            )
        }

        test("throwing into coverage is charged, even when the ball is perfect") {
            let intoGreen = SnapGrades(
                placementErrorYards: 0, targetOpenness: .open, ending: .thrown, isNeutral: false
            )
            let intoRed = SnapGrades(
                placementErrorYards: 0, targetOpenness: .covered, ending: .thrown, isNeutral: false
            )
            let green = ArcadeInput.execution(from: intoGreen, quarterback: quarterback)
            let red = ArcadeInput.execution(from: intoRed, quarterback: quarterback)
            expect(
                red.accuracy < green.accuracy,
                "a perfect ball into a red window must still be a worse decision"
            )
            expect(
                red.interceptionMultiplier > green.interceptionMultiplier,
                "and it should be the one that gets picked off"
            )
        }

        test("an accurate passer forgives a miss that ruins an inaccurate one") {
            let sharp = Athlete(
                player: {
                    var player = TestFixtures.player(position: .qb, rating: 75)
                    player.ratings[.throwAccuracy] = 99
                    return player
                }()
            )
            let scatter = Athlete(
                player: {
                    var player = TestFixtures.player(position: .qb, rating: 75)
                    player.ratings[.throwAccuracy] = 40
                    return player
                }()
            )
            let grades = SnapGrades(
                placementErrorYards: 4, targetOpenness: .open, ending: .thrown, isNeutral: false
            )
            expect(
                ArcadeInput.execution(from: grades, quarterback: sharp).accuracy
                    > ArcadeInput.execution(from: grades, quarterback: scatter).accuracy,
                "accuracy has to buy tolerance or the rating means nothing in the hand"
            )
        }

        test("beating tacklers and picking the right lane is worth yards, but not many") {
            let excellent = SnapGrades(
                pursuitBeaten: 3, laneQuality: 1, aggression: 1,
                ending: .handedOff, isNeutral: false
            )
            let execution = ArcadeInput.execution(from: excellent, quarterback: quarterback)
            expect(execution.running > 0.5, "a great run should grade well")
            expect(
                execution.yardsModifier <= ArcadeTuning.yardsSwing,
                "and still be capped: \(execution.yardsModifier)"
            )
            expect(
                execution.fumbleMultiplier > 1,
                "fighting for every yard has to carry the ball-security cost"
            )
        }

        test("pressure is charged to the play even when nothing was thrown") {
            let pressured = SnapGrades(ending: .pressured, isNeutral: false)
            let execution = ArcadeInput.execution(from: pressured, quarterback: quarterback)
            expect(execution.accuracy < 0, "a play that never got away is not a neutral one")
        }
    }

    // MARK: - Balance

    suite("Scripted thumbs") {
        /// Where the slot receiver actually lines up, read off the formation rather than typed
        /// in. A hard-coded aim point silently stops being a good throw the moment somebody
        /// touches the split table — which is exactly how the first version of this test came to
        /// be aiming at eleven yards of empty grass and calling it perfect play.
        func slotStem(_ offenseTeam: Team, call: OffensivePlay = .shortPass) -> FieldPoint {
            let players = Formations.offense(
                for: call, personnel: FieldFixtures.offense(offenseTeam)
            )
            let eligibles = players.filter {
                if case .receiver = $0.role { return true } else { return false }
            }
            guard eligibles.count > 2 else {
                return FieldPoint.yards(depth: 7.5, lateralYards: 0)
            }
            // The third eligible is the slot: against a base call the two corners take the two
            // widest receivers, so he is the man the read is supposed to find.
            return FieldPoint.yards(depth: 7.5, lateralYards: eligibles[2].point.lateralYards)
        }

        /// A bot that finds the open man and throws on time.
        func perfectTrace(_ offenseTeam: Team) -> InputTrace {
            InputTrace([
                TracedAction(time: 0.5, action: .beginAim),
                TracedAction(time: 0.55, action: .aim(slotStem(offenseTeam))),
                TracedAction(time: 0.75, action: .release),
                TracedAction(time: 1.2, action: .juke(direction: 1)),
            ])
        }

        /// Mean completion-probability shift a bot earns across many snaps.
        func meanCompletionShift(rating: Int, plays: Bool, samples: Int = 120) -> Double {
            let offenseTeam = FieldFixtures.team(rating: rating)
            let defenseTeam = FieldFixtures.team(rating: 75, name: "D", abbreviation: "DEF")
            let personnel = FieldFixtures.offense(offenseTeam)
            let trace = plays ? perfectTrace(offenseTeam) : .none
            var total = 0.0
            for index in 0..<samples {
                var kernel = FieldFixtures.kernel(
                    offense: offenseTeam, defense: defenseTeam, seed: 9_000 &+ UInt64(index)
                )
                let grades = kernel.run(trace: trace)
                total += ArcadeInput.execution(
                    from: grades, quarterback: personnel.quarterback
                ).completionModifier
            }
            return total / Double(samples)
        }

        test("playing well beats not playing, by a bounded amount") {
            let played = meanCompletionShift(rating: 75, plays: true)
            let untouched = meanCompletionShift(rating: 75, plays: false)
            expectClose(untouched, 0, 0.0001, "an untouched snap must be worth exactly nothing")
            expect(played > untouched, "playing the snap should be worth something: \(played)")
            expect(
                played <= ArcadeTuning.completionSwing,
                "no trace may exceed the cap: \(played)"
            )
        }

        test("perfect hands on a poor roster still trail perfect hands on a good one") {
            // The floor the whole management half of the game rests on.
            let onGreat = meanCompletionShift(rating: 90, plays: true)
            let onPoor = meanCompletionShift(rating: 55, plays: true)
            expect(
                onGreat > onPoor,
                "a 90 roster played perfectly earned \(onGreat), a 55 earned \(onPoor)"
            )
        }

        test("execution can never exceed the caps, whatever the trace") {
            let offenseTeam = FieldFixtures.team(rating: 99)
            let defenseTeam = FieldFixtures.team(rating: 40, name: "D", abbreviation: "DEF")
            let traces: [InputTrace] = [
                .none,
                perfectTrace(offenseTeam),
                // Deliberately terrible: aimed out of bounds and held until the rush arrives.
                InputTrace([
                    TracedAction(time: 0.1, action: .beginAim),
                    TracedAction(time: 0.2, action: .aim(FieldPoint.yards(depth: 30, lateralYards: 20))),
                    TracedAction(time: 5.0, action: .release),
                ]),
                InputTrace([TracedAction(time: 0.1, action: .handOff(gapIndex: 2))]),
                InputTrace([TracedAction(time: 0.1, action: .scramble)]),
            ]
            let personnel = FieldFixtures.offense(offenseTeam)
            for (index, trace) in traces.enumerated() {
                var kernel = FieldFixtures.kernel(
                    offense: offenseTeam, defense: defenseTeam, seed: 9_500 &+ UInt64(index)
                )
                let execution = ArcadeInput.execution(
                    from: kernel.run(trace: trace), quarterback: personnel.quarterback
                )
                expect(abs(execution.completionModifier) <= ArcadeTuning.completionSwing + 0.0001)
                expect(abs(execution.yardsModifier) <= ArcadeTuning.yardsSwing + 0.0001)
                expect(execution.sackMultiplier > 0, "trace \(index) produced a nonsense multiplier")
                expect(execution.interceptionMultiplier > 0)
            }
        }
    }
}
