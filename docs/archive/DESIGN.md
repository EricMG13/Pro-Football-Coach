---
name: Pro Football Coach
description: A native iOS pro-football franchise simulator — calm front office, loud gameday.
colors:
  page-light: "#F2F2F7"
  page-dark: "#000000"
  card-light: "#FFFFFF"
  card-dark: "#1C1C1E"
  rating-elite-light: "#6B4BC4"
  rating-elite-dark: "#C3A6FF"
  rating-star-light: "#1665C0"
  rating-star-dark: "#6BB3FF"
  rating-starter-light: "#22661F"
  rating-starter-dark: "#67D77A"
  rating-rotational-light: "#8A5000"
  rating-rotational-dark: "#F5A93C"
  rating-fringe-light: "#AB2A1E"
  rating-fringe-dark: "#FF8A80"
typography:
  display:
    fontFamily: "SF Pro Rounded"
    fontSize: "34pt (largeTitle, Dynamic Type)"
    fontWeight: 700
    lineHeight: "system"
  headline:
    fontFamily: "SF Pro"
    fontSize: "17pt (headline, Dynamic Type)"
    fontWeight: 600
  body:
    fontFamily: "SF Pro"
    fontSize: "17pt (body, Dynamic Type)"
    fontWeight: 400
  label:
    fontFamily: "SF Pro"
    fontSize: "15pt (subheadline, Dynamic Type)"
    fontWeight: 400
  chip:
    fontFamily: "SF Pro"
    fontSize: "11pt (caption2, Dynamic Type)"
    fontWeight: 600
rounded:
  chip: "10px"
  card: "20px"
  capsule: "9999px"
spacing:
  tight: "6px"
  small: "10px"
  medium: "16px"
  large: "24px"
  row: "52px"
components:
  card:
    backgroundColor: "{colors.card-light}"
    rounded: "{rounded.card}"
    padding: "16px"
  chip:
    textColor: "{colors.rating-star-light}"
    typography: "{typography.chip}"
    rounded: "{rounded.capsule}"
    padding: "4px 10px"
  chip-filled:
    backgroundColor: "{colors.rating-star-light}"
    textColor: "{colors.card-light}"
    typography: "{typography.chip}"
    rounded: "{rounded.capsule}"
    padding: "4px 10px"
---

# Design System: Pro Football Coach

## Overview

**Creative North Star: "The Coordinator's Clipboard"**

A working instrument owned by a professional. Everything on it is legible at a glance under time pressure, nothing is decorative, and every number is one you can act on. The interface earns trust the way a good clipboard does — by being unfussy, consistent, and never in the way of the decision.

The system runs in two registers. The **chassis** is native iOS restraint: grouped backgrounds, white cards, generous whitespace, hairline dividers, colour only where it carries meaning. That is the default for the franchise — roster, cap sheet, contracts, settings, stats. The **hero register** is broadcast: deep team-colour bands, tabular heavy numerals, tight stat blocks, high-contrast win/loss states. It is the moment you flip the clipboard around and show someone. It is permitted on exactly six surfaces and nowhere else (see Components).

Confirmed anti-references: the college reference app whose information architecture inspired this one — clean-room, no copied layouts, colours, icons, or strings; Madden/EA glossy chrome — no faux-3D bevels, metallic gradients, or skewed italics; the spreadsheet — no dense multi-column table as a default view; the generic AI dashboard — no purple-gradient SaaS look, no default component-library card grid, no emoji standing in for icons.

**Key characteristics:**
- Two registers, with a fixed list of which surfaces get the loud one
- Flat by construction — zero shadows anywhere in the system
- Team colour as accent only; body surfaces stay neutral system backgrounds
- Every colour-coded value is also readable without colour
- Tokens in one file; a literal in a view is a defect

## Colors

A neutral system chassis carrying two colour families that both mean something: the team's identity, and a player's quality.

### Primary
- **Team Tint** (per-franchise, e.g. Empire Harbor Navy `#14294B`, Ironmen Iron Black `#2B2B2B`): the coached team's own colour, injected through the environment so every screen re-themes when a coach changes jobs. Drives tint, primary CTAs, chips, hero bands. In dark mode the raw team hex is lifted toward white until it clears 4.5:1 against the wash a bordered control paints behind its own label — a navy or maroon franchise would otherwise render its own buttons dark-on-dark.

### Secondary — the rating ladder
Five bands, each a light/dark pair. Purpose-picked, not system colours: `.green` and `.orange` as text on a white card measure 2.2:1, and four of five system bands failed AA before this ladder replaced them.

- **Violet — Elite** (90+, `#6B4BC4` / `#C3A6FF`)
- **Cobalt — Star** (84–89, `#1665C0` / `#6BB3FF`)
- **Field Green — Starter** (74–83, `#22661F` / `#67D77A`)
- **Amber — Rotational** (64–73, `#8A5000` / `#F5A93C`)
- **Brick — Fringe** (<64, `#AB2A1E` / `#FF8A80`)

### Neutral
- **Page** (`#F2F2F7` light / `#000000` dark): `systemGroupedBackground`. The canvas behind every scroll.
- **Card** (`#FFFFFF` light / `#1C1C1E` dark): `secondarySystemGroupedBackground`. The primary container.
- Label, secondary label, and separator come from the system semantic set and are never hard-coded.

### Named Rules

**The Accents-Only Rule.** Team colour touches tint, CTAs, chips, hero bands and the scoreboard. It never becomes a body surface. With 32 arbitrary fictional colour pairs, immersive theming guarantees contrast failures; accents keep every screen legible in both themes with no per-team correction table.

**The Measured-Surface Rule.** A colour is verified against the surface it is actually drawn on — the card, the page, and the 14% chip tint — not against an idealised white. The first version of the team-tint check measured against a background the app never draws, and all thirty-two teams passed in the test while failing on the phone.

**The Never-Colour-Alone Rule.** No state is carried by hue by itself. Rating bands come out near-isoluminant, because clearing 4.5:1 on white forces all five dark and compresses the available lightness — so hue does all the visual work, and the adjacent number plus a spoken tier word carry the meaning for everyone else.

## Typography

**Display Font:** SF Pro Rounded (heavy) — display moments only
**Body Font:** SF Pro — everything else
**Label/Mono:** SF Pro with `monospacedDigit()` for any figure that changes

**Character:** The system face, used without decoration. Personality comes from weight and rhythm, not from a bought typeface. Rounded heavy appears only where a single number is the entire point.

### Hierarchy
- **Display** (heavy, `largeTitle`, rounded): a lone dominant figure — a player's overall on their card, a final score.
- **Headline** (semibold, `headline`): section headers, card titles, the name in a roster row.
- **Body** (regular, `body`): running copy, news items, descriptions.
- **Label** (regular, `subheadline`): row content, secondary values, stat cells.
- **Chip** (semibold, `caption2`): every metadata pill — week numbers, positions, home/away, contract years.

### Named Rules

**The Tabular Figures Rule.** Any number that changes between rows or ticks uses `monospacedDigit()`. Ratings, scores, clocks, cap figures, stat columns. Digits that shift width while a game clock runs read as instability.

**The Dynamic Type Rule.** Text styles only — no hard-coded point sizes. Every screen must survive XXXL without truncation or overlap.

## Layout

A single-column vertical scroll of focused cards, inside the safe area. Long scroll beats dense table; one concept per card. Depth lives behind a tap — sheet for a self-contained sub-task, push for the live game and trophy room — never in density.

Spacing is a four-step scale: `tight` 6, `small` 10, `medium` 16, `large` 24. Cards pad at `medium`. List rows target a `52` height, comfortably above the 44pt touch minimum. Navigation is a five-tab bar whose first tab re-labels itself Season or Offseason with the calendar phase; tabs are sections, never actions.

## Elevation & Depth

**Flat by construction. The system has no shadows at all** — not on cards, not on chips, not on bars.

Depth is tonal. In light mode the page is grey and cards are white, so cards read as nearer. In dark mode that inverts: the page is true black and cards lift to `#1C1C1E`. The same ordinal relationship survives both themes without a single shadow, and it costs nothing on scroll performance.

### Named Rules

**The Flat-Forever Rule.** Adding a shadow to make something stand out is the wrong fix. If an element needs emphasis, it needs a surface change, a colour with meaning, or a different place in the hierarchy.

## Shapes

Two radii and a capsule. Cards use `20` with `.continuous` corner style — Apple's superellipse, not a circular arc; the difference is visible at this size. Chips and small controls use `10`. Anything pill-shaped is a true capsule.

Borders are near-absent: separation comes from surface tone, not outlines. Where a rule is needed it is a hairline system separator, never a drawn border.

## Components

- **Card** (`.card()`): `medium` padding, `20` continuous radius, card fill, no border, no shadow. The primary container for everything.
- **Chip**: capsule, `caption2` semibold, `10`×`4` padding. Two variants — tinted (label at full strength over a 14% wash of the same colour) and filled (white label on the solid colour). Used for every metadata token in the app.
- **SectionHeader**: `headline` title with an optional trailing accessory, above a group of cards.
- **EmptyStateView**: SF Symbol at `largeTitle` in tertiary, headline title, secondary message, centred. Every list that can be empty has one; no bare blank space.
- **Rating value** (`.ratingStyle(_:)`): applies the tier colour and attaches the tier word as an accessibility value, so the visible text — which may be a scouted range or a one-decimal average — is still read first.
- **Hero surfaces** (the broadcast register, this list and no other): Season Hub "This Week" card · Matchup Preview hero · Live Game scoreboard and field · Game Report final score · Draft Day on-the-clock card · Trophy Room and championship moments.

Controls are stock SwiftUI. Switch, segmented control, stepper, picker, action sheet, alert, context menu, swipe actions — reinventing these is the most common form of native slop.

### Named Rules

**The Earned-Hero Rule.** A new screen does not get the broadcast register because it feels important. It gets it by being added to the list above, deliberately.

## Do's and Don'ts

**Do**
- Reference tokens. `Layout.medium`, `RatingTier`, `TeamTheme` — the same way `LeagueRules.swift` owns gameplay constants.
- State the number and its consequence together. Show the cap hit *and* the dead money.
- Verify a new colour against the card, the page, and its own chip tint, in both themes, before shipping it.
- Give every stat row a VoiceOver reading that is a sentence, not nine loose numbers.
- Honour Reduce Motion on every transition and celebration.

**Don't**
- Don't put a literal spacing value, radius, or hex in a view.
- Don't let team colour become a body surface.
- Don't add a shadow.
- Don't use a second letter scale anywhere near ratings — Potential already owns A+…F, and a second letter grade reads as the same scale. That is why the rating tiers are words.
- Don't disable the left-edge back gesture or hide a control under the Dynamic Island or home indicator.
- Don't reach for a raw system colour as text on a card without measuring it first.

### Known drift

- The player card's overall uses a hard-coded `.system(size: 44, weight: .heavy, design: .rounded)`, which contradicts the Dynamic Type Rule. It should move to a text style before that screen is considered finished.
- Two call sites still pass a rating colour straight into `Chip` rather than through `.ratingStyle(_:)`, so those chips carry no spoken tier. The number is in the chip text, so nothing is unreadable — but the two paths should converge.
