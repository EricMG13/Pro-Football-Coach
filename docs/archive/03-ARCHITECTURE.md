# 03 — Technical Architecture (rebuild)

How the software is shaped. Gameplay rules live in `02-GAME-DESIGN.md`; feel and staging in `DESIGN.md`; screens in `04-SCREENS-UI.md`. This document is designed for the new game, not inherited from v1 — but it carries v1's *validated behavior* forward as acceptance specifications (§6), because that knowledge is the project's moat.

**The one thing the old architecture got wrong:** it had no presentation pipeline. The engine already returned a `WeekReport` — results, news items, phase — and the UI threw it away, then re-derived a thinner picture by diffing an `@Observable` league value. Everything the game knew about its own drama died at that boundary. §5 exists so that cannot recur.

## 1. Stack

| Decision | Choice | Why |
|---|---|---|
| UI | SwiftUI, iOS 17+, stock controls | The genre is lists, cards, and staged numbers; no game engine needed |
| Language | Swift 6 toolchain, Swift 5 language mode (as today), strict concurrency on the engine | Catches sim/UI data races without a full Swift 6 migration in phase 1 |
| State | `@Observable` + unidirectional flow | Native, no dependency |
| Dependencies | **None** | Everything needed is stdlib/Foundation/SwiftUI/CoreHaptics/AVFAudio |
| Engine | Local Swift package `FootballSimCore` — zero UI imports | Pure, deterministic, testable without a simulator |
| Persistence | `Codable` JSON slots, versioned, off-main | Human-readable, migratable, durable |
| Backend | None. Fully offline | Product constraint |

## 2. Module layout

```
Package.swift
├── FootballSimCore/            Swift package — ZERO SwiftUI/UIKit imports
│   ├── Model/                  League, Team, Player, Contract, StatLine, GameRecord,
│   │                           Staff, CoachProfile, Position, Ratings
│   ├── Rules/                  LeagueRules (all constants), PlayMatrix, TeamTable, Scenario
│   ├── Engine/                 GameSimulator, PlayResolver, PlayCaller, SeasonEngine,
│   │                           OffseasonEngine, CapEngine, ContractPricer, TradeEngine,
│   │                           FreeAgencyEngine, DraftEngine, ProgressionEngine,
│   │                           ScheduleGenerator, StandingsCalculator, CoachEngine,
│   │                           RecordsBook, MatchupOdds
│   ├── Chronicle/              *** NEW — the witness layer's engine half ***
│   │                           LeagueEvent, EventKind, Salience, Chronicle,
│   │                           StoryHook, HookLedger, CareerLedger, Storyteller
│   ├── Generation/             LeagueFactory, PlayerFactory, DraftClassFactory, NameBank
│   └── Support/                SeededRandom, CodingSupport, SaveFormat
├── ProFootballCoachUI/         SwiftUI layer
│   ├── App/                    AppState (the only mutation funnel), Router
│   ├── Presentation/           *** NEW — the feel layer's UI half ***
│   │                           FeedStore, CardModel, StagingDirector, Channels
│   │                           (HapticsService, SoundService), MotionTokens
│   ├── DesignSystem/           Tokens, RatingTier, TeamTheme, components (Card, FeedCard,
│   │                           ScoreStrip, StakesPanel, StagedFigure, LedgerRow,
│   │                           DataTable, SwingChart, Chip, TeamMark, EmptyState)
│   ├── Features/               one folder per screen family (per 04-SCREENS-UI)
│   └── Persistence/            SaveStore, SaveQueue, SaveMigrator
└── Tests/                      engine suites, presentation suites, design-system suites,
                                acceptance suites (§6), soak
```

Rules: `Features/X/` holds `XView.swift` + `XModel.swift` + subviews. **Views never call engine statics** — v1 had ~28 such call sites; all engine access routes through `AppState` or a feature model. `FootballSimCore` never imports SwiftUI. `Chronicle/` never imports UI; `Presentation/` never contains game rules.

## 3. Core model

`League` stays one `Codable` value type — the whole save state — because value semantics are what make determinism, snapshots, and undo cheap.

```swift
struct League: Codable, Sendable {
    var version: Int                 // saveFormatVersion
    var rng: SeededRandom            // persisted; the stream survives save/load
    var year: Int
    var phase: SeasonPhase           // .preseason / .regularSeason(week:) / .playoffs(round:) / .offseason(stage:)
    var teams: [Team]                // 32
    var schedule: [ScheduledGame]
    var results: [GameRecord]
    var freeAgents: [Player]         // bounded
    var draftClass: [DraftProspect]
    var userTeamID: Team.ID
    var coach: CoachProfile
    var settings: LeagueSettings
    var history: [SeasonSummary]
    var hallOfFame: [HallOfFamer]

    // NEW — the witness layer's persisted state
    var chronicle: Chronicle         // recent events (bounded ring) + the season's narrative spine
    var hooks: HookLedger            // active storylines with deadlines (Pillar P1)
    var promises: [Promise]          // max 3 active (02 §6)
    var ledgers: [Player.ID: CareerLedger]   // permanent, append-only (Pillar P5)
}
```

Money = `Int` dollars. Ratings = `Int` 40–99. IDs = `UUID`, **always minted from the seeded RNG** (`rng.uuid()`), never `UUID()`.

This is a live determinism hazard in v1, and its shape matters: `id: UUID = UUID()` is a *default parameter value* on at least nine model and engine initializers (`Player`, `Team`, `League`, `Staff`, three in `GameRecord` including `PlayEvent`, `TradeEngine`, `CoachEngine`). Any call site that omits the argument silently mints an unseeded ID, and the determinism tests cannot see it because they compare scores and stats, not identities. The new rule: **no default-valued `UUID()` parameters anywhere in the engine** — IDs are always passed explicitly from the seeded stream — enforced by a source-scanning test in the same family as the one guarding seed derivation.

Player stats stay outside `Player` (folded from `results` + `history`) — but folding is now cached (§7), because v1's fold-per-render was a measured performance defect.

## 4. Engine principles

- **Deterministic.** Every entry point takes `inout SeededRandom` (SplitMix64). Seeds derive from identifier *bytes* via `SeededRandom.seed(from:)` — never `UUID.hashValue`, which Swift salts per process. This is v1's hardest-won bug; it survives as a test that scans engine sources.
- **Pure.** Engines are caseless enums of static funcs over `inout League`. No singletons, no `Date()`, no ambient state.
- **One engine, one truth.** Quick Sim, Call the Plays, and On the Field run the same `GameSimulator`; retaining the play log cannot change a result (asserted).
- **Stepwise.** `GameSimulator.advance(rng:userCall:execution:)` resolves exactly one snap or transition, so all three modes drive the same state machine at different granularities.
- **Speed.** A full week (16 games) simulates in <150 ms on an A15; a season <5 s. Non-user games run with `retainPlays: false`.

## 5. The presentation pipeline (the architectural addition)

The witness layer is a pipeline, not a feature. Its absence is what the old architecture got wrong, so it is specified structurally.

```
engine mutation ──emits──▶ [LeagueEvent] ──Storyteller──▶ [Card] ──FeedStore──▶ FeedCard views
      │                         │                             │
      │                         └─ HookLedger updates         └─ StagingDirector ──▶ motion + Channels
      └─ CareerLedger appends                                                          (haptics, sound)
```

**5.1 `LeagueEvent` (engine, `Chronicle/`).** Every engine action that changes something a player could care about returns events alongside its result. Not optional, not opt-in: engine entry points return `(League, [LeagueEvent])` or append to an `inout Chronicle`. Event kinds cover the sources in 02 §11 (game results, injuries, development, cap/contract, promises, fragility, milestones, records, hooks, league news, phase transitions). Each event carries: kind, involved player/team IDs, magnitude, the numbers it needs, and a cause reference — **cause is mandatory** (the consequence-with-story law, 02 §11; an event that cannot name its cause is a bug, enforced by a test).

**5.2 `Storyteller` (engine).** Pure function: `(Chronicle, League, inout SeededRandom) -> [Card]`. Scores each event for salience (user-team relevance, featured-player involvement, magnitude, hook advancement, rarity), selects 3–7 per week, and matches each to an author-written template by state (ADJ-48 matching-not-assembling), casting a press voice. Deterministic — the same save produces the same narration, which also makes narration testable.

**5.3 `HookLedger` (engine).** Tracks active storylines with deadlines and maintains the **horizon invariant**: at any week, at least one hook resolves within three weeks (Pillar P1). The ledger *schedules* — when the horizon would go empty, it promotes a candidate (record pace, contract clock, streak, job security, milestone watch). Soak-asserted.

**5.4 `FeedStore` (UI, `Presentation/`).** Owns the card queue, severity tiers, blocking semantics (a card blocks the advance only with deadline semantics — OD-3), and read state. It is the *only* thing that decides what the player sees next.

**5.5 `StagingDirector` (UI).** Maps a card or reveal to its staging spec from `DESIGN.md` §2.3 — anticipate → hold → resolve → settle — and drives the motion tokens plus the channel services in one place. **Single-owner rule:** exactly one layer fires feedback per event; engines never fire feedback, views never fire feedback directly, only the director does. This prevents the double-buzz class of bug by construction.

**5.6 `Channels` (UI).** `HapticsService` (Core Haptics, semantic events per `DESIGN.md` §2.5, lazy engine start, capability-gated once, stopped on background, user toggle, injected as an optional seam so tests pass `nil`) and `SoundService` (preloaded `.caf` PCM, `.ambient` + `.mixWithOthers` session, silent-switch respected, user toggle, 8–12 variants per repeated sound). Both speak the same semantic event enum; game code fires meaning, the services decide channels. Neither is ever the sole carrier of state — VoiceOver announcements accompany staged reveals.

**5.7 Reduce Motion.** A build-time-checked contract: every named motion in `DESIGN.md` §2.2 has an RM variant, and `StagingDirector` selects it from `@Environment(\.accessibilityReduceMotion)` at one site. Haptics and sound are never gated on Reduce Motion.

## 6. Engine acceptance specifications

The behavioral contract from the validated v1 (`docs/STATUS.md`) restated as specifications the **new** engine must re-earn with its own tests. These are gates, not aspirations: engine phases do not close until every band holds.

**6.1 Determinism**
- Same seed + same inputs ⇒ byte-identical `League` after a full season.
- Determinism holds **across processes**: a save produces the same league on a fresh launch (v1's cross-process bug came from `UUID.hashValue`).
- A source-scanning test forbids `UUID()` and `Date()` inside `FootballSimCore`.
- `retainPlays: true` vs `false` produces identical results (mode parity).
- Narration is deterministic: the same save produces the same cards.

**6.2 Calibration bands** (per simulated season, asserted over a ≥600-game sample)

| Metric | Band |
|---|---|
| Points per team-game | 20–26 |
| Pass yards per team-game | 195–245 |
| Completion % | 61–67 |
| Rush yards per team-game | 100–130 |
| Interceptions per team-game | 0.6–1.1 |
| Sacks per team-game | 2.0–3.1 |
| Field-goal % | 80–90 |
| Overtime rate | 0.8%–14% |
| Home win rate | 50–60% |
| Plays per team-game | 55–72 |

**6.3 Believability bands** (added because the sibling community's complaints were about *plausibility*, not averages)

| Metric | Band |
|---|---|
| Q4 share of scoring | 22–32% |
| Explosive plays (25+ yds) per game | 3–9 |
| Touchdowns of 40+ yds per game | 0.2–1.2 |
| Safeties per game | ≤ 0.05 |
| TE target share | 15–26% |
| RB target share | 10–28% |
| Max single-receiver target share | ≤ 45% |
| Ratings predictiveness | 12+ OVR gap ⇒ favorite wins ≥72% |

**6.4 Cap legality invariants**
- No team exceeds the cap outside the sanctioned dead-money overage (≤ cap/20), at any point in a ten-season run.
- Sum of contract cap hits + dead money = committed cap, exactly, in integer dollars.
- A practice-squad move can never reduce a player's cap charge below his contract's obligation (v1's laundering hole — carried forward as a permanent test).
- Every roster is exactly 53 active with position minimums satisfied after cutdown.

**6.5 The ten-season soak** (unattended, one seed, asserted at the end)
- Ten seasons complete; ten champions; no crash.
- Average OVR per year within 62–76, drift across the decade < 6.
- Average age per year within 23–30.
- Churn: no team in the top five all ten years; ≥3 distinct champions.
- Cap legal every year; cap grows.
- Save round-trips byte-identically and stays < 5 MB.
- Bounded growth: free agents ≤ 400, chronicle and news bounded, oldest free agent < 38.
- **New (witness layer):** zero silent weeks — every week produces ≥1 card; the hook horizon never empties (≥1 hook within 3 weeks in ≥95% of weeks); no card lacks a face or a cause; template repetition stays under the perceptual-uniqueness bar (no template fires twice within 10 weeks for standout events).

**6.6 Performance budgets**
- Week advance end-to-end (sim + chronicle + persist enqueue) < 150 ms on an A15.
- No main-actor file I/O, ever. Persistence is an actor; the UI observes a write-state, and a failed write surfaces to the user (v1 captured save errors into a field no view ever read).
- No per-render league folds: season and career stat aggregates are cached and invalidated on mutation.

## 7. Persistence

- One JSON file per save + a `.meta.json` sidecar (team, year, coach, timestamp, **active hook line** so the load list can greet you mid-story) + a rolling `.backup.json`.
- Writes go through a coalescing actor: one write per user action, never one per mutation. Atomic write, then backup rotation. Load falls back to the backup with an explicit notice.
- `SaveMigrator` reads the version from the cheap sidecar (not by re-parsing the whole file), switches on it, and every format change ships a migration plus a fixture test.
- Unknown fields decode to defaults so an older save still opens.
- Stat lines omit zero fields; finished seasons keep aggregates, not play-by-play. Chronicle keeps a bounded ring plus the season's narrative spine.

## 8. Concurrency

- `League` is `Sendable` value state; sim runs off-main via `Task.detached` for multi-week and multi-season work; results are reassigned on the main actor.
- `AppState` is `@MainActor` and owns **the single mutation funnel** — `mutate` is the only path that assigns `league`. v1 had six methods bypassing it; a test asserts the funnel is the sole assignment site.
- Live game streams through the stepwise simulator; the arcade's ticking values live in their own small views so a 60 Hz meter cannot invalidate the whole screen (v1 rebuilt the entire game view 62 times a second).
- Timing-critical loops derive from wall-clock deltas, not accumulated fixed steps.

## 9. Testing strategy

- **Engine:** TDD, one suite per engine, plus property checks (cap never illegal, schedule well-formed, draft order correct). The v1 harness (a hand-rolled TestKit, because XCTest is absent from the Command Line Tools) is retained *as a fallback*; prefer swift-testing when the toolchain in use provides it. Suites must self-register — v1's manual `main.swift` list is a silent-skip hazard.
- **Acceptance:** §6 as its own suite, run every phase.
- **Presentation:** the `Storyteller` is pure and therefore unit-tested — salience selection, template matching, no-faceless-card, cause-present, determinism. Coverage tests assert every `EventKind` has at least one template and one witnessing surface (Pillar P2 enforced mechanically).
- **Design system:** the coverage law — every color pairing in the token set is contrast-tested against its real composited surface in both themes; every team primary tested against white; a test fails the build when a new pairing is introduced without a test.
- **UI:** compiled and exercised in the simulator each phase; the cold-play gate is human, not automated.

## 10. Out of scope (v1)

Multiplayer, iCloud sync, Game Center, widgets, iPad layout, monetization, Android. Nothing above blocks them.

## 11. Open architecture decisions

- **OD-4 (from gate 1):** whether the `Storyteller` uses salience-matched templates (v1 floor) or a Wildermyth-style casting engine with typed roles and re-voicing. Decide with template-library sizing math in hand — the sizing question (how many templates survive a ten-season soak without perceptual repetition) is itself an input, and §6.5's repetition assertion is how it gets measured.
