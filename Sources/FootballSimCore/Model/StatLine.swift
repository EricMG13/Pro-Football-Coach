import Foundation

/// Everything one player accumulated in one game. Season and career totals are folds of these,
/// so no aggregate is ever stored twice and can never drift out of sync.
public struct StatLine: Codable, Sendable, Equatable {
    // Passing
    public var passAttempts = 0
    public var completions = 0
    public var passingYards = 0
    public var passingTouchdowns = 0
    public var interceptionsThrown = 0
    public var sacksTaken = 0

    // Rushing
    public var carries = 0
    public var rushingYards = 0
    public var rushingTouchdowns = 0

    // Receiving
    public var targets = 0
    public var receptions = 0
    public var receivingYards = 0
    public var receivingTouchdowns = 0

    // Defense
    public var tackles = 0
    public var sacks = 0
    public var interceptions = 0
    public var passesDefended = 0
    public var forcedFumbles = 0
    public var fumbleRecoveries = 0

    // Kicking
    public var fieldGoalsMade = 0
    public var fieldGoalsAttempted = 0
    public var extraPointsMade = 0
    public var extraPointsAttempted = 0
    public var longestFieldGoal = 0

    // Punting
    public var punts = 0
    public var puntYards = 0

    // Ball security
    public var fumbles = 0

    public var gamesPlayed = 0

    public init() {}

    public var completionPercentage: Double {
        passAttempts == 0 ? 0 : Double(completions) / Double(passAttempts) * 100
    }

    public var yardsPerCarry: Double {
        carries == 0 ? 0 : Double(rushingYards) / Double(carries)
    }

    public var yardsPerReception: Double {
        receptions == 0 ? 0 : Double(receivingYards) / Double(receptions)
    }

    public var fieldGoalPercentage: Double {
        fieldGoalsAttempted == 0 ? 0 : Double(fieldGoalsMade) / Double(fieldGoalsAttempted) * 100
    }

    public var averagePunt: Double {
        punts == 0 ? 0 : Double(puntYards) / Double(punts)
    }

    /// Standard passer rating, clamped to its defined 0–158.3 range.
    public var passerRating: Double {
        guard passAttempts > 0 else { return 0 }
        let attempts = Double(passAttempts)
        let a = ((Double(completions) / attempts) - 0.3) * 5
        let b = ((Double(passingYards) / attempts) - 3) * 0.25
        let c = (Double(passingTouchdowns) / attempts) * 20
        let d = 2.375 - ((Double(interceptionsThrown) / attempts) * 25)
        let clamp = { (value: Double) in Swift.min(Swift.max(value, 0), 2.375) }
        return (clamp(a) + clamp(b) + clamp(c) + clamp(d)) / 6 * 100
    }

    public var totalTouchdowns: Int {
        passingTouchdowns + rushingTouchdowns + receivingTouchdowns
    }

    public var scrimmageYards: Int { rushingYards + receivingYards }

    public static func + (lhs: StatLine, rhs: StatLine) -> StatLine {
        var result = lhs
        result.add(rhs)
        return result
    }

    public mutating func add(_ other: StatLine) {
        passAttempts += other.passAttempts
        completions += other.completions
        passingYards += other.passingYards
        passingTouchdowns += other.passingTouchdowns
        interceptionsThrown += other.interceptionsThrown
        sacksTaken += other.sacksTaken
        carries += other.carries
        rushingYards += other.rushingYards
        rushingTouchdowns += other.rushingTouchdowns
        targets += other.targets
        receptions += other.receptions
        receivingYards += other.receivingYards
        receivingTouchdowns += other.receivingTouchdowns
        tackles += other.tackles
        sacks += other.sacks
        interceptions += other.interceptions
        passesDefended += other.passesDefended
        forcedFumbles += other.forcedFumbles
        fumbleRecoveries += other.fumbleRecoveries
        fieldGoalsMade += other.fieldGoalsMade
        fieldGoalsAttempted += other.fieldGoalsAttempted
        extraPointsMade += other.extraPointsMade
        extraPointsAttempted += other.extraPointsAttempted
        longestFieldGoal = Swift.max(longestFieldGoal, other.longestFieldGoal)
        punts += other.punts
        puntYards += other.puntYards
        fumbles += other.fumbles
        gamesPlayed += other.gamesPlayed
    }

    public var isEmpty: Bool { self == StatLine() }
}

// A season stores one line per player per team, and most of those lines are nearly all zeros —
// an offensive lineman records an appearance and nothing else. Writing all twenty-eight fields
// regardless made a ten-season save several times larger than it needed to be, so encoding
// skips zeros and decoding treats a missing key as zero.
extension StatLine {
    private enum CodingKeys: String, CodingKey {
        case passAttempts = "pa", completions = "cmp", passingYards = "py"
        case passingTouchdowns = "ptd", interceptionsThrown = "int", sacksTaken = "skT"
        case carries = "car", rushingYards = "ry", rushingTouchdowns = "rtd"
        case targets = "tgt", receptions = "rec", receivingYards = "recy"
        case receivingTouchdowns = "rectd"
        case tackles = "tkl", sacks = "sk", interceptions = "intD", passesDefended = "pd"
        case forcedFumbles = "ff", fumbleRecoveries = "fr"
        case fieldGoalsMade = "fgm", fieldGoalsAttempted = "fga"
        case extraPointsMade = "xpm", extraPointsAttempted = "xpa", longestFieldGoal = "lfg"
        case punts = "pnt", puntYards = "pty", fumbles = "fum", gamesPlayed = "gp"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func value(_ key: CodingKeys) throws -> Int {
            try container.decodeIfPresent(Int.self, forKey: key) ?? 0
        }
        self.init()
        passAttempts = try value(.passAttempts)
        completions = try value(.completions)
        passingYards = try value(.passingYards)
        passingTouchdowns = try value(.passingTouchdowns)
        interceptionsThrown = try value(.interceptionsThrown)
        sacksTaken = try value(.sacksTaken)
        carries = try value(.carries)
        rushingYards = try value(.rushingYards)
        rushingTouchdowns = try value(.rushingTouchdowns)
        targets = try value(.targets)
        receptions = try value(.receptions)
        receivingYards = try value(.receivingYards)
        receivingTouchdowns = try value(.receivingTouchdowns)
        tackles = try value(.tackles)
        sacks = try value(.sacks)
        interceptions = try value(.interceptions)
        passesDefended = try value(.passesDefended)
        forcedFumbles = try value(.forcedFumbles)
        fumbleRecoveries = try value(.fumbleRecoveries)
        fieldGoalsMade = try value(.fieldGoalsMade)
        fieldGoalsAttempted = try value(.fieldGoalsAttempted)
        extraPointsMade = try value(.extraPointsMade)
        extraPointsAttempted = try value(.extraPointsAttempted)
        longestFieldGoal = try value(.longestFieldGoal)
        punts = try value(.punts)
        puntYards = try value(.puntYards)
        fumbles = try value(.fumbles)
        gamesPlayed = try value(.gamesPlayed)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        func write(_ value: Int, _ key: CodingKeys) throws {
            guard value != 0 else { return }
            try container.encode(value, forKey: key)
        }
        try write(passAttempts, .passAttempts)
        try write(completions, .completions)
        try write(passingYards, .passingYards)
        try write(passingTouchdowns, .passingTouchdowns)
        try write(interceptionsThrown, .interceptionsThrown)
        try write(sacksTaken, .sacksTaken)
        try write(carries, .carries)
        try write(rushingYards, .rushingYards)
        try write(rushingTouchdowns, .rushingTouchdowns)
        try write(targets, .targets)
        try write(receptions, .receptions)
        try write(receivingYards, .receivingYards)
        try write(receivingTouchdowns, .receivingTouchdowns)
        try write(tackles, .tackles)
        try write(sacks, .sacks)
        try write(interceptions, .interceptions)
        try write(passesDefended, .passesDefended)
        try write(forcedFumbles, .forcedFumbles)
        try write(fumbleRecoveries, .fumbleRecoveries)
        try write(fieldGoalsMade, .fieldGoalsMade)
        try write(fieldGoalsAttempted, .fieldGoalsAttempted)
        try write(extraPointsMade, .extraPointsMade)
        try write(extraPointsAttempted, .extraPointsAttempted)
        try write(longestFieldGoal, .longestFieldGoal)
        try write(punts, .punts)
        try write(puntYards, .puntYards)
        try write(fumbles, .fumbles)
        try write(gamesPlayed, .gamesPlayed)
    }
}

/// Team-level totals for one game.
public struct TeamGameStats: Codable, Sendable, Equatable {
    public var points = 0
    public var quarterPoints: [Int] = [0, 0, 0, 0]
    public var passingYards = 0
    public var rushingYards = 0
    public var firstDowns = 0
    public var turnovers = 0
    public var sacks = 0
    public var penalties = 0
    public var penaltyYards = 0
    public var possessionSeconds = 0
    public var thirdDownAttempts = 0
    public var thirdDownConversions = 0
    public var plays = 0

    public init() {}

    public var totalYards: Int { passingYards + rushingYards }

    public var thirdDownRate: Double {
        thirdDownAttempts == 0 ? 0 : Double(thirdDownConversions) / Double(thirdDownAttempts)
    }
}
