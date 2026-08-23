import Foundation

public struct CollegePortalMatchedEntrant: Sendable, Equatable {
    public let playerID: UUID
    public let intent: CollegePortalIntentExplanation
    public let retention: CollegePortalRetentionResolution
    public let offers: [CollegePortalOffer]
    public let acceptedDestinationProgrammeID: UUID?

    public var sourceProgrammeID: UUID { intent.sourceProgrammeID }

    fileprivate init(
        playerID: UUID,
        intent: CollegePortalIntentExplanation,
        retention: CollegePortalRetentionResolution,
        offers: [CollegePortalOffer],
        acceptedDestinationProgrammeID: UUID?
    ) {
        self.playerID = playerID
        self.intent = intent
        self.retention = retention
        self.offers = offers
        self.acceptedDestinationProgrammeID = acceptedDestinationProgrammeID
    }
}

public struct CollegePortalMatchingResult: Sendable, Equatable {
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let evaluatedAt: CalendarState
    public let entrants: [CollegePortalMatchedEntrant]
    public let programmes: [UUID: ProgrammeRecruitingState]
    public let scouting: ScoutingState
    let sourceState: GameState

    fileprivate init(
        targetSeason: Int,
        window: CollegePortalWindow,
        evaluatedAt: CalendarState,
        entrants: [CollegePortalMatchedEntrant],
        programmes: [UUID: ProgrammeRecruitingState],
        scouting: ScoutingState,
        sourceState: GameState
    ) {
        self.targetSeason = targetSeason
        self.window = window
        self.evaluatedAt = evaluatedAt
        self.entrants = entrants
        self.programmes = programmes
        self.scouting = scouting
        self.sourceState = sourceState
    }
}

fileprivate struct CollegePortalMatchingEntrantBaseline: Sendable {
    let origin: CollegePortalOriginEvidence
    let originCity: MapCity?
    let priorityWeights: [RecruitingPitch: Rating]
    let alreadyTransferredInTargetSeason: Bool
}

fileprivate struct CollegePortalMatchingDestinationBaseline: Sendable {
    let homeCity: MapCity
    let prestige: Rating
    let recruitingStaffAverage: Rating
    let archivedFinalRankingPosition: Int
    let positionRoomCounts: [Position: Int]
    let capacity: CollegePortalCapacitySnapshot

    var fixedOpenings: Int {
        min(capacity.rosterOpenings, capacity.scholarshipOpenings)
    }
}

/// A sealed, one-window market derived from one authoritative root.
///
/// Retention and fixed capacity are captured here. Matching consumes no caller-authored intents,
/// programme ledgers, observations, priorities, or capacity values.
public struct CollegePortalMarketSnapshot: Sendable {
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let evaluatedAt: CalendarState
    public let retainedPlayerIDs: [UUID]
    public let releasedPlayerIDs: [UUID]

    fileprivate let policy: CollegePortalPolicySnapshot
    fileprivate let programmes: [UUID: ProgrammeRecruitingState]
    fileprivate let retentionByPlayerID: [UUID: CollegePortalRetentionResolution]
    fileprivate let entrantBaselines: [UUID: CollegePortalMatchingEntrantBaseline]
    fileprivate let destinationBaselines: [UUID: CollegePortalMatchingDestinationBaseline]
    fileprivate let scouting: ScoutingState
    fileprivate let sourceState: GameState

    fileprivate init(
        policy: CollegePortalPolicySnapshot,
        programmes: [UUID: ProgrammeRecruitingState],
        retentionByPlayerID: [UUID: CollegePortalRetentionResolution],
        entrantBaselines: [UUID: CollegePortalMatchingEntrantBaseline],
        destinationBaselines: [UUID: CollegePortalMatchingDestinationBaseline],
        scouting: ScoutingState,
        sourceState: GameState
    ) {
        targetSeason = policy.targetSeason
        window = policy.window
        evaluatedAt = policy.evaluatedAt
        retainedPlayerIDs = retentionByPlayerID.compactMap { playerID, resolution in
            resolution.outcome == .retained ? playerID : nil
        }.sorted(by: CollegePortalPolicyV1.uuidRanksBefore)
        releasedPlayerIDs = retentionByPlayerID.compactMap { playerID, resolution in
            resolution.outcome == .released ? playerID : nil
        }.sorted(by: CollegePortalPolicyV1.uuidRanksBefore)
        self.policy = policy
        self.programmes = programmes
        self.retentionByPlayerID = retentionByPlayerID
        self.entrantBaselines = entrantBaselines
        self.destinationBaselines = destinationBaselines
        self.scouting = scouting
        self.sourceState = sourceState
    }
}

fileprivate struct CollegePortalMatchingPair {
    let playerID: UUID
    let destinationProgrammeID: UUID
    let knowledge: CollegePortalKnowledgeSnapshot
    let zeroNILPlayerFit: CollegePortalDestinationFitExplanation
    let destinationAdmission: CollegePortalDestinationAdmissionExplanation
    let capacity: CollegePortalCapacitySnapshot
}

extension CollegePortalPolicyV1 {
    static let mapWidth = 1_000
    static let mapHeight = 700

    public static func makeMarketSnapshot(
        targetSeason: Int,
        window: CollegePortalWindow,
        in state: GameState
    ) -> CollegePortalMarketSnapshot? {
        guard let policy = makeSnapshot(
            targetSeason: targetSeason,
            window: window,
            in: state
        ), state.programmes.count == CollegeRules.programmeCount else { return nil }

        var citiesByID: [UUID: MapCity] = [:]
        for city in state.map.cities {
            guard citiesByID[city.id] == nil,
                  (0...mapWidth).contains(city.x),
                  (0...mapHeight).contains(city.y) else { return nil }
            citiesByID[city.id] = city
        }

        let programmeIDs = state.programmes.ids
        let programmeIDSet = Set(programmeIDs)
        guard Set(state.college.programmes.keys) == programmeIDSet,
              let archive = uniquePortalMatchingArchive(
                  season: targetSeason - 1,
                  in: state
              ),
              archive.finalCollegeRanking.count == programmeIDs.count,
              Set(archive.finalCollegeRanking) == programmeIDSet else { return nil }
        var rankByProgrammeID: [UUID: Int] = [:]
        for (index, programmeID) in archive.finalCollegeRanking.enumerated() {
            guard rankByProgrammeID[programmeID] == nil else { return nil }
            rankByProgrammeID[programmeID] = index + 1
        }

        var ownerByPlayerID: [UUID: UUID] = [:]
        for programme in state.programmes.values {
            guard programme.rosterIDs.count <= CollegeRules.rosterLimit,
                  Set(programme.rosterIDs).count == programme.rosterIDs.count,
                  Set(programme.staffIDs).count == programme.staffIDs.count,
                  programme.staffIDs.allSatisfy({ state.staff[$0] != nil }),
                  let recruiting = state.college.programmes[programme.id],
                  recruiting.programmeID == programme.id,
                  recruiting.nilState.programmeID == programme.id,
                  recruiting.nilState.season == targetSeason,
                  recruiting.nilState.isValid,
                  recruiting.nilState.portalReservations.isEmpty,
                  recruiting.scholarshipPlayerIDs.count <= CollegeRules.scholarshipLimit,
                  Set(recruiting.scholarshipPlayerIDs).count
                    == recruiting.scholarshipPlayerIDs.count,
                  Set(recruiting.scholarshipPlayerIDs)
                    .isSubset(of: Set(programme.rosterIDs)),
                  programme.scholarshipCount == recruiting.scholarshipPlayerIDs.count,
                  let homeCityID = state.identities[programme.id]?.homeCityID,
                  citiesByID[homeCityID] != nil,
                  rankByProgrammeID[programme.id] != nil else { return nil }
            for playerID in programme.rosterIDs {
                guard state.players[playerID] != nil,
                      ownerByPlayerID[playerID] == nil else { return nil }
                ownerByPlayerID[playerID] = programme.id
            }
        }

        var postRetentionProgrammes = state.college.programmes
        var retentionByPlayerID: [UUID: CollegePortalRetentionResolution] = [:]
        for programmeID in programmeIDs {
            guard let actualProgramme = state.college.programmes[programmeID] else { return nil }
            let transition: CollegePortalRetentionTransition
            if let control = state.career.college,
               control.programmeID == programmeID,
               control.responsibilityOwners[.portalAndRetention] == .user {
                guard let baseline = resolveRetention(
                    for: programmeID,
                    programme: actualProgramme,
                    using: policy
                ) else { return nil }
                let requiredPlayerIDs = Set(baseline.resolutions.compactMap {
                    $0.value.outcome == .retained ? $0.key : nil
                })
                var overrides: [UUID: MandatoryDecisionAction] = [:]
                for resolution in state.career.mandatoryDecisionResolutions {
                    guard resolution.programmeID == programmeID,
                          resolution.decidedAt == policy.evaluatedAt,
                          case let .portalRetention(playerID, window) = resolution.subject,
                          window == policy.window else { continue }
                    guard overrides[playerID] == nil else { return nil }
                    overrides[playerID] = resolution.action
                }
                guard Set(overrides.keys) == requiredPlayerIDs,
                      let controlledTransition = resolveRetention(
                          for: programmeID,
                          programme: actualProgramme,
                          overrides: overrides,
                          using: policy
                      ) else { return nil }
                transition = controlledTransition
            } else {
                guard let automatic = resolveRetention(
                    for: programmeID,
                    programme: actualProgramme,
                    using: policy
                ) else { return nil }
                transition = automatic
            }
            postRetentionProgrammes[programmeID] = transition.programme
            for (playerID, resolution) in transition.resolutions {
                guard retentionByPlayerID[playerID] == nil else { return nil }
                retentionByPlayerID[playerID] = resolution
            }
        }
        guard Set(retentionByPlayerID.keys) == Set(policy.intents.map(\.playerID)) else {
            return nil
        }

        var destinationBaselines: [UUID: CollegePortalMatchingDestinationBaseline] = [:]
        for programmeID in programmeIDs {
            guard let programme = state.programmes[programmeID],
                  let recruiting = postRetentionProgrammes[programmeID],
                  let homeCityID = state.identities[programmeID]?.homeCityID,
                  let homeCity = citiesByID[homeCityID],
                  let rank = rankByProgrammeID[programmeID] else { return nil }
            var positionCounts: [Position: Int] = [:]
            for playerID in programme.rosterIDs {
                guard let player = state.players[playerID] else { return nil }
                positionCounts[player.position, default: 0] += 1
            }
            let staffRatings = programme.staffIDs.compactMap {
                state.staff[$0]?.rating(.recruiting).value
            }
            guard staffRatings.count == programme.staffIDs.count else { return nil }
            let staffAverage = staffRatings.isEmpty
                ? ratingFloor
                : staffRatings.reduce(0, +) / staffRatings.count
            let capacity = CollegePortalCapacitySnapshot(
                programmeID: programmeID,
                targetSeason: targetSeason,
                window: window,
                capturedAt: policy.evaluatedAt,
                // The active limits, not frozen copies of them. Capacity is a reading of a
                // roster as it stands now, so the openings the live rules call openings are the
                // ones matching has to allocate. `CollegePortalPolicyV1` kept its own
                // `rosterLimit` and `scholarshipLimit` until 2026-08-23; they were still equal to
                // `CollegeRules`', and nothing compared them -- exactly the state the frozen
                // `minimumPlayableRosterByPosition` just below is in, where the same silence has
                // already let `.runningBack` and `.linebacker` fall a man below `SharedRules`.
                // (`d5400e1` fixes the deficit reading on its own branch; it is deliberately not
                // duplicated here.) The frozen policy's reason -- an archived schema-six
                // explanation stays decodable through a balance pass -- does not reach a live
                // computation.
                rosterOpenings: max(0, CollegeRules.rosterLimit - programme.rosterIDs.count),
                scholarshipOpenings: max(
                    0,
                    CollegeRules.scholarshipLimit - recruiting.scholarshipPlayerIDs.count
                ),
                minimumCoverageDeficits: Dictionary(uniqueKeysWithValues:
                    CollegePortalPolicyV1.minimumPlayableRosterByPosition.compactMap {
                        position, minimum in
                        let deficit = max(0, minimum - (positionCounts[position] ?? 0))
                        return deficit > 0 ? (position, deficit) : nil
                    }
                ),
                nilRemaining: recruiting.nilState.remaining
            )
            destinationBaselines[programmeID] = CollegePortalMatchingDestinationBaseline(
                homeCity: homeCity,
                prestige: programme.prestige,
                recruitingStaffAverage: Rating(staffAverage),
                archivedFinalRankingPosition: rank,
                positionRoomCounts: positionCounts,
                capacity: capacity
            )
        }

        var entrantBaselines: [UUID: CollegePortalMatchingEntrantBaseline] = [:]
        for intent in policy.intents {
            guard ownerByPlayerID[intent.playerID] == intent.sourceProgrammeID,
                  let career = state.people.playerCareers[intent.playerID] else { return nil }
            let origin: CollegePortalOriginEvidence
            let originCity: MapCity?
            let priorities: [RecruitingPitch: Rating]
            if let recruitingOrigin = career.recruitingOrigin {
                guard Set(recruitingOrigin.recruitingPriorities.keys)
                        == Set(pitchOrder),
                      let knownCity = citiesByID[recruitingOrigin.originCityID] else { return nil }
                origin = .known(cityID: recruitingOrigin.originCityID)
                originCity = knownCity
                priorities = recruitingOrigin.recruitingPriorities
            } else {
                origin = .neutral
                originCity = nil
                priorities = Dictionary(uniqueKeysWithValues: pitchOrder.map {
                    ($0, Rating(neutralPitchWeight))
                })
            }
            let alreadyTransferred = career.portalWindows.contains { record in
                guard record.targetSeason == targetSeason else { return false }
                if case .transferred = record.outcome { return true }
                return false
            }
            entrantBaselines[intent.playerID] = CollegePortalMatchingEntrantBaseline(
                origin: origin,
                originCity: originCity,
                priorityWeights: priorities,
                alreadyTransferredInTargetSeason: alreadyTransferred
            )
        }

        return CollegePortalMarketSnapshot(
            policy: policy,
            programmes: postRetentionProgrammes,
            retentionByPlayerID: retentionByPlayerID,
            entrantBaselines: entrantBaselines,
            destinationBaselines: destinationBaselines,
            scouting: state.scouting,
            sourceState: state
        )
    }

    public static func match(
        using market: CollegePortalMarketSnapshot
    ) -> CollegePortalMatchingResult? {
        var intentByPlayerID: [UUID: CollegePortalIntentExplanation] = [:]
        for intent in market.policy.intents {
            guard intentByPlayerID[intent.playerID] == nil else { return nil }
            intentByPlayerID[intent.playerID] = intent
        }
        let candidates = market.policy.intents.filter { intent in
            market.retentionByPlayerID[intent.playerID]?.outcome == .released
                && market.entrantBaselines[intent.playerID]?
                    .alreadyTransferredInTargetSeason == false
        }.sorted { uuidRanksBefore($0.playerID, $1.playerID) }
        let destinations = market.destinationBaselines.keys.filter {
            market.destinationBaselines[$0]?.fixedOpenings ?? 0 > 0
        }.sorted(by: uuidRanksBefore)

        var generatedKnowledge: [CollegePortalKnowledgeSnapshot] = []
        for destinationID in destinations {
            for intent in candidates where intent.sourceProgrammeID != destinationID {
                guard let knowledge = knowledgeSnapshot(
                    observerProgrammeID: destinationID,
                    playerID: intent.playerID,
                    using: market.policy
                ) else { return nil }
                generatedKnowledge.append(knowledge)
            }
        }
        var pairsByDestinationID: [UUID: [CollegePortalMatchingPair]] = [:]
        for knowledge in generatedKnowledge {
            guard let intent = intentByPlayerID[knowledge.playerID],
                let entrant = market.entrantBaselines[knowledge.playerID],
                let destination = market.destinationBaselines[knowledge.observerProgrammeID],
                let targetCount = positionTargetCount(for: knowledge.position),
                let observedSchemeFit = knowledge.estimatedAttributes[.schemeFit]
            else { return nil }
            let squaredDistance: Int?
            if let originCity = entrant.originCity {
                squaredDistance = originCity.squaredDistance(to: destination.homeCity)
            } else {
                squaredDistance = nil
            }
            let destinationEvidence = CollegePortalDestinationEvidence(
                candidatePosition: knowledge.position,
                origin: entrant.origin,
                destinationHomeCityID: destination.homeCity.id,
                squaredCityDistance: squaredDistance,
                destinationPositionRoomCount: destination.positionRoomCounts[
                    knowledge.position
                ] ?? 0,
                positionTargetCount: targetCount,
                observedSchemeFit: observedSchemeFit,
                priorityWeights: entrant.priorityWeights,
                prestige: destination.prestige,
                recruitingStaffAverage: destination.recruitingStaffAverage,
                archivedFinalRankingPosition: destination.archivedFinalRankingPosition
            )
            let zeroFit = CollegePortalDestinationFitExplanation(
                policyVersion: version,
                playerID: knowledge.playerID,
                programmeID: knowledge.observerProgrammeID,
                evidence: destinationEvidence,
                components: destinationFitComponents(
                    for: destinationEvidence,
                    nilAllocationAdjustment: 0
                ),
                nilAllocationAdjustment: 0,
                knowledgeAdjustment: 0
            )
            let admissionEvidence = CollegePortalAdmissionEvidence(
                position: knowledge.position,
                estimatedOverall: knowledge.estimatedOverall,
                estimatedPotential: knowledge.estimatedPotential,
                appearances: intent.evidence.appearances,
                fixedPositionRoomCount: destinationEvidence.destinationPositionRoomCount,
                estimatedSchemeFit: observedSchemeFit,
                confidence: knowledge.confidence
            )
            pairsByDestinationID[knowledge.observerProgrammeID, default: []].append(
                CollegePortalMatchingPair(
                playerID: knowledge.playerID,
                destinationProgrammeID: knowledge.observerProgrammeID,
                knowledge: knowledge,
                zeroNILPlayerFit: zeroFit,
                destinationAdmission: CollegePortalDestinationAdmissionExplanation(
                    policyVersion: version,
                    playerID: knowledge.playerID,
                    programmeID: knowledge.observerProgrammeID,
                    evidence: admissionEvidence,
                    components: admissionComponents(for: admissionEvidence)
                ),
                capacity: destination.capacity
                )
            )
        }

        var willingPairsByPlayerID: [UUID: [CollegePortalMatchingPair]] = [:]
        for destinationID in destinations {
            guard let destination = market.destinationBaselines[destinationID] else { return nil }
            let ordered = (pairsByDestinationID[destinationID] ?? [])
                .sorted(by: admissionPairRanksBefore)
            let willingnessLimit = destination.fixedOpenings * admissionCandidatesPerOpening
            for pair in ordered.prefix(willingnessLimit) {
                willingPairsByPlayerID[pair.playerID, default: []].append(pair)
            }
        }

        var shortlistByPlayerID: [UUID: [CollegePortalMatchingPair]] = [:]
        for intent in candidates {
            let shortlist = (willingPairsByPlayerID[intent.playerID] ?? [])
                .sorted(by: zeroFitPairRanksBefore)
            shortlistByPlayerID[intent.playerID] = Array(
                shortlist.prefix(maximumShortlistDestinations)
            )
        }

        var offerCountByDestination: [UUID: Int] = [:]
        for pair in shortlistByPlayerID.values.flatMap({ $0 }) {
            offerCountByDestination[pair.destinationProgrammeID, default: 0] += 1
        }
        var programmes = market.programmes
        var offersByPlayerID: [UUID: [CollegePortalOffer]] = [:]
        for playerID in shortlistByPlayerID.keys.sorted(by: uuidRanksBefore) {
            guard let shortlist = shortlistByPlayerID[playerID] else { return nil }
            var offers: [CollegePortalOffer] = []
            for pair in shortlist {
                guard let count = offerCountByDestination[pair.destinationProgrammeID],
                      count > 0,
                      var programme = programmes[pair.destinationProgrammeID] else { return nil }
                let amount = min(
                    maximumOfferNIL,
                    pair.capacity.nilRemaining / count / nilBandUnit * nilBandUnit
                )
                guard programme.setPortalNILReservation(amount, playerID: playerID) else {
                    return nil
                }
                programmes[pair.destinationProgrammeID] = programme
                let nilAdjustment = amount / nilBandUnit
                let finalFit = CollegePortalDestinationFitExplanation(
                    policyVersion: version,
                    playerID: playerID,
                    programmeID: pair.destinationProgrammeID,
                    evidence: pair.zeroNILPlayerFit.evidence,
                    components: destinationFitComponents(
                        for: pair.zeroNILPlayerFit.evidence,
                        nilAllocationAdjustment: nilAdjustment
                    ),
                    nilAllocationAdjustment: nilAdjustment,
                    knowledgeAdjustment: 0
                )
                offers.append(CollegePortalOffer(
                    destinationProgrammeID: pair.destinationProgrammeID,
                    nilReservation: amount,
                    knowledge: pair.knowledge,
                    playerFit: finalFit,
                    destinationAdmission: pair.destinationAdmission,
                    fixedCapacity: pair.capacity
                ))
            }
            offersByPlayerID[playerID] = offers.sorted(by: offerPreferenceRanksBefore)
        }

        var scouting = market.scouting
        guard scouting.recordPortalKnowledgeBatch(
            offersByPlayerID.values.flatMap { $0.map(\.knowledge) },
            targetSeason: market.targetSeason,
            window: market.window
        ) else { return nil }

        guard let acceptedDestinationByPlayerID = deferredAcceptance(
            offersByPlayerID: offersByPlayerID,
            destinationBaselines: market.destinationBaselines
        ) else { return nil }
        for (playerID, offers) in offersByPlayerID {
            for offer in offers
                where acceptedDestinationByPlayerID[playerID] != offer.destinationProgrammeID {
                guard var programme = programmes[offer.destinationProgrammeID] else { return nil }
                let refunded = programme.refundPortalNILReservation(for: playerID)
                guard offer.nilReservation == 0
                    ? refunded == nil
                    : refunded == offer.nilReservation else { return nil }
                programmes[offer.destinationProgrammeID] = programme
            }
        }

        let entrants = market.policy.intents.sorted {
            uuidRanksBefore($0.playerID, $1.playerID)
        }.compactMap { intent -> CollegePortalMatchedEntrant? in
            guard let retention = market.retentionByPlayerID[intent.playerID] else { return nil }
            return CollegePortalMatchedEntrant(
                playerID: intent.playerID,
                intent: intent,
                retention: retention,
                offers: offersByPlayerID[intent.playerID] ?? [],
                acceptedDestinationProgrammeID: acceptedDestinationByPlayerID[intent.playerID]
            )
        }
        guard entrants.count == market.policy.intents.count else { return nil }
        return CollegePortalMatchingResult(
            targetSeason: market.targetSeason,
            window: market.window,
            evaluatedAt: market.evaluatedAt,
            entrants: entrants,
            programmes: programmes,
            scouting: scouting,
            sourceState: market.sourceState
        )
    }

    static func uuidRanksBefore(_ lhs: UUID, _ rhs: UUID) -> Bool {
        lhs.uuidString < rhs.uuidString
    }

    private static func uniquePortalMatchingArchive(
        season: Int,
        in state: GameState
    ) -> SeasonArchive? {
        let matches = state.competition.archives.filter { $0.season == season }
        return matches.count == 1 ? matches[0] : nil
    }

    private static func admissionPairRanksBefore(
        _ lhs: CollegePortalMatchingPair,
        _ rhs: CollegePortalMatchingPair
    ) -> Bool {
        if lhs.destinationAdmission.total != rhs.destinationAdmission.total {
            return lhs.destinationAdmission.total > rhs.destinationAdmission.total
        }
        return uuidRanksBefore(lhs.playerID, rhs.playerID)
    }

    private static func zeroFitPairRanksBefore(
        _ lhs: CollegePortalMatchingPair,
        _ rhs: CollegePortalMatchingPair
    ) -> Bool {
        if lhs.zeroNILPlayerFit.total != rhs.zeroNILPlayerFit.total {
            return lhs.zeroNILPlayerFit.total > rhs.zeroNILPlayerFit.total
        }
        return uuidRanksBefore(lhs.destinationProgrammeID, rhs.destinationProgrammeID)
    }

    private static func offerPreferenceRanksBefore(
        _ lhs: CollegePortalOffer,
        _ rhs: CollegePortalOffer
    ) -> Bool {
        if lhs.playerFit.total != rhs.playerFit.total {
            return lhs.playerFit.total > rhs.playerFit.total
        }
        return uuidRanksBefore(lhs.destinationProgrammeID, rhs.destinationProgrammeID)
    }

    private static func deferredAcceptance(
        offersByPlayerID: [UUID: [CollegePortalOffer]],
        destinationBaselines: [UUID: CollegePortalMatchingDestinationBaseline]
    ) -> [UUID: UUID]? {
        var nextChoiceByPlayerID = Dictionary(
            uniqueKeysWithValues: offersByPlayerID.keys.map { ($0, 0) }
        )
        var heldByDestination: [UUID: [UUID]] = [:]
        var queue = offersByPlayerID.keys.sorted(by: uuidRanksBefore)
        while let playerID = queue.first {
            queue.removeFirst()
            guard let offers = offersByPlayerID[playerID],
                  let nextChoice = nextChoiceByPlayerID[playerID] else { return nil }
            guard nextChoice < offers.count else { continue }
            let offer = offers[nextChoice]
            nextChoiceByPlayerID[playerID] = nextChoice + 1
            guard let capacity = destinationBaselines[
                offer.destinationProgrammeID
            ]?.fixedOpenings, capacity > 0 else { return nil }
            var held = heldByDestination[offer.destinationProgrammeID] ?? []
            guard !held.contains(playerID) else { return nil }
            held.append(playerID)
            held.sort { lhsID, rhsID in
                guard let lhs = offersByPlayerID[lhsID]?.first(where: {
                    $0.destinationProgrammeID == offer.destinationProgrammeID
                }), let rhs = offersByPlayerID[rhsID]?.first(where: {
                    $0.destinationProgrammeID == offer.destinationProgrammeID
                }) else { return uuidRanksBefore(lhsID, rhsID) }
                if lhs.destinationAdmission.total != rhs.destinationAdmission.total {
                    return lhs.destinationAdmission.total > rhs.destinationAdmission.total
                }
                return uuidRanksBefore(lhsID, rhsID)
            }
            var acceptedHeld: [UUID] = []
            for candidateID in held {
                guard let candidateOffer = offersByPlayerID[candidateID]?.first(where: {
                    $0.destinationProgrammeID == offer.destinationProgrammeID
                }) else { return nil }
                let proposedPositions = acceptedHeld.compactMap { acceptedID in
                    offersByPlayerID[acceptedID]?.first(where: {
                        $0.destinationProgrammeID == offer.destinationProgrammeID
                    })?.knowledge.position
                } + [candidateOffer.knowledge.position]
                if candidateOffer.fixedCapacity.acceptsPortalPositions(proposedPositions) {
                    acceptedHeld.append(candidateID)
                }
            }
            let acceptedSet = Set(acceptedHeld)
            let rejected = held.filter { !acceptedSet.contains($0) }
            heldByDestination[offer.destinationProgrammeID] = acceptedHeld
            queue.append(contentsOf: rejected)
            queue.sort(by: uuidRanksBefore)
        }
        var accepted: [UUID: UUID] = [:]
        for destinationID in heldByDestination.keys.sorted(by: uuidRanksBefore) {
            for playerID in heldByDestination[destinationID] ?? [] {
                guard accepted[playerID] == nil else { return nil }
                accepted[playerID] = destinationID
            }
        }
        return accepted
    }
}
