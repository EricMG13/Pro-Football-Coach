import Foundation

public enum Conference: String, Codable, CaseIterable, Sendable, Hashable, CodingKeyRepresentable {
    case liberty, frontier

    public var displayName: String {
        switch self {
        case .liberty: "Liberty Conference"
        case .frontier: "Frontier Conference"
        }
    }

    public var abbreviation: String {
        switch self {
        case .liberty: "LFC"
        case .frontier: "FFC"
        }
    }
}

public enum Division: String, Codable, CaseIterable, Sendable, Hashable, CodingKeyRepresentable {
    case east, north, south, west

    public var displayName: String { rawValue.capitalized }
}

public enum OffensiveScheme: String, Codable, CaseIterable, Sendable {
    case westCoast, vertical, spread, powerRun, balanced

    public var displayName: String {
        switch self {
        case .westCoast: "West Coast"
        case .vertical: "Vertical"
        case .spread: "Spread"
        case .powerRun: "Power Run"
        case .balanced: "Balanced"
        }
    }
}

public enum DefensiveScheme: String, Codable, CaseIterable, Sendable {
    case fourThree, threeFour, nickelBase

    public var displayName: String {
        switch self {
        case .fourThree: "4-3"
        case .threeFour: "3-4"
        case .nickelBase: "Nickel Base"
        }
    }
}

/// How an AI front office behaves in free agency, trades and the draft.
public enum AIPersonality: String, Codable, CaseIterable, Sendable {
    case winNow, balanced, rebuilder, capHawk

    public var displayName: String {
        switch self {
        case .winNow: "Win Now"
        case .balanced: "Balanced"
        case .rebuilder: "Rebuilder"
        case .capHawk: "Cap Hawk"
        }
    }

    /// Preference for proven veterans over young players with upside.
    public var veteranPreference: Double {
        switch self {
        case .winNow: 1.35
        case .balanced: 1.0
        case .rebuilder: 0.65
        case .capHawk: 0.9
        }
    }

    /// How far above even value the AI insists on before accepting a trade.
    public var tradeSurplusRequired: Double {
        switch self {
        case .winNow: 1.02
        case .balanced: 1.05
        case .rebuilder: 1.08
        case .capHawk: 1.06
        }
    }
}

public struct TeamColors: Codable, Sendable, Equatable {
    public let primaryHex: String
    public let secondaryHex: String

    public init(primaryHex: String, secondaryHex: String) {
        self.primaryHex = primaryHex
        self.secondaryHex = secondaryHex
    }
}

/// One franchise: identity, roster, depth chart, staff and front-office personality.
public struct Team: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var city: String
    public var name: String
    public var abbreviation: String
    public var colors: TeamColors
    public var conference: Conference
    public var division: Division
    public var stadiumName: String
    public var roster: [Player]
    /// Ordered player IDs per position; index 0 starts. Missing entries fall back to rating order.
    public var depthChart: [Position: [UUID]]
    public var staff: [StaffMember]
    public var offensiveScheme: OffensiveScheme
    public var defensiveScheme: DefensiveScheme
    /// 1...100. Drives free-agent interest and how attractive the head-coaching job is.
    public var reputation: Int
    /// 1...5. How long the owner tolerates losing.
    public var ownerPatience: Int
    public var aiPersonality: AIPersonality
    public var staffBudget: Int

    public init(
        id: UUID = UUID(),
        city: String,
        name: String,
        abbreviation: String,
        colors: TeamColors,
        conference: Conference,
        division: Division,
        stadiumName: String,
        roster: [Player] = [],
        depthChart: [Position: [UUID]] = [:],
        staff: [StaffMember] = [],
        offensiveScheme: OffensiveScheme = .balanced,
        defensiveScheme: DefensiveScheme = .fourThree,
        reputation: Int = 50,
        ownerPatience: Int = 3,
        aiPersonality: AIPersonality = .balanced,
        staffBudget: Int = 20_000_000
    ) {
        self.id = id
        self.city = city
        self.name = name
        self.abbreviation = abbreviation
        self.colors = colors
        self.conference = conference
        self.division = division
        self.stadiumName = stadiumName
        self.roster = roster
        self.depthChart = depthChart
        self.staff = staff
        self.offensiveScheme = offensiveScheme
        self.defensiveScheme = defensiveScheme
        self.reputation = reputation
        self.ownerPatience = ownerPatience
        self.aiPersonality = aiPersonality
        self.staffBudget = staffBudget
    }

    public var fullName: String { "\(city) \(name)" }

    public var activeRoster: [Player] { roster.filter { !$0.isOnPracticeSquad } }

    public var practiceSquad: [Player] { roster.filter(\.isOnPracticeSquad) }

    public func player(id: UUID) -> Player? { roster.first { $0.id == id } }

    public func staff(_ role: StaffRole) -> StaffMember? { staff.first { $0.role == role } }

    /// Players at a position in depth-chart order, injured players pushed to the back so the
    /// simulation always fields someone who can play.
    public func depthOrder(for position: Position, healthyOnly: Bool = true) -> [Player] {
        let pool = activeRoster.filter { $0.position == position }
        let ordered: [Player]
        if let chart = depthChart[position], !chart.isEmpty {
            let byID = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0) })
            var result = chart.compactMap { byID[$0] }
            let listed = Set(chart)
            result.append(contentsOf: pool.filter { !listed.contains($0.id) }
                .sorted { $0.overall > $1.overall })
            ordered = result
        } else {
            ordered = pool.sorted { $0.overall > $1.overall }
        }
        guard healthyOnly else { return ordered }
        return ordered.filter(\.isHealthy) + ordered.filter { !$0.isHealthy }
    }

    /// The players who take the field at a position right now.
    public func starters(at position: Position) -> [Player] {
        Array(depthOrder(for: position).prefix(position.starterCount))
    }

    /// Mean effective overall of the starters at a position, floored so a decimated unit still
    /// produces a usable number rather than crashing the sim.
    public func unitRating(at position: Position) -> Double {
        let starters = self.starters(at: position)
        guard !starters.isEmpty else { return Double(LeagueRules.ratingFloor) }
        let total = starters.reduce(0) { $0 + $1.effectiveOverall }
        return Double(total) / Double(starters.count)
    }

    private func coordinatorBonus(_ role: StaffRole) -> Double {
        staff(role)?.unitBonus(offense: offensiveScheme, defense: defensiveScheme) ?? 0
    }

    /// Weighted offensive strength, including the offensive coordinator's contribution.
    public var offenseRating: Double {
        let weights: [Position: Double] = [.qb: 0.34, .ol: 0.22, .wr: 0.20, .rb: 0.13, .te: 0.11]
        return weightedRating(weights) + coordinatorBonus(.offensiveCoordinator)
    }

    /// Weighted defensive strength, including the defensive coordinator's contribution.
    public var defenseRating: Double {
        let weights: [Position: Double] = [.dl: 0.32, .cb: 0.26, .lb: 0.24, .s: 0.18]
        return weightedRating(weights) + coordinatorBonus(.defensiveCoordinator)
    }

    public var specialTeamsRating: Double {
        let weights: [Position: Double] = [.k: 0.6, .p: 0.4]
        return weightedRating(weights) + coordinatorBonus(.specialTeamsCoordinator)
    }

    /// Headline team rating shown on cards and used for preseason projections.
    public var overallRating: Double {
        offenseRating * 0.45 + defenseRating * 0.45 + specialTeamsRating * 0.10
    }

    private func weightedRating(_ weights: [Position: Double]) -> Double {
        weights.reduce(0.0) { $0 + unitRating(at: $1.key) * $1.value }
    }

    public var injuredPlayers: [Player] { roster.filter { !$0.isHealthy } }

    /// Rebuilds the depth chart in rating order. Used at generation and by Auto-Sort.
    public mutating func autoSortDepthChart() {
        var chart: [Position: [UUID]] = [:]
        for position in Position.allCases {
            chart[position] = activeRoster
                .filter { $0.position == position }
                .sorted { $0.overall > $1.overall }
                .map(\.id)
        }
        depthChart = chart
    }

    /// Replaces a player in place, keeping roster order stable.
    public mutating func update(_ player: Player) {
        guard let index = roster.firstIndex(where: { $0.id == player.id }) else { return }
        roster[index] = player
    }
}
