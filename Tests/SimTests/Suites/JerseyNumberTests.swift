import Foundation
import FootballSimCore

/// `02` §4.1a. The three properties a derived number has to have, and one it deliberately does not.
func runJerseyNumberTests() {
    suite("Jersey numbers") {
        test("every position wears a band, with no gap in the table") {
            // Totality by construction, the same guard `RulesTests` puts on the decline-age table:
            // a position added later must not fall through to a default nobody chose.
            for position in Position.allCases {
                expect(SharedRules.jerseyBandByPosition[position] != nil,
                       "\(position.rawValue) has no jersey band (02 section 4.1a)")
            }
            for (position, band) in SharedRules.jerseyBandByPosition {
                expect(SharedRules.jerseyNumberRange.contains(band.lowerBound)
                           && SharedRules.jerseyNumberRange.contains(band.upperBound),
                       "\(position.rawValue)'s band leaves the legal range")
            }
        }

        test("every band is wide enough for what the roster template asks of it") {
            // Sized against the template rather than against memory of real football. The first
            // version put nine edge rushers and nine defensive tackles into a ten-number band, so
            // the spill fired on a normal roster and a defensive tackle appeared as `#0` on the
            // first screen anyone opened. This is the assertion that would have caught it.
            //
            // Demand is per band per unit, because that is the scope uniqueness has: two positions
            // sharing a band inside one unit compete for the same numbers.
            for (unit, positions) in Dictionary(grouping: Position.allCases, by: \.unit) {
                var demandByBand: [ClosedRange<Int>: Int] = [:]
                for position in positions {
                    guard let band = SharedRules.jerseyBandByPosition[position] else { continue }
                    demandByBand[band, default: 0] +=
                        CollegeRules.initialRosterByPosition[position] ?? 0
                }
                for (band, demand) in demandByBand {
                    expect(band.count >= demand,
                           "\(unit.rawValue) band \(band.lowerBound)-\(band.upperBound) holds "
                               + "\(band.count) numbers for \(demand) players")
                }
            }
        }

        test("every unit is numbered uniquely, and inside the bands where it can be") {
            // Per unit, not per roster, and the arithmetic is why: 105 college players against 100
            // legal numbers. A roster-wide assertion here would demand something impossible and
            // then be "fixed" by widening the number range, which is the wrong repair.
            expect(CollegeRules.rosterLimit > SharedRules.jerseyNumberRange.count,
                   "a roster now fits inside the number range, so re-read 02 section 4.1a "
                       + "before assuming uniqueness must stay per unit")
            let state = GameState.bootstrap(seed: 71_001)
            var checkedRosters = 0
            for programme in state.programmes.values.prefix(8) {
                let players = programme.rosterIDs.compactMap { state.players[$0] }
                guard !players.isEmpty else { continue }
                checkedRosters += 1
                let numbers = JerseyNumbers.assign(players)

                expectEqual(numbers.count, players.count)
                for unit in Unit.allCases {
                    let inUnit = players.filter { $0.position.unit == unit }
                    let assigned = inUnit.compactMap { numbers[$0.id] }
                    expectEqual(Set(assigned).count, inUnit.count,
                                "\(unit.rawValue) has two players wearing one number")
                }
                for number in numbers.values {
                    expect(SharedRules.jerseyNumberRange.contains(number),
                           "\(number) is outside the legal range")
                }
                // With the bands sized to the template, a generated roster should never spill.
                // Asserted at zero rather than at a majority, because the spill is a backstop for
                // a roster no template produces — if it fires here, a band is too narrow.
                let outOfBand = players.filter { player in
                    !JerseyNumbers.band(for: player).contains(numbers[player.id] ?? -1)
                }
                expect(outOfBand.isEmpty,
                       "\(outOfBand.count) players spilled out of their band, e.g. "
                           + "\(outOfBand.first.map { "\($0.position.rawValue) #\(numbers[$0.id] ?? -1)" } ?? "")")
            }
            expect(checkedRosters >= 8, "checked \(checkedRosters) rosters")
        }

        test("every roster in the world is legally numbered, at every swept seed") {
            // The check above numbers eight of 134 programmes at one seed and no pro team at all.
            // That is the coverage-boundary pattern CLAUDE.md names: the pro template is a
            // different shape (53 against 105, six corners against nine) and nothing had ever
            // numbered one. Enumerated by construction over every roster the world holds, swept,
            // so a tier or a template added later is covered the day it is added.
            for seed: UInt64 in [71_101, 71_102, 71_103] {
                let state = GameState.bootstrap(seed: seed)
                let rosters = state.programmes.values.map(\.rosterIDs)
                    + state.proTeams.values.map(\.rosterIDs)
                expectEqual(rosters.count, CollegeRules.programmeCount + ProRules.teamCount,
                            "seed \(seed): the world does not hold every roster")
                for rosterIDs in rosters {
                    let players = rosterIDs.compactMap { state.players[$0] }
                    expectEqual(players.count, rosterIDs.count,
                                "seed \(seed): a roster references a missing player")
                    let numbers = JerseyNumbers.assign(players)
                    expectEqual(numbers.count, players.count,
                                "seed \(seed): a player was left without a number")
                    for unit in Unit.allCases {
                        let inUnit = players.filter { $0.position.unit == unit }
                        expectEqual(Set(inUnit.compactMap { numbers[$0.id] }).count, inUnit.count,
                                    "seed \(seed): \(unit.rawValue) has two players wearing one "
                                        + "number")
                    }
                    for number in numbers.values {
                        expect(SharedRules.jerseyNumberRange.contains(number),
                               "seed \(seed): \(number) is outside the legal range")
                    }
                    let spilled = players.filter {
                        !JerseyNumbers.band(for: $0).contains(numbers[$0.id] ?? -1)
                    }
                    expect(spilled.isEmpty,
                           "seed \(seed): \(spilled.count) players spilled out of their band, e.g. "
                               + "\(spilled.first.map { "\($0.position.rawValue) #\(numbers[$0.id] ?? -1)" } ?? "")")
                }
            }
        }

        test("the same roster numbers the same way, in any order") {
            let state = GameState.bootstrap(seed: 71_002)
            guard let programme = state.programmes.values.first else {
                expect(false, "no programme generated")
                return
            }
            let players = programme.rosterIDs.compactMap { state.players[$0] }
            expectEqual(JerseyNumbers.assign(players), JerseyNumbers.assign(players.reversed()))
        }

        test("numbers derive from identifier bytes, so they survive a save round trip") {
            // The clause that matters most: `03` §3 forbids a salted hash, and a number drawn from
            // one would change on every launch. A round trip through the envelope is the cheapest
            // way to assert the derivation reads persisted bytes rather than process state.
            let state = GameState.bootstrap(seed: 71_003)
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            )
            guard let programme = state.programmes.values.first else {
                expect(false, "no programme generated")
                return
            }
            expectEqual(
                JerseyNumbers.assign(programme.rosterIDs.compactMap { state.players[$0] }),
                JerseyNumbers.assign(programme.rosterIDs.compactMap { restored.players[$0] })
            )
        }

        test("a roster larger than any band is still fully numbered") {
            // The spill path, exercised rather than assumed: sixty quarterbacks cannot fit in a
            // nineteen-number band, and every one of them must still get a number.
            let players = (0..<60).map { ordinal in
                Player(
                    id: UUID(uuidString: String(
                        format: "00000000-0000-4000-8000-%012X",
                        ordinal
                    ))!,
                    firstName: "Test",
                    lastName: "Quarterback",
                    position: .quarterback,
                    age: 20,
                    attributes: Attributes(),
                    potential: Rating(70),
                    eligibility: Eligibility()
                )
            }
            let numbers = JerseyNumbers.assign(players)
            expectEqual(numbers.count, 60)
            expectEqual(Set(numbers.values).count, 60)
        }
    }
}
