# 03 — Match Engine

D2, D3 and D4 in implementable detail. A builder should be able to work from this document without
further design work; where that is not yet true, the gap is named as such.

The engine is pure Swift with **zero `import SwiftUI`**. It runs headless, and every number below
lives in a rules module rather than inline.

---

## 1. Play resolution (D2)

### 1.1 The model

A snap resolves as a set of **matchups**, scored from ratings, and combined into an outcome. No
continuous physics, no tick integration. This is the hybrid assignment/leverage model D2 chose:
per-matchup causality the UI can narrate, with the probability mass in one place where it can be
calibrated.

```
resolveSnap(offense, defense, call, situation, rng) -> SnapOutcome
```

Stages, in fixed order (the order is part of the determinism contract):

1. **Assignment.** The offensive call assigns every offensive player a role (blocker, route runner,
   carrier, decoy). The defensive call assigns coverage responsibility, rush lanes and run fits.
2. **Leverage.** Each matchup produces a scalar in [-1, 1]:
   `leverage = f(attackerRating, defenderRating, schemeFit, fatigue, situationModifier) + noise(rng)`
   The rating term uses a logistic on the difference, not a linear one, so a 10-point gap matters
   more in the middle of the scale than at the ends.
3. **Resolution.** Leverages combine per play type into an outcome:
   - **Pass:** protection duels resolve first, producing time-to-pressure. Route matchups resolve
     into an openness score per receiver. The passer selects a target from openness, progression
     order and decision rating, then the throw resolves against openness, accuracy and pressure.
   - **Run:** front matchups resolve into lane quality; the carrier's vision and elusiveness resolve
     against pursuit leverage into yards, with a break-tackle chain that can extend the play.
   - **Kick:** distance, angle, leg strength, snap and hold quality, weather.
4. **Consequence.** Yards, clock, turnover, penalty, injury, fatigue accumulation.

**Stage 0, added 2026-08-13: the flag.** Penalties are drawn *before* assignment, for every snap,
whether or not one lands — `02` §3.5 states the model and the reason. Drawn first, a flag cannot
shift the stream the snap's own resolution reads; drawn unconditionally, its presence cannot change
how many draws a snap consumes. A pre-snap flag returns immediately and the snap never resolves; the
rest are applied to the finished outcome, with accept-or-decline resolved optimally for the side
holding the decision. Penalty yardage is **not** offensive yardage and a penalised snap is **not** an
offensive play: the calibration harness skips them before counting, or the penalty rate would move
plays per team-game and yards per play, both of which are banded in §5.1.

### 1.2 Attribute → outcome mapping

Each matchup names the attributes it reads. This table is the contract between the ratings model in
`02` and the engine:

| Matchup | Attacker attributes | Defender attributes |
|---|---|---|
| Pass protection | run/pass block, strength, awareness | pass rush, finesse, power, motor |
| Route vs coverage | route running, speed, release, hands | coverage, speed, agility, awareness |
| Throw | accuracy (short/mid/deep), arm strength, decision, poise | (openness, pressure state) |
| Run lane | run block, strength, scheme fit | run defence, shed, gap discipline |
| Carrier vs pursuit | vision, elusiveness, power, speed | tackling, pursuit angle, speed |
| Kick | leg strength, accuracy | block leverage |

### 1.3 Ceilings

The engine owns every probability. The match view measures and dramatises; it can never change an
outcome. A test asserts that rendering a play cannot alter its recorded result — the prior build's
"one engine, one truth" invariant, worth keeping.

---

## 2. Clock and situation

- Quarters, play clock, game clock, timeouts, two-minute handling, overtime per tier rules.
- **College clock rules differ from pro and must be modelled per tier** — the current rule on the
  clock stopping for first downs is a tier constant, not a shared one. Higher college tempo is a
  consequence of the clock model, not a fudge factor applied afterwards.
- Situation is a value type carried into resolution: down, distance, field position, score
  differential, time remaining, timeouts. Every call-in trigger in `02` reads it.

---

## 3. Determinism and the seeding contract

Non-negotiable (Tier A):

1. A given seed plus a given input state reproduces a match exactly, **across processes and app
   launches**.
2. **Seeds derive from identifier bytes, never from `hashValue`.** Swift salts `hashValue` per
   launch. The prior build seeded free-agent bidding from `UUID.hashValue`, so one save produced a
   different league every app start, and no in-process test could see it.
3. A **source-scanning test** fails the build if `hashValue` appears in any seeding path.
4. RNG is a value type, passed explicitly. No global or ambient randomness anywhere in the engine.
5. **No ambient `UUID()` or `Date()` in the engine.** Identities come from `rng.uuid()`, off the
   seeded stream; time comes from the simulated calendar. A second source-scanning test enforces it.
6. Seed derivation is hierarchical and stable: `leagueSeed -> seasonSeed -> weekSeed -> gameSeed ->
   driveSeed -> snapSeed`, each derived by a documented mixing function over the parent seed and the
   identifier bytes.

**Tests:** same seed twice in-process; same seed across two separate process invocations, compared
by hash of the full play-by-play; both source scans.

### Why clause 5 is here, and what it costs to omit

Added 2026-08-09. Clause 4 already forbade ambient randomness, but nothing enforced it, and clause 3
looks for the wrong thing — the previous build's determinism leak was **not** a `hashValue`. It was
`GameSimulator.swift:884` minting `PlayEvent(id: UUID(), ...)` at a call site, plus default-valued
`id: UUID = UUID()` on four engine initialisers. Five real offenders, and the suite was green,
because the scanner never looked for `UUID()` at all. The determinism tests could not see it either:
they compare scores and stats, not identities.

**The scan's rule, stated precisely so it is implementable:**

- **Forbidden in `Engine/`, `Generation/`, `AI/` and `Abstracted/`:** `UUID()` or `Date()` as an
  argument or an assignment. Every construction site passes an identity from the seeded stream.
- **Permitted in `Model/`:** `id: UUID = UUID()` as a *default parameter value* on an initialiser. A
  source scan cannot distinguish a default from a call, and the prior build's own evidence is that
  twelve of thirteen such sites were legitimate. The guarantee is upheld on the other side instead —
  engine construction passes `rng.uuid()` explicitly, which is exactly what the scan checks.

**And a defect in the scanner itself, inherited if it is ported verbatim.** The prior build's scan
(`DynastyTests.swift:605`) matched `line.contains(".hashValue") && !line.contains("//")` — so **any
offending line with a trailing comment was silently exempt**. A scan must strip comments properly and
ship with a self-test that fails on a planted offender, or it is a green light rather than a gate.

*Source: a cold-reader grill run against the parallel `rebuild/spec-package` branch (commit
`81af3e2`), which found this class against that branch's spec. The finding is scope-independent, so
it is adopted here. That branch is unmerged; see `docs/DOC-MANIFEST.md`.*

---

## 4. The off-screen model (D3)

The abstracted model resolves games the player does not watch: **~15 a week in the pro league, ~65 a
week in the college league** (~134 programmes), plus recruiting and portal AI for every programme.

It resolves at **drive level**: possessions are generated from team strength conditioned on scheme
matchup, home advantage, and fatigue/injury state; each possession draws an outcome (touchdown, field
goal, punt, turnover, downs, end of half) and a yardage; per-player stat lines are then allocated
from usage shares. No play-by-play is produced or stored.

### 4.1 The consistency requirement

Binding, not an optimisation. Over a **1000-season Monte Carlo**, the two models must be
*statistically equivalent*:

- **Test: TOST (two one-sided tests), α = 0.05.** Pass iff the 90% confidence interval for the
  difference between models lies **entirely inside** the equivalence margin.
- **Margins:** points/game ±0.75 · yards/play ±0.15 · completion rate ±1.5 pp · sack rate ±0.6 pp ·
  turnover rate ±0.4 pp · win-rate-vs-rating-gap ±2 pp at every 5-point bucket.
- **Shape check:** total variation distance between the models' points-per-game histograms ≤ 0.06.

**Range membership is explicitly rejected as the instrument.** A model whose true home-win rate is
0.62 passes a `0.50…0.60` range check roughly **1 run in 6** at n = 600, because the check has no
notion of sampling error and does not tighten as n grows. TOST puts the burden on the model.

---

## 5. The calibration harness

Implementable as specified. Structure:

```
CalibrationHarness
  .run(model:seasons:seed:) -> CalibrationReport
  report.assert(band:) -> pass/fail with the CI and the margin
```

Each band is `{ metric, tier, target, margin, test }`. The harness runs both models, produces
estimates with confidence intervals, and applies TOST — never a point-estimate range check.

### 5.1 Bands

Pro-tier bands **start from the numbers already asserted in the existing suite** (Tier B knowledge;
extracted in `01-RESEARCH.md` §6.4 with file and line) and are tightened by the TOST instrument
rather than re-derived. College-tier bands are the genuine gap and are sourced in §6.4.

Metrics both tiers must hold: points per game, yards per play, completion rate, sack rate, turnover
rate, explosive-play rate, field-goal accuracy by distance bucket, home advantage, fourth-quarter
scoring share, drive-outcome distribution, and target/carry distribution across the depth chart.

College-specific: higher plays per game, wider scoring variance, and a **talent-dispersion band** —
the win-rate-vs-rating-gap curve must be materially steeper than pro, because a top programme
against a bottom one is not a coin flip. §6.4 found a ~64-point spread across FBS; a generated
league that does not reproduce that spread fails D6 as well as calibration.

### 5.2 Overtime band — a note on scar tissue

The prior suite's overtime band was `0.008…0.14`, a seventeen-fold range. That is what widening a
band to stop a false failure looks like. Under TOST the correct response to a band that will not
hold is to fix the model or state the margin honestly, never to widen until green.

---

## 6. The soak

Twenty seasons, seeded, run headless, asserting:

- Ratings distribution stays inside band across all ~134 college programmes and 32 pro teams.
- Age and roster-size distributions stay legal; no roster illegal at any week boundary.
- Cap legality holds for every pro team (bounded overage from dead money only).
- Scholarship and eligibility legality holds for every college programme.
- Churn is within band — the league neither ossifies nor scrambles.
- **Save size stays under the D4 ceiling**, and every bounded collection in D7 is verified bounded
  by growth check, not by inspection.
- Job security moves (D8's falsifier), and coach tenure distribution stays in band.
- The two legal tests pass at every generated league.

---

## 7. Performance budgets (D4)

Restated here as the engine's contract; derived from the college case and now measured against an
iPhone 15-class device per the 2026-08-11 platform baseline.

| Budget | Target | Hard ceiling |
|---|---|---|
| Week advance, college (~65 games + recruiting/portal AI, ~134 programmes) | 1.2 s | **2.0 s** |
| Week advance, pro | 0.3 s | 0.6 s |
| Full-season sim, college | 20 s | 35 s |
| Match render frame | 8 ms | **16.7 ms** |
| Save size, 20 seasons | 4 MB | **8 MB** |
| Cold launch to playable | 1.2 s | 2.0 s |
| Save write (never on the main actor) | 150 ms | 400 ms |

The dominant week-advance term is recruiting AI across ~134 programmes, and it has **never been
measured** — flagged as an assumption in `01-RESEARCH.md` §6.2A and §6.4. If the ceiling cannot be
met, D14's fallback reduces the programme count rather than loosening the ceiling.

---

## 8. Known gaps in this document

Stated plainly rather than papered over:

1. **The presentation-time constants** that D1's arithmetic multiplies by (seconds per drive summary,
   seconds per call-in) are proposals, not measurements. They need the owner protocol in
   `01-RESEARCH.md` §6.0 §8 and one layout measurement in Xcode.
2. **Recruiting-AI cost** is unmeasured, as above.
3. **College clock rules** must be confirmed against the current rule book before the tier constants
   are fixed.
4. **Model-vs-model agreement for the recruiting/portal AI** is not covered by §4.1's bands, which
   cover game outcomes only. If the abstracted recruiting AI produces different class quality than a
   detailed one would, the league drifts over 20 seasons. The soak's churn assertion is a partial
   proxy; a proper band is unspecified work.
