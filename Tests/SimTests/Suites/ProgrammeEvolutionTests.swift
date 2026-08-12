import Foundation
import FootballSimCore

// M7's programme evolution. Prestige was frozen at generation: a programme that won titles for a
// decade was exactly as prestigious as one that never won, while prestige drives recruiting pull,
// the AI's valuations and which jobs a coach is offered. A living world has to let that move.

func runProgrammeEvolutionTests() {
    suite("Programme evolution: prestige follows results") {
        test("finishing top of the table raises prestige, bottom lowers it") {
            let state = evolutionState(seed: 98_001)
            let ranking = state.competition.rankings[.college] ?? []
            let best = try requireEvolution(ranking.first)
            let worst = try requireEvolution(ranking.last)
            let beforeBest = try requireEvolution(state.programmes[best]?.prestige.value)
            let beforeWorst = try requireEvolution(state.programmes[worst]?.prestige.value)

            let evolved = ProgrammeEvolutionSystem.process(
                collegeRanking: ranking,
                proRanking: state.competition.rankings[.pro] ?? [],
                in: state
            )
            let afterBest = try requireEvolution(evolved.programmes[best]?.prestige.value)
            let afterWorst = try requireEvolution(evolved.programmes[worst]?.prestige.value)

            expect(afterBest >= beforeBest, "the table's leader lost prestige")
            expect(afterWorst <= beforeWorst, "the table's tail gained prestige")
            expect(afterBest > beforeBest || beforeBest == SharedRules.ratingRange.upperBound,
                   "the leader did not move and was not already at the ceiling")
        }

        test("prestige moves at most one point a season") {
            // The restoring force. A rank-driven target with no step limit would swing a programme
            // twenty points the first time it had a bad year, and a career is only twenty seasons.
            let state = evolutionState(seed: 98_002)
            let evolved = ProgrammeEvolutionSystem.process(
                collegeRanking: state.competition.rankings[.college] ?? [],
                proRanking: state.competition.rankings[.pro] ?? [],
                in: state
            )
            for programme in state.programmes.values {
                let after = try requireEvolution(evolved.programmes[programme.id]?.prestige.value)
                expect(abs(after - programme.prestige.value) <= 1,
                       "\(programme.name) moved \(after - programme.prestige.value) in one season")
            }
        }

        test("prestige stays inside the rating range however long it runs") {
            var state = evolutionState(seed: 98_003)
            let ranking = state.competition.rankings[.college] ?? []
            for _ in 0..<80 {
                state = ProgrammeEvolutionSystem.process(
                    collegeRanking: ranking,
                    proRanking: state.competition.rankings[.pro] ?? [],
                    in: state
                )
            }
            for programme in state.programmes.values {
                expect(SharedRules.ratingRange.contains(programme.prestige.value),
                       "\(programme.name) left the rating range at \(programme.prestige.value)")
            }
        }

        test("a settled programme stops moving, so prestige converges rather than drifting") {
            // Held at the same rank for eighty seasons, a programme must reach its target and stay:
            // an evolution that never settles is a random walk wearing a rule's clothes.
            var state = evolutionState(seed: 98_004)
            let ranking = state.competition.rankings[.college] ?? []
            for _ in 0..<80 {
                state = ProgrammeEvolutionSystem.process(
                    collegeRanking: ranking,
                    proRanking: state.competition.rankings[.pro] ?? [],
                    in: state
                )
            }
            let settled = state
            let again = ProgrammeEvolutionSystem.process(
                collegeRanking: ranking,
                proRanking: state.competition.rankings[.pro] ?? [],
                in: settled
            )
            expectEqual(again.programmes.values.map(\.prestige.value),
                        settled.programmes.values.map(\.prestige.value),
                        "prestige never settles at a fixed rank")
        }

        test("an unranked programme is left alone") {
            let state = evolutionState(seed: 98_005)
            let evolved = ProgrammeEvolutionSystem.process(
                collegeRanking: [],
                proRanking: [],
                in: state
            )
            expectEqual(evolved.programmes.values.map(\.prestige.value),
                        state.programmes.values.map(\.prestige.value),
                        "an empty ranking still moved somebody")
        }

        test("professional prestige follows its own table") {
            let state = evolutionState(seed: 98_006)
            let proRanking = state.competition.rankings[.pro] ?? []
            let best = try requireEvolution(proRanking.first)
            let before = try requireEvolution(state.proTeams[best]?.prestige.value)
            let evolved = ProgrammeEvolutionSystem.process(
                collegeRanking: state.competition.rankings[.college] ?? [],
                proRanking: proRanking,
                in: state
            )
            let after = try requireEvolution(evolved.proTeams[best]?.prestige.value)
            expect(after >= before, "the professional table's leader lost prestige")
        }

        test("two runs over the same world agree") {
            let state = evolutionState(seed: 98_007)
            let ranking = state.competition.rankings[.college] ?? []
            let first = ProgrammeEvolutionSystem.process(
                collegeRanking: ranking, proRanking: [], in: state
            )
            let second = ProgrammeEvolutionSystem.process(
                collegeRanking: ranking, proRanking: [], in: state
            )
            expectEqual(first.programmes.values.map(\.prestige.value),
                        second.programmes.values.map(\.prestige.value))
        }
    }
}

private enum ProgrammeEvolutionTestError: Error { case missing }

private func requireEvolution<T>(_ value: T?) throws -> T {
    guard let value else { throw ProgrammeEvolutionTestError.missing }
    return value
}

/// A bootstrapped world advanced far enough to hold a ranking.
private func evolutionState(seed: UInt64) -> GameState {
    var state = GameState.bootstrap(seed: seed)
    state.competition = CompetitionReducer.rebuild(from: state)
    return state
}
