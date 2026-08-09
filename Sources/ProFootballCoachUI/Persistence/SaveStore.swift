import Foundation
import FootballSimCore

/// Enough to list a save without decoding the whole league.
public struct SaveMeta: Codable, Identifiable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id, name, teamName, teamAbbreviation, primaryHex, secondaryHex, coachName, year
        case phaseLabel, updatedAt
    }

    public let id: UUID
    public var name: String
    public var teamName: String
    public var teamAbbreviation: String
    public var primaryHex: String
    /// The club's second colour, so a save row can draw the real mark rather than a plain disc.
    public var secondaryHex: String
    public var coachName: String
    public var year: Int
    public var phaseLabel: String
    public var updatedAt: Date

    /// Decoded field by field so save lists written before the second colour existed still load.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        teamName = try container.decode(String.self, forKey: .teamName)
        teamAbbreviation = try container.decode(String.self, forKey: .teamAbbreviation)
        primaryHex = try container.decode(String.self, forKey: .primaryHex)
        secondaryHex = try container.decodeIfPresent(String.self, forKey: .secondaryHex) ?? "#FFFFFF"
        coachName = try container.decode(String.self, forKey: .coachName)
        year = try container.decode(Int.self, forKey: .year)
        phaseLabel = try container.decode(String.self, forKey: .phaseLabel)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public init(
        id: UUID,
        name: String,
        teamName: String,
        teamAbbreviation: String,
        primaryHex: String,
        secondaryHex: String = "#FFFFFF",
        coachName: String,
        year: Int,
        phaseLabel: String,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.teamName = teamName
        self.teamAbbreviation = teamAbbreviation
        self.primaryHex = primaryHex
        self.secondaryHex = secondaryHex
        self.coachName = coachName
        self.year = year
        self.phaseLabel = phaseLabel
        self.updatedAt = updatedAt
    }
}

/// Reads and writes franchises on disk.
///
/// Writes are atomic and always leave the previous good file behind as a backup. Save
/// corruption is the single most common complaint about the games this one follows — one bad
/// write around season eight and a dynasty is gone — so loading falls back to the backup
/// rather than failing outright.
public struct SaveStore: Sendable {
    private let directory: URL
    /// Resolved per call rather than stored: FileManager is not Sendable, and the default
    /// instance is cheap to reach.
    private var fileManager: FileManager { .default }

    public init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.directory = base.appendingPathComponent("ProFootballCoach/Saves", isDirectory: true)
        }
    }

    private func ensureDirectory() throws {
        guard !fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func leagueURL(_ id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    private func backupURL(_ id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).backup.json")
    }

    private func metaURL(_ id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).meta.json")
    }

    /// Every save on disk, newest first.
    public func list() -> [SaveMeta] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return [] }

        let decoder = JSONDecoder.stable()
        return contents
            .filter { $0.lastPathComponent.hasSuffix(".meta.json") }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(SaveMeta.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Writes a franchise, rotating the previous version into a backup first.
    @discardableResult
    public func save(_ league: League, id: UUID, name: String) throws -> SaveMeta {
        try ensureDirectory()
        let encoder = JSONEncoder.stable()
        let data = try encoder.encode(league)

        let target = leagueURL(id)
        if fileManager.fileExists(atPath: target.path) {
            let backup = backupURL(id)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: target, to: backup)
        }
        try data.write(to: target, options: .atomic)

        let team = league.userTeam
        let meta = SaveMeta(
            id: id,
            name: name,
            teamName: team?.fullName ?? "Unknown",
            teamAbbreviation: team?.abbreviation ?? "—",
            primaryHex: team?.colors.primaryHex ?? "#333333",
            secondaryHex: team?.colors.secondaryHex ?? "#FFFFFF",
            coachName: league.coach.name,
            year: league.year,
            phaseLabel: league.phase.label,
            updatedAt: Date()
        )
        try encoder.encode(meta).write(to: metaURL(id), options: .atomic)
        return meta
    }

    /// Loads a franchise, falling back to the backup if the main file is unreadable.
    public func load(id: UUID) throws -> League {
        let decoder = JSONDecoder.stable()
        do {
            let data = try Data(contentsOf: leagueURL(id))
            return try SaveMigrator.migrate(data: data, decoder: decoder)
        } catch {
            let data = try Data(contentsOf: backupURL(id))
            return try SaveMigrator.migrate(data: data, decoder: decoder)
        }
    }

    public func delete(id: UUID) {
        try? fileManager.removeItem(at: leagueURL(id))
        try? fileManager.removeItem(at: backupURL(id))
        try? fileManager.removeItem(at: metaURL(id))
    }
}

/// Brings older save files up to the current shape before decoding.
public enum SaveMigrator {
    public enum MigrationError: Error {
        case unreadable
        case futureVersion(Int)
    }

    /// Just the version, decoded without materialising the whole franchise.
    private struct VersionProbe: Decodable { let version: Int }

    /// Every format change bumps `League.currentVersion` and adds a step here.
    ///
    /// The version is read with a one-field probe rather than `JSONSerialization`, which
    /// previously built a full dictionary of a multi-megabyte save purely to read one integer —
    /// so every open parsed the file twice.
    public static func migrate(data: Data, decoder: JSONDecoder) throws -> League {
        guard let probe = try? decoder.decode(VersionProbe.self, from: data) else {
            throw MigrationError.unreadable
        }
        guard probe.version <= League.currentVersion else {
            throw MigrationError.futureVersion(probe.version)
        }
        // Version 1 is the current shape, so there is nothing to upgrade yet. Future versions
        // rewrite the payload step by step here before it is decoded.
        return try decoder.decode(League.self, from: data)
    }
}
