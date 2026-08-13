import Foundation
import FootballSimCore

func runTraditionEffectTests() {
    suite("Traditions do something") {
        test("every generated programme has traditions, and they are readable") {
            // D6 clause 4: a tradition the player cannot feel in the simulation is decoration.
            // TraditionGrammar generated four kinds of effect and nothing read any of them.
            let state = GameState.bootstrap(seed: 91_001)
            var withTraditions = 0
            for programmeID in state.programmes.ids.prefix(40) {
                if TraditionEffects.hasEffects(programmeID, in: state) { withTraditions += 1 }
            }
            expect(withTraditions > 0,
                   "no programme in forty had a tradition, so the generator is not producing them")
        }

        test("the loudest week is worth something in that week and nothing in the others") {
            let state = GameState.bootstrap(seed: 91_002)
            var found = false
            for programmeID in state.programmes.ids {
                let traditions = state.identities[programmeID]?.traditions ?? []
                guard let week = traditions.compactMap({ tradition -> Int? in
                    if case let .homeFieldInWeek(week, _) = tradition.effect { return week }
                    return nil
                }).first else { continue }
                let opponent = state.programmes.ids.first { $0 != programmeID }!
                let inWeek = TraditionEffects.homeFieldBonus(
                    home: programmeID, against: opponent, week: week, in: state
                )
                let otherWeek = TraditionEffects.homeFieldBonus(
                    home: programmeID, against: opponent, week: week == 1 ? 2 : week - 1, in: state
                )
                expect(inWeek > otherWeek,
                       "the loudest week was worth no more than any other week")
                found = true
                break
            }
            expect(found, "no programme in the world had a home-field-in-week tradition")
        }

        test("a rivalry tradition only fires against a rival") {
            var state = GameState.bootstrap(seed: 91_003)
            guard let programmeID = state.programmes.ids.first(where: { id in
                (state.identities[id]?.traditions ?? []).contains {
                    if case .homeFieldAgainstRival = $0.effect { return true }
                    return false
                }
            }) else {
                expect(false, "no programme in the world had a rivalry tradition")
                return
            }
            let stranger = state.programmes.ids.first {
                $0 != programmeID && !(state.programmes[programmeID]?.rivalIDs.contains($0) ?? false)
            }!
            let against = state.programmes[programmeID]?.rivalIDs.first ?? stranger
            state.programmes.update(programmeID) { $0.addRival(against) }
            expect(
                TraditionEffects.homeFieldBonus(home: programmeID, against: against, week: 3,
                                                in: state)
                    > TraditionEffects.homeFieldBonus(home: programmeID, against: stranger, week: 3,
                                                      in: state),
                "a rivalry tradition was worth the same against a stranger"
            )
        }

        test("a morale tradition cuts both ways") {
            let state = GameState.bootstrap(seed: 91_004)
            guard let programmeID = state.programmes.ids.first(where: { id in
                (state.identities[id]?.traditions ?? []).contains {
                    if case .moraleAfterResult = $0.effect { return true }
                    return false
                }
            }) else {
                expect(false, "no programme in the world had a morale tradition")
                return
            }
            let won = TraditionEffects.moraleDelta(programmeID: programmeID, wonLastGame: true,
                                                   in: state)
            let lost = TraditionEffects.moraleDelta(programmeID: programmeID, wonLastGame: false,
                                                    in: state)
            expectEqual(won, -lost,
                        "a morale tradition rewarded a win without punishing a defeat")
            expect(won != 0, "a morale tradition moved nothing either way")
        }

        test("a pipeline is worth interest from its own region only") {
            let state = GameState.bootstrap(seed: 91_005)
            guard let programmeID = state.programmes.ids.first(where: { id in
                (state.identities[id]?.traditions ?? []).contains {
                    if case .recruitingInRegion = $0.effect { return true }
                    return false
                }
            }), let region = (state.identities[programmeID]?.traditions ?? [])
                .compactMap({ tradition -> UUID? in
                    if case let .recruitingInRegion(regionID, _) = tradition.effect { return regionID }
                    return nil
                }).first else {
                expect(false, "no programme in the world had a recruiting tradition")
                return
            }
            let elsewhere = UUID(uuidString: "00000000-0000-4000-A100-000000000001")!
            expect(TraditionEffects.recruitingBonus(programmeID: programmeID,
                                                    prospectRegionID: region, in: state) > 0,
                   "a pipeline was worth nothing in its own region")
            expectEqual(TraditionEffects.recruitingBonus(programmeID: programmeID,
                                                         prospectRegionID: elsewhere, in: state), 0,
                        "a pipeline reached a region it has no pipeline into")
        }
    }
}
