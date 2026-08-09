import Foundation

/// Something the player did with their hands.
public enum ArcadeAction: Sendable, Equatable {
    /// Ball is snapped. The rush clock starts when the player starts aiming, not here — reading
    /// four routes takes a beat, and a clock that punishes thinking is not a difficulty curve.
    case snap
    case beginAim
    case aim(FieldPoint)
    case setBullet(Bool)
    /// Let it go at the current aim point.
    case release
    case handOff(gapIndex: Int?)
    case scramble
    /// -1 juke left, +1 juke right.
    case juke(direction: Double)
    case dive
    case stall
}

/// One action, stamped with when it happened.
public struct TracedAction: Sendable, Equatable {
    public let time: Double
    public let action: ArcadeAction

    public init(time: Double, action: ArcadeAction) {
        self.time = time
        self.action = action
    }
}

/// A whole snap's worth of input, so a test can play a down without a device.
public struct InputTrace: Sendable, Equatable {
    public let actions: [TracedAction]

    public init(_ actions: [TracedAction]) {
        self.actions = actions.sorted { $0.time < $1.time }
    }

    public static let none = InputTrace([])
}

/// Where the snap has got to.
public enum SnapPhase: Sendable, Equatable {
    case presnap
    /// Ball in the quarterback's hands.
    case dropback
    /// Thrown, and still travelling.
    case ballInAir(arrivesAt: Double)
    /// Somebody is running with it.
    case carrying(UUID)
    /// Done — the engine takes it from here.
    case complete(SnapEnding)
}

/// How the controlled portion of the snap finished. Deliberately not an *outcome*: the kernel
/// says what the player did and what the geometry was, never whether it worked. Whether the
/// pass was caught, whether the pressure became a sack, how many yards it gained — all of that
/// is the engine's, exactly as it is for a simulated snap.
public enum SnapEnding: Sendable, Equatable {
    /// Thrown at a receiver.
    case thrown
    /// Handed off, and the carry window has run.
    case handedOff
    /// The quarterback took off.
    case scrambled
    /// The pocket collapsed with the ball still in his hands.
    case pressured
    /// Thrown at nobody in particular.
    case throwAway
    /// The window closed without an input — he takes what is there.
    case noDecision
}

/// What the player's hands were worth, in the units the engine understands.
///
/// Every field is centred so that zero means "as well as the AI would have done it". A trace
/// with no actions in it grades to all zeros, which is what makes the neutral-bot parity test
/// possible: play nothing, get the simulated game.
public struct SnapGrades: Sendable, Equatable {
    /// Yards between where the ball landed and where the receiver was.
    public var placementErrorYards: Double
    /// What the indicator said about the target when the ball was released.
    public var targetOpenness: OpennessState
    /// -1...1 against the pocket's life.
    public var releaseTiming: Double
    /// Defenders the carrier got past.
    public var pursuitBeaten: Int
    /// 0...1 — how good the lane taken was against the best one available.
    public var laneQuality: Double
    /// -1 went down cleanly, +1 fought for everything.
    public var aggression: Double
    /// How far the controlled portion travelled, for the reconciliation check.
    public var provisionalYards: Double
    public var ending: SnapEnding
    /// True when the player never touched anything.
    public var isNeutral: Bool

    public init(
        placementErrorYards: Double = 0,
        targetOpenness: OpennessState = .contested,
        releaseTiming: Double = 0,
        pursuitBeaten: Int = 0,
        laneQuality: Double = 0.5,
        aggression: Double = 0,
        provisionalYards: Double = 0,
        ending: SnapEnding = .noDecision,
        isNeutral: Bool = true
    ) {
        self.placementErrorYards = placementErrorYards
        self.targetOpenness = targetOpenness
        self.releaseTiming = releaseTiming
        self.pursuitBeaten = pursuitBeaten
        self.laneQuality = laneQuality
        self.aggression = aggression
        self.provisionalYards = provisionalYards
        self.ending = ending
        self.isNeutral = isNeutral
    }
}

/// One rendered instant: everything the field view needs and nothing it doesn't.
public struct FieldFrame: Sendable {
    public let elapsed: Double
    public let players: [FieldedPlayer]
    public let ballPoint: FieldPoint
    public let indicators: [UUID: OpennessState]
    public let lanes: [RunLane]
    public let suggestedLane: RunLane?
    public let phase: SnapPhase
    public let pocketLife: Double
    public let sackWarningActive: Bool
    public let aimPoint: FieldPoint?
    public let scatterRadius: Double
    public let visibleArcFraction: Double
    public let maxThrowYards: Double
}

/// The spatial simulation of one snap.
///
/// Deterministic in `(personnel, calls, seed, actions)`: every roll comes from the seeded stream
/// handed in, and nothing reads a clock. That is what lets the whole thing be tested headless,
/// which matters more than usual here — there is no way to unit-test a thumb.
public struct SnapKernel {

    // MARK: - Fixed at the snap

    public let call: OffensivePlay
    public let defensiveCall: DefensivePlay
    public let dials: ArcadeTuning.DifficultyDials
    public let routes: [RouteKind]
    public let pocket: PocketState
    public let lanes: [RunLane]
    public let suggestedLane: RunLane?

    // MARK: - Live state

    public private(set) var elapsed: Double = 0
    public private(set) var players: [FieldedPlayer] = []
    public private(set) var phase: SnapPhase = .presnap
    public private(set) var ballPoint: FieldPoint
    public private(set) var grades = SnapGrades()

    private var rng: SeededRandom
    private var indicatorFeed: IndicatorFeed
    private var quarterbackID: UUID
    /// Set when the player starts aiming — the rush is measured from here.
    private var aimStartedAt: Double?
    private var currentAim: FieldPoint?
    private var isBullet = true
    private var landingPoint: FieldPoint?
    private var intendedTargetID: UUID?
    private var carrierID: UUID?
    private var carryStartedAt: Double?
    private var lastJukeAt: Double?
    private var beatenDefenders: Set<UUID> = []
    /// Lagged perception, so a defender reacts at the speed his awareness allows.
    private var perceivedAim: [UUID: FieldPoint] = [:]
    private var nextPerception: [UUID: Double] = [:]
    private var routeLeg: [UUID: Int] = [:]
    private var touchedControls = false

    // MARK: - Setup

    public init(
        offense: OffensivePersonnel,
        defense: DefensivePersonnel,
        call: OffensivePlay,
        defensiveCall: DefensivePlay,
        variation: Int = 0,
        dials: ArcadeTuning.DifficultyDials = ArcadeTuning.normalDials,
        seed: UInt64
    ) {
        self.call = call
        self.defensiveCall = defensiveCall
        self.dials = dials
        var generator = SeededRandom(seed: seed)

        var offensivePlayers = Formations.offense(for: call, personnel: offense, variation: variation)
        var defensivePlayers = Formations.defense(
            for: defensiveCall, personnel: defense, variation: variation
        )
        Coverage.assign(defenders: &defensivePlayers, offense: offensivePlayers, call: defensiveCall)

        let eligibleCount = offensivePlayers.reduce(into: 0) { count, player in
            if case .receiver = player.role { count += 1 }
        }
        routes = Routes.deal(for: call, eligibleCount: eligibleCount, variation: variation)

        let blockers = offensivePlayers.filter { $0.role == .blocker }
        let rushers = defensivePlayers.filter { $0.role == .rusher }
        pocket = Pocket.resolve(blockers: blockers, rushers: rushers, rng: &generator)
        let openLanes = RunLanes.open(
            blockers: blockers, defenders: defensivePlayers, call: call, rng: &generator
        )
        lanes = openLanes
        suggestedLane = RunLanes.suggested(
            lanes: openLanes, vision: offense.backs.first?.vision ?? LeagueRules.ratingFloor,
            rng: &generator
        )

        quarterbackID = offense.quarterback.id
        ballPoint = FieldPoint.yards(depth: Formations.quarterbackDepth(call), lateralYards: 0)
        indicatorFeed = IndicatorFeed(awareness: offense.quarterback.awareness)
        rng = generator

        // Offense first, then defense — a stable order so frame diffs and tests read the same
        // way every run.
        offensivePlayers.append(contentsOf: defensivePlayers)
        players = offensivePlayers
        _ = self.updateIndicators()
    }

    // MARK: - Derived

    public var offensePlayers: [FieldedPlayer] { players.filter { $0.side == .offense } }
    public var defensePlayers: [FieldedPlayer] { players.filter { $0.side == .defense } }

    public var quarterback: FieldedPlayer? { players.first { $0.id == quarterbackID } }

    public var isOver: Bool {
        if case .complete = phase { return true }
        return false
    }

    /// How much of the arc the passer lets you see.
    public var visibleArcFraction: Double {
        ArcadeTuning.visibleArcFraction(quarterback?.athlete.throwAccuracy ?? 70)
    }

    public var maxThrowYards: Double {
        ArcadeTuning.maxThrowYards(quarterback?.athlete.throwPower ?? 70)
    }

    /// The ring drawn at the aim point: how far off the ball might land from there.
    public func scatterRadius(forAimAt aim: FieldPoint?) -> Double {
        guard let passer = quarterback else { return 0 }
        var radius = ArcadeTuning.scatterRadius(passer.athlete.throwAccuracy)
        if let aim {
            let distance = passer.point.distance(to: aim)
            radius *= ArcadeTuning.scatterDistanceFactor(throwYards: distance)
        }
        if isUnderPressure { radius *= ArcadeTuning.scatterPressureFactor }
        if passer.athlete.isBoomBust { radius *= 1.4 }
        return radius
    }

    /// True once the first rusher is through his block.
    public var isUnderPressure: Bool {
        guard let started = aimStartedAt else { return false }
        return (elapsed - started) >= pocket.life
    }

    public var sackWarningActive: Bool {
        guard let started = aimStartedAt, let passer = quarterback else { return false }
        return (elapsed - started) >= pocket.warningTime(awareness: passer.athlete.awareness)
    }

    public var frame: FieldFrame {
        FieldFrame(
            elapsed: elapsed,
            players: players,
            ballPoint: ballPoint,
            indicators: indicatorFeed.allStates,
            lanes: lanes,
            suggestedLane: suggestedLane,
            phase: phase,
            pocketLife: pocket.life,
            sackWarningActive: sackWarningActive,
            aimPoint: currentAim,
            scatterRadius: scatterRadius(forAimAt: currentAim),
            visibleArcFraction: visibleArcFraction,
            maxThrowYards: maxThrowYards
        )
    }

    // MARK: - Input

    public mutating func apply(_ action: ArcadeAction) {
        switch action {
        case .snap:
            if phase == .presnap { phase = .dropback }

        case .beginAim:
            guard phase == .dropback else { return }
            touchedControls = true
            if aimStartedAt == nil { aimStartedAt = elapsed }

        case .aim(let point):
            guard phase == .dropback else { return }
            touchedControls = true
            if aimStartedAt == nil { aimStartedAt = elapsed }
            currentAim = clampAim(point)

        case .setBullet(let bullet):
            touchedControls = true
            isBullet = bullet

        case .release:
            guard phase == .dropback, let aim = currentAim else { return }
            touchedControls = true
            throwBall(at: aim)

        case .handOff(let gapIndex):
            guard phase == .dropback else { return }
            touchedControls = true
            handOff(gapIndex: gapIndex)

        case .scramble:
            guard phase == .dropback else { return }
            touchedControls = true
            beginCarry(by: quarterbackID, ending: .scrambled)

        case .juke(let direction):
            guard case .carrying = phase else { return }
            touchedControls = true
            juke(direction: direction)

        case .dive:
            guard case .carrying = phase else { return }
            touchedControls = true
            grades.aggression = -0.8
            finishCarry()

        case .stall:
            guard case .carrying = phase else { return }
            touchedControls = true
            grades.aggression = 0.8
        }
    }

    private func clampAim(_ point: FieldPoint) -> FieldPoint {
        guard let passer = quarterback else { return point }
        let limit = maxThrowYards
        let distance = passer.point.distance(to: point)
        guard distance > limit, distance > 0.001 else { return point }
        // Out of range: the ball lands short, which is what a weak arm actually produces.
        let t = limit / distance
        return FieldPoint.yards(
            depth: passer.point.depth + (point.depth - passer.point.depth) * t,
            lateralYards: passer.point.lateralYards
                + (point.lateralYards - passer.point.lateralYards) * t
        )
    }

    // MARK: - Stepping

    /// Advances one logical tick.
    public mutating func step() {
        guard !isOver else { return }
        let dt = ArcadeTuning.secondsPerTick
        elapsed += dt

        switch phase {
        case .presnap:
            phase = .dropback

        case .dropback:
            moveOffense(dt: dt)
            moveDefense(dt: dt)
            ballPoint = quarterback?.point ?? ballPoint
            _ = updateIndicators()
            checkPressure()

        case .ballInAir(let arrivesAt):
            moveOffense(dt: dt)
            moveDefense(dt: dt)
            moveBallInFlight(dt: dt)
            if elapsed >= arrivesAt { landThrow() }

        case .carrying:
            moveCarrier(dt: dt)
            moveDefense(dt: dt)
            ballPoint = players.first { $0.id == carrierID }?.point ?? ballPoint
            checkContact()

        case .complete:
            return
        }

        if elapsed >= ArcadeTuning.maxSnapSeconds, !isOver {
            finish(.noDecision)
        }
    }

    /// Plays a whole snap from a recorded trace. The headless path every kernel test uses.
    @discardableResult
    public mutating func run(trace: InputTrace) -> SnapGrades {
        var pending = trace.actions
        var ticks = 0
        apply(.snap)
        while !isOver, ticks < ArcadeTuning.maxSnapTicks {
            while let next = pending.first, next.time <= elapsed {
                apply(next.action)
                pending.removeFirst()
            }
            guard !isOver else { break }
            step()
            ticks += 1
        }
        if !isOver { finish(.noDecision) }
        return grades
    }

    // MARK: - Movement

    private mutating func moveOffense(dt: Double) {
        for index in players.indices {
            guard players[index].side == .offense else { continue }
            switch players[index].role {
            case .receiver(let routeIndex):
                runRoute(playerIndex: index, routeIndex: routeIndex, dt: dt)
            case .quarterback:
                // Three-step drop, then hold. No free pocket movement — the design's choice.
                let target = FieldPoint.yards(
                    depth: Formations.quarterbackDepth(call) - 2.0,
                    lateralYards: players[index].point.lateralYards
                )
                if players[index].point.depth > target.depth {
                    players[index].steer(toward: target, dt: dt, speedScale: 0.55)
                }
            case .blocker:
                // Blockers hold their ground; the duel that matters is already resolved.
                players[index].velocity = .zero
            case .carrier, .rusher, .manCoverage, .zoneCoverage, .runDefender:
                continue
            }
        }
    }

    private mutating func runRoute(playerIndex: Int, routeIndex: Int, dt: Double) {
        guard routeIndex < routes.count else { return }
        let route = routes[routeIndex]
        let playerID = players[playerIndex].id
        let alignment = alignmentPoint(for: playerID) ?? players[playerIndex].point
        let leg = routeLeg[playerID] ?? 0
        let target = Routes.waypoint(route, leg: leg, from: alignment)

        let retention = Routes.cutSpeedRetention(
            route, routeRunning: players[playerIndex].athlete.routeRunning
        )
        // Speed is shed at the break and recovered afterwards, which is what separates a crisp
        // route runner from a fast one.
        let atBreak = leg > 0
        players[playerIndex].steer(
            toward: target, dt: dt, speedScale: atBreak ? retention : 1.0
        )
        players[playerIndex].routeProgress =
            Double(leg) / Double(Swift.max(1, Routes.legCount(route)))

        let tolerance = Routes.waypointTolerance(agility: players[playerIndex].athlete.agility)
        if players[playerIndex].point.distance(to: target) <= tolerance,
           leg < Routes.legCount(route) - 1 {
            routeLeg[playerID] = leg + 1
        }
    }

    /// Where a receiver lined up. Cached the first time it is asked for, because a route is
    /// measured from the alignment rather than from wherever he has run to.
    private var alignments: [UUID: FieldPoint] = [:]

    private mutating func alignmentPoint(for id: UUID) -> FieldPoint? {
        if let known = alignments[id] { return known }
        guard let player = players.first(where: { $0.id == id }) else { return nil }
        alignments[id] = player.point
        return player.point
    }

    /// Whether the ball is out of the passer's hands, which is when coverage stops playing the
    /// route and starts playing the ball.
    ///
    /// A plain property rather than an immediately-applied closure: inside a `mutating` method
    /// `self` is `inout`, and a closure that reads it there is exactly the shape Swift refuses
    /// to capture. Not worth finding out which way the compiler jumps.
    private var ballIsLoose: Bool {
        switch phase {
        case .ballInAir, .carrying: true
        case .presnap, .dropback, .complete: false
        }
    }

    private mutating func moveDefense(dt: Double) {
        let offense = offensePlayers
        let loose = ballIsLoose

        for index in players.indices {
            guard players[index].side == .defense else { continue }
            let defender = players[index]

            if case .rusher = defender.role {
                // Rushers converge on the passer from the snap, but only get past their blocker
                // when the duel says so.
                let target = ballPoint
                let started = aimStartedAt ?? elapsed
                let through = pocket.hasBrokenThrough(defender.id, at: elapsed - started)
                players[index].steer(toward: target, dt: dt, speedScale: through ? 1.0 : 0.35)
                continue
            }

            // Everybody else reacts on their own delay.
            let refreshDue = nextPerception[defender.id] ?? 0
            if elapsed >= refreshDue || perceivedAim[defender.id] == nil {
                perceivedAim[defender.id] = Coverage.aimPoint(
                    for: defender, offense: offense, ballPoint: ballPoint,
                    ballIsLoose: loose, dials: dials
                )
                let delay = ArcadeTuning.reactionDelay(defender.athlete.awareness)
                    * dials.reactionMultiplier
                nextPerception[defender.id] = elapsed + Swift.max(ArcadeTuning.secondsPerTick, delay)
            }
            let aim = perceivedAim[defender.id] ?? ballPoint
            players[index].steer(toward: aim, dt: dt, speedScale: dials.closingMultiplier)
        }
    }

    private mutating func moveCarrier(dt: Double) {
        guard let carrierID, let index = players.firstIndex(where: { $0.id == carrierID }) else { return }
        // Runs upfield at his own speed, drifting toward the lane he is in.
        let laneCenter = RunLanes.lane(containing: players[index].point, lanes: lanes)?
            .centerLateralYards ?? players[index].point.lateralYards
        let target = FieldPoint.yards(
            depth: players[index].point.depth + 6,
            lateralYards: laneCenter * 0.3 + players[index].point.lateralYards * 0.7
        )
        players[index].steer(toward: target, dt: dt, speedScale: fatigueScale)
    }

    /// Late-game legs. Transient by design — this never touches a saved rating.
    private var fatigueScale: Double = 1.0

    public mutating func applyFatigue(touches: Int, isIronMan: Bool, age: Int) {
        let past = Swift.max(0, touches - ArcadeTuning.fatigueFreeTouches)
        var loss = Double(past) * ArcadeTuning.fatiguePerTouch
        if isIronMan { loss *= 0.5 }
        if age > 30 { loss *= 1.25 }
        fatigueScale = 1 - Swift.min(ArcadeTuning.maxFatigueLoss, loss)
    }

    private mutating func moveBallInFlight(dt: Double) {
        guard let landing = landingPoint, case .ballInAir(let arrivesAt) = phase else { return }
        let remaining = Swift.max(0.0001, arrivesAt - elapsed)
        let step = Swift.min(1.0, dt / remaining)
        ballPoint = FieldPoint.yards(
            depth: ballPoint.depth + (landing.depth - ballPoint.depth) * step,
            lateralYards: ballPoint.lateralYards
                + (landing.lateralYards - ballPoint.lateralYards) * step
        )
    }

    // MARK: - Events

    @discardableResult
    private mutating func updateIndicators() -> [UUID: OpennessState] {
        let truth = Openness.survey(offense: offensePlayers, defenders: defensePlayers)
        indicatorFeed.update(truth: truth, now: elapsed)
        return truth
    }

    /// What the quarterback is being shown right now.
    public func indicator(for receiverID: UUID) -> OpennessState? {
        indicatorFeed.state(for: receiverID)
    }

    private mutating func checkPressure() {
        guard let started = aimStartedAt else { return }
        guard (elapsed - started) >= pocket.life else { return }
        // A rusher is through and has reached him: the ball has to go somewhere, and what that
        // becomes — sack, throwaway, completion under duress — is the engine's call.
        guard let passer = quarterback else { return finish(.pressured) }
        let arrived = defensePlayers.contains { defender in
            guard case .rusher = defender.role else { return false }
            return defender.point.distance(to: passer.point) <= ArcadeTuning.contactRadiusYards * 2
        }
        if arrived {
            grades.releaseTiming = -1
            finish(.pressured)
        }
    }

    private mutating func throwBall(at aim: FieldPoint) {
        guard let passer = quarterback else { return }

        // Placement scatter. A roll, but not an outcome: it decides where the ball lands, and
        // the engine still decides what happens when it gets there.
        let radius = scatterRadius(forAimAt: aim)
        let angle = rng.double01() * 2 * Double.pi
        // Square-rooting the draw spreads points evenly over the disc instead of bunching them
        // at the centre, so the ring the player is shown means what it looks like it means.
        let distance = radius * rng.double01().squareRoot()
        let landing = FieldPoint.yards(
            depth: aim.depth + Foundation.cos(angle) * distance,
            lateralYards: aim.lateralYards + Foundation.sin(angle) * distance
        )
        landingPoint = landing

        // The receiver nearest the aim point is the man being thrown at.
        let eligibles = offensePlayers.filter { if case .receiver = $0.role { return true } else { return false } }
        let target = eligibles.min { $0.point.distance(to: aim) < $1.point.distance(to: aim) }
        intendedTargetID = target?.id

        grades.targetOpenness = target.flatMap { indicatorFeed.state(for: $0.id) } ?? .contested
        let held = elapsed - (aimStartedAt ?? elapsed)
        grades.releaseTiming = ArcadeInput.releaseTiming(
            heldSeconds: held, pocketSeconds: pocket.life
        )

        let flight = passer.point.distance(to: landing)
        let speed = ArcadeTuning.ballSpeed(passer.athlete.throwPower, isBullet: isBullet)
        let hang = isBullet ? 1.0 : ArcadeTuning.lobHangFactor
        phase = .ballInAir(arrivesAt: elapsed + Swift.max(0.15, flight / speed * hang))
        ballPoint = passer.point
    }

    private mutating func landThrow() {
        guard let landing = landingPoint else { return finish(.throwAway) }
        ballPoint = landing
        guard let targetID = intendedTargetID,
              let receiver = players.first(where: { $0.id == targetID }) else {
            return finish(.throwAway)
        }
        // How far off the ball was *when it got there* — which is the only version of accuracy
        // that means anything, because the receiver has been running the whole time it was in
        // the air. This is what a weak arm costs you.
        grades.placementErrorYards = receiver.point.distance(to: landing)
        grades.provisionalYards = receiver.point.depth
        finish(.thrown)
    }

    private mutating func handOff(gapIndex: Int?) {
        guard let back = offensePlayers.last(where: {
            if case .receiver = $0.role { return $0.athlete.position == .rb } else { return false }
        }) ?? offensePlayers.first(where: { if case .receiver = $0.role { return true } else { return false } })
        else { return finish(.noDecision) }

        let chosen = gapIndex.flatMap { index in lanes.first { $0.gapIndex == index } }
            ?? suggestedLane
        if let chosen, let best = lanes.max(by: { $0.halfWidth < $1.halfWidth }), best.halfWidth > 0 {
            grades.laneQuality = Swift.min(1, chosen.halfWidth / best.halfWidth)
        }
        grades.releaseTiming = ArcadeInput.releaseTiming(
            heldSeconds: elapsed - (aimStartedAt ?? elapsed), pocketSeconds: pocket.life
        )
        beginCarry(by: back.id, ending: .handedOff)
    }

    private mutating func beginCarry(by playerID: UUID, ending: SnapEnding) {
        carrierID = playerID
        carryStartedAt = elapsed
        grades.ending = ending
        if let index = players.firstIndex(where: { $0.id == playerID }) {
            players[index].role = .carrier
        }
        phase = .carrying(playerID)
    }

    private mutating func juke(direction: Double) {
        guard let carrierID, let index = players.firstIndex(where: { $0.id == carrierID }) else { return }
        lastJukeAt = elapsed
        let sign = direction >= 0 ? 1.0 : -1.0
        let moved = FieldPoint.yards(
            depth: players[index].point.depth,
            lateralYards: players[index].point.lateralYards + sign * ArcadeTuning.jukeLateralYards
        ).clampedToField()
        players[index].point = moved
    }

    private mutating func checkContact() {
        guard let carrierID, let carrier = players.first(where: { $0.id == carrierID }) else { return }
        for defender in defensePlayers where !beatenDefenders.contains(defender.id) {
            guard defender.point.distance(to: carrier.point) <= ArcadeTuning.contactRadiusYards else {
                continue
            }
            var chance = ArcadeTuning.breakTackleChance(
                carrier: carrier.athlete.breakTackle,
                strength: carrier.athlete.strength,
                tackler: defender.athlete.tackle
            )
            // A juke inside its window is the timing skill of the run game.
            if let lastJukeAt,
               elapsed - lastJukeAt <= ArcadeTuning.jukeWindow(carrier.athlete.agility) {
                chance += ArcadeTuning.jukeTimingBonus
            }
            chance += grades.aggression * 0.08

            if rng.chance(Swift.min(0.85, chance)) {
                beatenDefenders.insert(defender.id)
                grades.pursuitBeaten += 1
                if let index = players.firstIndex(where: { $0.id == defender.id }) {
                    players[index].isBeaten = true
                }
            } else {
                grades.provisionalYards = carrier.point.depth
                finishCarry()
                return
            }
        }

        // Nobody has him, but the window for the decision is not infinite.
        if let carryStartedAt, elapsed - carryStartedAt >= (call.isRun ? 3.5 : 2.5) {
            grades.provisionalYards = carrier.point.depth
            finishCarry()
        }
    }

    private mutating func finishCarry() {
        if let carrierID, let carrier = players.first(where: { $0.id == carrierID }) {
            grades.provisionalYards = carrier.point.depth
        }
        finish(grades.ending == .noDecision ? .handedOff : grades.ending)
    }

    private mutating func finish(_ ending: SnapEnding) {
        grades.ending = ending
        grades.isNeutral = !touchedControls
        phase = .complete(ending)
    }

    // MARK: - Reconciliation

    /// Moves the ball to where the engine says the play ended.
    ///
    /// The invariant the whole design rests on: what you watched and what the box score records
    /// are the same play. The kernel's own travel is provisional — it produced the grades, the
    /// engine produced the number, and this is where the two are made to agree.
    public mutating func reconcile(officialYards: Int) {
        let target = Double(officialYards)
        ballPoint = FieldPoint.yards(depth: target, lateralYards: ballPoint.lateralYards)
        if let carrierID, let index = players.firstIndex(where: { $0.id == carrierID }) {
            players[index].point = FieldPoint.yards(
                depth: target, lateralYards: players[index].point.lateralYards
            )
        }
        grades.provisionalYards = target
    }
}
