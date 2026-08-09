import Foundation

/// One point on a route, relative to where the receiver lined up.
///
/// `inside` is positive toward the middle of the field rather than toward a fixed sideline, so
/// the same post route works from either hash without a mirrored copy of the table.
public struct RouteWaypoint: Sendable, Equatable {
    public let depth: Double
    public let inside: Double

    public init(depth: Double, inside: Double) {
        self.depth = depth
        self.inside = inside
    }
}

/// The route tree. Deliberately small — these are the shapes a 2D field can read at a glance on
/// a phone, not a real playbook's hundred branches.
public enum RouteKind: String, Sendable, CaseIterable, Equatable {
    case flat, slant, drag, curl, out, comeback, post, corner, go, wheel, screen

    public var displayName: String {
        switch self {
        case .flat: "Flat"
        case .slant: "Slant"
        case .drag: "Drag"
        case .curl: "Curl"
        case .out: "Out"
        case .comeback: "Comeback"
        case .post: "Post"
        case .corner: "Corner"
        case .go: "Go"
        case .wheel: "Wheel"
        case .screen: "Screen"
        }
    }

    /// How far downfield the route ends up — what the depth bands in `06` are talking about.
    public var breakDepth: Double {
        switch self {
        case .screen: -1.5
        case .flat: 2.5
        case .slant: 5.5
        case .drag: 6.0
        case .curl: 11.0
        case .out: 9.0
        case .comeback: 14.0
        case .post: 22.0
        case .corner: 19.0
        case .go: 28.0
        case .wheel: 16.0
        }
    }

    public var waypoints: [RouteWaypoint] {
        switch self {
        case .screen:
            [RouteWaypoint(depth: -2.0, inside: -3.0), RouteWaypoint(depth: -1.0, inside: -8.0)]
        case .flat:
            [RouteWaypoint(depth: 1.5, inside: -4.0), RouteWaypoint(depth: 2.5, inside: -9.0)]
        case .slant:
            [RouteWaypoint(depth: 2.5, inside: 1.0), RouteWaypoint(depth: 6.5, inside: 8.0)]
        case .drag:
            [RouteWaypoint(depth: 3.0, inside: 2.0), RouteWaypoint(depth: 6.0, inside: 14.0)]
        case .curl:
            [RouteWaypoint(depth: 12.5, inside: 0), RouteWaypoint(depth: 10.5, inside: 1.5)]
        case .out:
            [RouteWaypoint(depth: 9.0, inside: 0), RouteWaypoint(depth: 9.5, inside: -7.0)]
        case .comeback:
            [RouteWaypoint(depth: 16.0, inside: 0), RouteWaypoint(depth: 13.0, inside: -3.0)]
        case .post:
            [RouteWaypoint(depth: 12.0, inside: 0), RouteWaypoint(depth: 24.0, inside: 11.0)]
        case .corner:
            [RouteWaypoint(depth: 11.0, inside: 0), RouteWaypoint(depth: 20.0, inside: -9.0)]
        case .go:
            [RouteWaypoint(depth: 14.0, inside: 0.5), RouteWaypoint(depth: 30.0, inside: 0)]
        case .wheel:
            [RouteWaypoint(depth: 1.0, inside: -6.0), RouteWaypoint(depth: 17.0, inside: -8.0)]
        }
    }

    /// How much speed a receiver sheds turning this corner, before his route running is applied.
    var cutSeverity: Double {
        switch self {
        case .go, .screen, .flat: 0.15
        case .slant, .drag, .wheel: 0.35
        case .post, .corner: 0.45
        case .curl, .out, .comeback: 0.65
        }
    }
}

/// Which routes each play call deals, and how an audible re-deals them.
public enum Routes {

    /// The concepts behind each call. Order matters: index 0 goes to the first eligible.
    public static func concept(for call: OffensivePlay) -> [RouteKind] {
        switch call {
        case .deepPass: [.go, .post, .comeback, .flat, .wheel]
        case .playAction: [.corner, .drag, .go, .flat, .curl]
        case .screen: [.screen, .flat, .slant, .drag, .curl]
        case .shortPass: [.curl, .slant, .out, .flat, .drag]
        // A run still sends receivers somewhere — they block or clear out, and if the play
        // becomes a scramble the quarterback needs somebody to find.
        case .insideRun, .outsideRun: [.drag, .go, .flat, .slant, .curl]
        default: [.flat, .slant, .curl, .drag, .go]
        }
    }

    /// The routes actually run on this snap.
    ///
    /// An audible rotates the concept rather than replacing it: the same call, dealt differently,
    /// which is what an audible is. The play's identity — and so the engine's matchup — is
    /// untouched, so re-dealing can never be a way to call a different play for free.
    public static func deal(
        for call: OffensivePlay,
        eligibleCount: Int,
        variation: Int = 0
    ) -> [RouteKind] {
        let concept = concept(for: call)
        guard !concept.isEmpty, eligibleCount > 0 else { return [] }
        let rotation = variation % concept.count
        var dealt: [RouteKind] = []
        for index in 0..<eligibleCount {
            dealt.append(concept[(index + rotation) % concept.count])
        }
        return dealt
    }

    /// The absolute spot a receiver is aiming at for a given leg of his route.
    ///
    /// `insideSign` is +1 when the middle of the field is to the receiver's right and -1 when it
    /// is to his left, which is what makes one waypoint table serve both sides.
    public static func waypoint(
        _ route: RouteKind,
        leg: Int,
        from alignment: FieldPoint
    ) -> FieldPoint {
        let points = route.waypoints
        guard !points.isEmpty else { return alignment }
        let index = Swift.min(Swift.max(leg, 0), points.count - 1)
        let step = points[index]
        let insideSign: Double = alignment.lateralYards <= 0 ? 1 : -1
        return FieldPoint.yards(
            depth: alignment.depth + step.depth,
            lateralYards: alignment.lateralYards + step.inside * insideSign
        ).clampedToField()
    }

    public static func legCount(_ route: RouteKind) -> Int { route.waypoints.count }

    /// How much of his speed a receiver keeps through a cut.
    ///
    /// This is where route running shows up on the field: a crisp receiver barely slows at the
    /// break, a poor one drifts through it and gives the defender the yard back.
    public static func cutSpeedRetention(_ route: RouteKind, routeRunning: Int) -> Double {
        let craft = ArcadeTuning.curve(routeRunning, at40: 0.45, at99: 0.95)
        return Swift.min(1.0, Swift.max(0.25, 1.0 - route.cutSeverity * (1 - craft)))
    }

    /// How close counts as having reached a waypoint. Scaled a little by agility so a nimble
    /// receiver actually hits his landmark rather than rounding it off.
    public static func waypointTolerance(agility: Int) -> Double {
        ArcadeTuning.curve(agility, at40: 1.3, at99: 0.7)
    }
}
