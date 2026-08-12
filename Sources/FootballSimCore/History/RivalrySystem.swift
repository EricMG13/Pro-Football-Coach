import Foundation

/// Applies completed rivalry meetings to the authoritative rivalry store.
///
/// The reducer only consumes results from the calendar being closed. That keeps a resumed save
/// from replaying older games and leaves the scheduler as the single owner of weekly ordering.
public struct RivalryTransition: Sendable, Equatable {
    public let rivalries: EntityStore<Rivalry>
    public let recordedRivalryIDs: [UUID]

    public init(rivalries: EntityStore<Rivalry>, recordedRivalryIDs: [UUID]) {
        self.rivalries = rivalries
        self.recordedRivalryIDs = recordedRivalryIDs
    }
}

public enum RivalrySystem {
    public static func process(after calendar: CalendarState, in state: GameState) -> RivalryTransition {
        var rivalries = state.rivalries
        let names = organisationNames(in: state)
        var rivalryByPair: [String: UUID] = [:]
        for rivalry in state.rivalries.values {
            let key = pairKey(rivalry.sideA, rivalry.sideB)
            if let existing = rivalryByPair[key] {
                if rivalry.id.uuidString < existing.uuidString {
                    rivalryByPair[key] = rivalry.id
                }
            } else {
                rivalryByPair[key] = rivalry.id
            }
        }
        var recorded: [UUID] = []

        let games = state.competition.currentSchedule.games
            .filter {
                $0.season == calendar.season
                    && $0.week == calendar.week
                    && $0.result != nil
            }
            .sorted { $0.id.uuidString < $1.id.uuidString }

        for game in games {
            guard let result = game.result,
                  let rivalryID = rivalryByPair[pairKey(game.homeID, game.awayID)] else {
                continue
            }
            let margin = abs(result.homeScore - result.awayScore)
            let closenessDelta: Int
            switch margin {
            case 0...3: closenessDelta = 5
            case 4...7: closenessDelta = 4
            case 8...14: closenessDelta = 2
            default: closenessDelta = 1
            }
            let stageDelta = game.stage == .regularSeason ? 0 : 1
            let homeName = names[game.homeID] ?? "Home"
            let awayName = names[game.awayID] ?? "Away"
            let meeting = "S\(calendar.season) W\(calendar.week): \(homeName) \(result.homeScore)-\(result.awayScore) \(awayName)"
            guard rivalries[rivalryID]?.notableMeetings.contains(meeting) != true else {
                continue
            }
            guard rivalries.update(rivalryID, {
                $0.record(meeting: meeting, intensityDelta: closenessDelta + stageDelta)
            }) else {
                continue
            }
            recorded.append(rivalryID)
        }

        return RivalryTransition(
            rivalries: rivalries,
            recordedRivalryIDs: recorded.sorted { $0.uuidString < $1.uuidString }
        )
    }

    private static func pairKey(_ lhs: UUID, _ rhs: UUID) -> String {
        let ordered = [lhs.uuidString, rhs.uuidString].sorted()
        return "\(ordered[0])|\(ordered[1])"
    }

    private static func organisationNames(in state: GameState) -> [UUID: String] {
        var names: [UUID: String] = [:]
        for programme in state.programmes.values { names[programme.id] = programme.name }
        for team in state.proTeams.values { names[team.id] = team.name }
        return names
    }
}
