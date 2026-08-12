# Reference-set findings, pass 2 — interface-mechanics inventory of six captures

**Destination:** `docs/briefs/2026-08-12-reference-set-findings-pass2.md`. **Working input, not
canon.** Second structural pass over the owner-supplied competitor captures, commissioned as a
complement to `docs/briefs/2026-08-12-reference-set-findings.md` (pass 1): pass 1 read the corpus
through an information-relationship lens; this pass reads six captures through a **mechanics lens**
— every interactive control, table column, persistent chrome element and visual encoding, each named
with its mechanism, what it binds, and what the player is asked to do with it.

Method and boundary: exactly six files from the gitignored `FM Screenshots/` directory were re-read
in full this session — C5, C9, C10, C13, C16, C17, per pass 1's §1 census mapping — including
enlarged crops of header strips, toolbars, slot columns and legends where capture resolution
allowed. They are third-party copyright; they stay outside the tree; this document is the durable
artefact and contains **no real club, player or competition name, no copied label list, and no
visual expression** — where a mechanism is carried by colour or shape in the source, only the
*binding* (what state the mark encodes) is recorded, never the look. The legal guardrail in
`CLAUDE.md` governs throughout. No canon file is edited by this pass.

Provenance is **inherited from pass 1's census** and repeated per capture below. Pass 1's grading
rule applies: anything witnessed only in C10 (`NON-FINAL CAPTURE`) is evidence of the competitor's
*intent*, not of a shipping product, unless a live capture independently witnesses it.

---

## 1. Scope and grading

| C | File (Screenshot 2026-08-09 at …) | Surface | Inherited grade |
|---|---|---|---|
| C5 | 22.38.37 | Squad overview hub with pinned-destination editor open | Desktop, apparently live |
| C9 | 22.41.08 | Mobile in-match pitch, play in progress | Mobile SKU (year 23), live |
| C10 | 22.41.31 | Tactics planner overlay | Desktop, **non-final capture** |
| C13 | 22.42.38 | Mobile in-match goal event with lower-third card | Mobile SKU, live; year uncertain |
| C16 | 22.43.33 | Squad table of a foreign club under scouting fog | Desktop, apparently live |
| C17 | 22.43.43 | Training week overlay | Desktop, apparently live |

Where a C10 mechanism also appears in a live capture, the pairing is stated and the grade rises to
live; the delta table (§3) marks the grade per finding.

## 2. Exhaustive inventories

Each row: the element, the mechanism as far as a still can show it, what information it binds, and
what the player is being asked to do. "Unresolved" items are gathered again in §4.

### 2.1 C5 — squad overview hub with pinned-destination editor (desktop, live)

Persistent chrome:

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 1 | Back/forward chevron pair | Browser-style history navigation over screens | Visit order across the whole product | Retrace steps instead of re-deriving a path (see A8) |
| 2 | Club crest block | Identity anchor at the chrome's corner | Session to the employing club | Orient; likely a home shortcut |
| 3 | Six top-level menus, each with a caret | Two-level IA: family menu, then dropdown of destinations | The whole product into six families | Choose family, then destination |
| 4 | Sub-tab row under the active family | Local tabs for the family's screens; the active tab is marked; three tabs carry a **link-out glyph**; a final overflow item holds the rest | Sibling screens to one family; marked tabs to *other* families they jump into | Move laterally; know before tapping which tabs leave the family (F32) |
| 5 | Global search field | Free-text search in chrome | Query to world objects (players, clubs, staff) | Jump to a named object (contrast A2: the mock's search was over the product's own tiles) |
| 6 | Utility icon group (four icons; one is settings by glyph) | Standing utilities | — | Unresolved individually (§4) |
| 7 | Date-and-clock widget | Current in-game date, weekday, day clock | Session to world time | Know where in the week/season you stand |
| 8 | Advance button, here labelled with the inbox's name plus a double-chevron | The continue control's label names the **next stop** the advance will land on (C10's same control reads as a plain continue) | Time advance to the pending obligation that will interrupt it | Advance, knowing what you will be shown next (F31) |
| 9 | Pinned-shortcut row: a pins dropdown plus six icon shortcuts, one wearing an unread-count badge, one a smaller dot badge | User-curated pin bar rendered as icon-only shortcuts; pins carry live badges | Six chosen destinations to one-tap reach; the inbox pin to its unread count | Maintain a personal shortcut set (A1); see arrivals without visiting |

Squad hub content:

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 10 | Squad panel header: crest, club name, "players" count in parentheses | Collection labelled with its size | Roster to its bound (F19) | Read the table knowing its extent |
| 11 | Panel page dots (three, first active) | The panel is a pager cycling alternative panel contents | Several summaries to one hub slot | Swipe/cycle for more without leaving the hub |
| 12 | Market-window chip: state icon, a league code, "closed", an until-date | Market state as a glyphed chip **on the roster header**, with the reopen date | Roster reading to the current administrative constraint | Plan signings inside the calendar (F25) |
| 13 | Registration chip: shirt icon plus an assigned-count | A labelled count chip beside the window chip | Roster to a registration/number budget | Referent unresolved (§4); the mechanism (admin count on the roster header) stands |
| 14 | Squad table columns: portrait + profile micro-icon + name; position codes; age; nation flag + code; appearances with substitute appearances in parentheses; average rating as a graded pill, dash pill when empty | Six fact columns; the appearances cell carries two numbers in one cell (starts vs from bench); the rating pill grades itself; absence of data is an explicit dash state | Identity to availability, usage and current level per row | Scan the squad; note who has not played (F19 kin; dash state is F3 kin on home data) |
| 15 | Name-text tint on several rows | Player-name colour encodes an availability/interest state, with no glyph or word beside it | Identity text to a state | Learn the tint convention (anti-lesson A6) |
| 16 | Table scrollbar | The list scrolls inside its card | — | — |
| 17 | Tactics tile: title, three sub-entry chips, formation thumbnail, caption naming the absence ("none set") | A hub tile that (a) exposes **several named doors** into its system, (b) draws current state as a thumbnail, and (c) states its own **empty state** in place | The tactics system's state and entrances to one tile | Treat the hub as a checklist: the tile itself says what is not yet done (F33) |
| 18 | Youth tile: one-word verdict above the label; staff-recommendation rows (portrait, truncated name, position codes, age, star grade); an intake row with a calendar chip, absolute date and days-to-go | Verdict-first quality read; **attributed** prospect suggestions each carrying a graded strength; a future event wearing absolute and relative time together | Programme quality to a word; prospects to their recommender and grade; the intake to its distance | Trust or verify staff picks; feel the deadline approach (F29, F30) |
| 19 | Feedback tile: two constituency rows, each with an icon and a one-word verdict chip | Per-stakeholder standing as a labelled verdict word | Each constituency's current opinion to one chip | Know who is drifting before it becomes a crisis (F28) |
| 20 | Medical tile: count headline ("N players injured"), then name chips per casualty, then a footer line counting players **at risk** of injury | Fact count, tappable instances, and a **forecast** line in one tile | Current casualties to predicted ones | Adjust load before the next injury, not after (F27) |
| 21 | Discipline tile: headline naming a ban **against the named next fixture**; footer counting players one caution from a ban | Suspension expressed as the match it costs; threshold proximity counted before it is crossed | Discipline state to the fixture it affects; near-misses to a count | Plan the eleven around the ban; manage risk players (F26) |
| 22 | Right-edge panels (partially cropped): a prose confidence snippet; a best-performer row with a rating pill labelled as an average; an absence panel with a date-range chip | Stakeholder prose, top performer, and a squad-absence window as small hub tiles | — | Cropped; sources unresolved (§4) |

Pinned-destination editor overlay:

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 23 | Overlay title carrying "used of capacity" ("6/12") | The pin budget stated in the header | Pins to their bound (F19) | Spend a scarce budget |
| 24 | Two-column list of ~30 destinations spanning inbox, squad, tactics, market, staff, competition, finance and media families — pinned entries gathered first, the rest alphabetical; each row an icon, a name, and a star toggle; the list scrolls | Binary star toggle per destination against a 12-pin cap; two entries point at an **external market-listing service** (a third-party integration exposed as ordinary destinations) | The product's whole destination space to a personal shortlist | Curate reach over an IA too large to reach directly — the anti-lesson A1 stands; the star-toggle-against-budget mechanism itself is F19 |

### 2.2 C9 — mobile in-match, play in progress (mobile, live)

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 1 | Menu button (top-left) | In-match menu access | — | Leave or adjust outside the play surface |
| 2 | Match clock | Elapsed time, minute:second | Play to match time | Track progress |
| 3 | Team plates: home crest + short name on its identity plate; away code + crest on its own; two score digits between them | Scoreline as three cells; each side wears its identity plate | Score to sides | Read state at a glance |
| 4 | Progress-mark row: **nine round marks, first filled** | Discrete progress marks beside the clock (pass 1 F12) | Elapsed to remaining — exact meaning still unread | Sense how much match remains |
| 5 | Settings glyph | Match options entry | — | — |
| 6 | Pause control (labelled plate, corner) | Match tempo control persistent in chrome | The simulation's flow to one always-on control | Stop time to think — the one guaranteed intervention (F35) |
| 7 | Full pitch, whole field in frame, goals at the screen edges | The entire playing surface visible at once; no camera pan | — | Watch shape, not a window |
| 8 | Players as numbered team-coloured discs; both goalkeepers distinct; the ball a small mark on the carrier | Uniform anonymous mark vocabulary for all 22 | Bodies to sides and numbers | Read structure, not identities |
| 9 | **Surname printed under exactly one disc — the carrier's** | The single exception to anonymity: the man on the ball is named in place | Attention to the current protagonist | Follow the story without a legend (F34) |
| 10 | Officials as letter-coded discs (one central, two at the edges) | Non-players share the disc vocabulary, letter instead of number | Everyone on the field to one mark grammar | — (minor; §3 minor list) |
| 11 | One-line commentary strip, full-width at the field's foot, filled in the acting team's identity | Rolling one-line narration; the strip's fill appears bound to the team acting — single-capture evidence only (§4) | The sentence to its subject | Read the story the field does not carry (pass 1 §3.3) |
| 12 | Two corner controls flanking the strip, both built on a pitch glyph, the right adding a person figure | The only standing management doors on the play surface — by glyph, view options and team/personnel respectively; exact functions unresolved (§4) | Management to two fixed entry points | Intervene rarely, deliberately (F35) |

### 2.3 C10 — tactics planner overlay (desktop, non-final capture)

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 1 | Overlay title row: name, an actions dropdown, close | The editor carries its own action menu | — | Import/export/manage the plan (contents unresolved) |
| 2 | Numbered plan slot ("1") + named-plan dropdown + an add button | A small **numbered library of standing plans**, one active; the name encodes shape plus a style word; "+" creates another | A whole plan to a reusable, switchable preset | Maintain alternates; switch rather than rebuild (F15) |
| 3 | Style dropdown and mentality dropdown, each showing value plus category label | Plan-level qualitative dials as two-part controls: the chosen value and the dial's name in one control | A qualitative posture to the plan | Set posture without a settings page |
| 4 | Intensity gauge (label + a short row of discrete marks, most filled) | A **derived** readout: the computed load consequence of the current style/mentality choices, displayed beside them | Choices to their aggregate cost | Watch the cost move as you choose (F38) |
| 5 | Phase tabs: both / one phase / the other | The same eleven holds **distinct standing arrangements per game phase**; tabs and twin pitch panels expose them side by side; several players' role tokens differ between panels | One selection to two phase shapes | Set posture per phase, not one static formation (F13) |
| 6 | Scope control: "set for" label + all-matches / next-match pair | A plan edit **declares its temporal scope**: standing, or one fixture only | The edit to how long it lives | Distinguish base plan from match plan (F14) |
| 7 | Next-fixture chip beside the scope control: opponent name + "tomorrow" | The next match named with relative time exactly where "next match" is an option | The scope choice to its concrete referent | Know what "next match" means before choosing (F14, F30) |
| 8 | Advice dropdown (star glyph) | Staff counsel **on demand** inside the editor — pull, where the in-match suggestion of pass 1 §3.2 is push | Staff judgement to the point of decision | Ask before committing (F16) |
| 9 | Undo button | The editor keeps a reversible history | Edits to a revert path | Experiment safely (F16) |
| 10 | Quick-pick button (shirt glyph, dropdown) | One-action competent auto-fill of the whole selection, with variants | Staff judgement to a complete default | Accept, then adjust — delegation as a first-class control (F16) |
| 11 | Twin pitch panels, each titled with its phase and carrying an instructions link with a double-chevron | Arrangement view and instruction list are separate surfaces joined by a per-phase deep link | The shape to its written instructions | Drill from picture to prose per phase (F13; pass 1 F9 kin) |
| 12 | Per-panel view dropdown (eye glyph) and grid toggle | Display-density and arrangement-view controls per panel | — | Contents unresolved (§4) |
| 13 | Player tiles on the pitch: shirt with squad number, role token plate, **star row in half-star steps**, surname | The assignment slot grades its occupant **in place**: role fit as a five-step scale on the tile itself; role tokens are grouped into families by plate | The man, the role, and how well he fits it, at the point of assignment | Spot the weak slot at a glance (F17; scale anti-lesson A7) |
| 14 | Small ball badge on three attacking tiles | Duty overlays badge the same tile (by glyph a set-piece/taker duty; exact duty unresolved, §4) | Standing duties to the man's slot | See duties where you assign (F17) |
| 15 | Substitutes panel header: title, "15 of 15", and a discrete capacity meter of fifteen marks, all filled | A bounded list wearing used-of-capacity in its header, twice over (numeral and marks) | The bench to its budget | Fill, and know when full (F19) |
| 16 | Bench rows S1–S11: slot token, portrait, name, position codes, condition heart, dash rating pill, remove control | An **ordered** bench: slot tokens carry priority; a per-row trash control edits membership; condition rides each row; the rating cell is an explicit empty state pre-match | Priority to token; fitness to the pick; membership to one tap | Order the bench, cut to the limit (F18) |
| 17 | Four further rows **without** slot tokens | Overflow members below the visible cut: token presence encodes matchday membership | In-squad versus out | Choose who travels (F18) |
| 18 | Phase tag chips at each panel's foot | The diagrams restate which phase they are | — | — |
| 19 | Non-final stamp (corner) | Provenance watermark | — | (grading only) |

### 2.4 C13 — mobile in-match goal event (mobile, live; SKU year uncertain)

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 1 | Menu button | As C9 | — | — |
| 2 | Team plates with crests and short codes; single score cell between; clock after the second plate | Same scoreline grammar, differently ordered across SKU years | Score to sides | — |
| 3 | Progress-mark row: **about eleven dash-shaped marks, first filled** | Same mechanism as C9 with different cardinality and glyph — the count is not fixed across captures, which further weakens any fixed-period reading (F12 caveat strengthened) | Elapsed to remaining | — |
| 4 | A control between the marks and settings, glyph a dotted downward arrow | Unresolved (§4) — plausibly a skip-to-next-event control | — | — |
| 5 | Settings glyph; pause control on its own plate | Persistent tempo control, as C9 | — | (F35) |
| 6 | Full pitch, all 22 as numbered discs, officials letter-coded, goalkeepers distinct | As C9 | — | — |
| 7 | Surname painted at the event protagonist's disc | The scorer is the one named man on the field at his moment | Attention to the protagonist | (F34) |
| 8 | Lower-third event card, left block: squad number, portrait, nation flag, surname, a one-line archetype descriptor, and the **club name** | The identity card teaches who this actor is at the moment he matters; attribution to a side is carried **textually by the club line**, while the card's fill is product-styling — so colour is not the attribution mechanism here (§4 note against over-reading C9's strip fill) | The event to a fully-identified, characterised actor | Meet the actor at the moment of consequence (pass 1 §3.3 holds; sharpened) |
| 9 | Lower-third right block: full name, event word, large event glyph | Event type as word plus icon beside the identity block | The moment to its kind | — |
| 10 | Card overlays the field; no commentary strip visible in-frame | The event card takes the narration slot during the event | — | — |
| 11 | No corner management doors visible in this frame | — | — | (does not contradict C9; different SKU year) |

### 2.5 C16 — foreign club's squad table under scouting fog (desktop, live)

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 1 | Breadcrumb trail in chrome (three levels deep, ending at the foreign club's first team) | Drill-ins into another club's pages run under a **path trail** inside the player's own chrome — the foreign object is visited, not switched to | Current position to the route in | Back out level by level (F32) |
| 2 | Stacked chevron pair beside the foreign crest | Unresolved (§4) — stepper between clubs or section collapse | — | — |
| 3 | Header: foreign crest, club name, "senior squad players" with count | Collection labelled with its bound, on someone else's roster too | (F19) | — |
| 4 | Named column-set dropdown (eye glyph) | One table, several named column families switched by dropdown — the control behind the column-set idea pass 1 already adopted (A4/T8); observed live | The same rows to different fact families | Switch lenses, not screens |
| 5 | Actions dropdown (person glyph) + leading checkbox column on every row | **Multi-select plus a bulk-action menu**: the table is a worklist operating on a selection | Many rows to one command (e.g. queue scouting) | Batch the market work (F24) |
| 6 | Filter dropdown | Row filtering | — | Narrow the list |
| 7 | Phase chip pair above the table | The **foreign** squad readout is phase-filtered with the same phase grammar as the planner (C10) — the selected phase presumably conditions the lineup plates | Their arrangement to a phase | Study the opponent per phase (F13's live witness) |
| 8 | "Picked" column, first eleven rows: position-slot plates, each containing a **mini-pitch micro-glyph with a dot locating the slot** plus the position code | The projected eleven leads the table in lineup order; the position token carries its own spatial locator | Reading order to their depth chart; token to place on the field | Read "who we will face" first (F23) |
| 9 | "Picked" column, next rows: bench slot tokens (S-numbers), then blank | The same ordered-bench token vocabulary as the player's own planner (C10), reused in the opponent readout; three membership tiers encoded by one column (plate / token / blank); one token absent from the sequence (§4) | Their matchday hierarchy to one column | Read their bench order too (F18, F23) |
| 10 | Status-chip column: three-letter state chips; the injury chip appears in **two severity states** | Pass 1 §3.10's glyph vocabulary, plus severity grading within one chip type | State to severity | Weigh, not just notice, availability (minor list, §3) |
| 11 | Player column: portrait, uniform profile micro-icon, name; two names tinted (two different tints) | Identity text as a colour-only state channel again | (A6) | — |
| 12 | Position column and best-position column | "Where he plays" separated from "where he is best" | Usage to optimum | Spot misused players |
| 13 | Value column: banded range with a tag glyph, or "unknown", or **"not for sale"** | The market cell has three answer kinds: estimate band, absence of knowledge, and the owner's **stance** | The asking question to band, fog, or refusal | Read posture as well as price (F20) |
| 14 | Best-role column: fogged throughout | Under fog even the derived judgement columns blank | — | (F21) |
| 15 | Age and nation columns: exact for every row | Public record stays exact under fog | — | (F21) |
| 16 | Ability and potential columns: "unknown" for every row; playing-time column: "scouting required" for most rows but a **public standing word for famous ones** | **Fog is per-fact, not per-player**: one row mixes exact public record, banded estimates, fogged judgements, and publicly-known standing; the required action sits in the cell where the answer would be (pass 1 F3's action-in-cell, now with cell-level granularity) | Each fact to its own knowledge state | Buy information precisely where it is missing (F21) |
| 17 | Wage column: banded ranges with a per-week unit suffix | Compensation estimated as a band under fog, unit stated | (F21) | — |
| 18 | Expiry column: exact date, each with a clock-arc glyph; the glyph renders in an **urgent state only for dates inside the nearest horizon** | Contract end is public and exact, and near expiries **flag themselves** | The poaching opportunity to a pre-lit mark | Scan for expiring deals without sorting (F22) |

### 2.6 C17 — training week overlay (desktop, live)

| # | Element | Mechanism | Binds | Player is asked to |
|---|---|---|---|---|
| 1 | Breadcrumb trail ending at the overlay, whose middle step is a sibling system, not a parent | The trail records the **route taken**, not a fixed taxonomy | Position to visit path | Back out the way you came (F32) |
| 2 | Close control | Overlay dismissal | — | — |
| 3 | Tactics summary card: title, the same three sub-entry chips as C5's hub tile, formation thumbnail with numbered shirts, footer chips naming the shape and flagging it customised | The **identical summary card recurs across screens** (empty-state on the hub in C5, populated here); the footer admits deviation from preset ("custom" flag) | The tactics system's state to every screen that mentions it | Trust one card everywhere (F33) |
| 4 | Two small marks over two shirts in the thumbnail | Unresolved (§4) — by position plausibly leadership marks | — | — |
| 5 | Week grid: seven day columns by two week rows, dated; up to three session blocks per day | The week is a grid of **typed slots**; a day holds a small fixed number of them | Chronology to capacity | Allocate finite slots (F36) |
| 6 | Session blocks: type icon + short name, colour-familied by kind (drill families, recovery, rest) | Session type as icon-plus-word block | Each slot to its purpose | Compose the week |
| 7 | Travel blocks and **match blocks (two crests + a home/away letter) occupying the same slots as drills** | Fixtures and travel **consume training capacity visibly** — congestion costs preparation, in place | The fixture list to the practice week | Feel the cost of a congested week (F36) |
| 8 | Today's date cell highlighted; the elapsed week's blocks rendered dimmer than the coming week's | Position-in-week state; elapsed days render spent (probable — §4) | Now to the plan | — |
| 9 | Individual-training card: up-glyph count of improvements, down-glyph count of regressions | Development counters beside the plan (pass 1 F5's counters) | Cause to effect | — |
| 10 | Notable-developments panel: named empty state | Absence stated in place again | (F33) | — |
| 11 | Units card: three named unit rows with icons and **headcounts** | The squad partitions into named practice units with visible sizes | Who trains what to how many | Rebalance groups (F39) |
| 12 | Intensity card: five condition glyphs whose **fill fraction rises band by band**, each with a training **multiplier** beneath | A standing **policy** mapping condition band to dose: the same condition glyph vocabulary as the planner's bench rows (C10), used as the key of a rule table; whether the multipliers are settable here is unresolved (§4) | Player state to training load, as a rule rather than a day-by-day choice | Govern load by state (F37) |
| 13 | Mentoring card: named empty state with icon | Absence stated in place | (F33) | — |
| 14 | Coach-assignments card: four rows of count × workload band, each with a small load ring | The plan reports its **staffing feasibility**: the distribution of coach workload the current week implies | The week to the capacity of the people delivering it | Hire or redistribute before quality decays (F38) |
| 15 | Facilities card: one-word verdict chip | Verdict-first quality read (pass 1 §3.1 family) | — | — |
| 16 | Session names truncated at column width | — | — | (§4: several unreadable) |

## 3. Delta — mechanisms not already recorded

Baseline beaten against: pass 1's F1–F12, A1–A5 and §6 verified list, and `01-RESEARCH.md` §6.6 §3
(items 1–11) and §4 (4.1–4.4). Numbering continues from pass 1. Each finding is a relationship,
never a layout; grades inherit §1. Where a prior finding covers half the mechanism, the prior
finding is named and the **uncovered half** is what is stated.

| F | Finding | The relationship | Seen in | Destination |
|---|---|---|---|---|
| F13 | **One selection, phase-conditioned shapes** | The same chosen personnel holds distinct standing arrangements per game phase, viewed/edited side by side — and even the *opponent's* readout is phase-filtered with the same grammar. Extends F9/§3.5, which held only the token mapping | C10 (non-final) + C16 (live witness) | Scheme Book, Personnel Packages, Opponent Preview — our offense/defense/situational package views |
| F14 | **A plan edit declares its scope** | Every change is stamped standing-plan or next-match-only, with the next fixture named (with relative time) beside the choice | C10 (non-final) | `02` game-planning loop; Game Plan vs Scheme Book split |
| F15 | **A small numbered plan library, one active** | Whole plans persist as a handful of numbered, named presets (name = shape + style summary); switching is selection, not reconstruction | C10 (non-final) | Scheme Book; base vs situational game plans |
| F16 | **The editor treats selection as drafting** | Delegate (one-action competent auto-fill with variants), consult (staff advice *pulled* on demand — the planning-side complement of §3.2's *pushed* in-match suggestion, which is the uncovered half), revert (undo) — all first-class toolbar controls | C10 (non-final) | Depth Chart auto-fill; staff advice model; any roster/plan editor |
| F17 | **The assignment slot grades its occupant in place** | Role-fit renders on the slot tile itself at the point of assignment, and duty badges overlay the same tile — fitness-for-role lives where the role is given, not on the player's page | C10 (non-final); C5 kin (graded recommendations) | Depth Chart, Personnel Packages — carried by our worded verdict chips, not a second scale (see A7) |
| F18 | **The bench is an ordered list with a visible cut** | Slot tokens mark matchday membership *and* priority; overflow rows sit beneath without tokens; the same token vocabulary reappears in the opponent's readout — a shared cross-screen encoding of squad hierarchy | C10 (non-final) + C16 (live witness) | Depth Chart backups; gameday actives/inactives list |
| F19 | **Bounded collections wear their bound at the header** | Used-of-capacity is stated wherever a bounded collection is shown — pins, bench (numeral *and* discrete capacity marks), roster counts. §3.8 held the money case; the mechanism is general, and it is the UI face of the engine's stated-bound rule | C5, C10, C16 | `04` §4 list grammar; roster, scholarship, bench and board counts |
| F20 | **The market cell can answer with a stance** | The value cell has three answer kinds: estimate band, unknown, and the owner's refusal ("not for sale") — posture is a display state alongside price. The uncovered half of F3/F8 | C16 | Portal Market, Pro Scouting — trade interest carries "untouchable" as a first-class state |
| F21 | **Fog is per-fact, not per-player** | One unscouted row mixes exact public record (age, position, expiry), banded estimates (value, wage), fogged judgements (ability, potential) and publicly-known standing — knowledge state attaches to the cell, and F3's buy-action sits in exactly the cells that lack answers | C16 | Recruiting/Pro Scouting data model; density model T2 |
| F22 | **Expiring deals flag themselves** | The contract-end glyph carries an urgent state only inside the nearest horizon — the poaching scan is pre-computed into the column | C16 | Free Agency, Portal Market watchlists; contract-year chips |
| F23 | **The opponent's roster reads in lineup order** | The foreign table leads with slot plates for the projected eleven, then the ordered bench, then the rest — the depth chart *is* the reading order, and the position token carries its own field-locator micro-glyph | C16 | Opponent Preview, Game Plan; feeds F8's decision-row columns |
| F24 | **The table is a worklist** | Rows multi-select via a leading checkbox column and a bulk-action menu operates on the selection — a readout becomes batch assignment (queue scouting across many targets at once) | C16 | Pro Scouting and Recruiting boards; watchlist building |
| F25 | **The roster header carries the market's administrative state** | Window open/closed with its reopen date, and a registration count, ride the squad table itself — the roster is read inside its constraints. Extends F4 beyond the ledger surface | C5 | Cap/window/eligibility chips on Roster and Depth Chart headers |
| F26 | **Discipline is a next-fixture consequence plus a threshold watch** | A suspension is stated as the named match it costs, and players one caution from crossing are counted before they cross | C5 | Availability strip on Game Plan/Depth Chart; suspension and eligibility surfaces |
| F27 | **The medical panel forecasts as well as counts** | Current casualties (count + named instances) sit directly above a predicted-casualties line ("at risk") — the tile answers "who is down" and "who is next" together; pairs with F5's cause-effect co-location | C5 | Medical/availability tile; Practice Plan load warnings |
| F28 | **Standing is a per-stakeholder verdict chip** | Each constituency (board, supporters) renders one labelled verdict word on the hub — job security as a glanceable per-audience state, §3.1's verdict-first applied to relationships | C5 | Coaching HQ; job-security and program-confidence surfaces |
| F29 | **Recommendations arrive with a source and a grade** | Prospect suggestions are attributed (staff-sourced), graded (star strength), and dated (intake countdown) — provenance, confidence and deadline travel with the suggestion | C5 | Recruiting pipeline; staff recommendation rows |
| F30 | **Deadlines wear their distance** | Future events carry relative time beside (or instead of) the absolute date wherever they appear — days-to-go on a programme event, "tomorrow" on the next fixture, an urgency flag on near expiries. §3.9 held the mock agenda's time-cost; live captures generalise it to event rows everywhere | C5, C10, C16 | Calendar/Season strip; Inbox; any dated chip |
| F31 | **The advance control names its next stop** | The same chrome slot reads as a plain continue in one state and as the pending destination in another — advancing time tells you what will interrupt it | C5 vs C10 | Week-advance control (P12); Inbox handoff |
| F32 | **Navigation marks its exits, and drill-ins carry a trail** | Sub-tabs that leave the current family wear a link-out glyph before they are tapped; visits into foreign objects and overlays run under a breadcrumb trail recording the route (not a taxonomy) | C5, C10 (glyphs, live+non-final); C16, C17 (trails, live) | `04` §3 world strip/local routes: mark cross-family jumps; foreign-object visits |
| F33 | **A hub tile states its own absence, holds several doors, and recurs** | F10's uncovered halves: a tile can expose multiple named sub-entries (not one link); when its system is empty it says so in place, converting the hub into a checklist; and the identical summary card is reused across screens, so one representation serves everywhere | C5, C17 | Coaching HQ tiles; empty states as imperatives; one card per system, reused |
| F34 | **The field names exactly one actor** | All players are anonymous numbered marks except the protagonist of the current touch or event, whose surname prints at his mark — the sharpened form of §3.3's "plain numbered dots": anonymity has precisely one exception, and it is the attention director | C9, C13 | Match Day field (P13); directed-attention rule |
| F35 | **In-play management is two doors plus tempo** | The play surface's standing controls reduce to a persistent pause and two fixed corner entries; every other decision arrives as an event. F11 said the registers are separable; this is the *size* of the management register while watching | C9 (C13 consistent) | Match Day controls; call-in model — decisions push in, menus stay out |
| F36 | **Fixtures consume training slots** | Travel, match and rest blocks occupy the same day-slots as drills in the week grid — congestion visibly spends preparation capacity. F5's uncovered half: not just load beside consequence, but the fixture list eating the plan | C17 | Practice Plan week grid; bye/travel weeks |
| F37 | **Load policy is keyed by condition band** | A standing rule maps each condition band (the same condition glyph vocabulary the rosters use, encoded by fill fraction) to a dose multiplier — dose follows state as a rule, not only as day-by-day choices | C17 (live); C10 kin (condition glyphs on bench rows) | Practice Plan fatigue policy; medical/load governance |
| F38 | **The plan states its derived cost beside the choices** | A computed consequence of current settings renders next to them: plan-level intensity as a discrete gauge on the tactics planner; implied coach-workload distribution (count × load band) on the training screen — feasibility is a readout, not an audit | C17 (live); C10 (non-final) | Scheme/Game Plan cost readouts; Practice Plan staffing feasibility; staff capacity |
| F39 | **The squad partitions into named units with headcounts** | Practice groups are first-class named units whose sizes are always visible — membership is a managed quantity | C17 | Practice Plan position groups (native to our sport); Depth Chart grouping |

Anti-lessons, extending pass 1's A1–A5:

| A | Symptom | The failure it evidences | Our tripwire |
|---|---|---|---|
| A6 | Player names tinted to encode availability/interest states, with no glyph or word carrying the same state (C5, C16 — two different tints in one table) | Colour-only encoding on identity text: a state channel invisible to colour-blind players and unreadable without the learned convention | `04` §6's accessibility contract: every state needs a non-colour carrier; a tinted name without a chip is a defect |
| A7 | A second learned scale (five-step stars for role-fit and prospect strength) living beside the primary numeric rating scale (C10, C5) | Two coexisting numeracy conventions, each needing learning — A5's failure, doubled | Ratings stay 40–99 printed; fitness-for-role and recommendation strength are **worded verdicts**, never a parallel scale |
| A8 | Browser-style back/forward history chevrons in persistent chrome (C5, C10) | Navigation deep enough to need session history is navigation that has outgrown its map — A1's failure seen from another side | The world strip plus local routes; if a history stack ever seems necessary, the IA has failed |

Minor mechanisms recorded without promotion (real, but too small or too sport-specific to carry a
finding): severity grading within one status-chip type (C16, two injury grades); the position
token's field-locator micro-glyph (C16 — folded into F23); pinned shortcuts carrying live unread
badges (C5); a fixture summarised as two crests plus a venue letter (C17); elapsed days rendering
spent in the week grid (C17, probable); officials sharing the field's mark vocabulary, letter-coded
(C9, C13); appearances cells carrying starts and substitute appearances as one two-number value
(C5); the explicit dash pill as a no-data state on home rows (C5, C10 — F3's state grammar applied
outside fog).

## 4. Not resolvable at capture resolution

Recorded so nobody later cites them as observations:

1. **C5:** the referent of the shirt-icon "assigned" count on the squad header (exceeds the squad
   size; plausibly club-wide shirt numbers — unverifiable). The four chrome utility icons'
   individual functions. The icon-to-destination mapping of the six pinned shortcuts (inferable
   from the editor's starred list, not proven). The sources of the cropped right-edge panels
   (prose confidence snippet; average-rating row; absence panel).
2. **C9:** the exact functions of the two corner controls flanking the commentary strip (glyphs
   suggest view options and team management). Whether the commentary strip's fill is genuinely
   bound to the acting team — one capture is consistent with it; C13's event card is
   product-styled, not team-styled, so colour-as-attribution must not be claimed from this corpus.
   A small tab at the left screen edge below the header (possibly a drawer handle).
3. **C10:** the contents of the overlay's actions menu, the per-panel eye-dropdown, and the grid
   toggle; the precise duty meant by the ball badge on three tiles; the exact mark count of the
   intensity gauge.
4. **C13:** the dotted-downward-arrow control between the progress marks and settings (plausibly
   skip-to-next-event); the protagonist's on-field name label is present but at the edge of
   legibility; the progress-mark count (~11) is approximate.
5. **C16:** the stacked chevrons beside the foreign crest (club stepper vs collapse); the fogged
   best-role column's populated form; one bench token absent from the otherwise contiguous
   sequence (unassigned slot or sorting artefact); whether the expiry glyph's arc length encodes
   remaining time or is a fixed clock mark; small marks inside two lineup plates.
6. **C17:** whether the condition-band multipliers are player-settable policy or a fixed rule
   display; two small marks over shirts in the tactics thumbnail (plausibly leadership marks);
   several session-block names truncated past reading.
7. **Cross-capture:** the progress-mark row's cardinality differs between the two mobile captures
   (nine round marks vs ~eleven dashes) — F12's "exact meaning unread" caveat is strengthened, and
   any fixed-period interpretation is now positively disfavoured.

## 5. Consistency check

Nothing in this pass contradicts pass 1 or `01-RESEARCH.md` §6.6. The two mobile captures' header
differences (mark cardinality and glyph, plate/clock order) are consistent with pass 1's proposed
correction 1 (different SKU years) and add evidence to it. C16's phase chips and slot tokens give
two of C10's non-final mechanisms (F13, F18) live witnesses, which is the direction the grading
rule wants strengthening to run. All six captures continue to support the §6 verified list; no
prior finding is weakened by anything inventoried here.
