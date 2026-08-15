import Foundation

public enum CompetitionStage: String, Codable, Sendable, CaseIterable, Hashable {
    case regularSeason
    case conferenceChampionship
    case quarterfinal
    case semifinal
    case championship
}

public enum GameSummarySource: String, Codable, Sendable, Equatable {
    case abstracted
    case detailed
}

/// The bounded team-level output of an abstract or detailed game.
public struct GameSummary: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case homeScore, awayScore, homeStatistics, awayStatistics
        case homeParticipantIDs, awayParticipantIDs, playerStatistics, source, evidence
    }

    public let homeScore: Int
    public let awayScore: Int
    public let homeStatistics: TeamGameStatistics
    public let awayStatistics: TeamGameStatistics
    public let homeParticipantIDs: [UUID]
    public let awayParticipantIDs: [UUID]
    public let playerStatistics: [PlayerGameStatistics]
    public let source: GameSummarySource
    /// Compact controlled-game evidence survives finalization for Aftermath/Game Detail.
    /// Abstracted games leave it nil because their bounded aggregate is the authoritative detail.
    public let evidence: GameEvidence?

    public init(
        homeScore: Int,
        awayScore: Int,
        homeStatistics: TeamGameStatistics,
        awayStatistics: TeamGameStatistics,
        homeParticipantIDs: [UUID] = [],
        awayParticipantIDs: [UUID] = [],
        playerStatistics: [PlayerGameStatistics],
        source: GameSummarySource = .abstracted,
        evidence: GameEvidence? = nil
    ) {
        self.homeScore = max(0, homeScore)
        self.awayScore = max(0, awayScore)
        self.homeStatistics = homeStatistics
        self.awayStatistics = awayStatistics
        let canonicalHome = Self.canonicalParticipantIDs(homeParticipantIDs)
        let homeSet = Set(canonicalHome)
        self.homeParticipantIDs = canonicalHome
        self.awayParticipantIDs = Self.canonicalParticipantIDs(
            awayParticipantIDs.filter { !homeSet.contains($0) }
        )
        self.playerStatistics = playerStatistics.sorted { $0.playerID.uuidString < $1.playerID.uuidString }
        self.source = source
        self.evidence = evidence
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedHomeScore = try container.decode(Int.self, forKey: .homeScore)
        let decodedAwayScore = try container.decode(Int.self, forKey: .awayScore)
        let decodedHomeParticipants = try container.decode(
            [UUID].self,
            forKey: .homeParticipantIDs
        )
        let decodedAwayParticipants = try container.decode(
            [UUID].self,
            forKey: .awayParticipantIDs
        )
        let decodedSource = try container.decodeIfPresent(GameSummarySource.self, forKey: .source)
            ?? .abstracted
        let decodedPlayerStatistics = try container.decode(
            [PlayerGameStatistics].self,
            forKey: .playerStatistics
        )
        let homeSet = Set(decodedHomeParticipants)
        let awaySet = Set(decodedAwayParticipants)
        let productionIDs = decodedPlayerStatistics.map(\.playerID)
        let maximumScore = decodedSource == .detailed
            ? MatchupRules.maximumDrivesPerGame
                * (MatchupRules.touchdownPoints + MatchupRules.extraPointPoints)
            : CompetitionRules.maximumFinalTeamScore
        guard (0...maximumScore).contains(decodedHomeScore),
              (0...maximumScore).contains(decodedAwayScore),
              decodedHomeParticipants.count <= CompetitionRules.maximumParticipantsPerTeam,
              decodedAwayParticipants.count <= CompetitionRules.maximumParticipantsPerTeam,
              homeSet.count == decodedHomeParticipants.count,
              awaySet.count == decodedAwayParticipants.count,
              homeSet.isDisjoint(with: awaySet),
              Set(productionIDs).count == productionIDs.count,
              Set(productionIDs).isSubset(of: homeSet.union(awaySet)) else {
            throw DecodingError.dataCorruptedError(
                forKey: .homeParticipantIDs,
                in: container,
                debugDescription: "Game participants are duplicated, unbounded, or disagree with production."
            )
        }
        self.init(
            homeScore: decodedHomeScore,
            awayScore: decodedAwayScore,
            homeStatistics: try container.decode(
                TeamGameStatistics.self,
                forKey: .homeStatistics
            ),
            awayStatistics: try container.decode(
                TeamGameStatistics.self,
                forKey: .awayStatistics
            ),
            homeParticipantIDs: decodedHomeParticipants,
            awayParticipantIDs: decodedAwayParticipants,
            playerStatistics: decodedPlayerStatistics,
            source: decodedSource,
            evidence: try container.decodeIfPresent(GameEvidence.self, forKey: .evidence)
        )
    }

    private static func canonicalParticipantIDs(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        return ids.sorted { $0.uuidString < $1.uuidString }
            .filter { seen.insert($0).inserted }
            .prefix(CompetitionRules.maximumParticipantsPerTeam)
            .map { $0 }
    }
}

public struct ScheduledGame: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let season: Int
    public let tier: Tier
    public let week: Int
    public let stage: CompetitionStage
    public let homeID: UUID
    public let awayID: UUID
    public var result: GameSummary?

    public init(
        id: UUID,
        season: Int,
        tier: Tier,
        week: Int,
        stage: CompetitionStage,
        homeID: UUID,
        awayID: UUID,
        result: GameSummary? = nil
    ) {
        self.id = id
        self.season = max(0, season)
        self.tier = tier
        self.week = max(1, week)
        self.stage = stage
        self.homeID = homeID
        self.awayID = awayID
        self.result = result
    }
}

/// A completed result to apply to an existing schedule entry. Schedule identity and ordering stay
/// authoritative in `SeasonSchedule`; callers can only supply the result payload.
public struct ScheduledGameResult: Sendable, Equatable {
    public let gameID: UUID
    public let summary: GameSummary

    public init(gameID: UUID, summary: GameSummary) {
        self.gameID = gameID
        self.summary = summary
    }
}

public enum ScheduleResultRecordingError: Error, Sendable, Equatable {
    case duplicateGameID(UUID)
    case unknownGameID(UUID)
    case alreadyResolvedGameID(UUID)
}

public struct SeasonSchedule: Codable, Sendable, Equatable {
    public let season: Int
    public private(set) var games: [ScheduledGame]

    public init(season: Int, games: [ScheduledGame]) {
        self.season = max(0, season)
        self.games = games.sorted(by: Self.gameOrder)
    }

    public mutating func replace(_ game: ScheduledGame) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return false }
        games[index] = game
        games.sort(by: Self.gameOrder)
        return true
    }

    /// Records a batch atomically and returns the completed games in canonical schedule order.
    /// The schedule keys cannot change, so this path performs no re-sort.
    public mutating func recordResults(
        _ records: [ScheduledGameResult]
    ) throws -> [ScheduledGame] {
        guard !records.isEmpty else { return [] }

        var recordsByID: [UUID: ScheduledGameResult] = [:]
        recordsByID.reserveCapacity(records.count)
        var duplicateIDs: Set<UUID> = []
        for record in records {
            if recordsByID.updateValue(record, forKey: record.gameID) != nil {
                duplicateIDs.insert(record.gameID)
            }
        }
        if let duplicateID = duplicateIDs.min(by: Self.idOrder) {
            throw ScheduleResultRecordingError.duplicateGameID(duplicateID)
        }

        let scheduledIDs = Set(games.map(\.id))
        if let unknownID = recordsByID.keys
            .filter({ !scheduledIDs.contains($0) })
            .min(by: Self.idOrder) {
            throw ScheduleResultRecordingError.unknownGameID(unknownID)
        }

        var updates: [(index: Int, summary: GameSummary)] = []
        updates.reserveCapacity(records.count)
        for (index, game) in games.enumerated() {
            guard let record = recordsByID[game.id] else { continue }
            guard game.result == nil else {
                throw ScheduleResultRecordingError.alreadyResolvedGameID(game.id)
            }
            updates.append((index: index, summary: record.summary))
        }

        for update in updates {
            games[update.index].result = update.summary
        }
        return updates.map { games[$0.index] }
    }

    public mutating func append(contentsOf newGames: [ScheduledGame]) {
        games.append(contentsOf: newGames)
        games.sort(by: Self.gameOrder)
    }

    private static func gameOrder(_ lhs: ScheduledGame, _ rhs: ScheduledGame) -> Bool {
        if lhs.week != rhs.week { return lhs.week < rhs.week }
        if lhs.tier != rhs.tier { return lhs.tier.rawValue < rhs.tier.rawValue }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func idOrder(_ lhs: UUID, _ rhs: UUID) -> Bool {
        lhs.uuidString < rhs.uuidString
    }
}

public struct CompetitionState: Codable, Sendable, Equatable {
    public static let archiveLimit = 100

    public var currentSchedule: SeasonSchedule
    public var standings: [Tier: [StandingRow]]
    public var rankings: [Tier: [UUID]]
    public var teamStatistics: [UUID: TeamSeasonStatistics]
    public var playerStatistics: [UUID: PlayerSeasonStatistics]
    public var collegeChampionID: UUID?
    public var proChampionID: UUID?
    public private(set) var archives: [SeasonArchive]
    public var recordBook: CompetitionRecordBook

    public init(
        currentSchedule: SeasonSchedule,
        standings: [Tier: [StandingRow]] = [:],
        rankings: [Tier: [UUID]] = [:],
        teamStatistics: [UUID: TeamSeasonStatistics] = [:],
        playerStatistics: [UUID: PlayerSeasonStatistics] = [:],
        collegeChampionID: UUID? = nil,
        proChampionID: UUID? = nil,
        archives: [SeasonArchive] = [],
        recordBook: CompetitionRecordBook = CompetitionRecordBook()
    ) {
        self.currentSchedule = currentSchedule
        self.standings = standings
        self.rankings = rankings
        self.teamStatistics = teamStatistics
        self.playerStatistics = playerStatistics
        self.collegeChampionID = collegeChampionID
        self.proChampionID = proChampionID
        self.archives = Array(archives.suffix(CompetitionState.archiveLimit))
        self.recordBook = recordBook
    }

    public static func bootstrap(
        seed: UInt64,
        season: Int,
        programmes: [Programme],
        proTeams: [ProTeam]
    ) -> CompetitionState {
        CompetitionState(currentSchedule: SeasonSchedule(
            season: season,
            games: ScheduleGenerator.regularSeason(
                seed: seed,
                season: season,
                programmes: programmes,
                proTeams: proTeams
            )
        ))
    }

    public mutating func appendArchive(_ archive: SeasonArchive) {
        archives = Array((archives + [archive]).suffix(CompetitionState.archiveLimit))
    }
}

public struct SeasonArchive: Codable, Sendable, Equatable {
    public let season: Int
    public let collegeChampionID: UUID
    public let proChampionID: UUID
    public let finalCollegeRanking: [UUID]
    public let finalProRanking: [UUID]
    public let awards: [SeasonAward]
    public let gamesPlayed: Int
    public let totalPoints: Int

    public init(
        season: Int,
        collegeChampionID: UUID,
        proChampionID: UUID,
        finalCollegeRanking: [UUID],
        finalProRanking: [UUID],
        awards: [SeasonAward],
        gamesPlayed: Int,
        totalPoints: Int
    ) {
        self.season = max(0, season)
        self.collegeChampionID = collegeChampionID
        self.proChampionID = proChampionID
        self.finalCollegeRanking = finalCollegeRanking
        self.finalProRanking = finalProRanking
        self.awards = awards
        self.gamesPlayed = max(0, gamesPlayed)
        self.totalPoints = max(0, totalPoints)
    }
}
