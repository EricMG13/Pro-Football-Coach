import Foundation
import FootballSimCore

private func portalMatchingUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-4000-8008-%012X", value))!
}

private func portalMatchingPriorities(_ value: Int) -> [RecruitingPitch: Rating] {
    Dictionary(uniqueKeysWithValues: RecruitingPitch.allCases.map {
        ($0, Rating(value))
    })
}

private struct PortalMatchingFixture {
    var state: GameState
    let sourceProgrammeID: UUID
    let destinationProgrammeIDs: [UUID]
    let entrantIDs: [UUID]
}

private func portalMatchingFixture(
    entrantCount: Int = 1,
    destinationOpenings: [Int] = [1],
    destinationNIL: [Int] = [1_000],
    destinationRanks: [Int]? = nil,
    destinationPrestige: [Int]? = nil,
    destinationStaff: [Int]? = nil,
    destinationQuarterbackRooms: [Int]? = nil,
    firstEntrantPriorities: [RecruitingPitch: Rating]? = nil
) -> PortalMatchingFixture {
    precondition(entrantCount > 0)
    precondition(destinationOpenings.count == destinationNIL.count)
    var state = GameState.bootstrap(seed: 96_001)
    let programmeIDs = state.programmes.ids
    let sourceID = programmeIDs[0]
    let destinationIDs = Array(programmeIDs.dropFirst().prefix(destinationOpenings.count))
    let entrantIDs = Array(
        state.programmes[sourceID]!.rosterIDs.sorted {
            $0.uuidString < $1.uuidString
        }.prefix(entrantCount)
    )

    for entrantID in entrantIDs {
        _ = state.players.update(entrantID) { player in
            player.position = .quarterback
            player.remove(.restless)
        }
        expect(state.people.updatePlayerCareer(entrantID) { career in
            expect(career.append(PlayerCareerSeason(
                season: 0,
                organisationID: sourceID,
                tier: .college,
                games: 8,
                starts: 5,
                overallAtEnd: Rating(70)
            )))
        })
    }

    if let firstEntrantPriorities, let firstEntrantID = entrantIDs.first {
        let originCityID = state.map.cities[0].id
        let contender = RecruitingCommitmentContenderContext(
            programmeID: sourceID,
            score: 60,
            explanation: [],
            relationshipInterest: 60,
            nilAllocation: 0,
            visitScheduled: false
        )
        let origin = PlayerRecruitingOrigin(
            originCityID: originCityID,
            commitmentHistory: [RecruitingCommitmentContext(
                committedAt: CalendarState(season: 0, week: 4),
                winner: contender
            )],
            signedAt: CalendarState(season: 0, week: 4),
            finalInterest: 60,
            finalNILAllocation: 0,
            overallAtSigning: Rating(70),
            recruitingPriorities: firstEntrantPriorities
        )
        let current = state.people.playerCareers[firstEntrantID]!
        let replacement = PlayerCareerRecord(
            playerID: firstEntrantID,
            recruitingOrigin: origin,
            seasons: current.seasons,
            portalWindows: current.portalWindows
        )
        state.people = PeopleState(
            playerLifecycle: Array(state.people.playerLifecycle.values),
            playerCareers: state.people.playerCareers.map { playerID, career in
                playerID == firstEntrantID ? replacement : career
            },
            staffCareers: Array(state.people.staffCareers.values),
            departedPlayers: Array(state.people.departedPlayers.values)
        )
        for destinationID in destinationIDs {
            let identity = state.identities[destinationID]!
            state.identities[destinationID] = TeamIdentity(
                colours: identity.colours,
                venueName: identity.venueName,
                traditions: identity.traditions,
                homeCityID: originCityID
            )
        }
    }

    for (index, destinationID) in destinationIDs.enumerated() {
        let openings = destinationOpenings[index]
        let destination = state.programmes[destinationID]!
        var removalCounts = Dictionary(grouping: destination.rosterIDs.compactMap {
            state.players[$0]?.position
        }, by: { $0 }).mapValues(\.count)
        var removedForOpenings: [UUID] = []
        for playerID in destination.rosterIDs.reversed() where removedForOpenings.count < openings {
            guard let position = state.players[playerID]?.position,
                  (removalCounts[position] ?? 0)
                    > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
            else { continue }
            removalCounts[position, default: 0] -= 1
            removedForOpenings.append(playerID)
        }
        precondition(removedForOpenings.count == openings)
        let removedSet = Set(removedForOpenings)
        _ = state.programmes.update(destinationID) { programme in
            programme.rosterIDs.removeAll(where: removedSet.contains)
            programme.scholarshipCount = max(0, CollegeRules.scholarshipLimit - openings)
            if let prestige = destinationPrestige?[index] {
                programme.prestige = Rating(prestige)
            }
        }
        if let roomCount = destinationQuarterbackRooms?[index],
           let destination = state.programmes[destinationID] {
            var counts = Dictionary(grouping: destination.rosterIDs.compactMap {
                state.players[$0]?.position
            }, by: { $0 }).mapValues(\.count)
            let existingQuarterbacks = destination.rosterIDs.filter {
                state.players[$0]?.position == .quarterback
            }
            for playerID in existingQuarterbacks {
                _ = state.players.update(playerID) { $0.position = .runningBack }
                counts[.quarterback, default: 0] -= 1
                counts[.runningBack, default: 0] += 1
            }
            var selected = Array(existingQuarterbacks.prefix(roomCount))
            if selected.count < roomCount {
                for playerID in destination.rosterIDs where selected.count < roomCount {
                    guard !selected.contains(playerID),
                          let position = state.players[playerID]?.position,
                          (counts[position] ?? 0)
                            > (SharedRules.minimumPlayableRosterByPosition[position] ?? 0)
                    else { continue }
                    counts[position, default: 0] -= 1
                    counts[.quarterback, default: 0] += 1
                    selected.append(playerID)
                }
            }
            precondition(selected.count == roomCount)
            for playerID in selected {
                _ = state.players.update(playerID) { $0.position = .quarterback }
            }
        }
        if let staffRating = destinationStaff?[index],
           let destination = state.programmes[destinationID] {
            for staffID in destination.staffIDs {
                _ = state.staff.update(staffID) {
                    $0.ratings[.recruiting] = Rating(staffRating)
                }
            }
        }
    }

    let requestedRanks = destinationRanks
        ?? destinationIDs.indices.map { $0 + 1 }
    precondition(requestedRanks.count == destinationIDs.count)
    var rankedSlots = Array<UUID?>(repeating: nil, count: programmeIDs.count)
    rankedSlots[100] = sourceID
    for (destinationID, rank) in zip(destinationIDs, requestedRanks) {
        precondition((1...programmeIDs.count).contains(rank))
        precondition(rankedSlots[rank - 1] == nil)
        rankedSlots[rank - 1] = destinationID
    }
    var remaining = programmeIDs.filter {
        $0 != sourceID && !destinationIDs.contains($0)
    }.makeIterator()
    let ranking = rankedSlots.map { $0 ?? remaining.next()! }
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
        let nilState: ProgrammeNILState
        if programme.id == sourceID {
            nilState = ProgrammeNILState(
                programmeID: programme.id,
                season: 1,
                annualBudget: entrantIDs.count * 99,
                rosterAllocations: Dictionary(uniqueKeysWithValues: entrantIDs.map {
                    ($0, 99)
                })
            )
        } else if let index = destinationIDs.firstIndex(of: programme.id) {
            nilState = ProgrammeNILState(
                programmeID: programme.id,
                season: 1,
                annualBudget: destinationNIL[index]
            )
        } else {
            nilState = ProgrammeNILState(
                programmeID: programme.id,
                season: 1,
                annualBudget: 0
            )
        }
        return (
            programme.id,
            ProgrammeRecruitingState(
                programmeID: programme.id,
                scholarshipPlayerIDs: Array(
                    programme.rosterIDs.prefix(programme.scholarshipCount)
                ),
                nilState: nilState
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
    return PortalMatchingFixture(
        state: state,
        sourceProgrammeID: sourceID,
        destinationProgrammeIDs: destinationIDs,
        entrantIDs: entrantIDs
    )
}

private func portalMatchingOffers(
    _ result: CollegePortalMatchingResult,
    destinationProgrammeID: UUID
) -> [(CollegePortalMatchedEntrant, CollegePortalOffer)] {
    result.entrants.compactMap { entrant in
        entrant.offers.first { $0.destinationProgrammeID == destinationProgrammeID }.map {
            (entrant, $0)
        }
    }
}

func runPortalMatchingTests() {
    suite("College portal matching v1") {
        test("v1 freezes pitch order and position knowledge attributes") {
            let expectedPitchOrder: [RecruitingPitch] = [
                .proximity,
                .prestige,
                .playingTime,
                .schemeFit,
                .relationship,
                .staffQuality,
                .teamSuccess,
                .nilOpportunity,
            ]
            expectEqual(CollegePortalPolicyV1.pitchOrder, expectedPitchOrder)
            expectEqual(
                CollegePortalPolicyV1.ratedAttributes(for: .quarterback),
                [
                    .speed, .strength, .agility, .durability,
                    .awareness, .schemeFit, .temperament, .workEthic, .clutch,
                    .accuracyShort, .accuracyMid, .accuracyDeep,
                    .armStrength, .decision, .poise,
                ]
            )
            expect(Position.allCases.allSatisfy {
                !CollegePortalPolicyV1.ratedAttributes(for: $0).isEmpty
            })
        }

        test("destination fit is exactly rederived from frozen evidence") {
            let evidence = CollegePortalDestinationEvidence(
                candidatePosition: .quarterback,
                origin: .known(cityID: portalMatchingUUID(1)),
                destinationHomeCityID: portalMatchingUUID(2),
                squaredCityDistance: 149_000,
                destinationPositionRoomCount: 2,
                positionTargetCount: 4,
                observedSchemeFit: Rating(99),
                priorityWeights: portalMatchingPriorities(99),
                prestige: Rating(99),
                recruitingStaffAverage: Rating(99),
                archivedFinalRankingPosition: 1
            )
            let components = CollegePortalPolicyV1.destinationFitComponents(
                for: evidence,
                nilAllocationAdjustment: 2
            )
            expectEqual(components.map(\.reason), RecruitingPitch.allCases)
            expectEqual(components.map(\.value), [9, 10, 8, 10, 0, 10, 10, 2])

            let explanation = CollegePortalDestinationFitExplanation(
                policyVersion: CollegePortalPolicyV1.version,
                playerID: portalMatchingUUID(3),
                programmeID: portalMatchingUUID(4),
                evidence: evidence,
                components: components,
                nilAllocationAdjustment: 2,
                knowledgeAdjustment: 0
            )
            expectEqual(explanation.total, 61)

            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(explanation)
            ) as! [String: Any]
            var tamperedComponents = object["components"] as! [[String: Any]]
            tamperedComponents[0]["value"] = 8
            object["components"] = tamperedComponents
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalDestinationFitExplanation.self,
                    from: JSONSerialization.data(withJSONObject: object)
                )
                expect(false, "formula-drifted portal fit decoded")
            } catch {
                expect(true)
            }
        }

        test("neutral portal origins use frozen seventy weights and neutral proximity") {
            let evidence = CollegePortalDestinationEvidence(
                candidatePosition: .quarterback,
                origin: .neutral,
                destinationHomeCityID: portalMatchingUUID(5),
                squaredCityDistance: nil,
                destinationPositionRoomCount: 2,
                positionTargetCount: 4,
                observedSchemeFit: Rating(99),
                priorityWeights: portalMatchingPriorities(70),
                prestige: Rating(99),
                recruitingStaffAverage: Rating(99),
                archivedFinalRankingPosition: 1
            )
            let components = CollegePortalPolicyV1.destinationFitComponents(
                for: evidence,
                nilAllocationAdjustment: 0
            )
            expectEqual(components.map(\.value), [3, 7, 5, 7, 0, 7, 7, 0])
        }

        test("destination admission is exactly rederived by frozen v1 constants") {
            let evidence = CollegePortalAdmissionEvidence(
                position: .quarterback,
                estimatedOverall: Rating(70),
                estimatedPotential: Rating(80),
                appearances: 8,
                fixedPositionRoomCount: 2,
                estimatedSchemeFit: Rating(99),
                confidence: 25
            )
            let components = CollegePortalPolicyV1.admissionComponents(for: evidence)
            expectEqual(components.map(\.reason), CollegePortalAdmissionReason.allCases)
            expectEqual(components.map(\.value), [10, 6, 6, 8, 10, -7])

            let explanation = CollegePortalDestinationAdmissionExplanation(
                policyVersion: CollegePortalPolicyV1.version,
                playerID: portalMatchingUUID(6),
                programmeID: portalMatchingUUID(7),
                evidence: evidence,
                components: components
            )
            var object = try JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(explanation)
            ) as! [String: Any]
            var tamperedComponents = object["components"] as! [[String: Any]]
            tamperedComponents[5]["value"] = -6
            object["components"] = tamperedComponents
            do {
                _ = try JSONDecoder.stable().decode(
                    CollegePortalDestinationAdmissionExplanation.self,
                    from: JSONSerialization.data(withJSONObject: object)
                )
                expect(false, "formula-drifted portal admission decoded")
            } catch {
                expect(true)
            }
        }

        test("sealed market owns authoritative retention priorities and knowledge") {
            var priorities = portalMatchingPriorities(40)
            priorities[.prestige] = Rating(99)
            let fixture = portalMatchingFixture(
                destinationQuarterbackRooms: [4],
                firstEntrantPriorities: priorities
            )
            let market = CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: fixture.state
            )!
            expect(!((market as Any) is any Encodable))
            expect(market.retainedPlayerIDs.isEmpty)
            expectEqual(market.releasedPlayerIDs, fixture.entrantIDs.sorted {
                $0.uuidString < $1.uuidString
            })

            let result = CollegePortalPolicyV1.match(using: market)!
            expect(!((result as Any) is any Encodable))
            expectEqual(result.entrants.count, 1)
            guard let entrant = result.entrants.first else {
                expect(false, "authoritative market omitted its released entrant")
                return
            }
            expectEqual(entrant.retention.outcome, .released)
            expectEqual(entrant.offers.count, 1)
            guard let offer = entrant.offers.first else {
                expect(false, "released entrant received no destination offer")
                return
            }
            expectEqual(offer.playerFit.evidence.priorityWeights, priorities)
            expectEqual(
                offer.playerFit.evidence.origin,
                .known(cityID: fixture.state.map.cities[0].id)
            )
            expectEqual(offer.playerFit.evidence.squaredCityDistance, 0)
            expectEqual(
                result.programmes[fixture.sourceProgrammeID]?.nilState.rosterAllocations[
                    entrant.playerID
                ],
                99
            )
        }

        test("willingness is top five per opening and losing reservations refund") {
            let fixture = portalMatchingFixture(
                entrantCount: 7,
                destinationOpenings: [1],
                destinationNIL: [1_000],
                destinationQuarterbackRooms: [4]
            )
            let destinationID = fixture.destinationProgrammeIDs[0]
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            let offered = portalMatchingOffers(result, destinationProgrammeID: destinationID)
            expectEqual(offered.count, 5)
            expect(result.entrants.allSatisfy { entrant in
                entrant.offers.count <= 5
                    && entrant.offers.allSatisfy {
                        $0.destinationProgrammeID != entrant.sourceProgrammeID
                    }
            })
            expect(offered.allSatisfy { $0.1.nilReservation == 200 })
            expectEqual(offered.reduce(0) { $0 + $1.1.nilReservation }, 1_000)

            let admissionOrder = result.entrants.compactMap { entrant
                -> (UUID, Int)? in
                guard let knowledge = result.scouting.portalKnowledge(
                    observerProgrammeID: destinationID,
                    playerID: entrant.playerID,
                    sourceProgrammeID: entrant.sourceProgrammeID,
                    targetSeason: 1,
                    window: .postseason
                ) else { return nil }
                let evidence = CollegePortalAdmissionEvidence(
                    position: knowledge.position,
                    estimatedOverall: knowledge.estimatedOverall,
                    estimatedPotential: knowledge.estimatedPotential,
                    appearances: entrant.intent.evidence.appearances,
                    fixedPositionRoomCount: 4,
                    estimatedSchemeFit: knowledge.estimatedAttributes[.schemeFit]!,
                    confidence: knowledge.confidence
                )
                return (
                    entrant.playerID,
                    CollegePortalPolicyV1.admissionComponents(for: evidence)
                        .reduce(0) { $0 + $1.value }
                )
            }.sorted { lhs, rhs in
                lhs.1 == rhs.1
                    ? lhs.0.uuidString < rhs.0.uuidString
                    : lhs.1 > rhs.1
            }
            expectEqual(
                offered.map { $0.0.playerID }.sorted { $0.uuidString < $1.uuidString },
                admissionOrder.prefix(5).map(\.0).sorted { $0.uuidString < $1.uuidString }
            )
            let accepted = offered.filter {
                $0.0.acceptedDestinationProgrammeID == destinationID
            }
            expectEqual(accepted.map { $0.0.playerID }, [admissionOrder[0].0])
            expectEqual(
                result.programmes[destinationID]?.nilState.portalReservations,
                [admissionOrder[0].0: 200]
            )
        }

        test("capacity two retains the two best admissions after displacement") {
            var fixture = portalMatchingFixture(
                entrantCount: 4,
                destinationOpenings: [2],
                destinationNIL: [1_000],
                destinationQuarterbackRooms: [4]
            )
            let orderedIDs = fixture.entrantIDs.sorted { $0.uuidString < $1.uuidString }
            for (playerID, value) in zip(orderedIDs, [40, 50, 90, 99]) {
                _ = fixture.state.players.update(playerID) { player in
                    for attribute in player.position.ratedAttributes {
                        player.attributes[attribute] = Rating(value)
                    }
                    player.potential = Rating(value)
                }
            }
            let destinationID = fixture.destinationProgrammeIDs[0]
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            let offered = portalMatchingOffers(result, destinationProgrammeID: destinationID)
            expectEqual(offered.count, 4)
            let admissionOrder = offered.sorted { lhs, rhs in
                lhs.1.destinationAdmission.total == rhs.1.destinationAdmission.total
                    ? lhs.0.playerID.uuidString < rhs.0.playerID.uuidString
                    : lhs.1.destinationAdmission.total > rhs.1.destinationAdmission.total
            }
            let acceptedIDs = offered.compactMap {
                $0.0.acceptedDestinationProgrammeID == destinationID
                    ? $0.0.playerID
                    : nil
            }.sorted { $0.uuidString < $1.uuidString }
            expectEqual(
                acceptedIDs,
                admissionOrder.prefix(2).map { $0.0.playerID }.sorted {
                    $0.uuidString < $1.uuidString
                }
            )
            expectEqual(result.programmes[destinationID]?.nilState.portalReservations.count, 2)
            expectEqual(
                result.programmes[destinationID]?.nilState.portalReservations.values.reduce(0, +),
                400
            )
        }

        test("a rejected entrant continues to the next preferred destination") {
            let fixture = portalMatchingFixture(
                entrantCount: 2,
                destinationOpenings: [1, 1],
                destinationNIL: [1_000, 1_000],
                destinationRanks: [1, 134],
                destinationPrestige: [99, 40],
                destinationStaff: [99, 40],
                destinationQuarterbackRooms: [0, 10]
            )
            let preferredID = fixture.destinationProgrammeIDs[0]
            let fallbackID = fixture.destinationProgrammeIDs[1]
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            expect(result.entrants.allSatisfy {
                $0.offers.map(\.destinationProgrammeID).prefix(2)
                    == [preferredID, fallbackID]
            })
            let preferredOffers = portalMatchingOffers(
                result,
                destinationProgrammeID: preferredID
            ).sorted { lhs, rhs in
                lhs.1.destinationAdmission.total == rhs.1.destinationAdmission.total
                    ? lhs.0.playerID.uuidString < rhs.0.playerID.uuidString
                    : lhs.1.destinationAdmission.total > rhs.1.destinationAdmission.total
            }
            expectEqual(
                preferredOffers.first?.0.acceptedDestinationProgrammeID,
                preferredID
            )
            expectEqual(
                preferredOffers.last?.0.acceptedDestinationProgrammeID,
                fallbackID
            )
        }

        test("a reserved minimum-coverage opening rejects off-position admission") {
            var fixture = portalMatchingFixture(
                entrantCount: 2,
                destinationOpenings: [1],
                destinationNIL: [1_000],
                destinationQuarterbackRooms: [0]
            )
            let offPositionID = fixture.entrantIDs[0]
            let specialistID = fixture.entrantIDs[1]
            _ = fixture.state.players.update(offPositionID) { player in
                player.position = .runningBack
                for attribute in Position.runningBack.ratedAttributes {
                    player.attributes[attribute] = Rating(99)
                }
                player.potential = Rating(99)
            }
            _ = fixture.state.players.update(specialistID) { player in
                player.position = .quarterback
                for attribute in Position.quarterback.ratedAttributes {
                    player.attributes[attribute] = Rating(40)
                }
                player.potential = Rating(40)
            }

            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            let offPosition = result.entrants.first { $0.playerID == offPositionID }!
            let specialist = result.entrants.first { $0.playerID == specialistID }!
            expect(offPosition.offers[0].destinationAdmission.total
                > specialist.offers[0].destinationAdmission.total)
            expect(offPosition.acceptedDestinationProgrammeID == nil)
            expectEqual(
                specialist.acceptedDestinationProgrammeID,
                fixture.destinationProgrammeIDs[0]
            )
            expectEqual(
                specialist.offers[0].fixedCapacity.minimumCoverageDeficits,
                [.quarterback: 1]
            )
        }

        test("an outbound entrant does not create an opening at a full source") {
            var fixture = portalMatchingFixture(
                entrantCount: 2,
                destinationOpenings: [0, 1],
                destinationNIL: [1_000, 1_000],
                destinationQuarterbackRooms: [4, 4]
            )
            let originalSourceID = fixture.sourceProgrammeID
            let fullSourceID = fixture.destinationProgrammeIDs[0]
            let movedID = fixture.entrantIDs[1]
            _ = fixture.state.programmes.update(originalSourceID) {
                $0.rosterIDs.removeAll { $0 == movedID }
            }
            _ = fixture.state.programmes.update(fullSourceID) { programme in
                programme.rosterIDs.removeFirst()
                programme.rosterIDs.append(movedID)
            }
            _ = fixture.state.players.update(movedID) { $0.add(.restless) }
            let movedCareer = PlayerCareerRecord(
                playerID: movedID,
                seasons: [PlayerCareerSeason(
                    season: 0,
                    organisationID: fullSourceID,
                    tier: .college,
                    games: 0,
                    starts: 0,
                    overallAtEnd: Rating(70)
                )],
                portalWindows: []
            )
            fixture.state.people = PeopleState(
                playerLifecycle: Array(fixture.state.people.playerLifecycle.values),
                playerCareers: fixture.state.people.playerCareers.map { playerID, career in
                    playerID == movedID ? movedCareer : career
                },
                staffCareers: Array(fixture.state.people.staffCareers.values),
                departedPlayers: Array(fixture.state.people.departedPlayers.values)
            )
            for programmeID in [originalSourceID, fullSourceID] {
                _ = fixture.state.programmes.update(programmeID) { programme in
                    programme.scholarshipCount = min(
                        CollegeRules.scholarshipLimit,
                        programme.rosterIDs.count
                    )
                }
            }
            var programmes = fixture.state.college.programmes
            for programmeID in [originalSourceID, fullSourceID] {
                let programme = fixture.state.programmes[programmeID]!
                let allocationID = programmeID == originalSourceID
                    ? fixture.entrantIDs[0]
                    : movedID
                programmes[programmeID] = ProgrammeRecruitingState(
                    programmeID: programmeID,
                    scholarshipPlayerIDs: Array(
                        programme.rosterIDs.prefix(programme.scholarshipCount)
                    ),
                    nilState: ProgrammeNILState(
                        programmeID: programmeID,
                        season: 1,
                        annualBudget: 100,
                        rosterAllocations: [allocationID: 100]
                    )
                )
            }
            fixture.state.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(targetSeason: 1),
                programmes: programmes
            )
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            expect(result.entrants.contains { $0.playerID == movedID })
            let other = result.entrants.first { $0.playerID != movedID }!
            expect(!other.offers.contains {
                $0.destinationProgrammeID == fullSourceID
            })
        }

        test("spring forbids a second transfer in the same target season") {
            var fixture = portalMatchingFixture(destinationQuarterbackRooms: [4])
            let playerID = fixture.entrantIDs[0]
            let completedSourceID = fixture.destinationProgrammeIDs[0]
            let currentSourceID = fixture.sourceProgrammeID
            let postseason = portalWindowRecord(
                playerID: playerID,
                sourceProgrammeID: completedSourceID,
                targetSeason: 1,
                window: .postseason,
                destinationProgrammeID: currentSourceID,
                offerNILReservation: 200,
                destinationNILRemaining: 200
            )
            let career = PlayerCareerRecord(
                playerID: playerID,
                seasons: [PlayerCareerSeason(
                    season: 0,
                    organisationID: completedSourceID,
                    tier: .college,
                    games: 8,
                    starts: 5,
                    overallAtEnd: Rating(70)
                )],
                portalWindows: [postseason]
            )
            fixture.state.people = PeopleState(
                playerLifecycle: Array(fixture.state.people.playerLifecycle.values),
                playerCareers: fixture.state.people.playerCareers.map { existingID, existing in
                    existingID == playerID ? career : existing
                },
                staffCareers: Array(fixture.state.people.staffCareers.values),
                departedPlayers: Array(fixture.state.people.departedPlayers.values)
            )
            var programmes = fixture.state.college.programmes
            let current = programmes[currentSourceID]!
            programmes[currentSourceID] = ProgrammeRecruitingState(
                programmeID: currentSourceID,
                scholarshipPlayerIDs: current.scholarshipPlayerIDs,
                nilState: ProgrammeNILState(
                    programmeID: currentSourceID,
                    season: 1,
                    annualBudget: 200,
                    rosterAllocations: [playerID: 200]
                )
            )
            fixture.state.college = CollegeState(
                recruitingSeason: 1,
                portal: CollegePortalState(
                    targetSeason: 1,
                    phase: .awaitingSpring,
                    entries: [playerID: postseason],
                    summaries: [CollegePortalWindowSummary(
                        targetSeason: 1,
                        window: .postseason,
                        completedAt: CalendarState(
                            season: 0,
                            week: SharedRules.inSeasonWeeks
                        ),
                        entrantCount: 1,
                        retainedCount: 0,
                        transferredCount: 1,
                        returnedCount: 0,
                        offerCount: postseason.offers.count
                    )]
                ),
                programmes: programmes
            )
            fixture.state.calendar = CalendarState(season: 1, week: 1)
            fixture.state.league.season = 1
            fixture.state.league.week = 1
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .spring,
                    in: fixture.state
                )!
            )!
            let entrant = result.entrants.first { $0.playerID == playerID }!
            expectEqual(entrant.retention.outcome, .released)
            expect(entrant.offers.isEmpty)
            expect(entrant.acceptedDestinationProgrammeID == nil)
        }

        test("zero-dollar and capped offers conserve each fixed NIL snapshot") {
            let fixture = portalMatchingFixture(
                destinationOpenings: [1, 1],
                destinationNIL: [99, 9_900],
                destinationQuarterbackRooms: [4, 4]
            )
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            let entrant = result.entrants[0]
            let byDestination = Dictionary(uniqueKeysWithValues: entrant.offers.map {
                ($0.destinationProgrammeID, $0)
            })
            expectEqual(
                byDestination[fixture.destinationProgrammeIDs[0]]?.nilReservation,
                0
            )
            expectEqual(
                byDestination[fixture.destinationProgrammeIDs[1]]?.nilReservation,
                500
            )
            for destinationID in fixture.destinationProgrammeIDs {
                let offer = byDestination[destinationID]!
                let reserved = result.programmes[destinationID]?
                    .nilState.portalReservations[entrant.playerID]
                if entrant.acceptedDestinationProgrammeID == destinationID,
                   offer.nilReservation > 0 {
                    expectEqual(reserved, offer.nilReservation)
                } else {
                    expect(reserved == nil)
                }
                expect(offer.nilReservation <= offer.fixedCapacity.nilRemaining)
            }
        }

        test("player preference and destination admission remain separate in matching") {
            var priorities = portalMatchingPriorities(40)
            priorities[.prestige] = Rating(99)
            priorities[.staffQuality] = Rating(99)
            priorities[.teamSuccess] = Rating(99)
            let fixture = portalMatchingFixture(
                destinationOpenings: [1, 1],
                destinationNIL: [1_000, 1_000],
                destinationRanks: [1, 134],
                destinationPrestige: [99, 40],
                destinationStaff: [99, 40],
                destinationQuarterbackRooms: [10, 0],
                firstEntrantPriorities: priorities
            )
            let result = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: fixture.state
                )!
            )!
            let entrant = result.entrants[0]
            let preferred = entrant.offers.first {
                $0.destinationProgrammeID == fixture.destinationProgrammeIDs[0]
            }!
            let admitted = entrant.offers.first {
                $0.destinationProgrammeID == fixture.destinationProgrammeIDs[1]
            }!
            expect(preferred.playerFit.total > admitted.playerFit.total)
            expect(preferred.destinationAdmission.total < admitted.destinationAdmission.total)
            expectEqual(entrant.offers.first?.destinationProgrammeID, preferred.destinationProgrammeID)
            expectEqual(entrant.acceptedDestinationProgrammeID, preferred.destinationProgrammeID)
        }

        test("held markets isolate truth and shuffled stores preserve canonical results") {
            let fixture = portalMatchingFixture(
                entrantCount: 2,
                destinationOpenings: [1, 1],
                destinationNIL: [1_000, 1_000],
                destinationQuarterbackRooms: [4, 4]
            )
            let market = CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: fixture.state
            )!
            let baseline = CollegePortalPolicyV1.match(using: market)!

            var changedTruth = fixture.state
            for playerID in fixture.entrantIDs {
                _ = changedTruth.players.update(playerID) { player in
                    for attribute in player.position.ratedAttributes {
                        player.attributes[attribute] = Rating(99)
                    }
                    player.potential = Rating(99)
                }
            }
            expectEqual(CollegePortalPolicyV1.match(using: market), baseline)
            let fresh = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: changedTruth
                )!
            )!
            expect(fresh.scouting != baseline.scouting)

            var shuffled = fixture.state
            shuffled.programmes = EntityStore(shuffled.programmes.values.reversed())
            shuffled.players = EntityStore(shuffled.players.values.reversed())
            shuffled.staff = EntityStore(shuffled.staff.values.reversed())
            let shuffledResult = CollegePortalPolicyV1.match(using:
                CollegePortalPolicyV1.makeMarketSnapshot(
                    targetSeason: 1,
                    window: .postseason,
                    in: shuffled
                )!
            )!
            expectEqual(shuffledResult, baseline)
            expectEqual(
                try JSONEncoder.stable().encode(shuffledResult.entrants.flatMap(\.offers)),
                try JSONEncoder.stable().encode(baseline.entrants.flatMap(\.offers))
            )
            expectEqual(
                try JSONEncoder.stable().encode(shuffledResult.programmes),
                try JSONEncoder.stable().encode(baseline.programmes)
            )
        }

        test("corrupt ownership and unsafe coordinates reject without touching the root") {
            let fixture = portalMatchingFixture(destinationQuarterbackRooms: [4])
            var duplicateOwner = fixture.state
            _ = duplicateOwner.programmes.update(fixture.destinationProgrammeIDs[0]) {
                $0.rosterIDs.append(fixture.entrantIDs[0])
            }
            let duplicateBefore = try JSONEncoder.stable().encode(duplicateOwner)
            expect(CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: duplicateOwner
            ) == nil)
            expectEqual(try JSONEncoder.stable().encode(duplicateOwner), duplicateBefore)

            let homeCityID = fixture.state.identities[
                fixture.destinationProgrammeIDs[0]
            ]!.homeCityID
            let unsafeMap = GameMap(
                regions: fixture.state.map.regions,
                cities: fixture.state.map.cities.map { city in
                    city.id == homeCityID
                        ? MapCity(
                            id: city.id,
                            name: city.name,
                            regionID: city.regionID,
                            x: Int.max,
                            y: city.y,
                            marketSize: city.marketSize
                        )
                        : city
                }
            )
            let unsafe = GameState(
                league: fixture.state.league,
                map: unsafeMap,
                programmes: fixture.state.programmes,
                proTeams: fixture.state.proTeams,
                players: fixture.state.players,
                staff: fixture.state.staff,
                identities: fixture.state.identities,
                rivalries: fixture.state.rivalries,
                history: fixture.state.history,
                calendar: fixture.state.calendar,
                pending: fixture.state.pending,
                competition: fixture.state.competition,
                people: fixture.state.people,
                prospects: fixture.state.prospects,
                college: fixture.state.college,
                scouting: fixture.state.scouting
            )
            let unsafeBefore = try JSONEncoder.stable().encode(unsafe)
            expect(CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: unsafe
            ) == nil)
            expectEqual(try JSONEncoder.stable().encode(unsafe), unsafeBefore)
        }

        test("a stable market rejects stale portal NIL reservations atomically") {
            var fixture = portalMatchingFixture(destinationQuarterbackRooms: [4])
            let destinationID = fixture.destinationProgrammeIDs[0]
            let current = fixture.state.college.programmes[destinationID]!
            var programmes = fixture.state.college.programmes
            programmes[destinationID] = ProgrammeRecruitingState(
                programmeID: destinationID,
                scholarshipPlayerIDs: current.scholarshipPlayerIDs,
                nilState: ProgrammeNILState(
                    programmeID: destinationID,
                    season: 1,
                    annualBudget: current.nilState.annualBudget,
                    rosterAllocations: current.nilState.rosterAllocations,
                    recruitingReservations: current.nilState.recruitingReservations,
                    portalReservations: [portalMatchingUUID(90_001): 100]
                )
            )
            fixture.state.college = CollegeState(
                recruitingSeason: 1,
                portal: fixture.state.college.portal,
                programmes: programmes
            )
            let before = try JSONEncoder.stable().encode(fixture.state)
            expect(CollegePortalPolicyV1.makeMarketSnapshot(
                targetSeason: 1,
                window: .postseason,
                in: fixture.state
            ) == nil)
            expectEqual(try JSONEncoder.stable().encode(fixture.state), before)
        }
    }
}
