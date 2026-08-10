# P4 Run Resolution Attempt Eight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the run resolver's zero-centred yardage shape with a positive ordinary-run baseline and a run-specific broken-tackle tail, then run the fifth consecutive genuine P4 model-tuning attempt against the fixed TOST bands.

**Architecture:** Preserve assignment, leverage, causal matchup records, explicit seeded RNG, and the bounded break-tackle chain. Separate rushing yards after contact from passing yards after catch so the run tail can be corrected without inflating a passing model that already exceeds its yardage band. Add a 2.0-yard run baseline before rounding and make each rushing tackle break worth 7 yards; retain the existing 4-yard increment for pass YAC.

**Tech Stack:** Swift 5 language mode with Swift Package Manager; the existing hand-rolled `SimTests` harness; the checked-in `CalibrationScore` executable and calibration shell contracts.

## Global Constraints

- `docs/03-MATCH-ENGINE.md` §1.1 requires assignment → leverage → resolution → consequence in fixed order, with every run produced by lane and carrier-versus-pursuit matchups.
- The engine remains pure Swift with zero `import SwiftUI`; every numeric rule lives in a rules module rather than inline.
- The engine owns every probability; rendering cannot reroll or change an outcome.
- Preserve deterministic output across processes, explicit hierarchical seeds, and the bans on `hashValue` and ambient `UUID()`/`Date()` in seeded paths.
- `docs/01-RESEARCH.md` §6.2 requires TOST: a 90% confidence interval must lie entirely within the evidence band. Point-estimate membership is not a pass.
- Never widen a band to make the engine pass.
- `CalibrationHarness.tuningSeeds` are the selection set. The set named `holdoutSeeds` is already exposed and is evaluation evidence only; run it once after the attempt and do not describe it as blinded.
- Attempt eight is the fifth consecutive genuine model-tuning attempt in D2's ledger. If any implemented band remains red after this attempt, record D2 as falsified and stop tuning the hybrid model.
- Do not use checkout, restore, stash, reset, or clean while implementing or reviewing.

---

### Task 1: Separate the rushing baseline and tackle-break tail from pass YAC

**Files:**

- Modify: `Sources/FootballSimCore/Rules/MatchupRules.swift`
- Modify: `Sources/FootballSimCore/Engine/SnapResolver.swift`
- Modify: `Tests/SimTests/Suites/EngineTests.swift`

**Interfaces:**

- Consumes: `SnapResolver.resolve(offensiveCall:defensiveCall:personnel:situation:rules:homeFieldAdvantage:rng:)`, `Leverage.score`, and the existing bounded carrier-versus-pursuit chain.
- Produces: `MatchupRules.baseRunYards: Double`, `MatchupRules.runBrokenTackleYards: Int`, and `MatchupRules.yardsAfterCatchPerBreak: Int`; `yardsAfterContact` gains a private `yardsPerBreak: Int` parameter.

- [ ] **Step 1: Add a failing run-shape regression test**

Add this test inside `suite("Snap resolution")` in `Tests/SimTests/Suites/EngineTests.swift`:

```swift
        test("an even run game has ordinary gains and a reachable explosive tail") {
            var rng = SeededRandom(seed: 8_008)
            var yards = 0
            var explosive = 0
            let attempts = 12_000
            for attempt in 0..<attempts {
                let outcome = SnapResolver.resolve(
                    offensiveCall: OffensiveCall(
                        playType: .run,
                        runGap: RunGap.allCases[attempt % RunGap.allCases.count]
                    ),
                    defensiveCall: DefensiveCall(coverage: .zoneUnder),
                    personnel: even,
                    situation: Situation(),
                    rules: rules,
                    rng: &rng
                )
                yards += outcome.yards
                if outcome.yards >= MatchupRules.explosiveRunYards { explosive += 1 }
            }
            let yardsPerCarry = Double(yards) / Double(attempts)
            let explosiveRate = Double(explosive) / Double(attempts)
            expect((3.4...4.8).contains(yardsPerCarry),
                   "even rushing averaged \(yardsPerCarry) yards per carry")
            expect((0.09...0.15).contains(explosiveRate),
                   "even rushing produced an explosive rate of \(explosiveRate)")
        }
```

- [ ] **Step 2: Run the full executable suite and capture the expected RED**

Run:

```bash
swift run -c release SimTests
```

Expected: non-zero exit; the new test reports roughly 1.3 yards per carry and roughly 0.03 explosive rate, outside both asserted ranges. No pre-existing test may fail.

- [ ] **Step 3: Add the run-specific rules**

Replace the run-yard rules in `Sources/FootballSimCore/Rules/MatchupRules.swift` with:

```swift
    /// Ordinary forward progress before lane leverage and contact are applied.
    ///
    /// A zero-centred lane cannot represent a real carry: an even line produced a zero-yard mode
    /// and only 1.33 yards per pro carry. The positive baseline carries the ordinary mass while
    /// lane leverage still moves each play above or below it.
    public static let baseRunYards = 2.0
    /// Yards per unit of lane leverage.
    public static let laneYardScale = 3.0
    /// Outside runs multiply the lane result, trading certainty for the edge.
    public static let outsideRunVariance = 1.35
    public static let crashRunBonus = 0.10
    public static let aggressionRunBonus = 0.05
    /// Leverage above which the carrier breaks a tackle.
    public static let breakTackleThreshold = 0.45
    /// A rushing tackle break gets the carrier through a level of the defence.
    public static let runBrokenTackleYards = 7
    /// A catch starts downfield, so its smaller YAC increment remains independent of rushing.
    public static let yardsAfterCatchPerBreak = 4
```

Keep `brokenTackleDecay` and `maximumBrokenTackles` unchanged immediately below this block.

- [ ] **Step 4: Parameterise contact yards and apply the positive run baseline**

In `resolvePass`, pass `yardsPerBreak: MatchupRules.yardsAfterCatchPerBreak` to `yardsAfterContact`.

In `resolveRun`, pass `yardsPerBreak: MatchupRules.runBrokenTackleYards` to `yardsAfterContact`, and replace the yardage calculation with:

```swift
        let gained = Int((MatchupRules.baseRunYards
            + lane * MatchupRules.laneYardScale * outside).rounded()) + broken
```

Change the private helper signature to:

```swift
    private static func yardsAfterContact(
        carrier: Player,
        pursuit: [Player],
        aggression: Double,
        homeFieldAdvantage: Double,
        yardsPerBreak: Int,
        rng: inout SeededRandom
    ) -> (yards: Int, record: MatchupRecord?) {
```

Inside its successful-break branch, replace the shared increment with:

```swift
            yards += yardsPerBreak * (attempt + 1)
```

- [ ] **Step 5: Run tests and verify GREEN**

Run:

```bash
swift run -c release SimTests
```

Expected: zero exit; the new run-shape test passes, all existing tests pass, and only the two pinned cross-process fingerprints fail if they have not yet been updated.

- [ ] **Step 6: Re-pin deterministic fingerprints as an explicit consequence of the accepted engine change**

Read the two actual fingerprint values printed by the failing pro and college assertions. Replace only the corresponding source literals in `Tests/SimTests/Suites/EngineTests.swift`, then run:

```bash
swift run -c release SimTests
swift run -c release SimTests
```

Expected: both independent processes exit zero with identical test/check totals and the same pinned values.

- [ ] **Step 7: Run post-edit quality workflows**

Run `rewrite-tournament` in no-argument post-edit mode on `resolvePass`, `resolveRun`, and `yardsAfterContact`. Then run `confidence-review`, enumerate every low-confidence point, investigate each to root cause, and patch confirmed defects before continuing.

- [ ] **Step 8: Commit the engine task**

```bash
git add Sources/FootballSimCore/Rules/MatchupRules.swift Sources/FootballSimCore/Engine/SnapResolver.swift Tests/SimTests/Suites/EngineTests.swift
git commit -m "fix: reshape rushing outcomes"
```

---

### Task 2: Run attempt eight and adjudicate D2 and P4

**Files:**

- Modify: `docs/HANDOFF-2026-08-10.md`
- Modify: `docs/STATUS.md`
- Modify: `docs/OPEN-DECISIONS.md` only if D2's five-attempt falsifier fires.

**Interfaces:**

- Consumes: checked-in `CalibrationScore tuning`, `CalibrationScore holdout`, the fixed 24 implemented bands, and D2's attempt ledger.
- Produces: immutable attempt-eight tuning/evaluation evidence and an explicit D2/P4 gate decision.

- [ ] **Step 1: Run the tuning scorer once on the accepted engine**

Run:

```bash
swift run -c release CalibrationScore tuning
```

Capture every band line and the final exact `SCORE passed/24` line in the task report. This is the attempt-eight tuning result; do not run coordinate search or change another engine constant after seeing it.

- [ ] **Step 2: Run the exposed evaluation set once**

Run:

```bash
swift run -c release CalibrationScore holdout
```

Capture every band line and the final exact `SCORE passed/24` line. Call this deterministic evaluation evidence, not blinded holdout evidence.

- [ ] **Step 3: Apply the pre-declared falsifier**

If tuning reports `SCORE 24/24`, leave D2 selected and mark P4 G5 green only if the evaluation report also returns `SCORE 24/24`.

If either report is below `24/24`, update `docs/OPEN-DECISIONS.md` D2 from **Choice** to **Falsified choice**, state that attempt eight completed the five consecutive genuine model-tuning failures, and identify option (b), the play-outcome distribution model with a causal visualisation record, as the required successor design. Do not start a sixth hybrid-model tuning attempt.

- [ ] **Step 4: Record exact evidence and the next gate**

Update `docs/HANDOFF-2026-08-10.md` and `docs/STATUS.md` with:

- the before diagnostic (1.33 pro yards/carry and 3.27% explosive) plus the exact attempt-eight pro rush-yards and explosive-run CI90 values,
- the complete tuning and evaluation failure lists with CI90, fixed band, and violated edge,
- the exact tuning and evaluation scores,
- the D2 ledger at 5 of 5 if any band remains red,
- P4 G5's actual state,
- and the next action: either P5 if G5 is green, or a written successor architecture plan if D2 is falsified.

- [ ] **Step 5: Run final verification**

Run:

```bash
./scripts/verify.sh
git diff --check
```

Expected: build PASS, calibration-tool contracts `23/23 PASS`, all `SimTests` pass, verification reports 3 passed and 0 failed, and `git diff --check` emits no output.

- [ ] **Step 6: Run final confidence review and commit the evidence task**

Run `confidence-review` over the complete task diff. Patch confirmed issues, rerun the covering checks, then commit only the three possible documentation paths:

```bash
git add docs/HANDOFF-2026-08-10.md docs/STATUS.md docs/OPEN-DECISIONS.md
git commit -m "docs: record calibration attempt eight"
```
