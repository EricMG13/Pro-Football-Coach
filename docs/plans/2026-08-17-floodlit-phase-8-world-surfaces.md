# Floodlit Phase 8 — World, Competition, Statistics, and Event Surfaces (registry 41–51)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the ten real world/competition presentation roots (registry 41–51) to Floodlit —
the largest surface count of any single phase in this cutover, and the first time a phase must decide
which surfaces (if any) take the BROADCAST register outside the Match Day/Aftermath pair Phase 4
introduced it for.

**Architecture:** Same mechanical recipe as Phases 3–7. `CompetitionOverviewView` repeats the
`ProManagementView` shape from Phase 7 exactly — no `CoachWorldScreenID` case of its own, reached
only through its two wrappers (`RankingsPlayoffPictureView`, `BracketPostseasonView`), both pure
delegates with no branch of their own.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness.

**Spec:** Task 10 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Preserve every field binding, callback, selection/tier state, and accessibility declaration.
  Presentation-only, except the one register decision named below.
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors.
- Apply the accumulated lessons directly: every bounded card becomes `coachWorldFloodlitPanel` with
  `CoachWorldTokens.Depth.panelBorderOpacity`, never a bare opacity literal; a panel frames its pane
  and never wraps content from outside a `ScrollView`; a selection-tint literal
  (`palette.collegeIdentity.color.opacity(0.14)`, used for the controlled-team highlight in
  `StandingsView`/`ScheduleView`/`CompetitionOverviewView`) is a different, already-established
  convention from a panel border and is left untouched.
- Both sessions still work directly in this shared checkout (no worktree isolation) — before any
  `git checkout`/`reset`, check `git status`/`git branch --show-current` first.

---

## Registry mapping, verified against `ScreenRegistry.swift` directly

Phase 7's plan predicted one conversion too many by trusting the master plan's prose file map instead
of the registry source. Checked this phase's range the same way before writing anything else:

```
case leagueMap = 41
case teamProgrammeProfile = 42
case standings = 43
case schedule = 44
case rankingsPlayoffPicture = 45
case bracketPostseason = 46
case gameDetailBoxScore = 47
case statisticsLeaders = 48
case awardsHonours = 49
case news = 50
case realignmentEvent = 51
```

Eleven screens, all separately registered — unlike Phase 7's `ProManagementView`, every file in this
range (including the two `CompetitionOverviewView` wrappers) resolves to its own `CoachWorldScreenID`
case. Expected conversion delta: **+11**, matching the registry count exactly.

## Where the twelve files actually stand

| File | Registry | Current state | Work this phase does |
|---|---|---|---|
| `LeagueMapView.swift` | 41 | 672 lines, the largest this phase touches. Two-pane `standardLayout` (`mapSurface` + `detailRail`), separate `accessibleLayout`. One `ContentUnavailableView` each in `mapSurface` and `detailRail`. Hairline helpers already use `CoachWorldTokens.Depth.panelBorderOpacity` (fixed in the prior phase's tokenization cleanup). | Mechanical conversion. |
| `TeamProgrammeProfileView.swift` | 42 | 211 lines. Plain `VStack` + `ScrollView`, `topBar` outside the scroll. Three bare-`Text` empty notes (fixtures/rivals/traditions). | Mechanical conversion. |
| `StandingsView.swift` | 43 | 141 lines. Plain `VStack` + `ScrollView`. One bare `0.35` hairline opacity to tokenize. No empty state (a standings table always has rows once a career exists). | Mechanical conversion plus the one literal. |
| `ScheduleView.swift` | 44 | 130 lines. One `ContentUnavailableView` for an empty schedule. | Mechanical conversion. |
| `CompetitionOverviewView.swift` | — (shared, no case of its own) | 159 lines. Shared root for `RankingsPlayoffPictureView`/`BracketPostseasonView`. One bare-`Text` empty note for an empty bracket. | Mechanical conversion. |
| `GameDetailBoxScoreView.swift` | 47 | 87 lines. Drill-down of `AftermathReadModel` — same model, same recap flow as the already-BROADCAST `AftermathView`, reached via its "Back to aftermath" button. Grade rows use `.thinMaterial` and `.secondary`, the exact pre-Phase-4 `AftermathView` pattern. | Mechanical conversion **with the BROADCAST register** — see below. |
| `StatisticsLeadersView.swift` | 48 | 60 lines. Plain `VStack` + `ScrollView`. One bare-`Text` empty note. | Mechanical conversion. |
| `AwardsHonoursView.swift` | 49 | 57 lines. Same shape as `StatisticsLeadersView`. One bare-`Text` empty note. | Mechanical conversion, DESK register — see below. |
| `NewsView.swift` | 50 | 94 lines. One `ContentUnavailableView`, row cards at `.opacity(0.72)`. | Mechanical conversion plus the one card-fill literal. |
| `RealignmentEventView.swift` | 51 | 69 lines. One bare-`Text` "no event" note, swap cards with no background at all (plain text rows). | Mechanical conversion, DESK register — see below. |
| `RankingsPlayoffPictureView.swift` | 45 | 36 lines. Pure wrapper, delegates wholly to `CompetitionOverviewView(focus: .rankingsPlayoffPicture, ...)`. | No edit — converts via the delegation fixpoint. |
| `BracketPostseasonView.swift` | 46 | 36 lines. Pure wrapper, delegates wholly to `CompetitionOverviewView(focus: .bracketPostseason, ...)`. | No edit. |

Verified both wrappers by direct read: neither contains `ContentUnavailableView` or any composition of
its own, so — unlike `SigningDayView`/`DraftRoomView` in Phases 6–7 — the plain delegation fixpoint is
correct here without needing its own stage wrap.

## The register decision: one BROADCAST surface, not three

Task 10's step 3 says to "convert event surfaces to BROADCAST where appropriate: box scores, awards
ceremony moments, and realignment announcements." Read literally that names three files. Applied to
what these three files actually are, only one holds up:

- **`GameDetailBoxScoreView` becomes BROADCAST.** It reads the identical `AftermathReadModel` the
  already-BROADCAST `AftermathView` reads, is reached only from `AftermathView`'s own "Back to
  aftermath" button, and shows the same match's grades and evidence at more depth. It is not a
  separate kind of surface — it is the same recap flow, one screen deeper. Giving it the flat
  BROADCAST ground `AftermathView` already has, rather than the gradient/glow DESK backdrop, keeps
  that flow visually continuous rather than having the coach's world lounge-lighting flash on for one
  screen and off again.
- **`AwardsHonoursView` and `RealignmentEventView` stay DESK.** Nothing about their current
  implementation or read model resembles a live moment: both are flat, paginated archival lists —
  structurally identical to `StatisticsLeadersView` (also in this phase) and `StandingsView`/
  `ScheduleView` (already DESK from this same phase). "Awards ceremony" and "realignment
  announcement" describe a presentation neither view actually has — no ceremony framing, no
  announcement beat, just a `ForEach` over past records. Registering them BROADCAST would be staging
  content that is not there rather than converting content that is, which is exactly what the
  render-recorded-match precedent (Phase 4) and CLAUDE.md's scope guard both warn against: "no new
  engine or inferred probability," extended here to no new presentational drama the read model does
  not carry. If a future phase gives these screens an actual ceremony/announcement composition, that
  is the moment to revisit the register — not before.

## What "converted" means here (unchanged from Phases 3–7)

1. Wrap the root's content in `CoachWorldFloodlitStage(palette: palette)` (or
   `CoachWorldFloodlitStage(palette: palette, register: .broadcast)` for `GameDetailBoxScoreView`
   only); delete the file's own `.foregroundStyle(palette.contentPrimary.color)` /
   `.background(palette.page.color.ignoresSafeArea())` pair.
2. Any bounded card becomes `.coachWorldFloodlitPanel(fill:border:)` with
   `CoachWorldTokens.Depth.panelBorderOpacity`, never a bare opacity literal.
3. Replace every `ContentUnavailableView(...)` and bare-`Text` empty note with
   `CoachWorldSystemState(.empty(...), palette: palette)`, folding title + description into one
   sentence wherever the original was a two-part `ContentUnavailableView`.
4. Preserve every binding, callback, selection state, and accessibility declaration verbatim.

## Steps

- [ ] **Step 1: Impact the ten real roots**

Run GitNexus upstream impact for all ten files before editing. GitNexus has failed to resolve most
`*View` type names by fuzzy match throughout this cutover even after a fresh index — direct source
reading is the established fallback: every file here is called only from `career` in
`CoachWorldAppRootView.swift`, the same LOW-risk single-caller pattern every prior phase has shown.

- [ ] **Step 2: Convert `LeagueMapView.swift`**

1. Wrap `body`'s `Group { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
   trailing `.foregroundStyle`/`.background` pair.
2. `mapSurface`: replace `ContentUnavailableView("No places to show", ...)` with
   `CoachWorldSystemState(.empty("No places to show. Programmes appear here when a world is
   loaded."), palette: palette)`.
3. `detailRail`'s `else` branch: replace `ContentUnavailableView("No place selected", ...)` with
   `CoachWorldSystemState(.empty("No place selected. Choose a programme on the map to read its
   place."), palette: palette)`.
4. Leave `tier`/`selectedPlaceID` state, the `onChange` handler, `LeagueMapLayout`, and every
   accessibility label exactly as they are.

- [ ] **Step 3: Convert `TeamProgrammeProfileView.swift`**

Wrap `body`'s `VStack { topBar; ...; ScrollView { ... } }` in `CoachWorldFloodlitStage(palette:
palette) { ... }`; delete the trailing `.foregroundStyle`/`.background` pair. Replace the three
bare-`Text` empty notes with `CoachWorldSystemState(.empty(...), palette: palette)`, each keeping its
existing sentence: `fixtures`'s "No fixtures recorded", `rivals`'s "No rivalry recorded", `traditions`'s
"No traditions recorded".

- [ ] **Step 4: Convert `StandingsView.swift`**

Wrap `body`'s `VStack { topBar; ...; ScrollView { ... } }` in `CoachWorldFloodlitStage(palette:
palette) { ... }`; delete the trailing `.foregroundStyle`/`.background` pair. In
`standingsRow(index:row:)`, replace `.fill(palette.contentQuiet.color.opacity(0.35))` with `.fill
(palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))`. Leave the
`0.14`-opacity controlled-row highlight untouched — that is the selection-tint convention, not a
panel border.

- [ ] **Step 5: Convert `ScheduleView.swift`**

Wrap `body`'s `VStack { topBar; ...; if/else }` in `CoachWorldFloodlitStage(palette: palette) { ... }`;
delete the trailing `.foregroundStyle`/`.background` pair. Replace `ContentUnavailableView("No
\(model.tier.lowercased()) games", ...)` with `CoachWorldSystemState(.empty("No \(model.tier
.lowercased()) games. The schedule is empty for this season."), palette: palette)` — the message is
interpolated per-tier, so the fold must preserve `model.tier` in the sentence, not hard-code a tier
name.

- [ ] **Step 6: Convert `CompetitionOverviewView.swift`**

Wrap `surface`'s `VStack { topBar; ...; ScrollView { ... } }` in `CoachWorldFloodlitStage(palette:
palette) { ... }`; delete the trailing `.foregroundStyle`/`.background` pair. Replace `bracket`'s
bare-`Text` empty note ("No postseason games are scheduled yet.") with
`CoachWorldSystemState(.empty("No postseason games are scheduled yet."), palette: palette)`. Leave
`rankings` untouched — it has no empty state (no ranking is ever an empty list once a season starts).

- [ ] **Step 7: Convert `GameDetailBoxScoreView.swift` — BROADCAST**

1. Wrap `content(palette:)`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette,
   register: .broadcast) { ... }`, called from `body` with `CoachWorldTokens.dark` as before; delete
   the trailing `.foregroundStyle`/`.background` pair.
2. Replace `.foregroundStyle(.secondary)` (the empty-evidence-section fallback text) with
   `.foregroundStyle(palette.contentSecondary.color)`.
3. Replace the grade row's `.background(.thinMaterial, in: RoundedRectangle(cornerRadius:
   CoachWorldTokens.Shape.surfaceRadius))` with `.coachWorldFloodlitPanel(fill: palette.raised.color,
   border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))` — the same
   fix Phase 4 already applied to `AftermathView`'s identical pattern.
4. Leave `evidenceSection`'s empty-string fallback behaviour and the "Back to aftermath" button
   exactly as they are — that button already carries no explicit `buttonStyle`, matching the
   convention every other bare "League"/"Done" navigation button in this phase's files uses; do not
   add one.

- [ ] **Step 8: Convert `StatisticsLeadersView.swift`**

Wrap `body`'s `VStack { ...; ScrollView { ... } }` in `CoachWorldFloodlitStage(palette: palette) {
... }`; delete the trailing `.foregroundStyle`/`.background` pair. Replace the bare-`Text` empty note
("No player statistics recorded.") with `CoachWorldSystemState(.empty("No player statistics
recorded."), palette: palette)`.

- [ ] **Step 9: Convert `AwardsHonoursView.swift` — DESK**

Wrap `body`'s `VStack { ...; ScrollView { ... } }` in `CoachWorldFloodlitStage(palette: palette) {
... }` (default register — see the register decision above); delete the trailing
`.foregroundStyle`/`.background` pair. Replace the bare-`Text` empty note ("No archived honours
recorded.") with `CoachWorldSystemState(.empty("No archived honours recorded."), palette: palette)`.

- [ ] **Step 10: Convert `NewsView.swift`**

Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the
trailing `.foregroundStyle`/`.background` pair. Replace `ContentUnavailableView("No news recorded",
...)` with `CoachWorldSystemState(.empty("No news recorded. Typed world events will appear here when
they become newsworthy."), palette: palette)`. Replace each item row's `.background(palette
.raised.color.opacity(0.72))` with `.coachWorldFloodlitPanel(fill: palette.raised.color, border:
palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))`.

- [ ] **Step 11: Convert `RealignmentEventView.swift` — DESK**

Wrap `body`'s `VStack { ...; ScrollView { ... } }` in `CoachWorldFloodlitStage(palette: palette) {
... }` (default register — see the register decision above); delete the trailing
`.foregroundStyle`/`.background` pair. Replace the bare-`Text` empty note ("No realignment event
recorded.") with `CoachWorldSystemState(.empty("No realignment event recorded."), palette: palette)`.

- [ ] **Step 12: Build**

```bash
swift build
```

- [ ] **Step 13: Run the competition/world-specific and design-contract lanes**

```bash
swift run SimTests --competition-only
swift run SimTests --realignment
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift build
```

Expected: the "Floodlit surface conversion" suite reports Phase 7's 47 plus 11, for 58.

- [ ] **Step 14: `detect_changes` against exactly this phase's paths**

```
mcp__gitnexus__detect_changes({scope: "unstaged"})
```

GitNexus's `detect_changes` has under-reported the full changed-file set in a recent phase even after
a fresh index — treat a short result as informative, not exhaustive; cross-check against `git status
--porcelain` for the real file list before drawing conclusions from it. Review only the symbols and
processes this phase's ten edited files touch. Do not stage or revert any concurrent session's
unrelated in-flight work.

- [ ] **Step 15: Adversarial review of the phase diff**

Same shape as Phases 3–7: independent dimension reviewers (canon compliance — including an exhaustive
grep for any surviving bare opacity literal, the class of miss that took a full review pass to catch
in Phase 6; structural correctness — double-ground check on all ten roots, and specifically whether
`GameDetailBoxScoreView`'s BROADCAST register was applied without also giving it any desk chrome the
register decision explicitly ruled out; accessibility; behaviour preservation against this plan's
presentation-only claim) each followed by adversarial verification of every finding. Fix everything
confirmed real before proceeding.

- [ ] **Step 16: Full suite**

```bash
swift run SimTests
```

- [ ] **Step 17: Commit**

Stage exactly this phase's files — the ten converted view files plus this plan doc — and commit as
`feat: convert Floodlit world surfaces`. Do not stage any concurrent session's unrelated files.
