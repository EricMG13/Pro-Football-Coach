import Foundation

/// A team's position in the table, with everything the standings screen needs.
public struct TeamStanding: Sendable, Equatable {
    public let team: Team
    public let record: TeamRecord
    public var divisionRank: Int
    public var conferenceSeed: Int?
    public var clinchedPlayoffs: Bool
    public var clinchedDivision: Bool
    public var eliminated: Bool

    public init(
        team: Team,
        record: TeamRecord,
        divisionRank: Int = 0,
        conferenceSeed: Int? = nil,
        clinchedPlayoffs: Bool = false,
        clinchedDivision: Bool = false,
        eliminated: Bool = false
    ) {
        self.team = team
        self.record = record
        self.divisionRank = divisionRank
        self.conferenceSeed = conferenceSeed
        self.clinchedPlayoffs = clinchedPlayoffs
        self.clinchedDivision = clinchedDivision
        self.eliminated = eliminated
    }
}

/// Orders teams and works out who is in the playoff field.
public enum StandingsCalculator {

    /// Applies one finished game to the league table.
    public static func apply(record: GameRecord, to league: inout League) {
        guard record.kind.countsInStandings else { return }
        guard let home = league.team(id: record.homeTeamID),
              let away = league.team(id: record.awayTeamID) else { return }

        var homeRecord = league.standings[home.id] ?? TeamRecord()
        var awayRecord = league.standings[away.id] ?? TeamRecord()

        homeRecord.pointsFor += record.homeScore
        homeRecord.pointsAgainst += record.awayScore
        awayRecord.pointsFor += record.awayScore
        awayRecord.pointsAgainst += record.homeScore

        let sameDivision = home.conference == away.conference && home.division == away.division
        let sameConference = home.conference == away.conference

        if record.isTie {
            homeRecord.ties += 1
            awayRecord.ties += 1
        } else if record.winnerID == home.id {
            homeRecord.wins += 1
            awayRecord.losses += 1
            if sameDivision { homeRecord.divisionWins += 1; awayRecord.divisionLosses += 1 }
            if sameConference { homeRecord.conferenceWins += 1; awayRecord.conferenceLosses += 1 }
        } else {
            awayRecord.wins += 1
            homeRecord.losses += 1
            if sameDivision { awayRecord.divisionWins += 1; homeRecord.divisionLosses += 1 }
            if sameConference { awayRecord.conferenceWins += 1; homeRecord.conferenceLosses += 1 }
        }

        league.standings[home.id] = homeRecord
        league.standings[away.id] = awayRecord
    }

    /// Head-to-head result between two teams this season, from `lhs`'s point of view.
    private static func headToHead(_ lhs: UUID, _ rhs: UUID, in league: League) -> Int {
        var margin = 0
        for record in league.results where record.involves(lhs) && record.involves(rhs) {
            if record.winnerID == lhs { margin += 1 }
            if record.winnerID == rhs { margin -= 1 }
        }
        return margin
    }

    /// Standard ordering: win percentage, then head-to-head, division record, conference
    /// record, and finally points scored.
    public static func isOrderedBefore(_ lhs: Team, _ rhs: Team, in league: League) -> Bool {
        let lhsRecord = league.record(for: lhs.id)
        let rhsRecord = league.record(for: rhs.id)

        if lhsRecord.winPercentage != rhsRecord.winPercentage {
            return lhsRecord.winPercentage > rhsRecord.winPercentage
        }
        let h2h = headToHead(lhs.id, rhs.id, in: league)
        if h2h != 0 { return h2h > 0 }

        if lhs.division == rhs.division && lhs.conference == rhs.conference {
            let lhsDivision = divisionWinPercentage(lhsRecord)
            let rhsDivision = divisionWinPercentage(rhsRecord)
            if lhsDivision != rhsDivision { return lhsDivision > rhsDivision }
        }
        let lhsConference = conferenceWinPercentage(lhsRecord)
        let rhsConference = conferenceWinPercentage(rhsRecord)
        if lhsConference != rhsConference { return lhsConference > rhsConference }

        if lhsRecord.pointsFor != rhsRecord.pointsFor { return lhsRecord.pointsFor > rhsRecord.pointsFor }
        // Last resort: a stable, arbitrary but deterministic order.
        return lhs.abbreviation < rhs.abbreviation
    }

    private static func divisionWinPercentage(_ record: TeamRecord) -> Double {
        let games = record.divisionWins + record.divisionLosses
        return games == 0 ? 0 : Double(record.divisionWins) / Double(games)
    }

    private static func conferenceWinPercentage(_ record: TeamRecord) -> Double {
        let games = record.conferenceWins + record.conferenceLosses
        return games == 0 ? 0 : Double(record.conferenceWins) / Double(games)
    }

    public static func divisionStandings(
        conference: Conference,
        division: Division,
        in league: League
    ) -> [TeamStanding] {
        league.teams(in: conference, division: division)
            .sorted { isOrderedBefore($0, $1, in: league) }
            .enumerated()
            .map { index, team in
                TeamStanding(
                    team: team,
                    record: league.record(for: team.id),
                    divisionRank: index + 1
                )
            }
    }

    /// The conference playoff field: division winners first by record, then wild cards.
    public static func playoffSeeds(conference: Conference, in league: League) -> [TeamStanding] {
        var divisionWinners: [Team] = []
        var others: [Team] = []

        for division in Division.allCases {
            let ordered = league.teams(in: conference, division: division)
                .sorted { isOrderedBefore($0, $1, in: league) }
            if let winner = ordered.first {
                divisionWinners.append(winner)
                others.append(contentsOf: ordered.dropFirst())
            }
        }

        divisionWinners.sort { isOrderedBefore($0, $1, in: league) }
        others.sort { isOrderedBefore($0, $1, in: league) }

        let wildCardSlots = max(0, league.settings.playoffFormat.teamsPerConference - divisionWinners.count)
        let field = divisionWinners + others.prefix(wildCardSlots)

        return field.enumerated().map { index, team in
            TeamStanding(
                team: team,
                record: league.record(for: team.id),
                divisionRank: divisionWinners.contains(where: { $0.id == team.id }) ? 1 : 0,
                conferenceSeed: index + 1,
                clinchedPlayoffs: true,
                clinchedDivision: divisionWinners.contains { $0.id == team.id }
            )
        }
    }

    /// Whole-conference ordering, used by the standings screen's conference tab.
    public static func conferenceStandings(_ conference: Conference, in league: League) -> [TeamStanding] {
        let seeded = playoffSeeds(conference: conference, in: league)
        let seedByTeam = Dictionary(uniqueKeysWithValues: seeded.compactMap { standing in
            standing.conferenceSeed.map { (standing.team.id, $0) }
        })
        return league.teams(in: conference)
            .sorted { isOrderedBefore($0, $1, in: league) }
            .map { team in
                TeamStanding(
                    team: team,
                    record: league.record(for: team.id),
                    conferenceSeed: seedByTeam[team.id],
                    clinchedPlayoffs: seedByTeam[team.id] != nil
                )
            }
    }

    public static func leagueStandings(in league: League) -> [TeamStanding] {
        league.teams
            .sorted { isOrderedBefore($0, $1, in: league) }
            .map { TeamStanding(team: $0, record: league.record(for: $0.id)) }
    }
}
