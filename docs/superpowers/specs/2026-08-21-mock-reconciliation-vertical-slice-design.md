# Mock Reconciliation Vertical Slice

Date: 2026-08-21
Status: approved design

## Goal

Adapt the Claude Design UI and UX mocks into a production-quality vertical slice covering Coaching
HQ, Roster, and Player Profile. Preserve the mocks' visual hierarchy and interaction intent while
showing only data and behavior the current game actually supports.

The mocks are a visual and UX target, not an implementation or feature specification. Existing game
behavior remains authoritative. Mock-only features are omitted from production and recorded for
future reconsideration.

## Selected approach

Use contract-first adaptation. Before changing production UI, reconcile each visible mock region
against the current read models and actions. Give every region one disposition:

- **Keep** — current data and behavior support the mock directly.
- **Adapt** — the UX intent is valid, but the presentation must use current data or behavior.
- **Omit** — the required feature does not exist; do not show a placeholder or disabled promise.

This approach was selected over a strict mock port, which would preserve outdated assumptions, and a
current-UI reskin, which would not deliver the intended UX.

## Authority boundary

Current production code owns behavioral truth:

- Existing read models determine which facts may be shown.
- Existing intent callbacks determine which actions may be offered.
- Existing navigation, saves, and simulation behavior remain unchanged unless a separately approved
  product change explicitly revises them.

The mocks govern:

- Visual hierarchy and composition.
- Navigation and interaction patterns where current behavior can support them.
- Typography, spacing, colour, surfaces, controls, and feedback.

Generated mock code is reference material only. Do not port it wholesale or make it a runtime
dependency.

## Scope

The first proof contains one complete production route:

1. Coaching HQ
2. Roster
3. Player Profile

It includes the real navigation between these screens, their supported states, accessibility
behavior, and any shared presentation patterns genuinely repeated within the slice.

It excludes:

- Features represented in the mocks but absent from current read models or callbacks.
- Placeholder content, invented statistics, synthetic players, and speculative actions.
- Disabled "coming soon" controls.
- Changes to simulation, persistence, or save formats.
- A system-wide conversion of all 62 registered screen families.
- Shared abstractions created only for possible future screens.

## Reconciliation artifacts

### Mock contract matrix

Create one row for every meaningful mock region in the three screens. Each row records:

| Field | Meaning |
|---|---|
| Mock source | Mock file or screen and identifiable region |
| UX purpose | What the region helps the player understand or do |
| Current source | Existing read-model field, callback, or route that supports it |
| Disposition | Keep, adapt, or omit |
| Production treatment | Exact supported presentation or interaction |
| Accessibility notes | Reading order, label, value, focus, and reflow implications |

The matrix is completed before production UI edits begin. A region without a current source cannot
be marked Keep.

### Omission ledger

Every Omit disposition creates an entry with:

| Field | Meaning |
|---|---|
| Mock source | Where the omitted element appears |
| Element | The visible control, fact, state, or route |
| Intended behavior | What the mock implies it would do |
| Omission reason | Why current production cannot support it truthfully |
| Missing capability | The read model, domain feature, callback, or route required |
| Reconsideration trigger | A concrete condition that makes the item eligible for review |

The ledger is a record, not a roadmap. An entry creates no commitment to build the omitted feature.

### Proof checklist

Maintain a checklist covering reachability, real data, actions, visual comparison, supported states,
accessibility, and regression verification. The slice is not a reusable template until this checklist
passes.

## Screen contracts

### Coaching HQ

Coaching HQ presents the current week, the most important supported state, and truthful routes into
management tasks. Its hierarchy should answer what matters now and where the coach can act next.
Navigation labels name the actual destination or consequence.

### Roster

Roster supports dense player comparison, existing filtering and sorting, and player selection using
the current roster read model. It does not display mock statistics or status claims that have no
current source.

### Player Profile

Player Profile presents identity and current player evidence, with only supported actions and
destinations. A missing fact uses an honest absent or unavailable treatment when the screen still has
useful supported content; it is never replaced with invented data.

## Components

Reuse existing Floodlit tokens and shared SwiftUI components when they satisfy the approved mock
contract. Adapt a shared component when the existing abstraction already owns the relevant pattern.
Add a new shared component only when at least two places in this slice repeat the same semantic and
visual contract.

Screen-specific composition remains local to its screen. Do not create factories, parallel design
systems, compatibility layers, or configuration for values that do not vary.

## Data and interaction flow

`CoachWorldStore` and the existing providers continue to produce immutable UI read models. The app
root owns production navigation. The three views render those read models and return user input
through existing callbacks.

SwiftUI views may own only ephemeral presentation state such as selection, sorting, disclosure, and
focus. They do not import simulation state to derive missing facts, mutate domain state directly, or
infer features from the mocks.

## States and error handling

Each screen truthfully handles the states applicable to its current data flow:

- Populated
- Empty
- Unavailable
- Error
- Focused
- Disabled

Show loading only where a real asynchronous boundary exists. Recovery controls name and perform a
real recovery action. Unsupported mock features are omitted rather than represented as errors or
disabled controls.

## Verification

The slice passes only when:

- Coaching HQ, Roster, and Player Profile are reachable through the production app using a real
  generated career.
- Supported mock interactions execute through existing callbacks.
- Every unsupported mock element appears in the omission ledger.
- No visible fact lacks a traceable current read-model source.
- Existing simulation and save behavior remain unchanged.
- Visual comparison confirms the mocks' hierarchy and interaction intent; every intentional
  difference is documented in the contract matrix.
- The screens work at supported landscape widths of 844, 852, and 956 points.
- Default and AX5 content sizes retain readable hierarchy and usable controls.
- VoiceOver reading order and labels, Reduce Motion, Reduce Transparency, Increase Contrast, and
  Differentiate Without Color meet the existing project contract.
- Primary and irreversible targets meet the existing 44-point target requirement.
- Relevant focused checks and the repository's established verification gates pass.

## Rollout

Do not treat the slice as a miniature system-wide migration. Once its proof checklist passes, retain
only the patterns that were proven useful and reusable. Select the next vertical slice by feature
maturity and player value, then repeat the same reconciliation process.

An omitted feature returns for consideration only when its ledger trigger is satisfied and the
product change is separately approved. The presence of a mock remains insufficient authority.

## Completion criteria

- The mock contract matrix covers every meaningful region in all three source mocks.
- The omission ledger contains every unsupported element and a concrete reconsideration trigger.
- The three production screens implement their approved Keep and Adapt dispositions.
- The production route works with real game state and existing callbacks.
- The proof checklist passes without changing simulation, persistence, or save semantics.
- No speculative feature surface or unproven shared abstraction is introduced.
