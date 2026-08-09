# Open Decisions — D1–D13

Every significant decision, with the options considered, the choice, the reason, **what evidence
would falsify it**, and the cost of reversing it later.

**Every falsifier names its instrument** — a soak assertion, a calibration band, a timing harness, a
determinism test, or an owner play-session protocol with a metric and a threshold *stated in
advance*. Under P5 there is no playtest cohort and no telemetry, so *"we would notice if players
disliked it"* is not available. A falsifier without an instrument is decoration.

**Blocking questions are at the top.** They are not resolved by a silent default.

---

## 🔴 Blocking — owner input required

### B1 — The engagement post-mortem was never run

**The problem.** The brief's §6.0 says the highest-value evidence is playing the existing build:
*"it is cheap: the app builds and runs."* The brief's §8 says *"this container has no `swift` and no
`xcodebuild`."* Both cannot be true of the same session, and the second one is. So the package's
primary evidence about the actual failure does not exist.

**What was done instead.** A static decision-surface census (`01-RESEARCH.md` §6.0b) plus the
competitive evidence in §6.2. That census is a real measurement of a real thing — the code offers
**one** branching decision per in-season week — and it is genuinely convergent with the market
signal, since the genre's best-reviewed title is criticised for the same defect. But it measures
affordances, not attention. **It cannot tell you when a player puts the phone down.**

**Why this blocks.** D1 is the most consequential decision in the project and it is currently
resolved on arithmetic and inference. If the owner's play session finds the built week already
engaging at 1–3 decisions, the diagnosis is wrong and the whole design premise changes.

**The ask.** Run `01-RESEARCH.md` §6.0a — six weeks, stopwatch, thresholds fixed in advance —
**before P7 closes.** Not before P6: the week is worth building either way. Before P7, because the
match surface is where the expensive, hard-to-reverse work is.

### B2 — Licensing posture on calibration sources

**The problem.** §6.4 sets college calibration band centres from published national per-game
averages. Underlying sporting facts are not copyrightable in the US, but a commercial aggregator's
compiled presentation may be governed by its terms of use — and the band constants would live in a
test file in a shipped repository.

**The recommendation, which needs a decision rather than an assumption.** Source every band centre
from a **primary official statistics publication** rather than a commercial aggregator, and record
the source in a comment next to each band. That removes the question rather than answering it.

**The ask.** Confirm the primary-source-only rule, or take the question to counsel. **Flagged, not
resolved here**, per the Tier A guardrail.

### B3 — The `/impeccable` rubric is reconstructed, not verbatim

`04b-AUDIT-RUBRIC.md`'s 0–4 anchors are inferred by working backwards from the scores the audit
assigned to specific evidence, because the tool was unavailable. Every phase gate cites that rubric.

**The ask.** Run `/impeccable audit` once on any surface and paste its real dimension anchors and
severity definitions over `04b` §§2–3. Until then the gate is measurable but not exact, and a future
tool run may disagree — in which case **the tool wins**.

---

## D1 — In-match agency model

**Options:** every-snap play-calling both sides · every-snap offence only · pure spectate with
halftime adjustment · situational call-ins with coordinator AI · **pre-set game plan + in-drive
adjustments + discrete high-leverage decisions**.

**Chosen: the Sideline Model** — game plan set during the week, drive-level watching, ~14–16 discrete
interventions, in-drive adjustment when the opponent shifts, opt-in snap-level fidelity. **The player
does not call individual plays and does not call defence per snap.**

**Reason.** Arithmetic (`02` §3). Every-snap calling costs 19.5 min/game pro and 25.5 college against
an 18 min weekly budget — it fails before any management time is priced. Offence-only survives pro
and fails college, and college is the binding tier. Pure spectate spends 72% of the budget to deliver
no agency. The Sideline Model prices at 14.2 min (pro) and 17.2 min (college) per week and clears.

**Falsifier + instrument.**
1. **Timing harness** (P7 gate): if measured wall-clock per default-fidelity match exceeds 7.5 min
   pro, the model is over budget.
2. **Decision-surface census** (P6 gate): if the week offers fewer than 5 meaningful decisions, the
   model has not fixed the diagnosis.
3. **Owner play protocol** (§6.0a thresholds): if the owner, unobserved at week 7, chooses a mode
   that gives more moment-to-moment control, then a tactile layer is load-bearing and D1 is wrong.

**Fallback if the presentation budget fails:** drop default granularity from snap-level to
**drive-summary** — animate the drive's decisive play, not every snap. `02` §3.5's sensitivity table
is the map.

**Cost of reversal.** **High after P7.** The agency model determines the engine's required fidelity,
the UI's information architecture and the season's shape. Reversing before P6 is cheap; after P7 it
is most of a rebuild — which is why B1 is gated on P7 rather than on ship.

---

## D2 — Match engine architecture

**Options:** agent-based per-snap resolution with continuous physics · play-outcome distribution with
a visualisation layer · **hybrid assignment/leverage resolution without continuous physics**.

**Chosen: hybrid assignment/leverage.** The engine resolves a snap structurally — assignments,
matchups, ordered decision points, each one seeded draw — and the `Canvas` choreographs the resolved
outcome with its last frame pinned to the recorded yardage.

**Reason.** It is the only candidate that can say *why*. `PlayResult` carries the decisive matchup,
which is what makes an adjustment meaningful, the play-by-play readable, and the render legible by
letting three dots out of twenty-two be emphasised. Agent-based physics cannot be calibrated to a
band and creates a floating-point determinism problem. A distribution model with a visual layer
recreates the divergence bug the reference app's community worked around by always watching games.

**Consequences:** determinism is integer draws; save size is unaffected (nothing spatial is
persisted); testability is per-decision-point; calibration is per-band.

**Falsifier + instrument.** The **calibration suite** (`03` §5): if bands cannot be met without
per-band fudge factors that contradict each other, the model lacks the degrees of freedom and needs
another decision point. The **render budget** (≤8 ms/frame): if choreography cannot hit it, the model
is emitting too much detail.

**Cost of reversal.** High. It is the engine.

---

## D3 — Two-tier simulation

**Chosen:** detailed model for your one game; **possession-level abstract model** for the off-screen
slate (~15 games/week pro, ~65 college); tiered recruiting AI for ~134 programmes.

**Consistency requirement — a hard gate.** 200 detailed vs 200 abstract seasons compared with a
**two-sample Kolmogorov–Smirnov test at α = 0.01** on per-team season totals, plus mean-difference
bands, **blowout frequency within ±3pp** and standings dispersion within ±0.4 wins.

**Reason.** Without a binding consistency requirement, the league's statistics and the player's own
game come from different universes — standings become nonsense and no player trusts the sim.

**Falsifier + instrument.** The KS gate itself (P4). It blocks the phase; it is not a warning. The
blowout band is the specific test of assumption A9 (that college is a widened talent distribution
over the same engine) and is the one most likely to fail first.

**Cost of reversal.** Medium. Raising abstract fidelity costs week-advance budget; lowering it breaks
the gate.

---

## D4 — Performance budgets

**Chosen, derived from the college case** (`03` §8): week advance college **≤800 ms** (target 500),
pro ≤250 ms; full college season ≤25 s; render ≤8 ms/frame; save write ≤100 ms **off the main
actor**; save size at season 20 ≤10 MB (target 6); cold launch ≤1.5 s.

**Reason.** The prior build's pro-only budgets do not carry: college is ~4.3× the games plus a
recruiting pass that is plausibly larger than the games themselves, and ~5× the player count.

**Falsifier + instrument.** Each budget is a test — soak assertions for week advance and save size,
an on-device measurement for render and launch recorded in `STATUS.md`. If college week advance
cannot reach 800 ms, **assumption A5 is false** and D3's recruiting tiering has to get more
aggressive or recruiting must move off the advance path entirely.

**Cost of reversal.** Low to state, high to meet. Numbers can be changed in a commit; the honest
failure mode is quietly missing them, which is what a test prevents.

---

## D5 — College/pro system design and the promotion arc

**Chosen** (`02` §§5–7): college runs 85/105 rosters, eligibility clocks, redshirts, interest-based
recruiting with promises, a two-way portal, and NIL as a programme pool; pro runs 53+16, a hard cap
with proration and dead money, a 7-round draft, free agency and trades. Promotion is triggered by a
**reputation** score against team needs; offers arrive as coordinator roles at good teams and head
coach roles at bad ones. Reputation, scheme identity, willing staff and your record carry; roster,
recruiting relationships, facilities and NIL do not. **The move is two-way** — being fired in the pro
league puts college jobs back in the carousel.

**Reason.** A one-way door makes the college tier a tutorial. Two-way makes it a place you can end
up, which is a better story and a much better failure state. Players you developed appearing on pro
rosters is the highest-value payoff of a unified save and costs almost nothing, because one player
model spans both tiers.

**Falsifier + instrument.** The **20-season soak** must include at least one promotion and one
firing, with `soakCarouselNeverDeadEnds` holding throughout. If reputation tuning makes promotion
either automatic or unreachable across 20 seasons, the trigger model is wrong. Owner protocol: the
promotion should arrive in seasons 4–8 for a competent player, and that window is asserted in the
soak.

**Cost of reversal.** Medium — it is a career-layer change, not an engine change.

---

## D6 — Fictional identity strategy

**Chosen** (`02` §11): 8 authored archetypes × fictional regional geography → programme identity;
rivalries seeded from geography and conference, then **accumulated from actual play**; traditions
with mechanical consequence; conference realignment as living politics.

**Reason.** College football's emotional payload is rivalry, tradition and place, and it must be
manufactured from original IP. Accumulated rivalry history is the cheapest possible source of
attachment — it is a record of things that already happened — and it is the mechanic that makes
season 8 better than season 1.

**Falsifier + instrument.** **Owner play protocol at season 5+**, threshold stated in advance: *can
you name your three biggest rivals and say why, without opening a menu?* If not, generated rivalry
is not carrying weight and the fallback is authored anchor rivalries among the 24 anchor programmes.
Machine side: `soakCollectionsBounded` asserts rivalry history is capped per pairing — this is
exactly the kind of accumulating collection that grows forever if nobody bounds it.

**Cost of reversal.** Low. Authoring anchor rivalries is content work, not architecture.

---

## D7 — Save architecture and schema migration

**Chosen** (`03b` §3): `Codable` JSON with a small sidecar per slot; version read by prefix scan;
forward-compatible by default via unknown-field defaults; numbered migrators **with committed
fixtures** for structural changes; explicit refusal of newer formats; rolling backup with automatic
recovery. **Every growable collection named and bounded.**

**Reason.** JSON survives schema change and is inspectable, which matters enormously for debugging a
20-season career. Its size cost is solved by bounding collections — the lesson that took the prior
build from 8.3 MB to 2.3 MB — not by changing format.

**Falsifier + instrument.** `soakSaveSizeBounded` at season 20 against the 10 MB ceiling. If JSON
cannot hold that with every collection bounded, the format decision is wrong and the fallback is a
binary encoding for the historical archive only, keeping JSON for live state. `soakCollectionsBounded`
asserts each named bound individually, so a failure says *which* collection.

**Cost of reversal.** Medium, and it rises every season a shipped save exists. Which is why the
migrator-plus-fixture discipline starts at P10, not at first release.

---

## D8 — Difficulty, jeopardy and failure

**Chosen** (`02` §8): job security as a visible band moved by **results against expectation**, not
raw record; firing at season end with warnings through the year; **the carousel can never
dead-end**; difficulty comes from AI decision quality and adjustment speed, **never from stat
cheats**.

**Reason.** The dead-end is the reference app's rank-2 complaint class and it soft-locks saves. Stat
cheating produces the "anti-upset cheese" perception that is the loudest complaint about the genre's
best game — a fairness failure, not a difficulty failure. Players forgive losing; they do not forgive
being decided against.

**Falsifier + instrument.**
- `soakCarouselNeverDeadEnds` — every coach with an expiring contract has ≥1 offer or an explicit
  year out, at every boundary of the 20-season soak.
- `difficultyDoesNotTouchRatings` — source scan asserting no difficulty parameter reaches any
  rating, attribute or leverage floor.
- `noRubberBanding` — 2,000 games across rating gaps; win probability must be **monotonic in the
  rating gap with no tail compression**.

**Cost of reversal.** Low for tuning, high for the principle — reintroducing stat cheats would
invalidate every calibration band.

---

## D9 — Onboarding and the first session

**Chosen** (`02` §9): the first week *is* the tutorial. Three programmes with one-line situations →
three players, not 85 → one game plan → the match with 3–4 interventions → one visible consequence.
An assistant-coach voice in the inbox that stops appearing once it is not needed.

**Reason.** Four things must land in fifteen minutes: expectation is what you are judged against;
these are people; **the week is the game**; you steer, you don't play. A modal tutorial wall teaches
none of them.

**Falsifier + instrument.** **Owner protocol with a fresh player**, threshold in advance: after
fifteen minutes, unprompted, can they say what they do during a week and what they are being judged
on? Two of two, or onboarding has failed. This is the P5-constrained version of a usability test —
one person, but with a stated pass condition rather than a vibe.

**Cost of reversal.** Low. It is content and sequencing.

---

## D10 — AI quality

**Chosen** (`03` §4): the coordinator executes *your* game plan, with quality expressed as
situational conditioning sharpness and drift under pressure; the opponent detects your tendencies
and **tells you it did**; fourth-down and clock decisions run on an expected-value model with a
per-coach aggression parameter.

**Reason.** Under D1 the coordinator calls every play, so AI quality *is* match quality. It is also
the genre's most common complaint, and the specific failure to avoid is rubber-banding.

**What stops it being cut when the schedule slips** — the brief's actual question, and the answer is
structural rather than aspirational: **the three AI tests are P3 phase gates.** `noRubberBanding`,
`difficultyDoesNotTouchRatings`, and an exploit-resistance soak asserting a single degenerate game
plan (all-blitz, all-deep-shot, never punt) stays under a 65% win rate against average opposition.
A phase whose AI tests fail does not close, so AI quality cannot be traded for schedule without
someone consciously deleting a gate.

**Falsifier + instrument.** Those three tests, plus the owner protocol: *did any loss feel decided
against you rather than earned?* Any yes is a P1.

**Cost of reversal.** Medium.

---

## D11 — Test strategy under the real toolchain

**Chosen:** an **executable target with a hand-rolled harness** (`Tests/SimTests/TestKit.swift`), run
as `swift build && swift run -c release SimTests`, reporting real pass counts and exiting non-zero
on failure.

**Reason.** Neither XCTest nor swift-testing ships with the Swift Command Line Tools, and agent
containers frequently have no toolchain at all. This is not a preference — it is the only thing that
runs where this project is built. It is proven at 224 tests and 13,226 assertions including a
ten-season soak in ~100 s.

**What the builder does when the toolchain is absent** (`03b` §4.2): keep building; write the tests
in the same commit; mark G1/G2 **BLOCKED — no toolchain**, never "green by inspection"; name every
uncompiled file in `STATUS.md` under *unverified*; move the surface to the owner's walkthrough. **An
adversarial review is not a build.**

**Falsifier + instrument.** If a defect class reaches the owner that the harness structurally cannot
catch — a compile error, a SwiftUI layout fault — the strategy is insufficient for that class, which
it already is, and the recorded mitigation is the walkthrough script. **Recommended permanent fix,
logged: add GitHub Actions CI with a Swift toolchain.** It is the single change that would convert
"the agent cannot verify" into "the agent can verify" for good, and it is not blocking only because
the owner is solo and it is their call.

**Cost of reversal.** Low — adding CI later loses nothing.

---

## D12 — Accessibility contract

**Chosen** (`04` §3): seven commitments, each with a **coverage-complete** test. The match view's
answer: the **play-by-play sentence is the accessible representation** and is written first; the
`Canvas` is decorative for traversal; every intervention is a labelled `Button`; Reduce Motion turns
the match into a **stepped** experience that is fully playable, not degraded.

**Reason.** The prior build scored 1/4 against commitments it had written down for itself. Writing
them down again changes nothing. The mechanism that changes something is PAT-1: a test that asserts
a property for some members of a category must cover all of them or name its exclusions at the
assertion site.

**Falsifier + instrument.** The seven tests, plus three owner device checks: a full VoiceOver match
without sight; Reduce Motion on; XXXL across every screen. If a coverage-complete test cannot be
written for a commitment, that commitment is **relabelled a review checklist item** rather than
being left as an implied assertion — *Never Colour Alone* is already handled that way.

**Cost of reversal.** None. There is no version of this project where accessibility is reversed.

---

## D13 — Content volume

**Chosen** (`02` §12): 8 archetypes, 24 authored anchor programmes, ~110 generated, 10 conferences,
20 traditions, 32 authored pro teams, ~120 news templates, curated name banks. Rivalry seeds are
rules; rivalry *history* is accumulated from play and costs nothing. **Authoring budget ~76 hours**
— roughly two solo working weeks, spread across phases.

**Reason.** This is the difference between a two-week and a two-month task, so it is budgeted rather
than discovered. The 24 anchor programmes carry the identity load; the other 110 exist to make the
league feel big and are allowed to be thinner.

**Falsifier + instrument.** Tracked hours per phase against the 76 h estimate, recorded in
`STATUS.md`. If P1's programme authoring overruns by more than 50%, the anchor count drops from 24
to 16 rather than the schedule absorbing it. Owner protocol at season 5+ (shared with D6): if
generated programmes are indistinguishable from one another, the archetype set is too small.

**Cost of reversal.** Low, in the direction of less. High in the direction of more, late.

---

## The symmetry rule — what is lost by rebuilding rather than porting

The brief requires this to be logged in both directions. **Discarding the simulation engine is a
decision with a cost, enumerated against `STATUS.md`:**

| Lost | Value |
|---|---|
| **Calibrated engine** | 224 tests, 13,226 assertions, all passing in ~100 s |
| **Calibration bands** | Ten metric families inside realistic bands — **carried forward as knowledge** (`03` §5.2) so the rebuild does not rediscover them |
| **Ten-season soak** | Ratings, ages, roster sizes, cap legality, churn and save size all holding — **methodology carried forward and extended to 20 seasons** |
| **Cross-process determinism fix** | The `UUID.hashValue` salting bug, found the hard way. **Carried forward as a rule plus a source-scanning test** |
| **Bounded save growth** | 8.3 MB → 2.3 MB. **Carried forward as the named-and-bounded discipline** |
| **Practice-squad cap-laundering defences** | Three specific rules found by adversarial review. **Carried forward verbatim into `02` §6** |
| **Schedule generator** | The real 17-game formula with legal byes — genuinely fiddly work, rebuilt from scratch |
| **Playoff/tiebreaker resolution** | Three formats verified to resolve cleanly — rebuilt |
| **The whole cap system** | Proration, guarantees, dead money, rookie scale — rebuilt |

**Rebuilding is nonetheless the decision**, because the new engine has a different shape: two tiers
with a consistency gate, an abstract model that did not exist, a structural per-matchup resolution
that the prior engine's design did not produce, and a college tier whose talent dispersion the prior
calibration cannot express. Porting the old engine into that would cost more than rebuilding, and
would carry a pro-shaped set of assumptions into a college-shaped problem.

**But it is not free, and this register says so.** The mitigation is that the six most expensive
lessons are carried forward as *knowledge* — bands, invariants, rules and methodology — which is the
whole reason Tier B exists.

---

## Assumptions without instruments

Two, and they are named rather than dressed up as decisions:

- **A7 — a unified college→pro save is more compelling than two separate modes.** This is P2, an
  owner-set parameter, and it is **not testable before release under P5**. It is owner conviction.
  Logged as such.
- **A8 — the 2016-era pro reference app's abandonment reflects developer attrition rather than
  absent demand.** Not testable. Mitigated by the explicit pro-version requests in `01-RESEARCH.md`
  §H, which are real but low-volume.
