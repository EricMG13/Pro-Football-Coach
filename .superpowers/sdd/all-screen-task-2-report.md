# All-screen Task 2 report — one-band top navigator

## Status

Implemented the shared one-band top navigator, removed the rail model/rendering seam, kept Match Day and unavailable canonical routes inside the shared navigation model, and updated the focused production UI route. No simulation, persistence, route, callback, or read-model behavior was intentionally changed.

The visible navigator was measured on the 844×390 install floor at `x=63, y=12, width=761, height=34` (189/36/2283/102 pixels at 3×). The family control's accessibility frame is 64.7×44 points; the following sibling target starts eight points after it. The identity, family button, sibling buttons, opponent context, and supplied club/opponent logos remain in source order with one club-logo and one opponent-logo rendering site. `top-navigator` is a semantic container, not a separate labelled VoiceOver stop; its children remain individually reachable.

## Implementation

- Replaced rail/two-row geometry with the 63/12/34/54/761 install-floor contract.
- Removed `RailEntry`, rail provider/sample data, `showsIconRail`, and `FloodlitIconRail` production paths.
- Built a single header row with identity, protected family registry button, scrolling sibling routes, and truncating right context.
- Constrained chromed compositions to the stage's exact `GeometryReader` proposal. This prevents oversized screen content from growing the stage to 397.7 points and centering it at y=−7.7.
- Kept standard layout horizontally full-window while retaining vertical safe-area ownership.
- Added shared chrome to Match Day, kept its pitch full bleed, and moved its score/control furniture below `Stage.contentTop`.
- Wrapped unavailable canonical routes in the requested screen's shared chrome while preserving `Back to HQ` and eligibility behavior.
- Updated the focused HQ→registry→Roster→Player Profile→Roster UI route.
- Updated the stale rail-readable-floor contract to assert horizontal scrolling without label scaling.

Additional necessary production files beyond the brief's primary list were `CoachWorldDeskComponents.swift` (exact proposal constraint), `ScreenReadModels.swift` (remove sample rail construction), and `RedesignedJobBoardProofView.swift` (replace the deleted rail-free token). `ContractTests.swift` was updated because its old rail assertion could no longer compile as a valid contract.

## TDD evidence

RED: `swift run SimTests --design-contracts` failed to compile at `DesignContractTests.swift:162` because `CoachWorldTokens.Stage.headerHeight` did not exist. The interrupted implementer's complete `One-band top navigator` suite was preserved.

GREEN:

- `swift run SimTests --design-contracts` — PASS, 50 tests / 794 checks.
- `swift run SimTests --core-contracts` — PASS, 230 tests / 3169 checks.
- Focused UI route, default size, iPhone 17e install floor — PASS.
- Focused UI route, AX5 (`accessibility-extra-extra-extra-large`) — PASS.
- Focused UI route, iPhone 15 Pro 852-point sanity — PASS.
- Focused UI route, Pro Max 956-point sanity — PASS.

The key diagnostic sequence was:

- Normal family `.tap()` originally failed while a scratch-only center-coordinate tap passed the entire route, proving the action/state/overlay path.
- Removing `.accessibilityElement(children: .contain)` made `top-navigator` undiscoverable and did not make the action fire, disproving container interception.
- Giving the family a temporary identifier was ineffective and was removed.
- The XCTest hierarchy exposed the real root cause: the chromed surface frame was `{{0,-7.7},{844,397.7}}`, placing the family target partly outside the window.
- Constraining the composition to the stage proposal restored y=12 and made the unchanged normal semantic `.tap()` pass.

## Verification commands and results

- `swift run SimTests --design-contracts` — initial sandbox cache denial; rerun with cache access PASS 50/794.
- `swift run SimTests --core-contracts` — PASS 230/3169.
- `./scripts/verify.sh --lane app` in the linked worktree — expected raw failure: `unable to override package 'ProFootballCoach' because its identity 'pro-football-coach' doesn't match override's identity (directory name) 'mock-reconciliation-vertical-slice'`.
- Same app lane from the established canonical-name isolated scratch copy `/private/tmp/pfc-task2-app.WxhXBV/pro-football-coach` — PASS, xcodegen + xcodebuild, 2 passed / 0 failed.
- Focused `xcodebuild ... -only-testing:ProFootballCoachUITests/ProFootballCoachUITests/testCoachingHQRosterPlayerProfileVerticalSlice test` — PASS at default, AX5, 852, and 956 widths.
- `rg` production retirement scan — no `FloodlitIconRail`, `RailEntry`, `showsIconRail`, `railFreeLeading`, or temporary identifier remains.
- `git diff --check` — PASS.

## Rewrite tournament and confidence review

Rewrite tournament winner: incumbent. Proposed removal of the stage `GeometryReader` was rejected because the direct composition had already been measured at y=−7.7 and failed the focused route. Proposed removal of accessibility containment was rejected because it removed the stable hook without fixing activation. Match Day's explicit negative inset cancellation is load-bearing and clearer than hiding it behind a helper.

Confidence review investigated: proposal sizing across 844/852/956; normal and AX5 family activation; visible-versus-hit geometry; family clipping/layout priority; semantic container/child order; logo uniqueness; Match Day full-bleed inset cancellation; unavailable route chrome; and persistence risk from touching `CoachWorldScreenID`. The UI matrix, source scan, app build, and 3169-check core suite found no confirmed defect. Comments referring to the old rail/second row were corrected.

## GitNexus scope

Pre-edit impacts were those recorded in the task brief. One additional shared owner was impacted before edit: `CoachWorldFloodlitStage` was CRITICAL (44 direct / 75 total, zero execution processes, one module); the controller explicitly approved a minimal layout-only edit under the full proof matrix.

Final `detect_changes(scope: all, exact worktree)` reported MEDIUM risk: 52 changed symbols across 13 files, two affected persistence processes (`RestoreExistingCareer → CoachWorldScreenID` and `RecoverFromBackup → CoachWorldScreenID`). No enum case or persistence representation changed; the core/save contracts passed.

## Concerns

- The linked-worktree app lane remains blocked by the repository's known package-identity mismatch; the exact-source canonical-name scratch lane passed.
- The shared stage constraint is high blast-radius by call graph, though limited to chromed layout and covered by default, AX5, 844/852/956 UI routes plus full design/core/app verification.
