# Pro Football Coach

A unified college→pro football **coaching** career simulator for iPhone. One save, one coach: you
start in the college game and get promoted to the pro league. SwiftUI, offline, zero third-party
dependencies.

You are a coach, never a player. There is **no direct control of players during play** — no arcade
mode, no throwing passes. Matches are watched in a 2D view and shaped by roster construction, scheme
identity, opponent preparation, staff and in-game decisions. Every school, team, conference, city,
stadium, player and coach is fictional and original.

> **Status: the Master Build Documentation rebaseline is active; M0 architecture hardening, M1
> playable world, and M2 people lifecycle are implemented.** The normalized deterministic root runs exact
> college and professional schedules, target-scale rosters, abstract results, regular-season
> standings, postseason brackets, awards/records, causal development, health and fatigue,
> eligibility/retirement, staff continuity, season rollover, and bounded history. M2 completed a
> verified 20-season college/pro lifecycle soak. P4's detailed-engine calibration instrument remains
> built but not calibrated. M3 college management is the active backend milestone. Exact gates and
> exclusions are in `docs/STATUS.md`.
>
> **The complete management game is not yet built** — college recruiting/portal/NIL, professional
> roster markets, tactics, the full career/stakes layer, AI/delegation, persistence productionization,
> the design system, and feature views remain ahead.
>
> The rejected v2, Stitch and 34-screen Film Room references were removed on 2026-08-11. The
> corrected canonical language is **The Coach's World**, with Film Room reserved for scouting,
> tactics and replay. [`docs/04-UX-AND-DESIGN-SYSTEM.md`](docs/04-UX-AND-DESIGN-SYSTEM.md) owns the
> complete 62-family screen inventory and the three-proof gate. Reference HTML never becomes
> production SwiftUI.
>
> [`docs/STATUS.md`](docs/STATUS.md) is the honest picture and takes precedence over this
> paragraph, and it is the cold-start pointer together with
> [`docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`](docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md).
> `docs/HANDOFF-2026-08-10.md` was linked here until 2026-08-23; it was deleted on 2026-08-10 and
> `docs/DOC-MANIFEST.md` §2 names those two as its replacement.

## Start here

1. **[`docs/DOC-MANIFEST.md`](docs/DOC-MANIFEST.md)** — what is canon, and what was deleted and why.
   Read this before opening anything else in `docs/`. Its rule has two limbs, and quoting only the
   first inverts it: a document carries authority if it is marked `RETAINED` **or** is one of the
   canon documents listed in its §4. Anything else carries none, whatever path it sits at.
2. **[`CLAUDE.md`](CLAUDE.md)** — standing rules for every session: process, tech stack, conventions,
   the legal guardrail.
3. **[`docs/reviews/2026-08-09-spec-prompt-v4.md`](docs/reviews/2026-08-09-spec-prompt-v4.md)** — the
   governing brief. Owner parameters, authority tiers, the core design problem, the deliverable list.
   Where any other document disagrees with it, the other document is wrong.

For a build session, **[`docs/08-OPUS5-BUILD-PROMPT.md`](docs/08-OPUS5-BUILD-PROMPT.md)** is the
entry point: it owns the mission and the definition of done, and it runs one phase at a time.

## Document map

`docs/DOC-MANIFEST.md` is the authority; this table is the short version.

| Doc | Purpose |
|---|---|
| [`docs/DOC-MANIFEST.md`](docs/DOC-MANIFEST.md) | Canon, and what was deleted, with reasons |
| [`CLAUDE.md`](CLAUDE.md) | Standing rules for every session |
| [`docs/01-RESEARCH.md`](docs/01-RESEARCH.md) | Reference research, competitive set, community signal, calibration sources |
| [`docs/02-GAME-DESIGN.md`](docs/02-GAME-DESIGN.md) | The game: core loop, agency model, both tiers, promotion arc, systems, stakes |
| [`docs/03-MATCH-ENGINE.md`](docs/03-MATCH-ENGINE.md) | Play resolution, seeding contract, off-screen model, calibration harness, soak |
| [`docs/03b-ARCHITECTURE.md`](docs/03b-ARCHITECTURE.md) | Module layout, engine/UI boundary, save architecture, test architecture |
| [`docs/04-UX-AND-DESIGN-SYSTEM.md`](docs/04-UX-AND-DESIGN-SYSTEM.md) | Design system, screens, match view, accessibility contract |
| [`docs/04b-AUDIT-RUBRIC.md`](docs/04b-AUDIT-RUBRIC.md) | 40-point product UI audit: football fantasy, specificity, hierarchy, continuity, control, accessibility, truth and craft |
| [`docs/05-IMPLEMENTATION-PLAN.md`](docs/05-IMPLEMENTATION-PLAN.md) | Phased build with per-phase gates |
| [`docs/plans/2026-08-11-skill-integration.md`](docs/plans/2026-08-11-skill-integration.md) | Skill activation, duplication boundaries, and project-local skill creation gates |
| [`docs/06-AUDIT-DISPOSITION.md`](docs/06-AUDIT-DISPOSITION.md) | Prior audit's P0/P1s and systemic patterns, converted into tests |
| [`docs/08-OPUS5-BUILD-PROMPT.md`](docs/08-OPUS5-BUILD-PROMPT.md) | Phase-entry prompt. Owns mission and definition of done |
| [`docs/OPEN-DECISIONS.md`](docs/OPEN-DECISIONS.md) | Decision register D1–D16, each with an instrumented falsifier |
| [`docs/PORT-LOG.md`](docs/PORT-LOG.md) | What survives from the previous build, with a logged reason both ways |
| [`docs/PRE-DEPLOYMENT-CHECKLIST.md`](docs/PRE-DEPLOYMENT-CHECKLIST.md) | What must be true before a build goes out |
| [`docs/STATUS.md`](docs/STATUS.md) | Honest state of the build: what exists, what is verified, what is not |
| [`docs/AUDIT.md`](docs/AUDIT.md) | Prior UI audit — evidence about craft, retained read-only |
| [`PRODUCT.md`](PRODUCT.md) | Positioning, audience, market gap, v1 scope |
| *(no archive)* | The superseded documents were deleted on 2026-08-10. `docs/DOC-MANIFEST.md` records what each was and why it went; `git show` recovers any of them |

## Non-negotiables

- **The shipped universe is fictional and original.** No bundled real school, team, conference,
  player or coach names; no real logos, colours, fight songs or broadcast identities. The UI
  reserves optional person/team/venue asset slots so a future, separately approved custom-universe
  feature is not architecturally blocked. Import is not a v1 feature and requires its own legal,
  privacy, security and content-handling decision. Name-collision and trade-dress tests remain gates
  on the bundled generator.
- **Determinism.** A given seed plus a given input state reproduces a match exactly, across processes
  and app launches. Seeds derive from identifier bytes, never from `hashValue`.
- **Offline, single-player.** No network, no accounts, no analytics, no ads, no IAP, no subscriptions.
- **iPhone-only, landscape-only, iOS 26+, tested on iPhone 15-generation hardware and newer, zero
  third-party app dependencies.** The 2D match view renders
  in SwiftUI `Canvas` + `TimelineView` — no SpriteKit, no Metal.
- **A full season is completable in 6–8 hours of play.**

## Layout

| Path | What |
|---|---|
| `docs/` | Design and planning documents. Start at `docs/DOC-MANIFEST.md` |
| *(no archive)* | Deleted 2026-08-10. See `docs/DOC-MANIFEST.md` |
| `docs/plans/` | Per-phase task plans, one per phase, written before that phase is built |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | The Coach's World language, canonical 62-family screen inventory and proof gate |
| `docs/reviews/` | The governing brief and the review that produced it |
| `Sources/FootballSimCore/` | The engine — pure Swift, no UI imports, seeded RNG. P0–P4 |
| `Sources/ProFootballCoachUI/` | The SwiftUI layer: views, read-model shapes and the design system |
| `Sources/CoachWorldApp/` | The composition layer — the only target allowed to see both the authoritative root and the screen read models |
| `Tests/SimTests/` | The suite and its hand-rolled harness |
| `App/` | Thin `@main` iOS shell + `project.yml` for Xcode project generation |
| `scripts/verify.sh` | Runs both machine gates and prints a pasteable result |

The previous build was removed by P0; what is under `Sources/`, `Tests/` and `App/` now is the
rebuild. `docs/PORT-LOG.md` records what survived and why, both ways.

## Building

```bash
./scripts/verify.sh
```

That is the gate: `swift build`, then the suite. Pass `--build` for the build alone, or
`--lane <name>` for one lane — `accessibility`, `app`, `archive`, `calibration`, `core`,
`determinism`, `release` or `soaks`.

Both library targets — engine *and* SwiftUI — build for macOS as well as iOS, so the codebase is
compile-verified from the command line without full Xcode. Neither XCTest nor swift-testing ships
with the Swift Command Line Tools, so the suite is an **executable target** with a hand-rolled
harness (`Tests/SimTests/TestKit.swift`); it reports real pass/fail counts and exits non-zero on
failure. The two commands underneath are:

```bash
swift build -c release -Xswiftc -enable-testing
swift run -c release -Xswiftc -enable-testing SimTests
```

`-Xswiftc -enable-testing` is not optional. `SimTests` is a plain executable target that
`@testable import`s `ProFootballCoachUI`, and a release build does not enable testability the way
a debug build happens to, so without it every `@testable` target fails with "module ... was not
compiled for testing". `scripts/verify.sh` passes it on both the build and the run.

A run counts only if it ends with TestKit's `N tests, M checks` summary. A Swift `precondition`
is a SIGTRAP that kills the process mid-run and silently skips every later suite, so a lane that
stops short of that line is truncated, not green; `verify.sh` fails the lane on a missing summary.

To build and run the iOS app you need full Xcode and
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (a build-time tool, not an app dependency):

```bash
xcodegen generate --spec App/project.yml && open App/ProFootballCoach.xcodeproj
```

If `xcodebuild` reports no simulator destinations, the iOS platform component is missing:
`xcodebuild -downloadPlatform iOS` installs it.

**On claiming a green build.** Agent environments frequently have no `swift` and no `xcodebuild`.
Where the toolchain is absent, code is written to the same standard and recorded in
`docs/STATUS.md` as **unverified — never compiled**, naming the files. Nothing is reported as "build
green" or "tests pass" that a compiler has not seen in the session making the claim.
