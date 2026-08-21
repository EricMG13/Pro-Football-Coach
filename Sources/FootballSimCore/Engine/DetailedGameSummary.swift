import Foundation

/// Converts the immutable detailed record into the bounded competition projection. The reducer
/// remains the only source of snaps; this adapter is deliberately pure so a completed match can be
/// finalized once and re-derived identically after a cold resume.
public enum DetailedGameSummaryBuilder {
    private struct Line {
        var passing = 0
        var rushing = 0
        var receiving = 0
        var touchdowns = 0
    }

    private struct TeamLine {
        var yards = 0
        var passing = 0
        var rushing = 0
        var turnovers = 0
        var plays = 0
    }

    public static func make(
        record: GameRecord,
        homeParticipantIDs: [UUID],
        awayParticipantIDs: [UUID],
        evidence: GameEvidence? = nil
    ) -> GameSummary {
        var teams: [Side: TeamLine] = [.home: TeamLine(), .away: TeamLine()]
        var lines: [UUID: Line] = [:]

        func update(_ id: UUID?, _ body: (inout Line) -> Void) {
            guard let id else { return }
            var line = lines[id, default: Line()]
            body(&line)
            lines[id] = line
        }

        for play in record.plays {
            let side = play.situation.possession
            let yards = max(0, play.outcome.yards)
            teams[side, default: TeamLine()].plays += 1
            if play.outcome.result.isTurnover {
                teams[side, default: TeamLine()].turnovers += 1
            }

            switch play.offensiveCall.playType {
            case .pass:
                teams[side, default: TeamLine()].yards += yards
                teams[side, default: TeamLine()].passing += yards
                update(play.outcome.passerID) { $0.passing += yards }
                update(play.outcome.targetID) { $0.receiving += yards }
                if play.outcome.result == .touchdown {
                    update(play.outcome.targetID ?? play.outcome.passerID) { $0.touchdowns += 1 }
                }
            case .run, .kneel:
                teams[side, default: TeamLine()].yards += yards
                teams[side, default: TeamLine()].rushing += yards
                update(play.outcome.ballCarrierID) { $0.rushing += yards }
                if play.outcome.result == .touchdown {
                    update(play.outcome.ballCarrierID) { $0.touchdowns += 1 }
                }
            case .punt, .fieldGoal:
                break
            }
        }

        func teamStatistics(_ side: Side) -> TeamGameStatistics {
            let line = teams[side] ?? TeamLine()
            let points = side == .home ? record.homeScore : record.awayScore
            return TeamGameStatistics(
                points: points,
                offensiveYards: line.yards,
                passingYards: line.passing,
                rushingYards: line.rushing,
                turnovers: line.turnovers,
                offensivePlays: line.plays
            )
        }

        let participants = Set(homeParticipantIDs + awayParticipantIDs)
        let playerStatistics: [PlayerGameStatistics] = lines.keys
            .sorted { $0.uuidString < $1.uuidString }
            .compactMap { id in
                guard participants.contains(id) else { return nil }
                let line = lines[id, default: Line()]
                return PlayerGameStatistics(
                    playerID: id,
                    passingYards: line.passing,
                    rushingYards: line.rushing,
                    receivingYards: line.receiving,
                    touchdowns: line.touchdowns
                )
            }
        return GameSummary(
            homeScore: record.homeScore,
            awayScore: record.awayScore,
            homeStatistics: teamStatistics(.home),
            awayStatistics: teamStatistics(.away),
            homeParticipantIDs: homeParticipantIDs,
            awayParticipantIDs: awayParticipantIDs,
            playerStatistics: playerStatistics,
            source: .detailed,
            evidence: evidence
        )
    }
}
