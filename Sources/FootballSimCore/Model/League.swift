import Foundation

/// Where the league is in its yearly cycle. The whole app navigates off this.
public enum SeasonPhase: Codable, Sendable, Equatable {
    case preseason
    case regularSeason(week: Int)
    case playoffs(round: Int)
    case offseason(stage: Int)

    public var isRegularSeason: Bool {
        if case .regularSeason = self { return true }
        return false
    }

    public var isPlayoffs: Bool {
        if case .playoffs = self { return true }
        return false
    }

    public var isOffseason: Bool {
        if case .offseason = self { return true }
        return false
    }

    public var week: Int? {
        if case .regularSeason(let week) = self { return week }
        return nil
    }

    public var label: String {
        switch self {
        case .preseason: "Preseason"
        case .regularSeason(let week): "Week \(week)"
        case .playoffs(let round): PlayoffRound(rawValue: round)?.displayName ?? "Playoffs"
        case .offseason(let stage): OffseasonStage(rawValue: stage)?.displayName ?? "Offseason"
        }
    }
}

public enum PlayoffRound: Int, Codable, CaseIterable, Sendable {
    case wildCard = 0
    case divisional = 1
    case conferenceChampionship = 2
    case championship = 3

    public var displayName: String {
        switch self {
        case .wildCard: "Wild Card"
        case .divisional: "Divisional Round"
        case .conferenceChampionship: "Conference Championships"
        case .championship: "Championship"
        }
    }

    public var gameKind: GameKind {
        switch self {
        case .wildCard: .wildCard
        case .divisional: .divisionalRound
        case .conferenceChampionship: .conferenceChampionship
        case .championship: .championship
        }
    }
}

/// The ordered offseason pipeline. Each stage is a screen and an engine step.
public enum OffseasonStage: Int, Codable, CaseIterable, Sendable {
    case seasonReview = 0
    case coachingCarousel = 1
    case retirements = 2
    case reSigning = 3
    case freeAgency = 4
    case draft = 5
    case trainingCamp = 6
    case rosterCutdown = 7

    public var displayName: String {
        switch self {
        case .seasonReview: "Season Review"
        case .coachingCarousel: "Coaching Carousel"
        case .retirements: "Retirements"
        case .reSigning: "Re-Sign Window"
        case .freeAgency: "Free Agency"
        case .draft: "Draft"
        case .trainingCamp: "Training Camp"
        case .rosterCutdown: "Roster Cutdown"
        }
    }

    public var detail: String {
        switch self {
        case .seasonReview: "Awards, goals and the year in review"
        case .coachingCarousel: "Head coaches and coordinators change jobs"
        case .retirements: "Veterans hang them up"
        case .reSigning: "Keep your own expiring contracts"
        case .freeAgency: "Bid against the rest of the league"
        case .draft: "Seven rounds, then undrafted signings"
        case .trainingCamp: "Development is revealed"
        case .rosterCutdown: "Trim to 53 and set the practice squad"
        }
    }
}

public enum PlayoffFormat: Int, Codable, CaseIterable, Sendable {
    case twelve = 12
    case fourteen = 14
    case sixteen = 16

    public var teamsPerConference: Int { rawValue / 2 }
    /// Top seeds that skip the wild-card round.
    public var byesPerConference: Int {
        switch self {
        case .twelve: 2
        case .fourteen: 1
        case .sixteen: 0
        }
    }

    public var displayName: String { "\(rawValue)-Team Playoff" }
}

public enum TradeDifficulty: String, Codable, CaseIterable, Sendable {
    case easy, medium, hard

    public var displayName: String { rawValue.capitalized }

    /// Surplus the AI demands before accepting.
    public var acceptanceThreshold: Double {
        switch self {
        case .easy: 1.00
        case .medium: 1.05
        case .hard: 1.12
        }
    }
}

/// Per-save rules the player chose during setup.
public struct LeagueSettings: Codable, Sendable, Equatable {
    public var playoffFormat: PlayoffFormat
    public var injuriesEnabled: Bool
    public var salaryCapEnabled: Bool
    public var coachFiringEnabled: Bool
    public var franchiseTagEnabled: Bool
    public var tradeDifficulty: TradeDifficulty
    public var autoCallPlays: Bool
    /// Show point spreads instead of win probability on matchup cards.
    public var showPredictionLine: Bool

    public init(
        playoffFormat: PlayoffFormat = .fourteen,
        injuriesEnabled: Bool = true,
        salaryCapEnabled: Bool = true,
        coachFiringEnabled: Bool = true,
        franchiseTagEnabled: Bool = true,
        tradeDifficulty: TradeDifficulty = .medium,
        autoCallPlays: Bool = false,
        showPredictionLine: Bool = true
    ) {
        self.playoffFormat = playoffFormat
        self.injuriesEnabled = injuriesEnabled
        self.salaryCapEnabled = salaryCapEnabled
        self.coachFiringEnabled = coachFiringEnabled
        self.franchiseTagEnabled = franchiseTagEnabled
        self.tradeDifficulty = tradeDifficulty
        self.autoCallPlays = autoCallPlays
        self.showPredictionLine = showPredictionLine
    }
}

public enum NewsCategory: String, Codable, CaseIterable, Sendable {
    case gameResult, injury, signing, trade, draft, milestone, award, hotSeat, retirement, staff, league

    public var iconName: String {
        switch self {
        case .gameResult: "sportscourt"
        case .injury: "cross.case"
        case .signing: "signature"
        case .trade: "arrow.left.arrow.right"
        case .draft: "person.badge.plus"
        case .milestone: "star"
        case .award: "trophy"
        case .hotSeat: "flame"
        case .retirement: "hand.wave"
        case .staff: "person.2"
        case .league: "newspaper"
        }
    }
}

public struct NewsItem: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let year: Int
    public let week: Int
    public let category: NewsCategory
    public let headline: String
    public let body: String
    public let teamIDs: [UUID]

    public init(
        id: UUID = UUID(),
        year: Int,
        week: Int,
        category: NewsCategory,
        headline: String,
        body: String = "",
        teamIDs: [UUID] = []
    ) {
        self.id = id
        self.year = year
        self.week = week
        self.category = category
        self.headline = headline
        self.body = body
        self.teamIDs = teamIDs
    }
}

/// A finished season, kept for history screens, records and the Hall of Fame.
public struct SeasonSummary: Codable, Sendable, Equatable {
    public let year: Int
    public let championTeamID: UUID?
    public let runnerUpTeamID: UUID?
    public let standings: [UUID: TeamRecord]
    public let playerStats: [UUID: StatLine]
    public let awards: [SeasonAward]
    public let userRecord: TeamRecord?

    public init(
        year: Int,
        championTeamID: UUID?,
        runnerUpTeamID: UUID?,
        standings: [UUID: TeamRecord],
        playerStats: [UUID: StatLine],
        awards: [SeasonAward] = [],
        userRecord: TeamRecord? = nil
    ) {
        self.year = year
        self.championTeamID = championTeamID
        self.runnerUpTeamID = runnerUpTeamID
        self.standings = standings
        self.playerStats = playerStats
        self.awards = awards
        self.userRecord = userRecord
    }
}

public enum AwardKind: String, Codable, CaseIterable, Sendable {
    case mostValuablePlayer
    case offensivePlayerOfTheYear
    case defensivePlayerOfTheYear
    case offensiveRookieOfTheYear
    case defensiveRookieOfTheYear
    case coachOfTheYear

    public var displayName: String {
        switch self {
        case .mostValuablePlayer: "Most Valuable Player"
        case .offensivePlayerOfTheYear: "Offensive Player of the Year"
        case .defensivePlayerOfTheYear: "Defensive Player of the Year"
        case .offensiveRookieOfTheYear: "Offensive Rookie of the Year"
        case .defensiveRookieOfTheYear: "Defensive Rookie of the Year"
        case .coachOfTheYear: "Coach of the Year"
        }
    }
}

public struct SeasonAward: Codable, Sendable, Equatable {
    public let kind: AwardKind
    public let year: Int
    public let playerID: UUID?
    public let playerName: String
    public let teamID: UUID?

    public init(kind: AwardKind, year: Int, playerID: UUID?, playerName: String, teamID: UUID?) {
        self.kind = kind
        self.year = year
        self.playerID = playerID
        self.playerName = playerName
        self.teamID = teamID
    }
}

/// Win-loss bookkeeping for one team in one season.
public struct TeamRecord: Codable, Sendable, Equatable {
    public var wins = 0
    public var losses = 0
    public var ties = 0
    public var divisionWins = 0
    public var divisionLosses = 0
    public var conferenceWins = 0
    public var conferenceLosses = 0
    public var pointsFor = 0
    public var pointsAgainst = 0

    public init() {}

    public var gamesPlayed: Int { wins + losses + ties }

    /// Ties count as half a win, as they do in real standings.
    public var winPercentage: Double {
        gamesPlayed == 0 ? 0 : (Double(wins) + Double(ties) * 0.5) / Double(gamesPlayed)
    }

    public var pointDifferential: Int { pointsFor - pointsAgainst }

    public var description: String {
        ties > 0 ? "\(wins)-\(losses)-\(ties)" : "\(wins)-\(losses)"
    }

    public var divisionDescription: String { "\(divisionWins)-\(divisionLosses)" }
    public var conferenceDescription: String { "\(conferenceWins)-\(conferenceLosses)" }
}

/// The entire save state. One value type: simulate on a copy, assign the result back.
public struct League: Codable, Sendable {
    /// Bumped whenever the on-disk shape changes; `SaveMigrator` switches on it.
    public static let currentVersion = 1

    public var version: Int
    public var rng: SeededRandom
    public var year: Int
    public var phase: SeasonPhase
    public var teams: [Team]
    public var schedule: [ScheduledGame]
    public var results: [GameRecord]
    public var standings: [UUID: TeamRecord]
    public var freeAgents: [Player]
    public var news: [NewsItem]
    public var userTeamID: UUID
    public var coach: CoachProfile
    public var settings: LeagueSettings
    public var history: [SeasonSummary]
    public var salaryCap: Int
    /// Dead money each team carries this year from cuts and trades.
    public var deadMoney: [UUID: Int]
    /// Players enshrined after their careers ended.
    public var hallOfFame: [HallOfFamer]

    public init(
        version: Int = League.currentVersion,
        rng: SeededRandom,
        year: Int,
        phase: SeasonPhase = .preseason,
        teams: [Team],
        schedule: [ScheduledGame] = [],
        results: [GameRecord] = [],
        standings: [UUID: TeamRecord] = [:],
        freeAgents: [Player] = [],
        news: [NewsItem] = [],
        userTeamID: UUID,
        coach: CoachProfile,
        settings: LeagueSettings = LeagueSettings(),
        history: [SeasonSummary] = [],
        salaryCap: Int = LeagueRules.salaryCapYearOne,
        deadMoney: [UUID: Int] = [:],
        hallOfFame: [HallOfFamer] = []
    ) {
        self.version = version
        self.rng = rng
        self.year = year
        self.phase = phase
        self.teams = teams
        self.schedule = schedule
        self.results = results
        self.standings = standings
        self.freeAgents = freeAgents
        self.news = news
        self.userTeamID = userTeamID
        self.coach = coach
        self.settings = settings
        self.history = history
        self.salaryCap = salaryCap
        self.deadMoney = deadMoney
        self.hallOfFame = hallOfFame
    }

    public func team(id: UUID) -> Team? { teams.first { $0.id == id } }

    public var userTeam: Team? { team(id: userTeamID) }

    public func record(for teamID: UUID) -> TeamRecord { standings[teamID] ?? TeamRecord() }

    public func teams(in conference: Conference) -> [Team] {
        teams.filter { $0.conference == conference }
    }

    public func teams(in conference: Conference, division: Division) -> [Team] {
        teams.filter { $0.conference == conference && $0.division == division }
    }

    /// Finds the player anywhere in the league, including free agency.
    public func findPlayer(id: UUID) -> (player: Player, teamID: UUID?)? {
        for team in teams {
            if let player = team.player(id: id) { return (player, team.id) }
        }
        if let player = freeAgents.first(where: { $0.id == id }) { return (player, nil) }
        return nil
    }

    public mutating func update(_ team: Team) {
        guard let index = teams.firstIndex(where: { $0.id == team.id }) else { return }
        teams[index] = team
    }

    public func games(inWeek week: Int) -> [ScheduledGame] {
        schedule.filter { $0.week == week }
    }

    public func result(for scheduledGameID: UUID) -> GameRecord? {
        results.first { $0.scheduledGameID == scheduledGameID }
    }

    public func hasPlayed(_ game: ScheduledGame) -> Bool {
        results.contains { $0.scheduledGameID == game.id }
    }

    /// Season-to-date statistics for one player, folded from this year's game records.
    public func seasonStats(for playerID: UUID) -> StatLine {
        results.reduce(into: StatLine()) { total, record in
            if let line = record.playerStats[playerID] { total.add(line) }
        }
    }

    /// Career statistics: this season plus every archived season.
    public func careerStats(for playerID: UUID) -> StatLine {
        var total = seasonStats(for: playerID)
        for season in history {
            if let line = season.playerStats[playerID] { total.add(line) }
        }
        return total
    }
}
