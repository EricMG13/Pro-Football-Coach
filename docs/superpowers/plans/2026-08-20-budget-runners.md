# Budget Runners Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make each product budget claim runnable only when it emits an observed figure, beginning with the 134-programme college week advance and its recruiting-AI component.

**Architecture:** Keep timing outside `WorldScheduler`: a focused `PerformanceBudgetTests` suite prepares a shipping-size `GameState`, times the production `CollegeRecruitingAISystem.process(in:)` function on that state, and times `WorldScheduler.advanceWeek(_:)`. `SuiteCatalog` names the command/function pair; `main.swift` dispatches it. The owner-only agency duration stays unregistered until observed timings exist, so no runner can fabricate a figure.

**Tech Stack:** Swift 6, Swift Package Manager executable test harness, `ContinuousClock`.

## Global Constraints

- D4 college week target is 1.2 s and hard ceiling is 2.0 s at about 134 programmes.
- A Mac result is host evidence, never an iPhone 15-class device result.
- The test runner must print measurements in debug and Release; it must not claim an estimate as an observation.
- Preserve the fixed scheduler sequence; do not instrument or alter `WorldScheduler.advanceWeek`.
- Do not publish `AgencyBudgetTests` or move it into PRODUCT commitments without an owner-observed season duration.

---

### Task 1: Add a focused performance-budget runner

**Files:**
- Create: `Tests/SimTests/Suites/PerformanceBudgetTests.swift`
- Modify: `Tests/SimTests/SuiteCatalog.swift:6-96`
- Modify: `Tests/SimTests/main.swift:10-16`

**Interfaces:**
- Consumes: `GameState.bootstrap(seed:)`, `CollegeRecruitingAISystem.process(in:)`, `WorldScheduler.advanceWeek(_:)`, `ContinuousClock`.
- Produces: `func runPerformanceBudgetTests()` and the dispatch pair `--performance-budget → runPerformanceBudgetTests`.

- [ ] **Step 1: Write the failing dispatch-coverage test**

Add a `SuiteCatalog` assertion that requires a `PerformanceBudgetTests` entry with exactly this runner:

```swift
expectEqual(
    SuiteCatalog.runner(for: .performanceBudget),
    SuiteCatalog.Runner(
        command: "--performance-budget",
        function: "runPerformanceBudgetTests"
    )
)
```

- [ ] **Step 2: Run the focused harness to verify it fails**

Run: `swift run -c release -Xswiftc -enable-testing SimTests --commitment-coverage`

Expected: failure because `performanceBudget` and its runner do not exist.

- [ ] **Step 3: Add the minimal runner and measurement suite**

Register the release gate as `PerformanceBudgetTests` in lane `performance`, give it the exact dispatch pair above, and add the `main.swift` branch. The suite must bootstrap the fixed seed, assert `state.programmes.count == 134`, time one `CollegeRecruitingAISystem.process(in:)` execution, then time one real `WorldScheduler.advanceWeek(_:)` execution. Print the two observed seconds alongside the 1.2 s target and 2.0 s ceiling.

- [ ] **Step 4: Run the focused harness to verify it passes**

Run: `swift run -c release -Xswiftc -enable-testing SimTests --performance-budget`

Expected: the suite prints programme count, recruiting-AI seconds, week-advance seconds, target and ceiling, then exits 0 unless the production work itself throws.

### Task 2: Verify catalog coverage and Release evidence

**Files:**
- Modify: `PRODUCT.md:83-110` only if the runner and a real figure exist.

**Interfaces:**
- Consumes: `SuiteCatalog.printCatalog()`, `runCommitmentCoverageTest()`, and Task 1 output.
- Produces: a machine-verifiable runner record and a dated, hardware-qualified host measurement.

- [ ] **Step 1: Run the catalog command**

Run: `swift run -c release -Xswiftc -enable-testing SimTests --catalog`

Expected: `PerformanceBudgetTests` ends with `--performance-budget → runPerformanceBudgetTests`.

- [ ] **Step 2: Run the commitment-coverage harness**

Run: `swift run -c release -Xswiftc -enable-testing SimTests --commitment-coverage`

Expected: it does not report the performance gate as missing a runner. Any remaining agency failure is evidence that the agency figure is still unavailable, not a reason to misstate one.

- [ ] **Step 3: Record the observed result**

Report only the command output from Step 1's performance execution with the local hardware model, chip, core count, memory, and operating-system version. Compare total week advance to 1.2 s and 2.0 s; report recruiting AI separately without treating it as a share inferred from the total.

### Task 3: Add agency evidence only after owner observation

**Files:**
- Modify: `Tests/SimTests/SuiteCatalog.swift`
- Modify: `Tests/SimTests/main.swift`
- Create: `Tests/SimTests/Suites/AgencyBudgetTests.swift`
- Modify: `PRODUCT.md`

**Interfaces:**
- Consumes: owner-recorded, timestamped durations for a defined season completion protocol.
- Produces: `func runAgencyBudgetTests()` and `--agency-budget → runAgencyBudgetTests` only when the measured inputs are present.

- [ ] **Step 1: Obtain owner-observed agency timings**

Use the D1 owner protocol in `docs/01-RESEARCH.md`; capture the actual session duration, hardware, app build and protocol count. Do not use design-time call-in or drive-summary constants.

- [ ] **Step 2: Write a failing test for the actual recorded figure**

Define the runner's input as the exact observed duration and assert it against the product's 6–8 hour target. Verify it fails before any runner implementation if the figure is outside that range.

- [ ] **Step 3: Implement and dispatch the runner**

Register `AgencyBudgetTests` in the performance lane, dispatch `--agency-budget` to `runAgencyBudgetTests`, and make the function print the recorded measurement and the hardware that produced it.

- [ ] **Step 4: Run and verify the runner**

Run: `swift run -c release -Xswiftc -enable-testing SimTests --agency-budget`

Expected: an observed duration and its hardware are printed, with no inferred values.

## Self-review

- D4’s target, ceiling, shipping-size fixture and recruiting-AI term are covered by Tasks 1–2.
- The plan deliberately rejects the critical-risk scheduler instrumentation path.
- Agency work is intentionally blocked on owner observation; making a placeholder runner would violate the goal’s no-estimate rule.
