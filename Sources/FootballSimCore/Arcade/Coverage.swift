import Foundation

/// Who covers whom, and how well.
///
/// Blitz vacancy is not special-cased anywhere in here: a blitzing defender is given the rusher
/// role by `Formations`, so nobody is left steering at the receiver he would have covered and
/// the window behind him opens on its own. Emergent rather than scripted, which means the
/// tactical trade-off in a blitz is real rather than a number someone typed.
public enum Coverage {

    /// How man-heavy each call is. Base plays the outside receivers in man and keeps the
    /// safeties over the top; the sub packages chase receivers; the soft calls sit in zone.
    public static func manCoverageSlots(for call: DefensivePlay) -> Int {
        switch call {
        case .base: 2
        case .blitz: 3
        case .nickel: 3
        case .dime: 4
        case .contain: 1
        case .prevent: 0
        }
    }

    /// Assigns the secondary. Corners take the widest receivers first, which is what puts a
    /// team's best cover man on the ball rather than on a decoy.
    public static func assign(
        defenders: inout [FieldedPlayer],
        offense: [FieldedPlayer],
        call: DefensivePlay
    ) {
        let receivers = offense
            .filter { if case .receiver = $0.role { return true } else { return false } }
            .sorted { abs($0.point.lateralYards) > abs($1.point.lateralYards) }
        guard !receivers.isEmpty else { return }

        var manSlots = manCoverageSlots(for: call)
        var claimed: Set<UUID> = []

        // Corners first, then safeties, then any linebacker still available.
        let coverageOrder: [Position] = [.cb, .s, .lb]
        for position in coverageOrder {
            for index in defenders.indices {
                guard manSlots > 0 else { break }
                guard defenders[index].athlete.position == position else { continue }
                // A rusher is rushing; he is not also covering somebody.
                if case .rusher = defenders[index].role { continue }
                guard let target = receivers.first(where: { !claimed.contains($0.id) }) else { break }
                claimed.insert(target.id)
                defenders[index].role = .manCoverage(target: target.id)
                manSlots -= 1
            }
        }

        // Whoever is left drops into a zone anchored where they lined up, deepened for the
        // calls that are protecting the field rather than attacking it.
        let zoneDepthBonus: Double = call == .prevent ? 6 : (call == .contain ? 2 : 0)
        for index in defenders.indices {
            switch defenders[index].role {
            case .rusher, .manCoverage:
                continue
            case .runDefender:
                // Linebackers keep run responsibility unless the call has taken them out of it.
                if call == .prevent || call == .dime {
                    defenders[index].role = .zoneCoverage(
                        anchor: FieldPoint(
                            depth: defenders[index].point.depth + zoneDepthBonus + 4,
                            lateral: defenders[index].point.lateral
                        )
                    )
                }
            case .zoneCoverage(let anchor):
                defenders[index].role = .zoneCoverage(
                    anchor: FieldPoint(depth: anchor.depth + zoneDepthBonus, lateral: anchor.lateral)
                )
            case .quarterback, .receiver, .blocker, .carrier:
                continue
            }
        }
    }

    /// The spot a defender is trying to get to right now.
    ///
    /// Man coverage aims ahead of the receiver by an amount his coverage rating buys — good
    /// cover men play the route, poor ones chase the jersey. Zone defenders sit on their anchor
    /// until somebody threatens it, then break on the nearest live threat.
    public static func aimPoint(
        for defender: FieldedPlayer,
        offense: [FieldedPlayer],
        ballPoint: FieldPoint,
        ballIsLoose: Bool,
        dials: ArcadeTuning.DifficultyDials
    ) -> FieldPoint {
        switch defender.role {
        case .manCoverage(let targetID):
            guard let target = offense.first(where: { $0.id == targetID }) else { return ballPoint }
            if ballIsLoose { return target.point }
            let anticipation = ArcadeTuning.curve(defender.athlete.coverage, at40: 0.05, at99: 0.42)
                * dials.coverageDiscipline
            return FieldPoint.yards(
                depth: target.point.depth + target.velocity.depth * anticipation,
                lateralYards: target.point.lateralYards + target.velocity.lateralYards * anticipation
            )

        case .zoneCoverage(let anchor):
            guard !ballIsLoose else { return ballPoint }
            // Break on the most threatening receiver inside the zone's radius.
            let radius = ArcadeTuning.curve(defender.athlete.coverage, at40: 5.0, at99: 9.0)
                * dials.coverageDiscipline
            let threats = offense.filter {
                if case .receiver = $0.role { return $0.point.distance(to: anchor) <= radius }
                return false
            }
            guard let nearest = threats.min(by: {
                $0.point.distance(to: anchor) < $1.point.distance(to: anchor)
            }) else { return anchor }
            // Split the difference: a zone defender does not abandon his area entirely.
            return FieldPoint.yards(
                depth: (nearest.point.depth + anchor.depth) / 2,
                lateralYards: (nearest.point.lateralYards + anchor.lateralYards) / 2
            )

        case .runDefender:
            return ballPoint

        case .rusher, .carrier, .quarterback, .receiver, .blocker:
            return ballPoint
        }
    }

    /// Separation in yards between a receiver and his nearest defender, with the defender.
    public static func nearestDefender(
        to receiver: FieldedPlayer,
        defenders: [FieldedPlayer]
    ) -> (defender: FieldedPlayer, separation: Double)? {
        var best: (FieldedPlayer, Double)?
        for defender in defenders where !defender.isBeaten {
            let distance = defender.point.distance(to: receiver.point)
            if best == nil || distance < best!.1 { best = (defender, distance) }
        }
        guard let found = best else { return nil }
        return (found.0, found.1)
    }
}
