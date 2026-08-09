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

**Team colours are generated per save** and must pass the trade-dress ΔE test and the contrast
contract *at generation time* — a generated pair that cannot carry legible text is rejected and
regenerated. This closes the prior build's whole class of "white on the team gradient" failures at
the source rather than at the call site.

### 2.2 Type

Dynamic Type throughout, `@ScaledMetric` for any dimension that gutters text. Roles: `display`,
`title`, `headline`, `body`, `callout`, `caption`. No `.system(size:)` anywhere — the prior build had
ten, four below the 11 pt floor.

### 2.3 Spacing, radius, elevation

An 8-point scale (`xs 4, s 8, m 16, l 24, xl 32, xxl 48`), three radii (`s 8, m 12, l 20`), three
elevations. Anything off-scale is a defect.

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

**Destructive and irreversible actions** have a defined placement: never in the navigation bar's
leading slot, always confirmed, always labelled with what will happen. The prior build put "sim the
rest of the game and commit it" in the cancellation slot.

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

**Navigation has a ceiling, and the ceiling is the point.** Five tabs; every destination reachable
in at most two taps from its tab root. If this game ever needs a search field over its own screens,
or a user-configurable shortcut manager, the architecture has failed rather than matured — both
appear in the reference set and both are symptoms (`01-RESEARCH.md` §6.6 §4.3). The screen list
above is a budget, not a starting point.

---

## 5. The match view — the hardest surface

### 5.1 The problem

22 marks on a ~390 pt-wide portrait screen. A football field is 53.3 × 120 yards — a landscape ratio
being shown on a portrait device. And human multiple-object tracking capacity is far below 22, so a
literal all-22 render is noise by construction, not by execution.

### 5.2 The resolution

**The field is drawn vertically** — the line of scrimmage runs across the screen, the offence attacks
upward. The camera holds the line of scrimmage plus about 25 yards downfield, which is where the play
is decided, and pans only when the carrier breaks it.

This decision rests on **field geometry alone, with no shipping precedent behind it**. It was once
supported by an assumed portrait pitch in FM Mobile; direct observation settled that the other way —
FM Mobile is landscape and rotates the device (`01-RESEARCH.md` §6.6 §2, AS-6.5-07). The geometry is
still decisive and points the opposite way from soccer's: a gridiron is about 1 : 2.25 where a pitch
is about 1 : 1.55, so the shape that wants landscape there wants portrait here. But the argument is
now unaccompanied, which raises what P13 owes the owner walkthrough.

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
| Contrast | ≥4.5:1 body, ≥3:1 large text and non-text indicators, measured on the composited surface, both appearances | `ContrastByConstructionTest` |
| Coverage | The contrast suite's surface count equals the count of surfaces consuming a colour token | meta-assertion inside the same test |
| Dynamic Type | Every screen legible at AX5, no clipping, no fixed-size text container | `DynamicTypeContractTest` |
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
