---
target: v2 on reference designs
total_score: 29
p0_count: 0
p1_count: 3
timestamp: 2026-08-10T16-41-35Z
slug: v2-reference-designs
---
# Impeccable Critique: v2 Reference Designs

Method: dual-agent (Assessment A: Design Review · Assessment B: Detector Scan & Browser Evidence)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Outstanding match clock/moment indicators and save/resume state clarity; timed draft auto-expiry behavior on backgrounding remains unresolved. |
| 2 | Match System / Real World | 4 | Domain-fluent football management grammar: 2D field canvas, score bugs, broadcast vs desk registers, and authentic college-to-pro career mechanics. |
| 3 | User Control and Freedom | 3 | Strong match exit modal, promotion refusal option, and destructive confirmation sheets; first-run sequence and draft flow remain comparatively rigid. |
| 4 | Consistency and Standards | 2 | Significant canonical contradictions between `*-v2.dc.html` sheets, `design.md`, and `docs/04-UX-AND-DESIGN-SYSTEM.md` (e.g., undrawn screen claims, conflicting token hexes, 726 off-scale spacing literals). |
| 5 | Error Prevention | 3 | Refusal banners explicitly state limit, resolution, and action link; over-capacity meters draw in negative state. However, 36pt touch targets on batch/empty state actions violate the 44pt contract. |
| 6 | Recognition Rather Than Recall | 3 | Verdict-first readouts eliminate raw data scanning; default Game Plan exposes 11 visible controls at once, violating the ≤4 working-memory guideline. |
| 7 | Flexibility and Efficiency | 3 | Powerful `ListControls` (search/filter/sort/multi-select) on Roster; lacks Game Plan presets or "reuse last week" shortcuts for rapid weekly iteration. |
| 8 | Aesthetic and Minimalist Design | 3 | Core product UI is focused and tailored to landscape mobile; reference HTML wrapper relies on AI editorial tropes (numbered `01/02/03` section markers, tracked uppercase eyebrows on every section, em-dash heavy copy, side-tab borders). |
| 9 | Error Recovery | 3 | Actionable save failure recovery preserving user progress; Dynamic Type scaling at AX5 drops reassurance text and some controls fall below 44pt touch regions. |
| 10 | Help and Documentation | 2 | `design.md` explicitly warns it is "NOT CANON" with 9 documented sheet-vs-canon conflicts (C1–C9); Map canvas accessibility remains marked "unresolved". |
| **Total** | | **29/40** | **Good foundation; not implementation-ready as a single source of authority.** |

## Anti-Patterns Verdict

**LLM assessment:** High product specificity with strong domain authenticities (desk vs broadcast registers, 2D field canvas, team primary fill rules, single-save career continuity). However, the documentation shell exhibits significant AI slop tells: repetitive numbered section headers (`01 / 02 / 03`), tracked all-caps eyebrows on nearly every section, heavy em-dash prose, and decorative 3px left-border side tabs across multiple HTML sheets (`FirstRun`, `Teaching`, `Throughput`, `Failure`).

**Deterministic scan:** 39 findings across the 16 reference HTML sheets:
- **25 `side-tab` warnings**: Decorative colored `border-left: 3px solid` callouts in `FirstRun-v2.dc.html`, `Teaching-v2.dc.html`, `Throughput-v2.dc.html`, and `Failure-v2.dc.html`.
- **11 `em-dash-overuse` warnings**: Excessive em-dash counts in body text (e.g. 11 in `Squad-v2.dc.html`, 7 in `Teaching-v2.dc.html`, 6 in `Offseason-v2.dc.html`).
- **3 `flat-type-hierarchy` warnings**: Font size steps too close together (e.g. 9px, 9.5px, 10px, 11px, 12px in `System-v2.dc.html` and `Teaching-v2.dc.html`), violating the 12pt floor and 1.25 step ratio.
- **`numbered-section-markers`**: Repeated use of `01, 02, 03...` display markers as section scaffolding in `Screens-v2.dc.html`, `System-v2.dc.html`, `Teaching-v2.dc.html`, and `Tokens-v2.dc.html`.

**Visual overlays:** Browser visualization was skipped for CLI file scan; CLI detector completed deterministically with exit code 2.

## Overall Impression

The v2 reference design suite establishes an exceptional, highly specific visual world for landscape iPhone football management. The broadcast/desk register distinction, consequence-first copy, rating lightness ladders, and commute-aware continuity rules are production-grade. However, as an implementation library, it suffers from self-contradictions across sheets, off-scale spacing literals, sub-12pt typography, and unresolved high-stakes states. Editorial reconciliation is required before SwiftUI code construction begins.

## What's Working

1. **Domain-Specific Visual Architecture:** The desk vs broadcast register separation, 2D full-field canvas with directed attention, single-hue rating lightness ladders, and team primary fill rules give the app a distinct, authentic sports-sim identity.
2. **Consequence-Driven Decision Design:** Every destination imposes real trade-offs (e.g., install hours vs game plan depth, contact budget vs recruiting reach), readouts lead with engine-generated verdicts, and failure surfaces provide 3-part actionable navigation.
3. **Deep Continuity & Accessibility Foundation:** AX5 single-column pane reductions, composed VoiceOver sentences, Reduce Motion discrete state sequences, and save-on-decision architecture are designed natively into the chassis.

## Priority Issues

### [P1] Canonical Contradictions & Unresolved Authority
- **Why it matters:** Implementers cannot determine whether to follow the 16 `*-v2.dc.html` sheets, `design.md`, or canonical `docs/04-UX-AND-DESIGN-SYSTEM.md`. `Screens-v2` claims Inbox, Game Plan, and Roster are undrawn (though later drawn); `Components-v2` applies `live` tokens to static final scores (violating token rules); `design.md` lists 9 explicit sheet-vs-canon conflicts (C1–C9).
- **Fix:** Perform an editorial pass reconciling all 16 HTML sheets with `docs/04-UX-AND-DESIGN-SYSTEM.md`. Remove historical "missing" claims, standardize token hexes, enforce the 22-component registry, and publish one unified canonical reference.
- **Suggested command:** `$impeccable document`

### [P1] Accessibility & Token Contract Violations in Reference Markup
- **Why it matters:** The reference HTML sheets contain 726 off-scale spacing padding literals (6px, 9px, 11px, 13px), 192 text runs below the 12pt floor (down to 9px), 36pt touch targets on batch/empty state actions (under the 44pt floor), and light-mode `content.tertiary` text falling below 4.5:1 contrast.
- **Fix:** Purge all off-scale spacing literals to match the 8pt scale (`xs 4, s 8, m 16, l 24, xl 32, xxl 48`), raise all text to ≥12pt, expand all interactive touch regions to 44×44pt, and restrict `content.tertiary` to large text or non-text indicators.
- **Suggested command:** `$impeccable audit`

### [P1] Unresolved Critical States & Missing Layout Cases
- **Why it matters:** Developers will be forced to invent product behavior at high-stakes moments. The Offer screen (S3) is unrendered; map canvas accessibility is marked "unresolved"; timed draft auto-expiry behavior on backgrounding is not defined; and no regular-width 932×430 Plus/Max desk chassis reference exists.
- **Fix:** Formally design and draw the S3 Offer screen, define the timed-draft interruption/backgrounding state machine, resolve accessible Map view twin semantics, and draw the regular-width 932×430 chassis layout.
- **Suggested command:** `$impeccable shape`

### [P2] Cognitive Overload in Weekly Game Plan Loop
- **Why it matters:** The 15-minute weekly loop forces users to evaluate 11 visible game-plan controls simultaneously on a single screen. This exceeds human working-memory limits (≤4 items) and creates friction for both novices and power users who lack one-tap presets or "reuse last plan" shortcuts.
- **Fix:** Lead with coordinator recommendations and named presets (e.g., "Ground & Pound", "Air Raid Defense"), hide secondary adjustments behind an "Advanced" accordion, and add a "Reuse Last Week's Plan" shortcut.
- **Suggested command:** `$impeccable distill`

### [P2] Truncated Career Promotion Emotional Arc
- **Why it matters:** College-to-pro promotion is the product's headline feature and primary multi-season retention hook. Currently, the experience terminates abruptly on a "Take the Job" button without an authored appointment arrival sequence or visual office transition.
- **Fix:** Build a dedicated promotion arrival sequence featuring a bronze-to-steel broadcast shift, new stakeholder introduction, and front office budget transition.
- **Suggested command:** `$impeccable delight`

## Persona Red Flags

- **Alex (Impatient Power User):** Weekly game plan requires manually configuring 11 separate dials before every match without presets, compare-to-last-week, or quick-apply shortcuts. First-run sequence lacks an explicit skip path.
- **Sam (Accessibility-Dependent User):** Reference sheets include sub-12pt text (9pt–11pt), 36pt touch targets on batch actions, and light mode tertiary labels below 4.5:1 contrast. Map canvas accessibility is marked "unresolved" in `League-v2`.
- **Casey (Distracted Mobile User):** Save-on-decision and paused match call-ins are excellent, but timed draft auto-expiry during an incoming phone call or backgrounding event is undefined, risking ruined draft picks.
- **Morgan (Veteran Football Sim Player):** Verdict-first summaries provide great guidance, but the game plan interface feels like a settings menu rather than strategic coaching. The missing post-promotion arrival undercuts the reward of a 10-season promotion arc.

## Minor Observations

- `numeral` Dynamic Type face (`SF Compact` condensed tabular) needs verification in SwiftUI implementation to ensure proper fallbacks.
- Bronze (`#D9A441`) and steel (`#7FB2E5`) house accents have near-identical luminance (1.007:1 ratio); relying solely on 9° geometry for college vs pro distinction may be subtle at small scales.
- ProgressState 600ms minimum display floor may feel slightly sluggish on instant local calculation steps.
- Light appearance reference coverage is sparse compared to native dark mode.

## Questions to Consider

- Should the weekly Game Plan lead with coordinator recommendations/presets rather than exposing 11 raw control sliders?
- How should the timed draft handle app backgrounding or incoming call interruptions without auto-picking unwanted players?
- What is the canonical source of truth when a `*-v2.dc.html` sheet directly contradicts `docs/04-UX-AND-DESIGN-SYSTEM.md`?
- Should the college-to-pro promotion sequence include an authored appointment scene to celebrate the career milestone?
