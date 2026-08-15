import Foundation

struct RecruitingProgrammeFitBaseline: Sendable {
    let home: MapCity
    let prestige: Int
    let rosterCounts: [Position: Int]
    let staffAverage: Int
    let teamSuccess: Int
}

struct RecruitingFitCache: Sendable {
    let citiesByID: [UUID: MapCity]
    let programmes: [UUID: RecruitingProgrammeFitBaseline]

    init(state: GameState) {
        let cityIndex = Dictionary(uniqueKeysWithValues: state.map.cities.map { ($0.id, $0) })
        citiesByID = cityIndex
        programmes = Dictionary(uniqueKeysWithValues: state.programmes.values.compactMap {
            programme in
            guard let homeID = state.identities[programme.id]?.homeCityID,
                  let home = cityIndex[homeID] else { return nil }
            let rosterCounts = Dictionary(grouping: programme.rosterIDs.compactMap {
                state.players[$0]?.position
            }, by: { $0 }).mapValues(\.count)
            let staffRatings = programme.staffIDs.compactMap {
                state.staff[$0]?.rating(.recruiting).value
            }
            let staffAverage = staffRatings.isEmpty
                ? SharedRules.ratingRange.lowerBound
                : staffRatings.reduce(0, +) / staffRatings.count
            let standing = state.competition.standings[.college]?.first {
                $0.id == programme.id
            }
            let teamSuccess = standing.map { row in
                row.games == 0 ? 5 : row.wins * 10 / row.games
            } ?? 5
            return (
                programme.id,
                RecruitingProgrammeFitBaseline(
                    home: home,
                    prestige: programme.prestige.value,
                    rosterCounts: rosterCounts,
                    staffAverage: staffAverage,
                    teamSuccess: teamSuccess
                )
            )
        })
    }
}

/// An immutable recruiting-fit view of one authoritative world-state snapshot.
///
/// Reuse this value when a system needs to explain many programme/prospect matchups from the
/// same state. Every evaluation observes the captured state and shares its derived baselines.
public struct RecruitingFitSnapshot: Sendable {
    private let state: GameState
    private let cache: RecruitingFitCache

    public init(in state: GameState) {
        self.state = state
        cache = RecruitingFitCache(state: state)
    }

    public func evaluate(
        programmeID: UUID,
        prospectID: UUID
    ) -> RecruitingDecisionExplanation? {
        RecruitingFitSystem.evaluate(
            programmeID: programmeID,
            prospectID: prospectID,
            in: state,
            cache: cache
        )
    }
}

public struct RecruitingScoreComponent: Codable, Sendable, Equatable {
    public let reason: RecruitingPitch
    public let value: Int

    public init(reason: RecruitingPitch, value: Int) {
        self.reason = reason
        self.value = min(max(-20, value), 20)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedValue = try container.decode(Int.self, forKey: .value)
        guard (-20...20).contains(decodedValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .value,
                in: container,
                debugDescription: "Recruiting score component is outside its legal range."
            )
        }
        reason = try container.decode(RecruitingPitch.self, forKey: .reason)
        value = decodedValue
    }
}

public struct RecruitingDecisionExplanation: Codable, Sendable, Equatable {
    public let programmeID: UUID
    public let prospectID: UUID
    public let components: [RecruitingScoreComponent]
    public let relationshipInterestAdjustment: Int
    public let nilAllocationAdjustment: Int
    public let knowledgeAdjustment: Int

    public init(
        programmeID: UUID,
        prospectID: UUID,
        components: [RecruitingScoreComponent],
        relationshipInterestAdjustment: Int = 0,
        nilAllocationAdjustment: Int = 0,
        knowledgeAdjustment: Int = 0
    ) {
        self.programmeID = programmeID
        self.prospectID = prospectID
        self.components = RecruitingPitch.allCases.compactMap { reason in
            components.first { $0.reason == reason }
        }
        self.relationshipInterestAdjustment = min(max(0, relationshipInterestAdjustment), 100)
        self.nilAllocationAdjustment = min(
            max(0, nilAllocationAdjustment),
            Self.maximumNILAdjustment
        )
        self.knowledgeAdjustment = min(
            max(0, knowledgeAdjustment),
            Self.maximumKnowledgeAdjustment
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedComponents = try container.decode(
            [RecruitingScoreComponent].self,
            forKey: .components
        )
        let decodedRelationship = try container.decode(
            Int.self,
            forKey: .relationshipInterestAdjustment
        )
        let decodedNIL = try container.decode(Int.self, forKey: .nilAllocationAdjustment)
        let decodedKnowledge = try container.decode(Int.self, forKey: .knowledgeAdjustment)
        let canonical = RecruitingPitch.allCases.compactMap { reason in
            decodedComponents.first { $0.reason == reason }
        }
        guard canonical == decodedComponents,
              Set(decodedComponents.map(\.reason)).count == decodedComponents.count,
              (0...100).contains(decodedRelationship),
              (0...Self.maximumNILAdjustment).contains(decodedNIL),
              (0...Self.maximumKnowledgeAdjustment).contains(decodedKnowledge) else {
            throw DecodingError.dataCorruptedError(
                forKey: .components,
                in: container,
                debugDescription: "Recruiting explanation adjustments are noncanonical or unbounded."
            )
        }
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        prospectID = try container.decode(UUID.self, forKey: .prospectID)
        components = decodedComponents
        relationshipInterestAdjustment = decodedRelationship
        nilAllocationAdjustment = decodedNIL
        knowledgeAdjustment = decodedKnowledge
    }

    public var total: Int {
        components.reduce(0) { $0 + $1.value }
            + relationshipInterestAdjustment
            + nilAllocationAdjustment
            + knowledgeAdjustment
    }

    public func value(for reason: RecruitingPitch) -> Int {
        components.first { $0.reason == reason }?.value ?? 0
    }

    func addingKnowledgeAdjustment(_ adjustment: Int) -> RecruitingDecisionExplanation {
        RecruitingDecisionExplanation(
            programmeID: programmeID,
            prospectID: prospectID,
            components: components,
            relationshipInterestAdjustment: relationshipInterestAdjustment,
            nilAllocationAdjustment: nilAllocationAdjustment,
            knowledgeAdjustment: adjustment
        )
    }

    private static var maximumNILAdjustment: Int {
        CollegeRules.maximumNILBudget / CollegeRules.nilInterestPointsPerUnit
    }

    private static var maximumKnowledgeAdjustment: Int {
        SharedRules.ratingRange.upperBound - SharedRules.ratingRange.lowerBound
    }

    private enum CodingKeys: String, CodingKey {
        case programmeID
        case prospectID
        case components
        case relationshipInterestAdjustment
        case nilAllocationAdjustment
        case knowledgeAdjustment
    }
}

public enum RecruitingFitSystem {
    public static func evaluate(
        programmeID: UUID,
        prospectID: UUID,
        in state: GameState
    ) -> RecruitingDecisionExplanation? {
        RecruitingFitSnapshot(in: state).evaluate(
            programmeID: programmeID,
            prospectID: prospectID
        )
    }

    static func evaluate(
        programmeID: UUID,
        prospectID: UUID,
        in state: GameState,
        cache: RecruitingFitCache
    ) -> RecruitingDecisionExplanation? {
        guard let prospect = state.prospects[prospectID],
              let origin = cache.citiesByID[prospect.originCityID],
              let baseline = cache.programmes[programmeID] else { return nil }
        let recruiting = state.college.programmes[programmeID]
        let relationship = recruiting?.relationships[prospectID]
        let maximumDistance = GameMap.width * GameMap.width + GameMap.height * GameMap.height
        let distance = min(maximumDistance, origin.squaredDistance(to: baseline.home))
        let proximity = 10 - distance * 10 / maximumDistance
        let prestige = (baseline.prestige - SharedRules.ratingRange.lowerBound) * 10 / 59
        let rosterCount = baseline.rosterCounts[prospect.position] ?? 0
        let target = max(1, CollegeRules.initialRosterByPosition[prospect.position] ?? 1)
        let playingTime = max(0, 10 - rosterCount * 5 / target)
        let observedSchemeFit = state.scouting.observation(
            observerID: programmeID,
            prospectID: prospectID
        )?.estimatedAttribute(.schemeFit).value
            ?? (SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound) / 2
        let schemeFit = (observedSchemeFit
            - SharedRules.ratingRange.lowerBound) * 10 / 59
        let relationshipValue = (relationship?.interest ?? 0) / 10
        let staffQuality = (baseline.staffAverage - SharedRules.ratingRange.lowerBound) * 10 / 59
        let nilAllocation = recruiting?.nilAllocation(for: prospectID) ?? 0
        let nilOpportunity = nilOpportunityRawValue(allocation: nilAllocation)
        let raw: [RecruitingPitch: Int] = [
            .proximity: proximity,
            .prestige: prestige,
            .playingTime: playingTime,
            .schemeFit: schemeFit,
            .relationship: relationshipValue,
            .staffQuality: staffQuality,
            .teamSuccess: baseline.teamSuccess,
            .nilOpportunity: nilOpportunity,
        ]
        return RecruitingDecisionExplanation(
            programmeID: programmeID,
            prospectID: prospectID,
            components: RecruitingPitch.allCases.map { reason in
                let importance = prospect.priorities[reason]?.value
                    ?? SharedRules.ratingRange.lowerBound
                return RecruitingScoreComponent(
                    reason: reason,
                    value: (raw[reason] ?? 0) * importance
                        / SharedRules.ratingRange.upperBound
                )
            },
            relationshipInterestAdjustment: relationship?.interest ?? 0,
            nilAllocationAdjustment: nilAllocation / CollegeRules.nilInterestPointsPerUnit
        )
    }

    static func nilOpportunityRawValue(allocation: Int) -> Int {
        min(10, max(0, allocation) / CollegeRules.nilInterestPointsPerUnit)
    }
}

public enum RecruitingInteractionKind: String, Codable, Sendable, CaseIterable, Hashable {
    case addToBoard
    case contact
    case evaluate
    case visit
    case scholarshipOffer
    case nilAllocation
    case withdraw
}

public enum RecruitingAction: Codable, Sendable, Equatable {
    case addToBoard
    case contact(points: Int)
    case evaluate(points: Int)
    case scheduleVisit
    case offerScholarship
    case setNILAllocation(amount: Int)
    case withdraw
}

public enum RecruitingCommitmentChallengePolicy {
    public static func permitsInvestment(_ action: RecruitingAction) -> Bool {
        switch action {
        case .evaluate, .contact, .scheduleVisit, .offerScholarship,
             .setNILAllocation:
            return true
        case .addToBoard, .withdraw:
            return false
        }
    }

    /// A commitment is stable, but its recorded runner-up gets the remainder of the commitment
    /// week to improve one shared, legal pursuit. The following week's market resolves that work
    /// before AI cleanup; after a flip, the displaced winner receives the same bounded opportunity.
    public static func isAuthorized(
        programmeID: UUID,
        prospectID: UUID,
        in state: GameState
    ) -> Bool {
        guard state.calendar.week < SharedRules.inSeasonWeeks,
              let recruitment = state.college.prospectRecruitment[prospectID],
              recruitment.phase == .committed,
              recruitment.commitmentHistory.count < CollegeRules.commitmentHistoryLimit,
              let context = recruitment.commitmentContext,
              context.committedAt == state.calendar,
              context.winner.programmeID != programmeID,
              context.runnerUp?.programmeID == programmeID
                || context.previousWinner?.programmeID == programmeID,
              let relationship = state.college.programmes[programmeID]?
                .relationships[prospectID],
              relationship.scholarshipOffered,
              let prospect = state.prospects[prospectID],
              CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
              )?.canReserve(position: prospect.position) == true else { return false }
        return true
    }
}

public struct RecruitingActionRequest: Codable, Sendable, Equatable {
    public let programmeID: UUID
    public let prospectID: UUID
    public let action: RecruitingAction

    public init(programmeID: UUID, prospectID: UUID, action: RecruitingAction) {
        self.programmeID = programmeID
        self.prospectID = prospectID
        self.action = action
    }
}

public enum RecruitingActionError: Error, Sendable, Equatable {
    case cycleUnavailable
    case missingProgramme
    case missingProspect
    case prospectUnavailable
    case boardFull
    case alreadyOnBoard
    case notOnBoard
    case insufficientContactPoints
    case evaluationAlreadyQueued
    case visitAlreadyScheduled
    case scholarshipAlreadyOffered
    case insufficientNILBudget
}

public struct RecruitingActionTransition: Sendable, Equatable {
    public let prospects: EntityStore<Prospect>
    public let college: CollegeState
    public let scouting: ScoutingState
    public let explanation: RecruitingDecisionExplanation
    public let eventPayloads: [DomainEventPayload]

    public init(
        prospects: EntityStore<Prospect>,
        college: CollegeState,
        scouting: ScoutingState,
        explanation: RecruitingDecisionExplanation,
        eventPayloads: [DomainEventPayload]
    ) {
        self.prospects = prospects
        self.college = college
        self.scouting = scouting
        self.explanation = explanation
        self.eventPayloads = eventPayloads
    }
}

public enum CollegeRecruitingSystem {
    public static func apply(
        _ request: RecruitingActionRequest,
        in state: GameState
    ) throws -> RecruitingActionTransition {
        try apply(request, in: state, fitCache: RecruitingFitCache(state: state))
    }

    static func apply(
        _ request: RecruitingActionRequest,
        in state: GameState,
        fitCache: RecruitingFitCache
    ) throws -> RecruitingActionTransition {
        guard state.college.phase == .active,
              state.college.portal.phase != .awaitingSpring else {
            throw RecruitingActionError.cycleUnavailable
        }
        guard state.programmes[request.programmeID] != nil,
              state.college.programmes[request.programmeID] != nil else {
            throw RecruitingActionError.missingProgramme
        }
        guard state.prospects[request.prospectID] != nil,
              let recruitment = state.college.prospectRecruitment[request.prospectID] else {
            throw RecruitingActionError.missingProspect
        }
        let isLostCommitmentWithdrawal: Bool
        if case .withdraw = request.action {
            isLostCommitmentWithdrawal = recruitment.phase == .committed
                && recruitment.programmeID != request.programmeID
        } else {
            isLostCommitmentWithdrawal = false
        }
        let isAuthorizedChallengeInvestment = RecruitingCommitmentChallengePolicy
            .permitsInvestment(request.action)
            && RecruitingCommitmentChallengePolicy.isAuthorized(
                programmeID: request.programmeID,
                prospectID: request.prospectID,
                in: state
            )
        guard recruitment.phase == .available
                || isLostCommitmentWithdrawal
                || isAuthorizedChallengeInvestment else {
            throw RecruitingActionError.prospectUnavailable
        }
        guard let explanation = RecruitingFitSystem.evaluate(
            programmeID: request.programmeID,
            prospectID: request.prospectID,
            in: state,
            cache: fitCache
        ) else { throw RecruitingActionError.missingProspect }

        var college = state.college
        var scouting = state.scouting
        let kind: RecruitingInteractionKind
        let cost: Int
        let interestAfter: Int

        switch request.action {
        case .addToBoard:
            let programme = college.programmes[request.programmeID]!
            if programme.boardIDs.contains(request.prospectID) {
                throw RecruitingActionError.alreadyOnBoard
            }
            guard programme.boardIDs.count < CollegeRules.recruitingBoardLimit else {
                throw RecruitingActionError.boardFull
            }
            let interest = min(100, max(0, explanation.total))
            _ = college.updateProgramme(request.programmeID) {
                _ = $0.addToBoard(
                    prospectID: request.prospectID,
                    relationship: ProgrammeProspectRelationship(
                        prospectID: request.prospectID,
                        interest: interest,
                        lastExplanation: explanation.components
                    )
                )
            }
            kind = .addToBoard
            cost = 0
            interestAfter = interest

        case let .contact(points):
            guard college.programmes[request.programmeID]?.relationships[request.prospectID] != nil
            else { throw RecruitingActionError.notOnBoard }
            guard points > 0,
                  points <= (college.programmes[request.programmeID]?.contactPointsRemaining ?? 0)
            else { throw RecruitingActionError.insufficientContactPoints }
            _ = college.updateProgramme(request.programmeID) { programme in
                _ = programme.spendContactPoints(points)
                _ = programme.updateRelationship(request.prospectID) { relationship in
                    relationship.contactPointsInvested = min(
                        CollegeRules.maximumSeasonRecruitingContactPoints,
                        relationship.contactPointsInvested + points
                    )
                    relationship.interest = min(100, relationship.interest + max(1, points / 4))
                }
            }
            kind = .contact
            cost = points
            interestAfter = college.programmes[request.programmeID]?
                .relationships[request.prospectID]?.interest ?? 0

        case let .evaluate(points):
            guard college.programmes[request.programmeID]?.relationships[request.prospectID] != nil
            else { throw RecruitingActionError.notOnBoard }
            guard points > 0,
                  points <= (college.programmes[request.programmeID]?.contactPointsRemaining ?? 0)
            else { throw RecruitingActionError.insufficientContactPoints }
            guard scouting.queueEvaluation(
                observerID: request.programmeID,
                prospectID: request.prospectID,
                effort: points
            ) else { throw RecruitingActionError.evaluationAlreadyQueued }
            _ = college.updateProgramme(request.programmeID) {
                _ = $0.spendContactPoints(points)
            }
            kind = .evaluate
            cost = points
            interestAfter = college.programmes[request.programmeID]?
                .relationships[request.prospectID]?.interest ?? 0

        case .scheduleVisit:
            guard let relationship = college.programmes[request.programmeID]?
                .relationships[request.prospectID] else {
                throw RecruitingActionError.notOnBoard
            }
            guard !relationship.visitScheduled else {
                throw RecruitingActionError.visitAlreadyScheduled
            }
            guard CollegeRules.visitContactCost <= (college.programmes[request.programmeID]?
                .contactPointsRemaining ?? 0) else {
                throw RecruitingActionError.insufficientContactPoints
            }
            _ = college.updateProgramme(request.programmeID) { programme in
                _ = programme.spendContactPoints(CollegeRules.visitContactCost)
                _ = programme.updateRelationship(request.prospectID) {
                    $0.visitScheduled = true
                    $0.interest = min(100, $0.interest + CollegeRules.visitInterestBonus)
                }
            }
            kind = .visit
            cost = CollegeRules.visitContactCost
            interestAfter = college.programmes[request.programmeID]?
                .relationships[request.prospectID]?.interest ?? 0

        case .offerScholarship:
            guard let relationship = college.programmes[request.programmeID]?
                .relationships[request.prospectID] else {
                throw RecruitingActionError.notOnBoard
            }
            guard !relationship.scholarshipOffered else {
                throw RecruitingActionError.scholarshipAlreadyOffered
            }
            _ = college.updateProgramme(request.programmeID) { programme in
                _ = programme.updateRelationship(request.prospectID) {
                    $0.scholarshipOffered = true
                    $0.interest = min(
                        100,
                        $0.interest + CollegeRules.scholarshipOfferInterestBonus
                    )
                }
            }
            kind = .scholarshipOffer
            cost = 0
            interestAfter = college.programmes[request.programmeID]?
                .relationships[request.prospectID]?.interest ?? 0

        case let .setNILAllocation(amount):
            guard var programme = college.programmes[request.programmeID],
                  programme.relationships[request.prospectID] != nil else {
                throw RecruitingActionError.notOnBoard
            }
            let previous = programme.nilAllocation(for: request.prospectID)
            let delta = amount - previous
            guard (0...CollegeRules.maximumNILBudget).contains(amount),
                  programme.setNILAllocation(amount, prospectID: request.prospectID) else {
                throw RecruitingActionError.insufficientNILBudget
            }
            _ = college.updateProgramme(request.programmeID) { $0 = programme }
            kind = .nilAllocation
            cost = delta
            interestAfter = college.programmes[request.programmeID]?
                .relationships[request.prospectID]?.interest ?? 0

        case .withdraw:
            guard var programme = college.programmes[request.programmeID],
                  programme.relationships[request.prospectID] != nil else {
                throw RecruitingActionError.notOnBoard
            }
            let refunded = programme.nilAllocation(for: request.prospectID)
            guard programme.withdraw(request.prospectID) else {
                throw RecruitingActionError.notOnBoard
            }
            _ = college.updateProgramme(request.programmeID) { $0 = programme }
            kind = .withdraw
            cost = -refunded
            interestAfter = 0
        }

        var resultingExplanation = explanation
        if college.programmes[request.programmeID]?.relationships[request.prospectID] != nil {
            var projected = state
            projected.college = college
            projected.scouting = scouting
            if let refreshed = RecruitingFitSystem.evaluate(
                programmeID: request.programmeID,
                prospectID: request.prospectID,
                in: projected,
                cache: fitCache
            ) {
                resultingExplanation = refreshed
                _ = college.updateProgramme(request.programmeID) {
                    _ = $0.updateRelationship(request.prospectID) {
                        $0.lastExplanation = refreshed.components
                    }
                }
            }
        }

        return RecruitingActionTransition(
            prospects: state.prospects,
            college: college,
            scouting: scouting,
            explanation: resultingExplanation,
            eventPayloads: [.recruitingInteraction(
                programmeID: request.programmeID,
                prospectID: request.prospectID,
                action: kind,
                resourceCost: cost,
                interestAfter: interestAfter
            )]
        )
    }
}
