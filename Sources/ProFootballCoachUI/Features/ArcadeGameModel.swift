import SwiftUI
import Observation
import FootballSimCore

/// A receiver as the arcade draws him: a name, and a spot on the field to throw at.
///
/// The engine has no notion of where anybody is standing — it resolves a matchup, not a
/// geometry. These positions exist so the player has something to aim at, and the only thing
/// that crosses back into the simulation is how close the throw came.
struct ReceiverTarget: Identifiable {
    let id: UUID
    let name: String
    let position: Position
    /// Yards downfield from the line of scrimmage.
    let depth: Double
    /// -1 (near sideline) to 1 (far sideline).
    let lateral: Double
}

/// Drives the on-field mode: owns the game, the phase of the current snap, and the routes the
/// player is aiming at.
@Observable
@MainActor
final class ArcadeGameModel {
    enum Phase: Equatable {
        /// Waiting for the player to choose what to run.
        case callingPlay
        /// Ball is snapped; the player is aiming or deciding to hand off.
        case live
        /// Lining up a placekick: first the power tap, then the aim tap.
        case kicking
        /// Showing what just happened.
        case showingResult(String)
        case opponentBall
        case finished
    }

    private(set) var game: InteractiveGame
    private(set) var phase: Phase = .callingPlay
    private(set) var receivers: [ReceiverTarget] = []
    private(set) var lastPlays: [PlayEvent] = []
    private(set) var pocketSeconds: Double = 3.0
    private(set) var heldSeconds: Double = 0
    private(set) var selectedCall: OffensivePlay = .shortPass
    private var pocketTask: Task<Void, Never>?
    private var meterTask: Task<Void, Never>?

    /// 0...1 sweep position of whichever kick meter is running.
    private(set) var meterValue: Double = 0
    private(set) var meterStage: MeterStage = .power
    private(set) var capturedPower: Double = 0.5

    enum MeterStage: Equatable { case power, aim }

    let userTeamID: UUID
    private let quarterback: Player?
    private let team: Team

    init(team: Team, opponent: Team, isHome: Bool, game: ScheduledGame, league: League) {
        self.team = team
        userTeamID = team.id
        quarterback = team.starters(at: .qb).first
        self.game = InteractiveGame(
            home: isHome ? team : opponent,
            away: isHome ? opponent : team,
            userTeamID: team.id,
            week: game.week,
            year: league.year,
            kind: game.kind,
            scheduledGameID: game.id,
            settings: league.settings,
            neutralSite: game.isNeutralSite,
            rng: league.rng
        )
    }

    var situation: GameSituation { game.situation }
    var userScore: Int { game.userScore }
    var opponentScore: Int { game.opponentScore }
    var quarter: Int { game.quarter }
    var clockRemaining: Int { game.clockRemaining }
    var record: GameRecord? { game.record }
    var plays: [PlayEvent] { game.plays }

    /// How much of the aiming arc the quarterback lets the player see. An accurate passer shows
    /// the whole flight; a poor one leaves the player guessing at the end of it.
    var visibleArcFraction: Double {
        guard let quarterback else { return 0.5 }
        let accuracy = Double(quarterback.ratings[.throwAccuracy])
        return min(1, max(0.35, 0.35 + (accuracy - 40) / 59 * 0.65))
    }

    var pocketFraction: Double {
        pocketSeconds <= 0 ? 0 : min(1, max(0, 1 - heldSeconds / pocketSeconds))
    }

    // MARK: - Flow

    func start() {
        advanceToUserTurn()
    }

    private func advanceToUserTurn() {
        lastPlays = game.advanceUntilUserTurn()
        switch game.state {
        case .finished: phase = .finished
        case .awaitingUserPlay: phase = .callingPlay
        case .simulating: phase = .opponentBall
        }
    }

    /// Whether a placekick is a sensible option from here — used to decide what the playbook
    /// offers, so the kicking screen is never a dead end.
    var isUserOnOffense: Bool { game.isUserOnOffense }

    var isInFieldGoalRange: Bool { situation.isInFieldGoalRange }

    var fieldGoalDistance: Int { situation.fieldGoalDistance }

    /// Snaps the ball. Routes are drawn to suit the call so aiming means something different on
    /// a screen than on a go route.
    func snap(_ call: OffensivePlay) {
        selectedCall = call

        if call == .fieldGoal {
            beginKick()
            return
        }
        if call == .punt {
            resolve(call: .punt, execution: .neutral)
            return
        }
        guard call.isPass else {
            // Runs need no aiming; the carrier decision is the whole play.
            resolve(call: call, execution: PlayExecution(running: 0.35))
            return
        }
        receivers = makeRoutes(for: call)
        pocketSeconds = estimatedPocketSeconds()
        heldSeconds = 0
        phase = .live
    }

    /// Starts the rush the moment the player begins to aim.
    ///
    /// Deliberately not at the snap: reading four routes takes a second or two, and a clock that
    /// runs while the player is still looking punishes thinking rather than hesitating. The
    /// pressure should measure how long they hold the ball once they have decided to throw.
    func beginAiming() {
        guard phase == .live, pocketTask == nil else { return }
        startPocketClock()
    }

    // MARK: - Kicking

    /// Starts the two-tap meter: a bar sweeps for power, then an arrow sweeps for aim.
    private func beginKick() {
        phase = .kicking
        meterStage = .power
        startMeter()
    }

    private func startMeter() {
        meterTask?.cancel()
        meterValue = 0
        meterTask = Task { [weak self] in
            let step = 0.016
            var rising = true
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(step))
                guard let self, self.phase == .kicking else { return }
                // A bar that bounces rather than wrapping keeps the timing readable.
                let speed = self.meterStage == .power ? 1.5 : 2.1
                self.meterValue += (rising ? 1 : -1) * step * speed
                if self.meterValue >= 1 { self.meterValue = 1; rising = false }
                if self.meterValue <= 0 { self.meterValue = 0; rising = true }
            }
        }
    }

    private func stopMeter() {
        meterTask?.cancel()
        meterTask = nil
    }

    /// Takes the current tap. The first sets power, the second sets aim and strikes the ball.
    func tapMeter() {
        guard phase == .kicking else { return }
        switch meterStage {
        case .power:
            capturedPower = meterValue
            meterStage = .aim
            startMeter()
        case .aim:
            let quality = ArcadeInput.kickQuality(power: capturedPower, aim: meterValue)
            stopMeter()
            resolve(call: .fieldGoal, execution: PlayExecution(kicking: quality))
        }
    }

    /// Runs the pass protection down in real time from the moment the ball is snapped.
    private func startPocketClock() {
        pocketTask?.cancel()
        pocketTask = Task { [weak self] in
            let step = 0.05
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(step))
                guard let self, self.phase == .live else { return }
                self.heldSeconds += step
                if self.heldSeconds >= self.pocketSeconds {
                    self.throwUnderPressure()
                    return
                }
            }
        }
    }

    private func stopPocketClock() {
        pocketTask?.cancel()
        pocketTask = nil
    }

    /// Releases the throw at a point on the field, in the same coordinates the routes use.
    func throwBall(atDepth depth: Double, lateral: Double) {
        guard phase == .live, let quarterback else { return }

        // The receiver nearest the landing spot is the one who was targeted.
        let miss = receivers
            .map { hypot($0.depth - depth, ($0.lateral - lateral) * 12) }
            .min() ?? 25

        let placement = ArcadeInput.throwAccuracy(missDistanceYards: miss, quarterback: quarterback)
        let execution = PlayExecution(
            accuracy: placement,
            timing: ArcadeInput.releaseTiming(heldSeconds: heldSeconds, pocketSeconds: pocketSeconds),
            // Placement also decides what happens after the catch: a ball in stride keeps a
            // receiver running, a ball behind him stops him dead. Without this, a perfect throw
            // and a rushed one that happened to be caught gain exactly the same yards, and the
            // player gets no feedback that aiming well did anything.
            running: placement * 0.5
        )
        resolve(call: selectedCall, execution: execution)
    }

    /// Hands off instead of throwing.
    func handOff() {
        guard phase == .live else { return }
        let timing = ArcadeInput.releaseTiming(heldSeconds: heldSeconds, pocketSeconds: pocketSeconds)
        resolve(call: .insideRun, execution: PlayExecution(timing: timing, running: 0.25))
    }

    /// The protection has broken down and the ball has to go somewhere. Whether that ends as a
    /// sack, a throwaway or a completion is still the engine's call — this only says the
    /// quarterback was under pressure and rushed it.
    func throwUnderPressure() {
        guard phase == .live else { return }
        resolve(call: selectedCall, execution: PlayExecution(accuracy: -0.6, timing: -1))
    }

    private func resolve(call: OffensivePlay, execution: PlayExecution) {
        stopPocketClock()
        stopMeter()
        lastPlays = game.playUserSnap(call: call, execution: execution)
        receivers = []
        let summary = lastPlays.last?.description ?? "The play is over."
        phase = .showingResult(summary)
    }

    /// Moves on from the result card to whatever comes next.
    func continueAfterResult() {
        advanceToUserTurn()
    }

    func simulateRest() {
        game.simulateRemainder()
        phase = .finished
    }

    // MARK: - Routes

    private func makeRoutes(for call: OffensivePlay) -> [ReceiverTarget] {
        let eligible = (team.starters(at: .wr) + team.starters(at: .te) + team.starters(at: .rb))
            .prefix(4)
        // Depth bands per call, so a deep shot really is a longer throw to make.
        let depths: [Double]
        switch call {
        case .deepPass: depths = [22, 30, 14, 6]
        case .playAction: depths = [16, 9, 24, 4]
        case .screen: depths = [-1, 3, 7, 1]
        default: depths = [8, 5, 13, 2]
        }
        let laterals: [Double] = [-0.6, 0.55, 0.15, -0.2]

        return eligible.enumerated().map { index, player in
            ReceiverTarget(
                id: player.id,
                name: player.name,
                position: player.position,
                depth: depths[index % depths.count],
                lateral: laterals[index % laterals.count]
            )
        }
    }

    /// How long the line is likely to hold, which is what release timing is measured against.
    private func estimatedPocketSeconds() -> Double {
        let line = team.unitRating(at: .ol)
        return 2.2 + (line - 55) / 35 * 2.3
    }
}
