# 06 — Played-Game Mode ("On the Field")

Arcade on-field gameplay for user-played games, inspired by Retro Bowl's *feel* (mechanics only — original art, names, layouts; see legal note §9). Research basis: `01-RESEARCH.md` §G. This mode joins, not replaces, the existing modes.

## 1. Three ways to play any game

| Mode | What it is | Who it's for |
|---|---|---|
| **Quick Sim** | Engine resolves everything (existing) | Season grinders |
| **Call the Plays** | Text/2D drive view, you call offense+defense playcalls, engine resolves (existing P4) | Strategy players |
| **On the Field** (new) | You *control* offensive snaps, kicks, returns arcade-style; defense = your playcall + fast animated resolution | Action players |

Choice made on the pre-game screen; switchable at halftime (downgrade only: Field → Plays → Sim). All three feed the identical `GameRecord`/`StatLine` pipeline — box scores, stats, news, XP work unchanged.

## 2. Design pillars (and where we beat the inspiration)

1. **One thumb, no menus between snaps.** Snap-to-whistle loop in seconds; full game 6–12 min.
2. **Ratings visibly matter in-hand** — arc length, throw range, juke success, pocket time all read from our existing attributes (§4). Upgrading your roster must *feel* different.
3. **Fix the genre's three known complaints** (from Retro Bowl community research):
   - *"Defense is a dice-roll text box"* → our defensive possessions render as fast animated 2D resolution in the same field view, driven by your defensive playcall (Base/Blitz/Nickel/Dime/Contain/Prevent) — watchable, skippable, tactical.
   - *"No real play-calling"* → we keep our full offensive playbook (Inside Run, Outside Run, Short Pass, Deep Pass, Play Action, Screen). Your call shapes the routes/blocking you then execute. Audible = re-deal variation within the same call family.
   - *"Too easy / dumb difficulty"* → difficulty scales **defender reaction delay + closing-speed multiplier + AI coverage quality**, not stat cheats. Dynamic difficulty option post-v1.
4. **Session parity with management layer:** injuries, fatigue, morale, coach skills all flow through.

## 3. On-field control model

**You control:** every offensive snap; FG/XP kicks; kick/punt returns; 2-pt attempts; go/kick/punt choice.
**Simulated (animated, not text):** your kickoffs/punts away, all defensive plays (after your playcall), OT coin toss.

**Per-snap flow:**
1. Pick playcall (or accept the Suggested one — one tap). Pre-snap you see routes + RB path + defensive front; QB `awareness ≥ 80` also reveals coverage shell hint.
2. **Audible** button re-deals the play variation (routes/protection/QB depth). Audibles per game = 1 + (QB awareness − 60)/10, clamped 1–4, +1 if OC rating ≥ 80 (§6).
3. Ball snaps on first input. From the pocket: **drag back = aim** (dotted landing-spot arc, length/visibility per §4), **release = throw**; second-finger tap while aiming toggles **lob ↔ bullet**; **drag forward = scramble** (QB becomes carrier, can slide); **tap RB ring = handoff**.
4. **Carrier control** (RB, WR after catch, scrambling QB, returner): auto-runs upfield at stat speed; **swipe up/down = juke** between lanes; **swipe forward = dive** (guaranteed short lunge, ends play); **swipe back = stall** (let blocks form / bait divers). Stiff-arms auto-trigger from BreakTackle/Strength on contact. No sprint button — speed is a stat, not a reflex.
5. Pass rush is a timer (§4 OL) — hold too long, sack animation.
6. 4th down / end-half prompt: Go / FG / Punt with EV hint (hint quality gated by coach skill Fourth-Down Analytics).
7. **Kick meter:** two taps — power bar fill, then sweeping aim arrow; wind icon shows direction/strength to aim against. Sweep speed ↓ with KickAccuracy, range from KickPower (max 66 yds), both degrade slightly late-game (fatigue).
8. Opponent possession: animated fast-forward resolution (~3–8 s per drive, tap to skip; "watch full" option replays play-by-play at readable speed). Uses the P2 engine verbatim — the arcade layer is presentation only here.
9. Quarter/half/OT per league rules (`02` §4). Quick Sim sheet still available mid-game (sim to possession/quarter/half/end — hands the rest to the engine).

**Returns:** catch, steer with jukes; swipe back inside your end zone = touchback kneel.

## 4. Ratings → on-field mapping (uses existing attributes only — no new persistent stats)

| Attribute | In-hand effect |
|---|---|
| QB ThrowAccuracy | % of aiming arc rendered (100 → full dotted arc; 60 → last third invisible) + landing scatter radius (0.5–2.5 yd) |
| QB ThrowPower | Max throw distance 18→32 yd + bullet velocity |
| QB Awareness | Coverage hint pre-snap (≥80), audible count, sack-warning flash timing |
| WR/TE/RB Catch | Completion prob on imperfect placement; contested-catch roll vs DB Coverage; drop/fumble floor |
| RouteRunning | AI separation quality vs coverage (route crispness, cut timing) |
| Speed / Agility | Carrier + defender movement speed / juke window & lane-change snappiness |
| BreakTackle (+Strength) | Auto stiff-arm & broken-tackle probability on contact |
| OL PassBlock (unit) | Pocket timer: 2.2 s (55 unit) → 4.5 s (90 unit) before rush arrives; RunBlock opens lane width on run plays |
| DL/LB/CB/S ratings | Drive-sim inputs on defense (engine) + live chaser quality when you have the ball: closing speed (Speed), reaction delay (Awareness, inverted), dive-tackle success (Tackle), coverage tightness (Coverage) |
| K/P Power+Accuracy | Meter range + arrow sweep speed + wind sensitivity |
| Morale | ±1 effective tier on Catch/Tackle at extremes (existing `02` §3 rule, surfaced here) |
| Injury status | Injured mid-game → next man up from depth chart, toast shown |
| **In-game fatigue** (transient, not persisted) | Heavy-usage carriers lose top speed late (recovers between drives; Iron Man trait halves, age > 30 amplifies). Resets postgame — season condition is handled by existing injury/morale systems |
| Traits | Clutch (+3 effective OVR in Q4 one-score, existing rule — affects arc/scatter/speed), Boom-Bust (scatter ×1.4 but big-play speed burst), others per `02` §3 |

Difficulty setting scales *only* defender reaction delay, closing multiplier, and AI coverage discipline. Player-skill ceiling stays high; stats set the floor.

## 5. Outcome integrity & balance

- Arcade plays emit the same `PlayEvent`/`StatLine` records as engine plays; box scores stay consistent (P4 gate logic reused).
- **Calibration tests exclude user-played games** — manual play is allowed to outperform the sim (that's the fun). Counterweights: goals/job-security expectations don't scale down; difficulty setting; records book flags nothing (a stat is a stat).
- Determinism: user input breaks seed-reproducibility for played games by design; `League.rng` still drives all non-input rolls, and sim-only games remain fully deterministic.
- Anti-degenerate guards: AI defense adapts within a game (repeat the same deep-pass call ≥4× successfully → coverage shades it, catch prob −8%); OT and clock rules identical across modes.

## 6. Coach, coordinators, meta hooks

- **Coach skill tree** (existing `02` §10) applies live: Offense/Defense unit nodes modify the same unit numbers the arcade reads; Explosive Plays widens the big-play tail on AI-resolved parts; Red-Zone Package tightens scatter inside the 20; Fourth-Down Analytics upgrades the Go/FG/Punt EV hint; Defense nodes strengthen your simulated defense.
- **Coordinators (v1-light staff system — added to `02` §10):** OC rating adds +1 audible at ≥80 and raises Suggested-play quality on offense; DC rating raises defensive playcall AI (when you let it auto-call) and drive-sim strength; STC boosts return blocking + kick meter forgiveness. Scheme mismatch halves these bonuses.
- **XP:** identical earn rates to Call-the-Plays mode (no farming incentive); playing a full game on the field grants the same per-win/goal XP.

## 7. Presentation (original expression — inspired feel, distinct look)

- **Landscape** during On-the-Field games only (rotate prompt; rest of app stays portrait). Side-scrolling 2D field, camera follows ball, optional zoom toggle.
- Our own pixel style: chunky readable sprites in **team colors from our palette**, distinct proportions/palette from any existing game, our own fonts (SF rounded scoreboard), our own animations and celebration vignettes. No scanline filter (their signature), no 8-bit-era framing — we skew "modern flat-pixel": crisp shapes, soft shadows, team-color gradients matching the app's card UI so the mode still feels like *our* app.
- Sound: light original SFX (crowd swell, hit thud, whistle); haptics on catches/tackles/kicks. Mute respects silent switch.
- Sim-resolution of opponent drives shows mini play animations + ticker line, not bare text boxes.

## 8. Scope & phasing

- New **Phase 4B** in `05-IMPLEMENTATION-PLAN.md`, after P4 (Call-the-Plays UI) and before P5. P4 ships first because its engine streaming + box-score plumbing is the substrate 4B renders.
- **Tech:** SpriteKit (`SKScene` in `SpriteView`) — native, zero dependencies, fine at this sprite count. Arcade logic lives in the app target (`Features/OnTheField/`), *reads* engine types but never forks rules: shared situation state (`down/distance/clock/score`) comes from `GameSimulator`'s public state machine; arcade resolves only the controlled play's outcome and feeds it back as a `PlayEvent`.
- **v1 cut lines:** no controllable defense post-snap (playcall only — v2 candidate: control one defender), no weather, no dynamic difficulty, returns ON (not paywalled — genre complaint). Onside kicks exist as an engine playcall (`02` §4) and work in all modes — in On-the-Field the kick itself is simulated like other kickoffs-away, recovery shown as animation.
- **Audience positioning (from `01` §H):** the management-sim community explicitly does NOT ask for arcade play — they want coach-brain control and trustworthy outcomes. On-the-Field targets the far larger casual arcade market instead. Therefore: never required, never advantaged in XP, Call-the-Plays and Quick Sim remain first-class paths, and the mode picker defaults to the player's last choice, not to arcade.
- **Gate (4B):** full game playable one-thumb; stat mapping table verified by targeted tests (e.g. 99-accuracy QB scatter < 1 yd, 55-OL pocket < 2.5 s); box score equals event log; 60 fps on A15; landscape↔portrait transitions clean; XP/injury/news parity with other modes.

## 9. Legal guardrails (extends `01-RESEARCH.md` §F)

Reimplemented *mechanic ideas* (uncopyrightable): offense-only control, drag-aim + release throw, lob/bullet toggle, lane-based jukes/dive/stall, auto stiff-arms, two-tap kick meter, hybrid-play audibles, fatigue/morale dials. **Never copy:** "Retro Bowl"/New Star marks, sprites, palette, fonts, animations, screen compositions, sounds, team names, or the ensemble of its 1987-era trade dress (no scanlines, no faux-CRT framing, distinct palette/proportions). Fan-wiki text used for research is CC-BY-SA — none of it ships in the app.
