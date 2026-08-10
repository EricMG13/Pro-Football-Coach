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

        test("every attribute the 03 matchup table names exists") {
            // 03 section 1.2 is the contract between 02's ratings model and the engine. Enumerated
            // by construction: this fails the day the engine reads an attribute the model lacks,
            // rather than the day someone remembers to check.
            for attribute in Attribute.allCases {
                expect(!attribute.label.isEmpty, "\(attribute) has no label")
            }
            let required: [Attribute] = [
                .passBlock, .runBlock, .strength, .awareness,
                .passRush, .finesse, .power, .motor,
                .routeRunning, .speed, .release, .hands,
                .coverage, .agility,
                .accuracyShort, .accuracyMid, .accuracyDeep, .armStrength, .decision, .poise,
                .schemeFit, .runDefence, .shed, .gapDiscipline,
                .vision, .elusiveness, .tackling, .pursuit,
                .legStrength, .kickAccuracy, .blockLeverage,
                .durability, .temperament, .workEthic, .clutch,
            ]
            for attribute in required {
                expect(Attribute.allCases.contains(attribute), "\(attribute) is missing")
            }
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
