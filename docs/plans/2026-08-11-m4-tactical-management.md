# M4 — Tactical management

## Scope

M4 keeps tactical choices pure, deterministic, and persisted at the weekly simulation boundary.
Balanced defaults remain explicit, so callers that do not submit a plan retain the established
policy rather than receiving hidden state.

## Delivered

- `TacticalPlan` models run/pass bias, tempo, and defensive pressure as immutable,
  `Codable`, `Sendable` value data.
- `OpponentScoutingSnapshot` derives pass and turnover rates only from observed
  season totals and rejects impossible persisted percentages.
- `TacticalCoordinatorSystem` produces a deterministic, rating- and opponent-aware
  plan without consulting hidden opponent attributes.
- `TacticalPlayCaller` applies the plan to the existing situation-aware detailed
  caller while preserving fourth-down and clock guards.
- `AbstractGameSimulator` accepts an optional plan map. Plans alter expected points,
  score variance, and passing share; the legacy overload is an explicit balanced-plan
  wrapper.
- Schema 8 adds `TacticalState` to the authoritative root. It carries calendar-bound game
  plans, practice allocations, opponent snapshots, and bounded post-game reviews through save/load.
- `TacticalPracticePlan` spends exactly 60 minutes across install, conditioning, recovery, and a
  position focus. The existing development system consumes its value, with focused plans trading
  development between position groups.
- `TacticalCallInSystem` produces a deterministic, inspectable proposal with at most three options,
  a recommendation, rationale, and named risk for every supported situation trigger.
- `CoachIntent` now owns game-plan and practice-plan writes; root integrity validates their
  organisation and calendar authority. The scheduler consumes plans before games and records
  reviews after results.

## Evidence

- Tactical focused gate: **6 tests / 67 checks**, all passed.
- Tactical state/intent gate: **5 tests / 16 checks**, all passed.
- Competition compatibility: **32 tests / 6,315 checks**, all passed.
- Core contracts: **144 tests / 867 checks**, all passed.
- Strict-concurrency FootballSimCore build: passed with no warnings.
- Schema-8 architecture fingerprints: **25 tests / 222 checks**, passed in two rebuilt runs.

## Remaining M4 work

Detailed-game call-in choices still need to be threaded through the live match session and the
controlled career actor. Production UI/read models remain deferred until the M8 proof gate; no
SwiftUI or simulator skill is activated until a launchable production surface exists.
