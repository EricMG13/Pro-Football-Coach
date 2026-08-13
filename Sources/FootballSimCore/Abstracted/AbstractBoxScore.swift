import Foundation

/// Turns an abstracted team result into a full box score. `02` §3.11.
///
/// The abstracted model produced three yardage numbers and a touchdown count, so the whole defensive
/// half of every roster in the world accumulated nothing across a twenty-season save — and no rate
/// statistic was computable anywhere, because nothing counted an attempt.
///
/// **Derived, not drawn.** Every counter here is arithmetic over the team totals the simulator
/// already produced, at rates that live in `CompetitionRules`. That matters for two reasons: the
/// box score cannot contradict the team line it came from, and adding counters consumes no random
/// draws, so no existing seeded output moves because this exists.
public enum AbstractBoxScore {
    /// The team-level counters a box score needs beyond yards and points.
    ///
    /// Computed before the lines are cut so the lines can be made to sum to them exactly, rather
    /// than each player being given a plausible number and the team total being whatever they happen
    /// to add up to.
    public struct TeamContext: Sendable, Equatable {
        public let sacksAllowed: Int
        public let interceptionsThrown: Int
        public let fumblesLost: Int
        public let penalties: Int
        public let penaltyYards: Int

        public init(sacksAllowed: Int, interceptionsThrown: Int, fumblesLost: Int,
                    penalties: Int, penaltyYards: Int) {
            self.sacksAllowed = sacksAllowed
            self.interceptionsThrown = interceptionsThrown
            self.fumblesLost = fumblesLost
            self.penalties = penalties
            self.penaltyYards = penaltyYards
        }
    }

    /// Splits a team's turnovers and derives its sacks and flags.
    ///
    /// Deterministic from the totals rather than drawn: the simulator has already spent its draws on
    /// the result, and a box score that re-rolled would make the same game produce different
    /// evidence depending on how many times it was asked for it.
    public static func context(
        for statistics: TeamGameStatistics,
        opposingDefense: Int
    ) -> TeamContext {
        // Interceptions take the larger share of turnovers, and a fumble the rest, which is the
        // split real seasons show. An odd turnover goes to the interception because that is the more
        // common one.
        let interceptions = (statistics.turnovers + 1) / 2
        let fumbles = statistics.turnovers - interceptions
        let sacks = statistics.passingYards
            * CompetitionRules.sacksPerHundredPassYards
            / 100
        let penalties = CompetitionRules.basePenaltiesPerGame
            + (opposingDefense % CompetitionRules.penaltyVarianceModulus)
        return TeamContext(
            sacksAllowed: max(0, sacks),
            interceptionsThrown: interceptions,
            fumblesLost: fumbles,
            penalties: penalties,
            penaltyYards: penalties * CompetitionRules.averagePenaltyYards
        )
    }

    /// Cuts the offensive lines: quarterback, backs, receivers, kicker and punter.
    ///
    /// - Parameter touchdowns: the team's touchdowns, already derived from its points.
    public static func offensiveLines(
        roster: [Player],
        statistics: TeamGameStatistics,
        context: TeamContext,
        touchdowns: Int
    ) -> [PlayerGameStatistics] {
        var lines: [PlayerGameStatistics] = []
        let ranked = rank(roster)

        // Passing. Attempts come from yards at a stated yards-per-attempt, so completion percentage
        // is a real ratio rather than a number typed in beside it.
        let completions = statistics.passingYards / max(1, CompetitionRules.yardsPerCompletion)
        let attempts = completions * 100 / max(1, CompetitionRules.completionPercentEstimate)
        let passingTouchdowns = touchdowns * CompetitionRules.passingTouchdownPercent / 100
        if let quarterback = ranked.first(where: { $0.position == .quarterback }) {
            lines.append(PlayerGameStatistics(
                playerID: quarterback.id,
                passAttempts: max(completions, attempts),
                completions: completions,
                passingYards: statistics.passingYards,
                passingTouchdowns: passingTouchdowns,
                interceptionsThrown: context.interceptionsThrown,
                sacksTaken: context.sacksAllowed
            ))
        }

        let rushingTouchdowns = touchdowns - passingTouchdowns
        let runners = Array(ranked.filter { $0.position == .runningBack }
            .prefix(CompetitionRules.abstractedRunnersPerGame))
        lines.append(contentsOf: split(
            players: runners, yards: statistics.rushingYards, touchdowns: rushingTouchdowns,
            fumbles: context.fumblesLost
        ) { player, yards, scores, fumbles in
            PlayerGameStatistics(
                playerID: player.id,
                carries: max(1, yards / max(1, CompetitionRules.yardsPerCarry)),
                rushingYards: yards,
                touchdowns: scores,
                fumblesLost: fumbles
            )
        })

        let receivers = Array(ranked.filter {
            $0.position == .wideReceiver || $0.position == .tightEnd
        }.prefix(CompetitionRules.abstractedReceiversPerGame))
        lines.append(contentsOf: split(
            players: receivers, yards: statistics.passingYards, touchdowns: passingTouchdowns,
            fumbles: 0
        ) { player, yards, scores, _ in
            let caught = max(1, yards / max(1, CompetitionRules.yardsPerCompletion))
            return PlayerGameStatistics(
                playerID: player.id,
                targets: caught * 100 / max(1, CompetitionRules.completionPercentEstimate),
                receptions: caught,
                receivingYards: yards,
                touchdowns: scores
            )
        })

        // The kicking game. Points that were not touchdowns and not tries are field goals, which is
        // the only honest way to derive them from a points total.
        let tryPoints = touchdowns * MatchupRules.extraPointPoints
        let fieldGoalPoints = max(0, statistics.points
            - touchdowns * MatchupRules.touchdownPoints - tryPoints)
        let fieldGoalsMade = fieldGoalPoints / MatchupRules.fieldGoalPoints
        if let kicker = ranked.first(where: { $0.position == .kicker }) {
            let attempted = fieldGoalsMade * 100 / max(1, CompetitionRules.fieldGoalPercentEstimate)
            lines.append(PlayerGameStatistics(
                playerID: kicker.id,
                fieldGoalsAttempted: max(fieldGoalsMade, attempted),
                fieldGoalsMade: fieldGoalsMade,
                extraPointsAttempted: touchdowns,
                extraPointsMade: touchdowns
            ))
        }
        if let punter = ranked.first(where: { $0.position == .punter }) {
            let punts = max(0, CompetitionRules.basePuntsPerGame
                - statistics.offensiveYards / max(1, CompetitionRules.yardsPerFewerPunt))
            lines.append(PlayerGameStatistics(
                playerID: punter.id,
                punts: punts,
                puntYards: punts * MatchupRules.basePuntYards
            ))
        }
        return lines
    }

    /// Cuts the defensive lines for the side that was *not* on offence.
    ///
    /// - Parameters:
    ///   - roster: the defending team's roster.
    ///   - opponentContext: what the offence gave up — its sacks taken and turnovers are this
    ///     defence's sacks and takeaways, so the two lines cannot disagree.
    public static func defensiveLines(
        roster: [Player],
        opponentContext: TeamContext,
        opponentPlays: Int
    ) -> [PlayerGameStatistics] {
        let ranked = rank(roster.filter { $0.position.unit == .defense })
        guard !ranked.isEmpty else { return [] }
        let tacklers = Array(ranked.prefix(CompetitionRules.abstractedTacklersPerGame))
        let totalTackles = opponentPlays * CompetitionRules.tacklesPerHundredPlays / 100

        var lines: [PlayerGameStatistics] = []
        for (index, player) in tacklers.enumerated() {
            // A share that falls with depth: the front seven make most of them, and a flat split
            // would give every safety a linebacker's line.
            let weight = tacklers.count - index
            let denominator = tacklers.count * (tacklers.count + 1) / 2
            lines.append(PlayerGameStatistics(
                playerID: player.id,
                tackles: max(1, totalTackles * weight / max(1, denominator))
            ))
        }

        // Sacks go to the pass rushers, takeaways to the secondary, in ranked order and one at a
        // time, so the totals match the offence's exactly rather than approximately.
        let rushers = rank(roster.filter { $0.position.group == .defensiveLine })
        lines = award(opponentContext.sacksAllowed, to: rushers, in: lines) { line in
            PlayerGameStatistics(playerID: line, sacks: 1)
        }
        let secondary = rank(roster.filter { $0.position.group == .secondary })
        lines = award(opponentContext.interceptionsThrown, to: secondary, in: lines) { line in
            PlayerGameStatistics(playerID: line, interceptions: 1, passesDefended: 1)
        }
        let front = rank(roster.filter {
            $0.position.group == .defensiveLine || $0.position.group == .linebackers
        })
        lines = award(opponentContext.fumblesLost, to: front, in: lines) { line in
            PlayerGameStatistics(playerID: line, forcedFumbles: 1)
        }
        return lines
    }

    // MARK: - Helpers

    private static func rank(_ players: [Player]) -> [Player] {
        players.sorted {
            $0.overall == $1.overall
                ? $0.id.uuidString < $1.id.uuidString
                : $0.overall > $1.overall
        }
    }

    /// Splits a yardage total across players, largest share first, and hands the touchdowns and
    /// fumbles to the top of the list. Remainders go to the leaders, so the parts sum to the whole.
    private static func split(
        players: [Player],
        yards: Int,
        touchdowns: Int,
        fumbles: Int,
        build: (Player, Int, Int, Int) -> PlayerGameStatistics
    ) -> [PlayerGameStatistics] {
        guard !players.isEmpty else { return [] }
        let share = yards / players.count
        let remainder = yards % players.count
        return players.enumerated().map { index, player in
            build(
                player,
                share + (index < remainder ? 1 : 0),
                index < touchdowns ? 1 : 0,
                index < fumbles ? 1 : 0
            )
        }
    }

    /// Adds `count` single-event lines to the ranked candidates, wrapping if there are more events
    /// than candidates.
    private static func award(
        _ count: Int,
        to candidates: [Player],
        in lines: [PlayerGameStatistics],
        build: (UUID) -> PlayerGameStatistics
    ) -> [PlayerGameStatistics] {
        guard count > 0, !candidates.isEmpty else { return lines }
        var merged = lines
        for event in 0..<count {
            let player = candidates[event % candidates.count]
            let addition = build(player.id)
            if let index = merged.firstIndex(where: { $0.playerID == player.id }) {
                merged[index] = merged[index] + addition
            } else {
                merged.append(addition)
            }
        }
        return merged
    }
}
