import Foundation
import FootballSimCore

/// Where the player's own settings live. `02` §3.16.
///
/// **Beside the save, not inside it.** Difficulty and accessibility choices are properties of how
/// someone plays rather than of the world they play in, and putting them in `GameState` would mean a
/// schema change — and a migration for every existing save — to answer a question the save does not
/// ask. It also means starting a new career does not silently reset how the player likes to play.
public struct CoachWorldSettings: Codable, Sendable, Equatable {
    public var difficulty: DifficultySettings.Level
    /// Whether to advance several weeks at a time when nothing is asking. `02` §3.12.
    public var advanceWeeksAtOnce: Int

    public init(
        difficulty: DifficultySettings.Level = .headCoach,
        advanceWeeksAtOnce: Int = 1
    ) {
        self.difficulty = difficulty
        self.advanceWeeksAtOnce = max(1, min(advanceWeeksAtOnce, CoachWorldSettings.maximumAdvance))
    }

    /// A bound, because `advance(weeks:)` is a loop and a settings file is user-writable.
    public static let maximumAdvance = 8

    public static let `default` = CoachWorldSettings()

    /// Tolerates a file written before a field existed, so adding a setting never strands one.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            difficulty: try container.decodeIfPresent(DifficultySettings.Level.self,
                                                      forKey: .difficulty) ?? .headCoach,
            advanceWeeksAtOnce: try container.decodeIfPresent(Int.self,
                                                              forKey: .advanceWeeksAtOnce) ?? 1
        )
    }
}

/// Reads and writes the settings file.
public struct CoachWorldSettingsStore: Sendable {
    public static let fileName = "settings.json"

    private let directory: URL

    public init(directory: URL? = nil) {
        self.directory = directory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public var url: URL { directory.appendingPathComponent(Self.fileName) }

    /// Never throws on a missing or unreadable file: a settings file that will not parse is a reason
    /// to play with the defaults, not a reason to refuse to start. The save is where refusing to
    /// guess matters, and that path still throws.
    public func read() -> CoachWorldSettings {
        guard let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(CoachWorldSettings.self, from: data)
        else { return .default }
        return settings
    }

    public func write(_ settings: CoachWorldSettings) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder.stable().encode(settings).write(to: url, options: .atomic)
    }
}
