import Foundation
import FootballSimCore

private struct M3RecruitingCalibrationRun {
    let state: GameState
    let projectedTargets: [UUID: Int]
    let signedClassSizes: [Int]
    let fillRates: [Double]
    let classOverallAverages: [Double]
    let signedOverallRatings: [Int]
    let nilPromises: [Int]
    let positionCoveredProgrammes: Int
    let legalRosterProgrammes: Int
    let recruitedScholarshipJoins: Int
    let walkOnJoins: Int
    let signedResolutions: Int
    let releasedResolutions: Int
    let commitmentEvents: Int
    let recruitingInteractionEvents: Int
    let emittedEventCount: Int
    let runtimeSeconds: Double
    let weeklyDiagnostics: [M3RecruitingWeekDiagnostic]
}

private struct M3RecruitingWeekDiagnostic {
    let week: Int
    let boardSlots: Int
    let uniqueBoardProspects: Int
    let maximumBoardMultiplicity: Int
    let offeredRelationships: Int
    let qualifiedRelationships: Int
    let qualifiedProspects: Int
    let offeredScoreMinimum: Int
    let offeredScoreMedian: Int
    let offeredScoreMaximum: Int
    let needsEvaluation: Int
    let needsOffer: Int
    let needsNIL: Int
    let fundableNILNeeds: Int
    let exhaustedNILNeeds: Int
    let nilNeedScoreGapMedian: Int
    let nilNeedPriorityMedian: Int
    let needsRelationshipWork: Int
    let maturePursuits: Int
    let programmesWithOpenCapacity: Int
    let totalOpenCapacity: Int
    let activeReservations: Int
    let retainedChallengers: Int
    let flipEligibleChallengers: Int
    var newCommitments: Int
    var flips: Int
}

private func m3Median(_ values: [Int]) -> Double {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let middle = sorted.count / 2
    if sorted.count.isMultiple(of: 2) {
        return Double(sorted[middle - 1] + sorted[middle]) / 2
    }
    return Double(sorted[middle])
}

private func m3Average(_ values: [Int]) -> Double {
    guard !values.isEmpty else { return 0 }
    return Double(values.reduce(0, +)) / Double(values.count)
}

private func m3Range(_ values: [Int]) -> String {
    guard let minimum = values.min(), let maximum = values.max() else { return "empty" }
    return "\(minimum)...\(maximum)"
}

private struct M3NILPolicyFixture {
    var state: GameState
    let programmeID: UUID
    let prospectID: UUID
    let portfolioTarget: Int
    let currentScore: Int
    let targetScore: Int
}

private func m3ReplacingRecruitingProgramme(
    _ programme: ProgrammeRecruitingState,
    in state: GameState
) -> GameState {
    var result = state
    var programmes = result.college.programmes
    programmes[programme.programmeID] = programme
    result.college = CollegeState(
        recruitingSeason: result.college.recruitingSeason,
        portal: result.college.portal,
        phase: result.college.phase,
        programmes: programmes,
        prospectRecruitment: result.college.prospectRecruitment,
        archivedProspects: result.college.archivedProspects,
        redshirtPlans: result.college.redshirtPlans
    )
    return result
}

private func m3Prospect(
    _ prospect: Prospect,
    nilPriority: Int,
    relationshipPriority: Int
) -> Prospect {
    var priorities = prospect.priorities
    priorities[.nilOpportunity] = Rating(nilPriority)
    priorities[.relationship] = Rating(relationshipPriority)
    return Prospect(
        id: prospect.id,
        firstName: prospect.firstName,
        lastName: prospect.lastName,
        position: prospect.position,
        age: prospect.age,
        originCityID: prospect.originCityID,
        attributes: prospect.attributes,
        potential: prospect.potential,
        traits: prospect.traits,
        priorities: priorities
    )
}

private func m3PortfolioTarget(
    nilPriority: Int,
    programmeID: UUID,
    in state: GameState
) -> Int {
    let recruiting = state.college.programmes[programmeID]!
    let capacity = CollegeCommitmentCapacitySystem.capacity(
        programmeID: programmeID,
        in: state,
        college: state.college
    )!
    let annualShare = recruiting.nilState.annualBudget
        / max(1, capacity.maximumReservations)
    let remainingShare = recruiting.nilState.remaining
        / max(1, capacity.openReservations)
    let priorityMidpoint = (
        SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound
    ) / 2
    let priorityShare = max(annualShare, remainingShare)
        * nilPriority / max(1, priorityMidpoint)
    let unit = CollegeRules.nilInterestPointsPerUnit
    return min(
        CollegeRules.aiInitialNILAllocation,
        max(unit, (priorityShare + unit - 1) / unit * unit)
    )
}

private func m3NILScoreGain(allocation: Int, priority: Int) -> Int {
    let unit = CollegeRules.nilInterestPointsPerUnit
    let raw = min(10, max(0, allocation) / unit)
    return raw * priority / SharedRules.ratingRange.upperBound
        + allocation / unit
}

private func m3RelationshipInterest(
    baseScore: Int,
    relationshipPriority: Int,
    nilGain: Int,
    closesAtTarget: Bool,
    below upperScore: Int = CollegeRules.minimumCommitmentScore
) -> (interest: Int, score: Int)? {
    (0..<100).compactMap { interest -> (Int, Int)? in
        let relationshipComponent = (interest / 10) * relationshipPriority
            / SharedRules.ratingRange.upperBound
        let score = baseScore + relationshipComponent + interest
        guard score < CollegeRules.minimumCommitmentScore,
              score < upperScore,
              (score + nilGain >= CollegeRules.minimumCommitmentScore)
                == closesAtTarget else { return nil }
        return (interest, score)
    }.max { lhs, rhs in
        if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
        return lhs.0 < rhs.0
    }
}

private func m3NILPolicyFixture(
    seed: UInt64,
    nilPriority: Int,
    relationshipPriority: Int,
    closesAtTarget: Bool,
    contactPointsRemaining: Int
) throws -> M3NILPolicyFixture {
    var state = GameState.bootstrap(seed: seed)
    let programmeID = state.programmes.ids[0]
    let capacity = CollegeCommitmentCapacitySystem.capacity(
        programmeID: programmeID,
        in: state,
        college: state.college
    )!
    let fitSnapshot = RecruitingFitSnapshot(in: state)
    let candidates = state.prospects.values.filter {
        capacity.canReserve(position: $0.position)
    }.sorted { lhs, rhs in
        let lhsScore = fitSnapshot.evaluate(
            programmeID: programmeID,
            prospectID: lhs.id
        )?.total ?? Int.max
        let rhsScore = fitSnapshot.evaluate(
            programmeID: programmeID,
            prospectID: rhs.id
        )?.total ?? Int.max
        if lhsScore != rhsScore { return lhsScore < rhsScore }
        return lhs.id.uuidString < rhs.id.uuidString
    }
    let portfolioTarget = m3PortfolioTarget(
        nilPriority: nilPriority,
        programmeID: programmeID,
        in: state
    )
    let nilGain = m3NILScoreGain(allocation: portfolioTarget, priority: nilPriority)
    let selection = candidates.lazy.compactMap {
        prospect -> (Prospect, Int, Int)? in
        let baseScore = fitSnapshot.evaluate(
            programmeID: programmeID,
            prospectID: prospect.id
        )?.total ?? Int.max
        guard let interest = m3RelationshipInterest(
            baseScore: baseScore,
            relationshipPriority: relationshipPriority,
            nilGain: nilGain,
            closesAtTarget: closesAtTarget
        ) else { return nil }
        return (prospect, interest.interest, interest.score)
    }.first!
    let prospect = selection.0
    state.prospects.insert(m3Prospect(
        prospect,
        nilPriority: nilPriority,
        relationshipPriority: relationshipPriority
    ))
    let existing = state.college.programmes[programmeID]!
    state = m3ReplacingRecruitingProgramme(
        ProgrammeRecruitingState(
            programmeID: programmeID,
            boardIDs: [prospect.id],
            relationships: [
                prospect.id: ProgrammeProspectRelationship(
                    prospectID: prospect.id,
                    interest: selection.1,
                    scholarshipOffered: true
                ),
            ],
            scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
            contactPointsRemaining: contactPointsRemaining,
            nilState: existing.nilState
        ),
        in: state
    )
    let midpoint = (
        SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound
    ) / 2
    state.scouting = ScoutingState(observationsByObserver: [
        programmeID: [
            prospect.id: ProspectObservation(
                prospectID: prospect.id,
                estimatedAttributes: [.schemeFit: Rating(midpoint)],
                estimatedPotential: prospect.potential,
                confidence: 100,
                lastUpdated: state.calendar,
                evidenceCount: 1
            ),
        ],
    ])
    let currentScore = RecruitingFitSystem.evaluate(
        programmeID: programmeID,
        prospectID: prospect.id,
        in: state
    )!.total
    let allocation = try CollegeRecruitingSystem.apply(
        RecruitingActionRequest(
            programmeID: programmeID,
            prospectID: prospect.id,
            action: .setNILAllocation(amount: portfolioTarget)
        ),
        in: state
    )
    var projected = state
    projected.college = allocation.college
    let targetScore = RecruitingFitSystem.evaluate(
        programmeID: programmeID,
        prospectID: prospect.id,
        in: projected
    )!.total
    return M3NILPolicyFixture(
        state: state,
        programmeID: programmeID,
        prospectID: prospect.id,
        portfolioTarget: portfolioTarget,
        currentScore: currentScore,
        targetScore: targetScore
    )
}

private func m3FinalWeekClosingFixture(seed: UInt64) throws -> M3NILPolicyFixture {
    var finalWeekState = GameState.bootstrap(seed: seed)
    // The last week recruiting is open, which is the week before signing day rather than the last
    // week of the calendar: `02` section 4.1 closes contact on signing day, so a recruiting request
    // in week 21 is refused by design and this fixture would be asserting the gate, not the policy.
    while finalWeekState.calendar.week < CollegeRules.signingDayWeek - 1 {
        finalWeekState = try WorldScheduler.advanceWeek(finalWeekState).state
    }
    let nilPriority = SharedRules.ratingRange.upperBound
    let relationshipPriority = SharedRules.ratingRange.lowerBound
    let midpoint = (
        SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound
    ) / 2

    for programmeID in finalWeekState.programmes.ids {
        var state = finalWeekState
        let removableBoardIDs = state.college.programmes[programmeID]?.boardIDs.filter {
            state.college.prospectRecruitment[$0]?.phase == .available
        } ?? []
        for prospectID in removableBoardIDs {
            let transition = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .withdraw
                ),
                in: state
            )
            state.college = transition.college
            state.scouting = transition.scouting
        }
        guard let capacity = CollegeCommitmentCapacitySystem.capacity(
            programmeID: programmeID,
            in: state,
            college: state.college
        ), capacity.openReservations > 0,
              (state.college.programmes[programmeID]?.nilState.remaining ?? 0)
                >= CollegeRules.nilInterestPointsPerUnit else { continue }
        let portfolioTarget = m3PortfolioTarget(
            nilPriority: nilPriority,
            programmeID: programmeID,
            in: state
        )
        let nilGain = m3NILScoreGain(
            allocation: portfolioTarget,
            priority: nilPriority
        )
        let fitSnapshot = RecruitingFitSnapshot(in: state)
        let globallyPursuedIDs = Set(state.college.programmes.values.flatMap(\.boardIDs))
        let selection = state.prospects.values.lazy.compactMap {
            prospect -> (Prospect, Int, Int)? in
            guard state.college.prospectRecruitment[prospect.id]?.phase == .available,
                  !globallyPursuedIDs.contains(prospect.id),
                  capacity.canReserve(position: prospect.position),
                  let baseScore = fitSnapshot.evaluate(
                    programmeID: programmeID,
                    prospectID: prospect.id
                  )?.total,
                  let interest = m3RelationshipInterest(
                    baseScore: baseScore,
                    relationshipPriority: relationshipPriority,
                    nilGain: nilGain,
                    closesAtTarget: true
                  ) else { return nil }
            return (prospect, interest.interest, interest.score)
        }.first
        guard let selection else { continue }
        let prospect = selection.0
        state.prospects.insert(m3Prospect(
            prospect,
            nilPriority: nilPriority,
            relationshipPriority: relationshipPriority
        ))
        let existing = state.college.programmes[programmeID]!
        var relationships = existing.relationships
        relationships[prospect.id] = ProgrammeProspectRelationship(
            prospectID: prospect.id,
            interest: selection.1,
            scholarshipOffered: true
        )
        state = m3ReplacingRecruitingProgramme(
            ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: existing.boardIDs + [prospect.id],
                relationships: relationships,
                scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                contactPointsRemaining: 0,
                nilState: existing.nilState
            ),
            in: state
        )
        var observations = state.scouting.observationsByObserver
        observations[programmeID] = [
            prospect.id: ProspectObservation(
                prospectID: prospect.id,
                estimatedAttributes: [.schemeFit: Rating(midpoint)],
                estimatedPotential: prospect.potential,
                confidence: 100,
                lastUpdated: state.calendar,
                evidenceCount: 1
            ),
        ]
        state.scouting = ScoutingState(
            observationsByObserver: observations,
            pendingEvaluations: state.scouting.pendingEvaluations.filter {
                $0.observerID != programmeID
            }
        )
        let currentScore = RecruitingFitSystem.evaluate(
            programmeID: programmeID,
            prospectID: prospect.id,
            in: state
        )!.total
        let allocation = try CollegeRecruitingSystem.apply(
            RecruitingActionRequest(
                programmeID: programmeID,
                prospectID: prospect.id,
                action: .setNILAllocation(amount: portfolioTarget)
            ),
            in: state
        )
        var projected = state
        projected.college = allocation.college
        let targetScore = RecruitingFitSystem.evaluate(
            programmeID: programmeID,
            prospectID: prospect.id,
            in: projected
        )!.total
        return M3NILPolicyFixture(
            state: state,
            programmeID: programmeID,
            prospectID: prospect.id,
            portfolioTarget: portfolioTarget,
            currentScore: currentScore,
            targetScore: targetScore
        )
    }
    preconditionFailure("final-week fixture found no capacity-legal NIL crossing")
}

private func m3RecruitingWeekDiagnostic(in state: GameState) -> M3RecruitingWeekDiagnostic {
    let fitSnapshot = RecruitingFitSnapshot(in: state)
    var boardMultiplicity: [UUID: Int] = [:]
    var offeredScores: [Int] = []
    var qualifiedRelationships = 0
    var qualifiedProspectIDs: Set<UUID> = []
    var needsEvaluation = 0
    var needsOffer = 0
    var needsNIL = 0
    var fundableNILNeeds = 0
    var exhaustedNILNeeds = 0
    var nilNeedScoreGaps: [Int] = []
    var nilNeedPriorities: [Int] = []
    var needsRelationshipWork = 0
    var maturePursuits = 0
    var programmesWithOpenCapacity = 0
    var totalOpenCapacity = 0
    var activeReservations = 0
    var retainedChallengers = 0
    var flipEligibleChallengers = 0
    let pending = Set(state.scouting.pendingEvaluations.map {
        "\($0.observerID.uuidString)|\($0.prospectID.uuidString)"
    })

    for programmeID in state.programmes.ids {
        guard let recruiting = state.college.programmes[programmeID] else { continue }
        let capacity = CollegeCommitmentCapacitySystem.capacity(
            programmeID: programmeID,
            in: state,
            college: state.college
        )
        if let capacity {
            totalOpenCapacity += capacity.openReservations
            activeReservations += capacity.activeReservations
            if capacity.openReservations > 0 { programmesWithOpenCapacity += 1 }
        }
        for prospectID in recruiting.boardIDs {
            boardMultiplicity[prospectID, default: 0] += 1
            guard let relationship = recruiting.relationships[prospectID],
                  let recruitment = state.college.prospectRecruitment[prospectID],
                  let prospect = state.prospects[prospectID]
            else { continue }
            let actionableAvailable = recruitment.phase == .available
                && capacity?.canReserve(position: prospect.position) == true
            let context = recruitment.commitmentContext
            let actionableChallenge = state.calendar.week < SharedRules.inSeasonWeeks
                && recruitment.phase == .committed
                && recruitment.programmeID != programmeID
                && recruitment.commitmentHistory.count < CollegeRules.commitmentHistoryLimit
                && context?.committedAt == state.calendar
                && (context?.runnerUp?.programmeID == programmeID
                    || context?.previousWinner?.programmeID == programmeID)
                && relationship.scholarshipOffered
                && capacity?.canReserve(position: prospect.position) == true
            guard actionableAvailable || actionableChallenge,
                  let explanation = fitSnapshot.evaluate(
                    programmeID: programmeID,
                    prospectID: prospectID
                  ) else { continue }
            let hasObservation = state.scouting.observation(
                observerID: programmeID,
                prospectID: prospectID
            ) != nil
            let hasPendingEvaluation = pending.contains(
                "\(programmeID.uuidString)|\(prospectID.uuidString)"
            )
            let offeredScore = relationship.scholarshipOffered ? explanation.total : nil
            let requiredScore = actionableChallenge
                ? (context?.winner.score ?? CollegeRules.minimumCommitmentScore)
                    + CollegeRules.minimumCommitmentFlipScoreImprovement
                : CollegeRules.minimumCommitmentScore
            if !hasObservation && !hasPendingEvaluation {
                needsEvaluation += 1
            } else if !relationship.scholarshipOffered {
                needsOffer += 1
            } else {
                let score = offeredScore ?? requiredScore
                if score >= requiredScore {
                    maturePursuits += 1
                } else {
                    let nilProposal = RecruitingDecisionPolicy.nilAllocationProposal(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        requiredScore: requiredScore,
                        explanation: explanation,
                        capacitySnapshot: capacity,
                        in: state
                    )
                    let canVisit = !relationship.visitScheduled
                        && relationship.interest < 100
                        && recruiting.contactPointsRemaining >= CollegeRules.visitContactCost
                    let canContact = relationship.interest < 100
                        && recruiting.contactPointsRemaining
                            >= CollegeRules.aiEvaluationContactPoints
                    let needsNILNow = nilProposal?.closesCurrentScoreGap == true
                        || (!canVisit && !canContact && nilProposal != nil)
                    if needsNILNow {
                        needsNIL += 1
                        fundableNILNeeds += 1
                        nilNeedScoreGaps.append(requiredScore - score)
                        nilNeedPriorities.append(
                            state.prospects[prospectID]?
                                .priorities[.nilOpportunity]?.value ?? 0
                        )
                    } else if canVisit || canContact {
                        needsRelationshipWork += 1
                    } else if recruiting.nilState.remaining
                                < CollegeRules.nilInterestPointsPerUnit {
                        needsNIL += 1
                        exhaustedNILNeeds += 1
                        nilNeedScoreGaps.append(requiredScore - score)
                        nilNeedPriorities.append(
                            state.prospects[prospectID]?
                                .priorities[.nilOpportunity]?.value ?? 0
                        )
                    } else {
                        maturePursuits += 1
                    }
                }
            }

            guard relationship.scholarshipOffered else { continue }
            let score = offeredScore ?? 0
            offeredScores.append(score)
            if score >= requiredScore {
                qualifiedRelationships += 1
                qualifiedProspectIDs.insert(prospectID)
            }
            if actionableChallenge {
                retainedChallengers += 1
                if score >= requiredScore {
                    flipEligibleChallengers += 1
                }
            }
        }
    }
    let sortedScores = offeredScores.sorted()
    return M3RecruitingWeekDiagnostic(
        week: state.calendar.week,
        boardSlots: boardMultiplicity.values.reduce(0, +),
        uniqueBoardProspects: boardMultiplicity.count,
        maximumBoardMultiplicity: boardMultiplicity.values.max() ?? 0,
        offeredRelationships: offeredScores.count,
        qualifiedRelationships: qualifiedRelationships,
        qualifiedProspects: qualifiedProspectIDs.count,
        offeredScoreMinimum: sortedScores.first ?? 0,
        offeredScoreMedian: Int(m3Median(sortedScores).rounded()),
        offeredScoreMaximum: sortedScores.last ?? 0,
        needsEvaluation: needsEvaluation,
        needsOffer: needsOffer,
        needsNIL: needsNIL,
        fundableNILNeeds: fundableNILNeeds,
        exhaustedNILNeeds: exhaustedNILNeeds,
        nilNeedScoreGapMedian: Int(m3Median(nilNeedScoreGaps).rounded()),
        nilNeedPriorityMedian: Int(m3Median(nilNeedPriorities).rounded()),
        needsRelationshipWork: needsRelationshipWork,
        maturePursuits: maturePursuits,
        programmesWithOpenCapacity: programmesWithOpenCapacity,
        totalOpenCapacity: totalOpenCapacity,
        activeReservations: activeReservations,
        retainedChallengers: retainedChallengers,
        flipEligibleChallengers: flipEligibleChallengers,
        newCommitments: 0,
        flips: 0
    )
}

private func runM3RecruitingCalibration(seed: UInt64) throws -> M3RecruitingCalibrationRun {
    var state = GameState.bootstrap(seed: seed)
    let recruitingSeason = state.calendar.season
    let initialPlayerIDs = Set(state.players.ids)
    let projectedTargets = Dictionary(uniqueKeysWithValues: state.programmes.ids.map {
        programmeID in
        (
            programmeID,
            CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )?.maximumReservations ?? 0
        )
    })
    var recruitedScholarshipJoins = 0
    var walkOnJoins = 0
    var signedResolutions = 0
    var releasedResolutions = 0
    var commitmentEvents = 0
    var recruitingInteractionEvents = 0
    var emittedEventCount = 0
    var weeklyDiagnostics: [M3RecruitingWeekDiagnostic] = []
    let startedAt = Date().timeIntervalSinceReferenceDate

    while state.calendar.season == recruitingSeason {
        var diagnostic = m3RecruitingWeekDiagnostic(in: state)
        let transition = try WorldScheduler.advanceWeek(state)
        emittedEventCount += transition.emittedEvents.count
        for event in transition.emittedEvents {
            switch event.payload {
            case let .playerJoined(_, _, source):
                switch source {
                case .recruitedScholarship:
                    recruitedScholarshipJoins += 1
                case .walkOn:
                    walkOnJoins += 1
                case .provisionalReplacement:
                    break
                }
            case let .commitmentResolved(_, _, outcome):
                switch outcome {
                case .signed:
                    signedResolutions += 1
                case .released:
                    releasedResolutions += 1
                }
            case let .prospectCommitted(_, context):
                commitmentEvents += 1
                if context.previousWinner == nil {
                    diagnostic.newCommitments += 1
                } else {
                    diagnostic.flips += 1
                }
            case .recruitingInteraction:
                recruitingInteractionEvents += 1
            default:
                break
            }
        }
        weeklyDiagnostics.append(diagnostic)
        state = transition.state
    }
    let runtimeSeconds = Date().timeIntervalSinceReferenceDate - startedAt

    var signedByProgramme = Dictionary(uniqueKeysWithValues: state.programmes.ids.map { ($0, 0) })
    var overallByProgramme: [UUID: [Int]] = [:]
    var signedOverallRatings: [Int] = []
    var nilPromises: [Int] = []
    for career in state.people.playerCareers.values {
        guard let origin = career.recruitingOrigin,
              origin.signingSeason == recruitingSeason else { continue }
        signedByProgramme[origin.programmeID, default: 0] += 1
        overallByProgramme[origin.programmeID, default: []].append(
            origin.overallAtSigning.value
        )
        signedOverallRatings.append(origin.overallAtSigning.value)
        nilPromises.append(origin.finalNILAllocation)
    }

    var positionCoveredProgrammes = 0
    var legalRosterProgrammes = 0
    for programme in state.programmes.values {
        let rosterPlayers = programme.rosterIDs.compactMap { state.players[$0] }
        let positionCounts = Dictionary(grouping: rosterPlayers, by: \.position).mapValues(\.count)
        if Position.allCases.allSatisfy({ position in
            positionCounts[position] ?? 0
                >= SharedRules.minimumPlayableRosterByPosition[position] ?? 0
        }) {
            positionCoveredProgrammes += 1
        }
        let recruiting = state.college.programmes[programme.id]
        // The rollover snapshot is taken before the following week's spring fill. A legal
        // roster may therefore be below the 105-player ceiling while still covering every
        // playable position; the scheduler fills remaining seats at the next boundary.
        if (1...CollegeRules.rosterLimit).contains(programme.rosterIDs.count),
           Set(programme.rosterIDs).count == programme.rosterIDs.count,
           rosterPlayers.count == programme.rosterIDs.count,
           programme.scholarshipCount <= CollegeRules.scholarshipLimit,
           recruiting?.scholarshipPlayerIDs.count == programme.scholarshipCount,
           Set(recruiting?.scholarshipPlayerIDs ?? []).isSubset(of: Set(programme.rosterIDs)),
           rosterPlayers.allSatisfy({ $0.eligibility != nil && $0.contract == nil }) {
            legalRosterProgrammes += 1
        }
    }
    let signedClassSizes = state.programmes.ids.map { signedByProgramme[$0] ?? 0 }
    let fillRates = state.programmes.ids.compactMap { programmeID -> Double? in
        guard let target = projectedTargets[programmeID], target > 0 else { return nil }
        return Double(signedByProgramme[programmeID] ?? 0) / Double(target)
    }
    let classOverallAverages = state.programmes.ids.compactMap { programmeID -> Double? in
        guard let ratings = overallByProgramme[programmeID], !ratings.isEmpty else { return nil }
        return m3Average(ratings)
    }

    expect(initialPlayerIDs.isDisjoint(with: Set(
        state.people.playerCareers.values.compactMap { career in
            career.recruitingOrigin?.signingSeason == recruitingSeason ? career.playerID : nil
        }
    )))

    return M3RecruitingCalibrationRun(
        state: state,
        projectedTargets: projectedTargets,
        signedClassSizes: signedClassSizes,
        fillRates: fillRates,
        classOverallAverages: classOverallAverages,
        signedOverallRatings: signedOverallRatings,
        nilPromises: nilPromises,
        positionCoveredProgrammes: positionCoveredProgrammes,
        legalRosterProgrammes: legalRosterProgrammes,
        recruitedScholarshipJoins: recruitedScholarshipJoins,
        walkOnJoins: walkOnJoins,
        signedResolutions: signedResolutions,
        releasedResolutions: releasedResolutions,
        commitmentEvents: commitmentEvents,
        recruitingInteractionEvents: recruitingInteractionEvents,
        emittedEventCount: emittedEventCount,
        runtimeSeconds: runtimeSeconds,
        weeklyDiagnostics: weeklyDiagnostics
    )
}

func runM3RecruitingCalibrationTests() {
    suite("M3 recruiting calibration") {
      let seasonOnly = ProcessInfo.processInfo.environment[
        "M3_RECRUITING_SEASON_ONLY"
      ] != nil
      if !seasonOnly {
        test("partial NIL yields to legal renewable relationship work") {
            var fixture = try m3NILPolicyFixture(
                seed: 93_016,
                nilPriority: 40,
                relationshipPriority: 40,
                closesAtTarget: false,
                contactPointsRemaining: CollegeRules.weeklyRecruitingContactPoints
            )
            expect(fixture.currentScore < CollegeRules.minimumCommitmentScore)
            expect(fixture.targetScore < CollegeRules.minimumCommitmentScore)
            let recruitingBefore = fixture.state.college.programmes[fixture.programmeID]!
            let decision = RecruitingDecisionPolicy.investmentDecision(
                programmeID: fixture.programmeID,
                in: fixture.state
            )
            guard case .scheduleVisit = decision?.request.action else {
                expect(false, "a partial NIL proposal displaced a legal visit")
                return
            }
            let transition = try CollegeRecruitingSystem.apply(
                decision!.request,
                in: fixture.state
            )
            fixture.state.college = transition.college
            fixture.state.scouting = transition.scouting
            let recruitingAfter = fixture.state.college.programmes[fixture.programmeID]!
            expectEqual(
                recruitingAfter.contactPointsRemaining,
                recruitingBefore.contactPointsRemaining - CollegeRules.visitContactCost
            )
            expectEqual(
                recruitingAfter.relationships[fixture.prospectID]?.interest,
                min(
                    100,
                    (recruitingBefore.relationships[fixture.prospectID]?.interest ?? 0)
                        + CollegeRules.visitInterestBonus
                )
            )
            expectEqual(recruitingAfter.nilState.remaining, recruitingBefore.nilState.remaining)
            expectEqual(
                recruitingAfter.nilState.recruitingReservations[fixture.prospectID],
                nil
            )
        }

        test("renewable work follows the highest-score pursuit across visit and contact") {
            var state = GameState.bootstrap(seed: 93_021)
            let programmeID = state.programmes.ids[0]
            let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!
            let candidates = state.prospects.values.filter {
                capacity.canReserve(position: $0.position)
            }.sorted { $0.id.uuidString < $1.id.uuidString }
            let priority = SharedRules.ratingRange.lowerBound
            let relationshipScore: (Int, Int) -> Int = { base, interest in
                base + interest + (interest / 10) * priority
                    / SharedRules.ratingRange.upperBound
            }
            let midpoint = (
                SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound
            ) / 2
            var fixture: (
                state: GameState,
                leadID: UUID,
                otherID: UUID,
                leadInterest: Int,
                otherInterest: Int
            )?

            for lead in candidates.prefix(40) {
                for other in candidates.prefix(40) where other.id != lead.id {
                    var trial = state
                    trial.prospects.insert(m3Prospect(
                        lead,
                        nilPriority: priority,
                        relationshipPriority: priority
                    ))
                    trial.prospects.insert(m3Prospect(
                        other,
                        nilPriority: priority,
                        relationshipPriority: priority
                    ))
                    let existing = trial.college.programmes[programmeID]!
                    trial = m3ReplacingRecruitingProgramme(
                        ProgrammeRecruitingState(
                            programmeID: programmeID,
                            boardIDs: [lead.id, other.id],
                            relationships: [
                                lead.id: ProgrammeProspectRelationship(
                                    prospectID: lead.id,
                                    interest: 0,
                                    scholarshipOffered: true
                                ),
                                other.id: ProgrammeProspectRelationship(
                                    prospectID: other.id,
                                    interest: 0,
                                    scholarshipOffered: true
                                ),
                            ],
                            scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                            contactPointsRemaining: CollegeRules.weeklyRecruitingContactPoints,
                            nilState: existing.nilState
                        ),
                        in: trial
                    )
                    trial.scouting = ScoutingState(observationsByObserver: [
                        programmeID: [
                            lead.id: ProspectObservation(
                                prospectID: lead.id,
                                estimatedAttributes: [.schemeFit: Rating(midpoint)],
                                estimatedPotential: lead.potential,
                                confidence: 100,
                                lastUpdated: trial.calendar,
                                evidenceCount: 1
                            ),
                            other.id: ProspectObservation(
                                prospectID: other.id,
                                estimatedAttributes: [.schemeFit: Rating(midpoint)],
                                estimatedPotential: other.potential,
                                confidence: 100,
                                lastUpdated: trial.calendar,
                                evidenceCount: 1
                            ),
                        ],
                    ])
                    let leadBase = RecruitingFitSystem.evaluate(
                        programmeID: programmeID,
                        prospectID: lead.id,
                        in: trial
                    )!.total
                    let otherScore = RecruitingFitSystem.evaluate(
                        programmeID: programmeID,
                        prospectID: other.id,
                        in: trial
                    )!.total
                    let portfolioTarget = m3PortfolioTarget(
                        nilPriority: priority,
                        programmeID: programmeID,
                        in: trial
                    )
                    let nilGain = m3NILScoreGain(
                        allocation: portfolioTarget,
                        priority: priority
                    )
                    let leadInterest = (0...70).last { interest in
                        let score = relationshipScore(leadBase, interest)
                        let afterVisitAndContact = relationshipScore(
                            leadBase,
                            interest + CollegeRules.visitInterestBonus
                                + CollegeRules.aiEvaluationContactPoints / 4
                        )
                        return score > otherScore
                            && score + nilGain < CollegeRules.minimumCommitmentScore
                            && afterVisitAndContact + nilGain
                                < CollegeRules.minimumCommitmentScore
                    }
                    guard let leadInterest else { continue }
                    var relationships = trial.college.programmes[programmeID]!.relationships
                    relationships[lead.id] = ProgrammeProspectRelationship(
                        prospectID: lead.id,
                        interest: leadInterest,
                        scholarshipOffered: true
                    )
                    let configured = trial.college.programmes[programmeID]!
                    trial = m3ReplacingRecruitingProgramme(
                        ProgrammeRecruitingState(
                            programmeID: programmeID,
                            boardIDs: configured.boardIDs,
                            relationships: relationships,
                            scholarshipPlayerIDs: configured.scholarshipPlayerIDs,
                            contactPointsRemaining: configured.contactPointsRemaining,
                            nilState: configured.nilState
                        ),
                        in: trial
                    )
                    fixture = (trial, lead.id, other.id, leadInterest, 0)
                    break
                }
                if fixture != nil { break }
            }
            guard let fixture else {
                expect(false, "fixture found no stable partial-NIL relationship sequence")
                return
            }
            state = fixture.state
            let recruitingBefore = state.college.programmes[programmeID]!
            var actualRequests: [RecruitingActionRequest] = []
            for _ in 0..<3 {
                guard let decision = RecruitingDecisionPolicy.investmentDecision(
                    programmeID: programmeID,
                    in: state
                ) else {
                    expect(false, "renewable sequence ended before three bounded actions")
                    return
                }
                actualRequests.append(decision.request)
                let transition = try CollegeRecruitingSystem.apply(
                    decision.request,
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            expectEqual(actualRequests, [
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: fixture.leadID,
                    action: .scheduleVisit
                ),
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: fixture.leadID,
                    action: .contact(points: CollegeRules.aiEvaluationContactPoints)
                ),
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: fixture.leadID,
                    action: .contact(points: CollegeRules.aiEvaluationContactPoints)
                ),
            ])
            let recruitingAfter = state.college.programmes[programmeID]!
            expectEqual(
                recruitingAfter.contactPointsRemaining,
                recruitingBefore.contactPointsRemaining
                    - CollegeRules.visitContactCost
                    - 2 * CollegeRules.aiEvaluationContactPoints
            )
            expectEqual(
                recruitingAfter.relationships[fixture.leadID]?.interest,
                fixture.leadInterest + CollegeRules.visitInterestBonus
                    + 2 * (CollegeRules.aiEvaluationContactPoints / 4)
            )
            expectEqual(
                recruitingAfter.relationships[fixture.otherID]?.interest,
                fixture.otherInterest
            )
            expectEqual(recruitingAfter.nilState, recruitingBefore.nilState)
        }

        test("a gap-closing high-priority NIL proposal beats a legal visit") {
            var fixture = try m3NILPolicyFixture(
                seed: 93_017,
                nilPriority: SharedRules.ratingRange.upperBound,
                relationshipPriority: SharedRules.ratingRange.lowerBound,
                closesAtTarget: true,
                contactPointsRemaining: CollegeRules.weeklyRecruitingContactPoints
            )
            expect(fixture.currentScore < CollegeRules.minimumCommitmentScore)
            expect(fixture.targetScore >= CollegeRules.minimumCommitmentScore)
            let recruitingBefore = fixture.state.college.programmes[fixture.programmeID]!
            let decision = RecruitingDecisionPolicy.investmentDecision(
                programmeID: fixture.programmeID,
                in: fixture.state
            )
            guard let decision,
                  case let .setNILAllocation(amount) = decision.request.action else {
                expect(false, "a gap-closing high-priority NIL proposal lost to renewable work")
                return
            }
            expect(amount <= fixture.portfolioTarget)
            let transition = try CollegeRecruitingSystem.apply(
                decision.request,
                in: fixture.state
            )
            fixture.state.college = transition.college
            fixture.state.scouting = transition.scouting
            let recruitingAfter = fixture.state.college.programmes[fixture.programmeID]!
            let scoreAfter = RecruitingFitSystem.evaluate(
                programmeID: fixture.programmeID,
                prospectID: fixture.prospectID,
                in: fixture.state
            )!.total
            expect(scoreAfter >= CollegeRules.minimumCommitmentScore)
            expectEqual(recruitingAfter.contactPointsRemaining, recruitingBefore.contactPointsRemaining)
            expectEqual(
                recruitingAfter.relationships[fixture.prospectID]?.interest,
                recruitingBefore.relationships[fixture.prospectID]?.interest
            )
            expectEqual(
                recruitingAfter.nilState.remaining,
                recruitingBefore.nilState.remaining - amount
            )
            if amount >= CollegeRules.nilInterestPointsPerUnit {
                let prior = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: fixture.programmeID,
                        prospectID: fixture.prospectID,
                        action: .setNILAllocation(
                            amount: amount - CollegeRules.nilInterestPointsPerUnit
                        )
                    ),
                    in: fixture.state
                )
                var priorState = fixture.state
                priorState.college = prior.college
                expect(
                    RecruitingFitSystem.evaluate(
                        programmeID: fixture.programmeID,
                        prospectID: fixture.prospectID,
                        in: priorState
                    )!.total < CollegeRules.minimumCommitmentScore
                )
            }
        }

        test("partial NIL remains available when renewable work is unavailable") {
            var fixture = try m3NILPolicyFixture(
                seed: 93_018,
                nilPriority: 40,
                relationshipPriority: 40,
                closesAtTarget: false,
                contactPointsRemaining: 0
            )
            let recruitingBefore = fixture.state.college.programmes[fixture.programmeID]!
            let decision = RecruitingDecisionPolicy.investmentDecision(
                programmeID: fixture.programmeID,
                in: fixture.state
            )
            guard let decision,
                  case let .setNILAllocation(amount) = decision.request.action else {
                expect(false, "an unavailable renewable action blocked bounded partial NIL")
                return
            }
            expectEqual(amount, fixture.portfolioTarget)
            let transition = try CollegeRecruitingSystem.apply(
                decision.request,
                in: fixture.state
            )
            fixture.state.college = transition.college
            fixture.state.scouting = transition.scouting
            let recruitingAfter = fixture.state.college.programmes[fixture.programmeID]!
            expectEqual(recruitingAfter.contactPointsRemaining, 0)
            expectEqual(
                recruitingAfter.relationships[fixture.prospectID]?.interest,
                recruitingBefore.relationships[fixture.prospectID]?.interest
            )
            expectEqual(
                recruitingAfter.nilState.remaining,
                recruitingBefore.nilState.remaining - amount
            )
            expect(
                RecruitingFitSystem.evaluate(
                    programmeID: fixture.programmeID,
                    prospectID: fixture.prospectID,
                    in: fixture.state
                )!.total < CollegeRules.minimumCommitmentScore
            )
            expectEqual(
                RecruitingDecisionPolicy.investmentDecision(
                    programmeID: fixture.programmeID,
                    in: fixture.state
                ),
                nil,
                "the partial portfolio total compounded on a later policy call"
            )
        }

        test("cross-board policy selects a closing NIL proposal over a higher-score partial one") {
            var state = GameState.bootstrap(seed: 93_019)
            let programmeID = state.programmes.ids[0]
            let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!
            let fitSnapshot = RecruitingFitSnapshot(in: state)
            let candidates = state.prospects.values.filter {
                capacity.canReserve(position: $0.position)
            }.sorted { $0.id.uuidString < $1.id.uuidString }
            let partialPriority = SharedRules.ratingRange.lowerBound
            let closingPriority = SharedRules.ratingRange.upperBound
            let relationshipPriority = SharedRules.ratingRange.lowerBound
            let partialTarget = m3PortfolioTarget(
                nilPriority: partialPriority,
                programmeID: programmeID,
                in: state
            )
            let closingTarget = m3PortfolioTarget(
                nilPriority: closingPriority,
                programmeID: programmeID,
                in: state
            )
            let partialGain = m3NILScoreGain(
                allocation: partialTarget,
                priority: partialPriority
            )
            let closingGain = m3NILScoreGain(
                allocation: closingTarget,
                priority: closingPriority
            )
            var selected: (
                partial: Prospect,
                partialInterest: Int,
                partialScore: Int,
                closing: Prospect,
                closingInterest: Int,
                closingScore: Int
            )?
            for partial in candidates.prefix(40) {
                let partialBase = fitSnapshot.evaluate(
                    programmeID: programmeID,
                    prospectID: partial.id
                )!.total
                guard let partialChoice = m3RelationshipInterest(
                    baseScore: partialBase,
                    relationshipPriority: relationshipPriority,
                    nilGain: partialGain,
                    closesAtTarget: false
                ) else { continue }
                for closing in candidates.prefix(40) where closing.id != partial.id {
                    let closingBase = fitSnapshot.evaluate(
                        programmeID: programmeID,
                        prospectID: closing.id
                    )!.total
                    guard let closingChoice = m3RelationshipInterest(
                        baseScore: closingBase,
                        relationshipPriority: relationshipPriority,
                        nilGain: closingGain,
                        closesAtTarget: true,
                        below: partialChoice.score
                    ) else { continue }
                    selected = (
                        partial,
                        partialChoice.interest,
                        partialChoice.score,
                        closing,
                        closingChoice.interest,
                        closingChoice.score
                    )
                    break
                }
                if selected != nil { break }
            }
            guard let selected else {
                expect(false, "fixture found no partial/closing score inversion")
                return
            }
            state.prospects.insert(m3Prospect(
                selected.partial,
                nilPriority: partialPriority,
                relationshipPriority: relationshipPriority
            ))
            state.prospects.insert(m3Prospect(
                selected.closing,
                nilPriority: closingPriority,
                relationshipPriority: relationshipPriority
            ))
            let existing = state.college.programmes[programmeID]!
            state = m3ReplacingRecruitingProgramme(
                ProgrammeRecruitingState(
                    programmeID: programmeID,
                    boardIDs: [selected.partial.id, selected.closing.id],
                    relationships: [
                        selected.partial.id: ProgrammeProspectRelationship(
                            prospectID: selected.partial.id,
                            interest: selected.partialInterest,
                            scholarshipOffered: true
                        ),
                        selected.closing.id: ProgrammeProspectRelationship(
                            prospectID: selected.closing.id,
                            interest: selected.closingInterest,
                            scholarshipOffered: true
                        ),
                    ],
                    scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                    contactPointsRemaining: CollegeRules.weeklyRecruitingContactPoints,
                    nilState: existing.nilState
                ),
                in: state
            )
            let midpoint = (
                SharedRules.ratingRange.lowerBound + SharedRules.ratingRange.upperBound
            ) / 2
            state.scouting = ScoutingState(observationsByObserver: [
                programmeID: [
                    selected.partial.id: ProspectObservation(
                        prospectID: selected.partial.id,
                        estimatedAttributes: [.schemeFit: Rating(midpoint)],
                        estimatedPotential: selected.partial.potential,
                        confidence: 100,
                        lastUpdated: state.calendar,
                        evidenceCount: 1
                    ),
                    selected.closing.id: ProspectObservation(
                        prospectID: selected.closing.id,
                        estimatedAttributes: [.schemeFit: Rating(midpoint)],
                        estimatedPotential: selected.closing.potential,
                        confidence: 100,
                        lastUpdated: state.calendar,
                        evidenceCount: 1
                    ),
                ],
            ])
            let actualPartialScore = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: selected.partial.id,
                in: state
            )!.total
            let actualClosingScore = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: selected.closing.id,
                in: state
            )!.total
            expect(actualPartialScore > actualClosingScore)
            expect(actualPartialScore + partialGain < CollegeRules.minimumCommitmentScore)
            expect(actualClosingScore + closingGain >= CollegeRules.minimumCommitmentScore)

            let decision = RecruitingDecisionPolicy.investmentDecision(
                programmeID: programmeID,
                in: state
            )
            expectEqual(decision?.request.prospectID, selected.closing.id)
            guard case .setNILAllocation = decision?.request.action else {
                expect(false, "the closing cross-board candidate did not receive NIL")
                return
            }
        }

        test("the final-week terminal market signs an AI threshold crossing in causal order") {
            let fixture = try m3FinalWeekClosingFixture(seed: 93_020)
            expect(fixture.currentScore < CollegeRules.minimumCommitmentScore)
            expect(fixture.targetScore >= CollegeRules.minimumCommitmentScore)
            guard case .setNILAllocation = RecruitingDecisionPolicy.investmentDecision(
                programmeID: fixture.programmeID,
                in: fixture.state
            )?.request.action else {
                expect(false, "final-week fixture did not expose its closing AI action")
                return
            }

            var preAI = fixture.state
            let health = PeopleLifecycleSystem.processHealth(
                at: preAI.calendar,
                in: preAI
            )
            preAI.people = health.people
            let development = DevelopmentSystem.practice(at: preAI.calendar, in: preAI)
            preAI.players = development.players
            preAI.people = development.people
            preAI.scouting = ScoutingSystem.process(
                at: preAI.calendar,
                in: preAI
            ).scouting
            let openingMarket = CollegeRecruitingMarketSystem.process(
                at: preAI.calendar,
                in: preAI
            )
            preAI.college = openingMarket.college
            expect(!openingMarket.commitments.contains {
                $0.prospectID == fixture.prospectID
            })
            let finalAI = try CollegeRecruitingAISystem.process(in: preAI)
            expect(finalAI.decisions.contains {
                $0.request.programmeID == fixture.programmeID
                    && $0.request.prospectID == fixture.prospectID
            })
            preAI.college = finalAI.college
            preAI.scouting = finalAI.scouting
            expect(
                RecruitingFitSystem.evaluate(
                    programmeID: fixture.programmeID,
                    prospectID: fixture.prospectID,
                    in: preAI
                )!.total >= CollegeRules.minimumCommitmentScore
            )
            let directTerminalMarket = CollegeRecruitingMarketSystem.process(
                at: preAI.calendar,
                in: preAI
            )
            expect(directTerminalMarket.commitments.contains {
                $0.programmeID == fixture.programmeID
                    && $0.prospectID == fixture.prospectID
            })

            let terminalTransition = try WorldScheduler.advanceWeek(fixture.state)
            // Signing is the week-21 rollover boundary, so carry the week-20 commitment into the
            // signing-week transition before asserting resolution and player intake.
            let signingTransition = try WorldScheduler.advanceWeek(terminalTransition.state)
            let emittedEvents = terminalTransition.emittedEvents + signingTransition.emittedEvents
            let relevantEvents = emittedEvents.enumerated().compactMap {
                index, event -> (Int, DomainEventPayload)? in
                let prospectID: UUID?
                switch event.payload {
                case let .recruitingInteraction(_, value, _, _, _): prospectID = value
                case let .prospectCommitted(value, _): prospectID = value
                case let .commitmentResolved(value, _, _): prospectID = value
                case let .playerJoined(value, _, _): prospectID = value
                default:
                    prospectID = nil
                }
                return prospectID == fixture.prospectID ? (index, event.payload) : nil
            }
            let interactionIndex = relevantEvents.first { _, payload in
                if case .recruitingInteraction = payload { return true }
                return false
            }?.0
            let commitmentIndices = relevantEvents.compactMap { index, payload in
                if case .prospectCommitted = payload { return index }
                return nil
            }
            let resolutionIndex = relevantEvents.first { _, payload in
                if case .commitmentResolved(_, _, .signed) = payload { return true }
                return false
            }?.0
            let joinIndex = relevantEvents.first { _, payload in
                if case .playerJoined(_, _, .recruitedScholarship) = payload { return true }
                return false
            }?.0

            expectEqual(commitmentIndices.count, 1)
            expect(interactionIndex != nil)
            expect(resolutionIndex != nil)
            expect(joinIndex != nil)
            if let interactionIndex,
               let commitmentIndex = commitmentIndices.first,
               let resolutionIndex,
               let joinIndex {
                expect(interactionIndex < commitmentIndex)
                expect(commitmentIndex < resolutionIndex)
                expect(resolutionIndex < joinIndex)
            }
            let origin = signingTransition.state.people.playerCareers[fixture.prospectID]?
                .recruitingOrigin
            expectEqual(origin?.programmeID, fixture.programmeID)
            expectEqual(origin?.commitmentHistory.count, 1)
        }

        test("a reusable fit snapshot matches scalar evaluation without mutating state") {
            let state = GameState.bootstrap(seed: 93_014)
            let beforeBytes = try JSONEncoder.stable().encode(state)
            let fitSnapshot = RecruitingFitSnapshot(in: state)
            let programmeIDs = Array(state.programmes.ids.prefix(3))
            let prospectIDs = Array(state.prospects.ids.prefix(4))

            for programmeID in programmeIDs {
                for prospectID in prospectIDs {
                    expectEqual(
                        fitSnapshot.evaluate(
                            programmeID: programmeID,
                            prospectID: prospectID
                        ),
                        RecruitingFitSystem.evaluate(
                            programmeID: programmeID,
                            prospectID: prospectID,
                            in: state
                        )
                    )
                }
            }
            expectEqual(try JSONEncoder.stable().encode(state), beforeBytes)
        }

        test("an explicit capacity snapshot preserves the NIL investment decision") {
            var state = GameState.bootstrap(seed: 93_015)
            let programmeID = state.programmes.ids[0]
            guard let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            ), let prospectID = state.prospects.values.first(where: {
                capacity.canReserve(position: $0.position)
            })?.id else {
                expect(false, "fixture has no legal recruiting capacity")
                return
            }
            for action in [
                RecruitingAction.addToBoard,
                .evaluate(points: CollegeRules.aiEvaluationContactPoints),
                .offerScholarship,
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            let activeRecruiting = state.college.programmes[programmeID]!
            state = m3ReplacingRecruitingProgramme(
                ProgrammeRecruitingState(
                    programmeID: programmeID,
                    boardIDs: activeRecruiting.boardIDs,
                    relationships: activeRecruiting.relationships,
                    scholarshipPlayerIDs: activeRecruiting.scholarshipPlayerIDs,
                    contactPointsRemaining: 0,
                    nilState: activeRecruiting.nilState
                ),
                in: state
            )
            let liveCapacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!
            let scalar = RecruitingDecisionPolicy.investmentDecision(
                programmeID: programmeID,
                in: state
            )
            let snapshotted = RecruitingDecisionPolicy.investmentDecision(
                programmeID: programmeID,
                in: state,
                capacitySnapshot: liveCapacity
            )

            expectEqual(snapshotted, scalar)
            guard case .setNILAllocation = snapshotted?.request.action else {
                expect(false, "fixture did not exercise NIL targeting")
                return
            }
        }

        test("first-week targeting distributes pursuits across the available market") {
            let state = GameState.bootstrap(seed: 93_002)
            let transition = try CollegeRecruitingAISystem.process(in: state)
            let pursuitCounts = Dictionary(grouping:
                transition.college.programmes.values.flatMap(\.boardIDs),
                by: { $0 }
            ).mapValues(\.count)
            let saturation = max(
                1,
                (state.programmes.count * CollegeRules.recruitingBoardLimit
                    + state.prospects.count - 1) / state.prospects.count
            )
            let boardSlots = pursuitCounts.values.reduce(0, +)

            expectEqual(
                boardSlots,
                state.programmes.count * CollegeRules.aiWeeklyBoardGrowth
            )
            expect((pursuitCounts.values.max() ?? 0) <= saturation)
            expect(pursuitCounts.count >= boardSlots / saturation)
        }

        test("later board growth searches every need before exceeding pursuit saturation") {
            var state = GameState.bootstrap(seed: 93_005)
            for _ in 0..<6 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            let pursuitCounts = Dictionary(grouping:
                state.college.programmes.values.flatMap(\.boardIDs),
                by: { $0 }
            ).mapValues(\.count)
            let saturation = max(
                1,
                (state.programmes.count * CollegeRules.recruitingBoardLimit
                    + state.prospects.count - 1) / state.prospects.count
            )

            expect((pursuitCounts.values.max() ?? 0) <= saturation)
            expect(pursuitCounts.count * saturation
                >= pursuitCounts.values.reduce(0, +))
        }

        test("NIL explanation is monotonic and respects the prospect's NIL priority") {
            let baseline = GameState.bootstrap(seed: 93_006)
            let programmeID = baseline.programmes.ids[0]
            let prospectID = baseline.prospects.ids[0]
            guard let original = baseline.prospects[prospectID] else {
                expect(false, "fixture prospect is missing")
                return
            }

            func nilComponent(priority: Int, allocation: Int) throws -> Int {
                var state = baseline
                var priorities = original.priorities
                priorities[.nilOpportunity] = Rating(priority)
                state.prospects.insert(Prospect(
                    id: original.id,
                    firstName: original.firstName,
                    lastName: original.lastName,
                    position: original.position,
                    age: original.age,
                    originCityID: original.originCityID,
                    attributes: original.attributes,
                    potential: original.potential,
                    traits: original.traits,
                    priorities: priorities
                ))
                var transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: .addToBoard
                    ),
                    in: state
                )
                state.college = transition.college
                if allocation > 0 {
                    transition = try CollegeRecruitingSystem.apply(
                        RecruitingActionRequest(
                            programmeID: programmeID,
                            prospectID: prospectID,
                            action: .setNILAllocation(amount: allocation)
                        ),
                        in: state
                    )
                    state.college = transition.college
                }
                return RecruitingFitSystem.evaluate(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    in: state
                )?.value(for: .nilOpportunity) ?? -1
            }

            let zero = try nilComponent(priority: 99, allocation: 0)
            let oneHundred = try nilComponent(priority: 99, allocation: 100)
            let fiveHundredLowPriority = try nilComponent(priority: 40, allocation: 500)
            let fiveHundredHighPriority = try nilComponent(priority: 99, allocation: 500)

            expectEqual(zero, 0)
            expect(oneHundred > zero)
            expect(fiveHundredHighPriority > oneHundred)
            expect(fiveHundredHighPriority > fiveHundredLowPriority)
        }

        test("NIL allocation changes are path-independent and preserve non-NIL interest") {
            let baseline = GameState.bootstrap(seed: 93_008)
            let programmeID = baseline.programmes.ids[0]
            let prospectID = baseline.prospects.ids[0]

            func allocatedState(_ amounts: [Int], from source: GameState) throws -> GameState {
                var state = source
                let addition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: .addToBoard
                    ),
                    in: state
                )
                state.college = addition.college
                state.scouting = addition.scouting
                for amount in amounts {
                    let transition = try CollegeRecruitingSystem.apply(
                        RecruitingActionRequest(
                            programmeID: programmeID,
                            prospectID: prospectID,
                            action: .setNILAllocation(amount: amount)
                        ),
                        in: state
                    )
                    state.college = transition.college
                    state.scouting = transition.scouting
                }
                return state
            }

            let added = try allocatedState([], from: baseline)
            let initialInterest = added.college.programmes[programmeID]!
                .relationships[prospectID]!.interest
            let direct = try allocatedState([100], from: baseline)
            let split = try allocatedState([50, 100], from: baseline)
            expectEqual(
                direct.college.programmes[programmeID]?.relationships[prospectID]?.interest,
                initialInterest
            )
            expectEqual(
                split.college.programmes[programmeID]?.relationships[prospectID]?.interest,
                initialInterest
            )
            expectEqual(
                direct.college.programmes[programmeID]?.relationships[prospectID]?.interest,
                split.college.programmes[programmeID]?.relationships[prospectID]?.interest
            )

            var saturated = baseline
            let existing = saturated.college.programmes[programmeID]!
            var programmeStates = saturated.college.programmes
            programmeStates[programmeID] = ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: [prospectID],
                relationships: [
                    prospectID: ProgrammeProspectRelationship(
                        prospectID: prospectID,
                        interest: 98
                    ),
                ],
                scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                contactPointsRemaining: existing.contactPointsRemaining,
                nilState: existing.nilState
            )
            saturated.college = CollegeState(
                recruitingSeason: saturated.college.recruitingSeason,
                portal: saturated.college.portal,
                phase: saturated.college.phase,
                programmes: programmeStates,
                prospectRecruitment: saturated.college.prospectRecruitment,
                archivedProspects: saturated.college.archivedProspects,
                redshirtPlans: saturated.college.redshirtPlans
            )
            for amount in [500, 0] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: .setNILAllocation(amount: amount)
                    ),
                    in: saturated
                )
                saturated.college = transition.college
            }
            expectEqual(
                saturated.college.programmes[programmeID]?.relationships[prospectID]?.interest,
                98
            )
        }

        test("the smallest NIL score unit remains a named cause at minimum priority") {
            var state = GameState.bootstrap(seed: 93_012)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            let original = state.prospects[prospectID]!
            var priorities = original.priorities
            priorities[.nilOpportunity] = Rating(SharedRules.ratingRange.lowerBound)
            state.prospects.insert(Prospect(
                id: original.id,
                firstName: original.firstName,
                lastName: original.lastName,
                position: original.position,
                age: original.age,
                originCityID: original.originCityID,
                attributes: original.attributes,
                potential: original.potential,
                traits: original.traits,
                priorities: priorities
            ))
            let addition = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .addToBoard
                ),
                in: state
            )
            state.college = addition.college
            let before = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )!
            let allocation = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    action: .setNILAllocation(amount: CollegeRules.nilInterestPointsPerUnit)
                ),
                in: state
            )
            state.college = allocation.college
            let after = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )!

            expectEqual(after.value(for: .nilOpportunity), 0)
            expectEqual(after.nilAllocationAdjustment, 1)
            expectEqual(after.total, before.total + 1)
        }

        test("policy scores are exactly reconstructible and stored pitch reasons stay current") {
            var state = GameState.bootstrap(seed: 93_009)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            for action in [
                RecruitingAction.addToBoard,
                .setNILAllocation(amount: 500),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            let live = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )!
            expectEqual(
                state.college.programmes[programmeID]?.relationships[prospectID]?
                    .lastExplanation,
                live.components
            )

            let decisions = try CollegeRecruitingAISystem.process(
                in: GameState.bootstrap(seed: 93_010)
            ).decisions
            expect(decisions.allSatisfy { $0.score == $0.explanation.total })
        }

        test("target selection exposes scouting knowledge as a named score cause") {
            var state = GameState.bootstrap(seed: 93_013)
            let programmeID = state.programmes.ids[0]
            let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!
            let prospect = state.prospects.values.first {
                capacity.canReserve(position: $0.position)
            }!
            for prospectID in state.prospects.ids where prospectID != prospect.id {
                _ = state.prospects.remove(prospectID)
            }
            let observation = ProspectObservation(
                prospectID: prospect.id,
                estimatedAttributes: [.schemeFit: Rating(99)],
                estimatedPotential: Rating(99),
                confidence: 100,
                lastUpdated: state.calendar,
                evidenceCount: 1
            )
            state.scouting = ScoutingState(observationsByObserver: [
                programmeID: [prospect.id: observation],
            ])

            let decision = RecruitingDecisionPolicy.targetDecision(
                programmeID: programmeID,
                in: state
            )
            expectEqual(decision?.request.prospectID, prospect.id)
            expectEqual(
                decision?.explanation.knowledgeAdjustment,
                SharedRules.ratingRange.upperBound - SharedRules.ratingRange.lowerBound
            )
            expectEqual(decision?.score, decision?.explanation.total)
        }

        test("an authorized challenger never spends on a visit or contact with zero score gain") {
            var state = GameState.bootstrap(seed: 93_011)
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            state.league.week = state.calendar.week
            let prospectID = state.prospects.ids[0]
            let programmeIDs = Array(state.programmes.ids.prefix(2))
            var programmeStates = state.college.programmes
            for programmeID in programmeIDs {
                let existing = programmeStates[programmeID]!
                programmeStates[programmeID] = ProgrammeRecruitingState(
                    programmeID: programmeID,
                    boardIDs: [prospectID],
                    relationships: [
                        prospectID: ProgrammeProspectRelationship(
                            prospectID: prospectID,
                            interest: 100,
                            scholarshipOffered: true
                        ),
                    ],
                    scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                    contactPointsRemaining: existing.contactPointsRemaining,
                    nilState: ProgrammeNILState(
                        programmeID: programmeID,
                        season: existing.nilState.season,
                        annualBudget: existing.nilState.annualBudget,
                        rosterAllocations: existing.nilState.rosterAllocations,
                        recruitingReservations: [prospectID: 500]
                    )
                )
            }
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: state.college.phase,
                programmes: programmeStates,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: state.college.redshirtPlans
            )
            let market = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
            guard let commitment = market.commitments.first,
                  let runnerUpID = commitment.runnerUpProgrammeID else {
                expect(false, "fixture produced no authorized runner-up")
                return
            }
            state.college = market.college
            expect(state.scouting.queueEvaluation(
                observerID: runnerUpID,
                prospectID: prospectID,
                effort: CollegeRules.aiEvaluationContactPoints
            ))

            expectEqual(
                RecruitingDecisionPolicy.investmentDecision(
                    programmeID: runnerUpID,
                    in: state
                ),
                nil
            )
        }

        test("NIL investment uses a score-gap portfolio share instead of a fixed promise") {
            var state = GameState.bootstrap(seed: 93_007)
            let programmeID = state.programmes.ids.min { lhs, rhs in
                let lhsRecruiting = state.college.programmes[lhs]
                let rhsRecruiting = state.college.programmes[rhs]
                let lhsCapacity = CollegeCommitmentCapacitySystem.capacity(
                    programmeID: lhs,
                    in: state,
                    college: state.college
                )?.openReservations ?? 1
                let rhsCapacity = CollegeCommitmentCapacitySystem.capacity(
                    programmeID: rhs,
                    in: state,
                    college: state.college
                )?.openReservations ?? 1
                let lhsShare = (lhsRecruiting?.nilState.annualBudget ?? 0)
                    / max(1, lhsCapacity)
                let rhsShare = (rhsRecruiting?.nilState.annualBudget ?? 0)
                    / max(1, rhsCapacity)
                if lhsShare != rhsShare { return lhsShare < rhsShare }
                return lhs.uuidString < rhs.uuidString
            }!
            let fitSnapshot = RecruitingFitSnapshot(in: state)
            let prospectID = state.prospects.ids.min { lhs, rhs in
                let lhsScore = fitSnapshot.evaluate(
                    programmeID: programmeID,
                    prospectID: lhs
                )?.total ?? Int.max
                let rhsScore = fitSnapshot.evaluate(
                    programmeID: programmeID,
                    prospectID: rhs
                )?.total ?? Int.max
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                return lhs.uuidString < rhs.uuidString
            }!
            guard let original = state.prospects[prospectID] else {
                expect(false, "fixture prospect is missing")
                return
            }
            var priorities = original.priorities
            priorities[.nilOpportunity] = Rating(40)
            state.prospects.insert(Prospect(
                id: original.id,
                firstName: original.firstName,
                lastName: original.lastName,
                position: original.position,
                age: original.age,
                originCityID: original.originCityID,
                attributes: original.attributes,
                potential: original.potential,
                traits: original.traits,
                priorities: priorities
            ))

            for action in [
                RecruitingAction.addToBoard,
                .evaluate(points: CollegeRules.aiEvaluationContactPoints),
                .offerScholarship,
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }
            let offeredScore = RecruitingFitSystem.evaluate(
                programmeID: programmeID,
                prospectID: prospectID,
                in: state
            )!.total
            expect(offeredScore < CollegeRules.minimumCommitmentScore)

            let activeRecruiting = state.college.programmes[programmeID]!
            state = m3ReplacingRecruitingProgramme(
                ProgrammeRecruitingState(
                    programmeID: programmeID,
                    boardIDs: activeRecruiting.boardIDs,
                    relationships: activeRecruiting.relationships,
                    scholarshipPlayerIDs: activeRecruiting.scholarshipPlayerIDs,
                    contactPointsRemaining: 0,
                    nilState: activeRecruiting.nilState
                ),
                in: state
            )

            guard let decision = RecruitingDecisionPolicy.investmentDecision(
                programmeID: programmeID,
                in: state
            ), case let .setNILAllocation(amount) = decision.request.action,
                  let recruiting = state.college.programmes[programmeID],
                  let capacity = CollegeCommitmentCapacitySystem.capacity(
                    programmeID: programmeID,
                    in: state,
                    college: state.college
                  ) else {
                expect(false, "sub-threshold offer received no NIL portfolio decision")
                return
            }
            let priorityMidpoint = (
                SharedRules.ratingRange.lowerBound
                    + SharedRules.ratingRange.upperBound
            ) / 2
            let fairShare = recruiting.nilState.remaining
                / max(1, capacity.openReservations)
            let priorityShare = fairShare * 40 / priorityMidpoint
            let roundedPortfolioCeiling = min(
                CollegeRules.aiInitialNILAllocation,
                max(100, (priorityShare + 99) / 100 * 100)
            )

            expect((100...CollegeRules.aiInitialNILAllocation).contains(amount))
            expect(amount <= roundedPortfolioCeiling)
            expect(amount <= (CollegeRules.minimumCommitmentScore - offeredScore) * 100)

            let remainingBefore = recruiting.nilState.remaining
            let interestBefore = recruiting.relationships[prospectID]?.interest
            let allocation = try CollegeRecruitingSystem.apply(decision.request, in: state)
            state.college = allocation.college
            state.scouting = allocation.scouting
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .recruitingReservations[prospectID],
                amount
            )
            expectEqual(
                state.college.programmes[programmeID]?.nilState.remaining,
                remainingBefore - amount
            )
            expectEqual(
                state.college.programmes[programmeID]?.relationships[prospectID]?.interest,
                interestBefore
            )

            let nextDecision = RecruitingDecisionPolicy.investmentDecision(
                programmeID: programmeID,
                in: state
            )
            expectEqual(
                nextDecision,
                nil,
                "the portfolio target was reapplied as another NIL increment"
            )
            expectEqual(
                state.college.programmes[programmeID]?.nilState
                    .recruitingReservations[prospectID],
                amount
            )
        }

        test("commitment-season policy works a mature pursuit while a score gap remains") {
            var state = GameState.bootstrap(seed: 93_004)
            for _ in 0..<CollegeRules.minimumCommitmentWeek - 1 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar.week, CollegeRules.minimumCommitmentWeek)

            let transition = try CollegeRecruitingAISystem.process(in: state)
            var resultingState = state
            resultingState.college = transition.college
            resultingState.scouting = transition.scouting

            for programmeID in state.programmes.ids {
                let decisions = transition.decisions.filter {
                    $0.request.programmeID == programmeID
                }
                let matureWork = decisions.filter { decision in
                    switch decision.request.action {
                    case .scheduleVisit, .contact, .setNILAllocation:
                        return true
                    default:
                        return false
                    }
                }.count
                let unworkedMatureNeed = resultingState.college.programmes[programmeID]?
                    .boardIDs.contains { prospectID in
                        guard resultingState.college.prospectRecruitment[prospectID]?.phase
                                == .available,
                              let relationship = resultingState.college
                                .programmes[programmeID]?.relationships[prospectID],
                              relationship.scholarshipOffered,
                              resultingState.scouting.observation(
                                observerID: programmeID,
                                prospectID: prospectID
                              ) != nil,
                              let explanation = RecruitingFitSystem.evaluate(
                                programmeID: programmeID,
                                prospectID: prospectID,
                                in: resultingState
                              ) else { return false }
                        return explanation.total < CollegeRules.minimumCommitmentScore
                    } ?? false
                expect(matureWork > 0 || !unworkedMatureNeed)
            }
        }

        test("a current-week runner-up gets one bounded path to a real flip") {
            var state = GameState.bootstrap(seed: 93_003)
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            let prospectID = state.prospects.ids[0]
            let programmesByFit = Dictionary(grouping: state.programmes.ids) {
                RecruitingFitSystem.evaluate(
                    programmeID: $0,
                    prospectID: prospectID,
                    in: state
                )?.total ?? Int.min
            }
            guard let contenderIDs = programmesByFit
                .filter({ $0.key > Int.min && $0.value.count >= 2 })
                .max(by: { $0.key < $1.key })?.value
                .prefix(2),
                  contenderIDs.count == 2 else {
                expect(false, "fixture found no equally rated contenders")
                return
            }

            func apply(
                _ action: RecruitingAction,
                programmeID: UUID,
                to state: inout GameState
            ) throws {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: prospectID,
                        action: action
                    ),
                    in: state
                )
                state.college = transition.college
                state.scouting = transition.scouting
            }

            for programmeID in contenderIDs {
                for action in [
                    RecruitingAction.addToBoard,
                    .evaluate(points: CollegeRules.aiEvaluationContactPoints),
                    .contact(points: CollegeRules.aiEvaluationContactPoints),
                    .offerScholarship,
                    .setNILAllocation(amount: CollegeRules.aiInitialNILAllocation),
                ] {
                    try apply(action, programmeID: programmeID, to: &state)
                }
            }
            let finalWeekFixture = state
            let initialMarket = CollegeRecruitingMarketSystem.process(
                at: state.calendar,
                in: state
            )
            guard let commitment = initialMarket.commitments.first,
                  commitment.prospectID == prospectID,
                  let runnerUpID = commitment.runnerUpProgrammeID else {
                expect(false, "fixture produced no two-programme commitment")
                return
            }
            state.college = initialMarket.college

            let sameWeekAI = try CollegeRecruitingAISystem.process(in: state)
            expect(sameWeekAI.college.programmes[runnerUpID]?
                .relationships[prospectID] != nil)
            let runnerUpInvestments = sameWeekAI.decisions.filter { decision in
                guard decision.request.programmeID == runnerUpID,
                      decision.request.prospectID == prospectID else { return false }
                switch decision.request.action {
                case .evaluate, .contact, .scheduleVisit, .offerScholarship,
                     .setNILAllocation:
                    return true
                case .addToBoard, .withdraw:
                    return false
                }
            }
            expect((1...3).contains(runnerUpInvestments.count))
            let investmentCounts = Dictionary(grouping: sameWeekAI.decisions.filter {
                switch $0.request.action {
                case .evaluate, .contact, .scheduleVisit, .offerScholarship,
                     .setNILAllocation:
                    return true
                case .addToBoard, .withdraw:
                    return false
                }
            }, by: { decision in
                "\(decision.request.programmeID.uuidString)|\(decision.request.prospectID.uuidString)"
            }).mapValues(\.count)
            expect((investmentCounts.values.max() ?? 0) <= 3)

            do {
                _ = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: commitment.programmeID,
                        prospectID: prospectID,
                        action: .contact(points: CollegeRules.aiEvaluationContactPoints)
                    ),
                    in: state
                )
                expect(false, "the commitment winner received challenger authority")
            } catch let error as RecruitingActionError {
                expectEqual(error, .prospectUnavailable)
            }

            var expiredState = state
            expiredState.calendar = CalendarState(
                season: state.calendar.season,
                week: state.calendar.week + 1
            )
            let expiredAI = try CollegeRecruitingAISystem.process(in: expiredState)
            expectEqual(expiredAI.college.programmes[runnerUpID]?
                .relationships[prospectID], nil)
            expectEqual(expiredAI.college.programmes[runnerUpID]?.nilState
                .recruitingReservations[prospectID], nil)
            expect(expiredAI.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: runnerUpID,
                    prospectID: prospectID,
                    action: .withdraw,
                    resourceCost: -CollegeRules.aiInitialNILAllocation,
                    interestAfter: 0
                ) = payload { return true }
                return false
            })

            var challengerState = state
            for expectedAction in [
                RecruitingInteractionKind.visit,
                .contact,
            ] {
                guard let decision = RecruitingDecisionPolicy.investmentDecision(
                    programmeID: runnerUpID,
                    in: challengerState
                ) else {
                    expect(false, "runner-up received no challenge investment")
                    return
                }
                let transition = try CollegeRecruitingSystem.apply(
                    decision.request,
                    in: challengerState
                )
                challengerState.college = transition.college
                challengerState.scouting = transition.scouting
                expect(transition.eventPayloads.contains { payload in
                    if case let .recruitingInteraction(_, _, action, _, _) = payload {
                        return action == expectedAction
                    }
                    return false
                })
            }
            challengerState.calendar = CalendarState(
                season: state.calendar.season,
                week: state.calendar.week + 1
            )
            let flipMarket = CollegeRecruitingMarketSystem.process(
                at: challengerState.calendar,
                in: challengerState
            )
            guard let flip = flipMarket.commitments.first else {
                expect(false, "improved runner-up did not flip the commitment")
                return
            }
            expectEqual(flip.prospectID, prospectID)
            expectEqual(flip.programmeID, runnerUpID)
            expect(flip.context.previousWinner != nil)
            expectEqual(
                flipMarket.college.prospectRecruitment[prospectID]?
                    .commitmentHistory.count,
                2
            )

            expectEqual(
                RecruitingDecisionPolicy.investmentDecision(
                    programmeID: runnerUpID,
                    in: challengerState
                ),
                nil,
                "the challenge window outlived its commitment week"
            )

            var finalWeekState = finalWeekFixture
            finalWeekState.calendar = CalendarState(
                season: finalWeekState.calendar.season,
                week: SharedRules.inSeasonWeeks
            )
            let finalWeekMarket = CollegeRecruitingMarketSystem.process(
                at: finalWeekState.calendar,
                in: finalWeekState
            )
            guard let finalCommitment = finalWeekMarket.commitments.first,
                  let finalRunnerUpID = finalCommitment.runnerUpProgrammeID else {
                expect(false, "final-week fixture produced no runner-up")
                return
            }
            finalWeekState.college = finalWeekMarket.college
            let finalWeekAI = try CollegeRecruitingAISystem.process(in: finalWeekState)
            expectEqual(finalWeekAI.college.programmes[finalRunnerUpID]?
                .relationships[prospectID], nil)
            expectEqual(finalWeekAI.college.programmes[finalRunnerUpID]?.nilState
                .recruitingReservations[prospectID], nil)
            expect(finalWeekAI.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: finalRunnerUpID,
                    prospectID: prospectID,
                    action: .withdraw,
                    resourceCost: -CollegeRules.aiInitialNILAllocation,
                    interestAfter: 0
                ) = payload { return true }
                return false
            })
            expect(!finalWeekAI.decisions.contains { decision in
                guard decision.request.programmeID == finalRunnerUpID,
                      decision.request.prospectID == prospectID else { return false }
                switch decision.request.action {
                case .evaluate, .contact, .scheduleVisit, .offerScholarship,
                     .setNILAllocation:
                    return true
                case .addToBoard, .withdraw:
                    return false
                }
            })
            finalWeekState.college = finalWeekAI.college
            finalWeekState.scouting = finalWeekAI.scouting
            let sameWeekTerminalMarket = CollegeRecruitingMarketSystem.process(
                at: finalWeekState.calendar,
                in: finalWeekState
            )
            expect(!sameWeekTerminalMarket.commitments.contains {
                $0.prospectID == prospectID
            })
            expectEqual(
                sameWeekTerminalMarket.college.prospectRecruitment[prospectID]?
                    .commitmentHistory.count,
                1
            )
        }
      }

        if ProcessInfo.processInfo.environment["M3_RECRUITING_UNIT_ONLY"] == nil {
          test("one generated season measures deterministic recruiting and rollover") {
            let seed: UInt64 = 93_001
            let first = try runM3RecruitingCalibration(seed: seed)
            if seasonOnly {
                print(String(
                    format: "M3 isolated first season complete: %.3fs",
                    first.runtimeSeconds
                ))
            }
            let second = try runM3RecruitingCalibration(seed: seed)
            if seasonOnly {
                print(String(
                    format: "M3 isolated repeat season complete: %.3fs",
                    second.runtimeSeconds
                ))
            }
            let encoder = JSONEncoder.stable()
            let firstBytes = try encoder.encode(first.state)
            let secondBytes = try encoder.encode(second.state)
            let firstEnvelope = try SaveEnvelope.encode(first.state)
            let decoded = try JSONDecoder().decode(GameState.self, from: firstBytes)
            let roundTripBytes = try encoder.encode(decoded)
            let integrity = WorldIntegrity.check(first.state)
            let targetValues = first.projectedTargets.values.sorted()
            let fillPercentages = first.fillRates.map { Int(($0 * 100).rounded()) }
            let classAverageValues = first.classOverallAverages.map {
                Int($0.rounded())
            }
            let totalProjectedTarget = targetValues.reduce(0, +)
            let totalSigned = first.signedClassSizes.reduce(0, +)
            let aggregateFillPercentage = totalProjectedTarget == 0
                ? 0
                : totalSigned * 100 / totalProjectedTarget
            let nonemptyClasses = first.signedClassSizes.filter { $0 > 0 }.count
            let nonzeroNILPromises = first.nilPromises.filter { $0 > 0 }.count

            print("M3 recruiting calibration seed: \(seed)")
            print(String(format: "runtime first/repeat: %.3fs / %.3fs",
                         first.runtimeSeconds, second.runtimeSeconds))
            print("projected class target range/median: \(m3Range(targetValues)) / \(m3Median(targetValues))")
            print("signed class range/median/mean: \(m3Range(first.signedClassSizes)) / \(m3Median(first.signedClassSizes)) / \(String(format: "%.2f", m3Average(first.signedClassSizes)))")
            print("fill rate range/median/mean: \(m3Range(fillPercentages))% / \(m3Median(fillPercentages))% / \(String(format: "%.2f", m3Average(fillPercentages)))%")
            print("aggregate fill/nonempty classes: \(aggregateFillPercentage)% / \(nonemptyClasses) of \(first.state.programmes.count)")
            print("signed overall range/median/mean: \(m3Range(first.signedOverallRatings)) / \(m3Median(first.signedOverallRatings)) / \(String(format: "%.2f", m3Average(first.signedOverallRatings)))")
            print("programme class-average range: \(m3Range(classAverageValues))")
            print("NIL promise range/median/mean: \(m3Range(first.nilPromises)) / \(m3Median(first.nilPromises)) / \(String(format: "%.2f", m3Average(first.nilPromises)))")
            print("signed/released/walk-ons: \(first.signedResolutions) / \(first.releasedResolutions) / \(first.walkOnJoins)")
            print("commitment/recruiting-interaction events: \(first.commitmentEvents) / \(first.recruitingInteractionEvents)")
            print("history total/hot/archive/limit: \(first.state.history.totalCount) / \(first.state.history.recent.count) / \(first.state.history.archivedCount) / \(first.state.history.retentionLimit)")
            print("save bytes: \(firstEnvelope.count) durable / \(firstBytes.count) JSON")
            print("position-covered/legal rosters: \(first.positionCoveredProgrammes) / \(first.legalRosterProgrammes) of \(first.state.programmes.count)")
            print("weekly: w board/unique/max-mult offered/qualified/qualified-prospects score(min/med/max) stages(E/O/N[fnd/exh;gap/priority]/R/M) open-programmes/open-slots/reserved challengers/flip-ready commits/flips")
            for week in first.weeklyDiagnostics {
                print("w\(week.week) \(week.boardSlots)/\(week.uniqueBoardProspects)/\(week.maximumBoardMultiplicity) \(week.offeredRelationships)/\(week.qualifiedRelationships)/\(week.qualifiedProspects) \(week.offeredScoreMinimum)/\(week.offeredScoreMedian)/\(week.offeredScoreMaximum) \(week.needsEvaluation)/\(week.needsOffer)/\(week.needsNIL)[\(week.fundableNILNeeds)/\(week.exhaustedNILNeeds);\(week.nilNeedScoreGapMedian)/\(week.nilNeedPriorityMedian)]/\(week.needsRelationshipWork)/\(week.maturePursuits) \(week.programmesWithOpenCapacity)/\(week.totalOpenCapacity)/\(week.activeReservations) \(week.retainedChallengers)/\(week.flipEligibleChallengers) \(week.newCommitments)/\(week.flips)")
            }

            expectEqual(first.state.calendar.season, 1)
            expectEqual(firstBytes, secondBytes)
            expectEqual(firstBytes, roundTripBytes)
            expect(integrity.isValid, integrity.issues.map(\.description).joined(separator: ", "))
            expectEqual(first.state.history.totalCount, first.emittedEventCount + 1)
            expect(first.state.history.recent.count <= first.state.history.retentionLimit)
            expectEqual(
                first.state.history.archivedCount + first.state.history.recent.count,
                first.state.history.totalCount
            )
            expectEqual(first.recruitedScholarshipJoins, first.signedResolutions)
            expectEqual(first.recruitedScholarshipJoins, first.signedOverallRatings.count)
            expectEqual(first.nilPromises.count, first.signedOverallRatings.count)
            expect(first.commitmentEvents
                >= first.signedResolutions + first.releasedResolutions)
            expectEqual(first.positionCoveredProgrammes, first.state.programmes.count)
            expectEqual(first.legalRosterProgrammes, first.state.programmes.count)

            // Broad plausibility bounds come from the measurement pass for this generated world.
            // They intentionally describe distributions, not an exact seed fingerprint.
            expect(targetValues.allSatisfy {
                (1...CollegeRules.initialSigningsPerClass).contains($0)
            })
            expect(first.signedClassSizes.allSatisfy {
                (0...CollegeRules.initialSigningsPerClass).contains($0)
            })
            for (index, programmeID) in first.state.programmes.ids.enumerated() {
                expect(first.signedClassSizes[index]
                    <= (first.projectedTargets[programmeID] ?? 0))
            }
            expect(nonemptyClasses >= first.state.programmes.count * 3 / 4)
            expectIn(Double(aggregateFillPercentage), 50...100)
            expect(m3Median(fillPercentages) >= 50)
            expect(first.fillRates.allSatisfy { (0...1).contains($0) })
            expectIn(m3Average(first.signedOverallRatings), 45...65)
            expect(classAverageValues.allSatisfy { (40...75).contains($0) })
            expect(first.nilPromises.allSatisfy {
                (0...CollegeRules.aiInitialNILAllocation).contains($0)
            })
            expectIn(m3Average(first.nilPromises), 250...500)
            expect(nonzeroNILPromises * 100 >= first.nilPromises.count * 60)
            expect(first.walkOnJoins <= first.recruitedScholarshipJoins)
            expect(first.recruitingInteractionEvents > first.commitmentEvents)
            expect(first.recruitingInteractionEvents
                <= first.state.programmes.count * SharedRules.inSeasonWeeks * (
                    CollegeRules.aiWeeklyInvestmentActionLimit
                        + 2 * CollegeRules.recruitingBoardLimit
                ))
            expectEqual(first.state.history.recent.count, first.state.history.retentionLimit)
            expect(first.state.history.totalCount < 250_000)
            expectEqual(try SaveEnvelope.decode(GameState.self, from: firstEnvelope), first.state)
            expect(firstEnvelope.count < 8_000_000)
          }
        }
    }
}
