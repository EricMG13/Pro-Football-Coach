---
target: HQ → Roster → Player Profile information hierarchy and team identity
total_score: 20
p0_count: 0
p1_count: 4
timestamp: 2026-08-21T22-03-00Z
slug: docs-proofs-mock-reconciliation-vertical-slice
---
# Vertical Slice UX/UI Critique

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of system status | 2 | Active routes and disabled Advance are visible, but commit receipts, undo, and blockers are weak. |
| 2 | Match system / real world | 3 | Football vocabulary is strong; some generated and repeated copy feels mechanical. |
| 3 | User control and freedom | 2 | Back navigation exists, but standard HQ choices commit immediately without visible undo. |
| 4 | Consistency and standards | 2 | Rail, two-row chrome, local routes, and differing standard/AX5 action semantics compete. |
| 5 | Error prevention | 2 | Constraints help, but high-stakes HQ choices lack a consistent preview-then-commit step. |
| 6 | Recognition rather than recall | 3 | Controls are labelled; truncation and hidden registry access add recall burden. |
| 7 | Flexibility and efficiency | 2 | Roster sorting helps, but 105 players lack a fast position/status filter. |
| 8 | Aesthetic and minimalist design | 2 | The atmosphere is credible, but hero counts, repeated labels, glass panels, and status colour create noise. |
| 9 | Error recovery | 1 | No clear recovery path is visible for a committed weekly decision. |
| 10 | Help and documentation | 1 | Evidence exists, but difficult decisions lack concise contextual explanation. |
| **Total** | | **20/40** | **Acceptable; significant improvements remain.** |

## Anti-Patterns Verdict

The current slice is football-specific enough to avoid a generic dashboard at first glance, but it drifts into a familiar premium-dark sports treatment: oversized hero figures, repeated tiny uppercase labels, rounded panels, global gold actions, and routine red/green status colour. The reference shell was followed more closely than its information logic was adapted.

The deterministic detector scanned `CoachingHQView.swift`, `RosterView.swift`, `PlayerProfileView.swift`, `FloodlitChrome.swift`, and `CoachWorldFloodlitComposition.swift` exactly once. It exited 0 with `[]`: zero rule findings and no false positives. This does not contradict the design review; the main issues are hierarchy and task framing rather than detector-recognizable code patterns.

No browser overlay was available because the target is native SwiftUI. Six 844x390 proof PNGs provided the visual fallback. They objectively confirm a seven-item rail, a two-row header, 709pt content width, widespread truncation, global gold primary actions, and AX5 layouts whose first viewport often omits the main task.

## Overall Impression

The product vocabulary and underlying read models feel like a real football management sim. The strongest opportunity is to stop presenting those models as a dashboard inventory and instead make each screen answer one coaching question: what must I decide, who am I comparing, or what should I believe about this player?

## What's Working

1. The roster table, fit, condition, academic year, availability, staff evidence, and weekly obligations are specific and credible.
2. Native condensed type, tabular figures, measured colour contrast, VoiceOver labels, selected traits, 44pt targets, and honest empty states are strong foundations.
3. The roster table plus selected-player dossier is the best expert composition in the slice; removing the rail gives it the density the reference intended.

## Priority Issues

### P1 — Shared navigation consumes the scarce landscape frame

The rail duplicates family navigation, forces content to x=115, truncates names, and becomes a second fixed navigator at AX5. Remove it globally. Use one 34pt band at x=63 and width=761 with the controlled team identity once, a family navigator opening the existing registry, horizontally scrollable sibling routes, and right-side context/opponent identity once.

### P1 — AX5 is scrollable but not task-usable

The first viewport shows oversized summaries instead of the first decision, roster row, or evidence panel. Build deliberate AX5 summaries: active HQ decision first, one compact roster status sentence before rows, and compact player identity before the active evidence route. Use one content scroll below the top navigator and no bottom rail.

### P1 — Coaching HQ leads with inventory rather than judgment

The open count and obligation carousel outrank the decision, consequence, and deadline. Lead with the riskiest or earliest mandatory decision using only existing truthful fields: title, deadline, consequence/evidence, cost, choices, explicit commit, receipt, and undo where supported. Put the remaining obligations in an ordered compact queue; keep kickoff and changed health/stakeholder signals secondary.

### P1 — Roster and Profile expose data without enough football judgment

The table is too narrow, routine availability shouts green, and the profile's large overall dial outranks fit, role, concern, and trajectory. Add a compact local position/status filter over the existing roster rows; quiet healthy defaults and emphasize exceptions. Reduce the profile dial toward the reference scale and prioritize role, availability, fit, concern, staff evidence, and recorded development before exhaustive attributes.

### P2 — Team identity is decorative rather than operational

Team chrome, global gold actions, green selection, and red/green ratings compete. Resolve slice actions from the existing team identity: contrast-safe primary fill and ink; neutral secondary action with the safest team-colour label/rule; semantic destructive red; neutral fallback. Reserve opponent colour for opponent context and semantic colours for genuine exceptions.

## Persona Red Flags

### Alex — Power user

- A 105-player roster has sortable columns but no quick position/status filter.
- Five visible rows and truncated names slow comparison.
- Duplicate navigation consumes the space experts need for data.
- HQ one-tap commit is fast but unsafe, while AX5 uses a different selection model.

### Sam — Accessibility-dependent user

- Semantics and touch-target foundations are strong.
- AX5 buries the first useful action below oversized summaries and fixed navigation.
- Truncated destination and attribute labels are harder to recover under low vision.
- Excess routine red/green creates cognitive noise even when text provides a second cue.

### Lee — Experienced mobile football-sim coach

- An open count does not identify the decision most likely to hurt Saturday.
- Undifferentiated option consequences make the world feel untrustworthy.
- Repeated default stakeholder and availability values feel like telemetry, not judgment.
- A profile led by a large overall number does not answer whether the player fits the required role.

## Minor Observations

- Duplicate week and roster-count copy should be removed.
- `All Tas…` is not an acceptable navigation label.
- `Open full dossier` is ambiguous inside an already-visible dossier.
- `Open development evidence` contradicts an empty evidence state.
- The profile repeats team context already established by shared chrome.
- Loading, saved, error, and undo states are not evidenced in the current proofs.

## Questions to Consider

1. If HQ could show only one object before kickoff, should it be an open count or the riskiest unmade decision?
2. Does `Available` need green ink on every row, or should only exceptions speak?
3. Should overall rating lead every player profile, or should role, fit, and evidence lead the judgment?
4. Should team colour decorate the shell, or identify the moments when the coach acts for the club?
