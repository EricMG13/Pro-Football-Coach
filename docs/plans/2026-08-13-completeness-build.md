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

| # | Slice | Register | Persisted state | Moves a pin |
|---|---|---|---|---|
| 1 | The conversion — PAT and the two-point decision | G-24 | no | play-by-play |
| 2 | Penalties | G-22 | no | play-by-play |
| 3 | Special teams — kickoffs, returns, onside | G-23 | no | play-by-play |
| 4 | Overtime in a played match | G-25 | no | play-by-play |
| 5 | In-match injuries | G-26 | no | play-by-play |
| 6 | Timeouts and clock management | G-21 | no | play-by-play |
| 7 | Weather | G-27 | game-level only | play-by-play |
| 8 | Statistics vocabulary, both sides of the ball | G-28, G-11 | **yes — schema** | root |
| 9 | Awards and honours | G-29 | **yes — schema** | root |
| 10 | Match integration and the call-in loop | G-18, G-19 | **yes** | root |
| 11 | Inbox and inbound events | G-20 | **yes — schema** | root |
| 12 | Depth chart | G-30 | **yes — schema** | root |
| 13 | Scheme fit and traditions wired to outcomes | G-32 | no | both |
| 14 | Staff as a managed resource | G-31 | **yes — schema** | root |
| 15 | Draft picks as assets, real trades | G-33 | **yes — schema** | root |
| 16 | Contract negotiation | G-34 | **yes — schema** | root |
| 17 | Player morale | G-35 | **yes — schema** | root |
| 18 | Discipline and suspensions | G-36 | **yes — schema** | root |
| 19 | Money — budgets, facilities, wages | G-37 | **yes — schema** | root |
| 20 | The postseason tail | G-38 | **yes** | root |
| 21 | Preseason and camp | G-39 | **yes** | root |
| 22 | Difficulty and match settings | G-42 | **yes** | root |
| 23 | Multi-week advance | G-43 | no | no |
| 24 | Audio and haptics | G-40, G-41 | no | no |
| 25 | Glossary and in-game help | G-44 | no | no |
| 26 | Shipping assets and the privacy manifest | G-45 | no | no |

Slices 8 onward each carry one schema bump. They are **batched into as few bumps as the dependency
order allows** rather than one per slice, because every bump is a migration fixture (P16) and a
re-pin.

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
