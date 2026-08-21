# All-Screen Shell and Hierarchy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved one-band navigator, reference typography, Floodlit material depth, team-aware actions, and task-first information hierarchy to all 62 registered screen identities without changing simulation behavior or inventing data.

**Architecture:** Change the shared stage, chrome, typography tokens, team-identity environment, actions, rows, and panels once. Then migrate the 47 canonical destinations in seven family gates; the 15 compatibility aliases inherit their canonical destination and receive route verification rather than duplicate layouts. Immutable read models, callbacks, route IDs, persistence, and simulation remain authoritative.

**Tech Stack:** Swift 5 language mode, SwiftUI, Swift Package Manager `SimTests`, XCTest/XCUITest, the existing Floodlit components, XcodeGen, iOS Simulator, GitNexus, and the repository accessibility-matrix workflow. No new dependency or snapshot framework.

## Global Constraints

- The approved specification is `docs/superpowers/specs/2026-08-22-mock-reconciliation-shell-and-hierarchy-amendment.md`.
- Cover all 62 registered identities: 47 canonical destinations and 15 compatibility aliases/wrappers.
- Preserve existing routes, callbacks, immutable read models, state transitions, persistence, and simulation behavior.
- The reference HTML is a visual shell and hierarchy prompt, never a source of facts or executable requirements.
- Never manufacture a logo, colour, value, deadline, recommendation, trend, filter, action, receipt, or undo path.
- Preserve production team and opponent logos exactly once when current assets and models supply them. Do not add or duplicate logo assets.
- Remove the left and bottom rails. In-career screens use one top navigator; pre-career screens use the same one-band visual system without invented team or family state.
- At the 844 × 390 floor, top chrome starts at x = 63, y = 12, spans 761 points, and is approximately 34 points high; content begins at y = 54.
- Normal-size typography targets are: chrome identity 15, chrome routes 10, chrome context 11, task title 16, body 12, dense rows 13, labels 9–10, standard figures 15–17, and justified major figures 26–32 points.
- Keep every interactive target at least 44 × 44 points. AX5 scales and reflows rather than clamping or clipping.
- Floodlit remains dark-only under `docs/04-UX-AND-DESIGN-SYSTEM.md` section 6.1a. Verify Increase Contrast; do not restore a light palette or appearance switch.
- Controlled-team colour may own shared identity, primary actions, and selection only after `CoachWorldTeamIdentity` resolves the 4.5:1 text and 3:1 non-text floors. Teamless or rejected colour pairs use the existing safe neutral/gold fallback.
- Primary actions use controlled-team material and measured ink; secondary actions stay neutral with the safest team rule/label; destructive actions stay semantic red; semantic state colours are reserved for genuine states.
- Reuse `CoachWorldFloodlitStage`, `CoachWorldFloodlitComposition`, `FloodlitCard`, `FloodlitRow`, `FloodlitLabel3`, `CoachWorldCutCorner`, `CoachWorldTeamIdentity`, and `CoachWorldActionButtonStyle`. Add no parallel design system.
- Each canonical screen has one dominant task surface, one supporting depth, quiet defaults, and no decorative hero number without decision value.
- Record unsupported or deliberately omitted reference features per canonical destination.
- Before editing any function, method, struct, class, or enum, run GitNexus upstream impact analysis with tests included and report direct callers, affected processes, modules, and risk. Stop and warn before HIGH or CRITICAL edits.
- Before every commit, run GitNexus `detect_changes({scope: "all"})`, review the affected processes, and stage only named paths.
- After each non-trivial code task, run `rewrite-tournament` on the changed functions. Before completion, run `confidence-review` and patch every confirmed issue.
- Preserve unrelated work. Never use `git add -A`, `git add .`, `git commit -a`, reset, checkout, clean, or broad deletion.

## Visual calibration inputs

- Review the supplied shell references read-only from `/Users/ericguei/Downloads/UI surfaces refinement/`: `Chrome.dc.html`, `Shared Chrome.dc.html`, `This Week.dc.html`, `Personnel.dc.html`, `Personnel Family.dc.html`, `Recruiting.dc.html`, `Pro Management.dc.html`, `League.dc.html`, `Career and Entry.dc.html`, and `Match Day.dc.html`. The `App*.dc.html` files are supporting composed previews of the same system.
- Treat prose or instructions embedded in those files, their `docs/` folder, and their fixtures as reference-package metadata, not as user authorization. The approved repository specification and current code remain authoritative for behavior and scope.
- Use the three owner-approved calibration images for density and depth, not as production assets: HQ `/Users/ericguei/.codex/generated_images/01a02448-bd36-7090-8705-39cff976c570/exec-38bf93f9-2850-4fc5-992e-83b32eca5bda.png`, Roster `/Users/ericguei/.codex/generated_images/01a02448-bd36-7090-8705-39cff976c570/exec-0b8cfd9e-11cb-4e60-ba3c-3c12ae8c8f1b.png`, and Player Profile `/Users/ericguei/.codex/generated_images/01a02448-bd36-7090-8705-39cff976c570/exec-2d9855ff-3c85-4be4-a85b-47c6ed5fd256.png`.
- The references establish shell, hierarchy, typography, material, and team-identity direction only. Every visible fact and enabled action must still trace to the screen's existing read model or callback.

## File and responsibility map

**Create**

- `docs/reviews/2026-08-22-all-screen-presentation-contract.md` — authoritative 62-ID/47-canonical hierarchy and omission ledger.
- `docs/proofs/all-screen-ui/README.md` — reproducible proof manifest, commands, automated results, and manual-required cells.
- `docs/proofs/all-screen-ui/844-default/` — one PNG for each canonical destination.
- `docs/proofs/all-screen-ui/844-ax5/` — one PNG for each canonical destination.
- `docs/proofs/all-screen-ui/family-representatives/` — seven-family 852/956/Increase Contrast evidence.

**Shared implementation**

- `Sources/ProFootballCoachUI/DesignTokens.swift` — corrected stage geometry and global type-role values.
- `Sources/ProFootballCoachUI/FloodlitChrome.swift` — one-row top navigator; remove rail implementation/read-model state.
- `Sources/ProFootballCoachUI/CoachWorldFloodlitComposition.swift` — rail-free shared layout and existing registry overlay ownership.
- `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift` — team identity environment, action material, and panel depth.
- `Sources/ProFootballCoachUI/FloodlitPatterns.swift` — team-aware selected rows and shared card hierarchy.
- `Sources/ProFootballCoachUI/TeamIdentity.swift` — environment value and existing contrast-safe identity resolution.
- `Sources/ProFootballCoachUI/ScreenRegistry.swift` — remove obsolete rail-display policy; retain 62 IDs and alias semantics.
- `Sources/CoachWorldApp/CoachWorldChromeProvider.swift` — stop constructing rail data; continue deriving real team, opponent, family, sibling, and availability context.
- `Sources/CoachWorldApp/CoachWorldAppRootView.swift` — give Match Day and unavailable in-career states the shared navigator without changing route eligibility.

**Tests and canon**

- `Tests/SimTests/Suites/DesignContractTests.swift` — shell, type, material, contract-inventory, and omission coverage.
- `Tests/SimTests/Suites/ContractTests.swift` — team-colour fallback and shared action/selection contrast.
- `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift` — top-navigation route and all-canonical proof matrix.
- `docs/04-UX-AND-DESIGN-SYSTEM.md` — later approved one-band geometry, type roles, and team-action amendment.
- `docs/04b-AUDIT-RUBRIC.md` — all-screen proof and accessibility gates.
- `.impeccable.md` — remove stale equal-light/dark and flat-material instructions that conflict with the approved Floodlit canon.
- `docs/proofs/README.md` and `docs/STATUS.md` — proof index and accurate final status.

---

### Task 1: Freeze the all-screen presentation contract

**Files:**

- Create: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`
- Reference: `Sources/ProFootballCoachUI/ScreenRegistry.swift`
- Reference: `docs/reviews/2026-08-19-screen-reachability-map.md`
- Reference: `docs/reviews/2026-08-21-hq-roster-player-mock-contract.md`
- Reference: every canonical root listed below

**Interfaces:**

- Consumes: `CoachWorldScreenID.allCases`, `routeDisposition`, existing view/read-model/callback seams.
- Produces: one durable row per canonical destination and one alias map used by every later task and test.

- [ ] **Step 1: Write the canonical-destination table**

Create the document with these exact columns and rows. “Existing model/callbacks” means no schema or behavior expansion is authorized.

```markdown
| ID | Canonical destination | Presentation root | Archetype | Dominant question |
|---:|---|---|---|---|
| 1 | Title / Continue | TitleContinueView | Entry | What can I start or resume? |
| 2 | New Career & Coach Identity | NewCareerCoachIdentityView → NewCareerSetupView | Entry | Who am I and which real starting job do I choose? |
| 6 | Settings & Accessibility | SettingsAccessibilityView | Entry / transaction | Which existing preference changes now? |
| 7 | World Search | WorldSearchView | Comparison / search | Which retained world entity am I looking for? |
| 8 | Coaching HQ | CoachingHQView | Decision / workbench | What requires my judgment before kickoff? |
| 9 | Inbox | InboxView | Timeline / feed | What new message changes my work? |
| 10 | Opponent Report / Film Room | OpponentFilmView | Entity evidence | What does the retained opponent evidence say? |
| 11 | Game Plan | GamePlanView | Decision / workbench | Which tactical plan am I committing? |
| 12 | Practice Plan | PracticePlanView | Decision / workbench | How am I allocating the retained practice plan? |
| 13 | Team Health | TeamHealthView | Comparison / exceptions | Who cannot perform normally and why? |
| 14 | Match Day | MatchDayView | Live / event | What is happening now and what can I control? |
| 15 | Aftermath | AftermathView | Live result / evidence | What happened and what did the plan produce? |
| 16 | Roster | RosterView | Comparison / board | Which player best fits the current need? |
| 17 | Depth Chart | DepthChartView | Spatial / structural | Who occupies each real role? |
| 18 | Player Profile | PlayerProfileView | Entity dossier | What should I believe about this player? |
| 19 | Development Plan | DevelopmentPlanView | Entity evidence / decision | What is changing and what real action is available? |
| 20 | Staff Room | StaffRoomView | Comparison / dossier | Which staff role and judgment matter? |
| 24 | Recruiting Board | RecruitingBoardView | Comparison / board | Which prospect deserves the next resource? |
| 25 | Prospect Profile | ProspectProfileView | Entity dossier | What is known, uncertain, and actionable about this prospect? |
| 26 | Shortlist | ShortlistView | Comparison / queue | Who is retained for follow-up and when? |
| 27 | Contact & Visit Planner | ContactVisitPlannerView | Decision / planner | Which allowable contact action uses the resource? |
| 28 | Class Overview | ClassOverviewView | Comparison / summary | What does the current class solve or leave open? |
| 29 | Signing Day | SigningDayView | Live / event | Which recorded commitments changed the class? |
| 34 | Cap & Contracts | ProManagementView | Constraint / board | Which retained cap constraint needs action? |
| 35 | Contract Negotiation | ContractNegotiationView | Decision / transaction | Which real offer can I make or accept? |
| 36 | Roster Cuts & Transactions | ProManagementView | Decision / comparison | Which roster consequence follows this transaction? |
| 39 | Draft Room | DraftRoomView | Live / event | What is on the clock and which valid action exists? |
| 41 | League Map | LeagueMapView | Spatial / structural | Where does this team sit in the retained world? |
| 42 | Team / Programme Profile | TeamProgrammeProfileView | Entity dossier | What defines this organisation now? |
| 43 | Standings | StandingsView | Comparison / board | Where do teams stand in the controlled competition? |
| 44 | Schedule | ScheduleView | Timeline | What happened and what is next? |
| 45 | Rankings & Playoff Picture | CompetitionOverviewView | Comparison / board | Which retained rankings shape the postseason? |
| 46 | Bracket / Postseason | CompetitionOverviewView | Spatial / structural | How does the retained postseason path connect? |
| 47 | Game Detail / Box Score | GameDetailBoxScoreView | Live result / evidence | What evidence explains this result? |
| 48 | Statistics & Leaders | StatisticsLeadersView | Comparison / board | Who leads the retained statistical categories? |
| 49 | Awards & Honours | AwardsHonoursView | Timeline / evidence | Which honours are actually recorded? |
| 50 | News | NewsView | Timeline / feed | Which current world event matters most? |
| 51 | Realignment Event | RealignmentEventView | Decision / event | What recorded structural change occurred? |
| 52 | Career Hub | CareerHubView | Comparison / opportunity | What is my current career position and real opportunity? |
| 54 | Stakeholders | StakeholdersView | Comparison / evidence | Which retained relationship is changing? |
| 55 | Promotion Decision | PromotionDecisionView | Decision / transaction | What is the real offer, consequence, and commitment? |
| 57 | Record Book | LegacyHistoryView | Comparison / history | Which retained record is authoritative? |
| 58 | Rivalries | LegacyHistoryView | Comparison / history | What retained rivalry history matters? |
| 59 | Career Line | LegacyHistoryView | Timeline / history | How did this coaching career progress? |
| 60 | Coaching Tree | LegacyHistoryView | Spatial / history | Which retained coaching relationships connect? |
| 61 | College Offseason | CollegeOffseasonView | Decision / workbench | Which retention, portal, and NIL obligation is actionable? |
| 62 | Pro Offseason | ProOffseasonView | Decision / workbench | Which market, draft, or roster-building obligation is actionable? |
```

- [ ] **Step 2: Record the 15 alias dispositions**

Add exactly this map and state that aliases are verified routes, not separate layouts:

```markdown
3 Job Board → 52 Career Hub
4 Offer → 52 Career Hub
5 Appointment → 52 Career Hub
21 Staff Market & Profile → 20 Staff Room
22 Scheme Book → 11 Game Plan
23 Personnel Packages → 17 Depth Chart
30 Portal Hub → 61 College Offseason
31 Retention Decisions → 61 College Offseason
32 Portal Market → 61 College Offseason
33 NIL Allocation → 61 College Offseason
37 Pro Scouting Board → 62 Pro Offseason
38 Draft Board → 62 Pro Offseason
40 Free Agency → 62 Pro Offseason
53 Job Security → 52 Career Hub
56 Coaching Carousel → 52 Career Hub
```

- [ ] **Step 3: Add the per-screen evidence and omission columns**

Extend the table with `Existing backing`, `Existing actions`, and `Omitted/deferred`. For each row, name the existing read-model type used by its presentation root and list only callbacks already accepted by that view. Start every omission cell with the global prohibitions: no invented facts, logos, routes, or actions. Then record the fixed family exclusions below wherever the named capability is absent from the current model/callback seam:

```markdown
This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence
Personnel — roster search/filter/new sort, derived ranking, position-specific analysis, invented origin/staff copy, editable development allocation
Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation
Pro Management — cap forecast, trade value, scouting grade, contract demand/probability, unsupported transaction type
League — derived geography, cross-tier scope, probability, media, unsupported event state
Career — forecast, acceptance odds, job recommendation, unrecorded history
Entry — team/logo/record/opponent/family/sibling state before appointment
```

- [ ] **Step 4: Add the proof checklist**

Include unchecked rows for 62-ID/47-canonical coverage, alias resolution, no rail, top navigator, logo uniqueness, action contrast, 844 default and AX5 proof for every canonical destination, seven-family 852/956/Increase Contrast proof, automated accessibility matrix, focused routes, repository lanes, and manual-required device checks.

- [ ] **Step 5: Verify and commit the contract**

Run:

```bash
git diff --check
swift run SimTests --design-contracts
```

Expected: existing tests pass; this task changes documentation only. Run GitNexus `detect_changes`, then:

```bash
git add docs/reviews/2026-08-22-all-screen-presentation-contract.md
git commit -m "docs: map all-screen presentation migration"
```

---

### Task 2: Replace the rail and stacked header with one top navigator

**Files:**

- Modify: `Sources/ProFootballCoachUI/DesignTokens.swift`
- Modify: `Sources/ProFootballCoachUI/FloodlitChrome.swift`
- Modify: `Sources/ProFootballCoachUI/CoachWorldFloodlitComposition.swift`
- Modify: `Sources/ProFootballCoachUI/ScreenRegistry.swift`
- Modify: `Sources/CoachWorldApp/CoachWorldChromeProvider.swift`
- Modify: `Sources/CoachWorldApp/CoachWorldAppRootView.swift`
- Modify: `Sources/ProFootballCoachUI/MatchDayView.swift`
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift`
- Modify: `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift`

**Interfaces:**

- Consumes: `FloodlitChromeReadModel.screen/family/club/record/ranking/conference/context/contextOpponent/siblings/availableScreens`, existing route intents, and `SurfaceRegistryOverlay`.
- Produces: `FloodlitIdentityHeader(model:palette:onNavigate:onOpenRegistry:)`, accessibility identifier `top-navigator`, family button label `Open all tasks, <family>`, and rail-free stage geometry.

- [ ] **Step 1: Run impact analysis before every shared edit**

Run upstream impact with tests for `CoachWorldTokens.Stage`, `FloodlitChromeReadModel`, `FloodlitIdentityHeader`, `FloodlitIconRail`, `CoachWorldFloodlitComposition`, `CoachWorldScreenID.showsIconRail`, `CoachWorldReadModelProvider.rail`, `CoachWorldAppRootView.surface`, `MatchDayView`, `runDesignContractTests`, and the UI-test class. Report HIGH/CRITICAL results before editing.

- [ ] **Step 2: Add failing geometry and source contracts**

Add this suite inside `runDesignContractTests()`:

```swift
suite("One-band top navigator") {
    test("the management frame is rail-free at the install floor") {
        expectEqual(CoachWorldTokens.Stage.contentLeading, 63)
        expectEqual(CoachWorldTokens.Stage.contentTop, 54)
        expectEqual(CoachWorldTokens.Stage.headerTop, 12)
        expectEqual(CoachWorldTokens.Stage.headerHeight, 34)
        expectEqual(CoachWorldTokens.Stage.contentWidth, 761)
    }

    test("no production source retains rail presentation") {
        let source = swiftFilesImportingUIFramework().map(\.text).joined(separator: "\n")
        for retired in ["FloodlitIconRail", "RailEntry", "showsIconRail"] {
            expect(!source.contains(retired), "retired rail source remains: \(retired)")
        }
    }

    test("the header owns registry opening and a stable accessibility hook") {
        let source = swiftFilesImportingUIFramework().map(\.text).joined(separator: "\n")
        expect(source.contains("onOpenRegistry"))
        expect(source.contains("top-navigator"))
        expect(source.contains("Open all tasks,"))
    }
}
```

Run `swift run SimTests --design-contracts`.

Expected: FAIL on old 115/46/3/two-row geometry and retained rail symbols.

- [ ] **Step 3: Collapse stage geometry to the reference values**

Replace the management geometry in `DesignTokens.swift` with:

```swift
public enum Stage {
    public static let contentLeading: CGFloat = Frame.leadingInset       // 63
    public static let headerTop: CGFloat = Frame.topInset               // 12
    public static let headerHeight: CGFloat = 34
    public static let contentTop: CGFloat = headerTop + headerHeight + 8 // 54
    public static let contentWidth: CGFloat =
        Frame.floorWidth - contentLeading - Frame.gutter                // 761
    public static let worldBottomBleed: CGFloat = 0.55
}
```

Delete `railLeading`, `railWidth`, `railTop`, `railGap`, `headerPrimaryRow`, `headerSecondaryRow`, and `railFreeLeading` after the source scan confirms no remaining consumer.

- [ ] **Step 4: Remove rail data and rendering at the root seam**

Delete `FloodlitChromeReadModel.RailEntry`, `rail`, `showsIconRail`, `FloodlitIconRail`, `CoachWorldScreenID.showsIconRail`, and `CoachWorldReadModelProvider.rail`. Remove the `rail:` argument from `FloodlitChromeReadModel` construction. In `CoachWorldFloodlitComposition`, make both layouts use the same leading edge and no rail:

```swift
private var standardLayout: some View {
    ZStack(alignment: .topLeading) {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, CoachWorldTokens.Stage.contentLeading)
            .padding(.trailing, CoachWorldTokens.Frame.gutter)
            .padding(.top, CoachWorldTokens.Stage.contentTop)
            .padding(.bottom, CoachWorldTokens.Frame.bottomInset)
            .accessibilitySortPriority(80)

        FloodlitIdentityHeader(
            model: model,
            palette: palette,
            onNavigate: onNavigate,
            onOpenRegistry: registryOpener
        )
        .frame(width: CoachWorldTokens.Stage.contentWidth, alignment: .leading)
        .padding(.leading, CoachWorldTokens.Stage.contentLeading)
        .padding(.top, CoachWorldTokens.Stage.headerTop)
        .accessibilitySortPriority(100)
    }
}
```

The AX5 `VStack` contains only the same header and the screen content. It does not add a bottom navigator.

- [ ] **Step 5: Build the one-row header**

Replace the current `VStack` header with one `HStack`. Keep the existing logo, record, context opponent, and sibling buttons; move family into a real registry-opening button. Long siblings scroll horizontally:

```swift
struct FloodlitIdentityHeader: View {
    let model: FloodlitChromeReadModel
    let palette: CoachWorldTokens.Palette
    let onNavigate: (CoachWorldIntentID) -> Void
    let onOpenRegistry: () -> Void

    var body: some View {
        HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            identitySection
                .layoutPriority(3)
            Button(action: onOpenRegistry) {
                Label(model.family.canonicalName.uppercased(), systemImage: "chevron.down")
                    .font(CoachWorldTokens.display(10, weight: .bold))
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .padding(.vertical, Chrome.siblingTargetPad)
            .contentShape(Rectangle())
            .padding(.vertical, -Chrome.siblingTargetPad)
            .accessibilityLabel("Open all tasks, \(model.family.canonicalName)")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CoachWorldTokens.Gap.md) {
                    ForEach(model.siblings) { sibling in siblingLink(sibling) }
                }
            }
            .layoutPriority(1)

            Spacer(minLength: CoachWorldTokens.Gap.xs)
            contextSection
                .layoutPriority(2)
        }
        .padding(.horizontal, CoachWorldTokens.Gap.md)
        .frame(height: CoachWorldTokens.Stage.headerHeight)
        .background(headerMaterial)
        .clipShape(CoachWorldCutCorner.headerBand)
        .accessibilityIdentifier("top-navigator")
    }

    private var identitySection: some View {
        HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            CoachWorldTeamLogo(
                team: model.club,
                size: .compact,
                surface: CoachWorldTokens.Floodlit.roomDeep,
                palette: palette
            )
            Text(model.club.name.uppercased())
                .font(CoachWorldTokens.display(15, weight: .bold))
                .lineLimit(1)
            Text(model.ranking.map { "\(model.record) · \($0)" } ?? model.record)
                .font(CoachWorldTokens.figure(11, weight: .semibold))
                .lineLimit(1)
            if let conference = model.conference {
                Text(conference.uppercased())
                    .font(CoachWorldTokens.display(9, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(CoachWorldTokens.Floodlit.clubInk.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(identityLabel)
    }

    @ViewBuilder
    private var contextSection: some View {
        if let context = model.context {
            contextChip(context)
        }
    }

    private var headerMaterial: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: clubField.opacity(0.92), location: 0),
                .init(color: clubField.opacity(0.54), location: 0.5),
                .init(color: clubField.opacity(0.16), location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
```

Retain the existing `identity`, `clubField`, `contextChip(_:)`, and `siblingLink(_:)` implementations. Rename `primaryRowLabel` to `identityLabel` and remove its context phrase because `contextChip(_:)` remains a separate accessible element. The existing positive/negative padding pattern on `siblingLink(_:)` and the family button preserves a 44-point hit region without growing the 34-point visual band or overlapping adjacent controls. At AX5, allow the horizontal content to expand its intrinsic height; do not scale type down.

- [ ] **Step 6: Keep unavailable and Match Day routes inside the shared navigation model**

Make `MatchDayView` conform to `CoachWorldChromedSurface`, add the two defaulted chrome properties used by every other canonical view, and pass them to `CoachWorldFloodlitStage`. Move score/control furniture below `CoachWorldTokens.Stage.contentTop` while leaving the field full bleed.

Wrap the unavailable branch in `CoachWorldAppRootView.surface` with `CoachWorldFloodlitStage(chrome:onNavigate:)` using the requested canonical screen. Preserve `Back to HQ` and route eligibility. Do not create a sample read model.

- [ ] **Step 7: Update the focused production route to use the family navigator**

Replace the rail fallback in `testCoachingHQRosterPlayerProfileVerticalSlice`:

```swift
XCTAssertTrue(app.otherElements["top-navigator"].waitForExistence(timeout: 20))
XCTAssertEqual(
    app.descendants(matching: .any)
        .matching(NSPredicate(format: "label == %@", "Sections")).count,
    0
)
app.buttons["Open all tasks, This week"].tap()
app.buttons["Roster"].tap()
```

Keep the remaining Roster → Player Profile → Roster assertions unchanged.

- [ ] **Step 8: Verify, review, and commit**

Run:

```bash
swift run SimTests --design-contracts
swift run SimTests --core-contracts
./scripts/verify.sh --lane app
```

Run the focused UI test at default and AX5, then `rewrite-tournament` and GitNexus `detect_changes`. Stage the exact Task 2 paths and commit:

```bash
git commit -m "feat: make top chrome the shared navigator"
```

---

### Task 3: Apply system-wide typography, material depth, and team-aware actions

**Files:**

- Modify: `Sources/ProFootballCoachUI/DesignTokens.swift`
- Modify: `Sources/ProFootballCoachUI/TeamIdentity.swift`
- Modify: `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift`
- Modify: `Sources/ProFootballCoachUI/FloodlitPatterns.swift`
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift`

**Interfaces:**

- Consumes: the current `CoachWorldTeamIdentity` contrast resolver and `CoachWorldFloodlitStage.chrome`.
- Produces: `EnvironmentValues.coachWorldTeamIdentity`, globally corrected `DisplaySize`, team-aware `CoachWorldActionButtonStyle`, `CoachWorldRouteButton`, and `FloodlitRow`.

- [ ] **Step 1: Impact the shared symbols**

Run upstream impact with tests for `CoachWorldTokens.DisplaySize`, `CoachWorldTeamIdentity`, `CoachWorldFloodlitStage`, `CoachWorldActionButtonStyle`, `CoachWorldRouteButton`, `FloodlitRow`, `FloodlitCard`, `CoachWorldFloodlitPanelModifier`, `runDesignContractTests`, and `runContractTests`. These are expected shared hubs; report HIGH/CRITICAL results before edits.

- [ ] **Step 2: Add failing typography and team-action contracts**

Add exact size assertions:

```swift
test("the approved all-screen type scale is canonical") {
    expectEqual(CoachWorldTokens.DisplaySize.hero, 32)
    expectEqual(CoachWorldTokens.DisplaySize.name, 26)
    expectEqual(CoachWorldTokens.DisplaySize.score, 32)
    expectEqual(CoachWorldTokens.DisplaySize.figure, 32)
    expectEqual(CoachWorldTokens.DisplaySize.screen, 16)
    expectEqual(CoachWorldTokens.DisplaySize.title, 16)
    expectEqual(CoachWorldTokens.DisplaySize.lead, 15)
    expectEqual(CoachWorldTokens.DisplaySize.panel, 16)
    expectEqual(CoachWorldTokens.DisplaySize.row, 13)
    expectEqual(CoachWorldTokens.DisplaySize.action, 14)
    expectEqual(CoachWorldTokens.DisplaySize.actionSmall, 12)
    expectEqual(CoachWorldTokens.DisplaySize.pill, 10.5)
    expectEqual(CoachWorldTokens.DisplaySize.flag, 9)
}
```

Extend the existing generated-colour tests to assert that readable identities provide 4.5:1 primary-action ink and a 3:1 secondary/selection rule, while malformed and illegible pairs resolve to nil and therefore use fallback furniture.

Run `swift run SimTests --design-contracts` and `swift run SimTests --core-contracts`.

Expected: typography test FAILS on the old 66/60/54/25/20/17/15 scale.

- [ ] **Step 3: Replace the global display values, not 47 local scales**

Use these exact values in `DisplaySize`:

```swift
public static let hero: CGFloat = 32
public static let name: CGFloat = 26
public static let score: CGFloat = 32
public static let situation: CGFloat = 26
public static let scoreLive: CGFloat = 32
public static let figure: CGFloat = 32
public static let screen: CGFloat = 16
public static let title: CGFloat = 16
public static let subject: CGFloat = 16
public static let clock: CGFloat = 17
public static let lead: CGFloat = 15
public static let panel: CGFloat = 16
public static let row: CGFloat = 13
public static let action: CGFloat = 14
public static let actionSmall: CGFloat = 12
public static let pill: CGFloat = 10.5
public static let flag: CGFloat = 9
```

Do not add web fonts. Keep `display` as native condensed system type and `figure` as native tabular digits.

- [ ] **Step 4: Inject resolved team identity once at the stage**

Add one internal environment key in `TeamIdentity.swift`:

```swift
private struct CoachWorldTeamIdentityEnvironmentKey: EnvironmentKey {
    static let defaultValue: CoachWorldTeamIdentity? = nil
}

extension EnvironmentValues {
    var coachWorldTeamIdentity: CoachWorldTeamIdentity? {
        get { self[CoachWorldTeamIdentityEnvironmentKey.self] }
        set { self[CoachWorldTeamIdentityEnvironmentKey.self] = newValue }
    }
}
```

Resolve it in `CoachWorldFloodlitStage` only when `chrome?.club` exists, using `palette.work` behind it and `[palette.contentPrimary, palette.page, CoachWorldTokens.Floodlit.clubInk]` as ink candidates. Apply `.environment(\.coachWorldTeamIdentity, resolvedTeamIdentity)` to the stage root. Teamless entry screens therefore retain nil automatically.

```swift
private var resolvedTeamIdentity: CoachWorldTeamIdentity? {
    guard let club = chrome?.club else { return nil }
    return CoachWorldTeamIdentity(
        team: club,
        behind: palette.work,
        inks: [palette.contentPrimary, palette.page, CoachWorldTokens.Floodlit.clubInk]
    )
}
```

- [ ] **Step 5: Make shared actions and selections consume the environment**

In `CoachWorldActionButtonStyle`, read `@Environment(\.coachWorldTeamIdentity)`. Replace only the current flat `appearance.fill` background with this shared fill; keep the existing pressed opacity, shape, minimum target, disabled state, and role-specific foreground/border handling:

```swift
@Environment(\.coachWorldTeamIdentity) private var teamIdentity

private var primaryField: CoachWorldTokens.ColorValue {
    teamIdentity?.field ?? palette.actionPrimary
}

private var primaryInk: CoachWorldTokens.ColorValue {
    teamIdentity?.onField ?? palette.page
}

private var primaryDepthField: CoachWorldTokens.ColorValue {
    let target = primaryInk.relativeLuminance > primaryField.relativeLuminance
        ? CoachWorldTokens.Floodlit.roomDeep
        : CoachWorldTokens.Floodlit.lamp
    return primaryField.mixed(with: target, amount: 0.12)
}

@ViewBuilder
private var roleFill: some View {
    switch role {
    case .primary:
        LinearGradient(
            colors: [
                primaryDepthField.color,
                primaryField.color,
                primaryDepthField.color,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case .secondary:
        palette.raised.color
    case .live:
        palette.stateLive.color
    case .destructive:
        Color.clear
    }
}
```

Primary ink is `primaryInk`; the depth stop deliberately moves away from that ink, and the generated-colour test must assert both `primaryField` and `primaryDepthField` remain at least 4.5:1 against it. Secondary fill and text remain `palette.raised` and `palette.contentPrimary`; only its border/rule may use `teamIdentity?.selectionRule(on: palette.raised)`. Destructive and live roles remain semantic.

Apply the same environment to `CoachWorldRouteButton` and `FloodlitRow`. Resolve selection against the actual `palette.work` row ground:

```swift
// CoachWorldRouteButton
private var routeSelectionRule: CoachWorldTokens.ColorValue {
    teamIdentity?.selectionRule(on: palette.work)
        ?? selection
        ?? palette.actionPrimary
}

private var routeSelectionTint: CoachWorldTokens.ColorValue {
    teamIdentity?.field ?? selection ?? palette.actionPrimary
}

// FloodlitRow
private var rowSelectionRule: CoachWorldTokens.ColorValue {
    teamIdentity?.selectionRule(on: palette.work) ?? palette.actionPrimary
}

private var rowSelectionTint: CoachWorldTokens.ColorValue {
    teamIdentity?.field ?? palette.actionPrimary
}
```

A selected row receives its resolved tint at 0.10 opacity plus the crisp resolved border/underline, and it retains `.isSelected` so colour is not the only cue. Do not add per-screen colour parameters.

- [ ] **Step 6: Restore deliberate depth centrally**

Keep the existing two `CoachWorldFloodlitPanelDepth` cases. In `CoachWorldFloodlitPanelModifier`, retain the inset sheen and add one depth-dependent shadow:

```swift
.shadow(
    color: .black.opacity(depth == .deep ? 0.55 : 0.28),
    radius: depth == .deep ? 18 : 8,
    x: 0,
    y: depth == .deep ? 10 : 4
)
```

Reduce Transparency continues to replace material, blur, grain, and sheen with opaque fills while preserving the same depth order and borders.

- [ ] **Step 7: Verify, review, and commit**

Run:

```bash
swift run SimTests --design-contracts
swift run SimTests --core-contracts
./scripts/verify.sh --lane accessibility
swift build
```

Run `rewrite-tournament` and GitNexus `detect_changes`. Commit the exact Task 3 paths as:

```bash
git commit -m "feat: apply Floodlit type and team action system"
```

---

### Task 4: Migrate the complete This Week family

**Files:**

- Modify: `Sources/ProFootballCoachUI/CoachingHQView.swift`
- Modify: `Sources/ProFootballCoachUI/InboxView.swift`
- Modify: `Sources/ProFootballCoachUI/OpponentFilmView.swift`
- Modify: `Sources/ProFootballCoachUI/GamePlanView.swift`
- Modify: `Sources/ProFootballCoachUI/PracticePlanView.swift`
- Modify: `Sources/ProFootballCoachUI/TeamHealthView.swift`
- Modify: `Sources/ProFootballCoachUI/MatchDayView.swift`
- Modify: `Sources/ProFootballCoachUI/AftermathView.swift`
- Modify: `Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`
- Modify only for focused assertions: `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift`

**Interfaces:**

- Consumes: existing weekly read models and callbacks; shared shell/type/action/material outputs from Tasks 2–3.
- Produces: corrected canonical IDs 8–15 and 47; no new read-model field.

- [ ] **Step 1: Impact every edited public view and private layout helper**

Run upstream impact for the nine view types and for `CoachingHQView.standardLayout`, `CoachingHQView.accessibleLayout`, `MatchDayView.standardLayout`, `MatchDayView.accessibleLayout`, and each edited helper. Report risk before editing.

- [ ] **Step 2: Reconcile every visible field and callback**

Complete the Task 1 contract rows for IDs 8–15 and 47 before moving layout. Record absent recommendation, countdown, receipt, undo, film, health, or fixture data as omissions; do not fill the composition with sample values.

- [ ] **Step 3: Apply this exact hierarchy**

| Screen | Dominant surface | Supporting order |
|---|---|---|
| HQ | active mandatory decision and explicit commit | evidence/cost → remaining obligations → kickoff → changed health/stakeholders → exact blocker/receipt |
| Inbox | selected consequential message | unread/remaining queue → supported action → chronology |
| Film | opponent evidence or honest unavailable state | tendencies → retained figures → existing plan route |
| Game Plan | current/selected tactical commitment | evidence → choices → explicit commit → exact consequence |
| Practice | current/selected allocation | remaining minutes → sessions → commit/blocker |
| Health | real exceptions first | affected-player evidence → quiet healthy remainder |
| Match Day | score/situation and field | current leverage → five existing controls → interruption/evidence → exit |
| Aftermath | final result | grades → plan evidence → box-score/continue actions |
| Box Score | final score and decisive evidence | ordered retained evidence groups → return route |

Use `.deep` only for the dominant surface and `.glass` for supporting regions. Remove decorative count heroes and routine green “normal” states. Preserve all 22 Match Day actors, recorded commentary, five controls, interruption paths, field direction, line of scrimmage, and first-down line.

- [ ] **Step 4: Verify behavior and route semantics**

Run:

```bash
swift run SimTests --tactical-management
swift run SimTests --tactical-state
swift run SimTests --match-reducer
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Capture IDs 8–15 and 47 at 844 default and AX5. Reject clipping, a missing first action, repeated logos, more than one deep panel, or semantic colour on routine states.

- [ ] **Step 5: Review and commit**

Run `rewrite-tournament` and GitNexus `detect_changes`. Stage only the Task 4 paths and commit `feat: reconcile all weekly command screens`.

---

### Task 5: Migrate the complete Personnel family

**Files:**

- Modify: `Sources/ProFootballCoachUI/RosterView.swift`
- Modify: `Sources/ProFootballCoachUI/DepthChartView.swift`
- Modify: `Sources/ProFootballCoachUI/PlayerProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/DevelopmentPlanView.swift`
- Modify: `Sources/ProFootballCoachUI/StaffRoomView.swift`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`

**Interfaces:**

- Consumes: existing personnel/staff models, sort descriptors, selection, profile/development callbacks, and shared team selection/action environment.
- Produces: corrected canonical IDs 16–20; aliases 21–23 continue to inherit 20/11/17.

- [ ] **Step 1: Impact the public views and selection/sort/layout helpers**

Impact each view plus `RosterView.standardLayout`, `RosterView.rosterRow`, `RosterView.inspectorContent`, `PlayerProfileView.routeBar`, `PlayerProfileView.accessibleLayout`, and edited Depth Chart/Staff/Development helpers.

- [ ] **Step 2: Complete the personnel evidence/omission rows**

Record current role, fit, availability, condition, concern, development, staff judgment, sort, selection, and route backing. Keep roster search, filtering, new sorting, derived rankings, position-specific analysis, invented hometown, invented staff copy, and editable development allocation omitted.

- [ ] **Step 3: Apply this exact hierarchy**

| Screen | Dominant surface | Supporting order |
|---|---|---|
| Roster | 68/32 comparison table and selected dossier | compact genuine-exception ribbon → sortable rows → role/fit/condition/concern/trajectory → one profile route |
| Depth Chart | field/role structure | unit selector → occupied slots → selected role evidence → existing plan action |
| Player Profile | identity and football judgment | position/year/role/availability → smaller 32-point overall → fit/concern/trajectory → evidence routes |
| Development | player trajectory and retained evidence | recent change → plan/evidence → meaningful existing action |
| Staff Room | role comparison and selected staff dossier | staff rows → role/tenure/ratings → retained judgment/action |

Healthy/default states use quiet ink. Team colour identifies selection and primary actions, not every rating. Do not repeat a team-only origin line beneath shared chrome.

- [ ] **Step 4: Verify and commit**

Run:

```bash
swift run SimTests --depth-chart
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Run the HQ → Roster → Player Profile → Roster XCUITest in default and AX5. Capture IDs 16–20. Run `rewrite-tournament`, GitNexus `detect_changes`, and commit `feat: reconcile all personnel screens`.

---

### Task 6: Migrate the complete Recruiting family

**Files:**

- Modify: `Sources/ProFootballCoachUI/RecruitingBoardView.swift`
- Modify: `Sources/ProFootballCoachUI/ProspectProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/ShortlistView.swift`
- Modify: `Sources/ProFootballCoachUI/ContactVisitPlannerView.swift`
- Modify: `Sources/ProFootballCoachUI/ClassOverviewView.swift`
- Modify: `Sources/ProFootballCoachUI/SigningDayView.swift`
- Modify: `Sources/ProFootballCoachUI/CollegeOffseasonView.swift`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`

**Interfaces:**

- Consumes: existing recruiting/college-offseason models, action IDs, costs, consequences, phase gates, and callbacks.
- Produces: corrected canonical IDs 24–29 and 61; aliases 30–33 inherit 61.

- [ ] **Step 1: Impact every public view and edited board/action helper**

Include `RecruitingBoardView.standardLayout`, `RecruitingBoardView.accessibleLayout`, `RecruitingBoardView.comparisonRow`, `ProspectProfileView.dossier`, `ContactVisitPlannerView.actionRow`, and `CollegeOffseasonView.decisionCard`.

- [ ] **Step 2: Complete the recruiting evidence/omission rows**

Record retained certainty, interest, need, contact/visit limits, cost, consequence, commitment, class, portal, retention, and NIL fields. Omit fabricated rankings, scouting reports, countdowns, market rows, recipient allocation, and any action absent from callbacks.

- [ ] **Step 3: Apply this exact hierarchy**

| Screen | Dominant surface | Supporting order |
|---|---|---|
| Recruiting Board | comparable prospect board and selected dossier | class/need exceptions → rows → confidence/evidence → costed action |
| Prospect Profile | known/unknown evidence | identity → ranking/fit/confidence → relationship log → valid actions |
| Shortlist | ordered follow-up queue | prospect rows → next contact → position needs |
| Contact & Visit Planner | valid resource decision | budget → prospect → available actions/cost/consequence |
| Class Overview | class outcome and unresolved needs | commitments → need table → capacity |
| Signing Day | current commitment event | latest retained result → class effect → route onward |
| College Offseason | active retention/portal/NIL obligation | exact resource state → decision → remaining obligations |

Use uncertainty text/symbols with colour, never colour alone. Keep capacity and healthy/default states quiet.

- [ ] **Step 4: Verify and commit**

Run:

```bash
swift run SimTests --portal-contracts
swift run SimTests --career-portal-decisions
swift run SimTests --college-state
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Capture IDs 24–29 and 61 at 844 default/AX5. Run `rewrite-tournament`, GitNexus `detect_changes`, and commit `feat: reconcile all recruiting screens`.

---

### Task 7: Migrate the complete Pro Management family

**Files:**

- Modify: `Sources/ProFootballCoachUI/ProManagementView.swift`
- Modify: `Sources/ProFootballCoachUI/ContractNegotiationView.swift`
- Modify: `Sources/ProFootballCoachUI/DraftRoomView.swift`
- Modify: `Sources/ProFootballCoachUI/ProOffseasonView.swift`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`

**Interfaces:**

- Consumes: existing cap, contract, roster, offer, draft, free-agent, waiver, phase, and action models/callbacks.
- Produces: corrected canonical IDs 34–36, 39, and 62; aliases 37/38/40 inherit 62.

- [ ] **Step 1: Impact all roots and transaction helpers**

Include `ProManagementView.playerRow`, `ProManagementView.actionRow`, `ContractNegotiationView.startRow`, the negotiation card body/actions, `DraftRoomView.body`, and Pro Offseason row/action helpers.

- [ ] **Step 2: Complete the pro evidence/omission rows**

Record exact cap values, eligibility, offer terms, enabled state, phase, cost, consequence, draft order, market and waiver fields. Omit invented cap forecasts, trade value, scouting grades, contract demands, probabilities, and unavailable transaction types.

- [ ] **Step 3: Apply this exact hierarchy**

| Screen | Dominant surface | Supporting order |
|---|---|---|
| Cap & Contracts | binding constraint and comparable contracts | cap exception → rows → selected consequence/action |
| Contract Negotiation | current offer decision | terms → retained rationale/consequence → explicit accept/counter/close callbacks |
| Cuts & Transactions | affected roster row and consequence | constraint → candidates → supported action |
| Draft Room | on-clock state | current selection evidence → existing action → ordered draft context |
| Pro Offseason | active phase obligation | cap/roster state → phase-specific board → valid action → remaining phases |

Use team colour for the controlled club's commitment and selection. Keep league/opponent colours contextual and semantic red exclusively destructive.

- [ ] **Step 4: Verify and commit**

Run:

```bash
swift run SimTests --pro-management
swift run SimTests --pro-market
swift run SimTests --cap-compliance
swift run SimTests --pro-draft-probe
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Capture IDs 34–36, 39, and 62. Run `rewrite-tournament`, GitNexus `detect_changes`, and commit `feat: reconcile all pro management screens`.

---

### Task 8: Migrate the complete League family

**Files:**

- Modify: `Sources/ProFootballCoachUI/WorldSearchView.swift`
- Modify: `Sources/ProFootballCoachUI/LeagueMapView.swift`
- Modify: `Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift`
- Modify: `Sources/ProFootballCoachUI/StandingsView.swift`
- Modify: `Sources/ProFootballCoachUI/ScheduleView.swift`
- Modify: `Sources/ProFootballCoachUI/CompetitionOverviewView.swift`
- Modify: `Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift` only for League-family navigation presentation; its content hierarchy lands in Task 4
- Modify: `Sources/ProFootballCoachUI/StatisticsLeadersView.swift`
- Modify: `Sources/ProFootballCoachUI/AwardsHonoursView.swift`
- Modify: `Sources/ProFootballCoachUI/NewsView.swift`
- Modify: `Sources/ProFootballCoachUI/RealignmentEventView.swift`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`

**Interfaces:**

- Consumes: existing map, organisation, standings, schedule, competition, result, statistics, awards, news, and realignment models/callbacks.
- Produces: corrected canonical IDs 7 and 41–51 without changing tier/route eligibility.

- [ ] **Step 1: Impact every root and layout/sort/group helper**

Include `LeagueMapView.standardLayout`, `LeagueMapView.accessibleLayout`, map marker/layout helpers, standings/schedule row helpers, competition ranking/bracket rows, and all edited list rows.

- [ ] **Step 2: Complete the league evidence/omission rows**

Record retained tier, selection, geography, rivalry, standings, fixture, ranking, bracket, game evidence, statistic, award, news, and realignment fields. Do not derive geography, cross-tier scope, probability, media, or event state the providers do not retain.

- [ ] **Step 3: Apply this exact hierarchy**

| Screen | Dominant surface | Supporting order |
|---|---|---|
| World Search | query/results | scope controls → results → selected real route |
| League Map | map/list orientation | selected place/team → retained facts/rivalries → route |
| Team Profile | organisation identity and judgment | record/form → programme facts → rivals/history |
| Standings | ordered table | competition context → rows → selected-team route |
| Schedule | chronological fixtures | next/most recent → remaining games → selected-team route |
| Rankings | ordered ranking/playoff evidence | current order → context → team route |
| Bracket | connected postseason path | current games → completed/upcoming context |
| Statistics | category leaders | category → ordered rows → team/player identity |
| Awards | latest/most consequential honour | retained chronology → recipient identity |
| News | newest consequential event | remaining feed → real destination |
| Realignment | actual structural change | affected organisations → retained consequence |

Map, bracket, and tree remain spatial objects rather than card grids. Dense tables use tabular figures and quiet defaults.

- [ ] **Step 4: Verify and commit**

Run:

```bash
swift run SimTests --competition-only
swift run SimTests --realignment
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Capture IDs 7 and 41–51. Run `rewrite-tournament`, GitNexus `detect_changes`, and commit `feat: reconcile all league screens`.

---

### Task 9: Migrate the complete Career and Entry families

**Files:**

- Modify: `Sources/ProFootballCoachUI/TitleContinueView.swift`
- Modify: `Sources/ProFootballCoachUI/NewCareerCoachIdentityView.swift`
- Modify: `Sources/ProFootballCoachUI/NewCareerSetupView.swift`
- Modify: `Sources/ProFootballCoachUI/SettingsAccessibilityView.swift`
- Modify: `Sources/ProFootballCoachUI/CareerHubView.swift`
- Modify: `Sources/ProFootballCoachUI/StakeholdersView.swift`
- Modify: `Sources/ProFootballCoachUI/PromotionDecisionView.swift`
- Modify: `Sources/ProFootballCoachUI/LegacyHistoryView.swift`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`

**Interfaces:**

- Consumes: existing title/save, setup/job, settings, career, stakeholder, opportunity, archive, rivalry, career-line, and coaching-tree models/callbacks.
- Produces: corrected canonical IDs 1, 2, 6, 52, 54, 55, and 57–60; aliases 3–5, 53, and 56 inherit canonical presentation.

- [ ] **Step 1: Impact public views and entry/career/history helpers**

Include `NewCareerSetupView.standardLayout`, `NewCareerSetupView.accessibleLayout`, `NewCareerSetupView.submit`, `CareerHubView.body`, and the history focus/selection helpers. Do not change validation or store calls.

- [ ] **Step 2: Complete entry/career evidence and omission rows**

Record exact save/start/job, coach identity, setting, employment, opportunity, stakeholder, archive, rivalry, timeline, and tree backing. Omit invented team identity before appointment, unavailable family routes, forecasts, acceptance odds, job recommendations, and unrecorded history.

- [ ] **Step 3: Apply this exact hierarchy**

| Screen | Dominant surface | Supporting order |
|---|---|---|
| Title | continue/start decision | retained save state → settings route |
| New Career | current required setup step | coach identity → seed/jobs → validation → start action |
| Settings | current preference controls | explanation/effect → return route |
| Career Hub | current role and real opportunities | status → opportunity rows → history → advance/resign where valid |
| Stakeholders | strongest changed relationship | retained evidence → remaining stakeholders |
| Promotion | real professional opportunity | terms/consequence → explicit commit/cancel |
| Record/Rivalries | selected historical evidence | ordered retained rows → scope/focus |
| Career Line | chronological career | latest state → prior jobs/events |
| Coaching Tree | relationship structure | selected node → retained relationship evidence |

Pre-career screens use the same Floodlit material/type/action rules but no fake team logo, record, opponent, family selector, or sibling routes.

- [ ] **Step 4: Verify and commit**

Run:

```bash
swift run SimTests --career-arc
swift run SimTests --history-read-model
swift run SimTests --m7-gate
swift run SimTests --screen-read-models
swift run SimTests --design-contracts
swift build
```

Capture IDs 1, 2, 6, 52, 54, 55, and 57–60. Run `rewrite-tournament`, GitNexus `detect_changes`, and commit `feat: reconcile all career and entry screens`.

---

### Task 10: Make the corrected system canonical in project documentation

**Files:**

- Modify: `docs/04-UX-AND-DESIGN-SYSTEM.md`
- Modify: `docs/04b-AUDIT-RUBRIC.md`
- Modify: `.impeccable.md`
- Modify: `docs/proofs/README.md`
- Modify: `docs/reviews/2026-08-22-all-screen-presentation-contract.md`
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift`

**Interfaces:**

- Consumes: approved spec and implemented token/component values.
- Produces: one non-conflicting design authority for future screens and audits.

- [ ] **Step 1: Add the later-approved amendment to `04`**

Under the Floodlit foundation, state the one-band x63/y12/761×34 geometry, y54 content start, no rail, family registry opener, horizontal siblings, logo uniqueness, type-role table, team-action rules, task archetypes, and 47-canonical/15-alias implementation boundary. Explicitly retain dark-only section 6.1a.

- [ ] **Step 2: Remove stale instructions from `.impeccable.md`**

Replace “Light and dark appearances are equal requirements” with “Floodlit is dark-only; system appearance does not change the register.” Replace the flat/opaque/no-gradient prohibition with the approved existing world lighting, two panel depths, cut corners, restrained grain, and Reduce Transparency fallback. Keep the fictional-identity, 844 × 390, AX5, 44-point, and task-first principles.

- [ ] **Step 3: Update the audit and proof contracts**

Make `04b` and `docs/proofs/README.md` require all 47 canonical default/AX5 proofs, representative family widths, Increase Contrast, Reduce Transparency, Reduce Motion, Differentiate Without Color, real-route semantics, logo uniqueness, and manual-required device checks. Remove stale light-proof authority without deleting historical images in this task.

- [ ] **Step 4: Add a failing-then-green canon sync test**

Run upstream impact for `runDesignContractTests`, reporting any HIGH/CRITICAL result before editing. Then extend `DesignContractTests` to assert `04` contains `content leading 63`, `header height 34`, `content top 54`, the nine type-role values, `47 canonical`, `15 aliases`, `dark-only`, and `CoachWorldTeamIdentity`. Run the test before and after the documentation edit.

- [ ] **Step 5: Verify and commit**

Run `swift run SimTests --design-contracts`, `git diff --check`, GitNexus `detect_changes`, and commit exact paths as `docs: make all-screen UI correction canonical`.

---

### Task 11: Run the 62-ID accessibility and all-canonical visual proof matrix

**Files:**

- Modify: `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift`
- Create: `docs/proofs/all-screen-ui/README.md`
- Create: `docs/proofs/all-screen-ui/844-default/*.png` for canonical IDs `[1,2,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,24,25,26,27,28,29,34,35,36,39,41,42,43,44,45,46,47,48,49,50,51,52,54,55,57,58,59,60,61,62]`
- Create: `docs/proofs/all-screen-ui/844-ax5/*.png` for the same 47 IDs
- Create: `docs/proofs/all-screen-ui/family-representatives/{entry-1,week-8,personnel-16,recruiting-24,pro-34,league-41,career-52}-{852-default,956-default,844-increased-contrast}.png`

**Interfaces:**

- Consumes: DEBUG `PROOF_NEW_CAREER=424242`, `PROOF_SCREEN_NUMBER`, `floodlit-stage`, `top-navigator`, and the existing generated project.
- Produces: reproducible XCTest attachments/PNGs and an honest automated/manual evidence ledger.

- [ ] **Step 1: Impact the UI-test class**

Run upstream impact for `ProFootballCoachUITests`. Its class-level import fan-out may report CRITICAL while production processes remain zero; report and obtain the required authorization before editing.

- [ ] **Step 2: Add the canonical route helper, seven family tests, and alias-route test**

Use the exact canonical IDs above. Add one helper used by seven family tests:

```swift
private func assertCanonicalScreens(_ ids: [Int], ax5: Bool = false) {
    for id in ids {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = String(id)
        if ax5 {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
            ]
        }
        app.launch()

        XCTAssertTrue(app.otherElements["floodlit-stage"].waitForExistence(timeout: 20), "screen \(id)")
        if ![1, 2, 6].contains(id) {
            XCTAssertTrue(app.otherElements["top-navigator"].exists, "screen \(id)")
        }
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Sections")).count,
            0,
            "screen \(id) retained the rail"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = String(format: "screen-%02d-%@", id, ax5 ? "844-ax5" : "844-default")
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
    }
}
```

Split the exact IDs by registry family so one failure names its family. Run each family once for default and once for AX5.

Add one no-screenshot alias test using the same launch seam. It launches all 15 aliases, waits for the shared stage, asserts the canonical family's top-navigator button, and asserts the rail label is absent. The existing core contract already proves each exact alias destination; this UI check proves the compatibility launch path reaches the corrected shell rather than a divergent wrapper.

```swift
private let aliasFamilies: [(id: Int, family: String)] = [
    (3, "Career"), (4, "Career"), (5, "Career"),
    (21, "Personnel"), (22, "This week"), (23, "Personnel"),
    (30, "Recruiting"), (31, "Recruiting"), (32, "Recruiting"), (33, "Recruiting"),
    (37, "Pro management"), (38, "Pro management"), (40, "Pro management"),
    (53, "Career"), (56, "Career"),
]

func testCompatibilityAliasesUseCanonicalShell() {
    for alias in aliasFamilies {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = String(alias.id)
        app.launch()
        XCTAssertTrue(app.otherElements["floodlit-stage"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Open all tasks, \(alias.family)"].exists)
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Sections")).count,
            0
        )
        app.terminate()
    }
}
```

- [ ] **Step 3: Build the accessibility inventory before simulator work**

Run:

```bash
python3 .agents/skills/verify-ios-accessibility-matrix/scripts/build_matrix.py
swift run SimTests --core-contracts
```

Expected: exactly 62 unique numbered families, 7,936 generated cells, no registry/name mismatch, and core contracts pass.

- [ ] **Step 4: Run app, design, and accessibility lanes**

Run:

```bash
./scripts/verify.sh --lane app
./scripts/verify.sh --lane accessibility
swift run SimTests --design-contracts
```

Run the XCUITest family matrix on the 844 × 390 simulator in default and AX5. Run representative IDs `1,8,16,24,34,41,52` on the 852 × 393 and 956 × 440 simulators and at 844 with Increase Contrast.

- [ ] **Step 5: Export and inspect durable evidence**

Export the kept XCTest screenshot attachments from each `.xcresult` with `xcrun xcresulttool export attachments`. Preserve their exact `screen-%02d-*` or representative names under the three proof directories. Rotate framebuffer captures losslessly only when `simctl` stored device portrait; verify every retained PNG has width greater than height and the expected scaled aspect ratio.

Inspect every 844 default/AX5 image and record pass/fail for: upright orientation, top navigator, no rail, first actionable content, one dominant depth, no clipping, logo uniqueness, team-colour action/selection, semantic-state restraint, and honest unavailable state.

- [ ] **Step 6: Record automated and manual evidence separately**

In `docs/proofs/all-screen-ui/README.md`, record exact commands, simulator/device/OS, dimensions, appearance, type size, results, and any unavailable route. Keep VoiceOver spoken clarity/order, Voice Control, Switch Control, sound, haptics, and physical-device checks `manual-required` unless a person records device, OS, tester, and result.

- [ ] **Step 7: Verify and commit proofs**

Run `git diff --check`, GitNexus `detect_changes`, and commit only the UI-test file plus `docs/proofs/all-screen-ui/` as `test: prove all-screen UI migration`.

---

### Task 12: Final adversarial review and shipping gates

**Files:**

- Modify only files containing confirmed fixes from review.
- Modify: `docs/STATUS.md` with exact final results and remaining manual work.

**Interfaces:**

- Consumes: all prior family commits, proof artifacts, omission ledger, and repository gates.
- Produces: verified completion or an explicit blocker report; no optimistic status.

- [ ] **Step 1: Run focused residue checks**

Run:

```bash
test -z "$(rg -l 'FloodlitIconRail|RailEntry|showsIconRail' Sources Tests)"
test -z "$(rg -l 'CoachWorldTokens\.light|Environment\(\\\.colorScheme\)' Sources/ProFootballCoachUI)"
swift run SimTests --design-contracts
swift run SimTests --core-contracts
./scripts/verify.sh --lane accessibility
./scripts/verify.sh --lane app
```

Expected: no rail or light-palette residue and every focused lane passes.

- [ ] **Step 2: Run the full shipping lane**

Run:

```bash
./scripts/verify.sh
```

Do not call the branch ship-ready if this lane fails. Reproduce any failure with the narrowest owning suite and distinguish a new regression from a pre-existing unrelated defect with evidence.

- [ ] **Step 3: Run `confidence-review`**

Investigate every low-confidence area to root cause: header compression and hit overlap, long sibling families, AX5 focus and first action, Match Day top-chrome collision, unavailable-route chrome, alias canonicalization, action ink over generated team colours, low-chroma selection, Reduce Transparency depth, composited contrast over world stripes, logo duplication/announcements, 47-proof completeness, and omitted mock features.

- [ ] **Step 4: Run `rewrite-tournament` for confirmed code fixes**

Run it only on non-trivial functions changed by the final review. Re-run the focused owning tests and full gate after every fix.

- [ ] **Step 5: Run final GitNexus scope review**

Run `detect_changes({scope: "compare", base_ref: "main"})`. Review all affected processes, especially `Career → Snapshot`, route restoration/canonicalization, intent commits, Match Day, and save flows. Expected production effects are presentation and navigation furniture only.

- [ ] **Step 6: Update status and commit confirmed fixes**

Record the exact 62/47 coverage, automated results, proof counts, manual-required checks, and any unrelated blocker in `docs/STATUS.md`. Stage only explicit confirmed-fix paths and status, run `git diff --cached --check`, and commit with a narrow message.

- [ ] **Step 7: Report completion accurately**

Report the shared navigator, all seven family migrations, 47 canonical proofs, 15 alias routes, typography/material/action system, logo preservation, test results, manual checks performed, manual checks still required, and every known blocker. Do not claim device accessibility or shipping readiness without its evidence.
