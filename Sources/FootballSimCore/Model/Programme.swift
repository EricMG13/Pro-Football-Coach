import Foundation

/// A college programme.
///
/// The archetype (`02-GAME-DESIGN.md` section 8) is a generated identity's spine: it carries priors
/// over resources, fanbase volatility, academic constraint, recruiting reach and scheme
/// inheritance. P2 generates those priors; P1 gives them a home.
public struct Programme: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var nickname: String
    public var cityName: String
    public var conferenceID: UUID?

    public var archetypeID: Int
    public var scheme: SchemeIdentity

    /// Prestige on the rating scale, so it is comparable with everything else.
    public var prestige: Rating

    public var rosterIDs: [UUID]
    public var scholarshipCount: Int
    public var staffIDs: [UUID]

    /// The rivalries this programme carries, strongest first, bounded by
    /// `SharedRules.rivalriesPerProgramme`.
    ///
    /// `private(set)` with a mutating adder, because a bound applied only in the memberwise
    /// initialiser is not a bound: the two paths that actually accumulate rivalries across a career
    /// are appending to the array and decoding a save, and both bypassed it. Fifty-eight rivals
    /// round-tripped through the envelope unchanged before this was written.
    public private(set) var rivalIDs: [UUID]

    public init(
        id: UUID = UUID(),
        name: String,
        nickname: String,
        cityName: String,
        conferenceID: UUID? = nil,
        archetypeID: Int,
        scheme: SchemeIdentity,
        prestige: Rating,
        rosterIDs: [UUID] = [],
        scholarshipCount: Int = 0,
        staffIDs: [UUID] = [],
        rivalIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.cityName = cityName
        self.conferenceID = conferenceID
        self.archetypeID = archetypeID
        self.scheme = scheme
        self.prestige = prestige
        self.rosterIDs = rosterIDs
        self.scholarshipCount = scholarshipCount
        self.staffIDs = staffIDs
        self.rivalIDs = Array(rivalIDs.prefix(SharedRules.rivalriesPerProgramme))
    }

    /// Routed through the memberwise initialiser so a save written before the bound existed is
    /// truncated on load rather than carried forward.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            nickname: try container.decode(String.self, forKey: .nickname),
            cityName: try container.decode(String.self, forKey: .cityName),
            conferenceID: try container.decodeIfPresent(UUID.self, forKey: .conferenceID),
            archetypeID: try container.decode(Int.self, forKey: .archetypeID),
            scheme: try container.decode(SchemeIdentity.self, forKey: .scheme),
            prestige: try container.decode(Rating.self, forKey: .prestige),
            rosterIDs: try container.decode([UUID].self, forKey: .rosterIDs),
            scholarshipCount: try container.decode(Int.self, forKey: .scholarshipCount),
            staffIDs: try container.decode([UUID].self, forKey: .staffIDs),
            rivalIDs: try container.decode([UUID].self, forKey: .rivalIDs)
        )
    }

    /// Adds a rivalry, keeping the list at its bound. Strongest first, so the one that drops off is
    /// the weakest.
    public mutating func addRival(_ rivalID: UUID) {
        guard !rivalIDs.contains(rivalID) else { return }
        rivalIDs = Array((rivalIDs + [rivalID]).prefix(SharedRules.rivalriesPerProgramme))
    }

    public var rosterLegality: RosterLegality {
        RosterLegality.college(players: rosterIDs.count, scholarships: scholarshipCount)
    }
}

/// Whether a roster obeys its tier's limits, and which limit it broke.
///
/// A predicate, not an enforcer. P7 and P8 own enforcement; the soak (`03` section 6) asserts this
/// holds at every week boundary, and a boolean with no reason attached is useless to whoever has to
/// fix the roster.
public struct RosterLegality: Sendable, Equatable {
    public enum Violation: String, Sendable, Equatable {
        case overRosterLimit
        case overScholarshipLimit
        case overActiveRosterLimit
        case overPracticeSquadLimit
    }

    public let violations: [Violation]

    public var isLegal: Bool { violations.isEmpty }

    public static func college(players: Int, scholarships: Int) -> RosterLegality {
        var violations: [Violation] = []
        if players > CollegeRules.rosterLimit { violations.append(.overRosterLimit) }
        if scholarships > CollegeRules.scholarshipLimit { violations.append(.overScholarshipLimit) }
        return RosterLegality(violations: violations)
    }

    public static func pro(active: Int, practiceSquad: Int) -> RosterLegality {
        var violations: [Violation] = []
        if active > ProRules.activeRosterLimit { violations.append(.overActiveRosterLimit) }
        if practiceSquad > ProRules.practiceSquadLimit { violations.append(.overPracticeSquadLimit) }
        return RosterLegality(violations: violations)
    }
}
