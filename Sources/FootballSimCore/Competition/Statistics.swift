import Foundation

public struct TeamGameStatistics: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case points, offensiveYards, passingYards, rushingYards, turnovers, offensivePlays
    }

    public let points: Int
    public let offensiveYards: Int
    public let passingYards: Int
    public let rushingYards: Int
    public let turnovers: Int
    /// Snaps the side took. Both models report it, so `TwoTierConsistencyTests` can hold them to
    /// the same plays-per-team-game band, and so yards per play is a quantity rather than a guess.
    public let offensivePlays: Int

    public init(
        points: Int,
        offensiveYards: Int,
        passingYards: Int,
        rushingYards: Int,
        turnovers: Int,
        offensivePlays: Int = 0
    ) {
        self.points = max(0, points)
        self.offensiveYards = max(0, offensiveYards)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.turnovers = max(0, turnovers)
        self.offensivePlays = max(0, offensivePlays)
    }

    /// A save written before plays were counted decodes with zero rather than failing, the same
    /// way `StandingRow` absorbed ties.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            points: try container.decode(Int.self, forKey: .points),
            offensiveYards: try container.decode(Int.self, forKey: .offensiveYards),
            passingYards: try container.decode(Int.self, forKey: .passingYards),
            rushingYards: try container.decode(Int.self, forKey: .rushingYards),
            turnovers: try container.decode(Int.self, forKey: .turnovers),
            offensivePlays: try container.decodeIfPresent(Int.self, forKey: .offensivePlays) ?? 0
        )
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
