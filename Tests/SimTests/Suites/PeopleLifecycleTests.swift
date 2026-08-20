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
            checkProAgeCurve(state, season: 0)
            for season in 1...(measured.max() ?? 1) {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    let transition = try WorldScheduler.advanceWeek(state)
                    state = transition.state
                    for event in transition.emittedEvents {
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
                guard measured.contains(season) else { continue }
                checkProAgeCurve(state, season: season)
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
    expect(proPastDeclineShareBand.contains(pastDeclineShare), String(
        format: "season %d: %.3f of professionals are at or past their decline age, "
            + "outside the band %.2f…%.2f",
        season, pastDeclineShare,
        proPastDeclineShareBand.lowerBound, proPastDeclineShareBand.upperBound
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
// **Professional, 0.10…0.50, derived `[P]` and deliberately the weaker limb.**
// `ProRules.contractYearsRange` is 1…7, so a roughly flat spread of contract lengths means a mean
// near 4 and an expiry-driven churn near 0.25, with cuts adding and re-signing subtracting. The
// second of those is not derivable from a constant — a team that re-signs everyone it lets expire
// shows near-zero churn without anything being wrong — so this limb is stated wide and catches only
// the two failures that matter: a roster nothing leaves, and a roster replaced outright.

private let collegeChurnBand: ClosedRange<Double> = 0.18...0.45
private let proChurnBand: ClosedRange<Double> = 0.10...0.50

typealias RosterSnapshot = (college: [UUID: Set<UUID>], pro: [UUID: Set<UUID>])

func rosterSnapshot(_ state: GameState) -> RosterSnapshot {
    (
        college: state.programmes.values.reduce(into: [:]) { $0[$1.id] = Set($1.rosterIDs) },
        pro: state.proTeams.values.reduce(into: [:]) { $0[$1.id] = Set($1.rosterIDs) }
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
    func churn(_ before: [UUID: Set<UUID>], _ after: [UUID: Set<UUID>])
        -> (share: Double, total: Int, moved: Int, left: Int) {
        // Where everybody ended up, so a departure can be told apart from a transfer. Churn that is
        // all `left` and no `moved` is a league whose market has stopped trading, which reads
        // identically to a healthy one if you only count departures.
        var organisationByPlayer: [UUID: UUID] = [:]
        for (organisationID, roster) in after {
            for playerID in roster { organisationByPlayer[playerID] = organisationID }
        }
        var moved = 0
        var left = 0
        var total = 0
        for (organisationID, roster) in before {
            guard after[organisationID] != nil else { continue }
            total += roster.count
            for playerID in roster.subtracting(after[organisationID] ?? []) {
                if organisationByPlayer[playerID] == nil { left += 1 } else { moved += 1 }
            }
        }
        let share = total > 0 ? Double(moved + left) / Double(total) : .nan
        return (share, total, moved, left)
    }
    for (label, band, measure) in [
        ("college", collegeChurnBand, churn(previous.college, current.college)),
        ("pro", proChurnBand, churn(previous.pro, current.pro)),
    ] {
        let (share, total, moved, left) = measure
        guard total > 0 else {
            expect(false, "season \(season): no \(label) roster to measure churn over")
            continue
        }
        print(String(
            format: "churn: season %d %@, n %d, share %.3f (moved %d, left %d)",
            season, label, total, share, moved, left
        ))
        guard label == "college" || assertPro else { continue }
        expect(band.contains(share), String(
            format: "season %d: %@ churn %.3f is outside the band %.2f…%.2f "
                + "(moved %d, left %d)",
            season, label, share, band.lowerBound, band.upperBound, moved, left
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

            for season in 1...seasons {
                for _ in 0..<SharedRules.inSeasonWeeks {
                    state = try WorldScheduler.advanceWeek(state).state
                }
                expectEqual(state.calendar, CalendarState(season: season, week: 1))
                let activePlayerIDs = state.programmes.values.flatMap(\.rosterIDs)
                    + state.proTeams.values.flatMap(\.rosterIDs)
                expectEqual(activePlayerIDs.count, activePlayerTarget)
                expectEqual(Set(activePlayerIDs).count, activePlayerTarget)
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
                checkProAgeCurve(state, season: season)
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
