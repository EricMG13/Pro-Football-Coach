import Foundation

/// A penalty, with everything enforcement needs to know about it.
///
/// `03-MATCH-ENGINE.md` §1.1 lists "penalty" among stage 4's consequences and nothing produced one:
/// there was no penalty type, constant or code path anywhere in the engine, and `02` §11.3.3's
/// `volatile` trait named a Discipline system that did not exist. `01-RESEARCH.md` §6.5 records
/// penalties as one of the loudest complaints about every competitor's match layer, which is an
/// argument for modelling them carefully rather than for leaving them out.
///
/// Seven kinds, not seventy. Each one has to earn its place by changing a decision or a drive, and a
/// kind whose enforcement is identical to another's is the same kind wearing a different name.
public enum PenaltyKind: String, Codable, Sendable, CaseIterable {
    case falseStart
    case delayOfGame
    case offensiveHolding
    case offside
    case defensiveHolding
    case passInterference
    case personalFoul

    /// Whether the offence committed it. The other side decides whether to accept.
    public var onOffense: Bool {
        switch self {
        case .falseStart, .delayOfGame, .offensiveHolding: return true
        case .offside, .defensiveHolding, .passInterference, .personalFoul: return false
        }
    }

    /// Yards from the offence's perspective: negative moves them back.
    public var yards: Int {
        switch self {
        case .falseStart, .delayOfGame: return -MatchupRules.minorPenaltyYards
        case .offensiveHolding: return -MatchupRules.majorPenaltyYards
        case .offside, .defensiveHolding: return MatchupRules.minorPenaltyYards
        case .passInterference, .personalFoul: return MatchupRules.severePenaltyYards
        }
    }

    /// Whether the snap happened at all. A pre-snap flag replaces the play rather than modifying it,
    /// which is why it is drawn before resolution rather than after.
    public var isPreSnap: Bool {
        switch self {
        case .falseStart, .delayOfGame, .offside: return true
        case .offensiveHolding, .defensiveHolding, .passInterference, .personalFoul: return false
        }
    }

    /// Defensive fouls that hand the offence a new set of downs whatever the yardage.
    public var automaticFirstDown: Bool {
        switch self {
        case .defensiveHolding, .passInterference, .personalFoul: return true
        case .falseStart, .delayOfGame, .offensiveHolding, .offside: return false
        }
    }

    /// Who most plausibly committed it.
    ///
    /// Not a rule of the sport — a linebacker can false-start on a fake — but the group the flag
    /// lands on most of the time, and the reason a penalty can name a player at all. A model that
    /// picked uniformly from twenty-two would put pass interference on the centre.
    public var likelyGroup: PositionGroup {
        switch self {
        case .falseStart, .offensiveHolding: return .offensiveLine
        case .delayOfGame: return .quarterbacks
        case .offside: return .defensiveLine
        case .defensiveHolding, .passInterference: return .secondary
        case .personalFoul: return .linebackers
        }
    }

    /// How often this kind is the one that gets called, relative to the others.
    ///
    /// Uniform selection would make pass interference as common as a false start, which is wrong by
    /// an order of magnitude and would wreck the yardage a penalty costs on average.
    public var frequencyWeight: Int {
        switch self {
        case .falseStart: return MatchupRules.falseStartWeight
        case .delayOfGame: return MatchupRules.delayOfGameWeight
        case .offensiveHolding: return MatchupRules.offensiveHoldingWeight
        case .offside: return MatchupRules.offsideWeight
        case .defensiveHolding: return MatchupRules.defensiveHoldingWeight
        case .passInterference: return MatchupRules.passInterferenceWeight
        case .personalFoul: return MatchupRules.personalFoulWeight
        }
    }

    public var label: String {
        switch self {
        case .falseStart: return "False start"
        case .delayOfGame: return "Delay of game"
        case .offensiveHolding: return "Holding"
        case .offside: return "Offside"
        case .defensiveHolding: return "Defensive holding"
        case .passInterference: return "Pass interference"
        case .personalFoul: return "Personal foul"
        }
    }
}

/// A flag on one snap.
public struct PenaltyRecord: Codable, Sendable, Equatable {
    public let kind: PenaltyKind
    /// The side that committed it.
    public let against: Side
    /// Who committed it. Nil only when the offending side had nobody on the field, which a legal
    /// roster cannot produce.
    public let offenderID: UUID?
    /// Enforced yards from the offence's perspective. **Zero when the flag was declined**, so a
    /// declined penalty is recorded — a box score that hid them would lose the causal record of a
    /// play that nearly did not count.
    public let yards: Int
    public let accepted: Bool
    /// Whether enforcement grants a first down. Copied from the kind so enforcement never has to
    /// re-derive it, and so a declined flag carries `false` however the kind reads.
    public let automaticFirstDown: Bool

    public init(kind: PenaltyKind, against: Side, offenderID: UUID?, yards: Int, accepted: Bool,
                automaticFirstDown: Bool) {
        self.kind = kind
        self.against = against
        self.offenderID = offenderID
        self.yards = yards
        self.accepted = accepted
        self.automaticFirstDown = automaticFirstDown
    }
}

/// Draws and enforces penalties. `02` §3.5.
public enum PenaltyModel {
    /// Draws a possible flag for one snap.
    ///
    /// **Always consumes exactly three draws**, whether or not it flags anything, and takes them
    /// before the snap resolves. Both halves matter: taken first, a flag cannot shift the stream the
    /// snap's own resolution reads; taken unconditionally, the presence of a flag cannot change how
    /// many draws the snap consumes, which is the property `SnapResolver`'s draw-count test asserts.
    ///
    /// The rate reads personnel and not the situation, so two snaps with the same players flag or do
    /// not flag together. A rate that moved with down and distance would make the draw-count
    /// property depend on the field position, which is exactly the coupling `03` §3 forbids.
    public static func draw(
        personnel: SnapPersonnel,
        situation: Situation,
        rng: inout SeededRandom
    ) -> PenaltyRecord? {
        let everyone = personnel.offense + personnel.defense
        let volatileShare = everyone.isEmpty
            ? 0
            : Double(everyone.filter { $0.has(.volatile) }.count) / Double(everyone.count)
        let rate = MatchupRules.penaltyChancePerSnap
            * (1 + volatileShare * MatchupRules.volatilePenaltyRateBonus)

        let flagged = rng.chance(rate)
        let kindDraw = rng.double01()
        let offenderDraw = rng.double01()
        guard flagged else { return nil }

        let kind = pick(by: kindDraw)
        let offence = situation.possession
        let against = kind.onOffense ? offence : offence.opponent
        let squad = kind.onOffense ? personnel.offense : personnel.defense
        return PenaltyRecord(
            kind: kind,
            against: against,
            offenderID: offender(from: squad, group: kind.likelyGroup, draw: offenderDraw)?.id,
            yards: kind.yards,
            accepted: true,
            automaticFirstDown: kind.automaticFirstDown
        )
    }

    /// The kind, from one uniform draw over the weight table.
    public static func pick(by draw: Double) -> PenaltyKind {
        let total = PenaltyKind.allCases.reduce(0) { $0 + $1.frequencyWeight }
        var target = draw * Double(total)
        for kind in PenaltyKind.allCases {
            target -= Double(kind.frequencyWeight)
            if target < 0 { return kind }
        }
        // Only reachable through floating-point drift at the very top of the range.
        return PenaltyKind.allCases[PenaltyKind.allCases.count - 1]
    }

    /// Who gets the flag: someone in the likely group, weighted toward the volatile.
    ///
    /// This is `volatile`'s mechanical bite (`02` §11.3.3, FSC-014). It changes *who* commits the
    /// foul rather than only how often one is called, because a trait a player carries should show
    /// up on that player's line and not merely in a team rate.
    public static func offender(from squad: [Player], group: PositionGroup, draw: Double) -> Player? {
        let ranked = SnapPersonnel.ranked(squad.filter { $0.position.group == group })
        let candidates = ranked.isEmpty ? SnapPersonnel.ranked(squad) : ranked
        guard !candidates.isEmpty else { return nil }
        let weights = candidates.map {
            $0.has(.volatile) ? MatchupRules.volatileOffenderWeight : 1
        }
        let total = weights.reduce(0, +)
        var target = draw * Double(total)
        for (index, weight) in weights.enumerated() {
            target -= Double(weight)
            if target < 0 { return candidates[index] }
        }
        return candidates[candidates.count - 1]
    }

    /// The snap that never happened.
    public static func preSnapOutcome(
        _ flag: PenaltyRecord,
        rules: any ClockRules.Type
    ) -> SnapOutcome {
        SnapOutcome(result: .penalty, yards: flag.yards,
                    secondsElapsed: rules.stoppedPlaySeconds, matchups: [], penalty: flag)
    }

    /// Applies a flag that happened during the play.
    ///
    /// The accept/decline decision is made **optimally for the side that holds it**, which is a
    /// deliberate simplification and is recorded as one in `02` §3.5: a real coach can decline
    /// badly, and one day this is a call-in. Modelling it as always-accept would be worse in a
    /// specific and visible way — a defence would take ten yards instead of the sack it just got.
    public static func applying(
        _ flag: PenaltyRecord,
        to outcome: SnapOutcome,
        situation: Situation,
        rules: any ClockRules.Type
    ) -> SnapOutcome {
        let accepted = shouldAccept(
            flag.kind,
            playYards: outcome.yards,
            playWasTurnover: outcome.result.isTurnover,
            playScored: outcome.result == .touchdown,
            distance: situation.distance
        )
        guard accepted else {
            let declined = PenaltyRecord(kind: flag.kind, against: flag.against,
                                         offenderID: flag.offenderID, yards: 0, accepted: false,
                                         automaticFirstDown: false)
            return outcome.recording(declined)
        }
        // The matchups are carried through: the play still happened, and `04` §5.3's causal record
        // is the reason this engine resolves duels at all. What is wiped is the yardage.
        return SnapOutcome(result: .penalty, yards: flag.yards,
                           secondsElapsed: rules.stoppedPlaySeconds, matchups: outcome.matchups,
                           ballCarrierID: outcome.ballCarrierID, passerID: outcome.passerID,
                           targetID: outcome.targetID, penalty: flag)
    }

    /// Whether the side holding the decision takes the flag.
    public static func shouldAccept(
        _ kind: PenaltyKind,
        playYards: Int,
        playWasTurnover: Bool,
        playScored: Bool,
        distance: Int
    ) -> Bool {
        if kind.onOffense {
            // The defence decides, and it keeps a takeaway over any yardage.
            if playWasTurnover { return false }
            return playYards > kind.yards
        }
        // The offence decides. A touchdown beats every flag; a turnover is worth wiping out at any
        // price.
        if playScored { return false }
        if playWasTurnover { return true }
        let value = kind.automaticFirstDown ? Swift.max(kind.yards, distance) : kind.yards
        return value > playYards
    }
}
