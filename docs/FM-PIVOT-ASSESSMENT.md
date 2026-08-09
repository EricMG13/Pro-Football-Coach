# Assessment — moving from the current PRODUCT.md to an FM-class pro football sim

Written 2026-08-09 against commit `47ac105`. Source-level review of `Sources/`, `docs/`,
`PRODUCT.md`. No Swift toolchain was available in this container, so nothing here was measured
at runtime; every performance figure below is labelled as an estimate and says what it is
derived from.

**The question:** should the product move away from the current `PRODUCT.md` — a mobile-paced
pro football coach sim with cap depth, a coach RPG and an arcade mode — toward a pro football
equivalent of *Football Manager*, with the same analytical depth and the same class of
simulation engine?

Read charitably, that is not "reuse SI's engine" (impossible and unlicensable) but "build a
sim of that class": individual players simulated as agents, outcomes emergent rather than drawn,
and a decision surface deep enough that the numbers reward study.

---

## Verdict

**The direction is right, the framing is wrong, and one third of it is already half-built.**

Three things are true at once, and they pull in different directions:

1. **The depth gap is real and worth closing.** The current sim resolves plays from unit
   averages and assigns statistics from share tables. That breaks the causal chain from decision
   to outcome, which is the entire mechanism FM's appeal rests on. Closing that gap is the
   single highest-value change available to this project, and most of it does not require the
   engine rewrite.

2. **The engine rewrite is more tractable here than it looks — and the codebase has already
   written most of it, wired backwards.** `Sources/FootballSimCore/Arcade/` is 2,376 lines of
   spatial, per-player, seeded football: formations, routes against live coverage, per-matchup
   protection duels, run lanes, carrier pursuit, openness. It is an FM-class match engine in
   embryo. It is currently forbidden from deciding anything — `SnapKernel.swift:56-59` states the
   rule outright: *"the kernel says what the player did and what the geometry was, never whether
   it worked."* The pivot's central engineering act is inverting that one dependency.

3. **The literal goal as stated would break three commitments in `PRODUCT.md` that are load-
   bearing**, and two of them are not engineering problems. Taken in order of how hard they are
   to recover from: the calibration guarantee, the iPhone-only surface, and the 150 ms week
   advance.

So: **do not "move away from" `PRODUCT.md`. Amend it, in three separable decisions, sequenced
so the risky one is last and reversible.** Details in *Recommendation*.

---

## 1. What "the same analytical depth" actually means

The most common way this pivot fails is cargo-culting the attribute count. FM's depth is not
mainly in having 35 attributes instead of 6. It is in four structural properties, and they are
worth naming separately because this project scores very differently on each.

| Property | What it means | Current project |
|---|---|---|
| **Emergence** | Statistics are a *record* of simulated events, not a *cause* of them. A winger's assists come from where he stood. | **Absent.** Target share is a function of depth-chart slot (`PlayResolver.pickByShares`), not of separation. |
| **Granularity** | The unit of simulation is the individual in a position, with a role. | **Coarse.** 11 position groups; `ol` and `dl` are single undifferentiated ratings. |
| **A deep decision surface** | Tactics are a large, legible, consequential space the player composes rather than picks from. | **Thin.** 6 offensive calls × 6 defensive × 3 tempos. |
| **Instrumentation** | The game hands you the analysis, not just the box score. | **Thin.** 9 stat categories, box scores, leaderboards, records. |

Of those four, **granularity and decision surface are where the product value is**, and neither
requires an agent-based engine to start. Emergence requires it. Instrumentation depends on
emergence to have anything interesting to instrument.

That ordering matters, and it is the basis of the staged recommendation below.

### A note on the analogy

"FM for pro football" is a good internal north star and a bad external claim. *Football Manager*
is Sports Interactive's mark, and this project already runs a hard fictional-identity rule
(`PRODUCT.md`, Brand Commitments). The comparison belongs in planning documents; it must never
reach shipped copy, App Store metadata, or a TestFlight description. Cheap to observe now,
expensive to unpick later.

---

## 2. Where the project actually stands

Measured from source, not from the docs' claims about the source.

**Player model** — `Model/Player.swift`, `Model/Position.swift`

- 20 attributes exist league-wide; each player stores only his position's 5–8. A quarterback
  has six: speed, strength, agility, awareness, throw power, throw accuracy.
- One potential letter (8 grades), 0–2 traits from a list of 8, one morale integer.
- No hidden attributes. No consistency, no big-game temperament, no injury history beyond a
  weeks-remaining counter, no professionalism or work rate — which is to say nothing that would
  let two 82-overall players behave differently over a decade.
- `effectiveOverall` collapses morale to a ±3 shift. This is a deliberate, documented choice
  ("morale colours performance, it doesn't decide games") and it is the correct choice *for the
  current engine*. In an FM-class model it would be wrong: the whole point is that the
  intangibles compound.

**Positional model** — the sharpest structural limit

`Position` has 11 cases. `ol` is nine players behind one rating; `dl` is eight. There is no
left tackle, no interior/edge split, no slot corner, no fullback, no returner. This forecloses
most of what makes pro roster-building analytically interesting: positional value, scheme fit
("he's a 4-3 end in a 3-4 front"), and the premium markets that follow from both. You cannot
express *why* a left tackle costs more than a right guard in a model that has neither.

**Tactical surface** — `Rules/PlayMatrix.swift`

`OffensivePlay` has 6 real calls (inside run, outside run, short pass, deep pass, play action,
screen) plus 5 situational; `DefensivePlay` has 6; `Tempo` has 3. The gameplan space is a
36-cell matrix with a tempo multiplier. There is no personnel, no formation, no route concept,
no coverage shell, no front, no weekly game plan, no opponent tendency, no situational package.
`depthChart: [Position: [Player.ID]]` is a flat ordering — no snap-count distribution, no
sub packages, no rotation.

For comparison, this is roughly the tactical depth of choosing "attacking" or "defensive" in a
football game — which is exactly the level FM left behind in the 1990s.

**Resolution model** — `Engine/PlayResolver.swift`

The shape is honest and well built: play profile supplies a mean, standard deviation and
explosive rate; the offensive/defensive unit rating delta shifts the mean; a Gaussian draw plus
a fat tail produces yards; a handful of individual attribute edges nudge the result (throw
accuracy ±0.35%/point on completion, catching ±0.2%/point, break-tackle and speed on yards
after catch). Then share tables decide *who* gets credited.

This is a stochastic outcome-distribution engine with light per-player attribution. It is the
standard architecture for the genre and it is executed above the genre average — the fumble
yardage reconciliation at `PlayResolver.swift:307-309`, the summation-order determinism note at
`Player.swift:104-107`, and the defender draw weighting at `PlayResolver.swift:415-417` are all
the work of someone who cared. But its ceiling is fixed by two facts:

- **The offensive line is one number.** An elite left tackle and a replacement right tackle are
  indistinguishable to the simulation. So are their contracts' justifications.
- **Targets are assigned, not earned.** Sign the best route runner in the league and put him
  second on the depth chart, and he gets the second slot's share. The decision does not reach
  the outcome.

Every other depth complaint downstream of this — thin instrumentation, shallow scouting payoff,
weak scheme fit — is a symptom of these two.

**Staff** — `Model/Staff.swift`

Three slots (OC/DC/STC). Each is one 40–99 rating, a scheme specialty, and 0–1 trait from a
list of three. FM's staff system is roughly fifteen role types with their own attribute sets
feeding training, scouting accuracy, medical outcomes and data analysis. This gap is wide, but
it is also the cheapest of the big ones to close, because staff effects are multipliers on
systems that already exist.

**What is genuinely strong and would survive any pivot**

- Determinism, taken seriously — including the cross-process seeding bug found and fixed, and a
  source-scanning test to stop it returning (`STATUS.md`).
- The cap engine, dead money, proration, and the practice-squad laundering holes closed.
- Save durability: versioned, backed up, forward-compatible, 2.3 MB after ten seasons, bounded
  free-agent pool and news feed.
- 224 tests, 13,226 assertions, calibration bands asserted per simulated season, a ten-season
  soak.

That last one is the most valuable asset in the repository, and section 4 explains why it is
also the pivot's biggest risk.

---

## 3. The engine question

### The finding: the match engine exists and is pointed the wrong way

`Sources/FootballSimCore/Arcade/` — 2,376 lines across `SnapKernel`, `Formations`, `Routes`,
`Coverage`, `Openness`, `Pocket`, `RunLanes`, `FieldGeometry`, `DefensiveInputs`,
`Choreographer` — is a spatial, seeded, headless-testable model of 22 players on a field. That
is the hard part of an FM-class match engine, and it is written.

It is also, by explicit design, subordinate:

- `SnapKernel` grades what the *human* did and emits `SnapGrades` — placement error, target
  openness, release timing, lane quality — which become `PlayExecution` modifiers on the
  existing probabilistic resolver. `STATUS.md` states the contract: *"The engine still owns
  every probability; the field only measures."*
- `Choreographer` runs the other direction: it takes an already-resolved play and generates
  all-22 motion *whose last frame is pinned to the recorded yardage*. It is a renderer for a
  decision already made.

So the codebase contains a spatial simulator that is forbidden from simulating, and an animation
layer that reverse-engineers geometry from an outcome. **The pivot is the inversion: let the
kernel decide, and demote `PlayResolver`'s distributions from truth to calibration target.**

Two large caveats, both from `STATUS.md`:

- **None of Phase 4C has ever been compiled.** Not the kernel, not the ~60 tests written against
  it. It was reviewed adversarially by agents in place of a compiler, which the document itself
  says is not the same thing. Before any of this is planned against, it has to build and go
  green. That is step zero and it is not optional.
- **It only models the offence's snap under human control.** All 22 move, but the defensive side
  is a reactive scaffold for grading a human's read, not an independent decision-maker. Turning
  it into a generator means writing per-agent decision logic for eleven defenders — pursuit
  angles, zone handoffs, leverage, run fits — that currently has no equivalent.

### Feasibility: the arithmetic is favourable, and it is favourable for a specific reason

The instinct is that FM's engine is out of reach on a phone. The instinct is wrong, and the
reason is scale, not sophistication.

FM's computational problem is that a save simulates a hundred-plus leagues and tens of thousands
of matches per season across a database of several hundred thousand players. This project
simulates **one league of 32 teams**. That is roughly two orders of magnitude less work per
simulated day.

An order-of-magnitude estimate for a tick-based snap kernel:

| Quantity | Figure |
|---|---|
| Offensive plays per game, both teams | ~130 |
| Simulated seconds of action per play | ~5 |
| Tick rate | 10 Hz → ~50 ticks/play |
| Agents per tick | 22 |
| Agent-updates per game | ~143,000 |
| Agent-updates per week (16 games) | ~2.3M |

At 100–300 ns per agent-update — plausible for flat arrays of value types with simple steering
and a brute-force 22-agent proximity check, which at 484 pair-tests per tick needs no spatial
index — a week lands around **0.25–0.7 s**, and a full season around **5–13 s**. Estimates, not
measurements; on an A15 rather than desktop.

**That is affordable. It is also four to five times the 150 ms week-advance budget in
`PRODUCT.md`.**

Worth noting: that budget may already be under pressure. `STATUS.md` reports the suite at ~100 s
"dominated by the ten-season soak", and ten seasons is roughly 2,850 games — implying tens of
milliseconds per game on a desktop-class release build, against a budget of 9.4 ms per game
(150 ms ÷ 16). No week-advance figure has been measured on device. **Measure the current one
before planning around the new one** — the pivot may be inheriting a broken budget rather than
breaking a working one.

### Cost

Honest sizing, in the project's own phase currency:

- **Compile and green Phase 4C** — unknown, days. Blocking everything else.
- **Invert the kernel** — defensive agent decisions, offensive AI for all eleven, ball flight,
  catch contests, tackle resolution, penalties as emergent events. This is larger than any
  completed phase in the project's history. Call it two phases.
- **Recalibrate** — see section 4. Open-ended. This is the part that eats schedules.

---

## 4. The three commitments the literal pivot breaks

### 4.1 The calibration guarantee — the serious one

The current engine's quality claim is that its output sits inside asserted statistical bands:
points per game 20–26, completion 61–67%, sacks 2.0–2.9, fourth-quarter scoring share 22–30%,
no receiver above 40% of targets, a 12-point overall gap winning ≥72% of the time.

Those bands hold because the engine *draws from distributions chosen to produce them*. Tuning is
direct: move the mean, the mean moves.

**An agent-based engine gives you none of that.** Aggregate statistics become emergent, which
means calibration becomes an inverse problem — you adjust pursuit angles and hope completion
percentage lands. This is genuinely hard, and the evidence is that Sports Interactive has had a
dedicated team on exactly this problem for two decades and still ships a discoverable "meta
tactic" most years.

This is the pivot's dominant execution risk, and it deserves a blunt statement: **you would be
trading a provably calibrated engine for one that will be uncalibrated for a long time, and
whose calibration is an open-ended tuning problem rather than a task with a completion date.**

The mitigation is strong, though, and it is already sitting in the repository. The existing
engine and its 13,226 assertions become **the oracle**: the new engine is not done when it
works, it is done when it reproduces the old engine's bands, on the same seeds, within
tolerance. Concretely:

- Put both behind one protocol (`PlayResolving`) and keep both shipping-capable.
- Keep the existing calibration suite pointed at whichever is active.
- Add a distribution-comparison test: agent engine vs. resolver over N seeded seasons, asserting
  the aggregate distributions agree — the same discipline as the existing
  `retainPlays true vs false` mode-parity test, applied across engines instead of modes.
- Ship the agent engine behind a setting, default off, until it passes. Then flip the default.
  Do not delete the resolver until a release has shipped on the new default.

Done this way, the pivot is **reversible at every point**, which is what makes it a reasonable
risk rather than a bet on the project.

### 4.2 The iPhone-only surface — the one that is not an engineering problem

`PRODUCT.md` commits to compact width only, single-column, no size-class branching, Dynamic Type
at XXXL without truncation. FM's analytical depth is expressed through dense multi-column
tables, filters, scatter plots and side-by-side comparison — a 27-inch idiom.

The precedent is unambiguous and unflattering: the people who own FM shipped *Football Manager
Mobile* as a deliberately shallower product, because they concluded the depth does not fit a
phone. Assume they were right about the naive port and ask what follows.

Three honest options:

- **(a) Bring iPad and regular width into scope.** Currently explicit backlog. Real cost, known
  shape, no invention required.
- **(b) Invent a phone-native idiom for depth.** Progressive disclosure; one insight per card;
  comparison as a considered two-up rather than a twelve-column table; the analyst's conclusion
  surfaced with the table one tap behind it. Harder, and it is where this product could actually
  beat both FM Mobile and the PC front-office sims — none of which are well designed.
- **(c) Take less depth than the goal implies.** Legitimate, but then say so explicitly rather
  than discovering it during construction.

**This decision gates how much depth can ever be surfaced, so it should be taken before, not
after, the engine work.** It is also the cheapest to defer *if* the answer is (b) or (c) —
depth that exists in the model can be surfaced later; depth that was never modelled cannot.

Note the existing pull in this direction: `docs/AUDIT.md` scored adaptivity 2/4 with "no
orientation policy at all", and Phase 4C then locked the app to portrait. That is the right call
for an arcade field and the wrong direction for a data product. The tension is already live.

### 4.3 The 150 ms week advance

Covered in section 3. It does not survive an agent engine and it probably should not survive
contact with a measurement either. The fix is to renegotiate the number honestly — a
0.3–1.0 s week advance with a progress affordance is a fine product, and *hiding* a one-second
advance is a solved UI problem. What must not happen is the budget silently becoming a lie.

Save size is *not* a constraint here, contrary to instinct: 2,200 players at 35 attributes is
under 200 KB. The risk is only if per-play spatial telemetry gets retained. Rule for the pivot:
**store aggregates (snap counts, pressure rates, separation averages, route distribution), never
trajectories.**

---

## 5. What survives, what inverts, what is written off

Roughly 19,200 lines of Swift and 5,145 of tests exist today. The pivot's effect on them is very
uneven, and the good news outweighs the bad.

**Survives untouched (~40%)** — `SeededRandom`, save/persistence/versioning/backup,
`ScheduleGenerator` (394), `StandingsCalculator` (189), `CapEngine` (253), `ContractPricer`
(142), `RecordsBook` (231), `NewsEngine` (169), `LeagueFactory`/`NameBank` (465), `TeamTable`,
the design system, the test harness. None of this cares how a play resolves.

**Survives with extension (~25%)** — `Player`/`Team`/`League` models (add attributes, split
positions), `TradeEngine` (289), `FreeAgencyEngine` (215), `DraftEngine` (345),
`OffseasonEngine` (606), `ProgressionEngine` (175). These get richer inputs, not new shapes.
Note that a deeper positional model *improves* all of them immediately — positional value is
what makes a trade chart interesting.

**Survives but must be re-tuned** — `GameSimulator` (901) is mostly a clock/down/drive/scoring
state machine, and that part is engine-agnostic. Only the resolution call site changes. Its
end-of-game edge cases are the project's hardest-won correctness and must not be re-derived.

**Inverted or demoted (~1,300 lines)** — `PlayResolver` (420), `PlayMatrix` (357),
`PlayExecution` (199), `PlayCaller` (328). Demoted to oracle and calibration target, per 4.1.
Not deleted.

**Promoted, and unverified (2,376 lines)** — all of `Arcade/`. From renderer to engine. Must
compile first.

**At risk of write-off (~2,800 lines)** — this is the part worth thinking about carefully:

- **The coach RPG** (`CoachEngine` 508, `CoachViews` 508, plus `Staff`) — XP, levels, four skill
  trees, skill points. This is structurally anti-FM. FM has no skill tree; a manager's ability
  is expressed through attributes, reputation and the staff they hire. Keeping both is
  incoherent — the player would be buying "Scheme Guru II: offence +2" in a game whose premise
  is that offence emerges from eleven individuals. **If the pivot proceeds, the skill trees
  should convert into coach *attributes* and *staff hires*, which is a re-skin of existing
  mechanics rather than a deletion, and is a strict improvement in coherence.**
- **The arcade mode** (`Arcade/` engine is *promoted*, but ~1,511 lines of arcade UI —
  `ArcadeFieldView` 504, `ArcadeGameModel` 469, `ArcadeGameView` 330, `FieldCanvas` 208 — plus
  the portrait lock and the untuned carrier window from `STATUS.md`'s known gaps) is orthogonal
  to FM. It is also the project's most distinctive feature and the one with proven mobile appeal.

On the arcade mode I would resist the obvious cut. Under an inverted engine it stops being a
bolt-on and becomes *the match engine rendered* — which is exactly what FM's 2D view is, and it
would be strictly better than what exists now, because the motion would be real rather than
pinned to a predetermined yardage. The mode that looks least FM-like today is the one the pivot
most improves. What should be cut is the *pretence that a phone-tuned carrier window is
shippable without a real thumb on it* — that gap has been open since Phase 4C and it should be
closed or the feature parked, either way explicitly.

---

## 6. The audience question

`PRODUCT.md` names its audience precisely and with evidence: the community orphaned by the
*Football Coach* Android lineage, whose successor went Steam-only. That is a documented,
reachable population that wants a mobile-paced coach sim with real cap depth.

The FM audience overlaps but is not the same. It is people who will spend an hour in a tactics
screen and read a scout report as literature. The current `PRODUCT.md` claims to serve both
shapes — "Fast" and "Deep" — with the same screens, and Principle 3 makes that explicit: *depth
lives behind a tap, never behind a mode.*

**An FM pivot reweights hard toward Deep, and Principle 3 is the thing that will bend.** Whether
that is acceptable is the owner's call, not an analysis output. Two observations that should
inform it:

- The competitive niche for a deep pro football front-office sim is *occupied but badly served* —
  Front Office Football, Draft Day Sports: Pro Football, Football Mogul. All PC, all deep, all
  with interfaces from a decade ago. Nobody has shipped a well-designed one anywhere, let alone
  on mobile. That is a genuine opening and it is the strongest strategic argument for the pivot.
- That audience is smaller and considerably more demanding about simulation fidelity. They are
  the users most likely to notice that the offensive line is one number — and also the users
  least forgiving of an emergent engine that has not finished calibrating.

Since distribution is TestFlight and personal use with no App Store release planned, the
audience-size argument carries less weight than it normally would. **Which means the honest
version of this decision is mostly about what the owner wants to build**, and that is a
legitimate basis for it. Worth saying out loud rather than dressing in market reasoning.

---

## 7. Recommendation

Do not treat this as one decision. It is three, they are separable, and their risk/value
profiles are very different.

### D2 first — the depth transplant *(highest value per unit of risk)*

Before any engine work. All of it improves the current engine too, so it is valuable even if
D1 is never taken.

1. **Break open the positional model.** 11 groups → ~20 positions: split the line into LT/LG/C/
   RG/RT, the front into interior and edge, corners into boundary and slot; add FB and returner.
   Touches `Position`, `PlayerFactory`, depth charts, every UI that renders a position, and the
   overall weight tables.
2. **Deepen attributes toward ~25–30 per player, including hidden ones** — consistency, big-game
   temperament, work rate, professionalism, durability, injury history. Hidden attributes are
   what make scouting and player development interesting over a decade, and they are cheap:
   they are integers.
3. **Add scheme as a first-class system.** Team scheme, per-player scheme fit, personnel
   packages, a weekly game plan. This is what turns the front office from a spreadsheet into a
   set of arguments, and it is the single most FM-like thing available without touching the
   engine.
4. **Deepen staff** from three ratings to role-specific attribute sets that multiply systems
   that already exist (training, scouting accuracy, medical, development).
5. **Convert the coach skill trees to coach attributes + staff**, per section 5.

Even against the existing probabilistic resolver, these change what the player is deciding
about. Steps 1 and 3 in particular make the trade, draft and free-agency engines — all already
written and tested — substantially more interesting for very little engine risk.

### D3 second — decide the surface *(gating, cheap to decide, expensive to discover late)*

Answer section 4.2 explicitly in `PRODUCT.md`: (a) iPad in scope, (b) invent the phone idiom, or
(c) accept less depth. My recommendation is **(b), with (a) as a later additive** — a phone-
native depth idiom is where this product could genuinely be the best thing in its category, and
it is the only one of the three that is a differentiator rather than a cost. But it is a design
invention with real risk, and it should be prototyped on one screen (the cap sheet or a player
comparison) before it is committed to in the document.

### D1 last — the engine inversion *(highest risk, staged and reversible)*

1. **Compile and green Phase 4C.** Nothing else in D1 is plannable until this is done. Also
   measure the current on-device week advance while the toolchain is out.
2. **Introduce a `PlayResolving` protocol** with the existing resolver as the default
   implementation. No behaviour change. This is the reversibility mechanism and it costs almost
   nothing.
3. **Extend the kernel to decide, not measure** — defensive agent logic first, since it does not
   exist at all.
4. **Calibrate against the old engine as oracle** — same bands, same seeds, distribution
   comparison as an asserted test.
5. **Ship behind a setting, default off. Flip the default only when the bands hold. Delete
   nothing until a release has shipped on the new default.**

### What I would not do

- **Do not lead with attribute count.** 35 attributes on top of an engine that averages the
  offensive line into one number is strictly worse than 6 — more surface, same causal chain, and
  now the player can see attributes that demonstrably do nothing.
- **Do not delete the probabilistic resolver.** It is the oracle, and it is the fallback if
  calibration stalls.
- **Do not drop the two-minute session.** The "advance the week on the bus" promise is the
  product's mobile reason to exist and does not conflict with depth. FM's own Instant Result
  button is the proof.
- **Do not rewrite `PRODUCT.md` as a whole.** Amend the specific lines the decisions above
  change: the 150 ms budget, the compact-width commitment, Principle 3's "never behind a mode",
  and the not-in-v1 list. A wholesale rewrite would discard the parts that are well-evidenced —
  the audience, the durability commitment, the fictional-identity rule — for no reason.

---

## 8. Open questions for the owner

These change the work materially and cannot be resolved from the codebase.

1. **Surface:** (a) iPad in scope, (b) invent the phone idiom, or (c) less depth? *Gates
   everything downstream.*
2. **Does the coach RPG stay?** Skill trees and emergent simulation are philosophically opposed.
   Converting them to attributes and staff is the coherent path, but it is a real feature change
   for a system that is built and tested.
3. **Is the arcade mode still a pillar?** It survives the pivot well and improves under it, but
   it is also the least FM-like thing in the product and the one with an open, device-dependent
   tuning gap.
4. **What is the actual tolerance for an uncalibrated engine?** If the answer is "the bands must
   hold at all times", D1 is a long project behind a feature flag. If it is "I'll play a
   half-tuned engine for a few months to get emergence", it is much shorter.
5. **Is this a product decision or a builder's decision?** With TestFlight-only distribution the
   market argument is weak, and "I want to build the deep one" is a sufficient and honest reason.
   Saying which it is will keep the next six months of scope arguments short.

---

## Appendix — the single most persuasive fact

`Arcade/SnapKernel.swift:56-59`:

> *"Deliberately not an outcome: the kernel says what the player did and what the geometry was,
> never whether it worked."*

Everything the pivot needs is on the correct side of that sentence. What it asks for is the
sentence's deletion.
