# Document manifest

Written 2026-08-09 as Deliverable 0b of `docs/reviews/2026-08-09-spec-prompt-v4.md`.

This file is the authority on what is canon in this repo. Every document that existed before the
rebuild appears in the table below exactly once, classified and given a reason.

**The rule: a document not listed here as `RETAINED`, or written as one of the new canon documents
listed in [§4](#4-canon-paths-not-yet-written), carries no authority — whatever path it sits at.**
Files under `docs/archive/` are history, not specification.

This exists because a cold builder used to open `README.md`, read "Start here:
`docs/00-EXECUTIVE-PLAN.md`", and land in a plan for a different product — and could then find
`docs/06-PLAYED-GAME-MODE.md` specifying, in implementable detail, the direct player control the
current mission forbids. Naming the canon is not enough while the anti-canon sits at a canonical
path. The archival below has actually been performed with `git mv`; this manifest describes the true
state of the tree, not an intention.

## What the project is now, in one paragraph

A unified college→pro football **coaching** career simulator for iPhone. One save, one coach: start
in the college game, get promoted to the pro league. The player never controls a player during a
snap. The match is watched in a 2D SwiftUI `Canvas` view and shaped by preparation and decisions.
Every school, team, conference, city, stadium, player and coach is fictional and original. Governing
brief: `docs/reviews/2026-08-09-spec-prompt-v4.md`. Standing rules: `CLAUDE.md`.

---

## 1. How to read the three classifications

| Mark | Meaning | Where the old text lives |
|---|---|---|
| `SUPERSEDED-BY <path>` | A new document has **already been written at that same path**, replacing the old one in place. | Git history only. |
| `ARCHIVED-TO docs/archive/<path>` | The file has been moved out of the canon tree. Its old path is now empty (or will be re-occupied by a new document, named in the row). | `docs/archive/`. |
| `RETAINED` | Still at its path, still authoritative. | Unchanged. |

`SUPERSEDED-BY` is used **only** where the replacement exists now. Where a replacement is still to be
written, the pre-existing file is archived instead, so the canonical path is *empty* rather than
*wrong* while the package is being authored. An empty path makes a builder ask; a stale path makes a
builder build the wrong game.

## 2. The manifest

### Repository root

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `CLAUDE.md` | `SUPERSEDED-BY CLAUDE.md` | Rewritten in place as Deliverable 0. The old text asserted a pro-only scope, "College mechanics are replaced by pro mechanics", a 32-team league shape, and a doc map pointing at the arcade mode — all now false. Not archived: every session loads this file, so it must never be absent. | `CLAUDE.md` (current) |
| `README.md` | `SUPERSEDED-BY README.md` | Rewritten in place by this deliverable. Its "Start here" pointed at `docs/00-EXECUTIVE-PLAN.md`, and its one-line description sold a pro-only franchise sim. | `README.md` (current) |
| `PRODUCT.md` | `ARCHIVED-TO docs/archive/PRODUCT.md` | Positioning is built on a pro-only product and explicitly sells the "On the Field" arcade mode the mission forbids; its market-gap claim predates the research that must now produce it (§6.3 of the brief). | New `PRODUCT.md` — Deliverable 7 |
| `DESIGN.md` | `ARCHIVED-TO docs/archive/DESIGN.md` | The design system gets exactly one home, and it is not this file. Its tokens describe the "Coordinator's Clipboard" visual world, which the archived Almanac plan had already superseded, on a screen inventory that no longer applies. Explicitly **not** maintained in parallel. | `docs/04-UX-AND-DESIGN-SYSTEM.md` — Deliverable 5 |

### `docs/`

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/00-EXECUTIVE-PLAN.md` | `ARCHIVED-TO docs/archive/00-EXECUTIVE-PLAN.md` | The master plan for the discarded pro-only scope — 32 teams, live two-way play-calling, Phase 4B "On the Field". It was the repo's advertised entry point, which made it the most misleading file a cold builder could open. No new document takes the `00-` number. | Split: scope and positioning → `PRODUCT.md`; phases, gates and process → `docs/05-IMPLEMENTATION-PLAN.md`; definition of done → `docs/08-OPUS5-BUILD-PROMPT.md` |
| `docs/01-RESEARCH.md` | `RETAINED` | Tier B evidence. Sections A (reference-app screen inventory), B (the lineage), C and H (community signal), D (owner working patterns) and F (legal guardrails) carry forward. Extended, never replaced — see [§5](#5-required-edits-inside-retained-documents). | `docs/01-RESEARCH.md`, extended by Deliverable 1 |
| `docs/02-GAME-DESIGN.md` | `ARCHIVED-TO docs/archive/02-GAME-DESIGN.md` | Designs a different game: 32 fictional pro teams in 2 conferences × 4 divisions, no college tier, and "Every down is a decision" as the core loop — i.e. it silently resolves gate zero (agency density) in favour of every-snap play-calling, the exact question the rebuild must decide with arithmetic. | New `docs/02-GAME-DESIGN.md` — Deliverable 2 |
| `docs/03-ARCHITECTURE.md` | `ARCHIVED-TO docs/archive/03-ARCHITECTURE.md` | Number collision: `03` is now the match engine. Its content is also stale — module layout, save format and test mechanism are re-decided in D7 and D11, and it assumes a single pro league. | `docs/03b-ARCHITECTURE.md` — Deliverable 4 |
| `docs/04-SCREENS-UI.md` | `ARCHIVED-TO docs/archive/04-SCREENS-UI.md` | Number collision: `04` is now UX and the design system. Its screens are converted one-for-one from the pro-only scope and include play-calling and arcade surfaces that no longer exist. | `docs/04-UX-AND-DESIGN-SYSTEM.md` — Deliverable 5 |
| `docs/05-IMPLEMENTATION-PLAN.md` | `ARCHIVED-TO docs/archive/05-IMPLEMENTATION-PLAN.md` | Phases P0–P8 build the implementation Tier C discards, including P4B/4C arcade mode, and its gates cite bands and budgets that D3/D4 must re-derive from the college case. | New `docs/05-IMPLEMENTATION-PLAN.md` — Deliverable 8 |
| `docs/06-PLAYED-GAME-MODE.md` | `ARCHIVED-TO docs/archive/06-PLAYED-GAME-MODE.md` | **The most dangerous file in the repo for a cold builder.** It specifies direct player control — drag-aim passing, ball-carrier control, kick meter, all-22 arcade field — in enough detail to be built from. The mission forbids all of it. The `06-` number is now the audit disposition. | Nothing. The feature is out of scope. `docs/06-AUDIT-DISPOSITION.md` (Deliverable 9) takes the number |
| `docs/AUDIT.md` | `RETAINED` | Tier B evidence. A UI-layer audit of the discarded view code, so it is evidence about *craft*, not about why the game was boring. Its `Patterns & Systemic Issues` section, and the line *"the test's coverage boundary became the quality boundary"*, are design inputs for the rebuild. Read-only; dispositioned, not edited. | `docs/AUDIT.md`; disposition in `docs/06-AUDIT-DISPOSITION.md` |
| `docs/STATUS.md` | `RETAINED` | Tier B evidence and the live status document. Holds the calibration bands, the soak invariants, the bounded-save-growth lesson, the toolchain reality that D11 must answer to, and the record of Phase 4C shipping uncompiled. The builder keeps writing to it. | `docs/STATUS.md` |

### `docs/plans/`

All three plans expand phases of the archived implementation plan against code Tier C discards.
`docs/plans/` itself stays, empty: `CLAUDE.md` requires each new phase plan to be written there.

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/plans/2026-08-09-phase-a-foundation.md` | `ARCHIVED-TO docs/archive/plans/2026-08-09-phase-a-foundation.md` | Phase plan for audit fixes and Almanac tokens inside the discarded UI layer. Its accessibility and save-queue thinking is reusable knowledge; the tasks are not. | New phase plans under `docs/plans/`, from Deliverable 8 |
| `docs/plans/2026-08-09-almanac-redesign.md` | `ARCHIVED-TO docs/archive/plans/2026-08-09-almanac-redesign.md` | UI redesign of the pro-only build, whose own status line reads "awaiting owner approval. No build until the signal." That signal was never given, and the product it redesigns no longer exists. | `docs/04-UX-AND-DESIGN-SYSTEM.md` — Deliverable 5 |
| `docs/plans/2026-08-09-arcade-all22.md` | `ARCHIVED-TO docs/archive/plans/2026-08-09-arcade-all22.md` | The build plan for direct player control (Phase 4C): input traces, thumb grading, a controlled ball carrier. Forbidden by the mission. Its `SnapKernel`/`Canvas` rendering notes may inform D2 as prior art, but the control layer must not be revived. | Nothing. Rendering prior art only, with no authority |

### `docs/reviews/`

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/reviews/2026-08-09-spec-prompt-v4.md` | `RETAINED` | **The governing brief.** Owner parameters P1–P5, authority tiers, gate zero, the decision register and the deliverable list all live here. Where any other document disagrees with it, the other document is wrong. | `docs/reviews/2026-08-09-spec-prompt-v4.md` |
| `docs/reviews/2026-08-09-spec-prompt-v3-adversarial-review.md` | `RETAINED` | The review that produced v4. Retained so the reasoning behind v4's constraints is recoverable instead of looking arbitrary. Historical: it critiques v3, not the current brief. | `docs/reviews/2026-08-09-spec-prompt-v3-adversarial-review.md` |

## 3. Counts

| Classification | Count |
|---|---|
| `SUPERSEDED-BY` (rewritten in place) | 2 |
| `ARCHIVED-TO docs/archive/` | 11 |
| `RETAINED` | 5 |
| **Total pre-existing documents** | **18** |

Files created by this deliverable, which have no pre-rebuild predecessor: `docs/DOC-MANIFEST.md`
(this file) and `docs/archive/README.md` (a no-authority banner over the archive folder).

## 4. Canon paths

All of these now exist. Nothing was archived from any of these paths — they are new files, written
during the v4 execution.

| Path | Deliverable | Owns |
|---|---|---|
| `docs/02-GAME-DESIGN.md` | 2 | The game: core loop, the agency-model resolution, both tiers, the promotion arc, systems, stakes, onboarding, content volume |
| `docs/03-MATCH-ENGINE.md` | 3 | Play resolution, seeding and determinism contract, the abstracted off-screen model, the calibration harness, the soak |
| `docs/03b-ARCHITECTURE.md` | 4 | Module layout, engine/UI boundary and its enforcement, save architecture, test architecture |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | 5 | Design system from zero, screens, the match view, the accessibility contract |
| `docs/04b-AUDIT-RUBRIC.md` | 6 | Five dimensions, 0–4 anchors, P0–P3 severities, which dimensions are global |
| `PRODUCT.md` | 7 | Positioning, audience, the market-gap argument, v1 scope |
| `docs/05-IMPLEMENTATION-PLAN.md` | 8 | Phased build with per-phase gates |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | 8 | What must be true before a build goes out. Authored, never regenerated — no such file has ever existed here |
| `docs/06-AUDIT-DISPOSITION.md` | 9 | The 25 P0/P1s and the five systemic patterns, converted into named tests |
| `docs/OPEN-DECISIONS.md` | 10 | The D1–D14 register, each with an instrumented falsifier. D14 (build order and league size) was added during execution because P2 fixes *that* both tiers ship, not which is built first. **D11 is ESCALATED** |
| `docs/08-OPUS5-BUILD-PROMPT.md` | 11 | The phase-entry prompt. **Owns mission and definition of done** |

There is deliberately no `docs/00-*` and no `docs/07-*`. `00` was the old executive plan and is not
replaced; `07` never existed.

## 5. Required edits inside retained documents

`docs/01-RESEARCH.md` is retained, but two of its sections are not covered by the carry-forward list
and must be handled explicitly by Deliverable 1 rather than left to imply they still stand:

- **§E "Competitive positioning (one paragraph)"** — superseded by the new §6.3 market-gap argument,
  which must be an output of research rather than an assumption. Mark it superseded in place; do not
  delete it.
- **§G "Retro Bowl mechanics research (for doc 06)"** — its consumer, `06-PLAYED-GAME-MODE.md`, is
  archived and the feature is forbidden. Retain it as evidence about tactility and what direct
  control was substituting for, and label it plainly: **no longer specifies a shipping feature.**

Sections A, B, C, D, F and H carry forward verbatim or with additions only. Nothing in this file is
dropped silently.

## 6. Dangling references, knowingly left alone

- Retained and archived documents link to paths that moved. `docs/AUDIT.md` cites `DESIGN.md` and
  `docs/04-SCREENS-UI.md`; `docs/STATUS.md` cites `00-EXECUTIVE-PLAN.md` and
  `05-IMPLEMENTATION-PLAN.md`; `docs/01-RESEARCH.md` §G cites doc 06. All of those targets now live
  under `docs/archive/`. The links are **not** repaired: a historical record that has been quietly
  edited stops being a record. Resolve them by prefixing `docs/archive/`.
- `docs/01-RESEARCH.md` §A says the screen inventory was compiled from "all 68 screenshots in this
  folder". **No image files have ever been committed to this repository.** The tables in §A are the
  only surviving record of those screenshots; treat them as the primary artefact, and do not go
  looking for images that are not there.
- The empty directory `Pro-Football-Coach/` at the repository root is a stray, contains nothing, and
  is not tracked by git.

## 7. What about the source tree?

`Sources/`, `Tests/`, `App/`, `Package.swift` and `build/` are **Tier C: no authority**. They are the
prior implementation — a pro-only game with an arcade mode — and the rebuild does not carry them
forward by default. They are not documents, so they are not archived here; they are left in place as
readable prior art until `docs/05-IMPLEMENTATION-PLAN.md` says what happens to them.

Porting any of it requires a logged justification naming what would be lost by rebuilding it.
Discarding the simulation engine requires the same justification in the other direction, enumerated
against `docs/STATUS.md`: the calibration bands, the soak invariants, the cross-process determinism
fix, the bounded save growth, and the cap system's practice-squad defences. Rebuilding may well be
right. It is not free.
