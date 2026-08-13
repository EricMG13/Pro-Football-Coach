import Foundation
import FootballSimCore

/// B-4's first budget, measured instead of stated. `--week-advance-timing`.
///
/// D4 budgets a week advance at 2.0 s and a frame at 16.7 ms, and
/// `docs/plans/2026-08-12-road-to-beta.md` records both as never measured on anything. This measures
/// the first one on whatever host runs it, which is not the phone and must never be reported as if
/// it were: a development Mac is several times faster than an iPhone under thermal load, so a
/// comfortable number here is evidence that the shape is right, not that the budget holds.
///
/// It is a probe, not a gate: it prints and asserts nothing about the budget, because a machine
/// this does not know the speed of cannot fairly fail a build. The gate is the owner's, on the
/// device, per `docs/OWNER-WALKTHROUGH.md` §4.
func runWeekAdvanceTimingProbe(weeks: Int = 21) {
    let clock = ContinuousClock()
    let bootstrapStarted = clock.now
    var state = GameState.bootstrap(seed: 20_260_813)
    let bootstrapDuration = bootstrapStarted.duration(to: clock.now)

    var samples: [Double] = []
    samples.reserveCapacity(weeks)
    for _ in 0..<weeks {
        let started = clock.now
        do {
            state = try WorldScheduler.advanceWeek(state).state
        } catch {
            print("TIMING: advanceWeek threw at \(state.calendar): \(error)")
            return
        }
        samples.append(seconds(started.duration(to: clock.now)))
    }

    let sorted = samples.sorted()
    let median = sorted[sorted.count / 2]
    let worst = sorted[sorted.count - 1]
    let total = samples.reduce(0, +)
    print(String(
        format: "TIMING: bootstrap %.3f s; %d weeks in %.3f s; median %.3f s; worst %.3f s; "
            + "D4 budget 2.000 s/week (host measurement, not a device)",
        seconds(bootstrapDuration), weeks, total, median, worst
    ))
    print("TIMING: worst week is \(worst > 2.0 ? "over" : "inside") the budget on this host")
}

private func seconds(_ duration: Duration) -> Double {
    Double(duration.components.seconds)
        + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
}
