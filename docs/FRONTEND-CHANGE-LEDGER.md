# Frontend change ledger — Press Box

**A living record, not canon.** `docs/DOC-MANIFEST.md` governs what is canon; nothing here amends a
canon document. Opened 2026-08-23.

**Standard:** Press Box, Claude Design project `3e8bedda-4c56-4be1-8f3a-98f9c2e82d9d`, owner-approved
2026-08-23 as the design standard. Its own `AUTHORITY.md` states what that overrides and — more
importantly — what it does not.

**Purpose:** every change the SwiftUI frontend needs to meet that standard, with enough detail to
act on without re-deriving it. One row per change. Nothing here is speculative: each entry names a
file or symbol that exists, or states plainly that the thing does not exist yet.

---

## Status legend

| | Meaning |
|---|---|
| **CHANGE** | The thing exists and is wrong. Adapt it. |
| **ADD** | The thing does not exist and must be built. |
| **REMOVE** | The thing exists and should not. |
| **ASK** | Blocked on the engine or on an owner decision. Do not invent around it. |

---

## The one rule that governs the whole rebuild

**The standard decides how a thing is drawn. It does not license drawing a thing that does not
exist.**

`docs/reviews/2026-08-22-all-screen-presentation-contract.md` states what each screen's read model
holds, what its callbacks are, and what it must omit. That contract is untouched by the standard and
binds in full. Where this ledger asks for a composition the read model cannot feed, it is filed as
**ASK** rather than drawn — see Part D.

This matters because the reference package would have led the other way. All 21 `*.dc.html` sheets
carry one mtime (2026-08-21 14:19); the contract is a day newer and forbids, by name, seven things
those sheets draw. Details in `docs/briefs/2026-08-23-surface-coverage.md` §1a.

---

## Part A — the shared layer

**Do this part first.** Six of these files are read by every surface, so each fix here removes the
same defect from dozens of views at once. Nothing in Part B should start before A1–A4 land.

### A1 · `DesignTokens.swift` — `Stage`: the rail is gone

**CHANGE.** `Stage` still describes the 44 pt icon rail that direction 3a removed, and derives the
content column from it.

| Symbol | Now | Required |
|---|---|---|
| `Stage.railLeading` `railWidth` `railTop` `railGap` | 59 / 44 / 46 / 2 | **REMOVE** — there is no rail |
| `Stage.contentLeading` | `115` | `63` |
| `Stage.contentWidth` | `844 - 115 - 20` = **709** | `844 - 63 - 20` = **761** |
| `Stage.contentTop` | `46` | `54` |
| `Stage.headerTop` | `3` | `12` — the top inset |
| `Stage.headerHeight` | *(two rows: 22 + 16)* | `34` — one row |
| `Stage.railFreeLeading` | `63` | **REMOVE** — every surface is now rail-free |
| `Stage.headerPrimaryRow` `headerSecondaryRow` | 22 / 16 | **REMOVE** — the header is one row |

Derive rather than restate, exactly as the reconciliation plan does:

```swift
contentLeading = Frame.leadingInset                 // 63
headerTop      = Frame.topInset                     // 12
headerHeight   = 34
contentTop     = headerTop + headerHeight + 8       // 54
contentWidth   = Frame.floorWidth - contentLeading - Frame.gutter   // 761
```

`63 + 761 + 20 = 844` exactly. **Four of those five matched Press Box and one did not** — Press Box
had `--header-top: 3`, which put the band *above* the safe top inset its own file declares at 12.
The 17 pt gap that left below the band looked deliberate enough that nothing flagged it. Press Box
is corrected; the reconciliation's derivation was right and this is the one place it corrected the
standard rather than the other way round.

**Add the retired-symbol scan**, which is the part that keeps this fixed: a source test asserting no
production file contains `FloodlitIconRail`, `RailEntry` or `showsIconRail`. Deleting a symbol is
not the same as preventing its return.

This is the highest-leverage change in the document: it is +4.6% content area on all 47 canonical
destinations, and it is a precondition for every plate width in Part B.

### A2 · `DesignTokens.swift` — `Heat`: three bands must become five

**CHANGE.** `Heat` implements *"red below 70, amber from 70–84 and green from 85 upward"* — three
bands, with amber as the ordinary starter's colour.

Required: **five bands around a neutral centre**, warm band *below* the median.

| Band | Range | Role |
|---|---|---|
| well below | 40–59 | `stateNegative` |
| below | 60–69 | `stateWarning` |
| **average** | **70–79** | **`contentSecondary` — neutral ink, not a colour** |
| above | 80–84 | `#7FCB9E` — **ADD**, no existing role holds it |
| well above | 85–99 | `statePositive` |

Two defects in the three-band version, and the second is the serious one:

1. An ordinary starter at 74 reads as a caution.
2. In the retired scale the middle band was gold — spending the commit colour on every average
   rating in every dense table. `Heat.color(for:palette:)` no longer returns gold, but the shape that
   allowed it is still there.

`04` §6.4 was amended to the five-band scale on 2026-08-22. This code is behind its own canon.

### A3 · `DesignTokens.swift` — `stateWarning` is a refused value

**CHANGE.** `stateWarning: 0xFFB03A`.

Measured **6.1° from gold** at the same saturation. At 11 pt under a thumb a caution and a commit are
the same colour. Required: **`0xC9704A`** — 24.1° from gold, 5.57:1 on page.

`04` §6.1a retired `#FFB03A` on 2026-08-22, and `codex/integrate-mock-reconciliation` carries the
canon amendment. This file did not follow.

Note the same file already refuses `#65788F` for `contentQuiet` and says so in a comment — the
identical reasoning, applied to one value and not the other.

### A4 · `DesignTokens.swift` — the translucent-surfacing scales are missing

**ADD.** Press Box carries four named scales that no Swift token holds. Without them every view
writes its own opacity, which is how the design system got 75 hard-coded colours in its own
components before this was fixed there.

| Scale | Steps | What it is |
|---|---|---|
| `wash` | 1 / 7 / 10 / 13 / 20 % of `contentPrimary` | a surface lifted off its ground |
| `recess` | 34 / 70 % of `page` | a surface pushed behind |
| `plate` | 96 % of `glassFlat` / `glassFlatDeep` | an opaque-enough working plate |
| `select` | 30 / 72 / 82 % of `raised` | selection and focus on a working surface |

Also missing, and each currently has no home:

- `ruleStructural` / `ruleLegible` / `ruleStrong` / `ruleGlass` / `ruleRow` — the hairline family
- `unseenInk` + `unseenOpacity` — an unobserved rating's treatment
- `inkOnGoldQuiet` — the sub-label under a commit's verb
- `bannerInfo/Good/Bad` × `from`/`to`/`edge` — **nine values, and they are load-bearing**: they are
  three grounds the four-ground palette does not cover, and `contentQuiet` measures 3.21 and 4.25 on
  two of them. Only `contentPrimary` and `contentSecondary` are legal on a banner.
- `maskTrailing` — the fade on a strip with more content than room

### A4b · The type scale — a conflict that needs an owner call

**ASK.** The reconciliation plan sets a single global `DisplaySize` and halves the display end.

| | hero | name | score | situation | screen | title | lead | row |
|---|---|---|---|---|---|---|---|---|
| **Reconciled** | 32 | 26 | 32 | 26 | 16 | 16 | 15 | 13 |
| **Press Box** | 66 | 60 | 54 | 52 | 25 | 20 | 17 | 15 |

The small end agrees exactly — `panel` 16, `action` 14, `actionSmall` 12, `pill` 10.5, `flag` 9 are
identical in both. The disagreement is entirely in display type.

**Neither is simply wrong, and that is the finding.** A flat `DisplaySize` enum **cannot express a
per-register budget**. 32 is right for a Desk surface and would be absurd on a ceremony; 66 is right
for a ceremony and would be absurd on a roster. The reconciled scale is a single value serving 47
management screens, and it flattens Broadcast into Desk — which is the "product that is neither"
the register model exists to prevent.

It also collides with the reconciliation's own Match Day amendment, which says the reference wins
there and reproduces its typography as drawn — while `score: 32` says otherwise.

**Recommended:** make the scale register-aware rather than re-valued. Desk and Dossier take the
reconciled values; Broadcast keeps the large end, and the ceremony budget (five a season) is what
licenses it. **Do not resolve this by picking one number.**

### A4c · Team-aware primary actions — a second conflict

**ASK.** The plan makes the primary action take the controlled team's colour when
`CoachWorldTeamIdentity` resolves 4.5:1 text and 3:1 non-text, falling back to neutral/gold
otherwise. Press Box says the commit is **always gold**.

Contrast is not the only risk, and the resolver only guards that one. **The real hazard is semantic
collision:** a club whose primary is green gives every commit the colour of a positive state; one
whose primary is amber gives it the colour of a caution. Press Box already measured this class —
the placeholder club's secondary `#F2D864` is gold-adjacent, which is why *position* is marked in
ink rather than in the club accent.

Gold means one thing in this system: *this moves the game forward*. A team-coloured commit means a
different thing per save.

**Recommended:** keep gold for the commit; let team colour own identity and selection, which is
what it already does in the band. Owner call.

### A4d · Team identity injected once at the stage — adopt this

**ADD, and it is better than what Press Box has.** The plan resolves `CoachWorldTeamIdentity` once
at `CoachWorldFloodlitStage`, only when `chrome?.club` exists, and injects it through the
environment — so **teamless entry screens retain nil automatically** rather than each surface
remembering to opt out.

Press Box has `--club-*` tokens and no equivalent story for a surface with no club. Adopt the
pattern: one resolution point, contrast-checked, with nil as the honest teamless case.

### A5 · Accessibility — `prefers-contrast` has no branch

**ADD.** Reduce Motion, Reduce Transparency and forced colours are handled. **Increase Contrast is
not**, while `SettingsAccessibilityView` reports it to the user — a promise about behaviour with
nothing behind it.

Required, per `tokens/a11y.css`: every hairline steps up one stop, the material drops, and **the inks
do not move** — they already clear 4.5:1 on all four grounds, and lightening passing ink flattens the
three-step hierarchy that distinguishes a figure from a label.

`codex/integrate-mock-reconciliation` carries a commit recording Increase Contrast as unimplemented,
so this is known and unfixed rather than unnoticed.

### A6 · `FloodlitChrome.swift` — the band is three controls short

**CHANGE + ADD.** The band is the whole of navigation now that the rail is gone, and three of its
controls do not exist.

| Control | State | Required |
|---|---|---|
| **Family switcher** | **ADD** | The family name is a button opening the five families a seat holds, each with its task count. Two taps to any of 41 tasks, no index screen. The pro seat swaps Recruiting for Pro management, and **the family you do not hold is not drawn at all — not greyed**. |
| **Back control** | **ADD** | Three exclusive states: `plain` (a wedge), `up` (the host's name — *"this surface folds into that task"*), `none` (the wedge at a sixth ink, disabled). The dead state is **drawn, not omitted**, or the leading edge moves 25 pt between screens. Which state a surface takes is a routing fact — do not default it. |
| **Alias host panel** | **ADD** | A host tab carries a caret and a count and opens the registry numbers folding into it. **Without it, 15 of the 62 identities are reachable by saved route and by nothing on screen.** Six hosts: 52 Opportunities (3, 4, 5, 53, 56), 61 College offseason (30–33), 62 Pro front office (37, 38, 40), 20 Staff profiles (21), 11 Game plan (22), 17 Depth chart (23). |

**And the band needs a yielding rule.** When it runs out of room: the sibling strip shrinks and fades
to a floor that always keeps the current screen and the sign that more exists; only then does the
deadline swap to a **shorter form**; the strip then recovers what that freed; nothing is ever cut
mid-glyph. This requires a `contextShort` alongside `context` on the chrome read model — **ASK D4**.

The reference register specifies the opposite priority and collapses the deadline to `W…`, then
abandons that itself: *"a date cut to one letter is not a better answer than a shorter date."* The
standard overrides it (`AUTHORITY.md`).

### A6b · Chrome contracts that are testable — keep them

**CHANGE.** The plan fixes three strings that a UI test asserts, and they are worth preserving
exactly because they make the chrome checkable rather than merely drawn:

- accessibility identifier **`top-navigator`** on the band
- the family button's label **`"Open all tasks, <family>"`**
- the absence of any element labelled **`Sections`** — the rail check, asserted by absence

Also from the plan and absent from Press Box: **`accessibilitySortPriority`** — the header at 100,
the content at 80, so the band is read before the surface. Press Box specifies reading order
nowhere.

**One difference to settle:** the plan's family button opens the **registry overlay** (all tasks);
Press Box's opens a **family switcher** (five families, each with its task count, two taps to any
task). Press Box's is the standard, and the accessibility label should follow it rather than the
reverse — a button labelled "Open all tasks" that opens five families is a lie to a screen reader.

### A7 · Gold is counted, per register

**CHANGE.** Gold means one thing: *this moves the game forward*. Per-surface budget:

| Register | Gold |
|---|---|
| Broadcast | once — the commit |
| Desk | at most once, often zero |
| Dossier | once — **the seam spends it**, so no commit bar |
| Match Day | twice — line to gain, and the snap |
| **Fork** | **zero** |

Position is marked in **ink** — never gold, and never the club accent either, because a generated
secondary can itself be gold-adjacent (the placeholder's is `#F2D864`). Audit every view for gold on
a family chip, a sorted column, a selected row or a possession marker; all four are position, not
commitment.

### A8 · What is already correct — do not change it

Verified against the standard and matching:

- `Frame` — 844×390, leadingInset 63, bottomInset 25, topInset 12, gutter 20
- `Gap` — the full 2/3/4/6/7/8/9/11/12/14/18/20 ladder
- `Motion` — all five durations, `pressDim`, `disabledOpacity`; **press dims rather than scales**, already stated in the comment
- `contentQuiet` `#7A8A9E`, with `#65788F` refused in a comment for the right reason
- `fieldAnnotation` `#FFCE6A` — legal on turf only, and that is where it is
- The `DisplaySize` ladder and the `Glass` alphas

---

## Part B — per surface

**Coverage as of 2026-08-23: 27 of 47 canonical destinations drawn.** Three families complete. The live count is
`guidelines/coverage.card.html`, which fails on a stale mapping rather than printing it as coverage.

### B1 · This Week — complete, 9/9, and every one re-sourced

Drawn in `guidelines/this-week.card.html`. **These seven were re-sourced from the presentation
contract after the reference sheets proved wrong on facts** — the sheet version of each would have
shipped controls no read model supports.

| ID | Surface | Required change |
|---:|---|---|
| 8 | Coaching HQ | Match `ThisWeekDemo`. One 34 pt band, one opaque plate, one side column. One gold on the commit, naming where it goes. |
| 9 | Inbox | **REMOVE the reply action and the undo** — the contract forbids both. Actions are open, read, continue. A deadline is a **date, not a countdown**. One gold on continue, disabled *with its reason stated* (`canContinue`/`continueReason` are one pair). |
| 10 | Film room | **REMOVE the tendency table.** The model holds two rates, a confidence, a sample and an `unavailableReason`. Make the confidence the subject. **ADD the unavailable state as a drawn composition** — it is the common case, and an undrawn empty state becomes "No data". |
| 11 | Game plan | **REMOVE the emphasis budget and the sliders.** It is a **fork**: choose between complete options, so **zero gold** and no LOCK bar. Each option carries its three dimensions and its **consequence** — the contract omits cost, so consequence is what replaces it. Three panels is the ceiling (246 pt each at 761). |
| 12 | Practice plan | Same archetype as 11, drawn the same way. **REMOVE the remaining-minutes field and the day sliders.** Each option is already a complete allocation. |
| 13 | Team health | **REMOVE diagnosis, return date, treatment and re-injury percentage.** Retained: condition, fatigue, availability, detail. **Routine available rows stay neutral** — colouring them green makes availability look like a score. Four rows plus a foot is the ceiling. |
| 15 | Aftermath | **REMOVE every delta** (`#19 → #12`, `78 → 81 +3`). No trend, no prior-grade delta — the model holds the result and the grades, not last week's. **Broadcast register at Desk scale**: 40 pt hero, no flood, because this happens 12–15 times a season against a ceremony budget of five. |
| 47 | Box score | **REMOVE the opponent column.** No opposed team totals, no quarter scoring, no play-by-play. Answer its own question instead — what was called, where it came from, what it did, and the grades with their evidence. **Zero gold**; the only action is close, and it takes the `up` back state. |
| 14 | Match Day | The one surface where the reference wins over the general shell, by owner amendment. Gold spent **twice** and no more — line to gain, and the snap. Possession is `stateLive`, not gold. |

### B2 · Drawn elsewhere — 10 more

| ID | Surface | Press Box demo |
|---:|---|---|
| 16 | Roster | `PersonnelDemo` — 8 columns × 6 rows = 48 cells, the working budget exactly |
| 24 | Recruiting board | `RecruitingDemo` — every row names your position in the race |
| 25 | Prospect profile | `DossierDemo` — the seam spends the gold, so no commit bar |
| 29 | Signing day | `BroadcastDemo` |
| 39 | Draft room | `DraftRoomDemo` — **no pick clock**: no timed state exists, so it would be a countdown to nothing |
| 49 | Awards | `AwardsDemo` — `JerseyLockup` is the portrait substitute; no likeness exists |
| 55 | Promotion decision | `CareerDemo` — **zero gold**, the one register exception, symmetry is the argument |
| 6 | Settings & accessibility | `AppearanceDemo` — mostly readouts; the OS owns text size, transparency, motion, contrast |
| 54 | Stakeholders | `SeasonExpectationsDemo` — **partial**: draws the board's demands, not the wider cast |
| 1 | Title / Continue | `ContinuityDemo` — **partial**: draws the save list, not the entry ceremony |

### B0 · Three surfaces carry no band at all

**CHANGE.** The proof matrix asserts the top-navigator on every canonical ID **except 1, 2 and 6**:

```swift
if ![1, 2, 6].contains(id) {
    XCTAssertTrue(app.otherElements["top-navigator"].exists, "screen \(id)")
}
```

Title / Continue (1), New career & coach identity (2) and Settings & accessibility (6) are
pre-career or teamless: there is no club, no record, no family and no opponent to put in a band.

**DONE, and one of the two needed a subtler answer than "remove the band".**

- **1 Title / Continue** — band removed. It is a root: no club, no record, no week, and no `back`,
  because there is nowhere up from it. The identity moved into a title block.
- **6 Settings** — **needs both states.** The proof matrix *skips* the assertion here rather than
  asserting the band absent, and the not-produced register names Title, Job board, Offer, Coach
  identity and Appointment as bandless — **not** Settings. It is reachable from Title, where there is
  no club, and from a career, where there is. Both are drawn.

Settings is therefore the surface that proves the pattern in **A4d**: it should not choose. The
stage resolves team identity once and leaves nil where there is no club, and the surface renders
whichever it is handed.

Both now live in `demo/Entry.jsx`; the superseded copies were removed from `demo/Admin.jsx` rather
than left as a second drawing of the same surface.

The proof matrix also confirms the canonical count independently: it lists exactly 47 IDs.

### B2-C · Corrections to surfaces already drawn

**Found 2026-08-23 by reading the contract rows for the Personnel and Recruiting families.** Two
drawn surfaces carried figures no read model supplies. A drawn surface with fabricated data is worse
than an undrawn one, because it looks finished.

| Surface | Was drawn | Correction |
|---|---|---|
| **16 Roster** | a **CEILING** column, drawn as a narrowing confidence range (68–89 → 87–90) | **DONE.** `PlayerRow` holds *overall, **development and its delta**, scheme fit, condition, availability* — no ceiling, no potential. The column is now development and its delta: not where he might get to, but how far he has moved and which way. |
| **16 Roster** | a sort caret on the NOW column | **DONE.** The contract omits *"no sort key the model does not already order by"*. Rows arrive in the model's order; a caret claims a control that does not exist. |
| **25 Prospect profile** | four attributes as narrowing confidence ranges | **DONE.** A prospect has **no attribute numbers** in this model. What is retained is an `Evaluation` — verdict, scheme fit, **stated uncertainty in words**, cited outliers — plus board rank, interest, status and relationship history. |
| **29 Signing day** | *"Best class at Union in nine years · ranked 22nd"* | **DONE.** **Drama copy and a national ranking, both omitted by name** — and a club that is not the one in the save. Now the retained counts: scholarships against the limit, NIL committed against budget, contact points left. |
| **29 Signing day** | no off-phase state | **DONE.** *"Outside the signing phase it says signing day is closed rather than rendering an empty board."* An empty ceremony is the worst of both — the scale of an occasion with none of the content — and it is what a surface gets by default when nobody draws the off state. |

### C1-C · `ConfidenceRange` — retired from use

**DONE, and do not port it.** The component draws a numeric band whose width is a confidence the
product does not compute. All four consumers are corrected — Roster, Prospect profile, Compare and
the chrome demo's background roster — and it now has none.

The file is kept only so the reasoning survives with it. **Do not build a Swift equivalent.**

`Unseen` is unaffected and stays: a value the model does not hold is still drawn as not held. One
claim made alongside it *was* wrong, though, and is corrected — "you cannot lead against Unseen" is
a sound rule whose example was not. Both subjects of a roster comparison have every field, so
nothing there is unobserved; `Unseen` belongs where a value is genuinely absent, which is a
prospect's evaluation and not a rostered player's row.

### B1b · Personnel — complete, 5/5

| ID | Surface | Required change |
|---:|---|---|
| 16 | Roster | **REMOVE the ceiling column and the sort caret** — see B2-C. Development and its delta replace the projection. |
| 17 | Depth chart | **REMOVE any ranking of occupants.** The model records *occupancy*, not order — named roles, one player each, no second string. **No invented vacancy**: a hurt player still occupies his role; what changes is availability. Spatial, not a table. Plan options are a **fork** — zero gold. **Hosts alias 23**, so its tab carries the host caret. |
| 18 | Player profile | **REMOVE projection, comparison and any derived grade** — all omitted by name. A Dossier: one gold on the seam, no commit bar. The development link is a route, drawn in ink. |
| 19 | Development plan | **REMOVE the editable allocation and the projected trajectory.** There is no action here at all beyond closing — and the surface must **say so in words**, or a player will assume the control is hidden rather than absent. Zero gold. |
| 20 | Staff profiles | **REMOVE any delegation chip, ranking, hire or fire.** The only surface of the 62 with no reference drawing, so composition is new; every column is a `StaffRow` field. Age was dropped to keep ROLE readable — measured, not guessed. Zero gold. |

### B1c · Recruiting — complete, 7/7

| ID | Surface | Required change |
|---:|---|---|
| 24 | Recruiting board | Every row names your position in the race, and none says what to do. |
| 25 | Prospect profile | **REMOVE the attribute table** — a prospect has no attribute numbers. See B2-C. |
| 26 | Shortlist | **REMOVE re-ranking, derived priority and any countdown.** `boardRank` prints; the order is the model's and there is no handle to change it. Zero gold. |
| 27 | Contact & visit planner | **REMOVE any recommendation of which contact to spend**, and therefore **all gold** — see C5. Cost and consequence are the choice's own words; the screen never totals hours or scores one contact against another. Capacity prints as retained. |
| 28 | Class overview | **REMOVE the class grade, the national ranking and any projected finish.** What is left is the need table. Open needs carry the ink; solved ones stay neutral, or it reads as a scorecard. Zero gold. |
| 29 | Signing day | **REMOVE drama copy and the ranking** — see B2-C. Add the closed-phase state. |
| 61 | College offseason | The first committing workbench: `onCommit`, so **one gold**. **NIL prints as committed-of-budget, never as a remainder.** Hosts four aliases (30–33), so the tab carries the caret. Carries the product's **only delegation field** — see D7. |

### C5 · The gold rule generalises

**CHANGE — and it removes a judgement call rather than adding one.** A fork spends zero gold because
gilding one of two irreversible options would be the interface choosing. The contact planner offers
*four* allowable actions under the same prohibition — *"no recommendation of which contact to
spend"* — and spends zero for the same reason, reached from a different direction.

**When a surface offers several equal actions, its gold budget is zero by construction.** Not a
decision to be re-made per screen: a consequence of the product's oldest content rule.

The corollary matters for the rebuild: **a surface with exactly one committing action is the only
kind that may gild it.** Check the count before reaching for `actionPrimary`.

### B3 · Not yet drawn — 20 canonical

Undrawn here means no Press Box composition exists yet, **not** that the Swift view is missing —
all 62 have a view on `main`. These are queued in the order below.

| Family | Remaining | Note |
|---|---|---|
| **recruiting** 3/7 | 8c Shortlist · 8d Contact & visit planner · 8e Class overview · 8j College offseason | |
| **pro** 1/5 | 9a Cap & contracts · 9b Contract negotiation · 9c Roster cuts · 9h Pro front office | Money surfaces; integer dollars only, no floating-point currency |
| **career** 4/9 | 11k Opportunities · 11d Record book · 11e Rivalries · 11c Career line · 11f Coaching tree | |
| **entry** 0/1 | 11i New career & coach identity | **Riskiest omission for its size** — the first thing a player ever sees, never drawn against the register model |
| **league** 1/11 | 10i Map · 10h Team profile · 10a Standings · 10b Schedule · 10c Rankings · 10d Bracket · 10e Statistics · 10f News · 10j Realignment · 10k World search | Last, deliberately — see C3 |

---

## Part C — components that must be built

Press Box components with no Swift equivalent. Each was forced by a surface, not invented ahead of
one.

### C1 · `Versus` — the opposed comparison

**ADD.** Two subjects, attribute against attribute, label between the values so the eye reads the
gap. The leading side takes a **wedge, never colour alone** — a comparison is exactly where someone
reaches for red-and-green first.

**It is not a fork and must never be collapsed into one.** A fork draws its sides identically because
weighting one would be the interface recommending; a comparison exists *to* show which side leads.
Same geometry, opposite obligation.

**And it must decline to mark a lead where either side is unobserved.** A comparison against an
unobserved value is not a narrow win — it is not a comparison. Depends on **ASK D1**.

Compare is a core verb of the genre and **no registry screen performs it** — see D5.

### C2 · `FamilySwitcher`, `BackControl`, `HostPanel`

**ADD.** Specified in A6.

### C3 · League table shapes — expect two or three more

**ASK / ADD.** Ten of League's eleven are shapes nothing in the system has drawn: a map, a bracket, a
standings grid, a statistics leaderboard. `WorkPlate` is built for a roster — eight spans, six rows —
and a twelve-team standings table with nine numeric columns plus a prose "what is left" column does
not fit it.

Do not force them into the plate. Draw the family first, let the shapes declare themselves, then
build against ten known cases rather than one guessed one. This is how `Versus` arrived, and how
`ForkPanel`'s ledger got generalised.

### C4 · `ForkPanel`'s ledger must be per-fork

**CHANGE.** The ledger's rows were hard-coded to CLOCK and EXPOSURE — the two axes a *career* fork
weighs. A tactical fork weighs tempo, pressure and front; a practice fork weighs the days. It takes
its rows as data now.

---

## Part D — asks: blocked on the engine or on a decision

**Nothing in this section may be worked around by inventing data.**

### D1 · ~~No scouting-confidence model exists~~ — WITHDRAWN, and the design was wrong

**Withdrawn 2026-08-23, same day.** This asked the engine to supply a numeric confidence band —
`low`/`high` whose width is the confidence — so `ConfidenceRange` could draw it.

**The product has deliberately chosen the opposite and already built it.** The contract for both
Recruiting Board and Prospect Profile says so twice:

> "Uncertainty is the model's stated `uncertainty` text, never a derived confidence."
>
> "No projection, no comparison to another prospect, no derived grade, no probability of commitment
> … **What is unknown is said to be unknown.**"

`Evaluation` carries a **verdict**, a **scheme fit**, a **stated uncertainty in words**, and **cited
outliers**. That is a better answer than a numeric band, not a poorer one: a bar implies a precision
the scouting does not have, and "we have seen him twice, both in the rain" is a truer statement of
doubt than `68–89`.

**So the ask is withdrawn and a change replaces it — see B2-C1.** `ConfidenceRange` as drawn is
unbacked, and the premise it was built on — *an unearned rating is a range whose width is the
confidence* — is a model this product does not have and does not want.

What survives: **`Unseen` is still correct** where the model holds no value at all, and `Versus`
still must decline to mark a lead against it. What goes is the numeric band.

### D2 · Screen transitions are unspecified

**ASK.** One easing curve and named durations exist in `CoachWorldMotion.swift`, but **nothing names
a move between two surfaces** — the reference package's own register says so, and says the mock cuts
instantly.

With family-then-sibling navigation there are only **two moves** to specify: sibling within a family,
and family switch. Small, and unstarted. Reduce Motion must reduce both to a cut.

### D3 · Commits do not propagate

**ASK.** Per the reference register: 36 committing controls run commit → loading → success → undo
inside their own screen and nothing propagates. Money spent on 9b does not move 9a's cap line;
holding a player out on 6f does not change 7a's depth chart.

This is a simulation gap, not a design one, but it decides whether a commit's `sub` — the line naming
where it goes — is true. **A commit that names a consequence which does not happen is worse than one
that names nothing.**

### D4 · The chrome read model needs `contextShort`

**ASK.** The band's yielding rule (A6) requires a shorter form of the deadline, authored rather than
truncated. `FloodlitChromeReadModel` supplies one context string. Adding a second is a small model
change and the alternative is cutting a date mid-glyph.

### D5 · Five drawn surfaces have no registry entry

**ASK — owner decision.** Each was found by drawing rather than by reading, and adding any to
`ScreenRegistry.swift` forces a family assignment at compile time, which is the registry working as
designed.

| Surface | Why it exists |
|---|---|
| **Compare** | Two players, attribute against attribute. A core verb of the genre that no registry screen performs. |
| **Responsibilities** | Where delegation is *configured*, as against exercised. **Stronger than a missing registry entry — see D7: there is no delegation state at all.** |
| **While You Were Away** | Automation halts on a threshold and hands control back; nothing renders the gap. Invisible delegation is indistinguishable from a bug. **Also blocked by D7.** |
| **Season Review** | A *season* has no ending. Aftermath is per-match. In a game whose arc is college to pro, that is the arc's missing last page. |
| **Championship Result** | The fifth sanctioned ceremony. Bracket / postseason is a table, not a verdict. |

### D7 · There is no delegation state anywhere

**ASK — and it is larger than it looks.** The contract for Staff Room (20) states it flatly:

> "**No delegation chip — nothing records what is delegated to whom** — no hire, fire or negotiation
> action absent from the callbacks, no derived staff ranking, and no invented staff copy."

`StaffRoomReadModel`'s `StaffRow` carries name, role, age, reputation, development, recruiting, game
planning, scheme affinity, and seasons with the programme. **There is no ownership field.**

**One qualification, and it is the useful one.** `CollegeOffseasonReadModel` carries a **delegated
decision count** — so the *concept* is not foreign to the engine; it is modelled as a tally on one
surface, with no record of which area went to which person. That is a smaller build than starting
from nothing: what is missing is the ownership mapping, not the idea.

This is not "Responsibilities lacks a registry entry". It is that the thing Responsibilities would
configure **does not exist in the simulation**. Two drawn surfaces depend on it and neither can ship
until it does:

- **Responsibilities** — eleven ownership areas, each resolving to a named person, each printing
  what it yields and the threshold that ends a cruise. Every field is invented today.
- **While You Were Away** — renders what an assistant did while you were away. With no record of who
  owns what, there is nothing to render.

It also decides whether a whole product direction is real. The design system has been arguing that
*"invisible delegation is indistinguishable from a bug"* — that argument only pays off if delegation
is a thing the simulation models. **Owner decision:** build the delegation model, or drop both
surfaces and the argument with them. Do not draw around it.

### D6 · Canon has not been amended

**ASK — owner decision.** The standard does not automatically amend the repository's canon, and two
documents now describe a different system:

- **`docs/04-UX-AND-DESIGN-SYSTEM.md`** — predates the register model, the measured palette, the gold
  budget and the token-enforced accessibility contract.
- **`docs/04b-AUDIT-RUBRIC.md`** — scores against `04`, so it moves when `04` moves.

`CLAUDE.md`'s doc-first rule says canon is amended before implementation. Naming these is the
escalation; neither has been edited.

---

## Keeping this current

One row per change, and a change is done when the Swift matches the standard **and** a check proves
it — not when it looks right. Press Box's own verification is worth copying:

- **Six rules scanned across every component source**, in `guidelines/checks.card.html`. Not a
  checklist: a scan that fails the build of the claim. It is how `--press-dim` was found with no
  consumer anywhere, and how 75 hard-coded colours were found while the colour rule read PASS.
- **A geometry sweep over every surface at once.** Fixing the instance in front of you is not fixing
  the class — the sibling strip was clipping on four of five screens and only a full sweep showed it.
- **The check must be ancestor-aware on both axes.** An element clipped by its own container is not
  overflowing the frame; one cut off *inside* a plate leaves the frame measuring perfectly while the
  content is gone. Both directions caught real defects, and both took a corrected check to see.
