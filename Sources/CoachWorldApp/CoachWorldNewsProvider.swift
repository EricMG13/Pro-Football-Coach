import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func news(from state: GameState) -> NewsReadModel? {
        guard state.career.coachID != nil else { return nil }
        let feed = NewsFeedReadModel.build(from: state)
        return NewsReadModel(
            snapshotID: "news-\(state.league.id.uuidString)-\(state.calendar.season)-\(state.calendar.week)",
            provenance: .simulationSnapshot,
            world: worldReference(state),
            weekLabel: "Season \(state.calendar.season) · Week \(state.calendar.week)",
            items: feed.items.map {
                NewsReadModel.Item(
                    stableID: $0.eventID.uuidString,
                    occurred: "Season \($0.occurredAt.season) · Week \($0.occurredAt.week)",
                    headline: $0.headline,
                    weight: $0.weight
                )
            }
        )
    }
}
