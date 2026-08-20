# Floodlit Phase 3 — Entry Surfaces (registry 1–7)

**Scope.** Task 5 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## The five real presentation roots

Registry 1–7 resolve to five roots and three thin wrappers:

| Registry | Route | Root |
|---|---|---|
| 1 | Title / Continue | `TitleContinueView` |
| 2 | New Career & Coach Identity | `NewCareerSetupView` (via `NewCareerCoachIdentityView` wrapper) |
| 3, 4, 5 | Job Board, Offer, Appointment | `CareerHubView` (via three wrappers, `focus:` only) |
| 6 | Settings & Accessibility | `SettingsAccessibilityView` |
| 7 | World Search | `WorldSearchView` |

**`CareerHubView` is in scope and it is not scope creep.** Registries 3/4/5 are this task's, they are
thin `focus:`-passing wrappers, and they cannot be converted without converting the view they
delegate to. Converting it also lands the presentation for 52–55 (Career Hub, Job Security,
Stakeholders, Promotion Decision), which Task 11 then verifies rather than converts. Recorded here so
the later task's scope shrinking is deliberate rather than a surprise.

## What "converted" means, concretely

`CoachWorldFloodlitStage` already owns the committed dark world: page ground, backdrop, fixed-seed
grain (hidden under Reduce Transparency), `foregroundStyle(contentPrimary)`,
`preferredColorScheme(.dark)`, and the `floodlit-stage` accessibility identifier. So a converted root:

1. wraps its content in `CoachWorldFloodlitStage`;
2. **drops its own ground paint** — a root that both wraps in the stage and keeps
   `.background(palette.page.color.ignoresSafeArea())` paints over the backdrop it just asked for.
   This is the defect the new contract test exists to catch;
3. uses `coachWorldFloodlitPanel` and the `CutCorner` presets rather than `coachWorldDeskSurface`
   and `RoundedRectangle`;
4. uses `CoachWorldSystemState` for its empty/unavailable compositions instead of a bare
   `ContentUnavailableView` or a lone `Text`;
5. preserves every binding, callback, validation rule and accessibility declaration unchanged.

## Steps

1. GitNexus upstream impact on each root before editing; report anything HIGH/CRITICAL.
2. TDD: add a `Floodlit surface conversion` suite that enumerates families by construction
   (the `AccessibilityReflowTests` pattern), reports converted/pending counts rather than asserting
   a number that every later task would have to edit, and asserts the no-double-ground invariant on
   every converted root. Confirm red.
3. Convert the five roots.
4. `swift build`, `--design-contracts`, `--core-contracts`, full suite.
5. Confidence review, `detect_changes`, commit.

## Deviations

- The source plan's Step 2 says "wrap each real presentation root in `CoachWorldStage(register: .desk)`".
  There is no `register:` parameter and no `CoachWorldStage` — Task 3 shipped
  `CoachWorldFloodlitStage`, which does the same job. Using the type that exists rather than renaming
  working code to match a plan written before it landed.
- BROADCAST register is not introduced here. No entry surface is a broadcast surface, and inventing
  a register enum with one case and no second consumer would be the speculative abstraction
  `CLAUDE.md` forbids. It belongs with Match Day (Task 6), which is its first real consumer.

## What the conversion changed beyond paint

Three of these are behaviour, not presentation, and are called out so a reviewer does not read them
as drive-by edits:

- **`CoachWorldActionRole.destructive` added**, drawn as an outline in `actionDestructive` rather
  than a fill. `TitleContinueView`'s recovery branch previously offered "New career" in the same
  visual weight as "Try again", so the irreversible option and the lossless one were indistinguishable.
  It is now demoted to the destructive role, relabelled "Delete and start over", and carries its
  consequence sentence *above* the control rather than after the tap.
- **`NewCareerSetupView` no longer prefills `firstName`/`lastName`** with "Alex"/"Coach". A prefill
  let a fast tap-through ship a career under a name the app chose; `canSubmit` already requires both
  fields, so the requirement is now stated rather than silently satisfied.
- **Empty compositions became `CoachWorldSystemState`** in `CareerHubView` (job history,
  opportunities), `NewCareerSetupView` (no generated jobs) and `WorldSearchView` (no match), which
  replaces a bare `Text`/`ContentUnavailableView` with the typed empty state and its registered symbol.

## The test models delegation, not file text

The first run of the new suite failed on registry 2. That was a defect in the test: registry 2's
family file is `NewCareerCoachIdentityView`, a wrapper that delegates wholly to the converted
`NewCareerSetupView`, so it contains no `CoachWorldFloodlitStage` of its own and never will. A
wrapper has no ground to paint, so it is converted exactly when its delegate is.
`floodlitConvertedTypes()` therefore resolves delegation to a **fixpoint** rather than one hop,
because wrappers chain. Verified against the source that the 13 it reports are 5 directly-converted
family roots, the 7 `CareerHubView` wrappers, and `NewCareerCoachIdentityView` — no false positives.

## Adversarial review findings, fixed

A four-dimension review (canon compliance, structural correctness, accessibility, behaviour
preservation) with independent adversarial verification of every finding confirmed 5 issues, all
now fixed:

- **Untokenized border-opacity literal.** `coachWorldFloodlitPanel(border:)` calls in
  `CareerHubView`, `WorldSearchView` and `NewCareerSetupView` passed
  `palette.contentQuiet.color.opacity(0.38)` — a bare literal `CLAUDE.md` names as a defect, and
  the same literal already existed unnamed across 9 other files repo-wide. Added
  `CoachWorldTokens.Depth.panelBorderOpacity` alongside the existing `glassPanelOpacity`/
  `deepPanelOpacity` and applied it at the three call sites this phase touches. The other files
  carrying the same untokenized literal are out of this phase's scope and are flagged separately.
- **Two undocumented button relabels.** The conversion silently changed `TitleContinueView`'s
  recovery labels from "Retry restore"/"Use backup" to "Try again"/"Use the backup save" — copy
  with no source in canon or the design references, riding along with the one documented rename
  (destructive "New career" → "Delete and start over"). Reverted to the original copy; the phase is
  presentation-only apart from the three changes already listed above.
- **Missing accessibilityHint on the destructive control.** The consequence sentence ("Starting
  over deletes this career...") sat in a sibling `Text` the VoiceOver Buttons rotor skips past.
  Added the same sentence as `.accessibilityHint` on the "Delete and start over" button itself,
  matching the pattern `CareerHubView`'s "Resign from appointment" already uses.

Rebuilt green after each fix; full verification lanes re-run below.
