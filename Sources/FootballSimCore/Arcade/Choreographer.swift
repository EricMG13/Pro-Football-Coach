import Foundation

/// An engine-resolved play, turned into something to watch.
public struct ChoreographedPlay: Sendable {
    public let frames: [FieldFrame]
    /// The number the box score will carry. Identical to the event's, by construction.
    public let officialYards: Int
    public let duration: Double

    public init(frames: [FieldFrame], officialYards: Int, duration: Double) {
        self.frames = frames
        self.officialYards = officialYards
        self.duration = duration
    }

    public var finalFrame: FieldFrame? { frames.last }
}

/// Animates a play the engine has already decided.
///
/// This is what replaces the text box the genre's players complain about, and it is deliberately
/// the *opposite* of the kernel: the kernel takes input and produces grades for the engine to
/// judge, while this takes the engine's judgement and produces motion. Because the outcome is
/// known before the first frame is drawn, the animation cannot contradict the box score — which
/// is the failure the reference games are remembered for.
public enum Choreographer {

    /// How long a play takes to watch at 1×, by what happened.
    static func duration(for event: PlayEvent) -> Double {
        switch event.category {
        case .sack: 2.6
        case .run, .turnover: 2.4 + Swift.min(2.5, Double(abs(event.yards)) * 0.09)
        case .pass: 2.9 + Swift.min(2.6, Double(abs(event.yards)) * 0.08)
        case .punt, .kickoff: 4.2
        case .fieldGoal, .extraPoint: 2.2
        case .kneel, .spike, .timeout, .penalty, .injury, .administrative: 1.4
        case .touchdown, .twoPointConversion: 3.0
        }
    }

    /// Builds the frame stream for one resolved play.
    public static func play(
        event: PlayEvent,
        offense: OffensivePersonnel,
        defense: DefensivePersonnel,
        call: OffensivePlay,
        defensiveCall: DefensivePlay,
        seed: UInt64
    ) -> ChoreographedPlay {
        var rng = SeededRandom(seed: seed)
        var offensePlayers = Formations.offense(for: call, personnel: offense, variation: 0)
        var defensePlayers = Formations.defense(for: defensiveCall, personnel: defense, variation: 0)
        Coverage.assign(defenders: &defensePlayers, offense: offensePlayers, call: defensiveCall)

        let eligibleCount = offensePlayers.reduce(into: 0) { count, player in
            if case .receiver = player.role { count += 1 }
        }
        let routes = Routes.deal(for: call, eligibleCount: eligibleCount, variation: 0)
        let alignments = Dictionary(
            uniqueKeysWithValues: offensePlayers.map { ($0.id, $0.point) }
        )

        let total = duration(for: event)
        let targetDepth = Double(event.yards)
        let isPass = event.category == .pass || (event.category == .turnover && call.isPass)

        // Whoever the engine says touched the ball is who the animation follows. Falling back to
        // a plausible body keeps a play with a thin stat line watchable rather than empty.
        //
        // A sack is the exception and has to be: the man carrying the ball is the passer, and he
        // is going backwards. Handing it to a receiver would draw him sprinting to a negative
        // yard line, which is not a thing that happens.
        let isSack = event.category == .sack
        let carrier = isSack
            ? offensePlayers.first { $0.role == .quarterback }
            : pickCarrier(event: event, offense: offensePlayers, isPass: isPass, rng: &rng)
        // Captured when he takes the ball rather than at the snap: a receiver has run a route by
        // then, and freezing his alignment would teleport him back to the line to catch it.
        var carrierLateral = carrier?.point.lateralYards ?? 0
        var hasTakenBall = false

        var frames: [FieldFrame] = []
        var elapsed = 0.0
        let dt = ArcadeTuning.secondsPerTick
        // The throw goes out a third of the way through a passing play; a run starts moving at
        // once. Everything after that is the ball travelling to the number the engine chose.
        let releaseAt = isPass ? total * 0.34 : (isSack ? total * 0.55 : 0.12)
        var routeLeg: [UUID: Int] = [:]

        while elapsed <= total {
            let progress = total > 0 ? Swift.min(1, elapsed / total) : 1

            // Offense: receivers run their routes, the carrier heads for the recorded spot.
            for index in offensePlayers.indices {
                let id = offensePlayers[index].id
                if id == carrier?.id, elapsed >= releaseAt {
                    if !hasTakenBall {
                        carrierLateral = offensePlayers[index].point.lateralYards
                        hasTakenBall = true
                    }
                    let carryProgress = total > releaseAt
                        ? Swift.min(1, (elapsed - releaseAt) / (total - releaseAt))
                        : 1
                    // A sack drags the passer back from wherever he had dropped to; a run starts
                    // at the line; a catch starts wherever the receiver caught it.
                    let startDepth = (isPass || isSack) ? offensePlayers[index].point.depth : 0
                    let depth = startDepth + (targetDepth - startDepth) * carryProgress
                    offensePlayers[index].point = FieldPoint.yards(
                        depth: depth, lateralYards: carrierLateral
                    ).clampedToField()
                    offensePlayers[index].role = .carrier
                    continue
                }
                switch offensePlayers[index].role {
                case .receiver(let routeIndex):
                    guard routeIndex < routes.count else { break }
                    let route = routes[routeIndex]
                    let alignment = alignments[id] ?? offensePlayers[index].point
                    let leg = routeLeg[id] ?? 0
                    let target = Routes.waypoint(route, leg: leg, from: alignment)
                    offensePlayers[index].steer(toward: target, dt: dt)
                    let tolerance = Routes.waypointTolerance(
                        agility: offensePlayers[index].athlete.agility
                    )
                    if offensePlayers[index].point.distance(to: target) <= tolerance,
                       leg < Routes.legCount(route) - 1 {
                        routeLeg[id] = leg + 1
                    }
                case .quarterback:
                    if !isPass || elapsed < releaseAt {
                        let drop = FieldPoint.yards(
                            depth: Formations.quarterbackDepth(call) - 2,
                            lateralYards: offensePlayers[index].point.lateralYards
                        )
                        offensePlayers[index].steer(toward: drop, dt: dt, speedScale: 0.5)
                    }
                case .blocker, .carrier, .rusher, .manCoverage, .zoneCoverage, .runDefender:
                    break
                }
            }

            // The ball: in the passer's hands, then in the air, then with the carrier.
            let ballPoint: FieldPoint
            if isPass, elapsed < releaseAt {
                ballPoint = offensePlayers.first { $0.role == .quarterback }?.point
                    ?? FieldPoint.yards(depth: -5, lateralYards: 0)
            } else if let carrier, let live = offensePlayers.first(where: { $0.id == carrier.id }) {
                ballPoint = live.point
            } else {
                ballPoint = FieldPoint.yards(
                    depth: targetDepth * progress, lateralYards: carrierLateral
                )
            }

            // Defense converges on the ball, arriving as it gets there rather than before.
            for index in defensePlayers.indices {
                let scale = elapsed < releaseAt ? 0.75 : 1.0
                defensePlayers[index].steer(toward: ballPoint, dt: dt, speedScale: scale)
            }

            frames.append(
                FieldFrame(
                    elapsed: elapsed,
                    players: offensePlayers + defensePlayers,
                    ballPoint: ballPoint,
                    indicators: [:],
                    lanes: [],
                    suggestedLane: nil,
                    phase: elapsed >= total ? .complete(.thrown) : .dropback,
                    pocketLife: total,
                    sackWarningActive: false,
                    aimPoint: nil,
                    scatterRadius: 0,
                    visibleArcFraction: 1,
                    maxThrowYards: 0
                )
            )
            elapsed += dt
        }

        // The last frame is pinned to the engine's number rather than to wherever the kinematics
        // happened to land. This is the fidelity invariant, enforced by construction: no amount
        // of drift in the animation above can make the play end somewhere else.
        if var last = frames.popLast() {
            var pinned = last.players
            if let carrierID = carrier?.id,
               let index = pinned.firstIndex(where: { $0.id == carrierID }) {
                pinned[index].point = FieldPoint.yards(
                    depth: targetDepth, lateralYards: carrierLateral
                ).clampedToField()
            }
            last = FieldFrame(
                elapsed: last.elapsed,
                players: pinned,
                ballPoint: FieldPoint.yards(depth: targetDepth, lateralYards: carrierLateral)
                    .clampedToField(),
                indicators: [:],
                lanes: [],
                suggestedLane: nil,
                phase: .complete(ending(for: event)),
                pocketLife: total,
                sackWarningActive: false,
                aimPoint: nil,
                scatterRadius: 0,
                visibleArcFraction: 1,
                maxThrowYards: 0
            )
            frames.append(last)
        }

        return ChoreographedPlay(frames: frames, officialYards: event.yards, duration: total)
    }

    static func ending(for event: PlayEvent) -> SnapEnding {
        switch event.category {
        case .sack: .pressured
        case .pass, .turnover: .thrown
        case .run: .handedOff
        default: .noDecision
        }
    }

    /// The man the animation follows.
    private static func pickCarrier(
        event: PlayEvent,
        offense: [FieldedPlayer],
        isPass: Bool,
        rng: inout SeededRandom
    ) -> FieldedPlayer? {
        // The engine names who was involved; prefer somebody who is actually on the field for
        // this personnel grouping.
        for id in event.involvedPlayerIDs {
            if let found = offense.first(where: { $0.id == id }), found.role != .quarterback {
                return found
            }
        }
        let eligibles = offense.filter {
            if case .receiver = $0.role { return true } else { return false }
        }
        guard !eligibles.isEmpty else { return offense.first }
        if isPass {
            // A deeper play went to somebody running deeper.
            let wanted = Double(event.yards)
            return eligibles.min {
                abs($0.point.depth - wanted) < abs($1.point.depth - wanted)
            }
        }
        return eligibles.first { $0.athlete.position == .rb } ?? eligibles[
            rng.int(in: 0...(eligibles.count - 1))
        ]
    }
}
