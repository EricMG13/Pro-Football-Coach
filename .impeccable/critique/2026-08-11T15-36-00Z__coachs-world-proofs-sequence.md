---
target: The Coach's World proofs (hq, recruiting, match, index) — refinement command sequence
total_score: 35
max_score: 40
p0_count: 0
p1_count: 0
p2_count: 5
p3_count: 2
timestamp: 2026-08-11T15-36-00Z
slug: coachs-world-proofs-sequence
---
# Impeccable Sequence: The Coach's World Proofs

Method: static source review (4 HTML, `proof.css`, `interactions.js`, `README.md`, `EVIDENCE.md`)
scored against `docs/04b-AUDIT-RUBRIC.md`, plus the impeccable deterministic detector. Register:
**product** (design serves the task).

Deliverable: the order in which `distill`, `clarify`, `typeset`, `layout`, `bolder`, `harden` and
`polish` should be applied to the four proof files, with each step's shared-system work, per-screen
work, exit condition and regression guard.

## Method and its limits

Read honestly, because the previous build's failure was the claim rather than the gap.

- **What was examined:** every line of `hq.html`, `recruiting.html`, `match.html`, `index.html`,
  `proof.css` (364 lines), `interactions.js` (257 lines), `README.md`, `EVIDENCE.md`, and the
  8-dimension rubric in `docs/04b-AUDIT-RUBRIC.md`.
- **What was run:** the impeccable detector over the four HTML files and the stylesheet.
- **What was not run:** `render.cjs` and `audit.cjs` (the Playwright harness) were not re-executed,
  and no screenshots were taken in this pass. Every statement in this document about composited
  contrast, the 102-case matrix, pointer hit-testing or physical safe-area behaviour is **inherited
  from `EVIDENCE.md`, not independently verified here.**
- **Score deltas below are targets, not measurements.** The binding total is the **lowest** of the
  three proofs, because `04b` §7 requires Coaching HQ, Recruiting Board and Match Day to pass
  **together**. That is HQ at 35/40.

## Binding scorecard

From `EVIDENCE.md`, restated against the eight `04b` dimensions with the step that owns each gap.

| # | Dimension | HQ | Recruiting | Match | Owning step |
|---:|---|---:|---:|---:|---|
| 1 | Football fantasy | 5 | 5 | 5 | none — guard only |
| 2 | Task-specific composition | 5 | 5 | 5 | none — guard only |
| 3 | Information hierarchy | 4 | 4 | 5 | 1 `distill`, 5 `bolder` |
| 4 | World identity and continuity | 5 | 5 | 5 | none — guard only |
| 5 | Decision and control | 5 | 4 | 4 | 2 `clarify` |
| 6 | Accessibility and readability | 4 | 4 | 4 | 3 `typeset`, 6 `harden` |
| 7 | Truthfulness | 4 | 5 | 4 | 2 `clarify`, 6 `harden` |
| 8 | Craft and resilience | 3 | 4 | 4 | 4 `layout`, 5 `bolder`, 7 `polish` |
| | **Total** | **35** | **36** | **36** | |

Three dimensions are already at 5/5 across all three screens. **They are the constraint, not the
opportunity.** Every step below carries a guard naming what it must not cost.

## The sequence

Ordering principle: run each command **before** any command whose output it would invalidate. The
unit is two-tiered — shared-system work on `proof.css` / `interactions.js` happens once, then
per-screen work, so the token fix is never re-litigated three times.

### Step 1 — `distill`

**Position:** first. Nothing should be typeset, laid out, amplified or hardened if it is about to be
deleted. With the three absolute bans granted as authored exceptions (see below), `distill` is scoped
to genuine redundancy rather than ban-purging, which makes it a small, safe opening move.

**Shared system:**

- **Ten uppercase label roles** in 364 lines (`proof.css:66, 97, 108, 147, 150, 167, 175, 206, 224,
  271`). The individual instances are defensible; ten variants of "small loud label" are not. Reduce
  to at most three named roles. This is also the precondition for the `.eyebrow` exception holding:
  a device surrounded by nine competitors dilutes into the AI grammar the ban names.
- **Three container names for one behaviour:** `.decision-state`, `.board-state` and
  `.match-notice` all render the same `data-state-notice` / `role="status"` payload with slightly
  different chrome. One component, one name.

**Per screen:**

- **HQ — four renderings of one budget fact.** The eyebrow "Next obligation · due 12:00"
  (`hq.html:50`), the `.time-bank` "3h UNALLOCATED" (`hq.html:54`), the per-choice `2h / 2h / 1h`
  costs (`hq.html:61–68`) and the receipt line "Run fits selected · not saved" (`hq.html:72`) each
  narrate the same allocation. Separately, `.choice-evidence` "MARA'S PICK · 42 snaps · medium"
  (`hq.html:62`) repeats `.staff-voice` "Mara Bell · DC / 'Run fits first.'" (`hq.html:33`). This is
  the whole reason HQ sits at 4/5 hierarchy and 3/5 craft.
- **Recruiting — the file restates the row instead of extending it.** The prospect-file eyebrow
  "Board #1 · OT · top 3" (`recruiting.html:57`) repeats the rank, position and standing already
  carried by the selected row (`recruiting.html:37`), and `data-prospect-copy` repeats the sentence
  in `data-verdict`.
- **Match — two simultaneous causal narrations of one snap.** `.call-in` ("Theo Wren sees the
  cushion / CB24 is giving Voss eight yards at the boundary", `match.html:34`) and `.match-story`
  ("Voss has the split. Bell is protecting the sticks.", `match.html:41`) both explain the same
  moment, and one of them is `aria-live`. Match is 5/5 on hierarchy, so this is the lightest touch in
  the step; the risk is removing the wrong one and losing the staff-owner attribution that `04b` §4.8
  makes an automatic rejection condition.

**Exit condition:** every fact appears once per screen, or its repetition has a written reason. State
notices are one component.

**Guard:** dimensions 1 and 4 are at 5/5 and the repetitions carry world texture. **Replace
duplication with extension, never with absence.** If removing a line makes the screen quieter but
less inhabited, it was the wrong line.

### Step 2 — `clarify`

**Position:** second, because copy is the input to both the type scale and the grid. Rewriting
strings after the grid is fixed re-breaks the grid, and text overflowing its container is an
explicit ban. The counter-case is real and was considered: copy written to a known measure is normal
discipline. The mitigation is that this step must emit a **character budget per role**, so step 4 has
a target instead of a guess.

**Shared system:** the continuity vocabulary lives in `interactions.js`. `04b` §3.5 and the
2026-08-11 review both demand the same four facts on every state notice: **what saved, when, where
resume returns, and who now owns the decision.**

**Per screen:**

- **HQ:** "Set work" (`hq.html:73`) is a generic commit verb for an irreversible allocation.
  "Run fits selected · not saved" (`hq.html:72`) is a negative continuity statement with no stated
  resolution. "Delegate" names an action but not an authority transfer.
- **Recruiting:** the three actions state cost and nothing else — "Hold / No spend", "Plan visit /
  1 visit", "Call / 30 min" (`recruiting.html:67`). Consequence and deadline exist elsewhere as row
  text ("decision 9 days", `recruiting.html:46`) but not at the point of decision. This is the 4/5 on
  dimension 5.
- **Match:** three controls at three different specificities — "View matchup", "Stay on plan",
  "Attack CB24" (`match.html:35`) — and `Take Over` in `.match-controls` (`match.html:45`) names an
  authority handover with no stated scope or exit.

**Exit condition:** every control states cost, consequence and outcome owner. Every state notice
answers the four continuity facts. A per-role character budget is published for step 4.

**Guard:** dimension 7 is 4/5 on HQ and Match. Clarified copy must not promise a read model that
`EVIDENCE.md` §"Required production seams" has not named, or the step trades clarity for a
truthfulness regression.

### Step 3 — `typeset`

**Position:** third. This is the highest-value single step in the sequence and it must precede
`layout`, because measure and line-height derive from the scale, and a grid sized to a literal 12px
label breaks when the label becomes a token.

**The finding:** the type system passes AX5 **by enumeration rather than by construction.**

- **86 literal `font-size` declarations against 11 token references.**
- **72 hand-written `body.ax5` override rules** — 58 in the main block (`proof.css:279–336`) plus 14
  more inside the 870px media query (`proof.css:344–359`). **At least 18 exist only to restate a
  size**: `body.ax5 .world-route button { font-size: 17px }`,
  `body.ax5 .programme-id strong { font-size: 17px }`, `body.ax5 .week-days button { font-size: 17px }`
  and so on. Most of the remainder mix a size restatement with a genuine layout change, so they must
  be split rather than deleted.
- `audit.cjs:91–94` asserts that no working text renders below 17px at AX5. **It passes.** But it
  passes because someone remembered every element twice, and the assertion cannot distinguish that
  from a system that scales by construction. This is precisely the convention in `CLAUDE.md`: *"the
  test's coverage boundary became the quality boundary."* A new element added tomorrow is covered the
  day someone remembers it, not the day it is added.

**Shared system:**

- Extend the existing token set (`--meta 12`, `--body 14`, `--headline 17`, `--title 22`) to cover
  the display and data roles, then delete every `body.ax5` rule that only restates a size. Keep the
  `body.ax5` rules that change **layout** — `grid-template-columns`, `display: none`, padding — those
  belong to steps 4 and 6, not here.
- **Flatten the working band.** 12px appears 47 times, 14px 7 times, 13px 3 times, with no ratio
  between them. Product register wants 1.125–1.2 per step; three near-identical steps are noise.
- **Name the display band.** 19, 20, 22, 25, 29, 32 and 42px are currently one-offs.
- **Fix `letter-spacing: -.07em`** on the 42px week number (`proof.css:98`). The floor is -0.04em;
  below it the letters touch and read as cramped rather than designed.

**What must survive this step:** AX5 currently preserves the task by **deleting supporting facts**,
not just by growing type. Twelve or more rules hide content at AX5 — office wire items 3 and up
(`proof.css:308`), prospect rows 4 and up (`proof.css:320`), relationship steps 4 and up
(`proof.css:324`), the prospect verdict paragraph (`proof.css:323`), the board column header
(`proof.css:315`), the blank-photo label (`proof.css:326`), the story paragraph (`proof.css:332`), and
at 870px both HQ rails entirely (`proof.css:345–346`). The comment at `proof.css:278` states the
intent plainly: *"AX5 reductions preserve the task, not every supporting fact."* That is a defensible
owner decision and this step must not quietly reverse it while tokenising. It does mean an
AX5 user sees three of five prospects and loses the verdict paragraph, which is worth confirming as
intended rather than inherited.

**The one legitimate exemption:** the 9px jersey numbers on `.actor` (`proof.css:237`) sit inside a
`role="img"` field with a complete `aria-label` (`match.html:13`). They are graphic marks, not
authored text, and are correctly exempt from the 12pt floor. `EVIDENCE.md`'s blanket claim that
"Authored text stays at or above 12 pt" should be **amended to name the exemption** rather than left
as a contradiction for the next reader to trip over.

**Exit condition:** `rg -o 'font-size:\s*[0-9]' proof.css` returns only the field-graphic exemption.
AX5 is one token swap. A newly added element inherits the scale without anyone remembering it.

**Guard:** the 102 harness cases must still pass, and the AX5 assertion must move from *passes by
enumeration* to *passes by construction*. If the case count drops, the step regressed.

### Step 4 — `layout`

**Position:** fourth, against a final element set (step 1) and a final scale (step 3).

**Shared system:** one spacing scale. Off-scale literals are in place today — `padding: 5px`
(`proof.css:68`), `gap: 9px` (`proof.css:77, 243`), `padding: 7px 9px` (`proof.css:293`),
`gap: 14px` (`proof.css:86`), `margin-top: 2px` (`proof.css:82, 132`). Radii need no work and should
be left alone: 0, 3px, 4px and 50% is already disciplined, and is the opposite of the over-rounding
failure mode.

**Per screen:**

- **HQ:** the `166px / 1fr / 202px` three-column floor (`proof.css:95`) and its AX5 reduction to
  `138px / 174px` (`proof.css:286`). The decision is the task and currently occupies the middle
  third.
- **Recruiting:** board plus prospect-file two-column, with the 48px `.prospect-row` (`proof.css:176`)
  as the rhythm unit.
- **Match:** absolute overlay z-order — scorebug at z20, plus call-in, notice, story and controls.
  `04b` §8 requires no horizontal overflow and no hidden mandatory control at the exact frames.

**Exit condition:** verified at 844×390 **and** 932×430, `sensor-left` **and** `sensor-right`, with
no overflow and the primary action inside the first viewport at AX5. That last one is the exact
defect the 2026-08-11 Film Cut review caught in the earlier candidate; it is a known failure mode for
this layout family, not a hypothetical.

**Guard:** 44×44pt targets (`proof.css:62`) and the physical 59px landscape inset (`proof.css:58–59`)
must survive untouched.

### Step 5 — `bolder` (narrow)

**Position:** fifth and **scoped**, not a suite-wide amplification. These proofs are not bland: they
hold 5/5 on Football fantasy and Task-specific composition, and their loudest devices are being kept
as authored exceptions. Remit is limited to the dimensions the scorecard marks below 5.

**In remit:**

- **HQ, Craft 3/5 and hierarchy 4/5.** The `--identity` bronze is currently spent as a weak wash in
  three places at 13–14% `color-mix` (`proof.css:96, 135, 178`), which reads as three tinted panels
  rather than one committed identity. Let the practice decision own more surface than the two rails.
- **Recruiting, hierarchy 4/5.** The `.battle` column — "Carson · Northport · Bay State"
  (`recruiting.html:37`) — is where the drama of the screen lives and is currently the
  lightest-weight cell in the row.

**Out of remit:** Match Day, which is 5/5 on hierarchy. Leave it.

**Exit condition:** HQ Craft 3→4 at minimum, and owner-gate questions 1 and 5 in `04b` §7 answered
yes — it reads as a serious contemporary football game, and a screenshot stays identifiable with
every label outside the device removed.

**Guard:** two automatic rejection conditions are live here. §4.2 (five or more equal-weight rounded
containers dominating the initial viewport) and §4.3 (pills, coloured spines or shadows supplying
most of the hierarchy). The authored exception on the inset selection stripe makes §4.3 the real
risk: amplifying the stripe is the wrong way to answer this step.

### Step 6 — `harden`

**Position:** sixth. Hardening before the visual language settles produces adverse states authored in
a language that is about to change.

**Shared system:** re-establish the `04b` §6 matrix over the changed surface. The harness already
covers 102 cases and 1,315 checks; the point of this step is that **steps 1–5 invalidate that pass.**
In particular `stress=long` interacting with the new scale and grid needs re-proving, since long
generated names escaping their football object was one of the seven classes the original adversarial
pass had to fix.

**Verify, do not assume:** the 2026-08-11 review of the earlier Film Cut candidate found three
failure classes in a sibling artefact — commit announcing a focus other than the one selected,
delegation announcing success without settling authority or unlocking progression, and interruption
being bypassable without review. Those findings were made against `film-room.js`, **not** against
`interactions.js`, and no claim is made here that they recur. This step must check each one against
`interactions.js` and record the result either way.

**Per screen:** the nine states the proofs already accept (`normal`, `loading`, `empty`, `error`,
`success`, `disabled`, `delegated`, `interrupted`, `resume`) each need re-checking against the new
element set, particularly the ones step 1 consolidated into a single notice component.

**Exit condition:** `audit.cjs` re-run green at the same or higher case count, and `EVIDENCE.md`
**amended** rather than merely re-asserted — including the 12pt exemption from step 3 and any change
to the read-model seam table.

**Guard:** dimension 7. Hardened states must not invent a receipt, projection or save confirmation
that no named read model can own. `04b` §4.7 makes internal fixture copy inside the game frame an
automatic rejection.

### Step 7 — `polish`

**Position:** last, definitionally. Anything run after it is thrown away.

**Scope:** the residue that only shows up once everything else is settled.

- **Focus visibility:** `outline: 2px solid var(--ink); outline-offset: -4px` (`proof.css:89`) is an
  inset outline, which can be visually swallowed on a filled 44px target. Check both appearances.
- **Interaction state completeness:** product register requires default, hover, focus, active,
  disabled on every interactive class. Today `button:not(:disabled):active { transform:
  translateY(1px) }` (`proof.css:90`) is the only press feedback in the sheet, and several control
  classes have `:hover` but no distinct `:active`.
- **Untokenized literals:** the hand-mixed disabled state `#3c4530` / `#c7d2b0` (`proof.css:88`) and
  the direct hexes in `.world-strip` and `.scorebug` (`proof.css:75, 76, 82, 84, 242, 245`) sit
  outside the token set.

**Exit condition:** no untokenized literal outside the field-graphic set; every interactive class has
a complete state vocabulary; the detector returns zero findings outside the recorded exceptions.

**Guard:** if any later change touches structure, the sequence restarts at that change's own step.
Polish does not absorb structural work.

## Dependency rationale

Why this order and not another. Each line is an invalidation, which is the only ordering argument
that survives contact with the work.

- **`typeset` before `distill`** would set a scale for elements that then disappear.
- **`layout` before `typeset`** sizes grids to literal pixel labels that are about to become tokens.
- **`clarify` after `layout`** rewrites strings into a fixed measure and risks overflow, which `04b`
  and the shared bans both punish. Rejected, with the mitigation that `clarify` publishes a character
  budget so `layout` is not guessing.
- **`bolder` before `typeset` / `layout`** would be defensible in the general case, because
  amplification decides how much surface the dominant object owns and therefore what the scale and
  grid must be. It is held to step 5 here for a specific reason: the base is already 5/5 on fantasy
  and composition, so an early direction change has more to lose than to gain. If the owner rejects
  the direction at step 5, the correct response is to restart at step 3, not to have run `bolder`
  first as insurance.
- **`harden` before steps 1–5** authors adverse states in a language that then changes.
- **`polish` anywhere but last** is discarded work.

## Authored exceptions

Owner-granted 2026-08-11. Three impeccable absolute bans are present in the proofs and are **kept**,
because each is doing football work rather than decoration. Recorded here so the next reader finds
the justification rather than re-opening the argument, and so the recurring detector findings are
explained rather than re-triaged.

**1. Tracked uppercase eyebrow — `.eyebrow` (`proof.css:66`).** Seven uses inside native frames
(`hq.html:25, 29, 50, 84`; `recruiting.html:26, 57, 59`), one in gallery chrome (`index.html`).
*Justification:* it carries the register and the dateline in a broadcast and desk idiom, and football
broadcast typography is genuinely uppercase and tracked. *Condition:* step 1 must bring the nine
competing uppercase roles down. An exception surrounded by imitators is no longer an exception.

**2. Numbered markers — `.choice-index` `01 / 02 / 03` (`hq.html:62, 65, 68`).** *Justification:* the
practice choices genuinely are an ordered call sheet, so the number carries information rather than
scaffolding, which is the distinction the ban itself draws. *Condition:* they must not spread to any
non-ordered section anywhere in the suite.

**3. Side-stripe accent — `box-shadow: inset 4px 0` and `inset 5px 0 var(--identity)`
(`proof.css:135, 178, 245`).** *Justification:* it is a selection affordance bound to `aria-pressed`
and `aria-selected`, not decoration on a static card. *Condition:* `04b` §4.3 forbids coloured spines
supplying **most** of the hierarchy. Step 5 must confirm that boundary, value and spoken state still
carry selection without colour — which `EVIDENCE.md` already asserts and which the harness measures.

## Anti-patterns verdict

**Deterministic scan:** the detector returns **3 advisory findings, all `numbered-section-markers`**,
in `hq.html`, `match.html` and `index.html`. No warnings. No errors.

On inspection **two of the three are false positives**: the reported sequence in `match.html` is
`10, 11, 12`, which the scanner is reading off jersey numbers on the field actors
(`match.html:21–22`), and `index.html` is gallery chrome outside the native frame. `hq.html`'s
sequence `01, 02, 03, 09, 11, 12` is the only real hit, mixing the three choice indices with the week
number `09` and incidental figures. **That single real finding is authored exception 2 above.**

The suite is therefore clean against the deterministic scan. For scale: the superseded
`*-v2.dc.html` sheets produced **1,011 findings** across 16 files, including 696 untokenized colors,
192 off-scale radii, 25 side-stripe borders and 8 numbered eyebrows. The proofs are a different class
of artefact.

**LLM assessment:** no gradient text, no glassmorphism, no hero-metric template, no identical card
grid, no `repeating-linear-gradient` decoration, no sketchy SVG, no ghost-card border-plus-wide-shadow
pairing, and no over-rounding. The codex-specific tells are absent. What remains is not slop but
**system debt**: a type scale held together by enumeration, a spacing scale with off-scale literals,
and one screen narrating the same fact four ways.

## What's working

1. **Radius and shadow discipline.** Radii are 0, 3px, 4px and 50%, and the only shadows in the sheet
   are `inset` identity strokes. There is no `1px border + 24px blur` ghost card and nothing rounded
   past 4px. This is the inverse of the usual failure mode and should be protected through all seven
   steps.
2. **Safe areas modelled physically, not decoratively.** `--safe-left` / `--safe-right` with
   `body.sensor-left` and `body.sensor-right` supplying the real 59px landscape inset
   (`proof.css:25–26, 58–59`), consumed by every chassis rule (`proof.css:75, 95, 242`). The absent
   safe-area handling that the 2026-08-11 review raised as a P1 against the earlier candidate is
   already solved here.
3. **One design language, three visibly different football experiences.** This is the actual `04b` §7
   proof-gate requirement, and it holds: office rails and a week canvas, a ranked ledger board with a
   dossier, and a full-bleed 22-actor field with a broadcast scorebug. The composition follows the
   football object in all three cases, which is why dimension 2 is 5/5 across the board and why no
   automatic generic-application rejection condition fires.

## Priority issues

No P0. No P1 — the primary task completes and is understandable on all three screens, in both
appearances, at AX5, in both sensor orientations, per the harness result recorded in `EVIDENCE.md`.

### [P2] AX5 passes by enumeration rather than construction
- **Why it matters:** 86 literal font sizes, 11 token references and 72 `body.ax5` override rules.
  The `audit.cjs:91–94` assertion passes, so nothing is currently broken for a supported user — but
  correctness depends on human memory, and the next element added is uncovered until someone
  remembers it. `PRODUCT.md` commits to "Every screen legible at AX5" and backs it with
  `DynamicTypeContractTest`; that contract cannot be honoured by a scale that must be restated twice
  per element.
- **Fix:** one constructed token scale; delete every `body.ax5` rule that only restates a size.
- **Suggested command:** `$impeccable typeset` (step 3)

### [P2] Four renderings of one budget fact on Coaching HQ
- **Why it matters:** the eyebrow, the time bank, the per-choice costs and the receipt line all
  narrate the same allocation, and the choice evidence repeats the staff voice. This is the direct
  cause of HQ's 4/5 hierarchy and 3/5 craft, and HQ's 35/40 is the binding total for the whole gate.
- **Fix:** each fact once, or a stated reason for the repetition; extend rather than delete.
- **Suggested command:** `$impeccable distill` (step 1)

### [P2] Two simultaneous causal narrations on Match Day
- **Why it matters:** `.call-in` and `.match-story` explain the same snap at the same time, one of
  them inside `aria-live`. For a non-visual user this is two announcements of one event.
- **Fix:** one causal sentence with its staff owner; the other container becomes evidence or
  consequence, not a second narration.
- **Suggested command:** `$impeccable distill` (step 1)

### [P2] Continuity language incomplete at the moment of commitment
- **Why it matters:** `04b` §3.5 separates inspect, decide, delegate, recover and continue by
  semantics. "Set work", "not saved" and a bare "Delegate" do not say what saved, when, where resume
  returns or who now owns the outcome — and the commuter persona needs exactly that at the moment the
  phone goes back in a pocket.
- **Fix:** the four continuity facts on every state notice; cost, consequence and owner on every
  control.
- **Suggested command:** `$impeccable clarify` (step 2)

### [P2] Off-scale spacing literals
- **Why it matters:** 5px, 7px, 9px and 14px against an 8pt scale. Minor individually; collectively
  it is the drift that made the v2 sheets unimplementable.
- **Fix:** one spacing scale, verified at both native frames and both sensor orientations.
- **Suggested command:** `$impeccable layout` (step 4)

### [P3] `EVIDENCE.md`'s 12pt claim contradicts the field graphics
- **Why it matters:** "Authored text stays at or above 12 pt" reads as absolute, while `.actor`
  jersey numbers render at 9px (`proof.css:237`). The numbers are correctly exempt — graphic marks
  inside a fully labelled `role="img"` — but an unqualified claim leaves a contradiction for the next
  reader, and unqualified claims are this project's recorded failure mode.
- **Fix:** amend the claim to name the exemption.
- **Suggested command:** `$impeccable typeset` (step 3), landed in `harden`'s evidence amendment

### [P3] Ten uppercase label roles in one 364-line sheet
- **Why it matters:** it dilutes the deliberate eyebrow into general grammar, which is the exact
  mechanism by which an authored device becomes a tell.
- **Fix:** at most three named label roles.
- **Suggested command:** `$impeccable distill` (step 1)

## Persona red flags

- **Alex (impatient power user):** the practice decision offers no "same as last week" path, and the
  weekly obligation queue in `.office-wire` cannot be cleared without visiting each item. Step 2
  should give the commit control a repeat affordance; step 5 should make the decision, not the rails,
  the thing the thumb lands on.
- **Sam (accessibility-dependent user):** currently the best-served persona — 44pt floor enforced
  globally (`proof.css:62`), skip link, `sr-only` live region, composed field label, physical safe
  areas. The exposure is latent rather than present: 72 hand-written AX5 rules mean the next element
  is one forgotten override away from failing. Step 3 is the fix.
- **Casey (distracted mobile user):** "not saved" is shown at precisely the moment continuity
  matters most, without stating what happens on interruption. The `interrupted` and `resume` fixtures
  exist; step 2 must make their copy answer where resume returns, and step 6 must prove the path.
- **Morgan (veteran football sim player):** well served on evidence and attribution — snap counts,
  named owners, explicit confidence. The gap is that HQ's identity colour is spent as three weak
  panel washes rather than one committed stroke, so the office reads flatter than the field. Step 5,
  narrowly.
- **Sam again, on content rather than size:** at AX5 the same user sees three of five prospects, three
  of four relationship steps and no verdict paragraph. The task survives; the evidence behind the
  judgement partly does not. Steps 3 and 6 should confirm that trade is intended.

## Minor observations

- **Motion is effectively absent:** one `transition`, one `animation` and one
  `prefers-reduced-motion` block in 364 lines, with a 1px active translate as the only press
  feedback. Product register wants 150–250ms state transitions. `animate` is **not** in this
  sequence, so either step 7 absorbs a minimal state-transition vocabulary or the gap is recorded and
  carried to the SwiftUI phase.
- **Tokens are hex, not OKLCH.** Defensible for a proof whose target is SwiftUI rather than CSS, and
  the palette is coherent in both appearances. Worth deciding deliberately before the token set is
  extracted for Swift, because that is the moment the choice becomes expensive.
- **Light appearance is a full second token block** (`proof.css:32–52`), not an afterthought — but
  `--quiet: #68727e` on `--work: #f5f3ed` should be re-measured after any step touches colour.
- **The world strip stays dark in light mode** (`proof.css:76`), an intentional chrome-versus-content
  split. Step 4 should keep it; it is doing the second-neutral-layer job the product register asks
  for.
- **`.impeccable/critique/latest-critique.json` is 0 bytes**, so the `critique.latest` signal is
  blind. This document is a sequencing plan rather than a scored critique run and does not populate
  it; a `critique` run against these proofs would.

## Out of scope for this sequence

Named so their absence is a decision rather than an oversight: `animate` (the motion gap above),
`colorize` (the palette is coherent; the OKLCH question is a token-extraction decision),
`extract` and `document` (the SwiftUI token handoff, which belongs to the production phase),
`shape` (no new screens are being designed), `onboard`, `adapt` and `optimize`.

## Questions to consider

- Should step 2 give the practice commit a "same as last week" path, or does a repeat affordance
  weaken the weekly decision that is the point of the screen?
- On Match Day, which of the two causal containers survives step 1 — the staff call-in, which carries
  the owner and the actionable choice, or the story band, which carries the `aria-live` narration?
- Does the motion gap get absorbed by step 7 as a minimal state-transition vocabulary, or recorded
  and carried whole into the SwiftUI phase where `Canvas` and `TimelineView` own it anyway?
- Hex or OKLCH for the token set, decided before extraction rather than after?
- Is the AX5 content reduction intended as designed? An AX5 user currently sees three of five
  prospects and no verdict paragraph. Preserving the task while dropping the evidence is a real
  position, but it should be a chosen one.
- Is a second owner review scheduled between step 5 and step 6? `bolder` is the only step that can
  move the two 5/5 dimensions the gate depends on, and `04b` §7 is explicit that no numeric score
  overrules the owner on whether it feels like a serious football game.
