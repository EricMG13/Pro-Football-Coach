# Floodlit Phase 9 — Career-Stakes and History Surfaces (registry 52–60)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the one remaining real presentation root in registry 52–60 to Floodlit. Landing it
closes out **all 62 registered surfaces** — the last phase in this cutover's surface-conversion arc
(Task Tasks 5–11 of the master plan).

**Architecture:** No new mechanism. `LegacyHistoryView` is the same shared-root-with-no-case-of-its-own
shape as `ProManagementView` (Phase 7) and `CompetitionOverviewView` (Phase 8) — reached only through
four pure-delegate wrappers, each supplying a different `focus:`.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness.

**Spec:** Task 11 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Preserve every field binding, callback, and accessibility declaration. Presentation-only.
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors.
- Both sessions still work directly in this shared checkout (no worktree isolation) — before any
  `git checkout`/`reset`, check `git status`/`git branch --show-current` first.

---

## Why this phase is nearly done before it starts

Registry 52–60 is nine screens:

```
case careerHub = 52
case jobSecurity = 53
case stakeholders = 54
case promotionDecision = 55
case coachingCarousel = 56
case recordBook = 57
case rivalries = 58
case careerLine = 59
case coachingTree = 60
```

**Five of these are already converted.** `CareerHubView` was converted in Phase 3 (Task 5) because it
is also the shared root `JobBoardView`/`OfferView`/`AppointmentView` (registry 3–5) delegate to — Phase
3's plan doc named this explicitly: "`CareerHubView` is in scope and it is not scope creep... converting
it also lands the presentation for 52–55 (Career Hub, Job Security, Stakeholders, Promotion Decision),
which Task 11 then verifies rather than converts." Confirmed directly: `JobSecurityView`,
`StakeholdersView`, `PromotionDecisionView`, `CoachingCarouselView` (52–56, minus 52 itself) are all
53-line pure delegates — `let content = CareerHubView(..., focus: .stakeholders, ...)` and nothing
else — so the delegation fixpoint in `AccessibilityReflowTests.swift` has counted all five as converted
since Phase 3 landed. This is why Phase 8 finished at 58/62 converted with exactly 4 pending, not 9:
the four pending are `recordBook`, `rivalries`, `careerLine`, `coachingTree` (57–60) — the
`LegacyHistoryView` family, the one root this cutover has not yet touched.

**`LegacyHistoryView` has no `CoachWorldScreenID` case of its own** — same shape as
`ProManagementView`/`CompetitionOverviewView` in Phases 7–8. Verified all four of its wrappers
(`RecordBookView`, `RivalriesView`, `CareerLineView`, `CoachingTreeView`, 21 lines each) by direct
read: every one is a pure delegate (`LegacyHistoryView(model:focus:statusMessage:onClose:onNavigate:)`
and nothing else), so converting `LegacyHistoryView` alone lands all four remaining screens through
the existing fixpoint — no wrapper needs its own edit, and none has the `SigningDayView`/`DraftRoomView`
hybrid shape that would need one.

## What `LegacyHistoryView` actually needs

157 lines. Plain `VStack { topBar; ...; ScrollView { section } }`, `.background(palette.page.color
.ignoresSafeArea())` at the root. Four `focus`-switched sections (`records`, `rivalries`, `careerLine`,
`coachingTree`), each with a bare-`Text` empty note. No `coachWorldDeskSurface`, no bare opacity
literal of the panel-border class — checked directly, clean. This is the smallest real conversion
target of any phase in this cutover.

## Steps

- [ ] **Step 1: Impact `LegacyHistoryView` and re-check `CareerHubView`'s graph**

Run GitNexus upstream impact for `LegacyHistoryView`. GitNexus has failed to resolve most `*View` type
names by fuzzy match throughout this cutover — direct source reading is the established fallback: it
is called only from `career` in `CoachWorldAppRootView.swift`, the same LOW-risk single-caller pattern
every prior phase has shown. Per the master plan's own Task 11 step 1, also re-run impact for
`CareerHubView` before touching anything near it, even though this phase makes no edit to it — its
graph may have shifted since Phase 3, and Task 11 is the phase that verifies 52–56, not just 57–60.

- [ ] **Step 2: Verify registry 52–56 needs no further work**

Read `CareerHubView.swift`'s current committed state (Phase 3, `9c77d4c`) and confirm it still:
preserves origin-aware close/navigation behaviour (the `focus:` parameter each wrapper supplies), uses
`CoachWorldFloodlitStage`, and has no `ContentUnavailableView`/bare-opacity-literal residue introduced
by any later phase's edits. Do not re-convert or restyle it — Task 11's own text calls this
verification, not conversion, for exactly this range. If a real gap is found, fix it as a named,
separately-justified deviation — do not silently expand this phase's scope to "redo Phase 3."

- [ ] **Step 3: Convert `LegacyHistoryView.swift`**

1. Wrap `body`'s `VStack { topBar; ...; ScrollView { section } }` in `CoachWorldFloodlitStage(palette:
   palette) { ... }`; delete the trailing `.foregroundStyle(palette.contentPrimary.color)` /
   `.background(palette.page.color.ignoresSafeArea())` pair.
2. `records`: replace the bare-`Text` empty note ("No team records recorded.") with
   `CoachWorldSystemState(.empty("No team records recorded."), palette: palette)`.
3. `rivalries`: replace the bare-`Text` empty note ("No rivalry recorded.") with
   `CoachWorldSystemState(.empty("No rivalry recorded."), palette: palette)`.
4. `careerLine`: replace the bare-`Text` empty note ("No recorded assignments.") with
   `CoachWorldSystemState(.empty("No recorded assignments."), palette: palette)`.
5. `coachingTree`: replace the bare-`Text` empty note ("No recorded coaching relationships.") with
   `CoachWorldSystemState(.empty("No recorded coaching relationships."), palette: palette)`.
6. Leave the `focus`-switched `section` computed property, the `Menu("Views")` navigation, and every
   accessibility label exactly as they are.

- [ ] **Step 4: Build**

```bash
swift build
```

- [ ] **Step 5: Run the career-arc and history-specific lanes plus design-contracts**

```bash
swift run SimTests --career-arc
swift run SimTests --history-read-model
swift run SimTests --m7-gate
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift build
```

Expected: the "Floodlit surface conversion" suite reports **62 converted, 0 pending** — every
registered surface in the app. This is the completion condition for the master plan's Task 2 step 4
("registry coverage non-vacuous... `expectEqual(landed.count, 62)`, `expect(pending.isEmpty, ...)`"),
which has been true of the *landed* enumeration since early in this cutover but only becomes true of
the *converted* enumeration now.

- [ ] **Step 6: `detect_changes` against exactly this phase's paths**

```
mcp__gitnexus__detect_changes({scope: "unstaged"})
```

`detect_changes` has under-reported the full changed-file set in recent phases even after a fresh
index — cross-check against `git status --porcelain` before drawing conclusions from a short result.
Review only the symbols and processes `LegacyHistoryView.swift` touches. Do not stage or revert any
concurrent session's unrelated in-flight work.

- [ ] **Step 7: Adversarial review of the phase diff**

Same shape as Phases 3–8, scaled to the one-file diff: canon compliance (no bare opacity literal, no
`coachWorldDeskSurface` residue), structural correctness (the double-ground check — the stage wrap
must not leave the old `.background(palette.page.color.ignoresSafeArea())` behind), accessibility
(every fold preserves the exact original message), behaviour preservation (the `focus`-switch and
`Menu` navigation untouched). Fix everything confirmed real before proceeding.

- [ ] **Step 8: Full suite**

```bash
swift run SimTests
```

- [ ] **Step 9: Commit**

Stage exactly `LegacyHistoryView.swift` plus this plan doc, and commit as
`feat: convert Floodlit career surfaces`. Do not stage any concurrent session's unrelated files.

## What comes after this phase

This closes Tasks 5–11 of the master plan — every one of the 62 registered surfaces is now Floodlit.
What remains in `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md` is not more conversion:
Task 12 (make dark appearance and unavailable-state handling authoritative at the app root — the
`CoachWorldAppRootView`/`RootView` guardrail and the `PROOF_SCREEN_NUMBER` debug seam), Task 13
(retire v3/light canon authority in the docs), Task 14 (the device verification matrix and UI test),
and Task 15 (final adversarial pass and completion gate). None of those is "Phase 10" in the sense
this session has used the word for a mechanical per-family conversion — each is a materially different
kind of work and should get its own scoped plan when taken up.
