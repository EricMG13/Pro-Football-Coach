import Foundation
import FootballSimCore

private func assertWeeklyInjuryEvidence() {
    var selected: GameState?
    for seed in 82_100...82_611 {
        var candidate = GameState.bootstrap(seed: UInt64(seed))
        candidate.calendar = CalendarState(season: 0, week: 2)
        candidate.league.week = 2
        guard var game = candidate.competition.currentSchedule.games.first(where: {
            $0.tier == .college && $0.week == 1 && $0.result == nil
        }),
              let programme = candidate.programmes[game.homeID],
              let awayProgramme = candidate.programmes[game.awayID],
              let playerID = programme.rosterIDs.first else { continue }
        let evidence = GameEvidence(
            fixtureID: game.id,
            record: GameRecord(homeScore: 7, awayScore: 0, drives: [], tier: .college),
            homeParticipantIDs: programme.rosterIDs,
            awayParticipantIDs: awayProgramme.rosterIDs,
            callInReceipts: []
        )
        game.result = DetailedGameSummaryBuilder.make(
            record: evidence.record,
            homeParticipantIDs: programme.rosterIDs,
            awayParticipantIDs: awayProgramme.rosterIDs,
            evidence: evidence
        )
        expect(candidate.competition.currentSchedule.replace(game))
        candidate.competition = CompetitionReducer.rebuildStandings(from: candidate)
        candidate.competition = CompetitionReducer.rebuildStatistics(from: candidate)
        _ = candidate.people.updatePlayerLifecycle(playerID) {
            $0.applyWorkload(PeopleRules.fatigueRange.upperBound)
        }
        let health = PeopleLifecycleSystem.processHealth(at: candidate.calendar, in: candidate)
        if health.eventPayloads.contains(where: {
            if case let .playerInjured(id, _, _, _) = $0 { return id == playerID }
            return false
        }) {
            selected = candidate
            break
        }
    }
    guard let selected else {
        expect(false, "the bounded deterministic injury search found no receipt case")
        return
    }
    let integrity = WorldIntegrity.check(selected)
    expect(integrity.isValid, integrity.issues.map(\.description).joined(separator: ", "))
    let transition: WorldTransition
    do {
        transition = try WorldScheduler.advanceWeek(selected)
    } catch {
        expect(false, "weekly injury evidence advance failed: \(error)")
        return
    }
    let detailed = transition.state.competition.currentSchedule.games.first(where: {
        $0.week == 1 && $0.result?.source == .detailed
    })
    expect(detailed?.result?.evidence?.injuries.isEmpty == false)
    expectEqual(detailed?.result?.evidence?.injuries.first?.occurredAt, CalendarState(season: 0, week: 1))
}

func runInjuryEvidenceTests() {
    suite("Injury evidence") {
        test("weekly injuries become receipt-backed detailed-game evidence") {
            assertWeeklyInjuryEvidence()
        }
    }
}

func runPeopleLifecycleTests() {
    suite("People lifecycle state") {
        test("bootstrap covers every player with neutral bounded lifecycle state") {
            let state = GameState.bootstrap(seed: 80_001)

            expectEqual(Set(state.people.playerLifecycle.keys), Set(state.players.ids))
            expectEqual(Set(state.people.playerCareers.keys), Set(state.players.ids))
            expect(state.people.playerLifecycle.values.allSatisfy {
                $0.fatigue == 0 && $0.injury == nil && $0.status == .active
            })
            expect(state.people.playerCareers.values.allSatisfy { $0.seasons.isEmpty })
            expectEqual(Set(state.people.staffCareers.keys), Set(state.staff.ids))
        }

        test("people state survives the save envelope byte-identically") {
            let state = GameState.bootstrap(seed: 80_002)
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            )
            expectEqual(restored.people, state.people)
        }

        test("compaction keeps active and recent people while discarding stale records") {
            let state = GameState.bootstrap(seed: 80_003)
            let activeID = state.players.ids[0]
            let recentDepartureID = state.players.ids[1]
            let staleDepartureID = state.players.ids[2]
            let retainedStaffID = state.staff.ids[0]
            let staleStaffID = state.staff.ids[1]
            var people = state.people
            people.archive(player: state.players[recentDepartureID]!, status: .graduated)
            people.archive(player: state.players[staleDepartureID]!, status: .graduated)

            let compacted = people.compacted(
                retainingPlayerIDs: [recentDepartureID],
                staffIDs: [retainedStaffID]
            )

            expect(compacted.playerLifecycle[activeID] != nil)
            expect(compacted.playerCareers[activeID] != nil)
            expect(compacted.departedPlayers[recentDepartureID] != nil)
            expect(compacted.playerCareers[recentDepartureID] != nil)
            expect(compacted.departedPlayers[staleDepartureID] == nil)
            expect(compacted.playerCareers[staleDepartureID] == nil)
            expect(compacted.staffCareers[retainedStaffID] != nil)
            expect(compacted.staffCareers[staleStaffID] == nil)
        }

        test("compaction preserves durable portal history for departed players") {
            var state = GameState.bootstrap(seed: 80_004)
            let programmeID = state.programmes.ids[0]
            let player = state.players.values[0]
            expect(state.people.updatePlayerCareer(player.id) { career in
                expect(career.append(PlayerCareerSeason(
                    season: 0,
                    organisationID: programmeID,
                    tier: .college,
                    games: 8,
                    starts: 5,
                    overallAtEnd: player.overall
                )))
                expect(career.append(portalWindowRecord(
                    playerID: player.id,
                    sourceProgrammeID: programmeID,
                    targetSeason: 1,
                    window: .postseason
                )))
                career.end(at: CalendarState(season: 1, week: 1), status: .graduated)
            })
            state.people.archive(player: player, status: .graduated)

            let compacted = state.people.compacted(
                retainingPlayerIDs: [],
                staffIDs: []
            )

            expectEqual(compacted.playerCareers[player.id], state.people.playerCareers[player.id])
            expectEqual(compacted.playerCareers[player.id]?.portalWindows.count, 1)
            expect(compacted.departedPlayers[player.id] != nil)
        }

        test("attribute history is causal, bounded, and legacy-defaulted") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000008010")!
            var lifecycle = PlayerLifecycleState(playerID: playerID)
            for week in 1...(PeopleRules.recentChangeHistoryLimit + 2) {
                lifecycle.recordDevelopment(DevelopmentSummary(
                    occurredAt: CalendarState(season: 0, week: week),
                    components: [DevelopmentComponent(reason: .practice, value: 1)],
                    attributeChanges: [AttributeDevelopment(attribute: .speed, delta: 1)]
                ))
            }
            expectEqual(lifecycle.recentChanges.count, PeopleRules.recentChangeHistoryLimit)
            expectEqual(lifecycle.recentChanges.first?.occurredAt.week, 3)
            expectEqual(lifecycle.recentChanges.last?.cause, .practice)

            var legacy = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(PlayerLifecycleState(playerID: playerID))
            ) as! [String: Any]
            legacy.removeValue(forKey: "recentChanges")
            let restored = try JSONDecoder.stable().decode(
                PlayerLifecycleState.self,
                from: JSONSerialization.data(withJSONObject: legacy)
            )
            expect(restored.recentChanges.isEmpty, "legacy lifecycle did not default history")
        }

        test("persisted fatigue outside its legal range is rejected") {
            let lifecycle = PlayerLifecycleState(
                playerID: UUID(uuidString: "00000000-0000-4000-8000-000000008001")!
            )
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(lifecycle)
            ) as! [String: Any]
            object["fatigue"] = PeopleRules.fatigueRange.upperBound + 1
            let corrupted = try JSONSerialization.data(withJSONObject: object)

            do {
                _ = try JSONDecoder().decode(PlayerLifecycleState.self, from: corrupted)
                expect(false, "an out-of-range fatigue value decoded")
            } catch {
                expect(true)
            }
        }

        test("persisted people subrecords reject impossible values") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000008004")!
            let organisationID = UUID(uuidString: "00000000-0000-4000-8000-000000008005")!
            let season = PlayerCareerSeason(
                season: 0,
                organisationID: organisationID,
                tier: .college,
                games: 12,
                starts: 0,
                overallAtEnd: Rating(60)
            )
            var seasonObject = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(season)
            ) as! [String: Any]
            seasonObject["games"] = -1

            let summary = DevelopmentSummary(
                occurredAt: CalendarState(),
                components: [DevelopmentComponent(reason: .practice, value: 1)],
                attributeChanges: [AttributeDevelopment(attribute: .speed, delta: 1)]
            )
            var summaryObject = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(summary)
            ) as! [String: Any]
            var changes = summaryObject["attributeChanges"] as! [[String: Any]]
            changes[0]["delta"] = 99
            summaryObject["attributeChanges"] = changes

            let departedPlayer = Player(
                id: playerID,
                firstName: "Test",
                lastName: "Player",
                position: .quarterback,
                age: 22,
                attributes: Attributes(),
                potential: Rating(60)
            )
            let identity = DepartedPlayerIdentity(player: departedPlayer, status: .retired)
            var identityObject = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(identity)
            ) as! [String: Any]
            identityObject["finalAge"] = -10

            for (type, object) in [
                (PlayerCareerSeason.self, seasonObject),
                (DevelopmentSummary.self, summaryObject),
                (DepartedPlayerIdentity.self, identityObject),
            ] as [(any Decodable.Type, [String: Any])] {
                let data = try JSONSerialization.data(withJSONObject: object)
                do {
                    _ = try JSONDecoder().decode(type, from: data)
                    expect(false, "an impossible persisted people subrecord decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("career season history remains bounded and chronological") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000008002")!
            let organisationID = UUID(uuidString: "00000000-0000-4000-8000-000000008003")!
            var career = PlayerCareerRecord(playerID: playerID, portalWindows: [])
            for season in 0..<(PeopleRules.careerSeasonHistoryLimit + 5) {
                career.append(PlayerCareerSeason(
                    season: season,
                    organisationID: organisationID,
                    tier: .college,
                    games: 12,
                    starts: 0,
                    overallAtEnd: Rating(60)
                ))
            }

            expectEqual(career.seasons.count, PeopleRules.careerSeasonHistoryLimit)
            expectEqual(career.seasons.first?.season, 5)
            expectEqual(career.seasons.last?.season, PeopleRules.careerSeasonHistoryLimit + 4)
        }

        test("whole-root integrity rejects missing and orphan lifecycle keys") {
            var state = GameState.bootstrap(seed: 80_003)
            let missingID = state.players.ids[0]
            let orphanID = UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFF8003")!
            let lifecycle = state.people.playerLifecycle.values.filter {
                $0.playerID != missingID
            } + [PlayerLifecycleState(playerID: orphanID)]
            state.people = PeopleState(
                playerLifecycle: lifecycle,
                playerCareers: Array(state.people.playerCareers.values),
                staffCareers: []
            )

            let issues = WorldIntegrity.check(state).issues
            expect(issues.contains { issue in
                if case .missingPlayerLifecycle(playerID: missingID) = issue { return true }
                return false
            })
            expect(issues.contains { issue in
                if case .orphanPlayerLifecycle(playerID: orphanID) = issue { return true }
                return false
            })
        }

        test("whole-root integrity rejects an impossible active player age") {
            var state = GameState.bootstrap(seed: 80_004)
            let playerID = state.players.ids[0]
            state.players.update(playerID) { $0.age = PeopleRules.playerAgeRange.upperBound + 1 }

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidPlayerLifecycle(playerID: playerID) = issue { return true }
                return false
            })
        }
    }


    suite("Initial staff population") {
        test("every organisation has the exact coaching structure") {
            let state = GameState.bootstrap(seed: 81_001)
            let organisations = state.programmes.values.map { ($0.id, $0.staffIDs) }
                + state.proTeams.values.map { ($0.id, $0.staffIDs) }

            expectEqual(
                state.staff.count,
                (CollegeRules.programmeCount + ProRules.teamCount) * PeopleRules.staffPerOrganisation
            )
            for (organisationID, staffIDs) in organisations {
                expectEqual(staffIDs.count, PeopleRules.staffPerOrganisation)
                let staff = staffIDs.compactMap { state.staff[$0] }
                expectEqual(staff.filter { $0.role == .headCoach }.count, 1)
                for role in StaffRole.coordinators {
                    expectEqual(staff.filter { $0.role == role }.count, 1)
                }
                for group in PositionGroup.allCases {
                    expectEqual(staff.filter {
                        $0.role == .positionCoach && $0.positionGroup == group
                    }.count, 1)
                }
                expect(staff.allSatisfy { PeopleRules.staffAgeRange.contains($0.age) })
                expect(staff.allSatisfy { member in
                    CoachAttribute.allCases.allSatisfy { attribute in
                        SharedRules.ratingRange.contains(member.rating(attribute).value)
                    }
                })
                expect(staffIDs.allSatisfy { id in
                    state.people.staffCareers[id]?.assignments.last?.organisationID
                        == organisationID
                })
            }
        }

        test("staff generation is deterministic and passes employment integrity") {
            let first = GameState.bootstrap(seed: 81_002)
            let second = GameState.bootstrap(seed: 81_002)

            expectEqual(try SaveEnvelope.encode(first.staff), try SaveEnvelope.encode(second.staff))
            let report = WorldIntegrity.check(first)
            expect(report.isValid, report.issues.map(\.description).joined(separator: ", "))
        }
    }


    suite("Weekly health lifecycle") {
        test("the scheduler activates health and applies prior-game workload deterministically") {
            let initial = GameState.bootstrap(seed: 82_001)
            let afterWeekOne = try WorldScheduler.advanceWeek(initial)
            let first = try WorldScheduler.advanceWeek(afterWeekOne.state)
            let second = try WorldScheduler.advanceWeek(afterWeekOne.state)

            expectEqual(first.state.people, second.state.people)
            expectEqual(
                first.stepRecords.first { $0.step == .injuriesAndRecovery }?.status,
                .executed
            )
            expect(first.state.people.playerLifecycle.values.contains { $0.fatigue > 0 },
                   "completed games produced no player workload")
            expect(first.state.people.playerLifecycle.values.allSatisfy {
                PeopleRules.fatigueRange.contains($0.fatigue)
            })
        }

        test("weekly injuries become receipt-backed detailed-game evidence") {
            assertWeeklyInjuryEvidence()
        }

        test("an injury recovers to availability on its final week") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000008201")!
            var lifecycle = PlayerLifecycleState(
                playerID: playerID,
                injury: PlayerInjury(
                    area: .ankle,
                    severity: .minor,
                    occurredAt: CalendarState(),
                    originalWeeks: 1,
                    weeksRemaining: 1
                )
            )

            let recovered = lifecycle.recoverWeek()
            expect(recovered)
            expect(lifecycle.isAvailable)
            expectEqual(lifecycle.injury, nil)
        }

        test("injured players are excluded from abstract roster strength") {
            var healthy = GameState.bootstrap(seed: 82_002)
            let game = healthy.competition.currentSchedule.games.first { $0.tier == .college }!
            let healthyResult = AbstractGameSimulator.play(game, in: healthy)
            let injury = PlayerInjury(
                area: .knee,
                severity: .severe,
                occurredAt: healthy.calendar,
                originalWeeks: 8,
                weeksRemaining: 8
            )
            for id in healthy.programmes[game.homeID]!.rosterIDs {
                healthy.people.updatePlayerLifecycle(id) { $0.sustain(injury) }
            }
            let depletedResult = AbstractGameSimulator.play(game, in: healthy)

            expect(healthyResult != depletedResult,
                   "removing an entire roster from availability did not alter the simulation")
        }

        test("fatigue raises injury risk and durability lowers it") {
            let restedDurable = PeopleRules.injuryProbability(
                fatigue: 0,
                durability: Rating(90)
            )
            let tiredDurable = PeopleRules.injuryProbability(
                fatigue: 90,
                durability: Rating(90)
            )
            let tiredFragile = PeopleRules.injuryProbability(
                fatigue: 90,
                durability: Rating(45)
            )
            expect(tiredDurable > restedDurable)
            expect(tiredFragile > tiredDurable)
        }
    }


    suite("Explainable development") {
        test("a development checkpoint is deterministic, bounded, and reasoned") {
            let state = GameState.bootstrap(seed: 83_001)
            let calendar = CalendarState(season: 0, week: 8)
            let first = DevelopmentSystem.practice(at: calendar, in: state)
            let second = DevelopmentSystem.practice(at: calendar, in: state)

            expectEqual(first, second)
            expect(!first.eventPayloads.isEmpty, "the checkpoint developed nobody")
            var changed = 0
            for id in state.players.ids {
                guard let before = state.players[id], let after = first.players[id] else { continue }
                for attribute in before.position.ratedAttributes {
                    let delta = after.attributes[attribute].value - before.attributes[attribute].value
                    expect((-1...1).contains(delta))
                    expect(after.attributes[attribute].value <= before.potential.value
                        || delta <= 0)
                    if delta != 0 { changed += 1 }
                }
                if let summary = first.people.playerLifecycle[id]?.lastDevelopment {
                    expectEqual(summary.occurredAt, calendar)
                    expectEqual(Set(summary.components.map(\.reason)).count,
                                summary.components.count)
                }
            }
            expectEqual(changed, first.eventPayloads.count)
        }

        test("the scheduler exposes practice as an activated ordered step") {
            let transition = try WorldScheduler.advanceWeek(GameState.bootstrap(seed: 83_002))
            expectEqual(
                transition.stepRecords.first { $0.step == .practiceAndDevelopment }?.status,
                .executed
            )
        }
    }


    suite("Season-boundary people lifecycle") {
        test("rollover advances careers and preserves minimum coverage deterministically") {
            var first = GameState.bootstrap(seed: 84_001)
            var second = GameState.bootstrap(seed: 84_001)
            let initialPlayerIDs = Set(first.players.ids)
            let initialProspectIDs = Set(first.prospects.ids)
            var rolloverEvents: [DomainEvent] = []
            for _ in 0..<SharedRules.inSeasonWeeks {
                let firstTransition = try WorldScheduler.advanceWeek(first)
                first = firstTransition.state
                rolloverEvents = firstTransition.emittedEvents
                second = try WorldScheduler.advanceWeek(second).state
            }

            expectEqual(first, second)
            expectEqual(first.calendar, CalendarState(season: 1, week: 1))
            let activeRosterIDs = Set(
                first.programmes.values.flatMap(\.rosterIDs)
                    + first.proTeams.values.flatMap(\.rosterIDs)
            )
            // Every player the store holds is either on a roster or in the professional market.
            //
            // This asserted `players.count == activeRosterIDs.count` until 2026-08-13, when
            // `0deb629` gave a generated world contracts to expire: beat 1 (`02` §4.2a) *is*
            // players leaving a roster at the season boundary without leaving the world, and the
            // old equality said that must never happen. The invariant that matters — no player
            // exists whom nothing accounts for — survives, and is stronger than a count.
            let accountedIDs = activeRosterIDs
                .union(first.proTeams.values.flatMap(\.practiceSquadIDs))
                .union(first.proMarket.freeAgentIDs)
            expect(Set(first.players.ids).subtracting(accountedIDs).isEmpty,
                   "players exist that no roster and no market accounts for")
            expect(!first.proMarket.freeAgentIDs.isEmpty,
                   "a season boundary passed and no contract reached free agency (02 section 4.2a)")
            expect(!first.people.departedPlayers.isEmpty,
                   "departed identities were not retained in compact history")
            for programme in first.programmes.values {
                expect(programme.rosterIDs.count <= CollegeRules.rosterLimit)
                let counts = Dictionary(
                    grouping: programme.rosterIDs.compactMap { first.players[$0]?.position },
                    by: { $0 }
                ).mapValues(\.count)
                for position in Position.allCases {
                    expect((counts[position] ?? 0)
                        >= (SharedRules.minimumPlayableRosterByPosition[position] ?? 0))
                }
                expect(programme.rosterIDs.allSatisfy {
                    first.players[$0]?.eligibility?.isExhausted == false
                        && first.people.playerLifecycle[$0]?.status == .active
                })
            }
            for team in first.proTeams.values {
                // A professional roster is *below* the limit here, and that is beat 1 working
                // rather than a defect: `02` §4.2a says a roster drops below 53 because contracts
                // ended, and that this is what makes room for free agency and the draft. The
                // assertion was `== activeRosterLimit` until 2026-08-13, which described the world
                // before `0deb629` gave it any contract to expire.
                expect(team.rosterIDs.count <= ProRules.activeRosterLimit,
                       "a professional roster exceeded the limit")
                expect(team.rosterIDs.count > 0, "a professional roster was emptied")
                expect(team.rosterIDs.allSatisfy {
                    first.people.playerLifecycle[$0]?.status == .active
                })
                // What must still hold at every point of the offseason: somebody can play every
                // position. That is the invariant the expiry exemption exists to protect.
                let counts = Dictionary(
                    grouping: team.rosterIDs.compactMap { first.players[$0]?.position },
                    by: { $0 }
                ).mapValues(\.count)
                for (position, minimum) in SharedRules.minimumPlayableRosterByPosition {
                    expect(counts[position, default: 0] >= minimum,
                           "\(team.id) has \(counts[position, default: 0]) at "
                               + "\(position.rawValue), below the playable minimum of \(minimum)")
                }
            }
            let departed = initialPlayerIDs.filter {
                first.people.departedPlayers[$0] != nil
            }
            expect(!departed.isEmpty, "one full season produced no graduation or retirement")
            expect(departed.allSatisfy { first.people.playerCareers[$0]?.endedAt != nil })
            expect(initialPlayerIDs.allSatisfy {
                first.people.playerCareers[$0]?.seasons.count == 1
            })
            expectEqual(first.college.recruitingSeason, 1)
            expectEqual(first.college.phase, .active)
            expectEqual(first.prospects.count, CollegeRules.annualProspectCount)
            expect(Set(first.prospects.ids).isDisjoint(with: initialProspectIDs))
            expect(first.college.prospectRecruitment.values.allSatisfy {
                $0.phase == .available && $0.programmeID == nil
            })
            expect(first.college.programmes.values.allSatisfy {
                $0.boardIDs.isEmpty && $0.relationships.isEmpty
            })
            expect(first.scouting.observationsByObserver.isEmpty)
            expect(first.scouting.pendingEvaluations.isEmpty)

            let programmeIDs = Set(first.programmes.ids)
            let collegeIntakeSources = rolloverEvents.compactMap { event -> PlayerIntakeSource? in
                guard case let .playerJoined(_, organisationID, source) = event.payload,
                      programmeIDs.contains(organisationID) else { return nil }
                return source
            }
            expect(!collegeIntakeSources.isEmpty)
            expect(!collegeIntakeSources.contains(.provisionalReplacement))
            expect(collegeIntakeSources.allSatisfy {
                $0 == .recruitedScholarship || $0 == .walkOn
            })
            expect(first.programmes.values.flatMap(\.rosterIDs).contains {
                initialProspectIDs.contains($0)
            }, "no committed prospect retained identity through signing")
            expect(WorldIntegrity.check(first).isValid)
        }

        test("the staff market resolves a planted head-coach vacancy before integrity") {
            var state = GameState.bootstrap(seed: 84_002)
            let programmeID = state.programmes.ids[0]
            let originalHeadID = state.programmes[programmeID]!.staffIDs.first {
                state.staff[$0]?.role == .headCoach
            }!
            state.programmes.update(programmeID) {
                $0.staffIDs.removeAll { $0 == originalHeadID }
            }

            let transition = try WorldScheduler.advanceWeek(state)
            let staff = transition.state.programmes[programmeID]!.staffIDs.compactMap {
                transition.state.staff[$0]
            }
            expectEqual(staff.filter { $0.role == .headCoach }.count, 1)
            expect(WorldIntegrity.check(transition.state).isValid)
            expect(transition.emittedEvents.contains { event in
                if case .staffHired(_, organisationID: programmeID, role: .headCoach) = event.payload {
                    return true
                }
                return false
            })
        }


        test("integrity rejects an exhausted player left on a college roster") {
            var state = GameState.bootstrap(seed: 84_003)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.players.update(playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 0, yearsRemaining: 1)
            }

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidPlayerLifecycle(playerID: playerID) = issue { return true }
                return false
            })
        }
    }

    suite("Lifecycle distributions hold their bands") {
        test("the age curve and the injured share hold their bands across a long run") {
            var state = GameState.bootstrap(seed: 84_010)
            let measured = [1, 3, 6, 10]
            var injuries: [(ironman: Bool, severity: InjurySeverity, weeks: Int)] = []
            var previousRosters = rosterSnapshot(state)
            var suspensionsThisSeason = 0
            var playerWeeksThisSeason = 0
            checkProAgeCurve(state, season: 0)
            checkRatingSpread(state, season: 0, assertTierGap: false)
            for season in 1...(measured.max() ?? 1) {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    let transition = try WorldScheduler.advanceWeek(state)
                    state = transition.state
                    // Player-weeks counted from the rosters the draw actually reads, so the
                    // denominator is the population at risk rather than the whole player store.
                    playerWeeksThisSeason += state.programmes.values.reduce(0) {
                        $0 + $1.rosterIDs.count
                    } + state.proTeams.values.reduce(0) { $0 + $1.rosterIDs.count }
                    for event in transition.emittedEvents {
                        if case .playerSuspended = event.payload { suspensionsThisSeason += 1 }
                        guard case let .playerInjured(playerID, _, severity, weeks)
                            = event.payload else { continue }
                        injuries.append((
                            state.players[playerID]?.has(.ironman) ?? false,
                            severity,
                            weeks
                        ))
                    }
                    // Sampled in-season rather than at the boundary the age curve uses: the injured
                    // share is a steady state that fatigue has to build up to, and week 1 of a new
                    // season measures an offseason population that no weekly draw has touched.
                    if measured.contains(season), state.calendar.week == injurySampleWeek {
                        checkInjuredShare(state, season: season)
                    }
                }
                // Snapshotted every season rather than only at a measured one, because churn is a
                // difference between consecutive boundaries and the measured indices are not
                // consecutive. The set arithmetic is free next to the season it walks.
                let currentRosters = rosterSnapshot(state)
                defer { previousRosters = currentRosters }
                let seasonSuspensions = suspensionsThisSeason
                let seasonPlayerWeeks = playerWeeksThisSeason
                suspensionsThisSeason = 0
                playerWeeksThisSeason = 0
                guard measured.contains(season) else { continue }
                checkProAgeCurve(state, season: season)
                checkRatingSpread(state, season: season, assertTierGap: false)
                checkDisciplineFrequency(
                    incidents: seasonSuspensions,
                    playerWeeks: seasonPlayerWeeks,
                    season: season
                )
                checkChurn(from: previousRosters, to: currentRosters, season: season,
                           assertPro: false)
            }
            checkIronmanShortensInjuries(injuries)
        }
    }
}

// MARK: - The professional age curve band

// `01` §6.5 bands the match engine and nothing bands the people model. The soak asserted only that
// every professional is at least 22 and short of `declineAge + guaranteedRetirementYearsAfterDecline`
// — a bound, which a league of nothing but 23-year-olds and a league of nothing but 33-year-olds
// both satisfy. Two limbs, both stated before either was measured:
//
// **Mean age, 25.0…27.5.** External anchor: league-wide mean roster age in the professional game
// sits near 26 and has been stable for decades. No page was retrieved for that figure in this
// environment, so by `01` §0.1 it grades `provisional [U]` and the band carries roughly ±1.3 years
// rather than a tight interval. Its upper limb is also the model's own ceiling, derived below.
//
// **Share at or past their position's decline age, 0.08…0.30.** Derived `[P]` from constants this
// repo already fixes. `SeasonLifecycleSystem.retires` escalates the hazard: a player k years past
// decline retires with probability `(k + 1) * retirementProbabilityPerYearAfterDecline`, so survival
// runs 0.86, 0.72, 0.58, 0.44, 0.30, 0.16, 0.02 and reaches zero at k = 7 — inside
// `guaranteedRetirementYearsAfterDecline`, which is therefore a backstop rather than the binding
// constraint. Expected presence past decline is the sum of P(present at k) ≈ 3.04 seasons, against a
// pre-decline span of `D - 22` ≈ 8.4 seasons at the playable-minimum-weighted decline age of ≈ 30.4.
// That gives a ceiling share of 3.04 / 11.44 ≈ 0.27 and a ceiling mean age of ≈ 27.3. Every other
// exit the professional market owns — cuts, contract expiry, the draft — removes veterans faster
// than rookies, so the realised figures must sit below those ceilings. The floor is the point at
// which the veteran tail has effectively stopped existing.
//
// Asserted at several season indices rather than once at the end, for the reason `ProSoakTests`
// gives: a check that fires only at the finish says something drifted without saying when.

private let proMeanAgeBand: ClosedRange<Double> = 25.0...27.5
private let proPastDeclineShareBand: ClosedRange<Double> = 0.08...0.30

/// The first season whose veteran tail is the model's own rather than the bootstrap population's.
///
/// The share above is a steady-state figure -- its ceiling is derived from the retirement hazard
/// running to equilibrium, and its floor is "the point at which the veteran tail has effectively
/// stopped existing". A generated world does not start in that equilibrium. It is seeded with a
/// full age spread, that founding cohort ages out together, and the share troughs before the
/// population re-equilibrates. Measured across a long run:
///
///     season  0   share 0.228
///     season  1   share 0.196
///     season  3   share 0.134
///     season  6   share 0.067
///     season 10   share 0.162
///
/// Season 6 sat below the steady floor and the run failed there for two days, reading as though
/// veterans were being culled. They were not: four seasons later the tail is back inside the band.
/// Asserting a steady-state floor against a transient is what was wrong, not the model and not the
/// floor.
///
/// 10 rather than 8 because 10 is the first season *measured* back inside the band. The crossing is
/// somewhere in (6, 10] and no checkpoint observes 7, 8 or 9, so gating on 8 would apply the strict
/// floor to a season nobody has looked at -- the same mistake this constant exists to fix. A later
/// checkpoint in that gap gets the transient band, which is the safe direction to be wrong in.
private let proSteadyStateSeason = 10

/// What the share may do while the founding cohort is still washing through.
///
/// Deliberately not derived, and it must not be read as one: the steady band comes `[P]` from
/// constants this repo fixes, this one is `[M]` -- an empirical guard around a known artefact. The
/// observed trough is 0.067, and 0.05 leaves headroom under it while still failing if the tail
/// halves again. Its purpose is to catch a real collapse during the transient, not to bless the
/// transient's shape. If world generation is ever made to start in equilibrium this whole
/// distinction should be deleted rather than retuned.
private let proTransientPastDeclineShareBand: ClosedRange<Double> = 0.05...0.30

/// Both limbs of the age-curve band, over the active professional rosters.
///
/// Practice squads are excluded on purpose: the anchor is a 53-man mean, and folding in a
/// developmental pool of rookies would move the measured number for a reason the band is not about.
func checkProAgeCurve(_ state: GameState, season: Int) {
    let players = state.proTeams.values.flatMap(\.rosterIDs).compactMap { state.players[$0] }
    guard !players.isEmpty else {
        expect(false, "season \(season): no professional players to measure an age curve over")
        return
    }
    let mean = Double(players.reduce(0) { $0 + $1.age }) / Double(players.count)
    let pastDeclineShare = Double(players.filter(\.isDeclining).count) / Double(players.count)
    print(String(
        format: "pro age curve: season %d, n %d, mean %.2f, past-decline share %.3f",
        season, players.count, mean, pastDeclineShare
    ))
    expect(proMeanAgeBand.contains(mean), String(
        format: "season %d: professional mean age %.2f is outside the band %.1f…%.1f",
        season, mean, proMeanAgeBand.lowerBound, proMeanAgeBand.upperBound
    ))
    // Which band applies is a property of the season, not of the measurement: before the founding
    // cohort has washed through, the steady-state floor is measuring something the model has not
    // had a chance to produce yet.
    let steady = season >= proSteadyStateSeason
    let band = steady ? proPastDeclineShareBand : proTransientPastDeclineShareBand
    expect(band.contains(pastDeclineShare), String(
        format: "season %d: %.3f of professionals are at or past their decline age, outside the "
            + "%@ band %.2f…%.2f",
        season, pastDeclineShare,
        steady ? "steady-state" : "bootstrap-transient",
        band.lowerBound, band.upperBound
    ))
}

// MARK: - The injured-share band

// What share of active players is carrying an injury in a given week. The soak asserted `> 0` and
// `< 10%` — a bound so wide that a model producing 0.5% and a model producing 9% both satisfy it,
// which is to say it detects only "injuries exist at all".
//
// **Band 0.015…0.055, derived `[P]` from constants this repo already fixes.**
// `PeopleLifecycleSystem.processHealth` draws once per player who appeared in last week's completed
// game, at `PeopleRules.injuryProbability` = `0.001 + fatigue * 0.000_15 + (99 - durability) *
// 0.000_08`. Fatigue nets `gameFatigueLoad - weeklyFatigueRecovery` = +4 a week plus up to
// `statisticalWorkloadFatigueMaximum`, so by the sample week a playing population sits somewhere
// around 45…70 against a generated durability centred near 70 — a weekly probability of roughly
// 0.008…0.014. Mean weeks lost is `0.72 * 1.5 + 0.23 * 4.5 + 0.05 * 10.5` = 2.64 from
// `PeopleRules.injurySeverity`'s ladder. An injured player takes no further draw, so the steady
// state is close to probability times duration: 0.021…0.037. The band is widened either side
// because fatigue is a distribution rather than a point, a bye week removes a whole team from the
// draw, and the postseason shrinks the participating population to a bracket.
//
// **This band describes the model as specified, not the sport.** Real football carries a materially
// higher unavailable share than 2-4% in a given week. That gap is a design question for the owner —
// `02` §11.3.3 and the injury constants would both have to move — and it is deliberately not
// resolved by loosening a test.

/// Late enough for fatigue to have built, early enough to be before the season boundary.
private let injurySampleWeek = 12
private let injuredShareBand: ClosedRange<Double> = 0.015...0.055

func checkInjuredShare(_ state: GameState, season: Int) {
    let activeIDs = state.programmes.values.flatMap(\.rosterIDs)
        + state.proTeams.values.flatMap(\.rosterIDs)
    guard !activeIDs.isEmpty else {
        expect(false, "season \(season): no active players to measure an injured share over")
        return
    }
    let injured = activeIDs.filter { state.people.playerLifecycle[$0]?.injury != nil }.count
    let share = Double(injured) / Double(activeIDs.count)
    print(String(
        format: "injured share: season %d week %d, n %d, injured %d, share %.4f",
        season, injurySampleWeek, activeIDs.count, injured, share
    ))
    expect(injuredShareBand.contains(share), String(
        format: "season %d week %d: injured share %.4f is outside the band %.3f…%.3f",
        season, injurySampleWeek, share, injuredShareBand.lowerBound, injuredShareBand.upperBound
    ))
}

// MARK: - The discipline frequency band

// How often a player turns up in the weekly discipline file. Nothing could measure this before
// 2026-08-20, and no band would have caught it: `DisciplineSystem.incidents` had zero callers in
// `Sources/`, so the measured frequency was structurally zero no matter what the constants said.
// The suite's nine discipline tests all called the API directly, which is why nothing noticed.
//
// **Band 0.004…0.030 incidents per player-week, derived `[P]`.** `DisciplineSystem` draws once a
// week per rostered player who is not already serving, at `baseIncidentProbability` 0.004, plus
// `volatileIncidentProbability` 0.020 if the player has the trait, plus
// `unhappyIncidentProbability` 0.012 if morale is below `unhappyMorale`. Volatile is populated at
// `traitPopulationProbability` 0.08, so it contributes 0.08 * 0.020 = 0.0016 league-wide. The
// unhappy share is not derivable from a constant — morale is computed from playing time, team
// success and investment — so the band spans from nobody unhappy (0.004 + 0.0016 = 0.0056) to
// everyone unhappy (0.0176), and is widened to 0.030 above that for the interaction between the
// two, and down to 0.004 below, which is the floor the base rate alone cannot go under while the
// step runs at all. A measurement at exactly 0 means the step stopped running; at the ceiling it
// means the file has become the soap opera `PeopleRules` says it must not be.
//
// **What is counted is suspensions, not incidents, and the band accounts for it.** The only
// observable an incident leaves is `playerSuspended`, and `PeopleRules.recommendedSuspensionWeeks`
// gives `timekeeping` zero weeks — the AI handles that one internally and emits nothing. Kind is a
// uniform draw over the four `DisciplineIncidentKind` cases, so three in four incidents become a
// suspension and the observable rate is about 0.75 of the incident rate: 0.75 * 0.0056 = 0.0042 at
// the quiet end and 0.75 * 0.0176 = 0.0132 at the loud one. Hence 0.003…0.020 rather than the
// incident band, widened a little either side of both ends. Stating the incident band and asserting
// the suspension rate against it would be measuring one thing and bounding another.
//
// The rules module states the intent this band is really checking: "an incident every week is a
// soap opera, and one a season across a roster is a football team".

private let suspensionsPerPlayerWeekBand: ClosedRange<Double> = 0.003...0.020

func checkDisciplineFrequency(
    incidents: Int,
    playerWeeks: Int,
    season: Int
) {
    guard playerWeeks > 0 else {
        expect(false, "season \(season): no player-weeks to measure discipline frequency over")
        return
    }
    let rate = Double(incidents) / Double(playerWeeks)
    print(String(
        format: "discipline: season %d, suspensions %d over %d player-weeks, rate %.5f",
        season, incidents, playerWeeks, rate
    ))
    expect(suspensionsPerPlayerWeekBand.contains(rate), String(
        format: "season %d: suspension rate %.5f per player-week is outside the band %.3f…%.3f",
        season, rate,
        suspensionsPerPlayerWeekBand.lowerBound, suspensionsPerPlayerWeekBand.upperBound
    ))
}

// MARK: - The rating spread band

// How far apart players are, within a tier and between the two. The soak asserted mean college
// overall in 45…85 and mean pro overall in 55…90 — intervals 40 and 35 points wide on a 40…99
// scale, which is to say they assert the rating type's own range and nothing about the population.
// Neither says anything at all about *spread*, so a league that converged on one identical rating
// would satisfy both. That is the grey-mush failure, and nothing could see it.
//
// **Within-tier standard deviation. College 3…10, pro 2.5…8. Derived `[P]`.**
// `RosterPopulationGenerator.baseRating` sets a roster's centre from prestige — pro
// `60 + span * 15/59`, college `50 + span * 25/59` — and each rated attribute is that base plus a
// uniform `-10…10`, with `Player.overall` averaging the rated attributes. The uniform has sd 6.06,
// so averaging k of them contributes 6.06/sqrt(k), about 2.7 at five rated attributes. Pro prestige
// is uniform 48…92 (`LeagueGenerator`), giving bases 62…73, an sd of 11/sqrt(12) = 3.18, and a total
// near sqrt(3.18^2 + 2.7^2) = 4.2. The college limb is wider on purpose: its prestige comes from
// per-archetype floors and ceilings rather than one uniform draw, so the between-programme term is
// not derivable the same way and the band states that honestly rather than pretending to a
// precision it does not have.
//
// **Tier gap, pro mean overall minus college mean overall: 1…12. Derived `[P]`** from the same two
// expressions, whose midpoints differ by roughly 5 to 6 at generation. The floor is what matters:
// at or below zero the professional tier is not the better one, and the promotion arc that `02`
// sells as the spine of the game is measuring nothing.
//
// Asserted across a long run because the failure mode is drift, not generation. Development is
// bounded at +/-1 an attribute a checkpoint, which is exactly the shape that can quietly homogenise
// a league over ten seasons while every individual step stays legal.

private let collegeOverallSDBand: ClosedRange<Double> = 3.0...10.0
private let proOverallSDBand: ClosedRange<Double> = 2.5...8.0
private let tierGapBand: ClosedRange<Double> = 1.0...12.0

/// `assertTierGap` follows the same rule as `checkChurn`'s professional limb: measured and printed
/// everywhere, asserted in the soaks lane. The gap limb is red because college talent decays to the
/// recruiting pipeline's scale, which is a generation-constant question for the owner and not a
/// band to be widened. The two standard-deviation limbs assert everywhere, because they hold.
func checkRatingSpread(_ state: GameState, season: Int, assertTierGap: Bool) {
    func overalls(_ ids: [UUID]) -> [Double] {
        ids.compactMap { state.players[$0].map { Double($0.overall.value) } }
    }
    func moments(_ values: [Double]) -> (mean: Double, sd: Double) {
        guard !values.isEmpty else { return (.nan, .nan) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        return (mean, variance.squareRoot())
    }
    let college = moments(overalls(state.programmes.values.flatMap(\.rosterIDs)))
    let pro = moments(overalls(state.proTeams.values.flatMap(\.rosterIDs)))
    guard !college.mean.isNaN, !pro.mean.isNaN else {
        expect(false, "season \(season): a tier had no rated players to measure spread over")
        return
    }
    print(String(
        format: "rating spread: season %d, college mean %.2f sd %.2f, pro mean %.2f sd %.2f, gap %.2f",
        season, college.mean, college.sd, pro.mean, pro.sd, pro.mean - college.mean
    ))
    expect(collegeOverallSDBand.contains(college.sd), String(
        format: "season %d: college overall sd %.2f is outside the band %.1f…%.1f",
        season, college.sd, collegeOverallSDBand.lowerBound, collegeOverallSDBand.upperBound
    ))
    expect(proOverallSDBand.contains(pro.sd), String(
        format: "season %d: pro overall sd %.2f is outside the band %.1f…%.1f",
        season, pro.sd, proOverallSDBand.lowerBound, proOverallSDBand.upperBound
    ))
    guard assertTierGap else { return }
    expect(tierGapBand.contains(pro.mean - college.mean), String(
        format: "season %d: tier gap %.2f is outside the band %.1f…%.1f "
            + "(college %.2f, pro %.2f)",
        season, pro.mean - college.mean,
        tierGapBand.lowerBound, tierGapBand.upperBound, college.mean, pro.mean
    ))
}

// MARK: - The churn band

// What share of an organisation's roster is gone a season later. Nothing measured it: the soak
// asserted only that `departedPlayers` is non-empty, which one graduating walk-on satisfies for a
// world that has otherwise frozen solid.
//
// **College, 0.18…0.45, derived `[P]`.** `CollegeRules.seasonsOfCompetition` is 4 and
// `rosterLimit` is a constant 105, so a steady state in which every player exhausts eligibility
// turns over 105/4 = 26.25 players a season — a churn of exactly 0.25 from graduation alone.
// `eligibilityClockYears` is 5, one longer than the seasons it holds, so a redshirt occupies a
// roster place for five years while spending four: universal redshirting would stretch mean
// occupancy to 5 and drop churn to 0.20. The floor sits below that at 0.18. Portal departures
// (`02` §4.1, two windows a season) only add, so the ceiling is loose at 0.45 — past which a
// programme is not turning over but being rebuilt wholesale.
//
// **Professional, 0.10…0.50.** Canon is more specific than this band: `02` §4.2a fixes bootstrap
// terms so that "roughly a fifth of each roster reaches expiry each season", about eleven players a
// roster, which is 0.20 before retirement is counted at all. The band stays at 0.10 rather than
// being tightened to canon, because expiry is not churn — a club that re-signs everyone it lets
// expire moves nobody — and 0.10 is the floor below which the market has stopped regardless. The
// measured value fails even that: `--pro-soak` counts 149 expiries a season against the roughly 339
// canon calls for, so the model contradicts `02` §4.2a directly and not merely a derived band.
//
// The rest of this limb is derived `[P]` and deliberately weak.
// `ProRules.contractYearsRange` is 1…7, so a roughly flat spread of contract lengths means a mean
// near 4 and an expiry-driven churn near 0.25, with cuts adding and re-signing subtracting. The
// second of those is not derivable from a constant — a team that re-signs everyone it lets expire
// shows near-zero churn without anything being wrong — so this limb is stated wide and catches only
// the two failures that matter: a roster nothing leaves, and a roster replaced outright.

private let collegeChurnBand: ClosedRange<Double> = 0.18...0.45
private let proChurnBand: ClosedRange<Double> = 0.10...0.50

typealias RosterSnapshot = (
    college: [UUID: Set<UUID>],
    pro: [UUID: Set<UUID>],
    pool: Set<UUID>
)

func rosterSnapshot(_ state: GameState) -> RosterSnapshot {
    (
        college: state.programmes.values.reduce(into: [:]) { $0[$1.id] = Set($1.rosterIDs) },
        pro: state.proTeams.values.reduce(into: [:]) { $0[$1.id] = Set($1.rosterIDs) },
        // The free-agent pool spans the season boundary: contracts expire in the final week of a
        // season and free agency signs out of the pool during the *next* one. A snapshot that reads
        // rosters alone therefore cannot see a relocation at all — the player is on nobody's roster
        // at the boundary between leaving and arriving, so an A-to-B move reads as a departure here
        // and an unrelated arrival a season later. Carrying the pool is what makes the three-way
        // split below truthful.
        pool: Set(state.proMarket.freeAgentIDs)
    )
}

/// `assertPro` is false in the default lane and true in the soaks lane, which is where this repo
/// already keeps this exact failure. The professional limb is red for the reason `a2e3147` and
/// `4a95ca5` record — "the professional roster never turns over", blocked on an owner-level design
/// call — and `--pro-soak` has carried that red, outside the default run, since `e710924` added it
/// "red for a real reason". Asserting it here too would turn the default lane red for a cause
/// already tracked elsewhere; not measuring it at all would lose the finding. So it is measured and
/// printed everywhere, and asserted where its sibling failure lives. The band itself is NOT widened
/// to accommodate the break: 0.10 stays 0.10.
func checkChurn(
    from previous: RosterSnapshot,
    to current: RosterSnapshot,
    season: Int,
    assertPro: Bool
) {
    /// Departures as a share of the roster they left, pooled across organisations. Pooled rather
    /// than averaged per organisation so one team with a freak roster cannot swing the figure.
    func churn(_ before: [UUID: Set<UUID>], _ after: [UUID: Set<UUID>], pool: Set<UUID>)
        -> (share: Double, total: Int, moved: Int, pooled: Int, left: Int) {
        // Where everybody ended up, three ways. `pooled` exists because the second bucket is not
        // "gone": a professional between contracts is mid-relocation, and counting them as departed
        // is what made an earlier version of this read `moved == 0` and conclude the market had
        // stopped trading. It had not. `--pro-movement-probe` watches every week instead of every
        // boundary and counts 280 relocations in one season against ten returns.
        var organisationByPlayer: [UUID: UUID] = [:]
        for (organisationID, roster) in after {
            for playerID in roster { organisationByPlayer[playerID] = organisationID }
        }
        var moved = 0
        var pooled = 0
        var left = 0
        var total = 0
        for (organisationID, roster) in before {
            guard after[organisationID] != nil else { continue }
            total += roster.count
            for playerID in roster.subtracting(after[organisationID] ?? []) {
                if organisationByPlayer[playerID] != nil { moved += 1 }
                else if pool.contains(playerID) { pooled += 1 }
                else { left += 1 }
            }
        }
        let share = total > 0 ? Double(moved + pooled + left) / Double(total) : .nan
        return (share, total, moved, pooled, left)
    }
    for (label, band, measure) in [
        ("college", collegeChurnBand, churn(previous.college, current.college, pool: [])),
        ("pro", proChurnBand, churn(previous.pro, current.pro, pool: current.pool)),
    ] {
        let (share, total, moved, pooled, left) = measure
        guard total > 0 else {
            expect(false, "season \(season): no \(label) roster to measure churn over")
            continue
        }
        print(String(
            format: "churn: season %d %@, n %d, share %.3f (moved %d, pooled %d, left %d)",
            season, label, total, share, moved, pooled, left
        ))
        guard label == "college" || assertPro else { continue }
        expect(band.contains(share), String(
            format: "season %d: %@ churn %.3f is outside the band %.2f…%.2f "
                + "(moved %d, pooled %d, left %d)",
            season, label, share, band.lowerBound, band.upperBound, moved, pooled, left
        ))
    }
}

// MARK: - Ironman has an effect, not just a spelling

// `02` §11.3.3: "§5 requires every trait to have mechanical bite in a specific system", and Ironman
// names Injury. It had none — `PeopleRules.injuryWeeks` implemented the trait and nothing in
// `Sources/` called it, while the suite asserted the trait's *storage* (canonical order, dedupe,
// round-trip) and never its *effect*. That is the coverage boundary `CLAUDE.md` names becoming the
// quality boundary: a generated Ironman was a label.
//
// Enumerated by construction over every injury the run emitted rather than over a hand-picked case,
// so an injury the model learns to produce tomorrow is covered the day it appears. Both arms are
// asserted non-empty, because a check over an empty set is a check that cannot fail.

/// Every injury the long run produced, checked against the ladder its trait state implies.
func checkIronmanShortensInjuries(_ injuries: [(ironman: Bool, severity: InjurySeverity, weeks: Int)]) {
    func fullRange(_ severity: InjurySeverity) -> ClosedRange<Int> {
        switch severity {
        case .minor: return PeopleRules.minorInjuryWeeks
        case .moderate: return PeopleRules.moderateInjuryWeeks
        case .severe: return PeopleRules.severeInjuryWeeks
        }
    }
    let ironmanInjuries = injuries.filter(\.ironman)
    let ordinaryInjuries = injuries.filter { !$0.ironman }
    expect(!ordinaryInjuries.isEmpty, "the run produced no injury to an ordinary player")
    expect(!ironmanInjuries.isEmpty,
           "the run produced no injury to an ironman, so the trait's effect went unmeasured")
    print("ironman: \(ironmanInjuries.count) of \(injuries.count) injuries went to an ironman")

    for injury in ordinaryInjuries {
        expect(fullRange(injury.severity).contains(injury.weeks),
               "an ordinary \(injury.severity) injury lasted \(injury.weeks) weeks, "
                   + "outside \(fullRange(injury.severity))")
    }
    for injury in ironmanInjuries {
        let expected = Set(fullRange(injury.severity).map {
            PeopleRules.injuryWeeks($0, ironman: true)
        })
        expect(expected.contains(injury.weeks),
               "an ironman \(injury.severity) injury lasted \(injury.weeks) weeks, which no "
                   + "draw from \(fullRange(injury.severity)) shortens to — the trait is not applied")
        expect(injury.weeks <= fullRange(injury.severity).upperBound,
               "an ironman injury outlasted the unshortened ladder")
    }
}

/// The M2 soak's roster and age invariants, at one season instead of twenty.
///
/// These invariants were wrong for nine days and nobody noticed, because `--m2-soak` is a
/// release-only lane that takes twenty minutes and nothing else asserted them. That is the part
/// worth fixing structurally: the same checks cost 22 weeks here and ride in the default suite, so
/// a regression of either shape fails in seconds rather than waiting for someone to run the soak.
///
/// Deliberately mirrors what `runM2SoakTests` asserts rather than inventing a second opinion --
/// same one-week peek for the college fill, same bound for professional rosters, same derived age
/// range. If the two ever disagree, this one is the copy to delete.
func runRosterFillTests() {
    suite("Season-start roster fill") {
        test("the season-boundary roster and age invariants hold in one season") {
            var state = GameState.bootstrap(seed: 91_002)
            for _ in 0..<SharedRules.inSeasonWeeks {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar, CalendarState(season: 1, week: 1))

            // Week 1 guarantees only the per-position coverage floor: `.awaitingSpring` is a
            // deliberate one-week gap before `.springRosterFill` tops rosters back to the limit.
            for position in Position.allCases {
                let minimum = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
                expect(state.programmes.values.allSatisfy { programme in
                    programme.rosterIDs.filter {
                        state.players[$0]?.position == position
                    }.count >= minimum
                }, "a college programme is below the week-1 coverage minimum for \(position)")
            }

            // One week on, the college fill has run and the exact count holds.
            let filled = try WorldScheduler.advanceWeek(state).state
            let collegeIDs = filled.programmes.values.flatMap(\.rosterIDs)
            expectEqual(collegeIDs.count, CollegeRules.programmeCount * CollegeRules.rosterLimit)
            expectEqual(Set(collegeIDs).count, collegeIDs.count)

            // Professional rosters refill one signing per team per week, so they are bounded here,
            // never exact.
            expect(filled.proTeams.values.allSatisfy {
                $0.rosterIDs.count <= ProRules.activeRosterLimit
            }, "a professional roster exceeds \(ProRules.activeRosterLimit)")
            let proIDs = filled.proTeams.values.flatMap(\.rosterIDs)
            expectEqual(Set(proIDs).count, proIDs.count)

            // The age bound, at the same derivation the soak uses.
            let oldestObservableAge = CollegeRules.prospectAgeRange.upperBound
                + CollegeRules.eligibilityClockYears - 1
            let legalCollegeAges =
                CollegeRules.prospectAgeRange.lowerBound...oldestObservableAge
            expect(state.programmes.values.flatMap(\.rosterIDs).allSatisfy {
                legalCollegeAges.contains(state.players[$0]?.age ?? -1)
            }, "a college roster age falls outside \(legalCollegeAges)")

            // The case that actually broke: real recruiting signs 17-year-olds, under the old
            // `18...21` floor. Named directly so a regression says so.
            let ages = state.programmes.values.flatMap(\.rosterIDs).compactMap {
                state.players[$0]?.age
            }
            expect(ages.contains(CollegeRules.prospectAgeRange.lowerBound),
                   "no signed freshman reached a college roster at the recruiting floor of "
                       + "\(CollegeRules.prospectAgeRange.lowerBound); this fixture no longer "
                       + "exercises the case it exists for")
        }
    }
}

func runM2SoakTests(seasons: Int) {
    suite("M2 people lifecycle soak") {
        test("target populations remain legal, staffed, bounded, and persistent") {
            let clock = ContinuousClock()
            let started = clock.now
            var state = GameState.bootstrap(seed: 91_002)
            let activePlayerTarget = CollegeRules.programmeCount * CollegeRules.rosterLimit
                + ProRules.teamCount * ProRules.activeRosterLimit
            let employedStaffTarget = (CollegeRules.programmeCount + ProRules.teamCount)
                * PeopleRules.staffPerOrganisation
            var saveSizes: [Int: Int] = [:]
            var previousRosters = rosterSnapshot(state)
            // Holds a peek one week beyond each season boundary: CollegeCycleSystem
            // .addWalkOns(for: .springRosterFill, ...) only tops college rosters back up
            // to CollegeRules.rosterLimit during the week1->week2 advance, once
            // CollegePortalPhase.awaitingSpring resolves. Used for the full-college-roster
            // assertions below, both per-season and after the loop. Professional rosters
            // have no equivalent same-week fill (see the note further down), so this peek
            // does not make them exact too.
            var filledState = state

            for season in 1...seasons {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    state = try WorldScheduler.advanceWeek(state).state
                }
                expectEqual(state.calendar, CalendarState(season: season, week: 1))

                // `.awaitingSpring` is a deliberate one-week gap (its own
                // CollegePortalPhase.isStableBoundary state): it lets the coach's spring
                // mandatory decisions land before the engine auto-fills the rest of the
                // roster. So at week 1 itself, college rosters are only guaranteed to
                // satisfy SharedRules.minimumPlayableRosterByPosition per position (the
                // .postseasonCoverage fill), not CollegeRules.rosterLimit. Assert that
                // real guarantee here.
                for position in Position.allCases {
                    let minimum = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
                    expect(state.programmes.values.allSatisfy { programme in
                        programme.rosterIDs.filter {
                            state.players[$0]?.position == position
                        }.count >= minimum
                    }, "a college programme is below the week-1 coverage minimum for \(position)")
                }

                // CollegeCycleSystem.addWalkOns(for: .springRosterFill, ...) runs in the
                // marketInteractions step of the week1->week2 advance, so peek one week
                // ahead (without consuming the loop's own `state`) to assert the
                // full-college-roster invariant at the point where it actually holds.
                filledState = try WorldScheduler.advanceWeek(state).state
                let filledCollegeRosterIDs = filledState.programmes.values.flatMap(\.rosterIDs)
                expectEqual(
                    filledCollegeRosterIDs.count,
                    CollegeRules.programmeCount * CollegeRules.rosterLimit
                )
                expectEqual(Set(filledCollegeRosterIDs).count, filledCollegeRosterIDs.count)

                // Professional rosters do not get a college-style bulk fill: `02` section 4.2a
                // has roughly a fifth of each 53-man roster (about 11 players) reach expiry at
                // once at the season boundary, then refilled by ProRosterAISystem's one
                // free-agent signing per team per week, plus the draft once free agency runs
                // dry. A team can stay under 53 for several weeks by design — ProSoakTests
                // asserts the same bound this design allows, never over the limit, never an
                // exact target.
                expect(filledState.proTeams.values.allSatisfy {
                    $0.rosterIDs.count <= ProRules.activeRosterLimit
                })
                let filledProRosterIDs = filledState.proTeams.values.flatMap(\.rosterIDs)
                expectEqual(Set(filledProRosterIDs).count, filledProRosterIDs.count)

                let activePlayerIDs = state.programmes.values.flatMap(\.rosterIDs)
                    + state.proTeams.values.flatMap(\.rosterIDs)
                expect(activePlayerIDs.allSatisfy {
                    state.people.playerLifecycle[$0]?.status == .active
                })
                expect(state.programmes.values.flatMap(\.rosterIDs).allSatisfy {
                    state.players[$0]?.eligibility?.isExhausted == false
                })
                // Derived from the rules, not from what one generator currently draws.
                // `ProspectPopulationGenerator` happens to draw 17-19 today, but that is not the
                // engine's ceiling: `Prospect.init` *clamps* to `CollegeRules.prospectAgeRange`
                // (17...21) and `WorldIntegrity` enforces the same range on the root, so a
                // 21-year-old prospect is legal state that any other intake path may produce. Such
                // a signee who spends their one spare redshirt year is rostered at 25, which a
                // hard-coded 23 would report as a defect.
                //
                // `Eligibility` decrements `yearsRemaining` every enrolled year but
                // `seasonsRemaining` only on a season actually played, and nothing graduates on age
                // alone -- only `Eligibility.isExhausted`. So the oldest observable age is the
                // oldest legal entry age plus one fewer than the full clock, the final enrolled
                // year being the one that exhausts and removes them in the same step.
                let oldestObservableAge = CollegeRules.prospectAgeRange.upperBound
                    + CollegeRules.eligibilityClockYears - 1
                let legalCollegeAges =
                    CollegeRules.prospectAgeRange.lowerBound...oldestObservableAge
                expect(state.programmes.values.flatMap(\.rosterIDs).allSatisfy {
                    legalCollegeAges.contains(state.players[$0]?.age ?? -1)
                })
                expect(state.proTeams.values.flatMap(\.rosterIDs).allSatisfy { id in
                    guard let player = state.players[id] else { return false }
                    return player.age >= 22
                        && player.age < player.position.declineAge
                            + PeopleRules.guaranteedRetirementYearsAfterDecline
                })

                let employedStaffIDs = state.programmes.values.flatMap(\.staffIDs)
                    + state.proTeams.values.flatMap(\.staffIDs)
                expectEqual(employedStaffIDs.count, employedStaffTarget)
                expectEqual(Set(employedStaffIDs).count, employedStaffTarget)
                expect(state.people.playerCareers.values.allSatisfy {
                    $0.seasons.count <= PeopleRules.careerSeasonHistoryLimit
                })
                let activeLifecycle = activePlayerIDs.compactMap {
                    state.people.playerLifecycle[$0]
                }
                let injuredCount = activeLifecycle.filter { $0.injury != nil }.count
                expect(injuredCount > 0, "injury simulation became unreachable")
                expect(injuredCount < activePlayerTarget / 10,
                       "more than ten percent of active players are injured")
                expect(activeLifecycle.contains { $0.lastDevelopment != nil },
                       "development checkpoints produced no retained explanation")
                let collegeOverall = state.programmes.values.flatMap(\.rosterIDs).compactMap {
                    state.players[$0]?.overall.value
                }
                let proOverall = state.proTeams.values.flatMap(\.rosterIDs).compactMap {
                    state.players[$0]?.overall.value
                }
                expect((45...85).contains(collegeOverall.reduce(0, +) / collegeOverall.count))
                expect((55...90).contains(proOverall.reduce(0, +) / proOverall.count))
                checkProAgeCurve(state, season: season)
                checkRatingSpread(state, season: season, assertTierGap: true)
                let currentRosters = rosterSnapshot(state)
                checkChurn(from: previousRosters, to: currentRosters, season: season,
                           assertPro: true)
                previousRosters = currentRosters
                let report = WorldIntegrity.check(state)
                expect(report.isValid, report.issues.map(\.description).joined(separator: ", "))

                if [1, 5, seasons].contains(season) {
                    let encoded = try SaveEnvelope.encode(state)
                    saveSizes[season] = encoded.count
                    expectEqual(try SaveEnvelope.decode(GameState.self, from: encoded), state)
                }
            }

            // A professional whose contract expires (ProMarketSystem.expireContracts) is never
            // removed from the player store, only unrostered into proMarket.freeAgentIDs — the
            // store holds the league's whole identity pool, not just who is rostered this week.
            // Retirement replacements preserve headcount and filledState has full college rosters,
            // so the bootstrap target is a lower bound rather than an exact store size.
            expect(filledState.players.count >= activePlayerTarget,
                   "player store fell below the retained-population floor: "
                       + "\(filledState.players.count) < \(activePlayerTarget)")
            expect(!state.people.departedPlayers.isEmpty,
                   "departed player identities did not persist")
            expect(state.staff.count >= employedStaffTarget,
                   "staff identities disappeared across turnover")
            expect(state.people.departedPlayers.count <= PeopleRules.departedPlayerRetentionLimit,
                   "departed identities are unbounded again: "
                       + "\(state.people.departedPlayers.count) retained")
            expectEqual(
                Set(state.people.playerCareers.keys),
                Set(state.players.ids).union(state.people.departedPlayers.keys),
                "career records and player identities came apart, so pruning dropped one half of a pair"
            )
            assertSaveSizeIsBounded(saveSizes, seasons: seasons, label: "M2")
            let elapsed = started.duration(to: clock.now)
            print("M2 soak: \(seasons) seasons in \(elapsed); save checkpoints \(saveSizes)")
        }
    }
}


/// The save-size gate both soaks share.
///
/// It was a `print` in each of them while `PRODUCT.md` listed the size commitment as verified, which
/// is the defect `docs/06-AUDIT-DISPOSITION.md` calls pattern 3: a named test that asserts nothing
/// about the thing it is named for.
func assertSaveSizeIsBounded(_ checkpoints: [Int: Int], seasons: Int, label: String) {
    for season in checkpoints.keys.sorted() {
        guard let bytes = checkpoints[season] else { continue }
        expect(bytes <= SaveEnvelope.productionSaveByteCeiling,
               "\(label) season \(season) save is \(bytes) bytes, over the "
                   + "\(SaveEnvelope.productionSaveByteCeiling) byte ceiling")
    }
    guard seasons > 5, let early = checkpoints[5], let late = checkpoints[seasons], early > 0 else {
        return
    }
    expect(Double(late) <= Double(early) * SaveEnvelope.productionSaveDriftRatio,
           "\(label) save drifted from \(early) bytes at season 5 to \(late) at season "
               + "\(seasons), beyond the \(SaveEnvelope.productionSaveDriftRatio)x allowance")
}
