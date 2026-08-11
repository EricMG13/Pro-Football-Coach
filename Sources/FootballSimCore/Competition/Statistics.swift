import Foundation

public struct TeamGameStatistics: Codable, Sendable, Equatable {
    public let points: Int
    public let offensiveYards: Int
    public let passingYards: Int
    public let rushingYards: Int
    public let turnovers: Int

    public init(
        points: Int,
        offensiveYards: Int,
        passingYards: Int,
        rushingYards: Int,
        turnovers: Int
    ) {
        self.points = max(0, points)
        self.offensiveYards = max(0, offensiveYards)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.turnovers = max(0, turnovers)
    }
}

public struct PlayerGameStatistics: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let passingYards: Int
    public let rushingYards: Int
    public let receivingYards: Int
    public let touchdowns: Int

    public init(
        playerID: UUID,
        passingYards: Int = 0,
        rushingYards: Int = 0,
        receivingYards: Int = 0,
        touchdowns: Int = 0
    ) {
        self.playerID = playerID
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.receivingYards = max(0, receivingYards)
        self.touchdowns = max(0, touchdowns)
    }
}

public struct StandingRow: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public private(set) var wins: Int
    public private(set) var losses: Int
    public private(set) var conferenceWins: Int
    public private(set) var conferenceLosses: Int
    public private(set) var pointsFor: Int
    public private(set) var pointsAgainst: Int

    public init(
        id: UUID,
        wins: Int = 0,
        losses: Int = 0,
        conferenceWins: Int = 0,
        conferenceLosses: Int = 0,
        pointsFor: Int = 0,
        pointsAgainst: Int = 0
    ) {
        self.id = id
        self.wins = max(0, wins)
        self.losses = max(0, losses)
        self.conferenceWins = max(0, conferenceWins)
        self.conferenceLosses = max(0, conferenceLosses)
        self.pointsFor = max(0, pointsFor)
        self.pointsAgainst = max(0, pointsAgainst)
    }

    public var games: Int { wins + losses }
    public var conferenceGames: Int { conferenceWins + conferenceLosses }
    public var pointDifferential: Int { pointsFor - pointsAgainst }

    public mutating func record(
        pointsFor: Int,
        pointsAgainst: Int,
        conferenceGame: Bool = false
    ) {
        if pointsFor > pointsAgainst {
            wins += 1
            if conferenceGame { conferenceWins += 1 }
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
