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

- **T1 — every tackle in a game is made by the same man.** `assignment.pursuit` is
  `ranked(personnel.defense)`, best-overall-first and blind to the play, and
  `SnapResolver.yardsAfterContact` always starts its break-tackle chain at index zero. So the
  highest-rated defender on the field is the recorded tackler on every snap, and therefore the only
  defender the animation ever moves. (This bullet first named `yardsAfterContact`'s `tackler.id` as
  the cause; that was wrong — see task 3 below, which is escalated rather than fixed.)
- **T2 — tokens are labelled with role codes**, not position shorthand. `roleLabel` in
  `CoachWorldMatchProvider` emits `B R CV FIT RR D P`; `MatchDayView.actorToken`'s own doc comment,
  MATCH-DAY.md §4 and `04` §6.5 #18 all specify `LT LG C RG RT QB RB X H Z TE` /
  `RE NT DT LE W M N RC LC FS SS`.

Two presentation observations, no canon question attached:

- The offensive line sits at the LOS and the defensive front 1 yard beyond it (~7 pt at the install
  floor), so the two lines interleave into one column of chips rather than reading as two lines.
- ~~Playback runs ~1.6 s then holds a static field for ~2.9 s.~~ **Withdrawn — measured wrong.** It
  is ~3.4 s live and ~1 s held, which is what the engine arithmetic says it should be. See task 6.

## Tasks

Each is one commit. Engine work is TDD: failing test first, in `SnapAnchorTests` unless named
otherwise.

### 1. Stride profile — `AnchorRules.ease`

One rules constant and one pure function, applied to the *global* playback fraction by both
`SnapAnchors.position(of:at:)` and the view's `MatchDayView.position` / `ballMark`. Global rather
than per-leg so an actor and the ball he carries warp identically and cannot desynchronise — the
property §9.6 constraint 3 asks for.

Test: `ease` is monotonic, fixes 0 and 1, and its *velocity* — not its position — is below the mean
at both ends with the peak between them. (The first draft of this line asserted position rather than
velocity, which is false: a decelerating profile is *ahead* of linear near the end.)

Landed as `AnchorRules.pathFraction(atPlayback:)`, and applied only at `MatchDayView.progress`, not
inside `SnapAnchors.position` — see the commit for why warping the engine's own path fractions would
have broken the ball-and-carrier invariant.

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

### 3. T1 — ESCALATED, NOT FIXED

The mechanism stated here was wrong. `tackler` is `pursuit.first` and `defender` is
`pursuit[min(attempt, count - 1)]`, which on attempt zero are the same man, so swapping them is a
no-op and shipping it as the fix would have claimed a repair that had not happened.

The defect is one level up, in `Assignment.assign`: `pursuit` is `ranked(defense)` — best-first, and
blind to the play — so the highest-rated defender on the field is first in the chain on every snap
of a game.

**Not fixed, and this is the owner's call.** Whoever is first in that list is whose `tackling` the
leverage reads, so any reordering moves the yardage distribution and the calibration bands with it.
Modelling pursuit by run gap, coverage and target is real engine work with its own gate; riding it
in on an animation fix would bury a calibration move in a commit nobody would think to look in.

Done instead: the misleading `tackler` alias removed, and the defect written down at the line that
causes it with what it would take to fix it (`825a959`).

### 4. T2 — position shorthand on the tokens

`roleLabel` → a position-shorthand mapping, enumerated from `Position.allCases` by construction so a
position added later fails the test the day it is added, per CLAUDE.md's coverage-boundary rule.

Test: every `Position` maps to a distinct non-empty shorthand; offense and defense shorthands match
the sets `04` §6.5 #18 names.

### 5. Formation legibility

Widen the gap between the offensive line and the defensive front so they stop interleaving. Existing
`SnapAnchorTests` assertions ("the offensive line stands on the line and the defence stands beyond
it") must stay green.

### 6. Playback timing — MEASURED, AND NOT DONE

The premise did not survive the measurement, which is why the task said to measure first.

The "~1.6 s live, ~2.9 s frozen" figure in the review above was read off a 5 fps contact sheet by
counting frames labelled `SNAP - IN PLAY` against frames labelled `RESULT`, and that label persists
into the next snap's setup, so it over-counted the frozen span badly. Measuring properly — mean
absolute frame-to-frame difference over the field band, at 10 fps, on the device captures — gives:

| | live burst | still gap between snaps |
|---|---|---|
| before | ~3.4 s | ~0.7-1.2 s |
| after | ~3.4 s | ~0.7-1.2 s |

which matches the engine arithmetic exactly: `durationSeconds` is `secondsElapsed x 0.55` clamped to
1.6-6.0, and a snap that burns 5-7 seconds of clock animates for 2.8-3.9 s. The 1.6 s floor almost
never binds, and the ~1 s hold is the 1.2 s `autoAdvanceDwellSeconds` doing exactly what it says
with no hidden app latency behind it.

So there is nothing here to fix, and changing either constant would be a guess-fix against a premise
the measurement refutes. **Not done, deliberately.**

The same measurement does carry the after-number that matters: mean motion magnitude per frame while
the field is live went from 0.68 to 1.24, so the dots travel about twice as far per frame as they
did.

## Gates

Build green, `scripts/verify.sh` green, both legal tests green, determinism pin re-pinned and
explained, calibration bands unmoved or escalated, and a fresh device capture showing the same drive
before and after.
