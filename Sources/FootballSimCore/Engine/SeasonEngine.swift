import Foundation

/// Drives the league forward: weeks, results, standings, playoffs and the news that narrates it.
public enum SeasonEngine {

    /// What happened when the league advanced.
    public struct WeekReport: Sendable {
        public let week: Int
        public let results: [GameRecord]
        public let newsItems: [NewsItem]
        public let phaseAfter: SeasonPhase
    }

    /// Starts a fresh season: schedule, empty standings, kickoff news.
    public static func startSeason(_ league: inout League) {
        league.schedule = ScheduleGenerator.makeSchedule(
            teams: league.teams,
            year: league.year,
            standings: league.history.last?.standings ?? [:],
            rng: &league.rng
        )
        league.results = []
        league.standings = Dictionary(uniqueKeysWithValues: league.teams.map { ($0.id, TeamRecord()) })
        league.phase = .regularSeason(week: 1)

        // Next spring's class is drawn now, so scouting has a board to work on all season. It
        // used to be created only when the draft room opened, which put the entire scouting
        // economy — a coach skill branch, three costed actions, the fog ranges — behind the one
        // door that made it pointless.
        //
        // It draws from its own stream rather than the league's. Consuming league.rng here would
        // shift every simulated game that follows, and the class is a fixture of the year, not an
        // outcome of it. The seed is stable across launches and unique per franchise and year.
        if league.draftClass.isEmpty {
            var classRNG = SeededRandom(
                seed: SeededRandom.seed(from: league.userTeamID) &+ UInt64(league.year)
            )
            league.draftClass = DraftClassFactory.makeClass(year: league.year + 1, rng: &classRNG)
        }
        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: 0,
                category: .league,
                headline: "\(league.year) season kicks off",
                body: "Seventeen games, one champion. Every roster starts level."
            )
        )
    }

    /// Plays every unplayed game in the current week and moves the league on.
    @discardableResult
    public static func advanceWeek(
        _ league: inout League,
        userGameResult: GameRecord? = nil
    ) -> WeekReport {
        switch league.phase {
        case .preseason:
            startSeason(&league)
            return WeekReport(week: 0, results: [], newsItems: [], phaseAfter: league.phase)

        case .regularSeason(let week):
            return advanceRegularSeasonWeek(&league, week: week, userGameResult: userGameResult)

        case .playoffs(let round):
            return advancePlayoffRound(&league, round: round, userGameResult: userGameResult)

        case .offseason:
            return WeekReport(week: 0, results: [], newsItems: [], phaseAfter: league.phase)
        }
    }

    private static func advanceRegularSeasonWeek(
        _ league: inout League,
        week: Int,
        userGameResult: GameRecord?
    ) -> WeekReport {
        var played: [GameRecord] = []
        var news: [NewsItem] = []

        for game in league.games(inWeek: week) where !league.hasPlayed(game) {
            let record: GameRecord?
            if let userGameResult, userGameResult.scheduledGameID == game.id {
                // The user played this one by hand; take their result rather than simming it.
                record = userGameResult
            } else {
                record = GameSimulator.simulate(game: game, in: league, rng: &league.rng)
            }
            guard let record else { continue }
            league.results.append(record)
            StandingsCalculator.apply(record: record, to: &league)
            applyInjuries(record.injuries, to: &league)
            payCoachIfUserGame(record, in: &league, isPlayoff: false)
            played.append(record)
        }

        news.append(contentsOf: NewsEngine.weekRecap(results: played, league: league, week: week))
        healInjuries(&league)
        applyMoraleDrift(&league, results: played)
        league.news.append(contentsOf: news)

        // Move to the next week, or into the playoffs once the calendar is done.
        if week >= LeagueRules.seasonWeeks {
            seedPlayoffs(&league)
        } else {
            league.phase = .regularSeason(week: week + 1)
        }

        return WeekReport(week: week, results: played, newsItems: news, phaseAfter: league.phase)
    }

    /// Pays the coach for their own result. Wins were worth nothing until now: the event table
    /// existed from the first commit and no caller ever reached it.
    private static func payCoachIfUserGame(
        _ record: GameRecord,
        in league: inout League,
        isPlayoff: Bool
    ) {
        guard record.involves(league.userTeamID) else { return }
        guard let winnerID = record.winnerID else { return }
        let opponentID = record.homeTeamID == league.userTeamID
            ? record.awayTeamID
            : record.homeTeamID
        let isDivisional = league.team(id: opponentID).map { opponent in
            opponent.conference == league.userTeam?.conference
                && opponent.division == league.userTeam?.division
        } ?? false

        CoachEngine.awardForResult(
            win: winnerID == league.userTeamID,
            isDivisional: isDivisional,
            isPlayoff: isPlayoff,
            in: &league
        )
    }

    // MARK: - Playoffs

    /// Builds the wild-card round from the final standings.
    public static func seedPlayoffs(_ league: inout League) {
        var games: [ScheduledGame] = []
        let format = league.settings.playoffFormat

        for conference in Conference.allCases {
            let seeds = StandingsCalculator.playoffSeeds(conference: conference, in: league)
            let byes = format.byesPerConference
            let playing = Array(seeds.dropFirst(byes))
            // Highest remaining seed hosts the lowest: 2v7, 3v6, 4v5 in the 14-team field.
            var low = playing.count - 1
            var high = 0
            while high < low {
                games.append(
                    ScheduledGame(
                        id: league.rng.uuid(),
                        week: LeagueRules.seasonWeeks + 1,
                        homeTeamID: playing[high].team.id,
                        awayTeamID: playing[low].team.id,
                        kind: .wildCard
                    )
                )
                high += 1
                low -= 1
            }
        }

        league.schedule.append(contentsOf: games)
        league.phase = .playoffs(round: PlayoffRound.wildCard.rawValue)
        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: LeagueRules.seasonWeeks,
                category: .league,
                headline: "The playoff field is set",
                body: "\(format.rawValue) teams remain."
            )
        )
    }

    private static func advancePlayoffRound(
        _ league: inout League,
        round: Int,
        userGameResult: GameRecord?
    ) -> WeekReport {
        let week = LeagueRules.seasonWeeks + 1 + round
        var played: [GameRecord] = []

        for game in league.games(inWeek: week) where !league.hasPlayed(game) {
            let record: GameRecord?
            if let userGameResult, userGameResult.scheduledGameID == game.id {
                record = userGameResult
            } else {
                record = GameSimulator.simulate(game: game, in: league, rng: &league.rng)
            }
            guard let record else { continue }
            league.results.append(record)
            applyInjuries(record.injuries, to: &league)
            payCoachIfUserGame(record, in: &league, isPlayoff: true)
            played.append(record)
        }

        var news = NewsEngine.weekRecap(results: played, league: league, week: week)

        if let currentRound = PlayoffRound(rawValue: round), currentRound == .championship {
            if let final = played.first, let championID = final.winnerID,
               let champion = league.team(id: championID) {
                // The title is the largest single payout in the game and nothing ever paid it.
                if championID == league.userTeamID {
                    CoachEngine.award(.championship, to: &league.coach)
                }
                news.append(
                    NewsItem(
                        id: league.rng.uuid(),
                        year: league.year,
                        week: week,
                        category: .award,
                        headline: "\(champion.fullName) win the championship",
                        body: "\(final.homeScore)-\(final.awayScore) in the title game.",
                        teamIDs: [championID]
                    )
                )
            }
            league.news.append(contentsOf: news)
            league.phase = .offseason(stage: OffseasonStage.seasonReview.rawValue)
            return WeekReport(week: week, results: played, newsItems: news, phaseAfter: league.phase)
        }

        buildNextPlayoffRound(&league, completedRound: round, week: week)
        league.news.append(contentsOf: news)
        return WeekReport(week: week, results: played, newsItems: news, phaseAfter: league.phase)
    }

    /// Reseeds the survivors — the top remaining seed always draws the lowest.
    private static func buildNextPlayoffRound(_ league: inout League, completedRound: Int, week: Int) {
        guard let nextRound = PlayoffRound(rawValue: completedRound + 1) else { return }
        let format = league.settings.playoffFormat
        var games: [ScheduledGame] = []

        if nextRound == .championship {
            // One game between the two conference champions, at a neutral site.
            let finalists: [Team] = Conference.allCases.compactMap { conference in
                let seeds = StandingsCalculator.playoffSeeds(conference: conference, in: league)
                let survivors = seeds.map(\.team).filter { survived($0.id, throughWeek: week, in: league) }
                return survivors.first
            }
            if finalists.count == 2 {
                games.append(
                    ScheduledGame(
                        id: league.rng.uuid(),
                        week: week + 1,
                        homeTeamID: finalists[0].id,
                        awayTeamID: finalists[1].id,
                        kind: .championship,
                        isNeutralSite: true
                    )
                )
            }
        } else {
            for conference in Conference.allCases {
                let seeds = StandingsCalculator.playoffSeeds(conference: conference, in: league)
                var alive = seeds.filter { standing in
                    // Teams on a bye this round have not played yet, so they are still alive.
                    survived(standing.team.id, throughWeek: week, in: league)
                }
                if nextRound == .divisional {
                    // Bye teams join here.
                    let byeTeams = seeds.prefix(format.byesPerConference).map(\.self)
                    for bye in byeTeams where !alive.contains(where: { $0.team.id == bye.team.id }) {
                        alive.insert(bye, at: 0)
                    }
                }
                alive.sort { ($0.conferenceSeed ?? 99) < ($1.conferenceSeed ?? 99) }

                var high = 0
                var low = alive.count - 1
                while high < low {
                    games.append(
                        ScheduledGame(
                            id: league.rng.uuid(),
                            week: week + 1,
                            homeTeamID: alive[high].team.id,
                            awayTeamID: alive[low].team.id,
                            kind: nextRound.gameKind
                        )
                    )
                    high += 1
                    low -= 1
                }
            }
        }

        league.schedule.append(contentsOf: games)
        league.phase = .playoffs(round: nextRound.rawValue)
    }

    /// A team is still alive if it has not lost a playoff game up to and including `week`.
    private static func survived(_ teamID: UUID, throughWeek week: Int, in league: League) -> Bool {
        for record in league.results
        where record.kind.isPlayoff && record.week <= week && record.involves(teamID) {
            if record.loserID == teamID { return false }
        }
        return true
    }

    // MARK: - Between-week upkeep

    private static func applyInjuries(_ injuries: [InjuryOutcome], to league: inout League) {
        guard !injuries.isEmpty else { return }
        for injury in injuries {
            guard let teamIndex = league.teams.firstIndex(where: { $0.id == injury.teamID }),
                  let playerIndex = league.teams[teamIndex].roster.firstIndex(where: { $0.id == injury.playerID })
            else { continue }
            league.teams[teamIndex].roster[playerIndex].injuryWeeksRemaining = injury.weeksOut
        }
    }

    private static func healInjuries(_ league: inout League) {
        for teamIndex in league.teams.indices {
            for playerIndex in league.teams[teamIndex].roster.indices
            where league.teams[teamIndex].roster[playerIndex].injuryWeeksRemaining > 0 {
                league.teams[teamIndex].roster[playerIndex].injuryWeeksRemaining -= 1
            }
        }
    }

    /// Winning lifts the room, losing wears on it, and a leader steadies both.
    private static func applyMoraleDrift(_ league: inout League, results: [GameRecord]) {
        for record in results {
            for teamID in [record.homeTeamID, record.awayTeamID] {
                guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }) else { continue }
                let won = record.winnerID == teamID
                let hasLeader = league.teams[teamIndex].roster.contains { $0.has(.leader) }
                let drift = (won ? 3 : -3) + (hasLeader ? 1 : 0)
                for playerIndex in league.teams[teamIndex].roster.indices {
                    let current = league.teams[teamIndex].roster[playerIndex].morale
                    league.teams[teamIndex].roster[playerIndex].morale = min(100, max(0, current + drift))
                }
            }
        }
    }

    // MARK: - Convenience

    /// Simulates straight through to the end of the regular season and playoffs.
    public static func simulateToOffseason(_ league: inout League, maxSteps: Int = 40) {
        var steps = 0
        while !league.phase.isOffseason && steps < maxSteps {
            advanceWeek(&league)
            steps += 1
        }
    }

    /// The champion of the current season, once the title game has been played.
    public static func champion(of league: League) -> Team? {
        guard let final = league.results.first(where: { $0.kind == .championship }),
              let winnerID = final.winnerID else { return nil }
        return league.team(id: winnerID)
    }
}
