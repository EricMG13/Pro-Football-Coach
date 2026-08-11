import Foundation

public struct PostseasonTransition: Sendable, Equatable {
    public let competition: CompetitionState
    public let eventPayloads: [DomainEventPayload]

    public init(competition: CompetitionState, eventPayloads: [DomainEventPayload]) {
        self.competition = competition
        self.eventPayloads = eventPayloads
    }
}

public enum PostseasonSystem {
    public static func advance(
        after completed: CalendarState,
        in state: GameState
    ) -> PostseasonTransition {
        var competition = state.competition
        var payloads: [DomainEventPayload] = []

        switch completed.week {
        case CollegeRules.regularSeasonWeeks:
            let ranking = competition.rankings[.college] ?? state.programmes.ids
            var pairs: [(UUID, UUID)] = []
            for conference in state.league.conferences(in: .college) {
                let members = ranking.filter(conference.memberIDs.contains)
                if members.count >= 2 { pairs.append((members[0], members[1])) }
            }
            appendStage(
                tier: .college,
                stage: .conferenceChampionship,
                week: CollegeRules.regularSeasonWeeks + 1,
                pairs: pairs,
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case CollegeRules.regularSeasonWeeks + CollegeRules.conferenceChampionshipWeeks:
            let entrants = Array((competition.rankings[.college] ?? []).prefix(
                CollegeRules.bracketTeams
            ))
            appendStage(
                tier: .college,
                stage: .quarterfinal,
                week: completed.week + 1,
                pairs: highLowPairs(entrants),
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case CollegeRules.regularSeasonWeeks + CollegeRules.conferenceChampionshipWeeks + 1:
            appendWinnerRound(
                tier: .college,
                from: .quarterfinal,
                to: .semifinal,
                week: completed.week + 1,
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case CollegeRules.regularSeasonWeeks + CollegeRules.conferenceChampionshipWeeks + 2:
            appendWinnerRound(
                tier: .college,
                from: .semifinal,
                to: .championship,
                week: completed.week + 1,
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case CollegeRules.seasonWeeks:
            competition.collegeChampionID = winners(
                tier: .college,
                stage: .championship,
                competition: competition
            ).first

        case ProRules.regularSeasonWeeks:
            let ranking = competition.rankings[.pro] ?? state.proTeams.ids
            var pairs: [(UUID, UUID)] = []
            for conference in state.league.conferences(in: .pro) {
                let entrants = Array(ranking.filter(conference.memberIDs.contains).prefix(4))
                pairs.append(contentsOf: highLowPairs(entrants))
            }
            appendStage(
                tier: .pro,
                stage: .quarterfinal,
                week: completed.week + 1,
                pairs: pairs,
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case ProRules.regularSeasonWeeks + 1:
            let quarterfinalWinners = winners(
                tier: .pro,
                stage: .quarterfinal,
                competition: competition
            )
            var pairs: [(UUID, UUID)] = []
            for conference in state.league.conferences(in: .pro) {
                let conferenceWinners = quarterfinalWinners.filter(conference.memberIDs.contains)
                pairs.append(contentsOf: highLowPairs(conferenceWinners))
            }
            appendStage(
                tier: .pro,
                stage: .semifinal,
                week: completed.week + 1,
                pairs: pairs,
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case ProRules.regularSeasonWeeks + 2:
            appendWinnerRound(
                tier: .pro,
                from: .semifinal,
                to: .championship,
                week: completed.week + 1,
                state: state,
                competition: &competition,
                payloads: &payloads
            )

        case ProRules.seasonWeeks:
            competition.proChampionID = winners(
                tier: .pro,
                stage: .championship,
                competition: competition
            ).first

        default:
            break
        }

        return PostseasonTransition(competition: competition, eventPayloads: payloads)
    }

    public static func completeSeason(
        after completed: CalendarState,
        in state: GameState
    ) -> PostseasonTransition {
        guard completed.week == SharedRules.inSeasonWeeks,
              let collegeChampionID = state.competition.collegeChampionID,
              let proChampionID = state.competition.proChampionID else {
            return PostseasonTransition(competition: state.competition, eventPayloads: [])
        }
        var competition = state.competition
        competition.appendArchive(SeasonArchive(
            season: completed.season,
            collegeChampionID: collegeChampionID,
            proChampionID: proChampionID,
            finalCollegeRanking: competition.rankings[.college] ?? [],
            finalProRanking: competition.rankings[.pro] ?? [],
            awards: seasonAwards(
                collegeChampionID: collegeChampionID,
                proChampionID: proChampionID,
                state: state,
                competition: competition
            ),
            gamesPlayed: competition.currentSchedule.games.filter { $0.result != nil }.count,
            totalPoints: competition.currentSchedule.games.reduce(0) {
                $0 + ($1.result.map { $0.homeScore + $0.awayScore } ?? 0)
            }
        ))
        let archives = competition.archives
        let recordBook = competition.recordBook
        competition = CompetitionState(
            currentSchedule: SeasonSchedule(
                season: completed.season + 1,
                games: ScheduleGenerator.regularSeason(
                    seed: state.league.seed,
                    season: completed.season + 1,
                    programmes: state.programmes.values,
                    proTeams: state.proTeams.values
                )
            ),
            archives: archives,
            recordBook: recordBook
        )
        var rolloverState = state
        rolloverState.competition = competition
        competition = CompetitionReducer.rebuild(from: rolloverState)
        return PostseasonTransition(
            competition: competition,
            eventPayloads: [.seasonCompleted(
                season: completed.season,
                collegeChampionID: collegeChampionID,
                proChampionID: proChampionID
            )]
        )
    }

    private static func appendWinnerRound(
        tier: Tier,
        from sourceStage: CompetitionStage,
        to stage: CompetitionStage,
        week: Int,
        state: GameState,
        competition: inout CompetitionState,
        payloads: inout [DomainEventPayload]
    ) {
        let ranking = competition.rankings[tier] ?? []
        let winnerSet = Set(winners(tier: tier, stage: sourceStage, competition: competition))
        let ordered = ranking.filter(winnerSet.contains)
        appendStage(
            tier: tier,
            stage: stage,
            week: week,
            pairs: highLowPairs(ordered),
            state: state,
            competition: &competition,
            payloads: &payloads
        )
    }

    private static func appendStage(
        tier: Tier,
        stage: CompetitionStage,
        week: Int,
        pairs: [(UUID, UUID)],
        state: GameState,
        competition: inout CompetitionState,
        payloads: inout [DomainEventPayload]
    ) {
        guard !pairs.isEmpty,
              !competition.currentSchedule.games.contains(where: {
                  $0.tier == tier && $0.stage == stage
              }) else { return }
        var games: [ScheduledGame] = []
        for (index, pair) in pairs.enumerated() {
            var rng = SeededRandom(seed: postseasonSeed(
                root: state.league.seed,
                season: state.calendar.season,
                tier: tier,
                stage: stage,
                ordinal: index
            ))
            games.append(ScheduledGame(
                id: rng.uuid(),
                season: state.calendar.season,
                tier: tier,
                week: week,
                stage: stage,
                homeID: pair.0,
                awayID: pair.1
            ))
        }
        competition.currentSchedule.append(contentsOf: games)
        payloads.append(.postseasonScheduled(
            tier: tier,
            stage: stage,
            gameIDs: games.map(\.id),
            participantIDs: games.flatMap { [$0.homeID, $0.awayID] }
        ))
    }

    private static func highLowPairs(_ ordered: [UUID]) -> [(UUID, UUID)] {
        guard ordered.count >= 2, ordered.count.isMultiple(of: 2) else { return [] }
        return (0..<(ordered.count / 2)).map {
            (ordered[$0], ordered[ordered.count - 1 - $0])
        }
    }

    private static func winners(
        tier: Tier,
        stage: CompetitionStage,
        competition: CompetitionState
    ) -> [UUID] {
        competition.currentSchedule.games.compactMap { game in
            guard game.tier == tier, game.stage == stage, let result = game.result else { return nil }
            return result.homeScore > result.awayScore ? game.homeID : game.awayID
        }
    }

    private static func postseasonSeed(
        root: UInt64,
        season: Int,
        tier: Tier,
        stage: CompetitionStage,
        ordinal: Int
    ) -> UInt64 {
        let seasonSeed = SeededRandom.derive(from: root, scope: .season, ordinal: season)
        let tierIndex = Tier.allCases.firstIndex(of: tier) ?? 0
        let tierSeed = SeededRandom.derive(from: seasonSeed, scope: .scheduler, ordinal: tierIndex)
        let stageIndex = CompetitionStage.allCases.firstIndex(of: stage) ?? 0
        let stageSeed = SeededRandom.derive(from: tierSeed, scope: .week, ordinal: stageIndex)
        return SeededRandom.derive(from: stageSeed, scope: .game, ordinal: ordinal)
    }

    private static func seasonAwards(
        collegeChampionID: UUID,
        proChampionID: UUID,
        state: GameState,
        competition: CompetitionState
    ) -> [SeasonAward] {
        var awards = [
            SeasonAward(kind: .champion, tier: .college, winnerID: collegeChampionID, value: 1),
            SeasonAward(kind: .champion, tier: .pro, winnerID: proChampionID, value: 1),
        ]
        let collegeIDs = Set(state.programmes.ids)
        let proIDs = Set(state.proTeams.ids)
        for (tier, ids) in [(Tier.college, collegeIDs), (Tier.pro, proIDs)] {
            if let topOffense = competition.teamStatistics
                .filter({ ids.contains($0.key) })
                .max(by: awardValueOrder) {
                awards.append(SeasonAward(
                    kind: .topOffense,
                    tier: tier,
                    winnerID: topOffense.key,
                    value: topOffense.value.points
                ))
            }
        }

        let collegePlayers = Set(state.programmes.values.flatMap(\.rosterIDs))
        let proPlayers = Set(state.proTeams.values.flatMap(\.rosterIDs))
        for (tier, ids) in [(Tier.college, collegePlayers), (Tier.pro, proPlayers)] {
            if let player = competition.playerStatistics
                .filter({ ids.contains($0.key) })
                .max(by: playerAwardValueOrder) {
                awards.append(SeasonAward(
                    kind: .playerOfTheYear,
                    tier: tier,
                    winnerID: player.key,
                    value: playerAwardValue(player.value)
                ))
            }
        }
        return awards.sorted {
            if $0.tier != $1.tier { return $0.tier.rawValue < $1.tier.rawValue }
            return $0.kind.rawValue < $1.kind.rawValue
        }
    }

    private static func awardValueOrder(
        _ lhs: Dictionary<UUID, TeamSeasonStatistics>.Element,
        _ rhs: Dictionary<UUID, TeamSeasonStatistics>.Element
    ) -> Bool {
        if lhs.value.points != rhs.value.points { return lhs.value.points < rhs.value.points }
        return lhs.key.uuidString > rhs.key.uuidString
    }

    private static func playerAwardValueOrder(
        _ lhs: Dictionary<UUID, PlayerSeasonStatistics>.Element,
        _ rhs: Dictionary<UUID, PlayerSeasonStatistics>.Element
    ) -> Bool {
        let lhsValue = playerAwardValue(lhs.value)
        let rhsValue = playerAwardValue(rhs.value)
        if lhsValue != rhsValue { return lhsValue < rhsValue }
        return lhs.key.uuidString > rhs.key.uuidString
    }

    private static func playerAwardValue(_ statistics: PlayerSeasonStatistics) -> Int {
        statistics.passingYards
            + statistics.rushingYards
            + statistics.receivingYards
            + statistics.touchdowns * CompetitionRules.playerAwardTouchdownValue
    }
}
