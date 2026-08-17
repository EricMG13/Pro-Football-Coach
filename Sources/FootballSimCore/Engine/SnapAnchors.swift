import Foundation

/// Where something is, in the space `03` §9.2 defines.
///
/// Offense-relative on purpose. `yard` matches `Situation.yardLine` so the two never need a
/// conversion inside the engine, and the engine never learns which way the offence faces — that is
/// presentation, and the provider owns it.
public struct FieldPoint: Codable, Sendable, Equatable {
    /// 0 to 100, from the offence's own goal line.
    public let yard: Double
    /// 0 to 1, across the field.
    public let lateral: Double

    /// Clamping here rather than validating at a boundary is what lets `SnapAnchors.choreograph`
    /// stay total, per `03` §9.3 clause 5: there is no point it can be handed that it must reject.
    public init(yard: Double, lateral: Double) {
        self.yard = Swift.min(100, Swift.max(0, yard))
        self.lateral = Swift.min(1, Swift.max(0, lateral))
    }
}

/// One player's movement across one snap.
public struct ActorAnchor: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let side: Side
    public let role: SnapRole
    public let start: FieldPoint
    public let end: FieldPoint
    /// Sparse by design, and empty for most actors on most snaps. A point appears here only when the
    /// record justifies it; see `03` §9.1.
    public let path: [FieldPoint]

    public init(
        playerID: UUID,
        side: Side,
        role: SnapRole,
        start: FieldPoint,
        end: FieldPoint,
        path: [FieldPoint] = []
    ) {
        self.playerID = playerID
        self.side = side
        self.role = role
        self.start = start
        self.end = end
        self.path = path
    }
}

/// One leg of the ball's journey, with when it happens as a fraction of the playback.
public struct BallSegment: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case snap, carry, air, loose
    }

    public let kind: Kind
    public let from: FieldPoint
    public let to: FieldPoint
    public let startFraction: Double
    public let endFraction: Double

    public init(
        kind: Kind,
        from: FieldPoint,
        to: FieldPoint,
        startFraction: Double,
        endFraction: Double
    ) {
        self.kind = kind
        self.from = from
        self.to = to
        self.startFraction = Swift.min(1, Swift.max(0, startFraction))
        self.endFraction = Swift.min(1, Swift.max(0, endFraction))
    }
}

/// The duel that decided the snap, carried through so the view can draw a sack as the protection
/// duel that lost rather than as a generic event. This is the point of D2.
public struct DecidingMark: Codable, Sendable, Equatable {
    public let kind: MatchupRecord.Kind
    public let attackerID: UUID
    public let defenderID: UUID
    public let attackerWon: Bool

    public init(kind: MatchupRecord.Kind, attackerID: UUID, defenderID: UUID, attackerWon: Bool) {
        self.kind = kind
        self.attackerID = attackerID
        self.defenderID = defenderID
        self.attackerWon = attackerWon
    }
}

/// Everything the view needs to animate one recorded snap, and nothing it could use to change one.
public struct SnapAnchorSet: Codable, Sendable, Equatable {
    public let lineOfScrimmage: Double
    public let firstDownLine: Double
    public let endSpot: Double
    public let actors: [ActorAnchor]
    public let ball: [BallSegment]
    public let deciding: DecidingMark?
    /// At most three, per `04` §9. Held to that by construction in `choreograph`.
    public let foregroundIDs: [UUID]
    public let durationSeconds: Double
    /// The VoiceOver equivalent P13 requires for every snap.
    public let sentence: String

    public init(
        lineOfScrimmage: Double,
        firstDownLine: Double,
        endSpot: Double,
        actors: [ActorAnchor],
        ball: [BallSegment],
        deciding: DecidingMark?,
        foregroundIDs: [UUID],
        durationSeconds: Double,
        sentence: String
    ) {
        self.lineOfScrimmage = lineOfScrimmage
        self.firstDownLine = firstDownLine
        self.endSpot = endSpot
        self.actors = actors
        self.ball = ball
        self.deciding = deciding
        self.foregroundIDs = foregroundIDs
        self.durationSeconds = durationSeconds
        self.sentence = sentence
    }
}

/// Geometry and timing constants for the anchor contract.
///
/// Rules constants, and they live here rather than inline for the reason `CLAUDE.md` gives: a magic
/// number in a view is a value nothing can test and nobody can find.
public enum AnchorRules {
    // MARK: Playback timing

    public static let minimumPlaybackSeconds = 1.6
    public static let maximumPlaybackSeconds = 6.0
    /// Playback compresses clock time. A snap that burned 40 seconds does not animate for 40.
    public static let clockToPlaybackRatio = 0.55

    /// The ball leaves the centre over this share of the playback.
    public static let snapFraction = 0.12
    /// A pass is in the air until this point of the playback.
    public static let releaseFraction = 0.55

    // MARK: Alignment, offense

    public static let lineLaterals: [Double] = [0.38, 0.44, 0.50, 0.56, 0.62]
    public static let centerLateral = 0.50
    public static let passerDepth = 5.0
    public static let backDepth = 6.0
    public static let backLateral = 0.44
    public static let tightEndLateral = 0.68
    public static let receiverLaterals: [Double] = [0.12, 0.88, 0.26, 0.74]

    // MARK: Alignment, defense

    public static let frontDepth = 1.0
    public static let edgeLaterals: [Double] = [0.34, 0.66]
    public static let interiorLaterals: [Double] = [0.46, 0.54]
    public static let linebackerDepth = 5.0
    public static let linebackerLaterals: [Double] = [0.36, 0.50, 0.64]
    public static let cornerDepth = 7.0
    public static let cornerLaterals: [Double] = [0.12, 0.88]
    public static let safetyDepth = 13.0
    public static let safetyLaterals: [Double] = [0.34, 0.66]

    // MARK: Movement

    /// How close a rusher gets to the passer when the duel is lost.
    public static let rusherClosingYards = 4.0
    /// How far a specialist stands off the formation.
    public static let specialistDepth = 8.0
    public static let maximumForegrounded = 3
}
