# 06 — Played-Game Mode ("On the Field")

Arcade on-field gameplay for user-played games, inspired by Retro Bowl's *feel* and the 2D
match-view convention of management sims (mechanics only — original art, names, layouts; see
legal note §9). Research basis: `01-RESEARCH.md` §G. This mode joins, not replaces, the existing
modes. **Revision 2 (all-22):** the abstract aim-and-throw view shipped in 4B is superseded by a
live all-22 2D field — every player on screen, moving, with the ratings driving what you see and
what your thumb can do. Build plan: `plans/2026-08-09-arcade-all22.md` (Phase 4C).

## 1. Three ways to play any game

| Mode | What it is | Who it's for |
|---|---|---|
| **Quick Sim** | Engine resolves everything (existing) | Season grinders |
| **Call the Plays** | Text/2D drive view, you call offense+defense playcalls, engine resolves (existing P4) | Strategy players |
| **On the Field** | You *control* offensive snaps, kicks, returns on a live all-22 field; defense = your playcall, watched in the same view (timed inputs 4C.3, one controlled defender v2) | Action players |

Choice made on the pre-game screen; switchable at halftime (downgrade only: Field → Plays → Sim).
All three feed the identical `GameRecord`/`StatLine` pipeline — box scores, stats, news, XP work
unchanged.

## 2. Design pillars (and where we beat the inspiration)

1. **One thumb, no menus between snaps.** Portrait, vertical field. Snap-to-whistle loop in
   seconds; full game 6–12 min.
2. **Ratings visibly matter in-hand** — openness windows, pocket life, throw projector, juke
   snappiness all read from existing attributes (§4). Upgrading your roster must *feel* different.
3. **The field tells the truth.** All 22 players are real positions computed from real ratings;
   the indicators never lie about the geometry, and the animation never contradicts the outcome
   the engine resolved (§5). No theatre.
4. **Fix the genre's three known complaints** (from Retro Bowl community research):
   - *"Defense is a dice-roll text box"* → defensive possessions render as watchable all-22
     resolution of your playcall (Base/Blitz/Nickel/Dime/Contain/Prevent) — skippable, tactical —
     then ramp to participatory: timed defensive inputs in 4C.3, a controlled defender in v2.
   - *"No real play-calling"* → full offensive playbook kept (Inside Run, Outside Run, Short
     Pass, Deep Pass, Play Action, Screen). Your call shapes the formation, routes and blocking
     you then execute. Audible = re-deal variation within the same call family.
   - *"Too easy / dumb difficulty"* → difficulty scales **defender reaction delay + closing-speed
     multiplier + AI coverage discipline**, never stat cheats. Dynamic difficulty option post-v1.
5. **Session parity with management layer:** injuries, fatigue, morale, coach skills all flow.

## 3. The all-22 field

**View:** portrait, top-down, you attack up-screen. Camera shows ~45 yards and follows the ball.
All 22 players are team-colored discs with position tags; ball is its own marker. The rest of the
app stays portrait too — nothing rotates (supersedes the landscape spec of revision 1; rationale
in `AUDIT.md` orientation findings).

**You control:** every offensive snap; FG/XP kicks; kick/punt returns; 2-pt attempts; go/kick/punt
choice. **Watched (not text):** your kickoffs/punts away, defensive plays (after your playcall),
OT coin toss.

**Per-snap flow (offense):**
1. Pick playcall (or the Suggested one — one tap; quality from OC rating). Pre-snap you see your
   formation, route stems, RB path, and the defensive front; QB `awareness ≥ 80` also reveals the
   coverage shell hint.
2. **Audible** re-deals the variation (routes/protection/QB depth). Audibles per game =
   1 + (QB awareness − 60)/10, clamped 1–4, +1 if OC rating ≥ 80 (§6).
3. Ball snaps on first input. Receivers run live routes against live coverage; each eligible
   target carries an **openness indicator** (§4). The pocket collapses visibly — rushers win
   their duels and converge; a sack-warning flash (lead time from QB awareness) precedes the hit.
4. From the pocket: **drag back = aim** the projector — dotted arc (visibility per accuracy), a
   **landing scatter ring** at the aim point (honest about the placement roll to come), throw
   distance capped by arm (§4); **release = throw**; second-finger tap toggles **lob ↔ bullet**;
   **drag forward = scramble** (QB becomes carrier, can slide); **tap RB ring = handoff**.
5. **Carrier control** (RB, WR after catch, scrambling QB, returner): auto-runs upfield at stat
   speed; **swipe left/right = juke** between lanes; **swipe up = dive** (guaranteed short lunge,
   ends play); **swipe down = stall** (let blocks form / bait divers; QB: slide). Stiff-arms
   auto-trigger from BreakTackle/Strength on contact. No sprint button — speed is a stat, not a
   reflex.
6. Run plays: blocking opens visible lanes (widths from line duels, §4); a suggested-lane
   highlight (quality from RB Vision) marks the crease; steer with jukes.
7. 4th down / end-half prompt: Go / FG / Punt with EV hint (quality gated by Fourth-Down
   Analytics coach skill).
8. **Kick meter** (carried over from 4B, unchanged): two taps — power bar, sweeping aim arrow;
   wind icon to aim against. Sweep speed ↓ with KickAccuracy, range from KickPower (max 66 yds),
   both degrade slightly late-game (fatigue).
9. Quarter/half/OT per league rules (`02` §4). Quick Sim sheet still available mid-game.

**Defensive possessions — the ramp:**

| Stage | What you do |
|---|---|
| 4C.1 (v1) | Call the defense, watch all 22 resolve it: outcome-conditioned choreography of the engine's resolved play, 2–3× speed, tap to skip, "watch full" replays at readable speed |
| 4C.3 | + timed inputs, each engine-checked and capped (§5): pre-snap **coverage shade** (boundary/field/deep/box), a **break-on-the-ball** tap in a timing window at the AI QB's release (centered = INT/PBU bonus; early = play-action vulnerability), a **commit-tackle** prompt on runs (fill the lane for a TFL vs. overrun your gap) |
| v2 | Control one defender (LB/S): your disc replaces his AI; proximity at the catch/contact points feeds the same capped modifiers |

**Returns:** catch, steer with jukes; swipe down inside your own end zone = touchback kneel.

## 4. Ratings → on-field mapping (existing attributes only — no new persistent stats)

| Attribute | In-hand effect |
|---|---|
| QB ThrowAccuracy | % of aiming arc rendered (100 → full dotted arc; 60 → last third invisible) + **scatter ring** radius 0.5 yd (99) → 2.5 yd (40), grown by throw distance (×1.0 ≤10 yd → ×1.6 at 30 yd) and pressure (×1.5 while collapsing) |
| QB ThrowPower | Max throw distance 18→32 yd + bullet flight speed (weak arms let deep windows close mid-flight) |
| QB Awareness | Indicator reveal latency 0.9 s (40) → 0.15 s (99); pre-snap coverage-shell hint (≥80); audible count; sack-warning flash lead 0.2–0.6 s |
| WR/TE/RB RouteRunning vs CB/S/LB Coverage | Live separation — route crispness and cut sharpness vs. coverage tightness. This duel *is* the openness indicator's input |
| WR/TE/RB Catch vs Coverage | Completion on imperfect placement; contested-catch roll on orange/red targets; drop/fumble floor |
| Speed / Agility | Disc movement speed / juke window & lane-change snappiness — for all 22, both sides |
| BreakTackle (+Strength) | Auto stiff-arm & broken-tackle roll on each contact event |
| OL PassBlock vs DL PassRush (per-matchup) | Each rusher's breakthrough time is a duel roll; pocket life = earliest breakthrough. Unit-level anchors preserved: 2.2 s mean (55 unit) → 4.5 s (90 unit). Blitzers rush sooner but vacate coverage — earlier green windows behind them |
| OL RunBlock vs DL/LB BlockShed | Visible lane widths on run plays; RB Vision sets suggested-lane highlight quality |
| DL/LB/CB/S ratings on your defense | Drive-sim inputs (engine) + how your watched defense moves; on offense they drive chaser quality: closing speed (Speed), reaction delay (Awareness, inverted), dive-tackle success (Tackle), coverage tightness (Coverage) |
| K/P Power+Accuracy | Meter range + arrow sweep speed + wind sensitivity |
| Morale | ±1 effective tier on Catch/Tackle at extremes (existing `02` §3 rule, surfaced here) |
| Injury status | Injured mid-game → next man up from depth chart, toast shown |
| **In-game fatigue** (transient, not persisted) | Heavy-usage carriers lose top speed late (recovers between drives; Iron Man halves, age > 30 amplifies). Resets postgame |
| Traits | Clutch (+3 effective OVR in Q4 one-score — affects scatter/speed/windows), Boom-Bust (scatter ×1.4 but big-play speed burst), others per `02` §3 |

**Openness indicator (honest colors, awareness sets timing):** each eligible receiver shows
green (**open**: separation ≥ 3.0 yd, not closing fast), orange (**maybe**: 1.5–3.0 yd, *or*
open but a defender is closing > 4 yd/s), red (**covered**: < 1.5 yd). Colors always tell the
truth about the geometry *right now* — a low-awareness QB never sees a false green; he sees the
truth **late** (reveal latency above), so reading the field yourself is how you play a bad
passer. Shape-coded as well as color-coded (solid / half / hollow ring) for color-blind players;
VoiceOver announces open/contested/covered.

Difficulty setting scales *only* defender reaction delay, closing multiplier, and AI coverage
discipline. Player-skill ceiling stays high; stats set the floor.

## 5. Outcome integrity & balance

- **Geometry grades, engine decides.** The spatial layer (`SnapKernel`, pure Swift in
  `FootballSimCore`) turns positions and input into *graded execution* — separation taken,
  placement error, release timing, pursuit beaten — fed through `PlayExecution`. Every
  probability lives in an engine formula; every roll draws from `League.rng`. The spatial layer
  never invents dice. The animation then renders what the engine resolved.
- **Reconciliation invariant (tested):** the play you watch ends exactly where the emitted
  `PlayEvent` says — spot, result, scorer. Choreographed plays (opponent drives, kicks away) are
  generated *from* the resolved event and cannot contradict it.
- **Skill ceiling — moderate (decided):** user execution can swing completion ±20 points, yards
  ±6, kick make ±18 points, defensive timed inputs ±10 points combined. All caps are named
  constants in `ArcadeTuning`. A sharp thumb meaningfully beats the sim with the same roster; a
  60-OVR QB still cannot play like a 90 — the roster remains the long game. (Supersedes 4B's
  ±12% ceilings.)
- **Scripted-thumbs soak (tested):** a perfect-input bot and a neutral-input bot each play
  hundreds of kernel snaps; the EV gap must sit inside the design band, and perfect play on a 90
  roster must beat perfect play on a 60 roster — stats floor verified, ceiling bounded.
- **Determinism:** `SnapKernel(players, calls, seed, InputTrace)` is a pure function — same
  inputs, same result — so the whole spatial layer is testable headless. Live user input breaks
  seed-reproducibility for played games by design; sim-only games remain fully deterministic.
- Arcade plays emit the same `PlayEvent`/`StatLine` records as engine plays; box scores stay
  consistent. **Calibration tests exclude user-played games** — manual play may outperform the
  sim (that's the fun). Counterweights: goals/job-security expectations don't scale down;
  difficulty setting; the records book flags nothing (a stat is a stat).
- Anti-degenerate guards: AI defense adapts within a game (repeat the same deep-pass call ≥4×
  successfully → coverage shades it, catch prob −8%); OT and clock rules identical across modes.

## 6. Coach, coordinators, meta hooks

- **Coach skill tree** (existing `02` §10) applies live: Offense/Defense unit nodes modify the
  same unit numbers the field reads; Explosive Plays widens the big-play tail on AI-resolved
  parts; Red-Zone Package tightens scatter inside the 20; Fourth-Down Analytics upgrades the
  Go/FG/Punt EV hint; Defense nodes strengthen your watched defense.
- **Coordinators (`02` §10):** OC rating adds +1 audible at ≥80 and raises Suggested-play
  quality; DC rating raises defensive playcall AI (when auto-called) and drive-sim strength; STC
  boosts return blocking + kick-meter forgiveness. Scheme mismatch halves these bonuses.
- **XP:** identical earn rates to Call-the-Plays mode (no farming incentive).

## 7. Presentation (original expression — inspired feel, distinct look)

- **Portrait everywhere.** The app locks portrait (per `AUDIT.md`); the field is vertical,
  top-down, camera follows the ball. One thumb reaches everything.
- **Tech: SwiftUI `Canvas` + `TimelineView`** — not SpriteKit. ~23 moving entities is trivial
  canvas load, it keeps the macOS compile-verification path alive, ships zero assets, and stays
  inside the app's existing rendering idiom. Logical sim ticks at a fixed 30 Hz decoupled from
  render; renderer interpolates.
- Our own modern-flat style: team-colored discs with position tags in **our palette**, our fonts
  (SF rounded scoreboard), soft shadows/gradients matching the app's card UI. No pixel-art
  pastiche, no scanlines, no faux-CRT framing — distinct from every inspiration.
- **Accessibility:** indicators shape-coded as well as colored; all interactive field states
  exposed to VoiceOver — the assistive path is the *watch + timed decisions* control variant with
  labeled buttons (target list with openness states, fight/secure), so the mode is fully playable
  without gestures. Reduce Motion: decorative motion (celebrations, ball-slide flourishes) stops;
  state changes present instantly.
- Sound: light original SFX (crowd swell, hit thud, whistle); haptics on catches/tackles/kicks.
  Mute respects silent switch.

## 8. Scope & phasing

- **Phase 4C**, three stages — plan with tasks, tests and constants:
  `docs/plans/2026-08-09-arcade-all22.md`. Stage 1: spatial substrate in `FootballSimCore`
  (TDD). Stage 2: renderer + offensive control, watchable defense, portrait lock + arcade audit
  fixes. Stage 3: defensive timed inputs.
- **v1 cut lines:** no steered defender post-snap (4C.3 timed inputs only — v2: control one
  defender), no weather, no dynamic difficulty, no zoom toggle, returns ON (not paywalled —
  genre complaint). Onside kicks exist as an engine playcall (`02` §4) — the kick itself is
  choreographed like other kicks away, recovery shown as animation. Call-the-Plays adopting the
  watch renderer is a v2 candidate (one renderer, three modes).
- **Audience positioning (from `01` §H):** the management-sim community explicitly does NOT ask
  for arcade play. On-the-Field targets the far larger casual arcade market instead. Therefore:
  never required, never advantaged in XP, Call-the-Plays and Quick Sim remain first-class, and
  the mode picker defaults to the player's last choice.
- **Gate (4C):** full game playable one-thumb in portrait; stat mapping verified by targeted
  kernel tests (99-accuracy scatter < 1 yd; 55-unit pocket < 2.5 s mean; indicator honesty
  invariant; reconciliation invariant; scripted-thumbs EV bands); box score equals event log;
  60 fps on A15; XP/injury/news parity with other modes; VoiceOver path playable end-to-end.

## 9. Legal guardrails (extends `01-RESEARCH.md` §F)

Reimplemented *mechanic ideas* (uncopyrightable): offense-only control, drag-aim + release
throw, lob/bullet toggle, lane-based jukes/dive/stall, auto stiff-arms, two-tap kick meter,
hybrid-play audibles, fatigue/morale dials, and the top-down dots-on-a-pitch match view — a
genre convention (Football Manager et al.). **Never copy:** "Retro Bowl"/New Star/"Football
Manager"/Sports Interactive marks, sprites, palette, fonts, animations, screen compositions,
sounds, team names, or any game's ensemble trade dress (no scanlines, no faux-CRT framing, no
FM UI skin — our palette, proportions, fonts). Fan-wiki text used for research is CC-BY-SA —
none of it ships in the app.
