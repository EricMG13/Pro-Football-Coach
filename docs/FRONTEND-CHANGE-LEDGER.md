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

### A4b · The type scale — RESOLVED 2026-08-23, register-aware

**CHANGE. Settled under the owner's 2026-08-23 grant; written into `04` §6.2.** The reconciliation plan sets a single global `DisplaySize` and halves the display end.

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

**Resolved: register-aware, not re-valued.** Desk and Dossier-below-the-seam take the reconciled
values; Broadcast and Dossier-above-the-seam take the large end, and §6.7's earned ceremony — five a
season — is what licenses it. Neither column was picked over the other, which is the point: the
grant settles the *model*, and under the model two-thirds of the numbers come from the reconciliation
plan. **A grant that made Press Box win every number would have been the wrong grant.**

### A4c · Team-aware primary actions — RESOLVED 2026-08-23, gold always

**CHANGE. Written into `04` §6.1a.** The plan makes the primary action take the controlled team's colour when
`CoachWorldTeamIdentity` resolves 4.5:1 text and 3:1 non-text, falling back to neutral/gold
otherwise. Press Box says the commit is **always gold**.

Contrast is not the only risk, and the resolver only guards that one. **The real hazard is semantic
collision:** a club whose primary is green gives every commit the colour of a positive state; one
whose primary is amber gives it the colour of a caution. Press Box already measured this class —
the placeholder club's secondary `#F2D864` is gold-adjacent, which is why *position* is marked in
ink rather than in the club accent.

Gold means one thing in this system: *this moves the game forward*. A team-coloured commit means a
different thing per save.

**Resolved: the commit is always gold, and team colour never carries an action.** Identity and
selection are what team colour owns, which is what it already does in the band. The contrast resolver
guards legibility and cannot see the collision, so passing its check is not evidence the colour is
safe.

### A4d · Team identity injected once at the stage — ADOPTED 2026-08-23

**ADD. Written into `04` §5.3. This is the case where the reconciliation plan beats Press Box.** The plan resolves `CoachWorldTeamIdentity` once
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

**Coverage as of 2026-08-23: 47 of 47 canonical destinations drawn. The registry is closed.** The live count is
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
| 6 | Settings & accessibility | `SettingsDemo` — mostly readouts; the OS owns text size, transparency, motion, contrast, and it needs **both** states because it is reachable before a career and during one |
| 54 | Stakeholders | `SeasonExpectationsDemo` — **partial**: draws the board's demands, not the wider cast |
| 1 | Title / Continue | `TitleContinueDemo` — **no band**: the one screen reached before a club, a record or a week exists |

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

### B1d · Pro management — complete, 5/5

| ID | Surface | Required change |
|---:|---|---|
| 34 | Cap & contracts | **REMOVE cap forecast, projected space, trade value, scouting grade, contract demand and probability** — six numbers a cap screen usually leads with. Unavailable actions **stay drawn and print their reason**. Zero gold. |
| 35 | Contract negotiation | **REMOVE the demanded figure, acceptance probability and agent sentiment.** `NegotiationRow` holds what *you* offered, how often, and when it closes — so the surface is a record of your own conduct, not a read on theirs. One gold; its sub-label states the figure. |
| 36 | Roster cuts | **Release states its exact dead money before it commits** — required by name. The commit's sub-label carries the cost, not the saving. No projected relief, no replacement suggestion, no ranking of who to cut. One gold. |
| 39 | Draft room | No pick clock — no timed state exists. |
| 62 | Pro front office | **`CapSummary` retains `remaining`, so it prints.** The rule is never *derive* a remainder, not never show one — NIL has no such field, which is why that screen prints committed-of-total instead. Hosts three aliases. Zero gold. |

### C6 · An unavailable action must print its reason

**ADD — to the component, not to each call site.** Every Pro `ActionRow` carries `isAvailable` and
`unavailableReason` as a pair, and the contract states the rule outright:

> "An unavailable action prints its `unavailableReason` rather than disappearing."

Inbox states the same shape as `canContinue` / `continueReason`. **This is system-wide.**

A control that vanishes teaches a coach the screen is inconsistent; one that greys out silently
teaches them it is broken. Saying why is the only version that teaches them the rules of the game.

`Commit` currently takes `disabled` with no reason, so the rule lives at each call site — which is
the same shape as `--press-dim` existing with no consumer. **Give the disabled state a required
reason** and the rule enforces itself.

**Budget note for whoever lays out a plate:** a two-line unavailable cell makes its row 52 rather
than 44. A plate with two of them holds four rows where it would hold five — measured, not
estimated: `2×44 + 2×52 + 28 + 22 + 56 = 298` against the 311 a 54 pt band leaves.

### B1e · Career — complete, 9/9

**Four of the nine share one read model.** Record book, Rivalries, Career line and Coaching tree are
all `LegacyHistoryReadModel` with a different `focus`, and all four carry the same omission: no
forecast, no acceptance odds, no job recommendation, and **no unrecorded history**.

| ID | Surface | Required change |
|---:|---|---|
| 52 | Career hub | **REMOVE acceptance odds and any job recommendation.** Zero gold — gilding accept would recommend it. **Resign takes semantic red, not neutral**: equal in weight is not equal in kind. Accepting **routes to the promotion fork** rather than committing here. Hosts five aliases. |
| 54 | Stakeholders | Partial — Season Expectations draws the board's demands, not the wider cast. |
| 57 | Record book | **REMOVE derived records.** "Best start since 2019" is a record nobody recorded. The holder column is the surface. Zero gold. |
| 58 | Rivalries | **REMOVE inferred rivalries.** Four close meetings do not make one; the model records which fixtures are. The record is printed **from your side and says so**. Zero gold. |
| 59 | Career line | **Timeline** — the first surface where position carries meaning. Evenly spaced, because the model records seasons not months. **No projection forward**: the line stops at the season in progress. Zero gold. |
| 60 | Coaching tree | **Spatial** — direction is the content. **No transitive closure**: a tree is where "no unrecorded history" has the most edges to invent. The coach who left stays on it, or it is an org chart. Zero gold. |

### C7 · Destructive actions are a third case, not an un-gilded one

**CHANGE.** The gold rule (C5) says several equal actions means zero gold. Career hub adds the case
it did not cover: **accept** and **resign** are both irreversible, so neither is gilded — but resign
is *destructive*, and destructive actions take the semantic red rather than an equal option's neutral
treatment.

**Equal in weight is not equal in kind.** Three treatments, not two: gold for the single commit,
neutral for equal options, semantic red for destruction.

### B1f · League and Entry — complete, 11/11 and 1/1

**One omission list governs all eleven League surfaces**, and it is the strictest in the contract:
*"derived geography, cross-tier scope, probability, media, unsupported event state."*

| ID | Surface | Required change |
|---:|---|---|
| 43 | Standings | **REMOVE all probability.** The last column is the **fixture list** — what is left to play, not what is likely. Your row is anchored and marked in ink. No cross-tier scope. Zero gold. |
| 45 | Rankings & playoff picture | **The screen named after a probability may not show one.** State position against the field — "two ranked wins short" is arithmetic on results played. Zero gold. |
| 48 | Statistics & leaders | **REMOVE filter and sort.** Categories are retained, in the model's order. Zero gold. |
| 44 | Schedule | Timeline. **An unplayed week is empty, not dashed** — a dash is a value, absence is the fact. **Draw the bye**, or week 9 looks adjacent to week 7. No shaded likely-win. |
| 50 | News | **REMOVE all media** — no outlet, byline, press quote or columnist. Each row is one sentence of fact. **A wire, not a newspaper.** Zero gold. |
| 41 | League map | **Structural, not geographic.** "Derived geography" is forbidden: the model holds membership and a city name, not coordinates. A pin invites reading travel and rivalry into it; neither is recorded. Zero gold. |
| 46 | Bracket | **Draw the empty side of a tie.** The shape is retained where the result is not; filling a slot with a likely winner is the forbidden probability. **No seeding maths.** Zero gold. |
| 42 | Team profile | A Dossier **about somebody else** — floods with *their* colour. Only recorded facts: no derived tradition, no programme ranking. One gold on the seam. |
| 7 | World search | **The kind comes first** — one string matches a programme, a person and a venue. No recent searches, no "did you mean", no relevance ranking. Zero gold. |
| 51 | Realignment | **One moment, not a lifecycle** — "unsupported event state". The model records the change, not the negotiation. The date is stated, never counted down. Zero gold. |
| 2 | New career | **No band** — no club, no record, no week, and not yet a coach. **Show the seed**: a deterministic product that hides it is keeping a promise nobody can check. No difficulty rating, no recommended job. One gold; `isWorking` drawn with **no progress bar**, because the wait cannot be measured. |

### C8 · League forced no new component — the prediction that failed

**No change required.** For most of this ledger's life, League's standings table was the standing
example of why a new component would be needed: twelve teams, nine numeric columns, a prose column.

Measured, it is six columns in 737 pt with **211 left for the team name**. `WorkPlate` was built for
a roster, and a roster is the harder case.

What League *did* force was two redefinitions, both recorded above: the map became structural, and
the playoff picture lost its odds. **Neither is a component; both are the contract deciding what a
surface is.**

The two genuinely new shapes came from Career — a timeline and a tree — and there are now four
across the system (career line, schedule, news; tree, map, bracket). They still are not extracted:
the timelines disagree on direction (a season runs left-to-right because it ends; a feed runs down
from now because it does not), which is exactly the joint a premature component would have fixed
wrongly.

---
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

**Read the document before raising an ask against it.** Three entries here have now been withdrawn
or closed as partly wrong — D1 asked the engine for a confidence band the product had deliberately
decided against, D2 asked for a transition value that had existed since 2026-08-18, and D6 said canon
predated a register model that canon already contained. Each was written from what the reference
package implied rather than from the source, which is the same failure as trusting the older sheets
over the newer contract. **An ask costs the owner attention; a wrong one costs their trust in the
rest of the list.**

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

**Canon carried the wrong form too, and has been corrected (2026-08-23).** `04` §6.4 held the range
rule verbatim, waiting on a scouting-confidence model — merged from part D of
`docs/ux/10-CANON-AMENDMENT-04.md` on 2026-08-22, the same day the contract that contradicts it was
written. It now records that the dependency was decided against rather than deferred. `Unseen`
survives; the numeric band does not. **Five of that amendment's six parts were right and one was
wrong, and the wrong one is the only one that carried an engine dependency** — a proposal that ends
"until the engine lands" is the one nobody re-reads once it is merged.

**So the ask is withdrawn and a change replaces it — see B2-C1.** `ConfidenceRange` as drawn is
unbacked, and the premise it was built on — *an unearned rating is a range whose width is the
confidence* — is a model this product does not have and does not want.

What survives: **`Unseen` is still correct** where the model holds no value at all, and `Versus`
still must decline to mark a lead against it. What goes is the numeric band.

### D2 · ~~Screen transitions are unspecified~~ — CLOSED 2026-08-23, and this one was half wrong too

**Closed in `04` §6.7. The ask claimed "nothing names a move between two surfaces". Something does.**
`Motion.world`, 0.42 s, has been in the table since 2026-08-18, described as *"a world-scale
transition — screen to screen, register to register"*. That is the family switch, already specified.

**What was actually missing is narrower and more useful: the *sibling* move had no value, and
`world` is the wrong one for it.** 0.42 s for changing a tab feels sluggish, and more than that it
claims a journey the player did not take — a sibling is not somewhere else, it is the same desk with
different paper.

Both moves are now named, and **neither adds a duration**, because §6.7 caps the motion vocabulary
the way §6.6 caps symbols:

| Move | Duration | What moves |
|---|---|---|
| Family switch | `world` 0.42 | the world may change with it; family label and sibling strip are replaced. The band never re-enters. |
| Sibling within a family | `value` 0.22 | the plate cross-fades **in place**; the selected-sibling indicator travels. Nothing else. |

**The indicator is the one thing licensed to travel**, because its position *is* the information —
§2's Acquisition Room exception ("a rank may travel, because the movement is the fact being
reported") generalised to any mark whose location carries the meaning.

Reduce Motion needs no special case: both collapse to cuts under the rule §6.7 already states.

**Two of the three asks I raised against canon turned out to be partly wrong the moment I read the
document** — this and D6. Both were written from what the reference package implied about canon
rather than from canon. The pattern is now recorded once, at the top of Part D, rather than three
times.

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

### D6 · ~~Canon has not been amended~~ — CLOSED 2026-08-23, and the ask was half wrong

**Closed. Two of its three claims did not survive checking, which is worth more than the ask was.**

**What was wrong.** This said `04` "predates the register model". It does not. `04` §2.1 *is* the
register model — Broadcast / Desk / Dossier, the told-versus-working axis, and the note that a
frequency-first rule misclassifies Match Day — merged in commit `2f6d2fd4` and dated 2026-08-22, the
day before this ledger opened. §6.1a carries the measured palette and the gold-once rule, §6.1d the
identity band, §6.4 the five-band heat scale, §4.5 the density budget. The reasoning sits in
`docs/ux/10-CANON-AMENDMENT-04.md`, whose parts A–F all landed.

**I wrote this ask without opening either file.** The design system had been reading the presentation
contract and the reference sheets, so it inferred canon's state from what the sheets implied rather
than from canon. That is the same failure the "sheets are older than the contract" correction caught,
one level up: *infer nothing about a document you have not read.*

**What was right, and is now done.** The 2026-08-23 work is genuinely newer than `04`, and it has
been written in rather than left in a design tool the repository cannot open:

| `04` | What landed |
|---|---|
| §4.4 | An unavailable control stays drawn beside its reason. Removing it or greying it in silence is a listed failure. |
| §4.5 | **Never *derive* a remainder** — the same class as the change-mark-without-a-delta rule this section already held. Where the read model retains one it prints. |
| §5.3 | Team identity resolved once at the stage; nil is the honest teamless case, reachable by construction rather than by discipline. |
| §6.1a | The gold budget in three cases, including **zero for several equal actions**, and destructive actions taking `state.negative`. Team colour never carries an action. |
| §6.2 | The display end of the type scale is register-aware. The working end does not move. |
| §6.1c | **The icon rail is removed**; every management surface takes the leading 63 that Title, Job Board and Offer already used, and the content column derives to **761**. The header's top comes off the safe-area inset, not the frame. |
| §7 | Increase Contrast raises hairlines and drops material and **moves no ink** — every ink is already measured, and a setting that repairs a palette is a report that the palette was wrong. |

`04b` moved with it: its enforcement list asserted *"both appearances meet contrast"* a week after
§6.1a retired the light register on 2026-08-16, so it was a check that could not fail. It now names the one
appearance that ships, plus the contrast branch, the gold count and the unavailable-reason pairing —
all countable in source, which is why they belong in that list rather than in prose.

**One stale banner fixed with it.** `docs/ux/10-CANON-AMENDMENT-04.md` still read *"DRAFT, not canon
until merged into `04` itself"* long after it was merged. That is precisely the failure
`DOC-MANIFEST.md` exists to prevent: a cold builder reads a merged decision as an open proposal and
re-litigates it. It now says what it is — the reasoning, not the rule.

**What is NOT claimed.** None of this has been compiled, and none of it is implemented in Swift.
`04` now describes the system; `DesignTokens.swift`, `FloodlitChrome.swift` and the stage do not yet
match it, and Parts A to C of this ledger are that gap. Amending canon before implementation is the
order `CLAUDE.md` requires, not evidence that the implementation exists.

---

## One found defect this ledger does not own

`04` §9 ("Match Day") has no numbered subsections, but line 1291 cites **§9.4** for the anchor-set
position template — a pointer introduced by `1f236d4e` that leads nowhere. **Not fixed here, because
fixing it means guessing what it was meant to name**, and a confident wrong pointer is worse than an
obviously broken one. Whoever wrote the anchor contract knows; a ten-second answer from them beats an
inference from me.

Found by scanning every `§n.n` in `04` against its own headings — one pass, and the only dangling
reference in 1,290 lines, which is a good result for a document this old and this amended.

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
