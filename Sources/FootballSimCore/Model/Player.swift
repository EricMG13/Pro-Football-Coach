import Foundation

/// Development ceiling. Visible for players on your own roster; fogged for draft prospects
/// until scouted — the letter is what turns a draft pick into a decision.
public enum PotentialGrade: String, Codable, CaseIterable, Sendable, Comparable {
    case aPlus = "A+"
    case a = "A"
    case bPlus = "B+"
    case b = "B"
    case cPlus = "C+"
    case c = "C"
    case d = "D"
    case f = "F"

    /// Scales how fast a young player gains and how gently an old one declines.
    public var developmentMultiplier: Double {
        switch self {
        case .aPlus: 1.60
        case .a: 1.45
        case .bPlus: 1.30
        case .b: 1.15
        case .cPlus: 1.00
        case .c: 0.90
        case .d: 0.75
        case .f: 0.60
        }
    }

    /// How many overall points above the player's current rating they can still reach.
    public var ceilingBonus: Int {
        switch self {
        case .aPlus: 22
        case .a: 18
        case .bPlus: 15
        case .b: 12
        case .cPlus: 9
        case .c: 7
        case .d: 4
        case .f: 2
        }
    }

    private var order: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    /// Higher grade compares greater, so `max()` picks the better prospect.
    public static func < (lhs: PotentialGrade, rhs: PotentialGrade) -> Bool {
        lhs.order > rhs.order
    }
}

/// Rare modifiers that give a roster texture. At most two per player, on roughly a quarter
/// of the league.
public enum Trait: String, Codable, CaseIterable, Sendable {
    case clutch
    case injuryProne
    case ironMan
    case leader
    case mercenary
    case loyal
    case lateBloomer
    case boomBust

    public var displayName: String {
        switch self {
        case .clutch: "Clutch"
        case .injuryProne: "Injury Prone"
        case .ironMan: "Iron Man"
        case .leader: "Locker-Room Leader"
        case .mercenary: "Mercenary"
        case .loyal: "Loyal"
        case .lateBloomer: "Late Bloomer"
        case .boomBust: "Boom or Bust"
        }
    }

    public var detail: String {
        switch self {
        case .clutch: "Raises his game late in one-score games."
        case .injuryProne: "Gets hurt more often than he should."
        case .ironMan: "Shrugs off contact that sidelines other players."
        case .leader: "Lifts the morale of everyone around him."
        case .mercenary: "Signs wherever the money is."
        case .loyal: "Takes a discount to stay put."
        case .lateBloomer: "Keeps improving well past the usual age."
        case .boomBust: "Spectacular and infuriating, often in the same quarter."
        }
    }
}

/// A player's rated skills. Only the position's own attributes are stored.
public struct Ratings: Codable, Sendable, Equatable {
    public private(set) var values: [Attribute: Int]

    public init(values: [Attribute: Int]) {
        self.values = values.mapValues { $0.clampedToRating() }
    }

    public subscript(attribute: Attribute) -> Int {
        get { values[attribute] ?? LeagueRules.ratingFloor }
        set { values[attribute] = newValue.clampedToRating() }
    }

    /// Weighted mean over the position's attributes, rounded to an integer 40...99.
    public func overall(for position: Position) -> Int {
        let weights = LeagueRules.overallWeights(for: position)
        let total = weights.reduce(0.0) { sum, entry in
            sum + Double(self[entry.key]) * entry.value
        }
        return Int(total.rounded()).clampedToRating()
    }

    /// Shifts every attribute by `delta`, respecting the rating bounds.
    public mutating func adjustAll(by delta: Int) {
        for key in values.keys { values[key] = (values[key]! + delta).clampedToRating() }
    }
}

extension Int {
    func clampedToRating() -> Int {
        Swift.min(Swift.max(self, LeagueRules.ratingFloor), LeagueRules.ratingCeiling)
    }
}

/// Where a player entered the league. Shown on his card forever.
public struct DraftOrigin: Codable, Sendable, Equatable {
    public let year: Int
    public let round: Int
    public let pickInRound: Int

    public init(year: Int, round: Int, pickInRound: Int) {
        self.year = year
        self.round = round
        self.pickInRound = pickInRound
    }

    /// `nil` round marks an undrafted free agent.
    public var isUndrafted: Bool { round <= 0 }

    public var label: String {
        isUndrafted ? "UDFA \(year)" : "R\(round) P\(pickInRound) \(year)"
    }
}

/// One football player. Season and career statistics deliberately live outside this type —
/// they are folded from game records — which keeps saves small and players cheap to copy.
public struct Player: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var position: Position
    public var age: Int
    public var yearsPro: Int
    public var jersey: Int
    public var heightInches: Int
    public var weightPounds: Int
    public var college: String
    public var draftOrigin: DraftOrigin?
    public var ratings: Ratings
    public var potential: PotentialGrade
    public var traits: [Trait]
    /// 0...100. Extremes nudge on-field performance and drive contract behaviour.
    public var morale: Int
    /// 0 means available. Counts down one per played week.
    public var injuryWeeksRemaining: Int
    public var contract: Contract?
    /// Practice-squad players are on the roster but not the active 53.
    public var isOnPracticeSquad: Bool

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        position: Position,
        age: Int,
        yearsPro: Int,
        jersey: Int,
        heightInches: Int,
        weightPounds: Int,
        college: String,
        draftOrigin: DraftOrigin? = nil,
        ratings: Ratings,
        potential: PotentialGrade,
        traits: [Trait] = [],
        morale: Int = 70,
        injuryWeeksRemaining: Int = 0,
        contract: Contract? = nil,
        isOnPracticeSquad: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.position = position
        self.age = age
        self.yearsPro = yearsPro
        self.jersey = jersey
        self.heightInches = heightInches
        self.weightPounds = weightPounds
        self.college = college
        self.draftOrigin = draftOrigin
        self.ratings = ratings
        self.potential = potential
        self.traits = traits
        self.morale = morale
        self.injuryWeeksRemaining = injuryWeeksRemaining
        self.contract = contract
        self.isOnPracticeSquad = isOnPracticeSquad
    }

    public var name: String { "\(firstName) \(lastName)" }

    public var overall: Int { ratings.overall(for: position) }

    public var isHealthy: Bool { injuryWeeksRemaining == 0 }

    public var isFreeAgent: Bool { contract == nil }

    public var isRookie: Bool { yearsPro == 0 }

    public func has(_ trait: Trait) -> Bool { traits.contains(trait) }

    public var heightDescription: String { "\(heightInches / 12)' \(heightInches % 12)\"" }

    /// Overall adjusted for morale — the number the simulation actually uses.
    /// Deliberately small: morale colours performance, it doesn't decide games.
    public var effectiveOverall: Int {
        let moraleShift: Int
        switch morale {
        case ..<25: moraleShift = -3
        case ..<40: moraleShift = -1
        case 85...: moraleShift = 3
        case 70...: moraleShift = 1
        default: moraleShift = 0
        }
        return (overall + moraleShift).clampedToRating()
    }

    /// The most a player can still develop to, given his grade.
    public var projectedCeiling: Int {
        (overall + potential.ceilingBonus).clampedToRating()
    }
}
