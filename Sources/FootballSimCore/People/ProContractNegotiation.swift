import Foundation

public enum ProContractNegotiationStatus: String, Codable, Sendable, Equatable {
    case offered
    case countered
    case accepted
    case rejected
    case withdrawn
    case expired

    public var isOpen: Bool {
        self == .offered || self == .countered
    }
}

/// A bounded, durable offer ledger for one professional player and team.
public struct ProContractNegotiation: Codable, Sendable, Equatable, Identifiable {
    public static let maximumOfferHistory = 8

    public let id: UUID
    public let playerID: UUID
    public let teamID: UUID
    public let openedAt: CalendarState
    public let deadline: CalendarState
    public private(set) var offerHistory: [Contract]
    public private(set) var status: ProContractNegotiationStatus

    public var currentOffer: Contract { offerHistory[offerHistory.count - 1] }

    public init(
        id: UUID,
        playerID: UUID,
        teamID: UUID,
        openedAt: CalendarState,
        deadline: CalendarState,
        offerHistory: [Contract],
        status: ProContractNegotiationStatus = .offered
    ) {
        precondition(
            !offerHistory.isEmpty && offerHistory.count <= Self.maximumOfferHistory,
            "A negotiation needs a bounded offer history."
        )
        precondition(deadline.isOnOrAfter(openedAt), "A negotiation deadline cannot precede its opening.")
        self.id = id
        self.playerID = playerID
        self.teamID = teamID
        self.openedAt = openedAt
        self.deadline = deadline
        self.offerHistory = offerHistory
        self.status = status
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let offerHistory = try container.decode([Contract].self, forKey: .offerHistory)
        let openedAt = try container.decode(CalendarState.self, forKey: .openedAt)
        let deadline = try container.decode(CalendarState.self, forKey: .deadline)
        guard !offerHistory.isEmpty,
              offerHistory.count <= Self.maximumOfferHistory,
              offerHistory.allSatisfy(Self.isValidContract),
              deadline.isOnOrAfter(openedAt) else {
            throw DecodingError.dataCorruptedError(
                forKey: .offerHistory,
                in: container,
                debugDescription: "The professional negotiation is outside its bounded contract shape."
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        playerID = try container.decode(UUID.self, forKey: .playerID)
        teamID = try container.decode(UUID.self, forKey: .teamID)
        self.openedAt = openedAt
        self.deadline = deadline
        self.offerHistory = offerHistory
        status = try container.decode(ProContractNegotiationStatus.self, forKey: .status)
    }

    public func isPastDeadline(at calendar: CalendarState) -> Bool {
        calendar.isAfter(deadline)
    }

    @discardableResult
    public mutating func counter(with contract: Contract) -> Bool {
        guard status.isOpen,
              offerHistory.count < Self.maximumOfferHistory,
              Self.isValidContract(contract) else { return false }
        offerHistory.append(contract)
        status = .countered
        return true
    }

    @discardableResult
    public mutating func settle(as status: ProContractNegotiationStatus) -> Bool {
        guard self.status.isOpen,
              status == .accepted || status == .rejected
                    || status == .withdrawn || status == .expired else { return false }
        self.status = status
        return true
    }

    private static func isValidContract(_ contract: Contract) -> Bool {
        guard ProRules.contractYearsRange.contains(contract.years),
              contract.baseSalaryByYear.count == contract.years,
              contract.baseSalaryByYear.allSatisfy({ $0 >= 0 }),
              contract.signingBonus >= 0 else { return false }
        return (0..<contract.years).allSatisfy { year in
            contract.baseSalaryByYear[year]
                <= Int.max - contract.bonusProration(inYear: year)
        }
    }
}

public extension CalendarState {
    func isAfter(_ other: CalendarState) -> Bool {
        season > other.season || (season == other.season && week > other.week)
    }

    func isOnOrAfter(_ other: CalendarState) -> Bool {
        self == other || isAfter(other)
    }
}
