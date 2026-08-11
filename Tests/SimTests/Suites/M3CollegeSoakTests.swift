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
                expect(state.history.recent.count <= state.history.retentionLimit)
                expect(state.history.archivedCount >= 0)

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
