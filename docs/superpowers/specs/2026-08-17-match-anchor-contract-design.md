# Design — the match anchor contract and the animated 2D match view (G-06)

Date: 2026-08-17
Status: approved by the owner 2026-08-17, pending implementation
Closes: G-06 (`docs/briefs/2026-08-12-gap-register.md`), FSC-011
Phase: `05` P13, first slice

## 1. What this builds, and what it does not

Today `MatchDayView` draws a static field diagram: turf, yard rules, hash marks, numbers, end zones,
line-of-scrimmage and first-down markers, and twenty-two numbered dots that never move. The dots are
not even in a formation — `CoachWorldMatchProvider.actors` gives every player on a side the same `x`
and spreads them vertically by array index, producing two columns of eleven. Speed and Tactics are
rendered disabled. There is no `TimelineView` anywhere in the view.

This design closes the gap between that and `04` §9 for **one snap at a time**.

**In scope**

- The anchor contract written into canon (`03` §9), because the doc-first amendment rule in
  `CLAUDE.md` forbids encoding a design decision only in code.
- `SnapAnchors` — a pure engine function from a recorded `PlayRecord` to a sparse anchor set.
- `MatchDayReadModel.playback` and the provider mapping that fills it.
- `TimelineView`-driven playback of the last completed snap inside the `Canvas` that already exists.
- The Speed control, made live.
- Reduce Motion as a discrete state sequence.
- The tests P13 names.

**Explicitly out of scope**

- Continuous drive or full-game playback. One snap, then the view settles into the next pre-snap
  state.
- Key-moment scrubbing, the Tactics control, and the rest of P13's broadcast rebuild.
- Any change to how football resolves. The reducer, resolver and drive engine are not touched.
- Routes simulated against live coverage, physics, pursuit models, or anything from the discarded
  `Arcade/` layer. `04` §9 prohibits invented movement, and this design has no place to put it.

## 2. Why almost nothing new has to be recorded

`PlayRecord` (`Sources/FootballSimCore/Engine/DriveEngine.swift:5`) already carries the pre-snap
`Situation`, the `OffensiveCall`, the `DefensiveCall`, the `SnapOutcome` and the call-in triggers,
and `DriveProgress.plays` holds those records inside the persisted `MatchSessionState`. `SnapOutcome`
carries `matchups`, `decidingMatchup`, `ballCarrierID`, `passerID`, `targetID`, `yards` and
`secondsElapsed`. `OffensiveCall` carries the `RunGap` and the `PassDepth`, and `PassDepth.airYards`
resolves to `MatchupRules.shortPassAirYards` / `midPassAirYards` / `deepPassAirYards`. `SnapRole`
already enumerates passer, blocker, routeRunner, carrier, decoy, rusher, coverage, runFit, kicker
and blockLeverage.

So the engine has the causal record and the vocabulary. What it lacks is geometry. This design adds
geometry as a **derivation**, not as new recorded state — which is also why the G-06 save bound in
the gap register is "current game only": nothing new is persisted at all.

The one thing genuinely absent is per-snap alignment. The owner's decision on 2026-08-17 is
**role-template alignment**: a fixed deterministic template keyed on `SnapRole` and `Position`.
`04` §9 permits this in terms — "route-tree and formation notation are drawn conventions of the
sport, not protected expression" — while continuing to refuse any specific playbook's diagrams.

## 3. Coordinate space, and the trap in it

`Situation.yardLine` is **offense-relative**: 0 to 100, measured from the offence's own goal line.
`MatchDayReadModel.Actor.xYardsFromLeftGoalLine` is **absolute**: 0 to 120 across the drawn field,
including both ten-yard end zones. The existing provider converts by assignment rather than by
arithmetic, and does not consult direction at all.

The contract fixes the boundary:

- **Engine anchors are offense-relative.** A `FieldPoint` carries `yard` in 0...100 from the
  offence's own goal line and `lateral` in 0...1 across the field. The engine never learns which way
  the offence is facing, because that is presentation.
- **The provider applies `offenseDirection`** when mapping to the read model's absolute 0...120
  space, and it owns the ten-yard end-zone offset.

Stating it this way keeps `03b`'s engine/UI separation intact and gives the direction rule in
`04` §9 — "the view never guesses from home/away colour" — exactly one place to live.

## 4. The anchor vocabulary

```swift
public struct FieldPoint: Codable, Sendable, Equatable {
    public let yard: Double     // 0...100, from the offence's own goal line
    public let lateral: Double  // 0...1 across the field
}

public struct ActorAnchor: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let side: Side
    public let role: SnapRole
    public let start: FieldPoint
    public let end: FieldPoint
    public let path: [FieldPoint]   // empty unless the record justifies a polyline
}

public struct BallSegment: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case snap, carry, air, loose
    }
    public let kind: Kind
    public let from: FieldPoint
    public let to: FieldPoint
    public let startFraction: Double  // 0...1 of the play's duration
    public let endFraction: Double
}

public struct DecidingMark: Codable, Sendable, Equatable {
    public let kind: MatchupRecord.Kind
    public let attackerID: UUID
    public let defenderID: UUID
    public let attackerWon: Bool
}

public struct SnapAnchorSet: Codable, Sendable, Equatable {
    public let lineOfScrimmage: Double
    public let firstDownLine: Double
    public let endSpot: Double
    public let actors: [ActorAnchor]      // exactly 22
    public let ball: [BallSegment]
    public let deciding: DecidingMark?
    public let foregroundIDs: [UUID]      // at most 3
    public let durationSeconds: Double
    public let sentence: String
}
```

`path` is empty for most actors on most snaps. That is the point: the set is sparse because the
record is sparse, and a dense set would have to be invented.

## 5. The function

```swift
public enum SnapAnchors {
    public static func choreograph(
        play: PlayRecord,
        offense: [Player],
        defense: [Player]
    ) -> SnapAnchorSet
}
```

Pure, total, RNG-free, and holding no reference to any engine type that can resolve football.

The two player arrays are passed separately rather than as a `SnapPersonnel` because a snap draws
its offence from the possessing side's `SnapPersonnel.offense` and its defence from the *other*
side's `SnapPersonnel.defense`, and no single `SnapPersonnel` holds that pair. Which side is on
offence is `play.situation.possession`, so it is not a parameter.

**Derivations.**

- `lineOfScrimmage = play.situation.yardLine`. `firstDownLine = LOS + play.situation.distance`,
  clamped to the goal line.
- `endSpot = LOS + play.outcome.yards`, clamped to 0...100. Negative yardage moves it backwards, so
  a sack ends behind the line by construction rather than by a special case.
- **Formation.** Every player gets a `start` from the role-template table: linemen on the line at
  fixed lateral stops, the passer behind them, backs beside the passer, receivers at the numbers and
  in the slots, the front seven mirrored across the line, corners over the widest receivers, safeties
  at depth. The template is a constant, and it is keyed on `SnapRole` first and `Position` second so
  a personnel package that puts a tight end at receiver aligns as what it is doing, not as what it
  is listed as.
- **Ball, pass.** `snap` from the centre to the passer, then `air` from the passer to
  `LOS + call.depth.airYards` at the target's lateral, then — on a completion only — `carry` to
  `endSpot`. An incompletion has no `carry` segment. An interception's `air` segment terminates at
  the defender and is followed by a `loose` segment.
- **Ball, run.** `snap` to the carrier, then `carry` through the lateral lane that `call.gap` names,
  to `endSpot`.
- **Ball, sack.** `snap` to the passer, then `carry` backwards to `endSpot`.
- **Actor ends.** Blockers hold their start. Rushers converge toward the passer. The carrier ends at
  the end spot. Route runners end at their depth; the defender in coverage on a recorded route ends
  alongside. Everyone else ends where they started. Nothing moves without a line in the record
  naming why.
- **Deciding.** `play.outcome.decidingMatchup` maps straight across.
- **Foreground.** At most three: the deciding pair, plus the ball carrier if not already among them.
  `04` §9's cap is met **by construction** — the list is built from those three sources and takes
  `prefix(3)`. It is not validated and it cannot throw, which is what keeps `choreograph` total.
- **Duration.** Derived from `outcome.secondsElapsed` and clamped, so a snap that consumed forty
  seconds of clock does not animate for forty seconds. The floor, ceiling and the clock-to-playback
  ratio are named constants in the anchor rules, not inline numbers — `CLAUDE.md` forbids a magic
  number here as firmly as anywhere else in the engine.

The template table itself is a constant in `SnapAnchors`, keyed on `SnapRole` and `Position`. It is
engine-side rather than view-side because it is part of what makes the anchor set deterministic and
testable; a template living in the view would be geometry the tests cannot see.
- **Sentence.** The VoiceOver equivalent P13 requires, built from the result, the yardage and the
  deciding matchup.

## 6. The read model and the view

`MatchDayReadModel` gains `playback: Playback?`, a presentation-space mirror of the anchor set with
`stableID` strings instead of `UUID`s and absolute 0...120 `x` values, validated in the same
throwing-init style the model already uses for actor counts and foreground caps.

`playback` is optional because it is genuinely absent before the first snap of a game. The view falls
back to today's static diagram, which is the correct thing to draw when nothing has happened yet.

In the view, `field` wraps its existing `ZStack` in `TimelineView(.animation)` and interpolates dot
positions from a normalised `t` over the play's duration. The `Canvas` that draws turf, rules, hashes
and numbers is untouched — it is already correct, and the play art is drawn over it.

The Speed control becomes live at 1x, 2x and 4x, scaling the rate. It is rendered
`isEnabled: false` today, which this replaces. Tactics stays disabled; it is not in this slice.

**Reduce Motion** drops the `TimelineView` entirely and renders discrete phases advanced by the Key
Moments control, per `04` §7's "Reduce Motion replaces travel, reveal and field animation with
discrete state changes". This is a separate code path, not an animation with its duration set to
zero, because the requirement is discrete *states* and not fast travel.

## 7. Data flow

The coach advances. The reducer resolves the snap and appends a `PlayRecord`. The provider
choreographs **that record** — a thing that has already happened — into a `Playback`. The view
animates it, then settles into the pre-snap state for the next snap.

Animation therefore always trails resolution. This is `03b`'s rule stated as a sequence: "The snap is
resolved first, the animation is choreographed to the recorded outcome second. Rendering cannot
change a result, and a test asserts it."

## 8. Error handling

`choreograph` is total. Every `SnapResult` case yields a valid set, and a test enumerates
`SnapResult.allCases` so a new result kind fails on the day it is added rather than the day someone
remembers it. There is no failure mode to handle because there is no input that can be malformed:
a `PlayRecord` that exists is a snap that resolved.

Read-model validation is the boundary that can fail, and it fails the way the model already fails —
by throwing on a wrong actor count, a duplicate identifier, or a foreground list over three.

## 9. Testing

`Tests/SimTests/Suites/SnapAnchorTests.swift`:

1. **Render cannot change the outcome.** P13's named gate. Choreograph a record, re-run the reducer
   over the same seed and state, assert the outcome is identical.
2. **Byte-identical determinism.** Encode two independently-constructed sets from the same record
   and compare bytes, per the gap register's "byte-identical across renders".
3. **Never contradicts the box score.** `endSpot - LOS == outcome.yards`; the carrier in the anchors
   is `outcome.ballCarrierID`; an incompletion has no `carry` segment; a sack's end spot is behind
   the line.
4. **Twenty-two actors, at most three foregrounded**, enumerated by construction over generated
   snaps. `CLAUDE.md`'s coverage-boundary rule forbids a hand-listed sample here.
5. **Every `SnapResult` case** produces a valid set, driven from `allCases`.
6. **On-field bounds.** Every `FieldPoint` inside 0...100 and 0...1.

## 10. What this design will not claim

- **The 16.7 ms figure is D4's frame ceiling.** The headless suite can assert the choreograph and
  interpolation *compute* budget. It cannot measure a rendered frame. The result will be reported as
  compute-only, and the frame ceiling will remain unverified until a device run.
- **`04` §9's owner walkthrough is an owner action.** Whether the field reads as a football field on
  a phone, and whether the line of scrimmage is legible as a line, are the presentation questions
  P13 says no test can answer. A written walkthrough script is the deliverable; a claim that it
  happened is not.

## 11. Files

| File | Change |
|---|---|
| `docs/03-MATCH-ENGINE.md` | New §9, the anchor contract |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | §9's "once G-06 lands" caveat updated |
| `Sources/FootballSimCore/Engine/SnapAnchors.swift` | New |
| `Sources/ProFootballCoachUI/ScreenReadModels.swift` | `MatchDayReadModel.playback` |
| `Sources/ProFootballCoachUI/MatchDayView.swift` | `TimelineView` playback, live Speed, Reduce Motion path |
| `Sources/CoachWorldApp/CoachWorldMatchProvider.swift` | Anchor to playback mapping, direction applied |
| `Tests/SimTests/Suites/SnapAnchorTests.swift` | New |
| `docs/STATUS.md` | What is verified and what is not |
