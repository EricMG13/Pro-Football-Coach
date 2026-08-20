import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func opponentFilm(from state: GameState) -> OpponentFilmReadModel? {
        guard let hq = coachingHQ(from: state),
              let observerID = UUID(uuidString: hq.team.stableID) else { return nil }
        let observation: OpponentObservation?
        let opponent: CoachWorldTeamReference?
        if let nextGame = scheduledGame(for: observerID, in: state) {
            let opponentID = nextGame.homeID == observerID ? nextGame.awayID : nextGame.homeID
            opponent = teamReference(opponentID, in: state)
            observation = state.tactical.observation(
                for: observerID,
                opponentID: opponentID,
                at: state.calendar
            )
        } else {
            opponent = nil
            observation = nil
        }
        return OpponentFilmReadModel(
            snapshotID: "film-" + observerID.uuidString + "-"
                + String(state.calendar.season) + "-" + String(state.calendar.week),
            provenance: .simulationSnapshot,
            team: hq.team,
            opponent: opponent,
            weekLabel: hq.week.weekLabel,
            sourceGameCount: observation?.sampleSize ?? 0,
            confidence: observation?.confidence ?? 0,
            passRate: observation?.passRate ?? 0,
            turnoverRate: observation?.turnoverRate ?? 0,
            sourceFixtureCount: observation?.sourceGameIDs.count ?? 0,
            isCurrent: observation != nil,
            unavailableReason: observation == nil
                ? (opponent == nil
                    ? "No scheduled opponent is available for this week."
                    : "No current observer-scoped film has been retained for this opponent.")
                : nil
        )
    }
}
