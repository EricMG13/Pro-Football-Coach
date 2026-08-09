import Foundation

/// A game played one snap at a time, with the user calling their own offence.
///
/// This owns no rules. It steps `GameSimulator` — the same object bulk simulation uses — and
/// simply pauses when the user's team has the ball. Everything else, including the opponent's
/// entire game, is resolved by the engine exactly as it would be in a simmed week.
public struct InteractiveGame {
    /// What the caller should do next.
    public enum State: Equatable {
        /// The user's offence is on the field and the game is waiting for a call.
        case awaitingUserPlay(GameSituation)
        /// The engine is running the opposition, or a kick, or the clock.
        case simulating
        case finished
    }

    private var simulator: GameSimulator
    private var rng: SeededRandom
    private let userTeamID: UUID
    private let homeTeamID: UUID
    private(set) public var record: GameRecord?
    /// Plays emitted so far, so the caller can render the log as it fills.
    private(set) public var plays: [PlayEvent] = []

    public init(
        home: Team,
        away: Team,
        userTeamID: UUID,
        week: Int,
        year: Int,
        kind: GameKind,
        scheduledGameID: UUID,
        settings: LeagueSettings,
        neutralSite: Bool,
        rng: SeededRandom
    ) {
        self.simulator = GameSimulator(
            home: home,
            away: away,
            week: week,
            year: year,
            kind: kind,
            scheduledGameID: scheduledGameID,
            options: .init(
                retainPlays: true,
                injuriesEnabled: settings.injuriesEnabled,
                neutralSite: neutralSite
            )
        )
        self.rng = rng
        self.userTeamID = userTeamID
        self.homeTeamID = home.id
    }

    /// The random stream, handed back so the league can carry on from where the game left it.
    public var currentRNG: SeededRandom { rng }

    public var situation: GameSituation { simulator.currentSituation }

    public var isUserOnOffense: Bool { simulator.offenseTeamID == userTeamID }

    /// Live scores tied to the teams themselves, so a scoreboard's labels stay put when
    /// possession changes hands.
    public var userScore: Int {
        homeTeamID == userTeamID ? simulator.liveHomeScore : simulator.liveAwayScore
    }

    public var opponentScore: Int {
        homeTeamID == userTeamID ? simulator.liveAwayScore : simulator.liveHomeScore
    }

    public var quarter: Int { simulator.currentQuarter }
    public var clockRemaining: Int { simulator.clockRemaining }

    public var state: State {
        if simulator.isComplete { return .finished }
        return isUserOnOffense ? .awaitingUserPlay(simulator.currentSituation) : .simulating
    }

    /// Runs the engine forward until the user's offence is back on the field, the game ends, or
    /// `limit` snaps have passed. Returns the plays produced along the way.
    @discardableResult
    public mutating func advanceUntilUserTurn(
        limit: Int = 400,
        read: DefensiveInput = .none,
        pausingOnOpponentSnaps: Bool = false
    ) -> [PlayEvent] {
        let before = plays.count
        var steps = 0
        while steps < limit {
            steps += 1
            if simulator.isComplete { break }
            // Stop *before* taking the user's snap so they get to call it.
            if isUserOnOffense, simulator.hasStarted { break }
            // The read only ever applies to a snap the opposition is taking; kickoffs, the
            // user's own plays and clock administration are untouched by it.
            let applied: DefensiveInput? = isUserOnOffense ? nil : read
            let countBefore = plays.count
            guard simulator.advance(rng: &rng, defensiveRead: applied) else { break }
            captureNewPlays()

            // Hand back after each snap the opposition takes, so a caller that wants to show
            // the drive can show it a play at a time. Without this the whole possession
            // resolves inside one call and there is nothing left to watch — which is exactly
            // the text-box treatment the arcade mode exists to replace.
            if pausingOnOpponentSnaps,
               plays.count > countBefore,
               let latest = plays.last,
               latest.offenseTeamID != userTeamID,
               Self.isWatchable(latest.category) {
                break
            }
        }
        finishIfComplete()
        return Array(plays.dropFirst(before))
    }

    /// Steps a single snap of the opposition's drive, with the user's defensive read applied.
    ///
    /// The read is scored inside the simulator, once the offense's call has been drawn — a shade
    /// that anticipates a deep shot is worth nothing against a draw, so it cannot be priced any
    /// earlier. It becomes an ordinary `PlayExecution` with its sign flipped, which is why there
    /// is no second resolution path and no second set of calibration bands. Returns the plays
    /// that snap produced, or nothing if it is not the opposition's ball.
    @discardableResult
    public mutating func advanceOpponentSnap(read: DefensiveInput = .none) -> [PlayEvent] {
        guard !simulator.isComplete, !isUserOnOffense else { return [] }
        let before = plays.count
        guard simulator.advance(rng: &rng, defensiveRead: read) else {
            finishIfComplete()
            return []
        }
        captureNewPlays()
        finishIfComplete()
        return Array(plays.dropFirst(before))
    }

    /// Plays the user's snap with the call and execution they produced.
    @discardableResult
    public mutating func playUserSnap(
        call: OffensivePlay,
        execution: PlayExecution
    ) -> [PlayEvent] {
        guard !simulator.isComplete else { return [] }
        let before = plays.count
        simulator.advance(rng: &rng, userCall: call, execution: execution)
        captureNewPlays()
        finishIfComplete()
        return Array(plays.dropFirst(before))
    }

    /// Hands the rest of the game to the engine — the "sim to final" escape hatch.
    public mutating func simulateRemainder() {
        var guardCounter = 0
        while !simulator.isComplete, guardCounter < 5_000 {
            guardCounter += 1
            guard simulator.advance(rng: &rng) else { break }
        }
        captureNewPlays()
        finishIfComplete()
    }

    /// Whether a play is worth stopping to show. Clock administration and timeouts are not
    /// plays anybody wants to watch resolve on a field.
    static func isWatchable(_ category: PlayCategory) -> Bool {
        switch category {
        case .administrative, .timeout, .penalty, .injury: false
        case .run, .pass, .sack, .punt, .fieldGoal, .extraPoint, .kickoff, .turnover,
             .touchdown, .twoPointConversion, .kneel, .spike: true
        }
    }

    private mutating func captureNewPlays() {
        let all = simulator.playLog
        guard all.count > plays.count else { return }
        plays = all
    }

    private mutating func finishIfComplete() {
        guard simulator.isComplete, record == nil else { return }
        record = simulator.finish(rng: &rng)
        plays = record?.plays ?? plays
    }
}
