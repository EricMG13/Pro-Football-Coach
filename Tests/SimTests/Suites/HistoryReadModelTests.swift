import Foundation
import FootballSimCore

func runHistoryReadModelTests() {
    suite("M7 history and search read model") {
        test("builds deterministic searchable entities, archives, records, and events") {
            var state = GameState.bootstrap(seed: 70_101)
            let programmeID = try require(state.programmes.ids.first)
            let proTeamID = try require(state.proTeams.ids.first)
            let archive = SeasonArchive(
                season: 0,
                collegeChampionID: programmeID,
                proChampionID: proTeamID,
                finalCollegeRanking: [programmeID],
                finalProRanking: [proTeamID],
                awards: [SeasonAward(kind: .champion, tier: .college, winnerID: programmeID, value: 1)],
                gamesPlayed: 2,
                totalPoints: 42
            )
            state.competition.appendArchive(archive)
            let event = DomainEvent(
                id: DomainEvent.deterministicID(rootSeed: state.league.seed, sequence: state.history.nextSequence),
                sequence: state.history.nextSequence,
                occurredAt: state.calendar,
                payload: .seasonCompleted(
                    season: 0,
                    collegeChampionID: programmeID,
                    proChampionID: proTeamID
                )
            )
            expect(state.history.append(event))

            let first = WorldHistoryReadModel.build(from: state)
            let second = WorldHistoryReadModel.build(from: state)
            expectEqual(first, second)
            expect(first.entries.contains { $0.kind == .programme })
            expect(first.entries.contains { $0.kind == .proTeam })
            expect(first.entries.contains { $0.kind == .season && $0.season == 0 })
            expect(first.entries.contains { $0.kind == .award && $0.title.contains("champion") })
            expect(first.entries.contains { $0.kind == .event && $0.title == "Season completed" })

            let programmeName = try require(state.programmes[programmeID]?.name)
            let programmeResults = first.search(programmeName.uppercased())
            expect(programmeResults.entries.contains { $0.entityID == programmeID })
            expect(first.search("champion").entries.contains { $0.kind == .award })
            expect(first.search("does-not-exist").entries.isEmpty)
            expect(first.search(" ").entries.isEmpty)
        }

        test("search limit is deterministic and never exposes the authoritative root") {
            let state = GameState.bootstrap(seed: 70_102)
            let model = WorldHistoryReadModel.build(from: state)
            let limited = model.search("player", limit: 3)
            expectEqual(limited.entries.count, 3)
            expectEqual(model.search("player", limit: -1).entries.count, 0)
            expectEqual(model.search("player", limit: 3).entries, model.search("PLAYER", limit: 3).entries)
            expect(WorldHistoryReadModel.maximumEntries >= model.entries.count)
        }

        test("rivalry meetings strengthen once, in calendar order") {
            var state = GameState.bootstrap(seed: 70_103)
            let game = try require(state.competition.currentSchedule.games.first {
                $0.tier == .college && $0.week == state.calendar.week
            })
            let rivalryID = UUID(uuidString: "00000000-0000-4000-8000-000000007103")!
            let rivalry = Rivalry(
                id: rivalryID,
                sideA: game.homeID,
                sideB: game.awayID,
                origin: .geography,
                intensity: Rating(60)
            )
            state.rivalries = EntityStore([rivalry])
            let summary = AbstractGameSimulator.play(game, in: state)
            state.competition.currentSchedule = try recording(
                ScheduledGameResult(gameID: game.id, summary: summary),
                in: state.competition.currentSchedule
            )

            let first = RivalrySystem.process(after: state.calendar, in: state)
            state.rivalries = first.rivalries
            let second = RivalrySystem.process(after: state.calendar, in: state)
            let updated = try require(first.rivalries[rivalryID])
            expectEqual(second.rivalries, first.rivalries)
            expect(second.recordedRivalryIDs.isEmpty)
            expectEqual(first.recordedRivalryIDs, [rivalryID])
            expect(updated.intensity.value > rivalry.intensity.value)
            expectEqual(updated.notableMeetings.count, 1)
            expect(updated.notableMeetings[0].contains("S0 W1"))
        }

        test("the weekly scheduler applies the same rivalry reducer") {
            var state = GameState.bootstrap(seed: 70_104)
            let game = try require(state.competition.currentSchedule.games.first {
                $0.tier == .college && $0.week == state.calendar.week
            })
            let rivalryID = UUID(uuidString: "00000000-0000-4000-8000-000000007104")!
            state.rivalries = EntityStore([Rivalry(
                id: rivalryID,
                sideA: game.homeID,
                sideB: game.awayID,
                origin: .conference,
                intensity: Rating(55)
            )])
            let before = try require(state.rivalries[rivalryID])
            let transition = try WorldScheduler.advanceWeek(state)
            let after = try require(transition.state.rivalries[rivalryID])
            expect(after.intensity.value > before.intensity.value)
            expectEqual(after.notableMeetings.count, 1)
            expect(transition.stepRecords.contains {
                $0.step == .relationshipsAndStakeholders && $0.status == .executed
            })
        }
    }
}

private enum HistoryReadModelTestError: Error { case missingFixture }

private func require<T>(_ value: T?) throws -> T {
    guard let value else { throw HistoryReadModelTestError.missingFixture }
    return value
}

private func recording(
    _ result: ScheduledGameResult,
    in schedule: SeasonSchedule
) throws -> SeasonSchedule {
    var copy = schedule
    _ = try copy.recordResults([result])
    return copy
}
