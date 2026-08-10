import Foundation
import FootballSimCore

// Every row of 02 section 11 asserted by value. The point is not that these numbers are hard to get
// right once — it is that a later phase that "just tweaks" one has to come here and change a test
// that names the canon section it came from, rather than editing a literal in passing.

func runRulesTests() {
    suite("Shared rules") {
        test("the rating range is 40 to 99") {
            expectEqual(SharedRules.ratingRange, 40...99)
            expectEqual(SharedRules.potentialRange, 40...99)
        }

        test("the call-in rate defaults inside its tunable range") {
            expectEqual(SharedRules.defaultCallInsPerGame, 25)
            expectEqual(SharedRules.callInsPerGameRange, 12...40)
            expect(SharedRules.callInsPerGameRange.contains(SharedRules.defaultCallInsPerGame),
                   "the default call-in rate is outside its own tunable range")
        }

        test("the group counts 02 names are here") {
            expectEqual(SharedRules.coordinatorCount, 4)
            expectEqual(SharedRules.stakeholderGroupCount, 4)
            expectEqual(SharedRules.programmeArchetypeCount, 14)
        }

        test("the rivalry bound is 8") {
            expectEqual(SharedRules.rivalriesPerProgramme, 8)
        }

        test("the shared calendar is 21 weeks and holds the longer tier exactly") {
            // 02 section 11.3.1. Both leagues run in one save on one week counter, so the shared
            // calendar has to be the longer of the two — not more, or there are dead weeks; not
            // less, or the pro bracket has nowhere to happen.
            expectEqual(SharedRules.inSeasonWeeks, 21)
            expectEqual(SharedRules.inSeasonWeeks,
                        Swift.max(CollegeRules.seasonWeeks, ProRules.seasonWeeks))
        }

        test("the decline-age table covers every position exactly once") {
            // Total by construction. A position added without a decline age fails here rather than
            // silently taking the fallback, which is the difference between a table and a default.
            expectEqual(SharedRules.declineAgeByPosition.count, Position.allCases.count)
            for position in Position.allCases {
                expect(SharedRules.declineAgeByPosition[position] != nil,
                       "\(position) has no decline age")
            }
        }

        test("decline ages are ordered the way 02 section 11.3.2 argues") {
            // Not just present, but in the relationship the canon table's reasoning claims: the
            // positions that live on top-end speed decline before the ones that live on technique,
            // and both before the ones that barely take contact.
            let age = { (position: Position) in SharedRules.declineAgeByPosition[position]! }
            expect(age(.runningBack) < age(.cornerback), "a back should decline before a corner")
            expect(age(.cornerback) < age(.leftTackle), "a corner should decline before a tackle")
            expect(age(.leftTackle) < age(.quarterback),
                   "a tackle should decline before a quarterback")
            expect(age(.quarterback) < age(.kicker), "a quarterback should decline before a kicker")
            for position in Position.allCases {
                expect(age(position) >= SharedRules.declineAgeFallback,
                       "\(position) declines before the fallback, so the fallback is not the floor")
            }
        }
    }

    suite("College rules") {
        test("college first-down restarts are a tier-specific clock rule") {
            expect(CollegeClockRules.clockStopsOnFirstDownInsideTwoMinutes,
                   "college must stop the clock after an inside-two-minute first down")
            expect(!ProClockRules.clockStopsOnFirstDownInsideTwoMinutes,
                   "pro must keep the clock running after an inside-two-minute first down")
            expectEqual(CollegeClockRules.readyForPlaySeconds, 18,
                        "college's ready-for-play charge must stay at the documented 18 seconds")
        }

        test("the league is 134 programmes in 10 conferences") {
            expectEqual(CollegeRules.programmeCount, 134)
            expectEqual(CollegeRules.conferenceCount, 10)
            expectEqual(CollegeRules.conferenceSizeRange, 12...16)
        }

        test("the conference shape can actually hold the programmes") {
            // 02 section 11.4 deliberately does not fix conference composition, so generation is
            // free to choose sizes. This asserts the shape is satisfiable at all: 10 conferences of
            // 12 to 16 must be able to sum to exactly 134, or P2 gets an impossible constraint.
            let smallest = CollegeRules.conferenceCount * CollegeRules.conferenceSizeRange.lowerBound
            let largest = CollegeRules.conferenceCount * CollegeRules.conferenceSizeRange.upperBound
            expect(smallest <= CollegeRules.programmeCount,
                   "10 conferences at the minimum size hold \(smallest), which exceeds 134")
            expect(largest >= CollegeRules.programmeCount,
                   "10 conferences at the maximum size hold only \(largest)")
        }

        test("the season is 17 weeks, and that is the sum of its parts") {
            expectEqual(CollegeRules.regularSeasonWeeks, 13)
            expectEqual(CollegeRules.gamesPerRegularSeason, 12)
            expectEqual(CollegeRules.byeWeeksPerRegularSeason, 1)
            expectEqual(CollegeRules.conferenceChampionshipWeeks, 1)
            expectEqual(CollegeRules.bracketTeams, 8)
            expectEqual(CollegeRules.bracketRounds, 3)
            // Derived, not written twice. A season length stated independently of its parts is a
            // number that drifts the first time one of the parts changes.
            expectEqual(CollegeRules.seasonWeeks, 17)
            expectEqual(
                CollegeRules.seasonWeeks,
                CollegeRules.regularSeasonWeeks + CollegeRules.conferenceChampionshipWeeks
                    + CollegeRules.bracketRounds
            )
        }

        test("games plus byes fill the regular season exactly") {
            expectEqual(
                CollegeRules.gamesPerRegularSeason + CollegeRules.byeWeeksPerRegularSeason,
                CollegeRules.regularSeasonWeeks,
                "a programme would have a week with neither a game nor a bye"
            )
        }

        test("the bracket rounds halve the field down to one") {
            // 8 teams, 3 rounds. If either changes without the other, the bracket cannot resolve.
            expectEqual(1 << CollegeRules.bracketRounds, CollegeRules.bracketTeams)
        }

        test("the roster and scholarship limits are 105 and 85") {
            expectEqual(CollegeRules.rosterLimit, 105)
            expectEqual(CollegeRules.scholarshipLimit, 85)
            expect(CollegeRules.scholarshipLimit <= CollegeRules.rosterLimit,
                   "more scholarships than roster spots")
        }

        test("the eligibility clock is 4 seasons inside 5 years") {
            expectEqual(CollegeRules.seasonsOfCompetition, 4)
            expectEqual(CollegeRules.eligibilityClockYears, 5)
            expect(CollegeRules.eligibilityClockYears > CollegeRules.seasonsOfCompetition,
                   "there is no room in the clock for a redshirt year, so 02 section 4.1's "
                       + "redshirt decision has nothing to spend")
        }

        test("a signing class is 25") {
            expectEqual(CollegeRules.initialSigningsPerClass, 25)
        }

        test("there are two portal windows") {
            expectEqual(CollegeRules.portalWindowCount, 2)
        }
    }

    suite("Pro rules") {
        test("the league is 32 teams in 2 conferences of 4 divisions of 4") {
            expectEqual(ProRules.teamCount, 32)
            expectEqual(ProRules.conferenceCount, 2)
            expectEqual(ProRules.divisionsPerConference, 4)
            expectEqual(ProRules.teamsPerDivision, 4)
            expectEqual(
                ProRules.conferenceCount * ProRules.divisionsPerConference
                    * ProRules.teamsPerDivision,
                ProRules.teamCount,
                "the division structure does not hold 32 teams"
            )
        }

        test("the season is 21 weeks, and that is the sum of its parts") {
            expectEqual(ProRules.gamesPerRegularSeason, 17)
            expectEqual(ProRules.byeWeeksPerRegularSeason, 1)
            expectEqual(ProRules.regularSeasonWeeks, 18)
            expectEqual(ProRules.bracketTeams, 8)
            expectEqual(ProRules.bracketRounds, 3)
            expectEqual(ProRules.seasonWeeks, 21)
            expectEqual(ProRules.seasonWeeks, ProRules.regularSeasonWeeks + ProRules.bracketRounds)
        }

        test("games plus byes fill the regular season exactly") {
            expectEqual(
                ProRules.gamesPerRegularSeason + ProRules.byeWeeksPerRegularSeason,
                ProRules.regularSeasonWeeks
            )
        }

        test("the bracket seeds four teams per conference and resolves") {
            expectEqual(1 << ProRules.bracketRounds, ProRules.bracketTeams)
            expectEqual(ProRules.bracketTeams / ProRules.conferenceCount, 4)
        }

        test("the roster limits are 53 active, 48 gameday, 16 practice squad") {
            expectEqual(ProRules.activeRosterLimit, 53)
            expectEqual(ProRules.gamedayActiveLimit, 48)
            expectEqual(ProRules.practiceSquadLimit, 16)
            expect(ProRules.gamedayActiveLimit <= ProRules.activeRosterLimit,
                   "more players dress than are on the roster")
        }

        test("the cap is integer dollars and grows") {
            expectEqual(ProRules.baseSalaryCap, 255_000_000)
            expectEqual(ProRules.capGrowthPercentPerYear, 7)
        }

        test("the cap grows without floating-point drift") {
            // Money is Int. A percent applied as a Double and rounded is how a cap ends up a dollar
            // out from itself after twenty seasons, which the soak would then report as an
            // illegal roster.
            let afterOne = ProRules.salaryCap(seasonsAfterBase: 1)
            expectEqual(afterOne, 255_000_000 + 255_000_000 * 7 / 100)
            expect(ProRules.salaryCap(seasonsAfterBase: 0) == ProRules.baseSalaryCap,
                   "season zero is not the base cap")
            // Monotonic across the soak's twenty seasons, and never negative.
            var previous = ProRules.salaryCap(seasonsAfterBase: 0)
            for season in 1...20 {
                let cap = ProRules.salaryCap(seasonsAfterBase: season)
                expect(cap > previous, "the cap did not grow in season \(season)")
                previous = cap
            }
        }

        test("signing-bonus proration is capped at five years") {
            expectEqual(ProRules.maximumProrationYears, 5)
        }

        test("contract length is bounded at both ends") {
            expectEqual(ProRules.contractYearsRange, 1...7)
            expect(ProRules.contractYearsRange.upperBound >= ProRules.maximumProrationYears,
                   "a contract cannot be shorter than the proration window it is capped at")
        }

        test("the cap does not trap on a season before the base") {
            // Rating sets the project's policy for a value that can arrive from a corrupt save:
            // clamp, never trap. season arrives from disk, so a precondition here turns a bad save
            // into a crash on the cap screen.
            expectEqual(ProRules.salaryCap(seasonsAfterBase: -1), ProRules.baseSalaryCap)
            expectEqual(ProRules.salaryCap(seasonsAfterBase: Int.min), ProRules.baseSalaryCap)
        }

        test("the draft is 7 rounds of 32") {
            expectEqual(ProRules.draftRounds, 7)
            expectEqual(ProRules.draftPicksPerRound, ProRules.teamCount)
            expectEqual(ProRules.draftPickCount, 224)
            expectEqual(ProRules.draftPickCount, ProRules.draftRounds * ProRules.draftPicksPerRound)
        }
    }

    suite("Outcome distribution rules") {
        test("run outcome bands are ordered, finite distributions for both tiers") {
            for tier in Tier.allCases {
                let weights = OutcomeDistributionRules.runWeights(tier: tier)
                expectEqual(weights.map(\.0), RunOutcomeBand.allCases)
                expect(weights.allSatisfy { $0.1.isFinite && $0.1 >= 0 },
                       "\(tier) run table contains a non-finite or negative weight")
                expectClose(weights.reduce(0) { $0 + $1.1 }, 1,
                            OutcomeDistributionRules.probabilityTolerance,
                            "\(tier) run table does not sum to one")
            }
        }

        test("pass outcome bands are ordered, finite distributions for both tiers") {
            for tier in Tier.allCases {
                let weights = OutcomeDistributionRules.passWeights(tier: tier)
                expectEqual(weights.map(\.0), PassOutcomeBand.allCases)
                expect(weights.allSatisfy { $0.1.isFinite && $0.1 >= 0 },
                       "\(tier) pass table contains a non-finite or negative weight")
                expectClose(weights.reduce(0) { $0 + $1.1 }, 1,
                            OutcomeDistributionRules.probabilityTolerance,
                            "\(tier) pass table does not sum to one")
            }
        }

        test("run tables retain every calibrated base weight") {
            let expected: [Tier: [(RunOutcomeBand, Double)]] = [
                .pro: [(.loss, 0.100), (.short, 0.538), (.medium, 0.232),
                       (.explosive, 0.108), (.breakaway, 0.010), (.fumbleLost, 0.012)],
                .college: [(.loss, 0.100), (.short, 0.508), (.medium, 0.229),
                           (.explosive, 0.136), (.breakaway, 0.015), (.fumbleLost, 0.012)],
            ]
            for tier in Tier.allCases {
                for (actual, expectedWeight) in zip(OutcomeDistributionRules.runWeights(tier: tier),
                                                     expected[tier]!) {
                    expectEqual(actual.0, expectedWeight.0, "\(tier) run band")
                    expectClose(actual.1, expectedWeight.1,
                                OutcomeDistributionRules.probabilityTolerance,
                                "\(tier) \(actual.0) run weight")
                }
            }
        }

        test("pass tables retain every calibrated base weight") {
            let expected: [Tier: [(PassOutcomeBand, Double)]] = [
                .pro: [(.sack, 0.060), (.interception, 0.022), (.incompletion, 0.278),
                       (.completion, 0.491), (.explosiveCompletion, 0.137), (.fumbleLost, 0.012)],
                .college: [(.sack, 0.060), (.interception, 0.022), (.incompletion, 0.278),
                           (.completion, 0.485), (.explosiveCompletion, 0.143), (.fumbleLost, 0.012)],
            ]
            for tier in Tier.allCases {
                for (actual, expectedWeight) in zip(OutcomeDistributionRules.passWeights(tier: tier),
                                                     expected[tier]!) {
                    expectEqual(actual.0, expectedWeight.0, "\(tier) pass band")
                    expectClose(actual.1, expectedWeight.1,
                                OutcomeDistributionRules.probabilityTolerance,
                                "\(tier) \(actual.0) pass weight")
                }
            }
        }

        test("run tables use the calibrated explosive mass for each tier") {
            let proExplosive = OutcomeDistributionRules.runWeights(tier: .pro)
                .filter { $0.0 == .explosive || $0.0 == .breakaway }
                .reduce(0) { $0 + $1.1 }
            let collegeExplosive = OutcomeDistributionRules.runWeights(tier: .college)
                .filter { $0.0 == .explosive || $0.0 == .breakaway }
                .reduce(0) { $0 + $1.1 }

            expectClose(proExplosive, 0.118, OutcomeDistributionRules.probabilityTolerance)
            expectClose(collegeExplosive, 0.151, OutcomeDistributionRules.probabilityTolerance)
        }

        test("pass tables use the calibrated explosive mass for each tier") {
            let proExplosive = OutcomeDistributionRules.passWeights(tier: .pro)
                .first { $0.0 == .explosiveCompletion }!.1
            let collegeExplosive = OutcomeDistributionRules.passWeights(tier: .college)
                .first { $0.0 == .explosiveCompletion }!.1

            expectClose(proExplosive, 0.137, OutcomeDistributionRules.probabilityTolerance)
            expectClose(collegeExplosive, 0.143, OutcomeDistributionRules.probabilityTolerance)
        }

        test("yard ranges are ordered") {
            let ranges: [ClosedRange<Int>] = [
                OutcomeDistributionRules.lossYards,
                OutcomeDistributionRules.shortRunYards,
                OutcomeDistributionRules.mediumRunYards,
                OutcomeDistributionRules.explosiveRunYards,
                OutcomeDistributionRules.breakawayRunYards,
                OutcomeDistributionRules.ordinaryPassYards,
                OutcomeDistributionRules.explosivePassYards,
                OutcomeDistributionRules.runFumbleYards,
                OutcomeDistributionRules.passFumbleYards,
                OutcomeDistributionRules.sackYards,
                OutcomeDistributionRules.puntYards,
            ]
            for range in ranges {
                expect(range.lowerBound <= range.upperBound, "unordered range \(range)")
            }
            expectEqual(OutcomeDistributionRules.lossYards, -3...0)
            expectEqual(OutcomeDistributionRules.shortRunYards, 1...3)
            expectEqual(OutcomeDistributionRules.mediumRunYards, 4...9)
            expectEqual(OutcomeDistributionRules.explosiveRunYards, 10...18)
            expectEqual(OutcomeDistributionRules.breakawayRunYards, 19...60)
            expectEqual(OutcomeDistributionRules.ordinaryPassYards, 1...14)
            expectEqual(OutcomeDistributionRules.explosivePassYards, 15...35)
            expectEqual(OutcomeDistributionRules.runFumbleYards, 1...3)
            expectEqual(OutcomeDistributionRules.passFumbleYards, 1...14)
            expectEqual(OutcomeDistributionRules.sackYards, -9 ... -4)
            expectEqual(OutcomeDistributionRules.puntYards, 35...55)
        }

        test("a ten-point rating edge consumes half the maximum probability shift") {
            let shift = 10.0 / OutcomeDistributionRules.ratingPointsForMaximumShift
                * OutcomeDistributionRules.maximumProbabilityShift
            expectClose(shift, OutcomeDistributionRules.maximumProbabilityShift / 2,
                        OutcomeDistributionRules.probabilityTolerance)
        }

        test("outcome constants match the starting calibration") {
            expectClose(OutcomeDistributionRules.proRunExplosiveMass, 0.118,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.collegeRunExplosiveMass, 0.151,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.passCompletionMass, 0.640,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.passSackMass, 0.060,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.passInterceptionMass, 0.022,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.proPassExplosiveMass, 0.137,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.collegePassExplosiveMass, 0.143,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.fumbleLostMass, 0.012,
                        OutcomeDistributionRules.probabilityTolerance)
            expectEqual(OutcomeDistributionRules.kneelYards, -1)
            expectClose(OutcomeDistributionRules.maximumProbabilityShift, 0.04,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.maximumBallSecurityProbabilityShift, 0.006,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.ratingPointsForMaximumShift, 20.0,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.maximumDepthProbabilityShift, 0.010,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.outsideRunProbabilityShift, 0.010,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.runAggressionProbabilityShift, 0.006,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.passAggressionProbabilityShift, 0.008,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.defensiveAggressionProbabilityShift, 0.006,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.rusherSackShiftPerPlayer, 0.006,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.coverageShellProbabilityShift, 0.008,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.longYardageProbabilityShift, 0.008,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.shortYardageProbabilityShift, 0.006,
                        OutcomeDistributionRules.probabilityTolerance)
            expectEqual(OutcomeDistributionRules.shortYardageDistance, 2)
            expectEqual(OutcomeDistributionRules.longYardageDistance, 7)
            expectClose(OutcomeDistributionRules.targetRatingFloor, 1.0,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.riskRewardSplit, 0.5,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.passProtectionThrowWeight, 0.5,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.minimumAttributionMagnitude, 0.5,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.attributionMagnitudeRange, 0.5,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.proHomeProbabilityShift, 0.010,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.collegeHomeProbabilityShift, 0.045,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.proFieldGoalBase, 0.84,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.collegeFieldGoalBase, 0.76,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.maximumFieldGoalMatchupProbabilityShift, 0.10,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.fieldGoalDistancePenaltyPerYard, 0.006,
                        OutcomeDistributionRules.probabilityTolerance)
            expectEqual(OutcomeDistributionRules.fieldGoalReferenceDistance, 35)
            expectClose(OutcomeDistributionRules.minimumFieldGoalProbability, 0.02,
                        OutcomeDistributionRules.probabilityTolerance)
            expectClose(OutcomeDistributionRules.maximumFieldGoalProbability, 0.98,
                        OutcomeDistributionRules.probabilityTolerance)
            expectEqual(OutcomeDistributionRules.lastFieldYardOffset, 1)
            expectClose(OutcomeDistributionRules.probabilityTolerance, 1e-12, 0)
        }
    }
}
