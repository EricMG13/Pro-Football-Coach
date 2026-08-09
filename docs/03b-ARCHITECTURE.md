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
  ProFootballCoachUI/     SwiftUI. Views + view models only. No simulation logic.
    DesignSystem/         tokens, components, accessibility contract surface
    Features/             one directory per feature area
App/                      thin @main shell + project.yml
Tests/                    see §5
```

**The boundary is enforced by test, not by convention.** A source-scanning test fails the build if
`import SwiftUI`, `import UIKit`, or any UI type appears anywhere under `FootballSimCore/`. The same
scan enforces the determinism rule (no `hashValue` in seeding paths) and the design-token rule (no
literal spacing, radius, colour or font size in a view).

That last one is the direct structural answer to `AUDIT.md`'s systemic pattern 2, which counted 43
literal spacings, 25 literal radii and 9–10 hard-coded font sizes against `DESIGN.md`'s own written
rule that "a literal in a view is a defect". A rule nothing enforces is a wish.

---

## 2. The engine/UI contract

The UI never computes a simulation result. It reads value types the engine produced and renders
them. Specifically:

- The engine exposes **immutable snapshots**: `WeekState`, `MatchFrame`, `SnapOutcome`,
  `LeagueView`. All `Sendable` value types.
- Mutation goes one way, through intents: the UI submits a `CoachIntent` (a call-in choice, a game
  plan, a roster change), the engine returns a new state.
- The match view consumes a **stream of `MatchFrame`** produced ahead of rendering. The snap is
  resolved first, the animation is choreographed to the recorded outcome second. Rendering cannot
  change a result, and a test asserts it.

---

## 3. Concurrency

- The engine is synchronous and pure. It does not know about actors.
- A `SimulationActor` owns long-running work (week advance, season sim, soak) off the main actor.
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

## 5. Test architecture (D11) — **blocked pending an owner decision**

**D11 is decided.** The runner is the hand-rolled harness below, run by `./scripts/verify.sh` on the
owner's machine — verified green on Swift 6.3.3 (299 tests, 18,412 checks). The constraints that
forced that choice, and that still shape every phase gate:

- Agent environments have had no `swift`, no `swiftc`, no `xcodebuild`, no `xcrun`, no `simctl`, and
  `download.swift.org` refused by egress policy.
- Neither XCTest nor swift-testing ships with the Swift Command Line Tools, which is why the prior
  build ran its suite as an executable target with a hand-rolled harness.
- Phase 4C shipped never having been compiled as a direct result.

**Until D11 is answered, this section specifies the structure but not the runner:**

```
Tests/
  EngineTests/        unit, property, determinism, source-scanning
  CalibrationTests/   bands + TOST, both models
  SoakTests/          20-season soak
  ContractTests/      accessibility contract, design tokens, legal tests
```

Every phase gate in `05` that says "tests green" is asserted against whatever D11 selects. If D11
lands on the hand-rolled harness with no agent-side toolchain, then **the agent cannot run the
gates**, and `05` must sequence phases so the owner runs them at phase boundaries. That is a
scheduling consequence, not a detail.

---

## 6. Rules modules

Per tier, one module, no magic numbers anywhere else: calendar, cap, eligibility, scholarships, NIL,
draft order, playoff formats, roster limits, practice-squad rules, portal windows, realignment
thresholds. A constant used by both tiers lives in a shared rules module and is named for what it
is, not duplicated.

---

## 7. Project structure

`App/project.yml` generates the Xcode project via XcodeGen. Portrait-only and iPhone-only are
declared there — the prior build's landscape audit findings were rooted in that declaration being
absent.
