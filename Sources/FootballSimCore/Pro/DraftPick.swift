import Foundation

/// A pick in a draft, owned by a club that may not be the one it came from. `02` §4.2c.
///
/// `ProMarketState.draftOrder` was a flat `[UUID]` of team identities, so a pick was a *position in
/// a list* rather than a thing anybody owned. That made three of the professional tier's ordinary
/// mechanics impossible at once: trading a pick, trading a future pick, and knowing whose pick a
/// slot originally was — and the register found no mention of pick trading anywhere in the tree or
/// the documents.
///
/// **Identity comes from the slot, not from a generator.** A pick is fully described by its season,
/// round and the club whose finish earned it, so its identifier is derived from those three rather
/// than drawn: two runs of the same world describe the same picks, and nothing has to be persisted
/// to remember which is which.
public struct DraftPick: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let season: Int
    /// 1-based.
    public let round: Int
    /// The club whose place in the order created this pick. It never changes, which is what lets a
    /// readout say "their second-rounder" years later.
    public let originalTeamID: UUID
    /// Who holds it now.
    public private(set) var ownerID: UUID

    public init(season: Int, round: Int, originalTeamID: UUID, ownerID: UUID? = nil) {
        self.season = max(0, season)
        self.round = max(1, round)
        self.originalTeamID = originalTeamID
        self.ownerID = ownerID ?? originalTeamID
        self.id = DraftPick.identity(season: self.season, round: self.round,
                                     originalTeamID: originalTeamID)
    }

    /// Decoding recomputes the identity rather than trusting it, so a hand-edited save cannot
    /// introduce two picks that claim the same slot.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            season: try container.decode(Int.self, forKey: .season),
            round: try container.decode(Int.self, forKey: .round),
            originalTeamID: try container.decode(UUID.self, forKey: .originalTeamID),
            ownerID: try container.decode(UUID.self, forKey: .ownerID)
        )
    }

    public static func identity(season: Int, round: Int, originalTeamID: UUID) -> UUID {
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.derive(from: SeededRandom.seed(from: originalTeamID),
                                      scope: .season, ordinal: season),
            scope: .scheduler,
            ordinal: round
        ))
        return rng.uuid()
    }

    /// True when the club holding it is not the club it came from.
    public var isTraded: Bool { ownerID != originalTeamID }

    public mutating func transfer(to teamID: UUID) {
        ownerID = teamID
    }
}

/// Builds and reads a season's picks. `02` §4.2c.
public enum DraftPickBook {
    /// Every pick of a season, in order: round by round, and inside a round in the draft order
    /// given.
    ///
    /// - Parameter order: the clubs in draft order, worst first. Its length is the round's size.
    public static func picks(season: Int, order: [UUID], rounds: Int) -> [DraftPick] {
        guard !order.isEmpty else { return [] }
        return (1...max(1, rounds)).flatMap { round in
            order.map { DraftPick(season: season, round: round, originalTeamID: $0) }
        }
    }

    /// Who is on the clock at a given overall pick number, reading ownership rather than the order
    /// the slots were created in. This is the whole point of the type: a traded pick means somebody
    /// else picks there.
    public static func owner(ofPick index: Int, in picks: [DraftPick]) -> UUID? {
        guard index >= 0, index < picks.count else { return nil }
        return picks[index].ownerID
    }

    /// The picks a club holds, in order — its own and any it has acquired.
    public static func held(by teamID: UUID, in picks: [DraftPick]) -> [DraftPick] {
        picks.filter { $0.ownerID == teamID }
    }

    /// Moves a pick between clubs, returning the updated book.
    ///
    /// Refuses a transfer to the club that already holds it, and a pick that is not in the book at
    /// all: both are silent no-ops otherwise, and a trade that silently did nothing is the worst
    /// kind of transaction bug.
    public static func transfer(
        pickID: UUID,
        to teamID: UUID,
        in picks: [DraftPick]
    ) -> [DraftPick]? {
        guard let index = picks.firstIndex(where: { $0.id == pickID }),
              picks[index].ownerID != teamID else { return nil }
        var updated = picks
        updated[index].transfer(to: teamID)
        return updated
    }
}
