# Pro Football Coach

A **unified college→pro career simulator** for iPhone. One save, one coach: take a college
programme, win with it, get promoted to the pro league, and carry your reputation, your staff and
your scheme identity with you.

You never control a player. You call the game from the sideline: game plan, personnel, tempo,
fourth downs, timeouts, in-drive adjustments. The match plays out on a 2D all-22 field you can
watch, steer, or skip.

Native SwiftUI. Offline. No accounts, no ads, no analytics, no in-app purchases.

## Start here

1. **[`docs/DOC-MANIFEST.md`](docs/DOC-MANIFEST.md)** — what is canon and what is archived history.
   Read this before trusting any other document. Much of `docs/archive/` describes a different,
   abandoned product.
2. **[`CLAUDE.md`](CLAUDE.md)** — standing rules for anyone, human or agent, working in this repo.
3. **[`docs/08-OPUS5-BUILD-PROMPT.md`](docs/08-OPUS5-BUILD-PROMPT.md)** — the mission, the definition
   of done, and the contract for picking up the next phase cold.
4. **[`docs/02-GAME-DESIGN.md`](docs/02-GAME-DESIGN.md)** — the game itself.

Current build state, including anything that has been written but never compiled, is in
[`docs/STATUS.md`](docs/STATUS.md).

## Layout

| Path | What |
|---|---|
| `Sources/FootballSimCore/` | Simulation engine — pure Swift, no UI imports, deterministic under a seeded RNG |
| `Sources/ProFootballCoachUI/` | SwiftUI feature layer (views + `@Observable` view models) |
| `Tests/SimTests/` | Engine unit, property, calibration and soak tests |
| `App/` | Thin `@main` iOS shell + `project.yml` for Xcode project generation |
| `docs/` | Canon (see the manifest) |
| `docs/archive/` | The abandoned product. History, not instruction. |

## Building and testing

Both library targets build for macOS as well as iOS, so the whole codebase — engine *and* views —
is compile-verified from the command line without Xcode:

```bash
swift build && swift run -c release SimTests
```

The suite runs as an **executable target** with a hand-rolled harness
(`Tests/SimTests/TestKit.swift`), not XCTest and not swift-testing: neither ships with the Swift
Command Line Tools. It reports real pass/fail counts and exits non-zero on failure. See D11 in
[`docs/OPEN-DECISIONS.md`](docs/OPEN-DECISIONS.md).

### The iOS app

Requires full Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec App/project.yml && open ProFootballCoach.xcodeproj
```

If `xcodebuild` reports no simulator destinations, the iOS platform component is missing:
`xcodebuild -downloadPlatform iOS`.

> **Agent sessions frequently have no Swift toolchain at all.** That is expected. Work continues and
> anything uncompiled is labelled **unverified** in `docs/STATUS.md` by name — never described as
> done. Simulator demonstration is an owner action, handed over as a written walkthrough script.

## Legal

Every team, school, conference, stadium, city identity, player, coach, mark, colour pairing and
tradition in this project is **fictional and original**. No real-name roster files, no importer
aimed at real identities, no wink in the store listing. Two parts of that guardrail are enforced by
tests — a name-collision test and a colour trade-dress test; the rest is a review checklist.
Details in [`CLAUDE.md`](CLAUDE.md).
