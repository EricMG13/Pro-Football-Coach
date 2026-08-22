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

/// Somewhere an actor is, and when it is there.
///
/// The fraction is the point of the whole thing. A waypoint without one cannot say "be at the catch
/// exactly when the ball arrives", and without that the ball and the man carrying it travel
/// independently — which is precisely how they came apart.
public struct ActorWaypoint: Codable, Sendable, Equatable {
    public let point: FieldPoint
    /// 0 to 1 of the playback.
    public let fraction: Double

    public init(point: FieldPoint, fraction: Double) {
        self.point = point
        self.fraction = Swift.min(1, Swift.max(0, fraction))
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
    /// record justifies it; see `03` §9.1. Ordered by fraction.
    public let path: [ActorWaypoint]

    public init(
        playerID: UUID,
        side: Side,
        role: SnapRole,
        start: FieldPoint,
        end: FieldPoint,
        path: [ActorWaypoint] = []
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
        /// The ball travelling between two players — centre to passer, or passer to back. Nobody is
        /// running with it, which is why it is not a `carry`: on a handoff the ball starts at the
        /// quarterback and the back is still in his stance, so demanding the carrier be on both ends
        /// of it would be demanding a thing that does not happen.
        case snap, handoff
        /// A player running with the ball. The carrier is on this leg at both ends, always.
        case carry
        /// In flight — a throw, or a kick.
        case air
        /// Live but uncontrolled: the flight after an interception.
        case loose
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
    /// A handoff completes by this point, and the back has the ball from here.
    public static let handoffFraction = 0.22
    /// A pass is in the air until this point of the playback.
    public static let releaseFraction = 0.55

    // MARK: The stride profile

    /// Share of the playback spent leaving a stance, and share spent being stopped.
    ///
    /// `03` §9.6: a straight line at constant velocity for the whole playback is not a neutral
    /// default, it is a claim that players do not accelerate — which is false, and reads as false.
    /// Both are tunable, because what looks right at roughly seven points per yard is a judgement
    /// about how a 15 pt disc reads in motion and not a number anything can derive.
    public static let strideAccelerate = 0.18
    public static let strideDecelerate = 0.22

    /// Wall-clock playback progress to progress along the authored path, under a trapezoidal
    /// velocity profile: ramp up over `strideAccelerate`, cruise, ramp down over
    /// `strideDecelerate`.
    ///
    /// Deliberately *not* applied inside `position(of:at:)`. That function works in path fractions,
    /// and the anchor set's own fractions are path fractions too — a waypoint at `handoffFraction`
    /// means "when the handoff happens", which is a fact about the play and not about the wall
    /// clock. Warping inside it would silently redefine every authored fraction and break the one
    /// invariant that matters most: that a man and the ball he is carrying are in the same place at
    /// the same moment.
    ///
    /// So this is applied once, at the single point wall time becomes a fraction, and everything
    /// downstream — every actor, every ball leg, and the loop that decides the snap is over —
    /// inherits the same warped value. That is what makes desynchronisation impossible rather than
    /// merely unlikely (§9.6 constraint 3).
    public static func pathFraction(atPlayback fraction: Double) -> Double {
        let t = Swift.min(1, Swift.max(0, fraction))
        let cruiseEnd = 1 - strideDecelerate
        // Area under the trapezoid. Dividing by it is what makes the profile land on exactly 1
        // rather than needing a clamp to get there.
        let total = 1 - strideAccelerate / 2 - strideDecelerate / 2
        let travelled: Double
        if t < strideAccelerate {
            travelled = t * t / (2 * strideAccelerate)
        } else if t <= cruiseEnd {
            travelled = strideAccelerate / 2 + (t - strideAccelerate)
        } else {
            let remaining = 1 - t
            travelled = strideAccelerate / 2 + (cruiseEnd - strideAccelerate)
                + strideDecelerate / 2 - remaining * remaining / (2 * strideDecelerate)
        }
        return Swift.min(1, Swift.max(0, travelled / total))
    }

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
    /// How far a blocker who lost his duel gets driven back off the line. Smaller than
    /// `rusherClosingYards`: this is the shove, not the rusher's own surge toward the passer.
    public static let beatenBlockerPushYards = 1.5
    /// How far of the way to the carrier's end spot a broken-tackle defender closes before the
    /// record says he missed. Short of 1 on purpose -- reaching it would draw a tackle nothing in
    /// the record says happened.
    public static let missedTackleCloseFraction = 0.7
}

/// Turns a recorded snap into a sparse spatial description of it.
///
/// Pure, total and rng-free, per `03` §9.3. It imports `Foundation` and nothing else, so it cannot
/// reach a resolver even by accident.
public enum SnapAnchors {
    /// Where a player of this position lines up.
    ///
    /// `03` §9.4: per-snap alignment is not recorded, so the start comes from this template and only
    /// the *end* comes from what the outcome recorded. Keyed on position because that is how
    /// alignment actually works, and indexed so two receivers do not stack.
    /// - Parameter isOffense: whether this player's team has the ball. Only the specialists read it,
    ///   and they read it because a kicker sets up behind his own line. It was `Side` first, which
    ///   is the wrong axis: with the away team attacking, its kicker lined up eight yards downfield
    ///   in the defence's territory.
    public static func alignment(
        for position: Position,
        index: Int,
        isOffense: Bool,
        lineOfScrimmage: Double
    ) -> FieldPoint {
        let slot = Swift.max(0, index)
        func pick(_ options: [Double]) -> Double {
            options.isEmpty ? AnchorRules.centerLateral : options[slot % options.count]
        }

        switch position {
        case .leftTackle:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.lineLaterals[0])
        case .guardPosition:
            return FieldPoint(
                yard: lineOfScrimmage,
                lateral: slot % 2 == 0 ? AnchorRules.lineLaterals[1] : AnchorRules.lineLaterals[3]
            )
        case .center:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.centerLateral)
        case .rightTackle:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.lineLaterals[4])
        case .quarterback:
            return FieldPoint(
                yard: lineOfScrimmage - AnchorRules.passerDepth,
                lateral: AnchorRules.centerLateral
            )
        case .runningBack:
            return FieldPoint(
                yard: lineOfScrimmage - AnchorRules.backDepth, lateral: AnchorRules.backLateral
            )
        case .tightEnd:
            return FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.tightEndLateral)
        case .wideReceiver:
            return FieldPoint(yard: lineOfScrimmage, lateral: pick(AnchorRules.receiverLaterals))
        case .edgeRusher:
            return FieldPoint(
                yard: lineOfScrimmage + AnchorRules.frontDepth,
                lateral: pick(AnchorRules.edgeLaterals)
            )
        case .defensiveTackle:
            return FieldPoint(
                yard: lineOfScrimmage + AnchorRules.frontDepth,
                lateral: pick(AnchorRules.interiorLaterals)
            )
        case .linebacker:
            return FieldPoint(
                yard: lineOfScrimmage + AnchorRules.linebackerDepth,
                lateral: pick(AnchorRules.linebackerLaterals)
            )
        case .cornerback:
            return FieldPoint(
                yard: lineOfScrimmage + AnchorRules.cornerDepth,
                lateral: pick(AnchorRules.cornerLaterals)
            )
        case .safety:
            return FieldPoint(
                yard: lineOfScrimmage + AnchorRules.safetyDepth,
                lateral: pick(AnchorRules.safetyLaterals)
            )
        case .kicker, .punter:
            let depth = isOffense ? -AnchorRules.specialistDepth : AnchorRules.specialistDepth
            return FieldPoint(yard: lineOfScrimmage + depth, lateral: AnchorRules.centerLateral)
        }
    }

    /// Where an actor is at a given point of the playback.
    ///
    /// The single interpolation, so the view and the tests cannot disagree about where a dot is.
    /// Walks `start`, then each waypoint in order, then `end`, and interpolates within whichever
    /// pair brackets the fraction — which is what makes a waypoint mean "be here at this moment"
    /// rather than merely "pass through here at some point".
    public static func position(of actor: ActorAnchor, at fraction: Double) -> FieldPoint {
        let t = Swift.min(1, Swift.max(0, fraction))
        var legs: [(point: FieldPoint, fraction: Double)] = [(actor.start, 0)]
        legs.append(contentsOf: actor.path.map { ($0.point, $0.fraction) })
        legs.append((actor.end, 1))

        for index in 1..<legs.count {
            let previous = legs[index - 1]
            let next = legs[index]
            guard t <= next.fraction else { continue }
            let span = next.fraction - previous.fraction
            guard span > 0 else { return next.point }
            let local = (t - previous.fraction) / span
            return FieldPoint(
                yard: previous.point.yard + (next.point.yard - previous.point.yard) * local,
                lateral: previous.point.lateral
                    + (next.point.lateral - previous.point.lateral) * local
            )
        }
        return actor.end
    }

    /// What this player was doing, read off the outcome's recorded identities first and their
    /// position second.
    ///
    /// Deliberately does not call `Assignment.assign`. The three identities the outcome already
    /// records — passer, target, carrier — answer the question for everyone who mattered, and
    /// position answers it for everyone else. Reading the record is truthful; re-deriving the
    /// assignment would be a second opinion the view has no business forming.
    public static func role(
        for playerID: UUID,
        position: Position,
        outcome: SnapOutcome,
        isOffense: Bool
    ) -> SnapRole {
        if position == .kicker || position == .punter { return .kicker }
        if playerID == outcome.passerID { return .passer }
        if playerID == outcome.ballCarrierID { return .carrier }
        if playerID == outcome.targetID { return .routeRunner }
        if isOffense {
            switch position {
            case .leftTackle, .guardPosition, .center, .rightTackle: return .blocker
            case .wideReceiver, .tightEnd: return .routeRunner
            default: return .decoy
            }
        }
        switch position {
        case .edgeRusher, .defensiveTackle: return .rusher
        case .linebacker: return .runFit
        default: return .coverage
        }
    }

    /// The sentence a VoiceOver user hears instead of watching the snap.
    ///
    /// `04` §9 requires an equivalent for every snap, and P13 requires it per snap rather than per
    /// drive.
    public static func sentence(
        for outcome: SnapOutcome,
        offense: [Player],
        defense: [Player]
    ) -> String {
        let distance = Swift.abs(outcome.yards)
        let yardWord = distance == 1 ? "yard" : "yards"
        let head: String
        switch outcome.result {
        case .gain:
            head = outcome.yards < 0
                ? "Stopped for a loss of \(distance) \(yardWord)"
                : "Gain of \(distance) \(yardWord)"
        case .incompletion: head = "Incomplete"
        case .sack: head = "Sacked for \(distance) \(yardWord)"
        case .interception: head = "Intercepted"
        case .fumbleLost: head = "Fumble lost"
        case .touchdown: head = "Touchdown, \(distance) \(yardWord)"
        case .fieldGoalGood: head = "Field goal is good"
        case .fieldGoalMissed: head = "Field goal is missed"
        case .punt: head = "Punt"
        case .safety: head = "Safety"
        case .kneel: head = "Kneel down"
        }

        guard let deciding = outcome.decidingMatchup else { return head + "." }
        let roster = offense + defense
        let duel: String
        switch deciding.kind {
        case .passProtection: duel = "the protection duel"
        case .routeVersusCoverage: duel = "the route"
        case .throwing: duel = "the throw"
        case .runLane: duel = "the run lane"
        case .carrierVersusPursuit: duel = "the pursuit"
        case .kick: duel = "the kick"
        }
        let winnerID = deciding.attackerWon ? deciding.attackerID : deciding.defenderID
        guard let winner = roster.first(where: { $0.id == winnerID }) else { return head + "." }
        return "\(head). \(winner.lastName) won \(duel)."
    }

    /// Turns one recorded snap into its anchor set.
    ///
    /// Total by construction: every branch below terminates in a set, so there is no resolved snap
    /// that has no choreography. `03` §9.3 clause 5.
    ///
    /// The caller supplies the eleven on the field for each side. `MatchSessionState` holds more
    /// than eleven per side, so the caller takes the prefix, exactly as the provider already does.
    public static func choreograph(
        play: PlayRecord,
        offense: [Player],
        defense: [Player]
    ) -> SnapAnchorSet {
        let outcome = play.outcome
        let los = Double(play.situation.yardLine)
        // Deliberately not clamped. `03` §9.3 clause 2 is unconditional — the end spot minus the
        // line of scrimmage must equal the recorded yardage — and a clamp would silently break it
        // exactly when a play reached a goal line. Clause 4 is about `FieldPoint`s, and those clamp
        // themselves, so the drawing stays on the field either way.
        let endSpot = los + Double(outcome.yards)
        let firstDown = Swift.min(100, los + Double(play.situation.distance))
        let offenseSide = play.situation.possession

        // Starts first, for everyone, because the catch spot depends on where the target lined up
        // and the carrier's movement depends on the catch spot. Deriving it once here is what stops
        // the ball and the man carrying it computing it separately and drifting apart.
        struct Placement {
            let player: Player
            let side: Side
            let isOffense: Bool
            let start: FieldPoint
            let role: SnapRole
        }

        func placements(_ players: [Player], side: Side, isOffense: Bool) -> [Placement] {
            var seen: [Position: Int] = [:]
            return players.map { player in
                let index = seen[player.position, default: 0]
                seen[player.position] = index + 1
                return Placement(
                    player: player,
                    side: side,
                    isOffense: isOffense,
                    start: alignment(
                        for: player.position, index: index, isOffense: isOffense,
                        lineOfScrimmage: los
                    ),
                    role: role(
                        for: player.id, position: player.position, outcome: outcome,
                        isOffense: isOffense
                    )
                )
            }
        }

        let placed = placements(offense, side: offenseSide, isOffense: true)
            + placements(defense, side: offenseSide.opponent, isOffense: false)

        // Where a completed pass is caught. Nil on anything that is not a pass to a named target,
        // and the single source both the receiver's path and the ball's legs read.
        let catchSpot: FieldPoint? = {
            guard play.offensiveCall.playType == .pass,
                  let targetID = outcome.targetID,
                  // The target must actually have finished with the ball. A sack can name a target
                  // for a throw that never left, and an interception names one who did not catch
                  // it; neither is a completion, and drawing one would be inventing a catch.
                  outcome.ballCarrierID == targetID,
                  let target = placed.first(where: { $0.player.id == targetID })
            else { return nil }
            return FieldPoint(
                yard: los + Double(play.offensiveCall.passDepth.airYards),
                lateral: target.start.lateral
            )
        }()

        // Where the ball comes to rest, and when the man carrying it has it. Both are needed by the
        // pursuit rule, which is `03` §9.6: the defender the record names ends where the ball ends.
        let ballRestsAt = FieldPoint(
            yard: endSpot,
            lateral: catchSpot?.lateral
                ?? placed.first { $0.player.id == outcome.ballCarrierID }?.start.lateral
                ?? AnchorRules.centerLateral
        )
        let carryBegins: Double = {
            if catchSpot != nil { return AnchorRules.releaseFraction }
            guard let carrierID = outcome.ballCarrierID, carrierID != outcome.passerID else {
                return AnchorRules.snapFraction
            }
            return AnchorRules.handoffFraction
        }()
        // Every pursuit attempt the carrier faced, in the order `SnapResolver.yardsAfterContact`
        // made them. Only the first ever lands in `matchups`; the rest, if any, are
        // `brokenTackleAttempts` — kept out of `matchups` so recording them cannot move
        // `playByPlayFingerprint` (see that property's own comment). Combining them here is what
        // lets a chain of more than one attempt still find its closing tackler.
        let pursuitAttempts = outcome.matchups.filter { $0.kind == .carrierVersusPursuit }
            + outcome.brokenTackleAttempts

        // The one defender the record names as having ended the play. `.carrierVersusPursuit` names
        // the tackler outright; a lost protection duel names the rusher who got home. Nobody else
        // converges, because nobody else is recorded — see `03` §9.6.
        let closingDefenderID: UUID? = {
            // Only when he actually won it. `.carrierVersusPursuit` names the carrier as attacker,
            // so `attackerWon` means the carrier broke the tackle — and drawing that defender
            // arriving at the end spot would claim a stop he did not make. On a touchdown it would
            // put a tackler on the goal line of a play nobody stopped. The chain stops the instant
            // a defender wins, so at most one attempt in the whole sequence can be a loss.
            if let pursuit = pursuitAttempts.first(where: { !$0.attackerWon }) {
                return pursuit.defenderID
            }
            if outcome.result == .sack || outcome.result == .safety,
               let beaten = outcome.matchups.first(where: {
                   $0.kind == .passProtection && !$0.attackerWon
               }) {
                return beaten.defenderID
            }
            return nil
        }()

        // Every attempt the carrier won — closed on him, missed. `firstIndex` rather than a running
        // count because the same defender can appear twice: the resolver clamps to the last man in
        // the pursuit list once the attempt count outruns how many defenders are actually there.
        var brokenTackleDefenderIDs: [UUID] = []
        for attempt in pursuitAttempts where attempt.attackerWon {
            if !brokenTackleDefenderIDs.contains(attempt.defenderID) {
                brokenTackleDefenderIDs.append(attempt.defenderID)
            }
        }

        let actors = placed.map { placement in
            if placement.player.id == closingDefenderID {
                return ActorAnchor(
                    playerID: placement.player.id,
                    side: placement.side,
                    role: placement.role,
                    start: placement.start,
                    end: ballRestsAt,
                    // He holds his alignment until the carrier actually has the ball, then closes,
                    // arriving as the ball does. The tackle is not a mark of its own — it is two
                    // dots the record says met, meeting.
                    path: [ActorWaypoint(point: placement.start, fraction: carryBegins)]
                )
            }
            if let index = brokenTackleDefenderIDs.firstIndex(of: placement.player.id) {
                // Spread evenly across the after-contact window, in the order the attempts actually
                // happened — real data. Exact timing within that order is not recorded, so evenly
                // spaced is the least invented placement, not a claim of precision the record does
                // not support.
                let fraction = carryBegins + (1 - carryBegins)
                    * Double(index + 1) / Double(brokenTackleDefenderIDs.count + 1)
                let closePoint = FieldPoint(
                    yard: placement.start.yard
                        + (ballRestsAt.yard - placement.start.yard)
                        * AnchorRules.missedTackleCloseFraction,
                    lateral: placement.start.lateral
                        + (ballRestsAt.lateral - placement.start.lateral)
                        * AnchorRules.missedTackleCloseFraction
                )
                return ActorAnchor(
                    playerID: placement.player.id,
                    side: placement.side,
                    role: placement.role,
                    start: placement.start,
                    end: closePoint,
                    path: [ActorWaypoint(point: placement.start, fraction: fraction)]
                )
            }
            let movement = movement(
                role: placement.role,
                start: placement.start,
                playerID: placement.player.id,
                call: play.offensiveCall,
                outcome: outcome,
                lineOfScrimmage: los,
                endSpot: endSpot,
                catchSpot: catchSpot
            )
            return ActorAnchor(
                playerID: placement.player.id,
                side: placement.side,
                role: placement.role,
                start: placement.start,
                end: movement.end,
                path: movement.path
            )
        }

        let deciding = outcome.decidingMatchup.map {
            DecidingMark(
                kind: $0.kind, attackerID: $0.attackerID, defenderID: $0.defenderID,
                attackerWon: $0.attackerWon
            )
        }

        // Only actors actually on the field may be foregrounded. A deciding matchup can name a
        // player outside the eleven the caller passed — the resolver sees the whole personnel group
        // — and `MatchDayReadModel` throws `unknownForegroundActor` on an identifier it cannot find.
        // Filtering here rather than letting the boundary reject it is what keeps this total.
        let onField = Set(actors.map(\.playerID))
        var foreground: [UUID] = []
        func foregroundIfPresent(_ id: UUID?) {
            guard let id, onField.contains(id), !foreground.contains(id) else { return }
            foreground.append(id)
        }
        foregroundIfPresent(deciding?.attackerID)
        foregroundIfPresent(deciding?.defenderID)
        foregroundIfPresent(outcome.ballCarrierID)
        // prefix rather than validation: `04` §9's cap is met by construction, which is the other
        // half of what keeps this function total.
        foreground = Array(foreground.prefix(AnchorRules.maximumForegrounded))

        let duration = Swift.min(
            AnchorRules.maximumPlaybackSeconds,
            Swift.max(
                AnchorRules.minimumPlaybackSeconds,
                Double(outcome.secondsElapsed) * AnchorRules.clockToPlaybackRatio
            )
        )

        return SnapAnchorSet(
            lineOfScrimmage: los,
            firstDownLine: firstDown,
            endSpot: endSpot,
            actors: actors,
            ball: ballPath(
                outcome: outcome, call: play.offensiveCall, actors: actors,
                lineOfScrimmage: los, endSpot: endSpot, catchSpot: catchSpot
            ),
            deciding: deciding,
            foregroundIDs: foreground,
            durationSeconds: duration,
            sentence: sentence(for: outcome, offense: offense, defense: defense)
        )
    }

    /// Where an actor goes, and when. Nothing moves without a field in the record naming why.
    private static func movement(
        role: SnapRole,
        start: FieldPoint,
        playerID: UUID,
        call: OffensiveCall,
        outcome: SnapOutcome,
        lineOfScrimmage: Double,
        endSpot: Double,
        catchSpot: FieldPoint?
    ) -> (end: FieldPoint, path: [ActorWaypoint]) {
        switch role {
        case .carrier:
            // A receiver who caught it runs *from the catch*, not from his stance. Holding the line
            // until the ball arrives, then breaking for the end spot, is what keeps him under it —
            // and the catch spot is the same value the ball's legs use, so they cannot disagree.
            if let catchSpot, outcome.targetID == outcome.ballCarrierID {
                return (
                    FieldPoint(yard: endSpot, lateral: catchSpot.lateral),
                    [ActorWaypoint(point: catchSpot, fraction: AnchorRules.releaseFraction)]
                )
            }
            // A runner holds his stance until the handoff reaches him, then breaks for the end spot.
            return (
                FieldPoint(yard: endSpot, lateral: start.lateral),
                [ActorWaypoint(point: start, fraction: AnchorRules.handoffFraction)]
            )

        case .passer:
            // A quarterback who is also the ball carrier goes where the ball goes. `role` tests
            // `passerID` before `ballCarrierID`, so this branch owns every case where they are the
            // same man — sacked, tackled for a safety, or keeping it himself — and without it he
            // stood at his drop point while the ball travelled off without him. Asking the record
            // who has the ball is truer than listing the results in which he might.
            guard outcome.ballCarrierID == outcome.passerID, outcome.ballCarrierID != nil else {
                return (start, [])
            }
            return (
                FieldPoint(yard: endSpot, lateral: start.lateral),
                [ActorWaypoint(point: start, fraction: AnchorRules.snapFraction)]
            )

        case .routeRunner:
            // Only on a pass. `passDepth` carries a default on every call, so reading it on a run
            // would send every receiver twelve yards downfield off a handoff — movement invented
            // from a field that meant nothing, which is exactly what `04` §9 prohibits.
            guard call.playType == .pass else { return (start, []) }
            // Recorded depth, not an invented route shape: the call's air yards are the only
            // downfield distance the record actually holds.
            return (
                FieldPoint(
                    yard: lineOfScrimmage + Double(call.passDepth.airYards), lateral: start.lateral
                ),
                []
            )

        case .rusher:
            return (
                FieldPoint(
                    yard: lineOfScrimmage - AnchorRules.rusherClosingYards, lateral: start.lateral
                ),
                []
            )

        case .blocker:
            // Blocking needs no engine change (Phase 5): `.passProtection` and `.runLane` duels are
            // already in `outcome.matchups`, keyed on this player as the attacker. A blocker who
            // held his ground is drawn exactly as he lined up — the winning case needs no invented
            // motion, and `04` §995 forbids drawing more than the record supports.
            guard let duel = outcome.matchups.first(where: {
                ($0.kind == .passProtection || $0.kind == .runLane) && $0.attackerID == playerID
            }), !duel.attackerWon else {
                return (start, [])
            }
            return (
                FieldPoint(yard: start.yard - AnchorRules.beatenBlockerPushYards,
                          lateral: start.lateral),
                []
            )

        case .decoy, .coverage, .runFit, .kicker, .blockLeverage:
            return (start, [])
        }
    }

    /// The ball's journey, as legs with when each happens.
    private static func ballPath(
        outcome: SnapOutcome,
        call: OffensiveCall,
        actors: [ActorAnchor],
        lineOfScrimmage: Double,
        endSpot: Double,
        catchSpot: FieldPoint?
    ) -> [BallSegment] {
        let centre = FieldPoint(yard: lineOfScrimmage, lateral: AnchorRules.centerLateral)
        func point(_ id: UUID?) -> FieldPoint? {
            guard let id else { return nil }
            return actors.first(where: { $0.playerID == id })?.start
        }
        let passerSpot = point(outcome.passerID)
            ?? FieldPoint(
                yard: lineOfScrimmage - AnchorRules.passerDepth,
                lateral: AnchorRules.centerLateral
            )
        let snap = BallSegment(
            kind: .snap, from: centre, to: passerSpot,
            startFraction: 0, endFraction: AnchorRules.snapFraction
        )

        switch outcome.result {
        case .incompletion, .interception:
            let targetLateral = point(outcome.targetID)?.lateral ?? AnchorRules.centerLateral
            let landing = FieldPoint(
                yard: lineOfScrimmage + Double(call.passDepth.airYards), lateral: targetLateral
            )
            var path = [snap, BallSegment(
                kind: .air, from: passerSpot, to: landing,
                startFraction: AnchorRules.snapFraction, endFraction: AnchorRules.releaseFraction
            )]
            if outcome.result == .interception {
                path.append(BallSegment(
                    kind: .loose, from: landing,
                    to: FieldPoint(yard: endSpot, lateral: targetLateral),
                    startFraction: AnchorRules.releaseFraction, endFraction: 1
                ))
            }
            return path

        case .sack, .kneel, .gain, .touchdown, .fumbleLost, .fieldGoalGood, .fieldGoalMissed,
             .punt, .safety:
            // The caller's catch spot, not a second computation of it. Two derivations of the same
            // point are two things that can drift, and drift is what put the receiver and the ball
            // in different places.
            if let catchSpot {
                return [snap, BallSegment(
                    kind: .air, from: passerSpot, to: catchSpot,
                    startFraction: AnchorRules.snapFraction,
                    endFraction: AnchorRules.releaseFraction
                ), BallSegment(
                    kind: .carry, from: catchSpot,
                    to: FieldPoint(yard: endSpot, lateral: catchSpot.lateral),
                    startFraction: AnchorRules.releaseFraction, endFraction: 1
                )]
            }
            // A kick flies; nobody runs it. Calling that a carry would oblige a carrier to be under
            // it at both ends, which is not what a field goal or a punt is.
            if call.playType == .fieldGoal || call.playType == .punt {
                return [snap, BallSegment(
                    kind: .air, from: passerSpot,
                    to: FieldPoint(yard: endSpot, lateral: AnchorRules.centerLateral),
                    startFraction: AnchorRules.snapFraction, endFraction: 1
                )]
            }
            // A handoff: the ball goes to the back, and only then is it carried. Modelling the
            // transfer is what lets the carry leg mean "a player is running with this".
            if let carrierSpot = point(outcome.ballCarrierID), outcome.ballCarrierID != outcome.passerID {
                return [snap, BallSegment(
                    kind: .handoff, from: passerSpot, to: carrierSpot,
                    startFraction: AnchorRules.snapFraction,
                    endFraction: AnchorRules.handoffFraction
                ), BallSegment(
                    kind: .carry, from: carrierSpot,
                    to: FieldPoint(yard: endSpot, lateral: carrierSpot.lateral),
                    startFraction: AnchorRules.handoffFraction, endFraction: 1
                )]
            }
            // The passer kept it himself.
            return [snap, BallSegment(
                kind: .carry, from: passerSpot,
                to: FieldPoint(yard: endSpot, lateral: passerSpot.lateral),
                startFraction: AnchorRules.snapFraction, endFraction: 1
            )]
        }
    }
}
