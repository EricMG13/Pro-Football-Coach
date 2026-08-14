import Foundation

/// Somebody who moved in camp.
public struct CampMovement: Sendable, Equatable, Identifiable {
    public var id: UUID { playerID }
    public let playerID: UUID
    public let attribute: Attribute
    /// Signed, in rating points.
    public let delta: Int

    public init(playerID: UUID, attribute: Attribute, delta: Int) {
        self.playerID = playerID
        self.attribute = attribute
        self.delta = delta
    }
}

/// A job two players are close enough to be arguing over.
public struct CampBattle: Sendable, Equatable {
    public let position: Position
    public let leaderID: UUID
    public let challengerID: UUID
    /// How far apart they are now, in overall points.
    public let gap: Int
    /// Whether camp is what put the leader in front — true when reversing what camp did would put
    /// the challenger on top instead.
    public let decidedInCamp: Bool

    public init(
        position: Position,
        leaderID: UUID,
        challengerID: UUID,
        gap: Int,
        decidedInCamp: Bool
    ) {
        self.position = position
        self.leaderID = leaderID
        self.challengerID = challengerID
        self.gap = gap
        self.decidedInCamp = decidedInCamp
    }
}

/// What happened at camp, for one organisation.
public struct CampReport: Sendable, Equatable {
    public let organisationID: UUID
    public let heldAt: CalendarState
    public let risers: [CampMovement]
    public let fallers: [CampMovement]
    public let battles: [CampBattle]

    public init(
        organisationID: UUID,
        heldAt: CalendarState,
        risers: [CampMovement],
        fallers: [CampMovement],
        battles: [CampBattle]
    ) {
        self.organisationID = organisationID
        self.heldAt = heldAt
        self.risers = Array(risers.prefix(PeopleRules.maximumCampMovements))
        self.fallers = Array(fallers.prefix(PeopleRules.maximumCampMovements))
        self.battles = Array(battles.prefix(PeopleRules.maximumCampBattles))
    }

    public var isEmpty: Bool { risers.isEmpty && fallers.isEmpty && battles.isEmpty }
}

/// Preseason camp. `02` §5.3.
///
/// The register found no camp, no position battles and no exhibition anywhere: `02` §11.3.1's
/// calendar is twenty-one weeks and every one of them is a game week, so **the season simply
/// started**. Every comparable game opens with camp, and it is where a coach finds out which of
/// last season's problems fixed itself.
///
/// **Held at the boundary, not in a week of its own.** Adding a preseason week would move every
/// dated system in the game — schedules, contracts, eligibility, the portal windows, the pro market
/// phases — for a beat that does not need a week. So camp runs once as the season rolls over, on
/// whoever is on the roster at that moment. A player who signs later in the offseason misses it,
/// which is also what happens.
public enum PreseasonCampSystem {
    /// Holds camp. The transition is a development transition because camp *is* the development
    /// pass, asked a different question — see `DevelopmentSystem.camp`.
    public static func hold(
        after completed: CalendarState,
        in state: GameState
    ) -> DevelopmentTransition {
        DevelopmentSystem.camp(at: completed, in: state, tactical: state.tactical)
    }
}

/// What camp changed, read back off the record it wrote. `02` §5.3.
///
/// Derived, never stored, like every other read model here. The window is stated rather than
/// implied: a lifecycle record keeps only its *most recent* development summary, so this reports
/// camp until the season's first in-season checkpoint overwrites it. That is exactly the window in
/// which a coach reads a camp report, and pretending otherwise would mean persisting a second copy
/// of something the save already holds.
public enum PreseasonCamp {
    /// When the camp for the season a world is currently in was held, or nil for the first season,
    /// which nobody had a camp for because the world was generated into it.
    ///
    /// Callers should not have to know that "camp for season five" is stamped with the last week of
    /// season four; that is an artefact of holding camp at the boundary, and it belongs here rather
    /// than at every reader.
    public static func heldAt(forSeasonIn calendar: CalendarState) -> CalendarState? {
        guard calendar.season > 0 else { return nil }
        return CalendarState(season: calendar.season - 1, week: SharedRules.inSeasonWeeks)
    }

    /// This season's camp report for an organisation, or an empty one before the first camp.
    public static func report(for organisationID: UUID, in state: GameState) -> CampReport {
        guard let heldAt = heldAt(forSeasonIn: state.calendar) else {
            return CampReport(
                organisationID: organisationID,
                heldAt: state.calendar,
                risers: [],
                fallers: [],
                battles: []
            )
        }
        return report(for: organisationID, heldAt: heldAt, in: state)
    }

    public static func report(
        for organisationID: UUID,
        heldAt: CalendarState,
        in state: GameState
    ) -> CampReport {
        let rosterIDs = state.programmes[organisationID]?.rosterIDs
            ?? state.proTeams[organisationID]?.rosterIDs
            ?? []

        var risers: [CampMovement] = []
        var fallers: [CampMovement] = []
        for playerID in rosterIDs {
            for change in campChanges(playerID, heldAt: heldAt, in: state) {
                let movement = CampMovement(
                    playerID: playerID,
                    attribute: change.attribute,
                    delta: change.delta
                )
                if change.delta > 0 { risers.append(movement) } else if change.delta < 0 {
                    fallers.append(movement)
                }
            }
        }

        return CampReport(
            organisationID: organisationID,
            heldAt: heldAt,
            risers: risers.sorted(by: ordered),
            fallers: fallers.sorted(by: ordered),
            battles: battles(rosterIDs: rosterIDs, heldAt: heldAt, in: state)
        )
    }

    /// The close jobs, and who is on top of them.
    ///
    /// Availability is read the way the depth chart reads it, so a suspended or injured player is
    /// not described as having won anything (`02` §5.2).
    public static func battles(
        rosterIDs: [UUID],
        heldAt: CalendarState,
        in state: GameState
    ) -> [CampBattle] {
        var byPosition: [Position: [Player]] = [:]
        for playerID in rosterIDs {
            guard let player = state.players[playerID],
                  state.people.playerLifecycle[playerID]?.isAvailable == true else { continue }
            byPosition[player.position, default: []].append(player)
        }
        return byPosition.compactMap { position, players -> CampBattle? in
            let ranked = players.sorted {
                $0.overall.value == $1.overall.value
                    ? $0.id.uuidString < $1.id.uuidString
                    : $0.overall.value > $1.overall.value
            }
            guard ranked.count >= 2 else { return nil }
            let leader = ranked[0]
            let challenger = ranked[1]
            let gap = leader.overall.value - challenger.overall.value
            guard gap <= PeopleRules.campBattleRatingGap else { return nil }
            // Reversing camp tells you whether camp is the reason. Comparing the two *before*
            // figures rather than one of them is the point: a challenger who also improved has not
            // lost the job to camp, they have simply not caught up.
            let leaderBefore = preCampOverall(leader, heldAt: heldAt, in: state)
            let challengerBefore = preCampOverall(challenger, heldAt: heldAt, in: state)
            return CampBattle(
                position: position,
                leaderID: leader.id,
                challengerID: challenger.id,
                gap: gap,
                decidedInCamp: challengerBefore > leaderBefore
            )
        }
        .sorted {
            $0.gap == $1.gap
                ? $0.position.rawValue < $1.position.rawValue
                : $0.gap < $1.gap
        }
    }

    /// What this player's overall was before camp, reconstructed from what camp recorded.
    ///
    /// The summary is the receipt: it names the attribute and the signed delta, so the pre-camp
    /// figure is the current one with that delta taken back out. Nothing has to be stored twice.
    public static func preCampOverall(
        _ player: Player,
        heldAt: CalendarState,
        in state: GameState
    ) -> Int {
        let rated = player.position.ratedAttributes
        guard !rated.isEmpty else { return SharedRules.ratingRange.lowerBound }
        var total = rated.reduce(0) { $0 + player.attributes[$1].value }
        for change in campChanges(player.id, heldAt: heldAt, in: state) where rated.contains(change.attribute) {
            total -= change.delta
        }
        return total / rated.count
    }

    /// What camp recorded for this player, or nothing if the record is about some other week.
    static func campChanges(
        _ playerID: UUID,
        heldAt: CalendarState,
        in state: GameState
    ) -> [AttributeDevelopment] {
        guard let summary = state.people.playerLifecycle[playerID]?.lastDevelopment,
              summary.occurredAt == heldAt else { return [] }
        return summary.attributeChanges
    }

    /// Biggest move first, then by identity so a rebuild does not reshuffle.
    static func ordered(_ lhs: CampMovement, _ rhs: CampMovement) -> Bool {
        abs(lhs.delta) == abs(rhs.delta)
            ? lhs.playerID.uuidString < rhs.playerID.uuidString
            : abs(lhs.delta) > abs(rhs.delta)
    }
}
