---
name: Pro Football Coach — Primetime
description: The fourth design system, feel-first — a broadcast done in text. Time (motion, sound, haptics, staging) is first-class; surfaces stay calm so staging reads.
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
  display: { fontFamily: "SF Pro Rounded", fontSize: "largeTitle, Dynamic Type", fontWeight: 800 }
  title: { fontFamily: "SF Pro", fontSize: "title3, Dynamic Type", fontWeight: 600 }
  body: { fontFamily: "SF Pro", fontSize: "body, Dynamic Type", fontWeight: 400 }
  label: { fontFamily: "SF Pro", fontSize: "caption, Dynamic Type", fontWeight: 600 }
  figure: { fontFamily: "SF Pro", fontSize: "title3, Dynamic Type", fontWeight: 600, fontFeature: "tabular numerals" }
spacing: { tight: "6px", small: "10px", medium: "16px", large: "24px", row: "52px" }
rounded: { chip: "9999px", card: "20px" }
motion:
  instant: "≤100ms"
  beat: "220ms"
  stage: "550ms"
  moment: "1600ms"
---

# Design System: Primetime

The fourth system. The first three (Coordinator's Clipboard, Franchise Almanac, The Broadcast) were static styling systems — colors, type, spacing — that specified surfaces and never time. Primetime is built feel-first: **§2 The Time Layer is the core of this document**, and the visual chassis exists to stay out of its way. Every element traces to one of three declared sources — research (`docs/research/R1a–R1d`, `R2-synthesis.md`), platform doctrine (Apple HIG and the `design/game-feel` skill's engineering discipline, cited as "game-feel doctrine"), or `NOVEL` with reasoning.

## 1. Identity

**North star: a broadcast, done in text.** (R2 ruling T3)

A real telecast is confident and plainspoken — its drama comes from staging: pacing, the cutaway, the stat card fired at the earned moment, the held beat before the number lands. That is this game's identity. Not glossy chrome, not a spreadsheet: a professional broadcast package for a league that happens to be fictional and rendered in text.

Positive commitments (what Primetime *does* — pays the identity debt, R2 §1.3b):

1. **Every meaningful sim event is narrated.** The engine never pays in silence (Pillar P2).
2. **Numbers arrive staged, never dumped** (Pillar P4; ADJ-35).
3. **The calendar creates occasions.** Marquee games look and sound like marquee games (MAD-04).
4. **The fictional press has personality; the system voice does not** (OD-1).
5. **Restraint everywhere else, so staging reads** (ADJ-24). One band of team color per surface; neutral cards; flat depth; no ambient motion.

Anti-references, kept short: EA-style glossy chrome and skewed italics; the generic purple-gradient dashboard; all three retired systems (each was correct and inert); scanline/CRT nostalgia (Retro Bowl's trade dress — legal and positioning).

## 2. The Time Layer

The missing layer of the first three systems. Everything here ships with a Reduce Motion variant and an accessibility story, or it does not ship.

### 2.1 The clock ladder (motion tokens)

| Token | Budget | Used for |
|---|---|---|
| `instant` | ≤100ms | Acknowledging any tap — response floor (ADJ-21) |
| `beat` | ~220ms | Standard transitions: card arrival, segment change, navigation accompaniment |
| `stage` | ~550ms | One staged number resolving (ADJ-35's staggered-digits budget) |
| `moment` | ~1.6s | Celebrations and chapter turns only — the rarest tier |

Rules: no animation exceeds its tier's budget; nothing loops ambiently (juice amplifies meaning, never decorates — game-feel doctrine); a staged interruption never exceeds a ~20-second read (ADJ-36); **values never teleport** — every changing figure animates via numeric content transition (under Reduce Motion, `count` degrades to a direct swap paired with its haptic; that is the sanctioned exception).

### 2.2 Named motions

Each motion is a token with a purpose, a shape, and a Reduce Motion (RM) variant. RM variants replace position/scale motion with opacity/crossfade; meaning always persists in a non-motion channel (ADJ-38).

| Motion | Purpose | Shape | RM variant |
|---|---|---|---|
| `tick` | Advance acknowledged | Instant state change + haptic `.advanceTick` | identical (no motion involved) |
| `settle` | A card lands in the feed | Slide-up 12pt + spring settle, `beat` | crossfade |
| `count` | A figure changes | Rolling numeric transition, `beat` | direct swap + haptic |
| `stagger` | A set of figures resolves in sequence | Left-to-right or top-down, 60–90ms offsets, total ≤ `stage` (ADJ-35) | figures appear together, sound/haptic sequence preserved |
| `hold` | The breath before a big reveal | 300ms deliberate pause, dimmed context (hitstop translated — ADJ-23) | identical (a pause is not motion) |
| `sweep` | Score strip updates | Horizontal content slide, `beat` | crossfade |
| `turn` | Chapter transition (season phase, firing, new job) | Full-card crossfade + sting, `moment` | identical minus any parallax |

`NOVEL` (shape choices); mechanisms trace ADJ-22/23/35.

### 2.3 The number staging grammar (Pillar P4)

Every headline number resolves through the same four-step grammar (ADJ-35, ADJ-36, ADJ-23):

**anticipate** (context line appears — what's at stake) → **hold** (300ms) → **resolve** (`stagger`/`count`, paired sound+haptic per step) → **settle** (final state + consequence line, per "say the number, then say what it means").

Staging specs — each headline moment ships with this table filled in; these are the v1 set:

| Moment | Anticipate | Resolve | Consequence line | Channels |
|---|---|---|---|---|
| Final score | "FINAL — <venue>" strip | Scores `count` up, winner's figure lands last | Record update + next hook | sound `sting-final`, haptic `.milestone` on win |
| Cap move (cut/sign/trade) | "Cap impact" | Dead money, then cap space `stagger` | "…leaves $6.2M dead through 2028" | haptic `.negative`/`.positive` |
| Draft pick | Card with pick number, `hold` | Name reveals, then position/college/grade `stagger` | War-room grade + fit line | sound `card`, haptic `.reveal` |
| Camp reveal (OVR/potential) | Player face + "Camp report" | Arrow + new rating `count` | What changed and why | haptic `.positive`/`.negative` |
| Record broken | "League record" banner, `hold` | Old mark strikes, new mark `count` | Holder + season context | sound `sting-final` (record variant), haptic `.milestone` |
| Award | Nominee context | Winner reveal after `hold` | Career ledger line appended | sound `card` |
| Contract signed | Ask vs offer recap | Years/money `stagger` | Cap line + morale effect | haptic `.positive` |

The total is withheld until resolve for the biggest reveals (ADJ-35). Live win-probability is **not** shown as an always-on figure; swing charts appear retrospectively at half and final (ADJ-36, R2 T5).

**Hero-surface first renders** (the P4 gate check applies to these three, by name):
- *Live gameday:* first render is the score strip + situation line + play panel — no staged interruption on entry; staging fires on events (score, turnover, final).
- *Season hub:* first render shows THIS WEEK settled and the feed in its landed state; staging happens only during the advance sequence (§2.2 `tick`→`settle` stagger), never on tab entry.
- *Player card:* identity band and arc strip render immediately; the hero figure uses the camp-reveal staging only when a change is unseen — otherwise it renders settled with its tier word. Attribute walls never render as the first screenful (summary rows + one-tap-deeper).

### 2.4 Sound language

Minimal mastered kit (game-feel doctrine: four to six effects cover the app; rarity gradient in loudness):

| Sound | Fires on | Character |
|---|---|---|
| `tick` | Week advance, sim step | Short, quiet, pitch-stable |
| `card` | Feed card / reveal lands | Soft pop, ~0.2s |
| `up` | Positive resolution | Bright, ~0.3s |
| `down` | Negative resolution | Dull thud, ~0.3s |
| `sting-final` | Game final, occasion-flavored variants | ~0.6s |
| `fanfare` | Championship tier only — the rarest, biggest sound | 1.5–2s |

Engineering policy (from `design/game-feel`): `.caf` PCM assets preloaded once at startup; session `.ambient` + `.mixWithOthers` — the user's podcast or music keeps playing, effects layer over it; the silent switch is respected (management game, not a room game); in-app SFX mute independent of haptics toggle; repeated sounds ship 8–12 pitch/volume variants against fatigue (ADJ-37). Sounds never carry state alone — VoiceOver announcements accompany state changes.

### 2.5 Haptic language

Core Haptics semantic vocabulary, one central service owning the engine (game-feel doctrine: name events by meaning; single owner per event; lazy start; capability-gated; background-stopped; optional seam for tests; user toggle — there is no system-wide haptics setting):

A note on system settings: iOS *does* ship system-wide haptic controls (Sounds & Haptics → System Haptics; Accessibility → Touch → Vibration, which silently disables all engine output device-wide). The in-app toggle still ships — it is the per-app control users expect — and because playback can be silently disabled, haptics are never the sole carrier of any state (mirrors §2.4's rule for sound).

| Event | Shape (tune on device) |
|---|---|
| `.advanceTick` | Light transient (0.4/0.3) — the loop's heartbeat |
| `.cardLand` | Soft transient (0.5/0.4) |
| `.reveal` | Medium transient (0.6/0.5) after every `hold` |
| `.positive` | Crisp transient (0.8/0.7) |
| `.negative` | Dull heavy transient (0.6/0.25) |
| `.stakes` | Two light transients 120ms apart — pre-resolution tension (ADJ-34) |
| `.milestone` | Two ascending transients |
| `.championship` | Three ascending transients + continuous swell — the biggest pattern in the app, played nowhere else |

Escalation tiers are pattern pairs (same shape, more intensity) and their thresholds match the visual escalation exactly. Haptic and audio transients co-fire same-frame and match perceived size (causality/harmony/utility — ADJ-37). Transients for instants; continuous ramps only for staged counts.

### 2.6 Celebration choreography

Rarity gradient (game-feel doctrine): if the rarest event fires the same pattern as a routine one, the app has no climax.

| Tier | Occasion | Choreography |
|---|---|---|
| 1 | Game win | Final-score staging (§2.3) + `.milestone`; no takeover |
| 2 | Division clinch, playoff berth | Tier 1 + clinch banner card with `turn`, `sting-final` variant |
| 3 | Conference title | Full-screen title card, `moment` budget, staged season line |
| 4 | **Championship** | The only tier with `fanfare` + `.championship`: title card → staged season retrospective (record, road, star ledger lines) → trophy-room card. ≤20s total, skippable |
| — | Chapter turns (fired, retired, rebuild begins) | Equal-weight somber treatment: `turn` motion, `down` sound, next-arc card — losing opens a chapter (Pillar P6), never silence |

Copy inside celebrations stays declarative — the number and what it means; the staging carries the emotion (T3).

### 2.7 The occasion system

Presentation skins keyed to the schedule (MAD-04: calendar structure converted into perceived occasion): **standard / division rival / marquee (game of the week) / playoffs / championship**. Marquee designation is schedule-derived — computed from standings stakes and rivalry, presentation-only, no scheduling mechanic (`NOVEL` derivation rule; MAD-04 covers the skin swap itself). A skin varies: score-strip accent, game-card header treatment, sting variant, and the fictional broadcast identity named on the card. All show identities are original and fictional (legal guardrail; network-lookalikes explicitly avoided — R2 §3).

## 3. Voice

Two registers, never blended (OD-1):

- **System voice** — confident, plainspoken, durable. Short declaratives, real numbers, sentence case, no exclamation marks. "Say the number, then say what it means" is a layout rule: fact line, consequence line.
- **Press voices** — the fictional league's media carry personality: the beat writer (dry, specific), the columnist (opinionated, quotable), the radio desk (quick, teasing). They narrate cards and shows; they may exclaim; they never state numbers the sim didn't produce (media reports state, never invents — R2 T4).

Losing is written as a chapter, not an end (ADJ-45): "4–13. The rebuild starts at the draft — three picks in the top 40."

## 4. Color

Neutral chassis + one band of team color + tested accents. Carried forward only what the audit machine-verified (AUDIT.md positive findings); everything else re-earned.

- **Grounds and text:** system semantics (`systemGroupedBackground`, secondary card fill, `label`/`secondaryLabel`, `separator`). Adapts to Dark Mode and contrast settings for free. *(Re-earned: AUDIT positive — resolves correctly, zero cost.)*
- **Team color:** primary fills the band, the mark, and primary actions; dark-mode control tint is lifted until it clears 4.5:1 against the composited wash. *(Re-earned: machine-verified per team by tests.)* **One Band Rule** stands: one team-color band per surface, never a body surface.
- **Rating ladder:** five tiers, light/dark hex pairs (front matter), each verified at 4.5:1 against card, page, and chip wash in both themes, tier word spoken to VoiceOver. *(Re-earned: AUDIT called this "better colour discipline than most shipping apps.")*
- **Semantic status set** — `positive / caution / negative / info` as light/dark pairs, added to the same contrast test loop. **Raw system colors (.green, .orange, .red, .teal, .blue, .purple) are banned as text or chip tints** — this is the fix for AUDIT's 50+-site contrast class.
- **The Measured-Surface Rule** and **Never-Color-Alone Rule** stand unchanged (validated by the audit's refutation record).
- **The coverage law** *(new, from AUDIT's systemic finding #1)*: a color pairing that is not in the automated contrast suite does not ship. The test's boundary is the design's boundary, by construction.

## 5. Typography

SF Pro; text styles only — no hard-coded point sizes anywhere (AUDIT class: ten literals, four below floor). Roles: **Display** (SF Pro Rounded, heavy, largeTitle — scores and heroes), **Title** (title3 semibold), **Body**, **Label** (caption semibold — chips, column heads), **Figure** (title3 semibold, tabular numerals — anything that changes). Sentence case throughout. Tabular figures are mandatory on changing values; `count` motion assumes them.

## 6. Layout

Single-column scroll of cards inside the safe area; spacing scale `tight 6 / small 10 / medium 16 / large 24`; rows target 52pt. **Touch floor: every tappable surface ≥44×44pt** — both dimensions — via `minWidth`/`minHeight` + `contentShape`, including chip-shaped buttons (AUDIT class; HIG). **Click budgets:** every deep screen's spec states its taps-to-information budget (routine fact ≤2 taps from its surface's root — R2 T1, FM-19). Fixed-width frames around scaling text are banned — gutters use `@ScaledMetric` with `minimumScaleFactor` backstop (AUDIT class; the `TeamBadge` pattern generalized). Portrait-locked app; the arcade scene alone opts into landscape (AUDIT orientation class).

## 7. Components

- **Card** — default container, 20pt radius, flat.
- **FeedCard** — the narrative unit (Pillar P1/P5 anatomy): face (player/coach mark) + headline number + consequence line + severity tier + optional action + **blocking flag** — a card blocks the week advance only when its decision has deadline semantics in the sim (contract deadline, lineup, expiring offer); everything else is non-blocking (R2 T1, OD-3).
- **DataTable** — the deep-layer primitive for roster, cap, stats, and scouting tables: column picker, density toggle, persistent sort, ≥52pt rows, tabular figures, horizontal overflow in its own scroll (R2 T1; FM-09/FM-19/FM-21 — the expertise surface is never amputated, it is one tap below its card).
- **ScoreStrip** — the persistent identity element: abbreviations, score, clock/state, occasion accent; readable sound-off at a glance (MAD-04; broadcast-bug doctrine, R1a §7).
- **StakesPanel** — pre-resolution odds/risk display for decisions (4th down, blitz, trade verdict): shows true numbers (R2 T5) with `.stakes` haptic (ADJ-34).
- **StagedFigure** — wrapper implementing §2.3 for any headline number.
- **LedgerRow** — label left, figure right, baselines aligned; the career-ledger row (Pillar P5).
- **Chip** — metadata pill only, never a control; label over 14% wash of a *vetted* color.
- **TeamMark** — club mark drawn from the club's two colors; no image assets.
- **EmptyState** — icon + headline + sentence; every listable surface has one (AUDIT positive, kept).
- Controls are stock SwiftUI. Reinventing them is the most common native slop (AUDIT positive, kept).

## 8. Platform physics (construction requirements, not audit items)

- Dynamic Type to XXXL without truncation or overlap on every screen.
- 4.5:1 measured-surface contrast, both themes, enforced by the coverage law (§4).
- 44pt touch minimum (§6).
- Reduce Motion: every named motion and staging spec carries its RM variant (§2.2); haptics and sound are never gated on Reduce Motion (unrelated setting).
- VoiceOver: stat rows read as sentences; staged reveals post announcements; custom meters expose label *and* value; haptic/SFX user toggles in Settings.
- Persistence and rendering honor the perf budgets: advance <150ms end-to-end, saves off the main actor (AUDIT P0 is an architecture requirement now).

## 9. Do / Don't

**Do**
- Route every event through the staging grammar; fire feedback from exactly one owner per event.
- Reference tokens for every spacing, radius, color, duration.
- State the number, then its consequence, in that order.
- Give every changing figure tabular numerals and a `count` transition.

**Don't**
- Don't dump a wall of figures as any surface's first render (Pillar P4).
- Don't ship an event without its witnessing card (Pillar P2) or a card without a face (P5).
- Don't exceed the tier budget or loop ambient motion.
- Don't put team color under body text, raw system color on anything, or a literal value in a view.
- Don't fire `.championship` or `fanfare` for anything but tier 4. The climax is a budget.

## 10. Known debts at birth

None. This document starts clean by construction: the coverage law (§4), the staging-spec table (§2.3), and the RM-variant column (§2.2) exist precisely so drift is caught by machines, not by the next audit.
