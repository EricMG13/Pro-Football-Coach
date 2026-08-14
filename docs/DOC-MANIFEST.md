# Document manifest

Written 2026-08-09 as Deliverable 0b of `docs/reviews/2026-08-09-spec-prompt-v4.md`.

This file is the authority on what is canon in this repo. Every document that existed before the
rebuild appears in the table below exactly once, classified and given a reason.

**The rule: a document not listed here as `RETAINED`, or written as one of the new canon documents
listed in [§4](#4-canon-paths), carries no authority — whatever path it sits at.**
**As of 2026-08-10 there is no archive.** Everything previously held there was deleted; see §1.

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
| **DELETED** | Gone from the tree. Its old path is empty, or re-occupied by a new document named in the row. | Git history. |
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
| `PRODUCT.md` | **DELETED**, as was the later gate-2 rewrite `PRODUCT-primetime.md` | Positioning is built on a pro-only product and explicitly sells the "On the Field" arcade mode the mission forbids; its market-gap claim predates the research that must now produce it (§6.3 of the brief). | New `PRODUCT.md` — Deliverable 7 |
| `DESIGN.md` | **DELETED** | The design system gets exactly one home, and it is not this file. Its tokens describe the "Coordinator's Clipboard" visual world, which the archived Almanac plan had already superseded, on a screen inventory that no longer applies. Explicitly **not** maintained in parallel. | `docs/04-UX-AND-DESIGN-SYSTEM.md` — Deliverable 5 |

### `docs/`

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/00-EXECUTIVE-PLAN.md` | **DELETED** | The master plan for the discarded pro-only scope — 32 teams, live two-way play-calling, Phase 4B "On the Field". It was the repo's advertised entry point, which made it the most misleading file a cold builder could open. No new document takes the `00-` number. | Split: scope and positioning → `PRODUCT.md`; phases, gates and process → `docs/05-IMPLEMENTATION-PLAN.md`; definition of done → `docs/08-OPUS5-BUILD-PROMPT.md` |
| `docs/01-RESEARCH.md` | `RETAINED` | Tier B evidence. Sections A (reference-app screen inventory), B (the lineage), C and H (community signal), D (owner working patterns) and F (legal guardrails) carry forward. Extended, never replaced — see [§5](#5-required-edits-inside-retained-documents). | `docs/01-RESEARCH.md`, extended by Deliverable 1 |
| `docs/02-GAME-DESIGN.md` | **DELETED** | Designs a different game: 32 fictional pro teams in 2 conferences × 4 divisions, no college tier, and "Every down is a decision" as the core loop — i.e. it silently resolves gate zero (agency density) in favour of every-snap play-calling, the exact question the rebuild must decide with arithmetic. | New `docs/02-GAME-DESIGN.md` — Deliverable 2 |
| `docs/03-ARCHITECTURE.md` | **DELETED** | Number collision: `03` is now the match engine. Its content is also stale — module layout, save format and test mechanism are re-decided in D7 and D11, and it assumes a single pro league. | `docs/03b-ARCHITECTURE.md` — Deliverable 4 |
| `docs/04-SCREENS-UI.md` | **DELETED** | Number collision: `04` is now UX and the design system. Its screens are converted one-for-one from the pro-only scope and include play-calling and arcade surfaces that no longer exist. | `docs/04-UX-AND-DESIGN-SYSTEM.md` — Deliverable 5 |
| `docs/05-IMPLEMENTATION-PLAN.md` | **DELETED** | Phases P0–P8 build the implementation Tier C discards, including P4B/4C arcade mode, and its gates cite bands and budgets that D3/D4 must re-derive from the college case. | New `docs/05-IMPLEMENTATION-PLAN.md` — Deliverable 8 |
| `docs/06-PLAYED-GAME-MODE.md` | **DELETED** | **The most dangerous file in the repo for a cold builder.** It specifies direct player control — drag-aim passing, ball-carrier control, kick meter, all-22 arcade field — in enough detail to be built from. The mission forbids all of it. The `06-` number is now the audit disposition. | Nothing. The feature is out of scope. `docs/06-AUDIT-DISPOSITION.md` (Deliverable 9) takes the number |
| `docs/AUDIT.md` | `RETAINED` | Tier B evidence. A UI-layer audit of the discarded view code, so it is evidence about *craft*, not about why the game was boring. Its `Patterns & Systemic Issues` section, and the line *"the test's coverage boundary became the quality boundary"*, are design inputs for the rebuild. Read-only; dispositioned, not edited. | `docs/AUDIT.md`; disposition in `docs/06-AUDIT-DISPOSITION.md` |
| `docs/STATUS.md` | `RETAINED` | Tier B evidence and the live status document. Holds the calibration bands, the soak invariants, the bounded-save-growth lesson, the toolchain reality that D11 must answer to, and the record of Phase 4C shipping uncompiled. The builder keeps writing to it. | `docs/STATUS.md` |

### `docs/` — the branch reconciliation, added 2026-08-09

**Why these were not in the table above.** This manifest was written on a branch, against the tree it
could see. `main` had meanwhile carried the *earlier* hybrid-rebuild program — a pro-only, 32-team
game with a played-game mode — twenty-two commits further on. Merging the two put files
at canonical `docs/` paths that this manifest classified nowhere — 26 moved by `git mv`, plus two
saved under new archive names, plus `PRODUCT.md`, whose main-side revision existed in no file and had
to be recovered from history separately, which under its own rule means they
carried no authority while sitting exactly where a cold builder would look. That is the failure this
file exists to prevent, so they are classified here and moved.

Owner decision, 2026-08-09: **superseded — archive it.** Nothing is deleted.

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/07-SALVAGE.md` | **DELETED** | The earlier program's salvage ledger, written against the pro-only v1. v4 re-does the same job in both directions — a logged reason to port *and* a logged reason to discard — from the current mission. | `docs/PORT-LOG.md` |
| `docs/research/R1a-madden-franchise.md` | **DELETED** | Reference dossier for the earlier program. Its ground is re-covered from the current scope, with per-claim sourcing and a standing-caveat register the dossiers do not carry. | `docs/01-RESEARCH.md` §6.2A |
| `docs/research/R1b-retro-bowl.md` | **DELETED** | Same. | `docs/01-RESEARCH.md` §6.2B |
| `docs/research/R1c-football-manager.md` | **DELETED** | Same, and narrower than what replaced it: §6.1 separates FM Mobile from desktop FM, which conflating is the main error in this area. | `docs/01-RESEARCH.md` §6.1, §6.6 |
| `docs/research/R1d-adjacent-and-feel.md` | **DELETED** | Same. | `docs/01-RESEARCH.md` §6.2A, §6.2B |
| `docs/research/R2-synthesis.md` | **DELETED** | Produced the six Experience Pillars and the parity rule, both written for the pro-only scope. The market argument it asserts is re-derived as an *output* in §6.3 rather than assumed. | `docs/01-RESEARCH.md` §6.3; `PRODUCT.md` |
| `docs/design/briefs/00-system.md` … `07-coach.md` (8 files) | **DELETED** | Per-screen briefs for the pro-only screen set, including front office and draft surfaces shaped by a 32-team league with no college tier. The design system they build on is the Primetime/Broadcast skin, which `04` replaces from zero. | `docs/04-UX-AND-DESIGN-SYSTEM.md` §4 |
| `docs/design/mockups/*.dc.html`, `02-hub-storyboard-selection.png` (12 files) | **DELETED** | Twelve owner-approved frames — real signed-off evidence, and the reason this row says archived rather than deleted. They are approvals of a **different product's** screens under a design system `04` does not inherit, so they cannot be canon; they remain readable as evidence of what the owner liked. | `docs/04-UX-AND-DESIGN-SYSTEM.md`; the approvals themselves carry no authority over the new screen set |
| `docs/OPEN-DECISIONS.md` (main's) | **DELETED** | **Not an older version of the file at that path — a different document that shares it.** Main's is the **OD-1…OD-5** owner-decision log from the three signed-off rebuild gates, two of its entries still open; v4's is the D1–D14 register. The OD rulings are real owner decisions and are preserved under their own name rather than lost to a conflict resolution. | `docs/OPEN-DECISIONS.md` (D1–D14) is canon; the OD log is history |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` (main's) | **DELETED** | Same situation. Main's is the outstanding-work list from the Broadcast skin critique (8 assessors, 87 issues) against a tree that P0 deletes. Retained as evidence about craft, like `AUDIT.md`. | `docs/PRE-DEPLOYMENT-CHECKLIST.md` (v4's) |

**Three of main's canonical files were already classified above and needed no new row** —
`DESIGN.md`, `docs/03-ARCHITECTURE.md` and `docs/04-SCREENS-UI.md` were archived on this branch
before the merge, and the merge kept them archived rather than resurrecting them. Verified, not
assumed.

### `docs/plans/`

All three plans expand phases of the archived implementation plan against code Tier C discards.
`docs/plans/` itself stays: `CLAUDE.md` requires each new phase plan to be written there. It now
holds `docs/plans/2026-08-09-p0-foundation.md`, written against P0 of the current implementation
plan — the first plan in this directory that belongs to the rebuild rather than to what it replaced.

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/plans/2026-08-09-phase-a-foundation.md` | **DELETED** | Phase plan for audit fixes and Almanac tokens inside the discarded UI layer. Its accessibility and save-queue thinking is reusable knowledge; the tasks are not. | New phase plans under `docs/plans/`, from Deliverable 8 |
| `docs/plans/2026-08-09-almanac-redesign.md` | **DELETED** | UI redesign of the pro-only build, whose own status line reads "awaiting owner approval. No build until the signal." That signal was never given, and the product it redesigns no longer exists. | `docs/04-UX-AND-DESIGN-SYSTEM.md` — Deliverable 5 |
| `docs/plans/2026-08-09-arcade-all22.md` | **DELETED** | The build plan for direct player control (Phase 4C): input traces, thumb grading, a controlled ball carrier. Forbidden by the mission. Its `SnapKernel`/`Canvas` rendering notes may inform D2 as prior art, but the control layer must not be revived. | Nothing. Rendering prior art only, with no authority |

### `docs/reviews/`

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `docs/reviews/2026-08-09-spec-prompt-v4.md` | `RETAINED` | **The governing brief.** Owner parameters P1–P5, authority tiers, gate zero, the decision register and the deliverable list all live here. Where any other document disagrees with it, the other document is wrong. | `docs/reviews/2026-08-09-spec-prompt-v4.md` |
| `docs/reviews/2026-08-09-spec-prompt-v3-adversarial-review.md` | `RETAINED` | The review that produced v4. Retained so the reasoning behind v4's constraints is recoverable instead of looking arbitrary. Historical: it critiques v3, not the current brief. | `docs/reviews/2026-08-09-spec-prompt-v3-adversarial-review.md` |

### UI-reference correction, 2026-08-11

Owner decision: **The Film Room is a location, not the product's global design language.** The
rendered libraries passed mechanical and accessibility checks while repeating one management-app
chassis across unrelated football tasks. Keeping the inputs beside canon would make that rejected
answer easier to rebuild than the approved one, so they are deleted rather than archived.

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `*-v2.dc.html` (16 root sheets) | **DELETED** | Historical rendered reference library; generic two-pane/card composition, stale screen count and parallel design authority. Replaced 2026-08-12 by the owner-approved `*-v3.dc.html` sheets (see §4a). | `docs/04-UX-AND-DESIGN-SYSTEM.md`; `*-v3.dc.html` |
| `design.md` | **DELETED** | Parallel token/design-system restatement derived from the rejected sheets. | `docs/04-UX-AND-DESIGN-SYSTEM.md` |
| `docs/briefs/2026-08-10-claude-design-ui-brief.md` | **DELETED** | Commissioned the two-pane rendered library and treated repeatable component cards as the visual-design goal. | Git history only |
| `docs/briefs/2026-08-10-google-stitch-prompt-pack.md` | **DELETED** | Prompted the same 38/62 chassis, DESK register and 2 pt identity treatment at scale. | Git history only |
| `docs/stitch_screens/` | **DELETED** | Generated implementation of the rejected prompt pack. | Git history only |
| `docs/plans/2026-08-10-reference-uplift.md` | **DELETED** | Plan for refining rather than replacing the rejected reference language. | `docs/05-IMPLEMENTATION-PLAN.md` |
| `docs/reviews/2026-08-10-v2-reference-library-critique.md` | **DELETED** | Useful mechanical findings but a misleading positive product judgement against the wrong direction. | `docs/04b-AUDIT-RUBRIC.md` |
| `docs/HANDOFF-2026-08-10.md` | **DELETED** | Stale handoff that told a cold builder to restart an obsolete phase sequence and pointed at the rejected rendered library. | `docs/STATUS.md` and the master roadmap |
| `DESIGN-IS-2026-08-10/` and `impeccable report.md` | **DELETED** | Parallel scorecards that could certify the rejected library without testing game fantasy. | `docs/04b-AUDIT-RUBRIC.md` |
| `scripts/export_existing_screens.py`, `scripts/export_stitch_html.py` | **DELETED** | Generators whose only output is the rejected reference material. | Nothing |

The separate unversioned 34-screen Film Room gallery was also removed from the active visualisation
workspace. Its replacement is a deliberately narrow three-screen **Coach's World** proof package;
proof code carries no canonical or production authority.

## 3. Counts

| Classification | Count |
|---|---|
| `SUPERSEDED-BY` (rewritten in place) | 2 |
| **DELETED** — original pass | 11 |
| **DELETED** — branch reconciliation, 2026-08-09 | 28 |
| `RETAINED` | 5 |
| **Total documents classified** | **46** |

**Superseded 2026-08-10.** The counts and the `git ls-files docs/archive` check below were
written when the anti-canon was archived rather than deleted. There is no archive now, so
the check is `git ls-files docs/archive | wc -l` returning **0**. What each deleted file was,
and why it went, is the table above — that is the part worth keeping.


Files created by this deliverable, which have no pre-rebuild predecessor: `docs/DOC-MANIFEST.md`
(this file).

## 4. Canon paths

All of these now exist. **Five of them replaced a document that was archived from the same path** —
`02-GAME-DESIGN.md`, `05-IMPLEMENTATION-PLAN.md`, `PRODUCT.md`, `PRE-DEPLOYMENT-CHECKLIST.md` and
`OPEN-DECISIONS.md` each have an `ARCHIVED-TO` row in §2 above. The rest are genuinely new. An
earlier version of this preamble said nothing was archived from any of these paths; that was wrong,
and it mattered, because it invited a reader to conclude the archive held no earlier version of a
file it does hold.

**These paths carry authority.** §2's `RETAINED` mark is one route to authority; being listed in this
table is the other. A restatement of the rule that mentions only `RETAINED` strips authority from
every document below, which is the opposite of what this manifest is for.

| Path | Deliverable | Owns |
|---|---|---|
| `docs/02-GAME-DESIGN.md` | 2 | The game: core loop, the agency-model resolution, both tiers, the promotion arc, systems, stakes, onboarding, content volume |
| `docs/03-MATCH-ENGINE.md` | 3 | Play resolution, seeding and determinism contract, the abstracted off-screen model, the calibration harness, the soak |
| `docs/03b-ARCHITECTURE.md` | 4 | Module layout, engine/UI boundary and its enforcement, save architecture, test architecture |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | 5 | The Coach's World design system, complete 62-family screen inventory, match view, accessibility and proof contract |
| `docs/04b-AUDIT-RUBRIC.md` | 6 | Eight-dimension 40-point product UI gate, automatic specificity rejection and P0–P3 severities |
| `PRODUCT.md` | 7 | Positioning, audience, the market-gap argument, v1 scope |
| `docs/05-IMPLEMENTATION-PLAN.md` | 8 | Phased build with per-phase gates |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | 8 | What must be true before a build goes out. Authored fresh against the v4 scope. A **different** checklist existed on the pre-merge `main` — the Broadcast-critique outstanding-work list — now at `docs/archive/PRE-DEPLOYMENT-CHECKLIST-broadcast.md` |
| `docs/06-AUDIT-DISPOSITION.md` | 9 | The 25 P0/P1s and the five systemic patterns, converted into named tests |
| `docs/OPEN-DECISIONS.md` | 10 | The D1–D14 register, each with an instrumented falsifier. D14 (build order and league size) was added during execution because P2 fixes *that* both tiers ship, not which is built first. **D11 closed 2026-08-09 — the gates were run** |
| `docs/08-OPUS5-BUILD-PROMPT.md` | 11 | The phase-entry prompt. **Owns mission and definition of done** |
| `docs/PORT-LOG.md` | — | Tier C's symmetric justification: what is ported from the prior build and why, what is discarded and why. Added during execution |
| `docs/plans/2026-08-11-skill-integration.md` | — | Supporting execution authority for development-skill activation, duplication boundaries, the iOS 26/iPhone 15-generation verification matrix, and the phase gates that create project-local skills |

There is deliberately no `docs/00-*` and no `docs/07-*`. `00` was the old executive plan and is not
replaced. `07` **did** exist — the earlier program's salvage ledger — and is archived to
the deleted `07-SALVAGE.md`; `docs/PORT-LOG.md` does that job now. Neither number is reused.

### `docs/roadmap/` — Master Build Documentation, imported 2026-08-12

The Codex-authored Master Build Documentation pack, previously outside the repository (which left
`docs/05-IMPLEMENTATION-PLAN.md`'s deferral pointing at a path that did not exist — the seam
recorded in `docs/briefs/2026-08-12-gap-register.md` §4 Q6). Imported verbatim on owner instruction;
**these paths carry authority**, and `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md` is the build
ordering `05` defers to. The pack's internal `00`–`09` numbering is its own and does not reuse the
`docs/` deliverable numbering above.

| Path | Owns |
|---|---|
| `docs/roadmap/README.md` | Reading order and the four-piece structural core recommendation |
| `docs/roadmap/00-MASTER-BUILD-BLUEPRINT.md` | The end-to-end build blueprint |
| `docs/roadmap/01-SYSTEM-DEPENDENCY-MAP.md` | System dependency ordering |
| `docs/roadmap/02-DOMAIN-MODEL-AND-DATA-CONTRACTS.md` | Domain model and data contracts |
| `docs/roadmap/03-SIMULATION-BACKEND-PLAN.md` | Simulation backend plan |
| `docs/roadmap/04-AI-AND-DELEGATION-ARCHITECTURE.md` | AI and delegation architecture |
| `docs/roadmap/05-PERSISTENCE-PERFORMANCE-TESTING.md` | Persistence, performance and testing plan |
| `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md` | **M0–M9 milestones and gates — the build ordering authority** |
| `docs/roadmap/07-FUTURE-SIMULATION-CONTRACT.md` | Future simulation contract (pack edition; the live tracked edition is `docs/FUTURE-SIMULATION-CONTRACT.md`) |
| `docs/roadmap/08-UI-ADVERSARIAL-AUDIT.md` | UI adversarial audit (pack edition) |
| `docs/roadmap/09-UI-BACKEND-SURFACE-CONTRACT.md` | UI/backend surface contract |

## 4a. The definitive design references, redrawn in Floodlit 2026-08-14

Ten self-contained sheets at the repository root, **the** design reference library. Every `04` §8
screen family is built against them; the M8 production-UI work consumes them.

| Path | Renders |
|---|---|
| `tokens-v4.dc.html` | The `04` §6.1–§6.3 system in both appearances: Floodlit colour roles on their real surfaces with measured ratios, type ramp through AX5, spacing and the `CutCorner` radii, the synthetic team trio |
| `depth-v4.dc.html` | **New.** Registry 24–28: the five `World` backdrops, the three depth levels and the deep-panel contrast rule, the glass edge, grain, the blur budget, Reduce Transparency |
| `gauge-v4.dc.html` | **New.** Registry 29–35: the proportion vocabulary (`ArcGauge`, `ValueRing`, `AttributeDial`, `ShareBar`) and the drawn marks (`StarRating`, `Pennant`, `TimeoutMarks`) |
| `chrome-v4.dc.html` | Registry 1–5: route pill, `GoButton` action styles, desk surface as the opaque `GlassPanel` fallback, blank photo plate, world strip |
| `table-v4.dc.html` | Registry 7–10, 17, 18: dense table, column sets, list controls, rating badge, status chips, role tokens |
| `person-v4.dc.html` | Registry 6, 11, 12, 16: identity band, delta marks, confidence tags, form line |
| `readout-v4.dc.html` | Registry 13–15: verdict line (shipping and target forms, per the verdict-state rule), meter, opposed bar |
| `week-v4.dc.html` | Registry 19 and the chronology compositions |
| `broadcast-v4.dc.html` | Registry 20–22 plus the key-moments row, the Broadcast-marks class |
| `failure-v4.dc.html` | Registry 23: the failure set inside its owning compositions |

Full-page renders and an index live in `docs/proofs/design-references/`.

**Their authority is bounded, and the bound is the point.** The sheets are a *rendering*:
`docs/04-UX-AND-DESIGN-SYSTEM.md` is the only canonical home for values, and a value appearing only
in a sheet has not shipped. Where a sheet and `04` disagree, `04` wins and the sheet is the defect.
What the sheets *do* settle is composition, states and the density model applied — and on that they
supersede every earlier rendered library, mockup set and design pass in this repository. Those
earlier artefacts are historical evidence only; a document describing one is a record of what was
done, never direction for what to build.

**The `*-v3.dc.html` set this replaced (owner-approved 2026-08-12, superseded 2026-08-14):**

| Path | Classification | Reason | Where its role lives now |
|---|---|---|---|
| `tokens-v3.dc.html`, `chrome-v3.dc.html`, `table-v3.dc.html`, `person-v3.dc.html`, `readout-v3.dc.html`, `week-v3.dc.html`, `broadcast-v3.dc.html`, `failure-v3.dc.html` (8 root sheets) | **DELETED** | Rendered the palette `04` §6.1 held before the owner adopted Floodlit as the visual language (2026-08-14): action violet where the system now reads gold, live green where it now reads red. Re-annotating in place would have produced sheets that pass the sheet-ratio lint while quoting figures for colours canon no longer holds — the exact failure the lint exists to catch — so the set was redrawn instead of amended. `docs/proofs/design-references/*-v3-sheet.png` (8 renders) went with them. | `*-v4.dc.html` (this section) |

The v2→v3 replacement above and this v3→v4 replacement are the same kind of event for different
reasons: v2 was rejected as the wrong design direction; v3 was correct when drawn and became stale
when the palette it rendered was retired under it. Both are recoverable via `git show` and neither
carries authority.

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
  `docs/04-SCREENS-UI.md`; `docs/STATUS.md` no longer cites `00-EXECUTIVE-PLAN.md` at all, and its
  `05-IMPLEMENTATION-PLAN.md` references now resolve to the **current** canon file rather than the
  archived one — so that pair is listed here for history, not as a live dangling reference.
  `docs/01-RESEARCH.md` §G cites doc 06. All of those targets now live
  to files since deleted. The links are **not** repaired: a historical record that has been quietly
  edited stops being a record. Resolve them with `git show`.
- `docs/01-RESEARCH.md` §A says the screen inventory was compiled from "all 68 screenshots in this
  folder". **No image files have ever been committed to this repository.** The tables in §A are the
  only surviving record of those screenshots; treat them as the primary artefact, and do not go
  looking for images that are not there.
- `Pro-Football-Coach/` at the repository root was **not** what an earlier version of this bullet
  claimed. It was not empty, it did not contain nothing, and it was not untracked: it was a **tracked
  gitlink** (mode `160000`) pointing at commit `a8fbcee` of this same repository, with no
  `.gitmodules` to resolve it — so every clone got a directory it could not initialise and
  `git submodule status` failed. On disk it holds a nested clone whose working tree is a **full copy
  of the anti-canon**, including `docs/06-PLAYED-GAME-MODE.md`. The gitlink was removed from the
  index on 2026-08-09 and the path is gitignored; the nested clone on disk was left alone, and it
  carries no authority — nothing inside it is canon, whatever path it sits at.

  **This bullet was wrong for as long as it existed, and that is why nobody fixed the gitlink**: the
  archival pass read it, saw "not tracked by git", and moved on. A false entry in the section whose
  whole job is enumerating what is broken is worse than no entry.

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
