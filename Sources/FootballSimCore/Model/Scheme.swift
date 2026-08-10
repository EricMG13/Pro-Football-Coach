import Foundation

/// An offensive scheme identity.
///
/// `02-GAME-DESIGN.md` section 6: "scheme identity is the spine", the roster's fit to it modifies
/// every matchup, and changing it is expensive and slow. The `emphasises` set is what a fit score
/// reads; a scheme that emphasised nothing would be a label, which section 6 explicitly is not.
public enum OffensiveScheme: String, Codable, Sendable, CaseIterable {
    case proStyle, airRaid, spreadOption, westCoast, powerRun, runAndShoot

    public var emphasises: Set<Attribute> {
        switch self {
        case .proStyle: return [.accuracyMid, .decision, .passBlock, .runBlock]
        case .airRaid: return [.accuracyDeep, .armStrength, .routeRunning, .speed]
        case .spreadOption: return [.vision, .elusiveness, .speed, .agility]
        case .westCoast: return [.accuracyShort, .decision, .routeRunning, .hands]
        case .powerRun: return [.runBlock, .strength, .power, .vision]
        case .runAndShoot: return [.release, .routeRunning, .agility, .poise]
        }
    }

    public var label: String {
        switch self {
        case .proStyle: return "Pro style"
        case .airRaid: return "Air raid"
        case .spreadOption: return "Spread option"
        case .westCoast: return "West coast"
        case .powerRun: return "Power run"
        case .runAndShoot: return "Run and shoot"
        }
    }
}

/// A defensive scheme identity. Same contract as the offensive one.
public enum DefensiveScheme: String, Codable, Sendable, CaseIterable {
    case fourThree, threeFour, nickelBase, bearFront, tampaTwo, pressMan

    public var emphasises: Set<Attribute> {
        switch self {
        case .fourThree: return [.passRush, .gapDiscipline, .tackling, .pursuit]
        case .threeFour: return [.power, .shed, .motor, .coverage]
        case .nickelBase: return [.coverage, .speed, .agility, .pursuit]
        case .bearFront: return [.power, .runDefence, .gapDiscipline, .shed]
        case .tampaTwo: return [.coverage, .awareness, .pursuit, .speed]
        case .pressMan: return [.coverage, .release, .strength, .agility]
        }
    }

    public var label: String {
        switch self {
        case .fourThree: return "Four-three"
        case .threeFour: return "Three-four"
        case .nickelBase: return "Nickel base"
        case .bearFront: return "Bear front"
        case .tampaTwo: return "Two deep"
        case .pressMan: return "Press man"
        }
    }
}

/// A team's scheme on both sides of the ball.
public struct SchemeIdentity: Codable, Sendable, Equatable {
    public var offense: OffensiveScheme
    public var defense: DefensiveScheme

    public init(offense: OffensiveScheme, defense: DefensiveScheme) {
        self.offense = offense
        self.defense = defense
    }

    /// The attributes this identity rewards, on the side of the ball a position plays.
    public func emphasised(for position: Position) -> Set<Attribute> {
        switch position.unit {
        case .offense: return offense.emphasises
        case .defense: return defense.emphasises
        case .specialTeams: return []
        }
    }
}
