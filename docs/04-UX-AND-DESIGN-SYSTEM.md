# 04 — UX and Design System

Owner-approved correction, 2026-08-11. This document is the only canonical home for product UX,
visual language, screen inventory and UI acceptance rules. The previous universal **Film Room**
system and its 34-screen rendered library were rejected because they made unrelated football tasks
look like variants of the same management application.

## 1. Product fantasy

The player is not operating software. The player is living a coaching career.

The global design premise is **The Coach's World**. Every surface must answer three questions within
the first glance:

1. Where am I in the football world?
2. What changed because time, people or competition moved?
3. What does the head coach need to understand or decide now?

**The Film Room is one location, not the whole game.** It is used for opponent analysis, tactics and
replay. Recruiting, contracts, career history and live football must not inherit its furniture.

### 1.1 What the owner-supplied Football Manager references establish

The eighteen saved references are the visual-density and information-behaviour proxy for the
management game. They represent desktop-class Football Manager composition adapted for landscape
iPhone. The capture corpus is desktop FM plus two Football Manager Mobile match frames; it contains
no Football Manager Touch capture (provenance census:
`docs/briefs/2026-08-12-reference-set-findings.md` §1), so the desktop-level-functionality-on-iPhone
target stands as owner intent (testimony recorded 2026-08-12), not as capture evidence. Copy
proportions, rhythm and hierarchy; do not copy protected assets or identities.

- a player report is organised around a person, club identity and role;
- a calendar becomes the screen when time is the task;
- a squad comparison becomes a dense, sortable team sheet when comparison is the task;
- tactics and set pieces become spatial field diagrams;
- training becomes a week plan with load and consequences;
- finances become a ledger with warnings and trajectories;
- analytics lead with a judgement, then show the evidence;
- mobile recent-form becomes one chronological story rather than a desktop dashboard;
- live football gives the field the frame, with the score and current cause attached to it.

The references also show what **not** to inherit: generic portal tiles, unstructured equal-weight card grids,
bookmark managers, unexplained data density, soccer-specific terminology, colours, assets and
trade dress. Their compact type, continuous panes, table rhythm and shallow navigation are positive
references and should be retained at the 844 × 390 pt floor.

FM feels alive partly because its data already carries real-world emotional meaning. This fictional
game must manufacture that meaning through continuity, people, place, rivalry, history and visible
consequence. Copying FM density without those stakes produces number juggling.

## 2. Registers: one career, several football places

Consistency comes from shared truth, typography, interaction and identity rules. It does **not**
come from forcing every screen into one chassis.

| Register | Player fantasy | Dominant objects | Shape and motion |
|---|---|---|---|
| **Coach's Office** | Run the week | week plan, correspondence, pressure, staff notes | disciplined seams, writable schedules, restrained motion |
| **Personnel Room** | Build and develop the team | team sheet, depth chart, player dossier, medical and staff files | dense comparison where earned; identity-led detail |
| **Acquisition Room** | Compete for future talent | recruiting board, territory, relationship history, offer ledger | live market movement, physical ranking/territory cues |
| **Front Office** | Keep the pro roster legal and competitive | cap ledger, contracts, draft board, market | harder steel geometry, transaction receipts, clocks only when real |
| **League & Media** | Understand the living world | map, standings, schedule, stories, records | editorial hierarchy; data tied to teams, games and history |
| **Career & Legacy** | Read the coach's story | timeline, stakeholders, jobs, rivals, record book | chronological composition; earned ceremony |
| **Film Room** | Study evidence | field film, tendencies, matchup evidence, staff interpretation | dark analytical environment; annotation belongs to evidence |
| **Broadcast** | Experience live or timed football | full field, score, clock, causal commentary, call-in | square geometry, team identity, no management chrome |
| **Ceremony** | Mark an irreversible career moment | appointment, signing, promotion, trophy | rare, focused, minimal controls |

No screen may describe itself as “Film Room” unless it belongs to that row.

## 3. World navigation

The former universal five-tab bottom bar is removed.

Management surfaces use a **world strip** that carries the current programme or club, coach, date or
phase, record and the next legal advance in time. It is world state, not an app toolbar. A task then
provides only the local routes it needs: Office, Personnel, Acquisition/Front Office, League and
Career. Labels may move or collapse, but the information architecture remains stable.

- `Continue` advances only to the next unresolved obligation or scheduled event.
- Mandatory work cannot be skipped. It may be explicitly delegated when the system supports it.
- Match, draft-room clocks, signing-day clocks and ceremonies suppress global navigation.
- Back/close returns to the football object that opened the surface, not an arbitrary tab root.
- Cold resume restores the exact surface and draft selection at the last durable boundary.
- No screen needs a bookmark manager or user-configurable shortcut system.

## 4. Composition rules

### 4.1 One dominant football object

Every screen has one dominant representation. Examples: week plan, player dossier, recruiting
board, salary ledger, field, map, chronological story. Supporting evidence may surround it, but no
more than two secondary regions compete at the initial viewport.

There is no universal 38/62 split, task header, verdict card, choice-card row or fixed action rail.
Those patterns may appear where the task earns them; they may not become global templates.

### 4.2 Density is task-relative

- Use full tables for roster, recruiting, contracts, standings and statistical comparison.
- Use spatial diagrams for tactics, depth, packages, territory and live play.
- Use chronology for weeks, recent form, career, recruiting relationships and offseason.
- Use editorial story hierarchy for news, appointment, promotion and aftermath.
- Lead analytical readouts with staff interpretation, then sample, confidence and evidence.
- Show exact numbers only where the simulation owns exact numbers. Use bands for estimates.
- Compact comparison density is the default for management work. Advanced columns and long-form
  evidence may move behind a local route, but the initial frame must still feel like a complete
  football workspace rather than a mobile card feed.

### 4.3 Decisions live beside their cause

A meaningful decision exposes deadline, cost, uncertainty, staff voice, consequence and two or
three defensible actions. The control is attached to the object being changed. A generic footer
button labelled `Commit` is prohibited unless the transaction itself is the dominant object.

`Decide`, `Inspect` and `Delegate` remain distinct. Success shows an exact receipt. Failure preserves
the authoritative draft and offers recovery. An interrupted decision must disclose what changed
before the player can resolve it.

### 4.4 Application-slop rejection

A screen fails before scoring if any of these is true:

- it could describe a CRM, analytics SaaS product or project-management tool after nouns are changed;
- unrelated tasks reuse the same visible chassis;
- an unstructured grid of equal-weight cards replaces the football task hierarchy;
- decorative pills, badges or coloured side rails substitute for meaning rather than compress it;
- generic blue is the only expression of action or selection;
- internal fixture, prototype or `REFERENCE DATA` copy appears inside the game frame;
- there is no visible team, opponent, season, person, place, football object or consequence;
- an AI-style verdict invents authority without sample, staff ownership or uncertainty;
- the first viewport is a contents page for the real task rather than the task itself.

Prototype truth disclosure belongs in gallery chrome outside the native device frame.

### 4.5 The density budget

*Adopted 2026-08-12 from `docs/briefs/2026-08-12-density-model.md`.*

Density is spent in five currencies: points, taps, working memory, learned symbols and verdict
lines. A management screen may spend: one dominant object (at least 60% of the initial viewport) and
at most two secondary regions; 24–28 pt table tracks with six to nine fact columns beside identity,
further facts arriving as column sets rather than horizontal scroll; at most three status glyphs per
row from the global status vocabulary of at most twelve, each changing a decision (that cap governs
the **status** class; other closed symbol vocabularies are enumerated and capped separately in
§6.6, and the total learned-symbol load is held there — a symbol not in §6.6 is a finding, not a
licence); at most one verdict line
per readout with its evidence exactly one tap away; popouts to depth one; any task-owned datum
within two taps. Comparisons happen on one surface; a flow that requires remembering the previous
screen is over budget regardless of fit. Pixels are spent before taps; working memory is never
spent. Verdicts, bands and change marks are drawn only where the simulation owns the computation
behind them: a verdict without an engine baseline, a band without a recorded observation, or a
change mark without a retained delta is fabrication under §4.4. At AX5 the composition reflows to
one column preserving order and dropping nothing. A screen is over budget when a second dominant
object appears, the glyph vocabulary grows to accommodate it, type falls below its floor to make
something fit, or AX5 loses data. The registry's per-screen budget statements are audited under
`04b`; a surface the inventory does not price is a finding, not a licence.

## 5. Identity system

Identity is structural, not a two-point decorative accent.

- Programme or club colour may own a world-strip field, scoreboard, selection state, uniform mark,
  recruiting territory or ceremony surface when it remains legible.
- Opponents use their own identity only where comparison or conflict requires it.
- College may use one restrained 9-degree cut in identity furniture. Pro remains orthogonal.
- Broadcast furniture uses both teams. Management never receives a decorative team-colour wash.
- Team marks, uniforms, stadium names, player names and staff names come from the generated universe.

**Restraint rules (added 2026-08-12; owner instruction — team colour must never become distracting
or intense).** The six slots above are the only surfaces team colour may own; anything else is the
wash §4.4 rejects. Within the slots:

- **One full-bleed team field per management screen: the world strip's.** Every other management
  use is mark-scale — chip, crest, boundary — none taller than its own row.
- **Selection takes a boundary, never a fill.** Boundary plus value plus spoken state per §6.3; the
  boundary rule may take the team accent only when it measures at least 3:1 against its surface at
  runtime, otherwise it falls back to `action.primary`. A team-coloured selection fill is a defect.
- **Recruiting territory is a bounded tint, adopted with the identity sheet.** The tint alpha and
  its measured ink pairings land with the P4 identity samples under the G-07 write-back discipline;
  until then a territory surface uses the neutral map grammar. Labels stay in content roles.
- **Scoreboard and ceremony surfaces may carry full identity.** They are BROADCAST-register places:
  a scoreboard carries both teams per the bullet above; a ceremony carries its subject.
- **Team colour never inks meaning.** Status glyphs stay in `state.*` roles, text in `content.*`,
  and no numeral that carries a value takes team ink.
- **`CoachWorldTeamIdentity` is the sole resolution point for generated colour.** A view that reads
  `primaryColorHex` directly is a defect (source-scannable). When the legibility gates fail, the
  surface refuses team paint and renders neutral; §6.1's mandatory hairline boundary applies to
  every team fill in every slot.

**Gold is not team colour (2026-08-14).** Floodlit's gold is `action.primary`, and the restraint
rules above do not touch it. Three consequences, stated because the two are easy to confuse:

- **A gold field is permitted on the committing action, and nowhere else.** It is the one control
  on a screen that moves the game forward, and it is the only element allowed to take the accent as
  a fill; everything else that looks interactive is outlined. This does not consume the screen's one
  full-bleed team field, which remains the world strip's.
- **On the field, gold is `field.annotation` — the first-down rule.** The two uses never co-occur,
  because §9 forbids management chrome on the match view, so no screen shows a gold action and a
  gold first-down line together.
- **A generated team colour near the accent still renders as itself.** The programme owns its
  colour; the action is told apart by shape, boundary and position, not by hue. This is the same
  reasoning as "team colour never inks meaning", applied in the other direction.

### 5.1 People and future custom universes

The base product uses a deliberate neutral photo plate for players and personnel. It contains no
generated face and no initials pretending to be a photograph. Recognition comes from name, role,
uniform, team, relationships and history.

The base UI never fetches procedural portraits or other identity assets from a network service.
Future user-supplied universe media is resolved from a validated local import, with the neutral
photo plate remaining the offline, missing-file and opt-out state.

The view model reserves optional asset references for future user-supplied universes:

- `person.photoAsset`
- `team.primaryMarkAsset`, `team.secondaryMarkAsset`, `team.uniformAsset`
- `team.displayName`, `team.shortName`, `team.colours`
- `venue.displayName`, `venue.imageAsset`

The base game remains fictional and original. Importing custom names or media is a future product
and legal decision, not a v1 feature; UI code must neither require it nor block it.

### 5.2 Generated crests and uniform marks

*Added 2026-08-12, owner-approved plan. The recognition device §5.1 promises — "uniform, team" —
made concrete without a single authored image.*

Each programme receives a **crest**: an abstract geometric mark composed from a closed heraldic
vocabulary, drawn only in the team's own colour pair.

- **Vocabulary, closed by construction.** Field divisions: pale, fess, bend, saltire, chevron,
  quartered. Charges: roundel, arch, bordure, canton, bar. The spec type can express nothing else —
  no letterforms, no figurative shapes, no mascots, no pictorial art. That impossibility is a
  type-level property with an exhaustive-case test, not a review item.
- **Grammar.** One field division plus at most two charges. Colours are `team.primary`,
  `team.secondary` and `team.onTeam` only — a crest never mints a colour.
- **Determinism.** The crest is a pure function of the team's stable identifier and colour pair,
  derived at read time. It is never persisted; there is no save-schema change (the
  rebuilt-not-persisted pattern).
- **Where it appears.** The §5 slots: world strip, scoreboard, uniform mark, ceremony surface. At
  chip scale it may replace the abbreviation text plate; the accessible name remains the programme
  name.
- **Read model.** A structured `team.crest` spec field. The §5.1 asset slots stay reserved for
  future user-supplied media and are never used for generated crests; when a validated import
  supplies a mark it replaces the generated crest, and the generated crest remains the offline,
  missing-file and opt-out state — the plate pattern applied to marks.
- **Legal posture.** The machine guarantees closure, determinism and colour provenance (colour
  pairs already pass the trade-dress ΔE sweep). Geometric resemblance to a real mark is **not**
  machine-testable: a deterministic crest census — a specimen grid across the legal-sweep leagues —
  is emitted for owner review and flagged for counsel per the `CLAUDE.md` guardrail. No test claims
  to cover crest resemblance, and no document may describe one as doing so.

## 6. Foundations

### 6.1 Colour roles

Tokens name purpose, never hue. Exact production values are validated in both appearances before
SwiftUI implementation.

| Role | Purpose |
|---|---|
| `world.page`, `world.work`, `world.raised` | three maximum neutral elevations |
| `content.primary`, `content.secondary`, `content.quiet` | text hierarchy; quiet never carries working prose |
| `action.primary`, `action.secondary`, `action.destructive` | controls; team colour is not a generic action token |
| `state.live`, `state.positive`, `state.warning`, `state.negative`, `state.info` | semantic state; never colour alone |
| `college.identity`, `pro.identity` | tier furniture only |
| `field.turf`, `field.line`, `field.annotation`, `field.live` | field grammar |
| `broadcast.home`, `broadcast.away`, `broadcast.ink` | per-match derived roles |

The owner-supplied Football Manager captures remain the production proxy for **density, navigation
proportions, panel rhythm and typographic hierarchy** — that is what §4.5 prices and what they are
for. They are no longer the proxy for colour or surface treatment. The game does not copy FM marks,
icons, photographs, club identities or branded artwork.

**The visual language is Floodlit (owner decision, 2026-08-14).** The Coach's World remains the
product premise — the registers in §2, the world navigation in §3 and the composition rules in §4 are
unchanged. Floodlit is how that premise is *painted*: a single lit world seen at night or indoors,
with glass panels held at depth under one light, proportions drawn as arcs, and film grain over
everything. Its `World` backdrop is the register made visible — the pitch when the screen is about
the field, the facility floor when it is about the programme, the footage itself in the film room.
The light appearance is the same places by day, not an inversion of the night values.

**Production values (Floodlit write-back, 2026-08-14; supersedes the 2026-08-12 G-07 table).** These
are the values `Sources/ProFootballCoachUI/DesignTokens.swift` ships, written back so no sheet or
view claims a value canon does not hold. Every ratio is measured WCAG 2.2 relative-luminance contrast
against the surface the role is actually composited on (floors: 4.5:1 body text, 3:1 large text and
non-text — SC 1.4.3/1.4.11, verified sources in `docs/briefs/2026-08-12-sourcing-log.md`). The
derivation and its three findings are in `docs/plans/2026-08-14-floodlit-canon-amendment.md`; the
code/canon sync check is `DesignContractTests`' token-sync suite.

The three neutral elevations are the **opaque equivalents** of Floodlit's surfaces: what a panel
measures as for contrast purposes, and the flat fill it falls back to when the blur budget in this
section is exceeded. `world.work` is Floodlit's standard glass composited over `world.page`.

| Role | Dark | on page / work / raised | Light | on page / work / raised |
|---|---|---|---|---|
| `world.page` | `#060A12` | — | `#EDF1F6` | — |
| `world.work` | `#141A26` | — | `#FAFBFD` | — |
| `world.raised` | `#1E2735` | — | `#DCE3EC` | — |
| `content.primary` | `#F6FAFF` | 18.90 / 16.62 / 14.34 | `#0B111C` | 16.66 / 18.25 / 14.62 |
| `content.secondary` | `#A9BACE` | 10.00 / 8.79 / 7.59 | `#414B5C` | 7.76 / 8.50 / 6.81 |
| `content.quiet` | `#8496AC` | 6.55 / 5.76 / 4.97 | `#566274` | 5.45 / 5.97 / 4.78 |
| `action.primary` | `#FFC53D` | 12.55 / 11.04 / 9.53 | `#7A5200` | 6.10 / 6.68 / 5.35 |
| `action.secondary` | `#A9BACE` | 10.00 / 8.79 / 7.59 | `#414B5C` | 7.76 / 8.50 / 6.81 |
| `action.destructive` | `#FF8E9C` | 9.06 / 7.96 / 6.87 | `#A3202F` | 6.60 / 7.23 / 5.79 |
| `state.live` | `#FF8E9C` | 9.06 / 7.96 / 6.87 | `#A3202F` | 6.60 / 7.23 / 5.79 |
| `state.positive` | `#7DF0B6` | 14.16 / 12.45 / 10.75 | `#14653C` | 6.26 / 6.86 / 5.49 |
| `state.warning` | `#FFB03A` | 10.87 / 9.56 / 8.25 | `#704C00` | 6.80 / 7.45 / 5.97 |
| `state.negative` | `#FF8E9C` | 9.06 / 7.96 / 6.87 | `#A3202F` | 6.60 / 7.23 / 5.79 |
| `state.info` | `#9CC8EE` | 11.24 / 9.88 / 8.53 | `#1E5A8C` | 6.39 / 7.00 / 5.61 |
| `college.identity` | `#C79AE4` | 8.65 / 7.61 / 6.57 | `#6A3E9C` | 6.65 / 7.29 / 5.84 |
| `pro.identity` | `#9CC8EE` | 11.24 / 9.88 / 8.53 | `#26608D` | 5.90 / 6.46 / 5.17 |
| `field.turf` | `#1C6E42` | — | `#D9E7DD` | — |
| `field.turfBand` | `#1F764A` | 1.12 on `field.turf` | `#D0E0D5` | 1.07 on `field.turf` |
| `field.line` (on turf) | `#F5F7FA` | 5.83 | `#0E1218` | 14.69 |
| `field.annotation` (on turf) | `#FFC53D` | **3.96** | `#7A5200` | 5.41 |
| `field.live` (on turf) | `#C6F24E` | 4.83 | `#3F6300` | 5.48 |

**State fills, distinct from the state inks above.** Floodlit separates the colour that fills a chip
or indicator from the colour that carries text, and canon holds both because they measure
differently. The inks are in the table; the fills are:

| Fill | Dark | on page / work / raised |
|---|---|---|
| `state.live` / `state.negative` / `action.destructive` fill | `#FF3B54` | 5.67 / 4.98 / **4.30** |
| `state.positive` fill | `#37E08A` | 11.50 / 10.11 / 8.73 |
| `state.warning` fill | `#FFB03A` | 10.87 / 9.56 / 8.25 |
| `state.info` fill | `#6FA8DC` | 7.84 / 6.89 / 5.95 |
| `college.identity` fill | `#B07BD6` | 6.27 / 5.52 / 4.76 |

Measured constraints, binding on every consumer:

- **Every ink role meets 4.5:1 against all three surfaces in both appearances.** The worst pairing
  is `content.quiet` on `raised` — 4.97 dark, 4.78 light — and it is the value the legible seam also
  takes, so the two floors move together.
- **The state fills are not inks.** `#FF3B54` measures **4.30** on `raised`: above the 3:1
  non-text/large-text floor, below the 4.5:1 body floor. It fills chips, rules and indicators and
  colours large text; working prose in that role takes the ink form `#FF8E9C` (6.87 on `raised`).
  The same separation governs every state role, which is why the two tables are kept apart.
- **A filled control inks with the ground, never with `content.primary`.** Floodlit's `goldInk`
  `#150F02` on the gold fill measures 12.08, on positive 11.07, on warning 10.47, on live 5.45.
  `content.primary` on those same fills measures 1.51 / 1.64 / 1.74 / 3.34 and is never used on
  them. `world.page` is an equivalent ink (12.55 on gold) and either may be named.
- **Body text over a lit world requires the deep panel — this is a contrast rule, not a taste
  one.** Floodlit's standard panel fill is white at 0.055; composited over the brightest point of
  the lit pitch (`#37A868`) it resolves to `#42AD70`, on which `content.primary` measures **2.69**
  and `content.secondary` **1.42**. The deep fill `#08070E` is therefore specified at **α ≥ 0.78**,
  not the 0.70 the prototype shipped, because 0.70 leaves `content.quiet` at 4.30 over that worst
  case. At 0.78 the panel composites to `#122A22` over the brightest turf and to `#08080F` over
  night, and `content.primary` / `content.secondary` / `content.quiet` measure 14.52 / 7.68 / 5.03
  at worst. A standard panel may carry labels and figures over a lit world; it may not carry prose.
- **`content.quiet` is `#8496AC`, not Floodlit's `#65788F`.** The prototype value measures
  4.37 / 3.85 / **3.32** and fails the body floor on every surface. The lift is a correction, and it
  is recorded here so it is not silently reverted to match the prototype.
- **`field.annotation` at 3.96 on turf is a non-text indicator** — the first-down rule — and clears
  the 3:1 floor for that use only. A *label* drawn on the field takes the light form `#FFE196`
  (4.90 on turf). One gold cannot do both jobs and the two are named separately.
- **Hairlines and boundaries, named.** There are two hairline jobs and they take different values,
  because they are doing different work:
  - **Structural rule** — separating continuous regions of one surface. Draws in `world.raised`
    over `work` (1.16 dark, 1.25 light). It is deliberately near-invisible: it groups, it does not
    signal, and a rule the eye stops on is a container pretending to be a rule.
  - **Legible seam** — where a divider must actually be seen, on a `raised` surface or against
    generated colour. Draws in `content.quiet` (4.97 on dark `raised`, 4.78 on light).
  - **Glass edge** — Floodlit's panels also carry a 1 pt hairline tracing the cut shape, which is
    what makes a pane read as glass rather than a hole. It is a **structural** rule by the test
    above and carries no meaning; it never substitutes for the legible seam.
  - The **mandatory team-fill boundary** is `content.secondary`, which is the legible case at its
    strongest, and it is required on every team fill (see the team-fill rule below).

  Neither hairline carries meaning alone; §6.3's boundary-value-spoken rule governs.

**Team colour reference trio (labelled synthetic — pending generator output, owner disposition
2026-08-12; the P2 generator's sampled space is uniformly dark-primary).** Floors:
`team.onTeam`-on-`team.primary` 4.5:1; `team.secondary`-on-`team.primary` 3:1.

| Pair | `team.primary` | `team.secondary` | `team.onTeam` | onTeam/primary | secondary/primary |
|---|---|---|---|---|---|
| dark-primary | `#14382A` | `#D9B23C` | `#F2F5F3` | 11.74 | 6.37 |
| light-primary | `#E9E0C9` | `#6E3038` | `#18202B` | 12.47 | 7.45 |
| low-chroma | `#555B66` | `#D9DDE4` | `#FFFFFF` | 6.83 | 5.01 |

- **`field.turfBand` is a mow band, never an information channel.** Added 2026-08-12: the match view
  draws twelve 8.333% bands across the 120-yard field, giving a 10-yard distance gauge that survives
  a delete test. Its contrast against `field.turf` is deliberately near-invisible (1.12 dark, 1.07
  light) — it must read as ground texture, not as data, and nothing may be encoded in which band a
  mark falls on. Everything drawn over it keeps its own floor: `field.line` measures 5.22 dark /
  13.68 light on the band, `field.annotation` 3.55 / 5.04 (non-text), `field.live` 4.32 / 5.11.
  **The band count is twelve, not Floodlit's twenty.** The prototype's `MownBands` draws twenty
  alternating bands, which yields a six-yard gauge and fails the delete test this rule exists to
  pass. Canon governs; the port takes twelve.
- **Team fills against the work surfaces (re-measured 2026-08-14 against the Floodlit surfaces):**
  dark-primary on dark `work` 1.35, on light `work` 12.45; light-primary on dark `work` 13.25, on
  light `work` 1.27; low-chroma on dark `work` 2.55, on light `work` 6.60. Every trio primary falls below the 3:1 non-text floor
  against its tonally-similar surface, so the rule is general, not a low-chroma special case:
  **a team-colour fill always carries the hairline boundary**, because generated colour cannot be
  assumed to clear the floor against any given surface. This is §6.3's boundary-value-spoken rule
  made mandatory for team colour.

**Surface treatment — rewritten 2026-08-14 for Floodlit.** The prior rule was *"No gradients, glow,
glass, fake paper, leather, cork or decorative shadow. Surfaces are matte and opaque."* Floodlit is
built on the first three, so the rule is restated around what it was actually protecting: no imitated
material, no depth that is not real depth, and no decoration that survives a delete test.

**Permitted, and constitutive of the system:**

- **The lit world.** A screen happens somewhere. The backdrop is one of the register's worlds —
  pitch, facility floor, film room, or the desk density they recede into — and it is drawn with
  gradient because light falls off. The world never carries data.
- **Glass at depth under one light.** A panel blurs what is behind it, carries a hairline at its
  cut edge, and takes a sheen from the upper left. **The light direction is the same on every
  screen and in every world**; a sheen from another direction is a defect, not a variant.
- **Grain over everything.** A fixed-seed noise tile at low opacity, identical between runs so it
  can be cached. It is texture, not information.
- **Glow** where a real light source is depicted — a floodlight shaft, a projector throw, a lit
  marker on the field. Glow that emanates from a control or a card is not a light source.

**Still forbidden, and the reasons are unchanged:**

- Imitated material: fake paper, leather, cork, wood, brushed metal, stitching, torn edges.
- Shadow that does not encode the depth order in this section. A card is not lifted because a
  shadow was added; the shadow follows the depth, never the other way round.
- Gradient inside a control to suggest a physical button, and gradient used to carry a value —
  proportion is drawn as an arc per §6.5, never as a colour ramp.
- More than the depth levels named here: world, standard panel, deep panel. A panel over a panel
  over a panel is a container pretending to be hierarchy.

**Blur budget.** `.ultraThinMaterial` over a 3D-transformed world is the most expensive thing the
product draws, and P13 gates on a 16.7 ms frame. **At most two material panels are live per screen**
— the dominant object's and one secondary region's. Every other panel takes the opaque equivalent
from the table above. A screen that wants a third has a composition problem, not a performance
problem.

**Reduce Transparency flattens the system, and this is binding.** When the accessibility setting is
on, every panel takes its opaque equivalent, the grain is dropped, and the world is replaced by
`world.page`. The composition, the depth order and every contrast ratio in this section must survive
that substitution unchanged — which is what the opaque equivalents are for, and why they are the
values the ratios are measured against rather than the composited glass. This joins Reduce Motion in
§7 as a setting with a defined reduced form, and it is testable by construction: a surface with no
Reduce Transparency branch has not had it considered.

Hairlines separate continuous regions; containers exist only for interaction, grouping or clipping.

### 6.2 Typography

Use the system family in production and a system stack in references. The hierarchy relies on scale,
weight and width, not a dozen tiny roles.

Do not substitute a generic “sports” display font for hierarchy. A bundled face may be evaluated
later only if its licence, full Dynamic Type range, numerals, localisation and VoiceOver behaviour
are verified without shrinking working text.

| Role | Default floor | Use |
|---|---:|---|
| Display | 20 pt | score, career moment, singular identity |
| Title | 17 pt | screen or dominant object |
| Headline | 15 pt semibold | local decision or story |
| Body | 12 pt | working prose and comparison rows |
| Callout | 11–12 pt | evidence and supporting facts |
| Caption | 10–11 pt | metadata, column labels and dense table cells |
| Numeral | 10–28 pt tabular | table ratings through score, clock, money and rank |
| Broadcast numeral | 20–34 pt tabular, compressed heavy | score, clock, down and distance in BROADCAST furniture only |

**Width axis (codified 2026-08-12).** The system family's width variants are part of the voice, not
a decoration: Display, Title and Headline ship condensed (`.width(.condensed)` in
`DesignTokens.swift` — the shipped choice, now stated in canon); Body, Callout and Caption stay
standard width, because condensing working prose buys density at the cost of reading comfort.
`Broadcast numeral` is the one compressed role: the BROADCAST register's square geometry earns the
densest width for score, clock and distance, and nowhere else. Compressed never sets prose;
Expanded is unused in v1. Reference sheets approximate width with `font-stretch`, which desktop
Chrome renders only approximately — the native render is authoritative.

Standard management screens may use 10–12 pt micro-type to reach desktop-class management density
on landscape iPhone. Working prose stays at 12 pt; 10–11 pt is reserved for short labels, ratings, metadata and
tabular cells. AX5 scales these semantic roles and reflows to one readable path; it does not preserve
the dense multi-pane composition. Diagram marks may remain fixed only when an equivalent accessible
sentence is present.

- Numeric columns use tabular figures (`monospacedDigit()` in SwiftUI); prose does not become
  monospaced merely to look technical.
- Micro-type uses tight tracking around −0.2 pt where it prevents wrapping without harming
  recognition.
- Custom sizes are wrapped in `@ScaledMetric` so the default composition remains dense while
  accessibility categories can expand and reflow it.
- **Production mapping (G-07 write-back, 2026-08-12):** `DesignTokens.swift` maps the roles to
  system text styles — Display = title3 heavy condensed (20 pt at Large), Title = headline heavy
  condensed (17 pt), Headline = subheadline semibold condensed (15 pt), Body/Callout = footnote
  (13 pt), Caption = caption (12 pt) — all Dynamic-Type-scaling by construction (verified per-style
  tables, sourcing row Q5: Body-class styles reach 44–53 pt at AX5). The shipped constants
  `authoredFloor = 12` and `workingProse = 13` sit at or above this section's 12 pt floors; the
  floor is the contract, the constants are the current choice.

**Floodlit mapping (2026-08-14).** The ramp does not move. Floodlit's display face is the system
family at `.width(.condensed)`, which is what this section already mandates for Display, Title and
Headline, so the visual change is carried by colour, surface and composition rather than by type.
Three things are settled here because the prototype and this section disagree:

- **The micro-label moves to 10 pt.** Floodlit's `Label3` — the tracked uppercase field label used
  throughout — ships at 9 pt with 0.2 em tracking. That is below this section's 10 pt Caption floor
  and below `04b` §8's authored-type check. It is a **Caption** and its floor is 10 pt. Its tracking
  is kept: uppercase micro-labels are the one place tracking above −0.2 pt is correct, because they
  are read as shapes rather than words.
- **A gradient type fill is measured at its worst stop.** Floodlit's `litFill()` runs a headline
  from white to `#93A8C0` so it reads as lit from above. The contrast that counts is the bottom of
  the glyph, not the top: `#93A8C0` measures 8.12 / 7.14 / 6.16 on page / work / raised and 6.23 on
  the deep panel over the brightest turf, so it clears the body floor everywhere and is permitted.
  Any future gradient fill is measured the same way, and the rule is general.
- **Fixed point sizes do not survive the port.** Every size Floodlit authored as a literal —
  including the 66 pt day name and the 34 pt gauge figure — is wrapped in `@ScaledMetric` against
  the role it belongs to, per the bullet above. A fixed-size display figure inside a fixed-height
  container is the exact defect `AUDIT.md` recorded 19 times in the prior build.

### 6.3 Shape, spacing and touch

- Base spacing steps: 4, 6, 8, 12, 16, 20. **Unchanged under Floodlit** — the prototype's 7, 9, 11,
  14, 15 and 21 snap to this scale on import. A design system with two spacing scales has none.
- **Corners are cut asymmetrically (2026-08-14).** A panel reads as a deliberate shape rather than a
  default card because its four radii differ. `RoundedRectangle` cannot express this, so the shape
  is drawn by hand as `CutCorner(topLeading:topTrailing:bottomTrailing:bottomLeading:)`:

  | Shape | Radii (TL / TR / BR / BL) | Use |
  |---|---|---|
  | Panel | 4 / 22 / 4 / 22 | any surface holding content |
  | Row | 3 / 14 / 3 / 14 | table rows, chips, free-standing rows |
  | Action | 22 / 22 / 22 / 5 | the committing control — soft on three corners, cut on the last |

  Continuous table row radius stays 0: a run of rows is one surface, and cutting each row's corners
  turns a table into a stack of cards. Broadcast radius stays 0.
- The **9-degree college cut** in §5 is identity furniture and is separate from these radii. The two
  never appear on the same element.
- Primary actions and irreversible controls remain at least 44 × 44 pt.
- Dense table rows use explicit 24–28 pt tracks in the default composition. AX5 expands and reflows
  them rather than forcing micro-type into an accessibility layout.
- Selected items receive boundary, value and spoken state; never a coloured fill alone.
- Icons use SF Symbols as one coherent line family. Emoji are prohibited.
- Repeated utilities may become icon-first: inspect film, delegate, pause, speed and tactical view.
  Their accessible names remain explicit. Destinations and irreversible decisions retain visible text;
  a familiar icon may support that label but never replace its meaning.

### 6.4 High-density SwiftUI component pipeline

The management register deliberately departs from default iOS `List` and `Form` spacing to reach
desktop-class management density.

1. **Micro-typography and tabular numbers**
   - Ratings and short statistics use 10–12 pt custom system fonts, tight tracking and one-line
     truncation.
   - Numeric columns apply `.monospacedDigit()` so values align and do not jitter.
   - `@ScaledMetric` owns custom sizes; AX5 receives a larger reflow rather than clipped micro-type.

   ```swift
   Text("\(rating)")
       .font(.system(size: 11, weight: .bold))
       .monospacedDigit()
       .tracking(-0.2)
       .lineLimit(1)
   ```

2. **Zero-inset dense containers**
   - Prefer `ScrollView` with `LazyVStack(spacing: 2)` or `LazyVGrid` over a default padded list.
   - Dense rows use explicit 24–28 pt heights and minimal 2–4 pt internal padding.
   - When `List` is required, remove automatic row insets with
     `.listRowInsets(EdgeInsets())`.

3. **Modular data tiles**
   - Scouting summaries, roster depth, cap space, coach chemistry and similar bounded readouts may
     use `LazyVGrid` with `GridItem(.adaptive(minimum: 160))`.
   - Tiles share a compact header/value/evidence grammar rather than default iOS card spacing.
   - `ViewThatFits` switches a multi-column landscape composition to stacked tiles on narrower
     devices or larger accessibility categories.

4. **Heatmaps, rating badges and micro gauges**
   - Replace repeated prose bands such as Elite/Average/Poor with fixed-size numeric badges when the
     rating is simulation-owned.
   - Use red below 70, amber from 70–84 and green from 85 upward as the default visual heat scale;
     retain the printed number and a spoken band so colour is not the sole meaning.
   - Thin progress bars or compact gauges may represent stamina, roster fit, development progress,
     portal interest or scouting confidence.

   ```swift
   Text("\(value)")
       .font(.system(size: 10, weight: .bold, design: .monospaced))
       .frame(width: 20, height: 16)
       .background(ratingColour.opacity(0.85))
       .clipShape(RoundedRectangle(cornerRadius: 3))
   ```

5. **Context-preserving inspection**
   - Player, prospect, contract and play-call previews open in a `Popover` or detented sheet rather
     than replacing the management screen.
   - Use `.presentationDetents([.fraction(0.35), .medium])` for short inspection flows.
   - Selection, drafts, clocks and save boundaries remain in the game model so dismissing an
     overlay restores the exact prior context.

### 6.5 Component registry

*Adopted 2026-08-12 from `docs/briefs/2026-08-12-reference-library-plan.md` §3, including its five
stated renames/merges relative to the deleted a60f4d9 registry (`AttributeRow` folds into
`DenseTable` plus `ConfidenceTag`; `Chip` splits into `StatusChip` and `RoleToken`; `Sparkline`
becomes `FormLine`; `StakeholderCard` and `MapCanvas` defer to their owning families).* §6.4's
pipeline is this registry's constructor; the P11 three-production-uses rule governs promotion, and
entries not yet promoted are provisional. Names map 1:1 onto Swift types in
`Sources/ProFootballCoachUI/`.

| # | Registry name | Purpose |
|---|---|---|
| 1 | `CoachWorldRouteButton` | Local-route navigation control |
| 2 | `CoachWorldActionButtonStyle` | Decide/inspect/delegate action styling with roles |
| 3 | `coachWorldDeskSurface` | Matte opaque panel treatment, hairline rules |
| 4 | `CoachWorldBlankPhotoPlate` | Neutral person plate, no generated face |
| 5 | `WorldStrip` | Programme/club, coach, date/phase, record, next advance |
| 6 | `IdentityBand` | Person-led stable header for sequenced disclosure |
| 7 | `DenseTable` | 24–28 pt tracked rows, sortable header, selection rule |
| 8 | `ColumnSet` | Segmented swap of fact columns over stable identity columns |
| 9 | `ListControls` | Sort/filter/bounded-search over simulation objects |
| 10 | `RatingBadge` | Fixed-size numeric badge, printed number plus spoken band |
| 11 | `DeltaMark` | Per-value recent-change mark with sentence equivalent |
| 12 | `ConfidenceTag` | Banded value / unknown / observation-count state |
| 13 | `VerdictLine` | Engine-backed judgement line heading a readout |
| 14 | `Meter` | Capacity track with defined over-capacity state |
| 15 | `OpposedBar` | Two-team shared-track comparison |
| 16 | `FormLine` | Bounded last-N results with rating thread |
| 17 | `StatusChip` | Closed vocabulary per §4.5; at most three per row |
| 18 | `RoleToken` | Short role/assignment code mapping list to diagram |
| 19 | `AgendaRow` | Obligation with cost/time-to-event and completion state |
| 20 | `ScoreBug` | Teams, score, quarter, clock, down, distance, possession |
| 21 | `LowerThird` | Causal what-just-happened card on the field |
| 22 | `CallInCard` | Named staff proposal, accept/dismiss/inspect |
| 23 | `EmptyState` / `ErrorBanner` / `InterruptedState` | The failure set, inside the owning composition |

**Floodlit primitives (added 2026-08-14).** The same 1:1 naming rule applies: each maps onto a Swift
type in `Sources/ProFootballCoachUI/`. Entries 24–28 are the surface and depth vocabulary §6.1 now
depends on; 29–32 are the proportion vocabulary; 33–35 are drawn identity marks.

| # | Registry name | Purpose |
|---|---|---|
| 24 | `CutCorner` | The asymmetric panel/row/action shape of §6.3, with its inset conformance |
| 25 | `GlassPanel` | Blurred pane at depth: standard and deep, the deep fill at α ≥ 0.78 per §6.1 |
| 26 | `GrainOverlay` | Fixed-seed noise tile above every screen; dropped under Reduce Transparency |
| 27 | `WorldBackdrop` | The register made visible — pitch, facility, film room, desk |
| 28 | `Stage` | Safe-area-owning content inset; owns physical edges, never a fixed device rect |
| 29 | `ArcGauge` | A proportion as an arc — the large form |
| 30 | `ValueRing` | The table-scale ring: a value inside its own proportion |
| 31 | `AttributeDial` | Concentric arcs, one per attribute, radius carrying the value |
| 32 | `ShareBar` | A horizontal share where a comparison sits in a row rather than a ring |
| 33 | `StarRating` | Recruiting stars drawn as blades |
| 34 | `Pennant` | The club mark as a depicted object |
| 35 | `TimeoutMarks` | Timeouts remaining; a filled mark is one in hand |

**The proportion rule (29–32).** Where a datum is a share of a whole, the form is an arc, not a bar
— the same primitive from a 26 pt table cell to a 212 pt dial, which is what holds the language
together at density. `ShareBar` is the stated exception, for comparisons that must sit inline in a
row. An arc always keeps its printed figure: the ring is a second reading of a number, never a
replacement for one, and §6.1's heat banding gives the third.

**Promotion status.** Entries 24–35 enter **provisional** under the P11 three-production-uses rule,
exactly as 5–23 did. They are drawn from a prototype with five screens, so none has three production
uses yet; the proof gate in §10 is where 24–32 earn theirs.

Adoption cost, carried knowingly: the registry is an audit surface (each entry needs its
three-production-uses record or an explicit provisional mark); screen-local implementations of
5–7, 10, 17 and 19–22 owe extraction refactors when promoted — P11/M8 work, not a silent rename;
and this section must stay synchronised with `Sources/ProFootballCoachUI/`, enforced through the
existing `ContractTests.swift` source-contract pattern.

### 6.6 The symbol register

*Added 2026-08-12, closing the defect the personnel-proof review names as F-02 and §5: every sheet
priced its symbol spend locally and then asserted global compliance, which no sheet can know.*
**This section is the one place the totals are held.** A symbol drawn anywhere in the product must
appear below; one that does not is a finding under §4.5, not a licence. The enforcing contract test
is gap G-08, and it walks `Sources/ProFootballCoachUI/ScreenRegistry.swift` by construction rather
than from a hand list.

Symbols are capped **per class**, because the classes are separate learning surfaces: a coach reads
a status chip on a roster row, a direction mark beside an attribute, and a session type on a week
grid in three different contexts. What is never permitted is an unbounded class.

| Class | Cap | Members | Where |
|---|---:|---|---|
| **Status** (`StatusChip`, registry 17) | 12 | `cross.case`, `bolt.slash`, `shield.slash`, `exclamationmark.triangle`, `clock.badge.exclamationmark`, `binoculars`, `hand.raised`, `graduationcap`, `arrow.uturn.left`, `star`, `checkmark.seal`, `calendar.badge.exclamationmark` | Any dense row; at most 3 per row |
| **Change** (`DeltaMark`, registry 11) | 2 | `arrow.up.right`, `arrow.down.right` | Attribute and rating rows |
| **Obligation** (`AgendaRow`, registry 19) | 2 | `checkmark.circle.fill` (complete), `person.badge.clock` (delegated) | Week plan, inbox, any obligation list |
| **Session type** (week grid) | 5 | `figure.run`, `film`, `airplane`, `football`, `moon.zzz` | Practice Plan week grid only |
| **Broadcast marks** (§9) | 3 | possession wedge, key-moment mark, timeout mark (`TimeoutMarks`, registry 35) | Match Day chrome only; each carries a printed or spoken value beside it, never counts alone |
| **Rating marks** (§5 identity) | 1 | star blade (`StarRating`, registry 33) | Recruiting and draft evaluation only; always beside its printed figure |
| **Empty-state marks** (`EmptyState`, registry 23) | 6 | `person.3`, `person.crop.rectangle`, `list.number`, `checkmark.circle` | Empty and unavailable states only. Enumerated but **not a learned class**: every empty state carries a title and a description sentence, so the mark orients and the words inform. Bounded anyway, because an unbounded class is what this table exists to prevent |
| **Control furniture** | not a learned class | `chevron.*`, `magnifyingglass`, `line.3.horizontal.decrease`, `rectangle.3.group`, `pause.fill`, `forward.end.fill`, `speedometer`, `checkmark`, `person.2`, `plus`, `xmark` | Navigation and controls; every one carries a visible or accessible label, so none is a symbol the player must learn. §6.3 anticipates the icon-first utilities (inspect film, delegate, pause, speed, tactical view) and requires their accessible names to stay explicit |

**Total learned symbols: 25** (12 status + 2 change + 2 obligation + 5 session + 3 broadcast +
1 rating). **Moved from 23 on 2026-08-14 by the owner decision adopting Floodlit**, which brings two
drawn marks with it: the timeout mark and the recruiting star blade. Both are drawn shapes rather
than SF Symbols, so they sit outside §6.3's one-line-family rule and are held to the same
displacement discipline instead. Floodlit's `Pennant` is **not** counted: a club mark is identity
furniture under §5, not a vocabulary item the player learns.

The last two rows of the table are **capped but not learned**: a control is read from its label and an empty state
from its title and description, so neither adds to what the player must recall. They are enumerated
and bounded regardless, because an unbounded class is the leak this table exists to detect. Control furniture
is excluded by the rule above — a marked control is read from its label, not recalled from a
vocabulary. **The 25 is stated so it can be argued with; it is the number the owner is agreeing to
when a class grows.** Filled and unfilled variants of one symbol are one member: `hand.raised.fill`
is `hand.raised`, and `circle` is the unchecked state of `checkmark.circle.fill` rather than a
thirteenth status symbol or a new class. Where two components want the same meaning they take the same member — a
delegated receipt is `person.badge.clock` on every surface, not `person.fill.checkmark` on one.

Growth rule: a new symbol displaces an existing member of its class or the class cap moves, and a
class cap moves only by owner decision recorded here. §4.5 names vocabulary growth as the leak
detector; this table is the detector. Custom symbols drawn on Apple's variable template (three
weights, exported per symbolset) are eligible members under the same displacement rule and join
§6.3's one-coherent-line-family requirement — a custom glyph that reads as a different family is a
defect, not a style.

**The definitive design references (owner-approved 2026-08-12).** Eight sheets at the repository
root render this registry: `tokens-v3.dc.html`, `chrome-v3.dc.html`, `table-v3.dc.html`,
`person-v3.dc.html`, `readout-v3.dc.html`, `week-v3.dc.html`, `broadcast-v3.dc.html`,
`failure-v3.dc.html`, with full-page renders and an index in `docs/proofs/design-references/`.
Every `04` §8 screen family is built against them. They supersede the deleted `*-v2.dc.html`
library entirely; any earlier rendered library, mockup set or design pass is historical evidence
and carries no authority. **The sheets remain a rendering — this document is the only canonical
home, and a value appearing only in a sheet has not shipped.** Where a sheet and `04` disagree,
`04` wins and the sheet is the defect.

**The verdict-state rule, one rule for the whole library (2026-08-12).** Registry 13 `VerdictLine`
has exactly one drawing convention, because three sheets shipped three different ones and each is a
build instruction. Every surface that will carry a verdict draws **both** states and labels them:
the **shipping form** is the verdict slot empty with its gap ID in place, because G-02 does not
exist and §4.4 rejects invented authority; the **target form** is the populated verdict — staff
name, sample size, confidence, and the computation class that backs it — marked "once G-02 lands".
The populated form is never the unlabelled default, and never appears at width or AX5 renditions
without the shipping form beside it. A verdict at high confidence is not the only case worth
drawing: a thin sample and a low-confidence judgement are what make a simulation honest under
uncertainty, so a surface that can produce them draws one.

## 7. Device and accessibility contract

*Window rewritten 2026-08-12 under D15 (option b) from verified sizes — Apple HIG Layout via
sourcing rows Q4–Q5, gate two passed (`docs/briefs/2026-08-12-sourcing-log.md`).*

Production promises landscape iPhone at **852 × 393 through 956 × 440** (iPhone 15 Pro class and
newer; all five window sizes Apple-verified: 852 × 393, 874 × 402, 932 × 430, 956 × 440, and the
844 × 390 `e`/base class below the promise). The **install floor stays 844 × 390**: below-promise
devices can always install, so every surface renders un-clipped and reachable there forever; the
promise floor is where the full budget must hold (two-tier `SmallestDeviceLayoutTest`, D15). Both
sensor orientations, light/dark appearances, compact/regular landscape width classes and AX5 are
binding.

Landscape safe-area insets are per-model and secondary-sourced (sensor edge / home edge): 59/21 for
the 15 generation and base 16; 62/21 for the 16 Pro class; 62 sides with 20 top and bottom for the
17 generation. Recorded gaps, not guessed: 16e landscape insets and the 17e are unsourced — measure
before relying on either. The 44 × 44 pt touch floor is HIG-verified (Apple's stated minimum is
28 × 28 pt; this contract keeps the stricter 44 pt).

- Safe areas are owned at physical edges, not guessed from a preferred orientation. **Floodlit's
  `Metrics.device` (844 × 390) is a preview reference frame only** — the size its prototype gallery
  renders at. It is never a layout constraint, never a `.frame(width:height:)` on a screen, and no
  view resolves a position against it. Composition is proportional across the window above.
- The initial viewport contains the dominant object and any decision due now.
- AX5 may scroll vertically. The focused action remains reachable without crossing a hidden shelf.
- VoiceOver order follows world context → dominant object → evidence → actions → local navigation.
- Reduce Motion replaces travel, reveal and field animation with discrete state changes.
- **Reduce Transparency flattens the visual system (added 2026-08-14).** Every panel takes the
  opaque equivalent named in §6.1, the grain is dropped and the world is replaced by `world.page`.
  Composition, depth order and every measured contrast ratio survive the substitution unchanged —
  which is why §6.1 measures against the opaque equivalents rather than the composited glass. A
  surface with no Reduce Transparency branch has not had it considered.
- Sound and haptics have visual and spoken equivalents.
- Loading never displays invented percentage progress.
- Empty, error, interrupted and resume states remain inside the composition they belong to.

### 7.1 What the AX5 contract asserts in the suite — added 2026-08-13

G-12 asks for an AX5 instrument that enumerates families **by construction**. The enumeration is
settled here; the rendering is not, and the difference is stated rather than blurred.

**The enumeration.** Families come from `CoachWorldScreenID` in `ScreenRegistry.swift`, and a family
is *landed* when a view named for it exists — `coachingHQ` → `CoachingHQView.swift`. Every one of
the 62 families is therefore either landed and checked, or pending and named. The suite asserts that
partition is total, so a view added tomorrow is inside the contract the day its file appears rather
than the day someone remembers to list it.

**What is asserted of a landed family, and what each clause stands for.**

1. It declares an accessibility-size composition (`dynamicTypeSize.isAccessibilitySize`). A screen
   with no AX5 branch has not had AX5 considered; this catches the omission, not the quality.
2. It declares deterministic VoiceOver order (`accessibilitySortPriority`). This is the
   world-context → dominant-object → evidence → actions → navigation rule above, made checkable.

**What is not asserted, and must not be claimed.** *No datum lost* and *no clipping* are properties
of a render, and the suite is a headless executable with neither XCTest nor a view host — it cannot
see a laid-out frame. The two clauses above are the source-visible proxy for having done the work,
not evidence that the work is correct. **The rendered limb of G-12 stays open**, and its mechanism —
snapshot versus layout assertion, and which target can host it now that full Xcode is present — is
`03b` §5's to decide and the owner's to schedule. An audit under `04b` may not score AX5 above 3 on
the strength of this suite alone.

## 8. Canonical v1 screen inventory — 62 families

Counting rule: a screen is a distinct player-facing destination or task surface. Loading, empty,
error, success, disabled, delegated, interrupted, confirmation, first-week teaching, AX5 and resume
are states beneath their owning screen. Tabs that preserve the same object and task are modes, not
new screens.

### Entry and system — 7

| # | Screen | Dominant object |
|---:|---|---|
| 1 | Title / Continue | current career and durable boundary |
| 2 | New Career & Coach Identity | coach premise and generated universe |
| 3 | Job Board | three defensible starting jobs |
| 4 | Offer | terms and accept/decline consequence |
| 5 | Appointment | stakeholder handoff and programme identity |
| 6 | Settings & Accessibility | device, match and accessibility choices |
| 7 | World Search | bounded index across people, teams, games and history |

### Week and match — 8

| # | Screen | Dominant object |
|---:|---|---|
| 8 | Coaching HQ | current week plan and next obligation |
| 9 | Inbox | conversations and commitments with cost |
| 10 | Opponent Report / Film Room | observed film, staff interpretation and confidence |
| 11 | Game Plan | weekly tactical keys and trade-offs |
| 12 | Practice Plan | scarce practice minutes across units |
| 13 | Team Health | availability, fatigue, injury and return decisions |
| 14 | Match Day | full field, score, current cause and call-ins |
| 15 | Aftermath | result, causal review and recovery consequence |

### Team and staff — 8

| # | Screen | Dominant object |
|---:|---|---|
| 16 | Roster | sortable legal team sheet |
| 17 | Depth Chart | spatial roles, packages and succession |
| 18 | Player Profile | role, story, form, confidence and history |
| 19 | Development Plan | current focus, staff ownership and opportunity cost |
| 20 | Staff Room | assignments, continuity and unit performance |
| 21 | Staff Market & Profile | candidate comparison, contract and scheme relationship |
| 22 | Scheme Book | offensive/defensive identity and adoption cost |
| 23 | Personnel Packages | situation-specific on-field assignments |

### College acquisition and offseason — 10

| # | Screen | Dominant object |
|---:|---|---|
| 24 | Recruiting Board | ranked live target board |
| 25 | Prospect Profile | evaluation, relationship, fit and uncertainty |
| 26 | Shortlist | monitored prospects and next contact |
| 27 | Contact & Visit Planner | weekly contact budget and scheduled visits |
| 28 | Class Overview | needs, commitments, capacity and class history |
| 29 | Signing Day | timed commitment feed and unresolved choices |
| 30 | Portal Hub | window, roster exposure and movement summary |
| 31 | Retention Decisions | departure risk, promise and NIL trade-offs |
| 32 | Portal Market | available players, fit, competition and capacity |
| 33 | NIL Allocation | finite programme pool distributed across the roster |

### Professional front office — 7

| # | Screen | Dominant object |
|---:|---|---|
| 34 | Cap & Contracts | legal ledger, commitments and future years |
| 35 | Contract Negotiation | term, guarantee, role and cap consequence |
| 36 | Roster Cuts & Transactions | legality deadline and loss of depth |
| 37 | Pro Scouting Board | uncertain draft and market evaluations |
| 38 | Draft Board | ranked prospects, needs and scouting investment |
| 39 | Draft Room | timed pick sequence and trade-off at the clock |
| 40 | Free Agency | live market waves, competing bidders and offers |

### League and competition — 11

| # | Screen | Dominant object |
|---:|---|---|
| 41 | League Map | place, distance, regions and rivalry context |
| 42 | Team / Programme Profile | identity, trajectory, venue and history |
| 43 | Standings | current competitive order and tiebreak meaning |
| 44 | Schedule | season chronology and preparation rhythm |
| 45 | Rankings & Playoff Picture | selection position, neighbours and path |
| 46 | Bracket / Postseason | live elimination path |
| 47 | Game Detail / Box Score | result, drives, turning points and participation |
| 48 | Statistics & Leaders | bounded comparison with context and sample |
| 49 | Awards & Honours | season and career recognition |
| 50 | News | editorial world events, bounded newest-first |
| 51 | Realignment Event | map change, cause and consequence |

### Career and legacy — 9

| # | Screen | Dominant object |
|---:|---|---|
| 52 | Career Hub | chronological story of the coach |
| 53 | Job Security | expectation, movement, cause and jeopardy |
| 54 | Stakeholders | relationships, voices and recent triggers |
| 55 | Promotion Decision | college-to-pro offer with a real decline path |
| 56 | Coaching Carousel | open jobs, interest and non-dead-end outcomes |
| 57 | Record Book | bounded records across the save |
| 58 | Rivalries | history, current stakes and accumulated strength |
| 59 | Career Line | roles, seasons, records and defining moments |
| 60 | Coaching Tree | staff relationships and career descendants |

### Offseason command — 2

| # | Screen | Dominant object |
|---:|---|---|
| 61 | College Offseason | dated sequence linking signing, portal, NIL, staff and carousel |
| 62 | Pro Offseason | dated sequence linking cuts, contracts, market, draft, staff and carousel |

Any new surface requires an amendment here, a read-model owner, a navigation location and a reason it
cannot be a mode of an existing family.

## 9. Match Day

Match is the strongest game-authenticity gate.

- The complete 120-yard field remains in frame, with both end zones, line of scrimmage and first-down
  line.
- Native drawing may add restrained turf bands, yard lines, hash marks and field numbers. Route
  vectors appear only when the recorded read model supplies that route; decorative or invented
  movement is prohibited.
- **The play-art vocabulary is fixed (added 2026-08-12):** route vectors as recorded polylines,
  formation dots per §6.5 #18's role tokens, the line-of-scrimmage and first-down rules, and the
  §6.6 broadcast marks. Route-tree and formation notation are drawn conventions of the sport, not
  protected expression; a specific playbook's diagrams are someone's expression and are never
  reproduced. Every fixed diagram mark carries §6.2's accessible-sentence equivalent.
- **The anchor contract (G-06, specified 2026-08-14; `03` owns the computation).** The view is
  handed, per snap: offense direction, line of scrimmage, first-down line, ball point, a point per
  actor with its display token, emphasis flags, route polylines where the resolution recorded one,
  playback phase and the causal commentary. The UI may interpolate between anchors, fade, highlight
  and zoom within safe bounds, and draw the stadium and field. It may **not** choose a route, alter
  an outcome, invent a missed assignment, or infer a matchup from the animation. Anchors are derived
  from the same resolution the commentary is built from, so the picture and the spoken sentence
  cannot diverge — that identity is the reason the contract exists, and it is what makes the
  VoiceOver limb of §7 true rather than parallel.
- Offense direction is recorded data. It owns defended end-zone labels and whether the first-down
  line lies left or right of the line of scrimmage; the view never guesses from home/away colour.
- All 22 actors are represented; no more than three are visually foregrounded at once.
- The field owns the usable frame. No management header, card grid or destination bar appears.
- The scorebug names teams, score, quarter, clock, down, distance and possession.
- A causal lower third answers what just happened and why it matters.
- The five primary controls are Speed, Pause, Key Moments, Take Over and Tactics.
- A call-in is a named staff proposal with accept, dismiss and inspect-evidence paths.
- Animation visualises an already-recorded outcome and cannot change simulation truth.

## 10. Proof and production gates

Before production SwiftUI begins, three interactive proof screens must be owner-approved together:

1. **Coaching HQ** — proves week rhythm, world context and local decision anatomy.
2. **Recruiting Board** — proves dense comparison, people, relationships and uncertainty.
3. **Match Day** — proves broadcast immersion, spatial football and live intervention.

They depict one continuous fictional save: Carson Tech, head coach Eric Mercer, Week 9, Southern
State as the current opponent, and consistent staff/recruit consequences. Personnel photographs are
neutral blank plates. The reference sheets hold themselves to the same one-save rule with their own
fixed cast, moment and figure table — `docs/briefs/2026-08-12-reference-shared-world.md`; a sheet
identity or figure outside that file is a defect.

Each proof renders at 844 × 390 (install floor), 852 × 393 (promise floor) and 956 × 440 (ceiling)
per §7 and D15, light and dark, default and AX5. It must score at least 31/40 under `04b`, with no
P0/P1 and none of the §4.4 automatic rejection conditions.

**Proof medium (amended 2026-08-12, owner-approved plan).** The proofs are the native SwiftUI
screens — Coaching HQ, Recruiting Board and Match Day — reached through the DEBUG `PROOF_SCREEN`
routing in `RootView.swift` and rendered at native size on simulator. They are production code
paths, not reference HTML; earlier language calling proof code reference-only described the HTML
era and is superseded. What does not change: a proof's read model stays fixture-fed and declares
`provenance: .sample` until G-01 lands, an approved proof never authorises invented read-model
values, and feature families beyond the three proofs begin only after the owner approves the set
together.
