# M3 — College management game

Authority: Master Build Documentation `00`–`06`, especially the Phase E/F dependency order and M3
gate; retained college rules and lifecycle contracts in `docs/02-GAME-DESIGN.md`. This milestone
replaces the college half of M2's provisional intake with an interconnected recruiting, scholarship,
redshirt, portal, and NIL ecosystem operated under the same constraints by the user and AI.

## Exit gate

- One complete college career can run headlessly through repeated recruiting, signing, roster,
  eligibility, redshirt, portal, NIL, development, competition, and offseason cycles.
- Every programme fills legal rosters under scholarship/resource constraints through the same
  deterministic decision machinery; no hidden AI-only roster repair is needed.
- Recruiting-class strength, geographic reach, commitment timing, portal churn, redshirt use, and
  roster age/position distributions remain plausible across a 20-season target-scale soak.
- Every consequential interaction records stable IDs and structured reasons that can later drive
  recruit histories, rivalries, reputation, inbox, and read models.

## Architectural contracts

- `CollegeState` owns authoritative recruiting cycles, scholarship allocation, NIL resources,
  portal windows, redshirt decisions, and bounded recruiting history. Prospects exist once in a
  normalized store; boards and classes store IDs.
- `ScoutingState` separates true prospect ability/potential from observer-specific estimates,
  confidence, evidence count, and last-updated calendar. AI and user evaluators consume only their
  permitted knowledge.
- Recruiting resolves from programme need, geography, fit, staff recruiting quality, relationship,
  playing-time path, team trajectory, NIL, contact/visit investment, and uncertainty. Every score
  produces named components; seeded randomness breaks justified ties rather than inventing desire.
- One deterministic decision policy evaluates legal actions for every programme. User intents and
  AI actions share validation, costs, constraints, state transitions, and event payloads.
- Scholarship and NIL money use centralized integer rules. No negative budget, double offer,
  over-signed class, exhausted eligibility, or orphan commitment can survive a scheduler boundary.
- Portal intent reads playing time, relationships available at this milestone, NIL, roster path,
  and team success. Transfer destinations use the same fit/knowledge framework as high-school
  recruiting. Every departure and arrival remains historically queryable.
- Redshirt is an explicit season decision. It spends an eligibility-clock year without spending a
  competition season and must be decided before rollover from recorded usage.
- M3 removes college `provisionalReplacement` generation. If a late-cycle emergency bridge is
  needed, it must be a truthful walk-on domain concept with explicit limits and history—not an
  invisible roster repair.

## Task 1 — College, prospect, knowledge, and resource contracts (TDD)

Add bounded normalized prospects, recruiting cycles/windows, programme boards, scholarship offers,
NIL allocations, observer knowledge, recruiting relationships, redshirt state, portal state, and
signed-class records. Extend save decoding and whole-root integrity before enabling resolution.

Tests first: deterministic bootstrap/encoding, truth-versus-observation separation, hostile decode,
unique ownership, bounded boards/evidence/history, integer budgets, and missing/orphan references.

## Task 2 — Recruiting pool and scouting/evaluation (TDD)

Generate geographically grounded annual prospect pools with position, ability, potential,
personality/importance factors, and original identity. Activate `scoutingKnowledge`; staff quality,
evaluation work, and evidence improve confidence without mutating truth or leaking exact hidden
ratings.

Tests first: same-seed bytes, position/region/rating distributions, confidence monotonicity and cap,
observer isolation, no truth leakage in projections, and target-world performance.

## Task 3 — Shared recruiting decision engine and weekly market (TDD)

Implement legal actions—evaluate, contact, offer, visit, NIL allocation, withdraw—and a scored
candidate-action policy used by every AI programme. Activate `rosterAndMarketInteractions` and
`aiTeamDecisions` for college recruiting in their fixed scheduler order. Store scored reasons and
emit typed events for relationships, offers, visits, board changes, wins, and losses.

Tests first: cost/offer validation, need/geography/fit/staff/NIL directions, deterministic tie breaks,
AI information limits, impossible-target abandonment, budget legality, and replay identity.

## Task 4 — Commitments, signing, scholarships, and roster intake (TDD)

Resolve commitment timing and flips from accumulated state, then run signing day and authoritative
scholarship accounting. Convert signed prospects into persistent players with recruiting history and
development state. Remove college provisional replacements and prove every programme reaches legal
position coverage through market outcomes plus explicitly modeled walk-ons if necessary.

Tests first: one commitment/programme, signed-player identity continuity, scholarship limits,
oversigning prevention, class-strength distributions, positional-need direction, and no roster
repair outside declared intake sources.

## Task 5 — Redshirts, portal, retention, transfer destinations, and NIL (TDD)

First add a deterministic per-team participant manifest to every recorded game and aggregate true
appearances separately from production statistics. Stat lines cover only ball production and cannot
truthfully decide whether linemen, defenders, specialists, or reserves used a season of competition.

Record usage-aware redshirt decisions, calculate explainable portal intent, process retention
attempts and NIL changes, and match entrants to destinations through the shared fit system. Preserve
eligibility, player identity, career/recruiting history, and domain events across transfer.

Tests first: four-in-five clock behavior, redshirt usage legality, playing-time/NIL/success
directions, transfer identity preservation, scholarship release/acquisition, no duplicate ownership,
and bounded portal windows.

## Task 6 — Full-cycle AI, projections/intents, and interconnection (TDD)

Expose immutable backend projections and explicit intents for future recruiting surfaces without
building production UI. Add routine delegation policy boundaries and mandatory exception records
where a meaningful user choice would later be required. Feed recruiting staff ratings, roster
planning, development history, programme prestige, competition results, and geography into the
cycle; feed signed/transfer players into M2 lifecycle and future history consumers.

Before exposing those surfaces, add a controlled-programme/career boundary so scheduled AI never
also acts for the player's organisation, and replace UUID-only pending queues with typed mandatory
decisions containing subjects, deadlines, stable option IDs, recommendations, causal reasons, and
delegation ownership. Presentation-facing intents must derive programme authority from the session;
they must not accept an arbitrary organisation ID or return the authoritative `GameState`.

Tests first: projection truth/uncertainty, intent parity with AI legality, deterministic deltas,
exception thresholds, complete headless user-policy career, and no UI access to `GameState`.

## Task 7 — Integrity, calibration, soak, adversarial review, and status

Activate the remaining FSC-005 checks. Run planted corruption/property tests, recruiting-cycle and
college-career system tests, the complete repository gate, and a target-scale 20-season soak with
save/load checkpoints. Measure week time, recruiting-resolution time, pool/class distributions,
scholarships, NIL, portal churn, redshirts, ages, ratings, AI legality, history growth, and save
growth. Adversarially inspect fog-of-war, causal reasons, AI parity, hidden roster repair, and
collection bounds; fix confirmed defects and update status/contracts.

Per owner direction, `rewrite-tournament` and `confidence-review` remain deferred to final product
verification. Ordinary milestone adversarial review, determinism, integrity, and tests still run.

## Development skill gate

Use the installed `swift-concurrency-pro` skill for Task 5's atomic portal transaction and Task 6's
scheduler/intent boundary before M3 exits. Apply its actor-isolation, reentrancy, cancellation, and
`Sendable` checks, but retain Swift 5 language mode and the repository's TestKit harness. The UI,
simulator, and accessibility skills remain dormant until the production UI foundation exists. The
complete activation and project-local creation schedule is
`docs/plans/2026-08-11-skill-integration.md`.

## Current checkpoint — 2026-08-11

- Tasks 1–2 are implemented and gated: schema-v3 college/prospect/scouting state, 4,020 annual
  prospects, observer-scoped evaluation, deterministic generation, hostile decoding, and integrity.
- Task 3's shared action resolver and weekly AI market are active. All 134 programmes use the same
  costs and legality as explicit coach intents; unscouted fit cannot read hidden ability. A weekly
  fit cache reduced AI market time from 3,124 ms to 67 ms in the focused release benchmark.
- Task 4's backend is implemented; its class-distribution calibration is active. Commitments reserve
  projected roster and scholarship openings with positional coverage, global races and flips retain
  causal contender snapshots, and signing conserves every commitment through a typed signed/released
  outcome. Week-21 rollover signs with identity continuity, fills only remaining legal vacancies
  with explicit lower-rated walk-ons, renews the 4,020-prospect pool, and leaves the professional
  provisional bridge intact for M6.
- Recruiting AI now grows boards by five per week to `min(40, projected class target + 15)`, stages
  up to fifteen ranked investments per programme, refunds losing NIL pursuits exactly, and culls
  routine work once commitment capacity is full. Root integrity validates stable cycle phases,
  commitment chronology/snapshots, terminal identity categories, and exact recruiting NIL totals.
- Recent-event resolution and durable recruiting history now have separate lifetimes. Unsigned
  former prospects retain only compact identities while hot events reference them; signed players
  retain immutable recruiting origin in their career. Exact tombstone pruning runs after event
  eviction, and integrity enforces pairwise active-prospect/player/archive disjointness.
- Task 5's participation prerequisite is active: recorded results carry side-specific participant
  manifests, appearances aggregate independently of production, and integrity checks participants
  against current roster ownership. Dated roster-tenure history is explicitly required before any
  future in-season movement can make that ownership time-dependent.
- Task 5's NIL prerequisite is active under save schema 5. Each programme has one seasonal ledger
  for roster allocations, recruiting reservations, and future portal reservations; remaining money
  is derived, category identities are disjoint, and hostile decoding rejects overcommitment.
  Signing reclassifies the exact recruiting reservation into the signed player's roster allocation,
  losing pursuits refund it, departures remove it, and rollover carries only retained roster money.
  Usage-aware redshirt plans are also authoritative: participant manifests drive appearances,
  designation changes game availability, four-or-fewer appearances can preserve a season, typed
  history precedes departure, and strict decoding rejects erased plans or impossible eligibility
  clocks. The focused college-state, commitment, and redshirt gates pass **39 tests / 3,600
  checks**, **25 / 124**, and **33 / 104**.
- The portal implementation contract is now fixed around two atomic windows. Postseason runs only
  after redshirt/eligibility resolution, signing, and next-season NIL renewal, then persists a
  minimum-position-legal `awaitingSpring` roster without filling every vacancy. Spring resolves in
  next-season week 1 before any game and only then fills remaining vacancies with explicit walk-ons.
  Recruiting stays `.active`; portal owns a separate phase machine. The authoritative move preserves
  player/lifecycle/eligibility/career identity and commits roster, scholarship, NIL, offers, career
  history, and events as one rollback-safe batch. The redshirt dependency is live. Schema 6 now
  requires stable season-bound portal state, exact atomic NIL reclassification, and durable player
  portal history with usage, five-year clock, source, scholarship, NIL, tenure, transfer, and
  career-end continuity. Frozen intent/retention policy, capacity-aware matching, the sealed
  transaction, events/integrity, and both scheduler windows are implemented and focused gates pass.
- The first deterministic one-season recruiting calibration was structurally green but plausibly
  red: median class **2** versus median target **21**, **902** scholarship signings versus **2,576**
  walk-ons, and **102.109 s / 105.813 s** for two byte-identical runs. The focused gate now requires
  at least 50% aggregate/median fill, at least 75% nonempty classes, and no walk-on-majority intake.
  The current policy has since gained capacity-aware culling, causal NIL scoring, reconstructible
  explanations, bounded action conservation, a noncompounding NIL portfolio target, readiness-first
  relationship work, and a final-week terminal market before signing. An immutable fit snapshot
  also removed an O(board entries x whole world) diagnostic rebuild. The unchanged gate now passes:
  **2,177** scholarship signings versus **1,301** walk-ons, **78%** aggregate and **94%** median
  fill, all 134 classes nonempty, legal/covered rosters, byte-identical replay, and exact save/load
  in **76.213 s / 81.268 s**. The old distribution remains only the pre-correction baseline.
- The settled schema-5 release gate is **454 tests / 715,092 checks, all passing** in **498.33
  seconds**. Event-ledger batch append preserves sequential bytes while avoiding repeated hot-ledger
  rebuilding; architecture fingerprints matched across two rebuilt runs. Schema 6 portal work now
  begins from this verified baseline.
- Task 6 is implemented under schema 7. One persisted controlled college job owns explicit
  responsibility assignments; scheduled AI excludes it, while delegated recruiting invokes the
  same policy and legal action authority as every other programme. Typed mandatory decisions carry
  stable option identities, deadlines, recommendations, causal reasons, and durable resolutions.
  `CareerSession` is the actor-owned presentation boundary: intents derive the programme from the
  session, immutable projections expose only observed recruiting estimates, cancellation is checked
  before commit, and neither projections nor the app target can access the authoritative root.
  Complete strict-concurrency diagnostics produced no warnings, actor-race instrumentation passed,
  and the focused career gate passes **11 tests / 77 checks**. Schema fingerprints matched in two
  rebuilt runs at **25 tests / 222 checks**; portal policy, matching, transaction, scheduler, and
  release core compatibility remain green.
- Task 7 is complete. The target-scale soak passed **20 seasons / 421 weeks / 8,307 checks** with
  deterministic save checkpoints through season 20, bounded portal/redshirt history, class sizes
  **3–25** (median **14**), and valid integrity at every checkpoint. The final release suite passed
  **558 tests / 746,742 checks**; the portal scheduler characterization remained byte-identical
  across two second-season replays. `rewrite-tournament` and `confidence-review` remain deferred
  until final product verification as directed.
