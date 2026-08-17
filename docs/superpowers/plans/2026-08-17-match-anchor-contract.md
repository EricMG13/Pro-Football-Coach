# Match Anchor Contract and Animated 2D Match View Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Animate one recorded snap on the Match Day field, choreographed from a pure function of the already-resolved `PlayRecord`, closing G-06.

**Architecture:** A new engine type `SnapAnchors` turns a recorded `PlayRecord` into a sparse `SnapAnchorSet` — formation starts from a position template, movement ends from the identities the outcome already records, a ball polyline, the deciding matchup, and a VoiceOver sentence. The provider maps that into a new `MatchDayReadModel.playback`, applying offense direction. `MatchDayView` interpolates it under a `TimelineView` inside the `Canvas` that already draws the field.

**Tech Stack:** Swift 6.3.3, SwiftUI, SwiftPM. No third-party dependencies. Tests are the repo's own `TestKit` harness in `Tests/SimTests`, not XCTest.

**Spec:** `docs/superpowers/specs/2026-08-17-match-anchor-contract-design.md`

## Global Constraints

- **No invented movement.** `04` §9: "Route vectors appear only when the recorded read model supplies that route; decorative or invented movement is prohibited." Every anchor must trace to a field on `PlayRecord`.
- **Render cannot change simulation truth.** `03b` §2. `SnapAnchors` holds no reference to a resolver and takes no `inout` anything.
- **Pure and RNG-free.** No `SeededRandom`, no `Date()`, no `hashValue`. Determinism is byte-identical across processes.
- **No magic numbers.** Every geometric and timing constant lives in a named `enum` in the anchor rules, per `CLAUDE.md`.
- **Coverage boundary is not the quality boundary.** Tests that check a class of things enumerate that class by construction — drive from `SnapResult.allCases` and `Position.allCases`, never a hand-listed sample.
- **Engine has zero `import SwiftUI`.** `SnapAnchors.swift` imports `Foundation` only.
- **Coordinate space:** engine anchors are offense-relative, `yard` in `0...100` from the offence's own goal line, `lateral` in `0...1` across the field. The provider converts to the read model's absolute `0...120`.
- **No emoji** in code, copy, commits or docs.
- Ratings are `Int` 40–99; money is `Int`. Neither appears in this work, but the rule stands.
- **Commit format:** Conventional Commits, ending with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- **Staging:** another agent shares this branch and has staged changes in the index. **Always `git add` and `git commit` by explicit path.** Never `git add -A`, never a bare `git commit`.

## Build and test commands

Full suite:

```bash
swift build && swift run SimTests
```

One suite by flag (added in Task 5):

```bash
swift run SimTests --snap-anchors
```

---

### Task 1: Write the anchor contract into canon

`CLAUDE.md`'s doc-first amendment rule: the design decision goes into canon before it goes into code. `03` is the owner doc for G-06 per the gap register.

**Files:**
- Modify: `docs/03-MATCH-ENGINE.md` (append a new `## 9` before `## 8 Known gaps`, or after it — place it as the last numbered section and renumber nothing)
- Modify: `docs/04-UX-AND-DESIGN-SYSTEM.md:861-863` (the "once G-06 lands" caveat)

**Interfaces:**
- Consumes: nothing
- Produces: the canonical vocabulary every later task cites

- [ ] **Step 1: Append §9 to `docs/03-MATCH-ENGINE.md`**

Append this section at the end of the file:

```markdown
## 9. The anchor contract (G-06)

`04` §9 requires a match view that animates what the engine recorded and cannot invent movement.
This section is the engine half of that requirement: what an anchor set contains, what makes it
legal, and what it may never contradict.

### 9.1 What an anchor set is

A **sparse** spatial description of one already-resolved snap, derived from its `PlayRecord`. It
holds twenty-two actor anchors, a ball polyline, the deciding matchup, a foreground list, a
playback duration and an accessible sentence. It holds no probabilities, no resolution and no
route that the record does not justify.

Sparse is the operative word. Most actors on most snaps have a start and an end and nothing
between them, because the record says nothing more about them. A dense anchor set would have to be
invented, and `04` §9 forbids that.

### 9.2 Coordinate space

Anchors are **offense-relative**. `yard` runs 0 to 100 from the offence's own goal line, matching
`Situation.yardLine`. `lateral` runs 0 to 1 across the field.

The engine never learns which way the offence is facing. Direction is presentation, it is recorded
on the read model, and the provider applies it when converting to the drawn field's absolute 0-to-120
space. This is what gives `04` §9's "the view never guesses from home/away colour" exactly one
place to live.

### 9.3 Legality

An anchor set is legal when all of the following hold. Each is a test.

1. **Pure.** A function of the `PlayRecord` and the two player lists, with no random source, no
   clock and no engine reference. The same input yields a byte-identical encoding, in any process.
2. **Consistent with the box score.** `endSpot - lineOfScrimmage` equals `outcome.yards`. The
   carrier named in the ball polyline is `outcome.ballCarrierID`. An incompletion has no carry
   segment. A sack ends behind the line.
3. **Complete.** Given eleven players a side, exactly twenty-two actor anchors, and at most three
   foregrounded, per `04` §9.
4. **On the field.** Every point lies within the coordinate space of §9.2.
5. **Total.** Every `SnapResult` yields a legal set. There is no input a resolved snap can present
   that has no anchor set, so construction cannot fail.

### 9.4 Alignment

Per-snap alignment is not recorded, and recording it would be a calibration problem of its own. The
starts come from a fixed template keyed on `Position`, and the ends from the identities the outcome
already records — `passerID`, `targetID`, `ballCarrierID`, and the deciding matchup's two players.

`04` §9 permits this in terms: route-tree and formation notation are drawn conventions of the sport
and not protected expression. It continues to refuse any specific playbook's diagrams, and nothing
here reproduces one.

### 9.5 Bound

Nothing is persisted. An anchor set is derived on demand from a `PlayRecord` that the save already
holds under D7's current-game play-by-play bound, so G-06 adds no save growth at all.
```

- [ ] **Step 2: Update the `04` §9 caveat**

In `docs/04-UX-AND-DESIGN-SYSTEM.md`, replace this text at lines 861-863:

```
  §6.6 broadcast marks. Every fixed diagram mark carries §6.2's accessible-sentence equivalent. Until G-06
  supplies recorded routes, sheets and views draw play art in target form only, labelled "once
  G-06 lands".
```

with:

```
  §6.6 broadcast marks. Every fixed diagram mark carries §6.2's accessible-sentence equivalent.
  **G-06's anchor contract is `03` §9, added 2026-08-17.** Match Day draws play art from a recorded
  anchor set; alignment starts come from the §9.4 position template and movement ends from the
  identities the outcome records. Sheets that have not yet adopted the anchor set still draw play
  art in target form only.
```

- [ ] **Step 3: Verify the docs still state one thing**

Read back both edited regions. Confirm `03` §9.2's coordinate rule and `04` §9's direction sentence agree, and that neither now claims recorded per-snap alignment exists.

- [ ] **Step 4: Commit**

```bash
git add docs/03-MATCH-ENGINE.md docs/04-UX-AND-DESIGN-SYSTEM.md
git commit docs/03-MATCH-ENGINE.md docs/04-UX-AND-DESIGN-SYSTEM.md -m "$(cat <<'EOF'
docs: write the anchor contract into canon (G-06)

03 gains section 9: what an anchor set is, the offense-relative
coordinate space, the five legality clauses, why alignment comes from a
template, and the zero save bound.

04 section 9's "once G-06 lands" caveat now points at the contract
instead of deferring.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Anchor types and rules constants

**Files:**
- Create: `Sources/FootballSimCore/Engine/SnapAnchors.swift`
- Create: `Tests/SimTests/Suites/SnapAnchorTests.swift`

**Interfaces:**
- Consumes: `Side` (`Engine/Situation.swift`), `SnapRole` (`Engine/Assignment.swift`), `MatchupRecord` (`Engine/SnapOutcome.swift`)
- Produces: `FieldPoint`, `ActorAnchor`, `BallSegment`, `DecidingMark`, `SnapAnchorSet`, `AnchorRules`, and `runSnapAnchorTests()`

- [ ] **Step 1: Write the failing test**

Create `Tests/SimTests/Suites/SnapAnchorTests.swift`:

All three modules are imported up front, because Tasks 6 and 7 add tests to this same file that
need the UI read model and the provider. Importing them now avoids editing the header twice.

```swift
import Foundation
import FootballSimCore
import ProFootballCoachUI
import CoachWorldApp

func runSnapAnchorTests() {
    suite("Snap anchors") {
        test("a field point clamps into the coordinate space of 03 section 9.2") {
            expectEqual(FieldPoint(yard: -12, lateral: 4).yard, 0)
            expectEqual(FieldPoint(yard: 180, lateral: -1).yard, 100)
            expectEqual(FieldPoint(yard: 50, lateral: -1).lateral, 0)
            expectEqual(FieldPoint(yard: 50, lateral: 9).lateral, 1)
            expectEqual(FieldPoint(yard: 40, lateral: 0.25).yard, 40)
            expectEqual(FieldPoint(yard: 40, lateral: 0.25).lateral, 0.25)
        }

        test("playback duration constants leave a snap watchable") {
            expect(AnchorRules.minimumPlaybackSeconds > 0,
                   "a zero-length playback is not a playback")
            expect(AnchorRules.maximumPlaybackSeconds > AnchorRules.minimumPlaybackSeconds,
                   "the playback ceiling must sit above its floor")
            expect(AnchorRules.clockToPlaybackRatio > 0 && AnchorRules.clockToPlaybackRatio <= 1,
                   "playback may compress clock time but never stretch it")
        }
    }
}
```

- [ ] **Step 2: Run it to make sure it fails**

Add the call to `Tests/SimTests/main.swift`'s final `else` block (after `runSnapResolverTests()`), then:

```bash
swift build 2>&1 | head -20
```

Expected: FAIL, `cannot find 'FieldPoint' in scope`.

- [ ] **Step 3: Write the minimal implementation**

Create `Sources/FootballSimCore/Engine/SnapAnchors.swift`:

```swift
import Foundation

/// Where something is, in the space `03` section 9.2 defines.
///
/// Offense-relative on purpose. `yard` matches `Situation.yardLine` so the two never need a
/// conversion inside the engine, and the engine never learns which way the offence faces — that is
/// presentation, and the provider owns it.
public struct FieldPoint: Codable, Sendable, Equatable {
    /// 0 to 100, from the offence's own goal line.
    public let yard: Double
    /// 0 to 1, across the field.
    public let lateral: Double

    /// Clamping in the initialiser rather than validating at the boundary is what lets
    /// `SnapAnchors.choreograph` stay total: there is no point it can be handed that it must reject.
    public init(yard: Double, lateral: Double) {
        self.yard = Swift.min(100, Swift.max(0, yard))
        self.lateral = Swift.min(1, Swift.max(0, lateral))
    }
}

/// One player's movement across one snap.
public struct ActorAnchor: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let side: Side
    public let role: SnapRole
    public let start: FieldPoint
    public let end: FieldPoint
    /// Sparse by design, and empty for most actors on most snaps. A point appears here only when
    /// the record justifies it; see `03` section 9.1.
    public let path: [FieldPoint]

    public init(
        playerID: UUID,
        side: Side,
        role: SnapRole,
        start: FieldPoint,
        end: FieldPoint,
        path: [FieldPoint] = []
    ) {
        self.playerID = playerID
        self.side = side
        self.role = role
        self.start = start
        self.end = end
        self.path = path
    }
}

/// One leg of the ball's journey, with when it happens as a fraction of the playback.
public struct BallSegment: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case snap, carry, air, loose
    }

    public let kind: Kind
    public let from: FieldPoint
    public let to: FieldPoint
    public let startFraction: Double
    public let endFraction: Double

    public init(
        kind: Kind,
        from: FieldPoint,
        to: FieldPoint,
        startFraction: Double,
        endFraction: Double
    ) {
        self.kind = kind
        self.from = from
        self.to = to
        self.startFraction = Swift.min(1, Swift.max(0, startFraction))
        self.endFraction = Swift.min(1, Swift.max(0, endFraction))
    }
}

/// The duel that decided the snap, carried through so the view can draw a sack as the protection
/// duel that lost rather than as a generic event. This is the point of D2.
public struct DecidingMark: Codable, Sendable, Equatable {
    public let kind: MatchupRecord.Kind
    public let attackerID: UUID
    public let defenderID: UUID
    public let attackerWon: Bool

    public init(kind: MatchupRecord.Kind, attackerID: UUID, defenderID: UUID, attackerWon: Bool) {
        self.kind = kind
        self.attackerID = attackerID
        self.defenderID = defenderID
        self.attackerWon = attackerWon
    }
}

/// Everything the view needs to animate one recorded snap, and nothing it could use to change one.
public struct SnapAnchorSet: Codable, Sendable, Equatable {
    public let lineOfScrimmage: Double
    public let firstDownLine: Double
    public let endSpot: Double
    public let actors: [ActorAnchor]
    public let ball: [BallSegment]
    public let deciding: DecidingMark?
    /// At most three, per `04` section 9. Held to that by construction in `choreograph`.
    public let foregroundIDs: [UUID]
    public let durationSeconds: Double
    /// The VoiceOver equivalent P13 requires for every snap.
    public let sentence: String

    public init(
        lineOfScrimmage: Double,
        firstDownLine: Double,
        endSpot: Double,
        actors: [ActorAnchor],
        ball: [BallSegment],
        deciding: DecidingMark?,
        foregroundIDs: [UUID],
        durationSeconds: Double,
        sentence: String
    ) {
        self.lineOfScrimmage = lineOfScrimmage
        self.firstDownLine = firstDownLine
        self.endSpot = endSpot
        self.actors = actors
        self.ball = ball
        self.deciding = deciding
        self.foregroundIDs = foregroundIDs
        self.durationSeconds = durationSeconds
        self.sentence = sentence
    }
}

/// Geometry and timing constants for the anchor contract.
///
/// These are rules constants and they live here rather than inline, for the reason `CLAUDE.md`
/// gives: a magic number in a view is a value nothing can test and nobody can find.
public enum AnchorRules {
    // MARK: Playback timing

    public static let minimumPlaybackSeconds = 1.6
    public static let maximumPlaybackSeconds = 6.0
    /// Playback compresses clock time. A snap that burned 40 seconds does not animate for 40.
    public static let clockToPlaybackRatio = 0.55

    /// The ball leaves the centre over this share of the playback.
    public static let snapFraction = 0.12
    /// A pass is in the air until this point of the playback.
    public static let releaseFraction = 0.55

    // MARK: Alignment, offense

    public static let lineLaterals: [Double] = [0.38, 0.44, 0.50, 0.56, 0.62]
    public static let centerLateral = 0.50
    public static let passerDepth = 5.0
    public static let backDepth = 6.0
    public static let backLateral = 0.44
    public static let tightEndLateral = 0.68
    public static let receiverLaterals: [Double] = [0.12, 0.88, 0.26, 0.74]

    // MARK: Alignment, defense

    public static let frontDepth = 1.0
    public static let edgeLaterals: [Double] = [0.34, 0.66]
    public static let interiorLaterals: [Double] = [0.46, 0.54]
    public static let linebackerDepth = 5.0
    public static let linebackerLaterals: [Double] = [0.36, 0.50, 0.64]
    public static let cornerDepth = 7.0
    public static let cornerLaterals: [Double] = [0.12, 0.88]
    public static let safetyDepth = 13.0
    public static let safetyLaterals: [Double] = [0.34, 0.66]

    // MARK: Movement

    /// How close a rusher gets to the passer when the duel is lost.
    public static let rusherClosingYards = 4.0
    /// How far a specialist stands off the formation.
    public static let specialistDepth = 8.0
    public static let maximumForegrounded = 3
}
```

- [ ] **Step 4: Run the tests and make sure they pass**

```bash
swift build && swift run SimTests --snap-anchors 2>&1 | tail -20
```

The flag does not exist yet, so run the full suite instead and grep:

```bash
swift build && swift run SimTests 2>&1 | grep -A 5 "Snap anchors"
```

Expected: the two tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift Tests/SimTests/main.swift
git commit Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift Tests/SimTests/main.swift -m "$(cat <<'EOF'
feat: add the anchor vocabulary and its rules constants

FieldPoint clamps in its initialiser rather than validating at a
boundary, which is what lets choreograph stay total later: there is no
point it can be handed that it has to reject.

Every geometric and timing value is a named constant in AnchorRules.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: The alignment template

**Files:**
- Modify: `Sources/FootballSimCore/Engine/SnapAnchors.swift`
- Modify: `Tests/SimTests/Suites/SnapAnchorTests.swift`

**Interfaces:**
- Consumes: `AnchorRules`, `FieldPoint`, `Position`, `Player`
- Produces: `SnapAnchors.alignment(for:index:side:lineOfScrimmage:) -> FieldPoint`

- [ ] **Step 1: Write the failing test**

Add inside the `suite("Snap anchors")` block in `Tests/SimTests/Suites/SnapAnchorTests.swift`:

```swift
test("every position aligns somewhere on the field") {
    // Enumerated from Position.allCases by construction, so a position added tomorrow fails
    // this the day it is added rather than the day someone remembers it.
    for position in Position.allCases {
        for side in Side.allCases {
            for index in 0..<4 {
                let point = SnapAnchors.alignment(
                    for: position, index: index, side: side, lineOfScrimmage: 40
                )
                expectIn(point.yard, 0...100, "\(position) aligned off the field")
                expectIn(point.lateral, 0...1, "\(position) aligned outside the sidelines")
            }
        }
    }
}

test("the offensive line stands on the line and the defence stands beyond it") {
    let los = 40.0
    let centre = SnapAnchors.alignment(for: .center, index: 0, side: .home, lineOfScrimmage: los)
    expectEqual(centre.yard, los, "the centre is on the line of scrimmage")
    expectEqual(centre.lateral, AnchorRules.centerLateral)

    let passer = SnapAnchors.alignment(for: .quarterback, index: 0, side: .home,
                                       lineOfScrimmage: los)
    expect(passer.yard < los, "the passer sets up behind the line")

    let edge = SnapAnchors.alignment(for: .edgeRusher, index: 0, side: .away,
                                     lineOfScrimmage: los)
    expect(edge.yard > los, "the defensive front lines up beyond the line of scrimmage")

    let safety = SnapAnchors.alignment(for: .safety, index: 0, side: .away, lineOfScrimmage: los)
    expect(safety.yard > edge.yard, "safeties play behind the front")
}

test("two players at the same position take different alignments") {
    let los = 40.0
    let first = SnapAnchors.alignment(for: .wideReceiver, index: 0, side: .home,
                                      lineOfScrimmage: los)
    let second = SnapAnchors.alignment(for: .wideReceiver, index: 1, side: .home,
                                       lineOfScrimmage: los)
    expect(first.lateral != second.lateral, "receivers stacked on one another")
}
```

- [ ] **Step 2: Run it to make sure it fails**

```bash
swift build 2>&1 | head -10
```

Expected: FAIL, `type 'SnapAnchors' has no member 'alignment'`.

- [ ] **Step 3: Write the minimal implementation**

Append to `Sources/FootballSimCore/Engine/SnapAnchors.swift`:

```swift
/// Turns a recorded snap into a sparse spatial description of it.
///
/// Pure, total and rng-free, per `03` section 9.3. It imports `Foundation` and nothing else, so it
/// cannot reach a resolver even by accident.
public enum SnapAnchors {
    /// Where a player of this position lines up.
    ///
    /// `03` section 9.4: per-snap alignment is not recorded, so the start comes from this template
    /// and only the *end* comes from what the outcome recorded. Keyed on position because that is
    /// how alignment actually works, and indexed so two receivers do not stack.
    public static func alignment(
        for position: Position,
        index: Int,
        side: Side,
        lineOfScrimmage: Double
    ) -> FieldPoint {
        let slot = Swift.max(0, index)
        func pick(_ options: [Double]) -> Double {
            options.isEmpty ? AnchorRules.centerLateral : options[slot % options.count]
        }

        switch position {
        case .leftTackle:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.lineLaterals[0])
        case .guardPosition:
            return FieldPoint(yard: lineOfScrimmage,
                              lateral: slot % 2 == 0 ? AnchorRules.lineLaterals[1]
                                                     : AnchorRules.lineLaterals[3])
        case .center:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.centerLateral)
        case .rightTackle:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.lineLaterals[4])
        case .quarterback:
            return FieldPoint(yard: lineOfScrimmage - AnchorRules.passerDepth,
                              lateral: AnchorRules.centerLateral)
        case .runningBack:
            return FieldPoint(yard: lineOfScrimmage - AnchorRules.backDepth,
                              lateral: AnchorRules.backLateral)
        case .tightEnd:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.tightEndLateral)
        case .wideReceiver:
            return FieldPoint(yard: lineOfScrimmage, lateral: pick(AnchorRules.receiverLaterals))
        case .edgeRusher:
            return FieldPoint(yard: lineOfScrimmage + AnchorRules.frontDepth,
                              lateral: pick(AnchorRules.edgeLaterals))
        case .defensiveTackle:
            return FieldPoint(yard: lineOfScrimmage + AnchorRules.frontDepth,
                              lateral: pick(AnchorRules.interiorLaterals))
        case .linebacker:
            return FieldPoint(yard: lineOfScrimmage + AnchorRules.linebackerDepth,
                              lateral: pick(AnchorRules.linebackerLaterals))
        case .cornerback:
            return FieldPoint(yard: lineOfScrimmage + AnchorRules.cornerDepth,
                              lateral: pick(AnchorRules.cornerLaterals))
        case .safety:
            return FieldPoint(yard: lineOfScrimmage + AnchorRules.safetyDepth,
                              lateral: pick(AnchorRules.safetyLaterals))
        case .kicker, .punter:
            let depth = side == .home ? -AnchorRules.specialistDepth : AnchorRules.specialistDepth
            return FieldPoint(yard: lineOfScrimmage + depth, lateral: AnchorRules.centerLateral)
        }
    }
}
```

- [ ] **Step 4: Run the tests and make sure they pass**

```bash
swift build && swift run SimTests 2>&1 | grep -A 8 "Snap anchors"
```

Expected: five tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift
git commit Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift -m "$(cat <<'EOF'
feat: add the alignment template

Keyed on position, because that is how alignment works, and indexed so
two receivers do not stack on one another.

The coverage test enumerates Position.allCases rather than a sample, so
a position added tomorrow fails on the day it is added.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Roles, and the sentence

**Files:**
- Modify: `Sources/FootballSimCore/Engine/SnapAnchors.swift`
- Modify: `Tests/SimTests/Suites/SnapAnchorTests.swift`

**Interfaces:**
- Consumes: `SnapOutcome`, `SnapRole`, `Position`
- Produces: `SnapAnchors.role(for:outcome:isOffense:) -> SnapRole`, `SnapAnchors.sentence(for:offense:defense:) -> String`

- [ ] **Step 1: Write the failing test**

Add inside the suite block:

```swift
test("roles come from what the outcome recorded, not from a guess") {
    let passer = UUID(uuidString: "00000000-0000-4000-8000-0000000000A1")!
    let target = UUID(uuidString: "00000000-0000-4000-8000-0000000000A2")!
    let carrier = UUID(uuidString: "00000000-0000-4000-8000-0000000000A3")!
    let outcome = SnapOutcome(
        result: .gain, yards: 8, secondsElapsed: 6, matchups: [],
        ballCarrierID: carrier, passerID: passer, targetID: target
    )
    expectEqual(SnapAnchors.role(for: passer, position: .quarterback, outcome: outcome,
                                isOffense: true), .passer)
    expectEqual(SnapAnchors.role(for: target, position: .wideReceiver, outcome: outcome,
                                isOffense: true), .routeRunner)
    expectEqual(SnapAnchors.role(for: carrier, position: .runningBack, outcome: outcome,
                                isOffense: true), .carrier)
    let other = UUID(uuidString: "00000000-0000-4000-8000-0000000000A4")!
    expectEqual(SnapAnchors.role(for: other, position: .leftTackle, outcome: outcome,
                                isOffense: true), .blocker)
    expectEqual(SnapAnchors.role(for: other, position: .edgeRusher, outcome: outcome,
                                isOffense: false), .rusher)
    expectEqual(SnapAnchors.role(for: other, position: .cornerback, outcome: outcome,
                                isOffense: false), .coverage)
    expectEqual(SnapAnchors.role(for: other, position: .linebacker, outcome: outcome,
                                isOffense: false), .runFit)
}

test("every result kind produces a non-empty accessible sentence") {
    // Driven from allCases: a new SnapResult that nobody wrote a sentence for fails here.
    let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
    for result in SnapResult.allCases {
        let outcome = SnapOutcome(
            result: result, yards: result == .sack ? -7 : 5, secondsElapsed: 6, matchups: []
        )
        let line = SnapAnchors.sentence(
            for: outcome, offense: personnel.offense, defense: personnel.defense
        )
        expect(!line.isEmpty, "\(result) produced no accessible sentence")
        expect(line.hasSuffix("."), "\(result)'s sentence is not a sentence: \(line)")
    }
}
```

- [ ] **Step 2: Run it to make sure it fails**

```bash
swift build 2>&1 | head -10
```

Expected: FAIL, `type 'SnapAnchors' has no member 'role'`.

- [ ] **Step 3: Write the minimal implementation**

Append inside `public enum SnapAnchors { ... }` in `Sources/FootballSimCore/Engine/SnapAnchors.swift`:

```swift
    /// What this player was doing, read off the outcome's recorded identities first and their
    /// position second.
    ///
    /// Deliberately does not call `Assignment.assign`. The three identities the outcome already
    /// records — passer, target, carrier — answer the question for everyone who mattered, and
    /// position answers it for everyone else. Reading the record is truthful; re-deriving the
    /// assignment would be a second opinion the view has no business forming.
    public static func role(
        for playerID: UUID,
        position: Position,
        outcome: SnapOutcome,
        isOffense: Bool
    ) -> SnapRole {
        if position == .kicker || position == .punter { return .kicker }
        if playerID == outcome.passerID { return .passer }
        if playerID == outcome.ballCarrierID { return .carrier }
        if playerID == outcome.targetID { return .routeRunner }
        if isOffense {
            switch position {
            case .leftTackle, .guardPosition, .center, .rightTackle: return .blocker
            case .wideReceiver, .tightEnd: return .routeRunner
            default: return .decoy
            }
        }
        switch position {
        case .edgeRusher, .defensiveTackle: return .rusher
        case .linebacker: return .runFit
        default: return .coverage
        }
    }

    /// The sentence a VoiceOver user hears instead of watching the snap.
    ///
    /// `04` section 9 requires an equivalent for every snap, and P13 requires it per snap rather
    /// than per drive.
    public static func sentence(
        for outcome: SnapOutcome,
        offense: [Player],
        defense: [Player]
    ) -> String {
        let distance = Swift.abs(outcome.yards)
        let yardWord = distance == 1 ? "yard" : "yards"
        let head: String
        switch outcome.result {
        case .gain:
            head = outcome.yards < 0
                ? "Stopped for a loss of \(distance) \(yardWord)"
                : "Gain of \(distance) \(yardWord)"
        case .incompletion: head = "Incomplete"
        case .sack: head = "Sacked for \(distance) \(yardWord)"
        case .interception: head = "Intercepted"
        case .fumbleLost: head = "Fumble lost"
        case .touchdown: head = "Touchdown, \(distance) \(yardWord)"
        case .fieldGoalGood: head = "Field goal is good"
        case .fieldGoalMissed: head = "Field goal is missed"
        case .punt: head = "Punt"
        case .safety: head = "Safety"
        case .kneel: head = "Kneel down"
        }

        guard let deciding = outcome.decidingMatchup else { return head + "." }
        let roster = offense + defense
        func name(_ id: UUID) -> String? {
            roster.first(where: { $0.id == id })?.lastName
        }
        let duel: String
        switch deciding.kind {
        case .passProtection: duel = "the protection duel"
        case .routeVersusCoverage: duel = "the route"
        case .throwing: duel = "the throw"
        case .runLane: duel = "the run lane"
        case .carrierVersusPursuit: duel = "the pursuit"
        case .kick: duel = "the kick"
        }
        let winner = deciding.attackerWon ? deciding.attackerID : deciding.defenderID
        guard let winnerName = name(winner) else { return head + "." }
        return "\(head). \(winnerName) won \(duel)."
    }
```

- [ ] **Step 4: Run the tests and make sure they pass**

```bash
swift build && swift run SimTests 2>&1 | grep -A 10 "Snap anchors"
```

Expected: seven tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift
git commit Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift -m "$(cat <<'EOF'
feat: derive snap roles and the accessible sentence

Roles read the outcome's recorded identities first and position second,
and deliberately do not call Assignment.assign. The three identities the
outcome already carries answer the question for everyone who mattered;
re-deriving the assignment would be a second opinion the view has no
business forming.

The sentence test enumerates SnapResult.allCases, so a new result kind
nobody wrote a sentence for fails on arrival.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: `choreograph`, and the legality tests

The heart of the contract. This task delivers `03` §9.3's five clauses as five tests.

**Files:**
- Modify: `Sources/FootballSimCore/Engine/SnapAnchors.swift`
- Modify: `Tests/SimTests/Suites/SnapAnchorTests.swift`
- Modify: `Tests/SimTests/main.swift` (add the `--snap-anchors` flag)

**Interfaces:**
- Consumes: `PlayRecord`, `SnapOutcome`, `OffensiveCall`, `Situation`, `Player`
- Produces: `SnapAnchors.choreograph(play:offense:defense:) -> SnapAnchorSet`

- [ ] **Step 1: Write the failing test**

Add inside the suite block:

```swift
test("an anchor set never contradicts the box score") {
    // 03 section 9.3 clause 2. Driven from allCases so no result kind escapes the check.
    let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
    for result in SnapResult.allCases {
        let yards = result == .sack ? -7 : 9
        let play = PlayRecord(
            situation: Situation(down: 2, distance: 10, yardLine: 40),
            offensiveCall: OffensiveCall(playType: result == .sack ? .pass : .run),
            defensiveCall: DefensiveCall(coverage: .man),
            outcome: SnapOutcome(result: result, yards: yards, secondsElapsed: 6, matchups: []),
            callInTriggers: []
        )
        let set = SnapAnchors.choreograph(
            play: play,
            offense: Array(personnel.offense.prefix(11)),
            defense: Array(personnel.defense.prefix(11))
        )
        expectEqual(set.endSpot - set.lineOfScrimmage, Double(yards),
                    "\(result) drew an end spot the box score does not agree with")
        if result == .sack {
            expect(set.endSpot < set.lineOfScrimmage, "a sack must end behind the line")
        }
        if result == .incompletion {
            expect(!set.ball.contains { $0.kind == .carry },
                   "an incompletion must have no carry segment")
        }
    }
}

test("an anchor set is complete and bounded") {
    // 03 section 9.3 clauses 3 and 4.
    let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
    for result in SnapResult.allCases {
        let play = PlayRecord(
            situation: Situation(down: 1, distance: 10, yardLine: 25),
            offensiveCall: OffensiveCall(playType: .pass),
            defensiveCall: DefensiveCall(coverage: .zoneUnder),
            outcome: SnapOutcome(result: result, yards: 4, secondsElapsed: 5, matchups: []),
            callInTriggers: []
        )
        let set = SnapAnchors.choreograph(
            play: play,
            offense: Array(personnel.offense.prefix(11)),
            defense: Array(personnel.defense.prefix(11))
        )
        expectEqual(set.actors.count, 22, "\(result) did not represent all 22 actors")
        expect(set.foregroundIDs.count <= AnchorRules.maximumForegrounded,
               "\(result) foregrounded more than three actors")
        expectEqual(Set(set.foregroundIDs).count, set.foregroundIDs.count,
                    "\(result) foregrounded the same actor twice")
        for actor in set.actors {
            expectIn(actor.start.yard, 0...100, "\(result) started an actor off the field")
            expectIn(actor.end.yard, 0...100, "\(result) ended an actor off the field")
        }
        for segment in set.ball {
            expectIn(segment.startFraction, 0...1, "\(result) has a ball segment outside playback")
            expectIn(segment.endFraction, 0...1, "\(result) has a ball segment outside playback")
        }
        expectIn(set.durationSeconds,
                 AnchorRules.minimumPlaybackSeconds...AnchorRules.maximumPlaybackSeconds,
                 "\(result) produced an unwatchable duration")
    }
}

test("the same record encodes byte-identically twice") {
    // 03 section 9.3 clause 1. This is the determinism the gap register asks for by name.
    let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
    let play = PlayRecord(
        situation: Situation(down: 3, distance: 7, yardLine: 62),
        offensiveCall: OffensiveCall(playType: .pass, passDepth: .deep),
        defensiveCall: DefensiveCall(coverage: .zoneDeep),
        outcome: SnapOutcome(
            result: .gain, yards: 21, secondsElapsed: 7, matchups: [],
            ballCarrierID: personnel.offense[2].id,
            passerID: personnel.offense[0].id,
            targetID: personnel.offense[2].id
        ),
        callInTriggers: []
    )
    func encodeOnce() -> Data {
        let set = SnapAnchors.choreograph(
            play: play,
            offense: Array(personnel.offense.prefix(11)),
            defense: Array(personnel.defense.prefix(11))
        )
        return try! JSONEncoder.stable().encode(set)
    }
    expectEqual(encodeOnce(), encodeOnce(), "choreography is not byte-identical across renders")
}

test("choreographing a snap cannot change what the snap was") {
    // 03 section 9.3, and P13's named render-cannot-change-outcome gate.
    let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
    let rules = Tier.pro.clockRules
    func resolveOnce() -> SnapOutcome {
        var rng = SeededRandom(seed: 4242)
        return SnapResolver.resolve(
            offensiveCall: OffensiveCall(playType: .pass),
            defensiveCall: DefensiveCall(coverage: .man),
            personnel: personnel, situation: Situation(), rules: rules, rng: &rng
        )
    }
    let before = resolveOnce()
    let play = PlayRecord(
        situation: Situation(),
        offensiveCall: OffensiveCall(playType: .pass),
        defensiveCall: DefensiveCall(coverage: .man),
        outcome: before,
        callInTriggers: []
    )
    _ = SnapAnchors.choreograph(
        play: play,
        offense: Array(personnel.offense.prefix(11)),
        defense: Array(personnel.defense.prefix(11))
    )
    expectEqual(resolveOnce(), before, "choreography perturbed the simulation")
}
```

- [ ] **Step 2: Run it to make sure it fails**

```bash
swift build 2>&1 | head -10
```

Expected: FAIL, `type 'SnapAnchors' has no member 'choreograph'`.

- [ ] **Step 3: Write the minimal implementation**

Append inside `public enum SnapAnchors { ... }`:

```swift
    /// Turns one recorded snap into its anchor set.
    ///
    /// Total by construction: every branch below terminates in a set, so there is no resolved snap
    /// that has no choreography. `03` section 9.3 clause 5.
    ///
    /// The caller supplies the eleven on the field for each side. `MatchSessionState` holds more
    /// than eleven per side, so the caller takes the prefix, exactly as the provider already does.
    public static func choreograph(
        play: PlayRecord,
        offense: [Player],
        defense: [Player]
    ) -> SnapAnchorSet {
        let outcome = play.outcome
        let los = Double(play.situation.yardLine)
        let endSpot = Swift.min(100, Swift.max(0, los + Double(outcome.yards)))
        let firstDown = Swift.min(100, los + Double(play.situation.distance))
        let offenseSide = play.situation.possession
        let defenseSide = offenseSide.opponent

        // Alignment. Index within position so two receivers do not stack.
        func anchors(_ players: [Player], side: Side, isOffense: Bool) -> [ActorAnchor] {
            var seen: [Position: Int] = [:]
            return players.map { player in
                let index = seen[player.position, default: 0]
                seen[player.position] = index + 1
                let start = alignment(
                    for: player.position, index: index, side: side, lineOfScrimmage: los
                )
                let role = self.role(
                    for: player.id, position: player.position, outcome: outcome,
                    isOffense: isOffense
                )
                return ActorAnchor(
                    playerID: player.id, side: side, role: role,
                    start: start,
                    end: destination(
                        role: role, start: start, outcome: outcome, call: play.offensiveCall,
                        lineOfScrimmage: los, endSpot: endSpot
                    )
                )
            }
        }

        let actors = anchors(offense, side: offenseSide, isOffense: true)
            + anchors(defense, side: defenseSide, isOffense: false)

        let deciding = outcome.decidingMatchup.map {
            DecidingMark(
                kind: $0.kind, attackerID: $0.attackerID, defenderID: $0.defenderID,
                attackerWon: $0.attackerWon
            )
        }

        var foreground: [UUID] = []
        if let deciding {
            foreground.append(deciding.attackerID)
            foreground.append(deciding.defenderID)
        }
        if let carrier = outcome.ballCarrierID, !foreground.contains(carrier) {
            foreground.append(carrier)
        }
        // prefix rather than validation: 04 section 9's cap is met by construction, which is what
        // keeps this function total.
        foreground = Array(foreground.prefix(AnchorRules.maximumForegrounded))

        let duration = Swift.min(
            AnchorRules.maximumPlaybackSeconds,
            Swift.max(
                AnchorRules.minimumPlaybackSeconds,
                Double(outcome.secondsElapsed) * AnchorRules.clockToPlaybackRatio
            )
        )

        return SnapAnchorSet(
            lineOfScrimmage: los,
            firstDownLine: firstDown,
            endSpot: endSpot,
            actors: actors,
            ball: ballPath(
                outcome: outcome, call: play.offensiveCall, actors: actors,
                lineOfScrimmage: los, endSpot: endSpot
            ),
            deciding: deciding,
            foregroundIDs: foreground,
            durationSeconds: duration,
            sentence: sentence(for: outcome, offense: offense, defense: defense)
        )
    }

    /// Where an actor finishes. Nothing moves without a field in the record naming why.
    private static func destination(
        role: SnapRole,
        start: FieldPoint,
        outcome: SnapOutcome,
        call: OffensiveCall,
        lineOfScrimmage: Double,
        endSpot: Double
    ) -> FieldPoint {
        switch role {
        case .carrier:
            return FieldPoint(yard: endSpot, lateral: start.lateral)
        case .routeRunner:
            // Recorded depth, not an invented route shape: the call's air yards are the only
            // downfield distance the record actually holds.
            return FieldPoint(
                yard: lineOfScrimmage + Double(call.passDepth.airYards), lateral: start.lateral
            )
        case .rusher:
            return FieldPoint(
                yard: lineOfScrimmage - AnchorRules.rusherClosingYards, lateral: start.lateral
            )
        case .passer, .blocker, .decoy, .coverage, .runFit, .kicker, .blockLeverage:
            return start
        }
    }

    /// The ball's journey, as legs with when each happens.
    private static func ballPath(
        outcome: SnapOutcome,
        call: OffensiveCall,
        actors: [ActorAnchor],
        lineOfScrimmage: Double,
        endSpot: Double
    ) -> [BallSegment] {
        let centre = FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.centerLateral)
        func point(_ id: UUID?) -> FieldPoint? {
            guard let id else { return nil }
            return actors.first(where: { $0.playerID == id })?.start
        }
        let passerSpot = point(outcome.passerID)
            ?? FieldPoint(yard: lineOfScrimmage - AnchorRules.passerDepth,
                          lateral: AnchorRules.centerLateral)
        let snap = BallSegment(
            kind: .snap, from: centre, to: passerSpot,
            startFraction: 0, endFraction: AnchorRules.snapFraction
        )

        switch outcome.result {
        case .incompletion, .interception:
            let targetLateral = point(outcome.targetID)?.lateral ?? AnchorRules.centerLateral
            let landing = FieldPoint(
                yard: lineOfScrimmage + Double(call.passDepth.airYards), lateral: targetLateral
            )
            var path = [snap, BallSegment(
                kind: .air, from: passerSpot, to: landing,
                startFraction: AnchorRules.snapFraction, endFraction: AnchorRules.releaseFraction
            )]
            if outcome.result == .interception {
                path.append(BallSegment(
                    kind: .loose, from: landing,
                    to: FieldPoint(yard: endSpot, lateral: targetLateral),
                    startFraction: AnchorRules.releaseFraction, endFraction: 1
                ))
            }
            return path

        case .sack, .kneel:
            return [snap, BallSegment(
                kind: .carry, from: passerSpot,
                to: FieldPoint(yard: endSpot, lateral: passerSpot.lateral),
                startFraction: AnchorRules.snapFraction, endFraction: 1
            )]

        default:
            let carrierSpot = point(outcome.ballCarrierID)
            let endLateral = carrierSpot?.lateral ?? AnchorRules.centerLateral
            if call.playType == .pass, outcome.targetID != nil {
                let targetLateral = point(outcome.targetID)?.lateral ?? AnchorRules.centerLateral
                let catchSpot = FieldPoint(
                    yard: lineOfScrimmage + Double(call.passDepth.airYards), lateral: targetLateral
                )
                return [snap, BallSegment(
                    kind: .air, from: passerSpot, to: catchSpot,
                    startFraction: AnchorRules.snapFraction,
                    endFraction: AnchorRules.releaseFraction
                ), BallSegment(
                    kind: .carry, from: catchSpot,
                    to: FieldPoint(yard: endSpot, lateral: targetLateral),
                    startFraction: AnchorRules.releaseFraction, endFraction: 1
                )]
            }
            return [snap, BallSegment(
                kind: .carry, from: passerSpot,
                to: FieldPoint(yard: endSpot, lateral: endLateral),
                startFraction: AnchorRules.snapFraction, endFraction: 1
            )]
        }
    }
```

- [ ] **Step 4: Add the suite flag**

In `Tests/SimTests/main.swift`, add a branch before the final `else`:

```swift
} else if CommandLine.arguments.contains("--snap-anchors") {
    runSnapAnchorTests()
```

- [ ] **Step 5: Run the tests and make sure they pass**

```bash
swift build && swift run SimTests --snap-anchors
```

Expected: all eleven tests pass. If the box-score test fails on a clamped end spot, the cause is a `yardLine` close enough to a goal line that `endSpot` clamps — fix by choosing a mid-field `yardLine` in the fixture, not by loosening the assertion.

- [ ] **Step 6: Run the whole suite to check nothing else moved**

```bash
swift run SimTests 2>&1 | tail -5
```

Expected: the existing count plus the new tests, all passing.

- [ ] **Step 7: Commit**

```bash
git add Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift Tests/SimTests/main.swift
git commit Sources/FootballSimCore/Engine/SnapAnchors.swift Tests/SimTests/Suites/SnapAnchorTests.swift Tests/SimTests/main.swift -m "$(cat <<'EOF'
feat: choreograph a recorded snap into an anchor set

Closes the engine half of G-06. The five legality clauses of 03 section
9.3 are five tests: purity by byte-identical encoding, box-score
consistency, completeness at 22 actors and 3 foregrounded, on-field
bounds, and totality over SnapResult.allCases.

The foreground cap is met by prefix rather than by validation, which is
what keeps choreograph total -- there is no resolved snap it can be
handed that it has to reject.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: `MatchDayReadModel.playback`

**Files:**
- Modify: `Sources/ProFootballCoachUI/ScreenReadModels.swift:1126-1370` (the `MatchDayReadModel` region)
- Modify: `Tests/SimTests/Suites/SnapAnchorTests.swift`

**Interfaces:**
- Consumes: nothing from the engine — this is presentation space, `stableID` strings and absolute 0-to-120 `x`
- Produces: `MatchDayReadModel.Playback`, `MatchDayReadModel.Playback.ActorTrack`, `MatchDayReadModel.Playback.BallLeg`, and a `playback` property on `MatchDayReadModel`

- [ ] **Step 1: Write the failing test**

Add to `Tests/SimTests/Suites/SnapAnchorTests.swift`, inside the suite. The imports were added in Task 2.

```swift
test("a playback track carries absolute field positions") {
    let track = MatchDayReadModel.Playback.ActorTrack(
        stableID: "a", startX: 40, startY: 0.3, endX: 52, endY: 0.3, role: "carrier"
    )
    expectEqual(track.startX, 40)
    expectEqual(track.endX, 52)

    let playback = MatchDayReadModel.Playback(
        durationSeconds: 3,
        actors: [track],
        ball: [MatchDayReadModel.Playback.BallLeg(
            kind: "carry", fromX: 40, fromY: 0.5, toX: 52, toY: 0.3,
            startFraction: 0.1, endFraction: 1
        )],
        endSpotX: 52,
        sentence: "Gain of 12 yards."
    )
    expectEqual(playback.actors.count, 1)
    expectEqual(playback.sentence, "Gain of 12 yards.")
}
```

- [ ] **Step 2: Run it to make sure it fails**

```bash
swift build 2>&1 | head -10
```

Expected: FAIL, `type 'MatchDayReadModel' has no member 'Playback'`.

- [ ] **Step 3: Write the minimal implementation**

In `Sources/ProFootballCoachUI/ScreenReadModels.swift`, inside `MatchDayReadModel`, next to the existing `Actor` struct (around line 1126), add:

```swift
    /// One recorded snap, ready to animate.
    ///
    /// Presentation space: `stableID` strings rather than `UUID`s, and absolute 0-to-120 x values
    /// rather than the engine's offense-relative 0-to-100. The provider does that conversion,
    /// because direction is presentation and `03` section 9.2 keeps it out of the engine.
    ///
    /// Optional on the model because it is genuinely absent before the first snap of a game, and
    /// the right thing to draw then is the static field the view already draws.
    public struct Playback: Sendable, Equatable {
        public struct ActorTrack: Sendable, Equatable {
            public let stableID: String
            public let startX: Double
            public let startY: Double
            public let endX: Double
            public let endY: Double
            public let role: String

            public init(
                stableID: String, startX: Double, startY: Double,
                endX: Double, endY: Double, role: String
            ) {
                self.stableID = stableID
                self.startX = startX
                self.startY = startY
                self.endX = endX
                self.endY = endY
                self.role = role
            }
        }

        public struct BallLeg: Sendable, Equatable {
            public let kind: String
            public let fromX: Double
            public let fromY: Double
            public let toX: Double
            public let toY: Double
            public let startFraction: Double
            public let endFraction: Double

            public init(
                kind: String, fromX: Double, fromY: Double, toX: Double, toY: Double,
                startFraction: Double, endFraction: Double
            ) {
                self.kind = kind
                self.fromX = fromX
                self.fromY = fromY
                self.toX = toX
                self.toY = toY
                self.startFraction = startFraction
                self.endFraction = endFraction
            }
        }

        public let durationSeconds: Double
        public let actors: [ActorTrack]
        public let ball: [BallLeg]
        public let endSpotX: Double
        public let sentence: String

        public init(
            durationSeconds: Double,
            actors: [ActorTrack],
            ball: [BallLeg],
            endSpotX: Double,
            sentence: String
        ) {
            self.durationSeconds = durationSeconds
            self.actors = actors
            self.ball = ball
            self.endSpotX = endSpotX
            self.sentence = sentence
        }
    }
```

Then add the stored property beside `foregroundActorIDs` (around line 1269):

```swift
    /// The last completed snap, if one has been played. Nil before the first snap.
    public let playback: Playback?
```

Add the parameter to the throwing initialiser (around line 1286), after `foregroundActorIDs`, with a default so no existing call site breaks:

```swift
        playback: Playback? = nil,
```

And the assignment beside the others (around line 1367):

```swift
        self.playback = playback
```

- [ ] **Step 4: Run the tests and make sure they pass**

```bash
swift build && swift run SimTests --snap-anchors
```

Expected: twelve tests pass, and no existing call site of the initialiser fails to compile.

- [ ] **Step 5: Commit**

```bash
git add Sources/ProFootballCoachUI/ScreenReadModels.swift Tests/SimTests/Suites/SnapAnchorTests.swift
git commit Sources/ProFootballCoachUI/ScreenReadModels.swift Tests/SimTests/Suites/SnapAnchorTests.swift -m "$(cat <<'EOF'
feat: add playback to the Match Day read model

Presentation space -- stable identifiers and absolute 0-to-120 x -- so
the engine's offense-relative anchors convert exactly once, in the
provider, where direction lives.

Optional because it is genuinely absent before the first snap, and the
static field the view already draws is the right thing to draw then.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: The provider mapping, with direction applied

This is where the coordinate trap gets closed: offense-relative 0-to-100 becomes absolute 0-to-120, and `offenseDirection` decides which way.

**Files:**
- Modify: `Sources/CoachWorldApp/CoachWorldMatchProvider.swift`
- Modify: `Tests/SimTests/Suites/SnapAnchorTests.swift`

**Interfaces:**
- Consumes: `SnapAnchors.choreograph`, `MatchDayReadModel.Playback`, `MatchFieldDirection` (`ScreenReadModels.swift:1064`)
- Produces: `CoachWorldReadModelProvider.playback(from:offenseDirection:) -> MatchDayReadModel.Playback`

- [ ] **Step 1: Write the failing test**

Add inside the suite. The fixture deliberately sits away from midfield: at `yardLine: 20` with a
10-yard gain, offense-relative `endSpot` is 30, which maps to absolute 40 rightward and 80 leftward.
A midfield fixture would map to the same number both ways and prove nothing.

```swift
test("direction decides which way the play runs on the drawn field") {
    let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
    let play = PlayRecord(
        situation: Situation(down: 1, distance: 10, yardLine: 20),
        offensiveCall: OffensiveCall(playType: .run),
        defensiveCall: DefensiveCall(coverage: .man),
        outcome: SnapOutcome(
            result: .gain, yards: 10, secondsElapsed: 6, matchups: [],
            ballCarrierID: personnel.offense[1].id
        ),
        callInTriggers: []
    )
    let set = SnapAnchors.choreograph(
        play: play,
        offense: Array(personnel.offense.prefix(11)),
        defense: Array(personnel.defense.prefix(11))
    )
    expectEqual(set.endSpot, 30, "the engine's end spot is offense-relative")

    let rightward = CoachWorldReadModelProvider.playback(from: set, offenseDirection: .leftToRight)
    let leftward = CoachWorldReadModelProvider.playback(from: set, offenseDirection: .rightToLeft)

    // Ten yards of end zone sit at each end of the 120-yard drawn field.
    expectEqual(rightward.endSpotX, 40, "a leftToRight drive must run up the drawn field")
    expectEqual(leftward.endSpotX, 80, "a rightToLeft drive must run down the drawn field")
    expectEqual(rightward.actors.count, 22)
    expectEqual(leftward.actors.count, 22)
    for actor in rightward.actors + leftward.actors {
        expectIn(actor.startX, 0...120, "an actor left the drawn field")
        expectIn(actor.endX, 0...120, "an actor left the drawn field")
    }
}
```

- [ ] **Step 2: Run it to make sure it fails**

```bash
swift build 2>&1 | head -10
```

Expected: FAIL, `type 'CoachWorldReadModelProvider' has no member 'playback'`.

- [ ] **Step 3: Write the minimal implementation**

Add to `Sources/CoachWorldApp/CoachWorldMatchProvider.swift`, inside the existing `public extension CoachWorldReadModelProvider`:

```swift
    /// Converts an engine anchor set into presentation space.
    ///
    /// The one place the offense-relative-to-absolute conversion happens, and the one place
    /// direction is read. `03` section 9.2 keeps both out of the engine, and `04` section 9
    /// requires that the view never guess direction from colour.
    static func playback(
        from set: SnapAnchorSet,
        offenseDirection: MatchFieldDirection
    ) -> MatchDayReadModel.Playback {
        // Ten yards of end zone sit at each end of the 120-yard drawn field, so an
        // offense-relative 0 is an absolute 10 when the offence attacks rightward, and an
        // absolute 110 when it attacks leftward.
        func x(_ yard: Double) -> Double {
            offenseDirection == .leftToRight ? yard + 10 : 110 - yard
        }

        return MatchDayReadModel.Playback(
            durationSeconds: set.durationSeconds,
            actors: set.actors.map { actor in
                MatchDayReadModel.Playback.ActorTrack(
                    stableID: actor.playerID.uuidString,
                    startX: x(actor.start.yard),
                    startY: actor.start.lateral,
                    endX: x(actor.end.yard),
                    endY: actor.end.lateral,
                    role: actor.role.rawValue
                )
            },
            ball: set.ball.map { segment in
                MatchDayReadModel.Playback.BallLeg(
                    kind: segment.kind.rawValue,
                    fromX: x(segment.from.yard),
                    fromY: segment.from.lateral,
                    toX: x(segment.to.yard),
                    toY: segment.to.lateral,
                    startFraction: segment.startFraction,
                    endFraction: segment.endFraction
                )
            },
            endSpotX: x(set.endSpot),
            sentence: set.sentence
        )
    }
```

Then wire it into `matchDay(from:)`. After the existing `let clock = ...` line, add:

```swift
        let lastPlay = session.currentDrive?.plays.last ?? session.drives.last?.plays.last
        let playback = lastPlay.map { play -> MatchDayReadModel.Playback in
            let offensePersonnel = play.situation.possession == .home
                ? session.home.offense : session.away.offense
            let defensePersonnel = play.situation.possession == .home
                ? session.away.defense : session.home.defense
            return playback(
                from: SnapAnchors.choreograph(
                    play: play,
                    offense: Array(offensePersonnel.prefix(11)),
                    defense: Array(defensePersonnel.prefix(11))
                ),
                offenseDirection: .leftToRight
            )
        }
```

and pass `playback: playback,` into the `MatchDayReadModel(...)` call, after `foregroundActorIDs:`.

- [ ] **Step 4: Run the tests and make sure they pass**

```bash
swift build && swift run SimTests --snap-anchors
```

Expected: thirteen tests pass.

If the read model's initialiser now throws `invalidLine("firstDownDirection")`, the cause is
`ScreenReadModels.swift:1335` — it requires `firstDownLine > lineOfScrimmage` when the direction is
`leftToRight` and the reverse when it is not. The provider must convert those two lines through the
same `x(_:)` mirror as everything else. Fix the conversion, never the guard.

- [ ] **Step 5: Commit**

```bash
git add Sources/CoachWorldApp/CoachWorldMatchProvider.swift Tests/SimTests/Suites/SnapAnchorTests.swift
git commit Sources/CoachWorldApp/CoachWorldMatchProvider.swift Tests/SimTests/Suites/SnapAnchorTests.swift -m "$(cat <<'EOF'
feat: project the anchor set into presentation space

The one place offense-relative 0-to-100 becomes the drawn field's
absolute 0-to-120, and the one place direction is read. Both stay out of
the engine per 03 section 9.2, and 04 section 9's rule that the view
never guesses direction from colour now has a single home.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Animate it

**Files:**
- Modify: `Sources/ProFootballCoachUI/MatchDayView.swift:166-194` (the `field` property) and `:275-...` (`actorMark`)

**Interfaces:**
- Consumes: `MatchDayReadModel.Playback`
- Produces: an animated `field`

- [ ] **Step 1: Add the playback clock**

In `MatchDayView`, add beside the existing `@State private var showsEvidence`:

```swift
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var playbackStart: Date?
    @State private var speedIndex = 0

    private var speedMultiplier: Double {
        MatchMetric.speedMultipliers[speedIndex % MatchMetric.speedMultipliers.count]
    }

    /// How far through the recorded snap we are, 0 to 1. Reaching 1 leaves the dots at their end
    /// positions, which is the pre-snap state for the next play.
    private func progress(at date: Date, duration: Double) -> Double {
        guard let playbackStart, duration > 0 else { return 1 }
        let elapsed = date.timeIntervalSince(playbackStart) * speedMultiplier
        return Swift.min(1, Swift.max(0, elapsed / duration))
    }
```

Add to the `private enum MatchMetric` at `MatchDayView.swift:536`, beside the existing
`actorSize` constant:

```swift
    static let speedMultipliers: [Double] = [1, 2, 4]
    static let ballMarkSize: CGFloat = 8
```

- [ ] **Step 2: Interpolate the actors**

Replace the `ForEach(model.actors, ...)` line inside `field`'s `ZStack` (line 185-187) with:

```swift
                if let playback = model.playback, !reduceMotion {
                    TimelineView(.animation) { timeline in
                        let t = progress(at: timeline.date, duration: playback.durationSeconds)
                        ZStack(alignment: .topLeading) {
                            ForEach(playback.actors, id: \.stableID) { track in
                                animatedMark(track, at: t, size: size)
                            }
                            ballMark(playback, at: t, size: size)
                        }
                    }
                } else {
                    ForEach(model.actors, id: \.stableID) { actor in
                        actorMark(actor, size: size)
                    }
                }
```

- [ ] **Step 3: Add the two new marks**

Add these methods to `MatchDayView`:

```swift
    /// One dot, between where it started and where the record says it finished.
    private func animatedMark(
        _ track: MatchDayReadModel.Playback.ActorTrack,
        at t: Double,
        size: CGSize
    ) -> some View {
        let x = track.startX + (track.endX - track.startX) * t
        let y = track.startY + (track.endY - track.startY) * t
        let foreground = model.foregroundActorIDs.contains(track.stableID)
        return Circle()
            .fill(foreground ? palette.fieldLive.color : palette.fieldLine.color)
            .frame(width: MatchMetric.actorSize, height: MatchMetric.actorSize)
            .position(
                x: size.width * CGFloat(x / 120),
                y: size.height * CGFloat(y)
            )
            .accessibilityHidden(true)
    }

    /// The ball, on whichever leg of its journey is current.
    private func ballMark(
        _ playback: MatchDayReadModel.Playback,
        at t: Double,
        size: CGSize
    ) -> some View {
        let leg = playback.ball.last { $0.startFraction <= t } ?? playback.ball.first
        return Group {
            if let leg {
                let span = Swift.max(0.0001, leg.endFraction - leg.startFraction)
                let local = Swift.min(1, Swift.max(0, (t - leg.startFraction) / span))
                let x = leg.fromX + (leg.toX - leg.fromX) * local
                let y = leg.fromY + (leg.toY - leg.fromY) * local
                Circle()
                    .fill(palette.fieldAnnotation.color)
                    .frame(width: MatchMetric.ballMarkSize, height: MatchMetric.ballMarkSize)
                    .position(
                        x: size.width * CGFloat(x / 120),
                        y: size.height * CGFloat(y)
                    )
            }
        }
        .accessibilityHidden(true)
    }
```

- [ ] **Step 4: Restart the clock when the snap changes**

Add to `field`, after `.accessibilitySortPriority(80)`:

```swift
        .onChange(of: model.recordedOutcomeID) { _, _ in
            playbackStart = Date()
        }
        .onAppear { playbackStart = Date() }
```

- [ ] **Step 5: Build and check the whole suite**

```bash
swift build && swift run SimTests 2>&1 | tail -5
```

Expected: build green, suite green. The view has no unit tests by `CLAUDE.md`'s rule, but it must compile.

- [ ] **Step 6: Commit**

```bash
git add Sources/ProFootballCoachUI/MatchDayView.swift
git commit Sources/ProFootballCoachUI/MatchDayView.swift -m "$(cat <<'EOF'
feat: animate the recorded snap on the Match Day field

TimelineView drives a normalised progress over the recorded duration and
the dots interpolate between the anchor set's start and end. The Canvas
that draws turf, rules, hashes and numbers is untouched; the play art is
drawn over it.

Progress reaching 1 leaves the dots at their end positions, which is the
pre-snap state for the next play, so the animation settles rather than
snapping back.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Reduce Motion, and the live Speed control

**Files:**
- Modify: `Sources/ProFootballCoachUI/MatchDayView.swift`
- Modify: `Sources/CoachWorldApp/CoachWorldMatchProvider.swift:117-119` (the `.speed` control)

**Interfaces:**
- Consumes: `MatchMetric.speedMultipliers`, `speedIndex`
- Produces: a live Speed control and an accessible discrete path

- [ ] **Step 1: Make the Speed control live in the provider**

In `CoachWorldMatchProvider.swift`, replace the `.speed` case (lines 117-119):

```swift
            case .speed:
                return .init(id: id, value: "1×", isEnabled: false, isSelected: false,
                             intentID: .init(rawValue: prefix + id.rawValue))
```

with:

```swift
            case .speed:
                // Live as of the G-06 slice. Playback rate is presentation, so the value cycles in
                // the view and the intent only tells the session a cycle happened.
                return .init(
                    id: id, value: "Speed", isEnabled: !session.completed, isSelected: false,
                    intentID: .init(rawValue: prefix + id.rawValue)
                )
```

- [ ] **Step 2: Cycle the speed in the view**

In `MatchDayView.controlButton` (`MatchDayView.swift:340-366`), replace lines 341-348:

```swift
        let presentation = controlPresentation(control.id)
        let accessibilityLabel = control.value.map {
            "\(presentation.title), \($0)"
        } ?? presentation.title

        return Button {
            onControl(control.intentID)
        } label: {
```

with:

```swift
        let presentation = controlPresentation(control.id)
        // Playback rate is presentation, so the view owns the displayed value for this one control
        // and the intent only records that a cycle happened.
        let displayedValue = control.id == .speed
            ? "\(Int(speedMultiplier))x"
            : control.value
        let accessibilityLabel = displayedValue.map {
            "\(presentation.title), \($0)"
        } ?? presentation.title

        return Button {
            if control.id == .speed {
                speedIndex = (speedIndex + 1) % MatchMetric.speedMultipliers.count
            }
            onControl(control.intentID)
        } label: {
```

and replace line 355:

```swift
                if let value = control.value { Text(value).font(.caption) }
```

with:

```swift
                if let value = displayedValue { Text(value).font(.caption) }
```

Note `x` rather than the multiplication sign: `CLAUDE.md` keeps copy plain, and the existing `1×`
came from the disabled placeholder this replaces.

- [ ] **Step 3: Give Reduce Motion the accessible sentence**

The `else` branch added in Task 8 already renders the static dots under Reduce Motion, so the snap
still needs narrating. `lowerThird` (`MatchDayView.swift:304-327`) is an `HStack`; insert the
sentence after the `Text(model.causalCommentary)` block at line 310, before the `Spacer`:

```swift
            if let sentence = model.playback?.sentence {
                Text(sentence)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            }
```

`lowerThird` already carries `.accessibilityElement(children: .combine)` at line 325, so the
sentence joins the existing combined label rather than needing one of its own.

- [ ] **Step 4: Build and run the suite**

```bash
swift build && swift run SimTests 2>&1 | tail -5
```

Expected: build green, suite green.

- [ ] **Step 5: Check the Reduce Motion gate still passes**

```bash
swift run SimTests --reduce-motion 2>&1 | tail -10
```

Expected: pass. If the gate enumerates surfaces by construction and now sees a `TimelineView`, it may require the surface to declare a discrete path — read the failure and satisfy it rather than exempting Match Day.

- [ ] **Step 6: Commit**

```bash
git add Sources/ProFootballCoachUI/MatchDayView.swift Sources/CoachWorldApp/CoachWorldMatchProvider.swift
git commit Sources/ProFootballCoachUI/MatchDayView.swift Sources/CoachWorldApp/CoachWorldMatchProvider.swift -m "$(cat <<'EOF'
feat: make Speed live and give Reduce Motion a discrete path

Speed was rendered disabled. Playback rate is presentation, so the value
cycles in the view and the intent only records that a cycle happened.

Reduce Motion drops the TimelineView entirely rather than animating at
zero duration, per 04 section 7: the requirement is discrete states, not
fast travel. The snap's accessible sentence carries the narration that
the animation would otherwise have carried.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: Record the truth, and write the walkthrough

**Files:**
- Modify: `docs/STATUS.md`
- Create: `docs/plans/2026-08-17-match-day-walkthrough.md`

**Interfaces:**
- Consumes: everything above
- Produces: the honest record, and the owner's script

- [ ] **Step 1: Update `docs/STATUS.md`**

`docs/STATUS.md:450` currently reads "Match Day still needs G-06 and G-11." Replace with a paragraph that states what landed, what a compiler and the suite actually saw, and the two things not verified:

```markdown
**G-06 landed 2026-08-17; Match Day still needs G-11.** `03` §9 holds the anchor contract and
`Sources/FootballSimCore/Engine/SnapAnchors.swift` implements it: a pure, total, rng-free function
from a recorded `PlayRecord` to a sparse anchor set. Its five legality clauses are five tests in
`--snap-anchors`, driven from `SnapResult.allCases` rather than a sample. The Match Day field now
animates the last completed snap under a `TimelineView`, and the Speed control -- previously
rendered disabled -- cycles 1x, 2x and 4x.

**Two things are not verified and must not be reported as if they were.** D4's 16.7 ms figure is a
*frame* ceiling; the headless suite measures choreography and interpolation compute only, and no
rendered frame has been timed. And `04` §9's orientation question -- does the field read as a
football field on a phone, is the line of scrimmage legible as a line -- is the presentation
question P13 says no test can answer. The script is `docs/plans/2026-08-17-match-day-walkthrough.md`
and the walkthrough is an owner action that has not happened.
```

- [ ] **Step 2: Write the walkthrough script**

Create `docs/plans/2026-08-17-match-day-walkthrough.md`:

```markdown
# Match Day walkthrough script (owner action)

P13 requires an owner orientation read that no test in the plan can answer. This is the script.
Nobody but the owner can run it, and no agent may report it as done.

## Setup

1. Build and run on an iPhone 15-generation simulator or device, landscape.
2. Start a new career, advance to the first fixture, and enter Match Day.
3. Advance one snap.

## The questions P13 asks

1. **Does the field read as a football field on a phone?** Not "can you tell what it is" — does it
   read as one at a glance, in the frame it occupies?
2. **Is the line of scrimmage legible as a line?** Both markers are drawn. Can you tell which is
   which without being told?
3. Does the animation read as the snap that the lower third describes, or as decoration?
4. At 4x, is anything still legible?
5. Under Settings > Accessibility > Motion > Reduce Motion, does the discrete path still tell you
   what happened?

## What to report back

For each question: yes, no, or "nearly, but". A "nearly, but" is the useful answer and the one the
next slice will act on.
```

- [ ] **Step 3: Run the full verification**

```bash
swift build && swift run SimTests 2>&1 | tail -5
```

Record the actual test count in the commit message. Do not round it, and do not describe the run as more than it is.

- [ ] **Step 4: Commit**

```bash
git add docs/STATUS.md docs/plans/2026-08-17-match-day-walkthrough.md
git commit docs/STATUS.md docs/plans/2026-08-17-match-day-walkthrough.md -m "$(cat <<'EOF'
docs: record what G-06 landed and what it did not verify

STATUS names the two claims this slice is not entitled to make: D4's
16.7 ms is a frame ceiling that a headless suite cannot measure, and the
04 section 9 orientation read is an owner action that has not happened.

The walkthrough script is the deliverable for the second one.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Verification before completion

After Task 10, per `CLAUDE.md` §5, assert only what was actually observed:

- [ ] `swift build` green — state the command and its result
- [ ] `swift run SimTests` green — state the actual test and check counts
- [ ] `swift run SimTests --snap-anchors` green
- [ ] The two legal tests still green (name collision, trade dress)
- [ ] Adversarial review on the phase diff, per `CLAUDE.md` §4, before declaring the phase done
- [ ] **Not claimed:** the 16.7 ms frame ceiling, and the owner walkthrough
