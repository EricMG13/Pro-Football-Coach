import Foundation
import FootballSimCore

// Build-wide invariants, gathered in one place.
//
// `docs/03b-ARCHITECTURE.md` §1 requires three source scans, and the reason they live together is
// the lesson from `docs/AUDIT.md`: the previous build verified contrast rigorously in exactly the
// places its tests looked and failed everywhere else, because "the test's coverage boundary became
// the quality boundary". A scan buried in a feature suite is a scan nobody remembers to extend.

/// Package root, resolved from this file rather than from the working directory, because
/// `swift run` and Xcode disagree about what that is.
private func packageRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // Suites
        .deletingLastPathComponent()   // SimTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // package root
}

/// Every `.swift` file under `relativePath`, as (path relative to that directory, contents).
private func swiftSources(under relativePath: String) -> [(path: String, text: String)] {
    let root = packageRoot().appendingPathComponent(relativePath)
    let names = FileManager.default.enumerator(atPath: root.path)?
        .compactMap { $0 as? String }
        .filter { $0.hasSuffix(".swift") } ?? []
    return names.compactMap { name in
        guard let text = try? String(contentsOfFile: root.appendingPathComponent(name).path,
                                     encoding: .utf8) else { return nil }
        return (name, text)
    }
}

/// Lines of a file as (1-based number, text), with comment-only lines dropped.
///
/// Dropping comments is what lets these scans state their own rule in prose without tripping over
/// it — this file names `.hashValue` several times and must not report itself.
private func codeLines(_ text: String) -> [(number: Int, text: Substring)] {
    text.split(separator: "\n", omittingEmptySubsequences: false)
        .enumerated()
        .map { (number: $0.offset + 1, text: $0.element) }
        .filter { !$0.text.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
}

func runContractTests() {
    TestKit.suite("Contracts — engine/UI boundary") {

        // The simulation has to run headless: the calibration harness, the soak and every
        // determinism check are command-line runs with no UI process to host them. A single UI
        // import in the engine is enough to make the whole target unbuildable in that context, and
        // it is the kind of thing that arrives by autocomplete rather than by decision.
        TestKit.test("no engine source imports a UI framework") {
            let sources = swiftSources(under: "Sources/FootballSimCore")
            TestKit.expect(!sources.isEmpty, "found no engine sources to scan")

            var offenders: [String] = []
            for (path, text) in sources {
                for line in codeLines(text) {
                    let trimmed = line.text.trimmingCharacters(in: .whitespaces)
                    for framework in ["SwiftUI", "UIKit", "AppKit"] where trimmed == "import \(framework)" {
                        offenders.append("\(path):\(line.number) — \(framework)")
                    }
                }
            }
            TestKit.expect(
                offenders.isEmpty,
                "the engine must stay headless; these files import a UI framework: "
                    + offenders.joined(separator: ", ")
            )
        }
    }

    TestKit.suite("Contracts — determinism") {

        // Running a league twice inside one process cannot catch the worst kind of
        // non-determinism, because the thing that varies is fixed for the life of a process.
        // Swift salts its hash seed per launch, so a value derived from a hash is stable within a
        // run and worthless between runs. One use of it in the free-agent market was enough to make
        // every launch produce a different league from the same save seed, while every in-process
        // test passed. Reading the source is the only cheap guard.
        //
        // A copy of this scan currently also lives in DynastyTests; that one goes when P0 removes
        // the code it sits beside. This is the canonical home.
        TestKit.test("nothing in the engine seeds from a hash value") {
            let sources = swiftSources(under: "Sources/FootballSimCore")
            TestKit.expect(!sources.isEmpty, "found no engine sources to scan")

            var offenders: [String] = []
            for (path, text) in sources {
                for line in codeLines(text) where line.text.contains(".hashValue") {
                    offenders.append("\(path):\(line.number)")
                }
            }
            TestKit.expect(
                offenders.isEmpty,
                "hashValue is salted per process; these lines make the league unreproducible: "
                    + offenders.joined(separator: ", ")
            )
        }
    }

    TestKit.suite("Contracts — design tokens") {

        // `docs/AUDIT.md` systemic pattern 2: DESIGN.md already said "a literal in a view is a
        // defect", and the view layer accumulated 43 literal spacings, 25 literal radii and 9-10
        // hard-coded font sizes against that rule. A rule nothing enforces is a wish.
        //
        // This reports rather than asserts, on purpose. The view layer it scans is the one
        // `docs/04-UX-AND-DESIGN-SYSTEM.md` replaces wholesale, so failing here today would only
        // measure code already condemned. It becomes an assertion at P11, against the design system
        // that replaces it — and the baseline it prints now is what P11 is judged against.
        TestKit.test("design-token literal baseline is recorded") {
            let sources = swiftSources(under: "Sources/ProFootballCoachUI")
            TestKit.expect(!sources.isEmpty, "found no view sources to scan")

            // Deliberately narrow: the numeric argument forms that carry a design decision.
            // Catching every bare number would drown the signal in layout maths.
            let patterns: [(name: String, regex: String)] = [
                ("spacing",  #"spacing:\s*\d"#),
                ("padding",  #"\.padding\(\s*\d"#),
                ("radius",   #"cornerRadius:\s*\d"#),
                ("fontSize", #"\.system\(size:\s*\d"#),
            ]
            var counts: [String: Int] = [:]
            for (_, text) in sources {
                for line in codeLines(text) {
                    for (name, pattern) in patterns
                    where line.text.range(of: pattern, options: .regularExpression) != nil {
                        counts[name, default: 0] += 1
                    }
                }
            }
            let summary = patterns
                .map { "\($0.name)=\(counts[$0.name] ?? 0)" }
                .joined(separator: " ")
            FileHandle.standardError.write(
                Data("   token-literal baseline (\(sources.count) view files): \(summary)\n".utf8)
            )
            TestKit.expect(true, "baseline recorded")
        }
    }

    TestKit.suite("Seed derivation") {

        let league = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let home = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let away = UUID(uuidString: "FFFFFFFF-0000-1111-2222-333333333333")!

        TestKit.test("the same path always derives the same seed") {
            let first = SeedPath.fullPath(league: league, year: 2031, week: 4,
                                          home: home, away: away, drive: 6, snap: 2)
            let second = SeedPath.fullPath(league: league, year: 2031, week: 4,
                                           home: home, away: away, drive: 6, snap: 2)
            TestKit.expect(first == second, "identical paths produced different seeds")
        }

        // Every component must actually reach the leaf. A step that silently drops its input is the
        // defect this catches: the seeds would still look random, and two different weeks would
        // quietly share a stream.
        TestKit.test("changing any component changes the seed") {
            let base = SeedPath.fullPath(league: league, year: 2031, week: 4,
                                         home: home, away: away, drive: 6, snap: 2)
            let variants: [(String, UInt64)] = [
                ("year",   SeedPath.fullPath(league: league, year: 2032, week: 4,
                                             home: home, away: away, drive: 6, snap: 2)),
                ("week",   SeedPath.fullPath(league: league, year: 2031, week: 5,
                                             home: home, away: away, drive: 6, snap: 2)),
                ("drive",  SeedPath.fullPath(league: league, year: 2031, week: 4,
                                             home: home, away: away, drive: 7, snap: 2)),
                ("snap",   SeedPath.fullPath(league: league, year: 2031, week: 4,
                                             home: home, away: away, drive: 6, snap: 3)),
                ("league", SeedPath.fullPath(league: away, year: 2031, week: 4,
                                             home: home, away: away, drive: 6, snap: 2)),
            ]
            for (name, seed) in variants {
                TestKit.expect(seed != base, "changing \(name) did not change the derived seed")
            }
        }

        // Home advantage is a real term in the engine, so a fixture and its reverse must not share
        // a stream. Mixing the two identifiers in order is what buys this; mixing them
        // commutatively (XOR, addition) would not.
        TestKit.test("a fixture and its reverse derive different seeds") {
            let forward = SeedPath.game(1, home: home, away: away)
            let reverse = SeedPath.game(1, home: away, away: home)
            TestKit.expect(forward != reverse, "home and away were mixed commutatively")
        }

        // Sibling indices differing by 1 must not produce neighbouring streams. This is the
        // property that a naive `parent + index` derivation fails.
        TestKit.test("adjacent snap indices are uncorrelated") {
            var collisions = 0
            for index in 0..<256 {
                var a = SeededRandom(seed: SeedPath.snap(99, index: index))
                var b = SeededRandom(seed: SeedPath.snap(99, index: index + 1))
                if a.next() == b.next() { collisions += 1 }
            }
            TestKit.expect(collisions == 0, "\(collisions) adjacent snap pairs shared a first draw")
        }

        TestKit.test("negative indices are legal and distinct") {
            TestKit.expect(
                SeedPath.drive(7, index: -1) != SeedPath.drive(7, index: 1),
                "a negative index collided with its positive twin"
            )
        }
    }
}
