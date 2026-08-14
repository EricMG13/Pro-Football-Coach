import Foundation
import FootballSimCore

/// Where the player's own settings live. `02` §3.16.
///
/// **This file holds the pre-career choice; the save is authoritative once a career exists.** The
/// original note here said difficulty belongs beside the save rather than inside it, and that was
/// wrong: all three of its settings are read by *engine* code — the call-in budget by the match
/// loop, delegation by career control, job-security pressure by the career arc — and the engine
/// cannot read an app-layer file without breaking the separation `CLAUDE.md` fixes. A difficulty the
/// engine cannot see changes nothing.
///
/// So `GameState.difficulty` carries it, optional and omitted when absent so no existing save is
/// stranded, and this file answers the one question the save cannot: what a *new* career should
/// start at. Which also keeps the original point intact — starting a new career does not silently
/// reset how the player likes to play.
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
