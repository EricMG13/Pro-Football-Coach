# The Franchise Almanac — Complete UI/UX Redesign Plan

**Status: awaiting owner approval. No build until the signal.**

Produced by `/impeccable critique + shape` with a grilled decision tree, a 78-finding native audit
(`docs/AUDIT.md`), and a 6-cluster dual-assessment critique (8 isolated assessors). Every structural
change below is tagged with its evidence. Supersedes `DESIGN.md` (the Coordinator's Clipboard) and
the affected sections of `docs/04-SCREENS-UI.md` as each phase lands. `PRODUCT.md` and the
`FootballSimCore` engine are untouched.

---

## 1. The eight locked decisions (grilled 2026-08-09)

| # | Decision | Ruling |
|---|---|---|
| 1 | World | Replace the visual world; keep the native chassis (stock TabView/NavigationStack/sheets/controls, HIG conformance) |
| 2 | Identity | **The Almanac** — the franchise's living record book; modernist print, never sepia |
| 3 | Type | System-only: **New York serif** display/record voice + **SF** condensed chrome + tabular numerals |
| 4 | Ground | **Paper by day** (warm near-white page/card) / **night edition** on the verified true-black + `#1C1C1E` dark |
| 5 | Loud register | **Commemorative editions** — front pages, plates; live game = the box score writing itself |
| 6 | UX latitude | Full — IA and flows redesignable inside the stock shell; every change evidence-gated and listed here |
| 7 | Sequencing | Foundation first; surfaces rebuilt in ranked order with fixes by construction; the old skin is never polished |
| 8 | Process | Plan now, execute on signal; fresh `main` per phase; small file-scoped commits |

## 2. North Star

**"The Franchise Almanac."** The app is the record book a franchise writes about itself, updated
live. Every screen is a page of it: the week is a front page, the cap sheet is a ledger, a player is
a dossier entry, a season is a chapter, a championship is a commemorative edition. The voice was
always plainspoken-numeric; now the typography, paper, rules and numerals say the same thing the
copy does.

Name alternatives (veto and pick if preferred): *The League Annual* · *The Record* · *The Club Book*.

**What the Almanac is not:** sepia nostalgia, texture overlays, faux paper grain, skeuomorphic
bindings. It is modernist print: type, rules, numerals, ink, and team colour doing all the work —
flat, zero shadows, zero image assets, exactly as the constraints demand.

## 3. The evidence in one page

**Audit** (`docs/AUDIT.md`): 9/20. 1 P0 · 24 P1 · 36 P2 · 17 P3 across 425 call sites. Systemic:
contrast verified only where tested; 70+ token bypasses; Reduce Motion and VoiceOver commitments
written down with zero implementations; synchronous main-actor saves; `ArcadeGameView` dead code.

**Critique** (6 clusters, Nielsen 0–4 ×10; all Operate mode):

| Cluster | Score | Specificity | Echoes | Worst heuristics |
|---|---|---|---|---|
| Weekly Loop | **19/40** | category-interchangeable | 10 | Error prevention 1 · Efficiency 1 · Recovery 1 |
| Coach & Legacy | 20/40 | mixed | 8 | Control 1 · Efficiency 1 |
| Live Game & Arcade | 20/40 | mixed | 8 | Control 1 |
| Entry & Onboarding | 21/40 | mixed | 10 | Prevention 1 · Recovery 1 |
| Front Office & Draft | 22/40 | mixed | 9 | Recognition 1 |
| Team & Player | 24/40 | category-interchangeable | 12 | — (2s across the board) |

**57 reference echoes catalogued** — the concrete inventory of "still the reference app": the
icon+title+subtitle+chevron menu, the 4-step dot-stepper wizard, the betting-pill THIS WEEK card,
the chips-for-everything token layer, the five-tab IA adopted as a bare default, colour-tiered OVR
numerals, the segmented Standings/Rankings/News pills, the paged tutorial carousel.

**Peak-end**: 5 designed peaks vs **8 missing** — the championship produces one news row and no
screen; season review, camp reveal, draft-pick verdicts, XP/level-ups, record breaks, injury blows,
and cap-crisis reassurance are all silent. **Sessions end on silence.**

**Personas' worst moments**: the Veteran taps the genre's most-requested feature and gets a replay
feed (see P0 below); the Commuter swipe-deletes a dynasty with no confirmation; the Low-Vision Fan
opens a player card where the only number that doesn't scale is the overall the screen exists for.

**New P0 (critique, missed by the audit's lens):** *"Call the Plays" contains no play-calling.* The
full game resolves in `play()` at `onAppear`; the live screen replays a finished result. The app's
subtitle is "Run the franchise. Call every down." The engine already steps snap-by-snap
(`f1f3e7f`); the UI never asks it to.

## 4. The Almanac system (replacement DESIGN.md, shipped in Phase A)

**Grounds.** Light: warm paper page + near-white card (exact hexes chosen in Phase A, verified by
the extended test suite before any view uses them). Dark: the current true-black page + `#1C1C1E`
card survive untouched — the night edition — keeping all 32 verified team-tint results. Ink is warm
near-black in light, warm off-white in dark. Zero shadows remains law.

**Type.** New York (system serif) for: mastheads, player names, record lines, edition plates, the
franchise wordmark. SF condensed caps for: labels, section chrome, table heads. SF tabular numerals
for every figure. All via text styles — the redesign deletes every hard-coded point size it touches.
Display moments use `largeTitle`/`title` with serif design, never `.system(size:)`.

**Rules, not cards-for-everything.** The almanac's primary separator is the printed rule: hairline
and heavy rules structure pages; cards demote to one job (the plate/edition and genuine groupings).
Chips demote from "every metadata token" to a small set of stamps (position, week, status). This is
the single biggest visible break from the reference formula.

**The rating ladder survives.** Five tiers, tier words, verified hexes, `.ratingStyle` — recolour
only if paper shifts a ratio below 4.5:1 (tests decide, not taste).

**Editions — the loud register.** One component family: full-bleed team-colour plate, oversized New
York display, heavy rules, `legibleOnDark`-style on-colour maths. The earned list (supersedes the
old six): **weekly front page (gameday state) · live game · final whistle · draft on-the-clock ·
season review · championship/commemorative · firing/cleared-desk.** Nothing else. The team-overview
gradient band and preseason hero — both unearned per critique — lose the register.

**Motion.** Paper-native: crossfades, rules drawing in, numerals rolling odometer-style, the ticker.
One shared `motionAware` modifier gates every animation on `accessibilityReduceMotion` — by
construction, closing the audit's zero-implementations finding class.

**Haptics.** A small grammar for gameday only (snap tick, tackle impact, whistle), silent elsewhere.

**Accessibility by construction.** The Phase A test suite extends `DesignSystemTests` to every
surface the audit found unmeasured (filled chips, tinted chips, plates, on-tint labels). Every new
component ships with a composed VoiceOver sentence and a 44pt floor. XXXL is a build gate per phase,
not an audit afterthought.

**Iconography.** SF Symbols only; the tab bar gets coach-native symbols (the Season tab currently
wears a basketball court — `sportscourt.fill`).

## 5. Phases

Order = (traffic × brokenness × identity payoff); Entry runs once so it goes last, built with the
finished system. Reorderable at approval.

Every phase follows CLAUDE.md process: expand with `writing-plans` at execution time → small
commits → adversarial review → build + tests + simulator demo (light and dark, XXXL) before close.
Engine-touching work (there is almost none — the live-game stepping is UI onto an existing engine
API) is TDD.

### Phase A — Foundation (no visible redesign yet)

*Look-independent audit fixes:*
- **P0** saves off the main actor (async, debounced; the open path stops double-parsing and
  rewriting) — `AppState.swift:164`, `SaveStore.swift:153`
- Error surfacing: `lastError` gets a UI (alert + inline row); load failure and save failure become
  visible, in voice ("Could not open this save. The file is unchanged.")
- Swipe-delete gets a confirmation naming the franchise and its seasons; `JobOffersSheet` gets a
  dismiss path
- Orientation policy declared (portrait app; arcade screen opts into landscape)
- `ArcadeGameView` dead code: deleted or wired behind a decision — resolved, not left
- A Settings surface exists (Light/Dark/System, the spec'd toggles)

*Foundation:*
- Almanac token layer in `DesignSystem.swift`: grounds, ink, rules, serif/condensed/numeral text
  roles, edition plate component, stamp (chip successor), ledger row, dossier line, ticker
- Extended contrast suite: every token × every surface it may sit on, both modes — green before any
  view adopts it
- `motionAware` modifier; haptic grammar stubs
- New `DESIGN.md` written; old one archived into it as anti-reference

**Gate:** all tests green including new suites; app runs unchanged visually except fixed errors/
settings; simulator demo of token gallery in both modes.

### Phase B — The Weekly Loop *(19/40, most-seen screen)*

The Season Hub becomes **the weekly front page**: masthead (week, record, phase), a lede — the
coordinator's sentence replacing the betting pills ("Three points better on paper. Their pass rush
is the argument.") — and the matchup as the page's story. Standings/Rankings/News become league
pages with printed rules; the playoff line is a drawn line through the table.

Structural changes (approval list):
- **Sim Week guarded** — it currently sims your own game unconfirmed beside Play [h5=1]
- **Schedule rows become navigable** — currently inert, no links to reports/previews [h7=1, echo]
- **Week-reveal ritual**: scores tick in as a two-second ticker ending on your game [peak-end]
- THIS WEEK card loses the broadcast register during the week; **flips to the front-page edition on
  gameday** [critique: register spent on the wrong card]
- Predictor maths moves to the engine (UI currently hand-rolls a logistic with a typed *e*) [P1]

Audit findings resolved by construction: raw-colour meaning text in the loop, hub token bypasses,
this cluster's VoiceOver sentences.

**Gate:** + a full simmed week demo; celebration of a win reaches the session's end.

### Phase C — Gameday *(the P0, and the register's proof)*

**Call the Plays becomes real.** The live screen drives the engine snap-by-snap: down/distance,
your call from a situation-grouped call sheet, resolution, consequence copy. Opponent possessions
are watchable (ticker + DC's call), not "the opposition has the ball." Win probability is the
coordinator's chart, annotated at swings. The final whistle is a full-screen edition in the
winner's colours — consequence-first copy, then the box score. The arcade keeps its mechanics,
re-chromed in almanac HUD (its 44pt work survives).

Structural: exit path from a live game (currently none; cancel slot hijacked) [P1]; quick-sim tiers
reachable mid-game.

**Gate:** + play a full game calling every down; lose one and read the edition; Reduce Motion pass.

### Phase D — Front Office & Draft *(most issues: 19)*

The cap becomes **the ledger**: current + future years (currently invisible) [P1], dead money as
"the receipts," over-cap states with the deadline sentence ("Clear $8.2M by cutdown — three
Fridays."). Free agency becomes narrated market days (the current CTA runs all three AI waves in
one tap) [P1]. Trades gain pick assets and a visible valuation (currently blind) [P1]. Draft day:
the on-the-clock edition, war-room verdicts on every pick from scouted-vs-revealed data, UDFA close.

**Gate:** + survive an offseason in the simulator demo; cap arithmetic property tests stay green.

### Phase E — Coach & Legacy *(the almanac's home turf)*

History as **tenure chapters with epitaphs**; records as living rivals ("Winslow's 1,889 — your man
is 214 short with 3 games left"); the firing gets the cleared-desk edition; job security speaks as
the owner, with its real thresholds legible [P1]; every RPG payoff (XP, level, goal, skill unlock)
gets its acknowledgment [peak-end ×3]. Skill tree redrawn as one annotated sheet. Job-offer trap
fixed in A; here it becomes an actual offer letter.

**Gate:** + a multi-season demo where a level-up, a record break, and a firing all visibly happen.

### Phase F — Team & Player *(best score; biggest emotional upside)*

The player card becomes **the dossier**: New York name, one-sentence generated scouting line, career
arc strip (currently one season of memory on a franchise card) [P1], provenance badges ("Your pick —
R1 2027"), next-man-up injury rows. Depth chart as the formation sheet; STARTER pills stop lying
about who starts [P1]; Auto-Sort gets an undo instead of an instant autosave [P1]. The unearned team
hero band is retired [audit + critique agree].

**Gate:** + cut a nine-season veteran and feel it; XXXL pass on the card (the 44pt number dies here
if it hasn't already).

### Phase G — Entry, Onboarding & the Seal

The menu becomes **your league's front page** (most recent save as a themed hero, one-tap continue)
[h7=2]. The wizard becomes the founding ritual: the theme flips the instant a team is tapped (the
proven payoff currently withheld until after onboarding); team choice gets decision support
(rating, cap-health word, situation tag — the spec's own doctrine, unimplemented) [h6=1]; Start
Franchise is signing the letterhead. Tutorial becomes the first day on the job, fed by the actual
generated season. Then the closing pass: `/impeccable polish` sweep, re-run `/impeccable audit` and
the critique, targets: audit ≥16/20, no cluster below 28/40, zero category-interchangeable verdicts.

**Gate:** the Definition-of-Done demo from `docs/00` — wizard → season → offseason → season 2 — in
the new world, both modes, XXXL, Reduce Motion.

## 6. Audit disposition

| Class | Count | Disposition |
|---|---|---|
| P0 main-actor saves | 1 | Phase A |
| Look-independent P1 (errors, orientation, traps, dead code) | 6 | Phase A |
| Contrast of old-skin components | ~20 | Superseded — components cease to exist; successors born verified |
| Token bypass (70+ literals) | ~8 findings | By construction per phase; new suite forbids regression |
| Dynamic Type / fixed frames | ~7 | By construction per phase; XXXL is a phase gate |
| VoiceOver / Reduce Motion classes | ~10 | Foundation modifier + per-phase sentences |
| Per-surface UX P1s | rest | Named in their phase above |
| Refuted (6) | — | Stay refuted; appendix in AUDIT.md prevents re-raising |

## 7. Process rules

- Execute **only on the owner's signal**, phase by phase; any session may run a phase but starts
  from fresh `main` and commits small and file-scoped (the concurrent arcade session is never swept)
- One phase = one `writing-plans` expansion at execution time; this document is the spec it expands
- Adversarial review closes every phase; findings fixed before the next opens
- `docs/04-SCREENS-UI.md` sections are marked "superseded by this plan §5.x" as phases land;
  `PRODUCT.md` never changes without a grilled decision

## 8. Open items (decided at execution, flagged now)

- Exact paper hexes (Phase A, test-driven)
- The 32-team geometric mark program (Phase F candidate; PRODUCT's no-image-assets rule holds — all
  code-drawn)
- Whether the arcade's "On the Field" mode adopts editions for its own touchdowns (Phase C decides
  with the register discipline)
- North Star name veto (§2)
