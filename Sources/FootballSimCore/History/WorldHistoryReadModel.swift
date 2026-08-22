import Foundation

public enum HistorySearchKind: String, Sendable, Equatable, CaseIterable {
    case programme
    case proTeam
    case player
    case staff
    case rivalry
    case season
    case award
    case record
    case event
}

public struct HistorySearchEntry: Sendable, Equatable, Identifiable {
    public let id: String
    public let entityID: UUID?
    public let kind: HistorySearchKind
    public let title: String
    public let detail: String
    public let season: Int?
    fileprivate let searchableText: String

    fileprivate init(
        id: String,
        entityID: UUID?,
        kind: HistorySearchKind,
        title: String,
        detail: String,
        season: Int?
    ) {
        self.id = id
        self.entityID = entityID
        self.kind = kind
        self.title = title
        self.detail = detail
        self.season = season
        searchableText = [title, detail, id].joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}

public struct HistorySearchResult: Sendable, Equatable {
    public let query: String
    public let entries: [HistorySearchEntry]

    public init(query: String, entries: [HistorySearchEntry]) {
        self.query = query
        self.entries = entries
    }
}

/// Rebuildable history/search projection. It is intentionally not Codable: authoritative state and
/// bounded event history remain the save contract, while this index can be rebuilt after load.
public struct WorldHistoryReadModel: Sendable, Equatable {
    /// Enough for the fixed current-world population, bounded recent events, and compact archives;
    /// older event bodies are not fabricated into this disposable projection.
    public static let maximumEntries = 32_768
    public let entries: [HistorySearchEntry]
    public let recordBook: CompetitionRecordBook

    public init(entries: [HistorySearchEntry], recordBook: CompetitionRecordBook) {
        self.entries = Array(entries.sorted(by: Self.entryOrder).prefix(Self.maximumEntries))
        self.recordBook = recordBook
    }

    public static func build(from state: GameState) -> WorldHistoryReadModel {
        var entries: [HistorySearchEntry] = []
        entries.reserveCapacity(state.players.count + state.staff.count + state.history.recent.count)
        let names = Self.names(in: state)

        entries.append(contentsOf: state.programmes.values.map { programme in
            HistorySearchEntry(
                id: "programme:\(programme.id.uuidString)",
                entityID: programme.id,
                kind: .programme,
                title: programme.name,
                detail: "College programme · \(programme.cityName)",
                season: nil
            )
        })
        entries.append(contentsOf: state.proTeams.values.map { team in
            HistorySearchEntry(
                id: "pro-team:\(team.id.uuidString)",
                entityID: team.id,
                kind: .proTeam,
                title: team.displayName,
                detail: "Professional team · \(team.cityName)",
                season: nil
            )
        })
        entries.append(contentsOf: state.players.values.map { player in
            HistorySearchEntry(
                id: "player:\(player.id.uuidString)",
                entityID: player.id,
                kind: .player,
                title: player.fullName,
                detail: "Player · \(player.position.rawValue)",
                season: nil
            )
        })
        entries.append(contentsOf: state.staff.values.map { staff in
            HistorySearchEntry(
                id: "staff:\(staff.id.uuidString)",
                entityID: staff.id,
                kind: .staff,
                title: staff.fullName,
                detail: "Staff · \(staff.role.rawValue)",
                season: nil
            )
        })
        entries.append(contentsOf: state.people.departedPlayers.values.map { departed in
            HistorySearchEntry(
                id: "departed-player:\(departed.id.uuidString)",
                entityID: departed.id,
                kind: .player,
                title: departed.fullName,
                detail: "Departed player · \(departed.status.rawValue)",
                season: nil
            )
        })
        entries.append(contentsOf: state.rivalries.values.map { rivalry in
            HistorySearchEntry(
                id: "rivalry:\(rivalry.id.uuidString)",
                entityID: rivalry.id,
                kind: .rivalry,
                title: "\(names[rivalry.sideA] ?? "Unknown") vs \(names[rivalry.sideB] ?? "Unknown")",
                detail: "Rivalry · intensity \(rivalry.intensity.value)",
                season: nil
            )
        })
        for archive in state.competition.archives.sorted(by: { $0.season < $1.season }) {
            entries.append(HistorySearchEntry(
                id: "season:\(archive.season)",
                entityID: nil,
                kind: .season,
                title: "Season \(archive.season)",
                detail: "Champions: \(names[archive.collegeChampionID] ?? "Unknown") / \(names[archive.proChampionID] ?? "Unknown")",
                season: archive.season
            ))
            for (index, award) in archive.awards.enumerated() {
                entries.append(HistorySearchEntry(
                    id: "award:\(archive.season):\(index):\(award.winnerID.uuidString)",
                    entityID: award.winnerID,
                    kind: .award,
                    title: "\(award.kind.rawValue) · \(names[award.winnerID] ?? "Unknown")",
                    detail: "\(award.tier.rawValue) season \(archive.season)",
                    season: archive.season
                ))
            }
        }
        if let record = state.competition.recordBook.highestTeamScore {
            entries.append(Self.recordEntry(
                id: "record:highest-score",
                title: "Highest team score",
                record: record,
                names: names
            ))
        }
        if let record = state.competition.recordBook.mostTeamYards {
            entries.append(Self.recordEntry(
                id: "record:most-yards",
                title: "Most team yards",
                record: record,
                names: names
            ))
        }
        entries.append(contentsOf: state.history.recent.map { event in
            HistorySearchEntry(
                id: "event:\(event.id.uuidString)",
                entityID: event.id,
                kind: .event,
                title: Self.eventTitle(event.payload),
                detail: "\(event.occurredAt.season)-\(event.occurredAt.week) · sequence \(event.sequence)",
                season: event.occurredAt.season
            )
        })
        return WorldHistoryReadModel(entries: entries, recordBook: state.competition.recordBook)
    }

    public func search(_ query: String, limit: Int = 50) -> HistorySearchResult {
        let normalized = query
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard !normalized.isEmpty else {
            return HistorySearchResult(query: query, entries: [])
        }
        let matches = entries.filter { entry in
            normalized.allSatisfy { entry.searchableText.contains($0) }
        }
        return HistorySearchResult(
            query: query,
            entries: Array(matches.prefix(max(0, limit)))
        )
    }

    private static func entryOrder(_ lhs: HistorySearchEntry, _ rhs: HistorySearchEntry) -> Bool {
        if lhs.kind != rhs.kind { return lhs.kind.rawValue < rhs.kind.rawValue }
        if lhs.title != rhs.title { return lhs.title < rhs.title }
        return lhs.id < rhs.id
    }

    private static func names(in state: GameState) -> [UUID: String] {
        var result: [UUID: String] = [:]
        for programme in state.programmes.values { result[programme.id] = programme.name }
        for team in state.proTeams.values { result[team.id] = team.displayName }
        for player in state.players.values { result[player.id] = player.fullName }
        for staff in state.staff.values { result[staff.id] = staff.fullName }
        for departed in state.people.departedPlayers.values { result[departed.id] = departed.fullName }
        return result
    }

    private static func recordEntry(
        id: String,
        title: String,
        record: TeamGameRecordEntry,
        names: [UUID: String]
    ) -> HistorySearchEntry {
        HistorySearchEntry(
            id: id,
            entityID: record.teamID,
            kind: .record,
            title: title,
            detail: "\(record.value) · \(names[record.teamID] ?? "Unknown") vs \(names[record.opponentID] ?? "Unknown") · season \(record.season)",
            season: record.season
        )
    }

    private static func eventTitle(_ payload: DomainEventPayload) -> String {
        switch payload {
        case .gameCompleted: return "Game completed"
        case .seasonCompleted: return "Season completed"
        case .playerJoined: return "Player joined"
        case .playerDeparted: return "Player departed"
        case .proPlayerSigned: return "Professional player signed"
        case .proContractExpired: return "Professional contract expired"
        case .proTradeCompleted: return "Professional trade completed"
        case .proWaiverPlaced, .proWaiverClaimed, .proWaiverExpired, .proWaiversResolved:
            return "Professional waiver activity"
        case .redshirtResolved: return "Redshirt resolved"
        case .portalWindowCompleted: return "Portal window completed"
        default: return "World event"
        }
    }
}
