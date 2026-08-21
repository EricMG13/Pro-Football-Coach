# Mock Reconciliation: Shell and Hierarchy Amendment

**Date:** 2026-08-22
**Status:** Approved
**Applies to:** All 62 registered screen identities across the seven surface families

## Purpose

This amendment corrects the first implementation pass after review of the supplied UI references and the working screenshots. It replaces the left navigation rail with a single top navigator, restores the reference design system's visual depth, corrects typography, and makes team identity useful without inventing game data or behavior. The approved system now applies to the complete registered UI, not only the Coaching HQ → Roster → Player Profile proof slice.

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

The authoritative registry contains 62 screen identities. Fifteen are compatibility aliases or thin wrappers; 47 are canonical destinations. Completion is measured against all 62 identities, while implementation should change shared components and canonical destinations rather than duplicating work in wrappers.

The correction applies these rules system-wide:

- remove the left rail from every Floodlit surface and make top chrome the shared navigator;
- use the approved typography roles on every canonical screen;
- use the existing Floodlit material, lighting, panel-depth, and cut-corner language consistently;
- make controlled-team identity operational in actions and selection wherever a controlled team exists;
- adapt each canonical screen's information hierarchy to its real coaching task and authoritative data;
- reduce duplicated team/opponent identity inside page content;
- verify every alias still resolves to a corrected canonical destination.

This remains a presentation migration. Existing rail model/provider code may remain if removal is not required for compilation; unrelated cleanup is out of scope.

## Shared top navigator

At the 844-point reference width, the chrome occupies one approximately 34-point visual band beginning at the existing 63-point content gutter. It replaces both the old stacked header and the rail on every in-career surface.

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
- Pre-career and appointment surfaces use the same one-band material and typography but do not fabricate team identity or sideways family routes before those concepts exist.
- Compatibility aliases inherit the chrome of their canonical destination; they do not create a second navigation variant.

## Visual system

The approved examples establish the system-wide one-row chrome and action rules. Every canonical surface uses the existing Floodlit reference system rather than flat bordered cards.

Reuse the established components and tokens where they already fit:

- stadium-office world lighting and the existing world backdrop;
- receding field/grid seams, upper-right warm lamp bloom, vignette, and restrained grain;
- two deliberate panel depths rather than a uniform stack of equally weighted cards;
- existing cut-corner geometry, with a small leading cut and longer swept trailing cut;
- inset seams and highlights on primary surfaces;
- warm laminate accents where the current system already provides them;
- low-opacity team tint plus a crisp rule for selected rows;
- the existing palette for neutral and semantic states.

The result should feel dense, credible, deliberate, and alive across all seven families. Individual screens may use different compositions, but they must not introduce a second design system, glassmorphism, neon decoration, generic floating cards, or new texture assets.

## Typography

Use the current native design-system type helpers and Dynamic Type. Do not add Archivo Narrow, IBM Plex Mono, or any other bundled font solely to imitate the HTML reference. Native condensed display faces and tabular figures are the approved equivalents.

Reference roles at the normal content-size category:

| Role | Reference size | Use |
|---|---:|---|
| Chrome identity | 15 pt | Controlled team or pre-career product identity |
| Chrome route | 10 pt | Family control and sibling destinations |
| Chrome context | 11 pt | Record, week, opponent, or schedule context |
| Screen title / active decision | 16 pt | The current task, not a decorative page heading |
| Body | 12 pt | Explanatory prose and evidence |
| Dense row | 13 pt | People, teams, events, transactions, and comparable entities |
| Table / metadata label | 9–10 pt | Compact columns, status labels, and route labels |
| Standard figure | 15–17 pt, tabular | Ratings, scores, costs, ranks, counts, and jersey numbers |
| Major evidence figure | 26–32 pt, tabular | One justified focal datum on a dossier, live state, or decision |

Major figures are exceptional. A screen does not receive a hero number simply because a number is available. Coaching HQ, Roster, and Player Profile remain the calibration examples: task title 16; roster rows 13 and ratings 15; player name 26 and overall rating 32.

These are design targets, not fixed-size accessibility clamps. AX5 scales and reflows into a coherent vertical scroll. Content must not be clipped merely to preserve the 390-point canvas.

## System-wide information hierarchy

Each canonical destination must answer one dominant user question before presenting supporting inventory. Use the closest existing task archetype rather than forcing every screen into the same dashboard template:

| Archetype | Dominant object | Typical registered surfaces |
|---|---|---|
| Decision / workbench | Consequence, evidence, choice, commit | HQ tasks, plans, retention, contracts, cuts, promotion, realignment |
| Comparison / board | Exceptions, comparable rows, selected dossier | Roster, recruiting, scouting, free agency, staff, standings, leaders |
| Entity dossier | Identity, role, fit, evidence, history | Player, prospect, staff, team/programme |
| Timeline / feed | Newest or most consequential event and route | Inbox, schedule, news, aftermath, career line |
| Spatial / structural | Orientation, relationships, selected detail | Depth chart, league map, bracket, coaching tree |
| Live / event | Current state, leverage, controls, result | Match day, draft room, signing day, game detail |
| Entry / transaction | Current step, required input, consequence, confirmation | New career, appointment, offers, settings |

Family emphasis:

- **This week:** decision, deadline, preparation, opponent, and result.
- **Personnel:** comparison, role, fit, availability, development, and staff judgment.
- **Recruiting:** pipeline, commitment, contact limits, deadline, and class consequences.
- **Pro management:** constraint, cost, roster consequence, transaction, and draft/market state.
- **League:** orientation, standings, schedule, historical evidence, and notable change.
- **Career:** stakes, relationships, trajectory, opportunity, and irreversible choices.
- **Entry:** one clear step at a time without invented team context or unavailable navigation.

Every screen should use one dominant surface, one supporting depth, and quiet defaults. Repeated labels, decorative hero counts, duplicated identity, and routine green/red telemetry are removed unless they carry real decision value.

## Calibration screen: Coaching HQ

The HQ should answer “what requires my judgment now?” before summarizing the rest of the week.

Presentation order:

1. active mandatory task, including its authoritative deadline or consequence only when supplied;
2. available evidence and cost/impact context already present in the read model;
3. explicit choice selection followed by the existing commit action;
4. compact queue of remaining obligations;
5. kickoff context and only non-empty health or stakeholder signals;
6. exact advance blocker or completion receipt when the current state supplies it.

The active decision receives the deepest panel and strongest typographic emphasis. Secondary summaries recede. Do not add a hero task count, carousel, fabricated countdown, staff recommendation, local undo, or mock-only status.

## Calibration screen: Roster

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
- Do not add roster search, filters, new sorting behavior, position-specific analysis, or derived rankings. Existing controls on other screens remain authoritative.

## Calibration screen: Player Profile

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

- The controlled team owns the shared identity block, active selection, and primary actions across the registered UI.
- The opponent appears only in right-side contextual chrome when current data supplies it.
- Content panels remain neutral; do not wash whole screens in team color.
- Existing production logos are used as-is and never duplicated locally.

Action rules for all registered screens:

- Primary: contrast-safe controlled-team primary fill, existing material depth/inset highlight, and measured foreground ink.
- Secondary: neutral deep surface with the safest team-color label or rule.
- Selected controls/rows: safest team accent plus underline, border, check, or other non-color state.
- Destructive: existing semantic red, never team color.
- Disabled: existing neutral disabled treatment.
- If generated team colors cannot meet the required contrast, fall back to the existing safe palette rather than weakening accessibility.

The shared action component may accept existing team identity as an optional input. Teamless and pre-career surfaces use the existing safe neutral/gold palette. No screen derives a custom action palette locally when the shared resolver can supply it.

## Accessibility and responsive behavior

- Preserve the 844 × 390 minimum landscape floor and current larger landscape widths.
- Keep all interactive hit targets at least 44 × 44 points.
- At AX5, use one coherent vertical reading/interaction flow with the first actionable content reachable near the top.
- Horizontal scrolling is reserved for the sibling route strip and genuinely dense data canvases where necessary; it must not trap VoiceOver focus.
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
- new behavior added solely to fill a reference composition;
- bespoke per-screen chrome, typography systems, or action palettes;
- removal of dormant rail read-model/provider code unless required to complete the root composition change.

## Migration sequence

The implementation plan should land in reviewable family increments while keeping the shared root stable:

1. freeze the 62-identity / 47-canonical inventory and add failing shared-shell, typography-role, action-contrast, alias, and omission-ledger contracts;
2. correct the shared stage, one-row chrome, registry opener, type roles, team action resolver, and reusable panel materials;
3. migrate the complete **This week** family, using Coaching HQ as the decision-workbench calibration screen;
4. migrate the complete **Personnel** family, using Roster and Player Profile as comparison/dossier calibration screens;
5. migrate the complete **Recruiting** family;
6. migrate the complete **Pro management** family;
7. migrate the complete **League** family;
8. migrate the complete **Career** and **Entry** families, including intentional teamless/pre-career chrome;
9. verify all aliases, all accessibility cells, all routes, and the complete visual proof set before final audit.

Each family phase begins with a read-model/callback inventory and a short screen-by-screen hierarchy table. Anything in the reference without real backing is added to the omission ledger before presentation work begins.

## Verification

Implementation is complete only when:

- all 62 registered identities resolve to one of the 47 corrected canonical destinations, with no missing or visually divergent alias path;
- every Floodlit surface renders no left or bottom navigation rail in standard or AX5 layouts;
- every in-career canonical destination uses the one-row top chrome to open the existing surface registry and navigate among real sibling routes;
- pre-career and appointment surfaces use the same visual system without fabricated team or family state;
- team and opponent logos remain present exactly once wherever current data/assets supplied them before;
- the focused HQ → Roster → Player Profile → Roster route passes through the top navigator in default type and AX5;
- all 47 canonical destinations use an explicit task archetype, approved typography roles, deliberate panel depth, and truthful actions;
- all 62 registry identities remain covered by the existing accessibility reflow and reduce-motion matrices;
- contrast is measured for representative team colors, teamless states, and the safe fallback;
- every canonical destination receives a visual proof at 844 × 390 in default type and AX5;
- each family receives representative proofs at 852 × 393 and 956 × 440, plus Increase Contrast at the minimum width; Floodlit remains dark-only under `04` section 6.1a;
- the existing design-contract, accessibility, app, and focused UI-test lanes pass, apart from separately documented pre-existing failures;
- the omission ledger records unsupported or deliberately deferred reference features per canonical destination;
- manual VoiceOver, Voice Control, Switch Control, sound/haptics, and physical-device checks remain clearly marked until actually performed.

## Non-goals

This amendment does not authorize changes to simulation rules, persistence, save data, read-model derivation, routing destinations, or game content. It does not make the generated concept images production assets. It does not require 62 bespoke layouts when shared components, canonical destinations, and existing wrappers cover the registered paths. It does not promise parity with unsupported HTML interactions.
