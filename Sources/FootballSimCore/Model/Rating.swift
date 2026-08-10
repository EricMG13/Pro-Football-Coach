import Foundation

/// A 40 to 99 rating, from `02-GAME-DESIGN.md` section 5.
///
/// A type rather than a bare `Int`, because the range is an invariant the whole engine depends on
/// and "remember to clamp" is not an invariant. The clamp is in the failable paths too: a save
/// hand-edited to 500 must produce 99, not a `Rating` that violates its own contract while every
/// downstream calculation reads it happily.
public struct Rating: Codable, Sendable, Equatable, Hashable, Comparable {
    public let value: Int

    public init(_ value: Int) {
        self.value = Rating.clamped(value)
    }

    /// Encoded as a bare number rather than an object. Saves carry dozens of these per player
    /// across thousands of players, and `{"value":68}` is four times the bytes of `68`.
    public init(from decoder: any Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(Int.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    /// Moves a rating by `delta`, staying inside the range.
    public func adjusted(by delta: Int) -> Rating { Rating(value + delta) }

    public static func < (lhs: Rating, rhs: Rating) -> Bool { lhs.value < rhs.value }

    private static func clamped(_ value: Int) -> Int {
        Swift.min(Swift.max(value, SharedRules.ratingRange.lowerBound),
                  SharedRules.ratingRange.upperBound)
    }
}

/// Every attribute the engine reads.
///
/// `03-MATCH-ENGINE.md` section 1.2 is the contract between `02`'s ratings model and the engine's
/// matchup table; this enum is that contract in code. The behavioural four at the end are `02`
/// section 5's traits expressed as ratings, because temperament and work ethic feed development
/// arithmetic rather than a yes-or-no.
public enum Attribute: String, Codable, Sendable, CaseIterable, Hashable {
    // Physical
    case speed, strength, agility, durability

    // Blocking
    case passBlock, runBlock

    // Pass rush
    case passRush, finesse, power, motor

    // Receiving
    case routeRunning, release, hands

    // Coverage and run defence
    case coverage, runDefence, shed, gapDiscipline, tackling, pursuit

    // Passing
    case accuracyShort, accuracyMid, accuracyDeep, armStrength, decision, poise

    // Carrying
    case vision, elusiveness

    // Kicking
    case legStrength, kickAccuracy, blockLeverage

    // Mental and behavioural
    case awareness, schemeFit, temperament, workEthic, clutch

    /// A short player-facing label. `04-UX-AND-DESIGN-SYSTEM.md` owns the copy; this is the
    /// engine-side default so no surface has to invent one.
    public var label: String {
        switch self {
        case .speed: return "Speed"
        case .strength: return "Strength"
        case .agility: return "Agility"
        case .durability: return "Durability"
        case .passBlock: return "Pass block"
        case .runBlock: return "Run block"
        case .passRush: return "Pass rush"
        case .finesse: return "Finesse"
        case .power: return "Power"
        case .motor: return "Motor"
        case .routeRunning: return "Route running"
        case .release: return "Release"
        case .hands: return "Hands"
        case .coverage: return "Coverage"
        case .runDefence: return "Run defence"
        case .shed: return "Shed"
        case .gapDiscipline: return "Gap discipline"
        case .tackling: return "Tackling"
        case .pursuit: return "Pursuit"
        case .accuracyShort: return "Short accuracy"
        case .accuracyMid: return "Mid accuracy"
        case .accuracyDeep: return "Deep accuracy"
        case .armStrength: return "Arm strength"
        case .decision: return "Decision"
        case .poise: return "Poise"
        case .vision: return "Vision"
        case .elusiveness: return "Elusiveness"
        case .legStrength: return "Leg strength"
        case .kickAccuracy: return "Kick accuracy"
        case .blockLeverage: return "Block leverage"
        case .awareness: return "Awareness"
        case .schemeFit: return "Scheme fit"
        case .temperament: return "Temperament"
        case .workEthic: return "Work ethic"
        case .clutch: return "Clutch"
        }
    }
}

/// A player's ratings, sparse.
///
/// A quarterback has no coverage rating worth storing. An attribute that was never set reads as the
/// bottom of the scale rather than as zero: zero is not a legal rating, and an engine that averages
/// across a set would otherwise drag its mean toward a value the model says cannot exist.
public struct Attributes: Codable, Sendable, Equatable {
    private var values: [Attribute: Rating]

    public init(_ values: [Attribute: Rating] = [:]) {
        self.values = values
    }

    public subscript(attribute: Attribute) -> Rating {
        get { values[attribute] ?? Rating(SharedRules.ratingRange.lowerBound) }
        set { values[attribute] = newValue }
    }

    /// The attributes actually set, for a surface that should show only what a position uses.
    public var assigned: [Attribute: Rating] { values }
}
