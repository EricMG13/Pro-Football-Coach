import Foundation
import FootballSimCore

// Pinned outputs of SeededRandom.derive. Changing the mixing function changes these, which is the
// point: a seeding change must be a deliberate edit here, not a silent drift. Regenerate only when
// the change is intended and no save exists that depends on the old stream.
private let GOLDEN_LEAGUE_0: UInt64 = 3_662_598_640_555_723_460
private let GOLDEN_SEASON_1: UInt64 = 1_738_821_789_517_853_511
private let GOLDEN_SNAP_42_17: UInt64 = 2_749_126_016_540_132_632

// The root of the hierarchy needs pinning too. `derive` is only ever as reproducible as the seed it
// starts from, and an unpinned `seed(from:)` can be replaced with system randomness without a single
// test noticing — which was true of this suite until it was tried.
private let GOLDEN_SEED_ONE: UInt64 = 3_372_039_570_709_087_602
private let GOLDEN_SEED_TWO: UInt64 = 6_619_274_789_208_811_879

private let ROOT_A = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
private let ROOT_B = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8")!

func runSeedDerivationTests() {
    suite("Seed derivation") {
        test("the same inputs always derive the same seed") {
            let a = SeededRandom.derive(from: 12345, scope: .week, ordinal: 3)
            let b = SeededRandom.derive(from: 12345, scope: .week, ordinal: 3)
            expectEqual(a, b, "derivation is not a pure function")
        }

        test("scope separates otherwise identical derivations") {
            // Week 3 and game 3 hang off the same parent with the same ordinal. Without the scope
            // tag in the mix they would collide, and a game would replay its week's stream.
            let week = SeededRandom.derive(from: 999, scope: .week, ordinal: 3)
            let game = SeededRandom.derive(from: 999, scope: .game, ordinal: 3)
            expect(week != game, "scope is not part of the mix: both derived \(week)")
        }

        test("ordinal separates siblings") {
            let first = SeededRandom.derive(from: 999, scope: .drive, ordinal: 1)
            let second = SeededRandom.derive(from: 999, scope: .drive, ordinal: 2)
            expect(first != second, "sibling ordinals collided at \(first)")
        }

        test("parent separates cousins") {
            let underA = SeededRandom.derive(from: 100, scope: .snap, ordinal: 7)
            let underB = SeededRandom.derive(from: 200, scope: .snap, ordinal: 7)
            expect(underA != underB, "different parents collided at \(underA)")
        }

        test("identifier derivation uses bytes, and matches across equal UUIDs") {
            let id = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8")!
            let same = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
            expectEqual(
                SeededRandom.derive(from: 5, scope: .game, identifier: id),
                SeededRandom.derive(from: 5, scope: .game, identifier: same),
                "equal UUIDs derived different seeds, so something case- or byte-sensitive is wrong"
            )
        }

        test("identifier derivation separates different identifiers") {
            let a = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
            let b = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
            expect(
                SeededRandom.derive(from: 5, scope: .game, identifier: a)
                    != SeededRandom.derive(from: 5, scope: .game, identifier: b),
                "two different identifiers derived the same seed"
            )
        }

        test("identifier and ordinal derivation do not alias each other") {
            // Both overloads mix parent and scope the same way and then diverge. If the ordinal
            // overload ever reduced to a 16-byte mix, an ordinal could collide with a UUID that
            // happens to share those bytes. Cheap to assert, expensive to discover.
            let id = UUID(uuidString: "00000000-0000-4000-8000-000000000000")!
            expect(
                SeededRandom.derive(from: 5, scope: .game, identifier: id)
                    != SeededRandom.derive(from: 5, scope: .game, ordinal: 0),
                "the identifier and ordinal overloads collided"
            )
        }

        test("a full six-level path is stable end to end") {
            // seed(from:) is called inside the closure, not hoisted out of it. Hoisted, both calls
            // close over one constant and the assertion holds for any implementation of the root
            // at all — a tautology wearing an end-to-end test's clothes.
            func path() -> UInt64 {
                var seed = SeededRandom.seed(from: ROOT_A)
                seed = SeededRandom.derive(from: seed, scope: .season, ordinal: 2)
                seed = SeededRandom.derive(from: seed, scope: .week, ordinal: 9)
                seed = SeededRandom.derive(from: seed, scope: .game, ordinal: 4)
                seed = SeededRandom.derive(from: seed, scope: .drive, ordinal: 11)
                seed = SeededRandom.derive(from: seed, scope: .snap, ordinal: 3)
                return seed
            }
            expectEqual(path(), path(), "the six-level path is not reproducible")
        }

        test("a negative ordinal is distinct from its positive twin") {
            // Ordinal is an Int and the mix reinterprets its bit pattern. A truncation to UInt32 or
            // a magnitude conversion would collapse these, which is the kind of thing that shows up
            // as a mysterious replay months later.
            expect(
                SeededRandom.derive(from: 7, scope: .drive, ordinal: -1)
                    != SeededRandom.derive(from: 7, scope: .drive, ordinal: 1),
                "ordinal -1 and 1 derived the same seed"
            )
        }

        // This is the cross-process assertion for the seeding layer, and it is why P0 needs no
        // subprocess harness. A literal in a source file cannot be salted per launch, so if the
        // mixing function ever changes — or ever picks up a hash-based input — these fail. P3 adds
        // the replay comparison once there is a play-by-play to hash.
        test("golden vectors pin the mixing function across processes and launches") {
            expectEqual(SeededRandom.derive(from: 0, scope: .league, ordinal: 0), GOLDEN_LEAGUE_0)
            expectEqual(SeededRandom.derive(from: 1, scope: .season, ordinal: 1), GOLDEN_SEASON_1)
            expectEqual(SeededRandom.derive(from: 42, scope: .snap, ordinal: 17), GOLDEN_SNAP_42_17)
        }

        test("golden vectors pin the root of the hierarchy too") {
            // Without these, seed(from:) can be swapped for UInt64.random and the whole suite stays
            // green: every other assertion here compares derive against derive, and derive is a
            // pure function of whatever root it is handed.
            expectEqual(SeededRandom.seed(from: ROOT_A), GOLDEN_SEED_ONE)
            expectEqual(SeededRandom.seed(from: ROOT_A, ROOT_B), GOLDEN_SEED_TWO)
        }

        test("the variadic root seed depends on identifier order") {
            expect(
                SeededRandom.seed(from: ROOT_A, ROOT_B) != SeededRandom.seed(from: ROOT_B, ROOT_A),
                "the multi-identifier root seed is order-insensitive, so two different leagues can "
                    + "share a root"
            )
        }

        test("every scope has a distinct raw value") {
            // Enumerated by construction: a scope added later without a unique tag fails here
            // rather than silently colliding with an existing one.
            let raws = Set(SeedScope.allCases.map(\.rawValue))
            expectEqual(raws.count, SeedScope.allCases.count, "two scopes share a raw value")
        }
    }
}
