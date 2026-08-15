import Foundation
import FootballSimCore

private func portalContractUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-4000-8006-%012X", value))!
}

private func portalCareerSeason(season: Int, organisationID: UUID) -> PlayerCareerSeason {
    PlayerCareerSeason(
        season: season,
        organisationID: organisationID,
        tier: .college,
        games: 8,
        starts: 5,
        overallAtEnd: Rating(70)
    )
}

private func portalIntent(
    playerID: UUID,
    sourceProgrammeID: UUID,
    targetSeason: Int,
    window: CollegePortalWindow,
    openedAt: CalendarState,
    position: Position = .quarterback,
    sourceRosterNIL: Int = 100,
    seasonsAtSource: Int = 1
) -> CollegePortalIntentExplanation {
    let intrinsicallyHardToRetain = sourceRosterNIL >= 2_000
    let evidence = CollegePortalIntentEvidence(
        position: position,
        starts: 5,
        appearances: 8,
        sourcePositionRoomSize: 4,
        seasonsAtSource: seasonsAtSource,
        sourceFinalRankingPosition: intrinsicallyHardToRetain ? 134 : 101,
        sourceRosterNIL: sourceRosterNIL,
        relationshipScore: intrinsicallyHardToRetain ? 0 : nil,
        isRestless: intrinsicallyHardToRetain
    )
    return CollegePortalIntentExplanation(
        policyVersion: CollegeRules.portalPolicyVersion,
        playerID: playerID,
        sourceProgrammeID: sourceProgrammeID,
        targetSeason: targetSeason,
        window: window,
        evaluatedAt: openedAt,
        evidence: evidence,
        components: CollegePortalPolicyV1.intentComponents(for: evidence),
        selectionThreshold: CollegePortalPolicyV1.intentSelectionThreshold
    )
}

private func portalOffer(
    playerID: UUID,
    sourceProgrammeID: UUID,
    destinationProgrammeID: UUID,
    targetSeason: Int,
    window: CollegePortalWindow,
    openedAt: CalendarState,
    nilReservation: Int = 200,
    fitValue: Int = 10,
    admissionOverall: Int = 70,
    position: Position = .quarterback,
    rosterOpenings: Int = 10,
    scholarshipOpenings: Int = 5,
    minimumCoverageDeficits: [Position: Int] = [:],
    nilRemaining: Int = 1_000
) -> CollegePortalOffer {
    let admissionEvidence = CollegePortalAdmissionEvidence(
        position: position,
        estimatedOverall: Rating(admissionOverall),
        estimatedPotential: Rating(75),
        appearances: 8,
        fixedPositionRoomCount: 4,
        estimatedSchemeFit: Rating(admissionOverall),
        confidence: 25
    )
    var fitPriorities = Dictionary(uniqueKeysWithValues: RecruitingPitch.allCases.map {
        ($0, Rating(40))
    })
    fitPriorities[.prestige] = Rating(99)
    let fitEvidence = CollegePortalDestinationEvidence(
        candidatePosition: position,
        origin: .known(cityID: portalContractUUID(89_999)),
        destinationHomeCityID: portalContractUUID(90_000),
        squaredCityDistance: 0,
        destinationPositionRoomCount: 4,
        positionTargetCount: max(
            1,
            CollegeRules.initialRosterByPosition[position] ?? 1
        ),
        observedSchemeFit: Rating(admissionOverall),
        priorityWeights: fitPriorities,
        prestige: Rating(40 + (fitValue - 10) * 59 / 10),
        recruitingStaffAverage: Rating(65),
        archivedFinalRankingPosition: 20
    )
    return CollegePortalOffer(
        destinationProgrammeID: destinationProgrammeID,
        nilReservation: nilReservation,
        knowledge: CollegePortalKnowledgeSnapshot(
            observerProgrammeID: destinationProgrammeID,
            playerID: playerID,
            sourceProgrammeID: sourceProgrammeID,
            targetSeason: targetSeason,
            window: window,
            position: admissionEvidence.position,
            estimatedOverall: admissionEvidence.estimatedOverall,
            estimatedAttributes: Dictionary(uniqueKeysWithValues:
                admissionEvidence.position.ratedAttributes.map {
                    ($0, Rating(admissionOverall))
                }
            ),
            estimatedPotential: Rating(75),
            confidence: 25,
            lastUpdated: openedAt,
            evidenceCount: 1
        ),
        playerFit: CollegePortalDestinationFitExplanation(
            policyVersion: CollegeRules.portalPolicyVersion,
            playerID: playerID,
            programmeID: destinationProgrammeID,
            evidence: fitEvidence,
            components: CollegePortalPolicyV1.destinationFitComponents(
                for: fitEvidence,
                nilAllocationAdjustment: nilReservation
                    / CollegeRules.nilInterestPointsPerUnit
            ),
            nilAllocationAdjustment: nilReservation / CollegeRules.nilInterestPointsPerUnit,
            knowledgeAdjustment: 0
        ),
        destinationAdmission: CollegePortalDestinationAdmissionExplanation(
            policyVersion: CollegeRules.portalPolicyVersion,
            playerID: playerID,
            programmeID: destinationProgrammeID,
            evidence: admissionEvidence,
            components: CollegePortalPolicyV1.admissionComponents(for: admissionEvidence)
        ),
        fixedCapacity: CollegePortalCapacitySnapshot(
            programmeID: destinationProgrammeID,
            targetSeason: targetSeason,
            window: window,
            capturedAt: openedAt,
            rosterOpenings: rosterOpenings,
            scholarshipOpenings: scholarshipOpenings,
            minimumCoverageDeficits: minimumCoverageDeficits,
            nilRemaining: nilRemaining
        )
    )
}

func portalWindowRecord(
    playerID: UUID,
    sourceProgrammeID: UUID,
    targetSeason: Int,
    window: CollegePortalWindow,
    destinationProgrammeID: UUID? = nil,
    sourceRosterNIL: Int = 100,
    offerNILReservation: Int = 200,
    destinationRosterOpenings: Int = 10,
    destinationScholarshipOpenings: Int = 5,
    destinationMinimumCoverageDeficits: [Position: Int] = [:],
    destinationNILRemaining: Int = 1_000,
    position: Position = .quarterback,
    seasonsAtSource: Int = 1
) -> CollegePortalWindowRecord {
    let openedAt = window == .postseason
        ? CalendarState(season: targetSeason - 1, week: SharedRules.inSeasonWeeks)
        : CalendarState(season: targetSeason, week: 1)
    let offer = destinationProgrammeID.map {
        portalOffer(
            playerID: playerID,
            sourceProgrammeID: sourceProgrammeID,
            destinationProgrammeID: $0,
            targetSeason: targetSeason,
            window: window,
            openedAt: openedAt,
            nilReservation: offerNILReservation,
            position: position,
            rosterOpenings: destinationRosterOpenings,
            scholarshipOpenings: destinationScholarshipOpenings,
            minimumCoverageDeficits: destinationMinimumCoverageDeficits,
            nilRemaining: destinationNILRemaining
        )
    }
    let intent = portalIntent(
        playerID: playerID,
        sourceProgrammeID: sourceProgrammeID,
        targetSeason: targetSeason,
        window: window,
        openedAt: openedAt,
        position: position,
        sourceRosterNIL: sourceRosterNIL,
        seasonsAtSource: seasonsAtSource
    )
    let currentBand = min(20, sourceRosterNIL / CollegeRules.nilInterestPointsPerUnit)
    let dropNeeded = intent.total - intent.selectionThreshold + 1
    let targetBand = currentBand + dropNeeded
    let requiredAdditionalNIL = targetBand > 20
        ? nil
        : max(
            0,
            targetBand * CollegeRules.nilInterestPointsPerUnit - sourceRosterNIL
        )
    return CollegePortalWindowRecord(
        policyVersion: CollegeRules.portalPolicyVersion,
        playerID: playerID,
        sourceProgrammeID: sourceProgrammeID,
        targetSeason: targetSeason,
        window: window,
        openedAt: openedAt,
        sourceWasScholarship: true,
        intent: intent,
        retention: CollegePortalRetentionResolution(
            policyVersion: CollegeRules.portalPolicyVersion,
            outcome: .released,
            requiredAdditionalNIL: requiredAdditionalNIL,
            appliedAdditionalNIL: 0,
            sourceRosterNILAfterDecision: sourceRosterNIL,
            intentScoreAfterDecision: intent.total
        ),
        offers: offer.map { [$0] } ?? [],
        outcome: destinationProgrammeID.map {
            .transferred(destinationProgrammeID: $0)
        } ?? .returnedToSource,
        finalIsScholarship: true,
        finalRosterNIL: offer?.nilReservation ?? sourceRosterNIL
    )
}

func runPortalContractTests() {
    if ProcessInfo.processInfo.environment["INVALID_COLLEGE_PORTAL_TARGET_PROBE"] != nil {
        _ = CollegeState(
            recruitingSeason: 0,
            portal: CollegePortalState(targetSeason: 1),
            programmes: [:]
        )
        return
    }
    if ProcessInfo.processInfo.environment["INVALID_PLAYER_CAREER_END_PROBE"] != nil {
        _ = PlayerCareerRecord(
            playerID: portalContractUUID(9_001),
            portalWindows: [],
            endedAt: CalendarState(season: 0, week: 1),
            endStatus: nil
        )
        return
    }
    if ProcessInfo.processInfo.environment["INVALID_GAME_SCHEMA_VERSION_PROBE"] != nil {
        let state = GameState.bootstrap(seed: 94_099)
        _ = GameState(
            version: GameState.schemaVersion - 1,
            league: state.league,
            map: state.map,
            programmes: state.programmes,
            proTeams: state.proTeams,
            players: state.players,
            staff: state.staff,
            identities: state.identities,
            rivalries: state.rivalries,
            history: state.history,
            calendar: state.calendar,
            pending: state.pending,
            competition: state.competition,
            people: state.people,
            prospects: state.prospects,
            college: state.college,
            scouting: state.scouting
        )
        return
    }

    suite("College portal state contracts") {
        test("college construction fails fast when its portal targets another season") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            process.arguments = ["--portal-contracts"]
            var environment = ProcessInfo.processInfo.environment
            environment["INVALID_COLLEGE_PORTAL_TARGET_PROBE"] = "1"
            process.environment = environment
            process.standardOutput = Pipe()
            process.standardError = Pipe()

            try process.run()
            process.waitUntilExit()

            expect(process.terminationStatus != 0)
        }

        test("source constructors enforce career termination and current root schema") {
            for probe in [
                "INVALID_PLAYER_CAREER_END_PROBE",
                "INVALID_GAME_SCHEMA_VERSION_PROBE",
            ] {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
                process.arguments = ["--portal-contracts"]
                var environment = ProcessInfo.processInfo.environment
                environment[probe] = "1"
                process.environment = environment
                process.standardOutput = Pipe()
                process.standardError = Pipe()

                try process.run()
                process.waitUntilExit()

                expect(process.terminationStatus != 0, "\(probe) did not fail fast")
            }
        }

        test("only closed and awaiting-spring phases are stable boundaries") {
            expect(CollegePortalPhase.closed.isStableBoundary)
            expect(CollegePortalPhase.awaitingSpring.isStableBoundary)
            expect(!CollegePortalPhase.postseasonOpen.isStableBoundary)
            expect(!CollegePortalPhase.springOpen.isStableBoundary)
        }

        test("bootstrap exposes an empty schema-six portal for the current season") {
            let state = GameState.bootstrap(seed: 94_001)

            expectEqual(GameState.schemaVersion, 12)
            expectEqual(state.college.portal.targetSeason, state.college.recruitingSeason)
            expectEqual(state.college.portal.phase, .closed)
            expect(state.college.portal.entries.isEmpty)
            expect(state.college.portal.summaries.isEmpty)
        }

        test("persisted schema-six college state requires an explicit portal") {
            let state = GameState.bootstrap(seed: 94_002)
            let encoded = try JSONEncoder.stable().encode(state.college)
            let baseline = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            var missing = baseline
            missing.removeValue(forKey: "portal")
            var null = baseline
            null["portal"] = NSNull()

            for object in [missing, null] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegeState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "college state decoded without an explicit portal")
                } catch {
                    expect(true)
                }
            }
        }

        test("a resolved window record round-trips with immutable explanations and offers") {
            let playerID = portalContractUUID(1)
            let sourceID = portalContractUUID(2)
            let destinationID = portalContractUUID(3)
            let record = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID
            )

            expectEqual(record.finalProgrammeID, destinationID)
            expectEqual(record.offers.first?.knowledge.sourceProgrammeID, sourceID)
            expectEqual(record.intent.total, 25)
            expectEqual(record.offers.first?.playerFit.total, 14)
            expectEqual(record.offers.first?.destinationAdmission.total, 24)
            expectEqual(
                CollegePortalPolicyV1.expectedCalendar(
                    targetSeason: 1,
                    window: .postseason
                ),
                CalendarState(season: 0, week: 21)
            )
            expectEqual(
                CollegePortalPolicyV1.expectedCalendar(
                    targetSeason: 1,
                    window: .spring
                ),
                CalendarState(season: 1, week: 1)
            )
            expectEqual(
                try JSONDecoder.stable().decode(
                    CollegePortalWindowRecord.self,
                    from: JSONEncoder.stable().encode(record)
                ),
                record
            )
        }

        test("persisted portal state rejects identity target and collection-bound corruption") {
            let record = portalWindowRecord(
                playerID: portalContractUUID(10),
                sourceProgrammeID: portalContractUUID(11),
                targetSeason: 1,
                window: .postseason
            )
            let valid = CollegePortalState(
                targetSeason: 1,
                phase: .awaitingSpring,
                entries: [record.playerID: record],
                summaries: [CollegePortalWindowSummary(
                    targetSeason: 1,
                    window: .postseason,
                    completedAt: record.openedAt,
                    entrantCount: 1,
                    retainedCount: 0,
                    transferredCount: 0,
                    returnedCount: 1,
                    offerCount: 0
                )]
            )
            let encoded = try JSONEncoder.stable().encode(valid)
            let baseline = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

            var wrongKey = baseline
            let entries = wrongKey["entries"] as! [String: Any]
            wrongKey["entries"] = [portalContractUUID(12).uuidString: entries.values.first!]

            var wrongTarget = baseline
            wrongTarget["targetSeason"] = 2

            var unbounded = baseline
            let records = Dictionary(uniqueKeysWithValues: (0...CollegeRules.portalPoolLimit).map {
                index -> (UUID, CollegePortalWindowRecord) in
                let playerID = portalContractUUID(1_000 + index)
                return (playerID, portalWindowRecord(
                    playerID: playerID,
                    sourceProgrammeID: portalContractUUID(20),
                    targetSeason: 1,
                    window: .postseason
                ))
            })
            unbounded["entries"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(records)
            )

            for object in [wrongKey, wrongTarget, unbounded] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "corrupt portal state decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("only coherent stable portal phases decode") {
            let transient = CollegePortalState(
                targetSeason: 1,
                phase: .postseasonOpen
            )
            do {
                _ = try JSONEncoder.stable().encode(transient)
                expect(false, "a transactional open phase encoded as a stable root")
            } catch {
                expect(true)
            }

            let record = portalWindowRecord(
                playerID: portalContractUUID(21),
                sourceProgrammeID: portalContractUUID(22),
                targetSeason: 1,
                window: .postseason
            )
            let awaiting = CollegePortalState(
                targetSeason: 1,
                phase: .awaitingSpring,
                entries: [record.playerID: record],
                summaries: [CollegePortalWindowSummary(
                    targetSeason: 1,
                    window: .postseason,
                    completedAt: record.openedAt,
                    entrantCount: 1,
                    retainedCount: 0,
                    transferredCount: 0,
                    returnedCount: 1,
                    offerCount: 0
                )]
            )
            let data = try JSONEncoder.stable().encode(awaiting)
            let baseline = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var missingPostseason = baseline
            missingPostseason["summaries"] = []
            var incoherentClosed = baseline
            incoherentClosed["phase"] = CollegePortalPhase.closed.rawValue

            for object in [missingPostseason, incoherentClosed] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an incoherent stable portal phase decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("portal state conserves one fixed destination capacity across the whole batch") {
            let destinationID = portalContractUUID(23)
            let first = portalWindowRecord(
                playerID: portalContractUUID(24),
                sourceProgrammeID: portalContractUUID(25),
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500
            )
            let second = portalWindowRecord(
                playerID: portalContractUUID(26),
                sourceProgrammeID: portalContractUUID(27),
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500
            )
            let state = CollegePortalState(
                targetSeason: 1,
                phase: .awaitingSpring,
                entries: [first.playerID: first, second.playerID: second],
                summaries: [CollegePortalWindowSummary(
                    targetSeason: 1,
                    window: .postseason,
                    completedAt: first.openedAt,
                    entrantCount: 2,
                    retainedCount: 0,
                    transferredCount: 2,
                    returnedCount: 0,
                    offerCount: 2
                )]
            )
            let data = try JSONEncoder.stable().encode(state)
            let baseline = try JSONSerialization.jsonObject(with: data) as! [String: Any]

            var snapshotDrift = baseline
            var driftEntries = snapshotDrift["entries"] as! [String: Any]
            let driftKey = driftEntries.keys.sorted().last!
            var driftRecord = driftEntries[driftKey] as! [String: Any]
            var driftOffers = driftRecord["offers"] as! [[String: Any]]
            var driftCapacity = driftOffers[0]["fixedCapacity"] as! [String: Any]
            driftCapacity["nilRemaining"] = 900
            driftOffers[0]["fixedCapacity"] = driftCapacity
            driftRecord["offers"] = driftOffers
            driftEntries[driftKey] = driftRecord
            snapshotDrift["entries"] = driftEntries

            let overReservedRecords = [first.playerID: portalWindowRecord(
                playerID: first.playerID,
                sourceProgrammeID: first.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500,
                destinationNILRemaining: 900
            ), second.playerID: portalWindowRecord(
                playerID: second.playerID,
                sourceProgrammeID: second.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500,
                destinationNILRemaining: 900
            )]
            var overReserved = baseline
            overReserved["entries"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(overReservedRecords)
            )

            let unequalRecords = [first.playerID: portalWindowRecord(
                playerID: first.playerID,
                sourceProgrammeID: first.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 400
            ), second.playerID: second]
            var unequalOffers = baseline
            unequalOffers["entries"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(unequalRecords)
            )

            let overAcceptedRecords = [first.playerID: portalWindowRecord(
                playerID: first.playerID,
                sourceProgrammeID: first.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500,
                destinationRosterOpenings: 1,
                destinationScholarshipOpenings: 1
            ), second.playerID: portalWindowRecord(
                playerID: second.playerID,
                sourceProgrammeID: second.sourceProgrammeID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500,
                destinationRosterOpenings: 1,
                destinationScholarshipOpenings: 1
            )]
            var overAccepted = baseline
            overAccepted["entries"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(overAcceptedRecords)
            )

            for object in [snapshotDrift, overReserved, unequalOffers, overAccepted] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalState.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "a portal batch exceeded its fixed destination capacity")
                } catch {
                    expect(true)
                }
            }
        }

        test("persisted acceptance preserves captured minimum-position repair capacity") {
            let playerID = portalContractUUID(28)
            let sourceID = portalContractUUID(29)
            let destinationID = portalContractUUID(30)
            let specialist = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500,
                destinationRosterOpenings: 1,
                destinationScholarshipOpenings: 1,
                destinationMinimumCoverageDeficits: [.quarterback: 1],
                position: .quarterback
            )
            let state = CollegePortalState(
                targetSeason: 1,
                phase: .awaitingSpring,
                entries: [playerID: specialist],
                summaries: [CollegePortalWindowSummary(
                    targetSeason: 1,
                    window: .postseason,
                    completedAt: specialist.openedAt,
                    entrantCount: 1,
                    retainedCount: 0,
                    transferredCount: 1,
                    returnedCount: 0,
                    offerCount: 1
                )]
            )
            var hostile = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(state)
            ) as! [String: Any]
            let offPosition = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID,
                offerNILReservation: 500,
                destinationRosterOpenings: 1,
                destinationScholarshipOpenings: 1,
                destinationMinimumCoverageDeficits: [.quarterback: 1],
                position: .kicker
            )
            hostile["entries"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode([playerID: offPosition])
            )
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalState.self,
                    from: JSONSerialization.data(withJSONObject: hostile)
                )
                expect(false, "an off-position acceptance consumed reserved coverage")
            } catch {
                expect(true)
            }
        }

        test("persisted window records reject duplicate destinations and source transfers") {
            let sourceID = portalContractUUID(30)
            let destinationID = portalContractUUID(31)
            let record = portalWindowRecord(
                playerID: portalContractUUID(32),
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .spring,
                destinationProgrammeID: destinationID
            )
            let encoded = try JSONEncoder.stable().encode(record)
            let baseline = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

            var duplicateOffers = baseline
            let offers = duplicateOffers["offers"] as! [[String: Any]]
            duplicateOffers["offers"] = offers + offers

            var sourceTransfer = baseline
            sourceTransfer["outcome"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(
                    CollegePortalWindowOutcome.transferred(destinationProgrammeID: sourceID)
                )
            )

            for object in [duplicateOffers, sourceTransfer] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalWindowRecord.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an inconsistent portal record decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("intent reasoning and offer counts use centralized hostile-input bounds") {
            expectEqual(CollegeRules.maximumPortalOffersPerEntrant, 5)
            expectEqual(CollegeRules.maximumPortalOffersPerWindow, 1_500)
            expectEqual(CollegeRules.maximumPortalIntentComponentMagnitude, 20)
            expectEqual(CollegeRules.portalIntentTotalRange, -120...120)
            expectEqual(CollegeRules.portalIntentSelectionThreshold, 25)

            let intent = portalIntent(
                playerID: portalContractUUID(40),
                sourceProgrammeID: portalContractUUID(41),
                targetSeason: 1,
                window: .postseason,
                openedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            )
            let intentData = try JSONEncoder.stable().encode(intent)
            let intentBaseline = try JSONSerialization.jsonObject(with: intentData) as! [String: Any]

            var oversizedComponent = intentBaseline
            var components = oversizedComponent["components"] as! [[String: Any]]
            components[0]["value"] = CollegeRules.maximumPortalIntentComponentMagnitude + 1
            oversizedComponent["components"] = components

            var oversizedThreshold = intentBaseline
            oversizedThreshold["selectionThreshold"] = CollegeRules.portalIntentSelectionThreshold + 1

            var impossibleStarts = intentBaseline
            var evidence = impossibleStarts["evidence"] as! [String: Any]
            evidence["starts"] = 9
            impossibleStarts["evidence"] = evidence

            for object in [oversizedComponent, oversizedThreshold, impossibleStarts] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalIntentExplanation.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "unbounded portal intent decoded")
                } catch {
                    expect(true)
                }
            }

            let playerID = portalContractUUID(42)
            let sourceID = portalContractUUID(43)
            let record = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason
            )
            let recordData = try JSONEncoder.stable().encode(record)
            var tooManyOffers = try JSONSerialization.jsonObject(with: recordData) as! [String: Any]
            let offers = (0...CollegeRules.maximumPortalOffersPerEntrant).map { index in
                portalOffer(
                    playerID: playerID,
                    sourceProgrammeID: sourceID,
                    destinationProgrammeID: portalContractUUID(50 + index),
                    targetSeason: 1,
                    window: .postseason,
                    openedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks),
                    fitValue: 20 - index
                )
            }
            tooManyOffers["offers"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(offers)
            )
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalWindowRecord.self,
                    from: JSONSerialization.data(withJSONObject: tooManyOffers)
                )
                expect(false, "a portal record accepted more than five offers")
            } catch {
                expect(true)
            }
        }

        test("offers conserve their NIL formula and require positive fixed capacity") {
            let offer = portalOffer(
                playerID: portalContractUUID(60),
                sourceProgrammeID: portalContractUUID(61),
                destinationProgrammeID: portalContractUUID(62),
                targetSeason: 1,
                window: .postseason,
                openedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            )
            let data = try JSONEncoder.stable().encode(offer)
            let baseline = try JSONSerialization.jsonObject(with: data) as! [String: Any]

            var mismatchedNIL = baseline
            mismatchedNIL["nilReservation"] = 300

            var zeroRoster = baseline
            var zeroRosterCapacity = zeroRoster["fixedCapacity"] as! [String: Any]
            zeroRosterCapacity["rosterOpenings"] = 0
            zeroRoster["fixedCapacity"] = zeroRosterCapacity

            var zeroScholarship = baseline
            var zeroScholarshipCapacity = zeroScholarship["fixedCapacity"] as! [String: Any]
            zeroScholarshipCapacity["scholarshipOpenings"] = 0
            zeroScholarship["fixedCapacity"] = zeroScholarshipCapacity

            for object in [mismatchedNIL, zeroRoster, zeroScholarship] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalOffer.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an offer violated NIL or fixed capacity")
                } catch {
                    expect(true)
                }
            }

            let maximumSummary = CollegePortalWindowSummary(
                targetSeason: 1,
                window: .postseason,
                completedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks),
                entrantCount: CollegeRules.portalPoolLimit,
                retainedCount: CollegeRules.portalPoolLimit,
                transferredCount: 0,
                returnedCount: 0,
                offerCount: CollegeRules.maximumPortalOffersPerWindow
            )
            let summaryData = try JSONEncoder.stable().encode(maximumSummary)
            var excessiveSummary = try JSONSerialization.jsonObject(
                with: summaryData
            ) as! [String: Any]
            excessiveSummary["offerCount"] = CollegeRules.maximumPortalOffersPerWindow + 1

            var perEntrantExcess = excessiveSummary
            perEntrantExcess["entrantCount"] = 1
            perEntrantExcess["retainedCount"] = 1
            perEntrantExcess["offerCount"] = CollegeRules.maximumPortalOffersPerEntrant + 1

            for object in [excessiveSummary, perEntrantExcess] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalWindowSummary.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "a summary exceeded the five-offer entrant bound")
                } catch {
                    expect(true)
                }
            }
        }

        test("policy-v1 admission components rederive from compact immutable evidence") {
            let offer = portalOffer(
                playerID: portalContractUUID(63),
                sourceProgrammeID: portalContractUUID(64),
                destinationProgrammeID: portalContractUUID(65),
                targetSeason: 1,
                window: .postseason,
                openedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            )
            expectEqual(
                offer.destinationAdmission.components.map(\.value),
                [10, 5, 6, 5, 5, -7]
            )

            let data = try JSONEncoder.stable().encode(offer)
            let baseline = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var wrongFormula = baseline
            var explanation = wrongFormula["destinationAdmission"] as! [String: Any]
            var components = explanation["components"] as! [[String: Any]]
            components[0]["value"] = 11
            explanation["components"] = components
            wrongFormula["destinationAdmission"] = explanation

            var unboundEvidence = baseline
            var unboundExplanation = unboundEvidence["destinationAdmission"] as! [String: Any]
            var evidence = unboundExplanation["evidence"] as! [String: Any]
            evidence["estimatedOverall"] = 69
            unboundExplanation["evidence"] = evidence
            var reboundComponents = unboundExplanation["components"] as! [[String: Any]]
            reboundComponents[0]["value"] = 9
            unboundExplanation["components"] = reboundComponents
            unboundEvidence["destinationAdmission"] = unboundExplanation

            var missingKnowledgeAttribute = baseline
            var missingKnowledge = missingKnowledgeAttribute["knowledge"] as! [String: Any]
            var estimatedAttributes = missingKnowledge["estimatedAttributes"] as! [String: Any]
            estimatedAttributes.removeValue(forKey: Attribute.speed.rawValue)
            missingKnowledge["estimatedAttributes"] = estimatedAttributes
            missingKnowledgeAttribute["knowledge"] = missingKnowledge

            var mismatchedKnowledgeOverall = baseline
            var mismatchedKnowledge = mismatchedKnowledgeOverall["knowledge"] as! [String: Any]
            mismatchedKnowledge["estimatedOverall"] = 69
            mismatchedKnowledgeOverall["knowledge"] = mismatchedKnowledge

            let wideReceiverKnowledge = CollegePortalKnowledgeSnapshot(
                observerProgrammeID: offer.destinationProgrammeID,
                playerID: offer.knowledge.playerID,
                sourceProgrammeID: offer.knowledge.sourceProgrammeID,
                targetSeason: offer.knowledge.targetSeason,
                window: offer.knowledge.window,
                position: .wideReceiver,
                estimatedOverall: Rating(70),
                estimatedAttributes: Dictionary(uniqueKeysWithValues:
                    Position.wideReceiver.ratedAttributes.map { ($0, Rating(70)) }
                ),
                estimatedPotential: offer.knowledge.estimatedPotential,
                confidence: offer.knowledge.confidence,
                lastUpdated: offer.knowledge.lastUpdated,
                evidenceCount: offer.knowledge.evidenceCount
            )
            var unboundPosition = baseline
            unboundPosition["knowledge"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(wideReceiverKnowledge)
            )

            for object in [
                wrongFormula,
                unboundEvidence,
                missingKnowledgeAttribute,
                mismatchedKnowledgeOverall,
                unboundPosition,
            ] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalOffer.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "admission evidence or formula drift decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("durable portal derivations require a supported explicit policy version") {
            expectEqual(CollegeRules.portalPolicyVersion, 1)
            let record = portalWindowRecord(
                playerID: portalContractUUID(66),
                sourceProgrammeID: portalContractUUID(67),
                targetSeason: 1,
                window: .postseason
            )
            let data = try JSONEncoder.stable().encode(record)
            let baseline = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var missing = baseline
            missing.removeValue(forKey: "policyVersion")
            var unsupported = baseline
            unsupported["policyVersion"] = CollegeRules.portalPolicyVersion + 1

            for object in [missing, unsupported] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalWindowRecord.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an unversioned portal derivation decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("player preference and destination admission stay separate and canonical") {
            let playerID = portalContractUUID(70)
            let sourceID = portalContractUUID(71)
            let openedAt = CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            let preferred = portalOffer(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                destinationProgrammeID: portalContractUUID(72),
                targetSeason: 1,
                window: .postseason,
                openedAt: openedAt,
                fitValue: 20,
                admissionOverall: 40
            )
            let admitted = portalOffer(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                destinationProgrammeID: portalContractUUID(73),
                targetSeason: 1,
                window: .postseason,
                openedAt: openedAt,
                fitValue: 10,
                admissionOverall: 99
            )
            expect(preferred.playerFit.total > admitted.playerFit.total)
            expect(preferred.destinationAdmission.total < admitted.destinationAdmission.total)

            let record = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason
            )
            let recordData = try JSONEncoder.stable().encode(record)
            let recordBaseline = try JSONSerialization.jsonObject(with: recordData) as! [String: Any]

            var canonical = recordBaseline
            canonical["offers"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode([preferred, admitted])
            )
            _ = try JSONDecoder.stable().decode(
                CollegePortalWindowRecord.self,
                from: JSONSerialization.data(withJSONObject: canonical)
            )

            var admissionCorruption = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(preferred)
            ) as! [String: Any]
            var explanation = admissionCorruption["destinationAdmission"] as! [String: Any]
            var components = explanation["components"] as! [[String: Any]]
            components[0]["value"] = CollegeRules.maximumPortalAdmissionComponentMagnitude + 1
            explanation["components"] = components
            admissionCorruption["destinationAdmission"] = explanation

            var evidenceCorruption = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(preferred)
            ) as! [String: Any]
            var playerFit = evidenceCorruption["playerFit"] as! [String: Any]
            var destinationEvidence = playerFit["evidence"] as! [String: Any]
            destinationEvidence["destinationPositionRoomCount"] = CollegeRules.rosterLimit + 1
            playerFit["evidence"] = destinationEvidence
            evidenceCorruption["playerFit"] = playerFit

            var capacityCorruption = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(preferred)
            ) as! [String: Any]
            var capacity = capacityCorruption["fixedCapacity"] as! [String: Any]
            capacity["programmeID"] = sourceID.uuidString
            capacityCorruption["fixedCapacity"] = capacity

            var playerOrderCorruption = recordBaseline
            playerOrderCorruption["offers"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode([admitted, preferred])
            )

            for object in [admissionCorruption, evidenceCorruption, capacityCorruption] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalOffer.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "an inconsistent portal offer decoded")
                } catch {
                    expect(true)
                }
            }
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalWindowRecord.self,
                    from: JSONSerialization.data(withJSONObject: playerOrderCorruption)
                )
                expect(false, "offers were not canonicalized by player preference")
            } catch {
                expect(true)
            }
        }

        test("retention records distinguish intrinsic impossibility and preserve score causality") {
            let impossible = portalWindowRecord(
                playerID: portalContractUUID(78),
                sourceProgrammeID: portalContractUUID(79),
                targetSeason: 1,
                window: .postseason,
                sourceRosterNIL: 2_000
            )
            expect(impossible.retention.requiredAdditionalNIL == nil)
            expectEqual(impossible.retention.intentScoreAfterDecision, impossible.intent.total)

            let record = portalWindowRecord(
                playerID: portalContractUUID(80),
                sourceProgrammeID: portalContractUUID(81),
                targetSeason: 1,
                window: .postseason
            )
            let data = try JSONEncoder.stable().encode(record)
            let baseline = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            expectEqual(record.retention.requiredAdditionalNIL, 100)

            let retained = CollegePortalWindowRecord(
                policyVersion: CollegeRules.portalPolicyVersion,
                playerID: record.playerID,
                sourceProgrammeID: record.sourceProgrammeID,
                targetSeason: record.targetSeason,
                window: record.window,
                openedAt: record.openedAt,
                sourceWasScholarship: record.sourceWasScholarship,
                intent: record.intent,
                retention: CollegePortalRetentionResolution(
                    policyVersion: CollegeRules.portalPolicyVersion,
                    outcome: .retained,
                    requiredAdditionalNIL: 100,
                    appliedAdditionalNIL: 100,
                    sourceRosterNILAfterDecision: 200,
                    intentScoreAfterDecision: 24
                ),
                offers: [],
                outcome: .retainedBySource,
                finalIsScholarship: true,
                finalRosterNIL: 200
            )
            expectEqual(
                try JSONDecoder.stable().decode(
                    CollegePortalWindowRecord.self,
                    from: JSONEncoder.stable().encode(retained)
                ),
                retained
            )

            var falseReleasedScore = baseline
            var falseReleasedResolution = falseReleasedScore["retention"] as! [String: Any]
            falseReleasedResolution["intentScoreAfterDecision"] = 24
            falseReleasedScore["retention"] = falseReleasedResolution

            var falseRetained = baseline
            var falseRetainedResolution = falseRetained["retention"] as! [String: Any]
            falseRetainedResolution["outcome"] = CollegePortalRetentionOutcome.retained.rawValue
            falseRetainedResolution["requiredAdditionalNIL"] = NSNull()
            falseRetainedResolution["appliedAdditionalNIL"] = 0
            falseRetainedResolution["intentScoreAfterDecision"] = 24
            falseRetained["retention"] = falseRetainedResolution
            falseRetained["outcome"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(CollegePortalWindowOutcome.retainedBySource)
            )

            var falseRequired = baseline
            var falseRequiredResolution = falseRequired["retention"] as! [String: Any]
            falseRequiredResolution["requiredAdditionalNIL"] = 101
            falseRequired["retention"] = falseRequiredResolution

            for object in [falseReleasedScore, falseRetained, falseRequired] {
                do {
                    _ = try JSONDecoder.stable().decode(
                        CollegePortalWindowRecord.self,
                        from: JSONSerialization.data(withJSONObject: object)
                    )
                    expect(false, "a causally false retention record decoded")
                } catch {
                    expect(true)
                }
            }
        }

        test("roster NIL setters are atomic and zero removes the allocation") {
            let programmeID = portalContractUUID(100)
            let rosterPlayerID = portalContractUUID(101)
            let portalPlayerID = portalContractUUID(102)
            var ledger = ProgrammeNILState(
                programmeID: programmeID,
                season: 1,
                annualBudget: 1_000,
                rosterAllocations: [rosterPlayerID: 200],
                portalReservations: [portalPlayerID: 300]
            )

            let beforeFailure = try JSONEncoder.stable().encode(ledger)
            expect(!ledger.setRosterAllocation(800, for: rosterPlayerID))
            expectEqual(try JSONEncoder.stable().encode(ledger), beforeFailure)
            expect(!ledger.setRosterAllocation(100, for: portalPlayerID))
            expectEqual(try JSONEncoder.stable().encode(ledger), beforeFailure)

            expect(ledger.setRosterAllocation(400, for: rosterPlayerID))
            expectEqual(ledger.rosterAllocations[rosterPlayerID], 400)
            expectEqual(ledger.remaining, 300)
            expect(ledger.setRosterAllocation(0, for: rosterPlayerID))
            expect(ledger.rosterAllocations[rosterPlayerID] == nil)
            expectEqual(ledger.remaining, 700)
        }

        test("portal NIL reclassification preserves the exact promise and remaining budget") {
            let playerID = portalContractUUID(110)
            var ledger = ProgrammeNILState(
                programmeID: portalContractUUID(111),
                season: 1,
                annualBudget: 1_000,
                rosterAllocations: [portalContractUUID(112): 200],
                portalReservations: [playerID: 300]
            )
            let remainingBefore = ledger.remaining

            expect(ledger.reclassifyPortalReservation(for: playerID, expectedAmount: 300))
            expect(ledger.portalReservations[playerID] == nil)
            expectEqual(ledger.rosterAllocations[playerID], 300)
            expectEqual(ledger.remaining, remainingBefore)

            let zeroDollarPlayerID = portalContractUUID(113)
            expect(ledger.reclassifyPortalReservation(
                for: zeroDollarPlayerID,
                expectedAmount: 0
            ))
            expect(ledger.portalReservations[zeroDollarPlayerID] == nil)
            expect(ledger.rosterAllocations[zeroDollarPlayerID] == nil)
            expectEqual(ledger.remaining, remainingBefore)

            let fullRoster = Dictionary(uniqueKeysWithValues: (0..<CollegeRules.rosterLimit).map {
                (portalContractUUID(1_000 + $0), 1)
            })
            let overflowPlayerID = portalContractUUID(2_000)
            var fullLedger = ProgrammeNILState(
                programmeID: portalContractUUID(2_001),
                season: 1,
                annualBudget: 1_000,
                rosterAllocations: fullRoster,
                portalReservations: [overflowPlayerID: 1]
            )
            let beforeCapacityFailure = try JSONEncoder.stable().encode(fullLedger)
            expect(!fullLedger.reclassifyPortalReservation(
                for: overflowPlayerID,
                expectedAmount: 1
            ))
            expectEqual(
                try JSONEncoder.stable().encode(fullLedger),
                beforeCapacityFailure
            )

            var mismatchedLedger = ProgrammeNILState(
                programmeID: portalContractUUID(2_002),
                season: 1,
                annualBudget: 1_000,
                portalReservations: [playerID: 300]
            )
            let beforeMismatch = try JSONEncoder.stable().encode(mismatchedLedger)
            expect(!mismatchedLedger.reclassifyPortalReservation(
                for: playerID,
                expectedAmount: 200
            ))
            expectEqual(try JSONEncoder.stable().encode(mismatchedLedger), beforeMismatch)
            expect(!mismatchedLedger.reclassifyPortalReservation(
                for: playerID,
                expectedAmount: 0
            ))
            expectEqual(try JSONEncoder.stable().encode(mismatchedLedger), beforeMismatch)
        }

        test("player careers require explicit durable portal-window history") {
            let career = PlayerCareerRecord(
                playerID: portalContractUUID(3_000),
                portalWindows: []
            )
            let data = try JSONEncoder.stable().encode(career)
            var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            object.removeValue(forKey: "portalWindows")

            do {
                _ = try JSONDecoder.stable().decode(
                    PlayerCareerRecord.self,
                    from: JSONSerialization.data(withJSONObject: object)
                )
                expect(false, "a player career decoded without portal history")
            } catch {
                expect(true)
            }
        }

        test("a newly signed player without a completed season cannot enter the portal") {
            let playerID = portalContractUUID(3_005)
            var career = PlayerCareerRecord(playerID: playerID, portalWindows: [])
            let record = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: portalContractUUID(3_006),
                targetSeason: 1,
                window: .postseason
            )
            let before = try JSONEncoder.stable().encode(career)

            expect(!career.append(record))
            expectEqual(try JSONEncoder.stable().encode(career), before)
        }

        test("career portal records bind completed usage and a five-year clock span") {
            let playerID = portalContractUUID(3_007)
            let sourceID = portalContractUUID(3_008)
            var usageCareer = PlayerCareerRecord(
                playerID: playerID,
                seasons: [PlayerCareerSeason(
                    season: 0,
                    organisationID: sourceID,
                    tier: .college,
                    games: 7,
                    starts: 5,
                    overallAtEnd: Rating(70)
                )],
                portalWindows: []
            )
            let usageRecord = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason
            )
            let beforeUsage = try JSONEncoder.stable().encode(usageCareer)
            expect(!usageCareer.append(usageRecord))
            expectEqual(try JSONEncoder.stable().encode(usageCareer), beforeUsage)

            var spanCareer = PlayerCareerRecord(
                playerID: playerID,
                seasons: [
                    portalCareerSeason(season: 0, organisationID: sourceID),
                    portalCareerSeason(season: 5, organisationID: sourceID),
                ],
                portalWindows: []
            )
            expect(spanCareer.append(usageRecord))
            let beforeSpan = try JSONEncoder.stable().encode(spanCareer)
            expect(!spanCareer.append(portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 6,
                window: .postseason
            )))
            expectEqual(try JSONEncoder.stable().encode(spanCareer), beforeSpan)
        }

        test("zero source tenure is structural but only causal after a same-season transfer") {
            let playerID = portalContractUUID(3_009)
            let sourceID = portalContractUUID(3_010)
            let destinationID = portalContractUUID(3_011)
            let intent = portalIntent(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                openedAt: CalendarState(season: 0, week: SharedRules.inSeasonWeeks)
            )
            let intentData = try JSONEncoder.stable().encode(intent)
            var intentObject = try JSONSerialization.jsonObject(with: intentData) as! [String: Any]
            var evidence = intentObject["evidence"] as! [String: Any]
            evidence["seasonsAtSource"] = 0
            intentObject["evidence"] = evidence
            var components = intentObject["components"] as! [[String: Any]]
            let relationshipIndex = components.firstIndex {
                $0["reason"] as? String == CollegePortalIntentReason.relationship.rawValue
            }!
            components[relationshipIndex]["value"] = 0
            intentObject["components"] = components
            _ = try JSONDecoder.stable().decode(
                CollegePortalIntentExplanation.self,
                from: JSONSerialization.data(withJSONObject: intentObject)
            )

            var career = PlayerCareerRecord(
                playerID: playerID,
                seasons: [portalCareerSeason(season: 0, organisationID: sourceID)],
                portalWindows: []
            )
            let postseason = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason
            )
            expect(career.append(postseason))
            let before = try JSONEncoder.stable().encode(career)
            expect(!career.append(portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .spring,
                seasonsAtSource: 0
            )))
            expectEqual(try JSONEncoder.stable().encode(career), before)

            var transferCareer = PlayerCareerRecord(
                playerID: playerID,
                seasons: [portalCareerSeason(season: 0, organisationID: sourceID)],
                portalWindows: []
            )
            expect(transferCareer.append(portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID
            )))
            expect(transferCareer.append(portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: destinationID,
                targetSeason: 1,
                window: .spring,
                sourceRosterNIL: 200,
                seasonsAtSource: 0
            )))
        }

        test("spring evidence and career end chronology bind to the postseason result") {
            let playerID = portalContractUUID(3_013)
            let sourceID = portalContractUUID(3_014)
            let destinationID = portalContractUUID(3_015)
            let postseason = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID
            )
            var career = PlayerCareerRecord(
                playerID: playerID,
                seasons: [portalCareerSeason(season: 0, organisationID: sourceID)],
                portalWindows: [postseason]
            )
            let before = try JSONEncoder.stable().encode(career)
            expect(!career.append(portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: destinationID,
                targetSeason: 1,
                window: .spring,
                sourceRosterNIL: 100,
                seasonsAtSource: 0
            )))
            expectEqual(try JSONEncoder.stable().encode(career), before)

            let validSpring = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: destinationID,
                targetSeason: 1,
                window: .spring,
                sourceRosterNIL: 200,
                seasonsAtSource: 0
            )
            let springData = try JSONEncoder.stable().encode(validSpring)
            var springObject = try JSONSerialization.jsonObject(with: springData) as! [String: Any]
            springObject["sourceWasScholarship"] = false
            springObject["finalIsScholarship"] = false
            let falseScholarshipSpring = try JSONDecoder.stable().decode(
                CollegePortalWindowRecord.self,
                from: JSONSerialization.data(withJSONObject: springObject)
            )
            expect(!career.append(falseScholarshipSpring))
            expectEqual(try JSONEncoder.stable().encode(career), before)

            let ended = PlayerCareerRecord(
                playerID: playerID,
                seasons: [portalCareerSeason(season: 0, organisationID: sourceID)],
                portalWindows: [],
                endedAt: postseason.openedAt,
                endStatus: .graduated
            )
            let endedData = try JSONEncoder.stable().encode(ended)
            var endedObject = try JSONSerialization.jsonObject(with: endedData) as! [String: Any]
            endedObject["portalWindows"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode([postseason])
            )
            do {
                _ = try JSONDecoder.stable().decode(
                    PlayerCareerRecord.self,
                    from: JSONSerialization.data(withJSONObject: endedObject)
                )
                expect(false, "a portal window at career end decoded")
            } catch {
                expect(true)
            }
        }

        test("career portal windows append only in chronology and source-chain order") {
            let playerID = portalContractUUID(3_010)
            let sourceID = portalContractUUID(3_011)
            let destinationID = portalContractUUID(3_012)
            var career = PlayerCareerRecord(
                playerID: playerID,
                seasons: [
                    portalCareerSeason(season: 0, organisationID: sourceID),
                    portalCareerSeason(season: 1, organisationID: destinationID),
                ],
                portalWindows: []
            )
            let postseason = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID
            )
            let spring = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: destinationID,
                targetSeason: 1,
                window: .spring,
                sourceRosterNIL: 200,
                seasonsAtSource: 0
            )

            expect(career.append(postseason))
            expect(career.append(spring))
            expectEqual(career.portalWindows, [postseason, spring])

            let beforeDuplicate = try JSONEncoder.stable().encode(career)
            expect(!career.append(spring))
            expectEqual(try JSONEncoder.stable().encode(career), beforeDuplicate)

            let wrongSource = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 2,
                window: .postseason
            )
            expect(!career.append(wrongSource))
            expectEqual(try JSONEncoder.stable().encode(career), beforeDuplicate)
        }

        test("career portal history retains all ten legal windows and rejects an eleventh") {
            expectEqual(PeopleRules.portalWindowHistoryLimit, 10)
            let playerID = portalContractUUID(3_020)
            let sourceID = portalContractUUID(3_021)
            var career = PlayerCareerRecord(
                playerID: playerID,
                seasons: (0..<CollegeRules.eligibilityClockYears).map {
                    portalCareerSeason(season: $0, organisationID: sourceID)
                },
                portalWindows: []
            )
            for targetSeason in 1...CollegeRules.eligibilityClockYears {
                expect(career.append(portalWindowRecord(
                    playerID: playerID,
                    sourceProgrammeID: sourceID,
                    targetSeason: targetSeason,
                    window: .postseason
                )))
                expect(career.append(portalWindowRecord(
                    playerID: playerID,
                    sourceProgrammeID: sourceID,
                    targetSeason: targetSeason,
                    window: .spring
                )))
            }
            expectEqual(career.portalWindows.count, 10)

            let beforeOverflow = try JSONEncoder.stable().encode(career)
            expect(!career.append(portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: CollegeRules.eligibilityClockYears + 1,
                window: .postseason
            )))
            expectEqual(try JSONEncoder.stable().encode(career), beforeOverflow)
        }

        test("persisted career portal history rejects broken source chains") {
            let playerID = portalContractUUID(3_030)
            let sourceID = portalContractUUID(3_031)
            let destinationID = portalContractUUID(3_032)
            let first = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: destinationID
            )
            let wrongSecond = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .spring
            )
            let career = PlayerCareerRecord(
                playerID: playerID,
                seasons: [portalCareerSeason(season: 0, organisationID: sourceID)],
                portalWindows: [first]
            )
            let data = try JSONEncoder.stable().encode(career)
            var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            object["portalWindows"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode([first, wrongSecond])
            )

            do {
                _ = try JSONDecoder.stable().decode(
                    PlayerCareerRecord.self,
                    from: JSONSerialization.data(withJSONObject: object)
                )
                expect(false, "a broken career portal source chain decoded")
            } catch {
                expect(true)
            }
        }

        test("a player cannot record two transfers into the same target season") {
            let playerID = portalContractUUID(3_040)
            let sourceID = portalContractUUID(3_041)
            let firstDestinationID = portalContractUUID(3_042)
            let secondDestinationID = portalContractUUID(3_043)
            let first = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: sourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: firstDestinationID
            )
            let second = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: firstDestinationID,
                targetSeason: 1,
                window: .spring,
                destinationProgrammeID: secondDestinationID,
                sourceRosterNIL: 200,
                seasonsAtSource: 0
            )
            var career = PlayerCareerRecord(
                playerID: playerID,
                seasons: [portalCareerSeason(season: 0, organisationID: sourceID)],
                portalWindows: [first]
            )
            let before = try JSONEncoder.stable().encode(career)
            expect(!career.append(second))
            expectEqual(try JSONEncoder.stable().encode(career), before)

            var persisted = try JSONSerialization.jsonObject(with: before) as! [String: Any]
            persisted["portalWindows"] = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode([first, second])
            )
            do {
                _ = try JSONDecoder.stable().decode(
                    PlayerCareerRecord.self,
                    from: JSONSerialization.data(withJSONObject: persisted)
                )
                expect(false, "two same-season transfers decoded into one career")
            } catch {
                expect(true)
            }
        }
    }
}
