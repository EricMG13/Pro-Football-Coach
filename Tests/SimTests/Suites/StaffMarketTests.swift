import Foundation
import FootballSimCore

func runStaffMarketTests() {
    suite("Hiring and firing") {
        test("a coach can be replaced, and the world stays legal") {
            // 02 section 6 makes continuity a resource and section 4.1 sells coordinators poached
            // and replacements hired. Neither was reachable: CoachIntent had seven cases and none
            // concerned staff, so a coach could not hire or fire anybody at all.
            let state = GameState.bootstrap(seed: 93_001)
            let programmeID = state.programmes.ids[0]
            let incumbentID = state.programmes[programmeID]!.staffIDs.first {
                state.staff[$0]?.role == .offensiveCoordinator
            }!
            let candidates = StaffMarketSystem.candidates(
                for: programmeID, role: .offensiveCoordinator, in: state
            )
            expectEqual(candidates.count, PeopleRules.staffCandidatesPerRole)
            expect(candidates.allSatisfy { $0.salary > 0 }, "a candidate would work unpaid")

            let after = try StaffMarketSystem.replace(
                incumbentID: incumbentID, with: candidates[0], at: programmeID, in: state
            )
            expect(after.staff[incumbentID] == nil, "the outgoing coach is still employed")
            expect(after.staff[candidates[0].id] != nil, "the incoming coach was not hired")
            expect(after.programmes[programmeID]!.staffIDs.contains(candidates[0].id),
                   "the new coach is not on the staff list")
            expect(!after.programmes[programmeID]!.staffIDs.contains(incumbentID),
                   "the old coach is still on the staff list")
            // The reason it is a swap and not a firing: whole-root integrity requires complete role
            // coverage, so a world with a vacancy is a world that cannot be saved.
            expect(WorldIntegrity.check(after).isValid,
                   "replacing a coordinator broke the world: \(WorldIntegrity.check(after).issues)")
        }

        test("the money is real") {
            let state = GameState.bootstrap(seed: 93_002)
            let programmeID = state.programmes.ids[0]
            let incumbentID = state.programmes[programmeID]!.staffIDs.first {
                state.staff[$0]?.role == .defensiveCoordinator
            }!
            let candidate = StaffMarketSystem.candidates(
                for: programmeID, role: .defensiveCoordinator, in: state
            )[0]
            let before = state.programmes[programmeID]!.finances(defaultingFor: .college).reserves
            let after = try StaffMarketSystem.replace(
                incumbentID: incumbentID, with: candidate, at: programmeID, in: state
            )
            let remaining = after.programmes[programmeID]!.finances(defaultingFor: .college).reserves
            expect(remaining < before, "hiring somebody cost nothing")
        }

        test("a programme that cannot pay cannot hire") {
            // What makes it a decision rather than a wish.
            var state = GameState.bootstrap(seed: 93_003)
            let programmeID = state.programmes.ids[0]
            _ = state.programmes.update(programmeID) {
                $0.finances = OrganisationFinances(facilities: Rating(60), reserves: 1)
            }
            let incumbentID = state.programmes[programmeID]!.staffIDs.first {
                state.staff[$0]?.role == .strengthCoordinator
            }!
            let candidate = StaffMarketSystem.candidates(
                for: programmeID, role: .strengthCoordinator, in: state
            )[0]
            do {
                _ = try StaffMarketSystem.replace(
                    incumbentID: incumbentID, with: candidate, at: programmeID, in: state
                )
                expect(false, "a programme with one dollar hired a coordinator")
            } catch let error as StaffMarketError {
                guard case .cannotAfford = error else {
                    expect(false, "the refusal was \(error) rather than an affordability one")
                    return
                }
                expect(true)
            }
        }

        test("the coach's own seat is not theirs to fill") {
            let state = GameState.bootstrap(seed: 93_004)
            let programmeID = state.programmes.ids[0]
            let headCoachID = state.programmes[programmeID]!.staffIDs.first {
                state.staff[$0]?.role == .headCoach
            }!
            let candidate = StaffMarketSystem.candidates(
                for: programmeID, role: .headCoach, in: state
            )[0]
            do {
                _ = try StaffMarketSystem.replace(
                    incumbentID: headCoachID, with: candidate, at: programmeID, in: state
                )
                expect(false, "a head coach hired their own replacement")
            } catch let error as StaffMarketError {
                expectEqual(error, .cannotReplaceHeadCoach)
            }
        }

        test("the market is stable for a given world and season") {
            let state = GameState.bootstrap(seed: 93_005)
            let programmeID = state.programmes.ids[0]
            let first = StaffMarketSystem.candidates(for: programmeID, role: .positionCoach,
                                                     positionGroup: .receivers, in: state)
            let second = StaffMarketSystem.candidates(for: programmeID, role: .positionCoach,
                                                      positionGroup: .receivers, in: state)
            expectEqual(first.map(\.id), second.map(\.id),
                        "the market offered different people to the same programme twice")
            let elsewhere = StaffMarketSystem.candidates(for: state.programmes.ids[1],
                                                         role: .positionCoach,
                                                         positionGroup: .receivers, in: state)
            expect(first.map(\.id) != elsewhere.map(\.id),
                   "every programme is offered the same shortlist")
        }
    }
}
