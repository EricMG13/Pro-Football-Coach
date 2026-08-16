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

public struct TacticalPracticeReceipt: Codable, Sendable, Equatable {
    public let organisationID: UUID
    public let calendar: CalendarState
    public let effects: TacticalPracticeEffects

    public init(organisationID: UUID, calendar: CalendarState,
                effects: TacticalPracticeEffects) {
        self.organisationID = organisationID
        self.calendar = calendar
        self.effects = effects
    }
}

/// Work that must be authored before a user-controlled fixture can be advanced.
///
/// This is intentionally a small rules-owned enum rather than a second agenda authority: the
/// records already stored by `TacticalState` remain the source of truth, and this enum only names
/// the missing records at the current calendar.
public enum TacticalPreparationRequirement: String, Codable, Sendable, Equatable, CaseIterable {
    case gamePlan
    case practicePlan
}

public struct TacticalState: Codable, Sendable, Equatable {
    public static let maximumPlans = 256
    public static let maximumScoutingSnapshots = 256
    public static let maximumOpponentObservations = 512
    public static let maximumReviews = 1_024

    public private(set) var calendar: CalendarState
    public private(set) var plansByOrganisation: [UUID: TacticalPlanRecord]
    public private(set) var practicePlansByOrganisation: [UUID: TacticalPracticePlanRecord]
    public private(set) var personnelPlansByOrganisation: [UUID: PersonnelPlan]
    public private(set) var practiceReceiptsByOrganisation: [UUID: TacticalPracticeReceipt]
    public private(set) var opponentScouting: [UUID: OpponentScoutingSnapshot]
    public private(set) var opponentObservations: [String: OpponentObservation]
    public private(set) var reviews: [TacticalGamePlanReview]

    public init(
        calendar: CalendarState = CalendarState(),
        plansByOrganisation: [UUID: TacticalPlanRecord] = [:],
        practicePlansByOrganisation: [UUID: TacticalPracticePlanRecord] = [:],
        personnelPlansByOrganisation: [UUID: PersonnelPlan] = [:],
        practiceReceiptsByOrganisation: [UUID: TacticalPracticeReceipt] = [:],
        opponentScouting: [UUID: OpponentScoutingSnapshot] = [:],
        opponentObservations: [String: OpponentObservation] = [:],
        reviews: [TacticalGamePlanReview] = []
    ) {
        precondition(Self.isValid(
            calendar: calendar,
            plansByOrganisation: plansByOrganisation,
            practicePlansByOrganisation: practicePlansByOrganisation,
            personnelPlansByOrganisation: personnelPlansByOrganisation,
            practiceReceiptsByOrganisation: practiceReceiptsByOrganisation,
            opponentScouting: opponentScouting,
            opponentObservations: opponentObservations,
            reviews: reviews
        ))
        self.calendar = calendar
        self.plansByOrganisation = plansByOrganisation
        self.practicePlansByOrganisation = practicePlansByOrganisation
        self.personnelPlansByOrganisation = personnelPlansByOrganisation
        self.practiceReceiptsByOrganisation = practiceReceiptsByOrganisation
        self.opponentScouting = opponentScouting
        self.opponentObservations = opponentObservations
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
        let personnelPlans = try container.decodeIfPresent(
            [UUID: PersonnelPlan].self,
            forKey: .personnelPlansByOrganisation
        ) ?? [:]
        let practiceReceipts = try container.decodeIfPresent(
            [UUID: TacticalPracticeReceipt].self,
            forKey: .practiceReceiptsByOrganisation
        ) ?? [:]
        let scouting = try container.decode(
            [UUID: OpponentScoutingSnapshot].self,
            forKey: .opponentScouting
        )
        let observations = try container.decodeIfPresent(
            [String: OpponentObservation].self,
            forKey: .opponentObservations
        ) ?? [:]
        let reviews = try container.decode([TacticalGamePlanReview].self, forKey: .reviews)
        guard Self.isValid(
            calendar: calendar,
            plansByOrganisation: plans,
            practicePlansByOrganisation: practicePlans,
            personnelPlansByOrganisation: personnelPlans,
            practiceReceiptsByOrganisation: practiceReceipts,
            opponentScouting: scouting,
            opponentObservations: observations,
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
        self.personnelPlansByOrganisation = personnelPlans
        self.practiceReceiptsByOrganisation = practiceReceipts
        self.opponentScouting = scouting
        self.opponentObservations = observations
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

    public func observation(
        for observerID: UUID,
        opponentID: UUID,
        at calendar: CalendarState
    ) -> OpponentObservation? {
        let value = opponentObservations[Self.observationKey(observerID, opponentID)]
        return value.flatMap { $0.isCurrent(at: calendar) ? $0 : nil }
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

    public func missingPreparation(
        for organisationID: UUID,
        at calendar: CalendarState
    ) -> [TacticalPreparationRequirement] {
        guard calendar == self.calendar else {
            return TacticalPreparationRequirement.allCases
        }
        var missing: [TacticalPreparationRequirement] = []
        if plan(for: organisationID, at: calendar) == nil {
            missing.append(.gamePlan)
        }
        if practicePlan(for: organisationID, at: calendar) == nil {
            missing.append(.practicePlan)
        }
        return missing
    }

    public func personnelPlan(
        for organisationID: UUID,
        at calendar: CalendarState
    ) -> PersonnelPlan? {
        guard let plan = personnelPlansByOrganisation[organisationID], plan.calendar == calendar else {
            return nil
        }
        return plan
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
              practiceReceiptsByOrganisation[organisationID]?.calendar != calendar,
              practicePlansByOrganisation[organisationID] != nil
                  || practicePlansByOrganisation.count < Self.maximumPlans else { return false }
        practicePlansByOrganisation[organisationID] = TacticalPracticePlanRecord(
            calendar: calendar,
            plan: plan
        )
        return true
    }

    @discardableResult
    public mutating func setPersonnelPlan(_ plan: PersonnelPlan) -> Bool {
        guard plan.calendar == calendar,
              personnelPlansByOrganisation[plan.organisationID] != nil
                  || personnelPlansByOrganisation.count < Self.maximumPlans else { return false }
        personnelPlansByOrganisation[plan.organisationID] = plan
        return true
    }

    /// Consumes the current week's plan once. An absent plan is an explicit balanced delegation,
    /// so every organisation gets one bounded receipt and retries cannot apply it twice.
    public mutating func consumePracticePlan(
        for organisationID: UUID,
        at calendar: CalendarState
    ) -> TacticalPracticeEffects? {
        guard calendar == self.calendar,
              practiceReceiptsByOrganisation[organisationID]?.calendar != calendar else {
            return nil
        }
        let plan = practicePlansByOrganisation[organisationID]?.plan ?? .balanced
        let effects = plan.effects
        practiceReceiptsByOrganisation[organisationID] = TacticalPracticeReceipt(
            organisationID: organisationID, calendar: calendar, effects: effects
        )
        return effects
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
    public mutating func recordObservation(_ observation: OpponentObservation) -> Bool {
        guard observation.observedThrough == calendar,
              opponentObservations[Self.observationKey(observation.observerID,
                                                       observation.opponentID)] != nil
                  || opponentObservations.count < Self.maximumOpponentObservations else {
            return false
        }
        let key = Self.observationKey(observation.observerID, observation.opponentID)
        guard let prior = opponentObservations[key] else {
            opponentObservations[key] = observation
            return true
        }

        // Keep the observer's bounded history instead of replacing it with the latest box score.
        // Source IDs are authoritative for sample count, so duplicate fixtures cannot inflate
        // confidence and rates remain scoped to games this observer could know.
        let sources = Array(Set(prior.sourceGameIDs + observation.sourceGameIDs))
            .sorted { $0.uuidString < $1.uuidString }
            .suffix(OpponentObservation.maximumSourceGames)
        let sampleSize = min(
            sources.count,
            max(0, prior.sampleSize) + max(0, observation.sampleSize)
        )
        let priorWeight = max(0, prior.sampleSize)
        let newWeight = max(0, observation.sampleSize)
        let totalWeight = priorWeight + newWeight
        let weightedPassRate: Int
        let weightedTurnoverRate: Int
        if totalWeight == 0 {
            weightedPassRate = observation.passRate
            weightedTurnoverRate = observation.turnoverRate
        } else {
            weightedPassRate = (prior.passRate * priorWeight
                + observation.passRate * newWeight) / totalWeight
            weightedTurnoverRate = (prior.turnoverRate * priorWeight
                + observation.turnoverRate * newWeight) / totalWeight
        }
        opponentObservations[key] = OpponentObservation(
            observerID: observation.observerID,
            opponentID: observation.opponentID,
            observedThrough: Self.maxCalendar(
                prior.observedThrough,
                observation.observedThrough
            ),
            sourceGameIDs: Array(sources),
            confidence: min(100, sampleSize * 25),
            sampleSize: sampleSize,
            passRate: weightedPassRate,
            turnoverRate: weightedTurnoverRate
        )
        return true
    }

    @discardableResult
    public mutating func recordReview(_ review: TacticalGamePlanReview) -> Bool {
        guard reviews.count < Self.maximumReviews else { return false }
        var lowerBound = 0
        var upperBound = reviews.count
        while lowerBound < upperBound {
            let midpoint = (lowerBound + upperBound) / 2
            if Self.reviewComesBefore(reviews[midpoint], review) {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        if lowerBound < reviews.count {
            let existing = reviews[lowerBound]
            guard existing.calendar != review.calendar
                    || existing.organisationID != review.organisationID
                    || existing.opponentID != review.opponentID else { return false }
        }
        reviews.insert(review, at: lowerBound)
        return true
    }

    public mutating func advance(to calendar: CalendarState) {
        guard Self.isLater(calendar, than: self.calendar) else { return }
        self.calendar = calendar
        plansByOrganisation.removeAll(keepingCapacity: true)
        practicePlansByOrganisation.removeAll(keepingCapacity: true)
        personnelPlansByOrganisation.removeAll(keepingCapacity: true)
    }

    public mutating func prepare(for calendar: CalendarState) {
        guard self.calendar != calendar else { return }
        self.calendar = calendar
        plansByOrganisation.removeAll(keepingCapacity: true)
        practicePlansByOrganisation.removeAll(keepingCapacity: true)
        personnelPlansByOrganisation.removeAll(keepingCapacity: true)
    }

    private static func isValid(
        calendar: CalendarState,
        plansByOrganisation: [UUID: TacticalPlanRecord],
        practicePlansByOrganisation: [UUID: TacticalPracticePlanRecord],
        personnelPlansByOrganisation: [UUID: PersonnelPlan],
        practiceReceiptsByOrganisation: [UUID: TacticalPracticeReceipt],
        opponentScouting: [UUID: OpponentScoutingSnapshot],
        opponentObservations: [String: OpponentObservation],
        reviews: [TacticalGamePlanReview]
    ) -> Bool {
            plansByOrganisation.count <= maximumPlans
            && practicePlansByOrganisation.count <= maximumPlans
            && personnelPlansByOrganisation.count <= maximumPlans
            && practiceReceiptsByOrganisation.count <= maximumPlans
            && opponentScouting.count <= maximumScoutingSnapshots
            && opponentObservations.count <= maximumOpponentObservations
            && reviews.count <= maximumReviews
            && plansByOrganisation.values.allSatisfy { $0.calendar == calendar }
            && practicePlansByOrganisation.values.allSatisfy { $0.calendar == calendar }
            && personnelPlansByOrganisation.allSatisfy {
                $0.key == $0.value.organisationID && $0.value.calendar == calendar
            }
            && practiceReceiptsByOrganisation.allSatisfy {
                $0.key == $0.value.organisationID
                    && isOnOrBefore($0.value.calendar, calendar)
            }
            && opponentScouting.allSatisfy { $0.key == $0.value.teamID }
            && opponentObservations.allSatisfy {
                $0.key == observationKey($0.value.observerID, $0.value.opponentID)
                    && isOnOrBefore($0.value.observedThrough, calendar)
            }
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
        reviews.sorted(by: reviewComesBefore)
    }

    private static func reviewComesBefore(
        _ lhs: TacticalGamePlanReview,
        _ rhs: TacticalGamePlanReview
    ) -> Bool {
        if lhs.calendar.season != rhs.calendar.season {
            return lhs.calendar.season < rhs.calendar.season
        }
        if lhs.calendar.week != rhs.calendar.week {
            return lhs.calendar.week < rhs.calendar.week
        }
        if lhs.organisationID != rhs.organisationID {
            return lhs.organisationID.uuidString < rhs.organisationID.uuidString
        }
        return lhs.opponentID.uuidString < rhs.opponentID.uuidString
    }

    private static func isLater(_ lhs: CalendarState, than rhs: CalendarState) -> Bool {
        lhs.season > rhs.season || (lhs.season == rhs.season && lhs.week > rhs.week)
    }

    private static func isOnOrBefore(_ lhs: CalendarState, _ rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week <= rhs.week)
    }

    private static func maxCalendar(_ lhs: CalendarState, _ rhs: CalendarState) -> CalendarState {
        isOnOrBefore(lhs, rhs) ? rhs : lhs
    }

    private static func observationKey(_ observerID: UUID, _ opponentID: UUID) -> String {
        "\(observerID.uuidString)|\(opponentID.uuidString)"
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
        if let stored = tactical.plan(for: organisationID, at: calendar) {
            return stored
        }
        let observation = tactical.observation(
            for: organisationID, opponentID: opponentID, at: calendar
        )
        let plan = TacticalCoordinatorSystem.plan(
            for: observation,
            at: calendar,
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
        let homeSnapshot = OpponentScoutingSnapshot.from(
            teamID: game.awayID,
            observedThrough: calendar,
            statistics: result.awayStatistics
        )
        let awaySnapshot = OpponentScoutingSnapshot.from(
            teamID: game.homeID,
            observedThrough: calendar,
            statistics: result.homeStatistics
        )
        _ = tactical.recordScouting(homeSnapshot)
        _ = tactical.recordScouting(awaySnapshot)
        _ = tactical.recordObservation(OpponentObservation(
            observerID: game.homeID,
            snapshot: homeSnapshot,
            sourceGameIDs: [game.id],
            confidence: 25,
            sampleSize: 1
        ))
        _ = tactical.recordObservation(OpponentObservation(
            observerID: game.awayID,
            snapshot: awaySnapshot,
            sourceGameIDs: [game.id],
            confidence: 25,
            sampleSize: 1
        ))
        if let homePlan = tactical.plan(for: game.homeID, at: calendar) {
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
        if let awayPlan = tactical.plan(for: game.awayID, at: calendar) {
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
