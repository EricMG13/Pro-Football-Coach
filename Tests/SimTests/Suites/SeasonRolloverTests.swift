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
            guard let teamID, let team = state.proTeams[teamID],
                  let playerID = team.rosterIDs.first else {
                expect(false, "no eligible non-controlled team with a rostered player")
                return
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
    }
}

private func controlledTeamID(in state: GameState) -> UUID? {
    state.careerArc.currentJob.flatMap { job in
        job.tier == .professional ? job.organisationID : nil
    }
}
