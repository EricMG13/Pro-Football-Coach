import Foundation

/// The unit a position belongs to. Drives depth-chart grouping and practice allocation.
public enum Unit: String, Codable, Sendable, CaseIterable {
    case offense, defense, specialTeams
}

/// A playing position.
///
/// `02-GAME-DESIGN.md` section 5: attribute sets are position-specific, and decline begins at
/// position-specific ages. Both live here so a phase that adds a position cannot forget either.
public enum Position: String, Codable, Sendable, CaseIterable, Hashable {
    case quarterback, runningBack, wideReceiver, tightEnd
    case leftTackle, guardPosition, center, rightTackle
    case edgeRusher, defensiveTackle
    case linebacker
    case cornerback, safety
    case kicker, punter

    public var unit: Unit {
        switch self {
        case .quarterback, .runningBack, .wideReceiver, .tightEnd,
             .leftTackle, .guardPosition, .center, .rightTackle:
            return .offense
        case .edgeRusher, .defensiveTackle, .linebacker, .cornerback, .safety:
            return .defense
        case .kicker, .punter:
            return .specialTeams
        }
    }

    /// The position group a depth chart and a practice focus operate on.
    public var group: PositionGroup {
        switch self {
        case .quarterback: return .quarterbacks
        case .runningBack: return .runningBacks
        case .wideReceiver, .tightEnd: return .receivers
        case .leftTackle, .guardPosition, .center, .rightTackle: return .offensiveLine
        case .edgeRusher, .defensiveTackle: return .defensiveLine
        case .linebacker: return .linebackers
        case .cornerback, .safety: return .secondary
        case .kicker, .punter: return .specialists
        }
    }

    /// The age at which decline begins for this position.
    ///
    /// `02` section 5: decline begins at position-specific ages and is visible before it is
    /// punishing. Positions that live on speed decline earliest; those that live on technique and
    /// awareness decline latest.
    public var declineAge: Int {
        switch self {
        case .runningBack: return 27
        case .cornerback, .wideReceiver, .edgeRusher: return 29
        case .safety, .linebacker, .defensiveTackle, .tightEnd: return 30
        case .leftTackle, .guardPosition, .center, .rightTackle: return 31
        case .quarterback: return 34
        case .kicker, .punter: return 36
        }
    }

    /// The attributes this position's matchups read, from `03-MATCH-ENGINE.md` section 1.2 plus the
    /// physical and behavioural attributes `02` section 5 shares across every position.
    public var ratedAttributes: [Attribute] {
        Position.sharedAttributes + positionSpecificAttributes
    }

    private static let sharedAttributes: [Attribute] = [
        .speed, .strength, .agility, .durability,
        .awareness, .schemeFit, .temperament, .workEthic, .clutch,
    ]

    private var positionSpecificAttributes: [Attribute] {
        switch self {
        case .quarterback:
            return [.accuracyShort, .accuracyMid, .accuracyDeep, .armStrength, .decision, .poise]
        case .runningBack:
            return [.vision, .elusiveness, .power, .hands, .passBlock]
        case .wideReceiver:
            return [.routeRunning, .release, .hands]
        case .tightEnd:
            return [.routeRunning, .release, .hands, .runBlock, .passBlock]
        case .leftTackle, .guardPosition, .center, .rightTackle:
            return [.passBlock, .runBlock]
        case .edgeRusher:
            return [.passRush, .finesse, .power, .motor, .runDefence, .shed, .tackling, .pursuit]
        case .defensiveTackle:
            return [.passRush, .power, .motor, .runDefence, .shed, .gapDiscipline, .tackling]
        case .linebacker:
            return [.coverage, .runDefence, .shed, .gapDiscipline, .tackling, .pursuit, .passRush]
        case .cornerback:
            return [.coverage, .release, .tackling, .pursuit, .hands]
        case .safety:
            return [.coverage, .runDefence, .tackling, .pursuit, .hands]
        case .kicker:
            return [.legStrength, .kickAccuracy, .poise]
        case .punter:
            return [.legStrength, .kickAccuracy]
        }
    }
}

public enum PositionGroup: String, Codable, Sendable, CaseIterable {
    case quarterbacks, runningBacks, receivers, offensiveLine
    case defensiveLine, linebackers, secondary, specialists
}
