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

**The boundary is enforced by test, not by convention.** **Four** source-scanning tests fail the
build:

| Scan | Rule | Root |
|---|---|---|
| Engine boundary | no `import SwiftUI` / `UIKit` / `AppKit`, no UI type | `FootballSimCore/` |
| Seeding | no `hashValue` | `FootballSimCore/` |
| Ambient randomness | no `UUID()` or `Date()` as argument or assignment; `id: UUID = UUID()` permitted as a default parameter in `Model/` only (`03` §3.5) | `Engine/`, `Generation/`, `AI/`, `Abstracted/` |
| Design tokens | no literal spacing, radius, colour or font size | `ProFootballCoachUI/` |

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

- The engine exposes **immutable snapshots**: `WeekState`, `MatchFrame`, `SnapOutcome`,
  `LeagueView`. All `Sendable` value types.
- Mutation goes one way, through intents: the UI submits a `CoachIntent` (a call-in choice, a game
  plan, a roster change), the engine returns a new state.
- The match view consumes a **stream of `MatchFrame`** produced ahead of rendering. The snap is
  resolved first, the animation is choreographed to the recorded outcome second. Rendering cannot
  change a result, and a test asserts it. `MatchFrame` carries the spatial anchors `03` §1.4
  specifies, derived at read time from the recorded outcome and never persisted.

**The intent surface must reach both tiers — added 2026-08-14.** `CoachIntent` carries pro management
and pro market actions, but the session that the UI actually holds exposes only six intents and
routes none of them, so the entire professional front office is unreachable from the app however
complete the engine beneath it is. The same gap silently blocks the promotion decision, which the
session explicitly rejects. The rule this restates: **an intent the engine resolves and the session
cannot reach is a dead capability**, which `08` names as a standing failure mode. The session's intent
surface is therefore the union of what the resolver handles, and a source scan asserts the two stay
equal — enumerated by construction from the resolver's own cases, so an intent added tomorrow is
covered the day it appears rather than the day someone remembers this paragraph.

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

**Bounds for the systems added 2026-08-14.** Each is stated here before it is built, because a bound
retrofitted after a soak is a bound chosen to fit the number it produced. All are per-save unless
noted, and all are discarded rather than archived when they leave the window.

| Collection | Bound | Note |
|---|---|---|
| Per-player attribute change ring | last 6 changes per active player | Discarded on departure. `03` §1.5's sample travels with it |
| Player-game ratings | derived, not stored | Computed from retained results; zero save cost |
| Verdict baselines | current season + 1 prior | League-week aggregates, discarded beyond the window |
| Spatial anchors | derived, not stored | `03` §1.4; a pure function of the recorded outcome |
| User `GameRecord` | the current week's game only | Evicted at the week boundary; the abstracted summary persists as before |
| Inbound events | 32 live, 8 arriving per week | `02` §7.1; archived events fold into the season digest |
| Job-market openings | 32 tracked | `02` §7.2; interest decays rather than accumulating |
| Staff candidate pool | refreshed at the season boundary | `02` §6.1; not cumulative across seasons |
| Depth charts | one ordering per position per organisation | `02` §2.1a; packages reference it rather than copying it |
| Personnel packages | 8 per side, 11 slots each | Rules constants, per tier |
| Contract negotiations | live negotiations expire within their window | `02` §4.2c; the free-agent pool cap of 512 already bounds the population |

The two derived rows are the ones worth noticing: the anchors and the ratings are the most
screen-visible additions in this programme and they cost the save nothing, because both are functions
of state the engine already keeps. A projection that could be derived and was stored anyway is how
the prior build reached 8.3 MB.

---

## 5. Test architecture (D11) — **decided 2026-08-09**

**The runner:** the ported `TestKit` harness, run as an executable target —
`swift build && swift run -c release SimTests`, wrapped by `./scripts/verify.sh`. Neither XCTest nor
swift-testing ships with the Swift Command Line Tools; both live inside Xcode. The harness needs
neither.

**Who runs it:** the session does. The machine hosting this work has Swift 6.3.3 and Xcode 26.6, and
the gates were run rather than reasoned about. See `docs/OPEN-DECISIONS.md` D11 for the full closure.

**The structure:**

```
Tests/
  EngineTests/        unit, property, determinism, source-scanning
  CalibrationTests/   bands + TOST, both models
  SoakTests/          20-season soak
  ContractTests/      accessibility contract, design tokens, legal tests
```

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
that matters; the owner changed which one on 2026-08-10 (`04` §5.2). `OrientationPolicyTest` reads
this manifest, so the declaration cannot drift from the design.
