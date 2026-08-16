import Foundation
import FootballSimCore

public struct StaffRoomReadModel: Sendable, Equatable {
    public static let maximumRows = 32

    public struct StaffRow: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let name: String
        public let role: String
        public let age: Int
        public let reputation: Int
        public let development: Int
        public let recruiting: Int
        public let gamePlanning: Int
        public let schemeAffinity: Int
        public let seasonsWithProgramme: Int

        public init(staff: Staff) {
            id = staff.id
            name = staff.fullName
            role = Self.roleLabel(staff.role)
            age = staff.age
            reputation = staff.reputation.value
            development = staff.rating(.development).value
            recruiting = staff.rating(.recruiting).value
            gamePlanning = staff.rating(.gamePlanning).value
            schemeAffinity = staff.rating(.schemeAffinity).value
            seasonsWithProgramme = staff.seasonsWithProgramme
        }

        private static func roleLabel(_ role: StaffRole) -> String {
            switch role {
            case .headCoach: return "Head coach"
            case .offensiveCoordinator: return "Offensive coordinator"
            case .defensiveCoordinator: return "Defensive coordinator"
            case .specialTeamsCoordinator: return "Special teams coordinator"
            case .strengthCoordinator: return "Strength coordinator"
            case .positionCoach: return "Position coach"
            }
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let rows: [StaffRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        rows: [StaffRow]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.rows = Array(rows.prefix(Self.maximumRows))
    }
}
