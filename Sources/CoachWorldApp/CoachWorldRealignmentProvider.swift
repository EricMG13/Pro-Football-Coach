import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func realignment(from state: GameState) -> RealignmentReadModel? {
        guard state.career.coachID != nil else { return nil }
        let events = state.history.recent + state.history.archive.flatMap(\.notableEvents)
        let payload = events.reversed().compactMap { event -> (DomainEvent, Int, ConferenceRealignmentReason, [ConferenceRealignmentSwap])? in
            guard case let .realignment(season, reason, swaps) = event.payload else { return nil }
            return (event, season, reason, swaps)
        }.first
        let mapped = payload.map { event, season, reason, swaps in
            RealignmentReadModel.Event(
                id: event.id.uuidString,
                seasonLabel: "Season \(season + 1)",
                reason: reason == .geographicFit ? "Geographic fit" : reason.rawValue,
                swaps: swaps.map { swap in
                    RealignmentReadModel.Swap(
                        id: swap.firstProgrammeID.uuidString + "-" + swap.secondProgrammeID.uuidString,
                        firstProgramme: state.programmes[swap.firstProgrammeID]?.name ?? "Unknown programme",
                        secondProgramme: state.programmes[swap.secondProgrammeID]?.name ?? "Unknown programme",
                        firstFrom: conferenceName(swap.firstFromConferenceID, in: state),
                        firstTo: conferenceName(swap.firstToConferenceID, in: state),
                        secondFrom: conferenceName(swap.secondFromConferenceID, in: state),
                        secondTo: conferenceName(swap.secondToConferenceID, in: state)
                    )
                }
            )
        }
        return RealignmentReadModel(
            snapshotID: snapshotID("realignment", state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            currentSeasonLabel: seasonLabel(state.calendar),
            event: mapped
        )
    }

    private static func conferenceName(_ id: UUID, in state: GameState) -> String {
        state.league.conferences.first(where: { $0.id == id })?.name ?? "Unknown conference"
    }
}
