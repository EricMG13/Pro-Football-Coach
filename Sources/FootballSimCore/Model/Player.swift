import Foundation

/// A player, in either tier.
///
/// One type rather than two. The tier-specific parts are optional and mutually exclusive in
/// practice — a college player has an `eligibility` clock and no `contract`, a pro player the
/// reverse — because `02-GAME-DESIGN.md` section 9 carries a career across the two tiers and a
/// hard type split makes every readout that spans them a conversion.
///
/// `Model/` is the one directory the ambient-identity source scan exempts (`03` section 3.5), so
/// `id: UUID = UUID()` is legal here. Engine construction still passes `rng.uuid()` explicitly;
/// the default exists for tests and for surfaces building a throwaway.
public struct Player: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var position: Position
    public var age: Int

    public var attributes: Attributes

    /// Hidden from the player, estimated with a confidence band by the surfaces that show it
    /// (`02` section 5). The model stores the truth; the fog is the reader's business.
    public var potential: Rating

    /// An array, deliberately, and kept in `Trait.allCases` order.
    ///
    /// This was a `Set<Trait>` and that was a cross-process determinism bug. `Set` encodes to an
    /// *unkeyed* container in iteration order; `JSONEncoder.stable()`'s `.sortedKeys` orders object
    /// keys and does nothing to array elements; and Swift's hash seed is per-launch. So one player
    /// with two traits produced different save bytes every launch, on the most-instantiated type in
    /// the save. Nothing could see it: `Set` equality is order-independent, so a round-trip test
    /// passes, and within one process the order is constant, so a repeat-encode test passes too.
    ///
    /// `ContractTests` now bans `Set<` as a stored property in `Model/` so this cannot come back.
    public private(set) var traits: [Trait]

    /// College only.
    public var eligibility: Eligibility?

    /// Pro only.
    public var contract: Contract?

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        position: Position,
        age: Int,
        attributes: Attributes,
        potential: Rating,
        traits: [Trait] = [],
        eligibility: Eligibility? = nil,
        contract: Contract? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.position = position
        self.age = age
        self.attributes = attributes
        self.potential = potential
        self.traits = Player.canonicalised(traits)
        self.eligibility = eligibility
        self.contract = contract
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            firstName: try container.decode(String.self, forKey: .firstName),
            lastName: try container.decode(String.self, forKey: .lastName),
            position: try container.decode(Position.self, forKey: .position),
            age: try container.decode(Int.self, forKey: .age),
            attributes: try container.decode(Attributes.self, forKey: .attributes),
            potential: try container.decode(Rating.self, forKey: .potential),
            traits: try container.decode([Trait].self, forKey: .traits),
            eligibility: try container.decodeIfPresent(Eligibility.self, forKey: .eligibility),
            contract: try container.decodeIfPresent(Contract.self, forKey: .contract)
        )
    }

    /// Deduplicated and put in a fixed order, so the encoded bytes are the same whatever order the
    /// caller supplied. Routing the decoder through the same initialiser means a save written
    /// before this rule existed is canonicalised on load rather than carried forward.
    private static func canonicalised(_ traits: [Trait]) -> [Trait] {
        Trait.allCases.filter(traits.contains)
    }

    public func has(_ trait: Trait) -> Bool { traits.contains(trait) }

    public mutating func add(_ trait: Trait) {
        traits = Player.canonicalised(traits + [trait])
    }

    public mutating func remove(_ trait: Trait) {
        traits.removeAll { $0 == trait }
    }

    public var fullName: String { "\(firstName) \(lastName)" }

    /// Whether age has passed this position's decline threshold (`02` section 11.3.2).
    public var isDeclining: Bool { age >= position.declineAge }

    /// The mean of the attributes this position's matchups actually read.
    ///
    /// Averaging every attribute would rate a quarterback on their coverage. The engine reads
    /// individual attributes; this exists for depth charts and readouts that need one number.
    public var overall: Rating {
        let rated = position.ratedAttributes
        guard !rated.isEmpty else { return Rating(SharedRules.ratingRange.lowerBound) }
        let total = rated.reduce(0) { $0 + attributes[$1].value }
        return Rating(total / rated.count)
    }
}
