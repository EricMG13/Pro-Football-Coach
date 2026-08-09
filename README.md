# Pro Football Coach

A unified college→pro football **coaching** career simulator for iPhone. One save, one coach: you
start in the college game and get promoted to the pro league. SwiftUI, offline, zero third-party
dependencies.

You are a coach, never a player. There is **no direct control of players during play** — no arcade
mode, no throwing passes. Matches are watched in a 2D view and shaped by roster construction, scheme
identity, opponent preparation, staff and in-game decisions. Every school, team, conference, city,
stadium, player and coach is fictional and original.

> **Status: ground-up rebuild in progress.** The design and planning package is being authored now.
> The code under `Sources/`, `Tests/` and `App/` is the *previous* build — a pro-only franchise sim
> with an arcade mode — and carries **no authority** over the rebuild. Do not treat it as a
> specification, and do not assume any of it survives.

## Start here

1. **[`docs/DOC-MANIFEST.md`](docs/DOC-MANIFEST.md)** — what is canon, what was archived and why,
   and which canon documents have not been written yet. Read this before opening anything else in
   `docs/`. A document not marked `RETAINED` there carries no authority, whatever path it sits at.
2. **[`CLAUDE.md`](CLAUDE.md)** — standing rules for every session: process, tech stack, conventions,
   the legal guardrail.
3. **[`docs/reviews/2026-08-09-spec-prompt-v4.md`](docs/reviews/2026-08-09-spec-prompt-v4.md)** — the
   governing brief. Owner parameters, authority tiers, the core design problem, the deliverable list.
   Where any other document disagrees with it, the other document is wrong.

Once the package is complete, `docs/08-OPUS5-BUILD-PROMPT.md` becomes the entry point for a build
session: it owns the mission and the definition of done, and it runs one phase at a time.

## Document map

`docs/DOC-MANIFEST.md` is the authority; this table is the short version.

| Doc | Purpose | State |
|---|---|---|
| [`docs/DOC-MANIFEST.md`](docs/DOC-MANIFEST.md) | Canon, superseded, archived | Written |
| [`CLAUDE.md`](CLAUDE.md) | Standing rules for every session | Written |
| [`docs/01-RESEARCH.md`](docs/01-RESEARCH.md) | Reference research, competitive set, community signal, calibration sources | Retained, being extended |
| [`docs/AUDIT.md`](docs/AUDIT.md) | Prior UI audit — evidence about craft | Retained, read-only |
| [`docs/STATUS.md`](docs/STATUS.md) | Honest state of the build: what exists, what is verified, what is not | Retained, live |
| `docs/02-GAME-DESIGN.md` | The game: core loop, agency model, both tiers, promotion arc, systems, stakes | Not yet written |
| `docs/03-MATCH-ENGINE.md` | Play resolution, seeding contract, off-screen model, calibration harness, soak | Not yet written |
| `docs/03b-ARCHITECTURE.md` | Module layout, engine/UI boundary, save architecture, test architecture | Not yet written |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | Design system, screens, match view, accessibility contract | Not yet written |
| `docs/04b-AUDIT-RUBRIC.md` | Audit rubric: five dimensions, 0–4 anchors, P0–P3 severities | Not yet written |
| `docs/05-IMPLEMENTATION-PLAN.md` | Phased build with per-phase gates | Not yet written |
| `docs/06-AUDIT-DISPOSITION.md` | Prior audit's P0/P1s and systemic patterns, converted into tests | Not yet written |
| `docs/OPEN-DECISIONS.md` | Decision register D1–D13, each with an instrumented falsifier | Not yet written |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | What must be true before a build goes out | Not yet written |
| `docs/08-OPUS5-BUILD-PROMPT.md` | Phase-entry prompt. Owns mission and definition of done | Not yet written |
| `PRODUCT.md` | Positioning, audience, market gap, v1 scope | Not yet written |
| [`docs/archive/`](docs/archive/) | History. No authority, nothing here is a specification | Archived |

## Non-negotiables

- **Fictional and original IP only.** No real school, team, conference, player or coach names, no
  real logos, colours, fight songs or broadcast identities. No importer, no "community" real-name
  files, no wink in the store listing. Two of these are shipping tests: a name-collision test against
  a blocklist, and a trade-dress test on generated colour pairs.
- **Determinism.** A given seed plus a given input state reproduces a match exactly, across processes
  and app launches. Seeds derive from identifier bytes, never from `hashValue`.
- **Offline, single-player.** No network, no accounts, no analytics, no ads, no IAP, no subscriptions.
- **iPhone-only, portrait-only, iOS 17+, zero third-party dependencies.** The 2D match view renders
  in SwiftUI `Canvas` + `TimelineView` — no SpriteKit, no Metal.
- **A full season is completable in 6–8 hours of play.**

## Layout

| Path | What |
|---|---|
| `docs/` | Design and planning documents. Start at `docs/DOC-MANIFEST.md` |
| `docs/archive/` | Superseded documents, kept as history. No authority |
| `docs/plans/` | Per-phase task plans, one per phase, written before that phase is built |
| `docs/reviews/` | The governing brief and the review that produced it |
| `Sources/FootballSimCore/` | Prior simulation engine — pure Swift, no UI imports, seeded RNG |
| `Sources/ProFootballCoachUI/` | Prior SwiftUI feature layer (views + view models) |
| `Tests/SimTests/` | Prior test suite and its hand-rolled harness |
| `App/` | Thin `@main` iOS shell + `project.yml` for Xcode project generation |

Everything under `Sources/`, `Tests/` and `App/` is the previous implementation and is retained as
readable prior art only. `build/` and `App/build/` are committed Xcode build output, not source.

## Building the previous implementation

These instructions describe the code as it stands today. The rebuild's project structure, test
mechanism and toolchain policy are decided in `docs/03b-ARCHITECTURE.md`; until that lands, do not
assume these commands are the long-term answer.

Both library targets — engine *and* SwiftUI — build for macOS as well as iOS, so the codebase is
compile-verified from the command line without full Xcode:

```bash
swift build
```

Neither XCTest nor swift-testing ships with the Swift Command Line Tools, so the suite is an
**executable target** with a hand-rolled harness (`Tests/SimTests/TestKit.swift`). It reports real
pass/fail counts and exits non-zero on failure:

```bash
swift run -c release SimTests
```

To build and run the iOS app you need full Xcode and
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (a build-time tool, not an app dependency):

```bash
xcodegen generate --spec App/project.yml && open ProFootballCoach.xcodeproj
```

If `xcodebuild` reports no simulator destinations, the iOS platform component is missing:
`xcodebuild -downloadPlatform iOS` installs it.

Agent environments frequently have **no `swift` and no `xcodebuild`**. When the toolchain is absent,
code is written to the same standard and recorded in `docs/STATUS.md` as **unverified — never
compiled**. Nothing is ever reported as "build green" or "tests pass" that a compiler has not seen.
