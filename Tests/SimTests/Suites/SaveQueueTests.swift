import Foundation
import FootballSimCore
import ProFootballCoachUI

func runSaveQueueTests() {
    suite("SaveQueue") {

        testAsync("a burst of writes coalesces and the last one wins") {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-savequeue-\(UUID().uuidString)")
            let store = SaveStore(directory: dir)
            let queue = SaveQueue(store: store)
            let id = UUID()

            var league = LeagueFactory.makeDefaultLeague(seed: 99, userTeamIndex: 0, coach: .stub())
            for year in 2026...2030 {
                league.year = year
                await queue.enqueue(.init(league: league, id: id, name: "Burst"))
            }
            await queue.flush()

            let reloaded = try store.load(id: id)
            expectEqual(reloaded.year, 2030, "the newest snapshot must be the one on disk")
            let writes = await queue.writeCount
            expect(writes >= 1, "at least one write must happen")
            expect(writes <= 5, "no more writes than enqueues")
            let failure = await queue.takeError()
            expect(failure == nil, "a clean burst must not record an error, got \(failure ?? "")")

            try? FileManager.default.removeItem(at: dir)
        }

        testAsync("flush returns immediately when nothing is queued") {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-savequeue-\(UUID().uuidString)")
            let queue = SaveQueue(store: SaveStore(directory: dir))
            await queue.flush()
            let writes = await queue.writeCount
            expectEqual(writes, 0, "an idle queue writes nothing")
            try? FileManager.default.removeItem(at: dir)
        }

        testAsync("a write failure is recorded and taking it clears it") {
            // A path that cannot be created forces the write to throw.
            let store = SaveStore(directory: URL(fileURLWithPath: "/dev/null/nope"))
            let queue = SaveQueue(store: store)
            let league = LeagueFactory.makeDefaultLeague(seed: 7, userTeamIndex: 0, coach: .stub())
            await queue.enqueue(.init(league: league, id: UUID(), name: "Doomed"))
            await queue.flush()

            let first = await queue.takeError()
            expect(first != nil, "a failed write must record an error")
            let second = await queue.takeError()
            expect(second == nil, "taking the error must clear it")
        }
    }
}
