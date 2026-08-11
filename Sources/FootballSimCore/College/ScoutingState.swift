import Foundation

public struct ScoutingAssignment: Codable, Sendable, Equatable, Hashable {
    public let observerID: UUID
    public let prospectID: UUID
    public let effort: Int

    public init(observerID: UUID, prospectID: UUID, effort: Int) {
        self.observerID = observerID
        self.prospectID = prospectID
        self.effort = min(max(1, effort), CollegeRules.weeklyRecruitingContactPoints)
    }
}

public struct ProspectObservation: Codable, Sendable, Equatable {
    public let prospectID: UUID
    public let estimatedAttributes: [Attribute: Rating]
    public let estimatedPotential: Rating
    public let confidence: Int
    public let lastUpdated: CalendarState
    public let evidenceCount: Int

    public init(
        prospectID: UUID,
        estimatedAttributes: [Attribute: Rating],
        estimatedPotential: Rating,
        confidence: Int,
        lastUpdated: CalendarState,
        evidenceCount: Int
    ) {
        self.prospectID = prospectID
        self.estimatedAttributes = estimatedAttributes
        self.estimatedPotential = estimatedPotential
        self.confidence = min(max(confidence, CollegeRules.knowledgeConfidenceRange.lowerBound),
                              CollegeRules.knowledgeConfidenceRange.upperBound)
        self.lastUpdated = lastUpdated
        self.evidenceCount = min(max(0, evidenceCount), CollegeRules.maximumScoutingEvidence)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedConfidence = try container.decode(Int.self, forKey: .confidence)
        let decodedEvidence = try container.decode(Int.self, forKey: .evidenceCount)
        guard CollegeRules.knowledgeConfidenceRange.contains(decodedConfidence),
              (0...CollegeRules.maximumScoutingEvidence).contains(decodedEvidence) else {
            throw DecodingError.dataCorruptedError(
                forKey: .confidence,
                in: container,
                debugDescription: "Prospect observation confidence or evidence is out of bounds."
            )
        }
        prospectID = try container.decode(UUID.self, forKey: .prospectID)
        estimatedAttributes = try container.decode(
            [Attribute: Rating].self,
            forKey: .estimatedAttributes
        )
        estimatedPotential = try container.decode(Rating.self, forKey: .estimatedPotential)
        confidence = decodedConfidence
        lastUpdated = try container.decode(CalendarState.self, forKey: .lastUpdated)
        evidenceCount = decodedEvidence
    }

    public func estimatedAttribute(_ attribute: Attribute) -> Rating {
        estimatedAttributes[attribute] ?? Rating(SharedRules.ratingRange.lowerBound)
    }
}

public struct ScoutingState: Codable, Sendable, Equatable {
    public private(set) var observationsByObserver: [UUID: [UUID: ProspectObservation]]
    public private(set) var pendingEvaluations: [ScoutingAssignment]
    public private(set) var portalKnowledgeByObserver: [UUID: [CollegePortalKnowledgeSnapshot]]

    public init(
        observationsByObserver: [UUID: [UUID: ProspectObservation]] = [:],
        pendingEvaluations: [ScoutingAssignment] = [],
        portalKnowledgeByObserver: [UUID: [CollegePortalKnowledgeSnapshot]] = [:]
    ) {
        let canonicalPortalKnowledge = portalKnowledgeByObserver.mapValues(Self.canonical)
        precondition(Self.portalKnowledgeIsValid(canonicalPortalKnowledge))
        self.observationsByObserver = observationsByObserver
        self.pendingEvaluations = Array(
            pendingEvaluations.prefix(CollegeRules.maximumPendingEvaluations)
        )
        self.portalKnowledgeByObserver = canonicalPortalKnowledge
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode(
            [UUID: [UUID: ProspectObservation]].self,
            forKey: .observationsByObserver
        )
        let decodedPending = try container.decode(
            [ScoutingAssignment].self,
            forKey: .pendingEvaluations
        )
        let decodedPortalKnowledge = try container.decode(
            [UUID: [CollegePortalKnowledgeSnapshot]].self,
            forKey: .portalKnowledgeByObserver
        )
        guard decoded.values.allSatisfy({ observations in
            observations.count <= CollegeRules.maximumObservationsPerProgramme
                && observations.allSatisfy { $0.key == $0.value.prospectID }
        }), decodedPending.count <= CollegeRules.maximumPendingEvaluations,
            decodedPending.allSatisfy({
                (1...CollegeRules.weeklyRecruitingContactPoints).contains($0.effort)
            }),
            Self.portalKnowledgeIsValid(decodedPortalKnowledge),
            decodedPortalKnowledge.allSatisfy({ _, snapshots in
                snapshots == Self.canonical(snapshots)
            }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .observationsByObserver,
                in: container,
                debugDescription: "Scouting observations violate identity or collection bounds."
            )
        }
        observationsByObserver = decoded
        pendingEvaluations = decodedPending
        portalKnowledgeByObserver = decodedPortalKnowledge
    }

    public func observation(observerID: UUID, prospectID: UUID) -> ProspectObservation? {
        observationsByObserver[observerID]?[prospectID]
    }

    public func portalKnowledge(
        observerProgrammeID: UUID,
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow
    ) -> CollegePortalKnowledgeSnapshot? {
        portalKnowledgeByObserver[observerProgrammeID]?.first {
            $0.playerID == playerID
                && $0.sourceProgrammeID == sourceProgrammeID
                && $0.targetSeason == targetSeason
                && $0.window == window
        }
    }

    @discardableResult
    package mutating func recordPortalKnowledge(
        _ snapshot: CollegePortalKnowledgeSnapshot
    ) -> Bool {
        let observerID = snapshot.observerProgrammeID
        if let currentTargetSeason = portalKnowledgeTargetSeason,
           currentTargetSeason != snapshot.targetSeason {
            return false
        }
        var snapshots = portalKnowledgeByObserver[observerID] ?? []
        if let existing = snapshots.first(where: {
            Self.samePortalKnowledgeIdentity($0, snapshot)
        }) {
            return existing == snapshot
        }
        guard portalKnowledgeByObserver[observerID] != nil
                || portalKnowledgeByObserver.count
                    < CollegePortalPolicyV1.maximumKnowledgeObservers,
              snapshots.filter({
                  $0.targetSeason == snapshot.targetSeason && $0.window == snapshot.window
              }).count < CollegePortalPolicyV1.maximumKnowledgePerObserverWindow
        else { return false }
        snapshots.append(snapshot)
        portalKnowledgeByObserver[observerID] = Self.canonical(snapshots)
        return true
    }

    @discardableResult
    package mutating func recordPortalKnowledgeBatch<S: Sequence>(
        _ newSnapshots: S,
        targetSeason: Int,
        window: CollegePortalWindow
    ) -> Bool where S.Element == CollegePortalKnowledgeSnapshot {
        let proposed = Array(newSnapshots)
        guard targetSeason >= 0,
              proposed.allSatisfy({
                  $0.targetSeason == targetSeason && $0.window == window
              }),
              portalKnowledgeTargetSeason.map({ $0 == targetSeason }) ?? true
        else { return false }

        var unique = Dictionary(
            uniqueKeysWithValues: proposed.prefix(1).map { (Self.identity($0), $0) }
        )
        for snapshot in proposed.dropFirst() {
            let key = Self.identity(snapshot)
            if let existing = unique[key], existing != snapshot { return false }
            unique[key] = snapshot
        }
        let grouped = Dictionary(grouping: unique.values, by: \.observerProgrammeID)
        let newObserverIDs = Set(grouped.keys).subtracting(portalKnowledgeByObserver.keys)
        guard portalKnowledgeByObserver.count + newObserverIDs.count
                <= CollegePortalPolicyV1.maximumKnowledgeObservers else { return false }

        var next = portalKnowledgeByObserver
        for (observerID, additions) in grouped {
            var current = next[observerID] ?? []
            let currentByIdentity = Dictionary(uniqueKeysWithValues: current.map {
                (Self.identity($0), $0)
            })
            var newIdentityCount = 0
            for addition in additions {
                let key = Self.identity(addition)
                if let existing = currentByIdentity[key] {
                    guard existing == addition else { return false }
                } else {
                    current.append(addition)
                    newIdentityCount += 1
                }
            }
            let currentWindowCount = (next[observerID] ?? []).filter {
                $0.targetSeason == targetSeason && $0.window == window
            }.count
            guard currentWindowCount + newIdentityCount
                    <= CollegePortalPolicyV1.maximumKnowledgePerObserverWindow else {
                return false
            }
            next[observerID] = Self.canonical(current)
        }
        portalKnowledgeByObserver = next
        return true
    }

    /// Clears only portal-player observations at the next target-season boundary. Package access
    /// lets the cycle coordinator use it without exposing same-season recomputation to surfaces.
    @discardableResult
    package mutating func renewPortalKnowledge(forTargetSeason targetSeason: Int) -> Bool {
        guard targetSeason >= 0 else { return false }
        if let currentTargetSeason = portalKnowledgeTargetSeason {
            guard targetSeason == currentTargetSeason + 1 else { return false }
            portalKnowledgeByObserver = [:]
        }
        return true
    }

    @discardableResult
    public mutating func queueEvaluation(
        observerID: UUID,
        prospectID: UUID,
        effort: Int
    ) -> Bool {
        guard (1...CollegeRules.weeklyRecruitingContactPoints).contains(effort),
              pendingEvaluations.count < CollegeRules.maximumPendingEvaluations,
              !pendingEvaluations.contains(where: {
                  $0.observerID == observerID && $0.prospectID == prospectID
              }) else { return false }
        pendingEvaluations.append(ScoutingAssignment(
            observerID: observerID,
            prospectID: prospectID,
            effort: effort
        ))
        return true
    }

    mutating func record(_ observation: ProspectObservation, observerID: UUID) {
        observationsByObserver[observerID, default: [:]][observation.prospectID] = observation
    }

    mutating func clearPendingEvaluations() {
        pendingEvaluations = []
    }

    private struct PortalKnowledgeIdentity: Hashable {
        let observerProgrammeID: UUID
        let playerID: UUID
        let sourceProgrammeID: UUID
        let targetSeason: Int
        let window: CollegePortalWindow
    }

    private static func portalKnowledgeIsValid(
        _ knowledge: [UUID: [CollegePortalKnowledgeSnapshot]]
    ) -> Bool {
        let allSnapshots = knowledge.values.flatMap { $0 }
        guard knowledge.count <= CollegePortalPolicyV1.maximumKnowledgeObservers,
              Set(allSnapshots.map(\.targetSeason)).count
                <= CollegePortalPolicyV1.maximumKnowledgeTargetSeasonSlices,
              knowledge.allSatisfy({ observerID, snapshots in
                  !snapshots.isEmpty
                      && snapshots.allSatisfy({ $0.observerProgrammeID == observerID })
                      && Set(snapshots.map(identity)).count == snapshots.count
                      && Dictionary(grouping: snapshots, by: { snapshot in
                          PortalKnowledgeSlice(
                              targetSeason: snapshot.targetSeason,
                              window: snapshot.window
                          )
                      }).values.allSatisfy({
                          $0.count
                              <= CollegePortalPolicyV1.maximumKnowledgePerObserverWindow
                      })
              }) else { return false }
        return true
    }

    private var portalKnowledgeTargetSeason: Int? {
        portalKnowledgeByObserver.values.lazy.compactMap(\.first?.targetSeason).first
    }

    private struct PortalKnowledgeSlice: Hashable {
        let targetSeason: Int
        let window: CollegePortalWindow
    }

    private static func identity(
        _ snapshot: CollegePortalKnowledgeSnapshot
    ) -> PortalKnowledgeIdentity {
        PortalKnowledgeIdentity(
            observerProgrammeID: snapshot.observerProgrammeID,
            playerID: snapshot.playerID,
            sourceProgrammeID: snapshot.sourceProgrammeID,
            targetSeason: snapshot.targetSeason,
            window: snapshot.window
        )
    }

    private static func samePortalKnowledgeIdentity(
        _ lhs: CollegePortalKnowledgeSnapshot,
        _ rhs: CollegePortalKnowledgeSnapshot
    ) -> Bool {
        identity(lhs) == identity(rhs)
    }

    private static func canonical(
        _ snapshots: [CollegePortalKnowledgeSnapshot]
    ) -> [CollegePortalKnowledgeSnapshot] {
        snapshots.sorted { lhs, rhs in
            if lhs.targetSeason != rhs.targetSeason {
                return lhs.targetSeason < rhs.targetSeason
            }
            if lhs.window != rhs.window { return lhs.window.order < rhs.window.order }
            if lhs.sourceProgrammeID != rhs.sourceProgrammeID {
                return lhs.sourceProgrammeID.uuidString < rhs.sourceProgrammeID.uuidString
            }
            return lhs.playerID.uuidString < rhs.playerID.uuidString
        }
    }
}
