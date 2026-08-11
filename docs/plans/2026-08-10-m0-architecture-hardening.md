# M0 — Architecture hardening

Authority: `/Users/ericguei/Documents/Pro-Football-Coach-Master-Build-Documentation/`.
This plan supersedes the old instruction to tune P4 next. Existing P0–P4 work remains a preserved
foundation, but no additional management or production UI work may precede this milestone.

## Phase 0 — Documentation discovery and measured baseline

Sources read in full:

- Master pack `README.md` and `00` through `09`.
- Every Swift source and test file under `Sources/`, `Tests/`, and `App/`.
- `Package.swift`, `App/project.yml`, and the repository verification scripts.
- Current `README.md`, `PRODUCT.md`, `CLAUDE.md`, `docs/STATUS.md`, and the existing roadmap.

Measured baseline on 2026-08-10:

- `swift build`: pass.
- `swift run -c release SimTests`: 263 tests, 78,296 checks, all passed.
- Existing strengths: deterministic seeded generation, centralized rules, stable save encoding,
  causal snap records, whole-game simulation, calibration instrumentation, legal identity gates.
- Missing M0 dependencies: authoritative `GameState`, normalized root ownership, versioned
  scheduler, structured domain-event ledger, intent/projection boundary, and whole-root integrity.

### Allowed APIs and patterns

- Copy the root ownership shape from master `02-DOMAIN-MODEL-AND-DATA-CONTRACTS.md`, section 1.
- Copy the exact weekly ordering from master `00-MASTER-BUILD-BLUEPRINT.md`, section 2B.
- Events carry stable IDs plus occurrence-time context, per master `02`, section 2.
- SwiftUI receives immutable purpose-built projections, never `GameState`, per master `02`,
  section 4.
- Writes enter through explicit intents with validation, deterministic resolution, events, and a
  returned snapshot/delta, per master `02`, section 5.
- Reuse `SeededRandom`, `SeedDerivation`, `SaveEnvelope`, `GeneratedWorld`, and existing model types.
- Continue using the executable `SimTests` harness and `scripts/verify.sh`.

### Anti-pattern guards

- No duplicate entity copies in root state; references use IDs.
- No ambient identity, time, randomness, or salted hashes outside the existing model exemption.
- No UI imports or UI types in `FootballSimCore`.
- No unbounded ledger/history collection.
- No event whose only payload is rendered prose.
- No placeholder management system presented as implemented; unavailable scheduler steps remain
  explicitly inactive until their milestone supplies a system.
- No invented surface values or direct `GameState` exposure.

## Task 1 — Normalized authoritative root (TDD)

Implement:

- `EntityStore<Entity: Identifiable & Codable & Sendable>` with deterministic encoding.
- `CalendarState` with one shared college/pro season and week boundary.
- `GameState` owning the generated league/map/identity/rivalry foundation plus normalized
  programmes, pro teams, players, and staff.
- Deterministic bootstrap from `GeneratedWorld` without changing generated identities or match data.

Verification:

- Test first and observe failure for bootstrap ownership, ID lookup, stable encoding, and save
  round-trip.
- Assert all generated programmes/teams exist exactly once in stores.
- Assert same seed produces byte-identical root state.

## Task 2 — Structured domain-event ledger (TDD)

Implement:

- Stable `DomainEventID` and structured `DomainEvent` envelope.
- Initial event payloads required by M0: world created, week advanced, and integrity checked.
- Bounded recent ledger with deterministic append ordering and explicit archive counters.
- Reference extraction so integrity checks can validate event entity IDs.

Verification:

- Test first and observe failure for deterministic IDs, append order, bounds, and round-trip.
- Plant an event with a missing entity reference and prove integrity rejects it.

## Task 3 — Versioned world scheduler (TDD)

Implement:

- Exact 15-step `WorldStep` order from the master blueprint.
- `WorldScheduler.version` as an explicit compatibility contract.
- Registered system execution by step; absent future systems are reported as inactive, not silently
  simulated.
- A real calendar transition, event emission, integrity pass, and immutable `WeekSnapshot`.
- Hierarchical scheduler seeds derived from the authoritative world seed/season/week/step.

Verification:

- Test first and observe failure for exact ordering, one-week transition, inactive-step reporting,
  deterministic output, and repeated execution from equal state.
- Existing generation and game fingerprints remain unchanged.

## Task 4 — Intent and projection boundary (TDD)

Implement:

- Public `CoachIntent` protocol or closed intent type with explicit validation failures.
- `AdvanceWeek` as the first real intent, blocked by unresolved mandatory work.
- `IntentResult` containing emitted events and a new `WeekSnapshot`, never `GameState`.
- `WeekSnapshotProjector` as a purpose-built immutable read model.

Verification:

- Test first and observe failure for blocked advancement, successful delegated/clear advancement,
  and projection determinism.
- Source contract test prevents `GameState` from being imported/stored by the UI target.

## Task 5 — Whole-root integrity suite (TDD)

Implement M0-reachable assertions:

- entity store key/ID agreement;
- conference/division/member references resolve;
- identities and rivalries reference existing members;
- each rostered player belongs to at most one organization;
- each employed staff member belongs to at most one organization;
- current roster-limit predicates hold;
- ledger references resolve and collection bounds hold;
- calendar values are legal;
- deterministic stable save encoding.

Assertions for schedules, standings, contracts, eligibility transitions, knowledge, and positional
coverage are registered as future checks and become active only when those systems exist.

Verification:

- Unit tests plant one violation per active rule.
- A generated target-scale world passes.
- One scheduler-driven week passes integrity and replays byte-identically.

## Task 6 — Milestone verification and status

- Run the no-argument `rewrite-tournament` on non-trivial changed functions.
- Run `confidence-review`; investigate every low-confidence point and patch confirmed defects.
- Run `scripts/verify.sh`.
- Run same-seed root/scheduler checks in separate process invocations through pinned fingerprints.
- Confirm existing generation and match fingerprints remain unchanged.
- Update `docs/STATUS.md`, `README.md`, and the Future Simulation Contract status truthfully.

M0 is complete only when all master milestone-zero exit gates hold. Calibration remains open and
resumes after the architectural backbone rather than being discarded.

## Completion record — 2026-08-10

Tasks 1–5 and the executable parts of Task 6 are implemented. The final gate passed with 289 tests
and 78,530 checks. Root and one-week transition fingerprints are pinned; existing pins remain green.
The adversarial review's confirmed save-corruption and contract-truthfulness findings were fixed.

Two Task 6 meta-reviews are intentionally deferred: the owner directed that `rewrite-tournament`
and `confidence-review` run once at the end of the complete product build. This is a process
override, not an unreported green gate. The next dependency milestone may proceed while those two
final-build reviews remain open.
