import Foundation
import FootballSimCore
import ProFootballCoachUI

func runPersistenceTests() {
    suite("SaveStore") {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pfc-tests-\(UUID().uuidString)")
        let store = SaveStore(directory: directory)

        test("a franchise survives a save and load") {
            var league = LeagueFactory.makeDefaultLeague(seed: 200, userTeamIndex: 4, coach: .stub())
            SeasonEngine.startSeason(&league)
            for _ in 1...3 { SeasonEngine.advanceWeek(&league) }

            let id = UUID()
            _ = try store.save(league, id: id, name: "Test Franchise")
            let restored = try store.load(id: id)

            expectEqual(restored.year, league.year)
            expectEqual(restored.teams.count, league.teams.count)
            expectEqual(restored.userTeamID, league.userTeamID)
            expectEqual(restored.results.count, league.results.count)
            expectEqual(
                restored.record(for: league.userTeamID).wins,
                league.record(for: league.userTeamID).wins
            )
            // Ratings must survive exactly, or a reloaded save would play differently.
            expectEqual(
                restored.teams[0].roster.map(\.overall),
                league.teams[0].roster.map(\.overall)
            )
        }

        test("season goals and the scouting budget survive a save") {
            var league = LeagueFactory.makeDefaultLeague(seed: 210, userTeamIndex: 3, coach: .stub())
            var rng = SeededRandom(seed: 4)
            league.seasonGoals = CoachEngine.makeSeasonGoals(for: league, rng: &rng)
            league.scoutingPoints = 85
            league.draftClass = DraftClassFactory.makeClass(year: league.year + 1, rng: &rng)
            expect(!league.seasonGoals.isEmpty, "fixture should have goals")

            let id = UUID()
            _ = try store.save(league, id: id, name: "Goals")
            let restored = try store.load(id: id)

            expectEqual(
                restored.seasonGoals.count,
                league.seasonGoals.count,
                "season goals were lost on load"
            )
            expectEqual(restored.seasonGoals.first?.description, league.seasonGoals.first?.description)
            expectEqual(restored.scoutingPoints, 85, "scouting budget was lost on load")
            expectEqual(
                restored.draftClass.count,
                league.draftClass.count,
                "the draft board was lost on load"
            )
        }

        test("a save written before those fields existed still loads") {
            // Strip the newer keys the way an older save file would not have had them.
            let league = LeagueFactory.makeDefaultLeague(seed: 211, userTeamIndex: 0, coach: .stub())
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(league)
            ) as! [String: Any]
            object.removeValue(forKey: "seasonGoals")
            object.removeValue(forKey: "scoutingPoints")
            object.removeValue(forKey: "draftClass")
            object.removeValue(forKey: "hallOfFame")
            let data = try JSONSerialization.data(withJSONObject: object)

            let restored = try SaveMigrator.migrate(data: data, decoder: JSONDecoder.stable())
            expectEqual(restored.teams.count, LeagueRules.teamCount, "an older save failed to load")
            expect(restored.seasonGoals.isEmpty)
            expectEqual(restored.scoutingPoints, LeagueRules.scoutingPointsPerSeason)
        }

        test("saves are listed with readable metadata") {
            let league = LeagueFactory.makeDefaultLeague(seed: 201, userTeamIndex: 0, coach: .stub())
            let id = UUID()
            _ = try store.save(league, id: id, name: "Listed Save")
            let listed = store.list().first { $0.id == id }
            expect(listed != nil, "the save did not appear in the list")
            expectEqual(listed?.name, "Listed Save")
            expectEqual(listed?.year, league.year)
            expect(listed?.teamName.isEmpty == false, "metadata should name the team")
        }

        test("a corrupted save falls back to its backup") {
            var league = LeagueFactory.makeDefaultLeague(seed: 202, userTeamIndex: 2, coach: .stub())
            let id = UUID()
            _ = try store.save(league, id: id, name: "Backup Test")

            // Second write rotates the first into the backup slot.
            league.year += 1
            _ = try store.save(league, id: id, name: "Backup Test")

            // Corrupt the live file the way a half-finished write would.
            let liveFile = directory.appendingPathComponent("\(id.uuidString).json")
            try Data("{ not json".utf8).write(to: liveFile)

            let recovered = try store.load(id: id)
            expectEqual(recovered.year, league.year - 1, "should have recovered the previous save")
        }

        test("deleting removes every file for a save") {
            let league = LeagueFactory.makeDefaultLeague(seed: 203, userTeamIndex: 1, coach: .stub())
            let id = UUID()
            _ = try store.save(league, id: id, name: "Doomed")
            store.delete(id: id)
            expect(store.list().first { $0.id == id } == nil, "the deleted save is still listed")
        }

        test("a save from a newer version is refused rather than misread") {
            let league = LeagueFactory.makeDefaultLeague(seed: 204, userTeamIndex: 0, coach: .stub())
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(league)
            ) as! [String: Any]
            object["version"] = League.currentVersion + 5
            let data = try JSONSerialization.data(withJSONObject: object)

            var refused = false
            do {
                _ = try SaveMigrator.migrate(data: data, decoder: JSONDecoder.stable())
            } catch {
                refused = true
            }
            expect(refused, "a future-version save should not be decoded blindly")
        }
    }
}
