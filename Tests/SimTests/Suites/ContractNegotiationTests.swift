import Foundation
import FootballSimCore

func runContractNegotiationTests() {
    suite("Contract negotiation") {
        test("a better player asks for more, and a replaceable one asks for the minimum") {
            let star = professional(overall: 85)
            let starter = professional(overall: 70)
            let fringe = professional(overall: ProRules.replacementRating - 5)
            let starPrice = ContractNegotiation.askingPrice(for: star, season: 0)
            let starterPrice = ContractNegotiation.askingPrice(for: starter, season: 0)
            let fringePrice = ContractNegotiation.askingPrice(for: fringe, season: 0)

            expect(annual(starPrice) > annual(starterPrice),
                   "an 85 overall asks no more than a 70")
            expectEqual(annual(fringePrice), ProRules.minimumSalary(seasonsAfterBase: 0),
                        "a player below replacement level asks for more than the minimum")
            expect(annual(starPrice) < ProRules.salaryCap(seasonsAfterBase: 0) / 10,
                   "one player asks for more than a tenth of the cap")
        }

        test("the price is a share of the cap, so a career does not make the market free") {
            // The defect this rules out: the cap compounds at 7% a season, so an asking price
            // written in fixed dollars is worth a quarter of itself twenty seasons in — and no
            // single-season test can see it, which is the same shape as the seed-from-hashValue bug.
            let player = professional(overall: 80)
            let early = ContractNegotiation.askingPrice(for: player, season: 0).totalValue
            let late = ContractNegotiation.askingPrice(for: player, season: 20).totalValue
            let earlyShare = early * ProRules.basisPointScale / ProRules.salaryCap(seasonsAfterBase: 0)
            let lateShare = late * ProRules.basisPointScale / ProRules.salaryCap(seasonsAfterBase: 20)

            expect(abs(earlyShare - lateShare) <= 1,
                   "the same player costs \(earlyShare) basis points of the cap in season zero and "
                       + "\(lateShare) in season twenty")
            expect(late > early * 3, "asking prices did not follow the cap upward at all")
        }

        test("age shortens the term rather than cutting the rate") {
            let young = professional(overall: 78, age: ProRules.youngPlayerAge - 1)
            let prime = professional(overall: 78, age: 27)
            let old = professional(overall: 78, age: 31)

            expectEqual(ContractNegotiation.requestedYears(for: young), ProRules.youngContractYears)
            expectEqual(ContractNegotiation.requestedYears(for: prime), ProRules.primeContractYears)
            expectEqual(ContractNegotiation.requestedYears(for: old), ProRules.decliningContractYears,
                        "a player past the decline age still wants a long deal")
            expectEqual(annual(ContractNegotiation.askingPrice(for: old, season: 0)),
                        annual(ContractNegotiation.askingPrice(for: prime, season: 0)),
                        "age cut the rate as well as the term, so a veteran is paid twice for it")
        }

        test("a player takes the better offer") {
            let player = professional(overall: 76)
            let asking = ContractNegotiation.askingPrice(for: player, season: 0)
            let modest = ContractOffer(teamID: club(1), contract: asking, prestige: Rating(60))
            let generous = ContractOffer(
                teamID: club(2),
                contract: raised(asking, byPercent: 25),
                prestige: Rating(60)
            )

            expectEqual(
                ContractNegotiation.choose(from: [modest, generous], player: player, season: 0)?.teamID,
                generous.teamID,
                "the player took the smaller deal from an identical club"
            )
        }

        test("standing is worth real money, but it cannot buy a discount") {
            let player = professional(overall: 76)
            let asking = ContractNegotiation.askingPrice(for: player, season: 0)
            let contender = ContractOffer(teamID: club(3), contract: asking, prestige: Rating(95))
            // Slightly more money at a club nobody has heard of.
            let strugglers = ContractOffer(
                teamID: club(4),
                contract: raised(asking, byPercent: 1),
                prestige: Rating(40)
            )
            expectEqual(
                ContractNegotiation.choose(from: [contender, strugglers], player: player, season: 0)?
                    .teamID,
                contender.teamID,
                "a club's standing was worth nothing against one percent more money"
            )

            // The other half of the rule: fame is not a discount. An offer under the asking price
            // is refused however big the club is, or the biggest club in the league would also be
            // permanently the cheapest.
            let cheapContender = ContractOffer(
                teamID: club(3),
                contract: raised(asking, byPercent: -20),
                prestige: Rating(99)
            )
            expect(!ContractNegotiation.meetsAskingPrice(cheapContender, player: player, season: 0),
                   "a famous club underpaid the asking price and was accepted")
            expect(ContractNegotiation.choose(from: [cheapContender], player: player, season: 0) == nil,
                   "a player signed for less than they were asking because the club was famous")
        }

        test("a short deal is worth less than its money says") {
            let player = professional(overall: 76, age: 24)
            let asking = ContractNegotiation.askingPrice(for: player, season: 0)
            let long = ContractOffer(teamID: club(5), contract: asking, prestige: Rating(60))
            let short = ContractOffer(
                teamID: club(6),
                contract: Contract(
                    years: 1,
                    baseSalaryByYear: [asking.totalValue],
                    signingBonus: 0,
                    signedSeason: 0
                ),
                prestige: Rating(60)
            )
            expect(ContractNegotiation.meetsAskingPrice(short, player: player, season: 0),
                   "an offer worth every dollar of the asking price was refused on money")
            expect(
                ContractNegotiation.value(of: short, to: player, season: 0)
                    < ContractNegotiation.value(of: long, to: player, season: 0),
                "the same money over one year was worth as much as over five"
            )
        }

        test("the same market resolves the same way in every process") {
            let player = professional(overall: 72)
            let asking = ContractNegotiation.askingPrice(for: player, season: 0)
            // Identical offers from four clubs: nothing separates them but identity, which is
            // exactly the case a hash-ordered or arrival-ordered resolution would get wrong.
            let offers = (1...4).map {
                ContractOffer(teamID: club($0), contract: asking, prestige: Rating(70))
            }
            let first = ContractNegotiation.choose(from: offers, player: player, season: 0)
            let reversed = ContractNegotiation.choose(
                from: Array(offers.reversed()),
                player: player,
                season: 0
            )
            expectEqual(first?.teamID, reversed?.teamID,
                        "the order the offers arrived in decided who signed the player")
            expectEqual(first?.teamID, offers.map(\.teamID).min { $0.uuidString < $1.uuidString },
                        "a tie did not break on identity")
        }

        test("nobody is signed for the league minimum any more") {
            // The gap `02` §4.2d records: signFreeAgent took whatever contract it was handed, so a
            // club could sign the best player in the pool for the floor and nothing objected.
            var state = GameState.bootstrap(seed: 60_140)
            guard let teamID = state.proTeams.ids.first,
                  let playerID = state.proTeams[teamID]?.rosterIDs.first else {
                expect(false, "a bootstrapped world has no professional to sign")
                return
            }
            state.proTeams.update(teamID) { $0.rosterIDs.removeAll { $0 == playerID } }
            // Uncontracted and off a roster is what `openOffseason` reads as a free agent. The
            // ratings are forced rather than taken as generated, so the fixture is a player with a
            // price at every seed instead of only at most of them.
            state.players.update(playerID) { player in
                player.contract = nil
                for attribute in player.position.ratedAttributes {
                    player.attributes[attribute] = Rating(80)
                }
            }
            do {
                state = try ProMarketSystem.openOffseason(in: state)
            } catch {
                expect(false, "the offseason would not open: \(error)")
                return
            }
            guard let player = state.players[playerID],
                  state.proMarket.freeAgentIDs.contains(playerID) else {
                expect(false, "the fixture professional never reached the free-agent pool")
                return
            }
            let before = state
            let minimum = Contract(
                years: 1,
                baseSalaryByYear: [ProRules.minimumSalary(seasonsAfterBase: 0)],
                signingBonus: 0
            )
            do {
                _ = try ProMarketSystem.signFreeAgent(
                    playerID: playerID,
                    teamID: teamID,
                    contract: minimum,
                    in: state
                )
                expect(false, "a starter signed for the league minimum")
            } catch ProMarketError.belowAskingPrice(let asked, let offered) {
                expect(asked > offered, "the refusal reported an asking price at or below the offer")
                expectEqual(
                    asked,
                    ContractNegotiation.askingPrice(for: player, season: state.proMarket.season)
                        .totalValue,
                    "the refusal quoted a price the player is not actually asking for"
                )
                expectEqual(state, before, "a refused signing still moved the world")
            } catch {
                expect(false, "the wrong error came back: \(error)")
            }

            // And the same signing at the asking price goes through.
            do {
                let signed = try ProMarketSystem.signFreeAgent(
                    playerID: playerID,
                    teamID: teamID,
                    contract: ContractNegotiation.askingPrice(
                        for: player,
                        season: state.proMarket.season
                    ),
                    in: state
                )
                expect(signed.proTeams[teamID]?.rosterIDs.contains(playerID) == true,
                       "an offer at the asking price was refused")
                expect(WorldIntegrity.check(signed).isValid)
            } catch {
                expect(false, "an offer at the asking price was refused: \(error)")
            }
        }
    }
}

// MARK: - Fixtures

/// A professional whose `overall` is exactly what the test asked for, so a price can be reasoned
/// about rather than measured.
private func professional(overall: Int, age: Int = 27, position: Position = .wideReceiver) -> Player {
    var attributes = Attributes()
    for attribute in position.ratedAttributes {
        attributes[attribute] = Rating(overall)
    }
    return Player(
        id: UUID(uuidString: String(format: "00000000-0000-4000-B200-%012X", overall * 100 + age))!,
        firstName: "Fixture",
        lastName: "Professional",
        position: position,
        age: age,
        attributes: attributes,
        potential: Rating(overall)
    )
}

private func club(_ index: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-4000-B300-%012X", index))!
}

private func annual(_ contract: Contract) -> Int {
    contract.baseSalaryByYear.first ?? 0
}

/// The same deal for more, or for less, keeping its shape.
private func raised(_ contract: Contract, byPercent percent: Int) -> Contract {
    Contract(
        years: contract.years,
        baseSalaryByYear: contract.baseSalaryByYear.map { $0 + $0 * percent / 100 },
        signingBonus: contract.signingBonus + contract.signingBonus * percent / 100,
        signedSeason: contract.signedSeason
    )
}
