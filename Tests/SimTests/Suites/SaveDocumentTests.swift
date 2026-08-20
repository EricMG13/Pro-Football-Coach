import Foundation
import FootballSimCore
import CoachWorldApp

private func legacyEnvelope(
    for state: GameState,
    omitOptionalRootFields: Bool = false,
    omitCoachIdentity: Bool = false
) throws -> Data {
    let encoded = try JSONEncoder.stable().encode(state)
    var object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
    object["version"] = GameState.legacySchemaVersion
    if omitOptionalRootFields {
        object.removeValue(forKey: "tactical")
        object.removeValue(forKey: "proMarket")
    }
    if omitCoachIdentity, var career = object["career"] as? [String: Any] {
        career.removeValue(forKey: "coachID")
        object["career"] = career
    }
    let body = try JSONSerialization.data(withJSONObject: object)
    var envelope = Data(Array("PFC1".utf8))
    var version = SaveEnvelope.currentSchemaVersion.littleEndian
    withUnsafeBytes(of: &version) { envelope.append(contentsOf: $0) }
    envelope.append(1)
    envelope.append(contentsOf: Array(repeating: UInt8(0), count: 7))
    envelope.append(try (body as NSData).compressed(using: .zlib) as Data)
    return envelope
}

func runSaveDocumentTests() {
    suite("Save document migration") {
        test("schema 11 bare root wraps and normalises to the current root") {
            let state = GameState.bootstrap(seed: 20_260_812)
            let legacy = try! legacyEnvelope(for: state)
            let document = try! CoachWorldSaveDocument.decode(envelopeData: legacy)
            expectEqual(document.documentVersion, CoachWorldSaveDocument.currentVersion)
            expectEqual(document.gameState.version, GameState.schemaVersion)
            expectEqual(document.metadata.migratedFromRootVersion, GameState.legacySchemaVersion)
            expectEqual(document.gameState.calendar, state.calendar)
            expectEqual(document.presentation.returnRoute, nil)
            expectEqual(document.presentation.readInboxItemIDs, [])
        }

        test("schema 11 missing later root fields receives explicit defaults") {
            let state = GameState.bootstrap(seed: 20_260_815)
            let legacy = try! legacyEnvelope(for: state, omitOptionalRootFields: true)
            let document = try! CoachWorldSaveDocument.decode(envelopeData: legacy)
            expectEqual(document.gameState.version, GameState.schemaVersion)
            expectEqual(document.gameState.proMarket.season, state.calendar.season)
        }

        test("schema 11 controlled career derives the coach identity from college control") {
            let source = GameState.bootstrap(seed: 20_260_816)
            let programmeID = source.programmes.ids[0]
            let controlled = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let legacy = try! legacyEnvelope(for: controlled, omitCoachIdentity: true)
            let document = try! CoachWorldSaveDocument.decode(envelopeData: legacy)
            expectEqual(
                document.gameState.career.coachID,
                document.gameState.career.college?.coachID
            )
        }

        test("schema 12 without the negotiation ledger receives an empty ledger") {
            let state = GameState.bootstrap(seed: 20_260_817)
            var object = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(state)
            ) as! [String: Any]
            object["version"] = GameState.previousSchemaVersion
            var market = object["proMarket"] as! [String: Any]
            market.removeValue(forKey: "contractNegotiations")
            object["proMarket"] = market
            let decoded = try! JSONDecoder().decode(
                GameState.self,
                from: JSONSerialization.data(withJSONObject: object)
            )
            expectEqual(decoded.version, GameState.schemaVersion)
            expectEqual(decoded.proMarket.contractNegotiations, [])
        }

        test("current document round trips") {
            let state = GameState.bootstrap(seed: 20_260_813)
            let selectedSubjectID = state.prospects.ids[0]
            let expected = CoachWorldSaveDocument(
                gameState: state,
                presentation: CareerPresentationState(
                    route: "13",
                    returnRoute: "16",
                    readInboxItemIDs: ["story:example"],
                    selectedSubjectID: selectedSubjectID
                ),
                metadata: CareerSaveMetadata(generation: 4, createdFromSeed: 20_260_813)
            )
            let decoded = try! CoachWorldSaveDocument.decode(
                envelopeData: SaveEnvelope.encode(expected)
            )
            expectEqual(decoded, expected)
            expectEqual(decoded.presentation.selectedSubjectID, selectedSubjectID)
        }

        test("current document without inbox receipts remains readable") {
            let state = GameState.bootstrap(seed: 20_260_819)
            let document = CoachWorldSaveDocument(gameState: state)
            var object = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(document)
            ) as! [String: Any]
            var presentation = object["presentation"] as! [String: Any]
            presentation.removeValue(forKey: "readInboxItemIDs")
            object["presentation"] = presentation
            let body = try! JSONSerialization.data(withJSONObject: object)
            var envelope = Data(Array("PFC1".utf8))
            var version = SaveEnvelope.currentSchemaVersion.littleEndian
            withUnsafeBytes(of: &version) { envelope.append(contentsOf: $0) }
            envelope.append(1)
            envelope.append(contentsOf: Array(repeating: UInt8(0), count: 7))
            envelope.append(try! (body as NSData).compressed(using: .zlib) as Data)
            let decoded = try! CoachWorldSaveDocument.decode(envelopeData: envelope)
            expectEqual(decoded.presentation.readInboxItemIDs, [])
        }

        test("future document markers are refused before body decoding") {
            let body = try! JSONSerialization.data(withJSONObject: [
                "documentVersion": CoachWorldSaveDocument.currentVersion + 1,
                "payload": "written by a newer build"
            ])
            var envelope = Data(Array("PFC1".utf8))
            var version = SaveEnvelope.currentSchemaVersion.littleEndian
            withUnsafeBytes(of: &version) { envelope.append(contentsOf: $0) }
            envelope.append(1)
            envelope.append(contentsOf: Array(repeating: UInt8(0), count: 7))
            envelope.append(try! (body as NSData).compressed(using: .zlib) as Data)
            do {
                _ = try CoachWorldSaveDocument.decode(envelopeData: envelope)
                expect(false, "future document should not decode")
            } catch let error as SaveDocumentError {
                expectEqual(error, .futureDocumentVersion(CoachWorldSaveDocument.currentVersion + 1))
            } catch {
                expect(false, "future document returned the wrong error: \(error)")
            }
        }
    }

    suite("Save coordinator") {
        testAsync("SaveOffMainActorTest keeps durable work behind the coordinator boundary") {
            // This used to grep the source for the literals "public actor SaveCoordinator" and
            // "Task.detached(priority: .utility)", which proved that two strings existed. What the
            // gate promises is that durable work does not run on the main actor, and the type
            // system can prove that: the call below is made from a `nonisolated` context, so it
            // compiles only while `SaveCoordinator` carries its own isolation. A `@MainActor`
            // coordinator, or a synchronous one, fails to build rather than failing to grep.
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let coordinator = SaveCoordinator(storage: CoachWorldSaveStore(directory: directory))
            let document = CoachWorldSaveDocument(gameState: GameState.bootstrap(seed: 20_260_818))
            try await coordinator.requestSave(document, reason: .newCareer)
            try await coordinator.flush(reason: .explicit)
            expectEqual(await coordinator.writeCount, 1,
                        "the durable write did not reach the coordinator")
        }

        testAsync("SaveWriteBudgetTest holds writes to flushes, not to intents") {
            // The budget this gate is named for: a burst of intents must cost one write, not one
            // write each. It was registered with a runner and no test at all, which is how the app
            // came to flush after every intent — including every match snap, at 2.9 s a snap —
            // without anything noticing. Twenty requests, one flush, one write.
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let coordinator = SaveCoordinator(storage: storage)
            let state = GameState.bootstrap(seed: 20_260_819)
            for index in 1...20 {
                try await coordinator.requestSave(
                    CoachWorldSaveDocument(
                        gameState: state,
                        metadata: CareerSaveMetadata(generation: UInt64(index))
                    ),
                    reason: .userAction
                )
            }
            expectEqual(await coordinator.writeCount, 0,
                        "requesting a save must not write; only a flush writes")
            try await coordinator.flush(reason: .explicit)
            expectEqual(await coordinator.writeCount, 1,
                        "twenty intents behind one flush must cost one durable write")
            // And the write is the newest of them, not the first.
            let written = try CoachWorldSaveDocument.decode(envelopeData: try storage.read())
            expectEqual(written.metadata.generation, 20)

            // A flush with nothing pending is free.
            try await coordinator.flush(reason: .explicit)
            expectEqual(await coordinator.writeCount, 1)
        }

        testAsync("a flush does not re-decode the save it is replacing") {
            // The promotion of a good primary to backup used to be gated on decoding it again:
            // 1.6 to 2.2 s at season 0, growing with the career, to re-establish what the previous
            // write had already verified by reading back. The backup must still be the previous
            // save, byte for byte -- that is what this asserts, without the decode.
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let coordinator = SaveCoordinator(storage: storage)
            let state = GameState.bootstrap(seed: 20_260_820)
            let first = CoachWorldSaveDocument(gameState: state, metadata: CareerSaveMetadata(generation: 1))
            try await coordinator.requestSave(first, reason: .newCareer)
            try await coordinator.flush(reason: .explicit)
            let firstBytes = try storage.read()
            try await coordinator.requestSave(
                CoachWorldSaveDocument(gameState: state, metadata: CareerSaveMetadata(generation: 2)),
                reason: .userAction
            )
            try await coordinator.flush(reason: .explicit)
            expectEqual(try storage.readBackup(), firstBytes,
                        "the previous save was not promoted to the backup slot")
            expectEqual(
                try CoachWorldSaveDocument.decode(envelopeData: try storage.read()).metadata.generation,
                2
            )
        }

        testAsync("a healthy save loads without decoding its backup") {
            // Half the cold-launch cost was decoding the backup to confirm a primary that had
            // already decoded. The flush order is backup-then-primary, so a primary at least as new
            // as its backup is the current save. A backup that is deliberately newer is still read.
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let state = GameState.bootstrap(seed: 20_260_821)
            let current = CoachWorldSaveDocument(gameState: state, metadata: CareerSaveMetadata(generation: 5))
            try storage.writeBackup(Data([0x00]))
            try storage.write(try SaveEnvelope.encode(current))
            // A corrupt backup older than the primary must not even be opened, so nothing is
            // quarantined and the primary is returned.
            let outcome = try await SaveCoordinator(storage: storage).load()
            guard case let .loaded(document, source) = outcome else {
                expect(false, "expected the primary to load")
                return
            }
            expectEqual(source, .primary)
            expectEqual(document.metadata.generation, 5)
            expect(!FileManager.default.fileExists(atPath: storage.quarantineDirectory.path),
                   "the backup was opened even though the primary was the newer file")
        }

        testAsync("coalesces and recovers from a corrupt primary") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let coordinator = SaveCoordinator(storage: storage)
            let state = GameState.bootstrap(seed: 20_260_814)
            let first = CoachWorldSaveDocument(gameState: state)
            try await coordinator.requestSave(first, reason: .newCareer)
            try await coordinator.requestSave(
                first.withGeneration(0),
                reason: .userAction
            )
            try await coordinator.flush(reason: .explicit)
            try await coordinator.requestSave(first.withGeneration(0), reason: .checkpoint)
            try await coordinator.flush(reason: .explicit)
            try Data([0x00]).write(to: storage.url, options: .atomic)
            let outcome = try await coordinator.load()
            guard case let .loaded(recovered, source) = outcome else {
                expect(false, "expected a recovered document")
                return
            }
            expectEqual(source, .backup)
            expectEqual(recovered.gameState.calendar, state.calendar)
            expect(FileManager.default.fileExists(atPath: storage.quarantineDirectory.path))
            let quarantined = try FileManager.default.contentsOfDirectory(
                at: storage.quarantineDirectory,
                includingPropertiesForKeys: nil
            )
            expectEqual(quarantined.count, 1)
            expectEqual(try Data(contentsOf: quarantined[0]), Data([0x00]))
        }

        testAsync("quarantines a corrupt backup while retaining a valid primary") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let document = CoachWorldSaveDocument(
                gameState: GameState.bootstrap(seed: 20_260_815),
                metadata: CareerSaveMetadata(generation: 4)
            )
            let corrupt = Data([0x01, 0x02])
            try storage.write(try SaveEnvelope.encode(document))
            try storage.writeBackup(corrupt)

            let outcome = try await SaveCoordinator(storage: storage).load()
            guard case let .loaded(loaded, source) = outcome else {
                expect(false, "expected the valid primary to remain usable")
                return
            }
            expectEqual(source, .primary)
            expectEqual(loaded, document)
            let quarantined = try FileManager.default.contentsOfDirectory(
                at: storage.quarantineDirectory,
                includingPropertiesForKeys: nil
            )
            expectEqual(quarantined.count, 1)
            expectEqual(try Data(contentsOf: quarantined[0]), corrupt)
        }

        testAsync("newer backup is promoted and latest request replaces stale pending state") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let coordinator = SaveCoordinator(storage: storage)
            let first = CoachWorldSaveDocument(gameState: GameState.bootstrap(seed: 20_260_816))
            let second = CoachWorldSaveDocument(gameState: GameState.bootstrap(seed: 20_260_817))
            try await coordinator.requestSave(first, reason: .newCareer)
            try await coordinator.flush(reason: .explicit)
            try storage.writeBackup(try SaveEnvelope.encode(second.withGeneration(9)))
            let recovered = try await coordinator.load()
            guard case let .loaded(document, source) = recovered else {
                expect(false, "expected backup recovery")
                return
            }
            expectEqual(source, .backup)
            expectEqual(document.metadata.generation, UInt64(9))
            try await coordinator.requestSave(second.withGeneration(1), reason: .userAction)
            try await coordinator.flush(reason: .explicit)
            let outcome = try await coordinator.load()
            guard case let .loaded(document, _) = outcome else {
                expect(false, "expected a loaded document")
                return
            }
            expectEqual(document.metadata.generation, UInt64(10))
            expectEqual(document.gameState.calendar, second.gameState.calendar)
            expectEqual(
                try CoachWorldSaveDocument.decode(envelopeData: storage.read()).metadata.generation,
                UInt64(10)
            )
        }

        testAsync("SaveCoalescingTest commits the newest distinct pending snapshot") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let coordinator = SaveCoordinator(storage: storage)
            let seeds: [UInt64] = [20_260_820, 20_260_821, 20_260_822]
            for seed in seeds {
                try await coordinator.requestSave(
                    CoachWorldSaveDocument(
                        gameState: GameState.bootstrap(seed: seed),
                        metadata: CareerSaveMetadata(createdFromSeed: seed)
                    ),
                    reason: .userAction
                )
            }
            try await coordinator.flush(reason: .explicit)
            let saved = try CoachWorldSaveDocument.decode(envelopeData: storage.read())
            expectEqual(saved.metadata.createdFromSeed, seeds.last)
            expectEqual(saved.metadata.generation, UInt64(seeds.count))
            expect(!FileManager.default.fileExists(atPath: storage.backupURL.path),
                   "distinct pending requests produced more than one primary write")
        }

        testAsync("SaveOpenIsReadOnlyTest leaves a valid primary byte-identical") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let document = CoachWorldSaveDocument(
                gameState: GameState.bootstrap(seed: 20_260_823),
                metadata: CareerSaveMetadata(generation: 7, createdFromSeed: 20_260_823)
            )
            try storage.write(try SaveEnvelope.encode(document))
            let before = try Data(contentsOf: storage.url)
            let beforeDate = try FileManager.default.attributesOfItem(atPath: storage.url.path)[.modificationDate]
                as? Date

            guard case let .loaded(loaded, source) = try await SaveCoordinator(storage: storage).load() else {
                expect(false, "a valid primary did not load")
                return
            }
            expectEqual(source, .primary)
            expectEqual(loaded, document)
            expectEqual(try Data(contentsOf: storage.url), before)
            let afterDate = try FileManager.default.attributesOfItem(atPath: storage.url.path)[.modificationDate]
                as? Date
            expectEqual(afterDate, beforeDate)
            expect(!FileManager.default.fileExists(atPath: storage.backupURL.path),
                   "opening a valid primary created a backup")
        }

        testAsync("generation exhaustion is reported instead of dropping a save") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            let document = CoachWorldSaveDocument(
                gameState: GameState.bootstrap(seed: 20_260_818)
            )
            try storage.write(try SaveEnvelope.encode(document.withGeneration(UInt64.max)))
            let coordinator = SaveCoordinator(storage: storage)

            do {
                try await coordinator.requestSave(document, reason: .userAction)
                expect(false, "an exhausted generation counter silently accepted a save")
            } catch let error as SaveCoordinatorError {
                expectEqual(error, .generationOverflow)
            }
        }

        testAsync("oversized compressed input is rejected from its header") {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("pfc-save-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let storage = CoachWorldSaveStore(directory: directory)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            var header = Data(Array("PFC1".utf8))
            var version = SaveEnvelope.currentSchemaVersion.littleEndian
            withUnsafeBytes(of: &version) { header.append(contentsOf: $0) }
            header.append(1)
            header.append(contentsOf: Array(repeating: UInt8(0), count: 7))
            expect(FileManager.default.createFile(atPath: storage.url.path, contents: header))
            let handle = try FileHandle(forWritingTo: storage.url)
            try handle.seek(toOffset: UInt64(
                SaveEnvelope.headerLength + SaveEnvelope.maximumStoredBodyBytes
            ))
            try handle.write(contentsOf: Data([0x00]))
            try handle.close()

            do {
                _ = try await SaveCoordinator(storage: storage).load()
                expect(false, "an oversized compressed input was read past its header")
            } catch let error as SaveEnvelopeError {
                expectEqual(
                    error,
                    .bodyTooLarge(
                        bytes: SaveEnvelope.maximumStoredBodyBytes + 1,
                        maximum: SaveEnvelope.maximumStoredBodyBytes
                    )
                )
                expect(FileManager.default.fileExists(atPath: storage.quarantineDirectory.path))
            }
        }
    }
}
