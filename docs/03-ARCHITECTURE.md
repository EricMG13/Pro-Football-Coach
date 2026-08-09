# 03 — Technical Architecture (rebuild)

How the software is shaped. Gameplay rules live in `02-GAME-DESIGN.md`; feel and staging in `DESIGN.md`; screens in `04-SCREENS-UI.md`. This document is designed for the new game, not inherited from v1 — but it carries v1's *validated behavior* forward as acceptance specifications (§6), because that knowledge is the project's moat.

**The one thing the old architecture got wrong:** it had no presentation pipeline. The engine already returned a `WeekReport` — results, news items, phase — and the UI threw it away, then re-derived a thinner picture by diffing an `@Observable` league value. Everything the game knew about its own drama died at that boundary. §5 exists so that cannot recur.

## 1. Stack

| Decision | Choice | Why |
|---|---|---|
| UI | SwiftUI, iOS 17+, stock controls | The genre is lists, cards, and staged numbers |
| Arcade rendering | SwiftUI `Canvas` + `TimelineView` — **not** SpriteKit | ~23 moving entities is trivial canvas load, it ships zero assets, keeps the macOS compile-verification path alive, and stays inside the app's existing rendering idiom (06 §7) |
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
│   │                           RecordsBook, MatchupOdds,
│   │                           GameplanEngine (focus effects + tendency memory, 02 §5),
│   │                           ScoutingEngine (fog, reports, accuracy grading, 02 §8),
│   │                           AbilityResolver (star abilities + counters, 02 §3),
│   │                           FeaturedSelector (foreground set derivation, 02 §3)
│   ├── Arcade/                 the all-22 spatial layer: SnapKernel, FieldGeometry,
│   │                           Formations, Routes, RunLanes, Openness, Pocket, Coverage,
│   │                           Choreographer, DefensiveInputs (pure; see 06 §5)
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
│   ├── Features/               one folder per screen family (per 04-SCREENS-UI), including
│   │                           OnTheField/ — FieldCanvas renderer + control surfaces (06)
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

    // NEW — homes for the systems 02 declares; each would otherwise be state with nowhere to live
    var gameplans: [Team.ID: Gameplan]        // the week's focus + reps (02 §5)
    var tendencies: TendencyMemory            // what each team has shown; feeds the opponent card
    var featured: [Team.ID: [Player.ID]]      // the foreground set, derived each week and persisted
    var scoutReports: [Player.ID: ScoutReport] // recorded predictions the save later grades (02 §8)
    var challenges: [ChallengeProgress]        // named long-horizon templates (02 §11)
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
- **Speed.** Budgets and their measurement basis live in §6.6 and are stated once there — do not restate them elsewhere. Non-user games run with `retainPlays: false`.

## 5. The presentation pipeline (the architectural addition)

The witness layer is a pipeline, not a feature. Its absence is what the old architecture got wrong, so it is specified structurally.

```
engine mutation ──emits──▶ [LeagueEvent] ──Storyteller──▶ [Card] ──FeedStore──▶ FeedCard views
      │                         │                             │
      │                         └─ HookLedger updates         └─ StagingDirector ──▶ motion + Channels
      └─ CareerLedger appends                                                          (haptics, sound)
```

**5.1 `LeagueEvent` (engine, `Chronicle/`).** Every engine action that changes something a player could care about emits events alongside its result.

**One signature, stated once:** engines keep the `inout League` model of §4 and return their events as a discardable result — the shape `SeasonEngine.advanceWeek(_ league: inout League, …) -> WeekReport` already uses and which already works. Extend that report to carry `[LeagueEvent]`; do **not** introduce a `(League, [LeagueEvent])` return, and do **not** pass `inout Chronicle` separately — `chronicle` is nested inside `League`, so `f(&league, chronicle: &league.chronicle)` is overlapping access to the same variable: a compile error for a local and an exclusivity trap for a stored property.

Event kinds cover the sources in 02 §11 (game results, injuries, development, cap/contract, promises, fragility, milestones, records, hooks, league news, phase transitions). Each event carries: kind, involved player/team IDs, magnitude, the numbers it needs, and a cause reference — **cause is mandatory** (the consequence-with-story law, 02 §11; an event that cannot name its cause is a bug, enforced by a test).

**5.2 `Storyteller` (engine).** Pure function: `(Chronicle, League, inout SeededRandom) -> [Narration]`.

**It returns `Narration`, not `Card`.** `Narration` is an engine-side value (kind, cast IDs, the numbers, the chosen template id, the voice); `CardModel` in `Presentation/` is the UI's projection of it. The engine cannot name a UI type — the package dependency runs UI→Core, and a `Card` in the engine's signature would make it circular, which SwiftPM rejects.

**It never draws from `league.rng`.** Narration takes a *derived* stream — `SeededRandom(seed: SeededRandom.seed(from: league.userTeamID) &+ UInt64(week))`, the pattern already used for draft-class generation — because how often the UI narrates would otherwise advance the same stream the simulator draws from, and §6.1's byte-identical-season guarantee would fail for reasons unrelated to the sim. This is the same defect class as the `retainPlays` parity risk.

The function scores each event for salience (user-team relevance, featured-player involvement, magnitude, hook advancement, rarity), selects 3–7 per week, and matches each to an author-written template by state (ADJ-48 matching-not-assembling). Deterministic, and therefore testable.

**5.3 `HookLedger` (engine).** Tracks active storylines with deadlines and maintains the **horizon invariant**: at any week, at least one hook resolves within three weeks (Pillar P1). The ledger *schedules* — when the horizon would go empty, it promotes a candidate (record pace, contract clock, streak, job security, milestone watch). Soak-asserted.

**5.4 `FeedStore` (UI, `Presentation/`).** Owns the card queue, severity tiers, blocking semantics (a card blocks the advance only with deadline semantics — OD-3), and read state. It is the *only* thing that decides what the player sees next.

**5.5 `StagingDirector` (UI).** Maps a card or reveal to its staging spec from `DESIGN.md` §2.3 — anticipate → hold → resolve → settle — and drives the motion tokens plus the channel services in one place. **Single-owner rule:** exactly one layer fires feedback per event; engines never fire feedback, views never fire feedback directly, only the director does. This prevents the double-buzz class of bug by construction.

**5.6 `Channels` (UI).** `HapticsService` (Core Haptics, semantic events per `DESIGN.md` §2.5, lazy engine start, capability-gated once, stopped on background, user toggle, injected as an optional seam so tests pass `nil`) and `SoundService` (preloaded `.caf` PCM, `.ambient` + `.mixWithOthers` session, silent-switch respected, user toggle, 8–12 variants per repeated sound). Both speak the same semantic event enum; game code fires meaning, the services decide channels. Neither is ever the sole carrier of state — VoiceOver announcements accompany staged reveals.

**5.7 Reduce Motion.** Every named motion in `DESIGN.md` §2.2 has an RM variant, and `StagingDirector` selects it at one site.

The director is a long-lived service, not a `View`, so it **cannot** read `@Environment(\.accessibilityReduceMotion)` — that is a `DynamicProperty` which resolves only during a view update and silently yields `false` everywhere else, which would leave Reduce Motion permanently off with no visible failure. The director reads `UIAccessibility.isReduceMotionEnabled` and observes `UIAccessibility.reduceMotionStatusDidChangeNotification`. A test flips the flag and asserts the RM variant is chosen. Haptics and sound are never gated on Reduce Motion.

## 6. Engine acceptance specifications

The behavioral contract from the validated v1 (`docs/STATUS.md`) restated as specifications the **new** engine must re-earn with its own tests. These are gates, not aspirations: engine phases do not close until every band holds.

**6.1 Determinism**
- Same seed + same inputs ⇒ byte-identical `League` after a full season.
- Determinism holds **across processes**: a save produces the same league on a fresh launch (v1's cross-process bug came from `UUID.hashValue`).
- A source-scanning test forbids `UUID()` and `Date()` as an **argument or assignment** inside `Engine/` and `Generation/`. It permits `= UUID()` as a default parameter on `Model/` initialisers, since twelve of the thirteen existing sites are exactly that and are legitimate. The one real leak it must catch is `GameSimulator.swift:867`, which mints `PlayEvent(id: UUID(), …)` at a call site.
- The scanner must be better than v1's. That one (`DynastyTests.swift:605`) matches `line.contains(".hashValue") && !line.contains("//")`, so any offending line with a trailing comment is silently exempt — and it never looks for `UUID()` at all, which is why the leak above survives a green suite. The new scanner strips comments properly and ships a self-test proving it fails on a planted offender.
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

**6.3 Believability bands.** Provenance, stated precisely because two docs previously disagreed: these eight gates are **carried** — the values are the ones v1's `"Calibration"` suite already asserts (`GameSimulatorTests.swift`), not newly invented here. `STATUS.md` describes them in prose without numbers, which is why 02 §4's "source: STATUS.md" is imprecise; the numeric source is the test suite. Their *rationale* is the sibling community's plausibility complaints (`01-RESEARCH.md` §H), which is why they exist alongside the averages rather than inside them.

| Metric | Band |
|---|---|
| Q4 share of scoring | 22–32% |
| Explosive plays (25+ yds) per game | 3–9 |
| Touchdowns of 40+ yds per game | 0.2–1.2 |
| Safeties per game | ≤ 0.05 |
| TE target share | 15–26% |
| RB target share | 10–28% |
| Max single-receiver target share | ≤ 45% |
| Ratings predictiveness | Best vs worst team in a fresh league, home field alternated: favorite wins ≥72% over 400 games — **and the test must additionally assert the gap it ran at is ≥12 OVR**, which v1 printed in the failure message but never checked |

**6.4 Cap legality invariants**
- No team exceeds the cap outside the sanctioned dead-money overage (≤ cap/20), at any point in a ten-season run.
- Sum of contract cap hits + dead money = committed cap, exactly, in integer dollars.
- A practice-squad move can never reduce a player's cap charge below his contract's obligation (v1's laundering hole — carried forward as a permanent test).
- Every roster is exactly 53 active with position minimums satisfied after cutdown.

**6.5 The ten-season soak** (unattended, one seed, asserted at the end)
- Ten seasons complete; ten champions; no crash.
- Average OVR per year within 62–76, drift across the decade < 6.
- Average age per year within 23–30.
- Churn: no team in the top five all ten years; **≥12 distinct teams reach the top five across the decade**; ≥3 distinct champions.
- Cap legal **at the end of every season — asserted inside the loop, not after it**. v1 checked only the final year's teams, so a blow-out in year four that recovered by year ten passed green.
- Cap grows.
- Save round-trips byte-identically and stays < 5 MB.
- Bounded growth: free agents ≤ 400, chronicle and news bounded, oldest free agent < 38.
- **New (witness layer):** zero silent weeks — every week produces ≥1 card; the hook horizon never empties (≥1 hook within 3 weeks in ≥95% of weeks); no card lacks a face or a cause; template repetition stays under the perceptual-uniqueness bar (no template fires twice within 10 weeks for standout events).
- **New (Pillar P6):** the soak seed is chosen to force at least one firing. Every fired or expired-contract path yields ≥1 job offer or an explicit sit-out-year arc, **and** a chapter card fires for it — the invariant is engine *and* presentation, since a dead end the player is never told about is still a dead end.

**6.7 Staging and craft gates** (Pillar P4 and the craft-debt payment)
- Every moment in `DESIGN.md` §2.3's staging table has a spec, and each of the three hero surfaces (gameday, season hub, player card) has a stated first-render treatment. A test asserts the table and the surface list stay in sync — a headline number with no staging spec fails the build.
- Every touched surface re-audits at **≥17/20 with zero P0/P1** against the audit's rubric (baseline 9/20). This is the mechanism by which craft debt is actually paid, and no phase closes without it.

**6.6 Performance and session budgets**

Machine budgets — stated on an honest measurement basis. The audit measured a v1 week advance at ~265 ms (105 ms sim + 160 ms of double autosave) **on a Mac**, and notes an iPhone is meaningfully slower; the only existing perf test permits 20 ms/game, i.e. 320 ms/week. So:
- Sim-only week (16 games): < 150 ms on the dev Mac, asserted in CI at < 9 ms per game.
- Week advance end-to-end (sim + chronicle + narration + persist enqueue): < 350 ms on an A15, **measured on device before this number is treated as final**.
- No main-actor file I/O, ever. Persistence is an actor; the UI observes a write-state. v1's real defect here is `isBusy` — declared and never written or read — so a 250–350 ms load froze the UI with no indication. (Its `lastError` *is* surfaced, via a RootView alert; the weakness is that it is only populated on the persist/flush paths.)
- No per-render league folds: season and career stat aggregates are cached and invalidated on mutation.

Session budgets — timed by walkthrough at every phase gate, because Pillar P3 is a session pillar, not a latency budget:
- Fast session (open → advance → read → close), one-handed: ≤ 3 min.
- Full played game: ≤ 8 min. Gameplan sheet: ≤ 60 s. Management interstitial: ≤ 1 min.

## 7. Persistence

- One JSON file per save + a `.meta.json` sidecar (team, year, coach, timestamp, **active hook line** so the load list can greet you mid-story) + a rolling `.backup.json`.
- Writes go through a coalescing actor: one write per user action, never one per mutation. Atomic write, then backup rotation. Load falls back to the backup with an explicit notice.
- `SaveMigrator` reads the version from the cheap sidecar (not by re-parsing the whole file), switches on it, and every format change ships a migration plus a fixture test.
- Unknown fields decode to defaults so an older save still opens.
- Stat lines omit zero fields; finished seasons keep aggregates, not play-by-play. Chronicle keeps a bounded ring plus the season's narrative spine.

## 8. Concurrency

- `League` is `Sendable` value state; sim runs off-main via `Task.detached` for multi-week and multi-season work; results are reassigned on the main actor.
- `AppState` is `@MainActor` and owns **the single mutation funnel** — `mutate` is the only path that assigns `league`. v1 bypasses it at **eleven sites across ten methods** (`startNewFranchise`, `load`, `closeFranchise`, `delete`, `beginDraftIfNeeded`, `commit(session:)`, `reSign` ×2, `sign`, `elevate`, `demote`). Four of those exist to *return an outcome*, not out of carelessness — so the funnel needs a value-returning variant, `mutate<T>(_ change: (inout League) -> T) -> T`, or those call sites have nowhere to go. A test asserts the funnel is the sole assignment site.
- Live game streams through the stepwise simulator; the arcade's ticking values live in their own small views so a 60 Hz meter cannot invalidate the whole screen (v1 rebuilt the entire game view 62 times a second).
- Timing-critical loops derive from wall-clock deltas, not accumulated fixed steps.

## 9. Testing strategy

- **Engine:** TDD, one suite per engine, plus property checks (cap never illegal, schedule well-formed, draft order correct). The v1 harness (a hand-rolled TestKit, because XCTest is absent from the Command Line Tools) is retained *as a fallback*; prefer swift-testing when the toolchain in use provides it. Suites must self-register — v1's manual `main.swift` list is a silent-skip hazard.
- **Acceptance:** §6 as its own suite, run every phase.
- **Presentation:** the `Storyteller` is pure and therefore unit-tested — salience selection, template matching, no-faceless-card, cause-present, determinism.
- **The P2 coverage matrix enumerates *state*, not events.** Asserting "every `EventKind` has a template" is circular: it proves the events the engine already declares get narrated, while a cap hit, morale move, development tick, or job-security swing that never emits an event in the first place passes silently — which is precisely the program's largest diagnosed failure. The matrix therefore enumerates mutable, player-visible `League` state (cap, morale, development, job security, records, roster status, contract status) and CI fails when a mutation site touches such state without emitting an event. Same family as the §6.1 source scanner.
- **Design system:** the coverage law — every color pairing in the token set is contrast-tested against its real composited surface in both themes; every team primary tested against white; a test fails the build when a new pairing is introduced without a test.
- **UI:** compiled and exercised in the simulator each phase; the cold-play gate is human, not automated.

## 10. Out of scope (v1)

Multiplayer, iCloud sync, Game Center, widgets, iPad layout, monetization, Android. Nothing above blocks them.

## 11. Traceability and open decisions

Every decision above traces to `docs/research/` findings, the R2 rulings and pillars, the locked design system, or the source survey of v1 — or is marked `NOVEL` with reasoning. The presentation pipeline (§5) is the architectural expression of R2's witness-debt verdict; §6 is the validated behavioral contract restated; §8's funnel and §7's off-main persistence pay audit findings.

- **OD-4 — closed.** The `Storyteller` ships **salience-matched templates** in v1, matching what 02 §11 already rules and 02 §14 already backlogs. §6.5's repetition assertion is the revisit trigger: if template repetition breaches the perceptual-uniqueness bar during the soak, escalate to a casting engine with typed roles and re-voicing. It is no longer a blocker.
