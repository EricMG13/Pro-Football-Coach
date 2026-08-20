import Foundation

/// Deterministic population of behavioural traits from an already-generated identity.
///
/// Identity is the substream boundary: adding or changing trait draws cannot consume the stream
/// that chose a person's name, ratings, position, potential, or UUID. Only traits with a live
/// mechanical consumer belong here. The other `Trait` cases remain Future Simulation Contract
/// dependencies until their named systems consume them; populating them now would make them
/// flavor-only data.
enum TraitPopulationGenerator {
    /// Already in `Trait.allCases` order. Add a case only when its mechanical consumer is live.
    ///
    /// `.ironman` joined when `PeopleLifecycleSystem.processHealth` began shortening its injuries
    /// through `PeopleRules.injuryWeeks`. Until then the trait was implemented and uncalled, so it
    /// was correctly withheld here — a populated `ironman` with no consumer is the flavour-only data
    /// this gate exists to refuse.
    private static let activeTraits: [Trait] = [.ironman, .restless]

    static func traits(for id: UUID) -> [Trait] {
        let personSeed = SeededRandom.seed(from: id)
        return activeTraits.filter { trait in
            guard let ordinal = Trait.allCases.firstIndex(of: trait) else { return false }
            var rng = SeededRandom(seed: SeededRandom.derive(
                from: personSeed,
                scope: .personnel,
                ordinal: ordinal
            ))
            return rng.chance(PeopleRules.traitPopulationProbability)
        }
    }
}
