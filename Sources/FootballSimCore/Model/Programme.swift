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

    /// The rivalries this programme carries, strongest first. Bounded — `CLAUDE.md` requires every
    /// collection that can grow across seasons to state one, and rivalry strength accumulates for
    /// a whole career.
    public var rivalIDs: [UUID]

    public static let rivalLimit = 8

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
        self.rivalIDs = Array(rivalIDs.prefix(Programme.rivalLimit))
    }

    public var rosterLegality: RosterLegality {
        RosterLegality.college(players: rosterIDs.count, scholarships: scholarshipCount)
    }
}

/// A pro team.
public struct ProTeam: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var nickname: String
    public var cityName: String
    public var conferenceID: UUID?
    public var divisionID: UUID?

    public var scheme: SchemeIdentity
    public var prestige: Rating

    public var rosterIDs: [UUID]
    public var practiceSquadIDs: [UUID]
    public var staffIDs: [UUID]

    /// Charged against the cap for players no longer on the roster. P8 owns how it gets here;
    /// `Contract.deadMoney(ifReleasedBeforeYear:)` owns how much.
    public var deadMoney: Int

    public init(
        id: UUID = UUID(),
        name: String,
        nickname: String,
        cityName: String,
        conferenceID: UUID? = nil,
        divisionID: UUID? = nil,
        scheme: SchemeIdentity,
        prestige: Rating,
        rosterIDs: [UUID] = [],
        practiceSquadIDs: [UUID] = [],
        staffIDs: [UUID] = [],
        deadMoney: Int = 0
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.cityName = cityName
        self.conferenceID = conferenceID
        self.divisionID = divisionID
        self.scheme = scheme
        self.prestige = prestige
        self.rosterIDs = rosterIDs
        self.practiceSquadIDs = practiceSquadIDs
        self.staffIDs = staffIDs
        self.deadMoney = deadMoney
    }

    public var rosterLegality: RosterLegality {
        RosterLegality.pro(active: rosterIDs.count, practiceSquad: practiceSquadIDs.count)
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
