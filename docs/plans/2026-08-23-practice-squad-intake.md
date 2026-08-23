# Practice-Squad Intake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development`
> (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Use
> `superpowers:using-git-worktrees` before Task 1. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the professional intake rate and the model's own career arithmetic agree, so that
professionals reach their decline age in the numbers `PeopleLifecycleTests`' past-decline band was
derived from, without widening that band and without shortening the seven-round draft.

**Owner decision, 2026-08-23:** of the four reconciliations put to the owner — populate the practice
squad, cut the draft to five rounds, re-derive the band's floor, or leave it — the owner chose
**populate the practice squad**.

## The arithmetic this exists to fix

Measured at seed 96,001 and 84,010 on 2026-08-23, and recorded in `docs/STATUS.md`:

| Quantity | Value | Source |
|---|---|---|
| Active seats | 1,696 | 32 x `ProRules.activeRosterLimit` |
| Practice-squad seats | 512 | 32 x `ProRules.practiceSquadLimit`, **0 ever occupied** |
| New entrants a season | 224 | `ProRules.draftPickCount`, all age 22-23 |
| Implied mean career | 7.6 seasons | 1,696 / 224 |
| Implied mean exit age | ~30 | 22.5 + 7.6 |
| Decline ages | 27 (RB) to 36 (K/P), ~30 weighted | `SharedRules.declineAgeByPosition` |
| Career the band assumes | 11.4 seasons | `D - 22` plus 3.05 post-decline |
| Entrants that career supports | ~149 a season | 1,696 / 11.4 |

The average professional therefore leaves the league at about the age his decline begins, and the
band's floor is unreachable because **most professionals never arrive at decline at all**. Measured
mean age is 25.1-25.8 against a 25.0-27.5 band — passing, but at the bottom.

**Retention itself is not the defect and must not be "fixed".** `--pro-movement-probe` classifies
every declining professional a season later: kept 171/118/107, retired 161/148/95, unattached
21/42/25 across seasons 2-4. Retirement is 42-48% of exits and the market only 6-14%, and
`SeasonLifecycleSystem.retires` matches its stated `(k + 1) x retirementProbabilityPerYearAfterDecline`
exactly. Any task here that changes the retirement hazard is out of scope.

## Architecture

Draft picks stop consuming a 53-man seat by default and enter on the practice squad, which this
model has defined since the beginning and has never once populated. The active roster is then
refilled from two competing sources on merit — promotion from the practice squad, and free agency,
whose pool is now the best 512 unattached professionals rather than an arbitrary 512 — so a returning
veteran and a developing rookie compete for the same seat instead of the rookie being guaranteed it.

`ProMarketPhase.rosterBuild` is the natural home and is currently **dead**: `ProRosterAISystem`
returns an empty transition for it, and before 2026-08-23 the market never even reached it. It
becomes the phase where clubs promote and trim.

**This is a milestone-sized slice, not a rule.** It changes league topology in the sense `02` section
8 uses: roster legality, cap accounting, integrity, the offseason phase machine and every
determinism pin read it.

## Global constraints

- Work only from a clean, isolated worktree. Other sessions commit to the shared branch; never stage
  their files and never use `git add -A`.
- Doc-first: `02` section 4.2 is amended **before** any code in Task 2 onward, including the
  reservation paragraph, which this plan removes.
- The past-decline band in `PeopleLifecycleTests` is **not** to be widened, moved, or re-derived by
  this work. Its numbers are the acceptance criterion.
- Before editing any symbol, run GitNexus upstream impact analysis and report the blast radius.
- Every determinism pin that moves must be reproduced in at least three independent release
  processes before being written, and the reason recorded above the constant.
- Practice-squad players **already count against the cap** (`ProManagementSystem.capSnapshot` sums
  `rosterIDs + practiceSquadIDs`). Seating 224 rookie contracts on top of a full active roster will
  press the cap, and Task 4 exists because of it.

## Answered by the owner, 2026-08-23

1. **All picks enter on the practice squad**, not only those with no active seat. Overflow-only would
   leave the intake arithmetic roughly where it is; all picks is what moves it. Task 8 still measures
   whether it is too strong.
2. **Two seasons** on the practice squad before release. 224 entering a year fits 448 into 512 seats
   with headroom; Task 5 makes the constant explicit rather than implied.
3. **`.rosterBuild` only** for promotion. In-season promotion needs an injury-replacement rule that
   does not exist yet, and inventing one here would widen this slice.

## Tasks

### Task 1 — Baseline the arithmetic on an immutable SHA

Baseline SHA: **`9d77d68`**, release build.

- [x] `--pro-movement-probe`, `PRO_MOVEMENT_SEASONS=6`:

      season  expired  drafted  FAsignings  active  midSeason  shortBy    weeks(FA/draft/build)
      1       293      0        0           1403    1696       6-11       0 / 0 / 0
      2       257      223      70          1439    1696       6-10       5 / 1 / 15
      3       200      218      39          1496    1696       3-10       4 / 1 / 16
      4       170      189      11          1526    1696       2-9        4 / 1 / 16
      5       354      165      5           1342    1696       7-15       3 / 1 / 17
      6       263      224      130         1433    1696       5-13       9 / 1 / 11

      Declining professionals a season later — kept / retired / unattached:

      season 2: 353 -> 171 / 161 / 21
      season 3: 308 -> 118 / 148 / 42
      season 4: 227 -> 107 /  95 / 25
      season 5: 199 ->  79 /  72 / 48
      season 6: 138 ->  51 /  47 / 40

      Two things to hold onto. The practice squad is **0 in every season**, which is the seat pool
      this plan exists to use. And the declining population itself collapses — 353, 308, 227, 199,
      138 — while the share of it lost to the market grows from 6% to 29%. Arrival at decline is the
      failing quantity, not retention once there.

- [ ] `--people-lifecycle` on the same SHA — the past-decline series is the acceptance criterion.
- [x] Numbers match `docs/STATUS.md`: active seats, the 224 intake, the 0-occupancy practice squad
      and the retention split all agree with the 2026-08-23 entries.

### Task 2 — Amend `02` section 4.2 — **done**

- [x] State that a draft pick enters on the practice squad, and why: the intake arithmetic above,
      with the measured figures.
- [x] **Remove the seat-reservation rule.** It exists so free agency cannot fill all 53 before the
      draft; once picks do not take active seats there is nothing to reserve, and leaving it in place
      would hold 7 seats empty for nobody. Note that this supersedes the 2026-08-20 entry and the
      2026-08-23 passed-pick entry, and say plainly that a passed pick becomes unreachable.
- [x] State the promotion rule, the practice-squad tenure limit, and that a pick still never forces a
      release — the 2026-08-12 "a pick is not a cut instrument" decision stands.

### Task 3 — Acquire onto the practice squad

- [ ] Add a practice-squad seating path to `ProManagementSystem.acquire`, alongside the active one.
      It must apply the same contract stamping, cap check and free-agent guards; only the destination
      list differs.
- [ ] `ProMarketSystem.draftForScheduler` seats there. `ProRosterAISystem.makeDraftPicks` loses its
      `activeRosterFull` pass path; keep `stoppedBecause` for anything else.
- [ ] Tests: a pick lands on the practice squad, is under contract, counts against the cap, and does
      not appear on the active roster. Root integrity accepts it.

### Task 4 — Cap headroom

- [ ] Measure whether a club can carry 53 active plus its picks under `ProRules` cap limits. If it
      cannot, the draft will throw `capExceeded` and stall exactly as it used to.
- [ ] If it cannot, this is an owner decision and not a licence to raise the cap: report the shortfall
      with the numbers and stop.

### Task 5 — `.rosterBuild` promotes and trims

- [ ] `ProRosterAISystem` gains a `.rosterBuild` branch: for each AI club, promote from the practice
      squad into every active vacancy, best-rated first, while legal; then release from the practice
      squad, lowest-rated first, until it is inside its limit and its tenure rule.
- [ ] The controlled club is skipped, as it is in every other phase.
- [ ] Tests: a full active roster promotes nobody; a club short by three promotes its three best; a
      squad over its limit trims from the bottom; the whole pass is deterministic across processes.

### Task 6 — Free agency fills the seats the draft no longer does

- [ ] `signingLimit` becomes `ProRules.activeRosterLimit`, the reservation having been removed in
      Task 2.
- [ ] Confirm free agency still terminates: it ends on the first pass that signs nobody, and clubs now
      need roughly nine signings rather than two, so it will run longer. Assert it still reaches the
      draft inside the season.

### Task 7 — Integrity and legality

- [ ] `WorldIntegrity`: practice-squad membership is bounded by `practiceSquadLimit`, disjoint from
      the active roster, and every member is under contract to the club that holds him.
- [ ] Positional coverage still reads the active roster only, and the active roster must still reach
      53 — a club that hides players on the practice squad to dodge coverage is a defect.

### Task 8 — Measure, and be willing to report failure

- [ ] Re-run `--pro-movement-probe` and `--people-lifecycle`. The acceptance criterion is the
      past-decline share inside 0.08-0.30 at **every** sampled season, with the mean-age band still
      held and the active roster still 1,696 mid-season.
- [ ] If the share moves the wrong way — as it did when the sample point was moved on 2026-08-23 —
      record the numbers and revert rather than chasing the band. Open question 1 is the first thing
      to revisit.

### Task 9 — Re-pin and verify

- [ ] Re-derive every moved pin in three independent release processes; record the reason above each
      constant.
- [ ] Full default suite green apart from any band this plan did not undertake to fix, plus
      `--m1-soak`, `--m7-gate`, `--pro-market`, `--pro-management`, `--cap-compliance`,
      `--save-document`, `--architecture-only`.
- [ ] `docs/STATUS.md` records the measured before and after, and says plainly which of the open
      questions above the implementation answered and which it left.
