import Foundation
import FootballSimCore

/// Host-only evidence for the two D4 operations. Device release gates live outside this probe.
func runPerformanceBudgetProbe() {
    suite("Performance evidence probe — no host threshold") {
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
                    format: "PERFORMANCE EVIDENCE ONLY: shipping college %d programmes; "
                        + "recruiting AI %.3f s; "
                        + "week advance %.3f s; target 1.200 s; hard ceiling 2.000 s "
                        + "(host measurement; no pass/fail threshold)",
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
