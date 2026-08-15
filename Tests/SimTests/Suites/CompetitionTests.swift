import Foundation
import FootballSimCore

func runCompetitionTests() {
    suite("Player form rating") {
        test("uses position-specific box-score production and bounded output") {
            let id = UUID(uuidString: "00000000-0000-4000-8000-000000007000")!
            expectEqual(
                PlayerFormRating.rating(
                    for: PlayerGameStatistics(playerID: id, passingYards: 200, touchdowns: 2),
                    position: .quarterback
                ),
                81
            )
            expectEqual(
                PlayerFormRating.rating(
                    for: PlayerGameStatistics(playerID: id, receivingYards: 80),
                    position: .wideReceiver
                ),
                63
            )
            expectEqual(
                PlayerFormRating.rating(
                    for: PlayerGameStatistics(playerID: id, touchdowns: 20),
                    position: .cornerback
                ),
                SharedRules.ratingRange.upperBound
            )
            expectEqual(
                PlayerFormRating.rating(
                    for: PlayerGameStatistics(playerID: id),
                    position: .runningBack
                ),
                55
            )
            expectEqual(
                PlayerFormRating.rating(
                    for: PlayerGameStatistics(
                        playerID: id,
                        passingYards: Int.max,
                        touchdowns: Int.max
                    ),
                    position: .quarterback
                ),
                SharedRules.ratingRange.upperBound
            )
        }
    }

    suite("Tie-aware standings") {
        test("records ties without inventing a winner and keeps legacy JSON readable") {
            let team = UUID(uuidString: "00000000-0000-4000-8000-000000007001")!
            var row = StandingRow(id: team)
            row.record(pointsFor: 17, pointsAgainst: 17, conferenceGame: true)
            expectEqual(row.wins, 0)
            expectEqual(row.losses, 0)
            expectEqual(row.ties, 1)
            expectEqual(row.conferenceTies, 1)
            expectEqual(row.games, 1)
            expectEqual(row.winningPercentage, 0.5)

            let legacy = """
            {"id":"00000000-0000-4000-8000-000000007001","wins":2,"losses":1,"conferenceWins":1,"conferenceLosses":1,"pointsFor":42,"pointsAgainst":35}
            """.data(using: .utf8)!
            let restored = try JSONDecoder.stable().decode(StandingRow.self, from: legacy)
            expectEqual(restored.ties, 0)
            expectEqual(restored.games, 3)
        }
    }

    suite("Regular-season schedule") {
        test("bootstrap creates only the exact regular-season slate") {
            let state = GameState.bootstrap(seed: 70_001)
            let games = state.competition.currentSchedule.games
            let college = games.filter { $0.tier == .college }
            let pro = games.filter { $0.tier == .pro }

            expectEqual(college.count, CollegeRules.programmeCount
                * CollegeRules.gamesPerRegularSeason / 2)
            expectEqual(pro.count, ProRules.teamCount * ProRules.gamesPerRegularSeason / 2)
            expect(games.allSatisfy { $0.stage == .regularSeason })
            expect(games.allSatisfy { $0.result == nil })
        }

        test("every organisation has its exact game count and one bye") {
            let state = GameState.bootstrap(seed: 70_002)
            assertScheduleShape(
                games: state.competition.currentSchedule.games.filter { $0.tier == .college },
                memberIDs: state.programmes.ids,
                gamesPerTeam: CollegeRules.gamesPerRegularSeason,
                regularSeasonWeeks: CollegeRules.regularSeasonWeeks
            )

            let collegeByesByWeek = (1...CollegeRules.regularSeasonWeeks).map { week in
                CollegeRules.programmeCount - 2 * state.competition.currentSchedule.games.filter {
                    $0.tier == .college && $0.week == week
                }.count
            }
            let proByesByWeek = (1...ProRules.regularSeasonWeeks).map { week in
                ProRules.teamCount - 2 * state.competition.currentSchedule.games.filter {
                    $0.tier == .pro && $0.week == week
                }.count
            }
            expect((collegeByesByWeek.max() ?? Int.max) <= 12,
                   "college scheduling collapsed every bye into one week")
            expect((proByesByWeek.max() ?? Int.max) <= 2,
                   "pro scheduling collapsed every bye into one week")
            assertScheduleShape(
                games: state.competition.currentSchedule.games.filter { $0.tier == .pro },
                memberIDs: state.proTeams.ids,
                gamesPerTeam: ProRules.gamesPerRegularSeason,
                regularSeasonWeeks: ProRules.regularSeasonWeeks
            )
        }

        test("no team is double-booked and no opponent pairing repeats") {
            let state = GameState.bootstrap(seed: 70_003)
            var weeklyAppearances: Set<String> = []
            var pairings: Set<String> = []

            for game in state.competition.currentSchedule.games {
                expect(game.homeID != game.awayID, "a team was scheduled against itself")
                for teamID in [game.homeID, game.awayID] {
                    let key = "\(game.tier.rawValue)|\(game.week)|\(teamID.uuidString)"
                    expect(weeklyAppearances.insert(key).inserted,
                           "a team was scheduled twice in one week")
                }
                let ordered = [game.homeID, game.awayID].sorted {
                    $0.uuidString < $1.uuidString
                }
                let pairing = "\(game.tier.rawValue)|\(ordered[0])|\(ordered[1])"
                expect(pairings.insert(pairing).inserted,
                       "an opponent pairing repeated in one season")
            }
        }

        test("all schedule IDs and references are unique and resolvable") {
            let state = GameState.bootstrap(seed: 70_004)
            let games = state.competition.currentSchedule.games
            expectEqual(Set(games.map(\.id)).count, games.count)
            for game in games {
                let storeContainsHome = game.tier == .college
                    ? state.programmes[game.homeID] != nil
                    : state.proTeams[game.homeID] != nil
                let storeContainsAway = game.tier == .college
                    ? state.programmes[game.awayID] != nil
                    : state.proTeams[game.awayID] != nil
                expect(storeContainsHome && storeContainsAway,
                       "a schedule entry references a missing organisation")
            }
        }

        test("the same seed creates byte-identical competition state") {
            let first = GameState.bootstrap(seed: 70_005).competition
            let second = GameState.bootstrap(seed: 70_005).competition
            expectEqual(try SaveEnvelope.encode(first), try SaveEnvelope.encode(second))
        }

        test("bye distribution remains bounded across an independent seed sweep") {
            for seed in 70_100..<70_116 {
                let world = LeagueGenerator.generate(seed: UInt64(seed))
                let schedule = ScheduleGenerator.regularSeason(
                    seed: UInt64(seed),
                    season: 0,
                    programmes: world.programmes,
                    proTeams: world.proTeams
                )
                expect(maximumByes(
                    tier: .college,
                    memberCount: CollegeRules.programmeCount,
                    weeks: CollegeRules.regularSeasonWeeks,
                    schedule: schedule
                ) <= 12, "college byes collapsed for seed \(seed)")
                expect(maximumByes(
                    tier: .pro,
                    memberCount: ProRules.teamCount,
                    weeks: ProRules.regularSeasonWeeks,
                    schedule: schedule
                ) <= 2, "pro byes collapsed for seed \(seed)")
            }
        }
    }


    suite("Abstract competition results") {
        test("the same scheduled game produces the same bounded summary") {
            let state = GameState.bootstrap(seed: 71_001)
            let game = state.competition.currentSchedule.games[0]
            let first = AbstractGameSimulator.play(game, in: state)
            let second = AbstractGameSimulator.play(game, in: state)

            expectEqual(first, second)
            expect(first.homeScore >= 0 && first.awayScore >= 0)
            if game.tier == .college || game.stage != .regularSeason {
                expect(first.homeScore != first.awayScore,
                       "a college or postseason game ended tied")
            }
            expectEqual(first.homeStatistics.points, first.homeScore)
            expectEqual(first.awayStatistics.points, first.awayScore)
            expectEqual(
                first.homeStatistics.passingYards + first.homeStatistics.rushingYards,
                first.homeStatistics.offensiveYards
            )
            expectEqual(
                first.awayStatistics.passingYards + first.awayStatistics.rushingYards,
                first.awayStatistics.offensiveYards
            )
        }

        test("professional regular season permits ties but college and postseason do not") {
            let state = GameState.bootstrap(seed: 71_002)
            let home = state.proTeams.ids[0]
            let away = state.proTeams.ids[1]
            var observedProfessionalTie = false

            for ordinal in 0..<1_024 {
                let game = ScheduledGame(
                    id: UUID(uuidString: String(
                        format: "00000000-0000-4000-8004-%012d", ordinal
                    ))!,
                    season: state.calendar.season,
                    tier: .pro,
                    week: 1,
                    stage: .regularSeason,
                    homeID: home,
                    awayID: away
                )
                let result = AbstractGameSimulator.play(game, in: state)
                if result.homeScore == result.awayScore {
                    observedProfessionalTie = true
                    break
                }
            }
            expect(observedProfessionalTie,
                   "the professional regular-season model never permits a bounded tie")

            for (tier, stage) in [
                (Tier.college, CompetitionStage.regularSeason),
                (Tier.pro, CompetitionStage.championship),
            ] {
                let teams = tier == .college ? state.programmes.ids : state.proTeams.ids
                for ordinal in 0..<128 {
                    let game = ScheduledGame(
                        id: UUID(uuidString: String(
                            format: "00000000-0000-4000-8005-%012d", ordinal
                        ))!,
                        season: state.calendar.season,
                        tier: tier,
                        week: 1,
                        stage: stage,
                        homeID: teams[0],
                        awayID: teams[1]
                    )
                    let result = AbstractGameSimulator.play(game, in: state)
                    expect(result.homeScore != result.awayScore,
                           "(tier.rawValue) (stage.rawValue) returned a tie")
                }
            }
        }

        test("the abstract result records every available contributor canonically") {
            let state = GameState.bootstrap(seed: 71_006)
            let game = state.competition.currentSchedule.games.first { $0.tier == .college }!
            let result = AbstractGameSimulator.play(game, in: state)
            let expectedHome = state.programmes[game.homeID]!.rosterIDs.filter {
                state.people.playerLifecycle[$0]?.isAvailable == true
            }.sorted { $0.uuidString < $1.uuidString }
            let expectedAway = state.programmes[game.awayID]!.rosterIDs.filter {
                state.people.playerLifecycle[$0]?.isAvailable == true
            }.sorted { $0.uuidString < $1.uuidString }

            expectEqual(result.homeParticipantIDs, expectedHome)
            expectEqual(result.awayParticipantIDs, expectedAway)

            let productionIDs = Set(result.playerStatistics.map(\.playerID))
            let homeRoster = expectedHome.compactMap { state.players[$0] }
            for position in [Position.leftTackle, .cornerback, .kicker] {
                let statless = homeRoster.first { $0.position == position }!
                expect(result.homeParticipantIDs.contains(statless.id))
                expect(!productionIDs.contains(statless.id),
                       "a statless \(position.rawValue) was omitted from appearances")
            }
            let quarterbacks = homeRoster.filter { $0.position == .quarterback }
            let rankedQuarterbacks = quarterbacks.sorted { lhs, rhs in
                if lhs.overall != rhs.overall { return lhs.overall > rhs.overall }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            let reserveQuarterback = rankedQuarterbacks[1]
            expect(result.homeParticipantIDs.contains(reserveQuarterback.id))
            expect(!productionIDs.contains(reserveQuarterback.id),
                   "a reserve without a production line was omitted from appearances")
        }

        test("participant lists are unique bounded and input-order independent") {
            let ids = (0...CompetitionRules.maximumParticipantsPerTeam).map { ordinal in
                UUID(uuidString: String(
                    format: "00000000-0000-4000-8001-%012d",
                    ordinal
                ))!
            }
            let first = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: ids + [ids[0]],
                awayParticipantIDs: [ids[0]],
                playerStatistics: []
            )
            let second = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: Array(ids.reversed()),
                awayParticipantIDs: [ids[0]],
                playerStatistics: []
            )

            expectEqual(first.homeParticipantIDs.count,
                        CompetitionRules.maximumParticipantsPerTeam)
            expectEqual(Set(first.homeParticipantIDs).count, first.homeParticipantIDs.count)
            expect(first.awayParticipantIDs.isEmpty,
                   "one player appeared for both teams in the same result")
            expectEqual(try JSONEncoder.stable().encode(first),
                        try JSONEncoder.stable().encode(second))
        }

        test("batch result recording matches sequential replacement bytes and order") {
            let state = GameState.bootstrap(seed: 71_007)
            let original = state.competition.currentSchedule
            let selected = Array(original.games.prefix(8))
            let records = selected.map { game in
                ScheduledGameResult(
                    gameID: game.id,
                    summary: AbstractGameSimulator.play(game, in: state)
                )
            }
            var sequential = original
            for record in records {
                var game = sequential.games.first { $0.id == record.gameID }!
                game.result = record.summary
                expect(sequential.replace(game))
            }
            var batched = original

            let recorded = try batched.recordResults(records)

            expectEqual(try JSONEncoder.stable().encode(batched),
                        try JSONEncoder.stable().encode(sequential))
            expectEqual(batched.games.map(\.id), original.games.map(\.id),
                        "recording results changed schedule order")
            expectEqual(recorded.map(\.id), selected.map(\.id))
        }

        test("batch result recording rejects an unknown ID atomically") {
            let state = GameState.bootstrap(seed: 71_008)
            var schedule = state.competition.currentSchedule
            let before = try JSONEncoder.stable().encode(schedule)
            let known = schedule.games[0]
            let records = [
                ScheduledGameResult(
                    gameID: known.id,
                    summary: AbstractGameSimulator.play(known, in: state)
                ),
                ScheduledGameResult(
                    gameID: UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF7108")!,
                    summary: AbstractGameSimulator.play(known, in: state)
                ),
            ]

            do {
                _ = try schedule.recordResults(records)
                expect(false, "an unknown scheduled-game ID was accepted")
            } catch let error as ScheduleResultRecordingError {
                expectEqual(error, .unknownGameID(records[1].gameID))
            }
            expectEqual(try JSONEncoder.stable().encode(schedule), before)
        }

        test("batch result recording rejects duplicate IDs atomically") {
            let state = GameState.bootstrap(seed: 71_009)
            var schedule = state.competition.currentSchedule
            let before = try JSONEncoder.stable().encode(schedule)
            let game = schedule.games[0]
            let record = ScheduledGameResult(
                gameID: game.id,
                summary: AbstractGameSimulator.play(game, in: state)
            )

            do {
                _ = try schedule.recordResults([record, record])
                expect(false, "duplicate scheduled-game IDs were accepted")
            } catch let error as ScheduleResultRecordingError {
                expectEqual(error, .duplicateGameID(game.id))
            }
            expectEqual(try JSONEncoder.stable().encode(schedule), before)
        }

        test("batch result recording rejects an already resolved ID atomically") {
            let state = GameState.bootstrap(seed: 71_010)
            var schedule = state.competition.currentSchedule
            let resolvedGame = schedule.games[0]
            let pendingGame = schedule.games[1]
            let resolvedRecord = ScheduledGameResult(
                gameID: resolvedGame.id,
                summary: AbstractGameSimulator.play(resolvedGame, in: state)
            )
            _ = try schedule.recordResults([resolvedRecord])
            let before = try JSONEncoder.stable().encode(schedule)
            let pendingRecord = ScheduledGameResult(
                gameID: pendingGame.id,
                summary: AbstractGameSimulator.play(pendingGame, in: state)
            )

            do {
                _ = try schedule.recordResults([pendingRecord, resolvedRecord])
                expect(false, "an already resolved scheduled-game ID was accepted")
            } catch let error as ScheduleResultRecordingError {
                expectEqual(error, .alreadyResolvedGameID(resolvedGame.id))
            }
            expectEqual(try JSONEncoder.stable().encode(schedule), before)
        }

        test("batch result recording canonicalizes input permutation") {
            let state = GameState.bootstrap(seed: 71_011)
            let original = state.competition.currentSchedule
            let selected = Array(original.games.prefix(8))
            let records = selected.map { game in
                ScheduledGameResult(
                    gameID: game.id,
                    summary: AbstractGameSimulator.play(game, in: state)
                )
            }
            var forward = original
            var reversed = original

            let forwardRecorded = try forward.recordResults(records)
            let reverseRecorded = try reversed.recordResults(Array(records.reversed()))

            expectEqual(try JSONEncoder.stable().encode(forward),
                        try JSONEncoder.stable().encode(reversed))
            expectEqual(forwardRecorded, reverseRecorded)
            expectEqual(forwardRecorded.map(\.id), selected.map(\.id))
        }


        test("the weekly scheduler completes the slate and rebuilds both projections") {
            let before = GameState.bootstrap(seed: 71_004)
            let due = before.competition.currentSchedule.games.filter {
                $0.season == before.calendar.season && $0.week == before.calendar.week
            }
            let transition = try WorldScheduler.advanceWeek(before)
            let completed = transition.state.competition.currentSchedule.games.filter {
                due.map(\.id).contains($0.id) && $0.result != nil
            }

            expectEqual(completed.count, due.count)
            expectEqual(
                transition.state.competition.standings.values
                    .flatMap { $0 }.reduce(0) { $0 + $1.games },
                due.count * 2
            )
            expectEqual(
                transition.state.competition.teamStatistics.values.reduce(0) { $0 + $1.games },
                due.count * 2
            )
            expectEqual(
                transition.emittedEvents.filter { event in
                    if case .gameCompleted = event.payload { return true }
                    return false
                }.count,
                due.count
            )
            let completedEventIDs = transition.emittedEvents.compactMap { event -> UUID? in
                guard case let .gameCompleted(gameID, _, _, _, _, _) = event.payload else {
                    return nil
                }
                return gameID
            }
            expectEqual(completedEventIDs, due.map(\.id),
                        "scheduler game events left canonical schedule order")
            expectEqual(
                transition.state.competition.currentSchedule.games.map(\.id),
                before.competition.currentSchedule.games.map(\.id),
                "recording weekly results reordered the schedule"
            )
        }

        test("standings and statistics reconcile completed games exactly") {
            var state = GameState.bootstrap(seed: 71_002)
            let selected = Array(state.competition.currentSchedule.games.prefix(120))
            for var game in selected {
                game.result = AbstractGameSimulator.play(game, in: state)
                expect(state.competition.currentSchedule.replace(game))
            }
            state.competition = CompetitionReducer.rebuild(from: state)

            let rows = state.competition.standings.values.flatMap { $0 }
            expectEqual(rows.reduce(0) { $0 + $1.wins + $1.losses }, selected.count * 2)
            expectEqual(rows.reduce(0) { $0 + $1.pointsFor },
                        selected.reduce(0) { total, game in
                            guard let result = state.competition.currentSchedule.games
                                .first(where: { $0.id == game.id })?.result else { return total }
                            return total + result.homeScore + result.awayScore
                        })
            expectEqual(
                state.competition.teamStatistics.values.reduce(0) { $0 + $1.games },
                selected.count * 2
            )
            expect(!state.competition.playerStatistics.isEmpty,
                   "team results produced no player-level statistical history")
        }

        test("appearances count once per participant independently of production") {
            var state = GameState.bootstrap(seed: 71_007)
            var game = state.competition.currentSchedule.games[0]
            let homeIDs = state.programmes[game.homeID]!.rosterIDs
            let awayID = state.programmes[game.awayID]!.rosterIDs[0]
            let producerID = homeIDs[0]
            let statlessID = homeIDs[1]
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [statlessID, producerID],
                awayParticipantIDs: [awayID],
                playerStatistics: [PlayerGameStatistics(
                    playerID: producerID,
                    passingYards: 250
                )]
            )
            expect(state.competition.currentSchedule.replace(game))

            let rebuilt = CompetitionReducer.rebuildStatistics(from: state)

            expectEqual(rebuilt.playerStatistics[producerID]?.games, 1)
            expectEqual(rebuilt.playerStatistics[producerID]?.passingYards, 250)
            expectEqual(rebuilt.playerStatistics[statlessID]?.games, 1)
            expectEqual(rebuilt.playerStatistics[statlessID]?.passingYards, 0)
            expectEqual(rebuilt.playerStatistics[awayID]?.games, 1)
        }

        test("aggregate rebuilding is idempotent and rankings contain every member once") {
            var state = GameState.bootstrap(seed: 71_003)
            for var game in state.competition.currentSchedule.games.prefix(80) {
                game.result = AbstractGameSimulator.play(game, in: state)
                _ = state.competition.currentSchedule.replace(game)
            }
            let first = CompetitionReducer.rebuild(from: state)
            state.competition = first
            let second = CompetitionReducer.rebuild(from: state)

            expectEqual(first, second)
            expectEqual(Set(first.rankings[.college] ?? []).count, CollegeRules.programmeCount)
            expectEqual(Set(first.rankings[.pro] ?? []).count, ProRules.teamCount)
        }

        test("a two-team standings tie is resolved by head-to-head before point differential") {
            var state = GameState.bootstrap(seed: 71_005)
            let members = state.league.conferences.first { $0.tier == .college }!.memberIDs
            let a = members[0]
            let b = members[1]
            let c = members[2]
            let d = members[3]
            state.competition.currentSchedule = SeasonSchedule(season: 0, games: [
                scheduledResult(home: a, away: b, week: 1, homeScore: 20, awayScore: 10),
                scheduledResult(home: c, away: a, week: 2, homeScore: 40, awayScore: 0),
                scheduledResult(home: b, away: d, week: 2, homeScore: 70, awayScore: 0),
            ])
            state.competition = CompetitionReducer.rebuild(from: state)

            let ranking = state.competition.rankings[.college]!
            expect(ranking.firstIndex(of: a)! < ranking.firstIndex(of: b)!,
                   "the head-to-head winner lost the two-team tiebreak")
            let rowA = state.competition.standings[.college]!.first { $0.id == a }!
            expectEqual(rowA.conferenceGames, 2)
        }
    }


    suite("Postseason and rollover") {
        test("one shared season reaches both brackets and archives both champions") {
            var state = GameState.bootstrap(seed: 72_001)

            for _ in 1...13 { state = try WorldScheduler.advanceWeek(state).state }
            expectEqual(
                state.competition.currentSchedule.games.filter {
                    $0.stage == .conferenceChampionship && $0.tier == .college
                }.count,
                CollegeRules.conferenceCount
            )

            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(stageGames(.quarterfinal, tier: .college, state: state).count, 4)
            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(stageGames(.semifinal, tier: .college, state: state).count, 2)
            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(stageGames(.championship, tier: .college, state: state).count, 1)
            state = try WorldScheduler.advanceWeek(state).state
            expect(state.competition.collegeChampionID != nil,
                   "the completed college final produced no champion")

            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(stageGames(.quarterfinal, tier: .pro, state: state).count, 4)
            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(stageGames(.semifinal, tier: .pro, state: state).count, 2)
            state = try WorldScheduler.advanceWeek(state).state
            expectEqual(stageGames(.championship, tier: .pro, state: state).count, 1)
            state = try WorldScheduler.advanceWeek(state).state

            expectEqual(state.calendar, CalendarState(season: 1, week: 1))
            expectEqual(state.competition.archives.count, 1)
            expect(state.programmes[state.competition.archives[0].collegeChampionID] != nil)
            expect(state.proTeams[state.competition.archives[0].proChampionID] != nil)
            expectEqual(state.competition.archives[0].awards.count, 6)
            expectEqual(
                Set(state.competition.archives[0].awards.map(\.kind)),
                Set(SeasonAwardKind.allCases)
            )
            expect(state.competition.recordBook.highestTeamScore != nil)
            expect(state.competition.recordBook.mostTeamYards != nil)
            expect(state.competition.recordBook.highestTeamScore?.opponentID != nil)
            expect(state.competition.recordBook.mostTeamYards?.opponentID != nil)
            expectEqual(state.competition.archives[0].gamesPlayed, 1_100)
            expect((10...45).contains(
                state.competition.archives[0].totalPoints
                    / (state.competition.archives[0].gamesPlayed * 2)
            ))
            expectEqual(state.competition.currentSchedule.season, 1)
            expect(state.competition.currentSchedule.games.allSatisfy {
                $0.stage == .regularSeason && $0.result == nil
            })
        }

        test("postseason participants are unique, valid, and earned from the prior round") {
            var state = GameState.bootstrap(seed: 72_002)
            for _ in 1...15 { state = try WorldScheduler.advanceWeek(state).state }
            let quarterfinals = stageGames(.quarterfinal, tier: .college, state: state)
            let semifinals = stageGames(.semifinal, tier: .college, state: state)
            let quarterfinalWinners = Set(quarterfinals.compactMap(winnerID))
            let semifinalParticipants = semifinals.flatMap { [$0.homeID, $0.awayID] }

            expectEqual(Set(semifinalParticipants).count, semifinalParticipants.count)
            expectEqual(Set(semifinalParticipants), quarterfinalWinners)
            expect(semifinalParticipants.allSatisfy { state.programmes[$0] != nil })
            let regularCompleted = state.competition.currentSchedule.games.filter {
                $0.stage == .regularSeason && $0.result != nil
            }.count
            let standingGames = state.competition.standings.values
                .flatMap { $0 }.reduce(0) { $0 + $1.games }
            expectEqual(standingGames, regularCompleted * 2,
                        "postseason games leaked into regular-season standings")
        }
    }


    suite("Competition integrity") {
        test("persisted game summaries reject malformed participant manifests") {
            let homeID = UUID(uuidString: "00000000-0000-4000-8002-000000000001")!
            let awayID = UUID(uuidString: "00000000-0000-4000-8002-000000000002")!
            let outsiderID = UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF8002")!
            let valid = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [homeID],
                awayParticipantIDs: [awayID],
                playerStatistics: [PlayerGameStatistics(playerID: homeID, passingYards: 200)]
            )
            let encoded = try JSONEncoder.stable().encode(valid)
            let base = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            let tooMany = (0...CompetitionRules.maximumParticipantsPerTeam).map { ordinal in
                String(format: "00000000-0000-4000-8003-%012d", ordinal)
            }
            var corruptions: [[String: Any]] = []
            var duplicate = base
            duplicate["homeParticipantIDs"] = [homeID.uuidString, homeID.uuidString]
            corruptions.append(duplicate)
            var overBound = base
            overBound["homeParticipantIDs"] = tooMany
            corruptions.append(overBound)
            var overlap = base
            overlap["awayParticipantIDs"] = [homeID.uuidString]
            corruptions.append(overlap)
            var outsiderLine = base
            outsiderLine["playerStatistics"] = [[
                "playerID": outsiderID.uuidString,
                "passingYards": 200,
                "rushingYards": 0,
                "receivingYards": 0,
                "touchdowns": 0,
            ]]
            corruptions.append(outsiderLine)
            var negativeScore = base
            negativeScore["homeScore"] = -1
            corruptions.append(negativeScore)
            var overBoundScore = base
            overBoundScore["homeScore"] = CompetitionRules.maximumFinalTeamScore + 1
            corruptions.append(overBoundScore)

            for object in corruptions {
                let corrupted = try JSONSerialization.data(withJSONObject: object)
                do {
                    _ = try JSONDecoder.stable().decode(GameSummary.self, from: corrupted)
                    expect(false, "a malformed participant manifest decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("a schedule participant that does not exist is rejected") {
            var state = GameState.bootstrap(seed: 73_001)
            let existing = state.programmes.ids[0]
            state.competition.currentSchedule.append(contentsOf: [ScheduledGame(
                id: UUID(uuidString: "00000000-0000-4000-8000-00000000C001")!,
                season: state.calendar.season,
                tier: .college,
                week: 1,
                stage: .regularSeason,
                homeID: UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFC001")!,
                awayID: existing
            )])

            let report = WorldIntegrity.check(state)
            expect(report.issues.contains { issue in
                if case .missingScheduledParticipant = issue { return true }
                return false
            })
        }

        test("standings and statistics that drift from results are rejected") {
            var state = try WorldScheduler.advanceWeek(GameState.bootstrap(seed: 73_002)).state
            state.competition.standings[.college] = []
            let completedTeamID = state.competition.currentSchedule.games.first {
                $0.result != nil
            }!.homeID
            state.competition.teamStatistics[completedTeamID] = TeamSeasonStatistics()

            let report = WorldIntegrity.check(state)
            expect(report.issues.contains { issue in
                if case .standingsDoNotMatchResults = issue { return true }
                return false
            })
            expect(report.issues.contains { issue in
                if case .statisticsDoNotMatchResults = issue { return true }
                return false
            })
        }

        test("a roster without a playable position group is rejected") {
            var state = GameState.bootstrap(seed: 73_003)
            let programmeID = state.programmes.ids[0]
            let quarterbackIDs = Set(state.programmes[programmeID]!.rosterIDs.filter {
                state.players[$0]?.position == .quarterback
            })
            state.programmes.update(programmeID) {
                $0.rosterIDs.removeAll(where: quarterbackIDs.contains)
            }

            let report = WorldIntegrity.check(state)
            expect(report.issues.contains { issue in
                if case .missingPositionalCoverage(organisationID: programmeID, position: .quarterback) = issue {
                    return true
                }
                return false
            })
        }

        test("a game result cannot attribute statistics to an uninvolved player") {
            var state = GameState.bootstrap(seed: 73_004)
            var game = state.competition.currentSchedule.games[0]
            let outsiderID = state.players.ids.first { id in
                !state.programmes[game.homeID]!.rosterIDs.contains(id)
                    && !state.programmes[game.awayID]!.rosterIDs.contains(id)
            }!
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                playerStatistics: [PlayerGameStatistics(playerID: outsiderID, passingYards: 300)]
            )
            expect(state.competition.currentSchedule.replace(game))
            state.competition = CompetitionReducer.rebuild(from: state)

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidScheduledGame(gameID: game.id) = issue { return true }
                return false
            })
        }

        test("a game result cannot record a participant outside either roster") {
            var state = GameState.bootstrap(seed: 73_006)
            var game = state.competition.currentSchedule.games[0]
            let outsiderID = state.players.ids.first { id in
                !state.programmes[game.homeID]!.rosterIDs.contains(id)
                    && !state.programmes[game.awayID]!.rosterIDs.contains(id)
            }!
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [outsiderID],
                awayParticipantIDs: [],
                playerStatistics: []
            )
            expect(state.competition.currentSchedule.replace(game))
            state.competition = CompetitionReducer.rebuild(from: state)

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidScheduledGame(gameID: game.id) = issue { return true }
                return false
            })
        }

        test("a participant must belong to the recorded side") {
            var state = GameState.bootstrap(seed: 73_007)
            var game = state.competition.currentSchedule.games[0]
            let awayPlayerID = state.programmes[game.awayID]!.rosterIDs[0]
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [awayPlayerID],
                awayParticipantIDs: [],
                playerStatistics: []
            )
            expect(state.competition.currentSchedule.replace(game))
            state.competition = CompetitionReducer.rebuild(from: state)

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidScheduledGame(gameID: game.id) = issue { return true }
                return false
            })
        }

        test("a production line requires a recorded appearance") {
            var state = GameState.bootstrap(seed: 73_008)
            var game = state.competition.currentSchedule.games[0]
            let homeRoster = state.programmes[game.homeID]!.rosterIDs
            let awayPlayerID = state.programmes[game.awayID]!.rosterIDs[0]
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [homeRoster[0]],
                awayParticipantIDs: [awayPlayerID],
                playerStatistics: [PlayerGameStatistics(
                    playerID: homeRoster[1],
                    passingYards: 200
                )]
            )
            expect(state.competition.currentSchedule.replace(game))
            state.competition = CompetitionReducer.rebuild(from: state)

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidScheduledGame(gameID: game.id) = issue { return true }
                return false
            })
        }

        test("a recorded participant must have an active player identity") {
            var state = GameState.bootstrap(seed: 73_009)
            var game = state.competition.currentSchedule.games[0]
            let missingPlayerID = state.programmes[game.homeID]!.rosterIDs[0]
            _ = state.players.remove(missingPlayerID)
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [missingPlayerID],
                awayParticipantIDs: [],
                playerStatistics: []
            )
            expect(state.competition.currentSchedule.replace(game))
            state.competition = CompetitionReducer.rebuild(from: state)

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidScheduledGame(gameID: game.id) = issue { return true }
                return false
            })
        }

        test("a team-only handcrafted result may omit participant manifests") {
            var state = GameState.bootstrap(seed: 73_010)
            var game = state.competition.currentSchedule.games[0]
            game.result = GameSummary(
                homeScore: 20,
                awayScore: 10,
                homeStatistics: testTeamStatistics(points: 20),
                awayStatistics: testTeamStatistics(points: 10),
                homeParticipantIDs: [],
                awayParticipantIDs: [],
                playerStatistics: []
            )
            expect(state.competition.currentSchedule.replace(game))
            state.competition = CompetitionReducer.rebuild(from: state)

            expect(!WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidScheduledGame(gameID: game.id) = issue { return true }
                return false
            })
        }

        test("malformed competition archives are rejected even when constructed directly") {
            var state = GameState.bootstrap(seed: 73_005)
            state.competition = CompetitionState(
                currentSchedule: state.competition.currentSchedule,
                standings: state.competition.standings,
                rankings: state.competition.rankings,
                teamStatistics: state.competition.teamStatistics,
                playerStatistics: state.competition.playerStatistics,
                archives: [SeasonArchive(
                    season: 0,
                    collegeChampionID: state.programmes.ids[0],
                    proChampionID: state.proTeams.ids[0],
                    finalCollegeRanking: [],
                    finalProRanking: [],
                    awards: [],
                    gamesPlayed: 0,
                    totalPoints: 0
                )]
            )

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidSeasonArchive(season: 0) = issue { return true }
                return false
            })
        }
    }
}

func runM1SoakTests(seasons: Int) {
    suite("M1 target-world soak") {
        test("college and pro complete repeated seasons without integrity drift") {
            let clock = ContinuousClock()
            let started = clock.now
            var state = GameState.bootstrap(seed: 90_001)
            var checkpointSizes: [Int: Int] = [:]

            for season in 1...seasons {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    state = try WorldScheduler.advanceWeek(state).state
                }
                expectEqual(state.calendar, CalendarState(season: season, week: 1))
                let report = WorldIntegrity.check(state)
                expect(report.isValid, report.issues.map(\.description).joined(separator: ", "))

                if [1, 5, seasons].contains(season) {
                    let encoded = try SaveEnvelope.encode(state)
                    checkpointSizes[season] = encoded.count
                    let restored = try SaveEnvelope.decode(GameState.self, from: encoded)
                    expectEqual(restored, state)
                }
            }

            expectEqual(state.competition.archives.count, seasons)
            expect(state.competition.archives.allSatisfy { $0.gamesPlayed == 1_100 })
            let averagePoints = state.competition.archives.reduce(0) { $0 + $1.totalPoints }
                / (state.competition.archives.reduce(0) { $0 + $1.gamesPlayed } * 2)
            expect((10...45).contains(averagePoints))
            expect(Set(state.competition.archives.map(\.collegeChampionID)).count >= 3)
            expect(Set(state.competition.archives.map(\.proChampionID)).count >= 3)

            let elapsed = started.duration(to: clock.now)
            print("M1 soak: \(seasons) seasons in \(elapsed); save checkpoints \(checkpointSizes)")
        }
    }
}

private func assertScheduleShape(
    games: [ScheduledGame],
    memberIDs: [UUID],
    gamesPerTeam: Int,
    regularSeasonWeeks: Int
) {
    for memberID in memberIDs {
        let memberGames = games.filter { $0.homeID == memberID || $0.awayID == memberID }
        expectEqual(memberGames.count, gamesPerTeam)
        expectEqual(Set(memberGames.map(\.week)).count, gamesPerTeam)
        expectEqual(regularSeasonWeeks - Set(memberGames.map(\.week)).count, 1)
        expect(memberGames.allSatisfy { (1...regularSeasonWeeks).contains($0.week) })
    }
}

private func stageGames(
    _ stage: CompetitionStage,
    tier: Tier,
    state: GameState
) -> [ScheduledGame] {
    state.competition.currentSchedule.games.filter {
        $0.stage == stage && $0.tier == tier
    }
}

private func winnerID(_ game: ScheduledGame) -> UUID? {
    guard let result = game.result else { return nil }
    return result.homeScore > result.awayScore ? game.homeID : game.awayID
}

private func scheduledResult(
    home: UUID,
    away: UUID,
    week: Int,
    homeScore: Int,
    awayScore: Int
) -> ScheduledGame {
    let id = UUID(uuidString: String(
        format: "00000000-0000-4000-8000-%012d",
        week * 100 + homeScore + awayScore
    ))!
    return ScheduledGame(
        id: id,
        season: 0,
        tier: .college,
        week: week,
        stage: .regularSeason,
        homeID: home,
        awayID: away,
        result: GameSummary(
            homeScore: homeScore,
            awayScore: awayScore,
            homeStatistics: testTeamStatistics(points: homeScore),
            awayStatistics: testTeamStatistics(points: awayScore),
            playerStatistics: []
        )
    )
}

private func testTeamStatistics(points: Int) -> TeamGameStatistics {
    TeamGameStatistics(
        points: points,
        offensiveYards: 300,
        passingYards: 180,
        rushingYards: 120,
        turnovers: 1
    )
}

private func maximumByes(
    tier: Tier,
    memberCount: Int,
    weeks: Int,
    schedule: [ScheduledGame]
) -> Int {
    (1...weeks).map { week in
        memberCount - 2 * schedule.filter { $0.tier == tier && $0.week == week }.count
    }.max() ?? memberCount
}
