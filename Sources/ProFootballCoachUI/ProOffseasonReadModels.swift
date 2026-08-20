import Foundation
import FootballSimCore

/// A bounded projection of the authoritative professional market. It carries market actions as
/// values so the view cannot invent a second transaction vocabulary or reconstruct stale IDs.
public struct ProOffseasonReadModel: Sendable, Equatable {
    public static let maximumRows = 64

    public struct CapSummary: Sendable, Equatable {
        public let capLimit: Int
        public let committedCap: Int
        public let remainingCap: Int
        public let deadMoney: Int
        public let activeRosterCount: Int
        public let practiceSquadCount: Int

        public init(snapshot: ProCapSnapshot) {
            capLimit = snapshot.capLimit
            committedCap = snapshot.committedCap
            remainingCap = snapshot.remainingCap
            deadMoney = snapshot.deadMoney
            activeRosterCount = snapshot.activeRosterCount
            practiceSquadCount = snapshot.practiceSquadCount
        }
    }

    public struct ActionRow: Identifiable, Sendable, Equatable {
        public let id: String
        public let title: String
        public let detail: String
        public let action: ProMarketAction
        public let isAvailable: Bool
        public let unavailableReason: String?

        public init(
            id: String,
            title: String,
            detail: String,
            action: ProMarketAction,
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

    public struct ProspectRow: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let name: String
        public let position: String
        public let estimatedOverall: Int?
        public let confidence: Int?
        public let action: ActionRow?

        public init(
            id: UUID,
            name: String,
            position: String,
            estimatedOverall: Int?,
            confidence: Int?,
            action: ActionRow?
        ) {
            self.id = id
            self.name = name
            self.position = position
            self.estimatedOverall = estimatedOverall
            self.confidence = confidence
            self.action = action
        }
    }

    public struct FreeAgentRow: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let name: String
        public let position: String
        public let action: ActionRow?

        public init(id: UUID, name: String, position: String, action: ActionRow?) {
            self.id = id
            self.name = name
            self.position = position
            self.action = action
        }
    }

    public struct WaiverRow: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let playerID: UUID
        public let name: String
        public let deadline: String
        public let action: ActionRow?

        public init(
            id: UUID,
            playerID: UUID,
            name: String,
            deadline: String,
            action: ActionRow?
        ) {
            self.id = id
            self.playerID = playerID
            self.name = name
            self.deadline = deadline
            self.action = action
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let phase: ProMarketPhase
    public let cap: CapSummary
    public let currentPickTeamID: UUID?
    public let nextPick: Int
    public let totalPicks: Int
    public let actions: [ActionRow]
    public let prospects: [ProspectRow]
    public let freeAgents: [FreeAgentRow]
    public let waivers: [WaiverRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        phase: ProMarketPhase,
        cap: CapSummary,
        currentPickTeamID: UUID?,
        nextPick: Int,
        totalPicks: Int,
        actions: [ActionRow],
        prospects: [ProspectRow],
        freeAgents: [FreeAgentRow],
        waivers: [WaiverRow]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.phase = phase
        self.cap = cap
        self.currentPickTeamID = currentPickTeamID
        self.nextPick = max(0, nextPick)
        self.totalPicks = max(0, totalPicks)
        self.actions = Array(actions.prefix(Self.maximumRows))
        self.prospects = Array(prospects.prefix(Self.maximumRows))
        self.freeAgents = Array(freeAgents.prefix(Self.maximumRows))
        self.waivers = Array(waivers.prefix(Self.maximumRows))
    }
}
