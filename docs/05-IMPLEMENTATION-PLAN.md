# 05 — Implementation Plan

> **Superseded build ordering (2026-08-10):** the Master Build Documentation folder supplied with
> the end-to-end goal is the primary authority. Follow milestones M0–M9 in its
> `06-BUILD-ROADMAP-AND-GATES.md`. This file remains historical detail for the preserved P0–P4
> foundation and its existing gates. M0 architecture hardening, M1 playable world, and M2 people
> lifecycle have exited; the active dependency milestone is M3 college management. Do not resume isolated P4 tuning ahead
> of the roadmap's interconnected tactical and product-completion work.

Phased build with per-phase gates. One phase at a time; a phase is not done until its gates are
green.

The platform baseline changed by owner decision on 2026-08-11: iOS 26+, with release support and
performance measured on iPhone 15-generation hardware and newer. The 844 × 390 layout floor remains
because later compact `e` models are smaller than the base iPhone 15. See
`docs/plans/2026-08-11-skill-integration.md` for the development-skill activation gates and the
scheduled creation of project-local skills.

**Ordering follows D14: college first, at ~134 programmes.** The player starts in college, and both
unsolved risks — D3/D4's scale problem and D6's identity problem — live there. Building pro first
defers both to the end of the schedule, which under P5 is how they end up unsolved.

---

## Gate definitions

Every phase gates on **G1–G4**. Engine phases add **G5–G7**. Milestones add **G8**.

| Gate | Requirement |
|---|---|
| **G1 Build green** | `swift build` clean. Asserted only by having run it in the session that claims it — see the D11 note below. |
| **G2 Tests green** | `swift run -c release SimTests` passes in full. Same rule: run it, or do not claim it. |
| **G3 Surface audit** | Touched surfaces score **≥17/20 with zero P0/P1** against `docs/04b-AUDIT-RUBRIC.md`, scored on the three **local** dimensions (Accessibility, Performance, Appearance & Theming). |
| **G4 Scope** | The diff contains what the phase specifies and nothing else. No opportunistic refactors. |
| **G5 Calibration** | All bands in `03` §5 hold under TOST. |
| **G6 Determinism** | Same seed reproduces exactly, **across processes**; **both** determinism source scans pass — no `hashValue`, and no ambient `UUID()`/`Date()` (`03` §3.5). |
| **G7 Soak** | The 20-season soak passes every assertion in `03` §6 **that the phase's scope can reach** — see the note below. |
| **G8 Milestone audit** | The two **global** rubric dimensions (Adaptivity, Platform Conformance) score ≥17/20 combined-with-local across the whole app. |

**Legal gates run on every phase that touches generation:** the name-collision test and the
trade-dress ΔE test.

### G7 is tier-scoped, because the unscoped version is impossible in order

Corrected 2026-08-09. `03` §6 defines the soak across **both** tiers — it asserts cap legality for
every pro team *and* scholarship legality for every college programme. P7 builds college systems and
P8 builds the cap. So a P7 that gates on the unscoped soak gates on assertions about systems that do
not exist yet, and can never go green.

G7 therefore means **the soak at the scope the phase has built**:

| Phase | G7 means |
|---|---|
| P7 | 20 seasons, college only. Scholarship, eligibility, roster, ratings, churn, save size. |
| P8 | 20 seasons, both tiers. The cap assertions come live here. |
| P9 | 20 seasons, both tiers, plus the career and carousel invariants the phase adds. |
| P16 | The full soak at full scale, every assertion in `03` §6, no exclusions. **This is the one that counts.** |

A phase that skips an assertion must name it in `docs/STATUS.md` and name the phase that turns it on.
A silently narrowed soak is the coverage-boundary failure `CLAUDE.md` warns about, wearing a gate's
clothes.

*Found by a cold-reader grill on the parallel `rebuild/spec-package` branch, which hit the identical
defect in that branch's plan — "the soak needs systems from P3 and P8". The shape transfers.*

### D11, where it bites — **resolved 2026-08-09, conditionally**

`docs/OPEN-DECISIONS.md` **D11 is closed.** The gates were run: Swift 6.3.3 and Xcode 26.6 are
present on the machine hosting these sessions, `./scripts/verify.sh` returns a green build and
`299 tests, 18412 checks, all passed`. **G1 and G2 are agent-assertable.**

Three rules survive the closure, and they are the ones that matter:

- **Run it, or do not claim it.** G1/G2 are asserted by the session that ran them, with the command
  output in hand. Citing D11, this plan, or a previous session's green run is not an assertion.
- **If the session has no toolchain, the old rules apply unchanged.** A sandboxed agent container has
  no `swift`. An agent that writes code without a compiler records it in `docs/STATUS.md` as
  **unverified — never compiled**, naming the files, and does not claim the phase is done. A phase
  whose only outstanding gates are G1/G2 is then blocked on the owner, not complete.
- **An adversarial review is not a build** and must never be reported as one.

Phase 4C of the previous build shipped never having been compiled. The toolchain being present now
removes the excuse, not the failure mode.

---

## Phases

### P0 — Foundation
Module skeleton per `03b` §1; the ported `SeededRandom` and `CodingSupport` plus the hierarchical
seed derivation contract from `03` §3; the **four** source-scanning tests (no SwiftUI in the engine,
no `hashValue` in seeding, no ambient `UUID()`/`Date()` in the engine, no design-token literals in
views), each comment-stripping and each with a self-test that fails on a planted offender, gathered
into one contract suite; the save
envelope with a version readable without a full parse; the ported `TestKit` harness; and the removal
of everything in `Sources/` not named in `docs/PORT-LOG.md`, in one legible commit.
**Gates:** G1, G2, G4, G6.

**Not blocked.** D11 is closed in both halves — the ported harness runs the tests, and the session
runs the harness. P0 asserts all four of its gates for real.

P0 carries one baseline obligation the other phases do not: the suite is green today at **299 tests,
18,412 checks** against the *previous* build. P0 deletes most of what those cover. The phase must
therefore state, at its close, the new count and what was removed — a suite that shrinks silently is
how a coverage boundary becomes a quality boundary, which is the failure `CLAUDE.md` names.

### P1 — Model and rules
Player, contract, programme, team, staff, league. Both rules modules — every constant that `02` and
`03` name, none inline.
**Gates:** G1, G2, G4.

### P2 — Generation and identity (D6)
Map and regions; 14 programme archetypes; name banks; tradition grammar with mechanical hooks;
rivalry seeding; team colour generation that must pass contrast and trade-dress at generation time.
**Gates:** G1, G2, G4, **both legal tests**, `IdentityDistributionTests`.

### P3 — Match engine core (D2)
Assignment → leverage → resolution → consequence. Clock and situation per tier, including the college
clock rules. Drive and game loops.
**Gates:** G1, G2, G4, G6.

### P4 — Calibration harness and bands
The harness, TOST, and the band set. Pro bands first — they start from the numbers already asserted
in the prior suite and are the known-good target — then college bands from §6.4.
**Gates:** G1, G2, G4, G5, G6.

### P5 — Abstracted model and two-tier consistency (D3, D4)
The off-screen model; `TwoTierConsistencyTests` under TOST; week-advance performance at ~134
programmes including recruiting AI cost.
**Gates:** G1, G2, G4, G5, G6, plus `PerformanceBudgetTests`.
**This is the phase that tests D14's fallback.** If the 2.0 s ceiling cannot be met at 134, reduce
the programme count here — before anything is tuned around it — rather than loosening the ceiling.

**`PerformanceBudgetTests` must assert only in release, and must measure in both.** `03` §7's budgets
assume an optimised build. A perf gate that asserts under `-Onone` reports a meaningless failure —
and, worse, would report a meaningless *pass* if the budget were ever loosened to accommodate it. The
prior build learned this concretely: its week-advance test asserted 150 ms and measured 398 ms in
debug, with no build-configuration guard. Measure both configurations, print both, assert on release.
*(Lesson taken from `adf5af1` on the unmerged `rebuild/spec-package` branch.)*

**And the budgets are Mac numbers until a device says otherwise.** `03` §7 now requires an
iPhone 15-class device; nothing has measured them on one. A green `PerformanceBudgetTests` on an
Apple-silicon Mac is necessary and not sufficient, and `docs/STATUS.md` says so.

### P6 — Season structure
Schedule generation both tiers, standings, tiebreakers, conference championships, brackets, awards.
**Gates:** G1, G2, G4, G6.

### P7 — College systems
Recruiting (contact budget, interest model, evaluation fog), the portal, NIL, eligibility clocks,
scholarships, signing day.
**Gates:** G1, G2, G4, G6, G7.

### P8 — Pro systems
Draft with scouting fog, salary cap with proration and dead money, free agency in waves, trades,
practice squad.
**Gates:** G1, G2, G4, G6, G7.

### P9 — Career, stakes and the arc (D5, D8)
Weekly job security against expectation; four stakeholder groups with triggers; the inbox event
system; firing in-season; the carousel that cannot dead-end; the promotion arc and what carries
across.
**Gates:** G1, G2, G4, G7, `JeopardyTests`, `CareerArcTests`.

### P10 — AI quality (D10)
Coordinator AI, roster AI, opponent game-plan AI — each against its stated bar.
**Gates:** G1, G2, G4, G5, G7, plus `CoordinatorAITests`, `RosterAITests`, `AdaptationTests`.
**These bars are gates, not polish.** AI quality is what gets cut when a schedule slips, and naming
it here is the only defence P5 allows.

**The UI phases do not build against the deleted v2 sheets, Stitch output or the rejected 34-screen
Film Room gallery.** Those artefacts repeated one application chassis across the game and were
removed on 2026-08-11. `04` remains the only canonical design and screen-inventory authority.

Before feature SwiftUI begins, three interactive HTML proofs establish the corrected direction:
Coaching HQ, Recruiting Board and Match Day. They share one continuous save but use three visibly
different registers. Passing the proof gate demonstrates direction; it does not make reference code
production code or authorise invented read-model values.

### P11 — Proof gate, design system and accessibility contract (D12)

1. Render the three owner-approved proof screens at both native sizes, both appearances, default and
   AX5, and both sensor orientations.
2. Score each at least 31/40 under `04b`, with no P0/P1 and no automatic design-specificity rejection.
3. Obtain owner approval of the set together. A mechanically passing proof that still looks like an
   application does not pass.
4. Build production tokens, shared interaction primitives and contract tests. Do not create a
   universal screen chassis or port reference HTML/CSS into SwiftUI.

The contract is built before feature views so subsequent phases inherit safe-area, type, theme,
truth, focus, motion and target guarantees. Components are promoted only after at least three real
production uses. Screen-specific football objects remain screen-specific.

### P12 — Entry, office and the playable week

Build the entry sequence, Coaching HQ, Inbox, Opponent Report / Film Room, Game Plan, Practice Plan,
Team Health and Aftermath from the named read models in `04` §8. Onboarding is state on these real
surfaces, not a separate tour.

Coaching HQ must prove the Coach's Office register rather than a dashboard: current world strip,
dominant week plan, next obligation and causal staff voice. Opponent Report is the only weekly screen
that inherits the Film Room register. A first decision that fails `02` §2.2 teaches the wrong game.
**Gates:** G1, G2, G3, G4.

### P13 — Match Day

Build the Broadcast register directly from `04` §9: complete landscape field, all 22 actors, at
most three foregrounded, scorebug, causal lower third, five primary controls and contextual staff
call-ins. Management navigation and application chrome are absent. The choreographer remains pinned
to recorded outcomes; Reduce Motion is a discrete state sequence; every snap has an equivalent
VoiceOver sentence.

**Gates:** G1, G2, G3, G4, plus the render-cannot-change-outcome assertion and the 16.7 ms frame
ceiling.
**Owner walkthrough owes an orientation read.** The landscape field rests on the `04` §5.2 arithmetic
plus a soccer precedent for a sport with the opposite field ratio, and it runs against FM's community
finding that the *vertical* pitch reads better for structure. The script must ask the owner,
explicitly, whether the field reads as a football field on a phone and whether the line of scrimmage
is legible as a line — the one presentation question no test in this plan can answer.
**→ Milestone M1: G8.**

### P14 — Remaining screen inventory

Build every remaining family in the explicit 62-screen inventory in `04` §8. Nothing may hide inside
a comma-list. Each family requires a named read model, world location, dominant football object,
state matrix and owner-visible completion gate.

Comparison tasks may be dense. They may not become generic tables: people, relationships, needs,
uncertainty and consequence remain visible. Analytical readouts state staff interpretation before
evidence and identify the sample and confidence. Career surfaces use chronology rather than summary
dashboards. Offseason command surfaces are dated sequences that open the real task screens.

**Gates:** G1, G2, G3, G4, every touched screen ≥31/40 under `04b`, and no inventory gap.

### P15 — Onboarding (D9)
The first fifteen minutes, taught through the first real week.
**Gates:** G1, G2, G3, G4, plus the D9 owner protocol.

**P15 no longer builds onboarding from nothing, and the correction matters.** D9's onboarding is
diegetic — it rides the week surfaces P12 builds and the entry sequence P12 now owns. A P15 that
arrives after P14 and starts building would be retrofitting first-run state into fourteen phases of
screens designed without it. P15's real scope is **tuning and the D9 protocol**: the beat sheet's
pacing, what is said when, and the owner run-through. The build happens in P12.

**And the owner walkthrough owes a first-hour read, not only a field read.** P13's script asks
whether the field reads as football. Nothing asked about the first hour — which `02` §9 names as the
thing that sells the game. That question belongs here.
**→ Milestone M2: G8.**

### P16 — Durability
The 20-season soak at full scale; save-size trajectory; bounded-collection growth checks; migration
fixtures at every version boundary.
**Gates:** G1, G2, G4, G5, G6, G7.

### P17 — Pre-deployment
`docs/PRE-DEPLOYMENT-CHECKLIST.md` in full.
**→ Milestone M3: G8, plus the owner simulator walkthrough.**

---

## What "done" means for an agent

Split, because the build environment cannot reach half of it.

**Machine-verifiable — an agent may assert these:** G1–G8 as above, the calibration bands,
cross-process determinism, the soak, the two legal tests, and the accessibility contract tests.

**Owner-verifiable — an agent hands these off and never claims them:** the simulator walkthrough
(script written by the agent, run by the owner), the D1 timing constants, the D9 onboarding protocol,
and the D6 identity protocol.

Any surface a compiler has not seen is recorded in `docs/STATUS.md` as **unverified — never
compiled**, naming the files.
