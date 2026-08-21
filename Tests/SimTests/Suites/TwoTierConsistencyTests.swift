import Foundation
import FootballSimCore

private enum TwoTierConsistency {
    static let pointsPerGameMargin = 0.75
    /// Twenty worlds provide 12,800 paired team observations per tier. These are disjoint from the
    /// 190- and 290-series tuning worlds used to calibrate the abstracted scoring baselines.
    static let worldSeeds: [UInt64] = Array(390_210...390_229)
    static let sampledGames = 320
}

private struct TwoTierPointsSample {
    var abstracted: [Double] = []
    var detailed: [Double] = []
}

private func collectTwoTierPoints(tier: Tier) -> TwoTierPointsSample {
    var sample = TwoTierPointsSample()
    for worldSeed in TwoTierConsistency.worldSeeds {
        for fixture in 0..<TwoTierConsistency.sampledGames {
            let ladder = CalibrationHarness.talentLadder(matchup: fixture)
            let home = CalibrationRoster.team(
                skill: ladder.home,
                seed: worldSeed &+ UInt64(fixture)
            )
            let away = CalibrationRoster.team(
                skill: ladder.away,
                seed: worldSeed &+ UInt64(fixture) &+ 500_000
            )
            let gameSeed = SeededRandom.derive(
                from: worldSeed,
                scope: .game,
                ordinal: fixture
            )
            guard let abstracted = AbstractGameSimulator.play(
                tier: tier,
                home: home,
                away: away,
                seed: gameSeed
            ) else {
                expect(false, "controlled fixture reused a participant across teams")
                return sample
            }
            sample.abstracted += [Double(abstracted.homeScore), Double(abstracted.awayScore)]

            let detailed = GameEngine.play(
                tier: tier,
                home: home,
                away: away,
                seed: gameSeed
            )
            sample.detailed += [Double(detailed.homeScore), Double(detailed.awayScore)]
        }
    }
    return sample
}

private func pairedMeanDifference(_ first: [Double], _ second: [Double]) -> Estimate? {
    guard first.count == second.count,
          first.count > 1,
          first.allSatisfy(\.isFinite),
          second.allSatisfy(\.isFinite) else { return nil }
    let differences = zip(first, second).map(-)
    let mean = differences.reduce(0, +) / Double(differences.count)
    let variance = differences.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        / Double(differences.count - 1)
    return Estimate(
        value: mean,
        sampleSize: differences.count,
        standardDeviation: variance.squareRoot(),
        estimator: .mean
    )
}

private func sampleShape(_ values: [Double]) -> String {
    guard !values.isEmpty else { return "empty" }
    let mean = values.reduce(0, +) / Double(values.count)
    return String(
        format: "mean=%.2f min=%.0f max=%.0f n=%d",
        mean,
        values.min() ?? 0,
        values.max() ?? 0,
        values.count
    )
}

func runTwoTierConsistencyTests() {
    suite("Two-tier consistency") {
        test("paired mean difference preserves pairing and rejects invalid samples") {
            let estimate = pairedMeanDifference([1, 3], [1, 1])
            expectClose(estimate?.value ?? .nan, 1, 1e-12)
            expectEqual(estimate?.sampleSize, 2)
            expect(pairedMeanDifference([1], [1]) == nil)
            expect(pairedMeanDifference([1, .nan], [1, 1]) == nil)
        }

        test("controlled fixtures reject participants assigned to both teams") {
            let personnel = CalibrationRoster.team(skill: 72, seed: 72_001)
            expect(AbstractGameSimulator.play(
                tier: .pro,
                home: personnel,
                away: personnel,
                seed: 1
            ) == nil)
        }

        for tier in Tier.allCases {
            test("points per game agrees under TOST — \(tier.rawValue)") {
                let sample = collectTwoTierPoints(tier: tier)
                guard let difference = pairedMeanDifference(sample.abstracted, sample.detailed) else {
                    expect(false, "points samples are empty, invalid, or misaligned")
                    return
                }
                let band = Band(
                    "points per game agreement",
                    tier: tier,
                    -TwoTierConsistency.pointsPerGameMargin,
                    TwoTierConsistency.pointsPerGameMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE section 4.1"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + sampleShape(sample.abstracted)
                    + " | detailed " + sampleShape(sample.detailed)
                expect(result.passed, message)
            }
        }
    }
}
