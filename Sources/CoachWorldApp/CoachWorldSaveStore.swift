import Foundation
import FootballSimCore

/// Where the one save lives on the device.
///
/// One save, one coach (`CLAUDE.md`), so there is no slot management and no file browser: a single
/// known path the app writes and reads. The bytes themselves are `SaveEnvelope`'s business —
/// versioning, compression and the integrity check on decode all belong to the engine.
public struct CoachWorldSaveStore: Sendable {
    public static let fileName = "career.pfcsave"

    private let directory: URL

    /// Defaults to the app's Documents directory. The initialiser takes one so a test can write to
    /// a temporary directory instead of the process's real save.
    public init(directory: URL? = nil) {
        self.directory = directory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public var url: URL { directory.appendingPathComponent(Self.fileName) }
    public var backupURL: URL { directory.appendingPathComponent("\(Self.fileName).backup") }
    public var metadataURL: URL { directory.appendingPathComponent("\(Self.fileName).metadata") }
    public var quarantineDirectory: URL { directory.appendingPathComponent("Quarantine", isDirectory: true) }

    public var hasSave: Bool { FileManager.default.fileExists(atPath: url.path) }

    public func read() throws -> Data { try Data(contentsOf: url) }

    public func readBackup() throws -> Data { try Data(contentsOf: backupURL) }

    /// Writes through a sibling temporary file and replaces atomically, so a save interrupted
    /// mid-write cannot leave a truncated file where a career used to be.
    public func write(_ data: Data) throws {
        try writeAtomically(data, to: url)
    }

    public func writeBackup(_ data: Data) throws {
        try writeAtomically(data, to: backupURL)
    }

    public func writeMetadata(_ data: Data) throws {
        try writeAtomically(data, to: metadataURL)
    }

    public func quarantine(_ data: Data, name: String) throws -> URL {
        try FileManager.default.createDirectory(
            at: quarantineDirectory,
            withIntermediateDirectories: true
        )
        let safeName = name.replacingOccurrences(of: "/", with: "_")
        let destination = quarantineDirectory.appendingPathComponent(safeName)
        try data.write(to: destination, options: .atomic)
        return destination
    }

    public func delete() throws {
        for candidate in [url, backupURL, metadataURL]
            where FileManager.default.fileExists(atPath: candidate.path) {
            try FileManager.default.removeItem(at: candidate)
        }
    }

    private func writeAtomically(_ data: Data, to destination: URL) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: destination, options: .atomic)
    }
}

public enum SaveReason: String, Codable, Sendable {
    case newCareer
    case userAction
    case checkpoint
    case background
}

public enum SaveFlushReason: String, Codable, Sendable {
    case explicit
    case background
    case termination
}

public enum SaveRecoveryAction: String, Codable, Sendable {
    case useBackup
    case quarantinePrimary
}

public enum SaveSource: String, Codable, Sendable {
    case primary
    case backup
}

public enum SaveLoadOutcome: Sendable {
    case empty
    case loaded(CoachWorldSaveDocument, source: SaveSource)
}

public enum SaveCoordinatorError: Error, Equatable, Sendable {
    case noRecoverySource
    case primaryAndBackupUnreadable
    case recoveryActionRequired
}

/// Serialises save requests, keeps only the newest pending snapshot, and verifies a candidate by
/// reopening it before the primary is considered current. The actor is intentionally independent
/// of SwiftUI so all durable I/O stays off the main actor.
public actor SaveCoordinator {
    private let storage: CoachWorldSaveStore
    private var pending: CoachWorldSaveDocument?
    private var lastWrittenGeneration: UInt64 = 0

    public init(storage: CoachWorldSaveStore = CoachWorldSaveStore()) {
        self.storage = storage
    }

    public func load() async throws -> SaveLoadOutcome {
        guard storage.hasSave || FileManager.default.fileExists(atPath: storage.backupURL.path) else {
            return .empty
        }
        if storage.hasSave {
            do {
                let document = try CoachWorldSaveDocument.decode(envelopeData: storage.read())
                if FileManager.default.fileExists(atPath: storage.backupURL.path),
                   let backup = try? CoachWorldSaveDocument.decode(envelopeData: storage.readBackup()),
                   backup.metadata.generation > document.metadata.generation {
                    lastWrittenGeneration = backup.metadata.generation
                    return .loaded(backup, source: .backup)
                }
                lastWrittenGeneration = document.metadata.generation
                return .loaded(document, source: .primary)
            } catch {
                if Self.isFuture(error) { throw error }
                let primary = try? storage.read()
                if let primary {
                    _ = try? storage.quarantine(primary, name: "primary-\(UUID().uuidString).pfcsave")
                }
            }
        }
        guard FileManager.default.fileExists(atPath: storage.backupURL.path) else {
            throw SaveCoordinatorError.noRecoverySource
        }
        do {
            let document = try CoachWorldSaveDocument.decode(envelopeData: storage.readBackup())
            lastWrittenGeneration = document.metadata.generation
            return .loaded(document, source: .backup)
        } catch {
            throw SaveCoordinatorError.primaryAndBackupUnreadable
        }
    }

    private static func isFuture(_ error: Error) -> Bool {
        if let envelope = error as? SaveEnvelopeError,
           case .futureVersion = envelope { return true }
        if let document = error as? SaveDocumentError,
           case .futureDocumentVersion = document { return true }
        return false
    }

    public func requestSave(_ document: CoachWorldSaveDocument, reason: SaveReason) async {
        _ = reason
        if lastWrittenGeneration == 0, storage.hasSave,
           let current = try? CoachWorldSaveDocument.decode(envelopeData: storage.read()) {
            lastWrittenGeneration = current.metadata.generation
        }
        let pendingGeneration = pending?.metadata.generation ?? 0
        let floor = max(lastWrittenGeneration, pendingGeneration)
        let requested = document.metadata.generation
        guard requested > floor || pending == nil else { return }
        let nextGeneration = requested > floor
            ? requested
            : (floor == UInt64.max ? UInt64.max : floor + 1)
        pending = document.withGeneration(nextGeneration)
    }

    public func flush(reason: SaveFlushReason) async throws {
        _ = reason
        guard let document = pending else { return }
        guard document.metadata.generation > lastWrittenGeneration else {
            pending = nil
            return
        }
        let candidate = try SaveEnvelope.encode(document)
        if storage.hasSave,
           let current = try? storage.read(),
           (try? CoachWorldSaveDocument.decode(envelopeData: current)) != nil {
            try storage.writeBackup(current)
        }
        try storage.write(candidate)
        _ = try CoachWorldSaveDocument.decode(envelopeData: storage.read())
        let metadata = try JSONEncoder.stable().encode(document.metadata)
        try storage.writeMetadata(metadata)
        lastWrittenGeneration = document.metadata.generation
        pending = nil
    }

    public func recover(using action: SaveRecoveryAction) async throws -> CoachWorldSaveDocument {
        switch action {
        case .useBackup:
            guard FileManager.default.fileExists(atPath: storage.backupURL.path) else {
                throw SaveCoordinatorError.noRecoverySource
            }
            let document = try CoachWorldSaveDocument.decode(envelopeData: storage.readBackup())
            try storage.write(try SaveEnvelope.encode(document))
            lastWrittenGeneration = document.metadata.generation
            return document
        case .quarantinePrimary:
            guard storage.hasSave else { throw SaveCoordinatorError.noRecoverySource }
            let primary = try storage.read()
            _ = try storage.quarantine(primary, name: "manual-\(UUID().uuidString).pfcsave")
            guard FileManager.default.fileExists(atPath: storage.backupURL.path) else {
                throw SaveCoordinatorError.recoveryActionRequired
            }
            let document = try CoachWorldSaveDocument.decode(envelopeData: storage.readBackup())
            try storage.write(try SaveEnvelope.encode(document))
            lastWrittenGeneration = document.metadata.generation
            return document
        }
    }
}
