# Claude build handoff

## Latest handoff — eight red suites on main, seven of them a merge (2026-08-22)

`main` at `da0eb73` failed eight suites in CI run `32558005794`. Seven of the eight were the shape
of a merge rather than a defect: PR #69 resolved file by file and kept one branch's tests beside
the other branch's production code. `docs/STATUS.md`'s 2026-08-22 entry carries the full account
and is the record to read; this is the pointer to it.

What was done, in order:

1. Merged the nine unmerged commits on `agent/floodlit-injury-evidence` (`c42b6e4`…`3a35bc6`).
   They restore `DetailedGameSummaryBuilder`'s preserved losses and re-derive ten fingerprints, and
   they close `Legal: shipped copy`, `League generation`, `Game loop` and `Authoritative game state`.
2. Reconciled four assertions that could not hold together after the merge — the pre-kickoff
   comparison root in `M4 tactical state`, the appended professional seat in `M5 career arc`, and
   the week-20 terminal checkpoint and NIL-budget fixture in `College portal scheduler lifecycle`.
3. Raised `SharedRules.minimumPlayableRosterByPosition[.runningBack]` to 2, for the reserve back
   `DepthChart.offensiveTemplate` now fields. This was a new failure the merge created, caught by
   the existing cross-check in `RulesTests`; no determinism lane moved with it.

### The one that is still red, and must not be re-pinned

`Lifecycle distributions hold their bands`. The professional past-decline share reads 0.228, 0.196,
0.146, **0.073**, 0.170 at seasons 0, 1, 3, 6, 10 against a band of 0.08…0.30. It is a real
measurement of two things at once: active professional rosters hold 1,411…1,533 against 32 × 53 =
1,696 from the first offseason onward, and every professional enters at age 22, so the initial
veteran tail retires out before the drafted cohorts reach decline. `--pro-soak` already asserts the
roster-legality half and is already red for it.

**Do not widen the band.** The decision the owner owns is whether the professional roster policy
fills to 53 — `ProRosterAISystem` signs at most one free agent per team per week and does nothing at
all in `.rosterBuild` — or whether the band is restated as a steady-state property that a run from
a bootstrapped population is not entitled to satisfy at season 6.

---

Checkpoint: **M7 is complete except conference realignment.** Continue from here; do not redo the
green gates below.

**`docs/STATUS.md` is the truth.** This file is a pointer, not a substitute — the previous version of
it listed only focused gates and a reader reasonably took that as "the build is green". It was not:
the full suite was red. Read STATUS before believing any summary, including this one.

## Verified, on 2026-08-12

`./scripts/verify.sh` — **663 tests / 747,584 checks, exit 0**, debug build and release suite. This
is the whole default run, not a selection.

Focused gates, each measured rather than estimated:

- `--core-contracts` 152 / 980
- `--news-feed` 8 / 14
- `--programme-evolution` 7 / 275
- `--architecture-only` 25 / 222
- `--generation-only` 34 / 39,143
- `--legal-only` 22 / 141
- `--history-archive` 20 / 147
- `--coaching-tree` 11 / 25
- `--rivalry-order` 7 / 11
- `--portal-scheduler` 9 / 27,823 (two-season byte-identical replay)
- `--m7-gate` 1 / 65, in release, 30 seasons

Root schema is **11**.

## What this checkpoint added

- **M7A** — rival lists reorder from the intensity their meetings earned, through the same ranking
  that seeded them; `CoachingTreeReadModel` derives mentor-to-disciple from bounded staff careers,
  rebuilt rather than persisted.
- **M7B** — the historical aggregate archive. An event leaving the bounded hot journal folds into a
  `SeasonHistoryDigest` for its own season: an archived count plus a bounded, *ranked* sample of
  bodies. `digest(forSeason:)` surfaces a past season without reading the journal or the save.
- **Save compression** — `03b` §4's reserved flags bit, claimed. **306.9 MB → 36.0 MB at season 30**,
  8.5x, with season 1 inside the original 8 MB ceiling.
- **The legal guardrail now refuses by name-kind**, after the owner permitted real locations.
- **M7C, the news feed** — headlines rendered from typed payloads over the hot journal *and* the
  archive's retained bodies, ranked by the same `historicalWeight` that decides what an archived
  season keeps. Derived, never persisted. `02` §4.2b.
- **M7D, programme evolution** — prestige was frozen at generation and now steps one point a season
  toward a target set by the final table. `02` §8. The portal characterization moved with it
  (385/210/94 entrant windows, transfers, returns became 409/217/112), which is the world evolving
  rather than a regression: those are descriptive outputs, not pins.
- **The personnel UI slice** with four proofs recaptured from current source.

## Red on purpose — read these before touching the professional tier

Neither is in the default run, so `verify.sh` is unaffected. Both name a real defect.

- **`--pro-soak`** — the both-tier professional soak the last handoff listed as open. It had never
  been written. It asserts cap and roster legality per season for all 32 teams and a byte-identical
  replay, and it fails because **the professional tier is inert**: rosters bootstrap at 53/53 and
  never turn over, and no professional holds a contract, so nothing expires and nobody reaches free
  agency. The 224-prospect draft class generated every season can never be taken.
- **`--pro-draft-probe`** — reaches the draft directly and reports the thrown reason in seconds
  rather than twelve minutes.
- **`--pro-week-walk`** — bisector: reports the exact week a professional step refuses.

**The blocker is FSC-013, not a missing cut policy.** Giving bootstrap professionals contracts was
tried and reverted. It works in isolation — 317 expire, cap legal, first draft pick succeeds — and
fails in the scheduler at season 0 week 21, because whole-root integrity validates recorded game
participants against *current* rosters. Releasing 315 players while that season's results are live
invalidates every game they played in. FSC-013 named its own activation trigger as "no later than
professional trades"; the real trigger is earlier — contract expiry at the final week of a live
season — and the entry now says so. **Professional turnover needs dated roster-tenure history
first.**

The headless offseason driver is already built and waiting for it: `ProRosterAISystem` signs while
signings are legal, begins the draft when a pass signs nobody, and picks in draft order, pausing only
when the controlled professional team is on the clock (`02` §4.2, amended 2026-08-12).

## Next work

1. **Conference realignment — M7's last item.** `02` §8 already specifies the inputs: performance,
   market and geography. It is not blocked on a decision; it is **milestone-sized**, because it
   changes league *topology* and schedule generation, standings, tiebreaks and whole-root integrity
   all read that topology. Budget it as a slice with its own plan, not as a rule.
2. **Cross-season semantic narrative** — a story that spans seasons rather than reporting one event.
   The feed reports; nothing yet narrates.
3. **M8 production UI** — gated. Its entry gate needs Coaching HQ, Recruiting Board and Match Day
   approved together as interactive native-size proofs at 31/40 or better against `04b`. A second
   session owns the design work.
4. **FSC-013 dated roster-tenure history** — unblocks the professional tier.
5. **L-01 — run the suite against the near-miss name list, and re-pin.** The blocklist work on
   `claude/game-name-equivalents-qczn9r` (PR #9) was written with no toolchain and is unverified.
   The nickname pools lost eight real college nicknames to one-for-one replacements, so
   `ArchitectureTests`' `pinnedRootFingerprint` and `pinnedAdvancedRootFingerprint` should both move
   and need re-pinning — **and a pin that does not move is the finding**, because it would mean the
   fingerprint never covered generated names. `docs/05-IMPLEMENTATION-PLAN.md`'s 2026-08-13
   amendments carry L-01 to L-06; L-02, the nickname morpheme grammar, is the only other one that is
   build work rather than a counsel or review action.
6. **M9** — where `docs/roadmap/06` puts final calibration, save migrations, performance and the long
   soak. **P4's match calibration is still failing at 5–6 of 24 bands**, and STATUS is explicit that
   the gap is model thinness — no per-drive accounting, a thin run game — not constants, so more
   search over the existing six will not move it.

## Standing constraints

Swift 5 language mode and TestKit. Preserve the actor-owned `CareerSession`, sealed portal
transactions, copied-root validation, deterministic event ordering, and no SwiftUI access to
`GameState`.

**Two things that cost real time here.** A second session commits to this branch: stage by explicit
path, never `git add -A`, and if its uncommitted work does not compile, build in a worktree rather
than touching its files. And **run the full suite before claiming green** — focused gates missed a
determinism pin that hashed the save envelope, so compression silently moved it; the full run is what
caught it.
