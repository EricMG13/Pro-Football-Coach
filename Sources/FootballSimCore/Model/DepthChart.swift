import Foundation

/// The only personnel state a coach needs to persist: a bounded, calendar-scoped ordering change.
/// The base chart remains derived from the roster, so an injury or suspension cannot leave a stale
/// player in the lineup.
public struct DepthChartOverride: Codable, Sendable, Equatable {
    public static let maximumPlayers = 32

    private enum CodingKeys: String, CodingKey { case position, playerIDs }

    public let position: Position
    public let playerIDs: [UUID]

    public init(position: Position, playerIDs: [UUID]) {
        var seen: Set<UUID> = []
        precondition(playerIDs.count <= Self.maximumPlayers)
        precondition(playerIDs.allSatisfy { seen.insert($0).inserted })
        self.position = position
        self.playerIDs = playerIDs
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ids = try container.decode([UUID].self, forKey: .playerIDs)
        guard ids.count <= Self.maximumPlayers, Set(ids).count == ids.count else {
            throw DecodingError.dataCorruptedError(
                forKey: .playerIDs,
                in: container,
                debugDescription: "A depth override contains too many or duplicate players."
            )
        }
        self.init(
            position: try container.decode(Position.self, forKey: .position),
            playerIDs: ids
        )
    }
}

public struct PersonnelPlan: Codable, Sendable, Equatable {
    public static let maximumOverrides = Position.allCases.count

    private enum CodingKeys: String, CodingKey { case organisationID, calendar, overrides }

    public let organisationID: UUID
    public let calendar: CalendarState
    public let overrides: [DepthChartOverride]

    public init(
        organisationID: UUID,
        calendar: CalendarState,
        overrides: [DepthChartOverride]
    ) {
        let sorted = overrides.sorted { $0.position.rawValue < $1.position.rawValue }
        precondition(sorted.count <= Self.maximumOverrides)
        precondition(Set(sorted.map(\.position)).count == sorted.count)
        precondition(Set(sorted.flatMap(\.playerIDs)).count == sorted.flatMap(\.playerIDs).count)
        self.organisationID = organisationID
        self.calendar = calendar
        self.overrides = sorted
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let overrides = try container.decode([DepthChartOverride].self, forKey: .overrides)
        guard overrides.count <= Self.maximumOverrides,
              Set(overrides.map(\.position)).count == overrides.count,
              Set(overrides.flatMap(\.playerIDs)).count == overrides.flatMap(\.playerIDs).count else {
            throw DecodingError.dataCorruptedError(
                forKey: .overrides,
                in: container,
                debugDescription: "A personnel plan contains duplicate or excessive positions."
            )
        }
        self.init(
            organisationID: try container.decode(UUID.self, forKey: .organisationID),
            calendar: try container.decode(CalendarState.self, forKey: .calendar),
            overrides: overrides
        )
    }

    /// Applies only legal, available overrides and then appends the derived remainder. The same
    /// result can therefore feed abstract and detailed resolution without inventing a second chart.
    public func resolve(
        roster: [Player],
        unavailableIDs: Set<UUID> = []
    ) -> [Position: [UUID]] {
        let derived = DepthChart.derive(roster: roster, unavailableIDs: unavailableIDs)
        let byID = Dictionary(uniqueKeysWithValues: roster.map { ($0.id, $0) })
        var result = derived
        for override in overrides {
            let selected = override.playerIDs.filter { id in
                guard let player = byID[id] else { return false }
                return player.position == override.position && !unavailableIDs.contains(id)
            }
            var used = Set(selected)
            let remainder = (derived[override.position] ?? []).filter { used.insert($0).inserted }
            result[override.position] = selected + remainder
        }
        return result
    }
}

/// Who plays, and in what order. `02` §3.13.
///
/// FSC-008 records this as the missing piece behind tactical package and role eligibility, and it is
/// the reason two other things could not be true: the abstracted model rated a team by whole-unit
/// averages, so a starter and a fifth-stringer contributed equally to every result, and `02` §3.8's
/// `forcedOut` — an injury bad enough to end a player's game — had nothing to hand the snap to.
///
/// **Derived, not stored**, exactly as jersey numbers are (`02` §4.1a) and for the same reason:
/// order is a *team's* fact about players who change teams, availability changes weekly, and a
/// stored chart would have to be re-sorted after every injury, signing, transfer and cut, with any
/// path that forgot leaving an injured player starting. Derived, it is right by construction, and
/// the only thing worth persisting is what a coach *changes* — which is a later slice with a
/// surface to change it on.
public enum DepthChart {
    /// The chart for one roster: every position that has anybody, best available first.
    ///
    /// - Parameter unavailableIDs: players who cannot play — injured, suspended, redshirted, out for
    ///   this game. They are not dropped: they sit at the bottom in the same order, so a chart can
    ///   still show a coach who is missing and where they would have been.
    public static func derive(
        roster: [Player],
        unavailableIDs: Set<UUID> = []
    ) -> [Position: [UUID]] {
        var chart: [Position: [UUID]] = [:]
        for position in Position.allCases {
            let candidates = roster.filter { $0.position == position }
            guard !candidates.isEmpty else { continue }
            chart[position] = ordered(candidates, unavailableIDs: unavailableIDs).map(\.id)
        }
        return chart
    }

    /// The starter at a position, or nil when nobody on the roster plays it.
    public static func starter(
        at position: Position,
        roster: [Player],
        unavailableIDs: Set<UUID> = []
    ) -> UUID? {
        derive(roster: roster, unavailableIDs: unavailableIDs)[position]?.first
    }

    /// The eleven a side puts on the field for a snap, built from the chart.
    ///
    /// This is what a played match needs and what nothing has been able to produce: `SnapPersonnel`
    /// says in its own documentation that substitution happens above it and it takes who is out
    /// there, and until now nothing was above it.
    ///
    /// The template is `02` §11.2.1's, read as a *formation* rather than as a roster shape: one
    /// quarterback, one back, three receivers, a tight end and five linemen on offence; four down,
    /// three linebackers and four in the secondary on defence. A position with nobody available
    /// falls through to the next-best player in the same group, because eleven players is a rule of
    /// the sport and a roster hole is not a reason to line up with ten.
    public static func personnel(
        offense: [Player],
        defense: [Player],
        unavailableIDs: Set<UUID> = []
    ) -> SnapPersonnel {
        SnapPersonnel(
            offense: unit(from: offense, template: offensiveTemplate,
                          unavailableIDs: unavailableIDs),
            defense: unit(from: defense, template: defensiveTemplate,
                          unavailableIDs: unavailableIDs)
        )
    }

    /// Builds the same formation while preserving the coach's legal, calendar-scoped ordering
    /// overrides. The ordinary overload remains the derived fallback for AI and callers without a
    /// plan; this overload is the shared authority used by detailed and abstract controlled games.
    public static func personnel(
        roster: [Player],
        plan: PersonnelPlan?,
        unavailableIDs: Set<UUID> = []
    ) -> SnapPersonnel {
        guard let plan else {
            return personnel(offense: roster, defense: roster, unavailableIDs: unavailableIDs)
        }
        let chart = plan.resolve(roster: roster, unavailableIDs: unavailableIDs)
        let byID = Dictionary(uniqueKeysWithValues: roster.map { ($0.id, $0) })

        func lineup(_ template: [Position]) -> [Player] {
            var used: Set<UUID> = []
            var result: [Player] = []
            for position in template {
                let samePosition = (chart[position] ?? []).compactMap { byID[$0] }
                let sameGroup = Position.allCases
                    .flatMap { chart[$0] ?? [] }
                    .compactMap { byID[$0] }
                    .filter { $0.position.group == position.group }
                let fallback = ordered(
                    roster.filter { $0.position.group == position.group },
                    unavailableIDs: unavailableIDs
                )
                let candidate = (samePosition + sameGroup + fallback + ordered(
                    roster,
                    unavailableIDs: unavailableIDs
                )).first {
                    !used.contains($0.id) && !unavailableIDs.contains($0.id)
                }
                if let candidate {
                    used.insert(candidate.id)
                    result.append(candidate)
                }
            }
            return result
        }

        return SnapPersonnel(
            offense: lineup(offensiveTemplate),
            defense: lineup(defensiveTemplate)
        )
    }

    /// The offensive formation, plus the reserve back used by the resolver and two specialists
    /// because a drive can end in a kick.
    public static let offensiveTemplate: [Position] = [
        .quarterback, .runningBack, .runningBack,
        .wideReceiver, .wideReceiver, .wideReceiver, .tightEnd,
        .leftTackle, .guardPosition, .guardPosition, .center, .rightTackle, .kicker, .punter,
    ]

    public static let defensiveTemplate: [Position] = [
        .edgeRusher, .edgeRusher, .defensiveTackle, .defensiveTackle,
        .linebacker, .linebacker, .linebacker,
        .cornerback, .cornerback, .safety, .safety,
    ]

    // MARK: - Ordering

    /// Available first, then by rating, then by identifier.
    ///
    /// The identifier tiebreak is not decoration: two players of equal rating must produce the same
    /// order on every run and in every process, and array order does not (`SnapPersonnel.ranked`
    /// makes the same argument for the same reason).
    static func ordered(_ players: [Player], unavailableIDs: Set<UUID>) -> [Player] {
        players.sorted { lhs, rhs in
            let lhsOut = unavailableIDs.contains(lhs.id)
            let rhsOut = unavailableIDs.contains(rhs.id)
            if lhsOut != rhsOut { return !lhsOut }
            if lhs.overall != rhs.overall { return lhs.overall > rhs.overall }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    /// Fills a formation from a squad, falling back within the position group and then to the best
    /// available body.
    private static func unit(
        from squad: [Player],
        template: [Position],
        unavailableIDs: Set<UUID>
    ) -> [Player] {
        let byPosition = Dictionary(grouping: squad, by: \.position)
            .mapValues { ordered($0, unavailableIDs: unavailableIDs) }
        var used: Set<UUID> = []
        var lineup: [Player] = []

        for position in template {
            if let pick = (byPosition[position] ?? []).first(where: {
                !used.contains($0.id) && !unavailableIDs.contains($0.id)
            }) {
                used.insert(pick.id)
                lineup.append(pick)
                continue
            }
            // Nobody left at the position: the next-best body in the same group, then the next-best
            // body at all. Eleven players is a rule of the sport; a roster hole is not a reason to
            // line up with ten, and the resolver would silently produce a different game if it were.
            let group = position.group
            let fallback = ordered(squad.filter { $0.position.group == group },
                                   unavailableIDs: unavailableIDs)
                .first { !used.contains($0.id) && !unavailableIDs.contains($0.id) }
                ?? ordered(squad, unavailableIDs: unavailableIDs)
                    .first { !used.contains($0.id) && !unavailableIDs.contains($0.id) }
            guard let fallback else { continue }
            used.insert(fallback.id)
            lineup.append(fallback)
        }
        return lineup
    }
}
