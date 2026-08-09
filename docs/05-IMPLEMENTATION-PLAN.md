# 05 — Implementation Plan

Phased build for the rebuild. Each phase is independently shippable to TestFlight quality and closes on its gates — **every phase gate is a hard stop; a phase does not close with an unmet gate.**

Expand each phase into a task plan with `superpowers:writing-plans` before starting it; save to `docs/plans/`. One task, one commit.

## Migration strategy — read before P0

The rebuild happens **in place, phase by phase, on a tree that stays green.** v1's code is not deleted up front and the new code is not written in a parallel target. The rule that makes this work:

**A v1 file lives until the phase that replaces it, and that phase replaces it and all of its callers together.** `docs/07-SALVAGE.md` §A lists what is ported; §B lists what is rewritten; **the `Model/` layer (`League`, `Player`, `Team`, `Contract`, `GameRecord`, `StatLine`, `Position`, `Staff`) is rewritten in P1 together with every call site it breaks** — that is P1's real size, and the plan says so rather than letting "silence means rewrite" decide a twelve-thousand-line question by omission.

Two consequences the builder must plan for:

- **P1 is large.** Rewriting the model touches `Engine/`, `Arcade/`, the UI layer, and the test suites in one phase. Do it as one mechanical migration commit per consumer directory, keeping the build green at each step, rather than one heroic commit.
- **`Arcade/` is current code, not v1 debt** (`07-SALVAGE.md` §E). P1 updates it to the new model types; it is *not* rewritten until P9, and its behaviour must not change in P1. Its tests are the check.

If a phase genuinely cannot keep the tree green, stop and ask the owner before proceeding — do not leave the build red across phases.

## Gates

Gates come in two kinds, because this plan is executed unattended and four of them cannot be closed by an agent.

### Machine gates — the agent closes these

1. **Build green.** `swift build` succeeds.
2. **Tests green.** The suite passes, including every acceptance spec in `03-ARCHITECTURE.md` §6 that the phase has reached (see the matrix below).
3. **Session budgets timed** where measurable in the simulator (`03` §6.6): fast session ≤3 min, played game ≤8 min, interstitial ≤1 min, gameplan sheet ≤60 s — whichever the phase has built.
4. **Parity ledger checked** (`07-SALVAGE.md` §F): no row moved to `dropped` without an owner decision.
5. **Adversarial review** on the phase diff; confirmed findings fixed.
6. **Doc-first honoured:** no rule was implemented that canon does not state.
7. **Simulator demonstration.** The agent runs the app in the iOS Simulator and captures evidence. (Distinct from gate O3 below, which is device work.)

### Owner gates — the agent prepares, queues, and moves on

The agent **does not self-certify these** and **does not block on them.** It records the phase as `owner-review pending`, appends the item to a queue in the phase notes, and continues to the next phase. **All queued owner gates must clear before P10 closes.**

- **O1 — Craft gate.** Every surface the phase touched re-audits at **≥17/20 with zero P0/P1** against the rubric in `docs/09-CRAFT-RUBRIC.md`. The 9/20 baseline is historical: it was measured against a UI layer this rebuild replaces.
- **O2 — Cold-play gate.** One uninstructed hour actually playing what exists, asking only: is this fun, and does it pull? (`NOVEL` dose; the FM evidence behind it is ~two hours.)
- **O3 — Device measurement.** The week-advance end-to-end budget and 60 fps on an A15 (`03` §6.6). Until measured, those numbers are targets, not gates.
- **O4 — Device thumb-tuning.** P9 only: the carrier and decision windows (`07-SALVAGE.md` §D).

### Which acceptance specs gate which phase

A §6 spec gates from the phase that builds its subject, and is re-run at every later phase. "Engine phases" is not a category the builder has to guess at:

| Phase | Adds to the gate |
|---|---|
| P1 | Cross-process determinism (§6.1); club-colour contrast |
| P2 | + calibration bands (§6.2), believability bands (§6.3), mode parity, end-of-game state machine |
| P3 | + witness-layer assertions over **three** seasons (§6.5's card/hook/face/cause items) |
| P7 | + cap invariants (§6.4), including all four practice-squad doors |
| P8 | + the **full ten-season soak** (§6.5) including the P6 firing-and-chapter-card assertion |
| P9 | + the arcade gate in `06` §8 |

Phases not listed add no new acceptance specs but re-run every spec already in force.

---

## P0 — Foundation

Repo housekeeping and the harness the rest depends on.

- **Decide the test harness once, and propagate the command everywhere.** v1's hand-listed `main.swift` lets a written-but-unlisted suite pass by never running, which is the defect to fix. The toolchain in use (Swift 6.3+) bundles swift-testing, which gives self-registration for free — so migrate to it, convert `SimTests` from an `.executableTarget` to a `.testTarget`, and **update every reference to the run command from `swift run SimTests` to `swift test`**: this plan, `docs/PRE-DEPLOYMENT-CHECKLIST.md`, `README.md`, and `Package.swift`'s own comments, which currently contradict each other on this exact point. If the toolchain turns out not to provide it, keep the hand-rolled harness, add self-registration to it, and leave the command as-is — but say which was chosen in the phase notes.
- The two source scanners from `03` §6.1, each with a self-test that fails on a planted offender: no `.hashValue` seeding (comment-stripped, unlike v1's), and no `UUID()`/`Date()` as argument or assignment in `Engine/`/`Generation/`.
- **Fix the five known offenders in the same task**, red-then-green: `GameSimulator.swift:884` (a real call-site leak — the one §6.1 names), and the default-valued `id: UUID = UUID()` in `TradeEngine.swift:14`, `CoachEngine.swift:212` and `:409`, and `DraftEngine.swift:19`. This is sanctioned by the scope guard's defect exception — a scanner that ships green against known offenders is theatre.
- Delete the nested duplicate `Pro-Football-Coach/` directory (an old doc copy, not code).
- CI-shaped script that runs build + tests + scanners in one command.

**Gate:** machine gates 1–2, 5–7. A planted offender fails each scanner, and the five real offenders are gone. (No owner gates: P0 produces nothing playable, so O1 and O2 do not apply.)

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
