import Foundation
import FootballSimCore

/// A bounded view of college-cycle and portal work already held by the authoritative state.
public struct CollegeOffseasonReadModel: Sendable, Equatable {
    public static let maximumDecisions = 8

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let programme: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let seasonLabel: String
    public let recruitingSeason: Int
    public let cyclePhase: RecruitingCyclePhase
    public let portalPhase: CollegePortalPhase
    public let boardCount: Int
    public let scholarshipCount: Int
    public let contactPointsRemaining: Int
    public let nilBudget: Int
    public let nilCommitted: Int
    public let portalEntryCount: Int
    public let delegatedDecisionCount: Int
    public let decisions: [CoachingHQReadModel.Decision]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        programme: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        seasonLabel: String,
        recruitingSeason: Int,
        cyclePhase: RecruitingCyclePhase,
        portalPhase: CollegePortalPhase,
        boardCount: Int,
        scholarshipCount: Int,
        contactPointsRemaining: Int,
        nilBudget: Int,
        nilCommitted: Int,
        portalEntryCount: Int,
        delegatedDecisionCount: Int,
        decisions: [CoachingHQReadModel.Decision]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.programme = programme
        self.coach = coach
        self.seasonLabel = seasonLabel
        self.recruitingSeason = max(0, recruitingSeason)
        self.cyclePhase = cyclePhase
        self.portalPhase = portalPhase
        self.boardCount = max(0, boardCount)
        self.scholarshipCount = max(0, scholarshipCount)
        self.contactPointsRemaining = max(0, contactPointsRemaining)
        self.nilBudget = max(0, nilBudget)
        self.nilCommitted = max(0, nilCommitted)
        self.portalEntryCount = max(0, portalEntryCount)
        self.delegatedDecisionCount = max(0, delegatedDecisionCount)
        self.decisions = Array(decisions.prefix(Self.maximumDecisions))
    }
}
