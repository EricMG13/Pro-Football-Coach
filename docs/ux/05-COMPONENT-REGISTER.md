# 05 — COMPONENT REGISTER

Ordered by dependency: **tokens → primitives → composites → patterns → screens.** A component may
not depend on anything below it in that order. Register is `CoachWorldRegister { desk, broadcast }`,
which already exists in
[`CoachWorldDeskComponents.swift`](../../Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift)
— *"DESK gets the full committed backdrop (gradient, glow, grain). BROADCAST is flat `page.color`
only."*

Status: **EXISTS** (keep as is) · **EXTEND** (exists, needs a stated addition) · **NEW** (build).
Every entry names its benchmark precedent and that precedent's evidence grade. Entries marked
**no precedent** are honest inventions and say so.

---

## Layer 0 — Tokens

Specified in [`06`](06-TOKENS-AND-DENSITY.md). Every component below consumes them; none redefines
them. A design-token literal in a view is a defect (`CLAUDE.md`).

---

## Layer 1 — Primitives

| Component | Register | Status | States | Precedent |
|---|---|---|---|---|
| `FloodlitLabel3` | both | EXISTS | — | FM26 micro-labels (A) |
| `FloodlitPill` | both | EXISTS | default/selected | FM26 status pills (A) |
| `FloodlitFlag` | both | EXISTS | — | FM26 `Inj`/`Tir`/`Wnt` (A) |
| `CoachWorldStatusChip` | both | EXISTS | tone × symbol | FM26 chips (A) |
| `CoachWorldDeltaMark` | both | EXISTS | up/down/flat | FM26 attribute trend chevron (A) |
| `CoachWorldRatingRing` | both | EXISTS | 26–118 pt, proportional stroke | The Show interest donut (A) |
| `CoachWorldMeter` | desk | EXISTS | empty/partial/full/**over** | FM26 wage bar overrunning red at 101.8% (A) |
| `CoachWorldOpposedBar` | both | EXISTS | balanced/skewed | FM26 match stats (A) |
| `CoachWorldConfidenceTag` | both | EXISTS | `.banded` / `.unknown` / `.observations(n)` | The Show prints "Unknown" as a value (A) |
| `CoachWorldCutCorner` | desk | EXISTS | — | house |
| `FloodlitRow` | both | EXISTS | 32 pt readout / 44 pt interactive | FM26 squad rows (A) |
| `FloodlitCard` | both | EXISTS | — | FM26 Cards (B) |
| **`LeaderMark`** | both | **NEW** | leads/trails/tied | **Madden amber leader triangle (A)** |
| **`RangedRating`** | both | **NEW** | known / ranged / unknown | **The Show `68-86 Potential` (A)** |
| **`BandLegend`** | both | **NEW** | — | **The Show printed scouting scale (A)** |

### `LeaderMark`
A small triangle placed on the leading side of a comparison row, pointing at it. **Encodes by
position and direction, not hue**, so it survives greyscale and colour-blindness with no extra work.
Observed in Madden's Game Stats and Team Stats (A). Adopting it discharges part of the §6
colour-independence obligation for free.

### `RangedRating`
Renders a rating as a point (`84`), a **range** (`68-86`), or `Unknown`. Range width *is* the
confidence interval; it narrows as observation accumulates. Pairs with `CoachWorldConfidenceTag`,
which already models `.observations(n)`.

> **This component cannot be built without [`07`](07-GAP-REGISTER.md) GAP-06** — the engine has no
> scouting-confidence model, so there is no range to render. Named, not designed around.

### `BandLegend`
Prints the league-relative bands on the surface that uses them — The Show's
`Well Below Avg 0-64 | Below Avg 65-74 | Average 75-79 | Above Avg 80-84 | Well Above Avg 85-99`
(A). **This is the cheap answer to the distribution problem**: it removes any need to compute a live
percentile at render time. Bands come from `CoachWorldTokens.Heat`, extended from three to five
(`06` §2.6).

---

## Layer 2 — Composites

| Component | Register | Status | States | Precedent |
|---|---|---|---|---|
| `FloodlitArcGauge` | both | EXISTS | — | FM26 gauges (A) |
| `FloodlitAttributeDial` | both | EXISTS | — | FM26 radar (A) |
| `FloodlitShareBar` | desk | EXISTS | — | FM26 sponsorship stacked bar (A) |
| `FloodlitCostLine` | desk | EXISTS | — | Madden `SUGGESTED TRADE OFFER` (A) |
| `FloodlitCommittingAction` | desk | EXISTS | enabled/disabled/pressed | Madden `TRADE FOR PLAYER` (A) |
| `CoachWorldSystemState` | desk | EXISTS | empty/loading/error | house |
| `CoachWorldIdentityBand` | both | EXISTS | — | FM26 header (A) |
| `CoachWorldAgendaRow` | desk | **EXTEND** | pending / complete / **delegated** | **FM25 Portal Agenda (A, unshipped)** |
| `FloodlitStaffVoice` | desk | **EXTEND** | — | **FM25 Dugout (A, unshipped)** |
| **`CapabilityList`** | desk | **NEW** | tick / cross | **Madden career-setup cards (A)** |
| **`ColumnSetControl`** | desk | **NEW** | — | FM26 Filter + The Show tabs (A); **composition is house** |

### `CoachWorldAgendaRow` — EXTEND
Already carries `title`, `timing`, `cost`, and `state ∈ {pending, complete, delegated}` — the FM25
Portal Agenda (*"Attend Press Conference 1h / Confirm match squad 7h / Attend match 8h"*) **plus a
delegated state FM25 does not have.** The repository is ahead of the benchmark here.

**Extension required:** the `delegated` state must name the delegate and be tappable through to
their report. Invariant L-3 in [`04`](04-INFORMATION-ARCHITECTURE.md): silent delegation is
indistinguishable from a bug.

**Caveat carried:** FM25 was cancelled. This pattern has **no reception evidence whatsoever**.

### `FloodlitStaffVoice` — EXTEND
The shipped analogue of FM25's Dugout (*"I think we should replace Stones with Akanji."* →
**"Do it"** / **"Ignore ⌄"**). The component exists; the **decision contract** does not.

**Extension required:** a primary accept, a secondary decline, and the decline's cost stated on the
control. Depends on [`07`](07-GAP-REGISTER.md) GAP-09 (staff trust). Until that lands, the decline
is free and the component is decorative.

### `ColumnSetControl` — NEW
Lets the player choose which columns a dense table shows, from named presets. **This is the direct
mitigation for the 5:1 density ratio** (`00` §4) and the only alternative to silently truncating a
15-column benchmark table to 8.

Honest note on precedent: FM26 has a `Filter` control and The Show has `Scouting | Positional Needs`
tabs (both A), but **neither was observed doing column-set selection**. The composition is a house
invention justified by arithmetic, not copied. Marked accordingly.

---

## Layer 3 — Patterns

| Pattern | Register | Status | Precedent |
|---|---|---|---|
| `CoachWorldFloodlitStage` | both | EXISTS | house composition root |
| `FloodlitChrome` (header, rail, backdrop) | desk | EXISTS | FM26 top bar + siblings (A) |
| `FloodlitRegisteredNotBuilt` | desk | EXISTS | house |
| `FloodlitFooterStrip` | desk | EXISTS | house |
| **`DecisionCard`** | desk | **NEW** | **Madden "BIG DECISION" (A)** |
| **`DelegateAssignmentCard`** | desk | **NEW** | **The Show scouting big board (A)** |
| **`NewsTicker`** | both | **NEW** | **Madden, every generation 2012→ (A); EA states it for M27 (B)** |
| **`CeremonyPlate`** | broadcast | **NEW** | **FM23 Mobile goal lower-third (A)** |
| **`DenseTable`** | desk | **NEW** | FM26 squad list (A), **budget-bound per `00` §4** |

### `DecisionCard` — the most important new pattern
Madden's "BIG DECISION" is the clearest single-frame answer to the decision-framing axis in the whole
research (A). Required parts, each observed:

1. **The problem**, in a sentence.
2. **The context that makes it judgeable** — your own current state at that position, carrying an
   aggregate grade. Madden shows the depth chart with a `B-`.
3. **Options as cards**, each with an identity badge, 3 relevant attributes as number-over-bar, and
   an archetype word.
4. **The price**, named — Madden's `SUGGESTED TRADE OFFER` names the asset given up.
5. **An explicit decline** — `NOT INTERESTED`, a real control, not a back gesture.
6. **A non-committing route to detail** — `PLAYER CARD`.

**States:** populated · disabled (cannot afford) · deferred · resolved · declined.

> **What this pattern must NOT claim.** Consequence *preview* — showing the marginal effect of the
> choice — was **refuted 0-3** in Madden 26 and again for Madden 27's delegation flow. There is no
> benchmark precedent for previewing an outcome. `DecisionCard` shows **the price**, which is
> observed, and must not be specified as showing **the result**, which is not. See
> [`08`](08-DECISION-REGISTER.md) **D-006**.

### `DelegateAssignmentCard`
From The Show's scouting big board (A): a coloured header **stating the delegate's numeric yield**
(`+2% INTEREST PER WEEK | +40% SCOUTING PER WEEK`), the assignment scope, and a footer **naming the
individual** (`SCOUT: WILLIAM WOMACK`). Three granularities on one screen.

> **This is the answer to "how is the player made to trust the delegate": print the rate of return
> where the assignment is made, and name the person rather than saying "auto".**

Used on the `Responsibilities` surface (`04` §5). Depends on GAP-05.

### `NewsTicker`
Ambient, non-interactive by default, rendered by `FloodlitChrome` so every DESK surface gets it by
construction. **This is the mechanism that makes the ceremony rule affordable** (`00` §6): the
zero-interaction default channel. Must respect Reduce Motion by becoming a static rotating item.

### `CeremonyPlate`
BROADCAST register. From FM23 Mobile's goal lower-third (A): angled plate, portrait, large name,
event label, secondary identity line — rendered **over** the current surface in landscape, **without
leaving it and without requiring a dismissal**. Used for in-match moments; the five dedicated
ceremony surfaces are screens, not plates.

### `DenseTable`
The single most constrained component in the system. **Hard budget: ≤72 cells per viewport at the
844×390 floor** (`00` §4.2). Composes `FloodlitRow` (32 pt readout / 44 pt interactive),
`ColumnSetControl`, `LeaderMark`, `RangedRating` and `BandLegend`.

**Must implement, from FM26's legibility technique (A):** positional grouping via a colour-filled
chip in the leading column; status flags in their own narrow column, never inline; monochrome type
with colour reserved for meaning; the name in a bordered pill so the tap target is visible.

**Must not implement:** 15 columns. See `00` §4.4 R-D1.

---

## Layer 4 — Screens

Screens are the 47 canonical `CoachWorldScreenID` cases. They compose patterns and introduce no new
vocabulary. Dispositions are in [`01`](01-REPO-UI-INVENTORY.md) §2. The four REBUILD screens are the
five ceremony surfaces in [`04`](04-INFORMATION-ARCHITECTURE.md) §6, minus the championship result,
which has no registry entry.

---

## Dependency check

```
tokens
  └── primitives ......... Label3 Pill Flag StatusChip DeltaMark RatingRing Meter
                           OpposedBar ConfidenceTag CutCorner Row Card
                           LeaderMark* RangedRating* BandLegend*
        └── composites ... ArcGauge AttributeDial ShareBar CostLine CommittingAction
                           SystemState IdentityBand AgendaRow† StaffVoice†
                           CapabilityList* ColumnSetControl*
              └── patterns ... FloodlitStage FloodlitChrome RegisteredNotBuilt FooterStrip
                               DecisionCard* DelegateAssignmentCard* NewsTicker*
                               CeremonyPlate* DenseTable*
                    └── screens ... 47 canonical surfaces
```
`*` NEW · `†` EXTEND. **No upward dependency exists.** `DecisionCard` depends only on composites and
primitives; `DenseTable` depends only on primitives and `ColumnSetControl`.

---

## Blocked components

Three cannot be completed as specified until engine work lands. They are named here rather than
designed around, per brief §6:

| Component | Blocked by | Without it |
|---|---|---|
| `RangedRating` | GAP-06 scouting confidence | Renders point ratings only; the uncertainty design is inert |
| `FloodlitStaffVoice` (extended) | GAP-09 staff trust | Declining is free; the delegation contract is decorative |
| `DelegateAssignmentCard` | GAP-05 delegation policy | No policy object to configure, no rate to print |
