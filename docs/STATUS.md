# Build Status

## Current state — 2026-08-09

**The project has pivoted.** It is no longer a pro-only franchise sim with a direct-control arcade
mode; it is a **unified college→pro career simulator in which the player never controls an athlete**
(`docs/DOC-MANIFEST.md`, `docs/08-OPUS5-BUILD-PROMPT.md`).

| | |
|---|---|
| **Spec package** | Complete. Canon rewritten; anti-canon archived |
| **Rebuild code** | **None written.** Phase P0 has not started |
| **Existing `Sources/`, `Tests/`, `App/`** | **Tier C — no authority.** Retained as evidence, not as a foundation |
| **Next action** | An Opus 5 session per `docs/08-OPUS5-BUILD-PROMPT.md`, entering at **P0 — Foundations** |

### Owner actions outstanding

Three blocking questions are at the top of `docs/OPEN-DECISIONS.md`:

1. **B1 — run the engagement post-mortem** (`01-RESEARCH.md` §6.0a): six weeks with a stopwatch,
   thresholds fixed in advance. The single most consequential decision in the project (D1) currently
   rests on arithmetic and inference because **the build could not be played in the spec session** —
   no `swift`, no Xcode, no simulator, and `download.swift.org` refused by egress. Needed **before
   P7 closes**.
2. **B2 — confirm the calibration-source licensing posture**, or take it to counsel.
3. **B3 — run `/impeccable audit` once** so `04b-AUDIT-RUBRIC.md`'s anchors can be made verbatim
   rather than reconstructed. Every phase gate cites that rubric.

### Verification reality

No part of the spec package has been compiled, because there is nothing to compile yet. The rules
that will govern this from P0 onward are in `CLAUDE.md` (*Honesty about verification*) and D11: the
suite runs as an executable target with a hand-rolled harness, and anything not compiled is named
here as **unverified** rather than described as done.

---

# Historical — the prior build (pro-only, superseded)

Everything below describes the **abandoned product** and is retained as Tier B evidence. Its
calibration bands, soak invariants, determinism fix, save-growth lesson and practice-squad rules are
carried forward as knowledge into `docs/03-MATCH-ENGINE.md` and `docs/02-GAME-DESIGN.md`. Its code
is not.

Every phase gate in the prior `05-IMPLEMENTATION-PLAN.md` and every line of the definition of done in
the prior `00-EXECUTIVE-PLAN.md` was met. This is the honest picture of what existed, what was
verified, and the one thing left that no amount of tooling could settle.

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

**224 tests, 13,226 assertions, all passing.** Runtime about 100 seconds, dominated by the
ten-season soak.

## Complete and tested

| Area | State |
|---|---|
| Deterministic RNG, seeded UUIDs | Done, and now true across processes as well as within one. The AI's free-agent bidding seeded a generator from `UUID.hashValue`, which Swift salts per launch, so the same save seed produced a different league every time the app started — the in-process determinism test could never see it. Seeds are derived from identifier bytes, and a test scans the engine sources so no future line can reintroduce it |
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
| Practice squad cannot launder the cap | A practice-squad player is charged a stipend, which made the squad the obvious place to hide a contract. Sending a signed veteran down wiped his cap hit, releasing him afterwards erased his dead money, and a "practice squad" free-agent offer was validated against the cap and then never charged. A squad place now requires squad money, dead money follows the contract rather than a flag, and a call-up is paid for |
| Practice squad: call up, send down | Done: `CapEngine.elevate` / `demote` with a positional floor, seven tests, swipe actions on the depth chart. Both refusal paths seen on device |
| The coach's own career: sacked, extended, re-hired | Done. The engine could always produce job offers but nothing called them, so a coach could sit through a decade of losing seasons and keep his desk. The carousel now settles his job in the same window as his assistants': zero-ish security or an expired deal without the results to back it puts him on the market, a secure coach is extended where he is, and the offers persist through a save so being out of work survives a reload |
| Save size after ten seasons | 2.3 MB, inside the plan's 5 MB budget and asserted by the soak. It was 8.3 MB: the free-agent pool and the news feed both grew without limit, reaching nine thousand unsigned players and eight thousand stories. Both are now bounded, which also stops every free-agency scan getting slower each year |
| Save / load, backup recovery, version refusal | Done, and forward-compatible: unknown-field defaults mean an older save still opens |
| Light and dark, small screen and large | Walked on an iPhone 17 Pro Max and an iPhone 17e, both appearances. The control tint is now lifted for the dark scheme: a bordered button draws its label in the tint over a wash of the same tint, so a navy team was rendering its own buttons dark-on-dark. A test checks every team's lifted tint against the dark page at 4.5:1 |
| Accessibility of rating colours | Done: every tier verified at 4.5:1 on card, page and chip tint in both themes, with the tier spoken to VoiceOver |
| SwiftUI app: menu, wizard, season hub, schedule, standings, news, team, depth chart, player cards, stats, front office, draft board, coach, offseason pipeline, both play modes | Built and run on an iPhone simulator; core path walked by hand |

## Phase 4C — the all-22 arcade field — is written but NOT compiled

This is the one thing on this page that has never been near a compiler, and it should be read
as unverified until it has.

The session that wrote it had no Swift toolchain: `swift` is absent from the container, Ubuntu's
archive carries only the unrelated OpenStack "swift" packages, there is no Docker daemon, and
`download.swift.org` is refused by the organisation's egress policy (a `403` on `CONNECT`, which
the proxy's own documentation says to report rather than route around). So neither
`swift build` nor `swift run -c release SimTests` was run against any of it.

What stood in for the compiler was a multi-agent adversarial review: independent passes for
symbol and signature existence, for `mutating`/initialisation/access-control rules, for pattern
matching and closure inference, and for runtime correctness, each finding then handed to a
separate agent whose brief was to refute it. That catches a great deal and it is not the same
thing as a build. **Before trusting any of Phase 4C, run the two commands at the top of this
file on a machine that has the tools.**

What was added, all of it under that caveat:

| Area | State |
|---|---|
| `SnapKernel` and the spatial layer | Written: formations, routes vs live coverage, per-matchup protection duels, run lanes, carrier pursuit, openness. Pure, seeded, headless-testable |
| Grades → `PlayExecution` | Written. The engine still owns every probability; the field only measures |
| Execution ceilings | Widened to ±20 points of completion and ±6 yards, moved into `ArcadeTuning` and asserted rather than trusted |
| `Choreographer` | Written: engine-resolved plays become all-22 motion whose last frame is pinned to the recorded yardage |
| Defensive reads | Written: shade, timed break, run commit — scored inside the simulator once the offence's call is drawn, capped at ±10 points combined |
| `FieldCanvas` renderer, model, shell view | Written, never run |
| Tests | ~60 new cases across three suites, including the honesty, reconciliation and fidelity invariants and a scripted-thumbs balance soak. Never executed |
| Portrait lock | `App/project.yml` now declares portrait only, which is the root cause behind the audit's landscape findings |

## Known gaps

Ordered by how much they would be missed.

0. **Phase 4C has not been compiled or run** — see the section above. Everything below predates
   it and was verified normally.

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
