import Foundation

/// Every tunable constant in the simulation. Nothing in the engine hard-codes a number that
/// a designer might want to change — it lives here, named, in one file.
public enum LeagueRules {

    // MARK: - Roster

    public static let activeRosterSize = 53
    public static let practiceSquadSize = 16
    public static var fullRosterSize: Int { activeRosterSize + practiceSquadSize }

    /// How many unsigned players the league carries between seasons. Without a ceiling the pool
    /// grows by every cut and every expiring contract forever — nine thousand of them after ten
    /// seasons — which bloats the save and makes every free-agency scan slower each year.
    public static let freeAgentPoolLimit = 400
    /// An unsigned player this old has run out of league.
    public static let freeAgentRetirementAge = 36
    /// How many stories the feed keeps. A decade of every signing in the league is not a feed.
    public static let newsFeedLimit = 500

    public static let ratingFloor = 40
    public static let ratingCeiling = 99
    public static var ratingRange: ClosedRange<Int> { ratingFloor...ratingCeiling }

    // MARK: - League shape

    public static let teamCount = 32
    public static let divisionsPerConference = 4
    public static let teamsPerDivision = 4

    // MARK: - Season

    public static let regularSeasonGames = 17
    public static let seasonWeeks = 18
    public static let divisionGamesPerTeam = 6
    public static let earliestByeWeek = 5
    public static let latestByeWeek = 14
    public static let tradeDeadlineWeek = 9
    public static let preseasonGames = 3

    // MARK: - Playoffs

    public static let playoffTeamsPerConference = 7
    /// Regular-season overtime is capped; playoff games repeat until decided.
    public static let regularSeasonOvertimePeriods = 1
    public static let overtimeLengthSeconds = 600

    // MARK: - Money (integer dollars everywhere — no floating-point currency)

    public static let salaryCapYearOne = 260_000_000
    public static let capGrowthRange: ClosedRange<Double> = 1.05...1.08
    public static let minimumSalaryYoung = 900_000
    public static let minimumSalaryVeteran = 1_200_000
    public static let veteranMinimumAge = 26
    public static let practiceSquadSalary = 250_000
    /// AI teams must spend at least this share of the cap — keeps the market liquid.
    public static let aiCapFloorShare = 0.89
    public static let maxContractYears = 5
    public static let maxBonusProrationYears = 5

    // MARK: - Staff

    public static let staffBudgetRange: ClosedRange<Int> = 14_000_000...30_000_000

    // MARK: - Draft

    public static let draftRounds = 7
    public static var draftPickCount: Int { draftRounds * teamCount }
    public static let undraftedPoolSize = 80
    public static let scoutingPointsPerSeason = 120
    public static let rookieAgeRange: ClosedRange<Int> = 21...23

    // MARK: - Game clock

    public static let quarterLengthSeconds = 900
    public static let timeoutsPerHalf = 3
    public static let playClockSeconds = 40
    public static let fieldLengthYards = 100
    public static let touchbackYardLine = 25
    public static let firstDownYards = 10

    // MARK: - Scoring

    public static let touchdownPoints = 6
    public static let extraPointPoints = 1
    public static let twoPointConversionPoints = 2
    public static let fieldGoalPoints = 3
    public static let safetyPoints = 2

    // MARK: - Position value

    /// Multiplier applied to market salary. Quarterbacks are the premium; specialists are not.
    public static func positionSalaryPremium(_ position: Position) -> Double {
        switch position {
        case .qb: 2.2
        case .dl: 1.35
        case .wr, .cb, .ol: 1.2
        case .te, .lb: 1.0
        case .rb, .s: 0.9
        case .k, .p: 0.35
        }
    }

    /// Peak-performance window. Development runs up to it, decline follows it.
    public static func peakAgeWindow(_ position: Position) -> ClosedRange<Int> {
        switch position {
        case .qb: 26...32
        case .rb: 23...27
        case .wr, .cb: 24...29
        case .ol, .dl, .lb, .te, .s: 25...30
        case .k, .p: 25...36
        }
    }

    /// Weights used to collapse a rating set into a single overall. Each set sums to 1.0 and
    /// only references attributes the position actually carries.
    public static func overallWeights(for position: Position) -> [Attribute: Double] {
        switch position {
        case .qb:
            [.throwAccuracy: 0.30, .throwPower: 0.20, .awareness: 0.25,
             .agility: 0.10, .speed: 0.10, .strength: 0.05]
        case .rb:
            [.speed: 0.24, .agility: 0.20, .breakTackle: 0.20, .vision: 0.16,
             .catching: 0.10, .strength: 0.06, .awareness: 0.04]
        case .wr:
            [.catching: 0.26, .routeRunning: 0.24, .speed: 0.22, .agility: 0.14,
             .breakTackle: 0.08, .awareness: 0.04, .strength: 0.02]
        case .te:
            [.catching: 0.24, .routeRunning: 0.18, .blockShed: 0.16, .strength: 0.14,
             .speed: 0.12, .breakTackle: 0.08, .agility: 0.05, .awareness: 0.03]
        case .ol:
            [.passBlock: 0.36, .runBlock: 0.32, .strength: 0.18,
             .awareness: 0.08, .agility: 0.04, .speed: 0.02]
        case .dl:
            [.passRush: 0.30, .blockShed: 0.24, .strength: 0.20, .tackle: 0.14,
             .speed: 0.06, .agility: 0.04, .awareness: 0.02]
        case .lb:
            [.tackle: 0.28, .coverage: 0.22, .blockShed: 0.16, .speed: 0.14,
             .awareness: 0.10, .strength: 0.07, .agility: 0.03]
        case .cb:
            [.coverage: 0.38, .speed: 0.26, .agility: 0.16, .awareness: 0.10,
             .tackle: 0.07, .strength: 0.03]
        case .s:
            [.coverage: 0.28, .tackle: 0.22, .awareness: 0.20, .speed: 0.18,
             .agility: 0.08, .strength: 0.04]
        case .k:
            [.kickAccuracy: 0.50, .kickPower: 0.35, .awareness: 0.15]
        case .p:
            [.puntAccuracy: 0.48, .puntPower: 0.37, .awareness: 0.15]
        }
    }
}
