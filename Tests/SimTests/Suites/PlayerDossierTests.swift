import Foundation
import FootballSimCore

private func beat(
    season: Int = 1,
    week: Int,
    attribute: Attribute? = .speed,
    delta: Int,
    pressure: Int,
    reason: DevelopmentReason? = .coaching
) -> DevelopmentBeat {
    beat(
        at: CalendarState(season: season, week: week),
        attribute: attribute,
        delta: delta,
        pressure: pressure,
        reason: reason
    )
}

/// Dated from a world's own calendar rather than a literal.
///
/// A bootstrapped world starts at season zero, week one, and `WorldIntegrity` rejects a beat dated
/// ahead of the calendar — so any test that touches a real `GameState` has to place its beats
/// relative to that state, not at a week number chosen in advance.
private func beat(
    at calendar: CalendarState,
    attribute: Attribute? = .speed,
    delta: Int,
    pressure: Int,
    reason: DevelopmentReason? = .coaching
) -> DevelopmentBeat {
    DevelopmentBeat(
        occurredAt: calendar,
        attribute: delta == 0 ? nil : attribute,
        delta: delta,
        pressure: pressure,
        leadingReason: reason
    )
}

func runPlayerDossierTests() {
    suite("Development beat ring") {
        test("the ring is bounded and keeps the breakout over the plateau") {
            var record = PlayerCareerRecord(playerID: UUID(), portalWindows: [])
            // One real movement early, then a long tail of nothing. Chronological retention would
            // evict the only week worth remembering; ranked retention must keep it.
            record.recordDevelopmentBeat(beat(week: 1, delta: 1, pressure: 6))
            for week in 2...12 {
                record.recordDevelopmentBeat(
                    beat(week: week, attribute: nil, delta: 0, pressure: 0)
                )
            }

            expectEqual(record.developmentBeats.count, PeopleRules.developmentBeatLimit)
            expect(record.developmentBeats.contains { $0.delta == 1 })
        }

        test("a near miss outranks a flat nothing") {
            var record = PlayerCareerRecord(playerID: UUID(), portalWindows: [])
            for week in 1...PeopleRules.developmentBeatLimit {
                record.recordDevelopmentBeat(
                    beat(week: week, attribute: nil, delta: 0, pressure: 0)
                )
            }
            let nearMiss = beat(week: 20, attribute: nil, delta: 0, pressure: 4)
            let kept = record.recordDevelopmentBeat(nearMiss)

            expect(kept)
            expect(record.developmentBeats.contains(nearMiss))
            expectEqual(record.developmentBeats.count, PeopleRules.developmentBeatLimit)
        }

        test("a beat less significant than everything held is refused, not stored and evicted") {
            var record = PlayerCareerRecord(playerID: UUID(), portalWindows: [])
            for week in 1...PeopleRules.developmentBeatLimit {
                record.recordDevelopmentBeat(beat(week: week, delta: 1, pressure: 6))
            }
            let dull = beat(week: 30, attribute: nil, delta: 0, pressure: 0)

            expect(!record.recordDevelopmentBeat(dull))
            expect(!record.developmentBeats.contains(dull))
            expectEqual(record.developmentBeats.count, PeopleRules.developmentBeatLimit)
        }

        test("a decline is kept as readily as an equivalent gain") {
            var record = PlayerCareerRecord(playerID: UUID(), portalWindows: [])
            for week in 1...PeopleRules.developmentBeatLimit {
                record.recordDevelopmentBeat(
                    beat(week: week, attribute: nil, delta: 0, pressure: 1)
                )
            }
            let decline = beat(week: 25, delta: -1, pressure: -3)

            expect(record.recordDevelopmentBeat(decline))
            expect(record.developmentBeats.contains(decline))
        }

        test("the ring is stored chronologically whatever order it arrives in") {
            var forwards = PlayerCareerRecord(playerID: UUID(), portalWindows: [])
            var backwards = PlayerCareerRecord(playerID: UUID(), portalWindows: [])
            let weeks = [3, 9, 1, 14, 6, 11, 2]
            for week in weeks {
                forwards.recordDevelopmentBeat(beat(week: week, delta: 1, pressure: week))
            }
            for week in weeks.reversed() {
                backwards.recordDevelopmentBeat(beat(week: week, delta: 1, pressure: week))
            }

            let occurrences = forwards.developmentBeats.map(\.occurredAt.week)
            expectEqual(occurrences, occurrences.sorted())
            // Order of arrival must not change what a player remembers, or a save round-trip could.
            expectEqual(forwards.developmentBeats, backwards.developmentBeats)
        }

        test("a summary flattens to a beat that agrees with it") {
            let summary = DevelopmentSummary(
                occurredAt: CalendarState(season: 2, week: 8),
                components: [
                    DevelopmentComponent(reason: .coaching, value: 2),
                    DevelopmentComponent(reason: .workEthic, value: 1),
                ],
                attributeChanges: [AttributeDevelopment(attribute: .speed, delta: 1)]
            )
            let flattened = summary.beat

            expectEqual(flattened.occurredAt, summary.occurredAt)
            expectEqual(flattened.delta, summary.appliedDelta)
            expectEqual(flattened.pressure, summary.explainedDelta)
            expectEqual(flattened.attribute, .speed)
            expectEqual(flattened.leadingReason, .coaching)
            expect(!flattened.isMiss)
        }

        test("a summary that moved nothing flattens to a miss naming no attribute") {
            let summary = DevelopmentSummary(
                occurredAt: CalendarState(season: 2, week: 9),
                components: [DevelopmentComponent(reason: .decline, value: -1)],
                attributeChanges: []
            )

            expect(summary.beat.isMiss)
            expectEqual(summary.beat.attribute, nil)
            expectEqual(summary.beat.delta, 0)
        }
    }

    suite("Scouting snapshot at signing") {
        test("the band is clamped to the rating range and reports whether it held") {
            let snapshot = ProspectScoutingSnapshot(
                estimatedOverall: Rating(70),
                estimatedPotential: Rating(84),
                confidence: 60,
                errorRadius: 4
            )

            expectEqual(snapshot.estimatedOverallBand, 66...74)
            expect(snapshot.bandContained(Rating(74)))
            expect(!snapshot.bandContained(Rating(75)))
        }

        test("a band at the range edge cannot invert") {
            let snapshot = ProspectScoutingSnapshot(
                estimatedOverall: Rating(SharedRules.ratingRange.upperBound),
                estimatedPotential: Rating(SharedRules.ratingRange.upperBound),
                confidence: 10,
                errorRadius: 9
            )

            expect(snapshot.estimatedOverallBand.lowerBound
                <= snapshot.estimatedOverallBand.upperBound)
            expectEqual(
                snapshot.estimatedOverallBand.upperBound,
                SharedRules.ratingRange.upperBound
            )
        }
    }

    suite("Player dossier projection") {
        test("an unknown identifier has no dossier") {
            let state = GameState.bootstrap(seed: 77_101)
            expect(PlayerDossierReadModel.build(for: UUID(), in: state) == nil)
        }

        test("a generated player projects with identity and an empty history") {
            let state = GameState.bootstrap(seed: 77_102)
            let playerID = state.players.ids[0]
            let dossier = PlayerDossierReadModel.build(for: playerID, in: state)

            expect(dossier != nil)
            expectEqual(dossier?.playerID, playerID)
            expectEqual(dossier?.name, state.players[playerID]?.fullName)
            expectEqual(dossier?.position, state.players[playerID]?.position)
            expect(dossier?.isActive == true)
            expectEqual(dossier?.developmentBeats.count, 0)
            // Bootstrap players were never recruited, so there is nothing to claim about their fog.
            expect(dossier?.recruitment == nil)
            expect(dossier?.careerRatingDelta == nil)
        }

        test("the projection carries the ring the record holds") {
            var state = GameState.bootstrap(seed: 77_103)
            let playerID = state.players.ids[0]
            state.people.updatePlayerCareer(playerID) {
                $0.recordDevelopmentBeat(
                    beat(at: state.calendar, delta: 1, pressure: 7)
                )
                $0.recordDevelopmentBeat(
                    beat(at: state.calendar, attribute: nil, delta: 0, pressure: 1)
                )
            }
            let dossier = PlayerDossierReadModel.build(for: playerID, in: state)

            expectEqual(dossier?.developmentBeats.count, 2)
            expectEqual(dossier?.definingBeat?.delta, 1)
            expect(WorldIntegrity.check(state).isValid)
        }

        test("the projection is rebuilt from the save rather than stored in it") {
            var state = GameState.bootstrap(seed: 77_104)
            let playerID = state.players.ids[0]
            state.people.updatePlayerCareer(playerID) {
                $0.recordDevelopmentBeat(beat(at: state.calendar, delta: 1, pressure: 5))
            }
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            )

            expectEqual(restored, state)
            expectEqual(
                PlayerDossierReadModel.build(for: playerID, in: restored),
                PlayerDossierReadModel.build(for: playerID, in: state)
            )
        }

        test("integrity rejects a ring dated ahead of the calendar") {
            var state = GameState.bootstrap(seed: 77_105)
            let playerID = state.players.ids[0]
            let future = CalendarState(season: state.calendar.season + 5, week: 1)
            state.people.updatePlayerCareer(playerID) {
                $0.recordDevelopmentBeat(beat(at: future, delta: 1, pressure: 5))
            }

            expect(!WorldIntegrity.check(state).isValid)
        }
    }
}
