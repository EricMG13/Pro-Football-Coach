# Coaching HQ → Roster → Player Profile mock contract

Status: frozen for the approved vertical slice. The mock files are user-provided design data; the
production read models and callbacks are behavioral truth. This record is a contract and omission
ledger, not a roadmap.

## Canonical mock sources

| Production screen | Canonical source | Frame | SHA-256 |
|---|---|---|---|
| Coaching HQ | `/Users/ericguei/Downloads/UI surfaces refinement/This Week.dc.html` | `6a` | `441cf7e08da2b3a850c98dfb1c37f38a1235f3d32bf3b4f65e2c04c73325ded3` |
| Roster | `/Users/ericguei/Downloads/UI surfaces refinement/Personnel.dc.html` | `2a` | `f888a27307c9267db09167578e8750280f02ea1f48dbb1758fa80d8f49fe2704` |
| Player Profile | `/Users/ericguei/Downloads/UI surfaces refinement/Personnel Family.dc.html` | `7f` | `6bc68e76a5d573732d8c018f7be220f4d94bae81fffd6fe9495ebe3b646da2a9` |

`Personnel` frames `2b` and `2c` are alternatives and remain parked. The broad HTML canvases are
not product input and their generated code is not copied.

The mocks' silence about logos is neutral: it does not authorize removing production logos.

## Contract matrix

| Screen / mock region | UX purpose | Current source | Disposition | Production treatment | Accessibility |
|---|---|---|---|---|---|
| HQ / shared chrome | Establish team, world, and routes | `This Week.dc.html` 6a; `CoachingHQView.worldStrip` / `worldMenu` | Keep | Use `FloodlitChromeReadModel` when supplied and real `onNavigate` routes | Route buttons and menu remain named controls; shared identity is read as one element |
| HQ → Roster → Profile / existing team/program logo identity | Preserve established game identity across the three-screen slice | Existing shared chrome or screen component logo rendering; current read models/assets | Keep | Preserve logos already rendered by shared chrome or an existing screen component when current read models/assets provide them; do not invent logo data, duplicate a shared-chrome logo inside a screen, add logo assets, or create speculative placements solely because the mocks omit them | Preserve the existing logo component's accessibility semantics; decorative marks must not create duplicate announcements |
| HQ / current week facts | Orient the coach to the actual current week | `CoachingHQReadModel.WeekContext` and `weekAgendaColumn` | Keep | Show truthful `weekLabel`, `currentDay`, and open-obligation count from the read model | Week facts are exposed as text, with dynamic type layout |
| HQ / weekly/open-work heading | Name the work window without asserting a fixed deadline | Mock `BEFORE SATURDAY`; `weekAgendaColumn` | Adapt | Replace `BEFORE SATURDAY` with a truthful weekly/open-work heading; do not imply a fixed Saturday deadline | Heading is exposed as text and remains readable at large type |
| HQ / obligations and work rows | Show work that can change the week | Mock work list; `CoachingHQReadModel.obligations` | Keep | Render actual obligation titles, due text, consequences, and mandatory state | Rows expose title, due, consequence, and state; no decorative-only completion claim |
| HQ / obligation actions | Let the coach act on supported work | `onInspect`, `onDelegate`, `onPrepare`, and decision callbacks in `CoachingHQView` | Adapt | Route work actions through actual callbacks; primary wording names the available action | Actions are named controls with supported enabled/disabled state |
| HQ / decision card | Let the coach make the real weekly decision | Mock decision; `CoachingHQReadModel.Decision.choices`; `onCommit` | Keep | Render the bounded real choices and commit the selected `CoachWorldIntentID`; film/delegate use their callbacks | Choice labels and consequences are spoken; disabled/unavailable reasons remain available |
| HQ / next opponent and venue | Provide next-fixture facts | Mock kickoff panel; `model.opponent` and `venue` in `CoachingHQView` | Keep | Show the real opponent and venue/context available from the read model | Opponent and venue are grouped as readable text |
| HQ / kickoff panel treatment | Present fixture context without fabricated timing | Mock kickoff countdown and primary action wording | Adapt | Remove the fabricated clock; primary wording names the actual available action | No unsupported time value is announced; action remains a named control |
| HQ / squad health | Surface availability and condition context | Mock squad panel; `CoachingHQReadModel.squadHealth` | Keep | Use the read model's actual slots, players, status, and support values | Status is text, not color alone; rows retain readable labels |
| HQ / stakeholder state | Show supported stakeholder context | Mock staff/state panel; `ScreenReadModels` fields | Keep | Render the actual populated stakeholder state available in the read model | State is text and not conveyed by color alone |
| HQ / staff recommendation | Recommend a weekly choice with confidence | Mock staff recommendation; optional `staffRecommendation` in `ScreenReadModels` | Omit | Do not render the mock recommendation; the current provider supplies no authoritative recommendation for this slice | Omission avoids attributing unsupported advice to staff |
| HQ / `4 of 7 done` progress | Claim authoritative completion progress | Mock `4 of 7 done` | Omit | Do not show a completion count without an obligation completion ledger | No completion state is announced as fact |
| HQ / exact kickoff countdown | Show a continuously ticking deadline | Mock `3d 06h` | Omit | Do not show an exact countdown; use read-model-backed week and fixture context only | No unsupported time value is announced |
| HQ / opponent spread/streak | Show matchup trend data | Mock opponent spread/streak | Omit | Do not show spread or streak without a production field | No unsupported betting/trend claim is announced |
| HQ / since-Sunday delta feed | Show a chronological change feed | Mock `SINCE SUNDAY` feed | Omit | Do not show a delta feed without a feed model and route | No absent event stream is announced |
| HQ / inbound correspondence feed | Read and answer desk correspondence | Mock correspondence feed; optional `correspondence` and `onOpenCorrespondence` | Omit | Do not include the feed in this slice; the required inbox state and answer flow are outside the contract | No unavailable inbox content is exposed |
| HQ / local success and undo | Confirm or reverse a local action | Mock success/undo states | Omit | Do not show local receipts or undo without a supported mutation callback/state transition | Avoids announcing an action that did not occur |
| HQ / routes and Continue | Move through the real career loop | Mock navigation; `onNavigate`, `onContinue`, `canAdvance` | Keep | Use existing route callbacks; Continue is enabled only when the model permits advancement | Minimum target sizing and disabled hint explain why advancement is unavailable |
| Roster / summary metrics | Establish capacity and personnel pressure | Mock summary; `RosterReadModel.rosterLimit`, `injuryCount`, `openNeedCount` | Keep | Show roster capacity, injury count, and open-need count from the read model | Labels and values are read together; counts are not color-only |
| Roster / class counts | Let the coach scan class distribution | Mock class summary; `RosterView.classCounts` derived from player rows | Keep | Derive counts from the actual rows and academic years | Each class count has a text label |
| Roster / sortable comparison table | Compare the whole roster efficiently | Mock table; `RosterSortDescriptor` and `visiblePlayers` | Keep | Retain sortable number/name/position/overall/development/condition columns and stable selection | Sort control announces field and direction; rows and targets remain usable at large type |
| Roster / selected dossier | Inspect the selected player's actionable summary | Mock dossier; `selectedPlayer`, profile fields, `dossierAttributes` | Keep | Show rating, fit, condition, availability, four attributes, concern, and the selected player's evidence | Selected state is communicated beyond color; dossier has a clear empty state |
| Roster / thinness label | Explain roster need | Mock `THIN AT EDGE · S`; `openNeedCount` | Adapt | Replace position-specific thinness with the available aggregate open-need count | The count is a literal text value and does not imply a position |
| Roster / availability label | Explain player readiness | Mock `AVAILABLE`; `PlayerRow.availability` | Adapt | Name the existing availability string exactly as supplied; do not imply a new availability state | Availability is text and not conveyed by color alone |
| Roster / full profile route | Reach the profile surface | `onOpenProfile` / sheet route | Keep | Preserve the existing profile route from the selected player | Route is a named, minimum-size action |
| Roster / dossier action wording | Make the profile action truthful and concise | Mock `OPEN THE FULL DOSSIER` | Adapt | Say `Open full dossier` | Action remains a named, minimum-size button |
| Roster / alternative layouts | Offer inline or grouped variants | `Personnel.dc.html` frames `2b`, `2c` | Omit | Keep the selected frame `2a`; do not add inline expansion or grouped-card variants | One stable interaction model is easier to navigate and test |
| Profile / identity and headline | Identify the player and establish context | Mock player frame 7f; `PlayerProfileReadModel.person`, number, position, overall | Keep | Use real identity and rating | Identity is grouped; rating is presented with a textual value |
| Profile / status and fit | Explain readiness and scheme relevance | Mock status; `academicYear`, `availability`, `condition`, `schemeFit` | Keep | Render the read-model values | Status is text and not conveyed by color alone |
| Profile / route tabs | Move among profile evidence surfaces | Mock `OVERVIEW`, `ATTRIBUTES`, `DEVELOPMENT`, `HISTORY`; `PlayerProfileView` route state | Keep | Retain the four route tabs and existing navigation callback | Current tab is exposed with semantic selection/current state |
| Profile / strengths and concern | Summarize useful evidence and risk | Mock summary; `strengths`, `concern` | Keep | Render actual lists and concern text | Lists and headings preserve reading order |
| Profile / attributes | Inspect measured player traits | Mock nine-value groups; `attributeGroups` | Keep | Render read-model groups and values; no estimated values | Labels and values are adjacent; grouping is announced |
| Profile / recent form evidence | Ground form in available game evidence | `PlayerProfileReadModel.recentForm` | Keep | Render the available recent-form entries and ratings | Entries are read in order with their opponent and rating |
| Profile / games-on-record presentation | State how much recent-form evidence exists | Mock `6 GAMES ON RECORD`; `recentForm.count` | Adapt | Use the real `recentForm.count`; empty form says no recorded games rather than asserting six | Count is derived and announced as text |
| Profile / hometown | Provide optional biographical context | Mock hometown; `hometown` and `team` | Adapt | If hometown is absent, show the team only; otherwise show team and hometown | The combined identity line remains a single understandable element |
| Profile / staff evidence | Show what staff has actually recorded | Mock staff quote; `staffSummary` and `quote` empty treatment | Adapt | Use current honest absence treatment when evidence is empty; never invent a quote | Empty state is explicitly spoken |
| Profile / development evidence | Reach supported development evidence | `developmentEvidence`, `onInspectDevelopment` | Keep | Preserve the existing development evidence and navigation callback | Evidence is distinguishable from controls |
| Profile / development control wording | Name the supported development action | Mock development panel control | Adapt | Control says `Open development evidence` | Button is a named action and remains a minimum-size target |
| Profile / history evidence | Review supported history evidence | Mock history panel; `historyEvidence` | Keep | Render the read-model history evidence as read-only content | Evidence is grouped and follows the profile reading order |
| Profile / back route | Return to personnel context | Mock back control; `onClose` | Keep | Preserve `Back to personnel` and the existing callback | Back action is first in the logical order and named plainly |
| Profile / editable development assignment | Assign hours and show resulting completion | Mock editable hours and completion/undo | Omit | No editable assignment, completion, or undo without a supported mutation callback | Avoids false confirmation of persisted work |

## Omission ledger

Every item below has a concrete trigger and is intentionally omitted from this slice. The ledger is
not a roadmap: an item is reconsidered only when the stated capability and trigger exist.

| Mock source | Omitted element | Implied behavior | Why unsupported | Missing capability | Reconsider when |
|---|---|---|---|---|---|
| This Week 6a | `4 of 7 done` | Track seven work items and completion progress | No matching completion ledger in the HQ read model | Persisted obligation completion state | A read model supplies authoritative completed/total counts |
| This Week 6a | Exact `3d 06h` countdown | Tick a kickoff timer continuously | `WeekContext` exposes labels/deadline, not a clock or timer callback | Authoritative time source and update policy | A supported countdown is provided and tested across lifecycle changes |
| This Week 6a | Opponent spread/streak | Show betting or matchup trend data | No production field or source callback | Backed opponent trend/statistics data | A read model supplies provenance-backed spread/streak values |
| This Week 6a | Since-Sunday delta feed | Show a chronological delta stream | No feed model or update/read route | Delta-feed read model and lifecycle | A supported feed is reachable from HQ |
| This Week 6a | Inbound correspondence feed | Read and answer correspondence from the desk | Callback exists for supplied correspondence, but this slice has no required inbox feed/state contract | Authoritative inbox contents and answer mutation | Inbox state and answer route are part of the tested flow |
| This Week 6a | Staff recommendation | Present a recommendation and confidence | Optional field may be absent and must not be fabricated | Populated, provenance-backed recommendation | `staffRecommendation` is populated for the scenario and its empty state is covered |
| This Week 6a | Local success/undo states | Confirm or reverse a local action | No matching persistence/undo callback | Mutation receipt and undo capability | A supported mutation returns an authoritative receipt and undo action |
| Personnel 2a | Position-specific `THIN AT EDGE · S` | Claim a thin position and class | Only aggregate `openNeedCount` is available | Position-scoped needs data | Position-scoped needs are supplied by the read model |
| Personnel 2b | Inline expansion alternative | Expand a row in place into more content | Selected frame and current view use a dossier/selection model | An approved inline expansion interaction contract | Design and route tests explicitly select inline expansion |
| Personnel 2c | Grouped-card alternative | Replace table comparison with grouped cards | It changes the selected frame's comparison and sorting behavior | Approved grouped-card layout and equivalent sorting semantics | Product explicitly selects 2c and covers its interaction contract |
| Personnel 2a | Invented `STAFF PICK` claim | Mark one player as recommended | No authoritative pick field/callback | Backed staff-pick state | A read model supplies a populated staff pick |
| Personnel Family 7f | Fixed `6 GAMES ON RECORD` | Claim a constant six-game history | `recentForm.count` varies and may be empty | Authoritative fixed-count history would be required | Reconsider only if a production contract explicitly supplies a fixed, provenance-backed game count |
| Personnel Family 7f | Invented hometown | Fill missing biography with a plausible place | Hometown is optional and must remain truthful | Authoritative hometown value | The read model provides the hometown |
| Personnel Family 7f | Invented staff quote | Attribute unsupported prose to staff | Empty staff evidence is explicitly supported | Authoritative staff evidence | A populated staff evidence field is available |
| Personnel Family 7f | Editable development-hours assignment | Persist hours and alter the plan | Profile exposes evidence/navigation, not an assignment mutation | Development assignment action and persistence | A supported assignment callback and receipt exist |
| Personnel Family 7f | Completion/undo state | Confirm or reverse development assignment | No supported mutation state | Mutation receipt and undo capability | The development flow supplies both and tests them |

## Proof checklist

The durable image set below uses the production DEBUG root, the existing
`PROOF_NEW_CAREER=424242` / `PROOF_SCREEN_NUMBER` seam, dark appearance, landscape, and real
generated-career read models. The images were inspected after capture; they were not treated as
proof merely because the simulator produced a file.

| Surface | 844×390 — iPhone 17e | 852×393 — iPhone 15 Pro | 956×440 — iPhone 17 Pro Max |
|---|---|---|---|
| Coaching HQ | [default](../proofs/mock-reconciliation-vertical-slice/hq-844-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/hq-844-ax5.png) | [default](../proofs/mock-reconciliation-vertical-slice/hq-852-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/hq-852-ax5.png) | [default](../proofs/mock-reconciliation-vertical-slice/hq-956-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/hq-956-ax5.png) |
| Roster | [default](../proofs/mock-reconciliation-vertical-slice/roster-844-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/roster-844-ax5.png) | [default](../proofs/mock-reconciliation-vertical-slice/roster-852-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/roster-852-ax5.png) | [default](../proofs/mock-reconciliation-vertical-slice/roster-956-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/roster-956-ax5.png) |
| Player Profile | [default](../proofs/mock-reconciliation-vertical-slice/player-844-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/player-844-ax5.png) | [default](../proofs/mock-reconciliation-vertical-slice/player-852-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/player-852-ax5.png) | [default](../proofs/mock-reconciliation-vertical-slice/player-956-default.png) · [AX5](../proofs/mock-reconciliation-vertical-slice/player-956-ax5.png) |

Increase Contrast was also enabled through `simctl`, read back as `enabled`, and inspected at the
narrowest width for [Coaching HQ](../proofs/mock-reconciliation-vertical-slice/hq-844-increased-contrast.png),
[Roster](../proofs/mock-reconciliation-vertical-slice/roster-844-increased-contrast.png), and
[Player Profile](../proofs/mock-reconciliation-vertical-slice/player-844-increased-contrast.png).
Each Increase Contrast capture is byte-identical to that surface's default 844 capture: the
explicit dark palette does not change, and inspection found no lost content or state distinction.
Existing shared-chrome team/program logos remain visible once per surface in the captures. No local
logo rendering or logo data was added. Pixel inspection and source scope support the no-duplicate
visual claim; duplicate *spoken* announcements remain a physical-device/manual item.

- [x] Verify real-career reachability into Coaching HQ.
- [x] Reach Roster from a real route and Player Profile from the real roster selection/dossier route.
- [x] Verify all displayed values come from real read-model data, not mock-only literals. The
  accessibility lane's read-model suite passed 69 tests and 9,704 checks against the production
  providers, and the captures use the generated career rather than mock state.
- [ ] Verify every presented action has a supported callback and reachable result. Static contracts
  verify supported callbacks and the focused test proves the slice route, but every HQ action result
  was not activated during this audit.
- [ ] Verify populated, empty, unavailable, and error states for each surface. The real populated
  route was exercised. This slice supplies no mock or production seam for the other three states;
  inventing them solely to complete a matrix is outside the contract.
- [x] Verify landscape widths of 844, 852, and 956 points.
- [x] Verify default type size and AX5 accessibility type size.
- [ ] Verify VoiceOver order, labels, selected/current states, and action hints. Automated XCTest
  accessibility-tree lookup proves distinct route/control labels in default and AX5 and static
  contracts cover current/selected semantics; spoken order, clarity, and hints remain
  manual-required.
- [ ] Verify Reduce Motion behavior. The automated source contract passed 5 tests / 10 checks (one
  declared animating family, 61 still families); actual assistive-setting behavior remains
  manual-required.
- [ ] Verify Reduce Transparency behavior. The available simulator control does not expose this
  setting; manual-required.
- [x] Verify Increase Contrast behavior at the supported narrow width; see durable captures above.
- [ ] Verify Differentiate Without Color behavior. The available simulator control does not expose
  this setting; manual-required.
- [x] Verify all interactive targets are at least 44 points through the design-contract gate.
- [x] Run the focused contract and vertical-route tests. The real HQ → Roster → Player Profile →
  Roster route passed at default and AX5 after the test selector and profile accessibility grouping
  were corrected.
- [ ] Run final repository gates, including the expected test/build checks and GitNexus change
  detection. Design contracts, accessibility, app build, focused default/AX5 routes, and GitNexus
  change detection pass. The full lane remains blocked by the deterministic pre-existing
  `Controlled college portal decisions / spring retention choices pause a user-owned portal
  responsibility` test: its final week advance throws
  `missingWeeklyPreparation([.gamePlan, .practicePlan])`. The full run completed 992 tests and
  795,451 checks with exactly this one failure; the focused `--career-portal-decisions` run
  reproduced it (1 test, 6 checks, 1 failure). This branch does not modify
  `CareerControlTests.swift` or `FootballSimCore`, and this unrelated test is not patched by the
  vertical-slice task.

Manual-required items are not waived: VoiceOver spoken clarity/order, Voice Control naming,
Switch Control reachability, sound equivalents, haptics, physical-device behavior, Reduce
Transparency, Differentiate Without Color, and the runtime Reduce Motion experience still need a
named tester, device, OS, and result. Simulator captures do not prove any of them.
