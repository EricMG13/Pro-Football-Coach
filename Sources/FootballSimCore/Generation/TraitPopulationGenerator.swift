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
    ///
    /// `.volatile` joined when the weekly `disciplineFile` step began running.
    /// `DisciplineSystem.incidents` had read `player.has(.volatile)` since it was written, but no
    /// scheduler step ever called it, so the trait had a consumer that nothing reached — the same
    /// gate, failing one level further out than `ironman` did.
    private static let activeTraits: [Trait] = [.ironman, .restless, .volatile]

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
