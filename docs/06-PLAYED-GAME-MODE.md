# 06 — Played-Game Mode ("On the Field")

Arcade on-field play for user games. Mechanics research only from the genre (`docs/research/R1b`); all art, names, layouts, sounds, and framing are original (§9). This mode **joins, never replaces** the other two, and it is never required and never advantaged (OD-2, confirmed at gate 1).

## 1. Three ways to play any game

| Mode | What it is | Who it's for |
|---|---|---|
| **Quick Sim** | The engine resolves everything | Season grinders; the fast session |
| **Call the Plays** | You call offense *and* defense each down; engine resolves; text/2D play-by-play | The core strategy path — a hero surface (`04-SCREENS-UI.md` §6) |
| **On the Field** | You control offensive snaps, kicks, and returns; defense is your playcall plus fast animated resolution | The casual arcade audience — a different market than this community (R1b RB-34; `01-RESEARCH.md` §H) |

Chosen on the pre-game sheet; switchable at halftime downward only (Field → Plays → Sim). All three feed the identical `GameRecord` / `StatLine` / event pipeline — box scores, chronicle cards, records, and XP work unchanged. **One engine, one truth** is asserted by test (`03-ARCHITECTURE.md` §6.1).

## 2. Design pillars

1. **One thumb, no menus between snaps.** Snap-to-whistle in seconds; a full game inside the 8-minute budget (`PRODUCT.md` pillar 3).
2. **Ratings visibly matter in-hand.** Arc length, throw range, juke success, and pocket time all read from existing attributes (§4). Upgrading the roster must *feel* different.
3. **The simulated half shows its receipts.** Defensive possessions resolve with inspectable causality — your call, its effect, the box-score delta (`02-GAME-DESIGN.md` §4; RB-40). A five-star defense that fails must show why. This is the mode's single most important correction to the genre.
4. **Session parity.** Injuries, fatigue, morale, coach skills, promises, and the chronicle all flow through unchanged.

## 3. Control model

**You control:** every offensive snap; FG/XP kicks; kick and punt returns; two-point attempts; the go/kick/punt choice.
**Simulated (animated, never a bare text box):** your kickoffs and punts away, all defensive plays after your playcall, the OT toss.

Per-snap flow:
1. Pick a playcall, or accept the suggested one in a tap. Pre-snap shows routes, the back's path, and the defensive front; a QB with Awareness ≥80 also gets a coverage-shell hint.
2. **Audible** re-deals the play variation. Audibles per game = 1 + (QB Awareness − 60)/10, clamped 1–4, +1 with an OC rated ≥80.
3. Ball snaps on first input. From the pocket: **drag back to aim** (dotted landing arc), **release to throw**; a second-finger tap toggles lob ↔ bullet; **drag forward to scramble**; **tap the back's ring to hand off**.
4. **Carrier control** (RB, WR after the catch, scrambling QB, returner): auto-runs upfield at stat speed; **swipe up/down to cut between lanes**, **forward to dive** (guaranteed short lunge, ends the play), **back to stall**. Stiff-arms trigger automatically from BreakTackle/Strength. No sprint button — speed is a stat, not a reflex.
5. Pass rush is a timer (§4). Hold too long and the sack lands.
6. Fourth down and end-of-half surface the **StakesPanel**: Go / FG / Punt with **true engine percentages** (`02-GAME-DESIGN.md` §4 presentation contract — never a fudged or flattering number), plus the coach's recommendation whose quality scales with Fourth-Down Analytics.
7. **Kick meter:** two taps — power, then a sweeping aim arrow, with wind shown. Sweep speed falls with KickAccuracy; range comes from KickPower (max 66 yds); both degrade slightly late from fatigue.
8. Opponent possession: fast animated resolution (~3–8 s per drive, tap to skip, "watch full" replays at readable speed) — with the receipts of pillar 3 available on the drive.
9. Quarter/half/OT per `02-GAME-DESIGN.md` §4. Sim-with-takeover is available at any point (R1b RB-33).

Returns: catch, steer with cuts; swipe back inside your own end zone to kneel for the touchback.

## 4. Ratings → on-field mapping

Uses existing attributes only; adds no persistent stats.

| Attribute | In-hand effect |
|---|---|
| QB ThrowAccuracy | Share of the aiming arc rendered (100 → full; 60 → last third invisible) + landing scatter 0.5–2.5 yds |
| QB ThrowPower | Max distance 18→32 yds + bullet velocity |
| QB Awareness | Coverage hint (≥80), audible count, sack-warning timing |
| WR/TE/RB Catch | Completion on imperfect placement; contested-catch roll vs coverage; drop floor |
| RouteRunning | Separation quality vs coverage |
| Speed / Agility | Carrier and defender speed; cut window and lane-change snappiness |
| BreakTackle (+Strength) | Auto stiff-arm and broken-tackle odds on contact |
| OL PassBlock (unit) | Pocket timer 2.2 s (55 unit) → 4.5 s (90 unit); RunBlock opens lane width |
| DL/LB/CB/S ratings | Drive-sim inputs on defense; live chaser closing speed, reaction delay, tackle and coverage quality |
| K/P Power + Accuracy | Meter range, sweep speed, wind sensitivity |
| Morale | ±1 effective tier on Catch/Tackle at extremes |
| In-game fatigue (transient) | Heavy-usage carriers lose top speed late; recovers between drives; Iron Man halves it, age >30 amplifies |
| Traits | Clutch (+3 effective OVR in a one-score Q4), Boom-Bust (scatter ×1.4, big-play burst) |
| **Star ability** (90+ players) | The named ability's stated effect applies here exactly as in the sim, with the same visible counter (`02-GAME-DESIGN.md` §3) |

Difficulty scales **only** defender reaction delay, closing multiplier, and coverage discipline — never stat inflation (R1b RB-15).

## 5. Outcome integrity

- Arcade plays emit the same events, stat lines, and chronicle entries as engine plays.
- **Calibration bands exclude user-played games** — manual play may outperform the sim; that is the fun. Counterweights: owner goals and job security do not scale down, and difficulty is the dial.
- Determinism: player input necessarily breaks seed-reproducibility for played games. All non-input rolls still draw from `league.rng`, and sim-only games stay fully deterministic (`03-ARCHITECTURE.md` §6.1).
- Anti-degenerate guard: repeating a successful call ≥4× shades the coverage against it.

## 6. Presentation and feel

Primetime applies here in full (`DESIGN.md`) — this mode is not a visual exception:

- **ScoreStrip** is the same component, with occasion accent and identity chip.
- **Staging:** scores, finals, and records use the §2.3 grammar; the final-score staging is identical to the other modes.
- **Channels:** haptics on catches, hits, kicks and the meter; sound per the six-effect kit. `.championship` and `fanfare` remain tier-4 only.
- **Reduce Motion:** the field's ball motion, camera follow, and celebration motion all carry RM variants; meaning persists in sound, haptics, and text.
- **Accessibility is construction, not polish** — the v1 arcade shipped a bare drag gesture with no accessibility element, which made an entire advertised mode unplayable under VoiceOver. Required here: the field is a labeled element exposing situation as its value; each receiver is an element with a label; `accessibilityAction` entries throw to each receiver; the kick meter exposes label *and* value and announces the sweet spot; every control is ≥44×44pt.
- Original expression only: our marks, our palette, our type, our animations. No scanlines, no CRT framing, no borrowed trade dress.

## 7. Orientation

Landscape for this scene only; the rest of the app is portrait-locked. The scene requests its own geometry on appear and releases it on disappear — v1 declared three orientations globally and every portrait screen rotated into a broken layout (`docs/AUDIT.md`). The layout must survive rotation *and* iPhone SE height: the field is proportional, never a fixed 300pt block, and the control bar is laid out before the field takes the remainder.

## 8. Scope and phasing

- Its own phase in `05-IMPLEMENTATION-PLAN.md`, after the Call-the-Plays surface (whose event and box-score plumbing it renders) and after the witness layer exists.
- **Tech:** SpriteKit (`SKScene` in `SpriteView`) — native, zero dependencies. Arcade code lives in the UI target and *reads* engine types but never forks rules: situation state comes from the simulator's public state machine; the arcade resolves only the controlled play's outcome and feeds it back as an event.
- **Not in v1:** controllable post-snap defense, weather, dynamic difficulty. Returns are in, free.
- **Phase gate:** a full game playable one-thumb inside 8 minutes; the ratings-mapping table verified by targeted tests (99-accuracy QB scatter <1 yd; 55-unit OL pocket <2.5 s); box score equals the event log; 60 fps on an A15; portrait↔landscape transitions clean; VoiceOver playable end-to-end; parity of XP, injuries, and chronicle cards with the other modes.
- **Carried unknown:** the carrier-decision window (2.5 s pass / 3.5 s run) is an unvalidated guess — the tooling round trip is ~7 s against a live window of seconds, so only device play with a real thumb settles it. Tuning it is a gate item for this phase, not a design question (`07-SALVAGE.md` §D).

## 9. Legal guardrails

Reimplemented *mechanic ideas* (uncopyrightable): offense-only control, drag-aim and release, lob/bullet toggle, lane-based cuts, dive and stall, auto stiff-arms, the two-tap kick meter, hybrid-play audibles. **Never copied:** any real game's marks, sprites, palette, fonts, animations, screen compositions, sounds, team names, or the ensemble of its trade dress. Research material used to understand mechanics never ships in the app.
