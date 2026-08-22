import Foundation
import FootballSimCore

func runM3CollegeSoakTests() {
    let requested = ProcessInfo.processInfo.environment["M3_SOAK_SEASONS"]
        .flatMap(Int.init) ?? 20
    precondition((1...20).contains(requested), "M3 soak seasons must be in 1...20.")

    suite("M3 college management soak") {
        testAsync("a delegated target-scale career remains legal and persistent") {
            var source = GameState.bootstrap(seed: 93_001)
            let programmeID = source.programmes.ids[0]
            source = try CareerControlSystem.startCollegeCareer(
                at: programmeID,
                in: source
            ).state
            let staffID = source.programmes[programmeID]!.staffIDs.first {
                source.staff[$0]?.role == .offensiveCoordinator
            }!
            for responsibility in CollegeCareerResponsibility.allCases {
                expect(CareerControlSystem.setResponsibility(
                    responsibility,
                    owner: .delegated(staffID: staffID),
                    in: &source
                ))
            }

            let session = try CareerSession(state: source)
            var projection = await session.projection()
            var weekDurations: [Double] = []
            var marketDurations: [Double] = []
            var classSizes: [Int] = []
            var portalOutcomes: [String: Int] = [:]
            var redshirtOutcomes: [RedshirtSeasonOutcome: Int] = [:]
            var saveSizes: [Int: Int] = [:]
            let checkpoints = Set([1, min(5, requested), requested])

            for targetSeason in 1...requested {
                while projection.calendar.season < targetSeason
                    || projection.calendar.week != 2 {
                    let started = Date.timeIntervalSinceReferenceDate
                    projection = try await session.resolve(.advanceWeek).projection
                    weekDurations.append(Date.timeIntervalSinceReferenceDate - started)
                }

                let data = try await session.saveData()
                let state = try SaveEnvelope.decode(GameState.self, from: data)
                let completedSeason = targetSeason - 1
                expect(
                    data.count <= 8 * 1024 * 1024,
                    "save is \(data.count) B at season \(targetSeason), over the 8 MB D4 ceiling"
                )
                expectEqual(state.calendar, CalendarState(season: targetSeason, week: 2))
                expectEqual(state.college.portal.phase, .closed)
                expectEqual(state.prospects.count, CollegeRules.annualProspectCount)
                expect(state.pending.mandatoryDecisions.isEmpty)
                expect(WorldIntegrity.check(state).isValid)

                let marketStarted = Date.timeIntervalSinceReferenceDate
                _ = CollegeRecruitingMarketSystem.process(at: state.calendar, in: state)
                marketDurations.append(Date.timeIntervalSinceReferenceDate - marketStarted)

                let origins = state.people.playerCareers.values.compactMap(\.recruitingOrigin)
                    .filter { $0.signingSeason == completedSeason }
                let signedByProgramme = Dictionary(grouping: origins, by: \.programmeID)
                classSizes.append(contentsOf: signedByProgramme.values.map(\.count))
                expect(!origins.isEmpty, "a completed recruiting cycle signed nobody")
                expect(
                    signedByProgramme.count >= CollegeRules.programmeCount * 3 / 4,
                    "fewer than three quarters of programmes signed a class"
                )

                for programme in state.college.programmes.values {
                    expect(programme.scholarshipPlayerIDs.count <= CollegeRules.scholarshipLimit)
                    expect(programme.nilState.remaining >= 0)
                    expectEqual(programme.nilState.season, targetSeason)
                }

                let windows = state.people.playerCareers.values.flatMap(\.portalWindows).filter {
                    $0.targetSeason == targetSeason
                }
                expect(windows.count <= CollegeRules.portalPoolLimit * CollegeRules.portalWindowCount)
                for record in windows {
                    switch record.outcome {
                    case .retainedBySource:
                        portalOutcomes["retained", default: 0] += 1
                    case .returnedToSource:
                        portalOutcomes["returned", default: 0] += 1
                    case .transferred:
                        portalOutcomes["transferred", default: 0] += 1
                    }
                }

                let collegeSeasons = state.people.playerCareers.values.flatMap(\.seasons).filter {
                    $0.tier == .college && $0.season == completedSeason
                }
                for season in collegeSeasons {
                    if let outcome = season.redshirtResolution?.outcome {
                        redshirtOutcomes[outcome, default: 0] += 1
                    }
                }
                expect(!collegeSeasons.isEmpty)

                let collegeOverall = state.programmes.values.flatMap(\.rosterIDs).compactMap {
                    state.players[$0]?.overall.value
                }
                expect((45...85).contains(collegeOverall.reduce(0, +) / collegeOverall.count))
                expect(state.programmes.values.flatMap(\.rosterIDs).allSatisfy {
                    (17...23).contains(state.players[$0]?.age ?? -1)
                })

                let hotReferencedIDs = Set(state.history.recent.flatMap {
                    $0.payload.referencedEntityIDs
                })
                let archivedReferencedIDs = Set(state.history.archive.flatMap {
                    $0.notableEvents.flatMap { $0.payload.referencedEntityIDs }
                })
                let archivedAwardPlayerIDs = Set(state.competition.archives.flatMap { archive in
                    archive.awards.compactMap { award in
                        award.kind == .playerOfTheYear ? award.winnerID : nil
                    }
                })
                let durablePlayerIDs = Set(state.people.playerCareers.compactMap { id, career in
                    career.recruitingOrigin != nil || !career.portalWindows.isEmpty ? id : nil
                })
                let retainedPlayerIDs = Set(state.players.ids)
                    .union(hotReferencedIDs)
                    .union(archivedReferencedIDs)
                    .union(archivedAwardPlayerIDs)
                    .union(durablePlayerIDs)
                let employedStaffIDs = Set(
                    state.programmes.values.flatMap(\.staffIDs)
                        + state.proTeams.values.flatMap(\.staffIDs)
                )
                var retainedStaffIDs = employedStaffIDs.union(hotReferencedIDs)
                    .union(archivedReferencedIDs)
                if let coachID = state.career.coachID {
                    retainedStaffIDs.insert(coachID)
                }
                let playerIdentityIDs = Set(state.players.ids)
                    .union(state.people.departedPlayers.keys)
                let archivedProspectIDs = Set(
                    (state.history.recent + state.history.archive.flatMap(\.notableEvents))
                        .flatMap { $0.payload.referencedProspectIDs }
                )
                    .subtracting(Set(state.prospects.ids))
                    .subtracting(playerIdentityIDs)

                expect(state.history.recent.count <= state.history.retentionLimit)
                expect(state.history.archive.count <= DomainEventLedger.maximumArchivedSeasons)
                expect(state.history.archive.allSatisfy {
                    $0.notableEvents.count <= SeasonHistoryDigest.maximumNotableEvents
                })
                expect(state.competition.archives.count <= CompetitionState.archiveLimit)
                expect(state.rivalries.values.allSatisfy {
                    $0.notableMeetings.count <= Rivalry.notableMeetingLimit
                })
                expectEqual(Set(state.people.playerLifecycle.keys), Set(state.players.ids))
                let departedPlayerIDs = Set(state.people.departedPlayers.keys)
                let exceptionalDepartedPlayerIDs = departedPlayerIDs.intersection(retainedPlayerIDs)
                expect(exceptionalDepartedPlayerIDs.subtracting(durablePlayerIDs).count
                    <= state.history.recent.count * 6
                        + state.competition.archives.count * Tier.allCases.count)
                expect(departedPlayerIDs.subtracting(exceptionalDepartedPlayerIDs).count
                    <= PeopleRules.maximumRetainedDepartedPlayers)
                expect(departedPlayerIDs.count <= PeopleRules.maximumRetainedDepartedPlayers
                    + exceptionalDepartedPlayerIDs.count)
                expectEqual(Set(state.people.playerCareers.keys),
                            Set(state.players.ids).union(departedPlayerIDs))
                expect(departedPlayerIDs.subtracting(exceptionalDepartedPlayerIDs).allSatisfy {
                    state.people.playerCareers[$0]?.recruitingOrigin == nil
                        && state.people.playerCareers[$0]?.portalWindows.isEmpty == true
                })
                expect(state.people.playerCareers.values.allSatisfy {
                    $0.seasons.count <= PeopleRules.careerSeasonHistoryLimit
                        && $0.portalWindows.count <= PeopleRules.portalWindowHistoryLimit
                })
                expect(state.people.playerLifecycle.values.allSatisfy {
                    $0.recentChanges.count <= PeopleRules.recentChangeHistoryLimit
                })
                expect(Set(state.staff.ids).isSubset(of: retainedStaffIDs))
                expectEqual(Set(state.people.staffCareers.keys), Set(state.staff.ids))
                expect(state.people.staffCareers.values.allSatisfy {
                    $0.assignments.count <= PeopleRules.careerSeasonHistoryLimit
                })
                expectEqual(Set(state.college.archivedProspects.keys), archivedProspectIDs)
                expect(state.career.mandatoryDecisionResolutions.count
                    <= CareerControlState.maximumMandatoryDecisionResolutions)
                expect(state.careerArc.jobHistory.count <= CareerArcState.maximumJobHistory)
                expect(state.careerArc.opportunities.count <= CareerArcState.maximumOpportunities)
                expect(state.pending.mandatoryDecisions.count
                    <= PendingQueues.maximumMandatoryDecisions)
                expect(state.college.portal.entries.count <= CollegePortalPolicyV1.maximumEntrants)
                expect(state.college.portal.summaries.count
                    <= CollegeRules.portalWindowCount)
                expect(state.people.playerCareers.values.flatMap(\.portalWindows).allSatisfy {
                    $0.offers.count <= CollegePortalPolicyV1.maximumOffersPerEntrant
                })
                expect(state.scouting.observationsByObserver.values.allSatisfy {
                    $0.count <= CollegeRules.maximumObservationsPerProgramme
                })
                expect(state.scouting.pendingEvaluations.count
                    <= CollegeRules.maximumPendingEvaluations)
                expect(state.scouting.portalKnowledgeByObserver.count
                    <= CollegePortalPolicyV1.maximumKnowledgeObservers)
                expect(state.scouting.portalKnowledgeByObserver.values.allSatisfy { snapshots in
                    snapshots.allSatisfy {
                            $0.targetSeason == state.college.portal.targetSeason
                        }
                        && Dictionary(grouping: snapshots, by: \.window).values.allSatisfy {
                            $0.count <= CollegePortalPolicyV1.maximumKnowledgePerObserverWindow
                        }
                })
                expect(state.tactical.plansByOrganisation.count <= TacticalState.maximumPlans)
                expect(state.tactical.practicePlansByOrganisation.count <= TacticalState.maximumPlans)
                expect(state.tactical.personnelPlansByOrganisation.count <= TacticalState.maximumPlans)
                expect(state.tactical.practiceReceiptsByOrganisation.count <= TacticalState.maximumPlans)
                expect(state.tactical.opponentScouting.count
                    <= TacticalState.maximumScoutingSnapshots)
                expect(state.tactical.opponentObservations.count
                    <= TacticalState.maximumOpponentObservations)
                expect(state.tactical.opponentObservations.values.allSatisfy {
                    $0.sourceGameIDs.count <= OpponentObservation.maximumSourceGames
                })
                expect(state.tactical.reviews.count <= TacticalState.maximumReviews)
                expect(state.proMarket.draftClass.count <= ProMarketState.maximumDraftClassSize)
                expect(state.proMarket.draftOrder.count <= ProRules.draftPickCount)
                expect(state.proMarket.draftedProspectIDs.count <= ProRules.draftPickCount)
                expect(state.proMarket.freeAgentIDs.count <= ProMarketState.maximumFreeAgentIDs)
                expect(state.proMarket.observations.count <= ProMarketState.maximumObservations)
                expect(state.proMarket.archivedDraftProspectIDs.count
                    <= ProMarketState.maximumArchivedProspectIDs)
                expect(state.proMarket.waivers.count <= ProMarketState.maximumWaivers)
                expect(state.proMarket.contractNegotiations.count
                    <= ProMarketState.maximumContractNegotiations)
                expect(state.proMarket.contractNegotiations.allSatisfy {
                    $0.offerHistory.count <= ProContractNegotiation.maximumOfferHistory
                })

                if checkpoints.contains(targetSeason) {
                    saveSizes[targetSeason] = data.count
                    expectEqual(try SaveEnvelope.decode(GameState.self, from: data), state)
                }
            }

            let sortedClassSizes = classSizes.sorted()
            let totalWeekTime = weekDurations.reduce(0, +)
            let totalMarketTime = marketDurations.reduce(0, +)
            print(
                "M3 soak: seasons=\(requested) weeks=\(weekDurations.count) "
                    + "weekTotal=\(totalWeekTime) weekMean=\(totalWeekTime / Double(weekDurations.count)) "
                    + "marketTotal=\(totalMarketTime) "
                    + "classMin=\(sortedClassSizes.first ?? 0) "
                    + "classMedian=\(sortedClassSizes[sortedClassSizes.count / 2]) "
                    + "classMax=\(sortedClassSizes.last ?? 0) "
                    + "portal=\(portalOutcomes) redshirts=\(redshirtOutcomes) saves=\(saveSizes)"
            )
        }
    }
}
