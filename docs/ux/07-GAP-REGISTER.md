# 07 — GAP REGISTER

**Co-primary deliverable.** Equal weight to the design specification.

Every system the design requires that does not exist in the codebase. Each gap names what it is,
which surfaces depend on it, whether it is engine-side or UI-side, and a build weight (S ≤1 day,
M ≤3 days, L ≤1 week, XL >1 week).

**Nothing in this dossier is designed around a gap silently.** Where a component cannot be built, it
is marked blocked in [`05`](05-COMPONENT-REGISTER.md) and appears here.

---

## 0. The eight classes the brief asks about — confirmed or denied

| Class | Verdict | Gap |
|---|---|---|
| Statistical accumulation layer | **Partially exists.** `Competition/Statistics.swift` and `CoachWorldStatisticsProvider` exist; per-week accumulation with retention does not | GAP-01 |
| League-relative distribution machinery | **Does not exist.** No percentile, no distribution, anywhere | GAP-02 |
| Retained history series | **Does not exist as a UI-consumable series.** `History/` exists engine-side but no stored time series is exposed | GAP-03 |
| Budget and financial state objects | **Partially exists.** Cap/contracts modelled; projections and multi-season budget state not | GAP-04 |
| Delegation policy objects and persistence | **Does not exist. Nothing.** The single largest gap | GAP-05 |
| Notification / inbox eventing | **Exists.** `InboxReadModels`, `CoachWorldInboxProvider`. Needs interrupt-threshold routing only | GAP-07 |
| Ceremony and presentation trigger system | **Does not exist.** No trigger, no queue, no once-only guarantee | GAP-08 |
| Saved-view and filter-state persistence | **Does not exist.** No filter state survives navigation | GAP-11 |

Two further classes the brief did not list but the design requires: **scouting confidence** (GAP-06)
and **staff trust / approval** (GAP-09).

---

## GAP-01 — Per-week statistical accumulation with retention · ENGINE · **L**

Statistics are computed; they are not accumulated into a per-week series that survives the season.
Without it there is no "this week vs last week", no form, and no trend anywhere in the product.

**Depends:** 48 Statistics & Leaders, 18 Player Profile, 42 Team Profile, 47 Box Score, 8 Coaching HQ.
**Blocks:** `CoachWorldDeltaMark` on any statistic (the component exists; the data does not).
**Bounded:** yes — must state a retention bound per `CLAUDE.md`. Prior build reached 8.3 MB saves on
unbounded collections; the D7 falsifier is already breached ~3× by season 20 on an unbounded
digest-archive array. **Do not add an unbounded series.** Proposal: rolling 17 weeks at full
resolution, season aggregates thereafter.

---

## GAP-02 — League-relative distribution machinery · ENGINE · **M**

Nothing knows what the league looks like. Every "good"/"average" judgement in the design is
currently unsupported.

**Two candidate designs, and the research picks the cheap one.** FM26 computes a verdict and plots
the league population as a scatter (A) — expensive, needs a live distribution at render time.
The Show **prints a five-band legend on the surface** (A) — needs only fixed thresholds.

**Adopt The Show's model.** Fixed bands (`06` §2.6) plus a per-season recomputed band table, not a
live percentile.
**Depends:** `BandLegend`, `RangedRating`, 48 Statistics, 25 Prospect Profile, 18 Player Profile,
24 Recruiting Board.
**Note:** without this, `06` §2.6's five-band scheme is decoration, because nothing validates that
70–79 really is average in a generated world.

---

## GAP-03 — Retained history series · ENGINE · **M**

No stored time series exists that a UI can read. Every trend line, sparkline and progression curve
in the component register is currently unbuildable.

**Depends:** 59 Career Line, 57 Record Book, 18 Player Profile, 42 Team Profile, and every
`CoachWorldDeltaMark` use.
**Bounded:** yes, and this is where the save-size risk concentrates. See GAP-01's bound.

---

## GAP-04 — Budget and multi-season financial state · ENGINE · **M**

Cap and contracts exist. Projections do not. FM26 shows end-of-season-plus-one and plus-two balance,
turnover and transfer budget with direction arrows (A); this product cannot.

**Depends:** 34 Cap & Contracts, 35 Contract Negotiation, 33 NIL Allocation, 62 Pro Offseason.
**Note:** `CoachWorldMeter`'s **over** state (the FM26 wage-bar overrun) is already built and has
nothing to overrun against.

---

## GAP-05 — Delegation policy objects and persistence · ENGINE + UI · **XL**

**The largest gap in the product, and the one the entire session-intent model rests on.**

Nothing exists. There is no delegation area enum, no policy object, no assignment of an area to a
staff member, no persistence of any of it, and no surface to configure it.

**Required, from the reference implementation (`02` §6, Grade B):**
- a `DelegationArea` enum, exhaustive, so a new area cannot ship unassigned;
- per-area assignment to a **named** person, never to "auto";
- a **temporary override layer** over the standing matrix (OOTP Vacation Settings);
- **six interrupt triggers with two configurable thresholds** (`04` §5);
- persistence in the save, with migration;
- **a guarantee that no area resolves to nobody** — the trap OOTP's own docs volunteer, where
  "unchanged" silently means "uncovered".

**Depends:** the new `Responsibilities` surface, `DelegateAssignmentCard`, `AgendaRow.delegated`,
`FloodlitStaffVoice`, invariant L-2 and L-3, and **all four session intents**.
**Without it there is no fast path at all**, only a manual game with an advance button.

---

## GAP-06 — Scouting confidence model · ENGINE · **L**

Ratings are point values. The design calls for ranges that narrow with observation.

**Depends:** `RangedRating`, `CoachWorldConfidenceTag` (built, currently unfed), 25 Prospect Profile,
24 Recruiting Board, 37 Pro Scouting.
**Precedent (A):** The Show's `68-86 Potential`, `PRESENT 43-61 → FUTURE 60-78`, with a scouting
progress bar directly above so the player sees why the numbers are vague.
**Note:** `CoachWorldConfidenceTag` already models `.observations(Int)`. The component anticipated
this system; the system was never built.

---

## GAP-07 — Interrupt-threshold routing · ENGINE · **S**

The inbox exists and works. What is missing is the *threshold* layer that decides which engine events
become interrupts, per the six triggers in `04` §5.

**Depends:** TRIAGE intent, invariant L-4.
**Small** because the eventing substrate is already there — this is routing and configuration, not
new infrastructure. Depends on GAP-05 for where the thresholds are stored.

---

## GAP-08 — Ceremony trigger system · ENGINE + UI · **M**

No mechanism decides that a moment deserves ceremony, queues it, guarantees it fires once, or
guarantees it does **not** fire on a routine week.

**Required:** a closed trigger enum matching the five sanctioned moments (`04` §6); a once-only
guarantee across save/reload; a **hard assertion that zero dedicated ceremony fires on a
non-qualifying week** — the countable half of `00` §6.3, and the half that keeps the fast path
honest.
**Depends:** all five ceremony surfaces, `CeremonyPlate`, `00` §6.

---

## GAP-09 — Staff trust and constituency approval · ENGINE · **L**

`FloodlitStaffVoice` exists and renders a suggestion. **Declining it costs nothing**, so the
delegation contract is currently decorative.

**Precedent (B), and the most transferable mechanic in the dossier:** EA's coordinators —
*"If you dismiss their input or make poor choices, their trust in your leadership may decline"* —
plus an Approval Rating across **GM, coaching staff, players, fans and media**, moving weekly,
judged at season end, persisting across seasons, and capable of ending the job.

**Two qualifications carried from the research:** coordinator trust is documented only
*qualitatively*, so a numeric meter is an invention, not a copy; and whether the cost is previewed
before dismissal is **unestablished** — do not specify a preview (see D-006).

**Depends:** `FloodlitStaffVoice` extended, `DecisionCard` decline path, 54 Stakeholders (currently
60 lines and the natural home for a five-constituency readout), 53 Job Security.

---

## GAP-10 — Championship result surface · UI · **S**

The fifth sanctioned ceremony has **no registry entry**. `CoachWorldScreenID` has no case for it.

**Depends:** `04` §6, GAP-08.
**Note:** adding a case forces a family assignment at compile time — the registry's coverage-by-
construction property working as designed.

---

## GAP-11 — Saved views and filter-state persistence · UI · **M**

No filter, sort, scroll position or column set survives navigation. This directly violates
[`03`](03-SESSION-INTENT-MODEL.md) invariant **T-2** and
[`04`](04-INFORMATION-ARCHITECTURE.md) §8.

**This is the gap most likely to sink the product's reception, on the strongest reception evidence
available.** FM26 went to ~81% negative on Steam with community reports that routine tasks roughly
doubled in click cost (C). Losing a filter on every round trip is exactly that tax.

**Required:** per-surface view state (scroll, sort, filter, column set, expansion), retained for the
session at minimum, persisted across launches ideally; plus named saved views on 16 Roster and
24 Recruiting Board.
**Depends:** `ColumnSetControl`, `DenseTable`, T-2, and every deep-dive exit in `04` §8.

---

## GAP-12 — `ScreenReadModels.swift` split · UI · **S**

Not a missing system; a structural risk. 2302 lines, the largest file in the module, sitting on the
engine/UI boundary. Violates `CLAUDE.md`'s "files small and focused". Mechanical, low-risk, split per
family.

---

## Summary

| Gap | Side | Weight | Blocks |
|---|---|---|---|
| GAP-05 delegation policy | engine+UI | **XL** | **the entire fast path** |
| GAP-01 statistical accumulation | engine | L | all trends |
| GAP-03 retained history | engine | M | all series |
| GAP-06 scouting confidence | engine | L | the uncertainty design |
| GAP-09 staff trust / approval | engine | L | the delegation contract |
| GAP-02 league distribution | engine | M | all relative judgement |
| GAP-04 financial projections | engine | M | pro management depth |
| GAP-08 ceremony triggers | engine+UI | M | all five ceremony surfaces |
| GAP-11 saved views | UI | M | **T-2, and the FM26 failure mode** |
| GAP-07 interrupt routing | engine | S | TRIAGE |
| GAP-10 championship surface | UI | S | ceremony #5 |
| GAP-12 read-model split | UI | S | nothing; hygiene |

**Engine-side work dominates: 7 of 12 gaps are engine, including the XL.** The honest reading is
that this is not primarily a UI project. The component vocabulary is largely built
([`01`](01-REPO-UI-INVENTORY.md) §3.3); what is missing is the **data and policy layer beneath it**.
Any plan that sequences UI work first will stall at GAP-05.
