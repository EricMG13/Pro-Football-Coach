import Foundation
import FootballSimCore

func runInvalidRedshirtCareerGamesProbe(tier: Tier) {
    let maximumGames = tier == .college
        ? CollegeRules.maximumGamesPerSeason
        : ProRules.maximumGamesPerSeason
    _ = PlayerCareerSeason(
        season: 0,
        organisationID: UUID(uuidString: "00000000-0000-4000-8005-000000000099")!,
        tier: tier,
        games: maximumGames + 1,
        starts: 0,
        overallAtEnd: Rating(60)
    )
    exit(0)
}

private func replacingPlayerCareer(
    _ replacement: PlayerCareerRecord,
    in people: PeopleState
) -> PeopleState {
    PeopleState(
        playerLifecycle: Array(people.playerLifecycle.values),
        playerCareers: people.playerCareers.values.map {
            $0.playerID == replacement.playerID ? replacement : $0
        },
        staffCareers: Array(people.staffCareers.values),
        departedPlayers: Array(people.departedPlayers.values)
    )
}

func runCollegeRedshirtTests() {
    suite("College redshirt contracts") {
        test("a bounded current-season plan requires a spare clock year") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8005-000000000001")!
            let programmeID = UUID(uuidString: "00000000-0000-4000-8005-000000000002")!
            let plan = RedshirtPlan(
                playerID: playerID,
                programmeID: programmeID,
                season: 3,
                plannedAppearanceLimit: 4
            )

            expectEqual(plan.playerID, playerID)
            expectEqual(plan.programmeID, programmeID)
            expectEqual(plan.season, 3)
            expectEqual(plan.plannedAppearanceLimit, 4)
            expect(CollegeRedshirtSystem.hasSpareClockYear(Eligibility()))
            expect(!CollegeRedshirtSystem.hasSpareClockYear(Eligibility(
                seasonsRemaining: 3,
                yearsRemaining: 3
            )))
        }

        test("persisted plans reject negative seasons and appearance limits outside zero through four") {
            let plan = RedshirtPlan(
                playerID: UUID(uuidString: "00000000-0000-4000-8005-000000000003")!,
                programmeID: UUID(uuidString: "00000000-0000-4000-8005-000000000004")!,
                season: 2,
                plannedAppearanceLimit: 4
            )
            let encoded = try JSONEncoder.stable().encode(plan)
            let base = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            var corruptions: [[String: Any]] = []
            for limit in [-1, 5] {
                var corrupted = base
                corrupted["plannedAppearanceLimit"] = limit
                corruptions.append(corrupted)
            }
            var negativeSeason = base
            negativeSeason["season"] = -1
            corruptions.append(negativeSeason)

            for object in corruptions {
                let data = try JSONSerialization.data(withJSONObject: object)
                do {
                    _ = try JSONDecoder.stable().decode(RedshirtPlan.self, from: data)
                    expect(false, "an invalid redshirt plan decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("designation records a current-season plan for an owned college player") {
            var state = GameState.bootstrap(seed: 85_001)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]

            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 3,
                in: state
            )

            expectEqual(state.college.redshirtPlans[playerID], RedshirtPlan(
                playerID: playerID,
                programmeID: programmeID,
                season: state.calendar.season,
                plannedAppearanceLimit: 3
            ))
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            )
            expectEqual(restored, state)
            expect(WorldIntegrity.check(state).isValid)
        }

        test("designation rejects an appearance limit above the redshirt maximum") {
            let state = GameState.bootstrap(seed: 85_002)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]

            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: playerID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: CollegeRules.maximumRedshirtAppearances + 1,
                    in: state
                )
                expect(false, "an over-limit redshirt designation succeeded")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .invalidAppearanceLimit)
            }
        }

        test("designation remains legal at exactly four authoritative appearances") {
            var state = GameState.bootstrap(seed: 85_010)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.competition.playerStatistics[playerID] = PlayerSeasonStatistics(
                playerID: playerID,
                games: CollegeRules.maximumRedshirtAppearances
            )

            let college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: CollegeRules.maximumRedshirtAppearances,
                in: state
            )

            expectEqual(college.redshirtPlans[playerID]?.playerID, playerID)
        }

        test("designation rejects a player whose usage already burned the season") {
            var state = GameState.bootstrap(seed: 85_011)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.competition.playerStatistics[playerID] = PlayerSeasonStatistics(
                playerID: playerID,
                games: CollegeRules.maximumRedshirtAppearances + 1
            )

            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: playerID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: CollegeRules.maximumRedshirtAppearances,
                    in: state
                )
                expect(false, "an already-burned player received a new designation")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .usageAlreadyExhausted)
            }
        }

        test("designation rejects a player owned by a different programme") {
            let state = GameState.bootstrap(seed: 85_003)
            let programmeID = state.programmes.ids[0]
            let otherProgrammeID = state.programmes.ids[1]
            let otherPlayerID = state.programmes[otherProgrammeID]!.rosterIDs[0]

            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: otherPlayerID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: 4,
                    in: state
                )
                expect(false, "a programme designated another programme's player")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .playerNotOwnedByProgramme)
            }
        }

        test("designation rejects a college player without a spare clock year") {
            var state = GameState.bootstrap(seed: 85_004)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 3, yearsRemaining: 3)
            }

            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: playerID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: 4,
                    in: state
                )
                expect(false, "a player without a spare clock year was designated")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .noSpareClockYear)
            }
        }

        test("designation rejects a rostered player without college eligibility") {
            var state = GameState.bootstrap(seed: 85_005)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.players.update(playerID) { $0.eligibility = nil }

            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: playerID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: 4,
                    in: state
                )
                expect(false, "a player without college eligibility was designated")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .ineligiblePlayer)
            }
        }

        test("a programme can clear its current-season designation") {
            var state = GameState.bootstrap(seed: 85_006)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 0,
                in: state
            )

            state.college = try CollegeRedshirtSystem.clearDesignation(
                playerID: playerID,
                programmeID: programmeID,
                in: state
            )

            expectEqual(state.college.redshirtPlans[playerID], nil)
            expect(WorldIntegrity.check(state).isValid)
        }

        test("designation rejects a missing programme before roster ownership") {
            let state = GameState.bootstrap(seed: 85_007)
            let playerID = state.programmes[state.programmes.ids[0]]!.rosterIDs[0]
            let missingProgrammeID = UUID(
                uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF8507"
            )!

            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: playerID,
                    programmeID: missingProgrammeID,
                    plannedAppearanceLimit: 4,
                    in: state
                )
                expect(false, "a missing programme accepted a designation")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .missingProgramme)
            }
        }

        test("clearing rejects wrong-owner missing and stale designations") {
            var state = GameState.bootstrap(seed: 85_008)
            let programmeID = state.programmes.ids[0]
            let otherProgrammeID = state.programmes.ids[1]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]

            do {
                _ = try CollegeRedshirtSystem.clearDesignation(
                    playerID: playerID,
                    programmeID: programmeID,
                    in: state
                )
                expect(false, "a missing designation was cleared")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .missingDesignation)
            }

            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 4,
                in: state
            )
            do {
                _ = try CollegeRedshirtSystem.clearDesignation(
                    playerID: playerID,
                    programmeID: otherProgrammeID,
                    in: state
                )
                expect(false, "a different programme cleared the designation")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .playerNotOwnedByProgramme)
            }

            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason + 1,
                portal: CollegePortalState(
                    targetSeason: state.college.recruitingSeason + 1
                ),
                phase: state.college.phase,
                programmes: state.college.programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: state.college.redshirtPlans
            )
            do {
                _ = try CollegeRedshirtSystem.clearDesignation(
                    playerID: playerID,
                    programmeID: programmeID,
                    in: state
                )
                expect(false, "a stale designation was cleared")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .seasonUnavailable)
            }
        }

        test("whole-root diagnostics reject invalid plans in canonical player order") {
            var state = GameState.bootstrap(seed: 85_009)
            let firstProgrammeID = state.programmes.ids[0]
            let secondProgrammeID = state.programmes.ids[1]
            let playerIDs = [
                state.programmes[firstProgrammeID]!.rosterIDs[0],
                state.programmes[secondProgrammeID]!.rosterIDs[0],
            ]
            let plans = [
                playerIDs[0]: RedshirtPlan(
                    playerID: playerIDs[0],
                    programmeID: secondProgrammeID,
                    season: state.calendar.season,
                    plannedAppearanceLimit: 4
                ),
                playerIDs[1]: RedshirtPlan(
                    playerID: playerIDs[1],
                    programmeID: firstProgrammeID,
                    season: state.calendar.season,
                    plannedAppearanceLimit: 4
                ),
            ]
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: state.college.phase,
                programmes: state.college.programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: plans
            )

            let report = WorldIntegrity.check(state)
            let reportedPlayerIDs = report.issues.compactMap { issue -> UUID? in
                guard case let .invalidRedshirtPlan(playerID) = issue else { return nil }
                return playerID
            }
            expectEqual(
                reportedPlayerIDs,
                playerIDs.sorted { $0.uuidString < $1.uuidString }
            )
            do {
                _ = try SaveEnvelope.decode(
                    GameState.self,
                    from: SaveEnvelope.encode(state)
                )
                expect(false, "a save with cross-owned redshirt plans decoded")
            } catch {
                expect(true)
            }
        }

        test("season resolutions distinguish no plan protection and usage burn") {
            let notDesignated = RedshirtSeasonResolution(
                outcome: .notDesignated,
                plannedAppearanceLimit: nil
            )
            let preserved = RedshirtSeasonResolution(
                outcome: .preservedCompetitionSeason,
                plannedAppearanceLimit: 2
            )
            let burned = RedshirtSeasonResolution(
                outcome: .burnedByUsage,
                plannedAppearanceLimit: 4
            )

            expect(notDesignated.isValid(appearances: 0))
            expect(preserved.isValid(appearances: 3))
            expect(!preserved.isValid(appearances: 5))
            expect(burned.isValid(appearances: 5))
            expect(!burned.isValid(appearances: 4))
            let maximumCollegeGames = CollegeRules.maximumGamesPerSeason
            expect(burned.isValid(appearances: maximumCollegeGames))
            expect(!burned.isValid(appearances: maximumCollegeGames + 1))
        }

        test("college career seasons retain redshirt outcomes while pro seasons do not") {
            let organisationID = UUID(uuidString: "00000000-0000-4000-8005-000000000006")!
            let preserved = RedshirtSeasonResolution(
                outcome: .preservedCompetitionSeason,
                plannedAppearanceLimit: 4
            )
            let college = PlayerCareerSeason(
                season: 0,
                organisationID: organisationID,
                tier: .college,
                games: 4,
                starts: 0,
                overallAtEnd: Rating(60),
                redshirtResolution: preserved
            )
            let pro = PlayerCareerSeason(
                season: 0,
                organisationID: organisationID,
                tier: .pro,
                games: 4,
                starts: 0,
                overallAtEnd: Rating(60)
            )

            expectEqual(college.redshirtResolution, preserved)
            expectEqual(pro.redshirtResolution, nil)
            expectEqual(
                try JSONDecoder.stable().decode(
                    PlayerCareerSeason.self,
                    from: JSONEncoder.stable().encode(college)
                ),
                college
            )
        }

        test("career-season construction fails fast above each tier's possible game bound") {
            for argument in [
                "--redshirt-invalid-college-career-games-probe",
                "--redshirt-invalid-pro-career-games-probe",
            ] {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
                process.arguments = [argument]
                process.standardOutput = Pipe()
                process.standardError = Pipe()

                try process.run()
                process.waitUntilExit()

                expect(process.terminationStatus != 0, "\(argument) did not fail fast")
            }
        }

        test("persisted career seasons reject games above each tier's possible bound") {
            let boundaries: [(Tier, Int)] = [
                (.college, CollegeRules.maximumGamesPerSeason),
                (.pro, ProRules.maximumGamesPerSeason),
            ]
            for (tier, maximumGames) in boundaries {
                let season = PlayerCareerSeason(
                    season: 0,
                    organisationID: UUID(
                        uuidString: "00000000-0000-4000-8005-000000000098"
                    )!,
                    tier: tier,
                    games: maximumGames,
                    starts: 0,
                    overallAtEnd: Rating(60),
                    redshirtResolution: tier == .college
                        ? RedshirtSeasonResolution(
                            outcome: .burnedByUsage,
                            plannedAppearanceLimit: 4
                        )
                        : nil
                )
                var object = try JSONSerialization.jsonObject(
                    with: JSONEncoder.stable().encode(season)
                ) as! [String: Any]
                object["games"] = maximumGames + 1

                do {
                    _ = try JSONDecoder.stable().decode(
                        PlayerCareerSeason.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an over-bound \(tier.rawValue) career season decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("persisted college career seasons require an explicit redshirt resolution") {
            let season = PlayerCareerSeason(
                season: 0,
                organisationID: UUID(
                    uuidString: "00000000-0000-4000-8005-000000000097"
                )!,
                tier: .college,
                games: 0,
                starts: 0,
                overallAtEnd: Rating(60)
            )
            let encoded = try JSONEncoder.stable().encode(season)
            let base = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            var missing = base
            missing.removeValue(forKey: "redshirtResolution")
            var null = base
            null["redshirtResolution"] = NSNull()

            for object in [missing, null] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        PlayerCareerSeason.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "a college career season omitted its redshirt resolution")
                } catch {
                    expect(true)
                }
            }
        }

        test("whole-root integrity rejects a career season that is not in the past") {
            var state = GameState.bootstrap(seed: 85_012)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            let player = state.players[playerID]!
            let currentSeason = state.calendar.season
            expect(state.people.updatePlayerCareer(playerID) {
                _ = $0.append(PlayerCareerSeason(
                    season: currentSeason,
                    organisationID: programmeID,
                    tier: .college,
                    games: 0,
                    starts: 0,
                    overallAtEnd: player.overall
                ))
            })

            expect(WorldIntegrity.check(state).issues.contains(
                .invalidPlayerCareer(playerID: playerID)
            ))
        }
    }


    suite("College redshirt game usage") {
        test("a zero-appearance plan excludes the player from the first abstract game") {
            var state = GameState.bootstrap(seed: 85_101)
            let game = state.competition.currentSchedule.games.first { $0.tier == .college }!
            let playerID = state.programmes[game.homeID]!.rosterIDs[0]
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: game.homeID,
                plannedAppearanceLimit: 0,
                in: state
            )

            let result = AbstractGameSimulator.play(game, in: state)

            expect(!result.homeParticipantIDs.contains(playerID))
            expect(!result.playerStatistics.contains { $0.playerID == playerID })
        }

        test("a four-appearance plan allows four games then preserves every other contributor") {
            var state = GameState.bootstrap(seed: 85_102)
            let game = state.competition.currentSchedule.games.first { $0.tier == .college }!
            let playerID = state.programmes[game.homeID]!.rosterIDs[0]
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: game.homeID,
                plannedAppearanceLimit: 4,
                in: state
            )
            state.competition.playerStatistics[playerID] = PlayerSeasonStatistics(
                playerID: playerID,
                games: 3
            )

            let fourthAppearance = AbstractGameSimulator.play(game, in: state)
            expect(fourthAppearance.homeParticipantIDs.contains(playerID))

            state.competition.playerStatistics[playerID] = PlayerSeasonStatistics(
                playerID: playerID,
                games: 4
            )
            let capped = AbstractGameSimulator.play(game, in: state)
            let expectedParticipants = state.programmes[game.homeID]!.rosterIDs.filter {
                $0 != playerID && state.people.playerLifecycle[$0]?.isAvailable == true
            }.sorted { $0.uuidString < $1.uuidString }

            expect(!capped.homeParticipantIDs.contains(playerID))
            expectEqual(capped.homeParticipantIDs, expectedParticipants)
            expect(Set(capped.playerStatistics.map(\.playerID)).isSubset(
                of: Set(capped.homeParticipantIDs + capped.awayParticipantIDs)
            ))
        }

        test("a capped redshirt receives no game workload when absent from the manifest") {
            var state = GameState.bootstrap(seed: 85_103)
            var game = state.competition.currentSchedule.games.first {
                $0.tier == .college && $0.week == 1
            }!
            let playerID = state.programmes[game.homeID]!.rosterIDs[0]
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: game.homeID,
                plannedAppearanceLimit: 0,
                in: state
            )
            game.result = AbstractGameSimulator.play(game, in: state)
            expect(game.result?.homeParticipantIDs.contains(playerID) == false)
            expect(state.competition.currentSchedule.replace(game))

            let transition = PeopleLifecycleSystem.processHealth(
                at: CalendarState(season: 0, week: 2),
                in: state
            )

            expectEqual(transition.people.playerLifecycle[playerID]?.fatigue, 0)
            expectEqual(transition.people.playerLifecycle[playerID]?.injury, nil)
        }
    }


    suite("College redshirt rollover") {
        test("season lifecycle rejects a completed calendar different from the root") {
            let state = GameState.bootstrap(seed: 85_190)

            do {
                _ = try SeasonLifecycleSystem.advance(
                    after: CalendarState(season: 0, week: SharedRules.inSeasonWeeks),
                    in: state
                )
                expect(false, "lifecycle accepted a mismatched completed calendar")
            } catch let error as SeasonLifecycleError {
                expectEqual(error, .completedCalendarMismatch)
            }
        }

        test("season lifecycle rejects a league calendar different from the root") {
            var state = GameState.bootstrap(seed: 85_191)
            let completed = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.calendar = completed

            do {
                _ = try SeasonLifecycleSystem.advance(after: completed, in: state)
                expect(false, "lifecycle accepted a mismatched league calendar")
            } catch let error as SeasonLifecycleError {
                expectEqual(error, .leagueCalendarMismatch)
            }
        }

        test("season lifecycle rejects a schedule from another season") {
            var state = GameState.bootstrap(seed: 85_192)
            let completed = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.calendar = completed
            state.league.week = completed.week
            state.competition.currentSchedule = SeasonSchedule(season: 1, games: [])

            do {
                _ = try SeasonLifecycleSystem.advance(after: completed, in: state)
                expect(false, "lifecycle accepted a mismatched competition season")
            } catch let error as SeasonLifecycleError {
                expectEqual(error, .scheduleSeasonMismatch)
            }
        }

        test("season lifecycle rejects a college cycle from another season") {
            var state = GameState.bootstrap(seed: 85_193)
            let completed = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.calendar = completed
            state.league.week = completed.week
            state.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(targetSeason: 1),
                phase: state.college.phase,
                programmes: state.college.programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: [:]
            )

            do {
                _ = try SeasonLifecycleSystem.advance(after: completed, in: state)
                expect(false, "lifecycle accepted a mismatched college season")
            } catch let error as SeasonLifecycleError {
                expectEqual(error, .collegeSeasonMismatch)
            }
        }

        test("commitment capacity treats a protected player as returning") {
            var state = GameState.bootstrap(seed: 85_200)
            let programmeID = state.programmes.ids[0]
            let playerID = state.college.programmes[programmeID]!.scholarshipPlayerIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 2)
            }
            let before = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!
            let designated = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 4,
                in: state
            )
            let after = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: designated
            )!

            expect(!before.projectedReturningPlayerIDs.contains(playerID))
            expect(after.projectedReturningPlayerIDs.contains(playerID))
            expectEqual(after.projectedRosterOpenings, before.projectedRosterOpenings - 1)
            expectEqual(
                after.projectedScholarshipOpenings,
                before.projectedScholarshipOpenings - 1
            )
        }

        test("designation atomically rejects a plan that strands an active commitment") {
            var state = GameState.bootstrap(seed: 85_203)
            let programmeID = state.programmes.ids[0]
            let programme = state.programmes[programmeID]!
            let positionCounts = Dictionary(grouping: programme.rosterIDs.compactMap {
                state.players[$0]?.position
            }, by: { $0 }).mapValues(\.count)
            let playerID = state.college.programmes[programmeID]!.scholarshipPlayerIDs.first {
                guard let position = state.players[$0]?.position else { return false }
                return (positionCounts[position] ?? 0) >
                    (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
            }!
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 2)
            }

            let reservationCount = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!.maximumReservations
            let prospectIDs = Array(state.prospects.ids.prefix(reservationCount))
            let relationships = Dictionary(uniqueKeysWithValues: prospectIDs.map { prospectID in
                (
                    prospectID,
                    ProgrammeProspectRelationship(
                        prospectID: prospectID,
                        interest: CollegeRules.minimumCommitmentScore,
                        scholarshipOffered: true
                    )
                )
            })
            let existing = state.college.programmes[programmeID]!
            var programmeStates = state.college.programmes
            programmeStates[programmeID] = ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: prospectIDs,
                relationships: relationships,
                scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                contactPointsRemaining: existing.contactPointsRemaining,
                nilState: existing.nilState
            )
            var prospectRecruitment = state.college.prospectRecruitment
            for prospectID in prospectIDs {
                prospectRecruitment[prospectID] = ProspectRecruitmentState(
                    prospectID: prospectID,
                    phase: .committed,
                    commitmentHistory: [RecruitingCommitmentContext(
                        committedAt: CalendarState(
                            season: state.calendar.season,
                            week: CollegeRules.minimumCommitmentWeek
                        ),
                        winner: RecruitingCommitmentContenderContext(
                            programmeID: programmeID,
                            score: CollegeRules.minimumCommitmentScore,
                            explanation: [],
                            relationshipInterest: CollegeRules.minimumCommitmentScore,
                            nilAllocation: 0,
                            visitScheduled: false
                        )
                    )]
                )
            }
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: state.college.phase,
                programmes: programmeStates,
                prospectRecruitment: prospectRecruitment,
                archivedProspects: state.college.archivedProspects,
                redshirtPlans: state.college.redshirtPlans
            )
            let before = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )!

            expectEqual(before.activeReservations, reservationCount)
            expectEqual(before.maximumReservations, reservationCount)
            do {
                _ = try CollegeRedshirtSystem.designate(
                    playerID: playerID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: 4,
                    in: state
                )
                expect(false, "a plan stranded an already reserved commitment")
            } catch let error as RedshirtPlanError {
                expectEqual(error, .capacityConflict)
            }
            expectEqual(state.college.redshirtPlans[playerID], nil)
        }

        test("a designated player at four or fewer appearances preserves the competition season") {
            var state = GameState.bootstrap(seed: 85_201)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 2)
            }
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 2,
                in: state
            )
            state.competition.playerStatistics[playerID] = PlayerSeasonStatistics(
                playerID: playerID,
                games: 3
            )
            let completed = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.calendar = completed
            state.league.week = completed.week

            let transition = try SeasonLifecycleSystem.advance(
                after: completed,
                in: state
            )

            expectEqual(
                transition.players[playerID]?.eligibility,
                Eligibility(seasonsRemaining: 1, yearsRemaining: 1)
            )
            let careerSeason = transition.people.playerCareers[playerID]?.seasons.last
            expectEqual(careerSeason?.games, 3)
            expectEqual(careerSeason?.redshirtResolution, RedshirtSeasonResolution(
                outcome: .preservedCompetitionSeason,
                plannedAppearanceLimit: 2
            ))
            expect(transition.programmes[programmeID]?.rosterIDs.contains(playerID) == true)
            expect(transition.eventPayloads.contains(.redshirtResolved(
                playerID: playerID,
                programmeID: programmeID,
                appearances: 3,
                plannedAppearanceLimit: 2,
                outcome: .preservedCompetitionSeason
            )))
        }

        test("usage above four burns the season and records resolution before departure") {
            var state = GameState.bootstrap(seed: 85_202)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 2)
            }
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 4,
                in: state
            )
            state.competition.playerStatistics[playerID] = PlayerSeasonStatistics(
                playerID: playerID,
                games: 5
            )
            let completed = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.calendar = completed
            state.league.week = completed.week

            let transition = try SeasonLifecycleSystem.advance(
                after: completed,
                in: state
            )
            let resolution = DomainEventPayload.redshirtResolved(
                playerID: playerID,
                programmeID: programmeID,
                appearances: 5,
                plannedAppearanceLimit: 4,
                outcome: .burnedByUsage
            )
            let departure = DomainEventPayload.playerDeparted(
                playerID: playerID,
                organisationID: programmeID,
                reason: .graduated
            )

            expectEqual(transition.players[playerID], nil)
            expectEqual(
                transition.people.playerCareers[playerID]?.seasons.last?.redshirtResolution,
                RedshirtSeasonResolution(
                    outcome: .burnedByUsage,
                    plannedAppearanceLimit: 4
                )
            )
            expect(transition.eventPayloads.contains(resolution))
            expect(transition.eventPayloads.contains(departure))
            expect(
                transition.eventPayloads.firstIndex(of: resolution)! <
                    transition.eventPayloads.firstIndex(of: departure)!
            )
        }

        test("zero appearances without a designation still spend the competition season") {
            var state = GameState.bootstrap(seed: 85_204)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 2)
            }
            let completed = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            state.calendar = completed
            state.league.week = completed.week

            let transition = try SeasonLifecycleSystem.advance(
                after: completed,
                in: state
            )

            expectEqual(transition.players[playerID], nil)
            expectEqual(
                transition.people.playerCareers[playerID]?.seasons.last?.redshirtResolution,
                RedshirtSeasonResolution(
                    outcome: .notDesignated,
                    plannedAppearanceLimit: nil
                )
            )
            expect(!transition.eventPayloads.contains { payload in
                guard case let .redshirtResolved(resolvedID, _, _, _, _) = payload else {
                    return false
                }
                return resolvedID == playerID
            })
        }

        test("weekly scheduling preserves plans deterministically and through save restoration") {
            var state = GameState.bootstrap(seed: 85_205)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 0,
                in: state
            )

            let first = try WorldScheduler.advanceWeek(state)
            let replay = try WorldScheduler.advanceWeek(state)
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(first.state)
            )

            expectEqual(first, replay)
            expectEqual(first.state.college.redshirtPlans[playerID], state.college.redshirtPlans[playerID])
            expectEqual(restored, first.state)
            expect(WorldIntegrity.check(first.state).isValid)
        }

        test("rollover resets plans and retained resolution events bind uniquely to career history") {
            var state = GameState.bootstrap(seed: 85_206)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.college = try CollegeRedshirtSystem.designate(
                playerID: playerID,
                programmeID: programmeID,
                plannedAppearanceLimit: 0,
                in: state
            )
            let completed = CalendarState(
                season: state.calendar.season,
                week: SharedRules.inSeasonWeeks
            )
            state.calendar = completed
            state.league.week = completed.week
            let transition = try SeasonLifecycleSystem.advance(after: completed, in: state)
            let resolutionPayloads = transition.eventPayloads.filter { payload in
                guard case let .redshirtResolved(resolvedID, _, _, _, _) = payload else {
                    return false
                }
                return resolvedID == playerID
            }
            expectEqual(resolutionPayloads.count, 1)

            var cycleInput = state
            cycleInput.programmes = transition.programmes
            cycleInput.proTeams = transition.proTeams
            cycleInput.players = transition.players
            cycleInput.staff = transition.staff
            cycleInput.people = transition.people
            cycleInput.college.reconcileScholarships(with: cycleInput.programmes)
            let cycle = try CollegeCycleSystem.closeAndOpen(
                nextSeason: completed.season + 1,
                in: cycleInput
            )
            expectEqual(cycle.college.redshirtPlans, [:])

            var coverageInput = cycleInput
            coverageInput.programmes = cycle.programmes
            coverageInput.players = cycle.players
            coverageInput.people = cycle.people
            coverageInput.prospects = cycle.prospects
            coverageInput.college = cycle.college
            coverageInput.scouting = cycle.scouting
            let coverage = CollegeCycleSystem.addWalkOns(
                for: .postseasonCoverage,
                season: completed.season + 1,
                in: coverageInput
            )

            guard let resolutionPayload = resolutionPayloads.first,
                  case let .redshirtResolved(
                    _,
                    resolvedProgrammeID,
                    appearances,
                    plannedAppearanceLimit,
                    outcome
                  ) = resolutionPayload else { return }
            expectEqual(resolvedProgrammeID, programmeID)
            expectEqual(appearances, 0)
            expectEqual(plannedAppearanceLimit, 0)
            expectEqual(outcome, .preservedCompetitionSeason)

            var linked = cycleInput
            linked.programmes = coverage.programmes
            linked.players = coverage.players
            linked.people = coverage.people
            linked.prospects = cycle.prospects
            linked.college = cycle.college
            linked.scouting = cycle.scouting
            linked.calendar = completed.advancedWeek()
            linked.league.season = linked.calendar.season
            linked.league.week = linked.calendar.week
            linked.competition = CompetitionState.bootstrap(
                seed: linked.league.seed,
                season: linked.calendar.season,
                programmes: linked.programmes.values,
                proTeams: linked.proTeams.values
            )
            linked.competition = CompetitionReducer.rebuild(from: linked)
            let resolutionEvent = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: linked.league.seed,
                    sequence: linked.history.nextSequence
                ),
                sequence: linked.history.nextSequence,
                occurredAt: completed,
                payload: resolutionPayload
            )
            expect(linked.history.append(resolutionEvent))
            expect(WorldIntegrity.check(linked).isValid)
            expectEqual(
                try SaveEnvelope.decode(GameState.self, from: SaveEnvelope.encode(linked)),
                linked
            )

            let departedPlayerID = linked.people.departedPlayers.keys.sorted {
                $0.uuidString < $1.uuidString
            }.first { candidateID in
                linked.people.playerCareers[candidateID]?.seasons.last?.tier == .college
            }!
            let departedCareer = linked.people.playerCareers[departedPlayerID]!
            let departedSeason = departedCareer.seasons.last!
            expect(!linked.history.recent.contains { event in
                guard case let .redshirtResolved(candidateID, _, _, _, _) = event.payload else {
                    return false
                }
                return candidateID == departedPlayerID
            })

            let wrongTierSeason = PlayerCareerSeason(
                season: departedSeason.season,
                organisationID: linked.proTeams.ids[0],
                tier: .college,
                games: departedSeason.games,
                starts: departedSeason.starts,
                overallAtEnd: departedSeason.overallAtEnd,
                redshirtResolution: departedSeason.redshirtResolution
            )
            let wrongTierCareer = PlayerCareerRecord(
                playerID: departedPlayerID,
                recruitingOrigin: departedCareer.recruitingOrigin,
                seasons: Array(departedCareer.seasons.dropLast()) + [wrongTierSeason],
                portalWindows: departedCareer.portalWindows,
                endedAt: departedCareer.endedAt,
                endStatus: departedCareer.endStatus
            )
            var wrongTierRoot = linked
            wrongTierRoot.people = replacingPlayerCareer(wrongTierCareer, in: linked.people)
            expect(WorldIntegrity.check(wrongTierRoot).issues.contains(
                .invalidPlayerCareer(playerID: departedPlayerID)
            ))

            let futureEndCareer = PlayerCareerRecord(
                playerID: departedPlayerID,
                recruitingOrigin: departedCareer.recruitingOrigin,
                seasons: departedCareer.seasons,
                portalWindows: departedCareer.portalWindows,
                endedAt: CalendarState(season: linked.calendar.season + 1, week: 1),
                endStatus: departedCareer.endStatus
            )
            var futureEndRoot = linked
            futureEndRoot.people = replacingPlayerCareer(futureEndCareer, in: linked.people)
            expect(WorldIntegrity.check(futureEndRoot).issues.contains(
                .invalidPlayerCareer(playerID: departedPlayerID)
            ))

            let gapEndCareer = PlayerCareerRecord(
                playerID: departedPlayerID,
                recruitingOrigin: departedCareer.recruitingOrigin,
                seasons: departedCareer.seasons,
                portalWindows: departedCareer.portalWindows,
                endedAt: CalendarState(
                    season: departedSeason.season + 1,
                    week: SharedRules.inSeasonWeeks
                ),
                endStatus: departedCareer.endStatus
            )
            var gapEndRoot = linked
            gapEndRoot.calendar = CalendarState(
                season: departedSeason.season + 2,
                week: 1
            )
            gapEndRoot.people = replacingPlayerCareer(gapEndCareer, in: linked.people)
            expect(WorldIntegrity.check(gapEndRoot).issues.contains(
                .invalidPlayerCareer(playerID: departedPlayerID)
            ))

            let earlyEndCareer = PlayerCareerRecord(
                playerID: departedPlayerID,
                recruitingOrigin: departedCareer.recruitingOrigin,
                seasons: departedCareer.seasons,
                portalWindows: departedCareer.portalWindows,
                endedAt: CalendarState(season: departedSeason.season, week: 1),
                endStatus: departedCareer.endStatus
            )
            var earlyEndRoot = linked
            earlyEndRoot.people = replacingPlayerCareer(earlyEndCareer, in: linked.people)
            expect(WorldIntegrity.check(earlyEndRoot).issues.contains(
                .invalidPlayerCareer(playerID: departedPlayerID)
            ))

            var mismatchedLedger = DomainEventLedger(
                retentionLimit: linked.history.retentionLimit
            )
            for event in linked.history.recent {
                let payload: DomainEventPayload = event.id == resolutionEvent.id
                    ? .redshirtResolved(
                        playerID: playerID,
                        programmeID: programmeID,
                        appearances: appearances + 1,
                        plannedAppearanceLimit: plannedAppearanceLimit,
                        outcome: outcome
                    )
                    : event.payload
                expect(mismatchedLedger.append(DomainEvent(
                    id: event.id,
                    sequence: event.sequence,
                    occurredAt: event.occurredAt,
                    payload: payload
                )))
            }
            var mismatched = linked
            mismatched.history = mismatchedLedger
            expect(WorldIntegrity.check(mismatched).issues.contains(
                .invalidHistoricalEvent(eventID: resolutionEvent.id)
            ))

            var entries: [(CalendarState, DomainEventPayload, Bool)] = []
            for event in linked.history.recent {
                entries.append((event.occurredAt, event.payload, false))
                if event.id == resolutionEvent.id {
                    entries.append((event.occurredAt, event.payload, true))
                }
            }
            var duplicateLedger = DomainEventLedger(
                retentionLimit: linked.history.retentionLimit
            )
            var duplicateEventID: UUID?
            for (sequence, entry) in entries.enumerated() {
                let eventID = DomainEvent.deterministicID(
                    rootSeed: linked.league.seed,
                    sequence: sequence
                )
                expect(duplicateLedger.append(DomainEvent(
                    id: eventID,
                    sequence: sequence,
                    occurredAt: entry.0,
                    payload: entry.1
                )))
                if entry.2 { duplicateEventID = eventID }
            }
            var duplicated = linked
            duplicated.history = duplicateLedger
            expect(WorldIntegrity.check(duplicated).issues.contains(
                .invalidHistoricalEvent(eventID: duplicateEventID!)
            ))
        }
    }
}
