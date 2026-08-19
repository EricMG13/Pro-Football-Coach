import Foundation
import FootballSimCore
import ProFootballCoachUI

/// Builds the profile shared by map, standings and schedule links. The provider accepts any
/// organisation UUID; it never assumes the controlled college team, so historical and pro links
/// remain truthful too.
public extension CoachWorldReadModelProvider {
    static func worldSearch(from state: GameState) -> WorldSearchReadModel {
        let cities = Dictionary(uniqueKeysWithValues: state.map.cities.map { ($0.id, $0) })
        let regions = Dictionary(uniqueKeysWithValues: state.map.regions.map { ($0.id, $0) })
        var results: [WorldSearchReadModel.Result] = []
        results.reserveCapacity(state.programmes.count + state.proTeams.count)

        for programme in state.programmes.values {
            guard let identity = state.identities[programme.id],
                  let city = cities[identity.homeCityID],
                  let region = regions[city.regionID] else { continue }
            results.append(WorldSearchReadModel.Result(
                id: programme.id.uuidString,
                team: teamReference(programme.id, in: state),
                tier: "College",
                cityName: city.name,
                regionName: region.name
            ))
        }
        for team in state.proTeams.values {
            guard let identity = state.identities[team.id],
                  let city = cities[identity.homeCityID],
                  let region = regions[city.regionID] else { continue }
            results.append(WorldSearchReadModel.Result(
                id: team.id.uuidString,
                team: teamReference(team.id, in: state),
                tier: "Professional",
                cityName: city.name,
                regionName: region.name
            ))
        }
        results.sort { $0.team.name == $1.team.name
            ? $0.id < $1.id
            : $0.team.name.localizedCaseInsensitiveCompare($1.team.name) == .orderedAscending }
        return WorldSearchReadModel(
            snapshotID: snapshotID("world-search", state.league.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            seasonLabel: seasonLabel(state.calendar),
            results: results
        )
    }

    static func teamProgrammeProfile(
        _ organisationID: UUID,
        from state: GameState
    ) -> TeamProgrammeProfileReadModel? {
        let tier: Tier
        let cityName: String
        let conferenceID: UUID?
        let divisionID: UUID?
        let prestige: Int
        let rosterCount: Int
        let staffCount: Int

        if let programme = state.programmes[organisationID] {
            tier = .college
            cityName = programme.cityName
            conferenceID = programme.conferenceID
            divisionID = nil
            prestige = programme.prestige.value
            rosterCount = programme.rosterIDs.count
            staffCount = programme.staffIDs.count
        } else if let team = state.proTeams[organisationID] {
            tier = .pro
            cityName = team.cityName
            conferenceID = team.conferenceID
            divisionID = team.divisionID
            prestige = team.prestige.value
            rosterCount = team.rosterIDs.count
            staffCount = team.staffIDs.count
        } else {
            return nil
        }

        guard let identity = state.identities[organisationID],
              let city = state.map.city(identity.homeCityID),
              let region = state.map.regions.first(where: { $0.id == city.regionID }) else {
            return nil
        }

        let conference = conferenceID.flatMap { id in
            state.league.conferences.first(where: { $0.id == id })?.name
        } ?? "Independent"
        let division = divisionID.flatMap { id in
            state.league.divisions.first(where: { $0.id == id })?.name
        }
        // The most recent 12 by season/week, not the earliest 12: this feeds "Form · last six"
        // (`TeamProgrammeProfileView.recentResults`, which reads the last `formGames` of whichever
        // fixtures land here). A regular season already schedules every game up front (17 for pro,
        // `ProRules.gamesPerRegularSeason`), so taking the earliest 12 goes permanently stale the
        // moment more than 12 games exist for the team -- confirmed by a source-tracing pass,
        // 2026-08-19. College's 12-game regular season (`CollegeRules.gamesPerRegularSeason`) never
        // hit this at week 1, which is why the existing fixture-set test above didn't catch it.
        let fixtures = state.competition.currentSchedule.games
            .filter { $0.homeID == organisationID || $0.awayID == organisationID }
            .sorted {
                if $0.season != $1.season { return $0.season < $1.season }
                if $0.week != $1.week { return $0.week < $1.week }
                return $0.id.uuidString < $1.id.uuidString
            }
            .suffix(12)
            .compactMap { game -> TeamProgrammeProfileReadModel.Fixture? in
                let isHome = game.homeID == organisationID
                let opponentID = isHome ? game.awayID : game.homeID
                guard state.programmes[opponentID] != nil || state.proTeams[opponentID] != nil else {
                    return nil
                }
                return TeamProgrammeProfileReadModel.Fixture(
                    id: game.id.uuidString,
                    week: "Season " + String(game.season + 1) + ", Week " + String(game.week),
                    opponent: teamReference(opponentID, in: state),
                    isHome: isHome,
                    score: game.result.map {
                        String($0.homeScore) + "–" + String($0.awayScore)
                    },
                    stage: CoachWorldReadModelProvider.competitionStageLabel(game.stage)
                )
            }

        let rivalries = RivalrySeeder.strongest(for: organisationID, among: state.rivalries.values)
            .prefix(8)
            .compactMap { rivalID -> TeamProgrammeProfileReadModel.Rival? in
                guard let rivalry = state.rivalries.values.first(where: {
                    $0.involves(organisationID) && $0.involves(rivalID)
                }) else { return nil }
                return TeamProgrammeProfileReadModel.Rival(
                    id: rivalID.uuidString,
                    team: teamReference(rivalID, in: state),
                    origin: rivalry.origin.rawValue,
                    intensity: rivalry.intensity.value
                )
            }

        return TeamProgrammeProfileReadModel(
            snapshotID: snapshotID("team-profile", organisationID, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(organisationID, in: state),
            cityName: cityName,
            regionName: region.name,
            seasonLabel: seasonLabel(state.calendar),
            tier: tier == .college ? "College" : "Professional",
            conference: conference,
            division: division,
            venue: venueReference(organisationID, in: state),
            prestige: prestige,
            record: standingRow(organisationID, in: state).map { record($0) } ?? "0-0",
            rank: rankLabel(organisationID, in: state),
            rosterCount: rosterCount,
            staffCount: staffCount,
            traditions: identity.traditions.map(\.name),
            fixtures: Array(fixtures),
            rivals: Array(rivalries)
        )
    }

    private static func record(_ row: StandingRow) -> String {
        if row.ties == 0 {
            return String(row.wins) + "-" + String(row.losses)
        }
        return String(row.wins) + "-" + String(row.losses) + "-" + String(row.ties)
    }
}
