import Foundation
import FootballSimCore

/// College acquisition rules asserted after **every transaction the weekly scheduler commits**,
/// rather than on the root each week comes to rest on.
///
/// The rules here were already stated in the rules module and already checked — once per week, at
/// `.saveGrowthAndIntegrity`. What was missing is the interval between two transactions.
/// Everything the season boundary does commits inside a single step, so a breach opened by one
/// transaction and closed by a later one is invisible to a weekly check. That is not hypothetical:
/// `WorldScheduler` calls `reconcileScholarships` precisely to repair one, several transactions
/// after it opened. `WorldScheduler.transactionObserver` is the seam that makes the interval
/// observable; this suite is what looks through it.
///
/// Two things are enumerated by construction rather than by hand, because a coverage boundary that
/// is a hand-written list becomes the quality boundary the day someone forgets to extend it:
///
/// - the checkpoints, because the observer fires for every `WorldStep` including steps added after
///   this was written; and
/// - the rules, because `acquisitionRules` is one list and every rule in it is evaluated at every
///   checkpoint. Adding a rule is one entry, not one test.

private struct AcquisitionRule: Sendable {
    let name: String
    /// How many things the rule swept. A rule that sweeps nothing passes for free, and a green
    /// that asserted nothing is worse than a red: it reads as coverage. Every rule declares its
    /// population so the suite can refuse to call itself covered when one is empty.
    let population: @Sendable (GameState) -> Int
    /// Returns one description per breach found in the root.
    let breaches: @Sendable (GameState) -> [String]
}

private let acquisitionRules: [AcquisitionRule] = [
    AcquisitionRule(
        name: "scholarship count",
        population: { Set($0.programmes.ids).union($0.college.programmes.keys).count },
        breaches: { state in
            CollegeScholarshipInvariant.findings(in: state).map {
                "\($0.breach.rawValue) at programme \($0.programmeID)"
            }
        }
    ),
    AcquisitionRule(
        name: "eligibility clock",
        population: { Set($0.programmes.values.flatMap(\.rosterIDs)).count },
        breaches: { state in
            CollegeEligibilityInvariant.findings(in: state).map {
                "\($0.breach.rawValue) for player \($0.playerID)"
            }
        }
    ),
    AcquisitionRule(
        name: "commitment uniqueness",
        population: { state in
            state.programmes.ids.reduce(0) {
                $0 + state.college.activeReservationCount(for: $1)
            }
        },
        breaches: { state in
            CollegeCommitmentInvariant.findings(in: state).map {
                "\($0.breach.rawValue) for \($0.subjectID)"
            }
        }
    ),
    AcquisitionRule(
        name: "portal window",
        population: { $0.college.portal.summaries.count + $0.college.portal.entries.count },
        breaches: { state in
            CollegePortalWindowInvariant.findings(in: state).map {
                "\($0.breach.rawValue)\($0.subjectID.map { " for \($0)" } ?? "")"
            }
        }
    ),
    AcquisitionRule(
        name: "redshirt legality",
        population: { $0.college.redshirtPlans.count },
        breaches: { state in
            CollegeRedshirtInvariant.findings(in: state).map {
                "\($0.breach.rawValue) for player \($0.playerID)"
            }
        }
    ),
]

private final class BreachRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [(checkpoint: String, rule: String, detail: String)] = []
    private var seenKeys: Set<String> = []
    private(set) var checkpointCount = 0
    private var seenCheckpoints: Set<String> = []
    private var populationHighWater: [String: Int] = [:]

    func observe(checkpoint: String, state: GameState) {
        var found: [(String, String, String)] = []
        var populations: [String: Int] = [:]
        for rule in acquisitionRules {
            populations[rule.name] = rule.population(state)
            for detail in rule.breaches(state) {
                found.append((checkpoint, rule.name, detail))
            }
        }
        lock.lock()
        defer { lock.unlock() }
        checkpointCount += 1
        seenCheckpoints.insert(checkpoint)
        for (name, size) in populations {
            populationHighWater[name] = max(populationHighWater[name] ?? 0, size)
        }
        for entry in found {
            // One entry per (checkpoint, rule, breach kind). A 134-programme world breaching the
            // same way at the same checkpoint would otherwise write 134 identical lines and bury
            // every other one. The trailing identity is dropped from the key, not from the report.
            let kind = entry.2.split(separator: " ").first.map(String.init) ?? entry.2
            guard seenKeys.insert("\(entry.0)|\(entry.1)|\(kind)").inserted else { continue }
            entries.append((checkpoint: entry.0, rule: entry.1, detail: entry.2))
        }
    }

    var breaches: [(checkpoint: String, rule: String, detail: String)] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    var checkpoints: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return seenCheckpoints
    }

    func largestPopulation(of rule: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return populationHighWater[rule] ?? 0
    }
}

/// Files a redshirt plan at each of the first few programmes.
///
/// Without this the redshirt rule sweeps an empty dictionary at every checkpoint and passes having
/// asserted nothing: plans are filed only through `CareerSession`, which a bare scheduler walk
/// never touches.
private func redshirtPlansFiled(on state: GameState, programmes: Int) -> GameState {
    var next = state
    for programmeID in next.programmes.ids.prefix(programmes) {
        guard let rosterIDs = next.programmes[programmeID]?.rosterIDs else { continue }
        for playerID in rosterIDs {
            guard let college = try? CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: CollegeRules.maximumRedshirtAppearances,
                in: next
            ) else { continue }
            next.college = college
            break
        }
    }
    return next
}

func runCollegeAcquisitionInvariantTests() {
    suite("College acquisition invariants are falsifiable") {
        test("every scholarship limb is reported when it is broken") {
            let state = GameState.bootstrap(seed: 41_003)
            expect(
                CollegeScholarshipInvariant.isSatisfied(in: state),
                "a bootstrapped root must already satisfy the rule"
            )

            let programmeID = state.programmes.ids[0]
            let programme = state.programmes[programmeID]!
            let recruiting = state.college.programmes[programmeID]!

            func breaches(
                programme: Programme?,
                recruiting: ProgrammeRecruitingState?
            ) -> Set<CollegeScholarshipInvariant.Breach> {
                Set(CollegeScholarshipInvariant.findings(
                    programmeID: programmeID,
                    programme: programme,
                    recruiting: recruiting
                ).map(\.breach))
            }

            expect(breaches(programme: programme, recruiting: recruiting).isEmpty)
            expectEqual(breaches(programme: nil, recruiting: recruiting), [.missingCounterpart])
            expectEqual(breaches(programme: programme, recruiting: nil), [.missingCounterpart])

            var offRoster = programme
            offRoster.rosterIDs = Array(programme.rosterIDs.suffix(1))
            expect(breaches(programme: offRoster, recruiting: recruiting)
                .contains(.holderOffRoster))

            var wrongCount = programme
            wrongCount.scholarshipCount += 1
            expectEqual(
                breaches(programme: wrongCount, recruiting: recruiting),
                [.countDisagreement]
            )

            // `ProgrammeRecruitingState`'s initializer refuses both an over-limit and a duplicated
            // holder list by construction, so the only route to those two limbs is a hostile
            // decode. Asserting the initializer's refusal is the honest form of the check: it says
            // the state cannot be built, which is stronger than saying the sweep would catch it.
            let overLimit = ProgrammeRecruitingState(
                programmeID: programmeID,
                scholarshipPlayerIDs: programme.rosterIDs
            )
            expectEqual(overLimit.scholarshipPlayerIDs.count, CollegeRules.scholarshipLimit)
            let duplicated = ProgrammeRecruitingState(
                programmeID: programmeID,
                scholarshipPlayerIDs: [programme.rosterIDs[0], programme.rosterIDs[0]]
            )
            expectEqual(duplicated.scholarshipPlayerIDs.count, 1)
        }

        test("every eligibility limb is reported when it is broken") {
            var state = GameState.bootstrap(seed: 41_003)
            expect(
                CollegeEligibilityInvariant.isSatisfied(in: state),
                "a bootstrapped root must already satisfy the clock"
            )

            let playerID = state.programmes.values.first!.rosterIDs[0]
            func limbs(_ eligibility: Eligibility?) -> Set<CollegeEligibilityInvariant.Breach> {
                Set(CollegeEligibilityInvariant.collegeFindings(
                    playerID: playerID,
                    eligibility: eligibility
                ).map(\.breach))
            }
            expect(limbs(Eligibility()).isEmpty)
            expectEqual(limbs(nil), [.missingClock])
            expectEqual(
                limbs(Eligibility(seasonsRemaining: 0, yearsRemaining: 1)),
                [.exhaustedClock]
            )
            // Three redshirts inside a five-year window: the counters are individually in range,
            // so only the gap between them says this could not have happened.
            expectEqual(
                limbs(Eligibility(seasonsRemaining: 1, yearsRemaining: 3)),
                [.impossibleClock]
            )

            let proTeamID = state.proTeams.ids[0]
            let proPlayerID = state.proTeams[proTeamID]!.rosterIDs[0]
            state.players.update(proPlayerID) { $0.eligibility = Eligibility() }
            expectEqual(
                CollegeEligibilityInvariant.findings(in: state).map(\.breach),
                [.professionalHoldsClock]
            )
        }
    }

    suite("College acquisition invariants after every transaction") {
        test("every rule holds at every checkpoint across a season boundary") {
            let recorder = BreachRecorder()
            WorldScheduler.transactionObserver = { checkpoint, state in
                recorder.observe(checkpoint: checkpoint, state: state)
            }
            defer { WorldScheduler.transactionObserver = nil }

            var state = redshirtPlansFiled(on: GameState.bootstrap(seed: 41_003), programmes: 3)
            expect(
                state.college.redshirtPlans.count == 3,
                "fixture filed \(state.college.redshirtPlans.count) redshirt plans, wanted 3"
            )
            do {
                // Through the final in-season week, the postseason rollover, and the spring
                // window: the three places a college acquisition transaction commits. The bound is
                // a hang guard, not a target: a test that never returns says less than one that
                // fails, and the calendar is the thing under test here.
                var advances = 0
                while state.calendar.season == 0 || state.calendar.week <= 2 {
                    state = try WorldScheduler.advanceWeek(state).state
                    advances += 1
                    guard advances <= SharedRules.inSeasonWeeks + 4 else {
                        expect(false, "the calendar did not reach season 1 week 3 in \(advances)")
                        return
                    }
                }
            } catch {
                expect(false, "week advance threw \(error)")
                return
            }

            expectEqual(state.calendar, CalendarState(season: 1, week: 3))
            expect(
                recorder.checkpointCount > 0,
                "the observer never fired, so this test asserted nothing"
            )
            for required in [
                "seasonLifecycle",
                "reconcileScholarships",
                "collegeCycle.closeAndOpen",
                "portalCommit.postseason",
                "walkOns.postseasonCoverage",
                "portalCommit.spring",
                "walkOns.springRosterFill",
                "recruitingAI",
                "recruitingMarket.weekly",
                "recruitingMarket.terminal",
            ] {
                expect(
                    recorder.checkpoints.contains(required),
                    "checkpoint \(required) never ran, so its transaction went unasserted"
                )
            }
            for step in WorldScheduler.steps {
                expect(
                    recorder.checkpoints.contains("step.\(step.rawValue)"),
                    "step \(step.rawValue) was never checkpointed"
                )
            }

            for rule in acquisitionRules {
                expect(
                    recorder.largestPopulation(of: rule.name) > 0,
                    "rule \(rule.name) swept nothing at every checkpoint, so it asserted nothing"
                )
            }

            let breaches = recorder.breaches
            for breach in breaches.prefix(12) {
                expect(
                    false,
                    "\(breach.rule) broken after \(breach.checkpoint): \(breach.detail)"
                )
            }
            expectEqual(breaches.count, 0, "distinct (checkpoint, rule, breach) triples")
        }
    }
}
