import Foundation

public enum ProMarketPhase: String, Codable, Sendable, Equatable, CaseIterable {
    case closed
    case freeAgency
    case draft
    case rosterBuild
}

public struct ProDraftProspect: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let player: Player
    public let draftSeason: Int
    public let originProgrammeID: UUID?

    public init(
        player: Player,
        draftSeason: Int,
        originProgrammeID: UUID? = nil
    ) {
        precondition(
            player.eligibility == nil && player.contract == nil,
            "A draft prospect must be a professional free agent." 
        )
        self.id = player.id
        self.player = player
        self.draftSeason = max(0, draftSeason)
        self.originProgrammeID = originProgrammeID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let player = try container.decode(Player.self, forKey: .player)
        let season = try container.decode(Int.self, forKey: .draftSeason)
        guard season >= 0,
              player.eligibility == nil,
              player.contract == nil else {
            throw DecodingError.dataCorruptedError(
                forKey: .player,
                in: container,
                debugDescription: "A draft prospect has an invalid professional player shape."
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        guard id == player.id else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "A draft prospect key disagrees with its player ID."
            )
        }
        self.player = player
        draftSeason = season
        originProgrammeID = try container.decodeIfPresent(UUID.self, forKey: .originProgrammeID)
    }
}

public struct ProDraftObservation: Codable, Sendable, Equatable, Identifiable {
    public var id: String {
        "\(teamID.uuidString)|\(prospectID.uuidString)|\(season)"
    }

    public let teamID: UUID
    public let prospectID: UUID
    public let season: Int
    public let estimatedOverall: Int
    public let estimatedPotential: Int
    public let confidence: Int
    public let evidenceCount: Int

    public init(
        teamID: UUID,
        prospectID: UUID,
        season: Int,
        estimatedOverall: Int,
        estimatedPotential: Int,
        confidence: Int,
        evidenceCount: Int
    ) {
        self.teamID = teamID
        self.prospectID = prospectID
        self.season = max(0, season)
        self.estimatedOverall = min(max(estimatedOverall, SharedRules.ratingRange.lowerBound), SharedRules.ratingRange.upperBound)
        self.estimatedPotential = min(max(estimatedPotential, SharedRules.ratingRange.lowerBound), SharedRules.ratingRange.upperBound)
        self.confidence = min(max(confidence, 0), 100)
        self.evidenceCount = min(max(evidenceCount, 0), 100)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let season = try container.decode(Int.self, forKey: .season)
        let estimatedOverall = try container.decode(Int.self, forKey: .estimatedOverall)
        let estimatedPotential = try container.decode(Int.self, forKey: .estimatedPotential)
        let confidence = try container.decode(Int.self, forKey: .confidence)
        let evidenceCount = try container.decode(Int.self, forKey: .evidenceCount)
        guard season >= 0,
              SharedRules.ratingRange.contains(estimatedOverall),
              SharedRules.ratingRange.contains(estimatedPotential),
              (0...100).contains(confidence),
              (0...100).contains(evidenceCount) else {
            throw DecodingError.dataCorruptedError(
                forKey: .confidence,
                in: container,
                debugDescription: "Draft scouting evidence is outside its bounds."
            )
        }
        teamID = try container.decode(UUID.self, forKey: .teamID)
        prospectID = try container.decode(UUID.self, forKey: .prospectID)
        self.season = season
        self.estimatedOverall = estimatedOverall
        self.estimatedPotential = estimatedPotential
        self.confidence = confidence
        self.evidenceCount = evidenceCount
    }
}

public struct ProWaiverEntry: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let playerID: UUID
    public let sourceTeamID: UUID
    public let openedAt: CalendarState
    public let claimDeadline: CalendarState

    public init(
        id: UUID,
        playerID: UUID,
        sourceTeamID: UUID,
        openedAt: CalendarState,
        claimDeadline: CalendarState
    ) {
        self.id = id
        self.playerID = playerID
        self.sourceTeamID = sourceTeamID
        self.openedAt = openedAt
        self.claimDeadline = claimDeadline
    }
}

public struct ProMarketState: Codable, Sendable, Equatable {
    public static let maximumDraftClassSize = ProRules.draftPickCount
    public static let maximumFreeAgentIDs = 512
    public static let maximumObservations = 8_192
    public static let maximumArchivedProspectIDs = 4_096
    public static let maximumWaivers = 512
    public static let maximumContractNegotiations = 256

    public private(set) var season: Int
    public private(set) var phase: ProMarketPhase
    public private(set) var draftClass: [ProDraftProspect]
    public private(set) var draftOrder: [UUID]
    public private(set) var nextPick: Int
    public private(set) var draftedProspectIDs: [UUID]
    public private(set) var freeAgentIDs: [UUID]
    public private(set) var observations: [ProDraftObservation]
    public private(set) var archivedDraftProspectIDs: [UUID]
    public private(set) var waivers: [ProWaiverEntry]
    public private(set) var contractNegotiations: [ProContractNegotiation]

    public init(
        season: Int = 0,
        phase: ProMarketPhase = .closed,
        draftClass: [ProDraftProspect] = [],
        draftOrder: [UUID] = [],
        nextPick: Int = 0,
        draftedProspectIDs: [UUID] = [],
        freeAgentIDs: [UUID] = [],
        observations: [ProDraftObservation] = [],
        archivedDraftProspectIDs: [UUID] = [],
        waivers: [ProWaiverEntry] = [],
        contractNegotiations: [ProContractNegotiation] = []
    ) {
        self.season = max(0, season)
        self.phase = phase
        self.draftClass = Self.canonicalProspects(draftClass)
        self.draftOrder = draftOrder
        self.nextPick = min(max(0, nextPick), self.draftClass.count)
        self.draftedProspectIDs = Self.canonicalIDs(draftedProspectIDs)
        self.freeAgentIDs = Self.canonicalIDs(freeAgentIDs)
        self.observations = Self.canonicalObservations(observations)
        self.archivedDraftProspectIDs = Self.canonicalIDs(archivedDraftProspectIDs)
        self.waivers = Self.canonicalWaivers(waivers)
        self.contractNegotiations = Self.canonicalNegotiations(contractNegotiations)
        precondition(isValidShape(proTeamIDs: nil), "Professional market state is invalid.")
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let season = try container.decode(Int.self, forKey: .season)
        let phase = try container.decode(ProMarketPhase.self, forKey: .phase)
        let draftClass = try container.decode([ProDraftProspect].self, forKey: .draftClass)
        let draftOrder = try container.decode([UUID].self, forKey: .draftOrder)
        let nextPick = try container.decode(Int.self, forKey: .nextPick)
        let draftedProspectIDs = try container.decode([UUID].self, forKey: .draftedProspectIDs)
        let freeAgentIDs = try container.decode([UUID].self, forKey: .freeAgentIDs)
        let observations = try container.decode([ProDraftObservation].self, forKey: .observations)
        let archivedDraftProspectIDs = try container.decode(
            [UUID].self,
            forKey: .archivedDraftProspectIDs
        )
        let waivers = try container.decode([ProWaiverEntry].self, forKey: .waivers)
        let contractNegotiations = try container.decodeIfPresent(
            [ProContractNegotiation].self,
            forKey: .contractNegotiations
        ) ?? []
        guard season >= 0,
              draftClass.count <= Self.maximumDraftClassSize,
              Set(draftClass.map(\.id)).count == draftClass.count,
              draftClass.allSatisfy({ $0.draftSeason == season }),
              ProRules.isLegalDraftOrder(draftOrder) || phase == .closed,
              (0...draftClass.count).contains(nextPick),
              draftedProspectIDs.count == nextPick,
              Set(draftedProspectIDs).count == draftedProspectIDs.count,
              Set(draftedProspectIDs).isSubset(of: Set(draftClass.map(\.id))),
              freeAgentIDs.count <= Self.maximumFreeAgentIDs,
              Set(freeAgentIDs).count == freeAgentIDs.count,
              observations.count <= Self.maximumObservations,
              Self.observationsAreUnique(observations),
              archivedDraftProspectIDs.count <= Self.maximumArchivedProspectIDs,
              Set(archivedDraftProspectIDs).count == archivedDraftProspectIDs.count,
              waivers.count <= Self.maximumWaivers,
              Set(waivers.map(\.id)).count == waivers.count,
              Set(waivers.map(\.playerID)).count == waivers.count,
              waivers.allSatisfy({ !$0.claimDeadlineIsBeforeOpened }),
              contractNegotiations.count <= Self.maximumContractNegotiations,
              Set(contractNegotiations.map(\.id)).count == contractNegotiations.count,
              contractNegotiations.allSatisfy({
                  !$0.offerHistory.isEmpty
                      && $0.offerHistory.count <= ProContractNegotiation.maximumOfferHistory
              }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .draftClass,
                in: container,
                debugDescription: "Professional market state is unbounded or inconsistent."
            )
        }
        self.init(
            season: season,
            phase: phase,
            draftClass: draftClass,
            draftOrder: draftOrder,
            nextPick: nextPick,
            draftedProspectIDs: draftedProspectIDs,
            freeAgentIDs: freeAgentIDs,
            observations: observations,
            archivedDraftProspectIDs: archivedDraftProspectIDs,
            waivers: waivers,
            contractNegotiations: contractNegotiations
        )
    }

    public var currentPickTeamID: UUID? {
        guard phase == .draft, nextPick < draftOrder.count else { return nil }
        return draftOrder[nextPick]
    }

    @discardableResult
    public mutating func open(
        season: Int,
        draftClass: [ProDraftProspect],
        draftOrder: [UUID],
        freeAgentIDs: [UUID]
    ) -> Bool {
        guard season >= 0,
              phase == .closed,
              draftClass.count <= Self.maximumDraftClassSize,
              draftClass.count == ProRules.draftPickCount,
              draftClass.allSatisfy({ $0.draftSeason == season }),
              Set(draftClass.map(\.id)).count == draftClass.count,
              ProRules.isLegalDraftOrder(draftOrder),
              freeAgentIDs.count <= Self.maximumFreeAgentIDs,
              Set(freeAgentIDs).count == freeAgentIDs.count else { return false }
        self.season = season
        self.phase = .freeAgency
        self.draftClass = Self.canonicalProspects(draftClass)
        self.draftOrder = draftOrder
        self.nextPick = 0
        self.draftedProspectIDs = []
        self.freeAgentIDs = Self.canonicalIDs(freeAgentIDs)
        self.observations = []
        return true
    }

    @discardableResult
    public mutating func beginDraft() -> Bool {
        guard phase == .freeAgency else { return false }
        phase = .draft
        return true
    }

    @discardableResult
    public mutating func consumeDraftPick(prospectID: UUID) -> Bool {
        guard phase == .draft,
              nextPick < draftClass.count,
              draftClass.contains(where: { $0.id == prospectID }),
              !draftedProspectIDs.contains(prospectID) else { return false }
        draftedProspectIDs.append(prospectID)
        draftedProspectIDs.sort { $0.uuidString < $1.uuidString }
        nextPick += 1
        if nextPick >= draftClass.count { phase = .rosterBuild }
        return true
    }

    @discardableResult
    public mutating func record(_ observation: ProDraftObservation) -> Bool {
        guard phase == .freeAgency || phase == .draft,
              observation.season == season,
              observations.count < Self.maximumObservations else { return false }
        let key = observation.id
        observations.removeAll { $0.id == key }
        observations.append(observation)
        observations.sort { $0.id < $1.id }
        return true
    }

    @discardableResult
    public mutating func removeFreeAgent(_ playerID: UUID) -> Bool {
        guard let index = freeAgentIDs.firstIndex(of: playerID) else { return false }
        freeAgentIDs.remove(at: index)
        return true
    }

    @discardableResult
    public mutating func addFreeAgent(_ playerID: UUID) -> Bool {
        guard freeAgentIDs.count < Self.maximumFreeAgentIDs,
              !freeAgentIDs.contains(playerID) else { return false }
        freeAgentIDs.append(playerID)
        freeAgentIDs.sort { $0.uuidString < $1.uuidString }
        return true
    }

    @discardableResult
    public mutating func addWaiver(_ entry: ProWaiverEntry) -> Bool {
        guard waivers.count < Self.maximumWaivers,
              !waivers.contains(where: { $0.id == entry.id || $0.playerID == entry.playerID }) else {
            return false
        }
        waivers.append(entry)
        waivers.sort { $0.id.uuidString < $1.id.uuidString }
        return true
    }

    @discardableResult
    public mutating func removeWaiver(_ waiverID: UUID) -> ProWaiverEntry? {
        guard let index = waivers.firstIndex(where: { $0.id == waiverID }) else { return nil }
        return waivers.remove(at: index)
    }

    @discardableResult
    public mutating func addContractNegotiation(_ negotiation: ProContractNegotiation) -> Bool {
        guard contractNegotiations.count < Self.maximumContractNegotiations,
              !contractNegotiations.contains(where: { $0.id == negotiation.id }) else {
            return false
        }
        contractNegotiations.append(negotiation)
        contractNegotiations = Self.canonicalNegotiations(contractNegotiations)
        return true
    }

    @discardableResult
    public mutating func updateContractNegotiation(_ negotiation: ProContractNegotiation) -> Bool {
        guard let index = contractNegotiations.firstIndex(where: { $0.id == negotiation.id }) else {
            return false
        }
        contractNegotiations[index] = negotiation
        contractNegotiations = Self.canonicalNegotiations(contractNegotiations)
        return true
    }

    public mutating func expireContractNegotiations(at calendar: CalendarState) {
        for index in contractNegotiations.indices where
            contractNegotiations[index].status.isOpen
                && contractNegotiations[index].isPastDeadline(at: calendar) {
            _ = contractNegotiations[index].settle(as: .expired)
        }
    }

    @discardableResult
    public mutating func close() -> Bool {
        guard phase == .rosterBuild || phase == .freeAgency || phase == .draft else { return false }
        let closedDraftIDs = draftClass.map(\.id)
        phase = .closed
        draftClass = []
        draftOrder = []
        nextPick = 0
        draftedProspectIDs = []
        freeAgentIDs = []
        observations = []
        archivedDraftProspectIDs = Array(
            Self.canonicalIDs(Array(Set(archivedDraftProspectIDs).union(closedDraftIDs)))
                .suffix(Self.maximumArchivedProspectIDs)
        )
        return true
    }

    private func isValidShape(proTeamIDs: Set<UUID>?) -> Bool {
        draftClass.count <= Self.maximumDraftClassSize
            && Set(draftClass.map(\.id)).count == draftClass.count
            && draftClass.allSatisfy { $0.draftSeason == season }
            && (phase == .closed || draftOrder.count == ProRules.draftPickCount)
            && (0...draftClass.count).contains(nextPick)
            && draftedProspectIDs.count == nextPick
            && Set(draftedProspectIDs).count == draftedProspectIDs.count
            && Set(draftedProspectIDs).isSubset(of: Set(draftClass.map(\.id)))
            && freeAgentIDs.count <= Self.maximumFreeAgentIDs
            && Set(freeAgentIDs).count == freeAgentIDs.count
            && observations.count <= Self.maximumObservations
            && Self.observationsAreUnique(observations)
            && archivedDraftProspectIDs.count <= Self.maximumArchivedProspectIDs
            && Set(archivedDraftProspectIDs).count == archivedDraftProspectIDs.count
            && waivers.count <= Self.maximumWaivers
            && Set(waivers.map(\.id)).count == waivers.count
            && Set(waivers.map(\.playerID)).count == waivers.count
            && waivers.allSatisfy { !$0.claimDeadlineIsBeforeOpened }
            && contractNegotiations.count <= Self.maximumContractNegotiations
            && Set(contractNegotiations.map(\.id)).count == contractNegotiations.count
            && contractNegotiations.allSatisfy {
                !$0.offerHistory.isEmpty
                    && $0.offerHistory.count <= ProContractNegotiation.maximumOfferHistory
            }
            && (proTeamIDs.map { Set(draftOrder).isSubset(of: $0) } ?? true)
    }

    private static func canonicalProspects(_ values: [ProDraftProspect]) -> [ProDraftProspect] {
        values.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private static func canonicalIDs(_ values: [UUID]) -> [UUID] {
        values.sorted { $0.uuidString < $1.uuidString }
    }

    private static func canonicalObservations(_ values: [ProDraftObservation]) -> [ProDraftObservation] {
        values.sorted { $0.id < $1.id }
    }

    private static func canonicalWaivers(_ values: [ProWaiverEntry]) -> [ProWaiverEntry] {
        values.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private static func canonicalNegotiations(
        _ values: [ProContractNegotiation]
    ) -> [ProContractNegotiation] {
        values.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private static func observationsAreUnique(_ values: [ProDraftObservation]) -> Bool {
        Set(values.map(\.id)).count == values.count
    }
}

private extension ProWaiverEntry {
    var claimDeadlineIsBeforeOpened: Bool {
        claimDeadline.season < openedAt.season
            || (claimDeadline.season == openedAt.season
                && claimDeadline.week < openedAt.week)
    }
}
