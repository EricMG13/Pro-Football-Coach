import Foundation
import FootballSimCore

private enum TwoTierConsistency {
    static let pointsPerGameMargin = 0.75
    static let yardsPerPlayMargin = 0.15
    static let completionRateMargin = 1.5
    static let sackRateMargin = 0.6
    static let turnoverRateMargin = 0.4
    static let explosivePlayRateMargin = 1.0
    static let fieldGoalAccuracyMargin = 3.0
    static let homeAdvantageMargin = 2.0
    static let homeAdvantageSeasons = 1_000
    static let evenRatingGamesPerSeason = 6
    /// One hundred worlds provide 12,800 paired team observations per tier. Spreading the same
    /// total games across more worlds prevents a short contiguous seed block from deciding TOST.
    static let worldSeeds: [UInt64] = Array(390_210...390_309)
    static let sampledGames = 64
}

private struct TwoTierSample {
    var abstracted: [GameSummary] = []
    var detailed: [GameSummary] = []
}

private func collectTwoTierSample(tier: Tier) -> TwoTierSample {
    var sample = TwoTierSample()
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
            sample.abstracted.append(abstracted)

            let detailed = GameEngine.play(
                tier: tier,
                home: home,
                away: away,
                seed: gameSeed
            )
            sample.detailed.append(DetailedGameSummaryBuilder.make(
                record: detailed,
                homeParticipantIDs: abstracted.homeParticipantIDs,
                awayParticipantIDs: abstracted.awayParticipantIDs
            ))
        }
    }
    return sample
}

private func teamValues(
    _ summaries: [GameSummary],
    _ value: (TeamGameStatistics) -> Double
) -> [Double] {
    summaries.flatMap { [value($0.homeStatistics), value($0.awayStatistics)] }
}

private func yardsPerPlay(_ summaries: [GameSummary]) -> [Double]? {
    var values: [Double] = []
    values.reserveCapacity(summaries.count * 2)
    for summary in summaries {
        for statistics in [summary.homeStatistics, summary.awayStatistics] {
            let plays = statistics.offensivePlays
            guard plays > 0 else { return nil }
            values.append(Double(statistics.offensiveYards) / Double(plays))
        }
    }
    return values
}

private func completionRates(_ summaries: [GameSummary]) -> [Double]? {
    var values: [Double] = []
    values.reserveCapacity(summaries.count * 2)
    for summary in summaries {
        for statistics in [summary.homeStatistics, summary.awayStatistics] {
            let attempts = statistics.passAttempts
            let completions = statistics.passCompletions
            guard attempts > 0,
                  (0...attempts).contains(completions) else { return nil }
            values.append(Double(completions) / Double(attempts) * 100)
        }
    }
    return values
}

private func sackRates(_ summaries: [GameSummary]) -> [Double]? {
    var values: [Double] = []
    values.reserveCapacity(summaries.count * 2)
    for summary in summaries {
        for statistics in [summary.homeStatistics, summary.awayStatistics] {
            let sacks = statistics.sacks
            guard sacks >= 0 else { return nil }
            let dropbacks = statistics.passAttempts + sacks
            guard dropbacks > 0 else { return nil }
            values.append(Double(sacks) / Double(dropbacks) * 100)
        }
    }
    return values
}

private func turnoverRates(_ summaries: [GameSummary]) -> [Double]? {
    var values: [Double] = []
    values.reserveCapacity(summaries.count * 2)
    for summary in summaries {
        for statistics in [summary.homeStatistics, summary.awayStatistics] {
            guard statistics.offensivePlays > 0 else { return nil }
            values.append(Double(statistics.turnovers) / Double(statistics.offensivePlays) * 100)
        }
    }
    return values
}

private func explosivePlayRates(_ summaries: [GameSummary]) -> [Double]? {
    var values: [Double] = []
    values.reserveCapacity(summaries.count * 2)
    for summary in summaries {
        for statistics in [summary.homeStatistics, summary.awayStatistics] {
            let explosivePlays = statistics.explosivePlays
            guard statistics.offensivePlays > 0,
                  (0...statistics.offensivePlays).contains(explosivePlays) else { return nil }
            values.append(Double(explosivePlays) / Double(statistics.offensivePlays) * 100)
        }
    }
    return values
}

private struct RateCount {
    var attempts = 0
    var made = 0
}

private func fieldGoalCount(
    _ summaries: [GameSummary],
    bucket: FieldGoalDistanceBucket
) -> RateCount {
    summaries.reduce(into: RateCount()) { count, summary in
        for statistics in [summary.homeStatistics, summary.awayStatistics] {
            count.attempts += statistics.fieldGoals.attempts(in: bucket)
            count.made += statistics.fieldGoals.made(in: bucket)
        }
    }
}

private func collectHomeAdvantageSample(tier: Tier) -> (abstracted: RateCount, detailed: RateCount) {
    var abstracted = RateCount()
    var detailed = RateCount()
    for season in 0..<TwoTierConsistency.homeAdvantageSeasons {
        let worldSeed = UInt64(391_000 + season)
        for fixture in 0..<TwoTierConsistency.evenRatingGamesPerSeason {
            let home = CalibrationRoster.team(skill: 72, seed: worldSeed &+ UInt64(fixture))
            let away = CalibrationRoster.team(
                skill: 72,
                seed: worldSeed &+ UInt64(fixture) &+ 500_000
            )
            let gameSeed = SeededRandom.derive(from: worldSeed, scope: .game, ordinal: fixture)
            guard let abstractedGame = AbstractGameSimulator.play(
                tier: tier,
                home: home,
                away: away,
                seed: gameSeed
            ) else {
                expect(false, "controlled fixture reused a participant across teams")
                return (abstracted, detailed)
            }
            if abstractedGame.homeScore != abstractedGame.awayScore {
                abstracted.attempts += 1
                if abstractedGame.homeScore > abstractedGame.awayScore { abstracted.made += 1 }
            }

            let detailedGame = GameEngine.play(
                tier: tier,
                home: home,
                away: away,
                seed: gameSeed
            )
            if detailedGame.homeScore != detailedGame.awayScore {
                detailed.attempts += 1
                if detailedGame.homeScore > detailedGame.awayScore { detailed.made += 1 }
            }
        }
    }
    return (abstracted, detailed)
}

private func independentRateDifference(
    _ first: RateCount,
    _ second: RateCount
) -> Estimate? {
    guard first.attempts > 0,
          second.attempts > 0,
          (0...first.attempts).contains(first.made),
          (0...second.attempts).contains(second.made) else { return nil }
    let firstRate = Double(first.made) / Double(first.attempts)
    let secondRate = Double(second.made) / Double(second.attempts)
    let standardError = (
        firstRate * (1 - firstRate) / Double(first.attempts)
            + secondRate * (1 - secondRate) / Double(second.attempts)
    ).squareRoot() * 100
    let sampleSize = first.attempts + second.attempts
    return Estimate(
        value: (firstRate - secondRate) * 100,
        sampleSize: sampleSize,
        standardDeviation: standardError * Double(sampleSize).squareRoot(),
        estimator: .mean
    )
}

private func rateShape(_ count: RateCount) -> String {
    guard count.attempts > 0 else { return "no attempts" }
    return String(
        format: "%.2f%% (%d/%d)",
        Double(count.made) / Double(count.attempts) * 100,
        count.made,
        count.attempts
    )
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
        test("legacy team statistics default new rate counters") {
            let data = Data(
                #"{"points":21,"offensiveYards":300,"passingYards":200,"rushingYards":100,"turnovers":1,"offensivePlays":64}"#.utf8
            )
            guard let statistics = try? JSONDecoder().decode(TeamGameStatistics.self, from: data) else {
                expect(false, "legacy team statistics no longer decode")
                return
            }
            expectEqual(statistics.passAttempts, 0)
            expectEqual(statistics.passCompletions, 0)
            expectEqual(statistics.sacks, 0)
            expectEqual(statistics.explosivePlays, 0)
            for bucket in FieldGoalDistanceBucket.allCases {
                expectEqual(statistics.fieldGoals.attempts(in: bucket), 0)
                expectEqual(statistics.fieldGoals.made(in: bucket), 0)
            }
        }

        test("paired mean difference preserves pairing and rejects invalid samples") {
            let estimate = pairedMeanDifference([1, 3], [1, 1])
            expectClose(estimate?.value ?? .nan, 1, 1e-12)
            expectEqual(estimate?.sampleSize, 2)
            expect(pairedMeanDifference([1], [1]) == nil)
            expect(pairedMeanDifference([1, .nan], [1, 1]) == nil)
        }

        test("independent rate difference uses both samples' uncertainty") {
            let estimate = independentRateDifference(
                RateCount(attempts: 100, made: 50),
                RateCount(attempts: 100, made: 50)
            )
            expectClose(estimate?.value ?? .nan, 0, 1e-12)
            expectClose(estimate?.standardError ?? .nan, 7.0710678119, 1e-9)
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
            let sample = collectTwoTierSample(tier: tier)
            let homeAdvantage = collectHomeAdvantageSample(tier: tier)

            test("points per game agrees under TOST — \(tier.rawValue)") {
                let abstracted = teamValues(sample.abstracted) { Double($0.points) }
                let detailed = teamValues(sample.detailed) { Double($0.points) }
                guard let difference = pairedMeanDifference(abstracted, detailed) else {
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
                    + " | abstracted " + sampleShape(abstracted)
                    + " | detailed " + sampleShape(detailed)
                expect(result.passed, message)
            }

            test("yards per play agrees under TOST — \(tier.rawValue)") {
                guard let abstracted = yardsPerPlay(sample.abstracted),
                      let detailed = yardsPerPlay(sample.detailed) else {
                    expect(false, "offensive play counts are missing or zero")
                    return
                }
                guard let difference = pairedMeanDifference(abstracted, detailed) else {
                    expect(false, "yards-per-play samples are empty, invalid, or misaligned")
                    return
                }
                let band = Band(
                    "yards per play agreement",
                    tier: tier,
                    -TwoTierConsistency.yardsPerPlayMargin,
                    TwoTierConsistency.yardsPerPlayMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE section 4.1"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + sampleShape(abstracted)
                    + " | detailed " + sampleShape(detailed)
                expect(result.passed, message)
            }

            test("completion rate agrees under TOST — \(tier.rawValue)") {
                guard let abstracted = completionRates(sample.abstracted),
                      let detailed = completionRates(sample.detailed) else {
                    expect(false, "pass attempts or completions are missing or invalid")
                    return
                }
                guard let difference = pairedMeanDifference(abstracted, detailed) else {
                    expect(false, "completion-rate samples are empty, invalid, or misaligned")
                    return
                }
                let band = Band(
                    "completion rate agreement",
                    tier: tier,
                    -TwoTierConsistency.completionRateMargin,
                    TwoTierConsistency.completionRateMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE section 5.1"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + sampleShape(abstracted)
                    + " | detailed " + sampleShape(detailed)
                expect(result.passed, message)
            }

            test("sack rate agrees under TOST — \(tier.rawValue)") {
                guard let abstracted = sackRates(sample.abstracted),
                      let detailed = sackRates(sample.detailed) else {
                    expect(false, "sacks are missing or pass dropbacks are invalid")
                    return
                }
                guard let difference = pairedMeanDifference(abstracted, detailed) else {
                    expect(false, "sack-rate samples are empty, invalid, or misaligned")
                    return
                }
                let band = Band(
                    "sack rate agreement",
                    tier: tier,
                    -TwoTierConsistency.sackRateMargin,
                    TwoTierConsistency.sackRateMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE section 5.1"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + sampleShape(abstracted)
                    + " | detailed " + sampleShape(detailed)
                expect(result.passed, message)
            }

            test("turnover rate agrees under TOST — \(tier.rawValue)") {
                guard let abstracted = turnoverRates(sample.abstracted),
                      let detailed = turnoverRates(sample.detailed) else {
                    expect(false, "offensive plays are missing or invalid")
                    return
                }
                guard let difference = pairedMeanDifference(abstracted, detailed) else {
                    expect(false, "turnover-rate samples are empty, invalid, or misaligned")
                    return
                }
                let band = Band(
                    "turnover rate agreement",
                    tier: tier,
                    -TwoTierConsistency.turnoverRateMargin,
                    TwoTierConsistency.turnoverRateMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE section 5.1"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + sampleShape(abstracted)
                    + " | detailed " + sampleShape(detailed)
                expect(result.passed, message)
            }

            test("explosive-play rate agrees under TOST — \(tier.rawValue)") {
                guard let abstracted = explosivePlayRates(sample.abstracted),
                      let detailed = explosivePlayRates(sample.detailed) else {
                    expect(false, "explosive-play counts are missing or invalid")
                    return
                }
                guard let difference = pairedMeanDifference(abstracted, detailed) else {
                    expect(false, "explosive-play-rate samples are empty, invalid, or misaligned")
                    return
                }
                let band = Band(
                    "explosive-play rate agreement",
                    tier: tier,
                    -TwoTierConsistency.explosivePlayRateMargin,
                    TwoTierConsistency.explosivePlayRateMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE section 5.1; owner-approved margin"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + sampleShape(abstracted)
                    + " | detailed " + sampleShape(detailed)
                expect(result.passed, message)
            }

            for bucket in FieldGoalDistanceBucket.allCases {
                test("field-goal accuracy agrees under TOST — \(tier.rawValue), \(bucket.label)") {
                    let abstracted = fieldGoalCount(sample.abstracted, bucket: bucket)
                    let detailed = fieldGoalCount(sample.detailed, bucket: bucket)
                    guard let difference = independentRateDifference(abstracted, detailed) else {
                        expect(false, "field-goal samples are empty, invalid, or misaligned")
                        return
                    }
                    let band = Band(
                        "field-goal accuracy agreement (\(bucket.label) yards)",
                        tier: tier,
                        -TwoTierConsistency.fieldGoalAccuracyMargin,
                        TwoTierConsistency.fieldGoalAccuracyMargin,
                        estimator: .mean,
                        confidence: "03-MATCH-ENGINE section 5.1; owner-approved buckets/margin"
                    )
                    let result = band.test(difference)
                    let message = result.report
                        + " | abstracted " + rateShape(abstracted)
                        + " | detailed " + rateShape(detailed)
                    expect(result.passed, message)
                }
            }

            test("home advantage agrees under TOST — \(tier.rawValue)") {
                let abstracted = homeAdvantage.abstracted
                let detailed = homeAdvantage.detailed
                guard let difference = independentRateDifference(abstracted, detailed) else {
                    expect(false, "even-rating home-win samples are empty or invalid")
                    return
                }
                let band = Band(
                    "home advantage agreement",
                    tier: tier,
                    -TwoTierConsistency.homeAdvantageMargin,
                    TwoTierConsistency.homeAdvantageMargin,
                    estimator: .mean,
                    confidence: "03-MATCH-ENGINE sections 4.1 and 5.1"
                )
                let result = band.test(difference)
                let message = result.report
                    + " | abstracted " + rateShape(abstracted)
                    + " | detailed " + rateShape(detailed)
                expect(result.passed, message)
            }
        }
    }
}
