import Foundation
import FootballSimCore

func runProManagementTests() {
    suite("M6 professional management") {
        test("a free-agent acquisition is cap legal and save stable") {
            var state = GameState.bootstrap(seed: 60_001)
            let teamID = state.proTeams.ids[0]
            makeRosterOpening(teamID: teamID, in: &state)
            let player = unattachedPlayer(id: UUID(uuidString: "00000000-0000-4000-8000-000000006001")!)
            state.players.insert(player)
            state.people.insert(player: player)
            let contract = Contract(years: 3, baseSalaryByYear: [2_000_000, 2_500_000, 3_000_000], signingBonus: 1_000_000)

            let receipt = try ProManagementSystem.acquire(
                playerID: player.id,
                for: teamID,
                kind: .freeAgency,
                contract: contract,
                in: state
            )
            expectEqual(receipt.capAfter.committedCap - receipt.capBefore.committedCap, contract.capHit(inYear: 0))
            expect(receipt.state.proTeams[teamID]?.rosterIDs.contains(player.id) == true)
            expectEqual(
                receipt.state.players[player.id]?.contract,
                contract.withSignedSeason(state.proMarket.season)
            )
            let encoded = try SaveEnvelope.encode(receipt.state)
            let restored = try SaveEnvelope.decode(GameState.self, from: encoded)
            expectEqual(restored, receipt.state)
        }

        test("release removes ownership and carries bonus into dead money") {
            var state = GameState.bootstrap(seed: 60_002)
            let teamID = state.proTeams.ids[0]
            makeRosterOpening(teamID: teamID, in: &state)
            let player = unattachedPlayer(id: UUID(uuidString: "00000000-0000-4000-8000-000000006002")!)
            state.players.insert(player)
            state.people.insert(player: player)
            let signed = try ProManagementSystem.acquire(
                playerID: player.id,
                for: teamID,
                kind: .draft,
                contract: Contract(years: 2, baseSalaryByYear: [1_000_000, 1_000_000], signingBonus: 700_003),
                in: state
            )
            let released = try ProManagementSystem.release(
                playerID: player.id,
                from: teamID,
                in: signed.state
            )
            expectEqual(released.deadMoneyAdded, 700_003)
            expect(released.state.proTeams[teamID]?.rosterIDs.contains(player.id) != true)
            expectEqual(released.state.players[player.id]?.contract, nil)
            expectEqual(released.state.proTeams[teamID]?.deadMoney, 700_003)
            expect(WorldIntegrity.check(released.state).isValid)
        }

        test("cap and roster boundaries reject atomically") {
            var state = GameState.bootstrap(seed: 60_003)
            let teamID = state.proTeams.ids[0]
            makeRosterOpening(teamID: teamID, in: &state)
            let player = unattachedPlayer(id: UUID(uuidString: "00000000-0000-4000-8000-000000006003")!)
            state.players.insert(player)
            state.people.insert(player: player)
            let before = try JSONEncoder.stable().encode(state)
            do {
                _ = try ProManagementSystem.acquire(
                    playerID: player.id,
                    for: teamID,
                    kind: .freeAgency,
                    contract: Contract(
                        years: 1,
                        baseSalaryByYear: [ProRules.salaryCap(seasonsAfterBase: state.calendar.season) + 1],
                        signingBonus: 0
                    ),
                    in: state
                )
                expect(false, "an over-cap acquisition was accepted")
            } catch ProManagementError.capExceeded {
                expectEqual(try JSONEncoder.stable().encode(state), before)
            } catch {
                expect(false, "wrong rejection: \(error)")
            }
        }

        test("draft order is deterministic and includes every team") {
            let state = GameState.bootstrap(seed: 60_004)
            expectEqual(ProManagementSystem.draftOrder(in: state), ProManagementSystem.draftOrder(in: state))
            expectEqual(Set(ProManagementSystem.draftOrder(in: state)), Set(state.proTeams.ids))
        }

        test("contract negotiation persists offer, counter, and settlement") {
            var state = GameState.bootstrap(seed: 60_008)
            let teamID = state.proTeams.ids[0]
            let playerID = state.proTeams[teamID]!.rosterIDs[0]
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let current = state.players[playerID]!.contract!
            let opening = try ProManagementSystem.beginNegotiation(
                playerID: playerID,
                teamID: teamID,
                offer: current,
                deadline: state.calendar.advancedWeek().advancedWeek(),
                in: state
            )
            expectEqual(opening.state.proMarket.contractNegotiations.count, 1)
            let negotiationID = opening.negotiation.id
            let counter = try ProManagementSystem.counterNegotiation(
                negotiationID: negotiationID,
                offer: current,
                in: opening.state
            )
            expectEqual(counter.negotiation.offerHistory.count, 2)
            let accepted = try ProManagementSystem.settleNegotiation(
                negotiationID: negotiationID,
                as: .accepted,
                in: counter.state
            )
            expectEqual(accepted.negotiation.status, .accepted)
            expectEqual(
                accepted.state.players[playerID]?.contract,
                current.withSignedSeason(state.calendar.season)
            )
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(accepted.state)
            )
            expectEqual(restored, accepted.state)
        }

        test("closed negotiation history survives a later player release") {
            var state = GameState.bootstrap(seed: 60_009)
            let teamID = state.proTeams.ids[0]
            let team = state.proTeams[teamID]!
            let positionCounts = Dictionary(
                grouping: team.rosterIDs.compactMap { state.players[$0]?.position },
                by: { $0 }
            ).mapValues(\.count)
            let playerID = team.rosterIDs.first(where: { playerID in
                guard let position = state.players[playerID]?.position else { return false }
                return positionCounts[position, default: 0]
                    > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
            })!
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let current = state.players[playerID]!.contract!
            let opening = try ProManagementSystem.beginNegotiation(
                playerID: playerID,
                teamID: teamID,
                offer: current,
                deadline: state.calendar.advancedWeek(),
                in: state
            )
            let rejected = try ProManagementSystem.settleNegotiation(
                negotiationID: opening.negotiation.id,
                as: .rejected,
                in: opening.state
            )
            let released = try ProManagementSystem.release(
                playerID: playerID,
                from: teamID,
                in: rejected.state
            )
            expect(WorldIntegrity.check(released.state).isValid)
            expectEqual(released.state.proMarket.contractNegotiations.first?.status, .rejected)
        }

        test("a promoted professional coach owns the transaction intent") {
            var state = GameState.bootstrap(seed: 60_005)
            let teamID = state.proTeams.ids[0]
            makeRosterOpening(teamID: teamID, in: &state)
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let player = unattachedPlayer(id: UUID(uuidString: "00000000-0000-4000-8000-000000006005")!)
            state.players.insert(player)
            state.people.insert(player: player)
            let request = ProManagementRequest(
                calendar: state.calendar,
                action: .acquire(
                    playerID: player.id,
                    teamID: teamID,
                    kind: .freeAgency,
                    contract: Contract(years: 1, baseSalaryByYear: [1_000_000], signingBonus: 0)
                )
            )
            let resolved = try IntentResolver.resolve(.proManagement(request), in: state)
            expect(resolved.state.proTeams[teamID]?.rosterIDs.contains(player.id) == true)
            if case let .proManagementUpdated(result) = resolved.result {
                expectEqual(result.calendar, state.calendar)
                expectEqual(result.cap.teamID, teamID)
            } else {
                expect(false, "professional intent returned the wrong result")
            }
            do {
                _ = try IntentResolver.resolve(.proManagement(request), in: GameState.bootstrap(seed: 60_006))
                expect(false, "a college-controlled root accepted a professional intent")
            } catch IntentResolutionError.professionalManagementUnavailable {
                expect(true)
            }
        }

        test("root integrity rejects an over-cap professional roster") {
            var state = GameState.bootstrap(seed: 60_007)
            let teamID = state.proTeams.ids[0]
            let playerID = state.proTeams[teamID]!.rosterIDs[0]
            let overCap = ProRules.salaryCap(seasonsAfterBase: state.calendar.season) + 1
            state.players.update(playerID) {
                $0.contract = Contract(years: 1, baseSalaryByYear: [overCap], signingBonus: 0)
            }
            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case let .invalidProfessionalCap(id) = issue { return id == teamID }
                return false
            }, "an over-cap team passed root integrity")
        }

        test("an acquired contract always carries the market season") {
            var state = GameState.bootstrap(seed: 60_020)
            let teamID = state.proTeams.ids[0]
            makeRosterOpening(teamID: teamID, in: &state)
            let player = unattachedPlayer(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000006020")!
            )
            state.players.insert(player)
            state.people.insert(player: player)

            let receipt = try ProManagementSystem.acquire(
                playerID: player.id,
                for: teamID,
                kind: .freeAgency,
                contract: Contract(
                    years: 2,
                    baseSalaryByYear: [1_000_000, 1_000_000],
                    signingBonus: 0
                ),
                in: state
            )
            expectEqual(
                receipt.state.players[player.id]?.contract?.signedSeason,
                state.proMarket.season,
                "the shared acquisition primitive left signedSeason unstamped"
            )

            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            makeRosterOpening(teamID: teamID, in: &state)
            let intentPlayer = unattachedPlayer(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000006021")!
            )
            state.players.insert(intentPlayer)
            state.people.insert(player: intentPlayer)
            let request = ProManagementRequest(
                calendar: state.calendar,
                action: .acquire(
                    playerID: intentPlayer.id,
                    teamID: teamID,
                    kind: .freeAgency,
                    contract: Contract(
                        years: 2,
                        baseSalaryByYear: [1_000_000, 1_000_000],
                        signingBonus: 0
                    )
                )
            )
            let resolved = try IntentResolver.resolve(.proManagement(request), in: state)
            expectEqual(
                resolved.state.players[intentPlayer.id]?.contract?.signedSeason,
                state.proMarket.season,
                "the controlled acquire intent left signedSeason unstamped"
            )
        }

        test("root integrity rejects a professional contract no team owns") {
            var state = GameState.bootstrap(seed: 60_008)
            let teamID = state.proTeams.ids[0]
            let playerID = state.proTeams[teamID]!.rosterIDs[0]
            state.proTeams.update(teamID) {
                $0.rosterIDs.removeAll { $0 == playerID }
            }
            expect(WorldIntegrity.check(state).issues.contains(
                .unownedProfessionalContract(playerID: playerID)
            ), "an unowned professional contract passed root integrity")
        }
    }
}

private func unattachedPlayer(id: UUID) -> Player {
    Player(
        id: id,
        firstName: "M6",
        lastName: "FreeAgent",
        position: .wideReceiver,
        age: 23,
        attributes: Attributes([.speed: Rating(80), .hands: Rating(76)]),
        potential: Rating(84)
    )
}

private func makeRosterOpening(teamID: UUID, in state: inout GameState) {
    guard let team = state.proTeams[teamID],
          let removableID = team.rosterIDs.first(where: {
              state.players[$0]?.position == .wideReceiver
          }) else { return }
    _ = state.proTeams.update(teamID) { team in
        team.rosterIDs.removeAll { $0 == removableID }
    }
    state.players.update(removableID) { $0.contract = nil }
}
