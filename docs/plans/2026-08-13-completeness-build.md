# Completeness build — executing the genre register to completion

**Input:** `docs/briefs/2026-08-13-genre-completeness-review.md` (G-18 to G-45).
**Instruction:** build all of it, to completion.

## The environment, stated once

This session has **no Swift toolchain** (`swift: command not found`), so per `CLAUDE.md`:

- the code is written to the same standard it would be with a compiler;
- **no slice claims G1 or G2.** Every slice lands in `docs/STATUS.md` as *unverified — never
  compiled*, naming its files;
- the words "build green", "tests pass" and "verified" do not appear about any of it.

**Pins that will move.** `Tests/SimTests/Suites/EngineTests.swift` holds two play-by-play fingerprint
literals, and `ArchitectureTests` holds root fingerprints. Any change to snap resolution or to
persisted state moves them, and this session cannot recompute one — recomputing requires running the
binary twice in separate processes, which is the whole point of the pin. Each slice that moves a pin
says so here and in `STATUS`, and the re-pin is a named toolchain-session task, never a guessed
literal. **A fabricated pin is worse than a red one.**

## Order, and why

Dependency first, then value. The match layer leads because its outputs are not persisted yet — the
detailed engine is reachable only from the calibration harness — so it is the one large area where a
change cannot corrupt a save or move a root fingerprint. It is also what match integration needs to
exist before it is worth integrating.

| # | Slice | Register | Status |
|---|---|---|---|
| 1 | The conversion — PAT and the two-point decision | G-24 | **written** |
| 2 | Penalties | G-22 | **written** |
| 3 | Special teams — kickoffs, returns, onside | G-23 | **written** |
| 4 | Overtime in a played match | G-25 | **written** |
| 5 | In-match injuries | G-26 | **written** |
| 6 | Timeouts and clock management | G-21 | **written**; challenges open |
| 7 | Weather | G-27 | **written** |
| 8 | Statistics vocabulary, both sides of the ball | G-28 | **written** |
| 8b | The played game's box score | G-11 | **written** |
| 9 | Awards and honours | G-29 | **written** |
| 10 | Scheme fit connected to every matchup | G-32 | **written**; traditions open |
| 11 | Advancing more than one week | G-43 | **written** |
| 12 | Store submission artefacts | G-45 | **written**; icon art is owner work |
| 13 | The sound and haptics contract | G-40, G-41 | **canon only**, deliberately — see below |
| 14 | The depth chart | G-30 | **written** |
| 15 | The coach's own game is played | G-18 | **written** |
| 16 | The call-in loop, connected | G-19 | **written**; the player is not yet the one answering |
| 17 | The inbox | G-20 | **written** |
| 18 | Difficulty | G-42 | **written** |
| 19 | The glossary | G-44 | **written**; no view yet |
| 20 | The postseason tail | G-38 | **written** |
| 21 | Morale | G-35 | **written**; nothing consumes it yet |

## What is not built, and the reason in each case

Not a backlog of things that ran out of time — each of these needs one of the two things this session
deliberately refused to do blind: **change persisted state** without a compiler to prove decoding, or
**move a pinned generation fingerprint** it cannot re-measure.

| Item | Register | Why not here |
|---|---|---|
| Traditions wired to outcomes | G-32b | `Programme` does not persist traditions; the generator threads them through a shared identity stream, so re-deriving them means giving them their own seed scope — which moves the pinned generation fingerprints |
| Staff as a managed resource | G-31 | Wages, hiring and firing are new persisted state plus new intents |
| Draft picks as assets, real trades | G-33 | Picks must become entities that can be owned and traded |
| Contract negotiation | G-34 | Asking prices, competing bids and agents are new state on the market |
| Discipline and suspensions | G-36 | A suspension has to persist to have a consequence; the penalty events that would drive it are engine-side and not journalled |
| Money — budgets, facilities, wages | G-37 | Entirely new persisted state on both organisation kinds |
| Preseason and camp | G-39 | Changes the shared calendar `02` §11.3.1 fixes, which every dated system reads |
| Challenges | G-21b | Needs a truth beneath the outcome for a review to contradict — an owner-level modelling decision (`02` §3.9) |
| Sound and haptics | G-40, G-41 | An owner fork, stated in `04` §7.2: ship silent and say so, or budget a pass. Code with no assets behind it would be dead capability |

**Ordering note, 2026-08-13.** The written slices are the whole match layer plus the record it
produces. That grouping was not chosen for tidiness: the detailed engine's outputs are not persisted,
so those changes could not corrupt a save, and everything downstream — a box score, an award, a
verdict, a match view — needs the match to produce the facts first.

**No schema bump was taken.** `GameState` requires an exact version match with no migration path, so
a bump rejects every existing save outright. The statistics slice reads the old shape instead — a
migration done in place — and every other persisted addition is optional-with-default. The remaining
slices should hold that line for as long as it is honest, and take one deliberate bump with a
migration fixture (P16) when it stops being.

## Standing rules for every slice

1. **Doc-first.** A gameplay question gets answered in `02` (design) or `03` (engine) before it is
   coded, and every number lands in a rules module. No design decision lives only in code.
2. **One task, one commit**, Conventional Commits.
3. **Tests are written with the code**, in the existing `TestKit` style, and are honest about being
   unrun.
4. **Additive over invasive.** New protocol requirements ship with default implementations so
   existing conformances keep compiling; new state is additive with defaulted decoding.
5. **Scope guard.** No opportunistic refactors of code a slice does not need.
6. `docs/STATUS.md` gains one entry per slice, naming the files and the unverified status.
