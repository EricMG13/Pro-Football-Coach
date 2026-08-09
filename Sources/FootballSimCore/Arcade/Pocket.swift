import Foundation

/// How long the protection holds, and which rusher gets there first.
///
/// The unit-level anchors from `06` are honoured exactly — about 2.2 seconds behind a 55-rated
/// line, about 4.5 behind a 90 — by deciding the pocket's life *first* and then distributing the
/// individual breakthroughs around it. Drawing four independent duels and taking the minimum
/// would have been the obvious way round, and it is wrong: the minimum of four draws sits well
/// below their mean, so the calibrated number would quietly stop being the number that shipped.
public struct PocketState: Sendable {
    /// When each rusher arrives, in seconds after the snap.
    public let breakthroughs: [UUID: Double]
    /// When the first one arrives — the number the player feels.
    public let life: Double
    /// Who that first one is.
    public let firstArrival: UUID?

    public init(breakthroughs: [UUID: Double], life: Double, firstArrival: UUID?) {
        self.breakthroughs = breakthroughs
        self.life = life
        self.firstArrival = firstArrival
    }

    /// Whether a given rusher is through his block yet.
    public func hasBrokenThrough(_ rusherID: UUID, at elapsed: Double) -> Bool {
        guard let time = breakthroughs[rusherID] else { return false }
        return elapsed >= time
    }

    /// When the sack warning should flash for a quarterback of this awareness.
    public func warningTime(awareness: Int) -> Double {
        Swift.max(0, life - ArcadeTuning.sackWarningLead(awareness))
    }
}

public enum Pocket {

    /// Mean rating of a group, floored so a wiped-out unit still produces a usable number.
    static func unitRating(_ players: [FieldedPlayer], _ attribute: (Athlete) -> Int) -> Double {
        guard !players.isEmpty else { return Double(LeagueRules.ratingFloor) }
        let total = players.reduce(0.0) { $0 + Double(attribute($1.athlete)) }
        return total / Double(players.count)
    }

    /// Pairs rushers against blockers and decides when each one arrives.
    ///
    /// Every rusher past the number of available blockers is unblocked and duels against the
    /// rating floor, which is what makes an extra blitzer genuinely dangerous rather than merely
    /// one more disc on the screen.
    public static func resolve(
        blockers: [FieldedPlayer],
        rushers: [FieldedPlayer],
        rng: inout SeededRandom
    ) -> PocketState {
        guard !rushers.isEmpty else {
            return PocketState(breakthroughs: [:], life: ArcadeTuning.maxSnapSeconds, firstArrival: nil)
        }

        let lineUnit = unitRating(blockers) { Double($0.passBlock) > 0 ? $0.passBlock : $0.strength }
        let rushUnit = unitRating(rushers, { $0.passRush })

        var life = ArcadeTuning.pocketSeconds(lineUnit: lineUnit, rushUnit: rushUnit)
        // Jitter around the calibrated mean rather than away from it, so 500 snaps still average
        // the figure the design promises.
        life += rng.gaussian(mean: 0, sd: ArcadeTuning.breakthroughSpreadSeconds * 0.35)
        // An unblocked rusher is a different play entirely.
        if rushers.count > blockers.count { life *= ArcadeTuning.blitzBreakthroughFactor }
        life = Swift.min(ArcadeTuning.maxSnapSeconds, Swift.max(0.6, life))

        // Sort the ordered pairings by width so the edge rusher meets the edge blocker.
        let orderedRushers = rushers.sorted { $0.point.lateralYards < $1.point.lateralYards }
        let orderedBlockers = blockers.sorted { $0.point.lateralYards < $1.point.lateralYards }

        // Score each duel; the biggest winner is the man who gets home first.
        var scored: [(id: UUID, score: Double)] = []
        for (index, rusher) in orderedRushers.enumerated() {
            let blockerRating = index < orderedBlockers.count
                ? Double(orderedBlockers[index].athlete.passBlock)
                : Double(LeagueRules.ratingFloor)
            let edge = Double(rusher.athlete.passRush) - blockerRating
            scored.append((rusher.id, edge + rng.gaussian(mean: 0, sd: 8)))
        }
        scored.sort { $0.score > $1.score }

        var breakthroughs: [UUID: Double] = [:]
        for (rank, entry) in scored.enumerated() {
            // The winner arrives at the pocket's life; everybody else trails him.
            let stagger = Double(rank) * ArcadeTuning.breakthroughSpreadSeconds
                * (0.4 + rng.double01() * 0.6)
            breakthroughs[entry.id] = life + stagger
        }

        return PocketState(breakthroughs: breakthroughs, life: life, firstArrival: scored.first?.id)
    }
}
