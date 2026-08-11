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

public struct ProMarketState: Codable, Sendable, Equatable {
    public static let maximumDraftClassSize = ProRules.draftPickCount
    public static let maximumFreeAgentIDs = 512
    public static let maximumObservations = 8_192

    public private(set) var season: Int
    public private(set) var phase: ProMarketPhase
    public private(set) var draftClass: [ProDraftProspect]
    public private(set) var draftOrder: [UUID]
    public private(set) var nextPick: Int
    public private(set) var draftedProspectIDs: [UUID]
    public private(set) var freeAgentIDs: [UUID]
    public private(set) var observations: [ProDraftObservation]

    public init(
        season: Int = 0,
        phase: ProMarketPhase = .closed,
        draftClass: [ProDraftProspect] = [],
        draftOrder: [UUID] = [],
        nextPick: Int = 0,
        draftedProspectIDs: [UUID] = [],
        freeAgentIDs: [UUID] = [],
        observations: [ProDraftObservation] = []
    ) {
        self.season = max(0, season)
        self.phase = phase
        self.draftClass = Self.canonicalProspects(draftClass)
        self.draftOrder = draftOrder
        self.nextPick = min(max(0, nextPick), self.draftClass.count)
        self.draftedProspectIDs = Self.canonicalIDs(draftedProspectIDs)
        self.freeAgentIDs = Self.canonicalIDs(freeAgentIDs)
        self.observations = Self.canonicalObservations(observations)
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
        guard season >= 0,
              draftClass.count <= Self.maximumDraftClassSize,
              Set(draftClass.map(\.id)).count == draftClass.count,
              draftClass.allSatisfy({ $0.draftSeason == season }),
              draftOrder.count == ProRules.draftPickCount || phase == .closed,
              (0...draftClass.count).contains(nextPick),
              draftedProspectIDs.count == nextPick,
              Set(draftedProspectIDs).count == draftedProspectIDs.count,
              Set(draftedProspectIDs).isSubset(of: Set(draftClass.map(\.id))),
              freeAgentIDs.count <= Self.maximumFreeAgentIDs,
              Set(freeAgentIDs).count == freeAgentIDs.count,
              observations.count <= Self.maximumObservations,
              Self.observationsAreUnique(observations) else {
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
            observations: observations
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
              draftOrder.count == ProRules.draftPickCount,
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
    public mutating func close() -> Bool {
        guard phase == .rosterBuild || phase == .freeAgency || phase == .draft else { return false }
        phase = .closed
        draftClass = []
        draftOrder = []
        nextPick = 0
        draftedProspectIDs = []
        freeAgentIDs = []
        observations = []
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

    private static func observationsAreUnique(_ values: [ProDraftObservation]) -> Bool {
        Set(values.map(\.id)).count == values.count
    }
}
