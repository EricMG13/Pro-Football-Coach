# G-03: Bounded Per-Player Attribute-Change Record — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every active player a bounded, queryable record of their last 6 attribute changes
(attribute, delta, cause, when), so `DeltaMark` and Player Profile can eventually show "what
changed" without inventing data — closing gap G-03.

**Architecture:** `PlayerLifecycleState` already receives a `DevelopmentSummary` on every
development event via `recordDevelopment(_:)`, but only keeps the most recent one
(`lastDevelopment`). Add a second, additive field — `recentChanges: [AttributeChangeRecord]` — that
`recordDevelopment(_:)` *appends* to (bounded, oldest evicted first) instead of overwriting. The
"cause" of a change is derived from data already present on the summary (`components`), so no call
site changes and no new parameter. Departure already deletes the whole `PlayerLifecycleState` via
`PeopleState.archive(player:status:)`, so "discarded on departure" needs no new code — only a test
proving it.

**Tech Stack:** Swift 6.0, SwiftPM, hand-rolled `TestKit` (`suite`/`test`/`expect`/`expectEqual`) —
no XCTest. `Sources/FootballSimCore/` only; this pass does not touch `Sources/CoachWorldApp/` or
`Sources/ProFootballCoachUI/`.

## Global Constraints

- Engine code only — zero `import SwiftUI` anywhere touched by this plan (`CLAUDE.md`).
- Ratings/deltas are bounded `Int`; no floating-point currency or rating (`CLAUDE.md`).
- Rules constants live in `Sources/FootballSimCore/Rules/` — never inline a magic number
  (`CLAUDE.md`; `PeopleRules.swift` is the file for this domain).
- Every collection that can grow across seasons has a stated bound (`CLAUDE.md`) — this plan's bound
  is **6 entries per player**, from `docs/briefs/2026-08-12-gap-register.md` G-03.
- TDD for all engine code: a failing test before the code that makes it pass (`CLAUDE.md`).
- Doc-first amendment rule: the "cause" derivation is a gameplay rule, so it is written into
  `docs/02-GAME-DESIGN.md` §5 before/alongside the code that implements it, not left implicit in
  code (`CLAUDE.md`).
- No unrequested read-model or UI wiring in this pass — `Sources/CoachWorldApp/` and
  `Sources/ProFootballCoachUI/` are out of scope (current session direction: backend only).

---

## Impact analysis (already run this session)

`mcp__gitnexus__impact` on `PlayerLifecycleState` (upstream): **CRITICAL, 76 impacted** — it is a
core `Codable` struct with call sites across `People`, `College`, `Career`, `Competition`, `Model`,
`Tactical`, `Generation` and 16 test suites. The change here is **purely additive**: one new stored
property with a default value (`recentChanges: [AttributeChangeRecord] = []`) and one new type. No
existing call site changes its arguments or return type, so none of the 76 impacted symbols require
edits — they keep compiling against the same public surface.

`mcp__gitnexus__impact` on `recordDevelopment` (upstream): graph reports 0 (a resolution artifact —
manual read of `Sources/FootballSimCore/People/DevelopmentSystem.swift` confirms 3 call sites, at
lines 50, 67 and 81 of `practice(at:in:tactical:)`). This plan does not change
`recordDevelopment`'s signature, so all 3 keep compiling unchanged.

---

### Task 1: `AttributeChangeRecord` type and bounded, appending `recordDevelopment`

**Files:**
- Modify: `Sources/FootballSimCore/People/PeopleState.swift` (add `AttributeChangeRecord` after
  `AttributeDevelopment`, at line 133; add `recentChanges` to `PlayerLifecycleState`, lines 184–256)
- Modify: `Sources/FootballSimCore/Rules/PeopleRules.swift:11` (add
  `recentChangeHistoryLimit` beside `maximumAttributeChangesPerSummary`)
- Test: `Tests/SimTests/Suites/PeopleLifecycleTests.swift` (existing suite `"People lifecycle
  state"`, add tests inside it)

**Interfaces:**
- Consumes: `CalendarState` (existing type, has a parameterless `init()` used throughout this test
  file), `Attribute` (existing enum, e.g. `.speed`), `DevelopmentReason` (existing enum:
  `.ageCurve, .practice, .playingTime, .coaching, .schemeFit, .workEthic, .decline,
  .injuryRecovery`), `PeopleRules.attributeDevelopmentRange` (existing `ClosedRange<Int>`, `-1...1`),
  `DevelopmentComponent(reason:value:)`, `DevelopmentSummary(occurredAt:components:attributeChanges:)`,
  `AttributeDevelopment(attribute:delta:)` — all existing, unchanged.
- Produces:
  - `public struct AttributeChangeRecord: Codable, Sendable, Equatable` with stored properties
    `occurredAt: CalendarState`, `attribute: Attribute`, `delta: Int`, `cause: DevelopmentReason`,
    and `public init(occurredAt:attribute:delta:cause:)`.
  - `PlayerLifecycleState.recentChanges: [AttributeChangeRecord]` (read-only outside the type,
    `public private(set) var`).
  - `PeopleRules.recentChangeHistoryLimit: Int` = `6`.
  - `recordDevelopment(_:)` keeps its existing signature
    `public mutating func recordDevelopment(_ summary: DevelopmentSummary)` and now also appends to
    `recentChanges`, bounded to `PeopleRules.recentChangeHistoryLimit`, oldest evicted first.

- [ ] **Step 1: Write the failing tests**

Open `Tests/SimTests/Suites/PeopleLifecycleTests.swift`. Find the closing brace of the
`"People lifecycle state"` suite (the `suite("People lifecycle state") { ... }` block — the last
test in it today is `"persisted people subrecords reject impossible values"`, ending around line
100–110; confirm the exact end of the suite block by reading the file, then insert the new tests as
additional `test(...)` calls immediately before that suite's closing `}`). Add:

```swift
        test("a development event with a real attribute change appends a recentChanges entry") {
            var lifecycle = PlayerLifecycleState(
                playerID: UUID(uuidString: "00000000-0000-4000-8000-000000008101")!
            )
            let calendar = CalendarState(season: 2, week: 8)
            let components = [
                DevelopmentComponent(reason: .ageCurve, value: 2),
                DevelopmentComponent(reason: .practice, value: 1),
                DevelopmentComponent(reason: .playingTime, value: 1),
                DevelopmentComponent(reason: .coaching, value: 0),
                DevelopmentComponent(reason: .schemeFit, value: 0),
                DevelopmentComponent(reason: .workEthic, value: 0),
            ]
            let summary = DevelopmentSummary(
                occurredAt: calendar,
                components: components,
                attributeChanges: [AttributeDevelopment(attribute: .speed, delta: 1)]
            )

            lifecycle.recordDevelopment(summary)

            expectEqual(lifecycle.recentChanges.count, 1)
            expectEqual(lifecycle.recentChanges.last?.attribute, .speed)
            expectEqual(lifecycle.recentChanges.last?.delta, 1)
            expectEqual(lifecycle.recentChanges.last?.cause, .ageCurve)
            expectEqual(lifecycle.recentChanges.last?.occurredAt, calendar)
        }

        test("recentChanges is bounded to 6 and evicts the oldest first") {
            var lifecycle = PlayerLifecycleState(
                playerID: UUID(uuidString: "00000000-0000-4000-8000-000000008102")!
            )
            let dominant = [DevelopmentComponent(reason: .practice, value: 2)]

            for week in 1...7 {
                let summary = DevelopmentSummary(
                    occurredAt: CalendarState(season: 1, week: week),
                    components: dominant,
                    attributeChanges: [AttributeDevelopment(attribute: .speed, delta: 1)]
                )
                lifecycle.recordDevelopment(summary)
            }

            expectEqual(lifecycle.recentChanges.count, PeopleRules.recentChangeHistoryLimit)
            expectEqual(lifecycle.recentChanges.first?.occurredAt, CalendarState(season: 1, week: 2))
            expectEqual(lifecycle.recentChanges.last?.occurredAt, CalendarState(season: 1, week: 7))
        }

        test("a development event with no attribute change leaves recentChanges untouched") {
            var lifecycle = PlayerLifecycleState(
                playerID: UUID(uuidString: "00000000-0000-4000-8000-000000008103")!
            )
            let summary = DevelopmentSummary(
                occurredAt: CalendarState(season: 3, week: 16),
                components: [DevelopmentComponent(reason: .decline, value: -1)],
                attributeChanges: []
            )

            lifecycle.recordDevelopment(summary)

            expect(lifecycle.recentChanges.isEmpty)
            expect(lifecycle.lastDevelopment != nil)
        }

        test("persisted recentChanges over the bound of 6 is rejected") {
            let lifecycle = PlayerLifecycleState(
                playerID: UUID(uuidString: "00000000-0000-4000-8000-000000008104")!
            )
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(lifecycle)
            ) as! [String: Any]
            let oneChange = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(AttributeChangeRecord(
                    occurredAt: CalendarState(season: 1, week: 1),
                    attribute: .speed,
                    delta: 1,
                    cause: .practice
                ))
            ) as! [String: Any]
            object["recentChanges"] = Array(repeating: oneChange, count: 7)
            let corrupted = try JSONSerialization.data(withJSONObject: object)

            do {
                _ = try JSONDecoder().decode(PlayerLifecycleState.self, from: corrupted)
                expect(false, "a recentChanges array over its bound decoded")
            } catch {
                expect(true)
            }
        }

        test("archiving a player discards recentChanges with the rest of the lifecycle state") {
            var state = PeopleState()
            let player = Player(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000008105")!,
                firstName: "Test",
                lastName: "Player",
                position: .quarterback,
                age: 22,
                attributes: Attributes(),
                potential: Rating(60)
            )
            state.insert(player: player)
            state.updatePlayerLifecycle(player.id) { lifecycle in
                lifecycle.recordDevelopment(DevelopmentSummary(
                    occurredAt: CalendarState(season: 1, week: 8),
                    components: [DevelopmentComponent(reason: .practice, value: 2)],
                    attributeChanges: [AttributeDevelopment(attribute: .speed, delta: 1)]
                ))
            }
            expectEqual(state.playerLifecycle[player.id]?.recentChanges.count, 1)

            state.archive(player: player, status: .retired)

            expect(state.playerLifecycle[player.id] == nil)
            expect(state.departedPlayers[player.id] != nil)
        }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift run -c release SimTests --people-lifecycle`
Expected: build FAILS — `AttributeChangeRecord` does not exist, `recentChanges` is not a member of
`PlayerLifecycleState`, `PeopleRules.recentChangeHistoryLimit` does not exist. (A compile failure is
the correct "red" for a brand-new type/property in a compiled language — there is no way to reach a
runtime failure yet.)

- [ ] **Step 3: Add the rules constant**

In `Sources/FootballSimCore/Rules/PeopleRules.swift`, after line 11
(`public static let maximumAttributeChangesPerSummary = 16`), add:

```swift
    public static let recentChangeHistoryLimit = 6
```

- [ ] **Step 4: Add `AttributeChangeRecord`**

In `Sources/FootballSimCore/People/PeopleState.swift`, immediately after the closing brace of
`AttributeDevelopment` (after line 132, before `public struct DevelopmentSummary`), insert:

```swift
public struct AttributeChangeRecord: Codable, Sendable, Equatable {
    public let occurredAt: CalendarState
    public let attribute: Attribute
    public let delta: Int
    public let cause: DevelopmentReason

    public init(
        occurredAt: CalendarState,
        attribute: Attribute,
        delta: Int,
        cause: DevelopmentReason
    ) {
        self.occurredAt = occurredAt
        self.attribute = attribute
        self.delta = delta
        self.cause = cause
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDelta = try container.decode(Int.self, forKey: .delta)
        guard PeopleRules.attributeDevelopmentRange.contains(decodedDelta),
              decodedDelta != 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .delta,
                in: container,
                debugDescription: "Attribute change record delta is outside its legal range."
            )
        }
        self.init(
            occurredAt: try container.decode(CalendarState.self, forKey: .occurredAt),
            attribute: try container.decode(Attribute.self, forKey: .attribute),
            delta: decodedDelta,
            cause: try container.decode(DevelopmentReason.self, forKey: .cause)
        )
    }
}
```

This mirrors `AttributeDevelopment`'s own `init(from:)` exactly (same range check, same
`dataCorruptedError` pattern), plus `occurredAt` and `cause`.

- [ ] **Step 5: Add `recentChanges` to `PlayerLifecycleState`**

In the same file, `PlayerLifecycleState` (starting at line 184). Add the stored property after
`lastDevelopment` (line 190):

```swift
    public private(set) var lastDevelopment: DevelopmentSummary?
    public private(set) var recentChanges: [AttributeChangeRecord]
```

Update the designated initializer (lines 192–205) to accept and bound it:

```swift
    public init(
        playerID: UUID,
        fatigue: Int = 0,
        injury: PlayerInjury? = nil,
        status: PlayerLifecycleStatus = .active,
        lastDevelopment: DevelopmentSummary? = nil,
        recentChanges: [AttributeChangeRecord] = []
    ) {
        self.playerID = playerID
        self.fatigue = min(max(fatigue, PeopleRules.fatigueRange.lowerBound),
                           PeopleRules.fatigueRange.upperBound)
        self.injury = injury
        self.status = status
        self.lastDevelopment = lastDevelopment
        self.recentChanges = Array(recentChanges.suffix(PeopleRules.recentChangeHistoryLimit))
    }
```

Update `init(from decoder:)` (lines 207–227) to decode and validate it — add the guard clause and
pass it through:

```swift
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedFatigue = try container.decode(Int.self, forKey: .fatigue)
        guard PeopleRules.fatigueRange.contains(decodedFatigue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .fatigue,
                in: container,
                debugDescription: "Player fatigue is outside its legal range."
            )
        }
        let decodedRecentChanges = try container.decode(
            [AttributeChangeRecord].self,
            forKey: .recentChanges
        )
        guard decodedRecentChanges.count <= PeopleRules.recentChangeHistoryLimit else {
            throw DecodingError.dataCorruptedError(
                forKey: .recentChanges,
                in: container,
                debugDescription: "Recent attribute change record exceeds its bound."
            )
        }
        self.init(
            playerID: try container.decode(UUID.self, forKey: .playerID),
            fatigue: decodedFatigue,
            injury: try container.decodeIfPresent(PlayerInjury.self, forKey: .injury),
            status: try container.decode(PlayerLifecycleStatus.self, forKey: .status),
            lastDevelopment: try container.decodeIfPresent(
                DevelopmentSummary.self,
                forKey: .lastDevelopment
            ),
            recentChanges: decodedRecentChanges
        )
    }
```

Update `recordDevelopment(_:)` (lines 254–256) to append instead of only overwrite `lastDevelopment`:

```swift
    public mutating func recordDevelopment(_ summary: DevelopmentSummary) {
        lastDevelopment = summary
        guard !summary.attributeChanges.isEmpty else { return }
        var dominant = summary.components.first
        for component in summary.components where abs(component.value) > abs(dominant?.value ?? 0) {
            dominant = component
        }
        guard let cause = dominant?.reason else { return }
        let appended = recentChanges + summary.attributeChanges.map {
            AttributeChangeRecord(
                occurredAt: summary.occurredAt,
                attribute: $0.attribute,
                delta: $0.delta,
                cause: cause
            )
        }
        recentChanges = Array(appended.suffix(PeopleRules.recentChangeHistoryLimit))
    }
```

(The `for component in summary.components where abs(...) > abs(...)` loop only replaces `dominant`
on a strictly greater magnitude, so on a tie the first component in the fixed array order —
age/decline, practice, playingTime, coaching, schemeFit, workEthic — wins, matching the canon rule
Task 2 writes into `02` §5.)

- [ ] **Step 6: Run tests to verify they pass**

Run: `swift run -c release SimTests --people-lifecycle`
Expected: `"People lifecycle state"` suite reports all tests passing, including the 5 new ones.

- [ ] **Step 7: Run the full suite to check for regressions**

Run: `swift run -c release SimTests`
Expected: every suite passes, same or higher total test/check count than before this change (no
suite newly fails). `PlayerLifecycleState`'s Equatable/Codable synthesis and the save-envelope
round-trip test (`"people state survives the save envelope byte-identically"`,
`PeopleLifecycleTests.swift:18`) exercise the new field automatically — watch that one specifically
in the output.

- [ ] **Step 8: Commit**

```bash
git add Sources/FootballSimCore/People/PeopleState.swift \
        Sources/FootballSimCore/Rules/PeopleRules.swift \
        Tests/SimTests/Suites/PeopleLifecycleTests.swift
git commit -m "feat: record a bounded per-player attribute-change history (G-03)"
```

---

### Task 2: Canon amendment — what "cause" means

**Files:**
- Modify: `docs/02-GAME-DESIGN.md` (§5, "Ratings, progression, development", lines 330–342)

**Interfaces:**
- Consumes: nothing new — this documents the rule Task 1 already implements
  (`recordDevelopment`'s dominant-component derivation).
- Produces: nothing code-facing; this is the canon record the doc-first rule requires.

- [ ] **Step 1: Add the amendment**

In `docs/02-GAME-DESIGN.md`, after the existing bullet ending "...top community complaint about the
reference title." (line 338) and before the `- **Decline** begins...` bullet (line 339), insert a
new bullet:

```markdown
- **Recorded changes.** Every development event that actually moves an attribute (a nonzero delta)
  is kept in a bounded per-player history of the last 6 changes — attribute, direction, cause and
  season/week — discarded when the player leaves the league. **Cause** is the single development
  factor (age curve, practice, playing time, coaching, scheme fit, work ethic) whose contribution had
  the largest magnitude that event; a tie is broken by that factor's fixed evaluation order (age
  curve or decline first, then practice, playing time, coaching, scheme fit, work ethic), so the
  record is always deterministic and reproducible from the same seed. This is a rules constant, not
  a per-screen judgement (`03b`) — added 2026-08-13, closing gap G-03.
```

- [ ] **Step 2: Commit**

```bash
git add docs/02-GAME-DESIGN.md
git commit -m "docs(canon): define attribute-change cause derivation for G-03"
```

---

### Task 3: Close out the gap register and status

**Files:**
- Modify: `docs/plans/2026-08-12-road-to-beta.md` (§1 table, G-03 row, line 50)
- Modify: `docs/STATUS.md` (append a dated entry; read the file first to find the correct place —
  it is appended-to throughout this rebuild, most recently under "2026-08-13 — the road to beta")

**Interfaces:**
- Consumes: nothing.
- Produces: nothing code-facing — this is bookkeeping so the next session does not re-discover work
  already done, matching how G-16's row was closed in the same table.

- [ ] **Step 1: Update the G-03 row**

In `docs/plans/2026-08-12-road-to-beta.md`, replace the G-03 row (line 50):

```markdown
| G-03 | Bounded per-player attribute-change record (bound: last 6, discarded on departure) | Not started | `DeltaMark`; Player Profile truthfulness |
```

with:

```markdown
| G-03 | Bounded per-player attribute-change record (bound: last 6, discarded on departure) | **Done, 2026-08-13.** `PlayerLifecycleState.recentChanges: [AttributeChangeRecord]`, appended by `recordDevelopment(_:)` and bounded to `PeopleRules.recentChangeHistoryLimit = 6`; cause is derived from the existing `DevelopmentSummary.components`, no new parameter. Departure was already handled — `PeopleState.archive` deletes the whole lifecycle record. Read-model wiring (`CoachWorldPersonnelProvider`) is untouched; this pass is engine-only | `DeltaMark`; Player Profile truthfulness |
```

- [ ] **Step 2: Append to STATUS.md**

Read `docs/STATUS.md` first to find its current end and dated-entry format, then append a new dated
entry following that format, stating: `PlayerLifecycleState.recentChanges` exists, bounded at 6,
tested (5 new tests: real-change append, 6-entry eviction, no-op on empty attributeChanges, decode
rejection over-bound, discard-on-archive), full suite re-run green, `docs/02-GAME-DESIGN.md` §5
amended to define "cause", and read-model/UI wiring for this data is explicitly out of scope for
this pass.

- [ ] **Step 3: Commit**

```bash
git add docs/plans/2026-08-12-road-to-beta.md docs/STATUS.md
git commit -m "docs: close G-03 in the road-to-beta register"
```

---

## Self-Review

**1. Spec coverage.**
- "last 6 recent attribute changes per active player (attribute, delta/direction, cause,
  season-week)" → `AttributeChangeRecord{occurredAt, attribute, delta, cause}`, Task 1 Step 4.
- "discarded on departure" → Task 1 Step 1's archive test proves this holds via existing
  `PeopleState.archive`, no new code needed; stated explicitly rather than assumed.
- "bound: last 6" → `PeopleRules.recentChangeHistoryLimit = 6`, enforced on both the mutating path
  (`.suffix(...)` in `recordDevelopment`) and the decode path (`guard decodedRecentChanges.count <=
  ...`), with a test for each (eviction test, decode-rejection test).
- "what counts as a change worth marking — a rules constant, not a per-screen judgement" (`02` §5
  per the gap register) → Task 2's canon amendment states the cause-derivation rule as a rules
  constant, matching `recordDevelopment`'s deterministic tie-break exactly.
- Blocks named in the register (`DeltaMark`; Player Profile truthfulness) are **not** closed by this
  plan — read-model wiring is explicitly deferred; Task 3's register update says so rather than
  overclaiming.

**2. Placeholder scan.** No "TBD"/"handle edge cases"/"similar to Task N" — every step shows the
real code or the real doc text; STATUS.md's exact insertion point is left to be found by reading the
file first (its dated-entry list has grown throughout the session and re-quoting a stale tail would
risk a bad diff), which is a legitimate "read then match the established format" instruction, not a
placeholder.

**3. Type consistency.** `AttributeChangeRecord` is defined once in Task 1 Step 4 with fields
`occurredAt: CalendarState, attribute: Attribute, delta: Int, cause: DevelopmentReason` and used
identically in every later test and in Task 2's prose. `PeopleRules.recentChangeHistoryLimit`
(Task 1 Step 3) is the only bound constant referenced anywhere (tests, `recordDevelopment`, the
decoder guard, the canon text). `recordDevelopment(_ summary: DevelopmentSummary)` keeps its exact
original signature throughout — no task changes it.
