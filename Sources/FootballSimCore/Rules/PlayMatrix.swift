import Foundation

/// What the offense can call.
public enum OffensivePlay: String, Codable, CaseIterable, Sendable {
    case insideRun, outsideRun, shortPass, deepPass, playAction, screen
    case fieldGoal, punt, kneel, spike, twoPointConversion

    public var isPass: Bool {
        switch self {
        case .shortPass, .deepPass, .playAction, .screen: true
        default: false
        }
    }

    public var isRun: Bool { self == .insideRun || self == .outsideRun }

    /// Plays the user picks from during normal downs.
    public static let standardCalls: [OffensivePlay] =
        [.insideRun, .outsideRun, .shortPass, .deepPass, .playAction, .screen]

    public var displayName: String {
        switch self {
        case .insideRun: "Inside Run"
        case .outsideRun: "Outside Run"
        case .shortPass: "Short Pass"
        case .deepPass: "Deep Pass"
        case .playAction: "Play Action"
        case .screen: "Screen"
        case .fieldGoal: "Field Goal"
        case .punt: "Punt"
        case .kneel: "Kneel"
        case .spike: "Spike"
        case .twoPointConversion: "Two-Point Try"
        }
    }
}

/// What the defense can call.
public enum DefensivePlay: String, Codable, CaseIterable, Sendable {
    case base, blitz, nickel, dime, contain, prevent

    public var displayName: String {
        switch self {
        case .base: "Base"
        case .blitz: "Blitz"
        case .nickel: "Nickel"
        case .dime: "Dime"
        case .contain: "Contain"
        case .prevent: "Prevent"
        }
    }
}

/// How fast the offense is playing — the clock-management lever.
public enum Tempo: String, Codable, CaseIterable, Sendable {
    case normal, hurryUp, chewClock

    public var displayName: String {
        switch self {
        case .normal: "Normal"
        case .hurryUp: "Hurry-Up"
        case .chewClock: "Chew Clock"
        }
    }

    /// Seconds burned between plays.
    public var playClockSeconds: Int {
        switch self {
        case .normal: 34
        case .hurryUp: 10
        case .chewClock: 40
        }
    }

    /// Rushing the line costs a little execution; grinding it out costs a little explosiveness.
    public var yardageModifier: Double {
        switch self {
        case .normal: 0
        case .hurryUp: -0.35
        case .chewClock: -0.15
        }
    }
}

/// The base shape of a play type before any matchup adjustment.
public struct PlayProfile: Sendable {
    /// Chance the pass is caught, before adjustments.
    public let completionRate: Double
    /// Mean yards on a successful play.
    public let meanYards: Double
    public let yardsSD: Double
    /// Chance the dropback ends in a sack.
    public let sackRate: Double
    /// Chance of an interception per attempt.
    public let interceptionRate: Double
    /// Chance the ball comes loose on a run or a catch.
    public let fumbleRate: Double
    /// Probability the play breaks for a big gain on top of the normal distribution.
    public let explosiveRate: Double
    public let explosiveBonusYards: Double

    public init(
        completionRate: Double = 1,
        meanYards: Double,
        yardsSD: Double,
        sackRate: Double = 0,
        interceptionRate: Double = 0,
        fumbleRate: Double = 0,
        explosiveRate: Double = 0,
        explosiveBonusYards: Double = 0
    ) {
        self.completionRate = completionRate
        self.meanYards = meanYards
        self.yardsSD = yardsSD
        self.sackRate = sackRate
        self.interceptionRate = interceptionRate
        self.fumbleRate = fumbleRate
        self.explosiveRate = explosiveRate
        self.explosiveBonusYards = explosiveBonusYards
    }
}

/// Adjustments a defensive call applies to an offensive play.
public struct DefensiveAdjustment: Sendable {
    public let completionDelta: Double
    public let yardsDelta: Double
    public let sackMultiplier: Double
    public let interceptionMultiplier: Double
    public let explosiveMultiplier: Double

    public init(
        completionDelta: Double = 0,
        yardsDelta: Double = 0,
        sackMultiplier: Double = 1,
        interceptionMultiplier: Double = 1,
        explosiveMultiplier: Double = 1
    ) {
        self.completionDelta = completionDelta
        self.yardsDelta = yardsDelta
        self.sackMultiplier = sackMultiplier
        self.interceptionMultiplier = interceptionMultiplier
        self.explosiveMultiplier = explosiveMultiplier
    }
}

/// The rock-paper-scissors layer: base play shapes plus how each defensive call bends them.
/// Every number here is a balance dial; the calibration suite is what keeps them honest.
public enum PlayMatrix {

    public static func profile(for play: OffensivePlay) -> PlayProfile {
        switch play {
        case .insideRun:
            PlayProfile(meanYards: 3.9, yardsSD: 3.4, fumbleRate: 0.008,
                        explosiveRate: 0.030, explosiveBonusYards: 13)
        case .outsideRun:
            PlayProfile(meanYards: 4.1, yardsSD: 4.8, fumbleRate: 0.010,
                        explosiveRate: 0.048, explosiveBonusYards: 21)
        case .shortPass:
            PlayProfile(completionRate: 0.690, meanYards: 6.6, yardsSD: 4.4,
                        sackRate: 0.052, interceptionRate: 0.020, fumbleRate: 0.004,
                        explosiveRate: 0.040, explosiveBonusYards: 16)
        case .deepPass:
            PlayProfile(completionRate: 0.415, meanYards: 19.5, yardsSD: 8.5,
                        sackRate: 0.098, interceptionRate: 0.048, fumbleRate: 0.003,
                        explosiveRate: 0.125, explosiveBonusYards: 30)
        case .playAction:
            PlayProfile(completionRate: 0.620, meanYards: 10.2, yardsSD: 6.6,
                        sackRate: 0.082, interceptionRate: 0.026, fumbleRate: 0.004,
                        explosiveRate: 0.075, explosiveBonusYards: 19)
        case .screen:
            PlayProfile(completionRate: 0.780, meanYards: 5.4, yardsSD: 6.0,
                        sackRate: 0.022, interceptionRate: 0.014, fumbleRate: 0.006,
                        explosiveRate: 0.055, explosiveBonusYards: 18)
        case .twoPointConversion:
            PlayProfile(completionRate: 0.560, meanYards: 3.0, yardsSD: 2.0,
                        sackRate: 0.040, interceptionRate: 0.020)
        case .kneel:
            PlayProfile(meanYards: -1, yardsSD: 0)
        case .spike, .fieldGoal, .punt:
            PlayProfile(meanYards: 0, yardsSD: 0)
        }
    }

    public static func adjustment(
        offense: OffensivePlay,
        defense: DefensivePlay
    ) -> DefensiveAdjustment {
        switch defense {
        case .base:
            return DefensiveAdjustment()

        case .blitz:
            // Pressure wins or it loses badly: sacks way up, but a beaten blitz gives up yards.
            if offense.isPass {
                return DefensiveAdjustment(
                    completionDelta: -0.065,
                    yardsDelta: 2.6,
                    sackMultiplier: 1.95,
                    interceptionMultiplier: 1.25,
                    explosiveMultiplier: 1.45
                )
            }
            return DefensiveAdjustment(yardsDelta: -0.5, explosiveMultiplier: 1.35)

        case .nickel:
            if offense.isPass {
                return DefensiveAdjustment(completionDelta: -0.030, yardsDelta: -0.6,
                                           explosiveMultiplier: 0.85)
            }
            return DefensiveAdjustment(yardsDelta: 0.85)

        case .dime:
            if offense == .deepPass {
                return DefensiveAdjustment(completionDelta: -0.075, yardsDelta: -1.8,
                                           interceptionMultiplier: 1.3, explosiveMultiplier: 0.6)
            }
            if offense.isPass {
                return DefensiveAdjustment(completionDelta: -0.045, yardsDelta: -0.9,
                                           explosiveMultiplier: 0.7)
            }
            return DefensiveAdjustment(yardsDelta: 1.7, explosiveMultiplier: 1.25)

        case .contain:
            if offense == .outsideRun {
                return DefensiveAdjustment(yardsDelta: -1.7, explosiveMultiplier: 0.55)
            }
            if offense.isRun {
                return DefensiveAdjustment(yardsDelta: -1.0, explosiveMultiplier: 0.7)
            }
            return DefensiveAdjustment(completionDelta: 0.020, yardsDelta: 0.4, sackMultiplier: 0.75)

        case .prevent:
            // Gives up everything underneath to take away the game-losing play.
            if offense == .deepPass {
                return DefensiveAdjustment(completionDelta: -0.150, yardsDelta: -4.5,
                                           sackMultiplier: 0.7, explosiveMultiplier: 0.25)
            }
            if offense.isPass {
                return DefensiveAdjustment(completionDelta: 0.070, yardsDelta: 1.0,
                                           sackMultiplier: 0.6, explosiveMultiplier: 0.45)
            }
            return DefensiveAdjustment(yardsDelta: 2.4, explosiveMultiplier: 0.8)
        }
    }

    /// Which units decide a play, as (position, weight) pairs.
    ///
    /// Arrays rather than dictionaries, held as constants rather than rebuilt: the simulator
    /// asks for these on every snap, and allocating two dictionaries per play was the single
    /// largest cost in bulk season simulation.
    public typealias UnitWeights = [(position: Position, weight: Double)]

    private static let insideRunWeights: (UnitWeights, UnitWeights) = (
        [(.ol, 0.60), (.rb, 0.30), (.te, 0.10)],
        [(.dl, 0.60), (.lb, 0.34), (.s, 0.06)]
    )
    private static let outsideRunWeights: (UnitWeights, UnitWeights) = (
        [(.ol, 0.38), (.rb, 0.46), (.te, 0.16)],
        [(.dl, 0.34), (.lb, 0.42), (.s, 0.14), (.cb, 0.10)]
    )
    private static let shortPassWeights: (UnitWeights, UnitWeights) = (
        [(.qb, 0.40), (.wr, 0.26), (.te, 0.16), (.ol, 0.18)],
        [(.cb, 0.34), (.lb, 0.30), (.s, 0.20), (.dl, 0.16)]
    )
    private static let deepPassWeights: (UnitWeights, UnitWeights) = (
        [(.qb, 0.44), (.wr, 0.34), (.ol, 0.22)],
        [(.cb, 0.46), (.s, 0.32), (.dl, 0.22)]
    )
    private static let playActionWeights: (UnitWeights, UnitWeights) = (
        [(.qb, 0.40), (.wr, 0.24), (.te, 0.14), (.ol, 0.22)],
        [(.cb, 0.30), (.s, 0.24), (.lb, 0.24), (.dl, 0.22)]
    )
    private static let fallbackWeights: (UnitWeights, UnitWeights) = ([(.ol, 1.0)], [(.dl, 1.0)])

    public static func matchupWeights(
        for play: OffensivePlay
    ) -> (offense: UnitWeights, defense: UnitWeights) {
        switch play {
        case .insideRun: insideRunWeights
        case .outsideRun: outsideRunWeights
        case .shortPass, .screen: shortPassWeights
        case .deepPass: deepPassWeights
        case .playAction, .twoPointConversion: playActionWeights
        default: fallbackWeights
        }
    }

    /// Yards gained per point of rating advantage. Passing rewards talent more than running does.
    public static func yardsPerRatingPoint(for play: OffensivePlay) -> Double {
        switch play {
        case .insideRun, .outsideRun: 0.055
        case .deepPass: 0.115
        case .playAction: 0.095
        case .shortPass, .screen: 0.075
        default: 0.05
        }
    }

    /// Completion probability gained per point of rating advantage.
    public static let completionPerRatingPoint = 0.0060

    /// Home advantage, expressed as an effective rating bump for the home side.
    public static let homeFieldRatingBonus = 4.2

    // MARK: - Target and tackle distribution

    /// Share of targets by position and depth slot. Tight ends get a real role here — their
    /// absence was a standing complaint about the games this one learns from.
    public static let targetShares: [(position: Position, slot: Int, share: Double)] = [
        (.wr, 0, 0.245), (.wr, 1, 0.185), (.wr, 2, 0.120), (.wr, 3, 0.030),
        (.te, 0, 0.155), (.te, 1, 0.050),
        (.rb, 0, 0.135), (.rb, 1, 0.060), (.rb, 2, 0.020),
    ]

    /// Share of carries by depth slot at running back, with a slice reserved for the quarterback.
    public static let carryShares: [(position: Position, slot: Int, share: Double)] = [
        (.rb, 0, 0.585), (.rb, 1, 0.245), (.rb, 2, 0.095),
        (.qb, 0, 0.050), (.wr, 0, 0.025),
    ]

    public static let tackleShares: [(position: Position, share: Double)] = [
        (.lb, 0.325), (.dl, 0.245), (.cb, 0.215), (.s, 0.215),
    ]

    public static let sackShares: [(position: Position, share: Double)] = [
        (.dl, 0.62), (.lb, 0.26), (.s, 0.07), (.cb, 0.05),
    ]

    public static let interceptionShares: [(position: Position, share: Double)] = [
        (.cb, 0.45), (.s, 0.30), (.lb, 0.22), (.dl, 0.03),
    ]

    // MARK: - Kicking

    /// Field-goal probability from distance, before the kicker's own rating is applied.
    public static func baseFieldGoalProbability(distance: Int) -> Double {
        switch distance {
        case ..<20: 0.985
        case 20..<30: 0.965
        case 30..<40: 0.925
        case 40..<50: 0.830
        case 50..<56: 0.680
        case 56..<61: 0.520
        case 61..<66: 0.330
        default: 0.150
        }
    }

    public static let extraPointDistance = 33
    public static let maxFieldGoalDistance = 66
    /// Kicks are rarely blocked; the reference game shipped this an order of magnitude too high.
    public static let blockRate = 0.012
    public static let puntMeanYards = 45.0
    public static let puntSDYards = 6.5
    public static let puntReturnMeanYards = 7.5
    public static let touchbackChance = 0.22
}
