import Foundation
import FootballSimCore

func runStaffCareerTests() {
    suite("Staff careers") {
        test("a coach's career record can record a move, in order and bounded") {
            // There was no way to add one: `assignments` is private(set) and only `insert(staff:)`
            // ever wrote it, which was true enough while nobody in the world changed jobs.
            let staffID = UUID(uuidString: "00000000-0000-4000-B700-000000000001")!
            let first = UUID(uuidString: "00000000-0000-4000-B700-000000000010")!
            let second = UUID(uuidString: "00000000-0000-4000-B700-000000000011")!
            var record = StaffCareerRecord(
                staffID: staffID,
                assignments: [StaffCareerAssignment(season: 3, organisationID: first,
                                                    role: .offensiveCoordinator)]
            )
            expect(record.append(StaffCareerAssignment(season: 4, organisationID: second,
                                                       role: .offensiveCoordinator)),
                   "a legal move was refused")
            expectEqual(record.assignments.count, 2)
            expectEqual(record.assignments.last?.organisationID, second)
            expect(!record.append(StaffCareerAssignment(season: 2, organisationID: first,
                                                        role: .offensiveCoordinator)),
                   "a career went backwards in time")

            for season in 5...(PeopleRules.careerSeasonHistoryLimit + 10) {
                record.append(StaffCareerAssignment(season: season, organisationID: first,
                                                    role: .offensiveCoordinator))
            }
            expectEqual(record.assignments.count, PeopleRules.careerSeasonHistoryLimit,
                        "a career history grew past its bound")
        }

        test("coaches develop, bounded and deterministically") {
            let state = GameState.bootstrap(seed: 62_001)
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let first = StaffDevelopmentSystem.process(after: boundary, in: state)
            let second = StaffDevelopmentSystem.process(after: boundary, in: state)
            expectEqual(first.changes.map(\.staffID), second.changes.map(\.staffID),
                        "the same season developed different coaches twice")
            expectEqual(first.staff, second.staff, "two identical seasons produced different staff")

            expect(!first.changes.isEmpty, "a whole season developed nobody, so the model is inert")
            for change in first.changes {
                expect((-1...1).contains(change.delta),
                       "a coach moved \(change.delta) points in one season")
                expect(abs(change.reputationDelta) <= PeopleRules.staffReputationStep,
                       "a reputation moved further in one season than the rules allow")
                guard let before = state.staff[change.staffID],
                      let after = first.staff[change.staffID] else {
                    expect(false, "a change names a coach who does not exist")
                    continue
                }
                expectEqual(after.rating(change.attribute).value,
                            before.rating(change.attribute).value + change.delta)
                expect(SharedRules.ratingRange.contains(after.rating(change.attribute).value),
                       "a coach developed outside the rating scale")
                expect(SharedRules.ratingRange.contains(after.reputation.value))
                // Nothing else about them moved.
                expectEqual(after.age, before.age)
                expectEqual(after.role, before.role)
                expectEqual(after.positionGroup, before.positionGroup)
            }
        }

        test("standing comes from the archive, because the table has already rolled over") {
            let state = GameState.bootstrap(seed: 62_002)
            guard let staffID = state.programmes.values.first?.staffIDs.first else {
                expect(false, "a bootstrapped world has no staff")
                return
            }
            // No season archived yet: nobody has had a good or bad season, and the system says so
            // rather than inventing one.
            expect(StaffDevelopmentSystem.employerStanding(of: staffID, in: state) == nil,
                   "a coach had a season before any season was played")
            expect(StaffDevelopmentSystem.employer(of: staffID, in: state) != nil,
                   "an employed coach has no employer")
        }

        test("a poaching leaves every organisation with exactly one coach per role") {
            // The invariant that shapes the whole system: whole-root integrity requires complete
            // role coverage, so a move that left a hole is a world that cannot be saved.
            var state = GameState.bootstrap(seed: 62_003)
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            // Make somebody worth taking. A generated world's coordinators sit below the poachable
            // threshold, so without this the market correctly does nothing and tests nothing.
            let programmes = state.programmes.values.sorted { $0.prestige > $1.prestige }
            guard programmes.count > 2,
                  let weakest = programmes.last,
                  let target = weakest.staffIDs.first(where: {
                      state.staff[$0]?.role == .offensiveCoordinator
                  }) else {
                expect(false, "a bootstrapped world has no coordinator to poach")
                return
            }
            state.staff.update(target) { $0.reputation = Rating(95) }

            let transition = StaffPoachingSystem.process(after: boundary, in: state)
            expect(WorldIntegrity.check(transition.state).isValid,
                   "poaching produced a world that cannot be saved")
            expect(!transition.poachings.isEmpty,
                   "a 95-reputation coordinator at the weakest programme was wanted by nobody")
            expect(transition.poachings.count <= PeopleRules.maximumPoachingsPerSeason,
                   "the offseason moved more coaches than the bound allows")

            for poaching in transition.poachings {
                let gained = organisationStaffIDs(poaching.toOrganisationID, in: transition.state)
                let lost = organisationStaffIDs(poaching.fromOrganisationID, in: transition.state)
                expect(gained.contains(poaching.staffID), "the poached coach never arrived")
                expect(!lost.contains(poaching.staffID), "the poached coach is in both places")
                expect(!gained.contains(poaching.displacedStaffID),
                       "the displaced coach is still in the job")
                expect(lost.contains(poaching.replacementStaffID),
                       "the raided organisation never hired anybody")
                // The career record follows the person, which is what a coaching tree reads.
                expectEqual(
                    transition.state.people.staffCareers[poaching.staffID]?
                        .assignments.last?.organisationID,
                    poaching.toOrganisationID,
                    "a coach's record still names the club they left"
                )
                // Unemployed, not deleted: their record would otherwise be orphaned.
                expect(transition.state.staff[poaching.displacedStaffID] != nil,
                       "the displaced coach was deleted along with their career")
            }
        }

        test("nobody ordinary is poached, and a head coach never is") {
            let state = GameState.bootstrap(seed: 62_004)
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let transition = StaffPoachingSystem.process(after: boundary, in: state)
            for poaching in transition.poachings {
                guard let member = transition.state.staff[poaching.staffID] else { continue }
                expect(member.role != .headCoach,
                       "a head coach was poached out of their own seat rather than by the carousel")
            }
            // Deterministic: the same world raids the same clubs.
            let again = StaffPoachingSystem.process(after: boundary, in: state)
            expectEqual(transition.poachings.map(\.staffID), again.poachings.map(\.staffID),
                        "the same offseason moved different coaches twice")
        }

        test("hiring a coach leaves a world that can be saved") {
            // The defect this test exists for: `replace` removed the outgoing coach from the store
            // while their career record stayed behind, and gave the incoming coach no record at
            // all, so every hire produced an invalid root and nothing asserted otherwise.
            let state = GameState.bootstrap(seed: 62_005)
            guard let programme = state.programmes.values.first,
                  let incumbentID = programme.staffIDs.first(where: {
                      state.staff[$0]?.role == .specialTeamsCoordinator
                  }) else {
                expect(false, "a bootstrapped programme has no coordinator")
                return
            }
            let shortlist = StaffMarketSystem.candidates(
                for: programme.id,
                role: .specialTeamsCoordinator,
                in: state
            )
            guard let candidate = shortlist.first else {
                expect(false, "the shortlist is empty")
                return
            }
            do {
                let hired = try StaffMarketSystem.replace(
                    incumbentID: incumbentID,
                    with: candidate,
                    at: programme.id,
                    in: state
                )
                let report = WorldIntegrity.check(hired)
                expect(report.isValid,
                       "hiring produced an invalid root: \(report.issues.prefix(3))")
                expect(hired.people.staffCareers[candidate.staff.id] != nil,
                       "the new coach has no career record")
                expect(hired.staff[incumbentID] != nil,
                       "the outgoing coach was deleted and their career orphaned")
                expect(hired.programmes[programme.id]?.staffIDs.contains(incumbentID) == false,
                       "the outgoing coach still holds the job")
            } catch StaffMarketError.cannotAfford {
                // A programme that cannot pay is a legal outcome and not what this test is about.
                expect(true)
            } catch {
                expect(false, "a legal hire threw: \(error)")
            }
        }
    }
}

private func organisationStaffIDs(_ organisationID: UUID, in state: GameState) -> [UUID] {
    state.programmes[organisationID]?.staffIDs
        ?? state.proTeams[organisationID]?.staffIDs
        ?? []
}
