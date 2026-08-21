import Foundation

private func portalOccurs(_ lhs: CalendarState, noLaterThan rhs: CalendarState) -> Bool {
    lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week <= rhs.week)
}

private func portalSafeSum(_ values: [Int]) -> Int? {
    var total: Int = 0
    for value in values {
        let (next, overflow) = total.addingReportingOverflow(value)
        guard !overflow else { return nil }
        total = next
    }
    return total
}

private func portalPolicyIsSupported(_ version: Int) -> Bool {
    CollegePortalPolicyV1.supports(version)
}

public enum CollegePortalWindow: String, Codable, Sendable, CaseIterable, Hashable {
    case postseason
    case spring

    var order: Int {
        switch self {
        case .postseason: return 0
        case .spring: return 1
        }
    }

    func expectedCalendar(targetSeason: Int) -> CalendarState? {
        CollegePortalPolicyV1.expectedCalendar(targetSeason: targetSeason, window: self)
    }
}

public enum CollegePortalPhase: String, Codable, Sendable, CaseIterable, Hashable {
    case closed
    case postseasonOpen
    case awaitingSpring
    case springOpen

    public var isStableBoundary: Bool {
        self == .closed || self == .awaitingSpring
    }
}

public enum CollegePortalIntentReason: String, Codable, Sendable, CaseIterable, Hashable {
    case playingTime
    case rosterPath
    case relationship
    case nilAllocation
    case teamSuccess
    case restless
}

public struct CollegePortalIntentEvidence: Codable, Sendable, Equatable {
    public let position: Position
    public let starts: Int
    public let appearances: Int
    public let sourcePositionRoomSize: Int
    public let seasonsAtSource: Int
    public let sourceFinalRankingPosition: Int
    public let sourceRosterNIL: Int
    public let relationshipScore: Int?
    public let isRestless: Bool

    public init(
        position: Position,
        starts: Int,
        appearances: Int,
        sourcePositionRoomSize: Int,
        seasonsAtSource: Int,
        sourceFinalRankingPosition: Int,
        sourceRosterNIL: Int,
        relationshipScore: Int?,
        isRestless: Bool
    ) {
        precondition(Self.isValid(
            starts: starts,
            appearances: appearances,
            sourcePositionRoomSize: sourcePositionRoomSize,
            seasonsAtSource: seasonsAtSource,
            sourceFinalRankingPosition: sourceFinalRankingPosition,
            sourceRosterNIL: sourceRosterNIL,
            relationshipScore: relationshipScore
        ))
        self.position = position
        self.starts = starts
        self.appearances = appearances
        self.sourcePositionRoomSize = sourcePositionRoomSize
        self.seasonsAtSource = seasonsAtSource
        self.sourceFinalRankingPosition = sourceFinalRankingPosition
        self.sourceRosterNIL = sourceRosterNIL
        self.relationshipScore = relationshipScore
        self.isRestless = isRestless
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPosition = try container.decode(Position.self, forKey: .position)
        let decodedStarts = try container.decode(Int.self, forKey: .starts)
        let decodedAppearances = try container.decode(Int.self, forKey: .appearances)
        let decodedRoomSize = try container.decode(Int.self, forKey: .sourcePositionRoomSize)
        let decodedSeasons = try container.decode(Int.self, forKey: .seasonsAtSource)
        let decodedRank = try container.decode(Int.self, forKey: .sourceFinalRankingPosition)
        let decodedNIL = try container.decode(Int.self, forKey: .sourceRosterNIL)
        let decodedRelationship = try container.decodeIfPresent(
            Int.self,
            forKey: .relationshipScore
        )
        guard Self.isValid(
            starts: decodedStarts,
            appearances: decodedAppearances,
            sourcePositionRoomSize: decodedRoomSize,
            seasonsAtSource: decodedSeasons,
            sourceFinalRankingPosition: decodedRank,
            sourceRosterNIL: decodedNIL,
            relationshipScore: decodedRelationship
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .appearances,
                in: container,
                debugDescription: "Portal intent evidence is outside its structural bounds."
            )
        }
        position = decodedPosition
        starts = decodedStarts
        appearances = decodedAppearances
        sourcePositionRoomSize = decodedRoomSize
        seasonsAtSource = decodedSeasons
        sourceFinalRankingPosition = decodedRank
        sourceRosterNIL = decodedNIL
        relationshipScore = decodedRelationship
        isRestless = try container.decode(Bool.self, forKey: .isRestless)
    }

    private static func isValid(
        starts: Int,
        appearances: Int,
        sourcePositionRoomSize: Int,
        seasonsAtSource: Int,
        sourceFinalRankingPosition: Int,
        sourceRosterNIL: Int,
        relationshipScore: Int?
    ) -> Bool {
        (0...CollegePortalPolicyV1.maximumGamesPerSeason).contains(starts)
            && starts <= appearances
            && (0...CollegePortalPolicyV1.maximumGamesPerSeason).contains(appearances)
            && (1...CollegePortalPolicyV1.rosterLimit).contains(sourcePositionRoomSize)
            && (0...CollegePortalPolicyV1.eligibilityClockYears).contains(seasonsAtSource)
            && (1...CollegePortalPolicyV1.programmeCount).contains(sourceFinalRankingPosition)
            && (0...CollegePortalPolicyV1.maximumNILBudget).contains(sourceRosterNIL)
            && (relationshipScore.map { (0...100).contains($0) } ?? true)
    }
}

public struct CollegePortalIntentComponent: Codable, Sendable, Equatable {
    public let reason: CollegePortalIntentReason
    public let value: Int

    public init(reason: CollegePortalIntentReason, value: Int) {
        precondition(Self.isValid(value))
        self.reason = reason
        self.value = value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedValue = try container.decode(Int.self, forKey: .value)
        guard Self.isValid(decodedValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .value,
                in: container,
                debugDescription: "Portal intent component exceeds its rules-owned magnitude."
            )
        }
        reason = try container.decode(CollegePortalIntentReason.self, forKey: .reason)
        value = decodedValue
    }

    private static func isValid(_ value: Int) -> Bool {
        let magnitude = CollegePortalPolicyV1.maximumIntentComponentMagnitude
        return (-magnitude...magnitude).contains(value)
    }
}

public struct CollegePortalIntentExplanation: Codable, Sendable, Equatable {
    public let policyVersion: Int
    public let playerID: UUID
    public let sourceProgrammeID: UUID
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let evaluatedAt: CalendarState
    public let evidence: CollegePortalIntentEvidence
    public let components: [CollegePortalIntentComponent]
    public let selectionThreshold: Int

    public var total: Int {
        portalSafeSum(components.map(\.value))!
    }

    public init(
        policyVersion: Int,
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        evaluatedAt: CalendarState,
        evidence: CollegePortalIntentEvidence,
        components: [CollegePortalIntentComponent],
        selectionThreshold: Int
    ) {
        precondition(Self.isValid(
            policyVersion: policyVersion,
            targetSeason: targetSeason,
            window: window,
            evaluatedAt: evaluatedAt,
            evidence: evidence,
            components: components,
            selectionThreshold: selectionThreshold
        ))
        self.policyVersion = policyVersion
        self.playerID = playerID
        self.sourceProgrammeID = sourceProgrammeID
        self.targetSeason = targetSeason
        self.window = window
        self.evaluatedAt = evaluatedAt
        self.evidence = evidence
        self.components = components
        self.selectionThreshold = selectionThreshold
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPolicyVersion = try container.decode(Int.self, forKey: .policyVersion)
        let decodedTarget = try container.decode(Int.self, forKey: .targetSeason)
        let decodedWindow = try container.decode(CollegePortalWindow.self, forKey: .window)
        let decodedCalendar = try container.decode(CalendarState.self, forKey: .evaluatedAt)
        let decodedEvidence = try container.decode(
            CollegePortalIntentEvidence.self,
            forKey: .evidence
        )
        let decodedComponents = try container.decode(
            [CollegePortalIntentComponent].self,
            forKey: .components
        )
        let decodedThreshold = try container.decode(Int.self, forKey: .selectionThreshold)
        guard Self.isValid(
            policyVersion: decodedPolicyVersion,
            targetSeason: decodedTarget,
            window: decodedWindow,
            evaluatedAt: decodedCalendar,
            evidence: decodedEvidence,
            components: decodedComponents,
            selectionThreshold: decodedThreshold
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .components,
                in: container,
                debugDescription: "Portal intent explanation is noncanonical or inconsistent."
            )
        }
        policyVersion = decodedPolicyVersion
        playerID = try container.decode(UUID.self, forKey: .playerID)
        sourceProgrammeID = try container.decode(UUID.self, forKey: .sourceProgrammeID)
        targetSeason = decodedTarget
        window = decodedWindow
        evaluatedAt = decodedCalendar
        evidence = decodedEvidence
        components = decodedComponents
        selectionThreshold = decodedThreshold
    }

    private static func isValid(
        policyVersion: Int,
        targetSeason: Int,
        window: CollegePortalWindow,
        evaluatedAt: CalendarState,
        evidence: CollegePortalIntentEvidence,
        components: [CollegePortalIntentComponent],
        selectionThreshold: Int
    ) -> Bool {
        let canonical = CollegePortalIntentReason.allCases.compactMap { reason in
            components.first { $0.reason == reason }
        }
        return portalPolicyIsSupported(policyVersion)
            && window.expectedCalendar(targetSeason: targetSeason) == evaluatedAt
            && CollegePortalIntentReason.allCases.count == 6
            && components.count == 6
            && canonical == components
            && Set(components.map(\.reason)).count == components.count
            && selectionThreshold == CollegePortalPolicyV1.intentSelectionThreshold
            && components == CollegePortalPolicyV1.intentComponents(for: evidence)
            && portalSafeSum(components.map(\.value)).map { $0 >= selectionThreshold } == true
    }
}

public struct CollegePortalKnowledgeSnapshot: Codable, Sendable, Equatable {
    public let observerProgrammeID: UUID
    public let playerID: UUID
    public let sourceProgrammeID: UUID
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let position: Position
    public let estimatedOverall: Rating
    public let estimatedAttributes: [Attribute: Rating]
    public let estimatedPotential: Rating
    public let confidence: Int
    public let lastUpdated: CalendarState
    public let evidenceCount: Int

    public init(
        observerProgrammeID: UUID,
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        position: Position,
        estimatedOverall: Rating,
        estimatedAttributes: [Attribute: Rating],
        estimatedPotential: Rating,
        confidence: Int,
        lastUpdated: CalendarState,
        evidenceCount: Int
    ) {
        precondition(Self.isValid(
            targetSeason: targetSeason,
            window: window,
            position: position,
            estimatedOverall: estimatedOverall,
            estimatedAttributes: estimatedAttributes,
            confidence: confidence,
            lastUpdated: lastUpdated,
            evidenceCount: evidenceCount
        ))
        self.observerProgrammeID = observerProgrammeID
        self.playerID = playerID
        self.sourceProgrammeID = sourceProgrammeID
        self.targetSeason = targetSeason
        self.window = window
        self.position = position
        self.estimatedOverall = estimatedOverall
        self.estimatedAttributes = estimatedAttributes
        self.estimatedPotential = estimatedPotential
        self.confidence = confidence
        self.lastUpdated = lastUpdated
        self.evidenceCount = evidenceCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTarget = try container.decode(Int.self, forKey: .targetSeason)
        let decodedWindow = try container.decode(CollegePortalWindow.self, forKey: .window)
        let decodedPosition = try container.decode(Position.self, forKey: .position)
        let decodedOverall = try container.decode(Rating.self, forKey: .estimatedOverall)
        let decodedAttributes = try container.decode(
            [Attribute: Rating].self,
            forKey: .estimatedAttributes
        )
        let decodedConfidence = try container.decode(Int.self, forKey: .confidence)
        let decodedUpdated = try container.decode(CalendarState.self, forKey: .lastUpdated)
        let decodedEvidence = try container.decode(Int.self, forKey: .evidenceCount)
        guard Self.isValid(
            targetSeason: decodedTarget,
            window: decodedWindow,
            position: decodedPosition,
            estimatedOverall: decodedOverall,
            estimatedAttributes: decodedAttributes,
            confidence: decodedConfidence,
            lastUpdated: decodedUpdated,
            evidenceCount: decodedEvidence
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .confidence,
                in: container,
                debugDescription: "Portal knowledge snapshot is future, malformed, or unbounded."
            )
        }
        observerProgrammeID = try container.decode(UUID.self, forKey: .observerProgrammeID)
        playerID = try container.decode(UUID.self, forKey: .playerID)
        sourceProgrammeID = try container.decode(UUID.self, forKey: .sourceProgrammeID)
        targetSeason = decodedTarget
        window = decodedWindow
        position = decodedPosition
        estimatedOverall = decodedOverall
        estimatedAttributes = decodedAttributes
        estimatedPotential = try container.decode(Rating.self, forKey: .estimatedPotential)
        confidence = decodedConfidence
        lastUpdated = decodedUpdated
        evidenceCount = decodedEvidence
    }

    private static func isValid(
        targetSeason: Int,
        window: CollegePortalWindow,
        position: Position,
        estimatedOverall: Rating,
        estimatedAttributes: [Attribute: Rating],
        confidence: Int,
        lastUpdated: CalendarState,
        evidenceCount: Int
    ) -> Bool {
        guard let openedAt = window.expectedCalendar(targetSeason: targetSeason) else { return false }
        let ratedAttributes = CollegePortalPolicyV1.ratedAttributes(for: position)
        guard !ratedAttributes.isEmpty,
              Set(estimatedAttributes.keys) == Set(ratedAttributes) else { return false }
        let mean = estimatedAttributes.values.reduce(0) { $0 + $1.value }
            / estimatedAttributes.count
        return estimatedOverall.value == mean
            && (0...CollegePortalPolicyV1.maximumKnowledgeConfidence).contains(confidence)
            && (0...CollegePortalPolicyV1.maximumScoutingEvidence).contains(evidenceCount)
            && lastUpdated == openedAt
    }
}

public enum CollegePortalOriginEvidence: Codable, Sendable, Equatable {
    case known(cityID: UUID)
    case neutral
}

public struct CollegePortalDestinationEvidence: Codable, Sendable, Equatable {
    public let candidatePosition: Position
    public let origin: CollegePortalOriginEvidence
    public let destinationHomeCityID: UUID
    public let squaredCityDistance: Int?
    public let destinationPositionRoomCount: Int
    public let positionTargetCount: Int
    public let observedSchemeFit: Rating
    public let priorityWeights: [RecruitingPitch: Rating]
    public let prestige: Rating
    public let recruitingStaffAverage: Rating
    public let archivedFinalRankingPosition: Int

    public init(
        candidatePosition: Position,
        origin: CollegePortalOriginEvidence,
        destinationHomeCityID: UUID,
        squaredCityDistance: Int?,
        destinationPositionRoomCount: Int,
        positionTargetCount: Int,
        observedSchemeFit: Rating,
        priorityWeights: [RecruitingPitch: Rating],
        prestige: Rating,
        recruitingStaffAverage: Rating,
        archivedFinalRankingPosition: Int
    ) {
        precondition(Self.isValid(
            candidatePosition: candidatePosition,
            origin: origin,
            squaredCityDistance: squaredCityDistance,
            destinationPositionRoomCount: destinationPositionRoomCount,
            positionTargetCount: positionTargetCount,
            priorityWeights: priorityWeights,
            archivedFinalRankingPosition: archivedFinalRankingPosition
        ))
        self.candidatePosition = candidatePosition
        self.origin = origin
        self.destinationHomeCityID = destinationHomeCityID
        self.squaredCityDistance = squaredCityDistance
        self.destinationPositionRoomCount = destinationPositionRoomCount
        self.positionTargetCount = positionTargetCount
        self.observedSchemeFit = observedSchemeFit
        self.priorityWeights = priorityWeights
        self.prestige = prestige
        self.recruitingStaffAverage = recruitingStaffAverage
        self.archivedFinalRankingPosition = archivedFinalRankingPosition
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRoomCount = try container.decode(
            Int.self,
            forKey: .destinationPositionRoomCount
        )
        let decodedRanking = try container.decode(
            Int.self,
            forKey: .archivedFinalRankingPosition
        )
        let decodedPosition = try container.decode(Position.self, forKey: .candidatePosition)
        let decodedOrigin = try container.decode(CollegePortalOriginEvidence.self, forKey: .origin)
        let decodedDistance = try container.decodeIfPresent(
            Int.self,
            forKey: .squaredCityDistance
        )
        let decodedTarget = try container.decode(Int.self, forKey: .positionTargetCount)
        let decodedPriorities = try container.decode(
            [RecruitingPitch: Rating].self,
            forKey: .priorityWeights
        )
        guard Self.isValid(
            candidatePosition: decodedPosition,
            origin: decodedOrigin,
            squaredCityDistance: decodedDistance,
            destinationPositionRoomCount: decodedRoomCount,
            positionTargetCount: decodedTarget,
            priorityWeights: decodedPriorities,
            archivedFinalRankingPosition: decodedRanking
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .destinationPositionRoomCount,
                in: container,
                debugDescription: "Portal destination evidence is outside programme bounds."
            )
        }
        candidatePosition = decodedPosition
        origin = decodedOrigin
        destinationHomeCityID = try container.decode(UUID.self, forKey: .destinationHomeCityID)
        squaredCityDistance = decodedDistance
        destinationPositionRoomCount = decodedRoomCount
        positionTargetCount = decodedTarget
        observedSchemeFit = try container.decode(Rating.self, forKey: .observedSchemeFit)
        priorityWeights = decodedPriorities
        prestige = try container.decode(Rating.self, forKey: .prestige)
        recruitingStaffAverage = try container.decode(Rating.self, forKey: .recruitingStaffAverage)
        archivedFinalRankingPosition = decodedRanking
    }

    private static func isValid(
        candidatePosition: Position,
        origin: CollegePortalOriginEvidence,
        squaredCityDistance: Int?,
        destinationPositionRoomCount: Int,
        positionTargetCount: Int,
        priorityWeights: [RecruitingPitch: Rating],
        archivedFinalRankingPosition: Int
    ) -> Bool {
        let distanceShapeIsValid: Bool
        switch origin {
        case .known:
            distanceShapeIsValid = squaredCityDistance.map {
                (0...CollegePortalPolicyV1.maximumSquaredCityDistance).contains($0)
            } ?? false
        case .neutral:
            distanceShapeIsValid = squaredCityDistance == nil
                && priorityWeights.values.allSatisfy {
                    $0.value == CollegePortalPolicyV1.neutralPitchWeight
                }
        }
        return distanceShapeIsValid
            && CollegePortalPolicyV1.positionTargetCount(for: candidatePosition)
                == positionTargetCount
            && Set(priorityWeights.keys) == Set(CollegePortalPolicyV1.pitchOrder)
            && (0...CollegePortalPolicyV1.rosterLimit).contains(
                destinationPositionRoomCount
            )
            && (1...CollegePortalPolicyV1.programmeCount).contains(
                archivedFinalRankingPosition
            )
    }
}

public struct CollegePortalDestinationFitExplanation: Codable, Sendable, Equatable {
    public let policyVersion: Int
    public let playerID: UUID
    public let programmeID: UUID
    public let evidence: CollegePortalDestinationEvidence
    public let components: [RecruitingScoreComponent]
    public let nilAllocationAdjustment: Int
    public let knowledgeAdjustment: Int

    public var total: Int {
        components.reduce(0) { $0 + $1.value }
            + nilAllocationAdjustment
            + knowledgeAdjustment
    }

    public init(
        policyVersion: Int,
        playerID: UUID,
        programmeID: UUID,
        evidence: CollegePortalDestinationEvidence,
        components: [RecruitingScoreComponent],
        nilAllocationAdjustment: Int,
        knowledgeAdjustment: Int
    ) {
        precondition(Self.isValid(
            policyVersion: policyVersion,
            evidence: evidence,
            components: components,
            nilAllocationAdjustment: nilAllocationAdjustment,
            knowledgeAdjustment: knowledgeAdjustment
        ))
        self.policyVersion = policyVersion
        self.playerID = playerID
        self.programmeID = programmeID
        self.evidence = evidence
        self.components = components
        self.nilAllocationAdjustment = nilAllocationAdjustment
        self.knowledgeAdjustment = knowledgeAdjustment
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPolicyVersion = try container.decode(Int.self, forKey: .policyVersion)
        let decodedComponents = try container.decode(
            [RecruitingScoreComponent].self,
            forKey: .components
        )
        let decodedEvidence = try container.decode(
            CollegePortalDestinationEvidence.self,
            forKey: .evidence
        )
        let decodedNIL = try container.decode(Int.self, forKey: .nilAllocationAdjustment)
        let decodedKnowledge = try container.decode(Int.self, forKey: .knowledgeAdjustment)
        guard Self.isValid(
            policyVersion: decodedPolicyVersion,
            evidence: decodedEvidence,
            components: decodedComponents,
            nilAllocationAdjustment: decodedNIL,
            knowledgeAdjustment: decodedKnowledge
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .components,
                in: container,
                debugDescription: "Portal destination fit is noncanonical or unbounded."
            )
        }
        policyVersion = decodedPolicyVersion
        playerID = try container.decode(UUID.self, forKey: .playerID)
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        evidence = decodedEvidence
        components = decodedComponents
        nilAllocationAdjustment = decodedNIL
        knowledgeAdjustment = decodedKnowledge
    }

    private static func isValid(
        policyVersion: Int,
        evidence: CollegePortalDestinationEvidence,
        components: [RecruitingScoreComponent],
        nilAllocationAdjustment: Int,
        knowledgeAdjustment: Int
    ) -> Bool {
        let canonical = CollegePortalPolicyV1.pitchOrder.compactMap { reason in
            components.first { $0.reason == reason }
        }
        return portalPolicyIsSupported(policyVersion)
            && components.count == CollegePortalPolicyV1.pitchOrder.count
            && canonical == components
            && Set(components.map(\.reason)).count == components.count
            && (0...CollegePortalPolicyV1.maximumFitNILAdjustment).contains(
                nilAllocationAdjustment
            )
            && knowledgeAdjustment == 0
            && components == CollegePortalPolicyV1.destinationFitComponents(
                for: evidence,
                nilAllocationAdjustment: nilAllocationAdjustment
            )
    }
}

public enum CollegePortalAdmissionReason: String, Codable, Sendable, CaseIterable, Hashable {
    case readiness
    case potential
    case production
    case positionNeed
    case schemeFit
    case uncertainty
}

public struct CollegePortalAdmissionComponent: Codable, Sendable, Equatable {
    public let reason: CollegePortalAdmissionReason
    public let value: Int

    public init(reason: CollegePortalAdmissionReason, value: Int) {
        precondition(Self.isValid(value))
        self.reason = reason
        self.value = value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedValue = try container.decode(Int.self, forKey: .value)
        guard Self.isValid(decodedValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .value,
                in: container,
                debugDescription: "Portal admission component exceeds its rules-owned magnitude."
            )
        }
        reason = try container.decode(CollegePortalAdmissionReason.self, forKey: .reason)
        value = decodedValue
    }

    private static func isValid(_ value: Int) -> Bool {
        let magnitude = CollegePortalPolicyV1.maximumAdmissionComponentMagnitude
        return (-magnitude...magnitude).contains(value)
    }
}

public struct CollegePortalAdmissionEvidence: Codable, Sendable, Equatable {
    public let position: Position
    public let estimatedOverall: Rating
    public let estimatedPotential: Rating
    public let appearances: Int
    public let fixedPositionRoomCount: Int
    public let estimatedSchemeFit: Rating
    public let confidence: Int

    public init(
        position: Position,
        estimatedOverall: Rating,
        estimatedPotential: Rating,
        appearances: Int,
        fixedPositionRoomCount: Int,
        estimatedSchemeFit: Rating,
        confidence: Int
    ) {
        precondition(Self.isValid(
            position: position,
            appearances: appearances,
            fixedPositionRoomCount: fixedPositionRoomCount,
            confidence: confidence
        ))
        self.position = position
        self.estimatedOverall = estimatedOverall
        self.estimatedPotential = estimatedPotential
        self.appearances = appearances
        self.fixedPositionRoomCount = fixedPositionRoomCount
        self.estimatedSchemeFit = estimatedSchemeFit
        self.confidence = confidence
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPosition = try container.decode(Position.self, forKey: .position)
        let decodedAppearances = try container.decode(Int.self, forKey: .appearances)
        let decodedRoomCount = try container.decode(Int.self, forKey: .fixedPositionRoomCount)
        let decodedConfidence = try container.decode(Int.self, forKey: .confidence)
        guard Self.isValid(
            position: decodedPosition,
            appearances: decodedAppearances,
            fixedPositionRoomCount: decodedRoomCount,
            confidence: decodedConfidence
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .appearances,
                in: container,
                debugDescription: "Portal admission evidence is incomplete or unbounded."
            )
        }
        position = decodedPosition
        estimatedOverall = try container.decode(Rating.self, forKey: .estimatedOverall)
        estimatedPotential = try container.decode(Rating.self, forKey: .estimatedPotential)
        appearances = decodedAppearances
        fixedPositionRoomCount = decodedRoomCount
        estimatedSchemeFit = try container.decode(Rating.self, forKey: .estimatedSchemeFit)
        confidence = decodedConfidence
    }

    private static func isValid(
        position: Position,
        appearances: Int,
        fixedPositionRoomCount: Int,
        confidence: Int
    ) -> Bool {
        CollegePortalPolicyV1.positionTargetCount(for: position) != nil
            && (0...CollegePortalPolicyV1.maximumGamesPerSeason).contains(appearances)
            && (0...CollegePortalPolicyV1.rosterLimit).contains(fixedPositionRoomCount)
            && (0...CollegePortalPolicyV1.maximumKnowledgeConfidence).contains(confidence)
    }
}

public struct CollegePortalDestinationAdmissionExplanation: Codable, Sendable, Equatable {
    public let policyVersion: Int
    public let playerID: UUID
    public let programmeID: UUID
    public let evidence: CollegePortalAdmissionEvidence
    public let components: [CollegePortalAdmissionComponent]

    public var total: Int {
        portalSafeSum(components.map(\.value))!
    }

    public init(
        policyVersion: Int,
        playerID: UUID,
        programmeID: UUID,
        evidence: CollegePortalAdmissionEvidence,
        components: [CollegePortalAdmissionComponent]
    ) {
        precondition(Self.isValid(
            policyVersion: policyVersion,
            evidence: evidence,
            components: components
        ))
        self.policyVersion = policyVersion
        self.playerID = playerID
        self.programmeID = programmeID
        self.evidence = evidence
        self.components = components
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPolicyVersion = try container.decode(Int.self, forKey: .policyVersion)
        let decodedEvidence = try container.decode(
            CollegePortalAdmissionEvidence.self,
            forKey: .evidence
        )
        let decodedComponents = try container.decode(
            [CollegePortalAdmissionComponent].self,
            forKey: .components
        )
        guard Self.isValid(
            policyVersion: decodedPolicyVersion,
            evidence: decodedEvidence,
            components: decodedComponents
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .components,
                in: container,
                debugDescription: "Portal admission explanation is noncanonical or unbounded."
            )
        }
        policyVersion = decodedPolicyVersion
        playerID = try container.decode(UUID.self, forKey: .playerID)
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        evidence = decodedEvidence
        components = decodedComponents
    }

    private static func isValid(
        policyVersion: Int,
        evidence: CollegePortalAdmissionEvidence,
        components: [CollegePortalAdmissionComponent]
    ) -> Bool {
        let canonical = CollegePortalAdmissionReason.allCases.compactMap { reason in
            components.first { $0.reason == reason }
        }
        guard portalPolicyIsSupported(policyVersion),
              CollegePortalAdmissionReason.allCases.count
                == CollegePortalPolicyV1.admissionReasonCount
                && components.count == CollegePortalPolicyV1.admissionReasonCount,
              canonical == components,
              Set(components.map(\.reason)).count == components.count,
              portalSafeSum(components.map(\.value)).map({
                  CollegePortalPolicyV1.admissionTotalRange.contains($0)
              }) == true,
              let expected = expectedComponents(
                  policyVersion: policyVersion,
                  evidence: evidence
              ) else { return false }
        return components == expected
    }

    private static func expectedComponents(
        policyVersion: Int,
        evidence: CollegePortalAdmissionEvidence
    ) -> [CollegePortalAdmissionComponent]? {
        guard policyVersion == CollegePortalPolicyV1.version else { return nil }
        return CollegePortalPolicyV1.admissionComponents(for: evidence)
    }
}

public struct CollegePortalCapacitySnapshot: Codable, Sendable, Equatable {
    public let programmeID: UUID
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let capturedAt: CalendarState
    public let rosterOpenings: Int
    public let scholarshipOpenings: Int
    public let minimumCoverageDeficits: [Position: Int]
    public let nilRemaining: Int

    public init(
        programmeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        capturedAt: CalendarState,
        rosterOpenings: Int,
        scholarshipOpenings: Int,
        minimumCoverageDeficits: [Position: Int] = [:],
        nilRemaining: Int
    ) {
        precondition(Self.isValid(
            targetSeason: targetSeason,
            window: window,
            capturedAt: capturedAt,
            rosterOpenings: rosterOpenings,
            scholarshipOpenings: scholarshipOpenings,
            minimumCoverageDeficits: minimumCoverageDeficits,
            nilRemaining: nilRemaining
        ))
        self.programmeID = programmeID
        self.targetSeason = targetSeason
        self.window = window
        self.capturedAt = capturedAt
        self.rosterOpenings = rosterOpenings
        self.scholarshipOpenings = scholarshipOpenings
        self.minimumCoverageDeficits = minimumCoverageDeficits
        self.nilRemaining = nilRemaining
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTarget = try container.decode(Int.self, forKey: .targetSeason)
        let decodedWindow = try container.decode(CollegePortalWindow.self, forKey: .window)
        let decodedCapturedAt = try container.decode(CalendarState.self, forKey: .capturedAt)
        let decodedRoster = try container.decode(Int.self, forKey: .rosterOpenings)
        let decodedScholarships = try container.decode(Int.self, forKey: .scholarshipOpenings)
        let decodedDeficits = try container.decode(
            [Position: Int].self,
            forKey: .minimumCoverageDeficits
        )
        let decodedNIL = try container.decode(Int.self, forKey: .nilRemaining)
        guard Self.isValid(
            targetSeason: decodedTarget,
            window: decodedWindow,
            capturedAt: decodedCapturedAt,
            rosterOpenings: decodedRoster,
            scholarshipOpenings: decodedScholarships,
            minimumCoverageDeficits: decodedDeficits,
            nilRemaining: decodedNIL
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .rosterOpenings,
                in: container,
                debugDescription: "Portal capacity snapshot is outside legal programme limits."
            )
        }
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        targetSeason = decodedTarget
        window = decodedWindow
        capturedAt = decodedCapturedAt
        rosterOpenings = decodedRoster
        scholarshipOpenings = decodedScholarships
        minimumCoverageDeficits = decodedDeficits
        nilRemaining = decodedNIL
    }

    private static func isValid(
        targetSeason: Int,
        window: CollegePortalWindow,
        capturedAt: CalendarState,
        rosterOpenings: Int,
        scholarshipOpenings: Int,
        minimumCoverageDeficits: [Position: Int],
        nilRemaining: Int
    ) -> Bool {
        window.expectedCalendar(targetSeason: targetSeason) == capturedAt
            && (0...CollegePortalPolicyV1.rosterLimit).contains(rosterOpenings)
            && (0...CollegePortalPolicyV1.scholarshipLimit).contains(scholarshipOpenings)
            && minimumCoverageDeficits.allSatisfy { position, deficit in
                deficit > 0
                    && deficit <= (CollegePortalPolicyV1
                        .minimumPlayableRosterByPosition[position] ?? 0)
            }
            && minimumCoverageDeficits.values.reduce(0, +) <= rosterOpenings
            && (0...CollegePortalPolicyV1.maximumNILBudget).contains(nilRemaining)
    }

    func acceptsPortalPositions(_ positions: [Position]) -> Bool {
        guard positions.count <= scholarshipOpenings else { return false }
        let acceptedByPosition = Dictionary(grouping: positions, by: { $0 }).mapValues(\.count)
        let remainingDeficit = minimumCoverageDeficits.reduce(0) { total, entry in
            total + max(0, entry.value - (acceptedByPosition[entry.key] ?? 0))
        }
        return positions.count + remainingDeficit <= rosterOpenings
    }
}

public struct CollegePortalOffer: Codable, Sendable, Equatable {
    public let destinationProgrammeID: UUID
    public let nilReservation: Int
    public let knowledge: CollegePortalKnowledgeSnapshot
    public let playerFit: CollegePortalDestinationFitExplanation
    public let destinationAdmission: CollegePortalDestinationAdmissionExplanation
    public let fixedCapacity: CollegePortalCapacitySnapshot

    public init(
        destinationProgrammeID: UUID,
        nilReservation: Int,
        knowledge: CollegePortalKnowledgeSnapshot,
        playerFit: CollegePortalDestinationFitExplanation,
        destinationAdmission: CollegePortalDestinationAdmissionExplanation,
        fixedCapacity: CollegePortalCapacitySnapshot
    ) {
        precondition(Self.isValid(
            destinationProgrammeID: destinationProgrammeID,
            nilReservation: nilReservation,
            knowledge: knowledge,
            playerFit: playerFit,
            destinationAdmission: destinationAdmission,
            fixedCapacity: fixedCapacity
        ))
        self.destinationProgrammeID = destinationProgrammeID
        self.nilReservation = nilReservation
        self.knowledge = knowledge
        self.playerFit = playerFit
        self.destinationAdmission = destinationAdmission
        self.fixedCapacity = fixedCapacity
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDestination = try container.decode(UUID.self, forKey: .destinationProgrammeID)
        let decodedNIL = try container.decode(Int.self, forKey: .nilReservation)
        let decodedKnowledge = try container.decode(
            CollegePortalKnowledgeSnapshot.self,
            forKey: .knowledge
        )
        let decodedPlayerFit = try container.decode(
            CollegePortalDestinationFitExplanation.self,
            forKey: .playerFit
        )
        let decodedAdmission = try container.decode(
            CollegePortalDestinationAdmissionExplanation.self,
            forKey: .destinationAdmission
        )
        let decodedCapacity = try container.decode(
            CollegePortalCapacitySnapshot.self,
            forKey: .fixedCapacity
        )
        guard Self.isValid(
            destinationProgrammeID: decodedDestination,
            nilReservation: decodedNIL,
            knowledge: decodedKnowledge,
            playerFit: decodedPlayerFit,
            destinationAdmission: decodedAdmission,
            fixedCapacity: decodedCapacity
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .destinationProgrammeID,
                in: container,
                debugDescription: "Portal offer disagrees with its knowledge, fit, or capacity."
            )
        }
        destinationProgrammeID = decodedDestination
        nilReservation = decodedNIL
        knowledge = decodedKnowledge
        playerFit = decodedPlayerFit
        destinationAdmission = decodedAdmission
        fixedCapacity = decodedCapacity
    }

    private static func isValid(
        destinationProgrammeID: UUID,
        nilReservation: Int,
        knowledge: CollegePortalKnowledgeSnapshot,
        playerFit: CollegePortalDestinationFitExplanation,
        destinationAdmission: CollegePortalDestinationAdmissionExplanation,
        fixedCapacity: CollegePortalCapacitySnapshot
    ) -> Bool {
        destinationProgrammeID == knowledge.observerProgrammeID
            && destinationProgrammeID == playerFit.programmeID
            && destinationProgrammeID == destinationAdmission.programmeID
            && destinationProgrammeID == fixedCapacity.programmeID
            && knowledge.playerID == playerFit.playerID
            && knowledge.playerID == destinationAdmission.playerID
            && knowledge.targetSeason == fixedCapacity.targetSeason
            && knowledge.window == fixedCapacity.window
            && playerFit.policyVersion == destinationAdmission.policyVersion
            && knowledge.position == playerFit.evidence.candidatePosition
            && knowledge.position == destinationAdmission.evidence.position
            && destinationAdmission.evidence.position == playerFit.evidence.candidatePosition
            && playerFit.evidence.observedSchemeFit
                == knowledge.estimatedAttributes[.schemeFit]
            && destinationAdmission.evidence.estimatedOverall == knowledge.estimatedOverall
            && destinationAdmission.evidence.estimatedPotential == knowledge.estimatedPotential
            && destinationAdmission.evidence.fixedPositionRoomCount
                == playerFit.evidence.destinationPositionRoomCount
            && destinationAdmission.evidence.estimatedSchemeFit
                == knowledge.estimatedAttributes[.schemeFit]
            && destinationAdmission.evidence.confidence == knowledge.confidence
            && (0...CollegePortalPolicyV1.maximumOfferNIL).contains(nilReservation)
            && nilReservation % CollegePortalPolicyV1.nilBandUnit == 0
            && playerFit.nilAllocationAdjustment
                == nilReservation / CollegePortalPolicyV1.nilBandUnit
            && nilReservation <= fixedCapacity.nilRemaining
            && fixedCapacity.rosterOpenings > 0
            && fixedCapacity.scholarshipOpenings > 0
    }
}

public enum CollegePortalRetentionOutcome: String, Codable, Sendable, CaseIterable, Hashable {
    case retained
    case released
}

public struct CollegePortalRetentionResolution: Codable, Sendable, Equatable {
    public let policyVersion: Int
    public let outcome: CollegePortalRetentionOutcome
    public let requiredAdditionalNIL: Int?
    public let appliedAdditionalNIL: Int
    public let sourceRosterNILAfterDecision: Int
    public let intentScoreAfterDecision: Int

    public init(
        policyVersion: Int,
        outcome: CollegePortalRetentionOutcome,
        requiredAdditionalNIL: Int?,
        appliedAdditionalNIL: Int,
        sourceRosterNILAfterDecision: Int,
        intentScoreAfterDecision: Int
    ) {
        precondition(Self.isValid(
            policyVersion: policyVersion,
            outcome: outcome,
            requiredAdditionalNIL: requiredAdditionalNIL,
            appliedAdditionalNIL: appliedAdditionalNIL,
            sourceRosterNILAfterDecision: sourceRosterNILAfterDecision,
            intentScoreAfterDecision: intentScoreAfterDecision
        ))
        self.policyVersion = policyVersion
        self.outcome = outcome
        self.requiredAdditionalNIL = requiredAdditionalNIL
        self.appliedAdditionalNIL = appliedAdditionalNIL
        self.sourceRosterNILAfterDecision = sourceRosterNILAfterDecision
        self.intentScoreAfterDecision = intentScoreAfterDecision
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPolicyVersion = try container.decode(Int.self, forKey: .policyVersion)
        let decodedOutcome = try container.decode(
            CollegePortalRetentionOutcome.self,
            forKey: .outcome
        )
        guard container.contains(.requiredAdditionalNIL) else {
            throw DecodingError.keyNotFound(
                CodingKeys.requiredAdditionalNIL,
                .init(
                    codingPath: container.codingPath,
                    debugDescription: "Portal retention requires explicit NIL feasibility."
                )
            )
        }
        let decodedRequired = try container.decodeIfPresent(
            Int.self,
            forKey: .requiredAdditionalNIL
        )
        let decodedApplied = try container.decode(Int.self, forKey: .appliedAdditionalNIL)
        let decodedFinal = try container.decode(Int.self, forKey: .sourceRosterNILAfterDecision)
        let decodedScore = try container.decode(Int.self, forKey: .intentScoreAfterDecision)
        guard Self.isValid(
            policyVersion: decodedPolicyVersion,
            outcome: decodedOutcome,
            requiredAdditionalNIL: decodedRequired,
            appliedAdditionalNIL: decodedApplied,
            sourceRosterNILAfterDecision: decodedFinal,
            intentScoreAfterDecision: decodedScore
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .requiredAdditionalNIL,
                in: container,
                debugDescription: "Portal retention resolution is outside NIL bounds."
            )
        }
        policyVersion = decodedPolicyVersion
        outcome = decodedOutcome
        requiredAdditionalNIL = decodedRequired
        appliedAdditionalNIL = decodedApplied
        sourceRosterNILAfterDecision = decodedFinal
        intentScoreAfterDecision = decodedScore
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(policyVersion, forKey: .policyVersion)
        try container.encode(outcome, forKey: .outcome)
        if let requiredAdditionalNIL {
            try container.encode(requiredAdditionalNIL, forKey: .requiredAdditionalNIL)
        } else {
            try container.encodeNil(forKey: .requiredAdditionalNIL)
        }
        try container.encode(appliedAdditionalNIL, forKey: .appliedAdditionalNIL)
        try container.encode(
            sourceRosterNILAfterDecision,
            forKey: .sourceRosterNILAfterDecision
        )
        try container.encode(intentScoreAfterDecision, forKey: .intentScoreAfterDecision)
    }

    private static func isValid(
        policyVersion: Int,
        outcome: CollegePortalRetentionOutcome,
        requiredAdditionalNIL: Int?,
        appliedAdditionalNIL: Int,
        sourceRosterNILAfterDecision: Int,
        intentScoreAfterDecision: Int
    ) -> Bool {
        CollegePortalPolicyV1.retentionResolutionIsValid(
            policyVersion: policyVersion,
            outcome: outcome,
            requiredAdditionalNIL: requiredAdditionalNIL,
            appliedAdditionalNIL: appliedAdditionalNIL,
            sourceRosterNILAfterDecision: sourceRosterNILAfterDecision,
            intentScoreAfterDecision: intentScoreAfterDecision
        )
    }


    private enum CodingKeys: String, CodingKey {
        case policyVersion
        case outcome
        case requiredAdditionalNIL
        case appliedAdditionalNIL
        case sourceRosterNILAfterDecision
        case intentScoreAfterDecision
    }
}

public enum CollegePortalWindowOutcome: Codable, Sendable, Equatable {
    case retainedBySource
    case returnedToSource
    case transferred(destinationProgrammeID: UUID)
}

public struct CollegePortalWindowRecord: Codable, Sendable, Equatable {
    public let policyVersion: Int
    public let playerID: UUID
    public let sourceProgrammeID: UUID
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let openedAt: CalendarState
    public let sourceWasScholarship: Bool
    public let intent: CollegePortalIntentExplanation
    public let retention: CollegePortalRetentionResolution
    public let offers: [CollegePortalOffer]
    public let outcome: CollegePortalWindowOutcome
    public let finalIsScholarship: Bool
    public let finalRosterNIL: Int

    public var finalProgrammeID: UUID {
        if case let .transferred(destinationProgrammeID) = outcome {
            return destinationProgrammeID
        }
        return sourceProgrammeID
    }

    public init(
        policyVersion: Int,
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        openedAt: CalendarState,
        sourceWasScholarship: Bool,
        intent: CollegePortalIntentExplanation,
        retention: CollegePortalRetentionResolution,
        offers: [CollegePortalOffer],
        outcome: CollegePortalWindowOutcome,
        finalIsScholarship: Bool,
        finalRosterNIL: Int
    ) {
        precondition(Self.isValid(
            policyVersion: policyVersion,
            playerID: playerID,
            sourceProgrammeID: sourceProgrammeID,
            targetSeason: targetSeason,
            window: window,
            openedAt: openedAt,
            sourceWasScholarship: sourceWasScholarship,
            intent: intent,
            retention: retention,
            offers: offers,
            outcome: outcome,
            finalIsScholarship: finalIsScholarship,
            finalRosterNIL: finalRosterNIL
        ))
        self.policyVersion = policyVersion
        self.playerID = playerID
        self.sourceProgrammeID = sourceProgrammeID
        self.targetSeason = targetSeason
        self.window = window
        self.openedAt = openedAt
        self.sourceWasScholarship = sourceWasScholarship
        self.intent = intent
        self.retention = retention
        self.offers = offers
        self.outcome = outcome
        self.finalIsScholarship = finalIsScholarship
        self.finalRosterNIL = finalRosterNIL
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPolicyVersion = try container.decode(Int.self, forKey: .policyVersion)
        let decodedPlayerID = try container.decode(UUID.self, forKey: .playerID)
        let decodedSourceID = try container.decode(UUID.self, forKey: .sourceProgrammeID)
        let decodedTarget = try container.decode(Int.self, forKey: .targetSeason)
        let decodedWindow = try container.decode(CollegePortalWindow.self, forKey: .window)
        let decodedOpenedAt = try container.decode(CalendarState.self, forKey: .openedAt)
        let decodedSourceScholarship = try container.decode(Bool.self, forKey: .sourceWasScholarship)
        let decodedIntent = try container.decode(
            CollegePortalIntentExplanation.self,
            forKey: .intent
        )
        let decodedRetention = try container.decode(
            CollegePortalRetentionResolution.self,
            forKey: .retention
        )
        let decodedOffers = try container.decode([CollegePortalOffer].self, forKey: .offers)
        let decodedOutcome = try container.decode(CollegePortalWindowOutcome.self, forKey: .outcome)
        let decodedFinalScholarship = try container.decode(Bool.self, forKey: .finalIsScholarship)
        let decodedFinalNIL = try container.decode(Int.self, forKey: .finalRosterNIL)
        guard Self.isValid(
            policyVersion: decodedPolicyVersion,
            playerID: decodedPlayerID,
            sourceProgrammeID: decodedSourceID,
            targetSeason: decodedTarget,
            window: decodedWindow,
            openedAt: decodedOpenedAt,
            sourceWasScholarship: decodedSourceScholarship,
            intent: decodedIntent,
            retention: decodedRetention,
            offers: decodedOffers,
            outcome: decodedOutcome,
            finalIsScholarship: decodedFinalScholarship,
            finalRosterNIL: decodedFinalNIL
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .outcome,
                in: container,
                debugDescription: "Portal window record is inconsistent or noncanonical."
            )
        }
        policyVersion = decodedPolicyVersion
        playerID = decodedPlayerID
        sourceProgrammeID = decodedSourceID
        targetSeason = decodedTarget
        window = decodedWindow
        openedAt = decodedOpenedAt
        sourceWasScholarship = decodedSourceScholarship
        intent = decodedIntent
        retention = decodedRetention
        offers = decodedOffers
        outcome = decodedOutcome
        finalIsScholarship = decodedFinalScholarship
        finalRosterNIL = decodedFinalNIL
    }

    var chronologyKey: (Int, Int) { (targetSeason, window.order) }

    private static func isValid(
        policyVersion: Int,
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        openedAt: CalendarState,
        sourceWasScholarship: Bool,
        intent: CollegePortalIntentExplanation,
        retention: CollegePortalRetentionResolution,
        offers: [CollegePortalOffer],
        outcome: CollegePortalWindowOutcome,
        finalIsScholarship: Bool,
        finalRosterNIL: Int
    ) -> Bool {
        guard portalPolicyIsSupported(policyVersion),
              intent.policyVersion == policyVersion,
              retention.policyVersion == policyVersion,
              window.expectedCalendar(targetSeason: targetSeason) == openedAt,
              intent.playerID == playerID,
              intent.sourceProgrammeID == sourceProgrammeID,
              intent.targetSeason == targetSeason,
              intent.window == window,
              intent.evaluatedAt == openedAt,
              offers.count <= CollegePortalPolicyV1.maximumOffersPerEntrant,
              Set(offers.map(\.destinationProgrammeID)).count == offers.count,
              offers == offers.sorted(by: { lhs, rhs in
                  lhs.playerFit.total == rhs.playerFit.total
                      ? lhs.destinationProgrammeID.uuidString
                          < rhs.destinationProgrammeID.uuidString
                      : lhs.playerFit.total > rhs.playerFit.total
              }),
              offers.allSatisfy({ offer in
                  offer.destinationProgrammeID != sourceProgrammeID
                      && offer.knowledge.playerID == playerID
                      && offer.knowledge.sourceProgrammeID == sourceProgrammeID
                      && offer.knowledge.targetSeason == targetSeason
                      && offer.knowledge.window == window
                      && offer.playerFit.policyVersion == policyVersion
                      && offer.destinationAdmission.policyVersion == policyVersion
                      && offer.destinationAdmission.evidence.appearances
                          == intent.evidence.appearances
                      && portalOccurs(offer.knowledge.lastUpdated, noLaterThan: openedAt)
              }),
              (0...CollegePortalPolicyV1.maximumNILBudget).contains(finalRosterNIL)
        else { return false }

        guard let expectation = retentionExpectation(
            policyVersion: policyVersion,
            intent: intent
        ), retention.requiredAdditionalNIL == expectation.requiredAdditionalNIL else {
            return false
        }

        switch retention.outcome {
        case .retained:
            guard retention.requiredAdditionalNIL != nil,
                  retention.intentScoreAfterDecision < intent.selectionThreshold else {
                return false
            }
            let (expected, overflow) = intent.evidence.sourceRosterNIL.addingReportingOverflow(
                retention.appliedAdditionalNIL
            )
            guard !overflow,
                  retention.sourceRosterNILAfterDecision == expected,
                  retention.intentScoreAfterDecision == expectedIntentScore(
                      intent: intent,
                      currentBand: expectation.currentBand,
                      finalRosterNIL: expected
                  ) else { return false }
        case .released:
            guard retention.sourceRosterNILAfterDecision == intent.evidence.sourceRosterNIL,
                  retention.intentScoreAfterDecision == intent.total,
                  retention.intentScoreAfterDecision == expectedIntentScore(
                      intent: intent,
                      currentBand: expectation.currentBand,
                      finalRosterNIL: intent.evidence.sourceRosterNIL
                  ) else {
                return false
            }
        }

        switch outcome {
        case .retainedBySource:
            return retention.outcome == .retained
                && offers.isEmpty
                && finalIsScholarship == sourceWasScholarship
                && finalRosterNIL == retention.sourceRosterNILAfterDecision
        case .returnedToSource:
            return retention.outcome == .released
                && finalIsScholarship == sourceWasScholarship
                && finalRosterNIL == intent.evidence.sourceRosterNIL
        case let .transferred(destinationProgrammeID):
            guard retention.outcome == .released,
                  destinationProgrammeID != sourceProgrammeID,
                  let accepted = offers.first(where: {
                      $0.destinationProgrammeID == destinationProgrammeID
                  }) else { return false }
            return finalIsScholarship && finalRosterNIL == accepted.nilReservation
        }
    }

    private static func retentionExpectation(
        policyVersion: Int,
        intent: CollegePortalIntentExplanation
    ) -> (requiredAdditionalNIL: Int?, currentBand: Int)? {
        guard CollegePortalPolicyV1.supports(policyVersion) else { return nil }
        return CollegePortalPolicyV1.retentionRequirement(
            intentScore: intent.total,
            sourceRosterNIL: intent.evidence.sourceRosterNIL
        )
    }

    private static func expectedIntentScore(
        intent: CollegePortalIntentExplanation,
        currentBand: Int,
        finalRosterNIL: Int
    ) -> Int {
        CollegePortalPolicyV1.expectedIntentScore(
            intentScore: intent.total,
            sourceRosterNIL: intent.evidence.sourceRosterNIL,
            finalRosterNIL: finalRosterNIL
        )
    }
}

public struct CollegePortalWindowSummary: Codable, Sendable, Equatable {
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let completedAt: CalendarState
    public let entrantCount: Int
    public let retainedCount: Int
    public let transferredCount: Int
    public let returnedCount: Int
    public let offerCount: Int

    public init(
        targetSeason: Int,
        window: CollegePortalWindow,
        completedAt: CalendarState,
        entrantCount: Int,
        retainedCount: Int,
        transferredCount: Int,
        returnedCount: Int,
        offerCount: Int
    ) {
        precondition(Self.isValid(
            targetSeason: targetSeason,
            window: window,
            completedAt: completedAt,
            entrantCount: entrantCount,
            retainedCount: retainedCount,
            transferredCount: transferredCount,
            returnedCount: returnedCount,
            offerCount: offerCount
        ))
        self.targetSeason = targetSeason
        self.window = window
        self.completedAt = completedAt
        self.entrantCount = entrantCount
        self.retainedCount = retainedCount
        self.transferredCount = transferredCount
        self.returnedCount = returnedCount
        self.offerCount = offerCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTarget = try container.decode(Int.self, forKey: .targetSeason)
        let decodedWindow = try container.decode(CollegePortalWindow.self, forKey: .window)
        let decodedCompleted = try container.decode(CalendarState.self, forKey: .completedAt)
        let decodedEntrants = try container.decode(Int.self, forKey: .entrantCount)
        let decodedRetained = try container.decode(Int.self, forKey: .retainedCount)
        let decodedTransferred = try container.decode(Int.self, forKey: .transferredCount)
        let decodedReturned = try container.decode(Int.self, forKey: .returnedCount)
        let decodedOffers = try container.decode(Int.self, forKey: .offerCount)
        guard Self.isValid(
            targetSeason: decodedTarget,
            window: decodedWindow,
            completedAt: decodedCompleted,
            entrantCount: decodedEntrants,
            retainedCount: decodedRetained,
            transferredCount: decodedTransferred,
            returnedCount: decodedReturned,
            offerCount: decodedOffers
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .entrantCount,
                in: container,
                debugDescription: "Portal window summary has inconsistent counts."
            )
        }
        targetSeason = decodedTarget
        window = decodedWindow
        completedAt = decodedCompleted
        entrantCount = decodedEntrants
        retainedCount = decodedRetained
        transferredCount = decodedTransferred
        returnedCount = decodedReturned
        offerCount = decodedOffers
    }

    private static func isValid(
        targetSeason: Int,
        window: CollegePortalWindow,
        completedAt: CalendarState,
        entrantCount: Int,
        retainedCount: Int,
        transferredCount: Int,
        returnedCount: Int,
        offerCount: Int
    ) -> Bool {
        guard window.expectedCalendar(targetSeason: targetSeason) == completedAt,
              (0...CollegePortalPolicyV1.portalPoolLimit).contains(entrantCount),
              retainedCount >= 0,
              transferredCount >= 0,
              returnedCount >= 0,
              offerCount >= 0 else { return false }
        let (resolved, overflow) = retainedCount.addingReportingOverflow(transferredCount)
        guard !overflow else { return false }
        let (totalResolved, secondOverflow) = resolved.addingReportingOverflow(returnedCount)
        guard !secondOverflow, totalResolved == entrantCount else { return false }
        return offerCount <= CollegePortalPolicyV1.maximumOffersPerWindow
            && offerCount <= entrantCount * CollegePortalPolicyV1.maximumOffersPerEntrant
    }
}

public struct CollegePortalState: Codable, Sendable, Equatable {
    public let targetSeason: Int
    public private(set) var phase: CollegePortalPhase
    public private(set) var entries: [UUID: CollegePortalWindowRecord]
    public private(set) var summaries: [CollegePortalWindowSummary]

    public init(
        targetSeason: Int,
        phase: CollegePortalPhase = .closed,
        entries: [UUID: CollegePortalWindowRecord] = [:],
        summaries: [CollegePortalWindowSummary] = []
    ) {
        precondition(Self.isValid(
            targetSeason: targetSeason,
            phase: phase,
            entries: entries,
            summaries: summaries,
            requiresStablePhase: false
        ))
        self.targetSeason = targetSeason
        self.phase = phase
        self.entries = entries
        self.summaries = summaries
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTarget = try container.decode(Int.self, forKey: .targetSeason)
        let decodedPhase = try container.decode(CollegePortalPhase.self, forKey: .phase)
        let decodedEntries = try container.decode(
            [UUID: CollegePortalWindowRecord].self,
            forKey: .entries
        )
        let decodedSummaries = try container.decode(
            [CollegePortalWindowSummary].self,
            forKey: .summaries
        )
        guard Self.isValid(
            targetSeason: decodedTarget,
            phase: decodedPhase,
            entries: decodedEntries,
            summaries: decodedSummaries,
            requiresStablePhase: true
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .entries,
                in: container,
                debugDescription: "Portal state is unbounded, noncanonical, or identity-inconsistent."
            )
        }
        targetSeason = decodedTarget
        phase = decodedPhase
        entries = decodedEntries
        summaries = decodedSummaries
    }

    public func encode(to encoder: any Encoder) throws {
        guard Self.isValid(
            targetSeason: targetSeason,
            phase: phase,
            entries: entries,
            summaries: summaries,
            requiresStablePhase: true
        ) else {
            throw EncodingError.invalidValue(
                phase,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription: "Transactional portal phases cannot cross persistence."
                )
            )
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(targetSeason, forKey: .targetSeason)
        try container.encode(phase, forKey: .phase)
        try container.encode(entries, forKey: .entries)
        try container.encode(summaries, forKey: .summaries)
    }

    package var isTransactionallyValid: Bool {
        Self.isValid(
            targetSeason: targetSeason,
            phase: phase,
            entries: entries,
            summaries: summaries,
            requiresStablePhase: false
        )
    }

    private static func isValid(
        targetSeason: Int,
        phase: CollegePortalPhase,
        entries: [UUID: CollegePortalWindowRecord],
        summaries: [CollegePortalWindowSummary],
        requiresStablePhase: Bool
    ) -> Bool {
        guard targetSeason >= 0,
              entries.count <= CollegePortalPolicyV1.portalPoolLimit,
              summaries.count <= CollegePortalPolicyV1.portalWindowCount,
              entries.allSatisfy({ key, record in
                  key == record.playerID && record.targetSeason == targetSeason
              }),
              Set(entries.values.map(\.window)).count <= 1,
              summaries.allSatisfy({ $0.targetSeason == targetSeason }),
              Set(summaries.map(\.window)).count == summaries.count,
              summaries == summaries.sorted(by: { $0.window.order < $1.window.order }),
              fixedCapacityIsValid(entries: entries)
        else { return false }

        if requiresStablePhase && !phase.isStableBoundary { return false }
        switch phase {
        case .awaitingSpring:
            guard summaries.map(\.window) == [.postseason],
                  entries.values.allSatisfy({ $0.window == .postseason }),
                  let summary = summaries.first else { return false }
            return summaryMatches(summary, entries: entries)
        case .closed:
            if summaries.isEmpty { return entries.isEmpty }
            guard summaries.map(\.window) == [.postseason, .spring],
                  entries.values.allSatisfy({ $0.window == .spring }),
                  let spring = summaries.last else { return false }
            return summaryMatches(spring, entries: entries)
        case .postseasonOpen, .springOpen:
            guard !requiresStablePhase else { return false }
            guard let entryWindow = entries.values.first?.window,
                  let summary = summaries.first(where: { $0.window == entryWindow }) else {
                return true
            }
            return summaryMatches(summary, entries: entries)
        }
    }

    private static func summaryMatches(
        _ summary: CollegePortalWindowSummary,
        entries: [UUID: CollegePortalWindowRecord]
    ) -> Bool {
        let records = Array(entries.values)
        return summary.entrantCount == records.count
            && summary.retainedCount == records.filter {
                $0.outcome == .retainedBySource
            }.count
            && summary.transferredCount == records.filter {
                if case .transferred = $0.outcome { return true }
                return false
            }.count
            && summary.returnedCount == records.filter {
                $0.outcome == .returnedToSource
            }.count
            && summary.offerCount == records.reduce(0) { $0 + $1.offers.count }
    }

    private static func fixedCapacityIsValid(
        entries: [UUID: CollegePortalWindowRecord]
    ) -> Bool {
        let offers = entries.values.flatMap(\.offers)
        let offersByDestination = Dictionary(
            grouping: offers,
            by: \.destinationProgrammeID
        )
        for (destinationID, destinationOffers) in offersByDestination {
            guard let capacity = destinationOffers.first?.fixedCapacity,
                  destinationOffers.allSatisfy({ $0.fixedCapacity == capacity }),
                  !destinationOffers.isEmpty else { return false }
            let exactOffer = min(
                CollegePortalPolicyV1.maximumOfferNIL,
                capacity.nilRemaining / destinationOffers.count
                    / CollegePortalPolicyV1.nilBandUnit
                    * CollegePortalPolicyV1.nilBandUnit
            )
            guard destinationOffers.allSatisfy({ $0.nilReservation == exactOffer }),
                  portalSafeSum(destinationOffers.map(\.nilReservation)).map({
                      $0 <= capacity.nilRemaining
                  }) == true else { return false }
            let acceptedPositions = entries.values.compactMap { record -> Position? in
                guard case let .transferred(acceptedDestinationID) = record.outcome,
                      acceptedDestinationID == destinationID else { return nil }
                return record.offers.first {
                    $0.destinationProgrammeID == destinationID
                }?.knowledge.position
            }
            guard capacity.acceptsPortalPositions(acceptedPositions) else { return false }
        }
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case targetSeason
        case phase
        case entries
        case summaries
    }
}
