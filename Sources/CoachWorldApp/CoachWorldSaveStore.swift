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

    public func read() throws -> Data { try read(from: url) }

    public func readBackup() throws -> Data { try read(from: backupURL) }

    public func readHeader() throws -> Data { try readHeader(from: url) }

    public func readBackupHeader() throws -> Data { try readHeader(from: backupURL) }

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
        let safeName = quarantineName(name)
        let destination = quarantineDirectory.appendingPathComponent(safeName)
        try data.write(to: destination, options: .atomic)
        return destination
    }

    /// Copies a corrupt save without first materialising it in memory. The original remains in
    /// place until the player explicitly chooses recovery or replacement.
    public func quarantinePrimary(name: String) throws -> URL {
        try FileManager.default.createDirectory(
            at: quarantineDirectory,
            withIntermediateDirectories: true
        )
        let safeName = quarantineName(name)
        let destination = quarantineDirectory.appendingPathComponent(safeName)
        try FileManager.default.copyItem(at: url, to: destination)
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

    private func quarantineName(_ name: String) -> String {
        let components = name.split(whereSeparator: { $0 == "/" || $0 == "\\" })
        return String(components.last ?? Substring("quarantine.pfcsave"))
    }

    private func readHeader(from source: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: source)
        defer { try? handle.close() }
        return try handle.read(upToCount: SaveEnvelope.headerLength) ?? Data()
    }

    private func read(from source: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: source)
        defer { try? handle.close() }

        let header = try handle.read(upToCount: SaveEnvelope.headerLength) ?? Data()
        guard header.count == SaveEnvelope.headerLength,
              (try? SaveEnvelope.schemaVersion(ofHeader: header)) == SaveEnvelope.currentSchemaVersion,
              header[8] & ~UInt8(1) == 0,
              header[9..<SaveEnvelope.headerLength].allSatisfy({ $0 == 0 })
        else {
            // Header validation belongs to SaveEnvelope. Returning only the fixed prefix keeps
            // malformed/future files cheap while preserving their precise error classification.
            return header
        }

        let bodyLimit = SaveEnvelope.storedBodyLimit(ofHeader: header)
        let maximumBytes = SaveEnvelope.headerLength + bodyLimit
        var result = Data()
        result.reserveCapacity(min(maximumBytes, 64 * 1024))
        result.append(header)
        let chunkSize = 64 * 1024
        while result.count < maximumBytes {
            let remaining = maximumBytes - result.count
            let chunk = try handle.read(upToCount: min(chunkSize, remaining)) ?? Data()
            if chunk.isEmpty { break }
            result.append(chunk)
        }
        if result.count == maximumBytes,
           !(try handle.read(upToCount: 1) ?? Data()).isEmpty {
            throw SaveEnvelopeError.bodyTooLarge(bytes: bodyLimit + 1, maximum: bodyLimit)
        }
        return result
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
    case generationOverflow
    case writeVerificationFailed
}

/// Serialises save requests, keeps only the newest pending snapshot, and verifies a candidate by
/// byte-identical readback before the primary is considered current. The actor is intentionally
/// independent of SwiftUI so all durable I/O stays off the main actor.
public actor SaveCoordinator {
    private let storage: CoachWorldSaveStore
    private var pending: CoachWorldSaveDocument?
    private var lastWrittenGeneration: UInt64 = 0
    private var flushTask: Task<UInt64, Error>?
    private var flushingGeneration: UInt64?

    public init(storage: CoachWorldSaveStore = CoachWorldSaveStore()) {
        self.storage = storage
    }

    public func load() async throws -> SaveLoadOutcome {
        guard storage.hasSave || FileManager.default.fileExists(atPath: storage.backupURL.path) else {
            return .empty
        }
        var primaryError: Error?
        var backupError: Error?
        let primary: LoadedSource?
        do { primary = try load(source: .primary) }
        catch { primary = nil; primaryError = error }
        let backup: LoadedSource?
        do { backup = try load(source: .backup) }
        catch { backup = nil; backupError = error }
        if let primaryError, Self.isFuture(primaryError) { throw primaryError }
        if let backupError, Self.isFuture(backupError) { throw backupError }
        if let primary, let backup {
            let selected = primary.document.metadata.generation >= backup.document.metadata.generation
                ? primary
                : backup
            lastWrittenGeneration = selected.document.metadata.generation
            if selected.source == .backup {
                // Promote the newest valid copy before returning. A later failed write must not
                // replace the only current backup with an older primary.
                try storage.write(try SaveEnvelope.encode(selected.document))
            }
            return .loaded(selected.document, source: selected.source)
        }
        if let primary {
            lastWrittenGeneration = primary.document.metadata.generation
            return .loaded(primary.document, source: .primary)
        }
        if let backup {
            lastWrittenGeneration = backup.document.metadata.generation
            try storage.write(try SaveEnvelope.encode(backup.document))
            return .loaded(backup.document, source: .backup)
        }
        if let primaryError, Self.isMissing(backupError) { throw primaryError }
        if let backupError, Self.isMissing(primaryError) { throw backupError }
        if storage.hasSave || FileManager.default.fileExists(atPath: storage.backupURL.path) {
            throw SaveCoordinatorError.primaryAndBackupUnreadable
        }
        throw SaveCoordinatorError.noRecoverySource
    }

    private struct LoadedSource: Sendable {
        let document: CoachWorldSaveDocument
        let source: SaveSource
    }

    private func load(source: SaveSource) throws -> LoadedSource {
        let exists = source == .primary ? storage.hasSave
            : FileManager.default.fileExists(atPath: storage.backupURL.path)
        guard exists else { throw SaveCoordinatorError.noRecoverySource }
        let url = source == .primary ? storage.url : storage.backupURL
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue
        let header = source == .primary ? (try? storage.readHeader()) : (try? storage.readBackupHeader())
        let storedLimit = header.map(SaveEnvelope.storedBodyLimit(ofHeader:))
            ?? SaveEnvelope.maximumBodyBytes
        if let size, size > storedLimit + SaveEnvelope.headerLength {
            if source == .primary {
                _ = try? storage.quarantinePrimary(name: "primary-\(UUID().uuidString).pfcsave")
            }
            throw SaveEnvelopeError.bodyTooLarge(
                bytes: size - SaveEnvelope.headerLength,
                maximum: storedLimit
            )
        }
        let data = source == .primary ? try storage.read() : try storage.readBackup()
        do {
            return LoadedSource(
                document: try CoachWorldSaveDocument.decode(envelopeData: data),
                source: source
            )
        } catch {
            if Self.isFuture(error) { throw error }
            if source == .primary {
                _ = try? storage.quarantinePrimary(name: "primary-\(UUID().uuidString).pfcsave")
            }
            throw error
        }
    }

    private static func isFuture(_ error: Error) -> Bool {
        if let envelope = error as? SaveEnvelopeError,
           case .futureVersion = envelope { return true }
        if let document = error as? SaveDocumentError,
           case .futureDocumentVersion = document { return true }
        return false
    }

    private static func isMissing(_ error: Error?) -> Bool {
        guard let error else { return true }
        return (error as? SaveCoordinatorError) == .noRecoverySource
    }

    public func requestSave(_ document: CoachWorldSaveDocument, reason: SaveReason) async throws {
        _ = reason
        if lastWrittenGeneration == 0 {
            let primary = try? load(source: .primary).document.metadata.generation
            let backup = try? load(source: .backup).document.metadata.generation
            lastWrittenGeneration = max(primary ?? 0, backup ?? 0)
        }
        let floor = max(
            max(lastWrittenGeneration, pending?.metadata.generation ?? 0),
            flushingGeneration ?? 0
        )
        guard floor < UInt64.max else { throw SaveCoordinatorError.generationOverflow }
        // The request itself is the newest state. Never discard it because its caller's metadata
        // was stale; the coordinator owns the durable ordering number.
        pending = document.withGeneration(max(document.metadata.generation, floor + 1))
    }

    public func flush(reason: SaveFlushReason) async throws {
        _ = reason
        while true {
            if let active = flushTask {
                let generation: UInt64
                do {
                    generation = try await active.value
                } catch {
                    flushTask = nil
                    flushingGeneration = nil
                    throw error
                }
                flushTask = nil
                flushingGeneration = nil
                lastWrittenGeneration = max(lastWrittenGeneration, generation)
                if pending?.metadata.generation == generation { pending = nil }
                continue
            }
            guard let document = pending else { return }
            guard document.metadata.generation > lastWrittenGeneration else {
                pending = nil
                return
            }
            let storage = self.storage
            flushingGeneration = document.metadata.generation
            let task = Task.detached(priority: .utility) {
                let candidate = try SaveEnvelope.encode(document)
                if storage.hasSave,
                   let current = try? storage.read(),
                   (try? CoachWorldSaveDocument.decode(envelopeData: current)) != nil {
                    try storage.writeBackup(current)
                }
                try storage.write(candidate)
                guard try storage.read() == candidate else {
                    throw SaveCoordinatorError.writeVerificationFailed
                }
                let metadata = try JSONEncoder.stable().encode(document.metadata)
                try storage.writeMetadata(metadata)
                return document.metadata.generation
            }
            flushTask = task
            let generation: UInt64
            do {
                generation = try await task.value
            } catch {
                flushTask = nil
                flushingGeneration = nil
                throw error
            }
            flushTask = nil
            flushingGeneration = nil
            lastWrittenGeneration = max(lastWrittenGeneration, generation)
            if pending?.metadata.generation == generation { pending = nil }
        }
    }

    public func recover(using action: SaveRecoveryAction) async throws -> CoachWorldSaveDocument {
        pending = nil
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
            _ = try storage.quarantinePrimary(name: "manual-\(UUID().uuidString).pfcsave")
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
