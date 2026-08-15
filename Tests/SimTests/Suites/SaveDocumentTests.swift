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
        test("schema 11 bare root wraps and normalises to 12") {
            let state = GameState.bootstrap(seed: 20_260_812)
            let legacy = try! legacyEnvelope(for: state)
            let document = try! CoachWorldSaveDocument.decode(envelopeData: legacy)
            expectEqual(document.documentVersion, CoachWorldSaveDocument.currentVersion)
            expectEqual(document.gameState.version, GameState.schemaVersion)
            expectEqual(document.metadata.migratedFromRootVersion, GameState.legacySchemaVersion)
            expectEqual(document.gameState.calendar, state.calendar)
            expectEqual(document.presentation.returnRoute, nil)
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

        test("current document round trips") {
            let state = GameState.bootstrap(seed: 20_260_813)
            let expected = CoachWorldSaveDocument(
                gameState: state,
                presentation: CareerPresentationState(route: "13", returnRoute: "16"),
                metadata: CareerSaveMetadata(generation: 4, createdFromSeed: 20_260_813)
            )
            let decoded = try! CoachWorldSaveDocument.decode(
                envelopeData: SaveEnvelope.encode(expected)
            )
            expectEqual(decoded, expected)
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
            expectEqual(try Data(contentsOf: quarantined[0]), Data([0x00]))
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
