# All-Screen Presentation Contract

Date: 2026-08-22
Scope: the 62 registered screen identities, resolved to 47 canonical presentation destinations.

## Authority and guardrails

This ledger freezes the presentation contract for the all-screen migration. Existing Swift views,
read models, assets, and callbacks are authoritative. Existing state transitions, persistence, and
simulation behavior must be preserved exactly. The supplied HTML/reference package is a visual
shell and hierarchy prompt only; it creates no facts or executable requirements. “Existing
model/callbacks” means no schema or behavior expansion is authorized.

Every production team or opponent logo supplied by current data and assets remains visible exactly
once on its destination. Do not add or duplicate logo assets. “No invented logos” prohibits
unsupported logo content; it does not authorize removing an existing supplied logo.

`onNavigateChrome` below is the existing optional shared-chrome callback accepted by conforming
presentation roots. It does not authorize a second local navigation surface.

## Amendments

### Match Day / ID 14 is required (owner, 2026-08-22)

The owner reversed the earlier instruction to skip Match Day. ID 14 is in scope, and
`Match Day.dc.html` from the supplied reference package is its exact visual and layout target:
hierarchy, spacing, field and broadcast furniture, control placement, depth, and typography are
reproduced as drawn. Match Day is the one exception where the reference wins over the general
management shell if the two conflict.

Everything above still binds for its facts and behavior. Match Day presents the immutable
`MatchDayReadModel`: all 22 retained actors, score and situation, field direction, line of
scrimmage, first-down line, recorded commentary and playback, the five existing controls, and the
existing interruption paths and callbacks. The mocks omit logos; production does not, so the real
team and opponent logos remain visible exactly once. No second engine, control, fact, outcome, or
callback behavior may be introduced to achieve the visual copy.

ID 14 stays open until that exact-reference implementation is proven on a real production route. It
is neither omitted nor complete, and the earlier Match Day evidence caveats in
`.superpowers/sdd/all-screen-task-4-report.md` are historical context, not acceptance.

### Weekly plan dominants read the selected option (review fix, 2026-08-22)

On IDs 11 and 12 the dominant readout describes the option the committing action would send, not
the plan already stored: `selectedOption?.plan ?? model.currentPlan`. A stored plan is the fallback
for when no option can be selected. Put the stored plan first and the screen shows last week's
values under this week's chosen label, beside a consequence and a committing action that name a
different plan. On ID 8 the blocker/receipt (`statusMessage`) presents after obligations, kickoff,
and health/stakeholders, never inside the dominant decision panel.

This adds no field, route, callback, or state; it fixes which existing value the dominant reads.
`ContractTests` and `DesignContractTests` pin both rules.

### Canonical destinations carry a stamp (proof convention, 2026-08-23)

Each canonical destination names itself with a `canonical-screen-<id>` accessibility identifier,
rendered by `CanonicalScreenStamp`, so a proof can enumerate the registry by looping the id range
rather than listing screens by hand. A surface must carry exactly one, and no other destination's.

Two rules the Personnel family paid for:

- **Attach it with `.background(alignment: .topLeading)`, never as a stack child.** As a child of a
  spaced `VStack` the stamp measures a point and takes the stack's spacing with it, which pushed
  three surfaces down 10 points in a 390-point window.
- **A screen-level `.accessibilityIdentifier` needs `.accessibilityElement(children: .contain)`
  ahead of it.** An accessibility property applied to a container propagates to its descendants and
  the outer one wins, so a bare identifier on the stage renames every descendant identifier beneath
  it -- which silently disabled both the stamp and the accessibility-size guard on IDs 16 and 18,
  and had already disabled the committing-action enumeration on ID 8.

The weekly command family still uses the older `weekly-command-screen-<id>` name. Task 10 folds the
two into one; until then both are stated here rather than one being introduced silently.

## Canonical destinations and evidence ledger

| ID | Canonical destination | Presentation root | Archetype | Dominant question | Existing backing | Existing actions | Omitted/deferred |
|---:|---|---|---|---|---|---|---|
| 1 | Title / Continue | TitleContinueView | Entry | What can I start or resume? | No named read model; existing `failure`, `isStarting`, `isRestoring`, and `recoveryRequired` inputs; optional `FloodlitChromeReadModel` | `onRetry`, `onUseBackup`, `onNewCareer`, `onSettings`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Entry — team/logo/record/opponent/family/sibling state before appointment. |
| 2 | New Career & Coach Identity | NewCareerCoachIdentityView → NewCareerSetupView | Entry | Who am I and which real starting job do I choose? | `[StartingJobReadModel]`, `defaultSeed`, `isWorking`, and `errorMessage` | `onStart`, `onSeedChanged`, `onCancel` | No invented facts, logos, routes, or actions. Entry — team/logo/record/opponent/family/sibling state before appointment. |
| 6 | Settings & Accessibility | SettingsAccessibilityView | Entry / transaction | Which existing preference changes now? | No named read model; system accessibility environment and static beta commitments; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No invented facts, logos, routes, or actions. Entry — team/logo/record/opponent/family/sibling state before appointment; no preference mutation or persistence without a callback. |
| 7 | World Search | WorldSearchView | Comparison / search | Which retained world entity am I looking for? | `WorldSearchReadModel`; optional `FloodlitChromeReadModel` | `onClose`, `onSelectTeam`, `onNavigateChrome` | No invented facts, logos, routes, or actions. League — derived geography, cross-tier scope, probability, media, unsupported event state. |
| 8 | Coaching HQ | CoachingHQView | Decision / workbench | What requires my judgment before kickoff? | `CoachingHQReadModel`: week/deadline, day plan, unallocated practice minutes, fixture/venue, obligations, optional decision evidence and 2–3 costed choices, optional retained staff recommendation, correspondence, squad-health exceptions, stakeholders; optional `statusMessage` and `FloodlitChromeReadModel` | `onCommit`, `onInspect`, `onDelegate`, `onPrepare`, `onContinue`, `onOpenCorrespondence`, `onNavigate`, `onNavigateChrome` | No reference-derived recommendation beyond `staffRecommendation`; no countdown, local receipt/undo, or film/health/fixture evidence beyond the named fields. |
| 9 | Inbox | InboxView | Timeline / feed | What new message changes my work? | `InboxReadModel`: bounded decision/task/story items with source, body, received time, optional deadline/destination, unread state, `canContinue`/`continueReason`; optional `statusMessage` and `FloodlitChromeReadModel` | `onClose`, `onOpen`, `onRead`, `onContinue`, `onNavigateChrome` | No recommendation, countdown, receipt, undo, reply/composition action, or message evidence beyond the retained item fields. |
| 10 | Opponent Report / Film Room | OpponentFilmView | Entity evidence | What does the retained opponent evidence say? | `OpponentFilmReadModel`: optional opponent, source-game/fixture counts, confidence, pass rate, turnover rate, current flag, honest `unavailableReason`; optional `statusMessage` and `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onNavigateChrome` | No recommendation, countdown, receipt, undo, down-and-distance splits, player film, hidden league totals, or opponent evidence beyond the two retained tendencies and source figures. |
| 11 | Game Plan | GamePlanView | Decision / workbench | Which tactical plan am I committing? | `GamePlanReadModel`: optional current `TacticalPlan`, opponent/week context, and retained options with title, three-dimension plan, and consequence; optional `statusMessage` and `FloodlitChromeReadModel` | `onSelect`, `onClose`, `onNavigateChrome` | No recommendation, countdown, cost, receipt, undo, coverage dimension, or tactical evidence beyond current/option plan values and consequence. |
| 12 | Practice Plan | PracticePlanView | Decision / workbench | How am I allocating the retained practice plan? | `PracticePlanReadModel`: optional current `TacticalPracticePlan`, week context, and retained options with title, complete session allocation, and consequence; optional `statusMessage` and `FloodlitChromeReadModel` | `onSelect`, `onClose`, `onNavigateChrome` | No separate remaining/unallocated-minutes field, recommendation, countdown, receipt, undo, or editable session sliders; each retained option is already a complete allocation. |
| 13 | Team Health | TeamHealthView | Comparison / exceptions | Who cannot perform normally and why? | `TeamHealthReadModel`: aggregate condition/fatigue and injury/suspension counts, bounded player condition/fatigue/availability/detail rows, `canContinue`/`continueReason`; optional `statusMessage` and `FloodlitChromeReadModel` | `onClose`, `onContinue`, `onNavigateChrome` | No diagnosis, recommendation, countdown, return date, treatment, receipt, undo, or health evidence beyond the retained readiness fields. Routine available rows remain neutral. |
| 14 | Match Day | MatchDayView | Live / event | What is happening now and what can I control? | `MatchDayReadModel`: final/current score furniture, venue/game/event context, situation and direction, exactly 22 actors, scrimmage/first-down lines, optional recorded playback, causal commentary, optional call-in budget/interruption/evidence, five controls and control depth; optional `FloodlitChromeReadModel` | `onControl`, `onInterruption`, `onExit`, `onNavigateChrome` | No recommendation, forecast, countdown, receipt, undo, extra control, reconstructed commentary, actor, line, fixture, or interruption evidence. |
| 15 | Aftermath | AftermathView | Live result / evidence | What happened and what did the plan produce? | `AftermathReadModel`: final score/result/headline, venue, retained evidence/call-ins/injuries, bounded player grades with evidence; optional `statusMessage` and `FloodlitChromeReadModel` | `onContinue`, optional `onOpenBoxScore`, `onNavigateChrome` | No recommendation, countdown, receipt, undo, trend, prior-grade delta, quarter score, reconstructed stat line, or result evidence beyond retained fields. |
| 16 | Roster | RosterView | Comparison / board | Which player best fits the current need? | `RosterReadModel`: roster limit, injury and open-need counts, season/week/record/rank labels, and bounded `PlayerRow`s carrying number, position, academic year, roster role, overall, development and its delta, scheme fit, condition, availability and a nested profile; optional `statusMessage` and `FloodlitChromeReadModel` | `onContinue`, `onNavigate`, `onInspectDevelopment`, `onOpenProfile`, `onNavigateChrome` | No roster search, no filtering, no sort key the model does not already order by, no derived ranking, no position-specific analysis, no invented origin or staff copy. The exception ribbon prints only the retained injury and open-need counts. |
| 17 | Depth Chart | DepthChartView | Spatial / structural | Who occupies each real role? | `DepthChartReadModel`: optional current `PersonnelPlan`, week context, `PositionGroup`s of real occupied roles, and retained plan `Option`s; optional `statusMessage` and `FloodlitChromeReadModel` | `onSelect`, `onClose`, `onNavigateChrome` | No invented role, no vacancy the model does not record, no recommendation, no ranking of occupants, and no plan action absent from `onSelect`. |
| 18 | Player Profile | PlayerProfileView | Entity dossier | What should I believe about this player? | `PlayerProfileReadModel`: number, position, overall, academic year, hometown, roster role, availability, condition, scheme fit, staff summary, strengths, concern, attribute groups, recent form, and development/history evidence; `CoachWorldTeamReference`; optional `FloodlitChromeReadModel` | `onClose`, `onInspectDevelopment`, `onNavigateChrome` | No projection, no comparison to another player, no derived grade, no trend the recent-form entries do not state, and no evidence route the callbacks do not carry. |
| 19 | Development Plan | DevelopmentPlanView | Entity evidence / decision | What is changing and what real action is available? | `RosterReadModel`, read for one player's development, its delta, and the retained development evidence; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No editable allocation, no projected trajectory, no coaching recommendation, and no change the recorded delta does not state. |
| 20 | Staff Room | StaffRoomView | Comparison / dossier | Which staff role and judgment matter? | `StaffRoomReadModel`: season label and `StaffRow`s carrying name, role, age, reputation, development, recruiting, game planning, scheme affinity, and seasons with the programme; optional `statusMessage` and `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No delegation chip -- nothing records what is delegated to whom -- no hire, fire or negotiation action absent from the callbacks, no derived staff ranking, and no invented staff copy. |
| 24 | Recruiting Board | RecruitingBoardView | Comparison / board | Which prospect deserves the next resource? | `RecruitingBoardReadModel`: world/team/provenance, `Capacity` (scholarship slots, weekly hours and official visits remaining), `PositionNeed`s (position, target, committed), bounded `Prospect`s carrying board rank, position, hometown, interest, status, an `Evaluation` (verdict, scheme fit, stated uncertainty, cited outliers), relationship history and `CoachWorldActionChoice`s, a separate `discovery` list, and `canContinue`/`continueReason`; optional `FloodlitChromeReadModel` | `onAction`, `onContinue`, `onNavigate`, `onOpenProspect`, `onOpenShortlist`, `onNavigateChrome` | No fabricated ranking beyond the retained `boardRank`, no scouting report, no commitment probability, no countdown, no market row, no recipient allocation, and no action absent from `choices`. Uncertainty is the model's stated `uncertainty` text, never a derived confidence. |
| 25 | Prospect Profile | ProspectProfileView | Entity dossier | What is known, uncertain, and actionable about this prospect? | `RecruitingBoardReadModel`: world/team/provenance, `Capacity` (scholarship slots, weekly hours and official visits remaining), `PositionNeed`s (position, target, committed), bounded `Prospect`s carrying board rank, position, hometown, interest, status, an `Evaluation` (verdict, scheme fit, stated uncertainty, cited outliers), relationship history and `CoachWorldActionChoice`s, a separate `discovery` list, and `canContinue`/`continueReason`; optional `FloodlitChromeReadModel`, existing `prospectID` | `onAction`, `onClose`, `onNavigateChrome` | No projection, no comparison to another prospect, no derived grade, no probability of commitment, and no evidence beyond the `Evaluation` and relationship history the model retains. What is unknown is said to be unknown. |
| 26 | Shortlist | ShortlistView | Comparison / queue | Who is retained for follow-up and when? | `RecruitingBoardReadModel`: world/team/provenance, `Capacity` (scholarship slots, weekly hours and official visits remaining), `PositionNeed`s (position, target, committed), bounded `Prospect`s carrying board rank, position, hometown, interest, status, an `Evaluation` (verdict, scheme fit, stated uncertainty, cited outliers), relationship history and `CoachWorldActionChoice`s, a separate `discovery` list, and `canContinue`/`continueReason`; optional `FloodlitChromeReadModel` | `onOpenProspect`, `onClose`, `onNavigateChrome` | No re-ranking, no derived priority, no countdown to a contact window, and no follow-up the model does not record. |
| 27 | Contact & Visit Planner | ContactVisitPlannerView | Decision / planner | Which allowable contact action uses the resource? | `RecruitingBoardReadModel`: world/team/provenance, `Capacity` (scholarship slots, weekly hours and official visits remaining), `PositionNeed`s (position, target, committed), bounded `Prospect`s carrying board rank, position, hometown, interest, status, an `Evaluation` (verdict, scheme fit, stated uncertainty, cited outliers), relationship history and `CoachWorldActionChoice`s, a separate `discovery` list, and `canContinue`/`continueReason`; optional `FloodlitChromeReadModel` | `onAction`, `onClose`, `onNavigateChrome` | No action absent from `choices`, no cost or consequence the choice does not state, and no recommendation of which contact to spend. Remaining hours and visits print from `Capacity`. |
| 28 | Class Overview | ClassOverviewView | Comparison / summary | What does the current class solve or leave open? | `RecruitingBoardReadModel`: world/team/provenance, `Capacity` (scholarship slots, weekly hours and official visits remaining), `PositionNeed`s (position, target, committed), bounded `Prospect`s carrying board rank, position, hometown, interest, status, an `Evaluation` (verdict, scheme fit, stated uncertainty, cited outliers), relationship history and `CoachWorldActionChoice`s, a separate `discovery` list, and `canContinue`/`continueReason`; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No class grade, no national ranking, no projected finish, and no need the `PositionNeed` table does not state. |
| 29 | Signing Day | SigningDayView | Live / event | Which recorded commitments changed the class? | `CollegeOffseasonReadModel`: season label, recruiting season, `cyclePhase` and `portalPhase`, board and scholarship counts, contact points remaining, NIL budget and committed, portal entry count, delegated decision count, and `Decision`s carrying their own cost and consequence; optional `FloodlitChromeReadModel` | `onCommit`, `onContinue`, `onClose`, `onNavigateChrome` | No fabricated commitment, no drama copy, no countdown, and no result the retained decisions do not record. Outside the signing phase it says signing day is closed rather than rendering an empty board. |
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
| 47 | Game Detail / Box Score | GameDetailBoxScoreView | Live result / evidence | What evidence explains this result? | `AftermathReadModel`: final score/result/headline, venue, retained evidence/call-ins/injuries, bounded player grades with evidence; optional `FloodlitChromeReadModel` | `onClose`, `onNavigateChrome` | No recommendation, countdown, receipt, undo, quarter scoring, opposed team totals, play-by-play, reconstructed stat line, or box-score evidence beyond the retained aftermath projection. |
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
| 61 | College Offseason | CollegeOffseasonView | Decision / workbench | Which retention, portal, and NIL obligation is actionable? | `CollegeOffseasonReadModel`: season label, recruiting season, `cyclePhase` and `portalPhase`, board and scholarship counts, contact points remaining, NIL budget and committed, portal entry count, delegated decision count, and `Decision`s carrying their own cost and consequence; optional `FloodlitChromeReadModel` | `onCommit`, `onContinue`, `onClose`, `onNavigateChrome` | No invented portal entrant, no NIL recipient allocation the model does not hold, no retention probability, and no action absent from a `Decision`. Exact NIL budget and committed values print rather than a derived remainder. |
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
