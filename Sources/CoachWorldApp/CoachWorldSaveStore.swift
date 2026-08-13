import Foundation

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

    public var hasSave: Bool { FileManager.default.fileExists(atPath: url.path) }

    public func read() throws -> Data { try Data(contentsOf: url) }

    /// Writes through a sibling temporary file and replaces atomically, so a save interrupted
    /// mid-write cannot leave a truncated file where a career used to be.
    public func write(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    public func delete() throws {
        guard hasSave else { return }
        try FileManager.default.removeItem(at: url)
    }
}
