import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func competitionStageLabel(_ stage: CompetitionStage) -> String {
        switch stage {
        case .regularSeason: "Regular season"
        case .conferenceChampionship: "Conference championship"
        case .quarterfinal: "Quarterfinal"
        case .semifinal: "Semifinal"
        case .championship: "Championship"
        }
    }

    static func controlledCompetitionTier(from state: GameState) -> Tier {
        if state.career.college != nil { return .college }
        return state.careerArc.currentJob?.tier == .professional ? .pro : .college
    }

    static func competitionOverview(
        tier: Tier = .college,
        from state: GameState
    ) -> CompetitionOverviewReadModel {
        let controlledID = state.career.college?.programmeID
            ?? state.careerArc.currentJob?.organisationID
        let order = state.competition.rankings[tier] ?? []
        let rankings = order.enumerated().compactMap { index, id -> CompetitionOverviewReadModel.RankingRow? in
            guard let row = standingRow(id, in: state) else { return nil }
            let record = row.ties == 0
                ? String(row.wins) + "-" + String(row.losses)
                : String(row.wins) + "-" + String(row.losses) + "-" + String(row.ties)
            return CompetitionOverviewReadModel.RankingRow(
                id: id.uuidString,
                team: teamReference(id, in: state),
                rank: index + 1,
                record: record,
                isControlled: id == controlledID
            )
        }
        let bracket = state.competition.currentSchedule.games
            .filter { $0.tier == tier && $0.stage != .regularSeason }
            .sorted {
                if $0.week != $1.week { return $0.week < $1.week }
                return $0.id.uuidString < $1.id.uuidString
            }
            .compactMap { game -> CompetitionOverviewReadModel.BracketGame? in
                guard state.programmes[game.homeID] != nil || state.proTeams[game.homeID] != nil,
                      state.programmes[game.awayID] != nil || state.proTeams[game.awayID] != nil else {
                    return nil
                }
                return CompetitionOverviewReadModel.BracketGame(
                    id: game.id.uuidString,
                    stage: competitionStageLabel(game.stage),
                    home: teamReference(game.homeID, in: state),
                    away: teamReference(game.awayID, in: state),
                    score: game.result.map {
                        String($0.homeScore) + "–" + String($0.awayScore)
                    },
                    week: "Week " + String(game.week)
                )
            }
        return CompetitionOverviewReadModel(
            snapshotID: snapshotID("competition-overview-" + tier.rawValue,
                                    state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            seasonLabel: seasonLabel(state.calendar),
            tier: tier == .college ? "College" : "Professional",
            rankings: rankings,
            bracket: bracket
        )
    }

    static func standings(
        tier: Tier = .college,
        from state: GameState
    ) -> StandingsReadModel? {
        guard let standings = state.competition.standings[tier] else { return nil }
        let controlledID = state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
        let rows = standings.map { standing in
            StandingsReadModel.Row(
                id: standing.id.uuidString,
                team: teamReference(standing.id, in: state),
                wins: standing.wins,
                losses: standing.losses,
                ties: standing.ties,
                conferenceRecord: "\(standing.conferenceWins)-\(standing.conferenceLosses)"
                    + (standing.conferenceTies == 0 ? "" : "-\(standing.conferenceTies)"),
                pointsFor: standing.pointsFor,
                pointsAgainst: standing.pointsAgainst,
                isControlled: standing.id == controlledID
            )
        }
        return StandingsReadModel(
            snapshotID: snapshotID("standings-\(tier.rawValue)", state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            seasonLabel: seasonLabel(state.calendar),
            weekLabel: weekLabel(state.calendar),
            tier: tier == .college ? "College" : "Professional",
            rows: rows
        )
    }

    static func schedule(
        tier: Tier = .college,
        from state: GameState
    ) -> ScheduleReadModel? {
        let controlledID = state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
        let games = state.competition.currentSchedule.games
            .filter { $0.tier == tier }
            .map { game in
                ScheduleReadModel.GameRow(
                    id: game.id.uuidString,
                    week: "Week \(game.week)",
                    stage: competitionStageLabel(game.stage),
                    home: teamReference(game.homeID, in: state),
                    away: teamReference(game.awayID, in: state),
                    score: game.result.map { "\($0.homeScore)–\($0.awayScore)" },
                    isControlled: game.homeID == controlledID || game.awayID == controlledID
                )
            }
        return ScheduleReadModel(
            snapshotID: snapshotID("schedule-\(tier.rawValue)", state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            seasonLabel: seasonLabel(state.calendar),
            tier: tier == .college ? "College" : "Professional",
            games: games
        )
    }
}
