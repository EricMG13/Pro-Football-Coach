# Exhaustive adversarial design critique — completed Floodlit surfaces

**Date:** 2026-08-18
**Branch:** `agent/floodlit-injury-evidence` @ `d2404f4`
**Rubric:** `docs/04b-AUDIT-RUBRIC.md` — eight dimensions, 0–5 each, pass at 31/40 with zero P0/P1
and no automatic design-specificity rejection.
**Authority for the design:** `docs/04-UX-AND-DESIGN-SYSTEM.md` §6.1a (palette, material, geometry),
§6.1b (broadcast register), §6.1c (management chrome and the eight patterns), §6.2–6.4 (type, shape,
density), §7 (frames and accessibility).
**Reviewer stance:** adversarial. Findings are stated as defects, not as differences. Where I was
wrong I say so.

---

## Method, and what it does and does not prove

- `xcodebuild -project App/ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Debug`
  **succeeded**. That is the only machine gate this review ran. **The test suites were not run**;
  nothing here should be read as a verification pass, and this review is not a build report.
- The app was installed and driven on an **iPhone 17e simulator, 844 × 390 pt — the install floor**
  of `04` §7, which is the frame the composition is authored against and the frame where overflow
  shows. The device reports portrait, so every capture is rotated upright; that is a capture
  artefact, not a render artefact.
- **A real career was played**, not the debug proof harness: coach created, programme
  *Marrow Hollow Normal* (#122 of 134), week 1, three obligations cleared, game and practice plans
  committed, week advanced into Match Day. Every screenshot is a real read model.
- 21 surfaces were reviewed on device. Captures are in
  `docs/proofs/2026-08-18-exhaustive-critique/`.
- Dark appearance only — `04` §6.1a retires light, correctly.
- Default type and AX5 were both exercised. Reduce Motion, Reduce Transparency, VoiceOver order,
  sensor-left/right and the 956 × 440 ceiling were **not** exercised; those cells of `04b` §6 remain
  unevidenced and are not claimed either way.

Three adversarial lenses were used, adapted from `adversarial-reviewer` to a design review: the
**Saboteur** (what does real generated content do to this composition?), the **New Hire** (can a
coach who has never seen this read it?), and the **Auditor** (does every visible fact map to a read
model, and does every control do what it says?). Findings caught by two lenses are promoted.

---

## Verdict

**Reject.** Every reviewed surface fails the `04b` gate, and four of the failures are systemic
rather than per-surface.

The chrome is real and good. The identity header, the icon rail, the world backdrops, the cut-corner
geometry and the eight patterns exist, are used, and look like the reference. The problem is not the
register. It is that **the register was fitted over an application whose navigation, copy and data
were never re-authored to match it**, and that the surfaces were signed off against sample data that
is shorter, fuller and better behaved than what the generator actually produces.

Three sentences that summarise the whole review:

1. **32 of the 62 registered surfaces have no route in a live career**, because the Floodlit
   conversion hid the navigation that reached them and did not replace it (G-01).
2. **The week cannot be advanced and the game never says why** (G-05).
3. **Real generated names break the compositions that sample names fit** — the personnel table, the
   depth chart and the Match Day field all clip or truncate the thing they exist to show
   (G-25, G-26, G-27).

---

## Systemic findings

### G-01 · P0 · Thirty-two of sixty-two surfaces are unreachable

`CoachWorldSurfaceFamily` has seven families. In a live career the navigation reaches three:
**weekly command** (rail: Week, Inbox, Plan, Film, Health), **personnel** (rail: Squad) and
**league** (rail: All 62 → World Search, then the sibling row). **Recruiting (11 surfaces),
pro management (8) and career (13) have no entry point at all.**

The only producers of a route into those families are the `route(_:screen:)` row and the
`Menu("World")` block inside each surface's `worldStrip` — and every one of those is guarded:

```swift
// CoachingHQView.swift:83, RosterView.swift:58, LeagueMapView.swift:65/623,
// RecruitingBoardView.swift:67
if chrome == nil { worldStrip }
```

`chrome(for:in:)` returns nil only when `store.coachingHQ` is nil, which does not happen in an
active career. So the strip — and with it the only link to the Recruiting Board, Career Hub, Job
Board, Portal, Class Overview, Contact & Visit Planner, Cap & Contracts, Draft Room, Record Book,
Rivalries, Coaching Tree and the rest — is never drawn.

This was the right fix for the defect it was aimed at (two navigations stacked on one screen, F-13
and the world-strip sweep in `PORT-LOG.md`). It removed the second navigation without giving the
first one the destinations. **The Recruiting Board is one of the three surfaces `04b` §7 requires to
pass together before production UI begins**, and it cannot be opened.

### G-02 · P1 · Settings & accessibility cannot be reached from inside a career

`onSettings` is wired on `TitleContinueView` only, and `screen == .settingsAccessibility` is handled
only in the pre-career branch of `CoachWorldAppRootView` (lines 69, 1235). There is no route back to
the title screen from a running career. Every accessibility control the app owns is therefore
unreachable the moment the player starts playing.

### G-05 · P0 · `ADVANCE` refuses in silence, and the hub asserts the opposite

Reproduced three times. With `0 OPEN` and `0 still open`, tapping the gold `ADVANCE` produced no
navigation, no status message and no state change. After committing a game plan and a practice
plan, the identical tap advanced the week into Match Day. The refusal is
`missingWeeklyPreparation`, and it is invisible because:

- `CoachWorldStore.run` writes the refusal to `statusMessage` (line 545), and the Floodlit hub's
  decision column **never reads `statusMessage`** — the only two reads are in `noDecision` and
  `selectionReceipt`, neither of which the Floodlit layout draws;
- the Floodlit empty state prints `"No decision is open. The week advances when its obligations are
  cleared."` (`CoachingHQView.swift:337`) — which is false in exactly the state that produces it;
- the pre-Floodlit layout's honest state (`"Weekly preparation required"`, `"Set a game plan and
  practice plan before the controlled fixture."`) **and its `Delegate balanced preparation` escape
  hatch** still exist in the file, and are reachable only when `chrome == nil`.

A new player with no obligations open, looking at a screen that says the week advances when
obligations are cleared, tapping the one gold button in the thumb arc, gets nothing and is told
nothing. `04b` §3.5 anchor 0: *required action is hidden, fake, irreversible without warning or
contradictory.*

### G-35 / G-36 · P1 · The type floor is breached, and the check that should catch it checks a constant

`FloodlitChrome.swift` sets the icon-rail label at **7.5 pt** with `minimumScaleFactor(0.7)` — an
effective **5.25 pt** — and the header's family label at **8.5 pt**. `04` §6.2's authored floor is
12 pt; §6.1b permits 10.5 pt and 9 pt **only** for tracked uppercase micro-labels. 7.5 and 8.5 are
below even the exemption. The code knows: `CoachWorldFloodlitComposition.swift:48` reads *"a 44 pt
rail of 7.5 pt labels cannot grow and stay a rail."*

`04b` §8 requires the SwiftUI phase to add a machine check that *no literal authored type is below
12 pt*. The only test in the suite is:

```swift
expect(CoachWorldTokens.TypeRole.authoredFloor >= 12, ...)   // ContractTests.swift:953
```

That asserts a constant is ≥ 12. It scans no call site and would pass with every surface set in
6 pt. This is precisely the failure `CLAUDE.md` names: *the test's coverage boundary became the
quality boundary.* A check enumerating by construction — every `display(_:)` / `figure(_:)` call
site in the module — would have caught the rail on the day it was written.

---

## Per-surface findings

### Entry — Title, New career

| # | Sev | Defect |
|---|---|---|
| G-23 | P2 | **Neither entry surface is in the Floodlit register.** Symmetric rounded rectangles, `.roundedBorder` text fields, no `CutCorner` geometry, no Label3, no world detail. `TitleContinueView` and `NewCareerSetupView` carry the chrome hook but draw DESK-era interiors. |
| G-24 | P2 | The selected starting job carries **a coloured fill and nothing else**. `04` §6.3: *selected items receive boundary, value and spoken state; never a coloured fill alone.* |
| G-44 | P2 | The world seed renders as a bare `20260812` in an unlabelled field once typed — placeholder-as-label, on the one control that determines the entire generated world. |
| G-45 | P2 | The three "generated openings" are near-duplicates: two share `Prestige 41 · Resources 40 · Target performance 51` and the descriptor `Commuter school`. The first choice in the game offers no choice. |
| G-46 | P2 | `Prestige 40 · Resources 55 · Target performance 50` — three abstract scalars with no unit, no scale and no football meaning. |
| G-47 | P3 | At AX5 the panel exceeds the frame; it scrolls, but the job rows overflow their panel horizontally (`Marrow Hollow` clipped at the right edge). |

### Weekly command — Coaching HQ

| # | Sev | Defect |
|---|---|---|
| G-05 | P0 | See above. |
| G-06 | P2 | `0 of N cleared` uses a **shrinking denominator**. Observed 0 of 3 → 0 of 2 → 0 of 0 across three clearances. The progress line is structurally incapable of showing progress. |
| G-09 | P2 | The decision's entire evidence is `Playing time: 0` — a raw counter, not evidence a coach can act on. |
| G-21 | P2 | `WHY IT IS HERE` is a Label3 with **nothing after it**. `CoachingHQView.swift:327` draws the label; no reason string is ever rendered. |
| G-48 | P2 | **No option carries a cost.** Both choices read `THIS WEEK` and nothing else. `04` §6.1c: *every option on a decision surface carries a cost in clock time, an attributed staff voice, and an exposure, then a consequence with a real arrow.* `FloodlitCostLine` is built and correct; the real read model never fills it. |
| G-49 | P2 | Agenda rows truncate at ~11 characters (`REDSHIRT: DARYN W…`) in a 350 pt row with an empty column beside it. |
| G-50 | P2 | The week's agenda is three redshirt toggles. Game plan, practice and recruiting — the reference's own agenda rows — never appear, because the agenda is fed engine *decisions* rather than the week's work. |
| G-51 | P3 | `WEEK 1 · WEEK 1` in the left eyebrow; `WEEK 1 · CALDER MINING` printed twice (header chip and decision eyebrow). |
| G-52 | P3 | Four stakeholder rows all read 60 with four identical bars. Furniture until something moves. |

### Weekly command — Inbox

| # | Sev | Defect |
|---|---|---|
| G-09 | P2 | `What is on the desk: Playing time 0 · Eligibility 1`. `PORT-LOG.md` records the earlier form (`Evidence: playingTime: 2 · eligibility: 1`) as fixed. It was reworded, not fixed — it is still a list of raw counters. |
| G-20 | P2 | The reading pane is one sentence over ~70 % dead space, and repeats the list row's subject and `DUE` chip verbatim. |
| G-53 | P2 | `File it` — the only way to dispose of a message — is unstyled 15 pt text with no border, fill or target treatment, beside a glowing gold `CONTINUE`. |
| G-54 | P3 | The fourth row is clipped by the frame; `5 UNANSWERED` is stated but the fifth is unreachable without a scroll affordance. |

### Weekly command — Film room

| # | Sev | Defect |
|---|---|---|
| G-10 | P2 | *"No current **observer-scoped** film has been retained for this opponent."* Engine vocabulary in player copy. |
| G-12 | P2 | `STALE` is printed top-right on a surface that says no film exists. Film that does not exist cannot be stale. |
| G-55 | P3 | `CALDER MINING · WHAT 0 GAMES OF FILM HOLD` — the eyebrow is ungrammatical at zero. |
| G-56 | P3 | The empty state's mark is `list.number`, which says nothing about film; the same mark is reused for Statistics and for the hub's empty decision. |

### Weekly command — Game plan

| # | Sev | Defect |
|---|---|---|
| G-22 | P2 | `TEMPO / AGGRESSION / BALANCE` are three cards each printing the word **BALANCED** at display size. The largest, densest elements on the surface carry the least information, and the arc family — which exists for exactly this — is unused. |
| G-48 | P2 | The Label3 reads `WHAT A DIFFERENT INSTALL COSTS` and **not one option shows a cost**. The heading advertises precisely what is missing. |
| G-32 | P2 | The committing action **overlaps** the second option row; the third option is pushed off the frame. |
| G-57 | P3 | Before an option is touched, nothing indicates which plan is current, so the coach cannot see the state they are about to change. |

### Weekly command — Practice plan

| # | Sev | Defect |
|---|---|---|
| G-32 | P2 | `SET THE WEEK` overlaps the `BALANCED WEEK` option row. |
| G-48 | P2 | `WHAT A DIFFERENT WEEK COSTS`, and the one visible option carries no cost. |
| G-58 | P2 | The four allocation rows look like controls and are not; the only thing that changes the week is the option list below, which is clipped. |
| G-59 | P3 | `NOT SET YET · WHAT THIS OPTION WOULD DO` reads as two labels collided. |

### Weekly command — Team health

| # | Sev | Defect |
|---|---|---|
| G-14 | P2 | **`FATIGUE 0%` is drawn as a full green bar.** The arc encodes the inverse of the figure beside it with nothing declaring the inversion. This is the same class of error the earlier review caught on the stakeholder bars (heat bands from a 40–99 scale applied to a 0–100 standing) — colour reading a different number from the one printed. |
| G-15 | P2 | `THE CASE TO WATCH` names the first row of the table — 100 % condition, *"No recorded fatigue"*. When nothing is wrong the panel invents a case. |
| G-41 | P2 | The first seven readiness rows are Branam, Branard, Branec, Branen, Braniel, Calay, Calick. The list is alphabetical and the surname generator's stems collide, so the surface reads as filler. |
| G-33 | P2 | The seventh row is bisected mid-glyph by the pinned footer. |

### Weekly command — Match Day (broadcast register)

| # | Sev | Defect |
|---|---|---|
| G-27 | P1 | **Player tokens truncate to `R…` `B…` `C…` `D…`** and overlap each other; the offensive line and the defenders are drawn in one vertical column; three tokens read `C`. The field is the dominant object of the flagship surface (`04` §6.1b) and it cannot be read. |
| G-08 | P1 | The staff call-in prints the role as **`offensiveCoordinator`** — a raw camelCase case, on the most prominent panel in the game. |
| G-30 | P2 | The same sentence (*"Staff flagged the plan does not cover this before the next snap."*) is printed simultaneously in the PRE-SNAP panel and the STAFF CALL-IN panel; the call-in offers **two options both titled "Trust the coordinator"**. |
| G-28 | P2 | `EVERY SNAP / COORD / LEVERAGE` is clipped at the trailing edge; the call-in panel overflows the right edge with a second panel visible behind it; the speed/pause/stop cluster overlaps the field's yard numbers. |
| G-29 | P2 | The result sentence truncates mid-word — `14 QB · Stopped for a loss of 1 yard. Co…` — in a 610 pt panel with room to wrap. The player who was sacked is `14 QB`, with no name. |
| G-31 | P2 | A grey rounded box carrying a spinner-like glyph sits inside the centre circle at midfield. |
| G-37 | P2 | At AX5 the scorebug reads `CAL 0 · MAR 0` — **opponent first** — where the default composition reads `MAR 0 | CAL 0`, and AX5 adds `LIVE CHECKPOINT`, which the default state never shows. Two type sizes, two readings of one state. |
| G-60 | P2 | `HALFTIME · PLAN EDIT` is drawn as a live control in Q1 at 14:54. |
| G-61 | P3 | The surface letterboxes with black margins on all four edges at the install floor, which is the aspect ratio it is authored for. |
| G-62 | P3 | `← WEEK`, the only exit, is buried inside the RESULT content panel. |

### Personnel — Roster

| # | Sev | Defect |
|---|---|---|
| G-25 | P1 | **The table clips its first and last columns.** `RosterView.swift:416` sets `.fixedSize(horizontal: true)` on the player name inside a fixed-width row, so the row cannot compress; with real generated names (`Krisam Kendhaven`, `Tayen Quillmont`) it exceeds `availableWidth × 0.68` and both the leading `POS` values and the trailing `ST` values are cut. The in-source comment records that `fixedSize` was chosen to stop a premature ellipsis — it traded a truncated name for two lost columns. |
| G-19 | P2 | The four-tile summary ribbon (`ROSTER / INJURIES / OPEN NEEDS / CLASS BALANCE`) on the navy `world.raised` fill is the stat-tile pattern F-16 removed from Recruiting, still shipping here. `04b` §4.3: *generic blue fills supply most of the hierarchy.* |
| G-43 | P2 | Every rating renders red. `04` §6.4's heat scale (red below 70) applied to a 40–99 scale paints an entire week-1 college roster as failing, so the colour carries no information and asserts something false. |
| G-63 | P2 | The dossier shows `Wesam Vanewell`, who is not among the visible rows — inspection and selection disagree. |
| G-21 | P2 | `STRENGTHS: Strength` (the attribute name reused as prose) above a `CONCERN` heading with nothing under it, and a gold `STRENGTH` flag duplicating the line below it. |

### Personnel — Depth chart

| # | Sev | Defect |
|---|---|---|
| G-26 | P1 | The field diagram is **clipped by the pinned footer** — the RB token is halved and the rest of the formation is unreachable. `PORT-LOG.md` records this exact defect being found and fixed once ("the depth chart's field was 30 pt taller than its slot"); it is back. |
| G-64 | P1 | Every token truncates: `Calius…`, `Nashyn…`, `Krisam…`, `Corick…`, `Vanceo…`, `Remyn…`, `Quinick Sed…`. A depth chart on which no name can be read. |
| G-65 | P2 | Six tokens are drawn for an offensive formation (WR, LT, G, C, RT, TE) — one guard, one receiver, no backs in the line — evenly spaced rather than in a formation. |
| G-66 | P3 | `SET THE CHART` is enabled but nothing on the surface affords changing the chart. |

### Personnel — Player profile

| # | Sev | Defect |
|---|---|---|
| G-04 | P2 | The `PLAYER` sibling link renders live, then prints *"Player Profile is not available yet"* and pushes the layout down, clipping more of the surface beneath. Same shape as `MATCH DAY` outside a fixture. A route that cannot be taken should not read as takeable. |

### Personnel — Development plan

| # | Sev | Defect |
|---|---|---|
| G-13 | P2 | `WHO HAS MOVED` beside `NOBODY HAS MOVED YET`, above four listed players with `—` deltas. The heading, the counter and the list disagree three ways. |
| G-34 | P3 | The attribute dial — the surface's hero object — is bisected by the footer strip. |
| G-67 | P3 | `SINCE AUGUST` is the only date anywhere in the career, and no other surface establishes it. |

### Personnel — Staff room

| # | Sev | Defect |
|---|---|---|
| G-68 | P2 | The player-coach is a row in the list, second, below the defensive coordinator. The person the career is about is indistinguishable from an employee. |
| G-43 | P2 | Every staff figure red, including `SCHEME FIT 48` — which is a fit, not a 40–99 rating, so the heat scale is being applied to a different scale again. |
| G-33 | P3 | The fourth row is clipped mid-glyph by the footer; `13 ON STAFF` with ~3.5 visible and no scroll affordance. |

### League — World search (reached as `ALL 62`)

| # | Sev | Defect |
|---|---|---|
| G-03 | P1 | The rail's seventh entry is labelled **`ALL 62`** and opens **World Search**. `CoachWorldChromeProvider.swift:65` even carries the comment *"The reference's seventh entry opens the registry overlay, not the league"* directly above the line that routes it to `.worldSearch`. |
| G-69 | P2 | `DONE ▶` occupies the committing-action slot on a search screen. The one gold, glowing control in the system means *commit*; using it to dismiss devalues it everywhere else. (Also `CONTINUE` on Standings/Rankings/Bracket/Team health, `BACK TO THE LEAGUE` on Statistics/News, `DONE` on Development/Staff room.) |
| G-70 | P2 | Results are grouped `PROFESSIONAL` first in a college career; the coach's own tier is second. |
| G-71 | P3 | The right ~40 % of the frame is empty while `Ashen Gate, Lamphier Falls Up…` truncates. |

### League — Standings, Schedule, Rankings, Bracket, Statistics, News

| # | Sev | Defect |
|---|---|---|
| G-16 | P1 | **Rankings and Bracket are the same view.** Both are `CompetitionOverviewView(focus:)`; on screen the only difference is the eyebrow word (`THE PICTURE` / `THE BRACKET`). Same rows, same empty `POSTSEASON` column, same footer sentence. `04b` §4.1: *the same composition used for an unrelated screen* is an automatic rejection. |
| G-07 | P1 | Schedule prints **`regularS…`** ten times — the raw `regularSeason` case, truncated mid-token. |
| G-11 | P1 | News prints `SEASON 0 · WEEK 1` for the same save on which Standings, Statistics and Development print `SEASON 1 · WEEK 1`. |
| G-72 | P2 | Standings shows rows 1–7 of 134 with the coach's programme at #122 and no way to reach it; the surface a coach opens to ask *where am I* does not answer. |
| G-21 | P2 | `POSTSEASON` is a column header over an empty column occupying ~40 % of the frame on both Rankings and Bracket. |
| G-73 | P2 | Schedule announces `804 GAMES` and shows ten, all week 1, each stamped `WEEK 1`, with no week control. |
| G-74 | P2 | Schedule does not contain the coach's own fixture; the header chip names it (`CALDER MINING`) and the grid does not. |
| G-20 | P2 | News restates the list row's headline at display size in the reading pane and adds nothing; there is no body. |
| G-75 | P3 | Standings' `REC` and `CONF` use a hyphen and `POINTS` an en dash for the same-looking `0-0` / `0–0` value; the points column is a record-shaped pair. |
| G-33 | P2 | The pinned footer clips the last row mid-glyph on Standings, Rankings and Bracket. It was introduced to stop rows scrolling through the footer sentence; it now hides them instead. |

### League — League map

| # | Sev | Defect |
|---|---|---|
| G-18 | P1 | **The identity header is clipped off the top of the frame and cannot be recovered** — the surface does not scroll. The chrome's one non-negotiable element is unreadable on this surface. |
| G-76 | P1 | The map — the surface's named dominant object — renders as a **~400 × 20 pt grey sliver** with a single magenta dot. `04b` §4.4: *no dominant football object is visible.* |
| G-77 | P1 | The tier switch is a **stock segmented control** in the system face on a grey capsule: outside the palette, outside `CutCorner`, outside the type scale. `04b` §4.3. |
| G-78 | P2 | The right panel overlaps the third team card; two of three cards truncate. |
| G-79 | P2 | `PRESTIGE 40 / MARKET 76 / TALENT IN REGION 63` — abstract scalars with no unit or scale; `DIFF 0` is tinted positive green. |
| G-80 | P3 | `Open team profile` is bare 20 pt text with no affordance. |

---

## World identity — the finding that no single surface owns

| # | Sev | Defect |
|---|---|---|
| G-40 | P2 | **The generated naming grammar is one shape.** Across 20 sampled programmes: Oakhaven Heath Upper, West Ivory Crossing, Jessup Hollow Coastal, South Dunmore Reach, Brack Bluff Academy, Fairbank Heath Maritime, Fairbank Landing Polytechnic, Netherby Basin East, Upper Draymoor Basin, Harrow Harbor West, Mossgate Crossing Lower, Central Wexford Landing, Hollowbrook Hollow… every one is `[Direction] + Place + Place`. **Not one has a nickname or mascot.** A college schedule that reads as place strings cannot carry `04b` dimension 1, and it is the cheapest of all these findings to fix — the pro tier already does it (`Ashen Gate Cinder Stalkers`, `Blackmere Harbor Iron Anchors`). |
| G-42 | P2 | `Marrow Hollow Normal` is the coach's own programme and appears in every header beside the team `Marrow Hollow`. It reads as a pipeline artefact rather than a school. |
| G-41 | P2 | Surname stems collide and lists are alphabetical, so consecutive rows share prefixes (Branam / Branard / Branec / Branen / Braniel; Uxhart / Uxwick). |

The legal guardrail is not at risk in anything I saw: no generated name approached a real programme,
and the place names in use (Marrow Hollow, Vantry Bend Marches) are invented rather than real. The
failure here is the opposite one — the world is so evenly generated that nothing in it is memorable.

---

## Accessibility

| # | Sev | Defect |
|---|---|---|
| G-35 | P1 | Rail labels 7.5 pt with `minimumScaleFactor(0.7)` → 5.25 pt effective; header family label 8.5 pt. Below `04` §6.2's 12 pt floor and below §6.1b's 9 pt micro-label exemption. |
| G-36 | P1 | The `04b` §8 machine check for authored type below 12 pt does not exist; the suite asserts a constant instead. |
| G-02 | P1 | Accessibility settings unreachable in a career. |
| G-37 | P2 | Match Day's default and AX5 states disagree about the score order and about whether `LIVE CHECKPOINT` exists. |
| G-38 | P2 | Disabled committing actions are the enabled control at `disabledOpacity = 0.4`. Composited, `gold-ink` on `action.primary` over `world.page` measures **≈2.7:1**, and no surface states why the control is disabled. WCAG 1.4.3 exempts disabled controls; `04b` §3.5 does not, and this treatment appears on Film room, Inbox, Team health and New career. |
| G-39 | P3 | Four views contain `if dynamicTypeSize.isAccessibilitySize { X } else { X }` — identical branches (`BracketPostseasonView`, `RankingsPlayoffPictureView`, `NewCareerCoachIdentityView`, `OpponentReportFilmRoomView`). |

**AX5 worked better than expected** and that should be said plainly: the accessible reflow branches
exist, they scroll, and the header and rail survive. The AX5 failures above are consistency and
floor failures, not the "cannot complete the task" failure I went looking for.

---

## Registry integrity

| # | Sev | Defect |
|---|---|---|
| G-17 | P2 | **28 of the 62 registry entries are one of ten host views** parameterised by `focus:` or `title:`. Career hub hosts 7 (Appointment, Coaching carousel, Job board, Job security, Offer, Promotion decision, Stakeholders); College offseason hosts 5 (NIL allocation, Portal hub, Portal market, Retention decisions, Signing day); Legacy history hosts 4 (Career line, Coaching tree, Record book, Rivalries); Pro offseason hosts 4 (Draft board, Draft room, Free agency, Pro scouting board); Competition overview hosts 2; Pro management hosts 2; plus Scheme book → Game plan, Personnel packages → Depth chart, Staff market → Staff room, Opponent report → Opponent film. |

Some of those are legitimately the same task at different moments. Rankings vs Bracket is not
(G-16), and the count matters because `62 converted / 0 pending` has been reported as coverage. The
honest number of distinct compositions is closer to **34**.

---

## Scores

All 21 surfaces fail the gate. The four systemic P0/P1s (G-01, G-02, G-05, G-35/36) apply to every
row, so no row can pass regardless of its own total.

| Surface | 1 Fantasy | 2 Composition | 3 Hierarchy | 4 World | 5 Control | 6 Access | 7 Truth | 8 Craft | Total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 1 | 1 | 2 | 1 | 2 | 2 | 3 | 2 | **14** |
| New career | 1 | 1 | 2 | 2 | 2 | 2 | 2 | 2 | **14** |
| Coaching HQ | 3 | 4 | 3 | 3 | 1 | 2 | 2 | 3 | **21** |
| Inbox | 1 | 2 | 2 | 3 | 2 | 2 | 2 | 3 | **17** |
| Film room | 2 | 2 | 2 | 2 | 2 | 2 | 1 | 3 | **16** |
| Game plan | 3 | 2 | 2 | 3 | 2 | 2 | 3 | 2 | **19** |
| Practice plan | 3 | 3 | 3 | 3 | 2 | 2 | 3 | 2 | **21** |
| Team health | 3 | 4 | 3 | 2 | 2 | 2 | 1 | 2 | **19** |
| Match Day | 4 | 4 | 3 | 3 | 2 | 2 | 1 | 1 | **20** |
| Roster | 3 | 3 | 2 | 2 | 2 | 2 | 2 | 1 | **17** |
| Depth chart | 4 | 4 | 2 | 2 | 2 | 2 | 2 | 1 | **19** |
| Player profile | — | — | — | — | 0 | — | — | — | **unreachable** |
| Development plan | 3 | 3 | 3 | 2 | 2 | 2 | 1 | 2 | **18** |
| Staff room | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 2 | **19** |
| World search | 2 | 3 | 2 | 3 | 1 | 2 | 3 | 3 | **19** |
| Standings | 2 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | **18** |
| Schedule | 2 | 4 | 3 | 2 | 2 | 2 | 1 | 2 | **18** |
| Rankings | 1 | 1 | 2 | 2 | 2 | 2 | 3 | 2 | **15** |
| Bracket | 1 | 1 | 2 | 2 | 2 | 2 | 3 | 2 | **15** |
| Statistics | 2 | 2 | 3 | 2 | 2 | 2 | 4 | 3 | **20** |
| News | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 3 | **17** |
| League map | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | **11** |

Nothing is close to 31/40. The median is 18.

---

## What is genuinely good, and should not be touched

Stated because an adversarial review that lists only defects is a misleading document.

- **The chrome is the reference.** Identity header, gold seam, pennant, icon rail, world backdrops,
  cut-corner geometry, grain. It is coherent across every surface and it looks like a football game.
- **The honesty lines are excellent and rare.** *"Home and away are as scheduled. Nothing here is a
  prediction."* / *"The field as it stands. Nobody is projected into a round they have not reached."*
  / *"Everything printed here happened. None of it is speculation."* / *"These are the people who
  carry the week when you are not in the room."* This is the voice the product should have
  everywhere.
- **The attribute-bar mapping is right.** `(value − 40) / (99 − 40)`, not `value / 100` — the fix
  recorded in the earlier review holds on Roster, Development and Staff room.
- **The conditional alert bar on Team health** — no permanent "0 injured" furniture — is the correct
  instinct, and the reason G-14 and G-15 stand out is that they violate the standard the same
  surface otherwise sets.
- **The AX5 reflow branches exist and work.** Content scrolls, chrome survives, nothing was lost.

---

## Recommended order

Nothing below is polish. The first three are the difference between a demo and a game.

1. **G-01** — give the rail or the header a route into recruiting, pro management and career, or
   build the `ALL 62` registry overlay the rail already claims to open (which closes G-03 too).
   Until this lands, 32 surfaces cannot be reviewed at all.
2. **G-05** — render `statusMessage` in the Floodlit hub and restore the preparation state and its
   delegate action. One surface, and the career stops being unplayable past week 1.
3. **G-25, G-26, G-27** — run the three table/diagram compositions against real generated names
   rather than sample data. All three are truncation and compression bugs, not layout redesigns.
4. **G-07, G-08, G-11** — three read-model formatting defects printing engine identifiers and a
   contradictory season number.
5. **G-35, G-36** — raise the two sub-9 pt labels and replace the constant assertion with a call-site
   scan, so the next one cannot land silently.
6. **G-48** — fill `FloodlitCostLine` from the real read models, or delete the three Label3 headings
   that promise costs the surfaces do not show.
7. **G-40** — give college programmes nicknames. The pro tier already has them, and it is the single
   cheapest lift available to `04b` dimension 1 across every surface at once.

## What this review did not cover

Reduce Motion, Reduce Transparency, VoiceOver order and rotor, sensor-left/right safe-area
ownership, the 852 × 393 promise floor and the 956 × 440 ceiling, the recruiting/pro/career families
(unreachable, per G-01), interruption and resume, and performance. `04b` §6 requires all of them
before any surface is called production-grade.
