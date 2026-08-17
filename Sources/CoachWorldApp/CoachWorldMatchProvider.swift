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
        let line = Double(min(100, max(0, session.situation.yardLine)))
        let firstDown = min(120, line + Double(max(1, session.situation.distance)))
        let homeActors = actors(
            homePlayers,
            side: .home,
            numbers: homeNumbers,
            line: line,
            xOffset: -2,
            isOffense: possession == .home
        )
        let awayActors = actors(
            awayPlayers,
            side: .away,
            numbers: awayNumbers,
            line: line,
            xOffset: 2,
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
                offenseDirection: .leftToRight
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
    static func playback(
        from set: SnapAnchorSet,
        stableID: String,
        offenseDirection: MatchFieldDirection
    ) -> MatchDayReadModel.Playback {
        // Ten yards of end zone sit at each end of the 120-yard drawn field, so an offense-relative
        // 0 is an absolute 10 when the offence attacks rightward, and an absolute 110 when it
        // attacks leftward.
        func x(_ yard: Double) -> Double {
            offenseDirection == .leftToRight ? yard + 10 : 110 - yard
        }

        return MatchDayReadModel.Playback(
            stableID: stableID,
            durationSeconds: set.durationSeconds,
            actors: set.actors.map { actor in
                MatchDayReadModel.Playback.ActorTrack(
                    stableID: actor.playerID.uuidString,
                    startX: x(actor.start.yard),
                    startY: actor.start.lateral,
                    endX: x(actor.end.yard),
                    endY: actor.end.lateral,
                    role: actor.role.rawValue
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
                    endFraction: segment.endFraction
                )
            },
            foregroundIDs: set.foregroundIDs.map(\.uuidString),
            endSpotX: x(set.endSpot),
            sentence: set.sentence
        )
    }

    private static func actors(
        _ players: [Player],
        side: MatchSide,
        numbers: [UUID: Int],
        line: Double,
        xOffset: Double,
        isOffense: Bool
    ) -> [MatchDayReadModel.Actor] {
        players.enumerated().map { index, player in
            let x = min(120, max(0, line + (isOffense ? xOffset : -xOffset)))
            return MatchDayReadModel.Actor(
                stableID: player.id.uuidString,
                side: side,
                uniformNumber: String(numbers[player.id] ?? 0),
                position: positionLabel(player.position),
                xYardsFromLeftGoalLine: x,
                yFraction: Double(index % 11) / 10
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
                return .init(id: id, value: "Plan fixed", isEnabled: false, isSelected: false,
                             intentID: .init(rawValue: prefix + id.rawValue))
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
                title: "Trust the coordinator",
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
            staff: .init(stableID: staff.id.uuidString, name: staff.fullName, role: staff.role.rawValue),
            message: "Staff flagged \(proposal.trigger.label.lowercased()) before the next snap.",
            evidence: [
                "Trigger: \(proposal.trigger.label)",
                "Down \(proposal.situation.down), \(proposal.situation.distance) to go at yard line \(proposal.situation.yardLine)."
            ],
            actions: actions
        )
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
        case .edgeRusher: return "EDGE"
        case .defensiveTackle: return "DT"
        case .linebacker: return "LB"
        case .cornerback: return "CB"
        case .safety: return "S"
        case .kicker: return "K"
        case .punter: return "P"
        }
    }
}
