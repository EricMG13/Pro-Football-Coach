# 05 — Implementation Plan

Phased build for the rebuild. Each phase is independently shippable to TestFlight quality and closes on its gates — **every phase gate is a hard stop; a phase does not close with an unmet gate.**

Expand each phase into a task plan with `superpowers:writing-plans` before starting it; save to `docs/plans/`. One task, one commit.

## Universal gates (every phase, no exceptions)

1. **Build green.** `swift build` succeeds.
2. **Tests green.** `swift run SimTests` passes, including every acceptance spec in `03-ARCHITECTURE.md` §6 that the phase has reached.
3. **Craft gate.** Every surface the phase touched re-audits at **≥17/20 with zero P0/P1** against the `/impeccable audit` rubric (baseline 9/20). This is how craft debt is actually paid.
4. **Cold-play gate.** One uninstructed hour actually playing what exists, asking only: is this fun, and does it pull? This instrument exists because milestone tracking historically missed a dead build until far too late (R1c FM-27).
5. **Session budgets timed** (`03` §6.6): fast session ≤3 min one-handed, played game ≤8 min, interstitial ≤1 min, gameplan sheet ≤60 s — whichever the phase has built.
6. **Parity ledger checked** (`07-SALVAGE.md`): nothing v1 shipped has silently disappeared.
7. **Adversarial review** on the phase diff; confirmed findings fixed before the phase closes.
8. **Demonstrated in the simulator.** Not described — demonstrated.
9. **Doc-first honoured:** no rule was implemented that canon does not state.

Engine phases additionally gate on: **calibration bands** (§6.2), **believability bands** (§6.3), **cap invariants** (§6.4), **cross-process determinism** (§6.1), and **the ten-season soak** (§6.5).

---

## P0 — Foundation

Repo housekeeping and the harness the rest depends on.

- Delete the nested duplicate `Pro-Football-Coach/` directory (an old doc copy, not code).
- Test harness with **self-registering suites** — v1's hand-listed `main.swift` lets a written-but-unlisted suite pass by never running. Prefer swift-testing where the toolchain provides it; keep the hand-rolled harness only as the documented fallback.
- The two source scanners from `03` §6.1, each with a self-test that fails on a planted offender: no `.hashValue` seeding (comment-stripped, unlike v1's), and no `UUID()`/`Date()` as argument or assignment in `Engine/`/`Generation/`.
- CI-shaped script that runs build + tests + scanners in one command.

**Gate:** universal 1–2, 7–9. A planted offender fails each scanner.

## P1 — Model, RNG, generation

- `SeededRandom` ported verbatim (S-01) **plus the missing coverage its own suite never had**: `seed(from:)` order-sensitivity and cross-process stability; `uuid()` reproducibility, RFC-4122 correctness, non-repetition.
- Core model per `03` §3 — including the new fields (`chronicle`, `hooks`, `promises`, `ledgers`, `gameplans`, `tendencies`, `featured`, `scoutReports`, `challenges`).
- `LeagueRules` constants and tables (S-02), `PlayMatrix` (S-03), the 32-club table from `02` §2.
- Generation: `LeagueFactory`, `PlayerFactory`, `NameBank` with the **duplicate-name guard** (S-10 amendment 2).
- Save round-trip: `Codable`, stable encoding (S-04), byte-identical re-encode.

**Gate:** universal + a generated league is legal (53-man rosters, position minimums, cap-legal, no duplicate full names); cross-process determinism holds; club primaries all clear 4.5:1 against white and secondaries clear their own primaries (S-12).

## P2 — Game engine

- `GameSimulator` and the play-resolution stack, stepwise (`advance` resolves one snap or transition).
- Box scores, stat lines, drive log.
- **Every engine mutation emits `LeagueEvent`s with mandatory causes** (`03` §5.1) — built in from the first play, not retrofitted.

**Gate:** universal + full engine acceptance set: calibration bands, believability bands, mode parity (`retainPlays` cannot change a result), determinism, the ratings-predictiveness test **with its ≥12 OVR precondition actually asserted**, and the end-of-game state machine exhaustively tested (0:00 edge cases, kneel-outs, untimed downs after a defensive penalty, OT caps, a touchdown as time expires still awarding the try — the genre's #1 crash locus).

## P3 — Season loop and the witness layer

The phase that decides whether the rebuild fixed anything.

- `SeasonEngine`, schedule generation (S-09), standings, tiebreakers, playoffs.
- `Chronicle`, `Storyteller` (salience-matched templates per OD-4), `HookLedger` with the horizon invariant, `CareerLedger`.
- `FeedStore`, card severity tiers, blocking semantics (deadline semantics only, OD-3).
- Occasion derivation (`02` §2), the five broadcast slots (`02` §11), press voices.

**Gate:** universal + the witness-layer soak assertions (`03` §6.5): zero silent weeks, hook horizon never empty in ≥95% of weeks, no card without a face and a cause, no template repeating within 10 weeks for standout events. **The P2 state-to-witness matrix passes** — every player-visible mutation emits an event.

## P4 — The presentation layer

- Primetime tokens and components; `StagingDirector` as the single feedback owner; `HapticsService` and `SoundService` per `DESIGN.md` §2.4–2.5.
- Season hub, schedule, standings, the card feed, the hooks rail — built against mockup canon.
- Reduce Motion variants, read via `UIAccessibility` (not `@Environment`, which silently yields false off-view — `03` §5.7).

**Gate:** universal + staging gate (`03` §6.7): every moment in `DESIGN` §2.3 has a spec and each hero surface has a stated first render; Reduce Motion test flips the flag and asserts the variant; contrast coverage law passes (an untested pairing fails the build); VoiceOver reads stat rows as sentences.

## P5 — Live gameday (Call the Plays)

- The gameday hero surface, play panel, `StakesPanel` with true odds, tempo, drive log, live box score.
- Halftime replay-your-half and swing chart; postgame verdict; game report.
- **Simulated-phase receipts** (`02` §4): a defensive drive shows your call and its effect.

**Gate:** universal + played game ≤8 min; box score equals the event log; receipts present on every simulated drive; the leading toolbar slot is a real cancel.

## P6 — Team, roster, stats

- Team overview, depth chart with the featured-players strip, player card with career ledger and star-ability line, injury report, stats suite, awards.
- `DataTable` with column picker, density toggle, persistent sort — the expertise surface.

**Gate:** universal + click budgets met (any player's cap hit ≤2 taps from the depth chart); XXXL survives on every list; no fixed-width gutter clips a scaled number.

## P7 — Front office

- Cap engine, contracts, dead money, re-sign with promises, free agency waves, trades, staff, owner expectations.

**Gate:** universal + cap invariants (§6.4) including **all four practice-squad laundering doors**; AI front offices pass the league-credibility invariant (re-sign their stars, stay cap-legal, refuse absurd trades) — this gates before any glamour feature above it.

## P8 — Draft, scouting, offseason

- Scouting with fog and **recorded predictions the save grades**; draft night as an occasion; the ten offseason stages; progression and camp; retirements with arcs; records, HoF, previous seasons.
- Coach RPG: XP (outcome-based, never stat-farmable), skill trees, goals, job security ladder, carousel.

**Gate:** universal + the **full ten-season soak** including the P6-pillar assertion (the soak seed forces a firing; every fired path yields an offer or a sit-out arc *and* a chapter card); scouting accuracy ledger produces grades; save <5 MB after ten seasons.

## P9 — On the Field

Phase 4C is merged and compiles; this phase brings it up to current canon.

- Run the suite against it (**OD-6** — currently unverified).
- Re-earn the Primetime rules: staging through `StagingDirector`, the six-sound/eight-haptic vocabularies replacing its ad-hoc set, flat surfaces replacing gradients, `ScoreStrip` and occasion accents.
- Emit chronicle events from arcade plays.
- Tune the carrier/decision windows **on a device with a real thumb** (`07-SALVAGE.md` §D).

**Gate:** universal + `06` §8's gate: one-thumb full game in portrait, kernel stat-mapping tests, indicator-honesty and reconciliation invariants, scripted-thumbs EV bands, 60 fps on an A15, VoiceOver path playable end-to-end, XP/injury/chronicle parity with the other modes.

## P10 — Ship readiness

- Settings, tutorial, scenarios, challenge templates, checkpoints, season retrospective and its local export.
- Full pre-deployment checklist (`docs/PRE-DEPLOYMENT-CHECKLIST.md`).

**Gate:** universal + the whole checklist green + the definition of done below.

---

## Definition of done (v1)

A new player can: onboard through the wizard → play or sim a full season → survive an entire offseason → start season two with a coherent roster and cap → and keep going. Across ten simulated seasons: no crash, calibration and believability bands hold, saves stay <5 MB, week advance inside budget, and **no silent weeks**. Every phase gate green. Runs on iPhone SE through Pro Max, light and dark, XXXL, VoiceOver, Reduce Motion.

## Sequencing rationale

The engine precedes the UI it feeds. **The witness layer lands in P3, not late** — it is the rebuild's thesis, and retrofitting narration onto a finished sim is exactly the mistake v1 made. Presentation follows immediately in P4 so the feel layer is never "later." The front office gates on AI credibility before anything is built on top of it. The arcade comes late because it renders everything below it. The coach RPG lands last because it hooks into all of it.
