import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func staffRoom(from state: GameState) -> StaffRoomReadModel? {
        let organisationID = state.career.college?.programmeID ?? state.careerArc.currentJob?.organisationID
        guard let organisationID,
              let staffIDs = state.programmes[organisationID]?.staffIDs
                  ?? state.proTeams[organisationID]?.staffIDs,
              let coach = state.career.coachID.flatMap({ state.staff[$0] })
                  ?? staffIDs.compactMap({ state.staff[$0] }).first else {
            return nil
        }
        let rows = staffIDs
            .compactMap { state.staff[$0] }
            .sorted {
                $0.role.rawValue == $1.role.rawValue
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.role.rawValue < $1.role.rawValue
            }
            .map(StaffRoomReadModel.StaffRow.init)
        return StaffRoomReadModel(
            snapshotID: snapshotID("staff-room", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(organisationID, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(state.calendar),
            rows: rows
        )
    }
}
