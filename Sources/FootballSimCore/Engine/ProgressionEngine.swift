import Foundation

/// How a player changed over an offseason, so training camp can show it rather than just
/// quietly rewriting the roster — opaque progression was a standing complaint about the games
/// this one follows.
public struct DevelopmentResult: Sendable, Equatable {
    public let playerID: UUID
    public let teamID: UUID
    public let playerName: String
    public let position: Position
    public let overallBefore: Int
    public let overallAfter: Int
    public let isBreakout: Bool
    public let isRegression: Bool

    public var delta: Int { overallAfter - overallBefore }

    public init(
        playerID: UUID,
        teamID: UUID,
        playerName: String,
        position: Position,
        overallBefore: Int,
        overallAfter: Int,
        isBreakout: Bool,
        isRegression: Bool
    ) {
        self.playerID = playerID
        self.teamID = teamID
        self.playerName = playerName
        self.position = position
        self.overallBefore = overallBefore
        self.overallAfter = overallAfter
        self.isBreakout = isBreakout
        self.isRegression = isRegression
    }
}

/// Ages the league: young players grow toward their ceiling, old ones decline.
public enum ProgressionEngine {

    /// Runs training camp for every team and reports what changed.
    @discardableResult
    public static func runTrainingCamp(_ league: inout League) -> [DevelopmentResult] {
        var results: [DevelopmentResult] = []

        for teamIndex in league.teams.indices {
            let team = league.teams[teamIndex]
            let offensiveBonus = team.staff(.offensiveCoordinator)?.developmentBonus ?? 0
            let defensiveBonus = team.staff(.defensiveCoordinator)?.developmentBonus ?? 0
            let coachBonus = CoachEngine.developmentBonus(for: league.coach)
                * (team.id == league.userTeamID ? 1 : 0)

            for playerIndex in team.roster.indices {
                var player = league.teams[teamIndex].roster[playerIndex]
                let before = player.overall

                let staffBonus = player.position.isOffense
                    ? offensiveBonus
                    : (player.position.isDefense ? defensiveBonus : 0)
                let result = develop(
                    player: &player,
                    staffBonus: staffBonus + coachBonus,
                    rng: &league.rng
                )

                player.age += 1
                player.yearsPro += 1
                league.teams[teamIndex].roster[playerIndex] = player

                if player.overall != before || result != .none {
                    results.append(
                        DevelopmentResult(
                            playerID: player.id,
                            teamID: team.id,
                            playerName: player.name,
                            position: player.position,
                            overallBefore: before,
                            overallAfter: player.overall,
                            isBreakout: result == .breakout,
                            isRegression: result == .collapse
                        )
                    )
                }
            }
            league.teams[teamIndex].autoSortDepthChart()
        }

        // Free agents age too, or the market would fill up with ageless 27-year-olds.
        for index in league.freeAgents.indices {
            var player = league.freeAgents[index]
            _ = develop(player: &player, staffBonus: 0, rng: &league.rng)
            player.age += 1
            player.yearsPro += 1
            league.freeAgents[index] = player
        }

        return results
    }

    private enum Outcome: Equatable {
        case none, breakout, collapse
    }

    /// Applies one year of development or decline to a single player.
    private static func develop(
        player: inout Player,
        staffBonus: Double,
        rng: inout SeededRandom
    ) -> Outcome {
        let peak = LeagueRules.peakAgeWindow(player.position)
        let ceiling = player.projectedCeiling
        var change = 0.0
        var outcome = Outcome.none

        if player.age < peak.lowerBound {
            // Still climbing: grade sets the pace, and the closer to his ceiling the slower.
            let headroom = Double(ceiling - player.overall)
            let base = 2.4 * player.potential.developmentMultiplier
            change = base * min(1.4, max(0.15, headroom / 12)) * (1 + staffBonus)
            if player.has(.lateBloomer) { change *= 0.8 }
            if rng.chance(0.06 * player.potential.developmentMultiplier), headroom > 6 {
                change += Double(rng.int(in: 4...8))
                outcome = .breakout
            }
        } else if player.age <= peak.upperBound {
            // Prime: small moves either way.
            change = rng.gaussian(mean: 0.4 * (1 + staffBonus), sd: 1.6)
            if player.has(.lateBloomer) { change += 0.9 }
            if rng.chance(0.03), player.overall < ceiling - 4 {
                change += Double(rng.int(in: 3...6))
                outcome = .breakout
            }
        } else {
            // Decline accelerates with every year past peak.
            let yearsPast = Double(player.age - peak.upperBound)
            change = -(0.8 + yearsPast * 0.75) * (1 - staffBonus * 0.5)
            if player.has(.lateBloomer) { change *= 0.6 }
            if rng.chance(0.05 + yearsPast * 0.02) {
                change -= Double(rng.int(in: 3...7))
                outcome = .collapse
            }
        }

        // Age hits the athletic attributes first; craft and awareness hold up longer.
        let rounded = Int(change.rounded())
        guard rounded != 0 else { return outcome }
        applyDelta(rounded, to: &player, decliningPhase: player.age > peak.upperBound, rng: &rng)
        return outcome
    }

    private static func applyDelta(
        _ delta: Int,
        to player: inout Player,
        decliningPhase: Bool,
        rng: inout SeededRandom
    ) {
        let athletic: Set<Attribute> = [.speed, .agility]
        let mental: Set<Attribute> = [.awareness]

        for attribute in player.position.attributes {
            var scaled = Double(delta)
            if decliningPhase {
                if athletic.contains(attribute) { scaled *= 1.5 }
                if mental.contains(attribute) { scaled = max(0, scaled * 0.2) }
            } else if mental.contains(attribute) {
                // Experience always accrues, even on a bad year.
                scaled = max(scaled, 0.5)
            }
            // Jitter so two players never develop identically.
            let jitter = rng.gaussian(mean: scaled, sd: 0.8)
            player.ratings[attribute] = player.ratings[attribute] + Int(jitter.rounded())
        }
    }
}
