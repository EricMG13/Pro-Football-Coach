import Foundation
import FootballSimCore
import ProFootballCoachUI

/// Roster and Player Profile, built from the authoritative root.
///
/// The second half of G-01, and it was blocked until `02` §4.1a gave the world jersey numbers:
/// `RosterReadModel.PlayerRow.number` is a non-optional `Int`, and a number the engine did not hold
/// would have been a football fact invented in the read model.
///
/// The same rule as the Coaching HQ provider governs it — `04` §4.4, a surface without engine
/// backing ships without the claim — and the blanks here are different ones, each named beside the
/// field with the register item that fills it.
public extension CoachWorldReadModelProvider {
    static func roster(from state: GameState) -> RosterReadModel? {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let coach = state.staff[control.coachID] else { return nil }

        let players = programme.rosterIDs.compactMap { state.players[$0] }
        let numbers = JerseyNumbers.assign(players)
        let unsorted: [RosterReadModel.PlayerRow] = players.map { player in
            row(player, number: numbers[player.id] ?? 0, programme: programme, in: state)
        }
        let rows = unsorted.sorted { lhs, rhs in
            lhs.number == rhs.number ? lhs.stableID < rhs.stableID : lhs.number < rhs.number
        }
        let injuryCount = players.filter {
            state.people.playerLifecycle[$0.id]?.injury != nil
        }.count
        let person = CoachWorldPersonReference(
            stableID: coach.id.uuidString,
            name: coach.fullName,
            role: label(coach.role)
        )

        return RosterReadModel(
            snapshotID: snapshotID("roster", programme.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(programme.id, in: state),
            coach: person,
            seasonLabel: seasonLabel(state.calendar),
            weekLabel: weekLabel(state.calendar),
            recordLabel: recordLabel(programme.id, in: state),
            rankLabel: rankLabel(programme.id, in: state),
            rosterLimit: CollegeRules.rosterLimit,
            injuryCount: injuryCount,
            // The number of positions carrying fewer bodies than the rules call playable. It is a
            // fact the rules and the roster hold between them, not a recruiting opinion.
            openNeedCount: openNeedCount(players),
            players: rows
        )
    }

    static func playerProfile(_ playerID: UUID, in state: GameState) -> PlayerProfileReadModel? {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              programme.rosterIDs.contains(playerID),
              let player = state.players[playerID] else { return nil }
        let numbers = JerseyNumbers.assign(programme.rosterIDs.compactMap { state.players[$0] })
        return profile(player, number: numbers[playerID] ?? 0, programme: programme, in: state)
    }

    // MARK: - Rows and profiles

    private static func row(
        _ player: Player,
        number: Int,
        programme: Programme,
        in state: GameState
    ) -> RosterReadModel.PlayerRow {
        RosterReadModel.PlayerRow(
            stableID: player.id.uuidString,
            person: person(player),
            number: number,
            position: label(player.position),
            academicYear: academicYear(player),
            rosterRole: rosterRole(player, programme: programme, in: state),
            overall: player.overall.value,
            // Potential is the engine's hidden truth. Showing it raw on a roster row is a knowledge
            // boundary question (`02` §5 says the fog is the reader's business) and the profile's
            // confidence banding is where it belongs — but the column exists and the root holds the
            // number, so it reports rather than inventing a second scale.
            development: player.potential.value,
            schemeFit: schemeFit(player, scheme: programme.scheme),
            condition: condition(player, in: state),
            availability: availability(player, in: state),
            profile: profile(player, number: number, programme: programme, in: state)
        )
    }

    private static func profile(
        _ player: Player,
        number: Int,
        programme: Programme,
        in state: GameState
    ) -> PlayerProfileReadModel {
        PlayerProfileReadModel(
            stableID: player.id.uuidString,
            person: person(player),
            number: number,
            position: label(player.position),
            academicYear: academicYear(player),
            // The root records where a *prospect* came from, not where a rostered player grew up.
            // Until it does, the field says nothing rather than borrowing the programme's city.
            hometown: "",
            rosterRole: rosterRole(player, programme: programme, in: state),
            availability: availability(player, in: state),
            condition: condition(player, in: state),
            schemeFit: schemeFit(player, scheme: programme.scheme),
            // G-02: an engine-owned verdict in a named staff voice. There is no such thing yet, and
            // a summary sentence is exactly the invented judgement `04` §4.4 forbids.
            staffSummary: "",
            strengths: strengths(player),
            // G-03 would make this a recorded change rather than a standing property.
            concern: concern(player, in: state),
            attributeGroups: attributeGroups(player),
            // G-04: no per-player form series and no engine-owned player-game rating exist.
            recentForm: []
        )
    }

    // MARK: - Fields

    static func person(_ player: Player) -> CoachWorldPersonReference {
        CoachWorldPersonReference(
            stableID: "\(player.id.uuidString)-person",
            name: player.fullName,
            role: label(player.position)
        )
    }

    /// Every attribute this position is actually rated on, grouped by the unit the rules group them
    /// in. Confidence is "Known" because the coach's own players carry no fog — `02` §5 puts the
    /// uncertainty on prospects and opponents, not on the roster in the building.
    private static func attributeGroups(_ player: Player)
        -> [PlayerProfileReadModel.AttributeGroup] {
        let rated = player.position.ratedAttributes
        let physical: Set<Attribute> = [.speed, .strength, .agility, .durability]
        let mental: Set<Attribute> = [
            .decision, .poise, .motor, .awareness, .schemeFit, .temperament, .workEthic, .clutch,
        ]
        let groups: [(String, String, [Attribute])] = [
            ("physical", "Physical", rated.filter { physical.contains($0) }),
            ("mental", "Mental", rated.filter { mental.contains($0) }),
            ("technical", "Technical", rated.filter {
                !physical.contains($0) && !mental.contains($0)
            }),
        ]
        return groups.compactMap { key, title, attributes in
            guard !attributes.isEmpty else { return nil }
            return PlayerProfileReadModel.AttributeGroup(
                stableID: "\(player.id.uuidString)-\(key)",
                title: title,
                attributes: attributes.map { attribute in
                    PlayerProfileReadModel.Attribute(
                        stableID: "\(player.id.uuidString)-\(attribute.rawValue)",
                        label: attribute.label,
                        value: player.attributes[attribute].value,
                        confidence: "Known"
                    )
                }
            )
        }
    }

    /// The rated attributes standing clearly above this player's own overall. A comparison against
    /// the player's own mean, not a threshold someone chose.
    private static func strengths(_ player: Player) -> [String] {
        let overall = player.overall.value
        return player.position.ratedAttributes
            .filter { player.attributes[$0].value >= overall + strengthMargin }
            .sorted { player.attributes[$0].value > player.attributes[$1].value }
            .prefix(3)
            .map(\.label)
    }

    private static let strengthMargin = 8

    /// A fact about this player the root holds, or nothing. Injury first because it is the one a
    /// coach acts on this week; decline second because the rules define the threshold.
    private static func concern(_ player: Player, in state: GameState) -> String {
        if let injury = state.people.playerLifecycle[player.id]?.injury {
            return "\(label(injury.area)) injury, \(injury.weeksRemaining) week(s) remaining"
        }
        if player.isDeclining {
            return "Past the decline age for the position"
        }
        return ""
    }

    static func condition(_ player: Player, in state: GameState) -> Int {
        guard let lifecycle = state.people.playerLifecycle[player.id] else { return 100 }
        let range = PeopleRules.fatigueRange
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 100 }
        return 100 - (lifecycle.fatigue - range.lowerBound) * 100 / span
    }

    static func availability(_ player: Player, in state: GameState) -> String {
        guard let lifecycle = state.people.playerLifecycle[player.id] else { return "Available" }
        if let injury = lifecycle.injury {
            return "Out \(injury.weeksRemaining) week(s)"
        }
        return lifecycle.status == .active ? "Available" : "Unavailable"
    }

    /// Scholarship or walk-on, and whether a redshirt is planned. All three are recorded state; a
    /// depth-chart role is not, so this does not claim one.
    private static func rosterRole(
        _ player: Player,
        programme: Programme,
        in state: GameState
    ) -> String {
        var parts: [String] = []
        if let recruiting = state.college.programmes[programme.id] {
            parts.append(
                recruiting.scholarshipPlayerIDs.contains(player.id) ? "Scholarship" : "Walk-on"
            )
        }
        if state.college.redshirtPlans[player.id] != nil { parts.append("Redshirt planned") }
        return parts.joined(separator: " · ")
    }

    private static func academicYear(_ player: Player) -> String {
        guard let eligibility = player.eligibility else { return "" }
        switch eligibility.seasonsRemaining {
        case 4: return "FR"
        case 3: return "SO"
        case 2: return "JR"
        case 1: return "SR"
        default: return "GR"
        }
    }

    /// How much of what this position is rated on the scheme actually emphasises. A ratio the
    /// scheme and the position define between them, banded for reading.
    private static func schemeFit(_ player: Player, scheme: SchemeIdentity) -> String {
        let rated = player.position.ratedAttributes
        guard !rated.isEmpty else { return "" }
        let emphasised = scheme.emphasised(for: player.position)
        guard !emphasised.isEmpty else { return "Neutral" }
        let matched = rated.filter { emphasised.contains($0) }
        guard !matched.isEmpty else { return "Weak" }
        let mean = matched.reduce(0) { $0 + player.attributes[$1].value } / matched.count
        if mean >= player.overall.value + strengthMargin { return "Elite" }
        if mean >= player.overall.value { return "Strong" }
        return "Fair"
    }

    private static func openNeedCount(_ players: [Player]) -> Int {
        var counts: [Position: Int] = [:]
        for player in players { counts[player.position, default: 0] += 1 }
        return SharedRules.minimumPlayableRosterByPosition.filter { position, minimum in
            counts[position, default: 0] < minimum
        }.count
    }

    // MARK: - Wording

    static func label(_ position: Position) -> String {
        switch position {
        case .quarterback: return "QB"
        case .runningBack: return "RB"
        case .wideReceiver: return "WR"
        case .tightEnd: return "TE"
        case .leftTackle: return "LT"
        case .guardPosition: return "G"
        case .center: return "C"
        case .rightTackle: return "RT"
        case .edgeRusher: return "EDGE"
        case .defensiveTackle: return "DT"
        case .linebacker: return "LB"
        case .cornerback: return "CB"
        case .safety: return "S"
        case .kicker: return "K"
        case .punter: return "P"
        }
    }

    static func label(_ area: InjuryArea) -> String {
        area.rawValue.prefix(1).uppercased() + area.rawValue.dropFirst()
    }
}
