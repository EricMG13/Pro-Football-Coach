import Foundation
import FootballSimCore
import ProFootballCoachUI

/// Live Match Day projection. It is intentionally built from the persisted match checkpoint;
/// production never falls back to the DEBUG sample fixture.
public extension CoachWorldReadModelProvider {
    static func matchDay(from state: GameState) -> MatchDayReadModel? {
        guard let session = state.matchSession,
              let fixtureID = session.fixtureID,
              let game = state.competition.currentSchedule.games.first(where: { $0.id == fixtureID }),
              session.home.offense.count >= 11,
              session.home.defense.count >= 11,
              session.away.offense.count >= 11,
              session.away.defense.count >= 11 else { return nil }

        let homeNumbers = JerseyNumbers.assign(session.home.offense + session.home.defense)
        let awayNumbers = JerseyNumbers.assign(session.away.offense + session.away.defense)
        let possession = session.situation.possession
        let homePlayers = Array((possession == .home ? session.home.offense : session.home.defense).prefix(11))
        let awayPlayers = Array((possession == .away ? session.away.offense : session.away.defense).prefix(11))
        // Offense-relative yards, converted once into drawn-field space. The previous version
        // assigned `yardLine` straight across, which put every marker ten yards adrift.
        let offenseYard = Double(min(100, max(0, session.situation.yardLine)))
        let line = fieldX(yard: offenseYard, direction: .leftToRight)
        let firstDown = fieldX(
            yard: firstDownYard(from: offenseYard, distance: session.situation.distance),
            direction: .leftToRight
        )
        let homeActors = actors(
            homePlayers,
            side: .home,
            numbers: homeNumbers,
            offenseYard: offenseYard,
            isOffense: possession == .home
        )
        let awayActors = actors(
            awayPlayers,
            side: .away,
            numbers: awayNumbers,
            offenseYard: offenseYard,
            isOffense: possession == .away
        )
        let controls = controls(for: session, fixtureID: fixtureID)
        let interruption = interruption(for: session, fixtureID: fixtureID, in: state)
        let possessionSide = possession == .home ? MatchSide.home : .away
        let foreground = (possessionSide == .home ? homeActors : awayActors)
            .prefix(2)
            .map(\.stableID)
        let commentary = interruption.map { "\($0.message)" }
            ?? "The next recorded snap belongs to \(possession == .home ? teamReference(game.homeID, in: state).name : teamReference(game.awayID, in: state).name)."
        let clock = min(900, max(0, session.situation.secondsRemainingInQuarter))

        // The last snap that actually resolved. Animation trails resolution, always: `03b` §2 and
        // `03` §9. Before the first snap of a game there is nothing to animate and the view draws
        // the static field instead.
        let lastPlay = session.currentDrive?.plays.last ?? session.drives.last?.plays.last
        let snapPlayback = lastPlay.map { play -> MatchDayReadModel.Playback in
            let playOffense = play.situation.possession == .home
                ? session.home.offense : session.away.offense
            let playDefense = play.situation.possession == .home
                ? session.away.defense : session.home.defense
            return playback(
                from: SnapAnchors.choreograph(
                    play: play,
                    offense: Array(playOffense.prefix(11)),
                    defense: Array(playDefense.prefix(11))
                ),
                // The revision, not the drive index: it increments on every snap, which is the
                // grain the playback clock has to restart on.
                stableID: "\(fixtureID.uuidString)-\(session.revision)",
                numbers: homeNumbers.merging(awayNumbers) { first, _ in first },
                shorthands: shorthands(Array(playOffense.prefix(11)))
                    .merging(shorthands(Array(playDefense.prefix(11)))) { first, _ in first },
                offenseDirection: .leftToRight,
                isPaused: session.isPaused
            )
        }

        return try? MatchDayReadModel(
            recordedOutcomeID: "\(fixtureID.uuidString)-\(session.nextDriveIndex)",
            provenance: .simulationSnapshot,
            world: worldReference(state),
            venue: venueReference(game.homeID, in: state),
            home: .init(
                team: teamReference(game.homeID, in: state),
                score: max(0, session.situation.homeScore)
            ),
            away: .init(
                team: teamReference(game.awayID, in: state),
                score: max(0, session.situation.awayScore)
            ),
            // Which side the coach's own program is on — independent of who owns the venue, so
            // an away game still gets "our" scorebug treatment rather than the home team's.
            perspective: state.careerArc.currentJob?.organisationID == game.awayID ? .away : .home,
            tier: session.tier == .college ? .college : .pro,
            situation: .init(
                quarter: max(1, session.situation.quarter),
                clockSecondsRemaining: clock,
                down: min(4, max(1, session.situation.down)),
                yardsToGo: max(1, session.situation.distance),
                possession: possessionSide
            ),
            offenseDirection: .leftToRight,
            actors: homeActors + awayActors,
            lineOfScrimmage: line,
            firstDownLine: firstDown > line ? firstDown : min(120, line + 1),
            foregroundActorIDs: Array(foreground),
            playback: snapPlayback,
            causalCommentary: commentary,
            staffInterruption: interruption,
            controls: controls
        )
    }

    /// Converts an engine anchor set into presentation space.
    ///
    /// The one place the offense-relative-to-absolute conversion happens, and the one place
    /// direction is read. `03` §9.2 keeps both out of the engine, and `04` §9 requires that the view
    /// never guess direction from colour.
    /// Turns an offense-relative yard into a position on the drawn field.
    ///
    /// **The only conversion between the two spaces, per `03` §9.2.** Ten yards of end zone sit at
    /// each end of the 120-yard drawn field, so an offense-relative 0 is an absolute 10 when the
    /// offence attacks rightward and an absolute 110 when it attacks leftward.
    ///
    /// Before this existed the provider assigned `Situation.yardLine` straight into the read model's
    /// absolute space, so the offence's own 25 drew on the drawn field's 15 — ten yards of end zone
    /// unaccounted for, on every marker, in every game.
    static func fieldX(yard: Double, direction: MatchFieldDirection) -> Double {
        direction == .leftToRight ? yard + 10 : 110 - yard
    }

    /// Where the first-down line sits, in offense-relative yards.
    ///
    /// Bounded at 110 — the back of the end zone — and never at 100. Goal-to-go puts the marker on
    /// the goal line itself, and `MatchDayReadModel` requires the first-down line *strictly* beyond
    /// the line of scrimmage. Clamping to 100 makes them equal there, which fails validation and
    /// blanks Match Day on exactly the snaps that matter most.
    static func firstDownYard(from yardLine: Double, distance: Int) -> Double {
        min(110, yardLine + Double(max(1, distance)))
    }

    static func playback(
        from set: SnapAnchorSet,
        stableID: String,
        numbers: [UUID: Int] = [:],
        shorthands: [UUID: String] = [:],
        offenseDirection: MatchFieldDirection,
        isPaused: Bool = false
    ) -> MatchDayReadModel.Playback {
        func x(_ yard: Double) -> Double { fieldX(yard: yard, direction: offenseDirection) }

        return MatchDayReadModel.Playback(
            stableID: stableID,
            durationSeconds: set.durationSeconds,
            actors: set.actors.map { actor in
                MatchDayReadModel.Playback.ActorTrack(
                    stableID: actor.playerID.uuidString,
                    side: actor.side == .home ? .home : .away,
                    uniformNumber: numbers[actor.playerID].map(String.init) ?? "",
                    startX: x(actor.start.yard),
                    startY: actor.start.lateral,
                    endX: x(actor.end.yard),
                    endY: actor.end.lateral,
                    waypoints: actor.path.map {
                        MatchDayReadModel.Playback.ActorTrack.Waypoint(
                            x: x($0.point.yard), y: $0.point.lateral, fraction: $0.fraction
                        )
                    },
                    // The slot shorthand, not the role code. MATCH-DAY.md §4 and `04` §6.5 #18
                    // both say "labels are position shorthand, not numbers"; emitting `B`, `R`,
                    // `CV` and `FIT` instead made the field read as a diagram of duties. Falls back
                    // to the role only for an identifier the caller did not supply a shorthand for,
                    // which is a labelled dot rather than a blank one.
                    role: shorthands[actor.playerID] ?? roleLabel(actor.role)
                )
            },
            ball: set.ball.map { segment in
                MatchDayReadModel.Playback.BallLeg(
                    kind: segment.kind.rawValue,
                    fromX: x(segment.from.yard),
                    fromY: segment.from.lateral,
                    toX: x(segment.to.yard),
                    toY: segment.to.lateral,
                    startFraction: segment.startFraction,
                    endFraction: segment.endFraction,
                    // Every leg was grounded before this: BallLeg.apexHeight defaults to 0 and
                    // nothing here ever passed one, so BallToken's lift/apex-scale/tilt/shadow code
                    // was dead on the live path. Only .air is actually airborne -- a snap, handoff,
                    // carry or a loose ball after an interception all stay on the turf.
                    apexHeight: segment.kind == .air ? 1 : 0
                )
            },
            foregroundIDs: set.foregroundIDs.map(\.uuidString),
            lineOfScrimmageX: x(set.lineOfScrimmage),
            firstDownLineX: x(set.firstDownLine),
            endSpotX: x(set.endSpot),
            sentence: set.sentence,
            isPaused: isPaused
        )
    }

    /// The pre-snap formation, from the same `03` §9.4 template the animation uses.
    ///
    /// It used to give every player on a side a single x — the line plus a two-yard offset — and
    /// spread them by array index, which drew two vertical columns of eleven rather than a
    /// formation. The first thing anyone saw on Match Day was a column that snapped into real
    /// football only after the first play. Sharing the template means the pre-snap field and the
    /// animated one agree by construction rather than by two authors remembering to match.
    private static func actors(
        _ players: [Player],
        side: MatchSide,
        numbers: [UUID: Int],
        offenseYard: Double,
        isOffense: Bool
    ) -> [MatchDayReadModel.Actor] {
        // The engine's own slot index, not a second count of the same thing: `choreograph` places a
        // man from it and this labels him from it, and two derivations are two things that drift.
        let indices = SnapAnchors.lineupIndices(players)
        return players.map { player in
            let index = indices[player.id] ?? 0
            let spot = SnapAnchors.alignment(
                for: player.position,
                index: index,
                isOffense: isOffense,
                lineOfScrimmage: offenseYard
            )
            return MatchDayReadModel.Actor(
                stableID: player.id.uuidString,
                side: side,
                uniformNumber: String(numbers[player.id] ?? 0),
                position: positionLabel(player.position),
                shorthand: SnapAnchors.shorthand(for: player.position, index: index),
                xYardsFromLeftGoalLine: fieldX(yard: spot.yard, direction: .leftToRight),
                yFraction: spot.lateral
            )
        }
    }

    private static func controls(
        for session: MatchSessionState,
        fixtureID: UUID
    ) -> [MatchDayReadModel.ControlState] {
        let prefix = "match|\(fixtureID.uuidString)|\(session.revision)|"
        return MatchDayControlID.allCases.map { id in
            switch id {
            case .keyMoments:
                return .init(
                    id: id,
                    value: session.pendingCallIn == nil ? "Next snap" : "Call-in pending",
                    isEnabled: session.pendingCallIn == nil && !session.completed && !session.isPaused,
                    isSelected: true,
                    intentID: .init(rawValue: prefix + "advance")
                )
            case .speed:
                // Live as of the G-06 slice. Playback rate is presentation, so the view owns the
                // displayed value and the intent only records that a cycle happened.
                return .init(
                    id: id, value: "Speed", isEnabled: !session.completed, isSelected: false,
                    intentID: .init(rawValue: prefix + id.rawValue)
                )
            case .pause:
                return .init(
                    id: id,
                    value: session.isPaused ? "Resume" : "Pause",
                    isEnabled: !session.completed && session.pendingCallIn == nil,
                    isSelected: session.isPaused,
                    intentID: .init(rawValue: prefix + id.rawValue)
                )
            case .takeOver:
                return .init(
                    id: id,
                    value: session.isTakeover ? "Hand back" : "Take over",
                    isEnabled: session.controlledSide != nil
                        && session.pendingCallIn == nil
                        && !session.completed,
                    isSelected: session.isTakeover,
                    intentID: .init(rawValue: prefix + "takeover")
                )
            case .tactics:
                // `02` section 3.2 names tempo, aggression and personnel packages as mid-match
                // changes. Gated exactly like Take Over: a side to change it for, no call-in
                // decision the coach must answer first, and a live game to change it in.
                return .init(
                    id: id, value: "Adjust",
                    isEnabled: session.controlledSide != nil
                        && session.pendingCallIn == nil
                        && !session.completed,
                    isSelected: false,
                    intentID: .init(rawValue: prefix + id.rawValue)
                )
            }
        }
    }

    private static func interruption(
        for session: MatchSessionState,
        fixtureID: UUID,
        in state: GameState
    ) -> MatchDayReadModel.StaffInterruption? {
        guard session.isTakeover, let proposal = session.pendingCallIn else { return nil }
        let controlledID = session.controlledSide == .home
            ? state.competition.currentSchedule.games.first(where: { $0.id == fixtureID })?.homeID
            : state.competition.currentSchedule.games.first(where: { $0.id == fixtureID })?.awayID
        guard let organisationID = controlledID else { return nil }
        let staffIDs = state.programmes[organisationID]?.staffIDs
            ?? state.proTeams[organisationID]?.staffIDs
            ?? []
        let staff = staffIDs.compactMap { state.staff[$0] }
            .first(where: { $0.role == .offensiveCoordinator || $0.role == .defensiveCoordinator })
            ?? staffIDs.compactMap { state.staff[$0] }.first
        guard let staff else { return nil }
        let acceptAction = proposal.recommendation
        let actionPrefix = "match|\(fixtureID.uuidString)|\(session.revision)|callin|"
        let actions = [
            MatchDayReadModel.StaffInterruption.Action(
                path: .accept,
                intentID: .init(rawValue: actionPrefix + "accept|" + acceptAction.rawValue),
                title: proposal.options.first(where: { $0.action == acceptAction })?.title ?? "Accept recommendation",
                cost: "Applies to future snaps",
                consequence: "The completed snaps remain unchanged."
            ),
            MatchDayReadModel.StaffInterruption.Action(
                path: .dismiss,
                intentID: .init(rawValue: actionPrefix + "dismiss|" + TacticalCallInAction.trustCoordinator.rawValue),
                title: "Keep current plan",
                cost: "No extra adjustment",
                consequence: "Keep the installed plan for this decision."
            ),
            MatchDayReadModel.StaffInterruption.Action(
                path: .inspectEvidence,
                intentID: .init(rawValue: actionPrefix + "inspect"),
                title: "Inspect evidence",
                cost: "No commitment",
                consequence: "Review the trigger and recorded situation."
            )
        ]
        return try? MatchDayReadModel.StaffInterruption(
            stableID: "\(fixtureID.uuidString)-callin-\(session.callInReceipts.count)",
            staff: .init(
                stableID: staff.id.uuidString,
                name: staff.fullName,
                role: staffRoleLabel(staff.role)
            ),
            message: "Staff flagged \(proposal.trigger.label.lowercased()) before the next snap.",
            evidence: [
                "Trigger: \(proposal.trigger.label)",
                "Down \(proposal.situation.down), \(proposal.situation.distance) to go at yard line \(proposal.situation.yardLine)."
            ],
            actions: actions
        )
    }

    private static func roleLabel(_ role: SnapRole) -> String {
        switch role {
        case .passer: return "P"
        case .blocker: return "B"
        case .routeRunner: return "RR"
        case .carrier: return "C"
        case .decoy: return "D"
        case .rusher: return "R"
        case .coverage: return "CV"
        case .runFit: return "FIT"
        case .kicker: return "K"
        case .blockLeverage: return "BL"
        }
    }

    private static func staffRoleLabel(_ role: StaffRole) -> String {
        switch role {
        case .headCoach: return "Head coach"
        case .offensiveCoordinator: return "Offensive coordinator"
        case .defensiveCoordinator: return "Defensive coordinator"
        case .specialTeamsCoordinator: return "Special teams coordinator"
        case .strengthCoordinator: return "Strength coordinator"
        case .positionCoach: return "Position coach"
        }
    }

    /// Slot shorthands for one side's eleven, keyed the way the playback's tracks are.
    private static func shorthands(_ players: [Player]) -> [UUID: String] {
        let indices = SnapAnchors.lineupIndices(players)
        return players.reduce(into: [:]) { out, player in
            out[player.id] = SnapAnchors.shorthand(
                for: player.position, index: indices[player.id] ?? 0
            )
        }
    }

    private static func positionLabel(_ position: Position) -> String {
        switch position {
        case .quarterback: return "QB"
        case .runningBack: return "RB"
        case .wideReceiver: return "WR"
        case .tightEnd: return "TE"
        case .leftTackle: return "LT"
        case .guardPosition: return "G"
        case .center: return "C"
        case .rightTackle: return "RT"
        // Two characters at most, like every other label here: these are drawn inside a 15 pt
        // field token, and MATCH-DAY.md section 4 fixes the vocabulary at one- and two-letter
        // shorthands for that reason. "EDGE" truncated to an ellipsis on the field.
        case .edgeRusher: return "DE"
        case .defensiveTackle: return "DT"
        case .linebacker: return "LB"
        case .cornerback: return "CB"
        case .safety: return "S"
        case .kicker: return "K"
        case .punter: return "P"
        }
    }
}
