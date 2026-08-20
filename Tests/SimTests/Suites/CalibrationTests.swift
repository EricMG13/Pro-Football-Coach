import Foundation
@testable import FootballSimCore

// The instrument, tested before it is trusted to judge the engine.
//
// 01-RESEARCH.md section 6.2 rejects range membership as the instrument because "a model whose true
// home-win rate is 0.62 passes a 0.50...0.60 range check roughly 1 run in 6 at n = 600, because the
// check has no notion of sampling error and does not tighten as n grows." A TOST implementation
// that quietly behaved like a range check would reintroduce exactly that, and look identical from
// the outside.

func runCalibrationTests() {
    suite("TOST") {
        let band = Band("probe", tier: .pro, 0.50, 0.60, estimator: .rate, confidence: "[C]")

        test("a tight estimate inside the band passes") {
            let estimate = Estimate(value: 0.55, sampleSize: 100_000, standardDeviation: 0,
                                    estimator: .rate)
            expect(band.test(estimate).passed, "a precise 0.55 inside 0.50 to 0.60 failed")
        }

        test("an estimate inside the band but imprecise FAILS") {
            // The whole difference between TOST and a range check. A point estimate of 0.55 from 40
            // trials is consistent with a true value well outside the band, and the burden is on the
            // model to be precise enough to prove otherwise.
            let estimate = Estimate(value: 0.55, sampleSize: 40, standardDeviation: 0,
                                    estimator: .rate)
            let result = band.test(estimate)
            expect(!result.passed,
                   "an imprecise estimate passed, so this is a range check wearing TOST's name")
            expectEqual(result.violatedEdge, "both (the interval is wider than the band)")
        }

        test("tightening the sample turns the same estimate from fail to pass") {
            // "Does not tighten as n grows" is 01 section 6.2's specific complaint about range
            // membership. This asserts the opposite property directly.
            let loose = band.test(Estimate(value: 0.55, sampleSize: 40, standardDeviation: 0,
                                           estimator: .rate))
            let tight = band.test(Estimate(value: 0.55, sampleSize: 40_000, standardDeviation: 0,
                                           estimator: .rate))
            expect(!loose.passed && tight.passed,
                   "the same point estimate did not improve with a larger sample")
        }

        test("an estimate outside the band fails on the edge it crossed") {
            let low = band.test(Estimate(value: 0.30, sampleSize: 100_000, standardDeviation: 0,
                                         estimator: .rate))
            expectEqual(low.violatedEdge, "lower")
            let high = band.test(Estimate(value: 0.90, sampleSize: 100_000, standardDeviation: 0,
                                          estimator: .rate))
            expectEqual(high.violatedEdge, "upper")
        }

        test("the failure message carries everything 01 section 6.6 clause 3 requires") {
            // metric, theta, CI90, band, n, and which edge. The prior suite printed value and range
            // and neither n nor the interval, "which is why a noise failure and a real failure look
            // identical today".
            let report = band.test(Estimate(value: 0.30, sampleSize: 900, standardDeviation: 0,
                                            estimator: .rate)).report
            for fragment in ["probe", "theta=", "CI90=", "band=", "n=900", "lower"] {
                expect(report.contains(fragment), "the failure message omits \(fragment): \(report)")
            }
        }

        test("the confidence interval uses the 90 percent quantile, not 95") {
            // TOST at alpha = 0.05 needs the (1 - 2 alpha) interval. Using 1.96 would be a
            // two-sided 95 percent interval and would make the gate stricter than the procedure
            // it claims to implement — a silent change of test.
            expectClose(Band.zNinety, 1.645, 0.001)
            let estimate = Estimate(value: 0.5, sampleSize: 100, standardDeviation: 0,
                                    estimator: .rate)
            let interval = band.test(estimate).confidenceInterval
            expectClose(interval.high - interval.low, 2 * 1.645 * 0.05, 0.001,
                        "the interval is not 2 x 1.645 x SE wide")
        }

        test("a mean's standard error uses the sample deviation, not an assumed one") {
            // 01 section 6.2: "The harness must compute s, not assume it. An engine with realistic
            // means and unrealistically low variance is a classic and invisible calibration
            // failure." Two samples with the same mean and different spread must not test alike.
            // sd 20 at n 400 still gives SE 1 and a CI comfortably inside a six-point band, so the
            // first version of this fixture proved nothing. The spread has to be large enough
            // relative to the band for the point to land.
            let tight = Estimate(value: 23, sampleSize: 400, standardDeviation: 1, estimator: .mean)
            let loose = Estimate(value: 23, sampleSize: 100, standardDeviation: 60, estimator: .mean)
            expect(tight.standardError < loose.standardError,
                   "spread does not affect the standard error")
            let points = Band("points", tier: .pro, 20, 26, estimator: .mean, confidence: "[C]")
            expect(points.test(tight).passed && !points.test(loose).passed,
                   "an engine with the right mean and absurd variance passed")
        }

        test("a percentage-scaled rate keeps its interval") {
            // Two of the harness's bands are stated in percent, so it scales those rates by 100.
            // The standard error clamps the proportion to [0, 1], so an unscaled 87.9 read as p = 1
            // returned SE = 0: the interval collapsed to a point and the band was decided by range
            // membership. Both percentage bands passed or failed on a point estimate for as long as
            // that held.
            let percent = Estimate(value: 85.3, sampleSize: 1245, standardDeviation: 0,
                                   estimator: .rate, scale: 100)
            expect(percent.standardError > 0,
                   "a percentage rate has no standard error, so its band is a range check")
            // The same measurement in proportion units must produce the same interval, scaled.
            let proportion = Estimate(value: 0.853, sampleSize: 1245, standardDeviation: 0,
                                      estimator: .rate)
            expectClose(percent.standardError, proportion.standardError * 100, 1e-9,
                        "the same rate measures differently in percent and in proportion")
            // And the fix has to be visible at the band, not only at the estimate: a percentage
            // estimate close to an edge must now fail on it.
            let goals = Band("field goal percentage", tier: .pro, 81, 88, estimator: .rate,
                             confidence: "[Q]")
            let nearCeiling = Estimate(value: 87.9, sampleSize: 1441, standardDeviation: 0,
                                       estimator: .rate, scale: 100)
            expect(!goals.test(nearCeiling).passed,
                   "87.9 percent with a 1441-kick sample passed an 81 to 88 band on a point")
        }

        test("an empty sample cannot pass") {
            let empty = Estimate(value: 0.55, sampleSize: 0, standardDeviation: 0, estimator: .rate)
            expect(!band.test(empty).passed, "a band passed on no data at all")
        }

        test("a rate interval is not clipped to the estimator support") {
            let ties = Band("tie rate", tier: .pro, 0, 0.02, estimator: .rate, confidence: "[C]")
            let result = ties.test(Estimate(value: 1.0 / 600, sampleSize: 600,
                                            standardDeviation: 0, estimator: .rate))
            expect(result.confidenceInterval.low < 0,
                   "the canonical normal interval was clipped at zero")
            expectEqual(result.violatedEdge, "lower")
        }

        test("malformed estimates fail closed") {
            let invalid = [
                Estimate(value: 0.55, sampleSize: 100_000, standardDeviation: 0,
                         estimator: .rate, scale: 0),
                Estimate(value: 1.2, sampleSize: 100_000, standardDeviation: 0,
                         estimator: .rate),
                Estimate(value: 23, sampleSize: 400, standardDeviation: -1,
                         estimator: .mean),
                Estimate(value: .nan, sampleSize: 400, standardDeviation: 1,
                         estimator: .mean),
                Estimate(value: 23, sampleSize: 400, standardDeviation: .infinity,
                         estimator: .mean),
            ]
            let bands = [
                band,
                Band("rate", tier: .pro, 1.1, 1.3, estimator: .rate, confidence: "[C]"),
                Band("mean", tier: .pro, 20, 26, estimator: .mean, confidence: "[C]"),
                Band("mean", tier: .pro, 20, 26, estimator: .mean, confidence: "[C]"),
                Band("mean", tier: .pro, 20, 26, estimator: .mean, confidence: "[C]"),
            ]
            for (estimate, target) in zip(invalid, bands) {
                expect(!target.test(estimate).passed,
                       "a malformed \(estimate.estimator.rawValue) estimate passed")
            }
        }
    }

    suite("Total variation distance") {
        test("identical distributions are zero apart and disjoint ones are one") {
            expectClose(TotalVariation.distance(observed: [1, 2, 3], target: [1, 2, 3]), 0, 1e-9)
            expectClose(TotalVariation.distance(observed: [1, 0], target: [0, 1]), 1, 1e-9)
        }

        test("it normalises, so counts and proportions agree") {
            expectClose(TotalVariation.distance(observed: [10, 20, 30], target: [1, 2, 3]), 0, 1e-9)
        }

        test("mismatched or empty shapes are maximally distant rather than silently compared") {
            expectClose(TotalVariation.distance(observed: [1, 2], target: [1, 2, 3]), 1, 1e-9)
            expectClose(TotalVariation.distance(observed: [], target: []), 1, 1e-9)
            expectClose(TotalVariation.distance(observed: [0, 0], target: [1, 1]), 1, 1e-9)
        }
    }

    suite("Band tables") {
        test("every band is well formed and transcribed from a real row") {
            expect(!CalibrationBands.all.isEmpty, "there are no bands")
            for band in CalibrationBands.all {
                expect(band.lower < band.upper,
                       "\(band.metric) [\(band.tier.rawValue)] has an empty or inverted band")
                expect(!band.confidence.isEmpty,
                       "\(band.metric) carries no confidence grade, so a failure cannot say how "
                           + "much the band itself is worth")
            }
        }

        test("no band is a seventeen-fold range") {
            // 03 section 5.2's scar tissue: the prior suite's overtime band was 0.008 to 0.14.
            // "That is what widening a band to stop a false failure looks like." This will not
            // catch every widening, but it catches that one, and it is a standing reminder that
            // the response to a red band is to fix the model.
            // The threshold is 15, not 10. A rate whose floor is near zero legitimately spans a
            // wide ratio — 01 section 6.5's safeties band is 0.005 to 0.05, a tenfold range that is
            // a real two-sided band on a rare event rather than a widened one. 17 is the number
            // that actually happened; 15 leaves the scar visible without failing canon.
            for band in CalibrationBands.all where band.lower > 0 {
                expect(band.upper / band.lower < 15,
                       "\(band.metric) [\(band.tier.rawValue)] spans "
                           + "\(band.upper / band.lower)x, which is a widened band rather than a "
                           + "measured one")
            }
        }

        test("both tiers are covered, and the tier is not a label") {
            expect(!CalibrationBands.pro.isEmpty, "no pro bands")
            expect(!CalibrationBands.college.isEmpty, "no college bands")
            for band in CalibrationBands.pro { expectEqual(band.tier, .pro) }
            for band in CalibrationBands.college { expectEqual(band.tier, .college) }
        }

        test("the tiers disagree where 01 section 6.5 says they disagree") {
            // College scores more, runs more plays and is more explosive. If the two tables were
            // the same numbers, there would be no two-tier calibration.
            func band(_ metric: String, _ tier: Tier) -> Band? {
                CalibrationBands.all.first { $0.metric == metric && $0.tier == tier }
            }
            for metric in ["points per team-game", "offensive plays per team-game",
                           "explosive run rate"] {
                guard let pro = band(metric, .pro), let college = band(metric, .college) else {
                    expect(false, "\(metric) is missing from a tier"); continue
                }
                expect(college.lower > pro.lower,
                       "\(metric) has the same floor in both tiers")
            }
        }

        test("what the harness does not yet measure is named, not dropped") {
            // 01 section 6.6 clause 3 wants every scalar band in 6.5 gated by TOST. Until that is
            // true the honest statement is a list of what is missing — a band table that quietly
            // covers two thirds of 6.5 and reports green is the coverage boundary becoming the
            // quality boundary.
            expect(CalibrationBands.unimplementedMetrics.count > 10,
                   "the unimplemented list is suspiciously short")
            for entry in CalibrationBands.unimplementedMetrics {
                expect(!entry.waitingOn.isEmpty,
                       "\(entry.metric) is listed as unimplemented with no reason")
                expect(!CalibrationBands.all.contains { $0.metric == entry.metric },
                       "\(entry.metric) is both implemented and listed as missing")
            }
        }
    }

    suite("Calibration harness") {
        test("the seed ladder is split and does not overlap") {
            // 01 section 6.6 clause 2. Tune against A, report against B. A seed in both sets makes
            // the holdout no holdout at all.
            expect(!CalibrationHarness.tuningSeeds.isEmpty, "no tuning seeds")
            expectEqual(CalibrationHarness.tuningSeeds.count,
                        CalibrationHarness.holdoutSeeds.count)
            let overlap = Set(CalibrationHarness.tuningSeeds)
                .intersection(CalibrationHarness.holdoutSeeds)
            expect(overlap.isEmpty, "the tuning and holdout ladders share \(overlap.count) seeds")
        }

        test("expanded roster streams keep tuning and holdout disjoint") {
            func rosterSeeds(_ bases: [UInt64]) -> Set<UInt64> {
                Set(bases.flatMap { seed in
                    (0..<CalibrationHarness.matchupsPerSeed).flatMap { matchup in
                        Side.allCases.map {
                            CalibrationHarness.rosterSeed(base: seed, matchup: matchup, side: $0)
                        }
                    }
                })
            }
            let tuning = rosterSeeds(CalibrationHarness.tuningSeeds)
            let holdout = rosterSeeds(CalibrationHarness.holdoutSeeds)
            let expected = CalibrationHarness.tuningSeeds.count
                * CalibrationHarness.matchupsPerSeed * Side.allCases.count
            expectEqual(tuning.count, expected, "the tuning ladder repeats roster streams")
            expectEqual(holdout.count, expected, "the holdout ladder repeats roster streams")
            expect(tuning.isDisjoint(with: holdout),
                   "expanded tuning and holdout ladders share roster streams")
        }

        test("safeties are measured per game") {
            let play = PlayRecord(
                situation: Situation(possession: .home),
                offensiveCall: OffensiveCall(playType: .pass),
                defensiveCall: DefensiveCall(coverage: .zoneUnder),
                outcome: SnapOutcome(result: .safety, yards: -3, secondsElapsed: 4, matchups: []),
                callInTriggers: []
            )
            let game = GameRecord(
                homeScore: 0,
                awayScore: MatchupRules.safetyPoints,
                drives: [DriveRecord(offense: .home, plays: [play], ending: .safety,
                                     pointsScored: MatchupRules.safetyPoints, startYardLine: 2)],
                tier: .pro
            )
            let estimate = CalibrationHarness.measure([
                CalibrationHarness.SampledGame(record: game, homeSkill: 70, awaySkill: 70)
            ])["safeties per game"]
            expectClose(estimate?.value ?? -1, 1, 1e-9)
            expectEqual(estimate?.sampleSize, 1)
        }

        test("the harness is reproducible from its seeds") {
            let first = CalibrationHarness.run(tier: .pro,
                                               seeds: Array(CalibrationHarness.tuningSeeds.prefix(2)))
            let second = CalibrationHarness.run(tier: .pro,
                                                seeds: Array(CalibrationHarness.tuningSeeds.prefix(2)))
            expectEqual(first.results.map(\.estimate.value), second.results.map(\.estimate.value),
                        "two runs of the same seeds measured different numbers")
        }

        test("the harness measures every band its tier declares") {
            // A band with no measurement behind it would silently vanish from the report rather
            // than fail, which is the quietest way for a gate to stop existing.
            for tier in Tier.allCases {
                let declared = (tier == .pro ? CalibrationBands.pro : CalibrationBands.college)
                let report = CalibrationHarness.run(tier: tier,
                                                    seeds: Array(CalibrationHarness.tuningSeeds.prefix(2)))
                expectEqual(report.results.count, declared.count,
                            "\(tier.rawValue) declares \(declared.count) bands and the harness "
                                + "reported on \(report.results.count)")
            }
        }

        test("the talent ladder actually produces mismatches") {
            // The favourite-win-rate and blowout bands cannot be measured from a sample of even
            // games. If every rung paired with itself, those two bands would be measuring noise.
            var mismatched = 0
            for matchup in 0..<CalibrationHarness.matchupsPerSeed {
                let ladder = CalibrationHarness.talentLadder(matchup: matchup)
                if ladder.home != ladder.away { mismatched += 1 }
            }
            expect(mismatched >= CalibrationHarness.matchupsPerSeed / 2,
                   "only \(mismatched) of \(CalibrationHarness.matchupsPerSeed) matchups are "
                       + "mismatches, so the favourite and blowout bands are measuring even games")
        }
    }
}
