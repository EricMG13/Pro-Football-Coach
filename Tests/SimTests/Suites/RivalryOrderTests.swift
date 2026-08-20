import Foundation
import FootballSimCore

// The rival list is what a screen names and what D6's endogenous identity rests on. It was seeded
// once from geography and conference and never touched again, so a rivalry could become the most
// intense in the world while still sitting last in the list that names it. The weekly relationships
// step already adjusts intensity; these tests make it adjust the order that intensity implies.

func runRivalryOrderTests() {
    suite("Rivalry order: bounded replacement") {
        test("reorderRivals replaces the whole list and keeps it at its bound") {
            let rivals = (0..<12).map { _ in UUID() }
            var programme = orderFixtureProgramme(rivalIDs: Array(rivals.prefix(3)))
            programme.reorderRivals(to: rivals)
            expectEqual(programme.rivalIDs.count, SharedRules.rivalriesPerProgramme)
            expectEqual(programme.rivalIDs, Array(rivals.prefix(SharedRules.rivalriesPerProgramme)))
        }

        test("reorderRivals drops duplicates rather than spending the bound on them") {
            let first = UUID()
            let second = UUID()
            var programme = orderFixtureProgramme(rivalIDs: [])
            programme.reorderRivals(to: [first, second, first])
            expectEqual(programme.rivalIDs, [first, second])
        }

        test("reorderRivals to nothing empties the list") {
            var programme = orderFixtureProgramme(rivalIDs: [UUID(), UUID()])
            programme.reorderRivals(to: [])
            expect(programme.rivalIDs.isEmpty)
        }
    }

    suite("Rivalry order: earned intensity moves the list") {
        test("a played rivalry overtakes an equal one that was not played") {
            // Both rivalries start level, and the weaker tie-break puts the unplayed one first. Any
            // completed meeting is worth at least one intensity, so after one week the played
            // rivalry is strictly stronger whatever the margin was — no dependency on the score the
            // simulator happens to produce.
            let fixture = try orderFixtureState(seed: 70_301, playingGame: true)
            let transition = RivalrySystem.process(after: fixture.state.calendar, in: fixture.state)
            expectEqual(transition.recordedRivalryIDs, [fixture.playedRivalryID])
            expectEqual(
                transition.reorderedProgrammeIDs,
                [fixture.homeID, fixture.awayID].sorted { $0.uuidString < $1.uuidString },
                "both sides of the played rivalry are reordered, and nothing else is"
            )
        }

        test("the scheduler applies the reordering to the copied root") {
            let fixture = try orderFixtureState(seed: 70_302)
            let transition = try WorldScheduler.advanceWeek(fixture.state)
            let home = try requireOrderFixture(transition.state.programmes[fixture.homeID])
            expectEqual(
                home.rivalIDs,
                [fixture.awayID, fixture.thirdID],
                "the played rival must lead the list it was behind in"
            )
            let away = try requireOrderFixture(transition.state.programmes[fixture.awayID])
            expectEqual(away.rivalIDs, [fixture.homeID])
        }

        test("a programme whose rivalry was not played keeps the list it had") {
            let fixture = try orderFixtureState(seed: 70_303)
            let before = try requireOrderFixture(fixture.state.programmes[fixture.thirdID]).rivalIDs
            let transition = try WorldScheduler.advanceWeek(fixture.state)
            let after = try requireOrderFixture(transition.state.programmes[fixture.thirdID])
            expectEqual(after.rivalIDs, before,
                        "an untouched programme must not be rewritten by the weekly step")
        }

        test("two identical runs produce the same order") {
            let first = try orderFixtureState(seed: 70_304, playingGame: true)
            let second = try orderFixtureState(seed: 70_304, playingGame: true)
            let firstTransition = RivalrySystem.process(after: first.state.calendar, in: first.state)
            let secondTransition = RivalrySystem.process(
                after: second.state.calendar,
                in: second.state
            )
            expectEqual(firstTransition.reorderedProgrammeIDs, secondTransition.reorderedProgrammeIDs)
            expectEqual(firstTransition.rivalries, secondTransition.rivalries)
        }
    }

    suite("Rivalry order: the list a real season leaves behind") {
        // Every test above runs on a two- or three-programme fixture and a single week. None walks
        // a season, so none can see the list a real calendar leaves behind — and the weekly step
        // deliberately reorders only the sides of a rivalry that was actually played, which is a
        // correctness claim about the 133 programmes it skips, not just the one it touches.
        //
        // `rivalIDs` is not independent state: `LeagueGenerator` seeds it from
        // `RivalrySeeder.strongest` and the weekly step reinstalls it from the same function, so at
        // every week of every season it must equal exactly what the rivalry store implies. Anything
        // else is a stale list — wrong order, a dropped rival, a rival the store no longer holds —
        // and it is what a screen names.
        test("every programme's rival list is the one the store implies, all season and across the boundary") {
            var state = GameState.bootstrap(seed: 70_401)
            let seededRivalryCount = state.rivalries.values.count
            var violations: [String] = []
            var weeksWalked = 0

            // Check, then advance: the loop stops on the far side of the boundary so season 1
            // week 1 is inspected rather than merely reached.
            while true {
                let ranked = state.rivalries.values.sorted { $0.id.uuidString < $1.id.uuidString }
                for programme in state.programmes.values {
                    let implied = RivalrySeeder.strongest(for: programme.id, among: ranked)
                    guard programme.rivalIDs != implied else { continue }
                    violations.append(
                        "S\(state.calendar.season)W\(state.calendar.week) \(programme.name): "
                            + "holds \(programme.rivalIDs.count), store implies \(implied.count)"
                    )
                }
                // Stop at the first bad week: a stale list stays stale, so walking on would report
                // the same defect once per remaining week and bury anything else.
                if !violations.isEmpty || state.calendar.season > 0 { break }
                expectEqual(state.rivalries.values.count, seededRivalryCount,
                            "the rivalry store grew at S\(state.calendar.season)"
                                + "W\(state.calendar.week); nothing seeds new rivalries after "
                                + "generation and the store has no other bound")
                state = try WorldScheduler.advanceWeek(state).state
                weeksWalked += 1
            }

            // Not vacuous: the walk has to have inspected the far side of the boundary, not
            // merely stopped somewhere in season 0.
            expectEqual(state.calendar, CalendarState(season: 1, week: 1),
                        "the walk ended somewhere other than the far side of the boundary after "
                            + "\(weeksWalked) weeks, so it asserts nothing about a transition")
            expect(violations.isEmpty,
                   "\(violations.count) programmes hold a list the rivalry store does not imply, "
                       + "first \(violations.first ?? "")")
        }
    }
}

private enum RivalryOrderTestError: Error { case missingFixture }

private func requireOrderFixture<T>(_ value: T?) throws -> T {
    guard let value else { throw RivalryOrderTestError.missingFixture }
    return value
}

private func orderFixtureProgramme(rivalIDs: [UUID]) -> Programme {
    Programme(
        name: "Thornby Reach Technical",
        nickname: "Kestrels",
        cityName: "Thornby Reach",
        archetypeID: 0,
        scheme: SchemeIdentity(offense: .proStyle, defense: .fourThree),
        prestige: Rating(60),
        resources: Rating(60),
        fanbaseVolatility: Rating(60),
        academicConstraint: Rating(60),
        recruitingReach: Rating(60),
        rivalIDs: rivalIDs
    )
}

private struct RivalryOrderFixture {
    var state: GameState
    let homeID: UUID
    let awayID: UUID
    let thirdID: UUID
    let playedRivalryID: UUID
}

/// A root with exactly two rivalries: one for a college game that is played this week, one for a
/// third programme that is not.
///
/// The store is replaced rather than added to, the way `HistoryReadModelTests` does it, so the
/// assertions describe two rivalries rather than whatever geography seeded. Both start at the same
/// intensity and the unplayed one carries the lower UUID, so it leads on the tie-break until the
/// played one earns its way past.
///
/// `playingGame` records the meeting up front, which is what a direct `RivalrySystem.process` call
/// needs: the reducer only consumes games that already carry a result. The scheduler tests leave it
/// false because `advanceWeek` plays the week itself, and a pre-recorded result would be a second
/// one.
private func orderFixtureState(
    seed: UInt64,
    playingGame: Bool = false
) throws -> RivalryOrderFixture {
    var state = GameState.bootstrap(seed: seed)
    let game = try requireOrderFixture(state.competition.currentSchedule.games.first {
        $0.tier == .college && $0.week == state.calendar.week
    })
    let thirdID = try requireOrderFixture(state.programmes.ids.first {
        $0 != game.homeID && $0 != game.awayID
    })

    // Fixed identities, and the unplayed rivalry sorts first so the starting order is the one the
    // week has to change.
    let unplayedRivalryID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
    let playedRivalryID = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
    state.rivalries = EntityStore([
        Rivalry(
            id: playedRivalryID,
            sideA: game.homeID,
            sideB: game.awayID,
            origin: .conference,
            intensity: Rating(62)
        ),
        Rivalry(
            id: unplayedRivalryID,
            sideA: game.homeID,
            sideB: thirdID,
            origin: .conference,
            intensity: Rating(62)
        ),
    ])
    _ = state.programmes.update(game.homeID) { $0.reorderRivals(to: [thirdID, game.awayID]) }
    _ = state.programmes.update(game.awayID) { $0.reorderRivals(to: [game.homeID]) }
    _ = state.programmes.update(thirdID) { $0.reorderRivals(to: [game.homeID]) }

    if playingGame {
        let summary = AbstractGameSimulator.play(game, in: state)
        var schedule = state.competition.currentSchedule
        _ = try schedule.recordResults([ScheduledGameResult(gameID: game.id, summary: summary)])
        state.competition.currentSchedule = schedule
    }

    return RivalryOrderFixture(
        state: state,
        homeID: game.homeID,
        awayID: game.awayID,
        thirdID: thirdID,
        playedRivalryID: playedRivalryID
    )
}
