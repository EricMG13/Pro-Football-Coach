import Foundation
import FootballSimCore

func runArcadeWatchTests() {

    // MARK: - Choreographer

    suite("Choreographer") {
        let offenseTeam = FieldFixtures.team(rating: 74)
        let defenseTeam = FieldFixtures.team(rating: 74, name: "D", abbreviation: "DEF")

        func event(
            category: PlayCategory,
            yards: Int,
            yardLine: Int = 40,
            involved: [UUID] = []
        ) -> PlayEvent {
            PlayEvent(
                drive: 1,
                quarter: 1,
                clockSeconds: 700,
                offenseTeamID: offenseTeam.id,
                category: category,
                yards: yards,
                down: 1,
                distance: 10,
                yardLine: yardLine,
                description: "Test play",
                involvedPlayerIDs: involved,
                homeScore: 0,
                awayScore: 0
            )
        }

        func choreograph(_ resolved: PlayEvent, call: OffensivePlay = .shortPass) -> ChoreographedPlay {
            Choreographer.play(
                event: resolved,
                offense: FieldFixtures.offense(offenseTeam),
                defense: FieldFixtures.defense(defenseTeam),
                call: call,
                defensiveCall: .base,
                seed: 3_300
            )
        }

        test("the play you watch ends exactly where the box score says") {
            // The fidelity invariant. If this ever fails, the mode is telling two different
            // stories about the same down, which is the exact failure this design set out to
            // avoid in the games it learns from.
            for yards in [-8, -1, 0, 3, 12, 27, 55] {
                for category in [PlayCategory.pass, .run, .sack] {
                    let played = choreograph(
                        event(category: category, yards: yards),
                        call: category == .run ? .insideRun : .shortPass
                    )
                    guard let last = played.finalFrame else {
                        expect(false, "\(category) for \(yards) produced no frames")
                        continue
                    }
                    expectEqual(played.officialYards, yards)
                    expectClose(
                        last.ballPoint.depth, Double(yards), 0.001,
                        "\(category) for \(yards) yards finished at \(last.ballPoint.depth)"
                    )
                }
            }
        }

        test("a play is watchable in a reasonable amount of time") {
            for yards in [0, 15, 60] {
                let played = choreograph(event(category: .pass, yards: yards))
                expect(played.duration <= 8, "a \(yards)-yard pass took \(played.duration)s")
                expect(played.duration >= 1, "and it cannot be instant either")
                expect(!played.frames.isEmpty, "no frames produced")
            }
        }

        test("all twenty-two are on the field for the whole play") {
            let played = choreograph(event(category: .pass, yards: 14))
            for frame in played.frames {
                expectEqual(frame.players.count, 22, "a frame dropped somebody")
            }
        }

        test("the animation follows whoever the engine says touched the ball") {
            let receiver = offenseTeam.starters(at: .wr).first
            guard let receiver else { return expect(false, "fixture has no receivers") }
            let played = choreograph(
                event(category: .pass, yards: 18, involved: [receiver.id])
            )
            guard let last = played.finalFrame else { return expect(false, "no frames") }
            let carrier = last.players.first { $0.role == .carrier }
            expectEqual(
                carrier?.id, receiver.id,
                "the man the engine credited should be the man carrying it"
            )
        }

        test("nobody ends up off the field") {
            let played = choreograph(event(category: .run, yards: 40), call: .outsideRun)
            for frame in played.frames {
                for player in frame.players {
                    expect(
                        abs(player.point.lateral) <= 1.0001,
                        "\(player.athlete.name) left the field at \(player.point.lateral)"
                    )
                }
            }
        }

        test("the same event choreographs the same way twice") {
            let resolved = event(category: .pass, yards: 21)
            let first = choreograph(resolved)
            let second = choreograph(resolved)
            expectEqual(first.frames.count, second.frames.count)
            for (left, right) in zip(first.frames, second.frames) {
                expectClose(left.ballPoint.depth, right.ballPoint.depth, 0.0001)
            }
        }
    }

    // MARK: - Defensive inputs

    suite("Defensive reads") {
        test("no read at all changes nothing") {
            let execution = DefensiveInputs.execution(input: .none, against: .shortPass)
            expect(execution.isNeutral, "an untouched defensive snap must be the simulated one")
        }

        test("guessing right helps, and guessing wrong costs the same") {
            let right = DefensiveInputs.execution(
                input: DefensiveInput(shade: .deep), against: .deepPass
            )
            let wrong = DefensiveInputs.execution(
                input: DefensiveInput(shade: .deep), against: .insideRun
            )
            expect(
                right.completionModifier < 0,
                "anticipating the call has to make it harder on the offense"
            )
            expect(wrong.completionModifier > 0, "and being wrong has to cost something")
            expectClose(
                abs(right.completionModifier), abs(wrong.completionModifier), 0.0001,
                "a read that is free when wrong is not a read"
            )
        }

        test("a timed break is worth more than a mistimed one") {
            let onTime = DefensiveInputs.execution(
                input: DefensiveInput(breakError: 0), against: .shortPass
            )
            let early = DefensiveInputs.execution(
                input: DefensiveInput(breakError: 1), against: .shortPass
            )
            expect(onTime.completionModifier < early.completionModifier)
            expect(
                early.completionModifier > 0,
                "breaking at the wrong moment should leave the man behind you open"
            )
            expect(
                onTime.interceptionMultiplier > 1,
                "a well-timed break is where a takeaway comes from"
            )
        }

        test("committing to the run fit is punished by play action") {
            let againstRun = DefensiveInputs.execution(
                input: DefensiveInput(committedToTackle: true), against: .insideRun
            )
            let againstPlayAction = DefensiveInputs.execution(
                input: DefensiveInput(committedToTackle: true), against: .playAction
            )
            expect(againstRun.yardsModifier < 0, "filling the gap should cost the run yards")
            expect(
                againstPlayAction.yardsModifier > 0,
                "biting on play action has to be the risk that makes it a decision"
            )
        }

        test("every combination of reads stays inside the cap") {
            for shade in CoverageShade.allCases {
                for breakError in [nil, 0.0, 0.5, 1.0] as [Double?] {
                    for committed in [nil, true, false] as [Bool?] {
                        for call in OffensivePlay.standardCalls {
                            let execution = DefensiveInputs.execution(
                                input: DefensiveInput(
                                    shade: shade,
                                    breakError: breakError,
                                    committedToTackle: committed
                                ),
                                against: call
                            )
                            expect(
                                abs(execution.completionModifier)
                                    <= ArcadeTuning.defensiveSwing + 0.0001,
                                "\(shade)/\(String(describing: breakError))/\(String(describing: committed)) "
                                    + "vs \(call.displayName) swung \(execution.completionModifier)"
                            )
                            expect(execution.sackMultiplier > 0)
                            expect(execution.interceptionMultiplier > 0)
                        }
                    }
                }
            }
        }

        test("the break window is wider for a defender who reads the game") {
            expect(
                DefensiveInputs.breakWindow(awareness: 99)
                    > DefensiveInputs.breakWindow(awareness: 40),
                "awareness should buy a more forgiving window"
            )
            expectClose(
                DefensiveInputs.breakError(tapAt: 1.0, releaseAt: 1.0, window: 0.3), 0, 0.0001
            )
            expectClose(
                DefensiveInputs.breakError(tapAt: 2.0, releaseAt: 1.0, window: 0.3), 1, 0.0001,
                "a tap a whole second off a 0.3s window is as wrong as it gets"
            )
        }

        test("defensive reads are worth less than offensive execution, on purpose") {
            // Defense is a coach's job in this design; the hands matter, but not as much as they
            // do when you have the ball.
            expect(
                ArcadeTuning.defensiveSwing < ArcadeTuning.completionSwing,
                "the defensive cap has to sit under the offensive one"
            )
        }
    }
}
