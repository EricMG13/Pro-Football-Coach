# Density model — how depth is bought on a landscape iPhone

**Destination:** `docs/briefs/2026-08-12-density-model.md`. **Working input, not canon.** This file
carries Outcome 1 of `docs/briefs/2026-08-12-reference-uplift-brief.md`. §7 below is a **proposed
canon amendment** to `docs/04-UX-AND-DESIGN-SYSTEM.md` (a new §4.5); nothing in canon has been
edited. Where this file disagrees with `04`, `04` wins and this file is the defect.

Evidence base: the eighteen owner-supplied captures (read in full this session; provenance census in
`docs/briefs/2026-08-12-reference-set-findings.md`), `docs/01-RESEARCH.md` §6.5 and §6.6, the
current tree (`Sources/ProFootballCoachUI/`, 13 files, fixture-driven), and the measured state in
`docs/STATUS.md`. Sourcing note: no web query was run this session; every externally-verifiable
number below inherits its existing ASSUMPTION/UNVERIFIED grade from canon and is listed in
`docs/briefs/2026-08-12-sourcing-log.md`.

---

## 1. What depth is actually made of

The brief's central question, answered before any technique: the reference desktop screens run up to
fifteen columns on roughly ten times our display area. If depth were column count, the translation
would be impossible and the honest answer would be "build a smaller game." It is not column count.

Read across all eighteen captures, what makes the reference feel deep decomposes into six
properties, and only one of them is bought with pixels:

| # | Property | What it is | Bought with |
|---|---|---|---|
| D1 | **Completeness of answer** | The screen answers the whole question its task asks — a person screen answers "who is he, what is he worth, what changed, what do I do"; a finance screen answers "am I compliant, how far over, what happens next season" | Information architecture |
| D2 | **Stated judgement** | Wherever the player must form a judgement, the product states the judgement first and lets the data be evidence | Simulation authority |
| D3 | **Honest uncertainty** | Unscouted values render as bands or as unknown, never as invented precision | Knowledge model |
| D4 | **Visible change** | What moved since the player last looked: per-attribute change marks, a form line threaded across five results, improvement/regression counters | Retained deltas |
| D5 | **Throughput over large N** | A 26-row squad sheet is sortable and filterable; the market is searchable; the player never reads all N to find one | Interaction primitives |
| D6 | **Simultaneity** | Several panels co-visible at once: squad beside tactics beside medical, three attribute columns side by side | **Display area** |

D1 through D5 are relationships between pieces of information and survive translation to 852 × 393
essentially intact. D6 is the desktop's area speaking, and it does not survive: it is the one
property that must be **replaced, not ported**. Its replacement is *sequenced disclosure with
preserved context* — the identity band stays put while detail levels swap beneath it; a popover
inspects without navigating away; state restoration guarantees the sequence can be left and resumed
(`04` §6.4.5 already commits to this). The exchange rate is the whole cost model: **what the desktop
buys with area, the phone pays for in taps and working memory.** Those two are therefore the budget's
currencies, alongside the pixel budget itself.

So the answer to "does the part that matters survive": yes, if the project spends engine work on D2,
D3 and D4 rather than layout work on imitating D6. A port that keeps the columns and drops the
judgement machinery would produce the number juggling `04` §1.1 already warns about — visually dense
and analytically empty, which is the prior build's UI failure with more ink.

## 2. The techniques

Each row: the mechanism as observed, what it traded away in situ, and whether it is portable to
852 × 393 at AX5 (the floor once the owner's proposed device change is assumed; at the current
844 × 390 floor every number shifts by about one percent — see the device-floor evaluation).

Capture references (`C1`–`C18`) are the census numbers in
`2026-08-12-reference-set-findings.md` §2. Provenance grade matters: techniques seen only in the
three watermarked design-file mocks are evidence of intent, not of a shipping product, and are
marked *(mock)*.

| T | Technique | Mechanism | What it traded | Portable? |
|---|---|---|---|---|
| T1 | **Verdict before evidence** | Analytics pages lead with a plain-language judgement pill plus two or three sentences naming which numbers are outliers and in which direction; the chart is demoted to evidence (C11, C18 — eight instances on one page) | Nothing visible; the trade is upstream — something must be authorised to decide the verdict | **Yes.** A verdict line plus one tap to evidence is the single cheapest density mechanism per point |
| T2 | **Banded uncertainty** | Another club's players show value as a band, ability as unknown, and a "scouting required" state (C16); confidence is a first-class column | Precision it never had | **Yes.** A band is shorter than a number and truthful |
| T3 | **Delta channels** | Per-attribute change arrows on the dossier (C12); a form line threaded across five result columns (C6, mock); improvement/regression counters on the training week (C17) | Absolute completeness — the channel shows movement, not the whole history | **Yes** at glyph scale; AX5 requires the sentence equivalent |
| T4 | **Fixed glyph vocabularies** | Squad rows carry a small learned set: condition heart, morale face, injury/wanted/tired chips (C5, C11, C16); training sessions are typed chips on a calendar (C3, C17) | Legibility to a newcomer; the vocabulary must be learned | **Bounded yes.** Portability holds only while the vocabulary stays small and each glyph changes a decision — the reference itself needed an in-game glossary (C4), which is the failure bound made visible |
| T5 | **Shared-track opposed bars** | Team-versus-team quantities on one track, value at each end (C8, mock; C11 live) | One number of resolution | **Yes** |
| T6 | **Chronology as spine** | The month is the screen when time is the task (C3); form is five columns of results; the training week is sessions-on-days (C17) | Nothing; time is the natural compression | **Yes** |
| T7 | **Context-preserving popout** | The glossary opens over the portal with live club data beside the definition (C4); player previews open without leaving the squad (C1's role list, C10's sub list) | Simultaneity's glanceability — content behind a popout is invisible until summoned | **Yes**, already canon at `04` §6.4.5. Budget: popout depth 1 |
| T8 | **Dense table with throughput controls** | 15-plus columns, sort, filter, column sets, multi-select (C5, C16) | Small-screen fit; assumes a learned 1–20 scale read at a glance | **Partially.** The relationship (one row per person, one column per decision-relevant fact, sortable) ports; the column count does not. Arithmetic below |
| T9 | **Identity band** | Person screens anchor on a stable band — name, age, role, employer, terms, ability — with tabs beneath it (C1, C12) | Vertical space (~15 % of the frame) | **Yes.** The band is what makes sequenced disclosure feel like one place |
| T10 | **Agenda as commitments with cost** | The day's obligations as checkboxes with time-to-event beside each (C7, mock) | Nothing | **Yes** |
| T11 | **Live data inside teaching** | The glossary definition sits beside the reader's own current numbers (C4) | Authoring cost | **Yes**, deferred by `01` §6.6 §3.11 to the D9 decision; unchanged |
| T12 | **Simultaneous multi-panel composition** | Three and four co-visible panels; three attribute columns side by side (C1, C2, C5, C11, C17) | — | **No.** This is D6. At 852 × 393 the honest maximum is one dominant object plus two secondary regions (`04` §4.1), which is exactly what canon already licenses |

Column arithmetic for T8, at the floor: 852 pt minus the assumed 59 pt sensor-housing inset leaves
~793 pt usable width (inset value UNVERIFIED, inherited from the superseded `04` §5.2, recoverable
at `git show a60f4d9:docs/04-UX-AND-DESIGN-SYSTEM.md`). The tree's own dense roster
(`Sources/ProFootballCoachUI/RosterView.swift`, `RosterMetric`) spends: number 28 + position 34 +
photo 52 + rating 48 + fit 52 + status 66 pt plus a flexible name column and 2–4 pt paddings, inside
a 0.64 table fraction beside an inspector. That is **six fixed facts plus identity per row** — call
the honest range six to nine columns at 10–12 pt type, against the reference's fifteen. The gap is
closed not by more columns but by **column sets** (a segmented switch swapping the fact columns while
identity columns hold) and by T1–T3 compressing several reference columns into one verdict or glyph.

## 3. Compression or judgement — what decides, per technique

The brief demands this not be assumed. If a technique reduces N data points to one statement,
something decided which statement.

| T | Reduction | What decides | Honesty condition |
|---|---|---|---|
| T1 | N metrics → one verdict + named outliers | **The engine**, against a distributional baseline (league percentile, expectation delta). A verdict is a computation, not copywriting | The engine must own baseline, sample and confidence, or the verdict is fabrication. `01` §6.5 §8 governs: the view draws only what is simulated |
| T2 | true value → band / unknown | **The knowledge model** — observer-scoped scouting state, which exists (`Sources/FootballSimCore/College/ScoutingState.swift`, `Pro/ProMarketState.swift` draft fog; FSC-007) | Band width derives from recorded observations, never from a display-side blur |
| T3 | history → marked deltas | **A retained change record** with a design-time threshold for "worth marking" | The threshold is a rules constant, not a per-screen judgement call |
| T4 | state → glyph | **Design time**: a closed vocabulary, each glyph tied to a decision it changes | The cap is enforced by review against the budget in §5; a growing vocabulary is the failure signal |
| T8 | N rows → the row you need | **The player**, via sort/filter — the machine decides nothing | Controls must operate on simulation truth, not display strings |

The dividing line: T1–T3 move judgement **into the engine**, T4 moves it into **design-time
vocabulary**, T8 leaves it **with the player**. All three destinations are legitimate; the defect the
model forbids is judgement invented **in the view at render time** — an adjective no computation
backs, which `04` §4.4 already rejects as invented authority.

## 4. What the model costs the engine

`01-RESEARCH.md` §6.5 §8: the engine decides what the view may honestly draw. The density model
leans on stated judgements, so these become engine requirements, not UI flourishes. Grounded against
the tree as it exists; each is a gap-register entry in
`2026-08-12-gap-register.md`, where bounds and save costs are stated.

| Requirement | Today, by path | Owner doc |
|---|---|---|
| Distributional baselines and verdicts (T1): league percentile per team/player metric, expectation delta, outlier naming, sample and confidence | `Sources/FootballSimCore/Competition/Statistics.swift` computes stats; `History/WorldHistoryReadModel.swift` indexes but judges nothing; no percentile/baseline machinery exists | `03` (computation), `02` (which verdicts exist) |
| Attribute-change record (T3) | `People/DevelopmentSystem.swift` produces causal development with typed events; no bounded per-player recent-change projection a dossier can read | `03b` (projection), `02` §5 |
| Per-player form series (T3) | Recorded results and per-player statistics exist (M1); no bounded last-N-games projection | `03b` |
| Opponent-preparation knowledge boundary (T2 beyond recruiting/draft) | FSC-007 names opponent knowledge as open; scouting fog exists for prospects, portal and draft only | `03` / `02` §2.1 beat 2 |
| Detailed-match per-player stat lines (evidence layer under T1 verdicts about the played match) | `docs/STATUS.md` P4: target-share bands unmeasured because the detailed engine does not produce per-player lines; the abstract model does | `03` |
| Match animation anchors (Match Day's ambient-field register) | FSC-011: match records explain outcomes but carry no top-down anchor stream; `Sources/ProFootballCoachUI/MatchDayView.swift` renders one recorded fixture frame | `03` |

A verdict the engine cannot back is fabrication; until a row above exists, the corresponding surface
ships **without** its verdict line rather than with an invented one, and says less, honestly.

## 5. The density budget

The generalisation `04` can carry, replacing per-screen improvisation. Units first — a budget in
unstated units is decoration:

- **pt** of the usable frame (852 × 393 minus safe areas at the proposed floor; 844 × 390 today);
- **taps** from the task screen to a datum;
- **items of working memory** a sequence asks the player to carry;
- **learned symbols** in the global vocabulary;
- **verdict lines** per surface.

**A management screen may spend:**

| Axis | Budget at default type | At AX5 |
|---|---|---|
| Dominant object | ≥ 60 % of the initial viewport; ≤ 2 secondary regions (`04` §4.1, restated) | The one column; ordering preserved |
| Table rows | 24–28 pt tracks (`04` §6.3); ≈ 10–12 data rows after the world strip and a 44 pt header band | Reflowed rows; no datum dropped |
| Fact columns | 6–9 beside identity at 10–12 pt; more facts arrive as **column sets**, never horizontal scroll | One fact stack per row |
| Status glyphs | ≤ 3 per row, each changing a decision | Spoken equivalents |
| Global glyph vocabulary | ≤ 12 learned symbols across the whole product | Same |
| Verdicts | ≤ 1 verdict line per readout; evidence exactly 1 tap away | Verdict precedes evidence in reading order |
| Popouts | Depth 1; a popout never opens a popout | Sheets become pushed context, still depth 1 |
| Reach | Any datum a task owns: ≤ 2 taps from that task's screen | ≤ 2 taps, longer scroll |
| Working memory | 0 — any comparison happens on one surface (a table or an explicit compare), never by remembering the previous screen | Same |
| Type | Nothing below 10 pt; working prose ≥ 12 pt (`04` §6.2) | Semantic roles scale |

**The ceiling — the surface has stopped being readable when any of these is true:**

1. A second dominant object appears (the screen is two screens).
2. The glyph vocabulary grows to accommodate it (the vocabulary is the leak detector — the
   reference needed a glossary and a bookmark manager when its vocabulary and destination count
   outgrew learning; both are captured in the corpus).
3. A verdict line has no engine computation behind it (fabrication, `04` §4.4).
4. A comparison requires cross-screen memory (working-memory budget breached).
5. Type falls below floor, or a row track falls below 24 pt, to make something fit.
6. AX5 reflow drops a datum instead of restacking it.

**Spending rule between the currencies:** pixels are spent first (denser rows, tighter tracks —
`04` §6.4 exists for this), taps second (column sets, popouts, local routes), working memory
**never**. A design that balances its pixel budget by spending working memory has failed even if
every row fits.

## 6. Throughput is part of density

Two different searches, kept apart because conflating them inverts a finding:

- **Search within data** — required. 134 programmes, ~15,766 generated players
  (`docs/STATUS.md` M1), recruiting boards, draft boards, free agency. Sort, filter, and bounded
  search over simulation objects are how a phone reaches N the desktop reaches with rows.
  `04` §8 screen 7 (World Search) is this, engine-backed by
  `Sources/FootballSimCore/History/WorldHistoryReadModel.swift` (tokenised, bounded, rebuilt after
  load). The tree's UI today has sorting only (`RosterSortDescriptor`,
  `Sources/ProFootballCoachUI/PersonnelReadModels.swift`); filter and search primitives are a gap
  (G-10).
- **Search across navigation** — forbidden as a destination. A search field over the product's own
  screens, or a user-configurable pin manager, is the information architecture failing (`01` §6.6
  §4.3; the corpus contains both symptoms as live captures). World Search indexes the *football
  world*, not the app's surfaces; the day it grows a result that is a screen name rather than a
  football object, this budget has been breached.

## 7. Proposed canon amendment — `04` §4.5 (not applied)

The density model needs a canonical home; `04` §4 (Composition rules) is where builders will look.
Proposed text, for the owner to accept, amend or reject:

> ### 4.5 The density budget
>
> Density is spent in five currencies: points, taps, working memory, learned symbols and verdict
> lines. A management screen may spend: one dominant object (≥ 60 % of the initial viewport) and at
> most two secondary regions; 24–28 pt table tracks with six to nine fact columns beside identity,
> further facts arriving as column sets rather than horizontal scroll; at most three status glyphs
> per row from a global vocabulary of at most twelve, each changing a decision; at most one verdict
> line per readout with its evidence exactly one tap away; popouts to depth one; any task-owned
> datum within two taps. Comparisons happen on one surface; a flow that requires remembering the
> previous screen is over budget regardless of fit. Pixels are spent before taps; working memory is
> never spent. Verdicts, bands and change marks are drawn only where the simulation owns the
> computation behind them: a verdict without an engine baseline, a band without a recorded
> observation, or a change mark without a retained delta is fabrication under §4.4. At AX5 the
> composition reflows to one column preserving order and dropping nothing. A screen is over budget
> when a second dominant object appears, the glyph vocabulary grows to accommodate it, type falls
> below its floor to make something fit, or AX5 loses data. The registry's per-screen budget
> statements are audited under `04b`; a surface the inventory does not price is a finding, not a
> licence.

Costs of adopting it, stated per the brief's rule that an amendment without its cost is unfinished:
it binds P11–P15 (and the M8 UI entry gate) to engine work G-03/G-04/G-05/G-06 before several
surfaces can carry their strongest form; it adds a per-screen budget statement to the `04b` audit
surface; and it makes the three-glyph and twelve-symbol caps testable claims that need an owning
contract test (register entry G-08).

## 8. What this model deliberately does not do

- It does not resolve the device floor; the budget is stated at both candidate floors and moves by
  about one percent between them (`2026-08-12-device-floor-evaluation.md`).
- It does not design screens. It prices them.
- It does not import the reference's visual expression. Every technique above is an information
  relationship; the constraint envelope in the brief and `CLAUDE.md` governs, and nothing in this
  file names a real club, player or mark.
