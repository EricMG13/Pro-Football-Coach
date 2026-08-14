import Foundation
import FootballSimCore

func runPreseasonCampTests() {
    suite("Preseason camp") {
        test("camp moves people, and it is the development pass rather than a second model") {
            let state = GameState.bootstrap(seed: 71_001)
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let camp = PreseasonCampSystem.hold(after: boundary, in: state)

            expect(!camp.eventPayloads.isEmpty, "camp developed nobody at all")
            var moved = 0
            for id in state.players.ids {
                guard let before = state.players[id], let after = camp.players[id] else { continue }
                for attribute in before.position.ratedAttributes {
                    let delta = after.attributes[attribute].value - before.attributes[attribute].value
                    expect(PeopleRules.attributeDevelopmentRange.contains(delta),
                           "camp moved an attribute by \(delta)")
                    // The same ceiling in-season development respects: camp cannot inflate a league
                    // past what its players could ever be.
                    expect(after.attributes[attribute].value <= before.potential.value || delta <= 0,
                           "camp pushed a player past their potential")
                    if delta != 0 { moved += 1 }
                }
            }
            expect(moved > 0, "camp changed nobody's ratings, so it is decoration")
        }

        test("camp does not credit last season's snaps") {
            // The one thing that separates camp from an in-season checkpoint: nobody has played
            // yet, so playing time cannot be a reason. A camp that read last season's statistics
            // would be rewarding a season that is already over.
            let state = GameState.bootstrap(seed: 71_002)
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let camp = PreseasonCampSystem.hold(after: boundary, in: state)
            var sawPlayingTime = false
            for id in state.players.ids {
                guard let summary = camp.people.playerLifecycle[id]?.lastDevelopment,
                      summary.occurredAt == boundary else { continue }
                if summary.components.contains(where: { $0.reason == .playingTime }) {
                    sawPlayingTime = true
                }
            }
            expect(!sawPlayingTime, "camp credited playing time nobody has had yet")
        }

        test("camp is deterministic") {
            let state = GameState.bootstrap(seed: 71_003)
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let first = PreseasonCampSystem.hold(after: boundary, in: state)
            let second = PreseasonCampSystem.hold(after: boundary, in: state)
            expectEqual(first, second, "two camps in the same world disagreed")
        }

        test("the report is read back off the receipt camp left") {
            var state = GameState.bootstrap(seed: 71_004)
            guard let programmeID = state.programmes.ids.sorted(by: {
                $0.uuidString < $1.uuidString
            }).first else {
                expect(false, "a bootstrapped world has no programme")
                return
            }
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let camp = PreseasonCampSystem.hold(after: boundary, in: state)
            state.players = camp.players
            state.people = camp.people

            let report = PreseasonCamp.report(for: programmeID, heldAt: boundary, in: state)
            expectEqual(report.organisationID, programmeID)
            expect(report.risers.count <= PeopleRules.maximumCampMovements,
                   "a report is a screen, not a census")
            expect(report.battles.count <= PeopleRules.maximumCampBattles)
            expect(report.risers.allSatisfy { $0.delta > 0 }, "a riser fell")
            expect(report.fallers.allSatisfy { $0.delta < 0 }, "a faller rose")
            expect(report.risers.allSatisfy {
                state.programmes[programmeID]?.rosterIDs.contains($0.playerID) == true
            }, "the report names somebody who is not on the roster")

            // Everyone it names actually moved, and the pre-camp figure is the current one with the
            // recorded delta taken back out.
            let preCamp = GameState.bootstrap(seed: 71_004)
            for movement in report.risers + report.fallers {
                guard let player = state.players[movement.playerID],
                      let before = preCamp.players[movement.playerID] else { continue }
                expectEqual(
                    PreseasonCamp.preCampOverall(player, heldAt: boundary, in: state),
                    before.overall.value,
                    "the reconstructed pre-camp overall disagrees with what the player actually was"
                )
            }

            let second = PreseasonCamp.report(for: programmeID, heldAt: boundary, in: state)
            expectEqual(report.risers.map(\.playerID), second.risers.map(\.playerID),
                        "a rebuilt report reshuffled")
        }

        test("a battle is a close job, and the report says whether camp decided it") {
            var state = GameState.bootstrap(seed: 71_005)
            guard let programmeID = state.programmes.ids.sorted(by: {
                $0.uuidString < $1.uuidString
            }).first,
                let rosterIDs = state.programmes[programmeID]?.rosterIDs else {
                expect(false, "a bootstrapped world has no programme")
                return
            }
            let boundary = CalendarState(season: state.calendar.season,
                                         week: SharedRules.inSeasonWeeks)
            let camp = PreseasonCampSystem.hold(after: boundary, in: state)
            state.players = camp.players
            state.people = camp.people

            let battles = PreseasonCamp.battles(rosterIDs: rosterIDs, heldAt: boundary, in: state)
            for battle in battles {
                expect(battle.gap <= PeopleRules.campBattleRatingGap,
                       "a battle was reported at a position \(battle.gap) points apart")
                expect(battle.gap >= 0, "the challenger is ahead of the leader")
                expect(battle.leaderID != battle.challengerID, "a player is fighting themselves")
                guard let leader = state.players[battle.leaderID],
                      let challenger = state.players[battle.challengerID] else {
                    expect(false, "a battle names somebody who does not exist")
                    continue
                }
                expectEqual(leader.position, battle.position)
                expectEqual(challenger.position, battle.position)
                expect(state.people.playerLifecycle[battle.leaderID]?.isAvailable == true,
                       "a player who cannot play was described as having won the job")
            }
            // Ordered closest-first, so the most open job leads.
            expectEqual(battles.map(\.gap), battles.map(\.gap).sorted(),
                        "the battles are not ordered by how open they are")
        }

        test("the first season has no camp to report, and says so rather than inventing one") {
            let state = GameState.bootstrap(seed: 71_006)
            expect(PreseasonCamp.heldAt(forSeasonIn: CalendarState(season: 0, week: 1)) == nil,
                   "the generated world claims it held a camp before it existed")
            expectEqual(
                PreseasonCamp.heldAt(forSeasonIn: CalendarState(season: 4, week: 1)),
                CalendarState(season: 3, week: SharedRules.inSeasonWeeks),
                "camp for a season is not stamped with the boundary it was held at"
            )
            guard let programmeID = state.programmes.ids.first else {
                expect(false, "a bootstrapped world has no programme")
                return
            }
            expect(PreseasonCamp.report(for: programmeID, in: state).isEmpty,
                   "the first season reported a camp nobody held")
        }

        test("a season boundary holds camp, and the week advances through it") {
            // The integration: camp is not a system somebody has to remember to call. Walked a week
            // at a time to the boundary rather than dropped there, because a state teleported to
            // week 21 has never played a season and the rollover reads what the season did.
            var state = GameState.bootstrap(seed: 71_007)
            var rolled = false
            do {
                for _ in 0..<(SharedRules.inSeasonWeeks + 1) {
                    let before = state.players
                    let startingSeason = state.calendar.season
                    let transition = try WorldScheduler.advanceWeek(state)
                    state = transition.state
                    guard state.calendar.season > startingSeason else { continue }
                    rolled = true
                    var moved = 0
                    for id in state.players.ids {
                        guard let old = before[id], let new = state.players[id] else { continue }
                        for attribute in old.position.ratedAttributes
                        where new.attributes[attribute].value != old.attributes[attribute].value {
                            moved += 1
                        }
                    }
                    expect(moved > 0,
                           "the season rolled over and nobody came out of camp any different")
                    expect(WorldIntegrity.check(state).isValid, "camp made the world invalid")
                    break
                }
            } catch {
                expect(false, "advancing to the season boundary threw: \(error)")
                return
            }
            expect(rolled, "twenty-two weeks did not reach a season boundary")
        }
    }
}
