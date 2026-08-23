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
    Engine/               snap resolution, drive, game, clock, situation, snap anchors
    Abstracted/           the off-screen model (D3)
    Generation/           league, programme identity, names, map, traditions (D6)
    AI/                   coordinator, roster, opponent game-plan (D10)
    Calibration/          harness, bands, TOST
    Persistence/          codable save, migrations, bounds
    Support/              seeded RNG, math, collections
    Career/               the controlled career: session actor, arc, jobs, stakes
    College/              college management: recruiting, portal, NIL, eligibility
    Pro/                  professional management: cap, draft, markets
    Competition/          standings, postseason, awards, records
    History/              the bounded durable archive
    Intent/               CoachIntent and its resolver
    Integrity/            world invariant checks
    People/               people lifecycle: development, health, retirement
    Scheduling/           the world scheduler and week advance
    Tactical/             game plan and scheme state
    World/                world assembly and realignment
  ProFootballCoachUI/     SwiftUI. Views, read-model shapes, design system. No simulation logic.
    Resources/            the only subdirectory; the rest of the target is flat
  CoachWorldApp/          the composition layer. The only target that may see both the
                          authoritative root and the screen read models, because mapping
                          one to the other is what it exists to do (Package.swift says why).
App/                      thin @main shell + project.yml
Tests/                    see §5
```

The tree above is `ls`, not intent. `ProFootballCoachUI/` was specified with `DesignSystem/` and
`Features/` subdirectories and shipped flat; the boundary that matters is enforced by the scans
below, not by directory, so the flat layout was left alone rather than rearranged to match a
diagram.

**The boundary is enforced by test, not by convention.** These **four** source-scanning tests fail
the build:

| Scan | Rule | Root |
|---|---|---|
| Engine boundary | no `import SwiftUI` / `UIKit` / `AppKit`, no UI type | `FootballSimCore/` |
| Seeding | no `hashValue` | `FootballSimCore/` |
| Ambient randomness | no `UUID()` or `Date()` as argument or assignment; `id: UUID = UUID()` permitted as a default parameter in `Model/` only (`03` §3.5) | `Engine/`, `Generation/`, `AI/`, `Abstracted/` |
| Design tokens | no literal spacing, radius, colour or font size | `ProFootballCoachUI/` |

They are the original four and no longer the whole set. `Tests/SimTests/Suites/ContractTests.swift`
also scans for a UI file owning or reading the authoritative root, a `Set` stored in a model type
(its encoded order is salted per launch), a dictionary key that does not encode as a JSON object, a
stored property without a type annotation, a random draw inside `SnapAnchors.swift`, and a symlink
hiding source from the other scans. Adding a scan does not require editing this table; the table
names the four the boundary was originally defined by.

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

- The engine exposes **immutable snapshots**: `GameState` and the `WorldTransition` a week advance
  returns, `SnapOutcome`, the `SnapAnchors` choreography record, and the screen read models in
  `Sources/ProFootballCoachUI/ScreenReadModels.swift`. All `Sendable` value types. *This clause named
  `WeekState`, `MatchFrame` and `LeagueView` until 2026-08-23; no type of any of those names was ever
  written.*
- Mutation goes one way, through intents: the UI submits a `CoachIntent` (a call-in choice, a game
  plan, a roster change), the engine returns a new state.
- The match view consumes a **choreography record produced ahead of rendering** — `SnapAnchors`
  waypoints, each carrying the fraction of playback it belongs at. The snap is
  resolved first, the animation is choreographed to the recorded outcome second. Rendering cannot
  change a result, and a test asserts it.

---

## 3. Concurrency

- The engine is synchronous and pure. It does not know about actors.
- An actor owns long-running work (week advance, season sim, soak) off the main actor. It ships as
  `CareerSession` (`Sources/FootballSimCore/Career/CareerSession.swift`), which admits no suspension
  between validating an intent and committing it, so an intent cannot re-enter against a partially
  applied `GameState`. This clause named a `SimulationActor` until 2026-08-23; no such type exists.
- **Saves are written off the main actor, always.** The prior build's only P0 was a 2.4–3.3 MB
  synchronous main-actor save at 11 call sites, paid on every league mutation and twice per action
  on the draft board. A test asserts no save path is reachable from the main actor.
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

**The runner:** the ported `TestKit` harness, run as an executable target — `swift build -c release
-Xswiftc -enable-testing`, then `swift run -c release -Xswiftc -enable-testing SimTests`, wrapped by
`./scripts/verify.sh`. Neither XCTest nor swift-testing ships with the Swift Command Line Tools; both
live inside Xcode. The harness needs neither.

`-Xswiftc -enable-testing` is load-bearing, and was missing from this line until 2026-08-23. Because
`SimTests` is an executable target rather than a recognised `.testTarget`, SwiftPM has no reason to
infer testability, and `-c release` does not enable it the way a debug build happens to — so a
release run of the command as previously documented fails every target that `@testable import`s
anything, with "module ... was not compiled for testing". `scripts/verify.sh` passes the flag on both
the build and the run, and says why at the call site.

**A run counts only if it ends with TestKit's `N tests, M checks` summary.** `TestKit.test` records a
thrown error as a failed check, but a Swift `precondition` is a SIGTRAP: it kills the process
mid-run, prints nothing, and leaves an ordinary non-zero status, so every later suite silently never
runs. `verify.sh` fails a lane whose log has no summary line, for exactly that reason.

**Who runs it:** the session does. The machine hosting this work has Swift 6.3.3 and Xcode 26.6, and
the gates were run rather than reasoned about. See `docs/OPEN-DECISIONS.md` D11 for the full closure.

**The structure:**

```
Tests/
  SimTests/
    main.swift          flag dispatch: one --flag per suite, plus the default run
    TestKit.swift       the harness: suite/test/expect and the terminal summary
    TestRoots.swift     package-root resolution, so a scan can read canon and the manifest
    SuiteCatalog.swift  release gates as data, so the harness and CI enumerate the same list
    Suites/             the suites themselves
```

One target, one flat `Suites/` directory. The four-directory split above was the specification and
was never built: the categories it names are suite *names* inside `Suites/` — `EngineTests.swift`,
`CalibrationTests.swift`, the `M1`/`M2`/`M3` soaks, `ContractTests.swift`,
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
