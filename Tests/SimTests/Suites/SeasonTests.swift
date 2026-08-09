import Foundation
import FootballSimCore

func runSeasonTests() {
    suite("ScheduleGenerator") {
        var league = LeagueFactory.makeDefaultLeague(seed: 41, userTeamIndex: 0, coach: .stub())
        SeasonEngine.startSeason(&league)
        let schedule = league.schedule

        test("every team plays a full season") {
            for team in league.teams {
                let games = schedule.filter { $0.involves(team.id) }
                expectEqual(
                    games.count,
                    LeagueRules.regularSeasonGames,
                    "\(team.abbreviation) game count"
                )
            }
        }

        test("nobody plays twice in one week") {
            for week in 1...LeagueRules.seasonWeeks {
                var seen = Set<UUID>()
                for game in schedule where game.week == week {
                    expect(seen.insert(game.homeTeamID).inserted, "double booking in week \(week)")
                    expect(seen.insert(game.awayTeamID).inserted, "double booking in week \(week)")
                }
            }
        }

        test("every team gets exactly one bye in the legal window") {
            for team in league.teams {
                let weeksPlayed = Set(schedule.filter { $0.involves(team.id) }.map(\.week))
                let byes = (1...LeagueRules.seasonWeeks).filter { !weeksPlayed.contains($0) }
                expectEqual(byes.count, 1, "\(team.abbreviation) bye count")
                if let bye = byes.first {
                    expect(
                        bye >= LeagueRules.earliestByeWeek && bye <= LeagueRules.latestByeWeek,
                        "\(team.abbreviation) bye in week \(bye)"
                    )
                }
            }
        }

        test("division rivals meet home and away") {
            for team in league.teams {
                let rivals = league.teams.filter {
                    $0.id != team.id && $0.conference == team.conference && $0.division == team.division
                }
                for rival in rivals {
                    let meetings = schedule.filter { $0.involves(team.id) && $0.involves(rival.id) }
                    expectEqual(
                        meetings.count, 2,
                        "\(team.abbreviation) vs \(rival.abbreviation) meetings"
                    )
                    let hosted = meetings.filter { $0.homeTeamID == team.id }.count
                    expectEqual(hosted, 1, "\(team.abbreviation) should host \(rival.abbreviation) once")
                }
                let divisionGames = schedule.filter {
                    $0.involves(team.id) && $0.kind == .division
                }
                expectEqual(
                    divisionGames.count,
                    LeagueRules.divisionGamesPerTeam,
                    "\(team.abbreviation) division games"
                )
            }
        }

        test("home and away games are close to balanced") {
            for team in league.teams {
                let home = schedule.filter { $0.homeTeamID == team.id }.count
                expect(
                    home >= 7 && home <= 10,
                    "\(team.abbreviation) hosts \(home) games"
                )
            }
        }

        test("schedules differ between years") {
            var later = LeagueFactory.makeDefaultLeague(seed: 41, userTeamIndex: 0, coach: .stub(), year: 2027)
            SeasonEngine.startSeason(&later)
            let firstPairs = Set(schedule.map { [$0.homeTeamID.uuidString, $0.awayTeamID.uuidString].sorted().joined() })
            let laterPairs = Set(later.schedule.map { [$0.homeTeamID.uuidString, $0.awayTeamID.uuidString].sorted().joined() })
            expect(firstPairs != laterPairs, "opponents should rotate year to year")
        }
    }

    suite("Standings") {
        test("results feed the table correctly") {
            var league = LeagueFactory.makeDefaultLeague(seed: 42, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...LeagueRules.seasonWeeks { SeasonEngine.advanceWeek(&league) }

            for team in league.teams {
                let record = league.record(for: team.id)
                expectEqual(
                    record.gamesPlayed,
                    LeagueRules.regularSeasonGames,
                    "\(team.abbreviation) games played"
                )
                expect(record.pointsFor > 0, "\(team.abbreviation) scored nothing all year")
                expect(
                    record.divisionWins + record.divisionLosses <= LeagueRules.divisionGamesPerTeam,
                    "\(team.abbreviation) division games exceed the schedule"
                )
                expect(
                    record.conferenceWins + record.conferenceLosses >= record.divisionWins + record.divisionLosses,
                    "\(team.abbreviation) conference record must include division games"
                )
            }

            let totalWins = league.teams.reduce(0) { $0 + league.record(for: $1.id).wins }
            let totalLosses = league.teams.reduce(0) { $0 + league.record(for: $1.id).losses }
            expectEqual(totalWins, totalLosses, "wins and losses must balance across the league")
        }

        test("playoff field is the right size and shape") {
            var league = LeagueFactory.makeDefaultLeague(seed: 43, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...LeagueRules.seasonWeeks { SeasonEngine.advanceWeek(&league) }

            for conference in Conference.allCases {
                let seeds = StandingsCalculator.playoffSeeds(conference: conference, in: league)
                expectEqual(
                    seeds.count,
                    league.settings.playoffFormat.teamsPerConference,
                    "\(conference) playoff field"
                )
                let divisionWinners = seeds.filter(\.clinchedDivision)
                expectEqual(divisionWinners.count, LeagueRules.divisionsPerConference, "division winners")
                // Every division winner must be seeded above every wild card.
                let lastWinnerSeed = divisionWinners.compactMap(\.conferenceSeed).max() ?? 0
                let firstWildCard = seeds.filter { !$0.clinchedDivision }
                    .compactMap(\.conferenceSeed).min() ?? 99
                expect(lastWinnerSeed < firstWildCard, "a wild card outranked a division winner")
            }
        }

        test("tiebreakers order deterministically") {
            var league = LeagueFactory.makeDefaultLeague(seed: 44, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...LeagueRules.seasonWeeks { SeasonEngine.advanceWeek(&league) }
            let first = StandingsCalculator.leagueStandings(in: league).map(\.team.id)
            let second = StandingsCalculator.leagueStandings(in: league).map(\.team.id)
            expect(first == second, "standings order must be stable")
        }
    }

    suite("SeasonEngine") {
        test("a full season reaches the offseason with a champion") {
            var league = LeagueFactory.makeDefaultLeague(seed: 45, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)

            expect(league.phase.isOffseason, "league did not reach the offseason: \(league.phase)")
            let champion = SeasonEngine.champion(of: league)
            expect(champion != nil, "no champion was crowned")

            let playoffGames = league.results.filter { $0.kind.isPlayoff }
            // 14-team field: 6 wild card, 4 divisional, 2 conference titles, 1 final.
            expectEqual(playoffGames.count, 13, "playoff game count")
            expect(
                playoffGames.allSatisfy { !$0.isTie },
                "a playoff game ended in a tie"
            )
        }

        test("every playoff format resolves to a single champion") {
            for format in PlayoffFormat.allCases {
                var settings = LeagueSettings()
                settings.playoffFormat = format
                var league = LeagueFactory.makeDefaultLeague(
                    seed: 452, userTeamIndex: 0, coach: .stub(), settings: settings
                )
                SeasonEngine.startSeason(&league)
                SeasonEngine.simulateToOffseason(&league)

                expect(
                    league.phase.isOffseason,
                    "\(format.displayName) never reached the offseason"
                )
                expect(
                    SeasonEngine.champion(of: league) != nil,
                    "\(format.displayName) crowned no champion"
                )

                // Every round must halve the field cleanly: one championship game, and each
                // conference reduced to exactly one finalist.
                let finals = league.results.filter { $0.kind == .championship }
                expectEqual(finals.count, 1, "\(format.displayName) championship games")

                let played = league.results.filter { $0.kind.isPlayoff }
                expect(
                    played.allSatisfy { !$0.isTie },
                    "\(format.displayName) produced a tied playoff game"
                )

                // Nobody should appear in a round after losing.
                var eliminated = Set<UUID>()
                for record in played.sorted(by: { $0.week < $1.week }) {
                    expect(
                        !eliminated.contains(record.homeTeamID)
                            && !eliminated.contains(record.awayTeamID),
                        "\(format.displayName): an eliminated team played again"
                    )
                    if let loser = record.loserID { eliminated.insert(loser) }
                }
            }
        }

        test("advancing a week is fast enough to feel instant") {
            var league = LeagueFactory.makeDefaultLeague(seed: 46, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            let start = Date()
            for _ in 1...LeagueRules.seasonWeeks { SeasonEngine.advanceWeek(&league) }
            let msPerWeek = Date().timeIntervalSince(start) * 1000 / Double(LeagueRules.seasonWeeks)
            // The budget is a release-build number. Unoptimised Swift runs this several times
            // slower, so asserting it in debug reports a failure that means nothing — and would
            // report a pass that means nothing if the budget were ever loosened. Measure in both
            // configurations, gate only in release.
            #if DEBUG
            print("  ⏱  week advance: \(String(format: "%.0f", msPerWeek)) ms (debug — budget not enforced)")
            #else
            expect(msPerWeek < 150, "\(String(format: "%.0f", msPerWeek)) ms per week exceeds the 150 ms budget")
            #endif
        }

        test("injuries are applied and heal over time") {
            var league = LeagueFactory.makeDefaultLeague(seed: 47, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...6 { SeasonEngine.advanceWeek(&league) }
            let injured = league.teams.flatMap(\.injuredPlayers).count
            expect(injured > 0, "nobody got hurt in six weeks across the whole league")
            expect(injured < 120, "\(injured) injured players is an epidemic, not a season")
        }

        test("the season produces news") {
            var league = LeagueFactory.makeDefaultLeague(seed: 48, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...4 { SeasonEngine.advanceWeek(&league) }
            expect(league.news.count > 20, "news feed is too quiet: \(league.news.count) items")
            expect(
                league.news.contains { $0.category == .gameResult },
                "no game results reached the feed"
            )
        }

        test("a user-played result is used instead of a simulated one") {
            var league = LeagueFactory.makeDefaultLeague(seed: 49, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            guard let userGame = league.games(inWeek: 1).first(where: { $0.involves(league.userTeamID) })
            else { return expect(false, "user team has no week 1 game") }

            var stats = TeamGameStats()
            stats.points = 99
            let handMade = GameRecord(
                scheduledGameID: userGame.id,
                week: 1,
                year: league.year,
                kind: userGame.kind,
                homeTeamID: userGame.homeTeamID,
                awayTeamID: userGame.awayTeamID,
                homeStats: stats,
                awayStats: TeamGameStats(),
                playerStats: [:]
            )
            SeasonEngine.advanceWeek(&league, userGameResult: handMade)

            let stored = league.result(for: userGame.id)
            expectEqual(stored?.homeScore, 99, "the played result should be the one recorded")
            expectEqual(
                league.record(for: userGame.homeTeamID).wins, 1,
                "the played result should count in the standings"
            )
        }

        test("season simulation is deterministic end to end") {
            func playSeason() -> [Int] {
                var league = LeagueFactory.makeDefaultLeague(seed: 50, userTeamIndex: 0, coach: .stub())
                SeasonEngine.startSeason(&league)
                SeasonEngine.simulateToOffseason(&league)
                return league.teams.map { league.record(for: $0.id).wins }
            }
            expect(playSeason() == playSeason(), "two identical seeds produced different seasons")
        }

        test("win totals spread realistically across the league") {
            var league = LeagueFactory.makeDefaultLeague(seed: 51, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...LeagueRules.seasonWeeks { SeasonEngine.advanceWeek(&league) }
            let wins = league.teams.map { league.record(for: $0.id).wins }.sorted()
            expect(wins.first! <= 6, "worst team won \(wins.first!) games")
            expect(wins.last! >= 11, "best team won only \(wins.last!) games")
        }
    }
}
