# Build Status

Last updated at the end of the initial build session. This is the honest picture of what
exists, what is verified, and what is still on the list.

## How this was verified

The machine this was built on has the Swift 6.3 command line tools but **not** full Xcode, so
`xcodebuild` and the iOS Simulator were unavailable. Two consequences shaped the project:

1. Neither XCTest nor swift-testing ships with the Command Line Tools, so the suite runs as an
   executable target with a small hand-rolled harness (`Tests/SimTests/TestKit.swift`). It
   reports real pass/fail counts and exits non-zero on failure.
2. Both library targets — engine *and* SwiftUI — build for macOS as well as iOS, so the entire
   codebase is compile-verified from the command line. The iOS app target itself is a thin
   `@main` shell that has not been launched on a simulator.

```bash
swift build && swift run -c release SimTests
```

**152 tests, ~4,000 assertions, all passing.** Runtime about 100 seconds, dominated by the
ten-season soak.

## Complete and tested

| Area | State |
|---|---|
| Deterministic RNG, seeded UUIDs | Done. Same seed reproduces a league byte for byte |
| Player / contract / team / league model | Done, including cap, proration and dead money |
| League generation (32 teams, tiers, staff) | Done |
| Game simulation | Done: drives, downs, clock, kicks, overtime, injuries, box scores |
| Calibration | Scoring, yardage, completion rate, sacks, turnovers, kicking, home advantage, fourth-quarter share, explosive plays and target distribution all asserted inside realistic bands |
| Schedule generation | Done: the real 17-game formula, one bye each in the legal window |
| Standings, tiebreakers, playoffs | Done, and all three playoff formats verified to resolve cleanly |
| Free agency, trades, cuts, cap enforcement | Done |
| Draft: class generation, scouting fog, order, AI picks | Done |
| Progression, retirement, awards, coaching carousel | Done |
| Coach career: XP, skill trees, goals, job security | Done |
| Ten-season soak | Done: ratings, ages, roster sizes, cap legality, churn and save size all hold |
| Scenarios (Cap Hell, Expansion, Aging Legend) | Done, each verified to leave a legal league |
| Record book and Hall of Fame | Done: seeded marks, live record chasing, enshrinement on retirement |
| Save / load, backup recovery, version refusal | Done |
| SwiftUI app: menu, wizard, season hub, schedule, standings, news, team, depth chart, player cards, stats, front office, draft board, coach, offseason pipeline, both play modes | Written and compile-verified; not yet exercised on a simulator |

## Known gaps

Ordered by how much they would be missed.

1. **Nothing has run on a device or simulator.** Every view compiles and the state layer is
   tested, but no screen has been seen. This is the first thing to do on a machine with Xcode:
   `xcodegen generate --spec App/project.yml`, then run.
2. **Re-sign negotiation UI.** The engine re-signs for AI teams and the free-agency offer sheet
   exists; the user's own expiring contracts are visible but not yet negotiable in the UI.
3. **Draft-day UI.** Scouting and the board are built; the user's picks are currently made by
   the same AI selection the other 31 teams use when the draft stage runs.
4. **Practice squad elevation** and in-season street free-agent signing are engine-supported but
   not surfaced.
5. **Tutorial and trophy room** are not built.
6. **On the Field** is a field view over the resolved game rather than the full arcade control
   scheme in `06-PLAYED-GAME-MODE.md`. Drag-to-aim passing, carrier control and the kick meter
   are the remaining work, and the engine already exposes what they need.

## Deliberate design decisions worth knowing

- **One engine, one truth.** Watched, simmed and arcade games all run the same simulation, and a
  test asserts that retaining the play-by-play cannot change a result. The reference games this
  learns from diverged here, and players noticed.
- **The carousel can never dead-end.** A coach whose contract expires always has at least one
  offer or an explicit year out. The equivalent situation soft-locks saves in the college game.
- **Cap hell is real but bounded.** Dead money can leave a team briefly over the cap, because
  accelerated proration cannot itself be cut away. The soak test allows a small overage and
  fails on a large one.
- **Saves stay small.** Stat lines omit zero fields when encoding and finished seasons keep
  aggregates rather than play-by-play; ten seasons come in well under the size budget.
