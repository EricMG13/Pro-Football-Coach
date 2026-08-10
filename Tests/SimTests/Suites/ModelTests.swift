import Foundation
import FootballSimCore

// P1's model types are mostly data. These test the parts that can be wrong: the rating clamp, the
// eligibility clock, contract money, and the roster-legality predicates. Plain fields with no
// behaviour get no test — YAGNI applies to tests too, and a test that only restates a stored
// property is noise that makes the real assertions harder to find.

func runModelTests() {
    suite("Rating") {
        test("a rating clamps to 40 to 99 at both ends") {
            expectEqual(Rating(12).value, 40)
            expectEqual(Rating(250).value, 99)
            expectEqual(Rating(70).value, 70)
        }

        test("the boundaries themselves are legal values") {
            expectEqual(Rating(40).value, 40)
            expectEqual(Rating(99).value, 99)
        }

        test("a rating decoded from a corrupt save clamps rather than trapping") {
            // The clamp has to live in init(from:) as well as init(_:), or a save hand-edited to
            // 500 produces a Rating that violates its own invariant and every downstream
            // calculation quietly reads it.
            let decoded = try JSONDecoder.stable().decode(Rating.self, from: Data("500".utf8))
            expectEqual(decoded.value, 99)
            let low = try JSONDecoder.stable().decode(Rating.self, from: Data("-3".utf8))
            expectEqual(low.value, 40)
        }

        test("a rating encodes as a bare number, not an object") {
            // Saves are large and every player carries dozens of these. A single-value container
            // is the difference between "68" and {"value":68} per attribute per player.
            expectEqual(String(decoding: try JSONEncoder.stable().encode(Rating(68)), as: UTF8.self),
                        "68")
        }

        test("adjusting a rating stays inside the range") {
            expectEqual(Rating(97).adjusted(by: 10).value, 99)
            expectEqual(Rating(42).adjusted(by: -10).value, 40)
            expectEqual(Rating(70).adjusted(by: 5).value, 75)
        }

        test("ratings order by value") {
            expect(Rating(60) < Rating(80), "ratings do not compare")
        }
    }

    suite("Attributes") {
        test("an unset attribute reads as the floor rather than as zero") {
            // Zero is not a legal rating. An attribute a position never uses must still answer
            // inside the scale, or an engine that averages across a set silently drags the mean
            // toward a value the model says cannot exist.
            let attributes = Attributes([.speed: Rating(88)])
            expectEqual(attributes[.speed].value, 88)
            expectEqual(attributes[.coverage].value, SharedRules.ratingRange.lowerBound)
        }

        test("an attribute map encodes as a keyed object, not a hash-ordered array") {
            // The exact defect CodingSupport was ported to prevent, reintroduced for a different
            // key type. Swift encodes a dictionary whose key is not CodingKeyRepresentable as a
            // flat [key, value, key, value] array in DICTIONARY ORDER, which is salted per process.
            // Every player carries one of these, so without the conformance the save bytes churn
            // between launches and no byte-level determinism test downstream can hold.
            //
            // Asserting the shape rather than comparing two in-process encodings is what makes this
            // decisive: within one process the hash seed is constant, so the churn is invisible to
            // a round-trip or a repeat-encode check. It is the array shape that is the bug.
            let json = String(
                decoding: try JSONEncoder.stable().encode(
                    Attributes([.speed: Rating(88), .coverage: Rating(61), .hands: Rating(70)])
                ),
                as: UTF8.self
            )
            expect(json.hasPrefix("{"), "an attribute map encoded as \(json)")
            expect(json.contains("\"speed\":88"), "attributes are not keyed by name: \(json)")
        }

        test("a coach rating map encodes as a keyed object too") {
            let staff = Staff(id: UUID(uuidString: "00000000-0000-4000-8000-00000000000C")!,
                              firstName: "Ray", lastName: "Okonkwo",
                              role: .offensiveCoordinator,
                              ratings: [.development: Rating(80), .recruiting: Rating(65)])
            let json = String(decoding: try JSONEncoder.stable().encode(staff), as: UTF8.self)
            expect(json.contains("\"development\":80"),
                   "coach ratings are not keyed by name: \(json)")
        }

        test("every attribute is rated by at least one position") {
            // The previous version of this test iterated a hand-written list and asserted
            // Attribute.allCases.contains(each) — which cannot be false, because every value of the
            // type is in allCases. It was a tautology over a list someone remembered, and it is why
            // blockLeverage shipped declared, never rated, reading the floor for every player alive
            // and turning P3's kick-block matchup into a constant.
            //
            // This version enumerates by construction. An attribute no position rates is dead
            // capability, which 08-OPUS5-BUILD-PROMPT.md names as this project's first failure mode.
            var rated: Set<Attribute> = []
            for position in Position.allCases { rated.formUnion(position.ratedAttributes) }
            let orphaned = Attribute.allCases.filter { !rated.contains($0) }
            expect(orphaned.isEmpty,
                   "these attributes are declared and rated by no position, so they read the floor "
                       + "forever: " + orphaned.map(\.rawValue).sorted().joined(separator: ", "))
        }

        test("every attribute has a label") {
            for attribute in Attribute.allCases {
                expect(!attribute.label.isEmpty, "\(attribute) has no label")
            }
        }

        test("writing the floor does not turn an unset attribute into a stored one") {
            // What a development tick that produced no change looks like. Storing it would make two
            // players that read identically compare unequal and encode differently, failing a
            // state-equality check and growing the save for nothing.
            var attributes = Attributes()
            attributes[.speed] = attributes[.speed]
            expectEqual(attributes, Attributes())
            expectEqual(String(decoding: try JSONEncoder.stable().encode(attributes), as: UTF8.self),
                        "{\"values\":{}}")
        }
    }

    suite("Position") {
        test("every position has a unit, a group and a decline age") {
            for position in Position.allCases {
                expect(SharedRules.declineAgeByPosition[position] != nil,
                       "\(position) has no decline age in the rules table")
                expectEqual(position.declineAge, SharedRules.declineAgeByPosition[position]!)
                expect(!position.ratedAttributes.isEmpty, "\(position) rates no attributes")
            }
        }

        test("every position rates the attributes shared across all of them") {
            for position in Position.allCases {
                for shared in [Attribute.speed, .strength, .agility, .durability, .awareness,
                               .schemeFit, .temperament, .workEthic, .clutch] {
                    expect(position.ratedAttributes.contains(shared),
                           "\(position) does not rate \(shared.rawValue)")
                }
            }
        }

        test("units partition the positions") {
            let byUnit = Dictionary(grouping: Position.allCases, by: \.unit)
            expectEqual(byUnit.values.reduce(0) { $0 + $1.count }, Position.allCases.count)
            for unit in Unit.allCases {
                expect(!(byUnit[unit] ?? []).isEmpty, "\(unit) has no positions")
            }
        }

        test("a player past the decline age is declining, and one before it is not") {
            func player(age: Int, at position: Position) -> Player {
                Player(firstName: "A", lastName: "B", position: position, age: age,
                       attributes: Attributes(), potential: Rating(70))
            }
            expect(player(age: 27, at: .runningBack).isDeclining, "a 27-year-old back is declining")
            expect(!player(age: 26, at: .runningBack).isDeclining, "a 26-year-old back is not")
            expect(!player(age: 33, at: .quarterback).isDeclining,
                   "a 33-year-old quarterback is not declining")
        }
    }

    suite("Player") {
        test("overall averages only the attributes the position reads, and stays in range") {
            // A quarterback rated on their coverage would be a nonsense number on every readout.
            // Swept across every position at both extremes: the result must never leave 40 to 99
            // and must never divide by zero.
            for position in Position.allCases {
                let floor = Player(firstName: "A", lastName: "B", position: position, age: 24,
                                   attributes: Attributes(), potential: Rating(70))
                expectEqual(floor.overall.value, SharedRules.ratingRange.lowerBound)

                var maxed = Attributes()
                for attribute in Attribute.allCases { maxed[attribute] = Rating(99) }
                let ceiling = Player(firstName: "A", lastName: "B", position: position, age: 24,
                                     attributes: maxed, potential: Rating(70))
                expectEqual(ceiling.overall.value, SharedRules.ratingRange.upperBound)
            }
        }

        test("traits are stored in a fixed order whatever order they arrive in") {
            // The determinism fix. Set<Trait> encoded in per-launch order; an array in allCases
            // order encodes the same bytes every time.
            let one = Player(firstName: "A", lastName: "B", position: .safety, age: 24,
                             attributes: Attributes(), potential: Rating(70),
                             traits: [.volatile, .ironman, .mentor])
            let other = Player(id: one.id, firstName: "A", lastName: "B", position: .safety, age: 24,
                               attributes: Attributes(), potential: Rating(70),
                               traits: [.mentor, .volatile, .ironman])
            expectEqual(one.traits, other.traits)
            expectEqual(try SaveEnvelope.encode(one), try SaveEnvelope.encode(other),
                        "trait order changed the save bytes")
            expectEqual(one.traits, Trait.allCases.filter(one.traits.contains),
                        "traits are not in allCases order")
        }

        test("a duplicate trait is not stored twice") {
            let player = Player(firstName: "A", lastName: "B", position: .safety, age: 24,
                                attributes: Attributes(), potential: Rating(70),
                                traits: [.ironman, .ironman])
            expectEqual(player.traits.count, 1)
        }

        test("adding and removing a trait keeps the order and the uniqueness") {
            var player = Player(firstName: "A", lastName: "B", position: .safety, age: 24,
                                attributes: Attributes(), potential: Rating(70), traits: [.volatile])
            player.add(.ironman)
            expectEqual(player.traits, [.ironman, .volatile], "add did not canonicalise the order")
            player.add(.ironman)
            expectEqual(player.traits.count, 2, "add stored a duplicate")
            expect(player.has(.ironman), "has() does not see an added trait")
            player.remove(.ironman)
            expectEqual(player.traits, [.volatile])
        }

        test("a save written with traits in another order is canonicalised on load") {
            // The decoder routes through the initialiser, so a save from before the rule existed
            // comes back in order rather than carrying the old order forward.
            let player = Player(firstName: "A", lastName: "B", position: .safety, age: 24,
                                attributes: Attributes(), potential: Rating(70),
                                traits: [.volatile, .ironman])
            let restored = try SaveEnvelope.decode(Player.self,
                                                   from: try SaveEnvelope.encode(player))
            expectEqual(restored.traits, [.ironman, .volatile])
        }
    }

    suite("Traits and schemes") {
        test("every trait names a system it bites in") {
            // 02 section 5: traits have mechanical bite "never as flavour". A trait whose system is
            // not in TraitSystem does not compile, and this asserts the mapping is total.
            for trait in Trait.allCases {
                expect(TraitSystem.allCases.contains(trait.bitesIn),
                       "\(trait) bites in a system that does not exist")
                expect(!trait.label.isEmpty, "\(trait) has no label")
            }
        }

        test("every scheme emphasises something") {
            // 02 section 6: a scheme that emphasised nothing would be a label, which section 6
            // explicitly says scheme identity is not.
            for scheme in OffensiveScheme.allCases {
                expect(!scheme.emphasises.isEmpty, "\(scheme) emphasises nothing")
                expect(!scheme.label.isEmpty, "\(scheme) has no label")
            }
            for scheme in DefensiveScheme.allCases {
                expect(!scheme.emphasises.isEmpty, "\(scheme) emphasises nothing")
                expect(!scheme.label.isEmpty, "\(scheme) has no label")
            }
        }

        test("no two schemes on a side emphasise the same set") {
            // Two identical schemes are one scheme with two names, and 02 section 6 makes changing
            // scheme expensive on the premise that it means something.
            expectEqual(Set(OffensiveScheme.allCases.map(\.emphasises)).count,
                        OffensiveScheme.allCases.count, "two offensive schemes are identical")
            expectEqual(Set(DefensiveScheme.allCases.map(\.emphasises)).count,
                        DefensiveScheme.allCases.count, "two defensive schemes are identical")
        }

        test("scheme identity reads the right side of the ball for a position") {
            let identity = SchemeIdentity(offense: .airRaid, defense: .pressMan)
            expectEqual(identity.emphasised(for: .quarterback), OffensiveScheme.airRaid.emphasises)
            expectEqual(identity.emphasised(for: .cornerback), DefensiveScheme.pressMan.emphasises)
            expect(identity.emphasised(for: .kicker).isEmpty,
                   "a specialist inherited a scheme emphasis")
        }
    }

    suite("Staff and league") {
        test("the coordinator roles match the count shared rules states") {
            expectEqual(StaffRole.coordinators.count, SharedRules.coordinatorCount)
            for role in StaffRole.coordinators {
                expect(StaffRole.allCases.contains(role), "\(role) is not a staff role")
            }
        }

        test("an unrated coach attribute reads at the floor, not zero") {
            let coach = Staff(firstName: "R", lastName: "O", role: .headCoach,
                              ratings: [.development: Rating(80)])
            expectEqual(coach.rating(.development).value, 80)
            expectEqual(coach.rating(.recruiting).value, SharedRules.ratingRange.lowerBound)
        }

        test("a tier knows its own season length and size") {
            expectEqual(Tier.college.seasonWeeks, CollegeRules.seasonWeeks)
            expectEqual(Tier.pro.seasonWeeks, ProRules.seasonWeeks)
            expectEqual(Tier.college.memberCount, CollegeRules.programmeCount)
            expectEqual(Tier.pro.memberCount, ProRules.teamCount)
        }

        test("both tiers fit inside the shared in-season calendar") {
            // 02 section 11.3.1: one save runs both leagues on one week counter, so neither tier
            // may run past it.
            for tier in Tier.allCases {
                expect(tier.seasonWeeks <= SharedRules.inSeasonWeeks,
                       "\(tier) runs \(tier.seasonWeeks) weeks, past the shared calendar's "
                           + "\(SharedRules.inSeasonWeeks)")
            }
        }

        test("league seeds derive from the root rather than being stored") {
            let league = League(seed: 1234, season: 2)
            expectEqual(league.seasonSeed,
                        SeededRandom.derive(from: 1234, scope: .season, ordinal: 2))
            expectEqual(league.weekSeed(5),
                        SeededRandom.derive(from: league.seasonSeed, scope: .week, ordinal: 5))
            expect(league.weekSeed(5) != league.weekSeed(6), "two weeks share a seed")
        }
    }

    suite("Rivalry bound") {
        test("a programme truncates rivalries on construction, on append and on load") {
            // A bound applied only in the memberwise initialiser is not a bound: appending and
            // decoding are the two paths that actually accumulate rivalries across a career, and
            // both bypassed it. Fifty-eight rivals round-tripped through the envelope before this.
            let many = (0..<50).map { index in
                UUID(uuidString: String(format: "00000000-0000-4000-8000-%012X", index))!
            }
            var programme = Programme(name: "N", nickname: "K", cityName: "C", archetypeID: 1,
                                      scheme: SchemeIdentity(offense: .proStyle, defense: .fourThree),
                                      prestige: Rating(70), rivalIDs: many)
            expectEqual(programme.rivalIDs.count, SharedRules.rivalriesPerProgramme)

            for id in many { programme.addRival(id) }
            expectEqual(programme.rivalIDs.count, SharedRules.rivalriesPerProgramme,
                        "addRival grew the list past its bound")

            let restored = try SaveEnvelope.decode(Programme.self,
                                                   from: try SaveEnvelope.encode(programme))
            expectEqual(restored.rivalIDs.count, SharedRules.rivalriesPerProgramme)
            expectEqual(restored, programme)
        }

        test("adding the same rival twice does not consume two slots") {
            var programme = Programme(name: "N", nickname: "K", cityName: "C", archetypeID: 1,
                                      scheme: SchemeIdentity(offense: .proStyle, defense: .fourThree),
                                      prestige: Rating(70))
            let rival = UUID(uuidString: "00000000-0000-4000-8000-0000000000AB")!
            programme.addRival(rival)
            programme.addRival(rival)
            expectEqual(programme.rivalIDs.count, 1)
        }
    }

    suite("Eligibility") {
        test("a fresh clock has four seasons to play inside five years") {
            let clock = Eligibility()
            expectEqual(clock.seasonsRemaining, CollegeRules.seasonsOfCompetition)
            expectEqual(clock.yearsRemaining, CollegeRules.eligibilityClockYears)
            expect(!clock.isExhausted, "a fresh clock reads as exhausted")
        }

        test("playing a season spends a season and a year") {
            let clock = Eligibility().advanced(redshirting: false)
            expectEqual(clock.seasonsRemaining, 3)
            expectEqual(clock.yearsRemaining, 4)
        }

        test("redshirting spends a year and no season") {
            // This is the whole point of the five-year clock, and it is 02 section 4.1's redshirt
            // decision having something to spend.
            let clock = Eligibility().advanced(redshirting: true)
            expectEqual(clock.seasonsRemaining, CollegeRules.seasonsOfCompetition)
            expectEqual(clock.yearsRemaining, 4)
        }

        test("four played seasons exhaust the clock") {
            var clock = Eligibility()
            for _ in 0..<4 { clock = clock.advanced(redshirting: false) }
            expectEqual(clock.seasonsRemaining, 0)
            expect(clock.isExhausted, "four played seasons did not exhaust eligibility")
        }

        test("a redshirt plus four seasons exhausts both halves at once") {
            var clock = Eligibility().advanced(redshirting: true)
            for _ in 0..<4 { clock = clock.advanced(redshirting: false) }
            expectEqual(clock.seasonsRemaining, 0)
            expectEqual(clock.yearsRemaining, 0)
            expect(clock.isExhausted, "the five-year clock did not run out")
        }

        test("running out of years exhausts eligibility even with seasons left") {
            // Two redshirts and three played seasons: a season of competition remains, but the
            // five-year window has closed. Checking only seasonsRemaining would let this player
            // keep playing forever.
            var clock = Eligibility()
            for _ in 0..<2 { clock = clock.advanced(redshirting: true) }
            for _ in 0..<3 { clock = clock.advanced(redshirting: false) }
            expectEqual(clock.seasonsRemaining, 1)
            expectEqual(clock.yearsRemaining, 0)
            expect(clock.isExhausted, "the clock ran out of years but did not read as exhausted")
        }

        test("advancing an exhausted clock does not go negative") {
            var clock = Eligibility()
            for _ in 0..<9 { clock = clock.advanced(redshirting: false) }
            expectEqual(clock.seasonsRemaining, 0)
            expectEqual(clock.yearsRemaining, 0)
        }
    }

    suite("Contract") {
        test("proration spreads a bonus over the contract's years") {
            let deal = Contract(years: 4, baseSalaryByYear: [1_000_000, 1_000_000, 1_000_000, 1_000_000],
                                signingBonus: 8_000_000)
            expectEqual(deal.prorationYears, 4)
            expectEqual(deal.annualBonusProration, 2_000_000)
        }

        test("proration is capped at five years on a longer deal") {
            let deal = Contract(years: 7, baseSalaryByYear: Array(repeating: 1_000_000, count: 7),
                                signingBonus: 10_000_000)
            expectEqual(deal.prorationYears, ProRules.maximumProrationYears)
            expectEqual(deal.annualBonusProration, 2_000_000)
        }

        test("a bonus that does not divide evenly loses no dollars") {
            // Integer dollars. If the per-year figure is truncated and the years are then summed,
            // the difference vanishes and the cap is charged less than the team actually paid —
            // which is a cap-laundering hole, not a rounding nit.
            let deal = Contract(years: 3, baseSalaryByYear: Array(repeating: 1_000_000, count: 3),
                                signingBonus: 10_000_000)
            let charged = (0..<3).reduce(0) { $0 + deal.bonusProration(inYear: $1) }
            expectEqual(charged, 10_000_000, "proration lost or invented dollars")
        }

        test("the cap hit in a year is base plus that year's proration") {
            let deal = Contract(years: 2, baseSalaryByYear: [2_000_000, 3_000_000],
                                signingBonus: 4_000_000)
            expectEqual(deal.capHit(inYear: 0), 2_000_000 + 2_000_000)
            expectEqual(deal.capHit(inYear: 1), 3_000_000 + 2_000_000)
        }

        test("releasing a deal accelerates every unamortised bonus dollar into dead money") {
            // The prior build's attack: dead money erased by release. Every bonus dollar not yet
            // charged has to land somewhere, and the total charged over the life of a released
            // contract must equal what was paid.
            let deal = Contract(years: 4, baseSalaryByYear: Array(repeating: 1_000_000, count: 4),
                                signingBonus: 8_000_000)
            expectEqual(deal.deadMoney(ifReleasedBeforeYear: 0), 8_000_000)
            expectEqual(deal.deadMoney(ifReleasedBeforeYear: 2), 4_000_000)
            expectEqual(deal.deadMoney(ifReleasedBeforeYear: 4), 0)
        }

        test("charged plus dead money equals the whole bonus, at every release point") {
            let deal = Contract(years: 5, baseSalaryByYear: Array(repeating: 1_000_000, count: 5),
                                signingBonus: 7_000_003)
            for release in 0...5 {
                let charged = (0..<release).reduce(0) { $0 + deal.bonusProration(inYear: $1) }
                expectEqual(charged + deal.deadMoney(ifReleasedBeforeYear: release), 7_000_003,
                            "bonus dollars went missing at release year \(release)")
            }
        }

        test("total value is every base dollar plus the bonus") {
            let deal = Contract(years: 3, baseSalaryByYear: [1_000_000, 2_000_000, 3_000_000],
                                signingBonus: 500_000)
            expectEqual(deal.totalValue, 6_500_000)
        }

        test("a contract with no bonus has no dead money") {
            let deal = Contract(years: 2, baseSalaryByYear: [1_000_000, 1_000_000], signingBonus: 0)
            expectEqual(deal.deadMoney(ifReleasedBeforeYear: 0), 0)
            expectEqual(deal.capHit(inYear: 0), 1_000_000)
        }

        test("an absurd year count from a save clamps rather than crashing the process") {
            // years is unbounded above until it is bounded: Int.max asked for an unbounded array
            // allocation and took the process down with SIGTRAP on load.
            let huge = Contract(years: Int.max, baseSalaryByYear: [], signingBonus: 0)
            expectEqual(huge.years, ProRules.contractYearsRange.upperBound)
            expectEqual(huge.baseSalaryByYear.count, ProRules.contractYearsRange.upperBound)

            let decoded = try SaveEnvelope.decode(
                Contract.self,
                from: try SaveEnvelope.encode(Contract(years: 3,
                                                       baseSalaryByYear: [1, 2, 3],
                                                       signingBonus: 9))
            )
            expectEqual(decoded.years, 3)
        }

        test("a negative base salary cannot invent cap space") {
            // signingBonus was clamped and baseSalaryByYear was not, two lines apart. A negative
            // base gives a negative cap hit, which is 100 million dollars of cap room conjured out
            // of a hand-edited save.
            let deal = Contract(years: 2, baseSalaryByYear: [-100_000_000, 1_000_000],
                                signingBonus: 0)
            expectEqual(deal.capHit(inYear: 0), 0)
            expect(deal.totalValue >= 0, "a contract is worth a negative number of dollars")
        }

        test("a contract of no years carries no bonus") {
            // Otherwise the bonus is paid, charged against no year at all, and reported as dead
            // money at every release point forever — the same shape as a bonus that never
            // amortises, which is the laundering this file exists to prevent.
            let deal = Contract(years: 0, baseSalaryByYear: [], signingBonus: 30_000_000)
            expectEqual(deal.signingBonus, 0)
            expectEqual(deal.deadMoney(ifReleasedBeforeYear: 0), 0)
            expectEqual(deal.totalValue, 0)
        }
    }

    suite("Roster legality") {
        test("a college programme is legal at the limits and illegal past them") {
            expect(RosterLegality.college(players: 105, scholarships: 85).isLegal,
                   "a roster exactly at both limits was rejected")
            expect(!RosterLegality.college(players: 106, scholarships: 85).isLegal,
                   "an over-size roster was accepted")
            expect(!RosterLegality.college(players: 105, scholarships: 86).isLegal,
                   "an over-scholarship roster was accepted")
        }

        test("an over-limit college roster says which limit it broke") {
            let violations = RosterLegality.college(players: 120, scholarships: 90).violations
            expectEqual(violations.count, 2, "both limits were broken and only \(violations.count) reported")
        }

        test("a pro roster is legal at 53 and 16 and illegal past them") {
            expect(RosterLegality.pro(active: 53, practiceSquad: 16).isLegal,
                   "a roster exactly at both limits was rejected")
            expect(!RosterLegality.pro(active: 54, practiceSquad: 16).isLegal,
                   "an over-size active roster was accepted")
            expect(!RosterLegality.pro(active: 53, practiceSquad: 17).isLegal,
                   "an over-size practice squad was accepted")
        }
    }

    suite("Model round-trip") {
        test("a player survives the save envelope unchanged") {
            // Every model type is Codable because the save is one document. A type that round-trips
            // lossily here corrupts a career quietly, twenty seasons in.
            let player = Player(
                id: UUID(uuidString: "00000000-0000-4000-8000-0000000000FF")!,
                firstName: "Adrian",
                lastName: "Bellweather",
                position: .quarterback,
                age: 21,
                attributes: Attributes([.armStrength: Rating(88), .decision: Rating(74)]),
                potential: Rating(91),
                traits: [.workhorse],
                eligibility: Eligibility(),
                contract: nil
            )
            let restored = try SaveEnvelope.decode(Player.self, from: try SaveEnvelope.encode(player))
            expectEqual(restored, player)
        }

        test("a league survives the save envelope unchanged") {
            let league = League(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
                seed: 42,
                season: 3,
                week: 9,
                conferences: [
                    Conference(id: UUID(uuidString: "00000000-0000-4000-8000-000000000002")!,
                               name: "Northern Reach", tier: .college, memberIDs: [])
                ]
            )
            let restored = try SaveEnvelope.decode(League.self, from: try SaveEnvelope.encode(league))
            expectEqual(restored, league)
        }
    }
}
