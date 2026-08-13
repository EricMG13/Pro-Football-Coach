import Foundation

/// A player hurt on a snap. `02` §3.8.
///
/// Injuries were produced only by `PeopleLifecycleSystem`'s weekly draw, which runs at scheduler
/// step 2 — **before** the week's games at steps 10 and 11. So a player's knee went in the middle of
/// the week, from accumulated workload, and nobody was ever hurt during a match. In a sport where an
/// injury changes the game being played, that is a missing mechanic rather than a missing detail.
///
/// The engine **reports** rather than applies. `SnapResolver` has no access to `PeopleState` and
/// should not: a pure resolver that mutated league state could not be replayed. The season layer
/// applies these when the detailed match is integrated, using the same `PlayerInjury` vocabulary
/// this record is written in.
public struct MatchInjury: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let area: InjuryArea
    public let severity: InjurySeverity
    /// Weeks out, already adjusted for `ironman`.
    public let weeks: Int
    /// Whether the player leaves this game. Anything past a knock does.
    public let forcedOut: Bool

    public init(playerID: UUID, area: InjuryArea, severity: InjurySeverity, weeks: Int,
                forcedOut: Bool) {
        self.playerID = playerID
        self.area = area
        self.severity = severity
        self.weeks = weeks
        self.forcedOut = forcedOut
    }
}

/// Draws in-play injuries. `02` §3.8.
public enum InjuryModel {
    /// Draws a possible injury from the players a snap actually involved.
    ///
    /// Candidates come from the snap's own matchups and ball handlers rather than from all
    /// twenty-two, because who was in the collision is exactly what the engine already records —
    /// `04` §5.3 reads that record to draw the play, and an injury attributed to a player standing
    /// on the far hash would contradict the picture beside it.
    public static func draw(
        in outcome: SnapOutcome,
        personnel: SnapPersonnel,
        rng: inout SeededRandom
    ) -> MatchInjury? {
        guard rng.chance(MatchupRules.injuryChancePerSnap) else { return nil }

        var candidateIDs: [UUID] = []
        for matchup in outcome.matchups {
            candidateIDs.append(matchup.attackerID)
            candidateIDs.append(matchup.defenderID)
        }
        if let carrier = outcome.ballCarrierID { candidateIDs.append(carrier) }
        if let passer = outcome.passerID { candidateIDs.append(passer) }
        if let target = outcome.targetID { candidateIDs.append(target) }

        let everyone = personnel.offense + personnel.defense
        let byID = Dictionary(everyone.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        // Ranked and de-duplicated so the candidate order is a property of the snap rather than of
        // dictionary iteration, which is not stable across runs.
        var seen: Set<UUID> = []
        var candidates = candidateIDs.compactMap { id -> Player? in
            guard seen.insert(id).inserted else { return nil }
            return byID[id]
        }
        if candidates.isEmpty { candidates = SnapPersonnel.ranked(everyone) }
        guard !candidates.isEmpty else { return nil }

        // Durability decides who, the same way `volatile` decides who draws a flag: a rating that
        // only moved a team-wide rate would never show up on the player carrying it.
        let weights = candidates.map {
            Swift.max(1, SharedRules.ratingRange.upperBound - $0.attributes[.durability].value)
        }
        let total = weights.reduce(0, +)
        var target = rng.double01() * Double(total)
        var chosen = candidates[candidates.count - 1]
        for (index, weight) in weights.enumerated() {
            target -= Double(weight)
            if target < 0 {
                chosen = candidates[index]
                break
            }
        }

        let ladder = PeopleRules.injurySeverity(roll: rng.double01())
        let weeks = PeopleRules.injuryWeeks(rng.int(in: ladder.weeks),
                                            ironman: chosen.has(.ironman))
        return MatchInjury(
            playerID: chosen.id,
            area: rng.pick(InjuryArea.allCases),
            severity: ladder.severity,
            weeks: weeks,
            forcedOut: ladder.severity != .minor
        )
    }
}
