# P10b — analytics/evidence authority: scope check, 2026-08-13

Written in a toolchain-less session; this is a scoping note, not an implementation plan detailed
enough to build from directly (contrast `docs/plans/2026-08-13-p10c-professional-roster-turnover.md`,
which traces exact call sites). P10b is lower urgency than P10c: nothing in `docs/STATUS.md` is
currently red because P10b is missing, whereas P10c blocks a measured, named failure. Time this
session went to P10c's traced fix first for that reason.

**Confirmed absent from `Sources/FootballSimCore`** (searched for `historicalWeight`-style dedicated
modules; only tangential matches in unrelated systems, listed below for reference): no
`AnalyticsSystem`/`EvidenceSystem`, no per-player form-series type, no attribute-change ring buffer,
no opponent-preparation-knowledge type beyond what `FSC-007`/`FSC-005` already cover for
college/draft scouting, no per-player detailed-match stat line type, no engine-owned load/condition
policy type. All six gap-register items (G-02 through G-05, G-11, G-14) are genuinely unbuilt.

**Why this is a schema-touching, multi-week slice, not a session's blind-code candidate:**

- G-02 (baselines/verdicts) and G-04 (form series) both need a new persisted per-player structure
  with a stated bound (`CLAUDE.md`: "every collection that can grow across seasons has a stated
  bound") and a save-size budget already given in `05` P10b's gate: G-02 ≤ 1.5 MB, G-03 ≤ 0.6 MB,
  G-04 ≤ 0.3 MB, G-05 ≤ 0.2 MB, G-06 ≤ 2.6 MB total. Getting a ring-buffer/bounded-history structure
  wrong in a save-schema field is exactly the kind of change this project bumps a schema version and
  writes migration fixtures for (schema has moved 5→11 exactly this carefully) — not defensible to
  attempt without compiling and running the migration/hostile-save tests.
- G-11 (detailed-match per-player stat lines) requires the P3/P4 detailed engine (currently
  uncalibrated — 5–6 of 24 bands hold) to attribute yards/tackles/etc. to individual players per
  play, which is itself a real engine-modelling task, not a data-plumbing one; it is explicitly
  named in `docs/STATUS.md` as "the P4-widening work" already prescribed elsewhere.
- G-14 (engine-owned load policy: condition-band cut points, dose multipliers, derived practice
  cost) needs the actual condition/fatigue model in `Sources/FootballSimCore/People/DevelopmentSystem.swift`
  read closely enough to add cut points without contradicting the existing calibration — a smaller
  slice than the rest of P10b, and the best candidate for a follow-up session to start with.

**Recommendation for the next toolchain session:** start with G-14 (smallest, most contained, no new
persisted collection — condition bands and multipliers can plausibly be pure functions over existing
state) and G-03 (a bounded 6-entry-per-player ring buffer is the smallest of the new persisted
structures) before attempting G-02/G-04's baseline/verdict machinery, which needs a real distributional
model (percentiles across ~15,766 players) that is easy to get subtly wrong without being able to run
it against the generated population and eyeball the distribution.

No code written for this task. Recorded here rather than left silently unstarted.
