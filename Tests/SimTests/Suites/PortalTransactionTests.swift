import Foundation
import FootballSimCore

private struct PortalTransactionFixture {
    let capturedState: GameState
    let result: CollegePortalMatchingResult
    let retainedSourceID: UUID
    let releasedSourceID: UUID
    let destinationID: UUID
    let entrantIDs: [UUID]
}

private struct ProjectedPortalTransition {
    let state: GameState
    let records: [CollegePortalWindowRecord]
}

private func portalTransactionFixture() -> PortalTransactionFixture {
    var rolled = GameState.bootstrap(seed: 97_001)
    while rolled.calendar.season == 0 {
        rolled = try! WorldScheduler.advanceWeek(rolled).state
    }
    precondition(rolled.calendar == CalendarState(season: 1, week: 1))
    precondition(WorldIntegrity.check(rolled).isValid)

    // The live scheduler intentionally leaves spring rosters partially open. This isolated
    // transaction fixture needs exactly one destination opening so it can exercise retained,
    // returned, and transferred outcomes in the same deterministic batch.
    let fullRosters = CollegeCycleSystem.addWalkOns(
        for: .springRosterFill,
        season: 1,
        in: rolled
    )
    rolled.programmes = fullRosters.programmes
    rolled.players = fullRosters.players
    rolled.people = fullRosters.people

    let rankedProgrammes = rolled.programmes.values.sorted { lhs, rhs in
        lhs.resources.value == rhs.resources.value
            ? lhs.id.uuidString < rhs.id.uuidString
            : lhs.resources.value > rhs.resources.value
    }
    let retainedSourceID = rankedProgrammes[0].id
    let releasedSourceID = rankedProgrammes[1].id
    let destinationID = rankedProgrammes[2].id
    let retainedPlayerID = rolled.programmes[retainedSourceID]!.rosterIDs.first {
        rolled.players[$0]?.position == .quarterback
    }!
    let releasedPlayerIDs = Array(rolled.programmes[releasedSourceID]!.rosterIDs.filter {
        rolled.players[$0]?.position == .quarterback
    }.prefix(2))
    precondition(releasedPlayerIDs.count == 2)
    let entrantIDs = [retainedPlayerID] + releasedPlayerIDs
    let entrantSet = Set(entrantIDs)

    for playerID in rolled.players.ids {
        _ = rolled.players.update(playerID) { player in
            player.remove(.restless)
            if entrantSet.contains(playerID) {
                player.add(.restless)
            }
        }
    }

    let ownerByPlayerID = Dictionary(uniqueKeysWithValues:
        rolled.programmes.values.flatMap { programme in
            programme.rosterIDs.map { ($0, programme.id) }
        }
    )
    rolled.people = PeopleState(
        playerLifecycle: Array(rolled.people.playerLifecycle.values),
        playerCareers: rolled.people.playerCareers.map { playerID, career in
            PlayerCareerRecord(
                playerID: playerID,
                recruitingOrigin: career.recruitingOrigin,
                seasons: career.seasons.map { season in
                    guard season.season == 0,
                          season.tier == .college,
                          let ownerID = ownerByPlayerID[playerID] else { return season }
                    return PlayerCareerSeason(
                        season: 0,
                        organisationID: ownerID,
                        tier: .college,
                        games: entrantSet.contains(playerID) ? 0 : 12,
                        starts: 0,
                        overallAtEnd: season.overallAtEnd
                    )
                },
                // This fixture deliberately reconstructs the pre-postseason authority root
                // after using the scheduler only to obtain a completed season and next schedule.
                portalWindows: [],
                endedAt: career.endedAt,
                endStatus: career.endStatus
            )
        },
        staffCareers: Array(rolled.people.staffCareers.values),
        departedPlayers: Array(rolled.people.departedPlayers.values)
    )

    let destination = rolled.programmes[destinationID]!
    var destinationPositionCounts: [Position: Int] = [:]
    for playerID in destination.rosterIDs {
        destinationPositionCounts[rolled.players[playerID]!.position, default: 0] += 1
    }
    let destinationScholarships = Set(
        rolled.college.programmes[destinationID]!.scholarshipPlayerIDs
    )
    let removedDestinationPlayerID = destination.rosterIDs.reversed().first { playerID in
        guard destinationScholarships.contains(playerID),
              let position = rolled.players[playerID]?.position else { return false }
        return (destinationPositionCounts[position] ?? 0)
            > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
    }!
    _ = rolled.programmes.update(destinationID) { programme in
        programme.rosterIDs.removeAll { $0 == removedDestinationPlayerID }
        programme.scholarshipCount -= 1
    }

    var programmeStates: [UUID: ProgrammeRecruitingState] = [:]
    for programme in rolled.programmes.values {
        let current = rolled.college.programmes[programme.id]!
        let scholarships = current.scholarshipPlayerIDs.filter {
            programme.rosterIDs.contains($0)
        }
        var rosterAllocations = current.nilState.rosterAllocations.filter {
            programme.rosterIDs.contains($0.key)
        }
        if programme.id == retainedSourceID {
            rosterAllocations.removeValue(forKey: retainedPlayerID)
        } else if programme.id == releasedSourceID {
            rosterAllocations = [:]
            let existingReservations = current.nilState.recruitingReservations.values.reduce(0, +)
            let amount = current.nilState.annualBudget - existingReservations
            let allocationID = programme.rosterIDs.first {
                !entrantSet.contains($0)
            }!
            if amount > 0 {
                rosterAllocations[allocationID] = amount
            }
        } else if programme.id == destinationID {
            rosterAllocations = [:]
        }
        programmeStates[programme.id] = ProgrammeRecruitingState(
            programmeID: programme.id,
            boardIDs: current.boardIDs,
            relationships: current.relationships,
            scholarshipPlayerIDs: scholarships,
            contactPointsRemaining: current.contactPointsRemaining,
            nilState: ProgrammeNILState(
                programmeID: programme.id,
                season: 1,
                annualBudget: current.nilState.annualBudget,
                rosterAllocations: rosterAllocations,
                recruitingReservations: current.nilState.recruitingReservations
            )
        )
    }
    rolled.history = DomainEventLedger()
    rolled.college = CollegeState(
        recruitingSeason: 1,
        portal: CollegePortalState(targetSeason: 1),
        phase: rolled.college.phase,
        programmes: programmeStates,
        prospectRecruitment: rolled.college.prospectRecruitment,
        archivedProspects: [:],
        redshirtPlans: rolled.college.redshirtPlans.filter {
            $0.key != removedDestinationPlayerID
        }
    )
    rolled.scouting = ScoutingState(
        observationsByObserver: rolled.scouting.observationsByObserver,
        pendingEvaluations: rolled.scouting.pendingEvaluations,
        portalKnowledgeByObserver: [:]
    )
    precondition(WorldIntegrity.check(rolled).isValid)

    var captured = rolled
    captured.calendar = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
    captured.league.season = 0
    captured.league.week = SharedRules.inSeasonWeeks
    let market = CollegePortalPolicyV1.makeMarketSnapshot(
        targetSeason: 1,
        window: .postseason,
        in: captured
    )!
    let result = CollegePortalPolicyV1.match(using: market)!
    precondition(result.entrants.count == 3)
    precondition(result.entrants.filter { $0.retention.outcome == .retained }.count == 1)
    precondition(result.entrants.filter { $0.acceptedDestinationProgrammeID != nil }.count == 1)

    return PortalTransactionFixture(
        capturedState: captured,
        result: result,
        retainedSourceID: retainedSourceID,
        releasedSourceID: releasedSourceID,
        destinationID: destinationID,
        entrantIDs: entrantIDs
    )
}

private func portalTwoWayResult(
    from fixture: PortalTransactionFixture
) -> (source: GameState, result: CollegePortalMatchingResult) {
    var state = fixture.capturedState
    let sourceAndDestinationID = fixture.releasedSourceID
    let releasedElsewhereID = fixture.retainedSourceID
    let existingDestinationID = fixture.destinationID
    let entrantSet = Set(fixture.entrantIDs)

    let sourceAndDestination = state.programmes[sourceAndDestinationID]!
    let scholarships = Set(
        state.college.programmes[sourceAndDestinationID]!.scholarshipPlayerIDs
    )
    let allocatedIDs = Set(
        state.college.programmes[sourceAndDestinationID]!.nilState.rosterAllocations.keys
    )
    var counts: [Position: Int] = [:]
    for playerID in sourceAndDestination.rosterIDs {
        counts[state.players[playerID]!.position, default: 0] += 1
    }
    let removedPlayerID = sourceAndDestination.rosterIDs.reversed().first { playerID in
        guard scholarships.contains(playerID),
              !entrantSet.contains(playerID),
              !allocatedIDs.contains(playerID),
              let position = state.players[playerID]?.position else { return false }
        return (counts[position] ?? 0)
            > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
    }!
    _ = state.programmes.update(sourceAndDestinationID) { programme in
        programme.rosterIDs.removeAll { $0 == removedPlayerID }
        programme.scholarshipCount -= 1
        programme.prestige = Rating(99)
    }
    _ = state.programmes.update(existingDestinationID) { programme in
        programme.prestige = Rating(40)
    }

    var recruiting = state.college.programmes
    for programmeID in [releasedElsewhereID, sourceAndDestinationID] {
        let current = recruiting[programmeID]!
        let programme = state.programmes[programmeID]!
        let scholarshipIDs = current.scholarshipPlayerIDs.filter {
            programme.rosterIDs.contains($0)
        }
        let existingRecruiting = current.nilState.recruitingReservations
        let availableForRoster = current.nilState.annualBudget
            - existingRecruiting.values.reduce(0, +)
        let allocationID = programme.rosterIDs.first {
            !entrantSet.contains($0)
                && existingRecruiting[$0] == nil
        }!
        recruiting[programmeID] = ProgrammeRecruitingState(
            programmeID: programmeID,
            boardIDs: current.boardIDs,
            relationships: current.relationships,
            scholarshipPlayerIDs: scholarshipIDs,
            contactPointsRemaining: current.contactPointsRemaining,
            nilState: ProgrammeNILState(
                programmeID: programmeID,
                season: 1,
                annualBudget: current.nilState.annualBudget,
                rosterAllocations: availableForRoster > 0
                    ? [allocationID: availableForRoster]
                    : [:],
                recruitingReservations: existingRecruiting
            )
        )
    }
    state.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: state.college.portal,
        phase: state.college.phase,
        programmes: recruiting,
        prospectRecruitment: state.college.prospectRecruitment,
        archivedProspects: state.college.archivedProspects,
        redshirtPlans: state.college.redshirtPlans.filter { $0.key != removedPlayerID }
    )

    var projected = state
    projected.calendar = CalendarState(season: 1, week: 1)
    projected.league.season = 1
    projected.league.week = 1
    precondition(WorldIntegrity.check(projected).isValid)
    let market = CollegePortalPolicyV1.makeMarketSnapshot(
        targetSeason: 1,
        window: .postseason,
        in: state
    )!
    let result = CollegePortalPolicyV1.match(using: market)!
    precondition(result.entrants.filter { $0.acceptedDestinationProgrammeID != nil }.count == 2)
    return (state, result)
}

private func projectedPostseasonTransition(
    _ fixture: PortalTransactionFixture
) -> ProjectedPortalTransition {
    let transition = CollegePortalPolicyV1.commit(fixture.result)!
    var projected = transition.state
    projected.calendar = CalendarState(season: 1, week: 1)
    projected.league.season = 1
    projected.league.week = 1
    return ProjectedPortalTransition(state: projected, records: transition.records)
}

private func portalSummary(
    targetSeason: Int,
    window: CollegePortalWindow,
    records: [CollegePortalWindowRecord]
) -> CollegePortalWindowSummary {
    let completedAt: CalendarState
    switch window {
    case .postseason:
        completedAt = CalendarState(
            season: targetSeason - 1,
            week: SharedRules.inSeasonWeeks
        )
    case .spring:
        completedAt = CalendarState(season: targetSeason, week: 1)
    }
    return CollegePortalWindowSummary(
        targetSeason: targetSeason,
        window: window,
        completedAt: completedAt,
        entrantCount: records.count,
        retainedCount: records.filter { $0.outcome == .retainedBySource }.count,
        transferredCount: records.filter {
            if case .transferred = $0.outcome { return true }
            return false
        }.count,
        returnedCount: records.filter { $0.outcome == .returnedToSource }.count,
        offerCount: records.reduce(0) { $0 + $1.offers.count }
    )
}

private func replacingPortal(_ portal: CollegePortalState, in state: GameState) -> GameState {
    var next = state
    next.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: portal,
        phase: state.college.phase,
        programmes: state.college.programmes,
        prospectRecruitment: state.college.prospectRecruitment,
        archivedProspects: state.college.archivedProspects,
        redshirtPlans: state.college.redshirtPlans
    )
    return next
}

func runPortalTransactionTests() {
    let fixture = portalTransactionFixture()

    suite("College portal atomic transaction") {
        test("one atomic commit records retained returned and transferred outcomes in event order") {
            let transition = CollegePortalPolicyV1.commit(fixture.result)!
            expect(!((transition as Any) is any Encodable))
            expectEqual(transition.records.map(\.playerID), transition.records.map(\.playerID).sorted {
                $0.uuidString < $1.uuidString
            })
            expectEqual(transition.records.count, 3)
            expectEqual(transition.summary.entrantCount, 3)
            expectEqual(transition.summary.retainedCount, 1)
            expectEqual(transition.summary.transferredCount, 1)
            expectEqual(transition.summary.returnedCount, 1)
            expectEqual(transition.state.college.portal.phase, .awaitingSpring)
            expectEqual(transition.state.college.portal.entries.count, 3)
            expectEqual(transition.state.college.portal.summaries, [transition.summary])

            let payloadKinds = transition.events.map { event -> String in
                switch event.payload {
                case .portalEntered: return "entered"
                case .portalRetentionResolved: return "retention"
                case .portalOfferMade: return "offer"
                case .playerTransferred: return "transfer"
                case .portalWindowCompleted: return "completed"
                default: return "unexpected"
                }
            }
            let enteredCount = transition.records.count
            let retentionCount = transition.records.count
            let offerCount = transition.records.reduce(0) { $0 + $1.offers.count }
            let transferCount = transition.records.filter {
                if case .transferred = $0.outcome { return true }
                return false
            }.count
            expectEqual(
                payloadKinds,
                Array(repeating: "entered", count: enteredCount)
                    + Array(repeating: "retention", count: retentionCount)
                    + Array(repeating: "offer", count: offerCount)
                    + Array(repeating: "transfer", count: transferCount)
                    + ["completed"]
            )
            expect(transition.events.allSatisfy {
                $0.occurredAt == fixture.capturedState.calendar
                    && $0.payload.referencedProspectIDs.isEmpty
            })
        }

        test("commit preserves player identity and reclassifies every scholarship and NIL promise") {
            let transition = CollegePortalPolicyV1.commit(fixture.result)!
            let recordsByPlayerID = Dictionary(uniqueKeysWithValues:
                transition.records.map { ($0.playerID, $0) }
            )

            for playerID in fixture.entrantIDs {
                let record = recordsByPlayerID[playerID]!
                expectEqual(transition.state.players[playerID], fixture.capturedState.players[playerID])
                expectEqual(
                    transition.state.people.playerLifecycle[playerID],
                    fixture.capturedState.people.playerLifecycle[playerID]
                )
                let beforeCareer = fixture.capturedState.people.playerCareers[playerID]!
                let afterCareer = transition.state.people.playerCareers[playerID]!
                expectEqual(afterCareer.recruitingOrigin, beforeCareer.recruitingOrigin)
                expectEqual(afterCareer.seasons, beforeCareer.seasons)
                expectEqual(afterCareer.endedAt, beforeCareer.endedAt)
                expectEqual(afterCareer.endStatus, beforeCareer.endStatus)
                expectEqual(afterCareer.portalWindows, beforeCareer.portalWindows + [record])

                let owners = transition.state.programmes.values.filter {
                    $0.rosterIDs.contains(playerID)
                }
                expectEqual(owners.count, 1)
                expectEqual(owners[0].id, record.finalProgrammeID)
                let finalRecruiting = transition.state.college.programmes[record.finalProgrammeID]!
                expectEqual(
                    finalRecruiting.scholarshipPlayerIDs.contains(playerID),
                    record.finalIsScholarship
                )
                expectEqual(
                    finalRecruiting.nilState.rosterAllocations[playerID] ?? 0,
                    record.finalRosterNIL
                )
            }

            expect(transition.state.college.programmes.values.allSatisfy {
                $0.nilState.portalReservations.isEmpty
            })
            let acceptedPlayerIDs = Set(transition.records.compactMap { record -> UUID? in
                if case .transferred = record.outcome { return record.playerID }
                return nil
            })
            for record in transition.records {
                for offer in record.offers where !acceptedPlayerIDs.contains(record.playerID)
                    || offer.destinationProgrammeID != record.finalProgrammeID {
                    expect(
                        transition.state.college.programmes[offer.destinationProgrammeID]!
                            .nilState.portalReservations[record.playerID] == nil
                    )
                }
            }
        }

        test("sealed result replays deterministically and only the projected boundary round trips") {
            let first = CollegePortalPolicyV1.commit(fixture.result)!
            let second = CollegePortalPolicyV1.commit(fixture.result)!
            expectEqual(first, second)
            expectEqual(
                try JSONEncoder.stable().encode(first.state),
                try JSONEncoder.stable().encode(second.state)
            )
            expectEqual(first.state.calendar, fixture.capturedState.calendar)

            let intermediateData = try JSONEncoder.stable().encode(first.state)
            do {
                _ = try JSONDecoder().decode(GameState.self, from: intermediateData)
                expect(false, "the captured-calendar transaction encoded as a stable boundary")
            } catch {
                expect(true)
            }
            var projected = first.state
            projected.calendar = CalendarState(season: 1, week: 1)
            projected.league.season = 1
            projected.league.week = 1
            expect(WorldIntegrity.check(projected).isValid)
            expectEqual(try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(projected)
            ), projected)
        }

        test("an empty window commits one completion event without inventing entrants") {
            var emptySource = fixture.capturedState
            for playerID in fixture.entrantIDs {
                _ = emptySource.players.update(playerID) { $0.remove(.restless) }
            }
            let entrantSet = Set(fixture.entrantIDs)
            emptySource.people = PeopleState(
                playerLifecycle: Array(emptySource.people.playerLifecycle.values),
                playerCareers: emptySource.people.playerCareers.map { playerID, career in
                    PlayerCareerRecord(
                        playerID: playerID,
                        recruitingOrigin: career.recruitingOrigin,
                        seasons: career.seasons.map { season in
                            guard entrantSet.contains(playerID), season.season == 0 else {
                                return season
                            }
                            return PlayerCareerSeason(
                                season: season.season,
                                organisationID: season.organisationID,
                                tier: season.tier,
                                games: 12,
                                starts: season.starts,
                                overallAtEnd: season.overallAtEnd
                            )
                        },
                        portalWindows: career.portalWindows,
                        endedAt: career.endedAt,
                        endStatus: career.endStatus
                    )
                },
                staffCareers: Array(emptySource.people.staffCareers.values),
                departedPlayers: Array(emptySource.people.departedPlayers.values)
            )
            let market = CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: emptySource
            )!
            let result = CollegePortalPolicyV1.match(using: market)!
            expect(result.entrants.isEmpty)
            let transition = CollegePortalPolicyV1.commit(result)!
            expect(transition.records.isEmpty)
            expectEqual(transition.summary.entrantCount, 0)
            expectEqual(transition.events.count, 1)
            if case .portalWindowCompleted(let summary) = transition.events[0].payload {
                expectEqual(summary, transition.summary)
            } else {
                expect(false, "the empty window did not emit its completion summary")
            }
            expectEqual(transition.state.college.portal.phase, .awaitingSpring)
            expect(transition.state.college.portal.entries.isEmpty)
        }

        test("sequence exhaustion rejects the whole commit without mutating the captured root") {
            var exhaustedSource = fixture.capturedState
            var exhaustedHistory = DomainEventLedger()
            expect(exhaustedHistory.append(DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: exhaustedSource.league.seed,
                    sequence: Int.max
                ),
                sequence: Int.max,
                occurredAt: exhaustedSource.calendar,
                payload: .integrityChecked(issueCount: 0)
            )))
            exhaustedSource.history = exhaustedHistory
            let before = try JSONEncoder.stable().encode(exhaustedSource)
            let market = CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: exhaustedSource
            )!
            let result = CollegePortalPolicyV1.match(using: market)!
            expect(CollegePortalPolicyV1.commit(result) == nil)
            expectEqual(try JSONEncoder.stable().encode(exhaustedSource), before)
        }

        test("a programme can send and receive in one batch without losing either roster update") {
            let twoWay = portalTwoWayResult(from: fixture)
            let transition = CollegePortalPolicyV1.commit(twoWay.result)!
            let transferred = transition.records.filter {
                if case .transferred = $0.outcome { return true }
                return false
            }
            expectEqual(transferred.count, 2)
            let sourceAndDestinationID = fixture.releasedSourceID
            expect(transferred.contains { $0.sourceProgrammeID == sourceAndDestinationID })
            expect(transferred.contains { $0.finalProgrammeID == sourceAndDestinationID })

            for programmeID in [sourceAndDestinationID, fixture.destinationID] {
                let incoming = transferred.filter { $0.finalProgrammeID == programmeID }
                    .map(\.playerID).sorted { $0.uuidString < $1.uuidString }
                let outgoing = Set(transferred.filter { $0.sourceProgrammeID == programmeID }
                    .map(\.playerID))
                let expected = twoWay.source.programmes[programmeID]!.rosterIDs.filter {
                    !outgoing.contains($0)
                } + incoming
                expectEqual(transition.state.programmes[programmeID]!.rosterIDs, expected)
                expectEqual(
                    transition.state.programmes[programmeID]!.scholarshipCount,
                    transition.state.college.programmes[programmeID]!
                        .scholarshipPlayerIDs.count
                )
            }
        }

        test("spring replaces hot entries while preserving postseason summary and career history") {
            let postseason = CollegePortalPolicyV1.commit(fixture.result)!
            var springSource = postseason.state
            springSource.calendar = CalendarState(season: 1, week: 1)
            springSource.league.season = 1
            springSource.league.week = 1
            let springMarket = CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .spring,
                in: springSource
            )!
            let springResult = CollegePortalPolicyV1.match(using: springMarket)!
            let spring = CollegePortalPolicyV1.commit(springResult)!
            expectEqual(spring.state.college.portal.phase, .closed)
            expectEqual(spring.state.college.portal.summaries.map(\.window), [
                .postseason,
                .spring,
            ])
            expect(spring.state.college.portal.entries.values.allSatisfy {
                $0.window == .spring
            })
            expectEqual(spring.state.college.portal.entries.count, spring.records.count)
            for record in spring.records {
                let career = spring.state.people.playerCareers[record.playerID]!
                expectEqual(career.portalWindows.last, record)
                let prior = postseason.state.people.playerCareers[record.playerID]!.portalWindows
                expectEqual(career.portalWindows, prior + [record])
            }
            let postseasonTransferredID = postseason.records.first {
                if case .transferred = $0.outcome { return true }
                return false
            }!.playerID
            if let springRecord = spring.state.college.portal.entries[postseasonTransferredID] {
                if case .transferred = springRecord.outcome {
                    expect(false, "a postseason transfer moved a second time in spring")
                } else {
                    expect(true)
                }
            }
            expect(WorldIntegrity.check(spring.state).isValid)
            expectEqual(
                try SaveEnvelope.decode(GameState.self, from: SaveEnvelope.encode(spring.state)),
                spring.state
            )
        }

        test("whole-root integrity identifies portal owner scholarship NIL career and phase drift") {
            let stable = projectedPostseasonTransition(fixture)
            let transferred = stable.records.first {
                if case .transferred = $0.outcome { return true }
                return false
            }!
            let destinationID = transferred.finalProgrammeID

            var wrongOwner = stable.state
            _ = wrongOwner.programmes.update(destinationID) { programme in
                programme.rosterIDs.removeAll { $0 == transferred.playerID }
            }
            expect(WorldIntegrity.check(wrongOwner).issues.contains {
                if case .invalidPortalOwner(let playerID, _) = $0 {
                    return playerID == transferred.playerID
                }
                return false
            })

            var wrongScholarship = stable.state
            let destination = wrongScholarship.college.programmes[destinationID]!
            let scholarships = destination.scholarshipPlayerIDs.filter {
                $0 != transferred.playerID
            }
            let withoutScholarship = ProgrammeRecruitingState(
                programmeID: destinationID,
                boardIDs: destination.boardIDs,
                relationships: destination.relationships,
                scholarshipPlayerIDs: scholarships,
                contactPointsRemaining: destination.contactPointsRemaining,
                nilState: destination.nilState
            )
            var recruiting = wrongScholarship.college.programmes
            recruiting[destinationID] = withoutScholarship
            _ = wrongScholarship.programmes.update(destinationID) {
                $0.scholarshipCount = scholarships.count
            }
            wrongScholarship.college = CollegeState(
                recruitingSeason: wrongScholarship.college.recruitingSeason,
                portal: wrongScholarship.college.portal,
                phase: wrongScholarship.college.phase,
                programmes: recruiting,
                prospectRecruitment: wrongScholarship.college.prospectRecruitment,
                archivedProspects: wrongScholarship.college.archivedProspects,
                redshirtPlans: wrongScholarship.college.redshirtPlans
            )
            expect(WorldIntegrity.check(wrongScholarship).issues.contains {
                if case .invalidPortalScholarship(let playerID) = $0 {
                    return playerID == transferred.playerID
                }
                return false
            })

            var wrongNIL = stable.state
            let originalRecruiting = wrongNIL.college.programmes[destinationID]!
            var allocations = originalRecruiting.nilState.rosterAllocations
            let wrongAmount = transferred.finalRosterNIL == 100 ? 200 : 100
            allocations[transferred.playerID] = wrongAmount
            let wrongLedger = ProgrammeNILState(
                programmeID: destinationID,
                season: originalRecruiting.nilState.season,
                annualBudget: originalRecruiting.nilState.annualBudget,
                rosterAllocations: allocations,
                recruitingReservations: originalRecruiting.nilState.recruitingReservations
            )
            recruiting = wrongNIL.college.programmes
            recruiting[destinationID] = ProgrammeRecruitingState(
                programmeID: destinationID,
                boardIDs: originalRecruiting.boardIDs,
                relationships: originalRecruiting.relationships,
                scholarshipPlayerIDs: originalRecruiting.scholarshipPlayerIDs,
                contactPointsRemaining: originalRecruiting.contactPointsRemaining,
                nilState: wrongLedger
            )
            wrongNIL.college = CollegeState(
                recruitingSeason: wrongNIL.college.recruitingSeason,
                portal: wrongNIL.college.portal,
                phase: wrongNIL.college.phase,
                programmes: recruiting,
                prospectRecruitment: wrongNIL.college.prospectRecruitment,
                archivedProspects: wrongNIL.college.archivedProspects,
                redshirtPlans: wrongNIL.college.redshirtPlans
            )
            expect(WorldIntegrity.check(wrongNIL).issues.contains {
                if case .invalidPortalNIL(let playerID) = $0 {
                    return playerID == transferred.playerID
                }
                return false
            })

            var wrongCareer = stable.state
            let career = wrongCareer.people.playerCareers[transferred.playerID]!
            wrongCareer.people = PeopleState(
                playerLifecycle: Array(wrongCareer.people.playerLifecycle.values),
                playerCareers: wrongCareer.people.playerCareers.map { playerID, current in
                    guard playerID == transferred.playerID else { return current }
                    return PlayerCareerRecord(
                        playerID: playerID,
                        recruitingOrigin: career.recruitingOrigin,
                        seasons: career.seasons,
                        portalWindows: Array(career.portalWindows.dropLast()),
                        endedAt: career.endedAt,
                        endStatus: career.endStatus
                    )
                },
                staffCareers: Array(wrongCareer.people.staffCareers.values),
                departedPlayers: Array(wrongCareer.people.departedPlayers.values)
            )
            expect(WorldIntegrity.check(wrongCareer).issues.contains {
                if case .invalidPortalCareer(let playerID) = $0 {
                    return playerID == transferred.playerID
                }
                return false
            })

            expect(WorldIntegrity.check(stable.state).isValid)
            let intermediate = CollegePortalPolicyV1.commit(fixture.result)!.state
            expect(WorldIntegrity.check(intermediate).issues.contains {
                if case .invalidPortalState = $0 { return true }
                return false
            })
            expectEqual(Set(WorldIntegrity.activeChecks).count, WorldIntegrity.activeChecks.count)
        }

        test("retained portal events are bound exactly while a valid hot suffix may be partial") {
            let stable = projectedPostseasonTransition(fixture)
            let enteredIndex = stable.state.history.recent.firstIndex {
                if case .portalEntered = $0.payload { return true }
                return false
            }!
            let wrongIntent = stable.records.first {
                $0.intent != stable.records[0].intent
            }!.intent
            var events = stable.state.history.recent
            let original = events[enteredIndex]
            if case let .portalEntered(playerID, sourceID, target, window, _) = original.payload {
                events[enteredIndex] = DomainEvent(
                    id: original.id,
                    sequence: original.sequence,
                    occurredAt: original.occurredAt,
                    payload: .portalEntered(
                        playerID: playerID,
                        sourceProgrammeID: sourceID,
                        targetSeason: target,
                        window: window,
                        intent: wrongIntent
                    )
                )
            }
            var mismatched = stable.state
            var mismatchedLedger = DomainEventLedger()
            expect(mismatchedLedger.append(contentsOf: events))
            mismatched.history = mismatchedLedger
            expect(WorldIntegrity.check(mismatched).issues.contains {
                if case .invalidPortalEvent(let eventID) = $0 { return eventID == original.id }
                return false
            })

            var suffix = stable.state
            var suffixLedger = DomainEventLedger(retentionLimit: 1)
            expect(suffixLedger.append(contentsOf: stable.state.history.recent))
            suffix.history = suffixLedger
            expect(!WorldIntegrity.check(suffix).issues.contains {
                if case .invalidPortalEvent = $0 { return true }
                return false
            })
        }

        test("portal knowledge rejects orphan observers and disagreement with persisted offers") {
            let stable = projectedPostseasonTransition(fixture)
            let existing = stable.state.scouting.portalKnowledgeByObserver.values
                .flatMap { $0 }.first!
            let orphanObserver = UUID(uuidString: "FFFFFFFF-FFFF-4FFF-8FFF-FFFFFFFFFFFF")!
            let orphan = CollegePortalKnowledgeSnapshot(
                observerProgrammeID: orphanObserver,
                playerID: existing.playerID,
                sourceProgrammeID: existing.sourceProgrammeID,
                targetSeason: existing.targetSeason,
                window: existing.window,
                position: existing.position,
                estimatedOverall: existing.estimatedOverall,
                estimatedAttributes: existing.estimatedAttributes,
                estimatedPotential: existing.estimatedPotential,
                confidence: existing.confidence,
                lastUpdated: existing.lastUpdated,
                evidenceCount: existing.evidenceCount
            )
            var orphaned = stable.state
            var portalKnowledge = orphaned.scouting.portalKnowledgeByObserver
            portalKnowledge[orphanObserver] = [orphan]
            orphaned.scouting = ScoutingState(
                observationsByObserver: orphaned.scouting.observationsByObserver,
                pendingEvaluations: orphaned.scouting.pendingEvaluations,
                portalKnowledgeByObserver: portalKnowledge
            )
            expect(WorldIntegrity.check(orphaned).issues.contains {
                if case .invalidPortalKnowledge(let observerID, let playerID) = $0 {
                    return observerID == orphanObserver && playerID == existing.playerID
                }
                return false
            })

            let entrantIDs = Set(stable.records.map(\.playerID))
            let fabricatedPlayerID = stable.state.programmes[existing.sourceProgrammeID]!
                .rosterIDs.first { !entrantIDs.contains($0) }!
            let fabricated = CollegePortalKnowledgeSnapshot(
                observerProgrammeID: existing.observerProgrammeID,
                playerID: fabricatedPlayerID,
                sourceProgrammeID: existing.sourceProgrammeID,
                targetSeason: existing.targetSeason,
                window: existing.window,
                position: existing.position,
                estimatedOverall: existing.estimatedOverall,
                estimatedAttributes: existing.estimatedAttributes,
                estimatedPotential: existing.estimatedPotential,
                confidence: existing.confidence,
                lastUpdated: existing.lastUpdated,
                evidenceCount: existing.evidenceCount
            )
            var withoutEntrant = stable.state
            portalKnowledge = withoutEntrant.scouting.portalKnowledgeByObserver
            portalKnowledge[existing.observerProgrammeID, default: []].append(fabricated)
            withoutEntrant.scouting = ScoutingState(
                observationsByObserver: withoutEntrant.scouting.observationsByObserver,
                pendingEvaluations: withoutEntrant.scouting.pendingEvaluations,
                portalKnowledgeByObserver: portalKnowledge
            )
            expect(WorldIntegrity.check(withoutEntrant).issues.contains {
                if case .invalidPortalKnowledge(let observerID, let playerID) = $0 {
                    return observerID == fabricated.observerProgrammeID
                        && playerID == fabricated.playerID
                }
                return false
            })

            let offer = stable.records.flatMap(\.offers).first!
            let stored = stable.state.scouting.portalKnowledge(
                observerProgrammeID: offer.destinationProgrammeID,
                playerID: offer.knowledge.playerID,
                sourceProgrammeID: offer.knowledge.sourceProgrammeID,
                targetSeason: offer.knowledge.targetSeason,
                window: offer.knowledge.window
            )!
            let changed = CollegePortalKnowledgeSnapshot(
                observerProgrammeID: stored.observerProgrammeID,
                playerID: stored.playerID,
                sourceProgrammeID: stored.sourceProgrammeID,
                targetSeason: stored.targetSeason,
                window: stored.window,
                position: stored.position,
                estimatedOverall: stored.estimatedOverall,
                estimatedAttributes: stored.estimatedAttributes,
                estimatedPotential: Rating(stored.estimatedPotential.value == 99
                    ? 98
                    : stored.estimatedPotential.value + 1),
                confidence: stored.confidence,
                lastUpdated: stored.lastUpdated,
                evidenceCount: stored.evidenceCount
            )
            var disagrees = stable.state
            portalKnowledge = disagrees.scouting.portalKnowledgeByObserver
            portalKnowledge[stored.observerProgrammeID] = portalKnowledge[
                stored.observerProgrammeID
            ]!.map { $0 == stored ? changed : $0 }
            disagrees.scouting = ScoutingState(
                observationsByObserver: disagrees.scouting.observationsByObserver,
                pendingEvaluations: disagrees.scouting.pendingEvaluations,
                portalKnowledgeByObserver: portalKnowledge
            )
            expect(WorldIntegrity.check(disagrees).issues.contains {
                if case .invalidPortalKnowledge(let observerID, let playerID) = $0 {
                    return observerID == stored.observerProgrammeID
                        && playerID == stored.playerID
                }
                return false
            })
        }

        test("durable career batches retain one capacity snapshot after hot entries rotate") {
            let postseason = CollegePortalPolicyV1.commit(fixture.result)!
            var springSource = postseason.state
            springSource.calendar = CalendarState(season: 1, week: 1)
            springSource.league.season = 1
            springSource.league.week = 1
            let spring = CollegePortalPolicyV1.commit(CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .spring,
                    in: springSource
                )!
            )!)!
            expectEqual(spring.state.college.portal.phase, .closed)
            expect(spring.state.college.portal.entries.values.allSatisfy {
                $0.window == .spring
            })

            let offersByDestination = Dictionary(grouping:
                postseason.records.flatMap { record in
                    record.offers.map { (record, $0) }
                },
                by: { $0.1.destinationProgrammeID }
            )
            let shared = offersByDestination.values.first { $0.count >= 2 }!
            let recordToChange = shared[1].0
            let offerToChange = shared[1].1
            let capacity = offerToChange.fixedCapacity
            let changedRemaining = capacity.nilRemaining <= 9_800
                ? capacity.nilRemaining + 100
                : capacity.nilRemaining - 100
            let changedCapacity = CollegePortalCapacitySnapshot(
                programmeID: capacity.programmeID,
                targetSeason: capacity.targetSeason,
                window: capacity.window,
                capturedAt: capacity.capturedAt,
                rosterOpenings: capacity.rosterOpenings,
                scholarshipOpenings: capacity.scholarshipOpenings,
                nilRemaining: changedRemaining
            )
            let changedOffer = CollegePortalOffer(
                destinationProgrammeID: offerToChange.destinationProgrammeID,
                nilReservation: offerToChange.nilReservation,
                knowledge: offerToChange.knowledge,
                playerFit: offerToChange.playerFit,
                destinationAdmission: offerToChange.destinationAdmission,
                fixedCapacity: changedCapacity
            )
            let changedOffers = recordToChange.offers.map {
                $0 == offerToChange ? changedOffer : $0
            }
            let changedRecord = CollegePortalWindowRecord(
                policyVersion: recordToChange.policyVersion,
                playerID: recordToChange.playerID,
                sourceProgrammeID: recordToChange.sourceProgrammeID,
                targetSeason: recordToChange.targetSeason,
                window: recordToChange.window,
                openedAt: recordToChange.openedAt,
                sourceWasScholarship: recordToChange.sourceWasScholarship,
                intent: recordToChange.intent,
                retention: recordToChange.retention,
                offers: changedOffers,
                outcome: recordToChange.outcome,
                finalIsScholarship: recordToChange.finalIsScholarship,
                finalRosterNIL: recordToChange.finalRosterNIL
            )
            var hostile = spring.state
            hostile.history = DomainEventLedger()
            hostile.people = PeopleState(
                playerLifecycle: Array(hostile.people.playerLifecycle.values),
                playerCareers: hostile.people.playerCareers.map { playerID, career in
                    guard playerID == changedRecord.playerID else { return career }
                    return PlayerCareerRecord(
                        playerID: playerID,
                        recruitingOrigin: career.recruitingOrigin,
                        seasons: career.seasons,
                        portalWindows: career.portalWindows.map {
                            $0 == recordToChange ? changedRecord : $0
                        },
                        endedAt: career.endedAt,
                        endStatus: career.endStatus
                    )
                },
                staffCareers: Array(hostile.people.staffCareers.values),
                departedPlayers: Array(hostile.people.departedPlayers.values)
            )
            expect(WorldIntegrity.check(hostile).issues.contains {
                if case .invalidPortalCapacity(let targetSeason, let window) = $0 {
                    return targetSeason == 1 && window == .postseason
                }
                return false
            })
        }

        test("stable portal summaries and live entries equal durable current-target careers") {
            let postseason = projectedPostseasonTransition(fixture)
            let omittedRecords = Array(postseason.records.dropLast())
            let omittedPortal = CollegePortalState(
                targetSeason: 1,
                phase: .awaitingSpring,
                entries: Dictionary(uniqueKeysWithValues: omittedRecords.map {
                    ($0.playerID, $0)
                }),
                summaries: [portalSummary(
                    targetSeason: 1,
                    window: .postseason,
                    records: omittedRecords
                )]
            )
            let omitted = replacingPortal(omittedPortal, in: postseason.state)
            expect(WorldIntegrity.check(omitted).issues.contains {
                if case .invalidPortalState = $0 { return true }
                return false
            })
            let hiddenTargetHistory = replacingPortal(
                CollegePortalState(targetSeason: 1),
                in: postseason.state
            )
            expect(WorldIntegrity.check(hiddenTargetHistory).issues.contains {
                if case .invalidPortalState = $0 { return true }
                return false
            })

            let postseasonTransition = CollegePortalPolicyV1.commit(fixture.result)!
            var springSource = postseasonTransition.state
            springSource.calendar = CalendarState(season: 1, week: 1)
            springSource.league.season = 1
            springSource.league.week = 1
            let spring = CollegePortalPolicyV1.commit(CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .spring,
                    in: springSource
                )!
            )!)!
            let wrongPostseasonSummary = CollegePortalWindowSummary(
                targetSeason: 1,
                window: .postseason,
                completedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks),
                entrantCount: 0,
                retainedCount: 0,
                transferredCount: 0,
                returnedCount: 0,
                offerCount: 0
            )
            let wrongSummaryPortal = CollegePortalState(
                targetSeason: 1,
                phase: .closed,
                entries: spring.state.college.portal.entries,
                summaries: [wrongPostseasonSummary, spring.summary]
            )
            let wrongSummary = replacingPortal(wrongSummaryPortal, in: spring.state)
            expect(WorldIntegrity.check(wrongSummary).issues.contains {
                if case .invalidPortalState = $0 { return true }
                return false
            })

            let postseasonOffer = postseason.records.flatMap(\.offers).first!
            var knowledge = spring.state.scouting.portalKnowledgeByObserver
            knowledge[postseasonOffer.destinationProgrammeID] = knowledge[
                postseasonOffer.destinationProgrammeID
            ]!.filter { $0 != postseasonOffer.knowledge }
            if knowledge[postseasonOffer.destinationProgrammeID]?.isEmpty == true {
                knowledge.removeValue(forKey: postseasonOffer.destinationProgrammeID)
            }
            var missingRotatedKnowledge = spring.state
            missingRotatedKnowledge.scouting = ScoutingState(
                observationsByObserver: spring.state.scouting.observationsByObserver,
                pendingEvaluations: spring.state.scouting.pendingEvaluations,
                portalKnowledgeByObserver: knowledge
            )
            expect(WorldIntegrity.check(missingRotatedKnowledge).issues.contains {
                if case .invalidPortalKnowledge(let observerID, let playerID) = $0 {
                    return observerID == postseasonOffer.destinationProgrammeID
                        && playerID == postseasonOffer.knowledge.playerID
                }
                return false
            })
        }

        test("awaiting spring rejects target-season results and duplicate or wrong-week facts") {
            let stable = projectedPostseasonTransition(fixture)
            var playedEarly = stable.state
            var game = playedEarly.competition.currentSchedule.games.first {
                $0.season == 1
            }!
            game.result = AbstractGameSimulator.play(game, in: playedEarly)
            expect(playedEarly.competition.currentSchedule.replace(game))
            playedEarly.competition = CompetitionReducer.rebuild(from: playedEarly)
            expect(WorldIntegrity.check(playedEarly).issues.contains {
                if case .invalidPortalState = $0 { return true }
                return false
            })

            let originalEvents = stable.state.history.recent
            let entered = originalEvents.first {
                if case .portalEntered = $0.payload { return true }
                return false
            }!
            let duplicate = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: stable.state.league.seed,
                    sequence: originalEvents.last!.sequence + 1
                ),
                sequence: originalEvents.last!.sequence + 1,
                occurredAt: entered.occurredAt,
                payload: entered.payload
            )
            var duplicated = stable.state
            var duplicateLedger = DomainEventLedger()
            expect(duplicateLedger.append(contentsOf: originalEvents + [duplicate]))
            duplicated.history = duplicateLedger
            expect(WorldIntegrity.check(duplicated).issues.contains {
                if case .invalidPortalEvent(let eventID) = $0 { return eventID == duplicate.id }
                return false
            })

            var wrongWeekEvents: [DomainEvent] = []
            for event in originalEvents {
                wrongWeekEvents.append(DomainEvent(
                    id: event.id,
                    sequence: event.sequence,
                    occurredAt: CalendarState(season: 1, week: 1),
                    payload: event.payload
                ))
            }
            var wrongWeek = stable.state
            var wrongWeekLedger = DomainEventLedger()
            expect(wrongWeekLedger.append(contentsOf: wrongWeekEvents))
            wrongWeek.history = wrongWeekLedger
            expect(WorldIntegrity.check(wrongWeek).issues.contains {
                if case .invalidPortalEvent = $0 { return true }
                return false
            })
        }

        test("zero-dollar acceptance creates scholarship ownership without a phantom NIL identity") {
            var source = fixture.capturedState
            let destinationID = fixture.destinationID
            let current = source.college.programmes[destinationID]!
            let recruitingTotal = current.nilState.recruitingReservations.values.reduce(0, +)
            let available = current.nilState.annualBudget - recruitingTotal
            let allocationID = source.programmes[destinationID]!.rosterIDs.first {
                current.nilState.recruitingReservations[$0] == nil
            }!
            let consumingAllocations = available > 99
                ? [allocationID: available - 99]
                : [:]
            var recruiting = source.college.programmes
            recruiting[destinationID] = ProgrammeRecruitingState(
                programmeID: destinationID,
                boardIDs: current.boardIDs,
                relationships: current.relationships,
                scholarshipPlayerIDs: current.scholarshipPlayerIDs,
                contactPointsRemaining: current.contactPointsRemaining,
                nilState: ProgrammeNILState(
                    programmeID: destinationID,
                    season: current.nilState.season,
                    annualBudget: current.nilState.annualBudget,
                    rosterAllocations: consumingAllocations,
                    recruitingReservations: current.nilState.recruitingReservations
                )
            )
            source.college = CollegeState(
                recruitingSeason: source.college.recruitingSeason,
                portal: source.college.portal,
                phase: source.college.phase,
                programmes: recruiting,
                prospectRecruitment: source.college.prospectRecruitment,
                archivedProspects: source.college.archivedProspects,
                redshirtPlans: source.college.redshirtPlans
            )
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: source
                )!
            )!
            let accepted = result.entrants.first {
                $0.acceptedDestinationProgrammeID == destinationID
            }!
            let acceptedOffer = accepted.offers.first {
                $0.destinationProgrammeID == destinationID
            }!
            expectEqual(acceptedOffer.nilReservation, 0)
            let transition = CollegePortalPolicyV1.commit(result)!
            let record = transition.records.first { $0.playerID == accepted.playerID }!
            expectEqual(record.finalRosterNIL, 0)
            expect(transition.state.college.programmes[destinationID]!
                .scholarshipPlayerIDs.contains(accepted.playerID))
            expect(transition.state.college.programmes[destinationID]!
                .nilState.rosterAllocations[accepted.playerID] == nil)
            expect(transition.state.college.programmes[destinationID]!
                .nilState.portalReservations[accepted.playerID] == nil)
        }

        test("a sealed result with an unrelated corrupt career fails atomically at final integrity") {
            var corrupt = fixture.capturedState
            let unrelatedPlayerID = corrupt.players.ids.first {
                !fixture.entrantIDs.contains($0)
                    && corrupt.people.playerCareers[$0]?.seasons.isEmpty == false
            }!
            let career = corrupt.people.playerCareers[unrelatedPlayerID]!
            let unknownProgrammeID = UUID(
                uuidString: "EEEEEEEE-EEEE-4EEE-8EEE-EEEEEEEEEEEE"
            )!
            corrupt.people = PeopleState(
                playerLifecycle: Array(corrupt.people.playerLifecycle.values),
                playerCareers: corrupt.people.playerCareers.map { playerID, current in
                    guard playerID == unrelatedPlayerID else { return current }
                    return PlayerCareerRecord(
                        playerID: playerID,
                        recruitingOrigin: career.recruitingOrigin,
                        seasons: career.seasons.map { season in
                            guard season.season == 0 else { return season }
                            return PlayerCareerSeason(
                                season: season.season,
                                organisationID: unknownProgrammeID,
                                tier: season.tier,
                                games: season.games,
                                starts: season.starts,
                                overallAtEnd: season.overallAtEnd
                            )
                        },
                        portalWindows: career.portalWindows,
                        endedAt: career.endedAt,
                        endStatus: career.endStatus
                    )
                },
                staffCareers: Array(corrupt.people.staffCareers.values),
                departedPlayers: Array(corrupt.people.departedPlayers.values)
            )
            let before = try JSONEncoder.stable().encode(corrupt)
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: corrupt
                )!
            )!
            expect(CollegePortalPolicyV1.commit(result) == nil)
            expectEqual(try JSONEncoder.stable().encode(corrupt), before)
        }

        test("the intermediate college coverage allowance never masks corrupt pro coverage") {
            var corrupt = fixture.capturedState
            let team = corrupt.proTeams.values[0]
            let position = Position.allCases.first {
                (SharedRules.minimumPlayableRosterByPosition[$0] ?? 0) > 0
            }!
            let minimum = SharedRules.minimumPlayableRosterByPosition[position]!
            let positionPlayerIDs = team.rosterIDs.filter {
                corrupt.players[$0]?.position == position
            }
            let replacement = Position.allCases.first { $0 != position }!
            for playerID in positionPlayerIDs.prefix(
                max(0, positionPlayerIDs.count - minimum + 1)
            ) {
                _ = corrupt.players.update(playerID) { $0.position = replacement }
            }
            expect(WorldIntegrity.check(corrupt).issues.contains {
                if case let .missingPositionalCoverage(organisationID, missing) = $0 {
                    return organisationID == team.id && missing == position
                }
                return false
            })

            let before = try JSONEncoder.stable().encode(corrupt)
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: corrupt
                )!
            )!
            expect(CollegePortalPolicyV1.commit(result) == nil)
            expectEqual(try JSONEncoder.stable().encode(corrupt), before)
        }
    }

    suite("Portal-touched departed-player retention") {
        test("a departed portal entrant is protected only while its window's completion event survives") {
            let projected = projectedPostseasonTransition(fixture)
            let entrantIDs = fixture.entrantIDs

            func fillerIdentity() -> DepartedPlayerIdentity {
                DepartedPlayerIdentity(
                    player: Player(
                        firstName: "Filler",
                        lastName: "Player",
                        position: .quarterback,
                        age: 25,
                        attributes: Attributes(),
                        potential: Rating(60)
                    ),
                    status: .graduated
                )
            }

            func buildState(dropCompletionEvent: Bool) -> GameState {
                var state = projected.state
                let fillerIdentities = (0..<PeopleRules.departedPlayerRetentionLimit).map { _ in
                    fillerIdentity()
                }
                let fillerCareers = fillerIdentities.map {
                    PlayerCareerRecord(
                        playerID: $0.id,
                        portalWindows: [],
                        endedAt: CalendarState(season: 1, week: 1),
                        endStatus: .graduated
                    )
                }
                let realIdentities = entrantIDs.map { id -> DepartedPlayerIdentity in
                    let player = state.players[id]!
                    _ = state.players.remove(id)
                    return DepartedPlayerIdentity(player: player, status: .graduated)
                }
                state.people = PeopleState(
                    playerLifecycle: Array(state.people.playerLifecycle.values),
                    playerCareers: Array(state.people.playerCareers.values) + fillerCareers,
                    staffCareers: Array(state.people.staffCareers.values),
                    departedPlayers: fillerIdentities + realIdentities
                )
                if dropCompletionEvent {
                    // Simulates the postseason window's `.portalWindowCompleted` event having
                    // aged out of the bounded hot journal, the way it eventually does after
                    // enough later seasons of unrelated activity.
                    state.history = DomainEventLedger()
                }
                state.calendar = CalendarState(season: 1, week: SharedRules.inSeasonWeeks)
                state.league.week = SharedRules.inSeasonWeeks
                return state
            }

            let liveCompletion = buildState(dropCompletionEvent: false)
            let liveTransition = try SeasonLifecycleSystem.advance(
                after: liveCompletion.calendar,
                in: liveCompletion
            )
            expect(
                entrantIDs.allSatisfy { liveTransition.people.departedPlayers[$0] != nil },
                "a portal entrant was evicted while its window's completion event was still live"
            )
            expectEqual(
                liveTransition.people.departedPlayers.count,
                PeopleRules.departedPlayerRetentionLimit
            )

            let agedOutCompletion = buildState(dropCompletionEvent: true)
            let agedOutTransition = try SeasonLifecycleSystem.advance(
                after: agedOutCompletion.calendar,
                in: agedOutCompletion
            )
            expect(
                entrantIDs.allSatisfy { agedOutTransition.people.departedPlayers[$0] == nil },
                "a portal entrant outlived every trace of its window once the completion event aged out"
            )
            expect(
                entrantIDs.allSatisfy { agedOutTransition.people.playerCareers[$0] == nil },
                "eviction dropped the departed identity but kept its paired career record"
            )
            var agedOutState = agedOutCompletion
            agedOutState.programmes = agedOutTransition.programmes
            agedOutState.proTeams = agedOutTransition.proTeams
            agedOutState.players = agedOutTransition.players
            agedOutState.staff = agedOutTransition.staff
            agedOutState.people = agedOutTransition.people
            agedOutState.college = agedOutTransition.college
            expect(
                !WorldIntegrity.check(agedOutState).issues.contains {
                    if case .invalidPortalCapacity = $0 { return true }
                    return false
                },
                "retained fragments of an archived portal window were treated as a complete batch"
            )
            expectEqual(
                agedOutTransition.people.departedPlayers.count,
                PeopleRules.departedPlayerRetentionLimit
            )
        }
    }
}
