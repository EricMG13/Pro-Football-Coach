import Foundation
import FootballSimCore

func runModelTests() {
    suite("Position & LeagueRules") {
        test("overall weights sum to one for every position") {
            for position in Position.allCases {
                let sum = LeagueRules.overallWeights(for: position).values.reduce(0, +)
                expectClose(sum, 1.0, 0.0001, "\(position.abbreviation) weights")
            }
        }

        test("overall weights only reference the position's own attributes") {
            for position in Position.allCases {
                let weighted = Set(LeagueRules.overallWeights(for: position).keys)
                let owned = Set(position.attributes)
                expect(weighted.isSubset(of: owned), "\(position.abbreviation) weights a foreign attribute")
            }
        }

        test("every position attribute carries weight") {
            for position in Position.allCases {
                let weighted = Set(LeagueRules.overallWeights(for: position).keys)
                let owned = Set(position.attributes)
                expect(owned.isSubset(of: weighted), "\(position.abbreviation) has an unweighted attribute")
            }
        }

        test("roster targets sum to the active roster size") {
            let total = Position.allCases.map(\.rosterTarget).reduce(0, +)
            expectEqual(total, LeagueRules.activeRosterSize)
        }

        test("minimums never exceed targets") {
            for position in Position.allCases {
                expect(
                    position.minimumRosterCount <= position.rosterTarget,
                    "\(position.abbreviation) minimum above target"
                )
                expect(
                    position.starterCount <= position.rosterTarget,
                    "\(position.abbreviation) starts more players than it rosters"
                )
            }
        }

        test("offense and defense partition the non-specialists") {
            for position in Position.allCases {
                let flags = [position.isOffense, position.isDefense, position.isSpecialist]
                expectEqual(flags.filter { $0 }.count, 1, "\(position.abbreviation) side-of-ball flags")
            }
        }

        test("display order covers every position exactly once") {
            expectEqual(Set(Position.displayOrder).count, Position.allCases.count)
        }

        test("specialists skip the athletic core") {
            expect(!Position.k.attributes.contains(.speed), "kickers should not be rated on speed")
            expect(!Position.p.attributes.contains(.strength), "punters should not be rated on strength")
        }
    }

    suite("Ratings") {
        test("uniform ratings produce that exact overall") {
            for position in Position.allCases {
                var values: [Attribute: Int] = [:]
                for attribute in position.attributes { values[attribute] = 80 }
                expectEqual(
                    Ratings(values: values).overall(for: position),
                    80,
                    "\(position.abbreviation) uniform overall"
                )
            }
        }

        test("ratings clamp into the legal band") {
            let ratings = Ratings(values: [.speed: 250, .strength: -40])
            expectEqual(ratings[.speed], LeagueRules.ratingCeiling)
            expectEqual(ratings[.strength], LeagueRules.ratingFloor)
        }

        test("missing attributes read as the floor") {
            expectEqual(Ratings(values: [:])[.coverage], LeagueRules.ratingFloor)
        }

        test("raising a weighted attribute raises the overall") {
            var values: [Attribute: Int] = [:]
            for attribute in Position.qb.attributes { values[attribute] = 70 }
            var ratings = Ratings(values: values)
            let before = ratings.overall(for: .qb)
            ratings[.throwAccuracy] = 95
            expect(ratings.overall(for: .qb) > before, "throw accuracy must move a QB's overall")
        }

        test("adjustAll shifts and clamps") {
            var ratings = Ratings(values: [.speed: 95, .strength: 50])
            ratings.adjustAll(by: 10)
            expectEqual(ratings[.speed], LeagueRules.ratingCeiling)
            expectEqual(ratings[.strength], 60)
        }
    }

    suite("Contract") {
        test("cap hit is salary plus proration") {
            let contract = Contract(
                years: 4,
                salaryPerYear: [8_000_000, 8_000_000, 8_000_000, 8_000_000],
                signingBonus: 8_000_000,
                guaranteedYears: 2,
                yearsElapsed: 1
            )
            expectEqual(contract.capHit(inYear: 0), 10_000_000)
            expectEqual(contract.currentCapHit, 10_000_000)
        }

        test("dead money accelerates proration and guarantees") {
            let contract = Contract(
                years: 4,
                salaryPerYear: [8_000_000, 8_000_000, 8_000_000, 8_000_000],
                signingBonus: 8_000_000,
                guaranteedYears: 2,
                yearsElapsed: 1
            )
            // 3 remaining proration years at 2M, plus 1 remaining guaranteed year at 8M.
            expectEqual(contract.deadMoneyIfCutNow(), 14_000_000)
            expectEqual(contract.capSavingsIfCutNow(), -4_000_000)
        }

        test("proration parts sum to the whole bonus") {
            let contract = Contract(
                years: 3,
                salaryPerYear: [1_000_000, 1_000_000, 1_000_000],
                signingBonus: 10_000_000
            )
            let parts = (0..<3).map { contract.bonusProration(inYear: $0) }.reduce(0, +)
            expectEqual(parts, 10_000_000, "indivisible bonus must not leak dollars")
        }

        test("proration caps at five years on a long deal") {
            let contract = Contract(
                years: 5,
                salaryPerYear: Array(repeating: 5_000_000, count: 5),
                signingBonus: 25_000_000
            )
            expectEqual(contract.bonusProrationPerYear, 5_000_000)
        }

        test("cutting an expired contract costs nothing") {
            var contract = Contract.flat(years: 2, salary: 3_000_000)
            contract.yearsElapsed = 2
            expectEqual(contract.deadMoneyIfCutNow(), 0)
            expect(contract.isExpired)
        }

        test("fully guaranteed deal returns no savings when cut") {
            let contract = Contract(
                years: 3,
                salaryPerYear: [10_000_000, 10_000_000, 10_000_000],
                signingBonus: 0,
                guaranteedYears: 3
            )
            expectEqual(contract.deadMoneyIfCutNow(), 30_000_000)
        }

        test("totals and averages") {
            let contract = Contract(
                years: 2,
                salaryPerYear: [4_000_000, 6_000_000],
                signingBonus: 2_000_000
            )
            expectEqual(contract.totalValue, 12_000_000)
            expectEqual(contract.averagePerYear, 6_000_000)
        }

        test("aging advances the deal toward expiry") {
            let contract = Contract.flat(years: 2, salary: 1_000_000)
            expectEqual(contract.yearsRemaining, 2)
            expect(!contract.isExpiring)
            let aged = contract.aged()
            expectEqual(aged.yearsRemaining, 1)
            expect(aged.isExpiring)
            expect(aged.aged().isExpired)
        }

        test("dead money survives a deal past its guarantee") {
            // Three years played, only one guaranteed: the naive range here is 3..<1, which
            // traps at runtime. This crashed the whole app before it was fixed.
            var contract = Contract(
                years: 4,
                salaryPerYear: [5_000_000, 5_000_000, 5_000_000, 5_000_000],
                signingBonus: 4_000_000,
                guaranteedYears: 1
            )
            contract.yearsElapsed = 3
            expectEqual(contract.deadMoneyIfCutNow(), 1_000_000, "only the final proration year remains")

            var noBonus = Contract.flat(years: 3, salary: 2_000_000, guaranteedYears: 1)
            noBonus.yearsElapsed = 2
            expectEqual(noBonus.deadMoneyIfCutNow(), 0)
        }

        test("out-of-range years contribute nothing") {
            let contract = Contract.flat(years: 2, salary: 1_000_000)
            expectEqual(contract.capHit(inYear: 5), 0)
            expectEqual(contract.capHit(inYear: -1), 0)
        }
    }

    suite("Player") {
        test("potential ordering puts A+ on top") {
            expect(PotentialGrade.aPlus > PotentialGrade.f)
            expectEqual(PotentialGrade.allCases.max(), .aPlus)
            expect(
                PotentialGrade.aPlus.developmentMultiplier > PotentialGrade.c.developmentMultiplier
            )
        }

        test("morale colours the effective overall without deciding games") {
            var player = TestFixtures.player(position: .wr, rating: 80, morale: 70)
            expectEqual(player.overall, 80)
            player.morale = 95
            expectEqual(player.effectiveOverall, 83)
            player.morale = 10
            expectEqual(player.effectiveOverall, 77)
        }

        test("health and free agency flags") {
            var player = TestFixtures.player(position: .rb, rating: 70)
            expect(player.isHealthy)
            expect(player.isFreeAgent)
            player.injuryWeeksRemaining = 3
            player.contract = .flat(years: 2, salary: 2_000_000)
            expect(!player.isHealthy)
            expect(!player.isFreeAgent)
        }

        test("projected ceiling reflects grade") {
            let high = TestFixtures.player(position: .qb, rating: 70, potential: .aPlus)
            let low = TestFixtures.player(position: .qb, rating: 70, potential: .f)
            expect(high.projectedCeiling > low.projectedCeiling)
            expectEqual(low.projectedCeiling, 72)
        }

        test("draft origin labels read correctly") {
            expectEqual(DraftOrigin(year: 2026, round: 1, pickInRound: 12).label, "R1 P12 2026")
            expect(DraftOrigin(year: 2026, round: 0, pickInRound: 0).isUndrafted)
        }
    }
}
