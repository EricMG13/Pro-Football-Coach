import Foundation
import FootballSimCore

func runCapComplianceTests() {
    suite("Cap compliance: event plumbing") {
        test("a compliance release headline names the team and the player") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-0000000CA001")!
            let teamID = UUID(uuidString: "00000000-0000-4000-8000-0000000CA002")!
            let payload = DomainEventPayload.proCapComplianceRelease(
                playerID: playerID,
                teamID: teamID,
                deadMoneyAdded: 500
            )
            expectEqual(payload.historicalWeight, 20)
            expectEqual(Set(payload.referencedEntityIDs), Set([playerID, teamID]))
        }
    }

    suite("Cap compliance: enforcement") {
        test("season-boundary discharge clears every team's dead money") {
            var state = GameState.bootstrap(seed: 62_007)
            let teamIDs = Array(state.proTeams.ids.prefix(2))
            state.proTeams.update(teamIDs[0]) { $0.deadMoney = 1 }
            state.proTeams.update(teamIDs[1]) { $0.deadMoney = 25_000_000 }

            let discharged = ProManagementSystem.dischargeDeadMoney(in: state)
            expect(discharged.proTeams.values.allSatisfy { $0.deadMoney == 0 },
                   "season-boundary discharge left dead money on the books")
        }

        test("compliance releases the cheapest dead money first, and stops once legal") {
            var state = GameState.bootstrap(seed: 62_001)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], team.rosterIDs.count >= 2 else {
                expect(false, "the fixture team has fewer than two rostered players")
                return
            }
            // A clean baseline: every contract this team holds is stripped, so the numbers below
            // are exact rather than layered on whatever bootstrap happened to sign.
            for playerID in team.rosterIDs + team.practiceSquadIDs {
                state.players.update(playerID) { $0.contract = nil }
            }
            _ = state.proTeams.update(teamID) { $0.deadMoney = 0 }

            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            let halfCap = capLimit / 2
            let cheapID = team.rosterIDs[0]
            let costlyID = team.rosterIDs[1]
            // Both contracts are legal alone (each capHit is roughly half the cap); together
            // they push the team over. Releasing either alone legalises the team, so the only
            // thing that decides which one goes is dead money: cheap carries 500, costly 50,000.
            // Signing bonuses divide evenly by the 5-year proration so the arithmetic is exact.
            state.players.update(cheapID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: Array(repeating: halfCap - 1_000, count: 5),
                    signingBonus: 500
                )
            }
            state.players.update(costlyID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: Array(repeating: halfCap - 1_000, count: 5),
                    signingBonus: 50_000
                )
            }

            let before = try ProManagementSystem.capSnapshot(teamID: teamID, in: state)
            expect(!before.isWithinCap, "the fixture is not actually over cap")

            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expectEqual(receipt.releases.map(\.playerID), [cheapID])
            expectEqual(receipt.releases.first?.deadMoneyAdded, 500)
            expectEqual(receipt.releases.first?.teamID, teamID)

            let after = try ProManagementSystem.capSnapshot(teamID: teamID, in: receipt.state)
            expect(after.isWithinCap, "the team is still over cap after compliance")
            expect(receipt.state.players[costlyID]?.contract != nil,
                   "the costly contract was released even though the cheap one alone sufficed")
            expect(receipt.state.players[cheapID]?.contract == nil)
            expect(receipt.state.proTeams[teamID]?.rosterIDs.contains(cheapID) != true)
            expect(receipt.state.proMarket.freeAgentIDs.contains(cheapID))
            expectEqual(receipt.state.proTeams[teamID]?.deadMoney, 500)
            expect(WorldIntegrity.check(receipt.state).isValid)
        }

        test("compliance never releases a deal whose release costs more cap than it sheds") {
            var state = GameState.bootstrap(seed: 62_005)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], team.rosterIDs.count >= 2 else {
                expect(false, "the fixture team has fewer than two rostered players")
                return
            }
            for playerID in team.rosterIDs + team.practiceSquadIDs {
                state.players.update(playerID) { $0.contract = nil }
            }
            state.proTeams.update(teamID) { $0.deadMoney = 0 }

            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            let trapID = team.rosterIDs[0]
            let payerID = team.rosterIDs[1]
            state.players.update(trapID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: Array(repeating: 0, count: 5),
                    signingBonus: 5,
                    signedSeason: state.calendar.season
                )
            }
            state.players.update(payerID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: [capLimit] + Array(repeating: 0, count: 4),
                    signingBonus: 5_000_000,
                    signedSeason: state.calendar.season
                )
            }

            let before = try ProManagementSystem.capSnapshot(teamID: teamID, in: state)
            expectEqual(before.committedCap, capLimit + 1_000_001)
            expect(!before.isWithinCap, "the fixture is not actually over cap")

            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expectEqual(receipt.releases.map(\.playerID), [payerID])
            expect(receipt.state.players[trapID]?.contract != nil,
                   "the trap deal was released even though releasing it raised the cap")
            let after = try ProManagementSystem.capSnapshot(teamID: teamID, in: receipt.state)
            expect(after.isWithinCap, "the team is still over cap after compliance")
            expect(after.committedCap < before.committedCap,
                   "compliance did not reduce committed cap")
            expect(WorldIntegrity.check(receipt.state).isValid)
        }

        test("compliance preserves the last playable body at every position") {
            var state = GameState.bootstrap(seed: 62_006)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID],
                  let kickerID = team.rosterIDs.first(where: {
                      state.players[$0]?.position == .kicker
                  }),
                  let payerID = team.rosterIDs.first(where: {
                      state.players[$0]?.position == .wideReceiver
                  }) else {
                expect(false, "the fixture team lacks a kicker or receiver")
                return
            }
            for playerID in team.rosterIDs + team.practiceSquadIDs {
                state.players.update(playerID) { $0.contract = nil }
            }
            state.proTeams.update(teamID) { $0.deadMoney = 0 }

            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            state.players.update(kickerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [1],
                    signingBonus: 0,
                    signedSeason: state.calendar.season
                )
            }
            state.players.update(payerID) {
                $0.contract = Contract(
                    years: 5,
                    baseSalaryByYear: [capLimit - 1] + Array(repeating: 0, count: 4),
                    signingBonus: 5,
                    signedSeason: state.calendar.season
                )
            }

            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expectEqual(receipt.releases.map(\.playerID), [payerID])
            expect(receipt.state.proTeams[teamID]?.rosterIDs.contains(kickerID) == true,
                   "compliance released the team's last kicker")
            expect(WorldIntegrity.check(receipt.state).isValid)
        }

        test("a team already within the cap is untouched") {
            let state = GameState.bootstrap(seed: 62_002)
            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expect(receipt.releases.isEmpty, "a legal bootstrap world had releases forced on it")
            expectEqual(
                try SaveEnvelope.encode(receipt.state),
                try SaveEnvelope.encode(state)
            )
        }

        test("a team with no releasable path to legality throws rather than persists") {
            var state = GameState.bootstrap(seed: 62_003)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], let onlyPlayerID = team.rosterIDs.first else {
                expect(false, "the fixture team has no rostered players")
                return
            }
            for playerID in team.rosterIDs + team.practiceSquadIDs where playerID != onlyPlayerID {
                _ = state.proTeams.update(teamID) { squad in
                    squad.rosterIDs.removeAll { $0 == playerID }
                    squad.practiceSquadIDs.removeAll { $0 == playerID }
                }
            }
            // Dead money already on the books, alone, exceeds the cap. No release of the one
            // remaining contracted player can ever bring committedCap back under the limit,
            // because releasing it only adds more dead money on top.
            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            _ = state.proTeams.update(teamID) { $0.deadMoney = capLimit + 1 }
            state.players.update(onlyPlayerID) {
                $0.contract = Contract(years: 1, baseSalaryByYear: [1], signingBonus: 0)
            }

            do {
                _ = try ProManagementSystem.enforceCapCompliance(at: state.calendar, in: state)
                expect(false, "an unfixable over-cap team did not throw")
            } catch ProManagementError.capExceeded {
                expect(true)
            } catch {
                expect(false, "wrong error: \(error)")
            }
        }

        test("the controlled team is never auto-released from") {
            var state = GameState.bootstrap(seed: 62_004)
            let teamID = state.proTeams.ids[0]
            guard let team = state.proTeams[teamID], team.rosterIDs.count >= 1 else {
                expect(false, "the fixture team has no rostered players")
                return
            }
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            let overCapPlayerID = team.rosterIDs[0]
            state.players.update(overCapPlayerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [capLimit + 1_000_000],
                    signingBonus: 0
                )
            }

            let receipt = try ProManagementSystem.enforceCapCompliance(
                at: state.calendar,
                in: state
            )
            expect(receipt.releases.isEmpty, "the controlled team was released from")
            expect(receipt.state.players[overCapPlayerID]?.contract != nil,
                   "the controlled team's over-cap contract was force-released")
        }
    }
}
