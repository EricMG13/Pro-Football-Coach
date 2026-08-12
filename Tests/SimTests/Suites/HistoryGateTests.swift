import Foundation
import FootballSimCore

// The M7 exit gate from `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`:
//
//   - 30+ season history remains useful and performant
//   - important past events can be surfaced without scanning entire save
//
// Both clauses are measured here rather than asserted in prose. The second one is the reason the
// archive exists: before it, the only record of an event that left the hot journal was a number, and
// a number cannot be surfaced. `docs/roadmap/05` §2 names the measurements — encoded size and load
// time at 1, 5, 20 and 50 seasons — and this takes them at 1, 5, 20 and 30, which is the gate's own
// horizon.
//
// Slow by construction, so it has its own flag and is not in the default run. `--m2-soak` and
// `--m3-soak` set that precedent.

func runHistoryGateTests() {
    let requested = ProcessInfo.processInfo.environment["M7_GATE_SEASONS"]
        .flatMap(Int.init) ?? 30
    precondition(requested >= 1, "The M7 history gate needs at least one season.")

    suite("M7 gate: thirty-season history") {
        test("history stays bounded, contiguous and surfacable across \(requested) seasons") {
            var state = GameState.bootstrap(seed: 70_901)
            var checkpoints: [(season: Int, bytes: Int, encodeSeconds: Double)] = []
            let measured = Set([1, min(5, requested), min(20, requested), requested])
            var weekDurations: [Double] = []

            for targetSeason in 1...requested {
                while state.calendar.season < targetSeason {
                    let started = Date.timeIntervalSinceReferenceDate
                    state = try WorldScheduler.advanceWeek(state).state
                    weekDurations.append(Date.timeIntervalSinceReferenceDate - started)
                }
                guard measured.contains(targetSeason) else { continue }
                let encodeStarted = Date.timeIntervalSinceReferenceDate
                let data = try SaveEnvelope.encode(state)
                let encodeSeconds = Date.timeIntervalSinceReferenceDate - encodeStarted
                checkpoints.append((targetSeason, data.count, encodeSeconds))
            }

            let archive = state.history.archive

            // Clause one: bounded and ordered, so thirty seasons of history is a fixed cost rather
            // than a growing one.
            expect(archive.count <= DomainEventLedger.maximumArchivedSeasons,
                   "the archive holds \(archive.count) seasons, over its bound")
            expectEqual(archive.map(\.season), archive.map(\.season).sorted(),
                        "the archive is not in season order")
            expectEqual(Set(archive.map(\.season)).count, archive.count,
                        "the archive repeats a season")
            if let first = archive.first?.season, let last = archive.last?.season {
                expectEqual(last - first + 1, archive.count,
                            "the retained seasons are not contiguous, so a season vanished")
            }

            // Clause two: a past season can be surfaced from its own digest. Reading the digest must
            // not depend on the hot journal, which by now holds only the most recent weeks.
            let hotSeasons = Set(state.history.recent.map(\.occurredAt.season))
            let archivedOnly = archive.map(\.season).filter { !hotSeasons.contains($0) }
            expect(!archivedOnly.isEmpty,
                   "no season has left the hot journal, so this gate proved nothing")
            for season in archivedOnly {
                let digest = state.history.digest(forSeason: season)
                expect(digest != nil, "season \(season) cannot be surfaced at all")
                expect((digest?.archivedCount ?? 0) > 0,
                       "season \(season) surfaced as an empty row")
            }

            // A season of a target-scale world produces championships, signings and departures. If a
            // retained season carries no notable body, the notability rule is wrong rather than the
            // season being quiet.
            let seasonsWithoutBodies = archive.filter { $0.notableEvents.isEmpty }.map(\.season)
            expect(seasonsWithoutBodies.isEmpty,
                   "retained seasons carry no notable event: "
                       + seasonsWithoutBodies.prefix(6).map(String.init).joined(separator: ", "))

            expect(WorldIntegrity.check(state).isValid,
                   "the root is not valid after \(requested) seasons")

            // Printed, not just asserted: `docs/roadmap/05` §2 asks for these numbers and the number
            // is the deliverable. A gate that only says "passed" hands the next reader nothing.
            let sizes = checkpoints
                .map { "s\($0.season)=\($0.bytes)B/\(String(format: "%.3f", $0.encodeSeconds))s" }
                .joined(separator: " ")
            let totalWeeks = weekDurations.count
            let weekTotal = weekDurations.reduce(0, +)
            print("""
            M7 history gate: seasons=\(requested) weeks=\(totalWeeks) \
            weekMeanMs=\(String(format: "%.2f", totalWeeks == 0 ? 0 : weekTotal / Double(totalWeeks) * 1000)) \
            archivedSeasons=\(archive.count) archivedEvents=\(state.history.archivedCount) \
            hotEvents=\(state.history.recent.count) \
            notableBodies=\(archive.reduce(0) { $0 + $1.notableEvents.count }) \
            save: \(sizes)
            """)
        }
    }
}
