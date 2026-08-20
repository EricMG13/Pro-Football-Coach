# Floodlit All-Surfaces Cutover

Date: 2026-08-15  
Status: approved for implementation

## Goal

Apply the Floodlit presentation system from Claude Design project
`4067686f-89c3-4a54-8058-e696cd570f03` to all 62 registered SwiftUI screens while preserving the
existing information architecture, simulation boundaries, navigation and user actions.

The ten `*-v4.dc.html` reference sheets are the visual contract. Their 47 specimens define the
shared vocabulary used across production screens. The separate `match-sim.dc.html` and
`match-2d.dc.html` prototypes are excluded: their independent simulation engine has no repository
counterpart, and the existing Match Day flow remains authoritative.

## Approved decisions

- Use one atomic, system-first cutover. Do not maintain v3 and Floodlit as parallel systems.
- Floodlit is dark-only. Do not implement a light or derived day register, light-mode proofs or a
  user-facing appearance switch. The app keeps the Floodlit appearance when the system appearance
  changes.
- Use `.82` for deep-panel opacity. It is the lowest documented value that preserves 4.5:1 body-text
  contrast when a panel crosses a mown stripe and floodlight beam.
- Permit tracked 10 pt micro-labels as an explicit design-contract class. Body copy remains at least
  12 pt, and accessibility sizes reflow rather than shrink.
- Snap Floodlit's incidental gaps to the existing `4/6/8/12/16/20` spacing scale.
- Keep AX5, VoiceOver, Reduce Transparency, Reduce Motion, Differentiate Without Color, 44 pt
  primary and irreversible targets, and measured composited contrast as structural requirements.

## Architecture

The existing `CoachWorldScreenID` registry, application root, read-model providers, intent callbacks
and simulation modules remain unchanged except where a truthful presentation contract requires a
different label or explicit unavailable state.

Presentation changes begin in the existing shared layer: `DesignTokens.swift`,
`CoachWorldDeskComponents.swift`, the broadcast components and the smallest reusable additions
needed by multiple production screens. Views compose those shared primitives rather than carrying
local copies of Floodlit colours, geometry or effects.

Use two functional registers inside the single dark appearance:

- **DESK** for management work: a committed night world, cut-corner glass and opaque work surfaces,
  condensed headings, compact metadata and gold committing actions.
- **BROADCAST** for live sport and major events: square field geometry, team-colour identity,
  tabular scores and immediate television-sports composition.

Use native SwiftUI shapes, materials, accessibility APIs and SF Symbols. Add no package or runtime
dependency. No custom match engine is introduced.

## Shared component families

### Foundation

`Stage`, `WorldBackdrop`, `GlassPanel`, `CutCorner` and `GrainOverlay` own safe areas, the committed
world, the two permitted panel depths, asymmetric geometry and the fixed-seed texture. Reduce
Transparency retains the composition and depth order with opaque `world.work` and `world.raised`
fills, removes grain and blur, and preserves meaningful emission effects.

### Navigation and chrome

Route controls, committing and secondary actions, desk surfaces, blank identity plates and the
weekly world strip share one action hierarchy. Visible and spoken labels name the action performed
in the current state. Continue/advance furniture exposes blocking work rather than implying success.

### Dense information

Dense tables, column sets, list controls, rating rings and badges, status chips and role tokens use
tabular figures and stable alignment. Colour always repeats a printed number, word or symbol. Dense
visual rows may sit inside a 44 pt semantic control without inflating every cell.

### People and analytical readouts

Identity bands, delta marks, confidence and fog states, form lines, verdict lines, meters, opposed
bars, arc gauges, value rings, attribute dials and share bars display only retained read-model facts.
Ratings use the documented 40–99 ceiling. Missing engine evidence produces the reference's honest
degraded form, never a synthetic confidence, verdict or percentage.

### Week chronology

Agenda rows, the week grid, load-policy ladder and hub tiles present costed commitments in causal
order. The weekly surface states what blocks advancement and what the user can do to clear it.

### Match and event presentation

The score bug, lower third, call-in card, key-moments row, pennants and timeout marks restyle the
existing Match Day and event flows. They do not replace the current engine or change play resolution.

### System states

Empty, loading, error, interrupted, delegated, disabled, focused and successful states remain inside
their owning composition. Each state names the condition and, when recovery is possible, offers one
clear recovery action.

## Data and interaction flow

Immutable app read models remain the only source of visible simulation facts. Shared components
receive formatted values, state and existing callbacks; they do not import or derive `GameState`.
SwiftUI owns only ephemeral presentation state such as selection, sorting, expanded disclosure and
local focus.

Routes and actions retain their existing semantics. Presentation work may correct labels that do not
describe the action or remove claims unsupported by retained evidence, but it must not invent new
simulation outcomes. Irreversible decisions continue to expose exact costs and consequences before
commit.

## Migration

1. Land the ten exported v4 HTML sheets, their ten PNG renders and the approved canon changes.
2. Replace the central token, depth, shape, type and accessibility contracts.
3. Implement or adapt shared components in the existing registry families.
4. Convert all 62 registered screens by family, preserving their read models and callbacks.
5. Remove v3 references, contradictory light-register requirements and temporary compatibility
   paths in the same cutover.
6. Regenerate proofs and run the complete verification matrix.

The worktree already contains substantial user-owned changes. Every edit must preserve them. If an
overlap cannot be reconciled from current intent and history, stop instead of overwriting it.

## Verification

- Exercise all 62 registry entries; every entry must render a Floodlit production view or an honest
  unavailable state.
- Verify landscape widths 844, 852 and 956 pt at default and AX5 content sizes.
- Verify Reduce Transparency, Reduce Motion, Increase Contrast, Differentiate Without Color and
  VoiceOver reading order and labels.
- Measure dark-theme contrast against the actual composited ground and panel depths.
- Verify 44 pt primary and irreversible targets and keyboard/focus states.
- Add focused checks for shared primitives, approved micro-label handling, dark-only appearance and
  registry coverage.
- Run existing contract, accessibility, simulator and full repository verification suites.
- Run GitNexus change detection and review every affected execution flow before completion.

## Completion criteria

- The ten v4 reference sheets and renders are present and agree with canon.
- The approved `.82`, 10 pt micro-label, six-value spacing and dark-only decisions are canonical and
  implemented.
- All 62 registered screens use the Floodlit system or an explicit honest unavailable state.
- No production v3 token, retired violet-system or light-register dependency remains.
- Existing navigation, actions, save data and simulation behavior remain intact.
- Automated checks pass and manual-only accessibility/device checks are recorded explicitly.

## Excluded

- The Claude Design project's independent match-simulation engine.
- Portrait, iPad, Mac and light/day compositions.
- New simulation features, speculative data, remote assets or third-party UI packages.
- Unrelated refactoring outside the presentation cutover.
