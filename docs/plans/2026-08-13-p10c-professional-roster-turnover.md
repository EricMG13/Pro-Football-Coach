# P10c — professional roster turnover: root cause and implementation plan

Written 2026-08-13, in a session with no Swift toolchain (confirmed: `swift`/`swiftc`/`xcodebuild`
all absent). Per `CLAUDE.md`'s no-toolchain rule this is a plan, not a landed change: the diagnosis
below is traced by reading the source, not by running it, and every fix candidate below still needs
a toolchain session to implement, recompute the pinned fingerprints, and run `--pro-soak`,
`--pro-draft-probe` and `--pro-week-walk` before it can be called done. Nothing here may be cited as
verified.

## What blocks P10c, restated precisely

`docs/STATUS.md`'s "the professional soak" section and `docs/FUTURE-SIMULATION-CONTRACT.md` FSC-013
already diagnose this at the product level: bootstrap professionals carry no contracts, so nothing
ever expires, so the roster never opens a seat for free agency or the draft to fill. A 2026-08-12
attempt to fix it by giving bootstrap professionals staggered contracts worked in isolation but broke
`WorldIntegrity` at season 0 week 21, because releasing ~315 players mid-rollover invalidated the
participant record of every game they had just played that season.

**This plan adds the exact code-level mechanism**, traced 2026-08-13:

1. `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`, `.jobAndStaffMarkets` case (currently
   lines ~359–539). At the final week (`completed.week == SharedRules.inSeasonWeeks`) it calls, in
   this order:
   - `resolveExpiredWaivers` (line ~368)
   - `ProMarketSystem.expireContracts` (line ~383) — **this is the release**
   - `ProMarketSystem.close` (line ~402)
   - `CollegeRecruitingMarketSystem.process` (line ~418)
   - `SeasonLifecycleSystem.advance` → `peopleTransition` (line ~430, unconditional every week)
   - `CareerArcSystem.evaluateSeasonEnd` + `PostseasonSystem.completeSeason` (lines ~435–453) —
     **this is where the season's games leave `competition.currentSchedule` and enter
     `competition.archives`**
   - `peopleTransition` gets applied to `nextState.programmes/proTeams/players/staff/people`
     (lines ~455–459)
   - `ProgrammeEvolutionSystem`, college cycle close/open, portal resolution, walk-ons,
     `ProMarketSystem.openOffseason` (lines ~460–530)

2. `Sources/FootballSimCore/Pro/ProMarketSystem.swift`, `expireContracts` (currently lines
   ~412–476) ends with `guard WorldIntegrity.check(next).isValid else { throw
   ProMarketError.invalidRoot }` — it self-validates the *whole root* immediately after releasing
   players, which is **before** step 1's `PostseasonSystem.completeSeason` has archived the season.

3. `Sources/FootballSimCore/Integrity/WorldIntegrity.swift`, `checkSchedule` (currently lines
   ~614–678) only walks `state.competition.currentSchedule.games`; `validResultParticipants`
   (currently lines ~680–704) checks each game's recorded participants against the team's **live**
   roster (`state.proTeams[game.homeID]?.rosterIDs`, not a historical snapshot).
   `checkCompetitionHistory` (currently lines ~706–758), which walks `state.competition.archives`,
   never calls `validResultParticipants` — archived games are not re-checked against the live roster
   at all.

**The bug is a step-order bug, not a missing subsystem.** By the time `expireContracts` runs its own
internal integrity check, the just-finished season's games are still in `currentSchedule` (they are
not archived until `completeSeason`, several steps later in the same `.jobAndStaffMarkets` case), so
`validResultParticipants` re-validates them against the now-smaller live roster and fails. If the
season were already archived before contracts expire, the same games would be exempt from the
live-roster check for the rest of the game's life, because `checkCompetitionHistory` never applies
it.

**Why this only shows up at the final week today.** `checkSchedule` re-validates every game still in
`currentSchedule`, which in principle includes mid-season games too — a mid-season trade or waiver
claim should hit exactly the same failure. It does not appear in the current soak because no
autonomous, unattended path currently calls `ProMarketSystem.trade` or produces a waiver claim
mid-season (`ProRosterAISystem` only signs free agents; `--pro-soak`'s red output shows
`waivers=0`). FSC-013 should stay open for that case — this plan closes the case that is actually
blocking today, not the general one.

## Fix candidates

### Candidate A — reorder within `.jobAndStaffMarkets` (recommended)

Move the `resolveExpiredWaivers` / `expireContracts` / `ProMarketSystem.close` block to run **after**
`CareerArcSystem.evaluateSeasonEnd` + `PostseasonSystem.completeSeason`, instead of before. Concretely:
split the final-week-only block currently at lines ~360–429 so the market-closing and college
terminal-market calls still happen where they are, but `resolveExpiredWaivers` and `expireContracts`
move to just after `PostseasonSystem.completeSeason` at line ~444 and before `nextState.programmes =
peopleTransition.programmes` at line ~455 — i.e., after the season is archived, but before
`peopleTransition`'s roster changes are applied, so contract expiry still reasons about the
still-current pre-transition roster it does today.

**Why this is minimal.** No schema change, no new persisted field, no save-size growth (a live
concern — FSC-003 is a named release blocker at 213–307 MB uncompressed for 20–30 seasons, and this
project should not add to that while that is open). It only reorders existing calls.

**What it does not fix.** A genuinely mid-season release (a future autonomous trade or waiver claim,
before that season's games are archived) still hits the same failure. Leave FSC-013 open for that
until either professional roster movement becomes AI-reachable mid-season, or Candidate B lands.

**What must be re-verified before this can be called done (needs a toolchain):**
- `Tests/SimTests/Suites/ArchitectureTests.swift`'s `pinnedRootFingerprint` and
  `pinnedAdvancedRootFingerprint` (currently `13_833_728_571_695_481_844` and
  `2_877_422_251_471_580_966`) will not move — `advanceWeek` on a freshly bootstrapped root never
  reaches the final week, so a one-week advance from bootstrap is unaffected. Confirm this by
  inspection of the test, not by assumption, before trusting it.
- Any test that advances a save to the final week and asserts on event order or sequence numbers
  needs its expectations checked: `proContractExpired` and `proWaiversResolved` events now emit
  *after* `seasonCompleted`/postseason-completion events instead of before. Search
  `Tests/SimTests/Suites/` for tests reaching `SharedRules.inSeasonWeeks` and check each one's
  event-order assertions by hand.
- `docs/STATUS.md`'s M7A entry notes `historicalWeight` ties break on event sequence — confirm
  nothing currently depends on contract-expiry events sorting before season-completion events at
  equal `historicalWeight`.
- Run `--pro-week-walk` (already built, per `docs/STATUS.md`) first — it is the fast bisector that
  found the original failure in seconds rather than the twelve-minute soak, so it is the right tool
  to confirm the fix before running `--pro-soak` in full.
- Then `--pro-soak` and `--pro-draft-probe` must both go green, and the ordinary default
  `./scripts/verify.sh` suite must stay green (neither red gate is in the default run today, so a
  regression in the reordered step could otherwise land unnoticed).

### Candidate B — record a roster snapshot at result-recording time

Add fields to `GameSummary` (`Sources/FootballSimCore/Competition/CompetitionState.swift`, currently
lines 12–101) capturing the roster each side had when `AbstractGameSimulator.play` produced the
result (`WorldScheduler.swift` `.nonUserGames`/`.userGame` cases), and change
`validResultParticipants` to check against that stored snapshot instead of the live roster — making
every recorded game permanently self-validating regardless of later roster movement, including
mid-season trades and waivers.

**Why this is not recommended now.** It is a schema change (new `Codable` fields on a struct that
already has a hand-written strict decoder with `DecodingError.dataCorruptedError` guards — every
guard clause needs re-deriving, not just extending) and it is not free: storing a roster's worth of
UUIDs (up to `ProRules.activeRosterLimit` = 53, doubled for home and away) on every recorded game,
across ~22,000 games in a 20-season soak, is on the order of tens of megabytes uncompressed — a
measurable regression on exactly the metric FSC-003 already names a release blocker. A smaller
encoding (e.g. a fixed-size Bloom filter or hash of the roster instead of the full ID list) would
avoid the size cost but adds its own correctness-verification burden this session cannot discharge
either. Candidate B is the right answer once mid-season professional roster movement is
AI-reachable; it is over-scoped for what is blocking today.

## Sequenced task list (for a session with a toolchain)

1. TDD: write a failing test that bootstraps a world, gives every professional player a contract
   with a season-0 term via a test-only helper (or via task 3 below if it has landed), advances to
   `SharedRules.inSeasonWeeks`, and asserts `WorldScheduler.advanceWeek` succeeds without
   `WorldSchedulerError.integrityFailed`. Confirm it fails today for the documented reason.
2. Implement Candidate A's reorder in `WorldScheduler.swift`.
3. Re-run the new test; it should pass. Re-run `--pro-week-walk`, then `--pro-soak` and
   `--pro-draft-probe`.
4. Recompute and update the two pinned fingerprints in `ArchitectureTests.swift` **only if the tests
   above show they actually moved** — do not pre-emptively change a literal you have not measured.
5. Grep-audit event-order-sensitive tests as described above; fix any that assumed the old order.
6. Implement the bootstrap contract-term recommendation now recorded in `docs/02-GAME-DESIGN.md`
   §4.2 (staggered 1–4 year terms, skewed toward the middle, on every bootstrap professional).
   Expect the two pinned fingerprints to move this time — bootstrap itself changes — and update them
   from a real measured run.
7. Full `./scripts/verify.sh`, `--pro-soak`, `--pro-draft-probe`, `--pro-week-walk` all green before
   closing P10c. Update `docs/STATUS.md` honestly either way.
8. Leave FSC-013 open in `docs/FUTURE-SIMULATION-CONTRACT.md` for the mid-season case per the note
   already added there 2026-08-13, rather than closing the row — Candidate A does not close it.
