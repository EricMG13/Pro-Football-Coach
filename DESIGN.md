---
name: Pro Football Coach
description: The record book a franchise writes about itself, updated live.
colors:
  page-paper: "#F2EFE8"
  page-night: "#000000"
  card-paper: "#FBF8F2"
  card-night: "#1C1C1E"
  ink-paper: "#1A1714"
  ink-night: "#F5F2EC"
  muted-paper: "#5B5347"
  muted-night: "#A9A296"
  rule-paper: "#D9D3C7"
  rule-night: "#3A3A3C"
  rating-elite-paper: "#6B4BC4"
  rating-elite-night: "#C3A6FF"
  rating-star-paper: "#155CB0"
  rating-star-night: "#6BB3FF"
  rating-starter-paper: "#22661F"
  rating-starter-night: "#67D77A"
  rating-rotational-paper: "#8A5000"
  rating-rotational-night: "#F5A93C"
  rating-fringe-paper: "#AB2A1E"
  rating-fringe-night: "#FF8A80"
typography:
  display:
    fontFamily: "New York (system serif)"
    fontSize: "largeTitle, Dynamic Type"
    fontWeight: 700
  title:
    fontFamily: "New York (system serif)"
    fontSize: "title2, Dynamic Type"
    fontWeight: 600
  body:
    fontFamily: "New York (system serif)"
    fontSize: "body, Dynamic Type"
    fontWeight: 400
  label:
    fontFamily: "SF Pro"
    fontSize: "caption, Dynamic Type"
    fontWeight: 600
    letterSpacing: "0.6"
  figure:
    fontFamily: "SF Pro"
    fontSize: "title3, Dynamic Type"
    fontFeature: "tabular numerals"
rounded:
  stamp: "3px"
  card: "20px"
spacing:
  tight: "6px"
  small: "10px"
  medium: "16px"
  large: "24px"
  row: "52px"
components:
  stamp:
    textColor: "{colors.ink-paper}"
    typography: "{typography.label}"
    rounded: "{rounded.stamp}"
    padding: "3px 6px"
  ledger-row:
    textColor: "{colors.ink-paper}"
    typography: "{typography.body}"
    padding: "6px 0"
  card:
    backgroundColor: "{colors.card-paper}"
    rounded: "{rounded.card}"
    padding: "16px"
---

# Design System: Pro Football Coach

## Overview

**Creative North Star: "The Franchise Almanac"**

The app is the record book a franchise writes about itself, updated live. Every screen is a page
of it: the week is a front page, the cap sheet is a ledger, a player is a dossier entry, a season
is a chapter, a championship is a commemorative edition. The voice was always plainspoken and
numeric; now the typography, the paper, the rules and the numerals say the same thing the copy
does.

This is modernist print, not nostalgia. There is no paper grain, no sepia, no faux binding, no
texture overlay, no skeuomorphic anything. Type, rules, numerals, ink and team colour do all the
work, on flat surfaces with zero shadows and zero image assets — which is also exactly what the
platform and the no-assets constraint want.

It runs in two registers. The **chassis** is the whole franchise: paper ground, printed rules,
serif record voice, tabular figures, colour only where it carries meaning. The **edition** is the
loud register, reserved for seven earned moments and used nowhere else.

**Key characteristics:**
- Two registers, with a closed list of which surfaces get the loud one
- Rules, not a card wrapped around everything
- Flat by construction — no shadows anywhere in the system
- Team colour as accent only; grounds stay paper or night
- Every colour-coded value readable without colour
- Tokens in `Almanac.swift` and `DesignSystem.swift`; a literal in a view is a defect

## Colors

A paper chassis carrying two colour families that both mean something: the franchise's identity,
and a player's quality.

### Primary
- **Team Tint** (per-franchise, e.g. Empire Harbor Navy `#14294B`): the coached team's colour,
  injected through the environment so every screen re-themes when a coach changes jobs. Drives
  tint, primary actions, edition plates. In the night edition the raw hex is lifted toward white
  until it clears 4.5:1 against the wash a bordered control paints behind its own label — a navy
  or maroon franchise would otherwise render its own buttons dark-on-dark.

### Secondary — the rating ladder
Five bands, each a paper/night pair, purpose-picked rather than taken from the system set:
`.green` and `.orange` as text on a white card measure 2.2:1, and four of five system bands failed
AA before this ladder replaced them.

- **Violet — Elite** (90+, `#6B4BC4` / `#C3A6FF`)
- **Cobalt — Star** (84–89, `#155CB0` / `#6BB3FF`)
- **Field Green — Starter** (74–83, `#22661F` / `#67D77A`)
- **Amber — Rotational** (64–73, `#8A5000` / `#F5A93C`)
- **Brick — Fringe** (<64, `#AB2A1E` / `#FF8A80`)

### Neutral
- **Page** (`#F2EFE8` paper / `#000000` night): the canvas behind every scroll.
- **Card** (`#FBF8F2` paper / `#1C1C1E` night): a grouping, not a default wrapper.
- **Ink** (`#1A1714` / `#F5F2EC`): warm near-black, warm off-white. Never pure — pure reads as a
  different material.
- **Muted ink** (`#5B5347` / `#A9A296`): supporting copy. Replaces the habit of using `.tertiary`
  as real informational text, which measured 2.11:1.
- **Rule** (`#D9D3C7` / `#3A3A3C`): the printed hairline.

### Named Rules

**The Accents-Only Rule.** Team colour touches tint, primary actions and edition plates. It never
becomes a body surface. With 32 arbitrary fictional colour pairs, immersive theming guarantees
contrast failures; accents keep every screen legible in both editions with no per-team correction.

**The Measured-Surface Rule.** A colour is verified against the surface it is actually drawn on —
the card, the page, and the composited tint — not against an idealised white. The first version of
the team-tint check measured against a background the app never draws, and all thirty-two teams
passed in the test while failing on the phone.

**The Never-Colour-Alone Rule.** No state is carried by hue alone. The rating bands come out near
isoluminant, because clearing 4.5:1 on paper forces all five dark and compresses the available
lightness — so hue does the visual work while the adjacent number and a spoken tier word carry the
meaning for everyone else.

## Typography

**Display / record voice:** New York (system serif)
**Chrome:** SF Pro
**Figures:** SF Pro with tabular numerals

**Character:** The record speaks in serif; the machinery around it speaks in SF. Nothing is
bundled — New York is a system face, so it costs no assets and scales with Dynamic Type for free.
Almost no app in this category uses it, which makes it distinctive by neglect rather than by
expense.

### Hierarchy
- **Display** (`almanacDisplay`, serif bold, largeTitle): mastheads, edition plates, a lone
  dominant figure.
- **Title** (`almanacTitle`, serif semibold, title2): player names, record lines, chapter heads.
- **Body** (`almanacBody`, serif, body): running record prose, news, dossier lines.
- **Label** (`almanacLabel`, SF semibold, caption, tracked): table heads, section chrome, stamps.
- **Figure** (`almanacFigure`, SF tabular, title3): any number that changes.

### Named Rules

**The Tabular Figures Rule.** Any figure that changes between rows or ticks uses tabular numerals.
Digits that shift width while a game clock runs read as instability.

**The Dynamic Type Rule.** Text styles only — no hard-coded point sizes, anywhere. Every screen
survives XXXL without truncation or overlap.

## Layout

A single-column vertical scroll inside the safe area, structured by rules rather than by stacking
cards. One concept per page section; depth lives behind a tap — sheet for a self-contained
sub-task, push for the live game and the archive — never in density.

Spacing is a four-step scale: `tight` 6, `small` 10, `medium` 16, `large` 24. Rows target 52pt,
comfortably above the 44pt touch minimum. Navigation is a five-tab bar whose first tab re-labels
itself Season or Offseason with the calendar phase; tabs are sections, never actions.

iPhone only, portrait only. The one exception is the on-field arcade screen, which opts into
landscape for itself.

## Elevation & Depth

**Flat by construction. The system has no shadows at all** — not on cards, not on stamps, not on
bars.

Depth is tonal and typographic. By day the page is paper and cards sit a shade lighter; at night
the page is true black and cards lift to `#1C1C1E`. The same ordinal relationship survives both
editions without a single shadow, and it costs nothing on scroll performance.

### Named Rules

**The Flat-Forever Rule.** Adding a shadow to make something stand out is the wrong fix. If an
element needs emphasis it needs a rule, a change of voice, a figure, or a different place in the
hierarchy.

## Shapes

Rules first, then two radii. Cards use `20` with `.continuous` — Apple's superellipse, not a
circular arc; the difference is visible at this size. Stamps use `3`, squared rather than pill,
because the capsule chip is the reference app's signature and this system is not that.

Borders are near-absent: separation comes from the printed rule and from surface tone.

## Components

- **Rule** (`Rule(.hair)` / `Rule(.heavy)`): the primary separator. Hairline for rows, heavy for
  section breaks and mastheads.
- **Stamp**: one piece of metadata, outlined rather than filled. The filled chip was the audit's
  worst contrast offender — hard-coded white measuring as low as 1.41:1 — so the successor keeps
  its label at full ink on its own ground and cannot fail.
- **LedgerRow**: label left, figure right, baselines aligned so a column of them reads as a column.
- **Card**: a genuine grouping, not the default wrapper. `medium` padding, `20` continuous radius,
  no border, no shadow.
- **Rating value** (`.ratingStyle(_:)`): tier colour plus the tier word as an accessibility value,
  so the visible text — which may be a scouted range or a one-decimal average — is read first.
- **Editions** (the loud register, this list and no other): weekly front page in its gameday state ·
  live game · final whistle · draft on-the-clock · season review · championship and commemorative
  moments · the firing.

Controls are stock SwiftUI. Switch, segmented control, stepper, picker, action sheet, alert,
context menu, swipe actions — reinventing these is the most common form of native slop.

### Named Rules

**The Earned-Edition Rule.** A screen does not get the loud register because it feels important. It
gets it by being on the list above, deliberately. The team-overview band and the preseason hero
both lost it.

## Do's and Don'ts

**Do**
- Reference tokens — `Almanac.ink`, `Layout.medium`, `RatingTier`, `.almanacFigure`.
- State the number and its consequence together. Show the cap hit *and* the dead money.
- Verify a new colour against the card, the page, and its own composited tint, in both editions,
  before shipping it.
- Give every stat row a VoiceOver reading that is a sentence, not loose numbers.
- Reach for `.motionAware(_:value:)` rather than `.animation` — Reduce Motion is a commitment, and
  a token cannot be forgotten the way a habit can.

**Don't**
- Don't put a literal spacing value, radius, hex or point size in a view.
- Don't let team colour become a body surface.
- Don't add a shadow.
- Don't fill a stamp with a colour and put white on it.
- Don't use a second letter scale near ratings — Potential already owns A+…F, which is why the
  rating tiers are words.
- Don't wrap something in a card when a rule would separate it.

## Anti-references

- **The college reference app.** Clean-room: no copied layouts, colours, icons or strings. Its
  signature formula — white cards for everything, capsule chips on every metadata token, the
  betting-pill week card, colour-tiered OVR numerals — is now an explicit anti-pattern here. The
  critique catalogued 57 places the old skin reproduced it; the Almanac exists to answer them.
- **The Coordinator's Clipboard.** The retired first world of this project. Not wrong, just
  generic — a native-restraint chassis with no identity of its own. Superseded 2026-08-09.
- **Madden / EA glossy chrome.** No faux-3D bevels, metallic gradients, or skewed italics.
- **The spreadsheet.** No dense multi-column table as a default view.
- **The generic AI dashboard.** No purple-gradient SaaS look, no default component-library grid,
  no emoji standing in for icons.

## Known drift

Tracked against `docs/AUDIT.md`; each is owned by a redesign phase in
`docs/plans/2026-08-09-almanac-redesign.md` rather than patched on the old skin.

- Two `Chip` call sites still take a rating colour directly and carry no spoken tier.
- The player card's overall is a hard-coded 44pt, which breaks the Dynamic Type Rule.
- Roughly 70 literal spacings, radii and font sizes remain in views built before the token layer.
- Contrast failures inherited from the old skin's filled chips, gradient hero text and raw system
  colours are superseded rather than fixed: those components cease to exist as their surfaces are
  rebuilt.
- Sheets do not inherit the root's `preferredColorScheme`. `SettingsView` sets it itself; the
  other sheets (wizard, load, scenarios, player card, negotiation) still follow the system
  appearance rather than the chosen one.
