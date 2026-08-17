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

        func anchors(_ players: [Player], side: Side, isOffense: Bool) -> [ActorAnchor] {
            var seen: [Position: Int] = [:]
            return players.map { player in
                let index = seen[player.position, default: 0]
                seen[player.position] = index + 1
                let start = alignment(
                    for: player.position, index: index, isOffense: isOffense, lineOfScrimmage: los
                )
                let assigned = role(
                    for: player.id, position: player.position, outcome: outcome,
                    isOffense: isOffense
                )
                return ActorAnchor(
                    playerID: player.id,
                    side: side,
                    role: assigned,
                    start: start,
                    end: destination(
                        role: assigned, start: start, call: play.offensiveCall,
                        lineOfScrimmage: los, endSpot: endSpot
                    )
                )
            }
        }

        let actors = anchors(offense, side: offenseSide, isOffense: true)
            + anchors(defense, side: offenseSide.opponent, isOffense: false)

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
                lineOfScrimmage: los, endSpot: endSpot
            ),
            deciding: deciding,
            foregroundIDs: foreground,
            durationSeconds: duration,
            sentence: sentence(for: outcome, offense: offense, defense: defense)
        )
    }

    /// Where an actor finishes. Nothing moves without a field in the record naming why.
    private static func destination(
        role: SnapRole,
        start: FieldPoint,
        call: OffensiveCall,
        lineOfScrimmage: Double,
        endSpot: Double
    ) -> FieldPoint {
        switch role {
        case .carrier:
            return FieldPoint(yard: endSpot, lateral: start.lateral)
        case .routeRunner:
            // Only on a pass. `passDepth` carries a default on every call, so reading it on a run
            // would send every receiver twelve yards downfield off a handoff — movement invented
            // from a field that meant nothing, which is exactly what `04` §9 prohibits.
            guard call.playType == .pass else { return start }
            // Recorded depth, not an invented route shape: the call's air yards are the only
            // downfield distance the record actually holds.
            return FieldPoint(
                yard: lineOfScrimmage + Double(call.passDepth.airYards), lateral: start.lateral
            )
        case .rusher:
            return FieldPoint(
                yard: lineOfScrimmage - AnchorRules.rusherClosingYards, lateral: start.lateral
            )
        case .passer, .blocker, .decoy, .coverage, .runFit, .kicker, .blockLeverage:
            return start
        }
    }

    /// The ball's journey, as legs with when each happens.
    private static func ballPath(
        outcome: SnapOutcome,
        call: OffensiveCall,
        actors: [ActorAnchor],
        lineOfScrimmage: Double,
        endSpot: Double
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

        case .sack, .kneel:
            return [snap, BallSegment(
                kind: .carry, from: passerSpot,
                to: FieldPoint(yard: endSpot, lateral: passerSpot.lateral),
                startFraction: AnchorRules.snapFraction, endFraction: 1
            )]

        case .gain, .touchdown, .fumbleLost, .fieldGoalGood, .fieldGoalMissed, .punt, .safety:
            if call.playType == .pass, let targetSpot = point(outcome.targetID) {
                let catchSpot = FieldPoint(
                    yard: lineOfScrimmage + Double(call.passDepth.airYards),
                    lateral: targetSpot.lateral
                )
                return [snap, BallSegment(
                    kind: .air, from: passerSpot, to: catchSpot,
                    startFraction: AnchorRules.snapFraction,
                    endFraction: AnchorRules.releaseFraction
                ), BallSegment(
                    kind: .carry, from: catchSpot,
                    to: FieldPoint(yard: endSpot, lateral: targetSpot.lateral),
                    startFraction: AnchorRules.releaseFraction, endFraction: 1
                )]
            }
            let endLateral = point(outcome.ballCarrierID)?.lateral ?? AnchorRules.centerLateral
            return [snap, BallSegment(
                kind: .carry, from: passerSpot,
                to: FieldPoint(yard: endSpot, lateral: endLateral),
                startFraction: AnchorRules.snapFraction, endFraction: 1
            )]
        }
    }
}
