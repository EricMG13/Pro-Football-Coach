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
            let idsBefore = Set(league.teams.flatMap { $0.roster.map(\.id) })
            DraftEngine.runDraft(&league, prospects: &prospects, picks: picks)
            let idsAfter = Set(league.teams.flatMap { $0.roster.map(\.id) })

            expectEqual(
                idsAfter.count - idsBefore.count,
                LeagueRules.draftPickCount,
                "every pick should produce a rookie"
            )
            // Identify draftees by who is newly on a roster. Filtering on draft year would also
            // catch generated players who happen to have entered the league the same year.
            let rookies = league.teams.flatMap(\.roster).filter { !idsBefore.contains($0.id) }
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

func runInteractiveDraftTests() {
    suite("DraftSession") {
        /// A league that has finished a season, so a real draft order exists.
        func preparedLeague(seed: UInt64) -> League {
            var league = LeagueFactory.makeDefaultLeague(seed: seed, userTeamIndex: 0, coach: .stub())
            SeasonEngine.startSeason(&league)
            SeasonEngine.simulateToOffseason(&league)
            return league
        }

        test("the session stops when the user is on the clock") {
            var league = preparedLeague(seed: 400)
            let prospects = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            let picks = TradeEngine.makePicks(for: league)
            var session = DraftSession(league: league, prospects: prospects, picks: picks)

            session.advanceToUserPick(league: &league)
            expect(session.isUserOnTheClock, "the session should stop on the user's pick")
            expect(!session.isFinished, "the draft should not be over yet")
            expect(
                session.completed.allSatisfy { $0.teamID != league.userTeamID },
                "the AI made a pick for the user"
            )
        }

        test("the user's selection lands on their roster on a rookie deal") {
            var league = preparedLeague(seed: 401)
            let prospects = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            let picks = TradeEngine.makePicks(for: league)
            var session = DraftSession(league: league, prospects: prospects, picks: picks)
            session.advanceToUserPick(league: &league)

            let rosterBefore = league.userTeam!.roster.count
            let wanted = session.prospects.max { $0.trueOverall < $1.trueOverall }!
            let pick = session.select(prospectID: wanted.id, league: &league)

            expect(pick != nil, "the selection was refused")
            expectEqual(pick?.playerID, wanted.player.id)
            expectEqual(league.userTeam!.roster.count, rosterBefore + 1)

            let rookie = league.userTeam!.player(id: wanted.player.id)
            expect(rookie != nil, "the pick never reached the roster")
            expect(rookie?.contract?.isRookieDeal == true, "a draft pick must be on a rookie deal")
            expectEqual(rookie?.draftOrigin?.year, league.year)
            expect(
                !session.prospects.contains { $0.id == wanted.id },
                "a drafted prospect is still on the board"
            )
        }

        test("a completed session drafts every pick exactly once") {
            var league = preparedLeague(seed: 402)
            let prospects = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            let picks = TradeEngine.makePicks(for: league)
            var session = DraftSession(league: league, prospects: prospects, picks: picks)

            var guardCounter = 0
            while !session.isFinished, guardCounter < LeagueRules.draftPickCount + 10 {
                guardCounter += 1
                if session.isUserOnTheClock {
                    session.autoPickForUser(league: &league)
                } else {
                    session.advanceToUserPick(league: &league)
                }
            }

            expectEqual(
                session.completed.count,
                LeagueRules.draftPickCount,
                "every pick in the draft should have been used"
            )
            let players = session.completed.map(\.playerID)
            expectEqual(Set(players).count, players.count, "a prospect was drafted twice")

            // Pick numbering must be continuous and rounds in order.
            expectEqual(session.completed.map(\.overall), Array(1...session.completed.count))
            expect(
                zip(session.completed, session.completed.dropFirst())
                    .allSatisfy { $0.round <= $1.round },
                "rounds went backwards"
            )
        }

        test("finishing early still fills every roster spot") {
            var league = preparedLeague(seed: 403)
            let prospects = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            let picks = TradeEngine.makePicks(for: league)
            var session = DraftSession(league: league, prospects: prospects, picks: picks)
            session.finish(league: &league)

            expect(session.isFinished)
            expect(session.prospects.isEmpty, "undrafted players were left in limbo")
            expectEqual(session.completed.count, LeagueRules.draftPickCount)
        }

        test("war-room grades reflect where a player was expected to go") {
            let pick = CompletedPick(
                id: UUID(), round: 4, pickInRound: 1, overall: 97, teamID: UUID(),
                playerID: UUID(), playerName: "Test", position: .wr, rating: 78
            )
            expectEqual(DraftSession.grade(for: pick, expectedRound: 7), "Steal")
            expectEqual(DraftSession.grade(for: pick, expectedRound: 4), "On the board")
            expectEqual(DraftSession.grade(for: pick, expectedRound: 1), "Reach")
        }
    }

    suite("Re-signing") {
        test("a fair offer is likely and a lowball is not") {
            var league = LeagueFactory.makeDefaultLeague(seed: 410, userTeamIndex: 0, coach: .stub())
            let team = league.userTeam!
            let player = team.activeRoster.first { $0.position == .wr }!

            let asking = ReSignEngine.askingSalary(for: player, team: team, league: league)
            let fair = ReSignEngine.acceptance(
                player: player, offer: .flat(years: 3, salary: asking), team: team, league: league
            )
            let lowball = ReSignEngine.acceptance(
                player: player, offer: .flat(years: 3, salary: asking / 3), team: team, league: league
            )
            expect(fair > lowball, "a fair offer should beat a lowball")
            expect(fair > 0.5, "a market-rate offer should usually be accepted: \(fair)")
            expect(lowball < 0.4, "a third of market value should usually be refused: \(lowball)")
            _ = league
        }

        test("loyal players are cheaper to keep than mercenaries") {
            let league = LeagueFactory.makeDefaultLeague(seed: 411, userTeamIndex: 0, coach: .stub())
            let team = league.userTeam!
            let loyal = TestFixtures.player(position: .te, rating: 80, traits: [.loyal])
            let mercenary = TestFixtures.player(position: .te, rating: 80, traits: [.mercenary])
            let offer = Contract.flat(
                years: 3,
                salary: ReSignEngine.askingSalary(for: loyal, team: team, league: league)
            )
            expect(
                ReSignEngine.acceptance(player: loyal, offer: offer, team: team, league: league)
                    > ReSignEngine.acceptance(player: mercenary, offer: offer, team: team, league: league),
                "loyalty should make a player easier to keep"
            )
        }

        test("re-signing puts a player back under contract and respects the cap") {
            var league = LeagueFactory.makeDefaultLeague(seed: 412, userTeamIndex: 0, coach: .stub())
            let teamID = league.userTeamID
            let player = league.userTeam!.activeRoster.first { $0.contract?.isExpiring ?? false }
                ?? league.userTeam!.activeRoster[0]

            let absurd = Contract.flat(years: 3, salary: 800_000_000)
            expect(
                !ReSignEngine.reSign(playerID: player.id, to: teamID, contract: absurd, in: &league),
                "an unaffordable extension was accepted"
            )

            let sensible = Contract.flat(years: 2, salary: 2_000_000)
            expect(
                ReSignEngine.reSign(playerID: player.id, to: teamID, contract: sensible, in: &league),
                "a sensible extension was refused"
            )
            let updated = league.userTeam!.player(id: player.id)
            expectEqual(updated?.contract?.years, 2)
            expectEqual(updated?.contract?.yearsRemaining, 2)
        }

        test("the expiring list finds the players whose deals are up") {
            var league = LeagueFactory.makeDefaultLeague(seed: 413, userTeamIndex: 0, coach: .stub())
            CapEngine.rolloverContracts(in: &league)
            let expiring = ReSignEngine.expiring(for: league.userTeam!)
            expect(
                expiring.allSatisfy { $0.contract == nil || ($0.contract?.isExpiring ?? false) },
                "a player with years left appeared on the expiring list"
            )
            expect(
                zip(expiring, expiring.dropFirst()).allSatisfy { $0.overall >= $1.overall },
                "the expiring list should lead with the best players"
            )
        }
    }
}
