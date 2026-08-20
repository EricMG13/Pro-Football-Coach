import Foundation
import FootballSimCore

func runDisciplineTests() {
    suite("Discipline") {
        test("a suspension is an absence the rest of the game already understands") {
            // The whole integration: `isAvailable` is what depth charts, personnel packages and the
            // abstracted simulator read, so a suspended player stops playing without one of them
            // being taught what a suspension is.
            var lifecycle = PlayerLifecycleState(playerID: UUID())
            expect(lifecycle.isAvailable, "a healthy player is unavailable before anything happened")
            lifecycle.suspend(PlayerSuspension(
                reason: .teamRules,
                occurredAt: CalendarState(season: 0, week: 4),
                originalWeeks: 2,
                weeksRemaining: 2
            ))
            expect(!lifecycle.isAvailable, "a suspended player is still available to play")

            expect(!lifecycle.serveSuspensionWeek(), "a two-week suspension ended after one")
            expect(!lifecycle.isAvailable, "a player came back halfway through their suspension")
            expect(lifecycle.serveSuspensionWeek(), "a two-week suspension did not end after two")
            expect(lifecycle.isAvailable, "a served suspension left the player out")
            expect(lifecycle.suspension == nil, "a served suspension was kept")
        }

        test("serving time is not recovering from an injury") {
            // `recoverWeek`'s Bool drives `.playerRecovered`, so folding a suspension into it would
            // announce a recovery from an injury the player never had.
            var lifecycle = PlayerLifecycleState(playerID: UUID())
            lifecycle.suspend(PlayerSuspension(
                reason: .conduct,
                occurredAt: CalendarState(season: 0, week: 1),
                originalWeeks: 1,
                weeksRemaining: 1
            ))
            expect(!lifecycle.recoverWeek(), "a suspension reported itself as an injury recovery")
            expect(!lifecycle.isAvailable, "recoverWeek served a suspension week on its own")
        }

        test("a second suspension cannot quietly shorten the first") {
            var lifecycle = PlayerLifecycleState(playerID: UUID())
            let long = PlayerSuspension(
                reason: .offField,
                occurredAt: CalendarState(season: 0, week: 2),
                originalWeeks: 4,
                weeksRemaining: 4
            )
            lifecycle.suspend(long)
            lifecycle.suspend(PlayerSuspension(
                reason: .timekeeping,
                occurredAt: CalendarState(season: 0, week: 3),
                originalWeeks: 1,
                weeksRemaining: 1
            ))
            expectEqual(lifecycle.suspension, long,
                        "a one-week suspension replaced the four-week one already being served")
        }

        test("a suspension is bounded, and a corrupt one clamps rather than traps") {
            let absurd = PlayerSuspension(
                reason: .conduct,
                occurredAt: CalendarState(season: 0, week: 1),
                originalWeeks: 9_999,
                weeksRemaining: 9_999
            )
            expectEqual(absurd.originalWeeks, PeopleRules.maximumSuspensionWeeks,
                        "an unbounded suspension removes a player from the game by a screen")
            expectEqual(absurd.weeksRemaining, PeopleRules.maximumSuspensionWeeks)
            let negative = PlayerSuspension(
                reason: .conduct,
                occurredAt: CalendarState(season: 0, week: 1),
                originalWeeks: -3,
                weeksRemaining: -3
            )
            expectEqual(negative.originalWeeks, 1, "a suspension of no weeks is not a suspension")
            expectEqual(negative.weeksRemaining, 0)

            // Built by encoding a legal suspension and moving one number out of bounds, rather than
            // hand-written: a hand-written body that got the shape wrong would fail to decode for
            // the wrong reason and the test would still pass.
            let legal = PlayerSuspension(
                reason: .conduct,
                occurredAt: CalendarState(season: 0, week: 1),
                originalWeeks: 4,
                weeksRemaining: 4
            )
            guard let legalBytes = try? JSONEncoder.stable().encode(legal),
                  let legalText = String(data: legalBytes, encoding: .utf8) else {
                expect(false, "a legal suspension would not encode")
                return
            }
            expect((try? JSONDecoder().decode(PlayerSuspension.self, from: legalBytes)) != nil,
                   "a legal suspension would not decode")
            let corrupt = legalText.replacingOccurrences(of: "\"originalWeeks\":4",
                                                         with: "\"originalWeeks\":400")
            do {
                _ = try JSONDecoder().decode(PlayerSuspension.self, from: Data(corrupt.utf8))
                expect(false, "a suspension outside its legal bounds decoded")
            } catch {
                expect(true)
            }
        }

        test("the file is deterministic, and a rebuild does not reshuffle it") {
            let state = GameState.bootstrap(seed: 60_150)
            guard let programmeID = state.programmes.ids.sorted(by: {
                $0.uuidString < $1.uuidString
            }).first else {
                expect(false, "a bootstrapped world has no programme")
                return
            }
            let first = DisciplineSystem.incidents(at: programmeID, in: state)
            let second = DisciplineSystem.incidents(at: programmeID, in: state)
            expectEqual(first.map(\.id), second.map(\.id),
                        "the same week produced a different file twice")
            expectEqual(first.map(\.playerID), second.map(\.playerID))
            expect(first.allSatisfy { state.programmes[programmeID]?.rosterIDs.contains($0.playerID) == true },
                   "the file names somebody who is not on the roster")

            // A different week is a different draw, not the same one relabelled.
            var laterWeek = state
            laterWeek.calendar = CalendarState(season: state.calendar.season,
                                               week: state.calendar.week + 1)
            let later = DisciplineSystem.incidents(at: programmeID, in: laterWeek)
            expect(Set(first.map(\.id)).isDisjoint(with: Set(later.map(\.id))),
                   "two weeks share incident identities, so the file never changes")
        }

        test("a volatile player is likelier to be in the file than a settled one") {
            // The trait's named consumer. Measured over a season of weeks rather than asserted at
            // one, because a probability is not a fact about any single draw.
            var state = GameState.bootstrap(seed: 60_151)
            guard let programmeID = state.programmes.ids.sorted(by: {
                $0.uuidString < $1.uuidString
            }).first,
                let rosterIDs = state.programmes[programmeID]?.rosterIDs,
                rosterIDs.count > 8 else {
                expect(false, "a bootstrapped programme has no roster to draw from")
                return
            }
            let volatileIDs = Set(rosterIDs.prefix(rosterIDs.count / 2))
            for id in volatileIDs {
                state.players.update(id) { $0.add(.volatile) }
            }

            var volatileIncidents = 0
            var settledIncidents = 0
            for week in 1...CollegeRules.seasonWeeks {
                var weekState = state
                weekState.calendar = CalendarState(season: state.calendar.season, week: week)
                for incident in DisciplineSystem.incidents(at: programmeID, in: weekState) {
                    if volatileIDs.contains(incident.playerID) {
                        volatileIncidents += 1
                    } else {
                        settledIncidents += 1
                    }
                }
            }
            expect(volatileIncidents > settledIncidents,
                   "volatile players drew \(volatileIncidents) incidents against \(settledIncidents) "
                       + "for everybody else, so the trait's named system does not read it")
        }

        test("the coach decides, and handling it internally changes nothing") {
            let state = GameState.bootstrap(seed: 60_152)
            guard let programmeID = state.programmes.ids.first,
                  let playerID = state.programmes[programmeID]?.rosterIDs.first else {
                expect(false, "a bootstrapped world has no roster")
                return
            }
            let incident = DisciplineIncident(
                id: UUID(uuidString: "00000000-0000-4000-B400-000000000001")!,
                playerID: playerID,
                organisationID: programmeID,
                kind: .teamRules,
                occurredAt: state.calendar
            )
            do {
                let ignored = try DisciplineSystem.respond(
                    to: incident, with: .handleInternally, in: state
                )
                expectEqual(ignored.state, state, "handling it internally moved the world")
                expect(ignored.eventPayloads.isEmpty, "handling it internally made the news")
            } catch {
                expect(false, "a legal response threw: \(error)")
            }

            do {
                let suspended = try DisciplineSystem.respond(
                    to: incident, with: .suspend(weeks: 2), in: state
                )
                expectEqual(
                    suspended.state.people.playerLifecycle[playerID]?.suspension?.originalWeeks,
                    2
                )
                expect(suspended.state.people.playerLifecycle[playerID]?.isAvailable == false,
                       "a suspended player is still available")
                expectEqual(suspended.eventPayloads.count, 1)
                expect((suspended.eventPayloads.first?.historicalWeight ?? 0) > 0,
                       "a suspension scores zero, so the news feed will never report it")
                expect(WorldIntegrity.check(suspended.state).isValid,
                       "a suspension made the world invalid")

                // And being punished is felt.
                let before = PlayerMorale.reading(for: playerID, in: state).value
                let after = PlayerMorale.reading(for: playerID, in: suspended.state).value
                expect(after < before,
                       "a suspended player feels exactly the same about the place, so discipline is "
                           + "a free action")

                do {
                    _ = try DisciplineSystem.respond(
                        to: incident, with: .suspend(weeks: 1), in: suspended.state
                    )
                    expect(false, "a player was suspended twice over the same incident")
                } catch DisciplineError.alreadySuspended {
                    expect(true)
                }
            } catch {
                expect(false, "a legal suspension threw: \(error)")
            }

            do {
                _ = try DisciplineSystem.respond(
                    to: incident,
                    with: .suspend(weeks: PeopleRules.maximumSuspensionWeeks + 1),
                    in: state
                )
                expect(false, "a suspension longer than the maximum was accepted")
            } catch DisciplineError.invalidLength {
                expect(true)
            } catch {
                expect(false, "the wrong error came back: \(error)")
            }
        }

        test("a suspension survives a save and counts down on the weekly tick") {
            var state = GameState.bootstrap(seed: 60_153)
            guard let programmeID = state.programmes.ids.first,
                  let playerID = state.programmes[programmeID]?.rosterIDs.first else {
                expect(false, "a bootstrapped world has no roster")
                return
            }
            let incident = DisciplineIncident(
                id: UUID(uuidString: "00000000-0000-4000-B400-000000000002")!,
                playerID: playerID,
                organisationID: programmeID,
                kind: .conduct,
                occurredAt: state.calendar
            )
            do {
                state = try DisciplineSystem.respond(
                    to: incident, with: .suspend(weeks: 1), in: state
                ).state
                expectEqual(
                    try SaveEnvelope.decode(GameState.self, from: SaveEnvelope.encode(state)),
                    state,
                    "a suspension did not survive a round trip"
                )
            } catch {
                expect(false, "a legal suspension threw: \(error)")
                return
            }

            let transition = PeopleLifecycleSystem.processHealth(
                at: CalendarState(season: state.calendar.season, week: state.calendar.week + 1),
                in: state
            )
            expect(transition.people.playerLifecycle[playerID]?.suspension == nil,
                   "a one-week suspension outlived its week, so nobody ever comes back")
            expect(transition.people.playerLifecycle[playerID]?.isAvailable == true)
            expect(transition.eventPayloads.contains { payload in
                if case let .playerReinstated(id) = payload { return id == playerID }
                return false
            }, "coming back went unreported")
        }

        test("a world in which nobody is suspended encodes exactly as it did before") {
            // The additive-optional contract: `GameState.schemaVersion` decodes on an exact match
            // with no migration path, so a new field that appeared in every save would strand every
            // existing league.
            let state = GameState.bootstrap(seed: 60_154)
            guard let playerID = state.players.ids.first,
                  let lifecycle = state.people.playerLifecycle[playerID] else {
                expect(false, "a bootstrapped world has no players")
                return
            }
            let encoded = try? JSONEncoder.stable().encode(lifecycle)
            guard let encoded, let text = String(data: encoded, encoding: .utf8) else {
                expect(false, "a lifecycle record would not encode")
                return
            }
            expect(!text.contains("suspension"),
                   "an unsuspended player carries a suspension key, so every save grew")
        }
    }
}
