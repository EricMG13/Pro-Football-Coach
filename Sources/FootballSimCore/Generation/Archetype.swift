import Foundation

/// A programme archetype, from D6 and `02-GAME-DESIGN.md` §8.
///
/// D6's falsifier is that **archetype must be inferable from a programme's generated properties by
/// a simple classifier** — if it is not, the archetypes are cosmetic. Every prior below is
/// therefore a number the generator actually applies, and `IdentityDistributionTests` runs the
/// classifier.
public struct Archetype: Sendable, Equatable {
    public let id: Int
    public let name: String

    /// Priors, all on the 40 to 99 rating scale so they are comparable with everything else and
    /// with each other.
    public let resources: Int
    public let fanbaseVolatility: Int
    public let academicConstraint: Int
    public let recruitingReach: Int
    public let prestigeFloor: Int
    public let prestigeCeiling: Int

    /// Which schemes this archetype tends to inherit. `02` §6 makes scheme identity the spine, so
    /// an archetype that had no scheme lean would be missing a fifth of what makes it one.
    public let offensiveLean: [OffensiveScheme]
    public let defensiveLean: [DefensiveScheme]

    /// The 14 `SharedRules.programmeArchetypeCount` refers to.
    ///
    /// The spread matters as much as the values: a classifier can only recover an archetype from a
    /// programme if the archetypes occupy distinct regions of the prior space. `RulesTests` asserts
    /// the count and `IdentityDistributionTests` asserts the separation.
    ///
    /// **The prior vectors are spaced by search, not by taste.** The hand-written first set put
    /// Private academic and Technical institute 16 rating points apart across four priors, which is
    /// inside the generator's own jitter — two archetypes that close are one archetype with two
    /// names, and D6 calls that cosmetic. A local search re-spaced all fourteen to a minimum
    /// pairwise L1 of 62 while holding every value within ten points of its original, so each one
    /// keeps the character its name describes. `separationFloor` records the requirement the search
    /// was run against.
    ///
    /// **Two numbers, and they are not the same number.** The *derived requirement* is 24: jitter is
    /// plus or minus `LeagueGenerator.priorJitter` on each of four dimensions, so a programme sits a
    /// mean L1 of about 16 from its own centroid, and anything under about 1.5 times that puts a
    /// programme nearer a neighbour than its own archetype often enough to matter. The *achieved*
    /// minimum after the search is 62.
    ///
    /// The bar is set at 48, not 24. A bar at less than half the measured value is not a gate — the
    /// spacing could regress by a factor of two and stay green, which is exactly the regression that
    /// would make the archetypes cosmetic again. 48 leaves room to re-tune an archetype's character
    /// while failing loudly on a collapse.
    public static let separationFloor = 48
    public static let all: [Archetype] = [
        Archetype(id: 0, name: "Land-grant power",
                  resources: 99, fanbaseVolatility: 79, academicConstraint: 44,
                  recruitingReach: 99, prestigeFloor: 72, prestigeCeiling: 96,
                  offensiveLean: [.powerRun, .proStyle], defensiveLean: [.fourThree, .bearFront]),
        Archetype(id: 1, name: "Private academic",
                  resources: 84, fanbaseVolatility: 54, academicConstraint: 99,
                  recruitingReach: 72, prestigeFloor: 52, prestigeCeiling: 82,
                  offensiveLean: [.westCoast, .proStyle], defensiveLean: [.tampaTwo, .nickelBase]),
        Archetype(id: 2, name: "Service academy",
                  resources: 48, fanbaseVolatility: 46, academicConstraint: 98,
                  recruitingReach: 42, prestigeFloor: 44, prestigeCeiling: 70,
                  offensiveLean: [.spreadOption, .powerRun], defensiveLean: [.threeFour, .bearFront]),
        Archetype(id: 3, name: "Commuter school",
                  resources: 40, fanbaseVolatility: 42, academicConstraint: 49,
                  recruitingReach: 56, prestigeFloor: 40, prestigeCeiling: 62,
                  offensiveLean: [.runAndShoot, .airRaid], defensiveLean: [.nickelBase, .tampaTwo]),
        Archetype(id: 4, name: "Regional riser",
                  resources: 73, fanbaseVolatility: 84, academicConstraint: 66,
                  recruitingReach: 57, prestigeFloor: 46, prestigeCeiling: 84,
                  offensiveLean: [.airRaid, .spreadOption], defensiveLean: [.nickelBase, .pressMan]),
        Archetype(id: 5, name: "Fallen blueblood",
                  resources: 90, fanbaseVolatility: 99, academicConstraint: 58,
                  recruitingReach: 79, prestigeFloor: 44, prestigeCeiling: 90,
                  offensiveLean: [.proStyle, .powerRun], defensiveLean: [.fourThree, .threeFour]),
        Archetype(id: 6, name: "Oil-money upstart",
                  resources: 87, fanbaseVolatility: 66, academicConstraint: 40,
                  recruitingReach: 63, prestigeFloor: 48, prestigeCeiling: 88,
                  offensiveLean: [.airRaid, .runAndShoot], defensiveLean: [.pressMan, .nickelBase]),
        Archetype(id: 7, name: "Rural stalwart",
                  resources: 61, fanbaseVolatility: 56, academicConstraint: 60,
                  recruitingReach: 40, prestigeFloor: 42, prestigeCeiling: 68,
                  offensiveLean: [.powerRun, .spreadOption], defensiveLean: [.bearFront, .fourThree]),
        Archetype(id: 8, name: "Metropolitan flagship",
                  resources: 98, fanbaseVolatility: 52, academicConstraint: 78,
                  recruitingReach: 97, prestigeFloor: 62, prestigeCeiling: 92,
                  offensiveLean: [.proStyle, .westCoast], defensiveLean: [.fourThree, .tampaTwo]),
        Archetype(id: 9, name: "Technical institute",
                  resources: 79, fanbaseVolatility: 40, academicConstraint: 79,
                  recruitingReach: 49, prestigeFloor: 46, prestigeCeiling: 76,
                  offensiveLean: [.spreadOption, .runAndShoot], defensiveLean: [.threeFour, .tampaTwo]),
        Archetype(id: 10, name: "Coastal boutique",
                  resources: 54, fanbaseVolatility: 68, academicConstraint: 86,
                  recruitingReach: 64, prestigeFloor: 44, prestigeCeiling: 78,
                  offensiveLean: [.westCoast, .airRaid], defensiveLean: [.pressMan, .nickelBase]),
        Archetype(id: 11, name: "Mining-town grinder",
                  resources: 50, fanbaseVolatility: 95, academicConstraint: 47,
                  recruitingReach: 43, prestigeFloor: 40, prestigeCeiling: 66,
                  offensiveLean: [.powerRun, .proStyle], defensiveLean: [.bearFront, .threeFour]),
        Archetype(id: 12, name: "Faith-founded",
                  resources: 61, fanbaseVolatility: 44, academicConstraint: 70,
                  recruitingReach: 80, prestigeFloor: 48, prestigeCeiling: 80,
                  offensiveLean: [.proStyle, .westCoast], defensiveLean: [.fourThree, .nickelBase]),
        Archetype(id: 13, name: "Frontier expansionist",
                  resources: 50, fanbaseVolatility: 71, academicConstraint: 52,
                  recruitingReach: 90, prestigeFloor: 42, prestigeCeiling: 74,
                  offensiveLean: [.spreadOption, .airRaid], defensiveLean: [.nickelBase, .bearFront]),
    ]

    public static func with(id: Int) -> Archetype {
        all[((id % all.count) + all.count) % all.count]
    }

    /// The priors as a vector, in a fixed order, for the classifier D6's falsifier requires.
    public var priorVector: [Int] {
        [resources, fanbaseVolatility, academicConstraint, recruitingReach]
    }
}
