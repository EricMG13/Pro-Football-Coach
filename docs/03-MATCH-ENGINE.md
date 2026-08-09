# 03 — Match Engine

D2, D3 and D4 in enough detail to implement without further design work. Pure Swift, no UI, no
`import SwiftUI`, deterministic under a seeded RNG.

The engine exists to serve one number: **§3.5's 1.2 seconds per snap.** Everything below is shaped
by the requirement that a snap resolve fast, reproduce exactly, and produce enough structure for the
renderer to say *why* it happened.

---

## 1. D2 — What the 2D view is showing

> **The engine resolves a snap structurally; the renderer choreographs the resolved outcome.**

Three candidates were considered:

| Candidate | Verdict |
|---|---|
| **Agent-based per-snap resolution** — 22 agents with continuous physics, outcome emerges | Rejected. Emergent outcomes cannot be calibrated to a band; they are the band. Determinism across processes becomes a floating-point portability problem. Far too slow for 65 off-screen college games a week |
| **Play-outcome distribution + visualisation** — draw a yardage from a distribution, animate something plausible | Rejected. Calibrates trivially and explains nothing. The picture and the truth are unrelated, which is exactly the "watched vs simmed games diverge" failure the reference app's community found and worked around by *always watching* (§H rank 3) |
| **Hybrid assignment/leverage resolution, no continuous physics** | **Chosen** |

### 1.1 The chosen model

A snap resolves in four stages. No stage integrates positions over time.

```
1  ASSIGN     From the two play calls, build the assignment set:
              each offensive player has a job, each defender has a responsibility,
              and each pairing that matters becomes a matchup.

2  LEVERAGE   Score each matchup: attribute delta, plus scheme leverage
              (does this call beat that call), plus situation (down, distance,
              field position, fatigue, weather).

3  RESOLVE    Walk the play's decision points in order — protection holds or breaks,
              the primary read is open or covered, the carrier is met at the line or
              in space — each resolved by one seeded draw against its matchup score.

4  RECORD     Emit a PlayResult: yardage, clock, participants, and the decisive
              matchup, plus the ordered beats the renderer needs.
```

**Why this one.** It is the only candidate that answers *why*. A `PlayResult` carries "your right
guard lost to their three-technique in 0.9 s" rather than "−3 yards", and that is what makes an
adjustment mean something, what makes the play-by-play readable, and what gives the renderer a
reason to emphasise three dots out of twenty-two (§6.5). It calibrates because each stage is a
bounded probability the suite can assert on; it is deterministic because every draw is a seeded
integer draw; and it is fast because a snap is a handful of draws, not a simulation loop.

The prior build already proved the spatial half of this is implementable — formations, routes against
live coverage, per-matchup protection duels, run lanes, pursuit
(`docs/archive/plans/2026-08-09-arcade-all22.md`). That work is **design evidence, not code to port**
(Tier C), and the cost of rebuilding it is logged in `OPEN-DECISIONS.md`.

### 1.2 The choreography contract

The renderer receives a **resolved** `PlayResult` and animates toward it.

- **The last frame is the truth.** The final position of the ball carrier is pinned to the recorded
  yardage. The animation may not disagree with the box score, ever.
- **The engine owns every probability. The field only measures.** No visual state may feed back into
  an outcome.
- **A test asserts that retaining the play-by-play cannot change a result.** Watched, key-moments and
  instant paths run the identical simulation. This is the *one engine, one truth* rule, and it is the
  fix for the divergence complaint above.

### 1.3 Attribute → outcome mapping

Ratings are 40–99. Every matchup reduces to a **leverage score** in the same shape, so one calibrated
curve serves the whole engine:

```
leverage = (attackRating − defendRating)          // −59 … +59
         + schemeLeverage                          // −12 … +12   does this call beat that call
         + situationModifier                       // −10 … +10   down, distance, field, fatigue, weather
         + traitModifier                           // −6  … +6    dev traits, clutch, discipline

p(success) = clamp(base + leverage × slope, floor, ceiling)
```

`base`, `slope`, `floor` and `ceiling` are per-decision-point constants in `EngineTuning.swift`,
calibrated in §5 — **never inline**. Floors and ceilings are non-negotiable: a 99 must not beat a 40
every time, because upsets are the sport.

Worked example, pass protection on one snap:

| Input | Value |
|---|---|
| LT pass block | 78 |
| EDGE pass rush | 88 |
| Scheme leverage (max protection vs 4-man rush) | +8 |
| Situation (3rd and long, rush knows it) | −6 |
| leverage | 78 − 88 + 8 − 6 = **−8** |
| p(protection holds long enough) | base .72 + (−8 × .006) = **.672** |

One seeded draw. If it fails, the quarterback's pocket-presence matchup resolves next — sack, throwaway,
scramble — and the play never reaches the receiver read.

### 1.4 Clock and situation model

| Element | Rule |
|---|---|
| Quarter | 900 s |
| Play clock | 40 s |
| Elapsed per snap | Incomplete pass 5–7 s · in-bounds run 4–6 s + huddle 25–40 s · out of bounds stops · scoring plays stop |
| Tempo | Game-plan setting scales huddle time: **hurry** 12–18 s, **normal** 25–40 s, **milk** 35–40 s |
| Timeouts | 3 per half |
| Two-minute warning | Pro only |
| Overtime | Pro regular season one period; playoffs to a result. College alternating possessions from the 25 |
| Clock rules | **College stops the clock on a first down**, pro does not — this is a real rules difference and it is a large part of why college snap counts run high |

The situation model tracks down, distance, field position, score margin, time remaining and
timeouts, and feeds `situationModifier` plus the AI's decision model (§4).

---

## 2. Determinism and the seeding contract

**The contract:** a given seed plus a given input state reproduces a match exactly, **across
processes and across app launches**.

### 2.1 Rules

1. `SeededRandom` is the only source of randomness in `FootballSimCore`. No `Int.random`, no
   `arc4random`, no `SystemRandomNumberGenerator`.
2. **Seeds derive from identifier bytes, never from `hashValue`.** Swift salts hashing per process.
   The prior build seeded the AI's free-agent bidding from `UUID.hashValue`, so the same save
   produced a different league on every app launch — and no in-process determinism test could see
   it, because within one process the salt is constant. This is the single most instructive bug in
   the repo's history.
3. Seeds are derived hierarchically and deterministically, never by consuming a shared stream in
   call order:
   ```
   seed(match)  = mix(saveSeed, season, week, homeTeamID.bytes, awayTeamID.bytes)
   seed(snap)   = mix(seed(match), driveIndex, snapIndex)
   ```
   This makes any snap independently reproducible and means adding a call site upstream cannot
   perturb everything downstream.
4. No iteration over `Set` or `Dictionary` in any order-sensitive path. Sort by identifier first.
5. No floating-point accumulation across platforms in any path that decides an outcome. Draws
   compare integers.

### 2.2 The tests

| Test | Asserts |
|---|---|
| `sameSeedSameGame` | Two runs in one process produce byte-identical `PlayResult` sequences |
| `crossProcessDeterminism` | A recorded digest of a 100-game sample, stored as a fixture, still matches. **This is the one that would have caught the `hashValue` bug** |
| `noHashValueSeeding` | Source scan over `Sources/FootballSimCore/`: no `hashValue`, no `.random(`, no `arc4random` outside `SeededRandom.swift` |
| `noUIImport` | Source scan: no `import SwiftUI` / `import UIKit` anywhere in the engine |
| `retainingPlaysDoesNotChangeResult` | Simulating with and without play retention gives identical final states |

---

## 3. D3 — Two tiers of simulation

The visible game and the off-screen slate cannot share a fidelity level and meet a mobile
week-advance budget.

| Tier | Volume per week | Model |
|---|---|---|
| **Detailed** | 1 game (yours) | §1 — full assignment/leverage resolution, ~130–180 snaps |
| **Abstract** | Pro **~15**; college **~65** | Drive-level resolution: possessions, not snaps |
| **Recruiting / portal AI** | **~134 programmes** | The dominant cost. See §3.3 |

### 3.1 The abstract model

Per game, resolve **possessions** rather than snaps:

```
for each possession:
    startField ← from the previous outcome (kickoff, punt, turnover, score)
    driveStrength ← teamOffenseRating − opponentDefenseRating + homeEdge + situation
    outcome ← seeded draw over {TD, FG, punt, turnover, downs, end of half}
              with field position shifting the distribution
    yards, plays, clock ← sampled conditional on the outcome
```

Then distribute the drive's yardage to players by **depth-chart share and role weights**, so the
stat leaderboards and the record book stay populated and believable across a 134-programme league.

Cost: ~24 possessions/game instead of ~160 snaps — roughly **7× cheaper**, and cheaper again because
no matchup set is built.

### 3.2 The consistency requirement — a hard gate, not an optimisation

**The two models must agree at the season level.** If they do not, the league's statistics and your
own game come from different universes, standings become nonsense, and no player will trust the sim.

**The instrument, named:**

- Simulate **N = 200 seasons** with the detailed model and **N = 200** with the abstract model, from
  the same league and the same seed family.
- For each of the metrics below, compare the two distributions of **per-team season totals** with a
  **two-sample Kolmogorov–Smirnov test**.
- **Pass condition: the KS statistic D fails to reject the null at α = 0.01**, *and* the difference
  in means sits inside the stated band.

| Metric | Mean band (detailed − abstract) |
|---|---|
| Points for, per team-season | ±3% |
| Points against, per team-season | ±3% |
| Total yards, per team-season | ±4% |
| Turnovers, per team-season | ±6% |
| Wins, per team-season | ±0.35 wins |
| Passing share of yards | ±3pp |

Plus two shape assertions the KS test alone will not catch:

- **Blowout frequency** — share of games decided by 21+ — must agree within ±3pp. This is the one
  the college tier will break first, because talent dispersion is the defining college/pro
  difference (§6.4, assumption A9).
- **Standings dispersion** — standard deviation of team wins — within ±0.4.

**Failing this gate blocks the phase.** It is not a warning.

### 3.3 Recruiting and portal AI — the real cost

Plausibly larger than the game simulation itself: 134 programmes each evaluating a recruit pool
every week. It is budgeted as such.

- **Tiered evaluation.** Programmes near the player and near the top of the rankings evaluate at
  full fidelity; the long tail runs a cheap heuristic. The player only ever *sees* the top tier.
- **Amortised across the week**, not computed in one blocking pass at advance.
- **Bounded pools**: the recruit class is generated once per cycle and capped, never grown.
- Assumption **A5** says this fits the budget. It has a benchmark, gated in the college phase.

---

## 4. Game AI (D10 is decided here)

The AI is load-bearing under D1: **your coordinator calls the plays**, so its quality *is* the
match's quality. It is also the genre's most common complaint (§6.2).

| Layer | Behaviour |
|---|---|
| **Play selection** | Sample from the game plan's distribution, conditioned on down, distance, field, score and clock. It executes *your* intent — a plan with 70% run lean runs 70% of the time, unless the situation forbids it |
| **Coordinator quality** | A good OC's situational conditioning is sharp; a poor one drifts toward his own tendencies under pressure, and *visibly so*. This is what makes the staff market matter |
| **Opponent adjustment** | Detects your tendencies over a rolling window and shifts its own distribution to counter. **Tells you it did**, which is what makes the in-drive adjustment a real decision rather than a guess |
| **Fourth down / clock** | Expected-value model over win probability, with an aggression parameter per coach personality |

### 4.1 What "good" means, and how it is measured

Three assertions, all in the suite:

1. **No rubber-banding.** A test simulates 2,000 games across rating gaps and asserts win probability
   is a **monotonic function of the rating gap** with no compression in the tail. If an 85-rated team
   beats a 70-rated team less often than the curve predicts, the AI is cheating and the test fails.
   This directly targets FC:CD's "anti-upset cheese" complaint (§6.2).
2. **Difficulty never touches ratings.** A source-scanning test asserts no difficulty parameter
   reaches any rating, attribute or leverage floor. Difficulty may only move AI *decision quality* and
   *adjustment speed*.
3. **Exploit resistance.** A soak plays 500 games with a single fixed degenerate game plan (all-blitz,
   all-deep-shot, never punt) and asserts its win rate stays under 65% against average opposition.
   A dominant single strategy is a failed AI.

**What stops it being cut when the schedule slips**: these three tests are **phase gates**, not
polish. A phase whose AI tests fail does not close.

---

## 5. The calibration harness

Concrete enough to implement without further design.

### 5.1 Shape

```swift
// Aggregates a batch of simulated games so calibration can assert league-wide.
let sample = SimHarness.sample(count: 600, seed: 31, tier: .pro, retainPlays: true)
expectIn(sample.pointsPerTeamGame, 20...26, "points per team game")
```

- **600 games** per sample, matching the prior build's proven sample size.
- **Fixed seed** per suite, so a failure is reproducible and not a coin flip.
- **Band widths are a statistical decision.** At 600 games the standard error on a rate like home-win
  is ~2pp; a band tighter than that fails on sampling noise rather than on regressions. Every band
  below is at least 3 standard errors wide.
- Each band records its **source** in a comment next to it (§6.4's licensing posture).

### 5.2 Pro bands — carried forward verbatim from the prior build

These are calibrated and proven (`Tests/SimTests/Suites/GameSimulatorTests.swift`, commit `47ac105`)
and are reproduced in `01-RESEARCH.md` §6.4. Points 20–26 · pass yards 195–245 · completion 61–67% ·
rush yards 100–130 · INT 0.6–1.1 · sacks 2.0–3.1 · FG 80–90% · OT rate 0.008–0.14 · home win
0.50–0.60 · plays 55–72 · Q4 share 0.22–0.32 · explosives 3–9 · long TDs 0.2–1.2 · safeties ≤0.05 ·
TE targets 0.15–0.26 · RB targets 0.10–0.28 · max receiver share ≤0.45.

### 5.3 College bands — new, and the genuine gap

Band centres are set from published national per-game averages at calibration time and **nothing is
shipped** (§6.4). Widths follow the 3-standard-error rule.

| Metric | Band | Why it differs from pro |
|---|---|---|
| Points per team-game | 24–33 | Higher scoring, much wider variance |
| Offensive plays per team-game | 64–80 | Tempo, plus the clock stopping on first downs |
| Pass yards per team-game | 200–265 | Wider range of offensive identity |
| Rush yards per team-game | 130–185 | Option and spread-run schemes |
| Completion % | 58–66 | Lower and wider |
| Sacks per team-game | 1.8–3.0 | Similar |
| FG % | 70–82 | Materially worse than pro, especially at range |
| **Share of games decided by 21+** | **0.22–0.34** | **The defining college metric.** Talent dispersion means blowouts are normal; a model calibrated on pro data produces college games that are all far too close |
| Home win rate | 0.54–0.66 | Home field is worth more in college |

**A9 is the assumption under all of this** — that college can be modelled as a widened talent
distribution over the same engine. The blowout band is the test that would falsify it.

### 5.4 Pass / fail

A calibration suite failure is a **build failure**. There is no "calibration warning" state. If a
band is wrong, the band gets changed deliberately, in a commit, with a reason — never silently
widened to make a red suite green.

---

## 6. The soak

Methodology carried from the prior build, which ran ten seasons and held.

| Invariant | Assertion |
|---|---|
| Ratings | No player outside 40–99, ever, at any point in any season |
| Ages | No player outside the legal age range; no negative eligibility |
| Roster sizes | Every team legal at every week boundary — 53+16 pro, 85 scholarship / 105 total college |
| Cap legality | Every team inside the cap, allowing a small dead-money overage and failing on a large one |
| Churn | Year-over-year roster turnover inside a believable band — neither frozen nor a random shuffle |
| **Save size** | **Bounded — see §7** |
| Carousel | **Never dead-ends**: every coach with an expiring contract has ≥1 offer or an explicit year-out |
| Competitive balance | No team wins more than N consecutive titles; no team is winless for a decade |
| Records | The record book advances and the hall of fame receives inductees |

**Duration: 20 seasons, not 10.** A unified career spans both tiers, and the promotion arc is not
exercised at all in 10. The soak must include at least one promotion and one firing.

---

## 7. Save-size discipline (feeds D7)

The prior build's saves grew to 8.3 MB before anyone looked, because the free-agent pool and the
news feed both grew without limit — nine thousand unsigned players, eight thousand stories. Bounding
them took it to 2.3 MB and stopped every free-agency scan getting slower each year.

**Every collection that can grow is named and bounded, or it is a defect:**

| Collection | Bound |
|---|---|
| Free-agent pool | Hard cap; retire the tail by age and rating |
| News feed | Ring buffer |
| Recruit classes | One live cycle; prior cycles reduced to outcomes |
| Portal pool | One window; cleared on close |
| Play-by-play | Current game only. Finished seasons keep aggregates |
| Season history | Aggregates only, never per-play |
| Records / HoF | Bounded by construction (top N) |
| Rivalry history | **Bounded per pairing** — the last N meetings plus lifetime aggregates |

A soak assertion on total save size at season 20 is the backstop. Budget in §8.

---

## 8. D4 — Performance budgets

**Derived from the college case, which is the worse one**, on an iPhone 12-class device. The prior
build's pro-only budgets do not carry over.

| Budget | Target | Ceiling | Derivation |
|---|---|---|---|
| **Week advance (college)** | 500 ms | **800 ms** | ~65 abstract games + recruiting/portal AI for 134 programmes. The prior build's pro week was 105 ms of engine work for 15 games; college is ~4.3× the games plus a recruiting pass that is plausibly larger than the games |
| Week advance (pro) | 150 ms | 250 ms | ~15 abstract games, no recruiting |
| Full-season sim (college) | 12 s | **25 s** | 16 weeks at the ceiling, plus the postseason |
| **Match render** | ≤ 8 ms/frame | 16.6 ms | 60 fps with 22 entities. Half the frame budget is the target so the rest of SwiftUI has room |
| Snap resolution (detailed) | ≤ 1 ms | 3 ms | 180 snaps must resolve far inside one frame if a player skips to the end |
| **Save write** | ≤ 40 ms, **off the main actor** | 100 ms | The prior build's P0: 84–112 ms synchronous on the main actor at 11 call sites |
| **Save size at season 20** | 6 MB | **10 MB** | College is ~5× the pro player count: ~134 programmes × 85 vs 32 × 69 |
| Cold launch to menu | 800 ms | 1.5 s | |

Every one of these is a **test**, not a note. The week-advance and save-size figures are soak
assertions; the render budget is measured on device by the owner and recorded in `STATUS.md`.

---

## 9. Standing invariants

Assertions that must hold at every week boundary of every soak. These are the five systemic patterns
from `AUDIT.md` and the prior build's hard-won lessons, converted into tests — see
`06-AUDIT-DISPOSITION.md` for the full mapping.

| # | Invariant | Test |
|---|---|---|
| I1 | The carousel never dead-ends | `soakCarouselNeverDeadEnds` |
| I2 | Every team is cap-legal and roster-legal | `soakLeagueAlwaysLegal` |
| I3 | Save size stays inside budget | `soakSaveSizeBounded` |
| I4 | No unbounded collection exists | `soakCollectionsBounded` — asserts each named collection against its cap |
| I5 | Determinism holds across processes | `crossProcessDeterminism` |
| I6 | The engine imports no UI | `noUIImport` |
| I7 | Watched and simmed games agree | `retainingPlaysDoesNotChangeResult` |
| I8 | Difficulty never touches ratings | `difficultyDoesNotTouchRatings` |
| I9 | Win probability is monotonic in rating gap | `noRubberBanding` |
| I10 | No generated name collides with a real one | `nameCollisionTest` — Tier A legal |
| I11 | No generated colour pair is real trade dress | `tradeDressTest` — Tier A legal |

### 9.1 The two Tier A legal tests, specified

**I10 — name collision.** Generate **N = 200** leagues across 200 seeds, in both tiers. Collect every
generated team, city, school, conference, stadium, player and coach name. Assert **zero** case- and
punctuation-insensitive matches against `Resources/Blocklist/*.txt`, a maintained list of real
league, programme, conference, stadium and notable-player names. A match is a build failure. The
blocklist is versioned in-repo and its coverage is a review checklist item, since no test can prove
a blocklist complete.

**I11 — trade dress.** For every generated `(primary, secondary)` colour pair, compute **CIE ΔE2000**
against every real programme pair in the blocklist. Assert:

```
for every real pair (r1, r2):
    max( ΔE00(primary, r1), ΔE00(secondary, r2) ) ≥ 10
```

The rule is deliberately on the **pair**, not on single colours: navy is not ownable and many real
programmes share one colour, but a matching *combination* is what reads as trade dress. Threshold 10
is a stated starting value to be tuned against false-positive rate during the generation phase, and
tuning it is a decision that gets logged, not a knob to quietly turn when the test goes red.

---

## 10. What is lost by rebuilding rather than porting

Required by the brief's symmetry rule, and recorded in full in `OPEN-DECISIONS.md`. In short: a
calibrated engine with 224 tests and 13,226 assertions, a ten-season soak that holds, the
cross-process determinism fix, the bounded save growth, and the practice-squad cap-laundering
defences. **Rebuilding is the decision. It is not free, and this document does not pretend it is.**
The calibration bands, the soak invariants and the three practice-squad rules are carried forward as
*knowledge* precisely so the rebuild does not pay for them twice.
