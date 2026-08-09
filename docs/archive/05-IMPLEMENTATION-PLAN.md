# Pro Football Coach — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> Phases P0–P1 below are fully expanded — execute directly. Phases P2–P8 are scoped specs: before starting each, run **superpowers:writing-plans** against that phase's spec (+ the docs it cites) to produce `docs/plans/YYYY-MM-DD-phase-N.md`, then execute that.

**Goal:** Native SwiftUI iOS pro-football franchise sim per `02-GAME-DESIGN.md`.

**Architecture:** Pure-Swift deterministic engine in local package `FootballSimCore` (TDD, seeded RNG); SwiftUI app layer with `@Observable` view models; Codable JSON save slots. See `03-ARCHITECTURE.md`.

**Tech Stack:** Swift 5.10+/SwiftUI, iOS 17+, XCTest, zero third-party dependencies.

## Global Constraints

- iOS deployment target **17.0**; Swift strict concurrency on; **no third-party dependencies**
- Engine code: **no `import SwiftUI`/`UIKit`**, no `Date()`/`Double.random` — all randomness via injected `SeededRandom`
- Money `Int` dollars; ratings `Int` 40–99; IDs `UUID`
- All tunables in `LeagueRules.swift` — no inline magic numbers
- Fictional names only (team table in `02-GAME-DESIGN.md` §2); no NFL/NCAA marks; no code from the CC-NC Java repo
- Commits: Conventional Commits, one task = one commit
- A phase closes only when: all tests green + adversarial review run + findings fixed + feature demoed in simulator

## Phase gates

| Phase | Gate (all must hold) |
|---|---|
| P0 | `swift test` runs (0 tests ok); app target builds & launches in simulator; docs committed |
| P1 | Determinism, roster-shape, save round-trip tests green; app lists 32 generated teams |
| P2 | 1,000-game calibration suite inside bands (`02` §4); single game < 20 ms |
| P3 | 10 simmed seasons: schedule/standings/playoff invariants green; week advance < 150 ms |
| P4 | Full game playable by hand; quick-sim tiers work; box score matches engine totals |
| P4B | On-the-Field game playable one-thumb at 60 fps; stat-mapping tests green; box score == event log; mode parity (XP/injuries/news) |
| P5 | Depth chart edits persist + affect sim; stats suite matches box-score aggregates |
| P6 | Cap property tests green (no negative space, dead-money identity); AI FA/trades keep 31 teams legal across 5 seasons |
| P7 | 10-season soak: drafts/offseasons complete, league OVR distribution stable (no inflation/collapse) |
| P8 | Definition of done in `00-EXECUTIVE-PLAN.md` |

---

# Phase 0 — Foundation

### Task 0.1: Repo + docs

**Files:** Create: `README.md`, `.gitignore`, `CLAUDE.md` (from plan folder), `docs/*` (docs 00–05)

- [ ] **Step 1:** Clone the empty repo; copy `CLAUDE.md` to root and the six plan docs into `docs/`.
- [ ] **Step 2:** Write `README.md`:

```markdown
# Pro Football Coach
Native iOS pro-football franchise simulator. SwiftUI, offline, no dependencies.
- Docs: `docs/00-EXECUTIVE-PLAN.md` (start here) · design canon: `docs/02-GAME-DESIGN.md`
- Engine: `FootballSimCore/` Swift package — `cd FootballSimCore && swift test`
- App: `ProFootballCoach.xcodeproj`
```

- [ ] **Step 3:** `.gitignore`: Xcode standard (`xcuserdata/`, `DerivedData/`, `.DS_Store`, `*.xcuserstate`, `.build/`).
- [ ] **Step 4:** Commit: `chore: repo scaffold + planning docs`

### Task 0.2: FootballSimCore package

**Files:** Create: `FootballSimCore/Package.swift`, empty source/test dirs

- [ ] **Step 1:** `cd` repo root; `mkdir FootballSimCore && cd FootballSimCore && swift package init --type library --name FootballSimCore`
- [ ] **Step 2:** Replace `Package.swift`:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FootballSimCore",
    platforms: [.iOS(.v17), .macOS(.v14)],   // macOS enables fast CLI `swift test`
    products: [.library(name: "FootballSimCore", targets: ["FootballSimCore"])],
    targets: [
        .target(name: "FootballSimCore",
                swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]),
        .testTarget(name: "FootballSimCoreTests", dependencies: ["FootballSimCore"]),
    ]
)
```

- [ ] **Step 3:** Run `swift test` — expect: builds, example test passes (delete the placeholder test after).
- [ ] **Step 4:** Commit: `chore: FootballSimCore package scaffold`

### Task 0.3: App target

**Files:** Create: `project.yml`, `App/ProFootballCoachApp.swift`, `App/Assets.xcassets` (accent + icon placeholder)

- [ ] **Step 1:** Write `project.yml` (XcodeGen; `brew install xcodegen` if missing — if Homebrew unavailable, create the equivalent project manually in Xcode: iOS App template, SwiftUI, min iOS 17, add local package):

```yaml
name: ProFootballCoach
options: { bundleIdPrefix: com.ericmg, deploymentTarget: { iOS: "17.0" } }
packages: { FootballSimCore: { path: FootballSimCore } }
targets:
  ProFootballCoach:
    type: application
    platform: iOS
    sources: [App]
    dependencies: [{ package: FootballSimCore }]
    settings: { INFOPLIST_KEY_UILaunchScreen_Generation: YES, SWIFT_STRICT_CONCURRENCY: complete }
```

- [ ] **Step 2:** `App/ProFootballCoachApp.swift`:

```swift
import SwiftUI
import FootballSimCore

@main
struct ProFootballCoachApp: App {
    var body: some Scene { WindowGroup { Text("Pro Football Coach").font(.largeTitle.bold()) } }
}
```

- [ ] **Step 3:** `xcodegen generate`; build & launch in iPhone simulator (`xcodebuild -scheme ProFootballCoach -destination 'platform=iOS Simulator,name=iPhone 16' build` or the iOS-Simulator MCP build tool). Expected: app shows title text.
- [ ] **Step 4:** Commit: `chore: iOS app target via XcodeGen`

---

# Phase 1 — Domain core

### Task 1.1: SeededRandom

**Files:** Create: `FootballSimCore/Sources/FootballSimCore/Support/SeededRandom.swift`, Test: `.../Tests/FootballSimCoreTests/SeededRandomTests.swift`

**Interfaces — Produces:** `struct SeededRandom: Codable, Sendable` with `init(seed: UInt64)`, `mutating func next() -> UInt64`, `mutating func int(in: ClosedRange<Int>) -> Int`, `mutating func double01() -> Double`, `mutating func gaussian(mean: Double, sd: Double) -> Double`, `mutating func chance(_ p: Double) -> Bool`, `mutating func pick<T>(_ a: [T]) -> T`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import FootballSimCore

final class SeededRandomTests: XCTestCase {
    func testDeterminism() {
        var a = SeededRandom(seed: 42), b = SeededRandom(seed: 42)
        XCTAssertEqual((0..<100).map { _ in a.next() }, (0..<100).map { _ in b.next() })
    }
    func testIntBounds() {
        var r = SeededRandom(seed: 1)
        for _ in 0..<1000 { XCTAssertTrue((40...99).contains(r.int(in: 40...99))) }
    }
    func testGaussianMoments() {
        var r = SeededRandom(seed: 7)
        let xs = (0..<20_000).map { _ in r.gaussian(mean: 70, sd: 8) }
        let mean = xs.reduce(0, +) / Double(xs.count)
        XCTAssertEqual(mean, 70, accuracy: 0.5)
    }
    func testCodableRoundTripContinues() throws {
        var a = SeededRandom(seed: 9); _ = a.next()
        let b = try JSONDecoder().decode(SeededRandom.self, from: JSONEncoder().encode(a))
        var a2 = a, b2 = b
        XCTAssertEqual(a2.next(), b2.next())
    }
}
```

- [ ] **Step 2:** Run `swift test` — expect FAIL (type undefined).
- [ ] **Step 3: Implement** (SplitMix64 core; Box–Muller for gaussian):

```swift
public struct SeededRandom: Codable, Sendable, Equatable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    public mutating func double01() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
    public mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }
    public mutating func chance(_ p: Double) -> Bool { double01() < p }
    public mutating func pick<T>(_ a: [T]) -> T { a[int(in: 0...(a.count - 1))] }
    public mutating func gaussian(mean: Double, sd: Double) -> Double {
        let u1 = max(double01(), .leastNonzeroMagnitude), u2 = double01()
        return mean + sd * (-2 * Foundation.log(u1)).squareRoot() * Foundation.cos(2 * .pi * u2)
    }
}
// (file has `import Foundation` at the top)
```

- [ ] **Step 4:** `swift test` — expect PASS. Commit: `feat(core): seeded deterministic RNG`

### Task 1.2: Positions, attributes, LeagueRules skeleton

**Files:** Create: `.../Model/Position.swift`, `.../Rules/LeagueRules.swift`, Test: `LeagueRulesTests.swift`

**Interfaces — Produces:** `enum Position: String, Codable, CaseIterable, Sendable, CodingKeyRepresentable` (`qb rb wr te ol dl lb cb s k p`) with `var attributes: [Attribute]`, `var rosterTarget: Int`, `var starterCount: Int`; `enum Attribute: String, Codable, CaseIterable, Sendable, CodingKeyRepresentable` (speed strength agility awareness throwPower throwAccuracy catchRating routeRunning breakTackle vision runBlock passBlock tackle blockShed passRush coverage kickPower kickAccuracy puntPower puntAccuracy); `enum LeagueRules` with static constants + `static func ovrWeights(for: Position) -> [Attribute: Double]`

> **Why `CodingKeyRepresentable`:** without it, `[Attribute: Int]` / `[Position: [UUID]]` encode as flat *arrays* in nondeterministic dictionary-iteration order — save files churn and byte-equality tests flake. With it they encode as JSON objects, and `.sortedKeys` makes encoding deterministic. All dictionary-keyed enums in the model get this conformance.

- [ ] **Step 1: Failing test**

```swift
final class LeagueRulesTests: XCTestCase {
    func testWeightsSumToOne() {
        for pos in Position.allCases {
            let s = LeagueRules.ovrWeights(for: pos).values.reduce(0, +)
            XCTAssertEqual(s, 1.0, accuracy: 0.001, "\(pos)")
        }
    }
    func testWeightsCoverOnlyPositionAttributes() {
        for pos in Position.allCases {
            XCTAssertTrue(Set(LeagueRules.ovrWeights(for: pos).keys).isSubset(of: Set(pos.attributes)))
        }
    }
    func testRosterTargetsSumTo53() {
        XCTAssertEqual(Position.allCases.map(\.rosterTarget).reduce(0, +), LeagueRules.activeRosterSize)
    }
}
```

- [ ] **Step 2:** Run — FAIL. **Step 3: Implement.** Core attrs (speed/strength/agility/awareness) on all positions except K/P (awareness + kick/punt only); position sets and targets exactly per `02` §3 (QB3 RB4 WR6 TE3 OL9 DL8 LB7 CB6 S5 K1 P1 = 53); constants: `salaryCapYear1 = 260_000_000`, `activeRosterSize = 53`, `practiceSquadSize = 16`, `regularSeasonGames = 17`, `seasonWeeks = 18`, `playoffTeamsPerConference = 7`, `minSalaryYoung = 900_000`, `minSalaryVet = 1_200_000`, `practiceSquadSalary = 250_000`, `ratingFloor = 40`, `ratingCeil = 99`. Example weights (define all 11): QB `[.throwAccuracy: 0.30, .throwPower: 0.20, .awareness: 0.25, .agility: 0.10, .speed: 0.10, .strength: 0.05]`; K `[.kickAccuracy: 0.5, .kickPower: 0.35, .awareness: 0.15]`; others analogous, biased to the position's craft attributes.
- [ ] **Step 4:** PASS. Commit: `feat(core): positions, attributes, league rules`

### Task 1.3: Player, Contract, Ratings

**Files:** Create: `.../Model/Player.swift`, `.../Model/Contract.swift`, Test: `PlayerTests.swift`

**Interfaces — Produces:**
`struct Ratings: Codable, Sendable { var values: [Attribute: Int]; func ovr(for: Position) -> Int }`
`struct Contract: Codable, Sendable { var years: Int; var salaryPerYear: [Int]; var signingBonus: Int; var guaranteedYears: Int; var yearsElapsed: Int; var isRookieDeal: Bool; var bonusProrationPerYear: Int { get }; func capHit(inYear: Int) -> Int; func deadMoneyIfCutNow() -> Int }`
`struct Player: Codable, Identifiable, Sendable { id: UUID; firstName, lastName: String; position: Position; age: Int; yearsPro: Int; jersey: Int; heightInches, weightPounds: Int; college: String; draftOrigin: String?; ratings: Ratings; potential: PotentialGrade; traits: [Trait]; morale: Int; injuryWeeksRemaining: Int; contract: Contract?; var name: String { get }; var ovr: Int { get } }`
`enum PotentialGrade: String, Codable, CaseIterable, Sendable` (aPlus…f) with `var devMultiplier: Double`; `enum Trait: String, Codable, CaseIterable, Sendable` (clutch, injuryProne, ironMan, leader, mercenary, loyal, lateBloomer, boomBust)

- [ ] **Step 1: Failing test**

```swift
final class PlayerTests: XCTestCase {
    func testOVRIsWeightedMeanRounded() {
        var v = [Attribute: Int](); Position.qb.attributes.forEach { v[$0] = 80 }
        XCTAssertEqual(Ratings(values: v).ovr(for: .qb), 80)   // uniform 80 → 80 at any weights
    }
    func testCapHitAndDeadMoney() {
        // 4yr, $8M/yr flat, $8M bonus (→ $2M/yr proration), 2 guaranteed yrs
        let c = Contract(years: 4, salaryPerYear: [8_000_000, 8_000_000, 8_000_000, 8_000_000],
                         signingBonus: 8_000_000, guaranteedYears: 2, yearsElapsed: 1, isRookieDeal: false)
        XCTAssertEqual(c.capHit(inYear: 1), 10_000_000)               // salary + proration
        // cut after year 1: remaining proration 3×2M + remaining guaranteed salary 1×8M
        XCTAssertEqual(c.deadMoneyIfCutNow(), 14_000_000)
    }
}
```

- [ ] **Step 2:** FAIL. **Step 3:** Implement. `ovr(for:)` = `Int((Σ weight·value).rounded())` clamped 40…99, missing attr → treat as `LeagueRules.ratingFloor`. `capHit(inYear: y)` (0-based) = `salaryPerYear[y] + bonusProrationPerYear`; proration = `signingBonus / years` (integer division; put remainder into year 0). `deadMoneyIfCutNow()` = remaining years' proration + salaries of remaining guaranteed years (from `yearsElapsed`). `devMultiplier`: aPlus 1.6, a 1.45, bPlus 1.3, b 1.15, cPlus 1.0, c 0.9, d 0.75, f 0.6.
- [ ] **Step 4:** PASS. Commit: `feat(core): player, ratings, contract math`

### Task 1.4: Team, League, SeasonPhase

**Files:** Create: `.../Model/Team.swift`, `.../Model/League.swift`, Test: `LeagueModelTests.swift`

**Interfaces — Produces:**
`enum Conference: String, Codable, CaseIterable, Sendable { liberty, frontier }`; `enum Division: String, Codable, CaseIterable, Sendable { east, north, south, west }`
`struct TeamColors: Codable, Sendable { var primaryHex: String; var secondaryHex: String }`
`struct Team: Codable, Identifiable, Sendable { id: UUID; city, name, abbrev: String; colors: TeamColors; conference: Conference; division: Division; roster: [Player]; depthChart: [Position: [UUID]]; reputation: Int; aiPersonality: AIPersonality; ownerPatience: Int; var ovr: Double { get } }` (`ovr` = mean of top starters per position weighted by `starterCount`)
`enum AIPersonality: String, Codable, CaseIterable, Sendable { winNow, balanced, rebuilder, capHawk }`
`enum CoachBackground: String, Codable, CaseIterable, Sendable { formerPlayer, talentEvaluator, playcaller, defensiveMind }` (used by `CoachProfile`; give `CoachProfile` a `static let stub` for tests)
`enum SeasonPhase: Codable, Sendable, Equatable { case preseason; case regularSeason(week: Int); case playoffs(round: Int); case offseason(stage: Int) }`
`struct League: Codable, Sendable { var version: Int; var rng: SeededRandom; var year: Int; var phase: SeasonPhase; var teams: [Team]; var schedule: [ScheduledGame]; var results: [GameRecord]; var freeAgents: [Player]; var news: [NewsItem]; var userTeamID: UUID; var coach: CoachProfile; var settings: LeagueSettings; var history: [SeasonSummary] }` — for P1, `ScheduledGame`, `GameRecord`, `NewsItem`, `CoachProfile`, `LeagueSettings`, `SeasonSummary` are minimal Codable stubs with the fields P1 needs (`CoachProfile`: firstName, lastName, age, background; `LeagueSettings`: playoffFormat=14, injuriesOn=true, capOn=true; others empty structs to be filled in their phases).

- [ ] Steps: failing test (team OVR of uniform-80 roster == 80; `League` encodes/decodes to equal value), implement, pass, commit `feat(core): team + league aggregate`.

### Task 1.5: NameBank + PlayerFactory

**Files:** Create: `.../Generation/NameBank.swift`, `.../Generation/PlayerFactory.swift`, Test: `PlayerFactoryTests.swift`

**Interfaces — Produces:** `enum NameBank { static func first(_: inout SeededRandom) -> String; static func last(_: inout SeededRandom) -> String; static func college(_: inout SeededRandom) -> String }` (≥120 first, ≥160 last names, ≥40 fictional colleges — reuse college-app naming flavor: "Palmetto State", "Port City", "Provo" etc.); `enum PlayerFactory { static func make(position: Position, age: Int, targetOVR: Int, rng: inout SeededRandom) -> Player }`

- [ ] **Step 1: Failing test**

```swift
final class PlayerFactoryTests: XCTestCase {
    func testTargetOVRWithinBand() {
        var rng = SeededRandom(seed: 3)
        for _ in 0..<200 {
            let p = PlayerFactory.make(position: .wr, age: 25, targetOVR: 78, rng: &rng)
            XCTAssertTrue((64...92).contains(p.ovr), "\(p.ovr)")   // ±14: ~5σ of the weighted-mean spread, no flake
            XCTAssertTrue(p.ratings.values.values.allSatisfy { (40...99).contains($0) })
        }
    }
    func testDeterministic() {
        var a = SeededRandom(seed: 5), b = SeededRandom(seed: 5)
        let x = PlayerFactory.make(position: .qb, age: 24, targetOVR: 75, rng: &a)
        let y = PlayerFactory.make(position: .qb, age: 24, targetOVR: 75, rng: &b)
        XCTAssertEqual(x.ratings.values, y.ratings.values); XCTAssertEqual(x.name, y.name)
    }
}
```

- [ ] Implement: each attribute = `clamp(gaussian(mean: targetOVR ± positionSkew, sd: 6))`; craft attributes skew +4, off-craft −4; height/weight gaussian per position table; potential letter drawn from distribution conditioned on age (younger → wider); traits: 25% chance one, 5% two; jersey by position range. Pass, commit `feat(core): name bank + player generation`.

### Task 1.6: LeagueFactory (default 32-team league)

**Files:** Create: `.../Generation/LeagueFactory.swift`, `.../Rules/TeamTable.swift`, Test: `LeagueFactoryTests.swift`

**Interfaces — Produces:** `enum TeamTable { static let entries: [(city: String, name: String, abbrev: String, primaryHex: String, secondaryHex: String, conference: Conference, division: Division)] }` — exactly the 32 from `02` §2; `enum LeagueFactory { static func makeDefaultLeague(seed: UInt64, userTeamIndex: Int, coach: CoachProfile) -> League }`

- [ ] **Step 1: Failing test**

```swift
final class LeagueFactoryTests: XCTestCase {
    func testLeagueShape() {
        let l = LeagueFactory.makeDefaultLeague(seed: 11, userTeamIndex: 0, coach: .init(firstName: "Eric", lastName: "Sea", age: 35, background: .playcaller))
        XCTAssertEqual(l.teams.count, 32)
        for conf in Conference.allCases {
            XCTAssertEqual(l.teams.filter { $0.conference == conf }.count, 16)
            for div in Division.allCases {
                XCTAssertEqual(l.teams.filter { $0.conference == conf && $0.division == div }.count, 4)
            }
        }
        for t in l.teams {
            XCTAssertEqual(t.roster.count, LeagueRules.activeRosterSize + LeagueRules.practiceSquadSize)
            for pos in Position.allCases {
                XCTAssertGreaterThanOrEqual(t.roster.filter { $0.position == pos }.count, pos.rosterTarget)
            }
            XCTAssertTrue((55...92).contains(Int(t.ovr)))
            XCTAssertTrue(t.roster.allSatisfy { $0.contract != nil })
        }
        XCTAssertEqual(Set(l.teams.flatMap(\.roster).map(\.id)).count, 32 * 69)   // unique players
    }
    func testDeterministicLeague() {
        let a = LeagueFactory.makeDefaultLeague(seed: 2, userTeamIndex: 3, coach: .stub)
        let b = LeagueFactory.makeDefaultLeague(seed: 2, userTeamIndex: 3, coach: .stub)
        let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys]   // required for byte-equality
        XCTAssertEqual(try! enc.encode(a), try! enc.encode(b))
    }
}
```

- [ ] Implement: team quality tiers (4 contenders 82–88 team target, 12 solid 74–81, 12 mediocre 66–73, 4 rebuilding 58–65 — shuffled by rng); per-slot player target OVR = tier target ± depth falloff (starters near target, backups −8…−14, PS −18); ages: veteran-skewed for winNow teams, young for rebuilders; initial contracts: market-value formula stub `ContractPricer.marketSalary(ovr:age:position:)` (position premiums from `02` §6) with 1–4 year terms so expiries stagger; depth chart sorted by OVR; reputation from tier; deterministic team-table order. Ensure league-wide cap legality: scale contracts so each team's year-0 payroll ∈ 85–98% of cap. Pass, commit `feat(core): default league generation`.

### Task 1.7: SaveStore + app shell proof

**Files:** Create: `App/Persistence/SaveStore.swift`, `App/AppState.swift`, `App/RootView.swift`; Modify: `App/ProFootballCoachApp.swift`; Test: `FootballSimCoreTests/SaveCodableTests.swift` (round-trip lives in core; file IO is app-side, exercised manually)

**Interfaces — Produces:** `@Observable final class AppState { var league: League?; func newGame(seed: UInt64, teamIndex: Int, coach: CoachProfile); func save(); func loadMostRecent() }`; `struct SaveStore { func list() -> [SaveMeta]; func save(_ league: League, name: String) throws; func load(id: UUID) throws -> League; func delete(id: UUID) }` with `SaveMeta: Codable { id, name, teamAbbrev, year, week, updatedAt }` in `Application Support/Saves/`, atomic writes.

- [ ] **Step 1:** Core test: encode league (from Task 1.6) with `.sortedKeys`, decode, re-encode with `.sortedKeys` → byte-equal. `SaveStore` uses `.sortedKeys` too (stable diffs, stable files). FAIL→implement→PASS.
- [ ] **Step 2:** `RootView`: if no league → "New Game" button (calls `newGame(seed: UInt64.random(in: .min ... .max), teamIndex: 0, ...)` — UI layer may use system randomness for *seed choice only*); else `List(league.teams)` rows: abbrev chip, city+name, division label, `ovr` formatted `%.1f`, colored circle from `primaryHex`.
- [ ] **Step 3:** Build, run in simulator: tap New Game → 32 teams listed with plausible OVR spread; relaunch → league persists via autosave in `newGame`. Screenshot for the phase record.
- [ ] **Step 4:** Commit: `feat(app): save store + generated-league proof screen`
- [ ] **Step 5 (phase close):** Run adversarial review on P1 diff; fix; re-run tests; commit fixes.

---

# Phase 2 — Game engine (spec; expand with writing-plans before starting)

**Files:** `Engine/GameSimulator.swift`, `Engine/PlayResolver.swift`, `Model/GameRecord.swift` (real fields now: quarter scores, team stat lines, per-player `StatLine`, `[PlayEvent]`), `Model/StatLine.swift`, `Rules/PlayMatrix.swift`; tests `GameSimulatorTests`, `CalibrationTests`.

**Interfaces — Produces:** `GameSimulator.simulate(home: Team, away: Team, rules: LeagueSettings, rng: inout SeededRandom, retainPlays: Bool) -> GameRecord`; `PlayEvent { drive, quarter, clock, description, teamID, involved: [UUID], type }`; `enum OffensiveCall/DefensiveCall` per `02` §4; `StatLine` (all box-score fields, position-relevant).
**Key algorithms:** unit ratings from starters via depth chart; play matrix table (`OffensiveCall × DefensiveCall → (meanYards, sd, sackP, intP, fumbleP, bigPlayTail)`); clock model; AI playcaller (situation → call distribution); 4th-down EV chart; FG curve; injuries per `02` §3; win-prob logistic; OT rules.
**Gate tests:** determinism (same seed → identical `GameRecord`); stat-conservation (team pass yards == Σ receiver yards == Σ QB pass yards); calibration over 1,000 games between random league teams: all bands `02` §4 **including believability bands and mode parity (retainPlays true/false byte-identical outcomes for same seed)**; **end-of-game state-machine suite: expiring-TD awards the try, kneel-out math, untimed downs, OT caps, clock never sticks at 0:00 with play continuing**; performance `measure` < 20 ms/game (retainPlays false).

# Phase 3 — Season loop (spec)

**Files:** `Engine/ScheduleGenerator.swift`, `Engine/SeasonEngine.swift`, `Engine/StandingsCalculator.swift`, `Engine/PowerRankings.swift`, `Engine/NewsEngine.swift` (recaps/injuries only for now); app `Features/SeasonHub`, `Features/Schedule`, `Features/Standings` with view models.
**Interfaces:** `ScheduleGenerator.makeSchedule(teams:, year:, rng:) -> [ScheduledGame]` (formula `02` §2 incl. byes weeks 5–14, 17th-game rotation); `SeasonEngine.advanceWeek(league: inout League)` — sims all unplayed games this week, updates records/stats/news/injury recovery, advances phase (into playoffs → offseason handoff stub); `StandingsCalculator.standings(conference:) -> [TeamStanding]` with tiebreakers `02` §2; `PowerRankings.compute(league:) -> [RankedTeam]` (rating = weighted recent results + point diff + team OVR).
**Gate:** invariants over 10 seeded seasons — every team plays 17 (9H/8A or 8H/9A, alternating 17th), 6 division games, one bye 5–14; playoff bracket = 7 seeds reseeded per `02`; champion crowned; week advance < 150 ms; Season/Schedule/Standings screens per `04` §3/7/13 demoed.

# Phase 4 — Live game UI (spec)

**Files:** `Features/GameCenter/` (LiveGameView, FieldView, PlaybookView, PlayLogView, WinProbBar, CoinTossDialog, QuickSimSheet, BoxScoreSheet, GameReportSheet) + `LiveGameViewModel` bridging `AsyncStream<PlayEvent>`.
**Spec:** `04` §5–6 exactly; engine already emits everything (P2). User calls both sides when possessing/defending; Suggested banner = AI call; Simulate button = AI-vs-AI for one play; quick-sim runs engine to target then re-streams. XP toast stub (records XP into `CoachProfile` for P8).
**Gate:** hand-play a full game; totals equal engine `GameRecord`; all quick-sim targets land exactly; 60 fps scroll on iPhone SE-class simulator.

# Phase 4B — On the Field arcade mode (spec)

**Files:** `Features/OnTheField/` (FieldScene.swift SpriteKit `SKScene`, OnTheFieldView (SpriteView host + HUD), AimController, CarrierController, KickMeterView, DefenseResolutionView, SpriteFactory, FatigueModel), `Engine/GameSimulator+Interactive.swift` (public state machine: expose `GameSituation`, accept externally-resolved `PlayEvent` for one play, resume sim).
**Spec:** `06-PLAYED-GAME-MODE.md` in full — control model §3, ratings mapping table §4 (implement as pure functions with unit tests: arc length, scatter radius, pocket timer, sweep speed), coordinator hooks §6, presentation rules §7 (landscape only in-game, original sprite style, team colors), cut lines §8.
**Key architecture rule:** arcade layer resolves ONLY the user-controlled play's outcome and returns a `PlayEvent` + `StatLine` delta to the engine's state machine; clock, downs, penalties, scoring, OT, and all defensive/AI possessions stay in `FootballSimCore`. No rule logic duplicated in the app target.
**Gate:** phase-gate table row P4B; targeted tests: QB accuracy 99 → scatter < 1 yd & full arc; accuracy 60 → ≤ 2/3 arc; OL unit 55 → pocket ≤ 2.5 s, 90 → ≥ 4.2 s; kick accuracy sweep-speed monotonic; fatigue reduces carrier top speed ≥ 8% after 15 touches; box score equals accumulated events; 60 fps on A15-class simulator; portrait↔landscape transition clean; XP/injury/news identical to Call-the-Plays for same results.

# Phase 5 — Team & stats UI (spec)

**Files:** `Features/Roster/DepthChartView(+VM)`, `Features/Roster/PlayerCardView`, `Features/Team/TeamOverviewView`, `Features/Stats/StatsSuiteView(+VM)`, `Features/Awards/` weekly stub.
**Spec:** `04` §8–10, §14. Depth chart edits write `team.depthChart` (persisted; P2 engine already reads it — verify effect: benching starter QB drops unit rating). Player card shows contract card (read-only until P6). Stats suite aggregates from `results[].playerStats`; 9 categories, sort/filter/scope per `04`.
**Gate:** stat suite totals == Σ box scores (property test on view-model aggregation); depth-chart persistence + sim effect demonstrated.

# Phase 6 — Front office (spec)

**Files:** `Engine/CapEngine.swift`, `Engine/ContractPricer.swift` (promote P1 stub), `Engine/FreeAgencyEngine.swift`, `Engine/TradeEngine.swift`, `Engine/RosterMoves.swift` (cut/sign/elevate); app `Features/FrontOffice/` (CapView, ResignView + NegotiationSheet, FreeAgencyView, TradeCenterView).
**Spec:** `02` §6–7, §9; UI `04` §11. AI teams run FA/re-sign/cuts/trades with personality; user negotiation sheets with accept-probability meter; trade value chart + counteroffers; deadline enforcement.
**Gate (property tests):** cap space never negative for any team after any AI stage; dead money identity (Σ cap hits + dead money == Σ contract values paid); every AI team ends offseason cap-legal with ≥ minimum position counts, across 5 simmed offseasons.

# Phase 7 — Draft & offseason (spec)

**Files:** `Engine/DraftClassFactory.swift`, `Engine/ScoutingEngine.swift`, `Engine/DraftEngine.swift`, `Engine/ProgressionEngine.swift`, `Engine/RetirementEngine.swift`, `Engine/AwardsEngine.swift`, `Engine/StaffEngine.swift` (coordinator market/poaching per `02` §10), `Engine/OffseasonEngine.swift` (10-stage orchestrator per `02` §5), `Engine/RecordsBook.swift`, `Engine/HallOfFame.swift`; app `Features/Draft/`, `Features/Offseason/OffseasonHubView`, `Features/Staff/`, `Features/Awards/`, `Features/HallOfFame/`.
**Spec:** `02` §3 (curve/retirement), §5, §8, §10 (coordinators), §11. Scouting fog = stored per-user `ScoutingReport` (range, revealed flags); draft order reverse standings w/ playoff adjustment; AI need×BPA×personality; pick trades live; UDFA; camp reveal with ▲▼ (coordinator dev bonuses applied); coordinator market at carousel stage (hire/renew/poach, staff budget); awards + All-League voting; records seeded then chased; season summary → `history`. Note: `StaffMember` model + unit-rating/suggest-quality hooks land earlier (P2 reads staff bonuses if present, default nil) — P7 adds the market/lifecycle.
**Gate:** 10-season soak — league mean OVR stays 72–78 every year (no inflation/collapse), age pyramid stable, every offseason completes unattended, draft classes hit steal/bust quotas, HoF inducts by year 6+, **AI teams keep rebuilding (top-5 team churn: no team stays top-5 by OVR 8+ straight years), carousel no-dead-end invariant holds (fired/expired user coach always has ≥1 path), save+backup round-trips clean every season boundary**.

# Phase 8 — Coach RPG, scenarios, ship (spec)

**Files:** `Engine/CoachEngine.swift` (XP, levels, skill effects application, job security, goal generation/eval, firing/job market), `Rules/SkillTrees.swift` (4×6 nodes per `02` §10); app `Features/Coach/` (hub, MyCoach, SkillTree, Goals, TeamSearch), `Features/Trophies/`, `Features/Scenarios/` (3 configs per `02` §12), `Features/Onboarding/` full 4-step wizard per `04` §2, `Features/Settings/`, tutorial overlay, Load Game screen, checkpoints, app icon + accent, App Store metadata.
**Spec:** `02` §10–13; `04` §1–2, §16–21. Skill effects hook points already exist (scouting costs, camp XP, unit ratings, trade threshold, injury odds) — wire, don't refactor.
**Gate:** definition of done (`00`); full new-player path from install to season 2 without docs; adversarial review + `/code-review` clean on final diff.

---

## Self-review checklist (run after expanding each phase plan)

1. Every spec item in the phase's `02`/`04` sections maps to a task.
2. No placeholder steps ("add error handling", "write tests") without content.
3. Names/signatures match the **Interfaces** blocks of earlier phases — grep before renaming anything.
