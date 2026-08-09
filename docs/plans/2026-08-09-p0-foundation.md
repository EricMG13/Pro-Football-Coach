# P0 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development`
> (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip the repository to the four things `docs/PORT-LOG.md` justifies keeping, then build the
foundation every later phase inherits: the module skeleton, the hierarchical seeding contract, the
four source-scanning contract tests, and a save envelope whose version is readable without a full
parse.

**Architecture:** One SwiftPM package, two library targets and one executable test target.
`FootballSimCore` is pure Swift with zero UI imports; `ProFootballCoachUI` is SwiftUI only; `SimTests`
is an executable running a hand-rolled harness, because neither XCTest nor swift-testing ships
outside Xcode. The engine/UI boundary, the determinism rule and the design-token rule are enforced by
source-scanning tests rather than by convention — a rule nothing enforces is a wish.

**Tech Stack:** Swift 6.3.3 (`swiftLanguageModes: [.v5]`), SwiftPM, iOS 17 / macOS 14, XcodeGen for the
app shell. Zero third-party dependencies.

## Global Constraints

Copied verbatim from `CLAUDE.md` and `docs/03b-ARCHITECTURE.md`. Every task's requirements implicitly
include this section.

- **iOS 17+, Swift 5.10+, SwiftUI. iPhone-only, portrait-only. Offline. Zero third-party dependencies.**
- **Strict engine/UI separation.** `Sources/FootballSimCore/` contains zero `import SwiftUI`.
- **Determinism.** A given seed plus a given input state reproduces a match exactly, **across
  processes and app launches**. Seeds derive from identifier *bytes*, never from `hashValue`.
- **Ratings are 40–99 `Int`. Money is integer dollars (`Int`)** — no floating-point currency.
- **A design-token literal in a view is a defect.**
- **No emoji in code, UI copy, commits or docs.**
- **Rules constants live in a single rules module per tier.** Never inline a magic number.
- **Every collection that can grow across seasons has a stated bound.**
- **Conventional Commits.** One task, one commit.
- **Gates for this phase: G1 (build green), G2 (tests green), G4 (scope), G6 (determinism).**
  G1 and G2 are asserted by running them in the session that claims them — `./scripts/verify.sh` —
  never by citing a previous run.

## Starting state, measured 2026-08-09

Do not take these on trust; re-run `./scripts/verify.sh` before Task 1 and confirm.

| Fact | Value |
|---|---|
| Toolchain | Swift 6.3.3, Xcode 26.6, simulators available |
| `swift build` | green, 6.91 s |
| Suite | `299 tests, 18412 checks, all passed` |
| Swift files under `Sources/` | 71 |
| Swift files under `Tests/` | 17 |
| Arcade tests inside that suite | 90 (ArcadeTests 29, ArcadeFieldTests 48, ArcadeWatchTests 13) |

**The suite will shrink dramatically in Task 1. That is the point, and the numbers are recorded so
the shrink is a stated fact rather than a silence.**

## File Structure

What P0 leaves behind. Everything not on this list is deleted in Task 1.

| Path | Responsibility |
|---|---|
| `Package.swift` | Two library targets, one executable test target |
| `Sources/FootballSimCore/Support/SeededRandom.swift` | Ported. SplitMix64 + byte-derived seeding |
| `Sources/FootballSimCore/Support/SeedDerivation.swift` | **New.** The `03` §3 hierarchical seed path |
| `Sources/FootballSimCore/Support/CodingSupport.swift` | Ported. `UUID: CodingKeyRepresentable`, stable encoders |
| `Sources/FootballSimCore/Persistence/SaveEnvelope.swift` | **New.** Versioned envelope, header-readable version |
| `Sources/FootballSimCore/{Model,Rules,Engine,Abstracted,Generation,AI,Calibration}/` | **New.** Empty, `.gitkeep` only — the `03b` §1 skeleton |
| `Sources/ProFootballCoachUI/Placeholder.swift` | **New.** One trivial view. Keeps the target compiling and both view-facing scans non-vacuous. P11 deletes it |
| `Tests/SimTests/TestKit.swift` | Ported harness |
| `Tests/SimTests/main.swift` | Suite registration |
| `Tests/SimTests/Suites/SeededRandomTests.swift` | Kept as-is. Verified self-contained: it imports only Foundation and FootballSimCore and touches no deleted type |
| `Tests/SimTests/Suites/SeedDerivationTests.swift` | **New.** Including the golden vectors |
| `Tests/SimTests/Suites/ContractTests.swift` | **New.** The four source scans, comment-stripping, each self-tested |
| `Tests/SimTests/Suites/SaveEnvelopeTests.swift` | **New.** |
| `App/project.yml`, `App/ProFootballCoachApp.swift` | The thin shell |
| `scripts/verify.sh` | The gate runner |

---

### Task 1: Demolition

One commit, because a 90-file deletion split across several is unreadable. The build and the suite
must both be green at the end of it.

**Files:**
- Delete: everything under `Sources/` except `Support/SeededRandom.swift` and
  `Support/CodingSupport.swift`
- Delete: everything under `Tests/SimTests/Suites/` except `SeededRandomTests.swift`
- Create: `Sources/ProFootballCoachUI/Placeholder.swift`
- Modify: `Tests/SimTests/main.swift` (all registrations but one)
- Modify: `Package.swift:8-11` (the contradictory comment named in `PORT-LOG.md` §3)
- Modify: `docs/PORT-LOG.md` (write back the SHA, file list and counts)

**Interfaces:**
- Consumes: nothing.
- Produces: a package with `SeededRandom`, `CodingSupport` and `TestKit` and nothing else.
  `SeededRandom.seed(from:)` and the `JSONEncoder.stable()` / `JSONDecoder.stable()` pair are the
  only public API surviving into Task 3 and Task 5.

- [ ] **Step 1: Confirm the starting state rather than trusting this document**

```bash
./scripts/verify.sh
```

Expected: `swift build` PASS, then `299 tests, 18412 checks` and `all passed`, then
`2 passed, 0 failed`. If the counts differ, stop and update the table above before continuing —
Task 7 compares against them.

- [ ] **Step 2: Record the pre-deletion file list**

`PORT-LOG.md` owes a list of what was removed. Capture it before it is gone.

```bash
git ls-files Sources Tests > /tmp/pfc-p0-before.txt
wc -l < /tmp/pfc-p0-before.txt
```

Expected: 88 (71 under `Sources/`, 17 under `Tests/`).

- [ ] **Step 3: Delete the discarded engine and UI**

Everything here is dispositioned in `docs/PORT-LOG.md` under "Discarded — with the reason".

`Sources/FootballSimCore/Support/` holds **three** files, not two: `SeededRandom.swift` and
`CodingSupport.swift` are ported, and `FootballSimCore.swift` is a `version = "0.1.0"` marker that
nothing in the tree reads. It is not on the ported list, so it goes — P0's rule is *remove everything
not named in `PORT-LOG.md`*, and an unread constant is exactly the kind of thing that survives by
inattention.

```bash
git rm -r -q Sources/FootballSimCore/Arcade \
             Sources/FootballSimCore/Engine \
             Sources/FootballSimCore/Model \
             Sources/FootballSimCore/Rules \
             Sources/FootballSimCore/Generation \
             Sources/ProFootballCoachUI
git rm -q Sources/FootballSimCore/Support/FootballSimCore.swift
git ls-files Sources
```

Expected output: exactly two paths —
`Sources/FootballSimCore/Support/CodingSupport.swift` and
`Sources/FootballSimCore/Support/SeededRandom.swift`.

- [ ] **Step 4: Delete the test suites that covered deleted code**

`Tests/` tracks 17 files: 14 suites, plus `TestKit.swift`, `main.swift` and `TestFixtures.swift`.
Thirteen suites go; `SeededRandomTests.swift` stays. `TestFixtures.swift` goes with them — it
fixtures a model that no longer exists.

```bash
cd Tests/SimTests/Suites && git rm -q $(ls *.swift | grep -v '^SeededRandomTests.swift$') && cd -
git rm -q Tests/SimTests/TestFixtures.swift
git ls-files Tests
```

Expected: exactly three paths — `Tests/SimTests/Suites/SeededRandomTests.swift`,
`Tests/SimTests/TestKit.swift`, `Tests/SimTests/main.swift`.

- [ ] **Step 5: Reduce `main.swift` to what still exists**

Replace the whole file with:

```swift
// Test entry point. Add each new suite's runner here.
runSeededRandomTests()

TestKit.finish()
```

- [ ] **Step 6: Add the placeholder view so the UI target still has sources**

Create `Sources/ProFootballCoachUI/Placeholder.swift`:

```swift
import SwiftUI

// ponytail: this view exists only so the ProFootballCoachUI target has a source file and keeps
// compiling, which in turn keeps ContractTests' engine-boundary and design-token scans pointed at a
// real directory instead of passing vacuously. P11 builds the design system and deletes it.
struct Placeholder: View {
    var body: some View {
        Text("Pro Football Coach")
    }
}
```

Note there is no design-token literal in it — no `padding`, no `cornerRadius`, no `font(.system(size:))`.
That is deliberate: Task 4's scan runs against this file.

- [ ] **Step 7: Fix the contradictory comment in `Package.swift`**

`docs/PORT-LOG.md` §3 names this defect: the header says tests use swift-testing, the target comment
says swift-testing needs full Xcode. The second is correct. Replace lines 5–11 (the block beginning
`// One package, two library targets:`) so the header reads:

```swift
// One package, two library targets:
//   FootballSimCore    — pure simulation logic, no UI imports, fully unit-tested
//   ProFootballCoachUI — SwiftUI feature layer (type-checks on macOS so it stays verified
//                        even when building without full Xcode; the iOS app target is a
//                        thin @main shell in App/ generated from project.yml)
//
// Tests run through a hand-rolled harness (Tests/SimTests/TestKit.swift) as an executable
// target. Neither XCTest nor swift-testing ships with the Swift Command Line Tools — both
// live inside Xcode — so this is what lets the suite run from the command line.
```

- [ ] **Step 8: Build and run the surviving suite**

```bash
./scripts/verify.sh
```

Expected: build PASS. Test output is a much smaller count — roughly `12 tests`, all passed. Record
the exact numbers; Step 10 writes them into `PORT-LOG.md`.

If the build fails, the cause is almost certainly a suite file still referencing a deleted type.
Re-check Step 4's output against `git ls-files Tests`.

- [ ] **Step 9: Commit the demolition**

```bash
git add -A Sources Tests Package.swift
git commit -m "refactor: strip the tree to what the port log justifies keeping

Removes 83 of 88 tracked source and test files. What survives is exactly the
ported list in docs/PORT-LOG.md — SeededRandom, CodingSupport, the TestKit
harness and its own suite — plus a placeholder view that keeps the UI target
compiling so the contract scans in the next task have a real directory to walk.

The suite shrinks from 299 tests to the ported surface. That is the phase
working, not a regression, and the counts are written into PORT-LOG.md in the
next commit so the shrink is stated rather than silent.

Arcade/ is deleted rather than quarantined per the owner decision recorded in
PORT-LOG.md. It compiles and its 90 tests pass; the discard rests on the
mission constraint alone. The SHA of this commit is its retrieval address.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 10: Write the retrieval address back into `PORT-LOG.md`**

`docs/PORT-LOG.md` §"The deletion commit must leave a retrieval address" owes three things. Get the
SHA:

```bash
git rev-parse --short HEAD
```

Then append to that section of `docs/PORT-LOG.md`, filling in the real values:

```markdown
**Done in P0.**

- **Deletion commit:** `<sha>` — `git show <sha>` retrieves any deleted file;
  `git show <sha>^:Sources/FootballSimCore/Arcade/SnapKernel.swift` retrieves one directly.
- **Files removed:** 83 of 88 (69 of 71 under `Sources/`, 14 of 17 under `Tests/`). Full list:
  `git show --stat <sha>`.
- **Suite before:** 299 tests, 18412 checks. **After:** <N> tests, <M> checks. The difference is
  the 90 arcade tests plus every suite covering the discarded model, engine, generation and UI.
```

- [ ] **Step 11: Commit the port log update**

```bash
git add docs/PORT-LOG.md
git commit -m "docs: record the deletion SHA, file count and suite delta

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Module skeleton and the two platform declarations

**Files:**
- Create: `Sources/FootballSimCore/{Model,Rules/CollegeRules,Rules/ProRules,Engine,Abstracted,Generation,AI,Calibration,Persistence}/.gitkeep`
- Modify: `App/project.yml:24` (`TARGETED_DEVICE_FAMILY`) and the stale arcade comment above it

**Interfaces:**
- Consumes: nothing.
- Produces: the directory tree `docs/03b-ARCHITECTURE.md` §1 specifies, which Task 4's scans walk and
  every later phase fills.

- [ ] **Step 1: Create the skeleton**

`docs/03b-ARCHITECTURE.md` §1 names these directories. They are created now, empty, so the layout is
a fact in the tree rather than a diagram in a document — a later phase that invents its own directory
is then a visible deviation.

```bash
cd Sources/FootballSimCore
for d in Model Rules/CollegeRules Rules/ProRules Engine Abstracted Generation AI Calibration Persistence; do
  mkdir -p "$d" && touch "$d/.gitkeep"
done
cd -
find Sources/FootballSimCore -name .gitkeep | sort
```

Expected: nine paths, matching `03b` §1's tree.

- [ ] **Step 2: Fix the iPad declaration**

`CLAUDE.md` says **iPhone-only**. `App/project.yml` currently says `TARGETED_DEVICE_FAMILY: "1,2"`,
which is iPhone **and iPad**. In `App/project.yml`, change:

```yaml
        TARGETED_DEVICE_FAMILY: "1,2"
```

to:

```yaml
        # iPhone only (family 1). Family 2 is iPad, which CLAUDE.md excludes; it was declared
        # here against that constraint.
        TARGETED_DEVICE_FAMILY: "1"
```

- [ ] **Step 3: Correct the stale portrait comment**

The comment above `INFOPLIST_KEY_UISupportedInterfaceOrientations` justifies portrait by reference to
the arcade mode, which Task 1 deleted. Replace the three comment lines with:

```yaml
        # Portrait only. The audit's landscape findings all traced back to this one line: every
        # screen was rotatable and two of them lost their controls off the bottom edge when they
        # were. The match view is a vertical, one-thumb surface by design (04 section 5.2), so
        # nothing in the app wants the other orientation.
```

- [ ] **Step 4: Verify nothing broke**

```bash
./scripts/verify.sh
```

Expected: build PASS, suite unchanged from Task 1 Step 8, `2 passed, 0 failed`.

`project.yml` is not compiled by SwiftPM, so this step is confirming the `.gitkeep` files did not
disturb the targets — SwiftPM ignores non-Swift files, and an all-`.gitkeep` directory contributes no
sources.

- [ ] **Step 5: Commit**

```bash
git add -A Sources App/project.yml
git commit -m "feat: the 03b module skeleton, and iPhone-only where it is declared

Creates the nine engine directories 03b section 1 names, empty, so the layout
is a fact in the tree rather than a diagram in a document.

Also fixes two things in App/project.yml. TARGETED_DEVICE_FAMILY was 1,2 —
iPhone and iPad — against CLAUDE.md's iPhone-only constraint. And the comment
justifying portrait pointed at the arcade mode, which no longer exists; it now
points at 04 section 5.2.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: The hierarchical seeding contract

`docs/03-MATCH-ENGINE.md` §3.5 requires seed derivation to be hierarchical and stable:
`leagueSeed -> seasonSeed -> weekSeed -> gameSeed -> driveSeed -> snapSeed`, each derived by a
documented mixing function over the parent seed and the identifier bytes.

**Files:**
- Create: `Sources/FootballSimCore/Support/SeedDerivation.swift`
- Create: `Tests/SimTests/Suites/SeedDerivationTests.swift`
- Modify: `Tests/SimTests/main.swift`

**Interfaces:**
- Consumes: `SeededRandom.seed(from:)` — the FNV-1a-over-UUID-bytes function already in
  `Sources/FootballSimCore/Support/SeededRandom.swift`.
- Produces, for every later phase:
  - `public enum SeedScope: UInt64, Sendable, CaseIterable` with cases
    `league = 1, season = 2, week = 3, game = 4, drive = 5, snap = 6`
  - `public static func SeededRandom.derive(from parent: UInt64, scope: SeedScope, ordinal: Int) -> UInt64`
  - `public static func SeededRandom.derive(from parent: UInt64, scope: SeedScope, identifier: UUID) -> UInt64`

- [ ] **Step 1: Write the failing tests**

Create `Tests/SimTests/Suites/SeedDerivationTests.swift`:

```swift
import Foundation
import FootballSimCore

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

        test("a full six-level path is stable end to end") {
            let league = SeededRandom.seed(from: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!)
            func path() -> UInt64 {
                var seed = league
                seed = SeededRandom.derive(from: seed, scope: .season, ordinal: 2)
                seed = SeededRandom.derive(from: seed, scope: .week, ordinal: 9)
                seed = SeededRandom.derive(from: seed, scope: .game, ordinal: 4)
                seed = SeededRandom.derive(from: seed, scope: .drive, ordinal: 11)
                seed = SeededRandom.derive(from: seed, scope: .snap, ordinal: 3)
                return seed
            }
            expectEqual(path(), path(), "the six-level path is not reproducible")
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

        test("every scope has a distinct raw value") {
            // Enumerated by construction: a scope added later without a unique tag fails here
            // rather than silently colliding with an existing one.
            let raws = Set(SeedScope.allCases.map(\.rawValue))
            expectEqual(raws.count, SeedScope.allCases.count, "two scopes share a raw value")
        }
    }
}
```

- [ ] **Step 2: Register the suite**

In `Tests/SimTests/main.swift`, add above `TestKit.finish()`:

```swift
runSeedDerivationTests()
```

- [ ] **Step 3: Run to verify it fails**

```bash
swift build 2>&1 | grep -E ': error:' | head -5
```

Expected: FAIL, with errors naming `SeedScope`, `derive`, `GOLDEN_LEAGUE_0`,
`GOLDEN_SEASON_1`, `GOLDEN_SNAP_42_17` as unresolved.

- [ ] **Step 4: Write the implementation**

Create `Sources/FootballSimCore/Support/SeedDerivation.swift`:

```swift
import Foundation

/// Where a derived seed sits in the hierarchy `03-MATCH-ENGINE.md` section 3.5 specifies:
/// league -> season -> week -> game -> drive -> snap.
///
/// The raw value is mixed into the derivation, so a week and a game with the same ordinal under the
/// same parent get different streams. Without it, a game would replay its week's numbers.
public enum SeedScope: UInt64, Sendable, CaseIterable {
    case league = 1
    case season = 2
    case week = 3
    case game = 4
    case drive = 5
    case snap = 6
}

public extension SeededRandom {
    /// Derives a child seed from a parent seed, a scope tag and a sibling ordinal.
    ///
    /// FNV-1a over the little-endian bytes of parent, scope and ordinal, in that order — the same
    /// mixing function and the same constants as `seed(from:)`, so the whole project has one
    /// documented way of turning bytes into a seed. FNV-1a is not a cryptographic hash and does not
    /// need to be: the requirement is reproducibility across processes and good separation between
    /// siblings, and salting is exactly what must not happen here.
    static func derive(from parent: UInt64, scope: SeedScope, ordinal: Int) -> UInt64 {
        var value = fnvOffsetBasis
        value = mix(value, bytesOf: parent)
        value = mix(value, bytesOf: scope.rawValue)
        value = mix(value, bytesOf: UInt64(bitPattern: Int64(ordinal)))
        return value
    }

    /// Derives a child seed from an identifier rather than an ordinal.
    ///
    /// Uses the UUID's raw bytes. Never `hashValue`, which Swift salts per launch — the bug that
    /// made one save produce a different league every app start.
    static func derive(from parent: UInt64, scope: SeedScope, identifier: UUID) -> UInt64 {
        var value = fnvOffsetBasis
        value = mix(value, bytesOf: parent)
        value = mix(value, bytesOf: scope.rawValue)
        withUnsafeBytes(of: identifier.uuid) { raw in
            for byte in raw { value = (value ^ UInt64(byte)) &* fnvPrime }
        }
        return value
    }

    private static var fnvOffsetBasis: UInt64 { 0xCBF2_9CE4_8422_2325 }
    private static var fnvPrime: UInt64 { 0x0000_0100_0000_01B3 }

    private static func mix(_ accumulator: UInt64, bytesOf word: UInt64) -> UInt64 {
        var value = accumulator
        withUnsafeBytes(of: word.littleEndian) { raw in
            for byte in raw { value = (value ^ UInt64(byte)) &* fnvPrime }
        }
        return value
    }
}
```

- [ ] **Step 5: Generate the golden vectors, then pin them**

The golden values cannot be invented — they are whatever the function above produces. Print them
once, read them off, and hard-code them.

Temporarily add to the top of `runSeedDerivationTests()`:

```swift
        print("GOLDEN_LEAGUE_0   = \(SeededRandom.derive(from: 0, scope: .league, ordinal: 0))")
        print("GOLDEN_SEASON_1   = \(SeededRandom.derive(from: 1, scope: .season, ordinal: 1))")
        print("GOLDEN_SNAP_42_17 = \(SeededRandom.derive(from: 42, scope: .snap, ordinal: 17))")
```

Comment out the golden-vector test, run `swift run -c release SimTests`, copy the three printed
values, then **delete the three print lines**, uncomment the test, and add the constants at the top
of the test file:

```swift
// Pinned outputs of SeededRandom.derive. Changing the mixing function changes these, which is the
// point: a seeding change must be a deliberate edit here, not a silent drift. Regenerate only when
// the change is intended and no save exists that depends on the old stream.
private let GOLDEN_LEAGUE_0: UInt64 = <printed value>
private let GOLDEN_SEASON_1: UInt64 = <printed value>
private let GOLDEN_SNAP_42_17: UInt64 = <printed value>
```

- [ ] **Step 6: Run the tests to verify they pass**

```bash
./scripts/verify.sh
```

Expected: build PASS, all seed-derivation tests passing, `2 passed, 0 failed`.

- [ ] **Step 7: Confirm no print statements survived**

```bash
grep -n "print(" Tests/SimTests/Suites/SeedDerivationTests.swift
```

Expected: no output.

- [ ] **Step 8: Commit**

```bash
git add Sources/FootballSimCore/Support/SeedDerivation.swift \
        Tests/SimTests/Suites/SeedDerivationTests.swift Tests/SimTests/main.swift
git commit -m "feat: the hierarchical seeding contract from 03 section 3.5

league -> season -> week -> game -> drive -> snap, each derived by FNV-1a over
the little-endian bytes of parent, scope tag and ordinal, using the same
constants as the existing seed(from:). The scope tag is what stops a game
replaying its week's stream when both hang off the same parent at the same
ordinal.

Golden vectors pin the mixing function. A literal in a source file cannot be
salted per launch, so they are the cross-process assertion for the seeding
layer and are why P0 needs no subprocess harness. P3 adds the replay
comparison once there is a play-by-play to hash.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: The contract suite — four source scans

`docs/03b-ARCHITECTURE.md` §1: the boundary is enforced by test, not by convention. `PORT-LOG.md` §4
says to port the existing `hashValue` scan as the template and gather them in one place, because a
build-wide invariant buried in `DynastyTests.swift` was the wrong home.

**Port the idea, not the implementation.** The existing scan has two defects, both of which shipped
green against real violations, and both of which this task must not inherit (`03` §3.5):

1. It matches `line.contains(".hashValue") && !line.contains("//")` — so **any offending line with a
   trailing comment is silently exempt.** The scan below strips the comment portion instead.
2. **It never looks for `UUID()` at all**, which is why five real determinism leaks survived a green
   suite — a call-site `PlayEvent(id: UUID(), ...)` plus four default-valued engine initialisers.
   Hence the fourth scan.

**Files:**
- Create: `Tests/SimTests/Suites/ContractTests.swift`
- Modify: `Tests/SimTests/main.swift`

**Interfaces:**
- Consumes: nothing from earlier tasks. Walks the filesystem.
- Produces: `runContractTests()`. No API other phases call — the value is the failing build.

- [ ] **Step 1: Write the failing tests**

Create `Tests/SimTests/Suites/ContractTests.swift`:

```swift
import Foundation

// The three build-wide invariants from 03b section 1, in one place because that is what they are:
// properties of the whole tree, not of any suite's subject.
//
// Each scan enumerates its file set by walking a directory rather than from a hand-written list.
// AUDIT.md's lesson is that "the test's coverage boundary became the quality boundary" — a scan over
// named files covers the files someone remembered, which is the defect, not the coverage.

private func swiftFiles(under relativePath: String) -> [(path: String, text: String)] {
    let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // Suites
        .deletingLastPathComponent()   // SimTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // package root
        .appendingPathComponent(relativePath)
    let names = FileManager.default.enumerator(atPath: root.path)?
        .compactMap { $0 as? String }
        .filter { $0.hasSuffix(".swift") } ?? []
    return names.compactMap { name in
        guard let text = try? String(contentsOfFile: root.appendingPathComponent(name).path,
                                     encoding: .utf8) else { return nil }
        return (path: "\(relativePath)/\(name)", text: text)
    }
}

/// Every line whose *code* matches `predicate`, as "path:line".
///
/// The comment portion is stripped before the predicate runs, rather than the whole line being
/// skipped when it contains "//". The prior build's scan did the latter, so `foo.hashValue // ok`
/// was silently exempt — a scan you can disable with a trailing comment is not a gate.
///
/// ponytail: naive "//" split, so a "//" inside a string literal truncates the line early. Harmless
/// for these four patterns — none of them can appear in a URL or path string — and the failure mode
/// is a false negative on a line no real offender occupies. Revisit only if a pattern ever needs to
/// match inside string content.
private func offendingLines(
    in files: [(path: String, text: String)],
    where predicate: (String) -> Bool
) -> [String] {
    var offenders: [String] = []
    for file in files {
        for (index, line) in file.text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let code = String(line).components(separatedBy: "//").first ?? ""
            guard !code.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            if predicate(code) { offenders.append("\(file.path):\(index + 1)") }
        }
    }
    return offenders
}

func runContractTests() {
    suite("Contracts") {
        test("the engine imports no UI framework") {
            let engine = swiftFiles(under: "Sources/FootballSimCore")
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: engine) { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.hasPrefix("import SwiftUI")
                    || trimmed.hasPrefix("import UIKit")
                    || trimmed.hasPrefix("import AppKit")
            }
            expect(
                offenders.isEmpty,
                "the engine must contain zero UI imports (03b section 1): "
                    + offenders.joined(separator: ", ")
            )
        }

        test("no engine code seeds anything from a hash value") {
            // Running a league twice inside one process cannot catch the worst non-determinism,
            // because the thing that varies — Swift's hash seed — is fixed for the life of a
            // process. UUID.hashValue looks like a stable identifier and is not, and one use of it
            // in the free-agent market was enough to make every launch produce a different league
            // from the same save seed. Reading the source is the only cheap guard.
            let engine = swiftFiles(under: "Sources/FootballSimCore")
            expect(!engine.isEmpty, "found no engine sources to scan — the scan would pass vacuously")
            let offenders = offendingLines(in: engine) { $0.contains(".hashValue") }
            expect(
                offenders.isEmpty,
                "hashValue is salted per process; these lines make the league unreproducible: "
                    + offenders.joined(separator: ", ")
            )
        }

        test("the engine mints no ambient identity or timestamp") {
            // 03 section 3.4 forbids ambient randomness; nothing enforced it, and clause 3 looks for
            // the wrong thing. The prior build's determinism leak was not a hashValue at all: it was
            // PlayEvent(id: UUID(), ...) at GameSimulator.swift:884, plus default-valued
            // id: UUID = UUID() on four engine initialisers. Five offenders, suite green, because
            // no scan looked. The determinism tests could not see it either — they compare scores
            // and stats, not identities.
            //
            // Model/ is exempt by design (03 section 3.5): a scan cannot tell a default parameter
            // from a call, and twelve of the prior build's thirteen such sites were legitimate. The
            // guarantee is upheld on the other side — engine construction passes rng.uuid().
            let engineRoots = ["Engine", "Generation", "AI", "Abstracted"]
            let engine = swiftFiles(under: "Sources/FootballSimCore")
                .filter { file in engineRoots.contains { file.path.contains("/\($0)/") } }
            // P0 has no engine directories with sources yet, so this scan has nothing to walk. That
            // is stated rather than hidden: the assertion below turns real the moment P3 adds a file
            // under Engine/, and it fails loudly if the roots are ever renamed out from under it.
            let rootsExist = engineRoots.allSatisfy { name in
                FileManager.default.fileExists(atPath: URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent().deletingLastPathComponent()
                    .deletingLastPathComponent().deletingLastPathComponent()
                    .appendingPathComponent("Sources/FootballSimCore/\(name)").path)
            }
            expect(rootsExist, "an engine directory named in 03b section 1 is missing; the scan "
                             + "would silently cover nothing")
            let offenders = offendingLines(in: engine) { line in
                line.contains("UUID()") || line.contains("Date()")
            }
            expect(
                offenders.isEmpty,
                "identities come from rng.uuid() and time from the simulated calendar (03 "
                    + "section 3.5): " + offenders.joined(separator: ", ")
            )
        }

        test("no view contains a design-token literal") {
            // DESIGN.md wrote this rule down and the prior build accumulated 43 literal spacings,
            // 25 literal radii and 9 hard-coded font sizes against it. A rule nothing enforces is a
            // wish. P11 extends the pattern set as the design system grows; these four are the ones
            // the audit actually counted.
            let views = swiftFiles(under: "Sources/ProFootballCoachUI")
            expect(!views.isEmpty, "found no view sources to scan — the scan would pass vacuously")
            let patterns = [
                ".padding(",
                ".cornerRadius(",
                ".font(.system(size:",
                "spacing: ",
            ]
            let offenders = offendingLines(in: views) { line in
                patterns.contains { marker in
                    guard let range = line.range(of: marker) else { return false }
                    // A literal is a digit or a decimal point immediately after the marker.
                    let rest = line[range.upperBound...].drop(while: { $0 == " " })
                    return rest.first.map { $0.isNumber || $0 == "." } ?? false
                }
            }
            expect(
                offenders.isEmpty,
                "a design-token literal in a view is a defect (04 section 1.1): "
                    + offenders.joined(separator: ", ")
            )
        }
    }
}
```

- [ ] **Step 2: Register the suite**

In `Tests/SimTests/main.swift`, add above `TestKit.finish()`:

```swift
runContractTests()
```

- [ ] **Step 3: Run to verify it fails**

```bash
swift build 2>&1 | grep -E ': error:' | head -5
```

Expected: FAIL, `cannot find 'runContractTests' in scope` resolves once the file is added — so
instead confirm the *tests* would catch a violation before trusting them. Temporarily add to
`Sources/FootballSimCore/Support/SeedDerivation.swift`, at the top:

```swift
import SwiftUI
```

Then:

```bash
swift run -c release SimTests 2>&1 | tail -20
```

Expected: FAIL, naming `Sources/FootballSimCore/Support/SeedDerivation.swift:N` in the UI-import
scan. **This step is the one that proves the scan works** — a scan that has never failed is not
known to be a scan.

- [ ] **Step 4: Remove the deliberate violation and confirm green**

Delete the `import SwiftUI` line, then:

```bash
./scripts/verify.sh
```

Expected: build PASS, all three contract tests passing, `2 passed, 0 failed`.

- [ ] **Step 5: Prove the other three scans the same way**

Repeat Step 3's method three more times, one at a time, reverting each before the next. **A scan that
has never failed is not known to be a scan**, and two of these exist specifically because the prior
build's version shipped green against real violations.

1. **hashValue.** Add `let x = someUUID.hashValue` inside a function in `SeedDerivation.swift`.
   Expect a failure naming that line. Revert.
2. **hashValue with a trailing comment** — the defect being fixed. Add
   `let x = someUUID.hashValue // deliberate` and expect it to fail **anyway**. The prior build's
   scan passed on exactly this. If it passes here, `offendingLines` is not stripping comments.
   Revert.
3. **Ambient identity.** Create `Sources/FootballSimCore/Engine/Probe.swift` containing
   `let leak = UUID()` inside a function. Expect a failure naming it. Delete the file.
4. **Design token.** Add `.padding(16)` to the `Text` in `Placeholder.swift`. Expect a failure
   naming that line. Revert.

After all four reverts, run `./scripts/verify.sh` and expect green.

**Step 3 plus this step are the point of the task.** Four scans that have each been watched failing
are a gate; four scans that have only ever passed are a green light.

- [ ] **Step 6: Commit**

```bash
git add Tests/SimTests/Suites/ContractTests.swift Tests/SimTests/main.swift
git commit -m "test: the four build-wide source scans, in one contract suite

No UI import in the engine, no hashValue, no ambient UUID()/Date() in the
engine, no design-token literal in a view. Gathered from the scan that was
buried in DynastyTests, which was the wrong home for a property of the whole
tree.

The idea is ported; the implementation is not. The prior scan had two defects
that each shipped green against real violations. It matched
line.contains(\".hashValue\") && !line.contains(\"//\"), so a trailing comment
disabled it. And it never looked for UUID() at all, which is how five real
determinism leaks survived a green suite: a call-site PlayEvent(id: UUID(), ...)
plus four default-valued engine initialisers. The determinism tests could not
see them either, because they compare scores and stats, not identities.

So this version strips the comment portion rather than skipping the line, and
adds the ambient-identity scan. Model/ stays exempt by design: a scan cannot
tell a default parameter from a call, and the guarantee is upheld on the other
side, where engine construction passes rng.uuid() explicitly.

Each scan enumerates its file set by walking a directory and asserts the set is
non-empty, so none can pass vacuously. All four were verified by introducing a
violation and watching them fail before reverting — including the trailing
comment case specifically.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: The save envelope

`docs/03b-ARCHITECTURE.md` §4: `schemaVersion` on the envelope, readable **without parsing the whole
file**. A newer-version save is refused with a plain message, never partially opened.

**Files:**
- Create: `Sources/FootballSimCore/Persistence/SaveEnvelope.swift`
- Create: `Tests/SimTests/Suites/SaveEnvelopeTests.swift`
- Modify: `Tests/SimTests/main.swift`
- Delete: `Sources/FootballSimCore/Persistence/.gitkeep`

**Interfaces:**
- Consumes: `JSONEncoder.stable()` / `JSONDecoder.stable()` from `CodingSupport.swift`.
- Produces, for the phase that adds real persistence:
  - `public struct SaveEnvelope: Sendable` with `public static let currentSchemaVersion: UInt32`
  - `public static func SaveEnvelope.encode<T: Encodable>(_ payload: T) throws -> Data`
  - `public static func SaveEnvelope.schemaVersion(ofHeader header: Data) throws -> UInt32`
  - `public static func SaveEnvelope.decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T`
  - `public static let SaveEnvelope.headerLength: Int` (16)
  - `public enum SaveEnvelopeError: Error, Equatable` with `notASaveFile`, `truncatedHeader`,
    `futureVersion(found: UInt32, supported: UInt32)`

- [ ] **Step 1: Write the failing tests**

Create `Tests/SimTests/Suites/SaveEnvelopeTests.swift`:

```swift
import Foundation
import FootballSimCore

private struct Payload: Codable, Equatable {
    let league: UUID
    let seasons: Int
}

func runSaveEnvelopeTests() {
    suite("Save envelope") {
        let payload = Payload(league: UUID(uuidString: "00000000-0000-4000-8000-0000000000AA")!,
                              seasons: 3)

        test("a payload round-trips") {
            let data = try SaveEnvelope.encode(payload)
            let restored = try SaveEnvelope.decode(Payload.self, from: data)
            expectEqual(restored, payload)
        }

        test("the version is readable from the header alone") {
            // This is the requirement 03b section 4 states: readable WITHOUT parsing the whole file.
            // Handing the reader only the first 16 bytes is how the test proves it, because a
            // reader that needed the body would throw on a truncated one.
            let data = try SaveEnvelope.encode(payload)
            let header = data.prefix(SaveEnvelope.headerLength)
            expectEqual(header.count, 16, "header should be a fixed 16 bytes")
            expectEqual(try SaveEnvelope.schemaVersion(ofHeader: Data(header)),
                        SaveEnvelope.currentSchemaVersion)
        }

        test("a file that is not a save is refused by magic, not by a decode failure") {
            let junk = Data("this is not a save file at all, it is prose".utf8)
            do {
                _ = try SaveEnvelope.schemaVersion(ofHeader: junk)
                expect(false, "junk was accepted as a save header")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .notASaveFile)
            }
        }

        test("a truncated header is refused rather than read past") {
            let data = try SaveEnvelope.encode(payload)
            do {
                _ = try SaveEnvelope.schemaVersion(ofHeader: data.prefix(6))
                expect(false, "a 6-byte header was accepted")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .truncatedHeader)
            }
        }

        test("a save from a future version is refused, never partially opened") {
            var data = try SaveEnvelope.encode(payload)
            let future = SaveEnvelope.currentSchemaVersion + 1
            withUnsafeBytes(of: future.littleEndian) { raw in
                for (offset, byte) in raw.enumerated() { data[4 + offset] = byte }
            }
            do {
                _ = try SaveEnvelope.decode(Payload.self, from: data)
                expect(false, "a future-version save was opened")
            } catch let error as SaveEnvelopeError {
                expectEqual(error, .futureVersion(found: future,
                                                  supported: SaveEnvelope.currentSchemaVersion))
            }
        }

        test("encoding is byte-stable across calls") {
            // CodingSupport exists so [UUID: ...] maps encode in a stable order. If that regresses,
            // no byte-level determinism test downstream can hold, so it is asserted here at the
            // layer that depends on it.
            let first = try SaveEnvelope.encode(payload)
            let second = try SaveEnvelope.encode(payload)
            expectEqual(first, second, "the same payload produced two different byte sequences")
        }

        test("the reserved header bytes are zero, so a later flag cannot read as set") {
            let data = try SaveEnvelope.encode(payload)
            let reserved = Array(data[9..<16])
            expectEqual(reserved, Array(repeating: UInt8(0), count: 7))
        }
    }
}
```

- [ ] **Step 2: Register the suite**

In `Tests/SimTests/main.swift`, add above `TestKit.finish()`:

```swift
runSaveEnvelopeTests()
```

- [ ] **Step 3: Run to verify it fails**

```bash
swift build 2>&1 | grep -E ': error:' | head -5
```

Expected: FAIL, `cannot find 'SaveEnvelope' in scope`.

- [ ] **Step 4: Write the implementation**

Delete the placeholder and create the file:

```bash
git rm -q Sources/FootballSimCore/Persistence/.gitkeep
```

Create `Sources/FootballSimCore/Persistence/SaveEnvelope.swift`:

```swift
import Foundation

public enum SaveEnvelopeError: Error, Equatable {
    case notASaveFile
    case truncatedHeader
    case futureVersion(found: UInt32, supported: UInt32)
}

/// The on-disk wrapper around a save payload.
///
/// 03b section 4 requires the schema version to be readable *without parsing the whole file*. The
/// prior build learned that one the hard way: a save it could not open was a save whose version it
/// could not find out. So the layout puts a fixed 16-byte header in front of the JSON body:
///
///     0..<4    magic, ASCII "PFC1"
///     4..<8    schemaVersion, UInt32 little-endian
///     8        flags — bit 0 reserved for "body is compressed", currently always 0
///     9..<16   reserved, always zero
///     16...    body
///
/// Reading the version is a 16-byte read. The flags byte is deliberate headroom: 03b section 4 wants
/// the body gzipped, and adding that later must not move the version field or invalidate a save.
public struct SaveEnvelope: Sendable {
    public static let currentSchemaVersion: UInt32 = 1
    public static let headerLength = 16

    private static let magic: [UInt8] = Array("PFC1".utf8)

    public static func encode<T: Encodable>(_ payload: T) throws -> Data {
        var data = Data(magic)
        withUnsafeBytes(of: currentSchemaVersion.littleEndian) { data.append(contentsOf: $0) }
        data.append(0)                                        // flags: body uncompressed
        data.append(contentsOf: Array(repeating: UInt8(0), count: 7))   // reserved
        data.append(try JSONEncoder.stable().encode(payload))
        return data
    }

    /// Reads the version from the header alone. Accepts any `Data` at least `headerLength` long, so
    /// a caller can pass the first 16 bytes of a file it has not otherwise read.
    public static func schemaVersion(ofHeader header: Data) throws -> UInt32 {
        guard header.count >= headerLength else { throw SaveEnvelopeError.truncatedHeader }
        let bytes = Array(header.prefix(headerLength))
        guard Array(bytes[0..<4]) == magic else { throw SaveEnvelopeError.notASaveFile }
        return bytes[4..<8].reversed().reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let version = try schemaVersion(ofHeader: data)
        // Refused, never partially opened: a newer writer may have changed the body's shape, and a
        // half-migrated league is worse than a refused one.
        guard version <= currentSchemaVersion else {
            throw SaveEnvelopeError.futureVersion(found: version, supported: currentSchemaVersion)
        }
        return try JSONDecoder.stable().decode(type, from: data.dropFirst(headerLength))
    }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
./scripts/verify.sh
```

Expected: build PASS, all seven save-envelope tests passing, `2 passed, 0 failed`.

- [ ] **Step 6: Commit**

```bash
git add Sources/FootballSimCore/Persistence Tests/SimTests/Suites/SaveEnvelopeTests.swift \
        Tests/SimTests/main.swift
git commit -m "feat: a save envelope whose version is readable without a full parse

Fixed 16-byte header: magic PFC1, schemaVersion as little-endian UInt32, a
flags byte, seven reserved zero bytes, then the JSON body. Reading the version
is a 16-byte read, which is what 03b section 4 asks for and what the prior
build lacked when it met a save it could not open.

A future-version save is refused rather than partially opened. The flags byte
is headroom for gzipping the body later without moving the version field;
compression itself is D7's business and is not built here.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Close the phase

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/PORT-LOG.md` (final suite counts, if Task 1 Step 10 used an estimate)

**Interfaces:**
- Consumes: everything above.
- Produces: an honest record, and the gate results the phase is allowed to claim.

- [ ] **Step 1: Run the full gate set**

```bash
./scripts/verify.sh
```

Expected: build PASS, all tests passing, `2 passed, 0 failed`. **Copy the exact test and check
counts** — the next step records them.

This is G1 and G2. Per `docs/05-IMPLEMENTATION-PLAN.md`, they are asserted by having run them in this
session, with this output in hand.

- [ ] **Step 2: Assert G6 explicitly**

G6 is "same seed reproduces exactly, across processes; the `hashValue` source scan passes." Both are
covered by tests already run, but confirm the second directly and confirm the golden vectors survive
a genuinely separate process:

```bash
swift run -c release SimTests > /tmp/pfc-run1.txt 2>&1
swift run -c release SimTests > /tmp/pfc-run2.txt 2>&1
diff /tmp/pfc-run1.txt /tmp/pfc-run2.txt && echo "IDENTICAL ACROSS PROCESSES"
```

Expected: no diff output, then `IDENTICAL ACROSS PROCESSES`. Two separate invocations mean two
separate hash seeds; identical output means nothing in the tree depends on one.

- [ ] **Step 3: Assert G4 — scope**

```bash
git log --oneline main..HEAD
git diff --stat $(git merge-base main HEAD)..HEAD -- Sources Tests Package.swift App
```

Read the diff. Every file touched must appear in this plan's File Structure table. Anything else is a
scope violation and must be reverted, not rationalised.

- [ ] **Step 4: Rewrite `docs/STATUS.md`'s "Where the project actually is"**

Replace the section with the truth after P0. Fill in the real numbers from Step 1:

```markdown
## Where the project actually is

**P0 is complete. The tree is a foundation and nothing more.**

The spec package is complete and P0 has run: the repository has been stripped to the four things
`docs/PORT-LOG.md` justifies keeping, the `03b` section 1 module skeleton exists, the `03` section 3
hierarchical seeding contract is implemented and pinned by golden vectors, the three build-wide
source scans are in `Tests/SimTests/Suites/ContractTests.swift`, and the save envelope carries a
version readable from a 16-byte header.

**Gates, run on this machine this session and not cited from elsewhere:**

| Gate | Result |
|---|---|
| G1 build | green |
| G2 tests | <N> tests, <M> checks, all passed |
| G4 scope | diff matches `docs/plans/2026-08-09-p0-foundation.md` |
| G6 determinism | golden vectors pinned; two separate process invocations byte-identical; `hashValue` scan green |

**What is NOT true yet:** there is no model, no rules module, no engine, no generation, no AI, no
design system and no view beyond a placeholder. P1 starts the model.
```

- [ ] **Step 5: Commit and close**

```bash
git add docs/STATUS.md docs/PORT-LOG.md
git commit -m "docs: P0 is complete, with the gate results it is allowed to claim

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Adversarial review before declaring the phase done**

`CLAUDE.md` requires it, and it is not a build:

```bash
git diff $(git merge-base main HEAD)..HEAD -- Sources Tests Package.swift App
```

Run `adversarial-reviewer` (or `/code-review`) over that diff. Fix confirmed findings before
declaring P0 done. **An adversarial review must never be reported as a build.**

- [ ] **Step 7: Stop**

`CLAUDE.md`: one phase at a time. Do not begin P1.

---

## Notes carried out of this plan

Things noticed while writing it that are **not** P0's business and must not be done here:

1. **`App/build/`** sits untracked in the working tree. Not P0's scope.
   *(The nested `Pro-Football-Coach/` directory was originally noted here as "untracked" — that was
   wrong. It was a **gitlink**, mode `160000`, staged as a submodule with no `.gitmodules`, so every
   clone got an empty directory that could not be initialised. It had been on `origin/main` since
   `4ebf7eb`. Removed from the index before the push; the on-disk clone was left alone and the path
   is now gitignored.)*
2. **`03b` §3's "no save path reachable from the main actor" test** has no home yet — there is no
   `SimulationActor` until later. It belongs to the phase that adds one.
3. **Gzip for the save body** is D7's business. The envelope's flags byte reserves the bit.
4. **The design-token scan's pattern set is deliberately small** — the four the audit actually
   counted. P11 extends it as the design system grows, and `04` §3's component registry is what makes
   that enumeration by construction rather than by memory.
