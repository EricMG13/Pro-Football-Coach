import Foundation

/// Builds players around a target overall. Ratings are drawn per attribute, skewed so a
/// player is better at the things his position actually does, which makes two players with
/// the same overall still feel different.
public enum PlayerFactory {

    /// How far a position's craft attributes are pushed above its incidental ones.
    private static func skew(for attribute: Attribute, position: Position) -> Double {
        let weight = LeagueRules.overallWeights(for: position)[attribute] ?? 0
        let attributeCount = Double(position.attributes.count)
        let evenShare = 1.0 / attributeCount
        // Attributes that matter more than an even share drift up; the rest drift down.
        return (weight - evenShare) * 30
    }

    private static func heightWeight(
        for position: Position,
        _ rng: inout SeededRandom
    ) -> (height: Int, weight: Int) {
        let profile: (height: Int, heightSD: Double, weight: Int, weightSD: Double)
        switch position {
        case .qb: profile = (75, 1.4, 220, 10)
        case .rb: profile = (70, 1.5, 214, 12)
        case .wr: profile = (73, 1.8, 200, 12)
        case .te: profile = (77, 1.3, 250, 11)
        case .ol: profile = (77, 1.3, 315, 15)
        case .dl: profile = (76, 1.4, 295, 18)
        case .lb: profile = (74, 1.3, 240, 11)
        case .cb: profile = (71, 1.4, 192, 9)
        case .s: profile = (73, 1.3, 205, 9)
        case .k, .p: profile = (73, 1.6, 195, 12)
        }
        let height = Int(rng.gaussian(mean: Double(profile.height), sd: profile.heightSD).rounded())
        let weight = Int(rng.gaussian(mean: Double(profile.weight), sd: profile.weightSD).rounded())
        return (min(max(height, 66), 82), min(max(weight, 160), 360))
    }

    /// Younger players skew toward higher grades — the upside is what makes them worth drafting.
    private static func potential(
        age: Int,
        overall: Int,
        _ rng: inout SeededRandom
    ) -> PotentialGrade {
        // Roll on a 0...100 scale, shifted up for youth and down for players already good and old.
        var roll = rng.double01() * 100
        roll += Double(max(0, 27 - age)) * 3.5
        roll -= Double(max(0, age - 30)) * 6
        roll -= Double(max(0, overall - 80)) * 0.8
        switch roll {
        case 96...: return .aPlus
        case 88..<96: return .a
        case 78..<88: return .bPlus
        case 66..<78: return .b
        case 52..<66: return .cPlus
        case 36..<52: return .c
        case 20..<36: return .d
        default: return .f
        }
    }

    private static func traits(_ rng: inout SeededRandom) -> [Trait] {
        guard rng.chance(0.25) else { return [] }
        var picked = [rng.pick(Trait.allCases)]
        if rng.chance(0.2) {
            let second = rng.pick(Trait.allCases)
            // Never pair contradictory durability or loyalty traits.
            let conflicts: [Trait: Trait] = [
                .injuryProne: .ironMan, .ironMan: .injuryProne,
                .loyal: .mercenary, .mercenary: .loyal,
            ]
            if second != picked[0], conflicts[picked[0]] != second { picked.append(second) }
        }
        return picked
    }

    /// Creates one player whose overall lands near `targetOverall`.
    public static func make(
        position: Position,
        age: Int,
        targetOverall: Int,
        year: Int = 2026,
        rng: inout SeededRandom,
        potentialOverride: PotentialGrade? = nil,
        draftOrigin: DraftOrigin? = nil
    ) -> Player {
        let target = Double(targetOverall.clampedToRating())
        var values: [Attribute: Int] = [:]
        for attribute in position.attributes {
            let mean = target + skew(for: attribute, position: position)
            let raw = rng.gaussian(mean: mean, sd: 5.5)
            values[attribute] = Int(raw.rounded()).clampedToRating()
        }
        var ratings = Ratings(values: values)

        // Nudge the whole set so the weighted overall actually lands on target: individual
        // draws can drift, and the overall is what the rest of the game reads.
        let drift = targetOverall - ratings.overall(for: position)
        if drift != 0 { ratings.adjustAll(by: drift) }

        let (height, weight) = heightWeight(for: position, &rng)
        let (first, last) = NameBank.fullName(&rng)
        let yearsPro = max(0, age - 22)
        return Player(
            id: rng.uuid(),
            firstName: first,
            lastName: last,
            position: position,
            age: age,
            yearsPro: yearsPro,
            jersey: rng.int(in: position.jerseyRange),
            heightInches: height,
            weightPounds: weight,
            college: NameBank.college(&rng),
            draftOrigin: draftOrigin,
            ratings: ratings,
            potential: potentialOverride
                ?? potential(age: age, overall: ratings.overall(for: position), &rng),
            traits: traits(&rng),
            morale: rng.int(in: 55...85)
        )
    }

    /// Age drawn around a position's peak window, tilted by the front office's philosophy.
    public static func age(for position: Position, personality: AIPersonality, _ rng: inout SeededRandom) -> Int {
        let peak = LeagueRules.peakAgeWindow(position)
        let centre = Double(peak.lowerBound + peak.upperBound) / 2
        let tilt: Double
        switch personality {
        case .winNow: tilt = 1.5
        case .balanced: tilt = 0
        case .rebuilder: tilt = -2.0
        case .capHawk: tilt = -0.5
        }
        let drawn = rng.gaussian(mean: centre + tilt, sd: 3.0)
        return min(max(Int(drawn.rounded()), 21), 39)
    }
}
