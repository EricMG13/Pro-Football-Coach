import Foundation

/// A bounded projection of the readiness facts already held by player lifecycle state.
/// It deliberately contains no diagnosis or recommendation that the rules do not produce.
public struct TeamHealthReadModel: Sendable, Equatable {
    public struct PlayerStatus: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let name: String
        public let position: String
        public let condition: Int
        public let fatigue: Int
        public let availability: String
        public let statusDetail: String

        public var id: String { stableID }

        public init(
            stableID: String,
            name: String,
            position: String,
            condition: Int,
            fatigue: Int,
            availability: String,
            statusDetail: String
        ) {
            self.stableID = stableID
            self.name = name
            self.position = position
            self.condition = min(max(condition, 0), 100)
            self.fatigue = min(max(fatigue, 0), 100)
            self.availability = availability
            self.statusDetail = statusDetail
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let weekLabel: String
    public let averageCondition: Int
    public let averageFatigue: Int
    public let injuryCount: Int
    public let suspensionCount: Int
    public let players: [PlayerStatus]
    public let canContinue: Bool
    public let continueReason: String?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        weekLabel: String,
        averageCondition: Int,
        averageFatigue: Int,
        injuryCount: Int,
        suspensionCount: Int,
        players: [PlayerStatus],
        canContinue: Bool,
        continueReason: String?
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.weekLabel = weekLabel
        self.averageCondition = min(max(averageCondition, 0), 100)
        self.averageFatigue = min(max(averageFatigue, 0), 100)
        self.injuryCount = max(0, injuryCount)
        self.suspensionCount = max(0, suspensionCount)
        self.players = Array(players.prefix(128))
        self.canContinue = canContinue
        self.continueReason = continueReason
    }
}
