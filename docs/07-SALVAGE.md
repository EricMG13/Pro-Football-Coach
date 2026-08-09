# 07 — Salvage Ledger

**The rule (from the rebuild brief):** nothing carries forward by default. Porting old code requires a logged justification here showing it serves the new architecture *unchanged in role* and is cheaper than rewriting. **Silence means rewrite.** Old source is reference material — harvest edge cases and hard-won fixes, never structure.

This ledger is checked at every phase gate. Adding a row is a decision, not a formality.

## A. Approved ports

Code that survives, with its justification.

| # | Artifact | Old location | Role in the new architecture | Why porting beats rewriting |
|---|---|---|---|---|
| S-01 | `SeededRandom` (SplitMix64 + `seed(from:)` byte-derivation, `uuid()`, `gaussian`, rejection-sampled `int(in:)`) | `Support/SeededRandom.swift` (114 lines) | Unchanged: the determinism substrate for every engine | It *is* the cross-process determinism fix. Rewriting risks reintroducing the exact bug the fix exists for (`UUID.hashValue` is per-process salted). The code is small, pure, and already covered by its own suite. Port verbatim; keep the doc comment explaining why. |
| S-02 | `LeagueRules` constants and tables (`overallWeights`, `peakAgeWindow`, `positionSalaryPremium`) | `Rules/LeagueRules.swift` (153 lines) | Unchanged: the single home for tunable numbers | These are *calibration outputs*, not code — the values are what make §6.2/6.3 bands hold. Rewriting means recalibrating from scratch. Port the values; the file's shape may change. |
| S-03 | `PlayMatrix` play/counter-play profile tables | `Rules/PlayMatrix.swift` (357 lines) | Unchanged: play-resolution inputs | Same argument as S-02 — this table is a decade-equivalent of tuning encoded as data. It is the reason scoring, explosive-play rate, and sack rate land inside their bands. |
| S-04 | `CodingSupport` (`JSONEncoder.stable()` with sorted keys, `UUID: CodingKeyRepresentable`) | `Support/CodingSupport.swift` (45 lines) | Unchanged: save determinism and byte-equality round-trips | Tiny, correct, and load-bearing for the soak's byte-identical round-trip assertion. |
| S-05 | `SaveQueue` (coalescing actor: single-slot pending, one write in flight, `flush()` continuations) | `Persistence/SaveQueue.swift` (79 lines) | Unchanged: off-main persistence | Already the right shape for the new §6.6 budget and for fixing the audit's P0. Concurrency code this small and this correct is expensive to re-derive. |
| S-06 | `SaveStore` file layout (main + `.backup.json` + `.meta.json` sidecar; list decodes sidecars only; load falls back to backup) | `Persistence/SaveStore.swift` (195 lines) | Layout unchanged; call sites change (sidecar gains the active-hook line; version read moves to the sidecar) | The layout is validated durability design answering the genre's #1 complaint. Port the layout and the fallback logic; rewrite the version-probe path per §7. |
| S-07 | `TeamTheme.legibleOnDark` + `surface(for:over:)` + `contrastRatio` | `Theme/DesignSystem.swift` | Unchanged: the measured-surface contrast machinery the coverage law depends on | The audit singled this out as "unusually careful work," and its comment records why the first version was wrong (it measured against a background the app never draws). That knowledge is the asset. |
| S-08 | `RatingTier` band boundaries and light/dark hex pairs | `Theme/DesignSystem.swift` | Unchanged: the rating ladder | Machine-verified at 4.5:1 against card, page, and composited chip wash in both themes. Re-picking colors means re-verifying for no gain. |
| S-09 | `ScheduleGenerator` (17-game formula, bye placement) | `Engine/ScheduleGenerator.swift` (394 lines) | Unchanged: schedule construction | Pure, correct, property-tested (every team exactly 17 games, one bye in the legal window, no team twice in a week). A rewrite is a fresh chance to get a fiddly formula wrong. |
| S-10 | `NameBank` + name-generation weighting | `Generation/NameBank.swift` (80 lines) | Unchanged, with one amendment | Original fictional content that already exists and is legally clean. **Amendment:** the college bank must be regenerated independently per `02-GAME-DESIGN.md` §3 — any name traceable to the reference app is deleted. |
| S-11 | Test *assertions* from the calibration, believability, soak, cap-laundering, and design-system suites | `Tests/SimTests/Suites/*` | Become the §6 acceptance suite | The assertions are the behavioral contract in executable form. Port the assertions and their bands; the harness and file structure are rewritten (§9: suites must self-register). |

## B. Explicitly rejected — rewrite

Named so the decision is on the record and not relitigated.

| Artifact | Why it does not carry |
|---|---|
| `AppState` (540 lines) | Its central design defect is the reason the game is bland: it discards `SeasonEngine.WeekReport` — the events and news the engine already produced — and re-derives a thinner picture by observing a value. The new `AppState` consumes the event stream (§5). Also: six methods bypass the `mutate` funnel; `isBusy` and `lastError` are written and never read. |
| The whole `Features/` view layer (16 files, ~6,000 lines) | Built against a retired design system with no time layer, and carrying the audit's 78 findings. Every screen is re-specified in `04-SCREENS-UI.md` with an emotional job and a staging spec. |
| `Theme/DesignSystem.swift` and `Theme/Broadcast.swift` as *systems* | Superseded by Primetime. Only the four artifacts in S-07/S-08 survive, as values and math, not as a system. |
| `NewsEngine` (169 lines) | It is string templating over game results with no salience model, no cause tracking, no hooks, no faces, no voices. The `Chronicle` + `Storyteller` design replaces it wholesale. Harvest one lesson: it sorts by `uuidString` explicitly because dictionary order is per-process randomized — that hazard is real and the new code must respect it. |
| `ArcadeFieldView` / `ArcadeGameModel` (916 lines) | The audit's weakest area: partly dead code (`ArcadeGameView`'s only gate is statically false), no accessibility element on the field, unusable in landscape, 62 Hz whole-screen invalidation. Rebuild per `06-PLAYED-GAME-MODE.md` with the §8 concurrency rules. |
| `TestKit` + `main.swift` registration | The harness is retained as a *fallback mechanism* (S-11 ports assertions, not scaffolding), but manual suite registration is a silent-skip hazard: a suite that is written and never listed passes by not running. |
| The nested `Pro-Football-Coach/` directory | A duplicate git repo holding an older copy of the docs. Not code, not canon — delete during P0 housekeeping. |

## C. Harvested bug knowledge (no code, just the lessons)

Hard-won fixes that must not be re-broken. Each becomes a test in the new suite.

1. **Cross-process seed derivation.** `UUID.hashValue` is salted per launch; seeds must derive from identifier bytes. Guarded by a source-scanning test.
2. **Unseeded IDs leak determinism.** v1's `PlayEvent(id: UUID(), …)` is a live leak that its determinism test cannot see, because the test compares scores and stats, not IDs. New rule: no bare `UUID()` or `Date()` in the engine, enforced by the same scanning test.
3. **Dictionary iteration order is per-process randomized.** Any code that folds or picks from a dictionary must sort explicitly first.
4. **The practice squad is a cap-laundering vector.** Sending a signed veteran down must not wipe his cap hit; dead money follows the contract, not a flag; a call-up must be paid for. Three tests, permanently.
5. **The coaching carousel can dead-end a save.** A coach whose contract expires must always have an offer or an explicit sit-out-year path. Never removable.
6. **Save bloat is monotonic without bounds.** The free-agent pool and the news feed both grew unbounded (8.3 MB by season ten). Everything append-only needs a bound and a soak assertion.
7. **The end-of-game state machine is the #1 crash locus in this genre.** 0:00 edge cases, kneel-outs, untimed downs after a defensive penalty, OT caps, and a touchdown as time expires still awarding the try. Exhaustive unit tests, not spot checks.
8. **Contrast tests measure what they are pointed at.** v1's suite verified the rating ladder and team tints rigorously and everything else failed — the test's coverage boundary became the quality boundary. Hence the coverage law.
9. **A `guard` inside a mutation closure still triggers the write.** v1's `refreshGoals` always reassigned, so every week advance paid two full saves. Cheap to reintroduce; assert one write per user action.
10. **Tick loops that accumulate fixed steps drift under load.** Timing-skill mechanics must read wall-clock deltas.

## D. Open salvage questions

- **The arcade's carrier-window durations** (2.5 s pass / 3.5 s run) remain unvalidated guesses — the tooling round trip is ~7 s against a live window of seconds, so only a real thumb on a device can settle them. Carried as a phase gate item for the On the Field phase, not a salvage decision.
