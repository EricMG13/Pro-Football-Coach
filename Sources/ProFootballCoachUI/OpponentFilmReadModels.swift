import Foundation

/// Observer-scoped opponent evidence retained by the tactical authority. A nil observation is an
/// honest unavailable state; it is never replaced with hidden league totals.
public struct OpponentFilmReadModel: Sendable, Equatable {
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let team: CoachWorldTeamReference
    public let opponent: CoachWorldTeamReference?
    public let weekLabel: String
    public let sourceGameCount: Int
    public let confidence: Int
    public let passRate: Int
    public let turnoverRate: Int
    public let sourceFixtureCount: Int
    public let isCurrent: Bool
    public let unavailableReason: String?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        team: CoachWorldTeamReference,
        opponent: CoachWorldTeamReference?,
        weekLabel: String,
        sourceGameCount: Int,
        confidence: Int,
        passRate: Int,
        turnoverRate: Int,
        sourceFixtureCount: Int,
        isCurrent: Bool,
        unavailableReason: String?
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.team = team
        self.opponent = opponent
        self.weekLabel = weekLabel
        self.sourceGameCount = max(0, sourceGameCount)
        self.confidence = min(max(confidence, 0), 100)
        self.passRate = min(max(passRate, 0), 100)
        self.turnoverRate = min(max(turnoverRate, 0), 100)
        self.sourceFixtureCount = min(max(sourceFixtureCount, 0), 32)
        self.isCurrent = isCurrent
        self.unavailableReason = unavailableReason
    }
}
