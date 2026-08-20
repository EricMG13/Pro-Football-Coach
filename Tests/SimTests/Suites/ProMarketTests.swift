import Foundation
import FootballSimCore

func runProMarketTests() {
    suite("M6 professional market") {
        test("offseason market is deterministic and bounded") {
            let first = try ProMarketSystem.openOffseason(in: GameState.bootstrap(seed: 60_101))
            let second = try ProMarketSystem.openOffseason(in: GameState.bootstrap(seed: 60_101))
            expectEqual(first.proMarket, second.proMarket)
            expectEqual(first.proMarket.phase, .freeAgency)
            expectEqual(first.proMarket.draftClass.count, ProRules.draftPickCount)
            expectEqual(first.proMarket.draftOrder.count, ProRules.draftPickCount)
            expectEqual(Set(first.proMarket.draftOrder), Set(first.proTeams.ids))
            expect(first.proMarket.draftClass.allSatisfy { $0.player.eligibility == nil })
            expect(first.proMarket.draftClass.allSatisfy { $0.player.contract == nil })
            let encoded = try SaveEnvelope.encode(first)
            expectEqual(try SaveEnvelope.decode(GameState.self, from: encoded), first)
            var closed = first
            expect(closed.proMarket.close())
            expectEqual(closed.proMarket.archivedDraftProspectIDs.count, ProRules.draftPickCount)
            expect(WorldIntegrity.check(closed).isValid)
        }

        test("scouting is observer-specific and round trips") {
            let opened = try ProMarketSystem.openOffseason(in: GameState.bootstrap(seed: 60_102))
            let prospectID = try require(opened.proMarket.draftClass.first?.id)
            let teamID = try require(opened.proTeams.ids.first)
            let observed = try ProMarketSystem.recordScouting(
                teamID: teamID,
                prospectID: prospectID,
                in: opened
            )
            expectEqual(observed.proMarket.observations.count, 1)
            expectEqual(observed.proMarket.observations[0].teamID, teamID)
            expectEqual(observed.proMarket.observations[0].prospectID, prospectID)
            expectEqual(try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(observed)
            ), observed)
        }

        test("draft consumes one pick and acquires the prospect atomically") {
            var state = try ProMarketSystem.openOffseason(in: GameState.bootstrap(seed: 60_103))
            let teamID = try require(state.proMarket.draftOrder.first)
            removeProRosterPlayer(teamID: teamID, in: &state)
            state = try ProMarketSystem.beginDraft(in: state)
            let prospect = try require(state.proMarket.draftClass.first)
            let drafted = try ProMarketSystem.draft(
                prospectID: prospect.id,
                for: teamID,
                in: state
            )
            expectEqual(drafted.proMarket.nextPick, 1)
            expect(drafted.proMarket.draftedProspectIDs.contains(prospect.id))
            expect(drafted.proTeams[teamID]?.rosterIDs.contains(prospect.id) == true)
            expectEqual(
                drafted.players[prospect.id]?.contract,
                ProMarketSystem.rookieContract(for: prospect.player)
                    .withSignedSeason(state.proMarket.season)
            )
            expect(WorldIntegrity.check(drafted).isValid)
        }

        test("an unattached professional can sign in free agency") {
            var state = GameState.bootstrap(seed: 60_104)
            let teamID = try require(state.proTeams.ids.first)
            removeProRosterPlayer(teamID: teamID, in: &state)
            let player = marketFreeAgent(id: UUID(uuidString: "00000000-0000-4000-8000-000000006104")!)
            state.players.insert(player)
            state.people.insert(player: player)
            state = try ProMarketSystem.openOffseason(in: state)
            expect(state.proMarket.freeAgentIDs.contains(player.id))
            let signed = try ProMarketSystem.signFreeAgent(
                playerID: player.id,
                teamID: teamID,
                contract: Contract(years: 2, baseSalaryByYear: [1_000_000, 1_200_000], signingBonus: 0),
                in: state
            )
            expect(signed.proTeams[teamID]?.rosterIDs.contains(player.id) == true)
            expect(!signed.proMarket.freeAgentIDs.contains(player.id))
            expect(WorldIntegrity.check(signed).isValid)
        }

        test("wrong draft team and duplicate pick leave bytes unchanged") {
            var state = try ProMarketSystem.openOffseason(in: GameState.bootstrap(seed: 60_105))
            state = try ProMarketSystem.beginDraft(in: state)
            let prospect = try require(state.proMarket.draftClass.first)
            let before = try JSONEncoder.stable().encode(state)
            let wrongTeam = state.proTeams.ids.first { $0 != state.proMarket.currentPickTeamID } ?? state.proTeams.ids[0]
            do {
                _ = try ProMarketSystem.draft(prospectID: prospect.id, for: wrongTeam, in: state)
                expect(false, "wrong draft team was accepted")
            } catch ProMarketError.wrongDraftTeam {
                expectEqual(try JSONEncoder.stable().encode(state), before)
            }
        }

        test("professional market intents require a professional job") {
            var state = GameState.bootstrap(seed: 60_106)
            let teamID = try require(state.proTeams.ids.first)
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let request = ProMarketRequest(
                calendar: state.calendar,
                action: .openOffseason
            )
            let resolved = try IntentResolver.resolve(.proMarket(request), in: state)
            if case let .proMarketUpdated(result) = resolved.result {
                expectEqual(result.action, .openOffseason)
            } else {
                expect(false, "professional market intent returned the wrong result")
            }
            let playerID = try require(resolved.state.proTeams[teamID]?.rosterIDs.first)
            let moveRequest = ProMarketRequest(
                calendar: resolved.state.calendar,
                action: .moveToPracticeSquad(playerID: playerID, teamID: teamID)
            )
            let moved = try IntentResolver.resolve(.proMarket(moveRequest), in: resolved.state)
            if case let .proMarketUpdated(result) = moved.result {
                expect(result.emittedEvents.contains {
                    if case .proPracticeSquadMoved(playerID: playerID, teamID: teamID, promoted: false) = $0.payload {
                        return true
                    }
                    return false
                })
            } else {
                expect(false, "practice-squad intent returned the wrong result")
            }
            let promoted = try ProMarketSystem.promoteFromPracticeSquad(
                playerID: playerID,
                teamID: teamID,
                in: moved.state
            )
            expect(promoted.proTeams[teamID]?.rosterIDs.contains(playerID) == true)
            do {
                _ = try IntentResolver.resolve(
                    .proMarket(request),
                    in: GameState.bootstrap(seed: 60_107)
                )
                expect(false, "a college root accepted a professional market intent")
            } catch IntentResolutionError.professionalMarketUnavailable {
                expect(true)
            }
        }

        test("root integrity rejects an out-of-season professional market") {
            var state = GameState.bootstrap(seed: 60_108)
            state.proMarket = ProMarketState(season: state.calendar.season + 3)
            expect(WorldIntegrity.check(state).issues.contains(.invalidProfessionalMarket))
        }

        test("practice squad, trade, and waivers preserve ownership atomically") {
            var state = GameState.bootstrap(seed: 60_109)
            let teamIDs = Array(state.proTeams.ids.prefix(2))
            let sourceTeamID = try require(teamIDs.first)
            let destinationTeamID = try require(teamIDs.dropFirst().first)
            let sourcePlayerID = try require(state.proTeams[sourceTeamID]?.rosterIDs.first)
            let destinationPlayerID = try require(state.proTeams[destinationTeamID]?.rosterIDs.first)
            let contract = Contract(years: 2, baseSalaryByYear: [1_000_000, 1_000_000], signingBonus: 0)
            state.players.update(sourcePlayerID) { $0.contract = contract }

            let traded = try ProMarketSystem.trade(
                sourcePlayerID: sourcePlayerID,
                sourceTeamID: sourceTeamID,
                destinationPlayerID: destinationPlayerID,
                destinationTeamID: destinationTeamID,
                in: state
            )
            expect(traded.proTeams[sourceTeamID]?.rosterIDs.contains(destinationPlayerID) == true)
            expect(traded.proTeams[destinationTeamID]?.rosterIDs.contains(sourcePlayerID) == true)

            state = try ProMarketSystem.moveToPracticeSquad(
                playerID: sourcePlayerID,
                teamID: sourceTeamID,
                in: state
            )
            expect(state.proTeams[sourceTeamID]?.practiceSquadIDs.contains(sourcePlayerID) == true)
            state = try ProMarketSystem.placeOnWaivers(
                playerID: sourcePlayerID,
                teamID: sourceTeamID,
                at: state.calendar,
                in: state
            )
            _ = removeProRosterPlayer(teamID: destinationTeamID, in: &state)
            let claimed = try ProMarketSystem.claimWaiver(
                playerID: sourcePlayerID,
                teamID: destinationTeamID,
                at: state.calendar,
                in: state
            )
            expect(claimed.proTeams[sourceTeamID]?.practiceSquadIDs.contains(sourcePlayerID) == false)
            expect(claimed.proTeams[destinationTeamID]?.rosterIDs.contains(sourcePlayerID) == true)
            expect(claimed.proMarket.waivers.isEmpty)
            expect(WorldIntegrity.check(claimed).isValid)
        }

        test("expired waiver releases a player into the free-agent ledger") {
            var state = GameState.bootstrap(seed: 60_110)
            let teamID = try require(state.proTeams.ids.first)
            let playerID = try require(state.proTeams[teamID]?.rosterIDs.first)
            state.players.update(playerID) {
                $0.contract = Contract(years: 2, baseSalaryByYear: [1_000_000, 1_000_000], signingBonus: 0)
            }
            state = try ProMarketSystem.placeOnWaivers(
                playerID: playerID,
                teamID: teamID,
                at: state.calendar,
                in: state
            )
            let expiredAt = state.calendar.advancedWeek().advancedWeek()
            state = try ProMarketSystem.resolveExpiredWaivers(at: expiredAt, in: state)
            expect(state.proMarket.freeAgentIDs.contains(playerID))
            expect(state.players[playerID]?.contract == nil)
            expect(WorldIntegrity.check(state).isValid)
        }

        test("market signings carry a season and expire without dead money") {
            do {
                _ = try JSONDecoder().decode(
                    Contract.self,
                    from: Data(#"{"years":1,"baseSalaryByYear":[1],"signingBonus":0,"signedSeason":-1}"#.utf8)
                )
                expect(false, "negative contract start season was accepted")
            } catch {
                expect(true)
            }
            var state = GameState.bootstrap(seed: 60_111)
            let teamID = try require(state.proTeams.ids.first)
            let playerID = try require(state.proTeams[teamID]?.rosterIDs.first)
            _ = removeProRosterPlayer(teamID: teamID, in: &state)
            state = try ProMarketSystem.openOffseason(in: state)
            state = try ProMarketSystem.signFreeAgent(
                playerID: playerID,
                teamID: teamID,
                contract: Contract(years: 1, baseSalaryByYear: [1_000_000], signingBonus: 200_000),
                in: state
            )
            expectEqual(state.players[playerID]?.contract?.signedSeason, state.proMarket.season)
            expectEqual(try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            ), state)

            var rollover = GameState.bootstrap(seed: 60_112)
            let rolloverTeamID = try require(rollover.proTeams.ids.first)
            let rolloverPlayerID = try require(rollover.proTeams[rolloverTeamID]?.rosterIDs.first)
            rollover.players.update(rolloverPlayerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [1_000_000],
                    signingBonus: 200_000,
                    signedSeason: 0
                )
            }
            rollover.league.season = 0
            rollover.league.week = SharedRules.inSeasonWeeks
            rollover.calendar = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            // The signing week carries the signing phase (`02` section 4.1). Without this the
            // hand-built calendar produces a root the scheduler could never emit, and the integrity
            // assertion at the end of this test is checking the fixture rather than the expiry.
            rollover.college.phase = CollegeRules
                .recruitingCyclePhase(inWeek: rollover.calendar.week)
            let expired = try ProMarketSystem.expireContracts(at: rollover.calendar, in: rollover)
            expect(expired.expiredPlayerIDs.contains(rolloverPlayerID))
            expect(expired.state.players[rolloverPlayerID]?.contract == nil)
            expect(expired.state.proTeams[rolloverTeamID]?.rosterIDs.contains(rolloverPlayerID) == false)
            expect(expired.state.proMarket.freeAgentIDs.contains(rolloverPlayerID))
            expectEqual(expired.state.proTeams[rolloverTeamID]?.deadMoney, 0)
            expect(WorldIntegrity.check(expired.state).isValid)
        }

        test("professional roster AI is deterministic and leaves the controlled team alone") {
            func fixture() throws -> GameState {
                var state = GameState.bootstrap(seed: 60_113)
                let controlledTeamID = try require(state.proTeams.ids.first)
                let aiTeamID = try require(state.proTeams.ids.dropFirst().first)
                _ = removeProRosterPlayer(teamID: aiTeamID, in: &state)
                state.careerArc = CareerArcState(
                    currentJob: CareerJob(
                        organisationID: controlledTeamID,
                        tier: .professional,
                        startedAt: state.calendar
                    ),
                    status: .employed
                )
                state = try ProMarketSystem.openOffseason(in: state)
                return state
            }
            let firstRoot = try fixture()
            let secondRoot = try fixture()
            let first = try ProRosterAISystem.process(
                at: firstRoot.calendar,
                in: firstRoot
            )
            let second = try ProRosterAISystem.process(
                at: secondRoot.calendar,
                in: secondRoot
            )
            expectEqual(first.state, second.state)
            expectEqual(first.eventPayloads, second.eventPayloads)
            let aiTeamID = try require(first.state.proTeams.ids.dropFirst().first)
            expectEqual(first.signedPlayerIDs.count, 1)
            // `require` rather than `[0]`: an empty signing list is a failure to report, not a
            // reason to trap. Indexing it here aborted the process and took the rest of the suite
            // — and, in the full run, every suite after it — down with it.
            let signedPlayerID = try require(first.signedPlayerIDs.first)
            expect(first.state.proTeams[aiTeamID]?.rosterIDs.contains(signedPlayerID) == true)
            let controlledTeamID = try require(first.state.proTeams.ids.first)
            expect(first.state.proTeams[controlledTeamID]?.rosterIDs.contains(signedPlayerID) == false)
            expect(WorldIntegrity.check(first.state).isValid)
        }

        test("a weekly scheduler pass preserves both-tier legality after professional AI") {
            var state = GameState.bootstrap(seed: 60_114)
            let aiTeamID = try require(state.proTeams.ids.dropFirst().first)
            _ = removeProRosterPlayer(teamID: aiTeamID, in: &state)
            state = try ProMarketSystem.openOffseason(in: state)
            let transition = try WorldScheduler.advanceWeek(state)
            expect(WorldIntegrity.check(transition.state).isValid)
            expect(transition.state.players.values
                .filter { $0.contract?.signedSeason == transition.state.proMarket.season }
                .allSatisfy { $0.eligibility == nil })
            expectEqual(
                try SaveEnvelope.decode(
                    GameState.self,
                    from: SaveEnvelope.encode(transition.state)
                ),
                transition.state
            )
        }
    }
}

private func marketFreeAgent(id: UUID) -> Player {
    Player(
        id: id,
        firstName: "Market",
        lastName: "FreeAgent",
        position: .wideReceiver,
        age: 23,
        attributes: Attributes([.speed: Rating(80), .hands: Rating(78)]),
        potential: Rating(84)
    )
}

private enum ProMarketTestError: Error { case missingFixture }

private func require<T>(_ value: T?) throws -> T {
    guard let value else { throw ProMarketTestError.missingFixture }
    return value
}

@discardableResult
/// Opens one roster slot and puts the player it displaces into the market.
///
/// The contract goes with them, and that is not incidental. `openOffseason` builds the free-agent
/// pool from players who are unowned **and uncontracted**, so before `0deb629` — when a generated
/// world issued no contracts at all — removing a player from a roster was enough to make them a
/// free agent. Once bootstrap began issuing contracts it silently stopped being enough: the pool
/// came back empty, the AI signed nobody, and a test that indexed the first signing crashed the
/// whole process instead of failing one check.
private func removeProRosterPlayer(teamID: UUID, in state: inout GameState) -> UUID? {
    guard let playerID = state.proTeams[teamID]?.rosterIDs.first else { return nil }
    _ = state.proTeams.update(teamID) { team in
        team.rosterIDs.removeAll { $0 == playerID }
    }
    state.players.update(playerID) { $0.contract = nil }
    return playerID
}
