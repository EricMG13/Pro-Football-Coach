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
    }

    suite("College rules") {
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

        test("the draft is 7 rounds of 32") {
            expectEqual(ProRules.draftRounds, 7)
            expectEqual(ProRules.draftPicksPerRound, ProRules.teamCount)
            expectEqual(ProRules.draftPickCount, 224)
            expectEqual(ProRules.draftPickCount, ProRules.draftRounds * ProRules.draftPicksPerRound)
        }
    }
}
