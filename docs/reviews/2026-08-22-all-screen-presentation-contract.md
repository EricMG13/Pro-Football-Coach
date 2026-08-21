# All-Screen Presentation Contract

Date: 2026-08-22
Scope: the 62 registered screen identities, resolved to 47 canonical presentation destinations.

## Authority and guardrails

This ledger freezes the presentation contract for the all-screen migration. Existing Swift views,
read models, assets, and callbacks are authoritative. Reference HTML and reference-package prose
may inform presentation, but do not authorize new facts, state, routes, actions, schema, or behavior.
“Existing model/callbacks” means no schema or behavior expansion is authorized.

Every production team or opponent logo supplied by current data and assets remains visible exactly
once on its destination. “No invented logos” prohibits unsupported logo content; it does not
authorize removing an existing supplied logo.

`onNavigateChrome` below is the existing optional shared-chrome callback accepted by conforming
presentation roots. It does not authorize a second local navigation surface.

## Canonical destinations and evidence ledger

| ID | Canonical destination | Presentation root | Archetype | Dominant question | Existing backing | Existing actions | Omitted/deferred |
|---:|---|---|---|---|---|---|---|
| 1 | Title / Continue | TitleContinueView | Entry | What can I start or resume? | No named read model; existing `failure`, `isStarting`, `isRestoring`, and `recoveryRequired` inputs; optional `FloodlitChromeReadModel` | `onRetry`, `onUseBackup`, `onNewCareer`, `onSettings`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Entry — team/logo/record/opponent/family/sibling state before appointment. |
| 2 | New Career & Coach Identity | NewCareerCoachIdentityView → NewCareerSetupView | Entry | Who am I and which real starting job do I choose? | `[StartingJobReadModel]`, `defaultSeed`, `isWorking`, and `errorMessage` | `onStart`, `onSeedChanged`, `onCancel` | No invented facts, logos, routes, or actions. Entry — team/logo/record/opponent/family/sibling state before appointment. |
| 6 | Settings & Accessibility | SettingsAccessibilityView | Entry / transaction | Which existing preference changes now? | No named read model; system accessibility environment and static beta commitments; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Entry — team/logo/record/opponent/family/sibling state before appointment; no preference mutation or persistence without a callback. |
| 7 | World Search | WorldSearchView | Comparison / search | Which retained world entity am I looking for? | `WorldSearchReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 8 | Coaching HQ | CoachingHQView | Decision / workbench | What requires my judgment before kickoff? | `CoachingHQReadModel`; optional `FloodlitChromeReadModel` | `onCommit`, `onInspect`, `onDelegate`, `onPrepare`, `onContinue`, `onOpenCorrespondence`, `onNavigate`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 9 | Inbox | InboxView | Timeline / feed | What new message changes my work? | `InboxReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onOpen`, `onRead`, `onContinue`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 10 | Opponent Report / Film Room | OpponentFilmView | Entity evidence | What does the retained opponent evidence say? | `OpponentFilmReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 11 | Game Plan | GamePlanView | Decision / workbench | Which tactical plan am I committing? | `GamePlanReadModel`; optional `FloodlitChromeReadModel` | `onSelect`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 12 | Practice Plan | PracticePlanView | Decision / workbench | How am I allocating the retained practice plan? | `PracticePlanReadModel`; optional `FloodlitChromeReadModel` | `onSelect`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 13 | Team Health | TeamHealthView | Comparison / exceptions | Who cannot perform normally and why? | `TeamHealthReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 14 | Match Day | MatchDayView | Live / event | What is happening now and what can I control? | `MatchDayReadModel` | `onControl`, `onInterruption`, `onExit` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 15 | Aftermath | AftermathView | Live result / evidence | What happened and what did the plan produce? | `AftermathReadModel`; optional `FloodlitChromeReadModel` | `onContinue`, `onOpenBoxScore`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 16 | Roster | RosterView | Comparison / board | Which player best fits the current need? | `RosterReadModel`; optional `FloodlitChromeReadModel` | `onContinue`, `onNavigate`, `onInspectDevelopment`, `onOpenProfile`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Personnel — roster search/filter/new sort, derived ranking, position-specific analysis, invented origin/staff copy, editable development allocation. |
| 17 | Depth Chart | DepthChartView | Spatial / structural | Who occupies each real role? | `DepthChartReadModel`; optional `FloodlitChromeReadModel` | `onSelect`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Personnel — roster search/filter/new sort, derived ranking, position-specific analysis, invented origin/staff copy, editable development allocation. |
| 18 | Player Profile | PlayerProfileView | Entity dossier | What should I believe about this player? | `PlayerProfileReadModel`, `CoachWorldTeamReference`; optional `FloodlitChromeReadModel` | `onClose`, `onInspectDevelopment`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Personnel — roster search/filter/new sort, derived ranking, position-specific analysis, invented origin/staff copy, editable development allocation. |
| 19 | Development Plan | DevelopmentPlanView | Entity evidence / decision | What is changing and what real action is available? | `RosterReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Personnel — roster search/filter/new sort, derived ranking, position-specific analysis, invented origin/staff copy, editable development allocation. |
| 20 | Staff Room | StaffRoomView | Comparison / dossier | Which staff role and judgment matter? | `StaffRoomReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Personnel — roster search/filter/new sort, derived ranking, position-specific analysis, invented origin/staff copy, editable development allocation. |
| 24 | Recruiting Board | RecruitingBoardView | Comparison / board | Which prospect deserves the next resource? | `RecruitingBoardReadModel`; optional `FloodlitChromeReadModel` | `onAction`, `onContinue`, `onNavigate`, `onOpenProspect`, `onOpenShortlist`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 25 | Prospect Profile | ProspectProfileView | Entity dossier | What is known, uncertain, and actionable about this prospect? | `RecruitingBoardReadModel`, existing `prospectID`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 26 | Shortlist | ShortlistView | Comparison / queue | Who is retained for follow-up and when? | `RecruitingBoardReadModel`; optional `FloodlitChromeReadModel` | `onOpenProspect`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 27 | Contact & Visit Planner | ContactVisitPlannerView | Decision / planner | Which allowable contact action uses the resource? | `RecruitingBoardReadModel`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 28 | Class Overview | ClassOverviewView | Comparison / summary | What does the current class solve or leave open? | `RecruitingBoardReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 29 | Signing Day | SigningDayView | Live / event | Which recorded commitments changed the class? | `CollegeOffseasonReadModel`; optional `FloodlitChromeReadModel` | `onCommit`, `onContinue`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 34 | Cap & Contracts | ProManagementView | Constraint / board | Which retained cap constraint needs action? | `ProManagementReadModel`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Pro Management — cap forecast, trade value, scouting grade, contract demand/probability, unsupported transaction type. |
| 35 | Contract Negotiation | ContractNegotiationView | Decision / transaction | Which real offer can I make or accept? | `ProManagementReadModel`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Pro Management — cap forecast, trade value, scouting grade, contract demand/probability, unsupported transaction type. |
| 36 | Roster Cuts & Transactions | ProManagementView | Decision / comparison | Which roster consequence follows this transaction? | `ProManagementReadModel`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Pro Management — cap forecast, trade value, scouting grade, contract demand/probability, unsupported transaction type. |
| 39 | Draft Room | DraftRoomView | Live / event | What is on the clock and which valid action exists? | `ProOffseasonReadModel`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Pro Management — cap forecast, trade value, scouting grade, contract demand/probability, unsupported transaction type. |
| 41 | League Map | LeagueMapView | Spatial / structural | Where does this team sit in the retained world? | `LeagueMapReadModel`; optional `FloodlitChromeReadModel` | `onContinue`, `onNavigate`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 42 | Team / Programme Profile | TeamProgrammeProfileView | Entity dossier | What defines this organisation now? | `TeamProgrammeProfileReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 43 | Standings | StandingsView | Comparison / board | Where do teams stand in the controlled competition? | `StandingsReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 44 | Schedule | ScheduleView | Timeline | What happened and what is next? | `ScheduleReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 45 | Rankings & Playoff Picture | CompetitionOverviewView | Comparison / board | Which retained rankings shape the postseason? | `CompetitionOverviewReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 46 | Bracket / Postseason | CompetitionOverviewView | Spatial / structural | How does the retained postseason path connect? | `CompetitionOverviewReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 47 | Game Detail / Box Score | GameDetailBoxScoreView | Live result / evidence | What evidence explains this result? | `AftermathReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. This Week — recommendation, countdown, receipt, undo, new film/health/fixture evidence. |
| 48 | Statistics & Leaders | StatisticsLeadersView | Comparison / board | Who leads the retained statistical categories? | `StatisticsLeadersReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 49 | Awards & Honours | AwardsHonoursView | Timeline / evidence | Which honours are actually recorded? | `AwardsHonoursReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 50 | News | NewsView | Timeline / feed | Which current world event matters most? | `NewsReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 51 | Realignment Event | RealignmentEventView | Decision / event | What recorded structural change occurred? | `RealignmentReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 52 | Career Hub | CareerHubView | Comparison / opportunity | What is my current career position and real opportunity? | `CareerHubReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onAcceptOpportunity`, `onResign`, `onContinue`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 54 | Stakeholders | StakeholdersView | Comparison / evidence | Which retained relationship is changing? | `CareerHubReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onAcceptOpportunity`, `onResign`, `onContinue`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 55 | Promotion Decision | PromotionDecisionView | Decision / transaction | What is the real offer, consequence, and commitment? | `CareerHubReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onAcceptOpportunity`, `onResign`, `onContinue`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 57 | Record Book | LegacyHistoryView | Comparison / history | Which retained record is authoritative? | `LegacyHistoryReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 58 | Rivalries | LegacyHistoryView | Comparison / history | What retained rivalry history matters? | `LegacyHistoryReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 59 | Career Line | LegacyHistoryView | Timeline / history | How did this coaching career progress? | `LegacyHistoryReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 60 | Coaching Tree | LegacyHistoryView | Spatial / history | Which retained coaching relationships connect? | `LegacyHistoryReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigate`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Career — forecast, acceptance odds, job recommendation, unrecorded history. |
| 61 | College Offseason | CollegeOffseasonView | Decision / workbench | Which retention, portal, and NIL obligation is actionable? | `CollegeOffseasonReadModel`; optional `FloodlitChromeReadModel` | `onCommit`, `onContinue`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Recruiting — fabricated ranking/report/probability/countdown/market row/recipient allocation. |
| 62 | Pro Offseason | ProOffseasonView | Decision / workbench | Which market, draft, or roster-building obligation is actionable? | `ProOffseasonReadModel`, `focus`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Pro Management — cap forecast, trade value, scouting grade, contract demand/probability, unsupported transaction type. |

## Alias dispositions

Aliases are verified routes, not separate layouts. Every alias must resolve to its canonical
destination before presentation; it receives no independent layout, evidence ledger, or action
surface.

```text
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

## Proof checklist

- [ ] Prove all 62 registered IDs are accounted for as 47 canonical destinations and 15 aliases.
- [ ] Prove every alias resolves to the canonical destination above and never renders a separate layout.
- [ ] Prove every canonical destination presents without a rail.
- [ ] Prove every applicable canonical destination uses the top navigator and its canonical family/siblings.
- [ ] Prove each supplied production team/opponent logo appears exactly once, and absent assets do not produce invented logos.
- [ ] Prove every action has supported enabled, disabled, pressed, focus, and Increase Contrast distinction.
- [ ] Capture and inspect 844-point default and AX5 proof for every canonical destination.
- [ ] Capture and inspect representative proof for all seven families at 852 and 956 points and with Increase Contrast enabled.
- [ ] Run the automated accessibility matrix for every canonical destination and record its exact result.
- [ ] Run focused production routes through every canonical destination and record conditional/unavailable cases.
- [ ] Run the required repository build and test lanes and record exact commands and results.
- [ ] Complete manual-required physical-device checks for VoiceOver, Voice Control, Switch Control, sound equivalents, haptics, Reduce Motion, Reduce Transparency, Differentiate Without Color, and device-specific behavior; record tester, device, OS, and result.
