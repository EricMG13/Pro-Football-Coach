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
            let conferenceSizesBefore = conferenceSizes(in: state)
            var weeks = 0
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
                weeks += 1
                expect(weeks <= SharedRules.inSeasonWeeks + 1,
                       "the calendar did not roll over within one season of weeks")
            }
            expectEqual(state.calendar, CalendarState(season: 1, week: 1))
            assertTransitionScheduleShape(state)
            assertTransitionConferenceLegality(state, expectedSizes: conferenceSizesBefore)
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
            let conferenceSizesBefore = conferenceSizes(in: state)
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            assertTransitionScheduleShape(state)
            assertTransitionConferenceLegality(state, expectedSizes: conferenceSizesBefore)
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
            let conferenceSizesBefore = conferenceSizes(in: state)
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            assertTransitionScheduleShape(state)
            assertTransitionConferenceLegality(state, expectedSizes: conferenceSizesBefore)
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
            let conferenceSizesBefore = conferenceSizes(in: state)
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
            assertTransitionScheduleShape(transition.state)
            assertTransitionConferenceLegality(
                transition.state,
                expectedSizes: conferenceSizesBefore
            )
            let snapshot = try ProManagementSystem.capSnapshot(
                teamID: teamID,
                in: transition.state
            )
            expect(snapshot.isWithinCap,
                   "a real advanceWeek left a team over the cap after the boundary")
            expect(WorldIntegrity.check(transition.state).isValid)
        }
    }
}

private func assertTransitionScheduleShape(_ state: GameState) {
    let games = state.competition.currentSchedule.games
    assertScheduleShape(
        games: games.filter { $0.tier == .college },
        memberIDs: state.programmes.ids,
        gamesPerTeam: CollegeRules.gamesPerRegularSeason,
        regularSeasonWeeks: CollegeRules.regularSeasonWeeks
    )
    assertScheduleShape(
        games: games.filter { $0.tier == .pro },
        memberIDs: state.proTeams.ids,
        gamesPerTeam: ProRules.gamesPerRegularSeason,
        regularSeasonWeeks: ProRules.regularSeasonWeeks
    )
}

private func assertTransitionConferenceLegality(
    _ state: GameState,
    expectedSizes: [Int]
) {
    let conferences = state.league.conferences(in: .college)
    let memberIDs = conferences.flatMap(\.memberIDs)
    expectEqual(conferenceSizes(in: state), expectedSizes,
                "season transition changed conference cardinality")
    expectEqual(memberIDs.count, state.programmes.ids.count,
                "season transition duplicated or dropped conference membership")
    expectEqual(Set(memberIDs), Set(state.programmes.ids),
                "season transition left a programme outside the conference map")
    for conference in conferences {
        expect(conference.memberIDs.allSatisfy {
            state.programmes[$0]?.conferenceID == conference.id
        }, "season transition left programme and league conference IDs disagreeing")
    }
}

private func controlledTeamID(in state: GameState) -> UUID? {
    state.careerArc.currentJob.flatMap { job in
        job.tier == .professional ? job.organisationID : nil
    }
}
