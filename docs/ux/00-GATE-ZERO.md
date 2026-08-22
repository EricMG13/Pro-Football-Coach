# 00 — GATE ZERO

Status: **PARTIALLY CLOSED.** Two of the three limbs close arithmetically. One does not, and this
document states exactly what would close it rather than inventing a number.

Evidence grades used throughout: **A** first-hand observation of the artefact; **B**
developer-authored material; **C** structured community evidence; **D** inference from A/B/C with
premises stated. Ungraded assertions are defects.

---

## 0. Summary of rulings

| # | Question | Ruling |
|---|---|---|
| G0-1 | Fast-path interaction budget per week | **UNCLOSED.** No admissible session-length evidence exists. See §1.3 for what would close it and §1.4 for the substitute constraint adopted in its place |
| G0-2 | Deep-path decision count per week | **CLOSED: 50 decision points per in-game week**, 11 classes. §2 |
| G0-3 | The ratio | **Cannot be stated as fast÷deep.** Replaced by a derived *density* ratio of **5.0:1**, §4, which constrains the same design question on admissible evidence |
| G0-4 | Two personas or one oscillating user | **RESOLVED IN FAVOUR OF OSCILLATION**, on architectural evidence only, confidence low-medium. §5 |
| G0-5 | Ceremony budget | **CLOSED AS A RULE**, §6 |

---

## 1. The interaction-budget problem

### 1.1 What was sought

A defensible number for how many discrete interactions a delegating player tolerates per in-game
week, anchored on empirical mobile session-length data for mid-core management titles on iOS.

### 1.2 Why it could not be established

Two independent research passes attempted this. Every quantitative session-length figure obtained
failed adversarial verification. Specifically refuted, and **not to be reintroduced**:

- median mobile session 3.1–3.5 min (0-3); 5–6 min 2024 median (0-3)
- top 1% >22 min per session (0-3)
- 3.8–3.9 sessions/day (1-2); mid-core 6–7 sessions/day (0-3)
- ~12 min median daily playtime (0-3); ~22 min median daily playtime (0-3)
- mid-core 10–15 min per session (0-3)

The blocking fact is first-party and verified (**Grade B**): the 2026 GameAnalytics benchmark report
states *"Due to ongoing improvements to game genre categorization, genre-level benchmarks are
unavailable in this report"* and *"This data combines insights from iOS and Android, across all
genres and regions, for a full overview."* The primary benchmark source therefore does not segment
by genre or by platform, which are the two axes this project needs.

**Ruling: any "N interactions per session" figure appearing anywhere downstream of this document is
Grade D inference and must be labelled as such at the point of use.** Confident thin evidence is the
most expensive kind; an honest gap is cheaper than a fabricated constant that propagates into the
density model.

### 1.3 What would close G0-1

In descending order of value:

1. **The 2025 GameAnalytics benchmark edition**, which does segment by 16 genres. Its figures were
   cited and refuted here *as cited*; the PDF itself was never verified directly. Re-verify against
   the primary document, not a mirror.
2. **First-party telemetry from a shipped TestFlight build of this app.** This is the only source
   that would ever be Grade A for *this* product, and it is obtainable: instrument
   interactions-per-week and session length in the TestFlight phase, then set the budget from
   measurement. Everything before that is borrowed.
3. A published usability study of mobile management-sim sessions. None was found.

Until (1) or (2) lands, G0-1 stays open and is recorded as an open question in
[`08-DECISION-REGISTER.md`](08-DECISION-REGISTER.md) under **D-001**.

### 1.4 The substitute constraint

An unclosed budget limb must not block the deliverable, so a second constraint was derived that
answers the same design question — *how much can one surface carry* — from evidence that is
admissible. That is the density ratio in §4. It constrains layout directly, where the interaction
budget would only have constrained it by inference.

---

## 2. The deep-path decision count — CLOSED

### 2.1 Method

Count the decision points a Football-Manager-grade depth model surfaces in one in-game week, by
class, from observation of FM26 and from SI-authored material. A "decision point" is one choice the
player can independently make and that the simulation reads. A dropdown with 26 options is one
decision point, not 26.

### 2.2 The count

| # | Class | Points/week | Grade | Basis |
|---|---|---:|---|---|
| 1 | Training session slots | **21** | **A** | FM26 Training screen: a Mon–Sun grid, three stacked slot chips per day. 7 × 3 = 21. Observed directly |
| 2 | Training intensity | 5 | A | Five-step heart scale, x0 / x0.5 / x1 / x1 / x1, per unit |
| 3 | Individual training focus | 3 | A | Player Report role selector, one per player under individual focus; counted as 3 typical actives, not per-squad |
| 4 | Tactic: formation, style, mentality | 3 | A | Tactics Planner header: formation preset, Style (Gegenpress), Mentality (Positive) |
| 5 | In/out-of-possession instructions | 2 | A | Two Instructions buttons, one per phase |
| 6 | Set-piece routines | 4 | A | Set Pieces screen: type × scenario (Att/Def corners, Att/Def free kicks) as the routine-authoring unit |
| 7 | Match squad and subs | 2 | A | Match Squad plus a 15-slot subs bench |
| 8 | In-match interventions | 3 | A | Dugout suggestion accept/ignore, plus mentality and substitution during play |
| 9 | Medical / injury responses | 2 | A | Medical Centre panel: "6 players injured", "3 players at risk of injury" |
| 10 | Transfers, contracts, scouting actions | 4 | D | Shortlists, Transfer Activity, Recruitment Focuses, Contracts are separate destinations; four is a conservative per-week floor, not an observed count |
| 11 | Board / institutional requests | 1 | B | SI documents one High Priority club request per season in a Club Vision tab; amortised to ≤1/week |
| | **Total** | **50** | | |

**50 decision points per in-game week.** Classes 1–9 are Grade A. Class 10 is the weakest link and
is deliberately conservative; class 11 is Grade B.

### 2.3 Sensitivity

Excluding the Grade-D class 10 gives **46**. Counting only Grade-A classes gives **45**. The count
is robust to its weakest evidence: the conclusion "the deep path is 45-50, not single digits and not
hundreds" holds at every grading threshold.

### 2.4 A correction carried forward

An earlier verification pass refuted the 21-slot training week 0-3. That refutation was correct that
the cited FM24 manual page did not support the claim, and **wrong on the substance**: the FM26
Training screen shows the 7 × 3 grid directly. Re-graded **A**. This matters because training alone
is 42% of the total count.

---

## 3. The stated ratio, and why it is not the useful one

Fast-path budget ÷ deep-path count cannot be computed, because the numerator is unavailable (§1).

It is worth being explicit about what this does *not* license. It does not license picking a
plausible numerator. If the fast path were, say, 5 interactions per week, the ratio would be
5 ÷ 50 = **1:10** — an order of magnitude, which under the brief's own rule would make delegation
the primary architecture. But that "if" is doing all the work, and the brief's §4 forbids exactly
this move.

**What survives without the numerator:** the deep path is 50. Any fast path worth the name is
single-digit. The gap is therefore *at least* several-fold on any assumption anyone would defend,
and the delegation architecture is load-bearing rather than a convenience. That conclusion is
Grade D, its premise is stated, and it is the weakest form of the claim that still supports the
design — which is the right form to adopt.

---

## 4. The density ratio — the substitute constraint, CLOSED

Both sides of this are measured, so it is admissible where §3 is not.

### 4.1 The benchmark side (Grade A)

FM26's squad list is the densest routinely-used screen observed. Directly counted from the
artefact: **15 columns** (select, depth slot, status flags, player, position, best position,
transfer value, best role, age, ability, potential, playing time, nation, wage, contract expiry) ×
**~24 visible rows** = **~360 populated cells in one viewport.**

*Limit on this figure:* the capture is 2130 × 1036 px with an unrecorded scale factor, so its
physical size is unknown. The **cell count is therefore the transferable measure, not the pixel
density** — column and row counts are scale-invariant.

### 4.2 The floor side (Grade A, from the repo's own constants)

At the 844 × 390 install floor, using values already committed in
[`DesignTokens.swift`](../../Sources/ProFootballCoachUI/DesignTokens.swift):

```
content width  = Frame.floorWidth - Stage.contentLeading - Frame.gutter
               = 844 - 115 - 20      = 709 pt
content height = Frame.floorHeight - Stage.contentTop - Frame.bottomInset
               = 390 - 46  - 25      = 319 pt
```

Row capacity, from `FloodlitPatterns`' own committed rule — *"32 when it is a dense readout, 44 the
moment it can be tapped: a row that responds to touch is a control and takes a control's floor"*:

```
non-interactive rows = floor(319 / 32) = 9 rows
interactive rows     = floor(319 / 44) = 7 rows
```

Column capacity across 709 pt: one name column at ~140 pt plus numeric/chip columns at ~48 pt
(a two-to-four-character tabular figure plus `Gap.xs` either side) gives
`(709 − 140) / 48 ≈ 11`, i.e. **~12 columns** as an upper bound before any column loses its label.
Applying the same headroom discipline the benchmark uses (it spends ~30% of width on the name and
position chips) yields a working figure of **8 columns**.

```
floor capacity ≈ 9 rows × 8 columns = 72 cells per viewport
```

### 4.3 The ratio

```
360 benchmark cells ÷ 72 floor cells = 5.0 : 1
```

**A Football Manager screen carries five times what the install floor can carry.**

### 4.4 What follows, as rules

- **R-D1.** No surface may present a benchmark-density table verbatim. A 15-column table becomes at
  most 8 columns, or becomes a two-line row, or becomes a player-selected column set. There is no
  fourth option and no exemption.
- **R-D2.** Any surface exceeding **72 cells** in one viewport at the floor is over budget by
  construction and must be split, paginated, or given a column-set control. This is a testable
  number, and [`06-TOKENS-AND-DENSITY.md`](06-TOKENS-AND-DENSITY.md) §3 binds it to a test.
- **R-D3.** The 32/44 pt split is not advisory. A row that can be tapped costs 44 pt and therefore
  costs density. **Interactivity is purchased with rows**, and the purchase must be deliberate:
  going from 9 readout rows to 7 tappable rows is a 22% density loss.

---

## 5. Personas or one oscillating user — RESOLVED, LOW CONFIDENCE

### 5.1 The evidence position, stated honestly

No direct evidence was obtained. Sought and not found: telemetry statements from Sports Interactive,
Out of the Park Developments or EA; any published survey of management-game players; any
characterised community thread on instant-result usage; FM holiday-usage data; Madden super-sim
usage data. Two claims that would have demonstrated within-player oscillation were **refuted 0-3**,
including the claim that OOTP play-by-play users are forced into auto-play for the remaining
schedule.

**The brief's §10 dimension 6 asks for the two-persona model to be confirmed with evidence or
replaced with a better one. It is replaced, but on architectural evidence, not behavioural.**

### 5.2 The architectural argument (Grade D, premises stated)

*Premise 1 (Grade B).* OOTP models delegation as **11 independently assignable responsibility
areas**, each choosing between the human and a named staff member — not a global toggle. Stable
from OOTP 18 (2017) through the current wiki.

*Premise 2 (Grade B).* OOTP ships a **second, temporary** delegation layer ("Vacation Settings") —
a parallel column of per-area dropdowns with explicit inheritance from the standing matrix.

*Premise 3 (Grade B).* OOTP's auto-play **halts on user-configured conditions** — injury severity
above a chosen threshold, day-to-day injury above a chosen performance-drop percentage, DL
eligibility, messages, incoming trades — with the developer's stated rationale being to give the
manager *"a chance to shift your depth charts and lineups around, sign a free agent replacement, or
work a trade."*

*Inferential leap, marked:* a design that ships a per-area matrix, a separate temporary override,
and threshold-configurable handback is a design built for a user who **changes their level of
involvement repeatedly within one save**. Persona segmentation would be served by a single
difficulty-style switch chosen once. Three orthogonal mechanisms, refined across a decade of
releases, are evidence that the developer models oscillation — but they are evidence about the
*designer's* model, not about observed player behaviour.

### 5.3 Ruling

**Adopt a session-intent model, not a user-type model.** Downstream artefacts are written on that
basis; see [`03-SESSION-INTENT-MODEL.md`](03-SESSION-INTENT-MODEL.md).

**The design consequence is transition cost, not segmentation.** The measurable target: dropping
from cruise into one decision and climbing back out must cost ≤ 2 interactions each way and must
not lose scroll position or filter state.

**Confidence: low-medium. This is the weakest load-bearing ruling in the dossier.** It would be
falsified by evidence that players choose an involvement level once per save and keep it. Instrument
this in TestFlight: log every transition between delegated and manual control per save, and the
trigger. See **D-002**.

### 5.4 One inherited trap, worth more than the ruling

OOTP's own documentation volunteers a failure: leaving an area on "Use Current Settings" while *you*
personally own it means **nobody covers it** in your absence — *"no changes will be made... other
than the minimum required to keep the team running."* The inheriting default is a hazard, not a safe
default. Any cruise or away mode in this product must resolve every area to a named owner and must
never let "unchanged" mean "unowned". See **D-008**.

---

## 6. The pageantry/throughput conflict — CLOSED AS A RULE

### 6.1 The arithmetic

With G0-1 open, ceremony cannot be budgeted in seconds against a session length. It can be budgeted
in **interactions**, which is admissible.

A 17-game regular season plus a 4-round playoff run is **21 match weeks**. If ceremony costs even
one dismissal interaction per week, that is 21 interactions spent on nothing but acknowledgement —
against a fast path that must also carry the week advance itself. **Ceremony that costs an
interaction per week is unaffordable at any plausible budget.** This conclusion is robust precisely
because it does not depend on the unknown numerator: it fails at 5 interactions/week and at 50.

### 6.2 The evidence that resolves it (Grade A)

Three shipped patterns show ceremony delivered at **zero interaction cost**:

- **The persistent news ticker.** Present in every Madden generation observed, 2012-era through
  2018-era, and stated by EA for Madden 27 (*"A persistent news ticker now runs across every
  screen"*, Grade B). Ambient, unskippable-because-uninterrupting, costs nothing.
- **Ceremony as a destination, not an interruption.** Madden's League News is a *place you go*:
  a result card plus attributed pundit commentary. Skippable by construction, because you skip it by
  not visiting. (The mechanic transfers; the real named broadcasters absolutely do not — see the
  legal guardrail in `CLAUDE.md`.)
- **Ceremony inside the match frame.** FM23 Mobile fires a full broadcast lower-third — portrait,
  name, "Goal", club, descriptor — over the 2D pitch in landscape, without leaving the match view or
  requiring a dismissal.

### 6.3 The rule

> **R-C1. Ceremony is ambient by default, asymmetric by exception, and never modal on the fast
> path.**
>
> 1. **Default (every week):** ceremony renders *within* a surface the player is already on — ticker,
>    feed entry, lower-third over the match. **Zero interactions. Zero dismissals.** A Week 4 road
>    game gets no interruption whatsoever.
> 2. **Exception (bounded set):** a **named, closed list** of five moments per season may take a
>    dedicated surface — championship result, promotion decision, signing day, awards, career
>    milestone. Each costs at most **one** interaction to leave, and each is reachable again
>    afterwards from a destination, so leaving is never loss.
> 3. **Cap:** ≤ 5 dedicated ceremony surfaces per season, ≥ 0 on any non-playoff week. Enumerated in
>    [`04-INFORMATION-ARCHITECTURE.md`](04-INFORMATION-ARCHITECTURE.md) §6; adding a sixth is a
>    decision-register amendment, not an implementation choice.
> 4. **Never:** an unskippable animation, a modal on a routine week advance, or a ceremony that
>    blocks the advance loop.

This is a rule, not a preference, and it is enforceable: the cap is countable and the "zero
dismissals on a routine week" clause is testable.

---

## 7. What this gate hands downstream

| Constant | Value | Grade | Consumers |
|---|---|---|---|
| Deep-path decision count | 50/week, 11 classes | A (9 classes) | `03`, `04`, `07` |
| Density budget at the floor | 72 cells/viewport | A | `06` §3, and its test |
| Benchmark:floor density ratio | 5.0 : 1 | A | `05`, `06` |
| Row heights | 32 pt readout / 44 pt interactive | A | `06`, every table |
| Content box at the floor | 709 × 319 pt | A | every screen proposal |
| Ceremony cap | ≤5 dedicated surfaces/season, 0 dismissals on a routine week | A/D | `04` §6 |
| Transition-cost target | ≤2 interactions each way, no state loss | D | `03`, `04` |
| Fast-path interaction budget | **UNKNOWN — do not invent** | — | blocked; see D-001 |
