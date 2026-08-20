# Floodlit Phase 7 — Professional-Management and Offseason Surfaces (registry 34–40, 62)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the four real professional-management presentation roots (registry 34–40, 62) to
Floodlit — the pro-side mirror of Phase 6's college conversion, including the second occurrence of
Phase 6's "delegate on one branch, draw unstaged content on the other" pattern.

**Architecture:** Same mechanical recipe as Phases 3–6. `DraftRoomView` repeats `SigningDayView`'s
shape exactly (delegates to a shared root only in one phase, otherwise draws its own
`ContentUnavailableView`) — the fixpoint guard Phase 6's review added
(`AccessibilityReflowTests.swift`'s `drawsItsOwnUnconvertedState` check) already treats a file like
this as unconverted from the mention alone, so this is verification that the general fix holds, not a
new special case.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness.

**Spec:** Task 9 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Preserve every field binding, callback, negotiation/stepper state, and accessibility declaration.
  Presentation-only — no vocabulary adoption this phase (unlike Phase 6's `.delegated` adoption,
  nothing here maps onto an unused canon state).
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors.
- Both sessions still work directly in this shared checkout (no worktree isolation) — before any
  `git checkout`/`reset`, check `git status`/`git branch --show-current` first.
- Apply the Phase 6 review's lessons directly, not just as a checklist to re-run afterward:
  1. Any bounded card (half the screen or a list row) becomes `coachWorldFloodlitPanel`, never a bare
     `.background(color.opacity(n))` — that combination is untokenized glass with no Reduce
     Transparency branch, confirmed real in four Phase 6 sites.
  2. A panel wraps its *pane*, never scrolling content inside it — if a `ScrollView` sits beside the
     panel rather than inside it, the panel will size to content height instead of pane height.
  3. Use `CoachWorldTokens.Depth.panelBorderOpacity`, never a bare `0.38`/`0.7`/`0.72`.

---

## Where the nine files actually stand

| File | Registry | Current state | Work this phase does |
|---|---|---|---|
| `ProManagementView.swift` | 34 | 184 lines. Plain `ScrollView`, no panels (roster rows use bare `.background(palette.raised.color.opacity(0.7))`), one bare-`Text` empty note per roster section ("No contracted players are recorded here."). | Mechanical conversion; promote the two bare-`Text` empty notes and the row backgrounds. |
| `ContractNegotiationView.swift` | 35 | 232 lines. Two sections (`activeNegotiations`, `startNegotiations`), a nested `NegotiationCard` view with its own stepper/text-field state. Bare-`Text` empty note ("No contract offers are on file."). Cards use `.background(palette.raised.color.opacity(0.72))`. | Mechanical conversion. `NegotiationCard`'s own background needs the same panel treatment as the rest — it is a bounded card, not a full-screen paint. |
| `ProOffseasonView.swift` | 36 | 275 lines. Three sections (`prospectsSection`, `freeAgentsSection`, `waiversSection`), each with its own bare-`Text` empty note and `.background(palette.raised.color.opacity(0.7))` rows. Shared root for `DraftRoomView`, `ProScoutingBoardView`, `DraftBoardView`, `FreeAgencyView`. | Mechanical conversion. |
| `DraftRoomView.swift` | 37 | 45 lines. **Not a pure wrapper** — delegates to `ProOffseasonView` only when `model.phase == .draft`; otherwise draws its own unstaged `ContentUnavailableView("Draft room is closed", ...)`. Exact repeat of `SigningDayView`'s Phase 6 shape. | Needs its own `CoachWorldFloodlitStage` wrap for the closed branch, same fix as `SigningDayView`. |
| `CapContractsView.swift` | 38 | 26 lines. Pure wrapper, delegates wholly to `ProManagementView`. | No edit — converts via the delegation fixpoint. |
| `RosterCutsTransactionsView.swift` | 39 | 26 lines. Pure wrapper, delegates wholly to `ProManagementView`. | No edit. |
| `ProScoutingBoardView.swift` | 40 | 34 lines. Pure wrapper, delegates wholly to `ProOffseasonView`. | No edit. |
| `DraftBoardView.swift` | 62 | 34 lines. Pure wrapper, delegates wholly to `ProOffseasonView`. | No edit. |
| `FreeAgencyView.swift` | — (thin wrapper per master plan's file map, not separately registered) | 34 lines. Pure wrapper, delegates wholly to `ProOffseasonView`. | No edit. |

Verified each of the five short files by direct read: none contains `ContentUnavailableView` or any
composition of its own — only `CapContractsView`/`RosterCutsTransactionsView` call
`ProManagementView(...)`, and `ProScoutingBoardView`/`DraftBoardView`/`FreeAgencyView` call
`ProOffseasonView(...)`, each with only a different `title:` and nothing else.

## What "converted" means here (unchanged from Phases 3–6)

1. Wrap the root's content in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete the file's
   own `.foregroundStyle(palette.contentPrimary.color)` / `.background(palette.page.color
   .ignoresSafeArea())` pair.
2. Any bounded card — a roster row, a negotiation card, a prospect/free-agent/waiver row — becomes
   `.coachWorldFloodlitPanel(fill: palette.raised.color, border: palette.contentQuiet.color.opacity
   (CoachWorldTokens.Depth.panelBorderOpacity))`, replacing `.background(palette.raised.color
   .opacity(0.7))` / `.opacity(0.72)`.
3. Replace every bare-`Text` empty note with `CoachWorldSystemState(.empty(...), palette: palette)`,
   carrying the existing sentence over unchanged — this covers `ProManagementView`,
   `ContractNegotiationView`, and `ProOffseasonView`'s three sections. `DraftRoomView`'s closed branch
   is the one exception: it comes from a two-part `ContentUnavailableView(title, description:)`, same
   as `SigningDayView` in Phase 6, and folds title and description into one sentence the same way —
   see Step 5.
4. Preserve every binding, callback, and accessibility declaration verbatim.

## Steps

- [ ] **Step 1: Impact the four real roots**

Run GitNexus upstream impact for `ProManagementView`, `ContractNegotiationView`, `ProOffseasonView`,
and `DraftRoomView` before editing. GitNexus has failed to resolve several `*View` type names by
fuzzy match throughout this cutover (a known quirk, confirmed again for all four here even after a
fresh index) — direct source reading is the established fallback: all four are called only from
`career` in `CoachWorldAppRootView.swift`, the same LOW-risk single-caller pattern every prior phase
has shown.

- [ ] **Step 2: Convert `ProManagementView.swift`**

1. Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete
   the trailing `.foregroundStyle`/`.background` pair.
2. `rosterSection`: replace the bare-`Text` empty note ("No contracted players are recorded here.")
   with `CoachWorldSystemState(.empty("No contracted players are recorded here."), palette:
   palette)`. Replace each row's `.background(palette.raised.color.opacity(0.7))` with
   `.coachWorldFloodlitPanel(fill: palette.raised.color, border: palette.contentQuiet.color.opacity
   (CoachWorldTokens.Depth.panelBorderOpacity))`.
3. Leave `onAction`/`onClose`, `summaryCell`, and every accessibility label exactly as they are.

- [ ] **Step 3: Convert `ContractNegotiationView.swift`**

1. Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete
   the trailing `.foregroundStyle`/`.background` pair.
2. `activeNegotiations`: replace the bare-`Text` empty note ("No contract offers are on file.") with
   `CoachWorldSystemState(.empty("No contract offers are on file."), palette: palette)`.
3. `startNegotiations`: replace each row's `.background(palette.raised.color.opacity(0.72))` with the
   same panel treatment as step 2.2.
4. `NegotiationCard.body`: replace `.background(palette.raised.color.opacity(0.72))` with
   `.coachWorldFloodlitPanel(fill: palette.raised.color, border: palette.contentQuiet.color.opacity
   (CoachWorldTokens.Depth.panelBorderOpacity))` — this card is a bounded element inside a scrolling
   list, exactly the class of surface the panel modifier is for.
5. Leave `NegotiationCard`'s `@State private var years/baseSalary/signingBonus`, the `Stepper`,
   `TextField`s, and every `onAction` closure (`counterNegotiation`/`acceptNegotiation`/
   `rejectNegotiation`/`withdrawNegotiation`/`beginNegotiation`) exactly as they are.

- [ ] **Step 4: Convert `ProOffseasonView.swift`**

1. Wrap `body`'s `ScrollView { ... }` in `CoachWorldFloodlitStage(palette: palette) { ... }`; delete
   the trailing `.foregroundStyle`/`.background` pair.
2. `emptyText(_:)` (the shared helper `prospectsSection`/`freeAgentsSection`/`waiversSection` all
   call): replace its `Text(text).foregroundStyle(palette.contentSecondary.color)` body with
   `CoachWorldSystemState(.empty(text), palette: palette)` — converting the one helper converts all
   three call sites at once; do not touch the three call sites themselves.
3. `prospectsSection`'s row and `row(title:detail:action:)` (used by `freeAgentsSection` and
   `waiversSection`): replace `.background(palette.raised.color.opacity(0.7))` with the same panel
   treatment as Step 2.2.
4. Leave `phaseLabel`, `summaryCell`, `actionButton`, and every accessibility label exactly as they
   are.

- [ ] **Step 5: Convert `DraftRoomView.swift`**

Add `private var palette: CoachWorldTokens.Palette { CoachWorldTokens.dark }` (this file has none
yet — like `SigningDayView` before Phase 6, it never drew anything itself). Wrap the existing `Group {
if model.phase == .draft { ProOffseasonView(...) } else { ContentUnavailableView(...) } }` in
`CoachWorldFloodlitStage(palette: palette) { ... }`. Replace the closed-room
`ContentUnavailableView("Draft room is closed", ...)` with `CoachWorldSystemState(.empty("Draft room
is closed. The controlled draft clock is not active in this phase."), palette: palette)`.

- [ ] **Step 6: Build**

```bash
swift build
```

- [ ] **Step 7: Run the professional-specific and design-contract lanes**

```bash
swift run SimTests --pro-management
swift run SimTests --pro-market
swift run SimTests --cap-compliance
swift run SimTests --pro-draft-probe
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift build
```

Expected: the "Floodlit surface conversion" suite reports a higher converted count than Phase 6's 39.

**Correction found at this step, recorded rather than silently fixed:** the count rose by 8, not the
9 predicted above. `ProManagementView.swift` has no `CoachWorldScreenID` case of its own — unlike
every other "direct root" in this cutover, it is reached only through `CapContractsView` and
`RosterCutsTransactionsView`, so it was never going to appear as its own landed family regardless of
conversion; the prediction double-counted it. The eight real screens — `capContracts` (34),
`contractNegotiation` (35), `rosterCutsTransactions` (36), `proScoutingBoard` (37), `draftBoard` (38),
`draftRoom` (39), `freeAgency` (40), `proOffseason` (62) — landed exactly as Task 9's own "(34-40, 62)"
range names, confirmed against `ScreenRegistry.swift` directly rather than assumed from the master
plan's prose file map.

- [ ] **Step 8: `detect_changes` against exactly this phase's paths**

```
mcp__gitnexus__detect_changes({scope: "unstaged"})
```

Review only the symbols and processes this phase's four edited files touch. Do not stage or revert
any concurrent session's unrelated in-flight work.

- [ ] **Step 9: Adversarial review of the phase diff**

Same shape as Phases 3–6, and apply the Phase 6 lessons as explicit dimension prompts rather than
hoping they get rediscovered: canon compliance (in particular, no bare opacity literal survived —
grep the diff for `.opacity(0.7` / `.opacity(0.72` / `.opacity(0.38` before dispatching review
agents, the same class of miss that took a full review pass to catch last phase), structural
correctness (double-ground check on all four roots; verify no panel ended up wrapping a `ScrollView`
from outside rather than framing it — the `boardSurface` mistake from Phase 6), accessibility, and
behaviour preservation against this plan's presentation-only claim, with particular attention to
`NegotiationCard`'s stepper/text-field/action wiring. Fix everything confirmed real before
proceeding.

- [ ] **Step 10: Full suite**

```bash
swift run SimTests
```

- [ ] **Step 11: Commit**

Stage exactly this phase's files — the four converted view files plus this plan doc — and commit as
`feat: convert Floodlit pro surfaces`. Do not stage any concurrent session's unrelated files.
