# 01 — REPOSITORY UI INVENTORY

Baseline as of 2026-08-22, branch `agent/floodlit-injury-evidence`. Established by direct source
inspection before any external source was consulted. **Grade A throughout** — every claim here is
observation of files in this repository.

**Headline: the brief's premise that "no UX or UI artefact currently in the repository is final" is
correct as a statement of authority, and badly wrong as a statement of maturity.** The design
system is substantially built, its component vocabulary independently matches benchmark precedent,
and the engine/UI boundary is clean and test-enforced. The gap is composition and data, not
vocabulary. Dispositions below reflect that.

---

## 0. Three premises in the brief that the repository contradicts

These must be corrected before any downstream artefact repeats them.

| Brief asserts | Reality | Consequence |
|---|---|---|
| "the existing **READOUT / DESTINATION** split found in the repo" | **Does not exist.** Zero occurrences in `Sources/ProFootballCoachUI/`. The actual IA primitive is `CoachWorldScreenID` + `CoachWorldSurfaceFamily` | §5.2 of the brief cannot "validate the split". [`04`](04-INFORMATION-ARCHITECTURE.md) validates the *registry* instead, and adopts a readout/action distinction from **Madden's** `HOME/NEWS/ACTIONS/TEAM/LEAGUE`, which is a real precedent |
| "Every screen proposal survives **`SmallestDeviceLayoutTest`**" | **No such test.** Nearest is `Tests/SimTests/Suites/AccessibilityReflowTests.swift`. The floor exists as constants: `CoachWorldTokens.Frame.floorWidth = 844`, `floorHeight = 390` | The invariant is kept but re-pointed. [`06`](06-TOKENS-AND-DENSITY.md) §3 specifies the test that must be *written* |
| "Reuse **`CalibrationBands`** if the existing definition survives scrutiny" | **Category error.** `CalibrationBands` is at `Sources/FootballSimCore/Calibration/CalibrationBands.swift` and holds *simulation* statistical bands. It is not a design token and must never be imported by a view | The UI's rating-band equivalent is `CoachWorldTokens.Heat` (red <70, amber 70–84, green ≥85). [`06`](06-TOKENS-AND-DENSITY.md) §2.6 governs |

---

## 1. Module structure and scale

```
Sources/FootballSimCore/     114 files   pure simulation, no UI import
Sources/ProFootballCoachUI/  100 files   ~21,000 lines, SwiftUI feature layer
Sources/CoachWorldApp/        27 files   composition layer, the only target seeing both
Tests/SimTests/                          hand-rolled harness (XCTest needs full Xcode)
```

Root also holds **8 `*-v3.dc.html` design references** (broadcast, chrome, failure, person, readout,
table, tokens, week) — owner-approved 2026-08-12, and canon per `CLAUDE.md`.

---

## 2. Surface inventory

`CoachWorldScreenID` registers **62 screens**, numbered 1–62, partitioned by
`routeDisposition` into **47 canonical tasks** and **15 aliases**, across **7 families**
(`weeklyCommand`, `personnel`, `recruiting`, `proManagement`, `league`, `career`, `entry`).

Family membership is *derived from the screen*, not stored beside it, so the compiler forces a
family choice on every new case. That is coverage-by-construction and is exactly what `CLAUDE.md`'s
conventions demand.

### 2.1 Weekly command (9 screens)

| # | Screen | File | Lines | Reads | Mutates | Ruling |
|---|---|---|---:|---|---|---|
| 8 | Coaching HQ | `CoachingHQView.swift` | 937 | week read model, agenda, staff voices | navigation intents, week advance | **REFACTOR** — the cruise surface; concept correct, but must adopt the Agenda contract in `04` §4 |
| 9 | Inbox | `InboxView.swift` | 269 | `InboxReadModels` | read/unread, item actions | **KEEP** |
| 10 | Opponent report / film room | `OpponentReportFilmRoomView.swift` | 43 | delegates to `OpponentFilmView` (218) | — | **KEEP** (thin wrapper, §3.2) |
| 11 | Game plan | `GamePlanView.swift` | 192 | game-plan read model | plan selections | **REFACTOR** — needs consequence framing, `05` `DecisionCard` |
| 12 | Practice plan | `PracticePlanView.swift` | 185 | practice read model | practice allocation | **REFACTOR** — same |
| 13 | Team health | `TeamHealthView.swift` | 320 | `TeamHealthReadModels` (79) | availability responses | **KEEP** |
| 14 | Match day | `MatchDayView.swift` + `MatchDayField.swift` + `MatchDayScoreBug.swift` | 1020 + 968 + 482 | recorded match read model | none (immutable read model) | **REFACTOR** — see §4.1; the chrome is heavier than the benchmark's |
| 15 | Aftermath | `AftermathView.swift` | 262 | aftermath read model | acknowledgements | **KEEP** |
| 47 | Game detail / box score | `GameDetailBoxScoreView.swift` | 238 | box score read model | — | **KEEP** |

### 2.2 Personnel (8 screens: 6 canonical, 2 aliased)

| # | Screen | File | Lines | Ruling |
|---|---|---|---:|---|
| 16 | Roster | `RosterView.swift` | 846 | **REFACTOR** — the densest surface in the product; must be bound to the 72-cell budget (`00` §4) and given a column-set control |
| 17 | Depth chart | `DepthChartView.swift` | 483 | **KEEP** — already reasons explicitly about the 390 pt field and the install floor |
| 18 | Player profile | `PlayerProfileView.swift` | 383 | **REFACTOR** — must carry `ConfidenceTag` and ranged ratings (`06` §2.5) |
| 19 | Development plan | `DevelopmentPlanView.swift` | 232 | **KEEP** |
| 20 | Staff room | `StaffRoomView.swift` | 228 | **REFACTOR** — becomes the delegation-configuration surface (`04` §5) |
| 21 | Staff market & profile | `StaffMarketProfileView.swift` | 29 | **KEEP** (alias → 20) |
| 22 | Scheme book | `SchemeBookView.swift` | 41 | **KEEP** (alias → 11) |
| 23 | Personnel packages | `PersonnelPackagesView.swift` | 41 | **KEEP** (alias → 17) |

### 2.3 Recruiting (11 screens: 7 canonical, 4 aliased)

| # | Screen | File | Lines | Ruling |
|---|---|---|---:|---|
| 24 | Recruiting board | `RecruitingBoardView.swift` | 935 | **REFACTOR** — density budget; strongest candidate for the MLB-The-Show scout-card pattern (`05` `DelegateAssignmentCard`) |
| 25 | Prospect profile | `ProspectProfileView.swift` | 304 | **REFACTOR** — ranged ratings + printed band legend (`06` §2.5) |
| 26 | Shortlist | `ShortlistView.swift` | 235 | **KEEP** |
| 27 | Contact & visit planner | `ContactVisitPlannerView.swift` | 233 | **REFACTOR** — delegation rates must print on the card |
| 28 | Class overview | `ClassOverviewView.swift` | 245 | **KEEP** |
| 29 | Signing day | `SigningDayView.swift` | 65 | **REBUILD** — one of the five sanctioned ceremony surfaces (`00` §6.3); currently thin |
| 61 | College offseason | `CollegeOffseasonView.swift` | 346 | **KEEP** |
| 30/31/32/33 | Portal hub / retention / portal market / NIL | 35 each | **KEEP** (aliases → 61) |

### 2.4 Pro management (8 screens: 5 canonical, 3 aliased)

| # | Screen | File | Lines | Ruling |
|---|---|---|---:|---|
| 34 | Cap & contracts | `CapContractsView.swift` | 33 | **KEEP** (wrapper → `ProManagementView`, 323) |
| 35 | Contract negotiation | `ContractNegotiationView.swift` | 356 | **KEEP** |
| 36 | Roster cuts & transactions | `RosterCutsTransactionsView.swift` | 33 | **KEEP** (wrapper) |
| 39 | Draft room | `DraftRoomView.swift` | 63 | **REBUILD** — ceremony surface; the OOTP/Show draft-room pattern (queue + on-the-clock + up-next) is not present |
| 62 | Pro offseason | `ProOffseasonView.swift` | 434 | **KEEP** |
| 37/38/40 | Pro scouting / draft board / free agency | 42 each | **KEEP** (aliases → 62) |

### 2.5 League (11 screens)

| # | Screen | File | Lines | Ruling |
|---|---|---|---:|---|
| 41 | League map | `LeagueMapView.swift` | 768 | **KEEP** |
| 42 | Team / programme profile | `TeamProgrammeProfileView.swift` | 309 | **KEEP** |
| 43 | Standings | `StandingsView.swift` | 261 | **KEEP** |
| 44 | Schedule | `ScheduleView.swift` | 231 | **KEEP** |
| 45 | Rankings & playoff picture | `RankingsPlayoffPictureView.swift` | 41 | **KEEP** (wrapper → `CompetitionOverviewView`, 276) |
| 46 | Bracket / postseason | `BracketPostseasonView.swift` | 41 | **KEEP** (wrapper) |
| 48 | Statistics & leaders | `StatisticsLeadersView.swift` | 124 | **REFACTOR** — needs league-relative bands (`07` GAP-02) |
| 49 | Awards & honours | `AwardsHonoursView.swift` | 126 | **REBUILD** — ceremony surface |
| 50 | News | `NewsView.swift` | 159 | **REFACTOR** — becomes the always-one-control-away feed (`04` §3) |
| 51 | Realignment event | `RealignmentEventView.swift` | 74 | **KEEP** |
| 7 | World search | `WorldSearchView.swift` | 243 | **KEEP** |

### 2.6 Career (13 screens: 9 canonical, 4 aliased)

| # | Screen | File | Lines | Ruling |
|---|---|---|---:|---|
| 52 | Career hub | `CareerHubView.swift` | 486 | **KEEP** |
| 54 | Stakeholders | `StakeholdersView.swift` | 60 | **REFACTOR** — the natural home for a five-constituency approval readout (`07` GAP-09) |
| 55 | Promotion decision | `PromotionDecisionView.swift` | 60 | **REBUILD** — ceremony surface; the promotion arc is a v1 headline feature |
| 57/58/59/60 | Record book / rivalries / career line / coaching tree | 28 each | **KEEP** (wrappers → `LegacyHistoryView`, 175, via a `focus:` parameter) |
| 1 | Title / continue | `TitleContinueView.swift` | 153 | **KEEP** |
| 6 | Settings & accessibility | `SettingsAccessibilityView.swift` | 88 | **REFACTOR** — must gain the density-tier control (`06` §3.4) |
| 3/4/5/53/56 | Job board / offer / appointment / job security / carousel | 46–60 | **KEEP** (aliases → 52) |

### 2.7 Entry (2 screens)

| # | Screen | File | Lines | Ruling |
|---|---|---|---:|---|
| 2 | New career & coach identity | `NewCareerCoachIdentityView.swift` (46) + `NewCareerSetupView.swift` (215) | | **REFACTOR** — should adopt Madden's tick/cross capability list at the point of choice (`05` `CapabilityList`) |
| 5 | Appointment | `AppointmentView.swift` | 46 | **KEEP** |

### 2.8 Not registered

| File | Lines | Ruling |
|---|---:|---|
| `RootView.swift` | 328 | **KEEP** — routing shell |
| `RedesignedJobBoardProofView.swift` | 371 | **DELETE** — a proof artefact, not a product surface. Superseded by the job-board alias to Career Hub |
| `TeamLogoProofView.swift` | 44 | **DELETE** — proof tooling; belongs in `Tools/`, not the shipped module |
| `BlankPhotoPlate.swift` | 22 | **KEEP** |
| `TeamLogoCatalog.generated.swift` | 347 | **KEEP** — generated |

**Disposition totals, over 67 items (62 registry screens + 5 non-registered files):**
**KEEP 46 · REFACTOR 15 · REBUILD 4 · DELETE 2 · UNRESOLVED 0.**

REFACTOR (15): 2 New Career, 6 Settings, 8 Coaching HQ, 11 Game Plan, 12 Practice Plan,
14 Match Day, 16 Roster, 18 Player Profile, 20 Staff Room, 24 Recruiting Board,
25 Prospect Profile, 27 Contact & Visit Planner, 48 Statistics, 50 News, 54 Stakeholders.
REBUILD (4): 29 Signing Day, 39 Draft Room, 49 Awards, 55 Promotion Decision — all four are
ceremony surfaces. DELETE (2): the two proof views in §2.8.

No item is UNRESOLVED. Every ruling was decidable on the evidence gathered; where a REFACTOR
depends on an unbuilt system, the dependency is named in [`07`](07-GAP-REGISTER.md) rather than
parked here.

---

## 3. Component inventory

### 3.1 Formalised components

**Register (`CoachWorldDeskComponents.swift`).** `CoachWorldRegister { desk, broadcast }` — the
BROADCAST/DESK convention the brief refers to **does exist**, unlike READOUT/DESTINATION. Its
contract, verbatim from source: *"DESK gets the full committed backdrop (gradient, glow, grain).
BROADCAST is flat `page.color` only — the render-recorded-match contract forbids desk chrome,
gradients, and glow on a live match surface."*

| Component | File | Register | Ruling |
|---|---|---|---|
| `CoachWorldFloodlitStage` | Desk | both | **KEEP** — the composition root |
| `CoachWorldSystemState` (`.Kind`) | Vocabulary | desk | **KEEP** — empty/loading/error states |
| `CoachWorldStatusChip` (`.Tone`, `.Symbol`) | Vocabulary | both | **KEEP** |
| `CoachWorldDeltaMark` | Vocabulary | both | **KEEP** — the trend token |
| `CoachWorldRatingRing` | Vocabulary | both | **KEEP** — proportional stroke/text ratios, scales 26→118 pt |
| `CoachWorldMeter` | Vocabulary | desk | **KEEP** |
| `CoachWorldOpposedBar` | Vocabulary | both | **KEEP** — the two-sided comparison idiom |
| `CoachWorldAgendaRow` (`.pending/.complete/.delegated`) | Vocabulary | desk | **KEEP — see §3.3** |
| `CoachWorldIdentityBand` | Vocabulary | both | **KEEP** |
| `FloodlitChromeReadModel` (`.World`, `.RailEntry`, `.Sibling`) | Chrome | — | **KEEP** |
| `FloodlitIdentityHeader`, `FloodlitIconRail`, `CoachWorldWorldBackdrop` | Chrome | desk | **KEEP** |
| `FloodlitRegisteredNotBuilt` | Chrome | desk | **KEEP** — honest unbuilt-surface state |
| `FloodlitLabel3`, `FloodlitRow`, `FloodlitCard`, `FloodlitPill`, `FloodlitFlag` | Patterns | both | **KEEP** |
| `FloodlitArcGauge`, `FloodlitAttributeDial`, `FloodlitShareBar` | Patterns | both | **KEEP** |
| `FloodlitStaffVoice` | Patterns | desk | **KEEP — see §3.3** |
| `FloodlitCommittingAction`, `FloodlitCostLine` | Patterns | desk | **KEEP** |
| `CoachWorldConfidenceTag` (`.banded/.unknown/.observations`) | Patterns | both | **KEEP — see §3.3** |
| `CoachWorldCutCorner`, `CoachWorldGrainOverlay`, `CoachWorldActionButtonStyle`, `CoachWorldRouteButton` | Desk | desk | **KEEP** |

### 3.2 The thin-wrapper pattern is not a defect

Fourteen registered screens are 28–65 line files that delegate to a shared parent with a `focus:` or
`title:` parameter — e.g. `RecordBookView` → `LegacyHistoryView(focus: .recordBook)`,
`CapContractsView` → `ProManagementView(title: "CAP & CONTRACTS")`.

The brief anticipates copy-pasted markup as "the strongest signal of a missing primitive". **That
signal is absent here.** This is the opposite: one implementation, parameterised, with a registry
entry per addressable route. Ruled **KEEP** across the board.

### 3.3 Three components that already match benchmark precedent

This is the most consequential finding in the audit, and it inverts the brief's expectation.

- **`CoachWorldAgendaRow`** carries `title`, `timing`, `cost`, and
  `state ∈ {pending, complete, delegated}`. This is the FM25 Portal "Agenda" pattern — *"Attend
  Press Conference 1h / Confirm match squad 7h / Attend match 8h"* — **plus a delegated state FM25
  does not have.** The repo is ahead of the benchmark on the single most important cruise-surface
  primitive.
- **`CoachWorldConfidenceTag`** has `.banded(String)`, `.unknown`, and `.observations(Int)`, with a
  source comment reading *"Unknown is quiet, not alarming: an absent observation is not a bad one."*
  MLB The Show reaches the identical conclusion — it prints the literal word "Unknown" for
  unscouted fields rather than blanking or zeroing them.
- **`FloodlitStaffVoice`** is the shipped analogue of FM25's Dugout panel (assistant suggestion with
  "Do it" / "Ignore"). The component exists; what is missing is the **decision contract** around it
  — a scored cost for ignoring. See [`07`](07-GAP-REGISTER.md) GAP-09.

### 3.4 Missing primitives

Named here, specified in [`05`](05-COMPONENT-REGISTER.md), gap-tracked in [`07`](07-GAP-REGISTER.md):
`DecisionCard`, `DelegateAssignmentCard`, `ColumnSetControl`, `RangedRating`, `BandLegend`,
`LeaderMark`, `CapabilityList`, `NewsTicker`, `CeremonyPlate`.

---

## 4. Engine/UI boundary integrity

**No violations found. This is the healthiest part of the codebase and must not be weakened.**

Verified by direct inspection:

1. **`FootballSimCore` contains zero `import SwiftUI`.** One grep hit exists at
   `Sources/FootballSimCore/Rules/MatchupRules.swift:5` and is a **comment quoting the rule** —
   *"The engine is pure Swift with zero `import SwiftUI`"* — not an import. Not a violation.
2. **`Package.swift` enforces the three-layer split** structurally: `FootballSimCore` has no
   dependencies; `ProFootballCoachUI` depends on it; `CoachWorldApp` is documented as *"the only
   place allowed to see both the authoritative root and the screen read models."*
3. **The boundary is test-enforced.** `ContractTests.importsUIFramework` scans sources by
   construction. `Package.swift` records the finer rule: inside `CoachWorldApp`, *"a file that
   imports SwiftUI may not name `GameState`"* — file-by-file, enumerated by scan rather than by
   directory convention.
4. **27 provider files** in `CoachWorldApp` map engine state to read models, one per domain.
5. `ProFootballCoachUI` imports `FootballSimCore` in ~40 files, which is permitted — the forbidden
   direction is the reverse, and it is clean.

**One item to watch, not a violation.** `Sources/ProFootballCoachUI/ScreenReadModels.swift` is
**2302 lines**, the largest file in the module, and it sits on the boundary. It does not breach any
rule, but it violates `CLAUDE.md`'s "files small and focused, split by responsibility". Recorded as
**D-012**; splitting it per family is a mechanical, low-risk change.

---

## 5. Data-model-implied surfaces

`FootballSimCore` has 20 domain directories: `AI`, `Abstracted`, `Calibration`, `Career`, `College`,
`Competition`, `Engine`, `Generation`, `History`, `Integrity`, `Intent`, `Model`, `People`,
`Persistence`, `Pro`, `Rules`, `Scheduling`, `Support`, `Tactical`, `World`.

Directories with **no proportionate UI exposure**, seeding [`07`](07-GAP-REGISTER.md):

| Engine area | Exposed? | Implied surface |
|---|---|---|
| `AI` | No | Opponent/staff reasoning is invisible. A delegate whose reasoning is never shown cannot be trusted — the §3 axis the benchmarks answer by *printing the rate* |
| `History` | Thinly | `LegacyHistoryView` (175 lines) serves four registered routes. No retained time series → no trend lines (GAP-03) |
| `Integrity` | No | Determinism/save-integrity state has no player-facing readout |
| `Intent` | Partially | `CoachWorldIntentID` routes navigation, but there is no *delegation-policy* intent (GAP-05) |
| `Calibration` | No, correctly | Simulation-side only. Must stay unexposed |
| `Tactical` | Partially | `GamePlanView` 192 lines against a full tactical model — the thinnest exposure ratio in the codebase |
| `Competition` | Yes | Standings/schedule/bracket well covered |
| `People` | Partially | Staff exist as data; staff *relationships* and trust have no surface (GAP-09) |

**Uncurated observations.** No surface exposes: per-week statistical accumulation; league-relative
percentile for any rating; any stored time series; any financial projection; any delegation policy
object; any saved view or filter state; any ceremony trigger; approval or trust from any
constituency; injury *risk* as distinct from injury *state*; scouting confidence as a range.

Each becomes a numbered gap in [`07`](07-GAP-REGISTER.md).

---

## 6. What survives, in one line

The tokens, the register, the chrome, the component vocabulary and the engine boundary all survive.
The registry survives and is better than what the brief expected to find. What must change is
**density discipline on the four dense screens, decision framing on the ACTION surfaces, and the four ceremony surfaces that were
registered but never built** — plus the nine gaps in `07` that involve engine work — seven of them engine-only — without which
several REFACTORs cannot be completed at all.
