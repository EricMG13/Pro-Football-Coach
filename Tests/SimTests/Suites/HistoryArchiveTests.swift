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

    runHistoryArchiveLedgerTests()

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

private func runHistoryArchiveLedgerTests() {
    suite("History archive: notability") {
        test("a season ending is notable and a weekly integrity check is not") {
            expect(DomainEventPayload.seasonCompleted(
                season: 3,
                collegeChampionID: UUID(),
                proChampionID: UUID()
            ).isNotable)
            expect(!DomainEventPayload.integrityChecked(issueCount: 0).isNotable)
            expect(!DomainEventPayload.weekAdvanced(
                completed: CalendarState(season: 3, week: 1),
                next: CalendarState(season: 3, week: 2)
            ).isNotable)
        }
    }

    suite("History archive: the ledger folds overflow in") {
        test("an overflowing event lands in the digest for its own season") {
            var ledger = DomainEventLedger(retentionLimit: 1)
            expect(ledger.append(contentsOf: [
                archiveEvent(sequence: 0, season: 3),
                archiveEvent(sequence: 1, season: 3),
                archiveEvent(sequence: 2, season: 4),
            ]))
            expectEqual(ledger.digest(forSeason: 3)?.archivedCount, 2)
            expect(ledger.digest(forSeason: 4) == nil,
                   "the season still inside the window must not be archived yet")
            expectEqual(ledger.recent.count, 1)
        }

        test("a late append credits the old event to its own season, not the current one") {
            // The trap this exists to catch: crediting whatever season pushed an event out would
            // put 2027's events in 2031's digest and make every retrospective wrong.
            var ledger = DomainEventLedger(retentionLimit: 1)
            expect(ledger.append(archiveEvent(sequence: 0, season: 3)))
            expect(ledger.append(archiveEvent(sequence: 1, season: 9)))
            expectEqual(ledger.digest(forSeason: 3)?.archivedCount, 1)
            expect(ledger.digest(forSeason: 9) == nil)
        }

        test("the archived count always equals the sum of the retained digests") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            for sequence in 0..<60 {
                expect(ledger.append(archiveEvent(sequence: sequence, season: sequence / 10)))
            }
            expectEqual(ledger.archive.reduce(0) { $0 + $1.archivedCount }, ledger.archivedCount)
            expectEqual(ledger.archivedCount + ledger.recent.count, 60)
        }

        test("notable overflow keeps a body and ordinary overflow does not") {
            var ledger = DomainEventLedger(retentionLimit: 1)
            expect(ledger.append(contentsOf: [
                archiveNotableEvent(sequence: 0, season: 3),
                archiveEvent(sequence: 1, season: 3),
                archiveEvent(sequence: 2, season: 3),
            ]))
            let digest = ledger.digest(forSeason: 3)
            expectEqual(digest?.archivedCount, 2)
            expectEqual(digest?.notableEvents.count, 1)
            expectEqual(digest?.notableEvents.first?.sequence, 0)
        }

        test("the archive stays ascending and bounded, dropping the oldest season") {
            var ledger = DomainEventLedger(retentionLimit: 1)
            let seasons = DomainEventLedger.maximumArchivedSeasons + 5
            for season in 0..<seasons {
                expect(ledger.append(archiveEvent(sequence: season, season: season)))
            }
            expectEqual(ledger.archive.count, DomainEventLedger.maximumArchivedSeasons)
            expectEqual(ledger.archive.map(\.season), ledger.archive.map(\.season).sorted())
            expect(ledger.digest(forSeason: 0) == nil, "the oldest season must be the one dropped")
            expect(ledger.digest(forSeason: seasons - 2) != nil)
            // The dropped seasons still happened, so the honest total keeps counting them even
            // though their digests are gone.
            expectEqual(ledger.archivedCount, seasons - 1)
            expect(ledger.archivedCount > ledger.archive.reduce(0) { $0 + $1.archivedCount })
        }

        test("two identical append sequences produce identical archives") {
            func build() -> DomainEventLedger {
                var ledger = DomainEventLedger(retentionLimit: 3)
                for sequence in 0..<40 {
                    _ = ledger.append(
                        sequence.isMultiple(of: 7)
                            ? archiveNotableEvent(sequence: sequence, season: sequence / 8)
                            : archiveEvent(sequence: sequence, season: sequence / 8)
                    )
                }
                return ledger
            }
            expectEqual(build(), build())
        }

        test("a ledger with an archive round-trips through the save envelope") {
            var ledger = DomainEventLedger(retentionLimit: 2)
            for sequence in 0..<30 {
                _ = ledger.append(archiveNotableEvent(sequence: sequence, season: sequence / 6))
            }
            let restored = try SaveEnvelope.decode(
                DomainEventLedger.self,
                from: SaveEnvelope.encode(ledger)
            )
            expectEqual(restored, ledger)
            expect(!restored.archive.isEmpty)
        }
    }
}

private func archiveNotableEvent(sequence: Int, season: Int) -> DomainEvent {
    DomainEvent(
        id: DomainEvent.deterministicID(rootSeed: 90_702, sequence: sequence),
        sequence: sequence,
        occurredAt: CalendarState(season: season, week: 1),
        payload: .seasonCompleted(
            season: season,
            collegeChampionID: UUID(uuidString: "00000000-0000-4000-8000-00000000000a")!,
            proChampionID: UUID(uuidString: "00000000-0000-4000-8000-00000000000b")!
        )
    )
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
