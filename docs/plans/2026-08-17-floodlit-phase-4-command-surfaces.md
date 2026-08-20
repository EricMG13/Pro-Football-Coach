# Floodlit Phase 4 — Weekly Command and Tactical Surfaces (registry 8–15)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the eight weekly-command presentation roots (registry 8–15) to Floodlit, and — as
the phase's one piece of new foundation — introduce the DESK/BROADCAST register distinction so
Match Day and Aftermath get a materially different, chrome-free treatment instead of the glass-panel
desk backdrop.

**Architecture:** Same as Phases 1–3: `CoachWorldFloodlitStage` owns the committed dark world;
convert presentation roots in place; preserve every binding, callback, and accessibility declaration.
New this phase: `CoachWorldFloodlitStage` gains a `register:` parameter so the backdrop can be
suppressed for broadcast surfaces without a second stage type.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness.

**Spec:** Task 6 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`. Match Day's
structural contract (five controls, 22 actors, field/end-zone/line requirements, staff-interruption
paths) is also governed by the `render-recorded-match` skill
(`.claude/skills/render-recorded-match/SKILL.md`) — this plan does not relitigate that contract, only
adds the Floodlit dark commitment on top of it.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Preserve every field binding, callback, validation rule, and accessibility declaration; this phase
  is presentation-only except the one documented addition below.
- `render-recorded-match` skill, restated because it directly bears on this phase: "Suppress
  management navigation during Match... Avoid desk chrome, cards, gradients, glow, and decorative
  broadcast effects." Match Day already satisfies the structural half (5 controls, 22 actors, both
  end zones, line-of-scrimmage/first-down marks, causal lower-third, staff call-in Accept/Dismiss/
  Inspect); this phase must not regress it or bolt desk chrome onto it.
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors of code this phase
  does not touch.

---

## Where the eight files actually stand

Read in full before writing this plan. Three groups, not one:

| File | Registry | Current state | Work this phase does |
|---|---|---|---|
| `CoachingHQView.swift` | 8 | **Already Floodlit** — wraps in `CoachWorldFloodlitStage`, uses `coachWorldFloodlitPanel`/`CoachWorldRouteButton` throughout. Landed in an earlier "coach world surfaces" checkpoint, before this cutover's Phase 1. | Verify only — no edit expected. If the verify step finds a real gap, fix it as a named deviation, not silently. |
| `InboxView.swift`, `OpponentFilmView.swift`, `GamePlanView.swift`, `PracticePlanView.swift`, `TeamHealthView.swift` | 9, 10, 11, 12, 13 | Same pre-conversion shape as every Phase 3 target: `CoachWorldTokens.dark` palette already, plain `ScrollView` + `.background(palette.page.color.ignoresSafeArea())`, `ContentUnavailableView` for empty states, `RoundedRectangle(cornerRadius: rowRadius).stroke(...)` for rows. | Mechanical DESK conversion, identical recipe to Phase 3. |
| `OpponentReportFilmRoomView.swift` | — (thin wrapper only) | 36 lines, delegates wholly to `OpponentFilmView`. | Nothing to edit — `floodlitConvertedTypes()`'s fixpoint (Phase 3) already marks it converted once `OpponentFilmView` is. |
| `MatchDayView.swift`, `AftermathView.swift` | 14, 15 | `MatchDayView` already satisfies the render-recorded-match structural contract (5 controls, 22 actors, field, scorebug, lower-third, interruption rail); neither wraps in the stage yet. `AftermathView` uses system `.thinMaterial`/`.bordered`/`.secondary` rather than palette tokens. | BROADCAST register conversion (new, see below). |

Row-level borders in the five DESK files use `contentQuiet.color.opacity(0.6)`/`0.65`/`0.72` — not
the `0.38` literal the Phase 3 adversarial review flagged and spun off as a separate task. No overlap
with that follow-up; leave those row values as they are, matching the existing convention every other
row in the app already uses.

---

## The register decision

The master plan (Task 3) specified `CoachWorldStage(register: .desk | .broadcast)`; Phase 1 shipped
`CoachWorldFloodlitStage(palette:)` instead, with no register, because DESK was the only consumer at
the time (documented as a deviation in the Phase 3 plan). Match Day is the first surface that
actually needs the other branch, so this is where the register lands — extending the existing type
rather than inventing a second one.

**What differs between registers, concretely:** the DESK backdrop
(`CoachWorldFloodlitBackdrop` — a three-stop linear gradient, a gold radial glow, and a faint
pitch-band Canvas ambient) and the grain overlay are both exactly what the render-recorded-match
skill's "avoid desk chrome, cards, gradients, glow, and decorative broadcast effects" rules out for a
live match surface. BROADCAST therefore paints flat `palette.page.color` and nothing else in the
stage layer — no gradient, no glow, no grain. The `floodlit-stage` accessibility identifier is kept
for both registers unconditionally, because Task 14's registry-wide UI test
(`testEveryRegisteredSurfaceRendersFloodlitOrUnavailable`) checks for it on every one of the 62
surfaces, broadcast included.

The register governs the stage's own backdrop only. It says nothing about how a broadcast screen's
*content* is composed — `AftermathView`'s evidence/grade rows still adopt `coachWorldFloodlitPanel`
like any other report surface; only the page-level backdrop goes flat.

**Files:**

- Modify: `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift`
- Test: `Tests/SimTests/Suites/ContractTests.swift`

- [ ] **Step 1: Impact `CoachWorldFloodlitStage` before editing it**

Run GitNexus upstream impact for `CoachWorldFloodlitStage`. It is a shared type with six existing
call sites (`CareerHubView`, `CoachingHQView`, `NewCareerSetupView`, `SettingsAccessibilityView`,
`TitleContinueView`, `WorldSearchView`); confirm the change is additive (a new parameter with a
default) so none of the six need editing, and stop to re-scope if GitNexus reports anything beyond
those six call sites.

- [ ] **Step 2: Write the failing contract**

Add to `Tests/SimTests/Suites/ContractTests.swift`, inside the existing "Floodlit vocabulary
(Task 4)" suite:

```swift
test("the broadcast register renders no desk backdrop or grain") {
    let sourcePath = "Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift"
    guard let text = try? String(contentsOfFile: sourcePath, encoding: .utf8) else {
        fail("could not read \(sourcePath)")
        return
    }
    expect(text.contains("enum CoachWorldRegister"),
           "CoachWorldFloodlitStage has no register type to select broadcast's flat backdrop")
    expect(text.contains("register == .desk"),
           "the backdrop/grain are not conditioned on the register, so broadcast would inherit desk chrome")
}
```

- [ ] **Step 3: Run it and confirm red**

```bash
swift run SimTests --core-contracts
```

Expected: FAIL — `CoachWorldRegister` does not exist yet.

- [ ] **Step 4: Add the register**

In `CoachWorldDeskComponents.swift`, add the enum next to `CoachWorldFloodlitPanelDepth` and thread
it through the stage:

```swift
/// DESK gets the full committed backdrop (gradient, glow, grain). BROADCAST is flat `page.color`
/// only — the render-recorded-match contract forbids desk chrome, gradients, and glow on a live
/// match surface, so Match Day and Aftermath opt out rather than inheriting it.
enum CoachWorldRegister {
    case desk
    case broadcast
}
```

Change `CoachWorldFloodlitStage`:

```swift
struct CoachWorldFloodlitStage<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let palette: CoachWorldTokens.Palette
    let register: CoachWorldRegister
    @ViewBuilder let content: () -> Content

    init(
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark,
        register: CoachWorldRegister = .desk,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.register = register
        self.content = content
    }

    var body: some View {
        ZStack {
            palette.page.color
            if register == .desk {
                CoachWorldFloodlitBackdrop(palette: palette)
            }
            content()
            if register == .desk, !reduceTransparency {
                CoachWorldGrainOverlay()
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("floodlit-stage")
    }
}
```

The default parameter keeps all six existing call sites source-compatible; none of Phases 1–3's
files need to change.

- [ ] **Step 5: Confirm green, then leave it uncommitted**

```bash
swift build
swift run SimTests --core-contracts
```

Continue immediately into the file conversions below — this is one phase, one commit, matching
Phases 1–3.

---

## Converting the five mechanical DESK files

**Files:** `InboxView.swift`, `OpponentFilmView.swift`, `GamePlanView.swift`, `PracticePlanView.swift`,
`TeamHealthView.swift`.

- [ ] **Step 1: Impact each view type**

Run GitNexus upstream impact for all five public view structs before editing. Expect LOW/MEDIUM —
these are route-terminal presentation roots; stop and re-scope on anything HIGH/CRITICAL.

- [ ] **Step 2: Apply the Phase 3 recipe to each**

Per file:
1. Wrap the existing top-level content in `CoachWorldFloodlitStage(palette: palette) { ... }`.
2. Delete the file's own `.background(palette.page.color.ignoresSafeArea())` and
   `.foregroundStyle(palette.contentPrimary.color)` lines — the stage supplies both; keeping either
   double-paints over the backdrop the stage just asked for (the exact defect Phase 3's contract
   test exists to catch).
3. Replace `ContentUnavailableView(...)` with `CoachWorldSystemState(.empty(...), palette: palette)`,
   carrying the same message text.
4. Leave row-level `RoundedRectangle(cornerRadius: rowRadius).stroke(...)` treatments as they are —
   that is the established convention for list rows across the app, not something Phases 1–3 changed.
5. Preserve every binding, callback, and existing `accessibilityLabel`/`accessibilityHint` verbatim.

- [ ] **Step 3: Verify AX5 and VoiceOver order are unaffected**

Every one of the five already declares `dynamicTypeSize.isAccessibilitySize` and
`accessibilitySortPriority`; confirm the wrap doesn't remove either.

- [ ] **Step 4: Build**

```bash
swift build
```

---

## Converting Match Day and Aftermath to BROADCAST

**Files:** `MatchDayView.swift`, `AftermathView.swift`.

- [ ] **Step 1: Impact both view types**

Run GitNexus upstream impact for `MatchDayView` and `AftermathView`. The master plan calls out
`MatchDayView` as "high-fan-out proof and production surface" — read whatever GitNexus reports before
touching it, and stop if it names a process this plan doesn't already account for.

- [ ] **Step 2: Convert `MatchDayView`**

Wrap `body`'s existing `Group { ... }` in `CoachWorldFloodlitStage(palette: palette, register: .broadcast) { ... }`
and delete the file's own `.background(palette.page.color.ignoresSafeArea())`. Keep
`.foregroundStyle` off the view (the stage already supplies `contentPrimary`) and keep the
`.sheet(isPresented: $showsEvidence)` modifier where it is. Do **not** touch `scorebug`, `field`,
`lowerThird`, `controlBar`, `interruptionRail`, or `evidenceSheet` — they already satisfy the
render-recorded-match structural contract and already avoid desk chrome (plain `Rectangle`
backgrounds, no `coachWorldFloodlitPanel`, no `CutCorner`). Adding either now would be the
regression the skill warns against, not an improvement.

- [ ] **Step 3: Convert `AftermathView`**

This one needs real edits, not just a wrap — it currently uses system-default styling
(`.thinMaterial`, `.bordered`, `.borderedProminent`, `.secondary`) rather than Floodlit tokens:

1. Wrap `content(palette:)`'s `ScrollView` in `CoachWorldFloodlitStage(palette: palette, register: .broadcast) { ... }`, called from `body` with `CoachWorldTokens.dark` as before; delete the trailing `.foregroundStyle`/`.background` pair.
2. Replace `.foregroundStyle(.secondary)` (the result line) with `.foregroundStyle(palette.contentSecondary.color)`.
3. Replace the grade row's `.background(.thinMaterial, in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius))` with `.coachWorldFloodlitPanel(fill: palette.raised.color, border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))`.
4. Replace `Button("Open box score", ...).buttonStyle(.bordered)` with `.buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))`.
5. Replace `Button("Continue to HQ", ...).buttonStyle(.borderedProminent)` with `.buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))`.

- [ ] **Step 4: Build**

```bash
swift build
```

---

## Verify, review, commit

- [ ] **Step 1: Run the tactical and match-specific lanes plus design contracts**

```bash
swift run SimTests --tactical-management
swift run SimTests --tactical-state
swift run SimTests --match-reducer
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift build
```

Expected: the "Floodlit surface conversion" suite reports a higher converted count than Phase 3's 13
(the eight registry-8–15 roots plus `OpponentReportFilmRoomView`'s wrapper resolve through the same
fixpoint with no test changes needed); all tests pass.

- [ ] **Step 2: `detect_changes` against exactly this phase's paths**

```
mcp__gitnexus__detect_changes({scope: "unstaged"})
```

The worktree carries unrelated concurrent work (another session's inbox/read-model changes); review
only the symbols and processes this phase's eight files plus `CoachWorldDeskComponents.swift`
actually touch.

- [ ] **Step 3: Adversarial review of the phase diff**

Same shape as Phase 3: independent dimension reviewers (canon compliance, structural correctness —
including the double-ground check on all eight roots plus the register's `if register == .desk`
guard, accessibility, behaviour preservation against this plan's one documented addition) each
followed by adversarial verification of every finding. Fix everything confirmed real before
proceeding.

- [ ] **Step 4: Full suite**

```bash
swift run SimTests
```

- [ ] **Step 5: Commit**

Stage exactly this phase's files — the nine view/component files plus `ContractTests.swift` plus this
plan doc — and commit as `feat: convert Floodlit command surfaces`. Do not stage the concurrent
session's unrelated in-flight files.

## Adversarial review findings, fixed

Five dimensions (canon, structural correctness, the BROADCAST contract against
`render-recorded-match`, accessibility, behaviour preservation), each independently verified. One
finding was refuted, four confirmed and fixed:

- **Refuted — `AftermathView`'s grade-row panels don't violate the broadcast "no cards/gradients"
  rule.** `coachWorldFloodlitPanel` does add a subtle glass sheen to those rows, but the register
  only ever governed the *stage's own backdrop*, not content styling — exactly the boundary this
  plan's "register decision" section drew before writing any code. The verifier's own reading of
  `render-recorded-match` reached the same conclusion independently.
- **`OpponentFilmView.swift`'s empty/unavailable states silently dropped their titles when the
  `ContentUnavailableView(title, systemImage:, description:)` → `CoachWorldSystemState(.empty(...))`
  swap carried only the description string.** `CoachWorldSystemState.Kind.empty` has one message
  slot, not two — `04` §6.6 requires "a title and a description sentence, so the mark orients and the
  words inform." Rather than reshaping the shared component (which would force edits to three
  already-committed Phase 3 files just to keep them compiling), folded title and description into one
  sentence at each of this phase's three sites — the exact pattern Phase 3's `WorldSearchView`
  already used unremarked ("No organisation matches that search. Try a team, city, region or tier."):
  `InboxView` → "Inbox is clear. No decisions or current-week stories are recorded.";
  `OpponentFilmView` → "Opponent film unavailable. " + the model's dynamic reason;
  `TeamHealthView` → "No health records. No controlled roster is available for this week."
  Checked whether Phase 3's other two call sites (`CareerHubView`, `NewCareerSetupView`) have the
  same gap: they don't — both originated from a plain `Text`, never a `ContentUnavailableView`, so no
  title was ever lost there. This is scoped to what this diff actually did.
- **`OpponentFilmView.swift`'s `cell()` accessibility label was a plain string literal —
  `"(label.capitalized), (value)"` — missing the backslashes for interpolation, so VoiceOver
  announced that literal nonsense text on all four evidence tiles.** Pre-existing (introduced in
  `e3d237f`, before this cutover), but it sits inside a file this phase substantially rewrites, so
  fixed it in place rather than leaving a known-bad label in code just touched. An identical typo
  exists in `DepthChartView.swift:141`, untouched by this phase — flagged separately.
