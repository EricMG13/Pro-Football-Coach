# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Football management-sim players on iPhone. The core audience is the community orphaned by the *Football Coach* / *Pro Football Coach* lineage (r/FootballCoach): the Android originals were abandoned in 2019 and the developer's successor, *Pro Football Dynasty*, is Steam-only. They have been asking for an iOS pro sim for years. They are genre-literate — they read a dead-money figure and argue with it.

Two usage shapes, no mode switch between them:

- **Fast:** phone in hand, one-handed, a few minutes. Advance the week, check standings, close the app.
- **Deep:** an hour inside free agency, the draft, or the cap sheet.

The job: run a franchise and build something that lasts across a decade of seasons — make the call, see the consequence, live with it.

## Product Purpose

A native, offline pro-football franchise simulator: sim or play games, manage a 53-man roster plus a 16-player practice squad, run the salary cap, draft, trade, negotiate contracts, and build a dynasty. Success is a player who onboards through the wizard, survives a full offseason, and starts season two with a coherent roster and cap — then keeps going.

## Positioning

Modern iOS has a polished *college* football sim; it has no modern *pro* football management sim. The 2016 Android incumbent is abandoned and shipped contracts without a real cap by its own author's admission; the desktop successor is Steam-only. This pairs the proven mobile UX formula with the cap, draft, and trade depth the community has requested for years, plus live two-way play-calling and an "On the Field" arcade mode.

## Operating Context

Fully offline. No backend, no accounts, no network, no analytics, no ads. Saves are local JSON slots in Application Support with a versioned `saveFormatVersion`, rolling backups, weekly autosave, and manual checkpoints.

The season is a calendar the player walks through: preseason → 17-game regular season → 14-team playoffs → a ten-stage offseason (review, coaching carousel, retirements, re-signing, tags, free agency, draft, training camp, cutdown, preseason). The league runs all 31 AI teams through every stage; a news feed narrates it.

## Capabilities and Constraints

- Fixed fictional league: 32 teams, 2 conferences × 4 divisions × 4 teams.
- Ratings are 40–99 integers. Money is integer dollars — no floating-point currency.
- Simulation engine is a standalone Swift package (`FootballSimCore`): pure logic, no UI imports, deterministic under a seeded RNG, unit- and calibration-tested. The SwiftUI layer never contains game rules.
- Gameplay constants live in `LeagueRules.swift`; no inline magic numbers.
- iOS 17 minimum, Swift 5.10+, SwiftUI, `@Observable` view models, zero third-party dependencies.
- No image assets for team identity — 32 logos are composed geometrically in code.
- Performance and durability targets that shape design: week advance under 150 ms, saves under 5 MB, ten simulated seasons with no crash or calibration drift.
- **Undecided:** monetization. v1 ships no in-app purchase and the franchise editor is free; whether a later IAP exists is explicitly deferred.
- **Not in v1** (backlog, not scope): custom league editor with JSON import/export, controllable post-snap defense, weather, restructures, position coaches, Game Center leaderboards, multiplayer, iPad layout.

## Brand Commitments

Name: **Pro Football Coach**. Tagline: "Run the franchise. Call every down."

Voice is **confident, plainspoken, durable** — a good coordinator explaining a decision. Short declaratives, real numbers, no hype. "Cutting Reyes leaves $6.2M dead through 2028," never "Uh oh! That's a big cap hit!" Sentence case; no exclamation marks in system copy; no marketing language. A professional instrument that happens to be fun, not a toy with spreadsheets attached.

Binding legal constraint: **every team name, city pairing, logo, player name, and mark is fictional and original.** No real league's or college's names, marks, or players appear anywhere. The reference app that inspired the information architecture is design inspiration only — a clean-room rule forbids copying its UI assets, strings, or source, and the open-source ancestor is CC-NonCommercial and must not be read or reused.

## Evidence on Hand

- Design and planning canon in `docs/`: executive plan, research, game design, architecture, screen spec, implementation plan, played-game mode, build status.
- Working implementation: `Sources/FootballSimCore` (engine), `Sources/ProFootballCoachUI` (SwiftUI layer), a hand-rolled test harness with ~13,000 assertions.
- Community evidence for demand is real and cited in `docs/01-RESEARCH.md` (store reviews, subreddit requests, abandoned-app history).
- **No real assets exist:** no logos, no photography, no licensed marks, no testimonials, no user research beyond public community signal, no shipped-app metrics. Future work must not fabricate any of these.

## Product Principles

1. **The simulation is the product.** Believable numbers outrank everything else; the interface exists to make consequences legible. Calibration bands are a product requirement, not a test detail.
2. **Never lose a dynasty.** Save corruption around season eight was the single largest complaint against the incumbent. Durability is a feature the player must be able to feel.
3. **Serve the two-minute session and the one-hour session with the same screens.** Depth lives behind a tap, never behind a mode.
4. **Say the number, then say what it means.** State the fact and its consequence together, in the player's terms. Never make the player do arithmetic the engine already did.
5. **Everything original.** Fictional identity is a hard boundary, not a style choice.

## Accessibility & Inclusion

Committed to WCAG AA as the working floor, and to native iOS accessibility as a construction requirement rather than an audit item:

- Every screen survives Dynamic Type at XXXL without truncation or overlap.
- 4.5:1 contrast for text in both light and dark themes, verified against the actual surfaces a value is drawn on rather than assumed.
- 44pt minimum touch targets.
- Meaningful VoiceOver labels on stat rows and metadata chips — a box-score row reads as a sentence, not nine loose numbers.
- Reduce Motion honored on every transition and celebration.
- No state may be conveyed by color alone; every color-coded value carries a number, word, or symbol as well.
