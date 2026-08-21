import Foundation

public struct DisciplineAITransition: Sendable, Equatable {
    public let state: GameState
    public let eventPayloads: [DomainEventPayload]

    public init(state: GameState, eventPayloads: [DomainEventPayload]) {
        self.state = state
        self.eventPayloads = eventPayloads
    }
}

/// The headless discipline policy: what every organisation the player is not coaching does with its
/// own file each week.
///
/// Separate from `DisciplineSystem` for the reason `ProRosterAISystem` is separate from
/// `ProMarketSystem`. `DisciplineSystem` is the mechanism — it draws the incident and it applies a
/// response — and `02` §5.2 is explicit that choosing the response is the coach's, so a mechanism
/// that also decided would be "a game that administered its own discipline". This is the decision,
/// for the clubs no human is making it at.
///
/// **The controlled organisation is skipped on purpose.** Its incidents stay unanswered in the
/// weekly file, which is what makes the response a decision the player takes rather than one taken
/// for them. `DisciplineSystem.incidents` is stateless and derives from the world seed, the week and
/// the player, so the file the player opens is the same file this step read and skipped.
public enum DisciplineAISystem {
    public static func process(
        at calendar: CalendarState,
        in state: GameState
    ) throws -> DisciplineAITransition {
        guard calendar == state.calendar else {
            return DisciplineAITransition(state: state, eventPayloads: [])
        }
        let controlledID = state.careerArc.currentJob?.organisationID
        // Sorted so the order two organisations are processed in cannot depend on dictionary
        // iteration, which is the determinism rule every other weekly step follows.
        let organisationIDs = (state.programmes.ids + state.proTeams.ids)
            .sorted { $0.uuidString < $1.uuidString }

        var next = state
        var payloads: [DomainEventPayload] = []
        for organisationID in organisationIDs where organisationID != controlledID {
            for incident in DisciplineSystem.incidents(at: organisationID, in: next) {
                // The advice in the rules module is what an AI coach takes. `02` §5.2 makes it
                // advice rather than enforcement, and this is the caller that chooses to follow it.
                let weeks = PeopleRules.recommendedSuspensionWeeks[incident.kind] ?? 0
                let response: DisciplineResponse = weeks > 0 ? .suspend(weeks: weeks) : .handleInternally
                let transition = try DisciplineSystem.respond(
                    to: incident,
                    with: response,
                    in: next
                )
                next = transition.state
                payloads.append(contentsOf: transition.eventPayloads)
            }
        }
        return DisciplineAITransition(state: next, eventPayloads: payloads)
    }
}
