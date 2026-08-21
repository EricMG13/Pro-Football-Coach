# Mock Reconciliation: Shell and Hierarchy Amendment

**Date:** 2026-08-22
**Status:** Approved design; pending document review
**Applies to:** Coaching HQ → Roster → Player Profile vertical slice

## Purpose

This amendment corrects the first implementation pass after review of the supplied UI references and the working screenshots. It replaces the left navigation rail with a single top navigator, restores the reference design system's visual depth, corrects typography, and makes team identity useful without inventing game data or behavior.

This document amends the presentation guidance in:

- `2026-08-21-mock-reconciliation-vertical-slice-design.md`
- `2026-08-21-hq-roster-player-mock-contract.md`

Where those documents conflict with this amendment on navigation, typography, material treatment, or screen hierarchy, this amendment wins. Their behavior-authority, omission-ledger, accessibility, and no-invention rules remain in force.

## Authority and invariants

The shipped game remains authoritative for facts, state, callbacks, navigation destinations, persistence, and simulation behavior. The references are a visual shell and hierarchy prompt, not a source of product truth.

The correction must:

- preserve existing routes, callbacks, read models, and state transitions;
- preserve production team and opponent logos exactly once when current assets and models supply them;
- never manufacture a logo, color, value, deadline, recommendation, trend, filter, or action;
- keep unsupported reference features omitted and recorded;
- reuse the current Floodlit design system and native SwiftUI behavior;
- keep the 844 × 390 landscape floor and AX5 accessibility behavior viable;
- preserve semantic color meanings and measured text contrast.

## Scope

### Global shared-shell change

Remove the left navigation rail from every management surface that uses the shared Floodlit stage. The top chrome becomes the only shared navigator.

This is one root composition change. Existing rail model/provider code may remain if removal is not required for compilation; unrelated cleanup is out of scope.

### Slice-only changes

The following are limited to Coaching HQ, Roster, and Player Profile:

- reference-scale typography;
- information hierarchy and panel composition;
- team-colored primary, secondary, and selected action treatments;
- reduction of duplicated team identity inside page content.

No other management screen receives a typography, action-color, or content redesign in this correction.

## Shared top navigator

At the 844-point reference width, the chrome occupies one approximately 34-point visual band beginning at the existing 63-point content gutter. It replaces both the old stacked header and the rail.

The band contains, left to right:

1. controlled-team identity: existing logo, short name, and record/context when supplied;
2. a family control with a chevron that opens the existing full surface registry;
3. direct sibling destinations for the current family, with the active route underlined;
4. existing right-side opponent or schedule context when supplied.

Rules:

- The family control is the route to the existing surface registry; it is not a new destination.
- Sibling destinations retain their existing callbacks and route semantics.
- Long sibling sets scroll horizontally inside their region instead of wrapping or shrinking below the approved type scale.
- The family control stays visible. Team and right-side context may truncate to one line before controls become unusable.
- Visual height may be 34 points while button hit regions remain at least 44 × 44 points and do not overlap.
- The active route uses a crisp underline/rule plus existing accessibility selection state; color alone is insufficient.
- The shared header must not repeat a team logo or announce a decorative logo separately.
- Standard and AX5 layouts use this same navigation model. Neither restores a side or bottom rail.

## Visual system

The approved examples retain the one-row chrome and action rules but use the existing Floodlit reference system rather than flat bordered cards.

Reuse the established components and tokens where they already fit:

- stadium-office world lighting and the existing world backdrop;
- receding field/grid seams, upper-right warm lamp bloom, vignette, and restrained grain;
- two deliberate panel depths rather than a uniform stack of equally weighted cards;
- existing cut-corner geometry, with a small leading cut and longer swept trailing cut;
- inset seams and highlights on primary surfaces;
- warm laminate accents where the current system already provides them;
- low-opacity team tint plus a crisp rule for selected rows;
- the existing palette for neutral and semantic states.

The result should feel dense, credible, deliberate, and alive. It must not introduce a second design system, glassmorphism, neon decoration, generic floating cards, or new texture assets.

## Typography

Use the current native design-system type helpers and Dynamic Type. Do not add Archivo Narrow, IBM Plex Mono, or any other bundled font solely to imitate the HTML reference. Native condensed display faces and tabular figures are the approved equivalents.

Reference sizes at the normal content-size category:

| Surface | Role | Reference size |
|---|---|---:|
| Shared chrome | Team identity | 15 pt |
| Shared chrome | Family and sibling routes | 10 pt |
| Shared chrome | Record and schedule context | 11 pt |
| Coaching HQ | Active task title | 16 pt |
| Coaching HQ | Explanatory prose | 12 pt |
| Coaching HQ | Metadata and labels | 9–11 pt |
| Roster | Column headers | 9 pt |
| Roster | Player rows | 13 pt |
| Roster | Ratings | 15 pt, tabular |
| Roster | Exception ribbon | 10–12 pt |
| Player Profile | Player name | 26 pt |
| Player Profile | Overall rating | 32 pt, tabular |
| Player Profile | Jersey number | 17 pt, tabular |
| Player Profile | Facts and evidence | 12–13 pt |
| Player Profile | Labels and routes | 9–10 pt |

These are design targets, not fixed-size accessibility clamps. AX5 scales and reflows into a coherent vertical scroll. Content must not be clipped merely to preserve the 390-point canvas.

## Coaching HQ: decision first

The HQ should answer “what requires my judgment now?” before summarizing the rest of the week.

Presentation order:

1. active mandatory task, including its authoritative deadline or consequence only when supplied;
2. available evidence and cost/impact context already present in the read model;
3. explicit choice selection followed by the existing commit action;
4. compact queue of remaining obligations;
5. kickoff context and only non-empty health or stakeholder signals;
6. exact advance blocker or completion receipt when the current state supplies it.

The active decision receives the deepest panel and strongest typographic emphasis. Secondary summaries recede. Do not add a hero task count, carousel, fabricated countdown, staff recommendation, local undo, or mock-only status.

## Roster: comparison first

The roster should support scanning, comparing, and choosing a player without turning normal health into repeated decoration.

Presentation order:

1. a compact exception ribbon based only on existing roster metrics and genuine exceptions;
2. a wide roster table paired with a selected-player dossier, targeting an approximate 68/32 split at the reference width;
3. one existing route from the dossier to the full profile.

Rules:

- Keep the dense table as the primary artifact.
- Use tabular figures for ratings and compact headers for columns.
- Keep healthy/default states visually quiet; reserve semantic colors for actual exceptions.
- Selection uses the controlled team's safest accent plus a non-color rule.
- The dossier prioritizes authoritative role, fit, availability/condition, concern, and trajectory fields when present.
- Do not add search, filters, sorting behavior, position-specific analysis, or derived rankings in this slice.

## Player Profile: evidence first

The profile should explain the current football judgment, not merely enlarge raw identity data.

Presentation order:

1. existing route bar/back action;
2. player identity, position, year, role, and availability;
3. overall rating as a strong but subordinate readout;
4. fit, staff judgment, concern, and trajectory evidence when authoritative;
5. existing evidence routes and callbacks only where their content/action is meaningful.

Rules:

- Do not repeat a team-only origin line when the shared chrome already establishes the team. Show hometown or other authoritative origin detail when present.
- Do not fabricate position-specific attributes or scouting explanations.
- An empty evidence state must not present a contradictory primary call to action. Preserve the existing callback where real development evidence makes the route meaningful.
- Preserve the truthful Back and Open accessibility semantics established by the original slice.

## Team identity and actions

Team identity is operational and restrained:

- The controlled team owns the shared identity block, active selection, and slice-level primary action.
- The opponent appears only in right-side contextual chrome when current data supplies it.
- Content panels remain neutral; do not wash whole screens in team color.
- Existing production logos are used as-is and never duplicated locally.

Action rules for the three slice screens:

- Primary: contrast-safe controlled-team primary fill, existing material depth/inset highlight, and measured foreground ink.
- Secondary: neutral deep surface with the safest team-color label or rule.
- Selected controls/rows: safest team accent plus underline, border, check, or other non-color state.
- Destructive: existing semantic red, never team color.
- Disabled: existing neutral disabled treatment.
- If generated team colors cannot meet the required contrast, fall back to the existing safe palette rather than weakening accessibility.

The global action component may accept existing team identity as an optional input, but screens outside this slice retain their current appearance.

## Accessibility and responsive behavior

- Preserve the 844 × 390 minimum landscape floor and current larger landscape widths.
- Keep all interactive hit targets at least 44 × 44 points.
- At AX5, use one coherent vertical reading/interaction flow with the first actionable content reachable near the top.
- Horizontal scrolling is reserved for the sibling route strip and dense roster table where necessary; it must not trap VoiceOver focus.
- Preserve VoiceOver labels, traits, selection state, and logical order.
- Respect Reduce Motion, Increase Contrast, Reduce Transparency, and Differentiate Without Color.
- Never rely on team color, rating color, or underline alone to convey state.

## Deferred and omitted

Record these as deliberate omissions rather than silent losses:

- roster search, filtering, and new sorting behavior;
- custom web-font assets;
- invented team/opponent logos or alternative logo placements;
- fabricated countdowns, recommendations, trends, receipts, or undo behavior;
- derived roster rankings and position-specific analysis;
- a global typography or team-action recolor outside the three-screen slice;
- redesign of every surface now reached through the top navigator;
- removal of dormant rail read-model/provider code unless required to complete the root composition change.

## Verification

Implementation is complete only when:

- the shared management stage renders no left or bottom navigation rail in standard or AX5 layouts;
- the one-row top chrome opens the existing surface registry and navigates among real sibling routes;
- team and opponent logos remain present exactly once wherever current data/assets supplied them before;
- the focused HQ → Roster → Player Profile → Roster route passes through the top navigator in default type and AX5;
- HQ, Roster, and Player Profile match the approved hierarchy, typography, material depth, and action rules without unsupported data;
- contrast is measured for representative team colors and the safe fallback is covered;
- screenshots are reviewed at 844 × 390, 852 × 393, and 956 × 440 in default type and AX5, with at least one light-appearance pass at the minimum width;
- the existing design-contract, accessibility, app, and focused UI-test lanes pass, apart from separately documented pre-existing failures;
- the omission ledger is updated with every deferred item above;
- manual VoiceOver, Voice Control, Switch Control, sound/haptics, and physical-device checks remain clearly marked until actually performed.

## Non-goals

This amendment does not authorize changes to simulation rules, persistence, save data, read-model derivation, routing destinations, or game content. It does not make the generated concept images production assets. It does not promise parity with unsupported HTML interactions.
