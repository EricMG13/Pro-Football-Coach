import Foundation
import FootballSimCore

func runFrontOfficeTests() {
    suite("CapEngine") {
        test("cap spent counts contracts and dead money") {
            var league = LeagueFactory.makeDefaultLeague(seed: 61, userTeamIndex: 0, coach: .stub())
            let team = league.teams[0]
            let before = CapEngine.capSpent(for: team)
            expect(before > 0, "a full roster should cost something")

            league.deadMoney[team.id] = 5_000_000
            expectEqual(
                CapEngine.capSpent(for: team, deadMoney: 5_000_000),
                before + 5_000_000
            )
        }

        test("cutting a player creates dead money and frees the roster spot") {
            var league = LeagueFactory.makeDefaultLeague(seed: 62, userTeamIndex: 0, coach: .stub())
            let team = league.teams[0]
            guard let victim = team.activeRoster.first(where: { ($0.contract?.signingBonus ?? 0) > 0 })
            else { return expect(false, "no player with a signing bonus to cut") }

            let expectedDead = victim.contract!.deadMoneyIfCutNow()
            let rosterBefore = team.roster.count
            let dead = CapEngine.cut(playerID: victim.id, from: team.id, in: &league)

            expectEqual(dead, expectedDead, "dead money returned")
            expectEqual(league.deadMoney[team.id], expectedDead, "dead money recorded")
            expectEqual(league.team(id: team.id)!.roster.count, rosterBefore - 1)
            expect(
                league.freeAgents.contains { $0.id == victim.id },
                "a cut player should hit free agency"
            )
            expect(
                league.freeAgents.first { $0.id == victim.id }?.contract == nil,
                "a cut player should have no contract"
            )
        }

        test("signing respects the cap and the roster limit") {
            var league = LeagueFactory.makeDefaultLeague(seed: 63, userTeamIndex: 0, coach: .stub())
            let teamID = league.teams[0].id
            guard let target = league.freeAgents.first else { return expect(false, "no free agents") }

            // A contract nobody can afford must be refused.
            let absurd = Contract.flat(years: 1, salary: 900_000_000)
            expect(
                !CapEngine.sign(playerID: target.id, to: teamID, contract: absurd, in: &league),
                "an unaffordable contract was accepted"
            )

            // Room has to exist on the roster too.
            CapEngine.cut(playerID: league.team(id: teamID)!.activeRoster[0].id, from: teamID, in: &league)
            let affordable = ContractPricer.minimumContract(age: target.age)
            expect(
                CapEngine.sign(playerID: target.id, to: teamID, contract: affordable, in: &league),
                "an affordable signing was refused"
            )
        }

        test("contract rollover expires deals into free agency") {
            var league = LeagueFactory.makeDefaultLeague(seed: 64, userTeamIndex: 0, coach: .stub())
            let expiringBefore = league.teams.flatMap(\.roster)
                .filter { $0.contract?.isExpiring ?? false }.count
            let freeAgentsBefore = league.freeAgents.count

            CapEngine.rolloverContracts(in: &league)

            expect(
                league.freeAgents.count > freeAgentsBefore,
                "nobody reached free agency despite \(expiringBefore) expiring deals"
            )
            expect(league.deadMoney.isEmpty, "dead money should clear at the league year")
            expect(
                league.teams.flatMap(\.roster).allSatisfy { !($0.contract?.isExpired ?? true) },
                "an expired contract survived the rollover"
            )
        }

        test("cap compliance sheds salary until a team is legal") {
            var league = LeagueFactory.makeDefaultLeague(seed: 65, userTeamIndex: 0, coach: .stub())
            league.salaryCap = 60_000_000
            let teamID = league.teams[0].id
            CapEngine.enforceCapCompliance(teamID: teamID, in: &league)
            let team = league.team(id: teamID)!
            // Compliance never breaks the positional floors, even under a brutal cap.
            for position in Position.allCases {
                expect(
                    team.activeRoster.filter { $0.position == position }.count
                        >= position.minimumRosterCount,
                    "\(position.abbreviation) fell below the minimum during cap compliance"
                )
            }
        }
    }

    suite("Free agency") {
        test("positional need reflects the roster") {
            var league = LeagueFactory.makeDefaultLeague(seed: 66, userTeamIndex: 0, coach: .stub())
            var team = league.teams[0]
            let before = FreeAgencyEngine.positionalNeed(for: .qb, on: team)

            // Strip the quarterbacks; need must spike.
            team.roster.removeAll { $0.position == .qb }
            let after = FreeAgencyEngine.positionalNeed(for: .qb, on: team)
            expect(after > before, "losing every quarterback should raise the need")
            expectEqual(after, 1.0, "an empty position is a maximum need")
            league.update(team)
        }

        test("players prefer money, but not only money") {
            var league = LeagueFactory.makeDefaultLeague(seed: 67, userTeamIndex: 0, coach: .stub())
            let player = TestFixtures.player(position: .wr, rating: 80)
            let team = league.teams[0]
            let ask = ContractPricer.askingSalary(for: player, teamReputation: team.reputation)

            let lowball = FreeAgencyEngine.Offer(
                teamID: team.id, contract: .flat(years: 2, salary: ask / 3)
            )
            let fair = FreeAgencyEngine.Offer(
                teamID: team.id, contract: .flat(years: 3, salary: ask)
            )
            let lowInterest = FreeAgencyEngine.interest(player: player, offer: lowball, team: team, league: league)
            let fairInterest = FreeAgencyEngine.interest(player: player, offer: fair, team: team, league: league)
            expect(fairInterest > lowInterest, "a fair offer should beat a lowball")
            expect(lowInterest < 0.45, "a lowball should not be accepted")
            league.freeAgents.append(player)
        }

        test("a wave signs players without breaking any cap") {
            var league = LeagueFactory.makeDefaultLeague(seed: 68, userTeamIndex: 0, coach: .stub())
            CapEngine.rolloverContracts(in: &league)
            let freeAgentsBefore = league.freeAgents.count
            FreeAgencyEngine.runWave(&league, wave: 0)

            expect(league.freeAgents.count < freeAgentsBefore, "nobody signed anywhere")
            for team in league.teams {
                expect(
                    CapEngine.capSpace(for: team, in: league) >= 0,
                    "\(team.abbreviation) went over the cap in free agency"
                )
                expect(
                    team.activeRoster.count <= LeagueRules.activeRosterSize,
                    "\(team.abbreviation) exceeded the roster limit"
                )
            }
        }
    }

    suite("Trades") {
        test("value rises with quality and falls with age") {
            let star = TestFixtures.player(position: .wr, rating: 90, age: 25)
            let starter = TestFixtures.player(position: .wr, rating: 76, age: 25)
            let veteran = TestFixtures.player(position: .wr, rating: 90, age: 34)
            expect(TradeEngine.value(of: star) > TradeEngine.value(of: starter), "quality")
            expect(TradeEngine.value(of: star) > TradeEngine.value(of: veteran), "age")
        }

        test("cheap contracts are worth more than expensive ones") {
            var player = TestFixtures.player(position: .dl, rating: 82, age: 26)
            let market = ContractPricer.marketSalary(for: player)
            player.contract = .flat(years: 3, salary: market / 3)
            let bargain = TradeEngine.value(of: player)
            player.contract = .flat(years: 3, salary: market * 3)
            let albatross = TradeEngine.value(of: player)
            expect(bargain > albatross, "a bargain deal should carry more trade value")
        }

        test("early picks are worth more, and future picks are discounted") {
            let teamID = UUID()
            let first = DraftPick(year: 2026, round: 1, originalTeamID: teamID, ownerTeamID: teamID)
            let fifth = DraftPick(year: 2026, round: 5, originalTeamID: teamID, ownerTeamID: teamID)
            let future = DraftPick(year: 2028, round: 1, originalTeamID: teamID, ownerTeamID: teamID)
            expect(
                TradeEngine.value(of: first, currentYear: 2026) > TradeEngine.value(of: fifth, currentYear: 2026),
                "round value"
            )
            expect(
                TradeEngine.value(of: first, currentYear: 2026) > TradeEngine.value(of: future, currentYear: 2026),
                "future discount"
            )
        }

        test("lopsided offers are rejected and fair ones accepted") {
            var league = LeagueFactory.makeDefaultLeague(seed: 69, userTeamIndex: 0, coach: .stub())
            league.phase = .regularSeason(week: 3)
            let picks = TradeEngine.makePicks(for: league)
            let mine = league.teams[0]
            let theirs = league.teams[1]

            let theirStar = theirs.activeRoster.max { $0.overall < $1.overall }!
            let myScrub = mine.activeRoster.min { $0.overall < $1.overall }!

            let robbery = TradeProposal(
                fromTeamID: mine.id,
                toTeamID: theirs.id,
                sending: TradePackage(playerIDs: [myScrub.id]),
                receiving: TradePackage(playerIDs: [theirStar.id])
            )
            expect(!TradeEngine.evaluate(robbery, league: league, picks: picks).isAccepted, "robbery accepted")

            // A genuine overpay should get done.
            let myBest = mine.activeRoster
                .filter { $0.position == theirStar.position }
                .max { $0.overall < $1.overall }!
            let myPicks = picks.filter { $0.ownerTeamID == mine.id && $0.round <= 2 }.prefix(3)
            let overpay = TradeProposal(
                fromTeamID: mine.id,
                toTeamID: theirs.id,
                sending: TradePackage(playerIDs: [myBest.id], pickIDs: myPicks.map(\.id)),
                receiving: TradePackage(playerIDs: [theirStar.id])
            )
            let verdict = TradeEngine.evaluate(overpay, league: league, picks: picks)
            expect(verdict.isAccepted, "a heavy overpay was still rejected: \(verdict)")
        }

        test("trades are blocked after the deadline and during the playoffs") {
            var league = LeagueFactory.makeDefaultLeague(seed: 70, userTeamIndex: 0, coach: .stub())
            let picks = TradeEngine.makePicks(for: league)
            let proposal = TradeProposal(
                fromTeamID: league.teams[0].id,
                toTeamID: league.teams[1].id,
                sending: TradePackage(playerIDs: [league.teams[0].activeRoster[0].id]),
                receiving: TradePackage(playerIDs: [league.teams[1].activeRoster[0].id])
            )
            league.phase = .regularSeason(week: LeagueRules.tradeDeadlineWeek + 1)
            expect(!TradeEngine.evaluate(proposal, league: league, picks: picks).isAccepted, "post-deadline")
            league.phase = .playoffs(round: 0)
            expect(!TradeEngine.evaluate(proposal, league: league, picks: picks).isAccepted, "playoffs")
        }

        test("executing a trade moves players and picks both ways") {
            var league = LeagueFactory.makeDefaultLeague(seed: 71, userTeamIndex: 0, coach: .stub())
            var picks = TradeEngine.makePicks(for: league)
            let mine = league.teams[0]
            let theirs = league.teams[1]
            let myPlayer = mine.activeRoster[5]
            let theirPlayer = theirs.activeRoster[5]
            let myPick = picks.first { $0.ownerTeamID == mine.id && $0.round == 3 }!

            let proposal = TradeProposal(
                fromTeamID: mine.id,
                toTeamID: theirs.id,
                sending: TradePackage(playerIDs: [myPlayer.id], pickIDs: [myPick.id]),
                receiving: TradePackage(playerIDs: [theirPlayer.id])
            )
            expect(TradeEngine.execute(proposal, league: &league, picks: &picks), "execution failed")

            expect(league.team(id: theirs.id)!.player(id: myPlayer.id) != nil, "player did not arrive")
            expect(league.team(id: mine.id)!.player(id: myPlayer.id) == nil, "player did not leave")
            expect(league.team(id: mine.id)!.player(id: theirPlayer.id) != nil, "return player missing")
            expectEqual(
                picks.first { $0.id == myPick.id }?.ownerTeamID,
                theirs.id,
                "pick ownership did not change"
            )
        }
    }

    suite("Draft and scouting") {
        test("a class has the right size and a believable talent curve") {
            var rng = SeededRandom(seed: 72)
            let prospects = DraftClassFactory.makeClass(year: 2027, rng: &rng)
            expectEqual(
                prospects.count,
                LeagueRules.draftPickCount + LeagueRules.undraftedPoolSize
            )
            let firstRound = prospects.filter { $0.projectedRound == 1 }
            let sixthRound = prospects.filter { $0.projectedRound == 6 }
            let firstAverage = Double(firstRound.reduce(0) { $0 + $1.trueOverall }) / Double(firstRound.count)
            let sixthAverage = Double(sixthRound.reduce(0) { $0 + $1.trueOverall }) / Double(sixthRound.count)
            expect(firstAverage > sixthAverage + 5, "talent should fall through the rounds")
            expect(prospects.allSatisfy { $0.player.age <= 23 }, "prospects should be young")
        }

        test("classes contain steals worth finding") {
            var rng = SeededRandom(seed: 73)
            let prospects = DraftClassFactory.makeClass(year: 2027, rng: &rng)
            let sleepers = ScoutingEngine.sleepers(in: prospects)
            expect(!sleepers.isEmpty, "a class with no late-round talent gives scouting nothing to do")
        }

        test("scouting narrows the range and costs points") {
            var rng = SeededRandom(seed: 74)
            var prospects = DraftClassFactory.makeClass(year: 2027, rng: &rng)
            var points = 120
            let target = prospects[0]
            let spreadBefore = target.scoutedHigh - target.scoutedLow

            ScoutingEngine.scout(
                prospectID: target.id, action: .narrow,
                in: &prospects, pointsRemaining: &points, coach: .stub()
            )
            let updated = prospects.first { $0.id == target.id }!
            expect(updated.scoutedHigh - updated.scoutedLow < spreadBefore, "range did not narrow")
            expectEqual(points, 120 - ScoutingEngine.Action.narrow.cost)

            ScoutingEngine.scout(
                prospectID: target.id, action: .fullReport,
                in: &prospects, pointsRemaining: &points, coach: .stub()
            )
            let full = prospects.first { $0.id == target.id }!
            expect(full.fullyScouted && full.potentialRevealed, "full report did not reveal everything")
            expectEqual(full.scoutedLow, full.trueOverall)
        }

        test("scouting cannot spend points it does not have") {
            var rng = SeededRandom(seed: 75)
            var prospects = DraftClassFactory.makeClass(year: 2027, rng: &rng)
            var points = 5
            let spent = ScoutingEngine.scout(
                prospectID: prospects[0].id, action: .fullReport,
                in: &prospects, pointsRemaining: &points, coach: .stub()
            )
            expectEqual(spent, 0, "scouting happened without the points to pay for it")
            expectEqual(points, 5)
        }

        test("draft order runs worst to best with the champion last") {
            var league = LeagueFactory.makeDefaultLeague(seed: 76, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)

            let order = DraftEngine.draftOrder(for: league)
            expectEqual(order.count, LeagueRules.teamCount)
            expectEqual(Set(order).count, LeagueRules.teamCount, "a team appeared twice in the draft order")

            let champion = SeasonEngine.champion(of: league)
            expectEqual(order.last, champion?.id, "the champion should pick last")

            let firstRecord = league.record(for: order[0])
            let lastRecord = league.record(for: order[order.count - 1])
            expect(
                firstRecord.winPercentage <= lastRecord.winPercentage,
                "the first pick should not belong to a better team than the last"
            )
        }

        test("a draft fills rosters with rookies on slotted deals") {
            var league = LeagueFactory.makeDefaultLeague(seed: 77, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)

            var prospects = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            let picks = TradeEngine.makePicks(for: league)
            let rosterBefore = league.teams.reduce(0) { $0 + $1.roster.count }
            DraftEngine.runDraft(&league, prospects: &prospects, picks: picks)
            let rosterAfter = league.teams.reduce(0) { $0 + $1.roster.count }

            expectEqual(
                rosterAfter - rosterBefore,
                LeagueRules.draftPickCount,
                "every pick should produce a rookie"
            )
            let rookies = league.teams.flatMap(\.roster).filter { $0.draftOrigin?.year == league.year }
            expect(
                rookies.allSatisfy { $0.contract?.isRookieDeal ?? false },
                "a drafted rookie is not on a rookie contract"
            )
            expect(
                rookies.allSatisfy { ($0.contract?.years ?? 0) == 4 },
                "rookie deals should run four years"
            )
        }
    }
}
