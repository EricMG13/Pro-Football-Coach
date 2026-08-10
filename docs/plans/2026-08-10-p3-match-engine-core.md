# P3 — Match Engine Core Implementation Plan

**Goal:** D2's hybrid assignment/leverage resolution, per tier, with the clock and situation model,
and the drive and game loops on top.

**Gates:** G1 build, G2 tests, G4 scope, G6 determinism.

## What D2 chose, and what that constrains

`docs/OPEN-DECISIONS.md` D2: a snap resolves as a set of **matchups** — each blocker against each
rusher, each receiver against each defender, the run lane against the front — scored from ratings,
scheme fit, fatigue and the called play, then combined. No continuous physics, no tick integration.

Two consequences shape every file below.

1. **Per-matchup causality is the product, not a by-product.** D2 rejects the play-outcome
   distribution model because it "cannot answer why did that happen, which is the entire information
   payload of a coaching game: the player must be able to see that the left tackle lost, not merely
   that the sack occurred." So `SnapOutcome` carries the matchup results that produced it, not only
   the yardage. `04` §5.3 draws a sack as *the protection duel that lost*, and it can only do that
   if the engine recorded which duel that was.
2. **The engine owns every probability.** `03` §1.3: the match view measures and dramatises and can
   never change an outcome. P3 owns the engine half of that invariant.

## What to read out of history first, and what it settles

`docs/PORT-LOG.md` closes: "P3 is the phase that designs per-matchup resolution, and it is the phase
that should read `SnapKernel` back out of history before deciding how much of that geometry to
rebuild." Done, before this plan was written:

```
git show 37b10c3^:Sources/FootballSimCore/Arcade/SnapKernel.swift
```

755 lines. Its top-level API is `ArcadeAction` (`aim`, `setBullet`, `release`, `juke`, `dive`),
`TracedAction`, `InputTrace` — a record of what a thumb did, with timings. That is the mission
constraint the discard rests on, visible in the first forty lines, and it confirms the decision
rather than reopening it.

**But one thing in it transfers, and it is the important one.** Its `SnapEnding` doc comment reads:
*"Deliberately not an outcome: the kernel says what the player did and what the geometry was, never
whether it worked. Whether the pass was caught, whether the pressure became a sack, how many yards
it gained — all of that is the engine's."* That is D2's honesty invariant, already stated in the
prior build's own words. P3 keeps the separation and drops the input layer: the matchup layer
measures leverage, the resolver owns every probability.

## Files

| Path | Responsibility |
|---|---|
| `Engine/Situation.swift` | Down, distance, field position, score, clock, timeouts — the value every `02` §3.1 call-in trigger reads |
| `Engine/GameClock.swift` | Quarters, play clock, game clock, two-minute, overtime |
| `Rules/CollegeRules/CollegeClockRules.swift` | College clock constants (`03` §2) |
| `Rules/ProRules/ProClockRules.swift` | Pro clock constants |
| `Rules/MatchupRules.swift` | Every constant resolution reads. `03` §1.2's attribute table is the contract |
| `Engine/PlayCall.swift` | An offensive and a defensive call, and the assignments each implies |
| `Engine/Assignment.swift` | Stage 1 |
| `Engine/Leverage.swift` | Stage 2 |
| `Engine/SnapResolver.swift` | Stage 3 |
| `Engine/SnapOutcome.swift` | Stage 4, plus the causal record the UI narrates |
| `Engine/DriveEngine.swift` | The drive loop |
| `Engine/GameEngine.swift` | The game loop |

## Tasks

- [ ] **1. Escalate the college clock rules before fixing them.** `03` §8 clause 3: college clock
      rules "must be confirmed against the current rule book before the tier constants are fixed".
      No rule book is reachable from this environment. Record the constants used, mark them
      **unconfirmed** in `docs/STATUS.md`, and name the owner action. Do not present them as
      verified. This is `08`'s escalation trigger 1 in miniature: the phase proceeds, the claim does
      not.
- [ ] **2. Situation and clock, test first**, per tier. The clock-stopping-on-first-down difference
      is a tier constant, and higher college tempo must fall out of the clock model rather than being
      applied afterwards as a fudge (`03` §2).
- [ ] **3. Leverage, test first.** Logistic on the rating difference, not linear: `03` §1.1 requires
      a 10-point gap to matter more in the middle of the scale than at the ends. Assert the *shape*
      of the curve, not merely that its output is inside [-1, 1] — a linear ramp satisfies the range
      and fails the requirement.
- [ ] **4. Assignment and the matchup table.** Every attribute `03` §1.2 names is read by the matchup
      that names it, enumerated by construction so a later phase cannot quietly stop reading one.
- [ ] **5. Pass, run and kick resolution**, in `03` §1.1's fixed stage order. The order is part of
      the determinism contract, so a test asserts it rather than trusting the call sites.
- [ ] **6. Drive and game loops.**
- [ ] **7. Both determinism assertions.** Same seed twice in-process, and same seed across two
      **separate process invocations**, compared by hash of the full play-by-play. `03` §3 asks for
      exactly this, and P0's golden vectors deliberately deferred it to the phase that has a
      play-by-play to hash.
- [ ] **8. The honesty invariant, engine half.** Resolution is a pure function of state, call and
      rng, and it produces the frames — never the reverse. A test asserts a frame stream cannot
      alter its recorded outcome.
- [ ] **9. Gates, adversarial review, `STATUS.md`.**

## Explicitly not in P3

Calibration bands and TOST (P4). **The engine will be numerically wrong at the end of P3 and that is
expected** — P4 is where it is tuned, and a P3 that tuned by eye would make P4's TOST a formality
over numbers already fitted to it. The off-screen model (P5). Schedules and seasons (P6). The
coordinator AI that chooses calls (P10) — P3 takes a call as an input. The `Canvas` view (P13).
