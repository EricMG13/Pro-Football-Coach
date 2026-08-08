import Foundation
import FootballSimCore

private enum Format {
    static func money(_ amount: Int) -> String { NewsEngine.money(amount) }
}

/// The test that matters most: does the league still make sense after a decade?
///
/// Every complaint the reference games collect is a long-run failure — rosters decaying,
/// ratings inflating, AI teams never rebuilding, saves corrupting around season eight. This
/// suite runs ten seasons unattended and checks the league is still healthy at the end.
func runDynastyTests() {
    suite("Coach career") {
        test("experience levels the coach and pays skill points") {
            var coach = CoachProfile.stub()
            let startingLevel = coach.level
            for _ in 0..<20 { CoachEngine.award(.win, to: &coach) }
            expect(coach.level > startingLevel, "800 experience should have levelled the coach")
            expect(coach.skillPoints > 1, "levelling should award skill points")
        }

        test("skill trees unlock in order and cost points") {
            var coach = CoachProfile.stub()
            coach.skillPoints = 10
            expect(!CoachEngine.unlock(branch: .offense, index: 2, coach: &coach), "skipped ahead in the tree")
            expect(CoachEngine.unlock(branch: .offense, index: 0, coach: &coach), "first node refused")
            expect(CoachEngine.unlock(branch: .offense, index: 1, coach: &coach), "second node refused")
            expect(!CoachEngine.unlock(branch: .offense, index: 0, coach: &coach), "bought the same node twice")
            expectEqual(coach.skillPoints, 10 - 1 - 2, "skill point accounting")
            expect(CoachEngine.offenseRatingBonus(for: coach) == 2, "unlocked nodes should apply")
        }

        test("background grants its opening node") {
            var coach = CoachProfile.stub(background: .talentEvaluator)
            CoachEngine.applyBackgroundBonus(to: &coach)
            expect(coach.hasUnlocked(branch: .scouting, node: 0), "background node not granted")
        }

        test("goals scale to the roster and pay out when met") {
            var league = LeagueFactory.makeDefaultLeague(seed: 81, userTeamIndex: 0, coach: .stub())
            var rng = SeededRandom(seed: 5)
            var goals = CoachEngine.makeSeasonGoals(for: league, rng: &rng)
            expect(!goals.isEmpty, "no goals were set")
            expect(goals.contains { $0.kind == .wins }, "there should always be a win target")

            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)
            let experienceBefore = league.coach.experience + league.coach.level * 100
            CoachEngine.settleGoals(&goals, league: &league)
            let experienceAfter = league.coach.experience + league.coach.level * 100
            expect(experienceAfter >= experienceBefore, "settling goals should never cost experience")
        }

        test("the job market never leaves a coach stranded") {
            var league = LeagueFactory.makeDefaultLeague(seed: 82, userTeamIndex: 0, coach: .stub())
            // A wildly overqualified coach in a league of strong teams still gets an offer.
            league.coach.championships = 8
            league.coach.careerWins = 200
            for index in league.teams.indices { league.teams[index].reputation = 99 }
            var rng = SeededRandom(seed: 9)
            let offers = CoachEngine.jobOffers(for: league, rng: &rng)
            expect(!offers.isEmpty, "a career must never dead-end with zero offers")
        }

        test("job security responds to results") {
            var league = LeagueFactory.makeDefaultLeague(seed: 83, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...LeagueRules.seasonWeeks { SeasonEngine.advanceWeek(&league) }
            let before = league.coach.jobSecurity
            CoachEngine.updateJobSecurity(&league)
            let after = league.coach.jobSecurity
            let record = league.record(for: league.userTeamID)
            if record.winPercentage > 0.6 {
                expect(after >= before, "a winning season should not hurt job security")
            }
            expect(after >= 0 && after <= 100, "job security left its range: \(after)")
        }
    }

    suite("Offseason") {
        test("a full offseason completes and starts the next year") {
            var league = LeagueFactory.makeDefaultLeague(seed: 84, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)
            let year = league.year

            OffseasonEngine.runFullOffseason(&league)

            expectEqual(league.year, year + 1, "the calendar should roll over")
            expect(league.phase == .preseason, "should be back at the preseason, got \(league.phase)")
            expectEqual(league.history.count, 1, "the finished season should be archived")
            expect(league.history[0].championTeamID != nil, "the archive should record a champion")
        }

        test("every roster is legal after the offseason") {
            var league = LeagueFactory.makeDefaultLeague(seed: 85, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)
            OffseasonEngine.runFullOffseason(&league)

            for team in league.teams {
                expectEqual(
                    team.activeRoster.count,
                    LeagueRules.activeRosterSize,
                    "\(team.abbreviation) active roster"
                )
                expect(
                    team.practiceSquad.count <= LeagueRules.practiceSquadSize,
                    "\(team.abbreviation) oversized practice squad"
                )
                for position in Position.allCases {
                    expect(
                        team.activeRoster.filter { $0.position == position }.count
                            >= position.minimumRosterCount,
                        "\(team.abbreviation) short at \(position.abbreviation)"
                    )
                }
                expect(
                    team.roster.allSatisfy { $0.contract != nil },
                    "\(team.abbreviation) carries an unsigned player"
                )
                expectEqual(
                    team.staff.count,
                    StaffRole.allCases.count,
                    "\(team.abbreviation) staff after the carousel"
                )
            }
        }

        test("veterans retire and rookies replace them") {
            var league = LeagueFactory.makeDefaultLeague(seed: 86, userTeamIndex: 0, coach: .stub())
            // Age the league so there is a retirement class to find.
            for teamIndex in league.teams.indices {
                for playerIndex in league.teams[teamIndex].roster.indices where playerIndex % 4 == 0 {
                    league.teams[teamIndex].roster[playerIndex].age = 36
                }
            }
            let retired = OffseasonEngine.processRetirements(&league)
            expect(!retired.isEmpty, "an ageing league produced no retirements")
            expect(
                retired.allSatisfy { $0.age >= 28 },
                "somebody retired far too young"
            )
        }
    }

    suite("Ten-season soak") {
        // One long run, inspected from several angles.
        var league = LeagueFactory.makeDefaultLeague(seed: 90, userTeamIndex: 0, coach: .stub())
        var averageOverallByYear: [Double] = []
        var averageAgeByYear: [Double] = []
        var championIDs: [UUID] = []
        var topFiveStreak: [UUID: Int] = [:]
        var crashedAt: Int?

        for season in 0..<10 {
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)
            if let champion = SeasonEngine.champion(of: league) { championIDs.append(champion.id) }

            let players = league.teams.flatMap(\.roster)
            guard !players.isEmpty else { crashedAt = season; break }
            averageOverallByYear.append(
                Double(players.reduce(0) { $0 + $1.overall }) / Double(players.count)
            )
            averageAgeByYear.append(
                Double(players.reduce(0) { $0 + $1.age }) / Double(players.count)
            )

            let topFive = league.teams
                .sorted { $0.overallRating > $1.overallRating }
                .prefix(5)
            for team in topFive { topFiveStreak[team.id, default: 0] += 1 }

            OffseasonEngine.runFullOffseason(&league)
        }

        test("ten seasons complete without falling over") {
            expect(crashedAt == nil, "the league collapsed in season \(crashedAt ?? -1)")
            expectEqual(league.history.count, 10, "every season should be archived")
            expectEqual(championIDs.count, 10, "every season should crown a champion")
        }

        test("ratings neither inflate nor collapse") {
            for (index, average) in averageOverallByYear.enumerated() {
                expectIn(average, 62...76, "average overall in season \(index + 1)")
            }
            guard let first = averageOverallByYear.first, let last = averageOverallByYear.last
            else { return expect(false, "no seasons recorded") }
            expect(abs(last - first) < 6, "average rating drifted from \(first) to \(last)")
        }

        test("the age pyramid stays stable") {
            for (index, average) in averageAgeByYear.enumerated() {
                expectIn(average, 23...30, "average age in season \(index + 1)")
            }
        }

        test("the league keeps churning at the top") {
            // A genuine dynasty is fine; a team that is literally never displaced across a
            // decade means the AI never rebuilds and nobody ever catches up.
            let permanent = topFiveStreak.values.filter { $0 >= 10 }.count
            expect(permanent == 0, "\(permanent) team(s) held a top-five spot in all ten seasons")

            // Breadth matters more than any single run: plenty of teams should pass through
            // the top of the league over ten years.
            expect(
                topFiveStreak.count >= 12,
                "only \(topFiveStreak.count) different teams reached the top five in a decade"
            )
            expect(
                Set(championIDs).count >= 3,
                "only \(Set(championIDs).count) different champions in ten seasons"
            )
        }

        test("rosters and the cap are still legal a decade in") {
            for team in league.teams {
                expectEqual(
                    team.activeRoster.count,
                    LeagueRules.activeRosterSize,
                    "\(team.abbreviation) roster size after ten seasons"
                )
                // A team can end up slightly over: dead money from cutting a badly structured
                // contract counts against the cap and cannot itself be cut away. That is cap
                // hell working as designed, but it should stay small and recoverable.
                let overage = -CapEngine.capSpace(for: team, in: league)
                expect(
                    overage <= league.salaryCap / 20,
                    "\(team.abbreviation) is \(Format.money(overage)) over the cap"
                )
            }
        }

        test("the salary cap grows over a decade") {
            expect(
                league.salaryCap > LeagueRules.salaryCapYearOne,
                "the cap never grew: \(league.salaryCap)"
            )
        }

        test("history and career statistics accumulate") {
            let veteran = league.teams
                .flatMap(\.roster)
                .filter { $0.yearsPro >= 5 }
                .max { league.careerStats(for: $0.id).gamesPlayed < league.careerStats(for: $1.id).gamesPlayed }
            expect(veteran != nil, "nobody survived five seasons")
            if let veteran {
                let career = league.careerStats(for: veteran.id)
                expect(career.gamesPlayed > 0, "a five-year veteran has no recorded games")
            }
        }

        test("the save still round trips after ten seasons") {
            let encoder = JSONEncoder.stable()
            let data = try encoder.encode(league)
            let restored = try JSONDecoder.stable().decode(League.self, from: data)
            let reencoded = try encoder.encode(restored)
            expect(data == reencoded, "a ten-season save did not survive a round trip")
            // Saves have to stay small enough to write on every week advance.
            let megabytes = Double(data.count) / 1_000_000
            // The plan's definition of done sets 5 MB, and the save is written on every week
            // advance, so this is a budget rather than a curiosity.
            expect(
                megabytes < 5,
                "save file grew to \(String(format: "%.2f", megabytes)) MB"
            )
        }

        test("the league does not hoard players or headlines") {
            // Both of these once grew without limit — nine thousand unsigned players and eight
            // thousand stories after ten seasons, which was three quarters of the save file.
            expect(
                league.freeAgents.count <= LeagueRules.freeAgentPoolLimit,
                "free agent pool is \(league.freeAgents.count)"
            )
            expect(
                league.news.count <= LeagueRules.newsFeedLimit,
                "news feed is \(league.news.count) items"
            )
            expect(
                !league.freeAgents.contains { $0.age >= LeagueRules.freeAgentRetirementAge },
                "an unsigned player past the retirement age is still on the market"
            )
            // Trimming the market must not empty it: teams sign from this pool all season.
            expect(league.freeAgents.count > 100, "the market was trimmed to nothing")
        }
    }
}

func runLegacyTests() {
    suite("Records and Hall of Fame") {
        test("the record book is seeded so year one has marks to chase") {
            let league = LeagueFactory.makeDefaultLeague(seed: 300, userTeamIndex: 0, coach: .stub())
            let records = RecordsBook.current(in: league)
            expectEqual(records.count, LeagueRecord.Kind.allCases.count)
            expect(records.allSatisfy { $0.value > 0 }, "a record has no value")
            expect(records.allSatisfy { !$0.holderName.isEmpty }, "a record has no holder")
        }

        test("a monstrous season takes over the record") {
            var league = LeagueFactory.makeDefaultLeague(seed: 301, userTeamIndex: 0, coach: .stub())
            let seeded = RecordsBook.current(in: league)
                .first { $0.kind == .passingYardsSeason }!

            // Fabricate a season nobody could match.
            let quarterback = league.teams[0].starters(at: .qb)[0]
            var line = StatLine()
            line.passingYards = seeded.value + 1_000
            var stats = TeamGameStats()
            stats.points = 30
            league.results.append(
                GameRecord(
                    scheduledGameID: UUID(), week: 1, year: league.year, kind: .conference,
                    homeTeamID: league.teams[0].id, awayTeamID: league.teams[1].id,
                    homeStats: stats, awayStats: TeamGameStats(),
                    playerStats: [quarterback.id: line]
                )
            )

            let updated = RecordsBook.current(in: league).first { $0.kind == .passingYardsSeason }!
            expectEqual(updated.holderName, quarterback.name, "the record should change hands")
            expectEqual(updated.value, seeded.value + 1_000)
        }

        test("only genuinely great careers are enshrined") {
            let league = LeagueFactory.makeDefaultLeague(seed: 302, userTeamIndex: 0, coach: .stub())
            let journeyman = TestFixtures.player(position: .rb, rating: 68, age: 33)
            var modest = StatLine()
            modest.rushingYards = 3_400
            expect(
                HallOfFame.score(player: journeyman, career: modest) < HallOfFame.inductionThreshold,
                "a journeyman should not reach the Hall of Fame"
            )

            let great = TestFixtures.player(position: .qb, rating: 92, age: 39)
            var monumental = StatLine()
            monumental.passingYards = 62_000
            monumental.passingTouchdowns = 430
            expect(
                HallOfFame.score(player: great, career: monumental, championships: 2)
                    >= HallOfFame.inductionThreshold,
                "an all-time career should be enshrined"
            )
            expect(!HallOfFame.summary(for: great, career: monumental).isEmpty)
            _ = league
        }
    }

    suite("Scenarios") {
        test("every scenario applies cleanly and leaves a legal league") {
            for scenario in Scenario.all {
                var league = LeagueFactory.makeDefaultLeague(
                    seed: 310, userTeamIndex: 6, coach: .stub()
                )
                scenario.apply(&league)

                guard let team = league.userTeam else {
                    expect(false, "\(scenario.name) lost the user team")
                    continue
                }
                for position in Position.allCases {
                    expect(
                        team.activeRoster.filter { $0.position == position }.count
                            >= position.minimumRosterCount,
                        "\(scenario.name) left \(position.abbreviation) short"
                    )
                }
                expect(
                    team.roster.allSatisfy { $0.contract != nil },
                    "\(scenario.name) left a player unsigned"
                )
                expect(
                    !league.news.isEmpty,
                    "\(scenario.name) should explain itself in the feed"
                )
            }
        }

        test("cap hell really is a cap problem") {
            var league = LeagueFactory.makeDefaultLeague(seed: 311, userTeamIndex: 3, coach: .stub())
            let before = CapEngine.capSpace(for: league.userTeam!, in: league)
            Scenario.capHell.apply(&league)
            let after = CapEngine.capSpace(for: league.userTeam!, in: league)
            expect(after < before, "cap hell should cost cap space")
            expect(league.deadMoney[league.userTeamID] ?? 0 > 0, "cap hell should carry dead money")
        }

        test("an expansion roster is young and cheap") {
            var league = LeagueFactory.makeDefaultLeague(seed: 312, userTeamIndex: 5, coach: .stub())
            Scenario.expansion.apply(&league)
            let team = league.userTeam!
            let averageAge = Double(team.roster.reduce(0) { $0 + $1.age }) / Double(team.roster.count)
            expect(averageAge < 26, "expansion roster average age \(averageAge)")
            expect(
                CapEngine.capSpace(for: team, in: league) > 0,
                "an expansion team should have cap room"
            )
        }

        test("the aging legend is a genuine star with a short window") {
            var league = LeagueFactory.makeDefaultLeague(seed: 313, userTeamIndex: 8, coach: .stub())
            Scenario.agingLegend.apply(&league)
            let quarterback = league.userTeam!.starters(at: .qb)[0]
            expect(quarterback.overall >= 90, "the legend should be elite: \(quarterback.overall)")
            expect(quarterback.age >= 37, "the legend should be old: \(quarterback.age)")
            expect(
                (quarterback.contract?.yearsRemaining ?? 0) <= 2,
                "the window should be short"
            )
        }
    }
}
