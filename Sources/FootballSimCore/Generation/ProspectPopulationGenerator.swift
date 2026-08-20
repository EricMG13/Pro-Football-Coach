import Foundation

public enum ProspectPopulationGenerator {
    public static func generate(
        rootSeed: UInt64,
        season: Int,
        map: GameMap
    ) -> [Prospect] {
        guard !map.cities.isEmpty else { return [] }
        let seasonSeed = SeededRandom.derive(
            from: rootSeed,
            scope: .season,
            ordinal: season
        )
        let weightedPositions = Position.allCases.flatMap { position in
            Array(repeating: position, count: CollegeRules.initialRosterByPosition[position] ?? 1)
        }
        let regions = Dictionary(uniqueKeysWithValues: map.regions.map { ($0.id, $0) })
        var prospects: [Prospect] = []
        prospects.reserveCapacity(CollegeRules.annualProspectCount)

        for ordinal in 0..<CollegeRules.annualProspectCount {
            var rng = SeededRandom(seed: SeededRandom.derive(
                from: seasonSeed,
                scope: .personnel,
                ordinal: ordinal
            ))
            let city = map.cities[rng.int(in: 0...(map.cities.count - 1))]
            let position = ordinal < Position.allCases.count
                ? Position.allCases[ordinal]
                : weightedPositions[rng.int(in: 0...(weightedPositions.count - 1))]
            let density = regions[city.regionID]?.talentDensity.value
                ?? SharedRules.ratingRange.lowerBound
            // The same scale a programme's own roster is generated on, keyed on the region's
            // talent density rather than a programme's prestige. This was `42 + span * 28/59`, a
            // second expression nothing asserted agreed with the first, and recruiting therefore
            // sat 6.5 points below the league it fed.
            let base = RosterPopulationGenerator.baseRating(
                strength: Rating(density),
                tier: .college
            ) + rng.int(in: -8...8)
            var attributes = Attributes()
            for attribute in position.ratedAttributes {
                attributes[attribute] = Rating(base + rng.int(in: -7...7))
            }
            let name = NameGrammar.personName(using: &rng)
            let priorities = Dictionary(uniqueKeysWithValues: RecruitingPitch.allCases.map {
                ($0, Rating(rng.int(in: SharedRules.ratingRange)))
            })
            let id = rng.uuid()
            let age = rng.int(in: 17...19)
            let potential = Rating(base + rng.int(in: 8...24))
            prospects.append(Prospect(
                id: id,
                firstName: name.given,
                lastName: name.family,
                position: position,
                age: age,
                originCityID: city.id,
                attributes: attributes,
                potential: potential,
                traits: TraitPopulationGenerator.traits(for: id),
                priorities: priorities
            ))
        }
        return prospects
    }
}
