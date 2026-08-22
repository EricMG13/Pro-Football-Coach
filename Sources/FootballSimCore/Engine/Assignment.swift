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
public struct SnapPersonnel: Codable, Sendable, Equatable {
    public let offense: [Player]
    public let defense: [Player]

    public init(offense: [Player], defense: [Player]) {
        self.offense = offense
        self.defense = defense
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
            let receivers = SnapPersonnel.ranked(personnel.offense.filter {
                $0.position.group == .receivers || $0.position == .runningBack
            })
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
