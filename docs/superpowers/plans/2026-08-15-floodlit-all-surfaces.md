# Floodlit All-Surfaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current v3/light-aware presentation with the approved dark-only Floodlit system across all 62 registered SwiftUI surfaces, without changing simulation facts, navigation semantics, intent callbacks, or save data.

**Architecture:** Preserve `CoachWorldScreenID`, `CoachWorldAppRootView`, immutable read models, providers, and store intent seams. Land the ten Claude Design v4 sheets as the visual contract, then implement one dark palette and a small shared SwiftUI vocabulary in the existing token/component files. Convert the actual presentation roots by family; thin registry wrappers inherit the converted family view. The application root supplies an honest unavailable state whenever a registered route lacks a retained read model.

**Tech Stack:** Swift 5 mode in Swift 6.3.3, SwiftUI, SF Symbols, the existing hand-rolled `SimTests` harness, XCTest UI tests, XcodeGen, iOS 26 simulator tooling, Claude Design MCP, and GitNexus. No new dependency.

**Global Constraints:**

- The approved specification is `docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`.
- Floodlit is dark-only. Do not retain a production light palette, appearance switch, light proof, or system-colour-scheme branch.
- Preserve the six spacing values `4/6/8/12/16/20`, `.82` deep-panel opacity, a tracked 10 pt micro-label role, a 12 pt authored body floor, and 44 pt primary/irreversible targets.
- Keep the existing Match Day engine and read model. Do not port `match-sim.dc.html` or `match-2d.dc.html`.
- Use only facts already present in immutable UI read models. Missing evidence renders an honest degraded or unavailable state.
- Preserve the user's dirty worktree. Stage and commit only explicit task paths. Never use `git add -A`, `git add .`, `git commit -a`, reset, checkout, clean, or bulk deletion.
- Before editing any function, class, method, struct, or enum, run GitNexus `impact({target, direction: "upstream", includeTests: true})`, report direct callers, affected processes, and risk. Stop and warn before HIGH or CRITICAL edits.
- Before every task commit, run GitNexus `detect_changes({scope: "unstaged"})` and review only that task's paths. The worktree contains unrelated changes, so GitNexus's aggregate risk is not by itself evidence that the task caused them.
- After each non-trivial code task, run `rewrite-tournament` in post-edit mode on changed functions. Before any completion claim, run `confidence-review` and resolve every confirmed issue.

## File and surface map

The 62 registry entries already resolve to view files. Most short files are route wrappers; the meaningful conversion seams are the shared view they call.

| Registry range | Surfaces | Presentation roots to convert |
|---|---|---|
| 1–7 | Title/Continue, coach identity, job/offer/appointment, settings, world search | `TitleContinueView`, `NewCareerCoachIdentityView`, `CareerHubView`, `SettingsAccessibilityView`, `WorldSearchView` |
| 8–15 | HQ, inbox, film, game/practice plan, health, match, aftermath | `CoachingHQView`, `InboxView`, `OpponentFilmView`, `GamePlanView`, `PracticePlanView`, `TeamHealthView`, `MatchDayView`, `AftermathView` |
| 16–23 | Roster, depth, player/development, staff, scheme, packages | `RosterView`, `DepthChartView`, `PlayerProfileView`, `DevelopmentPlanView`, `StaffRoomView`, `GamePlanView` |
| 24–33, 61 | Recruiting, prospect, shortlist, contact/class/signing, portal/NIL, college offseason | `RecruitingBoardView`, `ProspectProfileView`, `ShortlistView`, `ContactVisitPlannerView`, `ClassOverviewView`, `CollegeOffseasonView` |
| 34–40, 62 | Cap/contracts, negotiation, cuts, scouting, draft, free agency, pro offseason | `ProManagementView`, `ContractNegotiationView`, `ProOffseasonView`, `DraftRoomView` |
| 41–51 | League/team, standings/schedule/postseason, box score, statistics, awards, news, realignment | `LeagueMapView`, `TeamProgrammeProfileView`, `StandingsView`, `ScheduleView`, `CompetitionOverviewView`, `GameDetailBoxScoreView`, `StatisticsLeadersView`, `AwardsHonoursView`, `NewsView`, `RealignmentEventView` |
| 52–60 | Career hub/stakes/carousel and durable history | `CareerHubView`, `JobSecurityView`, `StakeholdersView`, `PromotionDecisionView`, `CoachingCarouselView`, `LegacyHistoryView` |

Thin wrappers remain thin: `AppointmentView`, `JobBoardView`, `OfferView`, `OpponentReportFilmRoomView`, `StaffMarketProfileView`, `SchemeBookView`, `PersonnelPackagesView`, `PortalHubView`, `RetentionDecisionsView`, `PortalMarketView`, `NilAllocationView`, `SigningDayView`, `CapContractsView`, `RosterCutsTransactionsView`, `ProScoutingBoardView`, `DraftBoardView`, `FreeAgencyView`, `RankingsPlayoffPictureView`, `BracketPostseasonView`, `RecordBookView`, `RivalriesView`, `CareerLineView`, and `CoachingTreeView` should only need label/accessibility corrections if their delegated family cannot express the route context.

---

### Task 1: Import the approved Claude Design v4 contract

**Files:**

- Create: `tokens-v4.dc.html`
- Create: `depth-v4.dc.html`
- Create: `gauge-v4.dc.html`
- Create: `chrome-v4.dc.html`
- Create: `table-v4.dc.html`
- Create: `person-v4.dc.html`
- Create: `readout-v4.dc.html`
- Create: `week-v4.dc.html`
- Create: `broadcast-v4.dc.html`
- Create: `failure-v4.dc.html`
- Create: `docs/proofs/design-references/tokens-v4-sheet.png`
- Create: `docs/proofs/design-references/depth-v4-sheet.png`
- Create: `docs/proofs/design-references/gauge-v4-sheet.png`
- Create: `docs/proofs/design-references/chrome-v4-sheet.png`
- Create: `docs/proofs/design-references/table-v4-sheet.png`
- Create: `docs/proofs/design-references/person-v4-sheet.png`
- Create: `docs/proofs/design-references/readout-v4-sheet.png`
- Create: `docs/proofs/design-references/week-v4-sheet.png`
- Create: `docs/proofs/design-references/broadcast-v4-sheet.png`
- Create: `docs/proofs/design-references/failure-v4-sheet.png`
- Create: `docs/plans/2026-08-14-floodlit-canon-amendment.md`
- Modify: `docs/proofs/design-references/README.md`

- [ ] **Step 1: Re-read the ten source files through Claude Design MCP**

Read the project by ID `4067686f-89c3-4a54-8058-e696cd570f03`. Confirm the file list still contains exactly the ten `*-v4.dc.html` sheets above, their ten renders, the canon amendment, and the reference README. If the remote files changed after approval, stop and show the diff in design decisions before importing it.

- [ ] **Step 2: Import text artifacts byte-for-byte**

Use MCP `read_file` for each HTML/Markdown file and `apply_patch` to create the local file. Do not copy the excluded match prototypes or `export/main` path prefix into the repository.

- [ ] **Step 3: Import the ten PNG renders**

Use the Design MCP file/download response for each PNG. Validate each output with:

```bash
file docs/proofs/design-references/*-v4-sheet.png
sips -g pixelWidth -g pixelHeight docs/proofs/design-references/*-v4-sheet.png
```

Expected: ten valid PNGs with non-zero dimensions.

- [ ] **Step 4: Verify the imported reference inventory**

Run:

```bash
find . -maxdepth 1 -name '*-v4.dc.html' -print | sort
find docs/proofs/design-references -name '*-v4-sheet.png' -print | sort
rg -n 'match-sim|match-2d' . --glob '*-v4.dc.html' --glob 'docs/proofs/design-references/**'
```

Expected: ten HTML files, ten PNGs, and no imported prototype reference.

- [ ] **Step 5: Commit only the imported contract**

Run `detect_changes`, then:

```bash
git add tokens-v4.dc.html depth-v4.dc.html gauge-v4.dc.html chrome-v4.dc.html \
  table-v4.dc.html person-v4.dc.html readout-v4.dc.html week-v4.dc.html \
  broadcast-v4.dc.html failure-v4.dc.html \
  docs/proofs/design-references/tokens-v4-sheet.png \
  docs/proofs/design-references/depth-v4-sheet.png \
  docs/proofs/design-references/gauge-v4-sheet.png \
  docs/proofs/design-references/chrome-v4-sheet.png \
  docs/proofs/design-references/table-v4-sheet.png \
  docs/proofs/design-references/person-v4-sheet.png \
  docs/proofs/design-references/readout-v4-sheet.png \
  docs/proofs/design-references/week-v4-sheet.png \
  docs/proofs/design-references/broadcast-v4-sheet.png \
  docs/proofs/design-references/failure-v4-sheet.png \
  docs/proofs/design-references/README.md \
  docs/plans/2026-08-14-floodlit-canon-amendment.md
git diff --cached --check
git commit -m "docs: import Floodlit v4 references"
```

---

### Task 2: Turn the approved Floodlit decisions into executable contracts

**Files:**

- Modify: `Tests/SimTests/Suites/DesignContractTests.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift`
- Modify: `Tests/SimTests/Suites/AccessibilityReflowTests.swift`

- [ ] **Step 1: Run impact analysis before editing each test runner**

Run upstream impact for `runDesignContractTests`, `runContractTests`, and `runAccessibilityReflowTests`. These should affect the test entry point only; investigate any production flow reported.

- [ ] **Step 2: Replace the v3 sheet inventory test and make it fail**

Use one canonical list in `DesignContractTests.swift`:

```swift
private let floodlitSheets = [
    "tokens", "depth", "gauge", "chrome", "table",
    "person", "readout", "week", "broadcast", "failure",
]
```

Assert all ten root `*-v4.dc.html` files and all ten `docs/proofs/design-references/*-v4-sheet.png` files exist, all sheets contain a dark Floodlit marker, and no production contract references `*-v3.dc.html`.

- [ ] **Step 3: Add failing token tests**

Add contract assertions for the approved values:

```swift
expectEqual(CoachWorldTokens.Depth.deepPanelOpacity, 0.82)
expectEqual(CoachWorldTokens.TypeRole.microLabelSize, 10)
expectEqual(CoachWorldTokens.TypeRole.authoredFloor, 12)
```

Also assert the six spacing values and 44 pt target remain unchanged. The production source scan
for retired light branches lands in Task 13, after every family has been converted; committing that
red for the duration of the cutover would make intermediate verification meaningless.

- [ ] **Step 4: Make registry coverage non-vacuous**

Tighten `AccessibilityReflowTests` so all 62 registry view filenames are landed, not merely partitioned into landed/pending:

```swift
let (landed, pending) = landedFamilies()
expectEqual(landed.count, 62)
expect(pending.isEmpty, "registered surfaces still missing: \(pending.map(\\.canonicalName))")
```

Keep the existing AX5 composition and deterministic VoiceOver-order assertions for every landed file.

- [ ] **Step 5: Run the tests and confirm the intended red state**

```bash
swift run SimTests --design-contracts
swift run SimTests --core-contracts
```

Expected: failures identify the missing token members and stale v3 test expectations. Unexpected
simulation failures must be separated from these intentional presentation failures before
continuing.

- [ ] **Step 6: Keep the red contracts uncommitted until Task 3 makes them green**

Do not commit an intentionally failing repository state. Leave only the three exact test-file edits
in the worktree and continue immediately to Task 3.

---

### Task 3: Replace the token system and shared Floodlit foundation

**Files:**

- Modify: `Sources/ProFootballCoachUI/DesignTokens.swift`
- Modify: `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift`
- Modify: `Sources/ProFootballCoachUI/BlankPhotoPlate.swift`
- Test: `Tests/SimTests/Suites/ContractTests.swift`

- [ ] **Step 1: Run impact analysis and report the shared blast radius**

Run upstream impact for `CoachWorldTokens`, `CoachWorldActionButtonStyle`, `CoachWorldRouteButton`, `CoachWorldBlankPhotoPlate`, and `coachWorldDeskSurface`. This is expected to be HIGH because these are shared UI symbols. Report all direct view callers before editing; do not continue silently if GitNexus reports HIGH or CRITICAL.

- [ ] **Step 2: Replace the parallel palettes with one Floodlit palette**

Retain `ColorValue`, `Palette`, `Space`, and existing semantic property names where callers use them. Remove `light`; rename `dark` only if the resulting migration is smaller than keeping `dark` as the one canonical value. Add only approved roles:

```swift
public enum Depth {
    public static let glassPanelOpacity = 0.64
    public static let deepPanelOpacity = 0.82
}

public enum TypeRole {
    public static let microLabelSize: CGFloat = 10
    public static let authoredFloor: CGFloat = 12
    public static let microLabel = Font.system(size: microLabelSize, weight: .bold)
        .width(.condensed)
    public static let microLabelTracking: CGFloat = 0.8
    // Preserve display/title/headline/body/callout/caption call sites.
}
```

Apply `microLabelTracking` with `Text.tracking(_:)`; `Font` itself does not own tracking.

Use the exact v4 semantic colours. Do not add a theme object, protocol, dependency, or user setting.

- [ ] **Step 3: Add the minimum shared foundation to the existing component file**

Implement native shapes/modifiers for:

```swift
enum CoachWorldRegister { case desk, broadcast }
enum CoachWorldPanelDepth { case glass, deep }

struct CoachWorldCutCorner: Shape { /* asymmetric path from v4 geometry */ }
struct CoachWorldStage<Content: View>: View { /* dark world + safe area + register */ }
struct CoachWorldPanel<Content: View>: View { /* depth + Reduce Transparency */ }
```

`CoachWorldStage` owns the committed dark backdrop, the accessibility identifier
`floodlit-stage`, and `.preferredColorScheme(.dark)`. Read `accessibilityReduceTransparency`,
`accessibilityReduceMotion`, `accessibilityDifferentiateWithoutColor`, and `colorSchemeContrast`
only where they alter drawing. Grain must be fixed-seed/static and hidden when Reduce Transparency
is enabled. Do not create an animation coordinator.

- [ ] **Step 4: Adapt existing controls rather than duplicating them**

Update `CoachWorldActionButtonStyle`, `CoachWorldRouteButton`, `coachWorldDeskSurface`, and `CoachWorldBlankPhotoPlate` to use the Floodlit panel geometry, action hierarchy, focus stroke, disabled state, and 44 pt semantic target. Preserve their public/internal initializer shapes wherever possible so callers need only palette removal.

- [ ] **Step 5: Make the shared contracts green**

```bash
swift run SimTests --design-contracts
swift build
```

Expected: token and primitive tests pass; per-screen light-branch failures remain until later tasks.

- [ ] **Step 6: Run rewrite-tournament and commit the now-green contracts with the foundation**

Review only the changed shared functions/types, run `detect_changes`, stage the three Task 2 test
files plus the shared implementation files, and commit `feat: establish Floodlit presentation
foundation`.

---

### Task 4: Add the reusable data, people, chronology, broadcast, and state vocabulary

**Files:**

- Modify: `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift`
- Modify: `Sources/ProFootballCoachUI/MatchDayView.swift`
- Test: `Tests/SimTests/Suites/ContractTests.swift`

- [ ] **Step 1: Impact the existing component and Match Day symbols**

Run upstream impact for `CoachWorldActionButtonStyle`, `MatchDayView`, `MatchControlButtonStyle`, and every nested Match Day function to be edited. Warn before HIGH/CRITICAL work.

- [ ] **Step 2: Add only components with at least two production consumers**

Implement the smallest generic primitives needed by the forthcoming family tasks:

```swift
struct CoachWorldStatusChip: View { let label: String; let symbol: String?; let tone: Tone }
struct CoachWorldRatingRing: View { let value: Int; let label: String }
struct CoachWorldMeter: View { let value: Double; let range: ClosedRange<Double>; let label: String }
struct CoachWorldOpposedBar: View { let leading: Double; let trailing: Double; let label: String }
struct CoachWorldIdentityBand: View { /* retained identity fields only */ }
struct CoachWorldAgendaRow: View { /* title, timing, cost, state */ }
public struct CoachWorldSystemState: View { /* public Kind + init for CoachWorldApp */ }
```

Use printed text/symbols alongside colour. Clamp ratings to the documented display ceiling without mutating model data. Do not add one Swift type per one-off reference specimen: arc/value/dial/share variants may share the ring/meter/bar implementation when their semantics match.

- [ ] **Step 3: Extract Match Day broadcast furniture in place**

Keep the current match read model and callbacks. Refactor existing score, lower-third, interruption, and key-moment sections into private `ScoreBug`, `LowerThird`, `CallInCard`, and `KeyMomentsRow` views inside `MatchDayView.swift`. Use square BROADCAST geometry, tabular digits, team identity, and Reduce Motion-safe transitions.

- [ ] **Step 4: Add focused source contracts**

Assert the common state component exposes empty/error/loading/interrupted/delegated labels, colour-coded components include text/symbol redundancy, and Match Day still exposes exactly the five existing controls and all interruption actions.

- [ ] **Step 5: Verify and commit**

Run `swift run SimTests --core-contracts`, `swift build`, rewrite-tournament, and `detect_changes`. Commit only the three task paths as `feat: add Floodlit component vocabulary`.

---

### Task 5: Convert entry, setup, settings, and world-search surfaces (1–7)

**Files:**

- Modify: `Sources/ProFootballCoachUI/TitleContinueView.swift`
- Modify: `Sources/ProFootballCoachUI/NewCareerCoachIdentityView.swift`
- Modify: `Sources/ProFootballCoachUI/NewCareerSetupView.swift`
- Modify: `Sources/ProFootballCoachUI/CareerHubView.swift`
- Modify: `Sources/ProFootballCoachUI/SettingsAccessibilityView.swift`
- Modify: `Sources/ProFootballCoachUI/WorldSearchView.swift`
- Modify only if route wording requires it: `Sources/ProFootballCoachUI/JobBoardView.swift`, `OfferView.swift`, `AppointmentView.swift`

- [ ] **Step 1: Impact every view type and changed private function**

Run GitNexus upstream impact before each symbol edit. `CareerHubView` is shared with later career-stakes routes, so report its direct callers.

- [ ] **Step 2: Convert the shared roots**

Wrap each real presentation root in `CoachWorldStage(register: .desk)`, remove `colorScheme` environment branches, use the shared panel/action/state primitives, and preserve every field binding and callback. Keep setup validation, seed refresh, cancellation, and start actions unchanged.

- [ ] **Step 3: Verify AX5 and VoiceOver order in source contracts**

Every registry-named view file in this group must retain `dynamicTypeSize.isAccessibilitySize` and `accessibilitySortPriority`, including thin wrappers.

- [ ] **Step 4: Test and commit**

Run `swift run SimTests --design-contracts`, `swift build`, rewrite-tournament, and `detect_changes`. Commit only this task's touched files as `feat: convert Floodlit entry surfaces`.

---

### Task 6: Convert the weekly command and tactical surfaces (8–15)

**Files:**

- Modify: `Sources/ProFootballCoachUI/CoachingHQView.swift`
- Modify: `Sources/ProFootballCoachUI/InboxView.swift`
- Modify: `Sources/ProFootballCoachUI/OpponentFilmView.swift`
- Modify: `Sources/ProFootballCoachUI/OpponentReportFilmRoomView.swift`
- Modify: `Sources/ProFootballCoachUI/GamePlanView.swift`
- Modify: `Sources/ProFootballCoachUI/PracticePlanView.swift`
- Modify: `Sources/ProFootballCoachUI/TeamHealthView.swift`
- Modify: `Sources/ProFootballCoachUI/MatchDayView.swift`
- Modify: `Sources/ProFootballCoachUI/AftermathView.swift`

- [ ] **Step 1: Impact all nine view types plus edited nested functions**

Pay particular attention to `CoachingHQView` and `MatchDayView`; both are high-fan-out proof and production surfaces. Report risk before changes.

- [ ] **Step 2: Convert DESK surfaces**

Use the week grid/agenda/load hierarchy for HQ and Practice Plan, dense evidence panels for Inbox/Film/Game Plan/Health, and the shared honest state component for missing film, loading, blocked advance, and status messages. Preserve costs, consequences, delegate/inspect/commit callbacks, and causal ordering.

- [ ] **Step 3: Finish the BROADCAST conversion**

Apply `CoachWorldStage(register: .broadcast)` to Match Day and Aftermath. Keep all 22 actors, field direction, line-of-scrimmage/first-down marks, recorded commentary, five controls, and interruption paths intact. No new engine or inferred probability.

- [ ] **Step 4: Run focused behavior contracts**

```bash
swift run SimTests --tactical-management
swift run SimTests --tactical-state
swift run SimTests --match-reducer
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

- [ ] **Step 5: Review and commit**

Run rewrite-tournament and `detect_changes`; commit exact task files as `feat: convert Floodlit command surfaces`.

---

### Task 7: Convert personnel and staff surfaces (16–23)

**Files:**

- Modify: `Sources/ProFootballCoachUI/RosterView.swift`
- Modify: `Sources/ProFootballCoachUI/DepthChartView.swift`
- Modify: `Sources/ProFootballCoachUI/PlayerProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/DevelopmentPlanView.swift`
- Modify: `Sources/ProFootballCoachUI/StaffRoomView.swift`
- Modify only if route wording requires it: `StaffMarketProfileView.swift`, `SchemeBookView.swift`, `PersonnelPackagesView.swift`

- [ ] **Step 1: Impact the shared personnel symbols**

Run upstream impact for each public view and every private sort/filter/route function to be edited. Do not change `PersonnelReadModels.swift` unless a visible claim cannot be expressed truthfully; if that occurs, stop and re-scope.

- [ ] **Step 2: Convert tables and identity surfaces**

Use the shared dense rows, list controls, rating rings, role/status chips, identity bands, delta/confidence/form vocabulary, and blank photo plate. Preserve sort descriptors, selection, route tabs, stable IDs, and model-owned 0–99 values.

- [ ] **Step 3: Keep AX5 as information-preserving reflow**

At accessibility sizes, replace parallel columns with one scrollable evidence order. Do not hide attributes, development evidence, staff role, condition, or available actions.

- [ ] **Step 4: Test and commit**

Run `swift run SimTests --depth-chart`, `swift run SimTests --screen-read-models`, `swift run SimTests --design-contracts`, `swift build`, rewrite-tournament, and `detect_changes`. Commit exact files as `feat: convert Floodlit personnel surfaces`.

---

### Task 8: Convert recruiting and college-offseason surfaces (24–33, 61)

**Files:**

- Modify: `Sources/ProFootballCoachUI/RecruitingBoardView.swift`
- Modify: `Sources/ProFootballCoachUI/ProspectProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/ShortlistView.swift`
- Modify: `Sources/ProFootballCoachUI/ContactVisitPlannerView.swift`
- Modify: `Sources/ProFootballCoachUI/ClassOverviewView.swift`
- Modify: `Sources/ProFootballCoachUI/CollegeOffseasonView.swift`
- Modify only if route wording requires it: `SigningDayView.swift`, `PortalHubView.swift`, `RetentionDecisionsView.swift`, `PortalMarketView.swift`, `NilAllocationView.swift`

- [ ] **Step 1: Impact each shared view and edited helper**

Report the high-fan-out risk of `RecruitingBoardView` and `CollegeOffseasonView` before editing.

- [ ] **Step 2: Convert board, dossier, and chronology composition**

Use dense board columns, identity/confidence states, honest fog/degraded forms, costed action rows, week chronology, load/cap meters, and shared state surfaces. Preserve shortlist filtering, prospect IDs, commit intents, action availability, exact costs, and consequences.

- [ ] **Step 3: Verify college decision behavior**

```bash
swift run SimTests --portal-contracts
swift run SimTests --career-portal-decisions
swift run SimTests --college-state
swift run SimTests --design-contracts
swift build
```

- [ ] **Step 4: Review and commit**

Run rewrite-tournament and `detect_changes`; commit exact task paths as `feat: convert Floodlit college surfaces`.

---

### Task 9: Convert professional-management and offseason surfaces (34–40, 62)

**Files:**

- Modify: `Sources/ProFootballCoachUI/ProManagementView.swift`
- Modify: `Sources/ProFootballCoachUI/ContractNegotiationView.swift`
- Modify: `Sources/ProFootballCoachUI/ProOffseasonView.swift`
- Modify: `Sources/ProFootballCoachUI/DraftRoomView.swift`
- Modify only if route wording requires it: `CapContractsView.swift`, `RosterCutsTransactionsView.swift`, `ProScoutingBoardView.swift`, `DraftBoardView.swift`, `FreeAgencyView.swift`

- [ ] **Step 1: Impact all shared roots and negotiation helpers**

Run upstream impact for the four public views, `NegotiationCard`, and every changed private action helper.

- [ ] **Step 2: Convert cap, negotiation, market, and draft composition**

Use meters/opposed bars for retained cap and offer facts, dense rows for contracts/markets, explicit overage labels, committing gold actions, and BROADCAST furniture only for live draft moments. Preserve action IDs, enabled state, phase gates, costs, and consequences.

- [ ] **Step 3: Verify professional behavior**

```bash
swift run SimTests --pro-management
swift run SimTests --pro-market
swift run SimTests --cap-compliance
swift run SimTests --pro-draft-probe
swift run SimTests --design-contracts
swift build
```

- [ ] **Step 4: Review and commit**

Run rewrite-tournament and `detect_changes`; commit exact task paths as `feat: convert Floodlit pro surfaces`.

---

### Task 10: Convert world, competition, statistics, and event surfaces (41–51)

**Files:**

- Modify: `Sources/ProFootballCoachUI/LeagueMapView.swift`
- Modify: `Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/StandingsView.swift`
- Modify: `Sources/ProFootballCoachUI/ScheduleView.swift`
- Modify: `Sources/ProFootballCoachUI/CompetitionOverviewView.swift`
- Modify: `Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift`
- Modify: `Sources/ProFootballCoachUI/StatisticsLeadersView.swift`
- Modify: `Sources/ProFootballCoachUI/AwardsHonoursView.swift`
- Modify: `Sources/ProFootballCoachUI/NewsView.swift`
- Modify: `Sources/ProFootballCoachUI/RealignmentEventView.swift`
- Modify only if route wording requires it: `RankingsPlayoffPictureView.swift`, `BracketPostseasonView.swift`

- [ ] **Step 1: Impact each view and layout helper**

Include `LeagueMapLayout`, `LeagueMapMetric`, and every modified sorting/grouping helper. Do not alter the identifier-based map joins or generate geography that the model does not retain.

- [ ] **Step 2: Convert DESK information surfaces**

Use dense tables/columns, world strip, identity-safe team colour, status chips, and honest empty states. Preserve standings order, schedule facts, rankings, archive/statistics bounds, selected team IDs, and map/list parity.

- [ ] **Step 3: Convert event surfaces to BROADCAST where appropriate**

Use score/event furniture for box scores, awards ceremony moments, and realignment announcements without changing the underlying route or claiming nonexistent media.

- [ ] **Step 4: Verify and commit**

Run `swift run SimTests --competition-only`, `swift run SimTests --realignment`, `swift run SimTests --screen-read-models`, `swift run SimTests --design-contracts`, `swift build`, rewrite-tournament, and `detect_changes`. Commit exact files as `feat: convert Floodlit world surfaces`.

---

### Task 11: Convert career-stakes and history surfaces (52–60)

**Files:**

- Modify: `Sources/ProFootballCoachUI/CareerHubView.swift`
- Modify: `Sources/ProFootballCoachUI/JobSecurityView.swift`
- Modify: `Sources/ProFootballCoachUI/StakeholdersView.swift`
- Modify: `Sources/ProFootballCoachUI/PromotionDecisionView.swift`
- Modify: `Sources/ProFootballCoachUI/CoachingCarouselView.swift`
- Modify: `Sources/ProFootballCoachUI/LegacyHistoryView.swift`
- Modify only if route wording requires it: `RecordBookView.swift`, `RivalriesView.swift`, `CareerLineView.swift`, `CoachingTreeView.swift`

- [ ] **Step 1: Impact the career and history roots**

Run upstream impact for each public root and the private history-focus selection helpers. `CareerHubView` was already touched in Task 5; repeat impact against the current graph before further edits.

- [ ] **Step 2: Convert the career decision surfaces**

Use identity bands, verdict lines only where backed by model evidence, opposed bars/meters for retained values, exact cost/consequence actions, and honest unavailable states. Preserve origin-aware close/navigation behavior.

- [ ] **Step 3: Convert the durable-history family once**

Restyle `LegacyHistoryView`; keep the four route wrappers thin. Preserve archive bounds, focus selection, record/rivalry/career/tree distinctions, and empty-history wording.

- [ ] **Step 4: Verify and commit**

Run `swift run SimTests --career-arc`, `swift run SimTests --history-read-model`, `swift run SimTests --m7-gate`, `swift run SimTests --design-contracts`, `swift build`, rewrite-tournament, and `detect_changes`. Commit exact paths as `feat: convert Floodlit career surfaces`.

---

### Task 12: Make dark appearance and unavailable states authoritative at the app root

**Files:**

- Modify: `Sources/CoachWorldApp/CoachWorldAppRootView.swift`
- Modify: `Sources/ProFootballCoachUI/RootView.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift`
- Modify: `Tests/ProFootballCoachTests/ProFootballCoachTests.swift`

- [ ] **Step 1: Impact the root symbols before editing**

Run upstream impact for `CoachWorldAppRootView`, `career`, `navigate`, `RootView`, and `DebugCoachingHQRoot`. `career` participates in the `Career → Snapshot` process and calls most production roots; warn before any HIGH/CRITICAL result.

- [ ] **Step 2: Add one root-level dark commitment**

Apply `.preferredColorScheme(.dark)` and the Floodlit page ground at the shipped root and DEBUG root. This is a guardrail, not a replacement for the per-family conversion.

- [ ] **Step 3: Replace blank optional branches with one truthful helper**

Use one private helper rather than 62 copied empty states:

```swift
@ViewBuilder
private func surface<Model, Content: View>(
    _ model: Model?,
    screen: CoachWorldScreenID,
    @ViewBuilder content: (Model) -> Content
) -> some View {
    if let model {
        content(model)
    } else {
        CoachWorldSystemState(
            kind: .empty,
            title: "\(screen.canonicalName) unavailable",
            detail: "No retained career evidence is available for this surface."
        )
    }
}
```

Use it for each optional read-model branch in `career`. Do not change route eligibility or invent fallback models.

- [ ] **Step 4: Add root contracts**

Assert the shipped and DEBUG roots both commit dark appearance, every `CoachWorldScreenID` switch case is handled, and optional model branches call the unavailable helper instead of producing `EmptyView`.

- [ ] **Step 5: Complete the existing proof launch seam for the render gate**

Read `PROOF_SCREEN_NUMBER` only in `#if DEBUG`, validate it through
`CoachWorldScreenID(rawValue:)`, and prefer it over the restored presentation route. Reuse the
existing `PROOF_NEW_CAREER` convention rather than adding a second launch variable: when it carries
a valid seed and no save exists, obtain `CoachWorldStore.startingJobs(seed:)`, choose the first
returned job, and call the existing `startNewCareer` method. Keep this behavior in `#if DEBUG` so it
does not compile into Release. This lets Task 14 exercise all 62 routes without introducing sample
facts into production.

- [ ] **Step 6: Verify and commit**

Run `swift run SimTests --core-contracts`, `swift build`, rewrite-tournament, and `detect_changes`. Commit exact task paths as `fix: make Floodlit root states explicit`.

---

### Task 13: Update canonical documentation and retire v3/light authority

**Files:**

- Modify: `docs/04-UX-AND-DESIGN-SYSTEM.md`
- Modify: `docs/04b-AUDIT-RUBRIC.md`
- Modify: `docs/DOC-MANIFEST.md`
- Modify: `docs/proofs/README.md`
- Modify: `docs/plans/2026-08-12-road-to-beta.md`
- Modify: `docs/STATUS.md`
- Delete after v4 verification: `tokens-v3.dc.html`, `chrome-v3.dc.html`, `table-v3.dc.html`, `person-v3.dc.html`, `readout-v3.dc.html`, `week-v3.dc.html`, `broadcast-v3.dc.html`, `failure-v3.dc.html`
- Delete after v4 verification: `docs/proofs/design-references/tokens-v3-sheet.png`, `chrome-v3-sheet.png`, `table-v3-sheet.png`, `person-v3-sheet.png`, `readout-v3-sheet.png`, `week-v3-sheet.png`, `broadcast-v3-sheet.png`, `failure-v3-sheet.png`
- Delete as superseded light evidence: `docs/proofs/coaching-hq-light-standard.png`, `docs/proofs/recruiting-board-light-standard.png`, `docs/proofs/match-day-light-standard.png`, `docs/proofs/personnel/roster-light-default-iphone17promax.png`, `docs/proofs/personnel/player-light-default-iphone17promax.png`

- [ ] **Step 1: Apply the approved canon amendment**

Make the ten v4 sheets definitive; document dark-only presentation, `.82` deep panels, 10 pt tracked micro-labels, 12 pt authored body floor, six-value spacing, all 47 specimens, and the two excluded match prototypes. Remove live requirements for two appearances and light proofs. Preserve historical documents as history rather than rewriting every old mention.

- [ ] **Step 2: Update the audit and proof contracts**

Change the audit matrix from light/dark to dark Floodlit plus default/AX5, Reduce Transparency,
Reduce Motion, Increase Contrast, Differentiate Without Color, VoiceOver, and three supported
widths. Remove light proof rows; the five superseded light captures are deleted in this task.

- [ ] **Step 3: Delete only the exact retired v3 artifacts**

Before deletion, enumerate and verify the 21 targets are regular files inside the repository and
that all ten v4 replacements exist. Do not use a recursive command or wildcard deletion. Remove
each exact file with `apply_patch` for text and the safest exact-file operation available for PNGs.

- [ ] **Step 4: Run documentation/reference contracts**

```bash
swift run SimTests --design-contracts
rg -n 'CoachWorldTokens\.light|@Environment\(\\\.colorScheme\)' Sources/ProFootballCoachUI
rg -n '\*-v3\.dc\.html|light and dark|both appearances' \
  docs/04-UX-AND-DESIGN-SYSTEM.md docs/04b-AUDIT-RUBRIC.md \
  docs/DOC-MANIFEST.md docs/proofs/README.md
```

Expected: tests pass; production source has no light dependency; live canon has no v3/two-appearance authority. Historical briefs may still describe the former v3 work as historical.

- [ ] **Step 5: Commit the canon cutover**

Run `detect_changes`, stage only the listed docs and exact deletions, and commit `docs: make Floodlit v4 canonical`.

---

### Task 14: Build the app and record the dark-only verification matrix

**Files:**

- Modify: `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift`
- Modify: `docs/proofs/README.md`
- Create: `docs/proofs/floodlit/desk-844-default.png`
- Create: `docs/proofs/floodlit/desk-852-ax5-reduce-transparency.png`
- Create: `docs/proofs/floodlit/desk-956-ax5.png`
- Create: `docs/proofs/floodlit/broadcast-844-default.png`
- Create: `docs/proofs/floodlit/broadcast-852-ax5-reduce-motion.png`
- Create: `docs/proofs/floodlit/broadcast-956-ax5.png`
- Create: `docs/proofs/floodlit/registry-62-results.md`

- [ ] **Step 1: Impact the UI test class before editing**

Run upstream impact for `ProFootballCoachUITests` and the placeholder test method.

- [ ] **Step 2: Replace the placeholder UI test with launch and semantic checks**

Add one registry loop using the DEBUG seams from Task 12:

```swift
func testEveryRegisteredSurfaceRendersFloodlitOrUnavailable() {
    for number in 1...62 {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = String(number)
        app.launch()
        XCTAssertTrue(app.otherElements["floodlit-stage"].waitForExistence(timeout: 20))
        app.terminate()
    }
}
```

Also assert the app does not expose a light appearance switch, primary actions are hittable, and
representative DESK/BROADCAST surfaces expose expected accessibility labels. Do not build a custom
snapshot framework.

- [ ] **Step 3: Generate and build the iOS project**

```bash
xcodegen generate --spec App/project.yml --project App/ProFootballCoach.xcodeproj
xcodebuild -project App/ProFootballCoach.xcodeproj \
  -scheme ProFootballCoach -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Expected: clean iOS Simulator build.

- [ ] **Step 4: Run the simulator/accessibility workflows**

Use `ios-simulator-skill` and `verify-ios-accessibility-matrix`. Test dark-only rendering at 844×390, 852×393, and 956×440, default and AX5, for every registry surface reachable in the fixed career. For a route that is unavailable in the fixture, capture the explicit unavailable surface. Verify Reduce Transparency, Reduce Motion, Increase Contrast, Differentiate Without Color, VoiceOver order/labels, focus, and 44 pt primary/irreversible targets.

- [ ] **Step 5: Retain representative evidence without claiming unrun checks**

Store dark-only DESK and BROADCAST captures plus an index under `docs/proofs/floodlit/`. Record physical-device-only checks as pending unless actually performed. Do not create light captures.

- [ ] **Step 6: Run Xcode tests and commit evidence**

```bash
xcodebuild -project App/ProFootballCoach.xcodeproj \
  -scheme ProFootballCoach -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```

Run rewrite-tournament if UI test functions changed materially, then `detect_changes`. Commit only the UI test and retained proof paths as `test: verify Floodlit device matrix`.

---

### Task 15: Final adversarial verification and completion gate

**Files:**

- Modify only confirmed fixes from the review
- Modify: `docs/STATUS.md` only if final results differ from Task 13's provisional record

- [ ] **Step 1: Run the complete repository gate**

```bash
./scripts/verify.sh
```

Expected: `swift build` and the complete release `SimTests` run pass.

- [ ] **Step 2: Run explicit presentation residue checks**

```bash
test "$(find . -maxdepth 1 -name '*-v4.dc.html' | wc -l | tr -d ' ')" = 10
test "$(find docs/proofs/design-references -name '*-v4-sheet.png' | wc -l | tr -d ' ')" = 10
test -z "$(find . -maxdepth 1 -name '*-v3.dc.html' -print)"
test -z "$(find docs/proofs -type f -iname '*light*.png' -print)"
test -z "$(rg -l 'CoachWorldTokens\.light|@Environment\(\\\.colorScheme\)' Sources/ProFootballCoachUI)"
swift run SimTests --design-contracts
```

- [ ] **Step 3: Run `confidence-review`**

Enumerate every low-confidence area, including composited contrast over world stripes, `.82` panel behavior with Reduce Transparency, AX5 information retention, wrapper inheritance, route availability, Match Day control preservation, and proof completeness. Investigate each to root cause and patch confirmed defects.

- [ ] **Step 4: Re-run rewrite-tournament for review fixes**

Only if the confidence review changed non-trivial functions. Re-run the focused and full gates after any fix.

- [ ] **Step 5: Run final GitNexus scope review**

Run `detect_changes({scope: "compare", base_ref: "main"})`. Review every affected process, especially `Career → Snapshot`, restore/navigation, intent commits, and save flows. The expected production changes are presentation and explicit unavailable-state handling only.

- [ ] **Step 6: Commit only confirmed final fixes**

Use explicit paths, `git diff --cached --check`, and a narrow commit message. Do not stage unrelated user work.

- [ ] **Step 7: Report completion accurately**

Report the ten imported sheets/renders, the shared system, all 62 covered registry surfaces, dark-only proofs, automated results, manual checks actually performed, manual checks still pending, and any unrelated dirty paths left untouched.
