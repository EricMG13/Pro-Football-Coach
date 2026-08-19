import Foundation
import FootballSimCore
import ProFootballCoachUI

/// `GameState` to `LeagueMapReadModel`, per `04` section 8 family 41.
///
/// **The join throughout is `TeamIdentity.homeCityID`, never `Programme.cityName`.** A name join
/// would in fact be sound today — the generator draws city names without replacement from 570
/// distinct combinations against the 166 cities a world needs — but `GameMap.generate` keeps a
/// with-replacement fallback for a smaller name pool, and if that ever fired a name join would
/// silently collapse two cities into one and place a programme somewhere it does not play. The
/// engine joins by identifier for the same reason; the recruiting fit cache is the precedent.
public extension CoachWorldReadModelProvider {
    /// Nil when no career is under control, which is the only state this cannot describe.
    ///
    /// Resolves the controlled organisation by tier rather than assuming college, the same
    /// `controlledID` idiom `CoachWorldCompetitionProvider.standings`/`schedule` already use — a
    /// coach promoted to professional keeps this screen instead of losing it the moment
    /// `state.career.college` clears (it previously nil-guarded on college control alone).
    static func leagueMap(from state: GameState) -> LeagueMapReadModel? {
        guard let coachID = state.career.coachID,
              let coach = state.staff[coachID] else { return nil }
        let controlledTier = controlledCompetitionTier(from: state)
        guard let controlledID = state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
        else { return nil }

        let calendar = state.calendar
        // Built once and read 166 times. `GameMap.city(_:)` is a linear scan over every city, so
        // resolving each member through it would be quadratic in a world that is rebuilt after
        // every intent.
        let citiesByID = Dictionary(uniqueKeysWithValues: state.map.cities.map { ($0.id, $0) })
        let regionsByID = Dictionary(uniqueKeysWithValues: state.map.regions.map { ($0.id, $0) })
        let conferencesByID = Dictionary(
            uniqueKeysWithValues: state.league.conferences.map { ($0.id, $0) }
        )
        // `EntityStore.values` is sorted by uuidString, so this array — and therefore every rival
        // list derived from it — is in a deterministic order rather than a hash order.
        let rivalries = state.rivalries.values

        var places: [LeagueMapReadModel.Place] = []
        places.reserveCapacity(state.programmes.count + state.proTeams.count)

        for member in state.programmes.values {
            if let made = place(
                id: member.id,
                tierLabel: LeagueMapReadModel.Tier.college,
                conferenceID: member.conferenceID,
                prestige: member.prestige.value,
                isControlled: member.id == controlledID,
                in: state,
                citiesByID: citiesByID,
                regionsByID: regionsByID,
                conferencesByID: conferencesByID,
                rivalries: rivalries
            ) {
                places.append(made)
            }
        }
        for member in state.proTeams.values {
            if let made = place(
                id: member.id,
                tierLabel: LeagueMapReadModel.Tier.professional,
                conferenceID: member.conferenceID,
                prestige: member.prestige.value,
                isControlled: member.id == controlledID,
                in: state,
                citiesByID: citiesByID,
                regionsByID: regionsByID,
                conferencesByID: conferencesByID,
                rivalries: rivalries
            ) {
                places.append(made)
            }
        }

        let controlledConferenceID = controlledTier == .college
            ? state.programmes[controlledID]?.conferenceID
            : state.proTeams[controlledID]?.conferenceID

        return LeagueMapReadModel(
            snapshotID: snapshotID("map", controlledID, calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(controlledID, in: state),
            coach: CoachWorldPersonReference(
                stableID: coach.id.uuidString,
                name: coach.fullName,
                role: label(coach.role)
            ),
            seasonLabel: seasonLabel(calendar),
            weekLabel: weekLabel(calendar),
            recordLabel: recordLabel(controlledID, in: state),
            rankLabel: rankLabel(controlledID, in: state),
            gridWidth: GameMap.width,
            gridHeight: GameMap.height,
            regions: state.map.regions.map {
                LeagueMapReadModel.Region(
                    stableID: $0.id.uuidString,
                    name: $0.name,
                    talentDensity: $0.talentDensity.value
                )
            },
            places: places,
            conferenceStandings: conferenceStandings(for: controlledID, tier: controlledTier, in: state),
            conferenceName: controlledConferenceID.flatMap { conferencesByID[$0]?.name }
        )
    }

    /// The coach's own conference, ordered as the standings hold it.
    ///
    /// Derived from the same `state.competition.standings` the Standings surface reads, so the map
    /// and that surface cannot disagree about the table. Filtered to the coach's conference — the
    /// map's table is about the neighbours you play, not the whole tier. Tier-parameterized the
    /// same way `CoachWorldCompetitionProvider.standings`/`schedule` are, so a promoted coach's own
    /// conference reads from the professional table, not a college one they no longer belong to.
    static func conferenceStandings(
        for organisationID: UUID,
        tier: Tier,
        in state: GameState
    ) -> [LeagueMapReadModel.ConferenceStanding] {
        guard let standings = state.competition.standings[tier] else { return [] }
        let ownConferenceID: UUID?
        switch tier {
        case .college:
            guard let own = state.programmes[organisationID] else { return [] }
            ownConferenceID = own.conferenceID
        case .pro:
            guard let own = state.proTeams[organisationID] else { return [] }
            ownConferenceID = own.conferenceID
        }
        return standings
            .filter { member in
                let memberConferenceID = tier == .college
                    ? state.programmes[member.id]?.conferenceID
                    : state.proTeams[member.id]?.conferenceID
                return memberConferenceID == ownConferenceID
            }
            .map { standing in
                LeagueMapReadModel.ConferenceStanding(
                    stableID: standing.id.uuidString,
                    team: teamReference(standing.id, in: state),
                    conferenceRecord: "\(standing.conferenceWins)\u{2013}\(standing.conferenceLosses)",
                    overallRecord: "\(standing.wins)\u{2013}\(standing.losses)",
                    pointDifferential: standing.pointsFor - standing.pointsAgainst,
                    isControlled: standing.id == organisationID
                )
            }
    }

    // MARK: - One place

    /// A member with no identity or no resolvable city is dropped rather than guessed at.
    ///
    /// That cannot happen in a generated world — `LeagueGenerator` writes an identity for all 166
    /// members and gives each its own city — but a hostile save is not a generated world, and an
    /// invented coordinate would be a stated fact about where a programme plays.
    private static func place(
        id: UUID,
        tierLabel: String,
        conferenceID: UUID?,
        prestige: Int,
        isControlled: Bool,
        in state: GameState,
        citiesByID: [UUID: MapCity],
        regionsByID: [UUID: MapRegion],
        conferencesByID: [UUID: Conference],
        rivalries: [Rivalry]
    ) -> LeagueMapReadModel.Place? {
        guard let identity = state.identities[id],
              let city = citiesByID[identity.homeCityID] else { return nil }

        return LeagueMapReadModel.Place(
            stableID: id.uuidString,
            team: teamReference(id, in: state),
            cityName: city.name,
            regionID: city.regionID.uuidString,
            regionName: regionsByID[city.regionID]?.name ?? "Region not set",
            conferenceName: conferenceID.flatMap { conferencesByID[$0]?.name },
            tierLabel: tierLabel,
            isControlled: isControlled,
            x: city.x,
            y: city.y,
            marketSize: city.marketSize.value,
            prestige: prestige,
            venueName: identity.venueName,
            rivals: rivals(of: id, tierLabel: tierLabel, in: state, among: rivalries)
        )
    }

    /// The engine's own ordering, by calling the engine's own function.
    ///
    /// Re-sorting here would be a second definition of "strongest" that could drift from the one
    /// the world is actually built and maintained with.
    private static func rivals(
        of id: UUID,
        tierLabel: String,
        in state: GameState,
        among rivalries: [Rivalry]
    ) -> [LeagueMapReadModel.Rival] {
        RivalrySeeder.strongest(for: id, among: rivalries).compactMap { otherID in
            guard let rivalry = rivalries.first(where: {
                $0.involves(id) && $0.involves(otherID)
            }) else { return nil }
            return LeagueMapReadModel.Rival(
                stableID: otherID.uuidString,
                name: teamReference(otherID, in: state).name,
                originLabel: label(rivalry.origin, tierLabel: tierLabel),
                intensity: rivalry.intensity.value
            )
        }
    }

    /// Wording an enum the root holds, tier-aware. It states no fact the engine does not — and
    /// getting that requires the tier: `LeagueGenerator` seeds professional rivalries by passing
    /// each team's *division* id into the same field college seeding fills with a real conference
    /// id (`conferenceID: team.divisionID`), because the seeder itself is tier-blind and only ever
    /// asks "do these two share the id in this slot". A professional `Rivalry.origin` of
    /// `.conference` or `.both` therefore means *same division*, a materially tighter grouping than
    /// the professional 16-team conference this same `Place` already names in `conferenceName`.
    /// Calling it "Conference" would restate a different, larger group under the word for a smaller
    /// one on the same screen.
    static func label(_ origin: Rivalry.Origin, tierLabel: String) -> String {
        let sharedGroup = tierLabel == LeagueMapReadModel.Tier.professional ? "Division" : "Conference"
        switch origin {
        case .geography: return "Neighbours"
        case .conference: return sharedGroup
        case .both: return "\(sharedGroup) neighbours"
        }
    }
}
