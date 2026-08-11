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
            expectEqual(drafted.players[prospect.id]?.contract, ProMarketSystem.rookieContract(for: prospect.player))
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

private func removeProRosterPlayer(teamID: UUID, in state: inout GameState) {
    guard let playerID = state.proTeams[teamID]?.rosterIDs.first else { return }
    _ = state.proTeams.update(teamID) { team in
        team.rosterIDs.removeAll { $0 == playerID }
    }
}
