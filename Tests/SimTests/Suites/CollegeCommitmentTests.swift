import Foundation
import FootballSimCore

private func projectedCapacityState(
    seed: UInt64,
    rosterOpenings: Int,
    scholarshipOpenings: Int
) -> (state: GameState, programmeID: UUID) {
    precondition(scholarshipOpenings <= rosterOpenings)
    var state = GameState.bootstrap(seed: seed)
    let programmeID = state.programmes.ids[0]
    let rosterIDs = state.programmes[programmeID]!.rosterIDs
    let scholarshipIDs = state.college.programmes[programmeID]!.scholarshipPlayerIDs
    let scholarshipSet = Set(scholarshipIDs)

    for playerID in rosterIDs {
        state.players.update(playerID) {
            $0.eligibility = Eligibility()
        }
    }
    let departingScholarships = Array(scholarshipIDs.prefix(scholarshipOpenings))
    let departingWalkOns = rosterIDs.filter { !scholarshipSet.contains($0) }
        .prefix(rosterOpenings - scholarshipOpenings)
    for playerID in departingScholarships + departingWalkOns {
        state.players.update(playerID) {
            $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 1)
        }
    }
    return (state, programmeID)
}

private func kickerReservedCapacityState(
    seed: UInt64,
    rosterOpenings: Int = 1
) -> (state: GameState, programmeID: UUID) {
    precondition(rosterOpenings >= 1)
    var fixture = projectedCapacityState(
        seed: seed,
        rosterOpenings: 0,
        scholarshipOpenings: 0
    )
    let programme = fixture.state.programmes[fixture.programmeID]!
    let kickerID = programme.rosterIDs.first {
        fixture.state.players[$0]?.position == .kicker
    }!
    var departingIDs = [kickerID]
    if rosterOpenings > 1 {
        let rosterCounts = Dictionary(grouping: programme.rosterIDs.compactMap {
            fixture.state.players[$0]?.position
        }, by: { $0 }).mapValues(\.count)
        let additional = programme.rosterIDs.first { playerID in
            guard playerID != kickerID,
                  let position = fixture.state.players[playerID]?.position else { return false }
            return (rosterCounts[position] ?? 0)
                > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
        }!
        departingIDs.append(additional)
    }
    for playerID in departingIDs {
        fixture.state.players.update(playerID) {
            $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 1)
        }
    }
    let existing = fixture.state.college.programmes[fixture.programmeID]!
    var scholarshipIDs = existing.scholarshipPlayerIDs
    for playerID in departingIDs where !scholarshipIDs.contains(playerID) {
        if scholarshipIDs.count == CollegeRules.scholarshipLimit {
            scholarshipIDs.removeLast()
        }
        scholarshipIDs.append(playerID)
    }
    var programmeStates = fixture.state.college.programmes
    programmeStates[fixture.programmeID] = ProgrammeRecruitingState(
        programmeID: fixture.programmeID,
        boardIDs: existing.boardIDs,
        relationships: existing.relationships,
        scholarshipPlayerIDs: scholarshipIDs,
        contactPointsRemaining: existing.contactPointsRemaining,
        nilState: existing.nilState
    )
    fixture.state.college = CollegeState(
        recruitingSeason: fixture.state.college.recruitingSeason,
        portal: fixture.state.college.portal,
        phase: fixture.state.college.phase,
        programmes: programmeStates,
        prospectRecruitment: fixture.state.college.prospectRecruitment,
        archivedProspects: fixture.state.college.archivedProspects,
        redshirtPlans: fixture.state.college.redshirtPlans
    )
    return fixture
}

private func setProjectedScholarshipOpenings(
    _ openings: Int,
    programmeID: UUID,
    in state: inout GameState
) {
    let rosterIDs = state.programmes[programmeID]!.rosterIDs
    let scholarshipIDs = state.college.programmes[programmeID]!.scholarshipPlayerIDs
    for playerID in rosterIDs {
        state.players.update(playerID) { $0.eligibility = Eligibility() }
    }
    var counts = Dictionary(grouping: rosterIDs.compactMap {
        state.players[$0]?.position
    }, by: { $0 }).mapValues(\.count)
    var selected: [UUID] = []
    for playerID in scholarshipIDs {
        guard selected.count < openings,
              let position = state.players[playerID]?.position,
              (counts[position] ?? 0) - 1
                >= (SharedRules.minimumPlayableRosterByPosition[position] ?? 0) else { continue }
        counts[position, default: 0] -= 1
        selected.append(playerID)
    }
    precondition(selected.count == openings)
    for playerID in selected {
        state.players.update(playerID) {
            $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 1)
        }
    }
}

private func installOffers(
    programmeID: UUID,
    prospectInterests: [(UUID, Int)],
    boardIDs: [UUID]? = nil,
    in state: inout GameState
) {
    let existing = state.college.programmes[programmeID]!
    let relationships = Dictionary(uniqueKeysWithValues: prospectInterests.map { prospectID, interest in
        (
            prospectID,
            ProgrammeProspectRelationship(
                prospectID: prospectID,
                interest: interest,
                visitScheduled: true,
                scholarshipOffered: true
            )
        )
    })
    let nilState = ProgrammeNILState(
        programmeID: programmeID,
        season: existing.nilState.season,
        annualBudget: existing.nilState.annualBudget,
        rosterAllocations: existing.nilState.rosterAllocations,
        portalReservations: existing.nilState.portalReservations
    )
    var programmeStates = state.college.programmes
    programmeStates[programmeID] = ProgrammeRecruitingState(
        programmeID: programmeID,
        boardIDs: boardIDs ?? prospectInterests.map(\.0),
        relationships: relationships,
        scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
        contactPointsRemaining: existing.contactPointsRemaining,
        nilState: nilState
    )
    state.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: state.college.portal,
        phase: state.college.phase,
        programmes: programmeStates,
        prospectRecruitment: state.college.prospectRecruitment,
        archivedProspects: state.college.archivedProspects
    )
}

private func contenderContext(
    programmeID: UUID,
    prospectID: UUID,
    in state: GameState
) -> RecruitingCommitmentContenderContext {
    let relationship = state.college.programmes[programmeID]!.relationships[prospectID]!
    let explanation = RecruitingFitSystem.evaluate(
        programmeID: programmeID,
        prospectID: prospectID,
        in: state
    )!
    return RecruitingCommitmentContenderContext(
        programmeID: programmeID,
        score: explanation.total,
        explanation: explanation.components,
        relationshipInterest: relationship.interest,
        nilAllocation: state.college.programmes[programmeID]!.nilState
            .recruitingReservations[prospectID] ?? 0,
        visitScheduled: relationship.visitScheduled
    )
}

private func signingFixture(
    seed: UInt64,
    commitments: Int,
    actualOpenings: Int
) -> (state: GameState, programmeID: UUID, prospectIDs: [UUID]) {
    precondition(actualOpenings <= commitments)
    var state = GameState.bootstrap(seed: seed)
    let programmeID = state.programmes.ids[0]
    setProjectedScholarshipOpenings(commitments, programmeID: programmeID, in: &state)
    let prospectIDs = Array(state.prospects.ids.prefix(commitments))
    installOffers(
        programmeID: programmeID,
        prospectInterests: prospectIDs.enumerated().map { index, prospectID in
            (prospectID, 100 - index)
        },
        in: &state
    )
    let market = CollegeRecruitingMarketSystem.process(
        at: CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek),
        in: state
    )
    precondition(market.commitments.count == commitments)
    state.college = market.college

    let projection = CollegeCommitmentCapacitySystem.capacity(
        programmeID: programmeID,
        in: state,
        college: state.college
    )!
    let returningSet = Set(projection.projectedReturningPlayerIDs)
    let projectedDepartures = state.programmes[programmeID]!.rosterIDs.filter {
        !returningSet.contains($0)
    }
    let actualDepartures = Array(projectedDepartures.prefix(actualOpenings))
    state.programmes.update(programmeID) {
        $0.rosterIDs.removeAll { actualDepartures.contains($0) }
        $0.scholarshipCount -= actualDepartures.count
    }
    state.college.reconcileScholarships(with: state.programmes)
    state.calendar = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
    return (state, programmeID, prospectIDs)
}

private func committedIntegrityFixture(
    seed: UInt64
) -> (
    state: GameState,
    programmeID: UUID,
    prospectID: UUID,
    context: RecruitingCommitmentContext
) {
    var state = GameState.bootstrap(seed: seed)
    state.calendar = CalendarState(
        season: state.calendar.season,
        week: CollegeRules.minimumCommitmentWeek
    )
    state.league.week = state.calendar.week
    let programmeID = state.programmes.ids[0]
    let prospectID = state.prospects.ids[0]
    let existing = state.college.programmes[programmeID]!
    let relationship = ProgrammeProspectRelationship(
        prospectID: prospectID,
        interest: 100,
        visitScheduled: true,
        scholarshipOffered: true
    )
    var programmeStates = state.college.programmes
    programmeStates[programmeID] = ProgrammeRecruitingState(
        programmeID: programmeID,
        boardIDs: [prospectID],
        relationships: [prospectID: relationship],
        scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
        contactPointsRemaining: existing.contactPointsRemaining,
        nilState: existing.nilState
    )
    state.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: state.college.portal,
        phase: .active,
        programmes: programmeStates,
        prospectRecruitment: state.college.prospectRecruitment,
        archivedProspects: state.college.archivedProspects
    )
    let context = RecruitingCommitmentContext(
        committedAt: state.calendar,
        winner: contenderContext(
            programmeID: programmeID,
            prospectID: prospectID,
            in: state
        )
    )
    var recruitment = state.college.prospectRecruitment
    recruitment[prospectID] = ProspectRecruitmentState(
        prospectID: prospectID,
        phase: .committed,
        commitmentHistory: [context]
    )
    state.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: state.college.portal,
        phase: .active,
        programmes: state.college.programmes,
        prospectRecruitment: recruitment,
        archivedProspects: state.college.archivedProspects
    )
    return (state, programmeID, prospectID, context)
}

private func replacingFinalRelationship(
    in state: GameState,
    programmeID: UUID,
    prospectID: UUID,
    mutation: (inout ProgrammeProspectRelationship) -> Void
) -> GameState {
    var next = state
    let existing = state.college.programmes[programmeID]!
    var relationship = existing.relationships[prospectID]!
    mutation(&relationship)
    var programmes = state.college.programmes
    programmes[programmeID] = ProgrammeRecruitingState(
        programmeID: programmeID,
        boardIDs: existing.boardIDs,
        relationships: [prospectID: relationship],
        scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
        contactPointsRemaining: existing.contactPointsRemaining,
        nilState: existing.nilState
    )
    next.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: state.college.portal,
        phase: state.college.phase,
        programmes: programmes,
        prospectRecruitment: state.college.prospectRecruitment,
        archivedProspects: state.college.archivedProspects
    )
    return next
}

private func replacingFinalNILReservation(
    in state: GameState,
    programmeID: UUID,
    prospectID: UUID,
    amount: Int
) -> GameState {
    var next = state
    let existing = state.college.programmes[programmeID]!
    var nilState = existing.nilState
    precondition(nilState.setRecruitingReservation(amount, for: prospectID))
    var programmes = state.college.programmes
    programmes[programmeID] = ProgrammeRecruitingState(
        programmeID: programmeID,
        boardIDs: existing.boardIDs,
        relationships: existing.relationships,
        scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
        contactPointsRemaining: existing.contactPointsRemaining,
        nilState: nilState
    )
    next.college = CollegeState(
        recruitingSeason: state.college.recruitingSeason,
        portal: state.college.portal,
        phase: state.college.phase,
        programmes: programmes,
        prospectRecruitment: state.college.prospectRecruitment,
        archivedProspects: state.college.archivedProspects
    )
    return next
}

private func archivedProspectRoot(
    seed: UInt64,
    currentSeason: Int,
    archivedSeason: Int
) -> (state: GameState, prospectID: UUID) {
    var state = GameState.bootstrap(seed: seed)
    let prospect = state.prospects.values[0]
    _ = state.prospects.remove(prospect.id)
    let remainingRecruitment = state.college.prospectRecruitment.filter {
        $0.key != prospect.id
    }
    state.calendar = CalendarState(season: currentSeason, week: 1)
    state.league.season = currentSeason
    state.league.week = state.calendar.week
    // As in CollegeStateTests' cycle helper: a root whose calendar has moved two seasons past its
    // professional market is one the engine could never produce, and whole-root integrity says so.
    state.proMarket = ProMarketState(season: currentSeason)
    state.competition = CompetitionState.bootstrap(
        seed: state.league.seed,
        season: currentSeason,
        programmes: state.programmes.values,
        proTeams: state.proTeams.values
    )
    let programmeStates = Dictionary(uniqueKeysWithValues: state.college.programmes.map {
        programmeID, recruiting in
        (
            programmeID,
            ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: recruiting.boardIDs,
                relationships: recruiting.relationships,
                scholarshipPlayerIDs: recruiting.scholarshipPlayerIDs,
                contactPointsRemaining: recruiting.contactPointsRemaining,
                nilState: ProgrammeNILState(
                    programmeID: programmeID,
                    season: currentSeason,
                    annualBudget: recruiting.nilState.annualBudget,
                    rosterAllocations: recruiting.nilState.rosterAllocations,
                    recruitingReservations: recruiting.nilState.recruitingReservations,
                    portalReservations: recruiting.nilState.portalReservations
                )
            )
        )
    })
    state.college = CollegeState(
        recruitingSeason: currentSeason,
        portal: CollegePortalState(targetSeason: currentSeason),
        phase: .active,
        programmes: programmeStates,
        prospectRecruitment: remainingRecruitment,
        archivedProspects: [
            prospect.id: ArchivedProspectIdentity(
                prospect: prospect,
                recruitingSeason: archivedSeason
            ),
        ]
    )
    state.competition = CompetitionReducer.rebuild(from: state)
    state.history = DomainEventLedger()
    return (state, prospect.id)
}

func runCollegeCommitmentTests() {
    suite("College commitment capacity") {
        test("projected commitment limit is the smallest class roster and scholarship opening") {
            let classLimited = projectedCapacityState(
                seed: 93_001,
                rosterOpenings: 25,
                scholarshipOpenings: 25
            )
            let scholarshipLimited = projectedCapacityState(
                seed: 93_002,
                rosterOpenings: 25,
                scholarshipOpenings: 17
            )
            let rosterLimited = projectedCapacityState(
                seed: 93_003,
                rosterOpenings: 12,
                scholarshipOpenings: 12
            )

            let classCapacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: classLimited.programmeID,
                in: classLimited.state,
                college: classLimited.state.college
            )!
            let scholarshipCapacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: scholarshipLimited.programmeID,
                in: scholarshipLimited.state,
                college: scholarshipLimited.state.college
            )!
            let rosterCapacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: rosterLimited.programmeID,
                in: rosterLimited.state,
                college: rosterLimited.state.college
            )!

            expectEqual(classCapacity.maximumReservations, 25)
            expectEqual(classCapacity.projectedRosterOpenings, 25)
            expectEqual(classCapacity.projectedScholarshipOpenings, 25)
            expectEqual(scholarshipCapacity.maximumReservations, 17)
            expectEqual(rosterCapacity.maximumReservations, 12)
        }

        test("minimum position coverage reserves the final roster opening for a walk-on") {
            var fixture = projectedCapacityState(
                seed: 93_004,
                rosterOpenings: 0,
                scholarshipOpenings: 0
            )
            let kickerID = fixture.state.programmes[fixture.programmeID]!.rosterIDs.first {
                fixture.state.players[$0]?.position == .kicker
            }!
            let existingRecruiting = fixture.state.college.programmes[fixture.programmeID]!
            var programmeStates = fixture.state.college.programmes
            programmeStates[fixture.programmeID] = ProgrammeRecruitingState(
                programmeID: fixture.programmeID,
                boardIDs: existingRecruiting.boardIDs,
                relationships: existingRecruiting.relationships,
                scholarshipPlayerIDs: Array(existingRecruiting.scholarshipPlayerIDs.dropLast())
                    + [kickerID],
                contactPointsRemaining: existingRecruiting.contactPointsRemaining,
                nilState: existingRecruiting.nilState
            )
            fixture.state.college = CollegeState(
                recruitingSeason: fixture.state.college.recruitingSeason,
                portal: fixture.state.college.portal,
                phase: fixture.state.college.phase,
                programmes: programmeStates,
                prospectRecruitment: fixture.state.college.prospectRecruitment,
                archivedProspects: fixture.state.college.archivedProspects
            )
            fixture.state.players.update(kickerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 1, yearsRemaining: 1)
            }
            let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: fixture.programmeID,
                in: fixture.state,
                college: fixture.state.college
            )!

            expectEqual(capacity.maximumReservations, 1)
            expect(!capacity.canReserve(position: .wideReceiver))
            expect(capacity.canReserve(position: .kicker))
        }

        test("AI culls and refunds an available pursuit that cannot consume reserved position capacity") {
            var fixture = kickerReservedCapacityState(seed: 93_005)
            let programmeID = fixture.programmeID
            let wideReceiverID = fixture.state.prospects.values.first {
                $0.position == .wideReceiver
            }!.id
            for action in [
                RecruitingAction.addToBoard,
                .setNILAllocation(amount: 200),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: wideReceiverID,
                        action: action
                    ),
                    in: fixture.state
                )
                fixture.state.college = transition.college
                fixture.state.scouting = transition.scouting
            }
            let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: fixture.state,
                college: fixture.state.college
            )!
            expectEqual(capacity.openReservations, 1)
            expect(!capacity.canReserve(position: .wideReceiver))
            expect(capacity.canReserve(position: .kicker))

            let transition = try CollegeRecruitingAISystem.process(in: fixture.state)
            let recruiting = transition.college.programmes[programmeID]!
            let programmeDecisions = transition.decisions.filter {
                $0.request.programmeID == programmeID
            }

            expectEqual(recruiting.relationships[wideReceiverID], nil)
            expectEqual(recruiting.nilState.recruitingReservations[wideReceiverID], nil)
            expect(programmeDecisions.first.map {
                if case .withdraw = $0.request.action { return true }
                return false
            } == true, "capacity cleanup did not precede board growth")
            expect(recruiting.boardIDs.allSatisfy { prospectID in
                fixture.state.prospects[prospectID]?.position == .kicker
            })
            expect(transition.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: programmeID,
                    prospectID: wideReceiverID,
                    action: .withdraw,
                    resourceCost: -200,
                    interestAfter: 0
                ) = payload { return true }
                return false
            })
        }

        test("AI spends nothing after refunding an illegal pursuit when no legal candidate exists") {
            var fixture = kickerReservedCapacityState(seed: 93_006)
            let programmeID = fixture.programmeID
            let wideReceiverID = fixture.state.prospects.values.first {
                $0.position == .wideReceiver
            }!.id
            for action in [
                RecruitingAction.addToBoard,
                .setNILAllocation(amount: 200),
            ] {
                let transition = try CollegeRecruitingSystem.apply(
                    RecruitingActionRequest(
                        programmeID: programmeID,
                        prospectID: wideReceiverID,
                        action: action
                    ),
                    in: fixture.state
                )
                fixture.state.college = transition.college
                fixture.state.scouting = transition.scouting
            }
            for prospect in fixture.state.prospects.values where prospect.position == .kicker {
                _ = fixture.state.prospects.remove(prospect.id)
            }
            let annualBudget = fixture.state.college.programmes[programmeID]!.nilState.annualBudget

            let transition = try CollegeRecruitingAISystem.process(in: fixture.state)
            let recruiting = transition.college.programmes[programmeID]!
            let programmeDecisions = transition.decisions.filter {
                $0.request.programmeID == programmeID
            }

            expectEqual(programmeDecisions.count, 1)
            expectEqual(recruiting.boardIDs, [])
            expectEqual(recruiting.relationships, [:])
            expectEqual(recruiting.nilState.remaining, annualBudget)
            expectEqual(recruiting.contactPointsRemaining, CollegeRules.weeklyRecruitingContactPoints)
        }

        test("AI culls a backup that becomes illegal after another commitment consumes roster slack") {
            var fixture = kickerReservedCapacityState(seed: 93_007, rosterOpenings: 2)
            fixture.state.calendar = CalendarState(
                season: fixture.state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            fixture.state.league.week = fixture.state.calendar.week
            let programmeID = fixture.programmeID
            let wideReceiverIDs = Array(fixture.state.prospects.values.filter {
                $0.position == .wideReceiver
            }.prefix(2).map(\.id))
            installOffers(
                programmeID: programmeID,
                prospectInterests: [
                    (wideReceiverIDs[0], 100),
                    (wideReceiverIDs[1], 99),
                ],
                in: &fixture.state
            )
            let market = CollegeRecruitingMarketSystem.process(
                at: fixture.state.calendar,
                in: fixture.state
            )
            expectEqual(market.commitments.count, 1)
            fixture.state.college = market.college
            let availableID = wideReceiverIDs.first {
                fixture.state.college.prospectRecruitment[$0]?.phase == .available
            }!
            let nilTransition = try CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: availableID,
                    action: .setNILAllocation(amount: 300)
                ),
                in: fixture.state
            )
            fixture.state.college = nilTransition.college
            let capacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: fixture.state,
                college: fixture.state.college
            )!
            expectEqual(capacity.openReservations, 1)
            expect(!capacity.canReserve(position: .wideReceiver))

            let transition = try CollegeRecruitingAISystem.process(in: fixture.state)
            let recruiting = transition.college.programmes[programmeID]!
            expectEqual(recruiting.relationships[availableID], nil)
            expectEqual(recruiting.nilState.recruitingReservations[availableID], nil)
            expect(transition.eventPayloads.contains { payload in
                if case .recruitingInteraction(
                    programmeID: programmeID,
                    prospectID: availableID,
                    action: .withdraw,
                    resourceCost: -300,
                    interestAfter: 0
                ) = payload { return true }
                return false
            })
        }
    }

    suite("College commitment reservations") {
        test("the market reserves the strongest legal 25 independent of board order") {
            var first = GameState.bootstrap(seed: 93_010)
            let programmeID = first.programmes.ids[0]
            setProjectedScholarshipOpenings(25, programmeID: programmeID, in: &first)
            let prospectIDs = Array(first.prospects.ids.prefix(26))
            let pursuits = prospectIDs.enumerated().map { index, prospectID in
                (prospectID, 75 + index)
            }
            installOffers(
                programmeID: programmeID,
                prospectInterests: pursuits,
                in: &first
            )
            var reversed = first
            installOffers(
                programmeID: programmeID,
                prospectInterests: pursuits,
                boardIDs: prospectIDs.reversed(),
                in: &reversed
            )
            let calendar = CalendarState(
                season: first.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )

            let firstMarket = CollegeRecruitingMarketSystem.process(at: calendar, in: first)
            let reversedMarket = CollegeRecruitingMarketSystem.process(at: calendar, in: reversed)

            expectEqual(firstMarket.commitments, reversedMarket.commitments)
            expectEqual(firstMarket.eventPayloads, reversedMarket.eventPayloads)
            expectEqual(firstMarket.commitments.count, 25)
            let committedIDs = Set(firstMarket.commitments.map(\.prospectID))
            let uncommittedID = prospectIDs.first { !committedIDs.contains($0) }!
            let uncommittedScore = contenderContext(
                programmeID: programmeID,
                prospectID: uncommittedID,
                in: first
            ).score
            expect(firstMarket.commitments.allSatisfy { $0.score >= uncommittedScore })
            expectEqual(
                firstMarket.college.prospectRecruitment.values.filter {
                    $0.programmeID == programmeID && $0.phase == .committed
                }.count,
                25
            )
            let decision = firstMarket.commitments[0]
            let relationship = first.college.programmes[programmeID]!
                .relationships[decision.prospectID]!
            expectEqual(decision.context.committedAt, calendar)
            expectEqual(decision.context.winner.relationshipInterest, relationship.interest)
            expectEqual(
                decision.context.winner.nilAllocation,
                first.college.programmes[programmeID]!.nilState
                    .recruitingReservations[decision.prospectID] ?? 0
            )
            expectEqual(decision.context.winner.visitScheduled, relationship.visitScheduled)
        }

        test("a full preferred programme falls back to the next legal contender") {
            var state = GameState.bootstrap(seed: 93_011)
            let programmeIDs = Array(state.programmes.ids.prefix(2))
            let prospectID = state.prospects.ids[0]
            for programmeID in programmeIDs {
                installOffers(
                    programmeID: programmeID,
                    prospectInterests: [(prospectID, 100)],
                    in: &state
                )
            }
            let ranked = programmeIDs.sorted {
                contenderContext(programmeID: $0, prospectID: prospectID, in: state).score
                    > contenderContext(programmeID: $1, prospectID: prospectID, in: state).score
            }
            let preferredID = ranked[0]
            let fallbackID = ranked[1]
            setProjectedScholarshipOpenings(0, programmeID: preferredID, in: &state)
            setProjectedScholarshipOpenings(1, programmeID: fallbackID, in: &state)

            let market = CollegeRecruitingMarketSystem.process(
                at: CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek),
                in: state
            )

            expectEqual(market.commitments.count, 1)
            expectEqual(market.commitments[0].programmeID, fallbackID)
            expectEqual(market.commitments[0].context.winner.programmeID, fallbackID)
            if case let .capacityFallback(blockedPreferred)
                = market.commitments[0].context.selectionReason {
                expectEqual(blockedPreferred.programmeID, preferredID)
            } else {
                expect(false, "capacity fallback did not preserve the blocked preferred offer")
            }
        }

        test("a flip moves one reservation atomically between programmes") {
            var state = GameState.bootstrap(seed: 93_012)
            let programmeIDs = Array(state.programmes.ids.prefix(2))
            let prospectID = state.prospects.ids[0]
            for programmeID in programmeIDs {
                setProjectedScholarshipOpenings(1, programmeID: programmeID, in: &state)
            }
            let originalID = programmeIDs[0]
            let targetID = programmeIDs[1]
            installOffers(
                programmeID: originalID,
                prospectInterests: [(prospectID, CollegeRules.minimumCommitmentScore)],
                in: &state
            )
            let committedAt = CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek)
            let market = CollegeRecruitingMarketSystem.process(at: committedAt, in: state)
            expectEqual(market.commitments.count, 1)
            state.college = market.college
            installOffers(
                programmeID: targetID,
                prospectInterests: [(prospectID, 100)],
                in: &state
            )
            let flipMarket = CollegeRecruitingMarketSystem.process(
                at: CalendarState(season: 0, week: committedAt.week + 1),
                in: state
            )

            expectEqual(flipMarket.commitments.count, 1)
            expectEqual(flipMarket.commitments[0].programmeID, targetID)
            expectEqual(flipMarket.commitments[0].previousProgrammeID, originalID)
            expectEqual(
                flipMarket.college.prospectRecruitment[prospectID]?.programmeID,
                targetID
            )
            expectEqual(
                flipMarket.college.prospectRecruitment[prospectID]?.commitmentHistory.count,
                2
            )
            expectEqual(
                CollegeCommitmentCapacitySystem.capacity(
                    programmeID: originalID,
                    in: state,
                    college: flipMarket.college
                )?.openReservations,
                1
            )
            expectEqual(
                CollegeCommitmentCapacitySystem.capacity(
                    programmeID: targetID,
                    in: state,
                    college: flipMarket.college
                )?.openReservations,
                0
            )
        }

        test("a flip ignores every capacity-blocked leader when choosing its runner-up") {
            var state = GameState.bootstrap(seed: 93_013)
            let programmeIDs = Array(state.programmes.ids.prefix(4))
            let incumbentID = programmeIDs[0]
            let challengerIDs = Array(programmeIDs.dropFirst())
            let prospectID = state.prospects.ids[0]
            setProjectedScholarshipOpenings(1, programmeID: incumbentID, in: &state)
            installOffers(
                programmeID: incumbentID,
                prospectInterests: [(prospectID, CollegeRules.minimumCommitmentScore)],
                in: &state
            )
            let committedAt = CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek)
            let first = CollegeRecruitingMarketSystem.process(at: committedAt, in: state)
            expectEqual(first.commitments.count, 1)
            state.college = first.college

            for programmeID in challengerIDs {
                installOffers(
                    programmeID: programmeID,
                    prospectInterests: [(prospectID, 100)],
                    in: &state
                )
            }
            let rankedChallengers = challengerIDs.sorted { lhs, rhs in
                let lhsContext = contenderContext(
                    programmeID: lhs,
                    prospectID: prospectID,
                    in: state
                )
                let rhsContext = contenderContext(
                    programmeID: rhs,
                    prospectID: prospectID,
                    in: state
                )
                if lhsContext.score != rhsContext.score {
                    return lhsContext.score > rhsContext.score
                }
                return lhs.uuidString < rhs.uuidString
            }
            for blockedID in rankedChallengers.prefix(2) {
                setProjectedScholarshipOpenings(0, programmeID: blockedID, in: &state)
            }
            let legalID = rankedChallengers[2]
            setProjectedScholarshipOpenings(1, programmeID: legalID, in: &state)

            let flip = CollegeRecruitingMarketSystem.process(
                at: CalendarState(season: 0, week: committedAt.week + 1),
                in: state
            )

            expectEqual(flip.commitments.count, 1)
            expectEqual(flip.commitments.first?.programmeID, legalID)
            expectEqual(flip.commitments.first?.runnerUpProgrammeID, nil)
            expectEqual(flip.commitments.first?.previousProgrammeID, incumbentID)
        }

        test("the public reservation path rejects a backdated commitment") {
            var state = GameState.bootstrap(seed: 93_014)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            setProjectedScholarshipOpenings(1, programmeID: programmeID, in: &state)
            installOffers(
                programmeID: programmeID,
                prospectInterests: [(prospectID, 100)],
                in: &state
            )
            let context = RecruitingCommitmentContext(
                committedAt: CalendarState(
                    season: state.college.recruitingSeason,
                    week: CollegeRules.minimumCommitmentWeek - 1
                ),
                winner: contenderContext(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    in: state
                )
            )

            var college = state.college
            expect(!CollegeCommitmentSystem.reserve(
                prospectID: prospectID,
                context: context,
                in: state,
                college: &college
            ))
            expectEqual(college.prospectRecruitment[prospectID]?.phase, .available)
        }
    }

    suite("College commitment signing") {
        test("signing resolves every commitment and preserves durable recruiting context") {
            let fixture = signingFixture(
                seed: 93_020,
                commitments: 2,
                actualOpenings: 2
            )
            let transition = try CollegeSigningSystem.signCommitted(in: fixture.state)

            expectEqual(transition.resolutions.count, 2)
            expectEqual(transition.signings.count, 2)
            expect(transition.resolutions.allSatisfy { $0.outcome == .signed })
            expectEqual(
                Set(transition.resolutions.map(\.prospectID)),
                Set(fixture.prospectIDs)
            )
            let resolutionPayloads = transition.eventPayloads.compactMap {
                payload -> CommitmentTerminalOutcome? in
                guard case let .commitmentResolved(_, _, outcome) = payload else { return nil }
                return outcome
            }
            expectEqual(resolutionPayloads, [.signed, .signed])

            for prospectID in fixture.prospectIDs {
                let prospect = fixture.state.prospects[prospectID]!
                let recruitment = fixture.state.college.prospectRecruitment[prospectID]!
                let origin = transition.people.playerCareers[prospectID]!.recruitingOrigin!
                let relationship = fixture.state.college.programmes[fixture.programmeID]!
                    .relationships[prospectID]!
                expectEqual(origin.commitmentHistory, recruitment.commitmentHistory)
                expectEqual(origin.committedAt, recruitment.commitmentContext!.committedAt)
                expectEqual(origin.signedAt, fixture.state.calendar)
                expectEqual(origin.programmeID, fixture.programmeID)
                expectEqual(origin.finalInterest, relationship.interest)
                expectEqual(
                    origin.finalNILAllocation,
                    fixture.state.college.programmes[fixture.programmeID]!.nilState
                        .recruitingReservations[prospectID] ?? 0
                )
                expectEqual(origin.overallAtSigning, prospect.overall)
                expectEqual(origin.recruitingPriorities, prospect.priorities)
            }
        }

        test("a capacity change releases the remainder explicitly with terminal conservation") {
            let fixture = signingFixture(
                seed: 93_021,
                commitments: 2,
                actualOpenings: 1
            )
            let transition = try CollegeSigningSystem.signCommitted(in: fixture.state)
            let signed = transition.resolutions.filter { $0.outcome == .signed }
            let released = transition.resolutions.filter {
                $0.outcome == .released(reason: .scholarshipCapacityChanged)
            }

            expectEqual(transition.resolutions.count, 2)
            expectEqual(signed.count, 1)
            expectEqual(released.count, 1)
            expectEqual(
                Set(signed.map(\.prospectID)).union(released.map(\.prospectID)),
                Set(fixture.prospectIDs)
            )
            expect(Set(signed.map(\.prospectID)).isDisjoint(with: released.map(\.prospectID)))
            expectEqual(
                transition.college.prospectRecruitment.values.filter {
                    fixture.prospectIDs.contains($0.prospectID) && $0.phase == .committed
                }.count,
                0
            )
            expectEqual(
                transition.eventPayloads.filter {
                    if case .commitmentResolved = $0 { return true }
                    return false
                }.count,
                2
            )
        }
    }

    suite("College commitment integrity") {
        test("event history rejects calendar regression during append and decode") {
            let firstCalendar = CalendarState(season: 0, week: 5)
            let secondCalendar = CalendarState(season: 0, week: 6)
            var appendLedger = DomainEventLedger()
            expect(appendLedger.append(DomainEvent(
                id: DomainEvent.deterministicID(rootSeed: 93_040, sequence: 0),
                sequence: 0,
                occurredAt: firstCalendar,
                payload: .integrityChecked(issueCount: 0)
            )))
            expect(!appendLedger.append(DomainEvent(
                id: DomainEvent.deterministicID(rootSeed: 93_040, sequence: 1),
                sequence: 1,
                occurredAt: CalendarState(season: 0, week: 4),
                payload: .integrityChecked(issueCount: 0)
            )), "the ledger appended an event before its latest retained calendar")

            var decodedLedger = DomainEventLedger()
            expect(decodedLedger.append(DomainEvent(
                id: DomainEvent.deterministicID(rootSeed: 93_041, sequence: 0),
                sequence: 0,
                occurredAt: firstCalendar,
                payload: .integrityChecked(issueCount: 0)
            )))
            expect(decodedLedger.append(DomainEvent(
                id: DomainEvent.deterministicID(rootSeed: 93_041, sequence: 1),
                sequence: 1,
                occurredAt: secondCalendar,
                payload: .integrityChecked(issueCount: 0)
            )))
            var ledgerObject = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(decodedLedger)
            ) as! [String: Any]
            var recent = ledgerObject["recent"] as! [Any]
            var secondEvent = recent[1] as! [String: Any]
            var occurredAt = secondEvent["occurredAt"] as! [String: Any]
            occurredAt["week"] = 4
            secondEvent["occurredAt"] = occurredAt
            recent[1] = secondEvent
            ledgerObject["recent"] = recent
            do {
                _ = try JSONDecoder().decode(
                    DomainEventLedger.self,
                    from: JSONSerialization.data(withJSONObject: ledgerObject)
                )
                expect(false, "a calendar-regressing event ledger decoded")
            } catch {
                expect(true)
            }
        }

        test("stable commitment snapshots match the final offered relationship") {
            let fixture = committedIntegrityFixture(seed: 93_042)
            expect(WorldIntegrity.check(fixture.state).isValid)

            let offerMismatch = replacingFinalRelationship(
                in: fixture.state,
                programmeID: fixture.programmeID,
                prospectID: fixture.prospectID
            ) { $0.scholarshipOffered = false }
            let interestMismatch = replacingFinalRelationship(
                in: fixture.state,
                programmeID: fixture.programmeID,
                prospectID: fixture.prospectID
            ) { $0.interest = 99 }
            let nilMismatch = replacingFinalNILReservation(
                in: fixture.state,
                programmeID: fixture.programmeID,
                prospectID: fixture.prospectID,
                amount: 100
            )
            let visitMismatch = replacingFinalRelationship(
                in: fixture.state,
                programmeID: fixture.programmeID,
                prospectID: fixture.prospectID
            ) { $0.visitScheduled.toggle() }

            for (label, state) in [
                ("offer", offerMismatch),
                ("interest", interestMismatch),
                ("NIL", nilMismatch),
                ("visit", visitMismatch),
            ] {
                expect(
                    WorldIntegrity.check(state).issues.contains(
                        .invalidProspect(prospectID: fixture.prospectID)
                    ),
                    "a final \(label) snapshot mismatch passed root integrity"
                )
            }
        }

        test("stable roots reject inactive cycles and terminal active-prospect phases") {
            var inactive = GameState.bootstrap(seed: 93_043)
            inactive.college = CollegeState(
                recruitingSeason: inactive.college.recruitingSeason,
                portal: inactive.college.portal,
                phase: .closed,
                programmes: inactive.college.programmes,
                prospectRecruitment: inactive.college.prospectRecruitment,
                archivedProspects: inactive.college.archivedProspects
            )
            expect(!WorldIntegrity.check(inactive).isValid, "a closed stable cycle passed integrity")

            let fixture = committedIntegrityFixture(seed: 93_044)
            for phase in [ProspectRecruitmentPhase.signed, .released] {
                var terminal = fixture.state
                var recruitment = terminal.college.prospectRecruitment
                recruitment[fixture.prospectID] = ProspectRecruitmentState(
                    prospectID: fixture.prospectID,
                    phase: phase,
                    commitmentHistory: [fixture.context],
                    releaseReason: phase == .released ? .rosterCapacityChanged : nil
                )
                terminal.college = CollegeState(
                    recruitingSeason: terminal.college.recruitingSeason,
                    portal: terminal.college.portal,
                    phase: .active,
                    programmes: terminal.college.programmes,
                    prospectRecruitment: recruitment,
                    archivedProspects: terminal.college.archivedProspects
                )
                expect(
                    WorldIntegrity.check(terminal).issues.contains(
                        .invalidProspect(prospectID: fixture.prospectID)
                    ),
                    "a \(phase.rawValue) active prospect passed stable-root integrity"
                )
            }
        }

        test("programme NIL annual budget remains bound to programme resources") {
            var state = GameState.bootstrap(seed: 93_045)
            let programmeID = state.programmes.ids[0]
            let existing = state.college.programmes[programmeID]!
            var programmes = state.college.programmes
            programmes[programmeID] = ProgrammeRecruitingState(
                programmeID: programmeID,
                boardIDs: existing.boardIDs,
                relationships: existing.relationships,
                scholarshipPlayerIDs: existing.scholarshipPlayerIDs,
                contactPointsRemaining: existing.contactPointsRemaining,
                nilState: ProgrammeNILState(
                    programmeID: programmeID,
                    season: existing.nilState.season,
                    annualBudget: existing.nilState.annualBudget - 100,
                    rosterAllocations: existing.nilState.rosterAllocations
                )
            )
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                phase: .active,
                programmes: programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects
            )

            expect(
                WorldIntegrity.check(state).issues.contains(
                    .invalidProgrammeRecruitingState(programmeID: programmeID)
                ),
                "an over-promised NIL budget passed root integrity"
            )
        }

        test("retained events cannot occur after the authoritative root calendar") {
            var state = GameState.bootstrap(seed: 93_046)
            state.calendar = CalendarState(season: 0, week: 4)
            state.league.week = state.calendar.week
            let futureEvent = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: state.league.seed,
                    sequence: state.history.nextSequence
                ),
                sequence: state.history.nextSequence,
                occurredAt: CalendarState(season: 0, week: 5),
                payload: .integrityChecked(issueCount: 0)
            )
            expect(state.history.append(futureEvent))

            expect(
                WorldIntegrity.check(state).issues.contains(
                    .invalidHistoricalEvent(eventID: futureEvent.id)
                )
            )
        }

        test("active prospect commitment events bind to recruitment history") {
            let fixture = committedIntegrityFixture(seed: 93_047)
            let event = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: fixture.state.league.seed,
                    sequence: fixture.state.history.nextSequence
                ),
                sequence: fixture.state.history.nextSequence,
                occurredAt: fixture.context.committedAt,
                payload: .prospectCommitted(
                    prospectID: fixture.prospectID,
                    context: fixture.context
                )
            )
            var matching = fixture.state
            expect(matching.history.append(event))
            expect(WorldIntegrity.check(matching).isValid)

            var unbound = fixture.state
            var recruitment = unbound.college.prospectRecruitment
            recruitment[fixture.prospectID] = ProspectRecruitmentState(
                prospectID: fixture.prospectID,
                phase: .available
            )
            unbound.college = CollegeState(
                recruitingSeason: unbound.college.recruitingSeason,
                portal: unbound.college.portal,
                phase: .active,
                programmes: unbound.college.programmes,
                prospectRecruitment: recruitment,
                archivedProspects: unbound.college.archivedProspects
            )
            expect(unbound.history.append(event))
            expect(
                WorldIntegrity.check(unbound).issues.contains(
                    .invalidHistoricalEvent(eventID: event.id)
                ),
                "an unbound active-prospect commitment event passed integrity"
            )
        }

        test("signed prospect commitment events bind to recruiting-origin history") {
            var state = GameState.bootstrap(seed: 93_048)
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            state.league.week = state.calendar.week
            let programme = state.programmes.values[0]
            let playerID = programme.rosterIDs[0]
            let player = state.players[playerID]!
            let context = RecruitingCommitmentContext(
                committedAt: state.calendar,
                winner: RecruitingCommitmentContenderContext(
                    programmeID: programme.id,
                    score: CollegeRules.minimumCommitmentScore,
                    explanation: [],
                    relationshipInterest: CollegeRules.minimumCommitmentScore,
                    nilAllocation: 0,
                    visitScheduled: false
                )
            )
            let existingCareer = state.people.playerCareers[playerID]!
            let origin = PlayerRecruitingOrigin(
                originCityID: state.map.cities[0].id,
                commitmentHistory: [context],
                signedAt: state.calendar,
                finalInterest: context.winner.relationshipInterest,
                finalNILAllocation: context.winner.nilAllocation,
                overallAtSigning: player.overall,
                recruitingPriorities: state.prospects.values[0].priorities
            )
            let replacementCareer = PlayerCareerRecord(
                playerID: playerID,
                recruitingOrigin: origin,
                seasons: existingCareer.seasons,
                portalWindows: existingCareer.portalWindows,
                endedAt: existingCareer.endedAt,
                endStatus: existingCareer.endStatus
            )
            state.people = PeopleState(
                playerLifecycle: Array(state.people.playerLifecycle.values),
                playerCareers: state.people.playerCareers.values.map {
                    $0.playerID == playerID ? replacementCareer : $0
                },
                staffCareers: Array(state.people.staffCareers.values),
                departedPlayers: Array(state.people.departedPlayers.values)
            )

            var matching = state
            let matchingEvent = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: state.league.seed,
                    sequence: matching.history.nextSequence
                ),
                sequence: matching.history.nextSequence,
                occurredAt: context.committedAt,
                payload: .prospectCommitted(prospectID: playerID, context: context)
            )
            expect(matching.history.append(matchingEvent))
            expect(WorldIntegrity.check(matching).isValid)

            let forgedContext = RecruitingCommitmentContext(
                committedAt: context.committedAt,
                winner: RecruitingCommitmentContenderContext(
                    programmeID: programme.id,
                    score: CollegeRules.minimumCommitmentScore,
                    explanation: [],
                    relationshipInterest: CollegeRules.minimumCommitmentScore,
                    nilAllocation: 0,
                    visitScheduled: true
                )
            )
            var forged = state
            let forgedEvent = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: state.league.seed,
                    sequence: forged.history.nextSequence
                ),
                sequence: forged.history.nextSequence,
                occurredAt: forgedContext.committedAt,
                payload: .prospectCommitted(prospectID: playerID, context: forgedContext)
            )
            expect(forged.history.append(forgedEvent))
            expect(
                WorldIntegrity.check(forged).issues.contains(
                    .invalidHistoricalEvent(eventID: forgedEvent.id)
                ),
                "a commitment absent from the player's recruiting origin passed integrity"
            )
        }

        test("archived commitment and release events bind to the recruiting season") {
            let eventCalendar = CalendarState(
                season: 1,
                week: SharedRules.inSeasonWeeks
            )
            func context(programmeID: UUID) -> RecruitingCommitmentContext {
                RecruitingCommitmentContext(
                    committedAt: eventCalendar,
                    winner: RecruitingCommitmentContenderContext(
                        programmeID: programmeID,
                        score: CollegeRules.minimumCommitmentScore,
                        explanation: [],
                        relationshipInterest: CollegeRules.minimumCommitmentScore,
                        nilAllocation: 0,
                        visitScheduled: false
                    )
                )
            }
            func appendingArchiveEvents(
                to fixture: (state: GameState, prospectID: UUID)
            ) -> (state: GameState, eventIDs: [UUID]) {
                var state = fixture.state
                let programmeID = state.programmes.ids[0]
                let payloads: [DomainEventPayload] = [
                    .prospectCommitted(
                        prospectID: fixture.prospectID,
                        context: context(programmeID: programmeID)
                    ),
                    .commitmentResolved(
                        prospectID: fixture.prospectID,
                        programmeID: programmeID,
                        outcome: .released(reason: .rosterCapacityChanged)
                    ),
                ]
                var eventIDs: [UUID] = []
                for payload in payloads {
                    let event = DomainEvent(
                        id: DomainEvent.deterministicID(
                            rootSeed: state.league.seed,
                            sequence: state.history.nextSequence
                        ),
                        sequence: state.history.nextSequence,
                        occurredAt: eventCalendar,
                        payload: payload
                    )
                    expect(state.history.append(event))
                    eventIDs.append(event.id)
                }
                return (state, eventIDs)
            }

            let matching = appendingArchiveEvents(to: archivedProspectRoot(
                seed: 93_049,
                currentSeason: 2,
                archivedSeason: eventCalendar.season
            ))
            let matchingIssues = WorldIntegrity.check(matching.state).issues
            expect(
                matchingIssues.isEmpty,
                "same-season archived events broke integrity: \(matchingIssues)"
            )

            let wrongSeason = appendingArchiveEvents(to: archivedProspectRoot(
                seed: 93_050,
                currentSeason: 2,
                archivedSeason: 0
            ))
            let issues = WorldIntegrity.check(wrongSeason.state).issues
            expect(wrongSeason.eventIDs.allSatisfy { eventID in
                issues.contains(.invalidHistoricalEvent(eventID: eventID))
            }, "archive events from the wrong recruiting season passed integrity")
        }

        test("hostile saves cannot reorder explanations or exceed commitment bounds") {
            let programmeIDs = [
                UUID(uuidString: "00000000-0000-4000-8000-000000009301")!,
                UUID(uuidString: "00000000-0000-4000-8000-000000009302")!,
            ]
            let contender = RecruitingCommitmentContenderContext(
                programmeID: programmeIDs[0],
                score: 63,
                explanation: [
                    RecruitingScoreComponent(reason: .prestige, value: 2),
                    RecruitingScoreComponent(reason: .proximity, value: 1),
                ],
                relationshipInterest: 60,
                nilAllocation: 0,
                visitScheduled: false
            )
            var contenderObject = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(contender)
            ) as! [String: Any]
            contenderObject["explanation"] = Array(
                (contenderObject["explanation"] as! [Any]).reversed()
            )
            do {
                _ = try JSONDecoder().decode(
                    RecruitingCommitmentContenderContext.self,
                    from: JSONSerialization.data(withJSONObject: contenderObject)
                )
                expect(false, "a noncanonical commitment explanation decoded")
            } catch {
                expect(true)
            }

            func scoreContext(
                programmeID: UUID,
                score: Int
            ) -> RecruitingCommitmentContenderContext {
                RecruitingCommitmentContenderContext(
                    programmeID: programmeID,
                    score: score,
                    explanation: [],
                    relationshipInterest: score,
                    nilAllocation: 0,
                    visitScheduled: false
                )
            }
            let contexts = (0..<5).map { index -> RecruitingCommitmentContext in
                let winnerID = programmeIDs[index % 2]
                let winnerScore = CollegeRules.minimumCommitmentScore + index * 10
                return RecruitingCommitmentContext(
                    committedAt: CalendarState(
                        season: 0,
                        week: CollegeRules.minimumCommitmentWeek + index
                    ),
                    winner: scoreContext(programmeID: winnerID, score: winnerScore),
                    previousWinner: index == 0 ? nil : scoreContext(
                        programmeID: programmeIDs[(index - 1) % 2],
                        score: winnerScore - 10
                    )
                )
            }
            let bounded = ProspectRecruitmentState(
                prospectID: UUID(uuidString: "00000000-0000-4000-8000-000000009303")!,
                phase: .committed,
                commitmentHistory: Array(contexts.prefix(4))
            )
            var recruitmentObject = try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(bounded)
            ) as! [String: Any]
            var history = recruitmentObject["commitmentHistory"] as! [Any]
            history.append(try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(contexts[4])
            ))
            recruitmentObject["commitmentHistory"] = history
            do {
                _ = try JSONDecoder().decode(
                    ProspectRecruitmentState.self,
                    from: JSONSerialization.data(withJSONObject: recruitmentObject)
                )
                expect(false, "a fifth commitment history entry decoded")
            } catch {
                expect(true)
            }

            var state = GameState.bootstrap(seed: 93_035)
            let programmeID = state.programmes.ids[0]
            let context = RecruitingCommitmentContext(
                committedAt: CalendarState(
                    season: state.college.recruitingSeason,
                    week: CollegeRules.minimumCommitmentWeek
                ),
                winner: scoreContext(
                    programmeID: programmeID,
                    score: CollegeRules.minimumCommitmentScore
                )
            )
            var recruitment = state.college.prospectRecruitment
            for prospectID in state.prospects.ids.prefix(26) {
                recruitment[prospectID] = ProspectRecruitmentState(
                    prospectID: prospectID,
                    phase: .committed,
                    commitmentHistory: [context]
                )
            }
            state.college = CollegeState(
                recruitingSeason: state.college.recruitingSeason,
                portal: state.college.portal,
                programmes: state.college.programmes,
                prospectRecruitment: recruitment,
                archivedProspects: state.college.archivedProspects
            )
            do {
                _ = try JSONDecoder().decode(
                    CollegeState.self,
                    from: JSONEncoder().encode(state.college)
                )
                expect(false, "a 26th active class reservation decoded")
            } catch {
                expect(true)
            }
        }

        test("a stable root rejects a recruiting cycle from a different season") {
            var state = GameState.bootstrap(seed: 93_030)
            state.college = CollegeState(
                recruitingSeason: state.calendar.season + 1,
                portal: CollegePortalState(targetSeason: state.calendar.season + 1),
                phase: state.college.phase,
                programmes: state.college.programmes,
                prospectRecruitment: state.college.prospectRecruitment,
                archivedProspects: state.college.archivedProspects
            )

            expect(WorldIntegrity.check(state).issues.contains(.calendarDisagreement))
        }

        test("departed player recruiting origins retain valid world references") {
            var state = GameState.bootstrap(seed: 93_031)
            state.calendar = CalendarState(
                season: state.calendar.season,
                week: CollegeRules.minimumCommitmentWeek
            )
            state.league.week = state.calendar.week
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            let player = state.players[playerID]!
            let origin = PlayerRecruitingOrigin(
                originCityID: UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFF1")!,
                commitmentHistory: [RecruitingCommitmentContext(
                    committedAt: state.calendar,
                    winner: RecruitingCommitmentContenderContext(
                        programmeID: programmeID,
                        score: CollegeRules.minimumCommitmentScore,
                        explanation: [],
                        relationshipInterest: CollegeRules.minimumCommitmentScore,
                        nilAllocation: 0,
                        visitScheduled: false
                    )
                )],
                signedAt: state.calendar,
                finalInterest: CollegeRules.minimumCommitmentScore,
                finalNILAllocation: 0,
                overallAtSigning: player.overall,
                recruitingPriorities: state.prospects.values[0].priorities
            )
            let endedCareer = PlayerCareerRecord(
                playerID: playerID,
                recruitingOrigin: origin,
                portalWindows: state.people.playerCareers[playerID]!.portalWindows,
                endedAt: state.calendar,
                endStatus: .graduated
            )
            state.people = PeopleState(
                playerLifecycle: state.people.playerLifecycle.values.filter {
                    $0.playerID != playerID
                },
                playerCareers: state.people.playerCareers.values.map {
                    $0.playerID == playerID ? endedCareer : $0
                },
                staffCareers: Array(state.people.staffCareers.values),
                departedPlayers: Array(state.people.departedPlayers.values)
                    + [DepartedPlayerIdentity(player: player, status: .graduated)]
            )
            state.players.remove(playerID)
            state.programmes.update(programmeID) {
                $0.rosterIDs.removeAll { $0 == playerID }
                $0.scholarshipCount = max(0, $0.scholarshipCount - 1)
            }
            state.college.reconcileScholarships(with: state.programmes)

            expect(WorldIntegrity.check(state).issues.contains { issue in
                if case .invalidPlayerCareer(playerID: playerID) = issue { return true }
                return false
            })
        }

        test("retained commitment events must use their commitment calendar") {
            var state = GameState.bootstrap(seed: 93_032)
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            installOffers(
                programmeID: programmeID,
                prospectInterests: [(prospectID, 100)],
                in: &state
            )
            let context = RecruitingCommitmentContext(
                committedAt: CalendarState(season: 0, week: CollegeRules.minimumCommitmentWeek),
                winner: contenderContext(
                    programmeID: programmeID,
                    prospectID: prospectID,
                    in: state
                )
            )
            state.calendar = CalendarState(season: 0, week: context.committedAt.week + 1)
            state.league.week = state.calendar.week
            let event = DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: state.league.seed,
                    sequence: state.history.nextSequence
                ),
                sequence: state.history.nextSequence,
                occurredAt: state.calendar,
                payload: .prospectCommitted(prospectID: prospectID, context: context)
            )
            expect(state.history.append(event))

            expect(!WorldIntegrity.check(state).isValid)
        }

        test("commitment resolution events conserve the terminal identity category") {
            for outcome in [
                CommitmentTerminalOutcome.signed,
                .released(reason: .scholarshipCapacityChanged),
            ] {
                var state = GameState.bootstrap(seed: 93_033)
                let prospectID = state.prospects.ids[0]
                let programmeID = state.programmes.ids[0]
                let event = DomainEvent(
                    id: DomainEvent.deterministicID(
                        rootSeed: state.league.seed,
                        sequence: state.history.nextSequence
                    ),
                    sequence: state.history.nextSequence,
                    occurredAt: state.calendar,
                    payload: .commitmentResolved(
                        prospectID: prospectID,
                        programmeID: programmeID,
                        outcome: outcome
                    )
                )
                expect(state.history.append(event))
                expect(!WorldIntegrity.check(state).isValid)
            }
        }
    }
}
