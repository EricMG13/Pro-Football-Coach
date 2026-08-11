import Foundation

public enum RecruitingPitch: String, Codable, Sendable, CaseIterable, Hashable {
    case proximity
    case prestige
    case playingTime
    case schemeFit
    case relationship
    case staffQuality
    case teamSuccess
    case nilOpportunity
}

/// An unsigned generated college player identity. Signing converts this identity into `Player`
/// state; portal entrants remain existing players and never become prospects again.
public struct Prospect: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let position: Position
    public let age: Int
    public let originCityID: UUID
    public let attributes: Attributes
    public let potential: Rating
    public let traits: [Trait]
    public let priorities: [RecruitingPitch: Rating]

    public init(
        id: UUID,
        firstName: String,
        lastName: String,
        position: Position,
        age: Int,
        originCityID: UUID,
        attributes: Attributes,
        potential: Rating,
        traits: [Trait],
        priorities: [RecruitingPitch: Rating]
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.position = position
        self.age = min(max(age, CollegeRules.prospectAgeRange.lowerBound),
                       CollegeRules.prospectAgeRange.upperBound)
        self.originCityID = originCityID
        self.attributes = attributes
        self.potential = potential
        self.traits = Prospect.canonicalised(traits)
        self.priorities = priorities
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedAge = try container.decode(Int.self, forKey: .age)
        guard CollegeRules.prospectAgeRange.contains(decodedAge) else {
            throw DecodingError.dataCorruptedError(
                forKey: .age,
                in: container,
                debugDescription: "Prospect age is outside the college recruiting range."
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        position = try container.decode(Position.self, forKey: .position)
        age = decodedAge
        originCityID = try container.decode(UUID.self, forKey: .originCityID)
        attributes = try container.decode(Attributes.self, forKey: .attributes)
        potential = try container.decode(Rating.self, forKey: .potential)
        let decodedTraits = try container.decode([Trait].self, forKey: .traits)
        guard decodedTraits == Prospect.canonicalised(decodedTraits) else {
            throw DecodingError.dataCorruptedError(
                forKey: .traits,
                in: container,
                debugDescription: "Prospect traits must be unique and in Trait.allCases order."
            )
        }
        traits = decodedTraits
        priorities = try container.decode([RecruitingPitch: Rating].self, forKey: .priorities)
    }

    private static func canonicalised(_ traits: [Trait]) -> [Trait] {
        Trait.allCases.filter(traits.contains)
    }

    public var fullName: String { "\(firstName) \(lastName)" }

    public var overall: Rating {
        let rated = position.ratedAttributes
        guard !rated.isEmpty else { return Rating(SharedRules.ratingRange.lowerBound) }
        let total = rated.reduce(0) { $0 + attributes[$1].value }
        return Rating(total / rated.count)
    }
}

/// Compact identity retained only while bounded history still references a prospect who did not
/// become a player. Signed prospects continue under their player identity instead.
public struct ArchivedProspectIdentity: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let position: Position
    public let originCityID: UUID
    public let recruitingSeason: Int

    public init(prospect: Prospect, recruitingSeason: Int) {
        id = prospect.id
        firstName = prospect.firstName
        lastName = prospect.lastName
        position = prospect.position
        originCityID = prospect.originCityID
        self.recruitingSeason = max(0, recruitingSeason)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .recruitingSeason)
        guard decodedSeason >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .recruitingSeason,
                in: container,
                debugDescription: "Archived prospect season cannot be negative."
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        position = try container.decode(Position.self, forKey: .position)
        originCityID = try container.decode(UUID.self, forKey: .originCityID)
        recruitingSeason = decodedSeason
    }
}
