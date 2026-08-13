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

        // 02 section 4.2a. Bootstrap issued no contracts, so nothing expired, nobody reached free
        // agency, and the draft's first pick hit activeRosterFull. Beats 1 and 2 of the pro
        // offseason were prose with nothing behind them.
        test("every bootstrapped professional holds a contract, and no college player does") {
            let state = GameState.bootstrap(seed: 80_010)
            for team in state.proTeams.values {
                for id in team.rosterIDs {
                    guard let player = state.players[id] else {
                        expect(false, "a pro roster references a missing player")
                        continue
                    }
                    guard let contract = player.contract else {
                        expect(false, "pro player \(player.fullName) holds no contract")
                        continue
                    }
                    expect(ProRules.contractYearsRange.contains(contract.years),
                           "contract term \(contract.years) is outside the rules-owned range")
                    expectEqual(contract.signedSeason, state.calendar.season)
                    expect(contract.baseSalaryByYear.allSatisfy { $0 > 0 },
                           "a bootstrapped deal pays nothing in some year")
                }
            }
            for programme in state.programmes.values {
                for id in programme.rosterIDs where state.players[id]?.contract != nil {
                    expect(false, "a college player holds a pro contract")
                }
            }
        }

        test("the bootstrapped league is cap-legal for every team") {
            // Colours must pass contrast at generation rather than being fixed up later, and a
            // bootstrapped payroll is the same shape of obligation: a league that starts illegal
            // has no legal move that makes it legal.
            let state = GameState.bootstrap(seed: 80_011)
            let cap = ProRules.salaryCap(seasonsAfterBase: 0)
            for team in state.proTeams.values {
                let committed = team.rosterIDs.reduce(0) { total, id in
                    total + (state.players[id]?.contract?.capHit(atSeason: state.calendar.season) ?? 0)
                }
                expect(committed <= cap,
                       "team payroll \(committed) exceeds the cap \(cap)")
                expect(committed > 0, "a team committed nothing at all")
            }
        }

        test("terms are spread so about a fifth of the league expires each season") {
            // A flat term is a cliff; no contracts at all is a dead market. The spread is also
            // bounded from above: expiries land in a free-agent pool capped at
            // ProMarketState.maximumFreeAgentIDs, and a season that expires more than it holds
            // throws invalidRoot.
            let state = GameState.bootstrap(seed: 80_012)
            var byTerm: [Int: Int] = [:]
            var total = 0
            for team in state.proTeams.values {
                for id in team.rosterIDs {
                    guard let years = state.players[id]?.contract?.years else { continue }
                    byTerm[years, default: 0] += 1
                    total += 1
                }
            }
            expectEqual(total, ProRules.teamCount * ProRules.activeRosterLimit)
            expectEqual(byTerm.keys.sorted(), [1, 2, 3, 4, 5])

            let expiringFirstSeason = byTerm[1] ?? 0
            let fifth = total / 5
            expect(expiringFirstSeason > fifth * 3 / 4 && expiringFirstSeason < fifth * 5 / 4,
                   "\(expiringFirstSeason) deals expire after season one; a fifth of \(total) is \(fifth)")
            expect(expiringFirstSeason < ProMarketState.maximumFreeAgentIDs,
                   "a single season's expiries would overflow the free-agent pool")
        }

        test("the same seed produces the same contract terms across processes") {
            let first = GameState.bootstrap(seed: 80_013)
            let second = GameState.bootstrap(seed: 80_013)
            for team in first.proTeams.values {
                for id in team.rosterIDs {
                    expectEqual(first.players[id]?.contract, second.players[id]?.contract)
                }
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
