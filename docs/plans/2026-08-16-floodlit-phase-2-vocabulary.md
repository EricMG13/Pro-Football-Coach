# Floodlit Phase 2 — Reusable Vocabulary

**Scope.** Task 4 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`, minus Step 3
(Match Day extraction — deferred; see Deviations). Task 3's shared foundation (stage, panel depth,
cut-corner geometry, dark-only palette) landed in the prior commit via the pre-existing
`CoachWorldFloodlitStage`/`CoachWorldFloodlitPanelModifier`, so this phase is the component
vocabulary only.

**Why a new file, not `CoachWorldDeskComponents.swift`.** CLAUDE.md: "files small and focused,
split by responsibility." `CoachWorldDeskComponents.swift` already owns stage/panel/cut-corner/
buttons; the vocabulary layer (rings, bars, chips, marks, rows, states) is a distinct
responsibility. New file: `Sources/ProFootballCoachUI/CoachWorldVocabulary.swift`.

**Symbol sourcing.** Every icon is drawn from `04` section 6.6's registered members only — the
existing `runDesignContractTests` symbol-register suite scans any file for `systemName:`/
`systemImage:` by construction, so no new symbol test is needed; using an unregistered symbol here
fails that suite automatically.

## Components

- `CoachWorldRatingRing` — a proportion ring at any diameter (table-cell 26 pt through hero
  118 pt), replacing separate arc-gauge/value-ring/dial types per the plan's own instruction not to
  duplicate one type per specimen.
- `CoachWorldMeter` — a proportion bar, `value`/`range`/`label`.
- `CoachWorldOpposedBar` — two-sided comparison bar, `leading`/`trailing`/`label`.
- `CoachWorldStatusChip` — tracked micro-label chip, tone + required text, optional symbol from the
  12-member Status class (`registry 17`). Icon is never the only channel.
- `CoachWorldDeltaMark` — a signed rating delta, `arrow.up.right`/`arrow.down.right`
  (Change class, `registry 11`) paired with the printed signed number.
- `CoachWorldAgendaRow` — title/timing/cost/state, `checkmark.circle.fill`/`person.badge.clock`
  (Obligation class, `registry 19`).
- `CoachWorldIdentityBand` — retained-identity-only team strip, built from `CoachWorldTeamReference`
  and `CoachWorldTeamIdentity`; renders nothing when identity resolution refuses (no fallback team
  colour is invented).
- `CoachWorldSystemState` — the five states canon requires everywhere a composition can be empty,
  loading, erroring, interrupted or delegated. `internal`, matching every other component in this
  file (all 88+ UI views share one module, so cross-file access needs no `public`).

## Steps

1. Impact-analyse `CoachWorldActionButtonStyle` (adjacent, unedited) is not touched by this phase;
   no HIGH/CRITICAL risk expected since these are net-new types with zero existing callers.
2. TDD: write failing tests in `ContractTests.swift` for `CoachWorldSystemState`'s five kinds and
   for `CoachWorldStatusChip`/`CoachWorldDeltaMark` never being constructible without their required
   text. Confirm red.
3. Implement `CoachWorldVocabulary.swift`.
4. `swift build`, `swift run SimTests --design-contracts`, full suite.
5. Confidence review the new file, `detect_changes`, commit `feat: add Floodlit component
   vocabulary`.

## Deviations from the source plan

- Match Day's internal extraction into `ScoreBug`/`LowerThird`/`CallInCard`/`KeyMomentsRow` (Task 4
  Step 3) is **not done here**. `MatchDayView.swift` is 785 lines of already-correct, already-tested
  read-model wiring; folding a risky internal refactor into "also build 8 new types" is exactly the
  over-scoping CLAUDE.md's scope guard forbids. It belongs with Match Day's own surface-conversion
  pass (Task 6 / this project's Phase 4), where it can be reviewed on its own diff.
- No components are renamed from the existing `CoachWorldFloodlitStage`/`CoachWorldFloodlitPanelModifier`
  naming to the source plan's `CoachWorldStage`/`CoachWorldPanel` — they are functionally identical
  to what Task 3 asked for and already shipped; renaming working code with zero behaviour change is
  an unrequested refactor.
