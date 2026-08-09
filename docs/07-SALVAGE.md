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
| S-10 | `NameBank` name/college pools (uniform draw — there is no weighting layer) | `Generation/NameBank.swift` (80 lines) | Unchanged, with two amendments | Original fictional content that already exists and is legally clean. **Amendment 1:** the college bank must be regenerated independently per `02-GAME-DESIGN.md` §3 — any name traceable to the reference app is deleted. **Amendment 2:** the pools alone provide no uniqueness guard — 226 first × 250 last names drawn uniformly across a ~2,200-player league makes duplicate full names routine, and a duplicate is an attachment bug (Pillar P5: every number has a face, and two faces cannot share one). Add a re-draw guard at generation. |
| S-11 | Test *assertions* from the calibration, believability, soak, cap-laundering, coach-tenure, coaching-carousel, arcade-kernel, and design-system suites | `Tests/SimTests/Suites/*` | Become the §6 acceptance suite | The assertions are the behavioral contract in executable form. Port the assertions and their bands; the harness and file structure are rewritten (§9: suites must self-register). **Amendment:** `SeededRandomTests` does *not* cover the two members S-01 calls load-bearing — there is no test for `seed(from:)` and none for `uuid()`. The new suite must add them: `seed(from:)` is order-sensitive and stable across processes; `uuid()` is reproducible from a seed, RFC-4122 version-4/variant correct, and non-repeating within a stream. |
| S-12 | `TeamMark.legibleMotif(_:on:minimum:)` + its `blend` helper | `Theme/TeamMark.swift:62` | Unchanged as values-and-math: guarantees a club's secondary is visible against its own primary | Same class of asset as S-07, and it encodes a hazard nothing else covers: two colors can differ in hue and still share a luminance — one club's field and trim measure 1.02:1, so the mark would have vanished into itself. The 32-club table in `02-GAME-DESIGN.md` §2 verifies primaries against *white*; this verifies secondaries against *their own primary*. Both checks are required. |

## B. Explicitly rejected — rewrite

Named so the decision is on the record and not relitigated.

| Artifact | Why it does not carry |
|---|---|
| `AppState` (540 lines) | Its central design defect is the reason the game is bland: it discards `SeasonEngine.WeekReport` — the events and news the engine already produced — and re-derives a thinner picture by observing a value. The new `AppState` consumes the event stream (§5). Also: **eleven sites across ten methods** bypass the `mutate` funnel (four of them to return an outcome, so the funnel needs a value-returning variant). On the two status fields, precisely: `isBusy` is **dead** — declared, never written, never read — so long loads froze the UI with no indication; `lastError` *is* surfaced through a RootView alert, but only ever populated on the persist/flush paths. |
| The whole `Features/` view layer (16 files, ~6,000 lines) | Built against a retired design system with no time layer, and carrying the audit's 78 findings. Every screen is re-specified in `04-SCREENS-UI.md` with an emotional job and a staging spec. |
| `Theme/DesignSystem.swift` and `Theme/Broadcast.swift` as *systems* | Superseded by Primetime. Only the four artifacts in S-07/S-08 survive, as values and math, not as a system. |
| `NewsEngine` (169 lines) | It is string templating over game results with no salience model, no cause tracking, no hooks, no faces, no voices. The `Chronicle` + `Storyteller` design replaces it wholesale. Harvest one lesson: it sorts by `uuidString` explicitly because dictionary order is per-process randomized — that hazard is real and the new code must respect it. |
| ~~`ArcadeFieldView` / `ArcadeGameModel`~~ — **superseded, see note below** | The audit's grounds still hold against the 4B code (no accessibility element on the field, unusable in landscape, 62 Hz whole-screen invalidation); the dead-code clause is historical only — `ArcadeGameView.swift` was already deleted in `0dfd54a`. **But Phase 4C has since rewritten this area** around the all-22 field, and that work is now merged. It is not a salvage candidate: it is current code, built against `06-PLAYED-GAME-MODE.md` Revision 2, and it must be re-assessed against the new canon rather than rejected on a stale audit. See §E. |
| `TestKit` + `main.swift` registration | The harness is retained as a *fallback mechanism* (S-11 ports assertions, not scaffolding), but manual suite registration is a silent-skip hazard: a suite that is written and never listed passes by not running. |
| The nested `Pro-Football-Coach/` directory | A duplicate git repo holding an older copy of the docs. Not code, not canon — delete during P0 housekeeping. |

## C. Harvested bug knowledge (no code, just the lessons)

Hard-won fixes that must not be re-broken. Each becomes a test in the new suite.

1. **Cross-process seed derivation.** `UUID.hashValue` is salted per launch; seeds must derive from identifier bytes.
2. **Unseeded IDs leak determinism.** v1's `PlayEvent(id: UUID(), …)` is a live leak its determinism test cannot see, because that test compares scores and stats, not IDs. New rule: no `UUID()` or `Date()` as an argument or assignment in `Engine/` or `Generation/` (default-valued `= UUID()` on `Model/` initialisers stays legal — twelve of the thirteen existing sites are exactly that).
2b. **The v1 scanner that guards lesson 1 is weaker than it looks**, and lesson 2's rule inherits the weakness if copied. It matches `line.contains(".hashValue") && !line.contains("//")`, so any offending line carrying a trailing comment is silently exempt — and it never looks for `UUID()` at all, which is why the leak in lesson 2 survives a green suite. The new scanner strips comments properly, covers both patterns, and ships a self-test that fails on a planted offender.
3. **Dictionary iteration order is per-process randomized.** Any code that folds or picks from a dictionary must sort explicitly first.
4. **The practice squad is a cap-laundering vector with four doors, not three.** (a) Demotion must not wipe a signed veteran's cap hit. (b) Releasing him after demotion must not erase his dead money — dead money follows the contract, never a flag. (c) A call-up must be paid for. (d) **Re-signing is the fourth door:** a negotiated contract written onto a player still carrying the practice-squad flag would be charged at the stipend; likewise a signing routed with `practiceSquad: true`. v1 covers these across two suites and eight assertions. All four doors stay locked, permanently.
5. **The coaching carousel can dead-end a save.** A coach whose contract expires must always have an offer or an explicit sit-out-year path. Never removable.
5b. **Coach tenure bugs only a second or third season reveals.** Three, from v1's tenure suite: the contract clock ran double (a three-year deal must leave two years after one season, not burn two); the trophy case followed the *employer* rather than the man, so a coach changing jobs lost his own record; and with firing disabled, the calendar could still evict him — the toggle must block every eviction path, not just the performance one. Multi-season tests, not single-season ones, are the only thing that catches this class.
6. **Save bloat is monotonic without bounds.** The free-agent pool and the news feed both grew unbounded (8.3 MB by season ten). Everything append-only needs a bound and a soak assertion.
7. **The end-of-game state machine is the #1 crash locus in this genre.** 0:00 edge cases, kneel-outs, untimed downs after a defensive penalty, OT caps, and a touchdown as time expires still awarding the try. Exhaustive unit tests, not spot checks.
8. **Contrast tests measure what they are pointed at.** v1's suite verified the rating ladder and team tints rigorously and everything else failed — the test's coverage boundary became the quality boundary. Hence the coverage law.
9. **A `guard` inside a mutation closure still triggers the write.** v1's `refreshGoals` always reassigned, so every week advance paid two full saves. Cheap to reintroduce; assert one write per user action.
10. **Tick loops that accumulate fixed steps drift under load.** Timing-skill mechanics must read wall-clock deltas.

## E. Phase 4C — merged, not salvaged

The all-22 arcade layer (`Sources/FootballSimCore/Arcade/*`, `FieldCanvas.swift`, the rewritten `ArcadeFieldView`/`ArcadeGameModel`, `ArcadeTuning.swift`, and ~1,100 lines of arcade tests) arrived from `origin/main` after this ledger was first drafted. It is **current code built against current canon** — `06-PLAYED-GAME-MODE.md` Revision 2 — so it is outside the salvage question entirely.

Three things it changes for this program:

1. **Its design already satisfies several rebuild rules** the old arcade violated: portrait (so the app locks portrait everywhere and the audit's orientation class disappears), honest indicators that never show a false green, a tested reconciliation invariant (the play you watch ends where the emitted event says), a VoiceOver-playable control variant, and SwiftUI `Canvas` instead of SpriteKit — which is why `03-ARCHITECTURE.md` §1 now names Canvas.
2. **It is unverified.** `swift build` succeeds as of 2026-08-09 — its first compile — but the suite has not been run against it. See OD-6.
3. **It must still re-earn the Primetime and witness-layer rules** during its phase: staging through `StagingDirector`, the six-sound/eight-haptic vocabularies rather than its own ad-hoc set, flat surfaces rather than the gradients its §7 currently describes, and chronicle events emitted for its plays.

## F. Parity ledger

The instrument for the parity gate. Derived from v1's 29 registered test suites and `docs/STATUS.md` §"Complete and tested" — one row per shipped mechanic. **A row may only move to `dropped` by an owner decision recorded in `OPEN-DECISIONS.md`.** Update `Rebuild phase` and `Status` at each gate.

| v1 mechanic | v1 evidence (suite) | Rebuild phase | Status |
|---|---|---|---|
| Seeded RNG, cross-process determinism | SeededRandom, DeterminismUnderOffseason | P1 | carried |
| Player / contract / team / league model | Model, Generation | P1 | carried |
| League & roster generation, draft origins | Generation, DraftOrigin | P1 | carried |
| Play-by-play game simulation | GameSimulator | P2 | carried |
| Calibration & believability bands | GameSimulator (Calibration) | P2 | carried |
| Schedule generation, standings, tiebreakers | Season | P3 | carried |
| Weekly loop, playoffs, phase transitions | Season | P3 | carried |
| News feed | (NewsEngine, no suite) | P3 | **replaced** by the chronicle/Storyteller |
| Salary cap, dead money, proration | FrontOffice | P7 | carried |
| Practice squad moves & anti-laundering | RosterMove, PracticeSquadCap, ReSignSquad | P7 | carried |
| Re-signing & negotiation | FrontOffice, ReSignSquad | P7 | carried |
| Free agency waves & interest | FrontOffice | P7 | carried |
| Trades & value chart | FrontOffice | P7 | carried |
| Depth chart honesty | DepthHonesty | P6 | carried |
| Fourth-down decisions & advice | FourthDown | P2/P5 | carried |
| Matchup odds | MatchupOdds | P5 | carried |
| Draft class, scouting fog, AI picks | InteractiveDraft | P8 | carried |
| Interactive draft session | InteractiveDraft | P8 | carried |
| Progression, camp, retirements | Dynasty | P8 | carried |
| Awards, records book, Hall of Fame | Legacy | P8 | carried |
| Coach XP, skill trees, goals | Experience | P8 | carried |
| Coaching carousel & no-dead-end invariant | CoachCarousel | P8 | carried |
| Coach tenure (clock, trophies, firing toggle) | CoachTenure | P8 | carried |
| Ten-season soak | Dynasty | P8 | carried |
| Scenarios (3) | Legacy | P10 | carried |
| Save/load, backup, migration | Persistence | P1/P7 | carried |
| Coalescing save queue | SaveQueue | P1 | carried (S-05) |
| Rating ladder & contrast discipline | DesignSystem, Broadcast, TeamTint | P4 | carried (S-07/S-08/S-12) |
| Interactive game (watch + takeover) | InteractiveGame | P5 | carried |
| Arcade all-22 field, kernel, watch mode | Arcade, ArcadeField, ArcadeWatch | P9 | current code (§E) |

One deliberate replacement above: v1's `NewsEngine` is not carried, because the witness layer subsumes it (§B). That is a replacement, not a drop — the *capability* survives and grows.

## D. Open salvage questions

- **The arcade's carrier-window durations** (2.5 s pass / 3.5 s run) remain unvalidated guesses — the tooling round trip is ~7 s against a live window of seconds, so only a real thumb on a device can settle them. Carried as a phase gate item for the On the Field phase, not a salvage decision.
