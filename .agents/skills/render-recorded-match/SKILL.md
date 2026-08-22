---
name: render-recorded-match
description: Build or review Pro Football Coach Match Day UI from an immutable recorded-outcome read model. Use for SwiftUI match presentation, field diagrams, score furniture, key-moment controls, staff interruptions, and tests where the UI must present simulation truth without running or mutating the football engine.
---

# Render Recorded Match

Build a presentation of an already-recorded match. Never create a second match engine in UI code.

## Source boundary

1. Read `Sources/ProFootballCoachUI/ScreenReadModels.swift` and use `MatchDayReadModel` as the only source of match facts.
2. Read `Sources/ProFootballCoachUI/DesignTokens.swift` before styling.
3. Pass user intent out through required closures. Do not mutate scores, clocks, possession, plays, actors, or outcomes in the view.
4. Keep fixtures under `#if DEBUG`. Never present sample values as a loaded career in release builds.
5. Treat a single read model as one recorded key moment, not a timeline. Do not animate the clock or actors without recorded frames supplied by a future read model.

## Required presentation

- Suppress management navigation during Match.
- Keep the full 120-yard field visible with both end zones.
- Render exactly 22 actors: 11 offense and 11 defense.
- Show line of scrimmage and first-down line from the read model.
- Use the read model's offense direction to label the defended end zones and validate that the
  first-down line is ahead of the line of scrimmage. Never infer direction from home/away colour.
- Foreground no more than three actors identified by the read model.
- Provide exactly five primary controls: Speed, Pause, Key Moments, Take Over, Tactics. Speed, Pause, and Key Moments may change presentation state only. Take Over and Tactics may emit intent for a future branch or route, but must not alter the recorded moment.
- Lead with a compact scorebug and one causal lower-third. Avoid desk chrome, cards, gradients, glow, and decorative broadcast effects.
- Treat staff call-ins as typed interruptions with Accept, Dismiss, and Inspect Evidence paths. Do not enable Accept until its model-owned cost or consequence is visible.

## Accessibility and adaptation

- Use native SwiftUI controls with 44pt minimum targets.
- Give field actors deterministic labels including side, role, and yard position; do not rely on colour alone.
- Keep score, clock, down-and-distance, lower-third, and controls outside the diagram accessibility group and order them deliberately.
- In accessibility sizes, preserve the whole field and move supporting text into a scrollable or inspectable surface; never delete outcome context.
- Verify light, dark, standard type, AX5, both landscape sensor sides, Reduce Motion, and VoiceOver order.

## Gate

Before approval, verify:

- the read model rejects invalid score/situation values, any actor count other than 22, any side count other than 11, out-of-bounds field positions, more than three foreground actors, or a control list other than the canonical five;
- offense and defense are derived only from `situation.possession`; the view never guesses from team colour or field direction;
- controls change presentation mode only or emit intent closures;
- no UI target imports engine state or writes simulation truth;
- native captures show both end zones, all 22 actors, both field lines, scorebug, causal lower-third, and five controls;
- the rubric in `docs/04b-AUDIT-RUBRIC.md` yields an Impeccable score of at least 31/40 with no P0/P1 findings.
