# M2 — People lifecycle

Authority: Master Build Documentation `01`, `02`, `03`, `05`, and `06`; retained player/staff
contracts in `docs/02-GAME-DESIGN.md`. This milestone makes the M1 population persist credibly
through time before recruiting, draft, tactics, or career markets depend on it.

## Exit gate

- Development, fatigue, injury/recovery, college eligibility/graduation, professional retirement,
  replacement population, staff generation/employment, and staff continuity/careers are
  authoritative deterministic systems.
- Every weekly or seasonal people outcome records structured reasons; changes are bounded and
  reproducible from the root seed and input state.
- Twenty target-scale seasons retain plausible roster counts, age/class distributions, position
  coverage, and staff coverage; every vacancy resolves and whole-root integrity remains green.
- Existing competition, generation, detailed-match, and scheduler fingerprints remain explicit.

## Architectural contracts

- Persistent person IDs survive employment changes. Current state and career history are separate;
  an organisation roster is an assignment, not identity ownership.
- `PeopleState` owns availability, fatigue, development summaries, and compact career records.
  Match and UI consumers receive projections, never recompute health or progression.
- Development is causal: age curve, work ethic, usage, coaching quality, scheme fit, and declared
  focus contribute named integer components. RNG may select among equally justified attributes but
  may not invent unexplained total growth.
- Injury risk is based on workload, fatigue, and durability. Recovery is processed before new
  practice/game effects in the fixed scheduler order.
- College graduation/eligibility and pro retirement happen only at season rollover. Replacement
  generation restores legal, playable rosters before the next schedule becomes active.
- Staff vacancies are filled through the same deterministic candidate/evaluation machinery for AI
  and user organisations. M2 may auto-resolve all vacancies; delegation exceptions activate later.
- Hot per-person summaries are bounded. Durable identity/career facts use typed domain events and
  compact season records rather than prose.

## Task 1 — People-state and career contracts (TDD)

Add bounded health/development/career state keyed by player/staff ID, availability semantics,
structured development reasons, compact season lines, and decode/integrity checks. Bootstrap must
cover every person exactly once without duplicating identity data.

Tests first: deterministic bootstrap, save round-trip, bounds, missing/orphan keys, and no UI truth.

## Task 2 — Staff population and employment (TDD)

Generate a head coach, four coordinators, and one coach per position group for every organisation.
Give each persistent identity ratings, scheme preferences, role fit, age/reputation/career state,
and exactly one employer. Add deterministic vacancy filling and continuity increments.

Tests first: exact role coverage, one employer, rating/age bounds, same-seed bytes, planted vacancy,
and vacancy resolution at target scale.

## Task 3 — Weekly fatigue, injury, recovery, and usage (TDD)

Activate `injuriesAndRecovery`. Recover existing injuries, decay fatigue, derive game workload from
recorded participation/statistics, apply bounded fatigue, and create explainable injuries from
durability/workload/fatigue. Availability must affect the abstract match profile rather than remain
cosmetic.

Tests first: deterministic replay, recovery reachability, fatigue bounds, durability direction,
injured-player exclusion, and structured events.

## Task 4 — Weekly and offseason development (TDD)

Activate `practiceAndDevelopment`. Apply small weekly progress from work ethic, usage, staff quality,
scheme fit, age curve, and recovery allocation; apply visible decline after position thresholds.
Store bounded component explanations and emit meaningful development events only above a threshold.

Tests first: potential/rating caps, age direction, work-ethic and staff-quality direction, identical
replay, explanation sums, and no growth beyond hidden potential without an explicit exception.

## Task 5 — Eligibility, retirement, replacement, and careers (TDD)

At rollover, advance age/eligibility, graduate exhausted college players, retire professionals on a
position/age curve, append compact career lines, and generate replacements sufficient for legal
playable rosters. Later recruiting/draft systems replace the provisional replacement intake; log
that dependency without fabricating those markets.

Tests first: four-in-five eligibility, redshirt-safe transition contract, retirement direction,
stable roster size/position coverage, persistent departed identities/history, and deterministic
next population.

## Task 6 — Integrity, soak, adversarial review, and status

Activate eligibility-transition and people-state checks. Run focused planted corruption tests,
the complete repository gate, and a 20-season target-scale soak measuring distributions, vacancies,
runtime, and save growth. Adversarially inspect causality, history bounds, and AI-equivalent vacancy
handling; patch confirmed issues and update status/future contracts.

Per owner direction, `rewrite-tournament` and `confidence-review` remain deferred to final product
verification. Ordinary milestone adversarial review, determinism, integrity, and tests still run.

## Completion record — 2026-08-11

All six tasks and the M2 exit gate are complete. The final full gate passed debug and release builds
plus **330 tests / 710,609 checks**. The final release soak passed **20 seasons / 420 weeks / 326
checks** in **677.408770083 seconds**, with uncompressed save checkpoints of **22,119,600 bytes** at
season 1, **35,262,057 bytes** at season 5, and **84,659,139 bytes** at season 20.

The adversarial review found and fixed decoder-bypass paths for nested development, career,
assignment, and departed-player records, plus missing active-player age validation. The earlier
full departed-player objects were replaced with compact identities, reducing the 20-season save
from 136.99 MB to 84.66 MB and the first measured soak runtime from 911.94 to 677.41 seconds. The
remaining save-growth miss is registered for compressed/chunked persistence rather than concealed.

The same-position `provisionalReplacement` source is explicitly a dependency bridge. M3 recruiting
must replace college intake; M6 draft/free agency must replace professional intake. Redshirt choice,
portal movement, scholarship accounting, NIL, staff poaching, and coaching trees remain owned by
their named later milestones.
