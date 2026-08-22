import Foundation
import FootballSimCore
import ProFootballCoachUI
import CoachWorldApp

func runSnapAnchorTests() {
    suite("Snap anchors") {
        test("a field point clamps into the coordinate space of 03 section 9.2") {
            expectEqual(FieldPoint(yard: -12, lateral: 4).yard, 0)
            expectEqual(FieldPoint(yard: 180, lateral: -1).yard, 100)
            expectEqual(FieldPoint(yard: 50, lateral: -1).lateral, 0)
            expectEqual(FieldPoint(yard: 50, lateral: 9).lateral, 1)
            expectEqual(FieldPoint(yard: 40, lateral: 0.25).yard, 40)
            expectEqual(FieldPoint(yard: 40, lateral: 0.25).lateral, 0.25)
        }

        test("playback duration constants leave a snap watchable") {
            expect(AnchorRules.minimumPlaybackSeconds > 0,
                   "a zero-length playback is not a playback")
            expect(AnchorRules.maximumPlaybackSeconds > AnchorRules.minimumPlaybackSeconds,
                   "the playback ceiling must sit above its floor")
            expect(AnchorRules.clockToPlaybackRatio > 0 && AnchorRules.clockToPlaybackRatio <= 1,
                   "playback may compress clock time but never stretch it")
        }

        test("the stride profile accelerates off the snap and decelerates into contact") {
            // 03 section 9.6: "a straight line at constant velocity for the full playback is not a
            // neutral default; it is a claim that players do not accelerate, which is false and
            // reads as false." This is that claim, as an assertion.
            expect(AnchorRules.strideAccelerate > 0 && AnchorRules.strideDecelerate > 0,
                   "a profile with no ramp is the constant velocity this replaced")
            expect(AnchorRules.strideAccelerate + AnchorRules.strideDecelerate < 1,
                   "the ramps must leave a cruise between them, or the arithmetic has no middle")

            expectClose(AnchorRules.pathFraction(atPlayback: 0), 0, 1e-9,
                        "the profile must start where the path starts")
            expectClose(AnchorRules.pathFraction(atPlayback: 1), 1, 1e-9,
                        "the profile must finish where the path finishes, with no clamp doing it")

            // Strictly increasing: a dot that stalls or reverses mid-play is worse than a glide.
            var previous = -1.0
            var samples: [Double] = []
            for step in 0...200 {
                let value = AnchorRules.pathFraction(atPlayback: Double(step) / 200)
                expect(value > previous, "the profile went backwards at \(step)/200")
                previous = value
                samples.append(value)
            }

            // Velocity, as the finite difference. Slow at both ends, quickest in the middle -- the
            // shape of a man leaving a stance and being stopped, rather than a chip sliding.
            let speeds = zip(samples.dropFirst(), samples).map { $0 - $1 }
            let mean = speeds.reduce(0, +) / Double(speeds.count)
            expect(speeds.first! < mean, "the profile does not accelerate off the snap")
            expect(speeds.last! < mean, "the profile does not decelerate into contact")
            let quickest = speeds.firstIndex(of: speeds.max()!)!
            expectIn(Double(quickest) / Double(speeds.count), 0.2...0.8,
                     "top speed must fall between the ramps, not at an end")

            // Clamped, because a paused or over-run timeline can hand it either.
            expectClose(AnchorRules.pathFraction(atPlayback: -3), 0, 1e-9, "negative time unclamped")
            expectClose(AnchorRules.pathFraction(atPlayback: 9), 1, 1e-9, "over-run time unclamped")
        }

        test("every position aligns somewhere on the field") {
            // Enumerated from Position.allCases by construction, so a position added tomorrow fails
            // this the day it is added rather than the day someone remembers it.
            for position in Position.allCases {
                for isOffense in [true, false] {
                    for index in 0..<4 {
                        let point = SnapAnchors.alignment(
                            for: position, index: index, isOffense: isOffense, lineOfScrimmage: 40
                        )
                        expectIn(point.yard, 0...100, "\(position) aligned off the field")
                        expectIn(point.lateral, 0...1, "\(position) aligned outside the sidelines")
                    }
                }
            }
        }

        test("an attacking specialist stands behind the line, whichever team is attacking") {
            // This keyed on home/away, which is the wrong axis. With the away team attacking, its
            // kicker lined up eight yards downfield -- in the defence's territory -- because the
            // template read the side rather than who had the ball.
            let los = 40.0
            for position in [Position.kicker, .punter] {
                let attacking = SnapAnchors.alignment(
                    for: position, index: 0, isOffense: true, lineOfScrimmage: los
                )
                let defending = SnapAnchors.alignment(
                    for: position, index: 0, isOffense: false, lineOfScrimmage: los
                )
                expect(attacking.yard < los, "an attacking \(position) must set up behind the line")
                expect(defending.yard > los, "a defending \(position) must set up beyond the line")
            }
        }

        test("the offensive line stands on the line and the defence stands beyond it") {
            let los = 40.0
            let centre = SnapAnchors.alignment(
                for: .center, index: 0, isOffense: true, lineOfScrimmage: los
            )
            expectEqual(centre.yard, los, "the centre is on the line of scrimmage")
            expectEqual(centre.lateral, AnchorRules.centerLateral)

            let passer = SnapAnchors.alignment(
                for: .quarterback, index: 0, isOffense: true, lineOfScrimmage: los
            )
            expect(passer.yard < los, "the passer sets up behind the line")

            let edge = SnapAnchors.alignment(
                for: .edgeRusher, index: 0, isOffense: false, lineOfScrimmage: los
            )
            expect(edge.yard > los, "the defensive front lines up beyond the line of scrimmage")

            let safety = SnapAnchors.alignment(
                for: .safety, index: 0, isOffense: false, lineOfScrimmage: los
            )
            expect(safety.yard > edge.yard, "safeties play behind the front")
        }

        test("two players at the same position take different alignments") {
            let los = 40.0
            let first = SnapAnchors.alignment(
                for: .wideReceiver, index: 0, isOffense: true, lineOfScrimmage: los
            )
            let second = SnapAnchors.alignment(
                for: .wideReceiver, index: 1, isOffense: true, lineOfScrimmage: los
            )
            expect(first.lateral != second.lateral, "receivers stacked on one another")
        }

        test("roles come from what the outcome recorded, not from a guess") {
            let passer = UUID(uuidString: "00000000-0000-4000-8000-0000000000A1")!
            let target = UUID(uuidString: "00000000-0000-4000-8000-0000000000A2")!
            let carrier = UUID(uuidString: "00000000-0000-4000-8000-0000000000A3")!
            let outcome = SnapOutcome(
                result: .gain, yards: 8, secondsElapsed: 6, matchups: [],
                ballCarrierID: carrier, passerID: passer, targetID: target
            )
            expectEqual(SnapAnchors.role(for: passer, position: .quarterback, outcome: outcome,
                                         isOffense: true), .passer)
            expectEqual(SnapAnchors.role(for: target, position: .wideReceiver, outcome: outcome,
                                         isOffense: true), .routeRunner)
            expectEqual(SnapAnchors.role(for: carrier, position: .runningBack, outcome: outcome,
                                         isOffense: true), .carrier)
            let other = UUID(uuidString: "00000000-0000-4000-8000-0000000000A4")!
            expectEqual(SnapAnchors.role(for: other, position: .leftTackle, outcome: outcome,
                                         isOffense: true), .blocker)
            expectEqual(SnapAnchors.role(for: other, position: .edgeRusher, outcome: outcome,
                                         isOffense: false), .rusher)
            expectEqual(SnapAnchors.role(for: other, position: .cornerback, outcome: outcome,
                                         isOffense: false), .coverage)
            expectEqual(SnapAnchors.role(for: other, position: .linebacker, outcome: outcome,
                                         isOffense: false), .runFit)
        }

        test("a beaten blocker is driven back, and a winning blocker holds his ground") {
            // Phase 5: blocking needs no engine change. .passProtection and .runLane duels are
            // already in outcome.matchups, keyed on the blocker as attacker -- this is derivation,
            // not recording.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            // By group and fixture order (leftTackle, guardPosition, center, rightTackle) rather
            // than a raw array index: `testPersonnel` gained a second running back after this test
            // was written, which shifted every offensive-line index by one and broke it silently
            // -- the assertions still ran, they just checked the wrong two players.
            let offensiveLine = personnel.offensive(group: .offensiveLine)
            let leftTackle = offensiveLine[0]
            let center = offensiveLine[2]
            let rusher = personnel.defense[0]
            let interior = personnel.defense[2]
            let play = PlayRecord(
                situation: Situation(down: 1, distance: 10, yardLine: 40),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .sack, yards: -7, secondsElapsed: 6,
                    matchups: [
                        MatchupRecord(kind: .passProtection, attackerID: leftTackle.id,
                                     defenderID: rusher.id, leverage: -0.6),
                        MatchupRecord(kind: .passProtection, attackerID: center.id,
                                     defenderID: interior.id, leverage: 0.5),
                    ],
                    passerID: personnel.offense[0].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play, offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )
            let leftTackleAnchor = set.actors.first { $0.playerID == leftTackle.id }!
            let centerAnchor = set.actors.first { $0.playerID == center.id }!
            expect(leftTackleAnchor.end.yard < leftTackleAnchor.start.yard,
                   "a blocker who lost his duel must be drawn driven back off the line")
            expectEqual(centerAnchor.end.yard, centerAnchor.start.yard,
                        "a blocker who won his duel must hold his ground")
            expectEqual(centerAnchor.end.lateral, centerAnchor.start.lateral,
                        "a blocker who won his duel must hold his ground")
            expectIn(leftTackleAnchor.end.yard, 0...100, "a beaten blocker was drawn off the field")
        }

        test("a broken-tackle chain draws a near miss for each defender and still finds who closed") {
            // Phase 5: SnapOutcome.brokenTackleAttempts records every attempt beyond the first. A
            // chain that ends on attempt two or three must still resolve a closing tackler -- only
            // the first attempt ever lands in outcome.matchups, so the search has to look at both.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let carrier = personnel.offense[1]
            let first = personnel.defense[4]
            let second = personnel.defense[5]
            let closer = personnel.defense[9]
            let play = PlayRecord(
                situation: Situation(down: 1, distance: 10, yardLine: 40),
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .gain, yards: 14, secondsElapsed: 7,
                    matchups: [
                        MatchupRecord(kind: .carrierVersusPursuit, attackerID: carrier.id,
                                     defenderID: first.id, leverage: 0.5),
                    ],
                    brokenTackleAttempts: [
                        MatchupRecord(kind: .carrierVersusPursuit, attackerID: carrier.id,
                                     defenderID: second.id, leverage: 0.45),
                        MatchupRecord(kind: .carrierVersusPursuit, attackerID: carrier.id,
                                     defenderID: closer.id, leverage: -0.3),
                    ],
                    ballCarrierID: carrier.id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play, offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )
            let firstAnchor = set.actors.first { $0.playerID == first.id }!
            let secondAnchor = set.actors.first { $0.playerID == second.id }!
            let closerAnchor = set.actors.first { $0.playerID == closer.id }!

            expectEqual(closerAnchor.end.yard, set.endSpot,
                        "the closing tackler, found in brokenTackleAttempts, must converge on the "
                            + "ball exactly as one found in matchups already does")

            for missed in [firstAnchor, secondAnchor] {
                expect(!missed.path.isEmpty, "a broken-tackle defender needs a waypoint to time the "
                           + "near miss")
                expect(missed.end.yard != set.endSpot || missed.end.lateral != closerAnchor.end.lateral,
                       "a defender who missed must not be drawn arriving where the ball ends -- "
                           + "only the closing tackler does")
                expectIn(missed.end.yard, 0...100, "a broken-tackle near miss left the field")
                expectIn(missed.end.lateral, 0...1, "a broken-tackle near miss left the sidelines")
            }
            expect(firstAnchor.path[0].fraction < secondAnchor.path[0].fraction,
                   "broken-tackle defenders must close in the order their attempts happened")
        }

        test("every result kind produces a non-empty accessible sentence") {
            // Driven from allCases: a new SnapResult that nobody wrote a sentence for fails here.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            for result in SnapResult.allCases {
                let outcome = SnapOutcome(
                    result: result, yards: result == .sack ? -7 : 5, secondsElapsed: 6, matchups: []
                )
                let line = SnapAnchors.sentence(
                    for: outcome, offense: personnel.offense, defense: personnel.defense
                )
                expect(!line.isEmpty, "\(result) produced no accessible sentence")
                expect(line.hasSuffix("."), "\(result)'s sentence is not a sentence: \(line)")
            }
        }

        test("an anchor set never contradicts the box score") {
            // 03 section 9.3 clause 2. Driven from allCases so no result kind escapes the check.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            for result in SnapResult.allCases {
                let yards = result == .sack ? -7 : 9
                let play = PlayRecord(
                    situation: Situation(down: 2, distance: 10, yardLine: 40),
                    offensiveCall: OffensiveCall(playType: result == .sack ? .pass : .run),
                    defensiveCall: DefensiveCall(coverage: .man),
                    outcome: SnapOutcome(
                        result: result, yards: yards, secondsElapsed: 6, matchups: []
                    ),
                    callInTriggers: []
                )
                let set = SnapAnchors.choreograph(
                    play: play,
                    offense: Array(personnel.offense.prefix(11)),
                    defense: Array(personnel.defense.prefix(11))
                )
                expectEqual(set.endSpot - set.lineOfScrimmage, Double(yards),
                            "\(result) drew an end spot the box score does not agree with")
                if result == .sack {
                    expect(set.endSpot < set.lineOfScrimmage, "a sack must end behind the line")
                }
                if result == .incompletion {
                    expect(!set.ball.contains { $0.kind == .carry },
                           "an incompletion must have no carry segment")
                }
            }
        }

        test("an anchor set is complete and bounded") {
            // 03 section 9.3 clauses 3 and 4.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            for result in SnapResult.allCases {
                let play = PlayRecord(
                    situation: Situation(down: 1, distance: 10, yardLine: 25),
                    offensiveCall: OffensiveCall(playType: .pass),
                    defensiveCall: DefensiveCall(coverage: .zoneUnder),
                    outcome: SnapOutcome(
                        result: result, yards: 4, secondsElapsed: 5, matchups: []
                    ),
                    callInTriggers: []
                )
                let set = SnapAnchors.choreograph(
                    play: play,
                    offense: Array(personnel.offense.prefix(11)),
                    defense: Array(personnel.defense.prefix(11))
                )
                expectEqual(set.actors.count, 22, "\(result) did not represent all 22 actors")
                // The view drives ForEach off these identifiers. A duplicate would silently drop a
                // dot rather than fail, so it is asserted here where it can be seen.
                expectEqual(Set(set.actors.map(\.playerID)).count, 22,
                            "\(result) produced two actors with the same identifier")
                expect(set.foregroundIDs.count <= AnchorRules.maximumForegrounded,
                       "\(result) foregrounded more than three actors")
                expectEqual(Set(set.foregroundIDs).count, set.foregroundIDs.count,
                            "\(result) foregrounded the same actor twice")
                let onField = Set(set.actors.map(\.playerID))
                for id in set.foregroundIDs {
                    expect(onField.contains(id),
                           "\(result) foregrounded an actor who is not on the field")
                }
                for actor in set.actors {
                    expectIn(actor.start.yard, 0...100, "\(result) started an actor off the field")
                    expectIn(actor.end.yard, 0...100, "\(result) ended an actor off the field")
                    expectIn(actor.start.lateral, 0...1, "\(result) started an actor off the field")
                    expectIn(actor.end.lateral, 0...1, "\(result) ended an actor off the field")
                }
                for segment in set.ball {
                    expectIn(segment.startFraction, 0...1,
                             "\(result) has a ball segment outside playback")
                    expectIn(segment.endFraction, 0...1,
                             "\(result) has a ball segment outside playback")
                }
                expectIn(set.durationSeconds,
                         AnchorRules.minimumPlaybackSeconds...AnchorRules.maximumPlaybackSeconds,
                         "\(result) produced an unwatchable duration")
            }
        }

        test("a touchdown from the one produces a legal upper-bound anchor set") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let play = PlayRecord(
                situation: Situation(down: 1, distance: 1, yardLine: 99),
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .touchdown, yards: 1, secondsElapsed: 4, matchups: [],
                    ballCarrierID: personnel.offense[1].id
                ),
                callInTriggers: [.redZone]
            )

            let set = SnapAnchors.choreograph(
                play: play,
                offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )

            expectEqual(set.lineOfScrimmage, 99)
            expectEqual(set.firstDownLine, 100)
            expectEqual(set.endSpot, 100)
            for point in set.actors.flatMap({ [$0.start, $0.end] })
                + set.ball.flatMap({ [$0.from, $0.to] }) {
                expectIn(point.yard, 0...100, "a goal-line touchdown left the field")
                expectIn(point.lateral, 0...1, "a goal-line touchdown left the sidelines")
            }
        }

        test("a safety from the one produces a legal lower-bound anchor set") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let quarterback = personnel.offense[0]
            let play = PlayRecord(
                situation: Situation(down: 3, distance: 8, yardLine: 1),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .safety, yards: -1, secondsElapsed: 5, matchups: [],
                    ballCarrierID: quarterback.id, passerID: quarterback.id
                ),
                callInTriggers: [.thirdAndLong]
            )

            let set = SnapAnchors.choreograph(
                play: play,
                offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )

            expectEqual(set.lineOfScrimmage, 1)
            expectEqual(set.endSpot, 0)
            for point in set.actors.flatMap({ [$0.start, $0.end] })
                + set.ball.flatMap({ [$0.from, $0.to] }) {
                expectIn(point.yard, 0...100, "a safety left the field")
                expectIn(point.lateral, 0...1, "a safety left the sidelines")
            }
        }

        test("the same record encodes byte-identically twice") {
            // 03 section 9.3 clause 1. The determinism the gap register asks for by name.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let play = PlayRecord(
                situation: Situation(down: 3, distance: 7, yardLine: 62),
                offensiveCall: OffensiveCall(playType: .pass, passDepth: .deep),
                defensiveCall: DefensiveCall(coverage: .zoneDeep),
                outcome: SnapOutcome(
                    result: .gain, yards: 21, secondsElapsed: 7, matchups: [],
                    ballCarrierID: personnel.offense[2].id,
                    passerID: personnel.offense[0].id,
                    targetID: personnel.offense[2].id
                ),
                callInTriggers: []
            )
            func encodeOnce() -> Data {
                let set = SnapAnchors.choreograph(
                    play: play,
                    offense: Array(personnel.offense.prefix(11)),
                    defense: Array(personnel.defense.prefix(11))
                )
                return try! JSONEncoder.stable().encode(set)
            }
            expectEqual(encodeOnce(), encodeOnce(),
                        "choreography is not byte-identical across renders")
        }

        test("choreographing a snap cannot change what the snap was") {
            // 03 section 9.3, and P13's named render-cannot-change-outcome gate.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let rules = Tier.pro.clockRules
            func resolveOnce() -> SnapOutcome {
                var rng = SeededRandom(seed: 4242)
                return SnapResolver.resolve(
                    offensiveCall: OffensiveCall(playType: .pass),
                    defensiveCall: DefensiveCall(coverage: .man),
                    personnel: personnel, situation: Situation(), rules: rules, rng: &rng
                )
            }
            let before = resolveOnce()

            // E4: SnapOutcome equality alone cannot prove choreograph left the RNG untouched — two
            // different draw counts can coincide on one outcome, never on state. `choreograph` takes
            // no `rng` parameter at all, so this cannot fail by construction; the assertion is the
            // belt to that suspender, and it is what would catch a future change that gave it one.
            var threaded = SeededRandom(seed: 4242)
            let threadedOutcome = SnapResolver.resolve(
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                personnel: personnel, situation: Situation(), rules: rules, rng: &threaded
            )
            let rngStateAfterResolve = threaded

            let play = PlayRecord(
                situation: Situation(),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: threadedOutcome,
                callInTriggers: []
            )
            _ = SnapAnchors.choreograph(
                play: play,
                offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )
            expectEqual(threaded, rngStateAfterResolve, "choreography perturbed the RNG state")
            expectEqual(resolveOnce(), before, "choreography perturbed the simulation")
        }

        test("a playback track carries absolute field positions") {
            let track = MatchDayReadModel.Playback.ActorTrack(
                stableID: "a", side: .home, uniformNumber: "12",
                startX: 40, startY: 0.3, endX: 52, endY: 0.3, role: "carrier"
            )
            expectEqual(track.startX, 40)
            expectEqual(track.endX, 52)

            let playback = MatchDayReadModel.Playback(
                stableID: "fixture-7",
                durationSeconds: 3,
                actors: [track],
                ball: [MatchDayReadModel.Playback.BallLeg(
                    kind: "carry", fromX: 40, fromY: 0.5, toX: 52, toY: 0.3,
                    startFraction: 0.1, endFraction: 1
                )],
                foregroundIDs: ["a"],
                lineOfScrimmageX: 40,
                firstDownLineX: 50,
                endSpotX: 52,
                sentence: "Gain of 12 yards."
            )
            expectEqual(playback.actors.count, 1)
            expectEqual(playback.sentence, "Gain of 12 yards.")
        }

        test("direction decides which way the play runs on the drawn field") {
            // The fixture deliberately sits away from midfield: at yardLine 20 with a 10-yard gain,
            // offense-relative endSpot is 30, which maps to absolute 40 rightward and 80 leftward.
            // A midfield fixture would map to the same number both ways and prove nothing.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let play = PlayRecord(
                situation: Situation(down: 1, distance: 10, yardLine: 20),
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .gain, yards: 10, secondsElapsed: 6, matchups: [],
                    ballCarrierID: personnel.offense[1].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play,
                offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )
            expectEqual(set.endSpot, 30, "the engine's end spot is offense-relative")

            let rightward = CoachWorldReadModelProvider.playback(
                from: set, stableID: "snap-1", offenseDirection: .leftToRight
            )
            let leftward = CoachWorldReadModelProvider.playback(
                from: set, stableID: "snap-1", offenseDirection: .rightToLeft
            )

            // Ten yards of end zone sit at each end of the 120-yard drawn field.
            expectEqual(rightward.endSpotX, 40, "a leftToRight drive must run up the drawn field")
            expectEqual(leftward.endSpotX, 80, "a rightToLeft drive must run down the drawn field")
            expectEqual(rightward.actors.count, 22)
            expectEqual(leftward.actors.count, 22)
            for actor in rightward.actors + leftward.actors {
                expectIn(actor.startX, 0...120, "an actor left the drawn field")
                expectIn(actor.endX, 0...120, "an actor left the drawn field")
            }
        }

        test("a run play moves nobody downfield on a route") {
            // OffensiveCall carries a passDepth on every call, defaulted to .mid. Reading it on a
            // run sent every receiver twelve yards downfield off a handoff -- movement invented
            // from a field that meant nothing, which 04 section 9 prohibits.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let play = PlayRecord(
                situation: Situation(down: 1, distance: 10, yardLine: 30),
                offensiveCall: OffensiveCall(playType: .run, runGap: .insideLeft),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .gain, yards: 5, secondsElapsed: 6, matchups: [],
                    ballCarrierID: offense[1].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play, offense: offense, defense: Array(personnel.defense.prefix(11))
            )
            for actor in set.actors where actor.role == .routeRunner {
                expectEqual(actor.end.yard, actor.start.yard,
                            "a receiver ran a route on a running play")
            }
            // The carrier still runs, or the whole thing is inert.
            let carrier = set.actors.first { $0.role == .carrier }
            expectEqual(carrier?.end.yard, 35, "the carrier did not reach the end spot")
        }

        test("the foreground names the deciding pair, not the pre-snap pair") {
            // The deciding matchup is the point of D2 -- a sack drawn as the protection duel that
            // lost. Dropping it on the way into presentation space loses that entirely.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let defense = Array(personnel.defense.prefix(11))
            let blocker = offense[6]
            let rusher = defense[0]
            let play = PlayRecord(
                situation: Situation(down: 3, distance: 8, yardLine: 45),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .sack, yards: -7, secondsElapsed: 6,
                    matchups: [MatchupRecord(
                        kind: .passProtection, attackerID: blocker.id,
                        defenderID: rusher.id, leverage: -0.8
                    )],
                    passerID: offense[0].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(play: play, offense: offense, defense: defense)
            expectEqual(set.deciding?.kind, .passProtection)
            expect(set.foregroundIDs.contains(blocker.id), "the losing blocker is not foregrounded")
            expect(set.foregroundIDs.contains(rusher.id), "the winning rusher is not foregrounded")

            let projected = CoachWorldReadModelProvider.playback(
                from: set, stableID: "snap-9", offenseDirection: .leftToRight
            )
            expectEqual(projected.foregroundIDs.count, set.foregroundIDs.count,
                        "the deciding pair was dropped on the way into presentation space")
            expect(projected.foregroundIDs.contains(blocker.id.uuidString),
                   "the losing blocker did not survive projection")
            expectEqual(projected.stableID, "snap-9",
                        "playback must carry a snap-grained identity of its own")
        }

        test("whoever has the ball is where the ball is") {
            // The desync this closes: actors interpolated start-to-end across the whole playback
            // while the ball moved in timed legs, so a receiver glided straight to the end spot
            // while the ball went via the catch point. They were never in the same place at the
            // same moment. Driven over every result kind so no branch escapes.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let defense = Array(personnel.defense.prefix(11))
            for result in SnapResult.allCases {
                for playType in [OffensivePlayType.pass, .run] {
                    let play = PlayRecord(
                        situation: Situation(down: 1, distance: 10, yardLine: 35),
                        offensiveCall: OffensiveCall(playType: playType),
                        defensiveCall: DefensiveCall(coverage: .man),
                        outcome: SnapOutcome(
                            result: result, yards: result == .sack ? -8 : 12, secondsElapsed: 6,
                            matchups: [],
                            ballCarrierID: result == .sack ? offense[0].id : offense[2].id,
                            passerID: offense[0].id,
                            targetID: playType == .pass ? offense[2].id : nil
                        ),
                        callInTriggers: []
                    )
                    let set = SnapAnchors.choreograph(
                        play: play, offense: offense, defense: defense
                    )
                    // Every leg on which a player is physically carrying the ball must have that
                    // player at both of its ends, at the moments the ball is there.
                    for leg in set.ball where leg.kind == .carry {
                        guard let holderID = play.outcome.ballCarrierID,
                              let holder = set.actors.first(where: { $0.playerID == holderID })
                        else { continue }
                        let atStart = SnapAnchors.position(of: holder, at: leg.startFraction)
                        let atEnd = SnapAnchors.position(of: holder, at: leg.endFraction)
                        expectClose(atStart.yard, leg.from.yard, 0.001,
                                    "\(result)/\(playType): carrier not at the ball when the "
                                        + "carry begins")
                        expectClose(atStart.lateral, leg.from.lateral, 0.001,
                                    "\(result)/\(playType): carrier off the ball laterally")
                        expectClose(atEnd.yard, leg.to.yard, 0.001,
                                    "\(result)/\(playType): carrier not at the ball when the "
                                        + "carry ends")
                    }
                }
            }
        }

        test("the tackler meets the ball where the play ended") {
            // 03 section 9.6. The record names the man who ended it -- SnapResolver writes
            // MatchupRecord(kind: .carrierVersusPursuit, defenderID: tackler) -- so drawing him
            // converge is reading the record, not inventing a pursuit path.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let defense = Array(personnel.defense.prefix(11))
            let carrier = offense[1]
            let tackler = defense[5]
            let play = PlayRecord(
                situation: Situation(down: 1, distance: 10, yardLine: 30),
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .gain, yards: 7, secondsElapsed: 6,
                    matchups: [MatchupRecord(
                        kind: .carrierVersusPursuit, attackerID: carrier.id,
                        defenderID: tackler.id, leverage: -0.4
                    )],
                    ballCarrierID: carrier.id, passerID: offense[0].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(play: play, offense: offense, defense: defense)
            let tacklerAnchor = set.actors.first { $0.playerID == tackler.id }
            let carrierAnchor = set.actors.first { $0.playerID == carrier.id }
            expect(tacklerAnchor != nil && carrierAnchor != nil, "fixture actors missing")

            let tacklerEnd = SnapAnchors.position(of: tacklerAnchor!, at: 1)
            let carrierEnd = SnapAnchors.position(of: carrierAnchor!, at: 1)
            expectClose(tacklerEnd.yard, carrierEnd.yard, 0.001,
                        "the tackler did not arrive where the carrier was stopped")
            expectClose(tacklerEnd.lateral, carrierEnd.lateral, 0.001,
                        "the tackler arrived on a different part of the field")
            expect(tacklerAnchor!.start.yard != tacklerEnd.yard,
                   "the tackler never actually moved")

            // Nobody else converges. The record names one man, so one man moves; a second would be
            // a path nothing recorded.
            let others = set.actors.filter {
                $0.side != play.situation.possession && $0.playerID != tackler.id
            }
            expect(!others.isEmpty, "fixture has no other defenders to check")
            for other in others where other.role == .coverage || other.role == .runFit {
                expectClose(SnapAnchors.position(of: other, at: 1).yard, other.start.yard, 0.001,
                            "a defender the record never named drifted toward the ball")
            }
        }

        test("no tackler is drawn when the record names none") {
            // 03 section 9.6: a tackle is never asserted where the record does not claim one. An
            // incompletion has nobody to tackle, and a matchup-less snap names nobody.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let defense = Array(personnel.defense.prefix(11))
            let play = PlayRecord(
                situation: Situation(down: 2, distance: 8, yardLine: 40),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .zoneUnder),
                outcome: SnapOutcome(
                    result: .incompletion, yards: 0, secondsElapsed: 5, matchups: [],
                    passerID: offense[0].id, targetID: offense[2].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(play: play, offense: offense, defense: defense)
            for actor in set.actors where actor.side != play.situation.possession {
                guard actor.role == .coverage || actor.role == .runFit else { continue }
                expectClose(SnapAnchors.position(of: actor, at: 1).yard, actor.start.yard, 0.001,
                            "a defender converged on a play that recorded no tackler")
            }
        }

        test("a sacked passer is dragged down with the ball, not left standing") {
            // role() checks passerID before ballCarrierID, so a sacked quarterback was classed
            // .passer and told to hold his drop point while the ball travelled back to the sack
            // spot without him. SnapResolver sets ballCarrierID to the passer on a sack, so the
            // record always said he was carrying it.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let passer = offense[0]
            let play = PlayRecord(
                situation: Situation(down: 3, distance: 9, yardLine: 45),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .sack, yards: -8, secondsElapsed: 6, matchups: [],
                    ballCarrierID: passer.id, passerID: passer.id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play, offense: offense, defense: Array(personnel.defense.prefix(11))
            )
            let quarterback = set.actors.first { $0.playerID == passer.id }
            expect(quarterback != nil, "the passer is not on the field")
            expectClose(quarterback?.end.yard ?? -1, set.endSpot, 0.001,
                        "the sacked passer did not end at the sack spot")
            expect(set.endSpot < set.lineOfScrimmage, "the fixture is not actually a sack")
            // He holds his drop point while the ball is still being snapped, rather than drifting
            // backwards from the instant the play begins.
            let atSnap = SnapAnchors.position(of: quarterback!, at: AnchorRules.snapFraction)
            expectClose(atSnap.yard, quarterback!.start.yard, 0.001,
                        "the passer began retreating before he had the ball")
        }

        test("one conversion turns an offense-relative yard into a drawn-field position") {
            // 03 section 9.2 says there is exactly one of these. Before this existed the provider
            // assigned Situation.yardLine straight into the read model's absolute space, so the
            // offence's own 25 drew on the drawn field's 15 -- ten yards of end zone unaccounted
            // for, on every marker, in every game.
            expectEqual(CoachWorldReadModelProvider.fieldX(yard: 0, direction: .leftToRight), 10,
                        "an own goal line sits a full end zone in from the drawn edge")
            expectEqual(CoachWorldReadModelProvider.fieldX(yard: 100, direction: .leftToRight), 110)
            expectEqual(CoachWorldReadModelProvider.fieldX(yard: 0, direction: .rightToLeft), 110)
            expectEqual(CoachWorldReadModelProvider.fieldX(yard: 100, direction: .rightToLeft), 10)
            expectEqual(CoachWorldReadModelProvider.fieldX(yard: 25, direction: .leftToRight), 35)
        }

        test("the first-down line always sits strictly beyond the line of scrimmage") {
            // MatchDayReadModel requires it, and it throws the whole model away when it does not
            // hold -- so getting this wrong blanks Match Day rather than drawing a wrong line.
            // Goal-to-go is the case that breaks a naive clamp to 100.
            for yardLine in stride(from: 0.0, through: 100.0, by: 5.0) {
                for distance in [1, 5, 10, 25, 99] {
                    let first = CoachWorldReadModelProvider.firstDownYard(
                        from: yardLine, distance: distance
                    )
                    expect(first > yardLine,
                           "at yard \(yardLine) and \(distance) to go the marker did not advance")
                    for direction in [MatchFieldDirection.leftToRight, .rightToLeft] {
                        let line = CoachWorldReadModelProvider.fieldX(
                            yard: yardLine, direction: direction
                        )
                        let marker = CoachWorldReadModelProvider.fieldX(
                            yard: first, direction: direction
                        )
                        expectIn(marker, 0...120, "the first-down marker left the drawn field")
                        expect(direction == .leftToRight ? marker > line : marker < line,
                               "the first-down marker fell the wrong side of the line")
                    }
                }
            }
        }

        test("the field's markers describe the same snap the field is drawing") {
            // The defect this closes was visible on a simulator and invisible to every test: the
            // line-of-scrimmage and first-down markers came from the upcoming situation while the
            // dots replayed the last completed snap, so after a turnover they sat at opposite ends
            // of the field. Everything drawn on the field now comes from one PlayRecord.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let play = PlayRecord(
                situation: Situation(down: 2, distance: 6, yardLine: 40),
                offensiveCall: OffensiveCall(playType: .run),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .gain, yards: 8, secondsElapsed: 6, matchups: [],
                    ballCarrierID: personnel.offense[1].id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play,
                offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )
            for direction in [MatchFieldDirection.leftToRight, .rightToLeft] {
                let projected = CoachWorldReadModelProvider.playback(
                    from: set, stableID: "snap-1", offenseDirection: direction
                )
                expectEqual(projected.lineOfScrimmageX,
                            CoachWorldReadModelProvider.fieldX(yard: 40, direction: direction),
                            "the drawn line of scrimmage is not the animated snap's")
                expectEqual(projected.firstDownLineX,
                            CoachWorldReadModelProvider.fieldX(yard: 46, direction: direction),
                            "the drawn first-down line is not the animated snap's")
                // The gain travels from the line to the end spot, in whichever direction the
                // offence is attacking.
                let travelled = projected.endSpotX - projected.lineOfScrimmageX
                expectEqual(Swift.abs(travelled), 8,
                            "the drawn end spot disagrees with the drawn line of scrimmage")
                expect(direction == .leftToRight ? travelled > 0 : travelled < 0,
                       "the gain ran the wrong way down the drawn field")
            }
        }

        test("a thrown ball actually leaves the turf") {
            // BallToken draws lift, apex scale, tilt and shadow separation entirely from
            // apexHeight, and the provider never passed one -- every leg of every kind, air
            // included, was grounded. A completion's air leg is the one that should not be.
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let offense = Array(personnel.offense.prefix(11))
            let target = offense[2]
            let play = PlayRecord(
                situation: Situation(down: 2, distance: 8, yardLine: 35),
                offensiveCall: OffensiveCall(playType: .pass, passDepth: .mid),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: SnapOutcome(
                    result: .gain, yards: 14, secondsElapsed: 6, matchups: [],
                    ballCarrierID: target.id, passerID: offense[0].id, targetID: target.id
                ),
                callInTriggers: []
            )
            let set = SnapAnchors.choreograph(
                play: play, offense: offense, defense: Array(personnel.defense.prefix(11))
            )
            let projected = CoachWorldReadModelProvider.playback(
                from: set, stableID: "snap-air", offenseDirection: .leftToRight
            )
            let airLegs = projected.ball.filter { $0.kind == "air" }
            expect(!airLegs.isEmpty, "a completed pass produced no air leg to check")
            for leg in airLegs {
                expect(leg.apexHeight > 0, "an air leg stayed grounded — the ball never left the turf")
                expectClose(leg.height(at: 0.5), leg.apexHeight, 0.001,
                            "the arc's stated peak is not where height(at:) actually peaks")
                expectClose(leg.height(at: 0), 0, 0.001, "the arc did not start on the ground")
                expectClose(leg.height(at: 1), 0, 0.001, "the arc did not land")
            }
            let groundedKinds: Set<String> = ["snap", "handoff", "carry", "loose"]
            for leg in projected.ball where groundedKinds.contains(leg.kind) {
                expectEqual(leg.apexHeight, 0,
                            "\(leg.kind) is a grounded kind and must not have lift")
            }
        }
    }
}
