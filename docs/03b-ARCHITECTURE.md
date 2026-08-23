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
    Engine/               snap resolution, drive, game, clock, situation
    Abstracted/           the off-screen model (D3)
    Generation/           league, programme identity, names, map, traditions (D6)
    AI/                   coordinator, roster, opponent game-plan (D10)
    Calibration/          harness, bands, TOST
    Persistence/          codable save, migrations, bounds
    Support/              seeded RNG, math, collections
    Career/               the coach's own arc: jobs, tenure, jeopardy, promotion
    College/              the college tier's state and its management systems
    Pro/                  the professional tier's state and its markets
    Competition/          standings, brackets, awards, records
    Scheduling/           the world scheduler and the week advance
    People/               development, health, eligibility, retirement, staff
    History/              the durable archive and its bounds
    Tactical/             game plans and scheme identity
    Intent/               CoachIntent and its resolver
    Integrity/            cross-reference and invariant checks on the root
    World/                world bootstrap and the normalized entity stores
  ProFootballCoachUI/     SwiftUI. Views, read models and the token layer. No simulation logic.
    Resources/            packaged assets
  CoachWorldApp/          the composition layer: application root, store, save coordinator,
                          and one read-model provider per screen family
App/                      thin @main shell + project.yml
Tests/                    see §5
```

**`ProFootballCoachUI/` is flat, not `DesignSystem/` + `Features/`.** This section specified those
two directories and they were never created; the target holds its files at the top level with
`Resources/` beside them. The split is recorded here as unbuilt rather than described as if it
shipped.

**`CoachWorldApp/` was not in this section at all.** It is a third target, and the boundary it draws
matters more than its file count: `ProFootballCoachUI` may not own the authoritative root, and
`FootballSimCore` may not import SwiftUI, so the place the two meet has to be a target of its own.
Both of those rules are scanned (§1's table), and the scans name this target.

**The boundary is enforced by test, not by convention.** Source-scanning tests fail the build. The
four this section was written around are still there, and the shipped suite has since added more —
an authoritative-root scan, a composition-layer scan, a raw-colour scan, a raw-asset-loader scan, a
symlink scan and the legal name sweep among them. `Tests/SimTests/Suites/ContractTests.swift` and
`DesignContractTests.swift` are the enumeration; this table is not, and a count written here would
be stale again by the next one added.

| Scan | Rule | Root |
|---|---|---|
| Engine boundary | no `import SwiftUI` / `UIKit` / `AppKit`, no UI type | `Sources/FootballSimCore/` |
| Seeding | no `hashValue`, no `Hasher()` | `Sources/FootballSimCore/` |
| Ambient randomness | no `UUID()`, `Date()`, `Date.now`, `Int.random` or stdlib `shuffled()` (`03` §3.5) | all of `Sources/FootballSimCore/` **except** `Model/`, which is exempt wholesale |
| Design tokens | no literal spacing, radius, colour or font size | every file under `Sources/` that imports a UI framework, `CoachWorldMotion.swift` excepted as the definition site |
| Authoritative root | no `GameState` in code that draws | the same UI-import enumeration |

**Two of those roots are enumerated by construction, and that is the finding this table records.**
The ambient-randomness row used to name `Engine/`, `Generation/`, `AI/` and `Abstracted/`, and the
design-token row used to name the directory `ProFootballCoachUI/`. Both are now inverted: the
randomness scan reads the whole engine and subtracts one exemption, and the token scan asks what a
file imports rather than where it sits. The reason is `CLAUDE.md`'s own convention — a scan that
enumerates by hand covers the surfaces someone remembered, so `Sources/CoachWorldApp/` would have
been outside the token and root scans on the day it was created. The code comments at
`ContractTests.swift` say exactly this; the doc had not caught up.

**Every scan strips comments properly and ships a self-test that fails on a planted offender.** The
prior build's scan exempted any offending line carrying a trailing comment, and never looked for
`UUID()` at all — which is how five real determinism leaks survived a green suite (`03` §3.5). A scan
that has never failed is not known to be a scan.

That last one is the direct structural answer to `AUDIT.md`'s systemic pattern 2, which counted 43
literal spacings, 25 literal radii and 9–10 hard-coded font sizes against `DESIGN.md`'s own written
rule that "a literal in a view is a defect". A rule nothing enforces is a wish.

---

## 2. The engine/UI contract

The UI never computes a simulation result. It reads value types the engine produced and renders
them. Specifically:

- The engine exposes **immutable snapshots**, all `Sendable` value types. Three of the four names
  this section originally gave were aspirational and never shipped under them. What exists is
  `WeekSnapshot` (`Scheduling/WorldScheduler.swift`), `SnapOutcome` and `MatchStepReceipt` /
  `MatchSessionState` (`Engine/`). There is no `LeagueView` type and no `MatchFrame` type; the
  per-screen read models in `ProFootballCoachUI/ScreenReadModels.swift`, assembled by the
  `CoachWorld*Provider` types in `CoachWorldApp/`, do the job `LeagueView` named.
- Mutation goes one way, through intents: the UI submits a `CoachIntent` (`Intent/IntentResolver.swift`),
  and the engine returns a new state.
- The match view consumes recorded outcomes produced ahead of rendering. The snap is resolved first,
  the animation is choreographed to the recorded outcome second. Rendering cannot change a result,
  and a test asserts it.

---

## 3. Concurrency

- The engine is synchronous and pure. It does not know about actors.
- Durable work runs off the main actor behind `SaveCoordinator`, an `actor` in
  `CoachWorldApp/CoachWorldSaveStore.swift`. No type named `SimulationActor` was ever built;
  `CoachWorldStore` is the `@MainActor` counterpart that owns UI-facing state, and the isolation
  boundary between the two is what the section below describes.
- **Saves are written off the main actor, always.** The prior build's only P0 was a 2.4–3.3 MB
  synchronous main-actor save at 11 call sites, paid on every league mutation and twice per action
  on the draft board. `SaveOffMainActorTest`, in `Tests/SimTests/Suites/SaveDocumentTests.swift`,
  asserts durable work stays behind the coordinator boundary.
- Writes coalesce: a save request during an in-flight write supersedes rather than queues.

---

## 4. Save architecture (D7)

Single versioned JSON document per save, gzip-compressed, atomic replace, one backup generation,
unknown-field defaults for forward compatibility.

- `schemaVersion` on the envelope, readable **without parsing the whole file** (the prior build
  learned this one the hard way).
- Migrations are forward-only, one version step each, each a pure function with a fixture test at
  every boundary.
- A newer-version save is refused with a plain message, never partially opened.
- Every collection that can grow across seasons carries a bound, enumerated in D7 and verified by
  the soak's growth check rather than by inspection.

---

## 5. Test architecture (D11) — **decided 2026-08-09**

**The runner:** the ported `TestKit` harness, run as an executable target, wrapped by
`./scripts/verify.sh`. Neither XCTest nor swift-testing ships with the Swift Command Line Tools;
both live inside Xcode. The harness needs neither.

```bash
swift run -c release -Xswiftc -enable-testing SimTests
```

**`-Xswiftc -enable-testing` is load-bearing, and this section used to omit it.** Because `SimTests`
is a plain executable target rather than a recognised `.testTarget`, SwiftPM has no reason to infer
testability for it — and it `@testable import`s `ProFootballCoachUI` and `CoachWorldApp`. Debug
builds enable testing anyway; `-c release` does not, so the command as previously written here fails
with `module ... was not compiled for testing`. Prefer `verify.sh`, which passes the flag.

**A run counts only if it printed `N tests, M checks`.** A Swift `precondition` is a SIGTRAP that
kills the process mid-run without printing, leaving an ordinary non-zero status that looks like an
ordinary failure — so a lane stopping short of the summary has silently skipped every suite after
it. `verify.sh` greps for that line and reports `TRUNCATED`.

**Who runs it:** the session does. The machine hosting this work has Swift 6.3.3 and Xcode 26.6, and
the gates were run rather than reasoned about. See `docs/OPEN-DECISIONS.md` D11 for the full closure.

**The structure:**

```
Tests/
  SimTests/
    main.swift          the lane flags: --core-contracts, --design-contracts, --calibration,
                        --m1-soak, --m2-soak, --m7-gate, --legal-only, --architecture-only, ...
    TestKit.swift       suite/test/expect and the terminal summary line
    SuiteCatalog.swift  which suites each lane runs
    TestRoots.swift     helpers for suites that jump the calendar
    Suites/             the suites themselves
  ProFootballCoachTests/, ProFootballCoachUITests/
                        Xcode-side stubs the generated project needs; not the real suite
```

**The four-directory split above this was specified and never built.** There are no `EngineTests/`,
`CalibrationTests/`, `SoakTests/` or `ContractTests/` directories; the work they name is done, but
it lives in `SimTests/Suites/` as suite files, selected by lane flag rather than by directory. The
names survive as suite and file names — `ArchitectureTests.swift`, `ContractTests.swift`,
`DesignContractTests.swift`, `LegalTests.swift` — which is why the drift went unnoticed.

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
that matters; the owner changed which one on 2026-08-10 (`04` §5.2). The assertion reading this manifest is
`"the app declares landscape-only and never a portrait orientation"`, in the `Orientation policy`
suite of `Tests/SimTests/Suites/DesignContractTests.swift`, so the declaration cannot drift from the
design. It is **not** named `OrientationPolicyTest`: this section and `CLAUDE.md` both claimed that
name from 2026-08-10, and for two days no test of any name existed — the suite's own comment records
it as G-09.
