# Floodlit Phase 5 — Personnel and Staff Surfaces (registry 16–23)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the five personnel presentation roots (registry 16–23) to Floodlit — the same
mechanical recipe Phases 3–4 established, applied to a two-pane master/detail table (`RosterView`)
and an identity-band/route-tab dossier (`PlayerProfileView`) for the first time.

**Architecture:** `CoachWorldFloodlitStage` wraps every root; `coachWorldFloodlitPanel` +
`CoachWorldCutCorner` replace the older `coachWorldDeskSurface` + `RoundedRectangle`;
`CoachWorldSystemState` replaces `ContentUnavailableView` and bare empty-state `Text`. No new shared
component — Phase 5 consumes vocabulary Phase 2 already shipped.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness.

**Spec:** Task 7 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Preserve every field binding, callback, sort descriptor, selection state, stable ID, and
  accessibility declaration. This phase is presentation-only.
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors of code this phase
  does not touch.
- **A second, unrelated session is concurrently fixing a pre-existing accessibility-label typo in
  `DepthChartView.swift:141`** (`.accessibilityLabel("(option.title). (option.consequence)")`,
  missing interpolation backslashes). Convert everything else in that file; leave that exact line
  byte-for-byte untouched so the other session's one-line fix lands cleanly whenever it commits. Both
  sessions work directly in this same checkout (no worktree isolation) — before any `git checkout`,
  `git reset`, or other branch-changing command, check `git status`/`git branch --show-current` first,
  since the other session switching branches here will swap every file on disk out from under this
  one. If that happens mid-phase, `git checkout agent/floodlit-injury-evidence` restores this
  session's branch; nothing is lost (commits are commits), but always verify with `git log --oneline
  -1` and `git status --porcelain` after switching back before resuming edits.

---

## Where the eight files actually stand

| File | Registry | Current state | Work this phase does |
|---|---|---|---|
| `RosterView.swift` | 16 | 728 lines. Two-pane master/detail: `rosterSurface` (sortable table) + `inspector` (selected-player detail), sheet-presents `PlayerProfileView`. Two `coachWorldDeskSurface(fill:border:)` sites (`rosterSurface`, `inspector`). Two `ContentUnavailableView` empty states ("No players on the roster", "No player selected"). No stage wrap. | Mechanical conversion — the largest single file this cutover has touched, but the recipe is unchanged. |
| `DepthChartView.swift` | 17 | 153 lines. Plain `ScrollView` + `.background(palette.page.color.ignoresSafeArea())`. Position-group rows already use `RoundedRectangle` + `.clipShape` (not `coachWorldDeskSurface`). One pre-existing accessibility typo at line 141 (see Global Constraints). | Mechanical conversion, line 141 excluded. |
| `PlayerProfileView.swift` | 18 | 425 lines. `identityBand` + `routeBar` (4 tabs: Overview/Attributes/Development/History) + `routeContent`. One `coachWorldDeskSurface` site (`attributeGroup`). No `ContentUnavailableView` — nothing here is ever empty (a profile is only shown for a resolved player). | Mechanical conversion. |
| `DevelopmentPlanView.swift` | 19 | 102 lines. Plain `ScrollView` + `safeAreaInset(edge: .top) { topBar }`. One `ContentUnavailableView` ("No development evidence"). | Mechanical conversion. |
| `StaffRoomView.swift` | 20 | 112 lines. Plain `ScrollView`. Empty state is a **bare `Text`**, not even `ContentUnavailableView` — "No employed staff are recorded for this organisation." | Mechanical conversion; this is the first empty state in the cutover that starts as plain `Text` rather than `ContentUnavailableView`. |
| `StaffMarketProfileView.swift` | 21 | 22 lines. Thin wrapper, delegates wholly to `StaffRoomView`. | No edit — converts automatically once `StaffRoomView` does, via the delegation fixpoint in `AccessibilityReflowTests.swift`. |
| `SchemeBookView.swift` | 22 | 34 lines. Thin wrapper, delegates wholly to `GamePlanView` (already converted, Phase 4). | Already converts automatically — verify only. |
| `PersonnelPackagesView.swift` | 23 | 34 lines. Thin wrapper, delegates wholly to `DepthChartView`. | No edit — converts once `DepthChartView` does. |

## What "converted" means here (same contract as Phase 3–4)

1. Wrap the root's content in `CoachWorldFloodlitStage(palette: palette) { ... }`.
2. Delete the file's own `.background(palette.page.color.ignoresSafeArea())` and any redundant
   `.foregroundStyle(palette.contentPrimary.color)` — the stage supplies both.
3. Replace `coachWorldDeskSurface(fill:border:)` with
   `coachWorldFloodlitPanel(fill:border:depth:)` at every site (three total: `RosterView` ×2,
   `PlayerProfileView` ×1).
4. Replace `ContentUnavailableView(...)` and the one bare-`Text` empty state with
   `CoachWorldSystemState(.empty(...), palette: palette)`, carrying the **full orienting sentence**
   (title folded into the message, per the Phase 4 adversarial-review fix — `CoachWorldSystemState`
   has one message slot, not a separate title).
5. Preserve every binding, callback, sort descriptor, selection, stable ID, and accessibility
   declaration verbatim.

## Scope decision: rating rings stay plain text

Task 7's step 2 names `CoachWorldRatingRing` among the vocabulary this phase may draw on. Decided
**not** to retrofit it into `RosterView`'s table or `PlayerProfileView`'s attribute rows:

- `RosterView`'s `rosterRow` is `RosterMetric.rowContentHeight = 28` points tall — a ring needs real
  diameter to read as a ring rather than a smudge (`ringStrokeMinimum` alone is 2pt, `ringTextRatio`
  0.42 of diameter for the centred figure), and retrofitting one means redesigning row height, not
  converting presentation.
- `PlayerProfileView`'s `attributeGroup` rows are already dense, one row per attribute, several
  attributes per group, `CoachWorldTokens.Shape.minimumTarget` (44pt) tall — same problem at a
  smaller scale.
- The existing plain coloured `Text` rating (`ratingColor(_:)`, three-band green/amber/red) already
  satisfies canon's never-colour-alone rule: the number itself is the primary channel, colour is
  reinforcement.
- Phases 3–4 already established this precedent — `TeamHealthView`'s player rows and
  `DepthChartView`'s slots both display ratings/percentages as plain coloured text, not rings, and
  that was never a finding in either phase's adversarial review.

Rings remain reserved for a context with room for their actual geometry — a hero display, not a
dense list. Not this phase's call to invent that context.

## Steps

- [ ] **Step 1: Impact each of the five real roots**

Run GitNexus upstream impact for `RosterView`, `DepthChartView`, `PlayerProfileView`,
`DevelopmentPlanView`, `StaffRoomView` before editing. Expect LOW risk, single caller (`career` in
`CoachWorldAppRootView.swift`) — the pattern every prior phase's personnel-adjacent files have shown.
Stop and re-scope on anything HIGH/CRITICAL.

- [ ] **Step 2: Convert `RosterView.swift`**

1. Wrap `body`'s `Group { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
   trailing `.foregroundStyle(palette.contentPrimary.color)` / `.background(palette.page.color
   .ignoresSafeArea())` pair.
2. `rosterSurface`: replace
   `.background(palette.work.color).coachWorldDeskSurface(fill: palette.work.color, border:
   palette.contentQuiet.color.opacity(0.38))` with
   `.coachWorldFloodlitPanel(fill: palette.work.color, border: palette.contentQuiet.color.opacity
   (CoachWorldTokens.Depth.panelBorderOpacity), depth: .deep)`. Replace its
   `ContentUnavailableView("No players on the roster", ...)` with
   `CoachWorldSystemState(.empty("No players on the roster. Players appear here when a career roster
   is available."), palette: palette)`.
3. `inspector`: replace its `coachWorldDeskSurface(fill: palette.page.color, border:
   palette.contentQuiet.color.opacity(0.38))` with `coachWorldFloodlitPanel(fill: palette.page.color,
   border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))`. Replace
   its `ContentUnavailableView("No player selected", ...)` with `CoachWorldSystemState(.empty("No
   player selected. Select a player to review the dossier."), palette: palette)`.
4. `accessibleLayout`'s empty-roster branch: same swap as step 2's, same combined sentence.
5. Leave the `.sheet(item: $presentedProfile)` modifier, `RosterSortDescriptor`, `selectedPlayerID`,
   and every accessibility label/hint exactly as they are.

- [ ] **Step 3: Convert `DepthChartView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. This file has no `coachWorldDeskSurface` and no
`ContentUnavailableView` to swap — the wrap is the entire change. **Do not touch line 141's
accessibility label** (see Global Constraints).

- [ ] **Step 4: Convert `PlayerProfileView.swift`**

1. Wrap `body`'s `Group { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
   trailing `.foregroundStyle`/`.background` pair.
2. `attributeGroup`: replace `.coachWorldDeskSurface(fill: palette.work.color, border:
   palette.contentQuiet.color.opacity(0.38))` with `.coachWorldFloodlitPanel(fill: palette.work.color,
   border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))`.
3. Leave `identityBand`, `routeBar`, `activeRoute` state, `positionDiagram`, and every accessibility
   label exactly as they are — no empty state exists here to swap.

- [ ] **Step 5: Convert `DevelopmentPlanView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair (the `safeAreaInset(edge: .top) { topBar }` modifier
stays where it is, attached after the stage wrap). Replace `ContentUnavailableView("No development
evidence", ...)` with `CoachWorldSystemState(.empty("No development evidence. No roster records are
available for this checkpoint."), palette: palette)`.

- [ ] **Step 6: Convert `StaffRoomView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. Replace the bare
`Text("No employed staff are recorded for this organisation.")
.foregroundStyle(palette.contentSecondary.color)` with `CoachWorldSystemState(.empty("No employed
staff are recorded for this organisation."), palette: palette)` — already a single complete sentence,
no title to fold in.

- [ ] **Step 7: Build**

```bash
swift build
```

- [ ] **Step 8: Run the personnel-specific and design-contract lanes**

```bash
swift run SimTests --depth-chart
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift build
```

Expected: the "Floodlit surface conversion" suite reports a higher converted count than Phase 4's 21
(five new direct roots plus `StaffMarketProfileView`/`PersonnelPackagesView`'s wrappers resolve
through the existing fixpoint with no test changes needed — `SchemeBookView`'s wrapper was already
counted in Phase 4 once `GamePlanView` converted).

- [ ] **Step 9: `detect_changes` against exactly this phase's paths**

```
mcp__gitnexus__detect_changes({scope: "unstaged"})
```

Review only the symbols and processes this phase's five files touch. The worktree may carry the other
concurrent session's unrelated in-flight work (inbox/read-model changes, or its DepthChartView typo
fix) — do not stage or revert any of it.

- [ ] **Step 10: Adversarial review of the phase diff**

Same shape as Phases 3–4: independent dimension reviewers (canon compliance, structural correctness —
including the double-ground check on all five roots — accessibility, behaviour preservation against
this plan's presentation-only claim) each followed by adversarial verification of every finding. Fix
everything confirmed real before proceeding. Explicitly check that line 141 of `DepthChartView.swift`
was left untouched.

### Adversarial review findings

Two confirmed:

- **`RosterView.accessibleLayout` painted `.background(palette.work.color)` over the stage backdrop
  for every AX5 user.** Real defect, and a real gap in the existing "no converted root paints its own
  ground" contract test — that test's predicate is a literal substring match for
  `palette.page.color.ignoresSafeArea()` only, so a differently-worded opaque background (a different
  token, no `.ignoresSafeArea()`) falls outside its coverage. `PlayerProfileView.accessibleLayout` and
  `CoachingHQView.accessibleLayout`, both converted earlier in this cutover, never opaque-paint their
  AX5 layout — this file was the outlier. Fixed by removing the line, matching the sibling pattern.
  The contract-test gap itself is real but broader than this phase's fix; not resolved here.
- **`DepthChartView.swift`'s accessibility-label interpolation typo, again.** The reviewer correctly
  identified the same pre-existing typo (line ~150 after this phase's wrap) already known from this
  session and being fixed by a separate concurrent session per this plan's Global Constraints —
  correctly flagged, deliberately left untouched.

- [ ] **Step 11: Full suite**

```bash
swift run SimTests
```

- [ ] **Step 12: Commit**

Stage exactly this phase's files — the five converted view files plus this plan doc — and commit as
`feat: convert Floodlit personnel surfaces`. Do not stage the concurrent session's unrelated files.
