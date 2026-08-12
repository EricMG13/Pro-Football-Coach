import Foundation
import FootballSimCore

// An event that falls out of the bounded hot journal used to leave nothing behind but a number.
// `docs/roadmap/06` makes it an M7 exit condition that important past events can be surfaced
// without scanning the entire save, and a counter cannot surface anything. The archive keeps one
// digest per season: how many of that season's events were archived, and the bodies of the ones
// worth remembering.

func runHistoryArchiveTests() {
    suite("History archive: the season digest") {
        test("an ordinary event is counted and its body is not kept") {
            var digest = SeasonHistoryDigest(season: 3)
            digest.record(archiveEvent(sequence: 0, season: 3), isNotable: false)
            expectEqual(digest.archivedCount, 1)
            expect(digest.notableEvents.isEmpty)
        }

        test("a notable event is counted and its body is kept") {
            var digest = SeasonHistoryDigest(season: 3)
            let event = archiveEvent(sequence: 0, season: 3)
            digest.record(event, isNotable: true)
            expectEqual(digest.archivedCount, 1)
            expectEqual(digest.notableEvents, [event])
        }

        test("bodies stop at the bound while the count keeps rising") {
            // The count is the volume signal and the bodies are the bounded sample. A season with
            // ten thousand archived events must still say so.
            var digest = SeasonHistoryDigest(season: 3)
            let total = SeasonHistoryDigest.maximumNotableEvents + 40
            for sequence in 0..<total {
                digest.record(archiveEvent(sequence: sequence, season: 3), isNotable: true)
            }
            expectEqual(digest.archivedCount, total)
            expectEqual(digest.notableEvents.count, SeasonHistoryDigest.maximumNotableEvents)
        }

        test("the bodies kept are the earliest, so a finished season stops changing") {
            var digest = SeasonHistoryDigest(season: 3)
            let first = archiveEvent(sequence: 0, season: 3)
            for sequence in 0...SeasonHistoryDigest.maximumNotableEvents {
                digest.record(archiveEvent(sequence: sequence, season: 3), isNotable: true)
            }
            expectEqual(digest.notableEvents.first, first,
                        "a later event displaced an earlier one, so history is not stable")
        }

        test("a digest round-trips through the save envelope") {
            var digest = SeasonHistoryDigest(season: 3)
            digest.record(archiveEvent(sequence: 0, season: 3), isNotable: true)
            digest.record(archiveEvent(sequence: 1, season: 3), isNotable: false)
            let restored = try SaveEnvelope.decode(
                SeasonHistoryDigest.self,
                from: SaveEnvelope.encode(digest)
            )
            expectEqual(restored, digest)
        }
    }

    suite("History archive: hostile digests are refused") {
        test("more kept bodies than the bound is refused") {
            let events = (0...SeasonHistoryDigest.maximumNotableEvents).map {
                archiveEvent(sequence: $0, season: 3)
            }
            expect(archiveDigestIsRefused(season: 3, archivedCount: events.count, events: events),
                   "a digest over its notable bound decoded")
        }

        test("more kept bodies than archived events is refused") {
            // A kept body is by definition an archived event, so the count can never be the smaller
            // of the two. This is the accounting a hand-edited save would break first.
            let events = [archiveEvent(sequence: 0, season: 3), archiveEvent(sequence: 1, season: 3)]
            expect(archiveDigestIsRefused(season: 3, archivedCount: 1, events: events),
                   "a digest holding more bodies than it counted decoded")
        }

        test("a body from another season is refused") {
            expect(
                archiveDigestIsRefused(
                    season: 3,
                    archivedCount: 1,
                    events: [archiveEvent(sequence: 0, season: 4)]
                ),
                "a digest holding another season's event decoded"
            )
        }

        test("a negative season or count is refused") {
            expect(archiveDigestIsRefused(season: -1, archivedCount: 0, events: []))
            expect(archiveDigestIsRefused(season: 3, archivedCount: -1, events: []))
        }

        test("out-of-order bodies are refused") {
            expect(
                archiveDigestIsRefused(
                    season: 3,
                    archivedCount: 2,
                    events: [archiveEvent(sequence: 5, season: 3), archiveEvent(sequence: 1, season: 3)]
                ),
                "a digest whose bodies run backwards decoded"
            )
        }
    }
}

private func archiveEvent(sequence: Int, season: Int) -> DomainEvent {
    DomainEvent(
        id: DomainEvent.deterministicID(rootSeed: 90_701, sequence: sequence),
        sequence: sequence,
        occurredAt: CalendarState(season: season, week: 1),
        payload: .integrityChecked(issueCount: 0)
    )
}

/// Encodes a digest's fields directly as JSON and asserts the decoder refuses them.
///
/// Built as JSON rather than by mutating a valid digest, because every one of these shapes is
/// unreachable through the API — which is the point. The hostile input is a hand-edited or
/// corrupted save, and the decoder is the only thing standing in front of it.
private func archiveDigestIsRefused(
    season: Int,
    archivedCount: Int,
    events: [DomainEvent]
) -> Bool {
    let object: [String: Any] = [
        "season": season,
        "archivedCount": archivedCount,
        "notableEvents": (try? JSONSerialization.jsonObject(
            with: JSONEncoder().encode(events)
        )) ?? [],
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: object) else { return false }
    return (try? JSONDecoder().decode(SeasonHistoryDigest.self, from: data)) == nil
}
