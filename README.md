# Pro Football Coach

Native iOS pro-football franchise simulator. SwiftUI, offline, zero third-party dependencies, iPhone only.

- **Building it:** [docs/08-OPUS5-BUILD-PROMPT.md](docs/08-OPUS5-BUILD-PROMPT.md) — the kickoff prompt, and the canon reading order
- **The plan:** [docs/05-IMPLEMENTATION-PLAN.md](docs/05-IMPLEMENTATION-PLAN.md) — phases and their gates
- **Why it is the way it is:** [docs/research/R2-synthesis.md](docs/research/R2-synthesis.md) — the verdict, rulings, and pillars
- **Gameplay canon:** [docs/02-GAME-DESIGN.md](docs/02-GAME-DESIGN.md)
- **Design system:** [DESIGN.md](DESIGN.md)
- **Agent instructions:** [CLAUDE.md](CLAUDE.md)

## Layout

| Path | What |
|---|---|
| `Sources/FootballSimCore/` | Simulation engine — pure Swift, no UI imports, deterministic under a seeded RNG |
| `Sources/ProFootballCoachUI/` | SwiftUI feature layer |
| `Tests/SimTests/` | Engine, calibration, soak, and design-system suites |
| `App/` | Thin `@main` iOS shell + `project.yml` for Xcode project generation |
| `docs/` | Canon: design, architecture, plan, research |

Both library targets build on macOS, so engine *and* SwiftUI views are compile-verified from the command line without Xcode. The suite is an executable target, not XCTest — run it, don't `swift test`:

```bash
swift build && swift run -c release SimTests
```

## Building the iOS app

Requires full Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec App/project.yml && open App/ProFootballCoach.xcodeproj
```

If `xcodebuild` reports no simulator destinations, install the platform:

```bash
xcodebuild -downloadPlatform iOS
```
