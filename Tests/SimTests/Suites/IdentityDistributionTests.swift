import Foundation
import FootballSimCore

// D6's falsifier, verbatim from docs/OPEN-DECISIONS.md:
//
//   "Falsified if, across 200 generated leagues, rivalry intensity does not separate (top decile vs
//    median indistinguishable), or if programme archetype cannot be inferred from a programme's
//    generated properties by a simple classifier — meaning the archetypes are cosmetic."
//
// Both limbs are here. The owner-side half of the falsifier — after five seasons the owner should
// be able to name three rival programmes and why they matter — is an owner action and is handed off
// in the walkthrough script, never claimed here.

func runIdentityDistributionTests() {
    suite("Identity distribution: rivalry intensity") {
        test("rivalry intensity separates the top decile from the median") {
            // If every rivalry is equally intense, none of them is a rivalry. The separation is
            // what makes a save's map have a shape rather than a uniform texture.
            var intensities: [Int] = []
            for world in sweptWorlds {
                intensities.append(contentsOf: world.rivalries.map(\.intensity.value))
            }
            expect(intensities.count > 1_000, "only \(intensities.count) rivalries swept")
            intensities.sort()
            let median = intensities[intensities.count / 2]
            let topDecile = intensities[(intensities.count * 9) / 10]
            expect(topDecile > median,
                   "the top decile of rivalry intensity (\(topDecile)) does not exceed the median "
                       + "(\(median)), so intensity does not separate")
            expect(topDecile - median >= 5,
                   "the top decile beats the median by only \(topDecile - median) rating points, "
                       + "which is not a difference a player could feel")
        }

        test("origin drives intensity in the order the seeder claims") {
            // Not just that intensity varies, but that it varies for the stated reason. A seeder
            // that jittered a constant would pass the separation test above and mean nothing.
            var byOrigin: [Rivalry.Origin: [Int]] = [:]
            for world in sweptWorlds {
                for rivalry in world.rivalries {
                    byOrigin[rivalry.origin, default: []].append(rivalry.intensity.value)
                }
            }
            func mean(_ origin: Rivalry.Origin) -> Double {
                let values = byOrigin[origin] ?? []
                guard !values.isEmpty else { return 0 }
                return Double(values.reduce(0, +)) / Double(values.count)
            }
            expect(!(byOrigin[.both] ?? []).isEmpty, "no rivalry was seeded by both causes")
            expect(!(byOrigin[.geography] ?? []).isEmpty, "no rivalry was seeded by geography")
            expect(!(byOrigin[.conference] ?? []).isEmpty, "no rivalry was seeded by conference")
            expect(mean(.both) > mean(.geography),
                   "a shared border and a shared conference is not stronger than geography alone")
            expect(mean(.geography) > mean(.conference),
                   "geography does not beat conference, so place is not the mechanic D6 makes it")
        }

        test("a programme's strongest rival is not simply its nearest neighbour every time") {
            // Geography seeds rivalries; it must not wholly determine them, or conference and
            // jitter are decoration.
            var nearestWasStrongest = 0, considered = 0
            for world in sweptWorlds.prefix(20) {
                for programme in world.programmes.prefix(20) {
                    guard let strongest = programme.rivalIDs.first,
                          let home = world.identities[programme.id]
                              .map(\.homeCityID).flatMap(world.map.city)
                    else { continue }
                    let nearest = programme.rivalIDs.min { lhs, rhs in
                        let l = world.identities[lhs].map(\.homeCityID).flatMap(world.map.city)
                        let r = world.identities[rhs].map(\.homeCityID).flatMap(world.map.city)
                        guard let l, let r else { return false }
                        return home.squaredDistance(to: l) < home.squaredDistance(to: r)
                    }
                    considered += 1
                    if nearest == strongest { nearestWasStrongest += 1 }
                }
            }
            expect(considered > 100, "only \(considered) programmes considered")
            let share = Double(nearestWasStrongest) / Double(considered)
            expect(share < 0.9,
                   "the nearest rival is the strongest \(Int(share * 100)) percent of the time, so "
                       + "rivalry is just distance wearing another name")
        }
    }

    suite("Identity distribution: archetype recovery") {
        test("a nearest-centroid classifier recovers archetype from generated properties") {
            // D6's second limb. The classifier is deliberately simple — nearest centroid over the
            // prior vector, no training, no tuning — because the claim being tested is that the
            // archetypes are *legible in the output*, not that a clever model can find them.
            //
            // The features are what a programme actually carries after generation, so this fails if
            // generation stops applying an archetype's priors even while still recording its id.
            var correct = 0, total = 0
            for world in sweptWorlds.prefix(40) {
                for programme in world.programmes {
                    let predicted = nearestArchetype(to: programme.priorVector)
                    if predicted == programme.archetypeID { correct += 1 }
                    total += 1
                }
            }
            expect(total > 4_000, "only \(total) programmes classified")
            let accuracy = Double(correct) / Double(total)
            // Measured at 1.00 over 5,360 programmes, against a 0.07 chance baseline. The bar is
            // 0.90 rather than "three times chance" because a bar far below the measurement is not
            // a gate — it would stay green through a change that halved the archetype separation or
            // doubled the jitter, which is exactly the change that would make the archetypes
            // cosmetic again.
            expect(accuracy >= 0.90,
                   "archetype recovered at \(Int(accuracy * 100)) percent, against a measured "
                       + "baseline of 100 percent — the archetypes have stopped being legible in "
                       + "the generated output, which is D6's falsifier")
        }

        test("the classifier is not recovering archetype from a single giveaway feature") {
            // If prestige alone recovered the archetype, the other priors would be decoration and
            // the archetypes would be one number with fourteen labels.
            var prestigeOnlyCorrect = 0, total = 0
            for world in sweptWorlds.prefix(20) {
                for programme in world.programmes {
                    let predicted = Archetype.all.min {
                        Swift.abs(midPrestige($0) - Double(programme.prestige.value))
                            < Swift.abs(midPrestige($1) - Double(programme.prestige.value))
                    }
                    if predicted?.id == programme.archetypeID { prestigeOnlyCorrect += 1 }
                    total += 1
                }
            }
            // Measured at 0.13, against a 0.07 chance baseline and the full vector's 1.00. So the
            // four priors carry essentially all of the signal and prestige carries almost none of
            // it, which is what makes the 100 percent above a statement about the archetypes rather
            // than about one lucky feature.
            let prestigeAccuracy = Double(prestigeOnlyCorrect) / Double(total)
            expect(prestigeAccuracy < 0.35,
                   "prestige alone recovers archetype \(Int(prestigeAccuracy * 100)) percent of the "
                       + "time, so the other priors are not doing work")
        }

        test("archetypes occupy distinct regions of the prior space") {
            // The precondition for any classifier to work at all. Two archetypes with identical
            // priors are one archetype with two names, which is cosmetic by definition.
            for (indexA, archetypeA) in Archetype.all.enumerated() {
                for archetypeB in Archetype.all[(indexA + 1)...] {
                    let distance = zip(archetypeA.priorVector, archetypeB.priorVector)
                        .reduce(0) { $0 + Swift.abs($1.0 - $1.1) }
                    expect(distance >= Archetype.separationFloor,
                           "\(archetypeA.name) and \(archetypeB.name) differ by only \(distance) "
                               + "rating points across four priors, under the "
                               + "\(Archetype.separationFloor) the jitter needs")
                }
            }
        }

        test("archetypes are spread across programmes rather than piling on one") {
            var counts: [Int: Int] = [:]
            for world in sweptWorlds.prefix(40) {
                for programme in world.programmes { counts[programme.archetypeID, default: 0] += 1 }
            }
            expectEqual(counts.count, Archetype.all.count, "an archetype never generated")
            // Allocated, not sampled, so this is tight by construction: 134 does not divide by 14,
            // so each league gives some archetypes one extra programme and the counts differ by at
            // most one league's worth of remainder.
            let values = counts.values.sorted()
            expect(Double(values.last!) < Double(values.first!) * 1.2,
                   "archetype use is lopsided: \(values.first!) to \(values.last!)")
        }
    }
}

// MARK: - The simple classifier

private func midPrestige(_ archetype: Archetype) -> Double {
    Double(archetype.prestigeFloor + archetype.prestigeCeiling) / 2
}

/// Nearest centroid over the four realised priors, by L1 distance.
///
/// No training, no tuning, no weighting — deliberately. The claim D6's falsifier tests is that the
/// archetypes are *legible in the generated output*, not that a clever model can find them. A
/// classifier with any freedom in it would be testing the classifier.
private func nearestArchetype(to priors: [Int]) -> Int {
    Archetype.all.min { lhs, rhs in
        l1(priors, lhs.priorVector) < l1(priors, rhs.priorVector)
    }?.id ?? 0
}

private func l1(_ a: [Int], _ b: [Int]) -> Int {
    zip(a, b).reduce(0) { $0 + Swift.abs($1.0 - $1.1) }
}
