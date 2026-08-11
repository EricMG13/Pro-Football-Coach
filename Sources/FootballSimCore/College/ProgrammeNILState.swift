import Foundation

/// The single seasonal authority for every NIL promise made by one college programme.
/// Zero allocations are represented by absence from the relevant category.
public struct ProgrammeNILState: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { programmeID }
    public let programmeID: UUID
    public let season: Int
    public let annualBudget: Int
    public private(set) var rosterAllocations: [UUID: Int]
    public private(set) var recruitingReservations: [UUID: Int]
    public private(set) var portalReservations: [UUID: Int]

    public var remaining: Int {
        annualBudget - committed
    }

    public init(
        programmeID: UUID,
        season: Int,
        annualBudget: Int,
        rosterAllocations: [UUID: Int] = [:],
        recruitingReservations: [UUID: Int] = [:],
        portalReservations: [UUID: Int] = [:]
    ) {
        precondition(Self.isValid(
            season: season,
            annualBudget: annualBudget,
            rosterAllocations: rosterAllocations,
            recruitingReservations: recruitingReservations,
            portalReservations: portalReservations
        ))
        self.programmeID = programmeID
        self.season = season
        self.annualBudget = annualBudget
        self.rosterAllocations = rosterAllocations
        self.recruitingReservations = recruitingReservations
        self.portalReservations = portalReservations
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .season)
        let decodedBudget = try container.decode(Int.self, forKey: .annualBudget)
        let decodedRoster = try container.decode([UUID: Int].self, forKey: .rosterAllocations)
        let decodedRecruiting = try container.decode(
            [UUID: Int].self,
            forKey: .recruitingReservations
        )
        let decodedPortal = try container.decode(
            [UUID: Int].self,
            forKey: .portalReservations
        )
        guard Self.isValid(
            season: decodedSeason,
            annualBudget: decodedBudget,
            rosterAllocations: decodedRoster,
            recruitingReservations: decodedRecruiting,
            portalReservations: decodedPortal
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .annualBudget,
                in: container,
                debugDescription: "The programme NIL ledger overcommits or duplicates an identity."
            )
        }
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        season = decodedSeason
        annualBudget = decodedBudget
        rosterAllocations = decodedRoster
        recruitingReservations = decodedRecruiting
        portalReservations = decodedPortal
    }

    @discardableResult
    public mutating func setRecruitingReservation(
        _ amount: Int,
        for prospectID: UUID
    ) -> Bool {
        setReservation(
            amount,
            for: prospectID,
            category: .recruiting
        )
    }

    @discardableResult
    public mutating func setPortalReservation(_ amount: Int, for playerID: UUID) -> Bool {
        setReservation(amount, for: playerID, category: .portal)
    }

    @discardableResult
    public mutating func setRosterAllocation(_ amount: Int, for playerID: UUID) -> Bool {
        setReservation(amount, for: playerID, category: .roster)
    }

    @discardableResult
    public mutating func refundRecruitingReservation(for prospectID: UUID) -> Int? {
        recruitingReservations.removeValue(forKey: prospectID)
    }

    @discardableResult
    public mutating func refundPortalReservation(for playerID: UUID) -> Int? {
        portalReservations.removeValue(forKey: playerID)
    }

    /// Moves the exact recruiting promise to the signed player's roster category without changing
    /// committed or remaining money. A missing reservation represents a valid zero-dollar promise.
    @discardableResult
    public mutating func reclassifyRecruitingReservation(
        prospectID: UUID,
        playerID: UUID
    ) -> Bool {
        guard rosterAllocations[playerID] == nil,
              portalReservations[playerID] == nil,
              (prospectID == playerID || rosterAllocations[prospectID] == nil),
              portalReservations[prospectID] == nil else { return false }
        guard let amount = recruitingReservations[prospectID] else {
            return recruitingReservations[playerID] == nil
        }
        var nextRecruiting = recruitingReservations
        var nextRoster = rosterAllocations
        nextRecruiting.removeValue(forKey: prospectID)
        nextRoster[playerID] = amount
        guard Self.isValid(
            season: season,
            annualBudget: annualBudget,
            rosterAllocations: nextRoster,
            recruitingReservations: nextRecruiting,
            portalReservations: portalReservations
        ) else { return false }
        recruitingReservations = nextRecruiting
        rosterAllocations = nextRoster
        return true
    }

    /// Moves the exact portal promise into the accepted player's roster category without changing
    /// committed or remaining money. A missing reservation represents a valid zero-dollar promise.
    @discardableResult
    public mutating func reclassifyPortalReservation(
        for playerID: UUID,
        expectedAmount: Int
    ) -> Bool {
        guard expectedAmount >= 0 else { return false }
        guard rosterAllocations[playerID] == nil,
              recruitingReservations[playerID] == nil else { return false }
        if expectedAmount == 0 {
            return portalReservations[playerID] == nil
        }
        guard portalReservations[playerID] == expectedAmount else { return false }
        var nextRoster = rosterAllocations
        var nextPortal = portalReservations
        nextPortal.removeValue(forKey: playerID)
        nextRoster[playerID] = expectedAmount
        guard Self.isValid(
            season: season,
            annualBudget: annualBudget,
            rosterAllocations: nextRoster,
            recruitingReservations: recruitingReservations,
            portalReservations: nextPortal
        ) else { return false }
        rosterAllocations = nextRoster
        portalReservations = nextPortal
        return true
    }

    @discardableResult
    public mutating func removeRosterAllocation(for playerID: UUID) -> Int? {
        rosterAllocations.removeValue(forKey: playerID)
    }

    mutating func retainRosterAllocations(for playerIDs: Set<UUID>) {
        rosterAllocations = rosterAllocations.filter { playerIDs.contains($0.key) }
    }

    var isValid: Bool {
        Self.isValid(
            season: season,
            annualBudget: annualBudget,
            rosterAllocations: rosterAllocations,
            recruitingReservations: recruitingReservations,
            portalReservations: portalReservations
        )
    }

    private enum ReservationCategory {
        case roster
        case recruiting
        case portal
    }

    private var committed: Int {
        rosterAllocations.values.reduce(0, +)
            + recruitingReservations.values.reduce(0, +)
            + portalReservations.values.reduce(0, +)
    }

    private mutating func setReservation(
        _ amount: Int,
        for identityID: UUID,
        category: ReservationCategory
    ) -> Bool {
        guard amount >= 0 else { return false }
        switch category {
        case .roster:
            guard recruitingReservations[identityID] == nil,
                  portalReservations[identityID] == nil else { return false }
        case .recruiting:
            guard rosterAllocations[identityID] == nil,
                  portalReservations[identityID] == nil else { return false }
        case .portal:
            guard rosterAllocations[identityID] == nil,
                  recruitingReservations[identityID] == nil else { return false }
        }

        var nextRoster = rosterAllocations
        var nextRecruiting = recruitingReservations
        var nextPortal = portalReservations
        switch category {
        case .roster:
            if amount == 0 {
                nextRoster.removeValue(forKey: identityID)
            } else {
                nextRoster[identityID] = amount
            }
        case .recruiting:
            if amount == 0 {
                nextRecruiting.removeValue(forKey: identityID)
            } else {
                nextRecruiting[identityID] = amount
            }
        case .portal:
            if amount == 0 {
                nextPortal.removeValue(forKey: identityID)
            } else {
                nextPortal[identityID] = amount
            }
        }
        guard Self.isValid(
            season: season,
            annualBudget: annualBudget,
            rosterAllocations: nextRoster,
            recruitingReservations: nextRecruiting,
            portalReservations: nextPortal
        ) else { return false }
        rosterAllocations = nextRoster
        recruitingReservations = nextRecruiting
        portalReservations = nextPortal
        return true
    }

    private static func isValid(
        season: Int,
        annualBudget: Int,
        rosterAllocations: [UUID: Int],
        recruitingReservations: [UUID: Int],
        portalReservations: [UUID: Int]
    ) -> Bool {
        let rosterIDs = Set(rosterAllocations.keys)
        let recruitingIDs = Set(recruitingReservations.keys)
        let portalIDs = Set(portalReservations.keys)
        let values = Array(rosterAllocations.values)
            + Array(recruitingReservations.values)
            + Array(portalReservations.values)
        return season >= 0
            && (0...CollegeRules.maximumNILBudget).contains(annualBudget)
            && rosterAllocations.count <= CollegeRules.rosterLimit
            && recruitingReservations.count <= CollegeRules.recruitingBoardLimit
            && portalReservations.count <= CollegeRules.maximumPortalNILReservations
            && values.allSatisfy { (1...CollegeRules.maximumNILBudget).contains($0) }
            && rosterIDs.isDisjoint(with: recruitingIDs)
            && rosterIDs.isDisjoint(with: portalIDs)
            && recruitingIDs.isDisjoint(with: portalIDs)
            && values.reduce(0, +) <= annualBudget
    }
}
