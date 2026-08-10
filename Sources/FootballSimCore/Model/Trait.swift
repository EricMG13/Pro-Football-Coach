import Foundation

/// A behavioural trait.
///
/// `02-GAME-DESIGN.md` section 5: traits "have mechanical bite in specific systems, never as
/// flavour." `bitesIn` names the system, so a trait added without one is a compile error rather
/// than a decorative string on a player card — which is exactly the dead capability
/// `08-OPUS5-BUILD-PROMPT.md` names as this project's first failure mode.
public enum Trait: String, Codable, Sendable, CaseIterable, Hashable {
    /// Recovers faster and misses fewer weeks.
    case ironman
    /// Develops faster from practice allocation.
    case workhorse
    /// Performs above rating in the fourth quarter and in the bracket.
    case iceInVeins
    /// Performs below rating on the road and in hostile venues.
    case frontRunner
    /// Raises the development of younger players at the same position.
    case mentor
    /// Interest decays faster when the programme loses; leaves for the portal more readily.
    case restless
    /// Fits a new scheme faster after a change.
    case adaptable
    /// Draws more penalties and more discipline events.
    case volatile

    /// The system this trait changes. Every trait names one.
    public var bitesIn: TraitSystem {
        switch self {
        case .ironman: return .injury
        case .workhorse, .mentor: return .development
        case .iceInVeins, .frontRunner: return .matchResolution
        case .restless: return .retention
        case .adaptable: return .schemeFit
        case .volatile: return .discipline
        }
    }

    public var label: String {
        switch self {
        case .ironman: return "Ironman"
        case .workhorse: return "Workhorse"
        case .iceInVeins: return "Ice in veins"
        case .frontRunner: return "Front runner"
        case .mentor: return "Mentor"
        case .restless: return "Restless"
        case .adaptable: return "Adaptable"
        case .volatile: return "Volatile"
        }
    }
}

/// The systems a trait can bite in. A trait whose system is not listed here does not exist.
public enum TraitSystem: String, Codable, Sendable, CaseIterable {
    case injury, development, matchResolution, retention, schemeFit, discipline
}
