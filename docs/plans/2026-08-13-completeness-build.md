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
| 21 | Morale | G-35 | **written**; consumed by discipline since slice 27 |
| 22 | Traditions do something | G-32b | **written**; a wrong finding corrected in the open |
| 23 | Money, facilities and wages | G-37 | **written** |
| 24 | Hiring and firing | G-31 | **written**; staff ratings still never change |
| 25 | Draft picks as assets | G-33 | **written**; not yet authoritative for the draft itself |
| 26 | Contract negotiation | G-34 | **written**; free agency is now cap-bound |
| 27 | Discipline and suspensions | G-36 | **written** |
| 28 | Preseason camp | G-39 | **written**; no exhibition games, and canon says why |

**Every register row G-18 to G-45 is now either written or escalated to the owner.** The register's
own §3 anti-false-gap list is unchanged: those were never gaps.

## What is not built, and the reason in each case

Two items remain, and **neither is a thing that ran out of time.** Each is a fork the owner has to
take, and each is now a numbered decision with an instrumented falsifier rather than a paragraph in a
brief — `docs/OPEN-DECISIONS.md` D16 and D17, both `ESCALATED`.

| Item | Register | Decision | Why not here |
|---|---|---|---|
| Challenges | G-21b | **D16** | A challenge is a bet on a fact, and a snap has no fact at that resolution — no spot, no forward progress, no moment the ball came loose. Building one means inventing a truth beneath the outcome, which changes what a snap *is* and moves every determinism pin. `02` §3.9 states it; D16 prices the three options and recommends striking the promise unless a later milestone needs a spot anyway |
| Sound and haptics | G-40, G-41 | **D17** | Audio is an asset commitment, and an agent can neither author nor license a crowd bed. Code with nothing behind it is dead capability. `04` §7.2 carries the contract if it is built; D17 recommends shipping silent **and saying so**, because the part that must change either way is the accessibility clause that currently claims equivalents for a channel that does not exist |

### What was blocked before, and what unblocked it

The earlier version of this table listed seven more items, each blocked on "changes persisted state
without a compiler" or "moves a pinned fingerprint". Six were unblocked by the same three moves,
recorded here because they are the reusable technique rather than luck:

1. **Derive rather than store.** The depth chart, morale, the inbox, the staff shortlist, pick
   identity, the discipline file and the camp report are all functions of the save. Nothing new is
   persisted, so nothing can strand a league or move a generation fingerprint.
2. **Additive optional fields, or in-place legacy decoding.** `finances` and `suspension` are
   optional and omitted when absent, so a world without them encodes to exactly the bytes it did
   before; `PlayerSeasonStatistics` reads the old flat keys in place. **No schema bump was taken.**
3. **Check the claim before writing it down.** The traditions entry above said `Programme` does not
   persist traditions. It does, in `GameState.identities`, and always did — the claim had been
   checked against the wrong type. The correction is recorded in `02` §8.1 and `docs/STATUS.md`
   rather than quietly dropped.

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

## What a toolchain session has to do first

The plan is complete in the sense the instruction meant — every register row is written or
escalated — and **incomplete in the only sense that matters for shipping**: none of it has been
compiled. In order:

1. **Build.** `swift build` and `swift test`. Expect compile errors: 28 slices of Swift were written
   against a repository nobody could type-check, and the honest prior is that some of it does not
   compile the first time.
2. **Re-pin what moved.** `EngineTests`'s two play-by-play fingerprint literals move with any change
   to snap resolution — penalties, kickoffs, weather, in-play injuries and the conversion all touch
   it. Recompute them by running the binary twice in **separate processes**; that separation is the
   whole point of the pin. **A fabricated pin is worse than a red one.**
3. **Re-run the soaks and re-read the bands.** M1, M2 and the pro soak. Two slices are expected to
   move numbers: camp adds a third development pass per season, and negotiation makes free agency
   cap-bound for the first time. Both are bounded by construction — camp respects `potential`, and a
   replacement-level free agent asks the minimum — but "bounded in argument" is not "measured".
4. **Re-run the two legal tests**, which nothing in these slices should have touched, precisely
   because that is the kind of claim worth checking rather than assuming.
5. **Then, and only then**, `docs/STATUS.md`'s twenty-eight "written, unverified" entries can start
   becoming something else.
