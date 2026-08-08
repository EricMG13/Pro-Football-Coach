import Foundation

/// Turns results into headlines. The feed is what makes a simulated league feel inhabited —
/// a season of numbers becomes a season of stories.
public enum NewsEngine {

    /// Headlines for one week of results, user's team first.
    public static func weekRecap(results: [GameRecord], league: League, week: Int) -> [NewsItem] {
        var items: [NewsItem] = []
        var rng = SeededRandom(seed: UInt64(week &* 7919 &+ league.year &* 31))

        for record in results {
            guard let home = league.team(id: record.homeTeamID),
                  let away = league.team(id: record.awayTeamID) else { continue }

            let winner = record.winnerID.flatMap { league.team(id: $0) }
            let loser = record.loserID.flatMap { league.team(id: $0) }
            let margin = abs(record.homeScore - record.awayScore)

            let headline: String
            if let winner, let loser {
                if margin >= 24 {
                    headline = "\(winner.name) rout \(loser.name), \(max(record.homeScore, record.awayScore))-\(min(record.homeScore, record.awayScore))"
                } else if record.wentToOvertime {
                    headline = "\(winner.name) survive overtime against \(loser.name)"
                } else if margin <= 3 {
                    headline = "\(winner.name) edge \(loser.name) by \(margin)"
                } else {
                    headline = "\(winner.name) beat \(loser.name), \(max(record.homeScore, record.awayScore))-\(min(record.homeScore, record.awayScore))"
                }
            } else {
                headline = "\(home.name) and \(away.name) play to a \(record.homeScore)-\(record.awayScore) draw"
            }

            items.append(
                NewsItem(
                    id: rng.uuid(),
                    year: league.year,
                    week: week,
                    category: .gameResult,
                    headline: headline,
                    body: standoutLine(record: record, league: league) ?? "",
                    teamIDs: [home.id, away.id]
                )
            )

            for injury in record.injuries {
                items.append(
                    NewsItem(
                        id: rng.uuid(),
                        year: league.year,
                        week: week,
                        category: .injury,
                        headline: injury.description,
                        teamIDs: [injury.teamID]
                    )
                )
            }
        }

        // The user's own team leads the feed.
        return items.sorted { lhs, rhs in
            let lhsIsUser = lhs.teamIDs.contains(league.userTeamID)
            let rhsIsUser = rhs.teamIDs.contains(league.userTeamID)
            if lhsIsUser != rhsIsUser { return lhsIsUser }
            return false
        }
    }

    /// Picks the standout individual performance from a game, if there was one.
    private static func standoutLine(record: GameRecord, league: League) -> String? {
        var best: (name: String, line: String, score: Int)?

        // Sorted rather than raw dictionary order, which Swift randomises per process: two
        // players tied on the same score would otherwise give different headlines on different
        // launches, and the headline is written into the save.
        for (playerID, stats) in record.playerStats
            .sorted(by: { $0.key.uuidString < $1.key.uuidString }) {
            guard let (player, _) = league.findPlayer(id: playerID) else { continue }
            var score = 0
            var description = ""

            if stats.passingYards >= 300 || stats.passingTouchdowns >= 3 {
                score = stats.passingYards + stats.passingTouchdowns * 60
                description = "\(stats.passingYards) yards and \(stats.passingTouchdowns) touchdowns through the air"
            } else if stats.rushingYards >= 100 || stats.rushingTouchdowns >= 2 {
                score = stats.rushingYards * 2 + stats.rushingTouchdowns * 60
                description = "\(stats.rushingYards) yards on \(stats.carries) carries"
            } else if stats.receivingYards >= 100 || stats.receivingTouchdowns >= 2 {
                score = stats.receivingYards * 2 + stats.receivingTouchdowns * 60
                description = "\(stats.receptions) catches for \(stats.receivingYards) yards"
            } else if stats.sacks >= 2 {
                score = stats.sacks * 100
                description = "\(stats.sacks) sacks"
            } else if stats.interceptions >= 2 {
                score = stats.interceptions * 120
                description = "\(stats.interceptions) interceptions"
            }

            if score > 0, score > (best?.score ?? 0) {
                best = (player.name, description, score)
            }
        }

        guard let best else { return nil }
        return "\(best.name): \(best.line)."
    }

    public static func signing(
        player: Player,
        team: Team,
        contract: Contract,
        league: League,
        rng: inout SeededRandom
    ) -> NewsItem {
        let years = contract.years
        let perYear = contract.averagePerYear
        return NewsItem(
            id: rng.uuid(),
            year: league.year,
            week: 0,
            category: .signing,
            headline: "\(team.name) sign \(player.position.abbreviation) \(player.name)",
            body: "\(years) year\(years == 1 ? "" : "s"), \(money(perYear)) per year.",
            teamIDs: [team.id]
        )
    }

    public static func trade(
        from: Team,
        to: Team,
        summary: String,
        league: League,
        rng: inout SeededRandom
    ) -> NewsItem {
        NewsItem(
            id: rng.uuid(),
            year: league.year,
            week: 0,
            category: .trade,
            headline: "\(from.name) and \(to.name) swing a deal",
            body: summary,
            teamIDs: [from.id, to.id]
        )
    }

    public static func retirement(player: Player, team: Team?, league: League, rng: inout SeededRandom) -> NewsItem {
        NewsItem(
            id: rng.uuid(),
            year: league.year,
            week: 0,
            category: .retirement,
            headline: "\(player.position.abbreviation) \(player.name) retires at \(player.age)",
            body: team.map { "After his time with the \($0.name)." } ?? "",
            teamIDs: team.map { [$0.id] } ?? []
        )
    }

    /// Formats integer dollars the way the rest of the app shows money.
    public static func money(_ amount: Int) -> String {
        let millions = Double(amount) / 1_000_000
        if abs(millions) >= 1 {
            return millions == millions.rounded()
                ? String(format: "$%.0fM", millions)
                : String(format: "$%.1fM", millions)
        }
        return String(format: "$%.0fK", Double(amount) / 1_000)
    }
}
