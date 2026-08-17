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

        test("every position aligns somewhere on the field") {
            // Enumerated from Position.allCases by construction, so a position added tomorrow fails
            // this the day it is added rather than the day someone remembers it.
            for position in Position.allCases {
                for side in Side.allCases {
                    for index in 0..<4 {
                        let point = SnapAnchors.alignment(
                            for: position, index: index, side: side, lineOfScrimmage: 40
                        )
                        expectIn(point.yard, 0...100, "\(position) aligned off the field")
                        expectIn(point.lateral, 0...1, "\(position) aligned outside the sidelines")
                    }
                }
            }
        }

        test("the offensive line stands on the line and the defence stands beyond it") {
            let los = 40.0
            let centre = SnapAnchors.alignment(
                for: .center, index: 0, side: .home, lineOfScrimmage: los
            )
            expectEqual(centre.yard, los, "the centre is on the line of scrimmage")
            expectEqual(centre.lateral, AnchorRules.centerLateral)

            let passer = SnapAnchors.alignment(
                for: .quarterback, index: 0, side: .home, lineOfScrimmage: los
            )
            expect(passer.yard < los, "the passer sets up behind the line")

            let edge = SnapAnchors.alignment(
                for: .edgeRusher, index: 0, side: .away, lineOfScrimmage: los
            )
            expect(edge.yard > los, "the defensive front lines up beyond the line of scrimmage")

            let safety = SnapAnchors.alignment(
                for: .safety, index: 0, side: .away, lineOfScrimmage: los
            )
            expect(safety.yard > edge.yard, "safeties play behind the front")
        }

        test("two players at the same position take different alignments") {
            let los = 40.0
            let first = SnapAnchors.alignment(
                for: .wideReceiver, index: 0, side: .home, lineOfScrimmage: los
            )
            let second = SnapAnchors.alignment(
                for: .wideReceiver, index: 1, side: .home, lineOfScrimmage: los
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
            let play = PlayRecord(
                situation: Situation(),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .man),
                outcome: before,
                callInTriggers: []
            )
            _ = SnapAnchors.choreograph(
                play: play,
                offense: Array(personnel.offense.prefix(11)),
                defense: Array(personnel.defense.prefix(11))
            )
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
    }
}
