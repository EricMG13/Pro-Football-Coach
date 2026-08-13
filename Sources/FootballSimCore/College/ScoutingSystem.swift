import Foundation

public struct ScoutingTransition: Sendable, Equatable {
    public let scouting: ScoutingState
    public let eventPayloads: [DomainEventPayload]

    public init(scouting: ScoutingState, eventPayloads: [DomainEventPayload]) {
        self.scouting = scouting
        self.eventPayloads = eventPayloads
    }
}

public enum ScoutingSystem {
    public static func process(at calendar: CalendarState, in state: GameState) -> ScoutingTransition {
        guard state.college.portal.phase != .awaitingSpring else {
            return ScoutingTransition(scouting: state.scouting, eventPayloads: [])
        }
        var scouting = state.scouting
        var payloads: [DomainEventPayload] = []
        let assignments = scouting.pendingEvaluations.sorted {
            if $0.observerID != $1.observerID {
                return $0.observerID.uuidString < $1.observerID.uuidString
            }
            return $0.prospectID.uuidString < $1.prospectID.uuidString
        }

        for assignment in assignments {
            guard let programme = state.programmes[assignment.observerID],
                  let prospect = state.prospects[assignment.prospectID] else { continue }
            let previous = scouting.observation(
                observerID: assignment.observerID,
                prospectID: assignment.prospectID
            )
            let staffRatings = programme.staffIDs.compactMap { id in
                state.staff[id]?.rating(.recruiting).value
            }
            let staffQuality = staffRatings.isEmpty
                ? SharedRules.ratingRange.lowerBound
                : staffRatings.reduce(0, +) / staffRatings.count
            let evidenceGain = assignment.effort + max(1, staffQuality / 20)
            let evidence = min(
                CollegeRules.maximumScoutingEvidence,
                (previous?.evidenceCount ?? 0) + evidenceGain
            )
            let confidence = min(
                CollegeRules.maximumProspectKnowledgeConfidence,
                max(previous?.confidence ?? 0, (previous?.confidence ?? 0) + max(1, evidenceGain / 5))
            )
            var rng = SeededRandom(seed: observationSeed(
                root: state.league.seed,
                calendar: calendar,
                observerID: assignment.observerID,
                prospectID: assignment.prospectID
            ))
            // Derived from the confidence this observation will carry, so the band a surface draws
            // from `ProspectObservation.errorRadius` is the same width the estimate was sampled in.
            let errorRadius = ProspectObservation.errorRadius(forConfidence: confidence)
            let estimates = Dictionary(uniqueKeysWithValues: prospect.position.ratedAttributes.map {
                attribute in
                let truth = prospect.attributes[attribute].value
                return (attribute, Rating(truth + rng.int(in: -errorRadius...errorRadius)))
            })
            let observation = ProspectObservation(
                prospectID: prospect.id,
                estimatedAttributes: estimates,
                estimatedPotential: Rating(
                    prospect.potential.value + rng.int(in: -errorRadius...errorRadius)
                ),
                confidence: confidence,
                lastUpdated: calendar,
                evidenceCount: evidence
            )
            scouting.record(observation, observerID: assignment.observerID)
            payloads.append(.prospectEvaluated(
                observerID: assignment.observerID,
                prospectID: assignment.prospectID,
                confidence: confidence
            ))
        }
        scouting.clearPendingEvaluations()
        return ScoutingTransition(scouting: scouting, eventPayloads: payloads)
    }

    private static func observationSeed(
        root: UInt64,
        calendar: CalendarState,
        observerID: UUID,
        prospectID: UUID
    ) -> UInt64 {
        let season = SeededRandom.derive(from: root, scope: .season, ordinal: calendar.season)
        let week = SeededRandom.derive(from: season, scope: .week, ordinal: calendar.week)
        let observer = SeededRandom.derive(from: week, scope: .scouting, identifier: observerID)
        return SeededRandom.derive(from: observer, scope: .personnel, identifier: prospectID)
    }
}
