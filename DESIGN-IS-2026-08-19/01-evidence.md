# Evidence

## Method and current-tree boundary

- The audit covers the current working tree, not the older `be4f13a` snapshot alone. The 62 contiguous registry IDs and their seven families are defined at `Sources/ProFootballCoachUI/ScreenRegistry.swift:34-132`.
- Every corresponding `<Screen>View.swift` file was read. The source-contract lane completed at **219 tests / 2,302 checks**, reporting **62 landed / 0 pending**, **62 Floodlit-converted / 0 pending**, and **1 animating / 61 still** (`Tests/SimTests/Suites/AccessibilityReflowTests.swift:73-227`; `Tests/SimTests/Suites/ReduceMotionContractTests.swift:23-89`).
- Forty retained JPGs were inspected. They show 21 distinct real-career surfaces at the 844 × 390 pt install floor; the other 41 screens are source-only and therefore marked **INFERRED** (`docs/reviews/2026-08-18-floodlit-exhaustive-design-critique.md:15-37`).
- Current uncommitted changes supersede six older defects: the “All 62” control now opens a registry overlay, Settings is reachable in-career, blocked Advance explains itself, staff roles are humanized, roster names relinquish width correctly, and depth-chart field labels abbreviate without losing full spoken names (`Sources/ProFootballCoachUI/CoachWorldFloodlitComposition.swift:44-199`; `Sources/CoachWorldApp/CoachWorldAppRootView.swift:131-136`; `Sources/ProFootballCoachUI/CoachingHQView.swift:220-234,843-890`; `Sources/CoachWorldApp/CoachWorldMatchProvider.swift:314-367`; `Sources/ProFootballCoachUI/RosterView.swift:407-416`; `Sources/ProFootballCoachUI/DepthChartView.swift:158-207`).

## Structural evidence

- **Interactive declarations:** 136 static constructor sites in the shipped SwiftUI graph: **125 `Button`, 2 `Menu`, 1 `Picker`, 7 `TextField`, 1 `Stepper`; 0 gesture-only primary actions**. Runtime multiplicity is data-dependent because `ForEach`, menus, optional branches, the overlay, and Dynamic Type variants expand those declarations. Representative sources: `Sources/ProFootballCoachUI/TitleContinueView.swift:1-102`, `CoachingHQView.swift:1-952`, `MatchDayView.swift:1-1018`, `RecruitingBoardView.swift:1-901`, `LeagueMapView.swift:1-763`, and `CareerHubView.swift:1-351`.
- **Repeated patterns:** 29 `FloodlitCommittingAction` call sites plus one Match Day committing action; 20 interactive `FloodlitRow` sites; 4 interactive `FloodlitPill` sites; 4 `CoachWorldRouteButton` sites; 7 shared rail buttons; family-derived sibling buttons; and 62 destination buttons in the registry overlay (`Sources/ProFootballCoachUI/FloodlitPatterns.swift:53-105,303-356,450-472`; `CoachWorldDeskComponents.swift:326-367`; `FloodlitChrome.swift:403-448,500-567`; `CoachWorldFloodlitComposition.swift:134-199`).
- **Route/task mismatch:** the active-career switch has 58 explicit screen arms. Player Profile has no independent root arm and is a Roster sheet; the root default also carries Coaching HQ (`Sources/CoachWorldApp/CoachWorldAppRootView.swift:85-981,1054-1241`; `Sources/ProFootballCoachUI/RosterView.swift:71-72`).
- **Host reuse:** 28 registry entries reuse ten host compositions. Reuse is useful where the host changes the task, but at least 17 destinations are title-only or near-title-only variations that do not expose the named task: Job Board, Offer, Staff Market, Scheme Book, Personnel Packages, Portal Hub, Retention Decisions, Portal Market, NIL Allocation, Roster Cuts, Pro Scouting, Draft Board, Free Agency, Rankings and Bracket as separate destinations, Job Security, and Coaching Carousel. Exact instances appear in the census below.
- **Dead surface API:** 10 stored properties are not read after initialization: six `onClose` callbacks (`CareerHubView`, `CollegeOffseasonView`, `ScheduleView`, `StandingsView`, `TeamHealthView`, `CompetitionOverviewView`), `NewCareerSetupView.defaultSeed`, and three unused `palette` properties (`FloodlitCard`, `FloodlitFlag`, `FloodlitIdentityHeader`). One import is compiler-probed unused: `Foundation` in `Sources/ProFootballCoachUI/TeamHealthReadModels.swift:1`.
- **Primary-tree depth:** **14 source-declared nodes**. Counting resolves each registry case to its routed root, follows the deepest conditional branch, counts custom views/containers/`Group`/`ForEach`/controls/leaves once, and excludes modifier subtrees and runtime row multiplication. The maximum trace is `RecruitingBoardView → CoachWorldFloodlitStage → VStack → HStack → VStack → ScrollView → VStack → Group → VStack → ForEach → Button → HStack → VStack → Text` (`Sources/CoachWorldApp/CoachWorldAppRootView.swift:202-204`; `Sources/ProFootballCoachUI/RecruitingBoardView.swift:3,60-69,130-136,196-218,404-419,437-447`). Roster and HQ also reach 14. This is not SwiftUI's expanded runtime graph.

## Visual evidence

- **Spacing:** canonical layout/padding values are `[2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20]` pt (`Sources/ProFootballCoachUI/DesignTokens.swift:49-73,159-166`). One layout orphan, `5`, remains in the depth chart (`DepthChartView.swift:439-443`).
- **Type:** the declared fixed scale is `[9, 10.5, 12, 14, 15, 16, 17, 19, 20, 22, 25, 34, 40, 52, 54, 60, 66]` pt (`DesignTokens.swift:117-146`). Seven fixed values sit outside it: `[9.5, 11, 21, 23, 26, 36, 38]` in chrome, score, and field components (`FloodlitChrome.swift:633-650`; `MatchDayScoreBug.swift:226-244`; `MatchDayField.swift:844-851`).
- **Color:** production references **44 distinct static opaque RGB bases**: 14 unique palette bases, 23 Floodlit bases, and 7 direct/system bases; generated team colors are data-dependent and excluded (`DesignTokens.swift:219-346`; `TeamIdentity.swift:9-58`). The number is controlled but not minimal.
- **Visible system:** the 21 live captures consistently show the dark world, identity header, cut-corner geometry, condensed type, rail, and gold committing action. This is a coherent authored system, not orphan styling. Representative regions: `docs/proofs/2026-08-18-exhaustive-critique/07-hq.jpg` full frame, `23-roster.jpg` full frame, `35-matchday.jpg` full frame.
- **Space allocation:** at the install floor the persistent header and rail leave a compact content field; the League Map puts its map and table in an unconstrained vertical stack, so the named dominant object can collapse into a shallow strip (`Sources/ProFootballCoachUI/CoachWorldFloodlitComposition.swift:75-105`; `LeagueMapView.swift:220-230,312-340`; `docs/proofs/2026-08-18-exhaustive-critique/21-map.jpg`, central map region).
- **Action hierarchy:** the gold field is specified as the unique “moves the game forward” treatment (`DesignTokens.swift:339-345`), but noncommitting Done/Continue actions use it on World Search, Prospect Profile, Career Hub, and other read-only surfaces (`WorldSearchView.swift:199-208`; `ProspectProfileView.swift:253-262`; `CareerHubView.swift:303-328`).
- **Contrast:** all canonical opaque text tokens pass 4.5:1. The weakest role pair is `content.quiet` on `world.raised` at **4.61:1**; primary text on raised is **15.49:1** (`DesignTokens.swift:281-291`; WCAG calculation in `TeamIdentity.swift:61-90`). Match Day yard numbers use `field.line.opacity(0.33)` and calculate to **1.44–2.89:1** across declared turf stops, below 3:1 even for large text; the separate shadow was not framebuffer-measured (`MatchDayField.swift:277-300,830-833`).

## Copy and honesty evidence

- **Inflation:** no marketing superlatives or unsupported value claims were found.
- **Dark patterns:** no forced continuity, fake scarcity, confirmshaming, ads, or monetization pressure were found. **Hidden action/cost is present:** generic Continue advances simulation time; Release names dead-money risk but not its amount; Game Plan, Practice Plan, and Depth Chart commit on row selection while footer labels imply commitment happens later (`Sources/CoachWorldApp/CoachWorldAppRootView.swift:93,124,143,509-566,718-934`; `CoachWorldProManagementProvider.swift:31-32`; `Sources/ProFootballCoachUI/GamePlanView.swift:149-152`; `PracticePlanView.swift:150-153`; `DepthChartView.swift:277-280`).
- **Behavioral mismatches:**
  - “Settings & Accessibility” is a read-only capability statement, not a settings surface (`Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:24-43`). It also says every shipped surface supports Reduce Transparency and Differentiate Without Color (`:33-40`), while Match Day/loading retain unguarded materials and source has zero `accessibilityDifferentiateWithoutColor` reads.
  - Game Plan and Practice Plan promise “what … costs,” but their option rows expose consequences without a cost value (`GamePlanView.swift:140-171`; `PracticePlanView.swift:143-170`).
  - “Shortlist” opens a route instead of adding/removing the selected prospect; the Shortlist screen displays all prospects and has no membership state (`RecruitingBoardView.swift:767-773`; `ShortlistView.swift:35-43,101-104`).
  - Contact & Visit Planner is an action list; no day/slot model or calendar is present (`ContactVisitPlannerView.swift:41-44,165-223`).
  - Contract Negotiation styles irreversible Accept as plain text while styling Done as the dominant committing action (`ContractNegotiationView.swift:191-199,322-329,351-356`).
  - Standings labels a `PF–PA` pair “Points”; Schedule prints the `regularSeason` raw enum value (`StandingsView.swift:97-98,188-191`; `Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:110-114`; `ScheduleView.swift:145`).
  - Match Day always displays “HALFTIME · PLAN EDIT,” independent of quarter/state (`MatchDayView.swift:236-245`).
  - “Into the game plan” advances the week instead of routing to Game Plan; four “Back to league”/“League” labels close to Coaching HQ; the overlay presents 62 live buttons although Title, New Career, and Match Day have no generic active-career route (`OpponentFilmView.swift:205`; `Sources/CoachWorldApp/CoachWorldAppRootView.swift:143,1054-1245`; `TeamProgrammeProfileView.swift:283`; `StatisticsLeadersView.swift:113`; `AwardsHonoursView.swift:114`; `NewsView.swift:151`; `RealignmentEventView.swift:28`; `CoachWorldFloodlitComposition.swift:165-190`).
- **Jargon/plain replacements:** `regularSeason` → “Regular season”; “observer-scoped film” → “film reviewed by your staff”; “NIL allocation” should be paired with “player payments” in onboarding copy; `PF–PA` should be labeled “Points for–against.” The current product otherwise uses direct football language.
- **String inventory:** a source-level ledger of static user-facing expressions and accessibility copy is appended at `#user-facing-string-ledger`. Dynamic names, values, and sentences are listed by expression rather than by every runtime expansion.

## Weight and friction evidence

- **Initial JavaScript:** **0 bytes / N/A**. This is native SwiftUI with no WebKit or JavaScriptCore (`App/ProFootballCoachApp.swift:1-20`; `Package.swift:1-48`).
- **Native size proxy:** Release simulator `.app` 56,544 KiB allocated; universal executable 57,890,896 bytes; arm64 slice 28,727,376 bytes; arm64 `__TEXT` 8,929,280 bytes. These are simulator proxies, not App Store transfer size.
- **Initial network:** **0 observed requests** on clean cold launch; source contains no production networking API or URL literal. Saves restore locally (`Sources/CoachWorldApp/CoachWorldSaveStore.swift:1-280`).
- **TTI:** **estimated 700 ±100 ms**, measured at 10 Hz from launch animation onset to the first frame with both enabled title actions. It is not an Instruments/signpost measurement.
- **Idle animation:** **0** on the initial screen. Product-wide indefinite motion has one path: Match Day’s live dot, suppressed by Reduce Motion (`Sources/ProFootballCoachUI/CoachWorldMotion.swift:62-79`; `MatchDayScoreBug.swift:430-465`).
- **Initial attention load:** **0 notifications, 0 badges, 0 modals**; exactly two enabled actions. The 62-screen registry is progressive disclosure (`TitleContinueView.swift:24-72`; `CoachWorldFloodlitComposition.swift:44-66`).
- **Appearance/motion:** the product intentionally fixes Floodlit dark appearance (`Sources/CoachWorldApp/CoachWorldAppRootView.swift:75-76`) and shared animation paths suppress travel, pulse, and playback under Reduce Motion (`CoachWorldMotion.swift:25-105`; `MatchDayView.swift:430-544`).

## Accessibility evidence

- **Contrast per text role:** `content.primary` 18.90/18.27/15.49, `content.secondary` 10.00/9.67/8.20, `content.quiet` 5.62/5.43/4.61, `action.primary` 12.55/12.14/10.29, `action.destructive` 5.67/5.48/4.64, `state.positive` 10.13/9.79/8.30, and `state.info` 7.84/7.58/6.43 on page/work/raised. All pass 4.5:1; Match Day yard-number opacity is the measured exception (`DesignTokens.swift:281-291`; `MatchDayField.swift:277-300,830-833`).
- **Declared focus order:** common shell header `100` → content `80` → rail `40`, overlay `200`; HQ decision `90` → agenda `70` → support/actions `60` → world controls `50` → schedule `30`; Match Day score `100` → controls/interruption `95/90/85` → field `80` (`CoachWorldFloodlitComposition.swift:75-131,134-199`; `CoachingHQView.swift:252-562`; `MatchDayView.swift:200-487`).
- **Order defects:** New Career declares identity fields, Cancel, and Start Career at priority 300 before job choices at 200; League Map places its filter after the map/list it filters (`NewCareerSetupView.swift:74-148`; `LeagueMapView.swift:220-230`).
- **Reachability:** every primary action class is native `Button`, `Menu`, `TextField`, `Picker`, or `Stepper`; zero gesture-only primary actions were found. Native keyboard/Switch reachability is therefore present by source, but Full Keyboard Access and Switch Control were not run. No custom keyboard commands, focus bindings, headings, or rotors exist.
- **ARIA landmarks:** **0 / native N/A**. **Skip link:** no / native N/A. Native alternatives—headings, rotors, and managed accessibility focus—are also absent.
- **Dynamic Type/VoiceOver:** all 62 direct files declare an AX composition and deterministic sort priority. Source has 137 explicit labels, 2 values, 12 hints, 87 grouping modifiers, 56 decorative-hidden markers, and 21 selected traits. Twenty-nine screen files still use fixed-point display/figure/micro-label fonts; only HQ, Roster, and Recruiting declare `@ScaledMetric`.
- **States:** empty, loading, error, interrupted, delegated, and disabled states exist; success is only a row-level completion pattern, and authored visual/accessibility focus state is missing (`CoachWorldVocabulary.swift:13-78,311-363`; `CoachWorldDeskComponents.swift:255-323`; `FloodlitPatterns.swift:450-490`). Under the required checklist this is **two missing/rough states: success and focus**.
- **Reduce Transparency/Differentiate Without Color:** shared stage/panels branch for Reduce Transparency, but Match Day has unconditional material/grain paths and the loading overlay uses unconditional material. Differentiate Without Color is handled mostly by redundant text/symbols, but has no environment branch (`CoachWorldDeskComponents.swift:115-175,369-399`; `MatchDayView.swift:430-544`; `CoachWorldVocabulary.swift:80-146`).

## Screen-by-screen critique

The table names the strongest current issue. “Host mismatch” means the route exists and is visually coherent, but the host does not materially support the task promised by the route name.

| # | Screen | Current strongest issue |
|---:|---|---|
| 1 | Title / Continue | Minimal and clear; no screen-specific defect overrides the global dark-only constraint. Recovery states are explicit (`TitleContinueView.swift:79-99`). |
| 2 | New Career & Coach Identity | Selection is visually fill-led; the explicit selected state is stronger in accessibility metadata than on glass (`NewCareerSetupView.swift:172-188`). |
| 3 | Job Board | **Host mismatch:** Career Hub falls through to history; no vacancy list or comparison (`JobBoardView.swift:39-42`; `CareerHubView.swift:193-218`). |
| 4 | Offer | **Host mismatch:** no offer terms or response flow (`OfferView.swift:39-42`; `CareerHubView.swift:193-218`). |
| 5 | Appointment | Partial: identity supports the task, but the focus panel still defaults to completed-job history (`AppointmentView.swift:39-42`; `CareerHubView.swift:193-218`). |
| 6 | Settings & Accessibility | Read-only product-contract copy, not settings; its universal support statement exceeds observed implementation (`SettingsAccessibilityView.swift:24-43`). |
| 7 | World Search | Real query/filtering, but dismissive Done uses committing-action hierarchy (`WorldSearchView.swift:35-44,199-208`). |
| 8 | Coaching HQ | Clear weekly command composition; progress denominator shrinks with remaining obligations (`CoachingHQView.swift:252-274`). |
| 9 | Inbox | Useful two-pane reader; “File it” has weak affordance beside dominant Continue (`InboxView.swift:64-75,263-284`). |
| 10 | Opponent Report / Film Room | Honest missing evidence; unavailable film can still be labeled STALE (`OpponentFilmView.swift:39-77,89-109`). |
| 11 | Game Plan | Clear current-plan readout; promised install costs are absent (`GamePlanView.swift:78-113,140-171`). |
| 12 | Practice Plan | Honest weekly total; promised alternate-week costs are absent (`PracticePlanView.swift:68-170`). |
| 13 | Team Health | Worst-first triage is useful; fatigue percentage is paired with an inverse-condition bar without explanation (`TeamHealthView.swift:81-119,201-206`). |
| 14 | Match Day | Strong broadcast hierarchy; low-contrast yard numbers and state-independent “HALFTIME · PLAN EDIT” remain (`MatchDayField.swift:277-300`; `MatchDayView.swift:236-245`). |
| 15 | Aftermath | Winner-first result reads immediately; grade has no prior value/delta (`AftermathView.swift:72-129`). |
| 16 | Roster | Dense sortable table and inspector are strong; all non-Available statuses share one warning treatment (`RosterView.swift:319-537,765-769`). |
| 17 | Depth Chart | Field diagram and list provide two readings; field buttons are accessibility-hidden while only the open group is exposed below (`DepthChartView.swift:108-149,210-229`). |
| 18 | Player Profile | Rich dossier, but registry ID 18 is not independently dispatched and exists only as a Roster sheet (`RosterView.swift:71-72`; `CoachWorldAppRootView.swift:1238-1241`). |
| 19 | Development Plan | Movement grouping is clear; “Since August” lacks season/year context (`DevelopmentPlanView.swift:233-240`). |
| 20 | Staff Room | Selectable staff detail is readable; the panel has no recorded verdict or causal interpretation (`StaffRoomView.swift:83-175`). |
| 21 | Staff Market & Profile | **Host mismatch:** same employed-staff roster, no market candidates/hiring flow (`StaffMarketProfileView.swift:24-25`). |
| 22 | Scheme Book | **Host mismatch:** Game Plan title changes, but no scheme library/comparison (`SchemeBookView.swift:31-37`). |
| 23 | Personnel Packages | **Host mismatch:** Depth Chart title changes, but no package formations/substitutions (`PersonnelPackagesView.swift:31-37`). |
| 24 | Recruiting Board | Dense costed actions are useful; Shortlist navigates instead of mutating membership (`RecruitingBoardView.swift:437-483,767-805`). |
| 25 | Prospect Profile | Evidence and costed actions are strong; nonmutating Done uses the committing treatment (`ProspectProfileView.swift:167-262`). |
| 26 | Shortlist | Search/needs are useful; the view displays all prospects and has no shortlist state (`ShortlistView.swift:35-43,79-104`). |
| 27 | Contact & Visit Planner | Costs/budgets are explicit; it is an action list with no day/slot planner (`ContactVisitPlannerView.swift:41-44,165-223`). |
| 28 | Class Overview | Honest roster-source labeling; whole-roster coverage cannot explain class composition by position (`ClassOverviewView.swift:101-124`). |
| 29 | Signing Day | Honest closed-phase state; active content is still the generic offseason ledger (`SigningDayView.swift:40-57`; `CollegeOffseasonView.swift:73-80`). |
| 30 | Portal Hub | **Host mismatch:** generic offseason ledger, no portal roster/targets (`PortalHubView.swift:30`; `CollegeOffseasonView.swift:73-113`). |
| 31 | Retention Decisions | **Host mismatch:** generic decision column does not isolate retention cases (`RetentionDecisionsView.swift:30`; `CollegeOffseasonView.swift:161-174`). |
| 32 | Portal Market | **Host mismatch:** no candidate market/search (`PortalMarketView.swift:30`; `CollegeOffseasonView.swift:73-113`). |
| 33 | NIL Allocation | **Host mismatch:** aggregate spend, no recipient allocation controls (`NilAllocationView.swift:30`; `CollegeOffseasonView.swift:100-105`). |
| 34 | Cap & Contracts | Cap desk is coherent; route variation cannot isolate contract workflows (`CapContractsView.swift:28`; `ProManagementView.swift:72-186`). |
| 35 | Contract Negotiation | Terms/counters are legible; plain-text Accept is subordinate to committing-style Done (`ContractNegotiationView.swift:191-199,322-356`). |
| 36 | Roster Cuts & Transactions | **Host mismatch:** largest-cap-hits list, no cuts queue or transaction history (`RosterCutsTransactionsView.swift:28`; `ProManagementView.swift:153-186`). |
| 37 | Pro Scouting Board | **Host mismatch:** generic all-market offseason host, no scouting-evidence focus (`ProScoutingBoardView.swift:31`; `ProOffseasonView.swift:131-163`). |
| 38 | Draft Board | **Host mismatch:** generic offseason markets remain; no distinct ranking workflow (`DraftBoardView.swift:31`; `ProOffseasonView.swift:131-163`). |
| 39 | Draft Room | Honest phase gate; active room remains the generic all-market host (`DraftRoomView.swift:35-57`; `ProOffseasonView.swift:131-163`). |
| 40 | Free Agency | **Host mismatch:** title changes while draft/waiver content remains equally present (`FreeAgencyView.swift:31`; `ProOffseasonView.swift:131-163`). |
| 41 | League Map | Accessible list alternative is valuable; unconstrained vertical stack can collapse the map (`LeagueMapView.swift:220-230,312-357`). |
| 42 | Team / Programme Profile | Strong identity/form/rivalry context; draws are classified as losses by Boolean `won` (`TeamProgrammeProfileView.swift:163-190`). |
| 43 | Standings | Dense selectable table works; “Points” labels a PF–PA pair (`StandingsView.swift:97-98,188-191`). |
| 44 | Schedule | Completed/upcoming split is clear; raw `regularSeason` stage can ship (`CoachWorldCompetitionProvider.swift:110-114`; `ScheduleView.swift:145`). |
| 45 | Rankings & Playoff Picture | Context is useful; route does not prioritize rankings over the shared bracket structure (`RankingsPlayoffPictureView.swift:37-40`; `CompetitionOverviewView.swift:58-91`). |
| 46 | Bracket / Postseason | Bracket is present; route does not enlarge/prioritize it over shared rankings (`BracketPostseasonView.swift:37-40`; `CompetitionOverviewView.swift:58-91`). |
| 47 | Game Detail / Box Score | Good causal narrative; no opposing-team totals or conventional box-score table (`GameDetailBoxScoreView.swift:176-196`). |
| 48 | Statistics & Leaders | Rows are scannable; no player/team drill-down (`StatisticsLeadersView.swift:79-104`). |
| 49 | Awards & Honours | Rows communicate award/winner/tier/season; fixed 430 pt archive wastes the remaining landscape width (`AwardsHonoursView.swift:51-56,120-124`). |
| 50 | News | Headlines are simulation-backed; detail pane repeats the headline and has no article body (`NewsView.swift:113-140`). |
| 51 | Realignment Event | Before→after rows are clear; local League navigation duplicates shared chrome (`RealignmentEventView.swift:24-39,58-72`). |
| 52 | Career Hub | General career ledger is coherent; dominant Continue overstates read-only dismissal (`CareerHubView.swift:303-328`). |
| 53 | Job Security | **Host mismatch:** “What the board can see” still shows history, not targets/risk (`JobSecurityView.swift:39-49`; `CareerHubView.swift:193-218`). |
| 54 | Stakeholders | Route-specific support context exists; it restates figures without interpretation (`StakeholdersView.swift:39-49`; `CareerHubView.swift:193-201`). |
| 55 | Promotion Decision | Opportunity terms are meaningful; consequential “Take it” is plain text without committing/confirmation treatment (`CareerHubView.swift:257-300`). |
| 56 | Coaching Carousel | **Host mismatch:** personal history, no league-wide moves or vacancies (`CoachingCarouselView.swift:39-49`; `CareerHubView.swift:193-218`). |
| 57 | Record Book | Dedicated records section exists; visible rows omit date/game context held only in the accessibility label (`LegacyHistoryView.swift:78-105`). |
| 58 | Rivalries | Opponent/origin/meetings are useful; intensity has no visible scale and meetings are not openable (`LegacyHistoryView.swift:109-128`). |
| 59 | Career Line | Dedicated chronology exists; it omits outcomes and transition reasons (`LegacyHistoryView.swift:133-152`). |
| 60 | Coaching Tree | Recorded relationships exist; repeated `↳` in a flat stack cannot express multi-level hierarchy (`LegacyHistoryView.swift:155-170`). |
| 61 | College Offseason | Budgets and waiting decisions make a coherent hub; all scopes share one undifferentiated column (`CollegeOffseasonView.swift:83-174`). |
| 62 | Pro Offseason | All markets remain reachable; every nonempty section shows regardless of phase, weakening focus (`ProOffseasonView.swift:131-163`). |

## Per-principle synthesis facts

- **#1 innovative:** the product combines a context-preserving management shell with a field-scale causal Match Day and a truthful evidence vocabulary; these are refinements of established sports-management/broadcast patterns, not demonstrated category-first interactions (`MatchDayView.swift:200-487`; `CoachWorldFloodlitComposition.swift:75-105`).
- **#2 useful:** the core career week, roster, recruiting, and match tasks have direct controls, but at least 17 named destinations do not materially support their promised task (`#screen-by-screen-critique`).
- **#3 aesthetic:** Floodlit is visibly systematic, but one spacing orphan, seven type-size orphans, 44 static colors, the collapsed map risk, and low-contrast yard numbers exceed minor inconsistency (`#visual-evidence`).
- **#4 understandable:** canonical names and native controls help, but title-only hosts, raw labels, task-order defects, and inconsistent action hierarchy create more than three unclear controls/routes (`#structural-evidence`; `#copy-and-honesty-evidence`; `#accessibility-evidence`).
- **#5 unobtrusive:** initial load is quiet, yet persistent header/rail, strong world treatment, and committing gold used for dismissal compete with dense task content on the install floor (`#visual-evidence`; `#weight-and-friction-evidence`).
- **#6 honest:** there are no dark patterns or marketing inflation, but multiple labels and named destinations do not map 1:1 to behavior (`#copy-and-honesty-evidence`).
- **#7 long-lasting:** the disciplined dark sports register is coherent; glass, glow, grain, oversized condensed display, and dense all-caps micro-labels are multiple contemporary trend markers (`DesignTokens.swift:294-357`; `FloodlitChrome.swift:612-654`).
- **#8 thorough:** all 62 source families have AX and shared-state consideration, but first-class success and focus are missing and 41 screens lack current runtime visual proof (`#visual-evidence`; `#accessibility-evidence`).
- **#9 environmentally friendly:** zero JS, zero launch network, zero initial idle animation, two initial actions, dark appearance, and reduced-motion handling meet the software resource/attention anchor (`#weight-and-friction-evidence`).
- **#10 as little design as possible:** shared primitives reduce code repetition, but duplicate destinations, repeated navigation layers, noncommitting gold actions, and ten dead props show more structure than the tasks earn (`#structural-evidence`; `#screen-by-screen-critique`).

## Known gaps

- Forty-one screens have no current real-career screenshot. Source can prove composition and labels, not clipping, perceived hierarchy, or touch behavior.
- The retained real-career captures predate current uncommitted routing, type, roster, depth-chart, and HQ changes.
- The planned accessibility matrix has 7,936 cells, but its automation status remains `not-run` and manual cells remain `manual-required`; no current VoiceOver tree, Full Keyboard Access, Switch Control, physical-device, Reduce Transparency, or sensor-orientation session was captured.
- TTI is video-estimated; release size is a simulator proxy; no energy/thermal trace or signed thinned IPA was available.
- Generated team colors and translucent/gradient framebuffer contrast were not exhaustively pixel-sampled.
- Component-tree depth is source-declared rather than runtime-expanded; reusable-component internals, modifier-generated subtrees, and `ForEach` row multiplicity are excluded from the 14-node measure.

## User-facing string ledger

The ledger below records every static source expression that directly constructs visible text or accessibility copy in the 62 screen files and shared shell. It is intentionally expression-level: interpolated runtime names/numbers are represented once at their source line.

```text
Sources/ProFootballCoachUI/MatchDayView.swift:189:                    Text(statusMessage)
Sources/ProFootballCoachUI/MatchDayView.swift:237:            furnitureControlButton(.tactics, wide: true, label: "HALFTIME · PLAN EDIT")
Sources/ProFootballCoachUI/MatchDayView.swift:245:            furnitureControlButton(.pause)
Sources/ProFootballCoachUI/MatchDayView.swift:246:            furnitureControlButton(.takeOver)
Sources/ProFootballCoachUI/MatchDayView.swift:258:            Text("\(Int(speedMultiplier))×")
Sources/ProFootballCoachUI/MatchDayView.swift:272:        .accessibilityLabel("Speed, \(Int(speedMultiplier)) times")
Sources/ProFootballCoachUI/MatchDayView.swift:301:    private func furnitureControlButton(
Sources/ProFootballCoachUI/MatchDayView.swift:311:                    Text((label ?? presentation.title).uppercased())
Sources/ProFootballCoachUI/MatchDayView.swift:339:        .accessibilityLabel(label ?? presentation.title)
Sources/ProFootballCoachUI/MatchDayView.swift:367:                    Text(statusMessage)
Sources/ProFootballCoachUI/MatchDayView.swift:375:                        controlButton(control)
Sources/ProFootballCoachUI/MatchDayView.swift:387:                Text("\(model.away.team.abbreviation) \(model.away.score)  ·  "
Sources/ProFootballCoachUI/MatchDayView.swift:390:                Text("\(quarterLabel) · \(clockLabel)")
Sources/ProFootballCoachUI/MatchDayView.swift:394:            Text("\(ordinal(model.situation.down)) & \(model.situation.yardsToGo)"
Sources/ProFootballCoachUI/MatchDayView.swift:408:        .accessibilityLabel(
Sources/ProFootballCoachUI/MatchDayView.swift:682:            .accessibilityLabel(label)
Sources/ProFootballCoachUI/MatchDayView.swift:704:            .accessibilityLabel(
Sources/ProFootballCoachUI/MatchDayView.swift:716:            Text("STAFF CALL-IN")
Sources/ProFootballCoachUI/MatchDayView.swift:725:                    Text(interruption.staff.name)
Sources/ProFootballCoachUI/MatchDayView.swift:727:                    Text(interruption.staff.role)
Sources/ProFootballCoachUI/MatchDayView.swift:732:            Text(interruption.message)
Sources/ProFootballCoachUI/MatchDayView.swift:740:                    interruptionButton(action)
Sources/ProFootballCoachUI/MatchDayView.swift:743:            Text("CALL-IN \(callInFooterCount) · RATE SET BY CONTROL DEPTH")
Sources/ProFootballCoachUI/MatchDayView.swift:767:    private func interruptionButton(
Sources/ProFootballCoachUI/MatchDayView.swift:775:                Text(action.title)
Sources/ProFootballCoachUI/MatchDayView.swift:777:                Text(action.cost)
Sources/ProFootballCoachUI/MatchDayView.swift:794:        .accessibilityLabel(
Sources/ProFootballCoachUI/MatchDayView.swift:801:    private func controlButton(_ control: MatchDayReadModel.ControlState) -> some View {
Sources/ProFootballCoachUI/MatchDayView.swift:816:                Text(presentation.title).font(.caption.weight(.bold))
Sources/ProFootballCoachUI/MatchDayView.swift:817:                if let value = displayedValue { Text(value).font(.caption) }
Sources/ProFootballCoachUI/MatchDayView.swift:823:        .accessibilityLabel(Text(accessibilityLabel))
Sources/ProFootballCoachUI/MatchDayView.swift:831:            Text("STAFF CALL-IN")
Sources/ProFootballCoachUI/MatchDayView.swift:837:                    Text(interruption.staff.name).font(.headline.weight(.black))
Sources/ProFootballCoachUI/MatchDayView.swift:838:                    Text(interruption.staff.role)
Sources/ProFootballCoachUI/MatchDayView.swift:843:            Text(interruption.message)
Sources/ProFootballCoachUI/MatchDayView.swift:846:            Text(interruption.actions.map(\.title).joined(separator: " · "))
Sources/ProFootballCoachUI/MatchDayView.swift:850:                interruptionButton(action)
Sources/ProFootballCoachUI/MatchDayView.swift:863:                .toolbar { Button("Done") { showsEvidence = false } }
Sources/ProFootballCoachUI/ShortlistView.swift:57:                    Text(statusMessage)
Sources/ProFootballCoachUI/ShortlistView.swift:81:            TextField("Name, position or status", text: $query)
Sources/ProFootballCoachUI/ShortlistView.swift:84:                .accessibilityLabel("Filter the board by name, position or status")
Sources/ProFootballCoachUI/ShortlistView.swift:127:                Text("\(prospect.boardRank)")
Sources/ProFootballCoachUI/ShortlistView.swift:136:                    Text(prospect.person.name.uppercased())
Sources/ProFootballCoachUI/ShortlistView.swift:148:                Text(prospect.interest.uppercased())
Sources/ProFootballCoachUI/ShortlistView.swift:155:        .accessibilityLabel(
Sources/ProFootballCoachUI/ShortlistView.swift:171:                    Text("No position need is recorded for this class.")
Sources/ProFootballCoachUI/ShortlistView.swift:193:            Text(need.position.uppercased())
Sources/ProFootballCoachUI/ShortlistView.swift:202:            Text("\(need.committed)/\(need.target)")
Sources/ProFootballCoachUI/ShortlistView.swift:208:        .accessibilityLabel(
Sources/ProFootballCoachUI/ShortlistView.swift:217:            Text("The board in your own order. Nothing here ranks the class for you.")
Sources/ProFootballCoachUI/StaffRoomView.swift:46:                    Text(statusMessage)
Sources/ProFootballCoachUI/StaffRoomView.swift:99:                            Text(row.name.uppercased())
Sources/ProFootballCoachUI/StaffRoomView.swift:116:                .accessibilityLabel(
Sources/ProFootballCoachUI/StaffRoomView.swift:132:        return Text(initials.uppercased())
Sources/ProFootballCoachUI/StaffRoomView.swift:151:                    Text(row.name.uppercased())
Sources/ProFootballCoachUI/StaffRoomView.swift:158:                    Text(tenure(row))
Sources/ProFootballCoachUI/StaffRoomView.swift:168:                    Text("No staff verdict is recorded for this coach yet.")
Sources/ProFootballCoachUI/StaffRoomView.swift:190:            Text("\(value)")
Sources/ProFootballCoachUI/StaffRoomView.swift:197:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/StaffRoomView.swift:210:            Text("These are the people who carry the week when you are not in the room.")
Sources/ProFootballCoachUI/FloodlitChrome.swift:341:            Text(model.club.name.uppercased())
Sources/ProFootballCoachUI/FloodlitChrome.swift:346:            Text(model.ranking.map { "\(model.record) · \($0)" } ?? model.record)
Sources/ProFootballCoachUI/FloodlitChrome.swift:351:                Text(conference.uppercased())
Sources/ProFootballCoachUI/FloodlitChrome.swift:367:        .accessibilityLabel(primaryRowLabel)
Sources/ProFootballCoachUI/FloodlitChrome.swift:386:            Text(context.uppercased())
Sources/ProFootballCoachUI/FloodlitChrome.swift:405:            Text(model.family.canonicalName.uppercased())
Sources/ProFootballCoachUI/FloodlitChrome.swift:421:            Text(sibling.title.uppercased())
Sources/ProFootballCoachUI/FloodlitChrome.swift:446:        .accessibilityLabel(sibling.accessibleTitle)
Sources/ProFootballCoachUI/FloodlitChrome.swift:512:                    ForEach(entries) { entry in railButton(entry) }
Sources/ProFootballCoachUI/FloodlitChrome.swift:517:                        ForEach(entries) { entry in railButton(entry) }
Sources/ProFootballCoachUI/FloodlitChrome.swift:522:        .accessibilityLabel("Sections")
Sources/ProFootballCoachUI/FloodlitChrome.swift:525:    private func railButton(_ entry: FloodlitChromeReadModel.RailEntry) -> some View {
Sources/ProFootballCoachUI/FloodlitChrome.swift:538:                Text(entry.label.uppercased())
Sources/ProFootballCoachUI/FloodlitChrome.swift:564:        .accessibilityLabel(entry.label)
Sources/ProFootballCoachUI/FloodlitChrome.swift:591:            Text(needs)
Sources/ProFootballCoachUI/FloodlitChrome.swift:606:        .accessibilityLabel("\(screen.canonicalName). Registered, not built. \(needs)")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:36:                    Text(statusMessage).foregroundStyle(palette.stateWarning.color)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:52:            Button("History", action: onClose)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:56:                Text(focus.canonicalName).font(CoachWorldTokens.TypeRole.headline.weight(.black))
Sources/ProFootballCoachUI/LegacyHistoryView.swift:57:                Text(model.team.name + " · " + model.seasonLabel)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:62:            Menu("Views") {
Sources/ProFootballCoachUI/LegacyHistoryView.swift:63:                Button("Record book") { onNavigate(.recordBook) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:64:                Button("Rivalries") { onNavigate(.rivalries) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:65:                Button("Career line") { onNavigate(.careerLine) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:66:                Button("Coaching tree") { onNavigate(.coachingTree) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:67:                Button("Statistics & leaders") { onNavigate(.statisticsLeaders) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:68:                Button("Awards & honours") { onNavigate(.awardsHonours) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:69:                Button("Realignment event") { onNavigate(.realignmentEvent) }
Sources/ProFootballCoachUI/LegacyHistoryView.swift:90:            Text("Durable records").font(CoachWorldTokens.TypeRole.headline.weight(.black))
Sources/ProFootballCoachUI/LegacyHistoryView.swift:96:                    Text(row.title).frame(maxWidth: .infinity, alignment: .leading)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:97:                    Text(String(row.value)).monospacedDigit().fontWeight(.bold)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:98:                    Text(row.team.name + " vs " + row.opponent.name)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:104:                .accessibilityLabel("\(row.title), \(row.value), \(row.team.name) versus \(row.opponent.name), \(row.gameLabel)")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:111:            Text("Rivalries").font(CoachWorldTokens.TypeRole.headline.weight(.black))
Sources/ProFootballCoachUI/LegacyHistoryView.swift:118:                        Text(row.opponent.name).fontWeight(.bold)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:119:                        Text(row.origin + " · " + String(row.meetings.count) + " notable meetings")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:124:                    Text(String(row.intensity)).monospacedDigit()
Sources/ProFootballCoachUI/LegacyHistoryView.swift:128:                .accessibilityLabel("Rivalry with \(row.opponent.name), \(row.origin), intensity \(row.intensity), \(row.meetings.count) notable meetings")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:135:            Text("Career line").font(CoachWorldTokens.TypeRole.headline.weight(.black))
Sources/ProFootballCoachUI/LegacyHistoryView.swift:141:                    Text("Season \(row.season)").monospacedDigit().frame(width: 105, alignment: .leading)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:142:                    Text(row.role).frame(maxWidth: .infinity, alignment: .leading)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:143:                    Text(row.organisation.name).foregroundStyle(palette.contentSecondary.color)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:147:                .accessibilityLabel("Season \(row.season), \(row.role), \(row.organisation.name)")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:157:            Text("Coaching tree").font(CoachWorldTokens.TypeRole.headline.weight(.black))
Sources/ProFootballCoachUI/LegacyHistoryView.swift:163:                    Text(branch.mentorName).fontWeight(.bold)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:165:                        Text("↳ " + disciple).font(CoachWorldTokens.TypeRole.caption)
Sources/ProFootballCoachUI/LegacyHistoryView.swift:170:                .accessibilityLabel("Mentor \(branch.mentorName), \(branch.disciples.joined(separator: ", "))")
Sources/ProFootballCoachUI/GamePlanView.swift:54:                    Text(statusMessage)
Sources/ProFootballCoachUI/GamePlanView.swift:105:                Text(value.uppercased())
Sources/ProFootballCoachUI/GamePlanView.swift:113:        .accessibilityLabel("\(slot), \(value)")
Sources/ProFootballCoachUI/GamePlanView.swift:155:                        Text(option.title.uppercased())
Sources/ProFootballCoachUI/GamePlanView.swift:165:                        Text(option.consequence)
Sources/ProFootballCoachUI/GamePlanView.swift:171:                .accessibilityLabel("\(option.title). \(option.consequence)")
Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:28:                    Text("SETTINGS & ACCESSIBILITY")
Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:30:                    Text("BETA PRODUCT CONTRACT")
Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:33:                    Text("English-only beta · landscape play · silent product")
Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:35:                    Text("No audio, haptics, account, network, analytics, advertising, or in-app purchase channels are used.")
Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:38:                    Text("VoiceOver, Dynamic Type, Bold Text, Increase Contrast, Reduce Transparency, Differentiate Without Color, and Reduce Motion are supported by each shipped surface.")
Sources/ProFootballCoachUI/SettingsAccessibilityView.swift:41:                    Button("Done", action: onClose)
Sources/ProFootballCoachUI/CareerHubView.swift:61:                    Text(statusMessage)
Sources/ProFootballCoachUI/CareerHubView.swift:90:            Text(model.coach.name.uppercased())
Sources/ProFootballCoachUI/CareerHubView.swift:125:            Text(value)
Sources/ProFootballCoachUI/CareerHubView.swift:139:        .accessibilityLabel("\(key), \(value)")
Sources/ProFootballCoachUI/CareerHubView.swift:148:                Text("No support is recorded yet.")
Sources/ProFootballCoachUI/CareerHubView.swift:162:                            Text(row.stakeholder.uppercased())
Sources/ProFootballCoachUI/CareerHubView.swift:169:                            Text("\(row.value) of \(CareerMetric.supportCeiling)")
Sources/ProFootballCoachUI/CareerHubView.swift:177:                    .accessibilityLabel(
Sources/ProFootballCoachUI/CareerHubView.swift:195:                    Text(
Sources/ProFootballCoachUI/CareerHubView.swift:224:            Text("No completed appointment is on record yet.")
Sources/ProFootballCoachUI/CareerHubView.swift:231:                    Text(row.team.name.uppercased())
Sources/ProFootballCoachUI/CareerHubView.swift:238:                    Text(historyLine(row))
Sources/ProFootballCoachUI/CareerHubView.swift:245:                .accessibilityLabel("\(row.team.name). \(historyLine(row))")
Sources/ProFootballCoachUI/CareerHubView.swift:261:            Text("No offer is currently on the table.")
Sources/ProFootballCoachUI/CareerHubView.swift:268:                    Text(opportunity.team.name.uppercased())
Sources/ProFootballCoachUI/CareerHubView.swift:282:                        Button("Take it") { onAcceptOpportunity(opportunity.id) }
Sources/ProFootballCoachUI/CareerHubView.swift:292:                        Text(reason)
Sources/ProFootballCoachUI/CareerHubView.swift:307:            Text(footerNote)
Sources/ProFootballCoachUI/CareerHubView.swift:313:                Button("Resign", action: onResign)
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:53:                    Text(statusMessage)
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:115:                Text("\(row.rank)")
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:125:                Text(row.team.name.uppercased())
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:134:                Text(row.record)
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:158:        .accessibilityLabel(
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:200:            Text(game.week.uppercased())
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:206:                Text(game.away.name.uppercased())
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:213:                Text("at \(game.home.name)".uppercased())
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:219:            Text(game.score ?? "to play")
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:231:        .accessibilityLabel(
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:239:            Text("The field as it stands. Nobody is projected into a round they have not reached.")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:76:            Text("New career")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:78:            Text("Create a coach identity and choose the first appointment.")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:82:            TextField("First name", text: $firstName)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:84:                .accessibilityLabel("Coach first name")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:85:            TextField("Last name", text: $lastName)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:87:                .accessibilityLabel("Coach last name")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:88:            TextField("World seed", text: $seedText, onCommit: refreshJobsForSeed)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:90:                .accessibilityLabel("World seed")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:92:                Text("Press return to refresh the starting jobs for this seed.")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:99:                Text(errorMessage)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:106:                Button("Cancel", action: onCancel)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:109:                Button("Start career") { submit() }
Sources/ProFootballCoachUI/NewCareerSetupView.swift:126:            Text("Starting jobs")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:128:            Text("Three generated openings. Expectations and resources come from the selected programme.")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:157:                    Text(job.programme.name)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:160:                    Text(job.cityName)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:163:                Text("Prestige \(job.prestige) · Resources \(job.resources) · \(job.expectation)")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:166:                Text(job.archetype)
Sources/ProFootballCoachUI/NewCareerSetupView.swift:182:        .accessibilityLabel("\(job.programme.name), \(job.cityName)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:34:        Text(text.uppercased())
Sources/ProFootballCoachUI/FloodlitPatterns.swift:45:            .accessibilityLabel(text)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:73:            Button(action: action) { body(for: true) }
Sources/ProFootballCoachUI/FloodlitPatterns.swift:178:                Text(figure)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:185:        .accessibilityLabel("\(caption), \(figure)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:253:                Text("\(rating)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:266:        .accessibilityLabel("\(title), \(rating) out of \(CoachWorldTokens.Heat.scaleCeiling)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:323:            Button(action: action) { label }
Sources/ProFootballCoachUI/FloodlitPatterns.swift:332:        Text(title.uppercased())
Sources/ProFootballCoachUI/FloodlitPatterns.swift:354:            .accessibilityLabel(title)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:376:        Text(title.uppercased())
Sources/ProFootballCoachUI/FloodlitPatterns.swift:386:            .accessibilityLabel(title)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:422:            Text(monogram)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:436:                Text("\u{201C}\(advice)\u{201D}")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:440:                Text("\u{2014} \(staff.name), \(staff.role)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:446:        .accessibilityLabel("\(staff.name), \(staff.role), says: \(advice)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:500:            Text([cost, exposure].compactMap { $0 }.joined(separator: " · ").uppercased())
Sources/ProFootballCoachUI/FloodlitPatterns.swift:507:                Text(consequence)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:514:        .accessibilityLabel(
Sources/ProFootballCoachUI/FloodlitPatterns.swift:629:        Text(text.uppercased())
Sources/ProFootballCoachUI/FloodlitPatterns.swift:643:            .accessibilityLabel("Confidence: \(text)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:71:            Button(action: onClose) {
Sources/ProFootballCoachUI/PlayerProfileView.swift:72:                Text("Back to personnel")
Sources/ProFootballCoachUI/PlayerProfileView.swift:102:                        Text(model.person.name)
Sources/ProFootballCoachUI/PlayerProfileView.swift:113:                Text(statusLine)
Sources/ProFootballCoachUI/PlayerProfileView.swift:152:                    Text("\(attribute.value)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:161:                .accessibilityLabel(
Sources/ProFootballCoachUI/PlayerProfileView.swift:184:                    Text(routeMeta)
Sources/ProFootballCoachUI/PlayerProfileView.swift:276:            Text(text)
Sources/ProFootballCoachUI/PlayerProfileView.swift:287:                Text("\(value)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:300:        .accessibilityLabel("\(key), \(text)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:307:        Text(text.isEmpty ? "No staff evidence recorded yet." : text)
Sources/ProFootballCoachUI/PlayerProfileView.swift:327:        Text("\(model.number)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:336:            .accessibilityLabel("\(team.name), number \(model.number)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:360:        .accessibilityLabel(identityAccessibilityLabel)
Sources/ProFootballCoachUI/ScheduleView.swift:48:                    Text(statusMessage)
Sources/ProFootballCoachUI/ScheduleView.swift:120:                Text(game.week.uppercased())
Sources/ProFootballCoachUI/ScheduleView.swift:128:                    Text(game.away.name.uppercased())
Sources/ProFootballCoachUI/ScheduleView.swift:135:                    Text("at \(game.home.name)".uppercased())
Sources/ProFootballCoachUI/ScheduleView.swift:145:                Text(game.score ?? game.stage)
Sources/ProFootballCoachUI/ScheduleView.swift:172:        .accessibilityLabel(
Sources/ProFootballCoachUI/ScheduleView.swift:181:            Text("Home and away are as scheduled. Nothing here is a prediction.")
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:77:            Text(side.team.name.uppercased())
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:85:                Text(subline)
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:91:            Text("\(side.score)")
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:107:        .accessibilityLabel("\(side.team.name), \(side.score)")
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:127:                            Text(grade.position.uppercased())
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:143:                                Text(grade.player.name.uppercased())
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:150:                                Text(grade.evidence)
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:156:                            Text("\(grade.rating)")
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:167:                    .accessibilityLabel(
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:206:                Text(row)
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:219:            Text(model.headline)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:65:            Text(kind.message)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:70:                Button(recoveryTitle, action: onRecover)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:128:            Text(text.uppercased())
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:145:        .accessibilityLabel(text)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:177:            Text(value == 0 ? "—" : (value > 0 ? "+\(value)" : "\(value)"))
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:183:        .accessibilityLabel(value == 0 ? "no change" : "\(value > 0 ? "up" : "down") \(abs(value))")
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:232:            Text("\(value)")
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:243:        .accessibilityLabel("rating \(value)")
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:347:                Text(title)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:350:                Text(timing)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:356:                Text(cost)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:393:                Text(team.name)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:408:            .accessibilityLabel(team.name)
Sources/ProFootballCoachUI/ProOffseasonView.swift:51:                    Text(statusMessage)
Sources/ProFootballCoachUI/ProOffseasonView.swift:100:                .accessibilityLabel(
Sources/ProFootballCoachUI/ProOffseasonView.swift:117:            Text(value)
Sources/ProFootballCoachUI/ProOffseasonView.swift:121:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/ProOffseasonView.swift:172:                Text(prospect.position.uppercased())
Sources/ProFootballCoachUI/ProOffseasonView.swift:177:                Text(prospect.name.uppercased())
Sources/ProFootballCoachUI/ProOffseasonView.swift:181:                Text(prospect.estimatedOverall.map { "\($0)" } ?? "\u{2014}")
Sources/ProFootballCoachUI/ProOffseasonView.swift:189:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProOffseasonView.swift:198:                Text(player.position.uppercased())
Sources/ProFootballCoachUI/ProOffseasonView.swift:203:                Text(player.name.uppercased())
Sources/ProFootballCoachUI/ProOffseasonView.swift:209:        .accessibilityLabel("\(player.name), \(player.position)")
Sources/ProFootballCoachUI/ProOffseasonView.swift:215:                Text(waiver.name.uppercased())
Sources/ProFootballCoachUI/ProOffseasonView.swift:224:        .accessibilityLabel("\(waiver.name), claim deadline \(waiver.deadline)")
Sources/ProFootballCoachUI/ProOffseasonView.swift:235:                    Text("Select a name to see what you can do about it.")
Sources/ProFootballCoachUI/ProOffseasonView.swift:262:                Text(action.title.uppercased())
Sources/ProFootballCoachUI/ProOffseasonView.swift:272:                Text(action.isAvailable ? action.detail : (action.unavailableReason ?? action.detail))
Sources/ProFootballCoachUI/ProOffseasonView.swift:278:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProOffseasonView.swift:287:            Text("Every figure here is recorded. Nothing projects past this phase.")
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:36:                    Text(statusMessage)
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:83:                Text(row.player.name.uppercased())
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:88:            Text(row.team.name)
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:93:            Text("\(row.value)")
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:101:        .accessibilityLabel(
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:108:            Text("Season totals to date. Nobody is projected forward.")
Sources/ProFootballCoachUI/ContractNegotiationView.swift:50:                    Text(statusMessage)
Sources/ProFootballCoachUI/ContractNegotiationView.swift:55:                Text(
Sources/ProFootballCoachUI/ContractNegotiationView.swift:150:                        Text(player.name.uppercased())
Sources/ProFootballCoachUI/ContractNegotiationView.swift:158:                            Text("\(currency(player.capHit)) now")
Sources/ProFootballCoachUI/ContractNegotiationView.swift:168:                        Text(player.name.uppercased())
Sources/ProFootballCoachUI/ContractNegotiationView.swift:176:                        Text("\(currency(player.capHit)) now")
Sources/ProFootballCoachUI/ContractNegotiationView.swift:185:            .accessibilityLabel(
Sources/ProFootballCoachUI/ContractNegotiationView.swift:193:            Text("Every offer here is retained. Nothing is committed until you accept it.")
Sources/ProFootballCoachUI/ContractNegotiationView.swift:243:                    Text(negotiation.playerName.uppercased())
Sources/ProFootballCoachUI/ContractNegotiationView.swift:260:                .accessibilityLabel(
Sources/ProFootballCoachUI/ContractNegotiationView.swift:277:                        TextField("Annual base salary", value: $baseSalary, format: .number)
Sources/ProFootballCoachUI/ContractNegotiationView.swift:280:                        TextField("Signing bonus", value: $signingBonus, format: .number)
Sources/ProFootballCoachUI/ContractNegotiationView.swift:290:                                quietButton("Withdraw") {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:293:                                quietButton("Reject") {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:298:                                quietButton("Counter") {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:310:                            quietButton("Withdraw") {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:313:                            quietButton("Reject") {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:317:                            quietButton("Counter") {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:343:    private func quietButton(_ title: String, action: @escaping () -> Void) -> some View {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:344:        Button(title, action: action)
Sources/ProFootballCoachUI/ContractNegotiationView.swift:351:    private func acceptButton(action: @escaping () -> Void) -> some View {
Sources/ProFootballCoachUI/ContractNegotiationView.swift:352:        Button("Accept", action: action)
Sources/ProFootballCoachUI/InboxView.swift:51:                    Text(statusMessage)
Sources/ProFootballCoachUI/InboxView.swift:88:                Button(action: onClose) {
Sources/ProFootballCoachUI/InboxView.swift:89:                    Text("\u{2190} Back")
Sources/ProFootballCoachUI/InboxView.swift:137:                        Text(tag(for: item).uppercased())
Sources/ProFootballCoachUI/InboxView.swift:153:                            Text(item.title)
Sources/ProFootballCoachUI/InboxView.swift:166:                            Text(item.sourceLabel.uppercased())
Sources/ProFootballCoachUI/InboxView.swift:184:                .accessibilityLabel(
Sources/ProFootballCoachUI/InboxView.swift:203:                    Text(item.title)
Sources/ProFootballCoachUI/InboxView.swift:210:                    Text(item.body)
Sources/ProFootballCoachUI/InboxView.swift:225:                            Text("Open the \(destination.navigationName.lowercased())")
Sources/ProFootballCoachUI/InboxView.swift:269:                Button("File it") { onRead(item.stableID) }
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:46:                    Text(statusMessage)
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:96:            Text(value)
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:100:        .accessibilityLabel("\(label), \(value) left")
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:126:                    Text(prospect.person.name.uppercased())
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:141:                    Text(prospect.person.name.uppercased())
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:177:            let title = Text(choice.title.uppercased())
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:196:                    Text(choice.unavailableReason ?? "Not available this week.")
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:218:        .accessibilityLabel(
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:228:            Text("Every booking spends from the week. The planner never picks for you.")
Sources/ProFootballCoachUI/ProManagementView.swift:50:                    Text(statusMessage)
Sources/ProFootballCoachUI/ProManagementView.swift:82:                Text(currency(model.cap.remainingCap))
Sources/ProFootballCoachUI/ProManagementView.swift:85:                Text(model.cap.remainingCap >= 0 ? "Under the cap" : "Over the cap")
Sources/ProFootballCoachUI/ProManagementView.swift:94:            .accessibilityLabel(
Sources/ProFootballCoachUI/ProManagementView.swift:112:                    Text("\(model.cap.activeRosterCount)/\(ProRules.activeRosterLimit) active")
Sources/ProFootballCoachUI/ProManagementView.swift:115:                    Text("\(model.cap.practiceSquadCount)/\(ProRules.practiceSquadLimit) practice")
Sources/ProFootballCoachUI/ProManagementView.swift:138:            Text(value)
Sources/ProFootballCoachUI/ProManagementView.swift:150:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/ProManagementView.swift:197:                    Text(player.name.uppercased())
Sources/ProFootballCoachUI/ProManagementView.swift:208:                    Text(contract.years == 1 ? "1 yr" : "\(contract.years) yrs")
Sources/ProFootballCoachUI/ProManagementView.swift:213:                Text(currency(player.capHit))
Sources/ProFootballCoachUI/ProManagementView.swift:218:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProManagementView.swift:233:                Text(action.title.uppercased())
Sources/ProFootballCoachUI/ProManagementView.swift:247:                Text(action.isAvailable ? action.detail : (action.unavailableReason ?? action.detail))
Sources/ProFootballCoachUI/ProManagementView.swift:253:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProManagementView.swift:268:            Text(negotiationNote)
Sources/ProFootballCoachUI/ProManagementView.swift:273:            Button("Done", action: onClose)
Sources/ProFootballCoachUI/CoachingHQView.swift:95:                        Text(model.team.name.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:97:                        Text(accessibleWorldContextLine)
Sources/ProFootballCoachUI/CoachingHQView.swift:102:                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")
Sources/ProFootballCoachUI/CoachingHQView.swift:109:                        Text("COACH'S WORLD")
Sources/ProFootballCoachUI/CoachingHQView.swift:113:                        Text(model.team.name.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:118:                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")
Sources/ProFootballCoachUI/CoachingHQView.swift:152:        Menu("World") {
Sources/ProFootballCoachUI/CoachingHQView.swift:153:            Button("Office") { onNavigate(.coachingHQ) }
Sources/ProFootballCoachUI/CoachingHQView.swift:154:            Button("Settings & accessibility") { onNavigate(.settingsAccessibility) }
Sources/ProFootballCoachUI/CoachingHQView.swift:155:            Button("Inbox") { onNavigate(.inbox) }
Sources/ProFootballCoachUI/CoachingHQView.swift:156:            Button("Film") { onNavigate(.opponentReportFilmRoom) }
Sources/ProFootballCoachUI/CoachingHQView.swift:157:            Button("Team") { onNavigate(.roster) }
Sources/ProFootballCoachUI/CoachingHQView.swift:158:            Button("Recruit") { onNavigate(.recruitingBoard) }
Sources/ProFootballCoachUI/CoachingHQView.swift:159:            Button("League") { onNavigate(.leagueMap) }
Sources/ProFootballCoachUI/CoachingHQView.swift:160:            Button("Career") { onNavigate(.careerHub) }
Sources/ProFootballCoachUI/CoachingHQView.swift:162:                Button("Job board") { onNavigate(.jobBoard) }
Sources/ProFootballCoachUI/CoachingHQView.swift:163:                Button("Offers") { onNavigate(.offer) }
Sources/ProFootballCoachUI/CoachingHQView.swift:164:                Button("Appointment") { onNavigate(.appointment) }
Sources/ProFootballCoachUI/CoachingHQView.swift:166:            Button("News") { onNavigate(.news) }
Sources/ProFootballCoachUI/CoachingHQView.swift:167:            Button("Record book") { onNavigate(.recordBook) }
Sources/ProFootballCoachUI/CoachingHQView.swift:168:            Button("Rivalries") { onNavigate(.rivalries) }
Sources/ProFootballCoachUI/CoachingHQView.swift:169:            Button("Career line") { onNavigate(.careerLine) }
Sources/ProFootballCoachUI/CoachingHQView.swift:170:            Button("Coaching tree") { onNavigate(.coachingTree) }
Sources/ProFootballCoachUI/CoachingHQView.swift:171:            Button("Statistics & leaders") { onNavigate(.statisticsLeaders) }
Sources/ProFootballCoachUI/CoachingHQView.swift:172:            Button("Awards & honours") { onNavigate(.awardsHonours) }
Sources/ProFootballCoachUI/CoachingHQView.swift:173:            Button("Realignment event") { onNavigate(.realignmentEvent) }
Sources/ProFootballCoachUI/CoachingHQView.swift:174:            Button("Search") { onNavigate(.worldSearch) }
Sources/ProFootballCoachUI/CoachingHQView.swift:175:            Button("Game plan") { onNavigate(.gamePlan) }
Sources/ProFootballCoachUI/CoachingHQView.swift:176:            Button("Practice") { onNavigate(.practicePlan) }
Sources/ProFootballCoachUI/CoachingHQView.swift:177:            Button("Depth chart") { onNavigate(.depthChart) }
Sources/ProFootballCoachUI/CoachingHQView.swift:178:            Button("Scheme book") { onNavigate(.schemeBook) }
Sources/ProFootballCoachUI/CoachingHQView.swift:179:            Button("Personnel packages") { onNavigate(.personnelPackages) }
Sources/ProFootballCoachUI/CoachingHQView.swift:180:            Button("Team health") { onNavigate(.teamHealth) }
Sources/ProFootballCoachUI/CoachingHQView.swift:181:            Button("Staff room") { onNavigate(.staffRoom) }
Sources/ProFootballCoachUI/CoachingHQView.swift:182:            Button("Staff market & profile") { onNavigate(.staffMarketProfile) }
Sources/ProFootballCoachUI/CoachingHQView.swift:184:                Button("Pro offseason") { onNavigate(.proOffseason) }
Sources/ProFootballCoachUI/CoachingHQView.swift:185:                Button("Draft board") { onNavigate(.draftBoard) }
Sources/ProFootballCoachUI/CoachingHQView.swift:187:                    Button("Draft room") { onNavigate(.draftRoom) }
Sources/ProFootballCoachUI/CoachingHQView.swift:189:                Button("Free agency") { onNavigate(.freeAgency) }
Sources/ProFootballCoachUI/CoachingHQView.swift:190:                Button("Pro scouting board") { onNavigate(.proScoutingBoard) }
Sources/ProFootballCoachUI/CoachingHQView.swift:193:                Button("College offseason") { onNavigate(.collegeOffseason) }
Sources/ProFootballCoachUI/CoachingHQView.swift:194:                Button("Portal hub") { onNavigate(.portalHub) }
Sources/ProFootballCoachUI/CoachingHQView.swift:195:                Button("Retention decisions") { onNavigate(.retentionDecisions) }
Sources/ProFootballCoachUI/CoachingHQView.swift:196:                Button("Portal market") { onNavigate(.portalMarket) }
Sources/ProFootballCoachUI/CoachingHQView.swift:197:                Button("NIL allocation") { onNavigate(.nilAllocation) }
Sources/ProFootballCoachUI/CoachingHQView.swift:201:                    Button("Signing day") { onNavigate(.signingDay) }
Sources/ProFootballCoachUI/CoachingHQView.swift:203:                Button("Class overview") { onNavigate(.classOverview) }
Sources/ProFootballCoachUI/CoachingHQView.swift:204:                Button("Contact & visit planner") { onNavigate(.contactVisitPlanner) }
Sources/ProFootballCoachUI/CoachingHQView.swift:207:                Button("Cap & contracts") { onNavigate(.capContracts) }
Sources/ProFootballCoachUI/CoachingHQView.swift:209:                    Button("Contract negotiation") { onNavigate(.contractNegotiation) }
Sources/ProFootballCoachUI/CoachingHQView.swift:211:                Button("Roster cuts & transactions") { onNavigate(.rosterCutsTransactions) }
Sources/ProFootballCoachUI/CoachingHQView.swift:213:            Button("Rankings") { onNavigate(.rankingsPlayoffPicture) }
Sources/ProFootballCoachUI/CoachingHQView.swift:214:            Button("Postseason") { onNavigate(.bracketPostseason) }
Sources/ProFootballCoachUI/CoachingHQView.swift:222:        return Button(action: onContinue) {
Sources/ProFootballCoachUI/CoachingHQView.swift:223:            Label("Continue · \(mandatoryCount) due", systemImage: "forward.end.fill")
Sources/ProFootballCoachUI/CoachingHQView.swift:238:        CoachWorldRouteButton(
Sources/ProFootballCoachUI/CoachingHQView.swift:267:            Text("\(model.obligations.count) OPEN")
Sources/ProFootballCoachUI/CoachingHQView.swift:273:            Text("0 of \(model.obligations.count) cleared")
Sources/ProFootballCoachUI/CoachingHQView.swift:280:                            Text(obligation.title.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:318:                Text(decision.title)
Sources/ProFootballCoachUI/CoachingHQView.swift:322:                    Text(evidence)
Sources/ProFootballCoachUI/CoachingHQView.swift:358:                Text(choice.title.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:373:        Button(action: action) {
Sources/ProFootballCoachUI/CoachingHQView.swift:374:            Text(title.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:404:                                Text(row.slot.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:412:                                Text(row.player)
Sources/ProFootballCoachUI/CoachingHQView.swift:416:                                Text(row.status)
Sources/ProFootballCoachUI/CoachingHQView.swift:429:                            .accessibilityLabel("\(row.slot) \(row.player), \(row.status)")
Sources/ProFootballCoachUI/CoachingHQView.swift:441:                                Text(row.name)
Sources/ProFootballCoachUI/CoachingHQView.swift:445:                                Text("\(row.support)")
Sources/ProFootballCoachUI/CoachingHQView.swift:464:                            .accessibilityLabel("\(row.name), support \(row.support) of 100")
Sources/ProFootballCoachUI/CoachingHQView.swift:472:            Text("\(model.obligations.count) still open")
Sources/ProFootballCoachUI/CoachingHQView.swift:504:            Text("\(model.week.seasonLabel) · \(model.week.weekLabel)".uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:508:            Text(model.week.currentDay.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:514:                Text(obligation.consequence)
Sources/ProFootballCoachUI/CoachingHQView.swift:523:                    Text("NEXT FIXTURE")
Sources/ProFootballCoachUI/CoachingHQView.swift:527:                    Text(opponent.name.uppercased())
Sources/ProFootballCoachUI/CoachingHQView.swift:529:                    Text(model.venue?.name ?? "Venue not set")
Sources/ProFootballCoachUI/CoachingHQView.swift:544:                        Text(recommendation.staff.name).font(.headline)
Sources/ProFootballCoachUI/CoachingHQView.swift:546:                        Text(recommendation.staff.role)
Sources/ProFootballCoachUI/CoachingHQView.swift:586:                    Text(accessibleCurrentDayLabel)
Sources/ProFootballCoachUI/CoachingHQView.swift:590:                    Text(model.week.nextDeadline)
Sources/ProFootballCoachUI/CoachingHQView.swift:599:                        Text("\(day.dayLabel)\n\(day.assignment)")
Sources/ProFootballCoachUI/CoachingHQView.swift:609:                            .accessibilityLabel("\(day.dayLabel), \(day.assignment)")
Sources/ProFootballCoachUI/CoachingHQView.swift:625:                            Text("DUE · \(decision.deadline.uppercased())")
Sources/ProFootballCoachUI/CoachingHQView.swift:627:                            Text("\(unallocatedTimeLabel) unallocated")
Sources/ProFootballCoachUI/CoachingHQView.swift:631:                        Text(decision.title)
Sources/ProFootballCoachUI/CoachingHQView.swift:639:                            Text("DUE · \(decision.deadline.uppercased())")
Sources/ProFootballCoachUI/CoachingHQView.swift:643:                            Text(decision.title)
Sources/ProFootballCoachUI/CoachingHQView.swift:651:                            Text(unallocatedTimeLabel)
Sources/ProFootballCoachUI/CoachingHQView.swift:653:                            Text("UNALLOCATED").font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
Sources/ProFootballCoachUI/CoachingHQView.swift:657:                        .accessibilityLabel("\(unallocatedTimeLabel) unallocated")
Sources/ProFootballCoachUI/CoachingHQView.swift:664:                    choiceButton(choice)
Sources/ProFootballCoachUI/CoachingHQView.swift:678:            Text(evidence)
Sources/ProFootballCoachUI/CoachingHQView.swift:684:            Text("\(recommendation.staff.name): \(recommendation.verdict) · \(recommendation.confidence) confidence")
Sources/ProFootballCoachUI/CoachingHQView.swift:713:        Text(selectionReceipt(in: decision))
Sources/ProFootballCoachUI/CoachingHQView.swift:722:        Button(action: onInspect) {
Sources/ProFootballCoachUI/CoachingHQView.swift:723:            Label("Open film room", systemImage: "film")
Sources/ProFootballCoachUI/CoachingHQView.swift:727:        .accessibilityLabel("Inspect film")
Sources/ProFootballCoachUI/CoachingHQView.swift:732:        Button(action: onDelegate) {
Sources/ProFootballCoachUI/CoachingHQView.swift:737:            .accessibilityLabel("Delegate")
Sources/ProFootballCoachUI/CoachingHQView.swift:745:            Label("Set work", systemImage: "checkmark")
Sources/ProFootballCoachUI/CoachingHQView.swift:752:    private func choiceButton(_ choice: CoachWorldActionChoice) -> some View {
Sources/ProFootballCoachUI/CoachingHQView.swift:762:                        Text(choice.title).font(.headline)
Sources/ProFootballCoachUI/CoachingHQView.swift:764:                        Text(choice.cost).font(.caption.weight(.bold))
Sources/ProFootballCoachUI/CoachingHQView.swift:766:                    Text(choice.consequence)
Sources/ProFootballCoachUI/CoachingHQView.swift:791:        .accessibilityLabel("\(choice.title). Cost: \(choice.cost). Consequence: \(choice.consequence)")
Sources/ProFootballCoachUI/CoachingHQView.swift:798:                Text("YOUR DESK").font(.headline.weight(.black))
Sources/ProFootballCoachUI/CoachingHQView.swift:800:                Text("\(mandatoryCount) DUE")
Sources/ProFootballCoachUI/CoachingHQView.swift:811:                        Text("\(item.received) · \(item.isUnread ? "ANSWER" : "READ")")
Sources/ProFootballCoachUI/CoachingHQView.swift:814:                        Text(item.subject).font(.callout.weight(.semibold))
Sources/ProFootballCoachUI/CoachingHQView.swift:815:                        Text(item.sender.name)
Sources/ProFootballCoachUI/CoachingHQView.swift:828:                    Text("SATURDAY · OPPONENT").font(.caption.weight(.heavy))
Sources/ProFootballCoachUI/CoachingHQView.swift:829:                    Text(opponent.name).font(.headline)
Sources/ProFootballCoachUI/CoachingHQView.swift:830:                    Text(model.venue?.name ?? "Venue not set")
Sources/ProFootballCoachUI/CoachingHQView.swift:848:            ContentUnavailableView(
Sources/ProFootballCoachUI/CoachingHQView.swift:853:                description: Text(
Sources/ProFootballCoachUI/CoachingHQView.swift:862:                Button("Delegate balanced preparation", action: onPrepare)
Sources/ProFootballCoachUI/RosterView.swift:86:                    Text(model.team.name.uppercased())
Sources/ProFootballCoachUI/RosterView.swift:89:                    Text(statusMessage ?? worldContextLine)
Sources/ProFootballCoachUI/RosterView.swift:105:            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")
Sources/ProFootballCoachUI/RosterView.swift:120:            Button(action: onContinue) {
Sources/ProFootballCoachUI/RosterView.swift:121:                Label("Continue", systemImage: "forward.end.fill")
Sources/ProFootballCoachUI/RosterView.swift:137:        Text(model.team.abbreviation)
Sources/ProFootballCoachUI/RosterView.swift:192:        CoachWorldRouteButton(
Sources/ProFootballCoachUI/RosterView.swift:206:        Button(action: { onNavigate(screen) }) {
Sources/ProFootballCoachUI/RosterView.swift:207:            Text(title)
Sources/ProFootballCoachUI/RosterView.swift:258:            Text(label)
Sources/ProFootballCoachUI/RosterView.swift:261:            Text(value)
Sources/ProFootballCoachUI/RosterView.swift:335:            sortButton("POS", accessibilityName: "Position", field: .position,
Sources/ProFootballCoachUI/RosterView.swift:337:            sortButton("NO.", accessibilityName: "Number", field: .number,
Sources/ProFootballCoachUI/RosterView.swift:339:            sortButton("PLAYER", accessibilityName: "Player", field: .name,
Sources/ProFootballCoachUI/RosterView.swift:343:            sortButton("RATING", accessibilityName: "Rating", field: .overall,
Sources/ProFootballCoachUI/RosterView.swift:346:            sortButton("FRESH", accessibilityName: "Freshness", field: .condition,
Sources/ProFootballCoachUI/RosterView.swift:356:    private func sortButton(
Sources/ProFootballCoachUI/RosterView.swift:363:        Button(action: { toggleSort(field) }) {
Sources/ProFootballCoachUI/RosterView.swift:365:                Text(title)
Sources/ProFootballCoachUI/RosterView.swift:380:        .accessibilityLabel("Sort by \(accessibilityName)")
Sources/ProFootballCoachUI/RosterView.swift:391:        Text(title)
Sources/ProFootballCoachUI/RosterView.swift:399:        return Button(action: { selectedPlayerID = player.stableID }) {
Sources/ProFootballCoachUI/RosterView.swift:403:                Text(player.position.uppercased())
Sources/ProFootballCoachUI/RosterView.swift:406:                Text("\(player.number)")
Sources/ProFootballCoachUI/RosterView.swift:410:                Text(player.person.name)
Sources/ProFootballCoachUI/RosterView.swift:416:                Text(player.academicYear)
Sources/ProFootballCoachUI/RosterView.swift:420:                Text(player.schemeFit)
Sources/ProFootballCoachUI/RosterView.swift:425:                    Text("\(player.condition)")
Sources/ProFootballCoachUI/RosterView.swift:436:                Text(player.availability)
Sources/ProFootballCoachUI/RosterView.swift:461:        .accessibilityLabel(playerAccessibilityLabel(player))
Sources/ProFootballCoachUI/RosterView.swift:466:        Text("\(rating)")
Sources/ProFootballCoachUI/RosterView.swift:474:        return Text(text)
Sources/ProFootballCoachUI/RosterView.swift:510:                    Text(selected.person.name)
Sources/ProFootballCoachUI/RosterView.swift:513:                    Text("\(selected.academicYear) · #\(selected.number) · \(selected.position)")
Sources/ProFootballCoachUI/RosterView.swift:532:            Button("Open dossier") {
Sources/ProFootballCoachUI/RosterView.swift:553:                        Text(attribute.label.uppercased())
Sources/ProFootballCoachUI/RosterView.swift:566:                        Text("\(attribute.value)")
Sources/ProFootballCoachUI/RosterView.swift:575:                    .accessibilityLabel("\(attribute.label), \(attribute.value)")
Sources/ProFootballCoachUI/RosterView.swift:611:            Text(title)
Sources/ProFootballCoachUI/RosterView.swift:614:            Text(value)
Sources/ProFootballCoachUI/RosterView.swift:652:                Button(action: { selectedPlayerID = player.stableID }) {
Sources/ProFootballCoachUI/RosterView.swift:655:                            Text("#\(player.number) · \(player.person.name)")
Sources/ProFootballCoachUI/RosterView.swift:658:                            Text(player.position)
Sources/ProFootballCoachUI/RosterView.swift:661:                        Text("\(player.academicYear) · \(player.rosterRole)")
Sources/ProFootballCoachUI/RosterView.swift:666:                            Text("FIT")
Sources/ProFootballCoachUI/RosterView.swift:668:                            Text(player.schemeFit)
Sources/ProFootballCoachUI/RosterView.swift:671:                        Text(player.availability)
Sources/ProFootballCoachUI/RosterView.swift:690:                .accessibilityLabel(playerAccessibilityLabel(player))
Sources/ProFootballCoachUI/RosterView.swift:698:            Text(label)
Sources/ProFootballCoachUI/RosterView.swift:700:            Text("\(rating)")
Sources/ProFootballCoachUI/RosterView.swift:708:            Text("DEV change")
Sources/ProFootballCoachUI/RosterView.swift:710:            Text(delta.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "No recorded change")
Sources/ProFootballCoachUI/RosterView.swift:718:            Text("WORLD")
Sources/ProFootballCoachUI/RosterView.swift:721:            Text("\(model.team.name) · \(model.coach.name)")
Sources/ProFootballCoachUI/RosterView.swift:723:            Text(statusMessage ?? worldContextLine)
Sources/ProFootballCoachUI/RosterView.swift:733:            Button("Continue", action: onContinue)
Sources/ProFootballCoachUI/RosterView.swift:771:    private func playerAccessibilityLabel(_ player: RosterReadModel.PlayerRow) -> String {
Sources/ProFootballCoachUI/TeamHealthView.swift:44:                    Text(statusMessage)
Sources/ProFootballCoachUI/TeamHealthView.swift:124:            Text(player.position.uppercased())
Sources/ProFootballCoachUI/TeamHealthView.swift:134:            Text(player.name)
Sources/ProFootballCoachUI/TeamHealthView.swift:138:            Text(player.availability.uppercased())
Sources/ProFootballCoachUI/TeamHealthView.swift:154:            Text("\(player.condition)%")
Sources/ProFootballCoachUI/TeamHealthView.swift:168:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamHealthView.swift:191:                    Text(subject.name)
Sources/ProFootballCoachUI/TeamHealthView.swift:198:                    Text("\(subject.position) \u{00B7} \(subject.availability)")
Sources/ProFootballCoachUI/TeamHealthView.swift:207:                    Text(subject.statusDetail)
Sources/ProFootballCoachUI/TeamHealthView.swift:213:                    Text("Nobody is carrying anything.")
Sources/ProFootballCoachUI/TeamHealthView.swift:239:            Text(value)
Sources/ProFootballCoachUI/TeamHealthView.swift:244:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/TeamHealthView.swift:265:            Text(
Sources/ProFootballCoachUI/OpponentFilmView.swift:44:                    Text(statusMessage)
Sources/ProFootballCoachUI/OpponentFilmView.swift:119:            Text(situation.uppercased())
Sources/ProFootballCoachUI/OpponentFilmView.swift:128:            Text(split)
Sources/ProFootballCoachUI/OpponentFilmView.swift:132:            Text(filmedLabel)
Sources/ProFootballCoachUI/OpponentFilmView.swift:140:        .accessibilityLabel("\(situation), \(split), from \(filmedLabel)")
Sources/ProFootballCoachUI/OpponentFilmView.swift:164:                Text(
Sources/ProFootballCoachUI/OpponentFilmView.swift:178:            Text(label)
Sources/ProFootballCoachUI/OpponentFilmView.swift:182:            Text(value)
Sources/ProFootballCoachUI/OpponentFilmView.swift:186:        .accessibilityLabel("\(label.capitalized), \(value)")
Sources/ProFootballCoachUI/OpponentFilmView.swift:194:                Button("Back", action: onClose)
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:52:                    Text(statusMessage)
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:122:                Text(figure)
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:137:        .accessibilityLabel("\(label), \(figure)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:144:            Text(value)
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:158:        .accessibilityLabel("\(key), \(value)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:184:                    Text(decision.title)
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:201:                            Text(choice.title.uppercased())
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:215:                    .accessibilityLabel("\(choice.title) for \(decision.title)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:250:            Text(footerNote)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:77:                Text(model.team.name.uppercased())
Sources/ProFootballCoachUI/RecruitingBoardView.swift:80:                Text(statusMessage ?? worldContextLine)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:90:            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:103:            Button(action: onContinue) {
Sources/ProFootballCoachUI/RecruitingBoardView.swift:104:                Label("Continue", systemImage: "forward.end.fill")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:122:        CoachWorldRouteButton(
Sources/ProFootballCoachUI/RecruitingBoardView.swift:172:            Text("WORLD")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:175:            Text(model.team.name)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:177:            Text(statusMessage ?? worldContextLine)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:184:            Button("Continue", action: onContinue)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:239:            Text(positionPlanLine)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:250:        .accessibilityLabel("Position plan. \(positionPlanLine)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:259:                    Text("POSITION PLAN · \(positionPlanLine)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:278:        Text("RECRUITING BOARD")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:285:        Text("SAMPLE CAREER")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:344:            Text(value)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:347:            Text(label)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:359:            Text(label)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:364:            Text(value)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:367:            Text(suffix)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:408:                    Text("DISCOVERY · AVAILABLE PROSPECTS")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:429:        Text(title)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:442:                Text(prospect.boardRank == 0 ? "D" : "\(prospect.boardRank)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:447:                    Text(prospect.person.name)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:451:                    Text(prospect.hometown)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:479:        .accessibilityLabel(prospectAccessibilityLabel(prospect))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:486:        Text(value)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:501:                            Text("#\(prospect.boardRank) · \(prospect.person.name)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:504:                            Text(prospect.position)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:507:                        Text("\(prospect.hometown) · \(prospect.interest) interest")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:509:                        Text("\(prospect.status) · \(prospect.evaluation.schemeFit) fit")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:528:                .accessibilityLabel(prospectAccessibilityLabel(prospect))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:540:                    Text("DISCOVERY · AVAILABLE PROSPECTS")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:549:                                    Text("Discovery · \(prospect.person.name)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:552:                                    Text(prospect.position)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:555:                                Text("\(prospect.hometown) · \(prospect.evaluation.schemeFit) fit")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:557:                                Text(prospect.status)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:576:                        .accessibilityLabel(prospectAccessibilityLabel(prospect))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:636:                Text(prospect.boardRank == 0
Sources/ProFootballCoachUI/RecruitingBoardView.swift:641:                Text(prospect.person.name)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:644:                Text("\(prospect.hometown) · \(prospect.status)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:655:        .accessibilityLabel(
Sources/ProFootballCoachUI/RecruitingBoardView.swift:664:            Text("SYSTEM EVALUATION")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:667:            Text(prospect.evaluation.verdict)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:675:                Text(prospect.evaluation.citedOutliers.prefix(3).joined(separator: " · "))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:688:            Text(label)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:691:            Text(value)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:698:        Text(choice.title)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:704:            Text(choice.consequence)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:710:                Text(reason)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:720:            Text("RELATIONSHIP LOG")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:724:                Text("No contact recorded")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:730:                        Text("\(event.dateLabel) · \(event.summary)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:732:                        Text(event.effect)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:746:            Text("PROSPECT SURFACES")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:769:        Button("Open profile") { onOpenProspect(prospect.stableID) }
Sources/ProFootballCoachUI/RecruitingBoardView.swift:771:        Button("Shortlist") { onOpenShortlist() }
Sources/ProFootballCoachUI/RecruitingBoardView.swift:777:            Text("ASSIGN RECRUITING WORK")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:781:                Text("No action is currently available")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:793:                                Text(choice.cost)
Sources/ProFootballCoachUI/RecruitingBoardView.swift:820:                    .accessibilityLabel(
Sources/ProFootballCoachUI/RecruitingBoardView.swift:843:    private func prospectAccessibilityLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:137:                    Text(model.team.name.uppercased())
Sources/ProFootballCoachUI/LeagueMapView.swift:140:                    Text(statusMessage ?? worldContextLine)
Sources/ProFootballCoachUI/LeagueMapView.swift:156:            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")
Sources/ProFootballCoachUI/LeagueMapView.swift:174:            Button(action: onContinue) {
Sources/ProFootballCoachUI/LeagueMapView.swift:175:                Label("Continue", systemImage: "forward.end.fill")
Sources/ProFootballCoachUI/LeagueMapView.swift:187:        Text(model.team.abbreviation)
Sources/ProFootballCoachUI/LeagueMapView.swift:209:        CoachWorldRouteButton(
Sources/ProFootballCoachUI/LeagueMapView.swift:259:                        Text(row.team.name)
Sources/ProFootballCoachUI/LeagueMapView.swift:268:                        Text(row.conferenceRecord)
Sources/ProFootballCoachUI/LeagueMapView.swift:271:                        Text(row.overallRecord)
Sources/ProFootballCoachUI/LeagueMapView.swift:276:                        Text(row.pointDifferential > 0
Sources/ProFootballCoachUI/LeagueMapView.swift:295:                    .accessibilityLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:330:                            regionLabel(region, layout: layout)
Sources/ProFootballCoachUI/LeagueMapView.swift:351:                    placeBrowserButton(place)
Sources/ProFootballCoachUI/LeagueMapView.swift:356:        .accessibilityLabel("All \(tier) places")
Sources/ProFootballCoachUI/LeagueMapView.swift:359:    private func placeNameLabel(_ place: LeagueMapReadModel.Place) -> some View {
Sources/ProFootballCoachUI/LeagueMapView.swift:360:        Text(place.team.name)
Sources/ProFootballCoachUI/LeagueMapView.swift:365:    private func placeCityLabel(_ place: LeagueMapReadModel.Place) -> some View {
Sources/ProFootballCoachUI/LeagueMapView.swift:366:        Text(place.cityName)
Sources/ProFootballCoachUI/LeagueMapView.swift:372:    private func placeBrowserButton(_ place: LeagueMapReadModel.Place) -> some View {
Sources/ProFootballCoachUI/LeagueMapView.swift:378:                placeNameLabel(place)
Sources/ProFootballCoachUI/LeagueMapView.swift:379:                placeCityLabel(place)
Sources/ProFootballCoachUI/LeagueMapView.swift:390:        .accessibilityLabel(placeAccessibilityLabel(place))
Sources/ProFootballCoachUI/LeagueMapView.swift:397:                Text(value).tag(value)
Sources/ProFootballCoachUI/LeagueMapView.swift:439:    private func regionLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:444:        return Text(region.name.uppercased())
Sources/ProFootballCoachUI/LeagueMapView.swift:464:        return Button(action: { selectedPlaceID = place.stableID }) {
Sources/ProFootballCoachUI/LeagueMapView.swift:508:        .accessibilityLabel(placeAccessibilityLabel(place))
Sources/ProFootballCoachUI/LeagueMapView.swift:520:                        Text(place.team.name)
Sources/ProFootballCoachUI/LeagueMapView.swift:522:                        Text("\(place.cityName) · \(place.regionName)")
Sources/ProFootballCoachUI/LeagueMapView.swift:533:                    fact("Talent in region", talentDensityLabel(place))
Sources/ProFootballCoachUI/LeagueMapView.swift:534:                    Button("Open team profile") {
Sources/ProFootballCoachUI/LeagueMapView.swift:555:            Text(name.uppercased())
Sources/ProFootballCoachUI/LeagueMapView.swift:559:            Text(value)
Sources/ProFootballCoachUI/LeagueMapView.swift:566:        .accessibilityLabel("\(name), \(value)")
Sources/ProFootballCoachUI/LeagueMapView.swift:569:    private func talentDensityLabel(_ place: LeagueMapReadModel.Place) -> String {
Sources/ProFootballCoachUI/LeagueMapView.swift:576:        Text("Rivals".uppercased())
Sources/ProFootballCoachUI/LeagueMapView.swift:580:            Text("No rivalry recorded")
Sources/ProFootballCoachUI/LeagueMapView.swift:585:                Button(action: { selectedPlaceID = rival.stableID }) {
Sources/ProFootballCoachUI/LeagueMapView.swift:588:                            Text(rival.name)
Sources/ProFootballCoachUI/LeagueMapView.swift:591:                            Text(rival.originLabel)
Sources/ProFootballCoachUI/LeagueMapView.swift:596:                        Text("\(rival.intensity)")
Sources/ProFootballCoachUI/LeagueMapView.swift:604:                .accessibilityLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:629:                        Text("\(region.name) · talent \(region.talentDensity)")
Sources/ProFootballCoachUI/LeagueMapView.swift:638:                    Text("Rivals of \(place.team.name)")
Sources/ProFootballCoachUI/LeagueMapView.swift:653:        return Button(action: { selectedPlaceID = place.stableID }) {
Sources/ProFootballCoachUI/LeagueMapView.swift:655:                Text(place.team.name)
Sources/ProFootballCoachUI/LeagueMapView.swift:657:                Text("\(place.cityName) · \(place.conferenceName ?? "Independent")")
Sources/ProFootballCoachUI/LeagueMapView.swift:660:                Text("Prestige \(place.prestige) · market \(place.marketSize)")
Sources/ProFootballCoachUI/LeagueMapView.swift:682:        .accessibilityLabel(placeAccessibilityLabel(place))
Sources/ProFootballCoachUI/LeagueMapView.swift:686:    private func placeAccessibilityLabel(_ place: LeagueMapReadModel.Place) -> String {
Sources/ProFootballCoachUI/NewsView.swift:39:                    Text(statusMessage)
Sources/ProFootballCoachUI/NewsView.swift:84:                        Text(item.headline.uppercased())
Sources/ProFootballCoachUI/NewsView.swift:96:                .accessibilityLabel("\(item.occurred). \(item.headline)")
Sources/ProFootballCoachUI/NewsView.swift:124:                    Text(story.headline.uppercased())
Sources/ProFootballCoachUI/NewsView.swift:132:                    Text("The league records the event, not the article behind it.")
Sources/ProFootballCoachUI/NewsView.swift:146:            Text("Everything printed here happened. None of it is speculation.")
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:41:                    Text(statusMessage)
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:93:                    Text(player.person.name.uppercased())
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:101:                    Text("\(player.position.uppercased()) \u{00B7} \(player.overall) overall")
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:119:                        Text(deltaLabel(player.developmentDelta))
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:126:                        Text("Condition \(player.condition)")
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:158:                        Text(player.position.uppercased())
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:167:                        Text(player.person.name)
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:175:                        Text("\(player.overall)")
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:185:                        Text(deltaLabel(player.developmentDelta))
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:191:                .accessibilityLabel(
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:218:    private func deltaLabel(_ delta: Int?) -> String {
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:235:            Text("Everything here was earned since August. Nothing is projected.")
Sources/ProFootballCoachUI/PracticePlanView.swift:55:                    Text(statusMessage)
Sources/ProFootballCoachUI/PracticePlanView.swift:85:                    Text("\(TacticalPracticePlan.weeklyMinutes)\u{2032} total")
Sources/ProFootballCoachUI/PracticePlanView.swift:113:                Text(name.uppercased())
Sources/ProFootballCoachUI/PracticePlanView.swift:126:                Text("\(minutes)\u{2032}")
Sources/ProFootballCoachUI/PracticePlanView.swift:136:        .accessibilityLabel("\(name), \(minutes) minutes of \(TacticalPracticePlan.weeklyMinutes)")
Sources/ProFootballCoachUI/PracticePlanView.swift:156:                        Text(option.title.uppercased())
Sources/ProFootballCoachUI/PracticePlanView.swift:163:                        Text(option.consequence)
Sources/ProFootballCoachUI/PracticePlanView.swift:169:                .accessibilityLabel("\(option.title). \(option.consequence)")
Sources/ProFootballCoachUI/StandingsView.swift:48:                    Text(statusMessage)
Sources/ProFootballCoachUI/StandingsView.swift:115:        .accessibilityLabel(
Sources/ProFootballCoachUI/StandingsView.swift:116:            "\(index + 1). \(row.team.name), \(recordLabel(row)), "
Sources/ProFootballCoachUI/StandingsView.swift:130:                Text("\(index + 1). \(row.team.name)")
Sources/ProFootballCoachUI/StandingsView.swift:133:                Text(
Sources/ProFootballCoachUI/StandingsView.swift:134:                    "\(recordLabel(row)) \u{00B7} conference \(row.conferenceRecord)"
Sources/ProFootballCoachUI/StandingsView.swift:138:                Text("\(row.pointsFor) for, \(row.pointsAgainst) against")
Sources/ProFootballCoachUI/StandingsView.swift:162:                Text("\(index + 1)")
Sources/ProFootballCoachUI/StandingsView.swift:172:                Text(row.team.name.uppercased())
Sources/ProFootballCoachUI/StandingsView.swift:181:                Text(recordLabel(row))
Sources/ProFootballCoachUI/StandingsView.swift:184:                Text(row.conferenceRecord)
Sources/ProFootballCoachUI/StandingsView.swift:188:                Text("\(row.pointsFor)\u{2013}\(row.pointsAgainst)")
Sources/ProFootballCoachUI/StandingsView.swift:213:    private func recordLabel(_ row: StandingsReadModel.Row) -> String {
Sources/ProFootballCoachUI/StandingsView.swift:221:            Text(note)
Sources/ProFootballCoachUI/TitleContinueView.swift:48:            Text("Pro Football Coach")
Sources/ProFootballCoachUI/TitleContinueView.swift:51:                Text(failure)
Sources/ProFootballCoachUI/TitleContinueView.swift:66:                Button("New career", action: onNewCareer)
Sources/ProFootballCoachUI/TitleContinueView.swift:70:            Button("Settings & accessibility", action: onSettings)
Sources/ProFootballCoachUI/TitleContinueView.swift:84:            Button("Retry restore", action: onRetry)
Sources/ProFootballCoachUI/TitleContinueView.swift:87:            Button("Use backup", action: onUseBackup)
Sources/ProFootballCoachUI/TitleContinueView.swift:90:            Text("Starting over deletes this career and every season in it. There is no undo.")
Sources/ProFootballCoachUI/TitleContinueView.swift:94:            Button("Delete and start over", action: onNewCareer)
Sources/ProFootballCoachUI/AftermathView.swift:47:                    Text(statusMessage)
Sources/ProFootballCoachUI/AftermathView.swift:94:            Text(side.team.name.uppercased())
Sources/ProFootballCoachUI/AftermathView.swift:108:            Text("\(side.score)")
Sources/ProFootballCoachUI/AftermathView.swift:122:        .accessibilityLabel("\(side.team.name), \(side.score)")
Sources/ProFootballCoachUI/AftermathView.swift:154:            Text(grade.position.uppercased())
Sources/ProFootballCoachUI/AftermathView.swift:164:            Text(grade.player.name)
Sources/ProFootballCoachUI/AftermathView.swift:169:            Text("\(grade.rating)")
Sources/ProFootballCoachUI/AftermathView.swift:176:        .accessibilityLabel(
Sources/ProFootballCoachUI/AftermathView.swift:215:                    Text(line)
Sources/ProFootballCoachUI/AftermathView.swift:230:            Text(model.headline)
Sources/ProFootballCoachUI/AftermathView.swift:235:                Button("Box score", action: onOpenBoxScore)
Sources/ProFootballCoachUI/RealignmentEventView.swift:28:                    Button("League", action: onClose)
Sources/ProFootballCoachUI/RealignmentEventView.swift:32:                        Text("Realignment event").font(CoachWorldTokens.TypeRole.headline.weight(.black))
Sources/ProFootballCoachUI/RealignmentEventView.swift:33:                        Text(model.currentSeasonLabel).font(CoachWorldTokens.TypeRole.caption)
Sources/ProFootballCoachUI/RealignmentEventView.swift:39:                if let statusMessage { Text(statusMessage).frame(maxWidth: .infinity, alignment: .leading) }
Sources/ProFootballCoachUI/RealignmentEventView.swift:43:                            Text(event.seasonLabel + " · " + event.reason)
Sources/ProFootballCoachUI/RealignmentEventView.swift:66:            Text(title).fontWeight(.bold)
Sources/ProFootballCoachUI/RealignmentEventView.swift:67:            Text(firstMove)
Sources/ProFootballCoachUI/RealignmentEventView.swift:68:            Text(secondMove)
Sources/ProFootballCoachUI/RealignmentEventView.swift:72:        .accessibilityLabel(spoken)
Sources/ProFootballCoachUI/ProspectProfileView.swift:57:                    Text(statusMessage)
Sources/ProFootballCoachUI/ProspectProfileView.swift:106:                FloodlitLabel3(rankLabel(prospect), palette: palette, tint: palette.actionPrimary.color)
Sources/ProFootballCoachUI/ProspectProfileView.swift:107:                Text(prospect.person.name.uppercased())
Sources/ProFootballCoachUI/ProspectProfileView.swift:113:                Text("\(prospect.position) \u{00B7} \(prospect.hometown)")
Sources/ProFootballCoachUI/ProspectProfileView.swift:118:            .accessibilityLabel(
Sources/ProFootballCoachUI/ProspectProfileView.swift:119:                "\(rankLabel(prospect)), \(prospect.person.name), \(prospect.position), "
Sources/ProFootballCoachUI/ProspectProfileView.swift:124:                Text(prospect.evaluation.verdict)
Sources/ProFootballCoachUI/ProspectProfileView.swift:128:                    Text(prospect.evaluation.citedOutliers.prefix(3).joined(separator: " \u{00B7} "))
Sources/ProFootballCoachUI/ProspectProfileView.swift:138:    private func rankLabel(_ prospect: RecruitingBoardReadModel.Prospect) -> String {
Sources/ProFootballCoachUI/ProspectProfileView.swift:158:            Text(value.uppercased())
Sources/ProFootballCoachUI/ProspectProfileView.swift:164:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/ProspectProfileView.swift:171:                Text("No contact recorded.")
Sources/ProFootballCoachUI/ProspectProfileView.swift:177:                        Text(event.dateLabel)
Sources/ProFootballCoachUI/ProspectProfileView.swift:180:                        Text(event.summary)
Sources/ProFootballCoachUI/ProspectProfileView.swift:183:                        Text(event.effect)
Sources/ProFootballCoachUI/ProspectProfileView.swift:213:                            Text(choice.title.uppercased())
Sources/ProFootballCoachUI/ProspectProfileView.swift:234:                                Text(choice.unavailableReason ?? "Not available.")
Sources/ProFootballCoachUI/ProspectProfileView.swift:242:                    .accessibilityLabel(
Sources/ProFootballCoachUI/ProspectProfileView.swift:255:            Text(footerNote)
Sources/ProFootballCoachUI/DepthChartView.swift:55:                    Text(statusMessage)
Sources/ProFootballCoachUI/DepthChartView.swift:178:                Text(DepthPlacement.abbreviation(for: group.id))
Sources/ProFootballCoachUI/DepthChartView.swift:183:                Text(fieldPlayerName(starter?.playerName))
Sources/ProFootballCoachUI/DepthChartView.swift:205:        .accessibilityLabel(
Sources/ProFootballCoachUI/DepthChartView.swift:234:                Text(index == 0 ? "START" : "\(index + 1)")
Sources/ProFootballCoachUI/DepthChartView.swift:243:                    Text(slot.playerName.uppercased())
Sources/ProFootballCoachUI/DepthChartView.swift:250:                    Text(slot.availability)
Sources/ProFootballCoachUI/DepthChartView.swift:261:        .accessibilityLabel(
Sources/ProFootballCoachUI/DepthChartView.swift:283:                        Text(option.title.uppercased())
Sources/ProFootballCoachUI/DepthChartView.swift:293:                        Text(option.consequence)
Sources/ProFootballCoachUI/DepthChartView.swift:299:                .accessibilityLabel("\(option.title). \(option.consequence)")
Sources/ProFootballCoachUI/DepthChartView.swift:308:            Text(vacancyMessage)
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:45:                    Text(statusMessage)
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:74:                Text(model.team.name.uppercased())
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:78:                Text(conferenceLine)
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:83:            .accessibilityLabel(
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:87:                Text(model.record)
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:114:            Text(value)
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:127:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:148:                Text("No games played yet.")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:183:            Text(entry.won ? "W" : "L")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:188:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:203:                Text("No rivalry recorded.")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:220:                    Text(rival.team.name.uppercased())
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:240:                Text("\(rival.intensity)")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:245:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:261:                Text("No traditions recorded.")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:266:                    Text(tradition)
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:278:            Text("Every figure here is recorded for this programme, not projected.")
Sources/ProFootballCoachUI/RootView.swift:208:                            Text("Selected row").font(CoachWorldTokens.TypeRole.body)
Sources/ProFootballCoachUI/RootView.swift:213:                    FloodlitRow { Text("Plain row").font(CoachWorldTokens.TypeRole.body) }
Sources/ProFootballCoachUI/AwardsHonoursView.swift:36:                    Text(statusMessage)
Sources/ProFootballCoachUI/AwardsHonoursView.swift:81:                Text(award.winner.uppercased())
Sources/ProFootballCoachUI/AwardsHonoursView.swift:87:                Text(award.tier)
Sources/ProFootballCoachUI/AwardsHonoursView.swift:91:                Text(award.seasonLabel)
Sources/ProFootballCoachUI/AwardsHonoursView.swift:102:        .accessibilityLabel(
Sources/ProFootballCoachUI/AwardsHonoursView.swift:109:            Text("Honours already awarded. Nothing here is a nomination.")
Sources/ProFootballCoachUI/ClassOverviewView.swift:49:                    Text(statusMessage)
Sources/ProFootballCoachUI/ClassOverviewView.swift:67:                Text("\(committedCount)")
Sources/ProFootballCoachUI/ClassOverviewView.swift:74:                Text("of \(CollegeRules.initialSigningsPerClass)")
Sources/ProFootballCoachUI/ClassOverviewView.swift:89:        .accessibilityLabel(
Sources/ProFootballCoachUI/ClassOverviewView.swift:138:            Text(need.position.uppercased())
Sources/ProFootballCoachUI/ClassOverviewView.swift:146:            Text("\(need.committed)/\(need.target)")
Sources/ProFootballCoachUI/ClassOverviewView.swift:157:        .accessibilityLabel(
Sources/ProFootballCoachUI/ClassOverviewView.swift:175:                Text("Nobody has committed to this class yet.")
Sources/ProFootballCoachUI/ClassOverviewView.swift:188:            Text(prospect.person.name.uppercased())
Sources/ProFootballCoachUI/ClassOverviewView.swift:192:            Text(prospect.position.uppercased())
Sources/ProFootballCoachUI/ClassOverviewView.swift:197:            Text(prospect.evaluation.schemeFit)
Sources/ProFootballCoachUI/ClassOverviewView.swift:202:            Text(prospect.status.uppercased())
Sources/ProFootballCoachUI/ClassOverviewView.swift:213:        .accessibilityLabel(
Sources/ProFootballCoachUI/ClassOverviewView.swift:220:            Text(footerNote)
Sources/ProFootballCoachUI/WorldSearchView.swift:60:                    Text(statusMessage)
Sources/ProFootballCoachUI/WorldSearchView.swift:91:            TextField("Team, city or region", text: $query)
Sources/ProFootballCoachUI/WorldSearchView.swift:94:                .accessibilityLabel("Search current teams, cities or regions")
Sources/ProFootballCoachUI/WorldSearchView.swift:172:                Text(result.team.name.uppercased())
Sources/ProFootballCoachUI/WorldSearchView.swift:180:                Text("\(result.cityName), \(result.regionName)")
Sources/ProFootballCoachUI/WorldSearchView.swift:194:        .accessibilityLabel(
Sources/ProFootballCoachUI/WorldSearchView.swift:201:            Text("Every organisation currently in the world.")
```

Provider/read-model and displayed raw-enum string expressions:

```text
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:21:                ? String(row.wins) + "-" + String(row.losses)
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:22:                : String(row.wins) + "-" + String(row.losses) + "-" + String(row.ties)
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:48:                        String($0.homeScore) + "–" + String($0.awayScore)
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:50:                    week: "Week " + String(game.week)
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:54:            snapshotID: snapshotID("competition-overview-" + tier.rawValue,
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:59:            tier: tier == .college ? "College" : "Professional",
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:81:                conferenceRecord: "\(standing.conferenceWins)-\(standing.conferenceLosses)"
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:82:                    + (standing.conferenceTies == 0 ? "" : "-\(standing.conferenceTies)"),
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:89:            snapshotID: snapshotID("standings-\(tier.rawValue)", state.league.id, state.calendar),
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:94:            tier: tier == .college ? "College" : "Professional",
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:112:                    week: "Week \(game.week)",
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:116:                    score: game.result.map { "\($0.homeScore)–\($0.awayScore)" },
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:121:            snapshotID: snapshotID("schedule-\(tier.rawValue)", state.league.id, state.calendar),
Sources/CoachWorldApp/CoachWorldCompetitionProvider.swift:125:            tier: tier == .college ? "College" : "Professional",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:30:            state.proTeams[id].map { "Pick \(market.nextPick + 1) · \($0.cityName) \($0.nickname)" }
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:37:                id: "pro:open-offseason",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:38:                title: "Open offseason",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:39:                detail: "Create the next draft class and free-agent ledger.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:44:                id: "pro:begin-draft",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:45:                title: "Begin draft",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:46:                detail: "Move the league to the controlled draft clock.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:52:                    id: "pro:wait-draft",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:53:                    title: "Draft clock",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:57:                    unavailableReason: "The controlled team is not on the clock."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:62:                id: "pro:close-market",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:63:                title: "Close offseason",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:64:                detail: "Return the league to regular-season management.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:74:                id: "pro:resolve-waivers",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:75:                title: "Resolve expired waivers",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:76:                detail: "Release \(expiredWaiverCount) unclaimed player(s) into free agency.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:92:                        id: "pro:scout:\(prospect.id.uuidString)",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:93:                        title: "Scout",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:94:                        detail: "Record one controlled observation.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:99:                        id: "pro:draft:\(prospect.id.uuidString)",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:100:                        title: "Draft",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:101:                        detail: canDraft ? "Use the rookie contract." : currentPickLabel ?? "Wait for the clock.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:108:                        unavailableReason: canDraft ? nil : "The controlled team is not eligible to pick now."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:129:                    id: "pro:sign:\(playerID.uuidString)",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:130:                    title: "Sign",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:131:                    detail: "One-year minimum contract.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:139:                        ? (canAffordMinimum ? nil : "No cap room for the minimum contract.")
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:140:                        : "The active roster is full."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:164:                    reason = "A team cannot claim its own waiver."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:166:                    reason = "The claim deadline has passed."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:168:                    reason = "The active roster is full."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:170:                    reason = "No cap room for this contract."
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:180:                        id: "pro:claim:\(entry.playerID.uuidString)",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:181:                        title: "Claim",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:182:                        detail: "Assume the existing contract.",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:191:            snapshotID: snapshotID("pro-offseason", team.id, state.calendar)
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:192:                + "-\(market.phase.rawValue)-\(market.nextPick)",
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:238:        case .quarterback: return "Quarterback"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:239:        case .runningBack: return "Running back"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:240:        case .wideReceiver: return "Wide receiver"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:241:        case .tightEnd: return "Tight end"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:242:        case .leftTackle: return "Left tackle"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:243:        case .guardPosition: return "Guard"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:244:        case .center: return "Center"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:245:        case .rightTackle: return "Right tackle"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:246:        case .edgeRusher: return "Edge rusher"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:247:        case .defensiveTackle: return "Defensive tackle"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:248:        case .linebacker: return "Linebacker"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:249:        case .cornerback: return "Cornerback"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:250:        case .safety: return "Safety"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:251:        case .kicker: return "Kicker"
Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift:252:        case .punter: return "Punter"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:35:            resultLabel = "Tie"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:36:            headline = "\(home.team.name) and \(away.team.name) finished level."
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:39:            resultLabel = "\(winner.abbreviation) win"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:40:            headline = "\(winner.name) won the recorded fixture."
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:49:                stableID: "\(game.id.uuidString)-\(player.id.uuidString)",
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:58:                evidence: "Passing \(line.passingYards), rushing \(line.rushingYards), receiving \(line.receivingYards), TD \(line.touchdowns)."
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:62:            "\($0.side == .home ? home.team.abbreviation : away.team.abbreviation): \($0.action.rawValue) at \($0.trigger.label.lowercased())"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:78:            return "\(player.fullName): \(injury.area.rawValue) \(injury.severity.rawValue) injury, \(injury.weeks) week(s)."
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:90:                "Recorded drives: \(evidence.record.drives.count)",
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:91:                "Decisive matchups retained: \(evidence.decisiveMatchups.count)",
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:92:                "Source: controlled detailed reducer"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:109:        case .quarterback: return "QB"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:110:        case .runningBack: return "RB"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:111:        case .wideReceiver: return "WR"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:112:        case .tightEnd: return "TE"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:113:        case .leftTackle: return "LT"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:114:        case .guardPosition: return "G"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:115:        case .center: return "C"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:116:        case .rightTackle: return "RT"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:117:        case .edgeRusher: return "EDGE"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:118:        case .defensiveTackle: return "DT"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:119:        case .linebacker: return "LB"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:120:        case .cornerback: return "CB"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:121:        case .safety: return "S"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:122:        case .kicker: return "K"
Sources/CoachWorldApp/CoachWorldAftermathProvider.swift:123:        case .punter: return "P"
Sources/CoachWorldApp/CoachWorldCollegeOffseasonProvider.swift:28:            snapshotID: snapshotID("college-offseason", programme.id, state.calendar)
Sources/CoachWorldApp/CoachWorldCollegeOffseasonProvider.swift:29:                + "-\(state.college.portal.phase.rawValue)",
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:18:                historyRecord($0, title: "Highest team score", in: state)
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:21:                historyRecord($0, title: "Most team yards", in: state)
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:39:                id: "\(coachID.uuidString)-\(assignment.season)-\(assignment.organisationID.uuidString)-\(assignment.role.rawValue)",
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:49:                disciples: branch.disciples.map { "\($0.name) · Season \($0.firstHeadCoachSeason)" }
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:53:            snapshotID: snapshotID("legacy-history", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:70:            id: "\(title)-\(entry.gameID.uuidString)",
Sources/CoachWorldApp/CoachWorldHistoryProvider.swift:75:            gameLabel: "Season \(entry.season + 1) · Week \(entry.week) · \(entry.stage.rawValue)"
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:22:                tier: "College",
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:34:                tier: "Professional",
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:43:            snapshotID: snapshotID("world-search", state.league.id, state.calendar),
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:91:        } ?? "Independent"
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:111:                    week: "Season " + String(game.season + 1) + ", Week " + String(game.week),
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:115:                        String($0.homeScore) + "–" + String($0.awayScore)
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:136:            snapshotID: snapshotID("team-profile", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:143:            tier: tier == .college ? "College" : "Professional",
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:148:            record: standingRow(organisationID, in: state).map { record($0) } ?? "0-0",
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:160:            return String(row.wins) + "-" + String(row.losses)
Sources/CoachWorldApp/CoachWorldTeamProfileProvider.swift:162:        return String(row.wins) + "-" + String(row.losses) + "-" + String(row.ties)
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:49:                team.rosterIDs.contains(player.id) ? "Active roster" : "Practice squad"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:91:            ? "Complete the pending decision in Coaching HQ before advancing."
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:95:            snapshotID: snapshotID("roster", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:144:            rosterRole: team.rosterIDs.contains(playerID) ? "Active roster" : "Practice squad",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:202:            hometown: "",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:209:            staffSummary: "",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:221:            return "No recorded development change in this snapshot."
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:226:                    let sign = change.delta >= 0 ? "+" : ""
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:227:                    return "S\(change.occurredAt.season) W\(change.occurredAt.week) "
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:228:                        + "\(change.attribute.label) \(sign)\(change.delta) (\(change.cause.rawValue))"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:230:                .joined(separator: "; ")
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:234:            return "No recorded development change in this snapshot."
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:238:                let sign = change.delta >= 0 ? "+" : ""
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:239:                return "\(change.attribute.label) \(sign)\(change.delta)"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:241:            .joined(separator: ", ")
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:242:        let result = latest.isEmpty ? "No attribute change" : latest
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:243:        return "Season \(summary.occurredAt.season), week \(summary.occurredAt.week): \(result)."
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:258:            return "No completed game history is retained in this season's schedule."
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:261:        return "\(completedGames) completed game(s) retained; \(formCount) recent form result(s) shown."
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:292:                stableID: "\(player.id.uuidString)-\(game.id.uuidString)",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:303:            stableID: "\(player.id.uuidString)-person",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:310:    /// in. Confidence is "Known" because the coach's own players carry no fog — `02` §5 puts the
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:320:            ("physical", "Physical", rated.filter { physical.contains($0) }),
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:321:            ("mental", "Mental", rated.filter { mental.contains($0) }),
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:322:            ("technical", "Technical", rated.filter {
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:329:                stableID: "\(player.id.uuidString)-\(key)",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:333:                        stableID: "\(player.id.uuidString)-\(attribute.rawValue)",
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:336:                        confidence: "Known"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:360:            return "\(label(injury.area)) injury, \(injury.weeksRemaining) week(s) remaining"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:363:            return "Past the decline age for the position"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:365:        return ""
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:377:        guard let lifecycle = state.people.playerLifecycle[player.id] else { return "Available" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:379:            return "Suspended " + String(suspension.weeksRemaining) + " week(s)"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:382:            return "Out \(injury.weeksRemaining) week(s)"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:384:        return lifecycle.status == .active ? "Available" : "Unavailable"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:397:                recruiting.scholarshipPlayerIDs.contains(player.id) ? "Scholarship" : "Walk-on"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:400:        if state.college.redshirtPlans[player.id] != nil { parts.append("Redshirt planned") }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:401:        return parts.joined(separator: " · ")
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:405:        guard let eligibility = player.eligibility else { return "" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:407:        case 4: return "FR"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:408:        case 3: return "SO"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:409:        case 2: return "JR"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:410:        case 1: return "SR"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:411:        default: return "GR"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:419:        guard !rated.isEmpty else { return "" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:421:        guard !emphasised.isEmpty else { return "Neutral" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:423:        guard !matched.isEmpty else { return "Weak" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:425:        if mean >= player.overall.value + strengthMargin { return "Elite" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:426:        if mean >= player.overall.value { return "Strong" }
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:427:        return "Fair"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:442:        case .quarterback: return "QB"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:443:        case .runningBack: return "RB"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:444:        case .wideReceiver: return "WR"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:445:        case .tightEnd: return "TE"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:446:        case .leftTackle: return "LT"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:447:        case .guardPosition: return "G"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:448:        case .center: return "C"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:449:        case .rightTackle: return "RT"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:450:        case .edgeRusher: return "EDGE"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:451:        case .defensiveTackle: return "DT"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:452:        case .linebacker: return "LB"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:453:        case .cornerback: return "CB"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:454:        case .safety: return "S"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:455:        case .kicker: return "K"
Sources/CoachWorldApp/CoachWorldPersonnelProvider.swift:456:        case .punter: return "P"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:66:            ? "Complete the pending decision in Coaching HQ before advancing."
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:69:            snapshotID: snapshotID("recruiting", programme.id, state.calendar),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:107:            reason = "Recruiting responsibility is delegated"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:109:            reason = "Recruiting is not open in this phase"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:111:            reason = "Recruiting is paused for the spring portal transaction"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:113:            reason = "The recruiting board is full"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:120:                stableID: "\(stableID)-person",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:127:            interest: "Untracked",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:128:            status: "Discoverable",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:137:                intentID: CoachWorldIntentID(rawValue: "addToBoard"),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:138:                title: "Add to board",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:139:                cost: "0 contact points",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:140:                consequence: "Starts a bounded relationship record for this prospect",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:160:                stableID: "\(prospect.id.uuidString)-person",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:195:        guard let city = state.map.city(cityID) else { return "" }
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:199:        return "\(city.name), \(region.name)"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:204:        case ..<20: return "Cold"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:205:        case 20..<45: return "Warm"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:206:        case 45..<70: return "Hot"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:207:        default: return "Locked in"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:216:        case .committed: return "Committed"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:217:        case .signed: return "Signed"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:218:        case .released: return "Released"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:219:        case .available, nil: return "Uncommitted"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:237:                verdict: "Unscored",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:238:                schemeFit: "",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:239:                uncertainty: "",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:252:            .map { "\(label($0.reason)) \($0.value >= 0 ? "+" : "")\($0.value)" }
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:257:            uncertainty: confidence.map { "Confidence \($0)%" } ?? "No evaluation yet",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:264:        // sub-threshold fit cannot be presented as an "Elite" commitment prospect.
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:266:        case ..<60: return "Weak"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:267:        case 60..<70: return "Fair"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:268:        case 70..<85: return "Strong"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:269:        default: return "Elite"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:275:        case ..<0: return "Weak"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:276:        case 0..<4: return "Fair"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:277:        case 4..<8: return "Strong"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:278:        default: return "Elite"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:297:        let contactCost = "\(CollegeRules.aiEvaluationContactPoints) pts"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:316:            phaseReason = "Recruiting responsibility is delegated"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:318:            phaseReason = "Recruiting is not open in this phase"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:320:            phaseReason = "Recruiting is paused for the spring portal transaction"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:322:            phaseReason = "Recruiting is not open in this phase"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:325:        let boardReason = "This prospect is not on this programme's board"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:328:        case .signed: prospectReason = "This prospect has signed"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:329:        case .released: prospectReason = "This prospect was released"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:331:            prospectReason = "This prospect is committed elsewhere"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:332:        default: prospectReason = "This prospect is not available"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:336:                intentID: CoachWorldIntentID(rawValue: "contact"),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:337:                title: "Contact",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:339:                consequence: "Raises interest",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:344:                    : "Only \(recruiting.contactPointsRemaining) contact points remain"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:347:                intentID: CoachWorldIntentID(rawValue: "evaluate"),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:348:                title: "Evaluate",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:350:                consequence: "Narrows the fog on their true ratings",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:355:                    : "Only \(recruiting.contactPointsRemaining) contact points remain"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:360:                intentID: CoachWorldIntentID(rawValue: "scheduleVisit"),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:361:                title: "Schedule visit",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:362:                cost: "\(CollegeRules.visitContactCost) pts",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:363:                consequence: "Creates a commitment window",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:368:                    : "Only \(recruiting.contactPointsRemaining) contact points remain"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:373:                intentID: CoachWorldIntentID(rawValue: "offerScholarship"),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:374:                title: "Offer scholarship",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:375:                cost: "1 slot",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:376:                consequence: "Commits a scholarship slot",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:381:                    : "No scholarship slots remain"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:385:            intentID: CoachWorldIntentID(rawValue: "withdraw"),
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:386:            title: "Withdraw",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:387:            cost: "No cost",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:388:            consequence: "Leaves the board",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:393:                : recruitment?.phase == .signed ? "This prospect has signed"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:394:                : recruitment?.phase == .released ? "This prospect was released"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:395:                : recruitment?.phase == .committed ? "This prospect is committed to this programme"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:396:                : "This prospect is not on an active board"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:417:                stableID: "\(programme.id.uuidString)-\(position.rawValue)",
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:436:        case "addToBoard": return .addToBoard
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:437:        case "contact": return .contact(points: CollegeRules.aiEvaluationContactPoints)
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:438:        case "evaluate": return .evaluate(points: CollegeRules.aiEvaluationContactPoints)
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:439:        case "scheduleVisit": return .scheduleVisit
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:440:        case "offerScholarship": return .offerScholarship
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:441:        case "withdraw": return .withdraw
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:448:        case .proximity: return "Proximity"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:449:        case .prestige: return "Prestige"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:450:        case .playingTime: return "Playing time"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:451:        case .schemeFit: return "Scheme fit"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:452:        case .relationship: return "Relationship"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:453:        case .staffQuality: return "Staff quality"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:454:        case .teamSuccess: return "Team success"
Sources/CoachWorldApp/CoachWorldRecruitingBoardProvider.swift:455:        case .nilOpportunity: return "NIL"
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:72:            snapshotID: snapshotID("map", programme.id, calendar),
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:117:                    conferenceRecord: "\(standing.conferenceWins)\u{2013}\(standing.conferenceLosses)",
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:118:                    overallRecord: "\(standing.wins)\u{2013}\(standing.losses)",
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:152:            regionName: regionsByID[city.regionID]?.name ?? "Region not set",
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:167:    /// Re-sorting here would be a second definition of "strongest" that could drift from the one
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:192:    /// asks "do these two share the id in this slot". A professional `Rivalry.origin` of
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:195:    /// Calling it "Conference" would restate a different, larger group under the word for a smaller
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:198:        let sharedGroup = tierLabel == LeagueMapReadModel.Tier.professional ? "Division" : "Conference"
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:200:        case .geography: return "Neighbours"
Sources/CoachWorldApp/CoachWorldLeagueMapProvider.swift:202:        case .both: return "\(sharedGroup) neighbours"
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:8:/// The week hub already answers "who are we, what is our record, who is next", and resolving that
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:22:            ?? hub.opponent.map { "\(hub.week.currentDay) \u{00B7} \($0.name)" }
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:58:            (.coachingHQ, "calendar", "Week"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:59:            (.inbox, "tray.full", "Inbox"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:60:            (.roster, "person.2", "Squad"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:61:            (.gamePlan, "rectangle.3.group", "Plan"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:62:            (.opponentReportFilmRoom, "film", "Film"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:63:            (.teamHealth, "cross.case", "Health"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:65:            (.worldSearch, "square.grid.3x3", "All 62"),
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:72:                intentID: .init(rawValue: "route|\(entry.0.rawValue)")
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:85:                intentID: .init(rawValue: "route|\(sibling.rawValue)")
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:92:        let parts = intentID.rawValue.split(separator: "|")
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:93:        guard parts.count == 2, parts[0] == "route", let raw = Int(parts[1]) else { return nil }
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:109:        case .administration: "Athletic dir."
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:110:        case .boosters: "Boosters"
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:111:        case .fanbase: "Fanbase"
Sources/CoachWorldApp/CoachWorldChromeProvider.swift:112:        case .lockerRoom: "Locker room"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:50:        let commentary = interruption.map { "\($0.message)" }
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:51:            ?? "The next recorded snap belongs to \(possession == .home ? teamReference(game.homeID, in: state).name : teamReference(game.awayID, in: state).name)."
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:71:                stableID: "\(fixtureID.uuidString)-\(session.revision)",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:79:            recordedOutcomeID: "\(fixtureID.uuidString)-\(session.nextDriveIndex)",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:92:            // an away game still gets "our" scorebug treatment rather than the home team's.
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:158:                    uniformNumber: numbers[actor.playerID].map(String.init) ?? "",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:235:        let prefix = "match|\(fixtureID.uuidString)|\(session.revision)|"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:241:                    value: session.pendingCallIn == nil ? "Next snap" : "Call-in pending",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:244:                    intentID: .init(rawValue: prefix + "advance")
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:250:                    id: id, value: "Speed", isEnabled: !session.completed, isSelected: false,
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:256:                    value: session.isPaused ? "Resume" : "Pause",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:264:                    value: session.isTakeover ? "Hand back" : "Take over",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:269:                    intentID: .init(rawValue: prefix + "takeover")
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:276:                    id: id, value: "Adjust",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:305:        let actionPrefix = "match|\(fixtureID.uuidString)|\(session.revision)|callin|"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:309:                intentID: .init(rawValue: actionPrefix + "accept|" + acceptAction.rawValue),
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:310:                title: proposal.options.first(where: { $0.action == acceptAction })?.title ?? "Accept recommendation",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:311:                cost: "Applies to future snaps",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:312:                consequence: "The completed snaps remain unchanged."
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:316:                intentID: .init(rawValue: actionPrefix + "dismiss|" + TacticalCallInAction.trustCoordinator.rawValue),
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:317:                title: "Keep current plan",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:318:                cost: "No extra adjustment",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:319:                consequence: "Keep the installed plan for this decision."
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:323:                intentID: .init(rawValue: actionPrefix + "inspect"),
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:324:                title: "Inspect evidence",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:325:                cost: "No commitment",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:326:                consequence: "Review the trigger and recorded situation."
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:330:            stableID: "\(fixtureID.uuidString)-callin-\(session.callInReceipts.count)",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:336:            message: "Staff flagged \(proposal.trigger.label.lowercased()) before the next snap.",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:338:                "Trigger: \(proposal.trigger.label)",
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:339:                "Down \(proposal.situation.down), \(proposal.situation.distance) to go at yard line \(proposal.situation.yardLine)."
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:347:        case .passer: return "P"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:348:        case .blocker: return "B"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:349:        case .routeRunner: return "RR"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:350:        case .carrier: return "C"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:351:        case .decoy: return "D"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:352:        case .rusher: return "R"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:353:        case .coverage: return "CV"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:354:        case .runFit: return "FIT"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:355:        case .kicker: return "K"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:356:        case .blockLeverage: return "BL"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:362:        case .headCoach: return "Head coach"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:363:        case .offensiveCoordinator: return "Offensive coordinator"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:364:        case .defensiveCoordinator: return "Defensive coordinator"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:365:        case .specialTeamsCoordinator: return "Special teams coordinator"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:366:        case .strengthCoordinator: return "Strength coordinator"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:367:        case .positionCoach: return "Position coach"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:373:        case .quarterback: return "QB"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:374:        case .runningBack: return "RB"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:375:        case .wideReceiver: return "WR"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:376:        case .tightEnd: return "TE"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:377:        case .leftTackle: return "LT"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:378:        case .guardPosition: return "G"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:379:        case .center: return "C"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:380:        case .rightTackle: return "RT"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:383:        // shorthands for that reason. "EDGE" truncated to an ellipsis on the field.
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:384:        case .edgeRusher: return "DE"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:385:        case .defensiveTackle: return "DT"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:386:        case .linebacker: return "LB"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:387:        case .cornerback: return "CB"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:388:        case .safety: return "S"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:389:        case .kicker: return "K"
Sources/CoachWorldApp/CoachWorldMatchProvider.swift:390:        case .punter: return "P"
Sources/CoachWorldApp/CoachWorldNewsProvider.swift:10:            snapshotID: "news-\(state.league.id.uuidString)-\(state.calendar.season)-\(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldNewsProvider.swift:13:            weekLabel: "Season \(state.calendar.season) · Week \(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldNewsProvider.swift:17:                    occurred: "Season \($0.occurredAt.season) · Week \($0.occurredAt.week)",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:25:            let stableID = "decision:" + decision.id.uuidString
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:31:                "\(CoachWorldReadModelProvider.label($0.code)) \($0.value)"
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:34:                ? "A response is required before the listed deadline."
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:35:                : "What is on the desk: " + reasons.joined(separator: " · ")
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:39:                sourceLabel: "Decision desk",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:42:                received: "Received " + weekLabel(decision.createdAt),
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:43:                deadline: "Due " + weekLabel(decision.deadline),
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:58:                title = "Game plan required"
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:61:                title = "Practice plan required"
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:64:            let stableID = "task:" + requirement.rawValue + "-" + String(state.calendar.season)
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:65:                + "-" + String(state.calendar.week)
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:69:                sourceLabel: "Weekly preparation",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:71:                body: "Commit the current-week plan before the controlled fixture can continue.",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:72:                received: "Week " + String(state.calendar.week),
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:73:                deadline: "Before the next game",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:88:            let stableID = "story:" + story.eventID.uuidString
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:92:                sourceLabel: "World history",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:94:                body: "Typed event " + String(event.sequence) + " from the simulation ledger.",
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:95:                received: "Week " + String(event.occurredAt.week),
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:103:            snapshotID: "inbox-" + organisationID.uuidString + "-"
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:104:                + String(state.calendar.season) + "-" + String(state.calendar.week),
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:114:                : "Resolve the current weekly obligation before continuing."
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:122:            entityName = state.prospects[prospectID].map { "\($0.firstName) \($0.lastName)" } ?? "prospect"
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:124:            entityName = state.players[playerID]?.fullName ?? "player"
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:127:        case .recruiting: return "Recruiting decision · " + entityName
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:128:        case .portalRetention: return "Portal retention · " + entityName
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:129:        case .redshirt: return "Redshirt decision · " + entityName
Sources/CoachWorldApp/CoachWorldInboxProvider.swift:130:        case .nilAllocation: return "NIL allocation · " + entityName
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:30:                id: "pro-management:release:\(player.id.uuidString)",
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:31:                title: "Release",
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:32:                detail: "Add remaining guarantees to dead money.",
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:37:                    : "The active roster needs one more \(positionLabel(player.position))."
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:52:            .compactMap { row($0, kind: "Active", isActive: true) }
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:55:            .compactMap { row($0, kind: "Practice squad", isActive: false) }
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:78:            snapshotID: snapshotID("pro-management", team.id, state.calendar),
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:98:        case .quarterback: return "Quarterback"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:99:        case .runningBack: return "Running back"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:100:        case .wideReceiver: return "Wide receiver"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:101:        case .tightEnd: return "Tight end"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:102:        case .leftTackle: return "Left tackle"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:103:        case .guardPosition: return "Guard"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:104:        case .center: return "Center"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:105:        case .rightTackle: return "Right tackle"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:106:        case .edgeRusher: return "Edge rusher"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:107:        case .defensiveTackle: return "Defensive tackle"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:108:        case .linebacker: return "Linebacker"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:109:        case .cornerback: return "Cornerback"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:110:        case .safety: return "Safety"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:111:        case .kicker: return "Kicker"
Sources/CoachWorldApp/CoachWorldProManagementProvider.swift:112:        case .punter: return "Punter"
Sources/CoachWorldApp/CoachWorldStore.swift:80:        presentation: CareerPresentationState = CareerPresentationState(route: "8"),
Sources/CoachWorldApp/CoachWorldStore.swift:144:        firstName: String = "",
Sources/CoachWorldApp/CoachWorldStore.swift:145:        lastName: String = "",
Sources/CoachWorldApp/CoachWorldStore.swift:179:                presentation: CareerPresentationState(route: "8"),
Sources/CoachWorldApp/CoachWorldStore.swift:303:            statusMessage = "Development evidence is unavailable for that player"
Sources/CoachWorldApp/CoachWorldStore.swift:306:        statusMessage = "Development evidence opened for \(row.person.name)"
Sources/CoachWorldApp/CoachWorldStore.swift:323:            statusMessage = "No current opponent film evidence is recorded."
Sources/CoachWorldApp/CoachWorldStore.swift:326:        statusMessage = "Opponent film: \(observation.sampleSize) source games, \(observation.confidence)% confidence, \(observation.passRate)% pass rate, \(observation.turnoverRate)% turnover rate."
Sources/CoachWorldApp/CoachWorldStore.swift:355:            statusMessage = "That opportunity is no longer available"
Sources/CoachWorldApp/CoachWorldStore.swift:387:            statusMessage = "There is no delegable responsibility at this checkpoint"
Sources/CoachWorldApp/CoachWorldStore.swift:407:            statusMessage = "No employed staff member can take this responsibility"
Sources/CoachWorldApp/CoachWorldStore.swift:417:            statusMessage = "Delegated \(decision.responsibility.rawValue) to \(staff.fullName)"
Sources/CoachWorldApp/CoachWorldStore.swift:424:        let parts = intentID.rawValue.split(separator: "|", omittingEmptySubsequences: false)
Sources/CoachWorldApp/CoachWorldStore.swift:426:              parts[0] == "match",
Sources/CoachWorldApp/CoachWorldStore.swift:429:            statusMessage = "That match action is no longer available"
Sources/CoachWorldApp/CoachWorldStore.swift:432:        if parts[3] == "pause" {
Sources/CoachWorldApp/CoachWorldStore.swift:442:        if parts[3] == "takeover" {
Sources/CoachWorldApp/CoachWorldStore.swift:452:        if parts[3] == "advance" {
Sources/CoachWorldApp/CoachWorldStore.swift:464:        // "tactics", so reaching here means either a stale intent or a submitted plan. The three
Sources/CoachWorldApp/CoachWorldStore.swift:467:        if parts[3] == "tactics" {
Sources/CoachWorldApp/CoachWorldStore.swift:475:                statusMessage = "That tactical plan is no longer available"
Sources/CoachWorldApp/CoachWorldStore.swift:488:        guard parts.count >= 5, parts[3] == "callin" else {
Sources/CoachWorldApp/CoachWorldStore.swift:489:            statusMessage = "That match action is unavailable at this checkpoint"
Sources/CoachWorldApp/CoachWorldStore.swift:492:        if parts[4] == "inspect" { return }
Sources/CoachWorldApp/CoachWorldStore.swift:493:        let actionIndex = parts[4] == "accept" || parts[4] == "dismiss" ? 5 : 4
Sources/CoachWorldApp/CoachWorldStore.swift:496:            statusMessage = "That call-in choice is no longer available"
Sources/CoachWorldApp/CoachWorldStore.swift:516:            statusMessage = "That choice is no longer available"
Sources/CoachWorldApp/CoachWorldStore.swift:532:            statusMessage = "That recruiting action is no longer available"
Sources/CoachWorldApp/CoachWorldStore.swift:563:            return "That action could not be completed. Nothing was changed."
Sources/CoachWorldApp/CoachWorldStore.swift:567:            return "No career is under your control."
Sources/CoachWorldApp/CoachWorldStore.swift:569:            let work = requirements.map(Self.preparationName).joined(separator: " and ")
Sources/CoachWorldApp/CoachWorldStore.swift:570:            return "Set the \(work) before the week can advance."
Sources/CoachWorldApp/CoachWorldStore.swift:572:            return "A staff member owns this decision. Take it back to decide it yourself."
Sources/CoachWorldApp/CoachWorldStore.swift:574:            return "That decision is no longer waiting."
Sources/CoachWorldApp/CoachWorldStore.swift:576:            return "That option is no longer available on this decision."
Sources/CoachWorldApp/CoachWorldStore.swift:578:            return "The decision could not be committed. Nothing was changed."
Sources/CoachWorldApp/CoachWorldStore.swift:580:            return "That responsibility could not be reassigned. Nothing was changed."
Sources/CoachWorldApp/CoachWorldStore.swift:582:            return "That action does not apply right now."
Sources/CoachWorldApp/CoachWorldStore.swift:584:            return "A match is already under way."
Sources/CoachWorldApp/CoachWorldStore.swift:586:            return "No match is under way."
Sources/CoachWorldApp/CoachWorldStore.swift:588:            return "That match checkpoint is no longer current."
Sources/CoachWorldApp/CoachWorldStore.swift:590:            return "The match could not accept that action. The recorded moment is unchanged."
Sources/CoachWorldApp/CoachWorldStore.swift:598:        case .gamePlan: return "game plan"
Sources/CoachWorldApp/CoachWorldStore.swift:599:        case .practicePlan: return "practice plan"
Sources/CoachWorldApp/CoachWorldOpponentFilmProvider.swift:24:            snapshotID: "film-" + observerID.uuidString + "-"
Sources/CoachWorldApp/CoachWorldOpponentFilmProvider.swift:25:                + String(state.calendar.season) + "-" + String(state.calendar.week),
Sources/CoachWorldApp/CoachWorldOpponentFilmProvider.swift:38:                    ? "No scheduled opponent is available for this week."
Sources/CoachWorldApp/CoachWorldOpponentFilmProvider.swift:39:                    : "No current observer-scoped film has been retained for this opponent.")
Sources/CoachWorldApp/CoachWorldStaffRoomProvider.swift:24:            snapshotID: snapshotID("staff-room", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:17:                id: "current-\(programme.id.uuidString)",
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:19:                tier: "College",
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:29:                id: "current-\(programme.id.uuidString)",
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:31:                tier: "College",
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:36:                id: "current-\(job.organisationID.uuidString)",
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:56:                        + "-\(entry.job.startedAt.season)-\(entry.job.startedAt.week)",
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:91:                    unavailableReason = "Only professional offers are actionable here."
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:93:                    unavailableReason = "This offer has expired."
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:95:                    unavailableReason = "A professional appointment is already active."
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:97:                    unavailableReason = "This offer is not active yet."
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:99:                    unavailableReason = "The coach is not currently eligible to accept this offer."
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:127:            snapshotID: snapshotID("career", coachID, state.calendar),
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:144:        tier == .college ? "College" : "Professional"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:149:        case .employed: return "Employed"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:150:        case .fired: return "Fired"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:151:        case .seeking: return "Seeking"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:157:        case .fired: return "Fired"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:158:        case .promoted: return "Promoted"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:159:        case .resigned: return "Resigned"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:165:        case .sustainedCollegeSuccess: return "Sustained college success"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:166:        case .rivalryWin: return "Rivalry win"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:167:        case .staffRecommendation: return "Staff recommendation"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:173:        case .administration: return "Administration"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:174:        case .boosters: return "Boosters"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:175:        case .fanbase: return "Fanbase"
Sources/CoachWorldApp/CoachWorldCareerProvider.swift:176:        case .lockerRoom: return "Locker room"
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:10:            ("Passing yards", { $0.passingYards }),
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:11:            ("Rushing yards", { $0.rushingYards }),
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:12:            ("Receiving yards", { $0.receivingYards }),
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:13:            ("Touchdowns", { $0.touchdowns })
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:28:                    id: category + "-" + player.id.uuidString,
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:40:            snapshotID: snapshotID("statistics", state.league.id, state.calendar),
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:51:            .merging(state.proTeams.values.map { ($0.id, "\($0.cityName) \($0.nickname)") }, uniquingKeysWith: { first, _ in first })
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:58:                        id: "\(archive.season)-\(index)-\(award.winnerID.uuidString)",
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:60:                        winner: names[award.winnerID] ?? "Unknown winner",
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:63:                        seasonLabel: "Season \(archive.season + 1)"
Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:68:            snapshotID: snapshotID("awards", state.league.id, state.calendar),
Sources/CoachWorldApp/CoachWorldTeamHealthProvider.swift:15:                lifecycle.injury.map { "Injury \($0.weeksRemaining) week(s) remaining" },
Sources/CoachWorldApp/CoachWorldTeamHealthProvider.swift:16:                lifecycle.suspension.map { "Suspension \($0.weeksRemaining) week(s) remaining" }
Sources/CoachWorldApp/CoachWorldTeamHealthProvider.swift:19:                ? (lifecycle.fatigue == 0 ? "No recorded fatigue" : "Fatigue is recorded")
Sources/CoachWorldApp/CoachWorldTeamHealthProvider.swift:20:                : absences.joined(separator: " · ")
Sources/CoachWorldApp/CoachWorldTeamHealthProvider.swift:46:            snapshotID: "health-\(roster.team.stableID)-\(state.calendar.season)-\(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:17:/// engine does hold is this layer's job and is not invention: `Position.quarterback` becoming "QB"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:49:            snapshotID: snapshotID("hq", organisationID, calendar),
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:66:                // "current day" a 7-day strip would name does not exist. Naming the week is the
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:70:                    .map { "Due \(weekLabel($0))" } ?? "No deadline this week"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:109:                    status: "Out \(injury.weeksRemaining)w", isConcern: true
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:115:                    status: "Susp \(suspension.weeksRemaining)w", isConcern: true
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:121:                status: "Flg \(row.condition)", isConcern: true
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:147:                id: "balanced",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:148:                title: "Balanced control",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:150:                consequence: "Keeps tempo, run/pass balance, and pressure near the staff baseline."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:153:                id: "pressure",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:154:                title: "Pressure the quarterback",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:160:                consequence: "Adds early-down pressure and run support while accepting tempo cost."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:163:                id: "pace",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:164:                title: "Play with pace",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:170:                consequence: "Creates more passing volume and pace while reducing defensive aggression."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:174:            snapshotID: snapshotID("game-plan", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:192:                id: "balanced",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:193:                title: "Balanced week",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:195:                consequence: "Splits the 60 minutes across install, conditioning, recovery, and focus."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:198:                id: "install",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:199:                title: "Install and sharpen",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:207:                consequence: "Improves scheme installation while reducing recovery time."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:210:                id: "recovery",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:211:                title: "Recover and condition",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:219:                consequence: "Protects readiness and conditioning while installing less."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:223:            snapshotID: snapshotID("practice-plan", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:270:                    id: "\(position.rawValue)-\(playerID.uuidString)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:273:                    availability: available ? "Available" : "Unavailable · fallback applies",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:298:                id: "derived",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:299:                title: "Use derived depth",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:305:                consequence: "The best available player at each position starts automatically."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:308:                id: "availability-first",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:309:                title: "Lock available depth",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:315:                consequence: "Saves the current available order and falls back when availability changes."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:318:                id: "rotate-backups",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:319:                title: "Rotate first backups",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:325:                consequence: "Uses the second available player before the derived starter where legal."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:329:            snapshotID: snapshotID("depth-chart", organisationID, state.calendar),
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:348:        case .quarterback: return "Quarterback"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:349:        case .runningBack: return "Running back"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:350:        case .wideReceiver: return "Wide receiver"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:351:        case .tightEnd: return "Tight end"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:352:        case .leftTackle: return "Left tackle"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:353:        case .guardPosition: return "Guard"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:354:        case .center: return "Center"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:355:        case .rightTackle: return "Right tackle"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:356:        case .edgeRusher: return "Edge rusher"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:357:        case .defensiveTackle: return "Defensive tackle"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:358:        case .linebacker: return "Linebacker"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:359:        case .cornerback: return "Cornerback"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:360:        case .safety: return "Safety"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:361:        case .kicker: return "Kicker"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:362:        case .punter: return "Punter"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:386:        let action = recommended.map { label($0.action) } ?? "the balanced option"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:387:        let reason = decision.reasons.prefix(2).map(evidence).joined(separator: " · ")
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:398:            verdict: "Recommend \(action)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:399:            reason: reason.isEmpty ? "No recorded reason" : reason,
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:400:            confidence: "\(confidence)%"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:419:            "\($0.boardIDs.count) prospects · \($0.contactPointsRemaining) pts"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:420:        } ?? "Not available"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:425:            gameStatus = plan == nil ? "Needs plan · vs \(opponent)" : "Plan set · vs \(opponent)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:427:            gameStatus = "No game scheduled"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:431:                stableID: "\(programmeID)-inbox-\(state.calendar.season)-\(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:432:                dayLabel: "Inbox",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:433:                assignment: decisions.isEmpty ? "Clear" : "\(decisions.count) due",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:437:                stableID: "\(programmeID)-game-plan-\(state.calendar.season)-\(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:438:                dayLabel: "Game plan",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:443:                stableID: "\(programmeID)-practice-\(state.calendar.season)-\(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:444:                dayLabel: "Practice",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:445:                assignment: practiceMinutes == 0 ? "Planned" : "\(practiceMinutes) min open",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:449:                stableID: "\(programmeID)-recruiting-\(state.calendar.season)-\(state.calendar.week)",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:450:                dayLabel: "Recruiting",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:459:        CoachWorldReference(stableID: state.league.id.uuidString, name: "Football Universe")
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:465:            ?? state.proTeams[id].map { "\($0.cityName) \($0.nickname)" }
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:466:            ?? "Unknown team"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:479:            stableID: "\(organisationID.uuidString)-venue",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:480:            name: state.identities[organisationID]?.venueName ?? "Venue not set"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:493:        "\(kind)-\(calendar.season)-\(calendar.week)-\(id.uuidString)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:508:        guard let row = standingRow(organisationID, in: state) else { return "0-0" }
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:509:        return "\(row.wins)-\(row.losses)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:523:            if let index = order.firstIndex(of: organisationID) { return "#\(index + 1)" }
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:529:        "Season \(calendar.season + 1)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:532:    static func weekLabel(_ calendar: CalendarState) -> String { "Week \(calendar.week)" }
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:582:                    cost: "This week",
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:584:                        ? "The staff recommendation"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:585:                        : ""
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:594:        case .recruiting: return "Recruiting: \(name)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:595:        case .portalRetention: return "Transfer portal: \(name)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:596:        case .redshirt: return "Redshirt: \(name)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:597:        case .nilAllocation: return "NIL allocation: \(name)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:603:    static let mandatoryConsequence = "The week cannot advance while this is open."
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:609:            return "\(departed.firstName) \(departed.lastName)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:611:        return "Unnamed"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:617:        "\(label(reason.code)): \(reason.value)"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:624:        case .headCoach: return "Head coach"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:625:        case .offensiveCoordinator: return "Offensive coordinator"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:626:        case .defensiveCoordinator: return "Defensive coordinator"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:627:        case .specialTeamsCoordinator: return "Special teams coordinator"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:628:        case .strengthCoordinator: return "Strength coordinator"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:629:        case .positionCoach: return "Position coach"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:636:        case .portalRetention: return "Keep"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:637:        case .portalRelease: return "Release"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:638:        case let .redshirt(limit): return limit == nil ? "No redshirt" : "Redshirt"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:639:        case .nilAllocation: return "Set NIL"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:645:        case .addToBoard: return "Add to board"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:646:        case .contact: return "Contact"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:647:        case .evaluate: return "Evaluate"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:648:        case .scheduleVisit: return "Schedule visit"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:649:        case .offerScholarship: return "Offer scholarship"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:650:        case .setNILAllocation: return "Set NIL"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:651:        case .withdraw: return "Withdraw"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:657:        case .rosterNeed: return "Roster need"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:658:        case .rosterPath: return "Roster path"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:659:        case .scholarshipCapacity: return "Scholarship capacity"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:660:        case .nilBudget: return "NIL budget"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:661:        case .playingTime: return "Playing time"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:662:        case .relationship: return "Relationship"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:663:        case .teamSuccess: return "Team success"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:664:        case .restless: return "Restlessness"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:665:        case .eligibility: return "Eligibility"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:666:        case .fit: return "Scheme fit"
Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:667:        case .deadline: return "Deadline"
Sources/CoachWorldApp/CoachWorldCareerEntryProvider.swift:31:        return "Target performance \(target)"
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:16:                seasonLabel: "Season \(season + 1)",
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:17:                reason: reason == .geographicFit ? "Geographic fit" : reason.rawValue,
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:20:                        id: swap.firstProgrammeID.uuidString + "-" + swap.secondProgrammeID.uuidString,
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:21:                        firstProgramme: state.programmes[swap.firstProgrammeID]?.name ?? "Unknown programme",
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:22:                        secondProgramme: state.programmes[swap.secondProgrammeID]?.name ?? "Unknown programme",
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:32:            snapshotID: snapshotID("realignment", state.league.id, state.calendar),
Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:40:        state.league.conferences.first(where: { $0.id == id })?.name ?? "Unknown conference"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:14:        public static let college = "College"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:15:        public static let professional = "Professional"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:22:        /// "this region produces more talent" and nothing more.
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:45:        /// zero-based season, which would contradict the "Season N+1" labels used everywhere else
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:209:/// The DEBUG proof fixture. `provenance: .sample` is what the "SAMPLE CAREER" flag reads, and a
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:218:        snapshotID: "map-sample",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:220:        world: CoachWorldReference(stableID: "world-sample", name: "Football Universe"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:222:            stableID: "team-carson",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:223:            name: "Carson Tech",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:224:            abbreviation: "CAR",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:225:            primaryColorHex: "2F6DB5",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:226:            secondaryColorHex: "E8B23A"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:229:            stableID: "coach-mercer",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:230:            name: "Eric Mercer",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:231:            role: "Head Coach"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:233:        seasonLabel: "Season 1",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:234:        weekLabel: "Week 9",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:235:        recordLabel: "6-2",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:236:        rankLabel: "#18",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:241:                stableID: "region-north",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:242:                name: "Kessel Reach",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:246:                stableID: "region-south",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:247:                name: "Marlow Basin",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:253:                stableID: "team-carson",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:255:                    stableID: "team-carson",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:256:                    name: "Carson Tech",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:257:                    abbreviation: "CAR",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:258:                    primaryColorHex: "2F6DB5",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:259:                    secondaryColorHex: "E8B23A"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:261:                cityName: "Carson Hollow",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:262:                regionID: "region-north",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:263:                regionName: "Kessel Reach",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:264:                conferenceName: "Northern Reach Conference",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:265:                tierLabel: "College",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:271:                venueName: "Carson Hollow Grounds",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:274:                        stableID: "team-southern",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:275:                        name: "Southern State",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:276:                        originLabel: "Conference neighbours",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:282:                stableID: "team-southern",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:284:                    stableID: "team-southern",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:285:                    name: "Southern State",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:286:                    abbreviation: "SOU",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:287:                    primaryColorHex: "8E3B4F",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:288:                    secondaryColorHex: "D9D2C4"
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:290:                cityName: "Marlow Flats",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:291:                regionID: "region-south",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:292:                regionName: "Marlow Basin",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:293:                conferenceName: "Northern Reach Conference",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:294:                tierLabel: "College",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:300:                venueName: "Marlow Flats Field",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:303:                        stableID: "team-carson",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:304:                        name: "Carson Tech",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:305:                        originLabel: "Conference neighbours",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:312:            .init(stableID: "cs-1", team: CoachWorldTeamReference(
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:313:                stableID: "team-halloran", name: "Halloran Tech", abbreviation: "HAL"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:314:                conferenceRecord: "4\u{2013}0", overallRecord: "5\u{2013}1",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:316:            .init(stableID: "cs-2", team: CoachWorldTeamReference(
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:317:                stableID: "team-cobalt", name: "Cobalt Valley", abbreviation: "COB"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:318:                conferenceRecord: "3\u{2013}1", overallRecord: "5\u{2013}2",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:320:            .init(stableID: "cs-3", team: CoachWorldTeamReference(
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:321:                stableID: "team-carson", name: "Carson Tech", abbreviation: "CAR"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:322:                conferenceRecord: "3\u{2013}1", overallRecord: "4\u{2013}2",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:324:            .init(stableID: "cs-4", team: CoachWorldTeamReference(
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:325:                stableID: "team-ellenwood", name: "Ellenwood", abbreviation: "ELL"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:326:                conferenceRecord: "3\u{2013}2", overallRecord: "4\u{2013}3",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:328:            .init(stableID: "cs-5", team: CoachWorldTeamReference(
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:329:                stableID: "team-cedar", name: "Cedar Falls", abbreviation: "CED"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:330:                conferenceRecord: "2\u{2013}3", overallRecord: "3\u{2013}4",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:332:            .init(stableID: "cs-6", team: CoachWorldTeamReference(
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:333:                stableID: "team-marchmont", name: "Marchmont", abbreviation: "MAR"),
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:334:                conferenceRecord: "1\u{2013}3", overallRecord: "2\u{2013}5",
Sources/ProFootballCoachUI/LeagueMapReadModels.swift:337:        conferenceName: "Northern Reach Conference"
Sources/ProFootballCoachUI/StaffRoomReadModels.swift:34:            case .headCoach: return "Head coach"
Sources/ProFootballCoachUI/StaffRoomReadModels.swift:35:            case .offensiveCoordinator: return "Offensive coordinator"
Sources/ProFootballCoachUI/StaffRoomReadModels.swift:36:            case .defensiveCoordinator: return "Defensive coordinator"
Sources/ProFootballCoachUI/StaffRoomReadModels.swift:37:            case .specialTeamsCoordinator: return "Special teams coordinator"
Sources/ProFootballCoachUI/StaffRoomReadModels.swift:38:            case .strengthCoordinator: return "Strength coordinator"
Sources/ProFootballCoachUI/StaffRoomReadModels.swift:39:            case .positionCoach: return "Position coach"
Sources/ProFootballCoachUI/PersonnelReadModels.swift:85:        developmentEvidence: String = "",
Sources/ProFootballCoachUI/PersonnelReadModels.swift:86:        historyEvidence: String = ""
Sources/ProFootballCoachUI/PersonnelReadModels.swift:225:            let person = CoachWorldPersonReference(stableID: "\(id)-person", name: name, role: position)
Sources/ProFootballCoachUI/PersonnelReadModels.swift:227:                .init(stableID: "\(id)-\(key)", title: title, attributes: zip(labels, values).enumerated().map { index, pair in
Sources/ProFootballCoachUI/PersonnelReadModels.swift:228:                    .init(stableID: "\(id)-\(key)-\(index)", label: pair.0, value: pair.1, confidence: "Known")
Sources/ProFootballCoachUI/PersonnelReadModels.swift:231:            let profile = PlayerProfileReadModel(stableID: "\(id)-profile", person: person, number: number, position: position, overall: overall, academicYear: year, hometown: hometown, rosterRole: role, availability: availability, condition: condition, schemeFit: fit, staffSummary: summary, strengths: strengths, concern: concern, attributeGroups: [
Sources/ProFootballCoachUI/PersonnelReadModels.swift:232:                group("athletic", "Athletic", ["Speed", "Strength", "Stamina"], athletic),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:233:                group("technical", "Technical", ["Technique", "Position Skill", "Ball Security"], technical),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:234:                group("mental", "Mental", ["Decisions", "Awareness", "Leadership"], mental),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:235:            ], recentForm: zip(["SOU", "WST", "MET"], form).enumerated().map { index, pair in
Sources/ProFootballCoachUI/PersonnelReadModels.swift:236:                .init(stableID: "\(id)-form-\(index)", opponent: pair.0, rating: pair.1)
Sources/ProFootballCoachUI/PersonnelReadModels.swift:241:        return RosterReadModel(snapshotID: "sample-roster-snapshot", provenance: .sample, world: world, team: homeTeam, coach: headCoach, seasonLabel: "2027 season", weekLabel: "Week 9", recordLabel: "6–2", rankLabel: "#19", rosterLimit: 85, injuryCount: 2, openNeedCount: 3, players: [
Sources/ProFootballCoachUI/PersonnelReadModels.swift:242:            makePlayer(id: "sample-roster-bishop", number: 12, name: "Andre Bishop", position: "QB", year: "SR", role: "Captain · Starter", overall: 91, development: 78, developmentDelta: 1, fit: "Elite", condition: 96, availability: "Available", hometown: "Calder Springs, Thornby Reach", strengths: ["Deep accuracy", "Pressure control"], concern: "Late movement can hold the ball too long", summary: "Commands the offense and protects high-leverage downs.", athletic: [82, 76, 88], technical: [92, 94, 89], mental: [91, 93, 90], form: [88, 91, 86]),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:243:            makePlayer(id: "sample-roster-ward", number: 24, name: "Jalen Ward", position: "RB", year: "JR", role: "Starter", overall: 88, development: 86, developmentDelta: 0, fit: "Strong", condition: 91, availability: "Available", hometown: "Marrow Bend, Fenmark Flats", strengths: ["Contact balance", "Cut timing"], concern: "Pass protection remains inconsistent", summary: "Creates efficient early downs without wasting carries.", athletic: [91, 87, 90], technical: [86, 90, 84], mental: [85, 87, 79], form: [90, 84, 89]),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:244:            makePlayer(id: "sample-roster-okafor", number: 6, name: "Miles Okafor", position: "WR", year: "SO", role: "Rotation", overall: 84, development: 92, developmentDelta: 1, fit: "Strong", condition: 100, availability: "Available", hometown: "Harrow Landing, Redmoor Coast", strengths: ["Release burst", "Open-field acceleration"], concern: "Boundary route detail is unfinished", summary: "The highest-upside receiver on the roster.", athletic: [94, 72, 86], technical: [83, 85, 80], mental: [79, 82, 68], form: [82, 87, 80]),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:245:            makePlayer(id: "sample-roster-alvarez", number: 72, name: "Tomas Alvarez", position: "OT", year: "SR", role: "Starter", overall: 87, development: 74, developmentDelta: -1, fit: "Elite", condition: 88, availability: "Limited", hometown: "Pellham Mills, Dunmore Basin", strengths: ["Pass anchor", "Length"], concern: "Ankle limits lateral recovery", summary: "Reliable blind-side protection when healthy.", athletic: [76, 93, 82], technical: [90, 91, 88], mental: [86, 89, 84], form: [85, 88, 83]),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:246:            makePlayer(id: "sample-roster-webb", number: 87, name: "Darius Webb", position: "EDGE", year: "JR", role: "Starter", overall: 89, development: 88, developmentDelta: 1, fit: "Elite", condition: 94, availability: "Available", hometown: "Larkin Crossing, Gallow Uplands", strengths: ["First step", "Counter timing"], concern: "Can lose run leverage chasing pressure", summary: "Changes passing downs and forces protection help.", athletic: [93, 86, 89], technical: [88, 92, 81], mental: [84, 86, 78], form: [92, 89, 90]),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:247:            makePlayer(id: "sample-roster-reed", number: 55, name: "Marcus Reed", position: "MLB", year: "SR", role: "Captain · Starter", overall: 90, development: 76, developmentDelta: 0, fit: "Strong", condition: 97, availability: "Available", hometown: "Oakhaven Bluff, Netherby Divide", strengths: ["Run fits", "Communication"], concern: "Man coverage range is ordinary", summary: "Sets the front and prevents alignment errors.", athletic: [84, 89, 91], technical: [87, 90, 82], mental: [94, 95, 93], form: [89, 90, 91]),
Sources/ProFootballCoachUI/PersonnelReadModels.swift:248:            makePlayer(id: "sample-roster-brooks", number: 9, name: "Elijah Brooks", position: "CB", year: "SO", role: "Nickel", overall: 82, development: 94, developmentDelta: 1, fit: "Good", condition: 99, availability: "Available", hometown: "Wexford Harbor, Yarrow Tidelands", strengths: ["Press timing", "Recovery speed"], concern: "Route recognition varies snap to snap", summary: "Already playable inside with outside-corner upside.", athletic: [95, 70, 87], technical: [82, 84, 79], mental: [76, 78, 71], form: [81, 85, 83]),
Sources/ProFootballCoachUI/ScreenReadModels.swift:663:            ties == 0 ? "\(wins)-\(losses)" : "\(wins)-\(losses)-\(ties)"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1137:/// (handoff MATCH-DAY.md section 5's "control depth selector"), not one of the five primary
Sources/ProFootballCoachUI/ScreenReadModels.swift:1225:    /// Every string here comes from the save. The fixture cast's values ("The Example Bowl", "EC",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1226:    /// "44th annual") are placeholders the handoff flags for the owner — real postseason naming is
Sources/ProFootballCoachUI/ScreenReadModels.swift:1580:    /// Which side is the coach's own program — the design's "our cell" versus "their cell"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1582:    /// independent of this: an away game is still played by "us", and the scorebug's gold rail,
Sources/ProFootballCoachUI/ScreenReadModels.swift:1623:        controlDepthIntentID: CoachWorldIntentID = .init(rawValue: "match-control-depth"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1651:            throw ValidationError.invalidSituation("quarter")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1654:            throw ValidationError.invalidSituation("clock")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1657:            throw ValidationError.invalidSituation("down")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1660:            throw ValidationError.invalidSituation("yardsToGo")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1680:            throw ValidationError.invalidLine("lineOfScrimmage")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1683:            throw ValidationError.invalidLine("firstDownLine")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1688:            throw ValidationError.invalidLine("firstDownDirection")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1806:        stableID: "sample-world",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1807:        name: "Sample Football Universe"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1814:        stableID: "sample-carson",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1815:        name: "Carson Tech",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1816:        abbreviation: "CAR",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1817:        primaryColorHex: "#14382A",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1818:        secondaryColorHex: "#D9B23C"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1821:        stableID: "sample-southern",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1822:        name: "Southern State",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1823:        abbreviation: "SOU",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1824:        primaryColorHex: "#555B66",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1825:        secondaryColorHex: "#D9DDE4"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1828:        stableID: "sample-venue",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1829:        name: "Memorial Field"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1832:        stableID: "sample-coordinator",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1833:        name: "Morgan Hale",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1834:        role: "Defensive coordinator"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1837:        stableID: "sample-head-coach",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1838:        name: "Eric Mercer",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1839:        role: "Head coach"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1856:            (.coachingHQ, "calendar", "Week"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1857:            (.inbox, "tray.full", "Inbox"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1858:            (.roster, "person.2", "Squad"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1859:            (.gamePlan, "rectangle.3.group", "Plan"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1860:            (.opponentReportFilmRoom, "film", "Film"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1861:            (.teamHealth, "cross.case", "Health"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1862:            (.worldSearch, "square.grid.3x3", "All 62"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1868:            record: "4\u{2013}2",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1869:            ranking: "#21",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1870:            conference: "Meridian Valley",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1871:            context: context ?? "Sat \u{00B7} Southern State",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1878:                    intentID: .init(rawValue: "sample-rail-\(entry.0.number)")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1885:                    intentID: .init(rawValue: "sample-sibling-\(sibling.number)")
Sources/ProFootballCoachUI/ScreenReadModels.swift:1893:            stableID: "sample-practice-decision",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1894:            title: "Protect the edge or pressure the pocket?",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1895:            deadline: "Tuesday, 14:00",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1896:            evidence: ["Outside runs win early downs."],
Sources/ProFootballCoachUI/ScreenReadModels.swift:1899:                    intentID: .init(rawValue: "sample-run-fits"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1900:                    title: "Run Fits",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1901:                    cost: "2 hours",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1902:                    consequence: "Lose pressure reps"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1905:                    intentID: .init(rawValue: "sample-pass-rush"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1906:                    title: "Pass Rush",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1907:                    cost: "2 hours",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1908:                    consequence: "Run-fit concern remains"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1913:            snapshotID: "sample-hq-snapshot",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1918:            recordLabel: "6–2",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1919:            rankLabel: "#19",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1922:                seasonLabel: "2027 season",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1923:                weekLabel: "Week 9",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1924:                currentDay: "Monday",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1925:                nextDeadline: "Practice plan due Tuesday, 14:00"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1928:                .init(stableID: "sample-mon", dayLabel: "Mon", assignment: "Rest", isCurrent: true),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1929:                .init(stableID: "sample-tue", dayLabel: "Tue", assignment: "Work", isCurrent: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1930:                .init(stableID: "sample-wed", dayLabel: "Wed", assignment: "Install", isCurrent: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1931:                .init(stableID: "sample-thu", dayLabel: "Thu", assignment: "Polish", isCurrent: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1932:                .init(stableID: "sample-fri", dayLabel: "Fri", assignment: "Travel", isCurrent: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1933:                .init(stableID: "sample-sat", dayLabel: "Sat", assignment: "Game", isCurrent: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1934:                .init(stableID: "sample-sun", dayLabel: "Sun", assignment: "Review", isCurrent: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1940:                    stableID: "sample-obligation",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1941:                    title: "Set practice emphasis",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1942:                    due: "Tuesday, 14:00",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1943:                    consequence: "Staff cannot prepare the install",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1950:                verdict: "Run fits first",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1951:                reason: "The opponent creates its efficient downs outside the tackles.",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1952:                confidence: "Medium"
Sources/ProFootballCoachUI/ScreenReadModels.swift:1956:                    stableID: "sample-message",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1958:                    subject: "First film notes are ready",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1959:                    received: "08:15",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1964:                .init(stableID: "sh-1", slot: "RT", player: "L. Vasquez",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1965:                      status: "Out 2w", isConcern: true),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1966:                .init(stableID: "sh-2", slot: "CB2", player: "M. Lourdes",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1967:                      status: "Flg 71", isConcern: true),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1968:                .init(stableID: "sh-3", slot: "LB2", player: "K. Trace",
Sources/ProFootballCoachUI/ScreenReadModels.swift:1969:                      status: "Cleared", isConcern: false),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1972:                .init(stableID: "sk-1", name: "Athletic dir.", support: 58),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1973:                .init(stableID: "sk-2", name: "Boosters", support: 61),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1974:                .init(stableID: "sk-3", name: "Fanbase", support: 74),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1975:                .init(stableID: "sk-4", name: "Locker room", support: 69),
Sources/ProFootballCoachUI/ScreenReadModels.swift:1999:                    stableID: "\(id)-person",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2016:                        stableID: "\(id)-contact",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2017:                        dateLabel: "Monday",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2024:                        intentID: .init(rawValue: "\(id)-call"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2025:                        title: "Call prospect",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2026:                        cost: "1 recruiting hour",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2027:                        consequence: "Advances this relationship; delays another call"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2030:                        intentID: .init(rawValue: "\(id)-visit"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2031:                        title: "Offer official visit",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2032:                        cost: "1 of 4 remaining visits",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2033:                        consequence: "Creates a commitment window"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2040:            snapshotID: "sample-recruiting-snapshot",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2050:                .init(stableID: "sample-need-qb", position: "QB", target: 1, committed: 0),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2051:                .init(stableID: "sample-need-dl", position: "DL", target: 3, committed: 1),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2052:                .init(stableID: "sample-need-ol", position: "OL", target: 2, committed: 0),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2056:                    id: "sample-prospect-mercer",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2058:                    name: "Jordan Mercer",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2059:                    position: "QB",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2060:                    hometown: "Brack Hollow, Kestrel Marches",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2061:                    interest: "High",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2062:                    status: "Evaluating",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2063:                    verdict: "Starter tools; decision speed remains uncertain",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2064:                    fit: "Strong",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2065:                    uncertainty: "Medium",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2066:                    outliers: ["Deep accuracy", "Pressure response"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2067:                    contact: "Position coach call",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2068:                    effect: "Interest improved"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2071:                    id: "sample-prospect-harris",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2073:                    name: "Malik Harris",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2074:                    position: "EDGE",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2075:                    hometown: "Larkin Crossing, Gallow Uplands",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2076:                    interest: "Medium",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2077:                    status: "Contacted",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2078:                    verdict: "First-step pressure changes passing downs",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2079:                    fit: "Elite",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2080:                    uncertainty: "Low",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2081:                    outliers: ["Burst", "Run anchor"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2082:                    contact: "Coordinator film review",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2083:                    effect: "Family requested depth-chart detail"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2086:                    id: "sample-prospect-alvarez",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2088:                    name: "Mateo Alvarez",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2089:                    position: "OT",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2090:                    hometown: "Pellham Mills, Dunmore Basin",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2091:                    interest: "High",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2092:                    status: "Visit ready",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2093:                    verdict: "Long pass protector with unfinished leverage",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2094:                    fit: "Strong",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2095:                    uncertainty: "Medium",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2096:                    outliers: ["Length", "Pad level"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2097:                    contact: "Family call",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2098:                    effect: "Official visit dates discussed"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2101:                    id: "sample-prospect-brooks",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2103:                    name: "Darius Brooks",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2104:                    position: "CB",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2105:                    hometown: "Wexford Harbor, Yarrow Tidelands",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2106:                    interest: "Low",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2107:                    status: "Watching",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2108:                    verdict: "Press corner traits; recovery speed needs proof",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2109:                    fit: "Good",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2110:                    uncertainty: "High",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2111:                    outliers: ["Press timing", "Recovery speed"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2112:                    contact: "Area scout check-in",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2113:                    effect: "No movement after first contact"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2116:                    id: "sample-prospect-okafor",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2118:                    name: "Nia Okafor",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2119:                    position: "DT",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2120:                    hometown: "Harrow Landing, Redmoor Coast",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2121:                    interest: "Medium",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2122:                    status: "Evaluating",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2123:                    verdict: "Interior disruptor; snap volume is the open question",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2124:                    fit: "Strong",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2125:                    uncertainty: "Medium",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2126:                    outliers: ["Get-off", "Snap volume"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2127:                    contact: "Defensive line coach call",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2128:                    effect: "Requested scheme cut-ups"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2136:            ("12", "QB", 51, 0.50), ("24", "RB", 46, 0.50),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2137:            // Receiver shorthands, not two identical "WR"s: MATCH-DAY.md section 4's offensive
Sources/ProFootballCoachUI/ScreenReadModels.swift:2140:            ("1", "X", 54, 0.08), ("11", "Z", 54, 0.92), ("87", "TE", 55, 0.24),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2141:            ("72", "LT", 56, 0.34), ("65", "LG", 56, 0.42), ("55", "C", 56, 0.50),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2142:            ("68", "RG", 56, 0.58), ("76", "RT", 56, 0.66), ("6", "H", 53, 0.78),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2146:                stableID: "sample-home-\(index)",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2155:            ("3", "CB", 61, 0.08), ("94", "DE", 61, 0.26), ("91", "DT", 61, 0.42),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2156:            ("99", "DT", 61, 0.58), ("90", "DE", 61, 0.74), ("21", "CB", 61, 0.92),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2157:            ("44", "LB", 65, 0.32), ("50", "LB", 65, 0.50), ("32", "LB", 65, 0.68),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2158:            ("7", "FS", 72, 0.38), ("9", "SS", 68, 0.64),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2162:                stableID: "sample-away-\(index)",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2173:                value: control == .speed ? "1×" : nil,
Sources/ProFootballCoachUI/ScreenReadModels.swift:2176:                intentID: .init(rawValue: "sample-match-\(control.rawValue)")
Sources/ProFootballCoachUI/ScreenReadModels.swift:2184:            stableID: "sample-playback-snap",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2188:                    stableID: "sample-home-2",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2190:                    uniformNumber: "1",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2194:                    role: "carrier"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2199:                    kind: "snap", fromX: 56, fromY: 0.50, toX: 51, toY: 0.50,
Sources/ProFootballCoachUI/ScreenReadModels.swift:2203:                    kind: "air", fromX: 51, fromY: 0.50, toX: 63, toY: 0.20,
Sources/ProFootballCoachUI/ScreenReadModels.swift:2207:                    kind: "carry", fromX: 63, fromY: 0.20, toX: 69, toY: 0.24,
Sources/ProFootballCoachUI/ScreenReadModels.swift:2211:            foregroundIDs: ["sample-home-0", "sample-home-2", "sample-away-9"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2215:            sentence: "X catches the out route and picks up eight yards after contact."
Sources/ProFootballCoachUI/ScreenReadModels.swift:2218:            recordedOutcomeID: "sample-recorded-outcome",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2225:            callInBudget: .init(used: 18, total: 25, marks: 1, rateNote: "25 a game · the default"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2238:            foregroundActorIDs: ["sample-home-0", "sample-home-4", "sample-away-10"],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2240:            causalCommentary: "The safety stepped down after the tight end motion.",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2242:                stableID: "sample-call-in",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2244:                message: "Their weak-side safety is triggering before the snap.",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2245:                evidence: ["Safety alignment moved inside the hash after tight end motion."],
Sources/ProFootballCoachUI/ScreenReadModels.swift:2249:                        intentID: .init(rawValue: "sample-take-over"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2250:                        title: "Accept adjustment",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2251:                        cost: "Applies after this play",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2252:                        consequence: "The recorded moment remains unchanged"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2256:                        intentID: .init(rawValue: "sample-delegate"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2257:                        title: "Dismiss call-in",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2258:                        cost: "No tactical change",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2259:                        consequence: "Staff keeps the current future call"
Sources/ProFootballCoachUI/ScreenReadModels.swift:2263:                        intentID: .init(rawValue: "sample-inspect-evidence"),
Sources/ProFootballCoachUI/ScreenReadModels.swift:2264:                        title: "Inspect evidence",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2265:                        cost: "No commitment",
Sources/ProFootballCoachUI/ScreenReadModels.swift:2266:                        consequence: "Opens the safety-trigger evidence"
Sources/FootballSimCore/Generation/Archetype.swift:53:        Archetype(id: 0, name: "Land-grant power",
Sources/FootballSimCore/Generation/Archetype.swift:57:        Archetype(id: 1, name: "Private academic",
Sources/FootballSimCore/Generation/Archetype.swift:61:        Archetype(id: 2, name: "Service academy",
Sources/FootballSimCore/Generation/Archetype.swift:65:        Archetype(id: 3, name: "Commuter school",
Sources/FootballSimCore/Generation/Archetype.swift:69:        Archetype(id: 4, name: "Regional riser",
Sources/FootballSimCore/Generation/Archetype.swift:73:        Archetype(id: 5, name: "Fallen blueblood",
Sources/FootballSimCore/Generation/Archetype.swift:77:        Archetype(id: 6, name: "Oil-money upstart",
Sources/FootballSimCore/Generation/Archetype.swift:81:        Archetype(id: 7, name: "Rural stalwart",
Sources/FootballSimCore/Generation/Archetype.swift:85:        Archetype(id: 8, name: "Metropolitan flagship",
Sources/FootballSimCore/Generation/Archetype.swift:89:        Archetype(id: 9, name: "Technical institute",
Sources/FootballSimCore/Generation/Archetype.swift:93:        Archetype(id: 10, name: "Coastal boutique",
Sources/FootballSimCore/Generation/Archetype.swift:97:        Archetype(id: 11, name: "Mining-town grinder",
Sources/FootballSimCore/Generation/Archetype.swift:101:        Archetype(id: 12, name: "Faith-founded",
Sources/FootballSimCore/Generation/Archetype.swift:105:        Archetype(id: 13, name: "Frontier expansionist",
Sources/FootballSimCore/History/NewsFeedReadModel.swift:21:/// **Derived, never stored.** `DomainEventPayload` states the rule — "Presentation text is derived by
Sources/FootballSimCore/History/NewsFeedReadModel.swift:22:/// read-model builders, never persisted as the source of truth" — so a headline is computed here and
Sources/FootballSimCore/History/NewsFeedReadModel.swift:27:/// season keeps.** One definition of "important", used twice: a season that is worth remembering is
Sources/FootballSimCore/History/NewsFeedReadModel.swift:84:        func who(_ id: UUID) -> String { names[id] ?? "An unnamed party" }
Sources/FootballSimCore/History/NewsFeedReadModel.swift:88:            return "Season \(season) ends: \(who(collegeChampionID)) take the college title, "
Sources/FootballSimCore/History/NewsFeedReadModel.swift:89:                + "\(who(proChampionID)) the professional one"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:91:            return "Conference realignment: \(swaps.count) swap(s) for \(reason.rawValue)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:93:            return "A new football world opens with \(programmes) programmes and \(proTeams) "
Sources/FootballSimCore/History/NewsFeedReadModel.swift:94:                + "professional teams"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:96:            return "\(participantIDs.count) teams are seeded for the \(tier.rawValue) "
Sources/FootballSimCore/History/NewsFeedReadModel.swift:97:                + "\(stage.rawValue)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:99:            return "The transfer portal closes with \(summary.transferredCount) moves"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:101:            return "The season \(season) professional market opens: \(draftClassCount) draft "
Sources/FootballSimCore/History/NewsFeedReadModel.swift:102:                + "prospects and \(freeAgentCount) free agents"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:104:            return "The season \(season) professional draft is under way"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:106:            return "The season \(season) professional market closes"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:108:            return "\(who(teamID)) take \(who(prospectID)) with pick \(pick + 1)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:110:            return "\(who(playerID)) transfers to \(who(destinationProgrammeID))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:112:            return "\(who(sourceTeamID)) trade \(who(sourcePlayerID)) to "
Sources/FootballSimCore/History/NewsFeedReadModel.swift:113:                + "\(who(destinationTeamID)) for \(who(destinationPlayerID))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:115:            return "\(who(destinationTeamID)) claim \(who(playerID)) off waivers"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:117:            return "\(who(organisationID)) hire \(who(staffID)) as \(role.rawValue)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:119:            return "\(who(prospectID)) commits to \(who(context.winner.programmeID))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:123:                return "\(who(prospectID)) signs with \(who(programmeID))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:125:                return "\(who(programmeID)) release \(who(prospectID)): \(reason)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:128:            return "\(who(playerID)) enters the portal from \(who(sourceProgrammeID))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:130:            return "\(who(playerID)) joins \(who(organisationID))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:132:            return "\(who(playerID)) leaves \(who(organisationID)): \(reason.rawValue)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:134:            return "\(who(playerID)) at \(who(programmeID)): redshirt \(outcome.rawValue)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:136:            return "\(who(teamID)) sign \(who(playerID)) (\(kind.rawValue))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:138:            return "\(who(teamID)) release \(who(playerID)) to clear cap space"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:141:            return "\(who(organisationID)) suspend \(who(playerID)) for \(weeks) "
Sources/FootballSimCore/History/NewsFeedReadModel.swift:142:                + "\(weeks == 1 ? "week" : "weeks") over \(NewsFeedReadModel.wording(reason))"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:171:        case .timekeeping: return "missed team commitments"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:172:        case .conduct: return "conduct"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:173:        case .teamRules: return "a team rules breach"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:174:        case .offField: return "an off-field matter"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:185:            result[prospect.id] = "\(prospect.firstName) \(prospect.lastName)"
Sources/FootballSimCore/History/NewsFeedReadModel.swift:188:            result[archived.id] = "\(archived.firstName) \(archived.lastName)"
Sources/FootballSimCore/People/ProContractNegotiation.swift:41:            "A negotiation needs a bounded offer history."
Sources/FootballSimCore/People/ProContractNegotiation.swift:43:        precondition(deadline.isOnOrAfter(openedAt), "A negotiation deadline cannot precede its opening.")
Sources/FootballSimCore/People/ProContractNegotiation.swift:65:                debugDescription: "The professional negotiation is outside its bounded contract shape."
Sources/FootballSimCore/Model/Staff.swift:74:    public var fullName: String { "\(firstName) \(lastName)" }
Sources/FootballSimCore/People/PeopleState.swift:55:                debugDescription: "Injury duration is outside its legal bounds."
Sources/FootballSimCore/People/PeopleState.swift:125:                debugDescription: "Suspension duration is outside its legal bounds."
Sources/FootballSimCore/People/PeopleState.swift:170:                debugDescription: "Development component is outside its legal range."
Sources/FootballSimCore/People/PeopleState.swift:195:                debugDescription: "Attribute development delta is outside its legal range."
Sources/FootballSimCore/People/PeopleState.swift:224:                debugDescription: "Attribute change is outside its legal range."
Sources/FootballSimCore/People/PeopleState.swift:272:                debugDescription: "Development explanation exceeds its bounded unique shape."
Sources/FootballSimCore/People/PeopleState.swift:329:                debugDescription: "Player fatigue is outside its legal range."
Sources/FootballSimCore/People/PeopleState.swift:340:                debugDescription: "Recent attribute history exceeds its bound."
Sources/FootballSimCore/People/PeopleState.swift:361:    /// Separate from `recoverWeek`'s return value rather than folded into it: that Bool means "came
Sources/FootballSimCore/People/PeopleState.swift:362:    /// back from an injury" and drives `.playerRecovered`, so a suspension ending would otherwise
Sources/FootballSimCore/People/PeopleState.swift:476:            "Career seasons require supported usage and tier-consistent redshirt outcomes."
Sources/FootballSimCore/People/PeopleState.swift:518:                debugDescription: "Player career season has impossible season or usage totals."
Sources/FootballSimCore/People/PeopleState.swift:598:                debugDescription: "Player recruiting origin is outside its legal bounds."
Sources/FootballSimCore/People/PeopleState.swift:723:                debugDescription: "Player career history is malformed or unbounded."
Sources/FootballSimCore/People/PeopleState.swift:880:                debugDescription: "Staff assignment season cannot be negative."
Sources/FootballSimCore/People/PeopleState.swift:915:                debugDescription: "Staff career history exceeds its bound."
Sources/FootballSimCore/People/PeopleState.swift:951:                debugDescription: "Departed player identity has invalid age or active status."
Sources/FootballSimCore/People/PeopleState.swift:962:    public var fullName: String { "\(firstName) \(lastName)" }
Sources/FootballSimCore/People/PeopleState.swift:1020:                debugDescription: "People-state keys disagree with persistent person IDs."
Sources/FootballSimCore/Competition/CompetitionState.swift:98:                debugDescription: "Game participants are duplicated, unbounded, or disagree with production."
```

Accessibility-label/value/hint expressions:

```text
Sources/ProFootballCoachUI/MatchDayView.swift:272:        .accessibilityLabel("Speed, \(Int(speedMultiplier)) times")
Sources/ProFootballCoachUI/MatchDayView.swift:339:        .accessibilityLabel(label ?? presentation.title)
Sources/ProFootballCoachUI/MatchDayView.swift:408:        .accessibilityLabel(
Sources/ProFootballCoachUI/MatchDayView.swift:682:            .accessibilityLabel(label)
Sources/ProFootballCoachUI/MatchDayView.swift:704:            .accessibilityLabel(
Sources/ProFootballCoachUI/MatchDayView.swift:794:        .accessibilityLabel(
Sources/ProFootballCoachUI/MatchDayView.swift:823:        .accessibilityLabel(Text(accessibilityLabel))
Sources/ProFootballCoachUI/MatchDayView.swift:862:                .navigationTitle("Call-in evidence")
Sources/ProFootballCoachUI/ShortlistView.swift:84:                .accessibilityLabel("Filter the board by name, position or status")
Sources/ProFootballCoachUI/ShortlistView.swift:155:        .accessibilityLabel(
Sources/ProFootballCoachUI/ShortlistView.swift:208:        .accessibilityLabel(
Sources/ProFootballCoachUI/StaffRoomView.swift:116:                .accessibilityLabel(
Sources/ProFootballCoachUI/StaffRoomView.swift:197:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/FloodlitChrome.swift:367:        .accessibilityLabel(primaryRowLabel)
Sources/ProFootballCoachUI/FloodlitChrome.swift:446:        .accessibilityLabel(sibling.accessibleTitle)
Sources/ProFootballCoachUI/FloodlitChrome.swift:522:        .accessibilityLabel("Sections")
Sources/ProFootballCoachUI/FloodlitChrome.swift:564:        .accessibilityLabel(entry.label)
Sources/ProFootballCoachUI/FloodlitChrome.swift:606:        .accessibilityLabel("\(screen.canonicalName). Registered, not built. \(needs)")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:104:                .accessibilityLabel("\(row.title), \(row.value), \(row.team.name) versus \(row.opponent.name), \(row.gameLabel)")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:128:                .accessibilityLabel("Rivalry with \(row.opponent.name), \(row.origin), intensity \(row.intensity), \(row.meetings.count) notable meetings")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:147:                .accessibilityLabel("Season \(row.season), \(row.role), \(row.organisation.name)")
Sources/ProFootballCoachUI/LegacyHistoryView.swift:170:                .accessibilityLabel("Mentor \(branch.mentorName), \(branch.disciples.joined(separator: ", "))")
Sources/ProFootballCoachUI/GamePlanView.swift:113:        .accessibilityLabel("\(slot), \(value)")
Sources/ProFootballCoachUI/GamePlanView.swift:171:                .accessibilityLabel("\(option.title). \(option.consequence)")
Sources/ProFootballCoachUI/CareerHubView.swift:139:        .accessibilityLabel("\(key), \(value)")
Sources/ProFootballCoachUI/CareerHubView.swift:177:                    .accessibilityLabel(
Sources/ProFootballCoachUI/CareerHubView.swift:245:                .accessibilityLabel("\(row.team.name). \(historyLine(row))")
Sources/ProFootballCoachUI/CareerHubView.swift:322:                    .accessibilityHint(
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:158:        .accessibilityLabel(
Sources/ProFootballCoachUI/CompetitionOverviewView.swift:231:        .accessibilityLabel(
Sources/ProFootballCoachUI/NewCareerSetupView.swift:84:                .accessibilityLabel("Coach first name")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:87:                .accessibilityLabel("Coach last name")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:90:                .accessibilityLabel("World seed")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:182:        .accessibilityLabel("\(job.programme.name), \(job.cityName)")
Sources/ProFootballCoachUI/NewCareerSetupView.swift:183:        .accessibilityValue(
Sources/ProFootballCoachUI/PlayerProfileView.swift:161:                .accessibilityLabel(
Sources/ProFootballCoachUI/PlayerProfileView.swift:300:        .accessibilityLabel("\(key), \(text)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:336:            .accessibilityLabel("\(team.name), number \(model.number)")
Sources/ProFootballCoachUI/PlayerProfileView.swift:360:        .accessibilityLabel(identityAccessibilityLabel)
Sources/ProFootballCoachUI/ContractNegotiationView.swift:185:            .accessibilityLabel(
Sources/ProFootballCoachUI/ContractNegotiationView.swift:260:                .accessibilityLabel(
Sources/ProFootballCoachUI/InboxView.swift:184:                .accessibilityLabel(
Sources/ProFootballCoachUI/InboxView.swift:284:            .accessibilityHint(model.continueReason ?? "")
Sources/ProFootballCoachUI/RealignmentEventView.swift:72:        .accessibilityLabel(spoken)
Sources/ProFootballCoachUI/StatisticsLeadersView.swift:101:        .accessibilityLabel(
Sources/ProFootballCoachUI/RecruitingBoardView.swift:90:            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:108:                .accessibilityHint(model.continueReason ?? "")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:187:                .accessibilityHint(model.continueReason ?? "")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:250:        .accessibilityLabel("Position plan. \(positionPlanLine)")
Sources/ProFootballCoachUI/RecruitingBoardView.swift:479:        .accessibilityLabel(prospectAccessibilityLabel(prospect))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:528:                .accessibilityLabel(prospectAccessibilityLabel(prospect))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:576:                        .accessibilityLabel(prospectAccessibilityLabel(prospect))
Sources/ProFootballCoachUI/RecruitingBoardView.swift:655:        .accessibilityLabel(
Sources/ProFootballCoachUI/RecruitingBoardView.swift:820:                    .accessibilityLabel(
Sources/ProFootballCoachUI/WorldSearchView.swift:94:                .accessibilityLabel("Search current teams, cities or regions")
Sources/ProFootballCoachUI/WorldSearchView.swift:194:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProManagementView.swift:94:            .accessibilityLabel(
Sources/ProFootballCoachUI/ProManagementView.swift:150:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/ProManagementView.swift:218:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProManagementView.swift:253:        .accessibilityLabel(
Sources/ProFootballCoachUI/AftermathView.swift:122:        .accessibilityLabel("\(side.team.name), \(side.score)")
Sources/ProFootballCoachUI/AftermathView.swift:176:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:83:            .accessibilityLabel(
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:127:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:188:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:245:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProOffseasonView.swift:100:                .accessibilityLabel(
Sources/ProFootballCoachUI/ProOffseasonView.swift:121:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/ProOffseasonView.swift:189:        .accessibilityLabel(
Sources/ProFootballCoachUI/ProOffseasonView.swift:209:        .accessibilityLabel("\(player.name), \(player.position)")
Sources/ProFootballCoachUI/ProOffseasonView.swift:224:        .accessibilityLabel("\(waiver.name), claim deadline \(waiver.deadline)")
Sources/ProFootballCoachUI/ProOffseasonView.swift:278:        .accessibilityLabel(
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:100:        .accessibilityLabel("\(label), \(value) left")
Sources/ProFootballCoachUI/ContactVisitPlannerView.swift:218:        .accessibilityLabel(
Sources/ProFootballCoachUI/CoachingHQView.swift:102:                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")
Sources/ProFootballCoachUI/CoachingHQView.swift:118:                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")
Sources/ProFootballCoachUI/CoachingHQView.swift:230:            .accessibilityHint(
Sources/ProFootballCoachUI/CoachingHQView.swift:429:                            .accessibilityLabel("\(row.slot) \(row.player), \(row.status)")
Sources/ProFootballCoachUI/CoachingHQView.swift:464:                            .accessibilityLabel("\(row.name), support \(row.support) of 100")
Sources/ProFootballCoachUI/CoachingHQView.swift:609:                            .accessibilityLabel("\(day.dayLabel), \(day.assignment)")
Sources/ProFootballCoachUI/CoachingHQView.swift:657:                        .accessibilityLabel("\(unallocatedTimeLabel) unallocated")
Sources/ProFootballCoachUI/CoachingHQView.swift:727:        .accessibilityLabel("Inspect film")
Sources/ProFootballCoachUI/CoachingHQView.swift:737:            .accessibilityLabel("Delegate")
Sources/ProFootballCoachUI/CoachingHQView.swift:791:        .accessibilityLabel("\(choice.title). Cost: \(choice.cost). Consequence: \(choice.consequence)")
Sources/ProFootballCoachUI/CoachingHQView.swift:866:                    .accessibilityHint("Commits the balanced game and practice plans for this week.")
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:145:        .accessibilityLabel(text)
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:183:        .accessibilityLabel(value == 0 ? "no change" : "\(value > 0 ? "up" : "down") \(abs(value))")
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:243:        .accessibilityLabel("rating \(value)")
Sources/ProFootballCoachUI/CoachWorldVocabulary.swift:408:            .accessibilityLabel(team.name)
Sources/ProFootballCoachUI/ProspectProfileView.swift:118:            .accessibilityLabel(
Sources/ProFootballCoachUI/ProspectProfileView.swift:164:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/ProspectProfileView.swift:242:                    .accessibilityLabel(
Sources/ProFootballCoachUI/AwardsHonoursView.swift:102:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamHealthView.swift:168:        .accessibilityLabel(
Sources/ProFootballCoachUI/TeamHealthView.swift:244:        .accessibilityLabel("\(label), \(value)")
Sources/ProFootballCoachUI/TeamHealthView.swift:280:            .accessibilityHint(model.continueReason ?? "")
Sources/ProFootballCoachUI/PracticePlanView.swift:136:        .accessibilityLabel("\(name), \(minutes) minutes of \(TacticalPracticePlan.weeklyMinutes)")
Sources/ProFootballCoachUI/PracticePlanView.swift:169:                .accessibilityLabel("\(option.title). \(option.consequence)")
Sources/ProFootballCoachUI/StandingsView.swift:115:        .accessibilityLabel(
Sources/ProFootballCoachUI/DevelopmentPlanView.swift:191:                .accessibilityLabel(
Sources/ProFootballCoachUI/RosterView.swift:105:            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")
Sources/ProFootballCoachUI/RosterView.swift:125:            .accessibilityHint(model.continueReason ?? "")
Sources/ProFootballCoachUI/RosterView.swift:380:        .accessibilityLabel("Sort by \(accessibilityName)")
Sources/ProFootballCoachUI/RosterView.swift:381:        .accessibilityValue(
Sources/ProFootballCoachUI/RosterView.swift:461:        .accessibilityLabel(playerAccessibilityLabel(player))
Sources/ProFootballCoachUI/RosterView.swift:575:                    .accessibilityLabel("\(attribute.label), \(attribute.value)")
Sources/ProFootballCoachUI/RosterView.swift:690:                .accessibilityLabel(playerAccessibilityLabel(player))
Sources/ProFootballCoachUI/RosterView.swift:736:                .accessibilityHint(model.continueReason ?? "")
Sources/ProFootballCoachUI/NewsView.swift:96:                .accessibilityLabel("\(item.occurred). \(item.headline)")
Sources/ProFootballCoachUI/ClassOverviewView.swift:89:        .accessibilityLabel(
Sources/ProFootballCoachUI/ClassOverviewView.swift:157:        .accessibilityLabel(
Sources/ProFootballCoachUI/ClassOverviewView.swift:213:        .accessibilityLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:156:            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")
Sources/ProFootballCoachUI/LeagueMapView.swift:295:                    .accessibilityLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:356:        .accessibilityLabel("All \(tier) places")
Sources/ProFootballCoachUI/LeagueMapView.swift:390:        .accessibilityLabel(placeAccessibilityLabel(place))
Sources/ProFootballCoachUI/LeagueMapView.swift:508:        .accessibilityLabel(placeAccessibilityLabel(place))
Sources/ProFootballCoachUI/LeagueMapView.swift:566:        .accessibilityLabel("\(name), \(value)")
Sources/ProFootballCoachUI/LeagueMapView.swift:604:                .accessibilityLabel(
Sources/ProFootballCoachUI/LeagueMapView.swift:682:        .accessibilityLabel(placeAccessibilityLabel(place))
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:107:        .accessibilityLabel("\(side.team.name), \(side.score)")
Sources/ProFootballCoachUI/GameDetailBoxScoreView.swift:167:                    .accessibilityLabel(
Sources/ProFootballCoachUI/OpponentFilmView.swift:140:        .accessibilityLabel("\(situation), \(split), from \(filmedLabel)")
Sources/ProFootballCoachUI/OpponentFilmView.swift:186:        .accessibilityLabel("\(label.capitalized), \(value)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:137:        .accessibilityLabel("\(label), \(figure)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:158:        .accessibilityLabel("\(key), \(value)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:215:                    .accessibilityLabel("\(choice.title) for \(decision.title)")
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:216:                    .accessibilityHint(
Sources/ProFootballCoachUI/CollegeOffseasonView.swift:260:            .accessibilityHint(
Sources/ProFootballCoachUI/DepthChartView.swift:205:        .accessibilityLabel(
Sources/ProFootballCoachUI/DepthChartView.swift:261:        .accessibilityLabel(
Sources/ProFootballCoachUI/DepthChartView.swift:299:                .accessibilityLabel("\(option.title). \(option.consequence)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:45:            .accessibilityLabel(text)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:185:        .accessibilityLabel("\(caption), \(figure)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:266:        .accessibilityLabel("\(title), \(rating) out of \(CoachWorldTokens.Heat.scaleCeiling)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:354:            .accessibilityLabel(title)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:386:            .accessibilityLabel(title)
Sources/ProFootballCoachUI/FloodlitPatterns.swift:446:        .accessibilityLabel("\(staff.name), \(staff.role), says: \(advice)")
Sources/ProFootballCoachUI/FloodlitPatterns.swift:514:        .accessibilityLabel(
Sources/ProFootballCoachUI/FloodlitPatterns.swift:643:            .accessibilityLabel("Confidence: \(text)")
Sources/ProFootballCoachUI/TitleContinueView.swift:97:                .accessibilityHint(
Sources/ProFootballCoachUI/ScheduleView.swift:172:        .accessibilityLabel(
```
