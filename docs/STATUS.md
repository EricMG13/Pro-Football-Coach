# Build Status

Last updated at the end of the initial build session. This is the honest picture of what
exists, what is verified, and what is still on the list.

## How this was verified

The machine this was built on has the Swift 6.3 command line tools but **not** full Xcode, so
`xcodebuild` and the iOS Simulator were unavailable. Two consequences shaped the project:

1. Neither XCTest nor swift-testing ships with the Command Line Tools, so the suite runs as an
   executable target with a small hand-rolled harness (`Tests/SimTests/TestKit.swift`). It
   reports real pass/fail counts and exits non-zero on failure.
2. Both library targets — engine *and* SwiftUI — build for macOS as well as iOS, so the whole
   codebase is compile-verified from the command line even without Xcode.

The app has since been built and run on an iPhone simulator under Xcode 26.6. The full path
was exercised by hand: menu → four-step wizard → franchise created → season kicked off →
week 1 played through the play-by-play → box score → app relaunched → save loaded → team,
depth chart and player card. To build the Xcode project:

```bash
brew install xcodegen && xcodegen generate --spec App/project.yml
```

If `xcodebuild` reports no simulator destinations, the iOS platform component is missing —
`xcodebuild -downloadPlatform iOS` installs it.

```bash
swift build && swift run -c release SimTests
```

**193 tests, ~12,900 assertions, all passing.** Runtime about 100 seconds, dominated by the
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
| Draft day, played pick by pick | Done: AI picks resolve automatically, the board stops when you are on the clock |
| On the Field: call plays, drag to aim, throw under pressure | Done and played on device; the same engine resolves it as a simmed game |
| Re-signing your own expiring players | Done: asking price, acceptance odds and a three-round negotiation |
| Save / load, backup recovery, version refusal | Done, and forward-compatible: unknown-field defaults mean an older save still opens |
| Accessibility of rating colours | Done: every tier verified at 4.5:1 on card, page and chip tint in both themes, with the tier spoken to VoiceOver |
| SwiftUI app: menu, wizard, season hub, schedule, standings, news, team, depth chart, player cards, stats, front office, draft board, coach, offseason pipeline, both play modes | Built and run on an iPhone simulator; core path walked by hand |

## Known gaps

Ordered by how much they would be missed.

1. **Practice squad elevation** and in-season street free-agent signing are engine-supported but
   not surfaced.
2. **Tutorial and trophy room** are not built.
3. **On the Field** covers play calling, drag-to-aim passing and the pass rush. Carrier control
   after the catch and the two-tap kick meter are still to come; `ArcadeInput` already scores
   both, so they need the gestures rather than any new engine work.

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
