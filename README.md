# Pro Football Coach

A unified college→pro football **coaching** career simulator for iPhone. One save, one coach: you
start in the college game and get promoted to the pro league. SwiftUI, offline, zero third-party
dependencies.

You are a coach, never a player. There is **no direct control of players during play** — no arcade
mode, no throwing passes. Matches are watched in a 2D view and shaped by roster construction, scheme
identity, opponent preparation, staff and in-game decisions. Every school, team, conference, city,
stadium, player and coach is fictional and original.

> **Status: P0 through P3 are complete. P4's instrument is built and the engine it measures is
> not yet calibrated.** There is a foundation, a model, two rules modules, a world generator, and
> a match engine that plays a whole game from a seed and records why every play happened.
> Suite: **243 tests, 74,796 checks**, byte-identical across separate process invocations.
>
> **P5 through P17 have not started** — the off-screen model, seasons, both tiers' systems, the
> career arc, the AI, the design system and every view are ahead.
>
> The UI has a **rendered reference library**: sixteen `*-v2.dc.html` sheets at the repository
> root, indexed in [`docs/04-UX-AND-DESIGN-SYSTEM.md`](docs/04-UX-AND-DESIGN-SYSTEM.md). The rules
> live in `04`; the sheets are a rendering of them. A value that appears only in a sheet has not
> shipped.
>
> [`docs/STATUS.md`](docs/STATUS.md) is the honest picture and takes precedence over this
> paragraph. [`docs/HANDOFF-2026-08-10.md`](docs/HANDOFF-2026-08-10.md) is the cold-start pointer.

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
| [`docs/04b-AUDIT-RUBRIC.md`](docs/04b-AUDIT-RUBRIC.md) | Audit rubric: five dimensions, 0–4 anchors, P0–P3 severities |
| [`docs/05-IMPLEMENTATION-PLAN.md`](docs/05-IMPLEMENTATION-PLAN.md) | Phased build with per-phase gates |
| [`docs/06-AUDIT-DISPOSITION.md`](docs/06-AUDIT-DISPOSITION.md) | Prior audit's P0/P1s and systemic patterns, converted into tests |
| [`docs/08-OPUS5-BUILD-PROMPT.md`](docs/08-OPUS5-BUILD-PROMPT.md) | Phase-entry prompt. Owns mission and definition of done |
| [`docs/OPEN-DECISIONS.md`](docs/OPEN-DECISIONS.md) | Decision register D1–D14, each with an instrumented falsifier |
| [`docs/PORT-LOG.md`](docs/PORT-LOG.md) | What survives from the previous build, with a logged reason both ways |
| [`docs/PRE-DEPLOYMENT-CHECKLIST.md`](docs/PRE-DEPLOYMENT-CHECKLIST.md) | What must be true before a build goes out |
| [`docs/STATUS.md`](docs/STATUS.md) | Honest state of the build: what exists, what is verified, what is not |
| [`docs/AUDIT.md`](docs/AUDIT.md) | Prior UI audit — evidence about craft, retained read-only |
| [`PRODUCT.md`](PRODUCT.md) | Positioning, audience, market gap, v1 scope |
| *(no archive)* | The superseded documents were deleted on 2026-08-10. `docs/DOC-MANIFEST.md` records what each was and why it went; `git show` recovers any of them |

## Non-negotiables

- **Fictional and original IP only.** No real school, team, conference, player or coach names, no
  real logos, colours, fight songs or broadcast identities. No importer, no "community" real-name
  files, no wink in the store listing. Two of these become shipping tests — a name-collision test
  against a blocklist, and a trade-dress test on generated colour pairs. Neither exists yet; both are
  gates on the generation phase (P2).
- **Determinism.** A given seed plus a given input state reproduces a match exactly, across processes
  and app launches. Seeds derive from identifier bytes, never from `hashValue`.
- **Offline, single-player.** No network, no accounts, no analytics, no ads, no IAP, no subscriptions.
- **iPhone-only, landscape-only, iOS 17+, zero third-party dependencies.** The 2D match view renders
  in SwiftUI `Canvas` + `TimelineView` — no SpriteKit, no Metal.
- **A full season is completable in 6–8 hours of play.**

## Layout

| Path | What |
|---|---|
| `docs/` | Design and planning documents. Start at `docs/DOC-MANIFEST.md` |
| *(no archive)* | Deleted 2026-08-10. See `docs/DOC-MANIFEST.md` |
| `docs/plans/` | Per-phase task plans, one per phase, written before that phase is built |
| `*-v2.dc.html` | The rendered UI reference library. Indexed in `docs/04-UX-AND-DESIGN-SYSTEM.md` |
| `docs/reviews/` | The governing brief and the review that produced it |
| `Sources/FootballSimCore/` | The engine — pure Swift, no UI imports, seeded RNG. P0–P4 |
| `Sources/ProFootballCoachUI/` | The SwiftUI layer. Empty until P11 |
| `Tests/SimTests/` | The suite and its hand-rolled harness |
| `App/` | Thin `@main` iOS shell + `project.yml` for Xcode project generation |
| `scripts/verify.sh` | Runs both machine gates and prints a pasteable result |

The previous build was removed by P0; what is under `Sources/`, `Tests/` and `App/` now is the
rebuild. `docs/PORT-LOG.md` records what survived and why, both ways.

## Building

```bash
./scripts/verify.sh
```

That is the gate: `swift build`, then the suite. Pass `--build` for the build alone.

Both library targets — engine *and* SwiftUI — build for macOS as well as iOS, so the codebase is
compile-verified from the command line without full Xcode. Neither XCTest nor swift-testing ships
with the Swift Command Line Tools, so the suite is an **executable target** with a hand-rolled
harness (`Tests/SimTests/TestKit.swift`); it reports real pass/fail counts and exits non-zero on
failure. The two commands underneath are:

```bash
swift build && swift run -c release SimTests
```

To build and run the iOS app you need full Xcode and
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (a build-time tool, not an app dependency):

```bash
xcodegen generate --spec App/project.yml && open ProFootballCoach.xcodeproj
```

If `xcodebuild` reports no simulator destinations, the iOS platform component is missing:
`xcodebuild -downloadPlatform iOS` installs it.

**On claiming a green build.** Agent environments frequently have no `swift` and no `xcodebuild`.
Where the toolchain is absent, code is written to the same standard and recorded in
`docs/STATUS.md` as **unverified — never compiled**, naming the files. Nothing is reported as "build
green" or "tests pass" that a compiler has not seen in the session making the claim.
