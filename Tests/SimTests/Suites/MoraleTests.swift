import Foundation
import FootballSimCore

func runMoraleTests() {
    suite("Morale") {
        test("a reading explains itself") {
            // Causal, like development summaries. A number a coach cannot explain is a number they
            // cannot act on, and PeopleState carried no notion of how a player felt at all.
            let state = GameState.bootstrap(seed: 90_001)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            let reading = PlayerMorale.reading(for: playerID, in: state)

            expectEqual(reading.playerID, playerID)
            expect((0...100).contains(reading.value), "morale left its range at \(reading.value)")
            expect(!reading.components.isEmpty, "a reading explained nothing")
            for component in reading.components {
                expect(MoraleReason.allCases.contains(component.reason),
                       "a component named no reason")
            }
        }

        test("a fresh world is neither happy nor aggrieved") {
            // Nobody is unhappy about minutes they have not been denied yet.
            let state = GameState.bootstrap(seed: 90_002)
            let programmeID = state.programmes.ids[0]
            for playerID in state.programmes[programmeID]!.rosterIDs.prefix(20) {
                let reading = PlayerMorale.reading(for: playerID, in: state)
                expect(!reading.isUnhappy,
                       "a player was unhappy before a game had been played")
            }
            expect(PlayerMorale.unhappy(in: programmeID, state: state).isEmpty,
                   "a bootstrapped roster arrived with a mutiny")
        }

        test("being hurt costs morale") {
            var state = GameState.bootstrap(seed: 90_003)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            let before = PlayerMorale.reading(for: playerID, in: state).value

            state.people.updatePlayerLifecycle(playerID) {
                $0.sustain(PlayerInjury(
                    area: .knee, severity: .moderate, occurredAt: state.calendar,
                    originalWeeks: 4, weeksRemaining: 4
                ))
            }
            let after = PlayerMorale.reading(for: playerID, in: state)
            expect(after.value < before, "an injured player felt no different")
            expect(after.components.contains { $0.reason == .injury },
                   "the injury did not appear in the explanation")
        }

        test("the unhappy list is worst first and stable") {
            let state = GameState.bootstrap(seed: 90_004)
            let programmeID = state.programmes.ids[0]
            let first = PlayerMorale.unhappy(in: programmeID, state: state)
            let second = PlayerMorale.unhappy(in: programmeID, state: state)
            expectEqual(first.map(\.playerID), second.map(\.playerID),
                        "the unhappy list reshuffled between rebuilds")
            for index in 1..<max(1, first.count) {
                expect(first[index - 1].value <= first[index].value,
                       "the unhappy list is not worst first")
            }
        }

        test("the thresholds leave room between unhappy and delighted") {
            // A scale where every player is at one end is a flag with extra steps.
            expect(PeopleRules.unhappyMorale < PeopleRules.baselineMorale,
                   "the baseline is already unhappy")
            expect(PeopleRules.baselineMorale < PeopleRules.delightedMorale,
                   "the baseline is already delighted")
            expect(PeopleRules.delightedMorale - PeopleRules.unhappyMorale > 20,
                   "there is no middle for an ordinary player to sit in")
        }
    }
}
