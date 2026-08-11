import Foundation
import FootballSimCore

func runRosterPopulationTests() {
    suite("Initial roster population") {
        test("bootstrap fills every roster to its rules-owned target") {
            let state = GameState.bootstrap(seed: 80_001)
            let expectedCollege = CollegeRules.programmeCount * CollegeRules.rosterLimit
            let expectedPro = ProRules.teamCount * ProRules.activeRosterLimit
            expectEqual(state.players.count, expectedCollege + expectedPro)

            for programme in state.programmes.values {
                expectEqual(programme.rosterIDs.count, CollegeRules.rosterLimit)
                expectEqual(programme.scholarshipCount, CollegeRules.scholarshipLimit)
                assertPositionTemplate(
                    rosterIDs: programme.rosterIDs,
                    state: state,
                    expected: CollegeRules.initialRosterByPosition
                )
            }
            for team in state.proTeams.values {
                expectEqual(team.rosterIDs.count, ProRules.activeRosterLimit)
                expectEqual(team.practiceSquadIDs.count, 0)
                assertPositionTemplate(
                    rosterIDs: team.rosterIDs,
                    state: state,
                    expected: ProRules.initialRosterByPosition
                )
            }
        }

        test("college and pro age/eligibility shapes are tier-correct") {
            let state = GameState.bootstrap(seed: 80_002)
            for programme in state.programmes.values {
                for id in programme.rosterIDs {
                    guard let player = state.players[id] else {
                        expect(false, "a college roster player is missing")
                        continue
                    }
                    expect((18...21).contains(player.age))
                    expect(player.eligibility != nil)
                    expect(player.contract == nil)
                }
            }
            for team in state.proTeams.values {
                for id in team.rosterIDs {
                    guard let player = state.players[id] else {
                        expect(false, "a pro roster player is missing")
                        continue
                    }
                    expect((22...34).contains(player.age))
                    expect(player.eligibility == nil)
                }
            }
        }

        test("generated ratings are sparse, bounded, and position-relevant") {
            let state = GameState.bootstrap(seed: 80_003)
            for player in state.players.values {
                expect(!player.attributes.assigned.isEmpty)
                expect(Set(player.attributes.assigned.keys).isSubset(
                    of: Set(player.position.ratedAttributes)
                ))
                expect(player.attributes.assigned.values.allSatisfy {
                    SharedRules.ratingRange.contains($0.value)
                })
                expect(player.position.ratedAttributes.allSatisfy {
                    SharedRules.ratingRange.contains(player.attributes[$0].value)
                })
                expect(SharedRules.potentialRange.contains(player.potential.value))
            }
        }

        test("player ownership and generated full names pass global guards") {
            let state = GameState.bootstrap(seed: 80_004)
            let report = WorldIntegrity.check(state)
            expect(report.isValid, report.issues.map(\.description).joined(separator: ", "))
            expectEqual(
                Set(state.programmes.values.flatMap(\.rosterIDs)
                    + state.proTeams.values.flatMap(\.rosterIDs)).count,
                state.players.count
            )
            for player in state.players.values {
                expect(!Blocklist.blocks(player.fullName),
                       "generated player name collides with the legal blocklist: \(player.fullName)")
            }
        }
    }
}

private func assertPositionTemplate(
    rosterIDs: [UUID],
    state: GameState,
    expected: [Position: Int]
) {
    var actual: [Position: Int] = [:]
    for id in rosterIDs {
        guard let player = state.players[id] else {
            expect(false, "a roster references a missing player")
            continue
        }
        actual[player.position, default: 0] += 1
    }
    expectEqual(actual, expected)
}
