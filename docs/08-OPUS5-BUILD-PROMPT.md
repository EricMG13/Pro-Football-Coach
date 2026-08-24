# 08 — Opus 5 Build Prompt

**This file is the kickoff prompt.** Paste it, or point a session at it, and it runs one phase.

It owns **mission** and **done**. `CLAUDE.md` owns standing rules. They must not conflict; if they
appear to, that is a defect to escalate, not to resolve by picking a winner.

---

## Mission

Build a unified college→pro football coaching career simulator for iPhone. One save, one coach:
start in the college game, earn a promotion to the pro league. The player is a coach and never a
player — **there is no direct control of players during play**. The match is watched in a 2D view
and shaped by preparation and in-match decisions.

---

## You are running one phase, not the whole game

This is a **phase-entry** prompt. A career sim of this size is not one session's work at any effort
setting, and `CLAUDE.md` requires one phase at a time with adversarial review at each phase end.

**Resumption contract — do this every time you start:**

1. Read `docs/DOC-MANIFEST.md`. It is the authority on what is canon, and its rule has **two
   limbs**: a document carries authority if it is listed there as `RETAINED` **or** is one of the
   canon paths in its §4 (which includes all of `docs/roadmap/`). **Anything else carries none**,
   whatever path it sits at. Quoting only the first limb inverts the rule and strips authority from
   most of canon. There is no archive; superseded documents were deleted (see `docs/DOC-MANIFEST.md`).
2. Read `CLAUDE.md`, then `docs/OPEN-DECISIONS.md`, then
   `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md` — the M0–M9 milestone sequence `05` defers to — and
   `docs/05-IMPLEMENTATION-PLAN.md` for the P0–P4 foundation detail and the G1–G8 gate definitions.
3. Read `docs/STATUS.md` for the honest state of the build.
4. Find the **first milestone whose exit gates are not green**. That is your phase.
5. Check whether that phase is blocked (see escalation triggers). If it is, stop and escalate.
6. Run `superpowers:writing-plans` against that phase's section of `05` to produce a bite-sized task
   plan. Save it to `docs/plans/`.
7. Execute that phase. TDD for all engine code.
8. Run the phase-end adversarial review on the phase diff. Fix confirmed findings.
9. Update `docs/STATUS.md` honestly.
10. **Stop.** Do not start the next phase.

---

## Definition of done — for the phase you are running

Done is split, because this environment cannot reach half of it.

**Machine-verifiable — you may assert these:**

- Build green; full suite green by D11's mechanism.
- The phase's gates in `05` (G1–G7 as that phase specifies), and G8 if the phase ends a milestone.
- Calibration bands under TOST; cross-process determinism; the soak, where the phase gates on them.
- The name-collision and trade-dress tests, on any phase touching generation.
- Touched surfaces **≥31/40 with zero P0/P1** against `docs/04b-AUDIT-RUBRIC.md` (eight dimensions,
  0–5; the older ≥17/20 frame was superseded by the owner on 2026-08-11).

**Owner-verifiable — you hand these off and never claim them:**

- Simulator demonstration. **You do not have a simulator.** Write the walkthrough script — what to
  open, in what order, what should be true at each step — and hand it over.
- The D1 timing protocol, the D9 onboarding protocol, the D6 identity protocol.

**If there is no Swift toolchain** — and there frequently is not, though it is no longer always so:
D11 closed on 2026-08-09 by running the gates, and sessions since have had Swift and Xcode on the
host. Where they are absent, `download.swift.org` remains refused by egress policy, and then:

- Write the code anyway, to the same standard.
- Record it in `docs/STATUS.md` as **unverified — never compiled**, naming the files.
- **Never say "build green", "tests pass" or "verified" about anything a compiler has not seen.**
  Phase 4C of the previous build shipped uncompiled; the failure was not the missing toolchain, it
  was the claim.
- A phase gate that depends on a build then becomes an **escalation**, not a judgement call.

Never route around the egress policy to fetch a toolchain.

---

## Scope guard

Build what the plan specifies for this phase. No unrequested refactors. No opportunistic rewrites of
code the phase does not touch. No features that are not in `02` or `05`. If you find something ugly
outside your phase, write it down; do not fix it.

---

## Doc-first amendment rule

A gameplay question not answered in canon gets **answered in canon first, then implemented**. Never
encode a design decision only in code. `docs/02-GAME-DESIGN.md` is the gameplay authority;
`docs/03-MATCH-ENGINE.md` is the engine authority; `docs/OPEN-DECISIONS.md` records why.

---

## Delegation cap

- At most **6 concurrent subagents**.
- **No nested delegation** — a subagent may not spawn subagents.
- **No subagent is the sole verifier of its own work.**

---

## Escalation triggers — stop and ask the owner

1. **A blocking `docs/OPEN-DECISIONS.md` item stands in the phase's way.** As of writing, **D11
   (test strategy under the real toolchain) was closed on 2026-08-09 by running the gates, and P0 is
   no longer blocked. Assert G1/G2 only by running `./scripts/verify.sh` in the session that claims
   them; a session without a toolchain falls back to the unverified-never-compiled rule in `CLAUDE.md`.**
   Every "tests green" gate depends on the answer. Do not invent one.
2. **Canon contradicts itself.** Two RETAINED documents disagree on a decision.
3. **A gate fails repeatedly** — three genuine attempts at the same gate without progress.
4. **A phase cannot be verified** because the toolchain is absent and the gate requires a build.
5. **Anything legally borderline.** Flag it for the owner to take to counsel. Never resolve it
   yourself, and never propose a workaround that reintroduces real identities.

When you escalate: say which trigger fired, what you tried, what you need decided, and what you
recommend. Then stop.

---

## The two things this project has failed at before

Read these as failure modes to design against, not as history.

**1. Dead capability.** The previous build had a "Call the Plays" mode that called no plays, 22 of 24
coach skill nodes with no reachable effect, scouting points with nothing to buy, a screen that was
statically unreachable, and a job-security number that could not move for twenty weeks. It looked
finished and was hollow. `ReachabilityTest` catches the UI case; nothing catches the rest except
refusing to ship a system whose effect you have not observed.

**2. The coverage boundary becoming the quality boundary.** From `docs/AUDIT.md`: contrast was
verified rigorously in exactly the places the tests looked, and failed everywhere else. A test over a
class of surfaces must enumerate that class **by construction**, so a new surface is covered the day
it is added rather than the day someone remembers it. Spot-check tests over hand-listed instances are
a defect, not coverage.
