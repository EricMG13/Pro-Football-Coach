import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func legacyHistory(from state: GameState) -> LegacyHistoryReadModel? {
        guard let coachID = state.career.coachID,
              let organisationID = state.career.college?.programmeID
                  ?? (state.careerArc.currentJob?.tier == .professional
                      ? state.careerArc.currentJob?.organisationID : nil),
              let team = state.programmes[organisationID].map({ teamReference($0.id, in: state) })
                  ?? state.proTeams[organisationID].map({ teamReference($0.id, in: state) }) else {
            return nil
        }
        let history = WorldHistoryReadModel.build(from: state)
        let records = [
            history.recordBook.highestTeamScore.map {
                historyRecord($0, title: "Highest team score", in: state)
            },
            history.recordBook.mostTeamYards.map {
                historyRecord($0, title: "Most team yards", in: state)
            }
        ].compactMap { $0 }
        let rivalries = RivalrySeeder.strongest(for: organisationID, among: state.rivalries.values)
            .compactMap { rivalID -> LegacyHistoryReadModel.Rivalry? in
                guard let rivalry = state.rivalries.values.first(where: {
                    $0.involves(organisationID) && $0.involves(rivalID)
                }) else { return nil }
                return LegacyHistoryReadModel.Rivalry(
                    id: rivalry.id.uuidString,
                    opponent: teamReference(rivalID, in: state),
                    origin: rivalry.origin.rawValue,
                    intensity: rivalry.intensity.value,
                    meetings: Array(rivalry.notableMeetings.prefix(8))
                )
            }
        let careerLine = state.people.staffCareers[coachID]?.assignments.map { assignment in
            LegacyHistoryReadModel.CareerEntry(
                id: "(coachID.uuidString)-(assignment.season)-(assignment.organisationID.uuidString)-(assignment.role.rawValue)",
                season: assignment.season,
                organisation: teamReference(assignment.organisationID, in: state),
                role: assignment.role.rawValue
            )
        } ?? []
        let tree = CoachingTreeReadModel.build(from: state).branches.map { branch in
            LegacyHistoryReadModel.TreeBranch(
                id: branch.id.uuidString,
                mentorName: branch.mentorName,
                disciples: branch.disciples.map { "\($0.name) · Season \($0.firstHeadCoachSeason)" }
            )
        }
        return LegacyHistoryReadModel(
            snapshotID: snapshotID("legacy-history", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            team: team,
            seasonLabel: seasonLabel(state.calendar),
            records: records,
            rivalries: rivalries,
            careerLine: careerLine,
            coachingTree: tree
        )
    }

    private static func historyRecord(
        _ entry: TeamGameRecordEntry,
        title: String,
        in state: GameState
    ) -> LegacyHistoryReadModel.Record {
        LegacyHistoryReadModel.Record(
            id: "(title)-(entry.gameID.uuidString)",
            title: title,
            value: entry.value,
            team: teamReference(entry.teamID, in: state),
            opponent: teamReference(entry.opponentID, in: state),
            gameLabel: "Season (entry.season + 1) · Week (entry.week) · (entry.stage.rawValue)"
        )
    }
}
