import Foundation
import FootballSimCore

// M7's last item. `02` §8 asked for a map that changes across a career; nothing moved it.
//
// Realignment is a swap rather than a migration, and the reason is structural: a conference holds 12
// to 16 programmes summing to 134, and schedule generation, standings, tiebreaks and whole-root
// topology integrity all read that shape. A one-way move makes one conference 11 and another 17. A
// swap leaves every conference exactly the size it was.

func runRealignmentTests() {
    suite("Realignment: the map changes without churning") {
        test("a swap leaves every conference the size it was") {
            let state = GameState.bootstrap(seed: 95_101)
            let before = conferenceSizes(in: state)
            let after = conferenceSizes(in: ConferenceRealignmentSystem.process(in: state))
            expectEqual(after, before, "realignment changed a conference's size")
        }

        test("every programme still belongs to exactly one conference") {
            let state = ConferenceRealignmentSystem.process(in: GameState.bootstrap(seed: 95_102))
            var seen: [UUID: Int] = [:]
            for conference in state.league.conferences(in: .college) {
                for memberID in conference.memberIDs { seen[memberID, default: 0] += 1 }
            }
            expectEqual(seen.count, CollegeRules.programmeCount)
            expect(seen.values.allSatisfy { $0 == 1 }, "a programme is in two conferences at once")
            for programme in state.programmes.values {
                let conference = state.league.conferences(in: .college)
                    .first { $0.memberIDs.contains(programme.id) }
                expectEqual(programme.conferenceID, conference?.id,
                            "\(programme.name)'s own conferenceID disagrees with the league")
            }
        }

        test("the root stays valid after realignment") {
            let state = ConferenceRealignmentSystem.process(in: GameState.bootstrap(seed: 95_103))
            let report = WorldIntegrity.check(state)
            expect(report.isValid,
                   "realignment produced an invalid root: "
                       + report.issues.prefix(3).map { "\($0)" }.joined(separator: " | "))
        }

        test("it is bounded, so the map changes without churning") {
            let before = GameState.bootstrap(seed: 95_104)
            let after = ConferenceRealignmentSystem.process(in: before)
            let moved = before.programmes.values.filter { programme in
                after.programmes[programme.id]?.conferenceID != programme.conferenceID
            }
            expect(moved.count <= CollegeRules.realignmentSwapsPerSeason * 2,
                   "\(moved.count) programmes moved, more than the swap bound allows")
        }

        test("the map settles, because a swap only happens when it improves fit") {
            // The rule has to be able to decline, or realignment is churn rather than pressure. Each
            // swap strictly lowers a total that cannot go below zero, so it must converge; this
            // asserts it actually does, and reports the season it stopped on.
            var state = GameState.bootstrap(seed: 95_105)
            var settledAfter: Int?
            for season in 0..<80 {
                let next = ConferenceRealignmentSystem.process(in: state)
                let moved = state.programmes.values.contains { programme in
                    next.programmes[programme.id]?.conferenceID != programme.conferenceID
                }
                if !moved { settledAfter = season; break }
                state = next
            }
            expect(settledAfter != nil,
                   "the map never stopped moving, so realignment is churn rather than pressure")
            // And it is still a legal league once it has settled.
            expectEqual(conferenceSizes(in: state),
                        conferenceSizes(in: GameState.bootstrap(seed: 95_105)),
                        "sizes drifted over many seasons of realignment")
        }

        test("two runs over the same world agree") {
            let state = GameState.bootstrap(seed: 95_106)
            let first = ConferenceRealignmentSystem.process(in: state)
            let second = ConferenceRealignmentSystem.process(in: state)
            expectEqual(
                first.programmes.values.map { $0.conferenceID?.uuidString ?? "" },
                second.programmes.values.map { $0.conferenceID?.uuidString ?? "" }
            )
        }

        test("typed transition matches the state-only API") {
            let before = GameState.bootstrap(seed: 95_107)
            let transition = ConferenceRealignmentSystem.processTransition(in: before)
            expectEqual(transition.state, ConferenceRealignmentSystem.process(in: before))
            expect(transition.swaps.count <= CollegeRules.realignmentSwapsPerSeason,
                   "typed transition exceeded the realignment bound")
            for swap in transition.swaps {
                expect(swap.firstProgrammeID != swap.secondProgrammeID,
                       "realignment swapped a programme with itself")
                expect(swap.firstFromConferenceID != swap.firstToConferenceID,
                       "first programme did not change conferences")
                expect(swap.secondFromConferenceID != swap.secondToConferenceID,
                       "second programme did not change conferences")
            }
        }
    }

    suite("Realignment: the map the slate is built from") {
        test("the slate the boundary installs is built from the map the boundary produced") {
            // `WorldScheduler` stated the ordering as a requirement — "the schedule is
            // generated from conference membership, so a swap has to land before it is read, not
            // after" — and nothing asserted it. Every test above works on a single call to
            // `ConferenceRealignmentSystem`; none of them walks a real season boundary, so none of
            // them can see where the boundary puts that call relative to the slate it feeds.
            //
            // Advance a real world through one boundary, then rebuild the installed slate from the
            // conference map that same boundary left behind. Identical inputs must reproduce it
            // exactly: `ScheduleGenerator` reads nothing from a programme but its id and its
            // conference, and sorts its members itself. A disagreement means the season the player
            // is about to play was drawn against a map that no longer exists.
            var state = GameState.bootstrap(seed: 95_108)
            let start = state
            while state.calendar.season == 0 {
                state = try WorldScheduler.advanceWeek(state).state
            }
            expectEqual(state.calendar, CalendarState(season: 1, week: 1))
            expectEqual(state.competition.currentSchedule.season, 1)

            let moved = start.programmes.values.filter {
                state.programmes[$0.id]?.conferenceID != $0.conferenceID
            }
            expect(!moved.isEmpty,
                   "no programme changed conference across this boundary, so this test asserts "
                       + "nothing; seed 95_108 needs replacing with one that realigns")

            let rebuilt = ScheduleGenerator.regularSeason(
                seed: state.league.seed,
                season: 1,
                programmes: state.programmes.values,
                proTeams: state.proTeams.values
            )
            let installedKeys = pairingKeys(state.competition.currentSchedule.games)
            let rebuiltKeys = pairingKeys(rebuilt)
            let stale = installedKeys.subtracting(rebuiltKeys)
            expect(stale.isEmpty,
                   "\(moved.count) programmes realigned and \(stale.count) of "
                       + "\(installedKeys.count) scheduled meetings are ones the current "
                       + "conference map does not produce, so the slate was generated before the "
                       + "swap landed")
        }
    }
}

/// Tier, week and the unordered pairing — everything about a meeting except which side is home
/// and the identifier the generator happened to mint for it.
private func pairingKeys(_ games: [ScheduledGame]) -> Set<String> {
    Set(games.map { game in
        let ordered = [game.homeID, game.awayID].sorted { $0.uuidString < $1.uuidString }
        return "\(game.tier.rawValue)|\(game.week)|\(ordered[0].uuidString)"
            + "|\(ordered[1].uuidString)"
    })
}

func conferenceSizes(in state: GameState) -> [Int] {
    state.league.conferences(in: .college)
        .sorted { $0.id.uuidString < $1.id.uuidString }
        .map(\.memberIDs.count)
}
