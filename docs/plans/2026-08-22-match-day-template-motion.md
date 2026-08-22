# Match Day template motion

Owner directive, 2026-08-22: the 2D animation "does not move like players; players stop moving after
the play, they do not follow the play to the end, nor do the tackles look like tackles." Reviewed on
a booted iPhone 17e against a real build, and measured against the engine over 200 resolved snaps.
Canon amended first (`03` §9.6-§9.8, `04` §9) in 928105b. This is the build plan.

## What was measured

| Fact | Number | Where it comes from |
|---|---|---|
| Actor-snaps with `end == start` | 2,727 of 4,400 (62%) — **13.6 of 22 per snap** | `SnapAnchors.movement` returns `(start, [])` for `.coverage`, `.runFit`, `.decoy`, `.kicker`, `.blockLeverage` |
| Coverage (CB, S) still | **100%**, 0.0 yd mean | same |
| Run fit (LB) still | **100%**, 0.0 yd mean | same |
| Decoy still | **100%**, 0.0 yd mean | same |
| Passer still | 97%, 0.1 yd mean | `.passer` only moves when he is also the carrier |
| Blocker still | 57%, 0.6 yd mean | only a *beaten* blocker moves, 1.5 yd |
| Movers drawn as one constant-velocity straight line over the whole playback | 1,342 of 1,673 | no interior waypoint, and `position(of:at:)` is linear |
| Tackles credited to an `edgeRusher` | **200 of 200** | see T1 |

Two further defects found in the same pass:

- **T1 — every tackle in a game is made by the same man.** `SnapResolver.yardsAfterContact` records
  `defenderID: tackler.id` where `tackler = pursuit.first`, regardless of which defender in the
  break-tackle chain actually made the attempt; `assignment.pursuit` is `ranked(personnel.defense)`,
  best-overall-first. So the highest-rated defender on the field is the recorded tackler on every
  snap, and therefore the only defender the animation ever moves. **Fixing this moves
  `playByPlayFingerprint` and requires a determinism re-pin.**
- **T2 — tokens are labelled with role codes**, not position shorthand. `roleLabel` in
  `CoachWorldMatchProvider` emits `B R CV FIT RR D P`; `MatchDayView.actorToken`'s own doc comment,
  MATCH-DAY.md §4 and `04` §6.5 #18 all specify `LT LG C RG RT QB RB X H Z TE` /
  `RE NT DT LE W M N RC LC FS SS`.

Two presentation observations, no canon question attached:

- The offensive line sits at the LOS and the defensive front 1 yard beyond it (~7 pt at the install
  floor), so the two lines interleave into one column of chips rather than reading as two lines.
- Playback runs ~1.6 s (everything clamps to `minimumPlaybackSeconds`) then holds a completely
  static field for ~2.9 s. Roughly a third live, two thirds frozen.

## Tasks

Each is one commit. Engine work is TDD: failing test first, in `SnapAnchorTests` unless named
otherwise.

### 1. Stride profile — `AnchorRules.ease`

One rules constant and one pure function, applied to the *global* playback fraction by both
`SnapAnchors.position(of:at:)` and the view's `MatchDayView.position` / `ballMark`. Global rather
than per-leg so an actor and the ball he carries warp identically and cannot desynchronise — the
property §9.6 constraint 3 asks for.

Test: `ease` is monotonic, fixes 0 and 1, and is strictly slower than linear in the final fifth
(deceleration into contact) and faster than linear off the snap.

### 2. Everybody moves — `SnapAnchors.movement`

Give every role a template path. Phase timings come from the existing `snapFraction`,
`handoffFraction`, `releaseFraction` so a route ends when the ball arrives, not when the whistle
blows.

- `.passer` — drops to `passerDepth` behind the line by `releaseFraction`, then holds. A quarterback
  always drops back; 97% still is simply wrong.
- `.routeRunner` — reaches the recorded air-yard depth **by `releaseFraction`**, then continues on a
  shallow drift. Depth stays recorded; only the timing and the tail are template.
- `.rusher` — closes by `releaseFraction` rather than over the whole playback.
- `.blocker` — a step into contact at the line even when he won; a beaten blocker keeps his 1.5 yd
  push, unchanged.
- `.decoy` — a back who did not carry leads toward the play side; a receiver decoy runs a short
  route.
- `.coverage`, `.runFit` — align, then converge toward the end spot and **stop short of it** by
  `AnchorRules.pursuitStandoffYards`. This is the §9.6 constraint-2 line: visibly chasing, visibly
  not the man who made the stop.

Tests: no actor is still on a snap that had a carrier; no actor other than the recorded tackler ends
within `pursuitStandoffYards` of the end spot; the recorded tackler still ends exactly on it; a
carrier who won his duel still has nobody reach him.

### 3. T1 — the recorded tackler is the man who made the attempt

`yardsAfterContact` records `defender.id`, not `tackler.id`. Re-pin `playByPlayFingerprint` fixtures
and any calibration band that moves. **If a calibration band moves outside its stated tolerance,
stop and escalate — do not retune the band to fit.**

Test: over N snaps with a mixed-rating defense, recorded tacklers span more than one position group.

### 4. T2 — position shorthand on the tokens

`roleLabel` → a position-shorthand mapping, enumerated from `Position.allCases` by construction so a
position added later fails the test the day it is added, per CLAUDE.md's coverage-boundary rule.

Test: every `Position` maps to a distinct non-empty shorthand; offense and defense shorthands match
the sets `04` §6.5 #18 names.

### 5. Formation legibility

Widen the gap between the offensive line and the defensive front so they stop interleaving. Existing
`SnapAnchorTests` assertions ("the offensive line stands on the line and the defence stands beyond
it") must stay green.

### 6. Playback timing

Raise `minimumPlaybackSeconds` so plays stop clamping to the floor, and cut
`MatchMetric.autoAdvanceDwellSeconds`. **Measure the real inter-snap gap on device first** — the
~2.9 s observed includes app latency that is not the 1.2 s dwell, and changing the dwell without
measuring would be a guess-fix.

## Gates

Build green, `scripts/verify.sh` green, both legal tests green, determinism pin re-pinned and
explained, calibration bands unmoved or escalated, and a fresh device capture showing the same drive
before and after.
