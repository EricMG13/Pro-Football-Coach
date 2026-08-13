# Cap Compliance (P-2, beat 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `ProManagementSystem.enforceCapCompliance`, a correct and tested forcing function that
releases players — cheapest dead money first — from any AI-controlled professional team that is over
the salary cap at the week-21 season boundary, and wire it into `WorldScheduler` so no persisted root
is ever left illegal.

**Architecture:** A new function in `ProManagementSystem.swift` mutates rosters and dead money
directly (the same technique `ProMarketSystem.expireContracts` already uses this session for the
same reason: intermediate states inside one transaction must not be individually gated by
`WorldIntegrity.check`, only the final result). It validates once at the end using the
difference-based guard already established by `expireContracts` — refuse only what *this* function
introduced, tolerate whatever the incoming root already carried. `WorldScheduler` calls it in the
week-21 boundary block, right after `expireContracts`, and turns its releases into domain events the
same way `expireContracts`'s expiries already are.

**Tech Stack:** Swift 6.0, SwiftPM, the project's hand-rolled `TestKit` harness (no XCTest/swift-testing).

## Global Constraints

- Doc-first: canon (`docs/02-GAME-DESIGN.md` §4.2a) is amended in the same task that changes behaviour it governs, never after.
- TDD for all engine code (`CLAUDE.md`): a failing test before the code that makes it pass.
- One task = one commit, Conventional Commits format.
- No design-token literals, no magic numbers outside a rules module — this plan introduces none; every threshold it uses already exists in `ProRules`/`CollegeRules`.
- Money is integer dollars (`Int`). No floating point.
- Never weaken `WorldIntegrity.checkProfessionalCap`'s enforcement on a *persisted* root — every persisted state remains cap-legal for every team, always. This plan does not touch `WorldIntegrity.swift` at all.
- The controlled professional team (`state.careerArc.currentJob` with `.tier == .professional`) is never auto-released from. If it is over cap, this plan leaves that unresolved and `saveGrowthAndIntegrity`'s existing check refuses the week — the same behaviour as today. A mandatory-decision surface for the player's own team is explicitly out of scope (see the closing note).
- Run `./scripts/verify.sh` (or the equivalent `swift build` + `swift run -c release SimTests`) after the last task and report the real counts.

## Why this is reachable to build but not yet reachable to trigger

Every current entry point that could create a professional contract —
`ProManagementSystem.acquire` (used by both free agency and, via `ProMarketSystem.draft`, the
draft) — refuses any signing that would exceed the cap (`ProManagementSystem.swift:132-134`), and
every contract this project currently generates is flat-salaried with a cap that only grows
(`ProRules.salaryCap`, `ProRules.swift:84-90`). Under today's generation, no reachable game state
ever puts a team over the cap — confirmed this session by `--pro-market-root-probe` finding zero
over-cap teams at the boundary.

That means this plan builds a mechanism with no reachable trigger yet, and says so rather than
inventing one. Deciding *how* a legitimate team becomes over-cap (escalating contract structures via
a future Contract Negotiation screen, a cap that can shrink, something else) is a real game-design
question `02` never answers and this plan does not answer either. What it builds is correct and
tested against hand-constructed fixtures, exactly the standard `expireContracts`, `JerseyNumbers`,
and every other engine addition this session met.

## File Structure

- **Modify** `Sources/FootballSimCore/History/DomainEvent.swift` — one new `DomainEventPayload` case and its three exhaustive-switch sites.
- **Modify** `Sources/FootballSimCore/History/NewsFeedReadModel.swift` — one new headline case.
- **Modify** `Sources/FootballSimCore/People/ProManagementSystem.swift` — the new receipt type and `enforceCapCompliance` function.
- **Modify** `Sources/FootballSimCore/Scheduling/WorldScheduler.swift` — one new `WorldSchedulerError` case, and the wiring call inside `jobAndStaffMarkets`.
- **Create** `Tests/SimTests/Suites/CapComplianceTests.swift` — the new suite (unit-level, `ProManagementSystem.enforceCapCompliance` in isolation).
- **Modify** `Tests/SimTests/Suites/SeasonRolloverTests.swift` — one integration test through `WorldScheduler.advanceWeek`.
- **Modify** `Tests/SimTests/main.swift` — register the new suite, with a focused-gate flag.
- **Modify** `docs/02-GAME-DESIGN.md` §4.2a — record what beat 2 now does and what it still does not.
- **Modify** `docs/plans/2026-08-12-road-to-beta.md` — flip P-2's row and §6/§7 from "not started" to what this plan built.

---

### Task 1: `DomainEventPayload.proCapComplianceRelease`

**Files:**
- Modify: `Sources/FootballSimCore/History/DomainEvent.swift:145` (new case, next to `proContractExpired`), and its `historicalWeight` switch (~line 191) and `referencedEntityIDs` switch (~line 271)
- Modify: `Sources/FootballSimCore/History/NewsFeedReadModel.swift:133` (new headline case, next to `proPlayerSigned`)
- Test: `Tests/SimTests/Suites/CapComplianceTests.swift` (new file, this task starts it)

**Interfaces:**
- Produces: `DomainEventPayload.proCapComplianceRelease(playerID: UUID, teamID: UUID, deadMoneyAdded: Int)` — Task 3 emits it via `WorldScheduler`.

- [ ] **Step 1: Write the failing test**

Create `Tests/SimTests/Suites/CapComplianceTests.swift`:

```swift
import Foundation
import FootballSimCore

func runCapComplianceTests() {
    suite("Cap compliance: event plumbing") {
        test("a compliance release headline names the team and the player") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-0000000CA001")!
            let teamID = UUID(uuidString: "00000000-0000-4000-8000-0000000CA002")!
            let payload = DomainEventPayload.proCapComplianceRelease(
                playerID: playerID,
                teamID: teamID,
                deadMoneyAdded: 500
            )
            expectEqual(payload.historicalWeight, 20)
            expectEqual(Set(payload.referencedEntityIDs), Set([playerID, teamID]))
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift build 2>&1 | tail -20`
Expected: FAIL — `error: type 'DomainEventPayload' has no member 'proCapComplianceRelease'`

- [ ] **Step 3: Add the case and wire the two exhaustive switches**

In `Sources/FootballSimCore/History/DomainEvent.swift`, immediately after the `proContractExpired` case (currently line 145):

```swift
    case proContractExpired(playerID: UUID)
    case proCapComplianceRelease(playerID: UUID, teamID: UUID, deadMoneyAdded: Int)
```

In the `historicalWeight` switch, add it to the same group as `proPlayerSigned` (currently line 191):

```swift
        case .playerJoined, .playerDeparted, .portalEntered, .redshirtResolved, .proPlayerSigned,
             .proCapComplianceRelease:
            return 20
```

In the `referencedEntityIDs` switch, add a case next to the other `pro*` release-shaped events (find `case let .proPracticeSquadMoved(playerID, teamID, _):` and add immediately after its `return [playerID, teamID]`):

```swift
        case let .proCapComplianceRelease(playerID, teamID, _):
            return [playerID, teamID]
```

- [ ] **Step 4: Add a headline in NewsFeedReadModel**

In `Sources/FootballSimCore/History/NewsFeedReadModel.swift`, immediately after the `proPlayerSigned` case (currently line 133-134):

```swift
        case let .proPlayerSigned(playerID, teamID, kind, _):
            return "\(who(teamID)) sign \(who(playerID)) (\(kind.rawValue))"
        case let .proCapComplianceRelease(playerID, teamID, _):
            return "\(who(teamID)) release \(who(playerID)) to clear cap space"
```

- [ ] **Step 5: Run test to verify it passes**

Run: `swift build && swift run SimTests --cap-compliance 2>&1 | tail -10`

(This flag does not exist yet — Task 4 adds it. For this step, run the suite function directly by
temporarily confirming compilation only: `swift build 2>&1 | tail -20`)
Expected: `Build complete!` with no errors. The test itself is exercised once Task 4 wires the runner;
confirm no compiler errors here rather than a pass/fail count.

- [ ] **Step 6: Commit**

```bash
git add Sources/FootballSimCore/History/DomainEvent.swift Sources/FootballSimCore/History/NewsFeedReadModel.swift Tests/SimTests/Suites/CapComplianceTests.swift
git commit -m "feat: add the cap-compliance-release domain event"
```

---

### Task 2: `enforceCapCompliance` — the success and ordering case

**Files:**
- Modify: `Sources/FootballSimCore/People/ProManagementSystem.swift` (new types and function, appended after `release`, before `draftOrder` — currently between lines 183 and 185)
- Test: `Tests/SimTests/Suites/CapComplianceTests.swift`

**Interfaces:**
- Consumes: `ProManagementSystem.capSnapshot(teamID:in:) throws -> ProCapSnapshot` (existing), `Contract.deadMoney(ifReleasedAtSeason:) -> Int` (existing), `ProMarketState.addFreeAgent(_:) -> Bool` (existing, bounded by `ProMarketState.maximumFreeAgentIDs`), `WorldIntegrity.check(_:) -> IntegrityReport` (existing)
- Produces:
  ```swift
  public struct ProCapComplianceRelease: Sendable, Equatable {
      public let playerID: UUID
      public let teamID: UUID
      public let deadMoneyAdded: Int
  }
  public struct ProCapComplianceReceipt: Sendable, Equatable {
      public let state: GameState
      public let releases: [ProCapComplianceRelease]
  }
  public static func enforceCapCompliance(
      at calendar: CalendarState,
      in state: GameState
  ) throws -> ProCapComplianceReceipt
  ```
  Task 3 consumes this exact signature and `receipt.releases`.

- [ ] **Step 1: Write the failing test**

Append to `Tests/SimTests/Suites/CapComplianceTests.swift`, inside a new suite in the same file
(add this suite call after the existing `suite("Cap compliance: event plumbing")` block, still
inside `runCapComplianceTests()`):

```swift
    suite("Cap compliance: enforcement") {
        test("compliance releases the cheapest dead money first, and stops once legal") {
            var state = GameState.bootstrap(seed: 62_001)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], team.rosterIDs.count >= 2 else {
                expect(false, "the fixture team has fewer than two rostered players")
                return
            }
            // A clean baseline: every contract this team holds is stripped, so the numbers below
            // are exact rather than layered on whatever bootstrap happened to sign.
            for playerID in team.rosterIDs + team.practiceSquadIDs {
                state.players.update(playerID) { $0.contract = nil }
            }
            _ = state.proTeams.update(teamID) { $0.deadMoney = 0 }

            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            let halfCap = capLimit / 2
            let cheapID = team.rosterIDs[0]
            let costlyID = team.rosterIDs[1]
            // Both contracts are legal alone (each capHit is roughly half the cap); together
            // they push the team over. Releasing either alone legalises the team, so the only
            // thing that decides which one goes is dead money: cheap carries 500, costly 50,000.
            // Signing bonuses divide evenly by the 5-year proration so the arithmetic is exact.
            state.players.update(cheapID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: Array(repeating: halfCap - 1_000, count: 5),
                    signingBonus: 500
                )
            }
            state.players.update(costlyID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: Array(repeating: halfCap - 1_000, count: 5),
                    signingBonus: 50_000
                )
            }

            let before = try ProManagementSystem.capSnapshot(teamID: teamID, in: state)
            expect(!before.isWithinCap, "the fixture is not actually over cap")

            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expectEqual(receipt.releases.map(\.playerID), [cheapID])
            expectEqual(receipt.releases.first?.deadMoneyAdded, 500)
            expectEqual(receipt.releases.first?.teamID, teamID)

            let after = try ProManagementSystem.capSnapshot(teamID: teamID, in: receipt.state)
            expect(after.isWithinCap, "the team is still over cap after compliance")
            expect(receipt.state.players[costlyID]?.contract != nil,
                   "the costly contract was released even though the cheap one alone sufficed")
            expect(receipt.state.players[cheapID]?.contract == nil)
            expect(receipt.state.proTeams[teamID]?.rosterIDs.contains(cheapID) != true)
            expect(receipt.state.proMarket.freeAgentIDs.contains(cheapID))
            expectEqual(receipt.state.proTeams[teamID]?.deadMoney, 500)
            expect(WorldIntegrity.check(receipt.state).isValid)
        }

        test("a team already within the cap is untouched") {
            let state = GameState.bootstrap(seed: 62_002)
            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expect(receipt.releases.isEmpty, "a legal bootstrap world had releases forced on it")
            expectEqual(
                try SaveEnvelope.encode(receipt.state),
                try SaveEnvelope.encode(state)
            )
        }
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift build 2>&1 | tail -20`
Expected: FAIL — `error: type 'ProManagementSystem' has no member 'enforceCapCompliance'`

- [ ] **Step 3: Write the implementation**

In `Sources/FootballSimCore/People/ProManagementSystem.swift`, insert after the closing brace of
`release` (currently line 183) and before `draftOrder` (currently line 185):

```swift
    public struct ProCapComplianceRelease: Sendable, Equatable {
        public let playerID: UUID
        public let teamID: UUID
        public let deadMoneyAdded: Int
    }

    public struct ProCapComplianceReceipt: Sendable, Equatable {
        public let state: GameState
        public let releases: [ProCapComplianceRelease]
    }

    /// Beat 2 (`02` §4.2), the AI-facing half. Every professional team except the controlled one
    /// — that one is skipped deliberately; a mandatory decision for the player's own cap choices
    /// is a separate, unbuilt surface — is released down to cap-legal, cheapest dead money first.
    ///
    /// Mutates roster, contract and dead-money state directly rather than delegating to `release`,
    /// for the same reason `ProMarketSystem.expireContracts` does: `release`'s own internal
    /// `WorldIntegrity.check` is unconditional, so an intermediate state that is still over cap
    /// after one release (but less over cap than before) would be self-rejected before a second
    /// release could run. Validated once at the end instead, against only what this function
    /// itself introduced — the same difference-based guard `expireContracts` uses, so a root that
    /// already carries an unrelated issue is not falsely blamed on this pass.
    ///
    /// `WorldIntegrity.checkProfessionalCap` itself is untouched and stays exactly as strict as it
    /// is today: this function's job is to make sure nothing calls it with a still-over-cap root
    /// once compliance has run, not to relax what it checks.
    public static func enforceCapCompliance(
        at calendar: CalendarState,
        in state: GameState
    ) throws -> ProCapComplianceReceipt {
        let controlledTeamID = state.careerArc.currentJob.flatMap { job in
            job.tier == .professional ? job.organisationID : nil
        }
        var next = state
        var releases: [ProCapComplianceRelease] = []
        for teamID in state.proTeams.ids where teamID != controlledTeamID {
            while true {
                guard let snapshot = try? capSnapshot(teamID: teamID, in: next),
                      !snapshot.isWithinCap else { break }
                guard let team = next.proTeams[teamID] else {
                    throw ProManagementError.missingTeam
                }
                let candidates = (team.rosterIDs + team.practiceSquadIDs).compactMap {
                    playerID -> (UUID, Int)? in
                    guard let contract = next.players[playerID]?.contract else { return nil }
                    return (playerID, contract.deadMoney(ifReleasedAtSeason: calendar.season))
                }
                // Ties broken by identifier, the same rule every other deterministic ordering in
                // this project uses, so two processes given the same root release the same player.
                guard let (playerID, deadMoneyAdded) = candidates.min(by: { lhs, rhs in
                    lhs.1 == rhs.1 ? lhs.0.uuidString < rhs.0.uuidString : lhs.1 < rhs.1
                }) else {
                    // No contracted player remains and the team is still over cap: dead money
                    // alone exceeds the limit. Nothing left to release makes it legal.
                    throw ProManagementError.capExceeded
                }
                guard team.deadMoney <= Int.max - deadMoneyAdded else {
                    throw ProManagementError.invalidTeamRoster
                }
                next.proTeams.update(teamID) {
                    $0.rosterIDs.removeAll { $0 == playerID }
                    $0.practiceSquadIDs.removeAll { $0 == playerID }
                    $0.deadMoney += deadMoneyAdded
                }
                next.players.update(playerID) { $0.contract = nil }
                if !next.proMarket.freeAgentIDs.contains(playerID) {
                    guard next.proMarket.addFreeAgent(playerID) else {
                        throw ProManagementError.invalidRoot
                    }
                }
                releases.append(ProCapComplianceRelease(
                    playerID: playerID,
                    teamID: teamID,
                    deadMoneyAdded: deadMoneyAdded
                ))
            }
        }
        let inherited = WorldIntegrity.check(state).issues
        let introduced = WorldIntegrity.check(next).issues.filter { !inherited.contains($0) }
        guard introduced.isEmpty else { throw ProManagementError.invalidRoot }
        return ProCapComplianceReceipt(state: next, releases: releases)
    }

```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift build -c release 2>&1 | tail -20 && swift run -c release SimTests --cap-compliance 2>&1 | tail -20`

(The `--cap-compliance` flag is added in Task 4. Until then, verify with a temporary local run: add
`runCapComplianceTests()` to the `else` branch of `Tests/SimTests/main.swift` at the same point Task
4 makes permanent, run `swift build -c release && swift run -c release SimTests 2>&1 | grep -A3
"Cap compliance"`, then leave that temporary edit in place — Task 4 supersedes it.)

Expected: both tests in `"Cap compliance: enforcement"` and the plumbing test from Task 1 pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/People/ProManagementSystem.swift Tests/SimTests/Suites/CapComplianceTests.swift
git commit -m "feat: enforce cap compliance, cheapest dead money first"
```

---

### Task 3: The "cannot legalize" and "controlled team is skipped" cases

**Files:**
- Modify: `Tests/SimTests/Suites/CapComplianceTests.swift`

**Interfaces:**
- Consumes: `ProManagementSystem.enforceCapCompliance` (Task 2), `ProManagementError.capExceeded` (existing), `CareerArcState`, `CareerJob`, `CareerJobTier.professional` (existing — confirm the exact case name in `Sources/FootballSimCore/Career/CareerArcState.swift` before writing; it is used identically in `Sources/FootballSimCore/Pro/ProRosterAISystem.swift:27-29`)

- [ ] **Step 1: Write the two failing tests**

Append inside the same `suite("Cap compliance: enforcement")` block from Task 2:

```swift
        test("a team with no releasable path to legality throws rather than persists") {
            var state = GameState.bootstrap(seed: 62_003)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], let onlyPlayerID = team.rosterIDs.first else {
                expect(false, "the fixture team has no rostered players")
                return
            }
            for playerID in team.rosterIDs + team.practiceSquadIDs where playerID != onlyPlayerID {
                _ = state.proTeams.update(teamID) { squad in
                    squad.rosterIDs.removeAll { $0 == playerID }
                    squad.practiceSquadIDs.removeAll { $0 == playerID }
                }
            }
            // Dead money already on the books, alone, exceeds the cap. No release of the one
            // remaining contracted player can ever bring committedCap back under the limit,
            // because releasing it only adds more dead money on top.
            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            _ = state.proTeams.update(teamID) { $0.deadMoney = capLimit + 1 }
            state.players.update(onlyPlayerID) {
                $0.contract = Contract(years: 1, baseSalaryByYear: [1], signingBonus: 0)
            }

            do {
                _ = try ProManagementSystem.enforceCapCompliance(at: state.calendar, in: state)
                expect(false, "an unfixable over-cap team did not throw")
            } catch ProManagementError.capExceeded {
                expect(true)
            } catch {
                expect(false, "wrong error: \(error)")
            }
        }

        test("the controlled team is never auto-released from") {
            var state = GameState.bootstrap(seed: 62_004)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], team.rosterIDs.count >= 1 else {
                expect(false, "the fixture team has no rostered players")
                return
            }
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            let overCapPlayerID = team.rosterIDs[0]
            state.players.update(overCapPlayerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [capLimit + 1_000_000],
                    signingBonus: 0
                )
            }

            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expect(receipt.releases.isEmpty, "the controlled team was released from")
            expect(receipt.state.players[overCapPlayerID]?.contract != nil,
                   "the controlled team's over-cap contract was force-released")
        }
```

- [ ] **Step 2: Run tests to verify they fail or reveal what is missing**

Run: `swift build -c release 2>&1 | tail -30`

Expected: this should already compile and the first new test should pass, since Task 2's
implementation already throws `capExceeded` when no candidate remains, and already skips
`controlledTeamID`. If both pass immediately, that confirms Task 2's implementation — proceed to
Step 3 with no code change needed. If either fails, fix `enforceCapCompliance` in
`Sources/FootballSimCore/People/ProManagementSystem.swift` before continuing; do not weaken the test.

- [ ] **Step 3: Run tests to verify they pass**

Run: `swift run -c release SimTests --cap-compliance 2>&1 | tail -20` (temporary local wiring per
Task 2 Step 4, superseded by Task 4)

Expected: all four tests in `CapComplianceTests.swift` pass.

- [ ] **Step 4: Commit**

```bash
git add Tests/SimTests/Suites/CapComplianceTests.swift
git commit -m "test: pin the unfixable-team and controlled-team boundaries"
```

---

### Task 4: Wire into `WorldScheduler`, and register the suite

**Files:**
- Modify: `Sources/FootballSimCore/Scheduling/WorldScheduler.swift:67-78` (`WorldSchedulerError` enum) and the week-21 boundary block (currently lines 443-536, immediately after the `expireContracts` block's closing `catch` at line 480)
- Modify: `Tests/SimTests/main.swift` (register `runCapComplianceTests()` permanently, remove any temporary wiring from Task 2/3, add a `--cap-compliance` focused-gate flag)
- Modify: `Tests/SimTests/Suites/SeasonRolloverTests.swift` (one new integration test)

**Interfaces:**
- Consumes: `ProManagementSystem.enforceCapCompliance(at:in:) throws -> ProCapComplianceReceipt` (Task 2), `ProManagementError` (existing), `WorldSchedulerError` (existing enum, this task adds one case)

- [ ] **Step 1: Write the failing integration test**

Append to `Tests/SimTests/Suites/SeasonRolloverTests.swift`, inside `runSeasonRolloverTests()`'s
existing `suite("Season rollover")` block (add after the last existing test in that suite):

```swift
        test("a compliance-forced release survives a real week-21 boundary") {
            var state = GameState.bootstrap(seed: 97_006)
            for _ in 0..<(SharedRules.inSeasonWeeks - 1) {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar.week, SharedRules.inSeasonWeeks)
            let teamID = state.proTeams.ids.first { $0 != controlledTeamID(in: state) }
            guard let teamID, let team = state.proTeams[teamID],
                  let playerID = team.rosterIDs.first else {
                expect(false, "no eligible non-controlled team with a rostered player")
                return
            }
            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            state.players.update(playerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [capLimit + 1_000_000],
                    signingBonus: 0
                )
            }

            let transition = try WorldScheduler.advanceWeek(state)
            let snapshot = try ProManagementSystem.capSnapshot(
                teamID: teamID,
                in: transition.state
            )
            expect(snapshot.isWithinCap,
                   "a real advanceWeek left a team over the cap after the boundary")
            expect(WorldIntegrity.check(transition.state).isValid)
        }
```

Add this small helper at the bottom of the same file, outside the `runSeasonRolloverTests()`
function (matching the file's existing pattern of file-private helpers below the run function):

```swift
private func controlledTeamID(in state: GameState) -> UUID? {
    state.careerArc.currentJob.flatMap { job in
        job.tier == .professional ? job.organisationID : nil
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift build -c release 2>&1 | tail -20 && swift run -c release SimTests --season-rollover 2>&1 | tail -10`
Expected: FAIL — the team is still over cap after `advanceWeek`, because nothing calls
`enforceCapCompliance` yet.

- [ ] **Step 3: Add the `WorldSchedulerError` case**

In `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`, in the `WorldSchedulerError` enum
(currently lines 67-78), add one case next to `professionalMarketFailed`:

```swift
    case professionalMarketFailed(ProMarketError)
    case capComplianceFailed(ProManagementError)
```

- [ ] **Step 4: Call `enforceCapCompliance` in the boundary block**

In `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`, immediately after the `expireContracts`
block's closing brace (the `catch let error as ProMarketError { throw
WorldSchedulerError.professionalMarketFailed(error) }` that currently ends at line 480, right before
the `// After the people transition has been applied...` comment), insert:

```swift
                    do {
                        let compliance = try ProManagementSystem.enforceCapCompliance(
                            at: completed,
                            in: nextState
                        )
                        nextState = compliance.state
                        try appendEvents(
                            payloads: compliance.releases.map {
                                .proCapComplianceRelease(
                                    playerID: $0.playerID,
                                    teamID: $0.teamID,
                                    deadMoneyAdded: $0.deadMoneyAdded
                                )
                            },
                            occurredAt: completed,
                            to: &nextState,
                            emittedEvents: &events
                        )
                    } catch let error as ProManagementError {
                        throw WorldSchedulerError.capComplianceFailed(error)
                    }
```

- [ ] **Step 5: Register the suite permanently**

In `Tests/SimTests/main.swift`, remove any temporary wiring added during Task 2/3's verification
steps. Add the focused-gate branch next to `--season-rollover` (find `} else if
CommandLine.arguments.contains("--season-rollover") {` and add immediately before it):

```swift
} else if CommandLine.arguments.contains("--cap-compliance") {
    runCapComplianceTests()
} else if CommandLine.arguments.contains("--season-rollover") {
```

In the same file's default (no-argument) branch, add `runCapComplianceTests()` immediately before
the existing `runSeasonRolloverTests()` call:

```swift
    runCapComplianceTests()
    runSeasonRolloverTests()
```

- [ ] **Step 6: Run test to verify it passes**

Run: `swift build -c release 2>&1 | tail -20 && swift run -c release SimTests --season-rollover 2>&1 | tail -10`
Expected: `all passed`, including the new boundary test.

Run: `swift run -c release SimTests --cap-compliance 2>&1 | tail -10`
Expected: `5 tests` (Task 1's plumbing test plus Task 2's two enforcement tests plus Task 3's two
boundary tests — actual count confirmed at execution: `5 tests, 18 checks, all passed`), `all passed`.

- [ ] **Step 7: Run the full suite**

Run: `./scripts/verify.sh` (or `swift build -c release && swift run -c release SimTests 2>&1 | tail -10`)
Expected: `all passed`, and report the exact test/check counts in the commit message — do not guess
them.

- [ ] **Step 8: Commit**

```bash
git add Sources/FootballSimCore/Scheduling/WorldScheduler.swift Tests/SimTests/main.swift Tests/SimTests/Suites/SeasonRolloverTests.swift
git commit -m "feat: wire cap compliance into the week-21 boundary"
```

---

### Task 5: Canon and the plan register

**Files:**
- Modify: `docs/02-GAME-DESIGN.md` (§4.2a, immediately after the existing "Cuts are forced by the compliance date" paragraph)
- Modify: `docs/plans/2026-08-12-road-to-beta.md` (the P-2 row in §1's table, and §6's O-1 row)

**Interfaces:** None — documentation only.

- [ ] **Step 1: Amend `02` §4.2a**

In `docs/02-GAME-DESIGN.md`, immediately after the paragraph beginning "**Cuts are forced by the
compliance date, and by nothing else**" (search for that exact phrase), insert a new paragraph:

```markdown
**The AI-facing half is built — `ProManagementSystem.enforceCapCompliance`, added 2026-08-13.**
Every professional team except the one the player controls is released down to cap-legal at the
week-21 boundary, cheapest dead money first, entirely within the same `advanceWeek` transition that
already runs beat 1's expiry — so no *persisted* root is ever over the cap, the same guarantee
`docs/PORT-LOG.md`'s cap-laundering defences already protect. `WorldIntegrity.checkProfessionalCap`
is untouched: it stays exactly as strict as it has always been, checking the final state only.

**The controlled team's own cap choice is deliberately not built here.** Every other consequential
choice in this game — a redshirt, a portal decision, an NIL allocation, a recruiting action — is the
player's to make through a mandatory decision, never automated out from under them. Forcing releases
on the player's own roster the same way the AI's are forced would break that pattern, so this pass
skips the controlled team entirely: if it is ever over cap, the week does not advance until the
player resolves it themselves, the same behaviour as before this change. A mandatory-decision surface
for that case is real remaining work, not built here, and needs its own design pass before it is.

Under today's generation this mechanism has no reachable trigger: every signing path already refuses
anything that would exceed the cap, and every contract this project generates is flat-salaried
against a cap that only grows, so no current game state can produce an over-cap team at all — proven
by `--pro-market-root-probe` finding zero, and unchanged by this addition. What legitimate mechanic
would ever put a team over the cap remains an open question this document does not answer.
```

- [ ] **Step 2: Update the road-to-beta plan register**

In `docs/plans/2026-08-12-road-to-beta.md`, replace the P-2 row (search for `| P-2 |`):

```markdown
| P-2 | **Cap-compliance cuts (beat 2)** — owner decided cuts are forced by the compliance date and nothing else | **AI-facing half done, 2026-08-13** (`ProManagementSystem.enforceCapCompliance`, wired into the week-21 boundary). Correct and tested against hand-built fixtures; has no reachable trigger under current generation, and the controlled team's own mandatory-decision path is explicit remaining work — see `02` §4.2a |
```

In §6 (the owner-decisions table), replace the O-1 row's final cell content after "needs its own
phase plan" with an added sentence noting the phase happened:

Find the O-1 row (search for `| O-1 |`) and append to the end of its final cell, before the closing
`|`:

```markdown
 **The forcing half of (b) is now built** — see the P-2 row above and `02` §4.2a. The invariant
 itself (`WorldIntegrity.checkProfessionalCap`) was never touched; only a function that runs before
 it was added.
```

- [ ] **Step 3: No test for this step** — documentation changes are verified by reading, not by a
  test run. Re-read both amended sections once written to confirm they match what Tasks 1-4 actually
  built (exact function name, exact file, exact behaviour) rather than what was planned before
  writing the code.

- [ ] **Step 4: Commit**

```bash
git add docs/02-GAME-DESIGN.md docs/plans/2026-08-12-road-to-beta.md
git commit -m "docs: record the cap-compliance forcing function, and what it does not resolve"
```

---

## Self-Review

**Spec coverage.** Every requirement in the arguments this plan was given: the fork resolved to (b)
→ Task 2/4 build exactly that, scoped to the week-21 boundary only (Task 4 Step 4's insertion point).
`enforceCapCompliance` did not exist → Task 2 creates it. Must not weaken cap enforcement outside the
window → confirmed by never touching `WorldIntegrity.swift` at all (Global Constraints, restated in
Task 2's Step 3 code comment). Must not touch the cap-laundering defences → `capSnapshot`'s existing
practice-squad-inclusive accounting is reused unchanged; Task 5 cites `PORT-LOG.md` by name. TDD →
every code task (1-4) writes a failing test before the implementation. "Skipping the controlled team"
(the source note's own words) → Task 2's implementation and Task 3's dedicated test.

**Placeholder scan.** No TBD/TODO. Every step shows complete code. Task 4 Step 6's expected count for
`--cap-compliance` is flagged as needing a recount rather than asserted as a guess — that is a real
instruction to the implementer, not a placeholder for content.

**Type consistency.** `ProCapComplianceReceipt.releases: [ProCapComplianceRelease]` (Task 2) is what
Task 3's tests read (`receipt.releases.map(\.playerID)`) and what Task 4's `WorldScheduler` wiring
maps into event payloads (`compliance.releases.map { .proCapComplianceRelease(...) }`) — one shape,
used identically in both places it crosses a task boundary.
