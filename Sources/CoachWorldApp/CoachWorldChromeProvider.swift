import Foundation
import FootballSimCore
import ProFootballCoachUI

/// The shared management chrome, built from the surface that already resolves programme identity.
///
/// Deliberately derived from `CoachingHQReadModel` rather than from `GameState` a second time.
/// The week hub already answers "who are we, what is our record, who is next", and resolving that
/// twice is how two headers end up disagreeing about the same save.
public extension CoachWorldReadModelProvider {
    static func chrome(
        for screen: CoachWorldScreenID,
        hub: CoachingHQReadModel,
        conference: String? = nil
    ) -> FloodlitChromeReadModel {
        FloodlitChromeReadModel(
            screen: screen,
            world: world(for: screen),
            club: hub.team,
            record: hub.recordLabel,
            ranking: hub.rankLabel,
            conference: conference,
            context: hub.opponent.map { "\(hub.week.currentDay) \u{00B7} \($0.name)" },
            contextOpponent: hub.opponent,
            rail: rail(current: screen),
            siblings: siblings(for: screen)
        )
    }

    /// `pitch | facility | film` — the one variable that changes per screen (`04` section 6.1c).
    ///
    /// Film is the surface where the light goes cold, so it is named explicitly rather than
    /// falling out of a family: the film room is the only place that treatment belongs.
    static func world(for screen: CoachWorldScreenID) -> FloodlitChromeReadModel.World {
        switch screen {
        case .opponentReportFilmRoom:
            return .film
        case .coachingHQ, .gamePlan, .practicePlan, .matchDay, .aftermath,
             .gameDetailBoxScore, .depthChart, .personnelPackages:
            return .pitch
        default:
            return .facility
        }
    }

    /// The seven kinds of thing a coaching week contains. Fixed, because the rail is a learned
    /// place — a rail whose entries move is a rail nobody learns.
    static func rail(current: CoachWorldScreenID) -> [FloodlitChromeReadModel.RailEntry] {
        let entries: [(CoachWorldScreenID, String, String)] = [
            (.coachingHQ, "calendar", "Week"),
            (.inbox, "tray.full", "Inbox"),
            (.roster, "person.2", "Squad"),
            (.gamePlan, "rectangle.3.group", "Plan"),
            (.opponentReportFilmRoom, "film", "Film"),
            (.teamHealth, "cross.case", "Health"),
            (.leagueMap, "map", "League"),
        ]
        return entries.map { entry in
            .init(
                screen: entry.0,
                symbol: entry.1,
                label: entry.2,
                intentID: .init(rawValue: "route|\(entry.0.rawValue)")
            )
        }
    }

    /// The current family's surfaces, off the registry rather than a second hand-written list, so
    /// a surface joins its family's navigation the day it is added.
    static func siblings(for screen: CoachWorldScreenID) -> [FloodlitChromeReadModel.Sibling] {
        screen.family.surfaces.map { sibling in
            .init(
                screen: sibling,
                title: sibling.canonicalName,
                intentID: .init(rawValue: "route|\(sibling.rawValue)")
            )
        }
    }

    /// The screen a chrome navigation intent names, or nil when it is not one.
    static func routedScreen(for intentID: CoachWorldIntentID) -> CoachWorldScreenID? {
        let parts = intentID.rawValue.split(separator: "|")
        guard parts.count == 2, parts[0] == "route", let raw = Int(parts[1]) else { return nil }
        return CoachWorldScreenID(rawValue: raw)
    }
}
