import Foundation

/// Which tier a thing belongs to. One save spans both (`02-GAME-DESIGN.md` section 1).
public enum Tier: String, Codable, Sendable, CaseIterable {
    case college, pro

    /// The number of weeks a season runs in this tier.
    public var seasonWeeks: Int {
        switch self {
        case .college: return CollegeRules.seasonWeeks
        case .pro: return ProRules.seasonWeeks
        }
    }

    /// How many members the tier holds.
    public var memberCount: Int {
        switch self {
        case .college: return CollegeRules.programmeCount
        case .pro: return ProRules.teamCount
        }
    }
}

/// A conference. Composition is generated per save (`02` section 11.4), so this carries membership
/// rather than a fixed table.
public struct Conference: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var tier: Tier
    public var memberIDs: [UUID]

    /// Pro only. College conferences have no divisions in this game's structure.
    public var divisionIDs: [UUID]

    public init(
        id: UUID = UUID(),
        name: String,
        tier: Tier,
        memberIDs: [UUID] = [],
        divisionIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.tier = tier
        self.memberIDs = memberIDs
        self.divisionIDs = divisionIDs
    }
}

/// A division inside a pro conference.
public struct Division: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var conferenceID: UUID
    public var memberIDs: [UUID]

    public init(id: UUID = UUID(), name: String, conferenceID: UUID, memberIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.conferenceID = conferenceID
        self.memberIDs = memberIDs
    }
}

/// The league as a whole: where the calendar is, and what the save's root seed is.
///
/// `seed` is the root of `03-MATCH-ENGINE.md` section 3's hierarchy. Everything the engine draws
/// derives from it through `SeededRandom.derive`, which is why it is stored rather than recomputed:
/// a seed recomputed from a mutable league is a seed that changes when the league does.
public struct League: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let seed: UInt64

    /// Seasons elapsed since the save began. Zero-based.
    public var season: Int

    /// Week within the current season, one-based, running to the tier's `seasonWeeks`.
    public var week: Int

    public var conferences: [Conference]
    public var divisions: [Division]

    public init(
        id: UUID = UUID(),
        seed: UInt64,
        season: Int = 0,
        week: Int = 1,
        conferences: [Conference] = [],
        divisions: [Division] = []
    ) {
        self.id = id
        self.seed = seed
        self.season = season
        self.week = week
        self.conferences = conferences
        self.divisions = divisions
    }

    /// The seed for the current season, derived rather than stored.
    public var seasonSeed: UInt64 {
        SeededRandom.derive(from: seed, scope: .season, ordinal: season)
    }

    /// The seed for a given week of the current season.
    public func weekSeed(_ week: Int) -> UInt64 {
        SeededRandom.derive(from: seasonSeed, scope: .week, ordinal: week)
    }

    public func conferences(in tier: Tier) -> [Conference] {
        conferences.filter { $0.tier == tier }
    }
}
