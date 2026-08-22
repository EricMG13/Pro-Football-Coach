import Foundation

public enum DriveOutcomeBucket: Int, Codable, Sendable, CaseIterable {
    case touchdown
    case fieldGoalMade
    case fieldGoalMissed
    case punt
    case turnover
    case downs
    case safety
    case periodExpiry

    public var label: String {
        switch self {
        case .touchdown: return "touchdown"
        case .fieldGoalMade: return "made field goal"
        case .fieldGoalMissed: return "missed field goal"
        case .punt: return "punt"
        case .turnover: return "turnover"
        case .downs: return "downs"
        case .safety: return "safety"
        case .periodExpiry: return "half/game expiry"
        }
    }
}

public struct DriveOutcomeStatistics: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey { case counts }

    private var counts: [Int]

    public init() {
        counts = Array(repeating: 0, count: DriveOutcomeBucket.allCases.count)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decodeIfPresent([Int].self, forKey: .counts) ?? []
        var remaining = MatchupRules.maximumDrivesPerGame
        counts = DriveOutcomeBucket.allCases.map { bucket in
            let count = min(
                remaining,
                max(0, decoded.indices.contains(bucket.rawValue) ? decoded[bucket.rawValue] : 0)
            )
            remaining -= count
            return count
        }
    }

    mutating func record(_ bucket: DriveOutcomeBucket) {
        guard total < MatchupRules.maximumDrivesPerGame else { return }
        counts[bucket.rawValue] += 1
    }

    public func count(in bucket: DriveOutcomeBucket) -> Int {
        counts[bucket.rawValue]
    }

    public var total: Int { counts.reduce(0, +) }
}

public enum FieldGoalDistanceBucket: Int, Codable, Sendable, CaseIterable {
    case under30
    case from30To39
    case from40To49
    case atLeast50

    public init(distanceYards: Int) {
        switch max(0, distanceYards) {
        case ..<30: self = .under30
        case 30..<40: self = .from30To39
        case 40..<50: self = .from40To49
        default: self = .atLeast50
        }
    }

    public var label: String {
        switch self {
        case .under30: return "under 30"
        case .from30To39: return "30–39"
        case .from40To49: return "40–49"
        case .atLeast50: return "50+"
        }
    }
}

public struct FieldGoalStatistics: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey { case attempts, made }

    private var attempts: [Int]
    private var made: [Int]

    public init() {
        attempts = Array(repeating: 0, count: FieldGoalDistanceBucket.allCases.count)
        made = attempts
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedAttempts = try container.decodeIfPresent([Int].self, forKey: .attempts) ?? []
        let decodedMade = try container.decodeIfPresent([Int].self, forKey: .made) ?? []
        let normalizedAttempts = FieldGoalDistanceBucket.allCases.map { bucket in
            max(0, decodedAttempts.indices.contains(bucket.rawValue)
                ? decodedAttempts[bucket.rawValue] : 0)
        }
        attempts = normalizedAttempts
        made = FieldGoalDistanceBucket.allCases.map { bucket in
            min(
                normalizedAttempts[bucket.rawValue],
                max(0, decodedMade.indices.contains(bucket.rawValue)
                    ? decodedMade[bucket.rawValue] : 0)
            )
        }
    }

    mutating func record(_ bucket: FieldGoalDistanceBucket, made wasMade: Bool) {
        attempts[bucket.rawValue] += 1
        if wasMade { made[bucket.rawValue] += 1 }
    }

    public func attempts(in bucket: FieldGoalDistanceBucket) -> Int {
        attempts[bucket.rawValue]
    }

    public func made(in bucket: FieldGoalDistanceBucket) -> Int {
        made[bucket.rawValue]
    }
}

public struct TeamGameStatistics: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case points, offensiveYards, passingYards, rushingYards, turnovers, offensivePlays
        case passAttempts, passCompletions, sacks, explosivePlays, fieldGoals
    }

    public let points: Int
    public let offensiveYards: Int
    public let passingYards: Int
    public let rushingYards: Int
    public let turnovers: Int
    public let offensivePlays: Int
    public let passAttempts: Int
    public let passCompletions: Int
    public let sacks: Int
    public let explosivePlays: Int
    public let fieldGoals: FieldGoalStatistics

    public init(
        points: Int,
        offensiveYards: Int,
        passingYards: Int,
        rushingYards: Int,
        turnovers: Int,
        offensivePlays: Int = 0,
        passAttempts: Int = 0,
        passCompletions: Int = 0,
        sacks: Int = 0,
        explosivePlays: Int = 0,
        fieldGoals: FieldGoalStatistics = FieldGoalStatistics()
    ) {
        self.points = max(0, points)
        self.offensiveYards = max(0, offensiveYards)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.turnovers = max(0, turnovers)
        self.offensivePlays = max(0, offensivePlays)
        self.passAttempts = max(0, passAttempts)
        self.passCompletions = min(self.passAttempts, max(0, passCompletions))
        self.sacks = max(0, sacks)
        self.explosivePlays = min(self.offensivePlays, max(0, explosivePlays))
        self.fieldGoals = fieldGoals
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            points: try container.decode(Int.self, forKey: .points),
            offensiveYards: try container.decode(Int.self, forKey: .offensiveYards),
            passingYards: try container.decode(Int.self, forKey: .passingYards),
            rushingYards: try container.decode(Int.self, forKey: .rushingYards),
            turnovers: try container.decode(Int.self, forKey: .turnovers),
            offensivePlays: try container.decodeIfPresent(Int.self, forKey: .offensivePlays) ?? 0,
            passAttempts: try container.decodeIfPresent(Int.self, forKey: .passAttempts) ?? 0,
            passCompletions: try container.decodeIfPresent(Int.self, forKey: .passCompletions) ?? 0,
            sacks: try container.decodeIfPresent(Int.self, forKey: .sacks) ?? 0,
            explosivePlays: try container.decodeIfPresent(Int.self, forKey: .explosivePlays) ?? 0,
            fieldGoals: try container.decodeIfPresent(FieldGoalStatistics.self, forKey: .fieldGoals)
                ?? FieldGoalStatistics()
        )
    }
}

public struct PlayerGameStatistics: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case playerID, passingYards, rushingYards, receivingYards, touchdowns, targets, carries
    }

    public let playerID: UUID
    public let passingYards: Int
    public let rushingYards: Int
    public let receivingYards: Int
    public let touchdowns: Int
    public let targets: Int
    public let carries: Int

    public init(
        playerID: UUID,
        passingYards: Int = 0,
        rushingYards: Int = 0,
        receivingYards: Int = 0,
        touchdowns: Int = 0,
        targets: Int = 0,
        carries: Int = 0
    ) {
        self.playerID = playerID
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.receivingYards = max(0, receivingYards)
        self.touchdowns = max(0, touchdowns)
        let maximumPlays = MatchupRules.maximumDrivesPerGame * MatchupRules.maximumPlaysPerDrive
        self.targets = min(maximumPlays, max(0, targets))
        self.carries = min(maximumPlays, max(0, carries))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            playerID: try container.decode(UUID.self, forKey: .playerID),
            passingYards: try container.decode(Int.self, forKey: .passingYards),
            rushingYards: try container.decode(Int.self, forKey: .rushingYards),
            receivingYards: try container.decode(Int.self, forKey: .receivingYards),
            touchdowns: try container.decode(Int.self, forKey: .touchdowns),
            targets: try container.decodeIfPresent(Int.self, forKey: .targets) ?? 0,
            carries: try container.decodeIfPresent(Int.self, forKey: .carries) ?? 0
        )
    }
}

public struct StandingRow: Codable, Sendable, Equatable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case id, wins, losses, ties, conferenceWins, conferenceLosses, conferenceTies
        case pointsFor, pointsAgainst
    }

    public let id: UUID
    public private(set) var wins: Int
    public private(set) var losses: Int
    public private(set) var ties: Int
    public private(set) var conferenceWins: Int
    public private(set) var conferenceLosses: Int
    public private(set) var conferenceTies: Int
    public private(set) var pointsFor: Int
    public private(set) var pointsAgainst: Int

    public init(
        id: UUID,
        wins: Int = 0,
        losses: Int = 0,
        ties: Int = 0,
        conferenceWins: Int = 0,
        conferenceLosses: Int = 0,
        conferenceTies: Int = 0,
        pointsFor: Int = 0,
        pointsAgainst: Int = 0
    ) {
        self.id = id
        self.wins = max(0, wins)
        self.losses = max(0, losses)
        self.ties = max(0, ties)
        self.conferenceWins = max(0, conferenceWins)
        self.conferenceLosses = max(0, conferenceLosses)
        self.conferenceTies = max(0, conferenceTies)
        self.pointsFor = max(0, pointsFor)
        self.pointsAgainst = max(0, pointsAgainst)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            wins: try container.decode(Int.self, forKey: .wins),
            losses: try container.decode(Int.self, forKey: .losses),
            ties: try container.decodeIfPresent(Int.self, forKey: .ties) ?? 0,
            conferenceWins: try container.decode(Int.self, forKey: .conferenceWins),
            conferenceLosses: try container.decode(Int.self, forKey: .conferenceLosses),
            conferenceTies: try container.decodeIfPresent(Int.self, forKey: .conferenceTies) ?? 0,
            pointsFor: try container.decode(Int.self, forKey: .pointsFor),
            pointsAgainst: try container.decode(Int.self, forKey: .pointsAgainst)
        )
    }

    public var games: Int { wins + losses + ties }
    public var conferenceGames: Int { conferenceWins + conferenceLosses + conferenceTies }
    public var winningPercentage: Double {
        guard games > 0 else { return 0 }
        return (Double(wins) + Double(ties) * 0.5) / Double(games)
    }
    public var pointDifferential: Int { pointsFor - pointsAgainst }

    public mutating func record(
        pointsFor: Int,
        pointsAgainst: Int,
        conferenceGame: Bool = false
    ) {
        if pointsFor > pointsAgainst {
            wins += 1
            if conferenceGame { conferenceWins += 1 }
        } else if pointsFor == pointsAgainst {
            ties += 1
            if conferenceGame { conferenceTies += 1 }
        } else {
            losses += 1
            if conferenceGame { conferenceLosses += 1 }
        }
        self.pointsFor += max(0, pointsFor)
        self.pointsAgainst += max(0, pointsAgainst)
    }
}

public struct TeamSeasonStatistics: Codable, Sendable, Equatable {
    public private(set) var games: Int
    public private(set) var points: Int
    public private(set) var offensiveYards: Int
    public private(set) var passingYards: Int
    public private(set) var rushingYards: Int
    public private(set) var turnovers: Int

    public init(
        games: Int = 0,
        points: Int = 0,
        offensiveYards: Int = 0,
        passingYards: Int = 0,
        rushingYards: Int = 0,
        turnovers: Int = 0
    ) {
        self.games = max(0, games)
        self.points = max(0, points)
        self.offensiveYards = max(0, offensiveYards)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.turnovers = max(0, turnovers)
    }

    public mutating func record(_ game: TeamGameStatistics) {
        games += 1
        points += game.points
        offensiveYards += game.offensiveYards
        passingYards += game.passingYards
        rushingYards += game.rushingYards
        turnovers += game.turnovers
    }
}

public struct PlayerSeasonStatistics: Codable, Sendable, Equatable {
    public let playerID: UUID
    public private(set) var games: Int
    public private(set) var passingYards: Int
    public private(set) var rushingYards: Int
    public private(set) var receivingYards: Int
    public private(set) var touchdowns: Int

    public init(
        playerID: UUID,
        games: Int = 0,
        passingYards: Int = 0,
        rushingYards: Int = 0,
        receivingYards: Int = 0,
        touchdowns: Int = 0
    ) {
        self.playerID = playerID
        self.games = max(0, games)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.receivingYards = max(0, receivingYards)
        self.touchdowns = max(0, touchdowns)
    }

    public mutating func recordAppearance() {
        games += 1
    }

    public mutating func recordProduction(_ game: PlayerGameStatistics) {
        passingYards += game.passingYards
        rushingYards += game.rushingYards
        receivingYards += game.receivingYards
        touchdowns += game.touchdowns
    }
}
