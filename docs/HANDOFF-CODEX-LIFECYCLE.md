# Codex handoff — lifecycle calibration bands and the professional draft stall

Checkpoint from a Claude session, 2026-08-20, merged to main as PR [#37](https://github.com/EricMG13/Pro-Football-Coach/pull/37)
(merge commit `6330d82`). This is a pointer, not a substitute — `docs/STATUS.md`'s dated entries carry
every measurement. Separate from `docs/HANDOFF-CODEX-CALIBRATION.md` (the match-engine's 21/24
holdout bands) and `docs/HANDOFF-CODEX.md` (PR #9's re-pin) — unrelated efforts, different subsystem.

## Where things stand

Five lifecycle distributions are now banded and asserted at several season indices across a
ten-season run, in `Tests/SimTests/Suites/PeopleLifecycleTests.swift`, run via:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --people-lifecycle
```

Age curve, injured share, roster churn (both tiers), rating spread by tier, and discipline
frequency. Each band states its source before being measured — a rules constant, a derived
steady-state calculation, or an external anchor graded per `01-RESEARCH.md` §0.1 — never invented
to make a number pass. All five hold on the owner head `1694153` (`fix: tolerate pruned portal history`):
the long release run completed 21 tests and 520,251 checks, including season indices 0, 1, 3, 6 and
10, all passed. The focused companion suites also pass: discipline (9/36), roster tenure (4/5),
injury evidence (1/34), and programme evolution (7/275). The owner change is published as PR
[#61](https://github.com/EricMG13/Pro-Football-Coach/pull/61).

The separate 20-season M2 soak is still the slow lane. Its existing roster-retention failure and the
tactical-state failure are recorded below rather than being hidden by the green lifecycle-band run.

**What this fixed, in order of size:**

1. **The professional draft took zero picks in ten seasons** while starting nine times.
   `ProManagementSystem.acquire` enforced the identical `rosterIDs.count < activeRosterLimit` guard
   for both a free-agent signing and a draft pick, and free agency ran until that guard stopped
   finding a legal team, then began the draft — so the draft's first pick always met the exact
   ceiling free agency had just filled. Fixed by reserving seats: an AI club now signs only down to
   what its remaining draft-order picks need (main's `4fcd477`, which counts each team's actual
   remaining picks rather than a flat `draftRounds` assumption — better than this branch's own first
   attempt, which was dropped in favour of it during the merge). `--pro-soak`: `proDraftPick=1568`
   across ten seasons, up from 0, green for the first time since `e710924` added it.
2. **The college talent scale was two different formulas.** Bootstrap keyed off programme prestige
   (`RosterPopulationGenerator.baseRating`, midpoint 62.5); the recruiting pipeline keyed off city
   talent density with its own lower formula (midpoint 56.0). Nothing asserted they agreed, so a
   generated league's college talent decayed from the bootstrap scale to the recruiting scale over
   six seasons and settled there — the rating-spread band's tier-gap limb is what caught it.
   `ProspectPopulationGenerator` now calls the same `baseRating`, so the scale cannot move for one
   intake path without moving for the other.
3. **`DisciplineSystem` had zero callers anywhere in `Sources/`.** A played season produced no
   discipline incident at all; the frequency was structurally zero regardless of what the constants
   said. A weekly `disciplineFile` scheduler step now runs it (ordered after `injuriesAndRecovery`,
   because that step counts a served suspension down and a suspension drawn before it would lose a
   week to the tick that issued it), through a new `DisciplineAISystem` that answers the file for
   every organisation the player is not coaching and skips the controlled one — `02` §5.2 makes the
   response the coach's.
4. **`.ironman` and `.volatile` were implemented and never populated.** Both traits had a real
   mechanical consumer (`PeopleRules.injuryWeeks`, `DisciplineSystem`'s `player.has(.volatile)`
   read) that nothing ever called, so `TraitPopulationGenerator`'s own rule — populate a trait only
   once its consumer is live — correctly withheld them. Both consumers are reachable now (points 1
   and 3 above), so both joined `activeTraits`.

Each of the four came from deriving a band's expected value from the model's own constants *before*
measuring, then chasing the gap to a root cause rather than loosening the band. `docs/STATUS.md`'s
2026-08-20 entries under "Lifecycle distribution bands" carry the arithmetic for each.

## What is still open, and where

**Beat 2 of `02` §4.2 — cap-compliance cuts — remains unimplemented.** Nothing forces a club to cut
a player for money; only headcount (beat 1, expiry and retirement) was blocking the draft, and that
is what got fixed. `a2e3147` named this as an owner-level design call before this session, and it
still is. Not attempted here.

**The free-agent pool is now pinned at its 512-entry bound** (`ProMarketState.maximumFreeAgentIDs`)
by season 10 of `--pro-soak`. Expiry now outpaces signing — `proContractExpired=2288` against
`proPlayerSigned=554` over ten seasons — because the draft absorbs most of what used to sign, and
nothing yet drains the pool the other direction. Nothing fails today; `expireContracts` only refuses
when a single season's expiries exceed the bound outright. But `02` §4.2a sized bootstrap's
fifth-per-season expiry specifically to "leave real headroom for carryover", and there is now none.
The next change that raises expiry or lowers signing meets `ProMarketError.invalidRoot`. Whatever
drains the pool — beat 2's cuts, a pool eviction policy, or AI clubs signing deeper before the draft
reserve kicks in — is unbuilt. `docs/STATUS.md`'s "professional soak" section has the numbers.

**`--pro-soak`'s `weekMeanMs` rose 2,628 → 11,195, a 4.3x slowdown**, after `draftForScheduler` (a
new scheduler-path variant of `ProMarketSystem.draft` mirroring the existing
`signFreeAgentForScheduler`) had already removed 224 whole-root `WorldIntegrity.check` calls a
season. The remaining cost is real work — a league whose rosters actually refill simulates more
players every week — not waste, but it is a real regression against the app-latency concern this
project tracks (`docs/STATUS.md`'s "app-layer latency" line). Not profiled further here.

The exact owner release tree has now been checked in focused lanes: coach-season-record (3/22), staff
pruning (1/8), career arc (23/360), season rollover (13/96), portal transactions (17/124), and
architecture (29/245), in addition to the five lifecycle suites above. The tactical-state lane still
has one known baseline failure (8 tests / 31 checks): the weekly scheduler consumes the plan, but one
`GameSummary` equality assertion differs. That lane is outside the owner change and was not altered.
The no-argument default lane and the 20-season M2 soak remain separate completion gates.

The portal-history root cause is now fixed on the owner head. Departed-player pruning can remove the
individual completion records needed to prove a portal window's exact NIL split, even though the
window's retained summary or hot journal still proves the completed transaction. Integrity now uses
the retained summary, recent journal, and archive to mark a window complete only when their offer
counts agree; it always enforces aggregate reservation, capacity, offer-count, and accepted-position
limits, and applies the exact split only to those proven-complete windows. No decline-age or trait
constant was changed.

## What NOT to do

- Don't loosen any of the five new bands in `PeopleLifecycleTests.swift` to make a reading pass.
  Every one is derived from a stated source; if a measurement breaks a band, the fix is the model
  (as it was for all four items above) or an explicit, recorded, owner-approved change to a decline
  age or trait constant — `CLAUDE.md`'s standing rule, and the reason this session asked before
  touching either.
- Don't re-attempt a `freeAgencyRosterCeiling`-style flat reservation (`activeRosterLimit -
  draftRounds`) if you're reading old context — main's `signingLimit` (counted from each team's
  actual remaining `draftOrder` picks) superseded that during the merge and is what shipped. It
  handles a team holding an unusual number of picks correctly; the flat version didn't.
- Don't implement beat 2 (cap-compliance cuts) without an owner decision recorded first — `02` §4.2
  names the beat but not who gets cut, when, or by what criterion, and `a2e3147` is explicit that
  this is a design call, not an implementation detail.

Co-authored-by: Eric Guei <ericsea1990@googlemail.com>
Co-authored-by: Claude Opus 5 <noreply@anthropic.com>
