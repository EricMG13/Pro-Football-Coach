import Foundation
import FootballSimCore

/// Shared builders so suites don't repeat boilerplate construction.
enum TestFixtures {
    /// A player whose every rated attribute equals `rating`, so his overall is exactly `rating`.
    static func player(
        position: Position,
        rating: Int,
        potential: PotentialGrade = .cPlus,
        age: Int = 26,
        morale: Int = 70,
        traits: [Trait] = []
    ) -> Player {
        var values: [Attribute: Int] = [:]
        for attribute in position.attributes { values[attribute] = rating }
        return Player(
            firstName: "Test",
            lastName: position.abbreviation,
            position: position,
            age: age,
            yearsPro: max(0, age - 22),
            jersey: position.jerseyRange.lowerBound,
            heightInches: 73,
            weightPounds: 215,
            college: "Test State",
            ratings: Ratings(values: values),
            potential: potential,
            traits: traits,
            morale: morale
        )
    }

    /// A full-strength roster where every player rates `rating`.
    static func roster(rating: Int, age: Int = 26) -> [Player] {
        var players: [Player] = []
        for position in Position.allCases {
            for _ in 0..<position.rosterTarget {
                players.append(player(position: position, rating: rating, age: age))
            }
        }
        return players
    }
}
