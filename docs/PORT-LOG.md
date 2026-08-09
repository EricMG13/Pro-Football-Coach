# Port Log

Tier C of the v4 brief says the prior implementation carries no authority and **silence means
rewrite**. It also requires justification in **both** directions: a logged reason to port, and — after
the adversarial review of the v3 prompt — a logged reason to discard.

This file is that log. It is written before P0 so the phase knows what it is rebuilding and what it
is lifting.

**Default is rewrite.** Nothing is ported because it exists. Each entry below names what would be
lost by rebuilding it, and what was checked to be sure that is true.

---

## Ported — with the reason

### 1. `Support/SeededRandom.swift` — port substantially unchanged

**What would be lost by rebuilding:** the fix to the bug that made the previous save system
unreproducible, and which no in-process test could see.

`UUID.hashValue` is salted per launch in Swift. The prior build seeded AI free-agent bidding from it,
so a single save produced a different league every time the app started — while every in-process
determinism test passed, because within one process the salt is constant. The fix is
`SeededRandom.seed(from:)`, which mixes the raw UUID **bytes** with FNV-1a. That is Tier A's
determinism constraint made real, and rediscovering it costs a debugging cycle that has already been
paid for once.

**What was checked:** the implementation is SplitMix64 with correct constants; `int(in:)` uses
rejection sampling rather than modulo, so wide ranges are unbiased; `uuid()` stamps the version-4 and
RFC-4122 variant bits, so seeded identities read as ordinary UUIDs; `gaussian(_:in:)` resamples
rather than clamps, avoiding the pile-up at range edges that clamping produces. The whole generator
is one `UInt64`, so a save can resume the exact stream.

**Changes on port:** none required. Add `RandomNumberGenerator` conformance if the new engine wants
stdlib interop, and extend `seed(from:)` to take the hierarchical seed path `03` §3 specifies
(`leagueSeed → seasonSeed → weekSeed → gameSeed → driveSeed → snapSeed`).

### 2. `Support/CodingSupport.swift` — port substantially unchanged

**What would be lost:** a subtle determinism defect that is easy to reintroduce and hard to diagnose.

Swift encodes a dictionary whose key is not `CodingKeyRepresentable` as a flat
`[key, value, key, value…]` array **in hash order**, which differs run to run. The new model will be
full of `[UUID: …]` maps exactly as the old one was. Without the `UUID: CodingKeyRepresentable`
conformance, save bytes churn between runs and no byte-level determinism test can hold.

**Changes on port:** none. Keep `JSONEncoder.stable()` with `.sortedKeys`.

### 3. `Tests/SimTests/TestKit.swift` — port, and treat as D11(a)'s answer

**What would be lost:** the ability to run tests at all in this project's actual environments.

Neither XCTest nor swift-testing ships with the Swift Command Line Tools — both live inside Xcode.
The harness is ~50 lines, has zero dependencies, reports real pass/fail counts, exits non-zero on
failure, and runs as an executable target via `swift build && swift run -c release SimTests`. It
carried 224 tests and 13,226 assertions in about 100 seconds.

**Changes on port:** keep the assertion API surface; drop `testAsync`'s semaphore if the new engine
has no async surface (it is documented as deadlock-prone against `@MainActor` and the new engine is
synchronous by design, per `03b` §3).

**Note a defect to fix on port:** `Package.swift` currently carries contradictory comments — the
header says "Tests use swift-testing (bundled with the toolchain)" while the target comment says
XCTest and swift-testing both require full Xcode. The second is correct. Fixed in this commit.

### 4. The `hashValue` source-scanning test — port the idea, relocate it

Currently buried in `Tests/SimTests/Suites/DynastyTests.swift:603–628`, which is the wrong home for a
build-wide invariant. `03b` §1 requires three source scans (no SwiftUI in the engine, no `hashValue`
in seeding, no design-token literals in views). Port this one as the template and put all three in a
dedicated contract suite.

---

## Knowledge ported, code discarded

These are Tier B: the numbers and methods transfer, the implementation does not.

| Source | What transfers |
|---|---|
| Calibration assertions in `Tests/SimTests/Suites/` | The pro-tier bands themselves, extracted with file and line in `01-RESEARCH.md` §6.4. `03` §5 starts from them rather than re-deriving. |
| The ten-season soak | The **method** — which invariants are worth asserting across seasons: ratings, ages, roster sizes, cap legality, churn, save size. `03` §6 extends it to 20 seasons and both tiers. |
| Save-size work | The lesson, not the code: unbounded free-agent pools and news feeds took saves to 8.3 MB; bounding them brought it to 2.3 MB. D7 gives every growable collection a stated bound. |
| Cap laundering defences | The **attack**, which a rewrite would have to rediscover: practice squad as a place to hide a contract, dead money erased by release, an offer validated against the cap and never charged. |
| Carousel invariant | A coach whose contract expires always has at least one offer or an explicit year out. Without it, saves soft-lock. |

---

## Discarded — with the reason

Tier C's default, applied deliberately rather than by silence.

| Area | Reason for discarding |
|---|---|
| `Model/` (Player, Team, League, Contract, Staff, …) | Pro-only by construction: 32 teams, divisions, cap. The new model is college-first with ~134 programmes, scholarships, eligibility clocks and NIL. Reshaping costs more than writing. |
| `Rules/` | Same — `LeagueRules`, `TeamTable` and `Scenario` encode the old scope. The rules-module *pattern* survives; the contents do not. |
| `Engine/GameSimulator`, `PlayCaller`, `PlayMatrix` | D2 chose hybrid assignment/leverage resolution with per-matchup causality the UI can narrate. The prior simulator resolves plays without that structure, so the thing `04`'s match view needs most is exactly what it cannot supply. |
| `Arcade/` (SnapKernel, Choreographer, Routes, Coverage, Pocket, RunLanes, Openness, …) | The mission forbids direct control. **But see the note below — this is the discard that deserves the most scrutiny.** |
| `Generation/` | Pro-only name banks and league factory. D6's endogenous identity (archetypes, map, traditions, rivalries) is a different system. |
| All of `Sources/ProFootballCoachUI/` | 9/20 on the rubric, and `04` rebuilds the design system from zero with a contract the old layer cannot satisfy. |

### The arcade discard, examined properly

This is the largest single discard and the one most likely to be wrong, so it gets more than a table
row.

> **UPDATE 2026-08-09 — the experiment at the foot of this section was run, and two of its three
> reasons did not survive.**
>
> This section ended by saying: *"the cheap experiment is to compile `Arcade/` first, once a
> toolchain exists, and see what falls out."* A toolchain exists. It was run.
>
> **`Arcade/` compiles, and its tests pass.** `swift build` compiles all ten files under
> `Sources/FootballSimCore/Arcade/` — the build log names `Choreographer.swift` directly.
> `Tests/SimTests/main.swift` registers `runArcadeTests()`, `runArcadeFieldTests()` and
> `runArcadeWatchTests()`; they carry **90 of the suite's tests** (29 + 48 + 13) and they are inside
> the `299 tests, 18412 checks, all passed` result.
>
> So of the three reasons given below:
>
> | Reason | Status |
> |---|---|
> | Written to serve a thumb, not a coach — `DefensiveInputs`, `Pocket`, timed-window tuning | **Stands.** Mission-level, and on its own sufficient. |
> | "It has never been compiled" → unknown defect surface | **False.** It compiles. |
> | "Phase 4C was added after the last build that worked" | **False as an inference about the code.** The 70 MB artifact was stale; the code was not. The symbol table below is evidence about that *artifact*, and nothing more. |
>
> **The discard still holds, on the first reason alone** — the mission forbids direct control, and no
> compile result changes that. But it must be justified that way and not by the other two, and one
> consequence deserves the owner's attention rather than being buried: D2 needs per-matchup
> resolution (protection duels, route-versus-coverage, run lanes) and `04` §5.3 needs a sack drawn as
> *the protection duel that lost*. `SnapKernel` is a working, tested implementation of exactly that
> geometry. Whether the right move is "rewrite the model for a coach-facing engine" or "port the
> spatial layer and strip the input layer" is now a live question with evidence on both sides, where
> before it was settled by a fact that turned out to be wrong.
>
> Nothing below is deleted; it is the reasoning the decision was made against, and the symbol table
> remains true of the artifact it describes.

**What is being thrown away:** `SnapKernel` and its spatial layer — formations, routes against live
coverage, per-matchup protection duels, run lanes, carrier pursuit, openness scoring. Pure, seeded,
headless-testable, with the engine still owning every probability and the field only measuring.

**Why that is uncomfortable:** `01-RESEARCH.md` §6.0 found the arcade layer held about **99% of the
previous build's decision volume**, and D2's chosen architecture needs *exactly* per-matchup
resolution — protection duels, route-versus-coverage, run lanes. That is a description of
`SnapKernel`.

**Why it is still discarded:** it was written to serve a thumb, not a coach. Its outputs are shaped
for input timing and aiming (`DefensiveInputs`, `Pocket`, the timed-window tuning in `ArcadeTuning`).
And it has **never been compiled** — which is no longer an inference from `STATUS.md` but a measured
fact:

> The repository carried 70 MB of committed Xcode build products
> (`build/Debug-iphonesimulator/`, an `arm64-apple-ios-simulator` build of both library targets).
> Symbol counts in `FootballSimCore.o` (3.9 MB) and, independently, in the 926 KB `.swiftmodule`:
>
> | Symbol | `.o` | `.swiftmodule` |
> |---|---|---|
> | `SeededRandom` | 570 | 35 |
> | `GameSimulator` | 409 | 22 |
> | `PlayCaller` | 61 | — |
> | `LeagueFactory` | — | 7 |
> | **`SnapKernel`** | **0** | **0** |
> | **`Choreographer`** | **0** | **0** |
> | **`RunLanes`** | **0** | **0** |
> | **`Openness`** | **0** | **0** |
> | **`Pocket`** | **0** | **0** |
>
> Ten source files are tracked under `Sources/FootballSimCore/Arcade/`. None of them appears in the
> last artifact a compiler produced, while the rest of the engine does. Phase 4C was added after the
> last build that worked.

Porting code no compiler has ever seen into the foundation of a rebuild inherits an unknown defect
surface at the worst possible layer.

*(Those artifacts have since been untracked and gitignored — they were stale, 70 MB, and actively
misleading about what had been built.)*

**What is salvaged instead:** the *model*, not the code. `03` §1's matchup table is the same idea
expressed for a coach-facing engine, and the honesty invariant — the field measures, the engine owns
every probability, rendering cannot change a result — is carried forward explicitly as a test.

~~**If the owner disagrees**, the cheap experiment is to compile `Arcade/` first, once a toolchain
exists, and see what falls out. Until something has compiled it, porting it is a bet on code no
machine has ever checked.~~

**Run 2026-08-09. It compiles; 90 tests pass. See the update box at the head of this section.** The
bet is no longer on unchecked code, so the discard is now carried by the mission constraint alone.

---

## Not yet dispositioned

`Sources/` is still in the tree. Deleting it is P0's business and P0 has not run — and deleting 90
files is not something to do silently. P0 should remove everything not named in the ported list
above, in one commit, so the diff is legible.

### The deletion commit must leave a retrieval address — **owner decision, 2026-08-09**

Asked and answered: `Arcade/` is **deleted in P0**, and the discard is carried by the mission
constraint alone (see the update box above — the "never compiled" reason is false). It is deleted
rather than quarantined because a non-canon path in the tree is how a cold builder builds the wrong
game, which is the whole reason `docs/DOC-MANIFEST.md` exists.

Deleting working, tested code is only safe if it stays findable. **P0's deletion commit therefore
owes this file three things, written back here in the same phase:**

1. The **commit SHA** of the deletion, so `git show <sha>` retrieves any file.
2. The **file list** removed, so nobody has to guess what was there.
3. The **suite counts before and after** — currently `299 tests, 18412 checks`, of which 90 tests are
   arcade — so a shrinking suite is a stated number rather than a silence.

P3 is the phase that designs per-matchup resolution, and it is the phase that should read
`SnapKernel` back out of history before deciding how much of that geometry to rebuild.
