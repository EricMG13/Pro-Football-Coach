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
        test("the injured share and professional age curve hold their bands across a long run") {
            var state = GameState.bootstrap(seed: 84_010)
            let measured = [1, 3, 6, 10]
            checkProAgeCurve(state, season: 0)
            for season in 1...(measured.max() ?? 1) {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    state = try WorldScheduler.advanceWeek(state).state
                    if measured.contains(season), state.calendar.week == injurySampleWeek {
                        checkInjuredShare(state, season: season)
                    }
                }
                if measured.contains(season) {
                    checkProAgeCurve(state, season: season)
                }
            }
        }
    }
}

// **Mean age 25.0...27.5 and share at/past decline 0.08...0.30, derived [P] from the model.**
// Professional intake starts at 22. `SeasonLifecycleSystem.retires` applies an escalating 0.14,
// 0.28, ... annual hazard after each position's stated decline age, with a hard stop after eight
// years. At the playable-roster-weighted decline age near 30.4, the survival ladder contributes
// about 3.04 post-decline seasons against 8.4 pre-decline seasons: a 0.27 veteran-tail ceiling and
// mean near 27.3. The bands leave room for expiry and roster construction while rejecting a league
// with no veteran tail or one dominated by declining players.

private let proMeanAgeBand: ClosedRange<Double> = 25.0...27.5
private let proPastDeclineShareBand: ClosedRange<Double> = 0.08...0.30

private func checkProAgeCurve(_ state: GameState, season: Int) {
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
        format: "season %d: professional mean age %.2f is outside the band %.1f...%.1f",
        season, mean, proMeanAgeBand.lowerBound, proMeanAgeBand.upperBound
    ))
    expect(proPastDeclineShareBand.contains(pastDeclineShare), String(
        format: "season %d: past-decline share %.3f is outside the band %.2f...%.2f",
        season, pastDeclineShare,
        proPastDeclineShareBand.lowerBound, proPastDeclineShareBand.upperBound
    ))
}

// What share of active players is carrying an injury in a given week. The prior soak asserted only
// `> 0` and `< 10%`, which detects reachability but does not describe the distribution.
//
// **Band 0.015...0.055, derived [P] from the model's stated rules.**
// `PeopleRules.injuryProbability` gives the week-12 playing population a roughly 0.008...0.014
// weekly risk. `PeopleRules.injurySeverity` gives mean absence of
// `0.72 * 1.5 + 0.23 * 4.5 + 0.05 * 10.5 = 2.64` weeks. Probability times duration therefore
// predicts a steady injured share near 0.021...0.037; the wider band allows fatigue dispersion,
// byes, and the shrinking postseason field without weakening the existing 10% safety ceiling.

private let injurySampleWeek = 12
private let injuredShareBand: ClosedRange<Double> = 0.015...0.055

private func checkInjuredShare(_ state: GameState, season: Int) {
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
        format: "season %d week %d: injured share %.4f is outside the band %.3f...%.3f",
        season, injurySampleWeek, share, injuredShareBand.lowerBound, injuredShareBand.upperBound
    ))
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

            for season in 1...seasons {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    state = try WorldScheduler.advanceWeek(state).state
                }
                expectEqual(state.calendar, CalendarState(season: season, week: 1))
                let activePlayerIDs = state.programmes.values.flatMap(\.rosterIDs)
                    + state.proTeams.values.flatMap(\.rosterIDs)
                expectEqual(activePlayerIDs.count, activePlayerTarget)
                expectEqual(Set(activePlayerIDs).count, activePlayerTarget)
                expect(state.programmes.values.allSatisfy { $0.rosterLegality.isLegal })
                expect(state.proTeams.values.allSatisfy { $0.rosterLegality.isLegal })
                expect(activePlayerIDs.allSatisfy {
                    state.people.playerLifecycle[$0]?.status == .active
                })
                expect(state.programmes.values.flatMap(\.rosterIDs).allSatisfy {
                    state.players[$0]?.eligibility?.isExhausted == false
                })
                expect(state.programmes.values.flatMap(\.rosterIDs).allSatisfy {
                    (18...21).contains(state.players[$0]?.age ?? -1)
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
                let report = WorldIntegrity.check(state)
                expect(report.isValid, report.issues.map(\.description).joined(separator: ", "))

                if [1, 5, seasons].contains(season) {
                    let encoded = try SaveEnvelope.encode(state)
                    saveSizes[season] = encoded.count
                    expectEqual(try SaveEnvelope.decode(GameState.self, from: encoded), state)
                }
            }

            expectEqual(state.players.count, activePlayerTarget)
            expect(!state.people.departedPlayers.isEmpty,
                   "departed player identities did not persist")
            expect(state.staff.count >= employedStaffTarget,
                   "staff identities disappeared across turnover")
            let elapsed = started.duration(to: clock.now)
            print("M2 soak: \(seasons) seasons in \(elapsed); save checkpoints \(saveSizes)")
        }
    }
}
