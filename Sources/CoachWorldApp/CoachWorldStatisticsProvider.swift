import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func statisticsLeaders(from state: GameState) -> StatisticsLeadersReadModel? {
        guard state.career.coachID != nil, controlledID(in: state) != nil else { return nil }
        var rows: [StatisticsLeadersReadModel.Row] = []
        let categories: [(String, (PlayerSeasonStatistics) -> Int)] = [
            ("Passing yards", { $0.passingYards }),
            ("Rushing yards", { $0.rushingYards }),
            ("Receiving yards", { $0.receivingYards }),
            ("Touchdowns", { $0.touchdowns })
        ]
        for (category, value) in categories {
            let leaders = state.competition.playerStatistics.values
                .filter { value($0) > 0 }
                .sorted { lhs, rhs in
                    value(lhs) == value(rhs)
                        ? lhs.playerID.uuidString < rhs.playerID.uuidString
                        : value(lhs) > value(rhs)
                }
                .prefix(8)
            for stat in leaders {
                guard let player = state.players[stat.playerID],
                      let teamID = organisation(for: player.id, in: state) else { continue }
                rows.append(StatisticsLeadersReadModel.Row(
                    id: category + "-" + player.id.uuidString,
                    category: category,
                    player: CoachWorldPersonReference(
                        stableID: player.id.uuidString, name: player.fullName, role: player.position.rawValue
                    ),
                    team: teamReference(teamID, in: state),
                    value: value(stat),
                    seasonLabel: seasonLabel(state.calendar)
                ))
            }
        }
        return StatisticsLeadersReadModel(
            snapshotID: snapshotID("statistics", state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            seasonLabel: seasonLabel(state.calendar),
            weekLabel: weekLabel(state.calendar),
            rows: rows
        )
    }

    static func awardsHonours(from state: GameState) -> AwardsHonoursReadModel? {
        guard state.career.coachID != nil else { return nil }
        let names = Dictionary(uniqueKeysWithValues: state.programmes.values.map { ($0.id, $0.name) })
            .merging(state.proTeams.values.map { ($0.id, $0.displayName) }, uniquingKeysWith: { first, _ in first })
            .merging(state.players.values.map { ($0.id, $0.fullName) }, uniquingKeysWith: { first, _ in first })
        let awards = state.competition.archives
            .sorted { $0.season > $1.season }
            .flatMap { archive in
                archive.awards.enumerated().map { index, award in
                    AwardsHonoursReadModel.Award(
                        id: "\(archive.season)-\(index)-\(award.winnerID.uuidString)",
                        title: award.kind.rawValue,
                        winner: names[award.winnerID] ?? "Unknown winner",
                        tier: award.tier.rawValue,
                        value: award.value,
                        seasonLabel: "Season \(archive.season + 1)"
                    )
                }
            }
        return AwardsHonoursReadModel(
            snapshotID: snapshotID("awards", state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            awards: awards
        )
    }

    private static func controlledID(in state: GameState) -> UUID? {
        state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID : nil)
    }

    private static func organisation(for playerID: UUID, in state: GameState) -> UUID? {
        if let programme = state.programmes.values.first(where: { $0.rosterIDs.contains(playerID) }) {
            return programme.id
        }
        return state.proTeams.values.first(where: { $0.rosterIDs.contains(playerID) })?.id
    }
}
