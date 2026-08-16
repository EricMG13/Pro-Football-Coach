import Foundation
import FootballSimCore

/// Durable, application-level state around the engine root. The envelope header remains version 1;
/// this document is the first versioned shape inside it, which lets presentation and recovery state
/// evolve without pretending that a bare GameState is a complete app save.
public struct CareerPresentationState: Codable, Sendable, Equatable {
    public static let maximumReadInboxItems = 128

    private enum CodingKeys: String, CodingKey {
        case route
        case returnRoute
        case readInboxItemIDs
        case selectedSubjectID
        case draftValues
        case pendingTaskID
        case interruptedTask
    }

    public var route: String
    /// Optional origin for transient child surfaces; nil keeps legacy saves canonical.
    public var returnRoute: String?
    /// Stable IDs acknowledged by the coach. Presentation-only state is bounded so a long career
    /// cannot grow a save indefinitely; the authoritative item remains in the world ledger.
    public var readInboxItemIDs: [String]
    public var selectedSubjectID: UUID?
    public var draftValues: [String: String]
    public var pendingTaskID: UUID?
    public var interruptedTask: String?

    public init(
        route: String = "8",
        returnRoute: String? = nil,
        readInboxItemIDs: [String] = [],
        selectedSubjectID: UUID? = nil,
        draftValues: [String: String] = [:],
        pendingTaskID: UUID? = nil,
        interruptedTask: String? = nil
    ) {
        self.route = route
        self.returnRoute = returnRoute
        self.readInboxItemIDs = Array(readInboxItemIDs.suffix(Self.maximumReadInboxItems))
        self.selectedSubjectID = selectedSubjectID
        self.draftValues = draftValues
        self.pendingTaskID = pendingTaskID
        self.interruptedTask = interruptedTask
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        route = try container.decode(String.self, forKey: .route)
        returnRoute = try container.decodeIfPresent(String.self, forKey: .returnRoute)
        let decodedReadIDs = try container.decodeIfPresent(
            [String].self,
            forKey: .readInboxItemIDs
        ) ?? []
        guard decodedReadIDs.count <= Self.maximumReadInboxItems else {
            throw DecodingError.dataCorruptedError(
                forKey: .readInboxItemIDs,
                in: container,
                debugDescription: "Inbox read receipts exceed the bounded presentation limit."
            )
        }
        readInboxItemIDs = decodedReadIDs
        selectedSubjectID = try container.decodeIfPresent(UUID.self, forKey: .selectedSubjectID)
        draftValues = try container.decodeIfPresent([String: String].self, forKey: .draftValues) ?? [:]
        pendingTaskID = try container.decodeIfPresent(UUID.self, forKey: .pendingTaskID)
        interruptedTask = try container.decodeIfPresent(String.self, forKey: .interruptedTask)
    }
}

public struct CareerSaveMetadata: Codable, Sendable, Equatable {
    public var generation: UInt64
    public var createdFromSeed: UInt64?
    public var label: String
    public var migratedFromRootVersion: Int?

    public init(
        generation: UInt64 = 0,
        createdFromSeed: UInt64? = nil,
        label: String = "Career",
        migratedFromRootVersion: Int? = nil
    ) {
        self.generation = generation
        self.createdFromSeed = createdFromSeed
        self.label = label
        self.migratedFromRootVersion = migratedFromRootVersion
    }
}

public struct CoachWorldSaveDocument: Codable, Sendable, Equatable {
    public static let currentVersion: UInt32 = 1

    public let documentVersion: UInt32
    public let gameState: GameState
    public let presentation: CareerPresentationState
    public let metadata: CareerSaveMetadata

    public init(
        gameState: GameState,
        presentation: CareerPresentationState = CareerPresentationState(),
        metadata: CareerSaveMetadata = CareerSaveMetadata(),
        documentVersion: UInt32 = currentVersion
    ) {
        precondition(documentVersion == Self.currentVersion)
        self.documentVersion = documentVersion
        self.gameState = gameState
        self.presentation = presentation
        self.metadata = metadata
    }

    public func withGeneration(_ generation: UInt64) -> Self {
        Self(
            gameState: gameState,
            presentation: presentation,
            metadata: CareerSaveMetadata(
                generation: generation,
                createdFromSeed: metadata.createdFromSeed,
                label: metadata.label,
                migratedFromRootVersion: metadata.migratedFromRootVersion
            )
        )
    }

    /// Decodes a current document or wraps a legacy bare GameState. A document marker is checked
    /// before the legacy path so a future document fails loudly instead of being misread as a root.
    public static func decode(envelopeData: Data) throws -> Self {
        let body = try SaveEnvelope.body(from: envelopeData)
        let object = try JSONSerialization.jsonObject(with: body)
        let dictionary = object as? [String: Any]
        if dictionary?["documentVersion"] != nil {
            guard let rawVersion = dictionary?["documentVersion"] as? NSNumber else {
                throw SaveDocumentError.unsupportedDocumentVersion(0)
            }
            let version = rawVersion.uint32Value
            guard version == Self.currentVersion else {
                if version > Self.currentVersion {
                    throw SaveDocumentError.futureDocumentVersion(version)
                }
                throw SaveDocumentError.unsupportedDocumentVersion(version)
            }
            return try JSONDecoder.stable().decode(Self.self, from: body)
        }
        let legacy = try JSONDecoder.stable().decode(GameState.self, from: body)
        let rootVersion = (dictionary?["version"] as? NSNumber)?.intValue
        return Self(
            gameState: legacy,
            presentation: CareerPresentationState(route: "8"),
            metadata: CareerSaveMetadata(
                migratedFromRootVersion: rootVersion == GameState.legacySchemaVersion
                    ? GameState.legacySchemaVersion
                    : nil
            )
        )
    }
}

public enum SaveDocumentError: Error, Equatable, Sendable {
    case futureDocumentVersion(UInt32)
    case unsupportedDocumentVersion(UInt32)
    case generationOverflow
}
