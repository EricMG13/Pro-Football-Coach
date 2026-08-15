import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func aftermath(from state: GameState) -> AftermathReadModel? {
        guard let controlledID = controlledOrganisationID(in: state) else { return nil }
        let game = state.competition.currentSchedule.games
            .filter {
                $0.result?.source == .detailed
                    && $0.result?.evidence != nil
                    && ($0.homeID == controlledID || $0.awayID == controlledID)
            }
            .sorted {
                if $0.season != $1.season { return $0.season > $1.season }
                if $0.week != $1.week { return $0.week > $1.week }
                return $0.id.uuidString > $1.id.uuidString
            }
            .first
        guard let game, let summary = game.result, let evidence = summary.evidence else { return nil }

        let home = MatchDayReadModel.TeamScore(
            team: teamReference(game.homeID, in: state),
            score: summary.homeScore
        )
        let away = MatchDayReadModel.TeamScore(
            team: teamReference(game.awayID, in: state),
            score: summary.awayScore
        )
        let resultLabel: String
        let headline: String
        if summary.homeScore == summary.awayScore {
            resultLabel = "Tie"
            headline = "\(home.team.name) and \(away.team.name) finished level."
        } else {
            let winner = summary.homeScore > summary.awayScore ? home.team : away.team
            resultLabel = "\(winner.abbreviation) win"
            headline = "\(winner.name) won the recorded fixture."
        }
        let grades = summary.playerStatistics.compactMap { line -> AftermathReadModel.Grade? in
            guard let player = state.players[line.playerID] else { return nil }
            let teamID = summary.homeParticipantIDs.contains(player.id) ? game.homeID : game.awayID
            let production = line.passingYards / 20 + line.rushingYards / 10
                + line.receivingYards / 10 + line.touchdowns * 8
            return AftermathReadModel.Grade(
                stableID: "\(game.id.uuidString)-\(player.id.uuidString)",
                player: .init(
                    stableID: player.id.uuidString,
                    name: player.fullName,
                    role: positionLabel(player.position)
                ),
                team: teamReference(teamID, in: state),
                position: positionLabel(player.position),
                rating: min(99, max(40, 55 + production)),
                evidence: "Passing \(line.passingYards), rushing \(line.rushingYards), receiving \(line.receivingYards), TD \(line.touchdowns)."
            )
        }
        let callIns = evidence.callInReceipts.map {
            "\($0.side == .home ? home.team.abbreviation : away.team.abbreviation): \($0.action.rawValue) at \($0.trigger.label.lowercased())"
        }
        return AftermathReadModel(
            recordedOutcomeID: game.id.uuidString,
            provenance: .simulationSnapshot,
            world: worldReference(state),
            venue: venueReference(game.homeID, in: state),
            home: home,
            away: away,
            resultLabel: resultLabel,
            headline: headline,
            evidence: [
                "Recorded drives: \(evidence.record.drives.count)",
                "Decisive matchups retained: \(evidence.decisiveMatchups.count)",
                "Source: controlled detailed reducer"
            ],
            callIns: callIns,
            injuries: [],
            grades: grades.sorted { $0.rating > $1.rating }
        )
    }

    private static func controlledOrganisationID(in state: GameState) -> UUID? {
        state.career.college?.programmeID
            ?? (state.careerArc.currentJob?.tier == .professional
                ? state.careerArc.currentJob?.organisationID
                : nil)
    }

    private static func positionLabel(_ position: Position) -> String {
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
}
