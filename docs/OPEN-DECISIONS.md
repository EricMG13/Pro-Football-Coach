# Open Decisions — D1–D14

The decision register required by `docs/reviews/2026-08-09-spec-prompt-v4.md` §5. Every decision
carries: options considered, the choice, the reason, **a falsifier that names its instrument**, and
the cost of reversing it.

A falsifier without an instrument is decoration. Under P5 there is no playtest cohort and no
telemetry, so "players would tell us" is not a falsifier. Every entry below names the thing that
would actually run: a test, a band, a harness, or an owner protocol with a metric and a threshold
fixed in advance.

**Status key.** `DECIDED` — settled, build against it. `DECIDED (REVERSIBLE)` — settled on stated
assumptions, cheap to change. `ESCALATED` — blocking owner question, do not build past it.

| ID | Decision | Status |
|----|----------|--------|
| D1 | In-match agency model | DECIDED |
| D2 | Match engine architecture | DECIDED |
| D3 | Two-tier simulation | DECIDED |
| D4 | Performance budgets | DECIDED (REVERSIBLE) |
| D5 | College/pro system design | DECIDED |
| D6 | Fictional identity strategy | DECIDED |
| D7 | Save architecture and migration | DECIDED |
| D8 | Difficulty, jeopardy and failure | DECIDED |
| D9 | Onboarding and first session | DECIDED |
| D10 | AI quality | DECIDED |
| D11 | Test strategy under the real toolchain | DECIDED — harness verified green on the owner's machine |
| D12 | Accessibility contract | DECIDED (REVERSIBLE) |
| D13 | Content volume | DECIDED |
| D14 | Build order and league size | DECIDED (REVERSIBLE) — added in v4 execution |

---

## D1 — In-match agency model

### The arithmetic, before the choice

P4 fixes a season at 6–8 hours. Take **7 hours = 420 minutes** as the working figure and state the
season's shape:

| | College | Pro |
|---|---|---|
| Regular season | 12 games | 17 games + 1 bye |
| Post-season | conference championship + up to 4 playoff | up to 4 playoff |
| In-season weeks | ~17 | ~21 |
| Snaps your team is on the field for | ~150 (higher tempo) | ~130 |

Budget allocation, stated rather than assumed:

```
420 min total
 -90 min offseason (recruiting class, portal, draft, free agency, staff)
= 330 min in-season / ~20 weeks
= 16.5 min per week, inclusive of the match
```

Split that week: **~10.5 min match, ~6 min management.** Every candidate below is priced against
630 seconds of match time.

### Options priced

| Option | Decisions/game | Arithmetic | Season match total | Verdict |
|---|---|---|---|---|
| **A. Every-snap play-calling** | ~130 | 130 × (3 s decide + 4 s watch) = 910 s = 15.2 min | 304 min | **Fails.** Leaves 116 min for 20 weeks of management *and* the whole offseason. Also 15 minutes of continuous per-snap tapping is precisely what FM Mobile removed from desktop (§6.1). |
| **B. Situational call-ins + coordinator AI** | ~25 | 25 × 8 s = 200 s decisions + 24 drives × 15 s drive-level presentation = 360 s → 560 s = 9.3 min | 186 min | **Fits with slack.** 144 min left for management and offseason. |
| **C. Game plan + in-drive adjustments + high-leverage only** | ~12 | 12 × 8 s = 96 s + 360 s = 456 s = 7.6 min | 152 min | Fits easily. Thinner. |
| **D. Pure spectate + halftime** | ~2 | ~360 s = 6 min | 120 min | **Fails on the other side.** ~40 in-match decisions per season is a results screen with animation. |

Note what A is not: calling a play is a *coach* action, so option A does not violate the mission's
"no direct control of players during play." It fails on P4 alone.

### Choice: **B — situational call-ins with a coordinator AI, at a tunable call-in rate.**

The player sets a game plan pre-match (management time), the coordinator AI calls the majority of
snaps inside that plan, and the player is pulled in on flagged situations: fourth down, red zone,
two-minute, third-and-long, after a turnover, and any snap the game plan has left genuinely open.
The call-in rate is a difficulty/pacing setting spanning C (≈12) to just under A (≈40), with B's ~25
as the default.

### Why

§6.0 established what actually went wrong, and it was not the match: **the previous build's
management week contained exactly one mandatory decision, and it was a decision about presentation
rather than about the team.** The cure is decision density with consequence, and B supplies ~25
per game plus the week's management — roughly 500 consequential decisions a season against the
prior build's ~20.

B also survives the finding that should have been alarming: **the arcade layer held about 99% of
the previous build's decision volume**, and the mission removes it. Removing 99% of the decisions
without replacing them is how a rebuild becomes a better-looking bland application. B replaces them
with coach decisions rather than thumb decisions.

The tunable rate is not fence-sitting. It is the one parameter the arithmetic is most sensitive to,
and P5 provides no cohort to tune it against — so it ships as a player-facing setting and the
default moves when the owner protocol (§6.0 §8) produces a number.

### Falsifier — instrument: `AgencyBudgetTests`, a timing harness in the test suite

The model is falsified if, with the default call-in rate:

- median measured match time exceeds **11.5 min** (10% over the 10.5 budget), or
- a season's total measured play time exceeds **8 hours**, or
- fewer than **15** call-ins per game fire at the default rate across 200 simulated games (the
  coordinator is swallowing the game), or
- more than **40** fire (the player is being nagged).

The harness counts call-in events and multiplies by the presentation constants in `03`; it does not
need a human. The human protocol (§6.0 §8) sets the per-decision seconds it multiplies by, and
until it runs, those constants are **ASSUMPTION** and labelled so in `03`.

### Cost of reversal

**Low within B↔C, high toward A or D.** B and C differ by a rate constant. Moving to A requires a
per-snap UI and a different presentation model; moving to D removes the call-in system entirely and
would strand the game-plan design in `02`.

---

## D2 — Match engine architecture

**Options.** (a) Agent-based per-snap resolution with continuous physics; (b) play-outcome
distribution model with a visualisation layer; (c) hybrid assignment/leverage resolution without
continuous physics.

**Choice: (c) hybrid assignment/leverage resolution.**

The engine resolves a snap as a set of *matchups* — each blocker against each rusher, each receiver
against each defender, the run lane against the front — scored from ratings, scheme fit, fatigue and
the called play, and combined into an outcome. No continuous physics, no tick-level integration.
The `Canvas` view then renders motion whose **last frame is pinned to the recorded outcome**.

**Why.** (a) makes determinism expensive and calibration nearly impossible — you cannot tune a
physics system to hit a completion-rate band without fighting it. (b) cannot answer "why did that
happen", which is the entire information payload of a coaching game: the player must be able to see
that the left tackle lost, not merely that the sack occurred. (c) gives per-matchup causality that
the UI can narrate, while keeping the probability mass in one place where it can be calibrated.

The prior build reached the same conclusion the expensive way and the lesson transfers: its
`SnapKernel` measured matchups while **the engine still owned every probability**. That separation
is the reusable part.

**Falsifier — instrument: the calibration harness in `03` plus `DeterminismTests`.**
Falsified if the matchup model cannot be tuned to hold every band in `03` simultaneously — that is,
if fixing completion rate breaks sack rate and no parameter set holds both — across 5 consecutive
tuning attempts. Or if per-snap resolution cannot meet D4's frame budget.

**Cost of reversal: very high.** `03` and `04` both assume matchup-level causality is available to
narrate. Moving to (b) after `04` is written invalidates the match view's information design.

---

## D3 — Two-tier simulation

**The numbers the brief made explicit, restated because they drive everything:** the off-screen
slate is **~15 games a week in the pro league** (32 teams) and **~65 a week in the college league**
(~134 programmes) — plus recruiting and transfer-portal AI for every one of those programmes, which
is plausibly a larger cost than the game simulation itself.

**Choice.** Two models, one contract.

- **Detailed model** — the played game. Full matchup resolution per snap.
- **Abstracted model** — off-screen games. Resolves at drive level from team-strength distributions
  conditioned on scheme matchup, home advantage and fatigue/injury state, producing a box score with
  per-player stat lines but no play-by-play.

**The consistency requirement, stated as a hard requirement with its test named.** Over a
1000-season Monte Carlo, the season-level distributions produced by both models must be
*statistically equivalent*, not merely both-inside-a-range:

- **Test: TOST (two one-sided tests) at α = 0.05**, pass iff the 90% confidence interval for the
  difference between models lies entirely within the equivalence margin.
- **Margins:** points per game ±0.75; yards per play ±0.15; completion rate ±1.5 pp; sack rate
  ±0.6 pp; turnover rate ±0.4 pp; win-rate-vs-rating-gap curve ±2 pp at every 5-point bucket.
- **Plus a distribution-shape check:** total variation distance between the two models' points-per-
  game histograms ≤ 0.06.

Range membership is explicitly rejected as the instrument. §6.4 established why: a model whose true
home-win rate is 0.62 passes a `0.50…0.60` range check about **1 run in 6** at n = 600, because the
check has no notion of sampling error. TOST inverts the burden of proof onto the model.

**Falsifier — instrument: `TwoTierConsistencyTests`.** Falsified if TOST fails on any listed metric,
or if holding consistency forces the abstracted model to become slow enough to break D4.

**Cost of reversal: high.** A single-model design (simulate everything in detail) is the only
alternative and it is priced out by D4.

---

## D4 — Performance budgets

Derived from the **college** case, which is the worse one, on the oldest supported device
(iPhone 12-class, A14).

| Budget | Target | Hard ceiling | Notes |
|---|---|---|---|
| Week advance, college (~65 games + recruiting/portal AI for ~134 programmes) | 1.2 s | **2.0 s** | The dominant term is recruiting AI, not game sim |
| Week advance, pro (~15 games) | 0.3 s | 0.6 s | |
| Full-season sim, college | 20 s | 35 s | Used by the soak, and by "sim to end of season" |
| Match render frame budget | 8 ms | **16.7 ms** | 60 fps floor; `Canvas` + `TimelineView`, 22 marks |
| Save size, 20 seasons | 4 MB | **8 MB** | Prior build: 8.3 MB unbounded → 2.3 MB bounded, at 32 teams. ~134 programmes plus recruiting history is a materially larger object |
| Cold launch to playable | 1.2 s | 2.0 s | |
| Save write (off main actor, always) | 150 ms | 400 ms | The prior build's single P0 was a 2.4–3.3 MB synchronous main-actor save at 11 call sites |

**Reversible, and here is the trigger.** The recruiting-AI cost across ~134 programmes has never
been measured — §6.4 and §6.2A both flag it as an assumption on an assumption. If measurement shows
the 2.0 s ceiling cannot be met, the lever is **D14's programme count**, not the ceiling.

**Falsifier — instrument: `PerformanceBudgetTests` + Instruments trace on device.** Falsified if any
hard ceiling is exceeded on the oldest supported device at the shipping programme count.

**Cost of reversal: low for the numbers, high for what they imply.** Loosening the week-advance
ceiling changes the felt pace of the whole game.

---

## D5 — College/pro system design

P2 is a unified career, so both systems ship in v1 and the promotion arc is a v1 feature.

| Dimension | College | Pro |
|---|---|---|
| Talent in | Recruiting (multi-cycle, relationship-based) + transfer portal | Draft + free agency + trades |
| Talent out | Graduation, early declaration, portal departure | Retirement, release, expiry |
| Roster | ~85 scholarship + walk-ons | 53 + practice squad |
| Money | Scholarships (a count, not a currency) + NIL budget | Salary cap, proration, dead money |
| Clock | 4 years eligibility + redshirt | Contract years |
| Structure | Conferences + realignment pressure | Divisions, fixed |
| Post-season | Bracket + bowl tier | Seeded bracket |
| Job market | Coaching carousel, ~15 openings/year | Carousel, ~6 openings/year |

**Shared:** the match engine, the two-tier sim, the ratings model, progression and development,
staff, scheme identity, the news/record systems, and the save format. **Not shared:** the acquisition
loop, the money model, the eligibility model, and the post-season shape.

**The promotion arc.** A pro job offer becomes reachable when college reputation crosses a
threshold that also depends on the pro league's opening slate. What carries across: coach reputation,
scheme identity, a subset of staff, the record book, and the career line. What does not: players,
recruits and any college currency. The move is **one-way by default**, with a demotion path if the
pro job ends badly — the carousel can never dead-end (a prior-build invariant worth keeping).

**On positioning, per §6.3:** the arc is *a real feature and a weak differentiator*. It is shipped
elsewhere (Winning Tradition on iOS; DDS on desktop with universe import) and no community in the
research asked for it. `PRODUCT.md` must not lead with it. It is a retention device — a structural
answer to the hollowing that §6.2B found in the closest competitor, where acquisition is mastered
and nothing else deepens.

**Falsifier — instrument: `CareerArcTests` + the 20-season soak.** Falsified if the promotion
threshold is reachable in under 4 college seasons at median play (it should be earned), or is
unreachable in 12 (it should not be a myth), across 200 seeded careers.

**Cost of reversal: very high.** It is P2.

---

## D6 — Fictional identity strategy

The hard problem: college football's emotional payload is rivalry, tradition and place, all of which
must be manufactured from original IP. §6.2B found that no incumbent has solved this — it is the
genre's open problem, not a compliance tax.

**Choice: endogenous identity.** Identity is not authored and attached; it is *accumulated by the
save*. Concretely:

1. **Archetypes, not names.** ~14 programme archetypes (land-grant power, private academic, service
   academy, commuter school, regional riser, fallen blueblood…), each with a prior over resources,
   fanbase volatility, academic constraint, recruiting reach and scheme inheritance.
2. **Geography first.** A generated map of regions and cities, with distance driving recruiting
   reach, travel fatigue and natural rivalry candidates. Place is a mechanic, not flavour text.
3. **Rivalries are earned, then remembered.** A rivalry is seeded from geography and conference, and
   then *strengthened by what happens*: consecutive close games, upsets, title-deciding meetings.
   The rivalry record is a first-class save object with its own narrative line.
4. **Traditions with mechanical consequence.** Each programme generates 2–4 traditions from a
   grammar; each has a real effect (a home-field modifier on a specific week, a recruiting bonus in
   a region, a morale effect after a specific outcome). A tradition the player cannot feel in the
   simulation is decoration.
5. **Conference politics.** Realignment pressure is a simulated system driven by performance,
   market and geography, so the map the player inherits is not the map they leave.

**The two Tier A tests are the guardrail** (see the legal section of `CLAUDE.md`): the name-collision
test and the trade-dress ΔE test, both run across N generated leagues at many seeds.

**Falsifier — instrument: `IdentityDistributionTests` + the owner protocol.** Falsified if, across
200 generated leagues, rivalry intensity does not separate (top decile vs median indistinguishable),
or if programme archetype cannot be inferred from a programme's generated properties by a simple
classifier — meaning the archetypes are cosmetic. Owner-side: after 5 seasons the owner should be
able to name 3 rival programmes and why they matter, unprompted; if not, identity has not
accumulated.

**Cost of reversal: high.** Endogenous identity shapes the save format (D7) and the news systems.

---

## D7 — Save architecture and schema migration

**Format:** a single versioned JSON document per save, gzip-compressed on disk, written off the main
actor, with an atomic replace and one backup generation. No third-party dependency, human-inspectable
when uncompressed, and forward-compatible via unknown-field defaults — a property the prior build
proved out and should keep.

**Bounds — every collection that can grow across seasons carries one.** This is the lesson that took
the prior build's save from 8.3 MB to 2.3 MB:

| Collection | Bound |
|---|---|
| Free-agent / unsigned pool | 400 |
| News feed | 200 stories, ring buffer |
| Recruiting classes retained | current + 1 prior in full, older as aggregates |
| Portal pool | 300 |
| Play-by-play | current game only; finished seasons keep aggregates |
| Rivalry history | full, but as compact per-meeting records |
| Record book | top 50 per category |
| Retired players | name + career aggregates only |

**Migration policy:** the save carries `schemaVersion`. Migrations are forward-only, one step at a
time, each a pure function with a fixture test at every version boundary. A save from a newer
version is refused with a plain message rather than opened.

**Falsifier — instrument: the 20-season soak.** Falsified if a 20-season college→pro career exceeds
the 8 MB hard ceiling, or if any bounded collection is found unbounded by the soak's growth check.

**Cost of reversal: high after ship, low before.**

---

## D8 — Difficulty, jeopardy and failure

The prior build's failure here is documented and specific: **job security was recomputed once a
year**, so the number shown to the player could not move for ~20 weeks. Jeopardy that cannot change
is not jeopardy.

**Choice.** Pressure is continuous, legible, and sourced from named people.

- **Weekly recomputation** of job security from results against expectation, not raw record.
- **Expectation is set by a board/AD with a stated preseason target** the player can see, so
  overperforming a bad team is rewarded and underperforming a good one is punished.
- **Named stakeholders** — the AD, a booster bloc, the fanbase, the locker room — each with a
  visible disposition and their own trigger conditions. Pressure arrives as an *inbound event from
  someone*, which is the thing §6.0 found entirely absent: **zero inbound events; the game never
  initiated a conversation.**
- **Firing** happens in-season if security bottoms out, not only at year end.
- **The carousel can never dead-end** — always at least one offer or an explicit year out.

**Falsifier — instrument: `JeopardyTests` + the soak.** Falsified if, across 200 seeded careers,
median coach tenure exceeds 9 seasons (nothing threatens the player) or falls below 2.5 (the game is
capricious); or if job security is observed unchanged across more than 4 consecutive weeks while
results are moving.

**Cost of reversal: medium.**

---

## D9 — Onboarding and first session

**The first fifteen minutes**, and what the player understands at the end of them:

| Minutes | What happens | What it teaches |
|---|---|---|
| 0–2 | Pick a programme from 3 offered jobs, each with a visible expectation and a visible constraint | The job is a choice with stakes; expectation ≠ record |
| 2–5 | The AD states the season target. One recruit conversation arrives unprompted | Someone is watching; the game initiates |
| 5–11 | Week 1: set a game plan (3 choices), play the match with call-ins at the default rate | The core loop; that calls have consequences |
| 11–14 | Post-match: one development decision, one depth-chart consequence of an injury | Results feed the roster |
| 14–15 | The week advances; the next opponent's tendency is previewed | There is a next turn, and it is already interesting |

By minute 15 the player has: made a job choice, met a stakeholder, set a plan, made ~25 in-match
calls, seen a consequence, and been shown a reason to advance. No tutorial cards. The prior build's
five cards shown once are replaced by teaching through the first real week.

**Falsifier — instrument: owner protocol, threshold fixed in advance.** A first-time player who has
never seen the game reaches the end of week 1 within 15 minutes without asking a question, and can
then state what their job depends on. Falsified if either fails on 2 of 3 attempts.

**Cost of reversal: low.**

---

## D10 — AI quality

§6.2A confirmed AI quality is the dominant complaint across the deep-sim pole. Under D1's chosen
model the coordinator AI is calling ~105 of ~130 snaps, so it is not a background system — it is
most of the match.

**Choice.** Three AI systems, each with an explicit quality bar and its own test suite:

1. **Coordinator AI** (calls plays inside the player's game plan). Bar: against a fixed opponent it
   must beat a random-legal-call baseline by a stated margin on expected points added, and must not
   be exploitable by a fixed counter-strategy over 500 games.
2. **Roster AI** (recruiting, portal, draft, free agency, cap). Bar: no AI team ends a season
   illegal; AI-built rosters must not be systematically worse than the player's at equal resources —
   measured as rating-per-dollar and rating-per-scholarship across the soak.
3. **Opponent game-plan AI** (sets the other team's plan and adapts). Bar: measurable adaptation —
   a player who runs the same call 10 times must see the counter rate rise.

**The anti-cut rule:** each bar is a phase gate in `05`, not a polish item. AI quality is the thing
that gets cut when the schedule slips, and naming it as a gate is the only defence available under
P5.

**Falsifier — instrument: `CoordinatorAITests`, `RosterAITests`, `AdaptationTests`.** Each bar above
is directly a test. Falsified when a bar fails.

**Cost of reversal: high.** D1's model depends on the coordinator being trustworthy enough to hand
105 snaps to.

---

## D11 — Test strategy under the real toolchain — **DECIDED**

> **Amended after inspecting the repo.** D11 was first written as wholly blocking. That was wrong,
> and the correction matters because it unblocks most of P0. The question decomposes:
>
> **(a) What framework runs the tests? — DECIDED, from evidence.** The prior build already solved
> this and the solution is in the tree: `Tests/SimTests/TestKit.swift` is a ~50-line hand-rolled
> harness with real exit codes and zero dependencies, run as an executable target via
> `swift build && swift run -c release SimTests`. **Verified 2026-08-09 on the owner's machine
> (Swift 6.3.3): build green, 299 tests, 18,412 checks, all passed, 71.7 s.** It
> needs only the Swift Command Line Tools — **not full Xcode** — because neither XCTest nor
> swift-testing ships outside Xcode. Port it (see `docs/PORT-LOG.md`).
>
> **(b) Who actually runs it? — ESCALATED.** This is the real open question, and no amount of
> design resolves it.

Verified in this container, not assumed: `swift`, `swiftc`, `xcodebuild`, `xcrun` and `simctl` are
all absent; `download.swift.org` returns **403 on CONNECT** through the egress proxy; Ubuntu's
`swift` packages are the unrelated OpenStack object store; there is no Docker daemon
(`/var/run/docker.sock` does not exist). There is no sanctioned route to a toolchain from inside an
agent environment, and routing around the policy is forbidden.

So the remaining question is purely operational:

- This container has no `swift`, no `swiftc`, no `xcodebuild`, no `xcrun`, no `simctl` (verified).
- `docs/STATUS.md` records the same historically, plus `download.swift.org` refused by egress policy
  with a 403 on `CONNECT`.
- Neither XCTest nor swift-testing ships with the Swift Command Line Tools, which is why the prior
  build ran its suite as an executable target with a hand-rolled harness.
- Phase 4C shipped **never having been compiled** as a direct result.

Every "tests green" gate in `05` and the entire machine-verifiable half of the definition of done
depend on the answer.

**What the owner must decide — pick one:**

1. **Lift the egress rule for `download.swift.org`**, or supply a pre-baked image with the Swift
   Command Line Tools. Cheapest by far: the harness already runs on Command Line Tools alone, so
   this makes every machine gate agent-assertable and D11 closes completely.
2. **The owner's Xcode machine becomes the CI.** Agents write, the owner runs `swift build &&
   swift run -c release SimTests` at phase boundaries, results come back as the gate. Workable, but
   every phase gate becomes a synchronous human step and `05` must batch phases around it.
3. **Neither.** Then phase gates are asserted against a harness no agent can run, which is not a
   gate but a promise — and the package must say so in those words.

**Recommendation: option 1, falling back to option 2.** Option 1 is a one-line policy change that
removes a permanent tax from every future phase. Option 2 works today without anyone's permission.
Option 3 is how Phase 4C shipped uncompiled.

**Falsifier — instrument: for (a), the harness itself.** It has now run 299 tests and 18,412 checks
green on Swift 6.3.3; if a ported harness cannot reproduce that, (a) was wrong. For (b) there is no
instrument, which is exactly what makes it an owner question rather than a design question.

**Cost of reversal: low for (a)** — the harness is ~50 lines and swapping it for swift-testing later
is mechanical. **High and increasing for (b)** — every phase built before it is answered may be
built against a gate nobody can run.

---

## D12 — Accessibility contract

The prior build scored **1/4** on accessibility with Reduce Motion at literally zero occurrences and
3 accessibility modifiers across ~140 KB of view code, against commitments it had written down for
itself. `04b`'s ≥17/20 gate is unreachable without fixing this.

**The contract** (full form in `04`):

- **Contrast:** every foreground/background pair is composited and measured, in both appearances,
  at ≥4.5:1 for body text and ≥3:1 for large text and non-text indicators. Enumerated **by
  construction** — the test walks the token set and every surface that consumes it, so a new surface
  is covered the day it is added. This is the direct answer to `AUDIT.md`'s systemic pattern 1.
- **Dynamic Type:** every screen legible at AX5 with no clipping and no fixed-height text container.
  The prior build had 19 fixed-width frames that clipped scaling text.
- **Reduce Motion:** every animation has a defined reduced form. For the match view specifically,
  Reduce Motion replaces continuous motion with a **discrete state sequence** — snap, key moment,
  outcome — rather than disabling the view.
- **VoiceOver:** the match view emits a per-snap textual description built from the same matchup
  resolution the animation draws from, so the audio description and the picture cannot diverge.
- **Touch targets:** 44×44 pt minimum, enforced by test rather than by review.

**Reversible on one point, flagged honestly:** three premises behind this contract could not be
verified — `developer.apple.com` returned no readable body through the proxy. The 44 pt floor,
Apple's exact Reduce Motion semantics, and the SwiftUI API surface for suppressing `TimelineView`
updates are all cited from memory and marked UNVERIFIED in `01-RESEARCH.md`. **Confirm against the
HIG before implementing** — building an accessibility contract on unverified guidance reproduces
exactly the failure `AUDIT.md` pattern 1 names.

**Falsifier — instrument: `AccessibilityContractTests`.** Falsified by any surface failing any
clause. The by-construction enumeration is itself falsifiable: a test asserts that the count of
surfaces the contrast suite visits equals the count of surfaces that consume a colour token.

**Cost of reversal: low as a contract, very high as an afterthought.**

---

## D13 — Content volume

The brief asks for an authoring budget **in hours**. Under D6's endogenous-identity choice most
content is generated, so the authoring cost is in *grammars and tables*, not in per-programme prose.

| Asset | Authored | Estimate |
|---|---|---|
| Programme archetypes | 14, hand-written with priors | 10 h |
| Region/city map grammar | 1 generator + ~40 region seeds | 12 h |
| Name banks (given, surname by region, programme, city, stadium, nickname) | ~6 tables, 400–2000 entries each | 20 h |
| Tradition grammar | ~30 templates with mechanical hooks | 14 h |
| Rivalry narrative lines | ~60 templates | 8 h |
| News templates | ~120 across all systems | 20 h |
| Play/scheme content | ~40 offensive concepts, ~24 coverages/fronts | 24 h |
| Copy (UI strings, stakeholder voices) | — | 16 h |
| **Total** | | **~124 h** |

Plus the blocklist for the name-collision test, which is maintenance rather than authoring.

**Falsifier — instrument: a generation-diversity test.** Falsified if generated output is
insufficiently varied — measured as: no name repeats within a league; ≥90% of programmes carry a
distinguishable tradition set; news headline repeat rate under 2% within a season. If the tables are
too small, this test fails and the budget was wrong.

**Cost of reversal: low.** Tables grow.

---

## D14 — Build order and league size *(added during v4 execution)*

Not in the brief's register, but forced by it: P2 fixes *that* both tiers ship, not *which is built
first* nor *how large the college world is*. Both are load-bearing on D3, D4 and D13. Offered to the
owner and not answered, so decided here and flagged as reversible.

**Choice: college first, at ~134 programmes, with a stated fallback.**

**Why college first.** The player starts in college, so the first hour is a college hour — and §6.3's
strongest finding is that the arc is a bridge from a place the player must already want to be. Both
unsolved risks live in the college tier: D3/D4's scale problem and D6's identity problem, which no
incumbent has solved. Building pro first defers both to the end of the schedule, which under P5 is
how they end up unsolved.

**Why ~134.** §6.4 found the real FBS talent distribution has a ~64-point spread, and called it the
single most design-relevant statistic in the document for D6 and the promotion arc. A flat league
gives the career no gradient to climb. Because D6 generates from archetypes, the cost of scale lands
in D4 (weekly sim + recruiting AI) rather than in D13's authoring hours.

**The fallback, stated in advance so it is not a retreat.** If D4 measurement shows the 2.0 s
week-advance ceiling cannot be met at 134, reduce to **~64 in two conferences** before loosening the
ceiling. Felt pace is worth more than programme count.

**Falsifier — instrument: `PerformanceBudgetTests` at the shipping count, plus D6's
`IdentityDistributionTests`.** Falsified if 134 cannot meet D4, or if identity fails to differentiate
at that scale (a large flat league is worse than a small textured one).

**Cost of reversal: medium before the engine exists, high after.** The programme count is a constant;
what it costs to change is the tuning built around it.
