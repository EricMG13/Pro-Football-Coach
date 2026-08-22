---
target: v2 reference designs within the chrome test browser. garner context from game development files.
total_score: 29
p0_count: 0
p1_count: 3
timestamp: 2026-08-10T16-55-09Z
slug: v2-reference-designs
---
---
target: v2 reference designs
total_score: 29
p0_count: 0
p1_count: 3
timestamp: 2026-08-10T16:55:00Z
slug: v2-reference-designs
---
# Impeccable Critique: v2 Reference Designs

Method: dual-agent (Assessment A: Design Review · Assessment B: Detector Scan & Browser Evidence)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Timed draft state machine and score bugs defined, but status tags use hardcoded hexes (#22482C, #2E4A5C) rather than semantic live chartreuse (#C6F24E). |
| 2 | Match System / Real World | 4 | Excellent domain fluency: 2D field canvas, desk vs broadcast registers, call-in decision cards, college NIL & portal mechanics. |
| 3 | User Control and Freedom | 3 | Strong refusal banners and offer controls; fast-forward hand-off mode lacks instant pause affordance on certain match views. |
| 4 | Consistency and Standards | 2 | Major drift: 1,011 detector findings across 16 files (696 un-tokenized colors, 192 off-scale radii, 81 font violations, 25 side-tab borders, 8 section eyebrows). |
| 5 | Error Prevention | 3 | Refusal banners state limit, resolution, and action link; 44x44pt touch regions enforced; literal colors create 25 potential kit-clash edge cases. |
| 6 | Recognition Rather Than Recall | 3 | S8 Game Plan caps visible decision items at <=4; dense data tables in Throughput-v2 rely on un-tokenized status tags. |
| 7 | Flexibility and Efficiency | 3 | ListControls and batch selection on roster/recruiting are strong; keyboard shortcuts for landscape desktop testing remain incomplete. |
| 8 | Aesthetic and Minimalist Design | 2 | Prohibited AI slop elements persist in v2 sheets: 25 side-tab colored accent borders (border-left: 3px solid) and 8 numbered section eyebrows (01/02/03). |
| 9 | Error Recovery | 3 | Actionable save failure recovery banners and draft resume states are present; Dynamic Type scaling preserves recovery controls. |
| 10 | Help and Documentation | 3 | Canonical DESIGN.md and PRODUCT.md published; text-twin fallbacks for canvas elements need strict token alignment. |
| **Total** | | **29/40** | **Acceptable; significant token drift and anti-pattern cleanup required.** |

## Anti-Patterns Verdict

**LLM assessment:** High tactical product specificity with strong game domain authenticities (desk vs broadcast registers, 2D field canvas, single-save career continuity). However, the v2 reference sheets retain several explicit AI slop tells: 25 side-stripe accent borders (`border-left: 3px solid`), 8 numbered section markers (`01 / 02 / 03`), 696 un-tokenized color hexes, and 192 off-scale border radii (4px, 6px, 16px, 9999px).

**Deterministic scan:** Detector scanned 16 visual reference files (`*-v2.dc.html`). Total findings: 1,011 (115 Warnings, 896 Advisories). Key rules triggered: `design-system-color` (696), `design-system-radius` (192), `design-system-font` (81), `side-tab` (25), `numbered-section-markers` (8), `em-dash-overuse` (6), `flat-type-hierarchy` (3).

**Visual overlays:** Live server running on port 8400 (PID 86746, token `9102c422-069c-4c02-95d3-57b196a763c7`). Detection overlay script `http://localhost:8400/detect.js` available for browser visualization.

## Overall Impression

The v2 reference design suite establishes a strong "Tactical Command Console" identity, but carries 1,011 automated detector violations and explicit anti-pattern violations (side-tab borders and numbered section markers). Transitioning from v2 to a clean, fully tokenized v3 reference suite is necessary to achieve full compliance with canonical `DESIGN.md`.

## What's Working

1. **Tactical Command Console Architecture:** Authentic dual-register hierarchy (Desk 12px radius vs Broadcast 0px radius) tailored for landscape iPhone mobile play.
2. **Game Pacing & Decision Loops:** S8 Game Plan and call-in decision cards keep working memory load <=4 items while supporting deep coaching mechanics.
3. **Consequence-Driven Decision Design:** 3-part refusal banners (limit, resolution, action link) ensure transparent feedback.

## Priority Issues

### [P1] Purge Prohibited Side-Tab Accent Borders (25 occurrences)
- **Why it matters:** `border-left: 3px solid` accent stripes are an explicit Impeccable absolute ban and AI slop giveaway.
- **Fix:** Replace side-tab borders with clean 1px full-seam borders (`surface.card` hairline) or subtle background fills.
- **Suggested command:** `$impeccable quieter`

### [P1] Eliminate Numbered Section Markers & Eyebrows (8 occurrences)
- **Why it matters:** `01 / 02 / 03` section markers read as generic AI scaffolding rather than intentional UI hierarchy.
- **Fix:** Remove decorative numbered eyebrows; use standard section titles or semantic badges.
- **Suggested command:** `$impeccable typeset`

### [P1] Tokenize 696 Literal Colors to DESIGN.md Palette
- **Why it matters:** Raw hexes (`#fff`, `#000`, `#22482C`, `#2E4A5C`) bypass dark/light mode switching and contrast contracts.
- **Fix:** Map all hardcoded colors to semantic tokens (`content.primary`, `surface.card`, `accent`, `live`, `rating.*`).
- **Suggested command:** `$impeccable extract` / `$impeccable colorize`

### [P2] Reconcile 192 Off-Scale Radii & 81 Font Declarations
- **Why it matters:** Arbitrary 4px/6px/16px radii and undeclared font families (`SF Compact Display`) break component consistency.
- **Fix:** Clamp all radii to `s 8px`, `m 12px`, `l 20px`, and standardize font stack to SF Pro / SF Compact Tabular.
- **Suggested command:** `$impeccable layout`

## Persona Red Flags

- **Alex (Impatient Power User):** 1-tap game plan presets exist, but dense roster tables lack quick-filter keyboard shortcuts.
- **Sam (Accessibility-Dependent User):** High contrast on primary tokens, but 696 un-tokenized literal colors threaten WCAG AA 4.5:1 compliance on dark elevations.
- **Coach Vance (Game-Sim Veteran Persona):** Needs instant visibility into coordinator tendency recommendations and call-in risk trade-offs without visual clutter.

## Minor Observations

- Em-dash overuse in microcopy (6 instances).
- Rating ladders need verification that `rating.average` (#2E7BC4) is never used as text foreground.

## Questions to Consider

- Should we run `$impeccable polish` across all 16 `*-v2.dc.html` sheets to auto-fix the 1,011 token and anti-pattern violations?
- Would you like to generate clean `v3` reference sheets with all 1,011 findings resolved?
