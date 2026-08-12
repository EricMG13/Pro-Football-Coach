import Foundation

public enum CareerStakeholder: String, Codable, Sendable, CaseIterable, Hashable {
    case administration
    case boosters
    case fanbase
    case lockerRoom
}

extension CareerStakeholder: CodingKeyRepresentable {}

public enum CareerJobTier: String, Codable, Sendable, CaseIterable {
    case college
    case professional
}

public enum CareerEmploymentStatus: String, Codable, Sendable, CaseIterable {
    case employed
    case fired
    case seeking
}

public struct CareerJob: Codable, Sendable, Equatable {
    public let organisationID: UUID
    public let tier: CareerJobTier
    public let startedAt: CalendarState

    public init(organisationID: UUID, tier: CareerJobTier, startedAt: CalendarState) {
        self.organisationID = organisationID
        self.tier = tier
        self.startedAt = startedAt
    }
}

public struct CareerJobHistoryEntry: Codable, Sendable, Equatable {
    public let job: CareerJob
    public let endedAt: CalendarState
    public let reason: CareerExitReason

    public init(job: CareerJob, endedAt: CalendarState, reason: CareerExitReason) {
        precondition(!CareerArcState.occurs(endedAt, before: job.startedAt))
        self.job = job
        self.endedAt = endedAt
        self.reason = reason
    }
}

public enum CareerExitReason: String, Codable, Sendable, CaseIterable {
    case fired
    case promoted
    case resigned
}

public struct CareerOpportunity: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let organisationID: UUID
    public let tier: CareerJobTier
    public let offeredAt: CalendarState
    public let expiresAt: CalendarState
    public let prestige: Rating
    public let rationale: CareerOpportunityRationale

    public init(
        id: UUID,
        organisationID: UUID,
        tier: CareerJobTier,
        offeredAt: CalendarState,
        expiresAt: CalendarState,
        prestige: Rating,
        rationale: CareerOpportunityRationale
    ) {
        precondition(!CareerArcState.occurs(expiresAt, before: offeredAt))
        self.id = id
        self.organisationID = organisationID
        self.tier = tier
        self.offeredAt = offeredAt
        self.expiresAt = expiresAt
        self.prestige = prestige
        self.rationale = rationale
    }
}

public enum CareerOpportunityRationale: String, Codable, Sendable, CaseIterable {
    case sustainedCollegeSuccess
    case rivalryWin
    case staffRecommendation
}

public enum CareerArcAction: Codable, Sendable, Equatable {
    case acceptOpportunity(opportunityID: UUID)
    case resign
}

public struct CareerArcState: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case currentJob
        case jobHistory
        case stakeholderSupport
        case opportunities
        case status
    }

    public static let maximumJobHistory = 64
    public static let maximumOpportunities = 32
    public static let supportRange: ClosedRange<Int> = 0...100

    public private(set) var currentJob: CareerJob?
    public private(set) var jobHistory: [CareerJobHistoryEntry]
    public private(set) var stakeholderSupport: [CareerStakeholder: Int]
    public private(set) var opportunities: [CareerOpportunity]
    public private(set) var status: CareerEmploymentStatus

    public init(
        currentJob: CareerJob? = nil,
        jobHistory: [CareerJobHistoryEntry] = [],
        stakeholderSupport: [CareerStakeholder: Int] = Dictionary(
            uniqueKeysWithValues: CareerStakeholder.allCases.map { ($0, 60) }
        ),
        opportunities: [CareerOpportunity] = [],
        status: CareerEmploymentStatus = .seeking
    ) {
        precondition(Self.isValid(
            currentJob: currentJob,
            jobHistory: jobHistory,
            stakeholderSupport: stakeholderSupport,
            opportunities: opportunities,
            status: status
        ), "Career arc state is invalid.")
        self.currentJob = currentJob
        self.jobHistory = jobHistory
        self.stakeholderSupport = stakeholderSupport
        self.opportunities = Self.sorted(opportunities)
        self.status = status
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let currentJob = try container.decodeIfPresent(CareerJob.self, forKey: .currentJob)
        let history = try container.decode([CareerJobHistoryEntry].self, forKey: .jobHistory)
        let support = try container.decode(
            [CareerStakeholder: Int].self,
            forKey: .stakeholderSupport
        )
        let opportunities = try container.decode(
            [CareerOpportunity].self,
            forKey: .opportunities
        )
        let status = try container.decode(CareerEmploymentStatus.self, forKey: .status)
        guard Self.isValid(
            currentJob: currentJob,
            jobHistory: history,
            stakeholderSupport: support,
            opportunities: opportunities,
            status: status
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .status,
                in: container,
                debugDescription: "Career arc state is malformed or exceeds its history bounds."
            )
        }
        self.currentJob = currentJob
        self.jobHistory = history
        self.stakeholderSupport = support
        self.opportunities = Self.sorted(opportunities)
        self.status = status
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(currentJob, forKey: .currentJob)
        try container.encode(jobHistory, forKey: .jobHistory)
        try container.encode(stakeholderSupport, forKey: .stakeholderSupport)
        try container.encode(opportunities, forKey: .opportunities)
        try container.encode(status, forKey: .status)
    }

    public var averageSupport: Int {
        guard !stakeholderSupport.isEmpty else { return 0 }
        return stakeholderSupport.values.reduce(0, +) / stakeholderSupport.count
    }

    @discardableResult
    public mutating func establishCollegeJob(
        organisationID: UUID,
        at calendar: CalendarState
    ) -> Bool {
        guard currentJob == nil else { return currentJob?.organisationID == organisationID }
        currentJob = CareerJob(organisationID: organisationID, tier: .college, startedAt: calendar)
        status = .employed
        return true
    }

    @discardableResult
    public mutating func applySupport(
        deltas: [CareerStakeholder: Int]
    ) -> Bool {
        guard Set(deltas.keys).isSubset(of: Set(CareerStakeholder.allCases)),
              deltas.values.allSatisfy({ (-100...100).contains($0) }) else { return false }
        for stakeholder in CareerStakeholder.allCases {
            stakeholderSupport[stakeholder] = min(
                Self.supportRange.upperBound,
                max(
                    Self.supportRange.lowerBound,
                    stakeholderSupport[stakeholder, default: 60] + deltas[stakeholder, default: 0]
                )
            )
        }
        return true
    }

    @discardableResult
    public mutating func addOpportunity(_ opportunity: CareerOpportunity) -> Bool {
        guard opportunities.count < Self.maximumOpportunities,
              !opportunities.contains(where: { $0.id == opportunity.id }),
              !opportunities.contains(where: {
                  $0.organisationID == opportunity.organisationID
                      && $0.offeredAt == opportunity.offeredAt
              }) else { return false }
        opportunities.append(opportunity)
        opportunities = Self.sorted(opportunities)
        return true
    }

    @discardableResult
    public mutating func markFired(at calendar: CalendarState) -> Bool {
        guard status == .employed, let currentJob else { return false }
        guard jobHistory.count < Self.maximumJobHistory else { return false }
        jobHistory.append(CareerJobHistoryEntry(job: currentJob, endedAt: calendar, reason: .fired))
        self.currentJob = nil
        status = .fired
        return true
    }

    /// Moves a fired coach into the market.
    ///
    /// **Why this exists at all.** `markFired` used to be terminal: it set `.fired`, and both career
    /// evaluators then guarded on `status != .fired` and returned forever, so nothing in the
    /// repository could ever produce `.seeking` again. A fired save was permanently inert, which is
    /// the dead end `02` §7 and D8 forbid in as many words. Firing is a transition, not an ending.
    @discardableResult
    public mutating func beginSeeking() -> Bool {
        guard status == .fired, currentJob == nil else { return false }
        status = .seeking
        return true
    }

    /// Drops offers that can no longer be accepted, returning them so a caller can report them.
    ///
    /// An offer is spent the moment its deadline passes; keeping it would let `opportunities` fill
    /// to its bound with offers `acceptOpportunity` already refuses, which is how a coach ends up
    /// nominally in the market with nothing in it.
    @discardableResult
    public mutating func pruneOpportunities(
        expiringBefore calendar: CalendarState
    ) -> [CareerOpportunity] {
        let expired = opportunities.filter { Self.occurs($0.expiresAt, before: calendar) }
        guard !expired.isEmpty else { return [] }
        let expiredIDs = Set(expired.map(\.id))
        opportunities.removeAll { expiredIDs.contains($0.id) }
        return expired
    }

    @discardableResult
    public mutating func acceptOpportunity(
        id: UUID,
        at calendar: CalendarState
    ) -> Bool {
        guard let index = opportunities.firstIndex(where: { $0.id == id }) else { return false }
        let opportunity = opportunities[index]
        guard !Self.occurs(calendar, before: opportunity.offeredAt),
              !Self.occurs(opportunity.expiresAt, before: calendar),
              jobHistory.count < Self.maximumJobHistory else { return false }
        if let currentJob {
            // Leaving a job you still hold is a promotion; arriving from the market is not, and the
            // history entry has already been written by whatever ended the previous job.
            jobHistory.append(CareerJobHistoryEntry(
                job: currentJob,
                endedAt: calendar,
                reason: .promoted
            ))
        }
        self.currentJob = CareerJob(
            organisationID: opportunity.organisationID,
            tier: opportunity.tier,
            startedAt: calendar
        )
        opportunities.remove(at: index)
        status = .employed
        return true
    }

    @discardableResult
    public mutating func resign(at calendar: CalendarState) -> Bool {
        guard status == .employed,
              let currentJob,
              jobHistory.count < Self.maximumJobHistory else { return false }
        jobHistory.append(CareerJobHistoryEntry(
            job: currentJob,
            endedAt: calendar,
            reason: .resigned
        ))
        self.currentJob = nil
        status = .seeking
        return true
    }

    private static func isValid(
        currentJob: CareerJob?,
        jobHistory: [CareerJobHistoryEntry],
        stakeholderSupport: [CareerStakeholder: Int],
        opportunities: [CareerOpportunity],
        status: CareerEmploymentStatus
    ) -> Bool {
        let expectedStakeholders = Set(CareerStakeholder.allCases)
        let historyJobs = jobHistory.map { $0.job }
        return jobHistory.count <= maximumJobHistory
            && opportunities.count <= maximumOpportunities
            && Set(opportunities.map(\.id)).count == opportunities.count
            && Set(historyJobs.map { "\($0.organisationID.uuidString)|\($0.startedAt.season)|\($0.startedAt.week)" }).count
                == historyJobs.count
            && Set(stakeholderSupport.keys) == expectedStakeholders
            && stakeholderSupport.values.allSatisfy(supportRange.contains)
            && (status == .employed ? currentJob != nil : currentJob == nil)
            && opportunities.allSatisfy {
                !occurs($0.expiresAt, before: $0.offeredAt)
            }
    }

    private static func sorted(_ opportunities: [CareerOpportunity]) -> [CareerOpportunity] {
        opportunities.sorted {
            if $0.offeredAt != $1.offeredAt {
                return occurs($0.offeredAt, before: $1.offeredAt)
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    fileprivate static func occurs(_ lhs: CalendarState, before rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }
}

/// What a career evaluation did, for a caller that owns state the arc itself cannot reach.
///
/// `CareerArcState` knows about jobs; it does not know about `CareerControlState`, and a firing has
/// to end both together or the world is left with a coach who lost their job and kept their
/// programme. Returning the intent rather than mutating the root keeps the arc a value type and
/// leaves the scheduler as the one place that writes the root.
public struct CareerArcOutcome: Sendable, Equatable {
    /// Set when a job ended: the organisation whose control must now be released.
    public var vacatedOrganisationID: UUID?
    public var eventPayloads: [DomainEventPayload]

    public init(
        vacatedOrganisationID: UUID? = nil,
        eventPayloads: [DomainEventPayload] = []
    ) {
        self.vacatedOrganisationID = vacatedOrganisationID
        self.eventPayloads = eventPayloads
    }

    public static let none = CareerArcOutcome()
}

public enum CareerArcSystem {
    @discardableResult
    public static func evaluateWeek(
        after calendar: CalendarState,
        in state: GameState,
        arc: inout CareerArcState
    ) -> CareerArcOutcome {
        guard calendar.week <= SharedRules.inSeasonWeeks,
              let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              arc.status != .fired else { return .none }
        var outcome = CareerArcOutcome()
        if arc.currentJob == nil {
            if arc.establishCollegeJob(organisationID: programme.id, at: control.startedAt) {
                outcome.eventPayloads.append(.coachJobStarted(
                    organisationID: programme.id,
                    tier: .college
                ))
            }
        }
        guard arc.status == .employed,
              let game = state.competition.currentSchedule.games.first(where: {
                  $0.season == calendar.season
                      && $0.week == calendar.week
                      && $0.result != nil
                      && ($0.homeID == programme.id || $0.awayID == programme.id)
              }),
              let result = game.result else { return outcome }

        let programmeScore: Int
        let opponentScore: Int
        if game.homeID == programme.id {
            programmeScore = result.homeScore
            opponentScore = result.awayScore
        } else {
            programmeScore = result.awayScore
            opponentScore = result.homeScore
        }
        let performance = min(100, max(0, 50 + (programmeScore - opponentScore) * 2))
        let expectation = min(95, max(40, programme.prestige.value + 10))
        let delta = min(4, max(-4, (performance - expectation) / 10))
        let won = programmeScore > opponentScore
        let closeGame = abs(programmeScore - opponentScore) <= 7
        _ = arc.applySupport(deltas: Dictionary(uniqueKeysWithValues: CareerStakeholder.allCases.map {
            let bias: Int
            switch $0 {
            case .administration: bias = delta
            case .boosters: bias = delta + (won ? 1 : -1)
            case .fanbase: bias = delta + (won ? 2 : -2)
            case .lockerRoom: bias = delta + (closeGame ? 1 : 0)
            }
            return ($0, bias)
        }))
        if arc.averageSupport < 12, arc.markFired(at: calendar) {
            outcome.vacatedOrganisationID = programme.id
            outcome.eventPayloads.append(.coachJobEnded(
                organisationID: programme.id,
                tier: .college,
                reason: .fired
            ))
        }
        return outcome
    }

    @discardableResult
    public static func evaluateSeasonEnd(
        after calendar: CalendarState,
        in state: GameState,
        arc: inout CareerArcState
    ) -> CareerArcOutcome {
        guard calendar.week == SharedRules.inSeasonWeeks,
              let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              arc.status != .fired else { return .none }
        var outcome = CareerArcOutcome()
        if arc.currentJob == nil {
            if arc.establishCollegeJob(
                organisationID: programme.id,
                at: CalendarState(season: calendar.season, week: 1)
            ) {
                outcome.eventPayloads.append(.coachJobStarted(
                    organisationID: programme.id,
                    tier: .college
                ))
            }
        }
        guard arc.status == .employed else { return outcome }

        let ranking = state.competition.rankings[.college] ?? state.programmes.ids
        let rank = ranking.firstIndex(of: programme.id) ?? max(0, ranking.count - 1)
        let performance = ranking.count <= 1
            ? 100
            : 100 - rank * 100 / max(1, ranking.count - 1)
        let expectation = min(95, max(40, programme.prestige.value + 10))
        let delta = min(12, max(-12, (performance - expectation) / 5))
        _ = arc.applySupport(deltas: Dictionary(uniqueKeysWithValues: CareerStakeholder.allCases.map {
            let bias: Int
            switch $0 {
            case .administration: bias = delta
            case .boosters: bias = delta + (performance >= 70 ? 2 : 0)
            case .fanbase: bias = delta + (performance >= expectation ? 2 : -1)
            case .lockerRoom: bias = delta / 2
            }
            return ($0, bias)
        }))

        if arc.averageSupport < 20 {
            if arc.markFired(at: calendar) {
                outcome.vacatedOrganisationID = programme.id
                outcome.eventPayloads.append(.coachJobEnded(
                    organisationID: programme.id,
                    tier: .college,
                    reason: .fired
                ))
            }
            return outcome
        }
        guard performance >= 75, arc.averageSupport >= 70,
              let team = state.proTeams.values
                .filter({ $0.id != programme.id })
                .sorted(by: { $0.prestige == $1.prestige
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.prestige > $1.prestige
                })
                .first else { return outcome }
        let opportunityID = SeededRandom.derive(
            from: state.league.seed,
            scope: .personnel,
            identifier: team.id
        ) ^ UInt64(calendar.season)
        var rng = SeededRandom(seed: opportunityID)
        let opportunity = CareerOpportunity(
            id: rng.uuid(),
            organisationID: team.id,
            tier: .professional,
            offeredAt: calendar,
            expiresAt: CalendarState(season: calendar.season + 1, week: 2),
            prestige: team.prestige,
            rationale: .sustainedCollegeSuccess
        )
        if arc.addOpportunity(opportunity) {
            outcome.eventPayloads.append(.careerOpportunityOffered(
                opportunityID: opportunity.id,
                organisationID: opportunity.organisationID,
                tier: opportunity.tier
            ))
        }
        return outcome
    }

    /// D8's floor, as a mechanism: a coach out of work is never left with nothing to accept.
    ///
    /// Runs for a coach who is out of a job — `.fired` moves to `.seeking` here, which is the only
    /// place that transition happens — and offers a programme when the market is empty. The offer is
    /// deliberately downward: the least prestigious programme that is not the one that just sacked
    /// them, which is the lower-league restart the research says players author for themselves when
    /// a game does not supply it.
    @discardableResult
    public static func ensureMarketFloor(
        at calendar: CalendarState,
        in state: GameState,
        arc: inout CareerArcState
    ) -> CareerArcOutcome {
        _ = arc.beginSeeking()
        guard arc.status == .seeking, arc.currentJob == nil else { return .none }
        guard arc.opportunities.isEmpty else { return .none }
        let lastOrganisationID = arc.jobHistory.last?.job.organisationID
        guard let programme = state.programmes.values
            .filter({ $0.id != lastOrganisationID })
            .sorted(by: { $0.prestige == $1.prestige
                ? $0.id.uuidString < $1.id.uuidString
                : $0.prestige < $1.prestige
            })
            .first else { return .none }
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.derive(
                from: SeededRandom.derive(
                    from: state.league.seed,
                    scope: .season,
                    ordinal: calendar.season
                ),
                scope: .week,
                ordinal: calendar.week
            ),
            scope: .personnel,
            identifier: programme.id
        ))
        let opportunity = CareerOpportunity(
            id: rng.uuid(),
            organisationID: programme.id,
            tier: .college,
            offeredAt: calendar,
            expiresAt: CalendarState(
                season: calendar.season,
                week: min(SharedRules.inSeasonWeeks, calendar.week + 4)
            ),
            prestige: programme.prestige,
            rationale: .staffRecommendation
        )
        guard arc.addOpportunity(opportunity) else { return .none }
        return CareerArcOutcome(eventPayloads: [.careerOpportunityOffered(
            opportunityID: opportunity.id,
            organisationID: opportunity.organisationID,
            tier: opportunity.tier
        )])
    }
}
