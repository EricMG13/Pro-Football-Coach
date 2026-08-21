import Foundation
import FootballSimCore

// Separates game-to-game engine noise from the talent spread in the calibration ladder.
func runScoreVarianceProbe() {
    struct Distribution {
        let mean: Double
        let standardDeviation: Double
        let p95: Int
        let maximum: Int
        let shutoutRate: Double
    }

    func distribution(_ values: [Int]) -> Distribution {
        let mean = values.reduce(0, { $0 + Double($1) }) / Double(values.count)
        let variance = values.reduce(0) { total, value in
            total + (Double(value) - mean) * (Double(value) - mean)
        } / Double(values.count - 1)
        let ordered = values.sorted()
        let p95 = ordered[min(ordered.count - 1, Int(Double(ordered.count - 1) * 0.95))]
        return Distribution(
            mean: mean,
            standardDeviation: variance.squareRoot(),
            p95: p95,
            maximum: ordered.last ?? 0,
            shutoutRate: Double(values.filter { $0 == 0 }.count) / Double(values.count)
        )
    }

    func measure(
        _ label: String,
        home: SnapPersonnel,
        away: SnapPersonnel,
        seeds: Range<UInt64>
    ) {
        var homeScores: [Int] = []
        var awayScores: [Int] = []
        for seed in seeds {
            let game = GameEngine.play(
                tier: .pro,
                home: home,
                away: away,
                homeFieldAdvantage: 0,
                seed: seed
            )
            homeScores.append(game.homeScore)
            awayScores.append(game.awayScore)
        }
        let homeDistribution = distribution(homeScores)
        let awayDistribution = distribution(awayScores)
        print("--- " + label + " / fixed rosters — " + String(homeScores.count) + " games ---")
        print(String(format: "home: mean=%.2f sd=%.2f p95=%d max=%d shutout=%.3f",
                     homeDistribution.mean, homeDistribution.standardDeviation,
                     homeDistribution.p95, homeDistribution.maximum,
                     homeDistribution.shutoutRate))
        print(String(format: "away: mean=%.2f sd=%.2f p95=%d max=%d shutout=%.3f",
                     awayDistribution.mean, awayDistribution.standardDeviation,
                     awayDistribution.p95, awayDistribution.maximum,
                     awayDistribution.shutoutRate))
    }

    measure(
        "even 72 / 72",
        home: CalibrationRoster.team(skill: 72, seed: 72_001),
        away: CalibrationRoster.team(skill: 72, seed: 72_002),
        seeds: 100_000..<100_400
    )
    measure(
        "mismatch 78 / 69",
        home: CalibrationRoster.team(skill: 78, seed: 78_001),
        away: CalibrationRoster.team(skill: 69, seed: 69_001),
        seeds: 200_000..<200_400
    )
}
