import Foundation

/// What kind of game this is — drives scheduling, standings and playoff logic.
public enum GameKind: String, Codable, Sendable, Equatable {
    case preseason
    case division
    case conference
    case interConference
    case wildCard
    case divisionalRound
    case conferenceChampionship
    case championship

    public var isPlayoff: Bool {
        switch self {
        case .wildCard, .divisionalRound, .conferenceChampionship, .championship: true
        default: false
        }
    }

    public var countsInStandings: Bool {
        switch self {
        case .division, .conference, .interConference: true
        default: false
        }
    }

    public var label: String {
        switch self {
        case .preseason: "PRE"
        case .division: "DIV"
        case .conference: "CONF"
        case .interConference: "INTER"
        case .wildCard: "WILD CARD"
        case .divisionalRound: "DIVISIONAL"
        case .conferenceChampionship: "CONF CHAMPIONSHIP"
        case .championship: "CHAMPIONSHIP"
        }
    }
}

/// A fixture on the calendar.
public struct ScheduledGame: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let week: Int
    public let homeTeamID: UUID
    public let awayTeamID: UUID
    public let kind: GameKind
    /// Championship games are played somewhere neutral.
    public let isNeutralSite: Bool

    public init(
        id: UUID = UUID(),
        week: Int,
        homeTeamID: UUID,
        awayTeamID: UUID,
        kind: GameKind,
        isNeutralSite: Bool = false
    ) {
        self.id = id
        self.week = week
        self.homeTeamID = homeTeamID
        self.awayTeamID = awayTeamID
        self.kind = kind
        self.isNeutralSite = isNeutralSite
    }

    public func involves(_ teamID: UUID) -> Bool {
        homeTeamID == teamID || awayTeamID == teamID
    }

    public func opponent(of teamID: UUID) -> UUID? {
        switch teamID {
        case homeTeamID: awayTeamID
        case awayTeamID: homeTeamID
        default: nil
        }
    }
}

public enum PlayCategory: String, Codable, Sendable, Equatable {
    case run, pass, sack, punt, fieldGoal, extraPoint, kickoff, penalty, turnover
    case touchdown, twoPointConversion, kneel, spike, timeout, injury, administrative
}

/// One line of play-by-play. Retained for the user's own games so the log and the arcade
/// mode have something to render; discarded for bulk-simmed games to keep saves small.
public struct PlayEvent: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let drive: Int
    public let quarter: Int
    /// Seconds left in the quarter when the play ended.
    public let clockSeconds: Int
    public let offenseTeamID: UUID
    public let category: PlayCategory
    public let yards: Int
    public let down: Int
    public let distance: Int
    /// Yards from the offense's own goal line, 0...100.
    public let yardLine: Int
    public let description: String
    public let involvedPlayerIDs: [UUID]
    public let homeScore: Int
    public let awayScore: Int

    public init(
        id: UUID = UUID(),
        drive: Int,
        quarter: Int,
        clockSeconds: Int,
        offenseTeamID: UUID,
        category: PlayCategory,
        yards: Int,
        down: Int,
        distance: Int,
        yardLine: Int,
        description: String,
        involvedPlayerIDs: [UUID] = [],
        homeScore: Int,
        awayScore: Int
    ) {
        self.id = id
        self.drive = drive
        self.quarter = quarter
        self.clockSeconds = clockSeconds
        self.offenseTeamID = offenseTeamID
        self.category = category
        self.yards = yards
        self.down = down
        self.distance = distance
        self.yardLine = yardLine
        self.description = description
        self.involvedPlayerIDs = involvedPlayerIDs
        self.homeScore = homeScore
        self.awayScore = awayScore
    }

    /// "Q2 7:31" style stamp for the play log.
    public var clockLabel: String {
        let quarterLabel = quarter <= 4 ? "Q\(quarter)" : "OT"
        return String(format: "%@ %d:%02d", quarterLabel, clockSeconds / 60, clockSeconds % 60)
    }
}

/// An injury suffered during a game, applied to the league after the final whistle.
public struct InjuryOutcome: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let teamID: UUID
    public let weeksOut: Int
    public let description: String

    public init(playerID: UUID, teamID: UUID, weeksOut: Int, description: String) {
        self.playerID = playerID
        self.teamID = teamID
        self.weeksOut = weeksOut
        self.description = description
    }
}

/// The complete result of one played game.
public struct GameRecord: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let scheduledGameID: UUID
    public let week: Int
    public let year: Int
    public let kind: GameKind
    public let homeTeamID: UUID
    public let awayTeamID: UUID
    public let homeStats: TeamGameStats
    public let awayStats: TeamGameStats
    /// Per-player box score for both teams.
    public let playerStats: [UUID: StatLine]
    public let plays: [PlayEvent]
    public let injuries: [InjuryOutcome]
    public let overtimePeriods: Int

    public init(
        id: UUID = UUID(),
        scheduledGameID: UUID,
        week: Int,
        year: Int,
        kind: GameKind,
        homeTeamID: UUID,
        awayTeamID: UUID,
        homeStats: TeamGameStats,
        awayStats: TeamGameStats,
        playerStats: [UUID: StatLine],
        plays: [PlayEvent] = [],
        injuries: [InjuryOutcome] = [],
        overtimePeriods: Int = 0
    ) {
        self.id = id
        self.scheduledGameID = scheduledGameID
        self.week = week
        self.year = year
        self.kind = kind
        self.homeTeamID = homeTeamID
        self.awayTeamID = awayTeamID
        self.homeStats = homeStats
        self.awayStats = awayStats
        self.playerStats = playerStats
        self.plays = plays
        self.injuries = injuries
        self.overtimePeriods = overtimePeriods
    }

    public var homeScore: Int { homeStats.points }
    public var awayScore: Int { awayStats.points }
    public var isTie: Bool { homeScore == awayScore }
    public var winnerID: UUID? { isTie ? nil : (homeScore > awayScore ? homeTeamID : awayTeamID) }
    public var loserID: UUID? { isTie ? nil : (homeScore > awayScore ? awayTeamID : homeTeamID) }
    public var wentToOvertime: Bool { overtimePeriods > 0 }
    public var totalPoints: Int { homeScore + awayScore }

    public func involves(_ teamID: UUID) -> Bool {
        homeTeamID == teamID || awayTeamID == teamID
    }

    public func score(for teamID: UUID) -> Int {
        teamID == homeTeamID ? homeScore : awayScore
    }

    public func opponentScore(for teamID: UUID) -> Int {
        teamID == homeTeamID ? awayScore : homeScore
    }

    public func stats(for teamID: UUID) -> TeamGameStats {
        teamID == homeTeamID ? homeStats : awayStats
    }

    public func didWin(_ teamID: UUID) -> Bool { winnerID == teamID }

    /// Strips play-by-play, keeping the box score. Applied to older seasons so saves stay small.
    public func compacted() -> GameRecord {
        GameRecord(
            id: id,
            scheduledGameID: scheduledGameID,
            week: week,
            year: year,
            kind: kind,
            homeTeamID: homeTeamID,
            awayTeamID: awayTeamID,
            homeStats: homeStats,
            awayStats: awayStats,
            playerStats: playerStats,
            plays: [],
            injuries: injuries,
            overtimePeriods: overtimePeriods
        )
    }
}
