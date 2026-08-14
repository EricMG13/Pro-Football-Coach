import Foundation

/// What the kicking team is trying to do. `02` §3.6.
public enum KickoffType: String, Codable, Sendable, CaseIterable {
    /// Kick it deep and cover.
    case deep
    /// Kick it ten yards and try to get it back. The trailing team's last mechanism.
    case onside
}

/// One kickoff.
///
/// Every possession in this engine used to begin at a constant — `kickoffTouchbackYardLine`, applied
/// after every score, at the opening and at halftime — so there was no return game, no onside kick,
/// no field-position variance at all, and the special-teams coordinator `Staff.swift` employs had
/// nothing to coordinate.
public struct KickoffRecord: Codable, Sendable, Equatable {
    public let type: KickoffType
    /// The side that kicked.
    public let kickingSide: Side
    /// True when an onside kick was recovered by the kicking team, which is the only way a kickoff
    /// does not change possession.
    public let recoveredByKickingTeam: Bool
    public let touchback: Bool
    public let returnYards: Int
    /// Where the receiving team — or the kicking team, on a recovered onside kick — starts, from
    /// that team's own goal line.
    public let resultingYardLine: Int
    /// Points the return itself scored. Six plus the try, or zero.
    public let points: Int
    public let returnTouchdown: Bool
    public let kickerID: UUID?
    public let returnerID: UUID?

    public init(
        type: KickoffType,
        kickingSide: Side,
        recoveredByKickingTeam: Bool = false,
        touchback: Bool = false,
        returnYards: Int = 0,
        resultingYardLine: Int,
        points: Int = 0,
        returnTouchdown: Bool = false,
        kickerID: UUID? = nil,
        returnerID: UUID? = nil
    ) {
        self.type = type
        self.kickingSide = kickingSide
        self.recoveredByKickingTeam = recoveredByKickingTeam
        self.touchback = touchback
        self.returnYards = returnYards
        self.resultingYardLine = resultingYardLine
        self.points = points
        self.returnTouchdown = returnTouchdown
        self.kickerID = kickerID
        self.returnerID = returnerID
    }
}

/// Resolves kickoffs. `02` §3.6.
public enum KickoffModel {
    /// Deep, or onside.
    ///
    /// Takes scalars rather than a `Situation` because a kickoff happens *between* possessions, and
    /// a situation read from either side's perspective at that moment is a perspective bug waiting
    /// to happen. `trailingBy` is positive when the kicking team is behind.
    public static func chooseType(
        trailingBy: Int,
        secondsRemainingInHalf: Int,
        quarter: Int,
        quarters: Int
    ) -> KickoffType {
        guard quarter >= quarters,
              trailingBy > 0,
              trailingBy <= MatchupRules.onsideKickMaximumDeficit,
              secondsRemainingInHalf <= MatchupRules.onsideKickSecondsRemaining
        else { return .deep }
        return .onside
    }

    /// Resolves one kickoff.
    ///
    /// - Parameters:
    ///   - kicking: the kicking team's personnel. Its specialists kick and its defence covers.
    ///   - receiving: the receiving team's personnel. Its best back or receiver returns.
    public static func resolve(
        type: KickoffType,
        kickingSide: Side,
        kicking: SnapPersonnel,
        receiving: SnapPersonnel,
        weather: Weather = .clear,
        rng: inout SeededRandom
    ) -> KickoffRecord {
        let kicker = kicking.offensive(.kicker).first
            ?? kicking.offensive(group: .specialists).first
        switch type {
        case .onside:
            // Deliberately a flat chance rather than a matchup: an onside kick is decided by a
            // scramble among ten players for a bouncing ball, and dressing that up as a duel
            // between two named ones would be a false causal record — which `04` §5.3 reads.
            let recovered = rng.chance(MatchupRules.onsideRecoveryChance)
            return KickoffRecord(
                type: .onside,
                kickingSide: kickingSide,
                recoveredByKickingTeam: recovered,
                resultingYardLine: recovered
                    ? MatchupRules.onsideRecoveryYardLine
                    : 100 - MatchupRules.onsideRecoveryYardLine,
                kickerID: kicker?.id
            )
        case .deep:
            // Leg strength buys touchbacks, which is the whole reason a kicker's leg is rated
            // separately from their accuracy.
            let leg = kicker.map { SnapResolver.normalised($0.attributes[.legStrength]) } ?? 0.5
            // Wind and snow keep kicks in the field of play, which is where the return game comes
            // from on the days it matters most.
            let touchbackChance = MatchupRules.kickoffTouchbackChance
                + leg * MatchupRules.legStrengthTouchbackHelp
                - weather.kickPenalty
            let touchback = rng.chance(touchbackChance)
            guard !touchback else {
                return KickoffRecord(type: .deep, kickingSide: kickingSide, touchback: true,
                                     resultingYardLine: MatchupRules.kickoffTouchbackYardLine,
                                     kickerID: kicker?.id)
            }

            let returner = receiving.offensive(group: .runningBacks).first
                ?? receiving.offensive(group: .receivers).first
            let coverage = SnapPersonnel.ranked(kicking.defense).first
            guard let returner, let coverage else {
                return KickoffRecord(type: .deep, kickingSide: kickingSide, touchback: true,
                                     resultingYardLine: MatchupRules.kickoffTouchbackYardLine,
                                     kickerID: kicker?.id)
            }
            let leverage = Leverage.score(
                attacker: returner.attributes[.speed],
                defender: coverage.attributes[.tackling],
                rng: &rng
            )
            // The breakaway is its own draw rather than a threshold on the matchup, and it is taken
            // unconditionally so the branch cannot change how many draws a return consumes.
            //
            // A threshold was the obvious design and it is unreachable: the matchup can move a
            // return by at most `kickoffReturnYardScale` yards, so from the fielding spot no
            // leverage a returner can produce reaches the end zone. A branch that cannot be entered
            // is the dead capability this project's build prompt names first, and putting a return
            // touchdown behind one would have shipped exactly that.
            let brokeFree = rng.chance(MatchupRules.kickoffBreakawayChance)
            let gained = MatchupRules.baseKickoffReturnYards
                + Int((leverage * MatchupRules.kickoffReturnYardScale).rounded())
            let spot = brokeFree && leverage > 0
                ? 100
                : MatchupRules.kickoffReturnStartYardLine + Swift.max(0, gained)
            if spot >= 100 {
                return KickoffRecord(
                    type: .deep, kickingSide: kickingSide,
                    returnYards: 100 - MatchupRules.kickoffReturnStartYardLine,
                    resultingYardLine: MatchupRules.kickoffTouchbackYardLine,
                    returnTouchdown: true,
                    kickerID: kicker?.id, returnerID: returner.id
                )
            }
            return KickoffRecord(
                type: .deep, kickingSide: kickingSide,
                returnYards: Swift.max(0, gained),
                resultingYardLine: Swift.min(Swift.max(spot, 1), 99),
                kickerID: kicker?.id, returnerID: returner.id
            )
        }
    }
}
