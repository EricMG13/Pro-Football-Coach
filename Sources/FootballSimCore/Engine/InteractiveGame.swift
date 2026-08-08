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
    public mutating func advanceUntilUserTurn(limit: Int = 400) -> [PlayEvent] {
        let before = plays.count
        var steps = 0
        while steps < limit {
            steps += 1
            if simulator.isComplete { break }
            // Stop *before* taking the user's snap so they get to call it.
            if isUserOnOffense, simulator.hasStarted { break }
            guard simulator.advance(rng: &rng) else { break }
            captureNewPlays()
        }
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
