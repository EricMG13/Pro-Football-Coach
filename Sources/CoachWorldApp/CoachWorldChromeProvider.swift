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
        conference: String? = nil,
        /// Surface context for the header's right-hand chip. The reference varies this per screen
        /// — scholarships on personnel, the class on recruiting, conference position on league —
        /// so a caller that holds a surface's own figures passes them. Nil falls back to the next
        /// fixture, which is what the week hub itself shows.
        context surfaceContext: String? = nil,
        availableScreens: [CoachWorldScreenID] = CoachWorldScreenID.allCases
    ) -> FloodlitChromeReadModel {
        let canonicalScreen = screen.canonicalDestination
        let context = surfaceContext
            ?? hub.opponent.map { "\(hub.week.currentDay) \u{00B7} \($0.name)" }
        return FloodlitChromeReadModel(
            screen: canonicalScreen,
            world: world(for: canonicalScreen),
            club: hub.team,
            record: hub.recordLabel,
            ranking: hub.rankLabel,
            conference: conference,
            context: context,
            // The opponent pennant belongs to the chip only when the chip is about the fixture.
            contextOpponent: context == nil || !isFixtureContext(for: canonicalScreen)
                ? nil
                : hub.opponent,
            rail: rail(current: canonicalScreen),
            siblings: siblings(for: canonicalScreen, availableScreens: availableScreens),
            availableScreens: availableScreens
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
            // The reference's seventh entry opens the registry overlay, not the league.
            (.worldSearch, "square.grid.3x3", "All tasks"),
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
    static func siblings(
        for screen: CoachWorldScreenID,
        availableScreens: [CoachWorldScreenID] = CoachWorldScreenID.allCases
    ) -> [FloodlitChromeReadModel.Sibling] {
        screen.family.surfaces.filter { availableScreens.contains($0) }.map { sibling in
            .init(
                screen: sibling,
                // Short form for the row; `canonicalName` stays the migration/accessibility name.
                title: sibling.taskName,
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

private extension CoachWorldReadModelProvider {
    /// Whether the header chip is about the coming fixture, and so earns the opponent pennant.
    static func isFixtureContext(for screen: CoachWorldScreenID) -> Bool {
        screen.family == .weeklyCommand
    }
}

extension CareerStakeholder {
    /// Sentence case in source; the panel's rows print it as written.
    var displayName: String {
        switch self {
        case .administration: "Athletic dir."
        case .boosters: "Boosters"
        case .fanbase: "Fanbase"
        case .lockerRoom: "Locker room"
        }
    }
}
