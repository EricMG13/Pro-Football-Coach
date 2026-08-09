# Pro Football Coach — Ground-Up Rebuild (v4): Research & Spec Package

> **v4 changelog.** Supersedes v3 after adversarial review
> (`docs/reviews/2026-08-09-spec-prompt-v3-adversarial-review.md`). P1–P5 are filled. The
> definition of done is split into machine-verifiable and owner-verifiable halves because the build
> environment has no simulator. The audit rubric is now a deliverable rather than a reference to a
> tool. Research now starts by playing the build that exists. The 78-finding disposition is reduced
> to the 25 P0/P1s plus the five systemic patterns, each as a test. A doc manifest retires the
> anti-canon. `CLAUDE.md` is rewritten first, not last. Four decisions added (D10–D13). `08` is a
> phase-entry prompt, not a build-the-whole-game prompt.

You are Fable 5 acting as **spec author**, not builder. Your output is a self-contained research,
design and planning package that an Opus 5 session can execute cold, with no access to this
conversation. That is the acceptance test for everything below.

---

## 0. Owner-set parameters

Fixed inputs, not open questions. Do not re-litigate them; design within them.

| ID | Parameter | Value |
|----|-----------|-------|
| P1 | Platform & stack | iOS 17+, Swift 5.10+, SwiftUI, **iPhone-only**, portrait-only, offline, **zero third-party dependencies**. The 2D match view is rendered in **SwiftUI `Canvas` + `TimelineView`** — no SpriteKit, no Metal. |
| P2 | Scope shape | **Unified college→pro career.** One save, one coach: start in the college game, get promoted to the pro league. The promotion arc is a v1 feature, not a v2 addition. |
| P3 | Distribution & monetisation | TestFlight → paid premium on the App Store. **No IAP, no ads, no subscriptions, no analytics, no accounts.** |
| P4 | Season time budget | **A full season is completable in 6–8 hours of play.** |
| P5 | Team | Solo developer plus AI agents. No playtest cohort, no QA, no telemetry. |

These are settled. If executing this brief surfaces a genuine conflict between two of them, escalate
it as a blocking owner question — do not resolve it by quietly relaxing one.

---

## 1. Mission

Build, from the ground up, the **Football Manager Mobile of American football coaching** — a unified
college→pro career — with a **2D match engine** and **no direct control of players during play**.

The product is a career simulation about *being a coach*: roster construction, scheme identity,
opponent preparation, staff, player development, and the politics of the job. The player never
throws a pass or runs a route. What they do instead is the central design question of this project
(§4).

---

## 2. Authority tiers

This section governs everything. Read it before anything else.

### Tier A — Constraints (non-negotiable, survive the rebuild)

- **Legal guardrail.** All teams, schools, conferences, stadiums, players, coaches, marks, logos,
  colours, fight songs, traditions and broadcast identities are **fictional and original**.
  Reference titles are mechanics research only — never copy protected expression, names, art, text,
  audio or UI. Adding college football *raises* this bar: NCAA school identity, trade dress and
  player NIL are among the most aggressively enforced IP in sport. Any strategy that routes around
  this (bundled "community" real-name files, a roster importer pointed at a scraped source, a wink
  in the store listing) is out of scope. If a proposed feature depends on real identities to work,
  say so plainly and propose an original-IP substitute. Flag anything you judge legally borderline
  for the owner to take to counsel — do not resolve it yourself.

  **This constraint ships as two tests**, specified in the package and named in the plan:
  1. *Name collision test* — no generated team, city, school, conference, stadium, player or coach
     name matches an entry in a maintained blocklist of real ones, at any seed, across N generated
     leagues.
  2. *Trade dress test* — no generated primary/secondary colour pair falls within a stated ΔE of a
     real programme's known pair.

  Everything else in the guardrail is a review checklist item. Say that explicitly rather than
  pretending prose is an assertion.

- **Determinism.** Seeded RNG. A given seed plus a given input state reproduces a match exactly,
  **across processes and app launches**. Strict engine/UI separation: the simulation runs headless.
  Note the prior build's failure mode as a required regression test: a generator seeded from
  `UUID.hashValue` is salted per launch, so the same save seed produced a different league every
  app start, and no in-process determinism test could see it. Seeds derive from identifier bytes,
  and a source-scanning test forbids reintroduction.

- **Single-player, offline-first.** No server dependency for core play. No network at all.

- **P1–P5 above.**

### Tier B — Evidence (persists; may be superseded only with a written reason)

Prior work is discarded as *implementation*, not as *knowledge*.

- **The existing build itself** — the highest-value evidence available, and the only evidence that
  speaks to the actual failure. See §6.0. It runs; play it.
- **`docs/AUDIT.md`** — a **UI-layer** audit of `Sources/ProFootballCoachUI/` (17 files). It
  explicitly excludes the engine, iPad, size classes and App Store review, and it concludes the
  codebase is "structurally sound and idiomatic." It is therefore evidence about *craft*, not about
  why the game was boring — do not treat 9/20 as the diagnosis of blandness. Its transferable value
  is concentrated in `## Patterns & Systemic Issues`, above all: *"The defect is not ignorance of
  contrast; it is that the test's coverage boundary became the quality boundary."* Treat that as a
  design principle for the rebuild.
- **`docs/STATUS.md`** — the calibrated engine, 224 tests, 13,226 assertions and the ten-season soak
  are evidence about *how hard this problem is*. The calibration bands, the soak invariants
  (ratings, ages, roster sizes, cap legality, churn, save size) and the save-growth lesson (8.3 MB →
  2.3 MB once the free-agent pool and news feed were bounded) are reusable knowledge even if no line
  of code survives. So is its warning: *"multi-agent adversarial review… is not the same thing as a
  build."*
- **`docs/01-RESEARCH.md`** — prior research. Sections A (reference-app screen inventory), B (the
  Achi Jones lineage), C and H (community signal mined from the App Store and r/cfbsimulator), D
  (the owner's working patterns) and F (legal guardrails) **carry forward verbatim or with additions
  only**. They are not superseded by §6 and must not be dropped.

### Tier C — No authority

All current source; all current design and product documentation; the prior three-reference hybrid
framing (Madden / Retro Bowl / Football Manager); all prior scope and architecture choices.
**Silence means rewrite.**

Justification is required **symmetrically**:

- Porting anything requires a logged justification naming what would be lost by rebuilding it.
- **Discarding the simulation engine requires a logged justification naming what is lost by
  rebuilding it** — enumerated against `STATUS.md`: the calibration bands, the soak invariants, the
  cross-process determinism fix, the bounded save growth, and the cap system's practice-squad
  laundering defences. Rebuilding may well be right. It is not free, and the brief will not pretend
  it is.

`CLAUDE.md` as it currently stands has **no authority over this brief** where the two disagree —
its "Tech stack (decided — don't relitigate)" section, its "32 teams, 2 conferences × 4 divisions"
line and its "College mechanics are replaced by pro mechanics" line are all now false. It is
rewritten as Deliverable 0 before any other work begins.

---

## 3. Hypothesis to attack, not confirm

The owner's diagnosis of the previous build was: *"a bland application, not a game."*

Your obligation is to **attack this diagnosis, not ratify it** — and specifically to attack the
proposed cure. Note the tension you are being handed:

- The stated remedy is to become more like **Football Manager Mobile**, which is *itself* a
  menu-driven application.
- The previous framing included **Retro Bowl** as the source of immediacy and tactility. That
  reference and all direct player control are removed.

So the obvious failure mode of this rebuild is a *better-looking* bland application. Your package
must state, explicitly and early, **where engagement comes from** once direct control is off the
table, and defend it with evidence — from §6.0 first, then §6.1 and §6.2 — about why FM's players
stay engaged (jeopardy, ownership, emergent narrative, information asymmetry, the one-more-turn
loop) rather than assuming depth produces it.

You are equipped to attack it because §6.0 gives you primary evidence rather than a second-hand
argument. Use it. If the evidence suggests the owner's target is wrong, or that some minimal tactile
layer is load-bearing, say so and argue it — and note that the removed arcade layer was the part of
the previous build the owner actually played on device, which is a fact §6.0 should test rather than
assume in either direction.

---

## 4. Gate zero — the core design problem

> **Agency density versus season throughput.**

Football Manager's in-match loop — set tactics, watch, adjust, substitute — does not transfer
cleanly, because American football's decision surface is **discrete and per-snap**.

Name the positions you considered — at minimum: every-snap play-calling; situational call-ins with a
coordinator AI handling the rest; pre-set game plan plus in-drive adjustments plus discrete
high-leverage decisions (4th down, timeouts, challenges, clock management); pure spectate with
halftime and weekly adjustment only — then choose one and defend it with arithmetic.

### The arithmetic is mandated, not left to taste

Compute, and show the working, for **both tiers**:

```
season time = Σ over games [ snaps × (decision time + presentation time) × attention share ]
            + Σ over weeks [ week-management time ]
            + offseason time
```

Terms you must declare rather than assume:

- **Snaps.** ~130 per game is the count your team is on the field for — roughly 65 offensive and 65
  defensive. State whether the player calls defence too; the answer changes the total by 2×. College
  tempo pushes this toward 150–180.
- **Presentation time.** The time spent *watching* a snap resolve, which dominates the decision time
  and is the term most often omitted. At 6 s of animation per snap, 130 snaps is 13 minutes of
  watching before a single decision is priced. A 2D match engine nobody watches is wasted work; one
  that must be watched blows P4 unaided.
- **Attention share.** What fraction of games are played at full fidelity versus skipped or
  fast-forwarded, and what the fast-forward and delegation affordances actually are.
- **Season length.** College: 12 games + conference championship + playoff. Pro: 17 games + bye +
  playoffs. Both land near 20 in-season weeks.

**The budget this must clear.** P4 = 6–8 hours. Take 7 hours = 420 minutes across ~20 in-season
weeks plus an offseason: roughly **21 minutes per week, inclusive of the match**. That is the number
your chosen agency model has to survive. If it doesn't, either the model changes or you escalate P4
as a blocking question — you do not quietly assume the player will grant more time.

Do the same for **week-level throughput**: what the player does between games, how many meaningful
decisions that is, and how long it takes.

---

## 5. Decision register

Produce `docs/OPEN-DECISIONS.md` containing every decision below. For each: options considered, the
choice, the reason, **what evidence would falsify it**, and the cost of reversing it later.

**Every falsifier must name its instrument** — the thing that would actually run: a soak assertion,
a calibration band, a timing harness, a determinism test, or *an owner play-session protocol with a
metric and a threshold stated in advance*. Under P5 there is no playtest cohort, so "we would notice
if players disliked it" is not a falsifier. A falsifier without an instrument is decoration; write
the instrument or escalate the decision.

Any decision you cannot resolve from evidence goes to the owner as an explicit blocking question
rather than a silent default.

- **D1 — In-match agency model.** Output of §4.
- **D2 — Match engine architecture.** Is the 2D view *rendering a simulation* or *dramatising a
  statistical model*? Candidates: agent-based per-snap resolution; play-outcome distribution model
  with a visualisation layer; hybrid assignment/leverage resolution without continuous physics. Pick
  one; state the consequences for determinism, save size, testability and calibration. Note that P1
  fixes the renderer as SwiftUI `Canvas` — D2 decides what it draws, not what draws it.
- **D3 — Two-tier simulation.** The visible game and the off-screen slate cannot share a fidelity
  level and still meet a mobile week-advance budget. **The off-screen slate is ~15 games a week in
  the pro league (32 teams) and ~65 a week in the college league (~134 programmes)** — plus
  recruiting and transfer-portal AI for every one of those programmes, which is plausibly a larger
  cost than the game simulation itself. Specify the abstracted model and the **consistency
  requirement** binding it to the detailed model: season-level statistical distributions produced by
  both must agree within stated bands, with the statistical test named. This is a hard requirement,
  not an optimisation to discover later.
- **D4 — Performance budgets.** Restate as numbers: week advance, full-season sim, match render
  frame budget, save size, cold launch. **Derive them from the college case**, which is the worse
  one, and include recruiting/portal AI in the week-advance figure. The previous build's budgets do
  not carry over automatically.
- **D5 — College/pro system design.** P2 is a unified career, so the college→pro promotion arc is a
  first-class v1 feature. Specify what differs and what is shared: recruiting and the transfer
  portal versus draft and free agency; scholarships, eligibility clocks and NIL versus salary cap
  and contracts; ~85/105-man versus 53-man rosters; conference realignment versus divisions; playoff
  formats; the coaching carousel. Specify the promotion mechanic itself: what triggers an offer,
  what carries across (reputation, staff, scheme identity, records), and whether the move is
  one-way.
- **D6 — Fictional identity strategy.** College football's emotional payload is rivalry, tradition
  and place, and you must manufacture it from original IP. Specify how: generated or authored school
  archetypes, regional geography, procedurally seeded rivalry histories that accumulate across a
  save, traditions with mechanical consequence, conference politics. A design problem to solve well,
  not a compliance tax to minimise.
- **D7 — Save architecture and schema migration.** Career saves span in-game decades. Specify the
  persistence format, the size trajectory over 20 seasons, and the migration policy for
  post-release schema changes. `STATUS.md`'s unbounded-growth lesson is a required input: name every
  collection that can grow without limit and state its bound.
- **D8 — Difficulty, jeopardy and failure.** What losing looks like, how the player gets fired, what
  pressure feels like week to week. Include the prior build's non-negotiable: the carousel can never
  dead-end — a coach whose contract expires always has at least one offer or an explicit year out.
- **D9 — Onboarding and first session.** What the first fifteen minutes are, and what the player has
  understood by the end of them.
- **D10 — AI quality.** The coordinator, opponent and roster-management AI is load-bearing under
  every D1 option except every-snap play-calling, and it is the single most common complaint in this
  genre's communities (§6.2 will confirm or refute that). Specify what "good" means, how it is
  measured, and what stops it being the thing that gets cut when the schedule slips.
- **D11 — Test strategy under the real toolchain.** `STATUS.md` records that neither XCTest nor
  swift-testing ships with the Swift Command Line Tools, so the prior suite ran as an executable
  target with a hand-rolled harness. Agent build environments have had no Swift toolchain at all.
  Decide what runs the tests, headlessly, with no CI and possibly no toolchain, and what the builder
  does when the toolchain is absent. Every "tests green" gate in `05` depends on this answer.
- **D12 — Accessibility contract.** The prior build scored 1/4 on accessibility: Reduce Motion at 0
  occurrences, 3 accessibility modifiers across ~140 KB of view code, contrast failing at 50+ sites,
  all against commitments it had written down for itself. Specify contrast tokens, Dynamic Type
  behaviour, Reduce Motion, VoiceOver and touch-target floors as a **contract with tests**, designed
  so the coverage boundary cannot silently become the quality boundary again. The match view is the
  hard case: specify how a `Canvas` animation is described to VoiceOver and what it becomes under
  Reduce Motion.
- **D13 — Content volume.** D6 asks for rivalries, traditions and conference politics across ~134
  programmes plus a pro league. Decide how many schools, name tables, archetypes and traditions are
  authored versus generated, and state the authoring budget in hours. This is the difference between
  a two-week and a two-month task for a solo developer.

---

## 6. Research obligations

Each research claim carries a source. Claims you cannot source are labelled **assumption** and
listed together so the owner can see what the design rests on.

**6.0 — Play the build that exists.** *(Do this first. It is the only primary evidence available
about the actual failure, and it is cheap: the app builds and runs.)*

The audit measured craft. Nothing has ever measured engagement. Produce an engagement post-mortem
from a structured play session, recording at minimum:

- Wall-clock per in-game week, and the split between match time and management time.
- Meaningful decisions offered per week — decisions where a reasonable coach could go either way —
  versus confirmations.
- Which screens were opened, which were skipped, and which were opened once and never again.
- The point at which attention drops, and the last thing that held it.
- Whether the arcade layer (the removed direct-control mode) was the thing holding attention, and
  what it was substituting for.

State the protocol before running it, and report against the protocol including the parts that
disconfirm the diagnosis. This output is what §3 and §4 argue from.

**6.1 — Football Manager Mobile specifically** — not desktop FM. Its actual loop, session length,
match-view design, tactical abstraction, and what it *removed* from the desktop game and why.

**6.2 — The real competitive set**, which is not FM: Draft Day Sports (Pro Football and College
Football), Football Coach: College Dynasty, Bound For Glory, Front Office Football, Wolverine
Studios' catalogue, plus Retro Bowl and Retro Bowl College as the arcade pole. For each: loop,
agency model, match presentation, monetisation, platform, and what its community complains about.
Community complaints are the highest-value secondary signal available. Extend `01-RESEARCH.md` §C
and §H rather than restating them.

**6.3 — The market gap** — an *output*, argued from 6.0–6.2, not an assumption.

**6.4 — Statistical calibration targets.** Start from the bands already asserted in the existing
test suite (`STATUS.md`: scoring, yardage, completion rate, sacks, turnovers, kicking, home
advantage, fourth-quarter share, explosive plays, target distribution) and extend them. The genuine
gap is **college**, not pro. State sources and their licensing, and distinguish two postures
explicitly: using public data at *design and calibration* time versus *shipping* any of it. Flag
anything borderline for counsel rather than resolving it.

**6.5 — 2D match presentation** — how comparable titles convey what happened on a snap without
direct control, and what makes a dot-based view legible rather than noise.

---

## 7. Deliverables

Repo-relative paths. Stable paths are the interface contract between spec author and builder.

**0. `CLAUDE.md` — rewritten first, before any other deliverable.** It currently contradicts this
brief in three places (see Tier C) and is read by every session. Rewrite it before research starts.
It owns standing rules only: conventions, process, tech stack per P1, legal guardrail. It does not
own mission or done — `08` does — and the two must not conflict.

**0b. `docs/DOC-MANIFEST.md`** — every pre-existing document marked `SUPERSEDED-BY <path>`,
`ARCHIVED-TO docs/archive/<path>`, or `RETAINED`, with a reason. Nothing outside the manifest may
remain at a canonical path. This is not bookkeeping: a cold builder currently opens `README.md` and
is told "Start here: `docs/00-EXECUTIVE-PLAN.md`", and finds `docs/06-PLAYED-GAME-MODE.md`
specifying in detail the direct player control this mission forbids. Naming the canon is not enough
while the anti-canon sits at a canonical path. **Rewrite `README.md` as part of this.**

1. **`docs/01-RESEARCH.md`** — §6 output **merged into** the existing file. Sections A, B, C, D, F
   and H carry forward; §6.0–6.5 are added as new sections. Sources cited, assumptions listed
   separately. Nothing is dropped silently.

2. **`docs/02-GAME-DESIGN.md`** — the game itself: core loop, §4 resolution, season structure for
   both tiers, the promotion arc, progression, staff, scouting, development, D5 and D6 systems, D8
   stakes, D9 onboarding, D13 content volume.

3. **`docs/03-MATCH-ENGINE.md`** — D2, D3 and D4 in implementable detail: play resolution model,
   attribute→outcome mapping, clock and situation model, determinism and seeding contract, the
   abstracted off-screen model for both tiers, the **calibration harness** (targets, bands, named
   statistical test, pass/fail), and the soak methodology.

4. **`docs/03b-ARCHITECTURE.md`** — module layout, engine/UI boundary and how it is enforced, save
   architecture per D7, test architecture per D11, project structure. v3 had no home for this;
   `03-MATCH-ENGINE.md` is not it.

5. **`docs/04-UX-AND-DESIGN-SYSTEM.md`** — a design system built from zero, then screens, with the
   match view as the hardest surface. Includes the D12 accessibility contract. **`DESIGN.md` is
   archived, not maintained in parallel** — one home for the design system, recorded in the manifest.

6. **`docs/04b-AUDIT-RUBRIC.md`** — the audit rubric as a first-class artifact: the five dimensions,
   their 0–4 anchors, and the P0–P3 severity definitions, captured verbatim from the tool that
   produced the 9/20 baseline. Without this, every gate in `05` that cites "the same rubric" is
   unmeasurable. State which dimensions are **global** (Adaptivity, Platform Conformance) and
   therefore scored per milestone rather than per phase.

7. **`PRODUCT.md`** — positioning, audience, the §6.3 gap argument, P3, scope for v1 versus later.

8. **`docs/05-IMPLEMENTATION-PLAN.md`** — phased build with per-phase gates:
   - build green;
   - tests green, by the mechanism D11 decides;
   - touched surfaces auditing **≥17/20 with zero P0/P1** against `04b`, with global dimensions
     deferred to milestone boundaries;
   - engine phases additionally: calibration bands, cross-process determinism, the soak;
   - the two Tier A legal tests passing.

   Plus `docs/PRE-DEPLOYMENT-CHECKLIST.md` — **authored, not regenerated; no such file exists in
   this repo.** State what it must contain.

9. **`docs/06-AUDIT-DISPOSITION.md`** — the `docs/AUDIT.md` disposition, scoped to what is worth
   disposing:
   - **All 25 P0/P1 findings**, each dispositioned as (i) structurally impossible in the new design,
     (ii) addressed — *naming the test that will catch a regression*, or (iii) retired with a reason.
   - **All five systemic patterns** from `AUDIT.md:777`, each converted into a **standing invariant
     with a named test**. These matter more than the individual findings.
   - The P2/P3 tail retired in one paragraph with a stated reason.

   The 78 findings carry no IDs in the source document and most describe code Tier C discards;
   a 78-row table would be ritual. Convert findings into tests, not into prose.

10. **`docs/OPEN-DECISIONS.md`** — the §5 register, D1–D13, each with a falsifier that names its
    instrument, including any decision escalated to the owner as blocking.

11. **`docs/08-OPUS5-BUILD-PROMPT.md`** — the kickoff prompt for an Opus 5 session at **ultracode**
    effort. Write it to Opus 5's characteristics, not your own.

    **It is a phase-entry prompt, not a build-the-whole-game prompt.** A unified college→pro career
    sim with a 2D match engine is not one session's work at any effort setting, and `CLAUDE.md`
    itself mandates one phase at a time with adversarial review at each phase end. Its resumption
    contract: *read `05`; find the first phase whose gates are not green; execute that phase only;
    run the phase-end adversarial review; update `STATUS.md`; stop.*

    It must include:
    - the mission, and the canon as sole source of truth (pointing at the manifest);
    - **done**, per §8 below, with the machine/owner split intact;
    - a **scope guard** — build what the plan specifies, no unrequested refactors;
    - a **delegation cap** stated as a number: at most 6 concurrent subagents, no nested delegation,
      and no subagent may be the sole verifier of its own work;
    - a **doc-first amendment rule** — a gameplay question not answered in canon gets answered in
      canon before it gets implemented;
    - **escalation triggers**: a blocking `OPEN-DECISIONS.md` item, canon contradicting itself, a
      gate failing repeatedly, or an absent toolchain per D11.

    It owns mission and done; `CLAUDE.md` owns standing rules; they must not conflict.

---

## 8. Definition of done

Done is split, because the build environment cannot reach half of it. This container has no `swift`
and no `xcodebuild`; `STATUS.md` records the same historically, including an egress policy that
refuses `download.swift.org`, which is why Phase 4C shipped having never been compiled. Simulator
demonstration is an **owner** action on the owner's Xcode machine. Writing it into an unattended
agent's definition of done guarantees either a false claim of done or a permanent escalation.

**Machine-verifiable — the agent asserts these, headlessly:**

- Build green; tests green by D11's mechanism.
- Calibration bands met; cross-process determinism proven; the soak passing.
- The two Tier A legal tests passing.
- Touched surfaces ≥17/20, zero P0/P1, against `04b`.
- Every D-item decided with an instrumented falsifier, or escalated as a blocking owner question.
- `03` contains a calibration harness a builder can implement without further design work.

**Owner-verifiable — the agent hands these off, it does not claim them:**

- A written simulator walkthrough script: what to open, in what order, what should be true at each
  step.
- Any surface that has not been compiled or run is labelled **unverified** in `STATUS.md`, as 4C
  was. An adversarial review is not a build; do not let one stand in for the other silently.

**And, for the package itself:**

- A cold Opus 5 session, given only the repo and `docs/08-OPUS5-BUILD-PROMPT.md`, completes a phase
  or reaches a legitimate escalation with zero conversational context.
- Gate zero is resolved with the §4 arithmetic — all terms declared, both tiers computed — and the
  resolution is traceable through `02`, `03` and `04`.
- Every Tier A constraint appears as a named test somewhere in the package, or is explicitly marked
  as a review checklist item rather than an assertion.

---

## 9. Ordering rules

1. **`CLAUDE.md` and the doc manifest first.** Everything downstream is read in a repo that
   currently contradicts this brief.
2. **§6.0 → §6.1 → §6.2 → §4.** Gate zero is the most consequential decision in the project, so it
   must not be made before the research that informs it. §6.0 is primary evidence about the actual
   failure; §6.1 and §6.2 tell you where every comparable title sits on precisely the agency axis
   §4 is about. v3 put §4 before all research and was circular.
3. **§4 before `02`, `03` and `04`.** Agency density determines the engine's required fidelity, the
   UI's information architecture and the season's shape. Deciding it late means rewriting all three.
4. **Research before positioning.** The market-gap claim in `PRODUCT.md` is only worth writing if
   §6.3 produced it.
5. **Engine before UI.** The match view can only be designed once you know what the simulation can
   tell it and when.

---

## 10. Tooling

**Approved skills** — use these; do not improvise substitutes:

- `/deep-research` — for §6.1–6.5.
- `/impeccable` (`audit`, `critique`, `polish`) — the source of the 9/20 baseline and of `04b`'s
  rubric. Required, and previously unnamed while a gate depended on it.
- Claude Design via the briefs workflow — for `04`.
- `superpowers:writing-plans`, `superpowers:test-driven-development`,
  `superpowers:verification-before-completion`, `superpowers:systematic-debugging`,
  `adversarial-reviewer` — per `CLAUDE.md`'s process.

If a named skill is unavailable in the executing session, **do the work manually and label the
output as manually produced**. Do not stall, and do not substitute an unvetted tool.

Propose any additional third-party skill — name, source repo, licence — to the owner before
installing it. An unbounded "explore GitHub for tools" instruction is a supply-chain surface and is
not authorised.
