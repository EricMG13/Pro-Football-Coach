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

| # | Slice | Register | State | Status |
|---|---|---|---|---|
| 1 | The conversion — PAT and the two-point decision | G-24 | no | **written** |
| 2 | Penalties | G-22 | no | **written** |
| 3 | Special teams — kickoffs, returns, onside | G-23 | no | **written** |
| 4 | Overtime in a played match | G-25 | no | **written** |
| 5 | In-match injuries | G-26 | no | **written** |
| 6 | Timeouts and clock management | G-21 | no | **written** (challenges open) |
| 7 | Weather | G-27 | game-level | **written** |
| 8 | Statistics vocabulary, both sides of the ball | G-28 | **yes** | **written** |
| 8b | The played game's box score | G-11 | no | **written** |
| 9 | Awards and honours | G-29 | **yes** | **written** |
| 10 | Scheme fit connected to every matchup | G-32 | no | **written** (traditions open) |
| 11 | Advancing more than one week | G-43 | no | **written** |
| 12 | Store submission artefacts | G-45 | no | **written** (icon art is owner work) |
| — | Match integration and the call-in loop | G-18, G-19 | **yes** | not started |
| — | Inbox and inbound events | G-20 | **yes** | not started |
| — | Depth chart | G-30 | **yes** | not started |
| — | Traditions wired to outcomes | G-32b | **yes** | not started |
| — | Staff as a managed resource | G-31 | **yes** | not started |
| — | Draft picks as assets, real trades | G-33 | **yes** | not started |
| — | Contract negotiation | G-34 | **yes** | not started |
| — | Player morale | G-35 | **yes** | not started |
| — | Discipline and suspensions | G-36 | **yes** | not started |
| — | Money — budgets, facilities, wages | G-37 | **yes** | not started |
| — | The postseason tail | G-38 | **yes** | not started |
| — | Preseason and camp | G-39 | **yes** | not started |
| — | Difficulty and match settings | G-42 | **yes** | not started |
| — | Audio and haptics | G-40, G-41 | no | not started |
| — | Glossary and in-game help | G-44 | no | not started |
| — | Challenges (needs sub-outcome truth) | G-21b | no | owner decision first |

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
