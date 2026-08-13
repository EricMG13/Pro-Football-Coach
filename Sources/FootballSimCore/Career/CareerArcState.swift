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

    @discardableResult
    public mutating func acceptOpportunity(
        id: UUID,
        at calendar: CalendarState
    ) -> Bool {
        guard let index = opportunities.firstIndex(where: { $0.id == id }) else { return false }
        let opportunity = opportunities[index]
        guard opportunity.tier == .professional,
              !Self.occurs(calendar, before: opportunity.offeredAt),
              !Self.occurs(opportunity.expiresAt, before: calendar),
              jobHistory.count < Self.maximumJobHistory else { return false }
        if let currentJob {
            jobHistory.append(CareerJobHistoryEntry(
                job: currentJob,
                endedAt: calendar,
                reason: .promoted
            ))
        }
        self.currentJob = CareerJob(
            organisationID: opportunity.organisationID,
            tier: .professional,
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

public enum CareerArcSystem {
    public static func evaluateWeek(
        after calendar: CalendarState,
        in state: GameState,
        arc: inout CareerArcState
    ) {
        guard calendar.week <= SharedRules.inSeasonWeeks,
              let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              arc.status != .fired else { return }
        _ = arc.establishCollegeJob(
            organisationID: programme.id,
            at: control.startedAt
        )
        guard arc.status == .employed,
              let game = state.competition.currentSchedule.games.first(where: {
                  $0.season == calendar.season
                      && $0.week == calendar.week
                      && $0.result != nil
                      && ($0.homeID == programme.id || $0.awayID == programme.id)
              }),
              let result = game.result else { return }

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
        if arc.averageSupport < 12 {
            _ = arc.markFired(at: calendar)
        }
    }

    public static func evaluateSeasonEnd(
        after calendar: CalendarState,
        in state: GameState,
        arc: inout CareerArcState
    ) {
        guard calendar.week == SharedRules.inSeasonWeeks,
              let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              arc.status != .fired else { return }
        _ = arc.establishCollegeJob(organisationID: programme.id, at: CalendarState(
            season: calendar.season,
            week: 1
        ))
        guard arc.status == .employed else { return }

        let ranking = state.competition.rankings[.college] ?? state.programmes.ids
        let rank = ranking.firstIndex(of: programme.id) ?? max(0, ranking.count - 1)
        let performance = ranking.count <= 1
            ? 100
            : 100 - rank * 100 / max(1, ranking.count - 1)
        let expectation = min(95, max(40, programme.prestige.value + 10))
        let delta = min(12, max(-12, (performance - expectation) / 5))
        // `02` §7.1. The locker room is the one stakeholder that should be reading the room rather
        // than the scoreboard, and until now it read the same table everybody else did with a
        // close-game bias on top. §5.1's morale is what a locker room actually knows — playing time,
        // NIL, injuries, what this place does after a result, and since §5.2 who has been suspended
        // — so a season in which a quarter of the roster is unhappy costs support whatever the
        // record says.
        let lockerRoomMood = mood(of: programme.id, in: state)
        _ = arc.applySupport(deltas: Dictionary(uniqueKeysWithValues: CareerStakeholder.allCases.map {
            let bias: Int
            switch $0 {
            case .administration: bias = delta
            case .boosters: bias = delta + (performance >= 70 ? 2 : 0)
            case .fanbase: bias = delta + (performance >= expectation ? 2 : -1)
            case .lockerRoom: bias = delta / 2 + lockerRoomMood
            }
            return ($0, bias)
        }))

        if arc.averageSupport < 20 {
            _ = arc.markFired(at: calendar)
            return
        }
        guard performance >= 75, arc.averageSupport >= 70,
              let team = state.proTeams.values
                .filter({ $0.id != programme.id })
                .sorted(by: { $0.prestige == $1.prestige
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.prestige > $1.prestige
                })
                .first else { return }
        let opportunityID = SeededRandom.derive(
            from: state.league.seed,
            scope: .personnel,
            identifier: team.id
        ) ^ UInt64(calendar.season)
        var rng = SeededRandom(seed: opportunityID)
        _ = arc.addOpportunity(CareerOpportunity(
            id: rng.uuid(),
            organisationID: team.id,
            tier: .professional,
            offeredAt: calendar,
            expiresAt: CalendarState(season: calendar.season + 1, week: 2),
            prestige: team.prestige,
            rationale: .sustainedCollegeSuccess
        ))
    }

    /// What the room thinks, as a support bias. `02` §7.1.
    ///
    /// A share of the roster rather than a count, so it means the same thing at a programme carrying
    /// eighty-five players and at one carrying seventy. Silent in the middle for the reason the
    /// inbox is: a locker room that had an opinion every season about nothing is a dashboard, and
    /// pressure that is always on is not pressure.
    public static func mood(of organisationID: UUID, in state: GameState) -> Int {
        let rosterSize = state.programmes[organisationID]?.rosterIDs.count
            ?? state.proTeams[organisationID]?.rosterIDs.count
            ?? 0
        guard rosterSize > 0 else { return 0 }
        let unhappy = PlayerMorale.unhappy(in: organisationID, state: state).count
        let share = unhappy * 100 / rosterSize
        if share >= PeopleRules.mutinousRosterShare { return -PeopleRules.lockerRoomMoraleSwing }
        if share <= PeopleRules.contentRosterShare { return PeopleRules.lockerRoomMoraleSwing }
        return 0
    }
}
