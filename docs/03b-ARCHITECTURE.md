# 03b — Architecture

How the app is put together. The match engine's internals are in `03-MATCH-ENGINE.md`; this document
covers modules, the engine/UI boundary, persistence (D7), and the test architecture (D11).

---

## 1. Module layout

One Swift package, three targets. No third-party dependencies, ever.

```
ProFootballCoach/
├── Package.swift
├── App/
│   ├── ProFootballCoachApp.swift      thin @main shell
│   └── project.yml                    XcodeGen spec — iPhone only, portrait only
├── Sources/
│   ├── FootballSimCore/               pure simulation. no UI. deterministic.
│   │   ├── Model/                     Player, Team, Programme, League, Contract, Staff, Recruit
│   │   ├── Rules/                     LeagueRules, CollegeRules, EngineTuning, name banks
│   │   ├── Engine/                    snap resolution, drives, season, offseason, AI
│   │   ├── Abstract/                  the off-screen model (03 §3.1)
│   │   ├── Generation/                leagues, programmes, players, recruits, identity
│   │   ├── Career/                    reputation, carousel, the promotion arc
│   │   └── Support/                   SeededRandom, coding helpers
│   └── ProFootballCoachUI/            SwiftUI feature layer
│       ├── Theme/                     design tokens, the accessibility contract's implementation
│       ├── Persistence/               SaveStore, SaveQueue
│       ├── Match/                     FieldCanvas, choreography, the match surface
│       └── Features/                  one folder per section, not one file per app
└── Tests/
    └── SimTests/                      executable target, hand-rolled harness
```

**Why `ProFootballCoachUI` is a library rather than living in `App/`:** both library targets build
for macOS as well as iOS, so the whole codebase — engine *and* views — is compile-verified from the
command line without Xcode. That is the only thing that made the prior build verifiable at all in
agent environments, and it is worth the small friction of keeping views library-shaped.

---

## 2. The engine/UI boundary

**The rule:** `FootballSimCore` knows nothing about SwiftUI, and the UI never computes a game
outcome.

### 2.1 How it is enforced

Not by discipline — by tests:

| Enforcement | Mechanism |
|---|---|
| No UI in the engine | `noUIImport` source scan: no `import SwiftUI`, `import UIKit`, `import Combine` under `Sources/FootballSimCore/` |
| No simulation in the UI | `noSimulationInViews` source scan: no `SeededRandom`, no `.resolve(`, no engine mutation type outside a view model |
| No randomness in the UI | Source scan for `.random(`, `arc4random`, `Date()` in `Sources/ProFootballCoachUI/` outside the two allowed clock sites |
| The engine is Sendable | Model types are value types and `Sendable`, so the save can move off the main actor without data races |

### 2.2 Data flow

Unidirectional, one owner of truth:

```
        ┌────────────────────────────────────────────────┐
        │  AppState  (@Observable, @MainActor)           │
        │    owns exactly one League                     │
        │    mutate { } is the ONLY write path           │
        └───────────┬───────────────────────┬────────────┘
                    │ read                  │ mutate
             ┌──────▼──────┐         ┌──────▼───────────┐
             │  Views      │         │  FootballSimCore │
             │  (dumb)     │         │  pure functions  │
             └─────────────┘         └──────┬───────────┘
                                            │ after each mutation
                                     ┌──────▼───────────┐
                                     │  SaveQueue       │
                                     │  background actor│
                                     └──────────────────┘
```

Views read state and call intents. They never mutate a model directly and never hold a copy that can
drift.

---

## 3. D7 — Save architecture and schema migration

Career saves span in-game decades. The persistence design is where the prior build's two worst
defects lived, so both are designed out rather than fixed later.

### 3.1 Format

`Codable` JSON in Application Support. Not a binary format, not SQLite:

- JSON survives a schema change with unknown-field defaults, which is what makes a *shipped* save
  openable by a later build.
- It is diffable and inspectable, which matters enormously for debugging a 20-season career.
- The size problem it creates is solved by bounding collections (§3.4), not by changing format.

Each slot is a pair: `<id>.json` (the league) and `<id>.meta.json` (a small sidecar).

**The sidecar is load-bearing.** The save list decodes only the sidecars, never the multi-megabyte
league files, so the load screen renders without touching a full save. The prior build got this
right and it is preserved.

### 3.2 Writing — the P0 designed out

The prior build's single blocking defect: every league mutation performed a 2.4–3.3 MB synchronous
encode, backup copy, atomic write and directory rescan **on the main actor**, at 11 call sites,
measured at 84–112 ms each, with some user actions paying it 2–5 times.

The design that prevents it:

1. **One write per user action, not one per mutation.** `mutate` marks dirty; it does not save.
2. **`SaveQueue` is a background actor.** Encode and write never touch the main actor.
3. **Coalescing.** Multiple dirty marks inside one action collapse to one write.
4. **`store.list()` is never called from the save path.** The save list refreshes when the menu
   appears, not on every write.
5. **A `flush()` on background/terminate**, awaited, so nothing is lost.
6. **A test asserts writes-per-action.** `advanceWeek` produces exactly one write. This is the
   regression test the prior build did not have, and its absence is why the defect reached P0.

### 3.3 Migration policy

```swift
struct SaveEnvelope: Codable {
    let saveFormatVersion: Int   // read WITHOUT decoding the whole file
    let league: League
}
```

- The version is read from a **prefix scan**, not by decoding the file — reading a 6 MB save to find
  out you cannot open it is a bug the prior build fixed and this design keeps fixed.
- **Forward compatible by default**: unknown fields are ignored, missing fields default, so an older
  save opens in a newer build without a migration step for additive changes.
- **Structural changes get a numbered migrator** and a **fixture**: a real save from the prior
  version, committed to the repo, that the suite opens and validates. A migration without a fixture
  does not ship.
- **Refusal is explicit**: a save from a *newer* format version is refused with a message naming the
  problem, never opened and silently corrupted.
- **A rolling backup** — the previous good save is kept and recovered from automatically if the
  primary fails to decode. This is aimed squarely at the competitive set's largest complaint class:
  34% of the reference app's reviews concern crashes and save corruption around season 8, to the
  point that users buy checkpoint tokens as crash insurance (§H).

### 3.4 Size trajectory over 20 seasons

The budget is **6 MB target / 10 MB ceiling** at season 20 (`03-MATCH-ENGINE.md` §8). College drives
it: ~134 programmes × 85 scholarship players is ~11,400 active players against the pro tier's ~2,200.

Every collection that can grow is bounded, and each bound is asserted by `soakCollectionsBounded`:

| Collection | Bound | Note |
|---|---|---|
| Active players | Structural | Roster limits |
| Free-agent pool | Hard cap, tail retired by age/rating | Reached 9,000 in the prior build |
| Recruit classes | One live cycle | Prior cycles reduced to outcomes |
| Portal pool | One window, cleared on close | |
| News feed | Ring buffer | Reached 8,000 stories in the prior build |
| Play-by-play | Current game only | Finished seasons keep aggregates |
| Season history | Aggregates only | Never per-play |
| Records / Hall of Fame | Top N by construction | |
| Rivalry history | Last N meetings + lifetime aggregates | **New in this design — the mechanic in `02` §11 is exactly the kind that grows forever if nobody bounds it** |
| Coach career log | One row per season | |

Encoding discipline: stat lines omit zero fields, which is what took the prior build's ten-season
save from 8.3 MB to 2.3 MB alongside the pool bounds.

---

## 4. D11 — Test architecture under the real toolchain

**The constraint, stated plainly:** neither XCTest nor swift-testing ships with the Swift Command
Line Tools, and agent build environments frequently have **no Swift toolchain at all** — `swift` is
absent, Ubuntu's archive carries only the unrelated OpenStack packages, there is no Docker daemon,
and `download.swift.org` is refused by the egress policy. Every "tests green" gate in `05` depends
on how this is answered.

### 4.1 The decision

**The suite is an executable target with a hand-rolled harness** (`Tests/SimTests/TestKit.swift`),
run as:

```bash
swift build && swift run -c release SimTests
```

It reports real pass/fail counts and **exits non-zero on failure**. This is not a preference — it is
the only thing that runs where this project is actually built. It is proven: the prior build ran
224 tests and 13,226 assertions this way, including a ten-season soak, in about 100 seconds.

Rejected alternatives, with reasons:

| Option | Why not |
|---|---|
| XCTest | Requires full Xcode. Unavailable on the build machine and in every agent container |
| swift-testing | Same |
| A Docker image with a toolchain | No Docker daemon; `download.swift.org` refused by egress |
| CI on GitHub Actions | Would work, but the project has no CI today and the owner is solo. **Logged as the recommended future improvement** — it is the one change that would convert "agent cannot verify" into "agent can verify" permanently |

### 4.2 What the builder does when the toolchain is absent

This is the part that actually matters, because it is where the prior build shipped 4C uncompiled.

1. **Keep building.** Do not stall waiting for a toolchain that is not coming.
2. **Write the tests anyway**, in the same commit as the code.
3. **Label the work `unverified` in `docs/STATUS.md`, by name**, listing every file that has never
   been compiled.
4. **Never write "tests green"** for a suite that was not executed. "Tests written, not run" is the
   honest phrase and it is not a failure to say it.
5. **An adversarial review is not a build.** The prior build's Phase 4C used a multi-agent review as
   a compiler substitute — independent passes for symbol existence, mutation and initialisation
   rules, pattern matching, runtime correctness, each finding handed to a refuter. That catches a
   great deal. It does not catch what a compiler catches, and the STATUS entry saying so is the
   model to follow.
6. **The phase's gate does not close.** It becomes an owner-verifiable item and moves to the
   walkthrough script.

### 4.3 Test taxonomy

| Kind | Runs | Example |
|---|---|---|
| Unit | Always | Cap proration, eligibility clocks, tiebreakers |
| Property | Always | Ratings stay in 40–99 under any progression sequence |
| Source-scan | Always | `noUIImport`, `noHashValueSeeding`, `difficultyDoesNotTouchRatings` |
| Determinism | Always | Including the cross-process fixture digest |
| Calibration | Always | The bands in `03-MATCH-ENGINE.md` §5 |
| Consistency | Always | Detailed vs abstract KS test (§3.2 there) |
| Soak | Always, slow | 20 seasons, every invariant |
| Legal | Always | `nameCollisionTest`, `tradeDressTest` |
| Design-system | Always | Contrast against composited surfaces, in both themes |
| **Simulator walkthrough** | **Owner only** | A written script; never claimed by an agent |

### 4.4 The coverage-boundary rule

`AUDIT.md`'s sharpest finding, and it is a design principle rather than a bug:

> *"The defect is not ignorance of contrast; it is that the test's coverage boundary became the
> quality boundary."*

The prior build's `DesignSystemTests` verified five rating tiers and all 32 team tints against real
composited surfaces — genuinely rigorous. Every surface it did not look at failed, at 50+ sites.

**The rule that follows:** when a test asserts a property for *some* instances of a category, it must
either cover **every** instance or **name what it excludes** in a comment at the assertion. A test
that quietly samples is worse than no test, because it converts an unknown into a false assurance.
This is invariant P1 in `06-AUDIT-DISPOSITION.md` and it has its own meta-test: the design-system
suite enumerates every colour token in the system and fails if one is unasserted.

---

## 5. Concurrency

- `AppState` is `@MainActor`. Views only ever touch it there.
- `SaveQueue` is an `actor`. Encoding and disk I/O happen there and nowhere else.
- `FootballSimCore` is **synchronous and pure**. It does not know about actors, `Task`, or the main
  thread. A season advance is a function call; whoever wants it off the main actor is responsible
  for arranging that.
- Long operations — a full-season sim, a 20-season soak — run in a detached task with progress
  reported back, because a 25-second block with no loading state is how the prior build's P0 felt to
  a user even after it was measured.
- **Strict concurrency checking is on.** Model types are `Sendable` value types.

---

## 6. Project structure and build

- **iPhone only, portrait only**, declared in `App/project.yml`. The prior build declared no
  orientation policy at all, which produced four P1 adaptivity findings by itself.
- iOS 17 minimum.
- No asset catalogue for team identity: marks are geometric — a shape plus a monogram, drawn from
  team colours. This is a legal benefit *and* a performance one (no image decode, no cache), and it
  is what lets 134 programmes exist without 134 image assets.
- Xcode project generated from `project.yml` via XcodeGen; the checked-in source of truth is the
  spec, not the `.xcodeproj`.
