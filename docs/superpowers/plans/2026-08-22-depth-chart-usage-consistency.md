# Depth-Chart Usage Consistency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove detailed and abstract target/carry shares are equivalent within ±2 percentage points for the approved depth-chart buckets.

**Architecture:** Keep the detailed play record authoritative. Make the fixed personnel pool expose one reserve back, let assignment/resolution select eligible receivers and runners, project recorded target/carrier IDs into bounded player counters, then calibrate the abstract allocator on an isolated RNG stream.

**Tech Stack:** Swift 6, Swift Package Manager, the existing `SimTests` harness and TOST `Band`.

## Global Constraints

- Do not change detailed scoring or rate constants to make the abstract model pass.
- Target buckets: WR1, WR2, WR3+, TE, RB, other.
- Carry buckets: RB1, RB2+, QB, other.
- TOST equivalence margin: ±2 percentage points per bucket.
- Existing saves decode missing target/carry counters as zero.

---

### Task 1: Detailed usage mechanics

**Files:**
- Modify: `Sources/FootballSimCore/Engine/Assignment.swift`
- Modify: `Sources/FootballSimCore/Engine/SnapResolver.swift`
- Modify: `Sources/FootballSimCore/Model/DepthChart.swift`
- Modify: `Sources/FootballSimCore/Calibration/CalibrationHarness.swift`
- Test: `Tests/SimTests/Suites/EngineTests.swift`

- [ ] Add a failing pass-assignment test proving an RB can be a route runner.
- [ ] Run `swift run SimTests --engine` and confirm the RB-route assertion fails.
- [ ] Rank WR/TE/RB together for the four route slots and rerun the focused test green.
- [ ] Add a failing seeded run sample proving RB1, RB2, and QB all receive designed carries.
- [ ] Run the engine suite and confirm only RB1 appears.
- [ ] Add one reserve RB to the eligible pool and select runners at 70/25/5 using the existing snap RNG.
- [ ] Run the engine suite green.

### Task 2: Persisted player usage counters

**Files:**
- Modify: `Sources/FootballSimCore/Competition/Statistics.swift`
- Modify: `Sources/FootballSimCore/Engine/DetailedGameSummary.swift`
- Test: `Tests/SimTests/Suites/TwoTierConsistencyTests.swift`

- [ ] Add a failing projection test for target and carry counters.
- [ ] Run `swift run SimTests --two-tier-consistency` and confirm the counters are absent.
- [ ] Add bounded `targets` and `carries` fields with backward-compatible decoding.
- [ ] Count every recorded pass target and designed-run carrier in `DetailedGameSummaryBuilder.make`.
- [ ] Rerun the focused suite green.

### Task 3: TOST and abstract calibration

**Files:**
- Modify: `Sources/FootballSimCore/Abstracted/AbstractGameSimulator.swift`
- Modify: `Sources/FootballSimCore/Rules/CompetitionRules.swift`
- Modify: `Tests/SimTests/Suites/TwoTierConsistencyTests.swift`

- [ ] Add per-world target/carry share helpers and one TOST check per approved bucket.
- [ ] Run the 100-world release gate and record the expected abstract divergence.
- [ ] Allocate abstract targets/carries on a new derived RNG ordinal using the detailed rates.
- [ ] Rerun the release gate until all listed buckets pass without widening ±2 points.
- [ ] Run rewrite-tournament, confidence-review, save compatibility, `detect_changes`, and the final release gate.
