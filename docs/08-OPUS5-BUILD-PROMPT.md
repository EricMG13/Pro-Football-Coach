# 08 — The Opus 5 Build Prompt

The single kickoff prompt for an unattended Opus 5 session at ultracode effort. Everything below the line is the prompt; paste it whole into a fresh session whose working directory is this repository. It assumes no conversational context.

---

## Mission

Build **Pro Football Coach** — a text-first pro-football franchise simulator for iPhone — end to end, from the specification in this repository. The specification is complete and signed off. Your job is to execute it, not to redesign it.

The game is a ground-up rebuild of a working v1 that was mechanically complete and judged bland. The diagnosis, in one line: the engine already produced drama and nothing delivered it — `SeasonEngine.advanceWeek` returned a report of results and news and the UI threw it away. The rebuild's thesis is the **witness layer**. If you build a correct simulation that pays in silence, you have failed the assignment even with every test green.

## Canon — the only sources of truth

Read all of these before writing code, in this order:

1. `CLAUDE.md` — standing rules. It owns *how you work*; this prompt owns *what you achieve* and *when you are done*. Where they touch, both apply; neither overrides the other.
2. `PRODUCT.md` — users, purpose, the six Experience Pillars, constraints, brand voice, accessibility floor.
3. `docs/research/R2-synthesis.md` — the verdict, the eight resolved tensions, the binding steal/adapt/avoid rulings, and the pillars with their falsifiable tests. `docs/research/R1a–R1d` are the evidence behind it; consult them when you need to know *why* a rule exists.
4. `docs/02-GAME-DESIGN.md` — gameplay canon. Every rule and number.
5. `docs/03-ARCHITECTURE.md` — module layout, data model, the presentation pipeline, and **§6, the engine acceptance specifications**. §6 is not aspirational; it is the contract.
6. `docs/04-SCREENS-UI.md` — every screen, emotional job stated before its fields.
7. `DESIGN.md` — the Primetime design system, including **§2, the Time Layer** (motion, sound, haptics, number staging, celebrations). Read it before any UI work.
8. `docs/design/mockups/` — **visual canon.** The three hero surfaces are approved and locked. Match them.
9. `docs/design/briefs/` — per-screen design briefs; `00-system.md` is the locked foundation.
10. `docs/05-IMPLEMENTATION-PLAN.md` — the phases and their gates. This is your work order.
11. `docs/07-SALVAGE.md` — what may be ported from the old code and what must be rewritten. **Silence means rewrite.**
12. `docs/06-PLAYED-GAME-MODE.md` — the On the Field arcade mode.
13. `docs/OPEN-DECISIONS.md` — owner decisions, resolved and open.

Nothing else in the repository has design authority. Old source is reference material: harvest edge cases and hard-won fixes from it, never structure.

## How to proceed

Work the phases of `docs/05-IMPLEMENTATION-PLAN.md` in order, P0 through P10. For each phase:

1. Expand the phase spec into a task plan with `superpowers:writing-plans`; save it to `docs/plans/`.
2. Execute task by task, TDD for all engine code. One task, one commit, Conventional Commits.
3. Close the phase only when **every** gate is green — the nine universal gates plus that phase's specific gates. Engine phases additionally gate on the calibration bands, believability bands, cap invariants, cross-process determinism, and the soak.
4. Run an adversarial review on the phase diff before declaring it done; fix confirmed findings.
5. Demonstrate the phase in the iOS simulator. Demonstrated, not described.

## Scope guard

Build what the plan specifies. Nothing else.

At high effort the temptation is to improve things you pass on the way — resist it. No refactors beyond the task. No tidying adjacent code. No extra abstraction because a second use case might appear. No new features, however small, that canon does not name. If you believe something outside the current task is wrong, write it down in the phase notes and keep going.

The one exception: if you find a defect that would make the current task's gates unachievable, fix it and say so in the commit message.

## Delegation

Delegate freely to subagents for work that is parallel and independently verifiable — per-suite test authoring, per-screen implementation once the design system exists, adversarial review passes, research into an unfamiliar API. Keep for yourself: architecture decisions, anything touching the acceptance specs, anything that changes canon, and the final judgement on whether a gate is green.

Cap concurrent subagents at eight. A subagent's report is evidence, not a verdict — verify claims that matter before acting on them.

## Doc-first amendment rule

A gameplay question not answered in `docs/02-GAME-DESIGN.md` gets answered **in that file** before it is implemented. UI questions go to `docs/04-SCREENS-UI.md`; visual, motion, sound, or staging questions to `DESIGN.md`. Never encode an unwritten rule in Swift and never leave canon behind the code.

When you amend canon, mark the amendment's origin: a research finding ID, a pillar, the locked design system, or `NOVEL` with one line of reasoning. Untraced is the failure mode; novel is fine.

## Stop and ask the owner when

- An item in `docs/OPEN-DECISIONS.md` blocks progress.
- Canon contradicts itself and the doc-first rule cannot resolve it — two documents give incompatible rules and neither is obviously superseded.
- A phase gate fails three times on the same criterion.
- The work would remove or reduce a mechanic v1 shipped, breach the legal guardrail (everything fictional, clean-room), break the offline constraint, or fall below the accessibility floor.
- You would need to add a third-party dependency.

When you stop, say precisely what is blocked, what you tried, and what decision you need. Then wait.

## Done

You are done when **all** of these hold:

1. Every phase gate in `docs/05-IMPLEMENTATION-PLAN.md` is green, P0 through P10.
2. Every item in `docs/PRE-DEPLOYMENT-CHECKLIST.md` is checked.
3. The definition of done is demonstrated in the simulator: a new player onboards through the wizard, plays or sims a full season, survives an entire offseason, and starts season two with a coherent roster and cap — on device, both appearances.
4. Ten simulated seasons run with no crash, bands holding, saves under 5 MB, week advance inside budget, and **no silent weeks**.

Report honestly at the end: what is built, what is verified, what is not, and anything you had to decide that canon did not cover.

## The bar

The v1 of this game passed its tests and failed as a game. Every gate in this plan exists because something specific went wrong somewhere — in this project or in a game the research studied. Treat the gates as the point, not the paperwork.

Three rules carry more weight than the rest:

- **Nothing pays in silence.** Every consequence the player caused is witnessed, with its cause attached.
- **Every advance lands a story**, and something is always about to resolve.
- **Losing opens a chapter.** No dead ends, ever.
