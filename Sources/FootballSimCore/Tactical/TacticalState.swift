import Foundation

public struct TacticalPlanRecord: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let plan: TacticalPlan

    public init(calendar: CalendarState, plan: TacticalPlan) {
        self.calendar = calendar
        self.plan = plan
    }
}

public struct TacticalGamePlanReview: Codable, Sendable, Equatable {
    public let calendar: CalendarState
    public let organisationID: UUID
    public let opponentID: UUID
    public let plan: TacticalPlan
    public let pointsFor: Int
    public let pointsAgainst: Int
    public let opponentPassRate: Int
    public let opponentTurnoverRate: Int

    public init(
        calendar: CalendarState,
        organisationID: UUID,
        opponentID: UUID,
        plan: TacticalPlan,
        pointsFor: Int,
        pointsAgainst: Int,
        opponentPassRate: Int,
        opponentTurnoverRate: Int
    ) {
        precondition(pointsFor >= 0 && pointsAgainst >= 0)
        precondition((0...100).contains(opponentPassRate))
        precondition((0...100).contains(opponentTurnoverRate))
        self.calendar = calendar
        self.organisationID = organisationID
        self.opponentID = opponentID
        self.plan = plan
        self.pointsFor = pointsFor
        self.pointsAgainst = pointsAgainst
        self.opponentPassRate = opponentPassRate
        self.opponentTurnoverRate = opponentTurnoverRate
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pointsFor = try container.decode(Int.self, forKey: .pointsFor)
        let pointsAgainst = try container.decode(Int.self, forKey: .pointsAgainst)
        let passRate = try container.decode(Int.self, forKey: .opponentPassRate)
        let turnoverRate = try container.decode(Int.self, forKey: .opponentTurnoverRate)
        guard pointsFor >= 0, pointsAgainst >= 0,
              (0...100).contains(passRate),
              (0...100).contains(turnoverRate) else {
            throw DecodingError.dataCorruptedError(
                forKey: .pointsFor,
                in: container,
                debugDescription: "Tactical review values are outside their bounds."
            )
        }
        self.init(
            calendar: try container.decode(CalendarState.self, forKey: .calendar),
            organisationID: try container.decode(UUID.self, forKey: .organisationID),
            opponentID: try container.decode(UUID.self, forKey: .opponentID),
            plan: try container.decode(TacticalPlan.self, forKey: .plan),
            pointsFor: pointsFor,
            pointsAgainst: pointsAgainst,
            opponentPassRate: passRate,
            opponentTurnoverRate: turnoverRate
        )
    }
}

public struct TacticalState: Codable, Sendable, Equatable {
    public static let maximumPlans = 256
    public static let maximumScoutingSnapshots = 256
    public static let maximumReviews = 1_024

    public private(set) var calendar: CalendarState
    public private(set) var plansByOrganisation: [UUID: TacticalPlanRecord]
    public private(set) var practicePlansByOrganisation: [UUID: TacticalPracticePlanRecord]
    public private(set) var opponentScouting: [UUID: OpponentScoutingSnapshot]
    public private(set) var reviews: [TacticalGamePlanReview]

    public init(
        calendar: CalendarState = CalendarState(),
        plansByOrganisation: [UUID: TacticalPlanRecord] = [:],
        practicePlansByOrganisation: [UUID: TacticalPracticePlanRecord] = [:],
        opponentScouting: [UUID: OpponentScoutingSnapshot] = [:],
        reviews: [TacticalGamePlanReview] = []
    ) {
        precondition(Self.isValid(
            calendar: calendar,
            plansByOrganisation: plansByOrganisation,
            practicePlansByOrganisation: practicePlansByOrganisation,
            opponentScouting: opponentScouting,
            reviews: reviews
        ))
        self.calendar = calendar
        self.plansByOrganisation = plansByOrganisation
        self.practicePlansByOrganisation = practicePlansByOrganisation
        self.opponentScouting = opponentScouting
        self.reviews = Self.sortedReviews(reviews)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let calendar = try container.decode(CalendarState.self, forKey: .calendar)
        let plans = try container.decode(
            [UUID: TacticalPlanRecord].self,
            forKey: .plansByOrganisation
        )
        let practicePlans = try container.decode(
            [UUID: TacticalPracticePlanRecord].self,
            forKey: .practicePlansByOrganisation
        )
        let scouting = try container.decode(
            [UUID: OpponentScoutingSnapshot].self,
            forKey: .opponentScouting
        )
        let reviews = try container.decode([TacticalGamePlanReview].self, forKey: .reviews)
        guard Self.isValid(
            calendar: calendar,
            plansByOrganisation: plans,
            practicePlansByOrganisation: practicePlans,
            opponentScouting: scouting,
            reviews: reviews
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .calendar,
                in: container,
                debugDescription: "Tactical state exceeds bounds or has mismatched identifiers."
            )
        }
        self.calendar = calendar
        self.plansByOrganisation = plans
        self.practicePlansByOrganisation = practicePlans
        self.opponentScouting = scouting
        self.reviews = Self.sortedReviews(reviews)
    }

    public func plan(for organisationID: UUID, at calendar: CalendarState) -> TacticalPlan? {
        guard let record = plansByOrganisation[organisationID], record.calendar == calendar else {
            return nil
        }
        return record.plan
    }

    public func scouting(for opponentID: UUID) -> OpponentScoutingSnapshot? {
        opponentScouting[opponentID]
    }

    public func practicePlan(
        for organisationID: UUID,
        at calendar: CalendarState
    ) -> TacticalPracticePlan? {
        guard let record = practicePlansByOrganisation[organisationID], record.calendar == calendar else {
            return nil
        }
        return record.plan
    }

    @discardableResult
    public mutating func setPlan(
        _ plan: TacticalPlan,
        for organisationID: UUID,
        at calendar: CalendarState
    ) -> Bool {
        guard calendar == self.calendar,
              plansByOrganisation[organisationID] != nil
                  || plansByOrganisation.count < Self.maximumPlans else { return false }
        plansByOrganisation[organisationID] = TacticalPlanRecord(calendar: calendar, plan: plan)
        return true
    }

    @discardableResult
    public mutating func setPracticePlan(
        _ plan: TacticalPracticePlan,
        for organisationID: UUID,
        at calendar: CalendarState
    ) -> Bool {
        guard calendar == self.calendar,
              practicePlansByOrganisation[organisationID] != nil
                  || practicePlansByOrganisation.count < Self.maximumPlans else { return false }
        practicePlansByOrganisation[organisationID] = TacticalPracticePlanRecord(
            calendar: calendar,
            plan: plan
        )
        return true
    }

    @discardableResult
    public mutating func recordScouting(_ snapshot: OpponentScoutingSnapshot) -> Bool {
        guard snapshot.observedThrough == calendar,
              opponentScouting[snapshot.teamID] != nil
                  || opponentScouting.count < Self.maximumScoutingSnapshots else { return false }
        opponentScouting[snapshot.teamID] = snapshot
        return true
    }

    @discardableResult
    public mutating func recordReview(_ review: TacticalGamePlanReview) -> Bool {
        let duplicate = reviews.contains {
            $0.calendar == review.calendar
                && $0.organisationID == review.organisationID
                && $0.opponentID == review.opponentID
        }
        guard !duplicate, reviews.count < Self.maximumReviews else { return false }
        reviews.append(review)
        reviews = Self.sortedReviews(reviews)
        return true
    }

    public mutating func advance(to calendar: CalendarState) {
        guard Self.isLater(calendar, than: self.calendar) else { return }
        self.calendar = calendar
        plansByOrganisation.removeAll(keepingCapacity: true)
        practicePlansByOrganisation.removeAll(keepingCapacity: true)
    }

    public mutating func prepare(for calendar: CalendarState) {
        guard self.calendar != calendar else { return }
        self.calendar = calendar
        plansByOrganisation.removeAll(keepingCapacity: true)
        practicePlansByOrganisation.removeAll(keepingCapacity: true)
    }

    private static func isValid(
        calendar: CalendarState,
        plansByOrganisation: [UUID: TacticalPlanRecord],
        practicePlansByOrganisation: [UUID: TacticalPracticePlanRecord],
        opponentScouting: [UUID: OpponentScoutingSnapshot],
        reviews: [TacticalGamePlanReview]
    ) -> Bool {
            plansByOrganisation.count <= maximumPlans
            && practicePlansByOrganisation.count <= maximumPlans
            && opponentScouting.count <= maximumScoutingSnapshots
            && reviews.count <= maximumReviews
            && plansByOrganisation.values.allSatisfy { $0.calendar == calendar }
            && practicePlansByOrganisation.values.allSatisfy { $0.calendar == calendar }
            && opponentScouting.allSatisfy { $0.key == $0.value.teamID }
            && reviews.allSatisfy {
                $0.pointsFor >= 0
                    && $0.pointsAgainst >= 0
                    && (0...100).contains($0.opponentPassRate)
                    && (0...100).contains($0.opponentTurnoverRate)
            }
    }

    private static func sortedReviews(
        _ reviews: [TacticalGamePlanReview]
    ) -> [TacticalGamePlanReview] {
        reviews.sorted {
            if $0.calendar.season != $1.calendar.season {
                return $0.calendar.season < $1.calendar.season
            }
            if $0.calendar.week != $1.calendar.week {
                return $0.calendar.week < $1.calendar.week
            }
            if $0.organisationID != $1.organisationID {
                return $0.organisationID.uuidString < $1.organisationID.uuidString
            }
            return $0.opponentID.uuidString < $1.opponentID.uuidString
        }
    }

    private static func isLater(_ lhs: CalendarState, than rhs: CalendarState) -> Bool {
        lhs.season > rhs.season || (lhs.season == rhs.season && lhs.week > rhs.week)
    }
}

public enum TacticalPlanSystem {
    public static func coordinatorRating(
        for organisationID: UUID,
        in state: GameState
    ) -> Rating {
        let staffIDs: [UUID]
        if let programme = state.programmes[organisationID] {
            staffIDs = programme.staffIDs
        } else {
            staffIDs = state.proTeams[organisationID]?.staffIDs ?? []
        }
        let ratings: [Int] = staffIDs.compactMap { staffID in
            guard let staff = state.staff[staffID],
                  StaffRole.coordinators.contains(staff.role) else { return nil }
            return staff.rating(.gamePlanning).value
        }
        guard !ratings.isEmpty else { return Rating(SharedRules.ratingRange.lowerBound) }
        return Rating(ratings.reduce(0, +) / ratings.count)
    }

    public static func plan(
        for organisationID: UUID,
        against opponentID: UUID,
        at calendar: CalendarState,
        in state: GameState,
        tactical: inout TacticalState
    ) -> TacticalPlan {
        let statistics = state.competition.teamStatistics[opponentID] ?? TeamSeasonStatistics()
        let snapshot = OpponentScoutingSnapshot.from(
            teamID: opponentID,
            observedThrough: calendar,
            statistics: statistics
        )
        _ = tactical.recordScouting(snapshot)
        if let stored = tactical.plan(for: organisationID, at: calendar) {
            return stored
        }
        let plan = TacticalCoordinatorSystem.plan(
            for: snapshot,
            coordinatorRating: coordinatorRating(for: organisationID, in: state)
        )
        _ = tactical.setPlan(plan, for: organisationID, at: calendar)
        return plan
    }

    public static func recordReviews(
        for game: ScheduledGame,
        result: GameSummary,
        at calendar: CalendarState,
        in tactical: inout TacticalState
    ) {
        let homeSnapshot = tactical.scouting(for: game.awayID)
        let awaySnapshot = tactical.scouting(for: game.homeID)
        if let homeSnapshot, let homePlan = tactical.plan(for: game.homeID, at: calendar) {
            _ = tactical.recordReview(TacticalGamePlanReview(
                calendar: calendar,
                organisationID: game.homeID,
                opponentID: game.awayID,
                plan: homePlan,
                pointsFor: result.homeScore,
                pointsAgainst: result.awayScore,
                opponentPassRate: homeSnapshot.passRate,
                opponentTurnoverRate: homeSnapshot.turnoverRate
            ))
        }
        if let awaySnapshot, let awayPlan = tactical.plan(for: game.awayID, at: calendar) {
            _ = tactical.recordReview(TacticalGamePlanReview(
                calendar: calendar,
                organisationID: game.awayID,
                opponentID: game.homeID,
                plan: awayPlan,
                pointsFor: result.awayScore,
                pointsAgainst: result.homeScore,
                opponentPassRate: awaySnapshot.passRate,
                opponentTurnoverRate: awaySnapshot.turnoverRate
            ))
        }
    }
}
