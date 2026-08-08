# 03 — Technical Architecture

Pro Football Coach, iOS. Read `CLAUDE.md` first. Gameplay rules live in `02-GAME-DESIGN.md`; this doc is how the software is shaped.

## 1. Stack

| Decision | Choice | Why |
|---|---|---|
| UI | SwiftUI, iOS 17+ | Reference app proves the entire genre works as native SwiftUI lists/cards; no game engine needed |
| Language | Swift 5.10+ (Swift 6 mode on) | Strict concurrency catches data races in sim-vs-UI threading |
| Architecture | `@Observable` view models + unidirectional flow | Native, no dependency |
| Dependencies | **None** (no SPM third-party) | Everything needed is stdlib/Foundation/SwiftUI |
| Sim engine | Local Swift Package `FootballSimCore` | Pure logic, unit-testable without simulator, reusable if Android/web port ever happens |
| Persistence | `Codable` JSON save slots | Human-readable, versionable, enables the league import/export community feature for free |
| Backend | None. Fully offline | Matches reference app; no accounts/analytics/ads |

## 2. Targets & layout

```
ProFootballCoach.xcodeproj
├── FootballSimCore/                    # Swift Package — ZERO SwiftUI imports
│   ├── Sources/FootballSimCore/
│   │   ├── Model/          Player.swift, Team.swift, Contract.swift, League.swift,
│   │   │                   DraftProspect.swift, GameRecord.swift, Standings.swift,
│   │   │                   CoachProfile.swift, NewsItem.swift
│   │   ├── Rules/          LeagueRules.swift        # ALL tunable constants
│   │   ├── Engine/         GameSimulator.swift      # one game, play-by-play
│   │   │                   SeasonEngine.swift       # weekly loop, standings, playoffs
│   │   │                   OffseasonEngine.swift    # retirements→FA→draft→camp pipeline
│   │   │                   ProgressionEngine.swift  # age curves, development, regression
│   │   │                   CapEngine.swift          # salary cap math, dead money
│   │   │                   TradeEngine.swift        # valuation + AI accept/reject
│   │   │                   FreeAgencyEngine.swift   # market, AI bidding
│   │   │                   DraftEngine.swift        # order, AI picks, scouting fog
│   │   │                   ScheduleGenerator.swift  # NFL-style 17-game formula
│   │   ├── Generation/     NameBank.swift, PlayerFactory.swift, LeagueFactory.swift,
│   │   │                   DraftClassFactory.swift
│   │   └── Support/        SeededRandom.swift, SaveGame.swift, SaveMigrator.swift
│   └── Tests/FootballSimCoreTests/     # mirrors Engine/ one test file per engine
└── App/                                # iOS target
    ├── ProFootballCoachApp.swift
    ├── AppState.swift                  # root @Observable: current save, navigation
    ├── Theme/                          # team-color theming, design tokens
    ├── Features/                       # one folder per screen family
    │   ├── MainMenu/  NewGameWizard/  SeasonHub/  GameCenter/  Roster/
    │   ├── DepthChart/  Standings/  Stats/  Schedule/  Team/  Coach/
    │   ├── FrontOffice/   (cap, contracts, resign)
    │   ├── FreeAgency/  Draft/  Trades/  Scouting/
    │   └── Settings/  Scenarios/  News/  Awards/  HallOfFame/
    └── Persistence/    SaveStore.swift  # slot listing, load/save/delete, autosave
```

Rule: `Features/X/` contains `XView.swift` + `XViewModel.swift` + small subviews. View models call engine functions; views never touch engines directly.

## 3. Core model (summary — field-level detail sits with each phase plan)

```swift
struct League: Codable {            // the whole save state
    var version: Int                // saveFormatVersion
    var rng: SeededRandom           // persisted so determinism survives save/load
    var year: Int                   // e.g. 2026
    var phase: SeasonPhase          // .preseason, .regularSeason(week:), .playoffs(round:), .offseason(stage:)
    var teams: [Team]               // 32
    var schedule: [ScheduledGame]
    var results: [GameRecord]
    var freeAgents: [Player]
    var draftClass: [DraftProspect] // added in P7
    var news: [NewsItem]
    var userTeamID: Team.ID
    var coach: CoachProfile         // XP, level, skill tree
    var settings: LeagueSettings
    var history: [SeasonSummary]    // per past season: standings, awards, per-player StatLines
}

struct Team: Codable, Identifiable { id, city, name, abbrev, colors, conference, division,
    roster: [Player], depthChart: [Position: [Player.ID]],
    capSpent/capSpace (computed via CapEngine), reputation, ownerPatience, aiPersonality }

struct Player: Codable, Identifiable { id, firstName, lastName, position, age, yearsPro, jersey,
    heightInches, weightPounds, college, draftOrigin,
    ratings: Ratings,               // per-position relevant subratings; OVR computed
    potential: PotentialGrade, traits: [Trait], morale: Int,
    injuryWeeksRemaining: Int,      // 0 = healthy; injury flavor text lives in the news item
    contract: Contract? }           // nil = free agent
// Stats live OUTSIDE Player: current season aggregates from results[].playerStats;
// past seasons from history[].playerStats — career = fold over both. Keeps Player lean.

struct Contract: Codable { years, salaryPerYear: [Int], signingBonus, guaranteed, isRookieDeal }
```

Money = `Int` dollars. Ratings = `Int` 40–99. IDs = `UUID`.

## 4. Sim engine principles

- **Deterministic:** every engine entry point takes `inout SeededRandom` (SplitMix64). Same seed + same inputs ⇒ identical season. Makes bugs reproducible and tests exact.
- **Pure:** engines are `struct`s with static funcs `(League, inout SeededRandom) -> League` style (value semantics in, value out). No singletons, no Date().
- **Play-by-play, not box-score-only:** `GameSimulator` runs drives → plays (run/pass/PA selection from scheme + situation → yardage from matchup ratings + variance → downs, clock, scoring, turnovers, penalties, injuries). Emits `[PlayEvent]` so the UI can show live play-by-play, and aggregates to `GameRecord` + player `StatLine`s. Calibration targets (league-average points, yards, completion %, sack rate per season) are asserted in `CalibrationTests` against NFL-realistic bands.
- **Speed budget:** simulating a full week (16 games) < 150 ms on an A15; a full season < 5 s. Non-user games may use the same engine at reduced event retention (aggregate stats, discard play list).

## 5. Persistence

- `SaveStore` writes each dynasty as one JSON file in `Application Support/Saves/<uuid>.json` + a small `<uuid>.meta.json` (team, year, coach name, timestamp) for the Load Game list without decoding full saves.
- Atomic writes (`.atomic`), autosave after every advanced week and after every offseason step, **plus a rolling `.bak` of the previous good save — corruption of the reference app's saves (~season 8) is its #1 complaint; load falls back to `.bak` with a toast rather than dying. Checkpoints are free** (reference app sells them as crash insurance — we out-position by being reliable).
- `SaveMigrator` switches on `version` and upgrades old JSON dictionaries before decode. Every format change bumps `version` and adds a migration + test fixture.
- League sharing (later phase): export/import `LeagueTemplate` JSON (teams, colors, conferences — no rosters) mirroring the reference app's community-league pipeline.

## 6. Concurrency

- Engines run off-main via `Task.detached` when simulating multiple weeks/seasons; UI shows progress. Single-game "watch" mode streams `PlayEvent`s over an `AsyncStream` with adjustable playback speed.
- `League` is a value type — sim works on a copy, result reassigned on main actor. No locks. `FootballSimCore` compiles with strict concurrency; everything `Sendable`.

## 7. Theming

- `TeamTheme` derives primary/secondary `Color` + gradient from the user team; injected via Environment. Pre-dynasty screens use neutral accent, in-dynasty screens re-theme to team colors (pattern proven by reference app).
- All spacing/typography tokens in `Theme/DesignSystem.swift`; SF rounded display weight for headers, standard iOS list/card idioms. Dark mode supported from day one.

## 8. Testing strategy

- **Engine:** XCTest in the package. Every mechanic: unit tests + property-style checks (e.g. cap never negative after AI free agency; schedule generator: every team exactly 17 games, no team twice in a week; draft: 7 rounds × 32 picks, order = reverse standings with playoff adjustments).
- **Calibration:** simulate 20 seeded seasons, assert league-wide averages within realistic bands (points/game 20–26, ~1 QB > 4,800 yds rare, etc.). Catches balance regressions numerically.
- **Persistence:** round-trip encode/decode equality; migration fixtures per version.
- **UI:** compile + key flows exercised in simulator each phase (manual/screenshot); no UI test suite initially. `ponytail:` UI snapshot tests only if churn starts breaking screens.

## 9. Performance & memory

- History retention capped: full play-by-play kept only for user games of current season; older games keep `GameRecord` aggregates. `ponytail:` if saves exceed ~5 MB, move history to a sidecar file — don't build that until it happens.
- Lists use `LazyVStack`; stat leaderboards computed on demand from `StatLine`s, not stored.

## 10. Out of scope (v1)

Multiplayer, iCloud sync, Game Center, widgets, iPad-optimized layout (runs scaled), monetization, Android. Each is additive later; nothing above blocks them.
