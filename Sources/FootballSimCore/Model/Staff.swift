import Foundation

/// A staff role. `02-GAME-DESIGN.md` section 6: four coordinators plus position coaches.
public enum StaffRole: String, Codable, Sendable, CaseIterable, Hashable {
    case headCoach
    case offensiveCoordinator
    case defensiveCoordinator
    case specialTeamsCoordinator
    case strengthCoordinator
    case positionCoach

    /// The four `SharedRules.coordinatorCount` refers to.
    public static let coordinators: [StaffRole] = [
        .offensiveCoordinator, .defensiveCoordinator, .specialTeamsCoordinator, .strengthCoordinator,
    ]
}

/// What a coach is rated on. `02` section 6 names these four exactly.
public enum CoachAttribute: String, Codable, Sendable, CaseIterable, Hashable {
    case development, recruiting, gamePlanning, schemeAffinity
}

/// A member of staff.
///
/// Continuity is a resource (`02` section 6): staff are poached when they perform, and the
/// `seasonsWithProgramme` counter is what a continuity effect reads. P9 owns the poaching.
public struct Staff: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var role: StaffRole

    /// Set only for a position coach, and the group they coach.
    public var positionGroup: PositionGroup?

    public var ratings: [CoachAttribute: Rating]

    /// The scheme this coach runs best. Scheme affinity modifies fit when it matches the
    /// programme's identity.
    public var preferredOffense: OffensiveScheme?
    public var preferredDefense: DefensiveScheme?

    public var seasonsWithProgramme: Int

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        role: StaffRole,
        positionGroup: PositionGroup? = nil,
        ratings: [CoachAttribute: Rating] = [:],
        preferredOffense: OffensiveScheme? = nil,
        preferredDefense: DefensiveScheme? = nil,
        seasonsWithProgramme: Int = 0
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.positionGroup = positionGroup
        self.ratings = ratings
        self.preferredOffense = preferredOffense
        self.preferredDefense = preferredDefense
        self.seasonsWithProgramme = seasonsWithProgramme
    }

    public var fullName: String { "\(firstName) \(lastName)" }

    /// An unrated coach attribute reads at the bottom of the scale, for the same reason an unset
    /// player attribute does: zero is not a legal rating.
    public func rating(_ attribute: CoachAttribute) -> Rating {
        ratings[attribute] ?? Rating(SharedRules.ratingRange.lowerBound)
    }
}
