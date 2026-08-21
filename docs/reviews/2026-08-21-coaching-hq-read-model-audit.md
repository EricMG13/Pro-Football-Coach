# Coaching HQ read-model audit — 2026-08-21

Family: `04` §8 screen 8, Coaching HQ. Audit unit: the production career route, including shared
Floodlit chrome, standard layout, AX5 reflow, decision/empty/disabled/delegated states, and the
transient intent receipt shown after an action.

## Result

**Pass: 31/40, no P0 or P1, no automatic design-specificity rejection.**

The current production source passes the specificity gate: the week plan/open obligation is the
dominant football object; the initial frame is not a five-card dashboard; team, week, opponent and
consequence are present; and no fixture/debug label appears in the production frame.

| Dimension | Score | Evidence |
|---|---:|---|
| Football fantasy | 4 | Team, week, opponent, preparation, health, stakeholders and the blocked week are visible as coaching work. |
| Task-specific composition | 5 | Agenda → due decision → availability/standing is a week-room composition that would not sensibly serve an unrelated task. |
| Information hierarchy | 4 | One due decision/open-work count dominates; supporting regions are bounded to agenda and team/world context. |
| World identity and continuity | 4 | Club, coach, season/week, record/rank, opponent, venue, people and prior intent receipt share one snapshot. |
| Decision and control | 4 | Inspect, select, commit, delegate, prepare and advance are distinct; cost, deadline, evidence and refusal state are visible. |
| Accessibility and readability | 3 | AX5 branch, 44 pt controls and deterministic sort priorities exist; generated matrix is complete, but rendered and physical-device cells remain unverified. |
| Truthfulness | 4 | Every production fact below has a named source; absent engine facts are omitted or labelled unavailable. |
| Craft and resilience | 3 | Normal, empty, disabled and AX5 source states are composed; stored proof images predate the dark-only/week-granular production screen. |

## Displayed-fact map

Static headings, route names and control verbs are interface vocabulary, not claims about the
simulated world. They map to `CoachWorldScreenID`, `FloodlitChromeReadModel.rail/siblings`, or the
button's injected intent. Every changing fact maps as follows.

| Displayed fact | Named read model/source | Authoritative root or derivation | Absence rule |
|---|---|---|---|
| Club name, mark and generated colours | `FloodlitChromeReadModel.club` ← `CoachingHQReadModel.team` | controlled `Programme`/`ProTeam`, `TeamIdentity`, logo catalogue keyed by stable organisation ID | canonical blank mark/neutral identity fallback; no borrowed asset |
| Record | `FloodlitChromeReadModel.record` ← `CoachingHQReadModel.recordLabel` | `CompetitionState.standings` row for the controlled organisation | `Record unavailable`; never `0-0` without a row |
| Ranking | `FloodlitChromeReadModel.ranking` ← `CoachingHQReadModel.rankLabel` | controlled ID's index in `CompetitionState.rankings` | omitted when unranked or no ranking table |
| Header week/opponent chip and opponent pennant | `FloodlitChromeReadModel.context/contextOpponent` ← `CoachingHQReadModel.week.currentDay/opponent` | week-granular `CalendarState`; current unplayed `ScheduledGame` | omitted on a bye; no invented weekday |
| Current family, sibling links, icon rail, available destinations | `FloodlitChromeReadModel.screen/rail/siblings/availableScreens` | canonical `CoachWorldScreenID` registry plus retained route read models | unavailable destinations omitted |
| Team and coach identity in bare-stage/debug rendering | `CoachingHQReadModel.team/coach` | controlled organisation and appointed `Staff` | whole HQ model is nil without a controlled career |
| Season, week and current period | `CoachingHQReadModel.week` | `CalendarState`; current period repeats the week because the engine has no day clock | no day/date invented |
| Next deadline | `CoachingHQReadModel.week.nextDeadline` | minimum `MandatoryDecision.deadline` | `No deadline this week` when none exists |
| Open/due counts and each obligation's title/status | `CoachingHQReadModel.obligations` | controlled organisation's pending mandatory decisions | zero is the actual empty collection; no cleared-history count is shown |
| Obligation consequence | `CoachingHQReadModel.Obligation.consequence` | `IntentResolver` blocks week advance while any mandatory decision remains | fixed wording names the enforced rule only |
| Four management lanes and their state | `CoachingHQReadModel.weekPlan` | pending decisions, current tactical plan, current practice plan, recruiting board/contact points and current fixture | `No game scheduled` on a bye; no preparation lane is current without a fixture |
| Unallocated practice minutes | `CoachingHQReadModel.unallocatedPracticeMinutes` | `TacticalPracticePlan.weeklyMinutes` minus the all-or-nothing current-week plan state | never negative; zero only when this week's plan exists |
| Decision title, deadline and evidence | `CoachingHQReadModel.decision` | first user-owned `MandatoryDecision`; subject entity, deadline and recorded reason codes/values | decision region becomes an honest empty/preparation state |
| Choice title, cost, availability and selected draft | `CoachingHQReadModel.Decision.choices` plus local `selectedChoiceID` | recorded decision options; the option schema has no cost, so the read model says `No recorded cost`; selection remains local until commit | no numeric cost, staff verdict or option consequence is shown because the engine records none |
| Selection/commit receipt | local selection state plus injected `CoachWorldStore.statusMessage` | unsaved local choice, or the exact result/refusal from the intent boundary | explicitly says `unsaved`/`not saved`; never claims persistence before commit |
| Squad slot, player, injury/suspension/fatigue status | `CoachingHQReadModel.squadHealth` | roster read model joined to `PlayerLifecycleState`, bounded to three actionable rows | panel omitted when no player is flagged |
| Stakeholder name and support out of 100 | `CoachingHQReadModel.stakeholders` | `CareerArcState.stakeholderSupport`; domain is explicitly 0...100 | panel omitted before stakeholder state exists |
| Correspondence sender, subject, received state | `CoachingHQReadModel.correspondence` | no production inbound-event system exists | production collection is empty; sample proof content remains `.sample` fixture data only |
| Staff name/verdict/confidence | `CoachingHQReadModel.staffRecommendation` | engine records no staff author or confidence for the recommendation | production value is nil; only labelled `.sample` proof fixtures may supply it |
| Opponent and venue in the desk/identity rail | `CoachingHQReadModel.opponent/venue` | current unplayed schedule entry and home organisation's `TeamIdentity.venueName` | block omitted on a bye; missing venue says `Venue not set` |
| Advance enabled/disabled state | derived from `obligations`, `decision`, and current `weekPlan` preparation lane | mirrors `IntentResolver.advanceWeek` mandatory-decision and current-fixture preparation gates | bye weeks remain advanceable |
| Empty/preparation explanation | `week.nextDeadline`, `obligations`, current `weekPlan`, or exact `statusMessage` | same gates and intent receipt as above | no progress percentage or estimated completion |

## Findings

### P1 fixed before lower-severity work

1. **Invented staff authority and percentage.** The provider selected the highest-rated coordinator,
   attributed the engine's system recommendation to that person, and synthesized 25–95% confidence.
   Production now returns `staffRecommendation: nil` until the engine records author and uncertainty.
2. **Ownerless option verdict.** A recommended option was labelled `The staff recommendation`
   despite no recorded staff author. Production option consequences are now absent.
3. **Invented `0-0`.** A missing standings row displayed a numeric record. HQ now says
   `Record unavailable`.
4. **Invented Saturday.** The desk named a weekday the week-granular engine does not store. It now
   says `Next fixture`.
5. **Bye-week dead end.** Practice was marked current without a fixture, disabling Advance while the
   engine refused the offered preparation action. Practice is current only when a fixture exists.
6. **Invented cleared count.** `0 of N cleared` had no retained original total/history. The line was
   deleted.
7. **Deadline presented as cost.** Decision choices displayed `This week` in a field announced as
   Cost, but the option schema has no price. It now says `No recorded cost`; no figure was invented.

### P2 retained and scored upward

- The accessibility manifest covers 62 families and 7,936 combinations but remains `not-run` for
  automated rendering and `manual-required` for spoken/motor/audio/haptic evidence.
- `docs/proofs/coaching-hq-*.png` shows the retired light/sample Monday–Sunday screen, not the current
  dark-only, week-granular production surface. It cannot support a score of 4 for accessibility or
  craft.

## Verification

- `python3 .agents/skills/verify-ios-accessibility-matrix/scripts/build_matrix.py`: 62 unique
  families, registry match; automated evidence not run, manual evidence required.
- `swift run SimTests --screen-read-models`: 69 tests, 9,704 checks, all passed.
- `swift run SimTests --history-read-model`: 4 tests, 24 checks, all passed.
- `swift run SimTests --core-contracts`: 225 tests, 3,147 checks, all passed.
- GitNexus `detect_changes(scope: unstaged)`: expected HQ provider/view/test paths detected; HIGH
  because `coachingHQ` feeds Inbox and `weekPlan` crosses tactical/practice flows. The broader
  `main` comparison is CRITICAL due to unrelated pre-existing branch/worktree changes.

## Confidence review

Least confident about, ranked:

1. Choice cost truth: confirmed P1 — `MandatoryDecisionOption` has no cost, while the view announced
   `This week` as Cost. Patched to the explicit absence `No recorded cost` and covered by the
   truthfulness test.
2. Bye-week progression: verified fine — `weekPlan` now requires the same current unplayed fixture
   that gates preparation in `IntentResolver`; the added bye case advances successfully.
3. Missing record/rank: verified fine — an adversarial state with empty standings and rankings
   returns `Record unavailable` and no rank.
4. Staff attribution and uncertainty: verified fine — production returns no staff recommendation,
   and every choice omits the unowned consequence.
5. Current visual/accessibility evidence: open P2 — stored HQ proofs predate the current production
   composition and the generated accessibility matrix has no rendered or physical evidence. This is
   why accessibility and craft remain capped at 3.

Fixed: choice cost truth. Verified fine: bye progression, absent competition rows, staff omission,
and exact intent receipts. By design: local unsaved-choice state is labelled unsaved. Still open:
current rendered and physical accessibility proof.
