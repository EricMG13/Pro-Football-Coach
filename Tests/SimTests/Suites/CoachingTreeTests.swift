import Foundation
import FootballSimCore

// A coaching tree is the one piece of career history a coach reads about themselves: who they came
// up under, and who came up under them. It is derived, never stored. The authority is the bounded
// staff career record M2 already keeps, and this projection is rebuilt after load exactly like
// WorldHistoryReadModel — a second persisted copy of the same facts is a second authority that can
// disagree with the first.

/// One bootstrapped world, shared. Every test here swaps in its own career records; only the staff
/// identities and their names come from the world, and generating it per test bought nothing.
private let coachingTreeWorld: GameState = GameState.bootstrap(seed: 70_401)

func runCoachingTreeTests() {
    suite("Coaching tree: derivation") {
        test("an assistant who later became a head coach is a disciple of who they served under") {
            let cast = coachingTreeCast(count: 2)
            let organisation = coachingTreeWorld.programmes.ids[0]
            let state = coachingTreeState(careers: [
                StaffCareerRecord(staffID: cast[0], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: cast[1], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .offensiveCoordinator),
                    StaffCareerAssignment(season: 2029, organisationID: coachingTreeWorld.programmes.ids[1], role: .headCoach),
                ]),
            ])
            let tree = CoachingTreeReadModel.build(from: state)
            expectEqual(tree.branches.count, 1)
            expectEqual(tree.branches[0].mentorID, cast[0])
            expectEqual(tree.branches[0].disciples.count, 1)
            expectEqual(tree.branches[0].disciples[0].staffID, cast[1])
            expectEqual(tree.branches[0].disciples[0].sharedSeason, 2027)
            expectEqual(tree.branches[0].disciples[0].roleUnderMentor, StaffRole.offensiveCoordinator)
            expectEqual(tree.branches[0].disciples[0].firstHeadCoachSeason, 2029)
        }

        test("the branch and disciple carry the names the world knows") {
            let cast = coachingTreeCast(count: 2)
            let organisation = coachingTreeWorld.programmes.ids[0]
            let state = coachingTreeState(careers: [
                StaffCareerRecord(staffID: cast[0], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: cast[1], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .positionCoach),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .headCoach),
                ]),
            ])
            let tree = CoachingTreeReadModel.build(from: state)
            expectEqual(tree.branches[0].mentorName, coachingTreeWorld.staff[cast[0]]?.fullName)
            expectEqual(tree.branches[0].disciples[0].name, coachingTreeWorld.staff[cast[1]]?.fullName)
        }

        test("an assistant who never became a head coach is not a disciple") {
            let cast = coachingTreeCast(count: 2)
            let organisation = coachingTreeWorld.programmes.ids[0]
            let state = coachingTreeState(careers: [
                StaffCareerRecord(staffID: cast[0], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: cast[1], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .positionCoach),
                ]),
            ])
            expect(CoachingTreeReadModel.build(from: state).branches.isEmpty,
                   "a tree with no head-coaching descendant is not a tree")
        }

        test("a coach is never their own mentor") {
            let cast = coachingTreeCast(count: 1)
            let organisation = coachingTreeWorld.programmes.ids[0]
            let state = coachingTreeState(careers: [
                StaffCareerRecord(staffID: cast[0], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .positionCoach),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .headCoach),
                ]),
            ])
            expect(CoachingTreeReadModel.build(from: state).branches.isEmpty,
                   "one coach promoted in place is not a mentor relationship")
        }

        test("serving under the same head coach for years is one relationship, dated to the first") {
            let cast = coachingTreeCast(count: 2)
            let organisation = coachingTreeWorld.programmes.ids[0]
            let state = coachingTreeState(careers: [
                StaffCareerRecord(staffID: cast[0], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: cast[1], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .defensiveCoordinator),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .offensiveCoordinator),
                    StaffCareerAssignment(season: 2030, organisationID: coachingTreeWorld.programmes.ids[1], role: .headCoach),
                ]),
            ])
            let branches = CoachingTreeReadModel.build(from: state).branches
            expectEqual(branches[0].disciples.count, 1)
            expectEqual(branches[0].disciples[0].sharedSeason, 2027)
            expectEqual(branches[0].disciples[0].roleUnderMentor, StaffRole.defensiveCoordinator)
        }

        test("a coach who served under two head coaches appears in both trees") {
            let cast = coachingTreeCast(count: 3)
            let first = coachingTreeWorld.programmes.ids[0]
            let second = coachingTreeWorld.programmes.ids[1]
            let state = coachingTreeState(careers: [
                StaffCareerRecord(staffID: cast[0], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: first, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: cast[1], assignments: [
                    StaffCareerAssignment(season: 2028, organisationID: second, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: cast[2], assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: first, role: .positionCoach),
                    StaffCareerAssignment(season: 2028, organisationID: second, role: .defensiveCoordinator),
                    StaffCareerAssignment(season: 2031, organisationID: first, role: .headCoach),
                ]),
            ])
            let branches = CoachingTreeReadModel.build(from: state).branches
            expectEqual(branches.count, 2)
            expect(branches.allSatisfy { $0.disciples.map(\.staffID) == [cast[2]] })
        }

        test("a world with no recorded careers has no tree") {
            expect(CoachingTreeReadModel.build(from: coachingTreeState(careers: [])).branches.isEmpty)
        }
    }

    suite("Coaching tree: determinism and bounds") {
        test("two builds of the same state are identical") {
            let state = coachingTreeStateAtScale(mentors: 12, disciplesPerMentor: 3)
            expectEqual(
                CoachingTreeReadModel.build(from: state),
                CoachingTreeReadModel.build(from: state)
            )
        }

        test("the projection is bounded on both axes") {
            let state = coachingTreeStateAtScale(mentors: 400, disciplesPerMentor: 20)
            let tree = CoachingTreeReadModel.build(from: state)
            expect(tree.branches.count <= CoachingTreeReadModel.maximumBranches,
                   "branch count \(tree.branches.count) exceeds its bound")
            expect(
                tree.branches.allSatisfy {
                    $0.disciples.count <= CoachingTreeReadModel.maximumDisciplesPerBranch
                },
                "a branch exceeded its disciple bound"
            )
        }

        test("truncation keeps the deepest trees, not whichever the dictionary listed first") {
            let state = coachingTreeStateAtScale(
                mentors: CoachingTreeReadModel.maximumBranches + 40,
                disciplesPerMentor: 2
            )
            let tree = CoachingTreeReadModel.build(from: state)
            expectEqual(tree.branches.count, CoachingTreeReadModel.maximumBranches)
            let counts = tree.branches.map(\.disciples.count)
            expectEqual(counts, counts.sorted(by: >),
                        "branches must be ordered deepest first before the bound is applied")
            expect(counts.contains(2) && counts.contains(1),
                   "the fixture must mix depths or this assertion proves nothing")
            expectEqual(counts.firstIndex(of: 1), counts.lastIndex(of: 2).map { $0 + 1 },
                        "every two-disciple branch must survive ahead of every one-disciple branch")
        }
    }
}

private func coachingTreeCast(count: Int) -> [UUID] {
    Array(coachingTreeWorld.staff.ids.sorted { $0.uuidString < $1.uuidString }.prefix(count))
}

private func coachingTreeState(careers: [StaffCareerRecord]) -> GameState {
    var state = coachingTreeWorld
    state.people = PeopleState(staffCareers: careers)
    return state
}

/// A world of `mentors` head coaches whose former assistants went on to head-coaching jobs of their
/// own. Every identity is drawn from the bootstrapped staff, so the fixture is reproducible without
/// inventing UUIDs.
///
/// Depth alternates between `disciplesPerMentor` and one, deliberately. A fixture where every branch
/// is the same depth makes "truncation keeps the deepest" vacuously true, which is the kind of test
/// that reads as coverage and asserts nothing.
private func coachingTreeStateAtScale(mentors: Int, disciplesPerMentor: Int) -> GameState {
    let staffIDs = coachingTreeWorld.staff.ids.sorted { $0.uuidString < $1.uuidString }
    let organisationIDs = coachingTreeWorld.programmes.ids
    var careers: [StaffCareerRecord] = []
    var next = 0

    func take() -> UUID? {
        guard next < staffIDs.count else { return nil }
        defer { next += 1 }
        return staffIDs[next]
    }

    for mentorIndex in 0..<mentors {
        guard let mentorID = take() else { break }
        let seat = organisationIDs[mentorIndex % organisationIDs.count]
        // Each mentor gets their own season as well as their own seat, so two mentors can never
        // contend for the same seat and silently collapse into one branch.
        let season = 2000 + mentorIndex
        careers.append(StaffCareerRecord(staffID: mentorID, assignments: [
            StaffCareerAssignment(season: season, organisationID: seat, role: .headCoach),
        ]))
        let depth = mentorIndex.isMultiple(of: 2) ? disciplesPerMentor : 1
        for _ in 0..<depth {
            guard let discipleID = take() else { break }
            careers.append(StaffCareerRecord(staffID: discipleID, assignments: [
                StaffCareerAssignment(season: season, organisationID: seat, role: .positionCoach),
                StaffCareerAssignment(
                    season: season + 3,
                    organisationID: organisationIDs[(mentorIndex + 1) % organisationIDs.count],
                    role: .headCoach
                ),
            ]))
        }
    }
    return coachingTreeState(careers: careers)
}
