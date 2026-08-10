# 04 — UX and Design System

A design system built from zero, then the screens, then the match view — the hardest surface.
Includes the D12 accessibility contract in full.

The previous build scored **9/20** on `04b`'s rubric with accessibility at **1/4**. Every structural
choice here is aimed at making that class of failure impossible rather than merely discouraged.

---

## 1. Principles

1. **A literal in a view is a defect.** Spacing, radius, colour and font size come from tokens. The
   build fails on a literal (`03b` §1). The prior build wrote this rule down and accumulated 43
   literal spacings against it.
2. **Measured surfaces, not idealised ones.** A colour is verified against the surface it is
   actually composited on, in both appearances.
3. **Enumerate by construction.** Any test over a class of surfaces derives its list from the token
   set and component registry, never from a hand-written list.
4. **Every screen is a place to decide or a place to look**, and it declares which. Readouts do not
   pretend to be destinations.
5. **The game initiates.** Something arrives every week. §6.0 found zero inbound events in the
   previous build.

---

## 2. Tokens

### 2.1 Colour

Semantic roles only. No view names a hue.

| Role | Use |
|---|---|
| `surface.page` / `surface.card` / `surface.raised` | Backgrounds by elevation |
| `content.primary` / `.secondary` / `.tertiary` | Text by weight |
| `accent` | The single interactive accent |
| `rating.{elite,good,average,poor,bad}` | The rating ladder |
| `state.{positive,negative,warning,info}` | Status, never raw `.green`/`.red` |
| `team.primary` / `.secondary` / `.onTeam` | Programme identity, generated per save |

**The values.** Added 2026-08-10 from the design pass (`docs/briefs/2026-08-10-claude-design-ui-brief.md`).
Every ratio below was computed from WCAG relative luminance and independently re-computed before
being written here — 24 ratios and three seams, all exact. They are not estimates.

| Role | Light | vs page / card / raised | Dark | vs page / card / raised |
|---|---|---|---|---|
| `surface.page` | `#F2F3F6` | — | `#0C0E13` | — |
| `surface.card` | `#FFFFFF` | — | `#161A22` | — |
| `surface.raised` | `#FAFBFD` | — | `#1F242E` | — |
| `content.primary` | `#14161C` | 16.30 / 18.08 / 17.47 | `#F4F6FA` | 17.84 / 16.11 / 14.38 |
| `content.secondary` | `#4A4F5C` | 7.38 / 8.19 / 7.91 | `#A8AFBE` | 8.77 / 7.92 / 7.07 |
| `content.tertiary` | `#767C8B` | 3.77 / 4.18 / 4.04 | `#7C8494` | 5.13 / 4.64 / **4.14** |
| `accent` | `#0B63C5` | 5.25 / 5.82 / 5.63 | `#63A8F5` | 7.77 / 7.01 / 6.26 |
| `state.positive` | `#0A6B3D` | 6.60 on card | `#4ED08A` | 8.89 on card |
| `state.negative` | `#B3261E` | 6.54 on card | `#FF8A80` | 7.63 on card |
| `state.warning` | `#8A5A00` | 5.93 on card | `#E0A93B` | 8.22 on card |
| `state.info` | `#0B5FA8` | 6.53 on card | `#6DB3F2` | 7.78 on card |

`rating.*` is a **single-hue lightness ladder**: `elite #0B2E5C`, `good #14538F`, `average #2E7BC4`,
`poor #7FA9D9`, `bad #C2D4E8`. L\* runs 19 / 35 / 50 / 68 / 84.

**Four rules the values forced, each of which changes a test rather than a value.**

1. **`rating.*` is a fill role and is not legal as a text colour.** The ladder was chosen against a
   hue ramp and a hue-plus-glyph ramp by rendering all three under deuteranopia, protanopia and
   tritanopia. Only lightness survives all three — the hue ramp collapses `average` and `poor` to
   ΔE 2 under deuteranopia, two of five steps becoming one. The cost is that `poor` measures 2.45:1
   and `bad` 1.51:1 as a foreground on card. So the ladder is legal as a `Meter` track, a `Chip`
   background or a `Sparkline` bar, and never as a tinted numeral. **`ContrastByConstructionTest`
   must enumerate `rating.*` against the surface it fills, not as a foreground pair.** This closes
   the brief's open question 4: five steps hold, and it does not drop to four.
2. **`content.tertiary` is not a body-text role.** In light it clears 3:1 but not 4.5:1 on any
   surface — large text and non-text indicators only. In dark it clears 4.5:1 on page and card and
   drops to 4.14 on `surface.raised`, so tertiary body text is **banned on raised in dark**. Exactly
   the composited-surface case §1.2 exists for.
3. **The hairline is a token, not a style.** Every surface seam measures ~1.11:1 (card/page 1.110
   light, 1.108 and 1.120 dark). A card edge cannot be carried by the fill step, so the hairline is
   load-bearing and must be enumerated like any other colour.
4. **Elevation has two definitions, so it cannot be one shadow value.** See §2.3.

**Team colours are generated per save** and must pass the trade-dress ΔE test and the contrast
contract *at generation time* — a generated pair that cannot carry legible text is rejected and
regenerated. This closes the prior build's whole class of "white on the team gradient" failures at
the source rather than at the call site.

**The contrast contract, stated precisely.** Amended 2026-08-10 by P2, which found the loose version
unsatisfiable. Requiring one `team.onTeam` to be legible against *both* members rules out every
dark-plus-light pair — which is most of the sport's real identities, navy and white among them. The
three roles carry two different obligations:

| Pair | Floor | Why |
|---|---|---|
| `team.onTeam` against `team.primary` | **4.5:1** | Text sits on the primary. WCAG AA for body text |
| `team.secondary` against `team.primary` | **3:1** | The secondary is a stroke, a chip, a chart series — a non-text element that must be distinguishable on the primary. WCAG AA for non-text contrast |

`team.secondary` is not a text background. A surface that needs text on the secondary uses
`content.primary` on a neutral surface instead; nothing in §4 or §5 asks for the other thing.

### 2.2 Type

Dynamic Type throughout, `@ScaledMetric` for any dimension that gutters text. No `.system(size:)`
anywhere — the prior build had ten, four below the 11 pt floor.

**Six roles onto six iOS text styles.** Added 2026-08-10 from the design pass.

| Role | Text style | Default → AX5 |
|---|---|---|
| `display` | `.largeTitle` | 34 → 60 pt |
| `title` | `.title2` | 22 → 56 pt |
| `headline` | `.headline` (semibold) | 17 → 53 pt |
| `body` | `.body` | 17 → 53 pt |
| `callout` | `.callout` | 16 → 51 pt |
| `caption` | `.caption1` | 12 → 43 pt |

`.caption2`, `.footnote` and `.subheadline` are **deliberately unmapped**. The smallest role is
therefore 12 pt, clear of the 11 pt floor, and nothing in the system can land on the floor by
accident — the prior build's four sub-floor sizes are unreachable by construction rather than by
review. At AX5 `body` and `headline` converge on 53 pt: weight separates them at the top of the
scale, not size, so a layout that relies on size alone to distinguish them breaks at AX5.

**The AX5 point sizes are UNVERIFIED** — cited from memory, the same status `01-RESEARCH.md` gives
the 44 pt touch-target floor. Confirm against the HIG type table before P11 depends on them.

### 2.3 Spacing, radius, elevation

An 8-point scale (`xs 4, s 8, m 16, l 24, xl 32, xxl 48`), three radii (`s 8, m 12, l 20`), three
elevations. Anything off-scale is a defect.

**Radius carries depth, not decoration** (2026-08-10): `s` for `Chip` and `Badge`, `m` for `Card` and
`Row`, `l` for the sheet and `CallInCard` only.

**Elevation is two different mechanisms, and the token cannot be a single shadow value.** In light it
is shadow-borne; in dark a shadow is invisible on a near-black page, so it is surface-borne.

| Step | Light | Dark | Used for |
|---|---|---|---|
| `elev.1` | y1 b2 / 6 % | `surface.card` + 9 % hairline | Card at rest on page |
| `elev.2` | y4 b12 / 10 % | `surface.raised` + 14 % | `CallInCard` over the field |
| `elev.3` | y12 b28 / 16 % | `raised` + 22 % + scrim | Confirmation sheet |

Three surfaces carry three elevations, so **dark has no fourth step available**. `elev.3` reuses
`raised` and separates itself with a dimming scrim over what it covers, not with a lighter fill. A
fourth elevation is not a value someone can add later; it needs a fourth surface first.

---

## 3. Components

`Card`, `Row`, `StatCell`, `Chip`, `Meter`, `Badge`, `SegmentedControl`, `PrimaryButton`,
`DestructiveButton`, `InboxItem`, `CallInCard`, `FieldCanvas`, `EmptyState`, `ErrorBanner`,
`OpposedBar`, `Sparkline`, `LowerThird`.

Each is registered in a **component registry** that the contract tests enumerate. A component not in
the registry cannot ship, which is what makes "by construction" true rather than aspirational.

The last three, and two clarifications, come from the reference read in `01-RESEARCH.md` §6.6 §3:

- **`OpposedBar`** — two values on one shared track, label at each end. The shape for
  us-versus-them numbers; a two-column table is not legible at this width.
- **`Sparkline`** — a small fixed-count bar or line run for recent form and short trends.
- **`LowerThird`** — the match view's event card: who, what, and one line of context, over the
  field. It is how a moment gets *named*; the field stays ambient (§5).
- **`Meter` has a defined over-capacity state.** A budget that is exceeded draws past its track in
  `state.negative` with the figure stated. A breach must be visible before it is read — this is the
  cap, scholarship and contact-budget surface.
- **Role and status tokens are `Chip` variants, not new components.** A short assignment code beside
  a mark on a field, and a status glyph in a roster row, are the same primitive.

**Four rules the 2026-08-10 design pass found missing.** Each is a *stated reduction* rather than a
fixed-height container, which is what §6's no-clipping clause actually requires — a component that
must shrink at AX5 instead declares what it drops.

- **`PrimaryButton` pins to the bottom of its pane; it does not scroll with content.** At AX5 the
  Game plan's commit action otherwise falls below the fold, and `SmallestDeviceLayoutTest`'s
  no-off-screen-controls clause fails on the most important control on the screen. This is a
  component rule, not a per-screen fix, because every DESTINATION has one.
- **`SegmentedControl` becomes a list above AX3.** Three labels at 53 pt do not fit the usable width.
  Growing two segments is legal; shrinking three is not.
- **`LowerThird` drops its context line at AX5** rather than shrinking. A three-line card at 53 pt
  would cover the marks it exists to describe.
- **`OpposedBar` colours the outlier, not the home side.** When neither value is an outlier both
  fills go neutral. Otherwise the component reads as a loyalty badge rather than a comparison.

**Destructive and irreversible actions** have a defined placement: never in the navigation bar's
leading slot, always confirmed, always labelled with what will happen. The prior build put "sim the
rest of the game and commit it" in the cancellation slot.

**One thing the component pass could not test, stated rather than left implicit.** All 32 pro
`TeamTable` pairs are dark-primary-with-light-secondary, so the light-primary case these components
are required to survive **does not occur in the data**. Both real pairs clear their floors
comfortably; that is not reassurance, it is the observation that the floors have never met the case
that would break them. Either the generator's reachable colour space is narrower than §2.1 assumes,
or the light-primary requirement is theoretical — and which one it is belongs to generation, not to
the design system. Raised against P2's `ColourGenerator`.

---

## 4. Screens

Grouped by tab. Each declares DESTINATION or READOUT.

| Tab | Screen | Class |
|---|---|---|
| **Week** | Inbox | DESTINATION — the week's inbound events |
| | Opponent report | READOUT |
| | Game plan | DESTINATION — the week's biggest decision |
| | Practice allocation | DESTINATION |
| | Match | DESTINATION during call-ins |
| | Aftermath | READOUT + occasional decision |
| **Team** | Roster / depth chart | DESTINATION |
| | Player card | DESTINATION (development, discipline, redshirt) |
| | Staff | DESTINATION (hire, fire, assign) |
| | Scheme | DESTINATION |
| **Recruit** (college) / **Front office** (pro) | Board, shortlist, contact budget / cap, contracts, draft | DESTINATION |
| **League** | Standings, schedule, rankings, news, realignment | READOUT |
| **Career** | Job security, stakeholders, record book, rivalries, career line | READOUT + the carousel is a DESTINATION |

Every DESTINATION must pass `02` §2.2's three tests — two defensible answers, a visible consequence,
a cost — or it is demoted to a READOUT and its decision automated.

**Every READOUT states its own verdict.** A readout that shows numbers and leaves the reader to form
the judgement is wallpaper, and wallpaper is what §6.0 found. Each one carries, above its data, a
one-line judgement and at most three sentences naming which figures are outliers and in which
direction — *the run defence is the weakness; you are giving up 5.1 a carry against a league 4.2*.
This is the strongest single pattern in the reference read (`01-RESEARCH.md` §6.6 §3.1): wherever a
mature competitor expects the player to form a judgement, it states the judgement first and lets the
chart be the evidence — eight times on its analytics page alone. The verdict is generated by the
engine, not authored per screen, so it cannot go stale.

**The chassis is two-pane, because landscape gives width and takes height.** Added 2026-08-10 with
the orientation decision. A single scrolling column shows roughly five to seven rows at default type
and fewer at AX5 — a roster of 85 or a recruiting board becomes a scroll marathon. The width is the
compensation: **a list rail on the leading side, detail on the trailing side**, both visible at once.
This is not decoration. It removes a navigation level — roster row to player card stops being a push
and becomes a selection — which is how the two-tap ceiling below survives. READOUTs that are
genuinely one object (career line, record book) may still be full-width.

**Corrected the same day, by drawing it.** Two claims in the paragraph above were wrong as first
written, and the design pass found both:

1. **A management screen keeps its status bar, so the budget is 347 pt, not 369.** That is 22 pt off
   every two-pane screen, and it is not slack: the Inbox rail is full at **four** items in 347 pt,
   and Roster shows **six** rows at 812, not seven. §5.2's field arithmetic is unaffected only
   because the match view hides the status bar — see there.
2. **The two-pane chassis does not hold at AX5.** It holds at 844 at default type. At AX5 two option
   cards cannot sit side by side, and the correct behaviour is that **the pane falls to a single
   scrolling column** — a stated reduction, not a squeeze. This is the chassis rule, not a per-screen
   workaround.

**Design at 812 first and let 844 have the surplus.** At the mini class the detail pane drops to
216 pt, and what it loses is not a row — it is the explanatory clause. "Suspension pending" survives;
"the AD is waiting on you" does not, and the glyph legend that fits at 844 does not fit at all. A row
is the cheap loss. The expensive one is the detail pane ceasing to be able to explain itself, which
is the entire reason the second pane exists.

**Landscape's three costs, named so they are designed for rather than discovered.**

1. **AX5 is the binding constraint, not the smallest device.** 369 pt of height at the largest
   accessibility type is where layouts break. `DynamicTypeContractTest` is now the test most likely
   to fail first, and every screen is drawn at AX5 before it is drawn at default.
2. **This is a two-handed app.** 844 pt of width puts both thumbs at the extremes and nothing at the
   centre. Primary and destructive actions live in the **bottom corners** of the trailing pane; the
   centre of the screen is for reading, not for reaching.
3. **The sensor housing eats one short edge.** Chrome respects `safeAreaInsets` on both leading and
   trailing edges, because the device can be rotated either way and the inset follows the housing.

**And landscape reintroduces size classes, which portrait had made a non-issue.** Every supported
iPhone is compact-width in portrait — one case. In landscape, Plus- and Max-class devices report
**regular** width while the standard and SE classes report **compact**. So the two-pane chassis
cannot be a `NavigationSplitView` left to its own defaults: that control collapses to a single stack
at compact width, which is most of the range, and the layout would then be correct only on the
largest phones. The two panes are laid out explicitly and both size classes are rendered in test.

**Navigation has a ceiling, and the ceiling is the point.** Five tabs; every destination reachable
in at most two taps from its tab root. If this game ever needs a search field over its own screens,
or a user-configurable shortcut manager, the architecture has failed rather than matured — both
appear in the reference set and both are symptoms (`01-RESEARCH.md` §6.6 §4.3). The screen list
above is a budget, not a starting point.

---

## 5. The match view — the hardest surface

### 5.1 The problem

22 marks on one phone screen. Human multiple-object tracking capacity is far below 22, so a literal
all-22 render is noise by construction, not by execution. That half of the problem is
orientation-independent, and the directed-attention rule below is what answers it.

Orientation decides only the other half: how much field is in frame, at what scale, and whether the
camera has to move during a play.

### 5.2 The resolution

**The app is landscape** — owner decision, 2026-08-10, recorded in `CLAUDE.md` and `docs/STATUS.md`.
The field is drawn along the screen's long axis: the line of scrimmage runs **vertically**, the
offence attacks **rightward**, and the **whole 120-yard field is in frame at all times**. There is no
pan during a play and no recentring between snaps, because there is nothing to recentre to.

**The arithmetic, which portrait could not satisfy.** A football field is 120 × 53.333 yd —
**2.250 : 1**. A landscape iPhone is **2.164 : 1**. The field is *slightly* more elongated than the
screen, so fitting its length to the long axis leaves room to spare on the short one:

| Device | Usable canvas after safe areas | Scale at full 120 yd | Field width | Spare height |
|---|---|---|---|---|
| Base iPhone (844 × 390) | 785 × 369 | **6.54 pt/yd** | 349 pt | 20 pt |
| Mini class (812 × 375) | 753 × 354 | **6.28 pt/yd** | 335 pt | **19 pt** |
| SE floor (667 × 375) | 667 × 375 | **5.56 pt/yd** | 296 pt | 79 pt |

DERIVED. **The two floors are different devices**, which is worth knowing before a layout is drawn:
the mini is the binding case for **spare height** at 19 pt, and the SE — no sensor housing, no home
indicator, so no insets to subtract — is the binding case for **scale** at 5.56 pt/yd. Both fit.

**And the match view therefore hides the status bar.** Established 2026-08-10 when the design pass
found that management screens keep theirs (§4). Recomputed with a 22 pt status bar visible, the
usable height falls to 347 pt and the field wants 349 — **it does not fit, by 2 pt, on the base
device, and by 3 pt on the mini**. The margins above are 20 pt and 19 pt, so the status bar is not a
rounding error, it is the whole clearance. The field is a full-bleed immersive surface and hiding the
bar is the ordinary treatment for one; the scoreboard already carries the game state the status bar
would compete with. Stated here because it is a *requirement of the arithmetic*, not a style choice,
and a P13 that leaves the bar visible will find the field clipped rather than merely tight.

The design pass reached the same conclusion by a different route — it subtracted 75 pt of width
rather than 59, which its own inset table does not account for, and arrived at 6.41 pt/yd. The
discrepancy is unresolved and is one more reason P13 measures rather than derives. **The conclusion
is robust across the whole candidate range**: at 59 pt of inset on one edge (6.54 pt/yd), at the
design pass's 75 (6.41), and at 59 on both edges (6.05), the whole field fits with the status bar
hidden. What changes is mark size, not whether the approach works.

Device point sizes are ASSUMPTION, carried from `01-RESEARCH.md` §6.1 and still unmeasured; the
landscape safe-area figures (≈59 pt on the sensor-housing edge, ≈21 pt on the home-indicator edge)
are ASSUMPTION on the same footing. P13 replaces both with a measurement.

Against portrait's 7.31 pt/yd over **68 of 120 yards** with recentring between snaps, the trade is
explicit: **about 11 % smaller marks in exchange for the entire field, permanently, with no camera
motion.** Whole-field-always-visible was rejected in portrait on arithmetic — it wanted 877 pt of
height on an 844 pt screen (`01-RESEARCH.md` §6.5, option A). Rotating the device is what makes it
fit, and `01-RESEARCH.md` §6.5 dismissed landscape in one line without ever computing it.

**What this does not buy.** At 6.54 pt/yd adjacent linemen sit ~7.5 pt apart, ~6.4 pt on the SE,
against portrait's ~8.4 pt. Same order of magnitude, so `01-RESEARCH.md` §6.3's conclusion stands
unaltered: **individually numbered marks on the two lines remain geometrically impossible**, the
seven-man line is drawn as one shape rather than seven marks, and nothing inside the match `Canvas`
is individually tappable. Orientation bought field coverage. It bought nothing on local clustering.

**Chrome overlays the field; it does not take a slice of it.** The numbers above assume the canvas
gets the whole usable rectangle. A side rail that reserved 120 pt would drop the SE to 4.56 pt/yd,
below the legibility floor §6.5 uses to reject option A — so the scoreboard, the remaining-key-moments
indicator and the call-in are drawn **over** the field, in its dead margins, not beside it.

**Precedent, at its true strength.** FM Mobile is landscape throughout: the match pitch by direct
observation of two owner-supplied captures (`01-RESEARCH.md` §6.6 §2, AS-6.5-07), the management
screens by owner report — testimony, not capture, and marked as such. Real, but a *soccer* precedent
for a sport with the opposite field ratio. The load-bearing argument is the table, not the reference.

**The residual, not glossed.** FM's own community reports that the **vertical** pitch — attacking
up-screen — is the more legible orientation for reading team shape, lines and gaps
(`01-RESEARCH.md` §2.1), and FM26 ships a camera called *Vertical Scrolling*. Our field now runs the
other way. Whether "better for structure" survives transfer to a sport whose structure is a line of
scrimmage rather than a defensive block is settled by nothing in this document. It is the question
P13's owner walkthrough exists to ask.

**Half of that question came back answered on 2026-08-10, and the other half got sharper.** Drawn at
6.41 pt/yd, the hash marks and yard lines read, and the line of scrimmage reads as a line — because
it is the only unbroken vertical rule on the surface, which is a property worth protecting rather
than a coincidence. **What does not read is direction.** Nothing in a still frame says the offence
attacks rightward except the ball spot. So the remaining-key-moments indicator in the header is
carrying drive direction as well, which makes it load-bearing rather than ambient, and P13's
walkthrough should ask about direction specifically rather than about the field in general.

**Attention is directed, not divided.** At any moment the view foregrounds at most **three** marks:
the ball carrier or passer, the primary matchup the play turns on, and the defender who will decide
it. Everything else is drawn at reduced contrast and reduced size. This is the difference between an
all-22 diagram and a legible one.

**The field stays ambient; the moment is named.** The field is not asked to carry the story on its
own. A snap that matters resolves into a `LowerThird` — who, what happened, one line of context —
and that card, not the marks, is what the player reads. The reference read found the same division
of labour in a shipping mobile match view (`01-RESEARCH.md` §6.6 §3.3), arrived at from the opposite
direction: it leaves all 22 undifferentiated and lets the card do everything. Ours narrows the field
*and* names the moment.

**The player can see how much is left.** The match header carries one mark per remaining key moment,
filling as the game runs. Without it, drive-granularity default reads as an indefinite wait rather
than a known-length sequence — and D1's 10.5-minute budget is only reassuring if the player can feel
it (`01-RESEARCH.md` §6.6 §3.4).

**The play resolves before it animates.** The engine produces the outcome; the choreographer builds
motion whose last frame is pinned to the recorded result (`03` §1.3). The view cannot change what
happened, and a test asserts it.

**Drive granularity by default.** Between call-ins the view summarises at drive level. Full snap
animation is reserved for call-in snaps, scoring plays, turnovers and explosives — which is what
makes D1's 10.5-minute match budget hold.

### 5.3 What the player reads

A snap must be legible as *what it was*: a completion, a sack, a run stuffed at the line. The minimum
vocabulary is the matchup that decided it — which is available because D2 chose a model that knows.
A sack is drawn as the protection duel that lost, not as a generic collapse.

### 5.4 Accessibility of the match view

- **Reduce Motion:** the view becomes a discrete state sequence — formation, key moment, outcome —
  with no interpolated motion. It is not disabled; a player who needs Reduce Motion still gets the
  match.
- **VoiceOver:** each snap emits one composed sentence built from the same matchup resolution the
  animation draws from, so audio and picture cannot diverge.
- **Contrast:** every mark, trail and annotation is measured against the field surface in both
  appearances.

---

## 6. The accessibility contract (D12)

Binding, tested, and enumerated by construction.

| Clause | Requirement | Test |
|---|---|---|
| Contrast | ≥4.5:1 body, ≥3:1 large text and non-text indicators, measured on the composited surface, both appearances. **Fill roles are enumerated against the surface they fill, not as a foreground pair** — `rating.*` is a fill role (§2.1) and scoring it as text would fail it wrongly; the hairline is a colour token and is enumerated | `ContrastByConstructionTest` |
| Coverage | The contrast suite's surface count equals the count of surfaces consuming a colour token | meta-assertion inside the same test |
| Orientation | The app declares landscape and only landscape, in `App/project.yml`; no view opts out | `OrientationPolicyTest` reads the project manifest |
| Dynamic Type | Every screen legible at AX5 **in 369 pt of height**, no clipping, no fixed-size text container | `DynamicTypeContractTest` |
| Reduce Motion | Every animation has a defined reduced form | `ReduceMotionContractTest` |
| VoiceOver | Every data row is one sentence; every control has a label and a hint where non-obvious | `VoiceOverLabelTest` |
| Touch targets | 44 × 44 pt minimum | `TouchTargetTest` |
| Smallest device | Every screen usable at the smallest supported size, no off-screen controls | `SmallestDeviceLayoutTest` |
| Errors | Every error path terminates in a presented surface | `ErrorSurfaceTest` |
| Reachability | Every view is reachable from the app entry point | `ReachabilityTest` |

**Unverified premises, flagged rather than buried.** Three inputs to this contract could not be
checked — `developer.apple.com` returned no readable body through the proxy: the 44 pt touch-target
floor, Apple's exact Reduce Motion semantics, and the SwiftUI API surface for suppressing
`TimelineView` updates. All three are cited from memory and marked UNVERIFIED in `01-RESEARCH.md`.
**Confirm against the HIG before implementing.** Building an accessibility contract on unverified
guidance would reproduce precisely the failure pattern 1 names.

---

## 7. Copy

Short, plain, specific. No lorem ipsum, no emoji. A refusal names the door that shut ("roster full",
"$1.2M over the cap"), never just "cannot do that". Stakeholder voices are distinct enough to be
recognised without a name attached.
