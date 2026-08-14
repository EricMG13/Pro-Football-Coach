import Foundation
import FootballSimCore
import CoachWorldApp

private func legacyEnvelope(for state: GameState, omitOptionalRootFields: Bool = false) throws -> Data {
    let encoded = try JSONEncoder.stable().encode(state)
    var object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
    object["version"] = GameState.legacySchemaVersion
    if omitOptionalRootFields {
        object.removeValue(forKey: "tactical")
        object.removeValue(forKey: "proMarket")
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
        }

        test("schema 11 missing later root fields receives explicit defaults") {
            let state = GameState.bootstrap(seed: 20_260_815)
            let legacy = try! legacyEnvelope(for: state, omitOptionalRootFields: true)
            let document = try! CoachWorldSaveDocument.decode(envelopeData: legacy)
            expectEqual(document.gameState.version, GameState.schemaVersion)
            expectEqual(document.gameState.proMarket.season, state.calendar.season)
        }

        test("current document round trips") {
            let state = GameState.bootstrap(seed: 20_260_813)
            let expected = CoachWorldSaveDocument(
                gameState: state,
                presentation: CareerPresentationState(route: "roster"),
                metadata: CareerSaveMetadata(generation: 4, createdFromSeed: 20_260_813)
            )
            let decoded = try! CoachWorldSaveDocument.decode(
                envelopeData: SaveEnvelope.encode(expected)
            )
            expectEqual(decoded, expected)
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
            await coordinator.requestSave(first, reason: .newCareer)
            await coordinator.requestSave(
                first.withGeneration(0),
                reason: .userAction
            )
            try await coordinator.flush(reason: .explicit)
            await coordinator.requestSave(first.withGeneration(0), reason: .checkpoint)
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
        }
    }
}
