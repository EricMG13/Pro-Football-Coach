# D2 Distribution Successor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the falsified hybrid assignment/leverage resolver with a deterministic play-outcome distribution model whose sampled outcome and causal visualisation attribution are one immutable record, and produce statistically reachable calibration evidence for the currently implemented 24-band subset without misreporting that subset as full G5.

**Architecture:** Build the successor beside the legacy resolver long enough to compare deterministic behavior and calibration, but route the calibration scorer explicitly through the successor from its first executable integration. The successor samples bounded run/pass/kick outcome buckets from tier-, call-, situation-, and rating-conditioned weights; the same sample selects the player attribution carried by `SnapOutcome.matchups`, so rendering reads a recorded cause and never fabricates one. Delete the falsified hybrid after the successor's deterministic/causal contracts and evidence run are complete; P4 remains open until a follow-on G5 coverage plan implements every phase-reachable metric that `CalibrationBands.unimplementedMetrics` currently names.

**Tech Stack:** Swift 5 language mode, Swift Package Manager, the existing seeded `SimTests` executable, `CalibrationScore`, Bash calibration contracts, and no dependencies.

## Global Constraints

- D2 option (c) is falsified after five consecutive genuine model-tuning failures. Do not tune or restore the hybrid resolver.
- The successor is D2 option (b): a play-outcome distribution model with outcome and causal attribution sampled as one deterministic visualisation record.
- The engine remains pure Swift with zero `import SwiftUI`; every numeric rule lives in a rules module.
- RNG is explicit and seeded. No `hashValue`, ambient `UUID()`/`Date()`, standard-library random APIs, or render-time rerolls.
- A snap sample has a fixed draw budget for its play type. Branch results may not change how many draws that play type consumes.
- `SnapOutcome` remains an immutable value; views can read it but cannot reach the resolver.
- TOST passes only when the whole 90% CI lies inside the fixed evidence band. Never widen a band.
- Tune only against `CalibrationHarness.tuningSeeds`. The exposed `holdoutSeeds` are deterministic evaluation evidence, run once after selection and never called blinded.
- The confirmed current college clock rule is: the clock continues after a first down except inside the last two minutes of either half, when it stops. Do not preserve the legacy inverted rule.
- No sixth hybrid tuning attempt. Distribution-model calibration starts a new architecture ledger and must be reported separately.
- The currently implemented 24 bands are an interim subset, not full G5. A 24/24 subset result may approve removal of the falsified hybrid but may not close P4.
- Full scorer runs use exactly 2,000 games per tier per ladder. The checked-in ladder is exactly 24
  fixed seeds split 12 tuning/12 holdout, and college samples contain exactly 500 non-conference,
  1,300 conference, and 200 postseason games. Unit tests may inject a smaller total explicitly.
- Do not use checkout, restore, stash, reset, or clean.

---

### Task 1: Correct the college first-down clock semantics

The authority is the official 2025 NCAA Football Rules Book, Rule 3-3-2-e-1: after the two-minute
timeout, a Team A first down stops the clock and it restarts on the referee's ready-for-play signal.
The NCAA's 2026 published changes do not replace this timing rule.

**Files:**

- Modify: `Sources/FootballSimCore/Rules/ClockRules.swift`
- Modify: `Sources/FootballSimCore/Engine/DriveEngine.swift`
- Modify: `Sources/FootballSimCore/Engine/GameEngine.swift`
- Modify: `Tests/SimTests/Suites/RulesTests.swift`
- Modify: `Tests/SimTests/Suites/EngineTests.swift`
- Modify: `docs/03-MATCH-ENGINE.md`
- Modify: `docs/STATUS.md`

**Interfaces:**

- Produces: `ClockRules.clockStopsOnFirstDownInsideTwoMinutes: Bool`,
  `DriveEngine.firstDownStopsClock(madeFirstDown:situation:rules:)`, and
  `DriveEngine.preSnapSeconds(clockRunning:clockStoppedByFirstDown:tempo:rules:)`; adds
  `PlayRecord.preSnapSeconds` as the integration observable and fingerprint field; removes the
  inverted `firstDownStopEndsAtSecondsRemaining` contract.

- [ ] **Step 1: Add the RED clock tests**

Add this table-driven test in the game-loop suite; it fails to compile until the production decision
helper exists, so it cannot pass by reading a constant without exercising the decision:

```swift
test("college first downs stop only inside two minutes") {
    func stops(_ tier: Tier, _ seconds: Int) -> Bool {
        DriveEngine.firstDownStopsClock(
            madeFirstDown: true,
            situation: Situation(quarter: 2, secondsRemainingInQuarter: seconds),
            rules: tier.clockRules
        )
    }
    expect(!stops(.college, 300), "college stopped after a first down with five minutes left")
    expect(stops(.college, 90), "college did not stop after a first down inside two minutes")
    expect(stops(.college, 120), "college did not stop at the exact two-minute boundary")
    expect(!stops(.college, 121), "college stopped one second before the two-minute boundary")
    expect(!DriveEngine.firstDownStopsClock(
        madeFirstDown: true,
        situation: Situation(quarter: 1, secondsRemainingInQuarter: 90),
        rules: CollegeClockRules.self
    ), "first-quarter 1:30 was mistaken for the end of the half")
    expect(!DriveEngine.firstDownStopsClock(
        madeFirstDown: true,
        situation: Situation(quarter: 3, secondsRemainingInQuarter: 90),
        rules: CollegeClockRules.self
    ), "third-quarter 1:30 was mistaken for the end of the half")
    expect(DriveEngine.firstDownStopsClock(
        madeFirstDown: true,
        situation: Situation(quarter: 4, secondsRemainingInQuarter: 90),
        rules: CollegeClockRules.self
    ), "fourth-quarter 1:30 did not use end-of-half timing")
    expect(!stops(.pro, 300), "pro stopped after a first down with five minutes left")
    expect(!stops(.pro, 90), "pro stopped after a first down inside two minutes")

    expectEqual(DriveEngine.preSnapSeconds(
        clockRunning: false, clockStoppedByFirstDown: true, tempo: .normal,
        rules: CollegeClockRules.self
    ), CollegeClockRules.readyForPlaySeconds,
    "college first-down restart did not charge the 18-second ready-for-play interval")
}
```

- [ ] **Step 2: Run RED**

Run `swift run -c release SimTests`. Expected RED: compilation fails only on the two new
`DriveEngine` helper members and `PlayRecord.preSnapSeconds`; production does not yet expose either
decision or the integration observable.

- [ ] **Step 3: Replace the inverted protocol field**

In `ClockRules`, replace both `clockStopsOnFirstDown` and
`firstDownStopEndsAtSecondsRemaining` with:

```swift
static var clockStopsOnFirstDownInsideTwoMinutes: Bool { get }
```

Set college to `true` and pro to `false`. Add and use these helpers in `DriveEngine`:

```swift
public static func firstDownStopsClock(
    madeFirstDown: Bool,
    situation: Situation,
    rules: any ClockRules.Type
) -> Bool {
    rules.clockStopsOnFirstDownInsideTwoMinutes
        && madeFirstDown
        && situation.secondsRemainingInHalf(rules: rules) <= rules.twoMinuteSeconds
}

let firstDownStop = firstDownStopsClock(
    madeFirstDown: madeFirstDown,
    situation: situation,
    rules: rules
)

public static func preSnapSeconds(
    clockRunning: Bool,
    clockStoppedByFirstDown: Bool,
    tempo: Tempo,
    rules: any ClockRules.Type
) -> Int {
    if clockRunning { return tempo.snapSeconds(rules: rules) }
    if clockStoppedByFirstDown { return rules.readyForPlaySeconds }
    return 0
}
```

Replace the inline pre-snap branch with `preSnapSeconds`. An inside-two-minute college first down
stops the clock but still charges `readyForPlaySeconds` on the next snap; it never creates a free
zero-second restart. The helper is the direct observable because `PlayRecord` stores the situation
before a snap. Add `preSnapSeconds` to `PlayRecord`, populate it from the helper on every iteration,
and mix it in `GameRecord.playByPlayFingerprint` immediately before `outcome.secondsElapsed`.

Add an integration test that calls `DriveEngine.run` at quarter 2, 125 seconds, distance one, with a
fixed run caller, `clockRunning: true`, and 99-rated offence versus 40-rated defence. Search the bounded literal seeds
`1...200` only until a first-down opening play followed by two further recorded plays is found; assert the following
`PlayRecord.preSnapSeconds == CollegeClockRules.readyForPlaySeconds`. Require a third play and assert
its recorded clock equals the second play's recorded clock minus the second play's
`preSnapSeconds + outcome.secondsElapsed`; this proves the stored charge is applied, not merely
reported. Assert the equivalent pro
drive records `ProClockRules.normalTempoSnapSeconds`. The test fails if `run` computes the helper but
does not actually store/use its result. Keep the bounded search in the test and print the seed on
failure so the fixture remains deterministic and diagnosable.

Replace every existing rules/engine test that asserts the inverted `clockStopsOnFirstDown` flag.
Rewrite `ClockRules.swift`'s stale "unconfirmed" and "stops after every first down" comments to cite
Rule 3-3-2-e-1 and describe the ready-for-play restart; do not leave the fixed code under the old
rule explanation.
Update `03` §2 and the status clock note to the confirmed inside-two-minutes rule in the same commit;
no current-state document may continue to claim that college stops after every first down.

- [ ] **Step 4: Run GREEN and commit**

Run `swift run -c release SimTests` twice, re-pin only fingerprints changed by the corrected clock,
then run `rewrite-tournament` on the changed drive-loop region and `confidence-review`. Commit the
seven exact paths named by this task with `fix: correct college first-down clock`.

---

### Task 2: Add the deterministic distribution primitive and fixed draw budget

**Files:**

- Create: `Sources/FootballSimCore/Engine/OutcomeDistribution.swift`
- Create: `Sources/FootballSimCore/Engine/SnapDraws.swift`
- Modify: `Tests/SimTests/Suites/EngineTests.swift`

**Interfaces:**

- Produces: `WeightedOutcome<Value>.sample(roll:) -> Value?`, `OutcomeSampling.integer(in:roll:) -> Int?`, and `SnapDraws.init(rng:)`.

- [ ] **Step 1: Add RED tests for weighted sampling**

Cover first/last bucket boundaries, zero/negative/non-finite weights, empty distributions, a roll of exactly 1, integer range endpoints, and identical RNG state after different sampled outcomes.

- [ ] **Step 2: Implement the primitive**

Create:

```swift
public struct WeightedOutcome<Value: Sendable>: Sendable {
    public let entries: [(value: Value, weight: Double)]

    public init(_ entries: [(Value, Double)]) {
        self.entries = entries.map { (value: $0.0, weight: $0.1) }
    }

    public func sample(roll: Double) -> Value? {
        guard roll.isFinite, !entries.isEmpty,
              entries.allSatisfy({ $0.weight.isFinite && $0.weight >= 0 }) else { return nil }
        let total = entries.reduce(0) { $0 + $1.weight }
        guard total.isFinite, total > 0 else { return nil }
        let bounded = Swift.min(Swift.max(roll, 0), Double(1).nextDown)
        let target = bounded * total
        var cumulative = 0.0
        var lastPositive: Value?
        for entry in entries where entry.weight > 0 {
            lastPositive = entry.value
            cumulative += entry.weight
            if target < cumulative { return entry.value }
        }
        return lastPositive
    }

}

public enum OutcomeSampling {
    public static func integer(in range: ClosedRange<Int>, roll: Double) -> Int? {
        guard roll.isFinite else { return nil }
        let bounded = Swift.min(Swift.max(roll, 0), Double(1).nextDown)
        let (width, widthOverflow) = range.upperBound.subtractingReportingOverflow(range.lowerBound)
        let (count, countOverflow) = width.addingReportingOverflow(1)
        guard !widthOverflow, !countOverflow, count > 0 else { return nil }
        let offset = Swift.min(Int(bounded * Double(count)), count - 1)
        let (value, valueOverflow) = range.lowerBound.addingReportingOverflow(offset)
        return valueOverflow ? nil : value
    }
}
```

Create a fixed eight-draw value:

```swift
public struct SnapDraws: Sendable, Equatable {
    public let outcome, yardage, target, attribution, secondary, turnover, spareA, spareB: Double

    public init(rng: inout SeededRandom) {
        outcome = rng.double01(); yardage = rng.double01()
        target = rng.double01(); attribution = rng.double01()
        secondary = rng.double01(); turnover = rng.double01()
        spareA = rng.double01(); spareB = rng.double01()
    }

    public init(
        outcome: Double, yardage: Double, target: Double, attribution: Double,
        secondary: Double, turnover: Double, spareA: Double, spareB: Double
    ) {
        self.outcome = outcome; self.yardage = yardage
        self.target = target; self.attribution = attribution
        self.secondary = secondary; self.turnover = turnover
        self.spareA = spareA; self.spareB = spareB
    }
}
```

The memberwise-value initializer is the test injection seam. Production creates `SnapDraws` exactly
once from the RNG; focused tests call the public RNG-free `resolve(..., draws:)` overload with eight named
values to pin bucket boundaries and prove that the recorded pair is the same pair whose ratings
conditioned the outcome table.

- [ ] **Step 3: Run GREEN and quality gates**

Run `swift run -c release SimTests`; run `rewrite-tournament` on `sample` and `integer`; run `confidence-review` on overflow, empty, NaN, and boundary behavior. Commit the three paths with `feat: add deterministic outcome sampling`.

---

### Task 3: Define tiered outcome bands in rules

**Files:**

- Create: `Sources/FootballSimCore/Rules/OutcomeDistributionRules.swift`
- Modify: `Tests/SimTests/Suites/RulesTests.swift`

**Interfaces:**

- Produces: `RunOutcomeBand`, `PassOutcomeBand`, tiered base weights, bounded yard ranges, compressed rating-edge scale, and tier-specific kicking/home terms.

- [ ] **Step 1: Add RED rules-table tests**

Assert every table is finite, non-negative, sums to one within `probabilityTolerance`, every yard
range is ordered, pro explosive-run mass is `0.118`, college is `0.151`, explosive-pass mass is
`0.137` pro and `0.143` college, and a 10-point rating edge produces exactly half
`maximumProbabilityShift` before donor bounding.

- [ ] **Step 2: Implement exact starting tables**

```swift
public enum RunOutcomeBand: String, Sendable, CaseIterable {
    case loss, short, medium, explosive, breakaway, fumbleLost
}

public enum PassOutcomeBand: String, Sendable, CaseIterable {
    case sack, interception, incompletion, completion, explosiveCompletion, fumbleLost
}

public enum OutcomeDistributionRules {
    public static let proRunExplosiveMass = 0.118
    public static let collegeRunExplosiveMass = 0.151
    public static let passCompletionMass = 0.640
    public static let passSackMass = 0.060
    public static let passInterceptionMass = 0.022
    public static let proPassExplosiveMass = 0.137
    public static let collegePassExplosiveMass = 0.143
    public static let fumbleLostMass = 0.012

    public static func runWeights(tier: Tier) -> [(RunOutcomeBand, Double)] {
        switch tier {
        case .pro:
            return [(.loss, 0.100), (.short, 0.550 - fumbleLostMass),
                    (.medium, 1 - 0.100 - 0.550 - proRunExplosiveMass),
                    (.explosive, proRunExplosiveMass - 0.010), (.breakaway, 0.010),
                    (.fumbleLost, fumbleLostMass)]
        case .college:
            return [(.loss, 0.100), (.short, 0.520 - fumbleLostMass),
                    (.medium, 1 - 0.100 - 0.520 - collegeRunExplosiveMass),
                    (.explosive, collegeRunExplosiveMass - 0.015), (.breakaway, 0.015),
                    (.fumbleLost, fumbleLostMass)]
        }
    }

    public static func passWeights(tier: Tier) -> [(PassOutcomeBand, Double)] {
        let explosive = tier == .pro ? proPassExplosiveMass : collegePassExplosiveMass
        return [(.sack, passSackMass), (.interception, passInterceptionMass),
                (.incompletion, 1 - passSackMass - passInterceptionMass - passCompletionMass),
                (.completion, passCompletionMass - explosive - fumbleLostMass),
                (.explosiveCompletion, explosive), (.fumbleLost, fumbleLostMass)]
    }

    public static let lossYards = -3...0
    public static let shortRunYards = 1...3
    public static let mediumRunYards = 4...9
    public static let explosiveRunYards = 10...18
    public static let breakawayRunYards = 19...60
    public static let ordinaryPassYards = 1...14
    public static let explosivePassYards = 15...35
    public static let runFumbleYards = 1...3
    public static let passFumbleYards = 1...14
    public static let sackYards = -9 ... -4
    public static let puntYards = 35...55
    public static let kneelYards = -1
    public static let maximumProbabilityShift = 0.04
    public static let maximumBallSecurityProbabilityShift = 0.006
    public static let ratingPointsForMaximumShift = 20.0
    public static let maximumDepthProbabilityShift = 0.010
    public static let outsideRunProbabilityShift = 0.010
    public static let runAggressionProbabilityShift = 0.006
    public static let passAggressionProbabilityShift = 0.008
    public static let defensiveAggressionProbabilityShift = 0.006
    public static let rusherSackShiftPerPlayer = 0.006
    public static let coverageShellProbabilityShift = 0.008
    public static let longYardageProbabilityShift = 0.008
    public static let shortYardageProbabilityShift = 0.006
    public static let shortYardageDistance = 2
    public static let longYardageDistance = 7
    public static let targetRatingFloor = 1.0
    public static let riskRewardSplit = 0.5
    public static let passProtectionThrowWeight = 0.5
    public static let minimumAttributionMagnitude = 0.5
    public static let attributionMagnitudeRange = 0.5
    public static let proHomeProbabilityShift = 0.010
    public static let collegeHomeProbabilityShift = 0.045
    public static let proFieldGoalBase = 0.84
    public static let collegeFieldGoalBase = 0.76
    public static let maximumFieldGoalMatchupProbabilityShift = 0.10
    public static let fieldGoalDistancePenaltyPerYard = 0.006
    public static let fieldGoalReferenceDistance = 35
    public static let minimumFieldGoalProbability = 0.02
    public static let maximumFieldGoalProbability = 0.98
    public static let lastFieldYardOffset = 1
    public static let probabilityTolerance = 1e-12
}
```

No probability, yard range, leverage magnitude, distance slope, or call/situation modifier may be
spelled as a numeric literal in the resolver. `RulesTests` enumerates these constants, every base
table, and the adjusted-table fixtures used by Task 4.

- [ ] **Step 3: Run GREEN and commit**

Run `swift run -c release SimTests`, `confidence-review` the sum and range invariants, and commit with `feat: define outcome distribution rules`. Rewrite tournament is not applicable to declarative rules tables.

---

### Task 4: Implement the joint outcome-and-attribution resolver

**Files:**

- Create: `Sources/FootballSimCore/Engine/DistributionSnapResolver.swift`
- Modify: `Sources/FootballSimCore/Engine/SnapOutcome.swift`
- Modify: `Sources/FootballSimCore/Engine/GameEngine.swift`
- Modify: `Tests/SimTests/Suites/EngineTests.swift`
- Modify: `docs/03-MATCH-ENGINE.md`

**Interfaces:**

- Produces: `DistributionSnapResolver.resolve(tier:offensiveCall:defensiveCall:personnel:situation:isHomeOffense:rng:) -> SnapOutcome` plus a public RNG-free `resolve(..., draws:)` replay/test seam. Clock constants come from `tier.clockRules`, so callers cannot supply a tier/rules mismatch.

- [ ] **Step 1: Add RED behavioral tests**

Add table-driven tests using the eight-value `SnapDraws` initializer. Prove every `SnapResult` is
reachable from an appropriate play type/situation; every populated run, pass, or field-goal result
has the deciding attribution described below; a sack names a losing protection pair; an interception names the
selected target's defender in both `.throwing` and `.routeVersusCoverage`; `fumbleLost` names a
losing `.ballSecurity` pair; and a successful run names a winning lane or pursuit pair. For two
receivers whose target weights choose the second receiver, assert that the target ID and both throw
records name that receiver and its paired defender—never the first route.

The empty-personnel contract is exact: after consuming all eight draws, return `.gain`, zero yards,
`tier.clockRules.inBoundsPlaySeconds`, no matchups, and nil carrier/passer/target IDs for run/pass;
return `.fieldGoalMissed`, zero yards, `tier.clockRules.stoppedPlaySeconds`, no matchups, and nil IDs for a field goal;
punt and kneel preserve their declared results. With fixed draws at an outcome-bucket boundary,
weakening only the selected blocker or lane participant must move the sampled result in the predicted
direction, while weakening an unselected participant must leave the adjusted weights and result
unchanged. The `MatchupRecord` IDs must equal that selected causal pair. Separately, pass an already
resolved distribution game through the existing "rendering cannot change an outcome" read loop and
prove its fingerprint is unchanged; rendering receives neither draws nor a resolver.

Compare RNG state after run loss/gain/fumble, pass sack/incompletion/completion,
field-goal good/missed, punt, and kneel outcomes to prove every play type consumes exactly eight draws.

"Missing required personnel" means: run lacks a carrier, lane pair, or pursuer; pass lacks a
passer, route pair, or protection pair; field goal lacks a specialist or ranked defender. A partial
assignment uses the same fallback rather than inventing an ID or dividing by an empty aggregate.

- [ ] **Step 2: Implement rating conditioning without per-duel outcome resolution**

Create a private `mean(_:)` that returns nil for an empty rating list and otherwise averages the
integer rating values. Use these exact aggregates, never `overall` and never stochastic
`Leverage.score`:

- Run lane: the preselected blocker `.runBlock`, `.strength`, `.awareness`, and `.schemeFit` against
  the preselected lane defender `.runDefence`, `.shed`, `.gapDiscipline`, and `.strength`.
- Run carrier: carrier `.vision`, `.elusiveness`, `.power`, and `.speed` against the preselected
  pursuer's `.tackling`, `.pursuit`, and `.speed`.
- Pass protection: the preselected blocker's `.passBlock`, `.strength`, and `.awareness` against
  that paired rusher's `.passRush`, `.finesse`, `.power`, and `.motor`.
- Target/throw: the passer's depth-specific accuracy, `.armStrength`, `.decision`, and `.poise`, plus
  the selected receiver's `.routeRunning`, `.release`, `.hands`, and `.speed`, against the paired
  defender's `.coverage`, `.awareness`, `.hands`, `.speed`, and `.agility`. Apply the signed selected
  protection raw edge multiplied by `passProtectionThrowWeight` to this raw edge before converting
  it to probability mass, so pressure is read by the throw rather than merely by the sack bucket.
- Ball security: carrier `.power`, `.awareness`, and `.durability` against the selected pursuer's
  `.tackling`, `.pursuit`, and `.power`.
- Kick: kicker `.kickAccuracy`, `.legStrength`, and `.poise` against the selected defender's
  `.blockLeverage` and `.awareness`, with distance applied separately by the named slope.

Convert each offence-minus-defence aggregate to a signed probability shift with:

```swift
private static func ratingShift(_ rawEdge: Double, maximum: Double) -> Double {
    Swift.min(Swift.max(
        rawEdge / OutcomeDistributionRules.ratingPointsForMaximumShift * maximum,
        -maximum
    ), maximum)
}
```

Run, protection, and target/throw edges pass `maximumProbabilityShift`; ball security passes
`maximumBallSecurityProbabilityShift`; kick passes `maximumFieldGoalMatchupProbabilityShift`.

Implement one conservation primitive:

```swift
private static func transfer<Band: Hashable>(
    _ signedAmount: Double, between adverse: Band, and favourable: Band,
    in weights: inout [Band: Double]
) {
    let donor = signedAmount >= 0 ? adverse : favourable
    let receiver = signedAmount >= 0 ? favourable : adverse
    let moved = Swift.min(Swift.abs(signedAmount), weights[donor, default: 0])
    weights[donor, default: 0] -= moved
    weights[receiver, default: 0] += moved
}
```

All conditioning is expressed only as these bounded transfers, so no post-hoc clamp can create or
destroy mass. Apply transfers in this exact order:

- Run: selected lane edge and the tier home shift between `.loss`/`.medium`; selected carrier edge
  between `.short`/`.explosive`; ball-security edge between `.fumbleLost`/`.short`; outside-gap shift from
  `.short` to `.explosive`; signed offensive aggression between `.short`/`.explosive`; signed
  defensive aggression between `.medium`/`.loss`; a distance at or below
  `shortYardageDistance` transfers `.loss` to `.short`, while a distance at or above
  `longYardageDistance` transfers `.medium` to `.loss`.
- Pass: protection edge between `.sack`/`.completion`; target/throw edge between
  `.incompletion`/`.completion`; passer-decision minus defender-awareness edge between
  `.interception`/`.incompletion`; selected receiver ball-security edge between
  `.fumbleLost`/`.completion`; tier home shift between `.incompletion`/`.completion`.
  Short depth transfers `.explosiveCompletion` to `.completion`, mid makes no depth transfer, and
  deep transfers `.completion` to `.explosiveCompletion`, all by
  `maximumDepthProbabilityShift`. Each rusher above `MatchupRules.baseRushers` transfers
  `rusherSackShiftPerPlayer` from `.completion` to `.sack`; each rusher below that base reverses it.
  For short throws, `zoneUnder` transfers `.completion` to `.incompletion`, while `zoneDeep` and
  `prevent` reverse that transfer. For deep throws, `zoneDeep` and `prevent` transfer
  `.explosiveCompletion` to `.incompletion`, while `zoneUnder` reverses it; man and every mid-depth
  pairing have zero shell transfer. Offensive aggression moves half its signed risk amount from
  `.completion` to `.explosiveCompletion` and half from `.incompletion` to `.interception`;
  defensive aggression moves half from `.completion` to `.sack` and half from `.incompletion` to
  `.explosiveCompletion`. A distance at or below `shortYardageDistance` transfers `.incompletion`
  to `.completion`; a distance at or above `longYardageDistance` transfers `.completion` to
  `.explosiveCompletion`.

Every amount and threshold above comes from the named Task 3 constant. After all transfers, assert in debug and test code that weights are
finite/non-negative and their sum differs from one by at most `probabilityTolerance`. Convert the
dictionary back to `Band.allCases.map { ($0, weights[$0]!) }` before sampling; never sample dictionary
iteration order.

- [ ] **Step 3: Sample outcome, yards, and attribution jointly**

At the RNG-taking entry create `let draws = SnapDraws(rng: &rng)` and immediately call the public
`resolve(..., draws:)`; that overload contains no RNG parameter. Build `SnapAssignment` first. For a
pass, select the route before conditioning the table. Each route weight is:

```swift
OutcomeDistributionRules.targetRatingFloor
    + Double(route.receiver.attributes[.routeRunning].value
             - SharedRules.ratingRange.lowerBound)
    + Double(route.receiver.attributes[.hands].value
             - SharedRules.ratingRange.lowerBound)
    + Double(route.receiver.attributes[.speed].value
             - SharedRules.ratingRange.lowerBound)
```

sample it with `draws.target`. Condition the pass table on that exact route, then sample the band
with `draws.outcome`. Before conditioning, also use `draws.attribution` to preselect one protection
pair uniformly; that exact pair's edge conditions sack and throw mass, and a sack records that pair.
Thus target, protection, and result are not independent samples. Every non-sack pass uses the already
selected target pair for both route and throw records. Before conditioning a run table, use the same
`draws.attribution` with `OutcomeSampling.integer` to preselect one assigned lane and one pursuer
(each uniformly within its own list). The selected pursuer supplies the run ball-security defence
aggregate. After the band is sampled: `.loss` records the selected lane negative; `.short` and
`.medium` record the lane positive; `.explosive` and `.breakaway` record carrier-versus-selected-
pursuer positive; `.fumbleLost` records carrier-versus-selected-pursuer `.ballSecurity` negative.
There is no second attribution sample after the band is known.

Sample yards with `draws.yardage`. `fumbleLost` is a first-class run/pass band using
`runFumbleYards` or `passFumbleYards`; it is not a consequence reroll. Cap fumble yardage at
`max(0, situation.yardsToGoal - lastFieldYardOffset)` so a lost fumble never also crosses the goal
line. Map a non-fumble gain crossing the goal line to `.touchdown`; map a loss or sack crossing the
offence's goal line to `.safety`. Give attacker-favourable results positive leverage and
defender-favourable results negative leverage, with magnitude
`minimumAttributionMagnitude + draws.secondary * attributionMagnitudeRange`. Add
`MatchupRecord.Kind.ballSecurity`; run fumbles attribute carrier to the selected pursuer, pass
fumbles attribute the selected receiver to its paired defender, both negative. Update
`SnapOutcome.decidingMatchup` so `.fumbleLost` considers only `.ballSecurity`.

Pass yard ranges are net play yards, not air yards plus a second YAC roll: `.completion` samples
`ordinaryPassYards` (1...14) and `.explosiveCompletion` samples `explosivePassYards` (15...35).
This makes the public ≥15-yard explosive definition identical to the sampled bucket and prevents a
nominal ordinary completion from silently entering the explosive numerator.

Field goals use distance `situation.yardsToGoal + MatchupRules.fieldGoalSnapDistance` and sample
good/missed with `draws.outcome` from this exact probability, clamped only to the named limits:

```swift
baseByTier
    + ratingShift(kickOffenceMean - kickDefenceMean,
                  maximum: maximumFieldGoalMatchupProbabilityShift)
    - Double(max(0, distance - fieldGoalReferenceDistance)) * fieldGoalDistancePenaltyPerYard
    + (isHomeOffense ? homeShiftByTier : 0)
```

The kick record names the kicker and the first ranked defender, with sign matching good/missed.
Punts sample `puntYards` with `draws.yardage`, clamp to `situation.yardsToGoal`, and name the punter;
kneels use `kneelYards` and no attribution. Missing required people uses the exact fallback above.

- [ ] **Step 4: Make the record semantics honest**

Update `MatchupRecord` documentation to state that under option (b) it is the causal attribution
sampled jointly with the outcome, not a separately simulated duel. Update `decidingMatchup`'s nil
contract to list kneels, punts, and explicit missing-personnel fallbacks; populated run/pass/kick
outcomes must not return nil. Preserve the record's public shape for the future match view.
Correct `SnapOutcome.secondsElapsed` documentation to say it is play-action time only;
`PlayRecord.preSnapSeconds` is the separately recorded pre-snap charge. No comment may continue to
claim that `SnapOutcome.secondsElapsed` includes both.

Rewrite `docs/03-MATCH-ENGINE.md` §§1.1–1.2 in the same commit: replace the four-stage stochastic
duel/leverage description with assignment → selected causal pair/target → conditioned probability-
mass transfers → one sampled immutable outcome; replace its attribute table with the exact run,
protection, target/throw, ball-security, and kick attribute sets above. Remove every current-state
claim that every individual duel resolves or that `Leverage.score` produces the consequence.

Extend `GameRecord.playByPlayFingerprint` to mix `passerID` and `targetID` immediately after
`ballCarrierID`. Add three mutation tests proving independently replacing carrier, passer, or target
changes the fingerprint while an encode/decode round trip preserves it.

- [ ] **Step 5: Run GREEN and quality gates**

Run `swift run -c release SimTests` twice. Run `rewrite-tournament` on the transfer, run, pass, and
kick distribution functions and `confidence-review` on probability conservation, fixed draws,
target-conditioned attribution/result consistency, empty personnel, fingerprint identity fields,
goal-line clamping, safety, and fumble ordering. Commit the five exact paths with
`feat: add distribution snap resolver`.

---

### Task 5: Integrate the successor explicitly and calibrate it

**Files:**

- Modify: `Sources/FootballSimCore/Engine/DriveEngine.swift`
- Modify: `Sources/FootballSimCore/Engine/GameEngine.swift`
- Modify: `Sources/FootballSimCore/Rules/OutcomeDistributionRules.swift`
- Modify: `Sources/FootballSimCore/Calibration/CalibrationHarness.swift`
- Modify: `Tools/CalibrationScore/main.swift`
- Modify: `Tests/SimTests/Suites/EngineTests.swift`
- Modify: `Tests/SimTests/Suites/CalibrationTests.swift`
- Modify: `scripts/tune-calibration.sh`
- Modify: `scripts/test-calibration-tools.sh`
- Modify: `docs/01-RESEARCH.md`
- Create: `docs/plans/2026-08-10-p4-distribution-attempt-one.md`
- Modify: `docs/HANDOFF-2026-08-10.md`
- Modify: `docs/STATUS.md`
- Modify: `docs/OPEN-DECISIONS.md`

**Interfaces:**

- Produces: `public enum MatchEngineModel: String, Sendable { case legacyHybrid, distribution }` in `GameEngine.swift`, explicit selection during comparison, with `CalibrationScore` hard-wired to `.distribution` and no CLI mode that scores the retired hybrid.

- [ ] **Step 1: Add RED integration tests**

Add the exact enum above; require `GameEngine.play` and `CalibrationHarness.run` to take an explicit
model during the migration. Replace both current 20-seed arrays with one exact 24-seed literal;
define `tuningSeeds = Array(seedLadder[0..<12])` and
`holdoutSeeds = Array(seedLadder[12..<24])`. Replace `matchupsPerSeed` with
`fullGamesPerLadder = 2_000`, and define
`CalibrationHarness.run(tier:seeds:model:gamesPerLadder: Int = fullGamesPerLadder)`.
`CalibrationScore` uses the default, requires exactly 12 seeds, and fails unless each tier report
says exactly 2,000 games; focused unit tests pass `gamesPerLadder: 240`. Unit tests prove the
24/12/12 split and full total without running the full ladder inside `SimTests`; the separate scorer
run proves the actual report count. Tests also prove a midpoint
estimate for each home-win band has a CI narrow enough to fit, scorer reports distribution and its
game count, both models reproduce across processes, and render-facing `SnapOutcome` shape is
identical.

Add a RED metric-unit fixture containing one game with exactly one safety. Assert the estimate for
`"safeties per game"` is `1.0` with sample size one. Replace the current per-side
`teamSafeties` array with one `safetiesPerGame` value equal to the sum of both sides for each game;
the band is game-level and may not be halved through a team-game mean. Keep every other per-team
metric unchanged.

```swift
public static let seedLadder: [UInt64] = [
    1, 7, 11, 23, 41, 59, 83, 97, 131, 173, 211, 257,
    2, 8, 13, 29, 43, 61, 89, 101, 137, 179, 223, 263,
]
public static let fullGamesPerLadder = 2_000
public static let nonConferencePercent = 25
public static let postseasonPercent = 10
```

Add `CalibrationGameContext { case nonConference, conference, postseason }` to the harness and store
it on every `SampledGame`. For full college runs, ordinals `0..<500` are non-conference,
`500..<1_800` conference, and `1_800..<2_000` postseason; tests assert exact counts. For any injected
smaller total, assign contexts by the same 25/65/10 proportions using integer cut points, with the
remainder assigned to conference. Context changes matchup composition through exact talent-pair
index sets: non-conference `[7, 8, 9, 10]` (balanced home/away nine-point mismatches), conference
`[0, 1, 2, 3, 4, 5, 6]` (one even plus balanced three/six-point gaps), and postseason `[0, 1, 2]`
(one even plus balanced three-point gaps). Unit tests assert each context uses only its set, both
home/away mismatch directions occur equally except a single unavoidable remainder, and mean absolute
talent gap is ordered non-conference > conference > postseason. Pro runs use all 12 pairs with one
neutral context and do not report college strata.

Generate exactly `gamesPerLadder` games, not games-per-seed nested loops. For ordinal `g`, use seed
index `g % seeds.count`; select the context set above, compute its zero-based local context ordinal,
and choose index
`((localOrdinal / seeds.count) + (g % seeds.count) * 5) % contextPairIndices.count` from that set.
Derive the game seed with ordinal `g`. The multiplier is coprime to each context-set size, so every
seed rotates through every allowed pair and only the unavoidable one-game remainder remains; the
old nested loop overweighting cannot recur.
Amend `docs/01-RESEARCH.md` §6.1's contradictory `gamesPerSeed: Int` pseudocode to this exact
round-robin 2,000-game ladder while preserving its 24-seed split and context mix. Record the three
context pair-index sets as the provisional executable interpretation of the research's otherwise
unspecified "matches the real schedule shape" clause; do not present those weights as sourced fact.

Pin the scorer envelope: first `MODEL distribution`, then `GAMES pro 2000` and
`GAMES college 2000`, then the two summaries, exactly one `LOSS <finite-decimal>`, and finally
`SCORE <passed>/24`. The tuner rejects any missing, duplicate, reordered, or extra model/game/loss/
score control line.

- [ ] **Step 2: Thread tier and model explicitly**

Pass `tier` and `model` from `GameEngine` through `DriveEngine`. Dispatch `.distribution` to `DistributionSnapResolver` and `.legacyHybrid` to `SnapResolver`. Do not infer tier from a clock-rule metatype. The distribution path receives `isHomeOffense: Bool` and applies exactly one tier probability shift from `OutcomeDistributionRules`; it never receives the legacy leverage-unit `homeFieldAdvantage`. Keep the legacy home argument inside the legacy dispatch only, so the two units cannot be double-applied.

- [ ] **Step 3: Replace the retired tuner coordinates**

Generalise the tuner's descriptor-anchored target from the fixed `MatchupRules.swift` basename to a
single script-owned target `OutcomeDistributionRules.swift`; contract overrides must still be
confined to the gate's byte-identical isolated fixture. Search only these exact unique static lets
and grids, in this order:

```bash
names=(passCompletionMass passSackMass passInterceptionMass \
       proRunExplosiveMass collegeRunExplosiveMass \
       maximumProbabilityShift proHomeProbabilityShift collegeHomeProbabilityShift \
       proFieldGoalBase collegeFieldGoalBase)
grids=("0.61 0.64 0.67" "0.05 0.06 0.07" "0.015 0.022 0.030" \
       "0.105 0.118 0.130" "0.135 0.151 0.165" \
       "0.01 0.02 0.03 0.04" "0.005 0.010 0.020" "0.030 0.045 0.060" \
       "0.82 0.84 0.86" "0.74 0.76 0.78")
```

Have `CalibrationScore` print exactly one `LOSS <finite-decimal>` line before `SCORE`, where loss is
the sum across failed bands of squared, band-width-normalised CI edge distance:

```swift
let lowerGap = max(0, band.lower - interval.low) / (band.upper - band.lower)
let upperGap = max(0, interval.high - band.upper) / (band.upper - band.lower)
loss += lowerGap * lowerGap + upperGap * upperGap
```

Format that control line with
`String(format: "LOSS %.12f", locale: Locale(identifier: "en_US_POSIX"), loss)` so the tuner never
depends on ambient locale or exponent formatting.

Keep advisory locking, strict control-line parsing, descriptor-relative replacement, rollback, and
all 23 existing safety contracts. Update the rollback fixture to copy the new rules target byte-for-
byte. Add exactly twelve contracts: one retired-coordinate target check; missing, duplicate,
malformed, and non-finite `LOSS`; missing, duplicate, and wrong `MODEL`; and missing, duplicate,
wrong-tier/count, and reordered-or-extra `GAMES` control lines. Pin the new total at 35 contracts.
Candidate selection is lexicographic: higher passed count wins; when passed counts tie,
strictly lower loss wins. This permits movement across score plateaus without accepting a regression.

- [ ] **Step 4: Run a bounded distribution calibration**

Run one scorer baseline on tuning seeds. Search the exact ten-coordinate grid above; retain only
lexicographic `(passed, loss)` improvements. The corrected clock is a confirmed rule, not a tuning coordinate.
Run tuning to completion, then run exposed evaluation exactly once. Do not alter bands.

- [ ] **Step 5: Apply the P4 gate**

Record both exact reports regardless of score in
`docs/plans/2026-08-10-p4-distribution-attempt-one.md`, including every estimate, CI, band, edge,
confidence grade, `SCORE`, `LOSS`, selected constants, game counts, and whether tuning/evaluation
disagree. If either scorer is below `24/24`, keep the implemented subset red and write the smallest
next distribution-calibration action in that ledger; do not fall back to hybrid. If both are
`24/24`, mark only the implemented subset green—not G5. In both cases update HANDOFF, STATUS, and
OPEN-DECISIONS with the same verdict and continue to Task 6; the falsified hybrid is not a fallback.

- [ ] **Step 6: Verify and commit**

Run syntax, 35/35 direct tool contracts, `swift build`, two independent `SimTests`,
`rewrite-tournament` on model dispatch, and `confidence-review`. Commit the ten code/rules/test/
script/research-spec paths as `feat: integrate and calibrate distribution engine`; then commit only the attempt ledger,
HANDOFF, STATUS, and OPEN-DECISIONS as `docs: record distribution calibration attempt one`.

---

### Task 6: Delete the falsified hybrid and hand off full G5 coverage

**Files:**

- Delete: `Sources/FootballSimCore/Engine/Leverage.swift`
- Delete: `Sources/FootballSimCore/Engine/SnapResolver.swift`
- Modify: `Sources/FootballSimCore/Engine/GameEngine.swift`
- Modify: `Sources/FootballSimCore/Engine/DriveEngine.swift`
- Modify: `Sources/FootballSimCore/Calibration/CalibrationHarness.swift`
- Modify: `Tools/CalibrationScore/main.swift`
- Modify: `Sources/FootballSimCore/Engine/PlayCall.swift`
- Modify: `Sources/FootballSimCore/Engine/SnapOutcome.swift`
- Modify: `Sources/FootballSimCore/Rules/MatchupRules.swift`
- Modify: `Tests/SimTests/Suites/EngineTests.swift`
- Modify: `Tests/SimTests/Suites/RulesTests.swift`
- Modify: `Tests/SimTests/Suites/CalibrationTests.swift`
- Modify: `Tests/SimTests/main.swift`
- Modify: `docs/03-MATCH-ENGINE.md`
- Modify: `docs/05-IMPLEMENTATION-PLAN.md`
- Create: `docs/superpowers/plans/2026-08-10-p4-full-g5-coverage.md`
- Modify: `docs/HANDOFF-2026-08-10.md`
- Modify: `docs/STATUS.md`
- Modify: `docs/OPEN-DECISIONS.md`

- [ ] **Step 1: Prove no production caller uses legacy**

Use `rg` plus compiler tests. Remove the entire temporary `MatchEngineModel` enum and its parameters
from `GameEngine`, `DriveEngine`, `CalibrationHarness`, `CalibrationScore`, and calibration tests;
make `DistributionSnapResolver` the sole path, and delete `Leverage`, `SnapResolver`, legacy-only
computed properties (`CoverageShell.passHelp/runCost/help`, `DefensiveCall.coverageDrain`), constants,
and tests. Remove `homeFieldAdvantage` from both `GameEngine.play` and `DriveEngine.run`; the sole
engine now receives only `isHomeOffense` internally and the tier-specific probability shift cannot
be overridden with a legacy leverage-unit public knob. Update every caller and assert the public
signatures contain no `homeFieldAdvantage`. Rename the suite entry point in `Tests/SimTests/main.swift` from `runSnapResolverTests`
to `runDistributionResolverTests`. `Assignment`, public play-call values, `SnapOutcome`, and causal records remain. The
production scan must find zero `legacyHybrid`, `Leverage.score`, or `SnapResolver.resolve` matches.
Deletion occurs after Task 5 evidence even if the interim subset is red: option (c) was already
falsified, and this task may not restore it as a hidden fallback.

- [ ] **Step 2: Preserve causal and deterministic contracts**

Run reachability, attribution, render-cannot-change-outcome, two-process fingerprints, the 24 tuning
bands (the final tuning report must be byte-identical to Task 5's selected tuning report), and all
35 tuner contracts. Reuse Task 5's single recorded deterministic evaluation report;
do not run the exposed evaluation seeds a second time.

- [ ] **Step 3: Run mandatory final reviews**

Run `rewrite-tournament` on the final resolver, `confidence-review` on the entire successor diff,
per-task review, then a whole-branch review from this plan's base commit.

- [ ] **Step 4: Keep P4 honest and write the full-G5 follow-on**

Run `./scripts/verify.sh` and `git diff --check`; record exact build/test/contract/fingerprint counts.
Update `docs/05-IMPLEMENTATION-PLAN.md` to clarify the already-operative G5 meaning: all scalar
bands in `03`/research, not merely `CalibrationBands.all`; do not weaken or phase-scope the gate.
In the same edit, split the unfinished phase into **P4a distribution successor** (this plan) and
**P4b calibration prerequisites/full G5** (the follow-on), both before P5. Explicitly move only the
minimum calibration-observable prerequisites—target stat lines, game/drive context, bounded overtime
resolution plus event records, a controlled programme-talent population, and a headless abstracted calibration kernel—from
their later-phase ownership into P4b. The kernel must run the identical 2,000 fixtures without UI,
emit every scalar/TVD input the detailed model emits, independently pass public targets, and satisfy
research §6.4's per-scalar half-band difference and per-distribution TVD thresholds. P5 then consumes,
profiles, and completes that verified kernel as the production off-screen match model; it does not
invent a second one. P6 still owns the playable schedule and season systems. This is a sequencing
correction, not permission to mark P4 complete or skip their later feature scope.

Write `docs/superpowers/plans/2026-08-10-p4-full-g5-coverage.md` before changing P4 status. Its first
task must turn every current `CalibrationBands.unimplementedMetrics` entry into one of these exact,
auditable dispositions: (a) implement and TOST-test now because the engine already produces the
underlying event; (b) implement the bounded P4b prerequisite/event accounting newly authorized in
`docs/05`; or (c) for an unset/provisional scalar, keep the gate explicitly blocked on the named
owner confirmation/spec correction while completing every machine-verifiable prerequisite. No item
may wait on executing P5 or P6, because the canonical sequence still requires P4 first. The
plan must explicitly include distance-bucketed field goals, points/drive, 40-yard touchdowns,
receiver/TE/RB target shares, modal-total/TVD shape, best-vs-worst, overtime/tie behavior, schedule
context, margin context, title-capable share, and missing college pass/rush/completion/sack/
interception bands. It must define new bands or a documented spec correction for rows where research
never supplied a scalar—never silently omit them. It must also implement every research §6.3 TVD
table (margin by required context, team score, combined total, drive outcome, play gain, and field-
goal accuracy by distance), print chi-square residual diagnostics without gating on their p-value,
and carry forward §6.6's owner-verifiable provisional-band and play-count confirmations as explicit
unmet gates rather than agent assertions.

The follow-on must contain a separate abstracted-kernel task with the same fixture IDs and context
mix as the detailed harness, both models' independent scalar/TVD reports, and the direct detailed-vs-
abstracted consistency table required by research §6.4. P4/G5 stays red until all three reports pass.

HANDOFF, STATUS, and OPEN-DECISIONS must say separately whether the 24-band subset is green, that the
distribution successor is the sole engine, and that full G5/P4 remain open on the named coverage
plan. The next action is P4b full-G5 prerequisite implementation, not P5. Never claim owner-only checks.

After these documentation edits, rerun the whole-branch review from the plan base so the reviewer
sees the final sequencing and P4b plan, then rerun `git diff --check`. Do not proceed to commits on a
review concern.

- [ ] **Step 5: Commit the retirement and handoff separately**

After the Step 3 checks pass and every Step 4 deliverable/re-review is complete, stage the two deleted engine files plus all modified
source/tool/test files and `docs/03-MATCH-ENGINE.md`; verify that exact staged allowlist and commit
`refactor: retire hybrid snap resolver`. Then stage only `docs/05-IMPLEMENTATION-PLAN.md`, the new
P4b coverage plan, HANDOFF, STATUS, and OPEN-DECISIONS; verify that five-path allowlist and commit
`docs: hand off full G5 coverage`. Finish with clean `git status --short`, `git diff --check`, and
`git log -2 --oneline`; do not squash the evidence-bearing Task 5 commits.
