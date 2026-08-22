# 09 — BUILD PROMPT

**Self-contained.** An agent reading only this file plus the repository can work without asking
questions. Read `CLAUDE.md` first — it is binding and overrides anything here that conflicts.

---

## Mission

Construct the design system specified in `docs/ux/`, in dependency order, without re-litigating
design decisions. Where a judgement call arises, [`08-DECISION-REGISTER.md`](08-DECISION-REGISTER.md)
tells you which way to lean and why. Where a gap blocks you,
[`07-GAP-REGISTER.md`](07-GAP-REGISTER.md) names it — **stop and report rather than designing around
it**.

---

## Before you start

1. Read `CLAUDE.md` in full. Legal guardrail, process, tech stack and conventions are binding.
2. Read [`00-GATE-ZERO.md`](00-GATE-ZERO.md) §7 — the constants table. Every number you need is
   there, with its evidence grade.
3. Run `superpowers:writing-plans` against the stage you are starting and save the plan to
   `docs/plans/`. One stage at a time, then stop.
4. **Check for a Swift toolchain.** If `swift` and `xcodebuild` are absent — common in agent
   environments, and the egress policy refuses `download.swift.org` — write the code to the same
   standard anyway, record it in `docs/STATUS.md` as **unverified — never compiled**, naming the
   files, and **never** say "build green", "tests pass" or "verified". Do not route around the
   egress policy to fetch a toolchain.

---

## Three premises in the original brief that are WRONG. Do not act on them.

1. There is **no `READOUT / DESTINATION` split** in this repository. Zero occurrences. Use the
   readout/action **attribute** in [`04`](04-INFORMATION-ARCHITECTURE.md) §4 instead.
2. There is **no `SmallestDeviceLayoutTest`**. You will write `DensityBudgetTests` in
   `Tests/SimTests/Suites/`, per [`06`](06-TOKENS-AND-DENSITY.md) §3.5.
3. **`CalibrationBands` is a simulation artefact**, at
   `Sources/FootballSimCore/Calibration/CalibrationBands.swift`. It is not a design token. **A view
   must never import it.** The UI's rating-band equivalent is `CoachWorldTokens.Heat`.

---

## Build sequence

Stages are ordered by dependency. **Do not start a stage whose predecessor's acceptance criteria are
unmet.**

### Stage 0 — Amend canon (blocking, small)
Per `CLAUDE.md`'s doc-first rule, a design decision is answered in canon before it is implemented.

- Amend `docs/04-UX-AND-DESIGN-SYSTEM.md` §6.4 for the five-band heat scale (**D-007**). Without
  this amendment, stage 2 cannot proceed — this document does not get to change §6.4 unilaterally.
- Record the readout/action attribute in `04` alongside the existing surface registry description.

**Accept:** `04` states five bands with "average" neutral; `04` states the readout/action attribute;
no doc in `docs/` contradicts another. If `04` and this dossier appear to conflict anywhere else,
that is a defect to **escalate to the owner**, not to resolve by picking a winner.

### Stage 1 — Tokens
Extend `Sources/ProFootballCoachUI/DesignTokens.swift` only. No view changes.

- `Heat`: three bands → five ([`06`](06-TOKENS-AND-DENSITY.md) §2.6).
- New `Confidence` group: `rangeMinWidth 28`, `rangeSeparator "-"`, `unknownOpacity 0.55`,
  `progressHeight 4`.
- New `Density` group: the three tiers' row heights and cell budgets (`06` §3.2).

**Accept:** no design-token literal appears in any view; `Heat` returns five bands; the module
compiles (or is recorded unverified per the toolchain rule).

### Stage 2 — The density test (write it before the components it governs)
Write `Tests/SimTests/Suites/DensityBudgetTests.swift`, enumerating **by construction** from
`CoachWorldScreenID.allCases`. A hand-listed set of screens is a defect, not coverage — `CLAUDE.md`:
*"the test's coverage boundary became the quality boundary."*

Assert, at 844 × 390:
1. every canonical surface declares a tier;
2. no surface exceeds its tier's cell budget (DENSE 72, COMFORTABLE 56, BROADCAST 12);
3. no interactive row is shorter than `Shape.minimumTarget`;
4. no ACTION surface declares DENSE;
5. **every tier is instantiated by at least one surface at the floor** — otherwise it is an
   aspiration, not a tier.

**Accept:** the test compiles and **fails** against the current tree, naming the surfaces over
budget. A test that passes immediately is not testing anything.

### Stage 3 — Primitives
Build the three NEW primitives in [`05`](05-COMPONENT-REGISTER.md) Layer 1: `LeaderMark`,
`RangedRating`, `BandLegend`.

**Accept:** `LeaderMark` encodes by position and direction with no colour dependency and exposes a
spoken "leading"/"trailing" (**D-011**). `RangedRating` renders point, range and unknown, with
`.unknown` at `Confidence.unknownOpacity` and reading as *"not yet scouted"*. `BandLegend` renders
five bands from `Heat`. All three render at DENSE row height.

> `RangedRating` will have no real data until GAP-06. Build it against a stub read model, and record
> in `docs/STATUS.md` that it is unfed.

### Stage 4 — Composites
`CapabilityList` and `ColumnSetControl` (NEW). `CoachWorldAgendaRow` and `FloodlitStaffVoice`
(EXTEND).

**Accept:** `AgendaRow.delegated` names the delegate and is tappable through to their report
(invariant L-3). `ColumnSetControl` switches column sets without changing tier and **persists its
selection** — which requires GAP-11; if GAP-11 is not done, persist in memory for the session and
record the limitation. `CapabilityList` renders tick and cross with a text label, never colour alone.

### Stage 5 — Patterns
`DecisionCard`, `DelegateAssignmentCard`, `NewsTicker`, `CeremonyPlate`, `DenseTable`.

**Accept:**
- `DecisionCard` carries all six observed parts (`05` Layer 3) and **shows the price, never a
  predicted result** (**D-006**). An explicit decline control exists.
- `DelegateAssignmentCard` prints the delegate's numeric yield in its header and names the person.
  **Blocked on GAP-05** — build against a stub, record it.
- `NewsTicker` renders from chrome so every DESK surface gets it by construction; is **absent from
  the accessibility tree**; becomes static under Reduce Motion.
- `CeremonyPlate` is BROADCAST register, renders over the current surface, requires **no dismissal**.
- `DenseTable` **passes stage 2's budget** and implements FM26's four legibility techniques:
  leading position chip, status flags in their own narrow column, monochrome type with colour
  reserved for meaning, name in a bordered pill.

### Stage 6 — Refactor the 13 REFACTOR surfaces
Per [`01`](01-REPO-UI-INVENTORY.md). Highest value first: 16 Roster, 24 Recruiting Board,
8 Coaching HQ, 14 Match Day.

**Accept:** stage 2's test passes for every refactored surface. Every deep-dive exit restores scroll,
sort, filter and column set (**T-2**) — or GAP-11 is reported as blocking and the surface is left
alone rather than half-done.

### Stage 7 — Ceremony surfaces
Rebuild 29 Signing Day, 39 Draft Room, 49 Awards, 55 Promotion Decision. Add the championship result
surface (**GAP-10**) — adding the `CoachWorldScreenID` case will force a family assignment at compile
time, which is the registry working as designed.

**Accept:** exactly five ceremony surfaces exist; each costs one control to leave; each is reachable
afterwards from its family; **zero dedicated ceremony fires on a non-qualifying week** — assert this,
it is the countable half of `00` §6.3 and the half that keeps the fast path honest. Draft Room
carries the observed contract: on-the-clock header with countdown, "Up Next", filling pick list, and
a queue.

### Stage 8 — Delete
`RedesignedJobBoardProofView.swift`, `TeamLogoProofView.swift` (**D-013**). Split
`ScreenReadModels.swift` per family (**D-012**).

---

## Engine work — sequence separately, and note the honest reading

**7 of 12 gaps are engine-side, including the XL.** Any plan that sequences UI work first stalls at
GAP-05. If you own the engine too, run this in parallel from the start:

**GAP-05 (XL) → GAP-07 (S) → GAP-09 (L) → GAP-06 (L) → GAP-01 (L) → GAP-03 (M) → GAP-02 (M) →
GAP-08 (M) → GAP-04 (M)**

GAP-05 first because the entire session-intent model rests on it, and without it there is no fast
path — only a manual game with an advance button.

---

## Invariants — violating one invalidates the work

1. **No fabricated observations.** Every substantive claim carries an evidence grade. If you cannot
   observe it, say so. A fabricated screen layout propagates into the design system and costs a full
   rebuild cycle to detect.
2. **Engine/UI separation is preserved and strengthened** (**D-014**). No design may require
   `FootballSimCore` to know about presentation. Ceremony triggers emit **domain** events; the UI
   decides what is ceremonial. The engine says *"a championship was won"*, never *"play the
   championship ceremony"*. `FootballSimCore` contains zero `import SwiftUI` today — keep it that way.
3. **No desktop pattern without a translation note.** FM's density is 5:1 against this floor. Every
   borrowing states its translation. Every Madden/Show pattern additionally **replaces the console
   button legend with a visible affordance** — the legends are load-bearing there and have no touch
   equivalent.
4. **Every screen proposal survives the density test at 844 × 390**, or is explicitly marked as
   requiring a larger device class with the fallback specified. Portrait is not a supported
   orientation; landscape must work rotated **both** left and right.
5. **iOS-native idiom by default.** Deviations require a decision-register entry.
6. **The fast path is not a degraded mode.** A cruising player sees the same chrome, tokens and
   identity as a deep player. If delegation ever reads as "the version for people who don't really
   play", the brief has failed.
7. **Nothing in the repo is protected** — but `01`'s dispositions are evidence-based. Overturning a
   KEEP requires a new decision-register entry, not a preference.
8. **State the uncertainty.** Mark thin evidence and say what would resolve it.
9. **Legal guardrail (absolute).** All identities fictional and original. Real **place** names are
   permitted; venue and institution names are not. Madden's pundit-feed *mechanic* transfers; the
   real named broadcasters do not. Both legal tests stay green.
10. **No design-token literal in a view.** No magic numbers. No emoji in code, UI copy, commits or
    docs.

---

## Definition of done, per stage

- Build green **or** recorded as unverified-never-compiled with the files named. Never both, never
  a claim the compiler has not seen.
- Tests green, including `DensityBudgetTests`, `AccessibilityReflowTests`, `ContractTests` and both
  legal tests.
- Touched surfaces score **≥31/40 with zero P0/P1** against `docs/04b-AUDIT-RUBRIC.md` — eight
  dimensions, 0–5 each. Note this is 77.5%, and it **replaced** the older ≥17/20 five-dimension bar
  (85%); the two are not equivalent.
- `adversarial-reviewer` or `/code-review` run on the stage diff, confirmed findings fixed first. An
  adversarial review is **not** a build and must never be reported as one.
- One task = one commit, Conventional Commits.
- Simulator demonstration is an **owner** action. Hand off a written walkthrough script; never claim
  it happened.

---

## What to do when you hit a gap

Stop. Report which gap, which stage it blocks, and what the surface looks like without it. Then
either build against a stub and record the limitation in `docs/STATUS.md`, or move to the next
independent stage. **Do not** invent the missing data, and **do not** quietly narrow the surface so
the gap stops mattering — a design that assumes data the engine does not produce fails at build time,
and hiding that is worse than reporting it.
