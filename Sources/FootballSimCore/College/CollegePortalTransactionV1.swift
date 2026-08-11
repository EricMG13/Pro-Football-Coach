import Foundation

public struct CollegePortalWindowTransition: Sendable, Equatable {
    public let state: GameState
    public let records: [CollegePortalWindowRecord]
    public let events: [DomainEvent]
    public let summary: CollegePortalWindowSummary

    fileprivate init(
        state: GameState,
        records: [CollegePortalWindowRecord],
        events: [DomainEvent],
        summary: CollegePortalWindowSummary
    ) {
        self.state = state
        self.records = records
        self.events = events
        self.summary = summary
    }
}

extension CollegePortalPolicyV1 {
    public static func commit(
        _ result: CollegePortalMatchingResult
    ) -> CollegePortalWindowTransition? {
        let source = result.sourceState
        guard result.targetSeason == source.college.recruitingSeason,
              result.window.expectedCalendar(targetSeason: result.targetSeason)
                == result.evaluatedAt,
              result.evaluatedAt == source.calendar,
              result.entrants.map(\.playerID).sorted(by: uuidRanksBefore)
                == result.entrants.map(\.playerID),
              Set(result.entrants.map(\.playerID)).count == result.entrants.count else {
            return nil
        }

        let predecessorIsValid: Bool
        switch result.window {
        case .postseason:
            predecessorIsValid = source.college.portal.phase == .closed
                && source.college.portal.entries.isEmpty
                && source.college.portal.summaries.isEmpty
        case .spring:
            predecessorIsValid = source.college.portal.phase == .awaitingSpring
                && source.college.portal.summaries.map(\.window) == [.postseason]
                && source.college.portal.entries.values.allSatisfy {
                    $0.window == .postseason
                }
        }
        guard predecessorIsValid else { return nil }

        var records: [CollegePortalWindowRecord] = []
        records.reserveCapacity(result.entrants.count)
        for entrant in result.entrants {
            guard let sourceProgramme = source.college.programmes[entrant.sourceProgrammeID],
                  let resolvedSourceProgramme = result.programmes[entrant.sourceProgrammeID]
            else { return nil }
            let sourceWasScholarship = sourceProgramme.scholarshipPlayerIDs.contains(
                entrant.playerID
            )
            let outcome: CollegePortalWindowOutcome
            let finalIsScholarship: Bool
            let finalRosterNIL: Int
            switch entrant.retention.outcome {
            case .retained:
                guard entrant.offers.isEmpty,
                      entrant.acceptedDestinationProgrammeID == nil else { return nil }
                outcome = .retainedBySource
                finalIsScholarship = sourceWasScholarship
                finalRosterNIL = resolvedSourceProgramme.nilState.rosterAllocations[
                    entrant.playerID
                ] ?? 0
            case .released:
                if let destinationID = entrant.acceptedDestinationProgrammeID {
                    guard let acceptedOffer = entrant.offers.first(where: {
                        $0.destinationProgrammeID == destinationID
                    }) else { return nil }
                    outcome = .transferred(destinationProgrammeID: destinationID)
                    finalIsScholarship = true
                    finalRosterNIL = acceptedOffer.nilReservation
                } else {
                    outcome = .returnedToSource
                    finalIsScholarship = sourceWasScholarship
                    finalRosterNIL = sourceProgramme.nilState.rosterAllocations[
                        entrant.playerID
                    ] ?? 0
                }
            }
            records.append(CollegePortalWindowRecord(
                policyVersion: version,
                playerID: entrant.playerID,
                sourceProgrammeID: entrant.sourceProgrammeID,
                targetSeason: result.targetSeason,
                window: result.window,
                openedAt: result.evaluatedAt,
                sourceWasScholarship: sourceWasScholarship,
                intent: entrant.intent,
                retention: entrant.retention,
                offers: entrant.offers,
                outcome: outcome,
                finalIsScholarship: finalIsScholarship,
                finalRosterNIL: finalRosterNIL
            ))
        }

        let summary = CollegePortalWindowSummary(
            targetSeason: result.targetSeason,
            window: result.window,
            completedAt: result.evaluatedAt,
            entrantCount: records.count,
            retainedCount: records.filter { $0.outcome == .retainedBySource }.count,
            transferredCount: records.filter {
                if case .transferred = $0.outcome { return true }
                return false
            }.count,
            returnedCount: records.filter { $0.outcome == .returnedToSource }.count,
            offerCount: records.reduce(0) { $0 + $1.offers.count }
        )

        var recruiting = result.programmes
        var outgoingByProgramme: [UUID: Set<UUID>] = [:]
        var incomingByProgramme: [UUID: [UUID]] = [:]
        for record in records {
            guard case let .transferred(destinationID) = record.outcome,
                  var sourceRecruiting = recruiting[record.sourceProgrammeID],
                  var destinationRecruiting = recruiting[destinationID]
            else { continue }
            if record.sourceWasScholarship {
                guard sourceRecruiting.removeScholarshipPlayer(record.playerID) else { return nil }
            } else if sourceRecruiting.scholarshipPlayerIDs.contains(record.playerID) {
                return nil
            }
            let removedSourceNIL = sourceRecruiting.removeRosterNILAllocation(
                for: record.playerID
            )
            guard record.intent.evidence.sourceRosterNIL == 0
                ? removedSourceNIL == nil
                : removedSourceNIL == record.intent.evidence.sourceRosterNIL else { return nil }
            guard destinationRecruiting.addScholarshipPlayer(record.playerID),
                  destinationRecruiting.reclassifyPortalNILReservation(
                      for: record.playerID,
                      expectedAmount: record.finalRosterNIL
                  ) else { return nil }
            recruiting[record.sourceProgrammeID] = sourceRecruiting
            recruiting[destinationID] = destinationRecruiting
            outgoingByProgramme[record.sourceProgrammeID, default: []].insert(record.playerID)
            incomingByProgramme[destinationID, default: []].append(record.playerID)
        }

        var programmes = source.programmes
        for programmeID in source.programmes.ids {
            guard var programme = programmes[programmeID],
                  let nextRecruiting = recruiting[programmeID] else { return nil }
            let outgoing = outgoingByProgramme[programmeID] ?? []
            let incoming = (incomingByProgramme[programmeID] ?? []).sorted(by: uuidRanksBefore)
            guard incoming.allSatisfy({ !programme.rosterIDs.contains($0) }) else { return nil }
            programme.rosterIDs = programme.rosterIDs.filter { !outgoing.contains($0) } + incoming
            programme.scholarshipCount = nextRecruiting.scholarshipPlayerIDs.count
            guard programme.rosterLegality.isLegal,
                  Set(programme.rosterIDs).count == programme.rosterIDs.count,
                  Set(nextRecruiting.scholarshipPlayerIDs).isSubset(of: Set(programme.rosterIDs)),
                  nextRecruiting.nilState.portalReservations.isEmpty else { return nil }
            guard programmes.update(programmeID, { $0 = programme }) else { return nil }
        }

        var people = source.people
        for record in records {
            var appended = false
            guard people.updatePlayerCareer(record.playerID, { career in
                appended = career.append(record)
            }), appended else { return nil }
        }

        let portal: CollegePortalState
        switch result.window {
        case .postseason:
            portal = CollegePortalState(
                targetSeason: result.targetSeason,
                phase: .awaitingSpring,
                entries: Dictionary(uniqueKeysWithValues: records.map { ($0.playerID, $0) }),
                summaries: [summary]
            )
        case .spring:
            portal = CollegePortalState(
                targetSeason: result.targetSeason,
                phase: .closed,
                entries: Dictionary(uniqueKeysWithValues: records.map { ($0.playerID, $0) }),
                summaries: source.college.portal.summaries + [summary]
            )
        }
        let college = CollegeState(
            recruitingSeason: source.college.recruitingSeason,
            portal: portal,
            phase: source.college.phase,
            programmes: recruiting,
            prospectRecruitment: source.college.prospectRecruitment,
            archivedProspects: source.college.archivedProspects,
            redshirtPlans: source.college.redshirtPlans
        )

        let payloads = portalEventPayloads(records: records, summary: summary)
        guard let firstSequence = source.history.firstSequence(forAppending: payloads.count) else {
            return nil
        }
        var events: [DomainEvent] = []
        events.reserveCapacity(payloads.count)
        for (offset, payload) in payloads.enumerated() {
            let (sequence, overflow) = firstSequence.addingReportingOverflow(offset)
            guard !overflow else { return nil }
            events.append(DomainEvent(
                id: DomainEvent.deterministicID(
                    rootSeed: source.league.seed,
                    sequence: sequence
                ),
                sequence: sequence,
                occurredAt: result.evaluatedAt,
                payload: payload
            ))
        }
        var history = source.history
        guard history.append(contentsOf: events) else { return nil }

        var state = source
        state.programmes = programmes
        state.history = history
        state.people = people
        state.college = college
        state.scouting = result.scouting
        state.college = CollegeCycleSystem.pruningArchivedProspects(in: state)

        var integrityProjection = state
        if result.window == .postseason {
            integrityProjection.calendar = CalendarState(season: result.targetSeason, week: 1)
            integrityProjection.league.season = result.targetSeason
            integrityProjection.league.week = 1
        }
        let integrity = WorldIntegrity.check(integrityProjection)
        let collegeProgrammeIDs = Set(state.programmes.ids)
        let blockingIssues = integrity.issues.filter { issue in
            if case let .missingPositionalCoverage(organisationID, _) = issue,
               collegeProgrammeIDs.contains(organisationID) {
                return false
            }
            return true
        }
        guard blockingIssues.isEmpty else { return nil }
        return CollegePortalWindowTransition(
            state: state,
            records: records,
            events: events,
            summary: summary
        )
    }

    private static func portalEventPayloads(
        records: [CollegePortalWindowRecord],
        summary: CollegePortalWindowSummary
    ) -> [DomainEventPayload] {
        records.map { record in
            .portalEntered(
                playerID: record.playerID,
                sourceProgrammeID: record.sourceProgrammeID,
                targetSeason: record.targetSeason,
                window: record.window,
                intent: record.intent
            )
        } + records.map { record in
            .portalRetentionResolved(
                playerID: record.playerID,
                sourceProgrammeID: record.sourceProgrammeID,
                targetSeason: record.targetSeason,
                window: record.window,
                resolution: record.retention
            )
        } + records.flatMap { record in
            record.offers.map { offer in
                .portalOfferMade(
                    playerID: record.playerID,
                    sourceProgrammeID: record.sourceProgrammeID,
                    targetSeason: record.targetSeason,
                    window: record.window,
                    offer: offer
                )
            }
        } + records.compactMap { record in
            guard case let .transferred(destinationProgrammeID) = record.outcome else {
                return nil
            }
            return .playerTransferred(
                playerID: record.playerID,
                sourceProgrammeID: record.sourceProgrammeID,
                destinationProgrammeID: destinationProgrammeID,
                targetSeason: record.targetSeason,
                window: record.window,
                sourceWasScholarship: record.sourceWasScholarship,
                finalNIL: record.finalRosterNIL
            )
        } + [.portalWindowCompleted(summary: summary)]
    }
}
