# Brief — Claude Design for the UI

> **SUPERSEDED 2026-08-10 by the work it commissioned.** This brief asked for three card groups
> and got them; adversarial review then took the library to **sixteen** `*-v2.dc.html` sheets,
> indexed in `docs/04-UX-AND-DESIGN-SYSTEM.md`. Retained as the record of what was asked for and
> why — its §6 acceptance checks and §3 legal guardrail still describe the standard the library
> is held to. Its device figures and screen counts are stale; `04` carries the current ones.

Written 2026-08-10. **Not canon.** `docs/DOC-MANIFEST.md` §4 lists the paths that carry authority and
this is not one of them. It is a working input handed to a tool. Where it disagrees with
`docs/04-UX-AND-DESIGN-SYSTEM.md`, `04` wins and this file is the defect.

---

## 1. What is being asked for

Produce a **visual design system for Pro Football Coach as rendered preview cards** in a claude.ai
Claude Design project, driven by the `DesignSync` tool: token sheets, one card per component in the
`04` §3 registry, and five key screens.

The output is a **reference**, not shipping code. It exists so that P11 (design system and the
accessibility contract) and P12–P14 (the feature surfaces) implement against something that has been
seen and judged, rather than against prose. The prior build scored 9/20 on `04b` with accessibility
at 1/4; the point of doing this before P11 is that a wrong visual answer is cheap to find in a
preview card and expensive to find in twenty SwiftUI views.

## 2. What it must not do

| Not this | Because |
|---|---|
| Emit SwiftUI, or anything meant to be pasted into `Sources/` | The engine/UI boundary and the token-literal build gate are owned by `03b` and P11. HTML previews are a rendering, not a port. |
| Become a second home for the design system | `DESIGN.md` was archived precisely for being a parallel one (`DOC-MANIFEST.md` §2). The design system has exactly one home: `docs/04-UX-AND-DESIGN-SYSTEM.md`. |
| Invent a token and use it | Any value this work produces — a hex, a scale step, a new elevation — is written into `04` §2 **first**, then used. Doc-first amendment rule, `CLAUDE.md`. |
| Add a component | The `04` §3 registry is the whole list. A component not in the registry cannot ship. The registry holds seventeen; if a screen seems to need an eighteenth, that is a finding to report, not a card to draw. |
| Add a screen | The `04` §4 table is a budget, not a starting point. |
| Draw any real-world identity | Absolute. See §3. |

## 3. Legal guardrail — absolute, applies to mockups

Every school, team, conference, city, stadium, player and coach shown in any card is **fictional and
original**. No real school or franchise name, no real logo, no real colour pair, no real player name,
not even as throwaway filler in a roster row. Placeholder content is the single most common route
back into this failure: the deleted `NameBank.swift` declared its list "Fictional alma maters" and
contained real NCAA institutions.

Fictional sample identities for cards are drawn from the P2 generator
(`Sources/FootballSimCore/Generation/LeagueGenerator.swift`,
`Sources/FootballSimCore/Generation/ColourGenerator.swift`), not invented by hand. If the generator
cannot be run in the session, invent obviously-synthetic names and say in the card that they are
placeholders pending generator output.

No emoji anywhere — code, copy, cards or commits.

## 4. The frame

- **iPhone only, landscape only.** Owner decision 2026-08-10 — `04` §5.2. Cards render at
  **844 × 390** — the design floor since the owner dropped the SE and mini classes on 2026-08-10
  (`04` §4.1) — and again at the **932 × 430** ceiling. The supported range is now 6.54–7.28 pt/yd,
  an 11 % spread, with spare height flat at ~20 pt. Safe areas are not decorative: ≈59 pt on the
  sensor-housing short edge, ≈21 pt on the home-indicator edge, and the device rotates both ways so
  either short edge can be the housing one. Do **not** design for 667 × 375; it is unsupported but
  still installable, so it needs only the weaker assertion — reachable, not beautiful.
- **Two size classes, not one.** This is the trap. Portrait made every iPhone compact-width;
  landscape splits the range — Plus/Max report **regular** width, the standard and Pro classes report **compact**. The split runs through the middle of the *supported* set, so narrowing the device range did not remove it. A
  layout that only holds together on a Max is a P1. Render both.
- **The chassis is two-pane** (`04` §4): list rail leading, detail trailing, both visible at once.
  Height is the scarce axis now — ~369 pt usable — so a single scrolling column shows five to seven
  rows and is the wrong default.
- **Both appearances.** Light and dark are not a variant, they are two required renders. Contrast is
  measured against the surface a thing is *actually composited on*, in both.
- **Dynamic Type.** Every screen card also renders at **AX5**. No clipping, no fixed-height text
  container. In 369 pt of height this is now the check most likely to invalidate an otherwise good
  layout — do it first, not last.
- **Touch targets ≥ 44 × 44 pt.** Cited from memory and marked UNVERIFIED in `01-RESEARCH.md` —
  confirm against the HIG before treating the number as settled.
- **Zero third-party anything.** The previews are self-contained HTML/CSS. No CDN, no icon font, no
  web font. Type is SF (system stack); if a card needs a glyph, it is an SF Symbol name written as
  text, not an image.

## 5. Deliverables

### 5.1 Token sheets (group: `Tokens`)

`04` §2 names the roles and gives **no values**. Producing the values is the substantive part of this
work.

- **Colour.** Every semantic role in `04` §2.1 — `surface.{page,card,raised}`,
  `content.{primary,secondary,tertiary}`, `accent`, `rating.{elite,good,average,poor,bad}`,
  `state.{positive,negative,warning,info}` — as a light value and a dark value, each with its
  measured contrast ratio against the surfaces it is used on, printed on the card. No view ever names
  a hue, so the card is where a hue is allowed to appear.
  - `rating.*` is a five-step ladder that must stay ordered and distinguishable **for the three
    common colour-vision deficiencies**, not only at full trichromacy. A ladder that collapses to two
    steps under deuteranopia is a P1.
  - `state.*` must never be the *only* channel carrying the meaning.
- **Type.** `display`, `title`, `headline`, `body`, `callout`, `caption` mapped to the iOS text
  styles, shown at default and at AX5. No `.system(size:)` equivalent, no size below 11 pt.
- **Spacing, radius, elevation.** The 8-point scale (`xs 4, s 8, m 16, l 24, xl 32, xxl 48`), three
  radii (`s 8, m 12, l 20`), three elevations. Show them, do not just list them.

### 5.2 Component cards (group: `Components`)

One card per registry entry, named **exactly** as `04` §3 names it, so the mapping to the Swift
component registry is 1:1 and mechanical:

`Card`, `Row`, `StatCell`, `Chip`, `Meter`, `Badge`, `SegmentedControl`, `PrimaryButton`,
`DestructiveButton`, `InboxItem`, `CallInCard`, `FieldCanvas`, `EmptyState`, `ErrorBanner`,
`OpposedBar`, `Sparkline`, `LowerThird`.

Each card shows the component's **states**, not one happy instance: default, pressed/selected,
disabled, loading if it can, empty if it can, and error if it can. Specifically:

- **`Meter`** must show its **over-capacity state** — drawn past the track in `state.negative` with
  the figure stated. This is the cap / scholarship / contact-budget surface and a breach must be
  visible before it is read.
- **`Chip`** carries the role codes and status glyphs. They are `Chip` variants, not new components.
- **`DestructiveButton`** shows the confirmation, and the card states the placement rule: never in
  the navigation bar's leading slot, always labelled with what will happen.
- **`OpposedBar`**, **`Sparkline`**, **`LowerThird`** are the three newest and least specified. They
  get the most attention.

**Team colours are generated per save**, so every component that touches `team.primary` /
`team.secondary` / `team.onTeam` is rendered against **three** generated pairs spanning the range:
dark-primary, light-primary, and a low-chroma pair. The floors are `onTeam`-on-`primary` **4.5:1**
and `secondary`-on-`primary` **3:1** (`04` §2.1, amended 2026-08-10). A design that only looks right
on navy is broken, because the player will not have navy.

### 5.3 Screen cards (group: `Screens`)

Five, in this order. Each declares DESTINATION or READOUT at the top of the card, per `04` §4.

1. **Inbox** (DESTINATION) — the week's inbound events. The week opens on **commitments with a
   cost**: what each item will take, not only what happened.
2. **Opponent report** (READOUT) — the first surface to carry a generated **verdict**. The card must
   show the verdict pattern working: a one-line judgement above the data, then at most three
   sentences naming which figures are outliers and in which direction. The chart is the evidence, not
   the argument. A readout without a verdict is wallpaper.
3. **Game plan** (DESTINATION) — the week's biggest decision. Must visibly pass `02` §2.2: two
   defensible answers, a visible consequence, a cost.
4. **Roster / depth chart** (DESTINATION) — the density test. At most **three** status glyphs per
   row, each one that changes a decision.
5. **Match view** (see §5.4).

### 5.4 The match view — the hardest surface, and the one to be honest about

`04` §5.2 resolves it: **landscape field with all 120 yards in frame**, line of scrimmage running
vertically, offence attacking rightward, **no camera pan and no recentring**; **at most three
foregrounded marks** with everything else at reduced contrast and size; the field stays ambient and
the moment is named by a `LowerThird`; one mark per remaining key moment.

**Chrome overlays the field — it does not take a slice of it.** The field gets the whole usable
rectangle (6.54 pt/yd base, 5.56 pt/yd SE). A 120 pt side rail would drop the SE to 4.56 pt/yd, below
the legibility floor, so the scoreboard, the remaining-moments indicator and the call-in are drawn
over the field's dead margins.

Note what landscape did **not** fix: adjacent linemen are ~7.5 pt apart (~6.4 pt on SE), so
individually numbered marks on the two lines remain impossible and the seven-man line is one shape,
not seven marks.

Previews are static, which suits this: render the match view as the **three-state discrete sequence**
— formation, key moment, outcome. That is also exactly the Reduce Motion form the contract requires,
so drawing it satisfies two obligations at once. Add one card for the **call-in**: a named proposal
with one-tap accept and an explicit dismiss.

**Flag it, do not settle it.** FM's community reports the *vertical* pitch reads better for shape,
lines and gaps, and our field now runs the other way (`01-RESEARCH.md` §2.1 and §6.5's correction).
Whether the field reads as a football field, and the line of scrimmage as a line, is the one
presentation question no test can answer; it belongs in the P13 owner walkthrough. The brief's job is
to make the question askable by rendering it, not to declare it answered.

## 6. Acceptance

The work is done when, for every card produced:

- Light and dark both render, and every foreground/background pair has its measured ratio printed:
  **≥4.5:1** body text, **≥3:1** large text and non-text indicators, measured on the composited
  surface.
- Every screen card also renders at AX5 with no clipping.
- Every interactive element is ≥44 × 44 pt.
- Every READOUT card carries a verdict line.
- Every animation implied by a card names its reduced form.
- Every data row is expressible as one VoiceOver sentence, and the card states that sentence.
- No token value appears that is not also written into `04` §2.
- No real-world identity appears anywhere.

These mirror the D12 contract in `04` §6 deliberately. A card that cannot meet them is telling you
the design fails a gate that P11 will enforce mechanically, and it is cheaper to learn it here.

## 7. Running it

1. `DesignSync` `list_projects`; create one named `Pro Football Coach` if none exists.
2. Build the card bundle locally under a scratch directory. Each preview HTML's **first line** is
   `<!-- @dsCard group="Tokens|Components|Screens" -->` — the Design System pane builds its index
   from that marker, so explicit `register_assets` is not needed.
3. `finalize_plan` with the write paths and the local directory, then `write_files`.
4. Review in the Design System pane, iterate on the cards that fail §6.
5. Write the accepted token values and any component clarification into
   `docs/04-UX-AND-DESIGN-SYSTEM.md` **before** P11 starts. That write, not the project, is what the
   build consumes.

The claude.ai design project is authenticated through the user's claude.ai login. A non-interactive
session cannot run that authorization; if `list_projects` fails on auth, stop and hand it back rather
than working around it.

## 8. Open questions this work should return, not resolve

1. Does the landscape field read as a football field, and the line of scrimmage as a line, at
   6.54 pt/yd? → P13 owner walkthrough.
2. Does the two-pane chassis hold at compact width (standard iPhone, SE), or only at regular width
   (Plus, Max)? If only the latter, `04` §4 needs a second answer for the compact case.
3. Do the 44 pt floor and the Reduce Motion semantics survive a check against the current HIG? Three
   accessibility premises in `04` §6 are UNVERIFIED, as are every device point size and safe-area
   inset in `04` §5.2.
4. Does the `rating.*` ladder hold five distinguishable steps under CVD simulation, or does it need
   to be four?
5. Does any screen in the `04` §4 budget fail its DESTINATION test once drawn, and therefore get
   demoted to a READOUT with its decision automated?
