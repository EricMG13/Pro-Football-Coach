import Foundation
import FootballSimCore

/// Measures the two D4 operations on the shipping college fixture without altering the scheduler.
func runPerformanceBudgetTests() {
    suite("Performance budget") {
        let state = GameState.bootstrap(seed: 20_260_820)

        test("uses the shipping college league size") {
            expectEqual(state.programmes.count, 134)
        }

        test("measures recruiting AI and week advance") {
            let clock = ContinuousClock()
            let recruitingStarted = clock.now
            do {
                let recruiting = try CollegeRecruitingAISystem.process(in: state)
                let recruitingSeconds = seconds(recruitingStarted.duration(to: clock.now))
                expect(!recruiting.decisions.isEmpty, "recruiting AI made no decisions")

                let weekStarted = clock.now
                _ = try WorldScheduler.advanceWeek(state)
                let weekSeconds = seconds(weekStarted.duration(to: clock.now))
                print(String(
                    format: "PERFORMANCE: shipping college %d programmes; recruiting AI %.3f s; "
                        + "week advance %.3f s; target 1.200 s; hard ceiling 2.000 s "
                        + "(host measurement, not a device)",
                    state.programmes.count,
                    recruitingSeconds,
                    weekSeconds
                ))
            } catch {
                expect(false, "performance fixture threw: \(error)")
            }
        }
    }
}
