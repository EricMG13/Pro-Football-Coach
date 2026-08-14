import Foundation

/// Stage 1 of `03-MATCH-ENGINE.md` §1.1: the call assigns every player a role.
///
/// "The offensive call assigns every offensive player a role (blocker, route runner, carrier,
/// decoy). The defensive call assigns coverage responsibility, rush lanes and run fits."
public enum SnapRole: String, Codable, Sendable, CaseIterable {
    case passer, blocker, routeRunner, carrier, decoy
    case rusher, coverage, runFit, kicker, blockLeverage
}

/// The players on the field for one snap, already picked from the depth chart.
///
/// Substitution is `02` §3.2's business and happens above this; the resolver takes who is out
/// there. A value type, so a snap cannot mutate a roster.
public struct SnapPersonnel: Sendable, Equatable {
    public let offense: [Player]
    public let defense: [Player]
    /// The bench. `02` §3.8.
    ///
    /// Defaulted to empty so every existing caller compiles unchanged, and empty is honest: a
    /// personnel package built by hand for a test has no bench, and a side with no bench simply
    /// cannot replace anybody — which is exactly what the substitution rule below then does.
    public let reserves: [Player]

    public init(offense: [Player], defense: [Player], reserves: [Player] = []) {
        self.offense = offense
        self.defense = defense
        self.reserves = reserves
    }

    public func contains(playerID: UUID) -> Bool {
        offense.contains { $0.id == playerID } || defense.contains { $0.id == playerID }
    }

    /// The same side with one player replaced from the bench. `02` §3.8.
    ///
    /// `MatchInjury.forcedOut` was recorded and **never honoured**: a player whose game was over
    /// took every remaining snap of it, so an injury changed a line in the record and nothing in the
    /// match. That is the decoration D6 clause 4 forbids, and it is also the reason `DepthChart`
    /// exists — its own documentation says `forcedOut` "had nothing to hand the snap to".
    ///
    /// **No draw is consumed.** The replacement is the best reserve at the position, then the best
    /// in the group, chosen by the same ranking the depth chart uses. A substitution that rolled
    /// dice would put the injured player's bad luck into the stream every other snap reads.
    ///
    /// **A side that cannot replace somebody plays on with them.** Eleven players is a rule of the
    /// sport, and dropping to ten would give the resolver a formation it has no way to resolve —
    /// the same argument `DepthChart.unit` makes when it falls back to any available body.
    public func substituting(outPlayerID id: UUID) -> SnapPersonnel {
        let onOffense = offense.contains { $0.id == id }
        let unit = onOffense ? offense : defense
        guard let out = unit.first(where: { $0.id == id }) else { return self }
        let replacement = Self.ranked(reserves.filter { $0.position == out.position }).first
            ?? Self.ranked(reserves.filter { $0.position.group == out.position.group }).first
        guard let replacement else { return self }
        let replaced = unit.map { $0.id == id ? replacement : $0 }
        return SnapPersonnel(
            offense: onOffense ? replaced : offense,
            defense: onOffense ? defense : replaced,
            reserves: reserves.filter { $0.id != replacement.id }
        )
    }

    /// Every forced-out injury in a set of plays, applied in the order they happened.
    ///
    /// One definition, called from two places: the drive loop substitutes mid-drive so the next
    /// snap is short a man, and the game loop carries the same substitutions forward so the next
    /// drive does not un-injure him. Two copies of this rule would eventually disagree about who is
    /// on the field, and nothing would notice.
    public func substituting(forcedOutIn plays: [PlayRecord]) -> SnapPersonnel {
        plays.reduce(self) { personnel, play in
            guard let injury = play.outcome.injury, injury.forcedOut else { return personnel }
            return personnel.substituting(outPlayerID: injury.playerID)
        }
    }

    public func offensive(_ position: Position) -> [Player] {
        offense.filter { $0.position == position }
    }

    /// Players in a group, best first, so a resolver that needs "the top three receivers" gets a
    /// stable order rather than roster order.
    ///
    /// Ties break on the identifier's bytes, never on `hashValue` and never on array order, so two
    /// runs of the same seed pick the same players.
    public func offensive(group: PositionGroup) -> [Player] {
        Self.ranked(offense.filter { $0.position.group == group })
    }

    public func defensive(group: PositionGroup) -> [Player] {
        Self.ranked(defense.filter { $0.position.group == group })
    }

    static func ranked(_ players: [Player]) -> [Player] {
        players.sorted {
            $0.overall == $1.overall
                ? $0.id.uuidString < $1.id.uuidString
                : $0.overall > $1.overall
        }
    }
}

/// The assignment a call produces: who is doing what, in the order matchups resolve.
public struct SnapAssignment: Sendable, Equatable {
    /// Protection duels, attacker first. Offensive line against the rush.
    public let protection: [(blocker: Player, rusher: Player)]
    /// Route matchups, receiver against defender.
    public let routes: [(receiver: Player, defender: Player)]
    /// Run-lane matchups, blocker against front defender.
    public let runLane: [(blocker: Player, defender: Player)]
    public let passer: Player?
    public let carrier: Player?
    /// The pursuit the carrier has to beat, best defender first.
    public let pursuit: [Player]

    public init(
        protection: [(blocker: Player, rusher: Player)],
        routes: [(receiver: Player, defender: Player)],
        runLane: [(blocker: Player, defender: Player)],
        passer: Player?,
        carrier: Player?,
        pursuit: [Player]
    ) {
        self.protection = protection
        self.routes = routes
        self.runLane = runLane
        self.passer = passer
        self.carrier = carrier
        self.pursuit = pursuit
    }

    public static func == (lhs: SnapAssignment, rhs: SnapAssignment) -> Bool {
        lhs.protection.map(\.blocker.id) == rhs.protection.map(\.blocker.id)
            && lhs.protection.map(\.rusher.id) == rhs.protection.map(\.rusher.id)
            && lhs.routes.map(\.receiver.id) == rhs.routes.map(\.receiver.id)
            && lhs.routes.map(\.defender.id) == rhs.routes.map(\.defender.id)
            && lhs.runLane.map(\.blocker.id) == rhs.runLane.map(\.blocker.id)
            && lhs.passer?.id == rhs.passer?.id
            && lhs.carrier?.id == rhs.carrier?.id
            && lhs.pursuit.map(\.id) == rhs.pursuit.map(\.id)
    }
}

public enum Assignment {
    /// Assigns roles from the two calls and who is on the field.
    ///
    /// Pure and rng-free: assignment is a function of the calls and the personnel, and nothing
    /// here is a coin flip. Keeping the randomness entirely in stage 2 is what lets a replay pin
    /// the assignment and vary only the resolution.
    public static func assign(
        offensiveCall: OffensiveCall,
        defensiveCall: DefensiveCall,
        personnel: SnapPersonnel
    ) -> SnapAssignment {
        let line = personnel.offensive(group: .offensiveLine)
        let front = personnel.defensive(group: .defensiveLine)
            + personnel.defensive(group: .linebackers)
        let rushers = Array(front.prefix(defensiveCall.rushers))
        let coverageDefenders = personnel.defensive(group: .secondary)
            + personnel.defensive(group: .linebackers).dropFirst(
                Swift.max(0, defensiveCall.rushers - personnel.defensive(group: .defensiveLine).count)
            )

        // Each rusher is met by a blocker while blockers last; an unblocked rusher is the single
        // largest source of pressure and is modelled by pairing them against the weakest blocker
        // again rather than by dropping the matchup, so the record still names who lost.
        var protection: [(blocker: Player, rusher: Player)] = []
        if offensiveCall.playType == .pass, !line.isEmpty {
            for (index, rusher) in rushers.enumerated() {
                protection.append((blocker: line[Swift.min(index, line.count - 1)], rusher: rusher))
            }
        }

        var routes: [(receiver: Player, defender: Player)] = []
        if offensiveCall.playType == .pass {
            let receivers = personnel.offensive(group: .receivers)
                .prefix(MatchupRules.receiversInRoute)
            for (index, receiver) in receivers.enumerated() where !coverageDefenders.isEmpty {
                routes.append((receiver: receiver,
                               defender: coverageDefenders[index % coverageDefenders.count]))
            }
        }

        var runLane: [(blocker: Player, defender: Player)] = []
        if offensiveCall.playType == .run, !line.isEmpty, !front.isEmpty {
            for index in 0..<Swift.min(MatchupRules.runLaneMatchups, Swift.min(line.count, front.count)) {
                runLane.append((blocker: line[index], defender: front[index]))
            }
        }

        return SnapAssignment(
            protection: protection,
            routes: routes,
            runLane: runLane,
            passer: personnel.offensive(group: .quarterbacks).first,
            carrier: offensiveCall.playType == .run
                ? personnel.offensive(group: .runningBacks).first
                : nil,
            pursuit: SnapPersonnel.ranked(personnel.defense)
        )
    }
}
