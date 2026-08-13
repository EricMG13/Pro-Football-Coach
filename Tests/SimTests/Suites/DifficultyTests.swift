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
    }
}
