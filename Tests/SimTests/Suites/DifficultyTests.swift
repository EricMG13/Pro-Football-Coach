import Foundation
import FootballSimCore

func runDifficultyTests() {
    suite("Difficulty") {
        test("every level is a different game, and all of them are legal") {
            // The whole difficulty model was one sentence in 02 section 3.1 and was implemented
            // nowhere: the call-in range existed as a constant and nothing read it as a preference.
            var rates: Set<Int> = []
            for level in DifficultySettings.Level.allCases {
                let settings = level.settings
                rates.insert(settings.callInsPerGame)
                expect(SharedRules.callInsPerGameRange.contains(settings.callInsPerGame),
                       "\(level.rawValue) sits outside 02 section 3.1's tunable range")
                expect(settings.jobSecurityPressurePercent > 0,
                       "\(level.rawValue) freezes job security, which is the prior build's failure "
                           + "rather than a difficulty")
                expect(!level.label.isEmpty && !level.summary.isEmpty,
                       "\(level.rawValue) cannot be explained to a player")
            }
            expectEqual(rates.count, DifficultySettings.Level.allCases.count,
                        "two levels raise call-ins at the same rate")
        }

        test("the hardest level asks more and helps less") {
            let easy = DifficultySettings.Level.assistant.settings
            let hard = DifficultySettings.Level.programmeBuilder.settings
            expect(hard.callInsPerGame > easy.callInsPerGame, "the hard level asks for less")
            expect(hard.jobSecurityPressurePercent > easy.jobSecurityPressurePercent,
                   "the hard level is no more precarious")
            expect(easy.allowsDelegation && !hard.allowsDelegation,
                   "delegation does not change with difficulty")
        }

        test("a rate outside the range is clamped rather than obeyed") {
            expectEqual(
                DifficultySettings(callInsPerGame: 500, allowsDelegation: true,
                                   jobSecurityPressurePercent: 100).callInsPerGame,
                SharedRules.callInsPerGameRange.upperBound
            )
            expectEqual(
                DifficultySettings(callInsPerGame: 0, allowsDelegation: true,
                                   jobSecurityPressurePercent: 100).callInsPerGame,
                SharedRules.callInsPerGameRange.lowerBound
            )
            expect(DifficultySettings(callInsPerGame: 25, allowsDelegation: true,
                                      jobSecurityPressurePercent: 0)
                       .jobSecurityPressurePercent > 0,
                   "a settings file could freeze job security")
        }

        test("the default is the game the design is built around") {
            expectEqual(DifficultySettings.default.callInsPerGame,
                        SharedRules.defaultCallInsPerGame)
            expectEqual(DifficultySettings.default, DifficultySettings.Level.headCoach.settings)
        }

        test("the save carries it, and a save written before it existed still opens") {
            // `02` §3.16, corrected: all three settings are read by engine code, and the engine
            // cannot read an app-layer settings file. A difficulty the engine cannot see changes
            // nothing, which is what it was.
            var state = GameState.bootstrap(seed: 61_001)
            expect(state.difficulty == nil, "a fresh world arrives with a difficulty already set")
            expectEqual(state.difficultyOrDefault, DifficultySettings.default,
                        "a save with no difficulty does not read as the default one")

            // Omitted when absent, which is what keeps this additive against a schema with no
            // migration path: a world that never set one encodes as it did before the field existed.
            guard let bytes = try? JSONEncoder.stable().encode(state),
                  let text = String(data: bytes, encoding: .utf8) else {
                expect(false, "a bootstrapped world would not encode")
                return
            }
            expect(!text.contains("\"difficulty\""),
                   "every save grew a difficulty key, so every existing save is stranded")

            state.difficulty = DifficultySettings.Level.programmeBuilder.settings
            expectEqual(
                try? SaveEnvelope.decode(GameState.self, from: SaveEnvelope.encode(state)),
                state,
                "a difficulty did not survive a save round trip"
            )
            expectEqual(state.difficultyOrDefault.callInsPerGame,
                        SharedRules.callInsPerGameRange.upperBound)
            expect(!state.difficultyOrDefault.allowsDelegation)
        }

        test("the hardest level refuses to hand the week over") {
            // The setting is a promise about the week the player gets. Refused at the transaction
            // rather than hidden on a screen, so it is true however the delegation is requested.
            var state = GameState.bootstrap(seed: 61_002)
            guard let programme = state.programmes.values.first,
                  let coordinatorID = programme.staffIDs.first(where: {
                      state.staff[$0]?.role == .offensiveCoordinator
                  }) else {
                expect(false, "a bootstrapped programme has no staff")
                return
            }
            do {
                state = try CareerControlSystem.startCollegeCareer(
                    at: programme.id,
                    in: state
                ).state
            } catch {
                expect(false, "a career would not start: \(error)")
                return
            }

            state.difficulty = DifficultySettings.Level.headCoach.settings
            expect(CareerControlSystem.setResponsibility(.recruiting, owner: .delegated(staffID: coordinatorID), in: &state),
                   "the intended difficulty refused a legal delegation")

            state.difficulty = DifficultySettings.Level.programmeBuilder.settings
            expect(!CareerControlSystem.setResponsibility(.portalAndRetention, owner: .delegated(staffID: coordinatorID), in: &state),
                   "the hardest level handed the week to the staff anyway")
            expect(CareerControlSystem.setResponsibility(.recruiting, owner: .user, in: &state),
                   "taking a responsibility back was refused")
        }
    }
}
