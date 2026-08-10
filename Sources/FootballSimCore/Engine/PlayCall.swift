import Foundation

/// What the offence is trying to do.
public enum OffensivePlayType: String, Codable, Sendable, CaseIterable {
    case run, pass, punt, fieldGoal, kneel
}

/// How far downfield the pass is aimed. Drives which accuracy attribute the throw reads
/// (`03-MATCH-ENGINE.md` §1.2's Throw row names three).
public enum PassDepth: String, Codable, Sendable, CaseIterable {
    case short, mid, deep

    /// The accuracy attribute this depth reads.
    public var accuracy: Attribute {
        switch self {
        case .short: return .accuracyShort
        case .mid: return .accuracyMid
        case .deep: return .accuracyDeep
        }
    }

    /// Air yards, before anything the receiver does after the catch.
    public var airYards: Int {
        switch self {
        case .short: return MatchupRules.shortPassAirYards
        case .mid: return MatchupRules.midPassAirYards
        case .deep: return MatchupRules.deepPassAirYards
        }
    }
}

/// Where a run is aimed.
public enum RunGap: String, Codable, Sendable, CaseIterable {
    case insideLeft, insideRight, outsideLeft, outsideRight

    /// An outside run trades lane certainty for the chance of getting to the edge.
    public var isOutside: Bool { self == .outsideLeft || self == .outsideRight }
}

/// Tempo, which is both a clock choice and a fatigue choice. `02` §3.2 lets the coach change it
/// mid-match.
public enum Tempo: String, Codable, Sendable, CaseIterable {
    case hurry, normal, bleed

    public func snapSeconds(rules: any ClockRules.Type) -> Int {
        switch self {
        case .hurry: return rules.hurryTempoSnapSeconds
        case .normal: return rules.normalTempoSnapSeconds
        case .bleed: return rules.bleedTempoSnapSeconds
        }
    }
}

/// The offensive call.
public struct OffensiveCall: Codable, Sendable, Equatable {
    public var playType: OffensivePlayType
    public var passDepth: PassDepth
    public var runGap: RunGap
    public var tempo: Tempo
    /// -1 conservative to +1 aggressive. Moves the risk side of every resolution.
    public var aggression: Double

    public init(
        playType: OffensivePlayType,
        passDepth: PassDepth = .mid,
        runGap: RunGap = .insideLeft,
        tempo: Tempo = .normal,
        aggression: Double = 0
    ) {
        self.playType = playType
        self.passDepth = passDepth
        self.runGap = runGap
        self.tempo = tempo
        self.aggression = Swift.min(Swift.max(aggression, -1), 1)
    }
}

/// How the defence is playing it.
public enum CoverageShell: String, Codable, Sendable, CaseIterable {
    case man, zoneUnder, zoneDeep, prevent

    /// How much this shell helps against the pass, in leverage units, and what it concedes to the
    /// run. Every shell must give something up, or one of them is always right and `02` §2.2's
    /// first test for a real decision fails.
    public var passHelp: Double {
        switch self {
        case .man: return MatchupRules.manCoveragePassHelp
        case .zoneUnder: return MatchupRules.zoneUnderPassHelp
        case .zoneDeep: return MatchupRules.zoneDeepPassHelp
        case .prevent: return MatchupRules.preventPassHelp
        }
    }

    public var runCost: Double {
        switch self {
        case .man: return MatchupRules.manCoverageRunCost
        case .zoneUnder: return MatchupRules.zoneUnderRunCost
        case .zoneDeep: return MatchupRules.zoneDeepRunCost
        case .prevent: return MatchupRules.preventRunCost
        }
    }

    /// Deep shells concede the short throw and take away the long one.
    public func help(against depth: PassDepth) -> Double {
        switch (self, depth) {
        case (.zoneDeep, .short), (.prevent, .short): return -passHelp
        case (.zoneUnder, .deep): return -passHelp
        default: return passHelp
        }
    }
}

/// The defensive call.
public struct DefensiveCall: Codable, Sendable, Equatable {
    public var coverage: CoverageShell
    /// How many rush the passer. More rushers means quicker pressure and thinner coverage.
    public var rushers: Int
    /// -1 soft to +1 aggressive. Blitz timing, jumping routes, crashing the run.
    public var aggression: Double

    public init(coverage: CoverageShell, rushers: Int = 4, aggression: Double = 0) {
        self.coverage = coverage
        self.rushers = Swift.min(Swift.max(rushers, MatchupRules.minimumRushers),
                                 MatchupRules.maximumRushers)
        self.aggression = Swift.min(Swift.max(aggression, -1), 1)
    }

    /// Rushers beyond the base four come out of coverage. This is the cost that makes a blitz a
    /// decision rather than a free choice.
    public var coverageDrain: Double {
        Double(rushers - MatchupRules.baseRushers) * MatchupRules.rusherCoverageDrain
    }
}
