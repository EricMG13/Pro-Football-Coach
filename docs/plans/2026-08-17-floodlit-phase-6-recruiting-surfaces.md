# Floodlit Phase 6 — Recruiting and College-Offseason Surfaces (registry 24–33, 61)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the six real recruiting/college-offseason presentation roots (registry 24–33, 61) to
Floodlit — the largest single file this cutover has touched (`RecruitingBoardView.swift`, 854 lines),
plus the first production use of `CoachWorldSystemState`'s `.delegated` case.

**Architecture:** Same mechanical recipe as Phases 3–5. One structural nuance this phase introduces:
`RecruitingBoardView.accessibleLayout` currently paints a full-screen opaque background, the exact
double-paint defect Phase 5's adversarial review found and fixed in `RosterView.accessibleLayout` —
this plan removes it up front rather than re-discovering it in review.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness.

**Spec:** Task 8 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Preserve every field binding, callback, filter/search state, selection, stable ID, and
  accessibility declaration. Presentation-only except the `.delegated` vocabulary adoption named
  below.
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors.
- Both sessions still work directly in this shared checkout (no worktree isolation) — before any
  `git checkout`/`reset`, check `git status`/`git branch --show-current` first.

---

## Where the eleven files actually stand

| File | Registry | Current state | Work this phase does |
|---|---|---|---|
| `RecruitingBoardView.swift` | 24 | 854 lines. Two-pane `standardLayout` (`boardSurface` table + `dossier` panel) plus a separate `accessibleLayout`. `dossier` uses `coachWorldDeskSurface`. Three `ContentUnavailableView` sites (`accessibleLayout`, `boardSurface`, `dossier`'s empty branch). `accessibleLayout` opaque-paints its own full-screen background+border — the double-paint bug class. | Full conversion, largest this cutover. |
| `ProspectProfileView.swift` | 25 | 218 lines. One `ContentUnavailableView` ("No prospect selected"). | Mechanical conversion. |
| `ShortlistView.swift` | 26 | 136 lines. Search field + filtered list. One `ContentUnavailableView` ("No monitored prospects"). | Mechanical conversion. |
| `ContactVisitPlannerView.swift` | 27 | 108 lines. `ForEach` list with a trailing bare-`Text` empty note ("No board prospects have a contact or visit plan.") rather than a full `ContentUnavailableView`. | Mechanical conversion; promote the bare `Text` to `CoachWorldSystemState`, matching the `StaffRoomView` precedent from Phase 5. |
| `ClassOverviewView.swift` | 28 | 103 lines. No empty state at all — always has counts to show. | Wrap only, nothing to swap. |
| `CollegeOffseasonView.swift` | 33 | 232 lines. Shared root for `SigningDayView`/`PortalHubView`/`RetentionDecisionsView`/`PortalMarketView`/`NilAllocationView`. Two hand-rolled business states — `emptyState` ("No college-cycle decision is waiting") and `delegatedState` ("Staff decision in progress") — both currently a bare `VStack`/`Text` pair, not the shared component. | Mechanical conversion **plus** the `.delegated` vocabulary adoption (see below) — this file's two states are exactly `CoachWorldSystemState.Kind.empty` and `.delegated`, the first production use of `.delegated` since Phase 2 shipped it. |
| `SigningDayView.swift` | 29 | 48 lines. **Not a pure wrapper** — delegates to `CollegeOffseasonView` only when `model.cyclePhase == .signing`; otherwise shows its own unstaged `ContentUnavailableView("Signing day is closed", ...)`. | Needs its own `CoachWorldFloodlitStage` wrap (the delegation fixpoint would mark it "converted" from the `CollegeOffseasonView(` substring alone, while its closed-state branch stayed unconverted — a false-positive coverage gap caught before it shipped). |
| `PortalHubView.swift` | 30 | 28 lines. Pure wrapper, delegates wholly to `CollegeOffseasonView`. | No edit — converts via the delegation fixpoint. |
| `RetentionDecisionsView.swift` | 31 | 28 lines. Pure wrapper. | No edit. |
| `PortalMarketView.swift` | 32 | 28 lines. Pure wrapper. | No edit. |
| `NilAllocationView.swift` | 61 | 28 lines. Pure wrapper. | No edit. |

## What "converted" means here (unchanged from Phases 3–5)

1. Wrap the root's content in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the file's
   own `.foregroundStyle(palette.contentPrimary.color)` / `.background(palette.page.color
   .ignoresSafeArea())` pair.
2. Replace `coachWorldDeskSurface(fill:border:)` with `coachWorldFloodlitPanel(fill:border:depth:)`.
3. Promote a bare full-screen background (`RoundedRectangle`/`Rectangle` fill covering the whole
   root) to `coachWorldFloodlitPanel` when it is a **bounded card** sitting beside other content
   (e.g. `RecruitingBoardView.boardSurface`, half the screen); **remove it entirely** when it is a
   **full-screen opaque paint under the stage backdrop** (e.g. an `accessibleLayout` wrapping the
   whole visible surface) — the distinction Phase 5's review drew between a legitimate panel and the
   double-ground defect.
4. Replace `ContentUnavailableView(...)` and bare-`Text` empty notes with
   `CoachWorldSystemState(.empty(...), palette: palette)`, folding title + description into one
   sentence per the Phase 4 fix.
5. Preserve every binding, callback, filter state, selection, stable ID, and accessibility
   declaration verbatim.

## The `.delegated` adoption in `CollegeOffseasonView`

`CoachWorldSystemState.Kind` has carried `.delegated(String)` since Phase 2 (`04` §7's five required
states: empty, loading, error, interrupted, delegated) but nothing has consumed it in production —
Phase 2's own vocabulary tests exercise it directly, not through a real screen. `CollegeOffseasonView`
already hand-rolls exactly this state under a different name (`delegatedState`, "Staff decision in
progress... N delegated decision(s) remain with the assigned staff owner"). Converting it to
`CoachWorldSystemState(.delegated(...))` is not new scope — it is the first real screen matching a
component canon already specifies and this project already built. `emptyState` similarly maps
directly onto `.empty(...)`.

## Steps

- [ ] **Step 1: Impact the six real roots**

Run GitNexus upstream impact for `RecruitingBoardView`, `ProspectProfileView`, `ShortlistView`,
`ContactVisitPlannerView`, `ClassOverviewView`, `CollegeOffseasonView`, and `SigningDayView` before
editing. Expect LOW risk, single caller (`career` in `CoachWorldAppRootView.swift`) — the pattern
every prior phase has shown; GitNexus has repeatedly failed to resolve a handful of these view-type
names by fuzzy match alone (a known quirk, not a signal) — direct source reading is the fallback
already used successfully in Phases 4–5.

- [ ] **Step 2: Convert `RecruitingBoardView.swift`**

1. Wrap `body`'s `Group { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
   trailing `.foregroundStyle`/`.background` pair.
2. `boardSurface`: replace `.background(palette.work.color)` with `.coachWorldFloodlitPanel(fill:
   palette.work.color, border: palette.contentQuiet.color.opacity
   (CoachWorldTokens.Depth.panelBorderOpacity), depth: .deep)`. Replace its
   `ContentUnavailableView("No prospects on the board", ...)` with `CoachWorldSystemState(.empty("No
   prospects on the board. Add evaluated prospects before assigning recruiting time."), palette:
   palette)`.
3. `dossier`: replace `.coachWorldDeskSurface(fill: palette.page.color, border:
   palette.contentQuiet.color.opacity(0.38))` with `.coachWorldFloodlitPanel(fill: palette.page.color,
   border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))`. Replace
   its `ContentUnavailableView("No prospect selected", ...)` (in the `else` branch) with
   `CoachWorldSystemState(.empty("No prospect selected. Select a prospect to review the system
   evaluation."), palette: palette)` — drop the now-redundant `.background(palette.page.color)`
   sitting alongside it, which double-paints under the panel.
4. `accessibleLayout`: **delete** the `.background { RoundedRectangle(cornerRadius:
   CoachWorldTokens.Shape.surfaceRadius).fill(palette.work.color) }` and its paired `.overlay {
   RoundedRectangle...stroke(...) }` — this is the exact class of bug Phase 5's review found in
   `RosterView.accessibleLayout` (a full-screen opaque paint sitting on top of the stage backdrop for
   every AX5 user), just not yet caught here because the file had no stage wrap until this phase.
   Replace its `ContentUnavailableView("No prospects on the board", ...)` with the same
   `CoachWorldSystemState` call as step 2's.
5. Leave `selectedProspectID`, `comparisonRow`/`accessibleProspectRows` selection state, and every
   accessibility label exactly as they are.

- [ ] **Step 3: Convert `ProspectProfileView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. Replace `ContentUnavailableView("No prospect
selected", ...)` with `CoachWorldSystemState(.empty("No prospect selected. Return to the recruiting
board to choose a prospect."), palette: palette)`.

- [ ] **Step 4: Convert `ShortlistView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. Replace `ContentUnavailableView("No monitored
prospects", ...)` with `CoachWorldSystemState(.empty("No monitored prospects. Add evaluated prospects
to the board before monitoring contact windows."), palette: palette)`. Leave `query` state and
`filteredProspects` untouched.

- [ ] **Step 5: Convert `ContactVisitPlannerView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. Replace `Text("No board prospects have a contact or
visit plan.").foregroundStyle(palette.contentSecondary.color)` with `CoachWorldSystemState(.empty("No
board prospects have a contact or visit plan."), palette: palette)`.

- [ ] **Step 6: Convert `ClassOverviewView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. Nothing else to swap — this file has no empty state.

- [ ] **Step 7: Convert `CollegeOffseasonView.swift`**

1. Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete
   the trailing `.foregroundStyle`/`.background` pair.
2. Replace `emptyState`'s body with `CoachWorldSystemState(.empty("No college-cycle decision is
   waiting. The portal and recruiting ledgers are current for this boundary."), palette: palette)`,
   removing the hand-rolled `VStack`/`.background(palette.raised.color)` construction.
3. Replace `delegatedState`'s body with `CoachWorldSystemState(.delegated("Staff decision in
   progress. \(model.delegatedDecisionCount) delegated decision(s) remain with the assigned staff
   owner."), palette: palette)`, same removal.
4. Leave `decisions`, `summary`, `header`, and every `onCommit`/`onContinue`/`onClose` callback
   exactly as they are.

- [ ] **Step 8: Convert `SigningDayView.swift`**

Wrap the existing `Group { if model.cyclePhase == .signing { CollegeOffseasonView(...) } else {
ContentUnavailableView(...) } }` in `CoachWorldFloodlitStage(palette: palette) { ... }` (add a
`private var palette: CoachWorldTokens.Palette { CoachWorldTokens.dark }` computed property — this
file has none yet, since it never drew anything itself before). Replace the closed-state
`ContentUnavailableView("Signing day is closed", ...)` with `CoachWorldSystemState(.empty("Signing day
is closed. The signing period is not active in this phase."), palette: palette)`.

- [ ] **Step 9: Build**

```bash
swift build
```

- [ ] **Step 10: Run the recruiting-specific and design-contract lanes**

```bash
swift run SimTests --portal-contracts
swift run SimTests --career-portal-decisions
swift run SimTests --college-state
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift build
```

Expected: the "Floodlit surface conversion" suite reports a higher converted count than Phase 5's 28
(six new direct roots — `RecruitingBoardView`, `ProspectProfileView`, `ShortlistView`,
`ContactVisitPlannerView`, `ClassOverviewView`, `CollegeOffseasonView`, `SigningDayView` — that's
seven direct conversions, plus four wrapper fixpoints — `PortalHubView`, `RetentionDecisionsView`,
`PortalMarketView`, `NilAllocationView` — for eleven total newly converted).

- [ ] **Step 11: `detect_changes` against exactly this phase's paths**

```
mcp__gitnexus__detect_changes({scope: "unstaged"})
```

Review only the symbols and processes this phase's seven edited files touch. Do not stage or revert
any concurrent session's unrelated in-flight work.

- [ ] **Step 12: Adversarial review of the phase diff**

Same shape as Phases 3–5: independent dimension reviewers (canon compliance, structural correctness —
including the double-ground check on all seven roots, with particular attention to whether
`RecruitingBoardView`'s `boardSurface`-vs-`accessibleLayout` panel/remove distinction was applied
correctly — accessibility, behaviour preservation against this plan's presentation-only claim, and
specifically whether `CollegeOffseasonView`'s two folded messages read naturally as `.delegated`
output rather than losing meaning in the fold) each followed by adversarial verification of every
finding. Fix everything confirmed real before proceeding.

- [ ] **Step 13: Full suite**

```bash
swift run SimTests
```

- [ ] **Step 14: Commit**

Stage exactly this phase's files — the seven converted view files plus this plan doc — and commit as
`feat: convert Floodlit college surfaces`. Do not stage any concurrent session's unrelated files.

## Outcome

All seven roots converted; the conversion count moved 28 → 39, matching this plan's predicted +11
(seven direct roots plus the four `CollegeOffseasonView` wrapper fixpoints) exactly.

Two judgement calls, both recorded here because a reviewer would otherwise read them as scope creep:

- **`SigningDayView` needed its own stage wrap**, despite looking like a fifth thin wrapper. Its
  `else` branch draws a closed-signing-period state itself rather than delegating, so the delegation
  fixpoint would have marked the file "converted" off the `CollegeOffseasonView(` substring while that
  branch kept rendering an unstaged `ContentUnavailableView` on bare ground. A false positive in the
  coverage test, caught by reading the file rather than trusting the count — the
  "coverage boundary became the quality boundary" failure `CLAUDE.md` names.
- **`CollegeOffseasonView` adopted `.delegated`**, the one canon state (`04` §7) that had shipped in
  Phase 2's vocabulary but never reached a production screen. This file already hand-rolled exactly
  that condition in its own words; adopting the shared component removed a second spelling rather
  than adding scope.

### Two string-interpolation bugs fixed

A sweep for the defect class Phase 4's review first surfaced in `OpponentFilmView` (literal parens
where `\(...)` was intended) found two more, both now fixed:

- `DepthChartView.swift`'s personnel-option accessibility label — VoiceOver announced the literal
  text `(option.title). (option.consequence)`. Left untouched through Phase 5 because a separate
  session owned it; that session ended without landing the fix, so it was fixed here.
- **`ProspectProfileView.swift:92` was the worse one and nobody had flagged it**: the same bug in
  *visible on-screen copy*, rendering `Stable-ID dossier · (model.prospects.count +
  model.discovery.count) visible prospects` literally to the player. Found by widening the search from
  `accessibilityLabel(` to any string literal wrapping a Swift expression in bare parens. A
  repo-wide sweep now shows zero remaining instances of this class.
