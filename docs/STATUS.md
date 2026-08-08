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

**209 tests, 13,156 assertions, all passing.** Runtime about 100 seconds, dominated by the
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
| On the Field: call plays, drag to aim, throw under pressure, fourth-down kicks, carrier decision | Play calling, aiming and the kick meter played on device — a 51-yard field goal made through the meter. The carrier window resolves correctly but its UI has not been seen (see gap 3) |
| Re-signing your own expiring players | Done: asking price, acceptance odds and a three-round negotiation |
| First-run tutorial | Done: five cards on the job, shown once when a franchise opens and reopenable from the Coach tab |
| Trophy room | Done: titles, conference finals and your players' awards, with a career line that counts the season in progress |
| Street free agency, in season | Done: the free-agent board is open all year, with a practice-squad option on the offer sheet and a refusal that names the door that shut — roster full, squad full, or the amount over the cap |
| Practice squad: call up, send down | Done: `CapEngine.elevate` / `demote` with a positional floor, seven tests, swipe actions on the depth chart. Both refusal paths seen on device |
| Save size after ten seasons | 2.3 MB, inside the plan's 5 MB budget and asserted by the soak. It was 8.3 MB: the free-agent pool and the news feed both grew without limit, reaching nine thousand unsigned players and eight thousand stories. Both are now bounded, which also stops every free-agency scan getting slower each year |
| Save / load, backup recovery, version refusal | Done, and forward-compatible: unknown-field defaults mean an older save still opens |
| Light and dark, small screen and large | Walked on an iPhone 17 Pro Max and an iPhone 17e, both appearances. The control tint is now lifted for the dark scheme: a bordered button draws its label in the tint over a wash of the same tint, so a navy team was rendering its own buttons dark-on-dark. A test checks every team's lifted tint against the dark page at 4.5:1 |
| Accessibility of rating colours | Done: every tier verified at 4.5:1 on card, page and chip tint in both themes, with the tier spoken to VoiceOver |
| SwiftUI app: menu, wizard, season hub, schedule, standings, news, team, depth chart, player cards, stats, front office, draft board, coach, offseason pipeline, both play modes | Built and run on an iPhone simulator; core path walked by hand |

## Known gaps

Ordered by how much they would be missed.

1. **The arcade's carrier window is still untuned.** Two of the three timed inputs are now
   verified on device. Release timing is measurable exactly, because the pass rush starts when
   the player begins aiming rather than at the snap: a timed touch path held for one second
   against a three-second pocket produced a clean-timing completion. The carrier decision was
   seen and used — "Ball's away", the draining bar, Fight for Yards and Secure It — by
   temporarily widening the window to thirty seconds; the same throw that resolves for ten yards
   on no decision went for twelve when told to fight, which is the yardage modifier arriving as
   designed. What that build also measured is why the shipped durations remain guesses: the
   tooling round trip is about seven seconds, against a live window of 2.5 seconds for a pass
   and 3.5 for a run. Those two numbers need a real thumb, and nothing short of one will do.

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
