# Port Log

Tier C of the v4 brief says the prior implementation carries no authority and **silence means
rewrite**. It also requires justification in **both** directions: a logged reason to port, and — after
the adversarial review of the v3 prompt — a logged reason to discard.

This file is that log. It is written before P0 so the phase knows what it is rebuilding and what it
is lifting.

**Default is rewrite.** Nothing is ported because it exists. Each entry below names what would be
lost by rebuilding it, and what was checked to be sure that is true.

---

## Ported — with the reason

### 1. `Support/SeededRandom.swift` — port substantially unchanged

**What would be lost by rebuilding:** the fix to the bug that made the previous save system
unreproducible, and which no in-process test could see.

`UUID.hashValue` is salted per launch in Swift. The prior build seeded AI free-agent bidding from it,
so a single save produced a different league every time the app started — while every in-process
determinism test passed, because within one process the salt is constant. The fix is
`SeededRandom.seed(from:)`, which mixes the raw UUID **bytes** with FNV-1a. That is Tier A's
determinism constraint made real, and rediscovering it costs a debugging cycle that has already been
paid for once.

**What was checked:** the implementation is SplitMix64 with correct constants; `int(in:)` uses
rejection sampling rather than modulo, so wide ranges are unbiased; `uuid()` stamps the version-4 and
RFC-4122 variant bits, so seeded identities read as ordinary UUIDs; `gaussian(_:in:)` resamples
rather than clamps, avoiding the pile-up at range edges that clamping produces. The whole generator
is one `UInt64`, so a save can resume the exact stream.

**Changes on port:** none required. Add `RandomNumberGenerator` conformance if the new engine wants
stdlib interop, and extend `seed(from:)` to take the hierarchical seed path `03` §3 specifies
(`leagueSeed → seasonSeed → weekSeed → gameSeed → driveSeed → snapSeed`).

### 2. `Support/CodingSupport.swift` — port substantially unchanged

**What would be lost:** a subtle determinism defect that is easy to reintroduce and hard to diagnose.

Swift encodes a dictionary whose key is not `CodingKeyRepresentable` as a flat
`[key, value, key, value…]` array **in hash order**, which differs run to run. The new model will be
full of `[UUID: …]` maps exactly as the old one was. Without the `UUID: CodingKeyRepresentable`
conformance, save bytes churn between runs and no byte-level determinism test can hold.

**Changes on port:** none. Keep `JSONEncoder.stable()` with `.sortedKeys`.

### 3. `Tests/SimTests/TestKit.swift` — port, and treat as D11(a)'s answer

**What would be lost:** the ability to run tests at all in this project's actual environments.

Neither XCTest nor swift-testing ships with the Swift Command Line Tools — both live inside Xcode.
The harness is ~50 lines, has zero dependencies, reports real pass/fail counts, exits non-zero on
failure, and runs as an executable target via `swift build && swift run -c release SimTests`. It
carried 224 tests and 13,226 assertions in about 100 seconds.

**Changes on port:** keep the assertion API surface; drop `testAsync`'s semaphore if the new engine
has no async surface (it is documented as deadlock-prone against `@MainActor` and the new engine is
synchronous by design, per `03b` §3).

**Note a defect to fix on port:** `Package.swift` currently carries contradictory comments — the
header says "Tests use swift-testing (bundled with the toolchain)" while the target comment says
XCTest and swift-testing both require full Xcode. The second is correct. Fixed in this commit.

### 4. The `hashValue` source-scanning test — port the idea, relocate it

Currently buried in `Tests/SimTests/Suites/DynastyTests.swift:603–628`, which is the wrong home for a
build-wide invariant. `03b` §1 requires four source scans (no SwiftUI in the engine, no `hashValue`
in seeding, no ambient `UUID()`/`Date()` in the engine, no design-token literals in views). Put all
four in a dedicated contract suite.

**Port the idea, not the implementation.** This scan has two defects that each shipped green against
real violations, documented in `03` §3.5: it matches
`line.contains(".hashValue") && !line.contains("//")`, so a trailing comment disables it; and it
never looks for `UUID()`, which is how a call-site `PlayEvent(id: UUID(), ...)` and four
default-valued engine initialisers survived a green suite. The replacement strips comments and ships
a self-test that fails on a planted offender.

---

## Knowledge ported, code discarded

These are Tier B: the numbers and methods transfer, the implementation does not.

| Source | What transfers |
|---|---|
| Calibration assertions in `Tests/SimTests/Suites/` | The pro-tier bands themselves, extracted with file and line in `01-RESEARCH.md` §6.4. `03` §5 starts from them rather than re-deriving. |
| The ten-season soak | The **method** — which invariants are worth asserting across seasons: ratings, ages, roster sizes, cap legality, churn, save size. `03` §6 extends it to 20 seasons and both tiers. |
| Save-size work | The lesson, not the code: unbounded free-agent pools and news feeds took saves to 8.3 MB; bounding them brought it to 2.3 MB. D7 gives every growable collection a stated bound. |
| Cap laundering defences | The **attack**, which a rewrite would have to rediscover: practice squad as a place to hide a contract, dead money erased by release, an offer validated against the cap and never charged. |
| Carousel invariant | A coach whose contract expires always has at least one offer or an explicit year out. Without it, saves soft-lock. |
| `Generation/NameBank.swift` | **A worked example of the legal guardrail failing quietly.** See below — this is the most useful thing in the file, and it is why P2's collision test is a gate rather than a checklist item. |

### The name bank, as evidence for P2

Found by a pre-push audit on 2026-08-09. `Sources/FootballSimCore/Generation/NameBank.swift` is
deleted by P0 along with the rest of `Generation/`, so nothing here is a patch request. It is
recorded because it demonstrates, in shipped code, exactly how `CLAUDE.md`'s guardrail fails when it
is prose rather than a test.

**Two failures, both under a comment asserting the opposite.**

1. The file header states *"Everything here is invented or generic — no real player is referenced."*
   The generator takes a cross product of ~60 first names and ~60 last names, all drawn from the same
   naming pool professional football actually draws from. A cross product of plausible names
   **cannot** guarantee that claim, and does not. The defect is not the collision — it is the
   unconditional assertion, with nothing checking it.
2. `colleges` is commented *"Fictional alma maters"* and contains **Delta State**, **Pine Bluff**,
   **Western Reserve**, **Whitewater**, **Old Dominion Tech** and **Rockford** — real NCAA
   football-playing institutions or a one-word variant of one. These strings render on a player card
   as the player's college, which is product content, not research.

**What P2 must take from it:**

- The collision test enumerates the **generated output**, not the source arrays. Reading a list and
  judging it fictional is what produced both failures above.
- Every generated field that reaches a surface is in scope — player name, coach name, and **college
  or alma mater**, which is the field that slipped here.
- A comment asserting compliance is not compliance. Where the guardrail is claimed in a doc comment,
  the same claim must be a named assertion in the legal suite, or the comment comes out.

---

## Discarded — with the reason

Tier C's default, applied deliberately rather than by silence.

| Area | Reason for discarding |
|---|---|
| `Model/` (Player, Team, League, Contract, Staff, …) | Pro-only by construction: 32 teams, divisions, cap. The new model is college-first with ~134 programmes, scholarships, eligibility clocks and NIL. Reshaping costs more than writing. |
| `Rules/` | Same — `LeagueRules`, `TeamTable` and `Scenario` encode the old scope. The rules-module *pattern* survives; the contents do not. |
| `Engine/GameSimulator`, `PlayCaller`, `PlayMatrix` | D2 chose hybrid assignment/leverage resolution with per-matchup causality the UI can narrate. The prior simulator resolves plays without that structure, so the thing `04`'s match view needs most is exactly what it cannot supply. |
| `Arcade/` (SnapKernel, Choreographer, Routes, Coverage, Pocket, RunLanes, Openness, …) | The mission forbids direct control. **But see the note below — this is the discard that deserves the most scrutiny.** |
| `Generation/` | Pro-only name banks and league factory. D6's endogenous identity (archetypes, map, traditions, rivalries) is a different system. |
| All of `Sources/ProFootballCoachUI/` | 9/20 on the rubric, and `04` rebuilds the design system from zero with a contract the old layer cannot satisfy. |

### The arcade discard, examined properly

This is the largest single discard and the one most likely to be wrong, so it gets more than a table
row.

> **UPDATE 2026-08-09 — the experiment at the foot of this section was run, and two of its three
> reasons did not survive.**
>
> This section ended by saying: *"the cheap experiment is to compile `Arcade/` first, once a
> toolchain exists, and see what falls out."* A toolchain exists. It was run.
>
> **`Arcade/` compiles, and its tests pass.** `swift build` compiles all ten files under
> `Sources/FootballSimCore/Arcade/` — the build log names `Choreographer.swift` directly.
> `Tests/SimTests/main.swift` registers `runArcadeTests()`, `runArcadeFieldTests()` and
> `runArcadeWatchTests()`; they carry **90 of the suite's tests** (29 + 48 + 13) and they are inside
> the `299 tests, 18412 checks, all passed` result.
>
> So of the three reasons given below:
>
> | Reason | Status |
> |---|---|
> | Written to serve a thumb, not a coach — `DefensiveInputs`, `Pocket`, timed-window tuning | **Stands.** Mission-level, and on its own sufficient. |
> | "It has never been compiled" → unknown defect surface | **False.** It compiles. |
> | "Phase 4C was added after the last build that worked" | **False as an inference about the code.** The 70 MB artifact was stale; the code was not. The symbol table below is evidence about that *artifact*, and nothing more. |
>
> **The discard still holds, on the first reason alone** — the mission forbids direct control, and no
> compile result changes that. But it must be justified that way and not by the other two, and one
> consequence deserves the owner's attention rather than being buried: D2 needs per-matchup
> resolution (protection duels, route-versus-coverage, run lanes) and `04` §5.3 needs a sack drawn as
> *the protection duel that lost*. `SnapKernel` is a working, tested implementation of exactly that
> geometry. Whether the right move is "rewrite the model for a coach-facing engine" or "port the
> spatial layer and strip the input layer" is now a live question with evidence on both sides, where
> before it was settled by a fact that turned out to be wrong.
>
> Nothing below is deleted; it is the reasoning the decision was made against, and the symbol table
> remains true of the artifact it describes.

**What is being thrown away:** `SnapKernel` and its spatial layer — formations, routes against live
coverage, per-matchup protection duels, run lanes, carrier pursuit, openness scoring. Pure, seeded,
headless-testable, with the engine still owning every probability and the field only measuring.

**Why that is uncomfortable:** `01-RESEARCH.md` §6.0 found the arcade layer held about **99% of the
previous build's decision volume**, and D2's chosen architecture needs *exactly* per-matchup
resolution — protection duels, route-versus-coverage, run lanes. That is a description of
`SnapKernel`.

**Why it is still discarded:** it was written to serve a thumb, not a coach. Its outputs are shaped
for input timing and aiming (`DefensiveInputs`, `Pocket`, the timed-window tuning in `ArcadeTuning`).
And it has **never been compiled** — which is no longer an inference from `STATUS.md` but a measured
fact:

> The repository carried 70 MB of committed Xcode build products
> (`build/Debug-iphonesimulator/`, an `arm64-apple-ios-simulator` build of both library targets).
> Symbol counts in `FootballSimCore.o` (3.9 MB) and, independently, in the 926 KB `.swiftmodule`:
>
> | Symbol | `.o` | `.swiftmodule` |
> |---|---|---|
> | `SeededRandom` | 570 | 35 |
> | `GameSimulator` | 409 | 22 |
> | `PlayCaller` | 61 | — |
> | `LeagueFactory` | — | 7 |
> | **`SnapKernel`** | **0** | **0** |
> | **`Choreographer`** | **0** | **0** |
> | **`RunLanes`** | **0** | **0** |
> | **`Openness`** | **0** | **0** |
> | **`Pocket`** | **0** | **0** |
>
> Ten source files are tracked under `Sources/FootballSimCore/Arcade/`. None of them appears in the
> last artifact a compiler produced, while the rest of the engine does. Phase 4C was added after the
> last build that worked.

Porting code no compiler has ever seen into the foundation of a rebuild inherits an unknown defect
surface at the worst possible layer.

*(Those artifacts have since been untracked and gitignored — they were stale, 70 MB, and actively
misleading about what had been built.)*

**What is salvaged instead:** the *model*, not the code. `03` §1's matchup table is the same idea
expressed for a coach-facing engine, and the honesty invariant — the field measures, the engine owns
every probability, rendering cannot change a result — is carried forward explicitly as a test.

~~**If the owner disagrees**, the cheap experiment is to compile `Arcade/` first, once a toolchain
exists, and see what falls out. Until something has compiled it, porting it is a bet on code no
machine has ever checked.~~

**Run 2026-08-09. It compiles; 90 tests pass. See the update box at the head of this section.** The
bet is no longer on unchecked code, so the discard is now carried by the mission constraint alone.

---

## Not yet dispositioned

`Sources/` is still in the tree. Deleting it is P0's business and P0 has not run — and deleting 90
files is not something to do silently. P0 should remove everything not named in the ported list
above, in one commit, so the diff is legible.

### The deletion commit must leave a retrieval address — **owner decision, 2026-08-09**

Asked and answered: `Arcade/` is **deleted in P0**, and the discard is carried by the mission
constraint alone (see the update box above — the "never compiled" reason is false). It is deleted
rather than quarantined because a non-canon path in the tree is how a cold builder builds the wrong
game, which is the whole reason `docs/DOC-MANIFEST.md` exists.

Deleting working, tested code is only safe if it stays findable. **P0's deletion commit therefore
owes this file three things, written back here in the same phase:**

1. The **commit SHA** of the deletion, so `git show <sha>` retrieves any file.
2. The **file list** removed, so nobody has to guess what was there.
3. The **suite counts before and after** — currently `299 tests, 18412 checks`, of which 90 tests are
   arcade — so a shrinking suite is a stated number rather than a silence.

P3 is the phase that designs per-matchup resolution, and it is the phase that should read
`SnapKernel` back out of history before deciding how much of that geometry to rebuild.

**Done in P0.**

- **Deletion commit:** `37b10c3` — `git show 37b10c3` retrieves any deleted file;
  `git show 37b10c3^:Sources/FootballSimCore/Arcade/SnapKernel.swift` retrieves one directly.
- **Files removed:** 88 of 93 tracked (72 of 74 under `Sources/`, 16 of 19 under `Tests/`), 25,579
  lines. Full list: `git show --stat 37b10c3`.
- **Suite before:** 324 tests, 18,631 checks. **After:** 11 tests, 16 checks. The difference is the
  90 arcade tests plus every suite covering the discarded model, engine, generation, persistence and
  UI. What remains is `SeededRandomTests` alone; P0's later tasks add three suites back.

The plan document `docs/plans/2026-08-09-p0-foundation.md` recorded the starting state as 299 tests /
18,412 checks over 88 tracked files, measured 2026-08-09. Re-measuring at the top of P0 found 324 /
18,631 over 93 files. The plan told the executing session to re-run rather than trust it, which is
why the numbers above are the measured ones and not the written ones.

## 2026-08-18 — Floodlit Surfaces + Match Day handoff, milestone 1

Source: `design_handoff_floodlit_surfaces_and_match_day/` (README.md, MATCH-DAY.md,
FLOODLIT-SURFACES.md). Milestone 1 only — tokens and Match Day. Surfaces by family (milestone 3)
have not started; `ScreenRegistry.swift` is unchanged.

**Doc-first amendment.** `04-UX-AND-DESIGN-SYSTEM.md` gained new section 6.1b before any code
changed, per `CLAUDE.md`'s doc-first rule. It records the Match Day broadcast register — the
handoff's glass-over-turf treatment superseding §6.1a's "BROADCAST radius stays 0" for Match Day
only — the Floodlit colour ramp the handoff adds, the six new `CutCorner` presets, the re-derived
844 x 390 frame offsets, and one refusal: the handoff's `ink-3` `#65788F` measures 4.37 / 4.23 /
3.58 on page/work/raised and fails 4.5:1 on every ground it is drawn on. `content.quiet` `#7A8A9E`
ships in its place everywhere the handoff writes `ink-3`.

**Tokens.** `DesignTokens.swift` gained `CoachWorldTokens.Frame` (the 844x390 offsets),
`.Gap` (the handoff's literal gap ladder, deliberately not a 4/8 grid), `.Pad` (per-surface
padding), `.Motion` (the one easing curve, three durations), `.Heat` (the 40-99 band function),
`.DisplaySize` (the literal px scale, resolved through `.display()`/`.figure()` rather than
Archivo Narrow / IBM Plex Mono), and `.Floodlit` (the turf/gold/ball/club/opponent hues no
existing role name could carry). `CoachWorldCutCorner` gained `.card`, `.alert`, `.block`,
`.wide`, `.actionSmall`, `.playCard`. `coachWorldFloodlitPanel` took a generic `shape` parameter
(defaulted to `.panel`) so Match Day furniture can ask for `.card`/`.playCard` through the same
modifier every other glass panel already uses.

**Match Day.** `MatchDayReadModel` gained `kind: MatchGameKind`, `tier: MatchTier`,
`event: EventBadge?` (validated: required iff `kind != .regular`), `callInBudget:
CallInBudget?`, `controlDepth: MatchControlDepth`, and `Playback.BallLeg.apexHeight` (0 = grounded,
1 = apex; `height(at:)` returns a parabolic in-between so the model, not the view, drives lift).
New views: `FieldPlane` (the eight-layer turf stack, rasterised via `.drawingGroup()` per
`BUILD.md`'s heaviest-thing-in-the-app warning), `EndZonePaint`, `FieldMark` (five game-kind
variants), `PlayerToken`, `BallToken` (the lens silhouette, not an ellipse), `ScoreBug` (five
variants), `CallInBudgetBug`, `ControlDepthSelector`, `MatchLowerThird`, `CommittingAction`. The
standard (non-AX5) layout changed structurally from stacked chrome rows beside the field to a
full-bleed field with glass furniture floating above it, per MATCH-DAY.md section 1 ("the field
fills the frame, glass furniture sits above it"); the AX5 layout keeps the prior stacked,
scrollable structure, which the render-recorded-match contract requires.

**Approximated, not silently diverged:**

- The render-recorded-match skill's gate fixes Match Day at **exactly five primary controls**
  (Speed, Pause, Key Moments, Take Over, Tactics), asserted by `MatchDayReadModel`'s own
  validation (`controls.count == MatchDayControlID.allCases.count`). The handoff draws a
  different furniture set (call-in budget bug, control depth selector, halftime chip, speed
  cycle, "NEXT CALL-IN", the committing action) with no 1:1 mapping to the five. The five are
  preserved and remapped onto the handoff's positions: Speed to the speed-cycle pill, Key
  Moments to the committing action (its `.value`/`.isEnabled` already carried "Next
  snap"/"Call-in pending" before this milestone), Pause and Take Over to small glass icon
  chips, Tactics to the halftime chip. The handoff's separate "NEXT CALL-IN" button has no
  analogue — a sixth control would break the validated five-control shape — and was dropped;
  the committing action's own label already carries that meaning.
- `MatchControlDepth` cycling emits one shared `controlDepthIntentID` regardless of which of the
  three cells was tapped, matching every other Match Day control's one-intent-per-control
  convention. Selecting an exact value (rather than cycling) is provider wiring the handoff does
  not specify.
- `CoachWorldMatchProvider` was given `tier` (from `session.tier`, a real fact). `kind` and
  `event` were left at their `.regular`/`nil` defaults — mapping `CompetitionStage` to
  `MatchGameKind` needs real postseason names, and the handoff itself flags "The Example Bowl",
  "EC", "44th annual" as fixture-cast placeholders needing a product-owner decision before ship.
- Player/ball vertical placement uses two different mappings depending on layout: the standard
  layout's full-bleed field applies MATCH-DAY.md section 2's `y% = 10 + v * 0.80` band so tokens
  stay clear of the floating scorebug and lower third even where the field itself paints edge to
  edge; the AX5 layout's dedicated, chrome-free field frame uses the plain 0-1 span it always
  did. This is a real difference in where the same `yFraction` lands on screen between the two
  layouts, not an oversight.

**A confidence review caught one real bug before this landed.** The design's scorebug, end
zones and player tokens are drawn "our cell" versus "their cell" — MATCH-DAY.md section 3's own
language. The first pass keyed that off `MatchDayReadModel.home`/`.away` directly, which is wrong:
`home`/`away` name which team owns the venue, and this codebase already tracks that separately
from which program the coach works for (`session.controlledSide`, `careerArc.currentJob`) — an
away game is still "ours". Styling by literal `home` would have painted the *opponent* gold and
the coach's own team as neutral navy on every away game. Fixed by adding
`MatchDayReadModel.perspective: MatchSide` (defaulted `.home`, so every existing call site keeps
compiling unchanged), wiring `CoachWorldMatchProvider` to set it from
`state.careerArc.currentJob?.organisationID` against `game.awayID`, and rereading every "ours"
check in `ScoreBug`, `EndZonePaint`/`identity(for:)` and the field's `actorToken` off `perspective`
instead of `isHome`. Caught by re-tracing "which team's colour goes where" against how `home`/
`away` are actually populated elsewhere in the codebase, not by a test — no test asserts on this
view-layer colour logic today, which is itself worth naming as a gap rather than closing silently.

**Verified:** `swift build` (debug, clean) and `swift build -c release` both compile. The
no-argument `SimTests` run (`--design-contracts`, `--core-contracts`) was run in **debug** mode
only — `swift run -c release SimTests`, exactly as `scripts/verify.sh`'s `full` lane invokes it,
fails in this environment with `error: module 'ProFootballCoachUI' was not compiled for testing
[#ModuleNotTestable]` on a completely clean worktree with a fresh `--scratch-path`, i.e. before any
change in this milestone. This is a pre-existing environment defect, not a regression; release-mode
`SimTests` is unverified here for that reason, not because of anything this milestone touched.
`--core-contracts` and `--design-contracts` pass in debug with zero failures, after fixing one
symbol-register finding (two `Image(systemName:)` calls where `04` section 6.6 requires the two
Broadcast marks to be drawn shapes, not SF Symbols), six design-token-literal findings (magic
numbers that needed named constants), and the perspective bug above.

A full unattended no-argument debug run (897 tests, 769,735 checks) also completed twice, both
under background tasks whose output did not surface until well after this milestone's other work
was reported, so the result is recorded here rather than folded into the paragraph above. The
first ran on the code immediately before the perspective fix; the second, after it — same 897
tests, same 769,735 checks, same result both times. 892 of 897 passed, including
`ReadModelProviderTests`'s live `"a controlled checkpoint produces a live Match Day model"` test
(32 "Read model provider: identity" checks) and every portal, college, competition and career-arc
suite. The 5 failures are the same known hazard on both runs: a self-re-exec test tries to spawn
the `SimTests` binary at a path computed from the standard `.build` layout, and both runs used a
custom `--scratch-path` the re-exec logic does not account for (`NSCocoaErrorDomain Code=4, "The
file 'SimTests' doesn't exist"`) — matching the project's known self-re-exec scratch-path hazard,
not a regression. This is now a genuine green run of the full suite against the code as it stands,
not a traced-by-hand read.

**Visual check.** The app was built via `xcodegen` + `xcodebuild` for the iOS Simulator and run
through the existing `RootView` debug proof harness (`PROOF_SCREEN=match`), which boots straight
into `MatchDayView` with `CoachWorldSampleData.matchDay`. The first simulator used carried a
leftover accessibility text-size setting from earlier work in this repo, which correctly (per the
render-recorded-match contract) routed the app into the AX5 `accessibleLayout` rather than the new
full-bleed `standardLayout` this milestone built — a simulator-state artifact, not a code defect,
confirmed by erasing that simulator to factory defaults and re-launching, at which point the new
layout rendered: turf plane, painted "CAR" end-zone lettering, the gold line of scrimmage, the
staff call-in panel in its new glass treatment, and the gold committing action. That simulator's
device orientation itself did not rotate to landscape in this headless flow, so the captured
screenshot showed the content rotated 90° — worked around by capturing with `xcrun simctl io
screenshot` (which reads the true device framebuffer, 1320×2868 portrait) and rotating the file
90° counter-clockwise with `sips -r -90` rather than fighting the simulator's own display state.

**Two real layout bugs the corrected screenshot caught, both fixed:**

1. `topRightStack` (call-in budget bug, control depth selector, pause/take-over/tactics chips) and
   `staffCallInPanel` both anchored at the same `top: 12` on the trailing edge, so the panel — drawn
   later in the `ZStack` — fully hid the persistent furniture behind it whenever a call-in was open.
   MATCH-DAY.md section 5 states the panel starts at "top 122" *specifically so* the budget bug,
   control depth and halftime chip stay visible above it; a fixed offset equal to the furniture's
   own top inset could never satisfy that, since the furniture's height is not constant (the budget
   bug is conditional on `model.callInBudget`). Fixed with a `PreferenceKey` that reports
   `topRightStack`'s actual rendered height, read via `.onPreferenceChange` and used as the panel's
   top offset instead of a literal.
2. The call-in panel (244 pt wide, right-anchored) and `bottomRightCluster` (the speed pill and the
   gold committing action, right-anchored, narrower) share the same right edge and both reach the
   same bottom inset, so the panel — again drawn later — fully covered the committing action
   whenever a call-in was open. The committing action is already disabled in that state
   (`.keyMoments`'s control is gated on `pendingCallIn == nil` upstream in `CoachWorldMatchProvider`),
   so covering it is arguably the right *outcome*, but achieving that by stacking an opaque panel
   over a still-present, still-hit-testable button is a latent VoiceOver-order and hit-testing
   hazard regardless of what it looks like. Made the hide explicit: `bottomRightCluster` now only
   renders `if model.staffInterruption == nil`.

Neither bug was visible until the rotation was fixed — the earlier, sideways screenshots put
enough of the frame off-frame or foreshortened that the overlap did not read clearly. `--core-
contracts` and `--design-contracts` were re-run after both fixes and stayed green (both touch
layout only, not the read-model shape or the symbol/token scans).

### Side-by-side against the reference prototype

The reference was served over a local HTTP server (the browser pane refuses `file://` outside the
project) and rendered at its own 932 × 430 mock, then compared region by region against the
upright simulator capture. Six further divergences found; all six fixed.

1. **The scorebug was not drawing at all.** `CallInBudgetBug`'s inner `HStack` used
   `Spacer(minLength:)`, which is greedy — the bug stretched to the full frame width, and because
   `topRightStack` is drawn after `scoreBug` in the `ZStack` it painted straight over it. The
   entire top-left scorebug was invisible and I had read the wide dark band across the top as
   "the budget bug" rather than as a symptom. Fixed with `.fixedSize(horizontal: true,
   vertical: false)` so the panel hugs its content and the spacer collapses to its `minLength`,
   which is the gap the design actually asks for.
2. **Clock-cell type was oversized**: clock at 19 pt and down-and-spot at 14 pt against the
   handoff's stated 14 and 10. The oversize wrapped "1ST & 10 · CAR BALL" onto a second line and
   made the whole bug roughly twice its drawn height.
3. **Cell order was wrong.** The handoff's order is our cell, their cell, clock cell. The code
   ordered by `home`/`away`, so on a home game the opponent came first. Now ordered by
   `perspective`, the same fact the colour treatment already reads.
4. **The possession wedge led the cell instead of trailing it.** The handoff's stated order within
   the cell is rail, name, score, triangle.
5. **Player tokens carried jersey numbers, and only three of twenty-two carried anything.** The
   handoff is explicit — "labels are position shorthand, not numbers" — and the reference labels
   all twenty-two. The earlier reasoning for labelling only three (the 12 pt authored floor) does
   not survive inspection: this view already drew a 9 pt label on those three, so the floor was
   already being spent, and `04` section 6.2 exempts tracked uppercase micro-labels, which is what
   a position shorthand is. Two-letter shorthands also fit a 15 pt token where two-digit numbers
   did not — which is why the design specifies shorthands. All twenty-two now carry their position;
   foreground is a ring rather than being the only mark with text on it. Two supporting data fixes
   fell out of this: the live provider emitted `EDGE` (four characters, truncated to an ellipsis on
   the field) which is now `DE`, and the sample fixture's two identical `WR`s and its `SLOT` are now
   `X`, `Z` and `H`, per the handoff's stated vocabulary.
6. **The top-right stack was one row taller than the design's and buried the opponent's painted
   end-zone name.** Pause and Take Over were parked there purely because they are two of the five
   contract-fixed primary controls and needed somewhere to live; the design's top-right column is
   only the budget bug, the depth selector and the halftime chip, and it is short specifically so
   the end-zone lettering reads. They now sit in the bottom-right cluster, which is both closer to
   the design and closer to the thumb. This also supersedes the earlier note in this log that
   described Pause/Take Over as living in the top-right.

**One gap the comparison closed that was not a styling issue.** The handoff's lower third carries a
right-aligned `← WEEK` link, which had not been built. Checking why surfaced something worse: every
other surface in `CoachWorldAppRootView` takes an `onClose`, and Match Day took none — so there was
no way to leave the match screen at all. `MatchDayView` now takes an optional `onExit` (optional so
a caller with nowhere to go gets no dead control), the lower third draws the link when it is
supplied, and both the production root and the debug proof harness wire it to the coaching HQ.

## 2026-08-18 — Floodlit handoff, milestone 2: shared chrome and the eight patterns

Source: `FLOODLIT-SURFACES.md` sections 1 and 2. Milestone 2 only — the stage every management
surface renders inside, and the composition grammar those surfaces are built from. **No surfaces
were converted**; that is milestone 3, and `ScreenRegistry.swift` is unchanged in count and naming.

**Doc-first again.** `04` gains section 6.1c, which records the management chrome: the stage
geometry, the three worlds, the content-column widths, the flattened non-hero glass, the eight
patterns, and the derivation `844 − 115 − 20 = 709` so the content width stays right if the floor
ever moves. Three new fills are declared with measured ratios (`#11141E`, `#0B0D14`, `#04070C`).

**One accessibility carve-out is recorded rather than hidden.** The identity header's second row is
16 pt by design and its sibling links are 9.5 pt — far under the 44 pt minimum target. The row
height is load-bearing for the header's proportion, so the *visible* text keeps its drawn size and
each link carries a 44 pt hit area instead. Section 6.1c states the rule that makes this legal:
visible size and tappable size may differ; tappable size may not drop below 44.

**Registry.** `CoachWorldSurfaceFamily` and `CoachWorldScreenID.family` are new. The header's second
row is the whole of this game's navigation, so the grouping has to live where both the header and
the rail can read it, and the registry is the only thing that already knows every surface. It is
derived by an exhaustive `switch` rather than stored alongside, so a new case cannot be added
without the compiler asking which family it joins. `showsIconRail` carries the handoff's rule that
Title, Job Board and Offer sit outside the coaching week and so have no rail.

**New:** `FloodlitChrome.swift` (read model, `CoachWorldFloodlitSurface`, the three world backdrops,
identity header, pennant, icon rail, registered-not-built) and `FloodlitPatterns.swift` (Label3,
Row, Card, ArcGauge, AttributeDial, ShareBar, Pill, Flag, StaffVoice, CommittingAction, CostLine).
Three of the eight already shipped and were **not** rebuilt: the glass panel is
`coachWorldFloodlitPanel`, and the arc family's smallest and largest existing steps are
`CoachWorldRatingRing` and `CoachWorldMeter`.

**Two contract findings, both real, both fixed.** The suite caught them, not review:

1. `CoachWorldPennant` read `team.primaryColorHex` directly, bypassing `CoachWorldTeamIdentity` —
   which is exactly where the contrast floors live and where a generated pair that cannot be read
   is refused (`04` section 5). It would have painted an illegible pennant for precisely the
   generated pairs the identity type exists to catch. Now resolved through the identity type, with
   the neutral club field as the honest fallback and the *measured* ink for the dot rather than a
   fixed pale one.
2. A design-token literal in `FloodlitArcGauge`'s arc geometry, now a derived named constant.

**Three layout bugs the simulator caught, all fixed.** None were visible from the code:

1. The sibling links used `.frame(minHeight: 44)` for their tap target, which grew the header to
   44 pt per row and pushed it underneath the content column — the header and the first content
   row overlapped. Replaced with padding-out-then-cancel, so the hit area is 44 and the row stays 16.
2. `FloodlitAttributeDial` rotated its whole `ZStack` to place the arc's start angle, which turned
   the figure and its label upside down. Only the arcs rotate now.
3. The proof harness scaled the 212 pt hero dial into a 120 pt frame with `scaleEffect`, which
   shrinks the 7 pt stroke and the 34 pt figure with it — both stated sizes. The dial now takes a
   `diameter` and a caller with less room asks for a smaller one honestly.

**Verified:** package builds; `--core-contracts` (202 tests / 2220 checks) and `--design-contracts`
(29 / 610) green; the chrome and all eight patterns rendered together on a simulator via a new
`PROOF_SCREEN=chrome` proof surface, hosted on Scheme Book because it is registered-not-built and
so cannot collide with a real surface's composition.

**A capture-harness correction worth recording.** Mid-milestone I reported that Match Day had
regressed to a blank screen. It had not. The screenshot script's readiness check was gating on
brightness, which the plain-white iOS launch screen satisfies, so it was capturing the launch
transition rather than the app. The app log showed a clean launch and no crash throughout. The
check now waits for the launch screen to actually clear.

## 2026-08-18 — Floodlit handoff, milestone 3a: weekly command

The conversion seam, and the first of the six families (`FLOODLIT-SURFACES.md` section 3).

**The seam.** The chrome folded into `CoachWorldFloodlitStage` rather than becoming a wrapper type
around it. Three reasons, in order of weight: ground/world/grain/colour-scheme keep exactly one
owner, which is the invariant `AccessibilityReflowTests` already guards; converting a surface
becomes a one-line change at the call site; and views keep calling the symbol the conversion scan
recognises, so the partition cannot silently regress. `CoachWorldChromedSurface` gives a surface
`chrome` and `onNavigateChrome` with inline defaults, so an existing public initialiser keeps
compiling untouched and the caller opts in with `.floodlitChrome(_:onNavigate:)`.

**Provider.** `CoachWorldChromeProvider` builds the chrome from `CoachingHQReadModel` rather than
re-deriving identity from `GameState`. The week hub already answers "who are we, what is our
record, who is next", and resolving that twice is how two headers end up disagreeing about one
save. Rail entries and sibling links carry `route|<id>` intents that go through the same
`navigate(_:in:)` every other route uses, so a rail tap cannot reach a screen the router considers
unreachable.

`conference` became optional: it lives on `TeamProgrammeProfileReadModel`, not on the week hub, and
is not retained on every route. An absent conference is not a wrong conference, so the header omits
the slot rather than guessing.

**Converted (9 surfaces):** Coaching HQ, Inbox, Game Plan, Opponent Film, Opponent Report / Film
Room, Practice Plan, Team Health, Aftermath, Box Score. The film room delegates its whole
composition, so it passes the chrome through to the view that draws it rather than wrapping a
second stage around one that already has one.

**Two layout bugs the simulator caught:**

1. The chrome was added to the composition stack *before* the content, so the content painted over
   the identity header — the first capture showed only the header's second row, with the surface's
   own strip sitting where the programme name belonged. Content is drawn first now and the chrome
   over it: the chrome is the frame the surface sits in.
2. `CoachingHQView` kept drawing its own world strip under the new header, stacking two
   navigations. It now draws it only when no chrome is supplied, which is still the correct
   rendering for the un-converted path.

**Verified:** package builds; `--core-contracts` (202 / 2228) and `--design-contracts` (29 / 613)
green, with the conversion partition still reporting 62 converted / 0 pending; Coaching HQ captured
on a simulator inside the chrome.

## 2026-08-18 — milestone 3b: personnel

**Converted (8 surfaces):** Roster, Player Profile, Depth Chart, Development Plan, Staff Room,
Staff Market & Profile, Scheme Book, Personnel Packages.

Three of the eight are pure delegating wrappers (Staff Market over Staff Room, Scheme Book over
Game Plan, Personnel Packages over Depth Chart). They pass the chrome through to the view that
actually draws it rather than wrapping a second stage around one that already has one — the same
treatment the film room took in 3a.

`RosterView` carried its own world strip and now draws it only when no chrome is supplied, matching
`CoachingHQView`. Those two were the only surfaces in either family with a strip of their own; the
rest had no identity chrome at all before this.

**Verified:** `--core-contracts` (202 / 2228) and `--design-contracts` (29 / 613) green, partition
still 62 converted / 0 pending.

## 2026-08-18 — milestone 3c: recruiting (college)

**Converted (11 surfaces):** Recruiting Board, Prospect Profile, Shortlist, Contact & Visit
Planner, Class Overview, Signing Day, Portal Hub, Retention Decisions, Portal Market, NIL
Allocation, College Offseason.

Four of the eleven are wrappers over `CollegeOffseasonView` with a different title (Portal Hub,
Retention Decisions, Portal Market, NIL Allocation). They take the same pass-through treatment as
the other delegating wrappers rather than each growing a stage.

`RecruitingBoardView` was the third and last surface carrying its own world strip; it now draws it
only when no chrome is supplied.

**Verified:** `--core-contracts` (202 / 2228) and `--design-contracts` (29 / 613) green, partition
still 62 converted / 0 pending.

## 2026-08-18 — milestone 3d: pro management

**Converted (9 surfaces):** Cap & Contracts, Contract Negotiation, Roster Cuts & Transactions, Pro
Offseason, Pro Scouting Board, Draft Board, Draft Room, Free Agency, and the shared
`ProManagementView` the first and third of those wrap.

`ProManagementView` is not itself a registry surface — it is the composition Cap & Contracts and
Roster Cuts both render. It takes the chrome too, so those wrappers hand it down to the view that
owns the stage rather than each growing one. Cap, dead money and cuts share state, which is why
`FLOODLIT-SURFACES.md` section 3 says to port them together.

**Verified:** `--core-contracts` (202 / 2228) and `--design-contracts` (29 / 613) green, partition
still 62 converted / 0 pending.

## 2026-08-18 — milestone 3e: league

**Converted (12 surfaces):** League Map, Team / Programme Profile, Standings, Schedule, Rankings &
Playoff Picture, Bracket / Postseason, Competition Overview, Statistics & Leaders, Awards &
Honours, News, Realignment Event, World Search.

Rankings and Bracket are focus-scoped wrappers over `CompetitionOverviewView`; like every other
wrapper in this port they hand the chrome down to the composition that owns the stage.
`CompetitionOverviewView` itself is never rendered directly by the root — only through those two —
so it takes the chrome but has no wiring site of its own.

**Verified:** `--core-contracts` (202 / 2228) and `--design-contracts` (29 / 613) green, partition
still 62 converted / 0 pending.

## 2026-08-18 — milestone 3f: career (final family)

**Converted (15 surfaces):** Career Hub, Career Line, Job Security, Stakeholders, Promotion
Decision, Job Board, Offer, Record Book, Rivalries, Legacy History, Title / Continue, Settings &
Accessibility, Coaching Carousel, Coaching Tree, Appointment.

Most of this family are focus-scoped wrappers over `CareerHubView` or `LegacyHistoryView`. Four of
them (Coaching Carousel, Job Security, Promotion Decision, Stakeholders) bind the delegated view to
a `let` before branching on type size, so the chrome attaches at the binding rather than to a
branch.

**A trap worth naming.** `floodlitChrome` is declared on the concrete conforming type, so
`.frame(...)` — which erases to `some View` — must come *after* it. The first pass appended the
modifier at the end of the chain and eight files failed to compile. That failure was the good case:
had the modifier been merely reachable-but-ineffective rather than a type error, those surfaces
would have silently rendered without chrome. To be sure that is not true anywhere, a sweep now
checks that every type conforming to `CoachWorldChromedSurface` actually consumes its `chrome`
(either `chrome: chrome` into a stage, or `.floodlitChrome(chrome…)` onto a delegate). It reports
zero unattached.

**Not wired, correctly:** Title / Continue renders before a career exists, so there is no programme
to name and `chrome(for:in:)` would return nil anyway. It is also one of the three surfaces
`FLOODLIT-SURFACES.md` section 3 says carries no icon rail — with Job Board and Offer — which
`CoachWorldScreenID.showsIconRail` encodes and the composition honours by starting at the rail-free
leading edge.

**Milestone 3 complete.** All six families converted; the conversion partition reports 62 converted
/ 0 pending throughout.

**Verified:** `--core-contracts` (202 / 2228) and `--design-contracts` (29 / 613) green.

### Visual verification scope — stated plainly

Two families were confirmed **on a simulator**: Coaching HQ (weekly command) and Roster
(personnel), both rendering inside the chrome with the correct rail entry active, the correct
family siblings, and one navigation rather than two. The chrome-and-patterns proof surface covers
the grammar itself.

The other four families are verified by **compilation, the contract suites, and the attachment
sweep** — not by screenshot. That is weaker evidence and is named as such rather than implied. The
sweep is the part that makes it meaningful: it checks every type conforming to
`CoachWorldChromedSurface` actually consumes its chrome, so "it compiles" cannot hide a surface
that silently renders without one.

### Confidence review of milestone 3

Four things checked after the six families landed; two were findings.

1. **Every conforming type consumes its chrome** — swept mechanically, zero unattached. This is the
   check that makes "it compiles" mean something, because the failure mode here is silent.
2. **No surface takes chrome twice** — no file both passes `chrome:` into a stage and applies
   `.floodlitChrome` to a delegate. Clean.
3. **Nested scroll views at AX5 — a real defect, fixed.** The composition's accessible layout was a
   `ScrollView`, and every converted surface already scrolls its own accessible layout. That nests
   two vertical scrollers: the inner one swallows the drag and the header above it becomes
   unreachable at exactly the type size where reaching it matters most. The composition's AX layout
   is now a `VStack` and the content keeps its own scrolling.
4. **`PlayerProfileView` never receives chrome, and should not.** In production it is presented as
   a sheet from `RosterView`, and `04` section 6.4 clause 5 puts player, prospect and contract
   previews in a popover or detented sheet *rather than replacing the management screen*. A modal
   carrying an identity header and a navigation rail is a category error. It conforms — so a future
   full-screen route can supply chrome — but renders on the bare stage while it is a sheet. Named
   here so the gap between it and the section 3 table is a decision on the record rather than an
   omission.

`TitleContinueView` is the one surface rendered by the root without chrome, deliberately: it runs
before a career exists, so there is no programme to name.

### Full-suite result, and a correction

The no-argument suite completed on the six-family tree: **897 tests, 769,755 checks, 5 failures**,
all five the known self-re-exec scratch-path artifact (`NSCocoaErrorDomain Code=4, "The file
'SimTests' doesn't exist"`) that reproduces on an unmodified checkout. The run also reports
`AX5 contract: 62 landed, 0 pending` and `Floodlit conversion: 62 converted, 0 pending`.

Check count rose from 769,735 to 769,755 across milestone 3 — the twenty additional checks are the
registry's new family partition being exercised, not a suite that grew looser.

**Correction, recorded because it was stated aloud during the work.** Mid-verification I reported
that this run had "died mid-suite". It had not; it completed. I had tailed the output file at a
point where the harness had not yet flushed its summary, saw the process gone, and concluded a
crash. The same wrong call was made earlier in the session about Match Day regressing to a blank
screen, and the root cause is the same shape both times: treating an incomplete observation of a
long-running job as evidence of failure. The reliable signal is the harness's own totals line, and
that is what the wait loops now block on.

### Final-tree confirmation

Re-run after the last code commit (`b35fa2a`, the AX5 nesting fix), so the result covers the tree as
it stands rather than the six-family tree: **897 tests, 769,755 checks, 5 failures**, the same five
self-re-exec scratch-path artifacts, with `AX5 contract: 62 landed, 0 pending` and
`Floodlit conversion: 62 converted, 0 pending`. The Xcode app target also builds on the final tree,
and all three shipping SwiftPM targets compile in release.
