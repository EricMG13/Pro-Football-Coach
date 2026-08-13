import Foundation

public enum DisciplineError: Error, Sendable, Equatable {
    case missingPlayer
    case notOnRoster
    case alreadySuspended
    case invalidLength(weeks: Int)
    /// The player exists and is on the roster, but the suspension did not take — a career that has
    /// already ended is the reachable case. Thrown rather than returned quietly, because the
    /// alternative is announcing a suspension nobody is serving.
    case notSuspendable
}

/// Something a coach has to answer this week. `02` §5.2.
///
/// Derived, never stored, for the reason the inbox is: it is a fact about the week rather than a
/// second record to keep in step with the roster, and it costs nothing in save size — which FSC-003
/// makes a live concern. What *is* stored is the consequence, because time being served has to
/// outlive the week the incident happened in.
public struct DisciplineIncident: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let playerID: UUID
    public let organisationID: UUID
    public let kind: DisciplineIncidentKind
    public let occurredAt: CalendarState

    public init(
        id: UUID,
        playerID: UUID,
        organisationID: UUID,
        kind: DisciplineIncidentKind,
        occurredAt: CalendarState
    ) {
        self.id = id
        self.playerID = playerID
        self.organisationID = organisationID
        self.kind = kind
        self.occurredAt = occurredAt
    }

    /// What the coach is advised to do. Advice, because the decision is theirs.
    public var recommendedWeeks: Int {
        PeopleRules.recommendedSuspensionWeeks[kind] ?? 0
    }
}

/// What the coach does about it.
///
/// **Two responses, not three.** A warning is missing on purpose: to mean anything it would have to
/// be remembered — a second warning is worse than a first — and that is persisted state for a
/// system whose whole design is that the incident is derived and only the consequence is stored.
/// A button that recorded nothing and changed nothing would be the decoration D6 clause 4 forbids.
public enum DisciplineResponse: Sendable, Equatable {
    /// Handle it internally. Nothing changes, and that is a real answer: most of these are handled
    /// internally, and a coach who suspends for everything has a locker room that hates them.
    case handleInternally
    case suspend(weeks: Int)
}

public struct DisciplineTransition: Sendable, Equatable {
    public let state: GameState
    public let eventPayloads: [DomainEventPayload]

    public init(state: GameState, eventPayloads: [DomainEventPayload]) {
        self.state = state
        self.eventPayloads = eventPayloads
    }
}

/// Discipline. `02` §2.1 beat 5, `02` §5.2.
///
/// `02` §2.1 lists discipline among the weekly roster actions and `02` §11.3.3 names Discipline as
/// the authoritative system for the `volatile` trait. **Neither existed.** There was no incident, no
/// suspension, no discipline state and nothing that read `volatile` off the field, so the beat the
/// week is built around was a heading with nothing under it and the trait's named consumer was a
/// promise.
public enum DisciplineSystem {
    /// This week's incidents at one organisation, worst first.
    ///
    /// Deterministic and stateless: the draw comes from the world seed, the week and the player, so
    /// the same save shows the same file every time it is opened and a rebuild does not shuffle it.
    /// Bounded by the roster it reads.
    public static func incidents(
        at organisationID: UUID,
        in state: GameState
    ) -> [DisciplineIncident] {
        let rosterIDs = state.programmes[organisationID]?.rosterIDs
            ?? state.proTeams[organisationID]?.rosterIDs
            ?? []
        return rosterIDs.compactMap { playerID -> DisciplineIncident? in
            guard let player = state.players[playerID] else { return nil }
            // Someone already serving is not in the file again this week. Piling a second
            // suspension onto a player who is already out is not discipline, it is bookkeeping.
            guard state.people.playerLifecycle[playerID]?.suspension == nil else { return nil }

            var rng = SeededRandom(seed: SeededRandom.derive(
                from: SeededRandom.derive(from: state.league.seed, scope: .personnel,
                                          identifier: playerID),
                scope: .personnel,
                ordinal: state.calendar.season * 100 + state.calendar.week
            ))
            // The draw is taken before the probability is known, so the stream does not depend on
            // morale — the same property every other draw in this engine holds, and the reason a
            // readout that changes a player's mood cannot change what happens to them.
            let roll = rng.double01()
            let kindIndex = rng.int(in: 0...(DisciplineIncidentKind.allCases.count - 1))

            var probability = PeopleRules.baseIncidentProbability
            if player.has(.volatile) { probability += PeopleRules.volatileIncidentProbability }
            if PlayerMorale.reading(for: playerID, in: state).isUnhappy {
                probability += PeopleRules.unhappyIncidentProbability
            }
            guard roll < probability else { return nil }

            return DisciplineIncident(
                id: derivedID(seed: state.league.seed, calendar: state.calendar, playerID: playerID),
                playerID: playerID,
                organisationID: organisationID,
                kind: DisciplineIncidentKind.allCases[kindIndex],
                occurredAt: state.calendar
            )
        }
        .sorted {
            $0.recommendedWeeks == $1.recommendedWeeks
                ? $0.playerID.uuidString < $1.playerID.uuidString
                : $0.recommendedWeeks > $1.recommendedWeeks
        }
    }

    /// Applies the coach's answer.
    ///
    /// A suspension makes `isAvailable` false, which is the whole integration: every depth chart,
    /// personnel package and match already reads that flag for injuries, so a suspended player
    /// stops playing without one of them being taught what a suspension is.
    public static func respond(
        to incident: DisciplineIncident,
        with response: DisciplineResponse,
        in state: GameState
    ) throws -> DisciplineTransition {
        guard state.players[incident.playerID] != nil else { throw DisciplineError.missingPlayer }
        let roster = state.programmes[incident.organisationID]?.rosterIDs
            ?? state.proTeams[incident.organisationID]?.rosterIDs
            ?? []
        guard roster.contains(incident.playerID) else { throw DisciplineError.notOnRoster }

        guard case let .suspend(weeks) = response else {
            return DisciplineTransition(state: state, eventPayloads: [])
        }
        guard (1...PeopleRules.maximumSuspensionWeeks).contains(weeks) else {
            throw DisciplineError.invalidLength(weeks: weeks)
        }
        guard let lifecycle = state.people.playerLifecycle[incident.playerID] else {
            throw DisciplineError.missingPlayer
        }
        guard lifecycle.suspension == nil else { throw DisciplineError.alreadySuspended }

        var next = state
        next.people.updatePlayerLifecycle(incident.playerID) { record in
            record.suspend(PlayerSuspension(
                reason: incident.kind,
                occurredAt: state.calendar,
                originalWeeks: weeks,
                weeksRemaining: weeks
            ))
        }
        // The mutation is checked rather than assumed. `updatePlayerLifecycle` reports a miss with a
        // Bool and `suspend` refuses a career that has already ended, so a transaction that trusted
        // either would emit the event for a suspension nobody is serving.
        guard next.people.playerLifecycle[incident.playerID]?.suspension != nil else {
            throw DisciplineError.notSuspendable
        }
        return DisciplineTransition(
            state: next,
            eventPayloads: [.playerSuspended(
                playerID: incident.playerID,
                organisationID: incident.organisationID,
                reason: incident.kind,
                weeks: weeks
            )]
        )
    }

    /// A stable identifier for something nothing persists — from the seed, the week and the player,
    /// never `UUID()`, which the engine's ambient-identity scan forbids and which would give the
    /// same incident a new identity every time a screen was rebuilt.
    static func derivedID(seed: UInt64, calendar: CalendarState, playerID: UUID) -> UUID {
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.derive(from: seed, scope: .personnel, identifier: playerID),
            scope: .personnel,
            ordinal: -(calendar.season * 100 + calendar.week) - 1
        ))
        return rng.uuid()
    }
}
