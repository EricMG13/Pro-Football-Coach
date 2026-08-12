import Foundation

/// Moves prestige toward what the table says, one point a season.
///
/// Prestige was frozen at generation. A programme that won titles for a decade was exactly as
/// prestigious as one that never won, while prestige drives recruiting pull, the AI's valuations and
/// which jobs a coach is offered — so the world could not evolve in the one dimension every other
/// system reads. `02` §8 asks the map to change across a career; this is the half of it that is a
/// programme's own standing rather than its conference.
///
/// **A target with a one-point step, not a delta.** The obvious rule — win, gain; lose, drop — has no
/// restoring force and walks a programme to an extreme and off the scale. Instead the final ranking
/// maps to a *target* prestige, and prestige steps one point toward it. Consequences worth having:
/// a programme that settles at a rank converges and stays there rather than drifting; the ceiling
/// and floor are reached by standing there, not by arithmetic; and twenty seasons can move a
/// programme twenty points, which is a career-length change rather than a whiplash.
public enum ProgrammeEvolutionSystem {
    /// The most prestige can move in one season, in either direction.
    public static let maximumSeasonalDrift = 1

    /// Applies both tables. An empty ranking moves nobody — a season that produced no table says
    /// nothing about anybody's standing, and inventing a target from silence is how a world drifts
    /// for no reason.
    public static func process(
        collegeRanking: [UUID],
        proRanking: [UUID],
        in state: GameState
    ) -> GameState {
        var next = state
        for (position, programmeID) in collegeRanking.enumerated() {
            let target = targetPrestige(position: position, of: collegeRanking.count)
            next.programmes.update(programmeID) { programme in
                programme.prestige = stepped(programme.prestige, toward: target)
            }
        }
        for (position, teamID) in proRanking.enumerated() {
            let target = targetPrestige(position: position, of: proRanking.count)
            next.proTeams.update(teamID) { team in
                team.prestige = stepped(team.prestige, toward: target)
            }
        }
        return next
    }

    /// Where a finishing position sits on the rating scale: first is the ceiling, last is the floor,
    /// linear between. Integer arithmetic throughout, so the mapping is identical on every machine.
    static func targetPrestige(position: Int, of count: Int) -> Int {
        let low = SharedRules.ratingRange.lowerBound
        let high = SharedRules.ratingRange.upperBound
        guard count > 1 else { return high }
        let clamped = Swift.min(Swift.max(position, 0), count - 1)
        return high - (high - low) * clamped / (count - 1)
    }

    private static func stepped(_ current: Rating, toward target: Int) -> Rating {
        if current.value == target { return current }
        let direction = target > current.value ? maximumSeasonalDrift : -maximumSeasonalDrift
        return Rating(current.value + direction)
    }
}
