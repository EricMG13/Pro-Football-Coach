# Claude handoff — all-screen UI migration

Updated: 2026-08-22
Repository: `/Users/ericguei/Documents/Pro-Football-Coach`
Active worktree: `/Users/ericguei/Documents/Pro-Football-Coach/.worktrees/mock-reconciliation-vertical-slice`
Branch: `codex/mock-reconciliation-vertical-slice`
Committed HEAD when written: `83452c15cfa6698cc3f5ab888f96820c958e8eb4`

## Status update — 2026-08-23

Nineteen commits have landed since this document was written. Read this before acting on the resume
sequence below, which is done.

Everything an agent can close is closed and evidenced. Two gates remain, and **neither can be closed
by an agent**; they are the only outstanding work.

### The two remaining gates

1. **Manual device and assistive-technology matrix.** `CLAUDE.md`: *"Simulator demonstration is an
   owner action -- hand off a written walkthrough script, never claim it happened."* Script:
   `docs/proofs/2026-08-23-all-screen-owner-walkthrough.md`. One row is automated away (the 44-point
   touch floor, which found three defects), and two rows are pre-answered so the device pass
   confirms rather than discovers. `xcrun simctl ui` exposes only appearance, content size and
   increase_contrast, so VoiceOver speech, Voice Control, Switch Control, Reduce Motion, Reduce
   Transparency, haptics and thumb reach are unreachable from software.
2. **A fresh independent review by a person.** An independent *agent* review was run and returned
   BLOCK; its confirmed findings are fixed in `e4ef671` and recorded in the Task 4 report with the
   three findings that were overturned. That is a cold read by something that did not write the
   code, but it is not the human sign-off the process asks for.

Until both carry real results, `.superpowers/sdd/progress.md` stays `All-screen Task 4: pending`.
Tasks 5 to 12 of the plan have not been started.

### What landed

Task 4 review fixes; every committing action inside the initial viewport; Match Day reconciled to
reference 1a including all 22 actors, the single top-right plate and the yard-number contrast
repair; the real retained-game Match Day capture inside the production navigator, which found a
receipt drawn across the scorebug; the logo proof reds; the 44-point touch floor as a gate; four
unasserted read-model validators; the possession-derivation contract; and the independent review's
confirmed findings.

Defects found and fixed along the way that no existing gate would have caught: two controls at
27x14 and 17 points against a 44-point floor, a 60 Hz per-frame actor scan and per-frame label
interpolation, a VoiceOver label rewriting itself sixty times a second, and an AX5 test family that
could report green at the wrong size.

Known, measured, and deliberately left for the owner because each needs a canon decision rather
than a patch: Increase Contrast is unimplemented (`colorSchemeContrast` is read nowhere); HQ's
committing action measures maxY 407.7 in a 390-point window when a decision panel is open; HQ
carries two committing actions against `04` section 6.5; and the bottom and trailing safe-area
insets where reference 1a and the device disagree.

Full detail, including what the independent review got wrong, is in
`.superpowers/sdd/all-screen-task-4-report.md`.

## Mandatory repository workflow

The current `AGENTS.md` replaces older copies. In particular:

1. Before editing any symbol, run exact-worktree GitNexus upstream impact and report direct callers,
   affected processes/modules, and risk. Warn before HIGH/CRITICAL edits.
2. Before every commit, run GitNexus `detect_changes(scope: all)` on the exact worktree and inspect
   affected processes. Also use compare-main for final regression review.
3. After non-trivial code changes, run no-argument post-edit `rewrite-tournament` on changed
   functions.
4. Before declaring a code task done or committing it, run `confidence-review`, investigate each
   uncertainty to root cause, and patch confirmed defects.
5. Stage exact paths only. Never use `git add -A`, `git add .`, `git commit -a`, reset, checkout,
   clean, or broad deletion.

Use the exact GitNexus repository path, not the similarly named main checkout:

```text
/Users/ericguei/Documents/Pro-Football-Coach/.worktrees/mock-reconciliation-vertical-slice
```

## Completed and reviewed

| Task | State | Commits / evidence |
|---|---|---|
| 1 — presentation contract | complete, review clean | `2bd605e..b544af5`; 47 canonical roots/callbacks/read models checked |
| 2 — one-band navigator | complete, approved | `b544af5..1cb18e9`; default/AX5/844/852/956 and exact x63/y12/w761/h34 geometry |
| 3 — type/material/team actions | complete, review clean | `1cb18e9..6ed8433`; all 166 team colours pass rest and pressed contrast |
| 4 — This Week family | implementation committed, review fixes in progress | implementation `83452c1`; three Important review findings have uncommitted fixes |

The durable ledger is `.superpowers/sdd/progress.md`. It still says Task 4 pending and must not be
updated until the Task 4 fix receives a clean re-review.

## Current worktree — preserve exactly

The worktree is intentionally dirty. Do not discard these five files:

```text
 M Sources/ProFootballCoachUI/CoachingHQView.swift
 M Sources/ProFootballCoachUI/GamePlanView.swift
 M Sources/ProFootballCoachUI/PracticePlanView.swift
 M Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift
 M Tests/SimTests/Suites/DesignContractTests.swift
```

`git diff --check` currently passes. The uncommitted diff is about 184 insertions / 17 deletions.

### What the uncommitted Task 4 fix does

The fresh reviewer requested three Important corrections:

1. Game Plan dominant dials described `model.currentPlan` after the user selected a different
   option whose consequence/CTA would be committed.
2. Practice showed the same mismatch between displayed allocation and selected commit payload.
3. HQ placed `statusMessage` (the blocker/receipt seam) inside the dominant decision panel instead
   of after obligations, kickoff, health, and stakeholders.

The working diff now:

- changes Game Plan to `selectedOption?.plan ?? model.currentPlan`;
- changes Practice title/allocation to the selected option first, then current-plan fallback;
- moves HQ `statusMessage` to the final support position in standard and AX layouts;
- adds a design source/order contract for the HQ receipt;
- adds focused real-route UI coverage for selected dominant evidence and the commit target.

No callback payload, persisted state, route, or simulation behavior changes.

### Review-fix evidence already captured

- Clean RED for Game Plan after a real Balanced commit: selected Pressure option still displayed
  `Tempo, Balanced` instead of `Tempo, Grind it`, `Aggression, Aggressive`, and
  `Balance, Run heavy`.
- Clean RED for Practice after a real Balanced commit: selected Install option still displayed the
  old allocation rather than 30/10/5/15 minutes.
- HQ design RED was exactly three ordering failures.
- Production fix applied.
- `swift run SimTests --design-contracts`: PASS, 58 tests / 857 checks.
- Focused default UI review-fix route: PASS, 1 test / 0 failures, including HQ receipt screenshots
  and both selected non-current dominant states.
- AX5 Game Plan semantic portion passed.

### Exact interruption point

The final AX5 focused test was being repaired for XCTest viewport mechanics only:

- Practice option is around y=481 and commit around y=708 in a 390pt viewport, so the body must be
  scrolled.
- The app has two scroll views: horizontal `top-navigator` and body at roughly
  x62/y67/w720/h292. The test now selects the non-navigator body.
- After scrolling down to the commit, SwiftUI culls the above-fold dominant element. The test was
  reordered to select → scroll up/assert and screenshot dominant evidence → scroll down/assert and
  screenshot hittable commit → tap.
- That reordered genuine AX5 run had started but was interrupted before a final result.
- The simulator content-size state is unknown because sandboxed `simctl` read-back failed after the
  interruption. First restore/read `large`, then set genuine AX5 for the focused counterpart, and
  restore/read `large` in a cleanup path even on failure.

Do not change production layout to solve this; it is a viewport-safe test interaction issue.

## Immediate resume sequence

1. Read the complete current files above and `git diff`; do not redo or discard the working fix.
2. Confirm no stale xcodebuild/test process remains.
3. On iPhone 17e simulator `7082DFE5-3BFB-4073-859B-83E95B35531B`, restore and read back:

   ```sh
   xcrun simctl ui 7082DFE5-3BFB-4073-859B-83E95B35531B content_size large
   ```

4. Re-run the focused default test if needed:
   `testWeeklyPlanDominantEvidenceTracksSelectedCommitAtDefault`.
5. Set real AX5 using `content_size accessibility-extra-extra-extra-large`, run
   `testWeeklyPlanDominantEvidenceTracksSelectedCommitAtAX5`, then restore/read `large`.
6. If AX5 still fails, inspect hittability/frame/culling before changing production. The intended
   proof order is already in the uncommitted test.
7. Update `docs/reviews/2026-08-22-all-screen-presentation-contract.md` and
   `.superpowers/sdd/all-screen-task-4-report.md`:
   - record the three review fixes and final evidence;
   - record the latest user directive that Match Day/ID 14 is required and must exactly reproduce
     `Match Day.dc.html` visually;
   - retain the existing Task 4 Match Day implementation/evidence caveats as historical context,
     but do not mark ID 14 omitted or complete until the exact-reference production proof passes.
8. Re-run proportionate gates at minimum:

   ```sh
   swift run SimTests --design-contracts
   swift run SimTests --core-contracts
   swift run SimTests --tactical-management
   swift run SimTests --screen-read-models
   swift build
   git diff --check
   ```

9. Run `rewrite-tournament` on the changed production functions and `confidence-review`.
10. Run exact-worktree GitNexus `detect_changes(scope: all)` and inspect every affected process.
11. Stage only the five current files plus the exact updated contract/report paths. Commit a focused
    Task 4 review-fix commit.
12. Generate a full review package from Task 4 base `6ed8433` to the new HEAD and re-review all prior
    Task 4 findings. Only after Approved: update `.superpowers/sdd/progress.md` to mark Task 4
    complete.

## Task 4 committed implementation evidence

Implementation commit: `83452c1` (`feat: reconcile all weekly command screens`).

Report: `.superpowers/sdd/all-screen-task-4-report.md`.

Named gates before the latest review fix all passed:

- tactical management 8 tests / 81 checks;
- tactical state 8 / 31;
- match reducer 17 / 80;
- screen read models 69 / 9,704;
- design 57 / 852;
- core 237 / 3,237;
- `swift build` PASS.

The report documents exact 844 geometry, content bounds, receipts/footer fixes, identifier
propagation fixes, 18 settled framebuffer captures, and the previously accepted evidence caveats.
Those Match Day caveats are not final acceptance: the latest owner directive requires an
exact-reference Match Day implementation and production proof.

Temporary Task 4 evidence is under `/private/tmp/pfc-task4-final.EN1LgJ/`. Treat `/private/tmp` as
ephemeral; the report is the durable description.

## Remaining plan after Task 4

Continue sequentially with a fresh implementer and fresh reviewer per task:

5. complete Personnel family;
6. complete Recruiting family;
7. complete Pro Management family;
8. complete League family;
9. complete Career and Entry families;
10. make the corrected system canonical in project documentation;
11. run the all-canonical visual/accessibility proof matrix, including Match Day/ID 14 as an exact
    visual copy of `Match Day.dc.html`, with current-model facts/controls/logos and real production
    route evidence;
12. final adversarial review and shipping gates.

Do not ask whether to continue after each task. The user requested completion of all tasks. Pause
only for a genuine authorization/blocker or a new HIGH/CRITICAL warning that must be surfaced.

## Reference files

- Plan: `docs/superpowers/plans/2026-08-22-all-screen-shell-and-hierarchy.md`
- Approved amendment:
  `docs/superpowers/specs/2026-08-22-mock-reconciliation-shell-and-hierarchy-amendment.md`
- Presentation/omission contract:
  `docs/reviews/2026-08-22-all-screen-presentation-contract.md`
- Task 2 report: `.superpowers/sdd/all-screen-task-2-report.md`
- Task 3 report: `.superpowers/sdd/all-screen-task-3-report.md`
- Task 4 report: `.superpowers/sdd/all-screen-task-4-report.md`
- Task 4 brief: `.superpowers/sdd/all-screen-task-4-brief.md`
- Task 4 review package at committed implementation:
  `.superpowers/sdd/review-6ed8433..83452c1.diff`
- Owner references, read-only: `/Users/ericguei/Downloads/UI surfaces refinement/`

## Safety reminders

- Preserve the five-file uncommitted review fix.
- Do not reintroduce a left/bottom rail or parallel design system.
- Do not manufacture reference-only facts, recommendations, deadlines, receipts, filters, actions,
  logos, colours, or state.
- Do not add or duplicate logo assets.
- Do not infer green/manual evidence that was not run.
- Match Day is required. Treat `Match Day.dc.html` as its exact visual target while preserving
  current immutable model truth, existing callbacks, 22 actors, five controls, and real logos.
