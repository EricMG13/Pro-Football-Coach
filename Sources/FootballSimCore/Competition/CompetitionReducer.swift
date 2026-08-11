import Foundation

public enum CompetitionReducer {
    public static func rebuild(from state: GameState) -> CompetitionState {
        var intermediate = state
        intermediate.competition = rebuildStandings(from: state)
        return rebuildStatistics(from: intermediate)
    }

    public static func rebuildStandings(from state: GameState) -> CompetitionState {
        var competition = state.competition
        var rowsByID: [UUID: StandingRow] = [:]
        var tierByID: [UUID: Tier] = [:]
        var conferenceByID: [UUID: UUID] = [:]
        var headToHeadWinner: [String: UUID] = [:]

        for programme in state.programmes.values {
            rowsByID[programme.id] = StandingRow(id: programme.id)
            tierByID[programme.id] = .college
            conferenceByID[programme.id] = programme.conferenceID
        }
        for team in state.proTeams.values {
            rowsByID[team.id] = StandingRow(id: team.id)
            tierByID[team.id] = .pro
            conferenceByID[team.id] = team.conferenceID
        }

        for game in competition.currentSchedule.games {
            guard game.stage == .regularSeason, let result = game.result else { continue }
            let isConferenceGame = conferenceByID[game.homeID] != nil
                && conferenceByID[game.homeID] == conferenceByID[game.awayID]
            rowsByID[game.homeID]?.record(
                pointsFor: result.homeScore,
                pointsAgainst: result.awayScore,
                conferenceGame: isConferenceGame
            )
            rowsByID[game.awayID]?.record(
                pointsFor: result.awayScore,
                pointsAgainst: result.homeScore,
                conferenceGame: isConferenceGame
            )
            headToHeadWinner[teamPairKey(game.homeID, game.awayID)] = result.homeScore > result.awayScore
                ? game.homeID
                : game.awayID
        }

        var standings: [Tier: [StandingRow]] = [:]
        var rankings: [Tier: [UUID]] = [:]
        for tier in Tier.allCases {
            let ordered = rankedRows(
                rowsByID.values.filter { tierByID[$0.id] == tier },
                headToHeadWinner: headToHeadWinner
            )
            standings[tier] = ordered
            rankings[tier] = ordered.map(\.id)
        }
        competition.standings = standings
        competition.rankings = rankings
        return competition
    }

    public static func rebuildStatistics(from state: GameState) -> CompetitionState {
        var competition = state.competition
        var teamStatistics: [UUID: TeamSeasonStatistics] = [:]
        var playerStatistics: [UUID: PlayerSeasonStatistics] = [:]
        var recordBook = competition.recordBook
        for id in state.programmes.ids + state.proTeams.ids {
            teamStatistics[id] = TeamSeasonStatistics()
        }
        for game in competition.currentSchedule.games {
            guard let result = game.result else { continue }
            recordBook.consider(game, result: result)
            teamStatistics[game.homeID]?.record(result.homeStatistics)
            teamStatistics[game.awayID]?.record(result.awayStatistics)
            for playerID in result.homeParticipantIDs + result.awayParticipantIDs {
                var aggregate = playerStatistics[playerID]
                    ?? PlayerSeasonStatistics(playerID: playerID)
                aggregate.recordAppearance()
                playerStatistics[playerID] = aggregate
            }
            for line in result.playerStatistics {
                var aggregate = playerStatistics[line.playerID]
                    ?? PlayerSeasonStatistics(playerID: line.playerID)
                aggregate.recordProduction(line)
                playerStatistics[line.playerID] = aggregate
            }
        }
        competition.teamStatistics = teamStatistics
        competition.playerStatistics = playerStatistics
        competition.recordBook = recordBook
        return competition
    }

    private static func rankedRows(
        _ rows: [StandingRow],
        headToHeadWinner: [String: UUID]
    ) -> [StandingRow] {
        let overallOrdered = rows.sorted {
            if equalWinningPercentage($0, $1) { return $0.id.uuidString < $1.id.uuidString }
            return winningPercentageAhead($0, $1)
        }
        var result: [StandingRow] = []
        var start = 0
        while start < overallOrdered.count {
            var end = start + 1
            while end < overallOrdered.count
                && equalWinningPercentage(overallOrdered[start], overallOrdered[end]) {
                end += 1
            }
            var tied = Array(overallOrdered[start..<end])
            if tied.count == 2,
               let winnerID = headToHeadWinner[teamPairKey(tied[0].id, tied[1].id)] {
                if tied[1].id == winnerID { tied.swapAt(0, 1) }
            } else {
                tied.sort(by: conferenceAndPointsAhead)
            }
            result.append(contentsOf: tied)
            start = end
        }
        return result
    }

    private static func equalWinningPercentage(_ lhs: StandingRow, _ rhs: StandingRow) -> Bool {
        let lhsGames = max(1, lhs.games)
        let rhsGames = max(1, rhs.games)
        return lhs.wins * rhsGames == rhs.wins * lhsGames
    }

    private static func winningPercentageAhead(_ lhs: StandingRow, _ rhs: StandingRow) -> Bool {
        lhs.wins * max(1, rhs.games) > rhs.wins * max(1, lhs.games)
    }

    private static func teamPairKey(_ lhs: UUID, _ rhs: UUID) -> String {
        let ids = [lhs.uuidString, rhs.uuidString].sorted()
        return "\(ids[0])|\(ids[1])"
    }

    private static func conferenceAndPointsAhead(_ lhs: StandingRow, _ rhs: StandingRow) -> Bool {
        let lhsConferenceGames = max(1, lhs.conferenceGames)
        let rhsConferenceGames = max(1, rhs.conferenceGames)
        let lhsConferenceCrossProduct = lhs.conferenceWins * rhsConferenceGames
        let rhsConferenceCrossProduct = rhs.conferenceWins * lhsConferenceGames
        if lhsConferenceCrossProduct != rhsConferenceCrossProduct {
            return lhsConferenceCrossProduct > rhsConferenceCrossProduct
        }
        if lhs.pointDifferential != rhs.pointDifferential {
            return lhs.pointDifferential > rhs.pointDifferential
        }
        if lhs.pointsFor != rhs.pointsFor { return lhs.pointsFor > rhs.pointsFor }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
