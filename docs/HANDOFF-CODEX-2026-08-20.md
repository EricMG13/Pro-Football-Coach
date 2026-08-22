# Codex continuation handoff — Claude work review

Snapshot: 2026-08-20, Europe/London. This is a continuation memo, not canon. `docs/STATUS.md`,
`CLAUDE.md`, `docs/DOC-MANIFEST.md`, and the numbered canon documents remain authoritative.

## Repository state

- Working branch: `agent/floodlit-injury-evidence`, HEAD `d43a8b3`.
- Claude baseline: local `main` at `40ea8ed`; `origin/main` was `9bfcab5` when inspected.
- The branch is 8 commits ahead and 137 commits behind local `main`; this is a broad divergence,
  not a small merge delta.
- Existing WIP is intentionally preserved: 8 staged source/test files, one additionally unstaged
  test edit, `docs/STATUS.md`, and several untracked agent/design documents. Do not use `git add -A`.
- No source code was changed during this review.

## Claude work that is in the current main lineage

Claude/main has built the deterministic two-tier simulation, M0–M7 foundations, college recruiting
and portal systems, history/archive/news, career/coaching-tree systems, cap compliance, realignment,
Floodlit UI conversion, and broad contract/test coverage. Recent merged work also includes:

- season-boundary schedule/realignment/rivalry/ledger properties and fixes;
- all 62 Floodlit routes registered, with G-01/G-02/G-05/G-35/G-36 closed;
- professional-rule compliance tests and corrected college age/open-signing-day behavior;
- expanded world-generation/legal/trait sweeps;
- actor-hop cleanup in the app layer;
- defensive persistence, integrity, save readback, portal, redshirt, cap, and event-ledger checks.

The current main lineage is the baseline to compare against before integrating agent WIP. Many old
Claude handoffs say “M7 complete except realignment”; that statement is historical and stale because
realignment and later Floodlit work are now merged.

## Claude branches with material unmerged work

These branch tips were inspected; they are not automatically safe to merge:

- `claude/career-length-cap-30` (`a1f6766` plus handoff): caps careers at 30 seasons through the
  scheduler chokepoint. Targeted gates are green; the full default run was interrupted. It bounds
  digest growth but still measures about 37.11 MB at season 30, so the 8 MB FSC-003 decision remains
  open. A sibling retention branch reduced season-20 saves further to about 14.76 MB; composition was
  not measured.
- `claude/coach-career-promotion-integrity-f10168`: coordinator promotion, coach separation,
  coaching-tree correctness, and career movement work. Its handoff says PR #9 still needs a fresh
  full-run re-pin after the legal blocklist added NFL trade-dress pairs. Do not guess pins. Reproduce
  the current main + PR #9 merge, then update only the changed world/fingerprint/trait pins from one
  deterministic run. Two failures need root-cause confirmation first: missing weekly preparation and
  cap-compliance invalid-root at the week-21 boundary.
- `claude/codebase-review-confidence-b6b216`: removes actor hops and contains an orthogonal people
  retention/save-size reduction. Review composition with the career cap before merging.
- `claude/college-acquisition-rule-enforce-90fa82`: transaction-by-transaction college acquisition
  enforcement and reservation-count deduplication. Large diff; rebase and run focused college,
  commitment, portal, and release-core gates before considering it.
- `claude/hopeful-liskov-37edb2`: portal-touched retention experiment. It scopes retention to
  surviving completion events; do not accept without the long portal-retention soak.
- `claude/lifecycle-band-validation-a50138`: professional lifecycle/discipline/talent/age-band
  diagnostics, draft-seat reservation, and professional-soak fixes. Its own handoff says the
  professional tier remains blocked by FSC-013: turnover at week 21 invalidates live game
  participant manifests. Dated roster-tenure history is the required root fix.
- `claude/implement-landscape-screens-63c2b1`: League Map/read model and related UI work, with a
  documented full-suite measurement gap. Treat the UI audit/status claims as historical until the
  current full suite and simulator proof are rerun.
- `claude/missing-game-features-vcrzwz`: a large completeness-build branch adding many late feature
  slices (career, difficulty, locker-room, draft ownership, injury termination, traits, etc.). It
  compiled once but its run stopped mid-suite. Do not merge wholesale; cherry-pick only after mapping
  each slice to current main and re-verifying.
- `claude/road-to-beta-plan-40e904`: bounded per-player attribute-change history (G-03), a sizable
  feature branch requiring current-main impact review and persistence-size checks.
- `claude/sad-heisenberg-45fed4`: test corrections for invariants the engine does not promise; useful
  as a reference for separating week-1 coverage guarantees from later fill guarantees.
- `claude/tighten-calibration-bands-0a1924`: substantial match-model/calibration work. It reaches
  21/24 bands but explicitly leaves the final model gap; do not tune constants further without the
  per-drive/run-game model work described in STATUS.
- `claude/twotier-consistency-tests-runner-11d4f1`: two-tier consistency, home advantage, run/pass,
  pressure, and clock fixes with focused TOST coverage. Revalidate against current match pins.
- `claude/world-gen-property-assert-b8a302`: world-generation property sweeps for traits and
  pro-division/conference partitions; low-risk test-only work, but rerun after any generation change.

## Current agent WIP review — do not merge as-is

1. **Portal history loss (P1).** `PlayerCareerRecord.compactedForDeparture()` drops `portalWindows`
   and recruiting origin. `WorldScheduler.compactHistoryBoundState` protects only recent event IDs
   and player-of-the-year winners. An older departed player with portal history is compacted; Claude's
   main implementation explicitly protects every career with portal windows because a narrower filter
   reproduced `portalCommitFailed(.postseason)` at season 4.
2. **Historical integrity regression (P1).** WIP changes portal capacity validation from all career
   records to current-target records. Historical malformed capacity records can bypass whole-root
   integrity. Main validates `allCareerRecords`.
3. **Soak assertion weakened (P2).** The WIP M2 test accepts active players `<=` target and finally
   compares the store to the observed count. This can hide population underfill. Main’s one-week
   fill-state check preserves the stronger invariant.
4. **Archived news identity gap (P2).** WIP retention derives player protection from recent events,
   while the news feed renders archived notable events and resolves departed names separately. An
   evicted identity can render as “An unnamed party.” Main also needs an explicit archive-reference
   decision; do not assume this is solved by adopting either implementation.

The durable-positive WIP change is portal matching: scouting knowledge is now recorded for durable
offers rather than every generated candidate, with a focused regression test.

## Open build order for Codex

1. Reconcile current `main`/`origin/main` first; re-list branches and PRs because Claude sessions are
   still moving refs.
2. Finish or reject the current agent WIP, starting with portal-history retention and the historical
   integrity regression. Preserve explicit staged/unstaged ownership.
3. Run targeted gates, then the complete release/default suite before claiming green. A focused gate
   is not sufficient for persistence pins or determinism.
4. Decide with the owner whether the 8 MB save ceiling remains binding; do not unilaterally treat the
   30-season cap as a solution.
5. For professional turnover, implement dated roster-tenure history before reactivating bootstrap
   contracts or forcing week-21 expiration. The existing offseason AI/draft driver is downstream of
   that fix.
6. Keep M8 UI work behind the 04b 31/40 proof gate and owner simulator walkthrough. Pro management
   and career surfaces were not visually verified in the earlier handoffs.
7. Keep P4 calibration model work separate from constant search: the remaining gap is per-drive
   accounting and a thin run game, not merely six tunable constants.

## Operational constraints

Use Swift 5 language mode and TestKit. Preserve actor-owned `CareerSession`, sealed portal
transactions, copied-root validation, deterministic event ordering, and strict engine/UI separation.
Follow doc-first design decisions, TDD for engine changes, adversarial review, GitNexus impact before
symbol edits, and full verification before completion. Stage explicit paths only.
