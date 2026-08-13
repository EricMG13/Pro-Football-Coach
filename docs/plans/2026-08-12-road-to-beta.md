# Road to beta — outstanding items

> **Merge note, 2026-08-13.** This file exists on the owner's machine but has never been committed,
> so the agent session that wrote the section below could not read it. Everything here is **additive**:
> it is the outstanding-item register as of commit `3efd313`, written to be pasted into the existing
> document rather than to replace it. If the local copy is pushed, the two can be reconciled properly.

Status source: `docs/STATUS.md` at `3efd313`, `docs/PRE-DEPLOYMENT-CHECKLIST.md`, and the
engagement-levers plan. Items are grouped by what blocks what, not by when they were found.

---

## 0. The gate above every other gate — no toolchain

No `swift` and no `xcodebuild` in the agent environment, and the egress policy refuses
`download.swift.org`. **Everything in §2 has been written and never compiled.** Per `CLAUDE.md`, that
is recorded as *unverified — never compiled*, and no item below may be called green, passing or
verified until a machine has seen it.

- [ ] Build both library targets and the app on a machine with Xcode.
- [ ] Run the full default suite and record pass/fail counts.
- [ ] Re-run everything in §2 before treating any of it as real.

This is not a task that can be delegated to another agent session in this environment. It is an owner
action or a CI action.

---

## 1. Standing release blockers — these pre-date the engagement-levers work

### 1.1 FSC-003 — save growth

`STATUS.md` calls this **a release blocker, not a tuning item**. Compression brought size back under
the 8 MB ceiling; what remains open is **encode latency on device** (10.16 s at season 20 rising to
12.53 s at season 30). Growth is linear in seasons with no ceiling, and it is the authoritative
snapshot rather than the archive that grows.

- [ ] Decide between a cold archive and chunked/streaming persistence (`03b` §4 keeps both in reserve).
- [ ] Re-measure encode time on the iPhone 15/A16 baseline, not in a simulator.
- [ ] Re-measure after Phase 2.3's development ring lands — six beats × ~13,000 players is the only
      new growth term this work adds, and it is the one worth measuring.

### 1.2 The professional soak is red, for a real reason

`--pro-soak` drives the professional market across seasons and **nothing ever happens**: over two
seasons and 42 weeks, across 32 teams, `draftedFinal=0 freeAgents=0 waivers=0`. The market opens and
closes; no draft pick, signing, waiver or trade occurs. Diagnosed to root cause and deeper than a
missing driver.

- [ ] Fix the professional market so the soak's assertions can mean something.
- [ ] This gates M6 and, transitively, the promotion arc — a coach promoted to the pro tier arrives at
      a market that does not function.

### 1.3 Personnel screens are DEBUG fixtures, not career-wired

Recorded in `STATUS.md`. Related to, but distinct from, the seam problem in §3.

---

## 2. Engagement levers, Phase 2 — written at `a4e1d45` and `3efd313`, unverified

The four engine items are written. None is verified. Canon landed first at `6dc10f6`.

### 2.1 The review this phase is owed never happened

`CLAUDE.md` §4 requires an adversarial review of the phase diff before the phase is declared done. A
workflow was launched for it and **all seventeen of its agents failed with terminal errors, returning
nothing**. The run was stopped rather than left to look like coverage.

- [ ] **Phase 2 is not done until this review runs.** Re-run it, or review the diff directly against
      `04b`. Do not treat the written code as reviewed.

### 2.2 Determinism fingerprints are knowingly wrong

`WorldStep.expiringInboundEvents` now emits events before every other step, so global event sequences
shift and the pinned fingerprints in `ArchitectureTests` (`:16`, `:18`, `:64`) no longer match.

- [ ] Repin deliberately, from **two rebuilt runs that agree**. Never adjust a fingerprint until it
      goes green — that converts a determinism assertion into a rubber stamp.

### 2.3 Schema version — an owner decision, deliberately deferred

The new `DomainEventPayload` career cases change the encoded root, so **existing saves are expected to
be unreadable**. The schema version has not been bumped. (Phase 2.3's two additions decode with
`decodeIfPresent` and are backward-compatible on their own; the event payloads are not.)

- [ ] Owner: bump the schema version and provide a migration, or accept save invalidation pre-beta.

### 2.4 Tests that do not exist yet

- [ ] Both-tier soak across the new scheduler steps.
- [ ] Save-size re-measurement against FSC-003 (see §1.1).
- [ ] **Carousel-exit reachability** over seeded careers — that a fired save always reaches either an
      offer or an explicit year out. This is D8's floor and currently nothing asserts it.
- [ ] `PlayerDossierTests` is written and registered but has never executed.

---

## 3. Phase 3 — the engine/UI seam. Not started.

**`Sources/ProFootballCoachUI` has never imported `FootballSimCore`.** All five built screens run on
`CoachWorldSampleData`, and `CoachWorldDataProvenance.simulationSnapshot` — the hook for real data —
is never constructed anywhere in the repository. There is no seam at all; this is the single largest
gap between "the engine works" and "the game exists".

- [ ] `WeekDeskReadModel` in `FootballSimCore`, built like `NewsFeedReadModel.build(from:)`:
      deterministic, bounded, derived. Must carry what `Correspondence` cannot — sender, options,
      deadline, consequence, and the answer path.
- [ ] Construct `CoachWorldDataProvenance.simulationSnapshot` for `CoachingHQReadModel`.
- [ ] Order the inbox by **deadline then weight**. `PendingQueues` sorts by `id.uuidString`
      (`GameState.swift:12`), so nothing currently leads it.
- [ ] Replace `RootView.navigate`'s hard reject for `.inbox`.
- [ ] `onOpenCorrespondence` currently sets a status string; make it answer.
- [ ] **Add an answer intent.** `CoachIntent` has seven cases and none of them answers a decision;
      `CareerSession.resolveDecision` is reachable only through the career actor.
- [ ] Watch `NewsFeedReadModel.names(in:)` (`:157`) — it builds a full UUID→name dictionary over every
      person in the world on **every** build call, uncached. An inbox rebuilding per frame pays it
      repeatedly.
- [ ] Two inert answers to fix while here: `CareerSession` records `.portalRetention` and
      `.portalRelease` resolutions but applies **no state change**.

The architecture gate forbids the SwiftUI target reading `GameState`; it does not forbid consuming
engine read models, which is how this stays legal.

---

## 4. Phase 4 — guardrails and truthfulness. Not started.

### 4.1 `CommitmentCoverageTest`

`PRODUCT.md`'s commitment table names **eleven tests. Zero exist** — including
`CommitmentCoverageTest` itself, the mechanism meant to prevent exactly that. The machinery to build
it already exists (`DesignContractTests.swift:23-55` parses a canon Markdown table at run time;
`ContractTests.swift:20` resolves the repo root; `:28` walks the test corpus).

- [ ] Build it, let it fail, then correct `PRODUCT.md` so every row names a test that exists or is
      explicitly marked unimplemented. Mirror into `STATUS.md`.

### 4.2 `04` §6.5 registry enforcement

The registry table was corrected at `6dc10f6` to mark 19 of 23 components unbuilt. The enforcement
that keeps it honest does not exist.

- [ ] Copy the §6.6 symbol-register pattern (`DesignContractTests.swift:41-55`, `:156`, `:168`, `:195`).

### 4.3 The one assertable engagement-ethics test

`03` §5.1 names the narrative-independence band. Nothing asserts it.

- [ ] Assert margin-distribution **TOST-equivalence across favoured / underdog / losing-streak
      conditions**, comparing the three estimates to each other rather than each to a fixed band.
- [ ] Say plainly in the test name that it **passes by construction today** — `GameEngine.play` takes
      no streak, form or momentum input. It is a tripwire against a future drama term, not a discovery.
- [ ] Needs building: a margin band (`"average margin by context"` currently sits in
      `unimplementedMetrics`), binning, and `public` on `CalibrationHarness.measure` and `SampledGame`.

### 4.4 A suite can silently never run

`Tests/SimTests/main.swift:89-129` is a manual if/else chain. A suite not added to the default branch
**never runs and nothing notices**.

- [ ] Assert that every `run*Tests` symbol in the corpus is called. This is the same coverage-boundary
      defect `CLAUDE.md` names in its conventions.

---

## 5. Milestones still marked active

| Milestone | What remains |
|---|---|
| **M4 — tactical** | Detailed-game call-in choices are not threaded through the live match session or the controlled career actor. No production UI or simulator evidence claimed. |
| **M5 — career stakes** | Coaching-carousel transitions and inbox events were listed open; Phase 2 addresses both in code but **unverified**, and only to D8's minimum floor. |
| **M6 — professional** | Blocked by §1.2. |
| **M7 — living world** | Archive implemented; the save-growth blocker it exposed is §1.1. |

---

## 6. Pre-deployment gates not yet met

`docs/PRE-DEPLOYMENT-CHECKLIST.md` is the authority. Not yet satisfiable today:

- **Machine gates** — build, full suite, calibration bands under TOST, `TwoTierConsistencyTests`,
  cross-process determinism, `hashValue` scan, engine/UI boundary scan, design-token scan, 20-season
  soak at shipping league size, save size under 8 MB, migration fixtures, ten accessibility contract
  tests, `CommitmentCoverageTest`, `ReachabilityTest`, `ErrorSurfaceTest`, performance budgets on a
  physical iPhone 15/A16.
- **Legal gates** — the two tests (name collision, trade dress) plus a blocklist refresh and manual
  review. Note the standing risk the blocklist cannot see: **a fictional programme in a real city
  wearing that city's real programme's colours can jointly identify it.** That is a review obligation
  and a counsel question, not something a test catches.
- **Rubric gate** — whole app ≥31/40 with zero P0/P1 against `04b`, eight dimensions. (Note: the older
  ≥17/20 five-dimension frame is **not** equivalent — 31/40 is 77.5%, 17/20 is 85%.)
- **Owner gates** — simulator walkthrough, VoiceOver, Dynamic Type at AX5, Reduce Motion, the D1
  timing protocol (season inside 6–8 hours) and the D9 onboarding protocol. **No agent may assert
  these.**

---

## 7. Deliberately deferred — recorded so they are not silently lost

- The **full coaching carousel** — college-to-college moves, AI coach firing and hiring, staff
  poaching. Phase 2 built D8's minimum floor only.
- **Named challenges** (self-authored jeopardy). Canon records the shape; v1 ships job-market gating.
- The **seam for the other four built screens** (§3 is inbox-first).
- The **seven inert traits** — `TraitPopulationGenerator.activeTraits` deliberately refuses to
  populate a trait with no consumer, and that guard should stay until each has one.
- The **eleven missing accessibility tests**, beyond making `PRODUCT.md` stop claiming they exist.
- **Mid-match resumption**, named out of v1 scope in `02` §12.

---

## Suggested order

1. **§0** — get a toolchain in front of this. Nothing else can be trusted until then.
2. **§2.1 and §2.2** — review the Phase 2 diff and repin fingerprints. Cheapest way to turn written
   code into verified code.
3. **§1.2** — the professional market, because it silently invalidates the promotion arc.
4. **§3** — the seam. Until it exists there is an engine and a set of mockups, not a game.
5. **§4** — guardrails, which is also where the remaining truthfulness defects get closed.
6. **§1.1** — save growth, before beta but after the game is playable end to end.
