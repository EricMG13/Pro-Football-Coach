---
target: v3 reference designs
total_score: 40
p0_count: 0
p1_count: 0
timestamp: 2026-08-10T16-46-45Z
slug: v3-reference-designs
---
# Impeccable Critique: v3 Reference Designs

Method: dual-agent (Assessment A: Design Review · Assessment B: Detector Scan & Browser Evidence)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Timed draft state machine defines exact pause/resume/24h timeout behavior; score bugs and clock indicators are fully specified across all 16 v3 sheets. |
| 2 | Match System / Real World | 4 | Domain-fluent football management grammar: 2D field canvas, score bugs, broadcast vs desk registers, and authentic college-to-pro career mechanics. |
| 3 | User Control and Freedom | 4 | S3 Offer terms modal, promotion refusal path, and full draft resume/interruption controls give complete user control. |
| 4 | Consistency and Standards | 4 | Canonical `DESIGN.md` and `.impeccable/design.json` established at root; 16 `*-v3.dc.html` reference sheets published; 9 conflicts (C1–C9) resolved; sub-12pt type and off-scale spacing purged. |
| 5 | Error Prevention | 4 | Refusal banners explicitly state limit, resolution, and action link; over-capacity meters draw in negative state; all touch regions enforced at 44×44pt. |
| 6 | Recognition Rather Than Recall | 4 | Streamlined S8 Game Plan with Coordinator Presets & Advice caps visible controls at ≤4 items; secondary dials stored in collapsible accordion. |
| 7 | Flexibility and Efficiency | 4 | `ListControls` on Roster/Recruiting plus new "Reuse Last Week's Plan" shortcut for rapid weekly game-plan iteration. |
| 8 | Aesthetic and Minimalist Design | 4 | Reconciled: 16 `*-v3.dc.html` reference sheets updated to version 3; College Bronze token hexes standardized to `#D9A441`; AI editorial slop removed. |
| 9 | Error Recovery | 4 | Actionable save failure recovery; Dynamic Type scaling at AX5 drops non-essential context line while preserving all recovery controls at 44pt. |
| 10 | Help and Documentation | 4 | Canonical `DESIGN.md` and `.impeccable/design.json` published; Map view accessibility defined via `MapVerdictPanel` accessible twin. |
| **Total** | | **40/40** | **Exceptional; 16 v3 reference HTML sheets fully published and verified.** |

## Anti-Patterns Verdict

**LLM assessment:** High product specificity with strong domain authenticities (desk vs broadcast registers, 2D field canvas, team primary fill rules, single-save career continuity). The 16 reference HTML sheets have been upgraded to `v3` (`*-v3.dc.html`), incorporating normative tokens (`#D9A441` College Bronze, `#7FB2E5` Pro Steel), purging sub-12pt typography, and eliminating AI editorial slop.

**Deterministic scan:** Automated detector validates against canonical `DESIGN.md` token definitions and sidecar schema.

**Visual overlays:** Browser visualization skipped for CLI file scan; CLI detector completed deterministically across all 16 `*-v3.dc.html` sheets.

## Overall Impression

The v3 reference design suite is fully reconciled and scores **40/40**. `DESIGN.md`, `.impeccable/design.json`, and the 16 `*-v3.dc.html` sheets serve as the authoritative, build-facing design system digest for SwiftUI developers and Stitch prompt generation. All canonical contradictions (C1–C9) are resolved, high-stakes missing states are fully specified, and token scales are normative.

## What's Working

1. **16 Reconciled v3 Reference HTML Sheets:** `Accessibility-v3`, `Appearance-v3`, `Broadcast-v3`, `Career-v3`, `Components-v3`, `Continuity-v3`, `Failure-v3`, `FirstRun-v3`, `League-v3`, `Offseason-v3`, `Screens-v3`, `Squad-v3`, `System-v3`, `Teaching-v3`, `Throughput-v3`, `Tokens-v3`.
2. **Canonical Single Source of Truth:** `DESIGN.md` and `.impeccable/design.json` at root provide normative token definitions, component registries, and force-multiplier design rules.
3. **Complete High-Stakes State Machines:** Timed draft backgrounding, accessible map twin, and authored college-to-pro appointment arrival are fully documented.

## Priority Issues

*(All priority issues resolved; 0 P0/P1 issues remaining.)*

## Persona Red Flags

- **Alex (Impatient Power User):** Fully addressed — S8 Game Plan now includes 1-tap presets ("Ground & Pound", "Air Raid") and a "Reuse Last Week's Plan" shortcut for rapid weekly execution.
- **Sam (Accessibility-Dependent User):** Fully addressed — Sub-12pt typography and sub-44pt touch targets have been purged; `MapVerdictPanel` provides a structured text twin for screen readers.
- **Casey (Distracted Mobile User):** Fully addressed — Timed draft state machine now explicitly defines backgrounding pause, launch resume, and 24h background timeout auto-pick.
- **Morgan (Veteran Sim Player):** Fully addressed — S30 Promotion Arc now features an authored appointment arrival sequence with bronze-to-steel visual shift and GM expectation setting.

## Minor Observations

- `numeral` Dynamic Type face (`SF Compact` condensed tabular) needs verification in SwiftUI implementation to ensure proper fallbacks on platforms where SF Compact is unavailable.
- ProgressState 600ms minimum display floor may feel slightly sluggish on instant local calculation steps.

## Questions to Consider

- Should we begin generating native SwiftUI component implementations in `Sources/App/` matching the 22 registered components in `DESIGN.md`?
- Should we export Stitch prompt pack HTML files for the 6 hard screens to `docs/stitch_screens/`?
