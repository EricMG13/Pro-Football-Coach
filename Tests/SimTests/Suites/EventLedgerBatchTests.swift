import Foundation
import FootballSimCore

func runEventLedgerBatchTests() {
    suite("Atomic domain-event batches") {
        test("an empty batch is an exact no-op") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            expect(ledger.append(ledgerEvent(sequence: 0)))
            let before = try JSONEncoder.stable().encode(ledger)

            expect(ledger.append(contentsOf: []))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("batch and sequential append are byte-identical at and across hot retention") {
            let retention = DomainEventLedger.defaultRetentionLimit
            let overflow = 17
            let events = ledgerEvents(count: retention + overflow)
            let boundaryEvents = Array(events.prefix(retention))
            let overflowEvents = Array(events.dropFirst(retention))
            let clock = ContinuousClock()

            var sequential = DomainEventLedger(retentionLimit: retention)
            let sequentialStarted = clock.now
            var everySequentialAppendSucceeded = true
            for event in boundaryEvents {
                if !sequential.append(event) { everySequentialAppendSucceeded = false }
            }
            let sequentialAtBoundary = sequential
            for event in overflowEvents {
                if !sequential.append(event) { everySequentialAppendSucceeded = false }
            }
            let sequentialElapsed = sequentialStarted.duration(to: clock.now)

            var batched = DomainEventLedger(retentionLimit: retention)
            let batchedStarted = clock.now
            let boundaryAccepted = batched.append(contentsOf: boundaryEvents)
            let batchedAtBoundary = batched
            let overflowAccepted = batched.append(contentsOf: overflowEvents)
            let batchedElapsed = batchedStarted.duration(to: clock.now)

            expect(everySequentialAppendSucceeded)
            expect(boundaryAccepted && overflowAccepted)
            expectEqual(sequentialAtBoundary, batchedAtBoundary)
            expectEqual(
                try JSONEncoder.stable().encode(sequentialAtBoundary),
                try JSONEncoder.stable().encode(batchedAtBoundary)
            )
            expectEqual(batchedAtBoundary.recent.count, retention)
            expectEqual(batchedAtBoundary.archivedCount, 0)

            expectEqual(sequential, batched)
            let sequentialBytes = try JSONEncoder.stable().encode(sequential)
            let batchedBytes = try JSONEncoder.stable().encode(batched)
            expectEqual(sequentialBytes, batchedBytes)
            expectEqual(batched.recent.count, retention)
            expectEqual(batched.recent.first?.sequence, overflow)
            expectEqual(batched.recent.last?.sequence, retention + overflow - 1)
            expectEqual(batched.archivedCount, overflow)
            expectEqual(batched.lastSequence, retention + overflow - 1)
            expectEqual(batched.totalCount, retention + overflow)
            expectEqual(
                try JSONDecoder.stable().decode(DomainEventLedger.self, from: batchedBytes),
                batched
            )
            print(
                "Event-ledger observation: \(events.count) events; "
                    + "sequential \(sequentialElapsed), batch \(batchedElapsed)"
            )
        }

        test("a retained event ID collision rejects the whole batch") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            let retained = ledgerEvent(sequence: 0)
            expect(ledger.append(retained))
            let before = try JSONEncoder.stable().encode(ledger)
            let batch = [
                ledgerEvent(sequence: 1),
                ledgerEvent(sequence: 2, id: retained.id),
            ]

            expect(!ledger.append(contentsOf: batch))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("an ID repeated inside a batch rejects the whole batch") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            let repeatedID = ledgerEventID(44)
            let before = try JSONEncoder.stable().encode(ledger)
            let batch = [
                ledgerEvent(sequence: 0, id: repeatedID),
                ledgerEvent(sequence: 1, id: repeatedID),
            ]

            expect(!ledger.append(contentsOf: batch))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("a non-increasing middle sequence rejects the whole batch") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            let before = try JSONEncoder.stable().encode(ledger)
            let batch = [
                ledgerEvent(sequence: 0),
                ledgerEvent(sequence: 2),
                ledgerEvent(sequence: 1),
            ]

            expect(!ledger.append(contentsOf: batch))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("a middle calendar regression rejects the whole batch") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            let before = try JSONEncoder.stable().encode(ledger)
            let batch = [
                ledgerEvent(sequence: 0, occurredAt: CalendarState(season: 2, week: 3)),
                ledgerEvent(sequence: 1, occurredAt: CalendarState(season: 2, week: 4)),
                ledgerEvent(sequence: 2, occurredAt: CalendarState(season: 2, week: 3)),
            ]

            expect(!ledger.append(contentsOf: batch))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("a malformed middle event rejects the whole batch") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            let before = try JSONEncoder.stable().encode(ledger)
            let batch = [
                ledgerEvent(sequence: 0),
                DomainEvent(
                    id: ledgerEventID(45),
                    sequence: -1,
                    occurredAt: CalendarState(),
                    payload: .integrityChecked(issueCount: 0)
                ),
                ledgerEvent(sequence: 1),
            ]

            expect(!ledger.append(contentsOf: batch))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("archive accounting overflow rejects the whole batch") {
            var seed = DomainEventLedger(retentionLimit: 1)
            expect(seed.append(ledgerEvent(sequence: 0)))
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(seed)
            ) as! [String: Any]
            object["archivedCount"] = Int.max - 1
            var ledger = try JSONDecoder.stable().decode(
                DomainEventLedger.self,
                from: JSONSerialization.data(withJSONObject: object)
            )
            let before = try JSONEncoder.stable().encode(ledger)

            expectEqual(ledger.totalCount, Int.max)
            expect(!ledger.append(contentsOf: [ledgerEvent(sequence: 1)]))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)
        }

        test("decoding rejects archive accounting whose represented total overflows") {
            var seed = DomainEventLedger(retentionLimit: 1)
            expect(seed.append(ledgerEvent(sequence: 0)))
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(seed)
            ) as! [String: Any]
            object["archivedCount"] = Int.max

            do {
                _ = try JSONDecoder.stable().decode(
                    DomainEventLedger.self,
                    from: JSONSerialization.data(withJSONObject: object)
                )
                expect(false, "a ledger whose exact total overflows decoded")
            } catch {
                expect(true)
            }
        }

        test("maximum persisted sequence exposes no overflowing reservation") {
            var ledger = DomainEventLedger(retentionLimit: 2)
            expect(ledger.append(ledgerEvent(sequence: Int.max)))
            let bytes = try JSONEncoder.stable().encode(ledger)
            ledger = try JSONDecoder.stable().decode(DomainEventLedger.self, from: bytes)
            let before = try JSONEncoder.stable().encode(ledger)

            expectEqual(ledger.nextSequence, Int.max)
            expectEqual(ledger.firstSequence(forAppending: 1), nil)
            expect(!ledger.append(contentsOf: [ledgerEvent(sequence: Int.max)]))

            expectEqual(try JSONEncoder.stable().encode(ledger), before)

            var nearMaximum = DomainEventLedger(retentionLimit: 2)
            expect(nearMaximum.append(ledgerEvent(sequence: Int.max - 1)))
            expectEqual(nearMaximum.firstSequence(forAppending: 1), Int.max)
            expectEqual(nearMaximum.firstSequence(forAppending: 2), nil)
        }
    }

    suite("Scheduler event batches") {
        test("a weekly transition matches a sequential history reference exactly") {
            let before = GameState.bootstrap(seed: 74_101)
            let first = try WorldScheduler.advanceWeek(before)
            var sequentialHistory = before.history
            var sequentialAppendSucceeded = true
            for event in first.emittedEvents {
                if !sequentialHistory.append(event) { sequentialAppendSucceeded = false }
            }

            expect(sequentialAppendSucceeded)
            expectEqual(sequentialHistory, first.state.history)
            expectEqual(
                try JSONEncoder.stable().encode(sequentialHistory),
                try JSONEncoder.stable().encode(first.state.history)
            )
            var sequentialReferenceState = first.state
            sequentialReferenceState.history = sequentialHistory
            expectEqual(
                try SaveEnvelope.encode(sequentialReferenceState),
                try SaveEnvelope.encode(first.state)
            )
            expectEqual(first.snapshot.emittedEventIDs, first.emittedEvents.map(\.id))
            expect(first.emittedEvents.enumerated().allSatisfy { offset, event in
                event.sequence == before.history.nextSequence + offset
                    && event.id == DomainEvent.deterministicID(
                        rootSeed: before.league.seed,
                        sequence: event.sequence
                    )
            })
            guard let finalEvent = first.emittedEvents.last else {
                expect(false, "the scheduler emitted no week snapshot")
                return
            }
            expectEqual(finalEvent.occurredAt, first.snapshot.next)
            if case let .weekAdvanced(completed, next) = finalEvent.payload {
                expectEqual(completed, first.snapshot.completed)
                expectEqual(next, first.snapshot.next)
            } else {
                expect(false, "the scheduler's final event was not the week snapshot")
            }

            let encoded = try JSONEncoder.stable().encode(first)
            expectEqual(
                try JSONDecoder.stable().decode(WorldTransition.self, from: encoded),
                first
            )
            let second = try WorldScheduler.advanceWeek(GameState.bootstrap(seed: 74_101))
            expectEqual(try JSONEncoder.stable().encode(second), encoded)
        }

        test("an exhausted event sequence makes scheduler materialization fail cleanly") {
            var state = GameState.bootstrap(seed: 74_102)
            var exhausted = DomainEventLedger(retentionLimit: 2)
            expect(exhausted.append(ledgerEvent(
                sequence: Int.max,
                occurredAt: state.calendar
            )))
            state.history = exhausted

            do {
                _ = try WorldScheduler.advanceWeek(state)
                expect(false, "the scheduler advanced past an exhausted event sequence")
            } catch let error as WorldSchedulerError {
                expectEqual(error, .eventAppendFailed)
            }
        }
    }
}

private func ledgerEvents(count: Int) -> [DomainEvent] {
    (0..<count).map { ledgerEvent(sequence: $0) }
}

private func ledgerEvent(
    sequence: Int,
    id: UUID? = nil,
    occurredAt: CalendarState = CalendarState()
) -> DomainEvent {
    DomainEvent(
        id: id ?? ledgerEventID(sequence),
        sequence: sequence,
        occurredAt: occurredAt,
        payload: .integrityChecked(issueCount: 0)
    )
}

private func ledgerEventID(_ ordinal: Int) -> UUID {
    let bits = UInt64(bitPattern: Int64(ordinal))
    return UUID(uuidString: String(
        format: "00000000-0000-4000-8000-%012llX",
        bits & 0xFFFF_FFFF_FFFF
    ))!
}
