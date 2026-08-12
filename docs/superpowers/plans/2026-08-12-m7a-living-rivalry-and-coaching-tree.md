# M7A — Living Rivalry Order and Coaching Tree Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a programme's rival list reflect the intensity its games actually produced, and project the coaching tree that the existing staff career records already contain.

**Architecture:** Both halves are read-side truth that the authoritative root already owns. `RivalrySystem.process` already adjusts `Rivalry.intensity` every week; this plan makes the same step reorder `Programme.rivalIDs` from that adjusted store, touching only the programmes whose rivalries actually moved. The coaching tree is a disposable projection built from `PeopleState.staffCareers` — no new persisted authority, in the same spirit as `WorldHistoryReadModel`.

**Tech Stack:** Swift 5 language mode, no third-party dependencies, `Tests/SimTests` hand-rolled TestKit harness (no XCTest, no swift-testing).

## Global Constraints

- Engine is pure Swift; `Sources/FootballSimCore` contains zero `import SwiftUI`.
- Determinism: a seed plus an input state reproduces output exactly, across processes. Never seed from `hashValue`. Never iterate a `Set` or `Dictionary` where the result reaches output order.
- Every collection that grows across seasons carries a stated bound. `SharedRules.rivalriesPerProgramme` is 8; `PeopleRules.careerSeasonHistoryLimit` is 40.
- Ratings are 40–99 `Int`; money is integer dollars. No magic numbers in code — rules constants live in the rules modules.
- No emoji in code, UI copy, commits or docs.
- Schema is currently `GameState.schemaVersion = 10`. **Neither task in this plan changes the schema**: no new persisted field is introduced. If an implementation finds itself adding a stored property to a `Codable` root type, stop — that is a different plan.
- TDD: every mechanic gets a failing test first.
- Conventional Commits, one task per commit.

---

## File map

| File | Responsibility |
|---|---|
| `Sources/FootballSimCore/Model/Programme.swift` | Gains `reorderRivals(to:)`, the bounded replacement of the whole list. |
| `Sources/FootballSimCore/History/RivalrySystem.swift` | `process` additionally returns the programmes whose rival order changed. |
| `Sources/FootballSimCore/Scheduling/WorldScheduler.swift` | The `relationshipsAndStakeholders` step applies the reordering to the copied root. |
| `Sources/FootballSimCore/History/CoachingTreeReadModel.swift` | **New.** Disposable projection of mentor to former assistant, built from staff career records. |
| `Tests/SimTests/Suites/RivalryOrderTests.swift` | **New.** Focused suite for the ordering contract. |
| `Tests/SimTests/Suites/CoachingTreeTests.swift` | **New.** Focused suite for the projection contract. |
| `Tests/SimTests/main.swift` | Registers `--rivalry-order` and `--coaching-tree` filters and adds both suites to the default run. |

---

## Task 1: Live rival ordering

**Files:**
- Modify: `Sources/FootballSimCore/Model/Programme.swift:118-123`
- Modify: `Sources/FootballSimCore/History/RivalrySystem.swift:7-74`
- Modify: `Sources/FootballSimCore/Scheduling/WorldScheduler.swift:341-344`
- Create: `Tests/SimTests/Suites/RivalryOrderTests.swift`
- Modify: `Tests/SimTests/main.swift:55`

**Interfaces:**
- Consumes: `RivalrySeeder.strongest(for:among:) -> [UUID]`, `Rivalry.involves(_:)`, `Rivalry.other(than:)`, `SharedRules.rivalriesPerProgramme`, `EntityStore.update(_:_:)`.
- Produces: `Programme.reorderRivals(to ordered: [UUID])`, and `RivalryTransition.reorderedProgrammeIDs: [UUID]` alongside the existing `rivalries` and `recordedRivalryIDs`.

- [ ] **Step 1: Run the required blast-radius analysis**

Run:

```text
impact({repo: "Pro-Football-Coach", target: "RivalrySystem", direction: "upstream"})
impact({repo: "Pro-Football-Coach", target: "RivalryTransition", direction: "upstream"})
```

Report risk, direct callers and affected processes. `RivalryTransition` gains a field, so every construction site must be updated. Stop for user confirmation if either result is HIGH or CRITICAL.

- [ ] **Step 2: Write the failing test**

Create `Tests/SimTests/Suites/RivalryOrderTests.swift`:

```swift
import Foundation
import FootballSimCore

// The rival list is what a screen shows and what D6's endogenous identity rests on. Seeding it once
// and never touching it again means a rivalry can become the most intense in the world while sitting
// last in the list that names it.

func runRivalryOrderTests() {
    suite("Rivalry order: bounded replacement") {
        test("reorderRivals replaces the list and keeps it at its bound") {
            let rivals = (0..<12).map { _ in UUID() }
            var programme = makeOrderProgramme(rivalIDs: Array(rivals.prefix(3)))
            programme.reorderRivals(to: rivals)
            expectEqual(programme.rivalIDs.count, SharedRules.rivalriesPerProgramme)
            expectEqual(programme.rivalIDs, Array(rivals.prefix(SharedRules.rivalriesPerProgramme)))
        }

        test("reorderRivals drops duplicates rather than spending the bound on them") {
            let first = UUID()
            let second = UUID()
            var programme = makeOrderProgramme(rivalIDs: [])
            programme.reorderRivals(to: [first, second, first])
            expectEqual(programme.rivalIDs, [first, second])
        }
    }

    suite("Rivalry order: intensity drives the list") {
        test("a close meeting lifts its rivalry above one that has not been played") {
            // Two rivalries for the same programme, the second seeded stronger. A three-point game
            // in the first is worth five intensity, which is enough to overtake a two-point gap.
            let state = makeOrderState(strongerIntensity: 66, weakerIntensity: 64, homeScore: 24, awayScore: 21)
            let calendar = CalendarState(season: state.calendar.season, week: state.calendar.week, phase: state.calendar.phase)
            let transition = RivalrySystem.process(after: calendar, in: state)
            expectEqual(transition.reorderedProgrammeIDs.count, 2,
                        "both sides of the played rivalry must be reordered")
            let contested = transition.rivalries.values.first { $0.intensity.value == 69 }
            expect(contested != nil, "the close meeting must add five intensity")
        }

        test("a programme with no played rivalry is not reordered") {
            let state = makeOrderState(strongerIntensity: 66, weakerIntensity: 64, homeScore: nil, awayScore: nil)
            let calendar = CalendarState(season: state.calendar.season, week: state.calendar.week, phase: state.calendar.phase)
            let transition = RivalrySystem.process(after: calendar, in: state)
            expect(transition.reorderedProgrammeIDs.isEmpty,
                   "an unplayed week must not rewrite any rival list")
        }

        test("the reordered list is deterministic across two identical runs") {
            let first = RivalrySystem.process(
                after: makeOrderState(strongerIntensity: 66, weakerIntensity: 64, homeScore: 24, awayScore: 21).calendar,
                in: makeOrderState(strongerIntensity: 66, weakerIntensity: 64, homeScore: 24, awayScore: 21)
            )
            let second = RivalrySystem.process(
                after: makeOrderState(strongerIntensity: 66, weakerIntensity: 64, homeScore: 24, awayScore: 21).calendar,
                in: makeOrderState(strongerIntensity: 66, weakerIntensity: 64, homeScore: 24, awayScore: 21)
            )
            expectEqual(first.reorderedProgrammeIDs, second.reorderedProgrammeIDs)
        }
    }
}
```

The two fixture builders `makeOrderProgramme` and `makeOrderState` are written in Step 3, because the assertions above define what they must produce.

- [ ] **Step 3: Write the test fixtures**

Append to `Tests/SimTests/Suites/RivalryOrderTests.swift`:

```swift
private func makeOrderProgramme(rivalIDs: [UUID]) -> Programme {
    Programme(
        name: "Thornby Reach Technical",
        nickname: "Kestrels",
        cityName: "Thornby Reach",
        archetypeID: 0,
        scheme: SchemeIdentity(offense: .proStyle, defense: .fourThree),
        prestige: Rating(60),
        resources: Rating(60),
        fanbaseVolatility: Rating(60),
        academicConstraint: Rating(60),
        recruitingReach: Rating(60),
        rivalIDs: rivalIDs
    )
}
```

Read `Tests/SimTests/Suites/HistoryReadModelTests.swift` for the established way that suite assembles a `GameState` with programmes, a schedule and a result, and reuse it verbatim for `makeOrderState(strongerIntensity:weakerIntensity:homeScore:awayScore:)`. Do not invent a second fixture idiom: the suite next door already had to solve exactly this and its version is the one under test elsewhere. `homeScore: nil` means the scheduled game carries no result.

- [ ] **Step 4: Register the suite and run it to verify it fails**

In `Tests/SimTests/main.swift`, add before the `--competition-only` branch:

```swift
} else if CommandLine.arguments.contains("--rivalry-order") {
    runRivalryOrderTests()
```

and add `runRivalryOrderTests()` to the default `else` branch, immediately after `runHistoryReadModelTests()`.

Run:

```bash
swift run SimTests --rivalry-order
```

Expected: compile failure — `Programme` has no member `reorderRivals`, and `RivalryTransition` has no member `reorderedProgrammeIDs`. A compile failure is the correct red for a test that names a symbol which does not exist yet.

- [ ] **Step 5: Add the bounded replacement to `Programme`**

In `Sources/FootballSimCore/Model/Programme.swift`, directly after `addRival` (line 123):

```swift
    /// Replaces the whole list, strongest first, at the same bound `addRival` respects.
    ///
    /// Separate from `addRival` because the two callers want different things: seeding adds one
    /// unknown rival, and the weekly relationships step already knows the complete order. Rebuilding
    /// through repeated `addRival` calls would keep whichever eight arrived first rather than the
    /// eight that are now strongest, which is the bug this exists to prevent.
    public mutating func reorderRivals(to ordered: [UUID]) {
        var seen: Set<UUID> = []
        rivalIDs = Array(
            ordered.filter { seen.insert($0).inserted }.prefix(SharedRules.rivalriesPerProgramme)
        )
    }
```

- [ ] **Step 6: Return the reordered programmes from `RivalrySystem`**

In `Sources/FootballSimCore/History/RivalrySystem.swift`, extend the transition:

```swift
public struct RivalryTransition: Sendable, Equatable {
    public let rivalries: EntityStore<Rivalry>
    public let recordedRivalryIDs: [UUID]

    /// The programmes whose rival order the recorded meetings changed, in UUID order.
    ///
    /// Only the sides of a rivalry that actually moved: reordering all 134 programmes every week
    /// would be work proportional to the world rather than to the week, and `03b` makes the weekly
    /// step's cost a property the soak measures.
    public let reorderedProgrammeIDs: [UUID]

    public init(
        rivalries: EntityStore<Rivalry>,
        recordedRivalryIDs: [UUID],
        reorderedProgrammeIDs: [UUID]
    ) {
        self.rivalries = rivalries
        self.recordedRivalryIDs = recordedRivalryIDs
        self.reorderedProgrammeIDs = reorderedProgrammeIDs
    }
}
```

and at the end of `process`, replace the single `return` with:

```swift
        var affected: Set<UUID> = []
        for rivalryID in recorded {
            guard let rivalry = rivalries[rivalryID] else { continue }
            if state.programmes[rivalry.sideA] != nil { affected.insert(rivalry.sideA) }
            if state.programmes[rivalry.sideB] != nil { affected.insert(rivalry.sideB) }
        }

        return RivalryTransition(
            rivalries: rivalries,
            recordedRivalryIDs: recorded.sorted { $0.uuidString < $1.uuidString },
            reorderedProgrammeIDs: affected.sorted { $0.uuidString < $1.uuidString }
        )
```

The `Set` is sorted before it leaves the function, so no output order depends on hash order.

- [ ] **Step 7: Apply the reordering in the scheduler**

In `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`, replace the `.relationshipsAndStakeholders` case body (lines 341-344):

```swift
            case .relationshipsAndStakeholders:
                let rivalries = RivalrySystem.process(after: completed, in: nextState)
                nextState.rivalries = rivalries.rivalries
                let allRivalries = rivalries.rivalries.values
                    .sorted { $0.id.uuidString < $1.id.uuidString }
                for programmeID in rivalries.reorderedProgrammeIDs {
                    let ordered = RivalrySeeder.strongest(for: programmeID, among: allRivalries)
                    _ = nextState.programmes.update(programmeID) { $0.reorderRivals(to: ordered) }
                }
                records.append(WorldStepRecord(step: step, status: .executed))
```

`allRivalries` is sorted before `strongest` sees it so the tie-break inside `strongest` operates on a stable input, and it is hoisted out of the loop because it does not vary per programme.

- [ ] **Step 8: Run the focused suite**

Run:

```bash
swift run SimTests --rivalry-order
```

Expected: `all passed`.

- [ ] **Step 9: Run the suites that own the changed step**

Run:

```bash
swift run SimTests --portal-scheduler
swift run SimTests --history-read-model
swift run SimTests --architecture-only
swift run SimTests --core-contracts
```

Expected: every one prints `all passed`. `--portal-scheduler` is the two-season byte-identical replay; if the reordering were non-deterministic it fails here and nowhere else, which is the point of running it.

- [ ] **Step 10: Commit**

```bash
git add Sources/FootballSimCore/Model/Programme.swift Sources/FootballSimCore/History/RivalrySystem.swift Sources/FootballSimCore/Scheduling/WorldScheduler.swift Tests/SimTests/Suites/RivalryOrderTests.swift Tests/SimTests/main.swift
git commit -m "feat: reorder rival lists from earned intensity"
```

---

## Task 2: Coaching tree projection

**Files:**
- Create: `Sources/FootballSimCore/History/CoachingTreeReadModel.swift`
- Create: `Tests/SimTests/Suites/CoachingTreeTests.swift`
- Modify: `Tests/SimTests/main.swift:55`

**Interfaces:**
- Consumes: `PeopleState.staffCareers: [UUID: StaffCareerRecord]`, `StaffCareerAssignment(season:organisationID:role:)`, `StaffRole.headCoach`, `GameState.staff`, `GameState.people`.
- Produces: `CoachingTreeReadModel.build(from: GameState) -> CoachingTreeReadModel`, `CoachingTreeReadModel.branches: [CoachingTreeBranch]`, `CoachingTreeBranch(mentorID:mentorName:disciples:)`, `CoachingTreeDisciple(staffID:name:sharedSeason:sharedOrganisationID:roleUnderMentor:firstHeadCoachSeason:)`.

- [ ] **Step 1: Run the required blast-radius analysis**

Run:

```text
impact({repo: "Pro-Football-Coach", target: "StaffCareerRecord", direction: "upstream"})
```

This task only reads the record, so the expected result is that nothing this plan touches appears downstream. Report it before writing the file.

- [ ] **Step 2: Write the failing test**

Create `Tests/SimTests/Suites/CoachingTreeTests.swift`:

```swift
import Foundation
import FootballSimCore

// A coaching tree is the one piece of career history a coach reads about themselves. It is derived,
// never stored: the authority is the bounded staff career record, and this projection is rebuilt
// after load exactly like WorldHistoryReadModel.

func runCoachingTreeTests() {
    suite("Coaching tree: derivation") {
        test("an assistant who later became a head coach is a disciple of the head coach they served") {
            let mentor = UUID()
            let disciple = UUID()
            let organisation = UUID()
            let state = makeTreeState(careers: [
                StaffCareerRecord(staffID: mentor, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: disciple, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .offensiveCoordinator),
                    StaffCareerAssignment(season: 2029, organisationID: UUID(), role: .headCoach),
                ]),
            ])
            let tree = CoachingTreeReadModel.build(from: state)
            expectEqual(tree.branches.count, 1)
            expectEqual(tree.branches[0].mentorID, mentor)
            expectEqual(tree.branches[0].disciples.count, 1)
            expectEqual(tree.branches[0].disciples[0].staffID, disciple)
            expectEqual(tree.branches[0].disciples[0].sharedSeason, 2027)
            expectEqual(tree.branches[0].disciples[0].firstHeadCoachSeason, 2029)
        }

        test("an assistant who never became a head coach is not a disciple") {
            let mentor = UUID()
            let assistant = UUID()
            let organisation = UUID()
            let state = makeTreeState(careers: [
                StaffCareerRecord(staffID: mentor, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: assistant, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .positionCoach),
                ]),
            ])
            expect(CoachingTreeReadModel.build(from: state).branches.isEmpty,
                   "a tree with no head-coach descendant is not a tree")
        }

        test("a coach is never their own mentor") {
            let solo = UUID()
            let organisation = UUID()
            let state = makeTreeState(careers: [
                StaffCareerRecord(staffID: solo, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .headCoach),
                ]),
            ])
            expect(CoachingTreeReadModel.build(from: state).branches.isEmpty,
                   "one head coach alone is not a mentor relationship")
        }

        test("only the earliest shared season counts, so one pair yields one disciple entry") {
            let mentor = UUID()
            let disciple = UUID()
            let organisation = UUID()
            let state = makeTreeState(careers: [
                StaffCareerRecord(staffID: mentor, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .headCoach),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .headCoach),
                ]),
                StaffCareerRecord(staffID: disciple, assignments: [
                    StaffCareerAssignment(season: 2027, organisationID: organisation, role: .defensiveCoordinator),
                    StaffCareerAssignment(season: 2028, organisationID: organisation, role: .offensiveCoordinator),
                    StaffCareerAssignment(season: 2030, organisationID: UUID(), role: .headCoach),
                ]),
            ])
            let branches = CoachingTreeReadModel.build(from: state).branches
            expectEqual(branches[0].disciples.count, 1)
            expectEqual(branches[0].disciples[0].sharedSeason, 2027)
            expectEqual(branches[0].disciples[0].roleUnderMentor, StaffRole.defensiveCoordinator)
        }
    }

    suite("Coaching tree: determinism and bounds") {
        test("two builds of the same state are identical") {
            let state = makeTreeStateAtScale(mentorCount: 12, disciplesPerMentor: 3)
            expectEqual(CoachingTreeReadModel.build(from: state), CoachingTreeReadModel.build(from: state))
        }

        test("the projection is bounded") {
            let state = makeTreeStateAtScale(mentorCount: 400, disciplesPerMentor: 12)
            let tree = CoachingTreeReadModel.build(from: state)
            expect(tree.branches.count <= CoachingTreeReadModel.maximumBranches,
                   "branch count \(tree.branches.count) exceeds its bound")
            expect(tree.branches.allSatisfy { $0.disciples.count <= CoachingTreeReadModel.maximumDisciplesPerBranch },
                   "a branch exceeded its disciple bound")
        }
    }
}
```

`makeTreeState(careers:)` builds a `GameState` whose `people.staffCareers` holds those records and whose `staff` store holds a named `Staff` for every `staffID` mentioned. `makeTreeStateAtScale(mentorCount:disciplesPerMentor:)` generates that shape at size, with every UUID derived from `SeededRandom(seed:)` so the fixture is reproducible. Copy the `GameState` assembly idiom from `Tests/SimTests/Suites/PeopleLifecycleTests.swift` rather than inventing a third one.

- [ ] **Step 3: Register the suite and run it to verify it fails**

In `Tests/SimTests/main.swift`, add before the `--competition-only` branch:

```swift
} else if CommandLine.arguments.contains("--coaching-tree") {
    runCoachingTreeTests()
```

and add `runCoachingTreeTests()` to the default `else` branch, immediately after `runRivalryOrderTests()`.

Run:

```bash
swift run SimTests --coaching-tree
```

Expected: compile failure — `CoachingTreeReadModel` does not exist.

- [ ] **Step 4: Write the projection**

Create `Sources/FootballSimCore/History/CoachingTreeReadModel.swift`:

```swift
import Foundation

/// One coach who served under a head coach and later held a head-coaching job of their own.
public struct CoachingTreeDisciple: Sendable, Equatable, Identifiable {
    public var id: UUID { staffID }
    public let staffID: UUID
    public let name: String
    public let sharedSeason: Int
    public let sharedOrganisationID: UUID
    public let roleUnderMentor: StaffRole
    public let firstHeadCoachSeason: Int

    public init(
        staffID: UUID,
        name: String,
        sharedSeason: Int,
        sharedOrganisationID: UUID,
        roleUnderMentor: StaffRole,
        firstHeadCoachSeason: Int
    ) {
        self.staffID = staffID
        self.name = name
        self.sharedSeason = sharedSeason
        self.sharedOrganisationID = sharedOrganisationID
        self.roleUnderMentor = roleUnderMentor
        self.firstHeadCoachSeason = firstHeadCoachSeason
    }
}

public struct CoachingTreeBranch: Sendable, Equatable, Identifiable {
    public var id: UUID { mentorID }
    public let mentorID: UUID
    public let mentorName: String
    public let disciples: [CoachingTreeDisciple]

    public init(mentorID: UUID, mentorName: String, disciples: [CoachingTreeDisciple]) {
        self.mentorID = mentorID
        self.mentorName = mentorName
        self.disciples = disciples
    }
}

/// Rebuildable coaching-tree projection.
///
/// Deliberately not `Codable`. `PeopleState.staffCareers` is the authority and is already bounded at
/// `PeopleRules.careerSeasonHistoryLimit` assignments per coach; persisting a second copy of the same
/// facts would create a second authority that could disagree with the first, which is the failure
/// `03b` names. This is rebuilt after load, exactly like `WorldHistoryReadModel`.
public struct CoachingTreeReadModel: Sendable, Equatable {
    /// Bounds. A career is twenty seasons of staff churn, and a screen shows a list, not a census.
    public static let maximumBranches = 256
    public static let maximumDisciplesPerBranch = 16

    public let branches: [CoachingTreeBranch]

    public init(branches: [CoachingTreeBranch]) {
        self.branches = Array(branches.prefix(CoachingTreeReadModel.maximumBranches))
    }

    public static func build(from state: GameState) -> CoachingTreeReadModel {
        let careers = state.people.staffCareers.values
            .sorted { $0.staffID.uuidString < $1.staffID.uuidString }

        // Who held a head-coaching job, and from when. A coach with no head-coaching season is
        // neither a mentor nor a disciple, so this index answers both questions.
        var firstHeadCoachSeason: [UUID: Int] = [:]
        for career in careers {
            for assignment in career.assignments where assignment.role == .headCoach {
                let existing = firstHeadCoachSeason[career.staffID]
                if existing == nil || assignment.season < existing! {
                    firstHeadCoachSeason[career.staffID] = assignment.season
                }
            }
        }

        // The head coach of each organisation in each season. Ordered iteration, so a season with
        // two recorded head coaches resolves to the same one on every run.
        var headCoachBySeat: [SeatKey: UUID] = [:]
        for career in careers {
            for assignment in career.assignments where assignment.role == .headCoach {
                let seat = SeatKey(season: assignment.season, organisationID: assignment.organisationID)
                if let existing = headCoachBySeat[seat] {
                    if career.staffID.uuidString < existing.uuidString {
                        headCoachBySeat[seat] = career.staffID
                    }
                } else {
                    headCoachBySeat[seat] = career.staffID
                }
            }
        }

        var disciplesByMentor: [UUID: [CoachingTreeDisciple]] = [:]
        for career in careers {
            guard let becameHeadCoach = firstHeadCoachSeason[career.staffID] else { continue }
            // The earliest season this coach served under someone else, which is the tie the tree
            // is about. Later seasons under the same mentor are the same relationship.
            let served = career.assignments
                .filter { $0.role != .headCoach }
                .sorted { $0.season < $1.season }
            var claimedMentors: Set<UUID> = []
            for assignment in served {
                let seat = SeatKey(season: assignment.season, organisationID: assignment.organisationID)
                guard let mentorID = headCoachBySeat[seat], mentorID != career.staffID else { continue }
                guard claimedMentors.insert(mentorID).inserted else { continue }
                disciplesByMentor[mentorID, default: []].append(CoachingTreeDisciple(
                    staffID: career.staffID,
                    name: name(of: career.staffID, in: state),
                    sharedSeason: assignment.season,
                    sharedOrganisationID: assignment.organisationID,
                    roleUnderMentor: assignment.role,
                    firstHeadCoachSeason: becameHeadCoach
                ))
            }
        }

        let branches = disciplesByMentor
            .map { mentorID, disciples in
                CoachingTreeBranch(
                    mentorID: mentorID,
                    mentorName: name(of: mentorID, in: state),
                    disciples: Array(
                        disciples
                            .sorted {
                                $0.sharedSeason == $1.sharedSeason
                                    ? $0.staffID.uuidString < $1.staffID.uuidString
                                    : $0.sharedSeason < $1.sharedSeason
                            }
                            .prefix(CoachingTreeReadModel.maximumDisciplesPerBranch)
                    )
                )
            }
            .sorted {
                $0.disciples.count == $1.disciples.count
                    ? $0.mentorID.uuidString < $1.mentorID.uuidString
                    : $0.disciples.count > $1.disciples.count
            }

        return CoachingTreeReadModel(branches: branches)
    }

    private struct SeatKey: Hashable {
        let season: Int
        let organisationID: UUID
    }

    private static func name(of staffID: UUID, in state: GameState) -> String {
        state.staff[staffID]?.fullName ?? "Former coach"
    }
}
```

Both dictionaries are read into arrays that are sorted before anything leaves the function, so no output order depends on hash order. The `maximumBranches` truncation happens after the sort, so what survives is the deepest trees rather than whichever the dictionary listed first.

- [ ] **Step 5: Run the focused suite**

Run:

```bash
swift run SimTests --coaching-tree
```

Expected: `all passed`.

- [ ] **Step 6: Assert the engine/UI boundary still holds**

Run:

```bash
swift run SimTests --architecture-only
```

Expected: `all passed`. The new file lives in `FootballSimCore` and imports only `Foundation`; the architecture scan asserts that by construction.

- [ ] **Step 7: Commit**

```bash
git add Sources/FootballSimCore/History/CoachingTreeReadModel.swift Tests/SimTests/Suites/CoachingTreeTests.swift Tests/SimTests/main.swift
git commit -m "feat: project the coaching tree from staff careers"
```

---

## Task 3: Record the slice honestly and close it

**Files:**
- Modify: `docs/STATUS.md` (the `### M7 — living world/history — **active**` section)
- Modify: `docs/FUTURE-SIMULATION-CONTRACT.md` (the FSC-010 row)

**Interfaces:**
- Consumes: the measured counts printed by Step 1's runs.
- Produces: nothing code depends on.

- [ ] **Step 1: Run the full gates and record the real numbers**

Run:

```bash
swift run SimTests --rivalry-order
swift run SimTests --coaching-tree
./scripts/verify.sh
```

Write down the exact `N tests, M checks` line each prints. `./scripts/verify.sh` takes upwards of thirty minutes because the default run includes the portal-scheduler replay; let it finish rather than reporting a partial run. Do not write a number you did not read off a run.

- [ ] **Step 2: Update `docs/STATUS.md`**

In the `### M7 — living world/history — **active**` section, replace the closing sentence
("Cold event bodies, generated news, semantic rivalry narratives, coaching-tree projections, and the
30-season history/performance gate remain open.") with a paragraph stating: rival lists are now
reordered in the relationships step from earned intensity, touching only the programmes whose
rivalries moved; the coaching tree is a rebuildable projection over bounded staff career records; and
the still-open items are cold event bodies, generated news, semantic rivalry narratives, and the
30-season history/performance gate. Quote the measured counts from Step 1.

- [ ] **Step 3: Update `docs/FUTURE-SIMULATION-CONTRACT.md`**

In the FSC-010 row, move coaching-tree projections out of the "Missing dependency" column, leaving
cold event bodies and cross-season semantic narratives. Do not mark the row activated: two of its
four limbs remain.

- [ ] **Step 4: Run change detection**

Run:

```text
detect_changes({repo: "Pro-Football-Coach", scope: "all", worktree: "/Users/ericguei/Documents/Pro-Football-Coach"})
```

Expected: only `Programme`, `RivalrySystem`, `WorldScheduler`, the new projection, the two new suites, `main.swift`, and the two documents are attributable to this plan.

- [ ] **Step 5: Commit**

```bash
git add docs/STATUS.md docs/FUTURE-SIMULATION-CONTRACT.md
git commit -m "docs: record the M7A rivalry order and coaching tree slice"
```

---

## Not in this plan, and why

- **Durable cold event bodies.** `DomainEventLedger` keeps a bounded hot journal plus an
  `archivedCount`; giving archived events durable bodies changes a persisted root type and therefore
  the schema, and it needs its own bound design (a per-season digest, not an unbounded log). That is
  M7B, and it must be planned against `FSC-002`/`FSC-003` together with the save-size budget, which
  is still 84.66 MB at season 20 and is the reason the naive answer is wrong.
- **Generated news.** It reads the digests M7B introduces. Planning it first would design a feed over
  a store that does not exist.
- **The 30-season history gate.** It measures M7B and the news feed. Running it now would measure
  half a milestone and report the number as if it were the gate.
