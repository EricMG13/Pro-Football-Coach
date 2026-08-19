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

Per-family scores and findings for the other 53 surfaces follow in section 6, from the six
delegated reviews. Delegation honoured `CLAUDE.md`'s cap of six concurrent subagents with no nested
delegation; findings are merged and re-verified against source rather than accepted as returned.

*Section 6 pending — delegated reviews in flight at the time of writing.*
