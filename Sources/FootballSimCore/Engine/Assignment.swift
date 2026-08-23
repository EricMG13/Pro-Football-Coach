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
    ///
    /// Ordered by who actually gets there for *this* call, not by the depth chart. See
    /// `Assignment.pursuitOrder`.
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
            pursuit: pursuitOrder(
                offensiveCall: offensiveCall,
                front: front,
                coverage: coverageDefenders,
                personnel: personnel
            )
        )
    }

    /// Who reaches the carrier, in the order they get there.
    ///
    /// **This was `ranked(personnel.defense)` until 2026-08-23** -- best-overall-first, and blind to
    /// the call. `yardsAfterContact` always starts its break-tackle chain at index zero, so the
    /// highest-rated defender on the field was the recorded tackler on *every snap of a game*:
    /// measured over 200 resolved snaps, all 200 went to one position. It also meant the carrier
    /// always ran at the best tackler on the field, which is not a neutral simplification -- it is
    /// a systematic overestimate of the defence at the one moment that decides the yardage.
    ///
    /// The replacement keys on what the record already knows. A run is met by the front seven, and
    /// by the part of it the ball is going at; a catch happens downfield, where the secondary is.
    /// The near side of the gap leads, so two runs to different gaps do not produce the same first
    /// man. Nothing here is a coin flip -- assignment stays pure and rng-free, per §1.1 -- and the
    /// full ranked defence is appended so the chain can never run short of men.
    public static func pursuitOrder(
        offensiveCall: OffensiveCall,
        front: [Player],
        coverage: [Player],
        personnel: SnapPersonnel
    ) -> [Player] {
        let ordered: [Player]
        switch offensiveCall.playType {
        case .run:
            let interior = SnapPersonnel.ranked(
                personnel.defense.filter { $0.position == .defensiveTackle }
            )
            let edges = SnapPersonnel.ranked(
                personnel.defense.filter { $0.position == .edgeRusher }
            )
            let backers = personnel.defensive(group: .linebackers)
            // Outside runs are met at the edge, inside runs in the interior. The other half of the
            // line is still in the chase, just behind the men whose gap it actually was.
            let firstWave = offensiveCall.runGap.isOutside ? edges : interior
            let secondWave = offensiveCall.runGap.isOutside ? interior : edges
            ordered = nearSideFirst(firstWave, gap: offensiveCall.runGap)
                + nearSideFirst(backers, gap: offensiveCall.runGap)
                + secondWave + coverage

        case .pass:
            // A completed pass is caught where the coverage is. The front rushed the passer and
            // arrives late, if at all -- and the resolver hoists the man who was actually beaten on
            // the route ahead of everyone, because for a catch it knows exactly who that was.
            ordered = coverage + front

        case .fieldGoal, .punt, .kneel:
            // No gap and no route to key on. A kneel is not tackled at all and a return is met by
            // whoever is nearest, which the record does not describe. Unchanged, deliberately.
            ordered = SnapPersonnel.ranked(personnel.defense)
        }

        // Linebackers appear in both `front` and `coverage`, so first appearance wins; the ranked
        // defence backfills anyone neither list named.
        var seen: Set<UUID> = []
        return (ordered + SnapPersonnel.ranked(personnel.defense)).filter { seen.insert($0.id).inserted }
    }

    /// Who meets the carrier, once the line has actually been resolved.
    ///
    /// `pursuitOrder` runs in `assign`, before a single duel has been scored, so the best it can do
    /// is key on the call. Lane quality is the thing that decides *where* the carrier is met, and it
    /// is known by the time anyone tackles him -- so the run path applies this on top.
    ///
    /// Three levels, and the reason there are three rather than two is that two produced the defect
    /// in a mirror. A static order hands the first man in the list almost every recorded stop,
    /// because only the first attempt is recorded on a snap nobody breaks; so whichever level leads
    /// unconditionally takes the lot. Keying on lane quality means the level that leads *varies with
    /// what actually happened at the line*, which is both the football answer and the only thing
    /// that spreads the record without inventing a spread.
    ///
    /// A permutation, never a filter: every defender keeps a place in the chase, so the break-tackle
    /// chain can still run its full length whatever the lane did.
    public static func atTheSecondLevel(_ pursuit: [Player], lane: Double) -> [Player] {
        let level: (Player) -> Bool
        if lane > MatchupRules.openFieldLaneThreshold {
            level = { $0.position.group == .secondary }
        } else if lane > MatchupRules.secondLevelLaneThreshold {
            level = { $0.position == .linebacker }
        } else {
            return pursuit
        }
        let promoted = pursuit.filter(level)
        guard !promoted.isEmpty else { return pursuit }
        return promoted + pursuit.filter { !level($0) }
    }

    /// The men on the side the ball is going, first.
    ///
    /// Deterministic and rng-free. This is what stops one gap's answer being every gap's answer:
    /// with it, a run left and a run right are met by different people.
    public static func nearSideFirst(_ players: [Player], gap: RunGap) -> [Player] {
        guard players.count > 1 else { return players }
        let leadsLeft = gap == .insideLeft || gap == .outsideLeft
        let lead = leadsLeft ? 0 : players.count - 1
        return [players[lead]] + players.indices.filter { $0 != lead }.map { players[$0] }
    }
}
