# M7 — conference movement: scope check, 2026-08-13

Written in a toolchain-less session. `docs/02-GAME-DESIGN.md` §8 now carries an agent-recommended,
owner-unconfirmed mechanism (trigger, geography constraint, size constraint, cadence, falsifier) for
this — recorded there per the doc-first amendment rule. This note scopes the implementation; it does
not implement it.

**Where conference membership lives today:** `Sources/FootballSimCore/Model/League.swift` defines
the conference/membership model; `Sources/FootballSimCore/Generation/LeagueGenerator.swift` builds it
once at bootstrap; `Sources/FootballSimCore/Competition/ScheduleGenerator.swift`,
`PostseasonSystem.swift` and `Sources/FootballSimCore/Integrity/WorldIntegrity.swift` all read
conference membership to build schedules, conference championships and validate the root
respectively (`WorldIntegrity.swift` was read this session for the P10c fix and clearly treats
league/conference structure as integrity-checked state, not incidental data).

**Why this is a milestone-sized slice, per `docs/STATUS.md`'s own words, not a single-session
change:** moving a programme's conference membership mid-career touches at least:

1. `League`'s conference membership lists — the mutation itself.
2. `ScheduleGenerator` — next season's schedule must reflect the new conference, including whatever
   rivalry/divisional-game rules it currently encodes.
3. `PostseasonSystem` — conference-championship eligibility and any conference-scoped standings.
4. Rivalry continuity (`Sources/FootballSimCore/Competition/... RivalrySystem`, per `docs/STATUS.md`'s
   M7A section) — a programme's existing rivalries were seeded from its old conference and geography;
   moving conference does not erase an earned rivalry, but a newly conference-mate programme has none
   yet, and `RivalrySeeder` was written for bootstrap-time seeding, not a mid-career join.
5. `WorldIntegrity` — whatever check currently asserts conference membership is stable/consistent
   needs to accept a *legal* mid-career change without weakening its protection against an *illegal*
   one (a hostile save moving a programme to break the 12–16 band, for instance).
6. The pinned root/transition fingerprints in `Tests/SimTests/Suites/ArchitectureTests.swift`, same
   caveat as the P10c plan — any change here needs those recomputed by a real run, not guessed.

**Recommended sequencing for a toolchain session:** implement as its own `WorldStep`-adjacent system
(`ConferenceMovementSystem`, mirroring `ProgrammeEvolutionSystem`'s shape exactly — both read a final
standings/prestige table and mutate `programmes`/`league` once per season at the same rollover point),
gated behind a focused test suite the same way `ProgrammeEvolutionSystem` shipped with **7 tests /
275 checks** per `docs/STATUS.md`'s M7D entry — that is the right-sized proof-of-work bar to match.
Do not attempt rivalry re-seeding for newly-adjacent conference-mates in the same pass; ship
realignment first with "no rivalry yet" as the honest state for a fresh conference-mate, and let
`RivalrySeeder` pick it up as meetings accumulate, the same way any two programmes without history
start.

No code written for this task.
