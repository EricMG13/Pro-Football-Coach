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
row from a global vocabulary of at most twelve, each changing a decision; at most one verdict line
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

No gradients, glow, glass, fake paper, leather, cork or decorative shadow. Surfaces are matte and
opaque. Hairlines separate continuous regions; containers exist only for interaction, grouping or
clipping.

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

Standard management screens may use 10–12 pt micro-type to reproduce Football Manager Touch
density. Working prose stays at 12 pt; 10–11 pt is reserved for short labels, ratings, metadata and
tabular cells. AX5 scales these semantic roles and reflows to one readable path; it does not preserve
the dense multi-pane composition. Diagram marks may remain fixed only when an equivalent accessible
sentence is present.

- Numeric columns use tabular figures (`monospacedDigit()` in SwiftUI); prose does not become
  monospaced merely to look technical.
- Micro-type uses tight tracking around −0.2 pt where it prevents wrapping without harming
  recognition.
- Custom sizes are wrapped in `@ScaledMetric` so the default composition remains dense while
  accessibility categories can expand and reflow it.

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
Football Manager Touch density.

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

Adoption cost, carried knowingly: the registry is an audit surface (each entry needs its
three-production-uses record or an explicit provisional mark); screen-local implementations of
5–7, 10, 17 and 19–22 owe extraction refactors when promoted — P11/M8 work, not a silent rename;
and this section must stay synchronised with `Sources/ProFootballCoachUI/`, enforced through the
existing `ContractTests.swift` source-contract pattern.

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

- Safe areas are owned at physical edges, not guessed from a preferred orientation.
- The initial viewport contains the dominant object and any decision due now.
- AX5 may scroll vertically. The focused action remains reachable without crossing a hidden shelf.
- VoiceOver order follows world context → dominant object → evidence → actions → local navigation.
- Reduce Motion replaces travel, reveal and field animation with discrete state changes.
- Sound and haptics have visual and spoken equivalents.
- Loading never displays invented percentage progress.
- Empty, error, interrupted and resume states remain inside the composition they belong to.

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
neutral blank plates.

Each proof renders at 844 × 390 and 932 × 430, light and dark, default and AX5. It must score at
least 31/40 under `04b`, with no P0/P1 and none of the §4.4 automatic rejection conditions.

Proof code is reference-only. It does not define SwiftUI architecture, simulation truth or persisted
data. Production implementation begins only when its read model exists and the owner approves the
proof direction.
