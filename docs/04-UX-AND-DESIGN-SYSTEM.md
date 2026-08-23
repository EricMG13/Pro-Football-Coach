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
| **Coach's Office** | Run the week | week plan, correspondence, pressure, staff notes | disciplined seams, writable schedules, restrained motion — a plan changes state, it does not travel to prove it |
| **Personnel Room** | Build and develop the team | team sheet, depth chart, player dossier, medical and staff files | dense comparison where earned; identity-led detail; a value settles to its new figure, it does not slide there |
| **Acquisition Room** | Compete for future talent | recruiting board, territory, relationship history, offer ledger | live market movement, physical ranking/territory cues — the one register where a rank *may* travel, because the movement is the fact being reported |
| **Front Office** | Keep the pro roster legal and competitive | cap ledger, contracts, draft board, market | harder steel geometry, transaction receipts, clocks only when real; a receipt confirms, it does not animate in |
| **League & Media** | Understand the living world | map, standings, schedule, stories, records | editorial hierarchy; data tied to teams, games and history; a standing resettles in place between weeks |
| **Career & Legacy** | Read the coach's story | timeline, stakeholders, jobs, rivals, record book | chronological composition; earned ceremony — one entrance, held, never a repeating flourish |
| **Film Room** | Study evidence | field film, tendencies, matchup evidence, staff interpretation | dark analytical environment; annotation belongs to evidence and appears with it, never before it |
| **Broadcast** | Experience live or timed football | full field, score, clock, causal commentary, call-in | square geometry, team identity, no management chrome; the register that actually animates — the ball's flight, the live dot's pulse, the panel push, per §6.1b and §9 |
| **Ceremony** | Mark an irreversible career moment | appointment, signing, promotion, trophy | rare, focused, minimal controls; the "earned ceremony" §6.7 names — held, not looped |

No screen may describe itself as “Film Room” unless it belongs to that row.

### 2.1 The presentation lean (2026-08-22 amendment)

The nine registers above say what a screen **is about**. They do not say how much presentation it may
spend. That is a second, orthogonal axis with three positions, and **every surface carries one of
each**.

The axis is **whether the player is being told something or working something out.** Frequency does
not set it; frequency only decides how much spectacle is affordable once the side is picked. A
frequency-first rule was tested against the §8 inventory and classifies Match Day as a working
surface because it is seen fifteen times a season, which is plainly wrong.

| Lean | The player is | Ground | Mark | Largest numeral | Data points |
|---|---|---|---|---|---|
| **Broadcast** | being told | club or opponent colour, flooded | 200–390 pt | 40–72 pt | ≤ 12 |
| **Desk** | working | `world.page`; club colour confined to the identity band | 19 pt | 11–14 pt | ≤ 72 |
| **Dossier** | meeting a subject, then studying it | club colour above the seam, `world.page` below | 180–220 pt above | 40 pt above, 11.5 below | ≤ 8 above, ≤ 40 below |

**Default lean per register.** Broadcast and Ceremony take the Broadcast lean. Coach's Office,
Acquisition Room, Front Office, League & Media and Career & Legacy take the Desk lean. Personnel Room
takes Desk for its lists and Dossier for its dossiers — its row above already distinguishes “dense
comparison where earned” from “identity-led detail”. Film Room takes Desk.

**Match Day is the only surface carrying two leans at once** — a Broadcast ground with a Desk plate on
it. That is not an exception to be tolerated but the product's central claim; §9 governs it.

**A Dossier surface is marked by exactly one visible seam**, a 2 pt `action.primary` rule, at the
point the lean changes. A Dossier surface with no seam, or with two, is a finding.

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

Density is spent in six currencies: points, taps, working memory, learned symbols, verdict lines and
motion. A management screen may spend: one dominant object (at least 60% of the initial viewport) and
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
change mark without a retained delta is fabrication under §4.4. **Motion is spent only to carry a
state change that is already true without it** — a value settling to its new figure, a panel
entering, a snap replaying — never to manufacture meaning motion alone supplies; every duration and
curve is drawn from §6.7's closed register, the same discipline §6.6 already holds symbols to. At
AX5 the composition reflows to one column preserving order and dropping nothing. A screen is over
budget when a second dominant object appears, the glyph vocabulary grows to accommodate it, type
falls below its floor to make something fit, AX5 loses data, or a state change is illegible without
watching it animate. The registry's per-screen budget statements are audited under `04b`; a surface
the inventory does not price is a finding, not a licence.

#### 4.5a The measured budget (2026-08-22 amendment)

The currencies and caps above stand. What follows are the measured numbers behind them, which this
section previously stated only as ratios.

At the install floor the content box is 709 × 319 pt, but the **usable scroll viewport measures
291 pt**, and **241 pt** once a surface reserves a committing bar outside the scroll. The budgets
follow from the viewport, not from the box:

| Tier | Row height | Viewport | Rows | Columns | Cells |
|---|---|---|---|---|---|
| Dense | 32 pt | 291 | 9 | 8 | **72** |
| Working | 44 pt | 291 | 6 | 8 | **48** |
| Committing | 44 pt | 241 | 5 | 8 | **40** |
| Broadcast | — | 390 | — | — | **12** |

Eight columns is the working figure inside this section's existing six-to-nine range.

**Interactivity is bought with rows.** A row that responds to touch takes the 44 pt control floor, so
nine readout rows become six; reserving a commit bar takes six to five. A surface carrying a
committing control therefore has **40 cells, not 72**, and must be composed against that number.

A surface exceeding its tier's cell count is over budget by construction, in the same sense the
clauses above define over-budget. **The count is of declared data**, not of rendered elements: chrome,
labels, captions and prose are not cells.

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

### 5.2 Canonical team marks

*Revised 2026-08-20. The base universe ships one approved primary mark for every canonical
default-seed team.*

- **Packaged artwork.** Each primary mark is generated offline with AI, reviewed by a human, and
  packaged as a text-free PNG asset. Silhouettes are unrestricted; the mark may be abstract,
  figurative, or emblematic, provided it remains original to the fictional universe and obeys §5's
  colour and recognition rules.
- **Stable lookup.** `team.mark` is an optional asset reference resolved by a stable catalogue key
  for the canonical default-seed UUID. The mark is presentation data, not simulation state: an
  alternate-seed team or an unavailable packaged asset receives `nil` and the UI renders the
  legible abbreviation fallback.
- **Runtime boundary.** The shipped app performs no AI generation, network fetch, prompt handling,
  or external-image lookup for team marks. It only resolves its packaged catalogue assets.
- **Where it appears.** The §5 slots remain the only places a team mark may appear: world strip,
  scoreboard, uniform mark, and ceremony surface. At chip scale it may accompany the abbreviation,
  while the adjacent team name retains the accessible identity.
- **Originality gate.** Exact and near-duplicate checks protect the packaged set, but automated
  checks do not establish legal clearance. A human performs a manual similarity review before a
  mark is approved; the owner retains final originality and real-team-similarity approval.

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

The owner-supplied Football Manager captures are the temporary production proxy for density,
navigation proportions, panel rhythm and typographic hierarchy. DESK therefore defaults to a
near-navy workspace with restrained violet navigation/action furniture and compact opaque panels.
The game does not copy FM marks, icons, photographs, club identities or branded artwork.

**Production values (G-07 write-back, 2026-08-12).** These are the shipped values from
`Sources/ProFootballCoachUI/DesignTokens.swift`, written back so no sheet or view claims a value
canon does not hold. Every ratio is measured WCAG 2.2 relative-luminance contrast against the
surface the role is actually composited on (floors: 4.5:1 body text, 3:1 large text and non-text —
SC 1.4.3/1.4.11, verified sources in `docs/briefs/2026-08-12-sourcing-log.md`). A code/canon sync
check is owed by `ContractTests` (gap G-07's test half).

| Role | Dark | on page / work / raised | Light | on page / work / raised |
|---|---|---|---|---|
| `world.page` | `#080A14` | — | `#F1F2F7` | — |
| `world.work` | `#111426` | — | `#FBFBFD` | — |
| `world.raised` | `#191D32` | — | `#E6E8F0` | — |
| `content.primary` | `#F4F5FA` | 18.13 / 16.74 / 15.27 | `#111426` | 16.31 / 17.64 / 14.90 |
| `content.secondary` | `#B8BDCC` | 10.52 / 9.71 / 8.86 | `#4D5366` | 6.84 / 7.40 / 6.25 |
| `content.quiet` | `#858CA2` | 5.89 / 5.44 / 4.96 | `#596074` | 5.61 / 6.07 / 5.12 |
| `action.primary` | `#9964E8` | 5.02 / 4.64 / **4.23** | `#6840B0` | 6.37 / 6.89 / 5.82 |
| `action.secondary` | `#B8BDCC` | 10.52 / 9.71 / 8.86 | `#4D5366` | 6.84 / 7.40 / 6.25 |
| `action.destructive` | `#F07886` | 7.27 / 6.72 / 6.12 | `#A42D32` | 6.26 / 6.77 / 5.72 |
| `state.live` | `#72D7A0` | 11.23 / 10.37 / 9.46 | `#4A6F00` | 5.27 / 5.70 / 4.82 |
| `state.positive` | `#6FD39A` | 10.77 / 9.95 / 9.07 | `#1F7048` | 5.41 / 5.86 / 4.95 |
| `state.warning` | `#F0C56C` | 12.13 / 11.21 / 10.22 | `#765300` | 6.25 / 6.76 / 5.71 |
| `state.negative` | `#F07886` | 7.27 / 6.72 / 6.12 | `#A42D32` | 6.26 / 6.77 / 5.72 |
| `state.info` | `#72ADEC` | 8.37 / 7.73 / 7.05 | `#205F96` | 5.98 / 6.47 / 5.47 |
| `college.identity` | `#A861D6` | 5.03 / 4.64 / **4.23** | `#6840B0` | 6.37 / 6.89 / 5.82 |
| `pro.identity` | `#5B9DE0` | 6.90 / 6.38 / 5.81 | `#2D628B` | 5.81 / 6.29 / 5.31 |
| `field.turf` | `#163E2A` | — | `#DCE8DF` | — |
| `field.turfBand` | `#1A452F` | 1.10 on `field.turf` | `#D2E0D6` | 1.08 on `field.turf` |
| `field.line` (on turf) | `#F5F7FA` | 11.14 | `#0E1218` | 14.89 |
| `field.annotation` (on turf) | `#E7C45D` | 7.09 | `#7A5200` | 5.49 |
| `field.live` (on turf) | `#C6F24E` | 9.23 | `#4A6F00` | 4.67 |

Measured constraints, binding on every consumer:

- **Dark `action.primary` and `college.identity` on `raised` measure 4.23** — above the 3:1
  non-text/large-text floor, below the 4.5:1 body floor. On raised surfaces they may colour
  controls, icons and large text, never working prose.
- **Dark filled-violet controls use dark ink.** `content.primary` on dark `action.primary` measures
  3.61 (large text only); dark `world.page` ink on the same fill measures 5.02 and is the body-text
  pairing. Light-appearance fills are unconstrained (`world.work` on `action.primary` = 6.89).
- Every other role/surface pairing above meets 4.5:1 in both appearances.
- **Filled-control ink pairings (measured 2026-08-12, same method):** dark `world.page` ink on a
  dark `state.live` fill measures 11.23; light `world.page` ink on the light `action.primary` fill
  measures 6.37 (so the shipped light filled-violet ink passes alongside the 6.89 `world.work`
  pairing); light `world.work` ink on the light `state.live` fill measures 5.70. All meet the
  4.5:1 body floor.
- **Heat-fill badge inks (measured 2026-08-12):** the rule generalises — a filled control or badge
  inks with the palette's own ground. Dark `world.page` ink on the dark heat fills: positive 10.77,
  warning 12.13, negative 7.27. Light `world.work` ink on the light heat fills: positive 5.86,
  warning 6.76, negative 6.77. The opposite pairings measure 1.49–3.01 and are not used for text.
- **Hairlines and boundaries, named.** There are two hairline jobs and they take different values,
  because they are doing different work:
  - **Structural rule** — separating continuous regions of one surface. Draws in `world.raised`
    over `work` (1.10 dark, 1.18 light). It is deliberately near-invisible: it groups, it does not
    signal, and a rule the eye stops on is a container pretending to be a rule.
  - **Legible seam** — where a divider must actually be seen, on a `raised` surface or against
    generated colour. Draws in `content.quiet` (4.96 on dark `raised`, 5.12 on light).
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
  a delete test. Its contrast against `field.turf` is deliberately near-invisible (1.10 dark, 1.08
  light) — it must read as ground texture, not as data, and nothing may be encoded in which band a
  mark falls on. Everything drawn over it keeps its own floor: `field.line` measures 10.11 dark /
  13.75 light on the band, `field.annotation` 6.43 / 5.07, `field.live` 8.37 / 4.31.
- **Team fills against the work surfaces (measured 2026-08-12):** dark-primary on dark `work` 1.41,
  on light `work` 12.47; light-primary on dark `work` 13.86, on light `work` 1.27; low-chroma on
  dark `work` 2.67, on light `work` 6.61. Every trio primary falls below the 3:1 non-text floor
  against its tonally-similar surface, so the rule is general, not a low-chroma special case:
  **a team-colour fill always carries the hairline boundary**, because generated colour cannot be
  assumed to clear the floor against any given surface. This is §6.3's boundary-value-spoken rule
  made mandatory for team colour.

No gradients, glow, glass, fake paper, leather, cork or decorative shadow. Surfaces are matte and
opaque. Hairlines separate continuous regions; containers exist only for interaction, grouping or
clipping. **Superseded for the Floodlit register by §6.1a below** — the prohibition stood while the
production proxy was the FM captures; it does not survive the Floodlit cutover.

### 6.1a Floodlit palette and material (2026-08-16 amendment, dark-only)

Approved 2026-08-15 (`docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`). This
section replaces §6.1's dark production values and retires the light column entirely: **Floodlit is
dark-only.** There is no production light palette, no derived light register, no user-facing
appearance switch, and the app keeps its appearance when the system appearance changes. §7's
"light/dark appearances... binding" requirement is retired by this amendment; only dark is binding.

Role names are unchanged from §6.1 — every view keeps reading `palette.actionPrimary`,
`palette.stateWarning` and so on — only the hex each role resolves to changes, plus `Palette.light`
is deleted. Ratios below are the same WCAG 2.2 relative-luminance method as §6.1, against the actual
`page`/`work`/`raised` grounds.

| Role | Hex | on page / work / raised |
|---|---|---|
| `world.page` | `#060A12` | — |
| `world.work` | `#100E16` | — |
| `world.raised` | `#12203A` | — |
| `content.primary` | `#F6FAFF` | 18.90 / 18.27 / 15.49 |
| `content.secondary` | `#A9BACE` | 10.00 / 9.67 / 8.20 |
| `content.quiet` | `#7A8A9E` | 5.62 / 5.43 / 4.61 |
| `action.primary` | `#FFC53D` | 12.55 / 12.14 / 10.29 |
| `action.secondary` | `#A9BACE` | 10.00 / 9.67 / 8.20 |
| `action.destructive` | `#FF3B54` | 5.67 / 5.48 / 4.64 |
| `state.live` | `#37E08A` | 11.50 / 11.12 / 9.43 |
| `state.positive` | `#4FD08C` | 10.13 / 9.79 / 8.30 |
| `state.warning` | `#FFB03A` | 10.87 / 10.51 / 8.91 |
| `state.negative` | `#FF3B54` | 5.67 / 5.48 / 4.64 |
| `state.info` | `#6FA8DC` | 7.84 / 7.58 / 6.43 |
| `college.identity` | `#B07BD6` | 6.27 / 6.07 / 5.14 |
| `pro.identity` | `#6FA8DC` | 7.84 / 7.58 / 6.43 |
| `field.turf` | `#072616` | — |
| `field.line` (on turf) | `#F6FAFF` | 15.44 |
| `field.annotation` (on turf) | `#FFCE6A` | 11.01 |
| `field.live` (on turf) | `#4FD08C` | 8.27 |

Measured constraints, binding on every consumer:

- **`content.quiet` clears 4.5:1 on all three grounds** (4.61 on `raised`, its lowest), so unlike
  §6.1's v3 values it needs no working-prose exemption; §6.1's general rule that quiet stays out of
  working prose is a density choice here, not a contrast requirement.
- **Filled-control ink reuses `world.page` as the dark ink**, the pattern the shipped
  `CoachWorldActionButtonStyle` already implements (`page.color` as foreground on a filled action).
  Measured on every fill: `action.primary` 12.55, `state.live` 11.50, `state.positive` 10.13,
  `state.warning` 10.87, `state.info` 7.84, `state.negative`/`action.destructive` 5.67. All clear
  4.5:1; no new ink token is introduced.
- **The team-colour fill rule is unchanged and still binding**: `dark-primary` team fill against the
  new `world.raised` measures 1.26, `content.secondary` as the mandatory hairline on it measures
  6.51. A team fill still always carries the boundary.

**Material.** Glass, grain, blur and a directional sheen are permitted for the Floodlit register,
implemented exactly as `CoachWorldFloodlitStage`, `CoachWorldFloodlitPanelModifier` and
`CoachWorldGrainOverlay` already ship: `.ultraThinMaterial` plus an opacity-scaled fill from §6.1's
existing `Depth.glassPanelOpacity` (0.56) and `Depth.deepPanelOpacity` (0.82) — `.82` remains the
lowest value that preserves 4.5:1 body text when a panel crosses a mown stripe and a floodlight beam.
**Reduce Transparency removes glass, grain and blur and falls back to opaque `world.work` /
`world.raised` fills at the same depth order** — already implemented, and mandatory: no consumer may
render glass without the Reduce Transparency branch.

**Geometry.** §6.3's flat radius table is superseded for panels, rows and committing controls by an
asymmetric four-corner shape (`CutCorner`, independent `topLeading`/`topTrailing`/`bottomTrailing`/
`bottomLeading` radii — `RoundedRectangle` cannot express this). Three named presets:

| Preset | Radii (pt) | Use |
|---|---|---|
| `.panel` | 4 / 22 / 4 / 22 | House panel shape — glass panels, cards |
| `.row` | 3 / 14 / 3 / 14 | Rows and chips — tighter variant of `.panel` |
| `.action` | 22 / 22 / 22 / 5 | Committing controls — soft on three corners, cut on the last |

College identity furniture may take one restrained 9° cut per §5; Pro stays orthogonal. BROADCAST
radius stays 0 — square geometry is unchanged by this amendment. **Superseded for Match Day alone
by §6.1b (2026-08-18).**

#### 6.1a(ii) Role separation (2026-08-22 amendment)

The palette above carries four role collisions, measured in HSL from the shipped
`DesignTokens.swift`:

| Colliding roles | Values | Separation |
|---|---|---|
| `action.primary` / `state.warning` | `#FFC53D` / `#FFB03A` | **6.1°** hue, identical saturation, 0.6% luminance |
| `state.negative` / `action.destructive` | `#FF3B54` / `#FF3B54` | identical |
| `state.info` / `pro.identity` | `#6FA8DC` / `#6FA8DC` | identical |
| `state.live` / `state.positive` | `#37E08A` / `#4FD08C` | **1.1°** hue |

Both contrast tables above remain correct; contrast was never the defect. The defect is that two
roles which must never be confused are the same colour at a glance.

The first collision is the serious one: at 11 pt under a thumb, a caution and a commit are
indistinguishable.

**Gold — `action.primary` `#FFC53D` — marks the committing action and the live first-down line, and
carries no other meaning.** It is never a rating, never a state, never a position chip, never
decoration. **A surface spends gold at most once**, twice only on Match Day where the second is the
first-down line.

Consequently `state.warning` leaves the yellow-orange band. Its replacement must sit at least 24°
from gold's hue of 42.1° and clear 4.5:1 on `world.page`; **`#C9704A` satisfies both**, at 24.1° and
5.57:1.

The three identical or near-identical pairs stay legal as **aliases** — `action.destructive` may
alias `state.negative` — but must be declared as aliases in the token layer rather than repeated as
literals, so a future divergence is a deliberate edit and not an accident.

### 6.1b Match Day broadcast register (2026-08-18 amendment)

Source: the owner-supplied design handoff `design_handoff_floodlit_surfaces_and_match_day/`
(`MATCH-DAY.md`, `FLOODLIT-SURFACES.md`, `README.md`). It carries the same authority as the
2026-08-15 Floodlit spec §6.1a records, and where the two disagree this section is the later
decision.

**What changes.** §6.1a closed with "BROADCAST radius stays 0 — square geometry is unchanged by
this amendment", and §9 has read since the rebuild began as *no desk chrome, cards, gradients,
glow or decorative broadcast effects on a live match surface*. Match Day as drawn is glass
furniture with cut corners floating over a gradient turf plane, with one gold-glowing committing
action. **Those two rules are retired for the Match Day surface only**, and replaced by the
constraints below. Aftermath, box score and every other `.broadcast` surface keep §6.1a's square,
flat treatment until a design says otherwise.

The reason the old rule existed still holds and is restated as a constraint rather than a ban:
decoration must never sit between the coach and the state of the game. So:

- **Nothing decorative may carry meaning.** Glow marks the one committing action and the
  first-down line, and nothing else. A panel's material never encodes a value.
- **The field is the dominant object** (§4.1). Furniture is glass over it, never a card beside it.
- **Reduce Transparency still removes glass, grain and blur** on this surface exactly as
  `CoachWorldFloodlitStage` already implements. No consumer may render glass without that branch.
- **Reduce Motion still removes the ball's flight, the live dot's pulse and the panel push.**

**Geometry.** Match Day takes the same `CutCorner` presets §6.1a names, extended by six the
handoff's per-surface table adds. All are on `CoachWorldCutCorner`:

| Preset | Radii (pt) | Use |
|---|---|---|
| `.card` | 4 / 18 / 4 / 18 | Scorebug, call-in budget bug, staff call-in panel |
| `.alert` | 4 / 24 / 4 / 24 | Alert surfaces |
| `.block` | 4 / 20 / 4 / 20 | Blocks |
| `.wide` | 3 / 18 / 3 / 18 | Wide rows — the halftime plan's slot rows |
| `.actionSmall` | 18 / 18 / 18 / 4 | Small committing controls |
| `.playCard` | 14 / 14 / 6 / 6 | Call-in options, halftime footer action |

**Frame.** The install floor is 844 × 390 (§7). Left-anchored furniture clears the sensor housing
at `59 + 4 = 63`; the bottom band clears the home indicator at `21 + 4 = 25`; the trailing gutter is
`20`; top furniture sits at `12`. Minimum tap target stays 44.

**Colour.** The values below are the Floodlit ramp the handoff ships, in addition to §6.1a's roles.
Ratios are the same WCAG 2.2 relative-luminance method §6.1 uses.

| Token | Hex | Carries text? | Measured |
|---|---|---|---|
| `room-deep` | `#07060B` | ground | `content.primary` 19.27, `content.secondary` 10.19 |
| `turf` | `#1C6E42` | field ground | `field.line` 5.97 |
| `turf-hot` | `#37A868` | field ground | — |
| `turf-crown` | `#2A8850` | field gradient stop | — |
| `turf-mid` | `#124E2E` | field gradient stop | — |
| `turf-shade` | `#0A311D` | field gradient stop | — |
| `turf-night` | `#05150D` | field gradient stop | — |
| `lamp` | `#FFF2CE` | floodlight pool | 17.78 on `page` |
| `gold-light` | `#FFE196` | yes | 15.53 on `page` |
| `gold-deep` | `#D89713` | gradient stop | — |
| `gold-ink` | `#150F02` | yes, on gold fill | 12.08 on `action.primary`, 14.95 on `gold-light` |
| `live-ink` | `#FF8E9C` | yes | 9.06 on `page` |
| `go-ink` | `#7DF0B6` | yes | 14.16 on `page` |
| `cool-ink` | `#9CC8EE` | yes | 11.24 on `page` |
| `club-field` | `#0F5637` | ground | `club-ink` 7.71 |
| `club-ink` | `#EAF3EE` | yes | 7.71 on `club-field` |
| `opponent-field` | `#123A5E` | ground | `opponent-accent` 6.45, `opponent-ink` 8.46 |
| `opponent-accent` | `#9CC5E8` | yes | 10.91 on `page`, 6.45 on `opponent-field` |
| `opponent-ink` | `#C7DEF3` | yes | 8.46 on `opponent-field` |
| `endzone-opponent` | `#1B2431` | end zone fill | — |
| `bowl-ink` | `#C9A968` | yes | 8.79 on the bowl bug's ground |
| `ball-highlight` | `#A6572A` | ball gradient | — |
| `ball-mid` | `#7A3E1C` | ball gradient | — |
| `ball-shade` | `#46220F` | ball gradient | — |

**One handoff value is refused: `ink-3` `#65788F`.** It measures 4.37 / 4.23 / 3.58 on
`page` / `work` / `raised` and so fails 4.5:1 on every ground, including the two it is drawn on.
§6.1a's `content.quiet` `#7A8A9E` is the same role at 5.62 / 5.43 / 4.61 and is what ships wherever
the handoff writes `ink-3`. The handoff's "the prototype's literal value wins" rule governs
paddings and hues; it does not override §7's accessibility contract.

**Type.** The handoff's literal px scale (66 / 60 / 54 / 52 / 40 / 34 / 25 / 20 / 19 / 17 / 16 /
15 / 14 / 12 / 10.5 / 9) is a *drawing* scale in Archivo Narrow. In the app it is
`Font.system(size:).width(.condensed)`, and SF Pro Condensed sets wider at the same point size, so
every value below `display-lead` is subject to the sizing pass §6.2 already requires. §6.2's 12 pt
authored floor is unchanged and binding: the handoff's 10.5 pt and 9 pt values are permitted **only**
for tracked uppercase micro-labels, which §6.2 already exempts, and never for prose.

### 6.1c Floodlit management chrome (2026-08-18 amendment)

Source: the same owner-supplied handoff §6.1b records, `FLOODLIT-SURFACES.md` §1 and §2. Where
§6.1b governs the one broadcast surface, this section governs every **management** surface: the
shared stage they all render inside, and the eight moves they are all built from.

**The stage.** Composed at the install floor with absolute positions. There is no tab bar and no
nav rail beyond the icon column — navigation lives in the identity header, family on the left and
jump-to on the right.

| Element | Geometry |
|---|---|
| World backdrop | full bleed, bottom bleed 0.55, receding as density rises but never absent |
| Identity header | top 3, leading 115, trailing 20; two rows, 22 then 16 |
| Icon rail | leading 59, top 46, width 44; 44 pt targets, `.row` radius, 2 pt gaps |
| Content | leading 115, top 46, to the trailing gutter at 20 — max width **709** |
| Grain | over everything, 128 px tile, overlay, 0.5 |

`844 − 115 − 20 = 709`, so the content column is the frame minus the rail and the gutter, and the
number is derived rather than chosen. **Title, Job Board and Offer start at leading 63 and carry no
icon rail** — they sit outside the coaching week, so the rail would name places the player cannot
go from there.

**Three worlds, one variable.** The backdrop is `pitch | facility | film`, and it is the single
thing that changes per screen. It is a read-model fact, not a view's guess. **Film is the one place
the light goes cold**: its world is the projector beam and its glass loses the warm sheen every
other surface carries.

**Content column widths are deliberate, not fluid** (`FLOODLIT-SURFACES.md` §4): 150, 250, 300,
330, 345, 380, 396, 400, 402, 404, 410, 420, 428, 430, 474, 697, 709, 761. A surface either uses
the full 709 or a named narrower column with the world showing beside it.

**The hero object breaks the safe area on purpose** — the week arc, the jersey cut-out, the
attribute dial, the hand of play cards. Do not inset it to be tidy.

**Blur only where something is genuinely in front of something else.** Non-hero glass flattens to a
solid fill rather than stacking blur over a transformed plane, which smears. Two fills carry that:

| Token | Hex | Use | Measured |
|---|---|---|---|
| `glass-flat` | `#11141E` | non-hero glass, standard depth | `content.primary` 17.54, `content.secondary` 9.28 |
| `glass-flat-deep` | `#0B0D14` | non-hero glass, deep depth | `content.primary` 18.52, `content.secondary` 9.80 |
| `overlay-scrim` | `#04070C` | the registry overlay's ground | `content.primary` 19.25, `content.secondary` 10.19 |

**The eight composition patterns.** Every management surface is built from these and nothing else;
a surface that needs a ninth is a finding, not a licence. Names map 1:1 onto Swift types, and each
folds into §6.5's registry rather than starting a parallel one.

| Pattern | Spec |
|---|---|
| Glass panel | `.panel` radius, padding 11/15, 1 px white-13 hairline, 148° sheen, `shadow-panel` |
| Row / chip | `.row` radius, padding 10/12, min height 32–44, 1 px white-14, gold border on selection |
| Card | `.card` radius, padding 12/13 |
| Label3 | 9 pt uppercase, 0.2em tracking, quiet ink — **written sentence case in source and uppercased on render**, so the string stays readable to a translator |
| Arc family | one idea at four scales: `ValueRing` 26 → `ArcGauge` (panel) → `AttributeDial` 212 → `ShareBar` 4. An arc is permitted **only** where the datum is a proportion |
| Pill / Flag | the only capsules in the system. Pill 10.5, selected takes the gold field. Flag 9 at 1.35 px tracking |
| Staff voice | monogram avatar plus quoted advice, 11 pt in `content.secondary`, curly quotes, em dash for the turn |
| Committing action | one per screen, bottom-right in the thumb arc: gold field, `.action` radius, `glow-gold`, 14 pt/700 uppercase verb |

**Costs, not recommendations.** Every option on a decision surface carries a cost in clock time, an
attributed staff voice, and an exposure, then a consequence with a real arrow (`Gains four → fourth
and three`). The interface never says which to pick. This is §4.4's rejection of invented authority
stated as a layout rule.

**One accessibility carve-out, and its remedy.** The identity header's second row is 16 pt tall and
its sibling links are 9.5 pt text — well under §6.3's 44 pt minimum target. The row height is
load-bearing for the header's two-row proportion, so the visible text keeps its drawn size and each
link carries a **44 pt hit area** via an expanded content shape instead. Visible size and tappable
size are allowed to differ; tappable size is not allowed to drop below 44.

### 6.1d The identity band (2026-08-22 amendment)

§6.1c places a 19 pt mark in the identity header beside a separate icon rail. Club identity is
consequently near-absent from every management surface, which is what makes a football game read as a
database.

On every management surface the club's colour, mark, name and record are carried in a **single band
that encloses the whole of the navigation row** — mark, club name, record and rank, the family name,
the sibling tabs and the context slot all sit inside it. It is not a pill beside the navigation; the
navigation is inside it.

The band is **34 pt tall**, runs a gradient from the club's primary to `world.page`, and carries a
hairline of the club's secondary. Its mark is **19 pt** — the Desk lean's size under §2.1 — because
the band is the *only* place a Desk surface spends club colour.

The band is the sanctioned **seventh** placement for a team mark under §5.2, alongside the standings
row as the eighth. The team-colour fill rule in §6.1a applies unchanged: the band's gradient is a
team-colour fill and therefore always carries its hairline boundary.

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

### 6.3 Shape, spacing and touch

- Base spacing steps: 4, 6, 8, 12, 16, 20.
- DESK control radius: 8 pt; free-standing row radius: 8 pt; continuous table row radius: 0;
  surface radius: 10 pt.
- Broadcast radius: 0.
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
   - **Amended 2026-08-22.** The default visual heat scale over the 40–99 range is **five bands,
     diverging around a neutral centre** — not the three-band red/amber/green it replaces, under
     which an average starter read as a caution:

     | Band | Range | Role |
     |---|---|---|
     | Well below | 40–59 | `state.negative` |
     | Below | 60–69 | the amended `state.warning` |
     | **Average** | **70–79** | **`content.secondary` — neutral, never amber** |
     | Above | 80–84 | `state.positive`, lightened |
     | Well above | 85–99 | `state.positive` |

     Every band clears 4.5:1 on `world.page` and sits at least 24° from gold, per §6.1a(ii). Retain
     the printed number and a spoken band so colour is not the sole meaning — unchanged.
   - **Where a surface bands a rating it prints the band table on that surface.** This answers “is 74
     good?” without computing a live percentile, and degrades correctly in a save with no league
     history yet.
   - **A rating the simulation has not earned is drawn as a range, not a point.** Range width is the
     confidence: it narrows as observation accumulates, and a rating observed enough to be certain
     renders as a collapsed range (`83–83`), never as a different kind of number. An attribute with
     no observation at all prints the word — `Unseen` — never a blank, a dash or a zero. Where a
     range is drawn, the observation that produced it is drawn with it, so the player can see why the
     number is vague. This is §4.5's existing prohibition — “a band without a recorded observation …
     is fabrication under §4.4” — given a drawn form. It carries an engine dependency on a
     scouting-confidence model that does not yet exist; until that lands, surfaces render point
     values and **declare the gap** rather than implying a precision the engine cannot support.
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
| **Broadcast marks** (§9) | 2 | possession wedge, key-moment mark | Match Day chrome only; both carry a printed or spoken value beside them, never count alone |
| **Empty-state marks** (`EmptyState`, registry 23) | 6 | `person.3`, `person.crop.rectangle`, `list.number`, `checkmark.circle`, `clipboard` | Empty and unavailable states only. Enumerated but **not a learned class**: every empty state carries a title and a description sentence, so the mark orients and the words inform. Bounded anyway, because an unbounded class is what this table exists to prevent |
| **Control furniture** | not a learned class | `chevron.*`, `magnifyingglass`, `line.3.horizontal.decrease`, `rectangle.3.group`, `pause.fill`, `forward.end.fill`, `speedometer`, `checkmark`, `person.2`, `plus`, `xmark`, `calendar`, `tray.full`, `square.grid.3x3` | Navigation and controls; every one carries a visible or accessible label, so none is a symbol the player must learn. §6.3 anticipates the icon-first utilities (inspect film, delegate, pause, speed, tactical view) and requires their accessible names to stay explicit |

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

### 6.7 The motion register (added 2026-08-18)

*Written for values that were already shipping in `CoachWorldTokens.Motion`
(`Sources/ProFootballCoachUI/DesignTokens.swift`) with nowhere in this document naming them. The
tokens came from the owner's Floodlit design handoff; the handoff directory itself is not in the
repository, so until this section existed the values had no home a builder could read — exactly the
failure §6.6 closes for symbols, and the rule stated there applies here without amendment: **this
document is the only canonical home, and a value appearing only in code has not shipped.**

Motion is capped the same way symbols are, because an uncapped motion vocabulary is the same leak as
an uncapped glyph vocabulary: every curve and duration the player learns to read is a class, and an
unbounded class is a finding under §4.5.

**One curve for the whole product.** `timingCurve(0.32, 0.72, 0, 1)` — a fast-in, gentle-out ease
used for every timed transition. No second curve may ship without amending this line first; if a
surface needs a different feel, that is a finding against this section, not a reason to add a curve
inline. **`pulse`'s repetition is not a second curve** — `.repeatForever(autoreverses:)` runs the
same one curve back and forth; the shape of a single cycle is unchanged, only its recurrence.

| Duration | Seconds | Reduced form | Where used |
|---|---:|---|---|
| **press** | 0.12 | discrete: the pressed state applies with no dim | A committing control's press feedback |
| **value** | 0.22 | discrete: the new figure appears, no settle | A rating, score or attribute value changing |
| **world** | 0.42 | discrete: the destination appears, no travel | A world-scale transition — screen to screen, register to register |
| **panelEnter** | 0.24 | discrete: the panel is present or absent, never entering | The staff call-in panel's entrance |
| **pulse** | 1.5 | discrete: the live indicator is shown at full opacity, never dimming | The live-snap dot, `04:448`'s named example — a period, not a state-change duration, so it is the one row that repeats rather than resolving once |

**Companions, not durations:**

| Token | Value | What it is |
|---|---:|---|
| **panelPushDistance** | 14 pt | How far `panelEnter` travels a panel in from its edge |
| **pressDim** | 0.12 | How far a committing control dims on press — a dim, never a scale, so a control never shrinks under the thumb committing it |
| **disabledOpacity** | 0.4 | The resting opacity of a disabled control. Not paired with an animation — a control does not animate into disabled, it simply is — but it ships from `Motion` alongside the values that do, so it belongs in this table rather than nowhere |

**The reduced-form rule, stated once rather than four times.** `04:826` already requires it globally:
Reduce Motion replaces travel, reveal and field animation with discrete state changes. Applied to
this table, a reduced form is never "the same animation, faster" — duration collapsing to near-zero
still asks a screen reader and a motion-sensitive player to track something moving. It is the
*destination state*, presented immediately, exactly as `04:448` already requires for Match Day: the
ball's flight, the live dot's pulse and the panel push are removed, not accelerated.

**Nothing here licenses a screen to animate.** §2's per-register motion phrase and §4.5's motion
currency decide *whether* a state change may carry motion at all; this table only fixes *how*, once
that permission exists. A screen that animates without an entry in §2's row for its register is a
finding under §4.4 regardless of whether the duration is drawn from this table.

**One file holds both halves of this contract in code: `Sources/ProFootballCoachUI/CoachWorldMotion.swift`.**
It is the single definition site for this table's values — necessarily exempt from the literal-number
scan that polices every consumer, the same way a token's own declaration is not itself a violation —
and it is the only file permitted the raw vocabulary (`Animation.timingCurve`, `withAnimation`,
`.repeatForever`) that schedules motion at all. Every other file reaches motion through
`.coachWorldAnimation(_:value:)` or `.coachWorldPulse()`, never directly, so an off-token duration or
an un-reduced animation is unrepresentable outside this one file rather than merely catchable in it.

## 7. Device and accessibility contract

*Window rewritten 2026-08-12 under D15 (option b) from verified sizes — Apple HIG Layout via
sourcing rows Q4–Q5, gate two passed (`docs/briefs/2026-08-12-sourcing-log.md`).*

Production promises landscape iPhone at **852 × 393 through 956 × 440** (iPhone 15 Pro class and
newer; all five window sizes Apple-verified: 852 × 393, 874 × 402, 932 × 430, 956 × 440, and the
844 × 390 `e`/base class below the promise). The **install floor stays 844 × 390**: below-promise
devices can always install, so every surface renders un-clipped and reachable there forever; the
promise floor is where the full budget must hold (two-tier `SmallestDeviceLayoutTest`, D15). Both
sensor orientations, compact/regular landscape width classes and AX5 are binding. **Light/dark
appearances is retired by §6.1a (2026-08-16): Floodlit is dark-only, with no user-facing appearance
switch and no derived light register.**

Landscape safe-area insets are per-model and secondary-sourced (sensor edge / home edge): 59/21 for
the 15 generation and base 16; 62/21 for the 16 Pro class; 62 sides with 20 top and bottom for the
17 generation. Recorded gaps, not guessed: 16e landscape insets and the 17e are unsourced — measure
before relying on either. The 44 × 44 pt touch floor is HIG-verified (Apple's stated minimum is
28 × 28 pt; this contract keeps the stricter 44 pt).

- Safe areas are owned at physical edges, not guessed from a preferred orientation.
- The initial viewport contains the dominant object and any decision due now.
- AX5 may scroll vertically. The focused action remains reachable without crossing a hidden shelf.
- VoiceOver order follows world context → dominant object → evidence → actions → local navigation.
- Reduce Motion replaces travel, reveal and field animation with discrete state changes.
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
3. **Added 2026-08-18.** If it uses a construct §6.7 cannot wrap in the choke point —
   `TimelineView`, `matchedGeometryEffect`, `phaseAnimator`, `keyframeAnimator`, `symbolEffect` — it
   also declares `accessibilityReduceMotion` is read. `04:826`'s reduced-form requirement is a
   contract clause the enumeration machinery already existed to check; this is `ReduceMotionContractTest`,
   the release gate `PRODUCT.md` already names, made to actually run rather than exist as a
   registered name with nothing behind it.

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
  **G-06's anchor contract is `03` §9, added 2026-08-17.** Match Day draws play art from a recorded
  anchor set: alignment starts come from the §9.4 position template, and movement ends come from the
  identities the outcome records. Sheets that have not yet adopted the anchor set still draw play art
  in target form only.
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
