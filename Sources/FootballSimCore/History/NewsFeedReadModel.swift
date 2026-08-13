import Foundation

/// One story, rendered from a typed event.
public struct NewsItem: Sendable, Equatable, Identifiable {
    public var id: UUID { eventID }
    public let eventID: UUID
    public let occurredAt: CalendarState
    public let weight: Int
    public let headline: String

    public init(eventID: UUID, occurredAt: CalendarState, weight: Int, headline: String) {
        self.eventID = eventID
        self.occurredAt = occurredAt
        self.weight = weight
        self.headline = headline
    }
}

/// The living world's news feed: a bounded, rebuildable projection over typed history.
///
/// **Derived, never stored.** `DomainEventPayload` states the rule — "Presentation text is derived by
/// read-model builders, never persisted as the source of truth" — so a headline is computed here and
/// a save carries the facts, not the prose. That is also what lets the wording change without
/// migrating anybody's league.
///
/// **Newsworthiness is `historicalWeight`, the same rank M7B uses to decide which bodies an archived
/// season keeps.** One definition of "important", used twice: a season that is worth remembering is
/// a season worth reporting. A payload scoring zero is weekly bookkeeping and never makes the feed.
///
/// It reads the bounded hot journal *and* the archive's retained bodies, which is the point of
/// keeping bodies at all — a championship stays reportable long after it has left the hot window.
public struct NewsFeedReadModel: Sendable, Equatable {
    /// A feed is a screen, not a census.
    public static let maximumItems = 64

    public let items: [NewsItem]

    public init(items: [NewsItem]) {
        self.items = Array(items.prefix(NewsFeedReadModel.maximumItems))
    }

    public static func build(from state: GameState) -> NewsFeedReadModel {
        let names = Self.names(in: state)
        var seen: Set<UUID> = []
        var rendered: [NewsItem] = []

        // The hot journal first, then archived bodies, so a story still in the window is preferred
        // to its archived copy and neither is reported twice.
        for event in state.history.recent + state.history.archive.flatMap(\.notableEvents) {
            guard seen.insert(event.id).inserted else { continue }
            guard let headline = Self.headline(for: event.payload, names: names) else { continue }
            rendered.append(NewsItem(
                eventID: event.id,
                occurredAt: event.occurredAt,
                weight: event.payload.historicalWeight,
                headline: headline
            ))
        }

        // Newest season first, and inside a season the heaviest story leads. Sorting by recency
        // alone would bury a championship under the transactions that followed it; sorting by weight
        // alone would freeze the same headline at the top of the feed forever.
        rendered.sort { lhs, rhs in
            if lhs.occurredAt.season != rhs.occurredAt.season {
                return lhs.occurredAt.season > rhs.occurredAt.season
            }
            if lhs.weight != rhs.weight { return lhs.weight > rhs.weight }
            if lhs.occurredAt.week != rhs.occurredAt.week {
                return lhs.occurredAt.week > rhs.occurredAt.week
            }
            return lhs.eventID.uuidString < rhs.eventID.uuidString
        }
        return NewsFeedReadModel(items: rendered)
    }

    /// The story a payload tells, or nil when it tells none.
    ///
    /// Exhaustive with no `default`, like `historicalWeight` itself: a new payload cannot be added
    /// without someone deciding whether it is reportable and how it reads.
    private static func headline(
        for payload: DomainEventPayload,
        names: [UUID: String]
    ) -> String? {
        func who(_ id: UUID) -> String { names[id] ?? "An unnamed party" }

        switch payload {
        case let .seasonCompleted(season, collegeChampionID, proChampionID):
            return "Season \(season) ends: \(who(collegeChampionID)) take the college title, "
                + "\(who(proChampionID)) the professional one"
        case let .worldCreated(programmes, proTeams):
            return "A new football world opens with \(programmes) programmes and \(proTeams) "
                + "professional teams"
        case let .postseasonScheduled(tier, stage, _, participantIDs):
            return "\(participantIDs.count) teams are seeded for the \(tier.rawValue) "
                + "\(stage.rawValue)"
        case let .portalWindowCompleted(summary):
            return "The transfer portal closes with \(summary.transferredCount) moves"
        case let .proMarketOpened(season, draftClassCount, freeAgentCount):
            return "The season \(season) professional market opens: \(draftClassCount) draft "
                + "prospects and \(freeAgentCount) free agents"
        case let .proDraftStarted(season):
            return "The season \(season) professional draft is under way"
        case let .proMarketClosed(season):
            return "The season \(season) professional market closes"
        case let .proDraftPick(prospectID, teamID, pick, _):
            return "\(who(teamID)) take \(who(prospectID)) with pick \(pick + 1)"
        case let .playerTransferred(playerID, _, destinationProgrammeID, _, _, _, _):
            return "\(who(playerID)) transfers to \(who(destinationProgrammeID))"
        case let .proTradeCompleted(sourcePlayerID, sourceTeamID, destinationPlayerID, destinationTeamID):
            return "\(who(sourceTeamID)) trade \(who(sourcePlayerID)) to "
                + "\(who(destinationTeamID)) for \(who(destinationPlayerID))"
        case let .proWaiverClaimed(playerID, _, destinationTeamID):
            return "\(who(destinationTeamID)) claim \(who(playerID)) off waivers"
        case let .staffHired(staffID, organisationID, role):
            return "\(who(organisationID)) hire \(who(staffID)) as \(role.rawValue)"
        case let .prospectCommitted(prospectID, context):
            return "\(who(prospectID)) commits to \(who(context.winner.programmeID))"
        case let .commitmentResolved(prospectID, programmeID, outcome):
            switch outcome {
            case .signed:
                return "\(who(prospectID)) signs with \(who(programmeID))"
            case let .released(reason):
                return "\(who(programmeID)) release \(who(prospectID)): \(reason)"
            }
        case let .portalEntered(playerID, sourceProgrammeID, _, _, _):
            return "\(who(playerID)) enters the portal from \(who(sourceProgrammeID))"
        case let .playerJoined(playerID, organisationID, _):
            return "\(who(playerID)) joins \(who(organisationID))"
        case let .playerDeparted(playerID, organisationID, reason):
            return "\(who(playerID)) leaves \(who(organisationID)): \(reason.rawValue)"
        case let .redshirtResolved(playerID, programmeID, _, _, outcome):
            return "\(who(playerID)) at \(who(programmeID)): redshirt \(outcome.rawValue)"
        case let .proPlayerSigned(playerID, teamID, kind, _):
            return "\(who(teamID)) sign \(who(playerID)) (\(kind.rawValue))"
        case let .proCapComplianceRelease(playerID, teamID, _):
            return "\(who(teamID)) release \(who(playerID)) to clear cap space"

        // Weekly bookkeeping, scored zero by `historicalWeight` and reported by nobody.
        case .integrityChecked,
             .weekAdvanced,
             .gameCompleted,
             .playerInjured,
             .playerRecovered,
             .playerDeveloped,
             .prospectEvaluated,
             .recruitingInteraction,
             .portalRetentionResolved,
             .portalOfferMade,
             .proDraftScouted,
             .proContractExpired,
             .proPracticeSquadMoved,
             .proWaiverPlaced,
             .proWaiverExpired,
             .proWaiversResolved:
            return nil
        }
    }

    private static func names(in state: GameState) -> [UUID: String] {
        var result: [UUID: String] = [:]
        for programme in state.programmes.values { result[programme.id] = programme.name }
        for team in state.proTeams.values { result[team.id] = team.name }
        for player in state.players.values { result[player.id] = player.fullName }
        for staff in state.staff.values { result[staff.id] = staff.fullName }
        for prospect in state.prospects.values {
            result[prospect.id] = "\(prospect.firstName) \(prospect.lastName)"
        }
        for departed in state.people.departedPlayers.values {
            result[departed.id] = departed.fullName
        }
        return result
    }
}
