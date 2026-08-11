import Foundation

public struct CollegePortalRetentionTransition: Sendable, Equatable {
    public let programme: ProgrammeRecruitingState
    public let resolutions: [UUID: CollegePortalRetentionResolution]

    public init(
        programme: ProgrammeRecruitingState,
        resolutions: [UUID: CollegePortalRetentionResolution]
    ) {
        self.programme = programme
        self.resolutions = resolutions
    }
}

fileprivate struct CollegePortalPlayerTruth: Sendable {
    let position: Position
    let attributes: Attributes
    let potential: Rating
}

/// A sealed, single-window view of the authoritative world used by portal policy.
///
/// This is intentionally not `Codable`: durable explanations are persisted separately, while this
/// value exists only for one atomic policy transaction. Its initializer is file-private so callers
/// cannot pair forged intent evidence with private player truth or a different root seed.
public struct CollegePortalPolicySnapshot: Sendable {
    public let targetSeason: Int
    public let window: CollegePortalWindow
    public let evaluatedAt: CalendarState
    public let intents: [CollegePortalIntentExplanation]

    fileprivate let rootSeed: UInt64
    fileprivate let intentsByPlayerID: [UUID: CollegePortalIntentExplanation]
    fileprivate let playerTruthByID: [UUID: CollegePortalPlayerTruth]
    fileprivate let recruitingStaffAverageByObserverID: [UUID: Int]

    fileprivate init(
        targetSeason: Int,
        window: CollegePortalWindow,
        evaluatedAt: CalendarState,
        intents: [CollegePortalIntentExplanation],
        rootSeed: UInt64,
        playerTruthByID: [UUID: CollegePortalPlayerTruth],
        recruitingStaffAverageByObserverID: [UUID: Int]
    ) {
        self.targetSeason = targetSeason
        self.window = window
        self.evaluatedAt = evaluatedAt
        self.intents = intents
        self.rootSeed = rootSeed
        intentsByPlayerID = Dictionary(uniqueKeysWithValues: intents.map {
            ($0.playerID, $0)
        })
        self.playerTruthByID = playerTruthByID
        self.recruitingStaffAverageByObserverID = recruitingStaffAverageByObserverID
    }
}

/// The immutable policy that gives schema-six portal explanations their meaning.
///
/// These values deliberately do not delegate to the active `CollegeRules`. A future balance pass
/// may change the active policy without making a version-one career record undecodable.
public enum CollegePortalPolicyV1 {
    public static let version = 1
    public static let maximumEntrants = 300
    public static let maximumKnowledgePerObserverWindow = 300
    public static let maximumKnowledgeObservers = 134
    public static let maximumKnowledgeTargetSeasonSlices = 1
    public static let maximumScoutingEvidence = 10_000
    public static let maximumKnowledgeConfidence = 95
    public static let intentSelectionThreshold = 25
    public static let maximumIntentComponentMagnitude = 20
    public static let neutralPitchWeight = 70
    public static let maximumOffersPerEntrant = 5
    public static let admissionCandidatesPerOpening = 5
    public static let maximumShortlistDestinations = 5
    public static let maximumOfferNIL = 500
    public static let maximumSquaredCityDistance = 1_490_000
    public static let maximumAdmissionComponentMagnitude = 20

    package static let pitchOrder: [RecruitingPitch] = [
        .proximity,
        .prestige,
        .playingTime,
        .schemeFit,
        .relationship,
        .staffQuality,
        .teamSuccess,
        .nilOpportunity,
    ]

    static let programmeCount = maximumKnowledgeObservers
    static let portalPoolLimit = maximumEntrants
    static let portalWindowCount = 2
    static let maximumOffersPerWindow = portalPoolLimit * maximumOffersPerEntrant
    static let postseasonCalendarWeek = 21
    static let springCalendarWeek = 1
    static let maximumGamesPerSeason = 16
    static let rosterLimit = 105
    static let minimumPlayableRosterByPosition: [Position: Int] = [
        .quarterback: 1, .runningBack: 1, .wideReceiver: 3, .tightEnd: 1,
        .leftTackle: 1, .guardPosition: 2, .center: 1, .rightTackle: 1,
        .edgeRusher: 2, .defensiveTackle: 2, .linebacker: 2,
        .cornerback: 3, .safety: 2, .kicker: 1, .punter: 1,
    ]
    static let scholarshipLimit = 85
    static let eligibilityClockYears = 5
    static let maximumNILBudget = 9_900
    static let nilBandUnit = 100
    static let maximumNILBand = 20
    static let ratingFloor = 40
    static let ratingSpan = 59
    static let regularSeasonGames = 12
    static let maximumFitNILAdjustment = maximumOfferNIL / nilBandUnit
    static let admissionReasonCount = 6
    static let admissionTotalRange = -120...120

    private static let rosterTargets: [Position: Int] = [
        .quarterback: 4,
        .runningBack: 7,
        .wideReceiver: 14,
        .tightEnd: 6,
        .leftTackle: 6,
        .guardPosition: 12,
        .center: 5,
        .rightTackle: 6,
        .edgeRusher: 9,
        .defensiveTackle: 9,
        .linebacker: 11,
        .cornerback: 9,
        .safety: 5,
        .kicker: 1,
        .punter: 1,
    ]

    private static let sharedKnowledgeAttributes: [Attribute] = [
        .speed, .strength, .agility, .durability,
        .awareness, .schemeFit, .temperament, .workEthic, .clutch,
    ]

    private static let knowledgeAttributesByPosition: [Position: [Attribute]] = [
        .quarterback: sharedKnowledgeAttributes + [
            .accuracyShort, .accuracyMid, .accuracyDeep, .armStrength, .decision, .poise,
        ],
        .runningBack: sharedKnowledgeAttributes + [
            .vision, .elusiveness, .power, .hands, .passBlock,
        ],
        .wideReceiver: sharedKnowledgeAttributes + [
            .routeRunning, .release, .hands,
        ],
        .tightEnd: sharedKnowledgeAttributes + [
            .routeRunning, .release, .hands, .runBlock, .passBlock,
        ],
        .leftTackle: sharedKnowledgeAttributes + [.passBlock, .runBlock],
        .guardPosition: sharedKnowledgeAttributes + [.passBlock, .runBlock],
        .center: sharedKnowledgeAttributes + [.passBlock, .runBlock],
        .rightTackle: sharedKnowledgeAttributes + [.passBlock, .runBlock],
        .edgeRusher: sharedKnowledgeAttributes + [
            .passRush, .finesse, .power, .motor, .runDefence, .shed, .gapDiscipline,
            .tackling, .pursuit, .blockLeverage,
        ],
        .defensiveTackle: sharedKnowledgeAttributes + [
            .passRush, .finesse, .power, .motor, .runDefence, .shed, .gapDiscipline,
            .tackling, .pursuit, .blockLeverage,
        ],
        .linebacker: sharedKnowledgeAttributes + [
            .coverage, .runDefence, .shed, .gapDiscipline, .tackling, .pursuit,
            .passRush, .finesse, .power, .motor,
        ],
        .cornerback: sharedKnowledgeAttributes + [
            .coverage, .release, .tackling, .pursuit, .hands,
        ],
        .safety: sharedKnowledgeAttributes + [
            .coverage, .runDefence, .tackling, .pursuit, .hands,
        ],
        .kicker: sharedKnowledgeAttributes + [.legStrength, .kickAccuracy, .poise],
        .punter: sharedKnowledgeAttributes + [.legStrength, .kickAccuracy],
    ]

    static func supports(_ policyVersion: Int) -> Bool {
        policyVersion == version
    }

    package static func expectedCalendar(
        targetSeason: Int,
        window: CollegePortalWindow
    ) -> CalendarState? {
        switch window {
        case .postseason:
            guard targetSeason > 0 else { return nil }
            return CalendarState(
                season: targetSeason - 1,
                week: postseasonCalendarWeek
            )
        case .spring:
            guard targetSeason >= 0 else { return nil }
            return CalendarState(season: targetSeason, week: springCalendarWeek)
        }
    }

    public static func makeSnapshot(
        targetSeason: Int,
        window: CollegePortalWindow,
        in state: GameState
    ) -> CollegePortalPolicySnapshot? {
        let portal = state.college.portal
        switch window {
        case .postseason:
            guard portal.phase == .closed,
                  portal.entries.isEmpty,
                  portal.summaries.isEmpty else { return nil }
        case .spring:
            guard portal.phase == .awaitingSpring else { return nil }
        }
        guard portal.targetSeason == targetSeason,
              state.college.recruitingSeason == targetSeason,
              state.programmes.count <= maximumKnowledgeObservers,
              let evaluatedAt = window.expectedCalendar(targetSeason: targetSeason),
              state.calendar == evaluatedAt else { return nil }
        let intents = deriveIntents(
            targetSeason: targetSeason,
            window: window,
            in: state
        )
        let truths = Dictionary(uniqueKeysWithValues: intents.compactMap { intent in
            state.players[intent.playerID].map { player in
                (
                    player.id,
                    CollegePortalPlayerTruth(
                        position: player.position,
                        attributes: player.attributes,
                        potential: player.potential
                    )
                )
            }
        })
        guard truths.count == intents.count else { return nil }
        let staffAverages = Dictionary(uniqueKeysWithValues: state.programmes.values.map {
            programme -> (UUID, Int) in
            let ratings = programme.staffIDs.compactMap {
                state.staff[$0]?.rating(.recruiting).value
            }
            return (
                programme.id,
                ratings.isEmpty ? ratingFloor : ratings.reduce(0, +) / ratings.count
            )
        })
        return CollegePortalPolicySnapshot(
            targetSeason: targetSeason,
            window: window,
            evaluatedAt: evaluatedAt,
            intents: intents,
            rootSeed: state.league.seed,
            playerTruthByID: truths,
            recruitingStaffAverageByObserverID: staffAverages
        )
    }

    public static func intentComponents(
        for evidence: CollegePortalIntentEvidence
    ) -> [CollegePortalIntentComponent] {
        let targetPositionCount = max(1, rosterTargets[evidence.position] ?? 1)
        return [
            CollegePortalIntentComponent(
                reason: .playingTime,
                value: 20 - min(20, evidence.appearances * 20 / regularSeasonGames)
            ),
            CollegePortalIntentComponent(
                reason: .rosterPath,
                value: min(
                    15,
                    max(0, evidence.sourcePositionRoomSize - 1) * 15
                        / max(1, targetPositionCount - 1)
                )
            ),
            CollegePortalIntentComponent(
                reason: .relationship,
                value: evidence.relationshipScore.map { 10 - $0 / 5 }
                    ?? -min(5, evidence.seasonsAtSource)
            ),
            CollegePortalIntentComponent(
                reason: .nilAllocation,
                value: -min(maximumNILBand, evidence.sourceRosterNIL / nilBandUnit)
            ),
            CollegePortalIntentComponent(
                reason: .teamSuccess,
                value: (evidence.sourceFinalRankingPosition - 1) * 20
                    / (programmeCount - 1) - 10
            ),
            CollegePortalIntentComponent(
                reason: .restless,
                value: evidence.isRestless ? 10 : 0
            ),
        ]
    }

    public static func destinationFitComponents(
        for evidence: CollegePortalDestinationEvidence,
        nilAllocationAdjustment: Int
    ) -> [RecruitingScoreComponent] {
        let proximity: Int
        switch evidence.origin {
        case .known:
            proximity = 10
                - (evidence.squaredCityDistance ?? maximumSquaredCityDistance) * 10
                    / maximumSquaredCityDistance
        case .neutral:
            proximity = 5
        }
        let raw: [RecruitingPitch: Int] = [
            .proximity: proximity,
            .prestige: (evidence.prestige.value - ratingFloor) * 10 / ratingSpan,
            .playingTime: max(
                0,
                10 - evidence.destinationPositionRoomCount * 5
                    / evidence.positionTargetCount
            ),
            .schemeFit: (evidence.observedSchemeFit.value - ratingFloor) * 10 / ratingSpan,
            .relationship: 0,
            .staffQuality: (evidence.recruitingStaffAverage.value - ratingFloor) * 10
                / ratingSpan,
            .teamSuccess: 10 - (evidence.archivedFinalRankingPosition - 1) * 10
                / (programmeCount - 1),
            .nilOpportunity: min(10, nilAllocationAdjustment),
        ]
        return pitchOrder.map { reason in
            RecruitingScoreComponent(
                reason: reason,
                value: (raw[reason] ?? 0) * (evidence.priorityWeights[reason]?.value ?? 0)
                    / 99
            )
        }
    }

    public static func admissionComponents(
        for evidence: CollegePortalAdmissionEvidence
    ) -> [CollegePortalAdmissionComponent] {
        let targetPositionCount = positionTargetCount(for: evidence.position) ?? 1
        return [
            CollegePortalAdmissionComponent(
                reason: .readiness,
                value: (evidence.estimatedOverall.value - ratingFloor) * 20 / ratingSpan
            ),
            CollegePortalAdmissionComponent(
                reason: .potential,
                value: (evidence.estimatedPotential.value - ratingFloor) * 10 / ratingSpan
            ),
            CollegePortalAdmissionComponent(
                reason: .production,
                value: min(10, evidence.appearances * 10 / regularSeasonGames)
            ),
            CollegePortalAdmissionComponent(
                reason: .positionNeed,
                value: max(
                    0,
                    10 - evidence.fixedPositionRoomCount * 5 / targetPositionCount
                )
            ),
            CollegePortalAdmissionComponent(
                reason: .schemeFit,
                value: (evidence.estimatedSchemeFit.value - ratingFloor) * 10 / ratingSpan
            ),
            CollegePortalAdmissionComponent(
                reason: .uncertainty,
                value: -(maximumKnowledgeConfidence - evidence.confidence) * 10
                    / maximumKnowledgeConfidence
            ),
        ]
    }

    static func positionTargetCount(for position: Position) -> Int? {
        rosterTargets[position]
    }

    package static func ratedAttributes(for position: Position) -> [Attribute] {
        knowledgeAttributesByPosition[position] ?? []
    }

    private static func canonicalSelection<S: Sequence>(
        _ intents: S
    ) -> [CollegePortalIntentExplanation] where S.Element == CollegePortalIntentExplanation {
        let candidates = Array(intents)
        guard Set(candidates.map(\.playerID)).count == candidates.count,
              candidates.allSatisfy(intentIsValid) else { return [] }
        return Array(candidates.sorted(by: intentRanksBefore).prefix(maximumEntrants))
    }

    private static func deriveIntents(
        targetSeason: Int,
        window: CollegePortalWindow,
        in state: GameState
    ) -> [CollegePortalIntentExplanation] {
        guard targetSeason > 0,
              state.college.recruitingSeason == targetSeason,
              state.college.portal.targetSeason == targetSeason,
              let evaluatedAt = window.expectedCalendar(targetSeason: targetSeason),
              state.calendar == evaluatedAt,
              let archive = uniqueArchive(season: targetSeason - 1, in: state)
        else { return [] }

        let ownersByPlayer = Dictionary(grouping: state.programmes.values.flatMap { programme in
            programme.rosterIDs.map { ($0, programme.id) }
        }, by: { $0.0 })
        let explanations = state.players.values.compactMap { player -> CollegePortalIntentExplanation? in
            guard let eligibility = player.eligibility,
                  !eligibility.isExhausted,
                  player.contract == nil,
                  state.people.playerLifecycle[player.id]?.status == .active,
                  let ownership = ownersByPlayer[player.id],
                  ownership.count == 1,
                  let sourceID = ownership.first?.1,
                  let source = state.programmes[sourceID],
                  let recruiting = state.college.programmes[sourceID],
                  recruiting.nilState.season == targetSeason,
                  let career = state.people.playerCareers[player.id],
                  career.endedAt == nil,
                  let completed = career.seasons.first(where: {
                      $0.season == targetSeason - 1 && $0.tier == .college
                  }),
                  windowHistoryAllowsEntry(
                      window: window,
                      targetSeason: targetSeason,
                      currentSourceID: sourceID,
                      completedSourceID: completed.organisationID,
                      records: career.portalWindows
                  ),
                  let rank = uniqueRank(of: sourceID, in: archive.finalCollegeRanking)
            else { return nil }

            let roomSize = source.rosterIDs.reduce(into: 0) { count, rosterPlayerID in
                if state.players[rosterPlayerID]?.position == player.position { count += 1 }
            }
            let seasonsAtSource = career.seasons.filter {
                $0.tier == .college && $0.organisationID == sourceID
            }.count
            let targetPostseason = career.portalWindows.first {
                $0.targetSeason == targetSeason && $0.window == .postseason
            }
            if window == .spring,
               let targetPostseason,
               case .transferred = targetPostseason.outcome {
                guard seasonsAtSource == 0 else { return nil }
            } else {
                guard seasonsAtSource >= 1 else { return nil }
            }
            let relationship = career.recruitingOrigin.flatMap { origin in
                origin.programmeID == sourceID ? origin.finalInterest : nil
            }
            let evidence = CollegePortalIntentEvidence(
                position: player.position,
                starts: completed.starts,
                appearances: completed.games,
                sourcePositionRoomSize: roomSize,
                seasonsAtSource: seasonsAtSource,
                sourceFinalRankingPosition: rank,
                sourceRosterNIL: recruiting.nilState.rosterAllocations[player.id] ?? 0,
                relationshipScore: relationship,
                isRestless: player.has(.restless)
            )
            let components = intentComponents(for: evidence)
            guard components.reduce(0, { $0 + $1.value }) >= intentSelectionThreshold else {
                return nil
            }
            return CollegePortalIntentExplanation(
                policyVersion: version,
                playerID: player.id,
                sourceProgrammeID: sourceID,
                targetSeason: targetSeason,
                window: window,
                evaluatedAt: evaluatedAt,
                evidence: evidence,
                components: components,
                selectionThreshold: intentSelectionThreshold
            )
        }
        return canonicalSelection(explanations)
    }

    public static func knowledgeSnapshot(
        observerProgrammeID: UUID,
        playerID: UUID,
        using snapshot: CollegePortalPolicySnapshot
    ) -> CollegePortalKnowledgeSnapshot? {
        guard let intent = snapshot.intentsByPlayerID[playerID],
              let player = snapshot.playerTruthByID[playerID],
              let staffAverage = snapshot.recruitingStaffAverageByObserverID[
                  observerProgrammeID
              ],
              player.position == intent.evidence.position else { return nil }
        let confidence = min(
            maximumKnowledgeConfidence,
            25 + (staffAverage - ratingFloor) * 20 / ratingSpan
                + min(20, intent.evidence.appearances)
        )
        let evidenceCount = min(
            maximumScoutingEvidence,
            intent.evidence.appearances + max(1, staffAverage / 20)
        )
        var rng = SeededRandom(seed: knowledgeSeed(
            root: snapshot.rootSeed,
            targetSeason: snapshot.targetSeason,
            window: snapshot.window,
            observerProgrammeID: observerProgrammeID,
            sourceProgrammeID: intent.sourceProgrammeID,
            playerID: playerID
        ))
        let errorRadius = max(
            1,
            (maximumKnowledgeConfidence - confidence + 9) / 10
        )
        let estimatedAttributes = Dictionary(uniqueKeysWithValues:
            ratedAttributes(for: player.position).map { attribute in
                (
                    attribute,
                    Rating(player.attributes[attribute].value
                        + rng.int(in: -errorRadius...errorRadius))
                )
            }
        )
        let estimatedOverall = Rating(
            estimatedAttributes.values.reduce(0) { $0 + $1.value }
                / estimatedAttributes.count
        )
        return CollegePortalKnowledgeSnapshot(
            observerProgrammeID: observerProgrammeID,
            playerID: playerID,
            sourceProgrammeID: intent.sourceProgrammeID,
            targetSeason: snapshot.targetSeason,
            window: snapshot.window,
            position: player.position,
            estimatedOverall: estimatedOverall,
            estimatedAttributes: estimatedAttributes,
            estimatedPotential: Rating(
                player.potential.value + rng.int(in: -errorRadius...errorRadius)
            ),
            confidence: confidence,
            lastUpdated: snapshot.evaluatedAt,
            evidenceCount: evidenceCount
        )
    }

    public static func resolveRetention(
        for programmeID: UUID,
        programme: ProgrammeRecruitingState,
        using snapshot: CollegePortalPolicySnapshot
    ) -> CollegePortalRetentionTransition? {
        resolveRetention(
            for: programmeID,
            programme: programme,
            overrides: [:],
            using: snapshot
        )
    }

    static func resolveRetention(
        for programmeID: UUID,
        programme: ProgrammeRecruitingState,
        overrides: [UUID: MandatoryDecisionAction],
        using snapshot: CollegePortalPolicySnapshot
    ) -> CollegePortalRetentionTransition? {
        let candidates = snapshot.intents.filter {
            $0.sourceProgrammeID == programmeID
        }
        guard programme.programmeID == programmeID,
              programme.nilState.season == snapshot.targetSeason,
              Set(candidates.map(\.playerID)).count == candidates.count,
              candidates.allSatisfy({ intent in
                  intentIsValid(intent)
                      && intent.sourceProgrammeID == programmeID
                      && intent.targetSeason == snapshot.targetSeason
                      && intent.window == snapshot.window
                      && (programme.nilState.rosterAllocations[intent.playerID] ?? 0)
                          == intent.evidence.sourceRosterNIL
              }) else { return nil }

        let ordered = candidates.sorted(by: retentionRanksBefore)
        var resolvedProgramme = programme
        var resolutions: [UUID: CollegePortalRetentionResolution] = [:]
        for intent in ordered {
            let requirement = retentionRequirement(
                intentScore: intent.total,
                sourceRosterNIL: intent.evidence.sourceRosterNIL
            )
            if let override = overrides[intent.playerID] {
                switch override {
                case .portalRelease:
                    resolutions[intent.playerID] = releasedRetention(for: intent)
                    continue
                case let .portalRetention(finalNIL):
                    guard let required = requirement.requiredAdditionalNIL,
                          finalNIL == intent.evidence.sourceRosterNIL + required,
                          resolvedProgramme.setRosterNILAllocation(
                              finalNIL,
                              playerID: intent.playerID
                          ) else { return nil }
                    let afterScore = expectedIntentScore(
                        intentScore: intent.total,
                        sourceRosterNIL: intent.evidence.sourceRosterNIL,
                        finalRosterNIL: finalNIL
                    )
                    guard afterScore < intentSelectionThreshold else { return nil }
                    resolutions[intent.playerID] = CollegePortalRetentionResolution(
                        policyVersion: version,
                        outcome: .retained,
                        requiredAdditionalNIL: required,
                        appliedAdditionalNIL: required,
                        sourceRosterNILAfterDecision: finalNIL,
                        intentScoreAfterDecision: afterScore
                    )
                    continue
                default:
                    return nil
                }
            }
            if let required = requirement.requiredAdditionalNIL {
                let (finalNIL, overflow) = intent.evidence.sourceRosterNIL
                    .addingReportingOverflow(required)
                if !overflow,
                   resolvedProgramme.setRosterNILAllocation(
                       finalNIL,
                       playerID: intent.playerID
                   ) {
                    let afterScore = expectedIntentScore(
                        intentScore: intent.total,
                        sourceRosterNIL: intent.evidence.sourceRosterNIL,
                        finalRosterNIL: finalNIL
                    )
                    if afterScore < intentSelectionThreshold {
                        resolutions[intent.playerID] = CollegePortalRetentionResolution(
                            policyVersion: version,
                            outcome: .retained,
                            requiredAdditionalNIL: required,
                            appliedAdditionalNIL: required,
                            sourceRosterNILAfterDecision: finalNIL,
                            intentScoreAfterDecision: afterScore
                        )
                        continue
                    }
                    return nil
                }
            }
            resolutions[intent.playerID] = releasedRetention(for: intent)
        }
        return CollegePortalRetentionTransition(
            programme: resolvedProgramme,
            resolutions: resolutions
        )
    }

    private static func releasedRetention(
        for intent: CollegePortalIntentExplanation
    ) -> CollegePortalRetentionResolution {
        precondition(intentIsValid(intent))
        let requirement = retentionRequirement(
            intentScore: intent.total,
            sourceRosterNIL: intent.evidence.sourceRosterNIL
        )
        return CollegePortalRetentionResolution(
            policyVersion: version,
            outcome: .released,
            requiredAdditionalNIL: requirement.requiredAdditionalNIL,
            appliedAdditionalNIL: 0,
            sourceRosterNILAfterDecision: intent.evidence.sourceRosterNIL,
            intentScoreAfterDecision: intent.total
        )
    }

    static func retentionRequirement(
        intentScore: Int,
        sourceRosterNIL: Int
    ) -> (requiredAdditionalNIL: Int?, currentBand: Int) {
        let currentBand = min(maximumNILBand, sourceRosterNIL / nilBandUnit)
        let dropNeeded = intentScore - intentSelectionThreshold + 1
        let targetBand = currentBand + dropNeeded
        let required = targetBand > maximumNILBand
            ? nil
            : max(0, targetBand * nilBandUnit - sourceRosterNIL)
        return (required, currentBand)
    }

    static func expectedIntentScore(
        intentScore: Int,
        sourceRosterNIL: Int,
        finalRosterNIL: Int
    ) -> Int {
        let currentBand = min(maximumNILBand, sourceRosterNIL / nilBandUnit)
        let finalBand = min(maximumNILBand, finalRosterNIL / nilBandUnit)
        return intentScore - (finalBand - currentBand)
    }

    static func retentionResolutionIsValid(
        policyVersion: Int,
        outcome: CollegePortalRetentionOutcome,
        requiredAdditionalNIL: Int?,
        appliedAdditionalNIL: Int,
        sourceRosterNILAfterDecision: Int,
        intentScoreAfterDecision: Int
    ) -> Bool {
        let requiredIsValid = requiredAdditionalNIL.map {
            (1...maximumNILBudget).contains($0)
        } ?? true
        guard policyVersion == version,
              requiredIsValid,
              (0...maximumNILBudget).contains(appliedAdditionalNIL),
              (0...maximumNILBudget).contains(sourceRosterNILAfterDecision),
              (-120...120).contains(intentScoreAfterDecision)
        else { return false }
        switch outcome {
        case .released:
            return appliedAdditionalNIL == 0
        case .retained:
            return requiredAdditionalNIL != nil
                && appliedAdditionalNIL == requiredAdditionalNIL
                && sourceRosterNILAfterDecision >= appliedAdditionalNIL
        }
    }

    static func intentIsValid(_ intent: CollegePortalIntentExplanation) -> Bool {
        intent.policyVersion == version
            && intent.selectionThreshold == intentSelectionThreshold
            && intent.window.expectedCalendar(targetSeason: intent.targetSeason)
                == intent.evaluatedAt
            && intent.components == intentComponents(for: intent.evidence)
            && intent.total >= intentSelectionThreshold
    }

    private static func intentRanksBefore(
        _ lhs: CollegePortalIntentExplanation,
        _ rhs: CollegePortalIntentExplanation
    ) -> Bool {
        if lhs.total != rhs.total { return lhs.total > rhs.total }
        return lhs.playerID.uuidString < rhs.playerID.uuidString
    }

    private static func retentionRanksBefore(
        _ lhs: CollegePortalIntentExplanation,
        _ rhs: CollegePortalIntentExplanation
    ) -> Bool {
        if lhs.evidence.starts != rhs.evidence.starts {
            return lhs.evidence.starts > rhs.evidence.starts
        }
        if lhs.evidence.appearances != rhs.evidence.appearances {
            return lhs.evidence.appearances > rhs.evidence.appearances
        }
        return lhs.playerID.uuidString < rhs.playerID.uuidString
    }

    private static func uniqueArchive(season: Int, in state: GameState) -> SeasonArchive? {
        let matches = state.competition.archives.filter { $0.season == season }
        return matches.count == 1 ? matches[0] : nil
    }

    private static func uniqueRank(of programmeID: UUID, in ranking: [UUID]) -> Int? {
        let matches = ranking.enumerated().filter { $0.element == programmeID }
        guard matches.count == 1 else { return nil }
        let rank = matches[0].offset + 1
        return (1...programmeCount).contains(rank) ? rank : nil
    }

    private static func windowHistoryAllowsEntry(
        window: CollegePortalWindow,
        targetSeason: Int,
        currentSourceID: UUID,
        completedSourceID: UUID,
        records: [CollegePortalWindowRecord]
    ) -> Bool {
        let targetRecords = records.filter { $0.targetSeason == targetSeason }
        switch window {
        case .postseason:
            return targetRecords.isEmpty && currentSourceID == completedSourceID
        case .spring:
            guard targetRecords.count <= 1,
                  targetRecords.allSatisfy({ $0.window == .postseason }) else { return false }
            return targetRecords.first?.finalProgrammeID == currentSourceID
                || (targetRecords.isEmpty && currentSourceID == completedSourceID)
        }
    }

    private static func knowledgeSeed(
        root: UInt64,
        targetSeason: Int,
        window: CollegePortalWindow,
        observerProgrammeID: UUID,
        sourceProgrammeID: UUID,
        playerID: UUID
    ) -> UInt64 {
        let season = SeededRandom.derive(from: root, scope: .season, ordinal: targetSeason)
        let portalWindow = SeededRandom.derive(
            from: season,
            scope: .week,
            ordinal: window.order
        )
        let observer = SeededRandom.derive(
            from: portalWindow,
            scope: .scouting,
            identifier: observerProgrammeID
        )
        let source = SeededRandom.derive(
            from: observer,
            scope: .league,
            identifier: sourceProgrammeID
        )
        return SeededRandom.derive(
            from: source,
            scope: .personnel,
            identifier: playerID
        )
    }
}
