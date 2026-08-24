# 03b — Architecture

Module layout, the engine/UI boundary and how it is enforced, save architecture (D7), test
architecture (D11), and project structure. The v3 brief had no home for this; `03` is the match
engine, not the system.

---

## 1. Modules

```
Sources/
  FootballSimCore/        pure Swift. ZERO import SwiftUI. The simulation.
    Model/                value types: player, team, programme, contract, league, save
    Rules/                per-tier rules modules. Every constant lives here.
      CollegeRules/       calendar, eligibility, scholarships, NIL, portal, bracket
      ProRules/           calendar, cap, draft order, free agency, bracket
      (shared)            ClockRules, CompetitionRules, MatchupRules, PeopleRules, SharedRules
    Engine/               snap resolution, drive, game, clock, situation, snap anchors
    Abstracted/           the off-screen model (D3)
    Generation/           league, programme identity, names, map, traditions (D6)
    AI/                   coordinator, roster, opponent game-plan (D10)
    Calibration/          harness, bands, TOST
    Persistence/          the save envelope: header, version, compression, bounds
    Support/              seeded RNG, math, collections
    World/                the authoritative root and its scheduler
    Intent/               the intent and projection boundary (§2)
    Integrity/            the invariants the root is checked against
    Competition/          schedules, standings, brackets, statistics, honours
    People/               M2: development, morale, discipline, season lifecycle, and the
                          professional contract and roster systems
    College/              M3: recruiting, portal, NIL, scouting, redshirts, signing
    Pro/                  M6: the professional market and its roster AI
    Tactical/             M4: game plan, practice, call-in, tactical state
    Career/               M5: the career arc, its controls, and mandatory decisions
    History/              M7: domain events, season digests, rivalries, coaching tree, news feed
    Scheduling/           the world calendar and its weekly steps
  ProFootballCoachUI/     SwiftUI. Views, design tokens, screen registry. No simulation logic.
                          Flat, one file per surface or component; Resources/ carries the
                          packaged team marks.
  CoachWorldApp/          the composition layer, and the only module allowed to see both
                          GameState and the screen read models (§2). Read-model providers,
                          the store, and the save document/store.
App/                      thin @main shell + project.yml
Tests/                    see §5
```

The tree above is `ls`, not intent. `ProFootballCoachUI/` was specified with `DesignSystem/` and
`Features/` subdirectories and shipped flat; the boundary that matters is enforced by the scans
below, not by directory, so the flat layout was left alone rather than rearranged to match a
diagram.

**The boundary is enforced by test, not by convention.** These **five** source-scanning tests fail
the build:

| Scan | Rule | Root |
|---|---|---|
| Engine boundary | no `import SwiftUI` / `UIKit` / `AppKit`, no UI type | `FootballSimCore/` |
| Authoritative root | no file that imports a UI framework may name `GameState` | every file importing SwiftUI/UIKit/AppKit |
| Seeding | no `hashValue`, `Hasher(`, `hash(into:)` — every per-launch-salted hash, not one spelling | `FootballSimCore/` |
| Ambient randomness | no `UUID()`, `Date()`, `Date.now` as argument or assignment; `id: UUID = UUID()` permitted as a default parameter in `Model/` only (`03` §3 clause 5) | `FootballSimCore/`, less `Model/` |
| Design tokens | no literal spacing, radius, colour, font size or animation duration | every file importing SwiftUI/UIKit/AppKit, less `CoachWorldMotion.swift` |

**Three Root cells were corrected on 2026-08-23, all in the same direction: canon named a directory,
the scan enumerates by construction.** Ambient randomness read `Engine/`, `Generation/`, `AI/`,
`Abstracted/` — four of the engine's twenty-two directories; the scan walks the whole target and
exempts `Model/` by name, and the same hand list was removed from `03` §3 clause 5. Design tokens and
authoritative root both read `ProFootballCoachUI/`; each scan actually enumerates **every file that
imports a UI framework**, because the rule is about code that draws and the composition layer is a
second target that does — the authoritative-root scan's own comment records that a directory-only
enumeration would have missed `CoachWorldApp` the day it was created. Design tokens' one exemption,
`CoachWorldMotion.swift`, is the definition site for `04` §6.7's durations, which necessarily holds
the literal its consumers must not.

The authoritative-root scan is what makes `CoachWorldApp` a module rather than a convention. It runs
**file by file, not module by module**: inside the composition layer a file that imports SwiftUI
still may not name `GameState`, so the composition boundary holds within the one target that is
allowed to straddle it.

These five are not the whole set. `Tests/SimTests/Suites/ContractTests.swift` also scans for a `Set`
stored in a model type (its encoded order is salted per launch), a dictionary key that does not
encode as a JSON object, a stored property without a type annotation, a random draw inside
`SnapAnchors.swift`, and a symlink hiding source from the other scans. Adding a scan does not require
editing this table; the table names the five the boundary is built from.

**Every scan strips comments properly and ships a self-test that fails on a planted offender.** The
prior build's scan exempted any offending line carrying a trailing comment, and never looked for
`UUID()` at all — which is how five real determinism leaks survived a green suite (`03` §3
clause 5). A scan that has never failed is not known to be a scan.

That last one is the direct structural answer to `AUDIT.md`'s systemic pattern 2, which counted 43
literal spacings, 25 literal radii and 9–10 hard-coded font sizes against `DESIGN.md`'s own written
rule that "a literal in a view is a defect". A rule nothing enforces is a wish.

---

## 2. The engine/UI contract

The UI never computes a simulation result. It reads value types the engine produced and renders
them. Specifically:

- The UI reads **immutable read models** — one `…ReadModel` per screen family, all `Sendable`
  `Equatable` value types, declared in `ProFootballCoachUI` and built in `CoachWorldApp` by a
  `CoachWorld…Provider` from the authoritative `GameState`. The provider is the only thing that
  sees both sides, which is what §1's authoritative-root scan enforces.
- Mutation goes one way, through intents: the UI submits a `CoachIntent` (a call-in choice, a game
  plan, a roster change) to `CareerSession.resolve`, `IntentResolver` applies it, and the session
  returns a receipt and a new snapshot. The store then re-adopts that snapshot wholesale.
- The match view consumes a **recorded** playback, not a live simulation:
  `SnapAnchors.choreograph(play:offense:defense:)` turns an already-resolved `PlayRecord` into a
  sparse `SnapAnchorSet`, which the provider projects into `MatchDayReadModel.Playback`. The snap is
  resolved first, the animation is choreographed to the recorded outcome second. Rendering cannot
  change a result, and `03` §9.3's five legality clauses are tests.

Names to expect, since an earlier draft of this section named types that were never built: there is
no `MatchFrame`, no `LeagueView` and no `WeekState`. The read models above are what replaced them.

---

## 3. Concurrency

- The engine is synchronous and pure. It does not know about actors.
- `CareerSession` — a `public actor` — owns long-running work (week advance, season sim, soak) off
  the main actor. `CoachWorldStore` is the `@MainActor` face of it, and hops off with
  `Task.detached` for the work that is seconds long on a full world: new-career generation, save
  decode, and snapshotting. (An earlier draft called this actor `SimulationActor`; the type is
  `CareerSession`.)
- **Saves are written off the main actor, always.** The prior build's only P0 was a 2.4–3.3 MB
  synchronous main-actor save at 11 call sites, paid on every league mutation and twice per action
  on the draft board. A test asserts no save path is reachable from the main actor.
- Writes coalesce: a save request during an in-flight write supersedes rather than queues.

---

## 4. Save architecture (D7)

Single versioned JSON document per save, compressed, atomic replace, one backup generation,
unknown-field defaults for forward compatibility.

**As built** (`Sources/FootballSimCore/Persistence/SaveEnvelope.swift`,
`Sources/CoachWorldApp/CoachWorldSaveStore.swift`):

- A fixed 16-byte header in front of the body: magic `PFC1`, `schemaVersion` as little-endian
  `UInt32`, a flags byte, then seven reserved zero bytes. Reading the version is a 16-byte read —
  **without parsing the whole file** (the prior build learned this one the hard way).
- The body is **zlib**-compressed, not gzip: flags bit 0 says so, and it is set on every save this
  build writes. The reader branches on the bit, so a pre-flag uncompressed save still opens — which
  is the compatibility the byte was reserved for. Two ceilings guard the read: 64 MB stored and
  512 MB decompressed, both defensive parser bounds well above the 8 MB production target.
- The store writes through a sibling temporary file and replaces atomically, keeps one backup
  generation, and quarantines a file it cannot decode rather than deleting it.
- A newer-version save is refused with a plain message, never partially opened.

**Specified, not yet built.** Migrations are forward-only, one version step each, each a pure
function with a fixture test at every boundary. The envelope header is still at v1 and no envelope
migration table exists, so an *older* envelope version is refused
(`SaveEnvelopeError.unmigratableVersion`) rather than fed to the current decoder — a refusal being
strictly better than a decode that succeeds with wrong data. Application-document migration is a
separate seam and does exist: the document decoder owns the root schema-version defaults.

Every collection that can grow across seasons carries a bound, enumerated in D7 and verified by the
soak's growth check rather than by inspection. The 8 MB ceiling itself is **not currently met** —
`docs/STATUS.md` carries the measurement and the compaction work it implies.

---

## 5. Test architecture (D11) — **decided 2026-08-09**

**The runner:** the ported `TestKit` harness, run as an executable target, wrapped by
`./scripts/verify.sh`. Neither XCTest nor swift-testing ships with the Swift Command Line Tools;
both live inside Xcode. The harness needs neither.

The command underneath is:

```bash
swift run -c release -Xswiftc -enable-testing SimTests
```

`-Xswiftc -enable-testing` is load-bearing. `SimTests` is a plain executable target, not a
`.testTarget`, so SwiftPM has no reason to infer testability for it the way `swift test` would — and
it `@testable import`s **all three** library modules: `FootballSimCore`, `ProFootballCoachUI` and
`CoachWorldApp`. This section, `README.md` and `scripts/verify.sh`'s two comments each named only
`ProFootballCoachUI` until 2026-08-24; the flag was never optional for the other two either. A
release run without the flag fails every target that `@testable` imports anything, with
"module ... was not compiled for testing". Debug builds happen to enable it; release does not.

**A run is complete only if it ends with TestKit's `N tests, M checks` summary.** `TestKit.test`
records a thrown error as a failed check, but a Swift `precondition` is SIGTRAP: it kills the
process mid-run, prints nothing, and leaves an ordinary non-zero status, so every suite after it
never runs and says nothing. `verify.sh` greps for that summary line and fails a lane without it;
40 of 143 suites went unexercised between 2026-08-20 and 2026-08-23 while release claims quoted the
full run.

**Who runs it:** the session does. The machine hosting this work has Swift 6.3.3 and Xcode 26.6, and
the gates were run rather than reasoned about. See `docs/OPEN-DECISIONS.md` D11 for the full closure.

**The structure:**

```
Tests/
  SimTests/                     the executable target — the whole command-line suite
    main.swift                  argument dispatch: the default run, and one flag per lane
    TestKit.swift               the harness: suite/test/expect, counts, exit code
    SuiteCatalog.swift          the release gates as data — id, lane, default-run, runner
    TestRoots.swift             shared deterministic roots
    Suites/                     one file per subject area
  ProFootballCoachTests/        XCTest, Xcode only — declared in App/project.yml, not in Package.swift
  ProFootballCoachUITests/      XCUITest, Xcode only — same
```

`SuiteCatalog` is why the gate list does not drift: every release gate is an enumerated case with a
lane and a runner command, `--catalog` prints the table, and `--commitment-coverage` asserts that
every commitment named in `PRODUCT.md` resolves to a gate whose command is actually dispatched in
`main.swift`. A gate that exists as a name with nothing behind it fails that test.

`verify.sh` groups those flags into named lanes — `core`, `determinism`, `calibration`, `soaks`,
`accessibility`, `archive`, `release`, `app` and the default `full` — each with its own scratch
directory and logs, so a failed run in one cannot contaminate another.

**The catalogue's `lane` column is not that lane, measured 2026-08-24.**
`SuiteCatalog.lane(for:)`'s own comment states the rule — "the lane column names the `verify.sh`
lane that runs a gate" — and for **12 of the 20** registered gates it does not. Three of the seven
values it emits (`performance`, `persistence`, `legal`) are not `verify.sh` lane names at all. Six
gates labelled `accessibility` run elsewhere: `commitmentCoverage` in `release`, and
`contrastByConstruction`, `voiceOver`, `touchTarget`, `reachability` and `errorSurface` in `core`,
all five through `--core-contracts`. The four `persistence` gates run in `release` through
`--save-document`. `performanceBudget` and `legal` are run by no lane at all — `legal` at least
rides the default run, `performanceBudget` does not (see `docs/OPEN-DECISIONS.md` D4). Exactly six
rows are right — `dynamicType`, `accessibility`, `reduceMotion`, `determinism`, `m1Soak`, `m2Soak` —
and two more, `calibrationGate` and `twoTierConsistency`, read `manual`, which is the comment's own
deliberate spelling for "no lane runs this" and so is not a defect. Nothing checks the column, because
`CommitmentCoverageTest` asserts that a gate has a *dispatched runner*, not that its lane runs it —
so the column is prose inside a data structure. Recompute it before quoting it: the mismatch is
mechanical from `SuiteCatalog.swift` and `scripts/verify.sh` alone.

One target, one flat `Suites/` directory inside `SimTests/`. An earlier four-directory split was the
specification and was never built: the categories it named are suite *names* inside `Suites/` —
`EngineTests.swift`, `CalibrationTests.swift`, the `M1`/`M2`/`M3` soaks, `ContractTests.swift`,
`DesignContractTests.swift`, `LegalTests.swift` — and `SuiteCatalog.swift` is what makes the set
enumerable, which is the property the directory split was reaching for.

**The condition, which outlives the closure.** Agent environments *have* had no `swift`, no
`swiftc`, no `xcodebuild`, no `xcrun` and no `simctl`, with `download.swift.org` refused by egress
policy — and Phase 4C shipped never having been compiled as a direct result. That case has not
disappeared; it is simply not the case here. So the rule is behavioural, not environmental:

- **Assert "tests green" only by having run them in the session that claims it.** Citing D11, this
  section, or a previous session's green run is not an assertion.
- A session without a toolchain records what it wrote in `docs/STATUS.md` as **unverified — never
  compiled**, naming the files, and does not claim the phase is done.

---

## 6. Rules modules

Per tier, one module, no magic numbers anywhere else: calendar, cap, eligibility, scholarships, NIL,
draft order, playoff formats, roster limits, practice-squad rules, portal windows, realignment
thresholds. A constant used by both tiers lives in a shared rules module and is named for what it
is, not duplicated.

---

## 7. Project structure

`App/project.yml` generates the Xcode project via XcodeGen. **Landscape-only** and iPhone-only are
declared there — the prior build's orientation audit findings were rooted in that declaration being
absent, not in which orientation it named. One orientation, declared and asserted, is the property
that matters; the owner changed which one on 2026-08-10 (`04` §5.2). The **"Orientation policy"
suite** in `Tests/SimTests/Suites/DesignContractTests.swift` reads this manifest, so the declaration
cannot drift from the design.

There has never been a type named `OrientationPolicyTest` — the name this section, `CLAUDE.md` and
`06` §2 row 17 all used until 2026-08-23. The declaration was real and the test was not for the first
two days of the claim; that file's own comment records it.
