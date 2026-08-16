import Foundation

/// A bounded, immutable projection of typed world events. Headline text is derived by the
/// simulation history builder; the app never persists or invents a second news authority.
public struct NewsReadModel: Sendable, Equatable {
    public struct Item: Identifiable, Sendable, Equatable {
        public let stableID: String
        public let occurred: String
        public let headline: String
        public let weight: Int

        public var id: String { stableID }

        public init(stableID: String, occurred: String, headline: String, weight: Int) {
            self.stableID = stableID
            self.occurred = occurred
            self.headline = headline
            self.weight = weight
        }
    }

    public static let maximumItems = 64
    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let weekLabel: String
    public let items: [Item]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        weekLabel: String,
        items: [Item]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.weekLabel = weekLabel
        self.items = Array(items.prefix(Self.maximumItems))
    }
}
