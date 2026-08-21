import Foundation
import FootballSimCore

/// The season-boundary gate. Three defects lived here at once and each was reported as something
/// else, so the assertions below name the invariant rather than the symptom.
///
/// The first full-suite run since `0deb629` aborted in `PortalTransactionTests`'s fixture with
/// `professionalMarketFailed(.invalidRoot)`; behind it sat `portalCommitFailed(.postseason)`, which
/// the defect register carried as D-1 with its attribution explicitly open. Neither was a portal
/// defect and neither was the cap fork the register expected: contract expiry ran before the season
/// wrote its career records, and the last body at a position was kept on a contract whose term had
/// run out. `02` §4.2a now states the rule.
func runSeasonRolloverTests() {
    suite("Season rollover") {
        test("a full season advances into the next one") {
            // The reproduction, kept as a test rather than a probe. Seed 97_001 is the one
            // `PortalTransactionTests` walks, so this fails before that fixture aborts the process.
            var state = GameState.bootstrap(seed: 97_001)
            var weeks = 0
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
                weeks += 1
                expect(weeks <= SharedRules.inSeasonWeeks + 1,
                       "the calendar did not roll over within one season of weeks")
            }
            expectEqual(state.calendar, CalendarState(season: 1, week: 1))
            expect(WorldIntegrity.check(state).isValid,
                   "the rolled-over root is invalid: "
                       + WorldIntegrity.check(state).issues.prefix(3)
                           .map(\.description).joined(separator: " ; "))
        }

        test("no professional contract outlives its own term") {
            // The invariant the cap check reads, asserted over every team and every rostered player
            // rather than over the eleven that happened to fail. A contract is legal only while the
            // current season is inside its term; one that has run out must have been expired or
            // re-signed, never left attached.
            var state = GameState.bootstrap(seed: 97_002)
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            var offenders: [String] = []
            for team in state.proTeams.values {
                for playerID in team.rosterIDs + team.practiceSquadIDs {
                    guard let contract = state.players[playerID]?.contract,
                          let signedSeason = contract.signedSeason else { continue }
                    guard state.calendar.season < signedSeason + contract.years,
                          signedSeason <= state.calendar.season + 1 else {
                        offenders.append("\(playerID) signed \(signedSeason) for \(contract.years)")
                        continue
                    }
                }
            }
            expect(offenders.isEmpty,
                   "\(offenders.count) contracts outlived their term: "
                       + offenders.prefix(3).joined(separator: " ; "))
        }

        test("every professional team keeps a playable body at every position") {
            // The reason the exemption exists at all. Re-signing must satisfy it as completely as
            // holding a dead deal did.
            var state = GameState.bootstrap(seed: 97_003)
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            var shortfalls: [String] = []
            for team in state.proTeams.values {
                var counts: [Position: Int] = [:]
                for playerID in team.rosterIDs + team.practiceSquadIDs {
                    guard let position = state.players[playerID]?.position else { continue }
                    counts[position, default: 0] += 1
                }
                for (position, minimum) in SharedRules.minimumPlayableRosterByPosition
                where counts[position, default: 0] < minimum {
                    shortfalls.append("\(team.id) \(position.rawValue) "
                        + "\(counts[position, default: 0])/\(minimum)")
                }
            }
            expect(shortfalls.isEmpty,
                   "\(shortfalls.count) positional shortfalls: "
                       + shortfalls.prefix(3).joined(separator: " ; "))
        }

        test("expiry before the season's career records exist is refused") {
            // The ordering constraint, pinned so it cannot silently regress. Run against the raw
            // final week — before `SeasonLifecycleSystem.advance` has written the season's career
            // rows — expiry strands every completed professional game its departing players
            // appeared in, because FSC-013 legalises a departure only through that record. It must
            // refuse rather than return the stranded root.
            //
            // That is the whole reason the scheduler moved the call. The tolerant half of the same
            // guard — inherited issues, which at the new position are the college rosters
            // mid-turnover — is what makes "a full season advances into the next one" pass above;
            // with a plain `isValid` there is no point in the week where expiry can legally run.
            var state = GameState.bootstrap(seed: 97_004)
            for _ in 0..<(SharedRules.inSeasonWeeks - 1) {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar.week, SharedRules.inSeasonWeeks)
            do {
                _ = try ProMarketSystem.expireContracts(at: state.calendar, in: state)
                expect(false, "expiry stranded played games instead of refusing the root")
            } catch let error as ProMarketError {
                expectEqual(error, .invalidRoot)
            }
        }

        test("expiry still refuses a root it breaks itself") {
            // The other side of the difference guard. Filling the free-agent pool to its bound
            // means expiry cannot place the players it releases, which is a root only expiry can
            // produce — and it must refuse rather than return a professional it has stranded.
            var state = GameState.bootstrap(seed: 97_005)
            for _ in 0..<(SharedRules.inSeasonWeeks - 1) {
                state = try WorldScheduler.advanceWeek(state).state
            }
            let filler = (0..<ProMarketState.maximumFreeAgentIDs).map { ordinal in
                UUID(uuidString: String(format: "00000000-0000-4000-8000-%012X", ordinal))!
            }
            for id in filler where !state.proMarket.addFreeAgent(id) { break }
            expectEqual(state.proMarket.freeAgentIDs.count, ProMarketState.maximumFreeAgentIDs)

            do {
                _ = try ProMarketSystem.expireContracts(at: state.calendar, in: state)
                expect(false, "expiry placed contracts into a pool that was already full")
            } catch let error as ProMarketError {
                expectEqual(error, .invalidRoot)
            }
        }

        test("a compliance-forced release survives a real week-21 boundary") {
            var state = GameState.bootstrap(seed: 97_006)
            for _ in 0..<(SharedRules.inSeasonWeeks - 1) {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar.week, SharedRules.inSeasonWeeks)
            let teamID = state.proTeams.ids.first { $0 != controlledTeamID(in: state) }
            guard let teamID, let team = state.proTeams[teamID] else {
                expect(false, "no eligible non-controlled team")
                return
            }
            let positionCounts = Dictionary(
                grouping: team.rosterIDs.compactMap { state.players[$0]?.position },
                by: { $0 }
            ).mapValues(\.count)
            guard let playerID = team.rosterIDs.first(where: { playerID in
                guard let position = state.players[playerID]?.position else { return false }
                return positionCounts[position, default: 0]
                    > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
            }) else {
                expect(false, "no cap-release candidate above positional minimums")
                return
            }
            _ = state.proTeams.update(teamID) {
                $0.rosterIDs.removeAll { $0 == playerID }
                $0.practiceSquadIDs.append(playerID)
            }
            let capLimit = ProRules.salaryCap(seasonsAfterBase: state.calendar.season)
            state.players.update(playerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [capLimit + 1_000_000],
                    signingBonus: 0
                )
            }

            let transition = try WorldScheduler.advanceWeek(state)
            let snapshot = try ProManagementSystem.capSnapshot(
                teamID: teamID,
                in: transition.state
            )
            expect(snapshot.isWithinCap,
                   "a real advanceWeek left a team over the cap after the boundary")
            expect(WorldIntegrity.check(transition.state).isValid)
        }

        // `ArchitectureTests` asserts the full step ledger once, at season 0 week 1, and asserts
        // the week-21 roll as arithmetic on `CalendarState.advancedWeek()` rather than against
        // anything the scheduler does. Neither reaches the week that actually rolls: the boundary
        // is the one step where the transaction runs a second batch, replaces the slate, expires
        // contracts and rebuilds the college cycle, and it is the likeliest week for a step to be
        // skipped, run twice or reordered without a ledger entry to show for it.
        test("every week of the walk emits the whole step ledger in order and lands where it says") {
            var state = GameState.bootstrap(seed: 97_007)
            var visited: [CalendarState] = [state.calendar]
            var ledgerFaults: [String] = []
            var snapshotFaults: [String] = []

            while state.calendar.season == 0 {
                let before = state.calendar
                let transition = try WorldScheduler.advanceWeek(state)

                if transition.stepRecords.map(\.step) != WorldScheduler.steps {
                    ledgerFaults.append(
                        "S\(before.season)W\(before.week) emitted "
                            + "\(transition.stepRecords.count) records for "
                            + "\(WorldScheduler.steps.count) steps"
                    )
                }
                // The three claims the snapshot makes about where the week started, where it
                // ended, and that the two differ by exactly one calendar step.
                if transition.snapshot.completed != before
                    || transition.snapshot.next != before.advancedWeek()
                    || transition.state.calendar != transition.snapshot.next {
                    snapshotFaults.append(
                        "S\(before.season)W\(before.week) reported "
                            + "\(transition.snapshot.completed) -> \(transition.snapshot.next) "
                            + "and landed on \(transition.state.calendar)"
                    )
                }

                state = transition.state
                visited.append(state.calendar)
            }

            expect(ledgerFaults.isEmpty,
                   "\(ledgerFaults.count) weeks emitted an incomplete or reordered step ledger, "
                       + "first \(ledgerFaults.first ?? "")")
            expect(snapshotFaults.isEmpty,
                   "\(snapshotFaults.count) weeks disagreed with their own snapshot, first "
                       + "\(snapshotFaults.first ?? "")")

            // The walk itself: every week of the season exactly once, in order, and the roll only
            // at the documented last week.
            let expected = (1...SharedRules.inSeasonWeeks).map {
                CalendarState(season: 0, week: $0)
            } + [CalendarState(season: 1, week: 1)]
            expectEqual(visited, expected,
                        "the walk skipped, repeated or rolled on a week other than "
                            + "\(SharedRules.inSeasonWeeks)")
        }

        // `02` section 4.1: signing day is week 21 and the cycle phase is a function of the week.
        //
        // The phase enum carried a `signing` case that nothing ever assigned, and `WorldIntegrity`
        // required `active` at every stable root, so it could not have survived a week boundary
        // even if something had. Screen 29 rendered its closed branch for the whole of every
        // career. These assert the phase over every week by construction rather than at the one
        // boundary that happened to be interesting.
        test("the recruiting cycle phase is derived from the week, every week") {
            var state = GameState.bootstrap(seed: 97_010)
            expectEqual(state.calendar.week, 1)
            expectEqual(state.college.phase, .active)
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
                let expected = CollegeRules.recruitingCyclePhase(inWeek: state.calendar.week)
                expectEqual(state.college.phase, expected,
                            "week \(state.calendar.week) carried \(state.college.phase)")
                expect(WorldIntegrity.check(state).isValid,
                       "week \(state.calendar.week) root is invalid: "
                           + WorldIntegrity.check(state).issues.prefix(3)
                               .map(\.description).joined(separator: " ; "))
            }
            expectEqual(state.college.phase, .active)
        }

        test("signing day opens in the signing week and only there") {
            var state = GameState.bootstrap(seed: 97_011)
            var signingWeeks = 0
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
                guard state.calendar.season == 0 else { break }
                if state.college.phase == .signing {
                    signingWeeks += 1
                    expectEqual(state.calendar.week, CollegeRules.signingDayWeek)
                }
            }
            expectEqual(signingWeeks, 1,
                        "signing day opened \(signingWeeks) times in one season")
        }

        test("the integrity check refuses a phase the week does not carry") {
            var state = GameState.bootstrap(seed: 97_012)
            expectEqual(state.calendar.week, 1)
            state.college.phase = .signing
            expect(WorldIntegrity.check(state).issues.contains(
                .invalidRecruitingCyclePhase(.signing)
            ), "a signing phase outside the signing week passed the integrity check")

            while state.calendar.week < CollegeRules.signingDayWeek {
                state.college.phase = CollegeRules
                    .recruitingCyclePhase(inWeek: state.calendar.week)
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar.week, CollegeRules.signingDayWeek)
            state.college.phase = .active
            expect(WorldIntegrity.check(state).issues.contains(
                .invalidRecruitingCyclePhase(.active)
            ), "an active phase in the signing week passed the integrity check")
        }

        test("signing day closes contact and leaves commitment resolution open") {
            expect(!RecruitingCyclePhase.signing.allowsRecruitingActions)
            expect(RecruitingCyclePhase.signing.allowsCommitmentResolution)
            expect(RecruitingCyclePhase.active.allowsRecruitingActions)
            expect(RecruitingCyclePhase.active.allowsCommitmentResolution)
            expect(!RecruitingCyclePhase.closed.allowsRecruitingActions)
            expect(!RecruitingCyclePhase.closed.allowsCommitmentResolution)

            var state = GameState.bootstrap(seed: 97_013)
            while state.calendar.week < CollegeRules.signingDayWeek {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.college.phase, .signing)

            // The cycle gate is the first thing `apply` checks, so a request that would otherwise
            // fail on a missing programme still reports the gate. That is the point: on signing
            // day no recruiting request is reachable, whatever it names.
            let request = RecruitingActionRequest(
                programmeID: state.programmes.ids.first!,
                prospectID: state.prospects.ids.first!,
                action: .contact(points: 1)
            )
            do {
                _ = try CollegeRecruitingSystem.apply(request, in: state)
                expect(false, "a recruiting action was accepted on signing day")
            } catch let error as RecruitingActionError {
                expectEqual(error, .cycleUnavailable)
            }
        }

        // The assertion the first cut of this change did not have, and needed. `commit` and `flip`
        // still guarded on `== .active` underneath the market's own gate, so the signing week
        // computed contenders and then refused every one of them. Nothing failed; it showed up only
        // as six points of class fill in a calibration number nobody had to read.
        test("commitments still resolve during the signing week") {
            var state = GameState.bootstrap(seed: 97_015)
            var committedInSigningWeek = 0
            while state.calendar.season == 0 {
                let transition = try WorldScheduler.advanceWeek(state)
                state = transition.state
                for event in transition.emittedEvents {
                    if case .prospectCommitted = event.payload,
                       event.occurredAt.week == CollegeRules.signingDayWeek {
                        committedInSigningWeek += 1
                    }
                }
            }
            expect(committedInSigningWeek > 0,
                   "the signing week formed no commitments: signing day closed the class instead "
                       + "of resolving it")
        }

        test("the class still signs after the signing week") {
            var state = GameState.bootstrap(seed: 97_014)
            var signed = 0
            while state.calendar.season == 0 {
                let transition = try WorldScheduler.advanceWeek(state)
                state = transition.state
                for event in transition.emittedEvents {
                    if case let .commitmentResolved(_, _, outcome) = event.payload,
                       outcome == .signed {
                        signed += 1
                    }
                }
            }
            expect(signed > 0, "a full season signed nobody")
        }

        // The career-length cap: `02` section 11.3.1, owner decision 2026-08-20. Asserted from a
        // placed calendar rather than by playing thirty seasons, which is roughly twenty minutes of
        // simulation -- the guard reads `calendar.season` and nothing else, so a placed root
        // exercises exactly the branch the thirtieth season would reach.
        test("a career cannot advance past its final season") {
            // The last playable week: season 29 is inside the cap and must still advance.
            let final = seasonPlacedRoot(
                seed: 97_008,
                season: SharedRules.maximumCareerSeasons - 1
            )
            do {
                _ = try WorldScheduler.advanceWeek(final)
            } catch let error as WorldSchedulerError {
                expect(false, "the last season of the career refused to advance: \(error)")
            }

            // The terminal resting position: season 30 week 1 exists and cannot advance.
            let complete = seasonPlacedRoot(
                seed: 97_008,
                season: SharedRules.maximumCareerSeasons
            )
            do {
                _ = try WorldScheduler.advanceWeek(complete)
                expect(false, "the week advanced past the end of the career")
            } catch let error as WorldSchedulerError {
                expectEqual(error, .careerComplete)
            }

            // Terminal, not broken. A finished career is a save the player still loads and reads,
            // so the root has to stay valid at rest.
            let report = WorldIntegrity.check(complete)
            expect(report.isValid,
                   "the completed career's root is invalid: "
                       + report.issues.prefix(3).map(\.description).joined(separator: " ; "))
        }
    }
}

/// A root placed at `season` week 1 without running the scheduler to get there.
///
/// Everything the calendar drags with it has to move too, or whole-root integrity rejects a root
/// the engine could never have produced -- and this test would then fail for a reason that has
/// nothing to do with the career cap. `TestRoots.swift` records both hazards: the professional
/// market's season, and contracts whose term ended in the past.
private func seasonPlacedRoot(seed: UInt64, season: Int) -> GameState {
    var state = GameState.bootstrap(seed: seed)
    state.calendar = CalendarState(season: season, week: 1)
    state.league.season = season
    state.league.week = 1
    state.proMarket = ProMarketState(season: season)
    // The college cycle's own season, which `SeasonLifecycleSystem` checks against the calendar
    // before it will run a boundary at all -- a placed root without it throws
    // `collegeSeasonMismatch` long before the career cap is reached.
    state.college = CollegeState.bootstrap(
        season: season,
        programmes: state.programmes.values,
        prospects: state.prospects.values
    )
    state = professionalContractsRolled(to: season, in: state)
    state.competition = CompetitionState(
        currentSchedule: SeasonSchedule(
            season: season,
            games: ScheduleGenerator.regularSeason(
                seed: state.league.seed,
                season: season,
                programmes: state.programmes.values,
                proTeams: state.proTeams.values
            )
        ),
        archives: state.competition.archives,
        recordBook: state.competition.recordBook
    )
    state.competition = CompetitionReducer.rebuild(from: state)
    return state
}

func runStaffPruningTests() {
    suite("Staff pruning") {
        test("season rollover prunes only unreferenced seatless staff") {
            let source = GameState.bootstrap(seed: 97_008)
            let played = try CareerControlSystem.startCollegeCareer(
                at: source.programmes.ids[0],
                in: source
            ).state
            guard let programmeID = played.programmes.ids.first(where: {
                $0 != played.career.college?.programmeID
            }), let programme = played.programmes[programmeID] else {
                expect(false, "no secondary programme for the pruning fixture")
                return
            }
            guard let mentorID = programme.staffIDs.first(where: {
                played.staff[$0]?.role == .headCoach
            }), let discipleID = programme.staffIDs.first(where: {
                played.staff[$0]?.role == .offensiveCoordinator
            }), let discardedID = programme.staffIDs.first(where: {
                played.staff[$0]?.role == .defensiveCoordinator
            }), let historyID = programme.staffIDs.first(where: {
                played.staff[$0]?.role == .positionCoach
            }), let disciple = played.staff[discipleID] else {
                expect(false, "secondary programme did not have the staff roles needed")
                return
            }

            var state = played
            _ = state.programmes.update(programmeID) {
                $0.staffIDs.removeAll {
                    [mentorID, discipleID, discardedID, historyID].contains($0)
                }
            }
            _ = state.people.recordStaffAssignment(
                StaffCareerAssignment(
                    season: state.calendar.season + 1,
                    organisationID: state.proTeams.ids[0],
                    role: .headCoach
                ),
                for: disciple
            )
            let sequence = (state.history.lastSequence ?? -1) + 1
            expect(state.history.append(DomainEvent(
                id: DomainEvent.deterministicID(rootSeed: state.league.seed, sequence: sequence),
                sequence: sequence,
                occurredAt: state.calendar,
                payload: .staffHired(
                    staffID: historyID,
                    organisationID: programmeID,
                    role: .positionCoach
                )
            )))
            state.calendar = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.league.week = SharedRules.inSeasonWeeks

            let transition = try SeasonLifecycleSystem.advance(
                after: state.calendar,
                in: state
            )
            expect(transition.staff[mentorID] != nil,
                   "a seatless mentor named by the coaching tree was pruned")
            expect(transition.people.staffCareers[discipleID] != nil,
                   "a seatless coaching-tree disciple was pruned")
            expect(transition.staff[historyID] != nil,
                   "a seatless coach named by retained history was pruned")
            expect(transition.staff[discardedID] == nil,
                   "a seatless coach with no history was retained")
            expect(transition.people.staffCareers[discardedID] == nil,
                   "a pruned coach left an orphaned career record")
            expect(transition.staff[state.career.coachID!] != nil,
                   "the played coach was pruned while unseated staff were cleaned")
            expectEqual(
                Set(transition.staff.ids),
                Set(transition.people.staffCareers.keys),
                "staff pruning left the staff and career stores out of sync"
            )
        }
    }
}

private func controlledTeamID(in state: GameState) -> UUID? {
    state.careerArc.currentJob.flatMap { job in
        job.tier == .professional ? job.organisationID : nil
    }
}
