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
        if let control = state.career.college,
           let programme = state.programmes[control.programmeID],
           let coach = state.staff[control.coachID] {
            let players = programme.rosterIDs.compactMap { state.players[$0] }
            return rosterModel(
                organisationID: programme.id,
                players: players,
                needPlayers: players,
                coach: coach,
                scheme: programme.scheme,
                rosterLimit: CollegeRules.rosterLimit,
                role: { rosterRole($0, programme: programme, in: state) },
                in: state
            )
        }
        guard let job = state.careerArc.currentJob,
              job.tier == .professional,
              let team = state.proTeams[job.organisationID],
              let coach = state.career.coachID.flatMap({ state.staff[$0] })
                  ?? team.staffIDs.compactMap({ state.staff[$0] }).first else { return nil }
        let rosterIDs = Array(Set(team.rosterIDs + team.practiceSquadIDs)).sorted {
            $0.uuidString < $1.uuidString
        }
        let players = rosterIDs.compactMap { state.players[$0] }
        let activePlayers = team.rosterIDs.compactMap { state.players[$0] }
        return rosterModel(
            organisationID: team.id,
            players: players,
            needPlayers: activePlayers,
            coach: coach,
            scheme: team.scheme,
            rosterLimit: ProRules.activeRosterLimit + ProRules.practiceSquadLimit,
            role: { player in
                team.rosterIDs.contains(player.id) ? "Active roster" : "Practice squad"
            },
            in: state
        )
    }

    private static func rosterModel(
        organisationID: UUID,
        players: [Player],
        needPlayers: [Player],
        coach: Staff,
        scheme: SchemeIdentity,
        rosterLimit: Int,
        role: (Player) -> String,
        in state: GameState
    ) -> RosterReadModel {

        let numbers = JerseyNumbers.assign(players)
        let unsorted: [RosterReadModel.PlayerRow] = players.map { player in
            row(
                player,
                number: numbers[player.id] ?? 0,
                organisationID: organisationID,
                scheme: scheme,
                rosterRole: role(player),
                in: state
            )
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
        let continueReason = state.pending.mandatoryDecisions.contains(where: {
            $0.programmeID == organisationID
        })
            ? "Complete the pending decision in Coaching HQ before advancing."
            : weeklyPreparationReason(for: organisationID, in: state)

        return RosterReadModel(
            snapshotID: snapshotID("roster", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(organisationID, in: state),
            coach: person,
            seasonLabel: seasonLabel(state.calendar),
            weekLabel: weekLabel(state.calendar),
            recordLabel: recordLabel(organisationID, in: state),
            rankLabel: rankLabel(organisationID, in: state),
            rosterLimit: rosterLimit,
            injuryCount: injuryCount,
            // The number of positions carrying fewer bodies than the rules call playable. It is a
            // fact the rules and the roster hold between them, not a recruiting opinion.
            openNeedCount: openNeedCount(needPlayers),
            players: rows,
            canContinue: continueReason == nil,
            continueReason: continueReason
        )
    }

    static func playerProfile(_ playerID: UUID, in state: GameState) -> PlayerProfileReadModel? {
        if let control = state.career.college,
           let programme = state.programmes[control.programmeID],
           programme.rosterIDs.contains(playerID),
           let player = state.players[playerID] {
            let numbers = JerseyNumbers.assign(programme.rosterIDs.compactMap { state.players[$0] })
            return profile(
                player,
                number: numbers[playerID] ?? 0,
                organisationID: programme.id,
                scheme: programme.scheme,
                rosterRole: rosterRole(player, programme: programme, in: state),
                in: state
            )
        }
        guard let job = state.careerArc.currentJob,
              job.tier == .professional,
              let team = state.proTeams[job.organisationID],
              team.rosterIDs.contains(playerID) || team.practiceSquadIDs.contains(playerID),
              let player = state.players[playerID] else { return nil }
        let rosterIDs = Array(Set(team.rosterIDs + team.practiceSquadIDs)).sorted {
            $0.uuidString < $1.uuidString
        }
        let numbers = JerseyNumbers.assign(rosterIDs.compactMap { state.players[$0] })
        return profile(
            player,
            number: numbers[playerID] ?? 0,
            organisationID: team.id,
            scheme: team.scheme,
            rosterRole: team.rosterIDs.contains(playerID) ? "Active roster" : "Practice squad",
            in: state
        )
    }

    // MARK: - Rows and profiles

    private static func row(
        _ player: Player,
        number: Int,
        organisationID: UUID,
        scheme: SchemeIdentity,
        rosterRole: String,
        in state: GameState
    ) -> RosterReadModel.PlayerRow {
        RosterReadModel.PlayerRow(
            stableID: player.id.uuidString,
            person: person(player),
            number: number,
            position: label(player.position),
            academicYear: academicYear(player),
            rosterRole: rosterRole,
            overall: player.overall.value,
            // Potential is hidden truth. Keep the legacy numeric slot neutral; the roster's DEV
            // column reads the retained, dated delta below and otherwise shows no evidence.
            development: 0,
            schemeFit: schemeFit(player, scheme: scheme),
            condition: condition(player, in: state),
            availability: availability(player, in: state),
            profile: profile(
                player,
                number: number,
                organisationID: organisationID,
                scheme: scheme,
                rosterRole: rosterRole,
                in: state
            ),
            developmentDelta: state.people.playerLifecycle[player.id]?.lastDevelopment?.appliedDelta
        )
    }

    private static func profile(
        _ player: Player,
        number: Int,
        organisationID: UUID,
        scheme: SchemeIdentity,
        rosterRole: String,
        in state: GameState
    ) -> PlayerProfileReadModel {
        PlayerProfileReadModel(
            stableID: player.id.uuidString,
            person: person(player),
            number: number,
            position: label(player.position),
            overall: player.overall.value,
            academicYear: academicYear(player),
            // The root records where a *prospect* came from, not where a rostered player grew up.
            // Until it does, the field says nothing rather than borrowing the programme's city.
            hometown: "",
            rosterRole: rosterRole,
            availability: availability(player, in: state),
            condition: condition(player, in: state),
            schemeFit: schemeFit(player, scheme: scheme),
            // G-02: an engine-owned verdict in a named staff voice. There is no such thing yet, and
            // a summary sentence is exactly the invented judgement `04` §4.4 forbids.
            staffSummary: "",
            strengths: strengths(player),
            concern: concern(player, in: state),
            attributeGroups: attributeGroups(player),
            recentForm: recentForm(player, programmeID: organisationID, in: state),
            developmentEvidence: developmentEvidence(player, in: state),
            historyEvidence: historyEvidence(player, programmeID: organisationID, in: state)
        )
    }

    private static func developmentEvidence(_ player: Player, in state: GameState) -> String {
        guard let lifecycle = state.people.playerLifecycle[player.id] else {
            return "No recorded development change in this snapshot."
        }
        if !lifecycle.recentChanges.isEmpty {
            let changes = lifecycle.recentChanges
                .map { change in
                    let sign = change.delta >= 0 ? "+" : ""
                    return "S\(change.occurredAt.season) W\(change.occurredAt.week) "
                        + "\(change.attribute.label) \(sign)\(change.delta) (\(change.cause.rawValue))"
                }
                .joined(separator: "; ")
            return changes
        }
        guard let summary = lifecycle.lastDevelopment else {
            return "No recorded development change in this snapshot."
        }
        let latest = summary.attributeChanges
            .map { change in
                let sign = change.delta >= 0 ? "+" : ""
                return "\(change.attribute.label) \(sign)\(change.delta)"
            }
            .joined(separator: ", ")
        let result = latest.isEmpty ? "No attribute change" : latest
        return "Season \(summary.occurredAt.season), week \(summary.occurredAt.week): \(result)."
    }

    private static func historyEvidence(
        _ player: Player,
        programmeID: UUID,
        in state: GameState
    ) -> String {
        let completedGames = state.competition.currentSchedule.games.filter { game in
            guard let result = game.result,
                  game.homeID == programmeID || game.awayID == programmeID else { return false }
            return result.homeParticipantIDs.contains(player.id)
                || result.awayParticipantIDs.contains(player.id)
        }.count
        guard completedGames > 0 else {
            return "No completed game history is retained in this season's schedule."
        }
        let formCount = recentForm(player, programmeID: programmeID, in: state).count
        return "\(completedGames) completed game(s) retained; \(formCount) recent form result(s) shown."
    }

    /// A bounded, position-aware rating derived only from completed box-score lines. A player with
    /// no completed appearance has a truthful empty state rather than a fabricated trend.
    private static func recentForm(
        _ player: Player,
        programmeID: UUID,
        in state: GameState
    ) -> [PlayerProfileReadModel.FormEntry] {
        let games = state.competition.currentSchedule.games
            .filter {
                $0.result != nil
                    && ($0.homeID == programmeID || $0.awayID == programmeID)
                    && ($0.result?.homeParticipantIDs.contains(player.id) == true
                        || $0.result?.awayParticipantIDs.contains(player.id) == true)
            }
            .sorted {
                if $0.season != $1.season { return $0.season > $1.season }
                if $0.week != $1.week { return $0.week > $1.week }
                return $0.id.uuidString > $1.id.uuidString
            }
            .prefix(5)
        return games.compactMap { game in
            guard let result = game.result else { return nil }
            guard let line = result.playerStatistics.first(where: { $0.playerID == player.id }) else {
                return nil
            }
            let rating = PlayerFormRating.rating(for: line, position: player.position)
            let opponentID = game.homeID == programmeID ? game.awayID : game.homeID
            return PlayerProfileReadModel.FormEntry(
                stableID: "\(player.id.uuidString)-\(game.id.uuidString)",
                opponent: teamReference(opponentID, in: state).abbreviation,
                rating: rating
            )
        }
    }

    // MARK: - Fields

    private static func person(_ player: Player) -> CoachWorldPersonReference {
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

    private static func condition(_ player: Player, in state: GameState) -> Int {
        guard let lifecycle = state.people.playerLifecycle[player.id] else { return 100 }
        let range = PeopleRules.fatigueRange
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 100 }
        return 100 - (lifecycle.fatigue - range.lowerBound) * 100 / span
    }

    private static func availability(_ player: Player, in state: GameState) -> String {
        guard let lifecycle = state.people.playerLifecycle[player.id] else { return "Available" }
        if let suspension = lifecycle.suspension {
            return "Suspended " + String(suspension.weeksRemaining) + " week(s)"
        }
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
