import Foundation

/// Which side of the ball a fielded player is on.
public enum TeamSide: String, Sendable, Equatable, Codable {
    case offense, defense
}

/// A spot on the field, in the coordinates the whole arcade layer speaks.
///
/// Depth is yards downfield of the line of scrimmage, so it is negative behind it and the
/// quarterback starts around -5. Lateral is -1 at the left sideline and 1 at the right, which
/// keeps the renderer's job trivial while `lateralYards` supplies the real distance any physics
/// needs — a yard sideways has to cost the same as a yard forward or pursuit angles go wrong.
public struct FieldPoint: Sendable, Equatable, Codable {
    public var depth: Double
    public var lateral: Double

    public init(depth: Double, lateral: Double) {
        self.depth = depth
        self.lateral = lateral
    }

    /// Distance from the middle of the field in yards.
    public var lateralYards: Double { lateral * ArcadeTuning.fieldWidthYards / 2 }

    public static func yards(depth: Double, lateralYards: Double) -> FieldPoint {
        FieldPoint(depth: depth, lateral: lateralYards / (ArcadeTuning.fieldWidthYards / 2))
    }

    /// True distance in yards, with the lateral axis converted so it is comparable to depth.
    public func distance(to other: FieldPoint) -> Double {
        let dDepth = other.depth - depth
        let dLateral = other.lateralYards - lateralYards
        return (dDepth * dDepth + dLateral * dLateral).squareRoot()
    }

    /// Keeps a point inside the playing surface.
    public func clampedToField() -> FieldPoint {
        let margin = ArcadeTuning.sidelineMarginYards / (ArcadeTuning.fieldWidthYards / 2)
        let limit = 1 - margin
        return FieldPoint(depth: depth, lateral: Swift.min(limit, Swift.max(-limit, lateral)))
    }
}

/// A velocity, in yards per second on both axes. Lateral is in *yards*, not the -1...1 scale,
/// so that speed means the same thing in every direction.
public struct FieldVector: Sendable, Equatable, Codable {
    public var depth: Double
    public var lateralYards: Double

    public init(depth: Double = 0, lateralYards: Double = 0) {
        self.depth = depth
        self.lateralYards = lateralYards
    }

    public static let zero = FieldVector()

    public var magnitude: Double { (depth * depth + lateralYards * lateralYards).squareRoot() }

    /// Same direction, rescaled to `speed`. A zero vector stays zero.
    public func scaled(toSpeed speed: Double) -> FieldVector {
        let size = magnitude
        guard size > 0.0001 else { return .zero }
        return FieldVector(depth: depth / size * speed, lateralYards: lateralYards / size * speed)
    }

    /// The unit vector from one point to another.
    public static func direction(from origin: FieldPoint, to target: FieldPoint) -> FieldVector {
        let raw = FieldVector(
            depth: target.depth - origin.depth,
            lateralYards: target.lateralYards - origin.lateralYards
        )
        return raw.scaled(toSpeed: 1)
    }
}

/// How fast a defender is closing on a receiver right now, in yards per second.
///
/// Positive means the gap is shrinking. This is the second half of the openness question: a
/// receiver three yards clear with a safety bearing down is not open, and the indicator has to
/// say so before the throw rather than after it.
public func closingSpeed(
    defender: FieldPoint,
    defenderVelocity: FieldVector,
    receiver: FieldPoint,
    receiverVelocity: FieldVector
) -> Double {
    let gap = FieldVector(
        depth: receiver.depth - defender.depth,
        lateralYards: receiver.lateralYards - defender.lateralYards
    )
    let distance = gap.magnitude
    guard distance > 0.0001 else { return 0 }
    let unitDepth = gap.depth / distance
    let unitLateral = gap.lateralYards / distance
    let relativeDepth = defenderVelocity.depth - receiverVelocity.depth
    let relativeLateral = defenderVelocity.lateralYards - receiverVelocity.lateralYards
    return relativeDepth * unitDepth + relativeLateral * unitLateral
}

/// The ratings the spatial layer actually reads, lifted off a `Player` once per snap.
///
/// Copying a whole `Player` — dictionary and all — twenty-two times per tick would dominate the
/// frame. This is a flat value type with the numbers the kernel needs and nothing else, and it
/// is where morale cashes out into the two attributes `02` §3 says it touches.
public struct Athlete: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let position: Position
    public let jersey: Int

    public let speed: Int
    public let strength: Int
    public let agility: Int
    public let awareness: Int
    public let catching: Int
    public let routeRunning: Int
    public let breakTackle: Int
    public let vision: Int
    public let runBlock: Int
    public let passBlock: Int
    public let tackle: Int
    public let blockShed: Int
    public let passRush: Int
    public let coverage: Int
    public let throwPower: Int
    public let throwAccuracy: Int
    public let isClutch: Bool
    public let isBoomBust: Bool

    public init(player: Player, clutchApplies: Bool = false) {
        id = player.id
        name = player.name
        position = player.position
        jersey = player.jersey

        // Morale shifts the two attributes the design says it touches, and the clutch trait
        // lifts everything late in a one-score game — both are existing rules, surfaced here
        // rather than reinvented.
        let moraleShift: Int
        switch player.morale {
        case ..<25: moraleShift = -3
        case ..<40: moraleShift = -1
        case 85...: moraleShift = 3
        case 70...: moraleShift = 1
        default: moraleShift = 0
        }
        let clutchShift = (clutchApplies && player.has(.clutch)) ? 3 : 0

        func rating(_ attribute: Attribute, moraleSensitive: Bool = false) -> Int {
            let base = player.ratings[attribute] + clutchShift
            return (moraleSensitive ? base + moraleShift : base).clampedToRating()
        }

        speed = rating(.speed)
        strength = rating(.strength)
        agility = rating(.agility)
        awareness = rating(.awareness)
        catching = rating(.catching, moraleSensitive: true)
        routeRunning = rating(.routeRunning)
        breakTackle = rating(.breakTackle)
        vision = rating(.vision)
        runBlock = rating(.runBlock)
        passBlock = rating(.passBlock)
        tackle = rating(.tackle, moraleSensitive: true)
        blockShed = rating(.blockShed)
        passRush = rating(.passRush)
        coverage = rating(.coverage)
        throwPower = rating(.throwPower)
        throwAccuracy = rating(.throwAccuracy)
        isClutch = player.has(.clutch)
        isBoomBust = player.has(.boomBust)
    }

    public var topSpeed: Double { ArcadeTuning.topSpeed(speed) }
    public var acceleration: Double { ArcadeTuning.acceleration(agility) }
}

/// What a player is doing on this snap. Assignments are fixed at the snap; what happens to them
/// is not.
public enum FieldRole: Sendable, Equatable {
    case quarterback
    /// Running a route. The index keys into the snap's dealt routes.
    case receiver(routeIndex: Int)
    /// Blocking, either in protection or for a run.
    case blocker
    /// Rushing the passer.
    case rusher
    /// Covering a specific man.
    case manCoverage(target: UUID)
    /// Sitting in a zone, centred on a spot.
    case zoneCoverage(anchor: FieldPoint)
    /// Reading the run and filling.
    case runDefender
    /// Carrying the ball right now.
    case carrier
}

/// One player as the field draws and moves him.
public struct FieldedPlayer: Sendable, Equatable, Identifiable {
    public let athlete: Athlete
    public let side: TeamSide
    public var role: FieldRole
    public var point: FieldPoint
    public var velocity: FieldVector
    /// How far through his route or assignment he is, 0...1 — kept per player so the renderer
    /// can draw a stem without re-deriving it.
    public var routeProgress: Double
    /// Set when a defender has been beaten badly enough to be out of the play.
    public var isBeaten: Bool

    public var id: UUID { athlete.id }

    public init(
        athlete: Athlete,
        side: TeamSide,
        role: FieldRole,
        point: FieldPoint,
        velocity: FieldVector = .zero,
        routeProgress: Double = 0,
        isBeaten: Bool = false
    ) {
        self.athlete = athlete
        self.side = side
        self.role = role
        self.point = point
        self.velocity = velocity
        self.routeProgress = routeProgress
        self.isBeaten = isBeaten
    }

    /// Moves toward a target at the player's own pace, accelerating rather than teleporting.
    ///
    /// Speed is a stat here, exactly as the design promises: nothing the player does with their
    /// thumb changes how fast anybody runs.
    public mutating func steer(toward target: FieldPoint, dt: Double, speedScale: Double = 1) {
        let desired = FieldVector.direction(from: point, to: target)
            .scaled(toSpeed: athlete.topSpeed * speedScale)
        let accel = athlete.acceleration * dt
        var next = FieldVector(
            depth: velocity.depth + (desired.depth - velocity.depth).clampedMagnitude(to: accel),
            lateralYards: velocity.lateralYards
                + (desired.lateralYards - velocity.lateralYards).clampedMagnitude(to: accel)
        )
        let cap = athlete.topSpeed * speedScale
        if next.magnitude > cap { next = next.scaled(toSpeed: cap) }
        velocity = next
        point = FieldPoint.yards(
            depth: point.depth + velocity.depth * dt,
            lateralYards: point.lateralYards + velocity.lateralYards * dt
        ).clampedToField()
    }
}

extension Double {
    /// Clamps a delta's size while keeping its sign — the shape every acceleration limit wants.
    func clampedMagnitude(to limit: Double) -> Double {
        Swift.min(Swift.max(self, -limit), limit)
    }
}
