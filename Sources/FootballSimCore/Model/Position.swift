import Foundation

/// A single rated skill. Players carry only the attributes their position uses.
public enum Attribute: String, Codable, CaseIterable, Sendable, Hashable, CodingKeyRepresentable {
    // Core — every position except kickers and punters.
    case speed, strength, agility, awareness
    // Passing
    case throwPower, throwAccuracy
    // Ball carrying / receiving
    case catching, routeRunning, breakTackle, vision
    // Blocking
    case runBlock, passBlock
    // Defense
    case tackle, blockShed, passRush, coverage
    // Specialists
    case kickPower, kickAccuracy, puntPower, puntAccuracy

    public var displayName: String {
        switch self {
        case .speed: "Speed"
        case .strength: "Strength"
        case .agility: "Agility"
        case .awareness: "Awareness"
        case .throwPower: "Throw Power"
        case .throwAccuracy: "Throw Accuracy"
        case .catching: "Catch"
        case .routeRunning: "Route Running"
        case .breakTackle: "Break Tackle"
        case .vision: "Vision"
        case .runBlock: "Run Block"
        case .passBlock: "Pass Block"
        case .tackle: "Tackle"
        case .blockShed: "Block Shed"
        case .passRush: "Pass Rush"
        case .coverage: "Coverage"
        case .kickPower: "Kick Power"
        case .kickAccuracy: "Kick Accuracy"
        case .puntPower: "Punt Power"
        case .puntAccuracy: "Punt Accuracy"
        }
    }
}

/// Roster positions. Deliberately coarse (one OL, one DL — no LT/RG split) so depth charts
/// stay readable on a phone; granular line positions are a documented backlog item.
public enum Position: String, Codable, CaseIterable, Sendable, Hashable, CodingKeyRepresentable {
    case qb, rb, wr, te, ol, dl, lb, cb, s, k, p

    public var abbreviation: String { rawValue.uppercased() }

    public var displayName: String {
        switch self {
        case .qb: "Quarterback"
        case .rb: "Running Back"
        case .wr: "Wide Receiver"
        case .te: "Tight End"
        case .ol: "Offensive Line"
        case .dl: "Defensive Line"
        case .lb: "Linebacker"
        case .cb: "Cornerback"
        case .s: "Safety"
        case .k: "Kicker"
        case .p: "Punter"
        }
    }

    private static let core: [Attribute] = [.speed, .strength, .agility, .awareness]

    /// Attributes this position is rated on. Specialists skip the athletic core — a punter's
    /// forty time never decides a game.
    public var attributes: [Attribute] {
        switch self {
        case .qb: Self.core + [.throwPower, .throwAccuracy]
        case .rb: Self.core + [.catching, .breakTackle, .vision]
        case .wr: Self.core + [.catching, .routeRunning, .breakTackle]
        case .te: Self.core + [.catching, .routeRunning, .breakTackle, .blockShed]
        case .ol: Self.core + [.runBlock, .passBlock]
        case .dl: Self.core + [.tackle, .blockShed, .passRush]
        case .lb: Self.core + [.tackle, .coverage, .blockShed]
        case .cb, .s: Self.core + [.coverage, .tackle]
        case .k: [.awareness, .kickPower, .kickAccuracy]
        case .p: [.awareness, .puntPower, .puntAccuracy]
        }
    }

    /// Target count on a 53-man active roster. Sums to exactly `LeagueRules.activeRosterSize`.
    public var rosterTarget: Int {
        switch self {
        case .qb: 3
        case .rb: 4
        case .wr: 6
        case .te: 3
        case .ol: 9
        case .dl: 8
        case .lb: 7
        case .cb: 6
        case .s: 5
        case .k, .p: 1
        }
    }

    /// How many take the field in the base formation — drives unit-rating math.
    public var starterCount: Int {
        switch self {
        case .qb: 1
        case .rb: 1
        case .wr: 3
        case .te: 1
        case .ol: 5
        case .dl: 4
        case .lb: 3
        case .cb: 2
        case .s: 2
        case .k, .p: 1
        }
    }

    /// Hard floor enforced at roster cutdown — a team can never be left unable to field a unit.
    public var minimumRosterCount: Int {
        switch self {
        case .k, .p: 1
        case .qb, .te: 2
        case .rb: 2
        case .wr: 4
        case .ol: 7
        case .dl: 5
        case .lb: 4
        case .cb: 4
        case .s: 3
        }
    }

    public var isOffense: Bool {
        switch self {
        case .qb, .rb, .wr, .te, .ol: true
        default: false
        }
    }

    public var isDefense: Bool {
        switch self {
        case .dl, .lb, .cb, .s: true
        default: false
        }
    }

    public var isSpecialist: Bool { self == .k || self == .p }

    /// Jersey-number band, used only for flavor.
    public var jerseyRange: ClosedRange<Int> {
        switch self {
        case .qb: 1...19
        case .k, .p: 1...19
        case .rb: 20...49
        case .cb, .s: 20...49
        case .wr: 10...89
        case .te: 80...89
        case .ol: 50...79
        case .dl: 50...99
        case .lb: 40...59
        }
    }

    /// Ordering used by depth-chart and roster screens.
    public static let displayOrder: [Position] = [.qb, .rb, .wr, .te, .ol, .dl, .lb, .cb, .s, .k, .p]
}
