import FootballSimCore
import Foundation

private func usage() -> Never {
    fputs("usage: CalibrationScore <tuning|holdout>\n", stderr)
    exit(EXIT_FAILURE)
}

guard CommandLine.arguments.count == 2 else { usage() }

let seeds: [UInt64]
switch CommandLine.arguments[1] {
case "tuning":
    seeds = CalibrationHarness.tuningSeeds
case "holdout":
    seeds = CalibrationHarness.holdoutSeeds
default:
    usage()
}

let reports = Tier.allCases.map { CalibrationHarness.run(tier: $0, seeds: seeds) }
for report in reports {
    print(report.summary)
}

let results = reports.flatMap(\.results)
let passed = results.filter(\.passed).count
print("SCORE \(passed)/\(results.count)")
