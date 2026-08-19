# Screen Reachability and Role Map

Date: 2026-08-19
Scope: production gameplay in `CoachWorldAppRootView`; DEBUG proof routing is excluded.

> **Re-verified 2026-08-19, later the same day, against HEAD `68e9c15` — 3 of the 4 "confirmed
> defects" below no longer reproduce; the fourth is real but narrower than stated.** This document
> was committed in `e3b360d feat: complete 62-screen Floodlit redesign` alongside the very rewrite
> of `CoachingHQView.swift`, `CoachWorldAppRootView.swift`, `RosterView.swift` and
> `LeagueMapView.swift` its findings cite — the analysis was evidently drafted against an
> intermediate state of that commit and not re-run against its final diff before both landed
> together. Read the findings below as a historical record of what a mid-commit source pass found,
> not as the current state of the code. No source was changed in this re-verification pass; only
> this document and `docs/STATUS.md`/`docs/qa/feature-coverage.csv` were.
>
> **Finding 1 (Recruit link leaks to pro coaches) — does not reproduce.** Every cited site gates on
> a boolean already correctly derived from `store.recruitingBoard != nil`:
> `CoachingHQView.swift:129` (`if showsRecruitingBoard { route("Recruit", ...) }`),
> `CoachingHQView.swift:158-160` (same guard inside `worldMenu`),
> `RosterView.swift:120` and `:740`, `LeagueMapView.swift:167`. The flag is constructed identically
> at both `CoachWorldAppRootView.swift:105` and `:1004` (`showsRecruitingBoard: store.recruitingBoard
> != nil`), matching the `availableScreens` gate at `:1090` and the `navigate()` guard at `:1222`.
> `CoachWorldRecruitingBoardProvider.recruitingBoard(from:)` itself requires
> `state.career.college != nil`, so a professional career gets `nil` and every one of these sites
> correctly hides the link. `ReadModelProviderTests.swift` has no direct "recruiting board is nil for
> a professional career" assertion, which is the one real gap here — see the coverage note below.
>
> **Finding 2 (13 retired aliases still advertised in HQ's World menu) — does not reproduce.** The
> current `worldMenu` (`CoachingHQView.swift:151-204`) contains zero of the thirteen retired names
> (Job Board, Offer, Appointment, Scheme Book, Personnel Packages, Staff Market & Profile, Portal Hub,
> Retention Decisions, Portal Market, NIL Allocation, Draft Board, Free Agency, Pro Scouting Board) —
> confirmed by reading the full menu body and by a repo-wide grep for each literal label. Those
> strings exist only in `ScreenRegistry.swift`'s `canonicalName`, used for migration/decode
> diagnostics, never for menu construction.
>
> **Finding 3 (Realignment Event exposed to pro coaches / no-event seasons) — does not reproduce.**
> `CoachWorldRealignmentProvider.realignment(from:)`'s guard (`state.career.coachID != nil,
> state.career.college != nil, state.careerArc.currentJob?.tier != .professional`) excludes an
> actively-employed professional coach, and `CoachingHQView`'s menu entry
> (`CoachingHQView.swift:170-172`) is gated on `showsRealignmentEvent`, constructed at
> `CoachWorldAppRootView.swift:1005` as `store.realignment?.event != nil` — identical to the
> `availableScreens` gate (`:1113`) and the `navigate()` guard (`:1210`), so a season with no event
> correctly hides the route everywhere, not just at the destination. The specific edge this finding's
> wording implied — a promoted coach whose `state.career.college` is still populated (stale, not
> cleared by promotion) — is already covered by
> `ReadModelProviderTests.swift`'s "realignment is a typed event surface, not a current-table guess"
> test, which constructs exactly that `staleCollegeControl` root and asserts `nil`.
>
> **Finding 4 (Promotion Decision not scenario-gated) — real, but narrower than described.** The
> route itself **is** already gated everywhere on an actionable offer
> (`store.careerHub?.opportunities.contains { $0.canAccept }`), not merely `careerHub != nil` as the
> original finding stated — see the same three call sites as above. What remains true: `canAccept`'s
> `canAcceptWhileSeeking` branch (`CoachWorldCareerProvider.swift:74-77`) is deliberately tier-blind —
> any fired/seeking coach, college or professional, can accept any fresh professional offer through
> it, and the shared workspace still labels that "Promotion Decision" even for a professional coach's
> lateral re-hire. That is a real labeling-precision gap, not a dead link (the button works). It is
> the same shape of finding as `DESIGN-IS-2026-08-19`'s top redesign move ("make every visible label
> name the actual transition"), so it is left for that larger, owner-scoped effort rather than
> patched in isolation here. A previously-missing regression test for the `canAcceptWhileSeeking`
> path itself (uncovered either way, positive or negative) has been added:
> `ReadModelProviderTests.swift`, "career hub lets a fired, seeking coach accept a fresh professional
> opportunity".
>
> **Finding 5 (Statistics & Awards mix both tiers) — confirmed, and it is a product question, not a
> bug.** `CoachWorldStatisticsProvider.statisticsLeaders(from:)` reads
> `state.competition.playerStatistics.values` and `awardsHonours(from:)` reads
> `state.competition.archives` with no tier filter beyond requiring *some* controlled entity to exist
> (`CoachWorldStatisticsProvider.swift:6-51`). This is accurately described. Per the doc-first
> amendment rule (`CLAUDE.md`), whether these two screens are meant to be tier-global or
> tier-scoped is a canon decision nobody has made yet, not something to silently resolve in either
> direction here.
>
> **The shared cause across findings 1-3 being phantom, and 4-5 remaining open, is the same lesson
> this document's own thesis is about: a claim about the running system is only as good as the last
> moment it was checked against the system.** A QA document bundled into the same commit as the code
> it audits still needs a final pass against that commit's last diff before either is committed —
> exactly the discipline `docs/STATUS.md` enforces on itself throughout its history with dated,
> superseded-in-place corrections. This document had not had that pass until now.

## Verdict

- The registry contains **62 stable route IDs**: **47 canonical tasks** and **15 legacy aliases**.
- All 47 canonical tasks have a production rendering path under at least one real game state.
- The 15 alias wrapper views are **not independently reachable**. The router canonicalizes their IDs before rendering; this is intentional retirement, but their dead switch branches and source-only reachability tests obscure that fact.
- Role gating is mostly driven by optional read models and correctly separates college acquisition from the pro front office.
- The current UI still has **three role/scenario reachability defects** and **13 misleading legacy links**:
  1. Pro coaches see `Recruit` links that can only fail.
  2. `Realignment Event` is advertised to pro coaches and when no realignment event exists.
  3. `Promotion Decision` is advertised to pro coaches and when no actionable college-to-pro offer exists.
  4. The HQ `World` menu still advertises 13 retired route names even though All Tasks correctly hides aliases.

## Production navigation map

```text
Title / Continue
├── Settings & Accessibility
└── New Career & Coach Identity
    └── College appointment
        └── Coaching HQ
            ├── fixed rail: HQ · Inbox · Roster · Game Plan · Film · Health · All Tasks
            ├── All Tasks: canonical routes whose read model currently exists
            ├── contextual routes: player/prospect/team profiles, plans, match and box score
            ├── Advance week → Match Day → Aftermath → Game Detail / Box Score
            └── Career Hub → accept professional opportunity
                └── same career becomes a pro appointment; college models disappear and pro models appear
```

The shared All Tasks overlay is the closest thing to a truthful router. It filters on both canonicality and current read-model availability. The fixed rail and older screen-local/HQ menus do not consistently use that filtered set.

## Legend

- **Direct**: a distinct canonical production surface is rendered.
- **Conditional**: rendered only in a matching simulation phase/state.
- **Alias → X**: the legacy ID is accepted, but the named wrapper view never renders; the player lands on X.
- **Entry**: reachable outside an active career.
- **C / P**: appropriate for college / pro careers.
- **Leak**: advertised where the route is irrelevant or guaranteed to refuse.

## All 62 route IDs

| # | Screen | Production disposition | College | Pro | Gate / finding |
|---:|---|---|:---:|:---:|---|
| 1 | Title / Continue | Entry | ✓ | ✓ | Shown when no career is loaded. |
| 2 | New Career & Coach Identity | Entry | ✓ | — | New careers start at a college programme; pro is reached later through promotion. |
| 3 | Job Board | Alias → Career Hub | ✓ | Leak | Visible in the HQ menu for both roles; pro appointments cannot accept another pro offer. Named wrapper is unreachable. |
| 4 | Offer | Alias → Career Hub | ✓ | Leak | Same as Job Board; focus mode is reachable, distinct wrapper is not. |
| 5 | Appointment | Alias → Career Hub | ✓ | Leak | Same as Job Board; distinct wrapper is not rendered. |
| 6 | Settings & Accessibility | Direct / Entry | ✓ | ✓ | Reachable from title and active career. |
| 7 | World Search | Direct | ✓ | ✓ | Global world task. |
| 8 | Coaching HQ | Direct | ✓ | ✓ | Controlled college programme or pro team. |
| 9 | Inbox | Direct | ✓ | ✓ | Controlled organisation required. |
| 10 | Opponent Report / Film Room | Direct | ✓ | ✓ | Remains reachable without a fixture and shows an explicit unavailable-evidence state. |
| 11 | Game Plan | Direct | ✓ | ✓ | Controlled organisation required; also opened from film and Match Day. |
| 12 | Practice Plan | Direct | ✓ | ✓ | Controlled organisation required. |
| 13 | Team Health | Direct | ✓ | ✓ | Controlled roster required. |
| 14 | Match Day | Conditional | ✓ | ✓ | Only while a controlled match session exists. |
| 15 | Aftermath | Conditional | ✓ | ✓ | Only after a controlled match produces aftermath evidence. |
| 16 | Roster | Direct | ✓ | ✓ | Provider supports programme and pro-team rosters. |
| 17 | Depth Chart | Direct | ✓ | ✓ | Controlled roster required. |
| 18 | Player Profile | Direct | ✓ | ✓ | Contextual roster selection; All Tasks falls back deterministically to a roster player. |
| 19 | Development Plan | Direct | ✓ | ✓ | Uses controlled roster evidence for both tiers. |
| 20 | Staff Room | Direct | ✓ | ✓ | Provider supports programme and pro-team staff. |
| 21 | Staff Market & Profile | Alias → Staff Room | Leak | Leak | HQ still names a market, but there is no candidate/hiring model. Distinct wrapper is unreachable. |
| 22 | Scheme Book | Alias → Game Plan | Leak | Leak | HQ still promises a scheme library that does not exist. Distinct wrapper is unreachable. |
| 23 | Personnel Packages | Alias → Depth Chart | Leak | Leak | HQ still promises a separate package task. Distinct wrapper is unreachable. |
| 24 | Recruiting Board | Direct | ✓ | — | Read model correctly exists only for college control. Pro still sees dead `Recruit` buttons outside All Tasks. |
| 25 | Prospect Profile | Direct | ✓ | — | College recruiting model required. |
| 26 | Shortlist | Direct | ✓ | — | College recruiting model required. |
| 27 | Contact & Visit Planner | Direct | ✓ | — | College recruiting model required. |
| 28 | Class Overview | Direct | ✓ | — | College recruiting model required. |
| 29 | Signing Day | Conditional | ✓ | — | Advertised only during the signing phase. |
| 30 | Portal Hub | Alias → College Offseason | ✓ | — | HQ still advertises the retired name; aggregate offseason surface renders. |
| 31 | Retention Decisions | Alias → College Offseason | ✓ | — | Same host; no independent route surface. |
| 32 | Portal Market | Alias → College Offseason | ✓ | — | Same host; no candidate-market surface. |
| 33 | NIL Allocation | Alias → College Offseason | ✓ | — | Same host; no recipient-allocation surface. |
| 34 | Cap & Contracts | Direct | — | ✓ | Pro-management read model required. |
| 35 | Contract Negotiation | Direct | — | ✓ | Pro-management read model required; advertised even when the negotiation ledger may be empty. |
| 36 | Roster Cuts & Transactions | Direct | — | ✓ | Pro-management read model required. |
| 37 | Pro Scouting Board | Alias → Pro Offseason | — | ✓ | Focus mode works; named wrapper is not independently rendered. |
| 38 | Draft Board | Alias → Pro Offseason | — | ✓ | Focus mode works; named wrapper is not independently rendered. |
| 39 | Draft Room | Conditional | — | ✓ | Canonical and advertised only during the draft phase. |
| 40 | Free Agency | Alias → Pro Offseason | — | ✓ | Focus mode works; named wrapper is not independently rendered. |
| 41 | League Map | Direct | ✓ | ✓ | Intentionally global across both tiers. Its local `Recruit` link is a pro dead end. |
| 42 | Team / Programme Profile | Direct | ✓ | ✓ | Defaults to controlled organisation; map selection can inspect either tier. |
| 43 | Standings | Direct | ✓ | ✓ | Correctly scoped to the controlled competition tier. |
| 44 | Schedule | Direct | ✓ | ✓ | Correctly scoped to the controlled competition tier. |
| 45 | Rankings & Playoff Picture | Direct | ✓ | ✓ | Correctly scoped to the controlled competition tier. |
| 46 | Bracket / Postseason | Direct | ✓ | ✓ | Correctly scoped to the controlled competition tier. |
| 47 | Game Detail / Box Score | Conditional | ✓ | ✓ | Requires aftermath evidence. |
| 48 | Statistics & Leaders | Direct | ✓ | ✓ | Screen is shared, but rows are not tier-filtered; strict role scoping would fail here. |
| 49 | Awards & Honours | Direct | ✓ | ✓ | Screen is shared and intentionally/mistakenly mixes awards from both tiers; product decision needed. |
| 50 | News | Direct | ✓ | ✓ | Global world feed by implementation. |
| 51 | Realignment Event | Direct, incorrectly ungated | ✓ | Leak | Provider only requires a coach ID and always returns a model, even with no event. College-only conference realignment is exposed to pro coaches. |
| 52 | Career Hub | Direct | ✓ | ✓ | Career ledger shared across tiers. |
| 53 | Job Security | Alias → Career Hub | — | — | No current gameplay link; legacy restore/proof only. Distinct wrapper is unreachable. |
| 54 | Stakeholders | Direct | ✓ | ✓ | Shared career screen; pro still sees the college-flavoured `Boosters` stakeholder. |
| 55 | Promotion Decision | Direct, incorrectly ungated | ✓ | Leak | Visible whenever Career Hub exists, not only when a college coach has an actionable professional offer. |
| 56 | Coaching Carousel | Alias → Career Hub | — | — | No current gameplay link; legacy restore/proof only. Distinct wrapper is unreachable. |
| 57 | Record Book | Direct | ✓ | ✓ | Controlled organisation/history required. |
| 58 | Rivalries | Direct | ✓ | ✓ | Controlled organisation/history required. |
| 59 | Career Line | Direct | ✓ | ✓ | Coach history required. |
| 60 | Coaching Tree | Direct | ✓ | ✓ | Coach history required. |
| 61 | College Offseason | Conditional | ✓ | — | College-control model required; remains the canonical aggregate portal/NIL/retention host. |
| 62 | Pro Offseason | Conditional | — | ✓ | Professional appointment required; canonical front-office host. |

## Confirmed defects

### 1. Pro careers advertise an unreachable college route

`Recruit` is unconditional in Coaching HQ's primary strip and World menu, Roster's standard and accessibility navigation, and League Map's route bar. `navigate(.recruitingBoard)` then refuses because the pro store correctly has no recruiting read model.

Evidence:

- `Sources/ProFootballCoachUI/CoachingHQView.swift:129,158`
- `Sources/ProFootballCoachUI/RosterView.swift:117,737`
- `Sources/ProFootballCoachUI/LeagueMapView.swift:163`
- `Sources/CoachWorldApp/CoachWorldAppRootView.swift:1221-1237`

### 2. Retired aliases remain visible

All Tasks correctly filters aliases with `isCanonicalTask`, but HQ's World menu bypasses that source of truth. It advertises 13 retired names: Job Board, Offers, Appointment, Scheme Book, Personnel Packages, Staff Market & Profile, Portal Hub, Retention Decisions, Portal Market, NIL Allocation, Draft Board, Free Agency, and Pro Scouting Board.

The tap works only by canonicalizing to another task. The corresponding alias cases in `career(_:)` cannot execute because the switch input is already canonicalized.

Evidence:

- `Sources/ProFootballCoachUI/ScreenRegistry.swift:111-143`
- `Sources/ProFootballCoachUI/CoachingHQView.swift:151-215`
- `Sources/CoachWorldApp/CoachWorldAppRootView.swift:90,1154-1163`

### 3. Realignment is a college-only, event-only screen exposed everywhere

`realignment(from:)` returns a model for any career with a coach, including pro careers and seasons with no realignment. Both All Tasks and the HQ menu therefore advertise the route.

Evidence:

- `Sources/CoachWorldApp/CoachWorldRealignmentProvider.swift:6-36`
- `Sources/CoachWorldApp/CoachWorldAppRootView.swift:1112,1209-1212`
- `Sources/ProFootballCoachUI/CoachingHQView.swift:173`

### 4. Promotion is not scenario-gated

Promotion Decision appears whenever `careerHub != nil`. The focused panel is just the generic opportunity workspace, and a current pro appointment cannot accept another professional opportunity. The route should be college-only and conditional on an actionable professional offer, or be renamed to a general Opportunities task.

Evidence:

- `Sources/CoachWorldApp/CoachWorldAppRootView.swift:1115-1117,1332-1341`
- `Sources/CoachWorldApp/CoachWorldCareerProvider.swift:65-113`
- `Sources/ProFootballCoachUI/CareerHubView.swift:228-262`

### 5. Shared league intelligence is inconsistently tier-scoped

Standings, Schedule, Rankings, and Bracket receive the controlled tier. Statistics scans every player's statistics, and Awards merges every archived award from both tiers. If these are meant to be global, the UI should say so; if the requirement is strict role relevance, they need the same tier input as the other competition screens.

Evidence:

- `Sources/CoachWorldApp/CoachWorldStore.swift:99-112`
- `Sources/CoachWorldApp/CoachWorldStatisticsProvider.swift:6-71`

## Unreachable code and verification gap

The 15 alias wrapper views and their cases are dead as distinct production screens. Current contract tests can still report them as reachable because they search source text for `case .screen` and `ScreenView(` rather than driving the production router. The `62 converted` accessibility result likewise proves file-level composition, not gameplay reachability.

The missing regression check is a runtime matrix with at least these roots:

1. ordinary college week;
2. college signing phase;
3. controlled college match and aftermath;
4. college career with actionable pro offer;
5. ordinary pro week;
6. pro draft phase;
7. fired/seeking coach with no controlled team.

For each root, assert the exact advertised canonical task set and that every visible control reaches a non-refusal destination. This one matrix would catch the Recruit, Realignment, Promotion, and stale-alias problems above.

## Verification performed

- GitNexus index refreshed against the current checkout and navigation/game-control flows traced.
- `swift run SimTests --design-contracts`: **43 tests, 663 checks, passed**.
- `swift run SimTests --screen-read-models`: **66 tests, 9,695 checks, passed**.
- The passing lanes validate registry/read-model contracts; neither currently validates the role/scenario navigation matrix described above.
