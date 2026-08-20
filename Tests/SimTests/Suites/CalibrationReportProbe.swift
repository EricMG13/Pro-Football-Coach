import Foundation
import FootballSimCore

// A probe, not a gate: it prints what `CalibrationHarness` measures over the tuning ladder so a
// divergence can be attributed to a model rather than guessed at.
//
// It exists because `--calibration` tests the *instrument* — TOST, TVD, the band table — and never
// runs the engine against the bands. Until a lane does, this is the only way to read the detailed
// model's level, and it prints rather than asserts so that reading it is never mistaken for a gate.
func runCalibrationReportProbe() {
    for tier in Tier.allCases {
        for (name, seeds) in [("tuning", CalibrationHarness.tuningSeeds),
                              ("holdout", CalibrationHarness.holdoutSeeds)] {
            let report = CalibrationHarness.run(tier: tier, seeds: seeds)
            print("--- \(tier.rawValue) / \(name) ladder — \(report.gamesPlayed) games ---")
            print(report.summary)
        }
    }
}
