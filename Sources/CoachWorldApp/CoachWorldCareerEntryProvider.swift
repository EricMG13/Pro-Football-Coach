import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    static func startingJobs(from state: GameState, limit: Int = 3) -> [StartingJobReadModel] {
        guard limit > 0 else { return [] }
        return state.programmes.values
            .sorted {
                if $0.prestige.value != $1.prestige.value {
                    return $0.prestige.value < $1.prestige.value
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .prefix(limit)
            .map { programme in
                StartingJobReadModel(
                    stableID: programme.id.uuidString,
                    programme: teamReference(programme.id, in: state),
                    cityName: programme.cityName,
                    prestige: programme.prestige.value,
                    resources: programme.resources.value,
                    archetype: Archetype.with(id: programme.archetypeID).name,
                    expectation: expectation(for: programme.prestige.value)
                )
            }
    }

    private static func expectation(for prestige: Int) -> String {
        let target = min(95, max(40, prestige + 10))
        return "Target performance \(target)"
    }
}
