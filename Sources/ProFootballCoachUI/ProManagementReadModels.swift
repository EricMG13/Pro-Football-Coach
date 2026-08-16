import Foundation
import FootballSimCore

/// Bounded cap and roster-management projection. Mutations remain `ProManagementAction` values
/// and are revalidated by the career actor before they reach the engine.
public struct ProManagementReadModel: Sendable, Equatable {
    public static let maximumRows = 64

    public struct ActionRow: Identifiable, Sendable, Equatable {
        public let id: String
        public let title: String
        public let detail: String
        public let action: ProManagementAction
        public let isAvailable: Bool
        public let unavailableReason: String?

        public init(
            id: String,
            title: String,
            detail: String,
            action: ProManagementAction,
            isAvailable: Bool = true,
            unavailableReason: String? = nil
        ) {
            self.id = id
            self.title = title
            self.detail = detail
            self.action = action
            self.isAvailable = isAvailable
            self.unavailableReason = isAvailable ? nil : unavailableReason
        }
    }

    public struct PlayerRow: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let name: String
        public let position: String
        public let rosterKind: String
        public let capHit: Int
        public let contract: Contract?
        public let action: ActionRow?

        public init(
            id: UUID,
            name: String,
            position: String,
            rosterKind: String,
            capHit: Int,
            contract: Contract? = nil,
            action: ActionRow?
        ) {
            self.id = id
            self.name = name
            self.position = position
            self.rosterKind = rosterKind
            self.capHit = capHit
            self.contract = contract
            self.action = action
        }
    }

    public struct NegotiationRow: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let playerID: UUID
        public let playerName: String
        public let status: ProContractNegotiationStatus
        public let currentOffer: Contract
        public let offerCount: Int
        public let deadline: CalendarState

        public init(
            id: UUID,
            playerID: UUID,
            playerName: String,
            status: ProContractNegotiationStatus,
            currentOffer: Contract,
            offerCount: Int,
            deadline: CalendarState
        ) {
            self.id = id
            self.playerID = playerID
            self.playerName = playerName
            self.status = status
            self.currentOffer = currentOffer
            self.offerCount = offerCount
            self.deadline = deadline
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let calendar: CalendarState
    public let cap: ProOffseasonReadModel.CapSummary
    public let activeRoster: [PlayerRow]
    public let practiceSquad: [PlayerRow]
    public let negotiations: [NegotiationRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        calendar: CalendarState = CalendarState(),
        cap: ProOffseasonReadModel.CapSummary,
        activeRoster: [PlayerRow],
        practiceSquad: [PlayerRow],
        negotiations: [NegotiationRow] = []
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.calendar = calendar
        self.cap = cap
        self.activeRoster = Array(activeRoster.prefix(Self.maximumRows))
        self.practiceSquad = Array(practiceSquad.prefix(Self.maximumRows))
        self.negotiations = Array(negotiations.prefix(Self.maximumRows))
    }
}
