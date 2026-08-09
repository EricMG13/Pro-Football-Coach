# Document Manifest

**Every document in this repository is listed here.** If a file is not on this list, it has no
standing — treat it as untriaged and ask before acting on it.

The rebuild changed the product: from a pro-only franchise sim with an arcade direct-control mode,
to a **unified college→pro career simulator in which the player never controls an athlete**. Most
of the prior documentation describes the abandoned product accurately and is therefore actively
misleading. Naming the canon is not enough while the anti-canon sits at a canonical path, so the
anti-canon has been moved.

Status values:

- **RETAINED** — canonical, or evidence that survives the rebuild. Trust it.
- **SUPERSEDED-BY `<path>`** — the subject still matters, the document does not. Read the successor.
- **ARCHIVED-TO `docs/archive/<path>`** — describes an abandoned product. History, not instruction.

---

## Canon — read these

| Path | Status | Notes |
|---|---|---|
| `CLAUDE.md` | RETAINED (rewritten) | Standing rules, stack, process, legal guardrail. Rewritten before any other deliverable because it contradicted the rebuild in three places. |
| `README.md` | RETAINED (rewritten) | Entry point. Previously pointed a cold reader at the abandoned executive plan. |
| `PRODUCT.md` | RETAINED (rewritten) | Audience, positioning, the market-gap argument, scope. Prior version archived. |
| `docs/01-RESEARCH.md` | RETAINED (extended) | Sections A–H carry forward verbatim; §6.0–§6.5 added. Nothing dropped. |
| `docs/02-GAME-DESIGN.md` | RETAINED (rewritten) | The game. Prior pro-only version archived. |
| `docs/03-MATCH-ENGINE.md` | RETAINED (new) | Play resolution, determinism, two-tier model, calibration harness. |
| `docs/03b-ARCHITECTURE.md` | RETAINED (new) | Modules, engine/UI boundary, saves, test architecture. |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | RETAINED (new) | Design system and screens, including the accessibility contract. Absorbs `DESIGN.md`. |
| `docs/04b-AUDIT-RUBRIC.md` | RETAINED (new) | The rubric every phase gate is scored against. |
| `docs/05-IMPLEMENTATION-PLAN.md` | RETAINED (rewritten) | Phases and gates. Prior pro-only version archived. |
| `docs/06-AUDIT-DISPOSITION.md` | RETAINED (new) | What `AUDIT.md`'s findings became. Path reused — see the note below. |
| `docs/OPEN-DECISIONS.md` | RETAINED (new) | D1–D13, each with a falsifier and a named instrument. |
| `docs/08-OPUS5-BUILD-PROMPT.md` | RETAINED (new) | Mission, done, phase-entry contract for a cold build session. |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | RETAINED (new) | Ship gate. Authored here; no such file previously existed. |
| `docs/DOC-MANIFEST.md` | RETAINED | This file. |

> **`06` is a reused number.** `docs/06-PLAYED-GAME-MODE.md` specified the direct-control arcade
> mode in detail. That mode is cut, and the number now belongs to the audit disposition. A reader
> who remembers "doc 06" from the old repo is remembering a document that no longer exists at that
> path.

## Evidence — retained because it is true about the past

| Path | Status | Notes |
|---|---|---|
| `docs/AUDIT.md` | RETAINED | A **UI-layer** audit of 17 files that explicitly excludes the engine, iPad, size classes and App Store review. It is evidence about *craft*, not about why the game was boring — do not cite 9/20 as a diagnosis of blandness. Its most transferable content is `## Patterns & Systemic Issues`. Dispositioned in `docs/06-AUDIT-DISPOSITION.md`. **Its internal path citations are as of 2026-08-09 and point at documents since archived** — they are left intact because rewriting a record of the past is worse than a stale link. |
| `docs/STATUS.md` | RETAINED | The honest state of the prior build: 224 tests, 13,226 assertions, the ten-season soak, the calibration bands, the cross-process determinism bug, the save-growth lesson, and Phase 4C's never-compiled status. Rewritten forward as the rebuild proceeds; the historical section is preserved. |

## Archived — abandoned product, kept for history

Everything below describes features the rebuild deliberately does not have. **Following any of it
will take you the wrong way.**

| Path | Status | Why |
|---|---|---|
| `docs/archive/00-EXECUTIVE-PLAN.md` | ARCHIVED | Master plan for the pro-only game. Its scope, phase sequence and definition of done are all superseded; mission and done now live in `docs/08-OPUS5-BUILD-PROMPT.md`. |
| `docs/archive/02-GAME-DESIGN-pro-only.md` | ARCHIVED | The pro-only GDD. Explicitly stated that "college mechanics are replaced by pro mechanics" — the exact inversion of the current product. Its cap, contract and progression sections informed the rewrite. |
| `docs/archive/03-ARCHITECTURE.md` | SUPERSEDED-BY `docs/03-MATCH-ENGINE.md` + `docs/03b-ARCHITECTURE.md` | One document tried to hold both the simulation design and the app architecture. The rebuild splits them, because the match engine is now the largest single design surface in the project. |
| `docs/archive/04-SCREENS-UI.md` | SUPERSEDED-BY `docs/04-UX-AND-DESIGN-SYSTEM.md` | Screen-by-screen spec for the pro-only app, with no design system of its own and no accessibility contract. |
| `docs/archive/05-IMPLEMENTATION-PLAN-pro-only.md` | ARCHIVED | Phased plan for the abandoned build. Its gate *shape* was sound and is carried forward; its content is not. |
| `docs/archive/06-PLAYED-GAME-MODE.md` | ARCHIVED | Specifies "On the Field" — drag-to-aim passing, a kick meter, carrier decisions. **The rebuild forbids direct control of any player.** This is the single most dangerous document in the repo for a cold reader and is the reason this manifest exists. |
| `docs/archive/DESIGN.md` | SUPERSEDED-BY `docs/04-UX-AND-DESIGN-SYSTEM.md` | The prior visual system. Maintaining a design system in parallel with the screen spec is how the two drift; there is now one home. Its token discipline, the Flat-Forever rule and the Measured-Surface rule carry forward. |
| `docs/archive/PRODUCT-pro-only.md` | ARCHIVED | Prior product truth. Its accessibility commitments are carried forward into the D12 contract — notably because the prior build scored 1/4 against them. |
| `docs/archive/plans/2026-08-09-phase-a-foundation.md` | ARCHIVED | Task plan for a phase of the abandoned build. |
| `docs/archive/plans/2026-08-09-arcade-all22.md` | ARCHIVED | Task plan for the all-22 arcade field. The **spatial model** in it is genuinely reusable — formations, routes against live coverage, per-matchup protection duels, run lanes, pursuit — and is cited in `docs/03-MATCH-ENGINE.md`. The direct-control layer wrapped around it is not. |
| `docs/archive/plans/2026-08-09-almanac-redesign.md` | ARCHIVED | Task plan for the almanac/records theme of the abandoned build. |

## Source

`Sources/`, `Tests/` and `App/` are **Tier C**: no authority, silence means rewrite. They remain in
the tree because the prior build is the highest-value evidence available about the actual failure
(see `docs/01-RESEARCH.md` §6.0) and because `docs/06-AUDIT-DISPOSITION.md` cites specific lines.
Nothing in them is binding on the rebuild.

The one exception worth stating: `docs/OPEN-DECISIONS.md` logs, per the brief's symmetry rule, what
is **lost** by rebuilding the engine rather than porting it. Rebuilding is the decision; it is not
free, and the register says so.
