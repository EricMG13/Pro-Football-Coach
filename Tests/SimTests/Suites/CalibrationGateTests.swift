import Foundation
import FootballSimCore

// The engine measured against `01` section 6.5's bands, which nothing else does.
//
// `--calibration` tests the instrument: TOST arithmetic, total variation distance, the shape of the
// band table, harness reproducibility. It never runs the engine past a band. So for as long as it
// was the only calibration command, `docs/STATUS.md`'s "P4's calibration gate stays red" described
// prose rather than a test — the distinction `CLAUDE.md` forbids blurring, and a regression in the
// engine's numbers would have been invisible until someone re-ran the harness by hand.
//
// **This gate is red today, by design, and is not in any lane `verify.sh` runs.** It is registered
// exactly as `--pro-soak` is: out of the default run, red to say so.
//
// It reports against the **holdout** ladder. `01` section 6.6 clause 2: tune against A, report
// against B. Gating on the tuning ladder would gate the model on the seeds it was fitted to.
func runCalibrationGateTests() {
    suite("Calibration gate") {
        for tier in Tier.allCases {
            test("the \(tier.rawValue) engine holds every band on the holdout ladder") {
                let report = CalibrationHarness.run(tier: tier, seeds: CalibrationHarness.holdoutSeeds)
                // Printed whole, passing rows included. A calibration failure is read by comparing
                // the interval to the band, and 01 section 6.6 clause 3's contract is that every
                // row carries theta, CI90, the band, n and its confidence grade.
                print("--- \(tier.rawValue): \(report.gamesPlayed) games, "
                        + "\(report.failures.count) of \(report.results.count) bands failing")
                print(report.summary)
                expect(report.passed,
                       "\(report.failures.count) of \(report.results.count) \(tier.rawValue) bands "
                           + "fail on the holdout ladder:\n"
                           + report.failures.map(\.report).joined(separator: "\n"))
            }
        }
    }
}
