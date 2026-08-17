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
    }
}
