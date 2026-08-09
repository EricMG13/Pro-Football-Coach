# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Football management-sim players on iPhone. The core audience is the community orphaned by the *Football Coach* / *Pro Football Coach* lineage (r/FootballCoach): the Android originals were abandoned in 2019 and the developer's successor is Steam-only. They have been asking for an iOS pro sim for years. They are genre-literate — they read a dead-money figure and argue with it, and they empirically audit sims that lie to them (R1c FM-38; the sibling community's worst scandal was watched-vs-simmed divergence).

Two usage shapes, one surface, no mode switch:

- **Fast:** phone in hand, one-handed, under three minutes. Open, advance the week, read what the league did to you, close.
- **Deep:** an hour inside free agency, the draft, or the cap sheet.

The job: run a franchise and build something that lasts across a decade of seasons — make the call, see the consequence, live with it.

## Product Purpose

A native, offline pro-football franchise simulator: sim or play games, manage a 53-man roster plus a 16-player practice squad, run the salary cap, draft, trade, negotiate contracts, and build a dynasty. Success is a player who onboards through the wizard, survives a full offseason, starts season two with a coherent roster and cap — and comes back, because something in their save is always about to resolve.

## Positioning

Modern iOS has a polished *college* football sim; it has no modern *pro* football management sim. The abandoned 2016 incumbent shipped contracts without a real cap by its own author's admission; the desktop successor is Steam-only; the NFL-licensed mobile alternative is locked to a subscription service; and the strongest indie comparable's documented #1 weakness — sim believability — is precisely what this project's calibrated, deterministic engine already solves (R1d ADJ-12). The engine is the moat. The rebuild adds what the research says no adjacent title pairs with it: a narrated, staged, broadcast-grade presentation of a genre-literate simulation.

## Experience Pillars

Six falsifiable pillars govern every design and build decision (full tests and traces in `docs/research/R2-synthesis.md` §4):

1. **Every advance lands a story.** Each week-advance surfaces at least one narrative card with a face, a number, and a consequence; an unresolved hook is always within three weeks.
2. **Nothing pays in silence.** Every consequence the player caused is witnessed — a staged reveal or a card with its cause attached.
3. **The advance is faster than doubt.** Week advance under 150 ms; a fast session under three minutes; a full played game under eight; management interstitials under one.
4. **Numbers are staged, never dumped.** Every headline number has a staging spec — sequence, sound, haptic, Reduce Motion variant.
5. **Every number has a face.** No faceless cards; featured players carry arcs; every player has a permanent career ledger.
6. **Losing opens a chapter.** Every failure state routes to a named next arc. No dead ends, ever.

## Operating Context

Fully offline. No backend, no accounts, no network, no analytics, no ads. Saves are local JSON slots in Application Support with a versioned `saveFormatVersion`, rolling backups, weekly autosave, and manual checkpoints. Save durability is a marketable trust property: the genre's worst modern disaster was a server-side save wipe (R1a MAD-26), and this architecture is structurally immune to that class.

Distribution is **TestFlight and personal use — no public App Store release is planned.** Confirmed, not assumed. Nothing here is designed to App Review, store metadata, age rating, or screenshot requirements; if that changes, this line changes first. The fictional-identity rule under Brand Commitments is unaffected — it is a standing project rule, not a store requirement.

The season is a calendar the player walks through: preseason → 17-game regular season → 14-team playoffs → a ten-stage offseason. Weeks are two-beat structures (midweek report, gameday and aftermath), and the schedule creates occasions — marquee games look and sound like marquee games. The league runs all 31 AI teams through every stage; the fictional press narrates it.

## Capabilities and Constraints

- Fixed fictional league: 32 teams, 2 conferences × 4 divisions × 4 teams.
- Ratings are 40–99 integers. Money is integer dollars — no floating-point currency.
- Simulation engine is a standalone Swift package (`FootballSimCore`): pure logic, no UI imports, deterministic under a seeded RNG. Its validated behavioral contract — calibration bands, believability bands, cross-process determinism, cap legality, the ten-season soak — survives the rebuild as acceptance specifications the new engine must re-earn (`docs/STATUS.md` is the reference record).
- The simulation model is never simplified for presentation. The fast loop compresses how consequences are *shown*, never how they are computed (R2 T2). One engine, one truth: watched, simmed, and arcade games produce statistically identical results.
- Probabilities shown to the player are true probabilities. Resolution is never fudged; randomness is placed upstream where it reads as terrain (R2 T5).
- Gameplay constants live in `LeagueRules.swift`; no inline magic numbers.
- iOS 17 minimum, Swift 5.10+, SwiftUI, `@Observable` view models, zero third-party dependencies.
- **iPhone only, confirmed.** Compact width is the only target; iPad and regular-width layouts are backlog, not scope.
- No image assets for team identity — 32 marks are composed geometrically in code.
- Performance and durability targets that shape design: week advance under 150 ms, saves under 5 MB, ten simulated seasons with no crash or calibration drift, persistence off the main actor.
- **Undecided, and confirmed as still open:** monetization. v1 ships no in-app purchase and the franchise editor is free; whether a later IAP exists is deferred. Do not design paywalls or locked features against a guess.
- **Not in v1** (backlog, not scope): custom league editor with JSON import/export, controllable post-snap defense, weather, restructures, position coaches, Game Center leaderboards, multiplayer, iPad layout.

## Brand Commitments

Name: **Pro Football Coach**. Tagline: "Run the franchise. Call every down."

Identity: **a broadcast, done in text** — drama produced by staging, pacing, and earned moments, never by hype (DESIGN.md §1).

Two voices, never blended (OD-1, approved at gate 1):

- **System voice** — confident, plainspoken, durable. Short declaratives, real numbers, sentence case, no exclamation marks. "Cutting Reyes leaves $6.2M dead through 2028," never "Uh oh! That's a big cap hit!" Say the number, then say what it means.
- **Press voices** — the fictional league's media (beat writer, columnist, radio desk) carry personality and may exclaim. They narrate what the sim produced; they never invent.

Losing is written as a chapter, never an end.

Binding legal constraint: **every team name, city pairing, logo, player name, show identity, and mark is fictional and original.** No real league's or college's names, marks, or players appear anywhere. Reference games are mechanics research only — a clean-room rule forbids copying UI assets, strings, trade dress, or source; the open-source ancestor is CC-NonCommercial and must not be read or reused.

## Evidence on Hand

- Research canon: `docs/research/R1a–R1d` (four evidence dossiers, ~230 cited findings) and `R2-synthesis.md` (verdict, rulings, pillars). Every design decision traces there or is marked `NOVEL`.
- Engine behavioral contract: `docs/STATUS.md` (224 tests, calibration bands, ten-season soak) — validated knowledge held as acceptance specs.
- Prior audit: `docs/AUDIT.md` (native-craft rubric, 9/20 baseline; rebuild gates require ≥17/20 with zero P0/P1 on touched surfaces).
- Community evidence in `docs/01-RESEARCH.md` (store reviews, subreddit mining, abandoned-app history).
- **No real assets exist:** no logos, no photography, no licensed marks, no testimonials, no shipped-app metrics. Future work must not fabricate any of these.

## Accessibility & Inclusion

WCAG AA is the working floor, and native iOS accessibility is a construction requirement rather than an audit item:

- Every screen survives Dynamic Type at XXXL without truncation or overlap.
- 4.5:1 contrast for text in both themes, verified against the actual composited surfaces — enforced by the coverage law: an untested color pairing does not ship (DESIGN.md §4).
- 44pt minimum touch targets, including chip-shaped controls.
- Meaningful VoiceOver labels: a box-score row reads as a sentence; staged reveals post announcements; custom meters expose label and value.
- Reduce Motion honored on every transition, staging, and celebration via a specified variant per motion — meaning always persists in a non-motion channel.
- No state conveyed by color alone; every color-coded value carries a number, word, or symbol.
- User toggles for haptics and sound effects; sounds respect the silent switch.
