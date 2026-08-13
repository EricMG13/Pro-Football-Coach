import Foundation

public enum SeasonAwardKind: String, Codable, Sendable, CaseIterable, Hashable {
    case champion
    case topOffense
    case playerOfTheYear
    /// Added 2026-08-13 with the statistical vocabulary (`02` §3.11). Three award kinds, one of them
    /// offensive by construction and none of them reachable by a defender, was not a shortage of
    /// honours — it was the record having nothing to give one for.
    case topDefense
    case offensivePlayerOfTheYear
    case defensivePlayerOfTheYear

    /// Whether this honour goes to a team or to a person, so a reader never has to guess which kind
    /// of identifier `winnerID` holds.
    public var isTeamAward: Bool {
        switch self {
        case .champion, .topOffense, .topDefense: return true
        case .playerOfTheYear, .offensivePlayerOfTheYear, .defensivePlayerOfTheYear: return false
        }
    }
}

public struct SeasonAward: Codable, Sendable, Equatable {
    public let kind: SeasonAwardKind
    public let tier: Tier
    public let winnerID: UUID
    public let value: Int

    public init(kind: SeasonAwardKind, tier: Tier, winnerID: UUID, value: Int) {
        self.kind = kind
        self.tier = tier
        self.winnerID = winnerID
        self.value = max(0, value)
    }
}

public struct TeamGameRecordEntry: Codable, Sendable, Equatable {
    public let value: Int
    public let teamID: UUID
    public let gameID: UUID
    public let season: Int
    public let opponentID: UUID
    public let tier: Tier
    public let stage: CompetitionStage
    public let week: Int

    public init(
        value: Int,
        teamID: UUID,
        gameID: UUID,
        season: Int,
        opponentID: UUID,
        tier: Tier,
        stage: CompetitionStage,
        week: Int
    ) {
        self.value = max(0, value)
        self.teamID = teamID
        self.gameID = gameID
        self.season = max(0, season)
        self.opponentID = opponentID
        self.tier = tier
        self.stage = stage
        self.week = max(1, week)
    }
}

public struct CompetitionRecordBook: Codable, Sendable, Equatable {
    public private(set) var highestTeamScore: TeamGameRecordEntry?
    public private(set) var mostTeamYards: TeamGameRecordEntry?

    public init(
        highestTeamScore: TeamGameRecordEntry? = nil,
        mostTeamYards: TeamGameRecordEntry? = nil
    ) {
        self.highestTeamScore = highestTeamScore
        self.mostTeamYards = mostTeamYards
    }

    public mutating func consider(_ game: ScheduledGame, result: GameSummary) {
        considerScore(
            value: result.homeScore,
            teamID: game.homeID,
            gameID: game.id,
            season: game.season,
            opponentID: game.awayID,
            tier: game.tier,
            stage: game.stage,
            week: game.week
        )
        considerScore(
            value: result.awayScore,
            teamID: game.awayID,
            gameID: game.id,
            season: game.season,
            opponentID: game.homeID,
            tier: game.tier,
            stage: game.stage,
            week: game.week
        )
        considerYards(
            value: result.homeStatistics.offensiveYards,
            teamID: game.homeID,
            gameID: game.id,
            season: game.season,
            opponentID: game.awayID,
            tier: game.tier,
            stage: game.stage,
            week: game.week
        )
        considerYards(
            value: result.awayStatistics.offensiveYards,
            teamID: game.awayID,
            gameID: game.id,
            season: game.season,
            opponentID: game.homeID,
            tier: game.tier,
            stage: game.stage,
            week: game.week
        )
    }

    private mutating func considerScore(
        value: Int,
        teamID: UUID,
        gameID: UUID,
        season: Int,
        opponentID: UUID,
        tier: Tier,
        stage: CompetitionStage,
        week: Int
    ) {
        let candidate = TeamGameRecordEntry(
            value: value,
            teamID: teamID,
            gameID: gameID,
            season: season,
            opponentID: opponentID,
            tier: tier,
            stage: stage,
            week: week
        )
        if outranks(candidate, highestTeamScore) { highestTeamScore = candidate }
    }

    private mutating func considerYards(
        value: Int,
        teamID: UUID,
        gameID: UUID,
        season: Int,
        opponentID: UUID,
        tier: Tier,
        stage: CompetitionStage,
        week: Int
    ) {
        let candidate = TeamGameRecordEntry(
            value: value,
            teamID: teamID,
            gameID: gameID,
            season: season,
            opponentID: opponentID,
            tier: tier,
            stage: stage,
            week: week
        )
        if outranks(candidate, mostTeamYards) { mostTeamYards = candidate }
    }

    private func outranks(_ candidate: TeamGameRecordEntry, _ current: TeamGameRecordEntry?) -> Bool {
        guard let current else { return true }
        if candidate.value != current.value { return candidate.value > current.value }
        if candidate.season != current.season { return candidate.season < current.season }
        if candidate.gameID != current.gameID {
            return candidate.gameID.uuidString < current.gameID.uuidString
        }
        return candidate.teamID.uuidString < current.teamID.uuidString
    }
}
