# 08 — Build Prompt (Opus 5, ultracode)

**Paste this as the opening message of a fresh Opus 5 session at ultracode effort.** It assumes no
conversational context. If you are reading it as that session: everything you need is in this repo,
and this document plus `CLAUDE.md` are the two things to read before anything else.

**This is a phase-entry prompt, not a build-the-whole-game prompt.** A unified college→pro career
simulator with a 2D match engine is not one session's work at any effort setting. Your job is one
phase.

---

## The mission

Build a **unified college→pro career simulator** for iPhone. One save, one coach: start in the
college game, get promoted to the pro league. The player **never controls an athlete** — they coach
from the sideline: game plan, personnel, tempo, fourth downs, timeouts, in-drive adjustments. The
match is a 2D all-22 field in SwiftUI `Canvas` + `TimelineView`, watched at a speed the player
chooses.

**The failure mode you are building against, and it is specific:** the previous version of this
project was a technically excellent, deeply simulated, thoroughly tested application whose in-season
week offered exactly **one** branching decision — which of three ways to watch the game. It was not
short of systems. It was short of anything to do on a Tuesday. Every phase of this plan is aimed at
that. If you finish a phase and the week is not denser than when you started, something has gone
wrong even if every test is green.

---

## The canon is the only source of truth

**Read `docs/DOC-MANIFEST.md` first.** It marks every document `RETAINED`, `SUPERSEDED-BY` or
`ARCHIVED-TO`, with a reason.

`docs/archive/` describes a **different, abandoned product** — a pro-only franchise sim with a
direct-control arcade mode. It is accurate about that product and actively misleading about this
one. `docs/archive/06-PLAYED-GAME-MODE.md` in particular specifies in detail the direct player
control this mission forbids. Do not follow it. Do not port from it. It exists as history.

`Sources/`, `Tests/` and `App/` are **Tier C: no authority. Silence means rewrite.** The prior build
is evidence, not a foundation.

---

## Your resumption contract

Every session, in this order:

1. **Read** `CLAUDE.md`, `docs/DOC-MANIFEST.md`, `docs/05-IMPLEMENTATION-PLAN.md`, `docs/STATUS.md`.
2. **Find** the first phase whose gates are not green.
3. **Plan it** — a bite-sized task plan saved under `docs/plans/`. Use `superpowers:writing-plans`
   if available; otherwise write it by hand and label it manually produced.
4. **Execute that phase only.** Not the next one, however warm the context.
5. **Run the phase-end adversarial review** on the phase's diff. Fix confirmed findings.
6. **Update `docs/STATUS.md`** — honestly, including anything that has never been compiled.
7. **Stop.** Report what closed, what did not, and what the owner needs to do.

---

## Definition of done

Split, because the build environment cannot reach half of it. **This is not pessimism — it is the
observed state of this project's containers**, and the prior build shipped a phase that had never
been near a compiler because nobody wrote the split down.

### Machine-verifiable — you assert these, headlessly

- [ ] Build green (`swift build`)
- [ ] Tests green — `swift run -c release SimTests` **executed**, exiting zero, pass counts recorded
- [ ] Calibration bands met; cross-process determinism proven; the soak passing *(engine phases)*
- [ ] The two Tier A legal tests passing — `nameCollisionTest`, `tradeDressTest` *(from P1 onward)*
- [ ] Touched surfaces ≥10/12 on the three local dimensions, zero P0/P1, against
      `docs/04b-AUDIT-RUBRIC.md` — and ≥17/20 across all five at a milestone
- [ ] Every decision you were forced to make is either in `docs/OPEN-DECISIONS.md` with an
      instrumented falsifier, or escalated to the owner as blocking

### Owner-verifiable — you hand these over, you do not claim them

- [ ] **A written simulator walkthrough script**: what to open, in what order, what should be true at
      each step. Append it to `docs/STATUS.md` for the phase you just built
- [ ] Any surface not compiled or run is labelled **unverified** in `docs/STATUS.md`, **by name**

### The rule underneath both

**You may tick a machine box only by running the thing.** Not by reading the code and judging it
likely to pass. Not on the strength of an adversarial review, however thorough. Not because you
wrote the test in the same commit.

**An adversarial review is not a build.** The prior build's Phase 4C used a multi-agent review as a
compiler substitute — independent passes for symbol existence, mutation and initialisation rules,
pattern matching and runtime correctness, each finding handed to a refuter. It caught a great deal.
It did not catch what a compiler catches, and the honest `STATUS.md` entry saying so is the only
reason anyone knows. **Write that entry when it applies. It is not a failure to say "written, not
run".**

---

## Scope guard

**Build what the phase specifies. Nothing else.**

- No unrequested refactors.
- No opportunistic rewrites of neighbouring systems.
- No "while I was in here".
- No starting the next phase because this one finished early.

If you find something genuinely broken outside the phase, **write it in `docs/STATUS.md` and keep
going.** The plan is dependency-ordered for a reason, and a phase that quietly grows is a phase
whose gate no longer means anything.

---

## Delegation cap

Ultracode makes it cheap to spawn agents. That is exactly why this is a number and not a judgement
call.

- **At most 6 concurrent subagents.**
- **No nested delegation.** A subagent may not spawn subagents.
- **No subagent may be the sole verifier of its own work.** If an agent writes a system, a different
  agent — or you — reviews it. Self-verification is how a confident wrong answer becomes a merged
  wrong answer.
- Subagents produce findings and code; **you** own the phase, the gates and the `STATUS.md` entry.

---

## Doc-first amendment rule

**A gameplay question not answered in canon gets answered in canon before it gets implemented.**

If you reach a mechanic the docs do not specify:

1. Stop coding.
2. Write the answer into `docs/02-GAME-DESIGN.md` (or `03-MATCH-ENGINE.md` for engine behaviour).
3. Then implement it.

A mechanic that exists only in code is a mechanic nobody agreed to, and it will be discovered later
by someone who has to guess whether it was deliberate.

Constants go in `LeagueRules.swift` / `CollegeRules.swift` / `EngineTuning.swift`. **A magic number
at a call site is a defect.**

---

## Escalation triggers — stop and ask

Stop work and put the question to the owner when any of these is true:

| Trigger | What to do |
|---|---|
| **A blocking item in `docs/OPEN-DECISIONS.md` is reached.** There are three at the top of that file: the unrun engagement post-mortem (gates P7), the calibration-source licensing posture, and the reconstructed audit rubric | State which one, what it blocks, and what you would do under each answer |
| **Canon contradicts itself** | Quote both passages. Do not pick one silently — that is how the contradiction becomes permanent |
| **A gate fails repeatedly** and the fix would change a decision in the canon | Say which decision, and what the evidence is. Widening a calibration band to make a red suite green is never the answer |
| **The toolchain is absent** (D11) | Keep building, label honestly per D11, mark G1/G2 **BLOCKED — no toolchain**, and say so in your report. **Do not stall.** But also do not describe the phase as done |
| **Something looks legally borderline** | Flag it for the owner to take to counsel. Do not resolve it yourself and do not quietly drop the feature |

---

## What matters most, in order

If you have to trade something, trade in this order — later items give way to earlier ones.

1. **Honesty about what was verified.** Everything else in this document depends on it.
2. **The week is dense.** ≥5 meaningful decisions. This is the whole diagnosis.
3. **It does not break.** No corruption, no dead ends, no rubber-banding. The competitive set's
   weakest point and our cheapest win.
4. **The season fits 6–8 hours.** P4 is a promise, and the arithmetic in `02` §3 is tight in the
   college tier — 48 seconds of margin.
5. **Accessibility is construction, not audit.** The prior build scored 1/4 against its own written
   commitments.
6. **It looks good.**

---

## Where things live

| Question | Document |
|---|---|
| What is canon? | `docs/DOC-MANIFEST.md` |
| How do I work here? | `CLAUDE.md` |
| What is the game? | `docs/02-GAME-DESIGN.md` |
| How does a snap resolve? | `docs/03-MATCH-ENGINE.md` |
| Where do modules and saves go? | `docs/03b-ARCHITECTURE.md` |
| What does a screen look like? | `docs/04-UX-AND-DESIGN-SYSTEM.md` |
| How is a phase scored? | `docs/04b-AUDIT-RUBRIC.md` |
| What am I building next? | `docs/05-IMPLEMENTATION-PLAN.md` |
| Why was that decided? | `docs/OPEN-DECISIONS.md` |
| What is the evidence? | `docs/01-RESEARCH.md` |
| What state is the build in? | `docs/STATUS.md` |
| Are we ready to ship? | `docs/PRE-DEPLOYMENT-CHECKLIST.md` |

`CLAUDE.md` owns standing rules — conventions, process, stack, the legal guardrail. **This document
owns the mission and done.** If they ever conflict, that is a bug: fix it, and say that you did.
