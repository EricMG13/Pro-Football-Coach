import Foundation

public struct RecruitingPolicyDecision: Codable, Sendable, Equatable {
    public let request: RecruitingActionRequest
    public let score: Int
    public let explanation: RecruitingDecisionExplanation

    public init(
        request: RecruitingActionRequest,
        score: Int,
        explanation: RecruitingDecisionExplanation
    ) {
        self.request = request
        self.score = score
        self.explanation = explanation
    }
}

package struct RecruitingNILAllocationProposal: Sendable, Equatable {
    package let amount: Int
    package let incrementalCost: Int
    package let closesCurrentScoreGap: Bool
}

public struct CollegeRecruitingAITransition: Sendable, Equatable {
    public let college: CollegeState
    public let scouting: ScoutingState
    public let decisions: [RecruitingPolicyDecision]
    public let eventPayloads: [DomainEventPayload]

    public init(
        college: CollegeState,
        scouting: ScoutingState,
        decisions: [RecruitingPolicyDecision],
        eventPayloads: [DomainEventPayload]
    ) {
        self.college = college
        self.scouting = scouting
        self.decisions = decisions
        self.eventPayloads = eventPayloads
    }
}

public struct RecruitingCommitmentDecision: Codable, Sendable, Equatable {
    public let prospectID: UUID
    public let context: RecruitingCommitmentContext

    public var programmeID: UUID { context.winner.programmeID }
    public var runnerUpProgrammeID: UUID? { context.runnerUp?.programmeID }
    public var previousProgrammeID: UUID? { context.previousWinner?.programmeID }
    public var score: Int { context.winner.score }

    public init(
        prospectID: UUID,
        context: RecruitingCommitmentContext
    ) {
        self.prospectID = prospectID
        self.context = context
    }
}

public struct CollegeRecruitingMarketTransition: Sendable, Equatable {
    public let college: CollegeState
    public let commitments: [RecruitingCommitmentDecision]
    public let eventPayloads: [DomainEventPayload]

    public init(
        college: CollegeState,
        commitments: [RecruitingCommitmentDecision],
        eventPayloads: [DomainEventPayload]
    ) {
        self.college = college
        self.commitments = commitments
        self.eventPayloads = eventPayloads
    }
}

public enum CollegeRecruitingAIError: Error, Sendable, Equatable {
    case rejectedLegalDecision(RecruitingActionError)
}

/// The shared, knowledge-limited policy used by computer-controlled college programmes.
public enum RecruitingDecisionPolicy {
    public static func targetDecision(
        programmeID: UUID,
        in state: GameState
    ) -> RecruitingPolicyDecision? {
        guard let capacity = CollegeCommitmentCapacitySystem.capacity(
            programmeID: programmeID,
            in: state,
            college: state.college
        ) else { return nil }
        let pursuitCounts = globalPursuitCounts(in: state)
        var targetExplanationCache: [UUID: RecruitingDecisionExplanation] = [:]
        return targetDecision(
            programmeID: programmeID,
            in: state,
            capacity: capacity,
            cache: RecruitingFitCache(state: state),
            prospectsByPosition: Dictionary(grouping: state.prospects.values, by: \.position),
            pursuitCounts: pursuitCounts,
            pursuitSaturation: pursuitSaturation(in: state),
            targetExplanationCache: &targetExplanationCache
        )
    }

    static func targetDecision(
        programmeID: UUID,
        in state: GameState,
        capacity: ProgrammeCommitmentCapacity,
        cache: RecruitingFitCache,
        prospectsByPosition: [Position: [Prospect]],
        pursuitCounts: [UUID: Int],
        pursuitSaturation: Int,
        targetExplanationCache: inout [UUID: RecruitingDecisionExplanation]
    ) -> RecruitingPolicyDecision? {
        guard state.college.phase.allowsRecruitingActions,
              let recruiting = state.college.programmes[programmeID],
              capacity.openReservations > 0,
              recruiting.boardIDs.count < min(
                CollegeRules.recruitingBoardLimit,
                state.calendar.week * CollegeRules.aiWeeklyBoardGrowth,
                capacity.maximumReservations + CollegeRules.aiBoardDepthBeyondClassTarget
              ) else {
            return nil
        }
        let rankedPositions = priorityPositions(
            programmeID: programmeID,
            in: state,
            capacity: capacity
        )
        guard !rankedPositions.isEmpty else { return nil }
        let boardIDs = Set(recruiting.boardIDs)
        let reservablePositions = Set(Position.allCases.filter { capacity.canReserve(position: $0) })
        let candidatesForPosition: (Position) -> [Prospect] = { position in
            (prospectsByPosition[position] ?? []).filter { prospect in
                !boardIDs.contains(prospect.id)
                    && state.college.prospectRecruitment[prospect.id]?.phase == .available
                    && reservablePositions.contains(prospect.position)
            }
        }
        let candidates: [Prospect]
        if let diversified = rankedPositions.lazy.compactMap({ position in
            let unsaturated = candidatesForPosition(position).filter {
                (pursuitCounts[$0.id] ?? 0) < pursuitSaturation
            }
            return unsaturated.isEmpty ? nil : unsaturated
        }).first {
            candidates = diversified
        } else if let fallback = rankedPositions.lazy.compactMap({ position in
            let candidates = candidatesForPosition(position)
            return candidates.isEmpty ? nil : candidates
        }).first {
            candidates = fallback
        } else {
            return nil
        }
        var selected: (Prospect, RecruitingDecisionExplanation, UInt64)?
        for prospect in candidates {
            let explanation: RecruitingDecisionExplanation
            if let cached = targetExplanationCache[prospect.id] {
                explanation = cached
            } else {
                guard let evaluated = targetExplanation(
                    prospect: prospect,
                    programmeID: programmeID,
                    in: state,
                    cache: cache
                ) else { continue }
                targetExplanationCache[prospect.id] = evaluated
                explanation = evaluated
            }
            let candidate = (prospect, explanation, tieBreaker(
                programmeID: programmeID,
                prospectID: prospect.id,
                in: state
            ))
            if let current = selected,
               current.1.total > candidate.1.total
                || (current.1.total == candidate.1.total
                    && (current.2 > candidate.2
                        || (current.2 == candidate.2
                            && current.0.id.uuidString < candidate.0.id.uuidString))) {
                continue
            }
            selected = candidate
        }
        guard let selected else { return nil }
        return RecruitingPolicyDecision(
            request: RecruitingActionRequest(
                programmeID: programmeID,
                prospectID: selected.0.id,
                action: .addToBoard
            ),
            score: selected.1.total,
            explanation: selected.1
        )
    }

    public static func investmentDecision(
        programmeID: UUID,
        in state: GameState
    ) -> RecruitingPolicyDecision? {
        let capacity = CollegeCommitmentCapacitySystem.capacity(
            programmeID: programmeID,
            in: state,
            college: state.college
        )
        return investmentDecision(
            programmeID: programmeID,
            in: state,
            capacitySnapshot: capacity,
            cache: RecruitingFitCache(state: state),
            weeklyActionCounts: [:],
            weeklyEvaluationCount: 0
        )
    }

    /// Uses commitment capacity derived from the same immutable state snapshot.
    /// Package systems can reuse an existing projection without changing policy semantics.
    package static func investmentDecision(
        programmeID: UUID,
        in state: GameState,
        capacitySnapshot: ProgrammeCommitmentCapacity
    ) -> RecruitingPolicyDecision? {
        investmentDecision(
            programmeID: programmeID,
            in: state,
            capacitySnapshot: capacitySnapshot,
            cache: RecruitingFitCache(state: state),
            weeklyActionCounts: [:],
            weeklyEvaluationCount: 0
        )
    }

    static func investmentDecision(
        programmeID: UUID,
        in state: GameState,
        capacitySnapshot: ProgrammeCommitmentCapacity?,
        cache: RecruitingFitCache,
        weeklyActionCounts: [UUID: Int],
        weeklyEvaluationCount: Int
    ) -> RecruitingPolicyDecision? {
        guard state.college.phase.allowsRecruitingActions,
              let recruiting = state.college.programmes[programmeID] else { return nil }
        let capacity = capacitySnapshot
        let pending = Set(state.scouting.pendingEvaluations.compactMap {
            $0.observerID == programmeID ? $0.prospectID : nil
        })
        let ranked = recruiting.boardIDs.compactMap {
            prospectID -> (
                urgency: Int,
                stage: Int,
                decision: RecruitingPolicyDecision
            )? in
            guard let prospect = state.prospects[prospectID] else { return nil }
            let isAvailable = state.college.prospectRecruitment[prospectID]?.phase == .available
            let isLegalAvailable = isAvailable
                && capacity?.canReserve(position: prospect.position) == true
            let isChallenge = RecruitingCommitmentChallengePolicy.isAuthorized(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )
            let perProspectLimit = max(
                1,
                CollegeRules.aiWeeklyInvestmentActionLimit
                    / CollegeRules.aiWeeklyBoardGrowth
            )
            guard (isLegalAvailable || isChallenge),
                  (weeklyActionCounts[prospectID] ?? 0) < perProspectLimit,
                  let relationship = recruiting.relationships[prospectID],
                  let explanation = RecruitingFitSystem.evaluate(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    in: state,
                    cache: cache
                  ) else { return nil }
            let action: RecruitingAction
            let stage: Int
            let currentScore = explanation.total
            let requiredScore: Int
            if isChallenge,
               let winnerScore = state.college.prospectRecruitment[prospectID]?
                .commitmentContext?.winner.score {
                requiredScore = winnerScore
                    + CollegeRules.minimumCommitmentFlipScoreImprovement
            } else {
                requiredScore = CollegeRules.minimumCommitmentScore
            }
            if state.scouting.observation(observerID: programmeID, prospectID: prospectID) == nil,
               !pending.contains(prospectID) {
                guard recruiting.contactPointsRemaining
                        >= CollegeRules.aiEvaluationContactPoints else { return nil }
                action = .evaluate(points: CollegeRules.aiEvaluationContactPoints)
                stage = 0
            } else if !relationship.scholarshipOffered {
                action = .offerScholarship
                stage = 1
            } else if currentScore >= requiredScore {
                return nil
            } else {
                let nilProposal = nilAllocationProposal(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    requiredScore: requiredScore,
                    explanation: explanation,
                    capacitySnapshot: capacity,
                    in: state
                )
                if let nilProposal, nilProposal.closesCurrentScoreGap {
                    action = .setNILAllocation(amount: nilProposal.amount)
                    stage = 2
                } else if !relationship.visitScheduled,
                          relationship.interest < 100,
                          recruiting.contactPointsRemaining >= CollegeRules.visitContactCost {
                    action = .scheduleVisit
                    stage = 3
                } else if relationship.interest < 100,
                          recruiting.contactPointsRemaining
                            >= CollegeRules.aiEvaluationContactPoints {
                    action = .contact(points: CollegeRules.aiEvaluationContactPoints)
                    stage = 3
                } else if let nilProposal {
                    action = .setNILAllocation(amount: nilProposal.amount)
                    stage = 5
                } else {
                    return nil
                }
            }
            let balancedStage: Int
            if case .evaluate = action,
                      weeklyEvaluationCount >= max(
                        1,
                        (CollegeRules.weeklyRecruitingContactPoints
                            - CollegeRules.visitContactCost)
                            / CollegeRules.aiEvaluationContactPoints
                      ) {
                // Continue filling an empty pipeline, but mature existing pursuits before
                // evaluating the rest of this week's zero-contact board additions.
                balancedStage = 6
            } else {
                balancedStage = stage
            }
            return (isChallenge ? 0 : 1, balancedStage, RecruitingPolicyDecision(
                request: RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: action
                ),
                score: explanation.total,
                explanation: explanation
            ))
        }
        return ranked.min { lhs, rhs in
            if lhs.urgency != rhs.urgency { return lhs.urgency < rhs.urgency }
            if lhs.stage != rhs.stage { return lhs.stage < rhs.stage }
            if lhs.decision.score != rhs.decision.score {
                return lhs.decision.score > rhs.decision.score
            }
            return lhs.decision.request.prospectID.uuidString
                < rhs.decision.request.prospectID.uuidString
        }?.decision
    }

    static func withdrawalDecision(
        programmeID: UUID,
        prospectID: UUID,
        in state: GameState,
        cache: RecruitingFitCache
    ) -> RecruitingPolicyDecision? {
        guard state.college.programmes[programmeID]?.relationships[prospectID] != nil,
              let explanation = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state,
                cache: cache
              ) else { return nil }
        return RecruitingPolicyDecision(
            request: RecruitingActionRequest(
                programmeID: programmeID,
                prospectID: prospectID,
                action: .withdraw
            ),
            score: explanation.total,
            explanation: explanation
        )
    }

    package static func nilAllocationProposal(
        programmeID: UUID,
        prospectID: UUID,
        requiredScore: Int,
        explanation: RecruitingDecisionExplanation,
        capacitySnapshot: ProgrammeCommitmentCapacity?,
        in state: GameState
    ) -> RecruitingNILAllocationProposal? {
        guard let recruiting = state.college.programmes[programmeID],
              let prospect = state.prospects[prospectID],
              let capacity = capacitySnapshot,
              capacity.openReservations > 0 else { return nil }
        let currentAllocation = recruiting.nilAllocation(for: prospectID)
        let maximumIncrement = min(
            CollegeRules.aiInitialNILAllocation - currentAllocation,
            recruiting.nilState.remaining
        )
        guard maximumIncrement >= CollegeRules.nilInterestPointsPerUnit else { return nil }

        let scoreGap = max(0, requiredScore - explanation.total)
        guard scoreGap > 0 else { return nil }
        let priority = prospect.priorities[.nilOpportunity]?.value
            ?? SharedRules.ratingRange.lowerBound
        let priorityMidpoint = (
            SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound
        ) / 2
        let annualShare = recruiting.nilState.annualBudget
            / max(1, capacity.maximumReservations)
        let remainingShare = recruiting.nilState.remaining
            / max(1, capacity.openReservations)
        let fairShare = max(annualShare, remainingShare)
        let priorityShare = fairShare * priority / max(1, priorityMidpoint)
        let unit = CollegeRules.nilInterestPointsPerUnit
        let roundedPortfolioTarget = min(
            CollegeRules.aiInitialNILAllocation,
            max(unit, (priorityShare + unit - 1) / unit * unit)
        )
        let portfolioIncrement = min(
            maximumIncrement,
            max(0, roundedPortfolioTarget - currentAllocation)
        )
            / unit * unit
        guard portfolioIncrement > 0 else { return nil }

        let currentNILComponent = explanation.value(for: .nilOpportunity)
            + explanation.nilAllocationAdjustment
        var scoreClosingIncrement: Int?
        for increment in stride(from: unit, through: portfolioIncrement, by: unit) {
            let projectedAllocation = currentAllocation + increment
            let projectedNILComponent = RecruitingFitSystem.nilOpportunityRawValue(
                allocation: projectedAllocation
            ) * priority / SharedRules.ratingRange.upperBound
            let projectedNILAdjustment = projectedAllocation / unit
            let scoreGain = projectedNILComponent
                + projectedNILAdjustment
                - currentNILComponent
            if scoreGain >= scoreGap {
                scoreClosingIncrement = increment
                break
            }
        }
        let increment = scoreClosingIncrement ?? portfolioIncrement
        return RecruitingNILAllocationProposal(
            amount: currentAllocation + increment,
            incrementalCost: increment,
            closesCurrentScoreGap: scoreClosingIncrement != nil
        )
    }

    private static func priorityPositions(
        programmeID: UUID,
        in state: GameState,
        capacity: ProgrammeCommitmentCapacity
    ) -> [Position] {
        guard let recruiting = state.college.programmes[programmeID] else { return [] }
        let rosterCounts = capacity.projectedRosterCounts
        let boardCounts = Dictionary(grouping: recruiting.boardIDs.compactMap {
            state.prospects[$0]?.position
        }, by: { $0 }).mapValues(\.count)
        return Position.allCases.sorted { lhs, rhs in
            let lhsTarget = max(1, CollegeRules.initialRosterByPosition[lhs] ?? 1)
            let rhsTarget = max(1, CollegeRules.initialRosterByPosition[rhs] ?? 1)
            let lhsPressure = ((rosterCounts[lhs] ?? 0) + (boardCounts[lhs] ?? 0)) * 1_000
                / lhsTarget
            let rhsPressure = ((rosterCounts[rhs] ?? 0) + (boardCounts[rhs] ?? 0)) * 1_000
                / rhsTarget
            if lhsPressure != rhsPressure { return lhsPressure < rhsPressure }
            return lhs.rawValue < rhs.rawValue
        }
    }

    private static func targetExplanation(
        prospect: Prospect,
        programmeID: UUID,
        in state: GameState,
        cache: RecruitingFitCache
    ) -> RecruitingDecisionExplanation? {
        guard let explanation = RecruitingFitSystem.evaluate(
            programmeID: programmeID,
            prospectID: prospect.id,
            in: state,
            cache: cache
        ) else { return nil }
        let knowledgeBonus = state.scouting.observation(
            observerID: programmeID,
            prospectID: prospect.id
        ).map {
            ($0.estimatedPotential.value - SharedRules.ratingRange.lowerBound)
                * $0.confidence / 100
        } ?? 0
        return explanation.addingKnowledgeAdjustment(knowledgeBonus)
    }

    private static func tieBreaker(
        programmeID: UUID,
        prospectID: UUID,
        in state: GameState
    ) -> UInt64 {
        let season = SeededRandom.derive(
            from: state.league.seed,
            scope: .season,
            ordinal: state.calendar.season
        )
        let week = SeededRandom.derive(
            from: season,
            scope: .week,
            ordinal: state.calendar.week
        )
        let programme = SeededRandom.derive(
            from: week,
            scope: .scheduler,
            identifier: programmeID
        )
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: programme,
            scope: .personnel,
            identifier: prospectID
        ))
        return rng.next()
    }

    static func globalPursuitCounts(in state: GameState) -> [UUID: Int] {
        Dictionary(grouping: state.college.programmes.values.flatMap(\.boardIDs), by: { $0 })
            .mapValues(\.count)
    }

    static func pursuitSaturation(in state: GameState) -> Int {
        guard state.prospects.count > 0 else { return 1 }
        return max(
            1,
            (state.programmes.count * CollegeRules.recruitingBoardLimit
                + state.prospects.count - 1) / state.prospects.count
        )
    }
}

public enum CollegeRecruitingMarketSystem {
    private struct Contender {
        let context: RecruitingCommitmentContenderContext
        let tieBreaker: UInt64
    }

    public static func process(
        at calendar: CalendarState,
        in state: GameState
    ) -> CollegeRecruitingMarketTransition {
        guard state.college.portal.phase != .awaitingSpring else {
            return CollegeRecruitingMarketTransition(
                college: state.college,
                commitments: [],
                eventPayloads: []
            )
        }
        let refreshed = refresh(in: state)
        guard state.college.phase.allowsCommitmentResolution,
              calendar.week >= CollegeRules.minimumCommitmentWeek else {
            return CollegeRecruitingMarketTransition(
                college: refreshed,
                commitments: [],
                eventPayloads: []
            )
        }

        var workingState = state
        workingState.college = refreshed
        var college = refreshed
        let cache = RecruitingFitCache(state: workingState)
        var contendersByProspect: [UUID: [Contender]] = [:]
        for programmeID in state.programmes.ids {
            guard let recruiting = refreshed.programmes[programmeID] else { continue }
            for prospectID in recruiting.boardIDs {
                guard let recruitment = refreshed.prospectRecruitment[prospectID],
                      recruitment.phase == .available || recruitment.phase == .committed,
                      let relationship = recruiting.relationships[prospectID],
                      relationship.scholarshipOffered,
                      let explanation = RecruitingFitSystem.evaluate(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        in: workingState,
                        cache: cache
                      ) else { continue }
                let score = explanation.total
                guard score >= CollegeRules.minimumCommitmentScore else { continue }
                contendersByProspect[prospectID, default: []].append(Contender(
                    context: RecruitingCommitmentContenderContext(
                        programmeID: programmeID,
                        score: score,
                        explanation: explanation.components,
                        relationshipInterest: relationship.interest,
                        nilAllocation: recruiting.nilAllocation(for: prospectID),
                        visitScheduled: relationship.visitScheduled
                    ),
                    tieBreaker: commitmentTieBreaker(
                        prospectID: prospectID,
                        programmeID: programmeID,
                        calendar: calendar,
                        rootSeed: state.league.seed
                    )
                ))
            }
        }

        let rankedByProspect = contendersByProspect.mapValues { contenders in
            contenders.sorted { lhs, rhs in
                if lhs.context.score != rhs.context.score {
                    return lhs.context.score > rhs.context.score
                }
                if lhs.tieBreaker != rhs.tieBreaker { return lhs.tieBreaker > rhs.tieBreaker }
                return lhs.context.programmeID.uuidString < rhs.context.programmeID.uuidString
            }
        }
        var commitments: [RecruitingCommitmentDecision] = []
        var payloads: [DomainEventPayload] = []
        let raceOrder = rankedByProspect.keys.sorted { lhs, rhs in
            let lhsBest = rankedByProspect[lhs]?.first
            let rhsBest = rankedByProspect[rhs]?.first
            if lhsBest?.context.score != rhsBest?.context.score {
                return (lhsBest?.context.score ?? Int.min)
                    > (rhsBest?.context.score ?? Int.min)
            }
            if lhsBest?.tieBreaker != rhsBest?.tieBreaker {
                return (lhsBest?.tieBreaker ?? 0) > (rhsBest?.tieBreaker ?? 0)
            }
            return lhs.uuidString < rhs.uuidString
        }
        for prospectID in raceOrder {
            guard let prospect = state.prospects[prospectID],
                  let recruitment = college.prospectRecruitment[prospectID] else { continue }
            let ranked = rankedByProspect[prospectID] ?? []
            let winner: Contender
            let runnerUp: Contender?
            let context: RecruitingCommitmentContext
            let resolved: Bool
            switch recruitment.phase {
            case .available:
                let legal = ranked.filter {
                    CollegeCommitmentCapacitySystem.capacity(
                        programmeID: $0.context.programmeID,
                        in: workingState,
                        college: college
                    )?.canReserve(position: prospect.position) == true
                }
                guard let selected = legal.first else { continue }
                winner = selected
                runnerUp = legal.dropFirst().first
                let rawPreferred = ranked.first
                let selectionReason: CommitmentSelectionReason
                if let rawPreferred,
                   rawPreferred.context.programmeID != winner.context.programmeID {
                    selectionReason = .capacityFallback(
                        blockedPreferred: rawPreferred.context
                    )
                } else {
                    selectionReason = .normal
                }
                context = RecruitingCommitmentContext(
                    committedAt: calendar,
                    winner: winner.context,
                    runnerUp: runnerUp?.context,
                    selectionReason: selectionReason
                )
                resolved = CollegeCommitmentSystem.reserve(
                    prospectID: prospectID,
                    context: context,
                    in: workingState,
                    college: &college,
                    fitCache: cache
                )
            case .committed:
                guard recruitment.commitmentHistory.count
                        < CollegeRules.commitmentHistoryLimit,
                      let currentProgrammeID = recruitment.programmeID,
                      let currentRecruiting = college.programmes[currentProgrammeID],
                      let currentRelationship = currentRecruiting.relationships[prospectID],
                      currentRelationship.scholarshipOffered,
                      let currentExplanation = RecruitingFitSystem.evaluate(
                        programmeID: currentProgrammeID,
                        prospectID: prospectID,
                        in: workingState,
                        cache: cache
                      ) else { continue }
                let previousWinner = RecruitingCommitmentContenderContext(
                    programmeID: currentProgrammeID,
                    score: currentExplanation.total,
                    explanation: currentExplanation.components,
                    relationshipInterest: currentRelationship.interest,
                    nilAllocation: currentRecruiting.nilAllocation(for: prospectID),
                    visitScheduled: currentRelationship.visitScheduled
                )
                let legalTargets = ranked.filter { contender in
                    contender.context.programmeID != currentProgrammeID
                        && CollegeCommitmentCapacitySystem.capacity(
                            programmeID: contender.context.programmeID,
                            in: workingState,
                            college: college
                        )?.canReserve(position: prospect.position) == true
                }
                guard let selected = legalTargets.first else { continue }
                winner = selected
                let rawPreferredTarget = ranked.first {
                    $0.context.programmeID != currentProgrammeID
                }
                let blockedPreferred = rawPreferredTarget.flatMap {
                    $0.context.programmeID == winner.context.programmeID ? nil : $0.context
                }
                runnerUp = legalTargets.dropFirst().first
                context = RecruitingCommitmentContext(
                    committedAt: calendar,
                    winner: winner.context,
                    runnerUp: runnerUp?.context,
                    previousWinner: previousWinner,
                    selectionReason: blockedPreferred.map {
                        .capacityFallback(blockedPreferred: $0)
                    } ?? .normal
                )
                resolved = CollegeCommitmentSystem.flip(
                    prospectID: prospectID,
                    context: context,
                    in: workingState,
                    college: &college,
                    fitCache: cache
                )
            case .signed, .released:
                continue
            }
            guard resolved else { continue }
            let decision = RecruitingCommitmentDecision(
                prospectID: prospectID,
                context: context
            )
            commitments.append(decision)
            payloads.append(.prospectCommitted(
                prospectID: prospectID,
                context: context
            ))
        }
        return CollegeRecruitingMarketTransition(
            college: college,
            commitments: commitments,
            eventPayloads: payloads
        )
    }

    public static func refresh(in state: GameState) -> CollegeState {
        var college = state.college
        let cache = RecruitingFitCache(state: state)
        for programmeID in state.programmes.ids {
            guard let boardIDs = college.programmes[programmeID]?.boardIDs else { continue }
            for prospectID in boardIDs {
                guard let explanation = RecruitingFitSystem.evaluate(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    in: state,
                    cache: cache
                ) else { continue }
                _ = college.updateProgramme(programmeID) {
                    _ = $0.updateRelationship(prospectID) {
                        $0.lastExplanation = explanation.components
                    }
                }
            }
        }
        return college
    }

    private static func commitmentTieBreaker(
        prospectID: UUID,
        programmeID: UUID,
        calendar: CalendarState,
        rootSeed: UInt64
    ) -> UInt64 {
        let season = SeededRandom.derive(
            from: rootSeed,
            scope: .season,
            ordinal: calendar.season
        )
        let week = SeededRandom.derive(from: season, scope: .week, ordinal: calendar.week)
        let prospect = SeededRandom.derive(
            from: week,
            scope: .personnel,
            identifier: prospectID
        )
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: prospect,
            scope: .scheduler,
            identifier: programmeID
        ))
        return rng.next()
    }
}

public enum CollegeRecruitingAISystem {
    public static func process(in state: GameState) throws -> CollegeRecruitingAITransition {
        let controlledProgrammeID = state.career.college?.programmeID
        return try process(
            programmeIDs: state.programmes.ids.filter { $0 != controlledProgrammeID },
            in: state
        )
    }

    package static func process(
        programmeIDs: [UUID],
        in state: GameState
    ) throws -> CollegeRecruitingAITransition {
        guard state.college.phase.allowsRecruitingActions,
              state.college.portal.phase != .awaitingSpring else {
            return CollegeRecruitingAITransition(
                college: state.college,
                scouting: state.scouting,
                decisions: [],
                eventPayloads: []
            )
        }
        var working = state
        var decisions: [RecruitingPolicyDecision] = []
        var payloads: [DomainEventPayload] = []
        let cache = RecruitingFitCache(state: state)
        let prospectsByPosition = Dictionary(grouping: state.prospects.values, by: \.position)
        var pursuitCounts = RecruitingDecisionPolicy.globalPursuitCounts(in: working)
        let pursuitSaturation = RecruitingDecisionPolicy.pursuitSaturation(in: working)
        let eligibleProgrammeIDs = Set(programmeIDs)

        for programmeID in state.programmes.ids where eligibleProgrammeIDs.contains(programmeID) {
            let pursuedProspectIDs = working.college.programmes[programmeID]?.boardIDs ?? []
            guard let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: working,
                college: working.college
            ) else { continue }
            for prospectID in pursuedProspectIDs {
                guard let recruitment = working.college.prospectRecruitment[prospectID]
                else { continue }
                let lostCommitment = recruitment.phase == .committed
                    && recruitment.programmeID != programmeID
                    && !RecruitingCommitmentChallengePolicy.isAuthorized(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        in: working
                    )
                let cullAvailablePursuit = recruitment.phase == .available
                    && working.prospects[prospectID].map {
                        capacity.canReserve(position: $0.position) != true
                    } == true
                guard lostCommitment || cullAvailablePursuit,
                      let withdrawal = RecruitingDecisionPolicy.withdrawalDecision(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        in: working,
                        cache: cache
                      ) else { continue }
                try apply(
                    withdrawal,
                    fitCache: cache,
                    to: &working,
                    decisions: &decisions,
                    payloads: &payloads
                )
                if let count = pursuitCounts[prospectID] {
                    if count <= 1 {
                        pursuitCounts.removeValue(forKey: prospectID)
                    } else {
                        pursuitCounts[prospectID] = count - 1
                    }
                }
            }

            var targetExplanationCache: [UUID: RecruitingDecisionExplanation] = [:]
            while let target = RecruitingDecisionPolicy.targetDecision(
                programmeID: programmeID,
                in: working,
                capacity: capacity,
                cache: cache,
                prospectsByPosition: prospectsByPosition,
                pursuitCounts: pursuitCounts,
                pursuitSaturation: pursuitSaturation,
                targetExplanationCache: &targetExplanationCache
            ) {
                try apply(
                    target,
                    fitCache: cache,
                    to: &working,
                    decisions: &decisions,
                    payloads: &payloads
                )
                pursuitCounts[target.request.prospectID, default: 0] += 1
            }

            var weeklyActionCounts: [UUID: Int] = [:]
            var weeklyEvaluationCount = 0
            for _ in 0..<CollegeRules.aiWeeklyInvestmentActionLimit {
                guard let investment = RecruitingDecisionPolicy.investmentDecision(
                    programmeID: programmeID,
                    in: working,
                    capacitySnapshot: capacity,
                    cache: cache,
                    weeklyActionCounts: weeklyActionCounts,
                    weeklyEvaluationCount: weeklyEvaluationCount
                ) else { break }
                try apply(
                    investment,
                    fitCache: cache,
                    to: &working,
                    decisions: &decisions,
                    payloads: &payloads
                )
                weeklyActionCounts[investment.request.prospectID, default: 0] += 1
                if case .evaluate = investment.request.action {
                    weeklyEvaluationCount += 1
                }
            }
        }
        return CollegeRecruitingAITransition(
            college: working.college,
            scouting: working.scouting,
            decisions: decisions,
            eventPayloads: payloads
        )
    }

    private static func apply(
        _ decision: RecruitingPolicyDecision,
        fitCache: RecruitingFitCache,
        to state: inout GameState,
        decisions: inout [RecruitingPolicyDecision],
        payloads: inout [DomainEventPayload]
    ) throws {
        do {
            let transition = try CollegeRecruitingSystem.apply(
                decision.request,
                in: state,
                fitCache: fitCache
            )
            state.college = transition.college
            state.scouting = transition.scouting
            decisions.append(decision)
            payloads.append(contentsOf: transition.eventPayloads)
        } catch let error as RecruitingActionError {
            throw CollegeRecruitingAIError.rejectedLegalDecision(error)
        }
    }
}
