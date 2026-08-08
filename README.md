# Pro Football Coach

Native iOS pro-football franchise simulator. SwiftUI, offline, zero third-party dependencies.

- **Start here:** [docs/00-EXECUTIVE-PLAN.md](docs/00-EXECUTIVE-PLAN.md)
- **Gameplay canon:** [docs/02-GAME-DESIGN.md](docs/02-GAME-DESIGN.md)
- **Agent instructions:** [CLAUDE.md](CLAUDE.md)

## Layout

| Path | What |
|---|---|
| `Sources/FootballSimCore/` | Simulation engine — pure Swift, no UI imports, deterministic under a seeded RNG |
| `Sources/ProFootballCoachUI/` | SwiftUI feature layer (views + view models) |
| `Tests/FootballSimCoreTests/` | Engine unit, property, and calibration tests |
| `App/` | Thin `@main` iOS shell + `project.yml` for Xcode project generation |
| `docs/` | Design and planning documents |

Both library targets build on macOS, so the full codebase — engine *and* SwiftUI views —
is compile-verified and test-verified from the command line without Xcode:

```bash
swift test
```

## Building the iOS app

Requires full Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec App/project.yml && open ProFootballCoach.xcodeproj
```
