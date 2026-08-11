# M1 — Playable world

Authority: Master Build Documentation `01`, `03`, `05`, and `06`; retained numerical constants in
`docs/02-GAME-DESIGN.md` section 11. This milestone activates a real competition loop on top of M0.

## Exit gate

- College: 12 games plus one bye across weeks 1–13, conference championships in week 14, and an
  eight-team three-round bracket in weeks 15–17.
- Pro: 17 games plus one bye across weeks 1–18 and an eight-team three-round bracket in weeks
  19–21.
- Deterministic schedules, abstract non-user results, standings/rankings, postseason advancement,
  team statistics, record primitives, roster population, season rollover, and history events.
- Twenty college/pro seasons complete headlessly at target scale with no integrity failure.
- Existing detailed match generation and fingerprints remain unchanged.

## Architectural contracts

- `CompetitionState` is authoritative and stored under `GameState`; schedule entries use IDs and
  never copy teams or players.
- Games have stable deterministic IDs, explicit stage/status, and structured summaries. Full
  play-by-play is not stored for non-user games.
- The abstract simulator shares ratings/rules and produces a bounded summary; it does not pretend
  to have player-level data it did not simulate.
- Standings and aggregate statistics are rebuilt deterministically from completed games, so they
  cannot drift from results.
- Postseason games are scheduled only after their participants are known.
- Calendar rollover archives a compact `SeasonArchive` and creates the next season's schedule.
- Scheduler order remains the M0 compatibility contract. M1 activates only `nonUserGames`,
  `standingsAndRankings`, `statisticsAndRecords`, `saveGrowthAndIntegrity`, and `weekSnapshot`.

## Task 1 — Competition contracts and regular-season scheduling (TDD)

Implement tier/stage/status, scheduled games, season schedule, competition state, and deterministic
schedule generation. Generate one bye and the exact regular-season game count for every member,
with no self-match or duplicate pairing in a season. Prefer conference/division opponents where
possible without weakening validity.

Tests first: same-seed equality; exact counts; unique IDs/pairings; week bounds; one bye per member;
all references resolve; schedule survives the save envelope.

## Task 2 — Target-scale roster population (TDD)

Add deterministic roster population with a rules-owned position template, college age/class shape,
and pro age shape. Generate only attributes a position uses, assign each player once, and preserve
legal roster limits. Player identities must use hierarchical seeded RNG and fictional name grammar.

Tests first: target counts, positional coverage, legal ownership, rating bounds, deterministic
bytes, and generation performance measurement.

## Task 3 — Abstract outcomes and team statistics (TDD)

Implement a fast deterministic non-user simulator driven by roster strength, programme/team
quality, home advantage, and bounded scoring variance. Return team-level summaries only. Add
standings rows, tier-appropriate ranking/tiebreak order, cumulative team stats, and record-book
primitives derived from completed results.

Tests first: deterministic outcomes; reachability of either winner; non-negative plausible scores;
standings exactly reconcile games; no regular-season ties after competition overtime resolution;
ranking/tiebreak stability; aggregates are idempotent.

## Task 4 — Postseason and rollover (TDD)

At college week 13 create conference championships; after week 14 seed the eight-team bracket. At
pro week 18 select four teams per conference. Advance winners through three rounds, identify
champions, archive compact season summaries, and generate the next season before week 1 runs.

Tests first: participant eligibility, no duplicate entrants, bracket reachability, one champion per
tier, correct week placement, exact season archive count, and deterministic next-season schedule.

## Task 5 — Scheduler integration and integrity (TDD)

Activate the five M1 steps truthfully. Extend integrity for schedule references, duplicate game IDs,
game status/result agreement, standings derivation, postseason shape, roster positional coverage,
and archive bounds. Emit typed game/round/season events without prose-only truth.

Tests first: step activation order, one-week replay, planted schedule corruption, and decode-time
whole-root rejection.

## Task 6 — Soak, calibration screen, and status

Run a target-scale 20-season headless soak with repeated save/load checkpoints. Measure week/season
time and encoded sizes at seasons 1, 5, and 20. Check broad continuation bands (scores, win rates,
parity, games per team) without claiming final calibration. Patch confirmed issues, run
`scripts/verify.sh`, pin the M1 transition fingerprint, and update status/future contracts.

Per owner direction, `rewrite-tournament` and `confidence-review` remain deferred to final product
verification. Ordinary milestone adversarial review, determinism, integrity, and tests still run.

## Completion record — 2026-08-10

Tasks 1–6 are implemented. The final no-shortcuts repository gate passed with **312 tests and
225,499 checks**. The final release-mode soak completed **20 seasons / 420 weeks / 22,000 games** in
**266.816595875 seconds** (about 0.64 seconds per simulated week) with no integrity failure. Save
checkpoints round-tripped at **9,615,246 bytes** after season 1, **10,591,838 bytes** after season 5,
and **10,710,674 bytes** after season 20.

The milestone adversarial pass confirmed and fixed: postseason games leaking into regular-season
standings; non-football fallback ordering instead of two-team head-to-head and conference records;
inline abstract-simulation constants; record entries that lost opponent/stage context after
rollover; result lines referencing uninvolved players; malformed archive/record state escaping
integrity; ambiguous scheduler errors; rollover schedule/calendar disagreement; duplicate roster
references being mislabeled as multiple owners; and bracket participants not being checked against
the opening field or previous-round winners. A 16-seed schedule sweep now guards against collapsed
bye distribution.

Per owner direction, the no-argument `rewrite-tournament` and repository-wide `confidence-review`
remain explicitly deferred until the complete product's final verification. M1 is complete; M2
people lifecycle is the next dependency milestone.
