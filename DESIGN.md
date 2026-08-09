---
name: Pro Football Coach
description: A modern sports app — team colour on the band, chips for everything else.
colors:
  page: "systemGroupedBackground"
  card: "secondarySystemGroupedBackground"
  ink: "label"
  muted: "secondaryLabel"
  rule: "separator"
  rating-elite-light: "#6B4BC4"
  rating-elite-dark: "#C3A6FF"
  rating-star-light: "#155CB0"
  rating-star-dark: "#6BB3FF"
  rating-starter-light: "#22661F"
  rating-starter-dark: "#67D77A"
  rating-rotational-light: "#8A5000"
  rating-rotational-dark: "#F5A93C"
  rating-fringe-light: "#AB2A1E"
  rating-fringe-dark: "#FF8A80"
typography:
  display:
    fontFamily: "SF Pro"
    fontSize: "largeTitle, Dynamic Type"
    fontWeight: 700
  title:
    fontFamily: "SF Pro"
    fontSize: "title3, Dynamic Type"
    fontWeight: 600
  body:
    fontFamily: "SF Pro"
    fontSize: "body, Dynamic Type"
    fontWeight: 400
  label:
    fontFamily: "SF Pro"
    fontSize: "caption, Dynamic Type"
    fontWeight: 600
  figure:
    fontFamily: "SF Pro"
    fontSize: "title3, Dynamic Type"
    fontWeight: 600
    fontFeature: "tabular numerals"
rounded:
  chip: "9999px"
  card: "20px"
spacing:
  tight: "6px"
  small: "10px"
  medium: "16px"
  large: "24px"
  row: "52px"
components:
  chip:
    typography: "{typography.label}"
    rounded: "{rounded.chip}"
    padding: "4px 10px"
  chip-filled:
    textColor: "#FFFFFF"
    typography: "{typography.label}"
    rounded: "{rounded.chip}"
    padding: "4px 10px"
  card:
    backgroundColor: "{colors.card}"
    rounded: "{rounded.card}"
    padding: "16px"
---

# Design System: Pro Football Coach

## Overview

**Creative North Star: "The Broadcast"**

A modern sports app. Neutral system surfaces carry the work; the franchise's colour arrives as a
band above the content it belongs to; everything else that used to be a label is a chip. Clubs
have faces — each of the 32 marks is drawn from that club's own two colours.

Loudness is structural, not decorative: one colour band per surface, and only on the surfaces
that earn it. Underneath the band the card stays neutral and legible, which is what lets the cap
sheet and the roster stay calm while gameday still looks like gameday.

Grounds and text come from the system semantic set rather than hand-picked hexes. That is the
modern-iOS default and, unlike a bespoke palette, it adapts to Dark Mode, Increased Contrast and
Reduce Transparency without a table anyone has to maintain. The rating ladder is the one place
fixed hexes remain, because there the colour carries meaning — and it is verified by test.

**Key characteristics:**
- Team colour in a band; neutral card beneath it
- Chips for metadata, not labels-and-rules
- Drawn team marks using both club colours — no image assets
- Tabular figures on anything that changes
- Flat: no shadows, no gradients on body surfaces
- Every colour-coded value readable without colour

## Colors

### Grounds and text
System semantic throughout — `systemGroupedBackground` for the page, its secondary for cards,
`label` / `secondaryLabel` for text, `separator` for rules. Reached through `Broadcast.page`,
`.card`, `.ink`, `.muted`, `.rule` so a future change happens in one file.

### Team colour
Each club has a primary and a secondary. The primary fills bands, marks and primary actions; the
secondary cuts the club's motif. In dark mode the tint used for controls is lifted until it clears
4.5:1 against the wash a bordered button paints behind its own label.

### The rating ladder
Five bands, light/dark pairs, purpose-picked: the system's own `.green` and `.orange` measure
2.2:1 as text on a white card.

- **Violet — Elite** (90+, `#6B4BC4` / `#C3A6FF`)
- **Cobalt — Star** (84–89, `#155CB0` / `#6BB3FF`)
- **Field Green — Starter** (74–83, `#22661F` / `#67D77A`)
- **Amber — Rotational** (64–73, `#8A5000` / `#F5A93C`)
- **Brick — Fringe** (<64, `#AB2A1E` / `#FF8A80`)

### Named rules

**The One Band Rule.** One team-colour band per surface. It sits above the content it labels and
never becomes the body surface — 32 arbitrary club colours behind body text is a guaranteed
contrast failure.

**The Measured-Surface Rule.** A colour is verified against the surface it is actually drawn on —
the card, the page, and the composited chip tint — not against an idealised white.

**The Never-Colour-Alone Rule.** No state is carried by hue alone. A rating chip shows its number;
a result chip says "Won"; the tier word goes to VoiceOver.

## Typography

SF Pro throughout, text styles only, tabular figures on anything that changes. `displayFont` for
scores and screen titles, `titleFont` for names and section heads, `bodyFont` for running copy,
`labelFont` for chips and column heads, `figureFont` for numbers.

Sentence case. The tracked ALL-CAPS overline belonged to the previous world and is gone.

## Layout

Single-column scroll of cards inside the safe area. Spacing scale `tight` 6, `small` 10,
`medium` 16, `large` 24; rows target 52pt against a 44pt minimum. iPhone portrait only, except
the arcade screen which opts into landscape.

## Elevation & depth

Flat. No shadows anywhere. Depth is tonal — the card lifts off the page in both appearances — and
the band supplies the only strong value contrast on a surface.

## Components

- **Card** — the default container. 20pt continuous radius, no border, no shadow.
- **Stamp** — the chip. Capsule, label over a 14% wash of its own colour; `filled` is opt-in and
  takes a colour dark enough for white on it.
- **Rule** — hairline separator inside a card.
- **LedgerRow** — label left, figure right, baselines aligned.
- **BroadcastBand** — the signature: team-colour header over neutral content.
- **TeamMark** — the club's logo, drawn from its own two colours. Motif is derived from the
  abbreviation, so it is stable across launches and a league invented later gets one free.
  `legibleMotif` lifts a trim colour that shares its field's luminance.
- **Rating value** (`.ratingStyle(_:)`) — tier colour plus the tier word as an accessibility value.

Controls are stock SwiftUI. Reinventing switches, pickers and swipe actions is the most common
form of native slop.

## Do's and don'ts

**Do**
- Reference tokens: `Broadcast.ink`, `Layout.medium`, `.figureFont`, `RatingTier`.
- Put the team colour in a band, and the content on a card under it.
- State the number and its consequence together.
- Use `.motionAware(_:value:)` rather than `.animation`.

**Don't**
- Don't put a literal spacing value, radius, hex or point size in a view.
- Don't let team colour become a body surface.
- Don't add a shadow.
- Don't fill a chip with a light colour and put white on it.
- Don't use ALL-CAPS overlines or serif display type — that was the retired Almanac.

## Anti-references

- **The college reference app.** Clean-room: no copied layouts, colours, icons or strings.
- **The Franchise Almanac.** The retired second world of this project: paper grounds, New York
  serif, printed rules, squared stamps. Well-executed and wrong for the product — it read as a
  document rather than a sports app. Superseded 2026-08-09.
- **The Coordinator's Clipboard.** The retired first world: native restraint with no identity.
- **Madden / EA glossy chrome.** No faux-3D bevels, metallic gradients, or skewed italics.
- **The generic AI dashboard.** No purple-gradient SaaS look, no emoji standing in for icons.

## Known drift

Tracked against `docs/AUDIT.md`; each is owned by a redesign phase in
`docs/plans/2026-08-09-almanac-redesign.md` rather than patched on the old skin.

- Some `Chip` call sites take a rating colour directly and carry no spoken tier.

- Roughly 70 literal spacings, radii and font sizes remain in views built before the token layer.
- Contrast failures inherited from the old skin's filled chips, gradient hero text and raw system
  colours are superseded rather than fixed: those components cease to exist as their surfaces are
  rebuilt.
- Sheets do not inherit the root's `preferredColorScheme`. Settings, the wizard, the tutorial,
  scenarios and load now set it themselves; the player card and negotiation sheets still follow
  the system appearance rather than the chosen one.
- Two clubs can draw the same motif — the mark is derived from the abbreviation across seven
  shapes, so collisions are expected. Colour distinguishes them; a larger motif set would reduce
  it.
