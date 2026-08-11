# M5 — Career stakes

## Scope

Make the coach's job persistent and consequential before building the professional roster market.
The state must remain deterministic, calendar-bound, save-safe, and owned by the engine rather than
by a UI surface.

## Delivered

- `CareerArcState` stores the current job, bounded job history, four stakeholder support values,
  deterministic opportunities, and employment status.
- Weekly completed games adjust support against a prestige-derived expectation; low support can fire
  the coach in-season.
- Season-end evaluation creates a deterministic professional opportunity after sustained success and
  preserves the job history across rollover.
- Root integrity validates organisation ownership, tier, chronology, control alignment, and future
  dates. Stakeholder encoding is canonical so identical seeds produce identical save bytes.
- The fixed scheduler evaluates weekly stakes after statistics and season stakes before schedule
  replacement.

## Evidence

- Career arc: **8 tests / 35 checks**, all passed.
- Controlled career: **11 tests / 77 checks**, all passed.
- Core contracts: **144 tests / 873 checks**, all passed.
- Strict Swift-5 concurrency build: passed with no warnings.
- Architecture/determinism: **25 tests / 222 checks** in two rebuilt runs.

## Remaining

The engine now accepts a professional offer or resignation through the intent boundary. An inbound
inbox event model, coaching-carousel transitions after a job ends, the professional
roster/cap/draft/free-agency market, and the M6 career continuation are not claimed by this slice.
Detailed-game call-ins from M4 remain separate work.
