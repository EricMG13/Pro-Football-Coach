# All-screen Task 4 report — weekly command screens

## Status

IMPLEMENTATION DONE, TASK NOT COMPLETE. This commit (`feat: reconcile all weekly command screens`)
reconciles canonical IDs 8–15 and 47 against their existing read models and callbacks. It changes
presentation and focused proof only: no read-model field, route, callback, asset, simulation state,
persistence, or engine behavior was added.

Nine production views now present one dominant football task with `.deep` depth and supporting
evidence/actions with `.glass` depth. The shared top navigator, Task 3 typography/team identity,
team-coloured action rules, and one production team/opponent logo per supplied identity remain
intact.

Two things keep the task open. The owner reversed the earlier skip instruction and **Match Day /
ID 14 is required**, as an exact visual reproduction of `Match Day.dc.html` proven on a real
production route; the Match Day evidence caveats recorded below are retained as historical context
and do not close ID 14. And the review-fix pass found two pre-existing red UI tests on Task 4
surfaces; both are now fixed, and a third -- `testTeamLogoAssetAndFallbackProof` -- was found and
is still red. See "Review fix (2026-08-22)" and "Two pre-existing reds fixed (2026-08-22)". The
progress ledger still reads `All-screen Task 4: pending`.

## Contract reconciliation

The nine presentation-contract rows were reconciled before layout work. Source/read-model/callback
seams, not the supplied mock copy, were treated as authoritative.

| ID | Dominant truth | Existing action seam | Recorded omission boundary |
|---:|---|---|---|
| 8 | active mandatory decision and exact evidence/cost | `onCommit`, inspect/delegate/prepare/continue/navigation callbacks | no inferred recommendation, countdown, local receipt/undo, or new film/health/fixture evidence |
| 9 | selected consequential bounded message | open/read/continue/close/navigation callbacks | no reply/composition, recommendation, countdown, receipt, undo, or evidence beyond item fields |
| 10 | two retained opponent tendencies or honest unavailable reason | continue/close/navigation callbacks | no splits, player film, hidden league totals, or new opponent evidence |
| 11 | current/selected three-dimension tactical plan | `onSelect`, `onClose`, navigation | no coverage dial, cost, recommendation, receipt, undo, or new evidence |
| 12 | current/selected complete practice allocation | `onSelect`, `onClose`, navigation | no invented remaining-minutes field, editable sliders, recommendation, receipt, or undo |
| 13 | retained readiness exceptions before neutral healthy remainder | continue/close/navigation callbacks | no diagnosis, return date, treatment, recommendation, receipt, undo, or new health evidence |
| 14 | score/situation, immutable field, 22 actors, two lines, five controls | control/interruption/exit/navigation callbacks | no reconstructed actor, line, commentary, control, forecast, receipt, or interruption evidence |
| 15 | retained final result and plan evidence | continue, optional box-score, navigation | no quarter score, reconstructed stat line, trend, grade delta, recommendation, receipt, or undo |
| 47 | retained final score and ordered aftermath evidence | close/navigation callbacks | no quarter scoring, opposed totals, play-by-play, reconstructed stat line, recommendation, receipt, or undo |

Task 1's row for HQ described the available callback seam but the standard presentation previously
committed as soon as a choice was selected. The approved hierarchy requires an explicit commit.
Both standard and AX5 now use the same existing `onCommit` seam in one select-then-commit flow. The
callback payload and downstream transition are unchanged; this is UI trigger-order normalization,
not a new persisted or simulation state.

## Pre-edit GitNexus impacts

All analyses targeted the exact linked worktree and included tests. The user was warned before the
HIGH/CRITICAL edits and approved the narrow presentation/test changes.

| Symbol | Risk | Direct / total | Processes |
|---|---|---:|---:|
| `CoachingHQView` | LOW | 2 / 7 | 0 |
| `InboxView` | LOW | 1 / 4 | 0 |
| `OpponentFilmView` | LOW | 1 / 3 | 0 |
| `GamePlanView` | LOW | 2 / 5 | 0 |
| `PracticePlanView` | LOW | 1 / 4 | 0 |
| `TeamHealthView` | LOW | 1 / 4 | 0 |
| `MatchDayView` | LOW | 2 / 7 | 0 |
| `AftermathView` | LOW | 1 / 4 | 0 |
| `GameDetailBoxScoreView` | LOW | 1 / 4 | 0 |
| `CoachWorldFloodlitStage` | CRITICAL | 44 / 75 | 0 |
| `CoachWorldFloodlitComposition` | MEDIUM | 1 / 75 | 0 |
| `ProFootballCoachUITests` (test only) | CRITICAL | 74 / 74 | 0 |
| `runDesignContractTests` (test only) | MEDIUM | 1 / 75 | 0 |

The public-view graph carries lower-bound warnings for interface consumers. The compiler, app/UI
tests, and named read-model/state gates were therefore retained as the caller-contract oracle.

## Implementation

- HQ: one mandatory-decision workbench, explicit selected-choice commit, exact cost/evidence,
  remaining obligations and kickoff hierarchy. The same choice is visibly selected before the
  existing intent ID is committed.
- Inbox: one selected-message reading pane, bounded queue/remaining work, supported action and
  chronology. The existing footer moved inline so it cannot hide the final message.
- Film: retained pass-rate/turnover evidence or the exact unavailable reason, followed by retained
  source figures and the existing plan/return actions.
- Game Plan: current/selected plan rendered as exactly three real tactical dials; standard choices
  form a row, AX5 choices form a column, and consequence then explicit commit share an inline glass
  receipt band.
- Practice: current/selected complete allocation is dominant; no remainder is derived. Choices and
  the consequence/commit band use the same adaptive order as Game Plan.
- Health: exceptions are first and routine available players remain neutral. The standard footer
  remains pinned; AX5 places the same footer inline after the healthy remainder so it cannot cover
  the empty state. The callback is unchanged.
- Match Day: field/score remain dominant, all 22 actors, recorded playback/commentary, both field
  landmarks, five controls, interruption/evidence paths and exit are preserved. At AX5 the five
  controls precede interruption/evidence in source and accessibility order.
- Aftermath: retained result first, then grades/plan evidence and existing box-score/continue
  actions.
- Box Score: retained score and evidence groups first, followed by the existing return route.

Necessary directly-proved out-of-list changes:

- `CoachWorldDeskComponents.swift` forwards the actual viewport width and removes the unused,
  declaration-only propagating `floodlit-stage` automation identifier.
- `CoachWorldFloodlitComposition.swift` keeps horizontal safe-area expansion for the exact Task 2
  navigator while bounding the content proposal to the real viewport; it also removes the unused,
  propagating `floodlit-surface` identifier.
- `DesignContractTests.swift` forbids those two identifiers and the unused
  `match-day-standard` ancestor identifier so descendants retain their labels and IDs.

No identifier was relocated and no proof-only element was added.

## TDD and focused proof

RED evidence included:

- the initial nine-screen root/dominant assertions could not find one stable root and one dominant
  element on every route;
- HQ selection did not expose the approved explicit-commit step on the standard path;
- AX ancestor identifiers propagated over child labels/actions;
- Game Plan and Practice choice/receipt/action frames overlapped under AX5 and the initial visible
  selection did not always describe the first fallback payload;
- the first routes 9–13 viewport proof detected content outside the 844-point proposal;
- `health-overlap-red2.xcresult` failed the intended disjoint-frame assertion because Team Health's
  AX5 empty state intersected the pinned footer.

Some first REDs were test-selector defects (for example an exact label matched combined SwiftUI
descendants); those were corrected before treating a failure as product evidence.

GREEN evidence:

- `final-default.xcresult`: 5/6 groups passed. Its sole failure was a stale post-dismiss receipt
  selector; `final-receipt-default.xcresult` reran that corrected group and passed 1/1.
- `final-ax5.xcresult`: 5/5 groups passed: all nine roots/dominant regions, HQ explicit commit,
  Match Day landmarks/control order, viewport bounds, and receipt geometry/selection equivalence.
- `health-overlap-green.xcresult`: 2/2 passed after the narrow AX-only footer fix: focused Health
  disjointness plus the full AX routes 9–13 viewport group.
- Standard/AX receipt proofs require every option, consequence and CTA frame to be disjoint; the
  visibly selected option title equals the option named by the commit control before any further
  selection.
- Match Day exports exactly two distinct labelled landmarks without replacing the existing actor,
  score, field or control identifiers.
- Source contracts forbid `floodlit-stage`, `floodlit-surface`, and `match-day-standard`.

## Simulator, accessibility, and visual evidence

Device: iPhone 17e simulator `7082DFE5-3BFB-4073-859B-83E95B35531B`, native landscape
844 × 390 points. App products came from the exact-source scratch copy at
`/private/tmp/pfc-task4-final.EN1LgJ/pro-football-coach` with DerivedData at
`/private/tmp/pfc-task4-final.EN1LgJ/derived-data`.

Type-size commands:

```sh
xcrun simctl ui 7082DFE5-3BFB-4073-859B-83E95B35531B content_size large
xcrun simctl ui 7082DFE5-3BFB-4073-859B-83E95B35531B content_size accessibility-extra-extra-extra-large
xcrun simctl ui 7082DFE5-3BFB-4073-859B-83E95B35531B content_size large
```

The final read-back was `large`. Numbered routes used
`PROOF_NEW_CAREER=424242` plus `PROOF_SCREEN_NUMBER=<id>`. ID 14 used only the existing immutable
`PROOF_SCREEN=match` read-model fixture; no engine/debug state seam was created.

Framebuffer capture used `xcrun simctl io <device> screenshot <raw.png>`. Each launch was polled
until the framebuffer hash was neither known loading hash
`5f1231f5b82f8b0bd6e9d6774df7c3a26fd09051` (default) nor
`2d3df371231509d6ea5e552d6a5a60ed9e2b9402` (AX5), then required two consecutive identical
hashes. Management routes settled in eight polls and Match Day in six. Device-portrait framebuffers
were rotated orientation-only with `sips -r 270`; no pixels were otherwise altered. All 18 accepted
`screen-{8,9,10,11,12,13,14,15,47}.png` files under
`/private/tmp/pfc-task4-final.EN1LgJ/evidence-clean/{default,ax5}` are exactly 2532 × 1170 pixels.

The first fixed-delay/incorrect-orientation batch was rejected, not counted as evidence. The final
18 were inspected at original pixels for correct route/type size, clipping, overlap, duplicate
logos, extra deep regions, team/action colours, typography and routine semantic colour. No accepted
frame showed a defect. The visible default navigator was also measured from
`nav-measure.png` at x=63, y=12, width=761, height=34 points while management content began at x=63
and stayed at maxX <= 844.

IDs 15 and 47 honestly show their unavailable state on the numbered default/AX5 routes. Their
production result layouts are also compile/source/design-contract verified. ID 14's PNG is the
existing **unchromed immutable debug fixture**; it does not prove the actual in-career top navigator.
Task 2 separately proves the production-route shell. A single retained-game-plus-navigator capture
does not exist and remains an explicit Task 11 evidence gap.

The accessibility-matrix generator reports 62 registered screens and 7,936 full cross-product
cases. Its full automated status remains `not-run` and manual status `manual-required`. Task 4
proves the approved 844 default/AX5 semantic/interaction subset. Physical-device, VoiceOver,
Voice Control, Switch Control, sensor-left/right, Reduce Motion, sound-off and haptic-equivalent
checks remain manual/final-task evidence; none is inferred from screenshots.

## Named gates

- `swift run SimTests --tactical-management`: PASS, 8 tests / 81 checks.
- `swift run SimTests --tactical-state`: PASS, 8 / 31.
- `swift run SimTests --match-reducer`: PASS, 17 / 80.
- `swift run SimTests --screen-read-models`: PASS, 69 / 9,704.
- `swift run SimTests --design-contracts`: PASS, 57 / 852; AX5 62 landed / 0 pending;
  Floodlit 62 converted / 0 pending.
- `swift run SimTests --core-contracts`: PASS, 237 / 3,237.
- `swift build`: PASS.
- `git diff --check`: PASS.

## Product UI audit

Task 4 scope score: **31/40, PASS**, with no P0/P1 and no automatic design-specificity rejection.

| Dimension | Score | Evidence |
|---|---:|---|
| Football fantasy | 4 | team/week/opponent/result/field stakes shape every first viewport |
| Task-specific composition | 4 | workbench, reading pane, evidence dossier, allocator, exception table and field/result layouts are distinct |
| Information hierarchy | 4 | one runtime deep dominant region and no more than two initial support groups |
| World identity and continuity | 4 | Task 2 shell and Task 3 team/logo/action system remain coherent |
| Decision and control | 4 | choice, consequence and explicit commit are distinct and callback-equivalent |
| Accessibility and readability | 3 | 844 default/AX5 semantics and geometry pass; full manual/device matrix remains open |
| Truthfulness | 5 | every fact is retained-model truth or an explicitly bounded external fixture; unsupported states stay unavailable |
| Craft and resilience | 3 | accepted 18-frame set is clean; broader devices/themes/sensors and retained-game shell capture remain open |

The score is a Task 4 scope gate, not a claim that the rubric's later full production evidence matrix
is complete.

## Rewrite tournament

**Winner: Incumbent holds** for `GamePlanView.swift` lines 148–227 (choice/receipt/commit region).

- Explicit standard `HStack` and AX `VStack` branches preserve deterministic source order and avoid
  existential `AnyLayout`/measurement work.
- The selected fallback, visible cue, consequence and exact callback payload remain inspectable in
  one region; the focused default/AX tests prove them equivalent.
- Speed, memory and readability challengers added erasure or helper indirection without reducing
  branches or improving measured behavior.

Final code:

```swift
if dynamicTypeSize.isAccessibilitySize {
    VStack(spacing: CoachWorldTokens.Gap.xs) { /* ordered options */ }
} else {
    HStack(spacing: CoachWorldTokens.Gap.xs) { /* equal-width options */ }
}
// The glass receipt repeats the same AX column / standard row rule,
// then commits selectedOption.plan before onClose().
```

**Winner: Incumbent holds** for `CoachWorldFloodlitComposition.swift` lines 75–109.

- The bounded content width stays beside the load-bearing horizontal safe-area expansion and exact
  navigator offsets, preventing the two invariants from drifting apart.
- Extraction did not change asymptotic/runtime work and added a symbol without removing layout
  complexity.
- Focused runtime bounds plus the x=63/y=12/w=761/h=34 framebuffer measurement verify the existing
  region rather than a speculative rewrite.

Final code:

```swift
content()
    .frame(width: max(
        viewportWidth - CoachWorldTokens.Stage.contentLeading
            - CoachWorldTokens.Frame.gutter,
        .zero
    ), alignment: .topLeading)
    .padding(.leading, CoachWorldTokens.Stage.contentLeading)
    .padding(.trailing, CoachWorldTokens.Frame.gutter)
```

Verification for both incumbents: the exact named gates above, focused default/AX5 UI bundles, full
package build, and caller impacts (`GamePlanView`: LOW, 2 direct / 0 processes;
`CoachWorldFloodlitComposition`: MEDIUM, 1 direct / 0 processes) all passed. No tournament rewrite
was applied.

## Confidence review

Least confident about (ranked):

1. Shared horizontal safe-area expansion could widen content or shift the navigator.
   - investigated -> runtime routes 9–13 stay within the window; framebuffer measurement remains
     x=63/y=12/w=761/h=34.
   - verdict -> fine after the root viewport-bound proposal fix.
   - patch -> shared composition receives actual viewport width and bounds only content.
2. Visible initial selection might not equal the callback payload.
   - investigated -> default and AX5 receipt tests compare selected row title with commit title and
     tap the unchanged action; both pass.
   - verdict -> fine after normalizing the visible fallback selection.
   - patch -> initial selection/fallback use the same first retained option in Game Plan/Practice.
3. AX footer/receipt bands might hide content or reorder actions.
   - investigated -> all option/consequence/CTA frames are pairwise disjoint; Inbox item/footer and
     Team Health empty-state/footer focused assertions pass.
   - verdict -> fine after confirmed layout defects.
   - patch -> inline weekly receipts, inline Inbox footer, AX-only inline Health footer.
4. Ancestor automation IDs might replace VoiceOver child labels/actions.
   - investigated -> source contracts forbid all three unused ancestors; child root/dominant and
     action labels remain queryable at default and AX5.
   - verdict -> fine after confirmed propagation defects.
   - patch -> removed declarations; did not relocate them.
5. Presentation might imply data the models do not own.
   - investigated -> reconciled all nine rows, inspected callbacks, and passed 69 read-model tests /
     9,704 checks plus tactical/state/reducer gates.
   - verdict -> fine.
   - patch -> unsupported figures/capabilities remain explicit omissions or unavailable states.
6. Match Day evidence might accidentally claim an in-career shell or mutate replay state.
   - investigated -> capture uses the existing immutable `PROOF_SCREEN=match` model; diff touches
     panel depth, AX order and landmark semantics only. Actors/playback/engine path are unchanged.
   - verdict -> debug fixture is by-design; combined retained-game+navigator screenshot is open.
   - patch -> none; report labels the evidence boundary.
7. Screenshot readiness/orientation might hide a route mismatch.
   - investigated -> discarded the invalid batch; accepted only non-loading, two-hash-settled
     frames, verified all dimensions and visually inspected all 18.
   - verdict -> fine.
   - patch -> readiness polling plus orientation-only rotation.

Fixed: exact shared content bounds, explicit HQ trigger order, selected-payload equivalence,
weekly receipt geometry, Inbox and Team Health footer overlap, Match Day AX control order, and
propagating ancestor identifiers.

Verified fine: callback payloads, 44-point existing controls, one runtime dominant region,
navigator geometry, Task 3 identity/action/type rules, all 22 Match Day actors and five controls,
read-model truth, final image dimensions/routes, and all named gates.

By-design: ID 14 is an unchromed immutable debug fixture; IDs 15/47 numbered routes show honest
unavailable states; Task 2's AX header retains its approved horizontal context behavior.

Still open: Task 11 retained-game-plus-navigator screenshot and the full manual/device/assistive-
technology matrix described above.

## Final GitNexus scope

Exact-worktree `detect_changes(scope: all)` reported HIGH risk: 90 indexed symbols in the 14
expected source/test/contract files and seven affected `MatchDayView.field` rendering processes.
Context and the exact diff were inspected: the changed field symbol adds landmark semantics/IDs;
panel depths and AX control ordering also change presentation. Field geometry, 22 actors, playback,
progression, callbacks and engine state are unchanged. The tactical/state/reducer/read-model gates
therefore corroborate that no simulation, persistence or state-transition process changed.

`detect_changes(scope: compare, base_ref: main)` was also run as the repository regression view. It
reports CRITICAL branch-wide scope (609 files, 123 processes) because this long-lived all-screen
branch includes Tasks 1–3 and earlier product work relative to `main`; it is not the Task 4 commit
boundary. The exact-worktree `all` result above is the reviewed Task 4 scope.

## Concerns and omissions

No open Task 4 code concern. The explicitly retained gaps are evidence work, not hidden green
claims: full physical-device/assistive-tech matrix, broader appearance/viewport/sensor coverage,
and one real retained-game Match Day capture inside the production navigator. The progress ledger
was not edited.

## Review fix (2026-08-22)

Three Important findings from the fresh Task 4 review are fixed in a follow-up commit. No callback
payload, persisted state, route, or simulation behavior changes.

1. **Game Plan dominant described the wrong plan.** `dialGrid` read `model.currentPlan ??
   selectedOption?.plan`, so after a real commit the dials kept describing the stored plan while a
   different option was selected and its consequence and committing action were on screen. Now
   `selectedOption?.plan ?? model.currentPlan`: the dominant describes what the commit would send,
   and the stored plan is only the fallback for when nothing can be selected.
2. **Practice showed the same mismatch.** The allocator title and the four session bars now follow
   the selected option first (`selectedOption?.title ?? "Current plan"`, `selectedOption?.plan ??
   model.currentPlan`). The `"Option preview"` / `"This week"` warning-tinted title is gone: it
   labelled a state that no longer exists once the allocation always tracks the selection.
3. **HQ put the blocker/receipt inside the dominant decision panel.** `statusMessage` moved out of
   `decisionColumn` to the final support position in both `standardLayout` and `accessibleLayout`,
   after obligations, kickoff, and health/stakeholders.

### Review-fix contracts

- `DesignContractTests`: new "HQ presents blocker or receipt after every weekly support region".
  Both limbs were proven able to fail by mutating production and re-running:
  a `statusMessage` block reintroduced inside `decisionColumn` fails
  `DesignContractTests.swift:168`; moving `supportColumn` after the receipt in `accessibleLayout`
  fails `DesignContractTests.swift:194`. Production was restored byte-for-byte after each check.
- `ContractTests`: the practice clause pinned the literal `"Option preview"`, which finding 2
  deliberately deleted, so `--core-contracts` was red on the working fix. That stale clause is
  removed and replaced by a rule covering both screens: "weekly plan dominants must read the
  selected option before the stored plan", asserting `selectedOption?.plan ?? model.currentPlan` in
  `GamePlanView` and `PracticePlanView`. Proven able to fail by inverting the coalesce in
  `PracticePlanView` (`ContractTests.swift:1113`); production restored.

### Focused UI proof

`testWeeklyPlanDominantEvidenceTracksSelectedCommit{AtDefault,AtAX5}` drives real production routes
for screens 11 and 12: commit a Balanced plan, return to the route through the navigator, select a
different option, and assert the dominant and its evidence describe the selected payload and that
the committing action names it.

The AX5 counterpart was red for the Practice fixture, and the cause was an XCUITest interaction
defect, not production. XCUITest answers `isHittable == true` for a row that is inside the scroll
*content* but below the visible bounds: at AX5 the option rows sit about 120pt below the fold, the
hittability loop therefore broke without scrolling, and the tap was synthesized off-screen and
landed on nothing. Captured at the failure: viewport `{{62, 67}, {720, 292}}`, the row at
`{{62, 481.3}, {720, 44}}`, `isHittable true`. Replacing the loop with a swipe loop then oscillated,
because a swipe moves most of a viewport at once and overshoots a row only 120pt out of frame. The
committed helper `scroll(_:toReveal:)` drags by the measured remainder, clamped to 40% of the
viewport so a drag cannot reach a screen edge and become a system gesture, and holds at the
destination so the drag imparts no momentum. It converges in at most 3 of its 8 attempts on the
worst route, and it tests the visible frame, which is the property the proof actually wants.

Production selection at AX5 was separately confirmed by hand on the simulator before any test
change: tapping "Install and sharpen" selected the row, updated the consequence, and renamed the
committing action to "Set Install and Sharpen".

### Review-fix gates

Run on `7082DFE5-3BFB-4073-859B-83E95B35531B` (iPhone 17e, 844x390), content size set and read back
by `xcrun simctl ui ... content_size` for every run and restored to `large` at the end.

| Gate | Result |
|---|---|
| `swift build` | PASS |
| `swift run SimTests --design-contracts` | PASS, 58 tests / 857 checks |
| `swift run SimTests --core-contracts` | PASS, 238 tests / 3,243 checks |
| `swift run SimTests --tactical-management` | PASS, 8 tests / 81 checks |
| `swift run SimTests --screen-read-models` | PASS, 69 tests / 9,704 checks |
| `git diff --check` | clean |
| `testWeeklyPlanDominantEvidenceTracksSelectedCommitAtDefault` at `large` | PASS, 1 test / 0 failures |
| `testWeeklyPlanDominantEvidenceTracksSelectedCommitAtAX5` at `accessibility-extra-extra-extra-large` | PASS, 1 test / 0 failures |
| AX5 regression batch (dominant-surface, HQ-selects, receipt, viewport, team-health) | PASS, 5 tests / 0 failures |
| Default regression batch (dominant-surface, HQ-selects, receipt, viewport, vertical slice) | 3 of 5 pass; 2 pre-existing failures, see below |

Exact-worktree `detect_changes(scope: all)` after the fix: **low** risk, 16 symbols across the 7
changed files, **0 affected processes** — HQ `standardLayout`/`identityRail`, GamePlan `dialGrid`,
Practice `allocator`/`session`, `runContractTests`, `runDesignContractTests`, and the handoff doc.
No route, callback, persistence, or simulation symbol is in scope. `detect_changes(scope: compare,
base_ref: main)` again reports branch-wide CRITICAL (1,736 symbols, 611 files, 128 processes)
because the branch carries Tasks 1–3 relative to `main`; it is not this commit's boundary.

### Two pre-existing UI failures found, attributed, and NOT fixed here

Running the wider default-size UI batch surfaced two red tests. Both were re-run at the Task 4
implementation commit `83452c1` in a throwaway worktree and **fail there identically**, so neither
is caused by the review fix — but both sit on Task 4 surfaces and were not run when Task 4 was
reported DONE.

1. `testCoachingHQRosterPlayerProfileVerticalSlice` — after "Open all tasks" then "Roster",
   `app.otherElements["roster-screen"]` never appears within 10s, so the following
   `roster-open-dossier` tap has no match. Screen 8 route out of the surface registry.
2. `testWeeklyPlanReceiptDoesNotCoverChoicesAtDefault` — the Practice fixture only. After
   `commit.tap()`, `XCTAssertFalse(commit.exists)` fails: "Set Balanced week" is still present
   ~0.33s later. The Game Plan fixture passes the same assertion. Committing either screen raises
   the same mandatory-decision interruption, so the interruption alone does not explain the
   asymmetry; root cause is not yet established.

These block marking all-screen Task 4 complete. They are recorded here rather than fixed in the
review-fix commit because they are outside its diff and need their own change and review.

## Two pre-existing reds fixed (2026-08-22)

Both failures recorded above are fixed, and the first was a production defect rather than a test
artefact.

### Screen 12 committing action fell off the bottom edge

`testWeeklyPlanReceiptDoesNotCoverChoicesAtDefault` failed on `XCTAssertFalse(commit.exists)` after
committing, and the cause was not the assertion. The Practice Plan committing action sat at
`{{560, 384.7}, {157, 44}}` in an 844x390 window, with the content scroll viewport at
`{{63, 54}, {667, 291}}` and the content 397.7 points tall -- 106.7 points of overflow. The action
was entirely below the visible area, XCUITest synthesized the tap off-screen, nothing was
committed, and the screen never closed. Measured, not inferred: screen 11's commit button cleared
in 1.09s while screen 12's was still present after 10.3s, and the hierarchy at that point still
showed `weekly-command-screen-12` with the navigator's Practice Plan row selected.

`04` section 7 states "The initial viewport contains the dominant object and any decision due now"
and permits vertical scrolling only at AX5, so this is a defect against canon on the target device
at default type.

The fix follows the reference, whose own caption for 6e is "Four days as columns. Freshness is
spent left to right and totalled below": at non-accessibility sizes the four sessions are laid out
as columns instead of stacked rows, which reclaims about 107 points. AX5 keeps the stack, because
four columns cannot hold their labels at accessibility sizes and AX5 is exactly where scrolling is
permitted. The screen now fits with no scrolling at default, confirmed on the simulator.

The column labels deliberately carry no `minimumScaleFactor`. `DisplaySize.actionSmall` is 12 and
`TypeRole.authoredFloor` is 12, so any shrink puts authored text under the floor -- a long focus
name such as "FOCUS - OFFENSIVE LINE" would have rendered near 9 points. They truncate instead, and
the accessibility label still carries the whole name. Note that `optionRow` in this file and
`installRow` in `GamePlanView` both apply a 0.7 scale floor to 13-point `DisplaySize.row`, which
reaches about 9.1 points; that is pre-existing, is not covered by any assertion, and is left for a
separate decision because it is a token question.

### Screen 9 committing action fell off the bottom edge

The same by-construction check caught the Inbox, which nothing had suspected: its committing action
sat at maxY 457 against a 390-point window. Six messages beside a 313-point reading pane are taller
than the 291-point viewport on their own, so no arrangement of a trailing band fits. The band now
sits outside the `ScrollView` in a `VStack`, so the scroll view's own frame shrinks by the band
(measured: 291 to 241) and the action lands at maxY 345.

A first attempt pinned it with `safeAreaInset(edge: .bottom)`, matching the depth chart. That was
rejected: `safeAreaInset` leaves the scroll view's frame intact and only adds content inset, so at
rest the last message sits behind the band -- which is what the existing "content must clear the
footer" assertion exists to prevent. The `VStack` keeps both properties.

### The coverage gap that hid both

`assertWeeklyCommandContentStaysInsideTheViewport` hand-listed the labels it checked and its
`assert(_:staysInside:)` helper compared **minX and maxX only**. Nothing in the suite had ever
checked vertical containment, so a control 39 points below the bottom edge passed every gate. The
check now enumerates committing actions by their `committing-action` identifier -- added to
`FloodlitCommittingAction`, so all fifteen screens that carry one are covered the day they are
added -- and asserts vertical containment at default size, where canon forbids scrolling for it.

### Screen 8 route out of the task index

`testCoachingHQRosterPlayerProfileVerticalSlice` was a test defect, not a product one. The task
index lists every available surface (34 here), so Roster is below the fold when it opens; the test
tapped without scrolling and the tap was synthesized off-screen, so the route never ran. Confirmed
by hand: scrolling the index and tapping Roster opens the roster screen with its dossier action.
The overlay's list is now named `surface-registry` so the proof can address it, and the test scrolls
it into view first using the same helper as the weekly plan proof.

`XCTAssertFalse(commit.exists)` immediately after a tap is also replaced by
`waitForNonExistence`, because the close is animated and screen 11 legitimately takes about a
second.

### Evidence

| Gate | Result |
|---|---|
| `swift build` | PASS |
| `swift run SimTests --design-contracts` | PASS, 58 tests / 857 checks |
| `swift run SimTests --core-contracts` | PASS, 238 tests / 3,243 checks |
| `swift run SimTests --tactical-management` | PASS, 8 tests / 81 checks |
| `swift run SimTests --screen-read-models` | PASS, 69 tests / 9,704 checks |
| Default UI batch (6 tests, `large`) | PASS, 0 failures |
| AX5 UI batch (6 tests, genuine AX5) | PASS, 0 failures |
| Remaining UI tests (7, `large`) | 6 pass; `testTeamLogoAssetAndFallbackProof` fails |

`testTeamLogoAssetAndFallbackProof` fails on `team-logo-fallback-proof` not existing. It was
re-run at `83cf76f` in a throwaway worktree and **fails there identically**, so it is a third
pre-existing red unrelated to this change; it touches the logo proof screen, which none of these
edits reach. It is not fixed here and still blocks Task 4.

Exact-worktree `detect_changes(scope: all)`: medium risk, 16 symbols across 6 files, 2 affected
processes -- both `ProspectRow` flows via `FloodlitCostLine`, which this change does not touch. The
only edit in that file is four lines inside `FloodlitCommittingAction.body`, which shifted
`FloodlitCostLine`'s line range; the attribution is a line-range artefact, not real impact.

## Match Day / ID 14 against reference 1a (2026-08-22)

Owner directive: Match Day is required and `Match Day.dc.html` is its exact visual target. The
reference carries three variants; **1a "Floodlit Deep" is the one marked SELECTED**, and the owner
confirmed 1a. The package ships renders for 1b and 1c only, so 1a's geometry was read from its
markup.

The existing implementation turned out to be an accurate 1a build already: `Paint` and `EndZone`
match 1a's five-yard alpha .26 at 2px, tick .30 at 1.5px on a 7.033px pitch, sideline .40, goal .90
at 3px, hash row 6, number size 23 at rows .20/.80, pylons 5x9 with a 7px glow at .35, end-zone
wordmarks 38/36 at .11/.10 tracking, midfield rings 106/94 at .30/.15, and a 15pt token. The
`Frame` tokens match 1a's `left: 63` and `top: 12`. Four deltas were real.

### 1. All 22 actors were missing during playback

`field` iterated `playback.actors` while a snap was replaying. A recorded snap carries tracks only
for the actors that moved -- the proof fixture carries exactly one, and its own comment says "Every
other actor holds ... a static formation around one moving carrier is representative" -- so the
other twenty-one were drawn nowhere. Measured on the real route: **zero** elements labelled
"Offense, ..." or "Defense, ...", not twenty-one. The animated marks were additionally
`accessibilityHidden(true)`, so during playback VoiceOver had no actors at all.

`playbackMark` now draws one mark per **model actor**, travelling if this snap recorded a track for
it and holding at its recorded spot if not, and every mark is a real accessibility element carrying
the model actor's sentence. The landmark proof now asserts 22 marks, 11 a side, by construction --
it previously asserted the two field lines and the five controls and never counted actors, which is
why this survived.

### 2. Yard numbers were at the pre-repair contrast

1a annotates them "CONTRAST REPAIR: .33 to .66 ink over a 2 pt black drop". The file was built
against the earlier revision and still carried `number = 0.33` / `numberShadow = 0.45`. Now .66 and
.55, which is the reference's own accessibility fix and the single most visible change on the field.

### 3. Offense tokens were gold

1a states the rule on the token layer itself -- "OURS = pale disc, THEIRS = navy disc. **No gold on
the field but the first-down line**" -- and its design note says gold is "spent twice: the
first-down line and the commit". Ours filled with `actionPrimary` gold and inked `goldInk`. They are
now `contentPrimary` (#F6FAFF) with a `lamp` (#FFF2CE) hairline and `glassFlatDeep` (#0B0D14) ink,
matching 1a exactly and using existing tokens, no literals. Twenty-two gold discs had stopped the
one gold line reading as the thing that matters.

### 4. The top-right column overflowed the frame

`ControlDepthSelector`'s three segments each take `maxWidth: .infinity`, and a SwiftUI `frame` does
not clip, so inside its 140pt frame the row laid itself out wider and ran "LEVERAGE" off the
trailing edge of the 844pt frame. The column is now constrained to 1a's plate width of 172.

### Deliberate deviations from 1a, with reasons

- **Bottom inset stays 25, not 1a's `bottom: 16`.** 25 is the landscape home indicator (21) plus
  4pt clearance. The mock has no home indicator; the device does, and `04` section 7 owns safe
  areas at physical edges. Moving furniture to 16 would put the lower third and the committing
  cluster under it.
- **Trailing inset stays `Frame.gutter` 20, not 1a's `right: 16`.** There is no recorded safety
  basis either way for this edge -- `04` section 7 says the 17e insets are "unsourced -- measure
  before relying on either" -- so this is left as an owner question rather than silently moved 4pt.
- **1a differentiates plate grounds at .90 / .88 / .86 alpha** for scorebug / top-right / lower
  third; the implementation uses one 0.88. Sub-perceptual, not chased.
- **1a folds the three top-right cards into one plate with internal seams.** This step adopts its
  width and containment; they remain three cards. Outstanding.

### Evidence

Real production route `PROOF_SCREEN=match` on iPhone 17e, captured before and after each change.
`testMatchDayExportsDistinctFieldLandmarksAtDefault` and
`testUnchromedMatchProofKeepsBroadcastTopInset` pass at `large`; `...AtAX5` passes at genuine
`accessibility-extra-extra-extra-large`; content size restored to `large`. design 58/857, core
238/3243, screen read models 69/9704, `git diff --check` clean.

Exact-worktree `detect_changes(scope: all)`: **high** risk, 16 symbols across 4 files, 8 affected
processes -- all eight are the Match Day `field` rendering flow, which is the expected radius for
changing how the field paints and places actors. No simulation, persistence, or route process is in
scope. Several listed symbols (`Paint.arrowSize`, `pylonWidth`, `legs`, `local`, `position`) are
line-shift artefacts of edits elsewhere in the same files.

### Still outstanding for ID 14

The single top-right plate, the plate-ground alpha ramp, and the two inset questions above. ID 14 is
**not** complete and is not marked so.
