import Foundation

public struct ProgrammeCommitmentCapacity: Sendable, Equatable {
    public let programmeID: UUID
    public let projectedReturningPlayerIDs: [UUID]
    public let projectedReturningScholarshipPlayerIDs: [UUID]
    public let projectedRosterOpenings: Int
    public let projectedScholarshipOpenings: Int
    public let maximumReservations: Int
    public let activeReservations: Int
    public let projectedRosterCounts: [Position: Int]
    public let reservedPositionCounts: [Position: Int]

    public var openReservations: Int {
        max(0, maximumReservations - activeReservations)
    }

    public var preservesMinimumPositionCoverage: Bool {
        let remainingRosterOpenings = projectedRosterOpenings - activeReservations
        guard remainingRosterOpenings >= 0 else { return false }
        let remainingMinimumOpenings = Position.allCases.reduce(0) { total, position in
            let projected = (projectedRosterCounts[position] ?? 0)
                + (reservedPositionCounts[position] ?? 0)
            let minimum = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
            return total + max(0, minimum - projected)
        }
        return remainingMinimumOpenings <= remainingRosterOpenings
    }

    /// A scholarship commitment may consume a roster opening only when enough remaining roster
    /// openings still exist to supply every minimum playable position through later commitments or
    /// explicit walk-ons.
    public func canReserve(position: Position) -> Bool {
        guard openReservations > 0 else { return false }
        let rosterOpeningsAfterReservation = projectedRosterOpenings
            - activeReservations
            - 1
        guard rosterOpeningsAfterReservation >= 0 else { return false }

        let missingAfterReservation = Position.allCases.reduce(0) { total, candidate in
            let candidateAddition = candidate == position ? 1 : 0
            let projected = (projectedRosterCounts[candidate] ?? 0)
                + (reservedPositionCounts[candidate] ?? 0)
                + candidateAddition
            let minimum = SharedRules.minimumPlayableRosterByPosition[candidate] ?? 0
            return total + max(0, minimum - projected)
        }
        return missingAfterReservation <= rosterOpeningsAfterReservation
    }
}

public enum CollegeCommitmentCapacitySystem {
    /// Pure projected intake capacity. It intentionally assumes no portal movement: current-cycle
    /// high-school commitments are prior claims, while a later portal system may use openings that
    /// remain after signing or are created by actual transfers.
    public static func capacity(
        programmeID: UUID,
        in state: GameState,
        college: CollegeState
    ) -> ProgrammeCommitmentCapacity? {
        guard let programme = state.programmes[programmeID],
              let recruiting = college.programmes[programmeID] else { return nil }

        let returningPlayerIDs = programme.rosterIDs.filter { playerID in
            guard let player = state.players[playerID] else { return false }
            return CollegeEligibilityReturnPolicy.returnsAfterSeason(
                player,
                redshirting: CollegeRedshirtSystem.preservesCompetitionSeason(
                    playerID: playerID,
                    programmeID: programmeID,
                    in: state,
                    college: college
                )
            )
        }
        let returningSet = Set(returningPlayerIDs)
        let returningScholarshipIDs = recruiting.scholarshipPlayerIDs.filter(
            returningSet.contains
        )
        let rosterOpenings = max(0, CollegeRules.rosterLimit - returningPlayerIDs.count)
        let scholarshipOpenings = max(
            0,
            CollegeRules.scholarshipLimit - returningScholarshipIDs.count
        )
        let maximumReservations = min(
            CollegeRules.initialSigningsPerClass,
            rosterOpenings,
            scholarshipOpenings
        )
        let activeRecruitment = college.prospectRecruitment.values.filter {
            $0.programmeID == programmeID && CollegeState.occupiesClassPlace($0)
        }
        let rosterCounts = Dictionary(grouping: returningPlayerIDs.compactMap {
            state.players[$0]?.position
        }, by: { $0 }).mapValues(\.count)
        let reservedCounts = Dictionary(grouping: activeRecruitment.compactMap { recruitment in
            state.prospects[recruitment.prospectID]?.position
                ?? state.players[recruitment.prospectID]?.position
        }, by: { $0 }).mapValues(\.count)

        return ProgrammeCommitmentCapacity(
            programmeID: programmeID,
            projectedReturningPlayerIDs: returningPlayerIDs,
            projectedReturningScholarshipPlayerIDs: returningScholarshipIDs,
            projectedRosterOpenings: rosterOpenings,
            projectedScholarshipOpenings: scholarshipOpenings,
            maximumReservations: maximumReservations,
            activeReservations: activeRecruitment.count,
            projectedRosterCounts: rosterCounts,
            reservedPositionCounts: reservedCounts
        )
    }
}

public enum CollegeCommitmentSystem {
    @discardableResult
    public static func reserve(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        in state: GameState,
        college: inout CollegeState
    ) -> Bool {
        reserve(
            prospectID: prospectID,
            context: context,
            in: state,
            college: &college,
            fitCache: nil
        )
    }

    static func reserve(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        in state: GameState,
        college: inout CollegeState,
        fitCache: RecruitingFitCache?
    ) -> Bool {
        guard let prospect = state.prospects[prospectID],
              context.previousWinner == nil,
              contextIsAuthoritative(
                prospectID: prospectID,
                context: context,
                in: state,
                college: college,
                fitCache: fitCache
              ),
              let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: context.winner.programmeID,
                in: state,
                college: college
              ),
              capacity.canReserve(position: prospect.position) else { return false }
        return college.commit(
            prospectID: prospectID,
            context: context,
            reservationLimit: capacity.maximumReservations
        )
    }

    @discardableResult
    public static func flip(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        in state: GameState,
        college: inout CollegeState
    ) -> Bool {
        flip(
            prospectID: prospectID,
            context: context,
            in: state,
            college: &college,
            fitCache: nil
        )
    }

    static func flip(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        in state: GameState,
        college: inout CollegeState,
        fitCache: RecruitingFitCache?
    ) -> Bool {
        guard let prospect = state.prospects[prospectID],
              let existing = college.prospectRecruitment[prospectID],
              existing.phase == .committed,
              let previous = existing.commitmentContext,
              let previousWinner = context.previousWinner,
              existing.commitmentHistory.count < CollegeRules.commitmentHistoryLimit,
              context.winner.programmeID != previous.winner.programmeID,
              previousWinner.programmeID == previous.winner.programmeID,
              context.winner.score - previousWinner.score
                >= CollegeRules.minimumCommitmentFlipScoreImprovement,
              Self.isLater(context.committedAt, than: previous.committedAt),
              contextIsAuthoritative(
                prospectID: prospectID,
                context: context,
                in: state,
                college: college,
                fitCache: fitCache
              ),
              let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: context.winner.programmeID,
                in: state,
                college: college
              ),
              capacity.canReserve(position: prospect.position) else { return false }
        return college.flip(
            prospectID: prospectID,
            context: context,
            reservationLimit: capacity.maximumReservations
        )
    }

    private static func contextIsAuthoritative(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        in state: GameState,
        college: CollegeState,
        fitCache: RecruitingFitCache?
    ) -> Bool {
        guard context.isValid,
              let prospectPosition = state.prospects[prospectID]?.position,
              context.committedAt.season == college.recruitingSeason,
              context.committedAt.week >= CollegeRules.minimumCommitmentWeek else { return false }
        var workingState = state
        workingState.college = college
        let cache = fitCache ?? RecruitingFitCache(state: workingState)
        return contenderIsAuthoritative(
            prospectID: prospectID,
            contender: context.winner,
            in: workingState,
            fitCache: cache
        ) && (context.runnerUp.map {
            contenderIsAuthoritative(
                prospectID: prospectID,
                contender: $0,
                in: workingState,
                fitCache: cache
            )
        } ?? true) && (context.previousWinner.map {
            contenderIsAuthoritative(
                prospectID: prospectID,
                contender: $0,
                in: workingState,
                fitCache: cache
            )
        } ?? true) && {
            if case let .capacityFallback(blockedPreferred) = context.selectionReason {
                return contenderIsAuthoritative(
                    prospectID: prospectID,
                    contender: blockedPreferred,
                    in: workingState,
                    fitCache: cache
                ) && CollegeCommitmentCapacitySystem.capacity(
                    programmeID: blockedPreferred.programmeID,
                    in: state,
                    college: college
                )?.canReserve(position: prospectPosition) == false
            }
            return true
        }()
    }

    private static func contenderIsAuthoritative(
        prospectID: UUID,
        contender: RecruitingCommitmentContenderContext,
        in state: GameState,
        fitCache: RecruitingFitCache
    ) -> Bool {
        guard let recruiting = state.college.programmes[contender.programmeID],
              let relationship = recruiting.relationships[prospectID],
              relationship.scholarshipOffered,
              let explanation = RecruitingFitSystem.evaluate(
                programmeID: contender.programmeID,
                prospectID: prospectID,
                in: state,
                cache: fitCache
              ) else { return false }
        return contender.relationshipInterest == relationship.interest
            && contender.nilAllocation == recruiting.nilAllocation(for: prospectID)
            && contender.visitScheduled == relationship.visitScheduled
            && contender.explanation == explanation.components
            && contender.score == explanation.total
    }

    private static func isLater(_ lhs: CalendarState, than rhs: CalendarState) -> Bool {
        lhs.season > rhs.season || (lhs.season == rhs.season && lhs.week > rhs.week)
    }
}
