import Foundation

/// One matchup, and how it went.
///
/// **This type is the point of D2.** `docs/OPEN-DECISIONS.md` rejects the play-outcome distribution
/// model because it "cannot answer why did that happen, which is the entire information payload of
/// a coaching game: the player must be able to see that the left tackle lost, not merely that the
/// sack occurred." `04` §5.3 draws a sack as *the protection duel that lost*, and it can only do
/// that if the engine recorded which duel that was.
///
/// So every snap carries its matchups out with it, and the view reads them. A resolver that
/// returned only yardage would be the model D2 turned down.
public struct MatchupRecord: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case passProtection, routeVersusCoverage, throwing, runLane, carrierVersusPursuit, kick
    }

    public let kind: Kind
    public let attackerID: UUID
    public let defenderID: UUID
    /// The stage-2 scalar. Positive means the attacker won.
    public let leverage: Double

    public init(kind: Kind, attackerID: UUID, defenderID: UUID, leverage: Double) {
        self.kind = kind
        self.attackerID = attackerID
        self.defenderID = defenderID
        self.leverage = leverage
    }

    public var attackerWon: Bool { leverage > 0 }
}

/// How a snap ended.
public enum SnapResult: String, Codable, Sendable, CaseIterable {
    case gain
    case incompletion
    case sack
    case interception
    case fumbleLost
    case touchdown
    case fieldGoalGood
    case fieldGoalMissed
    case punt
    case safety
    case kneel
    /// An accepted penalty. The snap either never happened (a pre-snap flag) or was wiped out by
    /// one, and `SnapOutcome.penalty` carries which. `02` §3.5.
    case penalty

    /// Whether possession changes on this result. The drive loop reads it rather than re-deriving
    /// the rule at each site.
    public var isTurnover: Bool {
        switch self {
        case .interception, .fumbleLost: return true
        default: return false
        }
    }

    /// Whether the play clock stopped itself, independent of the tier's first-down rule.
    public var stopsClock: Bool {
        switch self {
        case .incompletion, .touchdown, .fieldGoalGood, .fieldGoalMissed, .punt, .safety,
             .interception, .penalty:
            return true
        case .gain, .sack, .fumbleLost, .kneel:
            return false
        }
    }
}

/// Everything one snap produced.
///
/// A value type with no reference to the engine that made it, so the UI can hold a stream of these
/// and cannot reach back into the simulation. That is the engine half of `03` §1.3's honesty
/// invariant: rendering measures and dramatises, and cannot change a result.
public struct SnapOutcome: Codable, Sendable, Equatable {
    public let result: SnapResult
    /// Net yards from the previous line of scrimmage. Negative on a sack or a loss.
    public let yards: Int
    /// Seconds the snap consumed, including the pre-snap clock at the chosen tempo.
    public let secondsElapsed: Int
    /// The matchups that produced it, in resolution order.
    public let matchups: [MatchupRecord]
    /// Who touched the ball, for the box score. Empty on a kneel.
    public let ballCarrierID: UUID?
    public let passerID: UUID?
    public let targetID: UUID?
    /// The flag on this snap, accepted or declined. `02` §3.5. Nil on the great majority of snaps.
    public let penalty: PenaltyRecord?

    public init(
        result: SnapResult,
        yards: Int,
        secondsElapsed: Int,
        matchups: [MatchupRecord],
        ballCarrierID: UUID? = nil,
        passerID: UUID? = nil,
        targetID: UUID? = nil,
        penalty: PenaltyRecord? = nil
    ) {
        self.result = result
        self.yards = yards
        self.secondsElapsed = secondsElapsed
        self.matchups = matchups
        self.ballCarrierID = ballCarrierID
        self.passerID = passerID
        self.targetID = targetID
        self.penalty = penalty
    }

    /// The same outcome with a flag attached — what a declined penalty produces, since the play
    /// stands and only the record changes.
    public func recording(_ penalty: PenaltyRecord) -> SnapOutcome {
        SnapOutcome(result: result, yards: yards, secondsElapsed: secondsElapsed,
                    matchups: matchups, ballCarrierID: ballCarrierID, passerID: passerID,
                    targetID: targetID, penalty: penalty)
    }

    /// The matchup that decided the snap: the largest-magnitude one of the deciding kind.
    ///
    /// What `04` §5.3's "draw the sack as the protection duel that lost" reads. Returns nil only for
    /// a snap with no matchups, which is a kneel.
    public var decidingMatchup: MatchupRecord? {
        let relevant: [MatchupRecord.Kind]
        switch result {
        case .sack: relevant = [.passProtection]
        case .incompletion, .interception: relevant = [.throwing, .routeVersusCoverage]
        case .fieldGoalGood, .fieldGoalMissed: relevant = [.kick]
        case .gain, .touchdown, .fumbleLost: relevant = [.carrierVersusPursuit, .throwing, .runLane]
        // A penalty's deciding matchup is whichever duel was largest: the flag is the story, and the
        // duel underneath it is the evidence. A pre-snap flag carries no matchups and returns nil,
        // which is correct — nothing was contested.
        case .punt, .safety, .kneel, .penalty: relevant = MatchupRecord.Kind.allCases
        }
        return matchups
            .filter { relevant.contains($0.kind) }
            .max { Swift.abs($0.leverage) < Swift.abs($1.leverage) }
    }
}
