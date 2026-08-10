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

    public var traits: Set<Trait>

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
        traits: Set<Trait> = [],
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
        self.traits = traits
        self.eligibility = eligibility
        self.contract = contract
    }

    public var fullName: String { "\(firstName) \(lastName)" }

    /// Whether age has passed this position's decline threshold (`02` section 5).
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
