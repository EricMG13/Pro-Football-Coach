# Full-surface adversarial review — 2026-08-19

**Method:** static source review against `docs/04b-AUDIT-RUBRIC.md` (eight dimensions 0–5, ten
automatic-rejection conditions, P0–P3). **No Swift toolchain and no simulator exist in the
environment this review ran in**, so nothing here was built, run, rendered or screenshotted.
Rubric dimensions 6 (accessibility) and 8 (craft/resilience) are therefore assessed only to the
extent source can carry them, and every claim below is a claim about source.

**Why this review exists.** The prior pass, `docs/reviews/2026-08-18-floodlit-adversarial-review.md`,
sampled **4 surfaces of 62**. `04b` has never been run at all. This review covers all 62 screen
families, the §6.5 element registry and the shared hosts, so that the coverage boundary is the
enumeration rather than whoever remembered a screen.

---

## 1. Systemic findings

These outrank the per-surface findings: they are the reason a per-surface defect can ship green.

### S-0 [P1] No text in the application scales with Dynamic Type

**The largest finding in this review.** Found independently by three of the six delegated reviews
and verified directly here.

`04` §6.2 line 622 requires: *"Custom sizes are wrapped in `@ScaledMetric` so the default
composition remains dense while accessibility categories can expand and reflow it."* §6.4 repeats
it. The token layer does not do this:

```swift
// DesignTokens.swift:149-157
public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight).width(.condensed)
}
public static func figure(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight).monospacedDigit()
}
```

Fixed points, no `relativeTo:`. A repo-wide scan finds **exactly three** `@ScaledMetric` uses in the
entire UI — `RecruitingBoardView.swift:19`, `CoachingHQView.swift:28`, `RosterView.swift:19` — and
**all three are spacing gaps**, not font sizes. No font in the application is Dynamic-Type aware.

Every `isAccessibilitySize` branch in the codebase therefore reflows **layout around text that never
grows**. An AX5 user gets a taller, one-column screen with identically tiny type. Load-bearing
content sits at 9–10.5 pt: fixture opponents (`ScheduleView.swift:135-139`), standings records
(`StandingsView.swift:182-189`), offer terms and expiry (`CareerHubView.swift:395-400`), award
titles, stat categories, news datelines, and every `FloodlitLabel3` (`FloodlitPatterns.swift:35`,
9 pt, `.lineLimit(1)`, no `minimumScaleFactor`).

`04b` §8 requires "no literal authored type below 12 pt" and rubric 3.6 anchor 0 is *"a supported
user cannot complete the task"*. This is a P1 against every one of the 62 families at once, and it
is the single change with the widest blast radius in the review.

### S-6 [P1] Fifteen of 62 families are routing aliases, and all fifteen of their root branches are dead code

`ScreenRegistry.swift:113-131` aliases fifteen families:

| Alias → canonical | Families |
|---|---|
| → `.careerHub` | `jobBoard`, `offer`, `appointment`, `jobSecurity`, `coachingCarousel` |
| → `.collegeOffseason` | `portalHub`, `retentionDecisions`, `portalMarket`, `nilAllocation` |
| → `.proOffseason` | `proScoutingBoard`, `draftBoard`, `freeAgency` |
| → `.staffRoom` | `staffMarketProfile` |
| → `.gamePlan` | `schemeBook` |
| → `.depthChart` | `personnelPackages` |

The aliasing itself is deliberate and documented (`:112`, and the 2026-08-19 IA plan). The defect is
what it leaves behind. The production switch subject is the *canonical* screen
(`CoachWorldAppRootView.swift:90`):

```swift
switch Self.canonicalScreen(screen) {
```

`canonicalScreen` returns `screen.canonicalDestination` (`:1538-1540`), which never equals an alias.
So every alias `case` in that switch is provably unreachable: lines **495, 508, 521, 548, 559, 570,
581, 674, 683, 696, 755, 768, 781, 794, 848**. Fifteen dead branches, each constructing a view type
that consequently never renders. Add `DraftRoomView`, which is never constructed anywhere in
`Sources/` at all (S-5), and **16 of 62 view files never render in production**.

Meanwhile `docs/STATUS.md` reports "62 converted / 0 pending", `AccessibilityReflowTests` counts all
62 as landed, and `ContractTests` certifies the dead ones as "reachable from the shipped app root".
The app has **47** reachable destinations. Nothing in the verification record says so.

### S-7 [P1] Four contract assertions check a string where their message claims a property

The enumeration in these suites is genuinely by construction and is good work. The **assertions** are
not. Every one below is satisfied by code that does nothing:

| Test message claims | What it actually asserts | Where |
|---|---|---|
| "must be reachable from the shipped app root" | the substring `case .jobBoard` appears in a file | `ContractTests.swift:1415-1417` |
| "has no accessibility-size composition, so AX5 reflow was never decided" | the substring `dynamicTypeSize.isAccessibilitySize` appears | `AccessibilityReflowTests.swift:105-107` |
| "leaves VoiceOver order to layout accident" | the substring `accessibilitySortPriority` appears | `AccessibilityReflowTests.swift:112-116` |
| "authored text must remain at least 12 points" | a constant equals itself | `ContractTests.swift:955` |

The last is the clearest. `authoredFloor` is asserted `>= 12`, and a repo-wide search finds it
referenced **only at its own declaration** (`DesignTokens.swift:215`). No font call site passes
through it. The floor guards itself and nothing else — while S-0 puts real content at 9 pt.

Two demonstrations that the gates are satisfiable by inert code, both found independently:

```swift
// NewCareerCoachIdentityView.swift:28-34, and identically
// RankingsPlayoffPictureView.swift:28-34, BracketPostseasonView.swift:28-34
if dynamicTypeSize.isAccessibilitySize {
    content.accessibilitySortPriority(100)
} else {
    content.accessibilitySortPriority(100)
}
```

Character-for-character identical branches. The test reports that AX5 "was decided" for these
families. Nothing was decided.

And one that asserts the opposite of its own message (`ContractTests.swift:1004-1007`):

```swift
expect(chrome.contains("static let familySize: CGFloat = 9")
           && chrome.contains("static let railLabel: CGFloat = 9"), ...
       "the icon rail must not scale authored labels below the readable floor")
```

It string-matches to **lock in** 9 pt, and calls that protecting a readable floor.

### S-8 [P1] The Match Day contrast gate measures a colour the field never draws

The fifth and most complete instance of the same defect. `ContractTests.swift:2085`:

```swift
expect(contrastRatio(palette.fieldLine, palette.fieldTurf) >= 3,
       "\(name) field lines must meet 3:1")
```

`grep fieldTurf MatchDayField.swift` returns **nothing**. The shipped field never draws that token.
Its ground is a five-stop gradient from `Floodlit.turfCrown` to `Floodlit.turfNight` (`:76-80`), and
the yard numbers are drawn at `line.opacity(0.33)` (`:284`, `Paint.number = 0.33` at `:831`).

Composited against the stops the field actually paints, the yard numbers measure **1.92:1** at the
top row and **2.84:1** at the bottom, against a 3:1 floor for large text. The gate asserts an opaque
pair that is not on screen, passes green, and the pair that is on screen fails. Raising
`Paint.number` fixes the pixels; it does not fix the gate, which must enumerate **composited draw
pairs** by construction.

### S-9 [P2] `docs/STATUS.md` carries a factual claim this review refutes

STATUS.md:86 lists F-09 as one of three findings that "will not close without a decision or engine
work", on the grounds that *"no scouting-confidence model exists, and deriving one would print
invented figures as fact."*

A scouting-confidence model does exist. `Sources/FootballSimCore/College/ScoutingState.swift:19,21`:

```swift
public let confidence: Int
public let evidenceCount: Int
```

Both are clamped to `CollegeRules.knowledgeConfidenceRange` / `maximumScoutingEvidence` (`:34-37`),
populated per observation, and already surfaced — `CoachWorldRecruitingBoardProvider.swift:257`
renders `"Confidence \($0)%"`. The blocker STATUS.md records is not a blocker.

What is real is smaller and different: the figure is printed under a label reading **"Uncertainty"**
(`ProspectProfileView.swift:149`), so a coach reads the value backwards; `evidenceCount` — the
sample `04b` §4.8 asks for — is never surfaced; and `CoachWorldConfidenceTag`, registry #12, built
and documented for exactly this field (`FloodlitPatterns.swift:592`), is used on no recruiting
surface. That is a presentation defect, not an engine gap. STATUS.md should be corrected.

### S-1 [P1] The accessibility gates are substring-presence checks, and they never open the file that holds the content

`Tests/SimTests/Suites/AccessibilityReflowTests.swift` asserts AX5 and VoiceOver order like this:

```swift
expect(family.text.contains("dynamicTypeSize.isAccessibilitySize"), ...)
expect(family.text.contains("accessibilitySortPriority"), ...)
```

A family passes by *containing the string anywhere* — including inside a comment. Worse, the file
it scans is resolved by `landedFamilies()`, which maps each screen to its own wrapper file only:

```swift
let fileName = viewFileName(for: screen)
if let file = sources.first(where: { $0.path.hasSuffix("/" + fileName) }) {
```

`Sources/ProFootballCoachUI/LegacyHistoryView.swift` is not a screen-family file. It renders **all
of** Record Book, Rivalries, Career Line and Coaching Tree, and it contains **zero** occurrences of
either string. All four families pass both accessibility gates on the strength of ~28-line wrappers
whose only accessibility content is the two magic strings, while 100% of their rendered content sits
in a file the gate never opens — and which carries a fixed-width text clip (C-6).

This is the defect `CLAUDE.md` quotes from `AUDIT.md` as the project's signature failure: *"the
test's coverage boundary became the quality boundary."*

### S-2 [P2] The colour contract scans exactly one file while views define their own colours

`DesignContractTests.swift:146` narrows the "every colour the UI ships is a value canon states" test
to a single file:

```swift
let tokenFiles = swiftFiles(under: "Sources/ProFootballCoachUI")
    .filter { $0.path.hasSuffix("DesignTokens.swift") }
```

Colours defined outside that file are structurally invisible to it. At least five sites define raw
colour values in view code:

| File:line | Literal |
|---|---|
| `CoachWorldDeskComponents.swift:191` | `Color(red: 1, green: 0.95, blue: 0.78).opacity(0.22)` |
| `CoachingHQView.swift:595` | `Color(red: 0.08, green: 0.06, blue: 0.01)` |
| `MatchDayField.swift:846-847` | `Color(red: 247/255, green: 251/255, blue: 255/255)` and sibling |
| `MatchDayScoreBug.swift:251` | `Color(red: 216/255, green: 151/255, blue: 19/255)` — a gold |
| `MatchDayScoreBug.swift:212` | `Color(red: 14/255, green: 10/255, blue: 6/255)` |

Two further sites hardcode alphas where their siblings use a token: `CoachingHQView.swift:377`
(`Color.white.opacity(0.14)`) and `FloodlitChrome.swift:403` (`Color.white.opacity(0.10)`), against
`CoachWorldTokens.Glass.line` elsewhere.

The fix needs no new mechanism: the same test file already enumerates the whole directory at line
373 for the light-palette rule. The enumeration exists; the colour rule just does not use it.

### S-3 [P2] `04` §6.5's registry and the shipped vocabulary have diverged, and canon was not amended

§6.1c states the rule: *"Names map 1:1 onto Swift types, and each folds into §6.5's registry rather
than starting a parallel one."* A parallel one exists.

**Implemented** (13): `CoachWorldRouteButton`, `CoachWorldActionButtonStyle`,
`CoachWorldBlankPhotoPlate`, `IdentityBand`, `DeltaMark`, `ConfidenceTag`, `Meter`, `OpposedBar`,
`StatusChip`, `AgendaRow`, `ScoreBug`, `LowerThird`, and #23's failure set as
`CoachWorldSystemState` (`.empty/.loading/.error/.interrupted`).

**No implementation of that name** (9): `coachWorldDeskSurface`, `WorldStrip`, `DenseTable`,
`ColumnSet`, `ListControls`, `VerdictLine`, `FormLine`, `RoleToken`, `CallInCard`.

**Form divergence** (1): #10 `RatingBadge` — canon specifies a *fixed-size numeric badge*; the code
ships `CoachWorldRatingRing`, an arc. See A-1, which is the consequence.

Per `CLAUDE.md`'s doc-first amendment rule, this had to be settled in canon first. It was settled in
code.

### S-4 [P3] Two shipped patterns sit outside canon's eight

§6.1c: *"Every management surface is built from these and nothing else; a surface that needs a ninth
is a finding, not a licence."* The eight are Glass panel, Row/chip, Card, Label3, Arc family,
Pill/Flag, Staff voice, Committing action. `FloodlitPatterns.swift` also ships `FloodlitCostLine`
(:479) and `FloodlitFooterStrip` (:525). `CostLine` has a textual basis in the "Costs, not
recommendations" paragraph that follows the table; `FooterStrip` has none. By canon's own test these
are findings to be ruled on, not silently carried.

### S-5 [P2] Draft Room's accessibility is certified against a file production never renders

The sharpest instance of S-1, and three tests collaborate to hold it in place.

Production routes Draft Room through `ProOffseasonView`, not `DraftRoomView`
(`CoachWorldAppRootView.swift:477-483`):

```swift
case .proOffseason, .draftRoom:
    let focus = screen == .draftRoom ? .draftRoom : proFocus
    surface(store.proOffseason, screen: .proOffseason) { model in
        ProOffseasonView(model: model, title: focus.taskName.uppercased(), focus: focus, ...)
```

`DraftRoomView` is constructed **nowhere in `Sources/`**. Its only references are its own
declaration, `ContractTests.swift:1386` and `AccessibilityReflowTests.swift:150`. It is dead code in
production that exists to satisfy tests.

Yet `landedFamilies()` resolves `.draftRoom` to `DraftRoomView.swift`, finds both magic strings in
it, and passes the AX5 and VoiceOver gates — for a file no player ever sees. A dedicated test,
*"the convention keeps the draft room family landed"*, exists specifically to keep `.draftRoom` off
the pending list, and `ContractTests.swift:1384-1395` requires the file to exist and contain
`dynamicTypeSize.isAccessibilitySize`.

The rendered path may well be fine — `ProOffseasonView` carries five AX5 branches. The defect is
that **nothing verifies the rendered path as Draft Room**, and the instrument that claims to is
reading a different file. Of the four pro-market wrappers this convention covers, three
(`draftBoard`, `freeAgency`, `proScoutingBoard`) are at least constructed in the root, so their
gate-checked file is on the render path. `draftRoom` alone is not.

Verified by construction: of 62 families, 61 are constructed in `Sources/CoachWorldApp/`;
`draftRoom` is the sole exception.

---

## 2. The arc rule

### A-1 [P2] A 40–99 rating is rendered as a proportion arc in two places

§6.1c: *"An arc is permitted **only** where the datum is a proportion."* `CoachWorldRatingRing`
defaults to `floor: 40, ceiling: 99` (`CoachWorldVocabulary.swift:194-196`) and computes
`(value − floor) / (ceiling − floor)`.

Two call sites take those defaults on a rating:

- `RosterView.swift:510` — `value: selected.overall`
- `StaffRoomView.swift:109` — `value: row.reputation`

A rating is ordinal, not a proportion of a whole. The arc manufactures a quantity the simulation
does not hold: a 70-rated player renders ~51% filled, a number with no referent, and a 40-rated
player renders an **empty** ring — reading as absence when 40 is the floor of the scale.

This is not an unknown rule in this codebase. `CareerHubView.swift:183-198` applies it correctly and
says so: *"Support is a 0-100 ledger, so the ring is read against that whole rather than the 40-99
rating scale the Heat bands describe."* The distinction is documented in one place and unapplied in
two others.

---

## 3. Career family (9 surfaces)

Reviewed directly rather than delegated. The four routes Job Security, Stakeholders, Promotion
Decision and Coaching Carousel are **byte-identical wrapper files** modulo the `focus:` value
(verified by hashing each with the type name and focus normalised — all four hash alike). They all
delegate to `CareerHubView`.

### C-1 [P1] Four unrelated career routes share one composition — auto-rejection #1 and #9

`CareerHubView.swift:226-227` states it in a doc comment:

```swift
/// The third column changes with the route. Four registry entries share this composition, and
/// what distinguishes them is which evidence the panel holds -- not a different screen.
```

Only the third column (`focusPanel`, :228) varies. `identityColumn` and `standingColumn` render
identically on all four. And the variation itself is thin — the `switch focus` at :234 resolves to:

| Route | `focusTitle` (:255) | `focusPanel` body (:234) |
|---|---|---|
| Job Security | "What the board can see" | falls to `default:` → `historyRows` |
| Stakeholders | "Who is behind you" | a hardcoded prose string (:236-239) |
| Promotion Decision | "What is on the table" | `opportunityWorkspace` — shared with Job Board, Offer, Appointment |
| Coaching Carousel | *(no case)* → "What is on the record" | falls to `default:` → `historyRows` |

None of the four has a task-specific composition. Rubric dimension 2 cannot score above 1 here, and
automatic-rejection #1 ("the same composition used for an unrelated screen") and #9 ("a content
index occupies the space where the task should be") both fire.

### C-2 [P1] Job Security cannot perform its named task

Its panel is titled "What the board can see" and renders the coach's **past appointment history**.
No job-security datum — heat, board confidence, hot seat, expectation gap — appears anywhere on the
surface. Dimension 5 scores 0 ("required action is hidden, fake or contradictory"); dimension 7
fails because the title names one thing and the body renders another.

### C-3 [P1] Coaching Carousel renders the wrong subject entirely

A coaching carousel is *other coaches* moving between jobs. This surface has no case in the switch,
so it falls to `default:` and renders **the player's own appointment history** under the heading
"What is on the record". The named task is not performed and no data for it is present.

### C-4 [P2] Stakeholders adds nothing over Career Hub

Its focus panel is a hardcoded sentence (`CareerHubView.swift:236-239`): *"These are the current
support figures, and nothing beyond them. No interpretation is recorded."* The actual stakeholder
data lives in `standingColumn`, which renders identically on all four routes. The surface is Career
Hub with a static apology in the third column.

### C-5 [P2] `LegacyHistoryView`'s `default:` makes the header lie

`LegacyHistoryView.swift:68-74` switches on focus with `default: records`, while `topBar` (:56)
prints `focus.canonicalName`. Any focus without a case renders the Record Book body under that
focus's name. It is also the coverage-boundary shape again: a fifth history surface added tomorrow
silently renders records instead of failing.

### C-6 [P2] Fixed-width text with no reflow, in a file with no AX5 branch

`LegacyHistoryView.swift:130`:

```swift
Text("Season \(row.season)").monospacedDigit().frame(width: 105, alignment: .leading)
```

A fixed 105 pt on text, with no `minimumScaleFactor` and no `fixedSize`. At AX5 this truncates,
which is the datum loss `04` §7.1 forbids. The file contains no `isAccessibilitySize` branch at all
— and per S-1, no gate can see it. `105` is also a bare literal where `CLAUDE.md` requires a token.

### C-7 [P2] The back control is labelled "History" on all four surfaces

`LegacyHistoryView.swift:52` — `Button("History", action: onClose)`. It does not name where it
returns to, on any of the four. This is the label/commit-mismatch class the 2026-08-19 design audit
raised as its Principle #6 finding.

### C-8 [P3] Only the empty state is handled

`LegacyHistoryView` renders `CoachWorldSystemState(.empty(...))` and nothing else, though
`.loading`, `.error(_, recoveryTitle:, onRecover:)` and `.interrupted` all exist
(`CoachWorldVocabulary.swift:19-22`). Registry #23 requires the failure set inside the owning
composition.

### C-9 [P3] Destructive callbacks default to no-ops (latent, not shipped)

The four wrappers default `onResign`, `onAcceptOpportunity` and `onContinue` to empty closures
(e.g. `JobSecurityView.swift:25-27`). **Production wires them** —
`CoachWorldAppRootView.swift:796-858` passes real handlers — so this is not a live defect, and the
"fake action" reading is refuted for the shipped app. It stays recorded because a new call site that
omits them gets a silently dead Resign control with no compiler complaint.

---

## 4. Refuted hypotheses

Recorded so they are not re-raised, and so this review is not read as confirming everything it
suspected.

- **"A ~28-line view is a title-only stub."** False for the career-history four.
  `LegacyHistoryView` genuinely recomposes per focus (:67-75): `records`, `rivalries`, `careerLine`
  and `coachingTree` are four distinct compositions. The wrapper's line count says nothing.
- **"The defaulted no-op callbacks mean the Resign button is fake."** False in production; see C-9.
- **"§6.5 #23's failure set is unimplemented."** False — it ships as `CoachWorldSystemState`. An
  earlier grep of mine returned a false absent; corrected in S-3.

---

## 5. Coverage

| Axis | Total | Covered here |
|---|---:|---|
| Screen families | 62 | 62 |
| §6.5 registry elements | 23 | 23 |
| Shared hosts / orphans | 7 | 7 |

The 62-family assignment was checked by diffing the reviewer allocation against the
`CoachWorldScreenID` enumeration: 62 declared, 62 assigned, zero unassigned, zero duplicated, zero
phantom. Coverage is proven by construction, which is the standard this rubric demands of the code.

Delegation honoured `CLAUDE.md`'s cap of six concurrent subagents with no nested delegation. **No
delegated finding was accepted as returned**: every P0 and every load-bearing P1 was re-verified
against source here, and three claims were corrected or downgraded in the process (see §4 and §6.5).

---

## 6. Per-surface results

Scores are the eight `04b` dimensions summed to 40. Every reviewer capped dimensions 6 and 8 at what
source can prove and said so. **No surface in any family reached the 31/40 gate.**

### 6.1 The one P0

**Depth Chart and Personnel Packages — VoiceOver and AX5 users can reach one position group of
fifteen.** Verified directly here against all four of its claims.

`DepthChartView.swift:175` — inside `token(_:)` — is the only writer that selects a specific group:

```swift
openPositionID = group.id
```

`token(_:)` is rendered only inside `fieldDiagram`, which carries `.accessibilityHidden(true)`
(`:140`), and which is **not constructed at all** at accessibility type sizes (`:60-64`). The
fallback then pins the surface to the first group (`:104-106`):

```swift
visibleGroups.first { $0.id == openPositionID } ?? visibleGroups.first
```

The unit pills (`:90`) reset it to `nil`, yielding that unit's first group and nothing further. The
authoring comment states the reasoning error exactly:

```swift
// The diagram is a second reading of the list, never the only one, so at AX
// sizes the list stands alone rather than a 390pt field being scaled to nothing.
```

The diagram is *not* a second reading — it holds the sole selection affordance. Rubric D6 anchor 0
and P0's "unusable supported configuration". `PersonnelPackagesView` renders `DepthChartView` and
inherits it whole.

### 6.2 Scores

| Family | Surface | Total | Verdict | Auto-rejections |
|---|---|--:|---|---|
| Entry | Title / Continue | 16/40 | Reject | #4, #5 |
| Entry | New Career & Coach Identity | 21/40 | Reject | — |
| Entry | Job Board | 13/40 | Reject | #1, #4, #6, #8 |
| Entry | Offer | 12/40 | Reject | #1, #4, #6, #8 |
| Entry | Appointment | 12/40 | Reject | #1, #4, #6, #8 |
| Entry | Settings & Accessibility | 13/40 | Reject | #4, #5 |
| Personnel | Roster | 23/40 | Reject | — |
| Personnel | Depth Chart | 20/40 | **Reject (P0)** | — |
| Personnel | Player Profile | 26/40 | Revise | — |
| Personnel | Development Plan | 17/40 | Reject | — |
| Personnel | Staff Room | 23/40 | Reject | — |
| Personnel | Staff Market & Profile | 11/40 | Reject | #1 |
| Personnel | Scheme Book | 12/40 | Reject | #1 |
| Personnel | Personnel Packages | 10/40 | **Reject (P0)** | #1 |
| Pro mgmt | Cap & Contracts | 20/40 | Reject | — |
| Pro mgmt | Contract Negotiation | 18/40 | Reject | — |
| Pro mgmt | Roster Cuts & Transactions | 14/40 | Reject | #1, #4 |
| Pro mgmt | Pro Scouting Board | 14/40 | Reject | #1, #8 |
| Pro mgmt | Draft Board | 15/40 | Reject | #1, #8 |
| Pro mgmt | Draft Room | 11/40 | Reject | #1, #4, #7 |
| Pro mgmt | Free Agency | 14/40 | Reject | #1 |
| Pro mgmt | Pro Offseason | 18/40 | Reject | — |
| League | League Map | 21/40 | Reject | #4 |
| League | Team / Programme Profile | 24/40 | Reject | — |
| League | Standings | 24/40 | Reject | — |
| League | Schedule | 21/40 | Reject | — |
| League | Rankings & Playoff Picture | 16/40 | Reject | — |
| League | Bracket / Postseason | 17/40 | Reject | — |
| League | Game Detail / Box Score | 23/40 | Reject | — |
| League | Statistics & Leaders | 17/40 | Reject | — |
| League | Awards & Honours | 17/40 | Reject | — |
| League | News | 18/40 | Reject | — |
| League | Realignment Event | 12/40 | Reject | #4 |
| League | World Search | 21/40 | Reject | — |

| Weekly | Coaching HQ | 22/40 | Reject | #9 (dead branch only) |
| Weekly | Inbox | 23/40 | Reject | #4, #6 (owner gate) |
| Weekly | Opponent Report / Film Room | 28/40 | Revise | — |
| Weekly | Game Plan | 24/40 | Revise | — |
| Weekly | Practice Plan | 26/40 | Revise | — |
| Weekly | Team Health | 26/40 | Revise | — |
| Weekly | Match Day | 25/40 | Reject (P1) | #7 |
| Weekly | Aftermath | 30/40 | Revise | — |
| Recruiting | Recruiting Board | 22/40 | Reject | #7, #8 |
| Recruiting | Prospect Profile | 20/40 | Reject | #8 |
| Recruiting | Shortlist | 14/40 | Reject | #9 |
| Recruiting | Contact & Visit Planner | 18/40 | Reject | — |
| Recruiting | Class Overview | 20/40 | Reject | — |
| Recruiting | Signing Day | 14/40 | Reject | #1, #4 |
| Recruiting | Portal Hub | 12/40 | Reject | #1, #4 |
| Recruiting | Retention Decisions | 12/40 | Reject | #1, #4 |
| Recruiting | Portal Market | 12/40 | Reject | #1, #4 |
| Recruiting | NIL Allocation | 11/40 | Reject | #1, #4 |
| Recruiting | College Offseason | 21/40 | Reject | #1 |

Career family (9) is scored in section 3. **Highest score in the application: Aftermath, 30/40 —
one point below the gate. Nothing passes.**

### 6.3 The dominant pattern: named destinations that do not perform their named task

`04` §8 assigns each family a dominant object. Across four families, reviewers found the rendered
object is a different one, or absent:

- **Offer** — canon: "terms and accept/decline consequence". No terms exist in `OpportunityRow`, and
  **no decline action exists anywhere** — not in the view, the read model, or the callback surface.
- **Settings & Accessibility** — canon: "device, match and accessibility choices". Five `Text` blocks
  and a Close button. Zero choices.
- **Title / Continue** — canon: "current career and durable boundary". A wordmark and two buttons; no
  Continue control exists, and no career is shown.
- **Staff Market & Profile** — canon: "candidate comparison, contract and scheme relationship".
  Renders your **own employed staff**, headed "STAFF MARKET · 8 on staff".
- **Scheme Book** — canon: "offensive/defensive identity and adoption cost". Renders Game Plan's
  composition headed by *this week's opponent*, and its commit writes `setGamePlan` — so "setting a
  scheme" silently changes this week's tactical plan.
- **Rankings & Playoff Picture** — canon: "selection position, neighbours and path". `RankingRow`
  holds no seed, no cut line, no bid count. A ranked list wearing a playoff-picture name.
- **Free Agency** — canon: "live market waves, competing bidders and offers". `FreeAgentRow` holds
  name and position only; there is no bidding.

### 6.4 Other confirmed P0/P1s worth naming

- **Cap gauge contradicts itself.** `ProManagementView.swift:145-149` clamps with `min(1, …)` and
  derives the printed figure from the clamped value, so an over-cap team renders **"100%"** three
  lines below `Text(… "Over the cap")` (`:102`). Registry #14 requires a defined over-capacity state;
  neither `FloodlitArcGauge` nor `CoachWorldMeter` can express one.
- **Contract Negotiation submits superseded terms.** `NegotiationCard` seeds `@State` in `init`
  (`:227-229`) under a `ForEach` keyed on a stable id, with no `.id()` or `.onChange` re-seed. After
  a counter, the fields hold the old offer while the cost line shows the new one — and "Counter"
  transmits the stale values to the engine.
- **News contradicts itself on season.** The provider prints `season + 1`
  (`CoachWorldNewsProvider.swift:13,17`) while the engine headline embeds the raw season
  (`NewsFeedReadModel.swift:88`). Season 1's dateline sits beside "Season 0 ends: …".
- **Roster prints an impossible class balance.** `classBalance` (`RosterView.swift:788-794`) buckets
  into FR/SO/JR/SR, but pro players generate with `eligibility = nil`, so every pro roster shows
  `ROSTER 53/69` beside `FR 0 · SO 0 · JR 0 · SR 0`. It also silently drops `GR` on college rosters.
  The value is computed in the view and maps to no read-model field.
- **Three rating-colour scales disagree.** `RosterView.ratingColor` (85/70),
  `DesignTokens.Heat` (85/72) and `CoachWorldRatingRing` (85/72) use different thresholds and
  different colour triples. A 70-rated player is amber "steady" in the Roster table and red "weak" on
  the Player Profile one tap away — and both appear inside single panels.
- **A dead-control pattern across six league surfaces.** `guard let id = UUID(uuidString:) else
  { return }` silently no-ops; the bundled DEBUG fixture uses non-UUID stable ids
  (`"team-carson"`), so in the sample path these are enabled buttons that do nothing.

### 6.5 Refutations from the delegated reviews

- **"Row selection commits before the explicit control"** (DESIGN-IS row 32) — **refuted** for Game
  Plan and Depth Chart. Both cited sites set local state only, and `DepthChartView.swift:268`
  documents the contract: *"Tapping a row only selects it; the footer owns the commit."*
- **"`CompetitionOverviewView` is a relabelling host"** — **refuted**. It genuinely recomposes per
  focus (`:85-104`). Rankings and Bracket fail for a different and worse reason: the read model holds
  no playoff-picture or bracket-topology data at all.
- **"`04b` requires dark and light appearances"** — superseded. `04` §7 retires it; Floodlit is
  dark-only by canon, so hardcoding `CoachWorldTokens.dark` is compliant and is **not** a finding.
- **Legal sweep across recruiting and league surfaces — clean.** No real institution, venue,
  programme or person name; no hardcoded team colours (all resolve through `CoachWorldTeamIdentity`).
  One residual, flagged not asserted: two hand-authored DEBUG fixture colour pairs
  (`LeagueMapReadModels.swift:255-259, 285-288`) sit outside the generated-pair ΔE sweep by
  construction — the same shape of gap that produced the 2026-08-12 defect. An owner checklist item.

### 6.6 Weekly command and recruiting — additional confirmed P1s

- **Match Day ships a fake three-way picker.** `ControlDepthSelector`
  (`MatchDayScoreBug.swift:333-341`) renders three labelled cells carrying `.isSelected`, and every
  one calls the identical `onSelect` closure with no `candidate` argument. The wired intent is
  documented as a *cycle* (`ScreenReadModels.swift:1595`). It presents as a segmented picker and
  behaves as an unlabelled cycle button — and it governs the call-in budget the coach is asked to
  spend (`MatchDayView.swift:743`).
- **Match Day asserts halftime unconditionally.** `MatchDayView.swift:237` renders
  `"HALFTIME · PLAN EDIT"` with no read of `situation.quarter`, in the same frame as a scorebug
  printing `Q1 · 14:32`, and speaks the false one to VoiceOver.
- **Coaching HQ cannot advance the week at AX5.** Both `onContinue` call sites live in branches that
  never render in the accessible composition (`:464` in `supportColumn`, and `continueButton` inside
  a `chrome == nil` gate that production never satisfies). The same branch silently drops the
  obligations list, squad health and stakeholders — a different composition, not a reflow.
- **Recruiting: "Committed" does not say to whom.** `statusLabel`
  (`CoachWorldRecruitingBoardProvider.swift:213-221`) switches on `.phase` alone and ignores
  `programmeID`, so a prospect who commits to a *rival* still reads "Committed" on your board — and
  Class Overview's 60 pt hero figure counts them in your class. The same file uses
  `recruitment?.programmeID != programmeID` for withdraw availability (`:390`), so the provider knows
  the distinction and does not apply it to the label. Class Overview then derives that figure by
  string-matching a presentation label (`ClassOverviewView.swift:96`).
- **`Withdraw` is labelled "No cost" and is destructive.** `CollegeState.withdraw(_:)` removes the
  `ProgrammeProspectRelationship` outright — accumulated interest, `visitScheduled`,
  `scholarshipOffered` — and drops the NIL reservation. Re-adding creates a fresh relationship; the
  interest is gone. The control is a visual peer of Contact and Evaluate, has no destructive role,
  and commits with no confirmation, on a surface whose siblings confirm *every* choice.
- **Coaching HQ prints "0 of N cleared".** `CoachingHQView.swift:262` — the read model holds no
  completion state, so the numerator is a literal `0` and the denominator *shrinks* as work is done.
  A coach who has cleared three of five reads `0 of 2 cleared`. `:817` invents `"SATURDAY"` with no
  day-of-week field, on a surface that also serves the pro tier.
- **Team Health inverts fatigue.** `TeamHealthView.swift:202-206` passes `100 - fatigue` as the bar
  proportion *and* as the heat input, while printing `fatigue`. A player at 80% fatigue shows 80%
  beside a 20%-filled bar tinted red-for-20. The accessibility label says 80% — so the spoken and
  sighted readings disagree.

### 6.7 Refutations from the final two reviews

- **"Match Day uses SpriteKit or Metal"** — refuted. No such import anywhere in `Sources/`; the
  field is `Canvas` + `TimelineView` as `CLAUDE.md` requires.
- **"'Into the game plan' advances the week"** (DESIGN-IS row 41) — refuted.
  `CoachWorldAppRootView.swift:151` now reads `onContinue: { navigate(.gamePlan, in: store) }`.
- **"Game Plan and Practice Plan commit on row selection"** — refuted a second time, independently.
- **Reduce Motion coverage is largely sound.** `CoachWorldMotion.swift` makes an un-reduced
  animation structurally unrepresentable. The real gap is narrower: the phase label freezes at
  `Result` because it keys off `isAnimatingSnap`.
- **Prior finding F-09** — refuted on its facts. See S-9.

---

## 7. Verdict

**Reject, at the system level rather than surface by surface.**

Sixty-two families scored. **None reaches 31/40.** The highest is Aftermath at 30. Nine surfaces
score 14 or below. One P0 and more than twenty P1s are confirmed against source.

But the per-surface scores are not the finding. Three system-level defects produce most of them, and
fixing those is worth more than fixing any number of screens:

1. **No text scales with Dynamic Type** (S-0). One change in the token layer moves dimension 6 on
   all 62 surfaces at once. Every AX5 branch in the codebase is currently reflowing layout around
   frozen type.
2. **15 of 62 families are aliases whose code cannot run** (S-6, S-5). The product has 47 reachable
   destinations. Sixteen view files never render. Deciding whether those families are real tasks or
   should be deleted is a scope decision the owner has to make before any further surface work.
3. **The verification apparatus checks strings, not properties** (S-7, S-8, S-2). Five distinct
   instances, including a contrast gate that measures a colour the field never draws and a type-floor
   constant that only asserts itself. This is why the first two could ship green, and it is why the
   record says "62 converted / 0 pending".

The enumeration discipline in this codebase is genuinely good — `landedFamilies()`, the legal
sweeps and the conversion partition all enumerate by construction, and the legal tests in particular
are exemplary (the partition comment records getting the count wrong twice by hand before deriving
it). The failure is one layer in: having enumerated the right set, the assertions ask whether a
substring is present. `CLAUDE.md` names this exact failure and the codebase reproduced it five times.

**Recommended order:** S-0 first (widest blast radius, single locus), then S-7/S-8 (until the gates
assert properties, no fix can be shown to hold), then the S-6 scope decision, then per-surface P0/P1s.

**What this review is not.** Nothing here was built, run or rendered — there is no Swift toolchain
and no simulator in this environment. Dimensions 6 and 8 are assessed only as far as source carries
them, and every reviewer capped their scores accordingly and said where. The 844 × 390 geometry
claims are arithmetic over stated constants, not observations. No owner walkthrough has happened,
and `04b` §7's questions 1 and 4 remain owner gates that no static review can answer.
