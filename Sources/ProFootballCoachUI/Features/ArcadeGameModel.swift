import SwiftUI
import Observation
import FootballSimCore

/// One receiver as the controls list shows him: who he is, and whether he is open.
struct ArcadeTarget: Identifiable, Equatable {
    let id: UUID
    let name: String
    let position: Position
    let state: OpennessState
}

/// Drives "On the Field": owns the game, the snap currently being played, and the animation
/// clock that steps both.
///
/// The division of labour is the point. `InteractiveGame` owns the rules, `SnapKernel` owns the
/// geometry, and this owns neither — it feeds the player's hands into the kernel, hands the
/// kernel's grades to the engine, and then makes the picture agree with the engine's answer.
@Observable
@MainActor
final class ArcadeGameModel {
    enum Phase: Equatable {
        /// Choosing what to run.
        case callingPlay
        /// The snap is live and under the player's control.
        case live
        /// Lining up a placekick.
        case kicking
        /// Showing what the engine decided.
        case showingResult(String)
        /// The opposition has the ball; we are watching it resolve.
        case watchingDefense
        case finished
    }

    private(set) var game: InteractiveGame
    private(set) var phase: Phase = .callingPlay
    private(set) var lastPlays: [PlayEvent] = []
    private(set) var selectedCall: OffensivePlay = .shortPass
    private(set) var defensiveCall: DefensivePlay = .base
    /// The read carried into the opposition's next snap. Persisted between drives, because a
    /// coach's tendency is a standing instruction rather than something re-entered every play.
    private(set) var defensiveRead = DefensiveInput()

    /// The snap being played right now, if any.
    private(set) var kernel: SnapKernel?
    /// The frame the field is drawing.
    private(set) var currentFrame: FieldFrame?
    /// Audibles left in this game.
    private(set) var audiblesRemaining: Int
    private(set) var variation = 0

    /// Kick meter, carried over from the first version of this mode unchanged.
    private(set) var meterValue: Double = 0
    private(set) var meterStage: MeterStage = .power
    private(set) var capturedPower: Double = 0.5

    enum MeterStage: Equatable { case power, aim }

    let userTeamID: UUID
    private let team: Team
    private let opponent: Team
    private var clockTask: Task<Void, Never>?
    private var meterTask: Task<Void, Never>?
    private var choreography: [FieldFrame] = []
    private var carrierTouches = 0
    /// When Reduce Motion is on, watched drives present their outcome instead of animating to it.
    /// The play still resolves identically — only the motion is dropped, which is the distinction
    /// the setting actually asks for.
    var prefersReducedMotion = false

    init(team: Team, opponent: Team, isHome: Bool, game: ScheduledGame, league: League) {
        self.team = team
        self.opponent = opponent
        userTeamID = team.id
        let quarterback = team.starters(at: .qb).first
        let awareness = quarterback?.ratings[.awareness] ?? 70
        let coordinator = team.staff(.offensiveCoordinator)?.rating ?? 0
        // 1 + (awareness - 60)/10, clamped 1...4, and one more from a good coordinator.
        let earned = 1 + (awareness - 60) / 10
        audiblesRemaining = min(4, max(1, earned)) + (coordinator >= 80 ? 1 : 0)

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

    // MARK: - Game state passthrough

    var situation: GameSituation { game.situation }
    var userScore: Int { game.userScore }
    var opponentScore: Int { game.opponentScore }
    var quarter: Int { game.quarter }
    var clockRemaining: Int { game.clockRemaining }
    var record: GameRecord? { game.record }
    var plays: [PlayEvent] { game.plays }
    var isUserOnOffense: Bool { game.isUserOnOffense }
    var isInFieldGoalRange: Bool { situation.isInFieldGoalRange }
    var fieldGoalDistance: Int { situation.fieldGoalDistance }

    /// Whether the clutch bonus applies — Q4, one score. Read once per snap so the whole snap
    /// agrees with itself.
    private var clutchApplies: Bool {
        quarter >= 4 && abs(userScore - opponentScore) <= 8
    }

    /// The eligible receivers, with what the quarterback currently believes about each.
    ///
    /// A named struct rather than a tuple because this list is the mode's assistive path: it is
    /// driven by `ForEach`, and Swift has no key paths into tuple elements to identify rows with.
    var targets: [ArcadeTarget] {
        guard let kernel else { return [] }
        return kernel.offensePlayers.compactMap { player in
            guard case .receiver = player.role else { return nil }
            return ArcadeTarget(
                id: player.id,
                name: player.athlete.name,
                position: player.athlete.position,
                state: kernel.indicator(for: player.id) ?? .contested
            )
        }
    }

    // MARK: - Flow

    func start() {
        advanceToUserTurn()
    }

    /// Guards the one path that can call itself: a watched snap that turns out to have nothing
    /// to show asks for the next one. The engine always makes progress, so this should never
    /// bite — but "should never" is how a spin lock gets shipped.
    private var advanceDepth = 0

    private func advanceToUserTurn() {
        guard advanceDepth < 8 else { return }
        advanceDepth += 1
        defer { advanceDepth -= 1 }

        // Pausing on each opposition snap is what makes the drive watchable. Without it the
        // whole possession resolves inside one call and this method only ever sees a finished
        // drive — which is how the watch-the-defense path came to be unreachable the first time.
        lastPlays = game.advanceUntilUserTurn(read: defensiveRead, pausingOnOpponentSnaps: true)
        switch game.state {
        case .finished:
            phase = .finished
        case .awaitingUserPlay:
            phase = .callingPlay
        case .simulating:
            beginWatchingDefense()
        }
    }

    /// Snaps the ball.
    func snap(_ call: OffensivePlay) {
        selectedCall = call
        variation = 0

        if call == .fieldGoal { return beginKick() }
        if call == .punt { return submit(call: .punt, execution: .neutral) }

        let built = SnapKernel(
            offense: OffensivePersonnel(team: team, clutchApplies: clutchApplies),
            defense: DefensivePersonnel(team: opponent, call: aiDefensiveCall(), clutchApplies: false),
            call: call,
            defensiveCall: aiDefensiveCall(),
            variation: variation,
            dials: ArcadeTuning.normalDials,
            seed: SeededRandom.seed(from: team.id, opponent.id) &+ UInt64(plays.count)
        )
        kernel = built
        currentFrame = built.frame
        phase = .live
        startClock()
    }

    /// Re-deals the play within the same family.
    func audible() {
        guard phase == .live, audiblesRemaining > 0, let existing = kernel else { return }
        guard existing.elapsed < 0.1 else { return }
        audiblesRemaining -= 1
        variation += 1
        let rebuilt = SnapKernel(
            offense: OffensivePersonnel(team: team, clutchApplies: clutchApplies),
            defense: DefensivePersonnel(team: opponent, call: aiDefensiveCall(), clutchApplies: false),
            call: selectedCall,
            defensiveCall: aiDefensiveCall(),
            variation: variation,
            dials: ArcadeTuning.normalDials,
            seed: SeededRandom.seed(from: team.id, opponent.id) &+ UInt64(plays.count) &+ UInt64(variation)
        )
        kernel = rebuilt
        currentFrame = rebuilt.frame
    }

    /// What the opposition is in. Their coordinator picks it; the player sees the front and
    /// reads it, which is what the pre-snap moment is for.
    private func aiDefensiveCall() -> DefensivePlay {
        let distance = situation.distance
        if situation.down >= 3, distance >= 8 { return .nickel }
        if situation.down >= 3, distance <= 2 { return .blitz }
        if situation.yardLine >= 80 { return .base }
        return .base
    }

    // MARK: - The snap clock

    private func startClock() {
        clockTask?.cancel()
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(ArcadeTuning.secondsPerTick))
                guard let self else { return }
                guard self.phase == .live else { return }
                self.tick()
            }
        }
    }

    private func stopClock() {
        clockTask?.cancel()
        clockTask = nil
    }

    private func tick() {
        guard var live = kernel else { return }
        live.step()
        kernel = live
        currentFrame = live.frame
        if live.isOver { finishSnap() }
    }

    // MARK: - Input

    func beginAiming() { apply(.beginAim) }
    func aim(at point: FieldPoint) { apply(.aim(point)) }
    func setBullet(_ bullet: Bool) { apply(.setBullet(bullet)) }
    func release() { apply(.release) }
    func handOff(gapIndex: Int? = nil) { apply(.handOff(gapIndex: gapIndex)) }
    func scramble() { apply(.scramble) }
    func juke(_ direction: Double) { apply(.juke(direction: direction)) }
    func dive() { apply(.dive) }
    func stall() { apply(.stall) }

    /// Throws at a named receiver. The gesture-free path, so VoiceOver can play the mode.
    func throwTo(_ receiverID: UUID) {
        guard let kernel, let target = kernel.offensePlayers.first(where: { $0.id == receiverID })
        else { return }
        apply(.beginAim)
        apply(.aim(target.point))
        apply(.release)
    }

    private func apply(_ action: ArcadeAction) {
        guard var live = kernel, phase == .live else { return }
        live.apply(action)
        kernel = live
        currentFrame = live.frame
        if live.isOver { finishSnap() }
    }

    // MARK: - Resolution

    /// The snap is done being played. The engine decides what it was worth.
    private func finishSnap() {
        stopClock()
        guard let live = kernel else { return }
        let passer = OffensivePersonnel(team: team, clutchApplies: clutchApplies).quarterback
        let execution = ArcadeInput.execution(from: live.grades, quarterback: passer)

        // A scramble is a run whatever the play was called; everything else keeps its call so
        // the engine's matchup is the one the player chose.
        let call: OffensivePlay = live.grades.ending == .scrambled ? .outsideRun : selectedCall
        submit(call: call, execution: execution)
    }

    private func submit(call: OffensivePlay, execution: PlayExecution) {
        lastPlays = game.playUserSnap(call: call, execution: execution)
        if call.isRun || call.isPass { carrierTouches += 1 }

        // Make the picture agree with the box score. Nothing the player watched is allowed to
        // contradict the number the engine recorded.
        if var live = kernel, let event = lastPlays.last {
            live.reconcile(officialYards: event.yards)
            live.applyFatigue(touches: carrierTouches, isIronMan: false, age: 26)
            kernel = live
            currentFrame = live.frame
        }

        phase = .showingResult(lastPlays.last?.description ?? "The play is over.")
    }

    func continueAfterResult() {
        kernel = nil
        currentFrame = nil
        advanceToUserTurn()
    }

    // MARK: - Watching the defense

    /// Builds the animation for the opposition's snap from the play the engine already resolved.
    private func beginWatchingDefense() {
        choreography = []
        // The snap the player is here to watch is the opposition's, not the extra point that
        // may have followed it. Setting the phase only once there is something to show keeps the
        // UI from parking in `watchingDefense` with an empty field.
        let watchable = lastPlays.first {
            $0.offenseTeamID != userTeamID && $0.category != .administrative
        }
        guard let event = watchable ?? lastPlays.last else {
            // Nothing came back — an administrative step, or overtime being set up. Keep going
            // rather than stranding the player on a blank field.
            return advanceToUserTurn()
        }
        phase = .watchingDefense
        let played = Choreographer.play(
            event: event,
            offense: OffensivePersonnel(team: opponent),
            defense: DefensivePersonnel(team: team, call: defensiveCall),
            call: event.category == .run ? .insideRun : .shortPass,
            defensiveCall: defensiveCall,
            seed: SeededRandom.seed(from: event.id)
        )
        choreography = played.frames
        currentFrame = played.frames.first
        playChoreography(speed: 2.5)
    }

    func setDefensiveCall(_ call: DefensivePlay) { defensiveCall = call }

    /// Tilts the coverage before the opposition's next snap.
    func setShade(_ shade: CoverageShade) {
        defensiveRead = DefensiveInput(
            shade: shade,
            breakError: defensiveRead.breakError,
            committedToTackle: defensiveRead.committedToTackle
        )
    }

    /// Commits to the run fit, or hangs back. Nil leaves it to the defender.
    func setRunCommit(_ committed: Bool?) {
        defensiveRead = DefensiveInput(
            shade: defensiveRead.shade,
            breakError: defensiveRead.breakError,
            committedToTackle: committed
        )
    }

    private func playChoreography(speed: Double) {
        stopClock()
        let frames = choreography
        guard !frames.isEmpty else { return }
        guard !prefersReducedMotion else {
            currentFrame = frames.last
            // Nothing is animating, so nothing will call this for us.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.8))
                guard let self, self.phase == .watchingDefense else { return }
                self.advanceToUserTurn()
            }
            return
        }
        clockTask = Task { [weak self] in
            for frame in frames {
                try? await Task.sleep(for: .seconds(ArcadeTuning.secondsPerTick / speed))
                guard let self, !Task.isCancelled else { return }
                guard self.phase == .watchingDefense else { return }
                self.currentFrame = frame
            }
            guard let self, !Task.isCancelled, self.phase == .watchingDefense else { return }
            // The play is over; go straight to the next one rather than waiting to be asked.
            self.advanceToUserTurn()
        }
    }

    /// Skips the rest of the opposition's drive. The outcome is already decided, so this costs
    /// nothing but the watching.
    ///
    /// Deliberately not `advanceToUserTurn()`: that pauses on the *next* opposition snap and
    /// starts animating it, which would make the button skip one play rather than the drive.
    func skipToNextUserSnap() {
        stopClock()
        choreography = []
        currentFrame = nil
        lastPlays = game.advanceUntilUserTurn(read: defensiveRead)
        switch game.state {
        case .finished: phase = .finished
        case .awaitingUserPlay: phase = .callingPlay
        case .simulating: phase = .callingPlay
        }
    }

    // MARK: - Kicking

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
            submit(call: .fieldGoal, execution: PlayExecution(kicking: quality))
        }
    }

    // MARK: - Leaving

    func simulateRest() {
        stopClock()
        stopMeter()
        kernel = nil
        currentFrame = nil
        game.simulateRemainder()
        phase = .finished
    }

    // No `deinit` cancelling the timers. Under `@Observable` the macro rewrites stored properties
    // into computed ones that touch the observation registrar, and reaching them from `deinit` on
    // a `@MainActor` class is exactly the isolation corner nobody wants to be standing in. It buys
    // nothing anyway: both loops capture `self` weakly and return the moment it is gone, so a
    // dismissed game stops on its next tick.
}
