# Floodlit Phase 11 — Retire v3/Light Canon Authority (Task 13)

> **INVALIDATED 2026-08-17 — do not execute as written.** Steps 1–2 of this plan import the ten
> `*-v4.dc.html` sheets from `~/Downloads/Floodlit design references refinement (1).zip` as "the
> definitive design references." That ZIP is **stale**: its `tokens-v4.dc.html` ships dark-mode hex
> values that disagree with what is already shipped and canonical — e.g. `state.live` is `#FF8E9C`
> in the sheet, `#37E08A` in `Sources/ProFootballCoachUI/DesignTokens.swift:113` and in `04` §6.1a.
> Several roles in the sheet even collide (`state.live` and `state.negative` share `#FF8E9C`,
> suggesting a copy-paste error in an intermediate draft). The sheets are dated one day before
> §6.1a's "2026-08-16 amendment," and whatever produced §6.1a's final values evidently changed
> several roles after the ZIP was generated. Attempting to write the sheets' 119 uncanonized contrast
> ratios into `04` (the ostensible next step after import) would have injected these wrong values as
> canon. Execution was stopped mid-way (Steps 1–2 only) and fully reverted — nothing from this plan
> landed. Task 13 needs sheets that actually match `04` §6.1a / `DesignTokens.swift` before it can
> proceed: either request corrected v4 sheets from the owner, or regenerate them from the currently
> shipped token values. The research in Steps 3–8 below (exact current-state text for the six other
> canon docs, the deletion target list, the verification commands) is still accurate and reusable —
> only the sheet-provenance assumption in Steps 1–2 and "The provenance problem" section is wrong.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the ten v4 design-reference sheets and their approved canon amendment authoritative,
and retire the eight v3 sheets and the five superseded light-appearance proof captures they replace.
This is Task 13 of the master plan — a docs/canon retirement task with zero Swift source changes,
the first phase in this cutover that touches no production code.

**Architecture:** No new mechanism. Six canon/tracking documents get precise text edits; ten new
reference-sheet files land at their target paths; twenty-one retired artifacts are deleted by exact
path. Verification is `rg` sweeps for stale references plus the existing `--design-contracts` lane,
not new tests — this task changes no code the lane exercises, so its job is to confirm the lane
stays green, not to turn it red-then-green.

**Tech Stack:** Markdown, self-contained `.dc.html` reference sheets (no script/font/CDN/image
asset). No Swift.

**Spec:** Task 13 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`, argued from
`docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md` ("Status: approved for
implementation") — that spec is the actual canon authority this phase applies, not the ZIP's own
`docs/plans/2026-08-14-floodlit-canon-amendment.md`, which is superseded on every point it left open
(see "The provenance problem" below).

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch — already true of all production Swift
  code from Tasks 1–12 (Phases 3–10 in this session's numbering); this phase touches zero `.swift`
  files.
- Preserve historical documents as history rather than rewriting every old mention (master plan
  Task 13 Step 1's own instruction). `docs/STATUS.md`'s entries already marked
  `SUPERSEDED 2026-08-1X` must not be rewritten, only possibly appended to.
- No recursive or wildcard deletion for the 21 retirement targets in Step 9. Verify each is a
  regular file before deleting it; delete by exact path, one operation per file.
- CLAUDE.md scope guard: build what this plan specifies, no unrequested refactors.

---

## The provenance problem, and how it resolves

Master-plan Task 13 assumes "ten v4 sheets" already exist as repo artifacts and an "approved canon
amendment" is ready to apply. Neither was true when this phase started. The ten `*-v4.dc.html`
sheets exist only inside an external ZIP the owner supplied
(`~/Downloads/Floodlit design references refinement (1).zip`), which also contains
`docs/plans/2026-08-14-floodlit-canon-amendment.md` — dated 2026-08-14, explicitly **"Proposed, not
applied... requires owner approval,"** leaving three items open: the micro-label floor conflict, the
gap-scale conflict, and the deep-panel opacity choice between `.78` and `.82`.

Those three items are already resolved by a different, newer document:
`docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`, status "approved for
implementation." It resolves: dark-only with **no light register at all** (stronger than the
amendment doc's "derived day register" idea), `.82` deep-panel opacity, 10 pt micro-labels as an
explicit design-contract class with the body floor staying 12 pt, and snapping gaps onto the
**existing** `4/6/8/12/16/20` scale — already canon, nothing to change there. `docs/04-UX-AND-DESIGN-
SYSTEM.md` already carries a `### 6.1a Floodlit palette and material (2026-08-16 amendment,
dark-only)` section (lines 352–423) built from and citing this approved spec by name, and
`Sources/ProFootballCoachUI/DesignTokens.swift:36` already ships `deepPanelOpacity = 0.82` — the
approved value, not the amendment doc's open one. §6.1a is real, live canon; the ZIP's amendment doc
is superseded working paper that supplied the detailed component list (§6.5 entries 24–35, the §6.6
symbol accounting) the approved spec doesn't spell out itself.

**Deliberate addition to Task 13's file list.** The master plan's own "Files" section for Task 13
lists only modifications and deletions — no "Create" entries for the ten sheet files. But the
approved spec's own Migration step 1 says *"Land the ten exported v4 HTML sheets, their ten PNG
renders and the approved canon changes,"* and its Completion criteria require *"The ten v4 reference
sheets and renders are present and agree with canon."* Landing the sheets was never given its own
numbered task anywhere in the master plan, and Task 13 is the only remaining canon/artifact task —
so Step 2 below imports them here, named explicitly as this phase's one deviation from Task 13's
literal file list, the same way `docs/plans/2026-08-17-floodlit-phase-10-app-root.md` named its own
deviation rather than silently exceeding scope.

**Deliberately out of scope.** The ZIP contains no PNG renders of the ten sheets — only the
`.dc.html` files plus two markdown files. Generating the ten `*-v4-sheet.png` convenience renders is
**not** part of this phase; it belongs with Task 14's device-capture work (or a dedicated follow-up).
This phase's own replacement `docs/proofs/design-references/README.md` says so explicitly rather than
silently implying the renders already exist.

---

## Step 1: Impact and precondition check

- [ ] Run GitNexus impact for `docs/04-UX-AND-DESIGN-SYSTEM.md` and `docs/DOC-MANIFEST.md` — expect
  LOW/no code risk (docs carry no symbols GitNexus tracks); this is a sanity check, not expected to
  surface anything.
- [ ] Verify all 21 deletion targets from Step 9 exist as regular files, and all ten v4 sheets exist
  in the ZIP extraction, before editing anything:

```bash
cd /Users/ericguei/Documents/Pro-Football-Coach
for f in tokens-v3.dc.html chrome-v3.dc.html table-v3.dc.html person-v3.dc.html \
         readout-v3.dc.html week-v3.dc.html broadcast-v3.dc.html failure-v3.dc.html \
         docs/proofs/design-references/tokens-v3-sheet.png \
         docs/proofs/design-references/chrome-v3-sheet.png \
         docs/proofs/design-references/table-v3-sheet.png \
         docs/proofs/design-references/person-v3-sheet.png \
         docs/proofs/design-references/readout-v3-sheet.png \
         docs/proofs/design-references/week-v3-sheet.png \
         docs/proofs/design-references/broadcast-v3-sheet.png \
         docs/proofs/design-references/failure-v3-sheet.png \
         docs/proofs/coaching-hq-light-standard.png \
         docs/proofs/recruiting-board-light-standard.png \
         docs/proofs/match-day-light-standard.png \
         docs/proofs/personnel/roster-light-default-iphone17promax.png \
         docs/proofs/personnel/player-light-default-iphone17promax.png; do
  [ -f "$f" ] && ! [ -L "$f" ] || echo "MISSING OR NOT A REGULAR FILE: $f"
done
for f in tokens chrome depth gauge failure person readout table week broadcast; do
  [ -f "/tmp/v4-inspect/extracted/export/main/${f}-v4.dc.html" ] || echo "MISSING v4 SHEET: $f"
done
echo "precondition check complete"
```

Expected: no output besides the final line — every target present, every v4 sheet present. If
anything prints "MISSING", stop; do not proceed to Step 9 with an unverified target list.

## Step 2: Import the ten v4 sheets

- [ ] Copy the ten sheets from the read-only extraction to the repository root, matching the v3
  sheets' existing flat-root layout:

```bash
cd /Users/ericguei/Documents/Pro-Football-Coach
for f in tokens chrome depth gauge failure person readout table week broadcast; do
  cp "/tmp/v4-inspect/extracted/export/main/${f}-v4.dc.html" "./${f}-v4.dc.html"
done
ls -la *-v4.dc.html
```

Expected: ten new files at the repo root, `tokens-v4.dc.html` through `broadcast-v4.dc.html`.

## Step 3: Update `docs/04-UX-AND-DESIGN-SYSTEM.md`

Five edits in this one file, in this order (line numbers are pre-edit and shift after each edit —
apply top to bottom).

- [ ] **3a. Mark §6.1's dark/light table historical.** Insert a blockquote immediately after the
  `### 6.1 Colour roles` heading, matching the existing historical-marker convention this document
  and `docs/STATUS.md` already use elsewhere:

Old (line 242):
```
### 6.1 Colour roles

Tokens name purpose, never hue. Exact production values are validated in both appearances before
```

New:
```
### 6.1 Colour roles

> **Historical as of the Floodlit cutover (2026-08-16).** This section's dark production values and
> its light column are superseded by §6.1a below. Preserved as the record of the FM-proxy-era values
> and their measured ratios — do not implement against this table.

Tokens name purpose, never hue. Exact production values are validated in both appearances before
```

- [ ] **3b. Point §6.3's flat radius table forward to §6.1a's `CutCorner` geometry.**

Old:
```
### 6.3 Shape, spacing and touch

- Base spacing steps: 4, 6, 8, 12, 16, 20.
- DESK control radius: 8 pt; free-standing row radius: 8 pt; continuous table row radius: 0;
  surface radius: 10 pt.
- Broadcast radius: 0.
```

New:
```
### 6.3 Shape, spacing and touch

**Superseded for panels, rows and committing controls by §6.1a's `CutCorner` geometry** (`.panel`/
`.row`/`.action` presets, asymmetric four-corner radii). The flat radii below remain the shape for
surfaces §6.1a does not name: dense table rows, BROADCAST chrome, and circles.

- Base spacing steps: 4, 6, 8, 12, 16, 20.
- DESK control radius: 8 pt; free-standing row radius: 8 pt; continuous table row radius: 0;
  surface radius: 10 pt.
- Broadcast radius: 0.
```

- [ ] **3c. Add registry entries 24–35 to §6.5's component table**, immediately after entry 23 and
  before the "Adoption cost" paragraph:

Old:
```
| 23 | `EmptyState` / `ErrorBanner` / `InterruptedState` | The failure set, inside the owning composition |

Adoption cost, carried knowingly:
```

New:
```
| 23 | `EmptyState` / `ErrorBanner` / `InterruptedState` | The failure set, inside the owning composition |
| 24 | `CutCorner` | Rectangle with four independent corner radii, drawn as a shape |
| 25 | `GlassPanel` | Blurred pane at two depths, hairline edge, sheen from the upper left |
| 26 | `GrainOverlay` | Fixed-seed 128 px noise tile, overlay blend, above every screen |
| 27 | `WorldBackdrop` | The screen's world — one of five, gradient-drawn, carries no data |
| 28 | `Stage` | Safe-area owner at physical edges; content area and thumb arc |
| 29 | `ArcGauge` | Large proportion arc with its figure printed in the core |
| 30 | `ValueRing` | Table-scale rating ring, 26 pt, value over the 40–99 ceiling |
| 31 | `AttributeDial` | Concentric attribute arcs, radius carrying the attribute |
| 32 | `ShareBar` | Horizontal shares of one whole — the stated arc-not-bar exception |
| 33 | `StarRating` | Recruiting stars as blades, printed beside the numeral |
| 34 | `Pennant` | Depicted club flag; identity furniture under §5 |
| 35 | `TimeoutMarks` | Timeouts in hand and spent, beside the printed count |

Two rules travel with 24–35, both applied, not open decisions: **the proportion rule** — where a
datum is a share of a whole the form is an arc, from a 26 pt table cell (`ValueRing`) to a 212 pt
dial (`ArcGauge`); `ShareBar` is the stated exception, for when several shares of one whole must be
scanned in a glance rather than read one ring at a time. **One rating, one sweep** — a rating maps to
its sweep as value over the **40–99** ceiling, not 0–100, in `ValueRing` and `AttributeDial` alike;
0–100 would make every real player's dial look artificially incomplete and make 40 — a professional
floor — read as nothing. Registry 23 stays provisional under the P11 three-production-uses rule.

Adoption cost, carried knowingly:
```

- [ ] **3d. Update §6.6's symbol register**: raise the Broadcast marks cap, add a Rating marks class,
  update the total, and repoint the definitive-references paragraph at the ten v4 sheets.

Old (Broadcast marks row):
```
| **Broadcast marks** (§9) | 2 | possession wedge, key-moment mark | Match Day chrome only; both carry a printed or spoken value beside them, never count alone |
```

New:
```
| **Broadcast marks** (§9, `TimeoutMarks` registry 35) | 3 | possession wedge, key-moment mark, `TimeoutMarks` | Match Day chrome only; both carry a printed or spoken value beside them, never count alone |
| **Rating marks** (`StarRating`, registry 33) | 1 | `star.fill` drawn as a blade | Recruiting and draft evaluation only, always printed beside the numeral it restates |
```

Old (total-count paragraph):
```
**Total learned symbols: 23** (12 status + 2 change + 2 obligation + 5 session + 2 broadcast). The
last two rows are **capped but not learned**: a control is read from its label and an empty state
from its title and description, so neither adds to what the player must recall. They are enumerated
and bounded regardless, because an unbounded class is the leak this table exists to detect. Control furniture
is excluded by the rule above — a marked control is read from its label, not recalled from a
vocabulary. **The 23 is stated so it can be argued with; it is the number the owner is agreeing to
when a class grows.** Filled and unfilled variants of one symbol are one member: `hand.raised.fill`
is `hand.raised`, and `circle` is the unchecked state of `checkmark.circle.fill` rather than a
thirteenth status symbol or a new class. Where two components want the same meaning they take the same member — a
delegated receipt is `person.badge.clock` on every surface, not `person.fill.checkmark` on one.
```

New:
```
**Total learned symbols: 25** (12 status + 2 change + 2 obligation + 5 session + 3 broadcast + 1
rating). The last two rows are **capped but not learned**: a control is read from its label and an
empty state from its title and description, so neither adds to what the player must recall. They are
enumerated and bounded regardless, because an unbounded class is the leak this table exists to
detect. Control furniture is excluded by the rule above — a marked control is read from its label,
not recalled from a vocabulary. **The 25 is stated so it can be argued with; it is the number the
owner is agreeing to when a class grows.** Filled and unfilled variants of one symbol are one member:
`hand.raised.fill` is `hand.raised`, and `circle` is the unchecked state of `checkmark.circle.fill`
rather than a thirteenth status symbol or a new class. Where two components want the same meaning
they take the same member — a delegated receipt is `person.badge.clock` on every surface, not
`person.fill.checkmark` on one. `Pennant` (registry 34) is **excluded** from this count: a club mark
is generated identity furniture under §5, not a vocabulary item the coach learns — the same rule that
excludes team colour itself.
```

Old (definitive-references paragraph, immediately after the growth-rule paragraph):
```
**The definitive design references (owner-approved 2026-08-12).** Eight sheets at the repository
root render this registry: `tokens-v3.dc.html`, `chrome-v3.dc.html`, `table-v3.dc.html`,
`person-v3.dc.html`, `readout-v3.dc.html`, `week-v3.dc.html`, `broadcast-v3.dc.html`,
`failure-v3.dc.html`, with full-page renders and an index in `docs/proofs/design-references/`.
Every `04` §8 screen family is built against them. They supersede the deleted `*-v2.dc.html`
library entirely; any earlier rendered library, mockup set or design pass is historical evidence
and carries no authority. **The sheets remain a rendering — this document is the only canonical
home, and a value appearing only in a sheet has not shipped.** Where a sheet and `04` disagree,
`04` wins and the sheet is the defect.
```

New:
```
**The definitive design references, approved for implementation 2026-08-15**
(`docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`). Ten sheets at the repository
root render this registry: `tokens-v4.dc.html`, `chrome-v4.dc.html`, `depth-v4.dc.html`,
`gauge-v4.dc.html`, `person-v4.dc.html`, `readout-v4.dc.html`, `table-v4.dc.html`,
`week-v4.dc.html`, `broadcast-v4.dc.html`, `failure-v4.dc.html`, with an index in
`docs/proofs/design-references/`. Every `04` §8 screen family is built against them. They supersede
the deleted `*-v3.dc.html` sheets (owner-approved 2026-08-12, retired by the Floodlit cutover) and,
through them, the deleted `*-v2.dc.html` library; any earlier rendered library, mockup set or design
pass is historical evidence and carries no authority. **The sheets remain a rendering — this document
is the only canonical home, and a value appearing only in a sheet has not shipped.** Where a sheet and
`04` disagree, `04` wins and the sheet is the defect.
```

- [ ] **3e. Retire the dual-appearance proof requirement in §10.**

Old:
```
Each proof renders at 844 × 390 (install floor), 852 × 393 (promise floor) and 956 × 440 (ceiling)
per §7 and D15, light and dark, default and AX5. It must score at least 31/40 under `04b`, with no
P0/P1 and none of the §4.4 automatic rejection conditions.
```

New:
```
Each proof renders at 844 × 390 (install floor), 852 × 393 (promise floor) and 956 × 440 (ceiling)
per §7 and D15, dark (Floodlit is dark-only per §6.1a — no light rendition), default and AX5. It must
score at least 31/40 under `04b`, with no P0/P1 and none of the §4.4 automatic rejection conditions.
```

- [ ] Build/lint check: `grep -n '\*-v3\.dc\.html\|light and dark\|both appearances' docs/04-UX-AND-DESIGN-SYSTEM.md` should print nothing.

## Step 4: Update `docs/04b-AUDIT-RUBRIC.md`

Two bullet edits.

- [ ] **4a.** `## 6. Required evidence`:

Old: `- dark and light appearances;`

New: `- the Floodlit dark appearance (no light register — retired by \`04\` §6.1a);`

- [ ] **4b.** `## 8. Production enforcement`:

Old: `- both appearances meet contrast on composited surfaces;`

New: `- the Floodlit dark appearance meets contrast on composited surfaces (no light register to check);`

## Step 5: Update `docs/DOC-MANIFEST.md`

- [ ] **5a. Replace the §4a table.**

Old:
```
## 4a. The definitive design references, approved 2026-08-12

Eight self-contained sheets at the repository root, owner-approved as **the** design reference
library. Every `04` §8 screen family is built against them; the M8 production-UI work consumes them.

| Path | Renders |
|---|---|
| `tokens-v3.dc.html` | The `04` §6.1–§6.3 system: colour roles on their real surfaces with measured ratios, type ramp through AX5, spacing and radii, the synthetic team trio |
| `chrome-v3.dc.html` | Registry 1–5: route button, action styles, desk surface, blank photo plate, world strip |
| `table-v3.dc.html` | Registry 7–10, 17, 18: dense table, column sets, list controls, rating badge, status chips, role tokens |
| `person-v3.dc.html` | Registry 6, 11, 12, 16: identity band, delta marks, confidence tags, form line |
| `readout-v3.dc.html` | Registry 13–15: verdict line, meter, opposed bar |
| `week-v3.dc.html` | Registry 19 and the chronology compositions |
| `broadcast-v3.dc.html` | Registry 20–22 plus the key-moments row, BROADCAST register |
| `failure-v3.dc.html` | Registry 23: the failure set inside its owning compositions |

Full-page renders and an index live in `docs/proofs/design-references/`.
```

New:
```
## 4a. The definitive design references, approved for implementation 2026-08-15

Ten self-contained sheets at the repository root (`docs/superpowers/specs/2026-08-15-floodlit-all-
surfaces-design.md`), owner-approved as **the** design reference library. Every `04` §8 screen family
is built against them; the M8 production-UI work consumes them. Supersede the deleted
`*-v3.dc.html` sheets (owner-approved 2026-08-12, retired by the Floodlit cutover — see the
UI-reference correction table below).

| Path | Renders |
|---|---|
| `tokens-v4.dc.html` | The `04` §6.1a–§6.3 system: colour roles on their real surfaces with measured ratios, type ramp through AX5, shape and spacing to scale, both live team-colour sets |
| `depth-v4.dc.html` | Registry 24–28: the five worlds, the two glass depths and deep-panel derivation, cut-corner shapes and glass edge, grain, Stage's safe areas, Reduce Transparency branch |
| `gauge-v4.dc.html` | Registry 29–35: arc gauge, value ring, attribute dial, share bar, then the three drawn marks with their §6.6 accounting |
| `chrome-v4.dc.html` | Registry 1–5: route button, action styles, desk surface, blank photo plate, world strip |
| `table-v4.dc.html` | Registry 7–10, 17, 18: dense table, column sets, list controls, rating badge, status chips, role tokens |
| `person-v4.dc.html` | Registry 6, 11, 12, 16: identity band, delta marks, confidence tags, form line |
| `readout-v4.dc.html` | Registry 13–15: verdict line, meter, opposed bar |
| `week-v4.dc.html` | Registry 19 and the chronology compositions |
| `broadcast-v4.dc.html` | Registry 20–22 plus the key-moments row, BROADCAST register |
| `failure-v4.dc.html` | Registry 23: the failure set inside its owning compositions |

Full-page renders and an index live in `docs/proofs/design-references/`. The PNG renders are not yet
generated — see that directory's own README for the current state.
```

- [ ] **5b. Add a v3-retirement row to the UI-reference correction table.** Insert after the existing
  `*-v2.dc.html` row (do not edit that row):

Old:
```
| `*-v2.dc.html` (16 root sheets) | **DELETED** | Historical rendered reference library; generic two-pane/card composition, stale screen count and parallel design authority. Replaced 2026-08-12 by the owner-approved `*-v3.dc.html` sheets (see §4a). | `docs/04-UX-AND-DESIGN-SYSTEM.md`; `*-v3.dc.html` |
| `design.md` | **DELETED** |
```

New:
```
| `*-v2.dc.html` (16 root sheets) | **DELETED** | Historical rendered reference library; generic two-pane/card composition, stale screen count and parallel design authority. Replaced 2026-08-12 by the owner-approved `*-v3.dc.html` sheets (see §4a). | `docs/04-UX-AND-DESIGN-SYSTEM.md`; `*-v3.dc.html` |
| `*-v3.dc.html` (8 root sheets) | **DELETED** | The retired-violet-system rendered reference library. Replaced 2026-08-15 by the owner-approved `*-v4.dc.html` sheets (see §4a) as part of the Floodlit cutover. | `docs/04-UX-AND-DESIGN-SYSTEM.md` §6.1a; `*-v4.dc.html` |
| `design.md` | **DELETED** |
```

(Use the exact surrounding row text from the file as the anchor for this Edit — `design.md` and its
row continue unchanged; only the new row is inserted between the two.)

- [ ] Lint check: `grep -n '\*-v3\.dc\.html' docs/DOC-MANIFEST.md` should show only the new
  `**DELETED**` row and nothing claiming v3 as current.

## Step 6: Update the proofs indexes

- [ ] **6a. `docs/proofs/README.md`** — repoint the definitive-references paragraph and drop the
  light column from both proof tables.

Old:
```
**The definitive design references are the eight `*-v3.dc.html` sheets at the repository root**
(owner-approved 2026-08-12; renders and index in `docs/proofs/design-references/`). These proof
screenshots are evidence of what the build renders today, not a design authority; where a proof and
a sheet disagree, the sheet governs, and where a sheet and `04` disagree, `04` governs.

Older proof variants were captured at the 844×390 landscape viewport; the supported window is now
844 × 390 (install floor) through 956 × 440 (ceiling) per `04` §7 and D15. Light/default renders at
2× and dark/AX5 at 3×. AX5 is an accessibility reflow proof, not a density reference.
```

New:
```
**The definitive design references are the ten `*-v4.dc.html` sheets at the repository root**
(approved for implementation 2026-08-15,
`docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`; index in
`docs/proofs/design-references/`). These proof screenshots are evidence of what the build renders
today, not a design authority; where a proof and a sheet disagree, the sheet governs, and where a
sheet and `04` disagree, `04` governs.

Older proof variants were captured at the 844×390 landscape viewport; the supported window is now
844 × 390 (install floor) through 956 × 440 (ceiling) per `04` §7 and D15. Floodlit is dark-only —
there is no light rendition — captured at 3× including AX5. AX5 is an accessibility reflow proof, not
a density reference.
```

Old (Coaching HQ/Recruiting Board/Match Day table):
```
| Proof | Light / standard | Dark / AX5 |
|---|---|---|
| Coaching HQ | `coaching-hq-light-standard.png` | `coaching-hq-dark-ax5.png` |
| Recruiting Board | `recruiting-board-light-standard.png` | `recruiting-board-dark-ax5.png` |
| Match Day | `match-day-light-standard.png` | `match-day-dark-ax5.png` |
```

New:
```
| Proof | Standard | AX5 |
|---|---|---|
| Coaching HQ | `coaching-hq-dark-standard.png` | `coaching-hq-dark-ax5.png` |
| Recruiting Board | `recruiting-board-dark-standard.png` | `recruiting-board-dark-ax5.png` |
| Match Day | `match-day-dark-standard.png` | `match-day-dark-ax5.png` |
```

Old (Roster/Player Profile table):
```
| Proof | Light / default | Dark / AX5 |
|---|---|---|
| Roster | `personnel/roster-light-default-iphone17promax.png` | `personnel/roster-dark-ax5-iphone17promax.png` |
| Player Profile | `personnel/player-light-default-iphone17promax.png` | `personnel/player-dark-ax5-iphone17promax.png` |
```

New:
```
| Proof | Default | AX5 |
|---|---|---|
| Roster | `personnel/roster-dark-default-iphone17promax.png` | `personnel/roster-dark-ax5-iphone17promax.png` |
| Player Profile | `personnel/player-dark-default-iphone17promax.png` | `personnel/player-dark-ax5-iphone17promax.png` |
```

The `-dark-standard`/`-dark-default` filenames named in the new tables do not exist on disk yet — the
five light PNGs they replace are deleted in Step 9, and re-capturing their dark-standard equivalents
is device-capture work, out of scope here (same as the ten sheet PNGs — Task 14's territory). This
table names what the proof set *should* contain once recaptured; it is intentionally honest about
the gap rather than silently leaving stale light filenames in a "definitive" index.

- [ ] **6b. Write `docs/proofs/design-references/README.md`**, adapted from the ZIP's version — not
  copied verbatim, because the ZIP's copy still describes the amendment as unapplied and `.82` as an
  open choice, both resolved by the approved spec. Read the current file first
  (`docs/proofs/design-references/README.md`) to confirm its existing content before overwriting.

```markdown
# Design-reference sheets — renders for review

Full-page renders of the ten `*-v4.dc.html` design-reference sheets at the repository root, so they
can be reviewed on a device without opening the HTML. **The HTML files are the deliverable; these
PNGs are a convenience.** Neither is canon — `docs/04-UX-AND-DESIGN-SYSTEM.md` is the only canonical
home, and a value appearing only in a sheet has not shipped.

The v4 set renders the registry against **Floodlit**, the approved visual direction (approved for
implementation 2026-08-15, `docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`):
glass at depth over one committed night world, one light from the upper left, asymmetrically cut
corners, a condensed display face. It supersedes the eight `*-v3.dc.html` sheets, which rendered the
retired violet system. `depth-v4` and `gauge-v4` are net-new and have no v3 equivalent.

**The PNG renders below are not yet generated.** This index states what they will cover once
captured; until then, read the `.dc.html` files directly. Registry 24–35, the §6.6 cap move and the
`.82` deep-panel opacity are canon as of `04` §6.1a — not a proposal — via the approved spec above.

| Sheet | Registry entries | What it covers |
|---|---|---|
| `tokens-v4-sheet.png` | — | The §6.1a/§6.2/§6.3 system: colour roles on their real surfaces with measured ratios, type ramp through AX5, shape and spacing to scale, both live team-colour sets, and one composition at three widths, at AX5 and flattened |
| `depth-v4-sheet.png` | 24–28 | The five worlds, the two glass depths and the deep-panel derivation, the cut-corner shapes and the glass edge, grain, Stage's safe areas, and the Reduce Transparency branch every entry must survive |
| `gauge-v4-sheet.png` | 29–35 | The four proportion primitives at their real diameters and strokes — arc gauge, value ring, attribute dial, share bar — then the three drawn marks with their §6.6 accounting |
| `chrome-v4-sheet.png` | 1–5 | Route button, action styles, desk surface, blank photo plate, world strip with the advance-affordance state pair |
| `table-v4-sheet.png` | 7–10, 17, 18 | Dense table with depth-slot chips and capacity header, column sets, list controls, rating badge, status-chip vocabulary, role tokens |
| `person-v4-sheet.png` | 6, 11, 12, 16 | Identity band with sequenced disclosure, delta marks, confidence tags and fog states, form line |
| `readout-v4-sheet.png` | 13–15 | Verdict line with its honest degraded form, meter with over-capacity, opposed bars — the pattern sheet the other nine follow |
| `week-v4-sheet.png` | 19 | Agenda rows as costed commitments, the week grid, load-policy ladder, hub tiles |
| `broadcast-v4-sheet.png` | 20–22 | Score bug, lower third, call-in card, key-moments row — BROADCAST register |
| `failure-v4-sheet.png` | 23 | Empty, error, interrupted, loading and delegated states inside their owning compositions |

Every card states its compliance with the ten-point card contract in
`docs/briefs/2026-08-12-reference-library-plan.md` §4: both registers with measured contrast ratios
quoted from canon, the three supported widths (844 install floor, 852 promise floor, 956 ceiling) plus
AX5, 44 pt minimum targets, states rather than one happy instance, team colour wherever it is touched,
one VoiceOver sentence per data row, the reduced form of every animation, verdict lines naming the
engine computation that backs them or the gap that does not yet, and a density-budget cost in the `04`
§4.5 currencies.

Sheets are self-contained: no script, no web font, no CDN, no image asset, so they render anywhere.
Two consequences worth knowing. Grain is **annotated rather than drawn** — the 128 px overlay tile is
an asset, and faking it with a gradient would misstate the texture, so it is named at each specimen
instead; `depth-v4` Card 26 leaves the slot deliberately empty for that reason even though the tile is
its own subject. And the condensed display face resolves through `font-stretch` with `Arial Narrow` in
the fallback chain for headless renders, so a render on a machine without it will be wider than the
device.

All identities are mechanical placeholders labelled *pending generator output*; sample content is
fictional and original per the `CLAUDE.md` legal guardrail.
```

## Step 7: Update `docs/plans/2026-08-12-road-to-beta.md`

- [ ] **7a.** Row U-1:

Old: `| U-1 | The eight \`*-v3.dc.html\` reference sheets, owner-approved, review findings applied | **Done** |`

New: `| U-1 | The eight \`*-v3.dc.html\` reference sheets, owner-approved, review findings applied | **Superseded 2026-08-15** — replaced by the ten \`*-v4.dc.html\` sheets, \`docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md\` |`

- [ ] **7b.** Row U-7 — read the file first to confirm the exact current cell text (it may wrap
  across lines), then close it out since dark-only retirement of the light register makes the
  light-primary contrast question moot rather than merely open:

Old (state column): `Open against P2`

New (state column): `**Closed 2026-08-15** — Floodlit retired the light register entirely (\`04\` §6.1a); light-primary team-colour contrast is no longer a live question`

## Step 8: Append a `docs/STATUS.md` orientation note

- [ ] Read the existing top-of-file blockquote convention (`docs/STATUS.md` lines 7–11, the
  "UI direction correction — owner decision 2026-08-11" blockquote) and add one more of the same
  shape directly beneath it — do not touch anything else in this 1548-line file; every existing v3/
  light mention in it is already inside a passage marked `SUPERSEDED`, per this phase's own research,
  and stays exactly as it is.

Old:
```
> **UI direction correction — owner decision 2026-08-11:** the v2 sheets, Stitch output and
> 34-screen Film Room gallery described in older dated entries below are rejected and removed.
> They are historical build notes, not references. The only current UI authority is
> `docs/04-UX-AND-DESIGN-SYSTEM.md`: **The Coach's World**, 62 screen families, no universal
> application chassis, and Film Room limited to scouting, tactics and replay.
```

New:
```
> **UI direction correction — owner decision 2026-08-11:** the v2 sheets, Stitch output and
> 34-screen Film Room gallery described in older dated entries below are rejected and removed.
> They are historical build notes, not references. The only current UI authority is
> `docs/04-UX-AND-DESIGN-SYSTEM.md`: **The Coach's World**, 62 screen families, no universal
> application chassis, and Film Room limited to scouting, tactics and replay.

> **Floodlit cutover — approved for implementation 2026-08-15:** the v3 sheets and the violet
> DESK system they rendered are retired. Canon is `docs/04-UX-AND-DESIGN-SYSTEM.md` §6.1a plus the
> ten `*-v4.dc.html` sheets. Floodlit is dark-only — there is no light register, light proofs or
> user-facing appearance switch.
```

## Step 9: Delete the 21 retired artifacts

Only after Steps 2–8 land and the precondition check in Step 1 passed. No recursive or wildcard
deletion — one exact path per `git rm` call, matching the master plan's own instruction.

- [ ] Delete the eight v3 sheets:

```bash
cd /Users/ericguei/Documents/Pro-Football-Coach
git rm tokens-v3.dc.html chrome-v3.dc.html table-v3.dc.html person-v3.dc.html \
       readout-v3.dc.html week-v3.dc.html broadcast-v3.dc.html failure-v3.dc.html
```

- [ ] Delete their eight PNG renders:

```bash
git rm docs/proofs/design-references/tokens-v3-sheet.png \
       docs/proofs/design-references/chrome-v3-sheet.png \
       docs/proofs/design-references/table-v3-sheet.png \
       docs/proofs/design-references/person-v3-sheet.png \
       docs/proofs/design-references/readout-v3-sheet.png \
       docs/proofs/design-references/week-v3-sheet.png \
       docs/proofs/design-references/broadcast-v3-sheet.png \
       docs/proofs/design-references/failure-v3-sheet.png
```

- [ ] Delete the five superseded light-evidence PNGs:

```bash
git rm docs/proofs/coaching-hq-light-standard.png \
       docs/proofs/recruiting-board-light-standard.png \
       docs/proofs/match-day-light-standard.png \
       docs/proofs/personnel/roster-light-default-iphone17promax.png \
       docs/proofs/personnel/player-light-default-iphone17promax.png
```

- [ ] Confirm exactly 21 deletions and 10 additions are staged, nothing else:

```bash
git status --porcelain | grep -v "^??"
```

## Step 10: Verify

```bash
cd /Users/ericguei/Documents/Pro-Football-Coach
swift run SimTests --design-contracts
rg -n 'CoachWorldTokens\.light|@Environment\(\\\.colorScheme\)' Sources/ProFootballCoachUI
rg -n '\*-v3\.dc\.html|light and dark|both appearances' \
  docs/04-UX-AND-DESIGN-SYSTEM.md docs/04b-AUDIT-RUBRIC.md \
  docs/DOC-MANIFEST.md docs/proofs/README.md
swift build
swift run SimTests
```

Expected: `--design-contracts` and the full suite pass unchanged (this phase touches no Swift, so
the gate is "still green," not "newly green"); the first `rg` finds nothing (already true before this
phase); the second `rg` finds nothing across all four live canon docs — this is the phase's own
completion gate.

## Step 11: `detect_changes` and review

- [ ] Run `mcp__gitnexus__detect_changes({scope: "unstaged", repo: "Pro-Football-Coach"})` — expect a
  docs-only change set (six modified files, ten new `.dc.html` files, one new/rewritten README, 21
  deletions), no Swift symbols touched. Cross-check against `git status --porcelain` per this
  cutover's established practice of not trusting `detect_changes` alone.
- [ ] Adversarial review of the diff: every remaining `*-v3.dc.html`/"eight sheets"/"light and
  dark"/"both appearances" reference in the four live canon docs is gone (not just in the edited
  passages — sweep the whole file); the new §6.5/§6.6 entries match the amendment doc's own wording
  rather than inventing new descriptions; no accidental deletion of a file this task didn't intend to
  touch; `docs/STATUS.md`'s pre-existing `SUPERSEDED` passages are untouched; the ten new `.dc.html`
  files are byte-identical to the ZIP's extraction (not accidentally edited during copy).

## Step 12: Commit

```bash
cd /Users/ericguei/Documents/Pro-Football-Coach
git add -A -- '*.dc.html' docs/04-UX-AND-DESIGN-SYSTEM.md docs/04b-AUDIT-RUBRIC.md \
  docs/DOC-MANIFEST.md docs/proofs/README.md docs/proofs/design-references/README.md \
  docs/plans/2026-08-12-road-to-beta.md docs/STATUS.md \
  docs/plans/2026-08-17-floodlit-phase-11-canon-retirement.md
git status --porcelain | grep -v "^??"
git commit -m "docs: make Floodlit v4 canonical"
```

Do not stage any concurrent session's unrelated in-flight files.

## What this phase is not

It does not touch any Swift source. It does not generate the ten v4 sheet PNG renders or the five
replacement dark-standard proof captures — both are device-capture work, naturally Task 14's
territory. It does not resolve anything the approved spec left genuinely open (there is nothing left
open — every item the ZIP's amendment doc flagged is already decided). It does not re-litigate the
Floodlit visual direction itself; that decision was made before this phase started.
