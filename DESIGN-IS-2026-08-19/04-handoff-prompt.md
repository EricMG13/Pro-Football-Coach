```text
/make-plan Redesign Pro Football Coach's 62-screen information architecture and action-truth contract. Current design failed audit at 10/30 with critical gaps in principles #2 useful, #4 understandable, and #6 honest.

Verdict paragraph (quoted from 03-verdict.md):
> **REDESIGN — preserve the Floodlit visual system and the proven week/roster/recruiting/match compositions, but redesign the 62-screen information architecture and action-truth contract: at 10/30 with load-bearing zeros in usefulness, understandability, and honesty, too many named destinations do not perform their named task and repeated label/commit mismatches make refinement alone insufficient.**

Why redesign and not refine: the total is below the 20-point refine threshold and usefulness, understandability, and honesty each scored zero on a worst-screen basis, so local copy and styling patches cannot repair the information architecture.

Preserve from current design:
- Floodlit's dark palette, spacing/motion tokens, cut-corner geometry, and committing-action role in `Sources/ProFootballCoachUI/DesignTokens.swift:49-98,117-217,277-357`.
- The shared identity shell and progressive All Surfaces disclosure in `Sources/ProFootballCoachUI/CoachWorldFloodlitComposition.swift:44-199`, plus the proven task-specific Coaching HQ, Roster, Recruiting Board, and Match Day compositions.

Discard:
- Title-only and near-title-only route wrappers that present generic Career Hub, College Offseason, Pro Offseason, Pro Management, Staff Room, Game Plan, Depth Chart, or Competition Overview content as a distinct task. Evidence: `01-evidence.md#screen-by-screen-critique`. Caused failure on principles #2, #4, and #10.
- Generic Continue/Done gold actions and selection-row commits whose visible label does not name the actual navigation, time advance, financial consequence, or commit point. Evidence: `01-evidence.md#copy-and-honesty-evidence`. Caused failure on principles #4 and #6.

Top 3–5 moves from the audit (verbatim):
1. **Principles #2/#4/#10 — useful, understandable, and little:** collapse or remove every title-only destination until it owns a task-specific composition; start with Job Board, Offer, Staff Market, Scheme Book, Personnel Packages, Portal/NIL routes, pro markets, Job Security, and Coaching Carousel. Evidence: `01-evidence.md#screen-by-screen-critique`.
2. **Principle #6 — honest:** make every visible label name the actual transition and consequence—especially Continue, Into the game plan, Back to league, Release, row-selection commits, shortlist membership, and the Settings accessibility claim. Evidence: `01-evidence.md#copy-and-honesty-evidence`.
3. **Principles #3/#5 — aesthetic and unobtrusive:** reclaim the 844 × 390 pt content field by demoting noncommitting gold, reducing persistent chrome where task context already exists, giving League Map a protected dominant region, and repairing Match Day yard-number contrast. Evidence: `01-evidence.md#visual-evidence`.
4. **Principle #8 — thorough:** add first-class success and focus states, close Match Day transparency/contrast gaps, then render and exercise all 62 destinations across the 7,936-cell accessibility plan before calling the system complete. Evidence: `01-evidence.md#accessibility-evidence`.
5. **Principle #10 — as little design as possible:** remove duplicate navigation and dead surface API, and keep progressive disclosure only for destinations that can complete a distinct task in the current save state. Evidence: `01-evidence.md#structural-evidence`.

Redesign principles in priority order:
1. Principle #2 — useful — every retained destination completes the named task directly or is removed until it can.
2. Principles #4/#6 — understandable and honest — every route, control, cost, state, and transition says exactly what it will do before activation.
3. Principle #10 — as little design as possible — one destination per distinct task, one navigation owner, and committing emphasis only where the career state changes.

Deliverables for the plan:
- New information architecture (not derived from old)
- New primary flow (low-fi, labeled, compared side-by-side to current)
- States checklist (empty, loading, error, success, focus, disabled)
- Migration path for users currently on the old design
- Cutover criteria (when is the old design retired)

Anti-patterns to guard against (specific to REDESIGN):
- Porting old structure under new styling
- Keeping both designs behind a flag indefinitely
- Redesigning to follow a trend rather than the principles above
- Treating the Preserve list as optional — it must be filled before this handoff is valid
```
