import Foundation

/// A bounded, immutable view of work and typed stories that arrived for the controlled team.
/// Mandatory decisions remain the authoritative actionable items; ledger stories are read-only.
public struct InboxReadModel: Sendable, Equatable {
    public enum ItemKind: String, Sendable, Equatable {
        case decision
        case task
        case story
    }

    public struct Item: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let kind: ItemKind
        public let sourceLabel: String
        public let title: String
        public let body: String
        public let received: String
        public let deadline: String?
        public let isUnread: Bool
        public let destination: CoachWorldScreenID?

        public var id: String { stableID }

        public init(
            stableID: String,
            kind: ItemKind,
            sourceLabel: String,
            title: String,
            body: String,
            received: String,
            deadline: String?,
            isUnread: Bool,
            destination: CoachWorldScreenID?
        ) {
            self.stableID = stableID
            self.kind = kind
            self.sourceLabel = sourceLabel
            self.title = title
            self.body = body
            self.received = received
            self.deadline = deadline
            self.isUnread = isUnread
            self.destination = destination
        }
    }

    public static let maximumItems = 64

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let weekLabel: String
    public let items: [Item]
    public let canContinue: Bool
    public let continueReason: String?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        weekLabel: String,
        items: [Item],
        canContinue: Bool,
        continueReason: String?
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.weekLabel = weekLabel
        self.items = Array(items.prefix(Self.maximumItems))
        self.canContinue = canContinue
        self.continueReason = continueReason
    }

    public func markingRead(_ stableID: String) -> Self {
        Self(
            snapshotID: snapshotID,
            provenance: provenance,
            world: world,
            team: team,
            coach: coach,
            weekLabel: weekLabel,
            items: items.map { item in
                guard item.stableID == stableID else { return item }
                return Item(
                    stableID: item.stableID,
                    kind: item.kind,
                    sourceLabel: item.sourceLabel,
                    title: item.title,
                    body: item.body,
                    received: item.received,
                    deadline: item.deadline,
                    isUnread: false,
                    destination: item.destination
                )
            },
            canContinue: canContinue,
            continueReason: continueReason
        )
    }
}
