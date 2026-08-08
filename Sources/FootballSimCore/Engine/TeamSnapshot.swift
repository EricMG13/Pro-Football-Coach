import Foundation

/// A team's depth chart, resolved once and reused for a whole game.
///
/// `Team.depthOrder(for:)` filters, sorts and builds a lookup on every call, and the simulator
/// asks for depth several times per snap — recomputing it made bulk season simulation about
/// three times slower than it needed to be. Snapshots do that work once per game and cache
/// unit ratings until an injury actually changes the picture.
public struct TeamSnapshot {
    public let team: Team
    private let depth: [Position: [Player]]
    private var unavailable: Set<UUID> = []
    private var unitRatingCache: [Position: Double] = [:]

    public init(team: Team) {
        self.team = team
        var resolved: [Position: [Player]] = [:]
        for position in Position.allCases {
            resolved[position] = team.depthOrder(for: position)
        }
        depth = resolved
    }

    public var id: UUID { team.id }
    public var abbreviation: String { team.abbreviation }

    /// Marks a player as out for the rest of this game.
    public mutating func markUnavailable(_ playerID: UUID) {
        unavailable.insert(playerID)
        unitRatingCache.removeAll(keepingCapacity: true)
    }

    public func isUnavailable(_ playerID: UUID) -> Bool { unavailable.contains(playerID) }

    /// Players at a position who can still play, in depth order.
    public func available(_ position: Position) -> ArraySlice<Player> {
        let all = depth[position] ?? []
        guard !unavailable.isEmpty else { return all[...] }
        return ArraySlice(all.filter { !unavailable.contains($0.id) })
    }

    /// The player in a given depth slot, falling back to the last available body.
    public func player(_ position: Position, slot: Int) -> Player? {
        let players = available(position)
        guard !players.isEmpty else { return depth[position]?.first }
        let index = players.index(players.startIndex, offsetBy: min(slot, players.count - 1))
        return players[index]
    }

    /// Mean effective overall of the players currently starting at a position.
    public mutating func unitRating(_ position: Position) -> Double {
        if let cached = unitRatingCache[position] { return cached }
        let starters = available(position).prefix(position.starterCount)
        let value: Double
        if starters.isEmpty {
            value = Double(LeagueRules.ratingFloor)
        } else {
            value = Double(starters.reduce(0) { $0 + $1.effectiveOverall }) / Double(starters.count)
        }
        unitRatingCache[position] = value
        return value
    }

    /// Weighted blend of unit ratings. The weights arrive in a fixed order, which keeps the
    /// floating-point summation stable — see the note on `Ratings.overall`.
    public mutating func weightedRating(_ weights: PlayMatrix.UnitWeights) -> Double {
        var total = 0.0
        for entry in weights { total += unitRating(entry.position) * entry.weight }
        return total
    }

    public func coordinatorBonus(_ role: StaffRole) -> Double {
        team.staff(role)?.unitBonus(
            offense: team.offensiveScheme,
            defense: team.defensiveScheme
        ) ?? 0
    }

    public func coordinatorQuality(_ role: StaffRole) -> Double {
        team.staff(role)?.playCallQuality ?? 0.7
    }
}
