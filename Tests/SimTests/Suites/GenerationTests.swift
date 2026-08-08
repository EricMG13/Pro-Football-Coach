import Foundation
import FootballSimCore

func runGenerationTests() {
    suite("PlayerFactory") {
        test("generated overall lands on target") {
            var rng = SeededRandom(seed: 3)
            for position in Position.allCases {
                for target in [55, 70, 85] {
                    let player = PlayerFactory.make(
                        position: position,
                        age: 26,
                        targetOverall: target,
                        rng: &rng
                    )
                    expectClose(
                        Double(player.overall),
                        Double(target),
                        2,
                        "\(position.abbreviation) target \(target)"
                    )
                }
            }
        }

        test("ratings stay inside the legal band") {
            var rng = SeededRandom(seed: 4)
            var ok = true
            for _ in 0..<400 {
                let player = PlayerFactory.make(
                    position: .wr,
                    age: 24,
                    targetOverall: 97,
                    rng: &rng
                )
                for attribute in player.position.attributes
                where !LeagueRules.ratingRange.contains(player.ratings[attribute]) { ok = false }
            }
            expect(ok, "an attribute escaped 40...99")
        }

        test("only the position's attributes are rated") {
            var rng = SeededRandom(seed: 5)
            let kicker = PlayerFactory.make(position: .k, age: 27, targetOverall: 75, rng: &rng)
            expectEqual(kicker.ratings.values.count, Position.k.attributes.count)
        }

        test("generation is deterministic for a seed") {
            var a = SeededRandom(seed: 5), b = SeededRandom(seed: 5)
            let first = PlayerFactory.make(position: .qb, age: 24, targetOverall: 75, rng: &a)
            let second = PlayerFactory.make(position: .qb, age: 24, targetOverall: 75, rng: &b)
            expectEqual(first.name, second.name)
            expectEqual(first.ratings, second.ratings)
            expectEqual(first.overall, second.overall)
        }

        test("craft attributes outrank incidental ones on average") {
            var rng = SeededRandom(seed: 6)
            var accuracy = 0, strength = 0
            for _ in 0..<300 {
                let qb = PlayerFactory.make(position: .qb, age: 26, targetOverall: 75, rng: &rng)
                accuracy += qb.ratings[.throwAccuracy]
                strength += qb.ratings[.strength]
            }
            expect(accuracy > strength, "quarterbacks should skew toward accuracy over strength")
        }

        test("young players draw better potential than old ones") {
            var rng = SeededRandom(seed: 7)
            func averageCeiling(age: Int) -> Double {
                var total = 0
                for _ in 0..<300 {
                    total += PlayerFactory.make(
                        position: .wr, age: age, targetOverall: 70, rng: &rng
                    ).potential.ceilingBonus
                }
                return Double(total) / 300
            }
            expect(averageCeiling(age: 22) > averageCeiling(age: 33), "youth should carry more upside")
        }

        test("traits are rare and never contradictory") {
            var rng = SeededRandom(seed: 8)
            var withTraits = 0
            var contradictions = 0
            let sample = 2_000
            for _ in 0..<sample {
                let player = PlayerFactory.make(position: .lb, age: 26, targetOverall: 70, rng: &rng)
                if !player.traits.isEmpty { withTraits += 1 }
                if player.has(.ironMan) && player.has(.injuryProne) { contradictions += 1 }
                if player.has(.loyal) && player.has(.mercenary) { contradictions += 1 }
                if player.traits.count > 2 { contradictions += 1 }
            }
            expectClose(Double(withTraits) / Double(sample), 0.25, 0.05, "trait frequency")
            expectEqual(contradictions, 0, "contradictory traits appeared")
        }
    }

    suite("ContractPricer") {
        test("better players cost more") {
            let star = ContractPricer.marketSalary(overall: 90, age: 26, position: .wr)
            let starter = ContractPricer.marketSalary(overall: 75, age: 26, position: .wr)
            let fringe = ContractPricer.marketSalary(overall: 62, age: 26, position: .wr)
            expect(star > starter, "star must cost more than starter")
            expect(starter > fringe, "starter must cost more than fringe")
        }

        test("quarterbacks carry the position premium") {
            let qb = ContractPricer.marketSalary(overall: 85, age: 27, position: .qb)
            let kicker = ContractPricer.marketSalary(overall: 85, age: 27, position: .k)
            expect(qb > kicker * 4, "QB premium should dwarf a kicker's")
        }

        test("age past peak discounts the price") {
            let prime = ContractPricer.marketSalary(overall: 84, age: 26, position: .rb)
            let old = ContractPricer.marketSalary(overall: 84, age: 33, position: .rb)
            expect(old < prime, "a 33-year-old back should cost less than a 26-year-old")
        }

        test("nobody signs below the league minimum") {
            let value = ContractPricer.marketSalary(overall: 40, age: 30, position: .p)
            expect(value >= LeagueRules.minimumSalaryVeteran, "veteran minimum floor")
        }

        test("loyal players take a discount, mercenaries a premium") {
            let loyal = TestFixtures.player(position: .wr, rating: 80, traits: [.loyal])
            let mercenary = TestFixtures.player(position: .wr, rating: 80, traits: [.mercenary])
            let loyalAsk = ContractPricer.askingSalary(for: loyal, teamReputation: 50)
            let mercenaryAsk = ContractPricer.askingSalary(for: mercenary, teamReputation: 50)
            expect(loyalAsk < mercenaryAsk, "loyalty should be cheaper than mercenary")
        }

        test("rookie scale falls from first pick to last") {
            let first = ContractPricer.rookieContract(round: 1, pickInRound: 1)
            let mid = ContractPricer.rookieContract(round: 3, pickInRound: 16)
            let last = ContractPricer.rookieContract(round: 7, pickInRound: 32)
            expect(first.totalValue > mid.totalValue, "R1P1 above R3")
            expect(mid.totalValue > last.totalValue, "R3 above R7")
            expectEqual(first.years, 4)
            expect(first.isRookieDeal)
            expect(last.salaryPerYear.allSatisfy { $0 >= LeagueRules.minimumSalaryYoung })
        }

        test("market contracts keep their structure consistent") {
            var rng = SeededRandom(seed: 9)
            for _ in 0..<200 {
                let player = PlayerFactory.make(
                    position: .dl, age: 27, targetOverall: 82, rng: &rng
                )
                let contract = ContractPricer.marketContract(for: player, rng: &rng)
                expectEqual(contract.salaryPerYear.count, contract.years)
                expect(contract.years >= 1 && contract.years <= LeagueRules.maxContractYears)
                expect(contract.signingBonus >= 0)
                expect(contract.guaranteedYears <= contract.years)
            }
        }
    }

    suite("LeagueFactory") {
        let league = LeagueFactory.makeDefaultLeague(seed: 11, userTeamIndex: 0, coach: .stub())

        test("league has the right shape") {
            expectEqual(league.teams.count, LeagueRules.teamCount)
            for conference in Conference.allCases {
                expectEqual(
                    league.teams(in: conference).count,
                    LeagueRules.teamCount / 2,
                    "\(conference) size"
                )
                for division in Division.allCases {
                    expectEqual(
                        league.teams(in: conference, division: division).count,
                        LeagueRules.teamsPerDivision,
                        "\(conference)/\(division) size"
                    )
                }
            }
        }

        test("abbreviations and identities are unique") {
            expectEqual(Set(league.teams.map(\.abbreviation)).count, LeagueRules.teamCount)
            expectEqual(Set(league.teams.map(\.id)).count, LeagueRules.teamCount)
            expectEqual(Set(league.teams.map(\.fullName)).count, LeagueRules.teamCount)
        }

        test("every roster is full and legal") {
            for team in league.teams {
                expectEqual(
                    team.activeRoster.count,
                    LeagueRules.activeRosterSize,
                    "\(team.abbreviation) active roster"
                )
                expectEqual(
                    team.practiceSquad.count,
                    LeagueRules.practiceSquadSize,
                    "\(team.abbreviation) practice squad"
                )
                for position in Position.allCases {
                    let count = team.activeRoster.filter { $0.position == position }.count
                    expect(
                        count >= position.minimumRosterCount,
                        "\(team.abbreviation) short at \(position.abbreviation): \(count)"
                    )
                }
                expect(
                    team.roster.allSatisfy { $0.contract != nil },
                    "\(team.abbreviation) has an unsigned player"
                )
            }
        }

        test("player identities are unique across the league") {
            let ids = league.teams.flatMap { $0.roster.map(\.id) }
            expectEqual(Set(ids).count, ids.count, "duplicate player id")
        }

        test("team ratings spread across a believable band") {
            let ratings = league.teams.map(\.overallRating)
            let best = ratings.max() ?? 0
            let worst = ratings.min() ?? 0
            expectIn(worst, 50...75, "worst team rating")
            expectIn(best, 75...95, "best team rating")
            expect(best - worst > 8, "league should not be flat: spread \(best - worst)")
        }

        test("every team carries a full coordinator staff") {
            for team in league.teams {
                expectEqual(team.staff.count, StaffRole.allCases.count, "\(team.abbreviation) staff")
                for role in StaffRole.allCases {
                    expect(team.staff(role) != nil, "\(team.abbreviation) missing \(role.abbreviation)")
                }
            }
        }

        test("depth charts cover every rostered position") {
            for team in league.teams {
                for position in Position.allCases {
                    let starters = team.starters(at: position)
                    expectEqual(
                        starters.count,
                        position.starterCount,
                        "\(team.abbreviation) \(position.abbreviation) starters"
                    )
                }
            }
        }

        test("contracts expire on a stagger") {
            let expiring = league.teams.flatMap(\.activeRoster)
                .filter { $0.contract?.isExpiring ?? false }
                .count
            let total = league.teams.flatMap(\.activeRoster).count
            let share = Double(expiring) / Double(total)
            expectIn(share, 0.15...0.55, "share of expiring contracts")
        }

        test("teams start close to cap-legal") {
            var overCap = 0
            for team in league.teams where CapEngine.capSpace(for: team, in: league) < 0 {
                overCap += 1
            }
            expect(
                overCap <= LeagueRules.teamCount / 4,
                "\(overCap) of 32 teams generated over the cap"
            )
        }

        test("generation is fully deterministic") {
            let encoder = JSONEncoder.stable()
            let first = LeagueFactory.makeDefaultLeague(seed: 2, userTeamIndex: 3, coach: .stub())
            let second = LeagueFactory.makeDefaultLeague(seed: 2, userTeamIndex: 3, coach: .stub())
            let firstData = try encoder.encode(first)
            let secondData = try encoder.encode(second)
            expect(firstData == secondData, "same seed produced different leagues")
        }

        test("different seeds produce different leagues") {
            let other = LeagueFactory.makeDefaultLeague(seed: 99, userTeamIndex: 0, coach: .stub())
            expect(
                other.teams[0].roster[0].name != league.teams[0].roster[0].name,
                "seeds should diverge"
            )
        }

        test("save round trips byte for byte") {
            let encoder = JSONEncoder.stable()
            let original = try encoder.encode(league)
            let decoded = try JSONDecoder.stable().decode(League.self, from: original)
            let reencoded = try encoder.encode(decoded)
            expect(original == reencoded, "league did not survive a save/load round trip")
        }

        test("user team is the requested one") {
            let picked = LeagueFactory.makeDefaultLeague(seed: 12, userTeamIndex: 7, coach: .stub())
            expectEqual(picked.userTeam?.id, picked.teams[7].id)
        }
    }
}
