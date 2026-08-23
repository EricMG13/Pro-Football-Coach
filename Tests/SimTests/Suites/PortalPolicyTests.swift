import Foundation
import FootballSimCore

private func portalPolicyUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-4000-8007-%012X", value))!
}

private struct PortalPolicyFixture {
    var state: GameState
    let playerID: UUID
    let sourceProgrammeID: UUID
    let observerProgrammeID: UUID
}

private func portalPolicyFixture(
    sourceRank: Int = 101,
    sourceRosterNIL: Int = 100,
    games: Int = 8,
    starts: Int = 5,
    isRestless: Bool = false
) -> PortalPolicyFixture {
    precondition((1...CollegeRules.programmeCount).contains(sourceRank))
    var state = GameState.bootstrap(seed: 95_001)
    let sourceID = state.programmes.ids[0]
    let observerID = state.programmes.ids[1]
    let playerID = state.programmes[sourceID]!.rosterIDs[0]
    _ = state.players.update(playerID) { player in
        player.position = .quarterback
        if isRestless {
            player.add(.restless)
        } else {
            player.remove(.restless)
        }
    }
    expect(state.people.updatePlayerCareer(playerID) { career in
        expect(career.append(PlayerCareerSeason(
            season: 0,
            organisationID: sourceID,
            tier: .college,
            games: games,
            starts: starts,
            overallAtEnd: Rating(70)
        )))
    })

    var ranking = state.programmes.ids.filter { $0 != sourceID }
    ranking.insert(sourceID, at: sourceRank - 1)
    state.competition.appendArchive(SeasonArchive(
        season: 0,
        collegeChampionID: ranking[0],
        proChampionID: state.proTeams.ids[0],
        finalCollegeRanking: ranking,
        finalProRanking: state.proTeams.ids,
        awards: [],
        gamesPlayed: 0,
        totalPoints: 0
    ))

    let programmeStates = Dictionary(uniqueKeysWithValues: state.programmes.values.map {
        programme -> (UUID, ProgrammeRecruitingState) in
        let allocations = programme.id == sourceID && sourceRosterNIL > 0
            ? [playerID: sourceRosterNIL]
            : [:]
        return (
            programme.id,
            ProgrammeRecruitingState(
                programmeID: programme.id,
                scholarshipPlayerIDs: Array(
                    programme.rosterIDs.prefix(CollegeRules.scholarshipLimit)
                ),
                nilState: ProgrammeNILState(
                    programmeID: programme.id,
                    season: 1,
                    annualBudget: programme.resources.value
                        * CollegeRules.nilBudgetPerResourcePoint,
                    rosterAllocations: allocations
                )
            )
        )
    })
    state.college = CollegeState(
        recruitingSeason: 1,
        portal: CollegePortalState(targetSeason: 1),
        programmes: programmeStates
    )
    state.calendar = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
    state.league.season = 0
    state.league.week = SharedRules.inSeasonWeeks
    return PortalPolicyFixture(
        state: state,
        playerID: playerID,
        sourceProgrammeID: sourceID,
        observerProgrammeID: observerID
    )
}

private func portalPolicySnapshot(
    _ state: GameState,
    window: CollegePortalWindow = .postseason
) -> CollegePortalPolicySnapshot {
    CollegePortalPolicyV1.makeSnapshot(
        targetSeason: 1,
        window: window,
        in: state
    )!
}

private func portalPolicyKnowledge(
    copying snapshot: CollegePortalKnowledgeSnapshot,
    playerID: UUID,
    observerProgrammeID: UUID? = nil,
    targetSeason: Int? = nil,
    window: CollegePortalWindow? = nil,
    estimatedPotential: Rating? = nil
) -> CollegePortalKnowledgeSnapshot {
    let target = targetSeason ?? snapshot.targetSeason
    let selectedWindow = window ?? snapshot.window
    return CollegePortalKnowledgeSnapshot(
        observerProgrammeID: observerProgrammeID ?? snapshot.observerProgrammeID,
        playerID: playerID,
        sourceProgrammeID: snapshot.sourceProgrammeID,
        targetSeason: target,
        window: selectedWindow,
        position: snapshot.position,
        estimatedOverall: snapshot.estimatedOverall,
        estimatedAttributes: snapshot.estimatedAttributes,
        estimatedPotential: estimatedPotential ?? snapshot.estimatedPotential,
        confidence: snapshot.confidence,
        lastUpdated: selectedWindow == .postseason
            ? CalendarState(season: target - 1, week: SharedRules.inSeasonWeeks)
            : CalendarState(season: target, week: 1),
        evidenceCount: snapshot.evidenceCount
    )
}

func runPortalPolicyTests() {
    if ProcessInfo.processInfo.environment["INVALID_EMPTY_PORTAL_OBSERVER_PROBE"] != nil {
        _ = ScoutingState(portalKnowledgeByObserver: [portalPolicyUUID(99_001): []])
        return
    }

    let base = portalPolicyFixture()

    suite("College portal policy v1") {
        test("intent evidence rederives the frozen six-component v1 explanation") {
            let batch = portalPolicySnapshot(base.state)
            let intents = batch.intents

            expectEqual(intents.count, 1)
            expectEqual(batch.targetSeason, 1)
            expectEqual(batch.window, .postseason)
            expectEqual(batch.evaluatedAt, base.state.calendar)
            let intent = intents[0]
            expectEqual(intent.playerID, base.playerID)
            expectEqual(intent.evidence.position, .quarterback)
            expectEqual(intent.components.map(\.reason), CollegePortalIntentReason.allCases)
            expectEqual(intent.components.map(\.value), [7, 15, -1, -1, 5, 0])
            expectEqual(intent.total, 25)
            expectEqual(intent.selectionThreshold, 25)

            let data = try JSONEncoder.stable().encode(intent)
            var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var components = object["components"] as! [[String: Any]]
            components[0]["value"] = 8
            object["components"] = components
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalIntentExplanation.self,
                    from: JSONSerialization.data(withJSONObject: object)
                )
                expect(false, "a formula-drifted v1 intent decoded")
            } catch {
                expect(true)
            }
        }

        test("intent eligibility excludes new signees exhausted players and duplicate owners") {
            var newSignee = base.state
            let newID = portalPolicyUUID(10)
            let template = newSignee.players[base.playerID]!
            newSignee.players.insert(Player(
                id: newID,
                firstName: template.firstName,
                lastName: template.lastName,
                position: template.position,
                age: template.age,
                attributes: template.attributes,
                potential: template.potential,
                eligibility: Eligibility()
            ))
            newSignee.people.insert(player: newSignee.players[newID]!)
            _ = newSignee.programmes.update(base.sourceProgrammeID) {
                $0.rosterIDs.append(newID)
            }
            expectEqual(
                portalPolicySnapshot(newSignee).intents.map(\.playerID),
                [base.playerID]
            )

            var exhausted = base.state
            _ = exhausted.players.update(base.playerID) {
                $0.eligibility = Eligibility(seasonsRemaining: 0, yearsRemaining: 0)
            }
            expect(portalPolicySnapshot(exhausted).intents.isEmpty)

            var duplicate = base.state
            _ = duplicate.programmes.update(base.observerProgrammeID) {
                $0.rosterIDs.append(base.playerID)
            }
            expect(portalPolicySnapshot(duplicate).intents.isEmpty)
        }

        test("intent selection is total-descending UUID-stable and capped at 300") {
            var state = base.state
            var eligibleCount = 0
            candidatePopulation: for programme in state.programmes.values {
                for playerID in programme.rosterIDs {
                    guard state.players[playerID]?.position == .quarterback else { continue }
                    _ = state.players.update(playerID) { $0.add(.restless) }
                    expect(state.people.updatePlayerCareer(playerID) { career in
                        if !career.seasons.contains(where: { $0.season == 0 }) {
                            expect(career.append(PlayerCareerSeason(
                                season: 0,
                                organisationID: programme.id,
                                tier: .college,
                                games: 0,
                                starts: 0,
                                overallAtEnd: Rating(70)
                            )))
                        }
                    })
                    eligibleCount += 1
                    if eligibleCount == CollegePortalPolicyV1.maximumEntrants + 1 {
                        break candidatePopulation
                    }
                }
            }
            expectEqual(eligibleCount, CollegePortalPolicyV1.maximumEntrants + 1)
            let first = portalPolicySnapshot(state).intents
            let second = portalPolicySnapshot(state).intents

            expectEqual(first, second)
            expectEqual(first.count, CollegePortalPolicyV1.maximumEntrants)
            expect(zip(first, first.dropFirst()).allSatisfy { lhs, rhs in
                lhs.total > rhs.total
                    || (lhs.total == rhs.total
                        && lhs.playerID.uuidString < rhs.playerID.uuidString)
            })
        }

        test("portal knowledge is deterministic observer-scoped and uses the exact v1 bounds") {
            let batch = portalPolicySnapshot(base.state)
            let intent = batch.intents[0]
            let first = CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: intent.playerID,
                using: batch
            )!
            let second = CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: intent.playerID,
                using: batch
            )!
            let observer = base.state.programmes[base.observerProgrammeID]!
            let ratings = observer.staffIDs.compactMap {
                base.state.staff[$0]?.rating(.recruiting).value
            }
            let staffAverage = ratings.isEmpty
                ? SharedRules.ratingRange.lowerBound
                : ratings.reduce(0, +) / ratings.count
            let expectedConfidence = min(
                95,
                25 + (staffAverage - 40) * 20 / 59 + min(20, intent.evidence.appearances)
            )
            let expectedEvidence = min(
                CollegePortalPolicyV1.maximumScoutingEvidence,
                intent.evidence.appearances + max(1, staffAverage / 20)
            )

            expectEqual(first, second)
            expectEqual(first.confidence, expectedConfidence)
            expectEqual(first.evidenceCount, expectedEvidence)
            expectEqual(
                Set(first.estimatedAttributes.keys),
                Set(CollegePortalPolicyV1.ratedAttributes(for: first.position))
            )
            expectEqual(
                first.estimatedOverall.value,
                first.estimatedAttributes.values.reduce(0) { $0 + $1.value }
                    / first.estimatedAttributes.count
            )

            var scouting = ScoutingState()
            expect(scouting.recordPortalKnowledge(first))
            expectEqual(scouting.portalKnowledge(
                observerProgrammeID: base.observerProgrammeID,
                playerID: base.playerID,
                sourceProgrammeID: base.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason
            ), first)
        }

        test("portal knowledge encoding is order-independent and enforces pool and season slices") {
            let batch = portalPolicySnapshot(base.state)
            let intent = batch.intents[0]
            let seed = CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: intent.playerID,
                using: batch
            )!
            let snapshots = (0..<CollegePortalPolicyV1.maximumKnowledgePerObserverWindow).map {
                portalPolicyKnowledge(copying: seed, playerID: portalPolicyUUID(2_000 + $0))
            }
            var ascending = ScoutingState()
            var descending = ScoutingState()
            expect(ascending.recordPortalKnowledgeBatch(
                snapshots,
                targetSeason: 1,
                window: .postseason
            ))
            expect(descending.recordPortalKnowledgeBatch(
                snapshots.reversed(),
                targetSeason: 1,
                window: .postseason
            ))
            expectEqual(
                try JSONEncoder.stable().encode(ascending),
                try JSONEncoder.stable().encode(descending)
            )

            let beforeOverflow = try JSONEncoder.stable().encode(ascending)
            expect(!ascending.recordPortalKnowledge(portalPolicyKnowledge(
                copying: seed,
                playerID: portalPolicyUUID(9_999)
            )))
            expectEqual(try JSONEncoder.stable().encode(ascending), beforeOverflow)

            let changedPotential = Rating(
                seed.estimatedPotential.value == 99
                    ? seed.estimatedPotential.value - 1
                    : seed.estimatedPotential.value + 1
            )
            var immutable = ScoutingState()
            expect(immutable.recordPortalKnowledge(seed))
            let beforeOverwrite = try JSONEncoder.stable().encode(immutable)
            expect(!immutable.recordPortalKnowledge(portalPolicyKnowledge(
                copying: seed,
                playerID: seed.playerID,
                estimatedPotential: changedPotential
            )))
            expectEqual(try JSONEncoder.stable().encode(immutable), beforeOverwrite)

            var atomicBatch = ScoutingState()
            let beforeMismatchedBatch = try JSONEncoder.stable().encode(atomicBatch)
            expect(!atomicBatch.recordPortalKnowledgeBatch(
                [
                    seed,
                    portalPolicyKnowledge(
                        copying: seed,
                        playerID: portalPolicyUUID(10_000),
                        targetSeason: 2
                    ),
                ],
                targetSeason: 1,
                window: .postseason
            ))
            expectEqual(
                try JSONEncoder.stable().encode(atomicBatch),
                beforeMismatchedBatch
            )

            var encodedScouting = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(ScoutingState(
                    portalKnowledgeByObserver: [base.observerProgrammeID: [seed]]
                ))
            ) as! [String: Any]
            if var observers = encodedScouting["portalKnowledgeByObserver"] as? [Any] {
                observers[1] = [Any]()
                encodedScouting["portalKnowledgeByObserver"] = observers
            } else if var observers = encodedScouting[
                "portalKnowledgeByObserver"
            ] as? [String: Any] {
                observers[base.observerProgrammeID.uuidString] = [Any]()
                encodedScouting["portalKnowledgeByObserver"] = observers
            } else {
                expect(false, "portal knowledge dictionary used an unknown encoded shape")
            }
            do {
                _ = try JSONDecoder.stable().decode(
                    ScoutingState.self,
                    from: JSONSerialization.data(withJSONObject: encodedScouting)
                )
                expect(false, "an empty portal observer bucket decoded")
            } catch {
                expect(true)
            }

            let emptyObserverProbe = Process()
            emptyObserverProbe.executableURL = currentExecutableURL()
            emptyObserverProbe.arguments = ["--portal-policy"]
            var probeEnvironment = ProcessInfo.processInfo.environment
            probeEnvironment["INVALID_EMPTY_PORTAL_OBSERVER_PROBE"] = "1"
            emptyObserverProbe.environment = probeEnvironment
            emptyObserverProbe.standardOutput = Pipe()
            emptyObserverProbe.standardError = Pipe()
            try emptyObserverProbe.run()
            emptyObserverProbe.waitUntilExit()
            expect(
                emptyObserverProbe.terminationStatus != 0,
                "an empty portal observer bucket did not fail fast"
            )
            expect(immutable.recordPortalKnowledge(seed))
            expectEqual(try JSONEncoder.stable().encode(immutable), beforeOverwrite)

            var earlyObject = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(seed)
            ) as! [String: Any]
            var earlyCalendar = earlyObject["lastUpdated"] as! [String: Any]
            earlyCalendar["week"] = SharedRules.inSeasonWeeks - 1
            earlyObject["lastUpdated"] = earlyCalendar
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalKnowledgeSnapshot.self,
                    from: JSONSerialization.data(withJSONObject: earlyObject)
                )
                expect(false, "portal knowledge from before the exact window calendar decoded")
            } catch {
                expect(true)
            }

            let observerIDs = base.state.programmes.ids
            let observerScale = observerIDs.enumerated().flatMap { observerIndex, observerID in
                (0..<3).map { playerIndex in
                    portalPolicyKnowledge(
                        copying: seed,
                        playerID: portalPolicyUUID(
                            20_000 + observerIndex * 3 + playerIndex
                        ),
                        observerProgrammeID: observerID
                    )
                }
            }
            var observerAscending = ScoutingState()
            var observerDescending = ScoutingState()
            expect(observerAscending.recordPortalKnowledgeBatch(
                observerScale,
                targetSeason: 1,
                window: .postseason
            ))
            expect(observerDescending.recordPortalKnowledgeBatch(
                observerScale.reversed(),
                targetSeason: 1,
                window: .postseason
            ))
            expectEqual(observerAscending.portalKnowledgeByObserver.count, 134)
            expectEqual(
                try JSONEncoder.stable().encode(observerAscending),
                try JSONEncoder.stable().encode(observerDescending)
            )
            let beforeObserverOverflow = try JSONEncoder.stable().encode(observerAscending)
            expect(!observerAscending.recordPortalKnowledge(portalPolicyKnowledge(
                copying: seed,
                playerID: portalPolicyUUID(30_000),
                observerProgrammeID: portalPolicyUUID(30_001)
            )))
            expectEqual(
                try JSONEncoder.stable().encode(observerAscending),
                beforeObserverOverflow
            )

            var slices = ScoutingState()
            expect(slices.recordPortalKnowledge(seed))
            let beforeNextTarget = try JSONEncoder.stable().encode(slices)
            expect(!slices.recordPortalKnowledge(portalPolicyKnowledge(
                copying: seed,
                playerID: portalPolicyUUID(10_001),
                targetSeason: 2
            )))
            expectEqual(try JSONEncoder.stable().encode(slices), beforeNextTarget)

            let prospectID = portalPolicyUUID(10_002)
            let observation = ProspectObservation(
                prospectID: prospectID,
                estimatedAttributes: [:],
                estimatedPotential: Rating(70),
                confidence: 10,
                lastUpdated: CalendarState(),
                evidenceCount: 1
            )
            let assignment = ScoutingAssignment(
                observerID: base.observerProgrammeID,
                prospectID: prospectID,
                effort: 1
            )
            var rollover = ScoutingState(
                observationsByObserver: [
                    base.observerProgrammeID: [prospectID: observation],
                ],
                pendingEvaluations: [assignment],
                portalKnowledgeByObserver: [base.observerProgrammeID: [seed]]
            )
            let beforeSameTargetRenewal = try JSONEncoder.stable().encode(rollover)
            expect(!rollover.renewPortalKnowledge(forTargetSeason: 1))
            expectEqual(
                try JSONEncoder.stable().encode(rollover),
                beforeSameTargetRenewal
            )
            expect(rollover.renewPortalKnowledge(forTargetSeason: 2))
            expect(rollover.portalKnowledgeByObserver.isEmpty)
            expectEqual(
                rollover.observation(
                    observerID: base.observerProgrammeID,
                    prospectID: prospectID
                ),
                observation
            )
            expectEqual(rollover.pendingEvaluations, [assignment])
            expect(rollover.recordPortalKnowledgeBatch(
                [portalPolicyKnowledge(
                    copying: seed,
                    playerID: portalPolicyUUID(10_003),
                    targetSeason: 2
                )],
                targetSeason: 2,
                window: .postseason
            ))
        }

        test("held policy snapshot isolates knowledge from later hidden-truth mutation") {
            let batch = portalPolicySnapshot(base.state)
            expect(!((batch as Any) is any Encodable))
            let intent = batch.intents[0]
            let first = CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: intent.playerID,
                using: batch
            )!

            var changedTruth = base.state
            _ = changedTruth.players.update(base.playerID) {
                $0.potential = Rating($0.potential.value > 69 ? 40 : 99)
                for attribute in $0.position.ratedAttributes {
                    $0.attributes[attribute] = Rating(
                        $0.attributes[attribute].value > 69 ? 40 : 99
                    )
                }
            }
            let observerStaffIDs = changedTruth.programmes[base.observerProgrammeID]!.staffIDs
            for staffID in observerStaffIDs {
                _ = changedTruth.staff.update(staffID) {
                    $0.ratings[.recruiting] = Rating(99)
                }
            }
            let second = CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: intent.playerID,
                using: batch
            )!
            expectEqual(second, first)
            let freshBatch = portalPolicySnapshot(changedTruth)
            let fresh = CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: intent.playerID,
                using: freshBatch
            )!
            expect(fresh != first)
            expectEqual(
                freshBatch.intents,
                batch.intents
            )
            var scouting = ScoutingState()
            expect(scouting.recordPortalKnowledge(first))
            let beforeOverwrite = try JSONEncoder.stable().encode(scouting)
            expect(!scouting.recordPortalKnowledge(fresh))
            expectEqual(try JSONEncoder.stable().encode(scouting), beforeOverwrite)
            expect(CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: base.observerProgrammeID,
                playerID: portalPolicyUUID(39_999),
                using: batch
            ) == nil)
            expect(CollegePortalPolicyV1.knowledgeSnapshot(
                observerProgrammeID: portalPolicyUUID(39_998),
                playerID: intent.playerID,
                using: batch
            ) == nil)
        }

        test("retention uses playing-role priority and one-unit-short trials are byte-identical") {
            var state = base.state
            let sourceID = base.sourceProgrammeID
            let higherID = base.playerID
            let lowerID = state.programmes[sourceID]!.rosterIDs.first {
                $0 != higherID && state.players[$0]?.position == .quarterback
            }!
            _ = state.players.update(lowerID) { $0.remove(.restless) }
            expect(state.people.updatePlayerCareer(lowerID) { career in
                expect(career.append(PlayerCareerSeason(
                    season: 0,
                    organisationID: sourceID,
                    tier: .college,
                    games: 8,
                    starts: 4,
                    overallAtEnd: Rating(70)
                )))
            })
            var programmeStates = state.college.programmes
            let current = programmeStates[sourceID]!
            programmeStates[sourceID] = ProgrammeRecruitingState(
                programmeID: sourceID,
                scholarshipPlayerIDs: current.scholarshipPlayerIDs,
                nilState: ProgrammeNILState(
                    programmeID: sourceID,
                    season: 1,
                    annualBudget: 399,
                    rosterAllocations: [lowerID: 100, higherID: 100]
                )
            )
            state.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(targetSeason: 1),
                programmes: programmeStates
            )
            let batch = portalPolicySnapshot(state)
            let programme = state.college.programmes[sourceID]!
            let resolved = CollegePortalPolicyV1.resolveRetention(
                for: sourceID,
                programme: programme,
                using: batch
            )!

            expectEqual(resolved.resolutions[higherID]?.outcome, .retained)
            expectEqual(resolved.resolutions[lowerID]?.outcome, .released)
            expectEqual(resolved.programme.nilState.rosterAllocations[higherID], 200)
            expectEqual(resolved.programme.nilState.rosterAllocations[lowerID], 100)

            var failedState = base.state
            var failedProgrammes = failedState.college.programmes
            let failedCurrent = failedProgrammes[sourceID]!
            failedProgrammes[sourceID] = ProgrammeRecruitingState(
                programmeID: sourceID,
                scholarshipPlayerIDs: failedCurrent.scholarshipPlayerIDs,
                nilState: ProgrammeNILState(
                    programmeID: sourceID,
                    season: 1,
                    annualBudget: 199,
                    rosterAllocations: [higherID: 100]
                )
            )
            failedState.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(targetSeason: 1),
                programmes: failedProgrammes
            )
            let failedBatch = portalPolicySnapshot(failedState)
            let singleProgramme = failedState.college.programmes[sourceID]!
            let before = try JSONEncoder.stable().encode(singleProgramme)
            let failed = CollegePortalPolicyV1.resolveRetention(
                for: sourceID,
                programme: singleProgramme,
                using: failedBatch
            )!
            expectEqual(failed.resolutions[higherID]?.outcome, .released)
            expectEqual(try JSONEncoder.stable().encode(failed.programme), before)

            let wrongProgramme = failedState.college.programmes[base.observerProgrammeID]!
            expect(CollegePortalPolicyV1.resolveRetention(
                for: sourceID,
                programme: wrongProgramme,
                using: failedBatch
            ) == nil)
        }

        test("retention crosses 199 with one unit and reports maximum-band impossibility") {
            let boundary = portalPolicyFixture(sourceRosterNIL: 199)
            let boundaryBatch = portalPolicySnapshot(boundary.state)
            let boundaryProgramme = boundary.state.college.programmes[
                boundary.sourceProgrammeID
            ]!
            let retained = CollegePortalPolicyV1.resolveRetention(
                for: boundary.sourceProgrammeID,
                programme: boundaryProgramme,
                using: boundaryBatch
            )!
            let retainedResolution = retained.resolutions[boundary.playerID]!
            expectEqual(retainedResolution.outcome, .retained)
            expectEqual(retainedResolution.requiredAdditionalNIL, 1)
            expectEqual(retainedResolution.appliedAdditionalNIL, 1)
            expectEqual(retainedResolution.sourceRosterNILAfterDecision, 200)
            expectEqual(
                retained.programme.nilState.rosterAllocations[boundary.playerID],
                200
            )

            let impossible = portalPolicyFixture(
                sourceRank: 134,
                sourceRosterNIL: 2_000,
                games: 0,
                starts: 0,
                isRestless: true
            )
            let impossibleBatch = portalPolicySnapshot(impossible.state)
            let impossibleProgramme = impossible.state.college.programmes[
                impossible.sourceProgrammeID
            ]!
            let before = try JSONEncoder.stable().encode(impossibleProgramme)
            let released = CollegePortalPolicyV1.resolveRetention(
                for: impossible.sourceProgrammeID,
                programme: impossibleProgramme,
                using: impossibleBatch
            )!
            expectEqual(released.resolutions[impossible.playerID]?.outcome, .released)
            expect(released.resolutions[impossible.playerID]?.requiredAdditionalNIL == nil)
            expectEqual(try JSONEncoder.stable().encode(released.programme), before)
        }

        test("persisted restless changes intent by exactly ten and crosses selection") {
            let quiet = portalPolicyFixture(sourceRank: 35)
            expect(portalPolicySnapshot(quiet.state).intents.isEmpty)

            var restlessState = quiet.state
            _ = restlessState.players.update(quiet.playerID) { $0.add(.restless) }
            let persisted = try JSONDecoder.stable().decode(
                Player.self,
                from: JSONEncoder.stable().encode(restlessState.players[quiet.playerID]!)
            )
            expect(persisted.has(.restless))
            let selected = portalPolicySnapshot(restlessState).intents
            expectEqual(selected.count, 1)
            expectEqual(selected[0].total, 25)
            expectEqual(
                selected[0].components.first { $0.reason == .restless }?.value,
                10
            )
            let evidence = selected[0].evidence
            let quietEvidence = CollegePortalIntentEvidence(
                position: evidence.position,
                starts: evidence.starts,
                appearances: evidence.appearances,
                sourcePositionRoomSize: evidence.sourcePositionRoomSize,
                seasonsAtSource: evidence.seasonsAtSource,
                sourceFinalRankingPosition: evidence.sourceFinalRankingPosition,
                sourceRosterNIL: evidence.sourceRosterNIL,
                relationshipScore: evidence.relationshipScore,
                isRestless: false
            )
            expectEqual(
                selected[0].total
                    - CollegePortalPolicyV1.intentComponents(for: quietEvidence)
                        .reduce(0) { $0 + $1.value },
                10
            )
        }

        test("policy snapshot requires the exact predecessor phase for each window") {
            var wrongTargetSeason = base.state
            wrongTargetSeason.calendar = CalendarState(
                season: 1,
                week: SharedRules.inSeasonWeeks
            )
            wrongTargetSeason.league.season = 1
            wrongTargetSeason.league.week = SharedRules.inSeasonWeeks
            let beforeWrongTarget = try JSONEncoder.stable().encode(wrongTargetSeason)
            expect(CollegePortalPolicyV1.makeSnapshot(
                targetSeason: 2,
                window: .postseason,
                in: wrongTargetSeason
            ) == nil)
            expectEqual(
                try JSONEncoder.stable().encode(wrongTargetSeason),
                beforeWrongTarget
            )

            var closedSpring = base.state
            closedSpring.calendar = CalendarState(season: 1, week: 1)
            closedSpring.league.season = 1
            closedSpring.league.week = 1
            expect(CollegePortalPolicyV1.makeSnapshot(
                targetSeason: 1,
                window: .spring,
                in: closedSpring
            ) == nil)

            let summary = CollegePortalWindowSummary(
                targetSeason: 1,
                window: .postseason,
                completedAt: CalendarState(
                    season: 0,
                    week: SharedRules.inSeasonWeeks
                ),
                entrantCount: 0,
                retainedCount: 0,
                transferredCount: 0,
                returnedCount: 0,
                offerCount: 0
            )
            var awaiting = base.state
            awaiting.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(
                    targetSeason: 1,
                    phase: .awaitingSpring,
                    entries: [:],
                    summaries: [summary]
                ),
                programmes: awaiting.college.programmes
            )
            expect(CollegePortalPolicyV1.makeSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: awaiting
            ) == nil)
            awaiting.calendar = CalendarState(season: 1, week: 1)
            awaiting.league.season = 1
            awaiting.league.week = 1
            let spring = CollegePortalPolicyV1.makeSnapshot(
                targetSeason: 1,
                window: .spring,
                in: awaiting
            )
            expect(spring != nil)
            expectEqual(spring?.window, .spring)
        }

        test("window-record persistence rejects a v1 retention that drifts from intent evidence") {
            let record = portalWindowRecord(
                playerID: portalPolicyUUID(40),
                sourceProgrammeID: portalPolicyUUID(41),
                targetSeason: 1,
                window: .postseason
            )
            expectEqual(record.retention.requiredAdditionalNIL, 100)
            expectEqual(record.retention.intentScoreAfterDecision, 25)
            let data = try JSONEncoder.stable().encode(record)
            var wrongRequired = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var wrongRequiredResolution = wrongRequired["retention"] as! [String: Any]
            wrongRequiredResolution["requiredAdditionalNIL"] = 101
            wrongRequired["retention"] = wrongRequiredResolution
            var wrongScore = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var wrongScoreResolution = wrongScore["retention"] as! [String: Any]
            wrongScoreResolution["intentScoreAfterDecision"] = 24
            wrongScore["retention"] = wrongScoreResolution
            for object in [wrongRequired, wrongScore] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalWindowRecord.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "a window record accepted formula-drifted retention")
                } catch {
                    expect(true)
                }
            }
        }

        test("spring intent supports zero tenure after postseason transfer and rejects a repeat window") {
            var state = base.state
            let ranking = state.competition.archives.first { $0.season == 0 }!
                .finalCollegeRanking
            let destinationID = ranking.last!
            let postseason = portalWindowRecord(
                playerID: base.playerID,
                sourceProgrammeID: base.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 200,
                destinationNILRemaining: 200
            )
            expect(state.people.updatePlayerCareer(base.playerID) {
                expect($0.append(postseason))
            })
            _ = state.programmes.update(base.sourceProgrammeID) {
                $0.rosterIDs.removeAll { $0 == base.playerID }
            }
            _ = state.programmes.update(destinationID) {
                $0.rosterIDs.append(base.playerID)
            }
            _ = state.players.update(base.playerID) { $0.add(.restless) }

            let programmeStates = Dictionary(uniqueKeysWithValues: state.programmes.values.map {
                programme -> (UUID, ProgrammeRecruitingState) in
                let allocations = programme.id == destinationID
                    ? [base.playerID: postseason.finalRosterNIL]
                    : [:]
                return (
                    programme.id,
                    ProgrammeRecruitingState(
                        programmeID: programme.id,
                        scholarshipPlayerIDs: Array(
                            programme.rosterIDs.prefix(CollegeRules.scholarshipLimit)
                        ),
                        nilState: ProgrammeNILState(
                            programmeID: programme.id,
                            season: 1,
                            annualBudget: programme.resources.value
                                * CollegeRules.nilBudgetPerResourcePoint,
                            rosterAllocations: allocations
                        )
                    )
                )
            })
            let postseasonSummary = CollegePortalWindowSummary(
                targetSeason: 1,
                window: .postseason,
                completedAt: postseason.openedAt,
                entrantCount: 1,
                retainedCount: 0,
                transferredCount: 1,
                returnedCount: 0,
                offerCount: postseason.offers.count
            )
            state.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(
                    targetSeason: 1,
                    phase: .awaitingSpring,
                    entries: [base.playerID: postseason],
                    summaries: [postseasonSummary]
                ),
                programmes: programmeStates
            )
            state.calendar = CalendarState(season: 1, week: 1)
            state.league.season = 1
            state.league.week = 1

            let springBatch = portalPolicySnapshot(state, window: .spring)
            let spring = springBatch.intents
            expectEqual(spring.count, 1)
            expectEqual(spring[0].sourceProgrammeID, destinationID)
            expectEqual(spring[0].evidence.seasonsAtSource, 0)

            let repeatWindow = portalWindowRecord(
                playerID: base.playerID,
                sourceProgrammeID: destinationID,
                targetSeason: 1,
                window: .spring,
                sourceRosterNIL: postseason.finalRosterNIL,
                seasonsAtSource: 0
            )
            expect(state.people.updatePlayerCareer(base.playerID) {
                expect($0.append(repeatWindow))
            })
            expect(portalPolicySnapshot(state, window: .spring).intents.isEmpty)
        }
    }
}
