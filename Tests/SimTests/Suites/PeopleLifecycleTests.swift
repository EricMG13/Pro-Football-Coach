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
            // store holds the league's whole identity pool, not just who is rostered this week,
            // so activePlayerTarget is still the right size for it even though a professional
            // roster itself is only bounded, not exact, at this checkpoint (see the note above).
            expectEqual(filledState.players.count, activePlayerTarget)
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
