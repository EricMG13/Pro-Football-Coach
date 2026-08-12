import Foundation

/// A position in the shared world calendar.
public struct CalendarState: Codable, Sendable, Equatable {
    public let season: Int
    public let week: Int

    public init(season: Int = 0, week: Int = 1) {
        self.season = max(0, season)
        self.week = min(max(1, week), SharedRules.inSeasonWeeks)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .season)
        let decodedWeek = try container.decode(Int.self, forKey: .week)
        guard decodedSeason >= 0, (1...SharedRules.inSeasonWeeks).contains(decodedWeek) else {
            throw DecodingError.dataCorruptedError(
                forKey: .week,
                in: container,
                debugDescription: "The world calendar is outside the supported season bounds."
            )
        }
        season = decodedSeason
        week = decodedWeek
    }

    public func advancedWeek() -> CalendarState {
        if week == SharedRules.inSeasonWeeks {
            return CalendarState(season: season + 1, week: 1)
        }
        return CalendarState(season: season, week: week + 1)
    }
}

/// Typed historical facts. Presentation text is derived by read-model builders, never persisted
/// as the source of truth.
public enum DomainEventPayload: Codable, Sendable, Equatable {
    case worldCreated(programmes: Int, proTeams: Int)
    case integrityChecked(issueCount: Int)
    case weekAdvanced(completed: CalendarState, next: CalendarState)
    case gameCompleted(
        gameID: UUID,
        homeID: UUID,
        awayID: UUID,
        stage: CompetitionStage,
        homeScore: Int,
        awayScore: Int
    )
    case postseasonScheduled(
        tier: Tier,
        stage: CompetitionStage,
        gameIDs: [UUID],
        participantIDs: [UUID]
    )
    case seasonCompleted(season: Int, collegeChampionID: UUID, proChampionID: UUID)
    case playerInjured(
        playerID: UUID,
        area: InjuryArea,
        severity: InjurySeverity,
        weeks: Int
    )
    case playerRecovered(playerID: UUID)
    case playerDeveloped(
        playerID: UUID,
        attribute: Attribute,
        delta: Int,
        components: [DevelopmentComponent]
    )
    case redshirtResolved(
        playerID: UUID,
        programmeID: UUID,
        appearances: Int,
        plannedAppearanceLimit: Int,
        outcome: RedshirtSeasonOutcome
    )
    case playerDeparted(
        playerID: UUID,
        organisationID: UUID,
        reason: PlayerDepartureReason
    )
    case playerJoined(
        playerID: UUID,
        organisationID: UUID,
        source: PlayerIntakeSource
    )
    case staffHired(staffID: UUID, organisationID: UUID, role: StaffRole)
    case prospectEvaluated(observerID: UUID, prospectID: UUID, confidence: Int)
    case recruitingInteraction(
        programmeID: UUID,
        prospectID: UUID,
        action: RecruitingInteractionKind,
        resourceCost: Int,
        interestAfter: Int
    )
    case prospectCommitted(
        prospectID: UUID,
        context: RecruitingCommitmentContext
    )
    case commitmentResolved(
        prospectID: UUID,
        programmeID: UUID,
        outcome: CommitmentTerminalOutcome
    )
    case portalEntered(
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        intent: CollegePortalIntentExplanation
    )
    case portalRetentionResolved(
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        resolution: CollegePortalRetentionResolution
    )
    case portalOfferMade(
        playerID: UUID,
        sourceProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        offer: CollegePortalOffer
    )
    case playerTransferred(
        playerID: UUID,
        sourceProgrammeID: UUID,
        destinationProgrammeID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow,
        sourceWasScholarship: Bool,
        finalNIL: Int
    )
    case portalWindowCompleted(summary: CollegePortalWindowSummary)
    case proMarketOpened(season: Int, draftClassCount: Int, freeAgentCount: Int)
    case proDraftScouted(teamID: UUID, prospectID: UUID, confidence: Int)
    case proDraftStarted(season: Int)
    case proPlayerSigned(
        playerID: UUID,
        teamID: UUID,
        kind: ProAcquisitionKind,
        contract: Contract
    )
    case proContractExpired(playerID: UUID)
    case proDraftPick(
        prospectID: UUID,
        teamID: UUID,
        pick: Int,
        contract: Contract
    )
    case proPracticeSquadMoved(playerID: UUID, teamID: UUID, promoted: Bool)
    case proTradeCompleted(
        sourcePlayerID: UUID,
        sourceTeamID: UUID,
        destinationPlayerID: UUID,
        destinationTeamID: UUID
    )
    case proWaiverPlaced(playerID: UUID, teamID: UUID, claimDeadline: CalendarState)
    case proWaiverClaimed(playerID: UUID, sourceTeamID: UUID, destinationTeamID: UUID)
    case proWaiverExpired(playerID: UUID, teamID: UUID)
    case proWaiversResolved(count: Int)
    case proMarketClosed(season: Int)

    public var referencedEntityIDs: [UUID] {
        switch self {
        case let .gameCompleted(_, homeID, awayID, _, _, _):
            return [homeID, awayID]
        case let .postseasonScheduled(_, _, _, participantIDs):
            return participantIDs
        case let .seasonCompleted(_, collegeChampionID, proChampionID):
            return [collegeChampionID, proChampionID]
        case let .playerInjured(playerID, _, _, _), let .playerRecovered(playerID):
            return [playerID]
        case let .playerDeveloped(playerID, _, _, _):
            return [playerID]
        case let .redshirtResolved(playerID, programmeID, _, _, _):
            return [playerID, programmeID]
        case let .playerDeparted(playerID, organisationID, _),
             let .playerJoined(playerID, organisationID, _):
            return [playerID, organisationID]
        case let .staffHired(staffID, organisationID, _):
            return [staffID, organisationID]
        case let .prospectEvaluated(observerID, prospectID, _):
            return [observerID, prospectID]
        case let .recruitingInteraction(programmeID, prospectID, _, _, _):
            return [programmeID, prospectID]
        case let .prospectCommitted(prospectID, context):
            return [prospectID, context.winner.programmeID]
                + (context.previousWinner.map { [$0.programmeID] } ?? [])
                + (context.runnerUp.map { [$0.programmeID] } ?? [])
                + {
                    if case let .capacityFallback(blockedPreferred) = context.selectionReason {
                        return [blockedPreferred.programmeID]
                    }
                    return []
                }()
        case let .commitmentResolved(prospectID, programmeID, _):
            return [prospectID, programmeID]
        case let .portalEntered(playerID, sourceProgrammeID, _, _, _),
             let .portalRetentionResolved(playerID, sourceProgrammeID, _, _, _):
            return [playerID, sourceProgrammeID]
        case let .portalOfferMade(playerID, sourceProgrammeID, _, _, offer):
            return [playerID, sourceProgrammeID, offer.destinationProgrammeID]
        case let .playerTransferred(
            playerID,
            sourceProgrammeID,
            destinationProgrammeID,
            _,
            _,
            _,
            _
        ):
            return [playerID, sourceProgrammeID, destinationProgrammeID]
        case let .proDraftScouted(teamID, prospectID, _):
            return [teamID, prospectID]
        case let .proPlayerSigned(playerID, teamID, _, _):
            return [playerID, teamID]
        case let .proContractExpired(playerID):
            return [playerID]
        case let .proDraftPick(prospectID, teamID, _, _):
            return [prospectID, teamID]
        case let .proPracticeSquadMoved(playerID, teamID, _):
            return [playerID, teamID]
        case let .proTradeCompleted(sourcePlayerID, sourceTeamID, destinationPlayerID, destinationTeamID):
            return [sourcePlayerID, sourceTeamID, destinationPlayerID, destinationTeamID]
        case let .proWaiverPlaced(playerID, teamID, _):
            return [playerID, teamID]
        case let .proWaiverClaimed(playerID, sourceTeamID, destinationTeamID):
            return [playerID, sourceTeamID, destinationTeamID]
        case let .proWaiverExpired(playerID, teamID):
            return [playerID, teamID]
        default:
            return []
        }
    }

    /// Prospect identities referenced by retained event bodies.
    ///
    /// A signed prospect subsequently resolves as a player, but the recruiting events emitted
    /// before signing remain prospect facts. Keeping this typed subset separate from the generic
    /// entity references lets annual-cycle retention preserve only the former prospect identities
    /// that the bounded hot journal can still query.
    public var referencedProspectIDs: [UUID] {
        switch self {
        case let .prospectEvaluated(_, prospectID, _),
             let .recruitingInteraction(_, prospectID, _, _, _),
             let .prospectCommitted(prospectID, _),
             let .commitmentResolved(prospectID, _, _):
            return [prospectID]
        default:
            return []
        }
    }
}

public struct DomainEvent: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let sequence: Int
    public let occurredAt: CalendarState
    public let payload: DomainEventPayload

    public init(
        id: UUID,
        sequence: Int,
        occurredAt: CalendarState,
        payload: DomainEventPayload
    ) {
        self.id = id
        self.sequence = sequence
        self.occurredAt = occurredAt
        self.payload = payload
    }

    /// Produces a stable identity in the save's one global event namespace.
    ///
    /// The ledger sequence is global across scheduler and player-intent events. Deriving every
    /// event ID from that sequence prevents independent deterministic streams from replaying the
    /// same UUID when their local ordinals happen to overlap.
    public static func deterministicID(rootSeed: UInt64, sequence: Int) -> UUID {
        precondition(sequence >= 0, "Domain-event identities require a non-negative sequence.")
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: rootSeed,
            scope: .scheduler,
            ordinal: sequence
        ))
        return rng.uuid()
    }
}

/// Bounded hot history plus an archive count. Later persistence milestones may move archived event
/// bodies to cold storage without changing this root contract.
public struct DomainEventLedger: Codable, Sendable, Equatable {
    public static let defaultRetentionLimit = 4_096
    public static let maximumRetentionLimit = 100_000

    public let retentionLimit: Int
    public private(set) var recent: [DomainEvent]
    public private(set) var archivedCount: Int
    public private(set) var lastSequence: Int?

    public init(retentionLimit: Int = DomainEventLedger.defaultRetentionLimit) {
        self.retentionLimit = min(
            max(1, retentionLimit),
            DomainEventLedger.maximumRetentionLimit
        )
        recent = []
        archivedCount = 0
        lastSequence = nil
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRetentionLimit = try container.decode(Int.self, forKey: .retentionLimit)
        let decodedArchivedCount = try container.decode(Int.self, forKey: .archivedCount)
        guard (1...DomainEventLedger.maximumRetentionLimit).contains(decodedRetentionLimit),
              decodedArchivedCount >= 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .retentionLimit,
                in: container,
                debugDescription: "The domain-event retention accounting is outside its bounds."
            )
        }
        let decodedRecent = try container.decode([DomainEvent].self, forKey: .recent)
        let decodedLastSequence = try container.decodeIfPresent(Int.self, forKey: .lastSequence)

        var previousSequence: Int?
        var previousCalendar: CalendarState?
        var eventIDs: Set<UUID> = []
        let eventsAreOrderedAndUnique = decodedRecent.allSatisfy { event in
            defer {
                previousSequence = event.sequence
                previousCalendar = event.occurredAt
            }
            return event.sequence >= 0
                && (previousSequence.map { event.sequence > $0 } ?? true)
                && (previousCalendar.map {
                    !Self.occurs(event.occurredAt, before: $0)
                } ?? true)
                && eventIDs.insert(event.id).inserted
        }
        let accountingIsValid = decodedRecent.count <= decodedRetentionLimit
            && decodedLastSequence == decodedRecent.last?.sequence
            && (decodedArchivedCount == 0 || decodedRecent.count == decodedRetentionLimit)
            && decodedArchivedCount <= Int.max - decodedRecent.count

        guard eventsAreOrderedAndUnique && accountingIsValid else {
            throw DecodingError.dataCorruptedError(
                forKey: .recent,
                in: container,
                debugDescription: "The domain-event ledger violates ordering or retention bounds."
            )
        }

        retentionLimit = decodedRetentionLimit
        recent = decodedRecent
        archivedCount = decodedArchivedCount
        lastSequence = decodedLastSequence
    }

    @discardableResult
    public mutating func append(_ event: DomainEvent) -> Bool {
        append(contentsOf: [event])
    }

    /// Validates and records a batch as one transaction. Validation indexes the bounded hot
    /// journal once, and retention is rebuilt once, so work is linear in existing hot history plus
    /// the incoming batch rather than repeating a scan and front-removal for every event.
    @discardableResult
    public mutating func append(contentsOf events: [DomainEvent]) -> Bool {
        guard !events.isEmpty else { return true }

        var retainedIDs = Set(recent.map(\.id))
        var previousSequence = lastSequence
        var previousCalendar = recent.last?.occurredAt
        for event in events {
            guard event.sequence >= 0 else { return false }
            guard previousSequence.map({ event.sequence > $0 }) ?? true else { return false }
            guard previousCalendar.map({
                !Self.occurs(event.occurredAt, before: $0)
            }) ?? true else { return false }
            guard retainedIDs.insert(event.id).inserted else { return false }
            previousSequence = event.sequence
            previousCalendar = event.occurredAt
        }

        let (combinedCount, countOverflow) = recent.count.addingReportingOverflow(events.count)
        guard !countOverflow else { return false }
        let overflowCount = max(0, combinedCount - retentionLimit)
        let (nextArchivedCount, archiveOverflow) = archivedCount.addingReportingOverflow(
            overflowCount
        )
        guard !archiveOverflow else { return false }
        let nextRecentCount = min(combinedCount, retentionLimit)
        let (_, totalOverflow) = nextArchivedCount.addingReportingOverflow(nextRecentCount)
        guard !totalOverflow else { return false }

        let incomingToKeep = min(events.count, retentionLimit)
        let existingToKeep = min(recent.count, retentionLimit - incomingToKeep)
        var nextRecent: [DomainEvent] = []
        nextRecent.reserveCapacity(existingToKeep + incomingToKeep)
        nextRecent.append(contentsOf: recent.suffix(existingToKeep))
        nextRecent.append(contentsOf: events.suffix(incomingToKeep))

        recent = nextRecent
        archivedCount = nextArchivedCount
        lastSequence = events.last?.sequence
        return true
    }

    public var totalCount: Int { archivedCount + recent.count }

    /// Compatibility accessor for callers that expect a concrete integer. An exhausted sequence
    /// saturates here; mutation code must use `firstSequence(forAppending:)` before materializing.
    public var nextSequence: Int { firstSequence(forAppending: 1) ?? Int.max }

    /// Returns the first consecutive sequence for a non-empty append, or `nil` when the requested
    /// range would exceed `Int.max`.
    public func firstSequence(forAppending count: Int) -> Int? {
        guard count > 0 else { return nil }
        let first: Int
        if let lastSequence {
            let (next, overflow) = lastSequence.addingReportingOverflow(1)
            guard !overflow else { return nil }
            first = next
        } else {
            first = 0
        }
        let (_, rangeOverflow) = first.addingReportingOverflow(count - 1)
        return rangeOverflow ? nil : first
    }

    private static func occurs(_ lhs: CalendarState, before rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }
}
