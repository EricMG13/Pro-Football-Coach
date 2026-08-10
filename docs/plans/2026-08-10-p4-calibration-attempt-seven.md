# P4 Calibration Attempt Seven — Execution Plan

> **For Codex:** Execute task by task in this isolated worktree. Use TDD for behavior changes, review every task before proceeding, and do not widen evidence bands to make the engine pass.

**Goal:** Restore a statistically valid, reproducible calibration workflow and run the handoff's seventh bounded tuning attempt against tuning seeds before evaluating untouched holdout seeds.

**Architecture:** Keep calibration math in `FootballSimCore`, expose a small checked-in command-line scoring target, and let the shell script coordinate only constant search. Preserve the deterministic engine and the tuning/holdout boundary.

**Tech stack:** Swift 5 language mode with Swift Package Manager; Bash orchestration; the existing hand-rolled `SimTests` harness.

## Global constraints

- `docs/01-RESEARCH.md` §6.2 requires TOST: a 90% confidence interval must lie entirely within the evidence band. Point-estimate range membership is forbidden.
- Rate standard error is `sqrt(p(1-p)/n)` in probability units and must be converted back into the estimate's displayed units.
- Tune only against `CalibrationHarness.tuningSeeds`; evaluate `holdoutSeeds` only after tuning is complete.
- Never widen a band to make a failing engine pass.
- Preserve deterministic output across processes and avoid `hashValue` in seeded paths.
- Do not use checkout, restore, stash, reset, or clean while implementing or reviewing.

## Task 1: Make rate confidence intervals unit-aware

**Files:**

- Modify: `Sources/FootballSimCore/Calibration/Band.swift`
- Modify: `Sources/FootballSimCore/Calibration/CalibrationHarness.swift`
- Test: `Tests/SimTests/Suites/CalibrationTests.swift`

**Requirements:**

1. Add a failing test proving a percentage-valued rate such as 65 at scale 100 has a non-zero standard error expressed in percentage points.
2. Make `Estimate` carry the scale of a rate, defaulting to 1 for existing fractional rates and means.
3. Compute the Bernoulli standard error from `value / scale`, then return it in the original displayed units.
4. Have `CalibrationHarness.rateEstimate` pass its scale into `Estimate`.
5. Preserve all existing fractional-rate behavior and reporting.

**Verification:** Run the focused calibration suite through `swift run SimTests --suite TOST` if supported by the harness; otherwise run `swift run SimTests` and capture the relevant failing-then-passing evidence.

## Task 2: Check in a reproducible calibration scorer

**Files:**

- Modify: `Package.swift`
- Create: `Tools/CalibrationScore/main.swift`
- Modify: `scripts/tune-calibration.sh`
- Test: `Tests/SimTests/Suites/ContractTests.swift` or a focused shell smoke test, whichever directly proves the changed contract without duplicating implementation.

**Requirements:**

1. Replace the external `/private/tmp` scratch package with a checked-in `CalibrationScore` executable target that depends on `FootballSimCore`.
2. Accept an explicit `tuning` or `holdout` seed-set argument, print each tier's band report, and print a machine-readable final `SCORE passed/total` line.
3. Reject missing or unknown seed-set arguments with a non-zero exit and concise usage text.
4. Resolve the repository root from the tuning script's own location; contain all edits to that root and fail if a named constant is missing or ambiguous.
5. Use strict shell error handling. A failed build, score, or replacement must stop the search instead of being treated as a zero score.
6. Keep coordinate descent bounded to the constants and grids in the handoff.

**Verification:** Run scorer argument-error checks, one tuning score, one holdout score, and the full verification suite.

## Task 3: Run bounded tuning attempt seven

**Files:**

- Modify only the searched constants in `Sources/FootballSimCore/Rules/MatchupRules.swift` when the winning candidate improves the tuning score.
- Record evidence in `docs/HANDOFF-2026-08-10.md` and `docs/STATUS.md`.

**Requirements:**

1. Record the pre-search tuning score and complete reports.
2. Run `scripts/tune-calibration.sh` to completion against tuning seeds only.
3. Record the final tuning score and full tuning report.
4. Run untouched holdout seeds exactly once after search, and record the full holdout report.
5. Do not retain constant changes that fail to improve the tuning score.
6. If all 24 implemented bands do not pass, invoke D2's architecture falsifier honestly and identify the smallest model deficiency supported by the reports. Do not opportunistically broaden P4.

## Task 4: Final gates and handoff

1. Run `rewrite-tournament` in no-argument post-edit mode on non-trivial changed functions.
2. Run `confidence-review`, investigate every low-confidence point to root cause, and patch confirmed defects.
3. Run `./scripts/verify.sh` and report the exact test/check counts.
4. Update status and handoff documents with commands, scores, remaining failed bands, and the next justified action.

