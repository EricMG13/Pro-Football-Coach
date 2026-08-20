# 62-Screen Information Architecture and Action-Truth Redesign

**Status:** implemented in the shared worktree; automated gates are green (918 tests, 770,067 checks; 43 design-contract tests, 663 checks). Representative 844 × 390 and AX5 captures are complete. Human VoiceOver/full 62-screen visual evidence and production offer-acceptance parity remain the release gate.

## Objective

Replace the current 62-name navigation catalogue with a task-first product structure in which every visible destination performs the task it names, every committing action states its consequence before activation, and every legacy saved route restores to a truthful canonical task.

The redesign preserves Floodlit and the proven Coaching HQ, Roster, Recruiting Board, Match Day, and evidence-led detail compositions. It does not preserve a destination merely because it has a `CoachWorldScreenID` case.

## Source of truth

- Audit scope and constraints: `DESIGN-IS-2026-08-19/00-scope.md`.
- Evidence and screen-by-screen critique: `DESIGN-IS-2026-08-19/01-evidence.md`.
- Audit verdict: `DESIGN-IS-2026-08-19/03-verdict.md`.
- Product navigation and action rules: `docs/04-UX-AND-DESIGN-SYSTEM.md:70-84`, `156-160`, and `513-580`.
- Current route inventory: `Sources/ProFootballCoachUI/ScreenRegistry.swift:34-176`.
- Production route boundary: `Sources/CoachWorldApp/CoachWorldAppRootView.swift`.
- Presentation-route persistence: `Sources/CoachWorldApp/CoachWorldSaveDocument.swift:7-67`.
- Existing verification selectors: `Tests/SimTests/main.swift:54-56`, `132-146`.

## Preserve

- `CoachWorldTokens.dark`, Floodlit spacing/type/motion tokens, cut-corner geometry, and the one-gold-commit rule.
- `CoachWorldFloodlitStage`, identity chrome, generated team identity, and progressive disclosure.
- Read-model-only SwiftUI surfaces. UI code must not reach into `GameState`.
- Stable subject IDs, origin-aware return routes, truthful empty/refusal states, and native semantic controls.
- The current DEBUG Job Board proof until its interaction contract is integrated into production and verified.

## Discard

- Title-only wrappers that relabel a generic host while showing the same content.
- Visible routes whose current read model cannot perform the named task.
- Generic gold `Continue` or `Done` actions.
- Row taps that mutate career state before an explicit commit control.
- Parallel old/new production designs or an indefinite feature flag.

## New task architecture

The player moves through six workspaces. Detail routes are contextual children and return to the object that opened them.

| Workspace | Canonical tasks | Contextual children |
|---|---|---|
| Career entry | Start or restore a career; choose and accept an opportunity | Coach identity, offer evidence, appointment receipt |
| This week | Resolve the next obligation and prepare for the next event | Inbox item, film, game plan, practice, health, match, aftermath |
| Team | Set personnel and develop people | Roster, depth/packages, player, development, staff profiles |
| Acquisition / front office | Improve the roster using the current tier and phase | College recruiting/signing/retention or pro cap/contracts/draft/free agency |
| League intelligence | Understand teams, schedule, competition, and current stories | Map/search, team profile, standings, schedule, postseason, statistics, awards, news |
| Career and legacy | Understand the coach's current standing and accumulated story | Stakeholders, promotion, records, rivalries, career line, coaching tree |

Rules:

1. The first destination after restore is the persisted canonical task, or Coaching HQ if the old route is no longer valid.
2. A contextual child stores its origin and returns there. It never guesses a tab root.
3. Acquisition navigation is tier- and phase-aware; college-only and pro-only tasks are never simultaneously advertised.
4. “All Surfaces” becomes “All Tasks” and lists only canonical tasks valid in the current read models.
5. Legacy route numbers remain decode inputs during migration, not visible proof that 62 distinct tasks still exist.

## Legacy route disposition

| Existing destinations | Cutover disposition |
|---|---|
| Job Board, Offer, Coaching Carousel | One Opportunities workspace with list, selected evidence, explicit acceptance, and receipt |
| Staff Market & Profile | Alias to Staff Room/Profiles until a candidate-pool read model and hiring intent exist |
| Scheme Book | Alias to Game Plan until a persistent scheme-library task exists |
| Personnel Packages | Focused mode of Depth Chart; only distinct if packages can be selected and committed independently |
| Portal Hub, Portal Market, NIL Allocation | Alias to College Offseason or hide; aggregate portal/NIL totals do not support candidate or recipient tasks |
| Pro Scouting Board, Draft Board, Draft Room, Free Agency | Focused modes of one Pro Front Office workspace using the read model's separate collections and phase |
| Job Security, Coaching Carousel | Hide or alias to Career Hub until board-target/risk and league-movement evidence exist |
| Rankings and Bracket | Focused modes of Competition Overview, each with a distinct dominant object |
| Record Book, Rivalries, Career Line, Coaching Tree | Focused modes of Legacy History with origin-preserving return behavior |

## Allowed implementation APIs

- SwiftUI `Button`, `alert`, `confirmationDialog`, `@AccessibilityFocusState`, `ScrollView`, and existing Dynamic Type environment checks.
- Existing Floodlit components and styles. Gold remains exclusive to explicit simulation commits.
- Existing `CareerHubReadModel.OpportunityRow` fields for opportunities; do not add salary, contract, buyout, or application claims without domain support.
- Existing `CollegeOffseasonReadModel` aggregate fields; they are insufficient for a portal candidate market or recipient-level NIL allocation.
- Existing `ProOffseasonReadModel` separated prospect/free-agent/waiver collections for focused front-office modes.
- Existing `Contract.deadMoney(ifReleasedAtSeason:)` for exact release disclosure.
- Existing presentation `route`, `returnRoute`, and `selectedSubjectID` fields for migration and contextual restoration.
- Existing SimTests harness and DEBUG proof router. Do not add a test framework or runtime dependency.

## Phase 0 — Re-baseline and classify the dirty tree

### Implement

1. Snapshot `git status`, the path-scoped diff, and the current `main` comparison without modifying unrelated owner work.
2. Classify every current UI change as:
   - carry forward because it directly satisfies this plan;
   - proof-only and retained until its production phase;
   - unrelated owner work and untouched;
   - superseded draft requiring a later scoped replacement.
3. Preserve the already-green draft fixes only after focused verification: truthful Signing Day gating, selected Player Profile routing, human-readable competition stages, one-based News seasons, and non-invented Game/Practice headings.
4. Record the baseline test counts. The no-argument selector is broad; use named selectors for phase gates and run the full lane only at cutover.

### References

- `AGENTS.md` GitNexus requirements.
- `Tests/SimTests/main.swift:54-56`, `132-146`.
- `DESIGN-IS-2026-08-19/01-evidence.md` screen inventory.

### Verify

- `git diff --check`
- `swift build`
- `swift run SimTests --design-contracts`
- `swift run SimTests --screen-read-models`
- `swift run SimTests --reduce-motion`
- GitNexus `detect_changes(scope: "compare", base_ref: "main")`, with unrelated dirty paths called out separately.

### Guard

- Do not clean, reset, or rewrite unrelated dirty files.
- Do not treat a source-scan contract as runtime proof.

## Phase 1 — Repair action truth before changing navigation

### Implement

1. Make Game Plan, Practice Plan, and Depth Chart rows selection-only. Their footer buttons commit exactly once and name the selected option.
2. Bind Film Room’s “Into the game plan” to navigation, not `advanceWeek()`.
3. Replace week-advancing `Continue` labels with `Advance week` or the exact next event. Keep them disabled with the existing refusal reason when obligations remain.
4. Replace gold dismissal `Done` controls with neutral `Close` or origin-specific labels.
5. Route “Back to the league” actions to League Map, or relabel them `Back to HQ` if that is the intended destination.
6. Disclose release dead money in the row and native confirmation action: `Release <player> · $X dead money`.
7. Rename the current all-board “Shortlist” route to a truthful board overview until membership state exists.
8. Change Settings to truthful accessibility notes; do not claim unverified universal support.
9. Every successful commit renders a receipt and moves accessibility focus to it. Cancellation changes nothing.

### References

- `Sources/ProFootballCoachUI/GamePlanView.swift:140-171`
- `Sources/ProFootballCoachUI/PracticePlanView.swift:142-173`
- `Sources/ProFootballCoachUI/DepthChartView.swift:268-300`
- `Sources/ProFootballCoachUI/OpponentFilmView.swift:195-210`
- `Sources/ProFootballCoachUI/ProManagementView.swift:205-235`
- `Sources/FootballSimCore/Model/Contract.swift:121`
- `Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:24-43`

### Verify

- Row selection leaves the store and save document unchanged.
- Footer commit mutates exactly once and produces the named receipt.
- Release cancel changes no roster, contract, dead-money, event, or save state; confirm applies the displayed amount once.
- Film-to-plan preserves calendar/week and returns to Film Room.
- Source contracts reject generic gold `Done`, generic week-advance `Continue`, and row callbacks that invoke commits.

### Guard

- Do not change engine intent semantics to match misleading copy.
- Do not calculate financial consequences in the view when the provider can expose the authoritative value.

## Phase 2 — Establish canonical task routing and migration

### Implement

1. Add one canonical-route mapping beside `CoachWorldScreenID`; avoid a second navigation registry.
2. Mark each legacy ID as canonical, alias, or unavailable with a player-facing reason.
3. Filter shared chrome and All Tasks by canonicality plus current read-model availability.
4. On restore, map persisted legacy route strings to canonical tasks in the existing `screenID(for:)` boundary. Preserve `selectedSubjectID` and valid return origins.
5. Add a migration table test covering all 62 legacy IDs, including unavailable fallbacks.
6. Replace the “62 distinct screens” contract with two contracts: every visible task is distinct and actionable; every legacy ID migrates deterministically.

### References

- `Sources/ProFootballCoachUI/ScreenRegistry.swift:34-176`
- `Sources/CoachWorldApp/CoachWorldAppRootView.swift`
- `Sources/CoachWorldApp/CoachWorldSaveDocument.swift:7-67`
- `Tests/SimTests/Suites/SaveDocumentTests.swift:85-103`

### Verify

- Every legacy route restores to the expected canonical task or HQ fallback.
- No visible sibling link opens a title-only host or unavailable read model.
- Back/close restores the originating football object after save/reload.

### Guard

- No second production router and no permanent feature flag.
- Do not change save schema solely to rename a presentation route; use tolerant mapping at the boundary.

## Phase 3 — Ship the Opportunities workspace

### Implement

1. Promote the reviewed DEBUG proof’s list/detail/confirmation/receipt interaction into production using `CareerHubReadModel`.
2. Job Board and Offer become entry/focus modes of the same workspace; they do not delegate to completed-job history.
3. Rows select locally. Acceptance is the only gold action and names the team plus current-job consequence.
4. Unavailable offers remain visible with their reason; no fabricated salary, buyout, or contract detail.
5. Acceptance invokes the existing production callback exactly once, displays the authoritative receipt, and returns or empties the list according to the rebuilt read model.
6. After parity is proven, delete the DEBUG-only duplicate proof and its special launch selector.

### References

- `Sources/ProFootballCoachUI/RedesignedJobBoardProofView.swift`
- `Sources/ProFootballCoachUI/CareerHubView.swift:185-250`
- `Sources/ProFootballCoachUI/ScreenReadModels.swift:549-595`
- `Sources/ProFootballCoachUI/JobBoardView.swift`
- `Sources/ProFootballCoachUI/OfferView.swift`

### Verify

- Selection and cancel do not mutate career state.
- Acceptance names the selected offer and consequence, mutates once, focuses the receipt, and survives save/reload.
- 844 × 390 uses list/detail; AX5 uses one ordered scroll column.
- VoiceOver order is offers, selected evidence, consequence, commit.

### Guard

- Do not keep proof and production implementations in parallel after cutover.
- Do not expose fields absent from `CareerHubReadModel`.

## Phase 4 — Consolidate Team and tactical work

### Implement

1. Preserve exact roster selection into Player Profile and clear route-local selection on exit.
2. Keep Scheme Book as an alias to Game Plan until a persistent scheme-library model exists.
3. Give Personnel Packages a focused Depth Chart mode only if package options can be selected and committed independently; otherwise keep it an alias.
4. Rename Staff Market & Profile to Staff Profiles/Staff Room and remove market navigation until candidate and hiring intent data exist.
5. Keep all detail returns origin-aware.

### Verify

- Selected player remains selected through profile/development and direct registry entry has a deterministic fallback.
- Alias routes never imply unsupported libraries or markets.
- Tactical commits pass Phase 1’s exactly-once checks from both weekly and Match Day origins.

### Guard

- Do not add candidate fixtures or fake scheme history to preserve a route name.

## Phase 5 — Consolidate college acquisition

### Implement

1. Keep Recruiting Board, Prospect, Visits, Class, Retention, and active Signing Day when their read models support the named task.
2. Alias Portal Hub/Market and NIL Allocation to College Offseason, or hide them with a reason, while only aggregate data exists.
3. Show phase and aggregate portal/NIL evidence in the offseason overview without presenting it as a candidate market or recipient allocation tool.
4. Keep Signing Day visible only when `collegeOffseason.cyclePhase == .signing`.

### Verify

- No college route advertises candidates, recipient allocations, or membership state absent from the model.
- Phase transitions update visible tasks without leaving a stale route.
- Signing Day closes truthfully when the phase changes.

### Guard

- No inferred prospects, NIL recipients, or fake shortlist membership.

## Phase 6 — Focus the Pro Front Office

### Implement

1. Use one Pro Front Office workspace with focused sections for cap/contracts, cuts, scouting, draft, and free agency.
2. Filter each focus to the existing separated collection in `ProOffseasonReadModel`; stop rendering all sections under every title.
3. Gate Draft Room by phase and suppress unrelated global navigation during timed/ceremony states.
4. Apply Phase 1’s cost disclosure, confirmation, and receipt rules to releases and other irreversible transactions.

### References

- `Sources/ProFootballCoachUI/ProOffseasonReadModels.swift:113-170`
- `Sources/ProFootballCoachUI/ProOffseasonView.swift:120-180`
- `Sources/ProFootballCoachUI/ProManagementView.swift`

### Verify

- Each focus contains only its named collection and actions.
- Invalid phases provide a reason and a valid return path.
- Transactions are atomic and reconcile cap, roster, events, receipt, and save.

### Guard

- Do not duplicate the host into four nearly identical views.

## Phase 7 — Finish League and Career truth

### Implement

1. Keep League Map’s dominant region protected from collapsing chrome; provide list/search parity for every selectable team.
2. Use human-readable competition stages and one-based seasons on every league/history surface.
3. Make League detail returns origin-aware and remove duplicate local League navigation when shared chrome owns it.
4. Keep Stakeholders, Promotion, and legacy history focuses that have real evidence.
5. Hide/alias Job Security and Coaching Carousel until board-target/risk and league-wide movement evidence exist.
6. Demote read-only dismissal from gold throughout Career and League.

### Verify

- Every map object is reachable without precise marker tapping.
- Labels agree across schedule, bracket, team profile, news, and history.
- Career focus panels never fall through to unrelated completed-job history.

### Guard

- Do not invent board confidence, targets, or carousel movement from stakeholder support or personal job history.

## Phase 8 — States, accessibility, and visual proof

### Implement

1. For every canonical task, cover empty, loading, error/refusal, success/receipt, focus, and disabled states.
2. Reflow every multi-column composition to one ordered scroll column at accessibility Dynamic Type sizes.
3. Keep 44-point targets, semantic buttons, visible selection/focus, deterministic VoiceOver order, Reduce Motion, Reduce Transparency, and Differentiate Without Color behavior.
4. Capture default, selected, confirmation, success, empty, and disabled states at 844 × 390 without committing generated screenshots.
5. Test every legacy route alias for restoration, but do not render aliases as separate fake screens.

### Verify

- `swift run SimTests --design-contracts`
- `swift run SimTests --reduce-motion`
- project accessibility matrix and simulator/VoiceOver checks
- composited contrast measurements for Match Day yard numbers and every changed action/focus state

### Guard

- A syntactic `dynamicTypeSize` marker is not proof of reflow.
- Do not count a legacy alias as a distinct completed screen.

## Phase 9 — Cut over and retire the old design

### Cutover criteria

1. Every visible destination completes its named task or gives a specific unavailable reason.
2. Every legacy route migrates deterministically and survives save/reload.
3. No row selection commits; every irreversible action names and confirms its consequence.
4. All canonical tasks pass the state and accessibility matrix at 844 × 390 and AX5.
5. DEBUG proofs used for design approval have either become production code or been deleted.
6. Shared chrome lists canonical valid tasks only; no old navigation remains behind a flag.
7. Build, focused suites, full verification lane, rewrite tournament, confidence review, and GitNexus change detection are green.

### Final verification

- `swift build`
- all phase-specific SimTests selectors
- `./scripts/verify.sh` or the documented full lane
- required rewrite tournament on changed non-trivial functions
- required confidence review with every low-confidence item investigated
- GitNexus `detect_changes(scope: "compare", base_ref: "main")`

## Execution order

Phases are consecutive. Phase 1 may ship before route consolidation because it removes deceptive behavior without locking the new IA. Phases 3–7 may be separate reviewable changes, but Phase 9 removes old wrappers and updates the registry only after all required canonical tasks are ready.
