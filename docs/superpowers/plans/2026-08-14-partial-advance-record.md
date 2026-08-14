# G-15: Partial-Advance Completion Record — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When `WorldScheduler.advanceWeek` fails partway through its 15-step weekly transaction,
expose which steps actually committed before the failure — closing gap G-15's backend half — instead
of discarding that information the way every one of its ~24 throw sites does today.

**Architecture:** `advanceWeek` already accumulates `records: [WorldStepRecord]` and
`events: [DomainEvent]` in plain local `var`s as it works through the step loop. Every existing
`throw WorldSchedulerError.xyz(...)` statement stays exactly where it is — none of the ~24 throw
sites are touched. Instead, the whole loop-and-return body is wrapped in one `do/catch` that, on any
`WorldSchedulerError`, re-throws a new `interrupted` case carrying whatever `records`/`events` had
accumulated at that point, plus the original error. This is a single change at the function's outer
shape, not 24 scattered edits.

**Tech Stack:** Swift 6.0, SwiftPM, hand-rolled `TestKit` — no XCTest. Engine-only
(`Sources/FootballSimCore/`); no UI wiring in this pass.

## Global Constraints

- Engine code only — zero `import SwiftUI` (`CLAUDE.md`).
- TDD for all engine code: failing test before the code that makes it pass (`CLAUDE.md`).
- No unrequested UI wiring — `Sources/CoachWorldApp/CoachWorldStore.swift` and
  `Sources/CoachWorldApp/CoachWorldAppRootView.swift` are explicitly out of scope for this pass
  (current session direction: backend only).
- Must not weaken any existing guarantee: no persisted (returned, usable) `GameState` may ever be
  invalid; the interrupted case exposes *what ran*, never a half-applied root.

---

## Impact analysis

`mcp__gitnexus__impact` on `WorldScheduler.advanceWeek` (upstream): **HIGH, 62 impacted, 19 direct
callers**. This is ordinary call-graph fan-out (test suites and `IntentResolver.swift` calling
`advanceWeek` at all) — not fragility around the thrown error's shape. Confirmed by an exhaustive
grep of `WorldSchedulerError` across `Sources/` and `Tests/`
(`grep -rn "WorldSchedulerError" Sources/ Tests/`): every one of the ~24 non-test occurrences is a
`throw` site inside `WorldScheduler.swift` itself. Exactly **one** place outside that file references
the type at all — `Tests/SimTests/Suites/EventLedgerBatchTests.swift:270`,
`catch let error as WorldSchedulerError { expectEqual(error, .eventAppendFailed) }` — and it compares
against one specific case by value. That is the only call site this plan's Task 1 must update.

`mcp__gitnexus__impact` on `WorldSchedulerError` and `WorldTransition` (upstream, re-checked for this
plan): both report **0 upstream** in the graph beyond `WorldScheduler.swift` itself — consistent with
the grep above; the graph tool does not resolve enum-case-level or nested-property-level references,
so the manual grep is the authoritative check here, as it was for `WorldSchedulerError`.

---

### Task 1: `WorldSchedulerError.interrupted`, the `do/catch` wrapper, and its tests

**Files:**
- Modify: `Sources/FootballSimCore/Scheduling/WorldScheduler.swift` (enum at lines 67–79; function
  body at lines 87–650)
- Modify: `Tests/SimTests/Suites/ArchitectureTests.swift` (suite `"World scheduler"`, lines 241–308 —
  add a new test)
- Modify: `Tests/SimTests/Suites/EventLedgerBatchTests.swift` (test `"an exhausted event sequence
  makes scheduler materialization fail cleanly"`, lines 258–273 — its assertion must change because
  the thrown shape changes)

**Interfaces:**
- Consumes: `WorldStepRecord{step: WorldStep, status: WorldStepStatus}` (existing, `Equatable`),
  `DomainEvent` (existing, `Equatable` — confirmed by reading
  `Sources/FootballSimCore/History/DomainEvent.swift:313`,
  `public struct DomainEvent: Codable, Sendable, Equatable, Identifiable`), `WorldScheduler.steps:
  [WorldStep]` (existing, the canonical 15-step order).
- Produces: a new case on the existing public type —
  `indirect case interrupted(committedSteps: [WorldStepRecord], committedEvents: [DomainEvent],
  underlying: WorldSchedulerError)` on `WorldSchedulerError`. `advanceWeek`'s signature
  (`public static func advanceWeek(_ state: GameState) throws -> WorldTransition`) is **unchanged**
  — only what it throws on failure gets richer.

- [ ] **Step 1: Write the failing tests**

In `Tests/SimTests/Suites/ArchitectureTests.swift`, inside `suite("World scheduler")` (after the
last test, `"the shared calendar rolls from week twenty-one into a new season"`, which ends at line
307, and before the suite's closing `}` at line 308), add:

```swift
        test("an interrupted advance reports exactly the steps that committed") {
            var state = GameState.bootstrap(seed: 74_102)
            var exhausted = DomainEventLedger(retentionLimit: 2)
            expect(exhausted.append(ledgerEvent(
                sequence: Int.max,
                occurredAt: state.calendar
            )))
            state.history = exhausted

            do {
                _ = try WorldScheduler.advanceWeek(state)
                expect(false, "the scheduler advanced past an exhausted event sequence")
            } catch let error as WorldSchedulerError {
                guard case let .interrupted(committedSteps, committedEvents, underlying) = error else {
                    expect(false, "an exhausted event sequence did not raise .interrupted: \(error)")
                    return
                }
                expectEqual(underlying, .eventAppendFailed)
                expect(committedSteps.count < WorldScheduler.steps.count,
                       "a partial advance reported every step as committed")
                expectEqual(
                    committedSteps.map(\.step),
                    Array(WorldScheduler.steps.prefix(committedSteps.count)),
                    "committed steps were not a prefix of the canonical step order"
                )
                expect(committedEvents.count <= committedSteps.count + 1,
                       "more events were reported than the committed steps could plausibly have emitted")
            }
        }
```

This reuses the exact fixture shape already proven (in `EventLedgerBatchTests.swift`) to trigger
`WorldSchedulerError.eventAppendFailed` deterministically — a ledger with `retentionLimit: 2` that
already holds one event at `sequence: Int.max`, so the very next sequence allocation overflows. It
asserts *properties* of `committedSteps` (a genuine prefix of the canonical order, strictly shorter
than the full 15) rather than one hardcoded exact list, because exactly which step first tries to
append a non-empty event batch is a detail of `PeopleLifecycleSystem`/`DevelopmentSystem`'s
data-dependent output, not something this plan should freeze into a brittle assertion.

`ledgerEvent(sequence:occurredAt:)` is declared in `Tests/SimTests/Suites/EventLedgerBatchTests.swift`
at file scope (not `private`, confirm this when reading the file in Step 2 below — if it is `private`
to that file, copy its body inline into this test instead of trying to reference it cross-file; read
the existing declaration first and use whatever it actually contains, do not guess its signature).

Then, in `Tests/SimTests/Suites/EventLedgerBatchTests.swift`, update the existing test (lines
258–273) — its catch block currently expects the old flat shape and will now receive `.interrupted`
instead:

```swift
        test("an exhausted event sequence makes scheduler materialization fail cleanly") {
            var state = GameState.bootstrap(seed: 74_102)
            var exhausted = DomainEventLedger(retentionLimit: 2)
            expect(exhausted.append(ledgerEvent(
                sequence: Int.max,
                occurredAt: state.calendar
            )))
            state.history = exhausted

            do {
                _ = try WorldScheduler.advanceWeek(state)
                expect(false, "the scheduler advanced past an exhausted event sequence")
            } catch let error as WorldSchedulerError {
                guard case let .interrupted(_, _, underlying) = error else {
                    expect(false, "an exhausted event sequence did not raise .interrupted: \(error)")
                    return
                }
                expectEqual(underlying, .eventAppendFailed)
            }
        }
```

- [ ] **Step 2: Run the tests to verify they fail**

Read `Tests/SimTests/Suites/EventLedgerBatchTests.swift` first to confirm the exact signature of
`ledgerEvent(sequence:occurredAt:)` before relying on it in Step 1's new test.

Run: `swift run -c release SimTests --architecture-only`
Expected: build FAILS — `.interrupted` is not a member of `WorldSchedulerError`.

- [ ] **Step 3: Add the `interrupted` case**

In `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`, change the enum at lines 67–79:

```swift
public enum WorldSchedulerError: Error, Equatable {
    case integrityFailed([IntegrityIssue])
    case scheduledGameMissing(UUID)
    case scheduledGameResultMissing(UUID)
    case scheduleResultRecordingFailed(ScheduleResultRecordingError)
    case eventAppendFailed
    case aiRecruitingActionFailed(RecruitingActionError)
    case collegeCycleFailed
    case portalMarketFailed(CollegePortalWindow)
    case portalCommitFailed(CollegePortalWindow)
    case professionalMarketFailed(ProMarketError)
    case capComplianceFailed(ProManagementError)
    indirect case interrupted(
        committedSteps: [WorldStepRecord],
        committedEvents: [DomainEvent],
        underlying: WorldSchedulerError
    )
}
```

The case is `indirect` because its own associated value is `WorldSchedulerError` itself — without
`indirect`, the compiler cannot compute a finite in-memory size for the enum (every value would need
to embed a full copy of itself).

- [ ] **Step 4: Wrap `advanceWeek`'s body in `do/catch`**

In the same file, `advanceWeek` currently reads (lines 87–650, abbreviated — the full step loop and
its 15 `case` branches are unchanged, only the outer wrapping changes):

```swift
    public static func advanceWeek(_ state: GameState) throws -> WorldTransition {
        var nextState = state
        let completed = state.calendar
        let next = completed.advancedWeek()
        var records: [WorldStepRecord] = []
        var events: [DomainEvent] = []

        for step in steps {
            switch step {
            // ... all 15 case branches, unchanged, exactly as they are today ...
            }
        }

        let snapshot = WeekSnapshot(
            completed: completed,
            next: next,
            emittedEventIDs: events.map(\.id)
        )
        return WorldTransition(
            state: nextState,
            snapshot: snapshot,
            stepRecords: records,
            emittedEvents: events
        )
    }
```

Change it to:

```swift
    public static func advanceWeek(_ state: GameState) throws -> WorldTransition {
        var nextState = state
        let completed = state.calendar
        let next = completed.advancedWeek()
        var records: [WorldStepRecord] = []
        var events: [DomainEvent] = []

        do {
            for step in steps {
                switch step {
                // ... all 15 case branches, unchanged, exactly as they are today ...
                }
            }

            let snapshot = WeekSnapshot(
                completed: completed,
                next: next,
                emittedEventIDs: events.map(\.id)
            )
            return WorldTransition(
                state: nextState,
                snapshot: snapshot,
                stepRecords: records,
                emittedEvents: events
            )
        } catch let error as WorldSchedulerError {
            throw WorldSchedulerError.interrupted(
                committedSteps: records,
                committedEvents: events,
                underlying: error
            )
        }
    }
```

Every one of the 15 `case` branches inside the `switch` — and every `throw WorldSchedulerError.xyz(...)`
inside them, and inside the `private` helpers `appendEvents`, `resolveAndCommitPortal`, and
`appendExistingEvents` that the loop body calls via `try` — is copied over **character for character**
from the current file. Do not retype them from memory; move the existing text as-is and only add the
new `do {` after the four `var`/`let` declarations and the new `} catch let error as
WorldSchedulerError { ... }` block after the `return WorldTransition(...)` statement's closing brace.
A throw from any of the three `private` helper functions still reaches this `catch`, because Swift
error propagation unwinds through `try` call sites up to the nearest enclosing `do/catch` in the
calling function's body regardless of how many function-call layers deep the `throw` originated —
the helpers do not need their own `do/catch`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `swift run -c release SimTests --architecture-only`
Expected: `"World scheduler"` suite passes, including the new test. Then run the event-ledger suite:

Run: `swift run -c release SimTests` (find the correct `--<flag>` for
`Tests/SimTests/Suites/EventLedgerBatchTests.swift` by reading `Tests/SimTests/main.swift` first, or
just run the full default suite since both suites are in it) and confirm `"Atomic domain-event
batches"` / whichever suite name `EventLedgerBatchTests.swift` registers passes with the updated
test.

- [ ] **Step 6: Run the full suite to check for regressions**

Run: `swift run -c release SimTests`
Expected: every suite passes. Pay particular attention to any suite whose tests construct a
`WorldSchedulerError` and compare it directly (the grep in the impact-analysis section above found
none besides the one test this task already updates, but the full run is the actual check, not the
grep).

- [ ] **Step 7: Commit**

```bash
git add Sources/FootballSimCore/Scheduling/WorldScheduler.swift \
        Tests/SimTests/Suites/ArchitectureTests.swift \
        Tests/SimTests/Suites/EventLedgerBatchTests.swift
git commit -m "feat: report the steps that committed before a scheduler interruption (G-15)"
```

---

### Task 2: Close out the docs

**Files:**
- Modify: `docs/03b-ARCHITECTURE.md` (§2, "The engine/UI contract", lines 53–66)
- Modify: `docs/plans/2026-08-12-road-to-beta.md` (§1 table, G-15 row)
- Modify: `docs/STATUS.md` (append to the dated backend-only-scope entry started for G-03, under
  `"### 2026-08-13 — the road to beta: ..."`)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing code-facing — bookkeeping, matching the pattern used to close G-03 and G-16.

- [ ] **Step 1: Note the new case in `03b`**

In `docs/03b-ARCHITECTURE.md`, after the bullet ending "...Rendering cannot change a result, and a
test asserts it." (the last bullet in §2, just before the `---` at line 66), add:

```markdown
- A failed `WorldScheduler.advanceWeek` exposes what already committed before the failure —
  `WorldSchedulerError.interrupted(committedSteps:committedEvents:underlying:)` — so a caller can
  report a truthful partial-completion state rather than a bare failure. No partial `GameState` is
  ever exposed or persisted this way; only the record of which steps ran, added 2026-08-13 (G-15).
```

- [ ] **Step 2: Update the G-15 row**

In `docs/plans/2026-08-12-road-to-beta.md`, replace the G-15 row in §1's table:

```markdown
| G-15 | Partial-advance completion record | Not started | Truthful interrupted-state copy |
```

with:

```markdown
| G-15 | Partial-advance completion record | **Done (engine half), 2026-08-13.** `WorldSchedulerError.interrupted(committedSteps:committedEvents:underlying:)` — every one of `advanceWeek`'s ~24 existing throw sites is untouched; the whole function body is wrapped in one `do/catch` that re-throws with whatever `records`/`events` had accumulated. No partial `GameState` is ever exposed. `CoachWorldStore`/`CoachWorldAppRootView` wiring and the `InterruptedState` view are UI work, out of scope for this pass | Truthful interrupted-state copy |
```

- [ ] **Step 3: Append to STATUS.md**

Read `docs/STATUS.md` first to find the paragraph appended for G-03 (search for "G-03 — bounded
per-player attribute-change record"), then append a new paragraph immediately after it, in the same
style, stating: `WorldSchedulerError.interrupted` exists; the wrapping is a single `do/catch` around
`advanceWeek`'s existing body with zero changes to any of the ~24 individual throw sites; the one
existing test that compared a thrown error by exact case (`EventLedgerBatchTests.swift`) was updated
and now asserts on the richer shape; a new test in `ArchitectureTests.swift`'s `"World scheduler"`
suite asserts `committedSteps` is a genuine prefix of the canonical step order and strictly shorter
than the full 15 under an induced failure; full suite re-run green; UI wiring
(`CoachWorldStore`/`CoachWorldAppRootView`/`InterruptedState` view) is explicitly out of scope for
this pass.

- [ ] **Step 4: Commit**

```bash
git add docs/03b-ARCHITECTURE.md docs/plans/2026-08-12-road-to-beta.md docs/STATUS.md
git commit -m "docs: close G-15's backend half in the road-to-beta register"
```

---

## Self-Review

**1. Spec coverage.**
- "A completion record on the advance boundary (which steps committed, which did not), exposed
  read-only" → `WorldSchedulerError.interrupted(committedSteps:committedEvents:underlying:)`, an
  immutable associated value on a thrown `Error` — inherently read-only, there is no mutating API on
  it. Task 1 Step 3–4.
- "Cost: small, bounded to the current advance" → `committedSteps`/`committedEvents` are exactly the
  `records`/`events` already accumulated for *this one* `advanceWeek` call; nothing is retained
  beyond the single throw, no new persisted state, no cross-week growth.
- "Test: record matches committed state after induced interruption" → Task 1 Step 1's new test,
  using the same induced-interruption technique the codebase already trusts.
- Owner doc `03b` (session/read-model boundary) → Task 2 Step 1's amendment to §2.

**2. Placeholder scan.** No "TBD"/"handle edge cases". The one place that says "read the file first"
(confirming `ledgerEvent`'s exact signature before Task 1 Step 1's test compiles) is a legitimate
"verify before relying on it" instruction, not a placeholder — the alternative would be guessing a
signature that might not match, which is worse.

**3. Type consistency.** `WorldSchedulerError.interrupted` is defined once (Task 1 Step 3) with
exactly the fields `committedSteps: [WorldStepRecord], committedEvents: [DomainEvent], underlying:
WorldSchedulerError`, and every later reference (both tests, the `03b` prose, the road-to-beta row)
uses that same three-field shape and those same names. `advanceWeek`'s signature
(`public static func advanceWeek(_ state: GameState) throws -> WorldTransition`) is stated as
unchanged in the Architecture summary and never contradicted in any task.

**4. Does any task risk silently swallowing an error, or changing observable behavior on the success
path?**
- **Silent swallowing: no.** The new `catch` re-throws unconditionally — `catch let error as
  WorldSchedulerError { throw WorldSchedulerError.interrupted(...) }` — every error that used to
  propagate still propagates, now carrying strictly more information (the original error is preserved
  verbatim as `underlying`), never less. A caller that only checks "did this throw" sees identical
  behavior to today; a caller that inspects the specific case sees a richer one. The only existing
  caller that did the latter (`EventLedgerBatchTests.swift:270`) is updated in the same task that
  introduces the change, not left broken.
- **Success-path behavior: no change.** The `do` block's success path is the exact original body,
  character for character (Task 1 Step 4's instruction is explicit about copying rather than
  retyping) — same loop, same steps, same `return WorldTransition(...)`. The existing tests "one week
  advances through the scheduler truthfully" and "equal states advance to byte-identical states and
  snapshots" (`ArchitectureTests.swift`, already in the suite, unmodified by this plan) continue to
  exercise that exact path and continue passing unchanged — that is the proof this plan relies on
  rather than adding a redundant new happy-path test.
