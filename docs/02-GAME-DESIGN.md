# 02 — Game Design Document: Pro Football Coach (rebuild canon)

The gameplay source of truth for the hybrid rebuild. UI belongs in `04-SCREENS-UI.md`; code shape in `03-ARCHITECTURE.md`; feel and staging in `DESIGN.md`. Every tunable number lands in `LeagueRules.swift` as a named constant. Every system traces to `docs/research/` findings, the R2 rulings/pillars, the locked design system, or is marked `NOVEL`.

**Parity rule (R2 T8):** v1's validated mechanics are the floor. Systems marked *(v1, carried)* survive with their rules intact and re-earn their tests in the new engine; systems marked *(new)* are the rebuild's additions. Nothing is removed — the removal ledger is the genre's deepest grievance (MAD-19).

## 1. Vision & pillars

Run a pro football franchise for decades: call the plays on Sunday, run the front office all week — and have the league narrate it back to you. Text-first sim: depth over graphics, sessions in minutes, dynasties over years.

The six Experience Pillars in `PRODUCT.md` are binding on every system here (falsifiable tests in `R2-synthesis.md` §4): every advance lands a story · nothing pays in silence · the advance is faster than doubt · numbers are staged, never dumped · every number has a face · losing opens a chapter.

## 2. League structure *(v1, carried)*

- **32 fictional teams**, 2 conferences × 4 divisions × 4:

| Liberty Conference | Frontier Conference |
|---|---|
| **East:** New York Empire, Boston Harbormen, Philadelphia Founders, Washington Sentinels | **East:** Baltimore Admirals, Cincinnati Riverhawks, Indianapolis Racers, Nashville Rhythm |
| **North:** Chicago Blizzard, Detroit Motors, Cleveland Forge, Pittsburgh Ironmen | **North:** Minneapolis Loons, Milwaukee Barons, Denver Summit, Salt Lake Peaks |
| **South:** Miami Tides, Atlanta Firebirds, Charlotte Aviators, New Orleans Revelers | **South:** Phoenix Scorchers, San Antonio Defenders, Las Vegas Highrollers, Oklahoma City Twisters |
| **West:** Dallas Lonestars, Houston Wildcatters, Kansas City Stampede, St. Louis Archers | **West:** Los Angeles Stars, San Diego Armada, San Francisco Fog, Seattle Evergreens |

Each team: city, name, 3-letter abbrev, primary/secondary colors, geometric mark, stadium name, AI GM personality (`winNow / balanced / rebuilder / capHawk`), owner patience (1–5), franchise **Reputation 1–100**.

- **Schedule (17 games / 18 weeks + bye)** — v1 formula unchanged. Preseason: 3 optional games.
- **Playoffs:** default 14-team (7 seeds/conference, #1 bye, reseed); 12/16 options. **Continental Championship** at a neutral site.
- **Tiebreakers (ordered):** head-to-head → division record → conference record → points for.
- **Occasion derivation** *(new — DESIGN.md §2.7; MAD-04)*: each week, every game gets an occasion tier computed from schedule facts — division rival; **marquee** = the league's game of the week (highest combined standings stakes, rivalry weighting, late-season tiebreak drama); playoffs; championship. Presentation-only; no scheduling mechanics change.

## 3. Players

### Core model *(v1, carried)*

Positions & roster template (53 + 16 PS): QB3 RB4 WR6 TE3 OL9 DL8 LB7 CB6 S5 K1 P1 targets; min 1 per position at cutdown. Identity: generated name, age 21–40, height/weight, college (independently generated fictional bank — clean-room rule: no name sourced from or matching the reference app), draft origin, jersey #, seeded avatar mark. Attributes 40–99 (core Speed/Strength/Agility/Awareness + position sets, v1 tables); OVR per-position weighted mean; Potential letter A+…F (hidden ceiling + speed multiplier), scouting-fogged for prospects. Traits (0–2 per player, 25% of players): Clutch, Injury Prone, Iron Man, Locker-room Leader, Mercenary, Loyal, Late Bloomer, Boom-Bust. Morale 0–100 with the v1 inputs and effects. Age curves, injuries, retirement probability — v1 rules.

**Progression causality law** *(new — MAD-23/MAD-47 avoid-ruling)*: player development flows from potential, age curves, camp events, and coaching boosts — never from box-score accumulation. No stat-farmable XP exists anywhere in the player model. (Coach XP §10 rewards outcomes — wins, goals — which are not per-player farmable stats.)

### The attachment layer *(new)*

- **Career ledger** — every player carries a permanent, append-only career record: season lines, transactions, injuries, awards, records, milestone events. Survives trades, cuts, retirement (feeds HoF). The ledger is a UI surface (player card), not just data (Pillar P5; FM-04→R1c §7.4, ADJ-44 permanence).
- **Featured players** *(NOVEL shape; RB-41, ADJ-44 attention budget)* — per team, a small foreground set (default 5: the stars and the storyline carriers) whose events get full narrative treatment: arcs, fragility events, press dilemmas, milestone staging. Background players resolve with standard cards. Featured membership is dynamic (breakouts promote, decline demotes) and derived, never hand-picked by the sim in a way the player can't audit.
- **Star abilities** *(new — MAD-13 bounded by MAD-39)*: players rated 90+ (Elite tier) carry one named, binary ability with a visible activation condition and a visible counter (e.g. *Deep Threat — active when single-covered: deep-pass completion +8% · countered by Contain/Prevent shells*). Effects are small, sim-plausible, auditable in the box score, and identical for AI teams. No hidden modifiers; the ability line appears on the player card and in matchup previews (fear-the-star legibility without superhero guarantees).
- **Fragility & discipline events** *(new — RB-06)*: featured players roll rare condition/discipline events (missed practice, contract gripe, minor injury flare) that arrive as decision cards with tradeoffs (rest him vs play him; fine him vs talk). Consequences proportional, telegraphed, never trolling (ADJ-44 trust rules).
- **Wonderkid hype** *(new — FM-33/FM-34/FM-37)*: each draft class generates 2–4 hyped prospects (media darlings). Hype is a public prediction the save later grades — the bust and the steal are both stories (ties to engineered steals/busts, §8).
- **Retirement arcs** *(new — RB-19 avoid-ruling)*: decline is telegraphed across seasons (ledger trend, camp arrows, beat-writer notes); a farewell arc (final-season framing, retirement card, HoF countdown) replaces rug-pull exits.

## 4. Game simulation *(v1 mechanics carried; presentation contract new)*

Loop, play resolution, units, clock, penalties, 4th-down EV, playcalls (offense 6 + situational; defense 6 + Hands Team; tempo), sequencing-correctness requirements, OT rules, injuries in-game, Player of the Game, box scores, drive log — all v1 rules unchanged. **Calibration and believability bands are unchanged and restated as engine acceptance specs in `03-ARCHITECTURE.md`** (source: `docs/STATUS.md`; includes mode parity — one engine, one truth).

**Presentation contract** *(new — binding on any UI over the sim)*:
- **Honest odds (R2 T5):** every probability shown is the true engine probability. Randomness sits upstream (matchup tables, noise mixtures), never as a visible last-step coin flip. FG%, 4th-down EV, interest meters, acceptance odds — all true numbers.
- **StakesPanel data:** every risk decision (4th down, deep shot vs blitz look, trade verdict, onside) exposes its options with true percentages before resolution (ADJ-34).
- **Win probability:** computed per play; surfaced only as retrospective swing charts (half, final) and never as an always-on live figure (ADJ-36).
- **Simulated-phase receipts (RB-40):** any phase resolved without player input — defensive drives, AI games — produces inspectable causality: drive log with the defensive playcall's effect, box-score deltas, coordinator postmortem line ("Blitz picked up twice; Cover-2 held the deep ball"). A 5-star defense that fails must show *why*.
- **Staging:** headline numbers resolve per `DESIGN.md` §2.3 specs. Final-score, record, and award staging are sim-triggered events, not UI improvisation.

## 5. Season calendar

Structure *(v1, carried)*: Preseason (3 wks, optional) → Weeks 1–18 (trade deadline end of Wk 9, weekly awards, power rankings, injuries heal) → Playoffs → the ten offseason stages in v1 order (Review → Carousel → Retirements → Re-sign → Tag → FA waves → Draft → Camp → Cutdown → Preseason).

**The two-beat week** *(new — R2 T7)*: every regular-season week has two stops, each a real session:
1. **Midweek beat:** injury report; **gameplan ritual** — opponent tendency card → focus pick with explicit pros AND cons → practice intensity/reps tradeoff (development vs fatigue/injury risk) (MAD-08/MAD-09/MAD-43: every step a tradeoff, nothing pure-reward); a press dilemma when one is queued (§11).
2. **Gameday beat:** play/sim the game → aftermath cards (result staging, consequence cards, hook updates).
Advancing collapses both beats gracefully for fast sessions — a single advance plays midweek defaults and sims, still landing all cards (Pillar P3; blocking rules §11).

**Interleaved horizons** *(new — ADJ-29)*: contract years, development arcs, record chases, milestone counters, draft positioning, and job security are scheduled so that at every week, at least one hook is ≤3 weeks from resolution (Pillar P1's soak-tested guarantee).

## 6. Salary cap & contracts *(v1, carried)*

Cap $260M year 1, +5–8%/yr seeded; all 53 + PS count. Contract model (years, salary array, prorated signing bonus, guarantees), dead money acceleration, rookie scale (slotted, 4 yrs + R1 option), minimum salaries, practice-squad stipends and the no-cap-laundering rules, re-sign ask model, negotiation (3 rounds, accept-probability meter — true odds), AI cap floor ≥89% over 3 years. All unchanged.

**Promises** *(new — MAD-10/MAD-45 grammar)*: negotiations and press moments can create recorded commitments (role, contention, extension timing). A promise persists visibly (hooks rail), and breaking it lands a delayed morale/trust consequence with real downside. Promise volume is scarce — at most a handful active per season — so each one binds.

## 7. Free agency *(v1, carried)*

Three waves, interest meter (money 55 / contender 20 / role 15 / reputation 10, trait skews — true numbers shown), losing-bid news, in-season street FA with explicit refusal reasons. Unchanged.

## 8. Draft & scouting *(v1, carried + graded predictions)*

Class generation (224 + UDFA, engineered steals ~6 and busts ~5), scouting fog (OVR ranges ±8), scouting points economy, draft order, AI pick logic, pick trades with value chart, UDFA — unchanged.

- **Graded predictions** *(new — R1c §7.3, FM-38)*: every scout report is a recorded prediction (range, potential read, comparison line). Post-hoc, the save grades them — a scouting accuracy ledger accumulates ("Your board hit on 7 of 11 top-100 calls"). Expertise becomes provable inside the sandbox; the offline substitute for FM's real-world validation.
- **Draft night** *(new staging — MAD-45, FM-08)*: draft day is the season's Christmas — full occasion treatment, pick-reveal staging (DESIGN §2.3), war-room grade toasts, hyped-prospect fall/rise cards. Systems unchanged; the event is staged.

## 9. Trades *(v1, carried)*

Value model, personality-adjusted acceptance (105% band), counter-offers, deadline, AI-to-AI trades, cap/roster legality both sides. Unchanged. Trade verdicts show true value numbers (T5); accepted blockbusters are league-news stories with faces (§11).

## 10. Coach RPG & staff *(v1, carried)*

Coordinators (OC/DC/STC: ratings, schemes, traits, budget, poaching pipeline), coach XP (wins/goals/playoffs — outcome-based, not stat-farmable), levels, 4 skill trees (Scouting/Development/Offense/Defense, v1 nodes), coach finances, job security, seasonal owner goals, retire→legacy. Unchanged.

**No-dead-end invariant** *(v1, carried — now also a presentation requirement, Pillar P6)*: the carousel always yields ≥1 offer or an explicit sit-out-a-year arc. The rebuild adds: every failure state is *announced as a chapter* — hot-seat arc cards, firing aftermath card naming the next path, rebuild-mode framing for bad rosters. Losing opens a chapter, never a dead end (ADJ-39/45; community complaint #2).

## 11. The witness layer *(new — the rebuild's core addition)*

Replaces v1's "news engine" section. One pipe: everything the sim does that the player should feel arrives as a card in the feed. Laws:

- **Consequence-with-story (ADJ-43):** no event ships without its visible arc — cause, effect, and what it sets up. If the arc can't be shown, the event doesn't fire.
- **Not severable (ADJ-03):** the witness layer has no off-switch. It is the game, not a feature flag.
- **Salience over volume (ADJ-42, FM-13):** the feed lands 3–7 salient cards per week, selected from all engine events by a salience score (player-team relevance, featured-player involvement, magnitude, hook advancement, rarity) — never a firehose. League-wide filler exists one tap deeper (league news list), not in the feed.
- **Blocking (OD-3):** a card blocks the advance only when its decision has deadline semantics. Everything else never interrupts.
- **Faces (Pillar P5):** every card names a person.

**Card sources:** game results and staging events (§4) · injuries and windows · development (camp arrows, breakouts, declines) · cap/contract consequences · promises and their outcomes · fragility/discipline events (§3) · press dilemmas · milestone and record chases · hooks resolving · league news (AI signings, firings, trades, races) · draft/FA/carousel events in phase.

**Press dilemmas** *(RB-07)*: occasional one-tap choices routing one scarce boost among stakeholders (star's morale / locker room / fans / owner patience). Mutually exclusive, so every answer is a real allocation. At most one queued per week; never blocking.

**Hooks rail:** the visible set of active storylines with countdowns (contract deadlines, record paces, streaks, hot seat, promise clocks, milestone watches). Always ≥1 hook within 3 weeks of resolving (Pillar P1); resolved hooks take their outcome accent and land a card.

**The five broadcast slots** *(MAD-42-anatomy via R1a §7; MAD-03/09/41)*:
1. **Pregame card** — matchup framing, key duel, prediction chip, occasion identity.
2. **In-game lines** — press-voice situational narration in the drive log.
3. **Halftime** — replay-your-half: 2–3 staged highlight lines from *your actual half* + swing chart.
4. **Postgame verdict** — result staging, Player of the Game, columnist's one-liner.
5. **The Weekly** — the league show: narrated evidence of games you didn't play (top performances, races, upsets — every simmed week produces openable league evidence: the "league feels alive" test, MAD-41). Phase-aware editorial: openers, streaks, clinching, playoff stakes.

**Voices:** 3 named fictional press personas (beat writer / columnist / radio desk) with distinct registers (DESIGN §3, OD-1). Templates are cast by salience with personality re-voicing where cheap; v1 floor is salience-matched templates (OD-4; ADJ-48). **Template pool sizing is a gate-3 input:** the pool must pass a 10-season soak without perceptual repetition on standout events (ADJ-47 oatmeal bar; MAD-14's two-season staleness clock is the failure precedent).

**Permanence surfaces** *(v1 records/HoF/archive carried + new)*: records book with live chases, Hall of Fame, previous-seasons archive, career ledgers (§3) — plus **season retrospective**: at season end, a staged recap (record, road, star ledger lines, what's next) exportable as a local image/text artifact (ADJ-46; no network).

**Challenge templates** *(new — FM-34)*: named long-horizon challenges selectable at franchise creation or adopted mid-save (Dynasty: 3 titles in 5 years · Homegrown: title with ≥80% drafted roster · The Long Rebuild: worst roster to champion). Tracked progress chip; completion enters the trophy room.

## 12. Scenarios *(v1, carried — exactly three)*

Cap Hell · Expansion Franchise · Aging Legend, with v1 parameters (Cap Hell: −$38M effective space next year). Config-driven, no bespoke engine paths. ("Draft King" from old 04 is backlog, not v1.)

## 13. Difficulty & settings *(v1, carried + amendments)*

Trade difficulty, owner patience, firing toggle, injuries toggle, playoff format, tag toggle, confirm-advance, injury popups, tutorial replay. Amendments *(new)*: difficulty never uniform-inflates opponent ratings (RB-15) — harder settings sharpen AI decision quality and economy pressure; **AI teams rebuild credibly across a decade** (ADJ-08 avoid-ruling — a tested invariant: year-10 league quality distribution matches year-1 bands); prediction display setting (spread ↔ win% chip); haptics toggle; SFX mute (DESIGN §2.4/2.5); Reduce Motion honored via DESIGN variants (system setting, no in-app toggle needed).

## 14. Explicitly out of v1 (ordered backlog)

Custom league editor + JSON import/export (v1.5 — data model ready day one) · in-app community league browser · weather · compensatory picks · in-season IR/designated return · restructures/June-1 cuts · position coaches & staff trees · coordinator career mode · controllable post-snap defense · dynamic difficulty · per-player usage sliders · social-style reacting feed and AI press conferences beyond §11's dilemmas (FM-13: high-volume media is the documented failure; §11's scarce-consequential model is the v1 answer) · multiplayer/Game Center beyond basics · expansion drafts · relocation · Wildermyth-style casting engine for templates (OD-4, gate-3 decision). Monetization if ever: editor + scenario packs, never ads, never paid crash insurance.
