# SwiftUI performance audit — 2026-08-20

**Scope:** every file that imports SwiftUI under `Sources/` and `App/` (85 files, 21,285 lines of
SwiftUI plus 9,308 lines of composition layer), the shipped asset bundle, and all 51 local and 23
remote branches compared against `main`.

**Method:** code-first review against the `swiftui-performance-audit` smell catalogue. **No
Instruments trace was captured and no frame was rendered during this audit.** Every number below is
either a static count, a byte count taken from the working tree, or an arithmetic consequence of
one. Where a claim is a hypothesis about runtime behaviour it says so. `docs/STATUS.md` §"Two things
are not verified" already records that D4's 16.7 ms frame ceiling is **unmeasured** because the
headless suite runs on macOS and renders nothing; this audit does not change that.

**Audited at:** `agent/floodlit-injury-evidence` @ `c0f4334`, 33 commits ahead of and 138 commits
behind `main` @ `17e2d43`.

---

## Summary

The single largest finding is not a view — it is **156.2 MB of 1024x1024 team-logo PNGs**
(`P0-1`) that the branch adds and renders through a 20-to-44 pt chip. The second is that this branch
**predates the whole of `main`'s app-layer performance work** (`P0-2`): the memoised store, the
`availableScreens` root query, the coalesced autosave and the launch backup skip all exist on `main`
and none of them are here. Merged as-is, the branch reintroduces a measured 5,454 ms week advance
and a 5,259 ms match snap against a 1,200 ms auto-advance dwell.

Underneath those two, the code has a genuinely good spine — no `AnyView`, no stray implicit
`.animation`, no `.id()` churn, one disciplined motion vocabulary, `.equatable()` and `.drawingGroup()`
correctly applied to the static field plane, and a `TimelineView` that actually pauses when the snap
ends. The recurring defects are narrower and mechanical, and they share one shape: **a good pattern
exists in the repository and was applied once rather than to its whole class.** `selectedX` computed
properties linear-scan a collection and are then read a dozen or more times per body evaluation; 35
scrolling surfaces are built eagerly in a plain `VStack` while six reach for a lazy container; three
progress-bar primitives are each built on a `GeometryReader` and appear across seventeen per-row call
sites; and the `Equatable` + `.drawingGroup()` guard that makes `FieldPlane` cheap reached one of the
three backdrops and neither of the two overlays. Each of those is fixed at the primitive, not at the
call site — which is the same coverage-boundary rule `CLAUDE.md` already states for tests.

---

## Findings

Ordered by impact. Severity uses `04b`'s P0-P3.

---

### P0-1 — 156 MB of 1024 px logos rendered into 20 pt chips

- **Symptom (predicted):** large install size; a memory spike and a visible stall entering World
  Search; jetsam risk on the 844 x 390 install-floor device. Not yet observed on a device.
- **Cause:** `Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets` holds **166 imagesets, 156.2 MB,
  every one a 1024 x 1024 8-bit RGBA PNG with alpha, declared at a single `"scale":"1x"`** and no
  smaller variant. `CoachWorldTeamLogo` renders them at `compact = 20`, `medium = 32` or `large = 44`
  points — at 3x that is 60, 96 or 132 device pixels against a 1024 px source: **7.8x linear, 60x by
  area** at the largest size the app ever draws.
  Decoded, one logo is 1024 x 1024 x 4 = **4 MiB**; all 166 resident is **664 MiB**.
- **Evidence:**
  - `Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets/*/Contents.json` — one `1x` entry each,
    no `2x`/`3x`, no `preserves-vector-representation`.
  - [CoachWorldTeamLogo.swift:25](Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift#L25) —
    `image.resizable().scaledToFit()` then `.frame(width: size.rawValue, ...)`. No downsampling.
  - [CoachWorldTeamLogo.swift:9](Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift#L9) — the size
    enum: `compact = 20`, `medium = 32`, `large = 44`.
  - `Tools/TeamLogos/generate_catalog.swift` writes the Swift map only; there is no resize step in
    the pipeline, and `Tests/SimTests/Suites/TeamLogoTests.swift` asserts squareness, alpha edges,
    uniqueness and family balance but **no pixel or byte bound**.
  - The blast radius is wider than the list screens: `FloodlitIdentityHeader.primaryRow`
    ([FloodlitChrome.swift:345](Sources/ProFootballCoachUI/FloodlitChrome.swift#L345)) draws a
    `.compact` logo, and the identity header is part of the shared chrome — so **every chromed
    screen** loads a 1024 px asset, not only the eighteen explicit call sites.
- **Fix:** downsample the source set to 256 x 256 (comfortable for a 132 px draw at 3x, with a 2x
  headroom for a future larger use) and let the asset catalogue keep them as a single scale.
  166 x ~35 KB is roughly **5 MB, a 30x reduction**; 128 x 128 would be ~2.5 MB and still exceeds
  every current draw. Add the missing bound to `TeamLogoTests` so this cannot regress — per
  `CLAUDE.md`'s coverage-boundary rule the assertion should enumerate the imageset directory by
  construction, not a hand-written list.
- **Validation:** re-measure the `.app` size, and capture Allocations while entering World Search
  before and after.

---

### P0-2 — the branch predates every app-layer performance fix on `main`

- **Symptom:** the app-path latencies `main` already fixed, still present here.
- **Cause:** `agent/floodlit-injury-evidence` branched at `91a108d` and is **138 commits behind
  `main`**. Commits `0e6953c`, `fc2cb2c` and `dfe3b76` are ancestors of `main` and **not** of `HEAD`.
- **Evidence** — four concrete divergences, each verified by diffing `main` against `HEAD`:

  | What | This branch | `main` |
  |---|---|---|
  | Screen read models | `rebuildScreens(from:)` builds **all 28** at the tail of every intent — [CoachWorldStore.swift:87](Sources/CoachWorldApp/CoachWorldStore.swift#L87), 33 provider calls | memoised per `revision`, one built on demand |
  | Route availability | `availableScreens(in:)` reads the store **44 times** — [CoachWorldAppRootView.swift:1068](Sources/CoachWorldApp/CoachWorldAppRootView.swift#L1068) | `CoachWorldReadModelProvider.availableScreens(from:)` answers from the root |
  | Autosave | `persist` calls `flush(reason: .explicit)` on every intent — [CoachWorldAppRootView.swift:1730](Sources/CoachWorldApp/CoachWorldAppRootView.swift#L1730) | deferred `scheduleFlush()` on a fixed deadline, so the coordinator coalesces |
  | Launch | `load()` always decodes the backup as well as the primary; `flush` re-decodes the file it replaces | `primaryIsKnownGood` + `backupCouldBeNewer()` skip both |

  `main`'s commit message records the before/after: week advance **5,454 ms -> 566 ms**, one match
  snap **5,259 ms -> 24 ms** against a 1,200 ms dwell, a 130-snap game **11.4 min -> 3.1 s**, durable
  writes per 25-snap burst **25 -> 1**, cold launch **3,972 ms -> 1,372 ms**.
  `main` also carries `SaveWriteBudgetTest`, which asserts the write-to-intent ratio; this branch has
  neither the test nor the `writeCount` it reads.
- **Fix:** rebase or merge `main` into the branch **before** any of the view-level work below, and
  re-verify the four table rows survive the merge. Nothing else in this report should be actioned on
  a tree that has not taken this.
- **Validation:** `SaveWriteBudgetTest` green, and the scratch-package harness described in the
  app-layer latency note re-run against `CoachWorldStore`'s public API.

---

### P1-1 — the app root takes an observation dependency on all 28 read models

- **Symptom (hypothesis):** any store mutation invalidates the whole root, rebuilding the current
  screen's entire subtree and its chrome, even when the mutation touched a screen nobody is looking at.
- **Cause:** `career(_ store:)` is a 58-case switch, and **all 58 cases call `chrome(for:in:)`**
  (59 call sites). `chrome` calls `availableScreens(in: store)`, which performs **44 reads across 28
  distinct `@Observable` properties**. Because those reads happen inside `body`, the Observation
  registrar records the root as dependent on every one of them. Combined with `rebuildScreens`
  writing all 28 per intent (P0-2), every intent is a guaranteed full-root invalidation — including a
  refused intent that changes nothing, since Observation notifies on assignment and does not diff.
- **Evidence:** [CoachWorldAppRootView.swift:1053-1125](Sources/CoachWorldApp/CoachWorldAppRootView.swift#L1053).
  58 `case` labels, 59 `chrome(for:` calls, 44 `store.` reads inside `availableScreens`.
- **Fix:** `main`'s shape already solves this — one `availableScreens` property answered from the
  root behind the memo. Taking P0-2 fixes this finding as a side effect. Note the trade `main` makes:
  its single observed `revision` is a deliberately coarse global dirty flag, so a world move still
  re-renders whatever is on the glass. That is correct for one-screen-at-a-time, and worth
  re-examining only if a future surface composes several models side by side.
- **Validation:** SwiftUI Instruments "View Body" lane — count root body evaluations across one
  refused intent. Expect 1, not 1 + a rebuild of 28 models.

---

### P1-2 — `selectedX` computed properties linear-scan, then get read a dozen-plus times per body

This is the most widespread defect in the view layer and it has the same shape everywhere.

- **Symptom (hypothesis):** navigation and selection taps cost more than they should on the densest
  surfaces; worsens with world size and roster size rather than staying flat.
- **Cause:** a `private var selectedX: T?` implemented as a linear search, referenced many times in
  one body evaluation — in two cases **inside the row loop**, making it O(n^2).
- **Evidence**, worst first:

  | Site | Definition | Reads/body | Cost per body evaluation |
  |---|---|---|---|
  | [ProspectProfileView.swift:38](Sources/ProFootballCoachUI/ProspectProfileView.swift#L38) | `model.prospects + model.discovery` then `.first(where:)` | ~37 | **allocates a fresh 64-element array 37 times**, ~2,400 struct copies, plus 37 scans |
  | [RecruitingBoardView.swift:49](Sources/ProFootballCoachUI/RecruitingBoardView.swift#L49) | four chained `.first(where:)` | ~19, **2 of them inside the 40-row `ForEach`** | ~5,100 string comparisons at a full board |
  | [LeagueMapView.swift:112](Sources/ProFootballCoachUI/LeagueMapView.swift#L112) | `model.places.first { ... }` over **166 places** | ~17 | ~2,800 string comparisons |
  | [LeagueMapView.swift:100](Sources/ProFootballCoachUI/LeagueMapView.swift#L100) | `visiblePlaces.sorted` | 2 | a 134-element sort, twice, `rank()` per comparison |
  | [TeamHealthView.swift:115](Sources/ProFootballCoachUI/TeamHealthView.swift#L115) | `model.players.sorted` over up to 128 | 4 | four sorts |
  | [WorldSearchView.swift:143](Sources/ProFootballCoachUI/WorldSearchView.swift#L143) | see P1-3 | 5 | see P1-3 |
  | [RosterView.swift:49](Sources/ProFootballCoachUI/RosterView.swift#L49) | `sort.sorted(model.players)` over 85 | 3 | re-sorts on unrelated state changes too |
  | [MatchDayView.swift:869](Sources/ProFootballCoachUI/MatchDayView.swift#L869) | `allCases.compactMap { model.controls.first { ... } }` | 5 | small (~5 controls) but on the match-day path |

  Twenty-plus further instances at 3-4 reads each are listed by the same scan; the eight above carry
  the cost.
  The same array-`contains` shape appears once more in the chrome:
  `SurfaceRegistryOverlay` filters each surface family against `availableScreens`, which is an
  `Array` here — roughly 2,000 comparisons to open the task list. `main` already declares it a
  `Set`, so P0-2's merge fixes that instance.
- **Fix:** two mechanical moves, no architecture change.
  1. Where the lookup is by a stable ID, give the read model an **index** — the provider already
     holds the collection, so a `[String: T]` built once per model beats a scan repeated per body.
  2. Where the value is genuinely derived, **compute it once at the top of `body`** into a `let` and
     pass it down, rather than referring to the computed property repeatedly. The skill's own note
     applies: `@State` is not the right home for this, and `.equatable()` is not the fix.
- **Validation:** Time Profiler on a selection tap in Recruiting Board at a full 40-prospect board,
  and on a marker tap in League Map.

---

### P1-3 — World Search rebuilds 166 rows and re-filters the whole world on every keystroke

- **Symptom (hypothesis):** typing in the search field is the worst input latency in the app, and it
  is the surface most likely to spike memory because of P0-1.
- **Cause:** three compounding problems on one screen.
  1. `scopedResults` -> `visibleResults` is recomputed **5 times per body evaluation** (`isEmpty`
     check, `countLabel`, `groupedTiers`, and once per tier inside `resultGroups`). Each pass walks
     every result and, per row, builds a 4-element array, `joined(separator:)`s it and `lowercased()`s
     it — **three allocations per row per pass**. `needle` is re-trimmed and re-lowercased each time
     too.
  2. `query` is a plain `@State` bound to a `TextField` with **no debounce**, so all of the above runs
     per character.
  3. `resultGroups` is a plain `VStack` + `ForEach`, **not lazy** — so every one of the world's
     **166 organisations** (134 programmes + 32 pro teams, `CollegeRules.programmeCount` +
     `ProRules`) materialises a row, and **each row contains a `CoachWorldTeamLogo`**. This is the
     screen where P0-1 bites hardest.
- **Evidence:** [WorldSearchView.swift:36-45](Sources/ProFootballCoachUI/WorldSearchView.swift#L36)
  (`visibleResults`), [:143](Sources/ProFootballCoachUI/WorldSearchView.swift#L143)
  (`scopedResults`), [:148-157](Sources/ProFootballCoachUI/WorldSearchView.swift#L148)
  (`resultGroups`, non-lazy, nested `.filter` per tier),
  [:172](Sources/ProFootballCoachUI/WorldSearchView.swift#L172) (the logo per row).
  `CoachWorldTeamProfileProvider.worldSearch(from:)` applies **no `prefix`** — the result set is the
  whole world.
- **Fix:** lowercase the searchable text **once, in the provider**, and store it on
  `WorldSearchReadModel.Result`; compute `scopedResults` once per body into a `let`; group with a
  single pass into `[String: [Result]]` instead of one `.filter` per tier; and wrap the groups in a
  `LazyVStack`. A debounce is optional once the per-keystroke work is O(n) with no allocation.
- **Validation:** SwiftUI Instruments while typing five characters; compare body-evaluation count and
  allocation volume before and after.

---

### P1-4 — 35 of 41 scrolling surfaces build every row eagerly

- **Symptom (hypothesis):** first-frame cost on list screens scales with the whole collection rather
  than the visible window; worst where the rows are expensive.
- **Cause:** 41 files use `ScrollView`; only **six** use any lazy container (`RosterView`,
  `StandingsView`, `ScheduleView`, `ClassOverviewView`, `StatisticsLeadersView`, `GamePlanView`, plus
  `TeamLogoProofView`). The rest place a plain `VStack` + `ForEach` inside the scroll view.
- **Evidence:** the unbounded or large ones, with their row sources —

  | Surface | Rows | Bound |
  |---|---|---|
  | `WorldSearchView` `resultGroups` | 166 | none — see P1-3 |
  | `LeagueMapView` `placeBrowser` | up to 134 | none; a horizontal `ScrollView` + plain `HStack` at [:351](Sources/ProFootballCoachUI/LeagueMapView.swift#L351) |
  | `NewsView` `model.items` | `NewsFeedReadModel.maximumItems` | bounded, value worth re-reading against the density budget |
  | `InboxView` `model.items` | provider-bounded | bounded |
  | `LegacyHistoryView` | four collections, one nested | `records` / `careerLine` / `coachingTree` carry **no `prefix`** in `CoachWorldHistoryProvider`; only `notableMeetings` is capped at 8 |
  | `RecruitingBoardView` | 40 + 24 | bounded, but every row carries several overlays |
  | `CompetitionOverviewView` | rankings + bracket | bracket is `ForEach(stages)` x `model.bracket.filter { $0.stage == stage }` — O(stages x games) per render at [:200](Sources/ProFootballCoachUI/CompetitionOverviewView.swift#L200) |

- **Fix:** `LazyVStack` / `LazyHStack` for `WorldSearchView.resultGroups`, `LeagueMapView.placeBrowser`,
  `LegacyHistoryView` and `NewsView`. Give `legacyHistory`'s three uncapped collections a stated
  bound in the provider — `CLAUDE.md` already requires that every collection that grows across
  seasons has one, and `careerLine` and `coachingTree` both grow with career length. The bounded
  bracket filter should be a single grouping pass rather than a filter per stage.
- **Validation:** first-frame time on World Search and Legacy History at season 20 versus season 0.

---

### P2-1 — the ball and the player tokens are the most expensive things in the 60 Hz frame

The `TimelineView` plumbing itself is right: `paused:` is bound, `playbackComplete` stops the
timeline, `FieldPlane` is `Equatable` and ends in `.drawingGroup()`, and the timeline is keyed on the
playback's own identity. The cost is inside the two things that move.

- **`BallToken`** ([MatchDayField.swift:679](Sources/ProFootballCoachUI/MatchDayField.swift#L679))
  re-renders every tick and, per frame, draws a **blurred** shadow ellipse, a `RadialGradient` glow, a
  `LinearGradient`-filled silhouette, **a nested `GeometryReader`** containing two `ForEach`es of
  `Rectangle`s, all inside a `.clipShape`. The blur and the clip are each an offscreen pass.
  The nested `GeometryReader` is **dead weight**: `leather` is given
  `.frame(width: Ball.width, height: Ball.height)` by its caller, so `scale = geometry.size.width /
  Ball.width` is always 1 — the subsequent `.scaleEffect` does not change layout size. The stripes
  and lace offsets can be constants.
  *Fix:* delete the inner `GeometryReader`; rasterise `leather` once with `.drawingGroup()` and let
  `.rotationEffect` / `.scaleEffect` transform the raster.
- **`PlayerToken`** ([MatchDayField.swift:642](Sources/ProFootballCoachUI/MatchDayField.swift#L642))
  is instantiated 22 times per tick — **1,320 per second** — and each one is a `Text` with
  `.minimumScaleFactor` (which forces a scale search during layout), a filled `Circle`, a stroked
  `Circle` overlay, and a **drop shadow**; foreground actors add a second stroked `Circle`.
  *Fix:* the label, colours and geometry of a token do not change during a snap — only its position
  does. Make `PlayerToken` `Equatable` and apply `.equatable()`, drop `.minimumScaleFactor` (the
  labels are short role strings measurable once), and either pre-rasterise the token or move the
  whole actor layer into a `Canvas` — legitimate here, unlike on League Map, because every mark is
  already `.accessibilityHidden(true)`.
- **`foregroundIDs` is an `[String]`, not a `Set`**
  ([ScreenReadModels.swift:1425](Sources/ProFootballCoachUI/ScreenReadModels.swift#L1425)), and
  [MatchDayView.swift:464](Sources/ProFootballCoachUI/MatchDayView.swift#L464) calls `.contains` on it
  once per actor per tick — 22 x |foregroundIDs| UUID-string comparisons, ~4,000/s at the `04` §9 cap
  of three. Free to fix by hoisting a `Set` above the `ForEach`.
- **Validation:** this is the one place where a code-first conclusion is weakest and a trace is worth
  most. Capture the SwiftUI template on a device during a live snap and read the View Body and
  Render lanes. `docs/STATUS.md` already flags the 16.7 ms budget as unmeasured; this is the capture
  that would close it.

---

### P2-2 — three progress-bar primitives are each a `GeometryReader`, used inside rows

- **Symptom (hypothesis):** extra layout passes on the densest tables, and the sizing instability
  `GeometryReader` is prone to inside a lazy container.
- **Cause:** `FloodlitShareBar`
  ([FloodlitPatterns.swift:271](Sources/ProFootballCoachUI/FloodlitPatterns.swift#L271)),
  `CoachWorldMeter` ([CoachWorldVocabulary.swift:251](Sources/ProFootballCoachUI/CoachWorldVocabulary.swift#L251))
  and `CoachWorldOpposedBar` ([CoachWorldVocabulary.swift:282](Sources/ProFootballCoachUI/CoachWorldVocabulary.swift#L282))
  all read a proxy solely to multiply a width by a fraction. `FloodlitShareBar` alone has **17 call
  sites**, several inside per-row content — `RosterView:566` is inside the attribute list,
  `TeamHealthView:233` inside `readinessRow`, `PlayerProfileView:147` inside a `ForEach`. An 85-player
  roster with a bar per row is 85 greedy readers in one lazy stack.
- **Fix:** none of the three needs a proxy. A full-width `Capsule` with
  `.scaleEffect(x: proportion, anchor: .leading)`, or a `.overlay(alignment: .leading)` with
  `.containerRelativeFrame(.horizontal)`, gives the same drawing with no second layout pass. Fixing
  the three primitives fixes all seventeen call sites at once.
- **Validation:** SwiftUI Instruments layout lane on Roster at 85 players.

---

### P2-3 — the rasterisation guard reached one of three backdrops and neither overlay

- **Symptom (hypothesis):** wasted `Canvas` and gradient work behind and over *every* screen on every
  root invalidation — which, per P1-1, is currently every intent.
- **Cause:** `FieldPlane` shows exactly the right pattern — `Equatable`, `.equatable()` at the call
  site, `.drawingGroup()` at the end
  ([MatchDayField.swift:52](Sources/ProFootballCoachUI/MatchDayField.swift#L52)). Nothing else in the
  composition layer got it. A `Canvas`'s renderer is a closure, so SwiftUI cannot diff it; without an
  `Equatable` guard above, the draw closure re-runs whenever the enclosing view is re-evaluated.

  | Layer | Where it draws | `Equatable` | `.drawingGroup()` |
  |---|---|---|---|
  | `FieldPlane` | Match Day only | yes | yes |
  | `CoachWorldWorldBackdrop` | every chromed surface | **no** | yes |
  | `CoachWorldFloodlitBackdrop` | every desk-register surface | **no** | **no** |
  | `CoachWorldGrainOverlay` | **every stage, topmost in the `ZStack`** | **no** | **no** |

- **Evidence:**
  - [CoachWorldDeskComponents.swift:115](Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift#L115)
    — `CoachWorldFloodlitStage.body`. Its `ZStack` picks one of the two backdrops, then puts
    `CoachWorldGrainOverlay()` on top of the content. The `ZStack` itself has **no**
    `.drawingGroup()`, so the grain composites live over everything, on every screen.
  - [CoachWorldDeskComponents.swift:178](Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift#L178)
    — `CoachWorldFloodlitBackdrop` is a `GeometryReader` holding a `LinearGradient`, a
    `RadialGradient` and a `Canvas` with a 7-iteration stroke loop, and it ends at `.ignoresSafeArea()`
    with **no rasterisation at all**.
  - [CoachWorldDeskComponents.swift:237](Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift#L237)
    — `CoachWorldGrainOverlay` issues **140 separate `context.fill(Path(CGRect(...)))` calls** for
    1 x 1 pixels. One accumulated `Path` would be one draw command instead of 140. Two of its three
    call sites sit inside `FieldPlane`'s rasterised group; **the third is the stage, and that one is
    on every screen**.
  - [FloodlitChrome.swift:120](Sources/ProFootballCoachUI/FloodlitChrome.swift#L120) —
    `CoachWorldWorldBackdrop` does end in `.drawingGroup()`, but is not `Equatable`, so its Canvas
    closure — a 7-iteration loop, a 9-iteration loop and a dust-mote loop — still re-runs.
- **Fix:** conform both backdrops to `Equatable` on `(world, palette)` / `(palette)` and apply
  `.equatable()`; add the missing `.drawingGroup()` to `CoachWorldFloodlitBackdrop`; accumulate the
  grain into a single `Path` and rasterise it. The pattern to copy is already in the repository, one
  file away.
- **Validation:** count `Canvas` draws per navigation in the SwiftUI template, on a desk-register
  screen and a chromed one.

### P3-1 — `.coachWorldAnimation(value:)` deep-compares whole collections

`StandingsView:69` passes `model.rows`, `RecruitingBoardView:401` passes `model.prospects`. `value:`
requires an `Equatable` comparison of the entire array on every render to decide whether to animate.
Both are deliberate — `04` §2 asks for the reorder itself to be the content — and both collections
are bounded, so this is a note rather than a defect. If either grows, compare a cheap derived key
(the ordered list of stable IDs) rather than the rows.

### P3-2 — `ColorValue.color` allocates a fresh `Color` at 718 call sites

[DesignTokens.swift:230](Sources/ProFootballCoachUI/DesignTokens.swift#L230) builds
`Color(red:green:blue:)` on every access, and there are **718 `.color` reads** across the module,
many inside row bodies. `CoachWorldTokens.dark` is correctly a `static let`, and `Color` compares
equal by components so this does **not** cause spurious invalidation — it is allocation churn only.
Caching the `Color` next to the components inside `ColorValue` removes it.

### P3-3 — a package-build-only fallback decodes a 1 MB PNG per body evaluation

[CoachWorldTeamLogo.swift:43](Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift#L43): when
`UIImage(named:in:.module)` misses, the fallback is `UIImage(contentsOfFile:)`, which **does not
cache** — so each `body` re-reads and re-decodes the PNG from disk on the main thread.
`Package.swift` declares `resources: [.process("Resources")]`, and an Xcode-driven iOS build compiles
the catalogue with `actool`, so the shipped app should take the cached first branch. Plain SwiftPM
builds — which is how the test executable builds — only copy, and take the fallback. This is
therefore a **development-path** hazard rather than a shipping one, but it is worth a memoised
cache regardless, because the failure is silent and the symptom is indistinguishable from P0-1.

---

## Branch findings

51 local and 23 remote branches were compared against `main`; nine diverge in the UI or composition
layer.

| Branch | Ahead | Behind `main` | UI files | Assessment |
|---|---|---|---|---|
| `agent/floodlit-injury-evidence` | 33 | 138 | 349 | The audited branch. Carries P0-1 and all of P0-2. |
| `codex/team-logos` | 31 | 138 | 350 | **Origin of P0-1** — the 333 logo blobs enter here. Same 138-commit gap, so merging it directly carries the same regression. |
| `origin/claude/game-surfaces-floodlit-plan-qo0okd` | 34 | 268 | 23 | A parallel 4,087-line design system (`DesignSystem/WorldBackdrop.swift` 428 lines, `GlassPanel`, `GrainOverlay`, `Gauges`). 268 commits behind — stale. If ever revived, audit `WorldBackdrop` and `GlassPanel` first; the existing backdrop is already P2-3. |
| `origin/claude/production-scale-local-testing-if99bb` | 6 | 139 | 11 | Touches five providers and the root view; name suggests scale testing. Worth reading before it goes stale, but 139 behind. |
| `origin/cursor/p12-week-screens-fbc0` | 1 | 268 | 15 | Stale. |
| `claude/implement-landscape-screens-63c2b1`, `claude/missing-game-features-vcrzwz` | 6 / 46 | 268 | 6 | Stale. |
| `codex/people-compaction-wip` | 9 | 138 | 2 | Engine-side. |
| `claude/career-length-cap-30`, `claude/codebase-review-confidence-b6b216`, `codex/fix-review-findings` | 1-3 | 0-133 | 1 | Small. |

The thirteen `.claude/worktrees/` checkouts are working copies of branches already listed; none holds
UI content not present on a branch.

**The one branch conclusion that matters:** every branch carrying the logos is also 138 commits
behind the performance work. Neither can be merged without the other.

---

## What is not covered

Stated plainly, because `04b`'s recurring lesson is that a review bounds what was checked, not what
is true.

- **No frame was rendered and no trace was captured.** Every runtime claim above is marked as a
  hypothesis and is derived from static structure, not measurement.
- **The only performance probe in the suite measures the engine.**
  `Tests/SimTests/Suites/PerformanceBudgetTests.swift` times `CollegeRecruitingAISystem.process` and
  `WorldScheduler.advanceWeek`, prints them, and **asserts no threshold** — its own header says
  "no host threshold". Nothing in the repository measures `CoachWorldStore` -> `CoachWorldAppRootView`,
  which is where P0-2's seconds lived.
- **Adjacent, engine-side, and already tracked:** `docs/STATUS.md` records a 30-season save at 36.0 MB
  compressed with a 12.5 s encode on a development Mac, and FSC-003 as a release blocker. The encode
  runs off the main actor in `Task.detached(priority: .utility)`
  ([CoachWorldSaveStore.swift:331](Sources/CoachWorldApp/CoachWorldSaveStore.swift#L331)), so it is
  not a frame hang — but it does delay the next intent, and `flush` additionally reads the whole file
  back to verify the write. Out of scope for a SwiftUI audit; noted so it is not mistaken for one.

---

## Next step

Two actions, in order, and the second is worthless without the first.

1. **Merge `main` into the branch** and confirm the four rows of the P0-2 table survive it. Then
   downsample the logo set and add the missing size bound to `TeamLogoTests`. Those two moves address
   both P0s and, via `main`'s `availableScreens`, P1-1 as well.
2. **Capture one SwiftUI Instruments trace on a device** — release build, iPhone 15-generation or
   newer per the supported-hardware rule, one live match snap — and read the View Body and Render
   lanes. That single capture is what would turn P2-1 from a code-first hypothesis into evidence, and
   it is the same capture `docs/STATUS.md` says is owed for D4's 16.7 ms frame ceiling.

---

## Measured on device — 2026-08-21

The code-first pass above was written without a trace. This section is measurement, taken after it,
and it **corrects the report in three places**. Where the two disagree, this section wins.

**Rig.** iPhone 17e simulator (the 844 x 390 install floor), iOS 26.5, Xcode 26.6, **Release**
configuration, Apple silicon host. Branch `agent/floodlit-injury-evidence` @ `c0f4334` — the branch
as audited, before any merge of `main`. New career, seed 20260812, Arnold PA Polytechnic Institute,
season 0 week 1, save file **3.72 MB**. Method: `ps` cputime + RSS sampled at 100 ms around each
interaction, `footprint(1)` for physical footprint. Wall time is the interval over which CPU time
was still climbing.

### Size — P0-1's first half, confirmed

| | Measured |
|---|---|
| Installed `.app` | **163 MB** |
| `Assets.car` (the logo catalogue) | **109.6 MB — 67% of the app** |
| App binary | 53.5 MB |
| Compressed payload (`.ipa`-equivalent zip) | **121.5 MB** |

`actool` compressed 156.2 MB of source PNGs to 109.6 MB — about 30%, nowhere near enough. The
catalogue is two thirds of the shipped application.

### Latency — P0-2, confirmed and worse than predicted

| Operation | Wall | CPU | Reference |
|---|---|---|---|
| Cold launch to idle | **9.0 s** / 9.2 s (2 runs) | 6.8 / 7.0 s | `main` after its fix: **1,372 ms** |
| World generation (new career) | ~4.8 s | 4.73 s | expected: it is 15,766 players |
| Screen navigation (rail tap) | 0.17 s | 0.26 s | no engine work, no save |
| Committed intent — redshirt decision | 4.38 s | **4.53 s** | |
| Committed intent — redshirt decision (repeat) | 7.12 s | **4.49 s** | |
| Committed intent — delegate preparation | 4.43 s | **4.49 s** | |
| **Week advance** | **7.44 s** | **8.95 s** | D4 ceiling **2.0 s**; `main` **566 ms** |
| **One match snap** | ~4.8 s | **4.78 s** | auto-advance dwell **1,200 ms**; `main` **24 ms** |

**The finding is the flatness of that column.** Three different committed intents — two decisions and
a preparation delegation, doing quite different engine work — each cost **4.49-4.53 CPU-seconds**.
That is not the engine; that is a fixed per-intent overhead: all 28 read models rebuilt, plus a
3.72 MB encode, plus the decode-to-validate, plus two 3.72 MB writes (primary and backup), plus a
read-back to verify. Navigation, which triggers none of that, costs 0.26 s — a 17x gap between an
intent and a route change on the same screen.

Three consequences follow directly:

- **A week advance is 3.7x over D4's own 2.0 s ceiling** and about 13x what `main` measures.
- **A snap costs 4x its own auto-advance dwell.** The game is scheduled to advance every 1,200 ms and
  takes 4,800 ms to do it, so it falls further behind itself with every play. At that rate a
  130-snap game is about **10.4 minutes of machine time** — which is `main`'s own pre-fix figure of
  11.4 minutes, reproduced.
- **Cold launch is 9 s** on the smallest save the game will ever have, and this save grows.

### Three corrections to the code-first report

1. **P2-1 is not confirmed, and Match Day idles correctly at 0% CPU.** Sampled over three
   consecutive 5 s windows with the field on screen and nothing animating: **0.00 CPU-seconds**. The
   `TimelineView(.animation(paused:))` guard and the `playbackComplete` latch do exactly what they
   claim. An earlier reading of "91% of a core at idle" was **wrong** — it was the tail of a
   4.5 s intent caught inside the sampling window. P2-1's per-frame costs (the ball's blur and clip,
   22 shadowed tokens, the dead inner `GeometryReader`) remain real code observations, but at
   4.8 s per snap the frame loop is not the bottleneck and **no frame-rate problem was observed**.
2. **P0-1's runtime-memory half is still unmeasured.** Physical footprint stayed at **19 MB** on the
   title, **47-58 MB** across six career screens. Peak RSS touched 571.8 MB during intents, but RSS
   counts clean and shared pages; footprint — the number jetsam acts on — never exceeded 58 MB.
   **World Search was never reached** (the task-registry overlay's rows swallow a drag, so the list
   could not be scrolled), so the screen that would put 166 logos on the glass at once was not
   exercised. The 664 MiB figure remains arithmetic on 1024 x 1024 x 4 bytes, not an observation.
   The size half of P0-1 stands on hard measurement; the memory half does not.
3. **World generation runs off the main actor as documented, and it costs 4.73 CPU-s with a
   166.9 MB peak footprint.** That is the one large cost in the app that is *not* a defect — the
   code says it is seconds of work on 15,766 players and 2,158 staff, and it is.

### What this does not measure

No Instruments trace was captured; this is process-level CPU, RSS and footprint sampling, which
attributes cost to an interaction but not to a symbol. It cannot separate the read-model rebuild
from the save encode inside that 4.5 s — only that the two together are fixed per intent and
independent of what the intent does. Nothing here was measured on physical hardware; a simulator on
Apple silicon is generally faster than an iPhone at CPU-bound work and slower at GPU-bound work, so
treat the latency numbers as a **floor**, not a ceiling. And every number is season 0 week 1, the
smallest save that exists.

### Next, revised

The order in the original report holds, and the case for step 1 is now much stronger than when it
was written. Merging `main` should take the week advance from 7.44 s toward its 566 ms and the snap
from 4.8 s toward 24 ms. **Re-run this same sequence after the merge** — it is about ten minutes of
work and it converts the whole of P0-2 from a citation of someone else's commit message into a
before/after on this branch. The one measurement still owed after that is World Search, reached by
some route the registry overlay does not swallow, with `footprint` sampled on arrival.

---

## Re-measured after merging `main` — 2026-08-21

Same rig, same interaction sequence, same seed and programme (Arnold PA Polytechnic Institute,
season 0 week 1, save 3.72 MB), clean install with no prior save.

**How the "after" tree was built, and what is provisional about it.** The repository's working tree
was **already dirty with another session's in-progress work** when this was run — at 05:20 something
downsampled all 166 logos from 1024 to **256 px**, taking the source bundle from 156.2 MB to
**4.1 MB**, and added `Tools/TeamLogos/generate_logos.swift`. Rather than merge 138 commits on top of
uncommitted work belonging to someone else, the merge was done in a **detached `git worktree` at
`/tmp/pfc-merge`**; the repository's own working tree was not touched and still holds that session's
changes. The 256 px logos were copied into the worktree read-only so the build reflects where the
repo actually is.

Six conflicts. `CoachWorldStore.swift` and `CoachWorldAppRootView.swift` — the two files that carry
the whole of P0-2's fix — **auto-merged clean**. Of the rest: the three view conflicts
(`StandingsView`, `ScheduleView`, `CompetitionOverviewView`) were all the same shape, this branch's
logo `HStack` against `main`'s swap from `.font(...)` to a `.coachWorldDisplay(...)` modifier, and
were resolved keeping both. `PRODUCT.md` kept this branch's deletion of the unmet
"save stays bounded across 20 seasons" claim. **`ContractTests.swift` and
`AccessibilityReflowTests.swift` were resolved by taking `main` whole** — `main` had rewritten both,
and this branch's surviving tails referenced a 2-tuple helper `main` had made a 3-tuple, and asserted
a property `main` proves false in a comment (an alias case in `career()` that can never execute).
That resolution **drops this branch's own additions to those two files, including its
`CoachWorldTeamLogo` contract check**. It is good enough to measure on; it is **not** the resolution
the real merge should ship. The suite was not run.

### Result

| | Before (audited branch) | After (merged) | Change |
|---|---|---|---|
| Installed `.app` | 163 MB | **56 MB** | −66% |
| `Assets.car` | 109.6 MB | **2.7 MB** | **40x smaller** |
| Zipped payload | 121.5 MB | **14.9 MB** | **8x smaller** |
| Cold launch to idle | 9.0 / 9.2 s | **3.38 / 3.17 s** | **2.8x** |
| Cold launch CPU | 6.8 / 7.0 s | **3.35 / 3.21 s** | 2.1x |
| World generation CPU | 4.73 s | **3.37 s** | 1.4x |
| **Committed intent, interactive CPU** | 4.53 / 4.49 / 4.49 s | **0.88 / 0.70 s** | **~5.7x** |
| — its durable save | *inside* that figure, blocking | **+0.90 / 0.89 s, ~4 s later** | off the interaction path |
| **Week advance, wall** | 7.44 s | **1.34 s** | **5.6x** |
| **Week advance, CPU** | 8.95 s | **0.88 s** (+0.91 deferred) | **10x** |
| One match snap, CPU | 4.78 s at 86% core | **~1.08 s at 27% core** | 4.4x, and animating rather than blocking |

### What actually changed, visible in the sampling

The shape of the CPU trace changed, not just its height. Before, every committed intent was **one
blocking burst pinned at ~100% of a core for 4.4 s**. After, the same interaction is **two separate
bursts**: about 0.8 s of interactive work, then the tree goes quiet, and about 0.9 s of durable write
fires roughly **four seconds later** on `scheduleFlush()`'s fixed deadline. That is `main`'s
coalescing design showing up exactly as its commit message describes, and it is the difference
between a save that blocks the coach and one that does not.

The snap tells the same story from the other side. Its CPU fell 4.4x, but the more telling number is
core utilisation: **86% before, 27% after**. Before, the snap was a blocking computation; after, it
is an animation spread across its own duration, which is what the `TimelineView` was always meant to
be doing.

**D4's week-advance ceiling is 2.0 s.** Before the merge this branch measured **7.44 s — 3.7x over**.
After, **1.34 s — inside it**, for the first time this audit has seen.

### What did not change, and what is still owed

- **The save is still 3.72 MB written twice**, primary and backup, at season 0 week 1. The merge moved
  that cost off the interaction path; it did not reduce it. FSC-003 is still a release blocker.
- **World Search was still not reached**, so P0-1's runtime-memory half remains unmeasured — though
  it now matters far less, because the assets it would have loaded are 256 px rather than 1024 px.
- **P2-1 is still not a measured problem.** Nothing in either run showed a frame-rate defect.
- **The conflict resolutions above are provisional**, and the two test files need a deliberate merge
  that keeps this branch's logo contract check rather than dropping it.
- **The suite has not been run** on the merged tree. Build green is not tests green.

---

## Suite run on the merged tree — 2026-08-21

The merge measured in the previous section was rebuilt properly first. The branch tip had moved
while that measurement was running: the other session committed its logo work as **`b6a5219`,
"feat: redraw the 166 team marks as flat vector artwork"** — 166 marks redrawn as flat vector
artwork at 256 px by a new `Tools/TeamLogos/generate_logos.swift`, with the manifest, hashes and
`TeamLogoTests` updated coherently in the same commit. It also **adds the pixel/byte bound this
report asked for**, and reads the largest size case back out of `CoachWorldTeamLogo.swift` so
growing the chip past what a 256 px source covers fails the suite.

So the measurement worktree — `main` merged into the older `66b95f3` with 256 px PNGs copied over an
older manifest — was **incoherent for the asset tests**. It was discarded and the merge redone from
`b6a5219`, this time resolving `ContractTests.swift` **surgically rather than by taking `main`
whole**, which preserves this branch's `CoachWorldTeamLogo` contract check. The stale `careerAliases`
tail was dropped, which is correct: it asserted an alias case in `career()` that `main` proves in a
comment can never execute.

Lane: `scripts/verify.sh --lane full` — release build with `-enable-testing`, then the default
`SimTests` run. Per the harness's own scope this **excludes the soaks and calibration lanes**.

### Result

```text
1002 tests, 794357 checks
136 suites green, 1 red
5 failing tests, 6 failed checks
```

**Every one of the six is a cross-process fingerprint pin in `ArchitectureTests`**, and every one is
of the form *expected constant X, got constant Y*:

| Test | Line |
|---|---|
| root and scheduler fingerprints are pinned across processes (2 checks) | `ArchitectureTests.swift:173-174` |
| the professional negotiation ledger is pinned across processes | `:208` |
| the match session is pinned across processes | `:242` |
| the news feed is pinned across processes | `:305` |
| the archived-season ledger is pinned across processes | `:353` |

### This is not a regression, and not the merge resolution's doing

Three facts settle it.

1. **`ArchitectureTests.swift` is byte-identical to `main`'s in the merged tree.** Neither the branch
   nor any conflict resolution touched it, so the *expected* constants are `main`'s, unmodified.
2. **`main` added these pins; the branch never had them.** `main`'s copy of the file contains five
   `pinned across processes` tests, `b6a5219`'s contains one — `main` added 275 lines the branch has
   never seen. The branch passes its own suite because four of these tests do not exist there.
3. **The branch has legitimately changed the world.** `git diff main b6a5219 -- Sources/FootballSimCore`
   is **30 files, 688 insertions, 630 deletions**. A different engine produces a different world, and
   these constants are a hash of that world.

So the merge does exactly what it should: it brings `main`'s pins together with the branch's engine,
and they disagree because the two worlds are different. `docs/STATUS.md` already records this exact
class from CI on an earlier `main` merge — *"`main` had independently added its own
negotiation-ledger, match-session, news-feed and archived-ledger fingerprint pins"*.

**Determinism itself is intact.** `"the same seed produces byte-identical root state"` — the
in-process determinism check, in the same suite — **passed**. So did `World integrity`,
`Competition integrity`, `Domain event ledger`, both legal suites, and the whole `Team logo assets`
family. What failed is only the agreement between a stored constant and a changed world.

### What this means for the merge

The six constants must be **re-pinned against the merged world** — but that is a deliberate act, not
a mechanical one, because re-pinning asserts *"the branch's world is the intended world."* Someone
who knows what those 30 engine files changed has to make that call; re-pinning to silence a red test
is exactly how a determinism guard stops guarding anything. This is the one item the merge cannot
close on its own.

### A caveat on the latency numbers above

While the suite ran, **seven `SimTests` processes were running concurrently on this machine**, all
CPU-bound, belonging to other sessions. Some were already running during both measurement rounds.
That contention does not explain the before/after gap — a 5 to 10x difference is far outside load
noise, and the change in *shape* (one blocking burst becoming an interactive burst plus a deferred
write) is load-independent — but it does mean the absolute wall-clock figures in both rounds should
be read as **approximate, and probably pessimistic**, rather than as clean bench numbers.
